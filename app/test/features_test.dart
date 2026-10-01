import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_stars/logic/game_controller.dart';
import 'package:math_stars/logic/question_generator.dart';
import 'package:math_stars/logic/quiz_controller.dart';
import 'package:math_stars/main.dart';
import 'package:math_stars/models/question.dart';
import 'package:math_stars/models/settings.dart';
import 'package:math_stars/screens/game_screen.dart';
import 'package:math_stars/services/progress_store.dart';
import 'package:math_stars/services/settings_controller.dart';
import 'package:math_stars/services/storage.dart';
import 'package:math_stars/widgets/time_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  await Storage.clearForTest();
}

void main() {
  setUp(_freshStorage);

  group("clock questions in the quiz", () {
    final gen = QuestionGenerator(Random(5));

    test("typed time: 3:15 is typed as 315 and submits itself", () {
      fakeAsync((fa) {
        final q = gen.makeTimeQuestion(3, 15, 0, "12");
        final quiz = QuizController(Settings(), [q])..start();
        for (final d in ["3", "1", "5"]) {
          quiz.key(d);
        }
        expect(quiz.answerMood, Mood.good);
        expect(quiz.answerDisplay, "3:15");
        quiz.dispose();
      });
    });

    test("picked time: hour then minute submits; the numpad is ignored", () {
      fakeAsync((fa) {
        final q = gen.makeTimeQuestion(
          9,
          45,
          5,
          "12",
        ); // 5 hours after 9:45 → 2:45
        final quiz = QuizController(Settings(timeInput: "pick"), [q])..start();
        expect(quiz.usesPick, isTrue);
        expect(quiz.pickHours, List.generate(12, (i) => i + 1));
        quiz.key("2");
        expect(quiz.answerDisplay, "–:––");
        quiz.pickHour(2);
        expect(quiz.answerDisplay, "2:––");
        quiz.pickMinute(45);
        expect(quiz.answerMood, Mood.good);
        quiz.dispose();
      });
    });

    test("picked time with the OK button waits for ✓", () {
      fakeAsync((fa) {
        final q = gen.makeTimeQuestion(0, 30, 0, "24");
        final quiz = QuizController(
          Settings(timeInput: "pick", autoSubmit: false),
          [q],
        )..start();
        expect(quiz.pickHours.first, 0); // 24-hour picker includes midnight
        quiz.pickHour(0);
        quiz.pickMinute(30);
        expect(quiz.locked, isFalse);
        quiz.pickOk();
        expect(quiz.answerMood, Mood.good);
        quiz.dispose();
      });
    });

    test(
      "dual clock: first reading keeps the question open, second finishes it",
      () {
        fakeAsync((fa) {
          final q = gen.makeTimeQuestion(7, 15, 0, "dual");
          final quiz = QuizController(Settings(timeInput: "pick"), [q])
            ..start();
          quiz.pickHour(19);
          quiz.pickMinute(15);
          expect(quiz.locked, isFalse);
          expect(quiz.feedbackText, "✓ 19:15");
          expect(quiz.pickH, isNull);
          quiz.pickHour(7); // minute is kept
          expect(quiz.answerMood, Mood.good);
          quiz.dispose();
        });
      },
    );

    test(
      "a wrong clock answer is saved as a weak time and logged for parents",
      () {
        fakeAsync((fa) {
          final q = gen.makeTimeQuestion(4, 30, -2, "12");
          final quiz = QuizController(Settings(), [q])..start();
          for (final d in ["4", "3", "0"]) {
            quiz.key(d);
          }
          expect(quiz.answerMood, Mood.bad);
          expect(WeakMemory.load()["time:4:30:-2"], 1);
          expect(MistakeLog.load().single.prompt, "🕐 4:30 −2h");
          quiz.dispose();
        });
      },
    );
  });

  group("kindergarten and times tables", () {
    test("kindergarten shapes stay countable and can be untimed", () {
      final s = Settings(
        mode: "kg",
        kgRange: 20,
        kgStyle: "shapes",
        kgTimer: false,
        count: 20,
      );
      final qs = QuestionGenerator(Random(6)).buildQuestions(s, {});
      for (final q in qs) {
        expect(q.op, anyOf("add", "sub"));
        expect(q.kgStyle, "shapes");
        expect(q.emoji, isNotNull);
        expect(q.untimed, isTrue);
        if (q.op == "add") expect(q.answer, lessThanOrEqualTo(kKgShapesMax));
      }
    });

    test("untimed questions get the full speed bonus", () {
      fakeAsync((fa) {
        final q = Question(op: "add", a: 2, b: 3, answer: 5)..untimed = true;
        final quiz = QuizController(Settings(mode: "kg"), [q])..start();
        fa.elapse(const Duration(minutes: 2));
        quiz.key("5");
        expect(quiz.points, closeTo(1000, 0.01));
        quiz.dispose();
      });
    });
  });

  group("reward games", () {
    test("which game a quiz earns", () {
      expect(gameKindFor(Settings(ops: ["add"])), GameKind.num);
      expect(gameKindFor(Settings(ops: ["time"])), GameKind.clock);
      expect(gameKindFor(Settings(ops: ["time", "mul"])), GameKind.mixed);
      expect(gameKindFor(Settings(mode: "kg", ops: ["time"])), GameKind.num);
    });

    test(
      "Meteor Blaster: typing an answer blasts it; three landings end the game",
      () {
        fakeAsync((fa) {
          final game = GameController(
            Settings(ops: ["add"], range: 10),
            Random(7),
          );
          double land(Meteor m) => 400;
          game.tick(0.1, land); // 2.6 s left until the first spawn
          for (var i = 0; i < 30 && game.meteors.isEmpty; i++) {
            game.tick(0.1, land);
          }
          final m = game.meteors.single;
          for (final d in "${m.answer}".split("")) {
            game.key(d);
          }
          expect(game.score, 10);
          expect(m.live, isFalse);
          while (!game.over) {
            game.tick(0.1, land);
          }
          expect(game.lives, 0);
          expect(game.isNewRecord, isTrue);
          expect(HighScores.bestFor("meteor"), 10);
          game.dispose();
        });
      },
    );

    test(
      "Clock Blaster: picking the right time blasts the clock; a wrong one flashes",
      () {
        fakeAsync((fa) {
          final game = GameController(
            Settings(ops: ["time"], timeLevel: 1),
            Random(8),
          );
          double land(Meteor m) => 10000;
          while (game.meteors.isEmpty) {
            game.tick(0.1, land);
          }
          final m = game.meteors.single;
          expect(m.isClock, isTrue);
          expect([0, 15, 30, 45], contains(m.m));
          game.pickHour((m.h + 1) % 24);
          game.pickMinute(m.m);
          expect(game.wrongFlash, isTrue);
          fa.elapse(const Duration(milliseconds: 400));
          expect(game.wrongFlash, isFalse);
          game.pickHour(m.h);
          game.pickMinute(m.m);
          expect(game.score, 10);
          game.dispose();
        });
      },
    );
  });

  group("screens", () {
    Future<SettingsController> app(
      WidgetTester tester,
      Size size,
      void Function(Settings s) setup,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _freshStorage();
      final settings = SettingsController()..load();
      settings.update((s) {
        s.sound = false;
        setup(s);
      });
      await tester.pumpWidget(MyMathyApp(settings: settings));
      return settings;
    }

    Future<void> start(WidgetTester tester) async {
      final start = find.text("Start! 🚀");
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pump();
    }

    Future<void> tapChip(
      WidgetTester tester,
      PickKind kind,
      String label,
    ) async {
      final chip = find.descendant(
        of: find.byWidgetPredicate((w) => w is PickRow && w.kind == kind),
        matching: find.text(label),
      );
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
    }

    QuizController quizOf(WidgetTester tester) =>
        (tester.state(find.byType(AppRoot)) as dynamic).quizForTest
            as QuizController;

    for (final (name, size) in const [
      ("iPad", Size(820, 1180)),
      ("iPad landscape", Size(1180, 820)),
      ("iPhone SE", Size(375, 667)),
    ]) {
      testWidgets("clock quiz with the picker on $name", (tester) async {
        await app(tester, size, (s) {
          s.ops = ["time"];
          s.clockMode = "dual";
          s.timeInput = "pick";
          s.count = 5;
        });
        await start(tester);
        for (var i = 0; i < 5; i++) {
          final q = quizOf(tester).current;
          for (final h in [q.answer ~/ 100, q.answer2! ~/ 100]) {
            await tapChip(tester, PickKind.hour, "$h");
            await tapChip(
              tester,
              PickKind.minute,
              q.b.toString().padLeft(2, "0"),
            );
          }
          await tester.pump(const Duration(milliseconds: 1000));
        }
        expect(find.textContaining("✓ 5 / 5"), findsOneWidget);
      });

      testWidgets("typed 24-hour clock quiz on $name", (tester) async {
        await app(tester, size, (s) {
          s.ops = ["time"];
          s.clockMode = "24";
          s.clockTask = "both";
          s.count = 5;
        });
        await start(tester);
        for (var i = 0; i < 5; i++) {
          final q = quizOf(tester).current;
          final typed = "${q.ansH}${q.b.toString().padLeft(2, "0")}";
          for (final d in typed.split("")) {
            await tester.tap(find.text(d).last);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 1000));
        }
        expect(find.textContaining("✓ 5 / 5"), findsOneWidget);
      });

      testWidgets("kindergarten shapes, then the game on $name", (
        tester,
      ) async {
        await app(tester, size, (s) {
          s.mode = "kg";
          s.kgRange = 10;
          s.count = 5;
          s.gameScore = 500;
        });
        await start(tester);
        for (var i = 0; i < 5; i++) {
          final q = quizOf(tester).current;
          expect(find.text(q.emoji!), findsWidgets);
          for (final d in "${q.answer}".split("")) {
            await tester.tap(find.text(d).last);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 1000));
        }
        final play = find.text("🎮 Play Meteor Blaster!");
        await tester.ensureVisible(play);
        await tester.pumpAndSettle();
        await tester.tap(play);
        await tester.pump();
        expect(find.byType(GameScreen), findsOneWidget);
        // let three meteors land
        for (var i = 0; i < 2000 && find.text("OK").evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.textContaining("☄️ 0"), findsWidgets);
        await tester.tap(find.text("OK"));
        await tester.pump();
        // the ticket is spent
        expect(find.text("🎮 Play Meteor Blaster!"), findsNothing);
      });
    }

    testWidgets("times tables run every fact in order", (tester) async {
      await app(tester, const Size(820, 1180), (s) {
        s.mode = "tables";
        s.tables = [2];
        s.factorMax = 10;
      });
      await start(tester);
      expect(quizOf(tester).questions.length, 10);
      expect(find.text("2 × 1 = ?"), findsOneWidget);
      expect(find.text("1 / 10"), findsOneWidget);
    });

    testWidgets("the mistakes log opens only on a long press", (tester) async {
      await app(tester, const Size(820, 1180), (s) {});
      MistakeLog.add("3 + 4 = ?", "7", "8");
      final clip = find.text("📋");
      await tester.ensureVisible(clip);
      await tester.pumpAndSettle();
      await tester.tap(clip);
      await tester.pump();
      expect(find.text("Hold to open 👆"), findsOneWidget);
      expect(find.text("Mistakes Log 📋"), findsNothing);
      final g = await tester.startGesture(tester.getCenter(clip));
      await tester.pump(const Duration(milliseconds: 700));
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text("Mistakes Log 📋"), findsOneWidget);
      expect(find.text("Child answered: 8"), findsOneWidget);
      await tester.tap(find.text("Clear log"));
      await tester.pump();
      expect(find.text("No mistakes recorded yet 🎉"), findsOneWidget);
    });
  }, skip: false);
}
