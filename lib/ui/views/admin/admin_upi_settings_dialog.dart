import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/master_data.dart';
import '../../../core/providers/repository_providers.dart';

/// Admin dialog to configure the vendor UPI ID, business name, and payment parameters.
/// Shows a live QR barcode preview that matches what clients see on payment requests.
class AdminUpiSettingsDialog extends ConsumerStatefulWidget {
  const AdminUpiSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AdminUpiSettingsDialog(),
    );
  }

  @override
  ConsumerState<AdminUpiSettingsDialog> createState() =>
      _AdminUpiSettingsDialogState();
}

class _AdminUpiSettingsDialogState
    extends ConsumerState<AdminUpiSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _upiIdController;
  late final TextEditingController _payeeNameController;
  late final TextEditingController _noteController;

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    _payeeNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initFields(AdminUpiConfig config) {
    if (_initialized) return;
    _upiIdController = TextEditingController(text: config.upiId);
    _payeeNameController = TextEditingController(text: config.payeeName);
    _noteController =
        TextEditingController(text: config.defaultNote ?? 'Chai Subscription Settlement');
    _upiIdController.addListener(() => setState(() {}));
    _payeeNameController.addListener(() => setState(() {}));
    _noteController.addListener(() => setState(() {}));
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final upiConfigAsync = ref.watch(adminUpiConfigProvider);

    return upiConfigAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AlertDialog(
        title: const Text('Error loading UPI config'),
        content: Text('$e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (config) {
        _initFields(config);

        final previewConfig = AdminUpiConfig(
          upiId: _upiIdController.text.trim().isEmpty
              ? config.upiId
              : _upiIdController.text.trim(),
          payeeName: _payeeNameController.text.trim().isEmpty
              ? config.payeeName
              : _payeeNameController.text.trim(),
          defaultNote: _noteController.text.trim().isEmpty
              ? config.defaultNote
              : _noteController.text.trim(),
        );
        final sampleUri = previewConfig.buildUpiUri(amount: 500);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: const Color(0xFFFAFAF9),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF06030).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFFF06030),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vendor UPI Settings',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E2530),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Clients scan this barcode to pay bills',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Barcode Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'LIVE QR BARCODE PREVIEW',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF06030).withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: QrImageView(
                                data: sampleUri,
                                version: QrVersions.auto,
                                size: 150,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF1E2530),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF1E2530),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            previewConfig.payeeName,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1E2530),
                            ),
                          ),
                          Text(
                            previewConfig.upiId,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF06030),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // UPI ID Field
                    TextFormField(
                      controller: _upiIdController,
                      decoration: InputDecoration(
                        labelText: 'Admin UPI Address (VPA)',
                        hintText: 'e.g. merchant@okhdfcbank or vendor@upi',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a valid UPI address';
                        }
                        if (!val.contains('@')) {
                          return 'UPI address must contain @ (e.g. id@bank)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Payee Name Field
                    TextFormField(
                      controller: _payeeNameController,
                      decoration: InputDecoration(
                        labelText: 'Business / Payee Display Name',
                        hintText: 'e.g. Indore Chai Company',
                        prefixIcon: const Icon(Icons.storefront_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the payee name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Default Note Field
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Default Payment Note',
                        hintText: 'e.g. Chai Subscription Settlement',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Save Button
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF06030),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _saving = true);
                              try {
                                final updated = AdminUpiConfig(
                                  upiId: _upiIdController.text.trim(),
                                  payeeName: _payeeNameController.text.trim(),
                                  defaultNote: _noteController.text.trim(),
                                );
                                await ref
                                    .read(masterDataRepositoryProvider)
                                    .saveUpiConfig(updated);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UPI configuration updated'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error saving: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save UPI Info',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
