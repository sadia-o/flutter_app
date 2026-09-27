import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class AuthenticatedBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final int unreadAlertCount;
  final ValueChanged<int> onSelected;

  const AuthenticatedBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.unreadAlertCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.place_outlined,
              activeIcon: Icons.place,
              label: 'Stations',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications,
              label: 'Alerts',
              badgeCount: unreadAlertCount,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.insert_chart_outlined,
              activeIcon: Icons.insert_chart,
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? AppColors.primaryBlue : AppColors.textTertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(index),
      child: Semantics(
        label: label,
        selected: isSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.criticalRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: isSelected
                    ? AppTypography.manropeBold.copyWith(
                        fontSize: 10,
                        color: color,
                      )
                    : AppTypography.manropeSemiBold.copyWith(
                        fontSize: 10,
                        color: color,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
