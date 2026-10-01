import 'package:flutter/material.dart';

import 'common.dart';

/// Hours and minutes get distinct colors so kids find the right row fast —
/// `.hourcol .pchip` / `.minutecol .pchip` in style.css.
enum PickKind { hour, minute }

class PickChip extends StatelessWidget {
  final String label;
  final PickKind kind;
  final bool selected;
  final bool wrong;
  final VoidCallback onTap;
  final double minWidth;
  final double minHeight;
  final double fontSize;
  const PickChip({
    super.key,
    required this.label,
    required this.kind,
    required this.selected,
    required this.onTap,
    this.wrong = false,
    this.minWidth = 48,
    this.minHeight = 46,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final hour = kind == PickKind.hour;
    final (bg, fg) = wrong
        ? (const Color(0xFFFFE6EA), const Color(0xFFE0284A))
        : selected
        ? (
            hour ? const Color(0xFF7C5CFF) : const Color(0xFFF97316),
            Colors.white,
          )
        : (
            hour ? const Color(0xFFEDE9FF) : const Color(0xFFFFEEDA),
            hour ? const Color(0xFF4C3BA8) : const Color(0xFFA05716),
          );
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E281464),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapping row of pick chips.
class PickRow extends StatelessWidget {
  final List<int> values;
  final PickKind kind;
  final int? selected;
  final bool wrong;
  final void Function(int v) onTap;
  final bool center;
  final double minWidth;
  final double minHeight;
  final double fontSize;
  final double spacing;
  const PickRow({
    super.key,
    required this.values,
    required this.kind,
    required this.selected,
    required this.onTap,
    this.wrong = false,
    this.center = false,
    this.minWidth = 48,
    this.minHeight = 46,
    this.fontSize = 18,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: spacing,
    runSpacing: spacing,
    alignment: center ? WrapAlignment.center : WrapAlignment.start,
    children: [
      for (final v in values)
        PickChip(
          label: kind == PickKind.minute ? v.toString().padLeft(2, "0") : "$v",
          kind: kind,
          selected: v == selected,
          wrong: wrong && v == selected,
          onTap: () => onTap(v),
          minWidth: minWidth,
          minHeight: minHeight,
          fontSize: fontSize,
        ),
    ],
  );
}
