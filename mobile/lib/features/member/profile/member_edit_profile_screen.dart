import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';

class MemberEditProfileScreen extends ConsumerStatefulWidget {
  final MemberProfile profile;
  const MemberEditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<MemberEditProfileScreen> createState() => _MemberEditProfileScreenState();
}

class _MemberEditProfileScreenState extends ConsumerState<MemberEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _profilePhotoBase64;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _profilePhotoBase64 = widget.profile.profilePhotoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageFile = file;
        _profilePhotoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memberProfileActionsProvider).updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        profilePhotoBase64: _profilePhotoBase64,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: AppColors.alert),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.surface,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty
                                  ? MemoryImage(base64Decode(_profilePhotoBase64!))
                                  : const AssetImage('assets/images/default_avatar_gray.png')) as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 18,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  _buildTextField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (val) => val!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) => val!.isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Address Field
                  _buildTextField(
                    label: 'Address',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    validator: (val) => val!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
