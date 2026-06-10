import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';
import 'dart:convert';
import 'member_edit_profile_screen.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(memberProfileProvider);
    final dashboardState = ref.watch(memberDashboardProvider);

    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'Not provided';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        return dateStr;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          profileState.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MemberEditProfileScreen(profile: profile)),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: () => ref.invalidate(memberProfileProvider)),
        ],
      ),
      body: profileState.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MemberEditProfileScreen(profile: profile)),
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.surface,
                        backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                            : const AssetImage('assets/images/default_avatar_gray.png') as ImageProvider,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 18,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Tap to Edit Profile', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              const SizedBox(height: 32),
              
              _ProfileItem(label: 'Full Name', value: profile.name, icon: Icons.person_outline),
              _ProfileItem(label: 'Email Address', value: profile.email?.isNotEmpty == true ? profile.email! : 'Not Provided', icon: Icons.email_outlined),
              _ProfileItem(label: 'Phone Number', value: profile.phone, icon: Icons.phone_outlined),
              _ProfileItem(label: 'Date of Birth', value: formatDate(profile.dob), icon: Icons.calendar_today_outlined),
              _ProfileItem(label: 'Gender', value: profile.gender?.isNotEmpty == true ? profile.gender! : 'Not Provided', icon: Icons.wc_outlined),
              _ProfileItem(label: 'Address', value: profile.address?.isNotEmpty == true ? profile.address! : 'Not Provided', icon: Icons.home_work_outlined),
              _ProfileItem(label: 'Date of Joining', value: formatDate(profile.dateOfJoining), icon: Icons.date_range_outlined),

              const SizedBox(height: 16),
              const _SectionHeader(title: 'Enrollment Details'),
              dashboardState.when(
                data: (data) => _EnrollmentCard(
                  sport: data.sport,
                  coach: data.coachName,
                  batchTime: data.batchTime,
                  membership: data.membershipType.toUpperCase(),
                  status: data.feeStatus.toUpperCase(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 32),
              ListTile(
                onTap: () => GoRouter.of(context).push('/member/orders'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('My Orders'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: () {},
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Account Settings'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: () {},
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security_outlined),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 48),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 120), // Added safety padding for the dynamic island nav bar
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final String sport, coach, batchTime, membership, status;
  const _EnrollmentCard({required this.sport, required this.coach, required this.batchTime, required this.membership, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPurple,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sport.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _EnrollmentInfoRow(icon: Icons.person_outline, label: 'Coach', value: coach),
          const SizedBox(height: 12),
          _EnrollmentInfoRow(icon: Icons.access_time, label: 'Batch', value: batchTime),
          const SizedBox(height: 12),
          _EnrollmentInfoRow(icon: Icons.card_membership_outlined, label: 'Membership', value: membership),
        ],
      ),
    );
  }
}

class _EnrollmentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _EnrollmentInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
