import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/strings.dart';
import '../models/settings.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

const String kAppVersion = "1.0.1"; // keep in sync with pubspec.yaml `version:`

/// The setup card — mirrors #screen-setup plus buildSetup()/refreshSetup().
/// Only what the native app can play so far is shown; the rest of the web
/// app's groups arrive with the features that use them.
class SetupScreen extends StatelessWidget {
  final VoidCallback onStart;
  const SetupScreen({super.key, required this.onStart});

  static const _ops = [("add", "+"), ("sub", "−"), ("mul", "×"), ("div", "÷")];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SettingsController>();
    final s = ctrl.settings;
    final t = kStrings[s.lang]!;
    void set(void Function(Settings s) f) => ctrl.update(f);

    final needsRange = s.ops.contains("add") || s.ops.contains("sub");
    final needsTables = s.ops.contains("mul") || s.ops.contains("div");
    final hint = s.ops.isEmpty
        ? t.s("hintOps")
        : needsTables && s.tables.isEmpty
            ? t.s("hintTables")
            : "";

    return Directionality(
      textDirection: s.lang == "ar" ? TextDirection.rtl : TextDirection.ltr,
      child: WhitePage(
        child: Center(
          child: SingleChildScrollView(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(t.s("title"),
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      for (final (code, label) in const [("en", "EN"), ("ar", "ع"), ("de", "DE")]) ...[
                        LangChip(label: label, selected: s.lang == code, onTap: () => set((s) => s.lang = code)),
                        const SizedBox(width: 6),
                      ],
                      LangChip(label: s.sound ? "🔊" : "🔇", selected: false, onTap: () => set((s) => s.sound = !s.sound)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Group(
                    title: t.s("ops"),
                    child: Row(
                      children: [
                        for (var i = 0; i < _ops.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: OpChip(
                              symbol: _ops[i].$2,
                              name: t.s(_ops[i].$1),
                              selected: s.ops.contains(_ops[i].$1),
                              onTap: () => set((s) => s.ops.contains(_ops[i].$1) ? s.ops.remove(_ops[i].$1) : s.ops.add(_ops[i].$1)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (s.ops.isNotEmpty)
                    _Group(
                      title: t.s("qFormat"),
                      child: _chips([
                        for (final f in ["result", "mixed"])
                          SimpleChip(
                            label: t.s(f == "result" ? "fmtResult" : "fmtMixed"),
                            selected: s.qFormat == f,
                            onTap: () => set((s) => s.qFormat = f),
                          ),
                      ]),
                    ),
                  if (needsRange)
                    _Group(
                      title: t.s("range"),
                      child: _chips([
                        for (final r in kRangeOptions)
                          SimpleChip(label: "$r", selected: s.range == r, onTap: () => set((s) => s.range = r)),
                      ]),
                    ),
                  if (needsTables) ...[
                    _Group(
                      title: t.s("tables"),
                      child: _chips([
                        for (var n = kTableMin; n <= kTableMax; n++)
                          SimpleChip(
                            label: "$n",
                            minWidth: 56,
                            selected: s.tables.contains(n),
                            onTap: () => set((s) => s.tables.contains(n) ? s.tables.remove(n) : s.tables.add(n)),
                          ),
                      ]),
                    ),
                    _Group(
                      title: t.s("factorMax"),
                      child: _chips([
                        for (final f in [10, 12])
                          SimpleChip(label: "× 1–$f", selected: s.factorMax == f, onTap: () => set((s) => s.factorMax = f)),
                      ]),
                    ),
                  ],
                  _Group(
                    title: t.s("count"),
                    child: _chips([
                      for (final c in kCountOptions)
                        SimpleChip(label: "$c", selected: s.count == c, onTap: () => set((s) => s.count = c)),
                    ]),
                  ),
                  _Group(
                    title: t.s("diff"),
                    note: t.s("diffNote"),
                    child: _chips([
                      for (final (d, key) in const [("easy", "diffEasy"), ("medium", "diffMed"), ("hard", "diffHard")])
                        SimpleChip(label: t.s(key), selected: s.difficulty == d, onTap: () => set((s) => s.difficulty = d)),
                    ]),
                  ),
                  _Group(
                    title: t.s("auto"),
                    child: _chips([
                      SimpleChip(label: t.s("autoOn"), selected: s.autoSubmit, onTap: () => set((s) => s.autoSubmit = true)),
                      SimpleChip(label: t.s("autoOff"), selected: !s.autoSubmit, onTap: () => set((s) => s.autoSubmit = false)),
                    ]),
                  ),
                  BigButton(label: t.s("start"), onTap: hint.isEmpty ? onStart : null),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(hint,
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                  ),
                  const SizedBox(height: 6),
                  const Text("v$kAppVersion",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.faint, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _chips(List<Widget> chips) => Wrap(spacing: 10, runSpacing: 10, children: chips);
}

/// `.setup-group`: a heading, its chips, and an optional grey note.
class _Group extends StatelessWidget {
  final String title;
  final Widget child;
  final String? note;
  const _Group({required this.title, required this.child, this.note});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.heading)),
            const SizedBox(height: 10),
            child,
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                child: Text(note!, style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      );
}
