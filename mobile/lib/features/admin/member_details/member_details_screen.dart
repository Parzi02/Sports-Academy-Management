import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
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
                      const _AttendanceTab(),
                      const _PaymentsTab(),
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

class _DetailsTab extends StatelessWidget {
  final AdminMemberProfile profile;
  const _DetailsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSection(title: 'Personal Info', items: [
            _InfoRow(label: 'Email', value: profile.email),
            _InfoRow(label: 'Date of Birth', value: profile.dob),
            _InfoRow(label: 'Gender', value: profile.gender),
            _InfoRow(label: 'Address', value: profile.address),
          ]),
          const SizedBox(height: 24),
          _InfoSection(title: 'Enrollment Info', items: [
            _InfoRow(label: 'Batch', value: profile.batchName == 'No Batch' ? 'No Batch' : '${profile.batchName} (${profile.batchTime})'),
            _InfoRow(label: 'Date of Joining', value: profile.dateOfJoining.isNotEmpty && profile.dateOfJoining.length >= 10 ? profile.dateOfJoining.substring(0, 10) : profile.dateOfJoining),
            _InfoRow(label: 'Status', value: profile.status.toUpperCase(), isBadge: true),
          ]),
          const SizedBox(height: 48),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('DELETE MEMBER'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 10,
      itemBuilder: (context, index) => _LogItem(
        title: '${24 - index} Feb 2024',
        subtitle: 'Morning Batch',
        status: index % 3 == 0 ? 'ABSENT' : 'PRESENT',
        color: index % 3 == 0 ? Colors.red : Colors.green,
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => _LogItem(
        title: 'Monthly Subscription',
        subtitle: 'Paid via G-Pay • 05 ${['Feb', 'Jan', 'Dec', 'Nov', 'Oct'][index]}',
        status: '₹500',
        color: AppColors.primary,
        isBoldStatus: true,
      ),
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
  const _InfoRow({required this.label, required this.value, this.isBadge = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(value, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
            )
          else
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
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
