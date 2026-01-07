//
//  DismissOnOutsideTapDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// Demo 8: Dismiss on Outside Tap
/// Shows dismissesOnOutsideTap behavior
final class DismissOnOutsideTapDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    
    /// Theme colors - teal/cyan palette
    private let themeColor = UIColor(red: 0.20, green: 0.60, blue: 0.65, alpha: 1.0)
    private let themeColorLight = UIColor(red: 0.20, green: 0.60, blue: 0.65, alpha: 0.12)
    
    /// Target card view with modern styling
    private lazy var targetCardView: UIView = {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 1.0)
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    private lazy var cardIconContainer: UIView = {
        let iconContainer = UIView()
        iconContainer.backgroundColor = themeColor
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        return iconContainer
    }()
    
    private lazy var cardIconImageView: UIImageView = {
        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconImageView.image = UIImage(systemName: "info.circle.fill", withConfiguration: config)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        return iconImageView
    }()
    
    private lazy var cardTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        return titleLabel
    }()
    
    private lazy var cardSubtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        return subtitleLabel
    }()
    
    private lazy var cardTextStack: UIStackView = {
        let textStack = UIStackView(arrangedSubviews: [cardTitleLabel, cardSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        return textStack
    }()
    
    private lazy var closeImageView: UIImageView = {
        let closeImageView = UIImageView()
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        closeImageView.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig)
        closeImageView.tintColor = UIColor.white.withAlphaComponent(0.4)
        closeImageView.contentMode = .scaleAspectFit
        closeImageView.translatesAutoresizingMaskIntoConstraints = false
        return closeImageView
    }()
    
    /// Status display card
    private lazy var statusCardView: UIView = {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 10
        card.layer.shadowOpacity = 0.05
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    private lazy var statusIconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.30, alpha: 0.15)
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var statusIconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        imageView.image = UIImage(systemName: "clock.fill", withConfiguration: config)
        imageView.tintColor = UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 1.0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statusTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.10, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Info cards container - wrapped in scroll view for smaller screens
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
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
        cardTitleLabel.text = DemoStrings.DismissOutside.importantInfo
        cardSubtitleLabel.text = DemoStrings.DismissOutside.tapOutsideToDismiss
        statusTitleLabel.text = DemoStrings.DismissOutside.status
        statusValueLabel.text = DemoStrings.DismissOutside.waiting
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }
    
    private func setupUI() {
        // Setup target card
        targetCardView.addSubview(cardIconContainer)
        cardIconContainer.addSubview(cardIconImageView)
        targetCardView.addSubview(cardTextStack)
        targetCardView.addSubview(closeImageView)
        
        view.addSubview(targetCardView)
        view.addSubview(statusCardView)
        statusCardView.addSubview(statusIconView)
        statusIconView.addSubview(statusIconImageView)
        statusCardView.addSubview(statusTitleLabel)
        statusCardView.addSubview(statusValueLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(infoCardsStack)
        view.addSubview(startGuideButton)
        
        setupInfoCards()
        
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Card icon
            cardIconImageView.centerXAnchor.constraint(equalTo: cardIconContainer.centerXAnchor),
            cardIconImageView.centerYAnchor.constraint(equalTo: cardIconContainer.centerYAnchor),
            
            cardIconContainer.leadingAnchor.constraint(equalTo: targetCardView.leadingAnchor, constant: 14),
            cardIconContainer.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            cardIconContainer.widthAnchor.constraint(equalToConstant: 40),
            cardIconContainer.heightAnchor.constraint(equalToConstant: 40),
            
            cardTextStack.leadingAnchor.constraint(equalTo: cardIconContainer.trailingAnchor, constant: 12),
            cardTextStack.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            cardTextStack.trailingAnchor.constraint(lessThanOrEqualTo: closeImageView.leadingAnchor, constant: -12),
            
            closeImageView.trailingAnchor.constraint(equalTo: targetCardView.trailingAnchor, constant: -16),
            closeImageView.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            closeImageView.widthAnchor.constraint(equalToConstant: 20),
            
            // Target card
            targetCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            targetCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            targetCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            targetCardView.heightAnchor.constraint(equalToConstant: 68),
            
            // Status card
            statusCardView.topAnchor.constraint(equalTo: targetCardView.bottomAnchor, constant: 16),
            statusCardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusCardView.widthAnchor.constraint(equalToConstant: 160),
            statusCardView.heightAnchor.constraint(equalToConstant: 72),
            
            statusIconView.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 14),
            statusIconView.centerYAnchor.constraint(equalTo: statusCardView.centerYAnchor),
            statusIconView.widthAnchor.constraint(equalToConstant: 36),
            statusIconView.heightAnchor.constraint(equalToConstant: 36),
            
            statusIconImageView.centerXAnchor.constraint(equalTo: statusIconView.centerXAnchor),
            statusIconImageView.centerYAnchor.constraint(equalTo: statusIconView.centerYAnchor),
            
            statusTitleLabel.topAnchor.constraint(equalTo: statusCardView.topAnchor, constant: 14),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 12),
            
            statusValueLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 2),
            statusValueLabel.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 12),
            
            // Scroll view for info cards
            scrollView.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startGuideButton.topAnchor, constant: -16),
            
            // Info cards stack inside scroll view
            infoCardsStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            infoCardsStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            infoCardsStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            infoCardsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            infoCardsStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
            
            // Start button
            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startGuideButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupInfoCards() {
        let dismissInfo = createInfoCard(
            icon: "hand.tap.fill",
            iconColor: themeColor,
            title: DemoStrings.DismissOutside.dismissInfoTitle,
            description: DemoStrings.DismissOutside.dismissInfoDesc
        )
        
        let callbackInfo = createInfoCard(
            icon: "arrow.turn.down.right",
            iconColor: UIColor(red: 0.60, green: 0.45, blue: 0.80, alpha: 1.0),
            title: DemoStrings.DismissOutside.callbackInfoTitle,
            description: DemoStrings.DismissOutside.callbackInfoDesc
        )
        
        let useCaseInfo = createInfoCard(
            icon: "lightbulb.fill",
            iconColor: UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0),
            title: DemoStrings.DismissOutside.useCaseInfoTitle,
            description: DemoStrings.DismissOutside.useCaseInfoDesc
        )
        
        infoCardsStack.addArrangedSubview(dismissInfo)
        infoCardsStack.addArrangedSubview(callbackInfo)
        infoCardsStack.addArrangedSubview(useCaseInfo)
    }
    
    private func refreshInfoCards() {
        infoCardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
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
    
    @objc private func startGuideTapped() {
        updateStatus(text: DemoStrings.DismissOutside.guideActive, color: UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0), icon: "play.circle.fill")
        
        let step = GuideStep()
        step.focusView = targetCardView
        step.dismissesOnOutsideTap = true  // Key setting!
        
        let roundedStyle = RoundedRectFocusStyle(
            focusCornerRadius: .fixed(20.0),
            focusAreaInsets: UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        )
        step.focusStyle = roundedStyle
        
        step.buddyView = SimpleBuddyView(
            title: DemoStrings.DismissOutside.buddyTitle,
            message: DemoStrings.DismissOutside.buddyMessage
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        controller.onDismiss = { [weak self] _, context in
            guard let self = self else { return }
            
            switch context.reason {
            case .outsideTap:
                self.updateStatus(text: DemoStrings.DismissOutside.dismissed, color: self.themeColor, icon: "xmark.circle.fill")
                print("📱 Guide dismissed by tapping outside")
            case .completed:
                self.updateStatus(text: DemoStrings.DismissOutside.completed, color: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0), icon: "checkmark.circle.fill")
                print("✅ Guide completed normally")
            case .skipped:
                print("⏭️ User skipped guide")
            case .completerTriggered:
                print("🔄 Guide auto-completed by completer")
            case .programmatic:
                print("🔧 Guide dismissed programmatically")
            }
            
            self.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
    }
    
    private func updateStatus(text: String, color: UIColor, icon: String) {
        statusValueLabel.text = text
        statusValueLabel.textColor = color
        
        statusIconView.backgroundColor = color.withAlphaComponent(0.15)
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        statusIconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        statusIconImageView.tintColor = color
        
        // Pulse animation
        UIView.animate(withDuration: 0.15, animations: {
            self.statusCardView.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.statusCardView.transform = .identity
            }
        }
    }
}
