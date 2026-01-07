//
//  MaskOverlayView.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/2/28.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// A closure invoked when the overlay view is tapped.
typealias MaskOverlayViewTapHandler = (_ view: UIView) -> Void

/// A base class for creating semi-transparent mask views with tap gesture support.
///
/// `MaskOverlayView` provides a reusable foundation for overlay masks in the UI.
/// It automatically handles tap gestures and allows subclasses to customize behavior
/// by overriding `maskOverlayViewDidTap()`.
///
/// - Note: The tap gesture only responds to taps directly on the mask view itself,
///         not on its subviews.
open class MaskOverlayView: UIView, UIGestureRecognizerDelegate {
    
    private enum Constants {
        static let defaultMaskAlpha: CGFloat = 0.6
    }
    
    // MARK: - Properties
    
    /// Optional user-defined data associated with this mask view.
    var userInfo: Any?
    
    /// The color of the mask overlay.
    ///
    /// Setting this property automatically updates the view's `backgroundColor`.
    /// - Note: Defaults to black with 60% opacity.
    var maskColor: UIColor {
        didSet {
            backgroundColor = maskColor
        }
    }
    
    /// Closure called after the mask view is tapped.
    ///
    /// This handler is invoked after `maskOverlayViewDidTap()` is called.
    var onTap: MaskOverlayViewTapHandler?
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureTriggered))
        gesture.delegate = self
        return gesture
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.maskColor = UIColor(white: 0, alpha: Constants.defaultMaskAlpha)
        super.init(frame: frame)
        maskViewCommonSetup()
    }
    
    required public init?(coder: NSCoder) {
        self.maskColor = UIColor(white: 0, alpha: Constants.defaultMaskAlpha)
        super.init(coder: coder)
        maskViewCommonSetup()
    }
    
    private func maskViewCommonSetup() {
        backgroundColor = maskColor
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tapGesture && touch.view != tapGesture.view {
            return false
        }
        return true
    }
    
    // MARK: - Actions
    
    @objc private func tapGestureTriggered() {
        maskOverlayViewDidTap()
        onTap?(self)
    }
    
    // MARK: - Methods
    
    /// Called when the mask view is tapped.
    ///
    /// Subclasses can override this method to provide custom behavior when the mask is tapped.
    /// The default implementation does nothing.
    func maskOverlayViewDidTap() {
    }
}

