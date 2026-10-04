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

        if tapIfPresent([
            app.staticTexts[filename].firstMatch,
            files.staticTexts[filename].firstMatch
        ], timeout: 2) {
            return true
        }

        _ = tapIfPresent([
            app.tabBars.buttons["Browse"].firstMatch,
            files.tabBars.buttons["Browse"].firstMatch,
            app.buttons["Browse"].firstMatch,
            files.buttons["Browse"].firstMatch
        ], timeout: 3)

        if tapIfPresent([
            app.staticTexts["On My iPhone"].firstMatch,
            files.staticTexts["On My iPhone"].firstMatch
        ], timeout: 5) {
            _ = tapIfPresent([
                app.staticTexts["MedicalSwift"].firstMatch,
                files.staticTexts["MedicalSwift"].firstMatch,
                app.staticTexts["MedicalSwiftRunner"].firstMatch,
                files.staticTexts["MedicalSwiftRunner"].firstMatch
            ], timeout: 5)
        }

        return tapIfPresent([
            app.staticTexts[filename].firstMatch,
            files.staticTexts[filename].firstMatch
        ], timeout: 8)
    }

    private func tapIfPresent(_ elements: [XCUIElement], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for element in elements where element.exists && element.isHittable {
                element.tap()
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }

}