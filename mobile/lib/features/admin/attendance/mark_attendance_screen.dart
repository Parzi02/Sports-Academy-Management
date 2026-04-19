import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../models/admin_models.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final Map<String, String> _attendanceMap = {}; // memberId -> 'present'/'absent'

  @override
  Widget build(BuildContext context) {
    final batchesState = ref.watch(adminBatchesProvider);
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final selectedBatchId = ref.watch(selectedAttendanceBatchIdProvider);
    final attendanceState = ref.watch(attendanceListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mark Attendance', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with Selectors
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _Selector(
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy').format(selectedDate),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            ref.read(selectedAttendanceDateProvider.notifier).state = picked;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: batchesState.when(
                        data: (batches) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Batch', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedBatchId,
                                  isExpanded: true,
                                  hint: const Text('Select', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  items: batches.map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(selectedAttendanceBatchIdProvider.notifier).state = val;
                                    }
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error: $e'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // List of Members from selected batch
              Expanded(
                child: attendanceState.when(
                  data: (members) {
                    if (selectedBatchId == null) {
                      return const Center(child: Text('Please select a batch first'));
                    }
                    if (members.isEmpty) {
                      return const Center(child: Text('No members found in this batch assigned to you'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 180),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        // Initialize local map if needed OR just use a specialized notifier.
                        // For simplicity, we'll keep local map but syncing it back.
                        return _MemberAttendanceItem(
                          member: member,
                          status: _attendanceMap[member.id] ?? member.status,
                          onStatusChanged: (status) {
                            setState(() {
                              _attendanceMap[member.id] = status;
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),

          // Submit Button positioned 2px above navigation bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 124, // 4px above the navigation pill (Shell uses ~120px bottom zone)
            child: SizedBox(
               height: 56,
               width: double.infinity,
               child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                onPressed: selectedBatchId == null || _attendanceMap.isEmpty ? null : () => _saveAttendance(selectedBatchId),
                child: const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchPicker(BuildContext context, List<AdminBatch> batches) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 40),
        children: batches.map((b) => ListTile(
          title: Text(b.name),
          subtitle: Text(b.sport),
          onTap: () {
            ref.read(selectedAttendanceBatchIdProvider.notifier).state = b.id;
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Future<void> _saveAttendance(String batchId) async {
    try {
      final List<Map<String, dynamic>> attendanceList = _attendanceMap.entries.map((e) => {
        'memberId': e.key,
        'status': e.value,
      }).toList();

      await ref.read(adminMarkAttendanceProvider).markAttendance(
        batchId: batchId,
        date: DateFormat('yyyy-MM-dd').format(ref.read(selectedAttendanceDateProvider)),
        attendanceList: attendanceList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully')));
        context.pop();
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save attendance: $e')));
    }
  }
}

class _Selector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _Selector({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberAttendanceItem extends StatelessWidget {
  final AttendanceMember member;
  final String? status;
  final Function(String) onStatusChanged;

  const _MemberAttendanceItem({
    required this.member,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=member')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(member.memberId, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _StatusButton(
                label: 'A',
                color: Colors.red,
                isSelected: status == 'absent',
                onTap: () => onStatusChanged('absent'),
              ),
              const SizedBox(width: 8),
              _StatusButton(
                label: 'P',
                color: Colors.green,
                isSelected: status == 'present',
                onTap: () => onStatusChanged('present'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
