import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'providers/sync_provider.dart';
import 'features/lots/screens/create_lot_screen.dart';
import 'features/prices/screens/price_board_screen.dart';
import 'features/recyclers/screens/recycler_match_screen.dart';
import 'core/local_storage/hive_setup.dart';
import 'core/network/dio_client.dart';
import 'features/handover/screens/pending_lots_screen.dart';
import 'features/handover/screens/handover_confirm_screen.dart';
import 'features/handover/screens/handover_generate_screen.dart';
import 'features/handover/screens/qr_display_screen.dart';
import 'features/handover/screens/handover_complete_screen.dart';
import 'features/earnings/screens/earnings_screen.dart';
import 'shared/widgets/language_selector.dart';
import 'models/local/lot_local.dart';
import 'models/api/handover_record.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/recycler_dashboard/screens/recycler_home_tab.dart';
import 'features/recycler_dashboard/screens/recycler_scanner_tab.dart';
import 'features/recycler_dashboard/screens/recycler_prices_tab.dart';
import 'features/recycler_dashboard/screens/recycler_handover_confirm_screen.dart';
import 'features/admin/screens/admin_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_recyclers_screen.dart';
import 'features/admin/screens/admin_transactions_screen.dart';

import 'features/auth/screens/collector_signup_screen.dart';
import 'features/auth/screens/recycler_signup_screen.dart';
import 'features/home/screens/collector_profile_screen.dart';
import 'features/recycler_dashboard/screens/recycler_profile_tab.dart';
import 'features/admin/screens/admin_profile_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_recyclers_screen.dart';
import 'features/admin/screens/admin_transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveSetup.init();
  DioClient.init();
  runApp(const ProviderScope(child: CollectorApp()));
}

// ─── Router ──────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation.startsWith('/signup');
      
      if (!authState.isAuthenticated && !isLoggingIn && !isSigningUp) {
        return '/login';
      }
      
      if (authState.isAuthenticated) {
        final path = state.uri.path;
        if (authState.role == 'collector') {
          if (path.startsWith('/collector')) return null;
          return '/collector/home';
        } else if (authState.role == 'recycler') {
          if (path.startsWith('/recycler')) return null;
          return '/recycler/home';
        } else if (authState.role == 'admin') {
          if (path.startsWith('/admin')) return null;
          return '/admin/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup/collector',
        builder: (context, state) => const CollectorSignupScreen(),
      ),
      GoRoute(
        path: '/signup/recycler',
        builder: (context, state) => const RecyclerSignupScreen(),
      ),
      // Admin Routes
      ShellRoute(
        builder: (context, state, child) => AdminAppShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/recyclers',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminRecyclersScreen()),
          ),
          GoRoute(
            path: '/admin/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminTransactionsScreen()),
          ),
          GoRoute(
            path: '/admin/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminProfileScreen()),
          ),
        ],
      ),
      // Collector Routes
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/collector/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeTab()),
          ),
          GoRoute(
            path: '/collector/prices',
            pageBuilder: (context, state) => const NoTransitionPage(child: PriceBoardScreen()),
          ),
          GoRoute(
            path: '/collector/recyclers',
            pageBuilder: (context, state) => const NoTransitionPage(child: RecyclerMatchScreen()),
          ),
          GoRoute(
            path: '/collector/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: CollectorProfileScreen()),
          ),
        ],
      ),
      // Shared / other collector routes
      GoRoute(
        path: '/collector/create-lot',
        builder: (context, state) => const CreateLotScreen(),
      ),
      GoRoute(
        path: '/collector/pending-lots',
        builder: (context, state) => const PendingLotsScreen(),
      ),
      GoRoute(
        path: '/collector/handover/confirm',
        builder: (context, state) => HandoverConfirmScreen(lot: state.extra as LotLocal),
      ),
      GoRoute(
        path: '/collector/handover/generating',
        builder: (context, state) => HandoverGenerateScreen(args: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/collector/handover/qr',
        builder: (context, state) => QRDisplayScreen(record: state.extra as HandoverRecord),
      ),
      GoRoute(
        path: '/collector/handover/complete',
        builder: (context, state) => HandoverCompleteScreen(record: state.extra as HandoverRecord),
      ),
      GoRoute(
        path: '/collector/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      // Recycler Routes
      ShellRoute(
        builder: (context, state, child) => RecyclerAppShell(child: child),
        routes: [
          GoRoute(
            path: '/recycler/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: RecyclerHomeTab()),
          ),
          GoRoute(
            path: '/recycler/scanner',
            pageBuilder: (context, state) => const NoTransitionPage(child: RecyclerScannerTab()),
          ),
          GoRoute(
            path: '/recycler/prices',
            pageBuilder: (context, state) => const NoTransitionPage(child: RecyclerPricesTab()),
          ),
          GoRoute(
            path: '/recycler/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: RecyclerProfileTab()),
          ),
        ],
      ),
      GoRoute(
        path: '/recycler/handover/confirm',
        builder: (context, state) => RecyclerHandoverConfirmScreen(payload: state.extra as Map<String, dynamic>),
      ),
    ],
  );
});

// ─── App ─────────────────────────────────────────────────────────────────────

class CollectorApp extends ConsumerStatefulWidget {
  const CollectorApp({super.key});

  @override
  ConsumerState<CollectorApp> createState() => _CollectorAppState();
}

class _CollectorAppState extends ConsumerState<CollectorApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectivitySyncProvider); // init listener
      ref.read(syncServiceProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'e-Mulya Platform',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C896),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}

// ─── Shell with Bottom Navigation ────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/collector/home',      icon: Icons.home_outlined,       activeIcon: Icons.home,              label: 'Home'),
    (path: '/collector/prices',    icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart,         label: 'Prices'),
    (path: '/collector/recyclers', icon: Icons.factory_outlined,    activeIcon: Icons.factory,            label: 'Recyclers'),
    (path: '/collector/profile',   icon: Icons.person_outline,      activeIcon: Icons.person,            label: 'Profile'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/collector/prices')) return 1;
    if (location.startsWith('/collector/recyclers')) return 2;
    if (location.startsWith('/collector/profile')) return 3;
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
        indicatorColor: const Color(0xFF00C896).withValues(alpha: 0.2),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final t = entry.value;
          final l10n = AppLocalizations.of(context)!;
          String localizedLabel = t.label;
          if (idx == 0) localizedLabel = l10n.navHome;
          if (idx == 1) localizedLabel = l10n.navPrices;
          if (idx == 2) localizedLabel = l10n.navRecyclers;
          if (idx == 3) localizedLabel = l10n.navProfile;

          return NavigationDestination(
            icon: Icon(t.icon, color: Colors.black54),
            selectedIcon: Icon(t.activeIcon, color: const Color(0xFF00C896)),
            label: localizedLabel,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Recycler Shell ──────────────────────────────────────────────────────────

class RecyclerAppShell extends ConsumerWidget {
  final Widget child;
  const RecyclerAppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/recycler/home',      icon: Icons.dashboard_outlined,       activeIcon: Icons.dashboard,              label: 'Dashboard'),
    (path: '/recycler/scanner',   icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner,        label: 'Scan'),
    (path: '/recycler/prices',    icon: Icons.price_change_outlined,    activeIcon: Icons.price_change,           label: 'Prices'),
    (path: '/recycler/profile',   icon: Icons.person_outline,           activeIcon: Icons.person,                 label: 'Profile'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/recycler/scanner')) return 1;
    if (location.startsWith('/recycler/prices')) return 2;
    if (location.startsWith('/recycler/profile')) return 3;
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
        indicatorColor: const Color(0xFFFFAA00).withValues(alpha: 0.2),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final t = entry.value;
          final l10n = AppLocalizations.of(context)!;
          String localizedLabel = t.label;
          if (idx == 0) localizedLabel = l10n.dashboard;
          if (idx == 1) localizedLabel = l10n.navScan;
          if (idx == 2) localizedLabel = l10n.navPrices;
          if (idx == 3) localizedLabel = l10n.navProfile;

          return NavigationDestination(
            icon: Icon(t.icon, color: Colors.black54),
            selectedIcon: Icon(t.activeIcon, color: const Color(0xFFFFAA00)),
            label: localizedLabel,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────


class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  Widget _buildSyncBanner(SyncStatus status) {
    return switch (status) {
      SyncStatus.syncing => const _SyncBanner('सिंक हो रहा है...', Colors.blue, Icons.sync),
      SyncStatus.success => const _SyncBanner('अभी सिंक हुआ', Colors.green, Icons.check),
      SyncStatus.failed  => const _SyncBanner('सिंक विफल — पुनः प्रयास करें', Colors.red, Icons.error),
      SyncStatus.offline => const _SyncBanner('ऑफलाइन — कैश डेटा', Colors.amber, Icons.wifi_off),
      SyncStatus.idle    => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSyncBanner(syncStatus),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.read(syncServiceProvider).sync(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C896).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.recycling, color: Color(0xFF00C896), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.appTitle,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Text(
                                  'Collector Platform',
                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const LanguageSelector(),
                          IconButton(
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                            },
                            icon: const Icon(Icons.logout, color: Colors.black54),
                            tooltip: 'Log Out',
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      _HomePrimaryCard(
                        icon: Icons.add_circle_outline,
                        color: const Color(0xFF00C896),
                        title: AppLocalizations.of(context)!.newLot,
                        subtitle: 'Photograph, classify & weigh a new e-waste lot',
                        onTap: () => context.push('/collector/create-lot'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeQuickCard(
                              icon: Icons.inventory_2,
                              color: const Color(0xFF00C896),
                              title: AppLocalizations.of(context)!.handover,
                              onTap: () => context.push('/collector/pending-lots'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HomeQuickCard(
                              icon: Icons.bar_chart,
                              color: const Color(0xFF4D9FFF),
                              title: AppLocalizations.of(context)!.analytics,
                              onTap: () => context.go('/collector/prices'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HomeQuickCard(
                              icon: Icons.factory,
                              color: const Color(0xFFFFAA00),
                              title: AppLocalizations.of(context)!.settings,
                              onTap: () => context.go('/collector/recyclers'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF00C896).withValues(alpha: 0.1)
                                : const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF00C896).withValues(alpha: 0.4)
                                  : const Color(0xFFFF4D6D).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? const Color(0xFF00C896) : const Color(0xFFFF4D6D),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline ? 'Online — syncing enabled' : 'Offline — local only',
                                style: TextStyle(
                                  color: isOnline ? const Color(0xFF00C896) : const Color(0xFFFF4D6D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePrimaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomePrimaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4), maxLines: 2),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _HomeQuickCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _SyncBanner(this.text, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
