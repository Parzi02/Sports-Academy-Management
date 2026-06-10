import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

// Provider to fetch member orders
final memberOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/orders/member');
  return response.data as List<dynamic>;
});

class MemberOrdersScreen extends ConsumerWidget {
  const MemberOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(memberOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.', style: TextStyle(color: AppColors.textSecondary)));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(memberOrdersProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.alert, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load orders', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(err.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(memberOrdersProvider),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(order['created_at']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final totalAmount = double.parse(order['total_amount'].toString());
    
    final items = order['items'] as List<dynamic>? ?? [];
    
    // Status colors
    final paymentStatus = order['status'] as String? ?? 'pending';
    final isPaymentSuccess = paymentStatus.toLowerCase() == 'success';
    final paymentColor = isPaymentSuccess ? AppColors.success : (paymentStatus.toLowerCase() == 'failed' ? AppColors.alert : Colors.orange);
    
    final deliveryStatus = order['delivery_status'] as String? ?? 'pending';
    final isDelivered = deliveryStatus.toLowerCase() == 'delivered';
    final deliveryColor = isDelivered ? AppColors.success : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text('${item['quantity']}x ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(
                      child: Text(
                        '${item['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(AppConstants.formatCurrency(double.parse(item['price'].toString()))),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  AppConstants.formatCurrency(totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: paymentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Payment', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text(paymentStatus.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: paymentColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: deliveryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Delivery', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text(deliveryStatus.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: deliveryColor)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
