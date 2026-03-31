import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.read(apiClientProvider)));

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  Future<DashboardStats> getDashboardStats() async {
    final response = await _client.get('/admin/dashboard');
    return DashboardStats.fromJson(response.data);
  }

  Future<List<AdminMember>> getMembers({String? search}) async {
    final Map<String, dynamic> params = {};
    if (search != null) params['search'] = search;
    
    final response = await _client.get('/admin/members', params: params);
    final List data = response.data;
    return data.map((e) => AdminMember.fromJson(e)).toList();
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

  Future<List<AdminEvent>> getEvents() async {
    final response = await _client.get('/admin/events');
    final List data = response.data;
    return data.map((e) => AdminEvent.fromJson(e)).toList();
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
}
