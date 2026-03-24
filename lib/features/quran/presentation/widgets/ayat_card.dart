import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_manager.dart';
import '../../../../core/audio/audio_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ayat.dart';
import '../providers/quran_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class AyatCard extends ConsumerWidget {
  const AyatCard({
    super.key,
    required this.ayat,
    this.isFirst = false,
    this.isLast = false,
  });

  final Ayat ayat;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioManagerProvider);
    final selectedQari = ref.watch(selectedQariProvider);
    final audioManager = ref.read(audioManagerProvider.notifier);
    final arabicFontSize = ref.watch(arabicFontSizeProvider);

    final isCurrent = audioState.isCurrentAyat(ayat.audioId);
    final isPlaying = isCurrent && audioState.isPlaying;
    final isLoading = isCurrent && audioState.isLoading;

    final cs = Theme.of(context).colorScheme;

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(14) : Radius.zero,
      bottom: isLast ? const Radius.circular(14) : Radius.zero,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.06)
            : cs.surface,
        borderRadius: radius,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cs.outline.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Accent bar kiri saat aktif ──────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isCurrent ? 3 : 0,
                color: AppColors.primary,
              ),

              // ── Konten ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: nomor + tombol play
                    _AyatHeader(
                      ayat: ayat,
                      isPlaying: isPlaying,
                      isLoading: isLoading,
                      isCurrent: isCurrent,
                      onPlayTap: () => audioManager.togglePlayPause(
                        ayat.audioId,
                        ayat.audioUrl(selectedQari),
                      ),
                    ),

                    // Teks Arab
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Text(
                        ayat.teksArab,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: arabicFontSize,
                          height: 2.0,
                          color: isCurrent
                              ? AppColors.primary
                              : cs.onSurface.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // Divider tipis
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: cs.outline.withValues(alpha: 0.4),
                    ),

                    // Teks Latin
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        ayat.teksLatin,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    // Terjemahan
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                      child: Text(
                        ayat.teksIndonesia,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),

                    // Progress bar
                    if (isCurrent && audioState.duration > Duration.zero)
                      _AudioProgressBar(audioState: audioState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _AyatHeader extends StatelessWidget {
  const _AyatHeader({
    required this.ayat,
    required this.isPlaying,
    required this.isLoading,
    required this.isCurrent,
    required this.onPlayTap,
  });

  final Ayat ayat;
  final bool isPlaying;
  final bool isLoading;
  final bool isCurrent;
  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: Row(
        children: [
          // Nomor ayat — pill kecil
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ayat.nomorAyat}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCurrent ? Colors.white : AppColors.primary,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const Spacer(),

          // Tombol play
          SizedBox(
            width: 40,
            height: 40,
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPlayTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? AppColors.primary
                              : cs.onSurface.withValues(alpha: 0.5),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar ──────────────────────────────────────────────────────────

class _AudioProgressBar extends StatelessWidget {
  const _AudioProgressBar({required this.audioState});

  final AudioState audioState;

  @override
  Widget build(BuildContext context) {
    final progress = audioState.duration.inMilliseconds > 0
        ? audioState.position.inMilliseconds /
            audioState.duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (_) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(audioState.position),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  _fmt(audioState.duration),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
