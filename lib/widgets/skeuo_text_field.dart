import 'package:flutter/material.dart';
import '../theme/skeuo_theme.dart';

/// Skeuomorphic Recessed Input Field
/// Sunken physical groove aesthetic with simulated inner shadows and soft typography
class SkeuoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const SkeuoTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
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
          decoration: BoxDecoration(
            color: SkeuoTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC8D5C6),
              width: 1.2,
            ),
            boxShadow: [
              // Inset shadow simulation (darker top-left, lighter bottom-right)
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
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SkeuoTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: SkeuoTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: SkeuoTheme.primaryGreen,
                      size: 20,
                    )
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
