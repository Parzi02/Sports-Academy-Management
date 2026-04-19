import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/storage_service.dart';

// UserModel placeholder
class UserModel {
  final String id;
  final String name;
  final String role;
  final String branchId;
  final String phone;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branchId,
    required this.phone,
  });

  factory UserModel.fromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token');
      
      // Decode payload (second part of JWT)
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);

      return UserModel(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? 'User',
        role: data['role']?.toString() ?? 'member',
        branchId: data['branch_id']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
      );
    } catch (e) {
      // Fallback for debugging if decoding fails
      return UserModel(
        id: 'error',
        name: 'Error User',
        role: 'member',
        branchId: '',
        phone: '',
      );
    }
  }
}

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }
  final Ref ref;

  Future<void> _init() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'jwt_token');
    if (token != null) {
      state = AsyncValue.data(UserModel.fromJwt(token));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String token) async {
    await ref.read(secureStorageProvider).write(key: 'jwt_token', value: token);
    state = AsyncValue.data(UserModel.fromJwt(token));
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).delete(key: 'jwt_token');
    await ref.read(storageServiceProvider).clearAll();
    state = const AsyncValue.data(null);
  }
}
