import XCTest

@MainActor
final class MedicalSwiftRunnerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCounterScriptRunsAndReRenders() throws {
        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["sourceEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let importButton = app.buttons["importButton"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        let initialCount = app.staticTexts["Count: 0"]
        XCTAssertTrue(initialCount.waitForExistence(timeout: 10))

        let tapButton = app.buttons["Tap me"]
        XCTAssertTrue(tapButton.waitForExistence(timeout: 5))
        tapButton.tap()

        let updatedCount = app.staticTexts["Count: 1"]
        XCTAssertTrue(updatedCount.waitForExistence(timeout: 5))
    }
    func testImportsSwiftFileThroughDocumentPickerAndRuns() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launch()

        let editor = app.textViews["sourceEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10),
            "ImportedCounter.swift was not created in the Runner Documents directory"
        )

        let importButton = app.buttons["importButton"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        importButton.tap()

        XCTAssertTrue(
            selectDocument(named: "ImportedCounter.swift", app: app),
            "Could not find ImportedCounter.swift in the system document picker"
        )

        XCTAssertTrue(app.navigationBars["ImportedCounter.swift"].waitForExistence(timeout: 10))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["Count: 41"].waitForExistence(timeout: 10))
        let importedButton = app.buttons["Imported tap"]
        XCTAssertTrue(importedButton.waitForExistence(timeout: 5))
        importedButton.tap()
        XCTAssertTrue(app.staticTexts["Count: 42"].waitForExistence(timeout: 5))
    }

    private func selectDocument(named filename: String, app: XCUIApplication) -> Bool {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        let apps = [app, files]

        if tapNamedItem(filename, in: apps, timeout: 2) {
            return true
        }

        _ = tapNamedItem("Browse", in: apps, timeout: 3)

        if tapNamedItem("On My iPhone", in: apps, timeout: 5) {
            if !tapNamedItem("MedicalSwift", in: apps, timeout: 5) {
                _ = tapNamedItem("MedicalSwiftRunner", in: apps, timeout: 3)
            }
        }

        return tapNamedItem(filename, in: apps, timeout: 8)
    }

    private func tapNamedItem(
        _ name: String,
        in apps: [XCUIApplication],
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            for app in apps {
                let predicate = NSPredicate(
                    format: "label == %@ OR identifier == %@",
                    name,
                    name
                )
                let candidates = [
                    app.descendants(matching: .any).matching(predicate).firstMatch,
                    app.cells.containing(.staticText, identifier: name).firstMatch,
                    app.cells[name].firstMatch,
                    app.buttons[name].firstMatch,
                    app.staticTexts[name].firstMatch,
                    app.otherElements[name].firstMatch
                ]

                for element in candidates where element.exists {
                    if element.isHittable {
                        element.tap()
                        return true
                    }

                    if !element.frame.isEmpty {
                        element.coordinate(
                            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
                        ).tap()
                        return true
                    }
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        return false
    }

}