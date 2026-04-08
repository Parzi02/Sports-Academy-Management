import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_providers.dart';
import '../models/admin_models.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(adminProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Profile', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: profileState.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _showEditProfile(context, profile),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.surface,
                        backgroundImage: profile.profilePhotoBase64 != null && profile.profilePhotoBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(profile.profilePhotoBase64!))
                            : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
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
              _ProfileItem(label: 'Email Address', value: profile.email.isNotEmpty ? profile.email : 'Not Provided', icon: Icons.email_outlined),
              _ProfileItem(label: 'Phone Number', value: profile.phone, icon: Icons.phone_outlined),
              _ProfileItem(label: 'Branch', value: profile.branchName, icon: Icons.location_on_outlined),
              _ProfileItem(label: 'Address', value: profile.address.isNotEmpty ? profile.address : 'Not Provided', icon: Icons.home_work_outlined),
              const SizedBox(height: 48),
              ListTile(
                onTap: () {},
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Account Settings'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: () {},
                leading: const Icon(Icons.security_outlined),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
                child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AdminProfileData profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditAdminProfileSheet(profile: profile),
    );
  }
}

class _EditAdminProfileSheet extends ConsumerStatefulWidget {
  final AdminProfileData profile;
  const _EditAdminProfileSheet({required this.profile});

  @override
  ConsumerState<_EditAdminProfileSheet> createState() => _EditAdminProfileSheetState();
}

class _EditAdminProfileSheetState extends ConsumerState<_EditAdminProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _imageFile;
  String? _profilePhotoBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _profilePhotoBase64 = widget.profile.profilePhotoBase64;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 80);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageFile = file;
        _profilePhotoBase64 = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
              const SizedBox(height: 32),
              
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.surface,
                        backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) 
                          : (_profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(_profilePhotoBase64!))
                              : const AssetImage('assets/images/default_avatar.jpg')) as ImageProvider?,
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 16),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                      return;
                    }

                    try {
                      await ref.read(adminProfileProvider.notifier).updateProfile({
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'phone': _phoneController.text,
                        'address': _addressController.text,
                        'profile_photo_base64': _profilePhotoBase64,
                      });
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                    }
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
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
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
