import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/product.dart';
import 'quantity_stepper.dart';

/// A modern, responsive, and touch-friendly product card for sales and item picking.
///
/// Automatically adapts between horizontal row and vertical column on narrow viewports
/// so that titles, prices, stepper buttons, and quick preset chips never get cut off.
class SalesProductCard extends StatelessWidget {
  const SalesProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    this.currency,
    this.showPresets = true,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final NumberFormat? currency;
  final bool showPresets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = currency ?? NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isSelected = quantity > 0;
    final itemTotal = product.price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 340;

            final productInfo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${formatter.format(product.price)} / ${product.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formatter.format(itemTotal),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );

            final stepper = QuantityStepper(
              value: quantity,
              showPresets: showPresets,
              onChanged: onQuantityChanged,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  productInfo,
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: stepper,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: productInfo),
                const SizedBox(width: 10),
                stepper,
              ],
            );
          },
        ),
      ),
    );
  }
}
