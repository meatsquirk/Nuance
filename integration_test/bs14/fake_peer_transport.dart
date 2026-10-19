// In-process loopback [PeerTransport] for the bs-14 acceptance suite (ITEST-1).
//
// The acceptance suite exercises the *real* gossip/merge/refine logic over real
// mix-accuracy records; the **only** thing it fakes is the off-device actor
// (D-3): the mDNS/socket transport EXCHANGE-4 ships for real is replaced here by
// an in-memory loopback so two "installs" can exchange records without a
// network. The fake models exactly the three operations the real transport
// contract exposes — [PeerTransport.discover], [PeerTransport.offer],
// [PeerTransport.receive] — and nothing more, so a test that passes over it
// would pass over the real transport too.
//
// A [FakeLocalNetwork] is the shared medium: installs [FakeLocalNetwork.join]
// it, each getting its own [FakePeerTransport] view. Through that view an
// install [discover]s the *other* joined installs, [offer]s records that land
// in the target's inbox, and [receive]s whatever a peer is currently offering.
// [FakeLocalNetwork.peersReachable] set false makes [discover] return none — the
// AC-7 "no peer reachable" case — without tearing the network down.

import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

/// One install's presence on the [FakeLocalNetwork]: what it offers to peers and
/// what peers have offered it.
class _Node {
  _Node(this.id);

  /// The install's stable source/device id (the real transport assigns an
  /// opaque per-session id; the suite uses a readable one so assertions name it).
  final String id;

  /// The records this install currently offers to peers (read by [receive]).
  List<MixAccuracyRecord> offering = const <MixAccuracyRecord>[];

  /// The records other installs have offered to this one (written by [offer]).
  final List<MixAccuracyRecord> inbox = <MixAccuracyRecord>[];
}

/// The shared in-memory medium two (or more) installs exchange over.
///
/// Models the local network the real transport discovers peers on: every joined
/// install can see every other, offer records into another's inbox, and read
/// another's offering. It keeps no concept of distance or addressing beyond the
/// opaque ids, matching the account-free [PeerTransport] contract.
class FakeLocalNetwork {
  final Map<String, _Node> _nodes = <String, _Node>{};

  /// Whether peers are reachable right now. Set false to drive the AC-7
  /// "no peer reachable" case: [FakePeerTransport.discover] then returns an
  /// empty list for every install, exactly as the real transport does when it
  /// finds nobody on the network.
  bool peersReachable = true;

  /// Joins an install identified by [id], offering [offering] to its peers, and
  /// returns the [PeerTransport] view it talks to the network through. Re-joining
  /// the same [id] replaces that install's offering.
  FakePeerTransport join(
    String id, {
    List<MixAccuracyRecord> offering = const <MixAccuracyRecord>[],
  }) {
    final node = _nodes.putIfAbsent(id, () => _Node(id))
      ..offering = List<MixAccuracyRecord>.of(offering);
    return FakePeerTransport._(this, node);
  }

  /// The records install [id] has been offered so far (what peers delivered via
  /// [FakePeerTransport.offer]). Read by the exchange ACs to assert what crossed.
  List<MixAccuracyRecord> inboxOf(String id) =>
      List<MixAccuracyRecord>.unmodifiable(
          _nodes[id]?.inbox ?? const <MixAccuracyRecord>[]);

  List<Peer> _discover(_Node self) {
    if (!peersReachable) return const <Peer>[];
    return <Peer>[
      for (final node in _nodes.values)
        if (node.id != self.id) Peer(node.id),
    ];
  }

  void _offer(Peer peer, List<MixAccuracyRecord> records) {
    _nodes[peer.id]?.inbox.addAll(records);
  }

  List<MixAccuracyRecord> _receive(Peer peer) =>
      List<MixAccuracyRecord>.unmodifiable(
          _nodes[peer.id]?.offering ?? const <MixAccuracyRecord>[]);
}

/// One install's view of the [FakeLocalNetwork] — a real [PeerTransport].
///
/// Obtained from [FakeLocalNetwork.join]. Every call is counted so the exchange
/// ACs can assert *that* discovery happened (AC-6) or *did not block* a core
/// flow (AC-7) without reaching into the gossip layer.
class FakePeerTransport implements PeerTransport {
  FakePeerTransport._(this._network, this._self);

  final FakeLocalNetwork _network;
  final _Node _self;

  /// How many times [discover] has been called on this view.
  int discoverCalls = 0;

  /// How many times [offer] has been called on this view.
  int offerCalls = 0;

  /// How many times [receive] has been called on this view.
  int receiveCalls = 0;

  @override
  Future<List<Peer>> discover() async {
    discoverCalls++;
    return _network._discover(_self);
  }

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {
    offerCalls++;
    _network._offer(peer, records);
  }

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async {
    receiveCalls++;
    return _network._receive(peer);
  }
}
