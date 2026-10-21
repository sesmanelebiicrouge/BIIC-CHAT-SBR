import 'package:flutter/material.dart';

/// Draws the BIIC CHAT logo with Flutter primitives instead of SVG text,
/// which is not consistently rendered by all Flutter Web engines.
class BiicBrand extends StatelessWidget {
  final double iconSize;
  final bool showSubtitle;
  const BiicBrand({super.key, this.iconSize = 54, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: iconSize, height: iconSize, child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFFD71920), borderRadius: BorderRadius.circular(iconSize * .22)),
        child: Center(child: Container(
          width: iconSize * .66, height: iconSize * .66,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(child: Container(
            width: iconSize * .58, height: iconSize * .58,
            decoration: const BoxDecoration(color: Color(0xFFD71920), shape: BoxShape.circle),
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('SBR', maxLines: 1, style: TextStyle(
              color: Colors.white, fontSize: iconSize * .225, fontWeight: FontWeight.w900, letterSpacing: iconSize * .002,
            )))),
          )),
        )),
      )),
      const SizedBox(width: 12),
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BIIC CHAT', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: .3)),
        if (showSubtitle) const Text('SBR • Messagerie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF777777))),
      ]),
    ]);
  }
}

class BiicAvatar extends StatelessWidget {
  final String? label;
  final double radius;
  const BiicAvatar({super.key, this.label, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final text = (label ?? 'B').trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFFFE5E6),
      foregroundColor: const Color(0xFFD71920),
      child: Text(
        text.isEmpty ? 'B' : text.substring(0, 1).toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: radius * .72),
      ),
    );
  }
}
