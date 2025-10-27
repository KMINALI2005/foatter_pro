import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class ShareService {
  static final ShareService instance = ShareService._init();
  ShareService._init();

  // مشاركة الفاتورة كنص
  Future<void> shareInvoiceAsText(Invoice invoice) async {
    final text = _formatInvoiceText(invoice);
    
    await Share.share(
      text,
      subject: 'فاتورة رقم ${invoice.invoiceNumber}',
    );
  }

  // مشاركة الفاتورة كـ PDF
  Future<void> shareInvoiceAsPDF(Invoice invoice) async {
    try {
      // إنشاء PDF
      final pdf = await _generateInvoicePDF(invoice);
      
      // حفظ PDF مؤقتاً
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/فاتورة_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // مشاركة الملف
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'فاتورة رقم ${invoice.invoiceNumber}',
        text: 'فاتورة ${invoice.customerName}',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة الفاتورة: $e');
    }
  }

  // مشاركة عبر WhatsApp
  Future<void> shareToWhatsApp(Invoice invoice, {String? phoneNumber}) async {
    final text = _formatInvoiceText(invoice);
    
    // إذا كان رقم الهاتف موجود، افتح محادثة مباشرة
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(text)}';
      
      await Share.share(text);
    } else {
      // مشاركة عامة
      await Share.share(text);
    }
  }

  // مشاركة كشف حساب زبون
  Future<void> shareCustomerStatement(
    String customerName,
    List<Invoice> invoices,
  ) async {
    final text = _formatCustomerStatementText(customerName, invoices);
    
    await Share.share(
      text,
      subject: 'كشف حساب $customerName',
    );
  }

  // مشاركة كشف حساب كـ PDF
  Future<void> shareCustomerStatementAsPDF(
    String customerName,
    List<Invoice> invoices,
  ) async {
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

  // تنسيق الفاتورة كنص
  String _formatInvoiceText(Invoice invoice) {
    final buffer = StringBuffer();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 ${AppConstants.appName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    buffer.writeln('🔢 رقم الفاتورة: ${invoice.invoiceNumber}');
    buffer.writeln('👤 اسم الزبون: ${invoice.customerName}');
    buffer.writeln('📅 التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}');
    buffer.writeln();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 المنتجات:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      buffer.writeln('${i + 1}. ${item.productName}');
      buffer.writeln('   الكمية: ${Helpers.formatNumber(item.quantity)}');
      buffer.writeln('   السعر: ${Helpers.formatCurrency(item.price)}');
      buffer.writeln('   الإجمالي: ${Helpers.formatCurrency(item.total)}');
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('   ملاحظة: ${item.notes}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 الحسابات:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('مجموع الفاتورة: ${Helpers.formatCurrency(invoice.total)}');
    
    if ((invoice.previousBalance ?? 0) > 0) {
      buffer.writeln('الحساب السابق: ${Helpers.formatCurrency(invoice.previousBalance ?? 0)}');
      buffer.writeln('─────────────────────────');
      buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(invoice.grandTotal)}');
    }
    
    if (invoice.amountPaid > 0) {
      buffer.writeln('المبلغ الواصل: ${Helpers.formatCurrency(invoice.amountPaid)}');
      buffer.writeln('─────────────────────────');
      buffer.writeln('المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
    }
    
    if (invoice.notes != null && invoice.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 ملاحظات: ${invoice.notes}');
    }
    
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا ✨');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return buffer.toString();
  }

  // تنسيق كشف حساب كنص
  String _formatCustomerStatementText(
    String customerName,
    List<Invoice> invoices,
  ) {
    final buffer = StringBuffer();
    
    // حساب الإجماليات
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final paidAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
    final remainingAmount = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 كشف حساب');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    buffer.writeln('👤 اسم الزبون: $customerName');
    buffer.writeln('📅 التاريخ: ${Helpers.formatDate(DateTime.now())}');
    buffer.writeln('📄 عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}');
    buffer.writeln();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 ملخص الحساب:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(totalAmount)}');
    buffer.writeln('المبالغ المدفوعة: ${Helpers.formatCurrency(paidAmount)}');
    buffer.writeln('─────────────────────────');
    buffer.writeln('💰 المتبقي: ${Helpers.formatCurrency(remainingAmount)}');
    buffer.writeln();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 تفاصيل الفواتير:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (var i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      buffer.writeln();
      buffer.writeln('${i + 1}. فاتورة #${invoice.invoiceNumber}');
      buffer.writeln('   التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}');
      buffer.writeln('   الإجمالي: ${Helpers.formatCurrency(invoice.grandTotal)}');
      buffer.writeln('   المدفوع: ${Helpers.formatCurrency(invoice.amountPaid)}');
      buffer.writeln('   المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
      buffer.writeln('   الحالة: ${invoice.status}');
    }
    
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا ✨');
    buffer.writeln('${AppConstants.appName}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return buffer.toString();
  }

  // إنشاء PDF للفاتورة
  Future<pw.Document> _generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();
    
    // محاولة تحميل الخط العربي (إن وجد)
    pw.Font? ttf;
    pw.Font? ttfBold;
    
    try {
      final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
      
      final fontDataBold = await rootBundle.load('fonts/Cairo-Bold.ttf');
      ttfBold = pw.Font.ttf(fontDataBold.buffer.asByteData());
    } catch (e) {
      // استخدام خط افتراضي
      ttf = null;
      ttfBold = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: ttf != null && ttfBold != null
            ? pw.ThemeData.withFont(base: ttf, bold: ttfBold)
            : null,
        build: (context) => pw.Center(
          child: pw.Text('فاتورة رقم ${invoice.invoiceNumber}'),
        ),
      ),
    );

    return pdf;
  }

  // إنشاء PDF لكشف الحساب
  Future<pw.Document> _generateStatementPDF(
    String customerName,
    List<Invoice> invoices,
  ) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Center(
          child: pw.Text('كشف حساب $customerName'),
        ),
      ),
    );

    return pdf;
  }
}
