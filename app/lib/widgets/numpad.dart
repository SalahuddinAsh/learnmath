import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// 1–9, ⌫, 0, ✓ — `.numpad` in style.css. With [showOk] false (instant entry)
/// the ✓ key is gone and 0 takes its slot, like `.numpad.no-ok`.
class Numpad extends StatelessWidget {
  final void Function(String key) onKey;
  final bool showOk;
  final double keyHeight;
  const Numpad({super.key, required this.onKey, this.showOk = true, this.keyHeight = 72});

  Widget _key(String k, String label, {Color bg = Colors.white, Color fg = AppColors.text}) => Pressable(
        onTap: () => onKey(k),
        pressedScale: 0.93,
        child: Container(
          height: keyHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x2E281464), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Text(label, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: fg)),
        ),
      );

  Widget _row(List<Widget> keys) => Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: keys[i]),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    final back = _key("back", "⌫", bg: AppColors.backKey, fg: AppColors.record);
    final zero = _key("0", "0");
    return Directionality(
      textDirection: TextDirection.ltr, // digits keep phone-pad order in the Arabic UI too
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in const [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
          ]) ...[
            _row([for (final d in r) _key(d, d)]),
            const SizedBox(height: 10),
          ],
          showOk
              ? _row([back, zero, _key("ok", "✓", bg: AppColors.good, fg: Colors.white)])
              : Row(children: [Expanded(child: back), const SizedBox(width: 10), Expanded(flex: 2, child: zero)]),
        ],
      ),
    );
  }
}
