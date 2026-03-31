import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../repositories/member_repository.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(memberDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Fees & Transactions'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(memberDashboardProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(memberDashboardProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Current Status Card matching Page 5
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: dashboardState.when(
                  data: (data) => data.feeStatus == 'paid' 
                      ? _NoDuesCard() 
                      : _DueStatusCard(
                          onPay: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              await ref.read(memberRepositoryProvider).recordPayment(7000.0, 'UPI');
                              Navigator.pop(context); // Close loading
                              ref.invalidate(memberDashboardProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Payment Successful!'))
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context); // Close loading
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Payment Failed: $e'))
                                );
                              }
                            }
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Text('Error: $e'),
                ),
              ),
              
              // Transaction History Section (Mocked for now as per controller status)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    const _TransactionCard(
                      category: 'Basketball Training',
                      date: '15 Jan 2026',
                      amount: '7000.00',
                      method: 'UPI',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100), // Spacing for bottom
            ],
          ),
        ),
      ),
    );
  }
}

class _DueStatusCard extends StatelessWidget {
  final VoidCallback onPay;
  const _DueStatusCard({required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Membership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Quarterly Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('DUE', style: TextStyle(color: AppColors.alert, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text('₹ 7000.00', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Due Date: 15 Apr 2026', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDuesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: 24),
          const Text('No Dues Left', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Your fees are up to date. Keep training!', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String category;
  final String date;
  final String amount;
  final String method;

  const _TransactionCard({
    required this.category,
    required this.date,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$date • $method', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹ $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.download_for_offline_outlined, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Receipt', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
