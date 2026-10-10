# Sign-off packet — Mixing recipes (bs-04) — Round 1

**Feature:** bs-04-mixing-recipes · **Spec:** [bs-04-mixing-recipes.feature](../../bs-04-mixing-recipes.feature)
**Prepared:** 2026-10-09 (SIGNOFF-1) · **At code:** `feat/bs-04-mixing-recipes` @ `ca877e4` (sign-off commit stamped on decision)
**Decision:** ⏸ Awaiting — a human approves or requests changes. The agent never approves.

All 12 acceptance criteria are coded, un-pended and green; the full cross-feature regression is green; a
fresh independent full-suite grade grid is **24×A, 0 below A**. This packet is the evidence for the decision.

To record the decision:
`/feature-next-phase --signoff bs-04-mixing-recipes approved | changes "<items>"`

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 17/17 phases ✅ Done (RECIPE/ENGINE/SCREEN/ITEST modules all done) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-12 all ✅ |
| Pending list empty | ✅ `integration_test/bs04/pending.dart` `pendingACs = {}` |
| No open row in ITEST *Test augmentations* | ✅ all 7 augmentation rows ✅ Closed (TestAC05/06/07/08/10/11/12) |
| Fresh whole-suite grade grid all A | ✅ 24×A / 0 below A (fresh-context grader, this session) |
| No open decision/dependency gates | ✅ G-1…G-6 all ✅ Resolved |

---

## 2. Full verification (primary checkout, this session)

Toolchain: Flutter 3.47.6 stable; iOS sim iPhone 17 `5AB9D06D…51685`; integration run under the verify lock.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found** (clean) |
| Unit + coverage | `flutter test --coverage` | **635 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all **16** touched bs-04 `lib/` files |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid>` | **91 passed, 0 failed, 0 pending** (capture 20 · comparison 27 · bs-01 harness 6 + readout 13 · recipes 25) |
| Acceptance — bs-04 (run-pending) | `flutter test integration_test/recipes_test.dart -d <udid> --dart-define=BS04_RUN_PENDING=true` | **25 passed, 0 failed, 0 skipped** — identical to default (nothing pending) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **24×A, 0 below A — PASS** |

Machine-readable results produced on the first run (`flutter test --machine`): unit, integration default,
integration run-pending. The summary page (§8) is built from them.

The 16 touched `lib/` files at 100%: `app/build_app.dart`, `app/router.dart`, `domain/paint.dart`,
`recipes/engine/{mixing_engine,subtractive_engine}.dart`, `recipes/{palette,palette_source,recipe_controller,
recipe_read_endpoint,recipe_speech,recipe_state,recipes_screen,target_region,controls_region,
recipe_list_region,gamut_banner}.dart`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green; ΔE00 assertions are graded against the harness's
**independent** `referenceDeltaE00` (CIEDE2000, Sharma–Wu–Dalal), never the product metric.

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | Chooses a saved sample as the target | `TestAC01_ChooseSavedTarget` | RECIPE-3 | ✅ green |
| AC-2 | Manual target; impossible value refused | `TestAC02_ManualTargetRefused` | RECIPE-3 | ✅ green |
| AC-3 | Recipes use only the selected palette | `TestAC03_PaletteConstrained` | ENGINE-2 | ✅ green |
| AC-4 | Top 3–5 recipes with parts + predicted colour | `TestAC04_TopRecipes` | ENGINE-2 | ✅ green |
| AC-5 | Close recipe states small ΔE + plain verdict | `TestAC05_CloseVerdict` | ENGINE-3 | ✅ green |
| AC-6 | Cleaner 2-paint ranks above muddier mix at ~ΔE | `TestAC06_PreferFewer` | ENGINE-3 | ✅ green |
| AC-7 | Component < ~2% → "a touch of" + technique note | `TestAC07_TraceTouchOf` | ENGINE-4 | ✅ green |
| AC-8 | Complementary-crossing mix flagged muddying | `TestAC08_MuddyingFlag` | ENGINE-4 | ✅ green |
| AC-9 | Out-of-gamut target, nearest not a match | `TestAC09_OutOfGamut` | ENGINE-5 | ✅ green |
| AC-10 | View the predicted dry colour | `TestAC10_WetDry` | ENGINE-6 | ✅ green |
| AC-11 | Hear the target spoken (name + L, C, h) | `TestAC11_SpeakTarget` | RECIPE-4 | ✅ green |
| AC-12 | Hear a recipe spoken (each paint + parts) | `TestAC12_SpeakRecipe` | RECIPE-4 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-04-mixing-recipes.md` — fresh SIGNOFF-1 full-suite re-grade
appended: **24×A (12 AC tests + 12 scaffold/fixture/reference guards), 0 below A**. The fresh grader
independently recomputed the Deep-Olive polar coordinates, the Vivid-Turquoise unreachability geometry and the
five Sharma CIEDE2000 reference pairs, and confirmed `referenceDeltaE00` imports no product metric.

---

## 4. Augmentations made (all closed)

Each limited AC test was strengthened by the behaviour phase that produced the real engine output, so the
test discriminates against the pre-phase code (ITEST *Test augmentations* table, all ✅ Closed):

- **TestAC05** (ENGINE-3) — a farther recipe (ΔE00 ≈ 20.5 → "far off") asserts the verdict *tracks* distance; a constant string fails.
- **TestAC06** (ENGINE-3) — the decisive near-tie the retargeted solve produces: 2-paint {Yellow Ochre, Ivory Black} ranks **above** the marginally-lower-ΔE 3-paint mix, so only the prefer-fewer tie-break (D-8) passes.
- **TestAC07** (ENGINE-4) — a genuine ≈1.4% Titanium White trace renders "a touch of" + note and **no** measured %.
- **TestAC08** (ENGINE-4) — a known Yellow Ochre + Ultramarine crossing is flagged; a known non-crossing mix is not.
- **TestAC10** (ENGINE-6) — the dry prediction is asserted **darker and less saturated** (the drying direction), not merely different.
- **TestAC11** (RECIPE-4) — labelled substrings `Lightness <L>` / `chroma <C>` / `hue <h> degrees`, so a label swap fails.
- **TestAC12** (RECIPE-4) — per-component parts quantity (`<name> <n> part(s)` / `a touch of <name>`), so a paint named without its parts fails.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A; nothing was closed by user acceptance of a gap.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1…G-6 all ✅ Resolved (spec approval; acceptance-test review G-2; foundation dependency G-3;
spec-data/engine reconciliation G-4; engine reachability G-5 → retarget; retargeted-test review G-6). No open
or recorded-but-unresolved gates.

**Open known flakes** (carried from bs-01/02/03 foundation, mitigated; neither observed this session):

| Test | Symptom | Mitigation |
|---|---|---|
| coverage_gate const-constructor line | `flutter test --coverage` can intermittently record a const-folded constructor line as uncovered | re-run once; green on re-run ⇒ ignore. Did not occur this session (gate PASS first run). |
| integration without `-d <udid>` | a device-less run executes zero tests and still exits 0 (false green) | always pass `-d <booted-udid>`. Done — sim booted, 91 tests actually ran. |

**Known gaps / deferred by design (not defects):**

- **Deep Olive retarget (G-5(a)).** `SAMPLE_DEEP_OLIVE` was retargeted from the spec's illustrative L 42 / C 28 / h 108 to a reachable olive **L 42 / C 24 / h 93** (a\* −8.65 → −1.26), because the earthy `PALETTE_MY_PAINTS` has no green/phthalo pigment and reached the original only to ΔE00 ≈ 9.31. The v1 engine reaches the retarget to ΔE00 ≈ 3.34 (≤ 5). The spec's pinned L/C/h are **illustrative** (G-4); the ACs assert behavioural properties (D-13). The spec text itself still shows the original numbers — approving sign-off accepts the retargeted fixture as the acceptance contract.
- **Measured-pigment mixing engine** (`docs/custom-mixing-engine-design.md`) — deferred SI-D3 upgrade behind the same `MixingEngine` interface; v1 ships the documented subtractive KM-class forward+inverse (D-2).
- **Persistent palette store** — bs-04 injects a minimal `PaletteSource`/`InMemoryPaletteSource` (D-5); bs-06 supplies the persistent store behind the same interface later.
- **Static technique notes** — the "a touch of" technique note is a static string (D-12); an LLM-sourced build-time pipeline is a later data concern (offline-at-runtime).
- **AC-8 discriminator residual** (noted by both the ENGINE-4 and the fresh SIGNOFF-1 grader, **not** docked): for a green target no cool-only non-crossing mix appears in the ranked top-5, so the clean control is warm-only; a narrow wrong impl "flag iff contains Ultramarine" would survive. G5 is still met (the test rejects constant-true/false/arbitrary/unimplemented flags). The physical muddying logic is unit-tested directly.

---

## 7. Cost and tokens

From the *Token usage* ledger (28 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 212,522,560 tokens — input 3,156 · cache write 5,349,382 · cache read 205,833,248 · output 1,336,774.
- **Cost (API list rates, 2026-09-25):** **$185.08** (cache write $48.73 · cache read $102.92 · output $33.42 · input $0.02).
- **Span:** 2026-10-08 11:52 EDT → 2026-10-09 21:47 EDT — **Σ active 9h 14m** (Σ wall 20h 05m).
- **Per-AC (fully loaded, sums to the feature total):** shared work $7.99/AC; behaviour direct $5.37 (AC-5/6) … $10.25 (AC-9); fully loaded ≈ $13–$18 per AC (mean ≈ $15.4).

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/RR385TL1rENXkrVoNEbLsn** — "Mixing Recipes Sign-off" scorecard (12 ACs, verification
headline, augmentations, cost). Private to the owner; share from the page's Share menu for other reviewers.
Its headline (unit 635 · coverage 16/16 · integration 91 · 24×A) matches this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the repo root, then open **Recipes** (the Readout screen's
"Find mixing recipes" handoff, or the router's recipes route). The screen regions are E22 target selector,
E23 speak-target, E24 wet/dry toggle, E25 speak-recipe, the recipe-list body, and the OUT-OF-GAMUT banner.
To watch the whole contract run green end to end:
`flutter test integration_test/recipes_test.dart -d <booted-udid>` (25 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| Target is a saved sample or manual colour | Open the E22 target selector; pick **Deep Olive Green**. Then open manual entry and type **Lightness 140**. | Target becomes "Deep Olive Green" at its L/C/h. L 140 is refused as out of range and the previous target is kept (no overwrite). |
| Recipes solved only against the selected palette | With "My paints" selected, read the recipe list. | Every recipe lists only Titanium White / Yellow Ochre / Ivory Black / Ultramarine Blue / Venetian Red — no paint from outside the palette. |
| Top few candidates with parts + predicted colour | Read the list for Deep Olive Green. | 3–5 recipes, each with its paints as parts-by-volume and a predicted colour swatch. |
| Each recipe states its distance + plain verdict | Read the top recipe. | ΔE00 shown plus a plain verdict from the band scale: *an almost exact match* (<1), **very close** (<5), *close* (<10), *in the ballpark* (<20), *far off* (≥20). The top Deep-Olive mix is ΔE00 ≈ 3.34 → "very close". |
| Prefers fewer paints | Compare the top two Deep-Olive recipes. | The cleaner 2-paint {Yellow Ochre, Ivory Black} mix ranks **above** a 3-paint mix even at a marginally lower ΔE — the prefer-fewer tie-break. |
| Trace = "a touch of" | Find a recipe with a sub-2% Titanium White component (e.g. the Deep Umber target). | That component reads "a touch of Titanium White" with a technique note, **not** a measured percentage. |
| Muddying flagged | Find a recipe spanning a complementary pair (Yellow Ochre + Ultramarine). | The card shows **"Liable to muddy"**; a non-crossing mix does not. |
| Out-of-gamut, no false recipe | Set the target to **Vivid Turquoise** (unreachable from the earthy palette). | The **OUT OF GAMUT** banner appears ("…the recipes below are the nearest possible, not a match"); offered mixes are labelled nearest, never "very close"/match. |
| Wet or dry | With an oil recipe shown, toggle **E24** wet→dry (oil after 7 days). | The predicted colour shifts **darker and less saturated** (the drying direction). |
| Target and recipe spoken | Tap **E23** then **E25**. | One utterance states the target name + "Lightness …, chroma …, hue … degrees"; one utterance states each paint and its parts ("… 6 parts", "a touch of …"). |

A reviewer likely to ask "show me it fails honestly" can run `BS04_RUN_PENDING=true` (no change now — nothing
pending) or revert the G-5 retarget and re-run: the engine-backed reachability guard and AC-6's prefer-fewer
tie-break both go red, confirming the tests discriminate.
