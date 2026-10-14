import 'package:flutter/material.dart';

import 'app_logo.dart';

/// A single navigation destination, rendered as either a [NavigationDestination]
/// (bottom bar) or a [NavigationRailDestination] (side rail) depending on the
/// available width.
class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// A responsive scaffold that adapts its navigation to the viewport width,
/// styled with the signature Indore Chai frosted kiosk aesthetic.
class AdaptiveNavScaffold extends StatelessWidget {
  final String title;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final String? subtitle;
  final bool hideBottomBarOnMobile;

  const AdaptiveNavScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.subtitle,
    this.hideBottomBarOnMobile = false,
  });

  static const double railBreakpoint = 800;
  static const double extendedRailBreakpoint = 1200;

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF06030).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: const AppLogo.mark(height: 26),
          ),
        ),
        title: Builder(
          builder: (context) {
            final showLivePill = MediaQuery.sizeOf(context).width > 420;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                    ),
                    if (showLivePill) ...[
                      const SizedBox(width: 6),
                      // Live Station Indicator Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle ?? 'Indore Central Hub',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            );
          },
        ),
        actions: actions != null
            ? [
                ...actions!,
                const SizedBox(width: 8),
              ]
            : null,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= railBreakpoint;

    final backgroundDecoration = const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAF7F5),
          Color(0xFFF8FAFC),
          Color(0xFFF1F5F9),
        ],
      ),
    );

    if (!useRail) {
      return Scaffold(
        appBar: _appBar(context),
        body: Container(
          decoration: backgroundDecoration,
          child: body,
        ),
        bottomNavigationBar: hideBottomBarOnMobile
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
              ),
      );
    }

    final extended = width >= extendedRailBreakpoint;

    return Scaffold(
      appBar: _appBar(context),
      body: Container(
        decoration: backgroundDecoration,
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
