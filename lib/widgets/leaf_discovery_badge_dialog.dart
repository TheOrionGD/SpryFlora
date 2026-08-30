import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/skeuo_theme.dart';
import 'fun_bouncy_button.dart';

/// Interactive Discovery Badge & Leaf Particle Celebration Modal
/// Displayed when a user captures or scans a newly discovered plant species.
class LeafDiscoveryBadgeDialog extends StatefulWidget {
  final String speciesName;
  final String badgeName;
  final String rewardMessage;

  const LeafDiscoveryBadgeDialog({
    super.key,
    required this.speciesName,
    this.badgeName = '🌱 Botanical Explorer Badge',
    this.rewardMessage =
        'You discovered and added a new plant species to the SpryFlora catalogue!',
  });

  static Future<void> show(
    BuildContext context, {
    required String speciesName,
    String badgeName = '🌱 Botanical Explorer Badge',
    String rewardMessage =
        'You discovered and added a new plant species to the SpryFlora catalogue!',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeafDiscoveryBadgeDialog(
        speciesName: speciesName,
        badgeName: badgeName,
        rewardMessage: rewardMessage,
      ),
    );
  }

  @override
  State<LeafDiscoveryBadgeDialog> createState() =>
      _LeafDiscoveryBadgeDialogState();
}

class _LeafDiscoveryBadgeDialogState extends State<LeafDiscoveryBadgeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _badgeRotateAnim;

  final List<_LeafParticle> _particles = List.generate(
    24,
    (index) => _LeafParticle(),
  );

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );

    _badgeRotateAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Falling Leaf Background Particles ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LeafParticlePainter(
                    particles: _particles,
                    progress: _animCtrl.value,
                  ),
                );
              },
            ),
          ),

          // ── Main Discovery Card ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFC8E6C9),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Badge Avatar
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_scaleAnim.value * 0.05),
                      child: Transform.rotate(
                        angle: _badgeRotateAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD54F),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43A047)
                                    .withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🎖️',
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Badge Ribbon Title
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFFCA28), width: 1.5),
                  ),
                  child: Text(
                    widget.badgeName,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Main Heading
                Text(
                  'New Species Discovered!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Species Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF81C784), width: 1.2),
                  ),
                  child: Text(
                    '🌿 ${widget.speciesName}',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: SkeuoTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Reward & Description
                Text(
                  widget.rewardMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Bonus XP Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFC8E6C9), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFFFFB300), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '+150 Garden Discovery Score',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Claim Button
                SizedBox(
                  width: double.infinity,
                  child: FunBouncyButton(
                    text: 'Claim Badge & Continue 🎉',
                    onPressed: () => Navigator.of(context).pop(),
                    color: SkeuoTheme.primaryGreen,
                    height: 52,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double speed = 0.2 + math.Random().nextDouble() * 0.4;
  double size = 8 + math.Random().nextDouble() * 14;
  double rotation = math.Random().nextDouble() * math.pi * 2;
  double rotSpeed = (math.Random().nextDouble() - 0.5) * 2;
  Color color = [
    const Color(0xFF66BB6A),
    const Color(0xFF81C784),
    const Color(0xFFA5D6A7),
    const Color(0xFFFFD54F),
    const Color(0xFFFFCA28),
  ][math.Random().nextInt(5)];
}

class _LeafParticlePainter extends CustomPainter {
  final List<_LeafParticle> particles;
  final double progress;

  _LeafParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = ((p.y + (progress * p.speed)) % 1.0) * size.height;
      final currentX =
          (p.x * size.width) + (math.sin(progress * math.pi * 2 + p.y) * 20);
      final currentRot = p.rotation + (progress * p.rotSpeed * math.pi);

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      // Draw leaf shape
      final path = Path();
      path.moveTo(0, -p.size / 2);
      path.quadraticBezierTo(p.size / 2, 0, 0, p.size / 2);
      path.quadraticBezierTo(-p.size / 2, 0, 0, -p.size / 2);
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafParticlePainter oldDelegate) => true;
}
