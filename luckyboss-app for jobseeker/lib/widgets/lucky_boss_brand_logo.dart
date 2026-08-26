import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuckyBossBrandLogo extends StatelessWidget {
  final double height;
  final double fontSize;

  const LuckyBossBrandLogo({super.key, this.height = 32, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lucky', style: GoogleFonts.cormorantGaramond(fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            Text('Boss', style: GoogleFonts.cormorantGaramond(fontSize: fontSize, fontWeight: FontWeight.w800, color: const Color(0xFF0B1B3D))),
          ],
        );
      },
    );
  }
}
