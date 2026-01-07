//
//  GuideBuddyView.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/3/29.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

// MARK: - GuideBuddyView

/// A companion view displayed alongside a focus view to provide additional context or instructions.
///
/// `GuideBuddyView` is designed to be subclassed for custom guide overlays. Common use cases include:
/// - Arrow indicators pointing to the focus view
/// - Explanatory text or instructions
/// - Action buttons (Next, Skip, etc.)
///
/// The buddy view's frame matches its associated focus view by default, but can be customized
/// via layout guides.
///
/// Example usage:
/// ```swift
/// class CustomBuddyView: GuideBuddyView {
///     override func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
///         super.updateLayout(referenceLayoutGuide: layoutGuide, focusView: focusView)
///         // Position your custom UI relative to layoutGuide
///     }
/// }
/// ```
///
/// - Important: This view always has a clear background. By default it does not handle touches
///              itself unless you attach gesture recognizers; interactive subviews (buttons, etc.)
///              can still receive events normally.
open class GuideBuddyView: UIView {
    
    // MARK: - Types
    
    public enum Action {
        case next
        case skip
    }
    
    // MARK: - Properties
    
    /// Called when the buddy view requests a guide action (e.g. next/skip).
    ///
    /// The guide controller sets this handler automatically.
    var onAction: ((Action) -> Void)?
    
    /// Layout guide referencing the content area relative to the focus view.
    ///
    /// This guide is set when `updateLayout(withRefLayoutGuide:focusView:)` is called.
    /// Use it to position subviews that should avoid overlapping the focus area.
    public private(set) var contentReferenceLayoutGuide: UILayoutGuide?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
    }
    
    // MARK: - Class Methods
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    // MARK: - Methods
    
    /// Updates the buddy view's layout based on the reference layout guide and focus view.
    ///
    /// Override this method to position your custom UI elements relative to the focus view.
    /// The `layoutGuide` parameter represents the area occupied by the focus view and its style.
    ///
    /// - Parameters:
    ///   - layoutGuide: A layout guide representing the focus area. Avoid placing subviews
    ///                  directly over this area.
    ///   - focusView: The view being highlighted by the guide system.
    ///
    /// - Important: Always call `super` when overriding this method.
    open func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
        contentReferenceLayoutGuide = layoutGuide
    }
    
    /// Requests the guide controller to advance to the next step.
    public func requestNext() {
        onAction?(.next)
    }
    
    /// Requests the guide controller to skip the guide.
    public func requestSkip() {
        onAction?(.skip)
    }
    
    // MARK: - UIView Overrides
    
    public final override var backgroundColor: UIColor? {
        get {
            return .clear
        }
        set {
            super.backgroundColor = .clear
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let responder = super.hitTest(point, with: event) else {
            return nil
        }
        
        if responder == self && (gestureRecognizers?.isEmpty ?? true) {
            // The buddy view itself shouldn't handle touches unless it has gestures.
            return nil
        }
        return responder
    }
}
