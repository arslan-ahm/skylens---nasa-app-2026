import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/motion.dart';

/// One bottom-navigation destination.
class ShellTab {
  const ShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Reusable bottom-tab shell for a `StatefulShellRoute`: each tab keeps its
/// own navigation stack and scroll position, tabs cross-fade and slide when
/// switching, the selected icon bounces, and each switch gives a light
/// haptic tick. Off-screen tabs stop their animations (TickerMode).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.shell,
    required this.children,
    required this.tabs,
  });

  final StatefulNavigationShell shell;
  final List<Widget> children;
  final List<ShellTab> tabs;

  void _select(int i) {
    if (i != shell.currentIndex) HapticFeedback.selectionClick();
    // Tapping the current tab again returns to its first page.
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final reduced = Motion.reduced(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < children.length; i++)
            _TabPage(
              active: i == shell.currentIndex,
              reduced: reduced,
              child: children[i],
            ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: t.outline, width: t.strokeWidth),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          animationDuration: Motion.medium,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final (i, tab) in tabs.indexed)
              NavigationDestination(
                tooltip: tab.label,
                label: tab.label,
                icon: Icon(tab.icon),
                selectedIcon: _BounceIcon(
                  key: ValueKey('tab$i'),
                  icon: tab.selectedIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({
    required this.active,
    required this.reduced,
    required this.child,
  });

  final bool active;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !active,
    child: TickerMode(
      enabled: active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: reduced ? Duration.zero : Motion.medium,
        curve: active ? Motion.enter : Motion.exit,
        child: AnimatedSlide(
          offset: active ? Offset.zero : const Offset(0, 0.02),
          duration: reduced ? Duration.zero : Motion.medium,
          curve: Motion.enter,
          child: ExcludeSemantics(excluding: !active, child: child),
        ),
      ),
    ),
  );
}

/// Pops with a little overshoot when it appears (i.e. when selected).
class _BounceIcon extends StatelessWidget {
  const _BounceIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: Motion.reduced(context) ? 1 : 0.6, end: 1),
    duration: Motion.slow,
    curve: Curves.elasticOut,
    builder: (context, s, child) => Transform.scale(scale: s, child: child),
    child: Icon(icon),
  );
}
