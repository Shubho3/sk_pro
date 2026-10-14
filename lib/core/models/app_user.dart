/// The three account types in the system.
enum UserRole { admin, employee, company, unknown }

/// Account lifecycle status.
enum UserStatus { active, pending, disabled }

UserRole userRoleFromString(String? value) => UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.unknown,
    );

UserStatus userStatusFromString(String? value) => UserStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserStatus.pending,
    );

/// A user profile stored in PostgreSQL `public.users`.
class AppUser {
  final int id;
  final String authId;
  final String _userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final UserStatus status;

  /// For `company` users, the linked `companies.id`.
  final int? companyId;

  /// id of the admin/employee who created this account.
  final int? createdBy;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.authId,
    String? userId,
    required this.name,
    this.email = '',
    required this.phone,
    required this.role,
    required this.status,
    this.companyId,
    this.createdBy,
    this.createdAt,
  }) : _userId = userId ?? '';

  /// Backward-compatible alias for auth ID.
  String get uid => authId;

  String get userId => _userId.isNotEmpty
      ? _userId
      : (email.contains('@')
          ? email.split('@').first
          : (email.isNotEmpty ? email : authId));

  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;
  bool get isCompany => role == UserRole.company;

  factory AppUser.fromMap(Map<String, dynamic> map, [String? fallbackUid]) {
    final rawEmail = (map['email'] ?? '') as String;
    final explicitUserId =
        (map['user_id'] ?? map['userId'] as String?)?.trim();
    final authId =
        (map['auth_id'] ?? map['uid'] ?? fallbackUid ?? '').toString();
    final effectiveUserId =
        (explicitUserId != null && explicitUserId.isNotEmpty)
            ? explicitUserId
            : (rawEmail.contains('@')
                ? rawEmail.split('@').first
                : (rawEmail.isNotEmpty ? rawEmail : authId));

    final role = userRoleFromString((map['role'] ?? '').toString());
    final rawStatus = map['status']?.toString();
    final status = rawStatus != null
        ? userStatusFromString(rawStatus)
        : (role == UserRole.admin ? UserStatus.active : UserStatus.pending);

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    final idVal = map['id'];
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal == null
        ? null
        : (compIdVal is int ? compIdVal : int.tryParse(compIdVal.toString()));

    final createdByVal = map['created_by'] ?? map['createdBy'];
    final createdBy = createdByVal == null
        ? null
        : (createdByVal is int
            ? createdByVal
            : int.tryParse(createdByVal.toString()));

    return AppUser(
      id: id,
      authId: authId,
      userId: effectiveUserId,
      name: (map['name'] ?? '') as String,
      email: rawEmail.isNotEmpty ? rawEmail : '$effectiveUserId@chai.app',
      phone: (map['phone'] ?? '') as String,
      role: role,
      status: status,
      companyId: companyId,
      createdBy: createdBy,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'auth_id': authId,
        'user_id': userId,
        'name': name,
        'email': email.isNotEmpty ? email : '$userId@chai.app',
        'phone': phone,
        'role': role.name,
        'status': status.name,
        if (companyId != null) 'company_id': companyId,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  AppUser copyWith({
    int? id,
    String? authId,
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    UserStatus? status,
    int? companyId,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
