import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../products/providers/cart_provider.dart';

class MemberShellScreen extends ConsumerWidget {
  final Widget child;
  const MemberShellScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/member/attendance')) return 1;
    if (location.startsWith('/member/events')) return 2;
    if (location.startsWith('/member/fees')) return 3;
    if (location.startsWith('/member/products') || location.startsWith('/member/cart')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/member'); break;
      case 1: context.go('/member/attendance'); break;
      case 2: context.go('/member/events'); break;
      case 3: context.go('/member/fees'); break;
      case 4: context.go('/member/products'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _getSelectedIndex(context);
    final location = GoRouterState.of(context).uri.path;
    final isCartPage = location == '/member/cart';

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: isCartPage ? null : SafeArea(
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
                _buildNavItem(context, activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Attendance', index: 1, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.vignette, inactiveIcon: Icons.vignette_outlined, label: 'Events', index: 2, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.savings, inactiveIcon: Icons.savings_outlined, label: 'Fee', index: 3, currentIndex: currentIndex),
                _buildNavItem(context, activeIcon: Icons.shopping_bag, inactiveIcon: Icons.shopping_bag_outlined, label: 'Shop', index: 4, currentIndex: currentIndex),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: (ref.watch(cartProvider).isNotEmpty && !isCartPage)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 0.5),
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => context.push('/member/cart'),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${ref.watch(cartProvider).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData activeIcon, required IconData inactiveIcon, required String label, required int index, required int currentIndex}) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index, context),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const SizedBox(height: 4),
              Text(
                label, 
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary, 
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
