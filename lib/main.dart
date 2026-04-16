import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/home_page.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/permission_page.dart';
import 'features/prayer/data/datasources/prayer_local_datasource.dart';
import 'features/prayer/presentation/providers/prayer_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi semua service secara paralel
  final futures = <Future>[
    _initHive(),
    SharedPreferences.getInstance(),
    SoLoud.instance.init(),
    NotificationService.instance.init(),
  ];
  // AdMob hanya tersedia di Android & iOS
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
  }
  final results = await Future.wait(futures);

  final localDatasource = results[0] as PrayerLocalDatasource;
  final prefs = results[1] as SharedPreferences;

  // Request notification permission
  await NotificationService.instance.requestPermission();

  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        // Inject instance yang sudah diinisialisasi
        sharedPreferencesProvider.overrideWithValue(prefs),
        prayerLocalDatasourceProvider.overrideWithValue(localDatasource),
      ],
      child: FashohahApp(onboardingDone: onboardingDone),
    ),
  );
}

/// Inisialisasi Hive dan return PrayerLocalDatasource yang sudah siap.
Future<PrayerLocalDatasource> _initHive() async {
  await Hive.initFlutter();
  final ds = PrayerLocalDatasource();
  await ds.init();
  return ds;
}

class FashohahApp extends ConsumerWidget {
  final bool onboardingDone;
  const FashohahApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Fashohah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: onboardingDone ? const HomePage() : const PermissionPage(),
    );
  }
}
