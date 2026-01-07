//
//  ArrowBuddyView.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// A buddy view that displays a hint label with an arrow pointing to the focus view.
/// This demonstrates how to use `updateLayout(referenceLayoutGuide:focusView:)` to
/// position elements relative to the highlighted focus view.
final class ArrowBuddyView: GuideBuddyView {
    
    // MARK: - Properties
    
    private let arrowImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let image = UIImage(systemName: "arrow.down", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemIndigo
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// Constraints that depend on the layout guide (created in updateLayout)
    private var layoutGuideConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(arrowImageView)
        
        // Static constraints (not dependent on layout guide)
        NSLayoutConstraint.activate([
            // Arrow sizing
            arrowImageView.widthAnchor.constraint(equalToConstant: 32),
            arrowImageView.heightAnchor.constraint(equalToConstant: 32),
        ])
    }
    
    // MARK: - GuideBuddyView Override
    
    /// This method is called when the guide system sets up the buddy view.
    /// We use the provided `layoutGuide` to position our hint label and arrow
    /// relative to the focus view's position.
    override func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
        super.updateLayout(referenceLayoutGuide: layoutGuide, focusView: focusView)
        
        // Remove previously set constraints
        NSLayoutConstraint.deactivate(layoutGuideConstraints)
        layoutGuideConstraints.removeAll()
        
        // The layoutGuide represents the focus area (including any style insets).
        // We position the arrow to point at the center-top of the focus area,
        // keeping the label removed while retaining the arrow indicator.
        
        layoutGuideConstraints = [
            // Arrow: positioned above the focus view, centered horizontally
            arrowImageView.bottomAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: -8),
            arrowImageView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
        ]
        
        NSLayoutConstraint.activate(layoutGuideConstraints)
        
        // Animate the arrow bouncing
        startArrowAnimation()
    }
    
    // MARK: - Animation
    
    private func startArrowAnimation() {
        // Cancel any existing animation
        arrowImageView.layer.removeAllAnimations()
        
        // Create a bouncing animation
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                self.arrowImageView.transform = CGAffineTransform(translationX: 0, y: 8)
            }
        )
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            arrowImageView.layer.removeAllAnimations()
        }
    }
}
