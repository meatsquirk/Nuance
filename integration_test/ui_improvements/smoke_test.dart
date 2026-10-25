// bs-20 UI-improvements acceptance-suite smoke test (ITEST-1).
//
// A never-pending proof that the stage-3 plumbing is sound before any AC test
// is written:
//   * the shells wire end to end — the real app, built through the single
//     production `buildApp` entry, renders the READOUT-2 readout regions and the
//     A11Y-1 settings toggle, reachable through the shared chrome;
//   * the pending gate is well-formed — the AC universe is exactly the nine
//     bs-20 ACs, every pending row names a real behaviour phase and matches the
//     master plan's owner, and no behaviour phase is dead/typo'd;
//   * the gate skips vs. runs correctly in both modes.
//
// None of this pends: it must stay green on every later phase, so each check is
// written to hold as the gate empties (it asserts the stable universe /
// owner-validity, never "all nine are still pending").
//
// AC ids mirror the master plan verbatim, so this file opts out of
// lowerCamelCase for the canonical owner map.
// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

/// The master plan's AC → owning-phase catalogue (AC-coverage table).
///
/// The canonical "nine ACs with real owners" the smoke test asserts the gate
/// against: [pendingACs] must agree with it for every row still pending, so a
/// mistyped or re-pointed owner is caught even as the gate empties.
const Map<String, String> _expectedOwners = {
  'AC-1': 'READOUT-4',
  'AC-2': 'READOUT-5',
  'AC-3': 'READOUT-4',
  'AC-4': 'READOUT-3',
  'AC-5': 'READOUT-6',
  'AC-6': 'A11Y-2',
  'AC-7': 'READOUT-7',
  'AC-8': 'READOUT-7',
  'AC-9': 'READOUT-8',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // Shells wired end to end
  // -------------------------------------------------------------------------

  testWidgets('smoke: the readout renders its shells through production wiring',
      (tester) async {
    // Given: the real app is built on the terracotta reading via `buildApp`.
    final harness = await givenReadoutOf(tester, warmTerracotta);

    // Then: the readout is the current screen and renders the sample.
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'smoke: the Readout must render the injected sample');

    // And: every READOUT-2 shell anchor the AC tests depend on is present and
    // findable (so an AC test fails on its Then, not on a missing widget).
    expect(harness.valueRegion, findsOneWidget, reason: 'smoke: value region');
    expect(harness.heroCard, findsOneWidget, reason: 'smoke: hero-card anchor');
    expect(harness.grayscaleSwatch, findsOneWidget,
        reason: 'smoke: grayscale swatch');
    expect(harness.displayedColorChip, findsOneWidget,
        reason: 'smoke: displayed-colour swatch');
    expect(harness.valueScale, findsOneWidget,
        reason: 'smoke: 0–10 value-scale anchor');
    expect(harness.allSpaces, findsOneWidget,
        reason: 'smoke: all-spaces region anchor');
    for (final space in ReadoutSpace.values) {
      expect(harness.spaceName(space), findsOneWidget,
          reason: 'smoke: per-space name anchor for ${space.name}');
    }

    // And: nothing was spoken just by opening the readout (no side-effecting
    // shell), and the display settings default to accessibility features off.
    expect(harness.speech.utterances, isEmpty,
        reason: 'smoke: opening the readout speaks nothing');
    expect(harness.settings.accessibilityFeatures, isFalse,
        reason: 'smoke: display settings default accessibility features off');
  });

  testWidgets('smoke: the settings panel opens to the accessibility toggle',
      (tester) async {
    // Given: the real app on the readout.
    final harness = await givenReadoutOf(tester, anySample);
    expect(harness.settingsPanel, findsNothing,
        reason: 'smoke: the panel is closed until the entry is tapped');

    // When: the painter opens the display settings from the shared chrome.
    await harness.whenOpenSettings();

    // Then: the panel is shown and carries the A11Y-1 accessibility-features
    // toggle the AC-6 test anchors on.
    expect(harness.settingsPanel, findsOneWidget,
        reason: 'smoke: the settings panel must open');
    expect(harness.accessibilityToggle, findsOneWidget,
        reason: 'smoke: the accessibility-features toggle must be present');
  });

  // -------------------------------------------------------------------------
  // The pending gate is well-formed
  // -------------------------------------------------------------------------

  test('smoke: the AC universe is exactly the nine bs-20 ACs', () {
    expect(allACs, hasLength(9),
        reason: 'smoke: bs-20 covers nine ACs');
    expect(allACs.toSet(), {
      'AC-1', 'AC-2', 'AC-3', 'AC-4', 'AC-5', 'AC-6', 'AC-7', 'AC-8', 'AC-9', //
    }, reason: 'smoke: the AC universe is AC-1..AC-9');
    expect(allACs.toSet(), hasLength(allACs.length),
        reason: 'smoke: no duplicate AC ids');
  });

  test('smoke: the canonical owner map is the nine ACs with real owners', () {
    expect(_expectedOwners.keys.toSet(), allACs.toSet(),
        reason: 'smoke: every AC has exactly one owning phase');
    for (final entry in _expectedOwners.entries) {
      expect(behaviorPhases, contains(entry.value),
          reason: 'smoke: ${entry.key} owner ${entry.value} must be a real '
              'behaviour phase');
    }
  });

  test('smoke: every pending row names a real phase and the planned owner', () {
    for (final entry in pendingACs.entries) {
      expect(allACs, contains(entry.key),
          reason: 'smoke: pending ${entry.key} must be a known bs-20 AC');
      expect(behaviorPhases, contains(entry.value),
          reason: 'smoke: pending ${entry.key} owner ${entry.value} must be a '
              'real behaviour phase');
      expect(entry.value, _expectedOwners[entry.key],
          reason: 'smoke: pending ${entry.key} owner must match the master '
              'plan (${_expectedOwners[entry.key]})');
    }
  });

  test('smoke: no behaviour phase is dead or typo\'d', () {
    // Every declared behaviour phase is either still a pending owner or has
    // completed and recorded its un-pend — so a phase that is neither (a typo,
    // or a stale phase left behind) is caught as the gate empties.
    final pendingOwners = pendingACs.values.toSet();
    for (final phase in behaviorPhases) {
      expect(
        pendingOwners.contains(phase) ||
            completedBehaviorPhases.contains(phase),
        isTrue,
        reason: 'smoke: behaviour phase $phase owns no pending AC and is not '
            'recorded complete — dead or mis-named',
      );
    }
  });

  // -------------------------------------------------------------------------
  // The gate skips vs. runs correctly in both modes
  // -------------------------------------------------------------------------

  test('smoke: every AC is delivered — the gate is empty and all ACs run',
      () {
    // READOUT-7 un-pended the last two ACs (AC-7/AC-8), so no AC remains
    // pending: every behaviour phase has landed. The gate is empty, so every AC
    // runs in both the default and the run-pending mode (asserted
    // deterministically via `forceRunPending`, independent of this run's mode).
    expect(pendingACs, isEmpty,
        reason: 'smoke: all nine bs-20 ACs are delivered; the gate is empty');
    for (final ac in allACs) {
      expect(pendingSkipReason(ac, forceRunPending: false), isNull,
          reason: 'smoke: un-pended $ac runs in the default run');
      expect(pendingSkipReason(ac, forceRunPending: true), isNull,
          reason: 'smoke: un-pended $ac runs under run-pending too');
    }

    // A non-pending id (never in the map): always runs, in either mode.
    const unpended = '__never-pending__';
    expect(pendingSkipReason(unpended, forceRunPending: false), isNull,
        reason: 'smoke: an un-pended AC always runs (default)');
    expect(pendingSkipReason(unpended, forceRunPending: true), isNull,
        reason: 'smoke: an un-pended AC always runs (run-pending)');
  });
}
