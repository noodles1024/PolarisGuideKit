//
//  TalkingBuddyView.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import Lottie
import PolarisGuideKit
import UIKit

final class TalkingBuddyView: GuideBuddyView, GuideAudioEventReceiving {

    // MARK: - Properties

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let statusLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    private var isAnimationLoaded = false
    private var isAudioPlaying = false

    private lazy var animationView: LottieAnimationView = {
        let subdirectory: String? = Bundle.main.url(
            forResource: "talking_man",
            withExtension: "lottie",
            subdirectory: "Resource"
        ) != nil ? "Resource" : nil

        let view = LottieAnimationView(
            dotLottieName: "talking_man",
            bundle: .main,
            subdirectory: subdirectory
        ) { [weak self] _, error in
            self?.handleAnimationLoad(error)
        }
        view.contentMode = .scaleAspectFill
        view.loopMode = .loop
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var layoutGuideConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialization

    init(title: String, message: String, actionTitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        messageLabel.text = message
        actionButton.setTitle(actionTitle, for: .normal)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.18
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = DemoStrings.AudioGuide.statusWaiting
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        actionButton.backgroundColor = .systemBlue
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        actionButton.layer.cornerRadius = 10
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(animationView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),

            animationView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 120),
            animationView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            actionButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - GuideBuddyView Override

    override func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
        super.updateLayout(referenceLayoutGuide: layoutGuide, focusView: focusView)

        NSLayoutConstraint.deactivate(layoutGuideConstraints)

        let minTopSpacing = containerView.topAnchor.constraint(
            greaterThanOrEqualTo: layoutGuide.bottomAnchor,
            constant: 16
        )
        minTopSpacing.priority = .defaultHigh
        layoutGuideConstraints = [minTopSpacing]
        NSLayoutConstraint.activate(layoutGuideConstraints)
    }

    // MARK: - GuideAudioEventReceiving

    func guideAudioDidStart() {
        isAudioPlaying = true
        statusLabel.text = DemoStrings.AudioGuide.statusPlaying
        statusLabel.textColor = .systemBlue
        animationView.play()
    }

    func guideAudioDidStop(didPlayToEnd: Bool) {
        isAudioPlaying = false
        if didPlayToEnd {
            statusLabel.text = DemoStrings.AudioGuide.statusFinished
            statusLabel.textColor = .secondaryLabel
        } else {
            // The audio was stopped by the plugin (e.g. step dismissed / replaced).
            statusLabel.text = DemoStrings.AudioGuide.statusWaiting
            statusLabel.textColor = .secondaryLabel
        }
        animationView.stop()
        animationView.currentProgress = 0
    }

    func guideAudioDidFail(_ error: Error) {
        isAudioPlaying = false
        statusLabel.text = DemoStrings.AudioGuide.statusFailed
        statusLabel.textColor = .systemRed
        animationView.stop()
        animationView.currentProgress = 0
        print("⚠️ Audio playback failed: \(error)")
    }

    // MARK: - Actions

    @objc private func actionButtonTapped() {
        requestNext()
    }

    // MARK: - UIView Overrides

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            animationView.stop()
        }
    }

    // MARK: - Public helpers

    func setStatusText(_ text: String, color: UIColor? = nil) {
        statusLabel.text = text
        if let color {
            statusLabel.textColor = color
        }
    }

    // MARK: - Private helpers

    private func handleAnimationLoad(_ error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let error {
                print("⚠️ Lottie load failed: \(error)")
            }
            self.isAnimationLoaded = (error == nil)
            if self.isAudioPlaying {
                self.animationView.play()
            }
        }
    }
}
