//
//  DefaultGaugeSectionLabel.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 12/09/2018.
//

import UIKit

/// A default factory which creates `DefaultGaugeSectionLabel`.
public struct DefaultGaugeSectionLabelFactory: GaugeSectionLabelFactory {

    public func make() -> GaugeSectionLabel {
        return DefaultGaugeSectionLabel()
    }
}

/// A default section label that's used by the `Gauge`.
///
/// It's a simple black hand that stays in the center of the Gauge and it's
/// rotated accordingly, so it points to the current value in the Gauge range.
public struct DefaultGaugeSectionLabel: GaugeSectionLabel {

    // MARK: GaugeSectionLabel

    public var view: UIView {
        return _label
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
    }

    // MARK: Private properties

    let _label = UILabel()
}
