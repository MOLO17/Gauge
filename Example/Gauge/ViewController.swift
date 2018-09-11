//
//  ViewController.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 09/11/2018.
//  Copyright (c) 2018 Alessandro Vendruscolo. All rights reserved.
//

import Gauge
import TinyConstraints
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(defaultGauge)
        defaultGauge.topToSuperview()
        defaultGauge.leading(to: view)
        defaultGauge.width(320)
        defaultGauge.height(320)

        view.addSubview(gauge2)
        gauge2.bottomToSuperview()
        gauge2.trailing(to: view)
        gauge2.width(320)
        gauge2.height(320)

    }

    private lazy var defaultGauge: Gauge = {
        let g = Gauge(bindingBehaviour: .title)
        g.range = 0...100
        g.value = 50
        g.origin = Angle(radians: .pi)

        return g
    }()

    private lazy var gauge2: Gauge = {
        let g = Gauge(bindingBehaviour: .none)
        g.range = 0...100
        g.value = 60
        g.origin = Angle(radians: .pi / 2)
        g.emptySlice = 0
        g.minValueLabel.isHidden = true
        g.maxValueLabel.isHidden = true
        g.hand = GaugeCustomHand()

        return g
    }()
}

private struct GaugeCustomHand: GaugeHand {

    var layer: CALayer {
        return _hand
    }

    func update(
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

        // Pay attention that UIBezierPath has a different coordinate system
        // compared the Angle type (because Quartz ¯\_(ツ)_/¯) so convert
        // received angle values to make sure the drawing is correct.
        // 360 - <the provided angle> is the conversion we need: Quartz works
        // with the exact opposite coordinate system.
        _hand.path = UIBezierPath(
            arcCenter: center,
            radius: bounds.width / 2 - trackThickness / 2,
            startAngle: (Angle(360) - origin).radians,
            endAngle: (Angle(360) - angle).radians,
            clockwise: true
        ).cgPath

        _hand.lineWidth = trackThickness
        _hand.frame = bounds
    }

    // MARK: Private properties

    let _hand: CAShapeLayer = {
        let l = CAShapeLayer()
        l.strokeColor = UIColor.green.cgColor
        l.fillColor = UIColor.clear.cgColor

        return l
    }()

}

