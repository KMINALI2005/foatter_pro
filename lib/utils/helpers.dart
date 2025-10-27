import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  // تحويل الأرقام الإنجليزية إلى عربية
  static String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }
  
  // تحويل الأرقام العربية إلى إنجليزية
  static String toEnglishNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }
  
  // تنسيق الأرقام مع فواصل
  static String formatNumber(double number, {bool useArabic = true}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    String formatted = formatter.format(number);
    return useArabic ? toArabicNumbers(formatted) : formatted;
  }
  
  // تنسيق الأرقام بدون كسور عشرية
  static String formatNumberInt(int number, {bool useArabic = true}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    String formatted = formatter.format(number);
    return useArabic ? toArabicNumbers(formatted) : formatted;
  }
  
  // تنسيق السعر مع العملة
  static String formatCurrency(double amount, {bool useArabic = true}) {
    String formatted = formatNumber(amount, useArabic: useArabic);
    return '$formatted ${AppConstants.currency}';
  }
  
  // تنسيق التاريخ
  static String formatDate(DateTime date, {bool useArabic = true}) {
    final formatter = DateFormat(AppConstants.displayDateFormat);
    String formatted = formatter.format(date);
    return useArabic ? toArabicNumbers(formatted) : formatted;
  }
  
  // تنسيق التاريخ والوقت
  static String formatDateTime(DateTime dateTime, {bool useArabic = true}) {
    final formatter = DateFormat('dd/MM/yyyy - hh:mm a');
    String formatted = formatter.format(dateTime);
    return useArabic ? toArabicNumbers(formatted) : formatted;
  }
  
  // تحويل النص إلى رقم
  static double? parseDouble(String? text) {
    if (text == null || text.isEmpty) return null;
    text = toEnglishNumbers(text.trim());
    text = text.replaceAll(',', '');
    return double.tryParse(text);
  }
  
  // تحويل النص إلى رقم صحيح
  static int? parseInt(String? text) {
    if (text == null || text.isEmpty) return null;
    text = toEnglishNumbers(text.trim());
    text = text.replaceAll(',', '');
    return int.tryParse(text);
  }
  
  // عرض رسالة SnackBar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppConstants.primaryColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        margin: const EdgeInsets.all(AppConstants.paddingMedium),
      ),
    );
  }
  
  // عرض رسالة نجاح
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppConstants.successColor,
      icon: Icons.check_circle,
    );
  }
  
  // عرض رسالة خطأ
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppConstants.dangerColor,
      icon: Icons.error,
    );
  }
  
  // عرض حوار تأكيد
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'نعم',
    String cancelText = 'لا',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppConstants.dangerColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  // عرض Loading Dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // إخفاء Loading Dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // التحقق من صحة رقم الهاتف
  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,}$').hasMatch(toEnglishNumbers(phone));
  }
  
  // توليد رقم فاتورة فريد
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }
  
  // حساب حالة الفاتورة
  static String getInvoiceStatus(double total, double paid) {
    if (paid >= total) {
      return AppConstants.statusPaid;
    } else if (paid > 0) {
      return AppConstants.statusPartial;
    } else {
      return AppConstants.statusUnpaid;
    }
  }
  
  // الحصول على لون حالة الفاتورة
  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return AppConstants.successColor;
      case AppConstants.statusPartial:
        return AppConstants.accentColor;
      case AppConstants.statusUnpaid:
        return AppConstants.dangerColor;
      default:
        return Colors.grey;
    }
  }
  
  // تحويل النص إلى عنوان (أول حرف كبير)
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // قص النص إذا كان طويلاً
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // حساب النسبة المئوية
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }
  
  // تنسيق النسبة المئوية
  static String formatPercentage(double percentage, {bool useArabic = true}) {
    String formatted = percentage.toStringAsFixed(1);
    return useArabic ? toArabicNumbers(formatted) : formatted;
  }
}
