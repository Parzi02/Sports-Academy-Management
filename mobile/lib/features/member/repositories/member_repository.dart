import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/member_models.dart';

final memberRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return MemberRepository(client);
});

class MemberRepository {
  final ApiClient _client;

  MemberRepository(this._client);

  Future<MemberDashboardData> getDashboard() async {
    final response = await _client.get('/member/dashboard');
    return MemberDashboardData.fromJson(response.data);
  }

  Future<List<MemberAttendanceLog>> getAttendanceLogs() async {
    final response = await _client.get('/member/attendance');
    final List data = response.data;
    return data.map((e) => MemberAttendanceLog.fromJson(e)).toList();
  }

  Future<List<MemberEvent>> getEvents() async {
    final response = await _client.get('/member/events');
    final List data = response.data;
    return data.map((e) => MemberEvent.fromJson(e)).toList();
  }

  Future<MemberProfile> getProfile() async {
    final response = await _client.get('/member/profile');
    return MemberProfile.fromJson(response.data);
  }

  Future<void> toggleFavourite(String eventId) async {
    await _client.post('/member/events/$eventId/favourite', {});
  }

  Future<void> recordPayment(double amount, String method) async {
    await _client.post('/member/payments', {
      'amount': amount,
      'paymentMethod': method,
      'upiTransactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<MemberProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/member/profile', data);
    return MemberProfile.fromJson(response.data);
  }
}
