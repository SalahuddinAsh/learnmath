import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_stars/logic/quiz_controller.dart';
import 'package:math_stars/main.dart';
import 'package:math_stars/services/settings_controller.dart';
import 'package:math_stars/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays a whole round through the real screens at iPad and small-iPhone
/// sizes; any layout overflow fails the test.
void main() {
  for (final (name, size) in const [
    ("iPad", Size(820, 1180)),
    ("iPhone SE", Size(375, 667)),
  ]) {
    for (final lang in const ["en", "ar"]) {
      testWidgets("setup → quiz → results on $name ($lang)", (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        await Storage.clearForTest();
        final settings = SettingsController()..load();
        settings.update((s) {
          s.lang = lang;
          s.count = 5;
          s.ops = ["add", "mul"];
          s.sound = false;
        });

        await tester.pumpWidget(MyMathyApp(settings: settings));
        final start = find.text(lang == "ar" ? "!ابدأ 🚀" : "Start! 🚀");
        await tester.ensureVisible(start);
        await tester.pumpAndSettle();
        await tester.tap(start);
        await tester.pump();

        for (var i = 0; i < 5; i++) {
          final quiz =
              (tester.state(find.byType(AppRoot)) as dynamic).quizForTest
                  as QuizController;
          final right = "${quiz.current.answer}";
          final answer = i == 1
              ? "0" * right.length
              : right; // one wrong answer
          for (final d in answer.split("")) {
            await tester.tap(find.text(d).last);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 2100));
        }
        await tester.pump();
        expect(
          find.textContaining("/ 1000", findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining("✓ 4 / 5"), findsOneWidget);
      });
    }
  }
}
