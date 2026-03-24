import '../entities/ayat.dart';
import '../entities/surat.dart';

abstract interface class QuranRepository {
  Future<List<Surat>> getSurats();
  Future<(Surat, List<Ayat>)> getSuratDetail(int nomorSurat);
}
