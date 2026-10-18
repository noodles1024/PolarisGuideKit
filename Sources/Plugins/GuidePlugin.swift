//
//  GuidePlugin.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/8/21.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

/// Lifecycle events dispatched by `GuideController`.
///
/// `stepDidShow` is emitted after the step is configured (mask/buddy/completer),
/// while `guideDidShow` is emitted after the overlay fade-in animation completes
/// (if animated). Plugins that rely on fully visible UI should wait for `guideDidShow`.
/// Events are not dispatched during controller deinitialization; plugins release
/// presentation resources through `GuidePlugin.tearDown()` instead.
public enum GuideEvent {
    case guideWillShow
    case guideDidShow
    case guideWillHide
    case guideDidHide
    case stepWillShow
    case stepDidShow
    case stepWillHide
    case stepDidHide
}

/// Context object passed to plugins for each guide event.
///
/// View references are weak to avoid retaining view hierarchies.
public final class GuideStepContext {
    public weak var hostView: UIView?
    public weak var containerView: UIView?
    public weak var overlayView: UIView?
    public weak var focusView: UIView?
    public weak var buddyView: GuideBuddyView?
    public let step: GuideStep
    public let stepIndex: Int

    public init(
        hostView: UIView?,
        containerView: UIView?,
        overlayView: UIView?,
        focusView: UIView?,
        buddyView: GuideBuddyView?,
        step: GuideStep,
        stepIndex: Int
    ) {
        self.hostView = hostView
        self.containerView = containerView
        self.overlayView = overlayView
        self.focusView = focusView
        self.buddyView = buddyView
        self.step = step
        self.stepIndex = stepIndex
    }
}

/// Plugin interface for extending guide behavior.
public protocol GuidePlugin: AnyObject {
    func handle(_ event: GuideEvent, context: GuideStepContext)

    /// Releases presentation resources when a displayed controller is deinitialized.
    ///
    /// Normal dismissal continues to send lifecycle events through `handle(_:context:)`.
    /// This method is only a fallback for a presentation that was not dismissed before
    /// its controller was released. It is not called for unshown or already hidden guides.
    /// The default implementation does nothing.
    ///
    /// - Important: Make cleanup idempotent. Do not access the deinitializing controller
    ///              or invoke application callbacks. Cancel pending work and release
    ///              resources such as players, timers, and observers directly.
    func tearDown()
}

public extension GuidePlugin {
    func tearDown() {}
}
