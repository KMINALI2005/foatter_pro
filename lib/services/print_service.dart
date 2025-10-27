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

  // طباعة فاتورة واحدة
  Future<void> printInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    
    final fontDataBold = await rootBundle.load('fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // رأس الفاتورة
              _buildInvoiceHeader(invoice, ttfBold),
              
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              
              // معلومات الزبون
              _buildCustomerInfo(invoice, ttf, ttfBold),
              
              pw.SizedBox(height: 20),
              
              // جدول المنتجات
              _buildProductsTable(invoice, ttf, ttfBold),
              
              pw.SizedBox(height: 20),
              
              // الإجماليات
              _buildTotals(invoice, ttf, ttfBold),
              
              pw.Spacer(),
              
              // التذييل
              _buildFooter(ttf),
            ],
          );
        },
      ),
    );

    // طباعة أو معاينة
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'فاتورة_${invoice.invoiceNumber}.pdf',
    );
  }

  // طباعة كشف حساب زبون
  Future<void> printCustomerStatement(
    String customerName,
    List<Invoice> invoices,
  ) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    
    final fontDataBold = await rootBundle.load('fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold.buffer.asByteData());

    // حساب الإجماليات
    final totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);
    final paidAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
    final remainingAmount = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (context) {
          return [
            // رأس كشف الحساب
            _buildStatementHeader(customerName, ttfBold),
            
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            
            // ملخص الحساب
            _buildAccountSummary(
              totalAmount,
              paidAmount,
              remainingAmount,
              ttf,
              ttfBold,
            ),
            
            pw.SizedBox(height: 30),
            
            // جدول الفواتير
            _buildInvoicesTable(invoices, ttf, ttfBold),
            
            pw.SizedBox(height: 30),
            
            // التوقيع
            _buildSignature(ttf),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'كشف_حساب_$customerName.pdf',
    );
  }

  // رأس الفاتورة
  pw.Widget _buildInvoiceHeader(Invoice invoice, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10b981'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            AppConstants.appName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'فاتورة رقم: ${invoice.invoiceNumber}',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // معلومات الزبون
  pw.Widget _buildCustomerInfo(
    Invoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#d1fae5')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'اسم الزبون:',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'التاريخ:',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                Helpers.formatDate(invoice.invoiceDate, useArabic: false),
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // جدول المنتجات
  pw.Widget _buildProductsTable(
    Invoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#d1fae5')),
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ecfdf5')),
          children: [
            _buildTableCell('المنتج', boldFont, isHeader: true),
            _buildTableCell('الكمية', boldFont, isHeader: true),
            _buildTableCell('السعر', boldFont, isHeader: true),
            _buildTableCell('الإجمالي', boldFont, isHeader: true),
          ],
        ),
        // صفوف المنتجات
        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item.productName, font),
              _buildTableCell(
                Helpers.formatNumber(item.quantity, useArabic: false),
                font,
              ),
              _buildTableCell(
                Helpers.formatCurrency(item.price, useArabic: false),
                font,
              ),
              _buildTableCell(
                Helpers.formatCurrency(item.total, useArabic: false),
                font,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // خلية الجدول
  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // الإجماليات
  pw.Widget _buildTotals(
    Invoice invoice,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow(
            'مجموع الفاتورة:',
            invoice.total,
            font,
            boldFont,
          ),
          if ((invoice.previousBalance ?? 0) > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow(
              'الحساب السابق:',
              invoice.previousBalance ?? 0,
              font,
              boldFont,
            ),
          ],
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
          _buildTotalRow(
            'الإجمالي الكلي:',
            invoice.grandTotal,
            font,
            boldFont,
            isMain: true,
          ),
          if (invoice.amountPaid > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow(
              'المبلغ الواصل:',
              invoice.amountPaid,
              font,
              boldFont,
            ),
            pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
            _buildTotalRow(
              'المتبقي:',
              invoice.remainingBalance,
              font,
              boldFont,
              isMain: true,
            ),
          ],
        ],
      ),
    );
  }

  // صف الإجمالي
  pw.Widget _buildTotalRow(
    String label,
    double amount,
    pw.Font font,
    pw.Font boldFont, {
    bool isMain = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: isMain ? boldFont : font,
            fontSize: isMain ? 14 : 12,
          ),
        ),
        pw.Text(
          Helpers.formatCurrency(amount, useArabic: false),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isMain ? 16 : 12,
            color: isMain ? PdfColor.fromHex('#10b981') : null,
          ),
        ),
      ],
    );
  }

  // التذييل
  pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          'شكراً لتعاملكم معنا - ${AppConstants.appName}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
        ),
      ),
    );
  }

  // رأس كشف الحساب
  pw.Widget _buildStatementHeader(String customerName, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#10b981'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'كشف حساب',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            customerName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'التاريخ: ${Helpers.formatDate(DateTime.now(), useArabic: false)}',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ملخص الحساب
  pw.Widget _buildAccountSummary(
    double total,
    double paid,
    double remaining,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#ecfdf5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ملخص الحساب',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 15),
          _buildTotalRow('الإجمالي الكلي:', total, font, boldFont),
          pw.SizedBox(height: 8),
          _buildTotalRow('المبالغ المدفوعة:', paid, font, boldFont),
          pw.Divider(thickness: 2, color: PdfColor.fromHex('#10b981')),
          _buildTotalRow('المتبقي:', remaining, font, boldFont, isMain: true),
        ],
      ),
    );
  }

  // جدول الفواتير
  pw.Widget _buildInvoicesTable(
    List<Invoice> invoices,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#d1fae5')),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ecfdf5')),
          children: [
            _buildTableCell('رقم الفاتورة', boldFont, isHeader: true),
            _buildTableCell('التاريخ', boldFont, isHeader: true),
            _buildTableCell('الإجمالي', boldFont, isHeader: true),
            _buildTableCell('المدفوع', boldFont, isHeader: true),
            _buildTableCell('المتبقي', boldFont, isHeader: true),
          ],
        ),
        ...invoices.map((invoice) {
          return pw.TableRow(
            children: [
              _buildTableCell(invoice.invoiceNumber, font),
              _buildTableCell(
                Helpers.formatDate(invoice.invoiceDate, useArabic: false),
                font,
              ),
              _buildTableCell(
                Helpers.formatCurrency(invoice.grandTotal, useArabic: false),
                font,
              ),
              _buildTableCell(
                Helpers.formatCurrency(invoice.amountPaid, useArabic: false),
                font,
              ),
              _buildTableCell(
                Helpers.formatCurrency(invoice.remainingBalance, useArabic: false),
                font,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // التوقيع
  pw.Widget _buildSignature(pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('توقيع الزبون:', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 30),
            pw.Container(
              width: 150,
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide()),
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('توقيع المحاسب:', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 30),
            pw.Container(
              width: 150,
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
