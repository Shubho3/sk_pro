import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/item_request.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../widgets/sales_product_card.dart';
import '../../widgets/status_views.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

/// Companyless counter sale: pick items, collect cash/UPI now. No bill, no
/// outstanding, no request document — just stock out and one point-of-sale
/// payment. An optional customer name is stored on the payment for the record.
class WalkInSaleScreen extends ConsumerStatefulWidget {
  const WalkInSaleScreen({super.key});

  @override
  ConsumerState<WalkInSaleScreen> createState() => _WalkInSaleScreenState();
}

class _WalkInSaleScreenState extends ConsumerState<WalkInSaleScreen> {
  final _name = TextEditingController();
  final Map<dynamic, int> _qty = {};
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<RequestLine> _linesFrom(List<Product> products) {
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

  Future<void> _confirm(List<Product> products) async {
    final lines = _linesFrom(products);
    if (lines.isEmpty) return;

    final uid = ref.read(appUserProvider).value?.uid;
    if (uid == null) return;

    final total = lines.fold<double>(0, (acc, l) => acc + l.total);
    setState(() => _saving = true);
    try {
      await ref.read(distributionServiceProvider).recordWalkInSale(
            employeeId: uid,
            items: lines,
            method: _method,
            customerName: _name.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Walk-in sale recorded — ${_currency.format(total)} collected'),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Walk-in sale')),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Customer name (optional)',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: _name.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _name.clear()),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ['Walk-in', 'Counter', 'Staff', 'Guest', 'Takeaway']
                    .map((preset) => ActionChip(
                          label: Text(preset, style: const TextStyle(fontSize: 12)),
                          avatar: const Icon(Icons.touch_app, size: 14),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _name.text = preset;
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              for (final p in products)
                SalesProductCard(
                  product: p,
                  quantity: _qty[p.id] ?? 0,
                  currency: _currency,
                  showPresets: true,
                  onQuantityChanged: (newQty) =>
                      setState(() => _qty[p.id] = newQty),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          _buildBottomBar(context, productsAsync.value ?? const []),
    );
  }

  Widget _buildBottomBar(BuildContext context, List<Product> products) {
    final lines = _linesFrom(products);
    final total = lines.fold<double>(0, (acc, l) => acc + l.total);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('Cash'),
                    icon: Icon(Icons.payments_outlined)),
                ButtonSegment(
                    value: PaymentMethod.upi,
                    label: Text('UPI'),
                    icon: Icon(Icons.qr_code)),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
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
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: (lines.isEmpty || _saving)
                  ? null
                  : () => _confirm(products),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm sale'),
            ),
          ],
        ),
      ),
    );
  }
}
