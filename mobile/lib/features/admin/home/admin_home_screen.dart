import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final profileState = ref.watch(adminProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: GestureDetector(
                onTap: () => context.push('/admin/profile'),
                child: profileState.maybeWhen(
                  data: (profile) => CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                        ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                        : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                  ),
                  orElse: () => const CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: AssetImage('assets/images/default_avatar.jpg'),
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(ref.watch(authStateProvider).value?.name ?? 'Coach', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Dashboard', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 24, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary), 
                onPressed: () {}
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          dashboardState.when(
            data: (stats) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Members',
                            value: stats.totalMembers.toString(),
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Events',
                            value: stats.totalEvents.toString(),
                            icon: Icons.event_available,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _QuickActionRow(
                      actions: [
                        _QuickAction(
                          label: 'Attendance', 
                          icon: Icons.fact_check_outlined, 
                          color: Colors.blue,
                          onTap: () => context.push('/admin/attendance/mark'),
                        ),
                        _QuickAction(
                          label: 'Payments', 
                          icon: Icons.payments_outlined, 
                          color: Colors.green,
                          onTap: () => context.push('/admin/payments/pending'), 
                        ),
                        _QuickAction(
                          label: 'Create Event', 
                          icon: Icons.campaign_outlined, 
                          color: Colors.orange,
                          onTap: () => context.push('/admin/events/create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
