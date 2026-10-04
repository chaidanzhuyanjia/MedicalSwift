# Phase 10 — external .swift file workflow

## VERIFIED — PASS

Phase 10 is now verified end to end on the iOS Simulator at commit `136ab1ca386d8cf9c4382267753b4735c9ecfab9`.

Verified GitHub Actions run:

- Workflow: `iOS Simulator CI`
- Run: `37175153083`
- Job: `111356135897`
- Result: **PASS**
- Swift CI for the same SHA: run `37175153082` — **PASS**

The built Runner Info.plist was checked in CI and contains:

- `UIFileSharingEnabled = true`
- `LSSupportsOpeningDocumentsInPlace = true`
- `UISupportsDocumentBrowser = true`
- `CFBundleDocumentTypes` with `public.swift-source`

The simulator pre-install step confirmed these real files in the Runner Documents container:

- `ImportedCounter.swift`
- `MedicalSwiftControl.txt`

The full system document-picker acceptance then passed:

```text
Import
→ Browse
→ On My iPhone
→ ImportedCounter.swift
→ return to Runner
→ navigation title = ImportedCounter.swift
→ Run
→ Count: 41
→ Imported tap
→ Count: 42
```

The existing embedded Counter regression also passed in the same run:

```text
Run → Count: 0 → Tap me → Count: 1
```

## Root cause fixed

The repeated Phase 10 failure was not the interpreter or the `.swift` UTI. The generated app Info.plist did not actually contain the Files/document-container keys even though they were written as generated-Info.plist build settings in `project.yml`.

The Runner now uses an explicit XcodeGen `info.properties` block so the final built app contains the required document metadata. CI verifies those final plist values before running the UI tests.

## Next acceptance

The next gate is a second imported Swift file using a PEDT-style subset:

- `Form`
- `Section`
- `Picker`
- multiple `@State Int`
- computed property using `+`
- `if/else`
- native re-render after picker selection

This is separate from the now-verified Phase 10 Counter file-import gate.

## Boundary

This proves the iOS Simulator system document-picker round trip using a real file in the Runner's Documents container. It does not yet prove every third-party Files provider or iCloud edge case.

MedicalSwift still interprets only its explicitly supported Swift/SwiftUI subset; it is not arbitrary Swift execution.
