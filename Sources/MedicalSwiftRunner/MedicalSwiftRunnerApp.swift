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
    private static let swiftSourceType = UTType(filenameExtension: "swift") ?? .plainText

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

    var body: some View {
        NavigationStack {
            TextEditor(text: $source)
                .accessibilityIdentifier("sourceEditor")
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
                    allowedContentTypes: [Self.swiftSourceType],
                    allowsMultipleSelection: false
                ) { result in
                    importSource(result)
                }
                .task {
                    seedUITestFixtureIfRequested()
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

        let fixture = """
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

        do {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            try fixture.write(
                to: documents.appendingPathComponent("ImportedCounter.swift"),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importSource(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
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
