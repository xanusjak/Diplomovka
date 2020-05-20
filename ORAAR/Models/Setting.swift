//
//  Setting.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 05/05/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import Foundation

enum Setting {
    case speech
    case disableSpeech
    case coreML
    case disableCoreML
    case vrMode
    case disableVrMode
    case gestures
    case disableGestures
    case logs
    case disableLogs
    
    static func all() -> [Setting] {
        [.speech, .coreML, .vrMode, .gestures, .logs, .disableVrMode, .disableSpeech, .disableCoreML, .disableGestures, .disableLogs]
    }
    
    static func allPrimary() -> [Setting] {
        [.speech, .coreML, .vrMode, .gestures, .logs]
    }
    
    var values: [String] {
        switch self {
        case .speech:
            return ["turn on voice control", "turn on speech"]
        case .coreML:
            return ["turn on core ml"]
        case .vrMode:
            return ["turn on virtual reality", "enable virtual reality"]
        case .gestures:
            return ["turn on gestures"]
        case .logs:
            return ["turn on console", "turn on log", "enable logs " , "enable log"]
        case .disableSpeech:
            return ["turn off voice control", "turn off speech"]
        case .disableCoreML:
            return ["turn off core ml"]
        case .disableVrMode:
            return ["turn off virtual reality", "turn off split view"]
        case .disableGestures:
            return ["turn off gestures"]
        case .disableLogs:
            return ["turn off console"]
        }
    }
}
