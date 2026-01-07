//
//  TouchForwardingDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// Demo: Touch Forwarding
/// Shows:
/// - forwardsTouchEventsToFocusView to allow interaction with the highlighted element
/// - ControlEventCompleter to auto-complete when the button is tapped
/// - HintArrowBuddyView to explain the interaction with an arrow and text
final class TouchForwardingDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    
    /// Theme colors - warm coral/orange palette
    private let themeColor = UIColor(red: 0.98, green: 0.45, blue: 0.35, alpha: 1.0)
    
    /// Interactive button with custom styling
    private lazy var interactiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = themeColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow
        button.layer.shadowColor = themeColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.35
        
        // Add icon
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: "hand.tap.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        return button
    }()
    
    /// Main scroll view to wrap all content except the start button
    private let mainScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = true
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    /// Content view inside the scroll view
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoCardsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var startGuideButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = themeColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow
        button.layer.shadowColor = themeColor.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.3
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        setupUI()
        updateTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTexts()
        refreshInfoCards()
    }
    
    // MARK: - Setup
    
    private func updateTexts() {
        interactiveButton.setTitle(DemoStrings.TouchForwarding.tapMeButton, for: .normal)
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }
    
    private func setupUI() {
        // Add main scroll view and start button to main view
        view.addSubview(mainScrollView)
        view.addSubview(startGuideButton)
        
        // Add content view to scroll view
        mainScrollView.addSubview(contentView)
        
        // Add all scrollable content to content view
        contentView.addSubview(interactiveButton)
        contentView.addSubview(infoCardsStack)
        
        setupInfoCards()
        
        interactiveButton.addTarget(self, action: #selector(interactiveButtonTapped), for: .touchUpInside)
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Main scroll view - fills the area above start button
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: startGuideButton.topAnchor, constant: -16),
            
            // Content view inside scroll view
            contentView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            
            // Interactive button - center upper area
            interactiveButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            interactiveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            interactiveButton.widthAnchor.constraint(equalToConstant: 180),
            interactiveButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Info cards stack
            infoCardsStack.topAnchor.constraint(equalTo: interactiveButton.bottomAnchor, constant: 32),
            infoCardsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            infoCardsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            infoCardsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Start button - fixed at bottom
            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startGuideButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupInfoCards() {
        let touchForwardInfo = createInfoCard(
            icon: "hand.point.up.left.fill",
            iconColor: themeColor,
            title: DemoStrings.TouchForwarding.touchForwardingInfoTitle,
            description: DemoStrings.TouchForwarding.touchForwardingInfoDesc
        )
        
        let completerInfo = createInfoCard(
            icon: "checkmark.circle.fill",
            iconColor: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
            title: DemoStrings.TouchForwarding.completerInfoTitle,
            description: DemoStrings.TouchForwarding.completerInfoDesc
        )
        
        
        let arrowBuddyInfo = createInfoCard(
            icon: "arrow.up.circle.fill",
            iconColor: UIColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 1.0),
            title: DemoStrings.TouchForwarding.arrowBuddyInfoTitle,
            description: DemoStrings.TouchForwarding.arrowBuddyInfoDesc
        )
        
        infoCardsStack.addArrangedSubview(touchForwardInfo)
        infoCardsStack.addArrangedSubview(completerInfo)
        infoCardsStack.addArrangedSubview(arrowBuddyInfo)
    }
    
    private func refreshInfoCards() {
        // Remove all existing cards
        infoCardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Re-add with updated strings
        setupInfoCards()
    }
    
    private func createInfoCard(icon: String, iconColor: UIColor, title: String, description: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.04
        
        let iconView = UIView()
        iconView.backgroundColor = iconColor.withAlphaComponent(0.12)
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 12, weight: .regular)
        descLabel.textColor = UIColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 1.0)
        descLabel.numberOfLines = 0
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(iconView)
        card.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        
        return card
    }
    
    // MARK: - Actions
    
    @objc private func interactiveButtonTapped() {
        // Visual feedback - pulse animation
        UIView.animate(withDuration: 0.1, animations: {
            self.interactiveButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0) {
                self.interactiveButton.transform = .identity
            }
        }
        
        // 跳转到结果页面 - 证明新手引导没有侵入原有的点击处理逻辑
        let resultVC = TapResultViewController()
        navigationController?.pushViewController(resultVC, animated: true)
    }
    
    @objc private func startGuideTapped() {
        let step = GuideStep()
        step.focusView = interactiveButton
        step.forwardsTouchEventsToFocusView = true
        step.completer = ControlEventCompleter(control: interactiveButton, event: .touchUpInside)
        
        // Use RoundedRectFocusStyle to highlight the button
        let roundedStyle = RoundedRectFocusStyle(
            focusCornerRadius: .fixed(20),
            focusAreaInsets: UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        )
        step.focusStyle = roundedStyle
        
        // Use HintArrowBuddyView to explain the interaction with an arrow
        step.buddyView = HintArrowBuddyView(
            title: DemoStrings.TouchForwarding.hintBuddyTitle,
            message: DemoStrings.TouchForwarding.hintBuddyMessage
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        controller.onDismiss = { [weak self] _, context in
            print("🎉 Guide dismissed: \(context.reason)")
            self?.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
    }
}
