import 'package:flutter/material.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../color_science/color_science.dart';
import '../compare/comparison_controller.dart';
import '../compare/comparison_read_endpoint.dart';
import '../compare/comparison_state.dart';
import '../compare/sample_source.dart';
import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../readout/readout_screen.dart';
import 'router.dart';

/// The sample the shipped bs-01 app opens the Readout screen on.
///
/// bs-01 ships the reading surface before capture exists (capture is bs-02,
/// D-1), so there is no painter-supplied sample yet. This fixed sample gives the
/// Readout a subject to render until bs-02 wires capture into
/// [AppDependencies.initialSample]. It is a plain [Sample] (canonical CIELAB +
/// provenance) with no derived values pre-computed — every presentable form is
/// derived by the COLOR behaviour phases from these coordinates.
const Sample demoSample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

/// Opt-in that opens the app on the Comparison screen (bs-03 D-8), symmetric to
/// bs-02's capture entry.
///
/// When [AppDependencies.comparisonEntry] carries one, [buildApp] launches to
/// the [ComparisonHomeScreen] — a comparison over [AppDependencies.sampleSource]
/// for [AppDependencies.cvdProfile] via [AppDependencies.confusionCheck] — so
/// the acceptance harness and a later production shortcut both enter comparison
/// through the one assembly entry. null (the default) preserves bs-01's Readout
/// entry. A marker for now; bs-06 may extend it (e.g. a pre-selected pair).
class ComparisonEntry {
  /// Creates the comparison-entry marker.
  const ComparisonEntry();
}

/// The app-wide services assembled once at startup and injected down the tree.
///
/// A single immutable holder so production (`main.dart`) and the acceptance
/// harness (ITEST-1) construct the app the same way, differing only in which
/// implementations they pass — the harness swaps the faked platform sinks
/// ([Speech], [Haptics]) and a test [ColorScience] while reusing [buildApp].
class AppDependencies {
  const AppDependencies({
    required this.colorScience,
    required this.speech,
    required this.haptics,
    this.router = const AppRouter(),
    this.initialSample = demoSample,
    this.cvdProfile = const CvdProfile(type: CvdType.deutan),
    this.confusionCheck = const NoopConfusionCheck(),
    this.sampleSource = const InMemorySampleSource(),
    this.comparisonEntry,
  });

  /// Derives every presentable form of a sample's colour (COLOR stub for now).
  final ColorScience colorScience;

  /// Spoken output sink (A11Y stub for now; faked in the acceptance suite).
  final Speech speech;

  /// Haptic feedback sink (A11Y stub for now; faked in the acceptance suite).
  final Haptics haptics;

  /// Typed navigation into the comparison / recipes destinations.
  final AppRouter router;

  /// The sample the app opens the Readout screen on.
  ///
  /// bs-01 has no capture yet (D-1), so production defaults to [demoSample]; the
  /// acceptance harness injects a fixture here to read each scenario's sample
  /// through this same [buildApp] entry (capture replaces it in bs-02).
  final Sample initialSample;

  /// The painter's colour-vision profile, read by [confusionCheck] (bs-03 D-4).
  ///
  /// Defaults to a deutan profile for bs-03's comparison scenarios; **bs-07**
  /// (CVD self-assessment) later populates it from the painter. Injected here so
  /// the confusion detector and the later simulation/daltonization features
  /// (bs-08/bs-10) all read one profile.
  final CvdProfile cvdProfile;

  /// Decides whether a compared pair is confusable for [cvdProfile] (AC-7/AC-8).
  ///
  /// Defaults to the inert [NoopConfusionCheck] so the assembled app wires the
  /// detector but flags nothing until CVD-2 supplies the dichromat projection.
  final ConfusionCheck confusionCheck;

  /// The saved-sample catalogue the comparison picker lists (bs-03 D-7).
  ///
  /// Defaults to an empty [InMemorySampleSource]; **COMPARE-3** injects one
  /// seeded with the saved samples, and **bs-06** later supplies a persistent
  /// store behind the same [SampleSource] interface. Read both by the comparison
  /// entry and by the Readout → compare handoff so a carried sample lands in a
  /// comparison that can still offer the catalogue for the other slot.
  final SampleSource sampleSource;

  /// Opens the app on the Comparison screen when present (bs-03 D-8).
  ///
  /// null (the default) keeps bs-01's Readout entry; a [ComparisonEntry] makes
  /// [buildApp] launch to the [ComparisonHomeScreen] over [sampleSource] /
  /// [cvdProfile] / [confusionCheck]. The bs-03 acceptance harness injects one
  /// to drive each comparison scenario through this same assembly entry.
  final ComparisonEntry? comparisonEntry;
}

/// Exposes the app-wide [AppDependencies] to descendant widgets.
///
/// The Readout screen and its controller (READOUT-1) read the injected services
/// through [AppScope.of] rather than constructing them, so the same screen runs
/// unchanged against the production stubs and the acceptance suite's fakes.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  /// The services injected at the root by [buildApp].
  final AppDependencies dependencies;

  /// The [AppDependencies] injected by the nearest enclosing [AppScope].
  ///
  /// Throws if no [AppScope] is above [context]; every screen built by
  /// [buildApp] has one.
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

/// Builds the root widget of the Paint Color Assistant.
///
/// The single production assembly entry (D-7): it injects [deps] via [AppScope]
/// and wires the router into a [MaterialApp]. The app opens on the
/// [ComparisonHomeScreen] when a [AppDependencies.comparisonEntry] is injected
/// (bs-03 D-8), and otherwise on the [ReadoutScreen] for
/// [AppDependencies.initialSample] (bs-01's entry). `main.dart` and the
/// acceptance harnesses construct the app through this one entry, differing only
/// in the injected services, the initial sample and the comparison entry.
Widget buildApp(AppDependencies deps) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: deps.comparisonEntry == null
          ? ReadoutScreen(sample: deps.initialSample)
          : ComparisonHomeScreen(
              sampleSource: deps.sampleSource,
              cvdProfile: deps.cvdProfile,
              confusionCheck: deps.confusionCheck,
            ),
    ),
  );
}

/// The Comparison screen the app opens on when a comparison entry is wired, and
/// the destination of the Readout → compare handoff (`AppRouter.toComparison`).
///
/// It owns the [ComparisonController] over the injected catalogue / profile /
/// detector and wraps its subtree in a [ComparisonReadEndpoint] so the
/// acceptance suite can observe the comparison state. The deps are passed in
/// (not read from [AppScope]) so the handoff route renders the carried sample
/// even when pushed outside an [AppScope] (bs-01's handoff tests); [initialA] /
/// [initialB] carry that sample into its slot.
///
/// This COMPARE-2 shell renders the two slots as a findable placeholder body —
/// enough for the entry and the handoff to assemble and the existing suites to
/// stay green. **SCREEN-1** replaces that body with the real `ComparisonScreen`
/// composing the wireframe regions (E3–E8, E49); the controller ownership and
/// the read endpoint stay here.
class ComparisonHomeScreen extends StatefulWidget {
  /// Creates the comparison home over the given catalogue / profile / detector,
  /// optionally pre-placing [initialA] / [initialB] into their slots.
  const ComparisonHomeScreen({
    this.sampleSource = const InMemorySampleSource(),
    this.cvdProfile = const CvdProfile(type: CvdType.deutan),
    this.confusionCheck = const NoopConfusionCheck(),
    this.initialA,
    this.initialB,
    super.key,
  });

  /// The saved-sample catalogue the comparison picker lists (D-7).
  final SampleSource sampleSource;

  /// The painter's colour-vision profile the confusion flag is judged against.
  final CvdProfile cvdProfile;

  /// The detector deciding whether the pair is confusable (AC-7/AC-8).
  final ConfusionCheck confusionCheck;

  /// A sample to pre-place into slot A (the Readout → compare-as-A handoff).
  final Sample? initialA;

  /// A sample to pre-place into slot B (the Readout → compare-as-B handoff).
  final Sample? initialB;

  @override
  State<ComparisonHomeScreen> createState() => _ComparisonHomeScreenState();
}

class _ComparisonHomeScreenState extends State<ComparisonHomeScreen> {
  late final ComparisonController _controller = ComparisonController(
    sampleSource: widget.sampleSource,
    confusionCheck: widget.confusionCheck,
    profile: widget.cvdProfile,
    initialA: widget.initialA,
    initialB: widget.initialB,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComparisonReadEndpoint(
      key: ComparisonReadEndpoint.endpointKey,
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _ComparisonShellBody(state: _controller.state),
      ),
    );
  }
}

/// The COMPARE-2 placeholder body: the two slots as findable text, matching
/// bs-01's handoff rendering (`Slot A: <name>` / `Slot B: (empty)`) so the
/// existing suites stay green. Replaced by SCREEN-1's region composition.
class _ComparisonShellBody extends StatelessWidget {
  const _ComparisonShellBody({required this.state});

  final ComparisonState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparison')),
      body: SafeArea(
        child: Column(
          children: [
            Text('Slot A: ${state.slotA?.name ?? '(empty)'}'),
            Text('Slot B: ${state.slotB?.name ?? '(empty)'}'),
          ],
        ),
      ),
    );
  }
}
