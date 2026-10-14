import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/complaint.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/complaint_tile.dart';
import '../../widgets/status_views.dart';

/// Every complaint raised by any employee or company, with the status menu
/// enabled so an admin can move one through open → inProgress → resolved.
class AdminComplaintsView extends ConsumerWidget {
  const AdminComplaintsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return complaintsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateView(message: '$e'),
      data: (complaints) {
        if (complaints.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_outlined,
            message: 'No complaints raised.',
          );
        }
        final open = complaints
            .where((c) => c.status != ComplaintStatus.resolved)
            .toList();
        final resolved = complaints
            .where((c) => c.status == ComplaintStatus.resolved)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final complaint in open)
              ComplaintTile(
                complaint: complaint,
                showAuthor: true,
                onStatusChange: (status) =>
                    _setStatus(context, ref, complaint, status),
              ),
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Resolved (${resolved.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All Resolved'),
                    onPressed: () => _clearAllResolved(context, ref, resolved),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final complaint in resolved)
                ComplaintTile(
                  complaint: complaint,
                  showAuthor: true,
                  onStatusChange: (status) =>
                      _setStatus(context, ref, complaint, status),
                  onDelete: () => _deleteComplaint(context, ref, complaint),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Complaint complaint,
    ComplaintStatus status,
  ) async {
    if (status == complaint.status) return;
    await ref.read(complaintRepositoryProvider).setStatus(complaint.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complaint marked ${status.name}')),
      );
    }
  }

  Future<void> _deleteComplaint(
    BuildContext context,
    WidgetRef ref,
    Complaint complaint,
  ) async {
    await ref.read(complaintRepositoryProvider).delete(complaint.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint cleared from inbox')),
      );
    }
  }

  Future<void> _clearAllResolved(
    BuildContext context,
    WidgetRef ref,
    List<Complaint> resolved,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Resolved Complaints?'),
        content: Text('Remove all ${resolved.length} resolved complaints from your inbox?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF06030)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final c in resolved) {
        await ref.read(complaintRepositoryProvider).delete(c.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared ${resolved.length} resolved complaints')),
        );
      }
    }
  }
}
