import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra inferior com FAB central (inspirada no EasyFlow, adaptada ao LifeUp).
class LifeUpBottomNav extends StatelessWidget {
  const LifeUpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.syncBadgeCount = 0,
    this.fabIcon = Icons.add_rounded,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final int syncBadgeCount;
  final IconData fabIcon;

  static const _fabSize = 58.0;
  static const _fabOverlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 64 + bottom + _fabOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _TabItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Início',
                            selected: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                          _TabItem(
                            icon: Icons.checklist_outlined,
                            activeIcon: Icons.checklist_rounded,
                            label: 'Hábitos',
                            selected: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: Row(
                        children: [
                          _TabItem(
                            icon: Icons.flag_outlined,
                            activeIcon: Icons.flag_rounded,
                            label: 'Metas',
                            selected: currentIndex == 2,
                            onTap: () => onTap(2),
                          ),
                          _TabItem(
                            icon: Icons.cloud_sync_outlined,
                            activeIcon: Icons.cloud_sync_rounded,
                            label: 'Sync',
                            selected: currentIndex == 3,
                            badgeCount: syncBadgeCount,
                            onTap: () => onTap(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: bottom + 64 - _fabOverlap,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: _fabSize + 12,
                height: _fabSize + 12,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    fabIcon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              child: Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
