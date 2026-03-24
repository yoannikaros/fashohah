import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer/presentation/providers/prayer_provider.dart';

// Bookmarks stored as Set<String> of dzikir ids
class BookmarkNotifier extends Notifier<Set<String>> {
  static const _key = 'dzikir_bookmarks';

  @override
  Set<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
    await prefs.setStringList(_key, state.toList());
  }

  bool isBookmarked(String id) => state.contains(id);
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, Set<String>>(
  BookmarkNotifier.new,
);
