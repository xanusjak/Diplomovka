//
//  SpeechRecognitionViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 12/04/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import ARKit

class SpeechRecognitionViewController: UIViewController {
    
    //MARK: - Private
    
    internal let moveConstant: Float = 0.05
    
    internal var currentNode: SCNNode?
    
//    internal var textNode: SCNNode?
    
//    internal var text: SCNText?
    
    internal var animating = false
    
    private var hasResult = false
    
    private var timer = Timer()
    
    internal var inputNodeBus: AVAudioNodeBus = 0
    
    /// The speech recogniser used by the controller to record the user's speech.
    private let speechRecogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    /// The audio engine used to record input from the microphone.
    private var audioEngine = AVAudioEngine()
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
//
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    internal func startRecording() throws {
        hasResult = false
        
        
        guard speechRecogniser.isAvailable else {
            // Speech recognition is unavailable, so do not attempt to start.
            return
        }
        
        if let recognitionTask = recognitionTask {
            // We have a recognition task still running, so cancel it before starting a new one.
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization({ _ in })
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        self.request = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = request else { return }
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecogniser.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result, self.hasResult == false {
                self.updateTextNode(string: result.bestTranscription.formattedString.lowercased())
                self.checkAction(result.bestTranscription.formattedString.lowercased())
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: self.inputNodeBus)
        inputNode.installTap(onBus: self.inputNodeBus, bufferSize: 1024, format: recordingFormat) { (audioBuffer, audioTime) in
            self.request?.append(audioBuffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    internal func stopRecording() {
        hasResult = true
        
        audioEngine.stop()
        request?.endAudio()
        audioEngine.inputNode.removeTap(onBus: self.inputNodeBus)
    }
    
    @objc private func reset() {
        print("--> reset()")
        stopRecording()
        try? startRecording()
    }
    
    private func checkAction(_ text: String) {
        print(text)
        
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(reset), userInfo: nil, repeats: false)
        
        for action in Action.all() {
            guard action.values.contains(where: text.contains) else { continue }
            
            switch action {
            case .leftRotation:
                leftRotationAction()
            case .rightRotation:
                rightRotationAction()
            case .stopRotation:
                stopRotationAction()
            case .showSelection:
                showSelection()
                break
            case .moveUp:
                moveUpAction()
            case .moveDown:
                moveDownAction()
            case .moveLeft:
                moveLeftAction()
            case .moveRight:
                moveRightAction()
            case .places:
                insertObjectAction()
            case .moveCloser:
                moveCloserAction()
            case .moveFurther:
                moveFurtherAction()
            case .stop:
                stopRecording()
            case .bigger:
                makeBiggerAction()
            case .smaller:
                makeSmallerAction()
            case .delete:
                deleteObjectAction()
            case .selectObject:
                selectObjectAction(text)
            case .closeView:
                closeViewAction()
            }
            
            self.reset()
            return
        }
        
        for setting in Setting.all() {
            guard setting.values.contains(where: text.contains) else { continue }
            
            switch setting {
            case .speech, .coreML, .vrMode, .gestures, .logs:
                enable(true, setting)
            default:
                enable(false, setting)
            }
            self.reset()
            return
        }
    }
    
    func updateTextNode(string: String) {
//        guard let text = text else { return }
//        text.string = string
    }
    
    //MARK: - Internal actions
    internal func showSelection() { }
    
    internal func showSettings() { }
    
    internal func insertObjectAction() { }
    
    internal func deleteObjectAction() { }
    
    internal func selectObjectAction(_ text: String) { }
    
    internal func closeViewAction() { }
    
    internal func settingWasUpdated(_ setting: Setting) { }
}

//MARK: - Private actions
extension SpeechRecognitionViewController {
    private func moveUpAction() {
        print("moveUpAction()")
        self.currentNode?.position.y += moveConstant
    }
    
    private func moveDownAction() {
        print("moveDownAction()")
        self.currentNode?.position.y -= moveConstant
    }
    
    private func moveLeftAction() {
        print("moveLeftAction()")
        self.currentNode?.position.x -= moveConstant
    }
    
    private func moveRightAction() {
        print("moveRightAction()")
        self.currentNode?.position.x += moveConstant
    }
    
    private func moveCloserAction() {
        print("moveCloserAction()")
        self.currentNode?.position.z -= moveConstant
    }
    
    private func moveFurtherAction() {
        print("moveFurtherAction()")
        self.currentNode?.position.z += moveConstant
    }
    
    private func makeBiggerAction() {
        print("makeBiggerAction()")
        guard let currentNode = currentNode else { return }
        let pinchScaleX: CGFloat = 1.2 * CGFloat((currentNode.scale.x))
        let pinchScaleY: CGFloat = 1.2 * CGFloat((currentNode.scale.y))
        let pinchScaleZ: CGFloat = 1.2 * CGFloat((currentNode.scale.z))
        currentNode.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
    }
    
    private func makeSmallerAction() {
        print("makeSmallerAction()")
        guard let currentNode = currentNode else { return }
        let pinchScaleX: CGFloat = 0.8 * CGFloat((currentNode.scale.x))
        let pinchScaleY: CGFloat = 0.8 * CGFloat((currentNode.scale.y))
        let pinchScaleZ: CGFloat = 0.8 * CGFloat((currentNode.scale.z))
        currentNode.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
    }
    
    func rightRotationAction() {
        print("rightRotationAction()")
        guard let currentNode = currentNode else { return }
        
        if animating {
            currentNode.removeAllActions()
        }
        animating = true
        
        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
        let repeatForever = SCNAction.repeatForever(rotateOne)
        currentNode.runAction(repeatForever)
    }
    
    func leftRotationAction() {
        print("leftRotationAction()")
        guard let currentNode = currentNode else { return }
        
        if animating {
            currentNode.removeAllActions()
        }
        animating = true

        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
        let backwards = rotateOne.reversed()
        let repeatForever = SCNAction.repeatForever(backwards)
        currentNode.runAction(repeatForever)
    }
    
    func stopRotationAction() {
        print("stopRotationAction()")
        guard let currentNode = currentNode else { return }
        
        currentNode.removeAllActions()
        animating = false
    }
}

//MARK: - Settings actions
extension SpeechRecognitionViewController {
    func enable(_ enable: Bool, _ setting: Setting) {
        switch setting {
        case .speech, .disableSpeech:
            guard SettingsManager.speechEnabled != enable else { return }
            SettingsManager.speechEnabled = enable
        case .coreML, .disableCoreML:
            guard SettingsManager.coreMLEnabled != enable else { return }
            SettingsManager.coreMLEnabled = enable
        case .vrMode, .disableVrMode:
            guard SettingsManager.vrModeEnabled != enable else { return }
            SettingsManager.vrModeEnabled = enable
        case .gestures, .disableGestures:
            guard SettingsManager.gesturesEnabled != enable else { return }
            SettingsManager.gesturesEnabled = enable
        case .logs, .disableLogs:
            guard SettingsManager.logsEnabled != enable else { return }
            SettingsManager.logsEnabled = enable
        }
        
        settingWasUpdated(setting)
    }
}

    
