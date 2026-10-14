// bs-12 AC-15 CONTROL fixture — a planted *offender* (ITEST-2 / GUARD-5).
//
// The CVD-model twin of `control_bound_to_concrete.dart`: this file deliberately
// binds a caller to the CONCRETE `DichromatConfusionCheck` (declaring a field of
// the concrete type) instead of depending on the `ConfusionCheck` interface. It
// exists ONLY so the AC-15 source guard can prove it discriminates: the GUARD-5
// `concreteTypeReferences('DichromatConfusionCheck')` scan, pointed at this
// fixtures directory, MUST list this file as a `ruleConcreteTypeReference`
// offender — a caller the "swap the CVD model without touching callers"
// guarantee would break.
//
// It lives under `integration_test/nfr/fixtures/controls/`, NOT under `lib/`, so
// the real AC-15 sweep over `lib/` (where every caller depends on
// `ConfusionCheck` and only the DI default constructs the concrete model) never
// sees it. It is never imported; the guard reads it as text.
//
// Test-support only — no `lib/` product code (D-7).

import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';

/// A caller bound to the concrete CVD model type — the AC-15 offence. A real
/// caller must depend on `ConfusionCheck`, never reach for
/// `DichromatConfusionCheck`.
final DichromatConfusionCheck boundToConcreteCvd = const DichromatConfusionCheck();
