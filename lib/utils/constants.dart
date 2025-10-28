import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'فواتير برو';
  static const String appNameEnglish = 'Invoices Pro';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'invoices_pro.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String invoicesTable = 'invoices';
  static const String invoiceItemsTable = 'invoice_items';
  static const String productsTable = 'products';
  static const String customersTable = 'customers';
  
  // Colors
  static const Color primaryColor = Color(0xFF10b981); // Emerald
  static const Color primaryDark = Color(0xFF059669);
  static const Color accentColor = Color(0xFFfbbf24); // Amber
  static const Color successColor = Color(0xFF4ade80);
  static const Color dangerColor = Color(0xFFfb7185);
  static const Color backgroundLight = Color(0xFFecfdf5);
  static const Color textDark = Color(0xFF064e3b);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFd1fae5);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF1a1a1a);
  static const Color darkSurface = Color(0xFF2d2d2d);
  static const Color darkPrimary = Color(0xFF10b981);
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  
  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  
  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textDark,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
  
  // Invoice Status
  static const String statusPaid = 'مسددة';
  static const String statusUnpaid = 'غير مسددة';
  static const String statusPartial = 'مسددة جزئياً';
  
  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  
  // Validation Messages
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidNumber = 'الرجاء إدخال رقم صحيح';
  static const String invalidPrice = 'الرجاء إدخال سعر صحيح';
  static const String invalidQuantity = 'الرجاء إدخال كمية صحيحة';
  
  // Success Messages
  static const String invoiceCreated = 'تم إنشاء الفاتورة بنجاح';
  static const String invoiceUpdated = 'تم تحديث الفاتورة بنجاح';
  static const String invoiceDeleted = 'تم حذف الفاتورة بنجاح';
  static const String productCreated = 'تم إضافة المنتج بنجاح';
  static const String productUpdated = 'تم تحديث المنتج بنجاح';
  static const String productDeleted = 'تم حذف المنتج بنجاح';
  
  // Error Messages
  static const String errorOccurred = 'حدث خطأ، الرجاء المحاولة مرة أخرى';
  static const String noInvoicesFound = 'لا توجد فواتير';
  static const String noProductsFound = 'لا توجد منتجات';
  static const String noCustomersFound = 'لا يوجد زبائن';
  
  // Confirmation Messages
  static const String confirmDelete = 'هل أنت متأكد من الحذف؟';
  static const String confirmDeleteInvoice = 'هل تريد حذف هذه الفاتورة؟';
  static const String confirmDeleteProduct = 'هل تريد حذف هذا المنتج؟';
  
  // Buttons
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String print = 'طباعة';
  static const String share = 'مشاركة';
  static const String add = 'إضافة';
  static const String search = 'بحث';
  static const String filter = 'تصفية';
  static const String backup = 'نسخ احتياطي';
  static const String restore = 'استعادة';
  
  // Currency
  static const String currency = 'IQD';
  static const String currencyArabic = 'دينار';
}

// Theme Data
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
      primary: AppConstants.primaryColor,
      secondary: AppConstants.accentColor,
      error: AppConstants.dangerColor,
      surface: AppConstants.cardBackground,
      background: AppConstants.backgroundLight,
    ),
    scaffoldBackgroundColor: AppConstants.backgroundLight,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(  // ✅ صحيح - الاسم الجديد في Flutter 3.24
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: AppConstants.cardBackground,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: const BorderSide(color: AppConstants.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: const BorderSide(color: AppConstants.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: const BorderSide(color: AppConstants.dangerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingMedium,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        elevation: 2,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: AppConstants.headingStyle,
      headlineMedium: AppConstants.subHeadingStyle,
      bodyLarge: AppConstants.bodyStyle,
      bodyMedium: AppConstants.captionStyle,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.darkPrimary,
      brightness: Brightness.dark,
      primary: AppConstants.darkPrimary,
      secondary: AppConstants.accentColor,
      error: AppConstants.dangerColor,
      surface: AppConstants.darkSurface,
      background: AppConstants.darkBackground,
    ),
    scaffoldBackgroundColor: AppConstants.darkBackground,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppConstants.darkSurface,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      color: AppConstants.darkSurface,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.darkPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        borderSide: const BorderSide(color: AppConstants.darkPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingMedium,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.darkPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        elevation: 2,
      ),
    ),
  );
}
