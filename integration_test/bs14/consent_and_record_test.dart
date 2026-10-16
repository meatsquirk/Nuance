// bs-14 acceptance criteria — consent + record (ITEST-2).
//
// One *pending* integration test per AC-1..AC-5, written against the real
// sharing subsystem through the public surface only (the booted app's
// `SharingConsentReadEndpoint` for the consent ACs; the real `RecordBuilder`
// observed through `RecordInspectEndpoint` for the record ACs). Each test
// encodes the AC's intended behaviour and is *pending* until its behaviour phase
// lands:
//
//   AC-1 → CORE-3   (opt in once, never shown the mechanism)   — widget
//   AC-2 → CORE-4   (no per-exchange action)                   — widget
//   AC-3 → RECORD-2 (record carries only the mapping evidence) — pure-Dart
//   AC-4 → RECORD-2 (nothing personal leaves the device)       — pure-Dart
//   AC-5 → RECORD-3 (no declared palette ⇒ not shared)         — pure-Dart
//
// The pending gate (`acTestWidgets` / `acTest`, keyed to `BS14_RUN_PENDING`)
// skips these in the default run (so the suite stays green with all five
// pending) and runs them under `--dart-define=BS14_RUN_PENDING=true` (the red
// baseline). Each pending test fails on a Then assertion or a Given precondition
// that names the owning phase — never a harness crash.
//
// Runs on the host `flutter-tester` device (pure-Dart sharing logic, no camera):
//   flutter test integration_test/bs14/consent_and_record_test.dart -d flutter-tester
//   flutter test integration_test/bs14/consent_and_record_test.dart -d flutter-tester \
//       --dart-define=BS14_RUN_PENDING=true   # red baseline
//
// Test names mirror the plan's verbatim `TestACnn_*` names, so this file opts
// out of lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/consent/consent_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

import 'harness.dart';

/// The key CORE-3 must give the one-time opt-in offer control.
///
/// Frozen here (the ITEST phase fixes the contract) so the AC-1 acceptance test
/// can find and tap the offer through the public widget surface; CORE-3 presents
/// the offer under this exact key. Absent in the shell ⇒ AC-1's Given
/// precondition fails here at the red baseline, naming CORE-3.
const Key sharingOptInKey = Key('sharing-opt-in-offer');

void main() {
  group('bs-14 consent & record acceptance criteria', () {
    // -----------------------------------------------------------------------
    // AC-1 — the painter opts in once in plain terms and is never shown the
    // mechanism. Owner: CORE-3.
    // -----------------------------------------------------------------------
    acTestWidgets('AC-1', 'TestAC01_OptInOnceNeverShown', (tester) async {
      final app = await givenTheSharingApp(tester);

      // Given: the painter is offered the plain-language opt-in, and a fresh
      // install is not yet opted in.
      expect(app.offerCopy, SharingConsent.defaultOfferCopy,
          reason: 'AC-1 Given: the offer is the frozen plain-language copy, '
              'naming no mechanism');
      expect(app.consented, isFalse,
          reason: 'AC-1 Given: a fresh install is not opted in');
      // Given precondition (CORE-3): the one-time opt-in offer is presented to
      // the painter. Absent in the shell ⇒ the red baseline fails here, naming
      // the owner, rather than crashing on a tap of a missing widget.
      final offer = find.byKey(sharingOptInKey);
      expect(offer, findsOneWidget,
          reason: 'AC-1 Given: CORE-3 presents the one-time opt-in offer');
      // Given (invisibility, pre-opt-in): the subsystem's one user-facing
      // surface is the plain-language offer itself — present in the live
      // inventory and naming no mechanism. Scanning the POPULATED inventory here
      // proves the post-opt-in no-mechanism scan below reads the real production
      // surface list (a wrong impl that leaked a mechanism surface would show it
      // here), not an inventory that is only incidentally empty. CORE-3
      // augmentation closing the ITEST-5 reviewer's live-binding note.
      expect(app.userFacingSharingSurfaces, isNotEmpty,
          reason: 'AC-1: the offer is a real user-facing surface pre-opt-in');
      expect(app.userFacingSharingSurfaces, contains(app.offerCopy),
          reason: 'AC-1: the one pre-opt-in surface is the offer itself');
      for (final surface in app.userFacingSharingSurfaces) {
        expect(_mentionsNetworkConcept(surface), isFalse,
            reason: 'AC-1: even the offer names no mechanism '
                '(offending surface: "$surface")');
      }

      // When: the painter opts in once, through the public offer control.
      await tester.tap(offer);
      await tester.pumpAndSettle();
      final after = _consentEndpoint(tester);

      // Then: consent is recorded...
      expect(after.consented, isTrue,
          reason: 'AC-1: opting in records the painter\'s consent');
      // ...the mechanism is never shown — no user-visible sharing surface names
      // peers, devices, syncing or a network...
      for (final surface in after.userFacingSharingSurfaces) {
        expect(_mentionsNetworkConcept(surface), isFalse,
            reason: 'AC-1: the subsystem never shows the mechanism '
                '(offending surface: "$surface")');
      }
      // ...and the offer is shown once — not re-presented once opted in.
      expect(find.byKey(sharingOptInKey), findsNothing,
          reason: 'AC-1: the one-time offer is not shown again after opting in');

      // Control: the network-concept scan is not vacuous — it flags a surface
      // that WOULD name the mechanism, so the clean inventory above is a real
      // result, not an empty pass (rejects an impl that, after opt-in, exposes a
      // "peers nearby" / "last synced" network-status surface).
      expect(_mentionsNetworkConcept('Peers nearby · last synced'), isTrue,
          reason: 'AC-1 control: the scan catches a mechanism-naming surface');
    });

    // -----------------------------------------------------------------------
    // AC-2 — no exchange ever asks the painter to do anything. Owner: CORE-4
    // (the silent background exchange + the mechanism-free "recipes improve"
    // signal); depends on CORE-3 (reactive consent) and EXCHANGE-3 (the
    // background exchange existing).
    // -----------------------------------------------------------------------
    acTestWidgets('AC-2', 'TestAC02_NoPerExchangeAction', (tester) async {
      // Given: the painter has opted in — recorded through the public consent
      // store, the same contract the opt-in action writes (CORE-3 makes the app
      // read it back live).
      final store = InMemoryPersistentStore();
      await PersistentConsentStore(store)
          .save(const SharingConsent(consented: true));
      final app = await givenTheSharingApp(tester, store: store);
      expect(app.consented, isTrue,
          reason: 'AC-2 Given: the painter has opted in (live consent — CORE-3)');

      // When: the background exchange runs silently once opted in (CORE-4).
      // Settle so that a per-exchange prompt, were one emitted, would have fired
      // by now — the settle point the negative Thens below read after (G3).
      await tester.pumpAndSettle();
      final after = _consentEndpoint(tester);

      // The only permitted ongoing signal is a mechanism-free "recipes improve
      // over time" — its presence proves the background exchange actually ran
      // (the settle point the negative Thens read after: if a per-exchange
      // prompt were going to fire, it would have by the time this signal
      // appeared). Absent in the shell ⇒ the red baseline fails here, naming
      // CORE-4. (The exchange runs during boot settle, so emptiness below is a
      // post-exchange reading, not a pre-exchange one.)
      expect(after.userFacingSharingSurfaces.any(_isRecipeImprovedSignal), isTrue,
          reason: 'AC-2: once opted in, the exchange surfaces only a '
              'recipe-improved signal (CORE-4)');

      // Then: the background exchange that just ran asked the painter nothing —
      // nothing was spoken or buzzed per exchange, and no surface names the
      // mechanism.
      expect(app.speech.utterances, isEmpty,
          reason: 'AC-2: the background exchange emits no spoken prompt');
      expect(app.haptics.confirmations, 0,
          reason: 'AC-2: the background exchange emits no haptic prompt');
      for (final surface in after.userFacingSharingSurfaces) {
        expect(_mentionsNetworkConcept(surface), isFalse,
            reason: 'AC-2: the exchange surfaces no network/sync wording '
                '(offending surface: "$surface")');
      }

      // Control: the prompt sinks are the real, LIVE capture channel — a probe
      // driven through the same wired speech/haptics sinks is recorded — so the
      // empty/zero assertions above are a real result, not a vacuous pass
      // against a dead or unwired sink (G3: shows the reading can change).
      await app.speech.speak('probe');
      await app.haptics.confirm();
      expect(app.speech.utterances, hasLength(1),
          reason: 'AC-2 control: the speech sink records what is spoken');
      expect(app.haptics.confirmations, 1,
          reason: 'AC-2 control: the haptics sink records what is buzzed');
    });

    // -----------------------------------------------------------------------
    // AC-3 — a shared record carries only the mapping evidence. Owner: RECORD-2.
    // -----------------------------------------------------------------------
    acTest('AC-3', 'TestAC03_RecordCarriesOnlyEvidence', () {
      const builder = EvidenceRecordBuilder();

      // Given: the painter has a confirmed/measured mix (`confirmedEvidence`,
      // a card-calibrated own swatch) and a declared palette; a record is
      // prepared through the real builder.
      final prepared = builder.prepare(confirmedEvidence, palette: seedPalette);
      // Given precondition (RECORD-2): a record is built. Null in the shell ⇒
      // the red baseline fails here, naming the owner.
      expect(prepared, isNotNull,
          reason: 'AC-3 Given: RECORD-2 builds a MixAccuracyRecord from a '
              'confirmed mix');
      final record = recordEndpoint(prepared: prepared).prepared!;

      // Then: the record carries exactly the four permitted fields — the
      // declared palette, the measured colour, the tier and the paint
      // combination — and the MixAccuracyRecord type structurally holds nothing
      // else (rejects an impl that omits the palette or the tier).
      expect(record.declaredPalette, seedPalette,
          reason: 'AC-3: the record carries the declared brand/line/medium');
      expect(record.declaredPalette.isPresent, isTrue,
          reason: 'AC-3: the carried declared palette is present');
      // measured colour — the mix's CIELAB verbatim, with a consistent CIELCh.
      expect(record.measuredColour.lab, confirmedEvidence.coordinates,
          reason: 'AC-3: the measured colour is the mix\'s CIELAB');
      final expectedLch = measuredColourOf(confirmedEvidence.coordinates).lch;
      expect(record.measuredColour.lch.lightness,
          closeTo(expectedLch.lightness, 1e-6));
      expect(record.measuredColour.lch.chroma, closeTo(expectedLch.chroma, 1e-6));
      expect(record.measuredColour.lch.hue, closeTo(expectedLch.hue, 1e-6),
          reason: 'AC-3: the CIELCh form is consistent with the CIELAB');
      // tier — mapped from how the mix was measured: a card-calibrated
      // photograph (`photographedSwatch`) ⇒ reference-card.
      expect(record.tier, MeasurementTier.referenceCard,
          reason: 'AC-3: the tier reflects how the mix was measured '
              '(card-calibrated photograph ⇒ referenceCard)');
      // paint combination — canonical (sorted, deduplicated) paint ids, present.
      expect(record.paintCombination.paintIds, isNotEmpty,
          reason: 'AC-3: the record carries the paint combination');
      expect(
        record.paintCombination.paintIds,
        orderedEquals(
            List<String>.of(record.paintCombination.paintIds)..sort()),
        reason: 'AC-3: the paint ids are canonical (sorted, deduplicated)',
      );
    });

    // -----------------------------------------------------------------------
    // AC-4 — no photo, project, sample, profile, identifier or location leaves
    // the device. Owner: RECORD-2 (redaction by construction).
    // -----------------------------------------------------------------------
    acTest('AC-4', 'TestAC04_NothingPersonalLeaves', () {
      const builder = EvidenceRecordBuilder();

      // Given: a confirmed mix that ALSO carries personal context — a personal
      // sample name and an evidence source id, standing in for the project /
      // saved sample / CVD profile the painter's app state holds. The builder
      // reads only the mix + declared palette, so redaction is by construction.
      final personalMix = confirmedEvidence;
      expect(personalMix.name, 'my warm grey mix',
          reason: 'AC-4 Given: the source mix carries a personal name');
      expect(personalMix.evidence.first.source, 'own-swatch',
          reason: 'AC-4 Given: the source mix carries an evidence source id');

      final prepared = builder.prepare(personalMix, palette: seedPalette);
      // Given precondition (RECORD-2): a record is built. Null in the shell ⇒
      // the red baseline fails here, naming the owner.
      expect(prepared, isNotNull,
          reason: 'AC-4 Given: RECORD-2 builds a record from the confirmed mix');
      final record = recordEndpoint(prepared: prepared).prepared!;

      // When: the record's serialized content — what actually crosses the
      // boundary (D-4) — is inspected.
      final crossing = record.canonicalForm.toLowerCase();

      // Control: the crossing serialization is actually populated — it carries
      // the declared brand it must — so the absence assertions below are
      // discriminating, not a vacuous pass against an empty/stub serialization
      // (G3).
      expect(crossing, contains(seedPalette.brand.toLowerCase()),
          reason: 'AC-4 control: the record serializes its declared palette '
              '(the crossing content is non-empty)');

      // Then: nothing personal leaves. None of the personal tokens present in
      // the source mix appears in the record, and the declared palette carries
      // only the brand/line/medium the painter declared (rejects an impl that
      // serializes a sample name/id, evidence source, project ref or location
      // into any carried field).
      expect(crossing, isNot(contains('my warm grey mix')),
          reason: 'AC-4: no personal sample name leaves the device');
      expect(crossing, isNot(contains('own-swatch')),
          reason: 'AC-4: no evidence source id leaves the device');
      expect(record.declaredPalette, seedPalette,
          reason: 'AC-4: the declared palette carries only brand/line/medium, '
              'un-polluted by personal data');
    });

    // -----------------------------------------------------------------------
    // AC-5 — a record without a declared palette is not shared. Owner: RECORD-3.
    // -----------------------------------------------------------------------
    acTest('AC-5', 'TestAC05_NoPaletteNotShared', () {
      const builder = EvidenceRecordBuilder();

      // Given: two candidates — one with a present declared palette
      // (interpretable, shareable) and `noPaletteRecord` with none.
      final shareable = peerRecords(1).single; // carries the present seedPalette
      expect(shareable.declaredPalette.isPresent, isTrue,
          reason: 'AC-5 Given: the control record has a present declared palette');
      expect(noPaletteRecord.declaredPalette.isPresent, isFalse,
          reason: 'AC-5 Given: the candidate has no declared palette');
      final candidates = <MixAccuracyRecord>[shareable, noPaletteRecord];

      // When: the share-set is selected through the real builder.
      final observed =
          recordEndpoint(shareSet: builder.selectShareSet(candidates)).shareSet;

      // Then: the record without a declared palette is excluded as not
      // interpretable, while the interpretable one is kept. The positive case is
      // the control: it rejects both "shares everything (including no-palette)"
      // and "excludes everything".
      expect(observed, contains(shareable),
          reason: 'AC-5: a record with a present declared palette is shared '
              '(RECORD-3)');
      expect(observed, isNot(contains(noPaletteRecord)),
          reason: 'AC-5: a record without a declared palette is not '
              'interpretable, so is not shared');
    });
  });
}

/// Re-reads the live `SharingConsentReadEndpoint` from the booted tree after an
/// action — the `SharingAppHarness` captured the endpoint at boot, but the
/// InheritedWidget is replaced when consent changes, so AC-1/AC-2 read the
/// current one by its stable key.
SharingConsentReadEndpoint _consentEndpoint(WidgetTester tester) =>
    tester.widget<SharingConsentReadEndpoint>(
        find.byKey(SharingConsentReadEndpoint.endpointKey));

/// Whether [surface] names any sharing *mechanism* — a peer, device, syncing or
/// a network. The invisibility guarantee (AC-1/AC-2) is that no user-visible
/// sharing surface ever does; only outcome wording ("recipes improve") is
/// permitted.
bool _mentionsNetworkConcept(String surface) {
  final s = surface.toLowerCase();
  const concepts = <String>[
    'peer',
    'device',
    'sync',
    'network',
    'wi-fi',
    'wifi',
    'bluetooth',
    'nearby',
    'server',
    'upload',
    'download',
    'cloud',
  ];
  return concepts.any(s.contains);
}

/// Whether [surface] is the one permitted ongoing signal: a mechanism-free
/// "recipes improve over time" (names an outcome, never a mechanism).
bool _isRecipeImprovedSignal(String surface) {
  final s = surface.toLowerCase();
  return s.contains('recipe') && s.contains('improve');
}
