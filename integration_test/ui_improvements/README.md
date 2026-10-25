# bs-20 UI-improvements acceptance suite

Seeded empty by READOUT-1 (scaffold). No tests live here yet.

**What lands here (stage 3):**
- ITEST-1 — the harness (Given/When/Then vocabulary + fixtures) and the
  `BS20_RUN_PENDING` pending gate (`pending.dart`), mirroring the sibling
  per-feature gates (`integration_test/bs17/pending.dart`, …).
- ITEST-2 — AC-1/AC-2/AC-3/AC-4/AC-5/AC-9 as *pending* tests.
- ITEST-3 — AC-6/AC-7/AC-8 as *pending* tests.
- ITEST-4 — the test-review packet (gate G-2).

**How it runs** (house gotcha: the whole dir won't launch at once — run per-file):

```
flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart
```

Pending ACs are skipped by default; add `--dart-define=BS20_RUN_PENDING=true`
(or the `BS20_RUN_PENDING=1` environment variable on a host-process run) to
execute them — the red-baseline / un-pend run.

See [the master plan](../../specs/bs-20-ui-improvements/MASTER_PLAN_FOR_FEATURE.md)
and [the ITEST module plan](../../specs/bs-20-ui-improvements/modules/ITEST.md).
