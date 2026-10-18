import UIKit

/// Supplies a stable failure requirement for one external gesture. Unlike a
/// dependency on the shared blocker, this can let one whitelisted gesture pass
/// without releasing any of the other external gestures.
internal final class GuideGestureGate: UIGestureRecognizer {
    private(set) weak var guardedGesture: UIGestureRecognizer?
    var shouldBlock: ((UIGestureRecognizer) -> Bool)?

    init(guarding gesture: UIGestureRecognizer, shouldBlock: @escaping (UIGestureRecognizer) -> Bool) {
        guardedGesture = gesture
        self.shouldBlock = shouldBlock
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .possible else { return }
        guard let gesture = guardedGesture, shouldBlock?(gesture) == true else {
            state = .failed
            return
        }
        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed { state = .changed }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed { state = .ended }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed { state = .cancelled }
    }

    // Only the explicit failure requirement may block another recognizer. A
    // whitelisted or internal gesture must neither prevent this gate nor be
    // prevented by a gate belonging to some other external gesture.
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    func invalidate() {
        isEnabled = false
        view?.removeGestureRecognizer(self)
        shouldBlock = nil
    }
}
