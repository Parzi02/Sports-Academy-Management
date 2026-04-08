import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdminShellScreen extends StatelessWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/members')) return 1;
    if (location.startsWith('/admin/attendance')) return 2;
    if (location.startsWith('/admin/events')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/admin'); break;
      case 1: context.go('/admin/members'); break;
      case 2: context.go('/admin/attendance'); break;
      case 3: context.go('/admin/events'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getSelectedIndex(context);
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Light pill background
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, activeIcon: Icons.home, inactiveIcon: Icons.home_outlined, label: 'Home', index: 0, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.group, inactiveIcon: Icons.group_outlined, label: 'Members', index: 1, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Attendance', index: 2, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.insights, inactiveIcon: Icons.insights_outlined, label: 'Events', index: 3, currentIndex: currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData activeIcon, required IconData inactiveIcon, required String label, required int index, required int currentIndex}) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary, 
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
            )),
          ],
        ),
      ),
    );
  }
}
