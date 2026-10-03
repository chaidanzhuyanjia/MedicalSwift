import SwiftUI
import MedicalSwiftCore

@main
struct MedicalSwiftRunnerApp: App {
    var body: some Scene {
        WindowGroup { RunnerHomeView() }
    }
}

struct RunnerHomeView: View {
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

    var body: some View {
        NavigationStack {
            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .padding()
                .navigationTitle("MedicalSwift")
                .toolbar {
                    Button(action: run) {
                        Label("Run", systemImage: "play.fill")
                    }
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

    private func run() {
        do {
            runtime = ScriptRuntime(program: try SwiftSubsetParser().parse(source))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
