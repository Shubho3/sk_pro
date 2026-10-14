import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/company.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/user_provisioning_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/status_views.dart';
import 'company_detail_view.dart';

/// Admin screen: create companies, manage them, and approve companies that
/// employees submitted for approval.
class OfficesView extends ConsumerWidget {
  const OfficesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, ref),
        icon: const Icon(Icons.business),
        label: const Text('Add Company'),
      ),
      body: companiesAsync.when(
        loading: () => const ShimmerList(itemCount: 6),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (companies) {
          if (companies.isEmpty) {
            return const EmptyState(
              icon: Icons.business_outlined,
              message: 'No companies yet.\nTap "Add Company" to create one.',
            );
          }
          final pending = companies
              .where((c) => c.approval == ApprovalStatus.pending)
              .toList();
          final others = companies
              .where((c) => c.approval != ApprovalStatus.pending)
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pending.isNotEmpty) ...[
                    _SectionHeader(
                        'Awaiting approval (${pending.length})', Colors.orange),
                    ...pending.map((c) => _PendingCard(company: c)),
                    const SizedBox(height: 16),
                  ],
                  _SectionHeader('Companies (${others.length})', Colors.teal),
                  ...others.map((c) => _CompanyCard(company: c)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _CompanyDialog(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _CompanyCard extends ConsumerWidget {
  const _CompanyCard({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = company.approval == ApprovalStatus.rejected;
    final approved = company.approval == ApprovalStatus.approved;
    final hasLogin = company.ownerUid != null;
    final isEnabled = company.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEnabled
              ? const Color(0xFFE2E8F0)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: rejected
              ? Colors.red.shade100
              : isEnabled
                  ? const Color(0xFFF06030).withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.2),
          child: Icon(
            Icons.business,
            color: rejected
                ? Colors.red
                : isEnabled
                    ? const Color(0xFFF06030)
                    : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                company.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? const Color(0xFF1E2530) : const Color(0xFF64748B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                isEnabled ? 'ACTIVE' : 'DISABLED',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${company.contactPerson} \u2022 ${company.phone}\n${company.address}',
              style: TextStyle(
                color: isEnabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enable / Disable switch
            Tooltip(
              message: isEnabled ? 'Disable company' : 'Enable company',
              child: Switch(
                value: isEnabled,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (val) async {
                  await ref.read(companyRepositoryProvider).setActive(company.id, val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? '${company.name} enabled'
                            : '${company.name} disabled (hidden from employees)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
            if (approved) ...[
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Billing & Invoices',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CompanyDetailView(company: company),
                  ),
                ),
              ),
            ],
            Icon(
              hasLogin ? Icons.verified_user : Icons.no_accounts,
              size: 18,
              color: hasLogin ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${company.contactPerson} \u2022 ${company.phone}'),
            Text(company.address),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        _CompanyDialog(approveCompany: company),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject company?'),
        content: Text('Reject "${company.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(companyRepositoryProvider)
          .setApproval(company.id, ApprovalStatus.rejected);
    }
  }
}

/// Dialog used both for creating a new company and for approving a pending one.
/// In both cases an optional login account can be provisioned.
class _CompanyDialog extends ConsumerStatefulWidget {
  const _CompanyDialog({this.approveCompany});

  /// When set, the dialog approves this existing (pending) company instead of
  /// creating a new one.
  final Company? approveCompany;

  @override
  ConsumerState<_CompanyDialog> createState() => _CompanyDialogState();
}

class _CompanyDialogState extends ConsumerState<_CompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  final _userId = TextEditingController();
  final _password = TextEditingController();

  bool _createLogin = true;
  bool _saving = false;
  String? _error;

  bool get _isApprove => widget.approveCompany != null;

  @override
  void initState() {
    super.initState();
    final c = widget.approveCompany;
    _name = TextEditingController(text: c?.name ?? '');
    _contact = TextEditingController(text: c?.contactPerson ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _address = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _address.dispose();
    _userId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final companyRepo = ref.read(companyRepositoryProvider);
    final adminId = ref.read(appUserProvider).value?.id;

    try {
      if (_isApprove) {
        // Approving an existing pending company.
        final companyId = widget.approveCompany!.id;
        await companyRepo.update(companyId, {
          'name': _name.text.trim(),
          'contact_person': _contact.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'approval': ApprovalStatus.approved.name,
        });

        if (_createLogin) {
          final uid = await ref.read(userProvisioningProvider).createAccount(
                name: _name.text.trim(),
                userId: _userId.text.trim(),
                phone: _phone.text.trim(),
                password: _password.text.trim(),
                role: UserRole.company,
                companyId: companyId,
                createdBy: adminId,
              );
          await companyRepo.setOwner(companyId, uid);
        }
      } else {
        // New company: atomic RPC handles company + optional login.
        await ref.read(userProvisioningProvider).createCompanyAccount(
              name: _name.text.trim(),
              contactPerson: _contact.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
              createLogin: _createLogin,
              userId: _createLogin ? _userId.text.trim() : null,
              password: _createLogin ? _password.text.trim() : null,
              createdBy: adminId,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isApprove
                  ? 'Company approved'
                  : 'Company created')),
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
      title: Text(_isApprove ? 'Approve Company' : 'Add Company'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Company Name', required: true),
              _field(_contact, 'Contact Person'),
              _field(_phone, 'Phone', keyboard: TextInputType.phone),
              _field(_address, 'Address', maxLines: 2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Create login account'),
                subtitle: const Text('Lets the company sign in to the portal'),
                value: _createLogin,
                onChanged: (v) => setState(() => _createLogin = v),
              ),
              if (_createLogin) ...[
                _field(_userId, 'User ID (alphanumeric)',
                    alphanumeric: true, min: 3, required: true),
                _field(_password, 'Temporary Password',
                    obscure: true, min: 6),
              ],
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
              : Text(_isApprove ? 'Approve' : 'Create'),
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
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final value = (v ?? '').trim();
          if (required && value.isEmpty) return 'Required';
          if (alphanumeric) {
            if (value.isEmpty) return 'Required';
            if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(value)) {
              return 'Use letters, numbers, and _ or -';
            }
          }
          if (min != null) {
            if (value.isEmpty) return 'Required';
            if (value.length < min) return 'At least $min characters';
          }
          return null;
        },
      ),
    );
  }
}
