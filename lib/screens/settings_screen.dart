import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والنسخ الاحتياطي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          _buildSectionTitle('النسخ الاحتياطي'),
          _buildBackupCard(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('التصدير والاستيراد'),
          _buildImportExportCard(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('التقارير'),
          _buildReportsCard(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('خيارات متقدمة'),
          _buildAdvancedCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup, color: AppConstants.primaryColor),
            title: const Text('إنشاء نسخة احتياطية'),
            subtitle: const Text('حفظ جميع البيانات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _createBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore, color: AppConstants.accentColor),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text('استيراد البيانات من ملف'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _restoreBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text('مشاركة نسخة احتياطية'),
            subtitle: const Text('إرسال البيانات عبر التطبيقات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _shareBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('النسخ الاحتياطية التلقائية'),
            subtitle: const Text('عرض النسخ المحفوظة تلقائياً'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _showAutoBackups,
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download, color: AppConstants.primaryColor),
            title: const Text('تصدير إلى JSON'),
            subtitle: const Text('تصدير جميع البيانات بصيغة JSON'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _exportJSON,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppConstants.successColor),
            title: const Text('تصدير إلى CSV'),
            subtitle: const Text('تصدير الفواتير بصيغة Excel'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _exportCSV,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_upload, color: AppConstants.accentColor),
            title: const Text('استيراد من JSON'),
            subtitle: const Text('استيراد البيانات من ملف JSON'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _importJSON,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.assessment, color: AppConstants.primaryColor),
            title: const Text('تقرير شامل'),
            subtitle: const Text('إنشاء تقرير بجميع البيانات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _generateReport,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text('مشاركة التقرير'),
            subtitle: const Text('إرسال التقرير عبر التطبيقات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _shareReport,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppConstants.dangerColor),
            title: const Text('حذف جميع البيانات'),
            subtitle: const Text('حذف جميع الفواتير والمنتجات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _clearAllData,
          ),
        ],
      ),
    );
  }

  // إنشاء نسخة احتياطية
  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    
    try {
      Helpers.showLoadingDialog(context, message: 'جاري إنشاء النسخة الاحتياطية...');
      
      final filePath = await _backupService.exportToJSON();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        final share = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ تم بنجاح'),
            content: const Text('تم إنشاء النسخة الاحتياطية.\nهل تريد مشاركتها؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لا'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('مشاركة'),
              ),
            ],
          ),
        );
        
        if (share == true && mounted) {
          await _backupService.shareBackup();
        }
        
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // استعادة نسخة احتياطية
  Future<void> _restoreBackup() async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        context,
        title: '⚠️ تحذير',
        message: 'سيتم استبدال جميع البيانات الحالية.\nهل تريد المتابعة؟',
        confirmText: 'نعم، استعادة',
        confirmColor: AppConstants.accentColor,
      );
      
      if (!confirm) return;
      
      Helpers.showLoadingDialog(context, message: 'جاري اختيار الملف...');
      
      final filePath = await _backupService.pickBackupFile();
      
      if (filePath == null) {
        if (mounted) {
          Helpers.hideLoadingDialog(context);
        }
        return;
      }
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showLoadingDialog(context, message: 'جاري استعادة البيانات...');
      }
      
      final result = await _backupService.importFromJSON(filePath);
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ تم الاستعادة'),
            content: Text(
              'تم استيراد:\n'
              '• ${Helpers.toArabicNumbers(result['invoices'].toString())} فاتورة\n'
              '• ${Helpers.toArabicNumbers(result['products'].toString())} منتج',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // العودة للشاشة الرئيسية
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // مشاركة نسخة احتياطية
  Future<void> _shareBackup() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحضير...');
      
      await _backupService.shareBackup();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showSuccessSnackBar(context, 'تم المشاركة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // عرض النسخ الاحتياطية التلقائية
  Future<void> _showAutoBackups() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحميل...');
      
      final backups = await _backupService.getBackupsList();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        if (backups.isEmpty) {
          Helpers.showSnackBar(context, 'لا توجد نسخ احتياطية تلقائية');
          return;
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('النسخ الاحتياطية التلقائية'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  final stat = backup.statSync();
                  
                  return ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text(backup.path.split('/').last),
                    subtitle: Text(
                      'التاريخ: ${Helpers.formatDateTime(stat.modified)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _restoreFromBackup(backup);
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // استعادة من نسخة احتياطية محددة
  Future<void> _restoreFromBackup(dynamic backup) async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        context,
        title: '⚠️ تحذير',
        message: 'سيتم استبدال جميع البيانات الحالية.\nهل تريد المتابعة؟',
        confirmText: 'نعم، استعادة',
        confirmColor: AppConstants.accentColor,
      );
      
      if (!confirm) return;
      
      Helpers.showLoadingDialog(context, message: 'جاري الاستعادة...');
      
      final result = await _backupService.restoreFromBackup(backup);
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ تم الاستعادة'),
            content: Text(
              'تم استيراد:\n'
              '• ${Helpers.toArabicNumbers(result['invoices'].toString())} فاتورة\n'
              '• ${Helpers.toArabicNumbers(result['products'].toString())} منتج',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // تصدير JSON
  Future<void> _exportJSON() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التصدير...');
      
      final filePath = await _backupService.exportToJSON();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showSuccessSnackBar(context, 'تم التصدير بنجاح');
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // تصدير CSV
  Future<void> _exportCSV() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التصدير...');
      
      final filePath = await _backupService.exportToCSV();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showSuccessSnackBar(context, 'تم التصدير بنجاح');
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // استيراد JSON
  Future<void> _importJSON() async {
    await _restoreBackup();
  }

  // إنشاء تقرير
  Future<void> _generateReport() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري إنشاء التقرير...');
      
      final filePath = await _backupService.exportFullReport();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        final share = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ تم إنشاء التقرير'),
            content: const Text('هل تريد مشاركة التقرير؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لا'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('مشاركة'),
              ),
            ],
          ),
        );
        
        if (share == true && mounted) {
          await _backupService.shareReport();
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // مشاركة التقرير
  Future<void> _shareReport() async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحضير...');
      
      await _backupService.shareReport();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showSuccessSnackBar(context, 'تم المشاركة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  // حذف جميع البيانات
  Future<void> _clearAllData() async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        context,
        title: '⚠️ تحذير شديد',
        message: 'سيتم حذف جميع الفواتير والمنتجات نهائياً!\n\nهذه العملية لا يمكن التراجع عنها.\n\nهل أنت متأكد؟',
        confirmText: 'نعم، احذف الكل',
        confirmColor: AppConstants.dangerColor,
      );
      
      if (!confirm) return;
      
      // تأكيد مرة أخرى
      final doubleConfirm = await Helpers.showConfirmDialog(
        context,
        title: '⚠️ تأكيد نهائي',
        message: 'هل أنت متأكد تماماً من حذف جميع البيانات؟',
        confirmText: 'نعم، متأكد',
        confirmColor: AppConstants.dangerColor,
      );
      
      if (!doubleConfirm) return;
      
      Helpers.showLoadingDialog(context, message: 'جاري الحذف...');
      
      await _backupService.clearAllData();
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ تم الحذف'),
            content: const Text('تم حذف جميع البيانات بنجاح'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }
}
