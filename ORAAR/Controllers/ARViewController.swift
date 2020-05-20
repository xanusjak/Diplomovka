//
//  ARViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 13/11/2019.
//  Copyright © 2019 Anušjak, Milan. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ARViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    private var imageName = "toy_drummer"
    
    private var selectedNode: SCNNode?
    private var currentNode: SCNNode?
    private var currentAngleY: Float = 0.0
    
    private var panStartZ: CGFloat = 0.0
    private var lastPanLocation = SCNVector3(0, 0, 0)
    
    private var animating = false
    
    // MARK: - CoreML
    let currentMLModel = HandModelOnline().model
    private let serialQueue = DispatchQueue(label: "com.aboveground.dispatchqueueml")
    private var visionRequests = [VNRequest]()
    private var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLighting()
        
        self.title = imageName
        
        setupCoreML()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopCoreMLUpdate), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.automaticImageScaleEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addNodeToSceneView(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        sceneView.addGestureRecognizer(rotateGesture)
        
        //let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveNode(_:)))
        //sceneView.addGestureRecognizer(panRecognizer)
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    private func loadSCNNode(withName name: String) -> SCNNode? {
        let sceneURL = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Assets.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)
        referenceNode?.load()
        return referenceNode
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectionVC = segue.destination as? SelectionViewController {
            selectionVC.delegate = self
        }
    }
}

//  MARK: - SCNNode Actions

extension ARViewController {
    @objc func addNodeToSceneView(_ gesture: UIGestureRecognizer) {
        let tapLocation = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        guard let node = self.loadSCNNode(withName: imageName) else { return }
        node.position = SCNVector3(x,y,z)
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        
        self.currentNode = node
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    @objc func scaleNode(_ gesture: UIPinchGestureRecognizer) {
        guard let currentNode = currentNode else { return }
        
        if gesture.state == .changed {
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((currentNode.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((currentNode.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((currentNode.scale.z))
            currentNode.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            gesture.scale = 1
        }
        
        if gesture.state == .ended { }
    }
    
    @objc func rotateNode(_ gesture: UIRotationGestureRecognizer){
        guard let currentNode = currentNode else { return }
        
        //1. Get The Current Rotation From The Gesture
        let rotation = Float(gesture.rotation)
        
        //2. If The Gesture State Has Changed Set The Nodes EulerAngles.y
        if gesture.state == .changed {
            currentNode.eulerAngles.y = currentAngleY + rotation
        }
        
        //3. If The Gesture Has Ended Store The Last Angle Of The Cube
        if gesture.state == .ended {
            currentAngleY = currentNode.eulerAngles.y
        }
    }
    
    @objc func moveNode(_ gesture: UIPanGestureRecognizer) {
        
        let touch = gesture.location(in: self.sceneView)
        
        switch gesture.state {
        case .began:
            // perform a hitTest
            let hitTestResult = self.sceneView.hitTest(touch, options: nil)
            guard let hitNode = hitTestResult.first?.node.parent?.childNodes.last else { return }
            // Set hitNode as selected
            self.selectedNode = hitNode
            
        case .changed:
            // make sure a node has been selected from .began
            guard let hitNode = self.selectedNode else { return }
            
            // perform a hitTest to obtain the plane
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            guard let hitPlane = hitTestPlane.first else { return }
            hitNode.position = SCNVector3(hitPlane.worldTransform.columns.3.x,
                                          hitNode.position.y,
                                          hitPlane.worldTransform.columns.3.z)
            
        case .ended:
            guard let _ = self.selectedNode else { return }
            // Undo selection
            self.selectedNode = nil
            
        default:
            break
        }
    }
    
    @IBAction fileprivate func animate(_ sender: UIBarButtonItem) {
        if animating {
            stopAnimating()
        } else {
            animateLeft()
        }
    }
    
    func animateLeft() {
        guard let currentNode = currentNode else { return }
        
        if animating { return }
        animating = true

        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
        
        let backwards = rotateOne.reversed()
        let repeatForever = SCNAction.repeatForever(backwards)
        
        currentNode.runAction(repeatForever)
    }
    
    func animateRight() {
        guard let currentNode = currentNode else { return }
        
        if animating { return }
        animating = true
        
        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
        
        let repeatForever = SCNAction.repeatForever(rotateOne)
        
        currentNode.runAction(repeatForever)
    }
    
    func stopAnimating() {
        guard let currentNode = currentNode else { return }
        
        currentNode.removeAllActions()
        animating = false
    }
}

//  MARK: - ARSCNView Delegate

extension ARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        let plane = SCNPlane(width: width, height: height)
//
//        // 3
//        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
//
//        // 4
//        let planeNode = SCNNode(geometry: plane)
//
//        // 5
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x,y,z)
//        planeNode.eulerAngles.x = -.pi / 2
//
//        // 6
//        node.addChildNode(planeNode)
        
        let meshNode : SCNNode
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        guard let meshGeometry = ARSCNPlaneGeometry(device: sceneView.device!) else {
                fatalError("Can't create plane geometry")
        }
        meshGeometry.update(from: planeAnchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)
        meshNode.opacity = 0.6
        meshNode.name = "MeshNode"
        
        guard let material = meshNode.geometry?.firstMaterial else {
            fatalError("ARSCNPlaneGeometry always has one material")
        }
        material.diffuse.contents = UIColor.blue
        
        node.addChildNode(meshNode)
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // 1
//        guard let planeAnchor = anchor as?  ARPlaneAnchor,
//            let planeNode = node.childNodes.first,
//            let plane = planeNode.geometry as? SCNPlane
//            else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        plane.width = width
//        plane.height = height
//
//        // 3
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x, y, z)
//    }
}

// MARK: - SelectionViewControllerDelegate

extension ARViewController: SelectionViewControllerDelegate {
    func didSelectItem(with imageName: String) {
        self.imageName = imageName
        self.title = imageName
    }
}

// MARK: - CoreML
extension ARViewController {
    @objc private func loopCoreMLUpdate() {
        serialQueue.async {
            self.updateCoreML()
        }
    }
    
    private func setupCoreML() {
        guard let selectedModel = try? VNCoreMLModel(for: currentMLModel) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
    }
    
    private func updateCoreML() {
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        
        let deviceOrientation = UIDevice.current.orientation.getImagePropertyOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff!, orientation: deviceOrientation,options: [:])
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    private func classificationCompleteHandler(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNClassificationObservation] else { return }
//
//        DispatchQueue.main.async {
//            for observation in observations {
//                guard observation.confidence > 0.95 else { return }
//
//                if observation.identifier == "👌" {
//                    print("👌 ---> \(observation.confidence)")
//                    self.animateRight()
//                } else if observation.identifier == "🖐" {
//                    print("🖐 ---> \(observation.confidence)")
//                    self.animateLeft()
//                } else if observation.identifier == "⚪️" {
//                    print("⚪️ ---> \(observation.confidence)")
//                    self.stopAnimating()
//                }
//            }
//        }
    }
}
