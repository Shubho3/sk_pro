import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../providers/auth_providers.dart';
import '../providers/supabase_providers.dart';
import '../../ui/views/admin/admin_dashboard_view.dart';
import '../../ui/views/auth/login_view.dart';
import '../../ui/views/auth/pending_view.dart';
import '../../ui/views/common/loading_view.dart';
import '../../ui/views/common/setup_required_view.dart';
import '../../ui/views/helper/helper_dashboard_view.dart';
import '../../ui/views/office/office_dashboard_view.dart';

/// Route path constants.
class Routes {
  static const setup = '/setup';
  static const login = '/login';
  static const loading = '/loading';
  static const pending = '/pending';
  static const admin = '/admin';
  static const employee = '/employee';
  static const company = '/company';
}

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return Routes.admin;
    case UserRole.employee:
      return Routes.employee;
    case UserRole.company:
      return Routes.company;
    case UserRole.unknown:
      return Routes.pending;
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The application router. Redirects are driven by Supabase readiness, auth
/// state and the signed-in user's role/status.
final routerProvider = Provider<GoRouter>((ref) {
  // Bump this notifier whenever auth or the user profile changes so GoRouter
  // re-evaluates its redirect.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..listen(appUserProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1) Supabase not configured -> lock everything to the setup screen.
      final supabaseReady = ref.read(supabaseReadyProvider);
      if (!supabaseReady) {
        return loc == Routes.setup ? null : Routes.setup;
      }
      if (loc == Routes.setup) return Routes.login;

      final authState = ref.read(authStateProvider);
      final signedIn = authState.value != null;

      // 2) Signed out -> only the login page is reachable.
      if (!signedIn) {
        return loc == Routes.login ? null : Routes.login;
      }

      // 3) Signed in: resolve the profile document.
      // Check cached profile first for instant zero-latency redirect upon login
      final auth = ref.read(authServiceProvider);
      final cached = auth.cachedUserProfile;
      final appUserAsync = ref.read(appUserProvider);

      if (cached == null && appUserAsync.isLoading) {
        return loc == Routes.loading ? null : Routes.loading;
      }
      final appUser = cached ?? appUserAsync.value;

      // Signed in but no/invalid profile, or awaiting approval.
      if (appUser == null ||
          appUser.role == UserRole.unknown ||
          appUser.status == UserStatus.pending ||
          appUser.status == UserStatus.disabled) {
        return loc == Routes.pending ? null : Routes.pending;
      }

      // 4) Active user: send them to their role home if they're on a
      // pre-auth / mismatched route.
      final home = _homeForRole(appUser.role);
      const preAuth = {
        Routes.login,
        Routes.loading,
        Routes.pending,
        Routes.setup,
      };
      if (preAuth.contains(loc)) return home;

      // Cross-role URL tamper protection
      const roleHomes = {Routes.admin, Routes.employee, Routes.company};
      if (roleHomes.contains(loc) && loc != home) return home;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.setup,
        builder: (_, _) => const SetupRequiredView(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginView(),
      ),
      GoRoute(
        path: Routes.loading,
        builder: (_, _) => const LoadingView(),
      ),
      GoRoute(
        path: Routes.pending,
        builder: (_, _) => const PendingView(),
      ),
      GoRoute(
        path: Routes.admin,
        builder: (_, _) => const AdminDashboardView(),
      ),
      GoRoute(
        path: Routes.employee,
        builder: (_, _) => const HelperDashboardView(),
      ),
      GoRoute(
        path: Routes.company,
        builder: (_, _) => const OfficeDashboardView(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
