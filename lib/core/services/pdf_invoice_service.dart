import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';

/// Renders an [Invoice] to a PDF and opens the print/download/share sheet.
/// Works on web (browser print dialog) and mobile/desktop.
class PdfInvoiceService {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
  final _dateFmt = DateFormat('d MMM yyyy');

  /// The opaque logo variant — a PDF has no theme to show through, so the
  /// cream-backed cut is the right one here. Cached after the first render.
  pw.MemoryImage? _logo;

  Future<pw.MemoryImage> _loadLogo() async {
    final data = await rootBundle.load('assets/logo_doc.png');
    return _logo ??= pw.MemoryImage(data.buffer.asUint8List());
  }

  Future<Uint8List> build(Invoice invoice) async {
    final logo = await _loadLogo();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(logo, width: 54, height: 54),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Indore Chai Company',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Tax Invoice',
                          style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed to:',
                          style:
                              pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.companyName),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Period: ${invoice.month}'),
                      pw.Text('Status: ${invoice.status.name}'),
                      if (invoice.generatedAt != null)
                        pw.Text(
                            'Generated: ${_dateFmt.format(invoice.generatedAt!)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Unit', 'Total'],
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                data: [
                  for (final line in invoice.lines)
                    [
                      line.description,
                      '${line.qty}',
                      _currency.format(line.unitPrice),
                      _currency.format(line.total),
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${_currency.format(invoice.subtotal)}'),
                    pw.Text('Paid: ${_currency.format(invoice.paid)}'),
                    pw.Text('Balance: ${_currency.format(invoice.balance)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  Future<void> printOrShare(Invoice invoice) async {
    final bytes = await build(invoice);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'invoice_${invoice.companyName}_${invoice.month}.pdf',
    );
  }
}
