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
/// * Section labels: (optional, with default) you can customize the labels and
///   their position, if you want them inside or outside the `Gauge`.
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

    /// An enum that defines the automatic binding behaviour of the `Gauge`
    /// `Value`.
    public enum BindingBehaviour {

        /// Binds the value to the valueLabel.
        case value

        /// Binds the value to the titleLabel.
        case title

        /// Do not perform any automatic binding.
        case none
    }

    /// An enum that defines the dimming of inactive sections.
    public enum InactiveSectionsDimming {

        /// Inactive sections dimming is disabled.
        case none

        /// Inactive sections dimming is enabled, setting the section alpha to
        /// the provided value.
        case enabled(alpha: Float)
    }

    // MARK: Init

    public init() {
        super.init(frame: .zero)

        buildViewHierarchy()
        updateTrackLayerColor()
        rebuildSections()
        updateSections()
        updateStackViewConstraints()
        updateMinMaxValueLabelConstraints()
        updateMinMaxValueLabelText()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        buildViewHierarchy()
        updateTrackLayerColor()
        rebuildSections()
        updateSections()
        updateStackViewConstraints()
        updateMinMaxValueLabelConstraints()
        updateMinMaxValueLabelText()
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

    /// The label used to display the lower bound of the range.
    public private (set) lazy var minValueLabel = self.makeMinMaxValueLabel()

    /// The label used to display the upper bound of the range.
    public private (set) lazy var maxValueLabel = self.makeMinMaxValueLabel()

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
            dimInactiveSectionsIfNeeded()
            updateValueLabel()
        }
    }

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
    /// - SeeAlso: `sortedSections`.
    public var sections: [Section] = [] {
        didSet {
            sortedSections = sections.sorted {
                $0.range.lowerBound < $1.range.lowerBound
            }
            rebuildSections()
            updateSections()
        }
    }

    /// The factory to make the labels displaying the section ranges.
    /// By default, the factory creates simple labels, you can provide your own
    /// to return a different kind of labels.
    /// - SeeAlso: `sections`.
    public var sectionValueLabelFactory: GaugeSectionLabelFactory = DefaultGaugeSectionLabelFactory()

    /// Whether to place the section value labels inside the `Gauge`.
    /// Note: setting this to `false` will place labels outside of the track.
    /// Labels might end up being outside of the bounds of the `Gauge`.
    public var sectionValueLabelInside = true {
        didSet {
            updateSections()
            updateStackViewConstraints()
            updateMinMaxValueLabelConstraints()
        }
    }

    /// Whether inactive sections will be displayed with a lowered alpha, to
    /// help users focus on the value.
    public var inactiveSectionsDimming: InactiveSectionsDimming = .enabled(alpha: 0.3) {
        didSet {
            dimInactiveSectionsIfNeeded()
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
            updateStackViewConstraints()
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
            updateStackViewConstraints()
            updateMinMaxValueLabelConstraints()
            updateHandLayer()
        }
    }

    /// Labels (min/max and section's) will be inset by this value. If you set
    /// it to zero labels will effectively touch the track on the inside.
    /// A positive value moves the labels closer to the center.
    /// If the `Gauge` is set the place section labels outside of the track, a
    /// positive value will move labels farther from the center.
    public var labelInsetMargin: CGFloat = 4 {
        didSet {
            updateSections()
            updateStackViewConstraints()
            updateMinMaxValueLabelConstraints()
        }
    }

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

    /// The hand to use to visually display the value.
    public var hand: GaugeHand = DefaultGaugeHand() {
        didSet {
            buildHandLayerHierarchy(removing: oldValue)
            updateHandLayer()
        }
    }

    /// The binding behaviour to apply.
    public var valueBindingBehaviour: BindingBehaviour = .title

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
        addSubview(mainLabelsStackView)
        mainLabelsStackView.addArrangedSubview(valueLabel)
        mainLabelsStackView.addArrangedSubview(titleLabel)

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

        // Finally, above everything, we'll have the hand.
        buildHandLayerHierarchy(removing: nil)
    }

    /// Builds the layer hierarchy for displaying the current `GaugeHand`.
    ///
    /// - Parameter removing: Optionally remove a prior `GaugeHand`.
    /// - SeeAlso: `hand`.
    private func buildHandLayerHierarchy(removing oldHand: GaugeHand?) {
        oldHand?.layer.removeFromSuperlayer()
        layer.addSublayer(hand.layer)
    }

    /// Updates the `trackLayer` to use the current `trackColor`.
    ///
    /// - SeeAlso: `trackLayer`.
    /// - SeeAlso: `trackColor`.
    private func updateTrackLayerColor() {
        trackLayer.strokeColor = trackColor.cgColor
    }

    /// If the last section has an upper bound that's lower than the `Gauge`
    /// range's upper bound, then include the section to draw the value label
    /// around the track.
    ///
    /// - Returns: The sections to use as basis to draw section labels.
    private func fullSectionsForLabels() -> [Section] {

        if let last = sortedSections.last,
            last.range.upperBound < range.upperBound {
            return sortedSections
        }

        return Array(sortedSections.dropLast())
    }

    /// Re-creates the section tracks and labels, removing the currently visible
    /// ones. Sections will be configured as needed, but their layers will be
    /// empty, so at this point it will look like there are no sections.
    /// This will also set initial constraints for the labels of the sections.
    /// - SeeAlso: `updateSections`.
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

        sectionValueLabels = fullSectionsForLabels()
            .map { section in

                let clamped = section.range.clamped(to: range)

                var label = sectionValueLabelFactory.make()
                sectionsValueLabelContainer.addSubview(label.view)
                label.view.translatesAutoresizingMaskIntoConstraints = false

                let (x, y) = makeConstraints(
                    for: label.view,
                    in: sectionsValueLabelContainer,
                    at: valueToShortArcAngle(clamped.upperBound),
                    placeViewInsideTrack: sectionValueLabelInside
                )
                label.activeXConstraint = x
                label.activeYConstraint = y

                return label
            }
    }

    /// Updates the layout of the sections, effectively showing the range of
    /// each section. Tracks will be redrawn, labels will be updated
    /// (delegation) and placed in the correct place.
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
        zip(sectionValueLabels, fullSectionsForLabels())
            .forEach { label, section in

                // Do some math.
                let clamped = section.range.clamped(to: range)
                let formatted = numberFormatter.string(from: clamped.upperBound as NSNumber) ?? ""
                let angle = valueToShortArcAngle(clamped.upperBound)
                let angleRadians = (180 - angle).normalizedDegrees.radians
                let width = bounds.width / 2
                let realOriginX = bounds.midX
                let realOriginY = bounds.midY

                // Place the label in the final position, updating constraints.
                if let x = label.activeXConstraint,
                    let y = label.activeYConstraint {
                    updateConstraints(x: x, y: y, at: angle, placeViewInsideTrack: sectionValueLabelInside)
                }

                // Delegate label updating.
                label.update(
                    value: clamped.upperBound,
                    formattedValue: formatted,
                    angle: angle,
                    valueInner: CGPoint(
                        x: realOriginX - cos(angleRadians) * (width - trackThickness),
                        y: realOriginY - sin(angleRadians) * (width - trackThickness)
                    ),
                    valueOuter: CGPoint(
                        x: realOriginX - cos(angleRadians) * width,
                        y: realOriginY - sin(angleRadians) * width
                    ),
                    bounds: bounds,
                    trackThickness: trackThickness
                )
            }
    }

    /// Updates the min and max value label constraints. This places the labels
    /// on the sides of the empty slice.
    private func updateMinMaxValueLabelConstraints() {

        let minValueLabelConstraints = makeConstraints(
            for: minValueLabel,
            in: self,
            at: minValueAnglePosition,
            placeViewInsideTrack: sectionValueLabelInside,
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
            placeViewInsideTrack: sectionValueLabelInside,
            oldXConstraint: maxValueLabelXConstraint,
            oldYConstraint: maxValueLabelYConstraint
        )

        maxValueLabelXConstraint = maxValueLabelConstraints.0
        maxValueLabelYConstraint = maxValueLabelConstraints.1
        maxValueLabel.setHugging(.required, for: .horizontal)
    }

    /// Updates the hand layer so it will point or generally display the current
    /// value.
    /// - SeeAlso: `value`.
    private func updateHandLayer() {

        // Do some math...
        let startAngle = valueToShortArcAngle(range.lowerBound)
        let startAngleRadians = startAngle.normalizedDegrees.radians
        let endAngle = valueToShortArcAngle(value)
        let endAngleRadians = (180 - endAngle).normalizedDegrees.radians
        let width = bounds.width / 2
        let realOriginX = bounds.midX
        let realOriginY = bounds.midY

        // ...And delegate hand updating.
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

    /// Updates the min and max value label constraints. This places the labels
    /// in the empty area near the empty slice.
    /// - SeeAlso: `emptySlice`.
    private func updateStackViewConstraints() {

        let stackViewConstraints = makeConstraints(
            for: mainLabelsStackView,
            in: self,
            at: origin,
            placeViewInsideTrack: true,
            oldXConstraint: mainLabelsStackViewXConstraint,
            oldYConstraint: mainLabelsStackViewYConstraint
        )

        mainLabelsStackViewXConstraint = stackViewConstraints.0
        mainLabelsStackViewYConstraint = stackViewConstraints.1
        mainLabelsStackView.setHugging(.required, for: .horizontal)
        mainLabelsStackView.setHugging(.required, for: .vertical)
    }

    /// Updates the content of the minimum and maximum values label, formatting
    /// the range bounds.
    /// - SeeAlso: `range`.
    /// - SeeAlso: `numberFormatter`.
    private func updateMinMaxValueLabelText() {
        minValueLabel.text = numberFormatter.string(from: range.lowerBound as NSNumber)
        maxValueLabel.text = numberFormatter.string(from: range.upperBound as NSNumber)
    }

    /// Updates the labels to display the current `Value`, depending by the
    /// behavior.
    /// - SeeAlso: `valueBindingBehaviour`.
    /// - SeeAlso: `value`.
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

    /// Dims inactive sections, if needed.
    /// - SeeAlso: `inactiveSectionsDimming`.
    private func dimInactiveSectionsIfNeeded() {

        guard case let .enabled(alpha) = inactiveSectionsDimming else { return }

        // First dim all sections.
        sectionTrackLayers.forEach { $0.opacity = alpha }

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
        for view: UIView,
        in containerView: UIView,
        at angle: Angle,
        placeViewInsideTrack: Bool,
        oldXConstraint: NSLayoutConstraint? = nil,
        oldYConstraint: NSLayoutConstraint? = nil
    ) -> (NSLayoutConstraint, NSLayoutConstraint) {

        oldXConstraint?.isActive = false
        oldYConstraint?.isActive = false

        let (xAnchor, yAnchor) = anchorsFor(
            angle: angle,
            of: view,
            placeViewInsideTrack: placeViewInsideTrack
        )

        let labelInset = anchorsInset(
            forAngle: angle,
            placeViewInsideTrack: placeViewInsideTrack
        )

        let x = xAnchor.constraint(equalTo: containerView.centerXAnchor, constant: labelInset.x)
        let y = yAnchor.constraint(equalTo: containerView.centerYAnchor, constant: labelInset.y)

        x.isActive = true
        y.isActive = true

        return (x, y)
    }

    private func updateConstraints(
        x xConstraint: NSLayoutConstraint,
        y yConstraint: NSLayoutConstraint,
        at angle: Angle,
        placeViewInsideTrack: Bool
    ) {

        let labelInset = anchorsInset(
            forAngle: angle,
            placeViewInsideTrack: placeViewInsideTrack
        )
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
    /// |           ╲╱           |
    /// | 157.5  -╲ |  ╱-  22.5  |
    /// |            •           |
    /// | 202.5  -╱ |  ╲- 337.5  |
    /// |           ╱╲           |
    /// |     247.5    292.5     |
    /// +------------------------+
    ///
    /// - Parameters:
    ///   - angle: The value of the angle, which represents the place in the
    ///   circle where the view should be placed..
    ///   - view: The view that should be placed inside the circle (superview).
    ///   It's used to get the anchors.
    ///   - placeViewInsideTrack: Whether the view should stay inside the circle
    ///   delimited by the track. This will effectively make the function return
    ///   the opposite anchor pair.
    /// - Returns: The pairs of layout anchors to use to setup constraints.
    ///   Using those pairs the view can be placed correctly in the superview.
    private func anchorsFor(
        angle: Angle,
        of view: UIView,
        placeViewInsideTrack: Bool
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

        if placeViewInsideTrack {

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

        } else {

            if sliceWidth * 0 ... sliceWidth * 1 ~= targetAngle {
                return (view.leadingAnchor, view.centerYAnchor)
            }
            if sliceWidth * 1 ... sliceWidth * 2 ~= targetAngle {
                return (view.leadingAnchor, view.bottomAnchor)
            }
            if sliceWidth * 2 ... sliceWidth * 3 ~= targetAngle {
                return (view.centerXAnchor, view.bottomAnchor)
            }
            if sliceWidth * 3 ... sliceWidth * 4 ~= targetAngle {
                return (view.trailingAnchor, view.bottomAnchor)
            }
            if sliceWidth * 4 ... sliceWidth * 5 ~= targetAngle {
                return (view.trailingAnchor, view.centerYAnchor)
            }
            if sliceWidth * 5 ... sliceWidth * 6 ~= targetAngle {
                return (view.trailingAnchor, view.topAnchor)
            }
            if sliceWidth * 6 ... sliceWidth * 7 ~= targetAngle {
                return (view.centerXAnchor, view.topAnchor)
            }

            // Catch all:
            // step * 7 ... step * 8 ~= angle + halfStep
            return (view.leadingAnchor, view.topAnchor)
        }
    }

    private func anchorsInset(
        forAngle angle: Angle,
        placeViewInsideTrack: Bool
    ) -> (x: CGFloat, y: CGFloat) {

        let targetAngle = angle.normalizedDegrees
        let radians = targetAngle.radians
        let radius = bounds.width / 2

        let thickness = placeViewInsideTrack ? -trackThickness : trackThickness
        return (
            x: cos(radians) * (radius + thickness - labelInsetMargin),
            y: -sin(radians) * (radius + thickness - labelInsetMargin)
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

    /// The array of sections, sorted by upper bound so they're sequential.
    /// Note: you should use this instead of the original `section` array.
    /// - SeeAlso: `sections`.
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

    /// The view that will contain all the section value labels.
    private lazy var sectionsValueLabelContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// The labels currently displayed to describe the sections ranges.
    /// - SeeAlso: `sections`.
    private var sectionValueLabels = [GaugeSectionLabel]()

    /// The stack view which contains the main labels.
    /// - SeeAlso: `valueLabel`.
    /// - SeeAlso: `titleLabel`.
    private lazy var mainLabelsStackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        return s
    }()

    private var minValueLabelXConstraint: NSLayoutConstraint?
    private var minValueLabelYConstraint: NSLayoutConstraint?

    private var maxValueLabelXConstraint: NSLayoutConstraint?
    private var maxValueLabelYConstraint: NSLayoutConstraint?

    private var mainLabelsStackViewXConstraint: NSLayoutConstraint?
    private var mainLabelsStackViewYConstraint: NSLayoutConstraint?
}
