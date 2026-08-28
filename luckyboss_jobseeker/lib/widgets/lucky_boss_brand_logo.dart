import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class LuckyBossBrandLogo extends StatelessWidget {
  final double height;
  final double fontSize;

  const LuckyBossBrandLogo({super.key, this.height = 36, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback when the asset is missing. Ledger sets the wordmark in the
        // system's own type rather than a third face, and the gradient is the
        // logo's actual ramp — this is one of the two places it is allowed.
        return ShaderMask(
          shaderCallback: (bounds) => AppTheme.brandRule.createShader(bounds),
          child: Text(
            'LuckyBOSS',
            style: GoogleFonts.archivo(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
