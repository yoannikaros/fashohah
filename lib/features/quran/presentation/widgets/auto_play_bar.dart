import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_manager.dart';
import '../../../../core/audio/audio_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ayat.dart';
import '../providers/quran_provider.dart';

class AutoPlayBar extends ConsumerWidget {
  const AutoPlayBar({super.key, required this.ayatList});

  final List<Ayat> ayatList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioManager = ref.read(audioManagerProvider.notifier);
    final audioState = ref.watch(audioManagerProvider);
    final selectedQari = ref.watch(selectedQariProvider);
    final isAutoPlaying = audioManager.isAutoPlaying;
    final cs = Theme.of(context).colorScheme;

    final hasAudio = audioState.currentAyatId != null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Status info ───────────────────────────────────────
              Expanded(
                child: hasAudio
                    ? _NowPlayingInfo(
                        audioState: audioState,
                        isAutoPlaying: isAutoPlaying,
                      )
                    : Text(
                        'Tap ▶ pada ayat untuk memutar',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              // ── Play All / Stop ───────────────────────────────────
              _PlayAllButton(
                isAutoPlaying: isAutoPlaying,
                onTap: () {
                  if (isAutoPlaying) {
                    audioManager.stop();
                  } else {
                    final queue = ayatList
                        .map((a) => (
                              ayatId: a.audioId,
                              url: a.audioUrl(selectedQari),
                            ))
                        .toList();
                    audioManager.startAutoPlay(queue);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowPlayingInfo extends StatelessWidget {
  const _NowPlayingInfo({
    required this.audioState,
    required this.isAutoPlaying,
  });

  final AudioState audioState;
  final bool isAutoPlaying;

  @override
  Widget build(BuildContext context) {
    final parts = audioState.currentAyatId?.split('-') ?? [];
    final nomorAyat = parts.length > 1 ? parts[1] : '?';

    final isPlaying = audioState.isPlaying;
    final isLoading = audioState.isLoading;

    return Row(
      children: [
        // Waveform / loading indicator
        _AnimatedWave(isPlaying: isPlaying, isLoading: isLoading),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAutoPlaying ? 'Auto Play — Ayat $nomorAyat' : 'Ayat $nomorAyat',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (audioState.duration > Duration.zero)
                Text(
                  '${_fmt(audioState.position)} / ${_fmt(audioState.duration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AnimatedWave extends StatelessWidget {
  const _AnimatedWave({required this.isPlaying, required this.isLoading});

  final bool isPlaying;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    return Icon(
      isPlaying ? Icons.equalizer_rounded : Icons.music_note_rounded,
      color: AppColors.primary,
      size: 20,
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  const _PlayAllButton({required this.isAutoPlaying, required this.onTap});

  final bool isAutoPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAutoPlaying
              ? Theme.of(context).colorScheme.error
              : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAutoPlaying ? Icons.stop_rounded : Icons.playlist_play_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isAutoPlaying ? 'Stop' : 'Play All',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
