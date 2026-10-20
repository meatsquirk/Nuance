import 'package:flutter/material.dart';

import '../app/app_top_bar.dart';
import '../app/build_app.dart';
import '../domain/sample.dart';
import '../widgets/mono_label.dart';
import '../widgets/speak_button.dart';
import '../widgets/surface_card.dart';
import 'actions_bar.dart';
import 'name_header.dart';
import 'provenance_region.dart';
import 'readout_controller.dart';
import 'space_selector.dart';
import 'temperature_line.dart';
import 'value_region.dart';

/// The Readout screen: the single surface the painter reads a sample through.
///
/// It owns a [ReadoutController] built from the app-injected services
/// ([AppScope]) and lays out every region — name, value + grayscale, temperature,
/// colour-space selector, provenance and the actions bar — so the acceptance
/// finders and the behaviour phases have stable anchors. This shell renders
/// placeholders; each region's real reading lands in its behaviour phase.
class ReadoutScreen extends StatefulWidget {
  const ReadoutScreen({required this.sample, super.key});

  /// The sample this screen reads.
  final Sample sample;

  @override
  State<ReadoutScreen> createState() => _ReadoutScreenState();
}

class _ReadoutScreenState extends State<ReadoutScreen> {
  ReadoutController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once, from the injected services above this screen.
    if (_controller == null) {
      final deps = AppScope.of(context);
      _controller = ReadoutController(
        sample: widget.sample,
        colorScience: deps.colorScience,
        speech: deps.speech,
        haptics: deps.haptics,
        router: deps.router,
      );
    }
  }

  @override
  void didUpdateWidget(ReadoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different sample injected into the same screen (e.g. a new capture
    // replacing the initial sample — bs-02) updates the reading in place.
    if (!identical(widget.sample, oldWidget.sample)) {
      _controller!.load(widget.sample);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Scaffold(
      appBar: const AppTopBar(title: 'Readout', themeToggle: ThemeToggleButton()),
      // Speak is the wireframe's round accent floating speak button (AC-5): a
      // always-visible FAB, not an in-scroll control, so it reads and activates
      // without scrolling. Its key is the shared [ActionsBar.speakKey] anchor and
      // its semantic label is unchanged, so the spoken-output / eyes-free
      // siblings still land on and drive it by that label (bs-11 A11Y-2, bs-08).
      floatingActionButton: SpeakButton(
        key: ActionsBar.speakKey,
        onPressed: () => controller.speak(),
        semanticLabel: 'Speak this readout',
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _cardedRegion('Colour name', NameHeader(controller: controller)),
                const SizedBox(height: 12),
                _cardedRegion('Value', ValueRegion(controller: controller)),
                const SizedBox(height: 12),
                TemperatureLine(controller: controller),
                const SizedBox(height: 12),
                _cardedRegion(
                    'Colour space', SpaceSelector(controller: controller)),
                const SizedBox(height: 12),
                ProvenanceRegion(controller: controller),
                const SizedBox(height: 16),
                ActionsBar(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lays a readout [region] inside a [SurfaceCard] beneath its uppercase mono
/// [eyebrow] naming the field — the wireframe's carded reading treatment (AC-5).
///
/// The region keeps its own key, so the card sits *above* the region's anchor
/// (the acceptance finders read the card as the region's ancestor) and the
/// eyebrow is a sibling of the region, never a descendant of its key.
Widget _cardedRegion(String eyebrow, Widget region) {
  return SurfaceCard(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(eyebrow),
          const SizedBox(height: 8),
          region,
        ],
      ),
    ),
  );
}
