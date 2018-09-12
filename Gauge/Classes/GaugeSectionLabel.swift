//
//  GaugeSectionLabel.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 12/09/2018.
//

import Foundation

/// A protocol used to define a factory to allow dependency injection of custom
/// labels in the `Gauge`.
public protocol GaugeSectionLabelFactory {

    func make() -> GaugeSectionLabel

}

/// A protocol defining a label for `Gauge`'s section labels.
///
/// Although it refers to labels, you can use any component to indicate the
/// bounds of the `Section`s, even a simple dot.
/// A default `Section` label that displays the range bounds is provided. You
/// can create your own class implementing this protocol and have it highlight
/// the `Section` `Value`s in a totally different way.
public protocol GaugeSectionLabel {

    /// The view displaying the range. It could be a simple label or a different
    /// view such as a dot. Your bet
    var view: UIView { get }

    /// The current constraint for the x axis. This is used by the `Gauge` to
    /// place the label in the appropriate place.
    var activeXConstraint: NSLayoutConstraint? { get set }

    /// The current constraint for the y axis. This is used by the `Gauge` to
    /// place the label in the appropriate place.
    var activeYConstraint: NSLayoutConstraint? { get set }

    /// Update the view. This is called when the `Gauge` needs to update the
    /// sections labels. Possible reasons include bounds changes and obviously
    /// `Section`s changes.
    /// Values provided are _final_, they take in consideration the current
    /// `Gauge` configuration, such as `origin`, `emptySlice`, etc.
    ///
    /// - Parameters:
    ///   - value: The `Value` of the `Section` that's going to be displayed.
    ///   - formattedValue: The string representation of the `Value`.
    ///   - angle: The computed angle (used for the rotation) of the `Section`
    ///   range to display. By using the angle for rotation the hand will point
    ///   to the target in the track.
    ///   - valueInner: The point, within the provided bounds, touching the
    ///   inner side of the track at the `Value` position.
    ///   - valueOuter: The point, within the provided bounds, touching the
    ///   outer side of the track at the `Value` position.
    ///   - bounds: The bounds of the Gauge.
    ///   - trackThickness: The width of the track of the `Gauge`.
    func update(
        value: Value,
        formattedValue: String,
        angle: Angle,
        valueInner: CGPoint,
        valueOuter: CGPoint,
        bounds: CGRect,
        trackThickness: CGFloat
    )
}
