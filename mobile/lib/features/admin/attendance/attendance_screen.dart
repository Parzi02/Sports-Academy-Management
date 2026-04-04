import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../repositories/admin_repository.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final selectedBatchId = ref.watch(selectedAttendanceBatchIdProvider);
    final searchQuery = ref.watch(attendanceSearchQueryProvider).toLowerCase();
    final statusFilter = ref.watch(attendanceStatusFilterProvider);
    
    final batchesState = ref.watch(adminBatchesProvider);
    final attendanceState = ref.watch(attendanceListProvider);

    // Filter logic
    final filteredMembers = attendanceState.when(
      data: (members) => members.where((m) {
        final matchesSearch = m.name.toLowerCase().contains(searchQuery) || m.memberId.contains(searchQuery);
        final matchesStatus = statusFilter == 'All' || 
                             (statusFilter == 'Present' && m.status == 'present') ||
                             (statusFilter == 'Absent' && m.status == 'absent') ||
                             (statusFilter == 'Pending' && m.status == 'pending');
        return matchesSearch && matchesStatus;
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );

    // Initialize first batch if none selected
    batchesState.whenData((batches) {
      if (selectedBatchId == null && batches.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedAttendanceBatchIdProvider.notifier).state = batches.first.id;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              onChanged: (val) => ref.read(attendanceSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search member',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. Filter Row (Date, Batch, Status)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Date Picker
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) ref.read(selectedAttendanceDateProvider.notifier).state = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd-MM-yyyy').format(selectedDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Batch Dropdown
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: batchesState.when(
                        data: (batches) => DropdownButton<String>(
                          value: selectedBatchId,
                          isExpanded: true,
                          hint: const Text('Batch', style: TextStyle(fontSize: 12)),
                          items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => ref.read(selectedAttendanceBatchIdProvider.notifier).state = val,
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // All Filter
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: statusFilter,
                        isExpanded: true,
                        items: ['All', 'Present', 'Absent', 'Pending'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => ref.read(attendanceStatusFilterProvider.notifier).state = val!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Batch Summary Row with Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: batchesState.maybeWhen(
              data: (batches) {
                final batch = batches.firstWhere((b) => b.id == selectedBatchId, orElse: () => batches.isNotEmpty ? batches.first : batches.first);
                final marked = attendanceState.maybeWhen(data: (m) => m.where((x) => x.status != 'pending').length, orElse: () => 0);
                final total = attendanceState.maybeWhen(data: (m) => m.length, orElse: () => 0);
                final progress = total > 0 ? marked / total : 0.0;
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        Text('Time ${batch.startTime} - ${batch.endTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('${marked.toString().padLeft(2, '0')}/${total.toString().padLeft(2, '0')} Marked', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox(height: 20),
            ),
          ),


          // 4. Member List
          Expanded(
            child: attendanceState.when(
              data: (_) => ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: filteredMembers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surface,
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/100?u=member'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(member.memberId, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        // Absent Button
                        _StatusButton(
                          label: 'A',
                          isActive: member.status == 'absent',
                          color: const Color(0xFFC62828), // Dark Red
                          onTap: () => ref.read(attendanceListProvider.notifier).updateStatus(member.id, 'absent'),
                        ),
                        const SizedBox(width: 12),
                        // Present Button
                        _StatusButton(
                          label: 'P',
                          isActive: member.status == 'present',
                          color: const Color(0xFF2E7D32), // Dark Green
                          onTap: () => ref.read(attendanceListProvider.notifier).updateStatus(member.id, 'present'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),

          // 5. Submit Button (matches screenshot logic)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: selectedBatchId == null ? null : () async {
                final members = ref.read(attendanceListProvider).value ?? [];
                final list = members.where((m) => m.status != 'pending').map((m) => {
                  'memberId': m.id,
                  'status': m.status,
                }).toList();
                
                if (list.isEmpty) return;

                try {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.markAttendance(
                    batchId: selectedBatchId,
                    date: DateFormat('yyyy-MM-dd').format(selectedDate),
                    attendanceList: list,
                  );
                  ref.invalidate(adminMarkedDaysProvider);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SUBMIT ATTENDANCE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
