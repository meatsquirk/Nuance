// bs-12 AC-14 CONTROL fixture — a planted *offender* (ITEST-2).
//
// This file deliberately binds a caller to the CONCRETE `SubtractiveMixingEngine`
// (importing and instantiating it directly) instead of depending on the
// `MixingEngine` interface. It exists ONLY so the AC-14 source guard can prove it
// discriminates: the GUARD-5 / GUARD-6 scan, pointed at this fixtures directory,
// MUST list this file as a `ruleConcreteTypeReference` offender — a caller the
// "swap the engine without touching callers" guarantee would break.
//
// It lives under `integration_test/nfr/fixtures/controls/`, NOT under `lib/`, so
// the real AC-14 sweep over `lib/` (which excludes the engine's own definition
// and the one production wiring site) never sees it — the invariant (callers
// depend on the interface) stays clean. It is never imported; the guard reads it
// as text.
//
// Test-support only — no `lib/` product code (D-7).

import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';

/// A caller bound to the concrete engine type — the AC-14 offence. A real caller
/// must depend on `MixingEngine`, never reach for `SubtractiveMixingEngine`.
final SubtractiveMixingEngine boundToConcrete = const SubtractiveMixingEngine();
