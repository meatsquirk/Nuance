# Sign-off packet — bs-20 UI improvements — Round 1

**Feature:** User interface improvements (readout re-composition + accessibility-features setting)
**Spec:** [bs-20-ui-improvements.feature](../../bs-20-ui-improvements.feature)
**At code:** `46ea352` (branch `feat/bs-20-ui-improvements`)
**Prepared:** 2026-10-26 (SIGNOFF-1)
**Decision:** ⏸ Awaiting sign-off — `/feature-next-phase --signoff bs-20-ui-improvements approved | changes "<items>"`

All 9 ACs are delivered, un-pended and green; the pending gate is empty; no augmentation row is open;
a fresh independent whole-suite re-grade is **9 A / 0 B**. The full cross-feature regression is green but
for three pre-existing off-lane flakes owned by other features (listed below, all reproduce at merge-base).

---

## 1. Per-AC result

Suite: `integration_test/ui_improvements/` (real `ReadoutScreen` / `DisplaySettingsScreen` pumped through
production wiring `buildApp` + `DisplayScope`). Run per-file under `flutter-tester` (the whole dir won't
launch at once — house gotcha). Default mode == run-pending mode (nothing pending).

| AC | Scenario | Test | Behavior phase | Result |
|---|---|---|---|---|
| AC-1 | Lightness shown in a prominent bordered card (largest reading) | `readout_test.dart` › AC-1 hero card | READOUT-4 | ✅ green |
| AC-2 | Munsell value on a 0–10 scale with the sample marked | `readout_test.dart` › AC-2 value scale | READOUT-5 | ✅ green |
| AC-3 | True-colour swatch as large as the grayscale swatch | `readout_test.dart` › AC-3 equal swatches | READOUT-4 | ✅ green |
| AC-4 | Every colour space shown together, no selector | `readout_test.dart` › AC-4 all spaces | READOUT-3 | ✅ green |
| AC-5 | Open a space's name for a fuller definition + example | `readout_test.dart` › AC-5 definitions | READOUT-6 | ✅ green |
| AC-6 | Accessibility features off by default | `settings_test.dart` › AC-6 default off | A11Y-2 | ✅ green |
| AC-7 | With accessibility off, Speak hidden | `settings_test.dart` › AC-7 Speak hidden | READOUT-7 | ✅ green |
| AC-8 | Turning accessibility on reveals Speak | `settings_test.dart` › AC-8 Speak shown | READOUT-7 | ✅ green |
| AC-9 | Readout uses "Color" not "Colour" | `readout_test.dart` › AC-9 Color spelling | READOUT-8 | ✅ green |

**bs-20 suite counts (at `46ea352`):** `readout_test` 8/8, `settings_test` 5/5, `smoke_test` 9/9 — in
**both** default and `--dart-define=BS20_RUN_PENDING=true` modes (identical, nothing pending). 22 checks, 0 fail.

---

## 2. Verification

- **Unit suite:** `flutter test test/ --coverage` → **1820 pass / 0 fail / 0 error** (machine reporter;
  prior phases cited ~1664 via the default reporter's grouped count — same green suite).
- **Coverage gate:** **PASS — N/A for this phase.** SIGNOFF-1 changes no `lib/` code (packet + plans only),
  so there are no touched source files to gate. Behavior-phase coverage was 100% on every touched file at
  its phase (see the ledger / module Results).
- **Full cross-feature regression (22 integration files, per-file under flutter-tester):** 20 files fully
  green. The two non-green files carry only the three pre-existing off-lane flakes below; no new failure,
  and none reference any bs-20 file (`lib/readout/`, `lib/display/`, `ColorChip`).
- **bs-11 accessibility-conformance:** **21/21 green** — the regression READOUT-9 fixed (AC-4 48 dp space-name
  tap target; AC-7 eyes-free reconcile to accessibility-on) stays fixed.
- **Grade gate:** fresh independent subagent re-grade of the whole (now un-pended) suite → **9 A / 0 B**,
  no downgrades from the prior grid.
  Grid: [`behavior-test-completeness-bs-20-ui-improvements.md`](../behavior-test-completeness-bs-20-ui-improvements.md)
  (SIGNOFF-1 whole-suite re-grade appended).

---

## 3. Augmentations made

One pre-seeded augmentation only — `TestAC07_SpeakHidden` ("absent while off" could pass vacuously).
**Closed in ITEST-3** (not in a behavior phase): AC-7 carries the on→shown control and AC-8 the off→hidden
control in-test, so the pair is non-vacuous; READOUT-7 made no test change beyond turning both green.
**No augmentation row remains open.**

---

## 4. Phases closed by user acceptance (with gaps)

None. Every AC is closed by a passing acceptance + grade gate, not by acceptance-despite-gap.

## 5. Non-A grades accepted

None. Every row graded A.

---

## 6. Gates

| Gate | Decision | Status |
|---|---|---|
| G-1 | Approve the spec | ✅ Resolved 2026-10-24 — Matt Quirk |
| G-2 | Approve the acceptance tests (ITEST-4 packet) | ✅ Resolved 2026-10-25 — Matt Quirk (keep A11Y-2; bs-01 AC-5/AC-8 reconciliation confirmed) |
| G-3 | Hiding Speak by default vs bs-11 conformance | ✅ Resolved 2026-10-25 — Matt Quirk. Corrected: default-hidden Speak **did** red bs-11 AC-7 (and AC-4's 48 dp, unrelated); owner chose remediate-not-reverse → READOUT-9 ran bs-11 conformance accessibility-on + fixed the 48 dp target (see D-6) |

No open or recorded-but-unresolved gate.

---

## 7. Open Known flakes (carried — not bs-20-caused)

All three are in the master plan's Known-flakes table, owned by other features, and reproduce at
merge-base `c00422f` (off-lane source-scan / native-flutter-tester ACs). They do **not** block this sign-off.

| Test | Symptom this run | Owner |
|---|---|---|
| bs-06 `palette_test` AC-3 (provenance legend explains four tiers) | off-lane flutter-tester error | bs-06 |
| bs-06 `palette_test` AC-5 (selecting a palette re-points recipe search) | off-lane flutter-tester error | bs-06 |
| bs-07 `self_assessment_test` AC-4 (prior clinical diagnosis seeds the prior) | off-lane flutter-tester error | bs-07 |

(`bs-08 display_test` AC-9, also in the table, was **green** this run — intermittent; left in the table.)

---

## 8. Known gaps & deferred items

- **D-1 (advisory, carried):** bs-19 (live camera capture) is still unmerged; it and bs-20's READOUT
  phases both edit `lib/app/build_app.dart` (READOUT-9 itself touched `space_definition.dart`, not
  `build_app.dart`). A merge-order conflict between the two is possible — mostly disjoint (camera vs
  readout/settings). Not a bs-20 defect.
- **Deferred wireframe element:** the two switchable readout layouts ("Value-first" vs "Spec sheet") were
  dropped by the owner (2026-10-24); bs-20 ships one merged layout. See
  [bs-20-ui-improvements.deferred.md](../../bs-20-ui-improvements.deferred.md). Not to be reintroduced.
- **P3 — feature intentionally left OPEN:** the spec header keeps bs-20 open for further small enhancement
  batches (added later via a plan upgrade). Signing off Round 1 closes *this* batch (9 ACs), not the feature
  file.
- **Open owner confirmation (non-blocking):** the swatch "APPROX." caption is kept always-visible; owner may
  later flip it to accessibility-gated (deferred file). No AC depends on this.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

Toolchain: `export PATH="/Users/matthew.quirk/development/flutter/bin:$PATH"` (no `timeout` on macOS).

**A. Run the acceptance suite yourself (fastest, deterministic):**

```bash
cd /Users/matthew.quirk/Nuance
flutter test -d flutter-tester integration_test/ui_improvements/readout_test.dart
flutter test -d flutter-tester integration_test/ui_improvements/settings_test.dart
flutter test -d flutter-tester integration_test/ui_improvements/smoke_test.dart
```

Each test pumps the **real** app via `buildApp` and asserts the exact Then through widget finders, so a
green run is the Rule working on the shipped widgets:

| Rule (spec) | What the reviewer sees proven |
|---|---|
| Value in a prominent bordered card | AC-1: Lightness 58 sits in a bordered ancestor **and** is the strictly largest reading paragraph on the readout. |
| Munsell value on a labelled 0–10 scale | AC-2: all eleven 0..10 step labels present; exactly one selected `Semantics` step marks the sample's value (colour-independent cue). |
| Displayed & grayscale swatches equal size | AC-3: `tester.getSize` of both swatch boxes is equal (48×48). |
| All four spaces at once, no selector | AC-4: CIELCh, Munsell, sRGB/hex and CIELAB all present simultaneously in the all-spaces region; `SpaceSelector` findsNothing. |
| A space name opens a fuller definition + example | AC-5: each of the four space names is an openable label; tapping reveals a plain-language definition carrying an example cue. |
| Accessibility features off by default | AC-6: the settings toggle is present and reads `false` on a fresh app. |
| Speak revealed only when accessibility on | AC-7/AC-8: Speak is absent while off and appears once the flag is turned on (both directions asserted as a pair). |
| Copy uses "Color" | AC-9: no "colou" substring anywhere in the readout Scaffold copy; "Color" is actually present. |

**B. See it live (optional demo launcher):**

```bash
cd /Users/matthew.quirk/Nuance
flutter run            # pick an iOS simulator or Chrome; open the Readout screen
```

On the Readout screen: the Lightness value is the hero card; the 0–10 value strip marks the sample; the
displayed and grayscale swatches are the same size; CIELCh / Munsell / sRGB / CIELAB are all listed at once
with no space-selector button; tapping a space **name** opens its definition. Open Settings → Accessibility
features is **off**, and the "Speak this readout" control is hidden on the readout. Turn Accessibility
features **on** → the Speak control appears. All user-facing copy reads "Color".

> Screenshots were not baked into this packet (the ACs are structural and fully asserted by the finder-based
> tests above). If you'd like a captured sim walkthrough or specific screenshots before deciding, say so and
> they'll be produced.

---

## 10. Cost (headline)

Full per-AC breakdown: [`cost-per-ac-round-1.md`](cost-per-ac-round-1.md) (19 ledger sessions, including
this SIGNOFF-1 session).

- **Feature total:** **$112.25** / **118,858,518 tokens** — input $0.01, cache write $32.83, cache read
  $57.21, output $22.19 (API list rates as of 2026-09-25).
- **Time:** Σ active **5h 53m** (Σ wall **47h 07m**); first start **2026-10-23 05:35 EDT** → last end
  **2026-10-26 00:03 EDT**.
- **Fully loaded per AC:** ~$12.47 each (even 1/9 share of all shared work; sums to the feature total).
  No AC carries direct cost in the ledger — the behavior phases' *Target AC* live in the module dashboards,
  so every phase's cost is attributed as shared (scaffold / shells / acceptance tests / sign-off).

---

## 11. Scorecard

Summary scorecard (one page): **https://claude.ai/artifact/E7Ar4N3JpQNpsXWAxrDqus**
