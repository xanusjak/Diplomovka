//
//  SettingsManager.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 05/05/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import Foundation

class SettingsManager {
    static var speechEnabled = true
    static var coreMLEnabled = true
    static var vrModeEnabled = false
    static var gesturesEnabled = false
    static var logsEnabled = false
    
    static func loadSettings() {
        speechEnabled = UserDefaults.standard.bool(forKey: "speechEnabled")
        coreMLEnabled = UserDefaults.standard.bool(forKey: "coreMLEnabled")
        vrModeEnabled = UserDefaults.standard.bool(forKey: "vrModeEnabled")
        gesturesEnabled = UserDefaults.standard.bool(forKey: "gesturesEnabled")
        logsEnabled = UserDefaults.standard.bool(forKey: "logsEnabled")
    }
    
    static func saveSettings() {
        UserDefaults.standard.set(speechEnabled, forKey: "speechEnabled")
        UserDefaults.standard.set(coreMLEnabled, forKey: "coreMLEnabled")
        UserDefaults.standard.set(vrModeEnabled, forKey: "vrModeEnabled")
        UserDefaults.standard.set(gesturesEnabled, forKey: "gesturesEnabled")
        UserDefaults.standard.set(logsEnabled, forKey: "logsEnabled")
    }
}
