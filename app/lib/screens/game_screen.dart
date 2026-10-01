import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/strings.dart';
import '../logic/game_controller.dart';
import '../models/question.dart';
import '../theme.dart';
import '../widgets/clock_face.dart';
import '../widgets/common.dart';
import '../widgets/numpad.dart';
import '../widgets/time_picker.dart';

/// The reward game — mirrors #screen-game: lives + score, the sky with
/// falling equations/clocks, the typed entry and the numpad or picker.
class GameScreen extends StatefulWidget {
  final GameController game;
  final String lang;
  final VoidCallback onDone;
  const GameScreen({
    super.key,
    required this.game,
    required this.lang,
    required this.onDone,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _sky = const Size(300, 400);

  GameController get game => widget.game;

  double get _clockSize => (_sky.width * 0.27).clamp(112.0, 172.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      game.tick(dt, (m) => _sky.height - (m.isClock ? _clockSize : 52));
      if (game.over) _ticker.stop();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = kStrings[widget.lang]!;
    return Directionality(
      textDirection: widget.lang == "ar"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: ScreenBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, box) => ListenableBuilder(
                listenable: game,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    Expanded(child: _skyView(t)),
                    const SizedBox(height: 12),
                    _entryBox(),
                    const SizedBox(height: 12),
                    game.currentIsClock
                        ? _picker()
                        : Numpad(
                            onKey: game.key,
                            showOk: false,
                            keyHeight: (box.maxHeight * 0.07).clamp(46.0, 64.0),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        Pressable(
          onTap: widget.onDone,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "✕",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
        Expanded(
          child: Text(
            game.lives > 0 ? "❤️" * game.lives : "💔",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "${game.currentIsClock ? "⏰" : "☄️"} ${game.score}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _skyView(L10n t) => LayoutBuilder(
    builder: (context, box) {
      _sky = box.biggest;
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: game.currentIsClock
                  ? const [Color(0xFF0F1B3D), Color(0xFF2A3A7A)]
                  : const [Color(0xFF17123D), Color(0xFF3B2D7A)],
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final m in game.meteors) _meteor(m),
                if (game.over) _gameOver(t),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _meteor(Meteor m) {
    final size = m.isClock ? _clockSize : 0.0;
    final left = m.isClock ? (_sky.width - size) / 2 : m.xFrac * _sky.width;
    final Widget body;
    if (m.boomAge != null) {
      // @keyframes boom: grow to 1.6, then 2.2 while fading
      final p = (m.boomAge! / 0.4).clamp(0.0, 1.0);
      final scale = p < 0.6
          ? 1 + 0.6 * (p / 0.6)
          : 1.6 + 0.6 * ((p - 0.6) / 0.4);
      body = Opacity(
        opacity: p < 0.6 ? 1 : 1 - (p - 0.6) / 0.4,
        child: Transform.scale(
          scale: scale,
          child: const Text("💥", style: TextStyle(fontSize: 35)),
        ),
      );
    } else if (m.isClock) {
      body = Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0xE65EC8F8), blurRadius: 24),
            BoxShadow(color: Colors.white, blurRadius: 7),
          ],
        ),
        child: ClockFace(h: m.h, m: m.m, night: m.night, size: size - 14),
      );
    } else {
      final q = m.q!;
      body = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const ShapeDecoration(
          shape: OvalBorder(),
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF9C7A55), Color(0xFF7A5C40), Color(0xFF4A3626)],
            stops: [0, 0.45, 1],
          ),
          shadows: [
            BoxShadow(color: Color(0xCCFF9F43), blurRadius: 18),
            BoxShadow(color: Color(0xFFFFD54A), blurRadius: 4),
          ],
        ),
        child: Text(
          "${q.a} ${kOpSymbol[q.op]} ${q.b}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      );
    }
    return Positioned(left: max(4, left), top: m.y, child: body);
  }

  Widget _gameOver(L10n t) {
    final title = game.kind == GameKind.num
        ? t.s("gameOver")
        : t.s("gameOver").replaceAll("☄️", game.kindEmoji);
    return Positioned.fill(
      child: Container(
        color: const Color(0xE017123D),
        padding: const EdgeInsets.all(20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                textDirection: widget.lang == "ar"
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${game.kindEmoji} ${game.score}",
                style: const TextStyle(
                  color: Color(0xFFFFD54A),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                game.isNewRecord
                    ? t.s("newRecord")
                    : "${t.s("best")}: ${game.best}",
                textDirection: widget.lang == "ar"
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.faint,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 220,
                child: BigButton(label: "OK", onTap: widget.onDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryBox() => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 220, minHeight: 56),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.answerBg,
        border: Border.all(color: AppColors.answerBorder, width: 3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        game.entryDisplay.isEmpty ? " " : game.entryDisplay,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    ),
  );

  /// Clock Blaster's picker: hours 0–11 and 12–23 on two rows (the face's
  /// light/dark color says which row), then the minutes.
  Widget _picker() => Directionality(
    textDirection: TextDirection.ltr,
    child: Column(
      children: [
        for (final start in const [0, 12]) ...[
          PickRow(
            values: List.generate(12, (i) => start + i),
            kind: PickKind.hour,
            selected: game.pickH,
            wrong: game.wrongFlash,
            onTap: game.pickHour,
            center: true,
            minWidth: 42,
            minHeight: 40,
            fontSize: 17,
            spacing: 5,
          ),
          const SizedBox(height: 7),
        ],
        PickRow(
          values: game.clockMinutes,
          kind: PickKind.minute,
          selected: game.pickM,
          wrong: game.wrongFlash,
          onTap: game.pickMinute,
          center: true,
          minWidth: 50,
          minHeight: 46,
          fontSize: 18,
          spacing: 5,
        ),
      ],
    ),
  );
}
