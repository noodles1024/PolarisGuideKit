//
//  GuideStep.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/3/29.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

/// Marker protocol for step-level attachments used by plugins.
public protocol GuideStepAttachment {}

/// A configuration object describing a single step in a user guide flow.
///
/// `GuideStep` defines what to highlight, how to style it, and what companion
/// content to display during a guide step. Each item represents one frame in a multi-step
/// tutorial or onboarding sequence.
///
/// Use `attachments` to associate plugin-specific data with a step.
///
/// At minimum, either `focusView` or `buddyView` must be set for the step to be valid.
public final class GuideStep {
    
    // MARK: - Properties
    
    /// Optional identifier for this guide item.
    ///
    /// Not used internally, but useful for analytics, debugging, or state restoration.
    public var identifier: String?
    
    /// Provider closure that returns the view to highlight.
    ///
    /// For dynamic scenarios (e.g., UITableView/UICollectionView cells that may be reused
    /// after `reloadData`), use this property directly to provide a closure that always
    /// returns the current, valid view.
    ///
    /// Example:
    /// ```swift
    /// step.focusViewProvider = { [weak self] in
    ///     self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
    /// }
    /// ```
    ///
    /// - Note: For static views, use the convenience `focusView` property instead.
    public var focusViewProvider: (() -> UIView?)?
    
    /// The view to highlight during this guide step.
    ///
    /// This is a convenience property that wraps `focusViewProvider`.
    /// - When getting: Calls the provider to obtain the current view.
    /// - When setting: Creates a weak-capturing closure for the provided view.
    ///
    /// For dynamic scenarios (e.g., cells in a reloading table/collection view),
    /// set `focusViewProvider` directly with a closure that returns the appropriate cell
    /// for the desired IndexPath.
    ///
    /// - Important: At least one of `focusView` or `buddyView` must be non-nil.
    public var focusView: UIView? {
        get { focusViewProvider?() }
        set {
            if let view = newValue {
                focusViewProvider = { [weak view] in view }
            } else {
                focusViewProvider = nil
            }
        }
    }
    
    /// Completer that determines when to auto-complete the guide.
    ///
    ///
    /// - Attention: Triggering the completer will automatically hide the entire guide.
    ///              Configure this only for the last step (or a single-step guide).
    public var completer: GuideAutoCompleter?
    
    /// Whether tapping outside the focus area dismisses the entire guide.
    ///
    /// - Note: Defaults to `false`.
    public var dismissesOnOutsideTap: Bool = false
    
    /// Whether to forward touch events to the focus view.
    ///
    /// When `true`, taps on the focus area are passed through to the underlying view,
    /// allowing users to interact with highlighted UI elements.
    ///
    /// - Important: Only works if `focusView` responds to touch events. If your focus view
    ///              doesn't handle touches (e.g., a `UILabel`), this property has no effect.
    /// - Note: Defaults to `false`.
    public var forwardsTouchEventsToFocusView: Bool = false
    
    /// Visual style applied to the focus area.
    ///
    /// Determines the shape and appearance of the highlight (e.g., rectangle, circle, rounded corners).
    /// - Note: Defaults to `DefaultFocusStyle` (rectangular highlight).
    public var focusStyle: any FocusStyle
    
    /// Companion view displayed alongside the focus area.
    ///
    /// Typically contains instructional text, arrows, or action buttons.
    /// - Important: At least one of `focusView` or `buddyView` must be non-nil.
    public var buddyView: GuideBuddyView?
    
    /// Additional highlight areas beyond the focus view.
    ///
    /// Use this to highlight multiple UI elements simultaneously or create custom shapes.
    public var additionalHighlightPaths: [UIBezierPath] = []

    /// Attachments that extend step behavior via plugins.
    ///
    /// Use attachments to associate plugin-specific data with a step.
    public var attachments: [GuideStepAttachment] = []
    
    // MARK: - Initialization
    
    public init() {
        self.focusStyle = DefaultFocusStyle()
    }
    
    // MARK: - Methods
    
    /// Validates whether this guide item has sufficient configuration to be displayed.
    ///
    /// - Returns: `true` if either `focusView` or `buddyView` is set; `false` otherwise.
    public var isValid: Bool {
        focusView != nil || buddyView != nil
    }
    
    /// Adds a plugin attachment to this step.
    public func addAttachment(_ attachment: GuideStepAttachment) {
        attachments.append(attachment)
    }
    
    /// Returns the first attachment matching the given type.
    public func attachment<T: GuideStepAttachment>(ofType type: T.Type = T.self) -> T? {
        return attachments.first { $0 is T } as? T
    }
    
    /// Returns all attachments matching the given type.
    public func attachments<T: GuideStepAttachment>(ofType type: T.Type = T.self) -> [T] {
        return attachments.compactMap { $0 as? T }
    }
    
    /// Removes all attachments matching the given type.
    public func removeAttachments<T: GuideStepAttachment>(ofType type: T.Type = T.self) {
        attachments.removeAll { $0 is T }
    }
    
    /// Determines if an animated transition should be shown when switching to this item.
    ///
    /// - Returns: `true` if there are extra focus areas or the focus view is in the view hierarchy.
    func canShowTransitionAnimation() -> Bool {
        if !additionalHighlightPaths.isEmpty {
            return true
        }
        if let focusView = focusView, focusView.superview != nil {
            return true
        }
        return false
    }
}
