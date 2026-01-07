//
//  DefaultFocusStyle.swift
//  PolarisGuideKit
//
//  Created by noodles on 2024/11/15.
//  Copyright © 2024 noodles. All rights reserved.
//

import UIKit

/// A simple rectangular focus style with no decorations.
///
/// This is the default style used when no custom style is specified.
/// It highlights the focus view's exact rectangular bounds without any modifications.
public final class DefaultFocusStyle: FocusStyle {
    
    public init() {}
    
    public func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath? {
        return UIBezierPath(rect: rect)
    }
    
    public func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide {
        return shadowView.frameLayoutGuide
    }
}

