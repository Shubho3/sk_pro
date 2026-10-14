import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/item_request.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _dateFmt = DateFormat('d MMM, h:mm a');

/// Admin review queue for item requests raised by a company from its portal.
/// Displays pending requests for approval/rejection as well as processed
/// (fulfilled/rejected) requests with options to clear them from inbox.
class AdminRequestsView extends ConsumerWidget {
  const AdminRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRequestsProvider);
    final processedAsync = ref.watch(processedRequestsProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateView(message: '$e'),
      data: (pending) {
        final processed = processedAsync.value ?? const <ItemRequest>[];

        if (pending.isEmpty && processed.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No item requests in inbox.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              _SectionHeader(title: 'Pending approval', count: pending.length),
              for (final request in pending)
                _RequestCard(
                  key: ValueKey(request.id),
                  request: request,
                ),
              if (processed.isNotEmpty) const SizedBox(height: 20),
            ],
            if (processed.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(
                    title: 'Processed & History',
                    count: processed.length,
                    color: const Color(0xFF64748B),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All Processed'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF06030),
                    ),
                    onPressed: () =>
                        _clearAllProcessed(context, ref, processed),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final request in processed)
                _RequestCard(
                  key: ValueKey(request.id),
                  request: request,
                  onDelete: () => _deleteRequest(context, ref, request),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _deleteRequest(
    BuildContext context,
    WidgetRef ref,
    ItemRequest request,
  ) async {
    await ref.read(requestRepositoryProvider).delete(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cleared from inbox')),
      );
    }
  }

  Future<void> _clearAllProcessed(
    BuildContext context,
    WidgetRef ref,
    List<ItemRequest> processed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Processed Requests?'),
        content: Text(
          'Remove all ${processed.length} processed requests from your inbox history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF06030)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final r in processed) {
        await ref.read(requestRepositoryProvider).delete(r.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared ${processed.length} processed requests')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.color,
  });

  final String title;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('$count', style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({
    super.key,
    required this.request,
    this.onDelete,
  });

  final ItemRequest request;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payNow = request.paymentMode == PaymentMode.payNow;
    final modeColor = payNow ? Colors.blue : Colors.brown;
    final isPending = request.status == RequestStatus.pending;
    final isFulfilled = request.status == RequestStatus.fulfilled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    payNow ? 'Pay on delivery' : 'Add to bill',
                    style: TextStyle(color: modeColor, fontSize: 11),
                  ),
                  backgroundColor: modeColor.withValues(alpha: 0.12),
                  side: BorderSide(color: modeColor.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                ),
                if (!isPending) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFulfilled
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isFulfilled ? 'FULFILLED' : 'REJECTED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isFulfilled
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    tooltip: 'Clear from inbox',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            if (request.createdAt != null)
              Text(
                _dateFmt.format(request.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            for (final line in request.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${line.name}  x${line.qty}')),
                    Text(_currency.format(line.total)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  _currency.format(request.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(distributionServiceProvider).approveRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved')),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject request?'),
        content: Text(
          '${request.companyName} will be notified that their request for '
          '${request.items.length} item(s) was not approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(distributionServiceProvider).rejectRequest(request);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }
}
