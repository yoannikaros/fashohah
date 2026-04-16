import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/navigation_provider.dart';
import '../features/dzikir/presentation/pages/dzikir_category_page.dart';
import '../features/prayer/presentation/pages/prayer_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/home/presentation/pages/home_screen.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _pages = [
    HomeScreen(),  // 0 — Beranda
    PrayerPage(),  // 1 — Sholat
    DzikirCategoryPage(), // 2 — Zikir
    SettingsPage(), // 3 — Pengaturan
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = i,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_rounded),
            label: 'Sholat',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Zikir',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
