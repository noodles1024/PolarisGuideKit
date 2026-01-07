//
//  SimpleBuddyView.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// A simple buddy view with title, message, and optional next/skip buttons
final class SimpleBuddyView: GuideBuddyView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private let buttonStackView = UIStackView()
    private let showNextButton: Bool
    private let showSkipButton: Bool
    
    // MARK: - Initialization
    
    init(title: String, message: String, showNextButton: Bool = false, showSkipButton: Bool = false) {
        self.showNextButton = showNextButton
        self.showSkipButton = showSkipButton
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
        // Container styling
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Title label
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message label
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        let hasButtons = showNextButton || showSkipButton
        
        if hasButtons {
            // Button stack view
            buttonStackView.axis = .horizontal
            buttonStackView.spacing = 16
            buttonStackView.alignment = .center
            buttonStackView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(buttonStackView)
            
            // Skip button (optional)
            if showSkipButton {
                skipButton.setTitle(DemoStrings.Common.skip, for: .normal)
                skipButton.titleLabel?.font = .systemFont(ofSize: 16)
                skipButton.setTitleColor(.secondaryLabel, for: .normal)
                skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
                buttonStackView.addArrangedSubview(skipButton)
            }
            
            // Spacer
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            buttonStackView.addArrangedSubview(spacer)
            
            // Next button (optional)
            if showNextButton {
                nextButton.setTitle(DemoStrings.Common.next, for: .normal)
                nextButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
                nextButton.setTitleColor(.systemBlue, for: .normal)
                nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
                buttonStackView.addArrangedSubview(nextButton)
            }
        }
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
        
        if hasButtons {
            NSLayoutConstraint.activate([
                buttonStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
                buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            ])
        } else {
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func nextButtonTapped() {
        requestNext()
    }
    
    @objc private func skipButtonTapped() {
        requestSkip()
    }
}
