import 'dart:math';

import '../models/question.dart';
import '../models/settings.dart';
import '../services/progress_store.dart';

const double kWeakBias = 0.4; // chance a question is drawn from saved weak ones
const int kKgShapesMax = 10; // shapes stay countable
const List<String> kEmojis = ["🍎", "⭐", "🎈", "🐟", "🦋", "🍓", "⚽", "🐥"];

/// What a round of questions is drawn from — mirrors the `cfg` objects in app.js.
class QuizConfig {
  final List<String> ops;
  final int range;
  final List<int> tables;
  final int factorMax;
  final int timeLevel;
  final String clockMode;
  final String clockTask;
  final String qFormat;
  List<Question> weakQs = const [];

  QuizConfig({
    required this.ops,
    required this.range,
    this.tables = const [],
    this.factorMax = kTableMax,
    this.timeLevel = 1,
    this.clockMode = "12",
    this.clockTask = "read",
    this.qFormat = "result",
  });
}

class QuestionGenerator {
  final Random rng;
  QuestionGenerator([Random? rng]) : rng = rng ?? Random();

  int rand(int lo, int hi) => lo + rng.nextInt(hi - lo + 1); // inclusive
  T pick<T>(List<T> list) => list[rng.nextInt(list.length)];
  bool coin() => rng.nextDouble() < 0.5;

  /// One question, avoiding the last 4 (recent is shared across a round).
  Question generate(QuizConfig cfg, List<String> recent) {
    late Question q;
    for (var attempt = 0; attempt < 50; attempt++) {
      // previously missed questions come back more often
      q = (cfg.weakQs.isNotEmpty && rng.nextDouble() < kWeakBias)
          ? pick(cfg.weakQs).copy()
          : makeOne(pick(cfg.ops), cfg);
      // mixed style: half the arithmetic questions hide the middle operand
      if (cfg.qFormat == "mixed" && !q.isTime && coin()) toBlank(q);
      final key = q.recentKey;
      if (!recent.contains(key) || attempt >= 40) {
        recent.add(key);
        if (recent.length > 4) recent.removeAt(0);
        return q;
      }
    }
    return q;
  }

  /// The face always shows h:m; shift (hours, negative = "before") moves the
  /// answer off the face. Mirrors makeTimeQuestion().
  Question makeTimeQuestion(int h, int m, int shift, String mode) {
    if (mode == "dual") {
      final ansH = (((h + shift) % 12) + 12) % 12;
      return Question(op: "time", a: h, b: m, answer: ansH * 100 + m)
        ..shift = shift
        ..ansH = ansH
        ..dual = true
        ..answer2 = (ansH + 12) * 100 + m;
    }
    var ansH = mode == "24"
        ? (((h + shift) % 24) + 24) % 24
        : (((h + shift) % 12) + 12) % 12;
    if (mode != "24" && ansH == 0) ansH = 12; // 12-hour faces read 12, never 0
    return Question(op: "time", a: h, b: m, answer: ansH * 100 + m)
      ..shift = shift
      ..ansH = ansH
      ..clock24 = mode == "24";
  }

  Question makeOne(String op, QuizConfig cfg) {
    if (op == "time") {
      final mode = cfg.clockMode;
      final m = cfg.timeLevel == 1 ? pick([0, 15, 30, 45]) : rand(0, 11) * 5;
      final task = cfg.clockTask;
      final shift = (task == "shift" || (task == "both" && coin()))
          ? rand(1, 11) * (coin() ? 1 : -1)
          : 0;
      // dual skips 12 so both answers stay distinct and < 24; 24h includes midnight
      final h = mode == "dual"
          ? rand(0, 11)
          : mode == "24"
          ? rand(0, 23)
          : rand(1, 12);
      return makeTimeQuestion(h, m, shift, mode);
    }
    if (op == "add") {
      final a = rand(1, max(1, cfg.range - 1));
      final b = rand(1, max(1, cfg.range - a));
      return Question(op: op, a: a, b: b, answer: a + b);
    }
    if (op == "sub") {
      final a = rand(2, cfg.range);
      final b = rand(1, a - 1);
      return Question(op: op, a: a, b: b, answer: a - b);
    }
    // × / ÷ come from a times-table fact: n (chosen table) × k (1..factorMax)
    final n = pick(cfg.tables);
    final k = rand(kTableMin, cfg.factorMax);
    return _fact(op, n, k);
  }

  Question _fact(String op, int n, int k) {
    if (op == "mul") {
      final swap = coin();
      final a = swap ? n : k, b = swap ? k : n;
      return Question(op: op, a: a, b: b, answer: a * b, fa: n, fb: k);
    }
    // ÷: product ÷ one factor = the other
    final swap = coin();
    final d = swap ? n : k, ans = swap ? k : n;
    return Question(op: op, a: n * k, b: d, answer: ans, fa: n, fb: k);
  }

  /// "a ∘ b = ?" → "a ∘ _ = result". For × the visible operand is always the
  /// chosen table number, so an unchosen number never appears on the left.
  static Question toBlank(Question q) {
    if (q.op == "mul") {
      q.a = q.fa!;
      q.b = q.fb!;
    }
    q.result = q.op == "mul" ? q.fa! * q.fb! : q.answer;
    q.answer = q.b;
    q.blank = true;
    return q;
  }

  /// A saved weak key turned back into a question — but only if it fits this
  /// quiz's settings. Mirrors weakToQuestion().
  Question? weakToQuestion(String key, QuizConfig cfg) {
    var m = RegExp(r"^f:(\d+)x(\d+)$").firstMatch(key);
    if (m != null) {
      final n = int.parse(m[1]!), k = int.parse(m[2]!);
      final ops = ["mul", "div"].where(cfg.ops.contains).toList();
      if (ops.isEmpty || !cfg.tables.contains(n) || k > cfg.factorMax) {
        return null;
      }
      return _fact(pick(ops), n, k);
    }
    m = RegExp(r"^(add|sub|time):(\d+):(\d+)(?::(-?\d+))?$").firstMatch(key);
    if (m == null || !cfg.ops.contains(m[1])) return null;
    final op = m[1]!, a = int.parse(m[2]!), b = int.parse(m[3]!);
    if (op == "add") {
      return a + b <= cfg.range
          ? Question(op: op, a: a, b: b, answer: a + b)
          : null;
    }
    if (op == "sub") {
      return a <= cfg.range && b < a
          ? Question(op: op, a: a, b: b, answer: a - b)
          : null;
    }
    if (cfg.timeLevel == 1 && b % 15 != 0) return null;
    final shift = m[4] != null ? int.parse(m[4]!) : 0;
    // only bring back the kind of clock question this quiz asks
    if (shift != 0 ? cfg.clockTask == "read" : cfg.clockTask == "shift") {
      return null;
    }
    if (cfg.clockMode == "dual") {
      final base = a > 12 ? a - 12 : a;
      if (base < 0 || base > 11) return null;
      return makeTimeQuestion(base, b, shift, "dual");
    }
    if (cfg.clockMode != "24" && (a < 1 || a > 12)) {
      return null; // 12-hour faces never show 0
    }
    return makeTimeQuestion(a, b, shift, cfg.clockMode);
  }

  /// Weighted pool: each saved question appears once per recorded miss.
  List<Question> weakQuestions(QuizConfig cfg, Map<String, int> weak) {
    final pool = <Question>[];
    weak.forEach((key, n) {
      final q = weakToQuestion(key, cfg);
      if (q == null) return;
      for (var i = 0; i < n; i++) {
        pool.add(q);
      }
    });
    return pool;
  }

  /// The round's questions for the current settings — mirrors buildQuestions().
  List<Question> buildQuestions(Settings s, Map<String, int> weak) {
    if (s.mode == "tables") {
      // every selected table in order, then that pool's weak facts once more
      final tables = [...s.tables]..sort();
      final qs = <Question>[
        for (final n in tables)
          for (var k = 1; k <= s.factorMax; k++)
            Question(op: "mul", a: n, b: k, answer: n * k, fa: n, fb: k),
      ];
      final seen = <String>{};
      weak.forEach((key, _) {
        final m = RegExp(r"^f:(\d+)x(\d+)$").firstMatch(key);
        if (m == null) return;
        final n = int.parse(m[1]!), k = int.parse(m[2]!);
        if (tables.contains(n) && k <= s.factorMax && seen.add(key)) {
          qs.add(Question(op: "mul", a: n, b: k, answer: n * k, fa: n, fb: k));
        }
      });
      return qs;
    }

    final recent = <String>[];
    if (s.mode == "kg") {
      final range = s.kgStyle == "shapes"
          ? min(s.kgRange, kKgShapesMax)
          : s.kgRange;
      final cfg = QuizConfig(ops: [...s.kgOps], range: range);
      return List.generate(s.count, (_) {
        final q = generate(cfg, recent)
          ..kg = true
          ..untimed = !s.kgTimer;
        if (s.kgStyle == "shapes") {
          q.kgStyle = "shapes";
          q.emoji = pick(kEmojis);
        }
        return q;
      });
    }

    final cfg = quizConfigFor(s);
    cfg.weakQs = weakQuestions(cfg, weak);
    return List.generate(s.count, (_) => generate(cfg, recent));
  }

  static QuizConfig quizConfigFor(Settings s) => QuizConfig(
    ops: [...s.ops],
    range: s.range,
    tables: [...s.tables]..sort(),
    factorMax: s.factorMax,
    timeLevel: s.timeLevel,
    clockMode: s.clockMode,
    clockTask: s.clockTask,
    qFormat: s.qFormat,
  );
}

/// Convenience used by the app: questions for [s] using the saved weak list.
List<Question> buildRound(Settings s, [Random? rng]) =>
    QuestionGenerator(rng).buildQuestions(s, WeakMemory.load());
