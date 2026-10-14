import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/payment_request.dart';
import 'upi_payment_dialog.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

/// Manages presentation of incoming payment requests across all corporate portal screens,
/// ensuring the dialogue is shown whether the client is on the homepage or any other tab.
class PaymentRequestPopup {
  static final Set<dynamic> dismissedRequestIds = {};
  static dynamic currentlyShowingId;

  static void checkAndShow(
    BuildContext context, {
    required List<PaymentRequest> pendingRequests,
    required dynamic companyId,
    required String companyName,
  }) {
    if (pendingRequests.isEmpty) return;
    final latest = pendingRequests.first;
    if (dismissedRequestIds.contains(latest.id) ||
        currentlyShowingId == latest.id) {
      return;
    }

    currentlyShowingId = latest.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      show(context,
          request: latest, companyId: companyId, companyName: companyName);
    });
  }

  static Future<void> show(
    BuildContext context, {
    required PaymentRequest request,
    required dynamic companyId,
    required String companyName,
  }) async {
    final payNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF06030).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFF06030),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Settlement Request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Admin has initiated a payment settlement request for $companyName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Billing Month',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          request.month,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount Due',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _currency.format(request.amount),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF06030),
                          ),
                        ),
                      ],
                    ),
                    if (request.note != null &&
                        request.note!.trim().isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              request.note!,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                color: Color(0xFF475569),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
                label: const Text('Pay with UPI / QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06030),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  dismissedRequestIds.add(request.id);
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text(
                  'Remind Me Later',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    currentlyShowingId = null;

    if (payNow == true && context.mounted) {
      await UpiPaymentDialog.show(
        context,
        companyId: companyId,
        companyName: companyName,
        amount: request.amount,
        invoiceId: request.invoiceId,
        invoiceMonth: request.month,
        paymentRequest: request,
      );
    }
  }
}
