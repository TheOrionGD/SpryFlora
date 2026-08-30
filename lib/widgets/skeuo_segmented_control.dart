import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Tactile Segmented Control (for YES / NO selection)
/// Unselected state looks raised; selected state sinks into the surface with tactile depth.
class SkeuoSegmentedControl extends StatelessWidget {
  final bool? value; // true = YES, false = NO, null = unselected
  final ValueChanged<bool> onChanged;

  const SkeuoSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: SkeuoTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC0CDC0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A8B7C).withValues(alpha: 0.35),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-2, -2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // YES Option
          Expanded(
            child: _buildSegmentButton(
              context: context,
              label: 'YES',
              icon: Icons.check_circle_outline,
              isSelected: value == true,
              activeColor: SkeuoTheme.primaryGreen,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 8),
          // NO Option
          Expanded(
            child: _buildSegmentButton(
              context: context,
              label: 'NO',
              icon: Icons.highlight_off,
              isSelected: value == false,
              activeColor: const Color(0xFFD32F2F),
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? activeColor : SkeuoTheme.surface,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    activeColor,
                    activeColor.withValues(alpha: 0.85),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    SkeuoTheme.surface,
                  ],
                ),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(1, 2),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: SkeuoTheme.darkShadow,
                    offset: const Offset(2, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : SkeuoTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isSelected ? Colors.white : SkeuoTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
