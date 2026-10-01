import 'dart:async';

import 'package:flutter/material.dart';

import '../data/strings.dart';
import '../services/progress_store.dart';
import '../theme.dart';
import 'common.dart';

/// The 📋 in the setup footer: opens the parents' mistakes log only after a
/// 600 ms hold, so kids don't wander in; a quick tap shows "Hold to open".
/// Mirrors #btn-parent and its pointer handlers in app.js.
class ParentLogButton extends StatefulWidget {
  final String lang;
  const ParentLogButton({super.key, required this.lang});

  @override
  State<ParentLogButton> createState() => _ParentLogButtonState();
}

class _ParentLogButtonState extends State<ParentLogButton> {
  Timer? _hold;
  Timer? _hintTimer;
  bool _pressing = false;
  bool _hint = false;

  void _down() {
    setState(() {
      _pressing = true;
      _hint = false;
    });
    _hold = Timer(const Duration(milliseconds: 600), () {
      _hold = null;
      setState(() => _pressing = false);
      showMistakesLog(context, widget.lang);
    });
  }

  void _up() {
    final wasPending = _hold != null; // released before the hold finished
    _cancel();
    if (wasPending) {
      setState(() => _hint = true);
      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _hint = false);
      });
    }
  }

  void _cancel() {
    _hold?.cancel();
    _hold = null;
    if (mounted) setState(() => _pressing = false);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _cancel(),
        child: AnimatedScale(
          scale: _pressing ? 1.3 : 1,
          duration: const Duration(milliseconds: 100),
          child: Opacity(
            opacity: _pressing ? 1 : 0.7,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text("📋", style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
      if (_hint)
        Text(
          kStrings[widget.lang]!.s("mistakesHoldHint"),
          style: const TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

/// "Sep 30" style dates without pulling in intl: day.month for German,
/// day/month for Arabic, month/day for English.
String _date(int ts, String lang) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int n) => n.toString().padLeft(2, "0");
  final time = "${two(d.hour)}:${two(d.minute)}";
  return switch (lang) {
    "de" => "${d.day}.${d.month}. $time",
    "ar" => "${d.day}/${d.month} $time",
    _ => "${d.month}/${d.day} $time",
  };
}

Future<void> showMistakesLog(BuildContext context, String lang) => showDialog(
  context: context,
  barrierColor: const Color(0x8C140A32),
  builder: (context) => Directionality(
    textDirection: lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
    child: _MistakesDialog(lang: lang),
  ),
);

class _MistakesDialog extends StatefulWidget {
  final String lang;
  const _MistakesDialog({required this.lang});

  @override
  State<_MistakesDialog> createState() => _MistakesDialogState();
}

class _MistakesDialogState extends State<_MistakesDialog> {
  List<Mistake> _list = MistakeLog.load().reversed.toList();

  @override
  Widget build(BuildContext context) {
    final t = kStrings[widget.lang]!;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.s("mistakesTitle"),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        t.s("mistakesClose"),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    t.s("mistakesEmpty"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final m = _list[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.missedBg,
                          border: Border.all(
                            color: AppColors.missedBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.prompt,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.given == null
                                  ? t.s("mistakesNoAnswer")
                                  : "${t.s("mistakesChild")}: ${m.given}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.badDark,
                              ),
                            ),
                            Text(
                              "${t.s("mistakesCorrect")}: ${m.correct}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goodDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _date(m.ts, widget.lang),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              BigButton(
                label: t.s("mistakesClear"),
                secondary: true,
                onTap: () {
                  MistakeLog.clear();
                  setState(() => _list = []);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
