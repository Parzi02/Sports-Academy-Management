import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/admin_repository.dart';
import '../models/admin_models.dart';

// Dashboard Stats Provider
final adminDashboardProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardStats();
});

// Batches Provider
final adminBatchesProvider = FutureProvider<List<AdminBatch>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getBatches();
});

// Events Provider
final adminEventsProvider = FutureProvider<List<AdminEvent>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getEvents();
});

// Coaches Provider
final adminCoachesProvider = FutureProvider<List<AdminCoach>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getCoaches();
});

// Admin Profile State Management
class AdminProfileNotifier extends StateNotifier<AsyncValue<AdminProfileData>> {
  final AdminRepository _repo;

  AdminProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.getAdminProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatedProfile = await _repo.updateAdminProfile(data);
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      throw e;
    }
  }
}

final adminProfileProvider = StateNotifierProvider<AdminProfileNotifier, AsyncValue<AdminProfileData>>((ref) {
  return AdminProfileNotifier(ref.watch(adminRepositoryProvider));
});

// Members State Management
class AdminMembersNotifier extends StateNotifier<AsyncValue<List<AdminMember>>> {
  final AdminRepository _repo;
  String _searchQuery = '';

  AdminMembersNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _repo.getMembers(search: _searchQuery.isEmpty ? null : _searchQuery);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateSearch(String query) {
    _searchQuery = query;
    fetchMembers();
  }

  Future<void> addMember(Map<String, dynamic> data) async {
    await _repo.addMember(data);
    await fetchMembers(); // Refresh list
  }
}

final adminMembersProvider = StateNotifierProvider<AdminMembersNotifier, AsyncValue<List<AdminMember>>>((ref) {
  return AdminMembersNotifier(ref.watch(adminRepositoryProvider));
});

// Single Member Profile Provider
final adminMemberProfileProvider = FutureProvider.family<AdminMemberProfile, String>((ref, id) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getMemberProfile(id);
});

// Attendance Management
final adminMarkAttendanceProvider = Provider((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo;
});

// Selected Date & Batch for Attendance Screen
final selectedAttendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final selectedAttendanceBatchIdProvider = StateProvider<String?>((ref) => null);
final attendanceSearchQueryProvider = StateProvider<String>((ref) => '');
final attendanceStatusFilterProvider = StateProvider<String>((ref) => 'All');

// Marked Days Provider (Green highlight dates)
final adminMarkedDaysProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month + 1, 0);
  
  return repo.getMarkedDays(
    startDate: DateFormat('yyyy-MM-dd').format(start),
    endDate: DateFormat('yyyy-MM-dd').format(end),
  );
});

// Dynamic Attendance List state
class AttendanceListNotifier extends StateNotifier<AsyncValue<List<AttendanceMember>>> {
  final AdminRepository _repo;
  final String? batchId;
  final String date;

  AttendanceListNotifier(this._repo, this.batchId, this.date) : super(const AsyncValue.loading()) {
    if (batchId != null) fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    if (batchId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final records = await _repo.getAttendanceRecords(batchId: batchId!, date: date);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateStatus(String memberId, String status) {
    state.whenData((members) {
      final updated = members.map((m) => m.id == memberId 
        ? AttendanceMember(id: m.id, name: m.name, memberId: m.memberId, status: status) 
        : m).toList();
      state = AsyncValue.data(updated);
    });
  }
}

final attendanceListProvider = StateNotifierProvider.autoDispose<AttendanceListNotifier, AsyncValue<List<AttendanceMember>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final batchId = ref.watch(selectedAttendanceBatchIdProvider);
  final date = ref.watch(selectedAttendanceDateProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  
  return AttendanceListNotifier(repo, batchId, dateStr);
});

// Admin Pending Payments Provider
final adminPendingPaymentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPendingPayments();
});
