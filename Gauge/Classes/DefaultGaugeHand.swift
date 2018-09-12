//
//  DefaultGaugeHand.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 11/01/2018.
//  Copyright © 2018 MOLO17. All rights reserved.
//

import UIKit

/// A default hand that's used by the Gauge.
///
/// It's a simple black hand that stays in the center of the Gauge and it's
/// rotated accordingly, so it points to the current value in the Gauge range.
public struct DefaultGaugeHand: GaugeHand {

    // MARK: GaugeHand

    public var layer: CALayer {
        return _hand
    }

    public func update(
        value: Value,
        angle: Angle,
        valueInner: CGPoint,
        valueOuter: CGPoint,
        origin: Angle,
        originInner: CGPoint,
        originOuter: CGPoint,
        bounds: CGRect,
        trackThickness: CGFloat
    ) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: 10,
            startAngle: 0,
            endAngle: Angle(degrees: 360).radians,
            clockwise: true
        )
        path.move(to: center)
        path.addLine(to: valueOuter)
        _hand.path = path.cgPath
        _hand.frame = bounds
    }

    // MARK: Private properties

    let _hand: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = UIColor.black.cgColor
        l.strokeColor = UIColor.black.cgColor
        l.lineWidth = 5

        return l
    }()
}
