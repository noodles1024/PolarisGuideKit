//
//  GuideOverlayView.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/3/28.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

/// A mask overlay view that highlights specific UI elements during user guides.
///
/// `GuideOverlayView` creates a semi-transparent overlay with a cut-out highlight for a single focus view.
/// It handles:
/// - Dynamic mask generation with smooth animations
/// - Touch event forwarding to highlighted areas
/// - Shadow view tracking for layout purposes
///
/// The view automatically updates its mask when the guide item changes, with optional
/// animated transitions between items.
internal final class GuideOverlayView: MaskOverlayView {
    
    private enum Constants {
        static let defaultMaskAlpha: CGFloat = 0.7
        static let defaultAnimationDuration: CFTimeInterval = 0.25
    }
    
    /// The duration of mask transition animations.
    ///
    /// This value is typically set by `GuideController` to synchronize animation timing.
    /// The default value is `0.25` seconds.
    var animationDuration: CFTimeInterval = Constants.defaultAnimationDuration
    
    // MARK: - Properties
    
    /// The host bound for the current presentation. It never follows global key-window changes.
    private(set) weak var hostView: UIView?

    /// Notifies the controller to reconnect the buddy view to the current shadow's layout guide.
    var onShadowChanged: (() -> Void)?

    private var shadowConstraints: [NSLayoutConstraint] = []
    private var isSynchronizingShadow = false

    /// A focus view is usable only while it shares the bound host's hierarchy with the overlay.
    internal var validatedFocusView: UIView? {
        guard let focusView = step?.focusView, isValidFocusView(focusView) else { return nil }
        return focusView
    }
    
    /// The current guide step being displayed.
    ///
    /// Use `setStep(_:animated:)` to change the step with animation control.
    private(set) var step: GuideStep?
    
    /// Updates the current guide step with optional animation.
    ///
    /// - Parameters:
    ///   - step: The new guide step to display, or `nil` to clear the current step.
    ///   - animated: Whether to animate the mask transition.
    internal func setStep(_ step: GuideStep?, animated: Bool) {
        self.step = step
        refreshMask(animated: animated && step != nil)
    }

    /// Binds the overlay to the host chosen for this presentation, after attachment.
    internal func bind(to host: UIView?) {
        hostView = host
        refreshMask(animated: false)
    }
    
    /// Shadow view tracking the current focus view.
    ///
    /// Used internally for layout calculations and lifecycle management.
    internal private(set) var shadowOfFocusView: GuideShadowView?
    
    /// Whether a mask transition animation is currently in progress.
    ///
    /// - Note: Prevents layout-triggered mask refreshes during animations.
    private(set) var isInTransitionAnimation: Bool = false
    
    /// The path that the last animation started from.
    ///
    /// Used as a fallback when presentation layer is not yet available
    /// (e.g., when layoutSubviews is called immediately after setting a new mask layer).
    private var lastAnimationFromPath: CGPath?

    /// Invalidates completion callbacks belonging to replaced or cleared masks.
    private var maskAnimationGeneration: UInt = 0
    
    /// Indicates that layout changed during animation and mask needs refresh after animation completes.
    private var needsRefreshAfterAnimation: Bool = false
    
    /// Closure invoked when the user taps outside the highlighted area.
    ///
    /// Only called if the current guide item's `touchWildToHide` property is `true`.
    var onOutsideTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(hostView: UIView?) {
        let bounds = hostView?.bounds ?? .zero
        super.init(frame: bounds)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        maskColor = UIColor(white: 0, alpha: Constants.defaultMaskAlpha)
    }
    
    // MARK: - Class Methods
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    // MARK: - Overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        synchronizeShadowOfFocusView()

        guard step != nil, isAttachedToBoundHost else {
            refreshMask(animated: false)
            return
        }
        
        if !isInTransitionAnimation {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.isInTransitionAnimation {
                    self.refreshMask(animated: false)
                }
                else {
                    self.needsRefreshAfterAnimation = true
                }
            }
        } else {
            // Layout changed during animation, mark for refresh after animation completes
            needsRefreshAfterAnimation = true
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If `super.hitTest` returns `self`, we may need to forward the touch to the focus view.
        guard isAttachedToBoundHost else { return nil }
        synchronizeShadowOfFocusView()
        
        guard let step = step else {
            return nil
        }
        
        guard self.point(inside: point, with: event) else {
            return nil
        }
        
        guard let responder = super.hitTest(point, with: event) else {
            return nil
        }
        
        if responder != self {
            return responder
        }
        
        let shouldForwardEvent = step.forwardsTouchEventsToFocusView
        if shouldForwardEvent,
           let focusView = validatedFocusView {
            let pointInView = convert(point, to: focusView)
            if let responderInView = focusView.hitTest(pointInView, with: event) {
                return responderInView
            }
        }
        
        return self
    }
    
    override func maskOverlayViewDidTap() {
        super.maskOverlayViewDidTap()
        if let step = step, step.dismissesOnOutsideTap {
            onOutsideTap?()
        }
    }
    
    // MARK: - Private Methods
    
    private var isAttachedToBoundHost: Bool {
        guard let hostView = hostView else { return false }
        return isDescendant(of: hostView) && window === ((hostView as? UIWindow) ?? hostView.window)
    }

    private func isValidFocusView(_ focusView: UIView) -> Bool {
        guard let hostView = hostView, isAttachedToBoundHost else { return false }
        return focusView !== hostView
            && focusView.isDescendant(of: hostView)
            && window === focusView.window
    }

    private func synchronizeShadowOfFocusView() {
        guard !isSynchronizingShadow else { return }
        isSynchronizingShadow = true
        var didChangeShadow = false
        defer {
            isSynchronizingShadow = false
            // Buddy callbacks can dismiss or refresh the guide. Finish updating our
            // state first so those operations can synchronously clear the shadow.
            if didChangeShadow { onShadowChanged?() }
        }

        let focusView = validatedFocusView
        if let focusView = focusView,
           shadowOfFocusView?.masterView === focusView,
           shadowOfFocusView?.superview === self,
           shadowConstraints.count == 4,
           shadowConstraints.allSatisfy({ $0.isActive }) {
            return
        }

        let hadShadow = shadowOfFocusView != nil
        NSLayoutConstraint.deactivate(shadowConstraints)
        shadowConstraints.removeAll()
        shadowOfFocusView?.removeFromSuperview()
        shadowOfFocusView = nil
        
        guard let focusView = focusView else {
            didChangeShadow = hadShadow
            return
        }
        
        let shadowView = GuideShadowView(masterView: focusView)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shadowView)
        
        shadowConstraints = [
            shadowView.leftAnchor.constraint(equalTo: focusView.leftAnchor),
            shadowView.rightAnchor.constraint(equalTo: focusView.rightAnchor),
            shadowView.topAnchor.constraint(equalTo: focusView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: focusView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(shadowConstraints)
        
        shadowOfFocusView = shadowView
        didChangeShadow = true
    }
    
    private func createLayerMask() -> CAShapeLayer? {
        guard let step = step, isAttachedToBoundHost else {
            return nil
        }
        
        let completePath = UIBezierPath(rect: bounds)
        
        // Highlight focus view
        if let focusView = validatedFocusView {
            focusView.superview?.layoutIfNeeded()
            // Layout callbacks may remove or move the focus view to another hierarchy.
            if isValidFocusView(focusView) {
                let rectInOverlay = focusView.convert(focusView.bounds, to: self)
                if let path = step.focusStyle.highlightPath(for: focusView, frameInOverlay: rectInOverlay) {
                    completePath.append(path)
                }
            }
        }
        
        // Highlight additional paths
        for path in step.additionalHighlightPaths {
            completePath.append(path)
        }
        
        if completePath.isEmpty {
            return nil
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.path = completePath.cgPath
        return maskLayer
    }
    
    /// Updates the mask layer to match the current guide item.
    ///
    /// Creates a new mask with cut-outs for the focus view and any extra focus areas.
    /// Optionally animates the transition from the previous mask shape.
    ///
    /// - Parameter animated: Whether to animate the mask shape transition.
    ///
    /// - Note: When `animated` is `true`, the animation starts from the current
    ///   presentation layer's path (the actual displayed state), enabling smooth
    ///   transitions even if a previous animation is interrupted.
    ///   When `animated` is `false`, any ongoing animation is immediately cancelled
    ///   and the mask jumps to the final state.
    internal func refreshMask(animated: Bool) {
        refreshMask(animated: animated, completion: nil)
    }
    
    /// Updates the mask layer to match the current guide item with an optional completion handler.
    ///
    /// Creates a new mask with cut-outs for the focus view and any extra focus areas.
    /// Optionally animates the transition from the previous mask shape.
    ///
    /// - Parameters:
    ///   - animated: Whether to animate the mask shape transition.
    ///   - completion: A closure to be called when the animation completes.
    ///                 Called immediately if `animated` is `false` or no animation occurs.
    ///
    /// - Note: When `animated` is `true`, the animation starts from the current
    ///   presentation layer's path (the actual displayed state), enabling smooth
    ///   transitions even if a previous animation is interrupted.
    ///   When `animated` is `false`, any ongoing animation is immediately cancelled
    ///   and the mask jumps to the final state.
    private func refreshMask(animated: Bool, completion: (() -> Void)?) {
        maskAnimationGeneration &+= 1
        let animationGeneration = maskAnimationGeneration
        synchronizeShadowOfFocusView()
        guard maskAnimationGeneration == animationGeneration else { return }

        // Reset the flag since we're refreshing now
        needsRefreshAfterAnimation = false
        
        // 1. Capture the currently displayed path from the presentation layer.
        //    If an animation is in progress, this gives us the intermediate state
        //    rather than the final model layer value.
        var currentDisplayedPath: CGPath?
        if let oldMaskLayer = layer.mask as? CAShapeLayer {
            if let presentationPath = oldMaskLayer.presentation()?.path {
                // Presentation layer is available, use its path (animation intermediate state)
                currentDisplayedPath = presentationPath
            } else if isInTransitionAnimation, let savedFromPath = lastAnimationFromPath {
                // Presentation layer not yet created (happens when layoutSubviews is called
                // immediately after setting a new mask layer). Use the saved from path.
                currentDisplayedPath = savedFromPath
            } else {
                // No saved path available, fall back to model layer path
                currentDisplayedPath = oldMaskLayer.path
            }
        }
        
        // 2. Create and apply the new mask layer.
        //    This replaces the old mask layer, effectively cancelling any ongoing animation.
        let maskLayer = createLayerMask()
        // Layout and style callbacks can synchronously clear or refresh this overlay.
        // A superseded refresh must not restore its old mask after that operation.
        guard maskAnimationGeneration == animationGeneration else { return }
        layer.mask?.removeAllAnimations()
        layer.mask = maskLayer
        
        // 3. Reset animation state since the old mask layer (and its animation) is now removed.
        isInTransitionAnimation = false
        lastAnimationFromPath = nil
        
        // 4. If animation is requested, animate from the current displayed path to the new path.
        if animated,
           let maskLayer = maskLayer,
           let fromPath = currentDisplayedPath,
           let step = step,
           validatedFocusView != nil || !step.additionalHighlightPaths.isEmpty {
            
            // Save the from path for potential use in subsequent calls
            // when presentation layer is not yet available
            lastAnimationFromPath = fromPath
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = animationDuration
            animation.fromValue = fromPath
            animation.toValue = maskLayer.path
            
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else {
                    completion?()
                    return
                }
                guard self.maskAnimationGeneration == animationGeneration else { return }
                self.isInTransitionAnimation = false
                self.lastAnimationFromPath = nil
                // If layout changed during animation, refresh mask now
                if self.needsRefreshAfterAnimation {
                    self.needsRefreshAfterAnimation = false
                    self.refreshMask(animated: false)
                }
                completion?()
            }
            isInTransitionAnimation = true
            maskLayer.add(animation, forKey: "maskLayerPathTransition")
            CATransaction.commit()
        } else {
            // No animation, call completion immediately
            completion?()
        }
    }
    
    // MARK: - Public Methods
    
    /// Returns the host bound to this presentation, or `nil` while unbound.
    internal func resolvedHostView() -> UIView? {
        return hostView
    }
}

