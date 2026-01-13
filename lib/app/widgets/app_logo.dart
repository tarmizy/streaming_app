import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B7CF7), // Light purple blue
                  Color(0xFF6B5CE7), // Purple blue
                  Color(0xFFE966A0), // Pink
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Center(
        child: Text(
          'TOY',
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppLogoWithText extends StatelessWidget {
  final double logoSize;

  const AppLogoWithText({
    super.key,
    this.logoSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6B5CE7), Color(0xFFE966A0)],
          ).createShader(bounds),
          child: const Text(
            'TOY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'Tube On You',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
