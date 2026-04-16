import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/utils/hijri_calculator.dart';
import '../../../prayer/domain/entities/prayer_day.dart';
import '../../../prayer/presentation/providers/prayer_provider.dart';
import 'category_page.dart';
import '../../../quran/presentation/pages/surat_list_page.dart';
import '../../../search/presentation/pages/search_page.dart';

// ─────────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────────
const kTeal = Color(0xFF00B5A5);
const kTealPattern = Color(0xFF009D8F);

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _now;
  Timer? _timer;
  final _scrollController = ScrollController();
  bool _showStickySearch = false;
  double _searchBarThreshold = 9999;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > _searchBarThreshold;
    if (show != _showStickySearch) {
      setState(() => _showStickySearch = show);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger auto-deteksi lokasi GPS
    ref.watch(prayerAutoLocationProvider);

    final kabkota = ref.watch(prayerKabkotaProvider);
    final todayAsync = ref.watch(todayPrayerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
          children: [
            // ── Section atas: dome.png menentukan tinggi Stack ──
            LayoutBuilder(
              builder: (context, constraints) {
                const aspect = 1319 / 1080;
                final domeH = constraints.maxWidth * aspect;
                final menuH =
                    domeH * 0.52 + MediaQuery.of(context).padding.top + 215;
                // Threshold: posisi tepat di mana search bar muncul
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _searchBarThreshold != menuH) {
                    setState(() => _searchBarThreshold = menuH);
                  }
                });
                return SizedBox(
                  height: menuH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Layer 1: teal+batik
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: domeH * 0.6,
                        child: Container(
                          color: kTeal,
                          child: CustomPaint(painter: ArabesquePainter()),
                        ),
                      ),
                      // Layer 1b: surface di bawah batik
                      Positioned(
                        top: domeH * 0.9,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(color: cs.surface),
                      ),
                      // Layer 2: dome.png
                      // Light mode : gambar asli
                      // Dark mode  : tint dengan warna surface (srcIn = hanya
                      //              piksel opaque dome yang diwarnai, transparan
                      //              tetap transparan → teal background terlihat)
                      Image.asset(
                        'assets/png/dome.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surface
                            : null,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      // Layer 3a: info konten
                      Positioned(
                        top: domeH * 0.28 + MediaQuery.of(context).padding.top,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _FashohahLogo(),
                            const SizedBox(height: 6),
                            _LocationRow(kabkota: kabkota),
                            const SizedBox(height: 10),
                            todayAsync.when(
                              loading: () => const _PrayerTimeBlock(
                                  prayerName: '--',
                                  prayerTime: '--:--',
                                  countdown: ''),
                              error: (_, __) => const _PrayerTimeBlock(
                                  prayerName: '--',
                                  prayerTime: '--:--',
                                  countdown: ''),
                              data: (today) {
                                if (today == null) {
                                  return const _PrayerTimeBlock(
                                      prayerName: '--',
                                      prayerTime: '--:--',
                                      countdown: '');
                                }
                                final next = today.nextPrayer;
                                final name = next?.name ?? 'Isya';
                                final time = next?.time ?? today.isha;
                                final countdown = next != null
                                    ? _formatCountdown(
                                        next.dateTime.difference(_now))
                                    : '';
                                return _PrayerTimeBlock(
                                  prayerName: name,
                                  prayerTime: time,
                                  countdown: countdown,
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            _DateRow(now: _now, today: todayAsync.value),
                          ],
                        ),
                      ),
                      // Layer 3b: menu grid
                      Positioned(
                        top: domeH * 0.52 + MediaQuery.of(context).padding.top,
                        left: 12,
                        right: 12,
                        child: const _MenuGrid(),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Konten scrollable di bawah dome ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SearchBar(),
            ),
            const SizedBox(height: 10),
            const _GreyDivider(),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _BannerSpace(),
            ),
            const SizedBox(height: 10),
            const _GreyDivider(),
            const SizedBox(height: 12),
            const _NewsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),

          // ── Sticky search bar muncul saat scroll ──
          AnimatedSlide(
            offset: _showStickySearch ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _showStickySearch ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: const _StickySearchBar(),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCountdown(Duration d) {
    if (d.isNegative) return '';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '- $h : $m : $s';
  }
}

// ─────────────────────────────────────────────────────────────
//  FASHOHAH LOGO
// ─────────────────────────────────────────────────────────────
class _FashohahLogo extends StatelessWidget {
  const _FashohahLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Fash" – italic teal
        const Text(
          'Fash',
          style: TextStyle(
            color: kTeal,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            height: 1.0,
          ),
        ),
        // Ring-circle "O"
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kTeal, width: 2.0),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kTeal,
              ),
            ),
          ),
        ),
        // "lah" – dark
        Text(
          'lah',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOCATION ROW
// ─────────────────────────────────────────────────────────────
class _LocationRow extends StatelessWidget {
  final String kabkota;
  const _LocationRow({required this.kabkota});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.location_on_rounded,
            color: Colors.redAccent, size: 13),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '$kabkota ',
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
        ),
        const Text(
          '(Ganti)',
          style: TextStyle(
            fontSize: 11,
            color: kTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRAYER TIME BLOCK
// ─────────────────────────────────────────────────────────────
class _PrayerTimeBlock extends StatelessWidget {
  final String prayerName;
  final String prayerTime;
  final String countdown;
  const _PrayerTimeBlock({
    required this.prayerName,
    required this.prayerTime,
    required this.countdown,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: cs.onSurface),
            children: [
              TextSpan(
                text: '$prayerName ',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              TextSpan(
                text: prayerTime,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const TextSpan(
                text: ' WIB',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (countdown.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            countdown,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.45),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATE ROW
// ─────────────────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  final DateTime now;
  final PrayerDay? today;
  const _DateRow({required this.now, required this.today});

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final gregorian = '${now.day} ${_months[now.month - 1]} ${now.year}';
    final hijri = today != null
        ? '${today!.hijriDay} ${today!.hijriMonthName} ${today!.hijriYear} H'
        : () {
            final h = HijriCalculator.fromGregorian(now);
            return '${h.day} ${h.monthName} ${h.year} H';
          }();

    return Text(
      '$gregorian / $hijri',
      style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MENU GRID
// ─────────────────────────────────────────────────────────────
class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  static const _items = [
    _MenuData(
        icon: Icons.menu_book_rounded,
        bg: Color(0xFFE2F5F0),
        iconColor: Color(0xFF2E8A6E),
        label: 'Al-Quran'),
    _MenuData(
        icon: Icons.back_hand_outlined,
        bg: Color(0xFFFFF3DC),
        iconColor: Color(0xFFB8860B),
        label: 'Wirid & Doa'),
    _MenuData(
        icon: Icons.access_time_rounded,
        bg: Color(0xFFFFFFFF),
        iconColor: kTeal,
        label: 'Jadwal Shalat',
        border: true),
    _MenuData(
        icon: Icons.explore_rounded,
        bg: Color(0xFFF0F0F0),
        iconColor: Color(0xFF444444),
        label: 'Kiblat'),
    _MenuData(
        icon: Icons.self_improvement_rounded,
        bg: Color(0xFFE3EEF9),
        iconColor: Color(0xFF3A7DCC),
        label: 'Tahlil & Yasin'),
    _MenuData(
        icon: Icons.import_contacts_rounded,
        bg: Color(0xFFE3F2E5),
        iconColor: Color(0xFF2E7D32),
        label: 'Maulid'),
    _MenuData(
        icon: Icons.volunteer_activism_rounded,
        bg: Color(0xFFFCE4EC),
        iconColor: Color(0xFFE53935),
        label: 'Zakat &\nSedekah'),
    _MenuData(
        icon: Icons.apps_rounded,
        bg: Color(0xFFDEF5F3),
        iconColor: kTeal,
        label: 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
        ),
        itemCount: _items.length,
        itemBuilder: (_, i) => _MenuCell(data: _items[i]),
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final String label;
  final bool border;
  const _MenuData({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.label,
    this.border = false,
  });
}

class _MenuCell extends StatelessWidget {
  final _MenuData data;
  const _MenuCell({required this.data, super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: switch (data.label) {
        'Lainnya' => () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
        'Al-Quran' => () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuratListPage()),
            ),
        _ => null,
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(height: 5),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GREY DIVIDER
// ─────────────────────────────────────────────────────────────
class _GreyDivider extends StatelessWidget {
  const _GreyDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BANNER SPACE
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
//  AD UNIT IDs
//  Ganti nilai di bawah dengan Ad Unit ID asli dari AdMob Console
//  saat siap production. Saat ini menggunakan test ID Google.
// ─────────────────────────────────────────────────────────────
const _kAdUnitIds = [
  'ca-app-pub-3940256099942544/6300978111', // Slot iklan 1 (test ID)
  'ca-app-pub-3940256099942544/6300978111', // Slot iklan 2 (test ID) — ganti dengan ID ke-2
];

class _BannerSpace extends StatefulWidget {
  const _BannerSpace();

  @override
  State<_BannerSpace> createState() => _BannerSpaceState();
}

class _BannerSpaceState extends State<_BannerSpace> {
  final _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Auto-slide setiap 8 detik
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _kAdUnitIds.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _kAdUnitIds.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _AdBannerSlide(adUnitId: _kAdUnitIds[i]),
          ),
          // Dot indicator
          if (_kAdUnitIds.length > 1)
            Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_kAdUnitIds.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: active ? 12 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: active
                          ? kTeal
                          : kTeal.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdBannerSlide extends StatefulWidget {
  const _AdBannerSlide({required this.adUnitId});
  final String adUnitId;

  @override
  State<_AdBannerSlide> createState() => _AdBannerSlideState();
}

class _AdBannerSlideState extends State<_AdBannerSlide> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // AdMob hanya tersedia di Android & iOS
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner, // 320×50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_loaded || _ad == null) {
      // Placeholder saat iklan belum muat
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Memuat iklan...',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.3),
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      ),
      child: Container(
        margin:
            const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 5),
        height: 43,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                color: cs.onSurface.withValues(alpha: 0.4), size: 18),
            const SizedBox(width: 8),
            Text(
              'Cari artikel, doa, kajian...',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STICKY SEARCH BAR (muncul saat scroll)
// ─────────────────────────────────────────────────────────────
class _StickySearchBar extends StatelessWidget {
  const _StickySearchBar();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      ),
      child: SizedBox(
        height: topPad + 52,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Layer 1: teal penuh + batik setinggi container
            Positioned.fill(
              child: ClipRect(
                child: ColoredBox(
                  color: kTeal,
                  child: CustomPaint(painter: ArabesquePainter()),
                ),
              ),
            ),
            // Layer 2: search field
            Positioned(
              left: 16,
              right: 16,
              top: topPad + 8,
              bottom: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search_rounded,
                          color: Colors.white, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        'Cari artikel, doa, kajian...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Cari',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NEWS LIST
// ─────────────────────────────────────────────────────────────
class _NewsList extends StatelessWidget {
  const _NewsList();

  static const _articles = [
    _Article('Hukum Membaca Qunut dalam Shalat Subuh', 'Fiqih', '2 jam lalu',
        Color(0xFFE3F2FD), Color(0xFF1565C0)),
    _Article('Kisah Sahabat Nabi: Umar bin Khattab', 'Sejarah', '4 jam lalu',
        Color(0xFFFFF3E0), Color(0xFFE65100)),
    _Article('Amalan Sunnah di Hari Jumat yang Dianjurkan', 'Ibadah',
        '5 jam lalu', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    _Article('Tafsir Surah Al-Fatihah: Makna Mendalam', 'Tafsir', '6 jam lalu',
        Color(0xFFF3E5F5), Color(0xFF6A1B9A)),
    _Article('Cara Menghitung Zakat Penghasilan Modern', 'Zakat', '8 jam lalu',
        Color(0xFFE0F7FA), Color(0xFF006064)),
    _Article('Doa Pagi Hari yang Diajarkan Rasulullah', 'Doa', '10 jam lalu',
        Color(0xFFFCE4EC), Color(0xFFB71C1C)),
    _Article('Pentingnya Shalat Berjamaah di Masjid', 'Ibadah', '12 jam lalu',
        Color(0xFFE8F5E9), Color(0xFF1B5E20)),
    _Article('Mengenal Ilmu Tajwid untuk Pemula', 'Al-Quran', '1 hari lalu',
        Color(0xFFE3F2FD), Color(0xFF0D47A1)),
    _Article('Sejarah Peradaban Islam di Nusantara', 'Sejarah', '1 hari lalu',
        Color(0xFFFFF8E1), Color(0xFFF57F17)),
    _Article('Rahasia Keutamaan Shalat Tahajud', 'Ibadah', '1 hari lalu',
        Color(0xFFEDE7F6), Color(0xFF4527A0)),
    _Article('Adab Bertetangga dalam Islam', 'Akhlak', '2 hari lalu',
        Color(0xFFE0F7FA), Color(0xFF00695C)),
    _Article('Makna Hijrah dalam Kehidupan Modern', 'Motivasi', '2 hari lalu',
        Color(0xFFFFEBEE), Color(0xFFC62828)),
    _Article('Panduan Lengkap Shalat Idul Fitri', 'Fiqih', '2 hari lalu',
        Color(0xFFE8F5E9), Color(0xFF388E3C)),
    _Article('Keutamaan Membaca Shalawat Nabi', 'Ibadah', '3 hari lalu',
        Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    _Article('Kisah Nabi Musa dan Pelajaran Hidup', 'Sejarah', '3 hari lalu',
        Color(0xFFFFF3E0), Color(0xFFBF360C)),
    _Article('Hukum Investasi Saham dalam Islam', 'Ekonomi', '3 hari lalu',
        Color(0xFFE3F2FD), Color(0xFF1976D2)),
    _Article('Tips Khusyuk dalam Shalat Sehari-hari', 'Ibadah', '4 hari lalu',
        Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    _Article('Ziarah Kubur: Hukum dan Adabnya', 'Fiqih', '4 hari lalu',
        Color(0xFFEDE7F6), Color(0xFF512DA8)),
    _Article('Mengenal Asmaul Husna dan Maknanya', 'Aqidah', '5 hari lalu',
        Color(0xFFE0F7FA), Color(0xFF0097A7)),
    _Article('Doa Mustajab di Waktu-waktu Utama', 'Doa', '5 hari lalu',
        Color(0xFFFCE4EC), Color(0xFFAD1457)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Artikel Terbaru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _NewsCard(article: _articles[i]),
        ),
      ],
    );
  }
}

class _Article {
  final String title;
  final String category;
  final String time;
  final Color catBg;
  final Color catColor;
  const _Article(
      this.title, this.category, this.time, this.catBg, this.catColor);
}

class _NewsCard extends StatelessWidget {
  final _Article article;
  const _NewsCard({required this.article, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: article.catBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.article_rounded, color: article.catColor, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: article.catBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: article.catColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 3),
                    Text(
                      article.time,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ARABESQUE PAINTER — hanya dirender di belakang dome.png
// ─────────────────────────────────────────────────────────────
class ArabesquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = kTealPattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = kTealPattern
      ..style = PaintingStyle.fill;
    const cw = 68.0;
    const ch = 68.0;
    for (double y = -ch; y < size.height + ch; y += ch) {
      final row = ((y + ch) / ch).floor();
      final ox = (row % 2 == 0) ? 0.0 : cw / 2;
      for (double x = -cw + ox; x < size.width + cw; x += cw) {
        _tile(canvas, stroke, fill, Offset(x, y), cw, ch);
      }
    }
  }

  void _tile(Canvas c, Paint s, Paint f, Offset o, double cw, double ch) {
    final cx = o.dx + cw / 2, cy = o.dy + ch / 2, pr = cw * 0.28;
    _rosette(c, s, f, cx, cy, pr);
    _vines(c, s, cx, cy, pr, cw, ch);
    _teardrops(c, s, cx, cy, cw * .46, cw * .10, cw * .055);
    _hearts(c, s, cx, cy, cw * .50);
  }

  void _rosette(Canvas c, Paint s, Paint f, double cx, double cy, double pr) {
    for (int i = 0; i < 8; i++) {
      final mid = (i + .5) * 2 * math.pi / 8 - math.pi / 2;
      final lft = i * 2 * math.pi / 8 - math.pi / 2;
      final rgt = (i + 1) * 2 * math.pi / 8 - math.pi / 2;
      final tx = cx + pr * math.cos(mid), ty = cy + pr * math.sin(mid);
      final sx = cx + pr * .42 * math.cos(lft),
          sy = cy + pr * .42 * math.sin(lft);
      final ex = cx + pr * .42 * math.cos(rgt),
          ey = cy + pr * .42 * math.sin(rgt);
      final c1x = cx + pr * .78 * math.cos(mid - .28),
          c1y = cy + pr * .78 * math.sin(mid - .28);
      final c2x = cx + pr * .78 * math.cos(mid + .28),
          c2y = cy + pr * .78 * math.sin(mid + .28);
      c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..cubicTo(c1x, c1y, c1x, c1y, tx, ty)
            ..cubicTo(c2x, c2y, c2x, c2y, ex, ey),
          s);
      c.drawCircle(Offset(tx, ty), 1.4, f);
    }
    c.drawCircle(Offset(cx, cy), pr * .20, s);
    c.drawCircle(Offset(cx, cy), pr * .08, f);
  }

  void _vines(Canvas c, Paint s, double cx, double cy, double pr, double cw,
      double ch) {
    for (final d in [
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0)
    ]) {
      final sx = cx + pr * .95 * d.dx, sy = cy + pr * .95 * d.dy;
      final ex = cx + cw / 2 * d.dx, ey = cy + ch / 2 * d.dy;
      final p = Offset(-d.dy, d.dx);
      c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..cubicTo(
                sx + (ex - sx) * .35 + p.dx * cw * .12,
                sy + (ey - sy) * .35 + p.dy * ch * .12,
                sx + (ex - sx) * .65 - p.dx * cw * .12,
                sy + (ey - sy) * .65 - p.dy * ch * .12,
                ex,
                ey),
          s);
    }
  }

  void _teardrops(Canvas c, Paint s, double cx, double cy, double dist,
      double h, double w) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      c.save();
      c.translate(cx + dist * math.cos(a), cy + dist * math.sin(a));
      c.rotate(a + math.pi / 2);
      c.drawPath(
          Path()
            ..moveTo(0, -h / 2)
            ..cubicTo(-w, -h * .1, -w, h * .35, 0, h / 2)
            ..cubicTo(w, h * .35, w, -h * .1, 0, -h / 2)
            ..close(),
          s);
      c.restore();
    }
  }

  void _hearts(Canvas c, Paint s, double cx, double cy, double dist) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final v = 7.0;
      c.save();
      c.translate(cx + dist * math.cos(a), cy + dist * math.sin(a));
      c.rotate(a + math.pi / 4);
      c.drawPath(
          Path()
            ..moveTo(0, v * .5)
            ..cubicTo(-v * .1, v * .15, -v * .5, -v * .05, -v * .5, -v * .25)
            ..cubicTo(-v * .5, -v * .55, 0, -v * .50, 0, -v * .15)
            ..cubicTo(0, -v * .50, v * .5, -v * .55, v * .5, -v * .25)
            ..cubicTo(v * .5, -v * .05, v * .1, v * .15, 0, v * .5)
            ..close(),
          s);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
