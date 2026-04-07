import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../models/admin_models.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(adminMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Member Directory'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(adminMembersProvider.notifier).fetchMembers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => ref.read(adminMembersProvider.notifier).updateSearch(value),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // Members Grid/List
          Expanded(
            child: membersState.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members found'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) => _MemberCard(member: members[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMember(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD MEMBER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddMember(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddMemberSheet(),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final AdminMember member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/members/${member.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: member.profilePhotoBase64 != null && member.profilePhotoBase64!.isNotEmpty
                  ? MemoryImage(base64Decode(member.profilePhotoBase64!))
                  : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
            ),
            const SizedBox(height: 12),
            Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(member.memberId, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet();

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDob;
  String? _selectedBatchId;
  String? _selectedMembershipType;
  String? _selectedGender;
  String? _profilePhotoBase64;
  File? _imageFile;

  final List<String> _membershipTypes = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // Default to 10 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
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
    final batchesState = ref.watch(adminBatchesProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Register Member', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
              const SizedBox(height: 32),
              
              // Profile Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? const Icon(Icons.camera_alt, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Add Photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              const SizedBox(height: 24),

              const _FormSection(title: 'Personal Info'),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  child: Text(
                    _selectedDob == null ? 'Select Date' : '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: _selectedDob == null ? AppColors.textSecondary : AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 16),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 32),
              
              const _FormSection(title: 'Training Details'),
              
              batchesState.when(
                data: (batches) => DropdownButtonFormField<String>(
                  value: _selectedBatchId,
                  decoration: const InputDecoration(labelText: 'Select Batch'),
                  items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.sport})'))).toList(),
                  onChanged: (val) => setState(() => _selectedBatchId = val),
                  isExpanded: true,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading batches: $e'),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedMembershipType,
                decoration: const InputDecoration(labelText: 'Membership Type'),
                items: _membershipTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => _selectedMembershipType = val),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty || _selectedBatchId == null || _selectedMembershipType == null || _selectedDob == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                       return;
                    }
                    
                    try {
                      final dobString = '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
                      await ref.read(adminMembersProvider.notifier).addMember({
                        'name': _nameController.text,
                        'phone': _phoneController.text,
                        'email': _emailController.text,
                        'dob': dobString,
                        'gender': _selectedGender?.toLowerCase() ?? 'other',
                        'address': _addressController.text,
                        'batch_id': _selectedBatchId,
                        'membership_type': _selectedMembershipType,
                        'profile_photo_base64': _profilePhotoBase64,
                      });


                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add member: $e')));
                    }
                  },
                  child: const Text('ENROLL MEMBER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  const _FormSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
