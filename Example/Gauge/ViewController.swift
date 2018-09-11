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

        return g
    }()

    private lazy var gauge2: Gauge = {
        let g = Gauge(bindingBehaviour: .none)
        g.range = 0...100
        g.value = 100
        g.emptyBottomSliceAngle = 0
        g.minValueLabel.isHidden = true
        g.maxValueLabel.isHidden = true

        return g
    }()
}

