//
//  GuideWithAudioDemoVC.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import PolarisGuideKit
import UIKit

/// Demo: Guide + Audio
/// Shows how to sync animation with audio playback in a buddy view.
final class GuideWithAudioDemoVC: UIViewController {

    // MARK: - Properties

    private var guideController: GuideController?

    private let themeColor = UIColor(red: 0.23, green: 0.56, blue: 0.90, alpha: 1.0)
    private let accentColor = UIColor(red: 0.98, green: 0.66, blue: 0.25, alpha: 1.0)

    private lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerTitleLabel, headerSubtitleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var targetCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cardIconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = themeColor.withAlphaComponent(0.18)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cardIconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let imageView = UIImageView(image: UIImage(systemName: "waveform", withConfiguration: config))
        imageView.tintColor = themeColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var cardTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var cardSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var cardTextStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cardTitleLabel, cardSubtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var cardChevronImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var startGuideButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = accentColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.shadowColor = accentColor.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
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
    }

    // MARK: - Setup

    private func updateTexts() {
        headerTitleLabel.text = DemoStrings.AudioGuide.headerTitle
        headerSubtitleLabel.text = DemoStrings.AudioGuide.headerSubtitle
        cardTitleLabel.text = DemoStrings.AudioGuide.cardTitle
        cardSubtitleLabel.text = DemoStrings.AudioGuide.cardSubtitle
        startGuideButton.setTitle(DemoStrings.Common.startGuide, for: .normal)
    }

    private func setupUI() {
        view.addSubview(headerStackView)
        view.addSubview(targetCardView)
        view.addSubview(startGuideButton)

        targetCardView.addSubview(cardIconContainer)
        cardIconContainer.addSubview(cardIconImageView)
        targetCardView.addSubview(cardTextStack)
        targetCardView.addSubview(cardChevronImageView)

        startGuideButton.addTarget(self, action: #selector(startGuideTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            targetCardView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 28),
            targetCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            targetCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            targetCardView.heightAnchor.constraint(equalToConstant: 50),

            cardIconContainer.leadingAnchor.constraint(equalTo: targetCardView.leadingAnchor, constant: 16),
            cardIconContainer.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            cardIconContainer.widthAnchor.constraint(equalToConstant: 48),
            cardIconContainer.heightAnchor.constraint(equalToConstant: 48),

            cardIconImageView.centerXAnchor.constraint(equalTo: cardIconContainer.centerXAnchor),
            cardIconImageView.centerYAnchor.constraint(equalTo: cardIconContainer.centerYAnchor),

            cardTextStack.leadingAnchor.constraint(equalTo: cardIconContainer.trailingAnchor, constant: 12),
            cardTextStack.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            cardTextStack.trailingAnchor.constraint(equalTo: cardChevronImageView.leadingAnchor, constant: -12),

            cardChevronImageView.trailingAnchor.constraint(equalTo: targetCardView.trailingAnchor, constant: -16),
            cardChevronImageView.centerYAnchor.constraint(equalTo: targetCardView.centerYAnchor),
            cardChevronImageView.widthAnchor.constraint(equalToConstant: 12),
            cardChevronImageView.heightAnchor.constraint(equalToConstant: 12),

            startGuideButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            startGuideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            startGuideButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            startGuideButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    // MARK: - Actions

    @objc private func startGuideTapped() {
        let step = GuideStep()
        step.focusView = targetCardView
        step.focusStyle = RoundedRectFocusStyle(
            focusCornerRadius: .followFocusView(delta: 1),
            focusAreaInsets: UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
        )
        let buddyView = TalkingBuddyView(
            title: DemoStrings.AudioGuide.buddyTitle,
            message: DemoStrings.AudioGuide.buddyMessage,
            actionTitle: DemoStrings.AudioGuide.buddyAction
        )
        step.buddyView = buddyView

        if let url = resourceURL(name: "guide_audio_1", extension: "mp3") {
            step.addAttachment(GuideAudioAttachment(url: url, volume: 1.0))
        } else {
            print("⚠️ guide_audio_1.mp3 not found in bundle.")
            buddyView.setStatusText(DemoStrings.AudioGuide.statusMissingAudio, color: .systemRed)
        }

        let controller = GuideController(
            hostView: navigationController?.view ?? view,
            steps: [step],
            plugins: [AudioGuidePlugin()]
        )
        controller.onDismiss = { [weak self] _, _ in
            self?.guideController = nil
        }

        _ = controller.show(animated: true)
        guideController = controller
    }

    private func resourceURL(name: String, extension fileExtension: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: fileExtension)
    }
}
