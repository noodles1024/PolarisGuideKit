//
//  CircleFocusStyle.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/12/01.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// A circular focus style for highlighting round UI elements.
///
/// `CircleFocusStyle` creates a perfect circular cutout in the mask overlay.
/// The circle size can be specified as an absolute radius or as a factor of the
/// focus view's dimensions.
///
/// Example usage:
/// ```swift
/// // Option 1: Fixed radius
/// let style1 = CircleFocusStyle(radiusMode: .fixed(100))
///
/// // Option 2: Proportional sizing (based on view's narrower dimension)
/// let style2 = CircleFocusStyle(radiusMode: .scaledToFocusView(factor: 1.3))
///
/// // Optional: Offset the circle center
/// let style3 = CircleFocusStyle(radiusMode: .fixed(50), centerOffset: CGPoint(x: 10, y: -20))
///
/// step.focusStyle = style1
/// ```
public final class CircleFocusStyle: FocusStyle {
    
    /// Determines how the circle radius is calculated.
    public enum RadiusMode: Equatable {
        /// Use a fixed radius value in points.
        case fixed(CGFloat)
        /// Scale the radius based on the focus view's narrower dimension.
        /// For example, factor 1.0 means the circle diameter equals the narrower dimension.
        /// Factor 1.3 means 130% of the narrower dimension.
        case scaledToFocusView(factor: CGFloat)
        
        fileprivate func resolved(for rect: CGRect) -> CGFloat {
            switch self {
            case .fixed(let radius):
                return max(0, radius)
            case .scaledToFocusView(let factor):
                let minSide = min(rect.width, rect.height)
                return max(0, minSide * factor / 2.0)
            }
        }
    }
    
    /// The mode used to calculate the circle radius.
    ///
    /// - Note: Defaults to `.fixed(50)`.
    public private(set) var radiusMode: RadiusMode
    
    /// Offset from the focus view's center for the circle's center point.
    ///
    /// - Note: Defaults to `.zero` (centered on focus view).
    public private(set) var centerOffset: CGPoint
    
    /// Creates a new circle focus style.
    ///
    /// - Parameters:
    ///   - radiusMode: The mode for calculating the circle radius. Defaults to `.fixed(50)`.
    ///   - centerOffset: Offset from the focus view's center. Defaults to `.zero`.
    public init(radiusMode: RadiusMode = .fixed(50), centerOffset: CGPoint = .zero) {
        self.radiusMode = radiusMode
        self.centerOffset = centerOffset
    }
    
    // MARK: - FocusStyle
    
    public func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath? {
        let baseCenter = CGPoint(x: rect.midX, y: rect.midY)
        let finalCenter = CGPoint(x: baseCenter.x + centerOffset.x, y: baseCenter.y + centerOffset.y)
        let finalRadius = radiusMode.resolved(for: rect)
        
        let circlePath = UIBezierPath(
            arcCenter: finalCenter,
            radius: finalRadius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        return circlePath
    }
    
    public func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide {
        return shadowView.frameLayoutGuide
    }
}
