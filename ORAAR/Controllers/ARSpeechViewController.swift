//
//  ARSpeechViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 13/04/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit
import ARKit
import Vision

var pupilsDistance: Float = 0.020 //0.066  // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).

class ARSpeechViewController: CoreMLViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var copySceneView: ARSCNView!
    
    @IBOutlet weak var logsStackView: UIStackView!
    @IBOutlet weak var logsLabel: UILabel!
    @IBOutlet weak var copyLogsLabel: UILabel!
    
    private var nodeName: String? {
        didSet { self.title = nodeName }
    }
    
    private var insertedNodes: [SCNNode] = []
    
    private var selectedNode: SCNNode?
    private var currentAngleY: Float = 0.0
    
    private var panStartZ: CGFloat = 0.0
    private var lastPanLocation = SCNVector3(0, 0, 0)
    
    private var gestures: [UIGestureRecognizer] = []
    
    private var showLogs = false
    
    var imagesNames: [String] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "Assets.scnassets") else {
            print("Failed to load URLS")
            return []
        }
        
        let insertedNames = insertedNodes.map { $0.name }.compactMap { $0 }
        return urls.map { $0.lastPathComponent.replacingOccurrences(of: ".usdz", with: "") }.filter { !insertedNames.contains($0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(deleteObject(_:))),
            UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(showSettings(_:))),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showSelection(_:)))
        ]
        
        configureLighting()
        
//        self.title = nodeName
        
        Setting.allPrimary().forEach { updateSetting($0) }
        
        if insertedNodes.isEmpty {
            nodeName = "toy_drummer"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.automaticImageScaleEstimationEnabled = true
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        copySceneView.delegate = self
        copySceneView.session.delegate = self
        copySceneView.scene = sceneView.scene
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addNodeToSceneView(_:)))
//                    sceneView.addGestureRecognizer(tapGestureRecognizer)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode(_:)))
        //            sceneView.addGestureRecognizer(pinchGesture)
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        //            sceneView.addGestureRecognizer(rotateGesture)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveNode(_:)))
        //            sceneView.addGestureRecognizer(panRecognizer)
        gestures = [tapGestureRecognizer, pinchGesture, rotateGesture, panRecognizer]
        
        if SettingsManager.gesturesEnabled {
            gestures.forEach { sceneView.addGestureRecognizer($0) }
        }
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
            selectionVC.imageNames = imagesNames
        } else if let settingsVC = segue.destination as? SettingsViewController {
            settingsVC.delegate = self
        }
    }
    
    @objc func deleteObject(_ sender: UIBarButtonItem) {
        deleteObjectAction()
    }
    
    @objc func showSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    @objc func showSelection(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSelection", sender: self)
    }
    
    override func updateCoreML() {
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
    
    override func updateTextNode(string: String) {
        guard showLogs else { return }
        logsLabel.text = string
        copyLogsLabel.text = string
    }
    
    // MARK: - Speech actions
    
    override func showSelection() {
        performSegue(withIdentifier: "showSelection", sender: self)
    }
    
    override func showSettings() {
        performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    override func insertObjectAction() {
        print("--> insertObjectAction()")
        guard let name = nodeName, let liveNode = sceneView.scene.rootNode.childNode(withName: "\(name)_live", recursively: false) else { return }
        
        guard sceneView.scene.rootNode.childNode(withName: name, recursively: false) == nil else {
            print("Object with name \(name) already exists.")
            return
        }
        guard let node = self.loadSCNNode(withName: name) else { return }
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        node.name = nodeName
        node.position = liveNode.position

        self.currentNode = node
        sceneView.scene.rootNode.addChildNode(node)
        insertedNodes.append(node)
        
        sceneView.scene.rootNode.childNode(withName: "\(name)_live", recursively: false)?.removeFromParentNode()
        nodeName = nil
    }
    
    override func deleteObjectAction() {
        print("--> deleteObjectAction()")
        //TODO: find object by name
        guard let last = insertedNodes.last else { return }
        last.removeFromParentNode()
        insertedNodes.removeLast()
        
        if insertedNodes.isEmpty {
            nodeName = "toy_drummer"
        }
    }
    
    override func settingWasUpdated(_ setting: Setting) {
        updateSetting(setting)
    }
}

//  MARK: - SCNNode Actions

extension ARSpeechViewController {
    @objc func addNodeToSceneView(_ gesture: UIGestureRecognizer) {
        if nodeName != nil {
            insertObjectAction()
            return
        }
        
        let tapLocation = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        

        guard let _ = hitTestResults.first else { return }
        if let last = insertedNodes.last {
            nodeName = last.name
            last.removeFromParentNode()
        }
        
//        let translation = hitTestResult.worldTransform.translation
//        let x = translation.x
//        let y = translation.y
//        let z = translation.z
//
//        guard let node = self.loadSCNNode(withName: nodeName) else { return }
//        node.position = SCNVector3(x,y,z)
//        node.scale = SCNVector3(0.01, 0.01, 0.01)
//
//        self.currentNode = node
//        sceneView.scene.rootNode.addChildNode(node)
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
}

//  MARK: - ARSCNView Delegate

extension ARSpeechViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        let meshNode : SCNNode
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        guard let meshGeometry = ARSCNPlaneGeometry(device: sceneView.device!) else {
                fatalError("Can't create plane geometry")
        }
        meshGeometry.update(from: planeAnchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)
        meshNode.opacity = 0.4
        meshNode.name = "MeshNode"
        
        guard let material = meshNode.geometry?.firstMaterial else {
            fatalError("ARSCNPlaneGeometry always has one material")
        }
        material.diffuse.contents = UIColor.blue
        
        node.addChildNode(meshNode)
    }
//        let textNode : SCNNode
//        let textGeometry = SCNText(string: "Plane", extrusionDepth: 1)
//        textGeometry.font = UIFont(name: "Futura", size: 75)
//
//        textNode = SCNNode(geometry: textGeometry)
//        textNode.name = "TextNode"
//
//        textNode.simdScale = SIMD3(repeating: 0.0005)
//        textNode.eulerAngles = SCNVector3(x: Float(-90.degreesToradians), y: 0, z: 0)
//
//        node.addChildNode(textNode)
//
//        textNode.centerAlign()

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = node.childNode(withName: "MeshNode", recursively: false)
        
        if let planeGeometry = planeNode?.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateCopySceneView()
        }
    }
    
    func updateCopySceneView() {
        // Clone pointOfView for SecondView
        let pointOfView : SCNNode = (sceneView.pointOfView?.clone())!
        copySceneView.pointOfView = pointOfView
        
//        // Determine Adjusted Position for Right Eye
//        let orientation : SCNQuaternion = pointOfView.orientation
//        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
//        let eyePos : GLKVector3 = GLKVector3Make(1.0, 0.0, 0.0)
//        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
//        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
//
//        let mag : Float = pupilsDistance //0.066 // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
//        print("MAAAAAAG \(mag)")
//        pointOfView.position.x += rotatedEyePosSCNV.x * mag
//        pointOfView.position.y += rotatedEyePosSCNV.y * mag
//        pointOfView.position.z += rotatedEyePosSCNV.z * mag
//
        // Set PointOfView for SecondView
//        copySceneView.pointOfView = pointOfView
    }
}

//  MARK: - ARSession Delegate

extension ARSpeechViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let location = sceneView.center
        let hitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitTest.isEmpty {
//            print("No Plane Detected")
            return
        } else if let name = nodeName {
            
            let columns = hitTest.first?.worldTransform.columns.3
            
            let position = SCNVector3(x: columns!.x, y: columns!.y, z: columns!.z)
            
            var node = sceneView.scene.rootNode.childNode(withName: "\(name)_live", recursively: false) ?? nil
            if node == nil {
                let scene = SCNScene(named: "Assets.scnassets/\(name).usdz")!
                node = scene.rootNode.childNode(withName: name, recursively: false)
                node?.opacity = 0.7
                node?.scale = SCNVector3(0.01, 0.01, 0.01)
                let columns = hitTest.first?.worldTransform.columns.3
                node!.name = "\(name)_live"
                node!.position = SCNVector3(x: columns!.x, y: columns!.y, z: columns!.z)
                sceneView.scene.rootNode.addChildNode(node!)
            }
            let position2 = node?.position
            
            if position == position2! {
                return
            } else {
                //action
                let action = SCNAction.move(to: position, duration: 0.1)
                node?.runAction(action)
            }
        } else {
            
        }
    }
}

// MARK: - SelectionViewController Delegate

extension ARSpeechViewController: SelectionViewControllerDelegate {
    func didSelectItem(with imageName: String) {
        if let name = nodeName {
            sceneView.scene.rootNode.childNode(withName: "\(name)_live", recursively: false)?.removeFromParentNode()
        }
        
        self.nodeName = imageName
//        self.title = imageName
    }
}

// MARK: - SettingsViewController Delegate

extension ARSpeechViewController: SettingsViewControllerDelegate {
    func settingUpdated(_ setting: Setting) {
        updateSetting(setting)
    }
    
    private func updateSetting(_ setting: Setting) {
        switch setting {
        case .speech: SettingsManager.speechEnabled ? try? startRecording() : stopRecording()
            
        case .coreML: SettingsManager.coreMLEnabled ? self.startCoreML() : self.stopCoreML()
            
        case .vrMode:
            let isHidden = !SettingsManager.vrModeEnabled
            self.copySceneView.isHidden = isHidden
            self.copyLogsLabel.isHidden = isHidden
            self.view.layoutIfNeeded()
            
        case .gestures:
            if SettingsManager.gesturesEnabled, (sceneView.gestureRecognizers ?? []).isEmpty {
                gestures.forEach { sceneView.addGestureRecognizer($0) }
            } else {
                (sceneView.gestureRecognizers ?? []).forEach { sceneView.removeGestureRecognizer($0) }
            }
            
        case .logs:
            showLogs = SettingsManager.logsEnabled
            if  showLogs {
                logsStackView.isHidden = false
//                text = SCNText(string: "Test", extrusionDepth: 2)
//                let material = SCNMaterial()
//                material.diffuse.contents = UIColor.magenta
//                text!.materials = [material]
//
//                textNode = SCNNode()
//                textNode!.position = SCNVector3(x:0, y:0.02, z:-0.1)
//                textNode!.scale = SCNVector3(x:0.01, y:0.01, z:0.01)
//                textNode!.geometry = text!
//
//                sceneView.scene.rootNode.addChildNode(textNode!)
            } else {
                logsStackView.isHidden = true
//                textNode?.removeFromParentNode()
//                textNode = nil
//                text = nil
            }
            
        default: return
        }
    }
}
