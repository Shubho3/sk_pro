import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/invoice.dart';
import '../../../core/providers/repository_providers.dart';
import '../helper/item_picker_screen.dart';
import 'upi_payment_dialog.dart';

/// Company raises an item request (choose pay-on-delivery or add-to-bill).
Future<void> raiseCompanyRequestFlow(
  BuildContext context,
  WidgetRef ref, {
  required dynamic companyId,
  required String companyName,
}) async {
  final result = await Navigator.of(context).push<ItemPickerResult>(
    MaterialPageRoute(
      builder: (_) => const ItemPickerScreen(
        title: 'Request items',
        confirmLabel: 'Send request',
      ),
    ),
  );
  if (result == null || result.items.isEmpty) return;
  await ref.read(distributionServiceProvider).raiseCompanyRequest(
        companyId: companyId,
        companyName: companyName,
        items: result.items,
        paymentMode: result.paymentMode,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent')),
    );
  }
}

/// Company records a payment using the UPI payment screen with QR code.
Future<void> payBillFlow(
  BuildContext context,
  WidgetRef ref, {
  required dynamic companyId,
  required String companyName,
  required double outstanding,
  dynamic invoiceId,
  String? invoiceMonth,
}) async {
  if (outstanding <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account is already fully settled!')),
    );
    return;
  }
  dynamic resolvedInvoiceId = invoiceId;
  String? resolvedMonth = invoiceMonth;

  if (resolvedInvoiceId == null) {
    try {
      final invList =
          ref.read(companyInvoicesProvider(companyId)).value ?? [];
      final unpaid = invList
          .where((i) => i.status != InvoiceStatus.paid && i.balance > 0)
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month));
      if (unpaid.isNotEmpty) {
        resolvedInvoiceId = unpaid.first.id;
        resolvedMonth ??= unpaid.first.month;
      }
    } catch (_) {}
  }

  await UpiPaymentDialog.show(
    context,
    companyId: companyId,
    companyName: companyName,
    amount: outstanding,
    invoiceId: resolvedInvoiceId,
    invoiceMonth: resolvedMonth,
  );
}
