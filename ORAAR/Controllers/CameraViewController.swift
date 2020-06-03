//
//  CameraViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 22/08/2019.
//  Copyright © 2019 Anušjak, Milan. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CameraViewController: UIViewController {
    
    @IBOutlet var cameraView: UIView!
    
    fileprivate var boundingBoxes = [BoundingBox]()
    fileprivate var request: VNCoreMLRequest!
    fileprivate var bufferSize: CGSize = .zero
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    fileprivate var boxesLayer: CALayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpBoundingBoxes()
        setUpVision()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.previewLayer.frame = self.cameraView.bounds
    }
    
    //MARK: Setup BoundingBoxes
    
    func setUpBoundingBoxes() {
        for _ in 0..<10 {
            boundingBoxes.append(BoundingBox())
        }
    }
    
    //MARK: Setup camera
    
    private func setupCamera() {
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
        bufferSize.width = CGFloat(dimensions.width)
        bufferSize.height = CGFloat(dimensions.height)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = self.cameraView.bounds
        cameraView.layer.addSublayer(previewLayer)
        
        boxesLayer = CALayer()
        boxesLayer.frame = CGRect(x: 0, y: 0, width: bufferSize.width, height: bufferSize.height)
        previewLayer.addSublayer(boxesLayer)
        updateLayerGeometry()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraQueue"))
        captureSession.addOutput(dataOutput)
        
        for box in self.boundingBoxes {
            box.addToLayer(self.boxesLayer)
        }
    }
    
    func updateLayerGeometry() {
        let bounds = previewLayer.bounds
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
                boundingBoxes[i].show(frame: rect, label: label)
            } else {
                boundingBoxes[i].hide()
            }
        }
        updateLayerGeometry()
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.predictUsingVision(pixelBuffer: pixelBuffer)
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
        
        DispatchQueue.main.async {
            self.show(observations: observations)
        }
    }
}
