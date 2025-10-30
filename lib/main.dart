import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'models/product_model.dart';
import 'models/invoice_model.dart';
import 'models/invoice_item_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه النص من اليمين لليسار
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // إضافة بيانات تجريبية إذا كانت قاعدة البيانات فارغة
  await _initializeSampleData();
  
  runApp(const MyApp());
}

// ✅ دالة لإضافة بيانات تجريبية
Future<void> _initializeSampleData() async {
  try {
    final db = DatabaseService.instance;
    
    // التحقق من وجود بيانات
    final existingProducts = await db.getAllProducts();
    final existingInvoices = await db.getAllInvoices();
    
    // إذا كانت قاعدة البيانات فارغة، أضف بيانات تجريبية
    if (existingProducts.isEmpty && existingInvoices.isEmpty) {
      print('🔄 إضافة بيانات تجريبية...');
      
      // 1. إضافة منتجات تجريبية
      final sampleProducts = [
        Product(
          name: 'سكر',
          price: 25000,
          notes: 'كيس 50 كيلو',
        ),
        Product(
          name: 'طحين',
          price: 18000,
          notes: 'كيس 50 كيلو',
        ),
        Product(
          name: 'رز',
          price: 45000,
          notes: 'كيس عنبر',
        ),
        Product(
          name: 'زيت طعام',
          price: 35000,
          notes: 'تنكة 18 لتر',
        ),
        Product(
          name: 'شاي',
          price: 12000,
          notes: 'علبة كبيرة',
        ),
      ];
      
      for (var product in sampleProducts) {
        await db.createProduct(product);
      }
      
      // 2. إضافة فواتير تجريبية
      final now = DateTime.now();
      
      // فاتورة 1 - أحمد علي (غير مسددة)
      final invoice1 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}001',
        customerName: 'أحمد علي محمد',
        invoiceDate: now.subtract(const Duration(days: 5)),
        previousBalance: 50000,
        amountPaid: 0,
        notes: 'تسليم يوم الخميس',
        createdAt: now,
        updatedAt: now,
        items: [
          InvoiceItem(
            productName: 'سكر',
            quantity: 2,
            price: 25000,
          ),
          InvoiceItem(
            productName: 'طحين',
            quantity: 3,
            price: 18000,
          ),
        ],
      );
      await db.createInvoice(invoice1);
      
      // فاتورة 2 - محمد حسين (مسددة جزئياً)
      final invoice2 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}002',
        customerName: 'محمد حسين كريم',
        invoiceDate: now.subtract(const Duration(days: 3)),
        previousBalance: 0,
        amountPaid: 50000,
        notes: null,
        createdAt: now,
        updatedAt: now,
        items: [
          InvoiceItem(
            productName: 'رز',
            quantity: 2,
            price: 45000,
          ),
        ],
      );
      await db.createInvoice(invoice2);
      
      // فاتورة 3 - فاطمة علي (مسددة)
      final invoice3 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}003',
        customerName: 'فاطمة علي حسن',
        invoiceDate: now.subtract(const Duration(days: 1)),
        previousBalance: 20000,
        amountPaid: 82000,
        notes: 'عميلة مميزة',
        createdAt: now,
        updatedAt: now,
        items: [
          InvoiceItem(
            productName: 'زيت طعام',
            quantity: 1,
            price: 35000,
          ),
          InvoiceItem(
            productName: 'شاي',
            quantity: 2,
            price: 12000,
          ),
          InvoiceItem(
            productName: 'سكر',
            quantity: 1,
            price: 25000,
            notes: 'إضافة خاصة',
          ),
        ],
      );
      await db.createInvoice(invoice3);
      
      print('✅ تم إضافة البيانات التجريبية بنجاح!');
    } else {
      print('✅ قاعدة البيانات تحتوي على بيانات');
    }
  } catch (e) {
    print('❌ خطأ في إضافة البيانات التجريبية: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // إعدادات اللغة العربية والاتجاه من اليمين لليسار
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('en', 'US'),
      ],
      
      // Theme - تم إزالة الخط المخصص لحل مشكلة البناء للإنتاج
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Home Screen
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      
      // Builder لضبط اتجاه النص
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
