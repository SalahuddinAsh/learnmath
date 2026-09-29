import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/quiz_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/numpad.dart';

/// One question at a time: progress + score, timer bar, the question card
/// and the numpad — mirrors #screen-quiz.
class QuizScreen extends StatelessWidget {
  final QuizController quiz;
  final VoidCallback onQuit;
  const QuizScreen({super.key, required this.quiz, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: quiz.settings.lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: ScreenBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 860),
            child: LayoutBuilder(
              builder: (context, box) => ListenableBuilder(
                listenable: quiz,
                builder: (context, _) => _body(box),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BoxConstraints box) {
    final q = quiz.current;
    final keyHeight = (box.maxHeight * 0.09).clamp(58.0, 84.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topBar(),
        const SizedBox(height: 14),
        if (quiz.timed) ...[_timeBar(), const SizedBox(height: 14)],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x33281464), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  questionText(q, quiz.settings.lang),
                  textDirection: q.isTime ? null : TextDirection.ltr, // equations always read left to right
                  style: TextStyle(
                    fontSize: min(58.0, max(38.0, box.maxWidth * 0.1)),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AnswerBox(
                text: quiz.answerDisplay,
                mood: quiz.answerMood,
                trigger: quiz.index * 2 + (quiz.answerMood == Mood.none ? 0 : 1),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Text(
                  quiz.feedbackText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: switch (quiz.feedbackMood) {
                      Mood.good => AppColors.goodDark,
                      Mood.bad => AppColors.badDark,
                      Mood.none => AppColors.heading,
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // the pad sits at the bottom and its keys shrink to fit short phones
        Expanded(
          child: LayoutBuilder(
            builder: (context, pad) => Align(
              alignment: Alignment.bottomCenter,
              child: Numpad(
                onKey: quiz.key,
                showOk: !quiz.settings.autoSubmit,
                keyHeight: min(keyHeight, max(40.0, (pad.maxHeight - 30) / 4)),
              ),
            ),
          ),
        ),
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
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14)),
                child: const Text("✕", style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),
            Expanded(
              child: Text(
                "${quiz.index + 1} / ${quiz.questions.length}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14)),
              child: Text("⭐ ${quiz.scoreRounded}",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _timeBar() {
    final f = quiz.timerFraction;
    final color = f < 0.25 ? AppColors.bad : f < 0.5 ? AppColors.warn : AppColors.good;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: f,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 34,
            child: Text("${quiz.secondsLeft}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
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
  const _AnswerBox({required this.text, required this.mood, required this.trigger});

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (mood) {
      Mood.good => (AppColors.goodBg, AppColors.good, AppColors.goodDark),
      Mood.bad => (AppColors.badBg, AppColors.bad, AppColors.badDark),
      Mood.none => (AppColors.answerBg, AppColors.answerBorder, AppColors.purple),
    };
    final label = Text(text.isEmpty ? " " : text,
        textDirection: TextDirection.ltr, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: fg));
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
              border: mood == Mood.none ? null : Border.all(color: border, width: 3),
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
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)).deflate(1.5));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, d + 9), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
