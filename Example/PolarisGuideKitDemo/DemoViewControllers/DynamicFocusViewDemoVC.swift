//
//  DynamicFocusViewDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/1/7.
//

import UIKit
import PolarisGuideKit

/// Demo: Dynamic FocusView
/// Demonstrates focusViewProvider for UITableView/UICollectionView cell reuse scenarios
final class DynamicFocusViewDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    
    /// Whether to use dynamic focusViewProvider
    private var useDynamicFocusView: Bool = true
    
    /// Sample data for table view
    private var sampleData: [String] = []
    
    /// Theme colors - purple palette
    private let themeColor = UIColor(red: 0.55, green: 0.35, blue: 0.85, alpha: 1.0)
    private let themeColorLight = UIColor(red: 0.55, green: 0.35, blue: 0.85, alpha: 0.12)
    
    // MARK: - UI Components
    
    /// Switch container card
    private lazy var switchCardView: UIView = {
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
    
    private lazy var switchIconView: UIView = {
        let view = UIView()
        view.backgroundColor = themeColorLight
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var switchIconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        imageView.image = UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: config)
        imageView.tintColor = themeColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dynamicSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = true
        sw.onTintColor = themeColor
        sw.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()
    
    /// Table view for demonstrating cell reuse
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.backgroundColor = .clear
        tv.layer.cornerRadius = 14
        tv.clipsToBounds = true
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    /// Info cards container
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
        
        generateSampleData()
        setupUI()
        updateTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTexts()
        refreshInfoCards()
    }
    
    // MARK: - Setup
    
    private func generateSampleData() {
        sampleData = (0..<10).map { "\(DemoStrings.DynamicFocus.sampleRow) \($0)" }
    }
    
    private func updateTexts() {
        switchLabel.text = DemoStrings.DynamicFocus.useDynamicSwitch
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
        
        // Update sample data text for language change
        generateSampleData()
        tableView.reloadData()
    }
    
    private func setupUI() {
        // Switch card
        view.addSubview(switchCardView)
        switchCardView.addSubview(switchIconView)
        switchIconView.addSubview(switchIconImageView)
        switchCardView.addSubview(switchLabel)
        switchCardView.addSubview(dynamicSwitch)
        
        // Table view
        view.addSubview(tableView)
        
        // Scroll view for info cards
        view.addSubview(scrollView)
        scrollView.addSubview(infoCardsStack)
        
        // Start button
        view.addSubview(startGuideButton)
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        setupInfoCards()
        
        NSLayoutConstraint.activate([
            // Switch card
            switchCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            switchCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            switchCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCardView.heightAnchor.constraint(equalToConstant: 56),
            
            switchIconView.leadingAnchor.constraint(equalTo: switchCardView.leadingAnchor, constant: 14),
            switchIconView.centerYAnchor.constraint(equalTo: switchCardView.centerYAnchor),
            switchIconView.widthAnchor.constraint(equalToConstant: 36),
            switchIconView.heightAnchor.constraint(equalToConstant: 36),
            
            switchIconImageView.centerXAnchor.constraint(equalTo: switchIconView.centerXAnchor),
            switchIconImageView.centerYAnchor.constraint(equalTo: switchIconView.centerYAnchor),
            
            switchLabel.leadingAnchor.constraint(equalTo: switchIconView.trailingAnchor, constant: 12),
            switchLabel.centerYAnchor.constraint(equalTo: switchCardView.centerYAnchor),
            
            dynamicSwitch.trailingAnchor.constraint(equalTo: switchCardView.trailingAnchor, constant: -16),
            dynamicSwitch.centerYAnchor.constraint(equalTo: switchCardView.centerYAnchor),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: switchCardView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 180),
            
            // Scroll view for info cards
            scrollView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startGuideButton.topAnchor, constant: -16),
            
            infoCardsStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            infoCardsStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            infoCardsStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            infoCardsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            infoCardsStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            // Start button
            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startGuideButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupInfoCards() {
        let dynamicInfo = createInfoCard(
            icon: "arrow.triangle.2.circlepath",
            iconColor: themeColor,
            title: DemoStrings.DynamicFocus.dynamicInfoTitle,
            description: DemoStrings.DynamicFocus.dynamicInfoDesc
        )
        
        let staticInfo = createInfoCard(
            icon: "pin.fill",
            iconColor: UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0),
            title: DemoStrings.DynamicFocus.staticInfoTitle,
            description: DemoStrings.DynamicFocus.staticInfoDesc
        )
        
        let liveDemoInfo = createInfoCard(
            icon: "play.circle.fill",
            iconColor: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
            title: DemoStrings.DynamicFocus.liveDemoTitle,
            description: DemoStrings.DynamicFocus.liveDemoDesc
        )
        
        infoCardsStack.addArrangedSubview(dynamicInfo)
        infoCardsStack.addArrangedSubview(staticInfo)
        infoCardsStack.addArrangedSubview(liveDemoInfo)
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
    
    @objc private func switchValueChanged() {
        useDynamicFocusView = dynamicSwitch.isOn
        
        // Animate icon change
        UIView.animate(withDuration: 0.2) {
            self.switchIconView.backgroundColor = self.dynamicSwitch.isOn ? self.themeColorLight : UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 0.12)
            self.switchIconImageView.tintColor = self.dynamicSwitch.isOn ? self.themeColor : UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let iconName = dynamicSwitch.isOn ? "arrow.triangle.2.circlepath" : "pin.fill"
        switchIconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
    }
    
    @objc private func startGuideTapped() {
        // Get the first cell for highlighting
        let targetIndexPath = IndexPath(row: 0, section: 0)
        
        let step = GuideStep()
        step.dismissesOnOutsideTap = true
        
        if useDynamicFocusView {
            // Dynamic mode: use focusViewProvider closure
            step.focusViewProvider = { [weak self] in
                guard let self else { return nil }
                var focusCell = self.tableView.cellForRow(at: targetIndexPath)
                if focusCell == nil {
                    self.tableView.layoutIfNeeded()
                    focusCell = self.tableView.cellForRow(at: targetIndexPath)
                }
                return focusCell
            }
            step.buddyView = SimpleBuddyView(
                title: DemoStrings.DynamicFocus.dynamicBuddyTitle,
                message: DemoStrings.DynamicFocus.dynamicBuddyMessage
            )
        } else {
            // Static mode: set focusView directly
            step.focusView = tableView.cellForRow(at: targetIndexPath)
            step.buddyView = SimpleBuddyView(
                title: DemoStrings.DynamicFocus.staticBuddyTitle,
                message: DemoStrings.DynamicFocus.staticBuddyMessage
            )
        }
        
        let roundedStyle = RoundedRectFocusStyle(
            focusCornerRadius: .fixed(12.0),
            focusAreaInsets: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        )
        step.focusStyle = roundedStyle
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        controller.onDismiss = { [weak self] _, _ in
            self?.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
        
        // Trigger reloadData after 2 seconds to demonstrate the difference
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.guideController != nil else { return }
            
            // Shuffle data to simulate real-world scenario
            self.sampleData.shuffle()
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension DynamicFocusViewDemoVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = sampleData[indexPath.row]
            
            // Highlight first row with special styling
            if indexPath.row == 0 {
                content.textProperties.color = themeColor
                content.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
            } else {
                content.textProperties.color = .label
                content.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
            }
            
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = sampleData[indexPath.row]
            if indexPath.row == 0 {
                cell.textLabel?.textColor = themeColor
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            } else {
                cell.textLabel?.textColor = .label
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
