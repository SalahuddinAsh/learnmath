import '../models/question.dart';
import 'storage.dart';

/// Weak questions: anything answered wrong is saved with a miss count (max 5)
/// and drawn more often later; correct answers work the count back down.
/// Mirrors loadWeak/saveWeak/recordResult in app.js.
class WeakMemory {
  static const _key = "mathstars-weak";

  static Map<String, int> load() {
    final raw = Storage.getJson(_key) ?? {};
    final out = <String, int>{};
    raw.forEach((k, v) {
      if (v is! int) return;
      // migrate v1 fact keys ("3x7" -> "f:3x7")
      out[RegExp(r"^\d+x\d+$").hasMatch(k) ? "f:$k" : k] = v;
    });
    return out;
  }

  static void save(Map<String, int> w) => Storage.setJson(_key, w);

  static void record(Question q, bool correct) {
    final w = load();
    final key = q.weakKey;
    if (correct) {
      final n = w[key];
      if (n == null) return;
      if (n <= 1) {
        w.remove(key);
      } else {
        w[key] = n - 1;
      }
    } else {
      w[key] = ((w[key] ?? 0) + 1).clamp(1, 5);
    }
    save(w);
  }
}

/// Best score per mode (and per reward game) — mirrors loadBest/saveBest.
class HighScores {
  static const _key = "mathstars-best";

  static int bestFor(String mode) =>
      (Storage.getJson(_key)?[mode] as int?) ?? 0;

  /// Saves [score] if it beats the stored best; returns true for a new record.
  static bool recordIfBest(String mode, int score) {
    final best = Storage.getJson(_key) ?? {};
    if (score <= ((best[mode] as int?) ?? 0)) return false;
    best[mode] = score;
    Storage.setJson(_key, best);
    return true;
  }
}

class Mistake {
  final String prompt;
  final String correct;
  final String? given; // null = time ran out
  final int ts;
  const Mistake(this.prompt, this.correct, this.given, this.ts);
}

/// Parent-only log of every wrong or timed-out answer (last 200) — mirrors
/// loadMistakes/saveMistakes/recordMistake.
class MistakeLog {
  static const _key = "mathstars-mistakes";

  static List<Mistake> load() => (Storage.getJsonList(_key) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(
        (m) => Mistake(
          "${m["prompt"]}",
          "${m["correct"]}",
          m["given"] as String?,
          (m["ts"] as int?) ?? 0,
        ),
      )
      .toList();

  static void add(String prompt, String correct, String? given) {
    final list = Storage.getJsonList(_key) ?? [];
    list.add({
      "prompt": prompt,
      "correct": correct,
      "given": given,
      "ts": DateTime.now().millisecondsSinceEpoch,
    });
    Storage.setJson(
      _key,
      list.length > 200 ? list.sublist(list.length - 200) : list,
    );
  }

  static void clear() => Storage.setJson(_key, []);
}
