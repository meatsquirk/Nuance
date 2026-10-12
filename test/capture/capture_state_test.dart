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
      expect(state.torchOn, isFalse);
      expect(state.torchWarning, isNull);
      expect(state.markedPoints, isEmpty);
      expect(state.markedReadings, isEmpty);
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
      const point = MarkedPoint(3, 4);
      const reading = MultiPointReading(
        position: MarkedPoint(3, 4),
        coordinates: ColorCoordinates(lightness: 50, a: 1, b: 2),
      );
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
        torchOn: true,
        torchWarning: 'Torch ~5500K biases the reading',
        markedPoints: const [point],
        markedReadings: const [reading],
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
      expect(copy.torchOn, isTrue);
      expect(copy.torchWarning, 'Torch ~5500K biases the reading');
      expect(copy.markedPoints, const [point]);
      expect(copy.markedReadings, const [reading]);
    });

    test('clearTorchWarning forces torchWarning back to null past the '
        'set-forward merge (CAPTURE-3)', () {
      const lit = CaptureState(torchOn: true, torchWarning: 'warn');

      // Without the flag the set-forward merge keeps the existing warning.
      expect(lit.copyWith().torchWarning, 'warn');

      // With the flag it clears, leaving the other fields (torchOn) intact.
      final cleared = lit.copyWith(clearTorchWarning: true);
      expect(cleared.torchWarning, isNull);
      expect(cleared.torchOn, isTrue);
    });
  });

  group('equality', () {
    // A fully-populated pair — every field, including the torch fields and the
    // non-empty marked lists — so equality reaches every comparison.
    CaptureState populated() => const CaptureState(
          stabilityCount: 3,
          torchOn: true,
          torchWarning: 'warn',
          markedPoints: [MarkedPoint(1, 2)],
          markedReadings: [
            MultiPointReading(
              position: MarkedPoint(1, 2),
              coordinates: ColorCoordinates(lightness: 50, a: 1, b: 2),
            ),
          ],
        );

    test('equal when every field matches', () {
      const a = CaptureState(stabilityCount: 3);
      const b = CaptureState(stabilityCount: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equal across every field, including torch and marked lists', () {
      expect(populated(), equals(populated()));
      expect(populated().hashCode, equals(populated().hashCode));
    });

    test('unequal when a field differs', () {
      expect(
        const CaptureState(stabilityCount: 3),
        isNot(equals(const CaptureState(stabilityCount: 4))),
      );
    });

    test('unequal when torchOn differs', () {
      expect(
        const CaptureState(torchOn: true),
        isNot(equals(const CaptureState())),
      );
    });

    test('unequal when torchWarning differs', () {
      expect(
        const CaptureState(torchWarning: 'a'),
        isNot(equals(const CaptureState(torchWarning: 'b'))),
      );
    });

    test('unequal when markedPoints differ', () {
      expect(
        const CaptureState(markedPoints: [MarkedPoint(1, 2)]),
        isNot(equals(const CaptureState(markedPoints: [MarkedPoint(3, 4)]))),
      );
    });

    test('unequal when markedReadings differ', () {
      const a = CaptureState(markedReadings: [
        MultiPointReading(
          position: MarkedPoint(1, 2),
          coordinates: ColorCoordinates(lightness: 50, a: 1, b: 2),
        ),
      ]);
      expect(a, isNot(equals(const CaptureState())));
    });

    test('unequal to a non-CaptureState object', () {
      // ignore: unrelated_type_equality_checks
      expect(const CaptureState() == 'x', isFalse);
    });
  });

  group('MarkedPoint', () {
    test('holds its frame position', () {
      // Built at runtime (non-const) so the const constructor line is covered.
      // ignore: prefer_const_constructors
      final point = MarkedPoint(7, 11);
      expect(point.x, 7);
      expect(point.y, 11);
    });

    test('equal by value, unequal when a coordinate differs', () {
      expect(const MarkedPoint(1, 2), equals(const MarkedPoint(1, 2)));
      expect(
        const MarkedPoint(1, 2).hashCode,
        equals(const MarkedPoint(1, 2).hashCode),
      );
      expect(const MarkedPoint(1, 2), isNot(equals(const MarkedPoint(1, 3))));
      // ignore: unrelated_type_equality_checks
      expect(const MarkedPoint(1, 2) == 'x', isFalse);
    });

    test('toString names the position', () {
      expect(const MarkedPoint(1, 2).toString(), 'MarkedPoint(1, 2)');
    });
  });

  group('MultiPointReading', () {
    const position = MarkedPoint(3, 4);
    const coordinates = ColorCoordinates(lightness: 50, a: 1, b: 2);
    const reading =
        MultiPointReading(position: position, coordinates: coordinates);

    test('keeps its position and sampled colour', () {
      // Built at runtime (non-const) so the const constructor line is covered.
      // ignore: prefer_const_constructors
      final built = MultiPointReading(position: position, coordinates: coordinates);
      expect(built.position, position);
      expect(built.coordinates, coordinates);
    });

    test('equal by value, unequal when a field differs', () {
      expect(
        reading,
        equals(const MultiPointReading(
          position: position,
          coordinates: coordinates,
        )),
      );
      expect(
        reading.hashCode,
        equals(const MultiPointReading(
          position: position,
          coordinates: coordinates,
        ).hashCode),
      );
      expect(
        reading,
        isNot(equals(const MultiPointReading(
          position: MarkedPoint(9, 9),
          coordinates: coordinates,
        ))),
      );
      expect(
        reading,
        isNot(equals(const MultiPointReading(
          position: position,
          coordinates: ColorCoordinates(lightness: 1, a: 1, b: 1),
        ))),
      );
      // ignore: unrelated_type_equality_checks
      expect(reading == 'x', isFalse);
    });

    test('toString names the position and colour', () {
      expect(
        reading.toString(),
        'MultiPointReading(MarkedPoint(3, 4) → $coordinates)',
      );
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
