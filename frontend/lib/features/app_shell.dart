import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/reactions_controller.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  final GlobalKey<NavigatorState> rootKey;
  final GlobalKey<NavigatorState> feedKey;
  final GlobalKey<NavigatorState> vibesKey;
  final GlobalKey<NavigatorState> newsKey;
  final GlobalKey<NavigatorState> marketKey;
  final GlobalKey<NavigatorState> profileKey;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.rootKey,
    required this.feedKey,
    required this.vibesKey,
    required this.newsKey,
    required this.marketKey,
    required this.profileKey,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _accent = Color(0xFF2D6BFF);

  final List<int> _tabHistory = [0];
  DateTime? _lastBackAt;

  int get _currentIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    // App açılınca backend'ten beğeni/kayıt durumlarını çek
    Future.microtask(() async {
      try {
        await ref.read(reactionsControllerProvider.notifier).hydrate();
      } catch (_) {
        // offline vs durumlarda sessiz geç
      }
    });
  }

  GlobalKey<NavigatorState>? _getCurrentBranchKey() {
    switch (_currentIndex) {
      case 0:
        return widget.feedKey;
      case 1:
        return widget.vibesKey;
      case 2:
        return widget.newsKey;
      case 3:
        return widget.marketKey;
      case 4:
        return widget.profileKey;
      default:
        return null;
    }
  }

  void _addToHistory(int index) {
    if (_tabHistory.isNotEmpty && _tabHistory.last == index) return;
    _tabHistory.add(index);
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
    } else {
      _addToHistory(index);
      widget.navigationShell.goBranch(index);
    }
  }

  Future<void> _handleBackPress() async {
    // 1) Root overlay varsa kapat
    final rootState = widget.rootKey.currentState;
    if (rootState != null && rootState.canPop()) {
      rootState.pop();
      return;
    }

    // 2) Aktif tab içinde pop varsa pop
    final currentBranchKey = _getCurrentBranchKey();
    if (currentBranchKey != null && currentBranchKey.currentState != null) {
      if (currentBranchKey.currentState!.canPop()) {
        currentBranchKey.currentState!.pop();
        return;
      }
    }

    // 3) Tab history geri
    if (_tabHistory.length > 1) {
      setState(() => _tabHistory.removeLast());
      widget.navigationShell.goBranch(_tabHistory.last);
      return;
    }

    // 4) Çıkış için çift bas
    final now = DateTime.now();
    final last = _lastBackAt;
    if (last == null ||
        now.difference(last) > const Duration(milliseconds: 1500)) {
      _lastBackAt = now;
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkmak için tekrar geri bas'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTap,
          backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          indicatorColor: _accent.withOpacity(0.16),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Paylaş',
            ),
            NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: 'Vibes',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper),
              label: 'Oku',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Sat/Al',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
