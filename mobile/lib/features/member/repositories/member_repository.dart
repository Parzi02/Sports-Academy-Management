import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/member_models.dart';

final memberRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return MemberRepository(client, storage);
});

class MemberRepository {
  final ApiClient _client;
  final StorageService _storage;

  MemberRepository(this._client, this._storage);

  static const _kDashboardCacheKey = 'member_dashboard_cache';
  static const _kProfileCacheKey = 'member_profile_cache';
  static const _kEventsCacheKey = 'member_events_cache';

  Future<MemberDashboardData> getDashboard() async {
    try {
      final response = await _client.get('/member/dashboard');
      final data = MemberDashboardData.fromJson(response.data);
      // Cache the fresh data
      await _storage.save(_kDashboardCacheKey, response.data);
      return data;
    } catch (e) {
      // Fallback to cache if network fails
      final cachedData = await _storage.get(_kDashboardCacheKey);
      if (cachedData != null) {
        return MemberDashboardData.fromJson(cachedData);
      }
      rethrow;
    }
  }

  Future<List<MemberAttendanceLog>> getAttendanceLogs() async {
    final response = await _client.get('/member/attendance');
    final List data = response.data;
    return data.map((e) => MemberAttendanceLog.fromJson(e)).toList();
  }

  Future<List<MemberEvent>> getEvents() async {
    try {
      final response = await _client.get('/member/events');
      final List data = response.data;
      await _storage.save(_kEventsCacheKey, data);
      return data.map((e) => MemberEvent.fromJson(e)).toList();
    } catch (e) {
      final cachedData = await _storage.get(_kEventsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((e) => MemberEvent.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<MemberProfile> getProfile() async {
    try {
      final response = await _client.get('/member/profile');
      final data = MemberProfile.fromJson(response.data);
      await _storage.save(_kProfileCacheKey, response.data);
      return data;
    } catch (e) {
      final cachedData = await _storage.get(_kProfileCacheKey);
      if (cachedData != null) {
        return MemberProfile.fromJson(cachedData);
      }
      rethrow;
    }
  }

  Future<void> toggleFavourite(String eventId) async {
    await _client.post('/member/events/$eventId/favourite', {});
  }

  Future<void> submitPaymentProof(double amount, String planType, String utrNumber, String screenshotBase64) async {
    await _client.post('/member/payments/submit', {
      'amount': amount,
      'planType': planType,
      'utrNumber': utrNumber,
      'screenshotBase64': screenshotBase64,
    });
  }

  Future<List<dynamic>> getPaymentHistory() async {
    final response = await _client.get('/member/payments/history');
    return response.data as List<dynamic>;
  }

  Future<void> recordPayment(double amount, String method) async {
    await _client.post('/member/payments', {
      'amount': amount,
      'paymentMethod': method,
      'upiTransactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<void> markSelfAttendance(String imageBase64) async {
    await _client.post('/member/attendance/mark', {'imageBase64': imageBase64});
  }

  Future<MemberProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/member/profile', data);
    final profile = MemberProfile.fromJson(response.data);
    await _storage.save(_kProfileCacheKey, response.data);
    return profile;
  }
}

