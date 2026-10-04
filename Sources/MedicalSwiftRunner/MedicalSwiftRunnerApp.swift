import SwiftUI
import UniformTypeIdentifiers
import Foundation
import MedicalSwiftCore

@main
struct MedicalSwiftRunnerApp: App {
    var body: some Scene {
        WindowGroup { RunnerHomeView() }
    }
}

struct RunnerHomeView: View {
    private static let swiftSourceType = UTType.swiftSource

    @State private var source = """
import SwiftUI
struct ContentView: View {
    @State var count = 0
    var body: some View {
        VStack {
            Text("Count: \\(count)")
            Button("Tap me") {
                count += 1
            }
        }
    }
}
"""
    @State private var runtime: ScriptRuntime?
    @State private var errorMessage: String?
    @State private var showingImporter = false
    @State private var loadedFilename: String?
    @State private var uiTestFixtureReady = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if ProcessInfo.processInfo.environment["MEDICALSWIFT_UI_TEST_SEED"] == "1" {
                    Text(uiTestFixtureReady ? "UITest fixture ready" : "UITest fixture pending")
                        .accessibilityIdentifier("uiTestFixtureStatus")
                        .font(.caption)
                }
                TextEditor(text: $source)
                    .accessibilityIdentifier("sourceEditor")
            }
                .font(.system(.body, design: .monospaced))
                .padding()
                .navigationTitle(loadedFilename ?? "MedicalSwift")
                .toolbar {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import", systemImage: "doc.badge.plus")
                    }
                    .accessibilityIdentifier("importButton")

                    Button(action: run) {
                        Label("Run", systemImage: "play.fill")
                    }
                    .accessibilityIdentifier("runButton")
                }
                .navigationDestination(
                    isPresented: Binding(
                        get: { runtime != nil },
                        set: { if !$0 { runtime = nil } }
                    )
                ) {
                    if let runtime {
                        NativeRenderer(runtime: runtime)
                    }
                }
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [Self.swiftSourceType, .sourceCode, .plainText],
                    allowsMultipleSelection: false
                ) { result in
                    importSource(result)
                }
                .task {
                    seedUITestFixtureIfRequested()
                    autoloadUITestFixtureIfRequested()
                }
                .alert(
                    "Cannot run",
                    isPresented: Binding(
                        get: { errorMessage != nil },
                        set: { if !$0 { errorMessage = nil } }
                    )
                ) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
        }
    }

    private func seedUITestFixtureIfRequested() {
        guard ProcessInfo.processInfo.environment["MEDICALSWIFT_UI_TEST_SEED"] == "1" else { return }

        let counterFixture = """
import SwiftUI
struct ContentView: View {
    @State var count = 41
    var body: some View {
        VStack {
            Text("Count: \\(count)")
            Button("Imported tap") {
                count += 1
            }
        }
    }
}
"""

        let pedtFixture = """
import SwiftUI
struct ContentView: View {
    @State var q1 = 0
    @State var q2 = 0

    var total: Int { q1 + q2 }

    var body: some View {
        Form {
            Section("PEDT demo") {
                Picker("Q1", selection: $q1) {
                    Text("0 points").tag(0)
                    Text("1 point").tag(1)
                    Text("4 points").tag(4)
                }
                Picker("Q2", selection: $q2) {
                    Text("0 points").tag(0)
                    Text("2 points").tag(2)
                }
                Text("Total: \\(total)")
                if total >= 4 {
                    Text("Higher score")
                } else {
                    Text("Lower score")
                }
            }
        }
    }
}
"""

        let forEachFixture = """
import SwiftUI
struct ContentView: View {
    @State var count = 3
    var body: some View {
        VStack {
            ForEach(0..<count, id: \\.self) { i in
                Text("Row \\(i)")
            }
        }
    }
}
"""

        do {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)

            let counterURL = documents.appendingPathComponent("ImportedCounter.swift")
            let pedtURL = documents.appendingPathComponent("ImportedPEDT.swift")
            let forEachURL = documents.appendingPathComponent("ImportedForEach.swift")
            let controlURL = documents.appendingPathComponent("MedicalSwiftControl.txt")
            try counterFixture.write(to: counterURL, atomically: true, encoding: .utf8)
            try pedtFixture.write(to: pedtURL, atomically: true, encoding: .utf8)
            try forEachFixture.write(to: forEachURL, atomically: true, encoding: .utf8)
            try "MedicalSwift file-provider control".write(
                to: controlURL,
                atomically: true,
                encoding: .utf8
            )
            uiTestFixtureReady =
                FileManager.default.fileExists(atPath: counterURL.path)
                && FileManager.default.fileExists(atPath: pedtURL.path)
                && FileManager.default.fileExists(atPath: forEachURL.path)
                && FileManager.default.fileExists(atPath: controlURL.path)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func autoloadUITestFixtureIfRequested() {
        guard let filename =
            ProcessInfo.processInfo.environment["MEDICALSWIFT_UI_TEST_AUTOLOAD"],
            !filename.isEmpty
        else { return }

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let url = documents.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "UI test fixture not found: \(filename)"
            return
        }

        importSource(.success([url]))
    }

    private func importSource(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            guard url.pathExtension.lowercased() == "swift" else {
                throw ImportError.notSwiftFile
            }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            source = try String(contentsOf: url, encoding: .utf8)
            loadedFilename = url.lastPathComponent
            runtime = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func run() {
        do {
            runtime = ScriptRuntime(program: try SwiftSubsetParser().parse(source))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


private enum ImportError: LocalizedError {
    case notSwiftFile

    var errorDescription: String? {
        switch self {
        case .notSwiftFile:
            return "Please select a .swift source file."
        }
    }
}
