//
//  CircleStyleDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit
import PolarisGuideKit

/// Demo: Circle Focus Style
/// Uses UISegmentedControl to switch between radius modes:
/// - scaledToFocusView: Circle radius scales with the view's size, perfect for dynamic UI elements
/// - fixed: Circle has a constant radius regardless of view size
final class CircleStyleDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?
    
    /// A circular icon view that demonstrates circle focus style
    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.40, blue: 0.45, alpha: 1.0)
        view.layer.cornerRadius = 36
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add gradient-like effect with inner shadow simulation
        let innerView = UIView()
        innerView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        innerView.layer.cornerRadius = 28
        innerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(innerView)
        
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        imageView.image = UIImage(systemName: "heart.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            innerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            innerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            innerView.widthAnchor.constraint(equalToConstant: 56),
            innerView.heightAnchor.constraint(equalToConstant: 56),
            
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        return view
    }()
    
    /// Decorative label under the icon
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.30, green: 0.30, blue: 0.35, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    /// UISegmentedControl for switching between radius modes
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            DemoStrings.Circle.segmentScaled,
            DemoStrings.Circle.segmentFixed
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
        control.selectedSegmentTintColor = UIColor(red: 0.95, green: 0.40, blue: 0.45, alpha: 1.0)
        
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
        button.backgroundColor = UIColor(red: 0.95, green: 0.40, blue: 0.45, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle shadow
        button.layer.shadowColor = UIColor(red: 0.95, green: 0.40, blue: 0.45, alpha: 1.0).cgColor
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
        updateSegmentedControl()
        refreshInfoCards()
    }
    
    // MARK: - Setup
    
    private func updateTexts() {
        iconLabel.text = DemoStrings.Circle.favorites
        modeTitleLabel.text = DemoStrings.Circle.radiusMode
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }
    
    private func updateSegmentedControl() {
        modeSegmentedControl.setTitle(DemoStrings.Circle.segmentScaled, forSegmentAt: 0)
        modeSegmentedControl.setTitle(DemoStrings.Circle.segmentFixed, forSegmentAt: 1)
    }
    
    private func setupUI() {
        view.addSubview(iconView)
        view.addSubview(iconLabel)
        view.addSubview(modeContainerView)
        modeContainerView.addSubview(modeTitleLabel)
        modeContainerView.addSubview(modeSegmentedControl)
        view.addSubview(scrollView)
        scrollView.addSubview(infoCardsStack)
        view.addSubview(startGuideButton)
        
        setupInfoCards()
        
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 72)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 72)
        
        NSLayoutConstraint.activate([
            // Icon view - circular element
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconWidthConstraint!,
            iconHeightConstraint!,
            
            // Icon label
            iconLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Mode container
            modeContainerView.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 24),
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
        let scaledInfo = createInfoCard(
            icon: "arrow.up.left.and.arrow.down.right.circle.fill",
            iconColor: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
            title: DemoStrings.Circle.scaledInfoTitle,
            description: DemoStrings.Circle.scaledInfoDesc
        )
        
        let fixedInfo = createInfoCard(
            icon: "circle.fill",
            iconColor: UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0),
            title: DemoStrings.Circle.fixedInfoTitle,
            description: DemoStrings.Circle.fixedInfoDesc
        )
        
        let demoInfo = createInfoCard(
            icon: "eye.fill",
            iconColor: UIColor(red: 0.60, green: 0.45, blue: 0.80, alpha: 1.0),
            title: DemoStrings.Circle.liveDemoTitle,
            description: DemoStrings.Circle.liveDemoDesc
        )
        
        infoCardsStack.addArrangedSubview(scaledInfo)
        infoCardsStack.addArrangedSubview(fixedInfo)
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
        // Reset iconView size to initial values
        iconWidthConstraint?.constant = 72
        iconHeightConstraint?.constant = 72
        iconView.layer.cornerRadius = 36
        view.layoutIfNeeded()
        
        // Create a single step based on the selected mode
        let step = GuideStep()
        step.focusView = iconView
        step.dismissesOnOutsideTap = true
        
        let selectedIndex = modeSegmentedControl.selectedSegmentIndex
        
        let circleStyle: CircleFocusStyle
        let buddyTitle: String
        let buddyMessage: String
        
        switch selectedIndex {
        case 0:
            // scaledToFocusView mode: radius scales with view size
            circleStyle = CircleFocusStyle(radiusMode: .scaledToFocusView(factor: 1.3))
            buddyTitle = DemoStrings.Circle.scaledBuddyTitle
            buddyMessage = DemoStrings.Circle.scaledBuddyMessage
            
        default:
            // fixed mode: constant radius
            circleStyle = CircleFocusStyle(radiusMode: .fixed(52))
            buddyTitle = DemoStrings.Circle.fixedBuddyTitle
            buddyMessage = DemoStrings.Circle.fixedBuddyMessage
        }
        
        step.focusStyle = circleStyle
        step.buddyView = SimpleBuddyView(
            title: buddyTitle,
            message: buddyMessage
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        
        controller.onDismiss = { [weak self] _, _ in
            guard let self = self else { return }
            // Restore focusView to initial state
            self.iconWidthConstraint?.constant = 72
            self.iconHeightConstraint?.constant = 72
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.iconView.layer.cornerRadius = 36
                self.view.layoutIfNeeded()
            }
            self.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
        
        // Schedule the size change after 1.5 seconds to demonstrate the mode behavior
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.guideController != nil else { return }
            self.iconWidthConstraint?.constant = 100
            self.iconHeightConstraint?.constant = 100
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                self.iconView.layer.cornerRadius = 50
                self.view.layoutIfNeeded()
            }
            self.guideController?.refreshOverlay(animated: true)
        }
    }
}
