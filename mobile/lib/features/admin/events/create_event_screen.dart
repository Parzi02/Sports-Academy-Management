import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../repositories/admin_repository.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _feeController = TextEditingController(text: '0');
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  String? _selectedCategory;
  String _sportCategory = 'General';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Event', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormLabel('TITLE'),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'e.g. Annual Sport Day')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FormLabel('DATE'),
                      InkWell(
                        onTap: () async {
                           final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2025));
                           if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                               const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FormLabel('CATEGORY'),
                      DropdownButtonFormField<String>(
                        isDense: true,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.zero),
                        items: ['Upcoming', 'Registration Open', 'Ongoing'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        hint: const Text('Select'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _FormLabel('VENUE'),
            TextField(controller: _venueController, decoration: const InputDecoration(hintText: 'e.g. Ground A, Koramangala')),
            const SizedBox(height: 24),
            const _FormLabel('SPORT'),
             DropdownButtonFormField<String>(
               value: _sportCategory,
                        isDense: true,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.zero),
                        items: ['Football', 'Cricket', 'Basketball', 'Tennis', 'General'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _sportCategory = v!),
                      ),
            const SizedBox(height: 24),
            const _FormLabel('DESCRIPTION'),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'About this event...')),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitEvent,
                child: const Text('PUBLISH EVENT'),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEvent() async {
    if (_titleController.text.isEmpty || _selectedCategory == null) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.createEvent({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'sport_category': _sportCategory,
        'event_category': _selectedCategory,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time': '09:00:00', // Default placeholder
        'end_time': '17:00:00',   // Default placeholder
        'venue': _venueController.text,
        'image_base64': null, // Next phase
      });

      // Invalidate dashboard stats and events list
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully')));
        context.pop();
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
    }
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 11, letterSpacing: 1.1)),
    );
  }
}
