# Phase 10 — external .swift file workflow

## Goal

Close the remaining video-parity gap between an embedded sample string and a user-selected real Swift source file.

The Runner now exposes an **Import** action backed by SwiftUI `fileImporter`. It accepts `.swift` files through a `UTType` derived from the Swift filename extension, reads the selected security-scoped URL as UTF-8 source, places the source in the editor, and clears any previously running runtime instance.

## Intended user flow

```
Files / iCloud Drive / local provider
-> choose SomeTool.swift
-> source appears in TextEditor
-> edit if desired
-> Run
-> SwiftSyntax parse/lower
-> native SwiftUI renderer
```

## Acceptance status

Implementation is committed, but Phase 10 is not yet marked verified.

Required next checks:

1. existing Swift package CI stays green;
2. iOS Simulator build stays green;
3. Counter runtime UI acceptance remains green;
4. Import control is present in the real Runner;
5. later, add a simulator automation path for selecting a real external `.swift` fixture through the document picker.

This phase still executes only the supported MedicalSwift subset, not arbitrary Swift.
