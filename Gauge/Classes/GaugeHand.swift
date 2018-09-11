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
    ///
    /// - Parameters:
    ///   - angle: The computed angle (used for the rotation) of the hand. It's
    ///   in cartesian coordinate space. By using the angle for rotation the
    ///   hand should point to the target.
    ///   - innerTarget: The point of the target. It touches on the inner side
    ///   of the track.
    ///   - outerTarget: The point of the target. It touches on the outer side
    ///   of the track.
    ///   - value: The current value of the Gauge.
    ///   - bounds: The bounds of the Gauge.
    func update(
        angle: Angle,
        innerTarget: CGPoint,
        outerTarget: CGPoint,
        value: Value,
        bounds: CGRect
    )
}
