import UIKit
import XCTest
@testable import PolarisGuideKit

@MainActor
final class GestureRecognizerCompleterTests: XCTestCase {
    func testReleaseRemovesEnabledAndDisabledRecognizers() {
        for enabled in [false, true] {
            let view = UIView()
            let recognizer = UITapGestureRecognizer()
            weak var released: GestureRecognizerCompleter?

            autoreleasepool {
                let completer = GestureRecognizerCompleter(view: view, gestureRecognizer: recognizer)
                released = completer
                completer.enable()
                if !enabled { completer.disable() }
                XCTAssertEqual(recognizer.isEnabled, enabled)
                XCTAssertTrue(recognizer.view === view)
            }

            XCTAssertNil(released)
            XCTAssertNil(recognizer.view)
            XCTAssertTrue(view.gestureRecognizers?.isEmpty ?? true)
        }
    }

    func testRepeatedGuideLifetimesDoNotAccumulateRecognizers() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let focus = UIView(frame: CGRect(x: 20, y: 40, width: 80, height: 40))
        host.addSubview(focus)
        let existingRecognizer = UITapGestureRecognizer()
        focus.addGestureRecognizer(existingRecognizer)

        for explicitlyHide in [false, true] {
            for _ in 0..<3 {
                weak var released: GuideController?
                autoreleasepool {
                    let step = GuideStep()
                    step.focusView = focus
                    step.completer = GestureRecognizerCompleter(view: focus)
                    let guide = GuideController(hostView: host, steps: [step])
                    released = guide
                    XCTAssertTrue(guide.show())
                    XCTAssertEqual(focus.gestureRecognizers?.count, 2)
                    if explicitlyHide { guide.hide() }
                }

                XCTAssertNil(released)
                XCTAssertEqual(focus.gestureRecognizers?.count, 1)
                XCTAssertTrue(focus.gestureRecognizers?.first === existingRecognizer)
            }
        }
    }

    func testReleaseDetachesRecognizerFromItsCurrentView() {
        let originalView = UIView()
        let currentView = UIView()
        let recognizer = UITapGestureRecognizer()
        weak var released: GestureRecognizerCompleter?

        autoreleasepool {
            let completer = GestureRecognizerCompleter(view: originalView, gestureRecognizer: recognizer)
            released = completer
            completer.enable()
            currentView.addGestureRecognizer(recognizer)
            XCTAssertTrue(recognizer.view === currentView)
        }

        XCTAssertNil(released)
        XCTAssertNil(recognizer.view)
        XCTAssertTrue(originalView.gestureRecognizers?.isEmpty ?? true)
        XCTAssertTrue(currentView.gestureRecognizers?.isEmpty ?? true)
    }
}
