import 'package:equatable/equatable.dart';

enum AudioStatus { idle, loading, playing, paused, error }

class AudioState extends Equatable {
  const AudioState({
    this.currentAyatId,
    this.status = AudioStatus.idle,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.errorMessage,
  });

  final String? currentAyatId;
  final AudioStatus status;
  final Duration duration;
  final Duration position;
  final String? errorMessage;

  bool get isIdle => status == AudioStatus.idle;
  bool get isLoading => status == AudioStatus.loading;
  bool get isPlaying => status == AudioStatus.playing;
  bool get isPaused => status == AudioStatus.paused;
  bool get hasError => status == AudioStatus.error;

  bool isCurrentAyat(String ayatId) => currentAyatId == ayatId;

  AudioState copyWith({
    String? currentAyatId,
    AudioStatus? status,
    Duration? duration,
    Duration? position,
    String? errorMessage,
    bool clearAyatId = false,
  }) {
    return AudioState(
      currentAyatId: clearAyatId ? null : currentAyatId ?? this.currentAyatId,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentAyatId,
        status,
        duration,
        position,
        errorMessage,
      ];
}
