import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/user_provisioning_service.dart';

enum AddTargetType { company, employee }

/// A unified dialog for Admin to add either a Company or an Employee.
/// Features a top dropdown/toggle to pick between Company and Employee.
class UnifiedAddDialog extends ConsumerStatefulWidget {
  const UnifiedAddDialog({
    super.key,
    this.initialType = AddTargetType.company,
  });

  final AddTargetType initialType;

  static Future<void> show(
    BuildContext context, {
    AddTargetType initialType = AddTargetType.company,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => UnifiedAddDialog(initialType: initialType),
    );
  }

  @override
  ConsumerState<UnifiedAddDialog> createState() => _UnifiedAddDialogState();
}

class _UnifiedAddDialogState extends ConsumerState<UnifiedAddDialog> {
  final _formKey = GlobalKey<FormState>();

  late AddTargetType _targetType;

  // Shared / Company Controllers
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Login / Employee Controllers
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createCompanyLogin = false;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _targetType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final admin = ref.read(appUserProvider).value;
    final adminId = admin?.id;

    try {
      if (_targetType == AddTargetType.company) {
        // Atomic RPC: creates company + optional login in one transaction.
        await ref.read(userProvisioningProvider).createCompanyAccount(
              name: _nameController.text.trim(),
              contactPerson: _contactController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              createLogin: _createCompanyLogin,
              userId: _createCompanyLogin ? _userIdController.text.trim() : null,
              password: _createCompanyLogin ? _passwordController.text.trim() : null,
              createdBy: adminId,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Company "${_nameController.text.trim()}" created successfully'),
            ),
          );
        }
      } else {
        // Employee
        await ref.read(userProvisioningProvider).createAccount(
              name: _nameController.text.trim(),
              userId: _userIdController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text.trim(),
              role: UserRole.employee,
              createdBy: adminId,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Employee account for "${_nameController.text.trim()}" created'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = UserProvisioningService.describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = _targetType == AddTargetType.company;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF06030).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompany ? Icons.business_rounded : Icons.person_add_rounded,
              color: const Color(0xFFF06030),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isCompany ? 'Add Company' : 'Add Employee',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown selector for entity type
                const Text(
                  'SELECT WHAT TO ADD',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AddTargetType>(
                      value: _targetType,
                      isExpanded: true,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1E2530),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AddTargetType.company,
                          child: Row(
                            children: [
                              Icon(Icons.business_rounded, color: Color(0xFFF06030), size: 18),
                              SizedBox(width: 8),
                              Text('Corporate Client / Company'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: AddTargetType.employee,
                          child: Row(
                            children: [
                              Icon(Icons.delivery_dining_rounded, color: Color(0xFF3B82F6), size: 18),
                              SizedBox(width: 8),
                              Text('Delivery Helper / Employee'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _targetType = val;
                                  _error = null;
                                });
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name Field (Company Name or Employee Name)
                _field(
                  _nameController,
                  isCompany ? 'Company Name *' : 'Full Name *',
                  required: true,
                  hintText: isCompany ? 'e.g. Acme Innovations Pvt Ltd' : 'e.g. Ramesh Kumar',
                ),

                if (isCompany) ...[
                  _field(_contactController, 'Contact Person Name', hintText: 'e.g. Sarah Jenkins'),
                  _field(_phoneController, 'Phone Number', keyboard: TextInputType.phone),
                  _field(_addressController, 'Office Address', maxLines: 2),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Provision Portal Login Account',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Allows company admin to view bills & place tea orders online',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: _createCompanyLogin,
                    activeThumbColor: const Color(0xFFF06030),
                    onChanged: _saving ? null : (v) => setState(() => _createCompanyLogin = v),
                  ),
                  if (_createCompanyLogin) ...[
                    _field(_userIdController, 'Company User ID (alphanumeric) *',
                        hintText: 'e.g. comp_tcs, infosys01',
                        alphanumeric: true, min: 3, required: true),
                    _field(_passwordController, 'Initial Password (min 6 chars) *',
                        obscure: true, min: 6, required: true),
                  ],
                ] else ...[
                  // Employee Fields
                  _field(_userIdController, 'Employee User ID (alphanumeric) *',
                      hintText: 'e.g. emp101, rahul_delivery',
                      alphanumeric: true, min: 3, required: true),
                  _field(_phoneController, 'Phone Number *',
                      keyboard: TextInputType.phone, required: true),
                  _field(_passwordController, 'Temporary Password (min 6 chars) *',
                      obscure: true, min: 6, required: true),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded, size: 16),
          label: Text(
            isCompany ? 'Create Company' : 'Create Employee',
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF06030),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hintText,
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
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: (v) {
          final trimmed = v?.trim() ?? '';
          if (required && trimmed.isEmpty) return 'This field is required';
          if (alphanumeric && trimmed.isNotEmpty && !RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(trimmed)) {
            return 'Use letters, numbers, and _ or -';
          }
          if (min != null && trimmed.length < min) {
            return 'Must be at least $min characters';
          }
          return null;
        },
      ),
    );
  }
}
