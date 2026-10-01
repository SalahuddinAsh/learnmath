import 'dart:math';

import 'package:flutter/material.dart';

import '../data/strings.dart';
import '../logic/quiz_controller.dart';
import '../models/question.dart';
import '../theme.dart';
import '../widgets/clock_face.dart';
import '../widgets/common.dart';
import '../widgets/numpad.dart';
import '../widgets/time_picker.dart';

/// One question at a time: progress + score, timer bar, the question card
/// and the numpad (or hour/minute picker) — mirrors #screen-quiz. Clock
/// questions on wide screens put the clock beside the input, like the web
/// app's `.time-side` layout, so nothing needs scrolling.
class QuizScreen extends StatelessWidget {
  final QuizController quiz;
  final VoidCallback onQuit;
  const QuizScreen({super.key, required this.quiz, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: quiz.settings.lang == "ar"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: ScreenBackground(
        child: ListenableBuilder(
          listenable: quiz,
          builder: (context, _) {
            final side = quiz.current.isTime;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: side ? 760 : 560,
                  maxHeight: 860,
                ),
                child: LayoutBuilder(builder: (context, box) => _body(box)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(BoxConstraints box) {
    final q = quiz.current;
    final header = <Widget>[
      _topBar(),
      const SizedBox(height: 14),
      if (quiz.timed) ...[_timeBar(), const SizedBox(height: 14)],
    ];

    if (!q.isTime) {
      final keyHeight = (box.maxHeight * 0.09).clamp(58.0, 84.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          _questionCard(box),
          const SizedBox(height: 14),
          // the pad sits at the bottom and its keys shrink to fit short phones
          Expanded(
            child: LayoutBuilder(
              builder: (context, pad) => Align(
                alignment: Alignment.bottomCenter,
                child: Numpad(
                  onKey: quiz.key,
                  showOk: !quiz.settings.autoSubmit,
                  keyHeight: min(
                    keyHeight,
                    max(40.0, (pad.maxHeight - 30) / 4),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // clock questions
    final wide = box.maxWidth > 560;
    final double keyHeight;
    final double clockSize;
    if (wide) {
      keyHeight = (box.maxHeight * 0.075).clamp(50.0, 72.0);
      clockSize = (box.maxWidth * 0.34).clamp(150.0, 240.0);
    } else {
      // phones: clock beside the answer box to save height
      keyHeight = (box.maxHeight * 0.07).clamp(44.0, 64.0);
      clockSize = min(box.maxWidth * 0.45, 200.0);
    }
    final card = _questionCard(box, clockSize: clockSize, compact: !wide);
    final input = quiz.usesPick
        ? _picker()
        : Numpad(
            onKey: quiz.key,
            showOk: !quiz.settings.autoSubmit,
            keyHeight: keyHeight,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: card)),
                    const SizedBox(width: 12),
                    Expanded(child: SingleChildScrollView(child: input)),
                  ],
                )
              : quiz.usesPick
              // 24 hour buttons don't fit under the clock on a phone: scroll
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [card, const SizedBox(height: 14), input],
                  ),
                )
              // typed answers: the numpad stays on screen and the card shrinks to fit above it
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(width: box.maxWidth, child: card),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    input,
                  ],
                ),
        ),
      ],
    );
  }

  Widget _questionCard(
    BoxConstraints box, {
    double clockSize = 0,
    bool compact = false,
  }) {
    final q = quiz.current;
    final t = kStrings[quiz.settings.lang]!;
    final Widget question;
    if (q.kgStyle == "shapes") {
      question = ConstrainedBox(
        // leave room for the header, answer box and a numpad with 44px keys
        constraints: BoxConstraints(
          maxHeight: max(100.0, min(box.maxHeight * 0.3, box.maxHeight - 480)),
        ),
        child: _Shapes(q: q, size: quiz.settings.kgSize),
      );
    } else if (q.isTime) {
      question = Text(
        questionText(q, quiz.settings.lang),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 24 : 30,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      );
    } else {
      question = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          questionText(q, quiz.settings.lang),
          textDirection:
              TextDirection.ltr, // equations always read left to right
          style: TextStyle(
            fontSize: min(58.0, max(38.0, box.maxWidth * 0.1)),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.text,
          ),
        ),
      );
    }
    // on the 24-hour clock every hour from 12:00 on shows the dark face
    final clock = ClockFace(
      h: q.a,
      m: q.b,
      night: q.clock24 && q.a >= 12,
      size: clockSize,
    );
    final daypart = q.clock24
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.s(
                q.a < 12
                    ? "morning"
                    : q.a < 18
                    ? "afternoon"
                    : "evening",
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: AppColors.heading,
              ),
            ),
          )
        : null;
    final answer = _AnswerBox(
      text: quiz.answerDisplay,
      mood: quiz.answerMood,
      trigger: quiz.index * 2 + (quiz.answerMood == Mood.none ? 0 : 1),
    );
    final feedback = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Text(
          quiz.feedbackText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact && q.isTime ? 17 : 21,
            fontWeight: FontWeight.w800,
            color: switch (quiz.feedbackMood) {
              Mood.good => AppColors.goodDark,
              Mood.bad => AppColors.badDark,
              Mood.none => AppColors.heading,
            },
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33281464),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: q.isTime && compact
          ? Column(
              children: [
                question,
                const SizedBox(height: 10),
                Row(
                  children: [
                    clock,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          ?daypart,
                          const SizedBox(height: 8),
                          answer,
                          feedback,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                question,
                if (q.isTime) ...[const SizedBox(height: 8), clock, ?daypart],
                const SizedBox(height: 14),
                answer,
                feedback,
              ],
            ),
    );
  }

  /// `.time-pick`: a row of hours, a row of minutes, and ✓ unless instant.
  Widget _picker() {
    final t = kStrings[quiz.settings.lang]!;
    Text label(String key, Color color) => Text(
      t.s(key),
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label("hours", const Color(0xFFD8CEFF)),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: PickRow(
            values: quiz.pickHours,
            kind: PickKind.hour,
            selected: quiz.pickH,
            onTap: quiz.pickHour,
          ),
        ),
        const SizedBox(height: 8),
        label("minutes", const Color(0xFFFFE3C2)),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: PickRow(
            values: quiz.pickMinutes,
            kind: PickKind.minute,
            selected: quiz.pickM,
            onTap: quiz.pickMinute,
          ),
        ),
        if (!quiz.settings.autoSubmit) ...[
          const SizedBox(height: 10),
          Opacity(
            opacity: quiz.pickComplete ? 1 : 0.4,
            child: Pressable(
              onTap: quiz.pickComplete ? quiz.pickOk : null,
              child: Container(
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.good,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "✓",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _topBar() => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        Pressable(
          onTap: onQuit,
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
            "${quiz.index + 1} / ${quiz.questions.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "⭐ ${quiz.scoreRounded}",
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

  Widget _timeBar() {
    final f = quiz.timerFraction;
    final color = f < 0.25
        ? AppColors.bad
        : f < 0.5
        ? AppColors.warn
        : AppColors.good;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: f,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 34,
            child: Text(
              "${quiz.secondsLeft}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.answer-box`: dashed while typing, solid green/red once answered.
class _AnswerBox extends StatelessWidget {
  final String text;
  final Mood mood;
  final int trigger;
  const _AnswerBox({
    required this.text,
    required this.mood,
    required this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (mood) {
      Mood.good => (AppColors.goodBg, AppColors.good, AppColors.goodDark),
      Mood.bad => (AppColors.badBg, AppColors.bad, AppColors.badDark),
      Mood.none => (
        AppColors.answerBg,
        AppColors.answerBorder,
        AppColors.purple,
      ),
    };
    final label = Text(
      text.isEmpty ? " " : text,
      textDirection: TextDirection.ltr,
      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: fg),
    );
    return PopShake(
      trigger: trigger,
      shake: mood == Mood.bad,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, minHeight: 64),
        child: CustomPaint(
          foregroundPainter: mood == Mood.none ? _DashedBorder(border) : null,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: mood == Mood.none
                  ? null
                  : Border.all(color: border, width: 3),
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  _DashedBorder(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(18),
        ).deflate(1.5),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, d + 9), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Kindergarten picture sum: each operand packed into a square-ish block of
/// emoji so the whole equation stays on one line, shrunk to fit — mirrors
/// shapesHTML() + fitShapes(). Big counts step the picture size down a notch.
class _Shapes extends StatelessWidget {
  final Question q;
  final String size;
  const _Shapes({required this.q, required this.size});

  static const _fontSizes = {"s": 38.0, "m": 50.0, "l": 62.0};

  @override
  Widget build(BuildContext context) {
    const sizes = ["s", "m", "l"];
    var si = sizes.indexOf(size);
    final total = q.a + q.b;
    if (total > 8) si--;
    if (total > 14) si--;
    final emojiSize = _fontSizes[sizes[max(0, si)]]!;

    Widget group(int n) {
      final cols = sqrt(n).ceil();
      final rows = (n / cols).ceil();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.softBg,
          border: Border.all(color: AppColors.chipBorder, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c < cols; c++)
                      Padding(
                        padding: EdgeInsets.only(left: c == 0 ? 0 : 8),
                        child: Opacity(
                          opacity: r * cols + c < n ? 1 : 0,
                          child: Text(
                            q.emoji!,
                            style: TextStyle(fontSize: emojiSize, height: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    Widget op(String s) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        s,
        style: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: AppColors.textMid,
        ),
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [group(q.a), op(kOpSymbol[q.op]!), group(q.b), op("= ?")],
        ),
      ),
    );
  }
}
