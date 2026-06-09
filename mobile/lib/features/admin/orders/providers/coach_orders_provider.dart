import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

final coachOrdersProvider = StateNotifierProvider.autoDispose<CoachOrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
  return CoachOrdersNotifier(ref.watch(apiClientProvider));
});

class CoachOrdersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ApiClient _apiClient;

  CoachOrdersNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/orders/coach');
      state = AsyncValue.data(response.data as List<dynamic>);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateOrderStatus(int orderId, {String? status, String? deliveryStatus}) async {
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (deliveryStatus != null) data['delivery_status'] = deliveryStatus;
      
      await _apiClient.patch('/orders/$orderId/status', data);
      
      // Update local state instead of full refresh for better UX
      if (state.hasValue) {
        final currentOrders = state.value!;
        final updatedOrders = currentOrders.map((order) {
          if (order['id'] == orderId) {
            final updatedOrder = Map<String, dynamic>.from(order);
            if (status != null) updatedOrder['status'] = status;
            if (deliveryStatus != null) updatedOrder['delivery_status'] = deliveryStatus;
            return updatedOrder;
          }
          return order;
        }).toList();
        state = AsyncValue.data(updatedOrders);
      }
    } catch (e) {
      rethrow;
    }
  }
}
