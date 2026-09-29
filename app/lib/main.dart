import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/question_generator.dart';
import 'logic/quiz_controller.dart';
import 'screens/quiz_screen.dart';
import 'screens/results_screen.dart';
import 'screens/setup_screen.dart';
import 'services/settings_controller.dart';
import 'services/sound_service.dart';
import 'services/storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final settings = SettingsController()..load();
  // Kindergarten, times-tables and clock questions aren't ported yet: until
  // they are, the app runs the plain arithmetic quiz.
  settings.update((s) {
    s.mode = "test";
    s.ops.remove("time");
  });
  runApp(MyMathyApp(settings: settings));
}

class MyMathyApp extends StatelessWidget {
  final SettingsController settings;
  const MyMathyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          title: "MyMathy",
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const Scaffold(body: AppRoot()),
        ),
      );
}

/// Screens are swapped explicitly (setup / quiz / results), like the web
/// app's showScreen() — no navigation stack, only in-app buttons.
enum AppScreen { setup, quiz, results }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _screen = AppScreen.setup;
  QuizController? _quiz;
  late final SoundService _sound = SoundService(context.read<SettingsController>());

  @visibleForTesting
  QuizController? get quizForTest => _quiz;

  // Screenshot aid: `--dart-define=OPEN_QUIZ=true` jumps straight into a quiz.
  static const _openQuiz = bool.fromEnvironment("OPEN_QUIZ");

  @override
  void initState() {
    super.initState();
    if (_openQuiz) WidgetsBinding.instance.addPostFrameCallback((_) => _startQuiz());
  }

  void _startQuiz() {
    _quiz?.dispose();
    final settings = context.read<SettingsController>().settings;
    final quiz = QuizController(settings, buildRound(settings))
      ..onGood = _sound.good
      ..onBad = _sound.bad
      ..onTick = _sound.tick
      ..onPartial = _sound.partial;
    quiz.addListener(() {
      if (quiz.result != null && _screen == AppScreen.quiz && identical(quiz, _quiz)) {
        setState(() => _screen = AppScreen.results);
      }
    });
    setState(() {
      _quiz = quiz;
      _screen = AppScreen.quiz;
    });
    quiz.start();
  }

  void _toSetup() {
    _quiz?.dispose();
    setState(() {
      _quiz = null;
      _screen = AppScreen.setup;
    });
  }

  @override
  void dispose() {
    _quiz?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_screen) {
        AppScreen.setup => SetupScreen(onStart: _startQuiz),
        AppScreen.quiz => QuizScreen(quiz: _quiz!, onQuit: _toSetup),
        AppScreen.results => ResultsScreen(
            result: _quiz!.result!,
            lang: _quiz!.settings.lang,
            onAgain: _startQuiz,
            onSettings: _toSetup,
          ),
      };
}
