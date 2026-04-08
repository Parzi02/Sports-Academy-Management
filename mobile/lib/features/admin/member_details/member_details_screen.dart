import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../repositories/admin_repository.dart';
import '../providers/admin_providers.dart';
import '../models/admin_models.dart';

class MemberDetailsScreen extends ConsumerWidget {
  final String id;
  const MemberDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(adminMemberProfileProvider(id));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Profile', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: profileState.when(
          data: (profile) => Column(
            children: [
              const SizedBox(height: 24),
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                          ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                          : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(profile.name, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ContactIcon(icon: Icons.call, color: AppColors.primary),
                        const SizedBox(width: 16),
                        _ContactIcon(icon: Icons.email, color: AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Tab Bar
              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Payments'),
                ],
              ),
              // Tab View
              Expanded(
                child: Container(
                  color: AppColors.surface,
                  child: TabBarView(
                    children: [
                      _DetailsTab(profile: profile),
                      _AttendanceTab(attendance: profile.attendance),
                      _PaymentsTab(payments: profile.payments),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ContactIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _DetailsTab extends StatefulWidget {
  final AdminMemberProfile profile;
  const _DetailsTab({required this.profile});

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  bool _isPaying = false;

  Future<void> _recordCashPayment(WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cash Payment'),
        content: Text('Are you sure you want to record a cash payment of ₹${widget.profile.amountDue} for the ${widget.profile.membershipType} plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isPaying = true);
      try {
        await ref.read(adminRepositoryProvider).recordCashPayment(
          memberId: widget.profile.id,
          amount: widget.profile.amountDue,
          planType: widget.profile.membershipType,
        );
        ref.invalidate(adminMemberProfileProvider(widget.profile.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cash payment recorded successfully!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error recording payment: $e'), backgroundColor: AppColors.alert),
          );
        }
      } finally {
        if (mounted) setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDue = widget.profile.status.toLowerCase() == 'due';

    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoSection(title: 'Personal Info', items: [
                _InfoRow(label: 'Email', value: widget.profile.email),
                _InfoRow(label: 'Date of Birth', value: widget.profile.dob),
                _InfoRow(label: 'Gender', value: widget.profile.gender),
                _InfoRow(label: 'Address', value: widget.profile.address),
              ]),
              const SizedBox(height: 24),
              _InfoSection(title: 'Enrollment Info', items: [
                _InfoRow(
                  label: 'Batch', 
                  value: widget.profile.batchName == 'No Batch' ? 'No Batch' : '${widget.profile.batchName} (${widget.profile.batchTime})',
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                    onPressed: () => _editBatch(ref),
                  ),
                ),
                _InfoRow(label: 'Date of Joining', value: widget.profile.dateOfJoining.isNotEmpty && widget.profile.dateOfJoining.length >= 10 ? widget.profile.dateOfJoining.substring(0, 10) : widget.profile.dateOfJoining),
                _InfoRow(label: 'Status', value: widget.profile.status.toUpperCase(), isBadge: true),
              ]),
              if (isDue) ...[
                const SizedBox(height: 24),
                _InfoSection(title: 'Payment Due', items: [
                  _InfoRow(
                    label: 'Plan', 
                    value: widget.profile.membershipType.toUpperCase(),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                      onPressed: () => _editPlan(ref),
                    ),
                  ),
                  _InfoRow(
                    label: 'Amount Due', 
                    value: '₹ ${widget.profile.amountDue.toStringAsFixed(0)}',
                    isBoldValue: true,
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPaying ? null : () => _recordCashPayment(ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isPaying 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('RECORD CASH PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('DELETE MEMBER'),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editBatch(WidgetRef ref) async {
    final batches = await ref.read(adminRepositoryProvider).getBatches();
    if (!mounted) return;

    final selectedBatch = await showDialog<AdminBatch>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final b = batches[index];
              return ListTile(
                title: Text(b.name),
                subtitle: Text('${b.sport} • ${b.startTime}'),
                onTap: () => Navigator.pop(context, b),
              );
            },
          ),
        ),
      ),
    );

    if (selectedBatch != null) {
      try {
        await ref.read(adminRepositoryProvider).updateMemberEnrollment(
          widget.profile.id,
          batchId: selectedBatch.id,
        );
        ref.invalidate(adminMemberProfileProvider(widget.profile.id));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editPlan(WidgetRef ref) async {
    final plans = ['Monthly', 'Quarterly', 'Yearly'];
    
    final selectedPlan = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Payment Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: plans.map((p) => ListTile(
            title: Text(p),
            onTap: () => Navigator.pop(context, p),
          )).toList(),
        ),
      ),
    );

    if (selectedPlan != null) {
      try {
        await ref.read(adminRepositoryProvider).updateMemberEnrollment(
          widget.profile.id,
          membershipType: selectedPlan,
        );
        ref.invalidate(adminMemberProfileProvider(widget.profile.id));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}



class _AttendanceTab extends StatelessWidget {
  final List<MemberAttendanceRecord> attendance;
  const _AttendanceTab({required this.attendance});

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final record = attendance[index];
        final isAbsent = record.status.toLowerCase() == 'absent';
        
        return _LogItem(
          title: record.date, // Already formatted as YYYY-MM-DD
          subtitle: record.batchName,
          status: record.status.toUpperCase(),
          color: isAbsent ? Colors.red : Colors.green,
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<MemberPaymentRecord> payments;
  const _PaymentsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(child: Text('No payment records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final isSuccess = payment.status.toLowerCase() == 'success';

        return _LogItem(

          title: '${payment.planType.toUpperCase()} Plan',
          subtitle: 'Status: ${payment.status.toUpperCase()} • ${payment.date}',
          status: '₹${payment.amount}',
          color: isSuccess ? AppColors.primary : Colors.orange,
          isBoldStatus: true,
        );

      },
    );
  }
}


class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBadge;
  final bool isBoldValue;
  final Widget? trailing;

  const _InfoRow({
    required this.label, 
    required this.value, 
    this.isBadge = false,
    this.isBoldValue = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(value, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              else
                Text(
                  value, 
                  style: TextStyle(
                    color: AppColors.textPrimary, 
                    fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                  )
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}



class _LogItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final bool isBoldStatus;

  const _LogItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    this.isBoldStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: isBoldStatus ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
