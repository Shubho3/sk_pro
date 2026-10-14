import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/user_provisioning_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/status_views.dart';

/// Admin screen to create and manage employee accounts.
class HelpersView extends ConsumerWidget {
  const HelpersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: employeesAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (employees) {
          if (employees.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'No employees yet.\nTap "Add Employee" to create one.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final active = employee.status == UserStatus.active;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: active
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    child: Icon(Icons.delivery_dining,
                        color: active ? Colors.green : Colors.grey),
                  ),
                  title: Text(employee.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('User ID: ${employee.userId}\n${employee.phone}'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: active,
                    onChanged: (value) => ref
                        .read(userRepositoryProvider)
                        .setStatus(
                          employee.uid,
                          value ? UserStatus.active : UserStatus.disabled,
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _CreateEmployeeDialog(),
    );
  }
}

class _CreateEmployeeDialog extends ConsumerStatefulWidget {
  const _CreateEmployeeDialog();

  @override
  ConsumerState<_CreateEmployeeDialog> createState() =>
      _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends ConsumerState<_CreateEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _userId = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _userId.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final admin = ref.read(appUserProvider).value;
      await ref.read(userProvisioningProvider).createAccount(
            name: _name.text,
            userId: _userId.text,
            phone: _phone.text,
            password: _password.text,
            role: UserRole.employee,
            createdBy: admin?.id,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee account created')),
        );
      }
    } catch (e) {
      setState(() => _error = UserProvisioningService.describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Employee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Full Name', required: true),
              _field(_userId, 'User ID (alphanumeric)',
                  alphanumeric: true, min: 3, required: true),
              _field(_phone, 'Phone', keyboard: TextInputType.phone),
              _field(_password, 'Temporary Password', obscure: true, min: 6),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool alphanumeric = false,
    bool obscure = false,
    int? min,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final value = (v ?? '').trim();
          if (required || alphanumeric || min != null) {
            if (value.isEmpty) return 'Required';
          }
          if (alphanumeric && !RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(value)) {
            return 'Use letters, numbers, and _ or -';
          }
          if (min != null && value.length < min) {
            return 'At least $min characters';
          }
          return null;
        },
      ),
    );
  }
}
