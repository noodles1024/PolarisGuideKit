//
//  MultiStepGuideDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// Demo: Multi-Step Guide
/// Shows how to create a multi-step guide with:
/// - RoundedRectFocusStyle for all steps
/// - Skip button functionality
/// - Step change animations
final class MultiStepGuideDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    
    // Modern color palette
    private let primaryColor = UIColor(red: 0.36, green: 0.42, blue: 0.98, alpha: 1.0)    // Indigo blue
    private let secondaryColor = UIColor(red: 0.29, green: 0.80, blue: 0.64, alpha: 1.0)  // Mint green
    private let accentColor = UIColor(red: 0.98, green: 0.58, blue: 0.38, alpha: 1.0)     // Coral
    private let ctaColor = UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1.0)        // Purple
    
    private lazy var button1: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = primaryColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = primaryColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var button2: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = secondaryColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = secondaryColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var button3: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = accentColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = accentColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [button1, button2, button3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.08
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cardTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var featureStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ctaColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startGuideButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = ctaColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.layer.shadowColor = ctaColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        updateTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTexts()
        refreshFeatureItems()
    }
    
    // MARK: - Setup
    
    private func updateTexts() {
        button1.setTitle(DemoStrings.MultiStep.step1, for: .normal)
        button2.setTitle(DemoStrings.MultiStep.step2, for: .normal)
        button3.setTitle(DemoStrings.MultiStep.step3, for: .normal)
        cardTitleLabel.text = DemoStrings.MultiStep.aboutThisDemo
        tipLabel.text = DemoStrings.MultiStep.tipLabel
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }
    
    private func setupUI() {
        view.addSubview(buttonStackView)
        view.addSubview(cardView)
        cardView.addSubview(cardTitleLabel)
        cardView.addSubview(featureStackView)
        cardView.addSubview(tipLabel)
        view.addSubview(startGuideButton)
        
        // Create feature items
        setupFeatureItems()
        
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Button stack
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            buttonStackView.heightAnchor.constraint(equalToConstant: 56),
            
            // Card view
            cardView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 32),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Card title
            cardTitleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            cardTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            cardTitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            // Feature stack
            featureStackView.topAnchor.constraint(equalTo: cardTitleLabel.bottomAnchor, constant: 16),
            featureStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            featureStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            // Tip label
            tipLabel.topAnchor.constraint(equalTo: featureStackView.bottomAnchor, constant: 16),
            tipLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            tipLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            tipLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            // Start button
            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            startGuideButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }
    
    private func setupFeatureItems() {
        let features = [
            ("checkmark.circle.fill", DemoStrings.MultiStep.feature1, primaryColor),
            ("forward.fill", DemoStrings.MultiStep.feature2, secondaryColor),
            ("sparkles", DemoStrings.MultiStep.feature3, accentColor)
        ]
        
        for (icon, text, color) in features {
            let itemView = createFeatureItem(icon: icon, text: text, color: color)
            featureStackView.addArrangedSubview(itemView)
        }
    }
    
    private func refreshFeatureItems() {
        featureStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        setupFeatureItems()
    }
    
    private func createFeatureItem(icon: String, text: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.textColor = .secondaryLabel
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconImageView)
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func startGuideTapped() {
        // Unified RoundedRectFocusStyle: cornerRadius = original + 2, insets = -4 (expand outward)
        let unifiedFocusStyle = RoundedRectFocusStyle(
            focusCornerRadius: .followFocusView(delta: 2),
            focusAreaInsets: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        )
        
        // Step 1
        let step1 = GuideStep()
        step1.focusView = button1
        step1.focusStyle = unifiedFocusStyle
        step1.buddyView = SimpleBuddyView(
            title: DemoStrings.MultiStep.step1of3Title,
            message: DemoStrings.MultiStep.step1Message,
            showNextButton: true,
            showSkipButton: true
        )
        
        // Step 2
        let step2 = GuideStep()
        step2.focusView = button2
        step2.focusStyle = unifiedFocusStyle
        step2.buddyView = SimpleBuddyView(
            title: DemoStrings.MultiStep.step2of3Title,
            message: DemoStrings.MultiStep.step2Message,
            showNextButton: true,
            showSkipButton: true
        )
        
        // Step 3
        let step3 = GuideStep()
        step3.focusView = button3
        step3.focusStyle = unifiedFocusStyle
        step3.buddyView = SimpleBuddyView(
            title: DemoStrings.MultiStep.step3of3Title,
            message: DemoStrings.MultiStep.step3Message,
            showNextButton: true,
            showSkipButton: false
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step1, step2, step3])
        controller.animatesStepTransition = true
        
        controller.onStepChange = { controller in
            print("📍 Step changed to index: \(controller.currentStepIndex)")
        }
        
        controller.onDismiss = { [weak self] _, context in
            switch context.reason {
            case .completed:
                print("✅ Multi-step guide completed!")
            case .skipped:
                print("⏭️ User skipped guide at step \(context.lastStepIndex)")
            case .outsideTap:
                print("👆 Guide dismissed by tapping outside")
            case .completerTriggered:
                print("🔄 Guide auto-completed by completer")
            case .programmatic:
                print("🔧 Guide dismissed programmatically")
            }
            self?.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
    }
}
