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
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // دالة البيانات التجريبية الرائعة التي أضفتها
  await _initializeSampleData();
  
  runApp(const MyApp());
}

Future<void> _initializeSampleData() async {
  try {
    final db = DatabaseService.instance;
    final existingInvoices = await db.getAllInvoices();
    
    if (existingInvoices.isEmpty) {
      print('🔄 Populating database with sample data...');
      
      final products = [
        Product(name: 'سكر', price: 25000, notes: 'كيس 50 كيلو', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Product(name: 'طحين', price: 18000, notes: 'كيس 50 كيلو', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Product(name: 'رز', price: 45000, notes: 'كيس عنبر', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Product(name: 'زيت طعام', price: 35000, notes: 'تنكة 18 لتر', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Product(name: 'شاي', price: 12000, notes: 'علبة كبيرة', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      
      for (var product in products) {
        await db.createProduct(product);
      }
      
      final now = DateTime.now();
      
      final invoice1 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}001', customerName: 'أحمد علي محمد',
        invoiceDate: now.subtract(const Duration(days: 5)), previousBalance: 50000, amountPaid: 0,
        notes: 'تسليم يوم الخميس', createdAt: now, updatedAt: now,
        items: [
          InvoiceItem(productName: 'سكر', quantity: 2, price: 25000),
          InvoiceItem(productName: 'طحين', quantity: 3, price: 18000),
        ],
      );
      await db.createInvoice(invoice1);
      
      final invoice2 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}002', customerName: 'محمد حسين كريم',
        invoiceDate: now.subtract(const Duration(days: 3)), previousBalance: 0, amountPaid: 50000,
        createdAt: now, updatedAt: now,
        items: [InvoiceItem(productName: 'رز', quantity: 2, price: 45000)],
      );
      await db.createInvoice(invoice2);
      
      print('✅ Sample data added successfully!');
    } else {
      print('✅ Database already has data.');
    }
  } catch (e) {
    print('❌ Error initializing sample data: $e');
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
    
    // ==== هذا هو الحل الشامل والنهائي لمشكلة التصميم ====
    // 1. تعريف لون أساسي واحد
    const seedColor = AppConstants.primaryColor;

    // 2. إنشاء تصميم فاتح وحديث من الصفر
    final lightTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo', // تطبيق الخط العربي
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );

    // 3. إنشاء تصميم داكن وحديث من الصفر
    final darkTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo', // تطبيق الخط العربي
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('en', 'US'),
      ],
      
      // 4. استخدام التصاميم الجديدة والنظيفة
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
