import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_stars/logic/question_generator.dart';
import 'package:math_stars/logic/quiz_controller.dart';
import 'package:math_stars/models/question.dart';
import 'package:math_stars/models/settings.dart';
import 'package:math_stars/services/progress_store.dart';
import 'package:math_stars/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    WeakMemory.save({});
    MistakeLog.clear();
  });

  group("question generator", () {
    final gen = QuestionGenerator(Random(1));

    test("add answers never exceed the range; sub never goes negative", () {
      for (final range in kRangeOptions) {
        final cfg = QuizConfig(ops: ["add", "sub"], range: range);
        for (var i = 0; i < 2000; i++) {
          final q = gen.makeOne(i.isEven ? "add" : "sub", cfg);
          if (q.op == "add") {
            expect(q.answer, q.a + q.b);
            expect(q.answer, lessThanOrEqualTo(range));
            expect(q.a, greaterThanOrEqualTo(1));
            expect(q.b, greaterThanOrEqualTo(1));
          } else {
            expect(q.answer, q.a - q.b);
            expect(q.answer, greaterThanOrEqualTo(1));
            expect(q.a, lessThanOrEqualTo(range));
          }
        }
      }
    });

    test("× and ÷ come only from the chosen tables", () {
      final cfg = QuizConfig(ops: ["mul", "div"], range: 20, tables: [3, 7], factorMax: 12);
      for (var i = 0; i < 2000; i++) {
        final q = gen.makeOne(i.isEven ? "mul" : "div", cfg);
        expect([3, 7], contains(q.fa));
        expect(q.fb, inInclusiveRange(1, 12));
        if (q.op == "mul") {
          expect(q.answer, q.a * q.b);
        } else {
          expect(q.a, q.b * q.answer);
        }
      }
    });

    test("blank questions: the answer is the hidden operand, × shows the table number", () {
      final cfg = QuizConfig(ops: ["add", "sub", "mul", "div"], range: 50, tables: [4], qFormat: "mixed");
      var blanks = 0;
      final recent = <String>[];
      for (var i = 0; i < 2000; i++) {
        final q = gen.generate(cfg, recent);
        if (!q.blank) continue;
        blanks++;
        expect(q.answer, q.b);
        final r = switch (q.op) { "add" => q.a + q.b, "sub" => q.a - q.b, "mul" => q.a * q.b, _ => q.a ~/ q.b };
        expect(q.result, r);
        if (q.op == "mul") expect(q.a, 4);
      }
      expect(blanks, greaterThan(500));
    });

    test("no repeat of the previous question when there's room to avoid it", () {
      final cfg = QuizConfig(ops: ["add"], range: 20);
      final recent = <String>[];
      String? prev;
      for (var i = 0; i < 500; i++) {
        final k = gen.generate(cfg, recent).recentKey;
        expect(k, isNot(prev));
        prev = k;
      }
    });

    test("time answers match makeTimeQuestion in app.js", () {
      expect(gen.makeTimeQuestion(9, 15, 5, "12").answer, 215);
      expect(gen.makeTimeQuestion(9, 15, 3, "12").answer, 1215); // 12, never 0
      expect(gen.makeTimeQuestion(21, 15, 5, "24").answer, 215);
      expect(gen.makeTimeQuestion(2, 0, -3, "24").answer, 2300);
      final d = gen.makeTimeQuestion(7, 15, 0, "dual");
      expect([d.answer, d.answer2], [715, 1915]);
      expect(gen.makeTimeQuestion(0, 30, 0, "24").expectedEntryLength, 3); // "030"
    });

    test("weak keys come back only when they fit the settings", () {
      final cfg = QuizConfig(ops: ["add", "mul"], range: 20, tables: [3], factorMax: 10);
      expect(gen.weakToQuestion("add:5:7", cfg)?.answer, 12);
      expect(gen.weakToQuestion("add:15:7", cfg), isNull); // over the range
      expect(gen.weakToQuestion("sub:9:4", cfg), isNull); // sub not selected
      expect(gen.weakToQuestion("f:3x7", cfg)?.answer, 21);
      expect(gen.weakToQuestion("f:4x7", cfg), isNull); // table not chosen
      expect(gen.weakToQuestion("f:3x11", cfg), isNull); // beyond ×10
    });

    test("tables mode: all facts in order, then weak ones again", () {
      WeakMemory.save({"f:2x7": 2, "f:9x1": 1});
      final s = Settings(mode: "tables", tables: [3, 2], factorMax: 10);
      final qs = QuestionGenerator(Random(2)).buildQuestions(s, WeakMemory.load());
      expect(qs.length, 21);
      expect(qs.first.solvedText, "2 × 1 = 2");
      expect(qs[19].solvedText, "3 × 10 = 30");
      expect(qs.last.solvedText, "2 × 7 = 14");
    });
  });

  group("weak memory", () {
    test("misses count up to 5, correct answers count down and clear", () {
      final q = Question(op: "add", a: 5, b: 7, answer: 12);
      for (var i = 0; i < 7; i++) {
        WeakMemory.record(q, false);
      }
      expect(WeakMemory.load()["add:5:7"], 5);
      WeakMemory.record(q, true);
      expect(WeakMemory.load()["add:5:7"], 4);
      for (var i = 0; i < 4; i++) {
        WeakMemory.record(q, true);
      }
      expect(WeakMemory.load().containsKey("add:5:7"), isFalse);
    });
  });

  group("quiz controller", () {
    List<Question> sums(int n) => List.generate(n, (i) => Question(op: "add", a: i + 1, b: 10, answer: i + 11));

    test("instant answers score about 1000; wrong ones are logged and missed", () {
      fakeAsync((fa) {
        final quiz = QuizController(Settings(count: 5), sums(5), Random(3))..start();
        for (var i = 0; i < 5; i++) {
          final q = quiz.current;
          final typed = i == 2 ? "99" : "${q.answer}";
          for (final ch in typed.split("")) {
            quiz.key(ch);
          }
          fa.elapse(Duration(milliseconds: i == 2 ? 2000 : 900)); // just the feedback pause
        }
        expect(quiz.result, isNotNull);
        expect(quiz.result!.correct, 4);
        expect(quiz.result!.missed.single.answer, 13);
        expect(quiz.result!.score, closeTo(800, 5));
        expect(MistakeLog.load().single.given, "99");
        expect(WeakMemory.load()["add:3:10"], 1);
        quiz.dispose();
      });
    });

    test("with the OK button, nothing is submitted until ✓", () {
      fakeAsync((fa) {
        final quiz = QuizController(Settings(autoSubmit: false), sums(1))..start();
        quiz.key("1");
        quiz.key("1");
        quiz.key("5");
        quiz.key("back");
        expect(quiz.locked, isFalse);
        expect(quiz.answerDisplay, "11");
        quiz.key("ok");
        expect(quiz.answerMood, Mood.good);
        quiz.dispose();
      });
    });

    test("medium: time runs out → shown as wrong with the answer", () {
      fakeAsync((fa) {
        final quiz = QuizController(Settings(difficulty: "medium"), sums(2))..start();
        fa.elapse(const Duration(seconds: 21));
        expect(quiz.answerMood, Mood.bad);
        expect(quiz.answerDisplay, "11");
        expect(MistakeLog.load().single.given, isNull);
        quiz.dispose();
      });
    });

    test("easy: after the buzzer answers still count, for 30% of the points", () {
      fakeAsync((fa) {
        final quiz = QuizController(Settings(difficulty: "easy"), sums(1))..start();
        fa.elapse(const Duration(seconds: 31));
        expect(quiz.overtime, isTrue);
        expect(quiz.locked, isFalse);
        quiz.key("1");
        quiz.key("1");
        expect(quiz.answerMood, Mood.good);
        expect(quiz.points, closeTo(300, 0.01));
        quiz.dispose();
      });
    });
  });
}
