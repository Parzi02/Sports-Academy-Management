import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../providers/coach_orders_provider.dart';

class CoachOrdersScreen extends ConsumerWidget {
  const CoachOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(coachOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Member Orders', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load orders: $err'),
              TextButton(
                onPressed: () => ref.read(coachOrdersProvider.notifier).fetchOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders found for your members.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(coachOrdersProvider.notifier).fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(24).copyWith(bottom: 120),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, ref, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final bool isCompleted = order['status'] == 'completed';
    final List<dynamic> items = order['items'] ?? [];
    final double totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    
    // Parse Date safely
    String dateStr = '';
    if (order['created_at'] != null) {
      try {
        final date = DateTime.parse(order['created_at']);
        dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
      } catch (e) {
        dateStr = 'Unknown date';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
                    Text(
                      order['member_name'] ?? 'Unknown Member',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${order['member_roll'] ?? 'N/A'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['quantity']}x ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Expanded(
                    child: Text(item['name'] ?? 'Item ${item['productId']}', style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  Text('₹${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            );
          }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                ],
              ),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(coachOrdersProvider.notifier).updateOrderStatus(order['id'], 'completed');
                      if (context.mounted) ToastUtils.showTopToast(context, 'Order marked as completed');
                    } catch (e) {
                      if (context.mounted) ToastUtils.showTopToast(context, 'Failed to update order');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Mark Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
