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
    
    /// The view that hosts this guide overlay.
    ///
    /// If `nil`, the key window is used as the host.
    private(set) weak var hostView: UIView?
    
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
        let oldStep = self.step
        self.step = step
        if step !== oldStep {
            setupShadowOfFocusView()
            refreshMask(animated: animated)
        }
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
    
    /// Indicates that layout changed during animation and mask needs refresh after animation completes.
    private var needsRefreshAfterAnimation: Bool = false
    
    /// Closure invoked when the user taps outside the highlighted area.
    ///
    /// Only called if the current guide item's `touchWildToHide` property is `true`.
    var onOutsideTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(hostView: UIView?) {
        self.hostView = hostView
        let bounds = hostView?.bounds ?? UIScreen.main.bounds
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
        
        // Check if focusView has changed (for dynamic provider scenarios,
        // e.g., UITableView/UICollectionView cell reuse after reloadData)
        if let currentFocusView = step?.focusView,
           currentFocusView !== shadowOfFocusView?.masterView {
            // focusView instance changed, rebuild shadow view constraints
            setupShadowOfFocusView()
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
        guard let host = resolvedHostView() else { return nil }
        if superview?.superview != host { return nil }
        
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
           let focusView = step.focusView,
           window == focusView.window {
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
    
    private func setupShadowOfFocusView() {
        shadowOfFocusView?.removeFromSuperview()
        shadowOfFocusView = nil
        
        guard let step = step, let focusView = step.focusView else {
            return
        }
        
        let shadowView = GuideShadowView(masterView: focusView)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shadowView)
        
        NSLayoutConstraint.activate([
            shadowView.leftAnchor.constraint(equalTo: focusView.leftAnchor),
            shadowView.rightAnchor.constraint(equalTo: focusView.rightAnchor),
            shadowView.topAnchor.constraint(equalTo: focusView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: focusView.bottomAnchor)
        ])
        
        shadowOfFocusView = shadowView
    }
    
    private func createLayerMask() -> CAShapeLayer? {
        guard let step = step else {
            return nil
        }
        
        let completePath = UIBezierPath(rect: bounds)
        guard let decidedHost = resolvedHostView() else { return nil }
        
        // Highlight focus view
        if let focusView = step.focusView, focusView.superview != nil {
            // Ensure the entire view hierarchy is laid out before converting coordinates.
            //decidedHost.layoutIfNeeded()
            focusView.superview?.layoutIfNeeded()
            
            let rectInHostView = focusView.convert(focusView.bounds, to: decidedHost)
            if let path = step.focusStyle.highlightPath(for: focusView, frameInOverlay: rectInHostView) {
                completePath.append(path)
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
            } else if let savedFromPath = lastAnimationFromPath {
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
        layer.mask = maskLayer
        
        // 3. Reset animation state since the old mask layer (and its animation) is now removed.
        isInTransitionAnimation = false
        
        // 4. If animation is requested, animate from the current displayed path to the new path.
        if animated,
           let maskLayer = maskLayer,
           let fromPath = currentDisplayedPath,
           let step = step,
           step.canShowTransitionAnimation() {
            
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
                self.isInTransitionAnimation = false
                // If layout changed during animation, refresh mask now
                if self.needsRefreshAfterAnimation {
                    self.needsRefreshAfterAnimation = false
                    self.refreshMask(animated: false)
                }
                completion?()
            }
            maskLayer.add(animation, forKey: "maskLayerPathTransition")
            CATransaction.commit()
            isInTransitionAnimation = true
        } else {
            // No animation, call completion immediately
            completion?()
        }
    }
    
    // MARK: - Public Methods
    
    /// Returns the effective host view for displaying the guide overlay.
    ///
    /// - Returns: The `hostView` if set; otherwise, the key window.
    internal func resolvedHostView() -> UIView? {
        return hostView ?? PolarisKeyWindowProvider.keyWindow()
    }
}

