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
    /// If `nil`, the focus view's window is used. A guide without a focus view
    /// uses an unambiguous foreground application window.
    public private(set) weak var hostView: UIView?
    
    /// Index of the currently displayed or preselected guide item.
    ///
    /// - Note: Starts at `-1` and resets to `-1` when the guide is hidden.
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
    private let usesAutomaticHost: Bool
    private weak var presentationHostView: UIView?
    private var presentationID: UUID?
    private var sceneDisconnectObserver: NSObjectProtocol?
    private var isDismissing = false
    private var isChangingStep = false
    private var stepChangeGeneration: UInt = 0
    
    /// A gesture recognizer that blocks external gestures while the guide is displayed.
    /// Added to hostView to intercept all touches including those in focusView area.
    private let blockingGesture = BlockAllGestureRecognizer(target: nil, action: nil)
    private var gestureGates: [ObjectIdentifier: GuideGestureGate] = [:]
    private var isSynchronizingGestureGates = false
    
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
    ///   - hostView: The view that will host the guide overlay. If `nil`, the focus view's
    ///               window is preferred, followed by an unambiguous foreground window.
    ///   - steps: Initial steps for the sequence. Invalid steps are automatically filtered out.
    ///   - plugins: Plugins that will receive guide lifecycle events.
    ///
    /// - Important: The focus/host hierarchy is checked when displaying a step.
    ///              An explicit host and its focus views do not need a window,
    ///              either during initialization or when calling `show()`.
    public init(hostView: UIView?, steps: [GuideStep] = [], plugins: [GuidePlugin] = []) {
        self.hostView = hostView
        self.usesAutomaticHost = hostView == nil
        let bounds = hostView?.bounds ?? .zero
        self.containerView = GuideContainerView(frame: bounds)
        self.overlayView = GuideOverlayView(hostView: hostView)
        self.plugins = plugins
        super.init()

        // Configure while self is alive; lazy initialization during deinit would
        // try to establish UIKit's weak target/delegate reference to a dying object.
        blockingGesture.addTarget(self, action: #selector(handleBlockingGesture(_:)))
        blockingGesture.delegate = self
        blockingGesture.cancelsTouchesInView = false
        blockingGesture.delaysTouchesBegan = false
                
        overlayView.onOutsideTap = { [weak self] in
            guard let self = self else { return }
            self.performDismiss(reason: .outsideTap)
        }
        
        addOverlayToContainerIfNeeded()
        
        overlayView.onShadowChanged = { [weak self] in
            self?.updateBuddyLayout()
            self?.synchronizeGestureGates()
        }
        containerView.onHierarchyOrLayoutChanged = { [weak self] in
            self?.synchronizeGestureGates()
        }

        // A provider may not resolve until its screen has appeared. Keep the step
        // and validate the resolved view immediately before displaying it.
        self.steps = steps.filter { $0.focusViewProvider != nil || $0.buddyView != nil }
    }

    // MARK: - Private Methods

    private func resolveHost(for focusView: UIView?) -> UIView? {
        // An explicitly supplied host that has deallocated must not turn into an
        // automatic request for some unrelated window.
        if !usesAutomaticHost { return hostView }
        if let focusView = focusView { return focusView.window }
        return PolarisKeyWindowProvider.keyWindow()
    }

    private func canDisplay(_ step: GuideStep, in host: UIView) -> Bool {
        return canDisplay(step, focusView: step.focusView, in: host)
    }

    private func canDisplay(_ step: GuideStep, focusView: UIView?, in host: UIView) -> Bool {
        guard let focusView = focusView else { return step.buddyView != nil }
        return focusView !== host && focusView.isDescendant(of: host)
            && !focusView.isDescendant(of: containerView)
            && focusView.window === ((host as? UIWindow) ?? host.window)
    }

    private func updateBuddyLayout() {
        guard let step = currentStep(), let buddyView = step.buddyView else { return }
        guard buddyView.superview === containerView,
              let focusView = overlayView.validatedFocusView,
              let shadowView = overlayView.shadowOfFocusView else {
            buddyView.clearLayoutReference()
            return
        }
        let guide = step.focusStyle.buddyLayoutGuide(for: focusView, shadowView: shadowView)
        buddyView.updateLayout(referenceLayoutGuide: guide, focusView: focusView)
    }

    private func synchronizeGestureGates() {
        guard !isDismissing, !isSynchronizingGestureGates, isShown(),
              blockingGesture.view != nil, let host = presentationHostView else { return }
        let presentation = presentationID
        isSynchronizingGestureGates = true
        defer { isSynchronizingGestureGates = false }

        var visited = Set<ObjectIdentifier>()
        var gestures: [ObjectIdentifier: UIGestureRecognizer] = [:]
        // Forwarded focus touches may traverse a navigation/scroll container
        // below a window host, so the host's ancestor chain alone is not enough.
        for start in [host, overlayView.validatedFocusView].compactMap({ $0 }) {
            var ancestor: UIView? = start
            while let view = ancestor, visited.insert(ObjectIdentifier(view)).inserted {
                for gesture in view.gestureRecognizers ?? [] {
                    if isGuideBlockingGesture(gesture) { continue }
                    gestures[ObjectIdentifier(gesture)] = gesture
                }
                ancestor = view.superview
            }
        }

        guard presentationID == presentation, isShown(), !isDismissing else { return }
        for (id, gate) in gestureGates {
            if gate.guardedGesture == nil {
                gate.invalidate()
                gestureGates.removeValue(forKey: id)
            } else {
                // Keep the dependency reusable if a dynamic focus moves back.
                // Detached/unrelated gestures must not wait on this guide.
                let isRelevant = gestures[id] != nil
                if gate.isEnabled != isRelevant { gate.isEnabled = isRelevant }
            }
        }
        for (id, gesture) in gestures where gestureGates[id] == nil {
            guard presentationID == presentation, isShown(), !isDismissing else { return }
            let gate = GuideGestureGate(guarding: gesture) { [weak self] gesture in
                guard let self = self, self.isShown(), !self.isDismissing,
                      let view = gesture.view else { return false }
                return !self.isInternalGestureView(view) && !self.isWhitelistedGesture(gesture)
            }
            gestureGates[id] = gate
            host.addGestureRecognizer(gate)
            // Navigation gestures can win arbitration when failure requirements
            // are supplied only by the shared blocker's delegate.
            // Install even for currently whitelisted gestures. The gate fails
            // for allowed touches and begins for blocked ones, so changing steps
            // never requires removing an irreversible failure relationship.
            gesture.require(toFail: gate)
        }
    }

    private func observeSceneDisconnect() {
        if #available(iOS 13.0, *) {
            sceneDisconnectObserver = NotificationCenter.default.addObserver(
                forName: UIScene.didDisconnectNotification, object: nil, queue: .main
            ) { [weak self] notification in
                // An explicit host may enter a window after show(). Resolve only
                // that host's current scene, never a global/key window.
                guard let self = self, let host = self.presentationHostView,
                      let scene = ((host as? UIWindow) ?? host.window)?.windowScene,
                      notification.object as? UIScene === scene else { return }
                self.hide()
            }
        }
    }

    /// Returns the currently displayed or preselected step.
    ///
    /// - Returns: The step at `currentStepIndex`, or `nil` if no step has been selected.
    public func currentStep() -> GuideStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }

    private func makeContext(for step: GuideStep, index: Int) -> GuideStepContext {
        return GuideStepContext(
            hostView: presentationHostView,
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
        let presentation = presentationID
        let generation = stepChangeGeneration
        let context = makeContext(for: step, index: index)
        for plugin in plugins {
            // A plugin may dismiss or advance synchronously. Do not deliver the
            // old presentation/step's events after the resulting transition.
            guard presentationID == presentation, stepChangeGeneration == generation else { break }
            plugin.handle(event, context: context)
        }
    }
    
    private func configureCurrentStep() {
        guard let step = currentStep() else { return }
        
        addOverlayToContainerIfNeeded()
        overlayView.setStep(step, animated: animatesStepTransition)
        guard isShown(), currentStep() === step else { return }
        
        if let completer = step.completer {
            completer.onTrigger = { [weak self] _ in
                guard let self = self else { return }
                self.performDismiss(reason: .completerTriggered)
            }
            completer.enable()
            guard isShown(), currentStep() === step else { return }
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
            
            updateBuddyLayout()
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
        guard isShown(), !isDismissing, !isChangingStep else { return }
        if currentStepIndex + 1 >= steps.count {
            performDismiss(reason: .completed)
        } else if showNextStep() {
            onStepChange?(self)
        }
    }
    
    deinit {
        overlayView.onOutsideTap = nil
        overlayView.onShadowChanged = nil
        containerView.onHierarchyOrLayoutChanged = nil
        // Release plugin resources without calling lifecycle handlers on a dying owner.
        hideInternal(dispatchesEvents: false)
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
        synchronizeGestureGates()
    }
    
    /// Adds a guide item to the sequence.
    ///
    /// If this is the first item and the guide is already showing, the item is displayed immediately.
    ///
    /// - Parameter item: The guide item to add.
    /// - Returns: `true` if the item was added successfully; `false` if invalid or already present.
    @discardableResult
    public func addStep(_ step: GuideStep) -> Bool {
        if step.focusViewProvider == nil && step.buddyView == nil {
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
    /// Before `show()`, this selects the starting item without attaching views or sending events.
    ///
    /// - Parameter index: The zero-based index of the item to display.
    /// - Returns: `true` if the item was selected or shown; `false` if the index or
    ///            presentation hierarchy is invalid, or another transition is in progress.
    @discardableResult
    public func showStep(at index: Int) -> Bool {
        guard !isDismissing, !isChangingStep, steps.indices.contains(index) else { return false }
        if !isShown() {
            if presentationID != nil { hideInternal() }
            currentStepIndex = index
            return true
        }
        guard let host = presentationHostView,
              canDisplay(steps[index], in: host), let presentation = presentationID else { return false }
        isChangingStep = true
        stepChangeGeneration &+= 1
        defer { isChangingStep = false }

        if currentStepIndex == index {
            let step = steps[index]
            dispatch(.stepWillShow, step: step, index: index)
            guard presentationID == presentation, isShown() else { return false }
            refreshOverlay(animated: false)
            guard presentationID == presentation, isShown() else { return false }
            isChangingStep = false
            dispatch(.stepDidShow, step: step, index: index)
            return presentationID == presentation && isShown()
        }

        let previousIndex = currentStepIndex
        if let previousStep = currentStep() {
            dispatch(.stepWillHide, step: previousStep, index: previousIndex)
            guard presentationID == presentation, isShown() else { return false }
            previousStep.buddyView?.removeFromSuperview()
            previousStep.buddyView?.onAction = nil
            previousStep.completer?.onTrigger = nil
            previousStep.completer?.disable()
            guard presentationID == presentation, isShown() else { return false }
            dispatch(.stepDidHide, step: previousStep, index: previousIndex)
            guard presentationID == presentation, isShown() else { return false }
        }

        currentStepIndex = index
        let step = steps[index]
        dispatch(.stepWillShow, step: step, index: index)
        guard presentationID == presentation, isShown() else { return false }
        configureCurrentStep()
        guard presentationID == presentation, isShown() else { return false }
        synchronizeGestureGates()
        isChangingStep = false
        dispatch(.stepDidShow, step: step, index: index)
        return presentationID == presentation && isShown()
    }

    /// Displays the guide overlay and begins the guide sequence.
    ///
    /// If already showing, this method returns `true` without changes.
    /// The first guide item (or the current item if resuming) is displayed.
    ///
    /// - Parameter animated: Whether to animate the appearance of the guide overlay. Defaults to `false`.
    /// - Returns: `true` if the guide was attached to its host; `false` if there are no
    ///            guide items, the host is ambiguous or unavailable, or the focus does
    ///            not belong to the host. An explicit host need not be in a window or
    ///            an active scene. A presentation stays bound to its host.
    @discardableResult
    public func show(animated: Bool = false) -> Bool {
        guard !isDismissing, !steps.isEmpty else { return false }
        if isShown() { return true }
        guard !isChangingStep else { return false }
        if presentationID != nil || containerView.superview != nil || blockingGesture.view != nil {
            hideInternal()
        }

        let indexToShow = currentStepIndex < 0 ? 0 : currentStepIndex
        let stepToShow = steps[indexToShow]
        let focusView = stepToShow.focusView
        if usesAutomaticHost && stepToShow.focusViewProvider != nil && focusView == nil {
            return false
        }
        guard let host = resolveHost(for: focusView),
              canDisplay(stepToShow, focusView: focusView, in: host) else { return false }

        let presentation = UUID()
        presentationID = presentation
        presentationHostView = host
        currentStepIndex = -1
        containerView.alpha = animated ? 0 : 1
        host.addSubview(containerView)
        guard presentationID == presentation, containerView.superview === host else { return false }
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: host.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: host.rightAnchor),
            containerView.topAnchor.constraint(equalTo: host.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        addOverlayToContainerIfNeeded()
        overlayView.bind(to: host)
        host.layoutIfNeeded()
        guard presentationID == presentation, isShown() else { return false }
        host.addGestureRecognizer(blockingGesture)
        blockingGesture.isEnabled = true
        synchronizeGestureGates()
        observeSceneDisconnect()

        dispatch(.guideWillShow, step: stepToShow, index: indexToShow)
        guard presentationID == presentation, showStep(at: indexToShow) else {
            if presentationID == presentation { hideInternal() }
            return false
        }

        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.containerView.alpha = 1
            }, completion: { [weak self] finished in
                guard let self = self, finished, self.presentationID == presentation,
                      self.isShown(), let step = self.currentStep() else { return }
                self.dispatch(.guideDidShow, step: step, index: self.currentStepIndex)
            })
        } else if let step = currentStep() {
            dispatch(.guideDidShow, step: step, index: currentStepIndex)
        }
        return presentationID == presentation && isShown()
    }

    /// Checks whether the guide is attached to its host, even if the host is offscreen.
    ///
    /// - Returns: `true` if the guide container is in the view hierarchy; `false` otherwise.
    public func isShown() -> Bool {
        guard presentationID != nil, let host = presentationHostView else { return false }
        return containerView.superview === host
    }

    /// Hides the guide overlay and resets the current index.
    ///
    /// Calling this method triggers `onDismiss` with `.programmatic` reason.
    /// All guide views are removed from the hierarchy and the current index is reset.
    public func hide() {
        performDismiss(reason: .programmatic)
    }
    
    /// Internal method to dismiss the guide with a specific reason.
    private func performDismiss(reason: GuideDismissReason) {
        guard !isDismissing,
              presentationID != nil || containerView.superview != nil || blockingGesture.view != nil else { return }
        let context = GuideDismissContext(
            reason: reason,
            step: currentStep(),
            lastStepIndex: currentStepIndex,
            totalSteps: steps.count
        )
        
        hideInternal()
        onDismiss?(self, context)
    }
    
    /// Cleans up without invoking onDismiss. Deinitialization uses resource-only plugin teardown.
    private func hideInternal(dispatchesEvents: Bool = true) {
        guard !isDismissing else { return }
        isDismissing = true
        defer { isDismissing = false }
        if let observer = sceneDisconnectObserver {
            NotificationCenter.default.removeObserver(observer)
            sceneDisconnectObserver = nil
        }
        containerView.layer.removeAllAnimations()
        let activeIndex = currentStepIndex
        let hadPresentation = presentationID != nil
        let activeStep = hadPresentation ? currentStep() : nil
        
        if let step = activeStep {
            if dispatchesEvents {
                dispatch(.stepWillHide, step: step, index: activeIndex)
                dispatch(.guideWillHide, step: step, index: activeIndex)
            }
            step.completer?.onTrigger = nil
            step.buddyView?.onAction = nil
            step.completer?.disable()
        }

        if !dispatchesEvents && hadPresentation {
            for plugin in plugins {
                plugin.tearDown()
            }
        }

        blockingGesture.isEnabled = false
        blockingGesture.view?.removeGestureRecognizer(blockingGesture)
        gestureGates.values.forEach { $0.invalidate() }
        gestureGates.removeAll()
        
        overlayView.setStep(nil, animated: false)
        activeStep?.buddyView?.clearLayoutReference()
        while !containerView.subviews.isEmpty {
            containerView.subviews.last?.removeFromSuperview()
        }
        containerView.removeFromSuperview()
        presentationID = nil
        
        if dispatchesEvents, let step = activeStep {
            dispatch(.stepDidHide, step: step, index: activeIndex)
            dispatch(.guideDidHide, step: step, index: activeIndex)
        }
        
        currentStepIndex = -1
        overlayView.bind(to: nil)
        presentationHostView = nil
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GuideController: UIGestureRecognizerDelegate {

    private func isGuideBlockingGesture(_ gesture: UIGestureRecognizer) -> Bool {
        return gesture is BlockAllGestureRecognizer || gesture is GuideGestureGate
    }
    
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
        if let focusView = overlayView.validatedFocusView,
           (view === focusView || view.isDescendant(of: focusView)) {
            return true
        }
        
        return false
    }
    
    private func isWhitelistedGesture(_ gesture: UIGestureRecognizer) -> Bool {
        guard let step = currentStep() else { return false }
        return step.gestureRecognizerWhitelist.contains { $0 === gesture }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        if isGuideBlockingGesture(otherGestureRecognizer) { return true }
        guard isShown() else { return true }  // Safety: don't interfere if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }
        
        // Allow simultaneous recognition with internal or whitelisted gestures.
        return isInternalGestureView(otherView) || isWhitelistedGesture(otherGestureRecognizer)
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        if isGuideBlockingGesture(otherGestureRecognizer) { return false }
        guard isShown() else { return false }  // Safety: don't interfere if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }

        // Internal or whitelisted gestures should have priority; blocker's recognition waits for them.
        return isInternalGestureView(otherView) || isWhitelistedGesture(otherGestureRecognizer)
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === blockingGesture else { return false }
        if isGuideBlockingGesture(otherGestureRecognizer) { return false }
        guard isShown() else { return false }  // Safety: don't block if not shown
        guard let otherView = otherGestureRecognizer.view else { return false }
        
        // Non-internal and non-whitelisted gestures must wait for the blocker to fail.
        return !(isInternalGestureView(otherView) || isWhitelistedGesture(otherGestureRecognizer))
    }
}
