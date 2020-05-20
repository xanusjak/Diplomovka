//
//  CoreMLViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 06/05/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit
import ARKit
import Vision

class CoreMLViewController: SpeechRecognitionViewController {
    
    // MARK: - CoreML
    let currentMLModel = HandModelOnline().model
    private let serialQueue = DispatchQueue(label: "com.aboveground.dispatchqueueml")
    internal var visionRequests = [VNRequest]()
    private var timer: Timer?
    
    
    @objc private func loopCoreMLUpdate() {
        serialQueue.async {
            self.updateCoreML()
        }
    }
    
    internal func startCoreML() {
        setupCoreML()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.loopCoreMLUpdate), userInfo: nil, repeats: true)
    }
    
    internal func stopCoreML() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private func setupCoreML() {
        guard let selectedModel = try? VNCoreMLModel(for: currentMLModel) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
    }
    
    internal func updateCoreML() {
    }
    
    internal func classificationCompleteHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation] else { return }
        
        DispatchQueue.main.async {
            for observation in observations {
                guard observation.confidence > 0.90 else { return }
                
                switch observation.identifier {
                case "FIVE-UB-RHand":
                    print("FIVE-UB-RHand")
                    guard !self.animating else { return }
                    self.rightRotationAction()
                case "fist-UB-RHand":
                    print("fist-UB-RHand")
                    guard !self.animating else { return }
                    self.leftRotationAction()
                case "no-hand":
                    print("no-hand")
                    guard self.animating else { return }
                    self.stopRotationAction()
                default: return
                }
            }
        }
    }
}
