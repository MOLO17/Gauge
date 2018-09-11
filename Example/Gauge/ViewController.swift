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

    }

    private lazy var defaultGauge: Gauge = {
        let g = Gauge(bindingBehaviour: .title)
        g.range = 0...100
        g.value = 50

        return g
    }()
}

