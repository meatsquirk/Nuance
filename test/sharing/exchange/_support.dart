import 'dart:async';

import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

/// A mix-accuracy record keyed off [id], for tests that need distinct records.
MixAccuracyRecord record(String id) => MixAccuracyRecord(
      paintCombination: PaintCombination.of([id]),
      declaredPalette:
          const DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil'),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 50, a: 10, b: -5),
        lch: CielchCoordinates(lightness: 50, chroma: 11.18, hue: 333.4),
      ),
      tier: MeasurementTier.instrument,
    );

/// An in-process [PeerTransport] double that records how it was driven.
///
/// [discover] returns [peers]; every peer [offering]s back the same records
/// (empty by default), and each [offer] appends to [offered] so a test can read
/// exactly what crossed to peers.
class FakePeerTransport implements PeerTransport {
  FakePeerTransport({
    this.peers = const <Peer>[],
    this.offering = const <MixAccuracyRecord>[],
  });

  /// The peers [discover] returns.
  final List<Peer> peers;

  /// What every peer offers back when [receive]d from.
  final List<MixAccuracyRecord> offering;

  /// How many times [discover] was called.
  int discoverCalls = 0;

  /// Every record [offer]ed to a peer, in call order — what crossed the boundary.
  final List<MixAccuracyRecord> offered = <MixAccuracyRecord>[];

  @override
  Future<List<Peer>> discover() async {
    discoverCalls++;
    return peers;
  }

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {
    offered.addAll(records);
  }

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async => offering;
}

/// A [PeerTransport] whose [discover] only completes when [gate] does, so a test
/// can prove the scheduler returns before the round finishes.
class GatedPeerTransport implements PeerTransport {
  GatedPeerTransport(this.gate);

  /// Resolves the pending [discover] future when completed.
  final Completer<List<Peer>> gate;

  @override
  Future<List<Peer>> discover() => gate.future;

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {}

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async =>
      const <MixAccuracyRecord>[];
}

/// A [PeerTransport] whose [discover] always fails, to exercise the scheduler's
/// silent-failure path (D-5).
class ThrowingPeerTransport implements PeerTransport {
  @override
  Future<List<Peer>> discover() async => throw StateError('transport down');

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {}

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async =>
      const <MixAccuracyRecord>[];
}
