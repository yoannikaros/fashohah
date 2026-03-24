import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kebijakan Privasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Privasi Fashohah',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Terakhir diperbarui: Maret 2025',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _Section(
            title: '1. Informasi yang Kami Kumpulkan',
            body:
                'Aplikasi Fashohah dirancang dengan mengutamakan privasi pengguna. Kami hanya mengakses data yang benar-benar diperlukan untuk fungsi aplikasi:\n\n'
                '• Lokasi perangkat (opsional) — digunakan untuk menghitung jadwal sholat berdasarkan koordinat GPS Anda. Lokasi tidak disimpan di server kami.\n\n'
                '• Data yang tersimpan lokal — jadwal sholat, dzikir favorit, dan preferensi pengaturan disimpan sepenuhnya di perangkat Anda menggunakan penyimpanan lokal.',
          ),

          _Section(
            title: '2. Penggunaan Data',
            body:
                'Data yang dikumpulkan digunakan semata-mata untuk:\n\n'
                '• Menampilkan jadwal sholat yang akurat sesuai lokasi Anda\n'
                '• Mengirimkan notifikasi pengingat adzan sesuai preferensi Anda\n'
                '• Menyimpan dzikir favorit dan riwayat hitungan dzikir\n'
                '• Menerapkan preferensi tampilan (tema, ukuran font)\n\n'
                'Kami tidak menggunakan data Anda untuk iklan, analitik pihak ketiga, atau tujuan komersial lainnya.',
          ),

          _Section(
            title: '3. Layanan Pihak Ketiga',
            body:
                'Aplikasi ini menggunakan layanan API pihak ketiga berikut:\n\n'
                '• Equran.id API — untuk data Al-Qur\'an dan audio tilawah. Tidak ada data pribadi yang dikirim ke layanan ini.\n\n'
                '• Aladhan.com API — untuk kalkulasi jadwal sholat. Koordinat lokasi dikirim secara anonim untuk menghitung waktu sholat.\n\n'
                'Layanan pihak ketiga ini memiliki kebijakan privasi masing-masing yang terpisah dari kebijakan ini.',
          ),

          _Section(
            title: '4. Izin Aplikasi',
            body:
                'Aplikasi meminta izin berikut:\n\n'
                '• Lokasi (Opsional) — untuk jadwal sholat otomatis berdasarkan posisi Anda. Jika ditolak, jadwal tetap tersedia menggunakan lokasi default (Jakarta).\n\n'
                '• Notifikasi — untuk mengirimkan pengingat waktu sholat. Dapat dinonaktifkan kapan saja melalui menu Pengaturan.\n\n'
                'Tidak ada izin yang bersifat wajib. Aplikasi dapat digunakan sepenuhnya tanpa memberikan izin apapun.',
          ),

          _Section(
            title: '5. Penyimpanan Data',
            body:
                'Seluruh data pengguna disimpan secara lokal di perangkat Anda:\n\n'
                '• Cache jadwal sholat disimpan menggunakan Hive local database\n'
                '• Preferensi dan bookmark disimpan menggunakan SharedPreferences\n'
                '• Audio Al-Qur\'an yang pernah diputar dapat di-cache secara lokal untuk akses offline\n\n'
                'Menghapus data aplikasi atau menguninstall aplikasi akan menghapus seluruh data tersebut secara permanen.',
          ),

          _Section(
            title: '6. Keamanan',
            body:
                'Kami mengambil langkah-langkah yang wajar untuk melindungi data Anda. Karena semua data disimpan lokal, keamanan data bergantung pada keamanan perangkat Anda sendiri. Kami menyarankan Anda untuk menggunakan proteksi layar kunci pada perangkat Anda.',
          ),

          _Section(
            title: '7. Perubahan Kebijakan',
            body:
                'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Perubahan akan diberitahukan melalui pembaruan aplikasi. Dengan terus menggunakan aplikasi setelah perubahan berlaku, Anda menyetujui kebijakan yang telah diperbarui.',
          ),

          _Section(
            title: '8. Hubungi Kami',
            body:
                'Jika Anda memiliki pertanyaan atau kekhawatiran mengenai kebijakan privasi ini, silakan hubungi kami melalui:\n\n'
                '• Email: support@fashohah.app\n\n'
                'Kami berkomitmen untuk menjawab setiap pertanyaan dalam waktu 7 hari kerja.',
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Dengan menggunakan aplikasi Fashohah, Anda menyetujui Kebijakan Privasi ini.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
