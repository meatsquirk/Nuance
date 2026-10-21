// bs-19 Live camera capture — acceptance test for the *platform declarations*
// AC (ITEST-3): the static manifest/plist entries the stores and the OS require
// before they grant camera access.
//
// One *pending* `acTestWidgets`, un-pended by PERM-4 (deleting its row in
// `pendingACs`). This is a source-scan AC (the bs-11/12/13 idiom): it reads the
// real `AndroidManifest.xml` and `Info.plist` off disk — paths resolve against
// the current directory, the repo root on the host VM — and inspects them, so
// nothing about the running app is faked. The permission / control ACs live in
// `permission_test.dart` / `controls_test.dart`; keep the files disjoint.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

/// The shipped Android manifest, relative to the repo root.
const String _androidManifestPath = 'android/app/src/main/AndroidManifest.xml';

/// The shipped iOS Info.plist, relative to the repo root.
const String _iosInfoPlistPath = 'ios/Runner/Info.plist';

/// The text of the iOS camera usage description, or null when the key/string is
/// absent. Matches `<key>NSCameraUsageDescription</key>` followed by its
/// `<string>…</string>` value so the Then can assert the explanation is present
/// *and* non-empty (an empty string would still satisfy a bare key check).
String? _cameraUsageDescription(String plist) {
  final match = RegExp(
    r'<key>\s*NSCameraUsageDescription\s*</key>\s*<string>(.*?)</string>',
    dotAll: true,
  ).firstMatch(plist);
  return match?.group(1)?.trim();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  acTestWidgets(
    'AC-10',
    'TestAC10_PlatformDeclarations — the app declares its camera use on both '
        'platforms',
    (tester) async {
      // Given: the shipped app uses the device camera, so both platform
      // manifests exist on disk — checked before they are inspected.
      final androidFile = File(_androidManifestPath);
      final iosFile = File(_iosInfoPlistPath);
      expect(androidFile.existsSync(), isTrue,
          reason: 'AC-10 Given: the Android manifest exists at '
              '$_androidManifestPath (cwd ${Directory.current.path})');
      expect(iosFile.existsSync(), isTrue,
          reason: 'AC-10 Given: the iOS Info.plist exists at $_iosInfoPlistPath');

      // When: the platform manifests are inspected.
      final android = androidFile.readAsStringSync();
      final ios = iosFile.readAsStringSync();

      // Then: the Android manifest declares the CAMERA permission…
      expect(android, contains('android.permission.CAMERA'),
          reason: 'AC-10: the Android manifest declares the CAMERA permission');
      // …and a camera uses-feature (rejects declaring one but not the other).
      expect(
        android,
        matches(RegExp(
            r'<uses-feature\s+android:name="android\.hardware\.camera')),
        reason: 'AC-10: the Android manifest declares a camera <uses-feature>',
      );

      // And: the iOS Info.plist declares a NON-EMPTY NSCameraUsageDescription
      // explaining the use (rejects a missing key or an empty usage string).
      final usage = _cameraUsageDescription(ios);
      expect(usage, isNotNull,
          reason: 'AC-10: the iOS Info.plist declares NSCameraUsageDescription');
      expect(usage, isNotEmpty,
          reason: 'AC-10: the NSCameraUsageDescription explains the camera use '
              '(rejects an empty usage string)');
    },
  );
}
