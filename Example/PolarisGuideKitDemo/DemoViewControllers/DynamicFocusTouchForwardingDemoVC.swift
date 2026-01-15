//
//  DynamicFocusTouchForwardingDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/1/7.
//

import UIKit
import PolarisGuideKit

/// Demo: Dynamic FocusView & Touch Forwarding
/// Shows:
/// - focusViewProvider updates after reloadData
/// - forwardsTouchEventsToFocusView to interact with the highlighted cell
/// - GestureRecognizerCompleter attached to collectionView
final class DynamicFocusTouchForwardingDemoVC: UIViewController {
    
    // MARK: - Properties
    
    private var guideController: GuideController?
    private var sampleData: [String] = []
    
    private let targetIndexPath = IndexPath(item: 0, section: 0)
    
    /// Theme colors - blue/indigo palette
    private let themeColor = UIColor(red: 0.25, green: 0.35, blue: 0.85, alpha: 1.0)
    
    private let collectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        return layout
    }()
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.register(DemoCollectionCell.self, forCellWithReuseIdentifier: DemoCollectionCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateItemSizeIfNeeded()
    }
    
    // MARK: - Setup
    
    private func generateSampleData() {
        sampleData = (0..<12).map { "\(DemoStrings.DynamicFocusTouchForwarding.itemPrefix) \($0 + 1)" }
    }
    
    private func updateTexts() {
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
        generateSampleData()
        collectionView.reloadData()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(scrollView)
        scrollView.addSubview(infoCardsStack)
        view.addSubview(startGuideButton)
        
        setupInfoCards()
        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 240),
            
            scrollView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startGuideButton.topAnchor, constant: -16),
            
            infoCardsStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            infoCardsStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            infoCardsStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            infoCardsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            infoCardsStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startGuideButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupInfoCards() {
        let focusInfo = createInfoCard(
            icon: "sparkles.rectangle.stack",
            iconColor: themeColor,
            title: DemoStrings.DynamicFocusTouchForwarding.focusInfoTitle,
            description: DemoStrings.DynamicFocusTouchForwarding.focusInfoDesc
        )
        
        let touchInfo = createInfoCard(
            icon: "hand.tap.fill",
            iconColor: UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
            title: DemoStrings.DynamicFocusTouchForwarding.touchInfoTitle,
            description: DemoStrings.DynamicFocusTouchForwarding.touchInfoDesc
        )
        
        infoCardsStack.addArrangedSubview(focusInfo)
        infoCardsStack.addArrangedSubview(touchInfo)
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
    
    private func updateItemSizeIfNeeded() {
        let columns: CGFloat = 3
        let layout = collectionLayout
        let totalInsets = layout.sectionInset.left + layout.sectionInset.right
        let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalInsets - totalSpacing
        guard availableWidth > 0 else { return }
        
        let itemWidth = floor(availableWidth / columns)
        if layout.itemSize.width != itemWidth {
            layout.itemSize = CGSize(width: itemWidth, height: 72)
            layout.invalidateLayout()
        }
    }
    
    private func reloadDataForDemo() {
        sampleData.shuffle()
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func startGuideTapped() {
        let step = GuideStep()
        step.focusViewProvider = { [weak self] in
            guard let self else { return nil }
            var focusCell = self.collectionView.cellForItem(at: self.targetIndexPath)
            if focusCell == nil {
                self.collectionView.layoutIfNeeded()
                focusCell = self.collectionView.cellForItem(at: self.targetIndexPath)
            }
            return focusCell
        }
        step.forwardsTouchEventsToFocusView = true
        
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        step.gestureRecognizerWhitelist = [tap]
        step.completer = GestureRecognizerCompleter(view: collectionView, gestureRecognizer: tap)
        
        let roundedStyle = RoundedRectFocusStyle(
            focusCornerRadius: .fixed(12.0),
            focusAreaInsets: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        )
        step.focusStyle = roundedStyle
        
        step.buddyView = SimpleBuddyView(
            title: DemoStrings.DynamicFocusTouchForwarding.buddyTitle,
            message: DemoStrings.DynamicFocusTouchForwarding.buddyMessage
        )
        
        let controller = GuideController(hostView: navigationController?.view ?? view, steps: [step])
        controller.onDismiss = { [weak self] _, _ in
            self?.guideController = nil
        }
        
        _ = controller.show(animated: true)
        guideController = controller
        
        reloadDataForDemo()
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension DynamicFocusTouchForwardingDemoVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sampleData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DemoCollectionCell.reuseIdentifier,
            for: indexPath
        ) as? DemoCollectionCell else {
            return UICollectionViewCell()
        }
        
        let isPrimary = indexPath == targetIndexPath
        cell.configure(text: sampleData[indexPath.item], isPrimary: isPrimary, themeColor: themeColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let resultVC = DynamicFocusTouchForwardingResultViewController()
        navigationController?.pushViewController(resultVC, animated: true)
    }
}

// MARK: - DemoCollectionCell

private final class DemoCollectionCell: UICollectionViewCell {
    
    static let reuseIdentifier = "DemoCollectionCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOpacity = 0.04
        contentView.layer.masksToBounds = false
        
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(text: String, isPrimary: Bool, themeColor: UIColor) {
        titleLabel.text = text
        if isPrimary {
            titleLabel.textColor = themeColor
            titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            contentView.backgroundColor = themeColor.withAlphaComponent(0.12)
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = themeColor.withAlphaComponent(0.4).cgColor
        } else {
            titleLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
            titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            contentView.backgroundColor = .white
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
