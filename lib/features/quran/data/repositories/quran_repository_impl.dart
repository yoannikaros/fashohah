import '../../domain/entities/ayat.dart';
import '../../domain/entities/surat.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_remote_datasource.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._remote);

  final QuranRemoteDatasource _remote;

  @override
  Future<List<Surat>> getSurats() async {
    return _remote.getSurats();
  }

  @override
  Future<(Surat, List<Ayat>)> getSuratDetail(int nomorSurat) async {
    return _remote.getSuratDetail(nomorSurat);
  }
}
