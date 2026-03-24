import 'package:flutter_riverpod/flutter_riverpod.dart';

// Per-dzikir counter: keyed by dzikir id
// State: current count
class DzikirCounter extends FamilyNotifier<int, String> {
  @override
  int build(String arg) => 0;

  void increment() => state++;

  void reset() => state = 0;
}

final dzikirCounterProvider =
    NotifierProvider.family<DzikirCounter, int, String>(
  DzikirCounter.new,
);
