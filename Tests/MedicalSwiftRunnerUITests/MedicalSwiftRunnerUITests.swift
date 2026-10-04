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

        let fixture = app.staticTexts["ImportedCounter.swift"].firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 10))
        fixture.tap()

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["Count: 0"].waitForExistence(timeout: 10))
        app.buttons["Tap me"].tap()
        XCTAssertTrue(app.staticTexts["Count: 1"].waitForExistence(timeout: 5))
    }
}
