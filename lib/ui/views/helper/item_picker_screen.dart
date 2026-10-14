import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/item_request.dart';
import '../../../core/models/payment.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/sales_product_card.dart';
import '../../widgets/status_views.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9');

/// Result returned from [ItemPickerScreen].
class ItemPickerResult {
  final List<RequestLine> items;
  final PaymentMode paymentMode;
  final PaymentMethod? method;

  const ItemPickerResult({
    required this.items,
    required this.paymentMode,
    this.method,
  });

  double get total => items.fold(0, (acc, i) => acc + i.total);
}

/// Full-screen product picker with quantity steppers and payment options.
/// Used for distributing goods (immediate payment option) and for recording
/// on-visit item requests.
class ItemPickerScreen extends ConsumerStatefulWidget {
  const ItemPickerScreen({
    super.key,
    required this.title,
    this.requireImmediatePayment = false,
    this.confirmLabel = 'Confirm',
    this.initialQuantities,
    this.initialMode,
    this.lockAddToBill = false,
  });

  final String title;

  /// When true, shows the cash/UPI method selector when "Pay now" is chosen
  /// (used for distributing goods). Requests settle later, so it's false there.
  final bool requireImmediatePayment;
  final String confirmLabel;

  /// When true, forces [PaymentMode.addToBill] and hides the pay-now / add-to-bill
  /// selector entirely — the company-sale flow always bills the client, so there
  /// is no payment UI to show. Defaults to false, preserving the existing
  /// pay-now/add-to-bill choice for every other caller.
  final bool lockAddToBill;

  /// Pre-selected quantities keyed by product id. Set when delivering an
  /// already-approved request, so the employee opens the picker with the
  /// requested basket loaded and only adjusts it if something changed at
  /// the door.
  final Map<dynamic, int>? initialQuantities;

  /// Payment mode to open on, when the request already chose one.
  final PaymentMode? initialMode;

  @override
  ConsumerState<ItemPickerScreen> createState() => _ItemPickerScreenState();
}

class _ItemPickerScreenState extends ConsumerState<ItemPickerScreen> {
  late final Map<dynamic, int> _qty = {...?widget.initialQuantities};
  late PaymentMode _mode = widget.lockAddToBill
      ? PaymentMode.addToBill
      : (widget.initialMode ?? PaymentMode.payNow);
  PaymentMethod _method = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(message: '$e'),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No products available.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final qty = _qty[p.id] ?? 0;
              return SalesProductCard(
                product: p,
                quantity: qty,
                currency: _currency,
                showPresets: true,
                onQuantityChanged: (newQty) =>
                    setState(() => _qty[p.id] = newQty),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context, productsAsync.value ?? []),
    );
  }

  Widget _buildBottomBar(BuildContext context, List products) {
    final lines = _linesFrom(products);
    final total = lines.fold<double>(0, (acc, l) => acc + l.total);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.lockAddToBill)
              SegmentedButton<PaymentMode>(
                segments: const [
                  ButtonSegment(
                      value: PaymentMode.payNow,
                      label: Text('Pay now'),
                      icon: Icon(Icons.payments_outlined)),
                  ButtonSegment(
                      value: PaymentMode.addToBill,
                      label: Text('Add to bill'),
                      icon: Icon(Icons.receipt_long_outlined)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            if (widget.requireImmediatePayment &&
                _mode == PaymentMode.payNow) ...[
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(value: PaymentMethod.cash, label: Text('Cash')),
                  ButtonSegment(value: PaymentMethod.upi, label: Text('UPI')),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                Text(_currency.format(total),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: lines.isEmpty
                  ? null
                  : () => Navigator.pop(
                        context,
                        ItemPickerResult(
                          items: lines,
                          paymentMode: _mode,
                          method: widget.requireImmediatePayment &&
                                  _mode == PaymentMode.payNow
                              ? _method
                              : null,
                        ),
                      ),
              child: Text(widget.confirmLabel),
            ),
          ],
        ),
      ),
    );
  }

  List<RequestLine> _linesFrom(List products) {
    final lines = <RequestLine>[];
    for (final p in products) {
      final qty = _qty[p.id] ?? 0;
      if (qty > 0) {
        lines.add(RequestLine(
          productId: p.id,
          name: p.name,
          qty: qty,
          price: p.price,
          unit: p.unit,
        ));
      }
    }
    return lines;
  }
}
