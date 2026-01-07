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
    func guideAudioDidStart()
    func guideAudioDidFinish()
}

/// Audio playback plugin for guide steps.
///
/// Note: You may need to set the correct `AVAudioSessionCategory` for your
///       application to ensure audio plays as expected.
public final class AudioGuidePlugin: GuidePlugin {

    private let audioPlayer = AVPlayer()
    private var audioDidFinishObserver: NSObjectProtocol?
    private weak var currentBuddyView: GuideBuddyView?

    public init() {}

    deinit {
        stopPlayback()
    }

    public func handle(_ event: GuideEvent, context: GuideStepContext) {
        switch event {
        case .stepDidShow:
            startPlaybackIfNeeded(context: context)
        case .stepWillHide, .guideWillHide:
            stopPlayback()
        default:
            break
        }
    }

    private func startPlaybackIfNeeded(context: GuideStepContext) {
        stopPlayback()
        guard let attachment = context.step.attachment(ofType: GuideAudioAttachment.self) else {
            return
        }

        let playerItem = AVPlayerItem(url: attachment.url)
        audioPlayer.replaceCurrentItem(with: playerItem)
        audioPlayer.volume = attachment.volume
        currentBuddyView = context.buddyView
        audioPlayer.play()

        notifyAudioDidStart()
        observePlaybackEnd(for: playerItem)
    }

    private func observePlaybackEnd(for item: AVPlayerItem) {
        if let token = audioDidFinishObserver {
            NotificationCenter.default.removeObserver(token)
        }
        audioDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.notifyAudioDidFinish()
        }
    }

    private func stopPlayback() {
        if let token = audioDidFinishObserver {
            NotificationCenter.default.removeObserver(token)
            audioDidFinishObserver = nil
        }
        audioPlayer.pause()
        audioPlayer.replaceCurrentItem(with: nil)
        currentBuddyView = nil
    }

    private func notifyAudioDidStart() {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidStart()
    }

    private func notifyAudioDidFinish() {
        (currentBuddyView as? GuideAudioEventReceiving)?.guideAudioDidFinish()
        // Cleanup the player so a completed item does not linger.
        stopPlayback()
    }
}
