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
        'version': '1.0.0', // يمكنك زيادة هذا الرقم في المستقبل
        'exportDate': DateTime.now().toIso8601String(),
        'invoices': invoices.map((inv) {
          return {
            ...inv.toMap(),
            'items': inv.items.map((item) => item.toMap()).toList(),
          };
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
          // ==== تم التعديل هنا ====
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
            final product = Product.fromMap(productMap);
            await _dbService.createProduct(product);
            importedProducts++;
          } catch (e) { /* تجاهل */ }
        }
      }

      if (data['invoices'] != null) {
        final invoices = data['invoices'] as List;
        for (var invoiceMap in invoices) {
          try {
            final now = DateTime.now();
            final invoiceDataWithDates = {
              ...invoiceMap,
              'created_at': invoiceMap['created_at'] ?? now.toIso8601String(),
              'updated_at': invoiceMap['updated_at'] ?? now.toIso8601String(),
            };
            final invoice = Invoice.fromMap(invoiceDataWithDates);
            
            if (invoiceMap['items'] != null) {
              final items = invoiceMap['items'] as List;
              invoice.items = items.map((item) => InvoiceItem.fromMap(item)).toList();
            }
            
            await _dbService.createInvoice(invoice);
            importedInvoices++;
          } catch (e) { /* تجاهل */ }
        }
      }

      return {
        'invoices': importedInvoices,
        'products': importedProducts,
      };
    } catch (e) {
      throw Exception('فشل الاستيراد: $e');
    }
  }

  // ==== تم التعديل هنا ====
  Future<void> _shareFile(String filePath, String subject, String text) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles([xFile], subject: subject, text: text);
  }

  Future<void> shareBackup() async {
    try {
      final filePath = await exportToJSON();
      await _shareFile(
        filePath,
        'نسخة احتياطية - فواتير برو',
        'نسخة احتياطية من البيانات',
      );
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

  // ... باقي الدوال تبقى كما هي ...

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

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('       تقرير شامل - فواتير برو');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('تاريخ التقرير: ${Helpers.formatDate(DateTime.now())}\n');
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📊 الإحصائيات العامة');
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('عدد الزبائن: ${Helpers.formatNumberInt(stats['customersCount'])}');
      buffer.writeln('عدد الفواتير: ${Helpers.formatNumberInt(stats['invoicesCount'])}');
      buffer.writeln('عدد المنتجات: ${Helpers.formatNumberInt(products.length)}\n');
      buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(stats['totalGrand'])}');
      buffer.writeln('المبالغ المدفوعة: ${Helpers.formatCurrency(stats['totalPaid'])}');
      buffer.writeln('المتبقي الكلي: ${Helpers.formatCurrency(stats['totalRemaining'])}\n');
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📄 تفاصيل الفواتير');
      buffer.writeln('═══════════════════════════════════');
      
      final customerInvoices = <String, List<Invoice>>{};
      for (var invoice in invoices) {
        customerInvoices.putIfAbsent(invoice.customerName, () => []).add(invoice);
      }

      for (var entry in customerInvoices.entries) {
        final totalRemaining = entry.value.fold(0.0, (sum, inv) => sum + inv.remainingBalance);
        buffer.writeln('\n👤 ${entry.key}');
        buffer.writeln('   عدد الفواتير: ${entry.value.length}');
        buffer.writeln('   المتبقي: ${Helpers.formatCurrency(totalRemaining)}');
      }

      buffer.writeln('\n═══════════════════════════════════');
      buffer.writeln('📦 المنتجات');
      buffer.writeln('═══════════════════════════════════');
      
      for (var product in products.take(20)) {
        buffer.writeln('• ${product.name} - ${Helpers.formatCurrency(product.price)}');
      }
      if (products.length > 20) {
        buffer.writeln('... و ${products.length - 20} منتج آخر');
      }

      buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('       نهاية التقرير');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
      await _shareFile(
        filePath,
        'تقرير شامل - فواتير برو',
        'تقرير شامل من تطبيق فواتير برو',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة التقرير: $e');
    }
  }
}
