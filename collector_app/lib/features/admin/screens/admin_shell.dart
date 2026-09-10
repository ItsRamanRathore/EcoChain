import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminAppShell extends ConsumerWidget {
  final Widget child;
  const AdminAppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/admin/home',          icon: Icons.dashboard_outlined,       activeIcon: Icons.dashboard,              label: 'Metrics'),
    (path: '/admin/recyclers',     icon: Icons.factory_outlined,         activeIcon: Icons.factory,                label: 'Recyclers'),
    (path: '/admin/transactions',  icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,           label: 'Transactions'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/admin/recyclers')) return 1;
    if (location.startsWith('/admin/transactions')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF4D9FFF).withValues(alpha: 0.2),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((t) {
          return NavigationDestination(
            icon: Icon(t.icon, color: Colors.black54),
            selectedIcon: Icon(t.activeIcon, color: const Color(0xFF4D9FFF)),
            label: t.label,
          );
        }).toList(),
      ),
    );
  }
}
