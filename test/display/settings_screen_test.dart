import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_scope.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/onboarding/cvd_profile_read_endpoint.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

/// Pumps the settings panel over a [DisplayScope] exposing [controller], so the
/// panel reads the live controller exactly as it does under `buildApp`.
///
/// When [profileStore] is given it is exposed above the panel through a
/// [CvdProfileReadEndpoint], exactly as `buildApp` mounts one at the app root,
/// so the no-saved-profile region (bs-10 AC-10) can consult it; omitted, the
/// panel runs with no profile store (a standalone-surface test).
Future<void> _pumpPanel(
  WidgetTester tester,
  DisplayController controller, {
  VoidCallback? onClose,
  CvdProfileStore? profileStore,
}) {
  Widget panel = DisplayScope(
    controller: controller,
    child: DisplaySettingsScreen(onClose: onClose ?? () {}),
  );
  if (profileStore != null) {
    panel = CvdProfileReadEndpoint(store: profileStore, child: panel);
  }
  return tester.pumpWidget(MaterialApp(home: panel));
}

void main() {
  group('DisplaySettingsButton (E2)', () {
    testWidgets('renders a findable, wired entry', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisplaySettingsButton(onPressed: () => opened++),
          ),
        ),
      );

      final button = tester.widget<IconButton>(
        find.byKey(DisplaySettingsButton.openKey),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byKey(DisplaySettingsButton.openKey));
      await tester.pump();
      expect(opened, 1);
    });

    test('exposes a stable key', () {
      expect(
        DisplaySettingsButton.openKey,
        const ValueKey('display-e2-open-settings'),
      );
    });

    testWidgets('exposes a meaningful screen-reader label (AC-6)',
        (tester) async {
      // The icon-only entry sits above the Navigator's Overlay, so it cannot
      // use a Tooltip; A11Y-6 labels it explicitly so a screen reader announces
      // what it does. The label must land on the button's own tappable node
      // (MergeSemantics), not an anonymous ancestor.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisplaySettingsButton(onPressed: () {}),
          ),
        ),
      );

      final data = tester
          .getSemantics(find.byKey(DisplaySettingsButton.openKey))
          .getSemanticsData();
      expect(data.label, 'Display and simulation settings');
      expect(data.hasAction(SemanticsAction.tap), isTrue,
          reason: 'the label must land on the tappable button node');
      handle.dispose();
    });
  });

  group('DisplaySettingsScreen', () {
    testWidgets('shows the simulation, grayscale and theme controls (AC-1 '
        'surface)', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      expect(find.byKey(DisplaySettingsScreen.panelKey), findsOneWidget);
      expect(find.byKey(DisplaySettingsScreen.simulationKey), findsOneWidget);
      expect(find.byKey(DisplaySettingsScreen.grayscaleKey), findsOneWidget);
      expect(find.byKey(DisplaySettingsScreen.severityKey), findsOneWidget);
      expect(find.byKey(DisplaySettingsScreen.themeKey), findsOneWidget);
    });

    testWidgets('offers off plus one option per CVD type, and shows the '
        'default type (D-2)', (tester) async {
      final controller = DisplayController(
        defaultSimulationType: CvdType.tritan,
      );
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      expect(DisplaySettingsScreen.simulationOptions,
          const [null, CvdType.protan, CvdType.deutan, CvdType.tritan]);
      for (final type in DisplaySettingsScreen.simulationOptions) {
        expect(
          find.byKey(DisplaySettingsScreen.simulationOptionKey(type)),
          findsOneWidget,
          reason: 'option for $type missing',
        );
      }
      // The panel reads defaultSimulationType to show the pre-selected type.
      expect(find.text('Default for your vision: tritan'), findsOneWidget);
    });

    testWidgets('marks the selected simulation and leaves the others unmarked',
        (tester) async {
      final controller = DisplayController()..setSimulationType(CvdType.deutan);
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      // The selected type is marked; "off" and the others are not (both label
      // branches of the mark ternary).
      expect(find.text('✓ deutan'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('protan'), findsOneWidget);
    });

    testWidgets('each option drives setSimulationType (off ⇒ null)',
        (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      await tester.tap(
        find.byKey(DisplaySettingsScreen.simulationOptionKey(CvdType.protan)),
      );
      await tester.pump();
      expect(controller.settings.simulationType, CvdType.protan);

      await tester.tap(
        find.byKey(DisplaySettingsScreen.simulationOptionKey(null)),
      );
      await tester.pump();
      expect(controller.settings.simulationType, isNull);
      expect(controller.settings.simulationOn, isFalse);
    });

    testWidgets('the grayscale toggle drives setGrayscale', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      expect(controller.settings.grayscale, isFalse);
      await tester.tap(find.byKey(DisplaySettingsScreen.grayscaleKey));
      await tester.pump();
      expect(controller.settings.grayscale, isTrue);
    });

    testWidgets('the daltonization toggle drives setDaltonization (both ways)',
        (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      // The switch reflects the (default off) setting and is findable.
      final tile = tester.widget<SwitchListTile>(
        find.byKey(DisplaySettingsScreen.daltonizationKey),
      );
      expect(tile.value, isFalse);

      // On, then off — covers both branches of setDaltonization's no-op guard.
      expect(controller.settings.daltonization, isFalse);
      await tester.tap(find.byKey(DisplaySettingsScreen.daltonizationKey));
      await tester.pump();
      expect(controller.settings.daltonization, isTrue);
      // The other axes are untouched — daltonization stands alone (D-3/D-5).
      expect(controller.settings.simulationType, isNull);
      expect(controller.settings.grayscale, isFalse);

      await tester.tap(find.byKey(DisplaySettingsScreen.daltonizationKey));
      await tester.pump();
      expect(controller.settings.daltonization, isFalse);
    });

    testWidgets('the no-saved-profile region is reachable and, with no store '
        'mounted, shows no prompt', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      // No profile store mounted (a standalone-surface test): the region is
      // present and keyed, but shows no prompt (no profile concept here).
      await _pumpPanel(tester, controller);
      await tester.pumpAndSettle();

      expect(
        find.byKey(DisplaySettingsScreen.noProfileRegionKey),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(DisplaySettingsScreen.noProfileRegionKey),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('with no saved profile it prompts for a self-assessment '
        '(AC-10)', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      // An empty profile store: nothing saved, so the control prompts for a
      // self-assessment rather than remapping against the const default (D-4).
      final store = CvdProfileStore(InMemoryPersistentStore());
      await _pumpPanel(tester, controller, profileStore: store);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(DisplaySettingsScreen.noProfileRegionKey),
          matching:
              find.textContaining(RegExp('self-assessment', caseSensitive: false)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('with a saved profile the self-assessment prompt is absent '
        '(AC-10 control)', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final store = CvdProfileStore(InMemoryPersistentStore());
      await store.save(const CvdProfile(type: CvdType.deutan, severity: 0.6));
      await _pumpPanel(tester, controller, profileStore: store);
      await tester.pumpAndSettle();

      // The region is still present (keyed) but carries no prompt — the remap
      // applies off the saved profile.
      expect(
        find.byKey(DisplaySettingsScreen.noProfileRegionKey),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(DisplaySettingsScreen.noProfileRegionKey),
          matching:
              find.textContaining(RegExp('self-assessment', caseSensitive: false)),
        ),
        findsNothing,
      );
    });

    testWidgets('the severity slider drives setSimulationSeverity over 0..1',
        (tester) async {
      final controller = DisplayController(
        initialSettings: const DisplaySettings(simulationSeverity: 0.5),
      );
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      final slider = tester.widget<Slider>(
        find.byKey(DisplaySettingsScreen.severityKey),
      );
      // The 0..1 severity is shown on the 0..100 scale.
      expect(slider.value, 50);
      // Setting 60 on the slider maps to 0.6 severity (D-6).
      slider.onChanged!(60);
      await tester.pump();
      expect(controller.settings.simulationSeverity, closeTo(0.6, 1e-9));
    });

    testWidgets('closing the panel invokes onClose', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      var closed = 0;
      await _pumpPanel(tester, controller, onClose: () => closed++);

      await tester.tap(find.byKey(DisplaySettingsScreen.closeKey));
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('the close control exposes a meaningful label (AC-6)',
        (tester) async {
      // The icon-only close control carries an explicit label on its tappable
      // node (A11Y-6 sweep) — the panel sits above the Navigator's Overlay, so
      // it cannot use a Tooltip.
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await _pumpPanel(tester, controller);

      final data = tester
          .getSemantics(find.byKey(DisplaySettingsScreen.closeKey))
          .getSemanticsData();
      expect(data.label, 'Close settings');
      expect(data.hasAction(SemanticsAction.tap), isTrue,
          reason: 'the label must land on the tappable close node');
      handle.dispose();
    });

    testWidgets('the theme control is presentation only — selecting a theme '
        'changes its mark but no display setting (D-11)', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await _pumpPanel(tester, controller);

      // Light is marked by default.
      expect(find.text('✓ Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('display-theme-dark')));
      await tester.pump();
      expect(find.text('✓ Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);

      // Back to light (both mark branches of the theme control).
      await tester.tap(find.byKey(const ValueKey('display-theme-light')));
      await tester.pump();
      expect(find.text('✓ Light'), findsOneWidget);

      // Nothing the feature grades moved.
      expect(controller.settings, const DisplaySettings());
    });

    test('exposes stable keys per wireframe element', () {
      expect(DisplaySettingsScreen.simulationKey,
          const ValueKey('display-e47-simulation'));
      expect(DisplaySettingsScreen.grayscaleKey,
          const ValueKey('display-e46-grayscale'));
      expect(DisplaySettingsScreen.severityKey,
          const ValueKey('display-e48-severity'));
      expect(
          DisplaySettingsScreen.themeKey, const ValueKey('display-theme'));
      expect(DisplaySettingsScreen.daltonizationKey,
          const ValueKey('display-bs10-daltonization'));
      expect(DisplaySettingsScreen.noProfileRegionKey,
          const ValueKey('display-bs10-no-profile'));
      expect(DisplaySettingsScreen.simulationOptionKey(CvdType.deutan),
          const ValueKey('display-e47-sim-deutan'));
      expect(DisplaySettingsScreen.simulationOptionKey(null),
          const ValueKey('display-e47-sim-off'));
    });
  });
}
