import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/complaint_dialog.dart';
import '../../widgets/complaint_tile.dart';
import '../../widgets/status_views.dart';

/// Employee complaints: list of complaints they raised, plus a button to raise
/// a new (general) complaint.
class HelperComplaintsView extends ConsumerWidget {
  const HelperComplaintsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final complaintsAsync = ref.watch(userComplaintsProvider(user.uid));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<ComplaintResult>(
            context: context,
            builder: (_) => const ComplaintDialog(),
          );
          if (result == null) return;
          await ref.read(distributionServiceProvider).raiseComplaint(
                raisedByUid: user.uid,
                raisedByName: user.name,
                raisedByRole: UserRole.employee,
                employeeId: user.uid,
                subject: result.subject,
                description: result.description,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Complaint submitted')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Raise Complaint'),
      ),
      body: complaintsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (complaints) {
          if (complaints.isEmpty) {
            return const EmptyState(
              icon: Icons.report_problem_outlined,
              message: 'No complaints raised.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in complaints) ComplaintTile(complaint: c),
            ],
          );
        },
      ),
    );
  }
}
