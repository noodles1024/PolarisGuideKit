//
//  RoundedRectStyleDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// Demo: Rounded Rect Focus Style
/// Uses UISegmentedControl to switch between three focusCornerRadius modes:
/// - fixed: Focus area corner radius remains constant
/// - followFocusView: Focus area corner radius = focusView's corner radius + delta
/// - scaleWithFocusView: Focus area corner radius = focusView's corner radius × multiplier
final class RoundedRectStyleDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    
    /// A horizontal card-style view that better demonstrates rounded rect focus style
    private lazy var featureCardView: UIView = {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 1.0)
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    private lazy var iconContainer: UIView = {
        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        return iconContainer
    }()
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconImageView.image = UIImage(systemName: "sparkles", withConfiguration: config)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        return iconImageView
    }()
    
    private lazy var cardTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        return titleLabel
    }()
    
    private lazy var cardSubtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        return subtitleLabel
    }()
    
    private lazy var textStack: UIStackView = {
        let textStack = UIStackView(arrangedSubviews: [cardTitleLabel, cardSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        return textStack
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView()
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        arrowImageView.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrowImageView.tintColor = UIColor.white.withAlphaComponent(0.5)
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        return arrowImageView
    }()
    
    /// Container for the mode selection
    private let modeContainerView: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let modeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// UISegmentedControl for switching between three corner radius modes
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            DemoStrings.RoundedRect.segmentFixed,
            DemoStrings.RoundedRect.segmentFollow,
            DemoStrings.RoundedRect.segmentScale
        ])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        
        // Style the segmented control
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.35, green: 0.35, blue: 0.40, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        control.setTitleTextAttributes(normalAttributes, for: .normal)
        control.setTitleTextAttributes(selectedAttributes, for: .selected)
        control.selectedSegmentTintColor = UIColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 1.0)
        
        return control
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
        button.backgroundColor = UIColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow
        button.layer.shadowColor = UIColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 1.0).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.3
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        updateTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTexts()
        updateSegmentedControl()
        refreshInfoCards()
    }
    
    // MARK: - Setup
    
    private func updateTexts() {
        cardTitleLabel.text = DemoStrings.RoundedRect.premiumFeatures
        cardSubtitleLabel.text = DemoStrings.RoundedRect.unlockTools
        modeTitleLabel.text = DemoStrings.RoundedRect.cornerRadiusMode
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }
    
    private func updateSegmentedControl() {
        modeSegmentedControl.setTitle(DemoStrings.RoundedRect.segmentFixed, forSegmentAt: 0)
        modeSegmentedControl.setTitle(DemoStrings.RoundedRect.segmentFollow, forSegmentAt: 1)
        modeSegmentedControl.setTitle(DemoStrings.RoundedRect.segmentScale, forSegmentAt: 2)
    }
    
    private func setupGradientBackground() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
    }
    
    private func setupUI() {
        // Setup feature card
        featureCardView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        featureCardView.addSubview(textStack)
        featureCardView.addSubview(arrowImageView)
        
        view.addSubview(featureCardView)
        view.addSubview(modeContainerView)
        modeContainerView.addSubview(modeTitleLabel)
        modeContainerView.addSubview(modeSegmentedControl)
        view.addSubview(scrollView)
        scrollView.addSubview(infoCardsStack)
        view.addSubview(startGuideButton)
        
        setupInfoCards()
        
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Icon container
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            iconContainer.leadingAnchor.constraint(equalTo: featureCardView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: featureCardView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: featureCardView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -12),
            
            arrowImageView.trailingAnchor.constraint(equalTo: featureCardView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: featureCardView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            
            // Feature card - wider horizontal card
            featureCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            featureCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            featureCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            featureCardView.heightAnchor.constraint(equalToConstant: 72),
            
            // Mode container
            modeContainerView.topAnchor.constraint(equalTo: featureCardView.bottomAnchor, constant: 20),
            modeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            modeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            modeTitleLabel.topAnchor.constraint(equalTo: modeContainerView.topAnchor, constant: 12),
            modeTitleLabel.leadingAnchor.constraint(equalTo: modeContainerView.leadingAnchor, constant: 16),
            
            modeSegmentedControl.topAnchor.constraint(equalTo: modeTitleLabel.bottomAnchor, constant: 8),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: modeContainerView.leadingAnchor, constant: 16),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: modeContainerView.trailingAnchor, constant: -16),
            modeSegmentedControl.bottomAnchor.constraint(equalTo: modeContainerView.bottomAnchor, constant: -12),
            modeSegmentedControl.heightAnchor.constraint(equalToConstant: 34),
            
            // Scroll view for info cards
            scrollView.topAnchor.constraint(equalTo: modeContainerView.bottomAnchor, constant: 16),
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
        let fixedInfo = createInfoCard(
            icon: "lock.fill",
            iconColor: UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0),
            title: DemoStrings.RoundedRect.fixedInfoTitle,
            description: DemoStrings.RoundedRect.fixedInfoDesc
        )
        
        let followInfo = createInfoCard(
            icon: "plus.forwardslash.minus",
            iconColor: UIColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 1.0),
            title: DemoStrings.RoundedRect.followInfoTitle,
            description: DemoStrings.RoundedRect.followInfoDesc
        )
        
        let scaleInfo = createInfoCard(
            icon: "arrow.up.left.and.arrow.down.right",
            iconColor: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
            title: DemoStrings.RoundedRect.scaleInfoTitle,
            description: DemoStrings.RoundedRect.scaleInfoDesc
        )
        
        let demoInfo = createInfoCard(
            icon: "eye.fill",
            iconColor: UIColor(red: 0.60, green: 0.45, blue: 0.80, alpha: 1.0),
            title: DemoStrings.RoundedRect.liveDemoTitle,
            description: DemoStrings.RoundedRect.liveDemoDesc
        )
        
        infoCardsStack.addArrangedSubview(fixedInfo)
        infoCardsStack.addArrangedSubview(followInfo)
        infoCardsStack.addArrangedSubview(scaleInfo)
        infoCardsStack.addArrangedSubview(demoInfo)
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
        // Reset corner radius to initial value
        featureCardView.layer.cornerRadius = 16
        
        // Create a single step based on the selected mode
        let step = GuideStep()
        step.focusView = featureCardView
        step.dismissesOnOutsideTap = true
        
        let selectedIndex = modeSegmentedControl.selectedSegmentIndex
        
        let roundedStyle: RoundedRectFocusStyle
        let buddyTitle: String
        let buddyMessage: String
        
        switch selectedIndex {
        case 0:
            // fixed mode: corner radius remains constant
            roundedStyle = RoundedRectFocusStyle(
                focusCornerRadius: .fixed(20),
                focusAreaInsets: UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
            )
            buddyTitle = DemoStrings.RoundedRect.fixedBuddyTitle
            buddyMessage = DemoStrings.RoundedRect.fixedBuddyMessage
            
        case 1:
            // followFocusView mode: corner radius = focusView.cornerRadius + delta
            roundedStyle = RoundedRectFocusStyle(
                focusCornerRadius: .followFocusView(delta: 2),
                focusAreaInsets: UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
            )
            buddyTitle = DemoStrings.RoundedRect.followBuddyTitle
            buddyMessage = DemoStrings.RoundedRect.followBuddyMessage
            
        default:
            // scaleWithFocusView mode: corner radius = focusView.cornerRadius × multiplier
            roundedStyle = RoundedRectFocusStyle(
                focusCornerRadius: .scaleWithFocusView(multiplier: 1.25),
                focusAreaInsets: UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
            )
            buddyTitle = DemoStrings.RoundedRect.scaleBuddyTitle
            buddyMessage = DemoStrings.RoundedRect.scaleBuddyMessage
        }
        
        step.focusStyle = roundedStyle
        step.buddyView = SimpleBuddyView(
            title: buddyTitle,
            message: buddyMessage
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        
        controller.onDismiss = { [weak self] _, _ in
            guard let self = self else { return }
            // Restore focusView to initial state
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.featureCardView.layer.cornerRadius = 16
            }
            self.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
        
        // Schedule the corner radius change after 1.5 seconds to demonstrate the mode behavior
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.guideController != nil else { return }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                self.featureCardView.layer.cornerRadius = 28
            }
            self.guideController?.refreshOverlay(animated: true)
        }
    }
}
