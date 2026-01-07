import UIKit

/// Internal helper for resolving the most appropriate key window in multi-scene environments.
internal enum PolarisKeyWindowProvider {
    static func keyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let preferredScenes = scenes.filter {
                $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
            }
            let windows = (preferredScenes.isEmpty ? scenes : preferredScenes).flatMap { $0.windows }
            return windows.first(where: { $0.isKeyWindow }) ?? windows.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}


