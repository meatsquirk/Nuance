import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/merge/source_rate_limiter.dart';

void main() {
  group('SourceRateLimiter', () {
    test('defaults to the per-source cap', () {
      final limiter = SourceRateLimiter();
      expect(limiter.maxPerSource, SourceRateLimiter.defaultMaxPerSource);
    });

    test('honours an explicit per-source cap', () {
      final limiter = SourceRateLimiter(maxPerSource: 3);
      expect(limiter.maxPerSource, 3);
    });

    test('admits up to the cap for one source, then rejects the excess', () {
      final limiter = SourceRateLimiter(maxPerSource: 3);
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-1'), isTrue);
      // The 4th and any later record from the same source is rejected.
      expect(limiter.admit('peer-1'), isFalse);
      expect(limiter.admit('peer-1'), isFalse);
    });

    test('counts each source independently — one at its cap never affects '
        'another', () {
      final limiter = SourceRateLimiter(maxPerSource: 2);
      // peer-1 reaches its cap …
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-1'), isFalse);
      // … yet peer-2 still has its full budget (no global starvation).
      expect(limiter.admit('peer-2'), isTrue);
      expect(limiter.admit('peer-2'), isTrue);
      expect(limiter.admit('peer-2'), isFalse);
    });

    test('a zero cap rejects every record', () {
      final limiter = SourceRateLimiter(maxPerSource: 0);
      expect(limiter.admit('peer-1'), isFalse);
    });
  });
}
