import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_camera_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';

// ...rest of the file until the end...

class _SelfAttendanceButton extends ConsumerStatefulWidget {
  const _SelfAttendanceButton();

  @override
  ConsumerState<_SelfAttendanceButton> createState() => _SelfAttendanceButtonState();
}

class _SelfAttendanceButtonState extends ConsumerState<_SelfAttendanceButton> {
  bool _isLoading = false;

  Future<void> _markAttendance() async {
    final File? pickedFile = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final file = pickedFile;
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      await ref.read(memberProfileActionsProvider).markSelfAttendance(base64Image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark attendance: $e'), backgroundColor: AppColors.alert),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(memberDashboardProvider);
    final isMarked = dashboardState.value?.isAttendanceMarkedToday ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Material(
        color: isMarked ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: (_isLoading || isMarked) ? null : _markAttendance,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: _isLoading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isMarked ? Icons.check_circle_outline : Icons.camera_alt_outlined, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isMarked ? "Attendance Marked" : "Mark Today's Attendance",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(memberDashboardProvider);
    final profileState = ref.watch(memberProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(memberDashboardProvider);
          ref.invalidate(memberProfileProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header matching wireframe
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: GestureDetector(
                  onTap: () => context.push('/member/profile'),
                  child: profileState.when(
                    data: (profile) => CircleAvatar(
                      backgroundColor: AppColors.surface,
                      backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                          ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                          : const AssetImage('assets/images/default_avatar_gray.png') as ImageProvider,
                    ),
                    loading: () => const CircleAvatar(backgroundColor: AppColors.surface, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const CircleAvatar(
                      backgroundImage: AssetImage('assets/images/default_avatar_gray.png'),
                    ),
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(profileState.value?.name ?? 'Member', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary), 
                  onPressed: () {}
                ),
              ],
            ),
            
            // Achievement Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: dashboardState.when(
                  data: (data) => Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Overall Progress',
                          value: '${data.attendancePercentage}%',
                          subLabel: 'Attendance',
                          icon: Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: data.feeStatus == 'paid' ? 'Paid' : 'Due',
                          value: data.feeStatus == 'paid' ? 'Up to Date' : 'Pending',
                          subLabel: 'Fee Status',
                          icon: data.feeStatus == 'paid' ? Icons.verified_outlined : Icons.info_outline,
                          color: data.feeStatus == 'paid' ? AppColors.success : AppColors.alert,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Text('Error: $e'),
                ),
              ),
            ),
            
            // Self Attendance Section
            const SliverToBoxAdapter(
              child: _SelfAttendanceButton(),
            ),
            
            // Today's Schedule Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: () => context.go('/member/attendance'), child: const Text('View All')),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: dashboardState.when(
                  data: (data) {
                    final schedules = data.todaySchedule ?? [];
                    if (schedules.isEmpty) {
                      return const Center(child: Text('No sessions today'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: schedules.length,
                      itemBuilder: (context, index) => _ScheduleCard(schedule: schedules[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label, 
    required this.value, 
    required this.subLabel,
    required this.icon, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final TodaySchedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPurple,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ONGOING BATCH', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(schedule.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(schedule.coach, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('${schedule.startTime} - ${schedule.endTime}', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(schedule.venue, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
