import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/complaint.dart';
import '../../../core/providers/repository_providers.dart';
import 'complaints_view.dart';
import 'requests_view.dart';

/// The admin's action queue: item requests waiting on a decision, and
/// complaints waiting on a response. They share a nav slot because both are
/// "things people have sent you that need answering".
class AdminInboxView extends ConsumerWidget {
  const AdminInboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequests =
        ref.watch(pendingRequestsProvider).value?.length ?? 0;
    final openComplaints = ref
            .watch(allComplaintsProvider)
            .value
            ?.where((c) => c.status != ComplaintStatus.resolved)
            .length ??
        0;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(child: _TabLabel(label: 'Requests', count: pendingRequests)),
              Tab(child: _TabLabel(label: 'Complaints', count: openComplaints)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdminRequestsView(),
                AdminComplaintsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen host for [AdminInboxView], pushed from the admin app-bar Inbox
/// icon (the inbox is no longer a bottom-nav / rail destination).
class AdminInboxScreen extends StatelessWidget {
  const AdminInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: const AdminInboxView(),
    );
  }
}

/// Tab caption with a count badge, shown only when there is something waiting.
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Badge(label: Text('$count')),
        ],
      ],
    );
  }
}
