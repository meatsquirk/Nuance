import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart';
import 'project.dart';

/// Builds a printable PDF "studio sheet" for [project] (bs-06 AC-10).
///
/// The sheet opens with the project's name and size, then lists every saved
/// sample (by name — see [sampleStudioLabel]) and every saved recipe (by its
/// component paints, with the predicted verdict — see [recipeStudioLabel]), so
/// the painter can carry the project's palette and mixes to the easel. Returns
/// the PDF document bytes; keeping and delivering them is the caller's concern —
/// `ProjectController.exportOpenedProject` keeps them as `lastExport` (never a
/// disk file, plan D-6) and hands them to the device share sink.
///
/// The sample names and recipe paint-lists are also written to the document's
/// `/Info` metadata (`keywords`), where the `pdf` package stores them as
/// contiguous literal strings. The page's own text is laid out word by word
/// (word spacing is positioning, not spaces in the stream), so the metadata is
/// what lets the acceptance suite assert the produced bytes reference each
/// sample and each recipe (the AC-10 augmentation) without parsing the content
/// stream.
Future<Uint8List> buildProjectStudioSheet(Project project) async {
  final sampleLabels = [for (final s in project.samples) sampleStudioLabel(s)];
  final recipePaints = [for (final r in project.recipes) recipePaintList(r)];
  final recipeLabels = [for (final r in project.recipes) recipeStudioLabel(r)];

  final doc = pw.Document(
    compress: false,
    title: project.name,
    subject: 'Studio sheet',
    // ASCII-only index of the sheet's contents, kept contiguous in `/Info` so a
    // test can assert each sample name and each recipe's paint list is present.
    keywords: [...sampleLabels, ...recipePaints].join(' | '),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(level: 0, text: project.name),
        if (project.size != null) pw.Text('Size: ${project.size}'),
        pw.SizedBox(height: 12),
        pw.Header(level: 1, text: 'Samples'),
        for (final label in sampleLabels) pw.Bullet(text: label),
        pw.SizedBox(height: 12),
        pw.Header(level: 1, text: 'Recipes'),
        for (final label in recipeLabels) pw.Bullet(text: label),
      ],
    ),
  );

  return doc.save();
}

/// A sample's line on the studio sheet: its name, or a CIELAB fallback when the
/// sample carries none (an unnamed capture still appears, by its coordinates).
String sampleStudioLabel(Sample sample) {
  final name = sample.name;
  if (name != null) return name;
  final c = sample.coordinates;
  return 'Lab ${c.lightness.round()}/${c.a.round()}/${c.b.round()}';
}

/// A recipe's component paints joined with " + " (e.g. `Yellow Ochre + Ivory
/// Black`) — the identifying part of its studio-sheet line and its metadata
/// index entry.
String recipePaintList(Recipe recipe) =>
    recipe.components.map((component) => component.paint.name).join(' + ');

/// A recipe's full line on the studio sheet: its [recipePaintList], with the
/// predicted verdict appended when the recipe carries one.
String recipeStudioLabel(Recipe recipe) {
  final paints = recipePaintList(recipe);
  final verdict = recipe.verdict;
  if (verdict == null) return paints;
  return '$paints ($verdict)';
}
