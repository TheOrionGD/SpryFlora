import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/milestone_stage.dart';

/// Containerless Floating Stage Mascot Display Widget.
/// Displays stage mascot artwork floating directly over background video,
/// without any diamond or hexagon stone card container framing it.
class StagePedestalCard extends StatefulWidget {
  final MilestoneStage stage;
  final double size;
  final bool isGlowing;

  const StagePedestalCard({
    super.key,
    required this.stage,
    this.size = 210.0,
    this.isGlowing = true,
  });

  @override
  State<StagePedestalCard> createState() => _StagePedestalCardState();
}

class _StagePedestalCardState extends State<StagePedestalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double imgSize = widget.size * 0.72;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: AnimatedBuilder(
        key: ValueKey('stage_pedestal_${widget.stage.stageNumber}'),
        animation: _floatCtrl,
        builder: (context, child) {
          final double dy = (1.0 - _floatCtrl.value) * 8.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stage Number & Symbol Floating Title Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E272C).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isGlowing
                        ? const Color(0xFFF1C40F)
                        : Colors.white38,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (widget.isGlowing)
                      BoxShadow(
                        color: const Color(0xFFF1C40F).withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1C40F),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.stage.stageNumber}',
                          style: GoogleFonts.cinzel(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.stage.badgeSymbol.toUpperCase(),
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Containerless Floating Mascot / Stage Artwork with Glow
              Transform.translate(
                offset: Offset(0, -dy),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle Golden Glow behind floating artwork
                    if (widget.isGlowing)
                      Container(
                        width: imgSize * 1.1,
                        height: imgSize * 1.1,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFF1C40F).withValues(alpha: 0.45),
                              const Color(0xFF2ECC71).withValues(alpha: 0.20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                    // Floating Mascot Sprite Asset directly on video background
                    SizedBox(
                      width: imgSize,
                      height: imgSize,
                      child: Image.asset(
                        widget.stage.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black45,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          child: Icon(
                            widget.stage.fallbackIcon,
                            size: imgSize * 0.55,
                            color: const Color(0xFF2ECC71),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

