//
//  BoundingBox.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 01/11/2019.
//  Copyright © 2019 Anušjak, Milan. All rights reserved.
//

import Foundation
import UIKit

class BoundingBox {
    let shapeLayer: CAShapeLayer
    let textLayer: CATextLayer
    
    init() {
        shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.isHidden = true
        
        textLayer = CATextLayer()
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.isHidden = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 17
        textLayer.font = UIFont(name: "Avenir", size: textLayer.fontSize)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
    }
    
    func show(frame: CGRect, label: String, color: UIColor = UIColor(red: 1, green: 1, blue: 0.2, alpha: 0.2)) {
        CATransaction.setDisableActions(true)
        
        //    let path = UIBezierPath(rect: frame)
        //    shapeLayer.path = path.cgPath
        //    shapeLayer.strokeColor = color.cgColor
        //    shapeLayer.isHidden = false
        
        shapeLayer.bounds = frame
        shapeLayer.position = CGPoint(x: frame.midX, y: frame.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = color.cgColor
        shapeLayer.cornerRadius = 7
        shapeLayer.isHidden = false
        
        textLayer.string = label
        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false
        textLayer.name = "Object Label"
        textLayer.bounds = CGRect(x: 0,
                                  y: 0,
                                  width: frame.size.height - 10,
                                  height: frame.size.width - 10)
        textLayer.position = CGPoint(x: frame.midX, y: frame.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    }
    
    func hide() {
        shapeLayer.isHidden = true
        textLayer.isHidden = true
    }
}
