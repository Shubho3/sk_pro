/// Approval state for a company (client) account.
enum ApprovalStatus { pending, approved, rejected }

ApprovalStatus approvalStatusFromString(String? value) =>
    ApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalStatus.pending,
    );

/// A client company served on distribution routes. Stored at `companies` table.
class Company {
  final int id;
  final String name;
  final String contactPerson;
  final String phone;
  final String address;

  /// e.g. `monthly`.
  final String billingCycle;

  /// Outstanding (unpaid) balance carried on the company's bill.
  final double outstanding;

  final ApprovalStatus approval;
  final bool isActive;

  /// id of the currently assigned employee (optional).
  final int? assignedEmployeeId;

  /// id (linked public.users.id) for this company, if provisioned.
  final int? ownerUid;

  final int? createdBy;
  final DateTime? createdAt;

  const Company({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.address,
    this.billingCycle = 'monthly',
    this.outstanding = 0,
    this.approval = ApprovalStatus.pending,
    this.isActive = true,
    this.assignedEmployeeId,
    this.ownerUid,
    this.createdBy,
    this.createdAt,
  });

  factory Company.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final assignedEmpVal =
        map['assigned_employee_id'] ?? map['assignedEmployeeId'];
    final assignedEmp = assignedEmpVal == null
        ? null
        : (assignedEmpVal is int
            ? assignedEmpVal
            : int.tryParse(assignedEmpVal.toString()));

    final ownerVal = map['owner_uid'] ?? map['ownerUid'];
    final ownerUid = ownerVal == null
        ? null
        : (ownerVal is int ? ownerVal : int.tryParse(ownerVal.toString()));

    final createdByVal = map['created_by'] ?? map['createdBy'];
    final createdBy = createdByVal == null
        ? null
        : (createdByVal is int
            ? createdByVal
            : int.tryParse(createdByVal.toString()));

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    return Company(
      id: id,
      name: (map['name'] ?? '') as String,
      contactPerson:
          (map['contact_person'] ?? map['contactPerson'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      billingCycle:
          (map['billing_cycle'] ?? map['billingCycle'] ?? 'monthly') as String,
      outstanding: (map['outstanding'] as num?)?.toDouble() ?? 0,
      approval: approvalStatusFromString((map['approval'] ?? '').toString()),
      isActive: (map['is_active'] ?? map['isActive'] as bool?) ?? true,
      assignedEmployeeId: assignedEmp,
      ownerUid: ownerUid,
      createdBy: createdBy,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'address': address,
        'billing_cycle': billingCycle,
        'outstanding': outstanding,
        'approval': approval.name,
        'is_active': isActive,
        if (assignedEmployeeId != null)
          'assigned_employee_id': assignedEmployeeId,
        if (ownerUid != null) 'owner_uid': ownerUid,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  Company copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? address,
    String? billingCycle,
    double? outstanding,
    ApprovalStatus? approval,
    bool? isActive,
    int? assignedEmployeeId,
    int? ownerUid,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      billingCycle: billingCycle ?? this.billingCycle,
      outstanding: outstanding ?? this.outstanding,
      approval: approval ?? this.approval,
      isActive: isActive ?? this.isActive,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      ownerUid: ownerUid ?? this.ownerUid,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
