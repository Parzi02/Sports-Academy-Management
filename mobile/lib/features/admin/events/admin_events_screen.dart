import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../models/admin_models.dart';
import 'dart:convert';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(adminEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Admin Events'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(adminEventsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                'All', 'Ongoing', 'Upcoming', 'Past'
              ].map((filter) => _FilterChip(
                label: filter,
                isSelected: _selectedFilter == filter,
                onSelected: (val) => setState(() => _selectedFilter = filter),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Events List
          Expanded(
            child: eventsState.when(
              data: (events) {
                final filteredEvents = _filterEvents(events);
                if (filteredEvents.isEmpty) {
                  return const Center(child: Text('No events found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) => _AdminEventCard(event: filteredEvents[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/events/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<AdminEvent> _filterEvents(List<AdminEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedFilter) {
      case 'Ongoing':
        return events.where((e) {
          final eventDate = DateTime.parse(e.date);
          return eventDate.isAtSameMomentAs(today);
        }).toList();
      case 'Upcoming':
        return events.where((e) {
          final eventDate = DateTime.parse(e.date);
          return eventDate.isAfter(today);
        }).toList();
      case 'Past':
        return events.where((e) {
          final eventDate = DateTime.parse(e.date);
          return eventDate.isBefore(today);
        }).toList();
      default:
        return events;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  const _FilterChip({required this.label, required this.onSelected, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: Colors.white,
        selectedColor: AppColors.secondary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final AdminEvent event;
  const _AdminEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event.date);
    final formattedDate = DateFormat('MMM dd').format(eventDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: event.imageBase64 != null && event.imageBase64!.isNotEmpty
                ? Image.memory(
                    base64Decode(event.imageBase64!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    'https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=2070&auto=format&fit=crop',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('$formattedDate • ${event.startTime} • ${event.venue}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.alert), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

