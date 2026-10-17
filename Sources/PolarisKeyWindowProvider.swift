import UIKit

/// Resolves an automatic host only when the available scene context is unambiguous.
/// Callers with a focus view should prefer that view's window instead.
internal enum PolarisKeyWindowProvider {
    static func keyWindow() -> UIWindow? {
        let application = UIApplication.shared
        if #available(iOS 13.0, *) {
            let connectedScenes = application.connectedScenes
            if !connectedScenes.isEmpty {
                let candidates = connectedScenes.compactMap { scene -> SceneCandidate? in
                    guard let scene = scene as? UIWindowScene else { return nil }
                    return SceneCandidate(
                        activationState: scene.activationState,
                        role: scene.session.role,
                        windows: scene.windows
                    )
                }
                return keyWindow(in: candidates)
            }
        }

        // Some legacy application configurations have no connected scenes. Keep
        // this compatibility path separate from scene selection and ambiguity.
        return legacyKeyWindow(in: application.windows, applicationState: application.applicationState)
    }

    @available(iOS 13.0, *)
    struct SceneCandidate {
        let activationState: UIScene.ActivationState
        let role: UISceneSession.Role
        let windows: [UIWindow]
    }

    @available(iOS 13.0, *)
    static func keyWindow(in candidates: [SceneCandidate]) -> UIWindow? {
        let activeApplicationScenes = candidates.filter {
            $0.activationState == .foregroundActive && $0.role == .windowApplication
        }
        guard activeApplicationScenes.count == 1 else { return nil }
        return suitableWindow(in: activeApplicationScenes[0].windows)
    }

    static func legacyKeyWindow(in windows: [UIWindow], applicationState: UIApplication.State) -> UIWindow? {
        guard applicationState == .active else { return nil }
        return suitableWindow(in: windows.filter { $0.screen === UIScreen.main })
    }

    private static func suitableWindow(in windows: [UIWindow]) -> UIWindow? {
        let candidates = windows.filter {
            !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal && $0.rootViewController != nil
        }
        if let keyWindow = candidates.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        return candidates.count == 1 ? candidates[0] : nil
    }
}
