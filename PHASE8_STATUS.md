# Phase 8 — iOS application shell

Phase 8 adds an XcodeGen specification for a real iOS application target and a separate GitHub Actions gate that builds the app against the iOS Simulator SDK.

## Gate

The phase is not accepted until this command succeeds in GitHub Actions:

```sh
xcodebuild \
  -project MedicalSwift.xcodeproj \
  -scheme MedicalSwiftRunner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This gate intentionally does not require Apple signing credentials.

A successful simulator build proves that the Runner and MedicalSwiftCore can be compiled as an iOS application. It still does not prove physical-device installation or App Store/TestFlight eligibility.
