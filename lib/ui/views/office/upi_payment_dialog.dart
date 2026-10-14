import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/master_data.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/payment_request.dart';
import '../../../core/providers/repository_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

/// Modal dialog showing vendor UPI details, a dynamic QR barcode, direct UPI app redirect,
/// and settlement confirmation.
class UpiPaymentDialog extends ConsumerStatefulWidget {
  const UpiPaymentDialog({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.amount,
    this.invoiceId,
    this.invoiceMonth,
    this.paymentRequest,
    this.upiConfig,
  });

  final dynamic companyId;
  final String companyName;
  final double amount;
  final dynamic invoiceId;
  final String? invoiceMonth;
  final PaymentRequest? paymentRequest;
  final AdminUpiConfig? upiConfig;

  static Future<void> show(
    BuildContext context, {
    required dynamic companyId,
    required String companyName,
    required double amount,
    dynamic invoiceId,
    String? invoiceMonth,
    PaymentRequest? paymentRequest,
    AdminUpiConfig? upiConfig,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpiPaymentDialog(
        companyId: companyId,
        companyName: companyName,
        amount: amount,
        invoiceId: invoiceId,
        invoiceMonth: invoiceMonth,
        paymentRequest: paymentRequest,
        upiConfig: upiConfig,
      ),
    );
  }

  @override
  ConsumerState<UpiPaymentDialog> createState() => _UpiPaymentDialogState();
}

class _UpiPaymentDialogState extends ConsumerState<UpiPaymentDialog> {
  final TextEditingController _utrController = TextEditingController();
  bool _confirming = false;
  String? _statusMessage;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _launchUpiApp(String upiUri, String upiId) async {
    try {
      final uri = Uri.parse(upiUri);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: upiId));
        if (mounted) {
          setState(() {
            _statusMessage = 'UPI ID copied to clipboard! Paste in your UPI app.';
          });
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: upiId));
      if (mounted) {
        setState(() {
          _statusMessage = 'UPI ID copied to clipboard! Paste in your UPI app.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveConfigAsync = ref.watch(adminUpiConfigProvider);
    final config = widget.upiConfig ??
        liveConfigAsync.value ??
        const AdminUpiConfig();

    final cleanAmount = widget.amount;
    final upiUri = config.buildUpiUri(
      amount: cleanAmount,
      note: widget.invoiceMonth != null
          ? 'Chai Subscription ${widget.invoiceMonth}'
          : 'Chai Bill Settlement',
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFFFAFAF9),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF06030).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFFF06030),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UPI Payment',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2530),
                          ),
                        ),
                        Text(
                          widget.invoiceMonth != null
                              ? 'Settling ${widget.invoiceMonth} Bill'
                              : 'Corporate Account Settlement',
                          style: const TextStyle(
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
              const SizedBox(height: 18),

              // Amount Due Hero Pill
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2530),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _currency.format(cleanAmount),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // QR Code Barcode Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                          data: upiUri,
                          version: QrVersions.auto,
                          size: 175,
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
                    const SizedBox(height: 12),
                    Text(
                      config.payeeName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF1E2530),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // UPI ID with copy button
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: config.upiId));
                        setState(() {
                          _statusMessage = 'UPI ID copied to clipboard!';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              config.upiId,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF06030),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded,
                                size: 14, color: Color(0xFFF06030)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan with GPay, PhonePe, Paytm or any UPI app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ),

              // Button 1: Pay with UPI Application
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Pay via UPI App',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF06030),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                onPressed: () => _launchUpiApp(upiUri, config.upiId),
              ),
              const SizedBox(height: 12),

              // Optional UTR / Reference ID Field
              TextField(
                controller: _utrController,
                decoration: InputDecoration(
                  labelText: 'Transaction / UTR Ref (Optional)',
                  hintText: 'e.g. 12-digit UPI reference number',
                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Button 2: I Have Paid Confirmation
              OutlinedButton.icon(
                icon: _confirming
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'I Have Paid (Confirm)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  foregroundColor: const Color(0xFF047857),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                onPressed: _confirming
                    ? null
                    : () async {
                        setState(() => _confirming = true);
                        try {
                          final refId = _utrController.text.trim().isNotEmpty
                              ? _utrController.text.trim()
                              : null;

                          await ref
                              .read(distributionServiceProvider)
                              .payByCompany(
                                companyId: widget.companyId,
                                companyName: widget.companyName,
                                amount: cleanAmount,
                                method: PaymentMethod.upi,
                                invoiceId: widget.invoiceId,
                                transactionRef: refId,
                              );

                          if (widget.paymentRequest != null) {
                            await ref
                                .read(paymentRequestRepositoryProvider)
                                .markPaid(widget.paymentRequest!.id,
                                    transactionRef: refId);
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF10B981),
                                content: Text(
                                  'Payment of ${_currency.format(cleanAmount)} recorded successfully!',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving payment: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _confirming = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
