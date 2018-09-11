//
//  GaugeSection.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 11/01/2018.
//  Copyright © 2018 MOLO17. All rights reserved.
//

import UIKit

public extension Gauge {

    /// A section of the main range in a `Gauge`.
    ///
    /// For example, you have the main range represented by `0...100`, and you
    /// want to highlight the `0...25` range with a different color. You can
    /// create a `Section` with that range and provide its color.
    /// Note: it's important that the scale is the same.
    public struct Section {

        public init(range: ClosedRange<Value>, color: UIColor) {
            self.range = range
            self.color = color
        }

        /// The range of the section.
        let range: ClosedRange<Value>

        /// The color to use to hightlight the section.
        let color: UIColor
    }
}
