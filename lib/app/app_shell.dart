import 'package:flutter/material.dart';

import 'app_destinations.dart';
import 'theme.dart';

/// The app's bottom-navigation shell (bs-18 CHROME-2, AC-1; wireframe E44).
///
/// A [Scaffold] whose body is an [IndexedStack] over the [destinations]' screens
/// and whose `bottomNavigationBar` is the design-system bottom nav. Each
/// destination's screen is built from its parallel entry in [bodies] (supplied
/// by `build_app.dart`, which owns the dependency wiring), so the shell itself
/// holds no app services and is unit-testable against fake bodies.
///
/// **Lazy mount (D: zero behaviour change):** the [IndexedStack] keeps every
/// *visited* destination alive (so switching back preserves its state) but a
/// destination that has never been selected renders an empty placeholder
/// instead of its real screen. The app opens on [initialIndex] only, so a boot
/// mounts exactly that one screen — the other three (and their controllers /
/// read endpoints) are not constructed until the painter first navigates to
/// them. This keeps the default route's widget tree equal to the pre-shell
/// landing plus the nav chrome.
///
/// **Test anchors (CHROME-2):** [bottomNavKey] marks the bar; every
/// destination's [AppDestination.navItemKey] marks its item (present whether or
/// not it is selected); [activeDestinationKey] marks the selected item's
/// filled-glyph/bold-label marker — the non-colour active indicator (AC-1 reads
/// "active state not by colour alone"; AC-13).
///
/// CHROME-3 (AC-1) finalises the nav's design-system treatment over this shell.
class AppShell extends StatefulWidget {
  AppShell({
    required this.destinations,
    required this.bodies,
    this.initialIndex = 0,
    super.key,
  })  : assert(
          destinations.length == bodies.length,
          'Each destination needs exactly one body builder.',
        ),
        assert(destinations.isNotEmpty, 'The shell needs a destination.'),
        assert(
          initialIndex >= 0 && initialIndex < destinations.length,
          'initialIndex must index a destination.',
        );

  /// The nav destinations, in bar order.
  final List<AppDestination> destinations;

  /// The screen builders parallel to [destinations] — `bodies[i]` builds the
  /// screen for `destinations[i]`, invoked the first time that destination is
  /// shown.
  final List<WidgetBuilder> bodies;

  /// The destination the shell opens on (default: the first).
  final int initialIndex;

  /// Test anchor: the bottom navigation bar.
  static const Key bottomNavKey = Key('app-shell-bottom-nav');

  /// Test anchor: the selected destination's non-colour active marker.
  static const Key activeDestinationKey = Key('app-shell-active-destination');

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  /// The indices whose real screen has been built. A destination stays in the
  /// stack once visited (preserving its state); an unvisited one is a
  /// placeholder, so a boot mounts only [AppShell.initialIndex].
  late final Set<int> _visited = {widget.initialIndex};

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: [
          for (var i = 0; i < widget.destinations.length; i++)
            _visited.contains(i)
                ? widget.bodies[i](context)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        destinations: widget.destinations,
        selectedIndex: _index,
        onSelected: _select,
      ),
    );
  }
}

/// The design-system bottom navigation bar (bs-18 CHROME-2 shell).
///
/// A themed [DecoratedBox] (surface fill + hairline top border read from the
/// theme tokens, never hardcoded — AC-14) holding one [_NavItem] per
/// destination. CHROME-3 (AC-1) refines the treatment; the shell keeps the keys
/// and the non-colour active marker stable so the acceptance test can anchor on
/// them now.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: AppShell.bottomNavKey,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colors.outline,
            width: AppTheme.hairlineBorderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One bottom-nav item: a tappable glyph + label.
///
/// When [selected] it shows the filled [AppDestination.selectedIcon] and a bold
/// label, and wraps that marker in [AppShell.activeDestinationKey] — the
/// non-colour active indicator. When not, it shows the outline glyph and the
/// normal label. The item always carries [AppDestination.navItemKey].
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tint = selected ? colors.primary : colors.onSurfaceVariant;
    final label = Text(
      destination.label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: tint,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      ),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? destination.selectedIcon : destination.icon,
          color: tint,
          size: 24,
        ),
        const SizedBox(height: 4),
        label,
      ],
    );
    return InkWell(
      key: destination.navItemKey,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // Only the selected item carries the active marker, so the acceptance
        // suite can read which destination is active without inspecting colour.
        child: selected
            ? KeyedSubtree(key: AppShell.activeDestinationKey, child: content)
            : content,
      ),
    );
  }
}
