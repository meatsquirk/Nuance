import 'package:flutter/material.dart';

import '../app/build_app.dart';
import '../domain/sample.dart';
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
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Scaffold(
      appBar: AppBar(title: const Text('Readout')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NameHeader(controller: controller),
                const SizedBox(height: 12),
                ValueRegion(controller: controller),
                const SizedBox(height: 12),
                TemperatureLine(controller: controller),
                const SizedBox(height: 12),
                SpaceSelector(controller: controller),
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
