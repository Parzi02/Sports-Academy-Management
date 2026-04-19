import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AdminRepository(client, storage);
});

class AdminRepository {
  final ApiClient _client;
  final StorageService _storage;

  AdminRepository(this._client, this._storage);

  static const _kDashboardStatsCacheKey = 'admin_dashboard_stats_cache';
  static const _kMembersCacheKey = 'admin_members_cache';
  static const _kEventsCacheKey = 'admin_events_cache';

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _client.get('/admin/dashboard');
      final data = DashboardStats.fromJson(response.data);
      await _storage.save(_kDashboardStatsCacheKey, response.data);
      return data;
    } catch (e) {
      final cachedData = await _storage.get(_kDashboardStatsCacheKey);
      if (cachedData != null) {
        return DashboardStats.fromJson(cachedData);
      }
      rethrow;
    }
  }

  Future<List<AdminMember>> getMembers({String? search}) async {
    try {
      final Map<String, dynamic> params = {};
      if (search != null) params['search'] = search;
      
      final response = await _client.get('/admin/members', params: params);
      final List data = response.data;
      
      // Only cache if it's a full list (no search)
      if (search == null) {
        await _storage.save(_kMembersCacheKey, data);
      }
      
      return data.map((e) => AdminMember.fromJson(e)).toList();
    } catch (e) {
      if (search == null) {
        final cachedData = await _storage.get(_kMembersCacheKey);
        if (cachedData != null && cachedData is List) {
          return cachedData.map((e) => AdminMember.fromJson(e)).toList();
        }
      }
      rethrow;
    }
  }

  Future<AdminProfileData> getAdminProfile() async {
    final response = await _client.get('/admin/profile');
    return AdminProfileData.fromJson(response.data);
  }

  Future<AdminProfileData> updateAdminProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/admin/profile', data);
    return AdminProfileData.fromJson(response.data['profile']);
  }

  Future<AdminMemberProfile> getMemberProfile(String id) async {
    final response = await _client.get('/admin/members/$id');
    return AdminMemberProfile.fromJson(response.data);
  }

  Future<List<AdminBatch>> getBatches() async {
    final response = await _client.get('/admin/batches');
    final List data = response.data;
    return data.map((e) => AdminBatch.fromJson(e)).toList();
  }

  Future<List<AdminCoach>> getCoaches() async {
    final response = await _client.get('/admin/coaches');
    final List data = response.data;
    return data.map((e) => AdminCoach.fromJson(e)).toList();
  }

  Future<List<AdminEvent>> getEvents() async {
    try {
      final response = await _client.get('/admin/events');
      final List data = response.data;
      await _storage.save(_kEventsCacheKey, data);
      return data.map((e) => AdminEvent.fromJson(e)).toList();
    } catch (e) {
      final cachedData = await _storage.get(_kEventsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((e) => AdminEvent.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<void> addMember(Map<String, dynamic> memberData) async {
    await _client.post('/admin/members', memberData);
  }

  Future<List<AttendanceMember>> getAttendanceRecords({
    required String batchId,
    required String date,
  }) async {
    final response = await _client.get('/admin/attendance', params: {
      'batchId': batchId,
      'date': date,
    });
    final List data = response.data;
    return data.map((e) => AttendanceMember.fromJson(e)).toList();
  }

  Future<List<String>> getMarkedDays({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _client.get('/admin/attendance/marked-days', params: {
      'startDate': startDate,
      'endDate': endDate,
    });
    final List data = response.data;
    return data.map((e) => e.toString()).toList();
  }

  Future<void> markAttendance({
    required String batchId,
    required String date,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    await _client.post('/admin/attendance', {
      'batchId': batchId,
      'date': date,
      'attendanceList': attendanceList,
    });
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    await _client.post('/admin/events', eventData);
  }

  Future<List<dynamic>> getPendingPayments() async {
    final response = await _client.get('/admin/payments/pending');
    return response.data as List<dynamic>;
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _client.put('/admin/payments/approve/$paymentId', {'status': status});
  }

  Future<void> recordCashPayment({
    required String memberId,
    required double amount,
    required String planType,
  }) async {
    await _client.post('/admin/members/$memberId/pay-cash', {
      'amount': amount,
      'planType': planType,
    });
  }

  Future<void> updateMemberEnrollment(String userId, {String? batchId, String? membershipType}) async {
    final Map<String, dynamic> data = {};
    if (batchId != null) data['batch_id'] = batchId;
    if (membershipType != null) data['membership_type'] = membershipType;
    
    await _client.put('/admin/members/$userId/enrollment', data);
  }
}



