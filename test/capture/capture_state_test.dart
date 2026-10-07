import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/sampling.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _sample = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
  provenance: Provenance(ProvenanceTier.measured),
);

void main() {
  group('defaults', () {
    const state = CaptureState();

    test('auto exposure, settling at 0, 5 px radius, approximate accuracy', () {
      expect(state.lockState, LockState.auto);
      expect(state.stabilityCount, 0);
      expect(state.radiusPx, kDefaultSamplingRadiusPx);
      expect(state.accuracy, CaptureAccuracy.approximate);
      expect(state.valueOnly, isFalse);
      expect(state.lowLightWarning, isFalse);
      expect(state.currentSample, isNull);
      expect(state.lastCommittedSample, isNull);
      expect(state.framesAveraged, 0);
    });
  });

  group('stability', () {
    test('settling below the target reads "SETTLING n/12"', () {
      const state = CaptureState(stabilityCount: 6);
      expect(state.isStable, isFalse);
      expect(state.stabilityText, 'SETTLING 6/12');
    });

    test('reaching the target reads "STABLE 12/12"', () {
      const state = CaptureState(stabilityCount: kStabilityFrameTarget);
      expect(state.isStable, isTrue);
      expect(state.stabilityText, 'STABLE 12/12');
    });

    test('locking reads "STABLE 12/12" even before the count settles', () {
      const state =
          CaptureState(lockState: LockState.locked, stabilityCount: 6);
      expect(state.isStable, isFalse);
      expect(state.stabilityText, 'STABLE 12/12');
    });
  });

  group('lock indicator', () {
    test('reads "AE · AWB · AF AUTO" while unlocked', () {
      const state = CaptureState();
      expect(state.lockIndicatorText, 'AE · AWB · AF AUTO');
    });

    test('reads "AE · AWB · AF LOCKED" once locked', () {
      const state = CaptureState(lockState: LockState.locked);
      expect(state.lockIndicatorText, 'AE · AWB · AF LOCKED');
    });
  });

  group('copyWith', () {
    const base = CaptureState();

    test('no arguments returns an equal-valued copy', () {
      expect(base.copyWith(), base);
    });

    test('replaces every field when given', () {
      final copy = base.copyWith(
        lockState: LockState.locked,
        stabilityCount: 12,
        radiusPx: 21,
        accuracy: CaptureAccuracy.calibrated,
        valueOnly: true,
        lowLightWarning: true,
        currentSample: _sample,
        lastCommittedSample: _sample,
        framesAveraged: 8,
      );
      expect(copy.lockState, LockState.locked);
      expect(copy.stabilityCount, 12);
      expect(copy.radiusPx, 21);
      expect(copy.accuracy, CaptureAccuracy.calibrated);
      expect(copy.valueOnly, isTrue);
      expect(copy.lowLightWarning, isTrue);
      expect(copy.currentSample, same(_sample));
      expect(copy.lastCommittedSample, same(_sample));
      expect(copy.framesAveraged, 8);
    });
  });

  group('equality', () {
    test('equal when every field matches', () {
      const a = CaptureState(stabilityCount: 3);
      const b = CaptureState(stabilityCount: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when a field differs', () {
      expect(
        const CaptureState(stabilityCount: 3),
        isNot(equals(const CaptureState(stabilityCount: 4))),
      );
    });

    test('unequal to a non-CaptureState object', () {
      // ignore: unrelated_type_equality_checks
      expect(const CaptureState() == 'x', isFalse);
    });
  });

  group('toString', () {
    test('plain state names the lock, stability, radius and accuracy', () {
      expect(
        const CaptureState().toString(),
        'CaptureState(auto, SETTLING 0/12, 5px, Approximate)',
      );
    });

    test('flags value-only and low-light when set', () {
      const state = CaptureState(valueOnly: true, lowLightWarning: true);
      expect(
        state.toString(),
        'CaptureState(auto, SETTLING 0/12, 5px, Approximate, value-only, '
        'low-light)',
      );
    });
  });
}
