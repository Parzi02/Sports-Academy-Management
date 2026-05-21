import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product, int quantity) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedCart = List<CartItem>.from(state);
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + quantity,
      );
      state = updatedCart;
    } else {
      state = [...state, CartItem(product: product, quantity: quantity)];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final updatedCart = List<CartItem>.from(state);
    final existingIndex = updatedCart.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(quantity: quantity);
      state = updatedCart;
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0.0, (total, item) => total + (item.product.price * item.quantity));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
