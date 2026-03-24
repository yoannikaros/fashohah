import 'package:dio/dio.dart';

import '../models/ayat_model.dart';
import '../models/surat_model.dart';

class QuranRemoteDatasource {
  QuranRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<SuratModel>> getSurats() async {
    final response = await _dio.get<Map<String, dynamic>>('/surat');
    final data = response.data;

    if (data == null || data['code'] != 200) {
      throw Exception('Gagal mengambil daftar surat: ${data?['message']}');
    }

    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => SuratModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<(SuratModel, List<AyatModel>)> getSuratDetail(int nomor) async {
    final response = await _dio.get<Map<String, dynamic>>('/surat/$nomor');
    final data = response.data;

    if (data == null || data['code'] != 200) {
      throw Exception('Gagal mengambil detail surat: ${data?['message']}');
    }

    final suratData = data['data'] as Map<String, dynamic>;
    final surat = SuratModel.fromJson(suratData);

    final ayatList = (suratData['ayat'] as List<dynamic>)
        .map((e) => AyatModel.fromJson(
              e as Map<String, dynamic>,
              nomorSurat: nomor,
            ))
        .toList();

    return (surat, ayatList);
  }
}
