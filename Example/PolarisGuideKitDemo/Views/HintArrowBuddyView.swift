//
//  HintArrowBuddyView.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2026/01/07.
//

import UIKit
import PolarisGuideKit

/// A buddy view that combines an arrow pointing to the focus view with an explanatory text bubble.
final class HintArrowBuddyView: GuideBuddyView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let arrowImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let image = UIImage(systemName: "arrow.down", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow to the arrow to match the container
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        return imageView
    }()
    
    private var layoutGuideConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    
    init(title: String, message: String) {
        super.init(frame: .zero)
        
        titleLabel.text = title
        messageLabel.text = message
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Arrow Setup
        addSubview(arrowImageView)
        
        // Container Setup (The Bubble)
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Title Label
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message Label
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Internal Constraints for the Bubble
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Allow container to grow but respect screen width padding (handled in updateLayout usually, 
            // but here we ensure internal consistency)
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])
    }
    
    // MARK: - GuideBuddyView Override
    
    override func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
        super.updateLayout(referenceLayoutGuide: layoutGuide, focusView: focusView)
        
        // Remove old constraints
        NSLayoutConstraint.deactivate(layoutGuideConstraints)
        layoutGuideConstraints.removeAll()
        
        // Determine position: We want the arrow to point DOWN at the element, 
        // effectively placing the entire bubble ABOVE the element.
        // OR: Point UP at the element (bubble BELOW).
        // Since the button is in the top-center area, placing the bubble BELOW is safer.
        // So Arrow points UP.
        
        // Let's update the arrow icon to point UP
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        arrowImageView.image = UIImage(systemName: "arrow.up", withConfiguration: config)
        
        layoutGuideConstraints = [
            // Arrow positioning
            // Point the arrow at the bottom-center of the highlight area
            arrowImageView.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: 8),
            arrowImageView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 32),
            arrowImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Container (Bubble) positioning
            // Place it below the arrow
            containerView.topAnchor.constraint(equalTo: arrowImageView.bottomAnchor, constant: 8),
            containerView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            
            // Ensure bubble stays within screen bounds (assuming superview is the overlay)
            // We can add relations to superview if needed, but centering usually works for this demo.
        ]
        
        NSLayoutConstraint.activate(layoutGuideConstraints)
        
        startArrowAnimation()
    }
    
    // MARK: - Animation
    
    private func startArrowAnimation() {
        arrowImageView.layer.removeAllAnimations()
        
        // Bouncing animation for the arrow
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                // Move arrow up and down slightly
                self.arrowImageView.transform = CGAffineTransform(translationX: 0, y: -8)
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
