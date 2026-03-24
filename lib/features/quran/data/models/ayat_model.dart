import '../../domain/entities/ayat.dart';

class AyatModel extends Ayat {
  const AyatModel({
    required super.nomorAyat,
    required super.nomorSurat,
    required super.teksArab,
    required super.teksLatin,
    required super.teksIndonesia,
    required super.audioUrls,
  });

  factory AyatModel.fromJson(Map<String, dynamic> json, {required int nomorSurat}) {
    // API mengembalikan audio sebagai Map<String, String>
    final audioRaw = json['audio'];
    final Map<String, String> audioUrls = {};

    if (audioRaw is Map) {
      audioRaw.forEach((key, value) {
        audioUrls[key.toString()] = value.toString();
      });
    }

    return AyatModel(
      nomorAyat: json['nomorAyat'] as int,
      nomorSurat: nomorSurat,
      teksArab: json['teksArab'] as String,
      teksLatin: json['teksLatin'] as String,
      teksIndonesia: json['teksIndonesia'] as String,
      audioUrls: audioUrls,
    );
  }
}
