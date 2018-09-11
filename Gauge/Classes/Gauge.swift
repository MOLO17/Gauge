//
//  Gauge.swift
//  Gauge
//
//  Created by Alessandro Vendruscolo on 11/01/2018.
//  Copyright © 2018 MOLO17. All rights reserved.
//

import TinyConstraints
import UIKit

/// The `Gauge` view is a custom gauge that displays a `Value` in a `Range`.
///
/// **Visuals**
/// The `Gauge` has many options and provide some sensible defaults.
/// * Sections: (optional) it can highlight mulitple sections using different
///   colors. Provide your `Gauge.Section` objects to set them.
/// * Current `Value`: (has defaults) it displays the current `Value` using the
///   `DefaultGaugeHand` and binds the `Value` to a label. This whole thing is
///    configurable, you might even not show the value.
/// * Empty area: (optional, with default) at the bottom there's an arc (which
///   can be 0) which won't be used by the `Gauge` track and leaves room for the
///   `Value` label, in order to display the value in a textual manner. To
///   disable this just set the `emptySlice` to `0` and set the
///   `valueBindingBehaviour` to `.none`.
/// * Min/max values: (optional) at the sides of the the empty area the `Gauge`
///   displays the minimum and maximum values it supports. The `Gauge` exposes
///   the labels, so you can just hide them.
/// * Inactive sections: (optional, with default) The `Gauge` dims the sections
///   (if any) that don't contain the current `Value`.
/// * Offset: (optional, with default) the `Gauge`'s values can easily be offset
///   by providing a different origin `Angle`.
///
/// **Layout**
/// The gauge can have any size and aspect ratio, but the drawing will always be
/// based on a square, with the width of the view used as the side length: the
/// drawing will be vertically centered if the height is greater than the width.
/// The drawing will go outside the view bounds if the width is greater than the
/// height. You should add a constraint to ensure that the view is square or set
/// a square frame.
open class Gauge: UIView {

    // MARK: Types

    /// An enum that defines the automatic behaviour of the gauge value.
    public enum BindingBehaviour {

        /// Binds the value to the valueLabel.
        case value

        /// Binds the value to the titleLabel.
        case title

        /// Do not perform any automatic binding.
        case none
    }

    // MARK: Init

    /// Initializes a new `Gauge` with the provided binding behavior.
    ///
    /// - Parameter bindingBehaviour: The binding behavior to use.
    /// - SeeAlso: `valueBindingBehaviour`.
    public init(bindingBehaviour: BindingBehaviour = .value) {
        valueBindingBehaviour = bindingBehaviour

        super.init(frame: .zero)

        buildViewHierarchy()
        updateTrackLayerColor()
        rebuildSections()
        updateSections()
        updateMinMaxValueLabelConstraints()
        updateMinMaxValueLabelText()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public properties

    /// The range of valid `Value`s displayed by the `Gauge`.
    public var range: ClosedRange<Value> = 0...100 {
        didSet {
            rebuildSections()
            updateSections()
            updateHandLayer()
            updateMinMaxValueLabelText()
        }
    }

    /// The `Value` to display. Changing this will update the hand and the
    /// label (if needed).
    ///
    /// Note that if the `Value` is out of the range bounds the hand will be
    /// pointing to the lower or upper bound of the range, while the label will
    /// show the value text.
    /// - SeeAlso: `valueBindingBehaviour`.
    public var value: Value = 0 {
        didSet {
            updateHandLayer()
            dimInactiveSections()
            updateValueLabel()
        }
    }

    /// The sections of the gauge. By default there isn't any `Section`.
    ///
    /// All sections will be drawn over the main track of the gauge. Sections
    /// will be clamped to the main range, and won't cover the empty arc at the
    /// bottom.
    ///
    /// Note: changing the sections will effectively redraw the tracks and
    /// labels, creating them from scratch. You might need to style them again.
    ///
    /// Internal note: you shouldn't use the sections property. Throughout the
    /// implementation always use `sortedSections` which is what you probably
    /// want.
    public var sections: [Section] = [] {
        didSet {
            sortedSections = sections.sorted {
                $0.range.lowerBound < $1.range.lowerBound
            }
            rebuildSections()
            updateSections()
        }
    }

    /// Whether inactive sections will be displayed with a lowered alpha, to
    /// help users focus on the value.
    public var dimsInactiveSections = true

    /// The lowered alpha value for inactive sections.
    public var inactiveSectionsAlpha: Float = 0.3

    /// The tickness of the track. It's used to draw the main track and the
    /// sections track (if present).
    public var trackThickness: CGFloat = 10 {
        didSet {
            setNeedsLayout()
        }
    }

    /// The color to use when drawing the main track. The main track will be
    /// always visible, at least in the empty slice area.
    /// - SeeAlso: `emptySliceAngle`.
    public var trackColor: UIColor = .lightGray {
        didSet {
            updateTrackLayerColor()
        }
    }

    /// The position of the origin (the minimum `Value`). You can change it to
    /// offset the starting point of the `Gauge` to suit better your
    /// requirements. This changes the location of the `emptySliceAngle` and the
    /// min and max labels, as it effectively _rotates_ the `Gauge`.
    /// Thus, the position of the maximum `Value` will be at
    /// `origin + 360° - emptySliceAngle`.
    public var origin = Angle(radians: .pi * 3 / 2) {
        didSet {
            updateSections()
            updateMinMaxValueLabelConstraints()
            updateHandLayer()
        }
    }

    /// The `Angle` of the slice that will always be empty. The slice is
    /// positioned around the minimum value of the gauge. If you want a gauge
    /// that has a straight base (so a circle cut in half) you'd set this to
    /// 180°.
    /// Changing this changes the _usable_ track length and the position of the
    /// min and max labels.
    /// Note: this is an `Angle` measured at the center of the `Gauge` and
    /// extends from the middle of the `origin`.
    /// - SeeAlso: origin
    public var emptySlice = Angle(radians: .pi / 4) {
        didSet {
            updateSections()
            updateMinMaxValueLabelConstraints()
            updateHandLayer()
        }
    }

    /// Labels (min/max and section's) will be inset by this value. If you set
    /// it to zero labels will effectively touch the track on the inside.
    public var labelInsetMargin: CGFloat = 4

    /// The number formatter to use to format the values displayed by the
    /// `Gauge`.
    ///
    /// The number formatter is used to format these values:
    /// * Min and max range values;
    /// * Current value;
    /// * Section values.
    public var numberFormatter = NumberFormatter() {
        didSet {
            updateMinMaxValueLabelText()
            updateValueLabel()
            updateSections()
        }
    }

    /// The hand to use to visually display the value.
    public var hand: GaugeHand = DefaultGaugeHand() {
        didSet {
            oldValue.layer.removeFromSuperlayer()
            layer.addSublayer(hand.layer)
            updateHandLayer()
        }
    }

    /// The label used to display the lower bound of the range.
    public private (set) lazy var minValueLabel = self.makeMinMaxValueLabel()

    /// The label used to display the upper bound of the range.
    public private (set) lazy var maxValueLabel = self.makeMinMaxValueLabel()

    /// A closure used as factory to make the labels displaying the section
    /// bounds.
    ///
    /// By default, the factory creates simple labels, you can provide your own
    /// factory to return a different kind of labels.
    /// - SeeAlso: `sections`.
    public var makeSectionValueLabel: () -> UILabel = {
        return UILabel()
    }

    /// The labels currently displayed to describe the sections bounds.
    /// - SeeAlso: `sections`.
    public var sectionValueLabels: [UILabel] {
        return _sectionValueLabels.map { $0.label }
    }

    /// The label used to display the `Value`. You can customize it, the guage
    /// by default binds the value to this label and only changes
    /// the `text` property.
    /// This label is above the title label.
    /// - SeeAlso: `valueBindingBehaviour`.
    public private (set) lazy var valueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    /// An optional label that can be used to display any other information.
    /// This label is below the value label, and you can optionally bind the
    /// `Value` to this label, if your design requires it.
    /// - SeeAlso: `valueBindingBehaviour`.
    public private (set) lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    // MARK: UIView overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        updateTrackLayer(trackLayer, startAngle: 360, endAngle: 0)
        updateMinMaxValueLabelConstraints()
        updateHandLayer()
        updateSections()
        updateStackViewConstraints()
    }

    // MARK: Private methods

    /// Builds the view hierarchy and sets view constraints.
    private func buildViewHierarchy() {

        // The track layer is always there and should be below everything.
        layer.addSublayer(trackLayer)

        // Build the view hierarchy.
        addSubview(minValueLabel)
        addSubview(maxValueLabel)
        addSubview(sectionsTrackContainer)
        addSubview(sectionsValueLabelContainer)
        addSubview(measuringStackView)
        measuringStackView.addArrangedSubview(valueLabel)
        measuringStackView.addArrangedSubview(titleLabel)

        // The sections track container will be as big as the gauge itself.
        sectionsTrackContainer.topAnchor.constraint(equalTo: topAnchor)
            .isActive = true
        sectionsTrackContainer.leftAnchor.constraint(equalTo: leftAnchor)
            .isActive = true
        sectionsTrackContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
            .isActive = true
        sectionsTrackContainer.rightAnchor.constraint(equalTo: rightAnchor)
            .isActive = true

        // The sections value label container will be as big as the gauge
        // itself.
        sectionsValueLabelContainer.topAnchor.constraint(equalTo: topAnchor)
            .isActive = true
        sectionsValueLabelContainer.leftAnchor.constraint(equalTo: leftAnchor)
            .isActive = true
        sectionsValueLabelContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
            .isActive = true
        sectionsValueLabelContainer.rightAnchor.constraint(equalTo: rightAnchor)
            .isActive = true

        // The stack view will be positioned to the empty space at the bottom of the gauge
        measuringStackView.centerXToSuperview()
        measuringStackViewYConstraint = measuringStackView.bottomAnchor
            .constraint(equalTo: bottomAnchor)
        measuringStackViewYConstraint?.isActive = true

        // Finally, above everything, we'll have the hand.
        layer.addSublayer(hand.layer)
    }

    private func updateTrackLayerColor() {
        trackLayer.strokeColor = trackColor.cgColor
    }

    /// Re-creates the section tracks and labels.
    private func rebuildSections() {

        // Redraw all section tracks, which highlight with their own color each
        // values in the main range.
        sectionsTrackContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        sectionTrackLayers = sortedSections.map {
            let layer = makeTrackLayer()
            layer.strokeColor = $0.color.cgColor
            sectionsTrackContainer.layer.addSublayer(layer)

            return layer
        }

        // Re-create all value labels, which will provide the bounds information
        // about each section (drawn above).
        // Sort by the lowerbound, so we're sure that the section at index 0
        // will be displayed before the one at index 1.
        sectionsValueLabelContainer.subviews.forEach { $0.removeFromSuperview() }
        _sectionValueLabels = sortedSections
            .dropLast()
            .map { section in
                let clamped = section.range.clamped(to: range)
                let label = makeSectionValueLabel()
                sectionsValueLabelContainer.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                let (x, y) = makeConstraints(
                    for: label,
                    in: sectionsValueLabelContainer,
                    at: valueToShortArcAngle(clamped.upperBound)
                )
                return (label: label, xConstraint: x, yConstraint: y)
            }
    }

    /// Updates the layout of the sections. Tracks will be redrawn, labels will
    /// be moved.
    private func updateSections() {

        // Redraw all section tracks, which highlight with their own color each
        // values in the main range.
        zip(sectionTrackLayers, sortedSections)
            .forEach { layer, section in
                let clamped = section.range.clamped(to: range)
                updateTrackLayer(
                    layer,
                    startAngle: valueToShortArcAngle(clamped.lowerBound),
                    endAngle: valueToShortArcAngle(clamped.upperBound)
                )
            }

        // Re-create all value labels, which will provide the bounds information
        // about each section (drawn above).
        // Sort by the lowerbound, so we're sure that the section at index 0
        // will be displayed before the one at index 1.
        zip(_sectionValueLabels, sortedSections.dropLast())
            .forEach { label, section in
                let clamped = section.range.clamped(to: range)
                label.label.text = numberFormatter.string(from: clamped.upperBound as NSNumber)
                updateConstraints(x: label.xConstraint, y: label.yConstraint, at: valueToShortArcAngle(clamped.upperBound))
            }
    }

    /// Updates the min and max value label constraints. This places the labels
    /// on the sides of the empty bottom slice.
    private func updateMinMaxValueLabelConstraints() {

        let minValueLabelConstraints = makeConstraints(
            for: minValueLabel,
            in: self,
            at: minValueAnglePosition,
            oldXConstraint: minValueLabelXConstraint,
            oldYConstraint: minValueLabelYConstraint
        )

        minValueLabelXConstraint = minValueLabelConstraints.0
        minValueLabelYConstraint = minValueLabelConstraints.1
        minValueLabel.setCompressionResistance(.required, for: .horizontal)

        let maxValueLabelConstraints = makeConstraints(
            for: maxValueLabel,
            in: self,
            at: maxValueAnglePosition,
            oldXConstraint: maxValueLabelXConstraint,
            oldYConstraint: maxValueLabelYConstraint
        )

        maxValueLabelXConstraint = maxValueLabelConstraints.0
        maxValueLabelYConstraint = maxValueLabelConstraints.1
        maxValueLabel.setHugging(.required, for: .horizontal)
    }


    private func updateHandLayer() {

        // Do some math
        let startAngle = valueToShortArcAngle(range.lowerBound)
        let startAngleRadians = startAngle.normalizedDegrees.radians
        let endAngle = valueToShortArcAngle(value)
        let endAngleRadians = (180 - endAngle).normalizedDegrees.radians
        let width = bounds.width / 2
        let realOriginX = bounds.midX
        let realOriginY = bounds.midY

        // and delegate hand updating
        hand.update(
            value: value,
            angle: endAngle,
            valueInner: CGPoint(
                x: realOriginX - cos(endAngleRadians) * (width - trackThickness),
                y: realOriginY - sin(endAngleRadians) * (width - trackThickness)
            ),
            valueOuter: CGPoint(
                x: realOriginX - cos(endAngleRadians) * width,
                y: realOriginY - sin(endAngleRadians) * width
            ),
            origin: origin,
            originInner: CGPoint(
                x: realOriginX - cos(startAngleRadians) * (width - trackThickness),
                y: realOriginY - sin(startAngleRadians) * (width - trackThickness)
            ),
            originOuter: CGPoint(
                x: realOriginX - cos(startAngleRadians) * width,
                y: realOriginY - sin(startAngleRadians) * width
            ),
            bounds: bounds,
            trackThickness: trackThickness
        )
    }

    private func updateStackViewConstraints() {
        measuringStackViewYConstraint?.constant = -trackThickness / 2
    }

    private func updateMinMaxValueLabelText() {
        minValueLabel.text = numberFormatter.string(from: range.lowerBound as NSNumber)
        maxValueLabel.text = numberFormatter.string(from: range.upperBound as NSNumber)
    }

    private func updateValueLabel() {
        switch valueBindingBehaviour {
        case .value:
            valueLabel.text = numberFormatter.string(from: value as NSNumber)
        case .title:
            titleLabel.text = numberFormatter.string(from: value as NSNumber)
        case .none:
            break
        }
    }

    private func dimInactiveSections() {

        guard dimsInactiveSections else { return }

        // First dim all sections.
        sectionTrackLayers.forEach { $0.opacity = inactiveSectionsAlpha }

        // Now we have to find the section of the current value, and get its
        // corresponding layer.
        let currentSectionTrackLayer: CAShapeLayer?

        // The first step is to check if we can find that section, because the
        // value is contained in the sections range. We have to reverse the
        // array because adding a sublayer inserts it at index 0, so the layer
        // at index 0 corresponds to the last section actually. If we're
        // displaying a value that's out of range, we either highlight the first
        // or last section, depending by the value.
        if let reversedIndex = sortedSections.reversed().index(where: {
            $0.range ~= self.value
        }) {
            let targetSection = sectionTrackLayers.index(before: reversedIndex.base)
            currentSectionTrackLayer = sectionTrackLayers[targetSection]
        } else if let lowestRange = sortedSections.first, self.value <= lowestRange.range.lowerBound {
            currentSectionTrackLayer = sectionTrackLayers.first
        } else {
            currentSectionTrackLayer = sectionTrackLayers.last
        }

        // We hope to have found something. In that case set the opacity back to
        // 1 so it's marked as _active_.
        currentSectionTrackLayer?.opacity = 1
    }

    // MARK: Helpers

    /// The value is not normalized, as we're not drawing it.
    func valueToFullCircleAngle(_ value: Value) -> Angle {

        // Make sure the value is contained in the range, which thus can be
        // expressed in the 0°...360° range.
        let clamped = max(min(value, range.upperBound), range.lowerBound)

        // Get the length of the range so we can port it the 0...360° range
        let rangeLength = range.upperBound - range.lowerBound

        // And finally get the value in that 0...360° range.
        let valueStartingFromZero = clamped - range.lowerBound

        // Make sure not to divide by 0. It can crash the simulator.
        let dividend = rangeLength > 0 ? rangeLength : 1

        return Angle(valueStartingFromZero * 360 / dividend)

    }

    /// The value is not normalized, as we're not drawing it.
    func valueToShortArcAngle(_ value: Value) -> Angle {

        // Place the value in the "full" circle.
        let fullAngle = valueToFullCircleAngle(value)

        // And then take in consideration the lower arc length, as it will "eat
        // up" space by remaining empty.
        let shorterAnglePercentage = 100 * (360 - emptySlice) / 360
        let shorterAngle = fullAngle * shorterAnglePercentage / 100

        // Consider that the min value is on the left side of the bottom empty
        // slice, so the min value should be considered the 0-value. From there
        // values go clockwise.
        return (minValueAnglePosition - shorterAngle)
    }

    private func updateTrackLayer(_ layer: CAShapeLayer, startAngle: Angle, endAngle: Angle) {

        layer.frame = bounds

        // Note that the Angle type it's not in the same coordinate system of
        // UIKit.
        layer.path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: bounds.width / 2 - trackThickness / 2,
            startAngle: (360 - startAngle).radians,
            endAngle: (360 - endAngle).radians,
            clockwise: true
        ).cgPath
        layer.lineWidth = trackThickness
    }

    // 1) Remove old constraints
    // 2) Calculate the new anchors & insets
    // 3) Apply them
    // 4) ???
    // 5) Profit
    @discardableResult
    private func makeConstraints(
        for label: UILabel,
        in containerView: UIView,
        at angle: Angle,
        oldXConstraint: NSLayoutConstraint? = nil,
        oldYConstraint: NSLayoutConstraint? = nil
    ) -> (NSLayoutConstraint, NSLayoutConstraint) {

        oldXConstraint?.isActive = false
        oldYConstraint?.isActive = false

        let (xAnchor, yAnchor) = anchorsFor(
            angle: angle,
            of: label
        )

        let labelInset = anchorsInset(forAngle: angle)

        let x = xAnchor.constraint(equalTo: containerView.centerXAnchor, constant: labelInset.x)
        let y = yAnchor.constraint(equalTo: containerView.centerYAnchor, constant: labelInset.y)

        x.isActive = true
        y.isActive = true

        return (x, y)
    }

    private func updateConstraints(
        x xConstraint: NSLayoutConstraint,
        y yConstraint: NSLayoutConstraint,
        at angle: Angle
    ) {

        let labelInset = anchorsInset(forAngle: angle)
        xConstraint.constant = labelInset.x
        yConstraint.constant = labelInset.y
    }

    /// Returns the layout attributes to use in a constraint-based layout to
    /// place a view in a circle.
    ///
    /// Using those attributes the view will be centered in the target "slice"
    /// of the circle. For example, providing a value of 10° the returned slice
    /// will be the rightmost: `(x: .trailing, y: .centerY)`.
    /// +------------------------+
    /// |      115.5    67.5     |
    /// |           ╲╱          |
    /// | 157.5  -╲ |  ╱-  22.5 |
    /// |            •           |
    /// | 202.5  -╱ |  ╲- 337.5 |
    /// |           ╱╲          |
    /// |     247.5    292.5     |
    /// +------------------------+
    ///
    /// - Parameters:
    ///   - angle: The value of the angle, which represents the place in the
    ///   circle where the view should be placed..
    ///   - view: The view that should be placed inside the circle (superview).
    ///   It's used to get the anchors.
    /// - Returns: The pairs of layout anchors to use to setup constraints.
    ///   Using those pairs the view can be placed correctly in the superview.
    private func anchorsFor(
        angle: Angle,
        of view: UIView
    ) -> ((NSLayoutXAxisAnchor, NSLayoutYAxisAnchor)) {

        let sliceWidth = Angle(45) // 360° / 8
        let halfStep = sliceWidth / 2

        // We divide the view in 8 equal slices, representing the area in which
        // the view should be placed, but we want it to be centered.
        // Instead of doing this (shifting 8 ranges by `-halfStep`) we simply
        // shift the angle forward by `+halfStep`. Note that the target angle
        // is normalized, as it might be outside of the 0...360 range.
        // +----------------------+          +----------------------+
        // |     115.5    67.5    |          |          90          | <== 72.5
        // |                      | <== 50   |   135           45   |
        // | 157.5           22.5 |          |                      | <== 22.5
        // |                      | <== 0    | 180                0 |
        // | 202.5          337.5 |          |                      |
        // |                      |          |   225          315   |
        // |    247.5    292.5    |          |         270          |
        // +----------------------+          +----------------------+

        let targetAngle = (angle + halfStep).normalizedDegrees

        if sliceWidth * 0 ... sliceWidth * 1 ~= targetAngle {
            return (view.trailingAnchor, view.centerYAnchor)
        }
        if sliceWidth * 1 ... sliceWidth * 2 ~= targetAngle {
            return (view.trailingAnchor, view.topAnchor)
        }
        if sliceWidth * 2 ... sliceWidth * 3 ~= targetAngle {
            return (view.centerXAnchor, view.topAnchor)
        }
        if sliceWidth * 3 ... sliceWidth * 4 ~= targetAngle {
            return (view.leadingAnchor, view.topAnchor)
        }
        if sliceWidth * 4 ... sliceWidth * 5 ~= targetAngle {
            return (view.leadingAnchor, view.centerYAnchor)
        }
        if sliceWidth * 5 ... sliceWidth * 6 ~= targetAngle {
            return (view.leadingAnchor, view.bottomAnchor)
        }
        if sliceWidth * 6 ... sliceWidth * 7 ~= targetAngle {
            return (view.centerXAnchor, view.bottomAnchor)
        }

        // Catch all:
        // step * 7 ... step * 8 ~= angle + halfStep
        return (view.trailingAnchor, view.bottomAnchor)
    }

    private func anchorsInset(forAngle angle: Angle) -> (x: CGFloat, y: CGFloat) {

        let targetAngle = angle.normalizedDegrees
        let radians = targetAngle.radians
        let radius = bounds.width / 2

        return (
            x: cos(radians) * (radius - trackThickness - labelInsetMargin),
            y: -sin(radians) * (radius - trackThickness - labelInsetMargin)
        )
    }

    private func makeTrackLayer() -> CAShapeLayer {
        let l = CAShapeLayer()
        l.fillColor = nil
        return l
    }

    private func makeMinMaxValueLabel() -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    // MARK: - Private properties

    /// The binding behaviour to apply.
    private let valueBindingBehaviour: BindingBehaviour

    /// The position around the track where the maximum value (range.upperBound)
    /// lies.
    private var minValueAnglePosition: Angle {
        return (origin - emptySlice / 2).normalizedDegrees
    }

    /// The position around the track where the minimum value (range.lowerBound)
    /// lies.
    private var maxValueAnglePosition: Angle {
        return (origin + emptySlice / 2).normalizedDegrees
    }

    private lazy var trackLayer = self.makeTrackLayer()

    private var sortedSections = [Section]()

    /// The view that will contain all the section tracks (which are just
    /// layers).
    private lazy var sectionsTrackContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// The layers currently displayed to highlight the sections bounds.
    private var sectionTrackLayers = [CAShapeLayer]()

    /// The labels currently displayed to show the sections bounds values. We
    /// also store the x/y constraints for easy updates.
    private var _sectionValueLabels = [(label: UILabel, xConstraint: NSLayoutConstraint, yConstraint: NSLayoutConstraint)]()

    /// The view that will contain all the section value labels.
    private lazy var sectionsValueLabelContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// The stack view which contains the measuring.
    private lazy var measuringStackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        return s
    }()

    private var minValueLabelXConstraint: NSLayoutConstraint?
    private var minValueLabelYConstraint: NSLayoutConstraint?

    private var maxValueLabelXConstraint: NSLayoutConstraint?
    private var maxValueLabelYConstraint: NSLayoutConstraint?

    private var measuringStackViewYConstraint: NSLayoutConstraint?
}
