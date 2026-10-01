import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Shrinks a little while pressed — the web app's `:active { transform: scale(...) }`.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.94,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}

/// Gradient backdrop + safe area — mirrors `body` / `.screen` in style.css.
class ScreenBackground extends StatelessWidget {
  final Widget child;
  const ScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Full-screen white page (setup, results): fills the screen edge to edge
/// like a normal app, with dark status-bar text.
class WhitePage extends StatelessWidget {
  final Widget child;
  const WhitePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: ColoredBox(
      color: Colors.white,
      child: SafeArea(child: child),
    ),
  );
}

/// The page's content column: comfortable padding, and on wide screens
/// (iPad) kept to a readable width in the middle.
class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: child,
    ),
  );
}

/// Full-width call-to-action — `.big-btn` (and `.big-btn.secondary`).
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final Gradient gradient;
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.gradient = AppColors.bigBtnGradient,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: EdgeInsets.only(top: secondary ? 12 : 8),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.97,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: secondary ? 14 : 18,
              horizontal: 12,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: secondary ? null : gradient,
              color: secondary ? AppColors.secondaryBg : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: secondary || disabled
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x73FFC542),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: secondary ? 19 : 24,
                fontWeight: FontWeight.w800,
                color: secondary ? AppColors.purple : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _chipDecoration(
  bool selected, {
  double radius = 18,
  double border = 2.5,
  Color? idleBg,
  Color? idleBorder,
}) => BoxDecoration(
  color: selected ? AppColors.purple : (idleBg ?? AppColors.chipBg),
  border: Border.all(
    color: selected ? AppColors.purple : (idleBorder ?? AppColors.chipBorder),
    width: border,
  ),
  borderRadius: BorderRadius.circular(radius),
  boxShadow: selected
      ? const [
          BoxShadow(
            color: Color(0x667C5CFF),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ]
      : null,
);

/// Text chip — `.chip`.
class SimpleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double minWidth;
  const SimpleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.minWidth = 62,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: _chipDecoration(selected),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    ),
  );
}

/// Symbol-over-name chip — `.op-chip` (operations and modes). Expands to share a row.
class OpChip extends StatelessWidget {
  final String symbol;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const OpChip({
    super.key,
    required this.symbol,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: _chipDecoration(selected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMid,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMid,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Small pill — `.lang-chip` (language switch and sound toggle).
class LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const LangChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _chipDecoration(
        selected,
        radius: 12,
        border: 2,
        idleBg: AppColors.softBg,
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.purple,
          ),
        ),
      ),
    ),
  );
}

/// Pops (success) or shakes (mistake) its child once each time [trigger] changes.
class PopShake extends StatefulWidget {
  final Widget child;
  final int trigger;
  final bool shake;
  const PopShake({
    super.key,
    required this.child,
    required this.trigger,
    required this.shake,
  });

  @override
  State<PopShake> createState() => _PopShakeState();
}

class _PopShakeState extends State<PopShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(PopShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final v = _c.value;
      if (!_c.isAnimating) return child!;
      if (widget.shake) {
        // @keyframes shake: -8, 8, -8, 8px at 20/40/60/80%, linear in between
        const stops = [0.0, -8.0, 8.0, -8.0, 8.0, 0.0];
        final i = (v * 5).floor().clamp(0, 4);
        final f = v * 5 - i;
        final dx = stops[i] + (stops[i + 1] - stops[i]) * f;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      }
      // @keyframes pop: up to 1.12 at 40%
      final s = v < 0.4
          ? 1 + 0.12 * (v / 0.4)
          : 1 + 0.12 * (1 - (v - 0.4) / 0.6);
      return Transform.scale(scale: s, child: child);
    },
  );
}
