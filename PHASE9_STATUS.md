# Phase 9 — runtime acceptance

## Goal

Move beyond compile-only validation. CI must now produce the actual unsigned iOS Simulator application bundle as an artifact, establishing a reproducible executable output for runtime testing.

## Gate A — application artifact

The iOS workflow builds with a deterministic DerivedData path, verifies that:

`Debug-iphonesimulator/MedicalSwiftRunner.app`

exists, packages it, and uploads it as the `MedicalSwiftRunner-simulator` artifact.

## Gate B — behavioral runtime acceptance

The minimum behavior remains:

```swift
struct ContentView: View {
    @State var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Tap me") {
                count += 1
            }
        }
    }
}
```

Acceptance: Runner launches -> source is parsed -> native UI is shown -> tapping the button changes count from 0 to 1 -> Text re-renders.

Gate B is not yet claimed as verified. Producing a simulator `.app` is the prerequisite for adding a booted-simulator launch/UI test.

Physical-device signing remains a later phase.
