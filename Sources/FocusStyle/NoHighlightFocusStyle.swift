//
//  NoHighlightFocusStyle.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/4/2.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

/// A focus style that creates no highlight cutout.
///
/// Use this when you want a full-screen overlay without highlighting any specific view.
/// Useful for displaying standalone messages or instructions that aren't tied to UI elements.
public final class NoHighlightFocusStyle: FocusStyle {
    
    public init() {}
    
    public func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath? {
        return nil
    }
    
    public func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide {
        return shadowView.frameLayoutGuide
    }
}

