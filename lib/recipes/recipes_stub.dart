import 'package:flutter/material.dart';

import '../domain/sample.dart';

/// Thin stand-in for the recipes screen (the real screen arrives in bs-04).
///
/// Renders the mixing [target] sample as findable text so the bs-01 acceptance
/// test can confirm the navigation handoff (AC-11). It is reached only through
/// `AppRouter.toRecipes`.
class RecipesStubScreen extends StatelessWidget {
  const RecipesStubScreen({required this.target, super.key});

  /// The sample the painter wants to mix toward.
  final Sample target;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Text('Recipe target: ${target.name ?? '(unnamed)'}'),
    );
  }
}
