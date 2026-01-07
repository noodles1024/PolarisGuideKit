//
//  DemoBuddyView.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// A custom buddy view with Next and Skip buttons
/// Demonstrates how to subclass GuideBuddyView with custom styling
final class DemoBuddyView: GuideBuddyView {
    
    // MARK: - Properties
    
    var titleText: String = "" {
        didSet { titleLabel.text = titleText }
    }
    
    var messageText: String = "" {
        didSet { messageLabel.text = messageText }
    }
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private let buttonStack = UIStackView()
    
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
        // Container styling - distinctive indigo theme
        containerView.backgroundColor = UIColor.systemIndigo
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 15
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Title label - white text
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message label - semi-transparent white
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Next button - white background, indigo text
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.systemIndigo, for: .normal)
        nextButton.backgroundColor = .white
        nextButton.layer.cornerRadius = 10
        nextButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Skip button - semi-transparent white background
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        skipButton.layer.cornerRadius = 10
        skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Button stack
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(skipButton)
        buttonStack.addArrangedSubview(nextButton)
        containerView.addSubview(buttonStack)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            buttonStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func nextButtonTapped() {
        requestNext()
    }
    
    @objc private func skipButtonTapped() {
        requestSkip()
    }
}

