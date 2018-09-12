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
        g.sectionValueLabelInside = false
        g.sectionValueLabelFactory = GaugeCustomSectionLabelFactory()
        g.sections = [
            Gauge.Section(range: 0...10, color: .clear),
            Gauge.Section(range: 10...20, color: .clear),
            Gauge.Section(range: 20...25, color: .clear),
            Gauge.Section(range: 25...30, color: .clear),
            Gauge.Section(range: 30...40, color: .clear),
            Gauge.Section(range: 40...50, color: .clear),
            Gauge.Section(range: 50...60, color: .clear),
            Gauge.Section(range: 60...70, color: .clear),
            Gauge.Section(range: 70...75, color: .clear),
            Gauge.Section(range: 75...80, color: .clear),
            Gauge.Section(range: 80...90, color: .clear),
            Gauge.Section(range: 90...100, color: .clear)
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

        // Now we have to draw the triangle pointing to the track. Will do a
        // a trick, drawing layer that's larger than the bounds. That layer will
        // be added to the _wrapper's superview layer to make things simpler.
        let deltaSize: CGFloat = 20;
        _indicator.frame = bounds.insetBy(dx: -deltaSize, dy: -deltaSize)
        _wrapper.superview?.layer.addSublayer(_indicator)

        // Do some math to compute the vertices of the triangle.
        let radius = bounds.width / 2
        let realOriginX = bounds.midX
        let realOriginY = bounds.midY
        let trianglePoint0 = CGPoint(
            x: deltaSize + realOriginX - cos((180 - angle).normalizedDegrees.radians) * (radius),
            y: deltaSize + realOriginY - sin((180 - angle).normalizedDegrees.radians) * (radius)
        )
        let trianglePoint1 = CGPoint(
            x: deltaSize + realOriginX - cos((180 - angle + 1).normalizedDegrees.radians) * (radius + deltaSize),
            y: deltaSize + realOriginY - sin((180 - angle + 1).normalizedDegrees.radians) * (radius + deltaSize)
        )
        let trianglePoint2 = CGPoint(
            x: deltaSize + realOriginX - cos((180 - angle - 1).normalizedDegrees.radians) * (radius + deltaSize),
            y: deltaSize + realOriginY - sin((180 - angle - 1).normalizedDegrees.radians) * (radius + deltaSize)
        )

        let path = UIBezierPath()
        path.move(to: trianglePoint0)
        path.addLine(to: trianglePoint1)
        path.addLine(to: trianglePoint2)
        path.close()
        _indicator.path = path.cgPath
    }

    // MARK: Init

    init() {
        _wrapper = UIView()
        _label = UILabel()
        _indicator = CAShapeLayer()

        _wrapper.addSubview(_label)
        _label.top(to: _wrapper, offset: 10)
        _label.leading(to: _wrapper, offset: 20)
        _label.bottom(to: _wrapper, offset: -10)
        _label.trailing(to: _wrapper, offset: -20)

        _label.textColor = .black

        _indicator.strokeColor = UIColor.green.cgColor
        _indicator.fillColor = UIColor.clear.cgColor
    }

    // MARK: Private properties

    let _wrapper: UIView
    let _label: UILabel
    let _indicator: CAShapeLayer

}
