import 'package:flutter/material.dart';

import '../data/strings.dart';
import '../logic/quiz_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Stars, score out of 1000, best score, cheer and the questions to review —
/// mirrors #screen-results / finishQuiz().
class ResultsScreen extends StatelessWidget {
  final QuizResult result;
  final String lang;
  final VoidCallback onAgain;
  final VoidCallback onSettings;
  const ResultsScreen({super.key, required this.result, required this.lang, required this.onAgain, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final t = kStrings[lang]!;
    final r = result;
    return Directionality(
      textDirection: lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: ScreenBackground(
        child: Center(
          child: SingleChildScrollView(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(r.stars > 0 ? "⭐" * r.stars : "🌱",
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 52, letterSpacing: 6)),
                  const SizedBox(height: 6),
                  Text(t.s("score"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: "${r.score} "),
                      const TextSpan(text: "/ 1000", style: TextStyle(fontSize: 22, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    ]),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.purple),
                  ),
                  Text("✓ ${r.correct} / ${r.total}",
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.goodDark)),
                  const SizedBox(height: 8),
                  Text(
                    r.isNewRecord ? t.s("newRecord") : "${t.s("best")}: ${r.best}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.isNewRecord ? 21 : 18,
                      fontWeight: FontWeight.w700,
                      color: r.isNewRecord ? AppColors.record : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t.s("cheer${r.stars}"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.heading)),
                  const SizedBox(height: 16),
                  if (r.missed.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.missedBg,
                        border: Border.all(color: AppColors.missedBorder, width: 2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.s("review"),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.badDark)),
                          const SizedBox(height: 6),
                          for (final q in r.missed)
                            Text(
                              q.isTime ? "🕐 ${answerText(q)}" : q.solvedText,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.6, color: AppColors.textMid),
                            ),
                        ],
                      ),
                    ),
                  BigButton(label: t.s("again"), onTap: onAgain),
                  BigButton(label: t.s("settings"), onTap: onSettings, secondary: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
