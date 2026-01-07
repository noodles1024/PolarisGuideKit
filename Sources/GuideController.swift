//
//  GuideController.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/6/19.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

// MARK: - BlockAllGestureRecognizer

/// A gesture recognizer that immediately enters the began state to block external gestures.
///
/// This custom gesture recognizer is used to prevent external gestures (such as navigation
/// swipe-back and scroll view panning) from being recognized while the guide overlay is displayed.
private final class BlockAllGestureRecognizer: UIGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .changed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}

// MARK: - GuideDismissReason

/// The reason why the guide was dismissed.
public enum GuideDismissReason {
    /// The user completed all steps in the guide sequence.
    case completed
    /// The user tapped the skip button.
    case skipped
    /// The user tapped outside the focus area (when `dismissesOnOutsideTap` is enabled).
    case outsideTap
    /// The guide was dismissed by a `GuideAutoCompleter`.
    case completerTriggered
    /// The guide was dismissed programmatically by calling `hide()`.
    case programmatic
}

// MARK: - GuideDismissContext

/// Context information when the guide is dismissed.
public struct GuideDismissContext {
    /// The reason for dismissal.
    public let reason: GuideDismissReason
    /// The step that was active when dismissed.
    public let step: GuideStep?
    /// The index of the step that was active when dismissed.
    public let lastStepIndex: Int
    /// The total number of steps in the guide.
    public let totalSteps: Int
}

// MARK: - Typealiases

/// Called when a guide event occurs (e.g. step changed).
public typealias GuideControllerEventHandler = (_ controller: GuideController) -> Void

// MARK: - GuideController

/// Orchestrates a multi-step guide/onboarding flow.
///
/// `GuideController` manages a sequence of steps, handling:
/// - Display of highlight overlays and companion views
/// - Navigation between guide steps
/// - Plugin event dispatch for step extensions
/// - Event forwarding and completion detection
///
/// Example usage:
/// ```swift
/// let step1 = GuideStep()
/// step1.focusView = someButton
/// step1.buddyView = instructionView
///
/// let controller = GuideController(hostView: view, steps: [step1])
/// controller.onDismiss = { controller, context in
///     print("Guide dismissed: \(context.reason)")
/// }
/// controller.show()
/// ```
public final class GuideController: NSObject {
    
    // MARK: - Properties
    
    /// The view that hosts the guide overlay.
    ///
    /// If `nil`, the key window is used as the host.
    public private(set) weak var hostView: UIView?
    
    /// Index of the currently displayed guide item.
    ///
    /// - Note: Returns `-1` when no item is showing or before `show()` is called.
    public private(set) var currentStepIndex: Int = -1
    
    /// Closure called when the current guide item changes.
    public var onStepChange: GuideControllerEventHandler?
    
    /// Closure called when the guide is dismissed for any reason.
    ///
    /// Use this callback to handle all dismissal scenarios uniformly.
    /// The context provides detailed information including the reason,
    /// the last active step, and progress information.
    public var onDismiss: ((_ controller: GuideController, _ context: GuideDismissContext) -> Void)?
    
    /// All guide items in this sequence.
    public private(set) var steps: [GuideStep] = []

    /// Plugins registered for this guide controller.
    public private(set) var plugins: [GuidePlugin] = []
    
    /// Controls whether step transitions are animated.
    ///
    /// When `true`, the highlight mask animates smoothly between steps.
    /// When `false` (the default), the mask changes immediately without animation.
    ///
    /// - Note: In some cases, enabling animation may cause visual tearing or
    ///   unexpected effects, particularly when:
    ///   - Using `additionalHighlightPaths` with complex shapes
    ///   - The highlight areas between consecutive steps differ significantly in size or position
    ///
    ///   In such scenarios, it is recommended to keep this property set to `false`.
    public var animatesStepTransition: Bool = false
    
    /// The duration of animations for showing the guide and transitioning between steps.
    ///
    /// This value is used for:
    /// - The fade-in animation when `show(animated:)` is called with `animated: true`
    /// - The mask transition animation between steps when `animatesStepTransition` is `true`
    ///
    /// The default value is `0.25` seconds.
    public var animationDuration: TimeInterval = 0.25 {
        didSet {
            overlayView.animationDuration = animationDuration
        }
    }
    
    private let containerView: GuideContainerView
    private let overlayView: GuideOverlayView
    
    /// A gesture recognizer that blocks external gestures while the guide is displayed.
    /// Added to hostView to intercept all touches including those in focusView area.
    private lazy var blockingGesture: BlockAllGestureRecognizer = {
        let gesture = BlockAllGestureRecognizer(target: self, action: #selector(handleBlockingGesture(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        gesture.delaysTouchesBegan = false
        return gesture
    }()
    
    @objc private func handleBlockingGesture(_ gesture: UIGestureRecognizer) {
        // Empty implementation - the gesture just needs to be recognized to block others.
    }

    
    // MARK: - Initialization
    
    public override convenience init() {
        self.init(hostView: nil, steps: [], plugins: [])
    }
    
    /// Creates a guide controller with the specified host view and initial steps.
    ///
    /// - Parameters:
    ///   - hostView: The view that will host the guide overlay. If `nil`, the key window is used.
    ///   - steps: Initial steps for the sequence. Invalid steps are automatically filtered out.
    ///   - plugins: Plugins that will receive guide lifecycle events.
    ///
    /// - Important: In debug builds, this initializer will `fatalError` if any focus view is not a
    ///              descendant of the resolved host view.
    public init(hostView: UIView?, steps: [GuideStep] = [], plugins: [GuidePlugin] = []) {
        self.hostView = hostView
        let bounds = hostView?.bounds ?? UIScreen.main.bounds
        self.containerView = GuideContainerView(frame: bounds)
        self.overlayView = GuideOverlayView(hostView: hostView)
        self.plugins = plugins
        super.init()
                
        overlayView.onOutsideTap = { [weak self] in
            guard let self = self else { return }
            self.performDismiss(reason: .outsideTap)
        }
        
        addOverlayToContainerIfNeeded()
        
        for step in steps {
            let illegal = isFocusViewIllegal(step.focusView)
            #if DEBUG
            if illegal {
                var errorMsg = "Focus view is illegal:\(step.focusView?.description ?? "nil")\n"
                errorMsg += "Focus view must be a descendant of hostView; "
                errorMsg += "key window will act as hostView if hostView is nil. "
                errorMsg += "Check your focus view and hostView.\n"
                fatalError(errorMsg)
            }
            #endif
            if step.isValid && !illegal {
                self.steps.append(step)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// focusView must not be hostView itself, and must be descendant
    /// of hostView. Otherwise, it is illegal.
    private func isFocusViewIllegal(_ view: UIView?) -> Bool {
        guard let view = view else {
            return false
        }
        guard let host = overlayView.resolvedHostView() else {
            return false
        }
        if view === host || !view.isDescendant(of: host) {
            return true
        }
        return false
    }
    
    /// Returns the currently displayed step.
    ///
    /// - Returns: The step at `currentStepIndex`, or `nil` if no step is showing.
    public func currentStep() -> GuideStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }

    private func makeContext(for step: GuideStep, index: Int) -> GuideStepContext {
        return GuideStepContext(
            hostView: overlayView.resolvedHostView(),
            containerView: containerView,
            overlayView: overlayView,
            focusView: step.focusView,
            buddyView: step.buddyView,
            step: step,
            stepIndex: index
        )
    }

    private func dispatch(_ event: GuideEvent, step: GuideStep, index: Int) {
        guard !plugins.isEmpty else { return }
        let context = makeContext(for: step, index: index)
        for plugin in plugins {
            plugin.handle(event, context: context)
        }
    }
    
    private func configureCurrentStep() {
        guard let step = currentStep() else { return }
        
        addOverlayToContainerIfNeeded()
        overlayView.setStep(step, animated: animatesStepTransition)
        
        if let completer = step.completer {
            completer.onTrigger = { [weak self] _ in
                guard let self = self else { return }
                self.performDismiss(reason: .completerTriggered)
            }
            completer.enable()
        }
        
        if let buddyView = step.buddyView {
            buddyView.onAction = { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .next:
                    self.showNextStepOrComplete()
                case .skip:
                    self.performDismiss(reason: .skipped)
                }
            }
            
            addBuddyViewToContainer(buddyView)
            
            if let focusView = step.focusView, let shadowView = overlayView.shadowOfFocusView {
                let buddyLayoutGuide = step.focusStyle.buddyLayoutGuide(for: focusView, shadowView: shadowView)
                buddyView.updateLayout(referenceLayoutGuide: buddyLayoutGuide, focusView: focusView)
            }
        }
    }
    
    private func addOverlayToContainerIfNeeded() {
        if overlayView.superview != containerView {
            containerView.addSubview(overlayView)
            NSLayoutConstraint.activate([
                overlayView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                overlayView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
                overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
    }
    
    private func addBuddyViewToContainer(_ buddyView: UIView) {
        buddyView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buddyView)
        
        NSLayoutConstraint.activate([
            buddyView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            buddyView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            buddyView.topAnchor.constraint(equalTo: containerView.topAnchor),
            buddyView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func showNextStepOrComplete() {
        let success = showNextStep()
        if success {
            onStepChange?(self)
        }
        if !success {
            performDismiss(reason: .completed)
        }
    }
    
    deinit {
        // Ensure blocking gesture is removed even if hideInternal() fails for some reason
        blockingGesture.view?.removeGestureRecognizer(blockingGesture)
        // Use hideInternal() to avoid triggering callbacks during deallocation
        hideInternal()
    }
    
    // MARK: - Public Methods
    
    /// Registers a plugin to receive guide lifecycle events.
    public func registerPlugin(_ plugin: GuidePlugin) {
        guard !plugins.contains(where: { $0 === plugin }) else { return }
        plugins.append(plugin)
    }
    
    /// Unregisters a previously registered plugin.
    public func unregisterPlugin(_ plugin: GuidePlugin) {
        plugins.removeAll { $0 === plugin }
    }
    
    /// Sets the overlay mask color.
    ///
    /// - Parameter color: The desired color for the semi-transparent mask.
    public func setOverlayColor(_ color: UIColor) {
        overlayView.maskColor = color
    }
    
    /// Refreshes the overlay mask to reflect the current focus view's position and size.
    ///
    /// Call this method when the focus view's frame changes externally (e.g., due to layout updates,
    /// animations, or content changes) and you need to update the highlight mask accordingly.
    ///
    /// - Parameter animated: Whether to animate the mask transition. Defaults to `false`.
    public func refreshOverlay(animated: Bool = false) {
        overlayView.refreshMask(animated: animated)
    }
    
    /// Adds a guide item to the sequence.
    ///
    /// If this is the first item and the guide is already showing, the item is displayed immediately.
    ///
    /// - Parameter item: The guide item to add.
    /// - Returns: `true` if the item was added successfully; `false` if invalid or already present.
    @discardableResult
    public func addStep(_ step: GuideStep) -> Bool {
        if !step.isValid {
            return false
        }
        
        // Avoid duplicates (identity-based).
        if steps.contains(where: { $0 === step }) {
            return false
        }
        
        steps.append(step)
        
        // If this is the first step and the guide is already visible, show it immediately.
        if steps.count == 1 && isShown() {
            showStep(at: 0)
        }
        
        return true
    }
    
    /// Advances to the next guide item in the sequence.
    ///
    /// - Returns: `true` if there was a next item to show; `false` if already at the end.
    @discardableResult
    public func showNextStep() -> Bool {
        if currentStepIndex + 1 >= steps.count {
            return false
        }
        return showStep(at: currentStepIndex + 1)
    }
    
    /// Displays the guide item at the specified index.
    ///
    /// If the index matches the current item, the mask is refreshed without changing items.
    ///
    /// - Parameter index: The zero-based index of the item to display.
    /// - Returns: `true` if the item was shown; `false` if the index is out of bounds.
    @discardableResult
    public func showStep(at index: Int) -> Bool {
        if index < 0 || index >= steps.count {
            return false
        }
        
        if currentStepIndex == index {
            if let step = currentStep() {
                dispatch(.stepWillShow, step: step, index: index)
                refreshOverlay(animated: false)
                dispatch(.stepDidShow, step: step, index: index)
            }
            return true
        }
        
        let previousIndex = currentStepIndex
        let previousStep = currentStep()
        
        if let previousStep = previousStep {
            dispatch(.stepWillHide, step: previousStep, index: previousIndex)
            previousStep.buddyView?.removeFromSuperview()
            previousStep.completer?.disable()
            dispatch(.stepDidHide, step: previousStep, index: previousIndex)
        }
        
        currentStepIndex = index
        guard let step = currentStep() else { return false }
        
        dispatch(.stepWillShow, step: step, index: index)
        configureCurrentStep()
        dispatch(.stepDidShow, step: step, index: index)
        
        return true
    }
    
    /// Displays the guide overlay and begins the guide sequence.
    ///
    /// If already showing, this method returns `true` without changes.
    /// The first guide item (or the current item if resuming) is displayed.
    ///
    /// - Parameter animated: Whether to animate the appearance of the guide overlay. Defaults to `false`.
    /// - Returns: `true` if the guide was shown; `false` if there are no guide items.
    @discardableResult
    public func show(animated: Bool = false) -> Bool {
        if steps.isEmpty {
            return false
        }
        
        if isShown() {
            return true
        }
        
        guard let decidedHostView = overlayView.resolvedHostView() else {
            return false
        }
        if containerView.superview != nil && containerView.superview != decidedHostView {
            containerView.removeFromSuperview()
        }
        
        if containerView.superview == nil {
            decidedHostView.addSubview(containerView)
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: decidedHostView.leftAnchor),
                containerView.rightAnchor.constraint(equalTo: decidedHostView.rightAnchor),
                containerView.topAnchor.constraint(equalTo: decidedHostView.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: decidedHostView.bottomAnchor)
            ])
            decidedHostView.layoutIfNeeded()
        }
        
        // Add blocking gesture to hostView to intercept all touches
        if blockingGesture.view == nil {
            decidedHostView.addGestureRecognizer(blockingGesture)
        }
        blockingGesture.isEnabled = true
        requireExternalGesturesToFail(in: decidedHostView)
        
        // Show the first step (or resume).
        let indexToShow = currentStepIndex < 0 ? 0 : currentStepIndex
        let stepToShow = steps[indexToShow]
        dispatch(.guideWillShow, step: stepToShow, index: indexToShow)
        
        if animated {
            containerView.alpha = 0
            showStep(at: indexToShow)
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.containerView.alpha = 1
            }, completion: { [weak self] _ in
                guard let self = self, self.isShown(), let step = self.currentStep() else { return }
                self.dispatch(.guideDidShow, step: step, index: self.currentStepIndex)
            })
        } else {
            showStep(at: indexToShow)
            if let step = currentStep() {
                dispatch(.guideDidShow, step: step, index: currentStepIndex)
            }
        }
        
        return true
    }
    
    /// Checks whether the guide is currently visible.
    ///
    /// - Returns: `true` if the guide container is in the view hierarchy; `false` otherwise.
    public func isShown() -> Bool {
        guard containerView.superview != nil else { return false }
        guard let host = overlayView.resolvedHostView() else { return false }
        return containerView.superview === host
    }
    
    /// Hides the guide overlay and resets the current index.
    ///
    /// Calling this method triggers `onDismiss` with `.programmatic` reason.
    /// All guide views are removed from the hierarchy and the current index is reset.
    public func hide() {
        guard isShown() else { return }
        performDismiss(reason: .programmatic)
    }
    
    /// Internal method to dismiss the guide with a specific reason.
    private func performDismiss(reason: GuideDismissReason) {
        let context = GuideDismissContext(
            reason: reason,
            step: currentStep(),
            lastStepIndex: currentStepIndex,
            totalSteps: steps.count
        )
        
        hideInternal()
        onDismiss?(self, context)
    }
    
    /// Internal hide implementation without triggering callbacks.
    private func hideInternal() {
        let activeIndex = currentStepIndex
        let activeStep = currentStep()
        
        if let step = activeStep {
            dispatch(.stepWillHide, step: step, index: activeIndex)
            dispatch(.guideWillHide, step: step, index: activeIndex)
            step.completer?.disable()
        }

        blockingGesture.isEnabled = false
        blockingGesture.view?.removeGestureRecognizer(blockingGesture)
        
        while !containerView.subviews.isEmpty {
            containerView.subviews.last?.removeFromSuperview()
        }
        containerView.removeFromSuperview()
        
        if let step = activeStep {
            dispatch(.stepDidHide, step: step, index: activeIndex)
            dispatch(.guideDidHide, step: step, index: activeIndex)
        }
        
        currentStepIndex = -1
    }
}

extension GuideController {
    private func requireExternalGesturesToFail(in targetView: UIView) {
        for view in gestureRequirementViews(from: targetView) {
            guard let gestures = view.gestureRecognizers else { continue }
            for gesture in gestures {
                if gesture === blockingGesture { continue }
                guard let gestureView = gesture.view else { continue }
                if isInternalGestureView(gestureView) { continue }
                gesture.require(toFail: blockingGesture)
            }
        }
    }

    private func gestureRequirementViews(from targetView: UIView) -> [UIView] {
        var hosts: [UIView] = []
        var current: UIView? = targetView
        while let view = current {
            hosts.append(view)
            current = view.superview
        }
        return hosts
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GuideController: UIGestureRecognizerDelegate {
    
    /// Checks if the given view belongs to internal guide components (containerView or focusView).
    ///
    /// Internal gestures should be allowed to work normally, while external gestures
    /// (like navigation swipe-back or ancestor scroll views) should be blocked.
    private func isInternalGestureView(_ view: UIView) -> Bool {
        // containerView or its subviews (overlayView, buddyView, etc.)
        if view === containerView || view.isDescendant(of: containerView) {
            return true
        }
        
        // focusView or its subviews
        if let focusView = currentStep()?.focusView,
           (view === focusView || view.isDescendant(of: focusView)) {
            return true
        }
        
        return false
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        guard isShown() else { return true }  // Safety: don't interfere if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }
        
        // Allow simultaneous recognition with internal gestures only.
        return isInternalGestureView(otherView)
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        guard isShown() else { return false }  // Safety: don't interfere if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }

        // Internal gestures should have priority; blocker's recognition waits for them.
        return isInternalGestureView(otherView)
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        guard isShown() else { return false }  // Safety: don't block if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }
        
        // External gestures must wait for the blocker to fail, effectively blocking them.
        return !isInternalGestureView(otherView)
    }
}
