# Planned 2026-10-20 by /feature-next-phase — AWAITING G-1 spec approval (no approval line yet)
# Feature: bs-19 Live camera capture source
#
# Resumes the deferred "SOURCE-2" work the capture architecture was always built
# for. bs-02 shipped the `CaptureSource` abstraction (lib/capture/source/) and a
# deterministic `SoftwareCaptureSource` as the shipped default; the live-view area
# has only ever rendered a flat grey placeholder
# (`ColoredBox(Color(0xFF3A3A3A))`, capture_live_view.dart) and the comments
# throughout the source note that "the native CameraX / AVFoundation sources are
# platform work tracked outside this pure-Dart build, wired behind the same
# CaptureSource interface" and "SOURCE-2 renders real frames here". No camera
# plugin, CAMERA permission or NSCameraUsageDescription exists yet. This feature
# builds the real source.
#
# It adds a real `CameraCaptureSource implements CaptureSource` backed by the
# official Flutter `camera` plugin, renders its frames into the live view
# (replacing the placeholder), converts device frames (YUV420 on Android /
# BGRA on iOS) to the existing `Frame`/`Pixel` RGB model, and selects the camera
# source in production when a camera is available AND permission is granted —
# falling back gracefully to `SoftwareCaptureSource` otherwise (no crash, no
# black screen). Because the reading pipeline (eyedropper, sample points,
# stability, AE·AWB·AF locks, torch) already consumes `Frame`s abstractly, the
# NEW behaviour is the real source, the preview render, the permission/fallback
# wiring and the platform declarations — not the reading maths, which bs-02/bs-09
# already own.
#
# Scope decisions (Matt Quirk, 2026-10-20): FULL pipeline — live frames feed the
# preview AND the eyedropper/sample/accuracy/lock readings. BOTH platforms —
# Android + iOS permission declarations. DEFERRED (out of scope, D-6): real
# reference-card calibration against the live camera (needs camera-specific CV)
# stays on the software path; RAW and wide-gamut selection stay deferred — the
# camera source reports the processed sRGB pipeline.
#
# Acceptance tests inject a scripted `CaptureSource` at the `AppDependencies.
# captureSource` seam (the same seam `FakeCaptureSource` uses), so the suite runs
# on `-d flutter-tester` with no real hardware; the real plugin is exercised by a
# manual device walkthrough at sign-off.

Feature: Live camera capture source
  As a colour-vision-deficient painter
  I want the Capture screen to show and sample my device's live camera
  So that I read real colours off the scene in front of me, not a placeholder

  Background:
    Given the app is built over the bs-02 capture pipeline and its CaptureSource seam
    And the reading pipeline samples colour from the active source's frames

  # ---- Live preview & colour -------------------------------------------------

  # UX: the Capture live-view area (capture_live_view.dart) shows the feed
  Scenario: The live view shows the camera feed
    Given a camera is available and camera permission is granted
    When the Capture screen opens on the live camera source
    Then the live view renders the camera's frames
    And it no longer shows the flat grey placeholder surface

  Scenario: Camera frames convert to the correct colour
    Given the camera delivers a frame whose pixel at the reticle is a known colour
    When that frame is converted into the app's Frame model
    Then the Frame's pixel at the reticle equals the known colour within tolerance
    And a frame of a different known colour converts to a correspondingly different pixel

  Scenario: The reading follows the live camera frame
    Given the Capture screen is reading the live camera source
    When the camera frame under the reticle changes to a new colour
    Then the current reading updates to the new colour
    And the reading equals the live frame's pixel under the reticle, not a fixed value

  Scenario: Value-only mode shows the live feed in grayscale
    Given the Capture screen is reading the live camera source
    When the painter turns on value-only mode
    Then the live view renders the camera frame in grayscale
    And the overlaid readings stay in colour

  # ---- Camera controls over the real device ----------------------------------

  Scenario: Locking exposure, white balance and focus settles the live camera
    Given the Capture screen is reading the live camera source
    And the reading is marked approximate because exposure is not locked
    When the painter locks AE, AWB and AF
    Then the live camera's exposure, white balance and focus are held
    And the "exposure not locked" approximate warning clears

  Scenario: The torch toggles the device light
    Given the Capture screen is reading the live camera source
    When the painter turns the torch on
    Then the device torch is lit
    And a reading committed while it is lit is stamped as lit by the torch
    And turning the torch off extinguishes the device light

  # ---- Permission, availability & fallback -----------------------------------

  Scenario: Camera permission is requested, and denial falls back gracefully
    Given camera permission has not yet been decided
    When the painter opens the Capture screen for a live reading
    Then the app requests camera permission
    And if permission is granted the live camera source becomes active
    And if permission is denied the app falls back to the software source without crashing
    And a "camera access needed" affordance is shown so the painter can retry or open settings

  Scenario: A device with no camera falls back gracefully
    Given the device reports no usable camera
    When the Capture screen opens
    Then the app falls back to the software source without crashing
    And the painter can still read, import a photo and use the rest of the app

  Scenario: The camera is released and re-acquired across the app lifecycle
    Given the Capture screen is reading the live camera source
    When the app is backgrounded or the Capture screen is disposed
    Then the camera controller is released
    And when the app returns to the Capture screen the live feed resumes without a frozen or black frame

  # ---- Platform declarations -------------------------------------------------

  # UX: static configuration the stores and OS require to grant camera access
  Scenario: The app declares its camera use on both platforms
    Given the shipped app uses the device camera
    When the platform manifests are inspected
    Then the Android manifest declares the CAMERA permission and a camera uses-feature
    And the iOS Info.plist declares an NSCameraUsageDescription explaining the use
