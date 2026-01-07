//
//  ControlEventCompleter.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/6/18.
//  Copyright © 2025 noodles. All rights reserved.
//

import UIKit

/// A completer that triggers when a UIControl fires a specific event.
///
/// Use this to auto-complete the guide when the user interacts with a highlighted control,
/// such as tapping a button or changing a switch value.
/// - Note: ControlEventCompleter requires `forwardsTouchEventsToFocusView = true`
/// when their control is also the focus view.
///
/// Example usage:
/// ```swift
/// let completer = ControlEventCompleter(
///     control: myButton,
///     event: .touchUpInside
/// )
/// step.completer = completer
/// step.forwardsTouchEventsToFocusView = true  // Required when control is the focusView
/// ```
///
/// - Important: If the `control` is also the step's `focusView`, set
///              `step.forwardsTouchEventsToFocusView = true` so the control can receive
///              touch events through the overlay.
public final class ControlEventCompleter: GuideAutoCompleter {
    
    // MARK: - Properties
    
    private weak var control: UIControl?
    private let event: UIControl.Event
    
    // MARK: - Initialization
    
    /// Creates a completer that monitors a specific control event.
    ///
    /// - Parameters:
    ///   - control: The control to monitor.
    ///   - event: The event to listen for (e.g., `.touchUpInside`).
    public init(control: UIControl, event: UIControl.Event) {
        self.control = control
        self.event = event
        super.init()
    }
    
    // MARK: - Actions
    
    @objc private func handleControlEvent(_ sender: Any) {
        trigger()
    }
    
    // MARK: - Overrides
    
    public override func enable() {
        control?.addTarget(self, action: #selector(handleControlEvent(_:)), for: event)
    }
    
    public override func disable() {
        control?.removeTarget(self, action: #selector(handleControlEvent(_:)), for: event)
    }
}
