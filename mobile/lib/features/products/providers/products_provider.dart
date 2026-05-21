import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/products');
  
  if (response.statusCode == 200) {
    final List<dynamic> data = response.data;
    return data.map((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load products');
  }
});
