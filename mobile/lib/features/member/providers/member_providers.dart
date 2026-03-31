import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_models.dart';
import '../repositories/member_repository.dart';

// Dashboard Provider
final memberDashboardProvider = FutureProvider.autoDispose<MemberDashboardData>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getDashboard();
});

// Attendance Logs Provider
final memberAttendanceProvider = FutureProvider.autoDispose<List<MemberAttendanceLog>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getAttendanceLogs();
});

// Events Provider
final memberEventsProvider = FutureProvider.autoDispose<List<MemberEvent>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getEvents();
});

// Profile Provider
final memberProfileProvider = FutureProvider.autoDispose<MemberProfile>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getProfile();
});

// Profile Actions Provider
final memberProfileActionsProvider = Provider((ref) {
  final repo = ref.watch(memberRepositoryProvider);
  return MemberProfileActions(ref, repo);
});

class MemberProfileActions {
  final Ref _ref;
  final MemberRepository _repo;

  MemberProfileActions(this._ref, this._repo);

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    String? profilePhotoBase64,
  }) async {
    final data = {
      'name': name,
      'phone': phone,
      'address': address,
      'profilePhotoBase64': profilePhotoBase64,
    };
    await _repo.updateProfile(data);
    _ref.invalidate(memberProfileProvider);
    _ref.invalidate(memberDashboardProvider); // Refresh dashboard too as name might impact it
  }
}

// Fees & Payment Status
final memberFeeStatusProvider = Provider.autoDispose<String>((ref) {
  final dashboard = ref.watch(memberDashboardProvider).value;
  return dashboard?.feeStatus ?? 'due';
});
