import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ShareService {
  static final ShareService instance = ShareService._init();
  ShareService._init();

  // الدوال المطلوبة المضافة
  Future<void> shareInvoiceAsText(Invoice invoice) async {
    try {
      final text = _generateInvoiceText(invoice);
      
      await Share.share(
        text,
        subject: 'فاتورة رقم ${invoice.invoiceNumber}',
      );
    } catch (e) {
      print('خطأ في مشاركة نص الفاتورة: $e');
      rethrow;
    }
  }

  Future<void> shareInvoiceAsPDF(Invoice invoice) async {
    try {
      final pdf = await _generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'فاتورة رقم ${invoice.invoiceNumber}',
        text: 'مرفق فاتورة رقم ${invoice.invoiceNumber} للزبون ${invoice.customerName}',
      );
      
      // حذف الملف المؤقت
      file.delete();
    } catch (e) {
      print('خطأ في مشاركة PDF الفاتورة: $e');
      rethrow;
    }
  }

  Future<void> shareToWhatsApp(Invoice invoice) async {
    try {
      final text = _generateInvoiceText(invoice);
      final whatsappText = Uri.encodeComponent(text);
      final whatsappUrl = 'https://wa.me/?text=$whatsappText';
      
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        // إذا لم ينجح فتح WhatsApp، شارك النص عادياً
        await Share.share(
          text,
          subject: 'فاتورة رقم ${invoice.invoiceNumber}',
        );
      }
    } catch (e) {
      print('خطأ في مشاركة واتساب: $e');
      // في حالة الخطأ، شارك النص عادياً
      final text = _generateInvoiceText(invoice);
      await Share.share(
        text,
        subject: 'فاتورة رقم ${invoice.invoiceNumber}',
      );
    }
  }

  // الدالة الأصلية للمشاركة مع PDF
  Future<void> shareInvoice(Invoice invoice) async {
    await shareInvoiceAsPDF(invoice);
  }

  Future<void> shareCustomerStatement(String customerName, List<Invoice> invoices) async {
    try {
      final pdf = await _generateStatementPDF(customerName, invoices);
      final bytes = await pdf.save();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/statement_${customerName.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'كشف حساب ${customerName}',
        text: 'مرفق كشف حساب للزبون ${customerName}',
      );
      
      // حذف الملف المؤقت
      file.delete();
    } catch (e) {
      print('خطأ في مشاركة كشف الحساب: $e');
      rethrow;
    }
  }

  // دالة لتوليد نص الفاتورة
  String _generateInvoiceText(Invoice invoice) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== ${AppConstants.appName} ===');
    buffer.writeln('فاتورة رقم: ${invoice.invoiceNumber}');
    buffer.writeln('التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}');
    buffer.writeln();
    
    buffer.writeln('بيانات الزبون:');
    buffer.writeln('الاسم: ${invoice.customerName}');
    if (invoice.customerPhone != null && invoice.customerPhone!.isNotEmpty) {
      buffer.writeln('الهاتف: ${invoice.customerPhone}');
    }
    if (invoice.customerAddress != null && invoice.customerAddress!.isNotEmpty) {
      buffer.writeln('العنوان: ${invoice.customerAddress}');
    }
    buffer.writeln();
    
    buffer.writeln('المنتجات:');
    buffer.writeln('-' * 50);
    
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      buffer.writeln('${i + 1}. ${item.productName}');
      buffer.writeln('   الكمية: ${item.quantity} × السعر: ${Helpers.formatCurrency(item.price)} = ${Helpers.formatCurrency(item.total)}');
      buffer.writeln();
    }
    
    buffer.writeln('-' * 50);
    buffer.writeln('مجموع الفاتورة: ${Helpers.formatCurrency(invoice.total)}');
    
    if (invoice.previousBalance > 0) {
      buffer.writeln('الحساب السابق: ${Helpers.formatCurrency(invoice.previousBalance)}');
      buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}');
    }
    
    if (invoice.amountPaid > 0) {
      buffer.writeln('المبلغ المدفوع: ${Helpers.formatCurrency(invoice.amountPaid)}');
      buffer.writeln('المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
    }
    
    buffer.writeln();
    buffer.writeln('شكراً لتعاملكم معنا - ${AppConstants.appName}');
    
    return buffer.toString();
  }

  Future<pw.Document> _generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();
    
    // استخدام خطوط متاحة في PDF
    final font = await pw.Font.ttf(await rootBundle.load('packages/pdf/fonts/ttf/Roboto-Regular.ttf'));
    final fontBold = await pw.Font.ttf(await rootBundle.load('packages/pdf/fonts/ttf/Roboto-Bold.ttf'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(invoice),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(invoice),
              pw.SizedBox(height: 20),
              _buildProductsTable(invoice),
              pw.SizedBox(height: 20),
              _buildTotals(invoice),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.Document> _generateStatementPDF(String customerName, List<Invoice> invoices) async {
    final pdf = pw.Document();
    
    final font = await pw.Font.ttf(await rootBundle.load('packages/pdf/fonts/ttf/Roboto-Regular.ttf'));
    final fontBold = await pw.Font.ttf(await rootBundle.load('packages/pdf/fonts/ttf/Roboto-Bold.ttf'));
    
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.totalWithPrevious);
    final paidAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
    final remainingAmount = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          return [
            _buildStatementHeader(customerName),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            _buildAccountSummary(totalAmount, paidAmount, remainingAmount),
            pw.SizedBox(height: 30),
            _buildInvoicesTable(invoices),
            pw.SizedBox(height: 30),
            _buildSignature(),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInvoiceHeader(Invoice invoice) {
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

  pw.Widget _buildCustomerInfo(Invoice invoice) {
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

  pw.Widget _buildProductsTable(Invoice invoice) {
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

  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('مجموع الفاتورة:', invoice.total, isMain: false),
          if (invoice.previousBalance > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('الحساب السابق:', invoice.previousBalance, isMain: false),
          ],
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
          _buildTotalRow('الإجمالي الكلي:', invoice.totalWithPrevious, isMain: true),
          if (invoice.amountPaid > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('المبلغ الواصل:', invoice.amountPaid, isMain: false),
            pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
            _buildTotalRow('المتبقي:', invoice.remainingBalance, isMain: true),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isMain = false}) {
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

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'شكراً لتعاملكم معنا - ${AppConstants.appName}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildStatementHeader(String customerName) {
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

  pw.Widget _buildAccountSummary(double total, double paid, double remaining) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(children: [
        pw.Text('ملخص الحساب', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 15),
        _buildTotalRow('الإجمالي الكلي:', total, isMain: false),
        pw.SizedBox(height: 8),
        _buildTotalRow('المبالغ المدفوعة:', paid, isMain: false),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
        _buildTotalRow('المتبقي:', remaining, isMain: true),
      ]),
    );
  }

  pw.Widget _buildInvoicesTable(List<Invoice> invoices) {
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

  pw.Widget _buildSignature() {
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
