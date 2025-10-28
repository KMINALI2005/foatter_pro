import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_item_model.dart'; 
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  final _dbService = DatabaseService.instance;

  Future<String> exportToJSON() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      final products = await _dbService.getAllProducts();

      final data = {
        'version': '1.0.1',
        'exportDate': DateTime.now().toIso8601String(),
        'invoices': invoices.map((inv) => {
          ...inv.toMap(),
          'items': inv.items.map((item) => item.toMap()).toList(),
        }).toList(),
        'products': products.map((prod) => prod.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('فشل التصدير: $e');
    }
  }

  Future<String> exportToCSV() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      final buffer = StringBuffer();
      
      buffer.writeln(
        'رقم الفاتورة,اسم الزبون,التاريخ,الحساب السابق,المبلغ الواصل,الإجمالي,المتبقي,الحالة',
      );

      for (var invoice in invoices) {
        buffer.writeln(
          '${invoice.invoiceNumber},'
          '${invoice.customerName},'
          '${Helpers.formatDate(invoice.invoiceDate, useArabic: false)},'
          '${invoice.previousBalance},'
          '${invoice.amountPaid},'
          '${invoice.totalWithPrevious},'
          '${invoice.remainingBalance},'
          '${invoice.status}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/invoices_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      throw Exception('فشل التصدير: $e');
    }
  }

  Future<Map<String, int>> importFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      int importedInvoices = 0;
      int importedProducts = 0;

      if (data['products'] != null) {
        final products = data['products'] as List;
        for (var productMap in products) {
          try {
            final product = Product.fromMap(Map<String, dynamic>.from(productMap));
            await _dbService.createProduct(product);
            importedProducts++;
          } catch (e) { /* تجاهل الأخطاء الفردية */ }
        }
      }

      if (data['invoices'] != null) {
        final invoices = data['invoices'] as List;
        for (var invoiceMapDynamic in invoices) {
          try {
            final invoiceMap = Map<String, dynamic>.from(invoiceMapDynamic);
            
            final now = DateTime.now();
            final invoiceDataWithDates = {
              ...invoiceMap,
              'created_at': invoiceMap['created_at'] ?? now.toIso8601String(),
              'updated_at': invoiceMap['updated_at'] ?? now.toIso8601String(),
            };
            final invoice = Invoice.fromMap(invoiceDataWithDates);
            
            if (invoiceMap['items'] != null) {
              final items = invoiceMap['items'] as List;
              invoice.items = items.map((item) => InvoiceItem.fromMap(Map<String, dynamic>.from(item))).toList();
            }
            
            await _dbService.createInvoice(invoice);
            importedInvoices++;
          } catch (e) { /* تجاهل الأخطاء الفردية */ }
        }
      }

      return {'invoices': importedInvoices, 'products': importedProducts};
    } catch (e) {
      throw Exception('فشل الاستيراد: $e');
    }
  }

  Future<void> _shareFile(String filePath, String subject, String text) async {
    await Share.shareXFiles([XFile(filePath)], subject: subject, text: text);
  }

  Future<void> shareBackup() async {
    try {
      final filePath = await exportToJSON();
      await _shareFile(filePath, 'نسخة احتياطية - فواتير برو', 'نسخة احتياطية من البيانات');
    } catch (e) {
      throw Exception('فشل في مشاركة النسخة الاحتياطية: $e');
    }
  }

  Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      return result?.files.single.path;
    } catch (e) {
      throw Exception('فشل في اختيار الملف: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      await _dbService.deleteAllInvoices();
      await _dbService.deleteAllProducts();
    } catch (e) {
      throw Exception('فشل في حذف البيانات: $e');
    }
  }

  Future<String> createAutoBackup() async {
    try {
      final filePath = await exportToJSON();
      final directory = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${directory.path}/backups');
      
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupsDir.path}/auto_backup_$timestamp.json');
      await File(filePath).copy(backupFile.path);

      await _cleanOldBackups(backupsDir);
      return backupFile.path;
    } catch (e) {
      throw Exception('فشل في إنشاء نسخة احتياطية تلقائية: $e');
    }
  }

  Future<void> _cleanOldBackups(Directory backupsDir) async {
    try {
      final files = backupsDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (files.length > 10) {
        for (var i = 10; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) { /* تجاهل */ }
  }

  Future<List<File>> getBackupsList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${directory.path}/backups');

      if (!await backupsDir.exists()) return [];

      final files = backupsDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> restoreFromBackup(File backupFile) async {
    try {
      return await importFromJSON(backupFile.path);
    } catch (e) {
      throw Exception('فشل في استعادة النسخة الاحتياطية: $e');
    }
  }

  Future<String> exportFullReport() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      final products = await _dbService.getAllProducts();
      final stats = await _dbService.getStatistics();
      
      final buffer = StringBuffer();
      
      buffer.writeln('═══════════════════════════════════════════');
      buffer.writeln('          تقرير شامل - فواتير برو          ');
      buffer.writeln('═══════════════════════════════════════════');
      buffer.writeln('التاريخ: ${Helpers.formatDateTime(DateTime.now())}');
      buffer.writeln('═══════════════════════════════════════════\n');
      
      buffer.writeln('📊 الإحصائيات العامة:');
      buffer.writeln('─────────────────────────────────────────');
      buffer.writeln('عدد الزبائن: ${Helpers.formatNumberInt(stats['customersCount'] ?? 0)}');
      buffer.writeln('عدد الفواتير: ${Helpers.formatNumberInt(stats['invoicesCount'] ?? 0)}');
      buffer.writeln('عدد المنتجات: ${Helpers.formatNumberInt(products.length)}');
      buffer.writeln('إجمالي المبالغ: ${Helpers.formatCurrency(stats['totalGrand'] ?? 0)}');
      buffer.writeln('إجمالي المدفوع: ${Helpers.formatCurrency(stats['totalPaid'] ?? 0)}');
      buffer.writeln('إجمالي المتبقي: ${Helpers.formatCurrency(stats['totalRemaining'] ?? 0)}');
      buffer.writeln();
      
      buffer.writeln('📦 المنتجات (${products.length}):');
      buffer.writeln('─────────────────────────────────────────');
      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        buffer.writeln('${i + 1}. ${product.name}');
        buffer.writeln('   السعر: ${Helpers.formatCurrency(product.price)}');
        if (product.notes != null && product.notes!.isNotEmpty) {
          buffer.writeln('   ملاحظة: ${product.notes}');
        }
      }
      buffer.writeln();
      
      buffer.writeln('📄 الفواتير (${invoices.length}):');
      buffer.writeln('─────────────────────────────────────────');
      
      final groupedByCustomer = <String, List<Invoice>>{};
      for (var invoice in invoices) {
        groupedByCustomer.putIfAbsent(invoice.customerName, () => []).add(invoice);
      }
      
      for (var customerEntry in groupedByCustomer.entries) {
        final customerName = customerEntry.key;
        final customerInvoices = customerEntry.value;
        final totalAmount = customerInvoices.fold(0.0, (sum, inv) => sum + inv.totalWithPrevious);
        final paidAmount = customerInvoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
        final remainingAmount = customerInvoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
        
        buffer.writeln('\n👤 الزبون: $customerName');
        buffer.writeln('عدد الفواتير: ${Helpers.formatNumberInt(customerInvoices.length)}');
        buffer.writeln('الإجمالي: ${Helpers.formatCurrency(totalAmount)}');
        buffer.writeln('المدفوع: ${Helpers.formatCurrency(paidAmount)}');
        buffer.writeln('المتبقي: ${Helpers.formatCurrency(remainingAmount)}');
        buffer.writeln();
        
        for (var invoice in customerInvoices) {
          buffer.writeln('  • فاتورة #${invoice.invoiceNumber}');
          buffer.writeln('    التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}');
          buffer.writeln('    الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}');
          buffer.writeln('    المدفوع: ${Helpers.formatCurrency(invoice.amountPaid)}');
          buffer.writeln('    المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}');
          buffer.writeln('    الحالة: ${invoice.status}');
          
          if (invoice.items.isNotEmpty) {
            buffer.writeln('    المنتجات:');
            for (var item in invoice.items) {
              buffer.writeln('      - ${item.productName}: ${Helpers.formatNumber(item.quantity)} × ${Helpers.formatCurrency(item.price)} = ${Helpers.formatCurrency(item.total)}');
            }
          }
          buffer.writeln();
        }
      }
      
      buffer.writeln('═══════════════════════════════════════════');
      buffer.writeln('         نهاية التقرير - شكراً لكم          ');
      buffer.writeln('═══════════════════════════════════════════');
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/report_$timestamp.txt');
      await file.writeAsString(buffer.toString());
      
      return file.path;
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  Future<void> shareReport() async {
    try {
      final filePath = await exportFullReport();
      await _shareFile(filePath, 'تقرير شامل - فواتير برو', 'تقرير شامل من تطبيق فواتير برو');
    } catch (e) {
      throw Exception('فشل في مشاركة التقرير: $e');
    }
  }
}
