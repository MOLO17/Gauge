//
//  Angle.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 11/01/2018.
//  Copyright © 2018 MOLO17. All rights reserved.
//

import UIKit

/// A type that represents an angle, in degrees. Has initializers and properties
/// suitable for radians conversion.
/// The Angle type follows geometrical rules. 0 is in the "right side"
/// (x: 1, y: 0) and goes counter-clockwise.
public typealias Angle = CGFloat

public extension Angle {

    /// The normalized degrees value [0..<360].
    var normalizedDegrees: Angle {
        return (self
            .truncatingRemainder(dividingBy: 360)
            + 360
            )
            .truncatingRemainder(dividingBy: 360)
    }

    /// The radians value.
    var radians: Angle {
        return self * Angle.pi / 180
    }

    /// Initializes a new Angle with the provided degrees value.
    init(degrees: Angle) {
        self = degrees
    }

    /// Initializes a new Angle with the provided radians value.
    init(radians: Angle) {
        self = radians * 180 / Angle.pi
    }

}
