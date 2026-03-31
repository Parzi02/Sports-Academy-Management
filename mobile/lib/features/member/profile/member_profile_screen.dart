import 'package:flutter/material.dart';
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
          child: Column(
            children: [
              // Header with Member ID
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60, 
                          backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                              : const AssetImage('assets/images/default_avatar_gray.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MemberEditProfileScreen(profile: profile)),
                            ),
                            child: const CircleAvatar(backgroundColor: AppColors.primary, radius: 18, child: Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: Text('Member ID: ${profile.memberId}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              
              // Details Sections
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'Personal Details'),
                    _ProfileInfoRow(label: 'Phone Number', value: profile.phone),
                    _ProfileInfoRow(label: 'Email', value: profile.email ?? 'Not provided'),
                    _ProfileInfoRow(label: 'Date of Birth', value: formatDate(profile.dob)),
                    _ProfileInfoRow(label: 'Gender', value: profile.gender ?? 'Not provided'),
                    _ProfileInfoRow(label: 'Address', value: profile.address ?? 'Not provided'),
                    _ProfileInfoRow(label: 'Date of Joining', value: formatDate(profile.dateOfJoining)),
                    
                    const SizedBox(height: 32),
                    
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
                    
                    const SizedBox(height: 48),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authStateProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout, color: AppColors.alert),
                        label: const Text('LOGOUT', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.alert),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const Divider(),
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
