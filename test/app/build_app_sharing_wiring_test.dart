import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/sharing/sharing_read_endpoint.dart';
import 'package:paint_color_assistant/sharing/sharing_scope.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

AppDependencies _deps({PersistentStore? store}) => AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      store: store,
    );

void main() {
  testWidgets(
      'buildApp mounts the SharingScope + consent read endpoint when a store '
      'is wired (CORE-2)', (tester) async {
    await tester.pumpWidget(buildApp(_deps(store: InMemoryPersistentStore())));

    // The SharingScope is present, holding the injected consent store.
    final scope = tester.widget<SharingScope>(find.byType(SharingScope));
    expect(scope.dependencies.consentStore, isNotNull);

    // The read endpoint the acceptance suite observes: the shell exposes the
    // not-opted-in default and an empty-of-network surface inventory (AC-1).
    final endpoint = tester.widget<SharingConsentReadEndpoint>(
      find.byKey(SharingConsentReadEndpoint.endpointKey),
    );
    expect(endpoint.consented, isFalse);
    expect(endpoint.offerCopy, 'help improve recipe accuracy by sharing anonymous mix results');
    expect(endpoint.userFacingSharingSurfaces, isEmpty);
  });

  testWidgets('buildApp mounts no SharingScope when no store is wired',
      (tester) async {
    await tester.pumpWidget(buildApp(_deps()));
    expect(find.byType(SharingScope), findsNothing);
    expect(find.byKey(SharingConsentReadEndpoint.endpointKey), findsNothing);
  });
}
