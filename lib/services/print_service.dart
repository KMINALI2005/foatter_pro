import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class PrintService {
  static final PrintService instance = PrintService._init();
  PrintService._init();

  Future<void> printInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.helvetica();
    final fontBold = await PdfGoogleFonts.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(invoice, fontBold),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(invoice, font, fontBold),
              pw.SizedBox(height: 20),
              _buildProductsTable(invoice, font, fontBold),
              pw.SizedBox(height: 20),
              _buildTotals(invoice, font, fontBold),
              pw.Spacer(),
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'فاتورة_${invoice.invoiceNumber}.pdf',
    );
  }

  Future<void> printCustomerStatement(String customerName, List<Invoice> invoices) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.helvetica();
    final fontBold = await PdfGoogleFonts.helveticaBold();
    
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.totalWithPrevious);
    final paidAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
    final remainingAmount = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            _buildStatementHeader(customerName, fontBold),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            _buildAccountSummary(totalAmount, paidAmount, remainingAmount, font, fontBold),
            pw.SizedBox(height: 30),
            _buildInvoicesTable(invoices, font, fontBold),
            pw.SizedBox(height: 30),
            _buildSignature(font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'كشف_حساب_$customerName.pdf',
    );
  }

  pw.Widget _buildInvoiceHeader(Invoice invoice, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10b981'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(AppConstants.appName, 
            style: pw.TextStyle(fontSize: 24, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('فاتورة رقم: ${invoice.invoiceNumber}', 
            style: pw.TextStyle(fontSize: 16, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#d1fae5')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('اسم الزبون:', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 5),
            pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('التاريخ:', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 5),
            pw.Text(Helpers.formatDate(invoice.invoiceDate, useArabic: false), 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  pw.Widget _buildProductsTable(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#d1fae5')),
      headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#ecfdf5')),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['المنتج', 'الكمية', 'السعر', 'الإجمالي'],
      data: invoice.items.map((item) => [
        item.productName,
        Helpers.formatNumber(item.quantity, useArabic: false),
        Helpers.formatCurrency(item.price, useArabic: false),
        Helpers.formatCurrency(item.total, useArabic: false),
      ]).toList(),
    );
  }

  pw.Widget _buildTotals(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('مجموع الفاتورة:', invoice.total, font, fontBold),
          if (invoice.previousBalance > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('الحساب السابق:', invoice.previousBalance, font, fontBold),
          ],
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
          _buildTotalRow('الإجمالي الكلي:', invoice.totalWithPrevious, font, fontBold, isMain: true),
          if (invoice.amountPaid > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('المبلغ الواصل:', invoice.amountPaid, font, fontBold),
            pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
            _buildTotalRow('المتبقي:', invoice.remainingBalance, font, fontBold, isMain: true),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, pw.Font font, pw.Font fontBold, {bool isMain = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(
          fontSize: isMain ? 14 : 12, 
          fontWeight: isMain ? pw.FontWeight.bold : pw.FontWeight.normal
        )),
        pw.Text(
          Helpers.formatCurrency(amount, useArabic: false),
          style: pw.TextStyle(
            fontSize: isMain ? 16 : 12,
            fontWeight: pw.FontWeight.bold,
            color: isMain ? PdfColor.fromHex('#10b981') : null,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Font font) {
    return pw.Center(
      child: pw.Text(
        'شكراً لتعاملكم معنا - ${AppConstants.appName}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildStatementHeader(String customerName, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10b981'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('كشف حساب', 
          style: pw.TextStyle(fontSize: 24, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(customerName, 
          style: pw.TextStyle(fontSize: 18, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text('التاريخ: ${Helpers.formatDate(DateTime.now(), useArabic: false)}', 
          style: pw.TextStyle(fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  pw.Widget _buildAccountSummary(double total, double paid, double remaining, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(children: [
        pw.Text('ملخص الحساب', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 15),
        _buildTotalRow('الإجمالي الكلي:', total, font, fontBold),
        pw.SizedBox(height: 8),
        _buildTotalRow('المبالغ المدفوعة:', paid, font, fontBold),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
        _buildTotalRow('المتبقي:', remaining, font, fontBold, isMain: true),
      ]),
    );
  }

  pw.Widget _buildInvoicesTable(List<Invoice> invoices, pw.Font font, pw.Font fontBold) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#d1fae5')),
      headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#ecfdf5')),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headers: ['رقم الفاتورة', 'التاريخ', 'الإجمالي', 'المدفوع', 'المتبقي'],
      data: invoices.map((invoice) => [
        invoice.invoiceNumber,
        Helpers.formatDate(invoice.invoiceDate, useArabic: false),
        Helpers.formatCurrency(invoice.totalWithPrevious, useArabic: false),
        Helpers.formatCurrency(invoice.amountPaid, useArabic: false),
        Helpers.formatCurrency(invoice.remainingBalance, useArabic: false),
      ]).toList(),
    );
  }

  pw.Widget _buildSignature(pw.Font font) {
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('توقيع الزبون:', style: pw.TextStyle()),
        pw.SizedBox(height: 30),
        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide()))),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('توقيع المحاسب:', style: pw.TextStyle()),
        pw.SizedBox(height: 30),
        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide()))),
      ]),
    ]);
  }
}
