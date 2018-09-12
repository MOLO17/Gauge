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
        g.sections = [
            Gauge.Section(range: 0...40, color: .yellow),
            Gauge.Section(range: 40...60, color: .red)
        ]

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
        g.sectionValueLabelFactory = GaugeCustomSectionLabelFactory()
        g.sections = [
            Gauge.Section(range: 0...25, color: .yellow),
            Gauge.Section(range: 25...50, color: .red),
            Gauge.Section(range: 50...75, color: .yellow),
            Gauge.Section(range: 75...100, color: .blue),
        ]

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

public struct GaugeCustomSectionLabelFactory: GaugeSectionLabelFactory {

    public func make() -> GaugeSectionLabel {
        return GaugeCustomSectionLabel()
    }
}

private struct GaugeCustomSectionLabel: GaugeSectionLabel {

    // MARK: GaugeSectionLabel

    public var view: UIView {
        return _wrapper
    }

    public var activeXConstraint: NSLayoutConstraint?

    public var activeYConstraint: NSLayoutConstraint?

    public func update(
        value: Value,
        formattedValue: String,
        angle: Angle,
        valueInner: CGPoint,
        valueOuter: CGPoint,
        bounds: CGRect,
        trackThickness: CGFloat
    ) {

        _label.text = formattedValue

        let converted = _wrapper.superview?.convert(valueInner, to: _wrapper) ?? .zero
        _indicator.position = converted
        _indicator.transform = CATransform3DRotate(_indicator.transform, (angle - 90).radians, 0, 0, 1)
    }

    // MARK: Init

    init() {
        _wrapper = UIView()
        _label = UILabel()
        _indicator = CAShapeLayer()

        _wrapper.addSubview(_label)
        _label.top(to: _wrapper, offset: 15)
        _label.leading(to: _wrapper, offset: 20)
        _label.bottom(to: _wrapper, offset: -15)
        _label.trailing(to: _wrapper, offset: -20)

        _wrapper.layer.addSublayer(_indicator)

        _label.textColor = .black

        // Draw a triangle, pointing to the top:
        //  .
        // /_\
        // The triangle is in a rectangle 10pt wide and 20pt tall.
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: 5, y: 0))
        trianglePath.addLine(to: CGPoint(x: 10, y: 20))
        trianglePath.addLine(to: CGPoint(x: 0, y: 20))
        trianglePath.close()
        _indicator.path = trianglePath.cgPath
        _indicator.bounds = CGRect(x: 0, y: 0, width: 10, height: 20)

        // Set the anchor point to the top-tip of the triangle for precise
        // rotations and placement.
        _indicator.anchorPoint = CGPoint(x: 0.5, y: 0)

        _indicator.strokeColor = UIColor.green.cgColor
        _indicator.fillColor = UIColor.clear.cgColor
    }

    // MARK: Private properties

    let _wrapper: UIView
    let _label: UILabel
    let _indicator: CAShapeLayer

}
