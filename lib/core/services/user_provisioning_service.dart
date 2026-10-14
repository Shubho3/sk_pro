import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// Creates new Supabase Auth accounts and public.users rows from the admin app.
class UserProvisioningService {
  UserProvisioningService(this._supabase);

  final SupabaseClient _supabase;

  /// Creates an employee or standalone user account via the `provision_user` RPC.
  Future<int> createAccount({
    required String name,
    required String userId,
    String? email,
    required String phone,
    required String password,
    required UserRole role,
    UserStatus status = UserStatus.active,
    int? companyId,
    int? createdBy,
  }) async {
    final cleanUserId = userId.trim().toLowerCase();
    if (cleanUserId.isEmpty) {
      throw Exception('User ID cannot be empty.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(cleanUserId)) {
      throw Exception(
          'User ID must be alphanumeric (letters, numbers, underscore, or dot).');
    }

    final res = await _supabase.rpc(
      'provision_user',
      params: {
        'p_user_id': cleanUserId,
        'p_password': password,
        'p_name': name.trim(),
        'p_phone': phone.trim(),
        'p_role': role.name,
        'p_company_id': companyId,
        'p_created_by': createdBy,
      },
    );

    return res is int ? res : (int.tryParse(res.toString()) ?? 0);
  }

  /// Atomically creates a company + optional login account via `create_company_account` RPC.
  /// Returns `{'company_id': int, 'user_id': int?, 'name': String}`.
  Future<Map<String, dynamic>> createCompanyAccount({
    required String name,
    String contactPerson = '',
    String phone = '',
    String address = '',
    bool createLogin = false,
    String? userId,
    String? password,
    int? createdBy,
  }) async {
    final res = await _supabase.rpc(
      'create_company_account',
      params: {
        'p_name': name.trim(),
        'p_contact_person': contactPerson.trim(),
        'p_phone': phone.trim(),
        'p_address': address.trim(),
        'p_create_login': createLogin,
        'p_user_id': userId?.trim().toLowerCase(),
        'p_password': password,
        'p_created_by': createdBy,
      },
    );

    if (res is Map<String, dynamic>) return res;
    // Supabase may return a list with one element for RPC calls
    if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
      return res.first as Map<String, dynamic>;
    }
    return {'company_id': 0, 'user_id': null, 'name': name.trim()};
  }

  /// Maps errors to friendly messages for provisioning dialogs.
  static String describeError(Object error) {
    final msg = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('PostgrestException: ', '');
    return msg;
  }
}
