import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/strings.dart';
import '../models/settings.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mistakes_log.dart';

const String kAppVersion = "1.1.0"; // keep in sync with pubspec.yaml `version:`

/// The setup page — mirrors #screen-setup plus buildSetup()/refreshSetup():
/// each group only shows when the chosen mode/operations use it.
class SetupScreen extends StatelessWidget {
  final VoidCallback onStart;
  const SetupScreen({super.key, required this.onStart});

  static const _ops = [
    ("add", "+"),
    ("sub", "−"),
    ("mul", "×"),
    ("div", "÷"),
    ("time", "🕐"),
  ];
  static const _modes = [
    ("test", "🎯", "modeTest"),
    ("kg", "🧸", "modeKg"),
    ("tables", "✖️", "modeTables"),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SettingsController>();
    final s = ctrl.settings;
    final t = kStrings[s.lang]!;
    void set(void Function(Settings s) f) => ctrl.update(f);

    final kg = s.mode == "kg";
    final marathon = s.mode == "tables";
    final test = s.mode == "test";
    final activeOps = kg ? s.kgOps : s.ops;
    final needsRange = test && (s.ops.contains("add") || s.ops.contains("sub"));
    final needsTables =
        marathon || (test && (s.ops.contains("mul") || s.ops.contains("div")));
    final needsTime = test && s.ops.contains("time");
    final arithSelected = s.ops.any((o) => o != "time");
    final hint = !marathon && activeOps.isEmpty
        ? t.s("hintOps")
        : needsTables && s.tables.isEmpty
        ? t.s("hintTables")
        : "";

    SimpleChip chip(
      String label,
      bool selected,
      void Function(Settings s) f, {
      double minWidth = 62,
    }) => SimpleChip(
      label: label,
      selected: selected,
      minWidth: minWidth,
      onTap: () => set(f),
    );

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
                          child: Text(
                            t.s("title"),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      for (final (code, label) in const [
                        ("en", "EN"),
                        ("ar", "ع"),
                        ("de", "DE"),
                      ]) ...[
                        LangChip(
                          label: label,
                          selected: s.lang == code,
                          onTap: () => set((s) => s.lang = code),
                        ),
                        const SizedBox(width: 6),
                      ],
                      LangChip(
                        label: s.sound ? "🔊" : "🔇",
                        selected: false,
                        onTap: () => set((s) => s.sound = !s.sound),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Group(
                    title: t.s("mode"),
                    child: _row([
                      for (final (mode, sym, key) in _modes)
                        OpChip(
                          symbol: sym,
                          name: t.s(key),
                          selected: s.mode == mode,
                          onTap: () => set((s) => s.mode = mode),
                        ),
                    ]),
                  ),
                  if (!marathon)
                    _Group(
                      title: t.s("ops"),
                      // kindergarten only offers + and −
                      child: _row([
                        for (final (op, sym) in _ops)
                          if (!kg || op == "add" || op == "sub")
                            OpChip(
                              symbol: sym,
                              name: t.s(op),
                              selected: activeOps.contains(op),
                              onTap: () => set((s) {
                                final list = kg ? s.kgOps : s.ops;
                                list.contains(op)
                                    ? list.remove(op)
                                    : list.add(op);
                              }),
                            ),
                      ]),
                    ),
                  if (kg) ...[
                    _Group(
                      title: t.s("range"),
                      child: _wrap([
                        for (final r in kKgRangeOptions)
                          chip("$r", s.kgRange == r, (s) => s.kgRange = r),
                      ]),
                    ),
                    _Group(
                      title: t.s("style"),
                      child: _row([
                        for (final (style, sym) in const [
                          ("shapes", "🍎"),
                          ("digits", "🔢"),
                        ])
                          OpChip(
                            symbol: sym,
                            name: t.s(style),
                            selected: s.kgStyle == style,
                            onTap: () => set((s) => s.kgStyle = style),
                          ),
                      ]),
                    ),
                    if (s.kgStyle == "shapes")
                      _Group(
                        title: t.s("kgSize"),
                        child: _wrap([
                          for (final (size, key) in const [
                            ("s", "sizeS"),
                            ("m", "sizeM"),
                            ("l", "sizeL"),
                          ])
                            chip(
                              t.s(key),
                              s.kgSize == size,
                              (s) => s.kgSize = size,
                            ),
                        ]),
                      ),
                    _Group(
                      title: t.s("kgTimer"),
                      child: _wrap([
                        chip(
                          t.s("timerOn"),
                          s.kgTimer,
                          (s) => s.kgTimer = true,
                        ),
                        chip(
                          t.s("timerOff"),
                          !s.kgTimer,
                          (s) => s.kgTimer = false,
                        ),
                      ]),
                    ),
                  ],
                  if (test && arithSelected)
                    _Group(
                      title: t.s("qFormat"),
                      child: _wrap([
                        chip(
                          t.s("fmtResult"),
                          s.qFormat == "result",
                          (s) => s.qFormat = "result",
                        ),
                        chip(
                          t.s("fmtMixed"),
                          s.qFormat == "mixed",
                          (s) => s.qFormat = "mixed",
                        ),
                      ]),
                    ),
                  if (needsRange)
                    _Group(
                      title: t.s("range"),
                      child: _wrap([
                        for (final r in kRangeOptions)
                          chip("$r", s.range == r, (s) => s.range = r),
                      ]),
                    ),
                  if (needsTables) ...[
                    _Group(
                      title: t.s("tables"),
                      note: marathon ? t.s("tablesNote") : null,
                      child: _wrap([
                        for (var n = kTableMin; n <= kTableMax; n++)
                          chip(
                            "$n",
                            s.tables.contains(n),
                            (s) => s.tables.contains(n)
                                ? s.tables.remove(n)
                                : s.tables.add(n),
                            minWidth: 56,
                          ),
                      ]),
                    ),
                    _Group(
                      title: t.s("factorMax"),
                      child: _wrap([
                        for (final f in [10, 12])
                          chip(
                            "× 1–$f",
                            s.factorMax == f,
                            (s) => s.factorMax = f,
                          ),
                      ]),
                    ),
                  ],
                  if (needsTime) ...[
                    _Group(
                      title: t.s("timeLevel"),
                      child: _wrap([
                        chip(
                          t.s("level1"),
                          s.timeLevel == 1,
                          (s) => s.timeLevel = 1,
                        ),
                        chip(
                          t.s("level2"),
                          s.timeLevel == 2,
                          (s) => s.timeLevel = 2,
                        ),
                      ]),
                    ),
                    _Group(
                      title: t.s("clockMode"),
                      child: _wrap([
                        for (final (mode, key) in const [
                          ("12", "c12"),
                          ("24", "c24"),
                          ("dual", "cDual"),
                        ])
                          chip(
                            t.s(key),
                            s.clockMode == mode,
                            (s) => s.clockMode = mode,
                          ),
                      ]),
                    ),
                    _Group(
                      title: t.s("clockTask"),
                      child: _wrap([
                        for (final (task, key) in const [
                          ("read", "taskRead"),
                          ("shift", "taskShift"),
                          ("both", "taskBoth"),
                        ])
                          chip(
                            t.s(key),
                            s.clockTask == task,
                            (s) => s.clockTask = task,
                          ),
                      ]),
                    ),
                    _Group(
                      title: t.s("timeInput"),
                      child: _wrap([
                        chip(
                          t.s("inputPick"),
                          s.timeInput == "pick",
                          (s) => s.timeInput = "pick",
                        ),
                        chip(
                          t.s("inputType"),
                          s.timeInput == "type",
                          (s) => s.timeInput = "type",
                        ),
                      ]),
                    ),
                  ],
                  if (!marathon)
                    _Group(
                      title: t.s("count"),
                      child: _wrap([
                        for (final c in kCountOptions)
                          chip("$c", s.count == c, (s) => s.count = c),
                      ]),
                    ),
                  if (!(kg && !s.kgTimer))
                    _Group(
                      title: t.s("diff"),
                      note: t.s("diffNote"),
                      child: _wrap([
                        for (final (d, key) in const [
                          ("easy", "diffEasy"),
                          ("medium", "diffMed"),
                          ("hard", "diffHard"),
                        ])
                          chip(
                            t.s(key),
                            s.difficulty == d,
                            (s) => s.difficulty = d,
                          ),
                      ]),
                    ),
                  _Group(
                    title: t.s("game"),
                    note: t.s("gameNote"),
                    child: _wrap([
                      for (final g in kGameScoreOptions)
                        chip(
                          g == 0 ? t.s("gameOff") : "$g",
                          s.gameScore == g,
                          (s) => s.gameScore = g,
                        ),
                    ]),
                  ),
                  _Group(
                    title: t.s("auto"),
                    child: _wrap([
                      chip(
                        t.s("autoOn"),
                        s.autoSubmit,
                        (s) => s.autoSubmit = true,
                      ),
                      chip(
                        t.s("autoOff"),
                        !s.autoSubmit,
                        (s) => s.autoSubmit = false,
                      ),
                    ]),
                  ),
                  BigButton(
                    label: t.s("start"),
                    onTap: hint.isEmpty ? onStart : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "v$kAppVersion",
                          style: TextStyle(
                            color: AppColors.faint,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ParentLogButton(lang: s.lang),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _wrap(List<Widget> chips) =>
      Wrap(spacing: 10, runSpacing: 10, children: chips);

  /// Chips sharing one line equally (`#op-row`, mode row).
  static Widget _row(List<Widget> chips) => Row(
    children: [
      for (var i = 0; i < chips.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(child: chips[i]),
      ],
    ],
  );
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 10),
        child,
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
            child: Text(
              note!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}
