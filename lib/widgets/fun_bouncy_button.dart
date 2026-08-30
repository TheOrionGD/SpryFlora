import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/skeuo_theme.dart';

/// Fun Bouncy Button — springs back after press, pill shaped, gradient.
class FunBouncyButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double height;
  final double fontSize;
  final Gradient? gradient;

  const FunBouncyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.height = 56,
    this.fontSize = 16,
    this.gradient,
  });

  @override
  State<FunBouncyButton> createState() => _FunBouncyButtonState();
}

class _FunBouncyButtonState extends State<FunBouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
          parent: _controller,
          curve: Curves.easeIn,
          reverseCurve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (widget.color ?? SkeuoTheme.primaryGreen)
                        .withValues(alpha: 0.9),
                    widget.color ?? SkeuoTheme.primaryGreenDark,
                  ],
                ),
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? SkeuoTheme.primaryGreen)
                    .withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: widget.textColor ?? Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: GoogleFonts.nunito(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  color: widget.textColor ?? Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fun Pill Badge — colorful rounded label badge
class FunPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;

  const FunPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = SkeuoTheme.primaryGreen,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated bouncing dot indicator for onboarding pages
class BouncingDotIndicator extends StatefulWidget {
  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  const BouncingDotIndicator({
    super.key,
    required this.count,
    required this.current,
    this.activeColor = SkeuoTheme.primaryGreen,
    this.inactiveColor = SkeuoTheme.lightGreen,
  });

  @override
  State<BouncingDotIndicator> createState() => _BouncingDotIndicatorState();
}

class _BouncingDotIndicatorState extends State<BouncingDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (i) {
        final isActive = i == widget.current;
        return AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, isActive ? _bounce.value : 0),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? widget.activeColor
                  : widget.inactiveColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: widget.activeColor
                      .withValues(alpha: isActive ? 0.4 : 0.0),
                  blurRadius: isActive ? 6.0 : 0.0,
                  offset: isActive ? const Offset(0, 2) : Offset.zero,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
