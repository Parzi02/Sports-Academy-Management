import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

final coachOrdersProvider = StateNotifierProvider<CoachOrdersNotifier, AsyncValue<List<dynamic>>>((ref) {
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

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _apiClient.patch('/orders/$orderId/status', {'status': newStatus});
      // Update local state instead of full refresh for better UX
      if (state.hasValue) {
        final currentOrders = state.value!;
        final updatedOrders = currentOrders.map((order) {
          if (order['id'] == orderId) {
            return {...order, 'status': newStatus};
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
