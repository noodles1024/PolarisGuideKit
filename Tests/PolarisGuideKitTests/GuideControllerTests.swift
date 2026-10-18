import UIKit
import XCTest
@testable import PolarisGuideKit

@available(iOS 13.0, *)
final class GuideControllerTests: XCTestCase {
    private var scene: UIWindowScene!
    private var originalKeyWindow: UIWindow?
    private var windows: [UIWindow] = []
    private var guides: [GuideController] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first {
            $0.session.role == .windowApplication
        })
        let active = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.scene.activationState == .foregroundActive
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [active], timeout: 5), .completed)
        originalKeyWindow = scene.windows.first { $0.isKeyWindow }
    }

    override func tearDown() {
        guides.forEach { $0.hide() }
        guides.removeAll()
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        originalKeyWindow?.makeKeyAndVisible()
        originalKeyWindow = nil
        scene = nil
        super.tearDown()
    }

    private func makeWindow() -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        windows.append(window)
        return window
    }

    private func makeStep(in host: UIView) -> GuideStep {
        let focus = UIView(frame: CGRect(x: 20, y: 100, width: 80, height: 40))
        host.addSubview(focus)
        let step = GuideStep()
        step.focusView = focus
        return step
    }

    private func guide(host: UIView?, steps: [GuideStep], plugins: [GuidePlugin] = []) -> GuideController {
        let guide = GuideController(hostView: host, steps: steps, plugins: plugins)
        guides.append(guide)
        return guide
    }

    private func container(in host: UIView) -> GuideContainerView? {
        host.subviews.compactMap { $0 as? GuideContainerView }.first
    }

    private func overlay(in host: UIView) throws -> GuideOverlayView {
        try XCTUnwrap(container(in: host)?.subviews.compactMap { $0 as? GuideOverlayView }.first)
    }

    private func blockers(in host: UIView) -> [UIGestureRecognizer] {
        (host.gestureRecognizers ?? []).filter { String(describing: type(of: $0)).contains("BlockAllGestureRecognizer") }
    }

    func testAutomaticHostFollowsFocusWindowEvenWhenAnotherWindowIsKey() throws {
        let first = makeWindow()
        let step = makeStep(in: first.rootViewController!.view)
        let other = makeWindow()
        let recorder = Recorder()
        let guide = guide(host: nil, steps: [step], plugins: [recorder])
        XCTAssertEqual(guide.steps.count, 1)
        XCTAssertTrue(other.isKeyWindow)
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: first))
        XCTAssertNil(container(in: other))
        XCTAssertTrue(recorder.hosts.allSatisfy { $0 === first })
        XCTAssertTrue(try overlay(in: first).shadowOfFocusView?.masterView === step.focusView)
    }

    func testKeyWindowChangeBetweenInitializationAndShowDoesNotCrash() {
        let first = makeWindow()
        let guide = guide(host: nil, steps: [makeStep(in: first.rootViewController!.view)])
        let other = makeWindow()
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: first))
        XCTAssertNil(container(in: other))
    }

    func testHideAfterKeyWindowChangeRemovesOverlayAndBlockerExactlyOnce() {
        let first = makeWindow()
        let recorder = Recorder()
        let guide = guide(host: nil, steps: [makeStep(in: first.rootViewController!.view)], plugins: [recorder])
        var dismissals = 0
        guide.onDismiss = { _, _ in dismissals += 1 }
        XCTAssertTrue(guide.show())
        XCTAssertEqual(blockers(in: first).count, 1)
        let other = makeWindow()
        XCTAssertTrue(guide.isShown())
        XCTAssertTrue(guide.show())
        XCTAssertNil(container(in: other))
        guide.hide()
        guide.hide()
        XCTAssertFalse(guide.isShown())
        XCTAssertNil(container(in: first))
        XCTAssertTrue(blockers(in: first).isEmpty)
        XCTAssertEqual(dismissals, 1)
        XCTAssertEqual(guide.currentStepIndex, -1)
        XCTAssertTrue(recorder.hosts.allSatisfy { $0 === first })
    }

    func testExplicitHostIsRespectedAndWrongHierarchyIsRejectedWithoutCrash() {
        let first = makeWindow()
        let second = makeWindow()
        let step = makeStep(in: first.rootViewController!.view)
        let wrong = guide(host: second, steps: [step])
        XCTAssertEqual(wrong.steps.count, 1)
        XCTAssertFalse(wrong.show())
        XCTAssertNil(container(in: second))
        XCTAssertTrue(blockers(in: second).isEmpty)
        let correct = guide(host: first.rootViewController!.view, steps: [step])
        XCTAssertTrue(correct.show())
        XCTAssertNotNil(container(in: first.rootViewController!.view))
    }

    func testDetachedFocusCanBeAttachedAndRetriedWithoutRecreatingGuide() {
        let window = makeWindow()
        let focus = UIView(frame: CGRect(x: 20, y: 100, width: 80, height: 40))
        let step = GuideStep()
        step.focusView = focus
        let guide = guide(host: nil, steps: [step])
        XCTAssertFalse(guide.show())
        XCTAssertEqual(guide.steps.count, 1)
        window.rootViewController!.view.addSubview(focus)
        XCTAssertTrue(guide.show())
    }

    func testExplicitHostCanShowBeforeItsViewTreeEntersAWindow() throws {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        let step = makeStep(in: host)
        let guide = guide(host: host, steps: [step])
        XCTAssertNil(host.window)
        XCTAssertNil(step.focusView?.window)
        XCTAssertTrue(guide.show())
        XCTAssertTrue(guide.isShown())
        let overlay = try overlay(in: host)
        XCTAssertTrue(overlay.shadowOfFocusView?.masterView === step.focusView)
        let window = makeWindow()
        window.rootViewController!.view.addSubview(host)
        window.layoutIfNeeded()
        guide.refreshOverlay()
        let shadow = try XCTUnwrap(overlay.shadowOfFocusView)
        XCTAssertEqual(shadow.convert(shadow.bounds, to: host), step.focusView!.frame)
        guide.hide()
        XCTAssertNil(container(in: host))
        XCTAssertTrue(blockers(in: host).isEmpty)
    }

    func testGuideCanBeCreatedInViewDidLoadUsingNavigationViewAsHost() throws {
        let page = ViewDidLoadPage()
        let navigation = UINavigationController(rootViewController: page)
        navigation.loadViewIfNeeded()
        page.loadViewIfNeeded()
        let guide = try XCTUnwrap(page.guide)
        guides.append(guide)
        XCTAssertNil(page.focus.window)
        XCTAssertTrue(guide.hostView === navigation.view)
        XCTAssertEqual(guide.steps.count, 1)
        let window = makeWindow()
        window.rootViewController = navigation
        window.layoutIfNeeded()
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: navigation.view))
        XCTAssertTrue(try overlay(in: navigation.view).shadowOfFocusView?.masterView === page.focus)
    }

    func testStepCanBeAddedBeforeItsFocusIsAttachedToTheHost() {
        let host = UIView()
        let guide = guide(host: host, steps: [makeStep(in: host)])
        XCTAssertTrue(guide.show())
        let laterFocus = UIView()
        let laterStep = GuideStep()
        laterStep.focusView = laterFocus
        XCTAssertTrue(guide.addStep(laterStep))
        XCTAssertFalse(guide.showNextStep())
        XCTAssertEqual(guide.currentStepIndex, 0)
        host.addSubview(laterFocus)
        XCTAssertTrue(guide.showNextStep())
        XCTAssertEqual(guide.currentStepIndex, 1)
    }

    func testUnresolvedProviderIsRetainedUntilPresentation() {
        let window = makeWindow()
        var focus: UIView?
        let step = GuideStep()
        step.focusViewProvider = { focus }
        let guide = guide(host: nil, steps: [step])
        XCTAssertEqual(guide.steps.count, 1)
        XCTAssertFalse(guide.show())
        focus = UIView(frame: CGRect(x: 20, y: 100, width: 80, height: 40))
        window.addSubview(focus!)
        XCTAssertTrue(guide.show())
    }

    func testUnresolvedProviderWithBuddyDoesNotGuessAnotherWindow() {
        let first = makeWindow()
        var focus: UIView?
        let step = GuideStep()
        step.focusViewProvider = { focus }
        step.buddyView = GuideBuddyView()
        let guide = guide(host: nil, steps: [step])
        let second = makeWindow()
        XCTAssertFalse(guide.show())
        XCTAssertNil(container(in: second))
        focus = makeStep(in: first).focusView
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: first))
    }

    func testPluginDismissalStopsRemainingShowEvents() {
        let window = makeWindow()
        let dismissingPlugin = CallbackPlugin()
        let recorder = Recorder()
        let guide = guide(host: window, steps: [makeStep(in: window)], plugins: [dismissingPlugin, recorder])
        dismissingPlugin.onEvent = { [weak guide] event in
            if case .stepDidShow = event { guide?.hide() }
        }
        XCTAssertFalse(guide.show())
        XCTAssertFalse(guide.isShown())
        XCTAssertEqual(recorder.stepDidShowCount, 0)
        XCTAssertEqual(recorder.didShowCount, 0)
        XCTAssertTrue(blockers(in: window).isEmpty)
    }

    func testHostCallbacksCanDismissWithoutLeavingBlockingGesture() {
        let window = makeWindow()
        for dismissOnAttachment in [false, true] {
            let host = CallbackHost(frame: window.bounds)
            window.addSubview(host)
            let guide = guide(host: host, steps: [makeStep(in: host)])
            let dismiss = { [weak guide] in guide?.hide() }
            if dismissOnAttachment {
                host.onGuideAdded = { dismiss() }
            } else {
                host.onLayout = { dismiss() }
            }
            XCTAssertFalse(guide.show())
            XCTAssertFalse(guide.isShown())
            XCTAssertNil(container(in: host))
            XCTAssertTrue(blockers(in: host).isEmpty)
            host.removeFromSuperview()
        }
    }

    func testGestureWhitelistCanChangeBetweenSteps() throws {
        let window = makeWindow()
        let externalGesture = UIPanGestureRecognizer()
        window.addGestureRecognizer(externalGesture)
        defer { window.removeGestureRecognizer(externalGesture) }
        let first = makeStep(in: window)
        let second = makeStep(in: window)
        first.gestureRecognizerWhitelist = [externalGesture]
        let guide = guide(host: window, steps: [first, second])
        XCTAssertTrue(guide.show())
        let blocker = try XCTUnwrap(blockers(in: window).first)
        XCTAssertFalse(guide.gestureRecognizer(blocker, shouldBeRequiredToFailBy: externalGesture))
        XCTAssertTrue(guide.gestureRecognizer(blocker, shouldRecognizeSimultaneouslyWith: externalGesture))
        XCTAssertTrue(guide.showNextStep())
        XCTAssertTrue(guide.gestureRecognizer(blocker, shouldBeRequiredToFailBy: externalGesture))
        XCTAssertFalse(guide.gestureRecognizer(blocker, shouldRecognizeSimultaneouslyWith: externalGesture))
    }

    func testExplicitFailureGatesFollowEachStepsWhitelistIndependently() throws {
        let window = makeWindow()
        let host = window.rootViewController!.view!
        let navigationGesture = FailureRequirementSpy()
        let firstPan = FailureRequirementSpy()
        let secondPan = FailureRequirementSpy()
        [navigationGesture, firstPan, secondPan].forEach { window.addGestureRecognizer($0) }
        let steps = (0..<4).map { _ in makeStep(in: host) }
        steps[1].gestureRecognizerWhitelist = [firstPan]
        steps[2].gestureRecognizerWhitelist = [secondPan]
        let guide = guide(host: host, steps: steps)
        XCTAssertTrue(guide.show())
        let navigationGate = try XCTUnwrap(navigationGesture.gates.first)
        let firstGate = try XCTUnwrap(firstPan.gates.first)
        let secondGate = try XCTUnwrap(secondPan.gates.first)
        XCTAssertFalse(firstGate === secondGate)
        XCTAssertFalse(firstGate === navigationGate)
        XCTAssertFalse(firstGate.canPrevent(secondPan))
        XCTAssertFalse(firstGate.canBePrevented(by: secondPan))
        XCTAssertFalse(firstGate.canPrevent(navigationGate))
        XCTAssertFalse(firstGate.canBePrevented(by: navigationGate))

        for index in steps.indices {
            if index > 0 { XCTAssertTrue(guide.showNextStep()) }
            XCTAssertEqual(firstGate.shouldBlock?(firstPan), index != 1)
            XCTAssertEqual(secondGate.shouldBlock?(secondPan), index != 2)
            XCTAssertEqual(navigationGate.shouldBlock?(navigationGesture), true)
            for gesture in [navigationGesture, firstPan, secondPan] {
                XCTAssertEqual(gesture.requirementCount, 1, "Step changes must reuse the explicit dependency")
            }
        }
        XCTAssertTrue(navigationGate.view === host)
        XCTAssertTrue(navigationGate.guardedGesture === navigationGesture)
    }

    func testExplicitFailureGateReadsWhitelistChangesWithinTheSameStep() throws {
        let window = makeWindow()
        let pan = FailureRequirementSpy()
        let navigationGesture = FailureRequirementSpy()
        window.addGestureRecognizer(pan)
        window.addGestureRecognizer(navigationGesture)
        let step = makeStep(in: window)
        let guide = guide(host: window, steps: [step])
        XCTAssertTrue(guide.show())
        let gate = try XCTUnwrap(pan.gates.first)
        let navigationGate = try XCTUnwrap(navigationGesture.gates.first)
        XCTAssertEqual(gate.shouldBlock?(pan), true)
        step.gestureRecognizerWhitelist = [pan]
        XCTAssertEqual(gate.shouldBlock?(pan), false)
        XCTAssertEqual(navigationGate.shouldBlock?(navigationGesture), true)
        step.gestureRecognizerWhitelist = []
        XCTAssertEqual(gate.shouldBlock?(pan), true)
        guide.refreshOverlay()
        XCTAssertEqual(pan.requirementCount, 1)
        XCTAssertEqual(navigationGesture.requirementCount, 1)
    }

    func testWindowHostGuardsForwardedFocusNavigationAncestors() throws {
        let window = makeWindow()
        let page = UIViewController()
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.setViewControllers([navigation.viewControllers[0], page], animated: false)
        window.rootViewController = navigation
        window.layoutIfNeeded()
        let navigationGesture = FailureRequirementSpy()
        navigation.view.addGestureRecognizer(navigationGesture)
        let focusGesture = FailureRequirementSpy()
        let step = makeStep(in: page.view)
        step.forwardsTouchEventsToFocusView = true
        step.focusView!.addGestureRecognizer(focusGesture)
        let guide = guide(host: nil, steps: [step])
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: window))
        let navigationGate = try XCTUnwrap(navigationGesture.gates.first)
        let focusGate = try XCTUnwrap(focusGesture.gates.first)
        XCTAssertTrue(navigationGate.view === window)
        XCTAssertEqual(navigationGate.shouldBlock?(navigationGesture), true)
        XCTAssertEqual(focusGate.shouldBlock?(focusGesture), false)
        let interactivePop = try XCTUnwrap(navigation.interactivePopGestureRecognizer)
        let popGate = try XCTUnwrap(window.gestureRecognizers?.compactMap { $0 as? GuideGestureGate }.first {
            $0.guardedGesture === interactivePop
        })
        XCTAssertEqual(popGate.shouldBlock?(interactivePop), true)
    }

    func testLayoutInstallsFailureGateWhenOffscreenHostAcquiresAnAncestor() throws {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        let guide = guide(host: host, steps: [makeStep(in: host)])
        XCTAssertTrue(guide.show())
        let window = makeWindow()
        let navigationGesture = FailureRequirementSpy()
        window.rootViewController!.view.addGestureRecognizer(navigationGesture)
        window.rootViewController!.view.addSubview(host)
        let container = try XCTUnwrap(container(in: host))
        container.setNeedsLayout()
        container.layoutIfNeeded()
        let gate = try XCTUnwrap(navigationGesture.gates.first)
        XCTAssertEqual(gate.shouldBlock?(navigationGesture), true)
        XCTAssertEqual(navigationGesture.requirementCount, 1)
    }

    func testRefreshingDynamicFocusEnablesOnlyRelevantAncestorGates() throws {
        let window = makeWindow()
        let left = UIView(frame: window.bounds)
        let right = UIView(frame: window.bounds)
        window.addSubview(left)
        window.addSubview(right)
        let leftGesture = FailureRequirementSpy()
        let rightGesture = FailureRequirementSpy()
        left.addGestureRecognizer(leftGesture)
        right.addGestureRecognizer(rightGesture)
        let leftFocus = makeStep(in: left).focusView!
        let rightFocus = makeStep(in: right).focusView!
        var selected = leftFocus
        let step = GuideStep()
        step.focusViewProvider = { selected }
        step.forwardsTouchEventsToFocusView = true
        let guide = guide(host: window, steps: [step])
        XCTAssertTrue(guide.show())
        let leftGate = try XCTUnwrap(leftGesture.gates.first)
        XCTAssertTrue(leftGate.isEnabled)
        XCTAssertTrue(rightGesture.gates.isEmpty)
        selected = rightFocus
        guide.refreshOverlay()
        let rightGate = try XCTUnwrap(rightGesture.gates.first)
        XCTAssertFalse(leftGate.isEnabled)
        XCTAssertTrue(rightGate.isEnabled)
        selected = leftFocus
        guide.refreshOverlay()
        XCTAssertTrue(leftGate.isEnabled)
        XCTAssertFalse(rightGate.isEnabled)
        XCTAssertEqual(leftGesture.requirementCount, 1)
        XCTAssertEqual(rightGesture.requirementCount, 1)
    }

    func testHidingDisablesRemovesAndReleasesFailureGatesWithoutChangingExternalGestures() throws {
        let host = UIView()
        let gestureDelegate = GestureDelegate()
        for originallyEnabled in [true, false] {
            let gesture = FailureRequirementSpy()
            gesture.delegate = gestureDelegate
            gesture.isEnabled = originallyEnabled
            host.addGestureRecognizer(gesture)
            let guide = guide(host: host, steps: [makeStep(in: host)])
            weak var releasedGate: GuideGestureGate?
            try autoreleasepool {
                XCTAssertTrue(guide.show())
                let gate = try XCTUnwrap(gesture.gates.first)
                releasedGate = gate
                guide.hide()
                XCTAssertFalse(gate.isEnabled)
                XCTAssertNil(gate.view)
                XCTAssertNil(gate.shouldBlock)
                XCTAssertEqual(gesture.isEnabled, originallyEnabled)
                XCTAssertTrue(gesture.delegate === gestureDelegate)
                XCTAssertTrue(gesture.view === host)
            }
            XCTAssertNil(releasedGate, "The external recognizer must not retain a stale failure gate")
            XCTAssertTrue(gesture.gates.isEmpty)
            host.removeGestureRecognizer(gesture)
        }
    }

    func testReleasingShownGuideReleasesFailureGatesWithoutChangingExternalGestures() throws {
        let host = UIView()
        let gesture = FailureRequirementSpy()
        let gestureDelegate = GestureDelegate()
        gesture.delegate = gestureDelegate
        host.addGestureRecognizer(gesture)
        weak var releasedGuide: GuideController?
        weak var releasedGate: GuideGestureGate?
        try autoreleasepool {
            var shown: GuideController? = GuideController(hostView: host, steps: [makeStep(in: host)])
            releasedGuide = shown
            XCTAssertTrue(shown!.show())
            let gate = try XCTUnwrap(gesture.gates.first)
            releasedGate = gate
            shown = nil
            XCTAssertNil(releasedGuide)
            XCTAssertFalse(gate.isEnabled)
            XCTAssertNil(gate.view)
            XCTAssertNil(gate.shouldBlock)
        }
        XCTAssertNil(releasedGate)
        XCTAssertTrue(gesture.isEnabled)
        XCTAssertTrue(gesture.delegate === gestureDelegate)
        XCTAssertTrue(gesture.view === host)
    }

    func testRepeatedPresentationDoesNotAccumulateFailureGates() throws {
        let host = UIView()
        let gesture = FailureRequirementSpy()
        host.addGestureRecognizer(gesture)
        let guide = guide(host: host, steps: [makeStep(in: host)])
        for presentation in 1...3 {
            XCTAssertTrue(guide.show())
            XCTAssertTrue(guide.show())
            guide.refreshOverlay()
            XCTAssertEqual(gesture.requirementCount, presentation)
            XCTAssertEqual(gesture.gates.count, 1)
            XCTAssertEqual(host.gestureRecognizers?.compactMap { $0 as? GuideGestureGate }.count, 1)
            guide.hide()
            XCTAssertTrue(gesture.gates.isEmpty)
            XCTAssertTrue(host.gestureRecognizers?.compactMap { $0 as? GuideGestureGate }.isEmpty == true)
        }
    }

    func testConcurrentGuidesDoNotCreateDependenciesOnEachOthersBlockingGestures() throws {
        let host = UIView()
        let gesture = FailureRequirementSpy()
        host.addGestureRecognizer(gesture)
        let first = guide(host: host, steps: [makeStep(in: host)])
        let second = guide(host: host, steps: [makeStep(in: host)])
        XCTAssertTrue(first.show())
        XCTAssertTrue(second.show())
        first.refreshOverlay()
        second.refreshOverlay()
        XCTAssertEqual(gesture.requirementCount, 2)
        let gates = gesture.gates
        XCTAssertEqual(gates.count, 2)
        XCTAssertTrue(gates.allSatisfy { $0.guardedGesture === gesture })
        XCTAssertEqual(host.gestureRecognizers?.compactMap { $0 as? GuideGestureGate }.count, 2)
        let blockingGestures = blockers(in: host)
        XCTAssertEqual(blockingGestures.count, 2)
        let firstBlocker = try XCTUnwrap(blockingGestures.first { $0.delegate === first })
        for other in blockingGestures.filter({ $0 !== firstBlocker }) + gates {
            XCTAssertFalse(first.gestureRecognizer(firstBlocker, shouldRequireFailureOf: other))
            XCTAssertFalse(first.gestureRecognizer(firstBlocker, shouldBeRequiredToFailBy: other))
            XCTAssertTrue(first.gestureRecognizer(firstBlocker, shouldRecognizeSimultaneouslyWith: other))
        }
        first.hide()
        XCTAssertEqual(gates.filter { $0.isEnabled }.count, 1)
        XCTAssertEqual(gates.filter { $0.shouldBlock?(gesture) == true }.count, 1)
        XCTAssertTrue(second.isShown())
    }

    func testDeallocatedExplicitHostDoesNotFallBackToKeyWindow() {
        let window = makeWindow()
        var explicit: UIView? = UIView()
        let step = GuideStep()
        step.buddyView = GuideBuddyView()
        let guide = guide(host: explicit, steps: [step])
        explicit = nil
        XCTAssertNil(guide.hostView)
        XCTAssertFalse(guide.show())
        XCTAssertNil(container(in: window))
    }

    func testExplicitHiddenHostCanBePreparedBeforeBecomingVisible() {
        let window = makeWindow()
        let guide = guide(host: window, steps: [makeStep(in: window)])
        window.isHidden = true
        XCTAssertTrue(guide.show())
        XCTAssertNotNil(container(in: window))
        window.makeKeyAndVisible()
        XCTAssertTrue(guide.show())
    }

    func testStepCanBeSelectedBeforePresentationWithoutCreatingConstraints() throws {
        let window = makeWindow()
        let first = makeStep(in: window)
        let second = makeStep(in: window)
        let recorder = Recorder()
        let guide = guide(host: window, steps: [first, second], plugins: [recorder])
        XCTAssertFalse(guide.showStep(at: 2))
        XCTAssertTrue(guide.showStep(at: 0))
        XCTAssertTrue(guide.showNextStep())
        XCTAssertEqual(guide.currentStepIndex, 1)
        XCTAssertNil(container(in: window))
        XCTAssertTrue(recorder.hosts.isEmpty)
        XCTAssertTrue(guide.show())
        XCTAssertEqual(guide.currentStepIndex, 1)
        XCTAssertTrue(try overlay(in: window).shadowOfFocusView?.masterView === second.focusView)
    }

    func testAutomaticHostUsesPreselectedStepsWindow() {
        let first = makeWindow()
        let second = makeWindow()
        let guide = guide(host: nil, steps: [makeStep(in: first), makeStep(in: second)])
        XCTAssertTrue(guide.showStep(at: 1))
        XCTAssertTrue(guide.show())
        XCTAssertNil(container(in: first))
        XCTAssertNotNil(container(in: second))
    }

    func testReleasingAPreselectedGuideSendsNoPresentationEvents() {
        let host = UIView()
        let plugin = CallbackPlugin()
        var events = 0
        plugin.onEvent = { _ in events += 1 }
        weak var released: GuideController?
        autoreleasepool {
            let guide = GuideController(hostView: host, steps: [makeStep(in: host)], plugins: [plugin])
            released = guide
            XCTAssertTrue(guide.showStep(at: 0))
        }
        XCTAssertNil(released)
        XCTAssertEqual(events, 0)
    }

    func testReleasingUnshownAndShownGuidesCleansUpWithoutLazyInitialization() {
        let host = UIView()
        for shouldShow in [false, true] {
            weak var released: GuideController?
            autoreleasepool {
                let guide = GuideController(hostView: host, steps: [makeStep(in: host)])
                released = guide
                if shouldShow { XCTAssertTrue(guide.show()) }
            }
            XCTAssertNil(released)
            XCTAssertNil(container(in: host))
            XCTAssertTrue(blockers(in: host).isEmpty)
        }
    }

    func testReleasingShownGuideUsesResourceCleanupWithoutCallingBackIntoController() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let step = makeStep(in: host)
        let focus = step.focusView
        let buddy = GuideBuddyView()
        let completer = CleanupCompleter()
        let plugin = CleanupPlugin()
        step.buddyView = buddy
        step.completer = completer
        weak var released: GuideController?

        autoreleasepool {
            let guide = GuideController(hostView: host, steps: [step], plugins: [plugin])
            released = guide
            // These unowned accesses would trap if deinit dispatched lifecycle events
            // or evaluated the focus provider to construct a plugin context.
            plugin.onEvent = { [unowned guide] _ in _ = guide.currentStepIndex }
            guide.onDismiss = { _, _ in XCTFail("Deinit must not invoke onDismiss") }
            XCTAssertTrue(guide.show())
            XCTAssertNotNil(buddy.contentReferenceLayoutGuide)
            step.focusViewProvider = { [unowned guide, weak focus] in
                _ = guide.currentStepIndex
                return focus
            }
        }

        XCTAssertNil(released)
        XCTAssertEqual(plugin.events, ["guideWillShow", "stepWillShow", "stepDidShow", "guideDidShow"])
        XCTAssertEqual(plugin.tearDownCount, 1)
        XCTAssertFalse(plugin.hasResources)
        XCTAssertEqual(completer.disableCount, 1)
        XCTAssertNil(completer.onTrigger)
        XCTAssertNil(buddy.onAction)
        XCTAssertNil(buddy.contentReferenceLayoutGuide)
        XCTAssertNil(buddy.superview)
        XCTAssertNil(container(in: host))
        XCTAssertTrue(blockers(in: host).isEmpty)
    }

    func testReleasingUnshownOrPreselectedGuideDoesNotTearDownPlugins() {
        let host = UIView()
        for preselect in [false, true] {
            let plugin = CleanupPlugin()
            weak var released: GuideController?
            autoreleasepool {
                let guide = GuideController(hostView: host, steps: [makeStep(in: host)], plugins: [plugin])
                released = guide
                if preselect { XCTAssertTrue(guide.showStep(at: 0)) }
            }
            XCTAssertNil(released)
            XCTAssertTrue(plugin.events.isEmpty)
            XCTAssertEqual(plugin.tearDownCount, 0)
        }
    }

    func testExplicitHideKeepsLifecycleEventsWithoutRepeatingCleanupAtDeinit() {
        let host = UIView()
        let plugin = CleanupPlugin()
        var dismissCount = 0
        weak var released: GuideController?
        autoreleasepool {
            let guide = GuideController(hostView: host, steps: [makeStep(in: host)], plugins: [plugin])
            released = guide
            guide.onDismiss = { _, _ in dismissCount += 1 }
            XCTAssertTrue(guide.show())
            plugin.events.removeAll()
            guide.hide()
            guide.hide()
            XCTAssertEqual(plugin.events, ["stepWillHide", "guideWillHide", "stepDidHide", "guideDidHide"])
        }
        XCTAssertNil(released)
        XCTAssertEqual(dismissCount, 1)
        XCTAssertEqual(plugin.tearDownCount, 0)
        XCTAssertFalse(plugin.hasResources)
    }

    func testReleasingGuideStillTearsDownPluginsAfterHostHasDeallocated() {
        let plugin = CleanupPlugin()
        var guide: GuideController?
        weak var releasedHost: UIView?
        autoreleasepool {
            let host = UIView()
            releasedHost = host
            guide = GuideController(hostView: host, steps: [makeStep(in: host)], plugins: [plugin])
            XCTAssertTrue(guide!.show())
        }
        XCTAssertNil(releasedHost)
        XCTAssertFalse(guide!.isShown())
        guide = nil
        XCTAssertEqual(plugin.tearDownCount, 1)
        XCTAssertFalse(plugin.hasResources)
    }

    func testShowIsIdempotentInsideStepCallbacks() {
        let host = UIView()
        let plugin = CallbackPlugin()
        let guide = guide(host: host, steps: [makeStep(in: host)], plugins: [plugin])
        var callbackCount = 0
        plugin.onEvent = { [weak guide] event in
            switch event {
            case .stepWillShow, .stepDidShow:
                callbackCount += 1
                XCTAssertTrue(guide?.show() == true)
            default: break
            }
        }
        XCTAssertTrue(guide.show())
        XCTAssertEqual(callbackCount, 2)
    }

    func testStepDidShowCallbackCanAdvanceToNextStep() throws {
        let host = UIView()
        let first = makeStep(in: host)
        let second = makeStep(in: host)
        let plugin = CallbackPlugin()
        let recorder = Recorder()
        let guide = guide(host: host, steps: [first, second], plugins: [plugin, recorder])
        plugin.onEvent = { [weak guide] event in
            if case .stepDidShow = event, guide?.currentStepIndex == 0 {
                XCTAssertTrue(guide?.showNextStep() == true)
            }
        }
        XCTAssertTrue(guide.show())
        XCTAssertEqual(guide.currentStepIndex, 1)
        XCTAssertEqual(recorder.stepDidShowCount, 1)
        XCTAssertTrue(try overlay(in: host).shadowOfFocusView?.masterView === second.focusView)
    }

    func testWillHideStillReportsAttachedUntilContainerIsRemoved() {
        let host = UIView()
        let plugin = CallbackPlugin()
        let guide = guide(host: host, steps: [makeStep(in: host)], plugins: [plugin])
        var callbackCount = 0
        plugin.onEvent = { [weak guide] event in
            switch event {
            case .stepWillHide, .guideWillHide:
                callbackCount += 1
                XCTAssertTrue(guide?.isShown() == true)
            case .stepDidHide, .guideDidHide:
                callbackCount += 1
                XCTAssertFalse(guide?.isShown() == true)
            default: break
            }
        }
        XCTAssertTrue(guide.show())
        guide.hide()
        XCTAssertEqual(callbackCount, 4)
    }

    func testInvalidAddedStepCannotCreateCrossHierarchyConstraints() {
        let first = makeWindow()
        let second = makeWindow()
        let guide = guide(host: first, steps: [])
        XCTAssertTrue(guide.addStep(makeStep(in: second)))
        XCTAssertFalse(guide.show())
        XCTAssertNil(container(in: first))
    }

    func testInvalidNextStepLeavesCurrentStepShowingWithoutCompletion() {
        let first = makeWindow()
        let second = makeWindow()
        let valid = makeStep(in: first)
        let buddy = GuideBuddyView()
        valid.buddyView = buddy
        let guide = guide(host: first, steps: [valid, makeStep(in: second)])
        var dismissed = false
        guide.onDismiss = { _, _ in dismissed = true }
        XCTAssertTrue(guide.show())
        buddy.requestNext()
        XCTAssertEqual(guide.currentStepIndex, 0)
        XCTAssertTrue(guide.isShown())
        XCTAssertFalse(dismissed)
        XCTAssertTrue(guide.addStep(makeStep(in: second)))
    }

    func testHideThenShowRebuildsFocusTrackingAndBuddyLayout() throws {
        let window = makeWindow()
        let step = makeStep(in: window)
        let buddy = TrackingBuddy()
        step.buddyView = buddy
        let guide = guide(host: window, steps: [step])
        XCTAssertTrue(guide.show())
        let oldShadow = try XCTUnwrap(overlay(in: window).shadowOfFocusView)
        guide.hide()
        step.focusView!.frame.origin.y = 250
        XCTAssertTrue(guide.show())
        window.layoutIfNeeded()
        let newShadow = try XCTUnwrap(overlay(in: window).shadowOfFocusView)
        XCTAssertFalse(newShadow === oldShadow)
        XCTAssertEqual(newShadow.convert(newShadow.bounds, to: window), step.focusView!.frame)
        XCTAssertTrue(buddy.contentReferenceLayoutGuide === newShadow.frameLayoutGuide)
        XCTAssertEqual(buddy.updateCount, 2)
    }

    func testDynamicFocusRebindsBuddyAndNeverMigratesToAnotherWindow() throws {
        let first = makeWindow()
        let second = makeWindow()
        let a = makeStep(in: first).focusView!
        let b = makeStep(in: first).focusView!
        b.frame.origin.y = 250
        let foreign = makeStep(in: second).focusView!
        var selected = a
        let step = GuideStep()
        step.focusViewProvider = { selected }
        step.forwardsTouchEventsToFocusView = true
        let buddy = TrackingBuddy()
        step.buddyView = buddy
        let guide = guide(host: nil, steps: [step])
        XCTAssertTrue(guide.show())
        let overlay = try overlay(in: first)
        selected = b
        guide.refreshOverlay()
        XCTAssertTrue(overlay.shadowOfFocusView?.masterView === b)
        XCTAssertTrue(buddy.contentReferenceLayoutGuide === overlay.shadowOfFocusView?.frameLayoutGuide)
        XCTAssertEqual(buddy.updateCount, 2)
        selected = foreign
        guide.refreshOverlay()
        XCTAssertNil(overlay.shadowOfFocusView)
        XCTAssertNil(overlay.validatedFocusView)
        XCTAssertNil(buddy.contentReferenceLayoutGuide)
        XCTAssertNil(container(in: second))
        XCTAssertTrue(guide.isShown())
        selected = a
        guide.refreshOverlay()
        XCTAssertTrue(overlay.shadowOfFocusView?.masterView === a)
        XCTAssertTrue(buddy.contentReferenceLayoutGuide === overlay.shadowOfFocusView?.frameLayoutGuide)
    }

    func testDisconnectCleansUpOnlyTheBoundScene() {
        let window = makeWindow()
        let guide = guide(host: window, steps: [makeStep(in: window)])
        XCTAssertTrue(guide.show())
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: NSObject())
        XCTAssertTrue(guide.isShown())
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: scene)
        XCTAssertFalse(guide.isShown())
        XCTAssertNil(container(in: window))
        XCTAssertTrue(blockers(in: window).isEmpty)
    }

    func testDisconnectIsHandledAfterAnOffscreenHostEntersAWindow() {
        let host = UIView()
        let guide = guide(host: host, steps: [makeStep(in: host)])
        XCTAssertTrue(guide.show())
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: scene)
        XCTAssertTrue(guide.isShown())
        let window = makeWindow()
        window.addSubview(host)
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: scene)
        XCTAssertFalse(guide.isShown())
        XCTAssertNil(container(in: host))
        XCTAssertTrue(blockers(in: host).isEmpty)
    }

    func testSynchronousCompleterDoesNotReattachBuddyAfterDismissal() {
        let window = makeWindow()
        let step = makeStep(in: window)
        let buddy = GuideBuddyView()
        step.buddyView = buddy
        step.completer = ImmediateCompleter()
        let guide = guide(host: window, steps: [step])
        XCTAssertFalse(guide.show())
        XCTAssertNil(buddy.superview)
        XCTAssertNil(container(in: window))
        XCTAssertTrue(blockers(in: window).isEmpty)
    }

    func testInterruptedShowAnimationDoesNotEmitDidShowForNewPresentation() {
        let window = makeWindow()
        let recorder = Recorder()
        let guide = guide(host: window, steps: [makeStep(in: window)], plugins: [recorder])
        guide.animationDuration = 0.05
        XCTAssertTrue(guide.show(animated: true))
        guide.hide()
        XCTAssertTrue(guide.show())
        let completed = expectation(description: "Old fade-in completion has run")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { completed.fulfill() }
        wait(for: [completed], timeout: 2)
        XCTAssertEqual(recorder.didShowCount, 1)
        XCTAssertTrue(guide.isShown())
    }
}

private final class ViewDidLoadPage: UIViewController {
    let focus = UIButton(frame: CGRect(x: 20, y: 100, width: 80, height: 40))
    var guide: GuideController?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(focus)
        let step = GuideStep()
        step.focusView = focus
        guide = GuideController(hostView: navigationController!.view, steps: [step])
    }
}

private final class TrackingBuddy: GuideBuddyView {
    var updateCount = 0
    override func updateLayout(referenceLayoutGuide layoutGuide: UILayoutGuide, focusView: UIView) {
        super.updateLayout(referenceLayoutGuide: layoutGuide, focusView: focusView)
        updateCount += 1
    }
}

private final class Recorder: GuidePlugin {
    var hosts: [UIView] = []
    var didShowCount = 0
    var stepDidShowCount = 0
    func handle(_ event: GuideEvent, context: GuideStepContext) {
        if let host = context.hostView { hosts.append(host) }
        if case .guideDidShow = event { didShowCount += 1 }
        if case .stepDidShow = event { stepDidShowCount += 1 }
    }
}

private final class ImmediateCompleter: GuideAutoCompleter {
    override func enable() { trigger() }
    override func disable() {}
}

private final class CallbackPlugin: GuidePlugin {
    var onEvent: ((GuideEvent) -> Void)?
    func handle(_ event: GuideEvent, context: GuideStepContext) { onEvent?(event) }
}

private final class CleanupPlugin: GuidePlugin {
    var events: [String] = []
    var tearDownCount = 0
    var hasResources = false
    var onEvent: ((GuideEvent) -> Void)?

    func handle(_ event: GuideEvent, context: GuideStepContext) {
        events.append(String(describing: event))
        if case .stepDidShow = event { hasResources = true }
        if case .guideDidHide = event { hasResources = false }
        onEvent?(event)
    }

    func tearDown() {
        tearDownCount += 1
        hasResources = false
    }
}

private final class CleanupCompleter: GuideAutoCompleter {
    var disableCount = 0
    override func enable() {}
    override func disable() {
        XCTAssertNil(onTrigger)
        disableCount += 1
    }
}

private final class CallbackHost: UIView {
    var onLayout: (() -> Void)?
    var onGuideAdded: (() -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        let callback = onLayout
        onLayout = nil
        callback?()
    }
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview is GuideContainerView { onGuideAdded?() }
    }
}

private final class WeakFailureRequirement {
    weak var gesture: UIGestureRecognizer?
    init(_ gesture: UIGestureRecognizer) { self.gesture = gesture }
}

private final class FailureRequirementSpy: UIGestureRecognizer {
    private var requirements: [WeakFailureRequirement] = []
    var requirementCount: Int { requirements.count }
    var gates: [GuideGestureGate] { requirements.compactMap { $0.gesture as? GuideGestureGate } }

    override func require(toFail otherGestureRecognizer: UIGestureRecognizer) {
        requirements.append(WeakFailureRequirement(otherGestureRecognizer))
        super.require(toFail: otherGestureRecognizer)
    }
}

private final class GestureDelegate: NSObject, UIGestureRecognizerDelegate {}
