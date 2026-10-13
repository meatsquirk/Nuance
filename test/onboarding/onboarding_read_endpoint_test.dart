import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/onboarding_controller.dart';
import 'package:paint_color_assistant/onboarding/onboarding_read_endpoint.dart';

void main() {
  testWidgets('of() returns the controller exposed by the nearest endpoint',
      (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    late OnboardingController read;

    await tester.pumpWidget(
      OnboardingReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            read = OnboardingReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(read, same(controller));
  });

  testWidgets('updateShouldNotify tracks the controller identity',
      (tester) async {
    final a = OnboardingController();
    final b = OnboardingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    const child = SizedBox();
    final first = OnboardingReadEndpoint(controller: a, child: child);
    final sameController = OnboardingReadEndpoint(controller: a, child: child);
    final other = OnboardingReadEndpoint(controller: b, child: child);

    expect(first.updateShouldNotify(sameController), isFalse);
    expect(first.updateShouldNotify(other), isTrue);
    expect(OnboardingReadEndpoint.endpointKey, const Key('onboarding-read-endpoint'));
  });
}
