import 'dart:io';
import 'package:flutter/services.dart'; // ==== تم إضافة هذا السطر ====
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ShareService {
  static final ShareService instance = ShareService._init();
  ShareService._init();

  Future<void> shareInvoiceAsText(Invoice invoice) async {
    final text = _formatInvoiceText(invoice);
    await Share.share(text, subject: 'فاتورة رقم ${invoice.invoiceNumber}');
  }

  Future<void> shareInvoiceAsPDF(Invoice invoice) async {
    try {
      final pdf = await _generateInvoicePDF(invoice);
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/فاتورة_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'فاتورة رقم ${invoice.invoiceNumber}',
        text: 'فاتورة ${invoice.customerName}',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة الفاتورة: $e');
    }
  }

  Future<void> shareToWhatsApp(Invoice invoice, {String? phoneNumber}) async {
    final text = _formatInvoiceText(invoice);
    await Share.share(text);
  }

  Future<void> shareCustomerStatement(String customerName, List<Invoice> invoices) async {
    final text = _formatCustomerStatementText(customerName, invoices);
    await Share.share(text, subject: 'كشف حساب $customerName');
  }

  Future<void> shareCustomerStatementAsPDF(String customerName, List<Invoice> invoices) async {
    try {
      final pdf = await _generateStatementPDF(customerName, invoices);
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/كشف_حساب_$customerName.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'كشف حساب $customerName',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة كشف الحساب: $e');
    }
  }

  String _formatInvoiceText(Invoice invoice) {
    // ... محتوى هذه الدالة يبقى كما هو ...
    final buffer = StringBuffer();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 ${AppConstants.appName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    buffer.writeln('🔢 رقم الفاتورة: ${invoice.invoiceNumber}');
    buffer.writeln('👤 اسم الزبون: ${invoice.customerName}');
    buffer.writeln('📅 التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}\n');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 المنتجات:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      buffer.writeln('${i + 1}. ${item.productName}');
      buffer.writeln('   الكمية: ${Helpers.formatNumber(item.quantity)} × السعر: ${Helpers.formatCurrency(item.price)} = ${Helpers.formatCurrency(item.total)}');
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('   ملاحظة: ${item.notes}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 الحسابات:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('مجموع الفاتورة: ${Helpers.formatCurrency(invoice.total)}');
    
    if (invoice.previousBalance > 0) {
      buffer.writeln('الحساب السابق: ${Helpers.formatCurrency(invoice.previousBalance)}');
      buffer.writeln('─────────────────────────');
      buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}');
    }
    
    if (invoice.amountPaid > 0) {
      buffer.writeln('المبلغ الواصل: ${Helpers.formatCurrency(invoice.amountPaid)}');
      buffer.writeln('─────────────────────────');
    }
    buffer.writeln('💰💰 المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
    
    if (invoice.notes != null && invoice.notes!.isNotEmpty) {
      buffer.writeln('\n📝 ملاحظات: ${invoice.notes}');
    }
    
    buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا ✨');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return buffer.toString();
  }

  String _formatCustomerStatementText(String customerName, List<Invoice> invoices) {
    // ... محتوى هذه الدالة يبقى كما هو ...
    final buffer = StringBuffer();
    
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.totalWithPrevious);
    final paidAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
    final remainingAmount = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 كشف حساب');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    buffer.writeln('👤 اسم الزبون: $customerName');
    buffer.writeln('📅 التاريخ: ${Helpers.formatDate(DateTime.now())}');
    buffer.writeln('📄 عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}\n');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 ملخص الحساب:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(totalAmount)}');
    buffer.writeln('المبالغ المدفوعة: ${Helpers.formatCurrency(paidAmount)}');
    buffer.writeln('─────────────────────────');
    buffer.writeln('💰 المتبقي: ${Helpers.formatCurrency(remainingAmount)}\n');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 تفاصيل الفواتير:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (var i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      buffer.writeln('\n${i + 1}. فاتورة #${invoice.invoiceNumber}');
      buffer.writeln('   التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}');
      buffer.writeln('   الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}');
      buffer.writeln('   المدفوع: ${Helpers.formatCurrency(invoice.amountPaid)}');
      buffer.writeln('   المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
      buffer.writeln('   الحالة: ${invoice.status}');
    }
    
    buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا ✨\n${AppConstants.appName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return buffer.toString();
  }

  // ==== تم تعديل هذه الدالة بالكامل ====
  Future<pw.Document> _generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();
    
    // استخدام الخطوط المحلية المحملة مع التطبيق
    final fontData = await rootBundle.load('asset/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    
    final fontDataBold = await rootBundle.load('asset/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (context) {
          // يمكنك لاحقاً إضافة تصميم كامل هنا مشابه لـ PrintService
          return pw.Center(
            child: pw.Text('فاتورة رقم ${invoice.invoiceNumber}'),
          );
        },
      ),
    );
    return pdf;
  }

  // ==== تم تعديل هذه الدالة بالكامل ====
  Future<pw.Document> _generateStatementPDF(String customerName, List<Invoice> invoices) async {
    final pdf = pw.Document();
    
    // استخدام الخطوط المحلية المحملة مع التطبيق
    final fontData = await rootBundle.load('asset/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    
    final fontDataBold = await rootBundle.load('asset/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (context) => pw.Center(
          child: pw.Text('كشف حساب $customerName'),
        ),
      ),
    );
    return pdf;
  }
}
