import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';

Widget _host({int radiusPx = 5}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: CaptureEyedropper(radiusPx: radiusPx),
        ),
      ),
    );

void main() {
  testWidgets('renders a findable centred reticle', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget);
    expect(find.byKey(CaptureEyedropper.reticleKey), findsOneWidget);
  });

  testWidgets('sizes the reticle to the selected radius (1→8, 5→20, 21→44)',
      (tester) async {
    for (final entry in CaptureEyedropper.reticleSizeByRadiusPx.entries) {
      await tester.pumpWidget(_host(radiusPx: entry.key));
      final reticle = tester.getSize(find.byKey(CaptureEyedropper.reticleKey));
      expect(reticle.width, entry.value,
          reason: 'radius ${entry.key} px → reticle ${entry.value} px');
      expect(reticle.height, entry.value, reason: 'the reticle is square');
    }
  });

  testWidgets('defaults an off-scale radius to the default reticle size',
      (tester) async {
    // 3 px is not a selectable radius; the marker falls back to the default
    // size rather than vanishing.
    await tester.pumpWidget(_host(radiusPx: 3));
    final reticle = tester.getSize(find.byKey(CaptureEyedropper.reticleKey));
    expect(reticle.width, CaptureEyedropper.placeholderReticleSize);
    expect(reticle.height, CaptureEyedropper.placeholderReticleSize);
  });

  test('maps each radius to its reticle size, falling back to the default', () {
    expect(CaptureEyedropper.reticleSizeFor(1), 8);
    expect(CaptureEyedropper.reticleSizeFor(5), 20);
    expect(CaptureEyedropper.reticleSizeFor(21), 44);
    expect(CaptureEyedropper.reticleSizeFor(3),
        CaptureEyedropper.placeholderReticleSize);
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
