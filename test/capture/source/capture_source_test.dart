import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';

void main() {
  test('stability target is 12 frames', () {
    expect(kStabilityFrameTarget, 12);
  });

  group('CaptureLocks', () {
    test('defaults to nothing locked', () {
      // Built non-const so the const constructor is covered at runtime.
      // ignore: prefer_const_constructors
      final locks = CaptureLocks();
      expect(locks.exposure, isFalse);
      expect(locks.whiteBalance, isFalse);
      expect(locks.focus, isFalse);
      expect(locks.allLocked, isFalse);
    });

    test('allLocked only once AE, AWB and AF are all locked', () {
      const partial = CaptureLocks(exposure: true, whiteBalance: true);
      expect(partial.allLocked, isFalse);
      const all = CaptureLocks(exposure: true, whiteBalance: true, focus: true);
      expect(all.allLocked, isTrue);
    });

    test('copyWith replaces each lock independently', () {
      const base = CaptureLocks();
      expect(base.copyWith(exposure: true).exposure, isTrue);
      expect(base.copyWith(whiteBalance: true).whiteBalance, isTrue);
      expect(base.copyWith(focus: true).focus, isTrue);
      // Unset fields are carried through.
      expect(base.copyWith(exposure: true).focus, isFalse);
    });

    test('equality and hashCode track all three locks', () {
      const a = CaptureLocks(exposure: true);
      const b = CaptureLocks(exposure: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(const CaptureLocks(focus: true))));
    });

    test('unequal to a non-CaptureLocks object', () {
      const locks = CaptureLocks();
      // ignore: unrelated_type_equality_checks
      final isEqual = locks == 'x';
      expect(isEqual, isFalse);
    });

    test('toString reports each lock', () {
      expect(
        const CaptureLocks(exposure: true).toString(),
        'CaptureLocks(AE true, AWB false, AF false)',
      );
    });
  });

  group('StabilityReading', () {
    test('defaults the required frames to the stability target', () {
      // Built non-const so the const constructor is covered at runtime.
      // ignore: prefer_const_constructors
      final reading = StabilityReading(settledFrames: 6);
      expect(reading.requiredFrames, kStabilityFrameTarget);
      expect(reading.settledFrames, 6);
    });

    test('is stable only once enough frames have settled', () {
      expect(const StabilityReading(settledFrames: 11).isStable, isFalse);
      expect(const StabilityReading(settledFrames: 12).isStable, isTrue);
      expect(const StabilityReading(settledFrames: 13).isStable, isTrue);
    });

    test('equality and hashCode track both counts', () {
      const a = StabilityReading(settledFrames: 6);
      const b = StabilityReading(settledFrames: 6);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(
        a,
        isNot(equals(const StabilityReading(settledFrames: 6, requiredFrames: 8))),
      );
      expect(a, isNot(equals(const StabilityReading(settledFrames: 7))));
    });

    test('unequal to a non-StabilityReading object', () {
      const reading = StabilityReading(settledFrames: 6);
      // ignore: unrelated_type_equality_checks
      final isEqual = reading == 'x';
      expect(isEqual, isFalse);
    });

    test('toString reports the fraction', () {
      expect(
        const StabilityReading(settledFrames: 6).toString(),
        'StabilityReading(6/12)',
      );
    });
  });

  test('Lighting names both tiers', () {
    expect(Lighting.values, [Lighting.adequate, Lighting.low]);
  });
}
