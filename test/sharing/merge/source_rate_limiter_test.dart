import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/merge/source_rate_limiter.dart';

void main() {
  group('SourceRateLimiter (shell)', () {
    test('defaults to the provisional per-source cap', () {
      final limiter = SourceRateLimiter();
      expect(limiter.maxPerSource, SourceRateLimiter.defaultMaxPerSource);
    });

    test('honours an explicit per-source cap', () {
      final limiter = SourceRateLimiter(maxPerSource: 3);
      expect(limiter.maxPerSource, 3);
    });

    test('admit accepts every record in the shell (no cap enforced)', () {
      final limiter = SourceRateLimiter(maxPerSource: 1);
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-1'), isTrue);
      expect(limiter.admit('peer-2'), isTrue);
    });
  });
}
