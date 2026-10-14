// bs-12 non-functional-requirements acceptance suite (ITEST-1..3).
//
// ITEST-1 lands the harness scaffold here: a never-pending smoke test proving
// the shells wire end to end — the real app (`buildApp`) launches into each
// core flow, and every reusable NFR guard / harness returns a populated result
// — plus guard tests so the scaffold cannot pass vacuously (the pending map
// must cover exactly the 16 automatable ACs, each owned by a real behaviour
// phase, and the fixtures / authority lists must carry what their ACs assume).
//
// ITEST-2 and ITEST-3 register one *pending* `acTestWidgets` per AC in this
// file; the behaviour phases (GUARD-3..6, QUALITY-2..5) un-pend each by deleting
// its row in `bs12/pending.dart`. Default
// `flutter test integration_test/bs12/nfr_test.dart -d <booted-udid>` skips
// pending ACs; `--dart-define=BS12_RUN_PENDING=true` runs them (the red
// baseline). A booted `-d` is mandatory — without it the run executes zero
// tests and exits 0 (a false green).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/recipes/gamut_banner.dart';

import 'nfr_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The home screen `buildApp` opens on for each core flow (buildApp's entry
  // precedence). The smoke test asserts each launch reaches its screen, proving
  // the one assembly path enters every flow the NFR guards sweep.
  final flowHome = <NfrFlow, Type>{
    NfrFlow.readout: ReadoutScreen,
    NfrFlow.capture: CaptureHomeScreen,
    NfrFlow.comparison: ComparisonHomeScreen,
    NfrFlow.recipes: RecipesHomeScreen,
    NfrFlow.palette: PaletteHomeScreen,
  };

  for (final flow in NfrFlow.values) {
    testWidgets(
      'smoke: buildApp launches into the ${flow.name} flow',
      (tester) async {
        final harness = await givenTheApp(tester, flow: flow);

        // The one production assembly reaches this flow's screen.
        expect(
          find.byType(flowHome[flow]!),
          findsOneWidget,
          reason: 'buildApp must open the ${flow.name} flow on '
              '${flowHome[flow]}',
        );
        // A real MaterialApp was assembled (the full app, not a bare screen),
        // and the faked platform sinks are inert until a flow drives them.
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(harness.flow, flow);
        expect(harness.speech.utterances, isEmpty);
        expect(harness.haptics.confirmations, 0);
      },
    );
  }

  group('the reusable guards and harnesses are wired', () {
    testWidgets('offline guard runs a body and refuses any network touch',
        (tester) async {
      final sink = NetworkAttemptSink();

      // A body that touches nothing completes and returns its value.
      final value = await runUnderNetworkBlock(() async => 'done', sink: sink);
      expect(value, 'done');

      // A body that opens an HttpClient is refused, fast and visibly.
      await expectLater(
        runUnderNetworkBlock(() async => HttpClient(), sink: sink),
        throwsA(isA<NetworkBlockedException>()),
      );

      // GUARD-3 wired the increment: the refused attempt was recorded on the
      // sink before it threw, so "zero attempts" across a flow is a meaningful
      // claim (the counter counts).
      expect(sink.attempts, 1);
    });

    test('source guard exposes every rule scan over populated authorities', () {
      // All five rule scans are real and hold over the shipped product:
      // forbiddenDependencies / offDeviceSenders (GUARD-4), conversion / deltaE /
      // platform (GUARD-6). An empty list means "invariant holds" over lib/.
      expect(conversionOffenders(), isEmpty);
      expect(deltaEOffenders(), isEmpty);
      expect(platformOffenders(), isEmpty);
      expect(forbiddenDependencies(), isEmpty);
      expect(offDeviceSenders(), isEmpty);

      // The authorities and allow-lists the scans judge against are configured
      // — an empty offender list means "invariant holds", not "nothing to
      // check".
      expect(conversionAuthorityFiles, contains('lib/color_science/conversions.dart'));
      expect(conversionAuthorityFiles.length, 3);
      expect(deltaEAuthorityFiles, contains('lib/compare/difference.dart'));
      expect(nativeCaptureSeam, 'lib/capture/source/');
      expect(forbiddenDependencyNames, contains('firebase_analytics'));
      expect(forbiddenDependencyNames, contains('sentry'));
    });

    test('the GUARD-6 conversion exemption is load-bearing, not vacuous', () {
      // Re-scoped D-4 (Matt Quirk 2026-10-14): the two domain pipelines are
      // sanctioned authorities for conversions. Prove the exemption is doing real
      // work — each sanctioned file genuinely carries the CIE conversion maths the
      // scan detects, yet the full lib/ sweep is empty, so the clean result is an
      // *exclusion*, not a "nothing to find" accident.
      expect(sanctionedDomainConversionFiles.length, 2);
      final conversionMarker = RegExp(r'0\.008856|7\.787|0\.95047|1\.08883');
      for (final path in sanctionedDomainConversionFiles) {
        final src = maskCommentsAndStrings(File(path).readAsStringSync());
        expect(
          conversionMarker.hasMatch(src),
          isTrue,
          reason: '$path must carry real conversion maths (in code, not a '
              'comment/string) for its exemption to be load-bearing',
        );
      }
      // Both sanctioned files carry conversion maths, yet the real lib/ sweep
      // reports zero offenders — the allow-list is the only thing keeping them
      // out, and the control fixture (same markers, not sanctioned) is still
      // flagged (AC-16). So the exemption discriminates; it does not blanket-mute.
      expect(conversionOffenders(), isEmpty);
      expect(
        conversionOffenders(roots: const [kControlFixturesRoot])
            .any((o) => o.path.contains('control_stray_colour_math')),
        isTrue,
      );
    });

    test('the GUARD-4 source scans exclude comments / strings and parse the lock',
        () {
      // maskCommentsAndStrings blanks every comment and string literal (newlines
      // kept), so a doc comment or log string naming an egress API is never a
      // false off-device offender — only real code is matched.
      const src = '''
// HttpClient() named in a line comment is not a call.
/* HttpClient() in a
   block comment spanning lines */
final a = 'HttpClient() in a single-quoted string';
final b = "and a double-quoted one";
final c = \'\'\'HttpClient() in a triple-quoted string\'\'\';
final d = 'escaped quote \\' then HttpClient()';
final r = r'raw HttpClient()';
void realCall() => HttpClient();''';
      final masked = maskCommentsAndStrings(src);
      // Every commented / quoted mention is blanked…
      expect('HttpClient'.allMatches(masked).length, 1,
          reason: 'only the one real HttpClient() call survives masking');
      // …newlines are preserved, so line numbers are unchanged.
      expect('\n'.allMatches(masked).length, '\n'.allMatches(src).length);

      // parseLockPackageNames reads the top-level `packages:` keys only.
      const lock = '''
# Generated by pub
packages:
  provider:
    dependency: "direct main"
    source: hosted
  firebase_analytics:
    dependency: transitive
sdks:
  dart: ">=3.0.0 <4.0.0"''';
      final names = parseLockPackageNames(lock);
      expect(names, containsAll(<String>{'provider', 'firebase_analytics'}));
      expect(names.contains('dependency'), isFalse,
          reason: 'nested keys are not package names');
      expect(names.contains('dart'), isFalse,
          reason: 'the sdks block is not the packages block');
      // A missing lockfile yields no resolved names (so the sweep is empty).
      expect(resolvedDependencyNames(lockPath: 'does_not_exist.lock'), isEmpty);
    });

    test('accuracy harness grades the seed set within bound by the reference ΔE',
        () {
      const harness = AccuracyHarness();
      final grades = harness.gradeAll();

      // One populated grade per seed sample, each within its condition's bound.
      expect(grades.length, syntheticAccuracySet.length);
      expect(grades.length, 3);
      for (final grade in grades) {
        expect(
          grade.withinBound,
          isTrue,
          reason: '${grade.sampleId} seed must sit inside ΔE00 '
              '${grade.maxDeltaE} (was ${grade.deltaE})',
        );
      }
      expect(
        grades.map((g) => g.sampleId).toSet(),
        syntheticAccuracySet.map((s) => s.id).toSet(),
      );

      // The seed set covers all three accuracy conditions.
      expect(
        syntheticAccuracySet.map((s) => s.condition).toSet(),
        AccuracyCondition.values.toSet(),
      );
    });

    test('perf harness measures a body against its budget', () async {
      const harness = PerfHarness();
      final probe = await harness.measure(
        'smoke',
        kCaptureSettleCiBudget,
        () async {},
      );
      expect(probe.label, 'smoke');
      expect(probe.budget, kCaptureSettleCiBudget);
      expect(probe.withinBudget, isTrue);

      // The AC-4 candidate-count bound discriminates 3–5 from outside it.
      expect(isTopCandidateCount(kMinTopCandidates), isTrue);
      expect(isTopCandidateCount(kMaxTopCandidates), isTrue);
      expect(isTopCandidateCount(kMinTopCandidates - 1), isFalse);
      expect(isTopCandidateCount(kMaxTopCandidates + 1), isFalse);
    });

    test('synthetic gamut targets carry one in-gamut control and one out', () {
      final inGamut = syntheticGamutTargets.where((t) => t.inGamut);
      final outOfGamut = syntheticGamutTargets.where((t) => !t.inGamut);
      expect(inGamut.length, 1, reason: 'AC-13 positive control');
      expect(outOfGamut.length, 1, reason: 'AC-13 out-of-gamut target');
    });

    testWidgets('swap harness pumps the real app through the injection seam',
        (tester) async {
      // Both swap seams default to the shipped implementations; GUARD-5 passes
      // recording alternates. ITEST-1 only proves the real app assembles through
      // the helper.
      await pumpAppWithSwaps(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // ITEST-2 — AC tests: the invariant guards (pending)
  //
  // AC-1,2,6 (offline / privacy over the real flows) grade A: each sweeps every
  // core flow under the network block and is discriminated by the counting
  // control (a deliberate touch must be recorded + refused — red until GUARD-3
  // wires the sink). AC-7,8,16,17 (source-scan rules) and AC-14,15 (swap seams)
  // are *limited* at this stage — the real scan / the caller-exercise land in
  // GUARD-4 / GUARD-6 / GUARD-5 — so each is graded *B pending <phase>* with a
  // Test-augmentations row, and fails red at baseline on its control Then.
  // Every test is registered via [acTestWidgets]: skipped by default, run under
  // `--dart-define=BS12_RUN_PENDING=true` (the red baseline).
  // -------------------------------------------------------------------------
  group('bs-12 acceptance criteria — invariant guards (ITEST-2)', () {
    acTestWidgets('AC-1', 'every core function works with networking disabled',
        (tester) async {
      // Scenario: With networking disabled, every core function still works.
      final sink = NetworkAttemptSink();
      // When: run every core function under the network block; each assembles
      // and runs from local data, reaching a working state.
      await runUnderNetworkBlock(() async {
        // Sweep every core flow (read-only launches — no navigation): each
        // feature assembles and runs offline, reaching its screen / local state.
        for (final flow in NfrFlow.values) {
          final h = await givenTheApp(tester, flow: flow);
          // Given: the flow opened through the production buildApp.
          expect(find.byType(flowHome[flow]!), findsOneWidget,
              reason: 'Given: ${flow.name} opened through buildApp offline');
          switch (flow) {
            case NfrFlow.readout:
              expect(
                  find.descendant(
                      of: find.byKey(NameHeader.headerKey),
                      matching: find.text(demoSample.name!)),
                  findsOneWidget,
                  reason: 'readout renders the reading offline');
            case NfrFlow.recipes:
              expect(h.recipeState.recipes, isNotEmpty,
                  reason: 'recipe search returns candidates offline');
            case NfrFlow.palette:
              // The projects controller mounted and read its local catalogue
              // offline (the getter resolves the read endpoint; default empty).
              expect(h.projectController.projects, isEmpty,
                  reason: 'projects load from local storage offline');
            case NfrFlow.capture:
            case NfrFlow.comparison:
              break; // screen-present (above) is the offline-launch proof
          }
        }
        // Depth, last: a capture commits a reading end to end offline. A commit
        // pushes the Readout route, so it is the final launch (nothing after it).
        final cap = await givenTheApp(tester, flow: NfrFlow.capture);
        await cap.whenCaptureCommittedReading();
        expect(cap.captureState.lastCommittedSample, isNotNull,
            reason: 'a reading commits offline');
      }, sink: sink);
      // Then: no core function touched the network.
      expect(sink.attempts, 0,
          reason: 'a core function attempted a network connection');
      // Control (G3/G5): the counter actually counts — a deliberate network
      // touch is recorded and refused, so "zero attempts" above is meaningful.
      await expectLater(
          runUnderNetworkBlock(() async => HttpClient(), sink: sink),
          throwsA(isA<NetworkBlockedException>()));
      expect(sink.attempts, greaterThan(0),
          reason: 'control: a network touch must be recorded + refused '
              '(GUARD-3 wires the sink)');
    });

    acTestWidgets('AC-2', 'no core function blocks waiting on connectivity',
        (tester) async {
      // Scenario: No core function blocks on connectivity.
      final sink = NetworkAttemptSink();
      await runUnderNetworkBlock(() async {
        for (final flow in NfrFlow.values) {
          // When: the painter uses each core function. givenTheApp's
          // pumpAndSettle completes — a flow that awaited a socket would hang
          // here (settle would time out); reaching the assertion proves it did
          // not block on connectivity.
          final h = await givenTheApp(tester, flow: flow);
          // Then: the flow completes deterministically to its screen.
          expect(find.byType(flowHome[flow]!), findsOneWidget,
              reason: '${flow.name} settled without blocking on connectivity');
          expect(h.flow, flow);
        }
      }, sink: sink);
      expect(sink.attempts, 0, reason: 'a flow attempted a network connection');
      // Control: an operation that DOES require connectivity cannot complete —
      // it is recorded and refused rather than silently waited on.
      await expectLater(
          runUnderNetworkBlock(() async => HttpClient(), sink: sink),
          throwsA(isA<NetworkBlockedException>()));
      expect(sink.attempts, greaterThan(0),
          reason: 'control: a connectivity-dependent op must be recorded + '
              'refused (GUARD-3 wires the sink)');
    });

    acTestWidgets('AC-6', 'photos and samples never leave the device',
        (tester) async {
      // Scenario: Photos and samples never leave the device.
      final sink = NetworkAttemptSink();
      Uint8List? exported;
      await runUnderNetworkBlock(() async {
        // Save + export: a locally-stored project exports to the on-device share
        // sink — the only export destination, never a network sink.
        final pal = await givenPaletteWithSeededProject(
          tester,
          pdfShareSink: (bytes, name) async => exported = bytes,
        );
        expect(
            pal.projectController.projects.map((p) => p.name),
            contains(nfrSeededProject.name),
            reason: 'the project resolves from the local project source');
        await pal.whenOpenAndExportProject(nfrSeededProject.name);
        expect(pal.projectController.lastExport, isNotNull,
            reason: 'export produced PDF bytes on-device');
        // Reset the tree so the opened-project route is torn down before the
        // next launch (a navigating action must not bleed into a fresh launch).
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        // Capture, last: a committed reading is held in local controller state
        // (a commit pushes the Readout route, so it is the final launch).
        final cap = await givenTheApp(tester, flow: NfrFlow.capture);
        await cap.whenCaptureCommittedReading();
        expect(cap.captureState.lastCommittedSample, isNotNull,
            reason: 'the captured sample is held locally');
      }, sink: sink);
      // Then: the export bytes went only to the on-device share sink…
      expect(exported, isNotNull,
          reason: 'export bytes were handed to the on-device share sink');
      expect(String.fromCharCodes(exported!.take(5)), '%PDF-',
          reason: 'the on-device sink received the real PDF document');
      // …and nothing left the device.
      expect(sink.attempts, 0, reason: 'an artefact was sent off-device');
      // Control (G3/G5): the counter counts — a deliberate touch is recorded.
      await expectLater(
          runUnderNetworkBlock(() async => HttpClient(), sink: sink),
          throwsA(isA<NetworkBlockedException>()));
      expect(sink.attempts, greaterThan(0),
          reason: 'control: a network touch must be recorded + refused '
              '(GUARD-3 wired the sink increment)');
    });

    acTestWidgets('AC-7', 'there is no account and no telemetry in v1',
        (tester) async {
      // Scenario: There is no account and no telemetry in v1.
      // Then (sweep): the resolved dependency set carries no forbidden package.
      expect(forbiddenDependencies(), isEmpty,
          reason: 'a forbidden analytics / account / telemetry package is '
              'present in the resolved dependencies');
      // …and no account surface is reachable from the running app.
      await givenTheApp(tester);
      expect(
          find.textContaining(
              RegExp(r'sign in|log in|create account|sign up',
                  caseSensitive: false)),
          findsNothing,
          reason: 'no account / auth surface is reachable');
      // Control (G5): a planted forbidden package name is flagged by the guard
      // (GUARD-4's real pubspec / lockfile scan honouring resolvedNames).
      expect(
          forbiddenDependencies(
              resolvedNames: const {'provider', 'drift', 'firebase_analytics'}),
          contains('firebase_analytics'),
          reason: 'control: the dependency guard must flag a forbidden package');
    });

    acTestWidgets('AC-8', 'any future sync is opt-in and explicit',
        (tester) async {
      // Scenario: Any future sync is opt-in and explicit (D-6: no off-device
      // path exists, and the guard defends that).
      // Then (sweep): no off-device sender exists in lib/.
      expect(offDeviceSenders(), isEmpty,
          reason: 'an unconsented off-device send path exists in lib/');
      // Control (G5): a planted unconsented off-device sender is flagged by
      // GUARD-4's real source scan honouring roots (reads on the host VM).
      expect(
          offDeviceSenders(roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_off_device_sender')),
          isTrue,
          reason: 'control: the off-device-sender guard must flag the planted '
              'sender');
    });

    acTestWidgets('AC-14',
        'the mixing engine can be replaced without touching its callers',
        (tester) async {
      // Scenario: The mixing engine can be replaced without touching its
      // callers. When: the app is assembled with an alternate MixingEngine
      // injected through AppDependencies.mixingEngine, and a recipe caller runs.
      final alt = RecordingMixingEngine();
      final h = await givenTheApp(tester, flow: NfrFlow.recipes, mixingEngine: alt);
      // Then (dynamic — swap works): the recipe caller reached the engine only
      // through the interface, driving the injected alternate and producing
      // correct candidates with no change to caller code.
      expect(alt.inverseCalls, greaterThan(0),
          reason: 'a recipe caller must drive the injected engine through the '
              'MixingEngine interface');
      expect(h.recipeState.recipes, isNotEmpty,
          reason: 'the callers produced recipes through the alternate engine');
      // Then (static — no coupling): no lib/ caller references the concrete
      // SubtractiveMixingEngine, so the swap needs no caller edit.
      expect(concreteTypeReferences('SubtractiveMixingEngine'), isEmpty,
          reason: 'a caller is bound to the concrete mixing engine');
      // Control (G5): a planted caller bound to the concrete engine is flagged
      // by the no-concrete-reference rule.
      expect(
          concreteTypeReferences('SubtractiveMixingEngine',
                  roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_bound_to_concrete')),
          isTrue,
          reason: 'control: the no-concrete-reference rule must flag the planted '
              'bound-to-concrete caller');
    });

    acTestWidgets('AC-15',
        'the CVD model can be replaced without touching its callers',
        (tester) async {
      // Scenario: The CVD model can be replaced without touching its callers.
      // When: the app is assembled with an alternate ConfusionCheck injected
      // through AppDependencies.confusionCheck, and a CVD caller runs — opening
      // a two-sample project drives the projects controller's confusion-pair
      // check (the production caller that reaches the CVD model).
      final alt = RecordingConfusionCheck();
      final h = await givenPaletteWithCvdCallerProject(tester, confusionCheck: alt);
      await h.whenOpenProject(nfrCvdCallerProject.name);
      // Then (dynamic — swap works): the caller reached the model only through
      // the interface, driving the injected alternate, with no change to caller
      // code.
      expect(alt.confusableCalls, greaterThan(0),
          reason: 'a CVD caller must drive the injected model through the '
              'ConfusionCheck interface');
      expect(h.projectController.openedProject?.name, nfrCvdCallerProject.name,
          reason: 'the opened project resolved its confusion pairs through the '
              'alternate model');
      // Then (static — no coupling): no lib/ caller references the concrete
      // DichromatConfusionCheck, so the swap needs no caller edit.
      expect(concreteTypeReferences('DichromatConfusionCheck'), isEmpty,
          reason: 'a caller is bound to the concrete CVD model');
      // Control (G5): a planted caller bound to the concrete model is flagged by
      // the no-concrete-reference rule.
      expect(
          concreteTypeReferences('DichromatConfusionCheck',
                  roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_bound_to_concrete_cvd')),
          isTrue,
          reason: 'control: the no-concrete-reference rule must flag the planted '
              'bound-to-concrete CVD caller');
    });

    acTestWidgets('AC-16',
        'colour-science conversions come from one tested library',
        (tester) async {
      // Scenario: Colour-science conversions come from one tested library
      // (D-4: one conversion authority, one ΔE authority).
      // Then (sweep): no lib/ file computes a conversion or a ΔE outside them.
      expect(conversionOffenders(), isEmpty,
          reason: 'a stray colour-space conversion exists in lib/');
      expect(deltaEOffenders(), isEmpty,
          reason: 'a stray ΔE00 computation exists in lib/');
      // Control (G5): the planted stray-maths fixture is flagged by both rules
      // (GUARD-6 landed the real conversion + ΔE scans).
      expect(
          conversionOffenders(roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_stray_colour_math')),
          isTrue,
          reason: 'control: the conversion rule must flag the planted stray '
              'maths');
      expect(
          deltaEOffenders(roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_stray_colour_math')),
          isTrue,
          reason: 'control: the ΔE rule must flag the planted stray maths');
    });

    acTestWidgets('AC-17',
        'only the native capture implementation differs per platform',
        (tester) async {
      // Scenario: Only the native capture implementation differs per platform.
      // Then (sweep): no platform-conditional code outside lib/capture/source/.
      expect(platformOffenders(), isEmpty,
          reason: 'platform-conditional code exists outside the capture seam');
      // Control (G5): the planted platform fixture is flagged (GUARD-6 landed
      // the real platform scan).
      expect(
          platformOffenders(roots: const [kControlFixturesRoot])
              .any((o) => o.path.contains('control_platform_dart')),
          isTrue,
          reason: 'control: the platform rule must flag the planted platform '
              'code');
    });
  });

  // -------------------------------------------------------------------------
  // ITEST-3 — AC tests: the quality targets (pending)
  //
  // AC-3/AC-4 (performance — hybrid, D-3) assert the *mechanism* (a reading
  // settles to STABLE with a visible indicator; a search returns 3–5 ranked
  // candidates) under the generous CI regression budget — never the
  // target-hardware ~1–2s figure, which is owner evidence at SIGNOFF (G-3).
  // AC-9 (reliability) drives a would-be-trustworthy commit under each poor
  // condition and asserts it is downgraded, never returned trustworthy — red
  // until QUALITY-2 wires the exposure/card triggers (only lighting downgrades
  // today), so B pending QUALITY-2. AC-10/11/12 (accuracy, D-2) feed the full
  // synthetic held-out set (≥3 per condition) through the real capture / engine
  // pipeline and grade each produced reading / prediction against its known
  // truth with the independent reference ΔE (≤ 3 calibrated / ≤ 8 approximate /
  // ≤ 5 in-gamut), each with a perturbation control — delivered in QUALITY-4.
  // AC-13 (out-of-gamut) drives the real engine
  // toward the synthetic gamut targets. Every test is registered via
  // [acTestWidgets]: skipped by default, run under
  // `--dart-define=BS12_RUN_PENDING=true` (the red baseline).
  // -------------------------------------------------------------------------
  group('bs-12 acceptance criteria — quality targets (ITEST-3)', () {
    acTestWidgets('AC-3',
        'a committed reading settles within the budget with a visible indicator',
        (tester) async {
      // Scenario: A committed reading settles within the budget with a visible
      // indicator (AC-3; performance is hybrid — mechanism + CI budget, D-3).
      const perf = PerfHarness();
      // Given: the capture flow opened through buildApp, the stability indicator
      // present and reading the real settle mechanism ("SETTLING n/12" before it
      // settles, "STABLE 12/12" once settled) — not a static placeholder.
      final probe = await perf.measure(
        'capture-settle',
        kCaptureSettleCiBudget,
        () async {
          final cap = await givenTheApp(tester, flow: NfrFlow.capture);
          // Given: the settle indicator is visible on the Capture screen…
          expect(find.byKey(CaptureLiveView.stabilityKey), findsOneWidget,
              reason: 'Given: the settle indicator is on the Capture screen');
          // …and it reflects the real settle mechanism ("SETTLING n/12" while
          // settling, "STABLE 12/12" once settled) — not a static placeholder.
          // The indicator's text is the observable [CaptureState.stabilityText].
          expect(
            cap.captureState.stabilityText,
            matches(RegExp(r'^(SETTLING \d+|STABLE 12)/12$')),
            reason: 'Given: the indicator reflects the real settle progress');
          // When: the painter settles the reading (locks AE/AWB/AF)…
          await cap.whenLockCapture();
          // Then: it reaches STABLE 12/12 (read through the endpoint, which stays
          // observable after a commit pushes Readout over the Capture screen)…
          expect(cap.captureState.stabilityText, 'STABLE 12/12',
              reason: 'the reading must reach STABLE before it commits');
          // …and committing the averaged frames lands the reading.
          await cap.whenCommitCapture();
          expect(cap.captureState.lastCommittedSample, isNotNull,
              reason: 'the settled reading must commit');
        },
      );
      // Then: the whole settle-and-commit stayed under the generous CI budget (a
      // regression ceiling on the sim — NOT the target-hardware ~1–2s, which is
      // owner evidence at SIGNOFF under G-3).
      expect(probe.withinBudget, isTrue,
          reason: 'settle+commit overran the CI regression budget: $probe');
    });

    acTestWidgets('AC-4', 'a recipe search returns 3–5 ranked candidates within '
        'the budget', (tester) async {
      // Scenario: Recipe search returns within the budget (AC-4).
      const perf = PerfHarness();
      late NfrHarness rec;
      // Given + When: a recipe search over the real engine for the seeded
      // reachable target, timed under the generous CI budget.
      final probe = await perf.measure(
        'recipe-search',
        kRecipeSearchCiBudget,
        () async {
          rec = await givenTheApp(tester, flow: NfrFlow.recipes);
        },
      );
      final recipes = rec.recipeState.recipes;
      // Then: 3–5 ranked candidates returned (the engine ranks them best-first
      // by its own criteria — ΔE00 and prefer-fewer components, bs-04 D-8 — so
      // this asserts the count the painter is offered, not a re-derived order)…
      expect(isTopCandidateCount(recipes.length), isTrue,
          reason: 'a recipe search must return $kMinTopCandidates–'
              '$kMaxTopCandidates candidates (got ${recipes.length})');
      // …and the search reports them as a solved result (the state the Recipes
      // screen renders candidates from).
      expect(rec.recipeState.hasRecipes, isTrue,
          reason: 'the search must return a solved candidate set');
      // …within the generous CI budget (regression ceiling, not the device
      // figure — owner evidence at SIGNOFF under G-3).
      expect(probe.withinBudget, isTrue,
          reason: 'the search overran the CI regression budget: $probe');
    });

    acTestWidgets('AC-9',
        'poor conditions downgrade the stated accuracy rather than failing '
        'quietly', (tester) async {
      // Scenario: Poor conditions downgrade the stated accuracy rather than
      // failing quietly (AC-9; D-5 — all three conditions must downgrade, not
      // just lighting). Each condition is driven to a reading that would
      // otherwise be trustworthy (calibrated against a card), then committed;
      // the stated accuracy must be downgraded, never returned as calibrated.

      // Commits a reading under one condition and returns the committed stated
      // accuracy plus the downgrade reasons the controller reports, then resets
      // the tree so the pushed Readout route does not bleed into the next launch.
      Future<({CaptureAccuracy? accuracy, Set<AccuracyDowngradeReason> reasons})>
          commitUnder(SceneSpec scene, {required bool lock}) async {
        final cap = await givenTheApp(
          tester,
          flow: NfrFlow.capture,
          captureSource: FakeCaptureSource(scene),
        );
        if (lock) await cap.whenLockCapture();
        // Calibrate against the card when one is in view (a no-op otherwise):
        // this is what would otherwise make the reading trustworthy.
        await cap.whenCalibrate();
        final reasons = cap.activeDowngradeReasons;
        await cap.whenCommitCapture();
        final committed = cap.captureState.lastCommittedSample;
        expect(committed, isNotNull, reason: 'a reading commits under $scene');
        final result = (accuracy: committed!.accuracy, reasons: reasons);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        return result;
      }

      // Low light: card present + calibrated, but the scene is dim — the reading
      // must be downgraded to approximate, not returned calibrated.
      final low = await commitUnder(nfrLowLightScene, lock: true);
      expect(low.reasons, contains(AccuracyDowngradeReason.lowLight),
          reason: 'low light is a reported downgrade condition');
      expect(low.accuracy, CaptureAccuracy.approximate,
          reason: 'a dim reading must be downgraded, never returned calibrated '
              '(QUALITY-2 wires the trigger)');

      // Unlocked exposure: card present + calibrated, but AE/AWB/AF never locked
      // — the unsettled reading must be downgraded.
      final unlocked = await commitUnder(nfrUnlockedScene, lock: false);
      expect(unlocked.reasons,
          contains(AccuracyDowngradeReason.exposureUnlocked),
          reason: 'unlocked exposure is a reported downgrade condition');
      expect(unlocked.accuracy, CaptureAccuracy.approximate,
          reason: 'an unsettled reading must be downgraded, never returned '
              'calibrated (QUALITY-2 wires the trigger)');

      // Missing card: no card to calibrate against — the reading must be
      // labelled approximate and the reason reported.
      final missing = await commitUnder(nfrMissingCardScene, lock: true);
      expect(missing.reasons,
          contains(AccuracyDowngradeReason.missingReferenceCard),
          reason: 'a missing reference card is a reported downgrade condition');
      expect(missing.accuracy, CaptureAccuracy.approximate,
          reason: 'a card-less reading must be labelled approximate');

      // Control (G5): a trustworthy reading — well lit, locked and calibrated
      // against a card — has no downgrade condition and must stay calibrated, so
      // the downgrades above are meaningful (the reading *can* be trustworthy).
      final trustworthy = await commitUnder(nfrTrustworthyScene, lock: true);
      expect(trustworthy.reasons, isEmpty,
          reason: 'control: a trustworthy reading has no downgrade condition');
      expect(trustworthy.accuracy, CaptureAccuracy.calibrated,
          reason: 'control: a trustworthy reading stays calibrated — the '
              'downgrade is not a blanket force-to-approximate');
    });

    // AC-10/11/12 feed the full held-out set (QUALITY-4) through the REAL
    // capture / engine pipeline and grade the *produced* reading / prediction
    // against its known truth with the INDEPENDENT reference ΔE00 (never the
    // product metric against itself, D-2). The synthetic truth is a
    // deterministic stand-in for a spectrophotometer measurement — the
    // "synthetic ≠ physical ground truth" gap is carried to sign-off; what these
    // prove is that the real pipeline meets each bound against a known truth.
    // Each test also drives its perturbation control, which must exceed the
    // bound, so the within-bound assertion is not vacuously satisfiable (G5).
    const harness = AccuracyHarness();
    const minSamplesPerCondition = 3;

    // Commits a reading of [truth] through the real capture pipeline and returns
    // the committed sample. With a reference [card] in view the card calibration
    // is applied (the calibrated, controlled path); without one the reading is
    // left to the honest card-less downgrade. The tree is reset after each so a
    // pushed Readout route never bleeds into the next launch (the AC-9 hygiene).
    Future<Sample> captureReading(
      WidgetTester tester,
      ColorCoordinates truth, {
      required bool card,
    }) async {
      final cap = await givenTheApp(
        tester,
        flow: NfrFlow.capture,
        captureSource: FakeCaptureSource(
          SceneSpec(groundTruth: truth, referenceCardPresent: card),
        ),
      );
      await cap.whenLockCapture();
      if (card) await cap.whenCalibrate();
      await cap.whenCommitCapture();
      final committed = cap.captureState.lastCommittedSample;
      expect(committed, isNotNull, reason: 'a reading commits for $truth');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      return committed!;
    }

    acTestWidgets('AC-10',
        'capture with a reference card in controlled lighting meets ΔE00 ≤ 3',
        (tester) async {
      // Scenario: card + controlled lighting → ΔE00 ≤ 3 (AC-10, D-2).
      final samples = heldOutCardControlled;
      expect(samples.length, greaterThanOrEqualTo(minSamplesPerCondition),
          reason: 'the held-out card+controlled set must carry '
              '≥$minSamplesPerCondition samples');
      // Then: each truth, read back through the real calibrated pipeline, lands
      // within ΔE00 3 of truth (independent reference metric) and is stated
      // calibrated — never silently downgraded under good conditions.
      for (final sample in samples) {
        final reading = await captureReading(tester, sample.truth, card: true);
        expect(reading.accuracy, CaptureAccuracy.calibrated,
            reason: 'a card-calibrated reading under good light is calibrated: '
                '${sample.id}');
        final grade = harness.gradeProduced(reading.coordinates, sample);
        expect(grade.maxDeltaE, 3);
        expect(grade.withinBound, isTrue,
            reason: 'card+controlled must sit within ΔE00 3: $grade');
      }
      // Control (G5): a reading pulled far off truth exceeds the bound, so the
      // grade + bound genuinely reject an off reading (not a vacuous pass).
      final control = accuracyPerturbationControls
          .firstWhere((c) => c.condition == AccuracyCondition.cardControlled);
      expect(harness.grade(control).withinBound, isFalse,
          reason: 'a perturbed card+controlled reading must exceed ΔE00 3');
    });

    acTestWidgets('AC-11',
        'capture without a reference card in daylight meets ΔE00 ≤ 8, labelled '
        'approximate', (tester) async {
      // Scenario: card-less daylight → ΔE00 ≤ 8 AND labelled approximate (AC-11).
      final samples = heldOutCardlessDaylight;
      expect(samples.length, greaterThanOrEqualTo(minSamplesPerCondition),
          reason: 'the held-out card-less daylight set must carry '
              '≥$minSamplesPerCondition samples');
      for (final sample in samples) {
        expect(sample.expectApproximate, isTrue,
            reason: 'a card-less daylight sample is labelled approximate');
        final reading = await captureReading(tester, sample.truth, card: false);
        // Then: labelled approximate (never returned calibrated)…
        expect(reading.accuracy, CaptureAccuracy.approximate,
            reason: 'a card-less reading must be labelled approximate: '
                '${sample.id}');
        // …and within ΔE00 8 of truth by the independent reference metric.
        final grade = harness.gradeProduced(reading.coordinates, sample);
        expect(grade.maxDeltaE, 8);
        expect(grade.withinBound, isTrue,
            reason: 'card-less daylight must sit within ΔE00 8: $grade');
      }
      // Control (G5): a reading far off truth exceeds the ΔE00 8 bound.
      final control = accuracyPerturbationControls
          .firstWhere((c) => c.condition == AccuracyCondition.cardlessDaylight);
      expect(harness.grade(control).withinBound, isFalse,
          reason: 'a perturbed card-less reading must exceed ΔE00 8');
    });

    acTestWidgets('AC-12',
        'a recipe prediction vs a mixed swatch meets ΔE00 ≤ 5 in-gamut',
        (tester) async {
      // Scenario: recipe prediction vs mixed swatch → ΔE00 ≤ 5 in-gamut (AC-12).
      final samples = heldOutRecipeVsSwatch;
      expect(samples.length, greaterThanOrEqualTo(minSamplesPerCondition),
          reason: 'the held-out recipe-vs-swatch set must carry '
              '≥$minSamplesPerCondition samples');
      for (final sample in samples) {
        // Given + When: the real engine solves toward the reachable truth.
        final rec = await givenTheApp(
          tester,
          flow: NfrFlow.recipes,
          recipeTarget: Sample(
            coordinates: sample.truth,
            provenance: const Provenance(ProvenanceTier.measured),
          ),
        );
        final recipes = rec.recipeState.recipes;
        expect(recipes, isNotEmpty, reason: 'in-gamut target returns recipes: '
            '${sample.id}');
        // Then: the target is reachable (in gamut)…
        expect(rec.recipeState.outOfGamut, isFalse,
            reason: 'an in-gamut target is not flagged out of gamut: '
                '${sample.id}');
        // …and the best predicted (forward-mixed) colour the painter is offered
        // sits within ΔE00 5 of truth by the INDEPENDENT reference metric (not
        // the engine's own ΔE) — the "mixed swatch" modelled as the prediction.
        final bestDeltaE = recipes
            .map((r) => harness.deltaE(r.predictedColor, sample.truth))
            .reduce((a, b) => a < b ? a : b);
        expect(bestDeltaE, lessThanOrEqualTo(sample.maxDeltaE),
            reason: 'an in-gamut recipe prediction must sit within ΔE00 5 of '
                'truth (best was $bestDeltaE): ${sample.id}');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      // Control (G5): an out-of-gamut target cannot be predicted within ΔE00 5 —
      // the real engine flags it and every nearest mix stays beyond the bound,
      // so the within-bound claim discriminates reachable from unreachable.
      final outTarget = syntheticGamutTargets.firstWhere((t) => !t.inGamut);
      final out = await givenTheApp(
        tester,
        flow: NfrFlow.recipes,
        recipeTarget: Sample(
          coordinates: outTarget.target,
          provenance: const Provenance(ProvenanceTier.measured),
        ),
      );
      expect(out.recipeState.outOfGamut, isTrue,
          reason: 'control: the out-of-gamut target must be flagged');
      final outBest = out.recipeState.recipes
          .map((r) => harness.deltaE(r.predictedColor, outTarget.target))
          .reduce((a, b) => a < b ? a : b);
      expect(outBest, greaterThan(5),
          reason: 'control: an out-of-gamut target cannot be predicted within '
              'ΔE00 5 (best was $outBest)');
    });

    acTestWidgets('AC-13',
        'an out-of-gamut target is identified and offered no false recipe',
        (tester) async {
      // Scenario: An out-of-gamut target is identified, no false recipe (AC-13;
      // behaviour exists — bs-04 ENGINE-5; QUALITY-3 proves and guards it).
      final outTarget = syntheticGamutTargets.firstWhere((t) => !t.inGamut);
      final inTarget = syntheticGamutTargets.firstWhere((t) => t.inGamut);

      // Given + When: the real engine solves toward the out-of-gamut target over
      // the owned palette.
      final out = await givenTheApp(
        tester,
        flow: NfrFlow.recipes,
        recipeTarget: Sample(
          coordinates: outTarget.target,
          provenance: const Provenance(ProvenanceTier.measured),
        ),
      );
      // Then: the target is identified as out of gamut (state + the shown
      // banner marker — not just the always-present collapsed anchor)…
      expect(out.recipeState.outOfGamut, isTrue,
          reason: 'the out-of-gamut target must be identified');
      expect(find.text(GamutBanner.markerText), findsOneWidget,
          reason: 'the out-of-gamut banner marker must be shown');
      // …and no recipe is offered as a match — every returned mix is flagged the
      // nearest possible, not a claimed match.
      expect(out.recipeState.recipes, isNotEmpty,
          reason: 'the nearest mixes are still offered (as non-matches)');
      expect(out.recipeState.recipes.every((r) => r.outOfGamut), isTrue,
          reason: 'no recipe may be presented as a match for an out-of-gamut '
              'target');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      // Control (G5): an in-gamut target is NOT flagged and DOES return recipes —
      // the identification discriminates reachable from unreachable.
      final inside = await givenTheApp(
        tester,
        flow: NfrFlow.recipes,
        recipeTarget: Sample(
          coordinates: inTarget.target,
          provenance: const Provenance(ProvenanceTier.measured),
        ),
      );
      expect(inside.recipeState.outOfGamut, isFalse,
          reason: 'control: an in-gamut target must not be flagged out of gamut');
      expect(find.text(GamutBanner.markerText), findsNothing,
          reason: 'control: no out-of-gamut marker is shown for an in-gamut '
              'target');
      expect(inside.recipeState.recipes, isNotEmpty,
          reason: 'control: an in-gamut target returns recipes');
    });
  });

  group('pending gate', () {
    // The 16 automatable ACs (AC-5 is pure-manual, D-3, never in the gate) were
    // all pending at ITEST-1; each behaviour phase deletes its row in
    // `bs12/pending.dart` as it un-pends that AC. GUARD-3 un-pended AC-1 + AC-2
    // (offline); GUARD-4 un-pended AC-6 + AC-7 + AC-8 (privacy); GUARD-5 un-pended
    // AC-14 + AC-15 (swappable interfaces); GUARD-6 un-pended AC-16 + AC-17 (one
    // colour library + portability); QUALITY-2 un-pended AC-9 (reliability
    // downgrade); QUALITY-3 un-pended AC-13 (out-of-gamut); QUALITY-4 un-pended
    // AC-10 + AC-11 + AC-12 (accuracy); QUALITY-5 un-pended AC-3 + AC-4
    // (performance). Every automatable AC has now landed, so the gate is empty.
    final expectedPending = <String>{
      // empty — all 16 automatable ACs un-pended (AC-5 is pure-manual, absent)
    };

    test('the pending map is exactly the still-pending automatable ACs, each '
        'owned by a real behaviour phase', () {
      expect(pendingACs.keys.toSet(), expectedPending);
      expect(pendingACs.length, 0);
      // Every automatable AC was un-pended by its owning phase and must not
      // reappear: AC-1 + AC-2 (GUARD-3), AC-3 + AC-4 (QUALITY-5), AC-6 + AC-7 +
      // AC-8 (GUARD-4), AC-9 (QUALITY-2), AC-10 + AC-11 + AC-12 (QUALITY-4),
      // AC-13 (QUALITY-3), AC-14 + AC-15 (GUARD-5), AC-16 + AC-17 (GUARD-6).
      expect(pendingACs.containsKey('AC-3'), isFalse);
      expect(pendingACs.containsKey('AC-4'), isFalse);
      expect(pendingACs.containsKey('AC-1'), isFalse);
      expect(pendingACs.containsKey('AC-2'), isFalse);
      expect(pendingACs.containsKey('AC-6'), isFalse);
      expect(pendingACs.containsKey('AC-7'), isFalse);
      expect(pendingACs.containsKey('AC-8'), isFalse);
      expect(pendingACs.containsKey('AC-9'), isFalse);
      expect(pendingACs.containsKey('AC-10'), isFalse);
      expect(pendingACs.containsKey('AC-11'), isFalse);
      expect(pendingACs.containsKey('AC-12'), isFalse);
      expect(pendingACs.containsKey('AC-13'), isFalse);
      expect(pendingACs.containsKey('AC-14'), isFalse);
      expect(pendingACs.containsKey('AC-15'), isFalse);
      expect(pendingACs.containsKey('AC-16'), isFalse);
      expect(pendingACs.containsKey('AC-17'), isFalse);

      // AC-5 (live-preview frame rate) is pure-manual and must never enter the
      // gate.
      expect(pendingACs.containsKey('AC-5'), isFalse);

      // Every key is a real AC id and every owner is a real behaviour phase.
      final acId = RegExp(r'^AC-\d+$');
      for (final entry in pendingACs.entries) {
        expect(acId.hasMatch(entry.key), isTrue,
            reason: '"${entry.key}" is not an AC id');
        expect(behaviorPhases, contains(entry.value),
            reason: '${entry.key} names unknown phase "${entry.value}"');
      }
    });

    test('with every automatable AC un-pended, the gate skips nothing and runs '
        'every AC in both modes', () {
      // The pending map is now empty (asserted by the sibling test), so this
      // loop is intentionally over an empty set — it still holds the invariant
      // that any residual pending AC would skip by default and run under the
      // flag, but the live assertions below are on the un-pended end state.
      expect(pendingACs, isEmpty);
      for (final ac in pendingACs.keys) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull);
        expect(pendingSkipReason(ac, forceRunPending: true), isNull);
      }
      // QUALITY-5's ACs (AC-3, AC-4) are now un-pended, so they run in *both*
      // modes — the end state every behaviour phase moved its AC toward (and a
      // regression that re-pended either would fail here).
      for (final ac in const ['AC-3', 'AC-4']) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNull,
            reason: '$ac is un-pended and must run in the default run');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac is un-pended and must run in run-pending mode');
        // The ambient path (used by acTestWidgets) agrees with the current mode.
        expect(pendingSkipReason(ac),
            pendingSkipReason(ac, forceRunPending: runPending));
      }
      // An AC absent from the map always runs, in either mode — the un-pended
      // end state each behaviour phase moved its AC toward.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
    });
  });

  group('the platform fakes record what the app drives them with', () {
    test('FakeSpeech appends each utterance in order', () async {
      final speech = FakeSpeech();
      await speech.speak('first');
      await speech.speak('second');
      expect(speech.utterances, ['first', 'second']);
    });

    test('FakeHaptics counts each confirmation', () async {
      final haptics = FakeHaptics();
      await haptics.confirm();
      await haptics.confirm();
      expect(haptics.confirmations, 2);
    });
  });
}
