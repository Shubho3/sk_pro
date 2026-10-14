/// An in-app notification stored in `notifications` table.
class AppNotification {
  final int id;
  final int? toUid;
  final String? toRole;
  final String title;
  final String body;

  /// Free-form category, e.g. `request`, `payment`, `complaint`, `route`.
  final String type;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.toUid,
    this.toRole,
    required this.title,
    required this.body,
    this.type = 'general',
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, [dynamic idFallback]) {
    final idVal = map['id'] ?? idFallback;
    final id = idVal is int
        ? idVal
        : (int.tryParse(idVal?.toString() ?? '') ?? 0);

    final toUidVal = map['to_uid'] ?? map['toUid'];
    final toUid = toUidVal == null
        ? null
        : (toUidVal is int ? toUidVal : int.tryParse(toUidVal.toString()));

    DateTime? parsedCreatedAt;
    final c = map['created_at'] ?? map['createdAt'];
    if (c is DateTime) {
      parsedCreatedAt = c;
    } else if (c is String) {
      parsedCreatedAt = DateTime.tryParse(c);
    } else if (c is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(c);
    }

    return AppNotification(
      id: id,
      toUid: toUid,
      toRole: (map['to_role'] ?? map['toRole'])?.toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? 'general').toString(),
      read: (map['read'] as bool?) ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (toUid != null) 'to_uid': toUid,
        if (toRole != null) 'to_role': toRole,
        'title': title,
        'body': body,
        'type': type,
        'read': read,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
