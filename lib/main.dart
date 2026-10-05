import 'package:flutter/material.dart';

/// Entry point for the Paint Color Assistant application.
///
/// This is the scaffold placeholder for feature bs-01. Domain model, app
/// assembly and navigation are built by the CORE-2 shell phase; the Readout
/// screen and behaviour arrive in later phases.
void main() {
  runApp(const PaintColorAssistantApp());
}

/// Root application widget.
class PaintColorAssistantApp extends StatelessWidget {
  const PaintColorAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Paint Color Assistant'),
      ),
    );
  }
}
