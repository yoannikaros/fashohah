import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/pages/home_screen.dart'
    show kTeal, ArabesquePainter;
import '../../../home/presentation/pages/category_detail_page.dart';
import '../../../home/presentation/pages/judul_detail_page.dart';
import '../../../home/presentation/providers/category_provider.dart';
import '../../../quran/presentation/providers/quran_provider.dart';
import '../../../quran/presentation/pages/surat_detail_page.dart';
import '../../../quran/domain/entities/surat.dart';
import '../../data/models/search_models.dart';
import '../providers/search_provider.dart';


class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Autofocus setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = val.trim());
    });
  }

  void _clearSearch() {
    _ctrl.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Scaffold(
      backgroundColor: kTeal,
      body: Column(
        children: [
          // ── Header teal + arabesque + search field (fixed) ──
          SizedBox(
            height: 130 + topPad,
            child: CustomPaint(
              painter: ArabesquePainter(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPad + 8),
                  // Baris back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search_rounded,
                                color: Colors.white70, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focusNode,
                              onChanged: _onChanged,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'Cari artikel, doa, kajian...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          if (_ctrl.text.isNotEmpty)
                            IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 18),
                              padding: const EdgeInsets.only(right: 8),
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card dengan hasil — pola rounded seperti settings ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: _query.length < 2
                  ? _RecommendationsView(bottomPad: bottomPad)
                  : _SearchResultsView(
                      query: _query, bottomPad: bottomPad),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rekomendasi (saat query kosong) ─────────────────────────────────────────

class _RecommendationsView extends ConsumerWidget {
  const _RecommendationsView({required this.bottomPad});
  final double bottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(apiCategoryProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 52, 16, 24 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick link Al-Qur'an
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SuratDetailPage(nomorSurat: 1)),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B5A5), Color(0xFF007A6E)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('☪',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Al-Qur\'an',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('114 Surat',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'KATEGORI POPULER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 14),
          categoriesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailPage(
                        categoryId: cat.id,
                        categoryName: cat.namaKategori,
                        isPremium: cat.isPremium,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kTeal.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cat.isPremium) ...[
                          const Icon(Icons.workspace_premium_rounded,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          cat.namaKategori,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.search_rounded,
                    size: 48,
                    color: cs.onSurface.withValues(alpha: 0.12)),
                const SizedBox(height: 10),
                Text(
                  'Ketik untuk mulai mencari',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hasil Pencarian ─────────────────────────────────────────────────────────

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({
    required this.query,
    required this.bottomPad,
  });
  final String query;
  final double bottomPad;

  List<Surat> _filterSurat(List<Surat> all, String q) {
    final lower = q.toLowerCase();
    return all
        .where((s) =>
            s.namaLatin.toLowerCase().contains(lower) ||
            s.arti.toLowerCase().contains(lower) ||
            s.nama.contains(q) ||
            s.nomor.toString() == q.trim())
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final resultsAsync = ref.watch(searchProvider(query));
    final suratAsync = ref.watch(suratListProvider);

    // Surat hasil filter (client-side)
    final matchedSurat = suratAsync.maybeWhen(
      data: (list) => _filterSurat(list, query),
      orElse: () => <Surat>[],
    );

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 40, color: cs.onSurface.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              Text('Gagal memuat hasil',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ),
      data: (results) {
        final hasResults = !results.isEmpty || matchedSurat.isNotEmpty;

        if (!hasResults) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada hasil untuk\n"$query"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 52, 16, 24 + bottomPad),
          children: [
            // ── Al-Qur'an ──
            if (matchedSurat.isNotEmpty) ...[
              _SectionLabel('Al-Qur\'an', matchedSurat.length),
              const SizedBox(height: 8),
              ...matchedSurat.map((s) => _SuratResultTile(s)),
              const SizedBox(height: 20),
            ],

            // ── Kategori ──
            if (results.categories.isNotEmpty) ...[
              _SectionLabel('Kategori', results.categories.length),
              const SizedBox(height: 8),
              ...results.categories.map((cat) => _CategoryResultTile(cat)),
              const SizedBox(height: 20),
            ],

            // ── Judul / Artikel ──
            if (results.judul.isNotEmpty) ...[
              _SectionLabel('Artikel & Kajian', results.judul.length),
              const SizedBox(height: 8),
              ...results.judul.map((j) => _JudulResultTile(j)),
            ],
          ],
        );
      },
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SuratResultTile extends StatelessWidget {
  const _SuratResultTile(this.surat);
  final Surat surat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuratDetailPage(nomorSurat: surat.nomor),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${surat.nomor}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTeal,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              surat.namaLatin,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              surat.nama,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Amiri',
                color: kTeal,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${surat.arti} • ${surat.jumlahAyat} ayat • ${surat.tempatTurun}',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: kTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTeal,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryResultTile extends StatelessWidget {
  const _CategoryResultTile(this.cat);
  final SearchCategory cat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailPage(
              categoryId: cat.id,
              categoryName: cat.namaKategori,
              isPremium: cat.isPremium,
            ),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_outlined, color: kTeal, size: 20),
        ),
        title: Text(
          cat.namaKategori,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Kategori',
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
        trailing: cat.isPremium
            ? const Icon(Icons.workspace_premium_rounded,
                size: 16, color: Colors.amber)
            : Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _JudulResultTile extends StatelessWidget {
  const _JudulResultTile(this.judul);
  final SearchJudul judul;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JudulDetailPage(
              judulId: judul.id,
              judulName: judul.judul,
            ),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: judul.isPremium
                ? Colors.amber.withValues(alpha: 0.1)
                : kTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            judul.isPremium
                ? Icons.workspace_premium_rounded
                : Icons.article_outlined,
            color: judul.isPremium ? Colors.amber : kTeal,
            size: 20,
          ),
        ),
        title: Text(
          judul.judul,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            judul.namaKategori,
            style: TextStyle(
              fontSize: 12,
              color: kTeal.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        isThreeLine: false,
      ),
    );
  }
}
