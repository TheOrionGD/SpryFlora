import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/skeuo_theme.dart';

/// Clean botanical Bottom Navigation Bar matching 255.jpg (Home, Plants, Buddy, Garden, Profile).
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SkeuoTheme.background,
        border: Border(
          top: BorderSide(color: SkeuoTheme.cardBorder, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                icon: Icons.home_rounded,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                icon: Icons.spa_outlined,
                activeIcon: Icons.spa_rounded,
                label: 'Plants',
                isSelected: currentIndex == 1,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                icon: Icons.sentiment_satisfied_alt_outlined,
                activeIcon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Buddy',
                isSelected: currentIndex == 2,
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                icon: Icons.filter_vintage_outlined,
                activeIcon: Icons.filter_vintage_rounded,
                label: 'Garden',
                isSelected: currentIndex == 3,
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = SkeuoTheme.primaryGreen;
    final inactiveColor = const Color(0xFF7A9377);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
