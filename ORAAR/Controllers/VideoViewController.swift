//
//  VideoViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 16/10/2019.
//  Copyright © 2019 Anušjak, Milan. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VideoViewController: UIViewController {
    
    fileprivate var boundingBoxes = [BoundingBox]()
    fileprivate var request: VNCoreMLRequest!
    fileprivate var bufferSize: CGSize = .zero
    fileprivate var boxesLayer: CALayer!
    
    enum VideoState {
        case playing
        case stopped
    }
    
    @IBOutlet fileprivate weak var playStopButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var videoView: UIView!
    @IBOutlet fileprivate weak var identifierLabel: UILabel!
    
    var videoAsset: AVAsset!
    private var videoState: VideoState = .stopped
    private var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpBoundingBoxes()
        setUpVision()
        setupVideoPlayer()
    }
    
    
    func setupVideoPlayer() {
        
        // Create AVPlayer object
        let playerItem = AVPlayerItem(asset: videoAsset)
        player = AVPlayer(playerItem: playerItem)
        
        // Create AVPlayerLayer object
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoView.bounds
        playerLayer.videoGravity = .resizeAspect
        
        // Add playerLayer to view's layer
        self.videoView.layer.addSublayer(playerLayer)
        
        //let dimensions = CMVideoFormatDescriptionGetDimensions((captureDevice.activeFormat.formatDescription))
        bufferSize.width = CGFloat(1080)
        bufferSize.height = CGFloat(1920)
        
        boxesLayer = CALayer()
        boxesLayer.frame = CGRect(x: 0, y: 0, width: bufferSize.width, height: bufferSize.height)
//        boxesLayer.backgroundColor = UIColor.red.cgColor
        self.videoView.layer.addSublayer(boxesLayer)
        
//        let boxLayer = CALayer()
//        boxLayer.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
//        boxLayer.backgroundColor = UIColor.red.cgColor
//        self.videoView.layer.addSublayer(boxLayer)
        
        let videoOutput = AVPlayerItemVideoOutput()
        playerItem.add(videoOutput)
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 30), queue: .main) { (time) in
            guard videoOutput.hasNewPixelBuffer(forItemTime: time),
                let buffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
            
            self.predictUsingVision(pixelBuffer: buffer)
        }
        
        for box in self.boundingBoxes {
            box.addToLayer(self.boxesLayer)
        }
    }
    
    func updateLayerGeometry() {
        let bounds = self.videoView.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        boxesLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        boxesLayer.position = CGPoint (x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
    
    //MARK: Setup vision
    
    func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: YOLOv3().model) else {
            fatalError("Error: could not create Vision model")
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        request.imageCropAndScaleOption = .scaleFill
    }
    
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
        
        DispatchQueue.main.async {
            self.show(observations: observations)
        }
    }
    
    //MARK: Setup BoundingBoxes
    
    func setUpBoundingBoxes() {
        for _ in 0..<10 {
            boundingBoxes.append(BoundingBox())
        }
    }
    
    func show(observations: [VNRecognizedObjectObservation]) {
        for i in 0..<boundingBoxes.count {
            if i < observations.count {
                let observation = observations[i]
                
                let rect = VNImageRectForNormalizedRect(observation.boundingBox,
                                                        Int(bufferSize.width),
                                                        Int(bufferSize.height))
                
                // Show the bounding box.
                let identifier = observation.labels[0].identifier
                let confidence = observation.labels[0].confidence
                let label = String(format: "%@ %.2f", identifier, confidence)
                print(label, rect)
                identifierLabel.text = label
                boundingBoxes[i].show(frame: rect, label: label)
            } else {
                boundingBoxes[i].hide()
            }
        }
        updateLayerGeometry()
    }
    
    @IBAction fileprivate func handlePlayStop(_ sender: UIBarButtonItem) {
        switch videoState {
        case .playing:
            self.videoState = .stopped
            player.pause()
            player.seek(to: .zero)
        case .stopped:
            self.videoState = .playing
            player.play()
        }
    }
}
