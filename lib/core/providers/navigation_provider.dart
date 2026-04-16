import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global untuk mengontrol tab aktif di HomePage dari halaman mana saja.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
