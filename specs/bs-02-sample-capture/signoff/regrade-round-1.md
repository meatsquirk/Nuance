# bs-02 Sample capture — sign-off round-1 fresh re-grade

Independent static re-grade of the **whole** bs-02 acceptance suite
(`integration_test/capture_test.dart`) on the behavior-test-check **G1–G6** rubric,
grading what the test code actually asserts. Tests were **not** run (static review).
Graded 2026-10-07 by an independent grader who did not write these tests. The
previous grid
(`behavior-test-completeness-bs-02-sample-capture.md`, last state 11×A/0×B) was used
as a reference only; every row was re-derived from the test source, the spec
(`specs/bs-02-sample-capture.feature`), the catalogue
(`MASTER_PLAN_FOR_FEATURE.md` §Test catalogue) and the live production code.

## Grade grid

| Test name | AC | Grade | Rule(s) missed | One-line justification |
|---|---|---|---|---|
| `TestAC01_Eyedropper` | AC-1 | A | — (G2/G3 n/a) | G1: `AppBar 'Capture'` + `liveViewKey` both `findsOneWidget` before the When. G4: asserts reticle **centre** vs feed **centre** on both axes at epsilon 0.5 (not mere presence); live `Stack(fit:expand)` + reticle in `Center` ⇒ correct render ≈0 px. G5 kills absent + off-centre marker. |
| `TestAC02_AreaAverage5px` | AC-2 | A | — (G3 n/a) | G1/G2: default `radiusPx==5` read through the endpoint (configured, not overridden). G4: raw sampled colour rendered back via the real `ColorScienceImpl.toSRGB`. G5: three-way distance on `SCENE_CENTRE_VARIED` (red/teal/yellow, pairwise L1 ~200–280 ≫ tol 45) kills a point read (`toDisc<toCentre`) and a wider radius (`toDisc<toOuter`). |
| `TestAC03_RadiusSelector` | AC-3 | A | — (G2 note; G3 n/a) | G1: `liveViewKey` shown. G4: exact `getSize(reticleKey)` == 8/20/44 (epsilon 0.5, square — border paints inside so layout size is exact) **and** radius-driven averaging. G5: three distinct sampled colours + directional pulls (s1→centre, s21→outer) kill an inert reticle, a radius-ignoring average and a swapped radius. Helper taps per-option `radiusOptionKey(1/5/21)` (prior placeholder judgement call resolved at SCREEN-2). |
| `TestAC09_SampleFromPhoto` | AC-9 | A | — (G3 n/a) | G1: `atP != atCentre` asserted on the fixture before the When. G2: no faked sample value — real `sampleFromPhoto` over fixture pixels. G5: `toP<45`, `toP<toCentre` (magenta vs grey), `toP<toColor(sampled, liveCamera)` (vs olive host) kill the two named wrong impls (image-centre read, live-camera read). |
| `TestAC10_ValueOnly` | AC-10 | A (limited) | — (see note; G4 residual weighed, does not drop below A) | G1: `valueOnly==false`, E21 reads exactly `'Value'`, **no** `ColorFiltered` ancestor over `liveViewKey` (paired control, G3). G3: after settle, `valueOnly==true`, `ColorFiltered` **ancestor of the feed** (`findsWidgets`), label flips to exact `'✓ Value'`. G5 kills all three catalogue Rejects (feed stays colour / label unchanged / unrelated widget greyscaled — readings are Stack siblings so the ancestor-scoped finder rejects them). `takeException` bounded. **Residual:** asserts structural `ColorFiltered` presence, not that the filter is the saturation-0 matrix — see note below. |
| `TestAC04_LockSettles` | AC-4 | A | — (G3 n/a) | G1: `lockState==auto` via endpoint + `_pumpUntilText` climbs the real counter to an explicit `find.text('SETTLING 6/12')`. G4: exact strings `'AE · AWB · AF LOCKED'` + `'STABLE 12/12'` + `lockState==locked` + `stabilityText`. G5 kills unchanged-indicator / never-settles / partial-lock. `takeException` bounded. |
| `TestAC05_SettlingWarns` | AC-5 | A | — | G1: `lockState==auto`. G3 textbook: negatives (`isStable==false`, `'STABLE 12/12'` findsNothing) at a settle point (re-assert `auto` at 6/12), paired with the counter demonstrably climbing 0→6 (reading can change) and AC-4 proving a locked reading WOULD show STABLE. G4/G5: `'SETTLING 6/12'` exact + `lockButton.enabled` (correct `TextButton` cast) kills STABLE-while-unlocked and a missing/disabled control. |
| `TestAC06_LowLightApproximate` | AC-6 | A | — (G1,G2,G3,G4,G5,G6 all met) | G1/G2: `lighting==low` + no card via `harness.source`. G4/G5 (dim half): commits (kills refusal), `warningKey`+flag (kills no-warning), `accuracy==approximate`, and `_dimRaw` ΔE00 ≈5.1 asserted **`≤8` and `>3`** (a real downgrade, not a conservative relabel). G3/G5 **control**: fresh-mounted SCENE_CARD in adequate light calibrates to `calibrated` within ΔE00 3 — pairing proves low light *specifically* downgrades. G6: the calibrated steps serve AC-6's own downgrade contrast (pre-seeded augmentation), not an AC-8 re-verification. |
| `TestAC07_DismissWarning` | AC-7 | A | — | G1: Given built through the real `commit()` on SCENE_DIM — `warningKey` + `lowLightWarning==true` + `accuracy==approximate` all asserted before the When. G3 textbook: the negative (`warningKey` findsNothing) after `whenDismissWarning`'s settle, paired with the warning-present Given (reading demonstrably changed). G4/G5: accuracy-invariance before **and** after kills *dismiss clears/upgrades the accuracy*. `takeException` bounded. |
| `TestAC08_CardCalibrates` | AC-8 | A | — (G3 n/a) | G1/G2: `referenceCardPresent==true` via `harness.source`. G4: live `'Calibrated'` label via `find.descendant(of: accuracyKey, …)` before nav, then committed `accuracy==calibrated` **and** `_deltaE00 ≤ 3` (real CIEDE2000). G5 non-vacuous: `_cardRaw` ΔE00 ≈4.6 so a relabel-only no-op commits ≈4.6 > 3 → `≤3` fails it; fixture guard pins the raw separation. `takeException` bounded. |
| `TestAC11_CommitOpensReadout` | AC-11 | A | — (G3 n/a) | G1: `haptics.confirmations==0` + `find.text('STABLE 12/12')` after a real `whenLock`. G4/G5 at grain: `framesAveraged>1` (kills single-frame by count on noisy SCENE_MULTIFRAME), mean within ΔE00 8, **exactly** `confirmations==1` (kills no-haptic + double-pulse), `AppBar 'Readout'` + `NameHeader` descendant `'Deep Olive Green'` (kills nav-without-sample / wrong name). `takeException` bounded. |
| `smoke: the assembled app boots to a Capture screen showing every region` | scaffold | A | — (G-rubric n/a) | Non-vacuous wiring smoke: asserts the Capture route (AppBar + endpoint), live view / eyedropper / reticle, every E15–E21 anchor, default readings (`SETTLING 0/12`, `Approximate`, warning hidden) and default state (`lockState==auto`, `radiusPx==5`, `currentSample` not null, `haptics==0`). Pins the anchors the AC finders rely on. |
| `no AC is still pending — every one has been un-pended` | scaffold | A | — (G-rubric n/a) | Pins `pendingACs == {}` by exact map equality **and** `isEmpty` (size pinned), so the empty-map `for` loop cannot pass vacuously. Matches the empty pending gate in `bs02/pending.dart`. |
| `every AC runs in both modes now that none is pending` | scaffold | A | — (G-rubric n/a) | Asserts `pendingSkipReason` returns null (runs) for AC-10 in **both** `forceRunPending` modes, plus AC-1/2/3/9 and an unmapped id — pins the gate opens every AC. |
| `SCENE_CENTRE_VARIED has three distinct colours …` | scaffold | A | — (G-rubric n/a) | Fixture-soundness guard for AC-2/AC-3: asserts centre ≠ 5 px ring ≠ outer band at the exact coordinates the AC tests read, so the sampling controls cannot silently go vacuous. |
| `PHOTO_SWATCH point P differs from the image centre …` | scaffold | A | — (G-rubric n/a) | Fixture-soundness guard for AC-9: `atP != atCentre`, so the wrong-point discriminator is real. |
| `FakeCaptureSource exposes ground truth and counts each frame read` | scaffold | A | — (G-rubric n/a) | Verifies the fake's two affordances the Thens depend on: `groundTruth` matches the scene and `framesRead == frames.length` (count is honest for AC-11's multi-frame claim). |
| `FakeHaptics counts confirmation pulses` | scaffold | A | — (G-rubric n/a) | Verifies the haptics sink counts 0→1 on `confirm()`, underpinning AC-11's `confirmations==1`. |
| `SCENE_CARD and SCENE_DIM read clearly off their ground truth …` | scaffold | A | — (G-rubric n/a) | Guards AC-6/AC-8 non-vacuity: raw centre pixel sits L1 sRGB > 20 off ground truth, so a no-op accuracy/calibration label cannot pass the ΔE Thens. |

## Grade counts

**19×A, 0×B.** (11 AC tests + 8 harness/scaffold tests, all A. AC-10 is A but carries
a documented, non-downgrading residual — see note.)

## Differences from the previous grid

**None.** Every AC row matches the previous grid's final (SCREEN-3) state of 11×A/0×B,
and all 8 harness/scaffold tests are A. No upgrades and no downgrades this round, so no
named-rule justification for a change is required. AC-6's earlier `B pending CAPTURE-5`
was already resolved to A at CAPTURE-5 (the calibrated-vs-approximate control landed and
discriminates); it holds A here on an independent read (G1,G2,G3,G4,G5,G6 all met).

## Note — AC-10 structural `ColorFiltered` assertion (weighed, stays A)

AC-10's positive Then asserts a `ColorFiltered` **ancestor of `liveViewKey`** exists
(`findsWidgets`) plus the exact `'✓ Value'` label; it does **not** assert the filter is
the saturation-0 `_grayscaleMatrix`. I weighed this as a possible **G4** miss
("assert the raw observable the step names, not a derived one; structural-only where a
value is available") and concluded it does **not** drop below A, for three concrete
reasons:

1. **The feed is a flat-colour placeholder** (`ColoredBox(Color(0xFF3A3A3A))`), so a
   pixel-level grayscale check is impossible and meaningless now — a correct saturation-0
   matrix leaves a flat grey unchanged.
2. **The only machine-checkable value assertion available over-fits.** Flutter's
   `ColorFilter` is opaque — you cannot read its matrix back or apply it to a probe colour
   through the public API; the one available value check is `colorFilter ==
   ColorFilter.matrix(<exact coeffs>)`. Asserting that would pin the Rec.709 luma
   coefficients and would **false-reject a valid alternative saturation-0 matrix**
   (Rec.601, equal-weight, etc.), which the spec's "value-only grayscale" permits.
3. **No plausible or catalogued wrong impl survives.** The ancestor-scoped finder kills
   every Reject the catalogue names (feed stays colour / label unchanged / unrelated
   widget greyscaled — the overlaid readings are Stack *siblings* of the wrapped feed, so
   an unrelated `ColorFiltered` cannot satisfy it). The one impl it technically misses — a
   deliberately identity/no-op `ColorFiltered` wrapped around the feed — is not a plausible
   implementation and is only catchable via the over-fitting assertion in (2).

**Tightening opportunity (carried, not a defect):** once the feed renders real frames,
assert the grayscale effect at the pixel/output grain (or, if `ColorFilter` gains an
introspectable form, that it is a saturation-0 matrix). Until then the structural
ancestor-over-feed finder is the correct grain.

## Minor observations (do not affect any grade)

- `fakes/fake_haptics.dart` and `fakes/fake_speech.dart` doc comments reference `AC-12`
  and `AC-8` — these are copied-over bs-01 AC numbers, not bs-02 ACs. Comment text only;
  no assertion is affected.

## VERDICT

**ALL A** — 19×A, 0×B. AC-10 carries one documented, non-downgrading residual (structural
`ColorFiltered` assertion vs the saturation-0 matrix), judged a legitimate A given the
flat-placeholder feed and the over-fit risk of the only available value assertion;
flagged as a post-real-frames tightening opportunity.
