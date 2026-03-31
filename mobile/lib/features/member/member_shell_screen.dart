import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class MemberShellScreen extends StatelessWidget {
  final Widget child;
  const MemberShellScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/member/attendance')) return 1;
    if (location.startsWith('/member/events')) return 2;
    if (location.startsWith('/member/fees')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/member'); break;
      case 1: context.go('/member/attendance'); break;
      case 2: context.go('/member/events'); break;
      case 3: context.go('/member/fees'); break;
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
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.vignette_outlined), activeIcon: Icon(Icons.vignette), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), activeIcon: Icon(Icons.savings), label: 'Fee'),
        ],
      ),
    );
  }
}
