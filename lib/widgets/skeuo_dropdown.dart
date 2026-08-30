import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Physical Dropdown Selector
class SkeuoDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final IconData? prefixIcon;

  const SkeuoDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SkeuoTheme.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: SkeuoTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC8D5C6),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: hintText != null
                  ? Text(
                      hintText!,
                      style: const TextStyle(
                        color: SkeuoTheme.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: SkeuoTheme.primaryGreen,
              ),
              dropdownColor: SkeuoTheme.surface,
              borderRadius: BorderRadius.circular(16),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
