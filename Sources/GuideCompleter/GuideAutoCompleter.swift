//
//  GuideAutoCompleter.swift
//  PolarisGuideKit
//
//  Created by noodles on 2025/6/18.
//  Copyright © 2025 noodles. All rights reserved.
//

import Foundation

/// A closure invoked when an auto-completer triggers.
public typealias GuideAutoCompleterHandler = (_ completer: GuideAutoCompleter) -> Void

/// Base class for objects that determine when to auto-complete the guide.
///
/// Subclass `GuideAutoCompleter` to create custom completion conditions, such as:
/// - User taps a specific button
/// - A certain amount of time elapses
/// - An animation completes
///
/// The completer is activated when its guide item is shown and deactivated when
/// the item is hidden or the guide completes.
///
/// Example usage:
/// ```swift
/// class CustomCompleter: GuideAutoCompleter {
///     override func enable() {
///         // Start monitoring your condition
///     }
///
///     override func disable() {
///         // Stop monitoring
///     }
///
///     private func conditionMet() {
///         trigger()
///     }
/// }
/// ```
///
/// - Important: Subclasses must override both `enable()` and `disable()`.
open class GuideAutoCompleter {
    
    /// Called when this completer's condition is satisfied.
    internal var onTrigger: GuideAutoCompleterHandler?
    
    /// Triggers the completion handler.
    ///
    /// Subclasses should call this when their completion condition is met.
    public final func trigger() {
        onTrigger?(self)
    }
    
    /// Activates the completer to begin monitoring its completion condition.
    ///
    /// Subclasses must override this method to start listening for events or conditions.
    /// Do not call `super.enable()` in your override.
    ///
    /// - Important: This method must be overridden. In debug builds, failing to override
    ///              will trigger a fatal error.
    open func enable() {
        #if DEBUG
        fatalError("For `GuideAutoCompleter` subclass, you must override \(#function) method")
        #endif
    }
    
    /// Deactivates the completer to stop monitoring its completion condition.
    ///
    /// Subclasses must override this method to clean up event listeners or timers.
    /// Do not call `super.disable()` in your override.
    ///
    /// - Important: This method must be overridden. In debug builds, failing to override
    ///              will trigger a fatal error.
    open func disable() {
        #if DEBUG
        fatalError("For `GuideAutoCompleter` subclass, you must override \(#function) method")
        #endif
    }
}
