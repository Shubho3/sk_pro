import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/company.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import 'company_sale_screen.dart';
import 'walkin_sale_screen.dart';

/// Employee home: quick sale actions (Scheduled Work / Walk-in Sale).
class HelperHomeView extends ConsumerWidget {
  const HelperHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(employeePaymentsProvider(user.uid));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            'Hello, ${user.name}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2530),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 28),

          // Primary Actions: Scheduled Work & Walk-in Sale
          _ActionCard(
            title: 'Scheduled Work',
            subtitle: 'Deliver tea & snacks on corporate route; added to client subscription',
            icon: Icons.storefront_rounded,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const CompanySaleScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            title: 'Walk-in Sale',
            subtitle: 'Direct counter orders with instant payment',
            icon: Icons.point_of_sale_rounded,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const WalkInSaleScreen(),
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Subtle secondary action for client onboarding
          Center(
            child: TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _AddCompanyDialog(employee: user),
              ),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text(
                'Register a new client company',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets an employee submit a new company; it is created with `pending` approval
/// for an admin to review.
class _AddCompanyDialog extends ConsumerStatefulWidget {
  const _AddCompanyDialog({required this.employee});
  final AppUser employee;

  @override
  ConsumerState<_AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends ConsumerState<_AddCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(companyRepositoryProvider).create(
            Company(
              id: 0,
              name: _name.text.trim(),
              contactPerson: _contact.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
              approval: ApprovalStatus.pending,
              createdBy: widget.employee.id,
            ),
          );
      await ref.read(notificationRepositoryProvider).create(
            AppNotification(
              id: 0,
              toRole: UserRole.admin.name,
              title: 'Company approval needed',
              body: '${widget.employee.name} submitted "${_name.text.trim()}".',
              type: 'approval',
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for admin approval')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register Company'),
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
              : const Text('Submit'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}

/// Prominent tappable action tile on the employee home (Company / Walk-in sale).
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFF06030).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF06030).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFF06030), size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2530),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
