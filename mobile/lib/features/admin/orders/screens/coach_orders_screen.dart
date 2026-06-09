import 'dart:convert';
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
          
          final pendingOrders = orders.where((o) => o['status'] == 'pending').toList();
          final toDeliverOrders = orders.where((o) => o['delivery_status'] == 'to_deliver').toList();
          final completedOrders = orders.where((o) => o['delivery_status'] == 'delivered').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Pending'),
                      Tab(text: 'To Deliver'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrderList(pendingOrders, ref, orders),
                      _buildOrderList(toDeliverOrders, ref, orders),
                      _buildOrderList(completedOrders, ref, orders),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showProofDialog(BuildContext context, String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof'),
              automaticallyImplyLeading: false,
              actions: const [CloseButton()],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Image.memory(base64Decode(base64String), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, WidgetRef ref, List<dynamic> allOrders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found.', 
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          textAlign: TextAlign.center,
        ),
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
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final bool isPendingPayment = order['status'] == 'pending';
    final bool isToDeliver = order['delivery_status'] == 'to_deliver';
    final bool isDelivered = order['delivery_status'] == 'delivered';
    
    try {
      List<dynamic> items = [];
      if (order['items'] != null) {
        if (order['items'] is String) {
          try {
            var decoded = jsonDecode(order['items']);
            if (decoded is String) {
              decoded = jsonDecode(decoded);
            }
            if (decoded is List) {
              items = List<dynamic>.from(decoded);
            }
          } catch (e) {
            items = [];
          }
        } else if (order['items'] is List) {
          items = List<dynamic>.from(order['items'] as List);
        }
      }
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
                  color: isDelivered ? Colors.green.withOpacity(0.1) : (isToDeliver ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDelivered ? 'Completed' : (isToDeliver ? 'To Deliver' : (isPendingPayment ? 'Pending Payment' : 'Processing')),
                  style: TextStyle(
                    color: isDelivered ? Colors.green : (isToDeliver ? Colors.blue : Colors.orange),
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
          
          if (order['utr_number'] != null && order['utr_number'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UTR Number', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(order['utr_number'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (order['payment_proof'] != null && order['payment_proof'].toString().isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showProofDialog(context, order['payment_proof']),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('View Proof', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],
          
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
              if (isPendingPayment)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(coachOrdersProvider.notifier).updateOrderStatus(
                        order['id'],
                        status: 'payment_verified',
                        deliveryStatus: 'to_deliver',
                      );
                      if (context.mounted) ToastUtils.showTopToast(context, 'Payment confirmed');
                    } catch (e) {
                      if (context.mounted) ToastUtils.showTopToast(context, 'Failed to update order');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if (isToDeliver)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(coachOrdersProvider.notifier).updateOrderStatus(
                        order['id'],
                        deliveryStatus: 'delivered',
                      );
                      if (context.mounted) ToastUtils.showTopToast(context, 'Order marked as delivered');
                    } catch (e) {
                      if (context.mounted) ToastUtils.showTopToast(context, 'Failed to update order');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Mark Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
    } catch (e, stacktrace) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        color: Colors.red.withOpacity(0.1),
        child: Text('Error rendering order:\n$e\n$stacktrace', style: const TextStyle(color: Colors.red)),
      );
    }
  }
}
