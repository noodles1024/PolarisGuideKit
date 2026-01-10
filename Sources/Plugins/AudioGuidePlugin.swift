//
//  AudioGuidePlugin.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/8/21.
//  Copyright © 2025 noodles. All rights reserved.
//

import AVFoundation
import UIKit

/// Attachment that provides audio playback configuration for a guide step.
public final class GuideAudioAttachment: GuideStepAttachment {
    public let url: URL
    public let volume: Float

    public init(url: URL, volume: Float = 1.0) {
        self.url = url
        self.volume = volume
    }
}

/// Optional protocol that a buddy view can adopt to receive audio events.
public protocol GuideAudioEventReceiving: AnyObject {
    /// Called right after the plugin starts playback for the current step.
    func guideAudioDidStart()
    /// Called when the plugin stops playback (or clears the player item).
    ///
    /// - Parameter didPlayToEnd: `true` if the audio played to the end naturally. `false` if it was
    ///   stopped for other reasons (e.g. step/guide dismissed, next step replaced the current item).
    func guideAudioDidStop(didPlayToEnd: Bool)
    /// Called when audio playback fails (e.g. network/decoding/format error).
    func guideAudioDidFail(_ error: Error)
}

/// Audio playback plugin for guide steps.
///
/// Note: You may need to set the correct `AVAudioSessionCategory` for your
///       application to ensure audio plays as expected.
public final class AudioGuidePlugin: GuidePlugin {

    private let audioPlayer = AVPlayer()
    private var audioDidFinishObserver: NSObjectProtocol?
    private var audioDidFailObserver: NSObjectProtocol?
    private weak var currentBuddyView: GuideBuddyView?

    public init() {}

    deinit {
        stopPlayback(didPlayToEnd: false, notifyStop: false)
    }

    public func handle(_ event: GuideEvent, context: GuideStepContext) {
        switch event {
        case .stepDidShow:
            startPlaybackIfNeeded(context: context)
        case .stepWillHide, .guideWillHide:
            stopPlayback(didPlayToEnd: false)
        default:
            break
        }
    }

    private func startPlaybackIfNeeded(context: GuideStepContext) {
        stopPlayback(didPlayToEnd: false)
        guard let attachment = context.step.attachment(ofType: GuideAudioAttachment.self) else {
            return
        }

        let playerItem = AVPlayerItem(url: attachment.url)
        audioPlayer.replaceCurrentItem(with: playerItem)
        audioPlayer.volume = attachment.volume
        currentBuddyView = context.buddyView
        audioPlayer.play()

        notifyAudioDidStart()
        observePlaybackEvents(for: playerItem)
    }

    private func observePlaybackEvents(for item: AVPlayerItem) {
        if let token = audioDidFinishObserver {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = audioDidFailObserver {
            NotificationCenter.default.removeObserver(token)
        }

        audioDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.stopPlayback(didPlayToEnd: true)
        }

        audioDidFailObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let error = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)
                ?? item.error
                ?? self.audioPlayer.currentItem?.error
                ?? self.audioPlayer.error
                ?? NSError(
                    domain: "PolarisGuideKit.AudioGuidePlugin",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Audio playback failed with an unknown error."]
                )
            self.notifyAudioDidFail(error)
        }
    }

    private func stopPlayback(didPlayToEnd: Bool, notifyStop: Bool = true) {
        if let token = audioDidFinishObserver {
            NotificationCenter.default.removeObserver(token)
            audioDidFinishObserver = nil
        }
        if let token = audioDidFailObserver {
            NotificationCenter.default.removeObserver(token)
            audioDidFailObserver = nil
        }

        if notifyStop, currentBuddyView != nil, audioPlayer.currentItem != nil {
            notifyAudioDidStop(didPlayToEnd: didPlayToEnd)
        }
        audioPlayer.pause()
        audioPlayer.replaceCurrentItem(with: nil)
        currentBuddyView = nil
    }

    private func notifyAudioDidStart() {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidStart()
    }

    private func notifyAudioDidStop(didPlayToEnd: Bool) {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidStop(didPlayToEnd: didPlayToEnd)
    }

    private func notifyAudioDidFail(_ error: Error) {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidFail(error)
        // Per API contract: for failure, only emit `guideAudioDidFail(_:)`, no stop callback.
        stopPlayback(didPlayToEnd: false, notifyStop: false)
    }
}
