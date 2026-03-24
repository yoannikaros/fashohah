import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/surat.dart';
import '../providers/quran_provider.dart';
import '../widgets/surat_card.dart';
import 'surat_detail_page.dart';

class SuratListPage extends ConsumerWidget {
  const SuratListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suratListAsync = ref.watch(suratListProvider);

    return Scaffold(
      body: suratListAsync.when(
        loading: () => const _SuratListSkeleton(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(suratListProvider),
        ),
        data: (surats) => _SuratList(surats: surats),
      ),
    );
  }
}

class _SuratList extends StatelessWidget {
  const _SuratList({required this.surats});

  final List<Surat> surats;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverToBoxAdapter(child: _ListHeader(total: surats.length)),

        // ── Search bar ──────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchBarDelegate(surats: surats),
        ),

        // ── List ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: surats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 1),
            itemBuilder: (context, index) {
              final surat = surats[index];
              return SuratCard(
                surat: surat,
                isFirst: index == 0,
                isLast: index == surats.length - 1,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SuratDetailPage(nomorSurat: surat.nomor),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Al-Qur\'an',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 34,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total Surat',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar Sticky ─────────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({required this.surats});

  final List<Surat> surats;

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => showSearch(
          context: context,
          delegate: _SuratSearchDelegate(surats),
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                'Cari surat...',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => false;
}

// ─── Skeleton Loading ──────────────────────────────────────────────────────

class _SuratListSkeleton extends StatelessWidget {
  const _SuratListSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHigh;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 36, width: 160,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(8),
                    )),
                const SizedBox(height: 8),
                Container(
                    height: 16, width: 80,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6),
                    )),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: 10,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 1),
              height: 72,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: i == 9 ? const Radius.circular(14) : Radius.zero,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Error View ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal memuat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Delegate ───────────────────────────────────────────────────────

class _SuratSearchDelegate extends SearchDelegate<Surat?> {
  _SuratSearchDelegate(this.surats);

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
