import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../data/strings.dart';
import '../models/question.dart';
import '../models/settings.dart';
import '../services/progress_store.dart';

const double kOvertimeFactor = 0.3; // share of a question's points for an overtime answer

enum Mood { none, good, bad }

class QuizResult {
  final int score;
  final int total;
  final int correct;
  final int stars;
  final List<Question> missed;
  final bool isNewRecord;
  final int best;
  final bool canPlayGame;
  const QuizResult({
    required this.score,
    required this.total,
    required this.correct,
    required this.stars,
    required this.missed,
    required this.isNewRecord,
    required this.best,
    required this.canPlayGame,
  });
}

/// "7 × 8 = ?", "3 × _ = 12", "What time is it 5 hours later?" — mirrors questionText().
String questionText(Question q, String lang) {
  final t = kStrings[lang]!;
  if (q.isTime) {
    if (q.shift == 0) return t.s(q.dual ? "whatTime2" : "whatTime");
    final text = t.s(q.shift > 0 ? "shiftAfter" : "shiftBefore").replaceAll("{h}", hoursWord(lang, q.shift.abs()));
    return q.dual ? "$text ${t.s("bothAnswers")}" : text;
  }
  if (q.blank) return "${q.a} ${kOpSymbol[q.op]} _ = ${q.result}";
  return "${q.a} ${kOpSymbol[q.op]} ${q.b} = ?";
}

String answerText(Question q) {
  if (q.isTime) return q.dual ? "${fmtTime(q.answer)} / ${fmtTime(q.answer2!)}" : fmtTime(q.answer);
  return "${q.answer}";
}

/// What the parent log shows as the question — mirrors mistakePromptText().
String mistakePrompt(Question q, String lang) {
  if (!q.isTime) return questionText(q, lang);
  if (q.shift == 0) return "🕐";
  return "🕐 ${fmtTime(q.a * 100 + q.b)} ${q.shift > 0 ? "+" : "−"}${q.shift.abs()}h";
}

/// Typed digits as shown in the answer box ("315" → "3:15" for time).
String entryDisplay(String entry, Question q) =>
    q.isTime && entry.length >= 3 ? "${entry.substring(0, entry.length - 2)}:${entry.substring(entry.length - 2)}" : entry;

/// Typed time digits → h*100+m; "3" means 3:00.
int parseTimeEntry(String entry) => entry.length <= 2
    ? int.parse(entry) * 100
    : int.parse(entry.substring(0, entry.length - 2)) * 100 + int.parse(entry.substring(entry.length - 2));

/// Drives one round — mirrors the `quiz` object and startQuiz/nextQuestion/
/// onKey/submit/onTimeout/advance/finishQuiz in app.js. The screens only
/// render this state and forward taps.
class QuizController extends ChangeNotifier {
  final Settings settings;
  final List<Question> questions;
  final Random _rng;

  int index = 0;
  int correct = 0;
  double points = 0;
  final List<Question> missed = [];
  QuizResult? result;

  String entry = "";
  bool locked = false;
  bool overtime = false;
  Mood answerMood = Mood.none;
  String answerOverride = ""; // shown instead of the entry after a timeout
  Mood feedbackMood = Mood.none;
  String feedbackText = "";
  Set<int>? dualLeft;

  // timer
  bool timed = true;
  double timerFraction = 1;
  int secondsLeft = 0;
  Timer? _timer;
  Timer? _advanceTimer;
  final Stopwatch _clock = clock.stopwatch(); // fake-able in tests
  double _totalMs = 1;
  bool _disposed = false;

  VoidCallback? onGood, onBad, onTick, onPartial;

  QuizController(Settings settings, this.questions, [Random? rng])
      : settings = settings.copy(),
        _rng = rng ?? Random();

  L10n get t => kStrings[settings.lang]!;
  Question get current => questions[min(index, questions.length - 1)];
  int get scoreRounded => points.round();

  String get answerDisplay {
    if (answerOverride.isNotEmpty) return answerOverride;
    return entryDisplay(entry, current);
  }

  void start() => _begin();

  void _begin() {
    entry = "";
    locked = false;
    overtime = false;
    answerMood = Mood.none;
    answerOverride = "";
    feedbackMood = Mood.none;
    feedbackText = "";
    final q = current;
    dualLeft = q.dual ? {q.answer, q.answer2!} : null;
    timed = !q.untimed;
    if (timed) {
      // two readings take longer than one, and so does counting hours off the face
      final secs = (settings.secondsPerQuestion * (q.dual ? 1.5 : 1) * (q.shift != 0 ? 1.5 : 1)).round();
      _startTimer(secs);
    } else {
      // no time pressure: every correct answer gets the full speed bonus
      _stopTimer();
      _totalMs = double.infinity;
      _clock
        ..reset()
        ..start();
    }
    _notify();
  }

  void _startTimer(int seconds) {
    _stopTimer();
    _totalMs = seconds * 1000.0;
    secondsLeft = seconds;
    timerFraction = 1;
    _clock
      ..reset()
      ..start();
    var lastTick = -1;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final left = _totalMs - _clock.elapsedMilliseconds;
      timerFraction = (left / _totalMs).clamp(0.0, 1.0);
      secondsLeft = max(0, (left / 1000).ceil());
      if (secondsLeft <= 5 && secondsLeft >= 1 && secondsLeft != lastTick) {
        lastTick = secondsLeft;
        onTick?.call();
      }
      if (left <= 0) {
        _stopTimer();
        // easy keeps accepting answers after the buzzer, for fewer points
        if (settings.difficulty == "easy") {
          _enterOvertime();
        } else {
          _onTimeout();
        }
      }
      _notify();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _enterOvertime() {
    overtime = true;
    timerFraction = 0;
    secondsLeft = 0;
    feedbackMood = Mood.none;
    feedbackText = t.s("overtime");
  }

  /// Numpad input: a digit, "back" or "ok".
  void key(String k) {
    if (locked) return;
    final q = current;
    if (k == "back") {
      if (entry.isNotEmpty) entry = entry.substring(0, entry.length - 1);
    } else if (k == "ok") {
      if (entry.isNotEmpty) _submit();
      return;
    } else if (entry.length < 4) {
      entry += k;
      // instant mode: submit once the expected number of digits is typed
      // (dual clock: either reading may come first, so match against both)
      final full = q.dual
          ? (dualLeft?.contains(parseTimeEntry(entry)) ?? false) || entry.length >= 4
          : entry.length >= q.expectedEntryLength;
      if (settings.autoSubmit && full) {
        _submit();
        return;
      }
    }
    _notify();
  }

  void _submit() {
    final q = current;
    final given = q.isTime ? parseTimeEntry(entry) : int.parse(entry);
    // dual clock: the first correct reading keeps the question open for the second
    if (q.dual && dualLeft!.length == 2 && dualLeft!.contains(given)) {
      dualLeft!.remove(given);
      entry = "";
      feedbackMood = Mood.good;
      feedbackText = "✓ ${fmtTime(given)}";
      onPartial?.call();
      _notify();
      return;
    }
    final frac = max(0.0, 1 - _clock.elapsedMilliseconds / _totalMs);
    _stopTimer();
    locked = true;
    final good = q.dual ? dualLeft!.contains(given) : given == q.answer;
    WeakMemory.record(q, good);
    if (good) {
      // faster answers earn more: full value instantly, half at the buzzer,
      // and a small share for overtime answers on easy
      final maxPts = 1000 / questions.length;
      final pts = overtime ? maxPts * kOvertimeFactor : maxPts * (0.5 + 0.5 * frac);
      correct++;
      points += pts;
      answerMood = Mood.good;
      feedbackMood = Mood.good;
      final cheers = t.list("good");
      feedbackText = "${cheers[_rng.nextInt(cheers.length)]} +${pts.round()}";
      onGood?.call();
      _after(900);
    } else {
      missed.add(q);
      MistakeLog.add(mistakePrompt(q, settings.lang), answerText(q), q.isTime ? fmtTime(given) : "$given");
      answerMood = Mood.bad;
      feedbackMood = Mood.bad;
      feedbackText = "${t.s("answerIs")}: ${answerText(q)}";
      onBad?.call();
      _after(2000);
    }
    _notify();
  }

  void _onTimeout() {
    final q = current;
    locked = true;
    missed.add(q);
    WeakMemory.record(q, false);
    MistakeLog.add(mistakePrompt(q, settings.lang), answerText(q), null);
    answerOverride = answerText(q);
    answerMood = Mood.bad;
    feedbackMood = Mood.bad;
    feedbackText = "${t.s("timeUp")} ${t.s("answerIs")}: ${answerText(q)}";
    onBad?.call();
    _after(2200);
  }

  void _after(int ms) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(Duration(milliseconds: ms), _advance);
  }

  void _advance() {
    if (_disposed) return;
    index++;
    if (index >= questions.length) {
      _finish();
    } else {
      _begin();
    }
  }

  void _finish() {
    _stopTimer();
    final score = points.round();
    final stars = score >= 900 ? 3 : score >= 700 ? 2 : score >= 450 ? 1 : 0;
    final isNewRecord = HighScores.recordIfBest(settings.mode, score);
    result = QuizResult(
      score: score,
      total: questions.length,
      correct: correct,
      stars: stars,
      missed: List.unmodifiable(missed),
      isNewRecord: isNewRecord,
      best: HighScores.bestFor(settings.mode),
      canPlayGame: settings.gameScore > 0 && score >= settings.gameScore,
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    _advanceTimer?.cancel();
    super.dispose();
  }
}
