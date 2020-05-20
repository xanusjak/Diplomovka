//
//  SettingsViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 04/05/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate {
    func settingUpdated(_ setting: Setting)
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var speechControl: UISegmentedControl!
    @IBOutlet weak var coreMLControl: UISegmentedControl!
    @IBOutlet weak var vrModeControl: UISegmentedControl!
    @IBOutlet weak var gesturesControl: UISegmentedControl!
    @IBOutlet weak var logsControl: UISegmentedControl!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceStepper: UIStepper!
    
    var delegate: SettingsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        distanceLabel.text = String(format: "Vzdialenost oci %.2f m", pupilsDistance)
        distanceStepper.value = Double(pupilsDistance)
        distanceStepper.minimumValue = 0.002
        distanceStepper.maximumValue = 0.096
        distanceStepper.stepValue = 0.002

        speechControl.selectedSegmentIndex = SettingsManager.speechEnabled ? 0 : 1
        coreMLControl.selectedSegmentIndex = SettingsManager.coreMLEnabled ? 0 : 1
        vrModeControl.selectedSegmentIndex = SettingsManager.vrModeEnabled ? 0 : 1
        gesturesControl.selectedSegmentIndex = SettingsManager.gesturesEnabled ? 0 : 1
        logsControl.selectedSegmentIndex = SettingsManager.logsEnabled ? 0 : 1
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SettingsManager.saveSettings()
    }

    @IBAction private func speechValueChanged(_ sender: UISegmentedControl) {
        SettingsManager.speechEnabled = sender.selectedSegmentIndex == 0
        delegate?.settingUpdated(Setting.speech)
    }
    
    @IBAction private func coreMLValueChanged(_ sender: UISegmentedControl) {
        SettingsManager.coreMLEnabled = sender.selectedSegmentIndex == 0
        delegate?.settingUpdated(Setting.coreML)
    }
    
    @IBAction private func vrModeValueChanged(_ sender: UISegmentedControl) {
        SettingsManager.vrModeEnabled = sender.selectedSegmentIndex == 0
        delegate?.settingUpdated(Setting.vrMode)
    }
    
    @IBAction func gestureValueChanged(_ sender: UISegmentedControl) {
        SettingsManager.gesturesEnabled = sender.selectedSegmentIndex == 0
        delegate?.settingUpdated(Setting.gestures)
    }
    
    @IBAction func logsValueChanged(_ sender: UISegmentedControl) {
        SettingsManager.logsEnabled = sender.selectedSegmentIndex == 0
        delegate?.settingUpdated(Setting.logs)
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        pupilsDistance = Float(sender.value)
        distanceLabel.text =  String(format: "Vzdialenost oci %.3f m", pupilsDistance)
    }
}
