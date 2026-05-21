import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: productsAsyncValue.when(
        data: (products) {
          final productId = int.tryParse(widget.id);
          final product = products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(id: 0, name: 'Not Found', description: '', price: 0.0),
          );

          if (product.id == 0) {
            return const Center(child: Text('Product not found.'));
          }

          Widget imageWidget;
          if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
            try {
              String base64String = product.imageBase64!;
              if (base64String.contains(',')) {
                base64String = base64String.split(',').last;
              }
              final bytes = base64Decode(base64String);
              imageWidget = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
            } catch (e) {
              imageWidget = const Icon(Icons.broken_image, size: 100, color: Colors.grey);
            }
          } else {
            imageWidget = const Icon(Icons.shopping_bag, size: 100, color: AppColors.primary);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: 300,
                  child: imageWidget,
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (quantity > 1) setState(() => quantity--);
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                color: AppColors.primary,
                                iconSize: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$quantity',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.primary,
                                iconSize: 32,
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 24.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(cartProvider.notifier).addToCart(product, quantity);
                                  ToastUtils.showTopToast(context, '${product.name} added to cart!');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
