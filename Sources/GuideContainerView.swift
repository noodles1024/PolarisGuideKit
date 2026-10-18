//
//  GuideContainerView.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/6/24.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

// MARK: - GuideContainerView

/// A transparent container view for hosting guide-related subviews.
///
/// This container ensures a clear background and provides a layout callback hook.
/// The background color is always forced to clear, even if explicitly set otherwise.
final class GuideContainerView: UIView {
    var onHierarchyOrLayoutChanged: (() -> Void)?
    
    // MARK: - Initialization
    
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
        backgroundColor = .clear
    }
    
    // MARK: - Overrides

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onHierarchyOrLayoutChanged?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onHierarchyOrLayoutChanged?()
    }
    
    override var backgroundColor: UIColor? {
        get {
            return .clear
        }
        set {
            super.backgroundColor = .clear
        }
    }
}

