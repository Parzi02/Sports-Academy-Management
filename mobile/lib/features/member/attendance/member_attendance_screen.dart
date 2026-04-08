import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';

class MemberAttendanceScreen extends ConsumerStatefulWidget {
  const MemberAttendanceScreen({super.key});

  @override
  ConsumerState<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends ConsumerState<MemberAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

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

              // 2. Date Indicator: Calendar Picker
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final logs = attendanceState.value ?? [];
                          final DateTime? picked = await showDialog<DateTime>(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _CalendarWidget(
                                    initialDate: _selectedDate,
                                    logs: logs,
                                  ),
                                ),
                              );
                            },
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.surface, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM, yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Weekly Calendar Strip: Mon-Sun capsule shapes
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(7, (index) {
                        final baseDate = _selectedDate;
                        final firstDayOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1));
                        final date = firstDayOfWeek.add(Duration(days: index));
                        final isSelected = date.day == baseDate.day && date.month == baseDate.month && date.year == baseDate.year;

                        return Expanded(
                          child: Container(
                            height: 75,
                            margin: EdgeInsets.only(right: index == 6 ? 0 : 6),
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
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
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

class _CalendarWidget extends StatefulWidget {
  final DateTime initialDate;
  final List<MemberAttendanceLog> logs;

  const _CalendarWidget({required this.initialDate, required this.logs});

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            Navigator.of(context).pop(selectedDay);
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(10),
            selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              MemberAttendanceLog? matchLog;
              for (var log in widget.logs) {
                try {
                  final logDate = DateTime.parse(log.date);
                  if (isSameDay(logDate, date)) {
                    matchLog = log;
                    break;
                  }
                } catch (_) {}
              }

              if (matchLog != null) {
                Color ringColor;
                if (matchLog.status == 'present') {
                  ringColor = AppColors.success;
                } else if (matchLog.status == 'absent') {
                  ringColor = AppColors.alert;
                } else {
                  return null;
                }

                return Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2.5),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
