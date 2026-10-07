import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';

Widget _host() => const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: CaptureEyedropper(),
        ),
      ),
    );

void main() {
  testWidgets('renders a findable centred reticle', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget);
    expect(find.byKey(CaptureEyedropper.reticleKey), findsOneWidget);
  });

  testWidgets('sizes the reticle to the placeholder size', (tester) async {
    await tester.pumpWidget(_host());

    final reticle = tester.getSize(find.byKey(CaptureEyedropper.reticleKey));
    expect(reticle.width, CaptureEyedropper.placeholderReticleSize);
    expect(reticle.height, CaptureEyedropper.placeholderReticleSize);
  });

  testWidgets('centres the reticle in its host', (tester) async {
    await tester.pumpWidget(_host());

    // The reticle centre sits at the host centre (the 300x400 SizedBox).
    final reticleCentre =
        tester.getCenter(find.byKey(CaptureEyedropper.reticleKey));
    final hostCentre = tester.getCenter(find.byType(SizedBox).first);
    expect(reticleCentre, hostCentre);
  });

  test('exposes stable keys', () {
    expect(CaptureEyedropper.eyedropperKey, const ValueKey('capture-eyedropper'));
    expect(CaptureEyedropper.reticleKey, const ValueKey('capture-reticle'));
  });
}
