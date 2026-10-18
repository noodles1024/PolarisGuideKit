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
    private var itemStatusObservation: NSKeyValueObservation?
    private weak var currentBuddyView: GuideBuddyView?
    private var playbackRequestID = UUID()

    public init() {}

    deinit {
        tearDown()
    }

    /// Stops playback and removes observers without notifying the buddy view.
    public func tearDown() {
        playbackRequestID = UUID()
        stopPlayback(didPlayToEnd: false, notifyStop: false)
    }

    public func handle(_ event: GuideEvent, context: GuideStepContext) {
        switch event {
        case .stepDidShow:
            startPlaybackIfNeeded(context: context)
        case .stepWillHide, .guideWillHide:
            playbackRequestID = UUID()
            stopPlayback(didPlayToEnd: false)
        default:
            break
        }
    }

    private func startPlaybackIfNeeded(context: GuideStepContext) {
        let requestID = UUID()
        playbackRequestID = requestID
        stopPlayback(didPlayToEnd: false)
        // A stop callback may synchronously dismiss the guide or start another step.
        guard playbackRequestID == requestID else { return }
        guard let attachment = context.step.attachment(ofType: GuideAudioAttachment.self) else {
            return
        }

        let playerItem = AVPlayerItem(url: attachment.url)
        // Binding the item begins loading its media, so observe readiness first.
        observePlaybackEvents(for: playerItem)
        audioPlayer.replaceCurrentItem(with: playerItem)
        audioPlayer.volume = attachment.volume
        currentBuddyView = context.buddyView
        audioPlayer.play()

        notifyAudioDidStart()
    }

    private func observePlaybackEvents(for item: AVPlayerItem) {
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            self?.enqueuePlaybackEvent(for: item) { plugin, item in
                plugin.failPlayback(for: item, error: item.error)
            }
        }

        audioDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self, weak item] _ in
            guard let item = item else { return }
            self?.enqueuePlaybackEvent(for: item) { plugin, _ in
                plugin.stopPlayback(didPlayToEnd: true)
            }
        }

        audioDidFailObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self, weak item] notification in
            guard let item = item else { return }
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.enqueuePlaybackEvent(for: item) { plugin, item in
                plugin.failPlayback(for: item, error: error)
            }
        }
    }

    private func enqueuePlaybackEvent(
        for item: AVPlayerItem,
        handle: @escaping (AudioGuidePlugin, AVPlayerItem) -> Void
    ) {
        // KVO may arrive off-main or during replaceCurrentItem. An old item's
        // already-queued callbacks must not stop playback for a subsequent step.
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.audioPlayer.currentItem === item else { return }
            handle(self, item)
        }
    }

    private func stopPlayback(didPlayToEnd: Bool, notifyStop: Bool = true) {
        let buddyView = currentBuddyView as? GuideAudioEventReceiving
        let hadPlayerItem = audioPlayer.currentItem != nil
        currentBuddyView = nil
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        if let token = audioDidFinishObserver {
            NotificationCenter.default.removeObserver(token)
            audioDidFinishObserver = nil
        }
        if let token = audioDidFailObserver {
            NotificationCenter.default.removeObserver(token)
            audioDidFailObserver = nil
        }

        audioPlayer.pause()
        audioPlayer.replaceCurrentItem(with: nil)

        // User callbacks may start a new step. Finish all old-item cleanup first.
        if notifyStop && hadPlayerItem {
            buddyView?.guideAudioDidStop(didPlayToEnd: didPlayToEnd)
        }
    }

    private func notifyAudioDidStart() {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidStart()
    }

    private func failPlayback(for item: AVPlayerItem, error: Error?) {
        let buddyView = currentBuddyView as? GuideAudioEventReceiving
        let playbackError = error ?? item.error ?? audioPlayer.error ?? NSError(
            domain: "PolarisGuideKit.AudioGuidePlugin",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Audio playback failed with an unknown error."]
        )
        // Per API contract: for failure, only emit `guideAudioDidFail(_:)`, no stop callback.
        stopPlayback(didPlayToEnd: false, notifyStop: false)
        buddyView?.guideAudioDidFail(playbackError)
    }
}
