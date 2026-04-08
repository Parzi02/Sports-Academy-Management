import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../models/member_models.dart';
import '../repositories/member_repository.dart';
import 'dart:convert';

class MemberEventsScreen extends ConsumerStatefulWidget {
  const MemberEventsScreen({super.key});

  @override
  ConsumerState<MemberEventsScreen> createState() => _MemberEventsScreenState();
}

class _MemberEventsScreenState extends ConsumerState<MemberEventsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(memberEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Academy Events'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(memberEventsProvider),
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
                'All', 'Ongoing', 'Upcoming', 'My Favourites'
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
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) => _EventCard(event: filteredEvents[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<MemberEvent> _filterEvents(List<MemberEvent> events) {
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
      case 'My Favourites':
        return events.where((e) => e.isFavourite).toList();
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

class _EventCard extends ConsumerWidget {
  final MemberEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventDate = DateTime.parse(event.date);
    final formattedDate = DateFormat('MMM dd').format(eventDate);

    return GestureDetector(
      onTap: () => context.push('/member/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: event.imageBase64 != null && event.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(event.imageBase64!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=2090&auto=format&fit=crop',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: Icon(
                      event.isFavourite ? Icons.favorite : Icons.favorite_border, 
                      color: event.isFavourite ? Colors.red : AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      await ref.read(memberRepositoryProvider).toggleFavourite(event.id);
                      ref.invalidate(memberEventsProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const Text('FREE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('$formattedDate • ${event.date.contains('T') ? DateFormat('hh:mm a').format(eventDate) : 'TBD'}', style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/member/events/${event.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('REGISTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
