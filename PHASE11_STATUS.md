# Phase 11 — practical Swift subset baseline

## VERIFIED BASELINE BEFORE THIS PHASE

The prior baseline at commit `6c08bcfc747d4fd823598ded687476ae96e8725f` is green:

- Swift CI: run `37180077987` — PASS
- iOS Simulator CI: run `37180078020` — PASS
- Counter runtime: PASS
- PEDT Form/Section/Picker/computed property/if-else: PASS
- Range ForEach: PASS (`Row 0`, `Row 1`, `Row 2`)

The system Files picker round trip was separately verified in Phase 10 at run `37175153083`.

Routine CI now uses deterministic fixture autoload for repeated language/runtime checks so the known-flaky Files UI does not turn normal language changes red. The actual import code and document-container metadata remain in the app.

## CURRENT PHASE TARGET

This phase expands the Swift subset needed by practical calculators and clinical tools:

- arithmetic expressions: `+`, `-`, `*`
- assignment in Button actions
- `+=`
- `-=`
- `Bool.toggle()`
- Bool/String equality and inequality conditions
- `.font(.title/.headline/.body/.caption)`

Acceptance fixture: `ImportedArithmetic.swift`.

