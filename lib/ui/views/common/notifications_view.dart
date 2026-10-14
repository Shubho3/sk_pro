import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/status_views.dart';

final _dateFmt = DateFormat('d MMM, h:mm a');

/// Merges a user's direct notifications (`toUid`) with role broadcasts
/// (`toRole`) into one list, newest first.
final _mergedNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<AppNotification>>>((ref) {
  final user = ref.watch(appUserProvider).value;
  if (user == null) return const AsyncValue.data([]);
  final byUid = ref.watch(userNotificationsProvider(user.uid));
  final byRole = ref.watch(roleNotificationsProvider(user.role.name));
  if (byUid.isLoading || byRole.isLoading) {
    return const AsyncValue.loading();
  }
  final merged = <AppNotification>[
    ...byUid.value ?? const [],
    ...byRole.value ?? const [],
  ]..sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return -1;
      if (bd == null) return 1;
      return bd.compareTo(ad);
    });
  return AsyncValue.data(merged);
});

int unreadCount(WidgetRef ref) {
  final async = ref.watch(_mergedNotificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
}

/// Notifications center screen, shared across roles.
class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_mergedNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              message: 'No notifications yet.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: n.read ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: Icon(
                    n.read
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: n.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(n.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${n.body}'
                    '${n.createdAt != null ? '\n${_dateFmt.format(n.createdAt!)}' : ''}',
                  ),
                  isThreeLine: true,
                  onTap: n.read
                      ? null
                      : () =>
                          ref.read(notificationRepositoryProvider).markRead(n.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// App-bar bell with an unread badge; opens [NotificationsView].
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = unreadCount(ref);
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsView()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
