# Sample capture and sampling (bs-02) — sign-off round 1 (pending)

- **Acceptance suite:** <result, default and run-pending identical, 0 pending>
- **Unit + coverage:** <result>
- **Per-AC:** see the AC coverage table in [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
- **Test grades:** <grid path> — <n> A · <n> other
- **Non-A grades accepted:** none
- **Augmentations made:** AC-6 control (card vs card-less) by CAPTURE-5 — <summary>
- **Closed by user acceptance:** none
- **Unresolved gates / open known flakes / known gaps / deferred:** native `CaptureSource` impls
  (CameraX/AVFoundation) are platform work outside this Dart build (D-2); reference-card calibration is a
  Phase 2 roadmap item delivered here behind the fake source — real-camera calibration accuracy is validated
  on device separately.
- **Token usage:** <feature total by type>; time <Σ active (Σ wall)>, <first start> → <last end>; by stage:
  <plan · scaffold · shells · acceptance tests · behavior · sign-off>; cost per AC: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)
- **Summary page:** <artifact url>
- **Manual walkthrough:**
  1. Live view + eyedropper: open Capture; a centre eyedropper marks the sample point (AC-1).
  2. Sampling: change the radius selector; the reticle resizes and the sampled colour averages over it (AC-2, AC-3).
  3. Lock & settle: before lock it reads "SETTLING n/12"; lock → "AE · AWB · AF LOCKED" + "STABLE 12/12" (AC-4, AC-5).
  4. Low light: capture in dim light → low-light warning, reading labelled approximate (ΔE 8); dismiss keeps it approximate (AC-6, AC-7).
  5. Reference card: calibrate against a card → normalised, upgraded to ΔE 3 (AC-8).
  6. Photo: import a gallery photo and sample a point on it (AC-9).
  7. Value-only: toggle value-only → grayscale feed, "✓ Value" (AC-10).
  8. Capture: with "STABLE 12/12", capture → averaged over frames, haptic, Readout for "Deep Olive Green" opens (AC-11).
- **Decision:** ⏸ Awaiting
