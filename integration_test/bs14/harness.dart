// Acceptance-suite harness for bs-14 Peer-to-peer evidence sharing (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and controls the AC tests (ITEST-2
// consent+record, ITEST-3 exchange+merge, ITEST-4 refine) are written against.
// The suite drives the *real* sharing subsystem: real records, the real gossip
// `GossipExchange`/`ExchangeScheduler`, the real `EvidenceMerge`/`CrowdRefine`/
// `SourceRateLimiter`, riding bs-13's real `ProvenanceDerivation`, and the real
// `ColorScience` for the CIELAB↔CIELCh a record carries. The **only** fake is
// the off-device `PeerTransport` (the in-process `FakePeerTransport` loopback,
// D-3) — there is no real network in the suite.
//
// Two observation surfaces:
//   * The consent surface (AC-1/AC-2) is read from the **booted app**: `buildApp`
//     mounts `SharingConsentReadEndpoint` under a `SharingScope` when a store is
//     wired (CORE-2), so [givenTheSharingApp] boots the real app and reads it.
//   * The record/exchange/merge surfaces (AC-3..AC-12) are read through the
//     sibling read endpoints — `RecordInspectEndpoint`, `ExchangeOutcomeEndpoint`,
//     `MappingEvidenceEndpoint`. These are not yet mounted in `buildApp` (the
//     behaviour phases wire them), so the harness builds each endpoint over the
//     real service's output (the sanctioned "the ITEST harness mounts the
//     endpoint directly; the behaviour phase populates it" pattern) — the service
//     under test is real, only the mount is the suite's.
//
// bs-14's own suite is pure-Dart logic (records, gossip, merge — no camera), so
// it runs on the host `flutter-tester` device, not an iOS sim (a `-d` is
// mandatory — see the master plan's Known flakes).
//
// The pending gate (all 12 ACs → owning phase) lives in `bs14/pending.dart`
// (seeded in CORE-1); this harness re-exports it, the fake transport and the
// shared fakes so an AC test imports only this file.
//
// Fixture identifiers mirror the master plan's fixture table verbatim (so the AC
// catalogue references them one-to-one), which means this file opts out of
// lowerCamelCase for the `seedMapping` / `peerRecords` / `noPaletteRecord` names.
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/dataset/seed_dataset.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_outcome_endpoint.dart';
import 'package:paint_color_assistant/sharing/exchange/exchange_scheduler.dart';
import 'package:paint_color_assistant/sharing/exchange/gossip_exchange.dart';
import 'package:paint_color_assistant/sharing/exchange/seen_set.dart';
import 'package:paint_color_assistant/sharing/merge/crowd_refine.dart';
import 'package:paint_color_assistant/sharing/merge/evidence_merge.dart';
import 'package:paint_color_assistant/sharing/merge/mapping_evidence_endpoint.dart';
import 'package:paint_color_assistant/sharing/merge/source_rate_limiter.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';
import 'package:paint_color_assistant/sharing/record/record_builder.dart';
import 'package:paint_color_assistant/sharing/record/record_inspect_endpoint.dart';
import 'package:paint_color_assistant/sharing/inactive_peer_transport.dart';
import 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';
import 'fake_peer_transport.dart';

// Re-export the pending gate, the fake transport and the shared fakes so an AC
// test only needs to import this harness.
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export 'fake_peer_transport.dart';
export 'pending.dart';

// Re-export the sharing, domain and colour types the AC tests build scenarios
// from, so an AC test imports only this harness.
export 'package:paint_color_assistant/color_science/color_science.dart'
    show CIELCh;
export 'package:paint_color_assistant/dataset/seed_dataset.dart'
    show CandidateMapping, SeedOrigin;
export 'package:paint_color_assistant/domain/color_coordinates.dart';
export 'package:paint_color_assistant/domain/provenance.dart';
export 'package:paint_color_assistant/domain/sample.dart'
    show EvidenceKind, EvidencePoint, Sample;
export 'package:paint_color_assistant/sharing/consent/sharing_consent.dart';
export 'package:paint_color_assistant/sharing/exchange/exchange_outcome_endpoint.dart';
export 'package:paint_color_assistant/sharing/exchange/exchange_scheduler.dart';
export 'package:paint_color_assistant/sharing/exchange/gossip_exchange.dart';
export 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
export 'package:paint_color_assistant/sharing/exchange/seen_set.dart';
export 'package:paint_color_assistant/sharing/merge/crowd_refine.dart';
export 'package:paint_color_assistant/sharing/merge/evidence_merge.dart';
export 'package:paint_color_assistant/sharing/merge/mapping_evidence_endpoint.dart';
export 'package:paint_color_assistant/sharing/merge/source_rate_limiter.dart';
export 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';
export 'package:paint_color_assistant/sharing/record/record_builder.dart';
export 'package:paint_color_assistant/sharing/record/record_inspect_endpoint.dart';
export 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';

// ---------------------------------------------------------------------------
// Colour helper — the real CIELAB → CIELCh the record carries.
// ---------------------------------------------------------------------------

/// The real colour-science engine, used to derive the CIELCh form of a record's
/// measured colour from its canonical CIELAB — never a hand-faked conversion, so
/// a record's two colour forms are consistent the way production builds them.
const ColorScience sharingColorScience = ColorScienceImpl();

/// Builds a [MeasuredColour] for [lab] with its CIELCh form computed by the real
/// [sharingColorScience]. The record's canonical form rounds both to 2 dp, so
/// two readings closer than that collapse to the same content hash (D-7).
MeasuredColour measuredColourOf(ColorCoordinates lab) {
  final CIELCh lch = sharingColorScience.toCIELCh(lab);
  return MeasuredColour(
    lab: lab,
    lch: CielchCoordinates(
      lightness: lch.lightness,
      chroma: lch.chroma,
      hue: lch.hue,
    ),
  );
}

// ---------------------------------------------------------------------------
// Fixtures — the master plan's fixture table.
// ---------------------------------------------------------------------------

/// The declared palette (brand/line/medium) a shareable record carries — the
/// only palette context that crosses the boundary (D-8). Present (all three
/// parts known) so a record built with it is interpretable and shareable.
const DeclaredPalette seedPalette = DeclaredPalette(
  brand: 'Winsor & Newton',
  line: 'Professional',
  medium: 'watercolour',
);

/// `seedMapping` — a bs-13 SEED [CandidateMapping] the LLM proposed (origin
/// [SeedOrigin.llmSeed]), so its value is **Estimated** until evidence refines
/// it. The crowd-refinement ACs (AC-8..AC-11) start from this.
const CandidateMapping seedMapping = CandidateMapping(
  targetDescriptor: 'warm grey',
  candidatePaintIds: <String>[
    'wn-titanium-white',
    'wn-ivory-black',
    'wn-yellow-ochre',
  ],
);

/// The Estimated starting value of [seedMapping] in canonical CIELAB — the point
/// crowd evidence refines toward (AC-8) and that the never-promote invariant
/// keeps Estimated (AC-9).
const ColorCoordinates seedMappingValue =
    ColorCoordinates(lightness: 62, a: 2, b: 6);

/// The canonical paint combination behind [seedMapping] (sorted, deduplicated).
final PaintCombination seedCombination =
    PaintCombination.of(seedMapping.candidatePaintIds);

/// `confirmedEvidence` — the painter's own measured swatch for [seedMapping]
/// (a card-calibrated photograph → [EvidenceKind.photographedSwatch]), the mix a
/// shareable record is built *from* (AC-3/AC-4). Carried as a [Sample] so the
/// record builder consumes it exactly as production will.
final Sample confirmedEvidence = Sample(
  coordinates: seedMappingValue,
  provenance: const Provenance(ProvenanceTier.confirmed),
  name: 'my warm grey mix',
  // The mix's recipe — the paints it was made from (bs-04). RECORD-2 carries
  // this as the record's anonymous paint combination; it is the one input the
  // builder sources the combination from (the frozen `prepare(Sample, {palette})`
  // takes no combination arg), so a shareable record is a recipe-bearing Sample.
  paintIds: seedMapping.candidatePaintIds,
  evidence: const <EvidencePoint>[
    EvidencePoint(
      coordinates: seedMappingValue,
      source: 'own-swatch',
      kind: EvidenceKind.photographedSwatch,
    ),
  ],
);

/// `noPaletteRecord` — a candidate record whose declared palette is **absent**
/// (empty brand/line/medium ⇒ [DeclaredPalette.isPresent] false), so it is not
/// interpretable and must be excluded from the share-set (AC-5).
///
/// Its combination, measured colour and `cardLess` tier match the interpretable
/// control (`peerRecords(1).single`) exactly, so the declared-palette presence
/// is the *only* axis separating a shared record from an excluded one — the AC-5
/// exclusion can only be palette-driven, never an accident of tier.
final MixAccuracyRecord noPaletteRecord = MixAccuracyRecord(
  paintCombination: seedCombination,
  declaredPalette: const DeclaredPalette(),
  measuredColour: measuredColourOf(seedMappingValue),
  tier: MeasurementTier.cardLess,
);

/// `peerRecords(n, spread, outlier?)` — [n] mix-accuracy records for
/// [seedMapping], their measured colours clustered around [seedMappingValue]
/// with a controlled CIELAB [spread] (the step between adjacent records), plus
/// one far statistical [outlier] when asked.
///
/// Deterministic — no RNG — so the suite is reproducible. The cluster is
/// centred on [seedMappingValue] and symmetric, and every record's colour is
/// distinct (monotonic offsets), so none collapses by content hash unless a
/// caller deliberately repeats one. AC-8 (tight cluster + outlier), AC-11 (tight
/// cluster + far outlier) and AC-12 (volume from one source) build on this.
List<MixAccuracyRecord> peerRecords(
  int n, {
  double spread = 0.4,
  bool outlier = false,
  DeclaredPalette palette = seedPalette,
  PaintCombination? combination,
  MeasurementTier tier = MeasurementTier.cardLess,
}) {
  final PaintCombination combo = combination ?? seedCombination;
  final List<MixAccuracyRecord> records = <MixAccuracyRecord>[];
  for (var i = 0; i < n; i++) {
    final double offset = (i - (n - 1) / 2.0) * spread;
    final ColorCoordinates lab = ColorCoordinates(
      lightness: seedMappingValue.lightness + offset,
      a: seedMappingValue.a + offset * 0.5,
      b: seedMappingValue.b - offset * 0.5,
    );
    records.add(MixAccuracyRecord(
      paintCombination: combo,
      declaredPalette: palette,
      measuredColour: measuredColourOf(lab),
      tier: tier,
    ));
  }
  if (outlier) {
    const ColorCoordinates far = ColorCoordinates(
      lightness: 22,
      a: 42,
      b: -38,
    );
    records.add(MixAccuracyRecord(
      paintCombination: combo,
      declaredPalette: palette,
      measuredColour: measuredColourOf(far),
      tier: tier,
    ));
  }
  return records;
}

/// Tags each of [records] with a distinct source id (`peer-0`, `peer-1`, …, or
/// [source] when given), as they arrive at the merge from distinct devices
/// (AC-10). An [EvidencePoint.source] the merge stamps comes from here.
List<SourcedRecord> sourcedFromDistinctPeers(
  Iterable<MixAccuracyRecord> records, {
  String Function(int index)? source,
}) {
  final String Function(int) name = source ?? (i) => 'peer-$i';
  var i = 0;
  return <SourcedRecord>[
    for (final MixAccuracyRecord r in records)
      SourcedRecord(source: name(i++), record: r),
  ];
}

/// Tags every one of [records] with the **same** [source] id — the single-source
/// flood the per-source rate limit bounds (AC-12).
List<SourcedRecord> sourcedFromOnePeer(
  Iterable<MixAccuracyRecord> records, {
  String source = 'flooder',
}) =>
    <SourcedRecord>[
      for (final MixAccuracyRecord r in records)
        SourcedRecord(source: source, record: r),
    ];

// ---------------------------------------------------------------------------
// twoInstalls — two real installs over one fake loopback transport.
// ---------------------------------------------------------------------------

/// One painter's install: the real sharing services, wired exactly as
/// production wires them, over this install's [transport] view of the shared
/// fake network. The gossip/merge/refine logic under test is real; nothing here
/// is faked but the transport.
class SharingInstall {
  /// Builds an install [id] over [transport], offering [ownRecords] to peers.
  SharingInstall({
    required this.id,
    required this.transport,
    List<MixAccuracyRecord> ownRecords = const <MixAccuracyRecord>[],
  })  : ownRecords = List<MixAccuracyRecord>.of(ownRecords),
        seenSet = SeenSet(),
        recordBuilder = const EvidenceRecordBuilder(),
        merge = const EvidenceMerge(),
        refine = const CrowdRefine(),
        rateLimiter = SourceRateLimiter() {
    gossip = GossipExchange(transport: transport, seenSet: seenSet);
    scheduler = ExchangeScheduler(gossip);
  }

  /// This install's stable source/device id.
  final String id;

  /// This install's view of the shared fake network.
  final FakePeerTransport transport;

  /// The records this install would offer to peers.
  final List<MixAccuracyRecord> ownRecords;

  /// The real per-device dedup memory (keyed by content hash, D-7).
  final SeenSet seenSet;

  /// The real record builder (prepare + share-set selection).
  final RecordBuilder recordBuilder;

  /// The real append-only source-tagged evidence merge (AC-10).
  final EvidenceMerge merge;

  /// The real crowd-refine estimator (AC-8/AC-11) that never promotes (AC-9).
  final CrowdRefine refine;

  /// The real per-source rate limiter (AC-12).
  final SourceRateLimiter rateLimiter;

  /// The real transport-agnostic gossip exchange over [transport].
  late final GossipExchange gossip;

  /// The real fire-and-forget scheduler driving [gossip] (AC-2/AC-7).
  late final ExchangeScheduler scheduler;
}

/// `twoInstalls` — installs A and B over one fake loopback [FakeLocalNetwork],
/// each offering its own record set. [peersReachable] false drives the AC-7
/// "no peer reachable" case.
class TwoInstalls {
  /// Pairs the shared [network] with its two [a]/[b] installs.
  TwoInstalls({required this.network, required this.a, required this.b});

  /// The shared fake medium both installs exchange over.
  final FakeLocalNetwork network;

  /// Install A.
  final SharingInstall a;

  /// Install B.
  final SharingInstall b;
}

/// Builds the `twoInstalls` fixture: two [SharingInstall]s on one shared fake
/// network, A offering [aRecords] and B offering [bRecords].
TwoInstalls twoInstalls({
  List<MixAccuracyRecord> aRecords = const <MixAccuracyRecord>[],
  List<MixAccuracyRecord> bRecords = const <MixAccuracyRecord>[],
  bool peersReachable = true,
}) {
  final FakeLocalNetwork network = FakeLocalNetwork()
    ..peersReachable = peersReachable;
  final SharingInstall a = SharingInstall(
    id: 'install-A',
    transport: network.join('install-A', offering: aRecords),
    ownRecords: aRecords,
  );
  final SharingInstall b = SharingInstall(
    id: 'install-B',
    transport: network.join('install-B', offering: bRecords),
    ownRecords: bRecords,
  );
  return TwoInstalls(network: network, a: a, b: b);
}

// ---------------------------------------------------------------------------
// Given/When/Then — the consent surface, booted from the real app.
// ---------------------------------------------------------------------------

/// A booted bs-14 app observed through its consent read endpoint.
///
/// [consentEndpoint] is the wired [SharingConsentReadEndpoint] (AC-1/AC-2 read
/// its [consented], [offerCopy] and the [userFacingSharingSurfaces] inventory);
/// the faked platform sinks are exposed for the "nothing is spoken/buzzed"
/// checks.
class SharingAppHarness {
  /// Wraps the booted app's [tester] and its read [consentEndpoint].
  SharingAppHarness(
    this.tester, {
    required this.consentEndpoint,
    required this.speech,
    required this.haptics,
  });

  /// The driver for the booted app.
  final WidgetTester tester;

  /// The wired consent read endpoint.
  final SharingConsentReadEndpoint consentEndpoint;

  /// The faked speech sink.
  final FakeSpeech speech;

  /// The faked haptics sink.
  final FakeHaptics haptics;

  /// Whether the painter has opted in.
  bool get consented => consentEndpoint.consented;

  /// The plain-language offer copy presented to the painter (AC-1).
  String get offerCopy => consentEndpoint.offerCopy;

  /// Every user-visible sharing surface the subsystem exposes — the inventory
  /// the invisibility guarantee reads (AC-1/AC-2).
  List<String> get userFacingSharingSurfaces =>
      consentEndpoint.userFacingSharingSurfaces;
}

/// Boots the real app through `buildApp` with a persistent [store] wired (so the
/// `SharingScope` and `SharingConsentReadEndpoint` mount, CORE-2) and returns a
/// [SharingAppHarness] observing the consent surface.
///
/// A fresh [InMemoryPersistentStore] is used when [store] is omitted, so the
/// app holds the not-opted-in consent default. The app opens on its default
/// route; the endpoint is mounted at the app root regardless of route.
Future<SharingAppHarness> givenTheSharingApp(
  WidgetTester tester, {
  PersistentStore? store,
}) async {
  // Open a fresh app each time (mirrors the sibling harnesses) so a repeated
  // `given` in one test does not reuse a prior tree's State.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final FakeSpeech speech = FakeSpeech();
  final FakeHaptics haptics = FakeHaptics();
  final AppDependencies deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    store: store ?? InMemoryPersistentStore(),
    // The app-boot consent surface (AC-1/AC-2) is observed here; the real
    // exchange is faked through the twoInstalls loopback path, so pin the inert
    // transport so an opted-in boot does not start real local-network discovery
    // (which would open a socket / leave a pending timer under flutter-tester).
    peerTransport: const InactivePeerTransport(),
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();

  final SharingConsentReadEndpoint endpoint = tester
      .widget<SharingConsentReadEndpoint>(
          find.byKey(SharingConsentReadEndpoint.endpointKey));
  return SharingAppHarness(
    tester,
    consentEndpoint: endpoint,
    speech: speech,
    haptics: haptics,
  );
}

// ---------------------------------------------------------------------------
// When/Then — the record / exchange / merge surfaces, read through the sibling
// endpoints the harness builds over the real service output.
// ---------------------------------------------------------------------------

/// Runs one fire-and-forget gossip round for [install] over its own records and
/// waits only for the *suite's* observation of the settled background round —
/// never on behalf of a core flow. Returns the install's running
/// [ExchangeOutcome] (whose [ExchangeOutcome.waitedOnExchange] stays false).
Future<ExchangeOutcome> runExchange(SharingInstall install) async {
  install.scheduler.trigger(install.ownRecords);
  await install.scheduler.settled;
  return install.scheduler.outcome;
}

/// Wraps an [ExchangeOutcome] in the [ExchangeOutcomeEndpoint] the exchange ACs
/// read (AC-6/AC-7), exactly as a behaviour phase will mount it.
ExchangeOutcomeEndpoint exchangeEndpoint(ExchangeOutcome outcome) =>
    ExchangeOutcomeEndpoint(outcome: outcome, child: const SizedBox.shrink());

/// Wraps the record builder's [prepared] record and [shareSet] selection in the
/// [RecordInspectEndpoint] the record ACs read (AC-3/AC-4/AC-5).
RecordInspectEndpoint recordEndpoint({
  MixAccuracyRecord? prepared,
  List<MixAccuracyRecord> shareSet = const <MixAccuracyRecord>[],
}) =>
    RecordInspectEndpoint(
      prepared: prepared,
      shareSet: shareSet,
      child: const SizedBox.shrink(),
    );

/// Wraps a refined mapping in the [MappingEvidenceEndpoint] the merge/refine ACs
/// read (AC-8..AC-12) — its derived [value], source-tagged [evidence], derived
/// [tier] and the user-facing [label].
MappingEvidenceEndpoint mappingEndpoint({
  required ColorCoordinates value,
  List<EvidencePoint> evidence = const <EvidencePoint>[],
  ProvenanceTier tier = ProvenanceTier.estimated,
  String label = 'Estimated — not yet verified',
}) =>
    MappingEvidenceEndpoint(
      view: MappingEvidenceView(
        value: value,
        evidence: evidence,
        tier: tier,
        label: label,
      ),
      child: const SizedBox.shrink(),
    );
