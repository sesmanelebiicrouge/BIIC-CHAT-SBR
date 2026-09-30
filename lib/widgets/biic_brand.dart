import 'package:flutter/material.dart';

class BiicBrand extends StatelessWidget {
  final double iconSize;
  final bool showSubtitle;
  const BiicBrand({super.key, this.iconSize = 54, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFFD71920),
            borderRadius: BorderRadius.circular(iconSize * .28),
          ),
          child: Icon(Icons.forum_rounded, color: Colors.white, size: iconSize * .52),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BIIC CHAT', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: .3)),
            if (showSubtitle)
              const Text('SBR • Messagerie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF777777))),
          ],
        ),
      ],
    );
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
      child: Text(text.isEmpty ? 'B' : text.substring(0, 1).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: radius * .72)),
    );
  }
}
