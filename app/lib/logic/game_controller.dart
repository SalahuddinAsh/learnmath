import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/question.dart';
import '../models/settings.dart';
import '../services/progress_store.dart';
import 'question_generator.dart';

/// Which reward game a finished quiz earns: a quiz that mixed Time with
/// other operations earns the mixed game — mirrors gameKindForCurrentSettings().
enum GameKind { num, clock, mixed }

GameKind gameKindFor(Settings s) {
  if (s.mode != "test") return GameKind.num;
  final hasTime = s.ops.contains("time");
  final hasOther = s.ops.any((o) => o != "time");
  if (hasTime && hasOther) return GameKind.mixed;
  return hasTime ? GameKind.clock : GameKind.num;
}

/// Something falling from the sky: an equation (meteor) or a clock face.
class Meteor {
  final Question? q; // equations
  final int answer;
  final bool isClock;
  final int h, m; // clocks
  final double xFrac; // equations: left edge as a share of the sky width
  double y;
  double? boomAge; // seconds since it exploded; null while live

  Meteor.num(Question this.q, this.xFrac, this.y)
    : answer = q.answer,
      isClock = false,
      h = 0,
      m = 0;

  Meteor.clock(this.h, this.m, this.y)
    : q = null,
      answer = h * 100 + m,
      isClock = true,
      xFrac = 0;

  bool get live => boomAge == null;
  bool get night => h >= 12;
}

/// Meteor Blaster / Clock Blaster / the Mix — a port of the game section of
/// app.js. Pure state: the screen calls [tick] every frame with the sky size.
class GameController extends ChangeNotifier {
  final GameKind kind;
  final QuestionGenerator _gen;
  final QuizConfig? _cfg;
  final List<String> _recent = [];
  final List<int>
  clockMinutes; // fixed for the whole game, like the quiz's clock level
  final List<({int h, int m})> _weakTimes;

  final List<Meteor> meteors = [];
  int score = 0;
  int lives = 3;
  String entry = "";
  int? pickH, pickM;
  bool wrongFlash = false;
  bool currentIsClock;
  bool over = false;
  bool isNewRecord = false;
  int best = 0;

  // the single-object games (clock, mixed) start slower: reading a face takes longer
  double speed; // px per second
  double spawnEvery; // ms
  double sinceSpawn; // ms
  final int maxItems;

  VoidCallback? onZap, onBad;
  Timer? _flashTimer;
  bool _disposed = false;

  GameController(Settings s, [Random? rng])
    : kind = gameKindFor(s),
      _gen = QuestionGenerator(rng),
      _cfg = gameKindFor(s) != GameKind.clock ? _gameCfg(s, rng) : null,
      clockMinutes = s.timeLevel == 1
          ? const [0, 15, 30, 45]
          : List.generate(12, (i) => i * 5),
      _weakTimes = gameKindFor(s) != GameKind.num
          ? _loadWeakTimes(
              s.timeLevel == 1
                  ? const [0, 15, 30, 45]
                  : List.generate(12, (i) => i * 5),
            )
          : const [],
      currentIsClock = gameKindFor(s) == GameKind.clock,
      speed = gameKindFor(s) != GameKind.num ? 10 : 26,
      spawnEvery = gameKindFor(s) != GameKind.num ? 2600 : 3000,
      sinceSpawn = gameKindFor(s) != GameKind.num ? 1000 : 2500,
      maxItems = gameKindFor(s) != GameKind.num ? 1 : 4;

  static QuizConfig _gameCfg(Settings s, Random? rng) {
    var ops = (s.mode == "kg" ? s.kgOps : s.ops)
        .where((o) => o != "time")
        .toList();
    if (s.mode == "tables") ops = ["mul"];
    if (ops.isEmpty) ops = ["add"];
    final cfg = QuizConfig(
      ops: ops,
      range: s.mode == "kg" ? s.kgRange : s.range,
      tables: s.tables.isNotEmpty ? [...s.tables] : [2, 3, 4, 5],
      factorMax: s.factorMax,
    );
    cfg.weakQs = QuestionGenerator(
      rng,
    ).weakQuestions(cfg, WeakMemory.load()); // the game drills tricky facts too
    return cfg;
  }

  // misread clock times come back more often — only those in this game's minute set
  static List<({int h, int m})> _loadWeakTimes(List<int> minutes) {
    final out = <({int h, int m})>[];
    WeakMemory.load().forEach((key, n) {
      final m = RegExp(r"^time:(\d+):(\d+)$").firstMatch(key);
      if (m == null || !minutes.contains(int.parse(m[2]!))) return;
      for (var i = 0; i < n; i++) {
        out.add((h: int.parse(m[1]!), m: int.parse(m[2]!)));
      }
    });
    return out;
  }

  String get bestKey => switch (kind) {
    GameKind.clock => "clockBlaster",
    GameKind.mixed => "mixedBlaster",
    GameKind.num => "meteor",
  };
  String get kindEmoji => switch (kind) {
    GameKind.clock => "⏰",
    GameKind.mixed => "🎮⏰",
    GameKind.num => "☄️",
  };

  Iterable<Meteor> get _live => meteors.where((m) => m.live);

  /// Advance the game by [dt] seconds. [landAt] gives the y at which a given
  /// meteor touches the ground (sky height minus its own height).
  void tick(double dt, double Function(Meteor m) landAt) {
    if (over) return;
    dt = min(dt, 0.1);
    sinceSpawn += dt * 1000;
    if (sinceSpawn >= spawnEvery && _live.length < maxItems) {
      _spawn();
      sinceSpawn = 0;
    }
    for (final m in _live.toList()) {
      m.y += speed * dt;
      if (m.y > landAt(m)) {
        _landed(m);
        if (over) break;
      }
    }
    for (final m in meteors) {
      if (m.boomAge != null) m.boomAge = m.boomAge! + dt;
    }
    meteors.removeWhere((m) => (m.boomAge ?? 0) > 0.4);
    _notify();
  }

  void _spawn() {
    switch (kind) {
      case GameKind.num:
        _spawnNum();
      case GameKind.clock:
        _spawnClock();
      case GameKind.mixed:
        _gen.coin() ? _spawnClock() : _spawnNum();
    }
  }

  void _spawnNum() {
    final q = _gen.generate(_cfg!, _recent);
    meteors.add(Meteor.num(q, 0.05 + _gen.rng.nextDouble() * 0.62, -50));
    if (kind == GameKind.mixed) _switchInput(false);
  }

  void _spawnClock() {
    ({int h, int m}) t = (h: 0, m: 0);
    for (var attempt = 0; attempt < 8; attempt++) {
      t = (_weakTimes.isNotEmpty && _gen.rng.nextDouble() < kWeakBias)
          ? _gen.pick(_weakTimes)
          : (h: _gen.rand(0, 23), m: _gen.pick(clockMinutes));
      if (!_live.any((x) => x.answer == t.h * 100 + t.m)) break;
    }
    meteors.add(Meteor.clock(t.h, t.m, -160));
    if (kind == GameKind.mixed) _switchInput(true);
  }

  void _switchInput(bool isClock) {
    currentIsClock = isClock;
    entry = "";
    pickH = null;
    pickM = null;
    wrongFlash = false;
  }

  void _landed(Meteor m) {
    m.boomAge = 0;
    lives--;
    onBad?.call();
    if (lives <= 0) {
      _end();
      return;
    }
    // fresh sky after losing a life: clear everything, keep the pace,
    // and leave a short breather before objects fall again
    meteors.removeWhere((x) => x.live);
    entry = "";
    pickH = null;
    pickM = null;
    sinceSpawn = -1500;
  }

  void _blast(Meteor m) {
    m.boomAge = 0;
    score += 10;
    speed += 1.5; // every blast makes the sky a little angrier
    if (kind == GameKind.num) {
      spawnEvery = max(1300, spawnEvery - 55);
    } else {
      // single-object pacing: the pause counts from when this one was answered
      sinceSpawn = 0;
      spawnEvery = max(1800, spawnEvery - 55);
    }
    onZap?.call();
  }

  /// The lowest matching object is the most urgent one.
  Meteor? _lowest(bool Function(Meteor m) test) {
    final hits = _live.where(test).toList()..sort((a, b) => b.y.compareTo(a.y));
    return hits.isEmpty ? null : hits.first;
  }

  /// Numpad input for falling equations.
  void key(String k) {
    if (over || currentIsClock) return;
    if (k == "back") {
      if (entry.isNotEmpty) entry = entry.substring(0, entry.length - 1);
    } else if (entry.length < 4) {
      entry += k;
    }
    final val = int.tryParse(entry);
    final hit = val == null
        ? null
        : _lowest((m) => !m.isClock && m.answer == val);
    if (hit != null) {
      _blast(hit);
      entry = "";
    } else {
      final lengths = _live
          .where((m) => !m.isClock)
          .map((m) => "${m.answer}".length);
      if (lengths.isNotEmpty && entry.length >= lengths.reduce(max)) {
        entry = ""; // full-length miss
      }
    }
    _notify();
  }

  void pickHour(int h) {
    if (over || wrongFlash) return;
    pickH = h;
    _pickTry();
  }

  void pickMinute(int m) {
    if (over || wrongFlash) return;
    pickM = m;
    _pickTry();
  }

  void _pickTry() {
    if (pickH == null || pickM == null) {
      _notify();
      return;
    }
    final hit = _lowest((m) => m.isClock && m.answer == pickH! * 100 + pickM!);
    if (hit != null) {
      _blast(hit);
      pickH = null;
      pickM = null;
    } else {
      // no falling clock shows that time: flash red, then let them try again
      wrongFlash = true;
      onBad?.call();
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 380), () {
        wrongFlash = false;
        pickH = null;
        pickM = null;
        _notify();
      });
    }
    _notify();
  }

  String get entryDisplay {
    if (!currentIsClock) return entry;
    if (pickH == null && pickM == null) return "";
    return "${pickH ?? "–"}:${pickM == null ? "––" : pickM.toString().padLeft(2, "0")}";
  }

  void _end() {
    over = true;
    isNewRecord = HighScores.recordIfBest(bestKey, score);
    best = HighScores.bestFor(bestKey);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _flashTimer?.cancel();
    super.dispose();
  }
}
