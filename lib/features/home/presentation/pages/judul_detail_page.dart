import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/audio/audio_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/api_category_detail_model.dart';
import '../providers/judul_detail_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../payment/presentation/pages/premium_upgrade_page.dart';
import 'home_screen.dart' show kTeal, ArabesquePainter;

// Font Arab bergaya mushaf (Amiri — Naskh klasik)
TextStyle _arabicStyle({
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.w600,
  double height = 1.6,
  Color? color,
}) =>
    GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class JudulDetailPage extends ConsumerWidget {
  const JudulDetailPage({
    super.key,
    required this.judulId,
    required this.judulName,
  });

  final int judulId;
  final String judulName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(judulDetailProvider(judulId));
    final cs = Theme.of(context).colorScheme;

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: cs.surface,
        body: _LoadingView(title: judulName),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: cs.surface,
        body: _ErrorView(
          title: judulName,
          message: e.toString(),
          onRetry: () => ref.invalidate(judulDetailProvider(judulId)),
        ),
      ),
      data: (detail) {
        final numberOne =
            detail.subtitles.where((s) => s.number == 1).firstOrNull;
        final audioUrl = numberOne?.audio ?? '';

        // Jika konten terkunci — tampilkan overlay premium gate
        if (detail.isLocked) {
          final topPad = MediaQuery.of(context).padding.top;
          return Scaffold(
            backgroundColor: cs.surface,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Konten di belakang (sebagian tersembunyi, scroll dinonaktifkan)
                AbsorbPointer(
                  child: _ContentView(
                    detail: detail,
                    hideBackButton: true,
                  ),
                ),
                // Overlay premium gate
                Positioned.fill(
                  child: _PremiumGateOverlay(
                    detail: detail,
                    judulId: judulId,
                  ),
                ),
                // Tombol back — di atas overlay agar tetap bisa ditekan
                Positioned(
                  top: topPad + 4,
                  left: 4,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          body: _ContentView(detail: detail),
          bottomNavigationBar: (numberOne != null && audioUrl.isNotEmpty)
              ? _AudioPlayerBar(item: numberOne)
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONTENT VIEW
// ─────────────────────────────────────────────────────────────
class _ContentView extends StatelessWidget {
  const _ContentView({required this.detail, this.hideBackButton = false});
  final ApiJudulDetail detail;
  final bool hideBackButton;

  static const _headerHeight = 190.0;
  static const _overlap = 80.0;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // ── Layer 1: teal + batik arabesque ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _headerHeight + topPad,
          child: Container(
            color: kTeal,
            child: CustomPaint(painter: ArabesquePainter()),
          ),
        ),

        // ── Layer 2: konten rounded top ──
        Positioned.fill(
          top: _headerHeight + topPad - _overlap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  const _BismillahDivider(),
                  // ── Baris khusus untuk subtitle number 1 ──
                  Builder(builder: (context) {
                    final numberOne = detail.subtitles
                        .where((s) => s.number == 1)
                        .firstOrNull;
                    if (numberOne == null) return const SizedBox.shrink();
                    return _NumberOneRow(item: numberOne);
                  }),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: _ArabicGrid(subtitles: detail.subtitles),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Layer 3: header teks + back button ──
        Positioned(
          top: topPad,
          left: 0,
          right: 0,
          height: _headerHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 28, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!hideBackButton)
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        detail.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // ── Badge sisa tampilan premium ──
                    if (detail.isPremium &&
                        !detail.isLocked &&
                        detail.viewsRemaining > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.remove_red_eye_outlined,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${detail.viewsRemaining}x lagi',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    // ── Tombol info penjelasan number 1 ──
                    Builder(builder: (ctx) {
                      final numberOne = detail.subtitles
                          .where((s) => s.number == 1)
                          .firstOrNull;
                      if (numberOne == null) return const SizedBox.shrink();
                      return IconButton(
                        onPressed: () => _showPenjelasanDialog(
                          ctx,
                          numberOne.subtitle,
                          numberOne.penjelasan,
                        ),
                        icon: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        tooltip: 'Penjelasan',
                      );
                    }),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    detail.namaKategori,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DIALOG PENJELASAN
// ─────────────────────────────────────────────────────────────
void _showPenjelasanDialog(
  BuildContext context,
  String arabicChar,
  String penjelasan,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _PenjelasanDialog(
      arabicChar: arabicChar,
      penjelasan: penjelasan,
    ),
  );
}

class _PenjelasanDialog extends StatelessWidget {
  const _PenjelasanDialog({
    required this.arabicChar,
    required this.penjelasan,
  });

  final String arabicChar;
  final String penjelasan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEmpty = penjelasan.trim().isEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header dengan warna primary ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Karakter Arab besar

                  const Text(
                    'Penjelasan Huruf',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cara membaca dan pengucapan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body penjelasan ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: isEmpty
                    ? Column(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 40,
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada penjelasan untuk huruf ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.45),
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : _PenjelasanBody(penjelasan: penjelasan, cs: cs),
              ),
            ),

            // ── Divider + tombol tutup ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Render teks penjelasan — baris yang diawali "•" atau "-" jadi bullet,
/// baris kosong jadi spasi, sisanya teks biasa.
class _PenjelasanBody extends StatelessWidget {
  const _PenjelasanBody({required this.penjelasan, required this.cs});
  final String penjelasan;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final lines = penjelasan.split('\n').map((l) => l.trimRight()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          if (line.trim().isEmpty)
            const SizedBox(height: 8)
          else if (line.trim().startsWith('•') ||
              line.trim().startsWith('-') ||
              line.trim().startsWith('*'))
            _BulletLine(text: line.trim().substring(1).trim(), cs: cs)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.cs});
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.65,
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BISMILLAH DIVIDER
// ─────────────────────────────────────────────────────────────
class _BismillahDivider extends StatelessWidget {
  const _BismillahDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: _arabicStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 2.0,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ARABIC GRID — 2 | spasi | 3 per baris
// ─────────────────────────────────────────────────────────────
class _ArabicGrid extends StatelessWidget {
  const _ArabicGrid({required this.subtitles});
  final List<ApiSubtitleItem> subtitles;

  @override
  Widget build(BuildContext context) {
    // Exclude item number 1 karena sudah ditampilkan di baris khusus
    final filtered = subtitles.where((s) => s.number != 1).toList();

    // Bagi jadi chunk 5 item (2 kanan + 3 kiri)
    final rows = <List<ApiSubtitleItem>>[];
    for (var i = 0; i < filtered.length; i += 5) {
      final end = (i + 5).clamp(0, filtered.length);
      rows.add(filtered.sublist(i, end));
    }

    return Column(
      children: rows.map((chunk) {
        final right = chunk.take(2).toList();
        final left = chunk.skip(2).take(3).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 2 item kanan ──
                for (final item in right) ...[
                  Expanded(child: _ArabicCell(item: item)),
                  const SizedBox(width: 6),
                ],
                // Placeholder jika kanan tidak penuh
                for (var i = right.length; i < 2; i++) ...[
                  const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 6),
                ],

                // ── Spasi tengah ──
                const SizedBox(width: 24),

                // ── 3 item kiri ──
                for (var i = 0; i < 3; i++) ...[
                  const SizedBox(width: 6),
                  if (i < left.length)
                    Expanded(child: _ArabicCell(item: left[i]))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ARABIC CELL — satu item dalam grid
// ─────────────────────────────────────────────────────────────
class _ArabicCell extends ConsumerWidget {
  const _ArabicCell({required this.item, super.key});
  final ApiSubtitleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final audioState = ref.watch(audioManagerProvider);
    final audioManager = ref.read(audioManagerProvider.notifier);

    final hasAudio = item.audio != null && item.audio!.isNotEmpty;
    final isCurrent = hasAudio && audioState.isCurrentAyat(item.audioId);
    final isPlaying = isCurrent && audioState.isPlaying;
    final isLoading = isCurrent && audioState.isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isPlaying
            ? cs.primary.withValues(alpha: 0.15)
            : isCurrent
                ? cs.primary.withValues(alpha: 0.07)
                : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlaying
              ? cs.primary
              : isCurrent
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outline,
          width: isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasAudio
                ? () => audioManager.togglePlayPause(item.audioId, item.audio!)
                : null,
            splashColor: cs.primary.withValues(alpha: 0.15),
            highlightColor: cs.primary.withValues(alpha: 0.08),
            child: Stack(
              children: [
                // ── Teks Arab — di tengah cell ──
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: _arabicStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                          color: isPlaying
                              ? cs.primary
                              : hasAudio
                                  ? cs.onSurface
                                  : cs.onSurface.withValues(alpha: 0.35),
                        ),
                        child: Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Loading spinner overlay ──
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Ikon play kecil di bawah ──
                if (hasAudio && !isCurrent)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 12,
                      color: cs.primary.withValues(alpha: 0.5),
                    ),
                  ),

                // ── Ikon equalizer saat playing ──
                if (isPlaying)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 13,
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NUMBER ONE ROW — baris penuh khusus subtitle number 1
// ─────────────────────────────────────────────────────────────
class _NumberOneRow extends ConsumerWidget {
  const _NumberOneRow({required this.item});
  final ApiSubtitleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final audioState = ref.watch(audioManagerProvider);
    final audioManager = ref.read(audioManagerProvider.notifier);

    final hasAudio = item.audio != null && item.audio!.isNotEmpty;
    final isCurrent = hasAudio && audioState.isCurrentAyat(item.audioId);
    final isPlaying = isCurrent && audioState.isPlaying;
    final isLoading = isCurrent && audioState.isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: isPlaying
            ? cs.primary.withValues(alpha: 0.15)
            : isCurrent
                ? cs.primary.withValues(alpha: 0.07)
                : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying
              ? cs.primary
              : isCurrent
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outline,
          width: isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasAudio
                ? () => audioManager.togglePlayPause(item.audioId, item.audio!)
                : null,
            splashColor: cs.primary.withValues(alpha: 0.15),
            highlightColor: cs.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // ── Teks Arab — memenuhi lebar ──
                  Expanded(
                    child: Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: _arabicStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        color: isPlaying ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Ikon status ──
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  else if (hasAudio)
                    Icon(
                      isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                      color:
                          cs.primary.withValues(alpha: isPlaying ? 1.0 : 0.5),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUDIO PLAYER BAR — bottom bar untuk play audio subtitle number 1
// ─────────────────────────────────────────────────────────────
class _AudioPlayerBar extends ConsumerWidget {
  const _AudioPlayerBar({required this.item});
  final ApiSubtitleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final audioState = ref.watch(audioManagerProvider);
    final audioManager = ref.read(audioManagerProvider.notifier);

    final isCurrent = audioState.isCurrentAyat(item.audioId);
    final isPlaying = isCurrent && audioState.isPlaying;
    final isLoading = isCurrent && audioState.isLoading;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Ikon speaker ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPlaying ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // ── Label ──
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Penjelasan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPlaying ? 'Sedang diputar...' : 'Tap untuk memutar',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Tombol play / loading ──
            if (isLoading)
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.primary,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () =>
                    audioManager.togglePlayPause(item.audioId, item.audio!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? cs.primary
                        : cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlaying ? Colors.white : cs.primary,
                    size: 24,
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
//  PREMIUM GATE OVERLAY
// ─────────────────────────────────────────────────────────────

class _PremiumGateOverlay extends ConsumerWidget {
  const _PremiumGateOverlay({
    required this.detail,
    required this.judulId,
  });

  final ApiJudulDetail detail;
  final int judulId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Gradient full-screen — non-interactive ──
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface.withValues(alpha: 0.0),
                  cs.surface.withValues(alpha: 0.75),
                  cs.surface,
                ],
                stops: const [0.0, 0.35, 0.55],
              ),
            ),
          ),
        ),

        // ── Gate card — tengah layar ──
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ikon kunci
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: detail.requiresLogin
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      detail.requiresLogin
                          ? Icons.person_outline_rounded
                          : Icons.workspace_premium_rounded,
                      size: 30,
                      color: detail.requiresLogin
                          ? AppColors.primary
                          : Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul
                  Text(
                    detail.requiresLogin
                        ? 'Daftar untuk Melanjutkan'
                        : 'Konten Premium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Pesan
                  Text(
                    detail.requiresLogin
                        ? 'Kamu sudah melihat konten ini 3 kali.\nDaftar gratis atau masuk untuk melanjutkan.'
                        : 'Konten ini khusus untuk member premium.\nUpgrade sekarang untuk akses penuh.',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  if (detail.requiresLogin) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                        if (result == true) {
                          ref.invalidate(judulDetailProvider(judulId));
                        }
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Daftar Gratis',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                        );
                        if (result == true) {
                          ref.invalidate(judulDetailProvider(judulId));
                        }
                      },
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Sudah Punya Akun? Masuk',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: () async {
                        if (!isLoggedIn) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                          if (result == true) {
                            ref.invalidate(judulDetailProvider(judulId));
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PremiumUpgradePage()),
                          );
                        }
                      },
                      icon: const Icon(Icons.workspace_premium_rounded,
                          size: 18),
                      label: const Text('Upgrade Premium',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING
// ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 190 + topPad,
          child: Container(
            color: kTeal,
            child: CustomPaint(painter: ArabesquePainter()),
          ),
        ),
        Positioned.fill(
          top: 190 + topPad - 80,
          child: ColoredBox(color: cs.surface),
        ),
        Positioned(
          top: topPad,
          left: 0,
          right: 0,
          height: 190,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 28, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ERROR
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 190 + topPad,
          child: Container(
            color: kTeal,
            child: CustomPaint(painter: ArabesquePainter()),
          ),
        ),
        Positioned.fill(
          top: 190 + topPad - 80,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: cs.primary),
                    const SizedBox(height: 16),
                    Text('Gagal memuat materi',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55))),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPad,
          left: 0,
          right: 0,
          height: 190,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 28, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
