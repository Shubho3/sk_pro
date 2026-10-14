import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/complaint.dart';

final _dateFmt = DateFormat('d MMM, h:mm a');

Color complaintStatusColor(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.open:
      // Amber rather than orange: orange is now the brand colour.
      return Colors.amber.shade800;
    case ComplaintStatus.inProgress:
      return Colors.blue;
    case ComplaintStatus.resolved:
      return Colors.green;
  }
}

/// A card showing a complaint. When [onStatusChange] is provided (admin view),
/// a menu lets the status be updated.
class ComplaintTile extends StatelessWidget {
  const ComplaintTile({
    super.key,
    required this.complaint,
    this.onStatusChange,
    this.onDelete,
    this.showAuthor = false,
  });

  final Complaint complaint;
  final ValueChanged<ComplaintStatus>? onStatusChange;
  final VoidCallback? onDelete;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final color = complaintStatusColor(complaint.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.report_problem, color: color),
        title: Text(complaint.subject,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${showAuthor ? '${complaint.raisedByName} (${complaint.raisedByRole.name})\n' : ''}'
          '${complaint.description}'
          '${complaint.createdAt != null ? '\n${_dateFmt.format(complaint.createdAt!)}' : ''}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onStatusChange == null)
              Chip(
                label: Text(complaint.status.name,
                    style: TextStyle(color: color, fontSize: 12)),
                backgroundColor: color.withValues(alpha: 0.12),
                side: BorderSide(color: color.withValues(alpha: 0.4)),
              )
            else
              PopupMenuButton<ComplaintStatus>(
                onSelected: onStatusChange,
                child: Chip(
                  label: Text(complaint.status.name,
                      style: TextStyle(color: color, fontSize: 12)),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                itemBuilder: (_) => [
                  for (final s in ComplaintStatus.values)
                    PopupMenuItem(value: s, child: Text('Mark ${s.name}')),
                ],
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Clear from inbox',
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
