import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EventDetailScreen extends StatelessWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image with Back Button
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.arrow_back, color: Colors.black)),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=2090&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.favorite_border, color: Colors.red)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              
              // Event Details
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('BASKETBALL', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const Text('FREE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('U16 Basketball Regional Playoffs 2026', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                      const SizedBox(height: 24),
                      
                      // Venue and Date
                      _InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: 'Sunday, 2 Feb 2026'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.access_time, label: 'Time', value: '09:00 AM - 05:00 PM'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: 'Ground A, Koramangala Branch'),
                      
                      const Divider(height: 48),
                      
                      Text('About Event', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      const Text(
                        'Join the regional playoffs for the U16 basketball tournament. This event is open to all registered members of the academy. Top teams will qualify for the state level championship.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text('Eligibility', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          _EligibilityItem(label: 'Age', value: '14-16 yrs'),
                          SizedBox(width: 16),
                          _EligibilityItem(label: 'Gender', value: 'Both'),
                          SizedBox(width: 16),
                          _EligibilityItem(label: 'Team', value: '5 + 3'),
                        ],
                      ),
                      
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Fixed Bottom Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('REGISTER NOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _EligibilityItem extends StatelessWidget {
  final String label;
  final String value;
  const _EligibilityItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
