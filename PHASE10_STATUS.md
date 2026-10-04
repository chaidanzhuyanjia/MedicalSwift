# Phase 10 — external .swift file workflow

## Implementation status

The Runner exposes an **Import** action backed by SwiftUI `fileImporter`. It accepts `.swift` files through a `UTType` derived from the Swift filename extension, reads the selected security-scoped URL as UTF-8 source, places the source in the editor, and clears any previously running runtime instance.

Commit `d94dfb7889af22785129a63e61eaf7b4374fb775` passed the push-triggered Swift CI and full iOS Simulator CI, including the existing Counter runtime regression test and verification that the Import control is present.

## Document-picker round-trip gate

A second UI acceptance test now seeds a deterministic `ImportedCounter.swift` into the Runner's Documents directory, opens the real system document picker, selects that `.swift` file, returns to the editor, taps **Run**, and requires the same `Count: 0 -> Count: 1` native interaction.

The app target also enables:

- `UIFileSharingEnabled`
- `LSSupportsOpeningDocumentsInPlace`

so its Documents directory participates in the Files workflow.

This round-trip test is not yet marked verified until the new CI run is green.

## Boundary

The seeded fixture validates the iOS document-picker path and real file reading, but it is still a deterministic simulator fixture created in the app's Documents directory. It does not yet prove every third-party Files provider or iCloud edge case.

The runtime continues to execute only the supported MedicalSwift subset, not arbitrary Swift.
