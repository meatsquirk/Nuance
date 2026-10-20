import 'package:flutter/material.dart';

/// The app's shared design-system top bar (bs-18 CHROME-2 shell, AC-2;
/// wireframe E1): a [title] in the theme's Atkinson type, an optional
/// leading back/close affordance, and a trailing theme-toggle slot.
///
/// A [PreferredSizeWidget] so a destination can mount it as its [Scaffold.appBar]
/// without changing its behaviour. CHROME-2 builds and unit-tests it as the
/// shared shell; **CHROME-4 (AC-2)** replaces each destination's ad-hoc header
/// with it. It is intentionally not yet wired onto the screens — doing so is the
/// AC-2 presentation swap, and mounting it alongside a screen's existing header
/// would double the bar.
///
/// Every colour and type value is read from the theme (`Theme.of`), never
/// hardcoded, so the single installed theme carries it (AC-11/AC-14) and the
/// title uses the Atkinson family the theme installs (AC-2).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.onBack,
    this.onClose,
    this.themeToggle,
    super.key,
  }) : assert(
          onBack == null || onClose == null,
          'A top bar shows at most one leading affordance (back or close).',
        );

  /// The screen title, rendered in the theme's title type (Atkinson).
  final String title;

  /// A back affordance when non-null (a destination pushed onto another).
  final VoidCallback? onBack;

  /// A close affordance when non-null (a modally-presented destination).
  final VoidCallback? onClose;

  /// The trailing theme-toggle control slot, or null when the destination
  /// offers none. The toggle control itself is supplied by the caller so the
  /// top bar stays free of the display wiring.
  final Widget? themeToggle;

  /// Test anchor: the title text.
  static const Key titleKey = Key('app-top-bar-title');

  /// Test anchor: the leading back/close affordance.
  static const Key leadingKey = Key('app-top-bar-leading');

  /// Test anchor: the trailing theme-toggle slot.
  static const Key themeToggleKey = Key('app-top-bar-theme-toggle');

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget? leading;
    if (onBack != null) {
      leading = IconButton(
        key: leadingKey,
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
        tooltip: 'Back',
      );
    } else if (onClose != null) {
      leading = IconButton(
        key: leadingKey,
        icon: const Icon(Icons.close),
        onPressed: onClose,
        tooltip: 'Close',
      );
    }
    final toggle = themeToggle;
    return AppBar(
      leading: leading,
      title: Text(
        title,
        key: titleKey,
        style: theme.textTheme.titleLarge,
      ),
      actions: [
        if (toggle != null)
          KeyedSubtree(key: themeToggleKey, child: toggle),
      ],
    );
  }
}

/// The shared light/dark theme toggle the chrome mounts in every [AppTopBar]
/// (wireframe E45, bs-18 AC-2).
///
/// It is **presentation only**: the app ships the single warm-paper light theme
/// and the dark-mode wiring is deferred (bs-18 D-3, following bs-17), so the
/// control toggles only its own glyph — it is the top-bar affordance the design
/// system calls for, not the (unbuilt) app-wide dark switch. Its icon renders in
/// the theme's app-bar foreground token (the ambient [IconButton] style), never
/// a hardcoded colour, so the one installed theme carries it (AC-11/AC-14).
///
/// Each destination supplies `const ThemeToggleButton()` to its top bar's
/// [AppTopBar.themeToggle] slot, keeping [AppTopBar] itself free of display
/// wiring (its CHROME-2 contract: no toggle unless one is supplied).
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  /// The locally-shown brightness. Presentation only — flipping it changes the
  /// glyph, not the app-wide theme (dark wiring deferred, D-3).
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => setState(() => _dark = !_dark),
      icon: Icon(_dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: _dark ? 'Switch to light theme' : 'Switch to dark theme',
    );
  }
}
