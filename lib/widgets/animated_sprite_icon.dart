import 'dart:math' as math;
import 'package:flutter/material.dart';

enum SpriteAnimationType {
  float,      // Gentle up & down hovering
  pulse,      // Soft breathing scale
  wiggle,     // Playful left-right tilt
  popIn,      // Bouncy elastic entrance
  celebrate,  // Bouncy jump with sparkle
  none,       // Static
}

/// Animated Sprite Icon Widget with clear micro-animations
class AnimatedSpriteIcon extends StatefulWidget {
  final String assetName; // e.g. 'mascot_pot_happy' or 'assets/sprites/mascot_pot_happy.png'
  final double? width;
  final double? height;
  final BoxFit fit;
  final SpriteAnimationType animationType;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AnimatedSpriteIcon({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.animationType = SpriteAnimationType.float,
    this.onTap,
    this.semanticLabel,
  });

  // Predefined factory constructors for each of the 12 icons:

  /// 1. Happy Mascot in Pot (Home / Companion)
  factory AnimatedSpriteIcon.mascotHappy({
    double size = 120,
    SpriteAnimationType anim = SpriteAnimationType.float,
    VoidCallback? onTap,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'mascot_pot_happy',
        width: size,
        height: size,
        animationType: anim,
        onTap: onTap,
      );

  /// 2. SpryFlora Text Logo with Sprout
  factory AnimatedSpriteIcon.logo({
    double width = 160,
    double height = 70,
    SpriteAnimationType anim = SpriteAnimationType.pulse,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'logo_spryflora',
        width: width,
        height: height,
        animationType: anim,
      );

  /// 3. Boy Planting Seedling (Onboarding 1 / Add Plant)
  factory AnimatedSpriteIcon.boyPlanting({
    double size = 160,
    SpriteAnimationType anim = SpriteAnimationType.float,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'boy_planting',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 4. Boy Scanning with Phone (Onboarding 2 / AI Doctor)
  factory AnimatedSpriteIcon.boyScanning({
    double size = 160,
    SpriteAnimationType anim = SpriteAnimationType.float,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'boy_phone_scanning',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 5. Green Potted Plant (My Plants / Species)
  factory AnimatedSpriteIcon.plantPotted({
    double size = 100,
    SpriteAnimationType anim = SpriteAnimationType.pulse,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'plant_potted',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 6. Winking Mascot in Pot (Onboarding 3 / Eco Buddy)
  factory AnimatedSpriteIcon.mascotWinking({
    double size = 130,
    SpriteAnimationType anim = SpriteAnimationType.wiggle,
    VoidCallback? onTap,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'mascot_pot_winking',
        width: size,
        height: size,
        animationType: anim,
        onTap: onTap,
      );

  /// 7. Circular Green Hero Avatar (Profile / Headers)
  factory AnimatedSpriteIcon.avatarHero({
    double size = 80,
    SpriteAnimationType anim = SpriteAnimationType.pulse,
    VoidCallback? onTap,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'avatar_boy_hero',
        width: size,
        height: size,
        animationType: anim,
        onTap: onTap,
      );

  /// 8. Golden Star Trophy (Milestones / Leaderboard)
  factory AnimatedSpriteIcon.trophy({
    double size = 90,
    SpriteAnimationType anim = SpriteAnimationType.float,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'trophy_champion',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 9. Achievement Diploma Scroll (Certificate Prompt)
  factory AnimatedSpriteIcon.scroll({
    double size = 90,
    SpriteAnimationType anim = SpriteAnimationType.float,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'scroll_diploma',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 10. Graduate Mascot with SpryFlora Logo (Certificate Header)
  factory AnimatedSpriteIcon.mascotGraduate({
    double size = 140,
    SpriteAnimationType anim = SpriteAnimationType.pulse,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'mascot_graduate_logo',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 11. Certificate Document Badge (Credentials / Unlock Card)
  factory AnimatedSpriteIcon.certificateDoc({
    double size = 90,
    SpriteAnimationType anim = SpriteAnimationType.float,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'certificate_doc',
        width: size,
        height: size,
        animationType: anim,
      );

  /// 12. Mascot Celebrating with Confetti (Celebration / Screen 20)
  factory AnimatedSpriteIcon.mascotCelebration({
    double size = 160,
    SpriteAnimationType anim = SpriteAnimationType.celebrate,
    VoidCallback? onTap,
  }) =>
      AnimatedSpriteIcon(
        assetName: 'mascot_celebrating_confetti',
        width: size,
        height: size,
        animationType: anim,
        onTap: onTap,
      );

  @override
  State<AnimatedSpriteIcon> createState() => _AnimatedSpriteIconState();
}

class _AnimatedSpriteIconState extends State<AnimatedSpriteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final duration = switch (widget.animationType) {
      SpriteAnimationType.float => const Duration(milliseconds: 2200),
      SpriteAnimationType.pulse => const Duration(milliseconds: 1800),
      SpriteAnimationType.wiggle => const Duration(milliseconds: 2000),
      SpriteAnimationType.popIn => const Duration(milliseconds: 700),
      SpriteAnimationType.celebrate => const Duration(milliseconds: 1400),
      SpriteAnimationType.none => const Duration(milliseconds: 100),
    };

    _ctrl = AnimationController(vsync: this, duration: duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    if (widget.animationType == SpriteAnimationType.popIn) {
      _ctrl.forward();
    } else if (widget.animationType != SpriteAnimationType.none) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _fullPath {
    if (widget.assetName.startsWith('assets/')) {
      return widget.assetName;
    }
    return 'assets/sprites/${widget.assetName}.png';
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      _fullPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco_rounded,
        size: widget.width ?? 48,
        color: const Color(0xFF4CAF50),
      ),
    );

    Widget animatedWidget;
    switch (widget.animationType) {
      case SpriteAnimationType.float:
        animatedWidget = AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final yOffset = math.sin(_anim.value * math.pi) * 8.0;
            return Transform.translate(
              offset: Offset(0, -yOffset),
              child: child,
            );
          },
          child: imageWidget,
        );
        break;

      case SpriteAnimationType.pulse:
        animatedWidget = AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final scale = 1.0 + (_anim.value * 0.06);
            return Transform.scale(scale: scale, child: child);
          },
          child: imageWidget,
        );
        break;

      case SpriteAnimationType.wiggle:
        animatedWidget = AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final angle = math.sin(_anim.value * math.pi) * 0.07;
            return Transform.rotate(angle: angle, child: child);
          },
          child: imageWidget,
        );
        break;

      case SpriteAnimationType.celebrate:
        animatedWidget = AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final jumpY = math.sin(_anim.value * math.pi) * 12.0;
            final scale = 1.0 + math.sin(_anim.value * math.pi) * 0.08;
            return Transform.translate(
              offset: Offset(0, -jumpY),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: imageWidget,
        );
        break;

      case SpriteAnimationType.popIn:
        animatedWidget = ScaleTransition(
          scale: Tween<double>(begin: 0.2, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
          ),
          child: imageWidget,
        );
        break;

      case SpriteAnimationType.none:
        animatedWidget = imageWidget;
        break;
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: animatedWidget,
      );
    }

    return animatedWidget;
  }
}
