import 'package:flutter/material.dart';

import '../../app/build_app.dart';
import '../../store/cvd_profile_store.dart';
import '../../store/persistent_store.dart';
import '../engine/assessment_engine.dart';
import '../onboarding_controller.dart';
import '../cvd_profile_read_endpoint.dart';
import '../onboarding_read_endpoint.dart';
import 'onboarding_screen.dart';

/// The self-assessment onboarding home: owns the [OnboardingController] and
/// mounts the read endpoints the acceptance suite observes (bs-07 FLOW-1).
///
/// Symmetric to the capture / comparison / recipes / palette homes in
/// `build_app.dart`: it builds the controller once, wraps its subtree in the
/// [CvdProfileReadEndpoint] (so a test can read the persisted profile and its
/// count — AC-13) and the [OnboardingReadEndpoint] (so a test can read the
/// assessment state), and renders the [OnboardingScreen] over the controller.
///
/// The profile store is resolved from the enclosing [AppScope] when present
/// (production assembly and the acceptance harness both inject a
/// [AppDependencies.store]); when no scope or store is wired — the bs-06
/// router/card unit tests push this entry under a bare `MaterialApp` — it falls
/// back to an in-memory store so the shell still boots. The save itself is inert
/// until PROFILE-2; nothing is written to the store yet.
class OnboardingHost extends StatefulWidget {
  /// Creates the onboarding home, placing [scaffoldKey] on the screen's
  /// [Scaffold] (the stable `self-assessment-entry-screen` anchor, bs-06 D-7).
  const OnboardingHost({this.scaffoldKey, super.key});

  /// The key the entry anchor is found by (threaded onto the screen's Scaffold).
  final Key? scaffoldKey;

  @override
  State<OnboardingHost> createState() => _OnboardingHostState();
}

class _OnboardingHostState extends State<OnboardingHost> {
  OnboardingController? _controller;
  CvdProfileStore? _profileStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller and resolve the profile store once, over the
    // dependencies injected above (if any).
    if (_controller == null) {
      final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
      final store = scope?.dependencies.store ?? InMemoryPersistentStore();
      _profileStore = CvdProfileStore(store);
      // The production flow scores through the real tiered engine (ENGINE-3 on);
      // the controller's own default stays the shell stand-in for bare tests.
      // The live-pipeline reconfiguration on save (AC-13, D-3) rides the
      // [LiveProfileScope] mounted by `buildApp`; it is null when the host is
      // pumped outside the app (the save then only writes the store).
      _controller = OnboardingController(
        engine: const TieredAssessmentEngine(),
        profileStore: _profileStore,
        onProfileSaved: LiveProfileScope.of(context),
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
    return CvdProfileReadEndpoint(
      key: CvdProfileReadEndpoint.endpointKey,
      store: _profileStore!,
      child: OnboardingReadEndpoint(
        key: OnboardingReadEndpoint.endpointKey,
        controller: _controller!,
        child: OnboardingScreen(
          controller: _controller!,
          scaffoldKey: widget.scaffoldKey,
        ),
      ),
    );
  }
}
