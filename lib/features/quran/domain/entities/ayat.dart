import 'package:equatable/equatable.dart';

class Ayat extends Equatable {
  const Ayat({
    required this.nomorAyat,
    required this.nomorSurat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audioUrls,
  });

  final int nomorAyat;
  final int nomorSurat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;

  /// Key: qari ID (e.g. "01", "02", ..., "05")
  final Map<String, String> audioUrls;

  /// ID unik untuk audio manager — format: "surat-ayat"
  String get audioId => '$nomorSurat-$nomorAyat';

  /// URL audio default (qari 01 = Abdullah Al-Juhany)
  String get defaultAudioUrl => audioUrls['01'] ?? audioUrls.values.first;

  String audioUrl(String qariId) =>
      audioUrls[qariId] ?? audioUrls['01'] ?? audioUrls.values.first;

  @override
  List<Object?> get props => [nomorAyat, nomorSurat];
}
