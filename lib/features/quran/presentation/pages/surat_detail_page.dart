import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ayat.dart';
import '../../domain/entities/surat.dart';
import '../providers/quran_provider.dart';
import '../widgets/auto_play_bar.dart';
import '../widgets/ayat_card.dart';

class SuratDetailPage extends ConsumerWidget {
  const SuratDetailPage({super.key, required this.nomorSurat});

  final int nomorSurat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(suratDetailProvider(nomorSurat));

    return detailAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(
        message: e.toString(),
        onRetry: () => ref.invalidate(suratDetailProvider(nomorSurat)),
      ),
      data: (data) {
        final (surat, ayatList) = data;
        return _SuratDetailBody(surat: surat, ayatList: ayatList);
      },
    );
  }
}

class _SuratDetailBody extends ConsumerWidget {
  const _SuratDetailBody({required this.surat, required this.ayatList});

  final Surat surat;
  final List<Ayat> ayatList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(surat.namaLatin),
        // actions: [
        //   //const QariSelector(),
        //   IconButton(
        //     icon: Icon(
        //       Icons.stop_circle_outlined,
        //       color: Theme.of(context)
        //           .colorScheme
        //           .onSurface
        //           .withValues(alpha: 0.5),
        //     ),
        //     onPressed: () => audioManager.stop(),
        //     tooltip: 'Stop Audio',
        //   ),
        // ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SuratHeader(surat: surat)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.separated(
              itemCount: ayatList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (context, index) => AyatCard(
                ayat: ayatList[index],
                isFirst: index == 0,
                isLast: index == ayatList.length - 1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: AutoPlayBar(ayatList: ayatList),
    );
  }
}

// ─── Surat Header ──────────────────────────────────────────────────────────

class _SuratHeader extends StatelessWidget {
  const _SuratHeader({required this.surat});

  final Surat surat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Nama Arab besar
          Text(
            surat.nama,
            style: GoogleFonts.amiri(
              fontSize: 52,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Nama Latin
          Text(
            surat.namaLatin,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  letterSpacing: -0.4,
                ),
          ),

          const SizedBox(height: 4),

          // Arti
          Text(
            surat.arti,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),

          // Chips metadata
          Wrap(
            spacing: 8,
            children: [
              _Chip(label: surat.tempatTurun),
              _Chip(label: '${surat.jumlahAyat} Ayat'),
              _Chip(label: 'Surat ke-${surat.nomor}'),
            ],
          ),

          // Bismillah — kecuali At-Taubah (9)
          if (surat.nomor != 9) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Divider(color: cs.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      color: cs.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      height: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ─── Loading & Error ───────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Terjadi Kesalahan',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
