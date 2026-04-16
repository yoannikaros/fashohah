import 'package:flutter/material.dart';

import '../../domain/entities/surat.dart';
import '../pages/surat_detail_page.dart';
import 'surat_card.dart';

/// SearchDelegate yang bisa dipakai dari manapun (home, surat list, dll).
class SuratSearchDelegate extends SearchDelegate<Surat?> {
  SuratSearchDelegate(this.surats);

  final List<Surat> surats;

  @override
  String get searchFieldLabel => 'Cari nama atau arti surat...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? surats
        : surats.where((s) {
            return s.namaLatin.toLowerCase().contains(q) ||
                s.arti.toLowerCase().contains(q) ||
                s.nomor.toString() == q;
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Surat "$query" tidak ditemukan',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final surat = filtered[index];
        return SuratCard(
          surat: surat,
          isFirst: index == 0,
          isLast: index == filtered.length - 1,
          onTap: () {
            close(context, surat);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SuratDetailPage(nomorSurat: surat.nomor),
              ),
            );
          },
        );
      },
    );
  }
}
