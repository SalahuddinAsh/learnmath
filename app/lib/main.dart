import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/game_controller.dart';
import 'models/settings.dart';
import 'logic/question_generator.dart';
import 'logic/quiz_controller.dart';
import 'screens/game_screen.dart';
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
  // Screenshot aid: `--dart-define=DEMO_SETTINGS='{"mode":"kg",...}'` overrides
  // the saved settings (fields not given keep their defaults).
  const demo = String.fromEnvironment("DEMO_SETTINGS");
  if (demo.isNotEmpty) {
    settings.replace(
      Settings.fromJson(jsonDecode(demo) as Map<String, dynamic>),
    );
  }
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

/// Screens are swapped explicitly (setup / quiz / results / game), like the
/// web app's showScreen() — no navigation stack, only in-app buttons.
enum AppScreen { setup, quiz, results, game }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _screen = AppScreen.setup;
  QuizController? _quiz;
  GameController? _game;
  bool _ticketSpent = false; // a qualifying quiz earns exactly one game
  late final SoundService _sound = SoundService(
    context.read<SettingsController>(),
  );

  @visibleForTesting
  QuizController? get quizForTest => _quiz;

  // Screenshot aid: `--dart-define=OPEN_QUIZ=true` jumps straight into a quiz.
  static const _openQuiz = bool.fromEnvironment("OPEN_QUIZ");
  // `--dart-define=OPEN_GAME=true` jumps straight into the reward game.
  static const _openGame = bool.fromEnvironment("OPEN_GAME");

  @override
  void initState() {
    super.initState();
    if (_openQuiz) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startQuiz());
    }
    if (_openGame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final game = GameController(context.read<SettingsController>().settings)
          ..onZap = _sound.zap
          ..onBad = _sound.bad;
        setState(() {
          _game = game;
          _screen = AppScreen.game;
        });
      });
    }
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
      if (quiz.result != null &&
          _screen == AppScreen.quiz &&
          identical(quiz, _quiz)) {
        setState(() => _screen = AppScreen.results);
      }
    });
    setState(() {
      _quiz = quiz;
      _ticketSpent = false;
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

  void _playGame() {
    final game = GameController(_quiz!.settings)
      ..onZap = _sound.zap
      ..onBad = _sound.bad;
    setState(() {
      _game = game;
      _ticketSpent = true;
      _screen = AppScreen.game;
    });
  }

  // quitting mid-game and "OK" on game over both go back to the results
  void _leaveGame() {
    _game?.dispose();
    setState(() {
      _game = null;
      _screen = _quiz?.result != null ? AppScreen.results : AppScreen.setup;
    });
  }

  String? get _gameLabelKey {
    final quiz = _quiz!;
    if (_ticketSpent || !quiz.result!.canPlayGame) return null;
    return switch (gameKindFor(quiz.settings)) {
      GameKind.mixed => "gamePlayMixed",
      GameKind.clock => "gamePlayClock",
      GameKind.num => "gamePlay",
    };
  }

  @override
  void dispose() {
    _quiz?.dispose();
    _game?.dispose();
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
      gameLabelKey: _gameLabelKey,
      onPlayGame: _playGame,
    ),
    AppScreen.game => GameScreen(
      game: _game!,
      lang: context.read<SettingsController>().settings.lang,
      onDone: _leaveGame,
    ),
  };
}
