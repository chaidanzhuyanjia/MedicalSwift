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
    func testLoadsCounterFileAndReRenders() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_AUTOLOAD"] = "ImportedCounter.swift"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))
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

    func testLoadsPEDTFileAndReRendersPickerComputedConditional() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_AUTOLOAD"] = "ImportedPEDT.swift"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))
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

    func testLoadsForEachFileAndRendersRange() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_AUTOLOAD"] = "ImportedForEach.swift"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["ImportedForEach.swift"].waitForExistence(timeout: 10))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["Row 0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Row 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Row 2"].waitForExistence(timeout: 5))
    }

    func testLoadsArithmeticFileAndRunsAssignments() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_AUTOLOAD"] = "ImportedArithmetic.swift"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["ImportedArithmetic.swift"].waitForExistence(timeout: 10))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["Value: 2"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Double: 4"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Disabled"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose: 2.5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose total: 7.5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose half: 3.75"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose low"].waitForExistence(timeout: 5))

        app.buttons["Add three"].tap()
        XCTAssertTrue(app.staticTexts["Value: 5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Double: 10"].waitForExistence(timeout: 5))

        app.buttons["Minus one"].tap()
        XCTAssertTrue(app.staticTexts["Value: 4"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Double: 8"].waitForExistence(timeout: 5))

        app.buttons["Toggle enabled"].tap()
        XCTAssertTrue(app.staticTexts["Enabled"].waitForExistence(timeout: 5))

        app.buttons["Add half dose"].tap()
        XCTAssertTrue(app.staticTexts["Dose: 3.0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose total: 9.0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose half: 4.5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dose high"].waitForExistence(timeout: 5))
    }

    func testLoadsStaticArrayForEachFile() throws {
        let app = XCUIApplication()
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_SEED"] = "1"
        app.launchEnvironment["MEDICALSWIFT_UI_TEST_AUTOLOAD"] = "ImportedArray.swift"
        app.launch()

        XCTAssertTrue(app.textViews["sourceEditor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UITest fixture ready"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["ImportedArray.swift"].waitForExistence(timeout: 10))

        let runButton = app.buttons["runButton"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5))
        runButton.tap()

        XCTAssertTrue(app.staticTexts["Item: Pain"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Item: Urinary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Item: QoL"].waitForExistence(timeout: 5))
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
        // SwiftUI fileImporter is presented inside the Runner accessibility tree.
        // Files can reopen in the last visited location and its local-provider index
        // can lag briefly after XCTest reinstalls the app, so treat navigation as a
        // small state machine instead of assuming one fixed screen.
        let pickerApps = [app]

        if tapDocument(named: filename, in: pickerApps, timeout: 8) {
            return true
        }

        // "Browse" may be absent when the picker already reopened on a browse page.
        _ = tapPickerItem("Browse", in: pickerApps, timeout: 3)

        if tapDocument(named: filename, in: pickerApps, timeout: 4) {
            return true
        }

        // Likewise, On My iPhone may already be the active location.
        _ = tapPickerItem("On My iPhone", in: pickerApps, timeout: 6)

        if tapDocument(named: filename, in: pickerApps, timeout: 4) {
            return true
        }

        if tapFolder(named: "MedicalSwift", in: pickerApps, timeout: 6)
            || tapFolder(named: "MedicalSwiftRunner", in: pickerApps, timeout: 3) {
            if tapDocument(named: filename, in: pickerApps, timeout: 15) {
                return true
            }
        }

        let controlVisible = pickerItemExists("MedicalSwiftControl.txt", in: pickerApps)
        print("PHASE10_DIAGNOSTIC target=\(filename) control_txt_visible=\(controlVisible)")
        print("PHASE10_DIAGNOSTIC runner_hierarchy=\n\(app.debugDescription)")
        return false
    }

    private func tapDocument(
        named filename: String,
        in apps: [XCUIApplication],
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            for app in apps {
                let picker = app.otherElements["Browse View (Picker)"]
                if !picker.exists {
                    return true
                }

                let prefix = NSPredicate(
                    format: "label BEGINSWITH[c] %@ OR identifier == %@",
                    filename,
                    filename
                )

                let cell = app.cells.matching(prefix).firstMatch
                if cell.exists, tapIfUsable(cell) {
                    let dismissalDeadline = Date().addingTimeInterval(8.0)
                    repeat {
                        if !picker.exists {
                            return true
                        }
                        RunLoop.current.run(
                            until: Date().addingTimeInterval(0.2)
                        )
                    } while Date() < dismissalDeadline

                    // Do not repeatedly tap a stale Files element while the picker
                    // is dismissing. A single document-cell tap is the selection.
                    return false
                }

                let label = app.staticTexts[filename].firstMatch
                if label.exists, tapIfUsable(label) {
                    let dismissalDeadline = Date().addingTimeInterval(8.0)
                    repeat {
                        if !picker.exists {
                            return true
                        }
                        RunLoop.current.run(
                            until: Date().addingTimeInterval(0.2)
                        )
                    } while Date() < dismissalDeadline
                    return false
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

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