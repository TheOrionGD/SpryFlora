import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Fun Animated Cartoon Plant Widget featuring the SpryFlora Mascot Sprout
/// Features continuous wiggle + physics bounce + water droplets + health reactivity.
class FunAnimatedPlant extends StatefulWidget {
  final double health; // 0.0 – 100.0
  final double size;
  final bool isWatered;
  final bool showDroplets;
  final VoidCallback? onTap;

  const FunAnimatedPlant({
    super.key,
    required this.health,
    this.size = 160,
    this.isWatered = false,
    this.showDroplets = false,
    this.onTap,
  });

  @override
  State<FunAnimatedPlant> createState() => _FunAnimatedPlantState();
}

class _FunAnimatedPlantState extends State<FunAnimatedPlant>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _wiggleController;
  late AnimationController _dropletController;
  late AnimationController _tapReactionController;
  late Animation<double> _bounceAnim;
  late Animation<double> _wiggleAnim;
  late Animation<double> _dropletAnim;
  late Animation<double> _tapScaleAnim;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _dropletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _tapReactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _wiggleAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    _dropletAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dropletController, curve: Curves.easeOut),
    );

    _tapScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _tapReactionController, curve: Curves.easeInOut),
    );

    if (widget.showDroplets) {
      _dropletController.repeat();
    }
  }

  @override
  void didUpdateWidget(FunAnimatedPlant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showDroplets && !oldWidget.showDroplets) {
      _dropletController.repeat();
    } else if (!widget.showDroplets && oldWidget.showDroplets) {
      _dropletController.stop();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _wiggleController.dispose();
    _dropletController.dispose();
    _tapReactionController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapReactionController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bounceController,
          _wiggleController,
          _dropletController,
          _tapReactionController,
        ]),
        builder: (context, child) {
          final floatY = math.sin(_bounceAnim.value * math.pi) * 8;
          final wiggle = _wiggleAnim.value;
          final scale = _tapScaleAnim.value;

          return Transform.translate(
            offset: Offset(0, -floatY),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: wiggle,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow background when healthy / watered
                      if (widget.health > 70)
                        Container(
                          width: widget.size * 0.85,
                          height: widget.size * 0.85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF81C784).withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),

                      // Mascot Sprout Artwork (Transparent PNG)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/sprites/mascot_pot_happy.png',
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return CustomPaint(
                              size: Size(widget.size, widget.size),
                              painter: _PlantPainter(
                                health: widget.health,
                                isWatered: widget.isWatered,
                                bounceT: _bounceAnim.value,
                              ),
                            );
                          },
                        ),
                      ),

                      // Water droplets overlay on watering
                      if (widget.showDroplets)
                        ..._buildDroplets(_dropletAnim.value),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildDroplets(double t) {
    return [
      _Droplet(
        offset: Offset(-widget.size * 0.3, -widget.size * 0.2 + t * 45),
        opacity: 1 - t,
      ),
      _Droplet(
        offset: Offset(widget.size * 0.32, -widget.size * 0.25 + t * 50),
        opacity: (1 - t) * 0.85,
      ),
      _Droplet(
        offset: Offset(0, -widget.size * 0.45 + t * 55),
        opacity: (1 - t) * 0.95,
      ),
    ];
  }
}

class _Droplet extends StatelessWidget {
  final Offset offset;
  final double opacity;

  const _Droplet({required this.offset, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: const Icon(
          Icons.water_drop_rounded,
          color: SkeuoTheme.waterBlue,
          size: 20,
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final double health;
  final bool isWatered;
  final double bounceT;

  _PlantPainter({
    required this.health,
    required this.isWatered,
    required this.bounceT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final leafColor = health > 60
        ? const Color(0xFF43A047)
        : health > 30
            ? const Color(0xFFAFB42B)
            : const Color(0xFF827717);

    final potColor =
        health > 50 ? const Color(0xFF8D6E63) : const Color(0xFF795548);
    final stemColor =
        health > 40 ? const Color(0xFF558B2F) : const Color(0xFF827717);

    final leafPaint = Paint()..color = leafColor..style = PaintingStyle.fill;
    final potPaint = Paint()..color = potColor..style = PaintingStyle.fill;
    final stemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Pot
    final potRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + size.height * 0.28),
        width: size.width * 0.42,
        height: size.height * 0.26,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(potRect, potPaint);

    // Pot rim
    final rimPaint = Paint()
      ..color = potColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.15),
          width: size.width * 0.48,
          height: size.height * 0.08,
        ),
        const Radius.circular(6),
      ),
      rimPaint,
    );

    // Main stem
    final stemPath = Path()
      ..moveTo(cx, cy + size.height * 0.14)
      ..quadraticBezierTo(
        cx + 5,
        cy - size.height * 0.05,
        cx,
        cy - size.height * 0.18,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Leaves
    _drawLeaf(canvas, cx, cy, leafPaint, isLeft: true, health: health);
    _drawLeaf(canvas, cx, cy, leafPaint, isLeft: false, health: health);
  }

  void _drawLeaf(
    Canvas canvas,
    double cx,
    double cy,
    Paint paint, {
    required bool isLeft,
    required double health,
  }) {
    final direction = isLeft ? -1.0 : 1.0;
    final leafPath = Path()
      ..moveTo(cx, cy - 10)
      ..cubicTo(
        cx + direction * 35,
        cy - 40,
        cx + direction * 45,
        cy - 10,
        cx + direction * 15,
        cy + 5,
      )
      ..close();
    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return oldDelegate.health != health ||
        oldDelegate.isWatered != isWatered ||
        oldDelegate.bounceT != bounceT;
  }
}
