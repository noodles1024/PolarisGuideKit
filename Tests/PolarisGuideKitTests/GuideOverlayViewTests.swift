import UIKit
import XCTest
@testable import PolarisGuideKit

@MainActor
final class GuideOverlayViewTests: XCTestCase {
    private struct Fixture {
        let host: UIView
        let container: UIView
        let focus: UIView
        let overlay: GuideOverlayView
        let step: GuideStep
    }

    private func makeFixture(hostBounds: CGRect = CGRect(x: 0, y: 0, width: 320, height: 480)) -> Fixture {
        let host = UIView(frame: CGRect(origin: .zero, size: hostBounds.size))
        host.bounds = hostBounds
        let focus = UIView(frame: CGRect(x: 90, y: 120, width: 60, height: 40))
        host.addSubview(focus)
        let container = UIView(frame: host.bounds)
        host.addSubview(container)
        let overlay = GuideOverlayView(hostView: host)
        attach(overlay, to: container)
        host.layoutIfNeeded()
        overlay.bind(to: host)
        let step = GuideStep()
        step.focusView = focus
        step.forwardsTouchEventsToFocusView = true
        return Fixture(host: host, container: container, focus: focus, overlay: overlay, step: step)
    }

    private func attach(_ overlay: GuideOverlayView, to container: UIView) {
        container.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: container.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func constraints(in host: UIView, referencing view: UIView) -> [NSLayoutConstraint] {
        host.constraints.filter { ($0.firstItem as? UIView) === view || ($0.secondItem as? UIView) === view }
    }

    func testInitializationDoesNotResolveOrBindAWindow() {
        let overlay = GuideOverlayView(hostView: nil)
        XCTAssertEqual(overlay.bounds, .zero)
        XCTAssertNil(overlay.resolvedHostView())

        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let hintedOverlay = GuideOverlayView(hostView: host)
        XCTAssertNil(hintedOverlay.resolvedHostView())
        hintedOverlay.bind(to: host)
        XCTAssertTrue(hintedOverlay.resolvedHostView() === host)
        hintedOverlay.bind(to: nil)
        XCTAssertNil(hintedOverlay.resolvedHostView())
    }

    func testSettingStepBeforeAttachmentDoesNotCreateCrossHierarchyConstraints() {
        let host = UIView()
        let focus = UIView()
        host.addSubview(focus)
        let step = GuideStep()
        step.focusView = focus
        let overlay = GuideOverlayView(hostView: host)
        overlay.bind(to: host)
        overlay.setStep(step, animated: false)

        XCTAssertNil(overlay.validatedFocusView)
        XCTAssertNil(overlay.shadowOfFocusView)
        XCTAssertNil(overlay.layer.mask)
    }

    func testOffscreenViewsInTheSameHierarchyCanBeHighlightedAndReceiveTouches() throws {
        let fixture = makeFixture()
        fixture.overlay.setStep(fixture.step, animated: false)
        fixture.host.layoutIfNeeded()

        XCTAssertNil(fixture.overlay.window)
        XCTAssertTrue(fixture.overlay.validatedFocusView === fixture.focus)
        XCTAssertTrue(fixture.overlay.shadowOfFocusView?.masterView === fixture.focus)
        let center = fixture.focus.convert(CGPoint(x: 30, y: 20), to: fixture.overlay)
        let maskPath = try XCTUnwrap((fixture.overlay.layer.mask as? CAShapeLayer)?.path)
        XCTAssertFalse(maskPath.contains(center, using: .evenOdd))
        XCTAssertTrue(fixture.overlay.hitTest(center, with: nil) === fixture.focus)
    }

    func testFocusInAnotherHierarchyIsNotHighlightedOrForwarded() throws {
        let fixture = makeFixture()
        let otherHost = UIView(frame: fixture.host.bounds)
        let otherFocus = UIView(frame: fixture.focus.frame)
        otherHost.addSubview(otherFocus)
        fixture.step.focusView = otherFocus
        fixture.overlay.setStep(fixture.step, animated: false)

        XCTAssertNil(fixture.overlay.validatedFocusView)
        XCTAssertNil(fixture.overlay.shadowOfFocusView)
        let point = CGPoint(x: 100, y: 130)
        let maskPath = try XCTUnwrap((fixture.overlay.layer.mask as? CAShapeLayer)?.path)
        XCTAssertTrue(maskPath.contains(point, using: .evenOdd))
        XCTAssertTrue(fixture.overlay.hitTest(point, with: nil) === fixture.overlay)
    }

    func testHostItselfCannotBeTheFocus() {
        let fixture = makeFixture()
        fixture.step.focusView = fixture.host
        fixture.overlay.setStep(fixture.step, animated: false)

        XCTAssertNil(fixture.overlay.validatedFocusView)
        XCTAssertNil(fixture.overlay.shadowOfFocusView)
    }

    func testRefreshNotifiesBuddyWhenDynamicFocusChanges() throws {
        let fixture = makeFixture()
        var focus: UIView? = fixture.focus
        fixture.step.focusViewProvider = { focus }
        var layoutGuides: [UILayoutGuide] = []
        let overlay = fixture.overlay
        overlay.onShadowChanged = { [weak overlay] in
            if let shadow = overlay?.shadowOfFocusView {
                layoutGuides.append(shadow.frameLayoutGuide)
            }
        }
        fixture.overlay.setStep(fixture.step, animated: false)
        let originalGuide = try XCTUnwrap(layoutGuides.last)
        let replacement = UIView(frame: CGRect(x: 140, y: 220, width: 80, height: 40))
        fixture.host.insertSubview(replacement, belowSubview: fixture.container)
        focus = replacement
        fixture.overlay.refreshMask(animated: false)

        XCTAssertEqual(layoutGuides.count, 2)
        XCTAssertFalse(layoutGuides.last === originalGuide)
        XCTAssertTrue(fixture.overlay.shadowOfFocusView?.masterView === replacement)
    }

    func testDetachedFocusClearsShadowAndCanRecoverWhenReattached() throws {
        let fixture = makeFixture()
        fixture.overlay.setStep(fixture.step, animated: false)
        let oldShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        fixture.focus.removeFromSuperview()
        fixture.overlay.refreshMask(animated: false)

        XCTAssertNil(fixture.overlay.validatedFocusView)
        XCTAssertNil(fixture.overlay.shadowOfFocusView)
        XCTAssertNil(oldShadow.superview)

        fixture.host.insertSubview(fixture.focus, belowSubview: fixture.container)
        fixture.overlay.refreshMask(animated: false)
        XCTAssertTrue(fixture.overlay.validatedFocusView === fixture.focus)
        XCTAssertNotNil(fixture.overlay.shadowOfFocusView)
        XCTAssertFalse(fixture.overlay.shadowOfFocusView === oldShadow)
    }

    func testNilDynamicFocusClearsShadowAndNotifiesBuddy() {
        let fixture = makeFixture()
        var focus: UIView? = fixture.focus
        fixture.step.focusViewProvider = { focus }
        fixture.overlay.setStep(fixture.step, animated: false)
        var changes = 0
        fixture.overlay.onShadowChanged = { changes += 1 }
        focus = nil
        fixture.overlay.refreshMask(animated: false)

        XCTAssertNil(fixture.overlay.validatedFocusView)
        XCTAssertNil(fixture.overlay.shadowOfFocusView)
        XCTAssertEqual(changes, 1)
    }

    func testMissingTrackingConstraintIsRebuiltEvenWhenFocusIdentityIsUnchanged() throws {
        let fixture = makeFixture()
        fixture.overlay.setStep(fixture.step, animated: false)
        let oldShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        let trackingConstraints = constraints(in: fixture.host, referencing: oldShadow)
        XCTAssertEqual(trackingConstraints.count, 4)
        try XCTUnwrap(trackingConstraints.first).isActive = false
        fixture.overlay.refreshMask(animated: false)

        let newShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        XCTAssertFalse(newShadow === oldShadow)
        XCTAssertEqual(constraints(in: fixture.host, referencing: newShadow).filter(\.isActive).count, 4)
    }

    func testReattachmentRebuildsTrackingConstraintsForTheSameStep() throws {
        let fixture = makeFixture()
        fixture.overlay.setStep(fixture.step, animated: false)
        let oldShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        fixture.overlay.removeFromSuperview()
        attach(fixture.overlay, to: fixture.container)
        fixture.overlay.setStep(fixture.step, animated: false)

        let newShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        XCTAssertFalse(newShadow === oldShadow)
        XCTAssertEqual(constraints(in: fixture.host, referencing: newShadow).filter(\.isActive).count, 4)
    }

    func testClearingStepRemovesMaskShadowAndAnimationBeforeReusingTheSameStep() throws {
        let fixture = makeFixture()
        fixture.overlay.setStep(fixture.step, animated: false)
        let oldShadow = try XCTUnwrap(fixture.overlay.shadowOfFocusView)
        fixture.focus.frame.origin.x += 20
        fixture.overlay.refreshMask(animated: true)
        XCTAssertTrue(fixture.overlay.isInTransitionAnimation)
        fixture.overlay.setStep(nil, animated: true)

        XCTAssertNil(fixture.overlay.step)
        XCTAssertNil(fixture.overlay.layer.mask)
        XCTAssertNil(fixture.overlay.shadowOfFocusView)
        XCTAssertNil(fixture.overlay.validatedFocusView)
        XCTAssertFalse(fixture.overlay.isInTransitionAnimation)
        XCTAssertTrue(constraints(in: fixture.host, referencing: oldShadow).isEmpty)

        fixture.overlay.setStep(fixture.step, animated: false)
        XCTAssertNotNil(fixture.overlay.shadowOfFocusView)
        XCTAssertFalse(fixture.overlay.shadowOfFocusView === oldShadow)
    }

    func testShadowCallbackCanSynchronouslyClearAndUnbindThePresentation() {
        let fixture = makeFixture()
        let overlay = fixture.overlay
        var callbackCount = 0
        var originalShadow: GuideShadowView?
        overlay.onShadowChanged = { [weak overlay] in
            guard let overlay = overlay else { return }
            callbackCount += 1
            guard callbackCount == 1 else { return }
            originalShadow = overlay.shadowOfFocusView
            overlay.setStep(nil, animated: false)
            overlay.removeFromSuperview()
            overlay.bind(to: nil)
        }

        overlay.setStep(fixture.step, animated: false)

        XCTAssertEqual(callbackCount, 2)
        XCTAssertNil(overlay.step)
        XCTAssertNil(overlay.shadowOfFocusView)
        XCTAssertNil(overlay.layer.mask)
        XCTAssertNil(overlay.resolvedHostView())
        XCTAssertNil(originalShadow?.superview)
    }

    func testRefreshingFromShadowCallbackDoesNotRepeatTheCallback() {
        let fixture = makeFixture()
        let overlay = fixture.overlay
        var callbackCount = 0
        overlay.onShadowChanged = { [weak overlay] in
            callbackCount += 1
            overlay?.refreshMask(animated: false)
        }

        overlay.setStep(fixture.step, animated: false)

        XCTAssertEqual(callbackCount, 1)
        XCTAssertTrue(overlay.shadowOfFocusView?.masterView === fixture.focus)
    }

    func testLayoutCallbackClearingStepCannotRestoreTheOldMask() {
        let fixture = makeFixture()
        let focusContainer = CallbackLayoutView(frame: fixture.host.bounds)
        let focus = UIView(frame: CGRect(x: 90, y: 120, width: 60, height: 40))
        focusContainer.addSubview(focus)
        fixture.host.insertSubview(focusContainer, belowSubview: fixture.container)
        fixture.step.focusView = focus
        let overlay = fixture.overlay
        overlay.setStep(fixture.step, animated: false)

        var didRunCallback = false
        focusContainer.onLayout = { [weak overlay] in
            didRunCallback = true
            overlay?.setStep(nil, animated: false)
        }
        focusContainer.setNeedsLayout()
        overlay.refreshMask(animated: false)

        XCTAssertTrue(didRunCallback)
        XCTAssertNil(overlay.step)
        XCTAssertNil(overlay.shadowOfFocusView)
        XCTAssertNil(overlay.layer.mask)
        XCTAssertFalse(overlay.isInTransitionAnimation)
    }

    func testHighlightUsesOverlayCoordinatesWhenHostBoundsOriginIsNonzero() throws {
        let fixture = makeFixture(hostBounds: CGRect(x: 40, y: 60, width: 320, height: 480))
        let style = RecordingFocusStyle()
        fixture.step.focusStyle = style
        fixture.overlay.setStep(fixture.step, animated: false)

        XCTAssertEqual(try XCTUnwrap(style.frameInOverlay), CGRect(x: 50, y: 60, width: 60, height: 40))
    }
}

private final class CallbackLayoutView: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        let callback = onLayout
        onLayout = nil
        callback?()
    }
}

private final class RecordingFocusStyle: FocusStyle {
    var frameInOverlay: CGRect?

    func highlightPath(for focusView: UIView, frameInOverlay rect: CGRect) -> UIBezierPath? {
        frameInOverlay = rect
        return UIBezierPath(rect: rect)
    }

    func buddyLayoutGuide(for focusView: UIView, shadowView: GuideShadowView) -> UILayoutGuide {
        shadowView.frameLayoutGuide
    }
}
