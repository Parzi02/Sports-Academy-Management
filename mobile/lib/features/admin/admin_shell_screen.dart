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
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), activeIcon: Icon(Icons.insights), label: 'Events'),
        ],
      ),
    );
  }
}
