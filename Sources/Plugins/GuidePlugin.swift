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
}
