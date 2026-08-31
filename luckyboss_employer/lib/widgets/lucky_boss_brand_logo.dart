import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon.png',
              height: height,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.brandRule.createShader(bounds),
              child: Text(
                'Luckyboss',
                style: GoogleFonts.archivo(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
