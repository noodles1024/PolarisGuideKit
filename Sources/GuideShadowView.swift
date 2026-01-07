//
//  GuideShadowView.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/2/28.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// A tracking view that monitors its master view's lifecycle and frame changes.
///
/// `GuideShadowView` is an invisible helper view that:
/// - Automatically tracks when its master view is removed or deallocated
/// - Provides a layout guide for positioning related UI elements
/// - Always remains transparent and non-interactive
///
/// This view is typically used in guide/tutorial systems to maintain references
/// to highlighted views and provide layout anchors for instructional overlays.
///
/// - Important: You cannot change the `backgroundColor` or `isUserInteractionEnabled`
///              properties of this view. They will always remain clear and disabled.
public final class GuideShadowView: UIView {
    
    // MARK: - Properties
    
    /// The view being tracked by this shadow view.
    ///
    /// This is a weak reference. When the master view is deallocated or removed
    /// from its superview, `onMasterViewLost` will be called.
    private(set) weak var masterView: UIView?
    
    /// Closure invoked when the master view is deallocated or removed from its superview.
    ///
    /// - Parameter view: The master view that was lost, or `nil` if it was deallocated.
    var onMasterViewLost: ((UIView?) -> Void)?
    
    /// A layout guide matching this shadow view's frame.
    ///
    /// Use this guide to position other views relative to the tracked master view.
    public let frameLayoutGuide: UILayoutGuide
    
    // MARK: - Initialization
    
    internal init(masterView: UIView) {
        self.masterView = masterView
        self.frameLayoutGuide = UILayoutGuide()
        super.init(frame: masterView.bounds)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        clipsToBounds = false
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        addLayoutGuide(frameLayoutGuide)
        NSLayoutConstraint.activate([
            frameLayoutGuide.leftAnchor.constraint(equalTo: leftAnchor),
            frameLayoutGuide.rightAnchor.constraint(equalTo: rightAnchor),
            frameLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Class Methods
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    // MARK: - Overrides
    
    public override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if superview != nil && (masterView == nil || masterView?.superview == nil) {
            removeFromSuperview()
            onMasterViewLost?(masterView)
        }
    }
}

