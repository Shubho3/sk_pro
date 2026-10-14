import 'app_user.dart';

enum ComplaintStatus { open, inProgress, resolved }

ComplaintStatus complaintStatusFromString(String? value) =>
    ComplaintStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintStatus.open,
    );

/// A complaint stored in `complaints` table.
class Complaint {
  final int id;
  final int raisedByUid;
  final String raisedByName;
  final UserRole raisedByRole;
  final int? companyId;
  final int? employeeId;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final DateTime? createdAt;

  const Complaint({
    required this.id,
    required this.raisedByUid,
    required this.raisedByName,
    required this.raisedByRole,
    this.companyId,
    this.employeeId,
    required this.subject,
    required this.description,
    this.status = ComplaintStatus.open,
    this.createdAt,
  });

  factory Complaint.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final raisedVal = map['raised_by_uid'] ?? map['raisedByUid'];
    final raisedByUid = raisedVal is int
        ? raisedVal
        : (int.tryParse(raisedVal?.toString() ?? '') ?? 0);

    final compIdVal = map['company_id'] ?? map['companyId'];
    final companyId = compIdVal == null
        ? null
        : (compIdVal is int ? compIdVal : int.tryParse(compIdVal.toString()));

    final empIdVal = map['employee_id'] ?? map['employeeId'];
    final employeeId = empIdVal == null
        ? null
        : (empIdVal is int ? empIdVal : int.tryParse(empIdVal.toString()));

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    return Complaint(
      id: id,
      raisedByUid: raisedByUid,
      raisedByName:
          (map['raised_by_name'] ?? map['raisedByName'] ?? '').toString(),
      raisedByRole: userRoleFromString(
          (map['raised_by_role'] ?? map['raisedByRole'])?.toString()),
      companyId: companyId,
      employeeId: employeeId,
      subject: (map['subject'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      status: complaintStatusFromString(map['status']?.toString()),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'raised_by_uid': raisedByUid,
        'raised_by_name': raisedByName,
        'raised_by_role': raisedByRole.name,
        if (companyId != null) 'company_id': companyId,
        if (employeeId != null) 'employee_id': employeeId,
        'subject': subject,
        'description': description,
        'status': status.name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
