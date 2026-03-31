import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';

class MemberAttendanceScreen extends ConsumerStatefulWidget {
  const MemberAttendanceScreen({super.key});

  @override
  ConsumerState<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends ConsumerState<MemberAttendanceScreen> {
  final DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(memberAttendanceProvider);
    final dashboardState = ref.watch(memberDashboardProvider);
    final profileState = ref.watch(memberProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberAttendanceProvider);
            ref.invalidate(memberDashboardProvider);
            ref.invalidate(memberProfileProvider);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Header: "My Attendance" + Icons
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Attendance',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          _CircularIcon(icon: Icons.notifications_none, color: AppColors.primary.withOpacity(0.1)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.push('/member/profile'),
                            child: profileState.when(
                              data: (profile) => CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.surface,
                                backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                                    ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                                    : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                              ),
                              loading: () => const CircleAvatar(radius: 20, backgroundColor: AppColors.surface),
                              error: (_, __) => const CircleAvatar(radius: 20, backgroundColor: AppColors.surface, child: Icon(Icons.person, color: AppColors.primary)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Date Indicator: Calendar Icon + February, 2026
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Weekly Calendar Strip: Mon-Sun capsule shapes
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final now = DateTime.now();
                        final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
                        final date = firstDayOfWeek.add(Duration(days: index));
                        final isSelected = date.day == now.day && date.month == now.month;

                        return Container(
                          width: 55,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 4. Monthly Summary Card: sessions attended + progress bar
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: dashboardState.when(
                    data: (data) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary of ${DateFormat('MMMM').format(_selectedDate)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${data.attendedSessions} / ${data.totalSessions} ',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const TextSpan(
                                      text: 'sessions attended',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${data.attendancePercentage}%',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (data.totalSessions > 0) ? (data.attendedSessions / data.totalSessions) : 0,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Text('Error: $e'),
                  ),
                ),
              ),

              // 5. Attendance Session List: Football/Batch header + items
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surface),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // Group Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dashboardState.value?.batchName ?? 'Class Training',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text(
                                'Coach: Assigned',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Log Items
                        attendanceState.when(
                          data: (logs) {
                            if (logs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('No attendance records found', style: TextStyle(color: AppColors.textSecondary)),
                              );
                            }
                            return Column(
                              children: [
                                for (int i = 0; i < logs.length; i++) ...[
                                  _AttendanceListTile(log: logs[i], batchTime: dashboardState.value?.batchTime ?? '-- : --'),
                                  if (i < logs.length - 1) const Divider(height: 1, indent: 20, endIndent: 20),
                                ],
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, __) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CircularIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _AttendanceListTile extends StatelessWidget {
  final MemberAttendanceLog log;
  final String batchTime;
  const _AttendanceListTile({required this.log, required this.batchTime});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(log.date);
    
    Widget statusWidget;
    switch (log.status) {
      case 'present':
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Present', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.success)),
          ],
        );
        break;
      case 'absent':
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel, color: AppColors.alert, size: 22),
            SizedBox(width: 8),
            Text('Absent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.alert)),
          ],
        );
        break;
      default:
        statusWidget = const Text('Update Pending', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, dd MMM').format(date),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(batchTime, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          statusWidget,
        ],
      ),
    );
  }
}

