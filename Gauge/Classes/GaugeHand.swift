//
//  GaugeHandle.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 11/01/2018.
//  Copyright © 2018 MOLO17. All rights reserved.
//

import UIKit

/// A protocol used to define a factory and updater to allow dependency
/// injection of custom hands in the `Gauge`.
///
/// A `GaugeHand` represent a hand which shows the current value of the `Gauge`,
/// and a default hand that provides such "visual behavior" is provided. You
/// can create your own class implementing this protocol and have it highlight
/// the current value in a totally different way.
public protocol GaugeHand {

    /// The layer containing the hand. It could be a simple image or a shape
    /// layer that draws the hand. Your bet.
    var layer: CALayer { get }

    /// Update the hand. This is called when the Gauge needs to update the hand.
    /// Possible reasons include bounds changes and obviously value changes.
    /// Values provided are _final_, they take in consideration the current
    /// `Gauge` configuration, such as `origin`, `emptySlice`, etc.
    ///
    /// - Parameters:
    ///   - value: The current value of the Gauge.
    ///   - angle: The computed angle (used for the rotation) of the hand. By
    ///   using the angle for rotation the hand will point to the target in the
    ///   track.
    ///   - valueInner: The point, within the provided bounds, touching the
    ///   inner side of the track at the `Value` position.
    ///   - valueOuter: The point, within the provided bounds, touching the
    ///   outer side of the track at the `Value` position.
    ///   - origin: The origin of the Gauge.
    ///   - originInner: The point, within the provided bounds, touching the inner
    ///   side of the track at the 0 position.
    ///   - originOuter: The point, within the provided bounds, touching the outer
    ///   side of the track at the 0 position.
    ///   - bounds: The bounds of the Gauge.
    ///   - trackThickness: The width of the track of the `Gauge`.
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
    )
}
