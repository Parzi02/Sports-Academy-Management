import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/toast_utils.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool isPlacingOrder = false;

  Future<void> _placeOrder() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    setState(() {
      isPlacingOrder = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final itemsData = cartItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
      }).toList();

      final totalAmount = ref.read(cartProvider.notifier).totalPrice;

      final response = await apiClient.post('/orders', {
        'items': itemsData,
        'totalAmount': totalAmount,
      });

      if (response.statusCode == 201) {
        ref.read(cartProvider.notifier).clearCart();
        if (mounted) {
          ToastUtils.showTopToast(context, 'Order placed successfully!');
          context.pop();
        }
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showTopToast(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.read(cartProvider.notifier).totalPrice;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      Widget imageWidget;
                      if (item.product.imageBase64 != null && item.product.imageBase64!.isNotEmpty) {
                        try {
                          String base64String = item.product.imageBase64!;
                          if (base64String.contains(',')) {
                            base64String = base64String.split(',').last;
                          }
                          final bytes = base64Decode(base64String);
                          imageWidget = Image.memory(bytes, fit: BoxFit.cover, width: 60, height: 60);
                        } catch (e) {
                          imageWidget = const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                        }
                      } else {
                        imageWidget = const Icon(Icons.shopping_bag, size: 40, color: AppColors.primary);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.grey[200],
                                  width: 60,
                                  height: 60,
                                  child: imageWidget,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1);
                                    },
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isPlacingOrder ? null : _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Place Order',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
