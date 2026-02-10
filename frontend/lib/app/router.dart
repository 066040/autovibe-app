// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/app_shell.dart';

// Tabs
import '../autovibe/autovibe_home_screen.dart';
import '../autovibe/autovibe_pager.dart';
import '../features/vibes/vibes_screen.dart';
import '../features/news/news_screen.dart';
import '../features/market/market_screen.dart';
import '../features/profile/profile_screen.dart';

// Profile overlays
import '../features/profile/edit_profile_screen.dart';

// Auth
import '../features/auth/login_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';

// Root overlays
import '../core/models/article.dart';

import '../features/settings/settings_screen.dart';

import '../features/article_detail/article_detail_screen.dart';

// -------------------- NAV KEYS --------------------
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final _feedKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final _vibesKey = GlobalKey<NavigatorState>(debugLabel: 'vibes');
final _newsKey = GlobalKey<NavigatorState>(debugLabel: 'news');
final _marketKey = GlobalKey<NavigatorState>(debugLabel: 'market');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final goRouterProvider = Provider<GoRouter>((ref) {
  // auth state'i izleyelim (refresh + redirect doğru çalışsın)
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,

    // ✅ Riverpod auth değişince GoRouter refresh
    refreshListenable: _RouterRefresh(ref),

    // ✅ Auth guard
    redirect: (context, state) {
      final a = ref.read(authControllerProvider);

      // Boot/readToken bitmeden zıplama
      if (a.loading) return null;

      final loc = state.matchedLocation;

      final goingAuth = loc == '/login' || loc == '/register' || loc == '/forgot';

      // login değilken ve authed değilse -> login
      if (!a.isAuthed && !goingAuth) return '/login';

      // authed ise ve auth sayfalarına gidiyorsa -> home
      if (a.isAuthed && goingAuth) return '/autovibe/autovibe_home';

      return null;
    },

    routes: [
      // ---------- AUTH ----------
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),

      // ---------- SHELL (BOTTOM BAR) ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            rootKey: _rootKey,
            feedKey: _feedKey,
            vibesKey: _vibesKey,
            newsKey: _newsKey,
            marketKey: _marketKey,
            profileKey: _profileKey,
          );
        },
        branches: [
          // 0) FEED (AutoVibeHomeScreen)
          StatefulShellBranch(
            navigatorKey: _feedKey,
            routes: [
              GoRoute(
                path: '/autovibe/autovibe_home',
                name: 'autovibe_home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AutoVibePager()),
              ),
            ],
          ),

          // 1) VIBES
          StatefulShellBranch(
            navigatorKey: _vibesKey,
            routes: [
              GoRoute(
                path: '/vibes',
                name: 'vibes',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: VibesScreen()),
              ),
            ],
          ),

          // 2) NEWS
          StatefulShellBranch(
            navigatorKey: _newsKey,
            routes: [
              GoRoute(
                path: '/news',
                name: 'news',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: NewsScreen()),
              ),
            ],
          ),

          // 3) MARKET
          StatefulShellBranch(
            navigatorKey: _marketKey,
            routes: [
              GoRoute(
                path: '/market',
                name: 'market',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MarketScreen()),
              ),
            ],
          ),

          // 4) PROFILE
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // ---------- ROOT OVERLAYS (BOTTOM BAR ÜSTÜNE) ----------

      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SettingsScreen()),
      ),

      // ✅ Edit Profile overlay burada olmalı (branch içine koyma!)
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: EditProfileScreen()),
      ),

      GoRoute(
        path: '/article',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final a = state.extra as Article;
          return MaterialPage(child: ArticleDetailScreen(article: a));
        },
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}
