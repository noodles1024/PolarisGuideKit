//
//  RoundedRectFocusStyle.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/11/15.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// A focus style with rounded corners.
///
/// Use this style to create smooth, rounded highlights for buttons, cards,
/// or other UI elements with rounded corners.
///
/// Example usage:
/// ```swift
/// let style = RoundedRectFocusStyle(
///     focusCornerRadius: .followFocusView(delta: 4),
///     focusAreaInsets: UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
/// )
/// step.focusStyle = style
/// ```
public final class RoundedRectFocusStyle: FocusStyle {
    
    /// Corner radius mode for focus area.
    ///
    /// Supports:
    /// - fixed radius
    /// - follow `focusView.layer.cornerRadius` with a delta (positive or negative)
    /// - scale `focusView.layer.cornerRadius` by a multiplier (e.g. 0.5 or 1.2)
    public enum CornerRadiusMode: Equatable {
        /// Use a fixed corner radius.
        case fixed(CGFloat)
        /// Use `focusView.layer.cornerRadius + delta`.
        case followFocusView(delta: CGFloat)
        /// Use `focusView.layer.cornerRadius * multiplier`.
        case scaleWithFocusView(multiplier: CGFloat)
        
        fileprivate func resolved(for focusView: UIView) -> CGFloat {
            let base = max(0, focusView.layer.cornerRadius)
            let value: CGFloat
            switch self {
            case .fixed(let radius):
                value = radius
            case .followFocusView(let delta):
                value = base + delta
            case .scaleWithFocusView(let multiplier):
                value = base * multiplier
            }
            return max(0, value)
        }
    }
    
    /// Corner radius mode for the highlighted area.
    ///
    /// - Note: Defaults to `.fixed(0)` (square corners).
    public private(set) var focusCornerRadius: CornerRadiusMode
    
    /// Insets to adjust the highlight area size.
    ///
    /// Negative values expand the highlight beyond the focus view's bounds.
    /// Positive values shrink it.
    /// - Note: Defaults to `.zero`.
    public private(set) var focusAreaInsets: UIEdgeInsets
    
    /// Which corners to round.
    ///
    /// - Note: Defaults to `.allCorners`.
    public private(set) var roundedCorners: UIRectCorner
    
    /// Creates a new rounded rect focus style.
    ///
    /// - Parameters:
    ///   - focusCornerRadius: Corner radius mode for the highlighted area. Defaults to `.fixed(0)`.
    ///   - focusAreaInsets: Insets to adjust the highlight area size. Defaults to `.zero`.
    ///   - roundedCorners: Which corners to round. Defaults to `.allCorners`.
    public init(
        focusCornerRadius: CornerRadiusMode = .fixed(0),
        focusAreaInsets: UIEdgeInsets = .zero,
        roundedCorners: UIRectCorner = .allCorners
    ) {
        self.focusCornerRadius = focusCornerRadius
        self.focusAreaInsets = focusAreaInsets
        self.roundedCorners = roundedCorners
    }
    
    // MARK: - FocusStyle
    
    public func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath? {
        let pathRect = rect.inset(by: focusAreaInsets)
        let resolvedRadius = focusCornerRadius.resolved(for: focusView)
        let cornerRadii = CGSize(width: resolvedRadius, height: resolvedRadius)
        
        return UIBezierPath(
            roundedRect: pathRect,
            byRoundingCorners: roundedCorners,
            cornerRadii: cornerRadii
        )
    }
    
    public func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide {
        return shadowView.frameLayoutGuide
    }
}
