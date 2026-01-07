//
//  FocusStyle.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/11/15.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// Protocol for customizing the appearance of highlighted focus areas in guides.
///
/// Adopt this protocol to create custom focus styles that define:
/// - The shape of the highlight cutout (rectangle, circle, custom path)
/// - Layout guides for positioning companion views
///
/// The system provides several built-in implementations:
/// - `DefaultFocusStyle`: Rectangular highlight
/// - `CircleFocusStyle`: Circular highlight
/// - `RoundedRectFocusStyle`: Rounded rectangle highlight
/// - `NoHighlightFocusStyle`: No highlight (full-screen overlay)
public protocol FocusStyle {
    
    /// Returns the bezier path defining the highlighted area.
    ///
    /// This path is cut out of the mask overlay, allowing the focus view to show through.
    ///
    /// - Parameters:
    ///   - focusView: The view being highlighted.
    ///   - rect: The focus view's frame in the guide overlay's coordinate system.
    /// - Returns: A bezier path for the highlight, or `nil` for no highlight.
    func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath?
    
    /// Returns a layout guide for positioning the buddy view.
    ///
    /// The buddy view typically uses this guide to avoid overlapping the focus area.
    ///
    /// - Parameters:
    ///   - focusView: The view being highlighted.
    ///   - shadowView: The shadow view tracking the focus view.
    /// - Returns: A layout guide representing the focus area.
    func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide
}

