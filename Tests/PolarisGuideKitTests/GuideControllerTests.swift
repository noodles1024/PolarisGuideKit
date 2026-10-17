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
