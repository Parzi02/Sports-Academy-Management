import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';
import '../repositories/admin_repository.dart';

class PaymentVerificationScreen extends ConsumerWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingState = ref.watch(adminPendingPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pending Payments'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(adminPendingPaymentsProvider),
          ),
        ],
      ),
      body: pendingState.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No pending verifications.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final pay = payments[index];
              return _VerificationCard(payment: pay);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error loading payments: $e')),
      ),
    );
  }
}

class _VerificationCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> payment;

  const _VerificationCard({required this.payment});

  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  bool _isProcessing = false;

  void _showScreenshot() {
    final base64String = widget.payment['screenshot_base64'];
    if (base64String == null || base64String.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No screenshot available.')));
      return;
    }

    try {
      final bytes = base64Decode(base64String);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes, fit: BoxFit.contain),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: const Text('Close Details'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not decode image: $e')));
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(adminRepositoryProvider).updatePaymentStatus(widget.payment['id'].toString(), status);
      ref.invalidate(adminPendingPaymentsProvider);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment $status successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(widget.payment['created_at']).toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.payment['member_name'], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('SID: ${widget.payment['member_sid'] ?? 'N/A'} • ${widget.payment['member_phone']}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.payment['plan_type'].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('₹ ${widget.payment['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('UTR Number', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(widget.payment['utr_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Submitted: $dateStr', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showScreenshot,
                      icon: const Icon(Icons.image, size: 18),
                      label: const Text('View Proof'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _updateStatus('failed'),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                  IconButton(
                    onPressed: () => _updateStatus('success'),
                    icon: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                    tooltip: 'Approve',
                  ),

                ],
              ),
          ],
        ),
      ),
    );
  }
}
