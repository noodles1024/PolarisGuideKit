import XCTest
import UIKit
@testable import PolarisGuideKit

@available(iOS 13.0, *)
final class PolarisKeyWindowProviderTests: XCTestCase {
    private final class TestWindow: UIWindow {
        var reportsKeyWindow = false

        override var isKeyWindow: Bool { reportsKeyWindow }
    }

    private func makeWindow(key: Bool = false) -> TestWindow {
        let window = TestWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = UIViewController()
        window.isHidden = false
        window.reportsKeyWindow = key
        return window
    }

    private func scene(
        _ windows: [UIWindow],
        state: UIScene.ActivationState = .foregroundActive,
        role: UISceneSession.Role = .windowApplication
    ) -> PolarisKeyWindowProvider.SceneCandidate {
        PolarisKeyWindowProvider.SceneCandidate(activationState: state, role: role, windows: windows)
    }

    func testUsesKeyWindowInTheOnlyActiveApplicationScene() {
        let otherWindow = makeWindow()
        let keyWindow = makeWindow(key: true)

        XCTAssertTrue(PolarisKeyWindowProvider.keyWindow(in: [scene([otherWindow, keyWindow])]) === keyWindow)
    }

    func testInactiveBackgroundAndUnattachedScenesAreNotEligible() {
        for state in [UIScene.ActivationState.foregroundInactive, .background, .unattached] {
            let window = makeWindow(key: true)
            XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene([window], state: state)]))
        }
    }

    func testInactiveSceneDoesNotCompeteWithTheActiveScene() {
        let inactiveWindow = makeWindow(key: true)
        let activeWindow = makeWindow(key: true)

        let result = PolarisKeyWindowProvider.keyWindow(in: [
            scene([inactiveWindow], state: .foregroundInactive),
            scene([activeWindow])
        ])

        XCTAssertTrue(result === activeWindow)
    }

    func testMultipleActiveApplicationScenesAreAmbiguous() {
        let firstWindow = makeWindow(key: true)
        let secondWindow = makeWindow(key: true)

        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene([firstWindow]), scene([secondWindow])]))
        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene([firstWindow]), scene([])]))
    }

    func testExternalDisplaySceneIsNotAnAutomaticHost() {
        let externalWindow = makeWindow(key: true)
        let applicationWindow = makeWindow(key: true)
        let externalScene = scene([externalWindow], role: .windowExternalDisplay)

        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [externalScene]))
        XCTAssertTrue(PolarisKeyWindowProvider.keyWindow(in: [externalScene, scene([applicationWindow])]) === applicationWindow)

        if #available(iOS 16.0, *) {
            let noninteractiveScene = scene([externalWindow], role: .windowExternalDisplayNonInteractive)
            XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [noninteractiveScene]))
        }
    }

    func testRejectsHiddenTransparentElevatedAndRootlessKeyWindows() {
        let hidden = makeWindow(key: true)
        hidden.isHidden = true
        let transparent = makeWindow(key: true)
        transparent.alpha = 0
        let elevated = makeWindow(key: true)
        elevated.windowLevel = .alert
        let rootless = makeWindow(key: true)
        rootless.rootViewController = nil
        let valid = makeWindow()

        let rejected = [hidden, transparent, elevated, rootless]
        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene(rejected)]))
        XCTAssertTrue(PolarisKeyWindowProvider.keyWindow(in: [scene(rejected + [valid])]) === valid)
    }

    func testNonKeyFallbackRequiresExactlyOneUsableWindow() {
        let firstWindow = makeWindow()
        let secondWindow = makeWindow()

        XCTAssertTrue(PolarisKeyWindowProvider.keyWindow(in: [scene([firstWindow])]) === firstWindow)
        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene([firstWindow, secondWindow])]))
        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: [scene([])]))
        XCTAssertNil(PolarisKeyWindowProvider.keyWindow(in: []))
    }

    func testLegacySelectionRequiresAnActiveApplicationAndUsableWindow() {
        let window = makeWindow(key: true)

        XCTAssertTrue(PolarisKeyWindowProvider.legacyKeyWindow(in: [window], applicationState: .active) === window)
        XCTAssertNil(PolarisKeyWindowProvider.legacyKeyWindow(in: [window], applicationState: .inactive))
        XCTAssertNil(PolarisKeyWindowProvider.legacyKeyWindow(in: [window], applicationState: .background))
        window.isHidden = true
        XCTAssertNil(PolarisKeyWindowProvider.legacyKeyWindow(in: [window], applicationState: .active))
    }
}
