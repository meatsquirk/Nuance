// bs-13 AC-4 augment guard — no stored claimed spectral/ratio value (GUARD-2).
//
// Test-support only — no `lib/` product code (bs-12 D-7).
//
// AC-4 structural invariant: no stored `SeedPaintEntry` carries a claimed
// spectral curve / mix ratio — at the schema level the definition declares no
// such field. Measured optical data (the masstone) and accepted metadata
// (pigment index, opacity, lightfastness) are kept; an LLM-*claimed* measured
// value is not. A planted stored claimed-value entry (`control_claimedSpectral`)
// must be listed.
//
// Enforced as a **schema check** over [schemaFiles] for a declared claimed
// spectral/ratio field; the field names mirror the ingest rule's
// `kRejectedClaimedFields` (`lib/dataset/seed_loader.dart`). The *ingest* facet
// of AC-4 (a raw record whose claimed fields are stripped by the loader) is
// exercised separately by the AC-4 acceptance test over the shipped seed. Empty
// list = pass. GUARD-1 laid this as a stub; GUARD-2 fills the real scan.

import 'source_scan.dart';

/// Matches a declared claimed spectral/ratio field — the thing a stored seed
/// entry must never carry (AC-4). The measured masstone and the accepted
/// metadata fields match none of these.
final RegExp _claimedField = RegExp(
  r'\b(?:spectralCurve|reflectanceCurve|spectral|reflectance|partsFraction|ratio|ratios|parts)\b',
);

/// Reports sites that break the AC-4 no-claimed-value invariant (empty list =
/// pass).
///
/// [schemaFiles] is the SEED schema definition checked for a forbidden claimed
/// spectral/ratio field. An acceptance test overrides it to point at a planted
/// control and assert the rule flags the claimed field.
List<GuardOffender> noClaimedValueGuard({
  Iterable<String> schemaFiles = kSeedSchemaFiles,
}) =>
    [
      for (final match in scanSchema(
        schemaFiles: schemaFiles,
        fieldPatterns: [_claimedField],
      ))
        GuardOffender(
          rule: 'seed-claimed-measured-value',
          detail: 'the seed schema declares a claimed spectral/ratio field — '
              'claimed measured values are stripped, never stored: '
              '${match.snippet}',
          path: match.path,
          line: match.line,
        ),
    ];
