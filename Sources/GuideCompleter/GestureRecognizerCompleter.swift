//
//  GestureRecognizerCompleter.swift
//  PolarisGuideKit
//
//  Created by noodles on 2026/1/14.
//  Copyright © 2026 noodles. All rights reserved.
//

import UIKit

/// A completer that triggers when a gesture recognizer fires on a view.
///
/// Use this when completion trigger view is not a `UIControl` but you still want
/// the guide to auto-complete after a user gesture (e.g., tap or long press).
/// - Note: If the gesture view is also the step's `focusView`, set
///         `step.forwardsTouchEventsToFocusView = true` so the view can receive touches.
/// - Note: Ensure `view.isUserInteractionEnabled = true` for views like `UILabel`/`UIImageView`.
public final class GestureRecognizerCompleter: GuideAutoCompleter {
    
    // MARK: - Properties
    
    private(set) weak var view: UIView?
    private let gestureRecognizer: UIGestureRecognizer
    
    // MARK: - Initialization
    
    /// Creates a completer that monitors a gesture recognizer on a view.
    ///
    /// The completer manages the recognizer's attachment and enabled state. When
    /// released, it removes its own target-action pair and detaches the recognizer
    /// from its current view, preserving any other target-action pairs.
    ///
    /// - Parameters:
    ///   - view: The view to attach the gesture recognizer to.
    ///   - gestureRecognizer: The gesture recognizer to use. Defaults to `UITapGestureRecognizer()`.
    public init(view: UIView, gestureRecognizer: UIGestureRecognizer = UITapGestureRecognizer()) {
        self.view = view
        self.gestureRecognizer = gestureRecognizer
        super.init()
        
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delaysTouchesBegan = false
        gestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.isEnabled = false
    }

    deinit {
        gestureRecognizer.removeTarget(self, action: #selector(handleGesture(_:)))
        gestureRecognizer.view?.removeGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - Actions
    
    @objc private func handleGesture(_ sender: UIGestureRecognizer) {
        trigger()
    }
    
    // MARK: - Overrides
    
    public override func enable() {
        gestureRecognizer.isEnabled = true
    }
    
    public override func disable() {
        gestureRecognizer.isEnabled = false
    }
}
