import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_state.dart';

/// Global AudioManager — satu instance untuk seluruh app.
/// Menggunakan flutter_soloud: SoLoud engine, zero external DLLs.
/// Works on Windows, Android, iOS, macOS, Linux.
class AudioManager extends Notifier<AudioState> {
  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  Timer? _positionTimer;
  late Dio _dio;

  // Queue untuk auto-play berurutan
  List<({String ayatId, String url})> _playQueue = [];
  int _queueIndex = 0;
  bool _isAutoPlaying = false;

  @override
  AudioState build() {
    _dio = Dio();

    ref.onDispose(() {
      _positionTimer?.cancel();
      _releaseCurrentSource();
    });

    return const AudioState();
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Putar satu ayat. Otomatis stop ayat sebelumnya.
  Future<void> playAyat(String ayatId, String url) async {
    _isAutoPlaying = false;
    _playQueue = [];
    await _playSingle(ayatId, url);
  }

  /// Toggle play/pause. Jika ayat berbeda → langsung ganti.
  Future<void> togglePlayPause(String ayatId, String url) async {
    if (state.currentAyatId == ayatId) {
      if (state.isPlaying) {
        await pause();
      } else if (state.isPaused) {
        await resume();
      } else {
        await playAyat(ayatId, url);
      }
    } else {
      await playAyat(ayatId, url);
    }
  }

  Future<void> pause() async {
    if (_currentHandle == null) return;
    SoLoud.instance.pauseSwitch(_currentHandle!);
    state = state.copyWith(status: AudioStatus.paused);
    _positionTimer?.cancel();
  }

  Future<void> resume() async {
    if (_currentHandle == null) return;
    SoLoud.instance.pauseSwitch(_currentHandle!);
    state = state.copyWith(status: AudioStatus.playing);
    _startPositionTimer();
  }

  Future<void> stop() async {
    _isAutoPlaying = false;
    _playQueue = [];
    _positionTimer?.cancel();
    await _releaseCurrentSource();
    state = const AudioState();
  }

  Future<void> seekTo(Duration position) async {
    if (_currentHandle == null) return;
    SoLoud.instance.seek(_currentHandle!, position);
    state = state.copyWith(position: position);
  }

  /// Auto-play seluruh ayat berurutan.
  Future<void> startAutoPlay(
      List<({String ayatId, String url})> ayatList) async {
    if (ayatList.isEmpty) return;
    _playQueue = List.from(ayatList);
    _queueIndex = 0;
    _isAutoPlaying = true;
    await _playFromQueue();
  }

  void stopAutoPlay() {
    _isAutoPlaying = false;
    _playQueue = [];
  }

  bool get isAutoPlaying => _isAutoPlaying;

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _playSingle(String ayatId, String url) async {
    try {
      // Update state ke loading sebelum stop yang lama
      state = state.copyWith(
        currentAyatId: ayatId,
        status: AudioStatus.loading,
        position: Duration.zero,
        duration: Duration.zero,
      );

      // Stop & release audio sebelumnya
      _positionTimer?.cancel();
      await _releaseCurrentSource();

      // Download dulu jika belum ada (offline cache)
      final localPath = await _getOrDownloadAudio(ayatId, url);

      if (localPath == null) {
        state = state.copyWith(
          status: AudioStatus.error,
          errorMessage: 'Gagal mengunduh audio. Periksa koneksi internet.',
        );
        return;
      }

      // Load file ke SoLoud
      _currentSource = await SoLoud.instance.loadFile(localPath);

      // Play
      _currentHandle = await SoLoud.instance.play(_currentSource!);

      // Update duration
      final duration = SoLoud.instance.getLength(_currentSource!);
      state = state.copyWith(
        status: AudioStatus.playing,
        duration: duration,
      );

      // Mulai polling posisi + deteksi selesai
      _startPositionTimer();
    } catch (e) {
      state = state.copyWith(
        status: AudioStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _playFromQueue() async {
    if (!_isAutoPlaying || _queueIndex >= _playQueue.length) {
      _isAutoPlaying = false;
      return;
    }
    final item = _playQueue[_queueIndex];
    await _playSingle(item.ayatId, item.url);
  }

  void _onAyatCompleted() {
    _positionTimer?.cancel();
    if (_isAutoPlaying) {
      _queueIndex++;
      _playFromQueue();
    } else {
      state = state.copyWith(status: AudioStatus.idle, clearAyatId: true);
    }
  }

  // ─── Position Timer ───────────────────────────────────────────────────────

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_currentHandle == null) return;

      // Cek apakah sudah selesai
      final isValid =
          SoLoud.instance.getIsValidVoiceHandle(_currentHandle!);
      if (!isValid) {
        _currentHandle = null;
        _onAyatCompleted();
        return;
      }

      // Update posisi
      try {
        final position = SoLoud.instance.getPosition(_currentHandle!);
        if (_currentSource != null) {
          final duration = SoLoud.instance.getLength(_currentSource!);
          state = state.copyWith(position: position, duration: duration);
        } else {
          state = state.copyWith(position: position);
        }
      } catch (_) {}
    });
  }

  // ─── Resource Management ──────────────────────────────────────────────────

  Future<void> _releaseCurrentSource() async {
    if (_currentHandle != null) {
      try {
        await SoLoud.instance.stop(_currentHandle!);
      } catch (_) {}
      _currentHandle = null;
    }
    if (_currentSource != null) {
      try {
        await SoLoud.instance.disposeSource(_currentSource!);
      } catch (_) {}
      _currentSource = null;
    }
  }

  // ─── Offline Cache ────────────────────────────────────────────────────────

  /// Download audio ke local storage. Return path jika sukses, null jika gagal.
  Future<String?> _getOrDownloadAudio(String ayatId, String url) async {
    try {
      final dir = await _getAudioCacheDir();
      final fileName = _sanitize('$ayatId.mp3');
      final file = File('${dir.path}/$fileName');

      // Sudah ada di cache → langsung return
      if (await file.exists()) return file.path;

      // Download
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        await file.writeAsBytes(response.data!);
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  Future<Directory> _getAudioCacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  Future<void> clearAudioCache(String ayatId) async {
    try {
      final dir = await _getAudioCacheDir();
      final file = File('${dir.path}/${_sanitize('$ayatId.mp3')}');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> clearAllAudioCache() async {
    try {
      final dir = await _getAudioCacheDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}

/// Provider global — satu instance untuk seluruh app.
final audioManagerProvider = NotifierProvider<AudioManager, AudioState>(
  AudioManager.new,
);
