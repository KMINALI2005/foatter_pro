import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ==== تم إصلاح المشكلة هنا ====
// 1. تم إضافة هذا السطر لاستيراد الكلاس المفقود 'InvoiceItem'
// تأكد من أن اسم الملف صحيح. إذا كان الكلاس موجوداً في invoice_model.dart، يمكنك إزالة هذا السطر.
import '../models/invoice_item_model.dart'; 
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  final _dbService = DatabaseService.instance;

  // تصدير جميع البيانات إلى JSON
  Future<String> exportToJSON() async {
    try {
      // جلب جميع البيانات
      final invoices = await _dbService.getAllInvoices();
      final products = await _dbService.getAllProducts();

      // تحويل إلى Map
      final data = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'invoices': invoices.map((inv) {
          return {
            ...inv.toMap(),
            'items': inv.items.map((item) => item.toMap()).toList(),
          };
        }).toList(),
        'products': products.map((prod) => prod.toMap()).toList(),
      };

      // تحويل إلى JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // حفظ في ملف
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('فشل التصدير: $e');
    }
  }

  // تصدير إلى CSV
  Future<String> exportToCSV() async {
    try {
      final invoices = await _dbService.getAllInvoices();

      // إنشاء CSV للفواتير
      final buffer = StringBuffer();
      
      // Headers
      buffer.writeln(
        'رقم الفاتورة,اسم الزبون,التاريخ,الحساب السابق,المبلغ الواصل,الإجمالي,المتبقي,الحالة',
      );

      // Rows
      for (var invoice in invoices) {
        buffer.writeln(
          '${invoice.invoiceNumber},'
          '${invoice.customerName},'
          '${Helpers.formatDate(invoice.invoiceDate, useArabic: false)},'
          '${invoice.previousBalance},'
          '${invoice.amountPaid},'
          '${invoice.grandTotal},'
          '${invoice.remainingBalance},'
          '${invoice.status}',
        );
      }

      // حفظ في ملف
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/invoices_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      throw Exception('فشل التصدير: $e');
    }
  }

  // استيراد من JSON
  Future<Map<String, int>> importFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      int importedInvoices = 0;
      int importedProducts = 0;

      // استيراد المنتجات
      if (data['products'] != null) {
        final products = data['products'] as List;
        for (var productMap in products) {
          try {
            final product = Product.fromMap(productMap);
            await _dbService.createProduct(product);
            importedProducts++;
          } catch (e) {
            // تجاهل الأخطاء في المنتجات الفردية
          }
        }
      }

      // استيراد الفواتير
      if (data['invoices'] != null) {
        final invoices = data['invoices'] as List;
        for (var invoiceMap in invoices) {
          try {
            final invoice = Invoice.fromMap(invoiceMap);
            
            // استيراد منتجات الفاتورة
            if (invoiceMap['items'] != null) {
              final items = invoiceMap['items'] as List;
              // ==== تم إصلاح المشكلة هنا ====
              // 2. تم حذف .cast<InvoiceItem>() لأنها غير ضرورية وتزيد من تعقيد الكود
              invoice.items = items.map((item) => InvoiceItem.fromMap(item)).toList();
            }
            
            await _dbService.createInvoice(invoice);
            importedInvoices++;
          } catch (e) {
            // تجاهل الأخطاء في الفواتير الفردية
          }
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

  // مشاركة نسخة احتياطية
  Future<void> shareBackup() async {
    try {
      final filePath = await exportToJSON();
      // ==== تم إصلاح المشكلة هنا ====
      // 3. تم استبدال `Share.shareXFiles` القديمة بالدالة الجديدة `shareXFiles`
      await shareXFiles(
        [XFile(filePath)],
        subject: 'نسخة احتياطية - فواتير برو',
        text: 'نسخة احتياطية من البيانات',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة النسخة الاحتياطية: $e');
    }
  }

  // اختيار ملف للاستيراد
  Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } catch (e) {
      throw Exception('فشل في اختيار الملف: $e');
    }
  }

  // حذف جميع البيانات
  Future<void> clearAllData() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      for (var invoice in invoices) {
        await _dbService.deleteInvoice(invoice.id!);
      }

      final products = await _dbService.getAllProducts();
      for (var product in products) {
        await _dbService.deleteProduct(product.id!);
      }
    } catch (e) {
      throw Exception('فشل في حذف البيانات: $e');
    }
  }

  // حفظ نسخة احتياطية تلقائية
  Future<String> createAutoBackup() async {
    try {
      final filePath = await exportToJSON();
      
      // نسخ إلى مجلد النسخ الاحتياطية
      final directory = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${directory.path}/backups');
      
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupsDir.path}/auto_backup_$timestamp.json');
      await File(filePath).copy(backupFile.path);

      // حذف النسخ القديمة (الاحتفاظ بآخر 10 نسخ فقط)
      await _cleanOldBackups(backupsDir);

      return backupFile.path;
    } catch (e) {
      throw Exception('فشل في إنشاء نسخة احتياطية تلقائية: $e');
    }
  }

  // تنظيف النسخ الاحتياطية القديمة
  Future<void> _cleanOldBackups(Directory backupsDir) async {
    try {
      final files = await backupsDir.list().toList();
      final backupFiles = files.whereType<File>().toList();

      // ترتيب حسب تاريخ التعديل
      backupFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // حذف النسخ القديمة (الاحتفاظ بآخر 10)
      if (backupFiles.length > 10) {
        for (var i = 10; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
        }
      }
    } catch (e) {
      // تجاهل الأخطاء في التنظيف
    }
  }

  // الحصول على قائمة النسخ الاحتياطية
  Future<List<File>> getBackupsList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${directory.path}/backups');

      if (!await backupsDir.exists()) {
        return [];
      }

      final files = await backupsDir.list().toList();
      final backupFiles = files.whereType<File>().toList();

      // ترتيب حسب الأحدث
      backupFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return backupFiles;
    } catch (e) {
      return [];
    }
  }

  // استعادة من نسخة احتياطية محددة
  Future<Map<String, int>> restoreFromBackup(File backupFile) async {
    try {
      return await importFromJSON(backupFile.path);
    } catch (e) {
      throw Exception('فشل في استعادة النسخة الاحتياطية: $e');
    }
  }

  // تصدير تقرير شامل
  Future<String> exportFullReport() async {
    try {
      final invoices = await _dbService.getAllInvoices();
      final products = await _dbService.getAllProducts();
      final stats = await _dbService.getStatistics();

      final buffer = StringBuffer();

      // العنوان
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('       تقرير شامل - فواتير برو');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('تاريخ التقرير: ${Helpers.formatDate(DateTime.now())}');
      buffer.writeln();

      // الإحصائيات العامة
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📊 الإحصائيات العامة');
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('عدد الزبائن: ${Helpers.formatNumberInt(stats['customersCount'])}');
      buffer.writeln('عدد الفواتير: ${Helpers.formatNumberInt(stats['invoicesCount'])}');
      buffer.writeln('عدد المنتجات: ${Helpers.formatNumberInt(products.length)}');
      buffer.writeln();
      buffer.writeln('الإجمالي الكلي: ${Helpers.formatCurrency(stats['totalGrand'])}');
      buffer.writeln('المبالغ المدفوعة: ${Helpers.formatCurrency(stats['totalPaid'])}');
      buffer.writeln('المتبقي الكلي: ${Helpers.formatCurrency(stats['totalRemaining'])}');
      buffer.writeln();

      // تفاصيل الفواتير
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📄 تفاصيل الفواتير');
      buffer.writeln('═══════════════════════════════════');
      
      // تجميع حسب الزبون
      final customerInvoices = <String, List<Invoice>>{};
      for (var invoice in invoices) {
        customerInvoices.putIfAbsent(invoice.customerName, () => []).add(invoice);
      }

      for (var entry in customerInvoices.entries) {
        final customerName = entry.key;
        final customerInvs = entry.value;
        final totalRemaining = customerInvs.fold(
          0.0,
          (sum, inv) => sum + inv.remainingBalance,
        );

        buffer.writeln();
        buffer.writeln('👤 $customerName');
        buffer.writeln('   عدد الفواتير: ${customerInvs.length}');
        buffer.writeln('   المتبقي: ${Helpers.formatCurrency(totalRemaining)}');
      }

      buffer.writeln();
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📦 المنتجات');
      buffer.writeln('═══════════════════════════════════');
      
      for (var product in products.take(20)) {
        buffer.writeln('• ${product.name} - ${Helpers.formatCurrency(product.price)}');
      }

      if (products.length > 20) {
        buffer.writeln('... و ${products.length - 20} منتج آخر');
      }

      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('       نهاية التقرير');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // حفظ في ملف
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/report_$timestamp.txt');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  // مشاركة التقرير
  Future<void> shareReport() async {
    try {
      final filePath = await exportFullReport();
      // ==== تم إصلاح المشكلة هنا ====
      // 3. تم استبدال `Share.shareXFiles` القديمة بالدالة الجديدة `shareXFiles`
      await shareXFiles(
        [XFile(filePath)],
        subject: 'تقرير شامل - فواتير برو',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة التقرير: $e');
    }
  }
}
