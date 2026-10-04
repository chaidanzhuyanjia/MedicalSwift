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

    func testImportsPEDTFormPickerComputedConditional() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))

        let importButton = app.buttons["importButton"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        importButton.tap()

        XCTAssertTrue(
            selectDocument(named: "ImportedPEDT.swift", app: app),
            "Could not find ImportedPEDT.swift in the system document picker"
        )
        XCTAssertTrue(app.navigationBars["ImportedPEDT.swift"].waitForExistence(timeout: 10))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["PEDT demo"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Total: 0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Lower score"].waitForExistence(timeout: 5))

        XCTAssertTrue(tapPickerRow(named: "Q1", app: app))
        XCTAssertTrue(tapPickerOption(named: "4 points", app: app))

        XCTAssertTrue(app.staticTexts["Total: 4"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Higher score"].waitForExistence(timeout: 5))
    }

    private func tapPickerRow(named name: String, app: XCUIApplication) -> Bool {
        let cell = app.cells.containing(.staticText, identifier: name).firstMatch
        if cell.waitForExistence(timeout: 5) {
            cell.tap()
            return true
        }

        let button = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", name)
        ).firstMatch
        if button.waitForExistence(timeout: 3) {
            button.tap()
            return true
        }

        let label = app.staticTexts[name]
        if label.waitForExistence(timeout: 3) {
            label.tap()
            return true
        }

        return false
    }

    private func tapPickerOption(named name: String, app: XCUIApplication) -> Bool {
        let button = app.buttons[name]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            return true
        }

        let label = app.staticTexts[name]
        if label.waitForExistence(timeout: 5) {
            label.tap()
            return true
        }

        return false
    }

    private func selectDocument(named filename: String, app: XCUIApplication) -> Bool {
        // SwiftUI fileImporter is presented inside the Runner's accessibility tree
        // on the simulator. Querying com.apple.DocumentsApp directly can fail because
        // that application is not running while the picker UI is hosted in-process.
        let pickerApps = [app]

        if tapPickerItem(filename, in: pickerApps, timeout: 2) {
            return true
        }

        guard tapPickerItem("Browse", in: pickerApps, timeout: 4) else {
            return false
        }

        guard tapPickerItem("On My iPhone", in: pickerApps, timeout: 6) else {
            return false
        }

        guard tapFolder(named: "MedicalSwift", in: pickerApps, timeout: 6)
            || tapFolder(named: "MedicalSwiftRunner", in: pickerApps, timeout: 3)
        else {
            print("PHASE10_DIAGNOSTIC folder_not_found")
            print("PHASE10_DIAGNOSTIC runner_hierarchy=\n\(app.debugDescription)")
            return false
        }

        if tapPickerItem(filename, in: pickerApps, timeout: 10) {
            return true
        }

        let controlVisible = pickerItemExists("MedicalSwiftControl.txt", in: pickerApps)
        print("PHASE10_DIAGNOSTIC control_txt_visible=\(controlVisible)")
        print("PHASE10_DIAGNOSTIC runner_hierarchy=\n\(app.debugDescription)")
        return false
    }

    private func pickerItemExists(_ name: String, in apps: [XCUIApplication]) -> Bool {
        let predicate = NSPredicate(
            format: "label == %@ OR identifier == %@",
            name,
            name
        )

        for app in apps {
            let candidates = [
                app.cells.containing(.staticText, identifier: name).firstMatch,
                app.cells[name].firstMatch,
                app.buttons[name].firstMatch,
                app.staticTexts[name].firstMatch,
                app.otherElements[name].firstMatch,
                app.descendants(matching: .any).matching(predicate).firstMatch
            ]
            if candidates.contains(where: { $0.exists }) {
                return true
            }
        }
        return false
    }

    private func tapFolder(
        named name: String,
        in apps: [XCUIApplication],
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let predicate = NSPredicate(
            format: "label == %@ OR identifier == %@",
            name,
            name
        )

        repeat {
            for app in apps {
                let cellCandidates = [
                    app.cells.containing(.staticText, identifier: name).firstMatch,
                    app.cells[name].firstMatch
                ]

                for element in cellCandidates where element.exists {
                    if tapIfUsable(element) {
                        return true
                    }
                }

                // The Runner itself also has a "MedicalSwift" navigation title.
                // When the document picker is open, choose the matching label
                // furthest down the screen; that is the Files folder row/grid item,
                // not the navigation chrome at the top.
                let labels = app.staticTexts.matching(predicate)
                var visibleLabels: [XCUIElement] = []
                for index in 0..<labels.count {
                    let element = labels.element(boundBy: index)
                    if element.exists, !element.frame.isEmpty {
                        visibleLabels.append(element)
                    }
                }

                if let folderLabel = visibleLabels.max(by: {
                    $0.frame.midY < $1.frame.midY
                }),
                folderLabel.frame.midY > 100,
                tapIfUsable(folderLabel) {
                    return true
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        return false
    }

    private func tapPickerItem(
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
                    app.cells.containing(.staticText, identifier: name).firstMatch,
                    app.cells[name].firstMatch,
                    app.buttons[name].firstMatch,
                    app.staticTexts[name].firstMatch,
                    app.otherElements[name].firstMatch,
                    app.descendants(matching: .any).matching(predicate).firstMatch
                ]

                for element in candidates where element.exists {
                    if tapIfUsable(element) {
                        return true
                    }
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        return false
    }

    private func tapIfUsable(_ element: XCUIElement) -> Bool {
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

        return false
    }

}