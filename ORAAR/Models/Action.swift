//
//  Action.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 13/04/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import Foundation

enum Action {
    case showSelection
    case closeView
    case rightRotation
    case leftRotation
    case stopRotation
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case moveCloser
    case moveFurther
    case places
    case stop
    case bigger
    case smaller
    case delete
    case selectObject
    
    static let maximumCount = 3
    
    static func all() -> [Action] {
        [.showSelection, .closeView, .leftRotation, .rightRotation, .stopRotation, .moveUp, .moveDown, .moveLeft, .moveRight, .places, .moveCloser, .moveFurther, .stop, .bigger, .smaller, .delete, .selectObject, .closeView]
    }
    
    var values: [String] {
        switch self {
        case .showSelection:
            return ["show selection"]
            
        case .rightRotation:
            return ["rotate right", "right rotation", "rotation right"]
            
        case .leftRotation:
            return ["rotate left", "rotate the left", "left rotation", "rotation left"]
            
        case .stopRotation:
             return ["rotate stop", "stop rotation", "rotation stop"]
            
        case .moveUp:
            return ["move up"]
            
        case .moveDown:
            return ["move down"]
            
        case .moveLeft:
            return ["move left", "move to left"]
            
        case .moveRight:
            return ["move right", "move to right"]
            
        case .moveCloser:
            return ["move closer"]
            
        case .moveFurther:
            return ["move further", "move back"]
            
        case .places:
            return ["places the object", "places object", "insert the object", "insert object"]
            
        case .stop:
            return ["reset"]
            
        case .bigger:
            return ["make bigger", "make a bigger"]
            
        case .smaller:
            return ["make smaller", "make a smaller"]
            
        case .delete:
            return ["delete object", "delete the object", "remove object", "remove the object"]
            
        case .selectObject:
            return ["select object", "select the object"]
        
        case .closeView:
            return ["close selection", "close view"]
        }
    }
}
