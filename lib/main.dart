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
  
  // قفل الاتجاه على العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ✅ إضافة البيانات التجريبية بشكل مضمون
  await _initializeSampleData();
  
  runApp(const MyApp());
}

// ✅ دالة محسّنة لإضافة البيانات التجريبية
Future<void> _initializeSampleData() async {
  try {
    print('🔄 Starting database initialization...');
    final db = DatabaseService.instance;
    
    // ✅ التأكد من عمل قاعدة البيانات أولاً
    await db.database;
    print('✅ Database connected successfully');
    
    final existingInvoices = await db.getAllInvoices();
    print('📊 Current invoices count: ${existingInvoices.length}');
    
    if (existingInvoices.isEmpty) {
      print('🔄 Adding sample data...');
      
      // إضافة المنتجات
      final products = [
        Product(
          name: 'سكر',
          price: 25000,
          notes: 'كيس 50 كيلو',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          name: 'طحين',
          price: 18000,
          notes: 'كيس 50 كيلو',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          name: 'رز',
          price: 45000,
          notes: 'كيس عنبر',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          name: 'زيت طعام',
          price: 35000,
          notes: 'تنكة 18 لتر',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          name: 'شاي',
          price: 12000,
          notes: 'علبة كبيرة',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      for (var product in products) {
        await db.createProduct(product);
        print('✅ Added product: ${product.name}');
      }
      
      // إضافة الفواتير
      final now = DateTime.now();
      
      // فاتورة 1
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
          InvoiceItem(productName: 'سكر', quantity: 2, price: 25000),
          InvoiceItem(productName: 'طحين', quantity: 3, price: 18000),
        ],
      );
      await db.createInvoice(invoice1);
      print('✅ Added invoice 1');
      
      // فاتورة 2
      final invoice2 = Invoice(
        invoiceNumber: 'INV${now.millisecondsSinceEpoch}002',
        customerName: 'محمد حسين كريم',
        invoiceDate: now.subtract(const Duration(days: 3)),
        previousBalance: 0,
        amountPaid: 50000,
        createdAt: now,
        updatedAt: now,
        items: [
          InvoiceItem(productName: 'رز', quantity: 2, price: 45000),
        ],
      );
      await db.createInvoice(invoice2);
      print('✅ Added invoice 2');
      
      // فاتورة 3
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
          InvoiceItem(productName: 'زيت طعام', quantity: 1, price: 35000),
          InvoiceItem(productName: 'شاي', quantity: 2, price: 12000),
        ],
      );
      await db.createInvoice(invoice3);
      print('✅ Added invoice 3');
      
      print('✅ Sample data added successfully!');
      
      // التحقق النهائي
      final finalCount = await db.getAllInvoices();
      print('📊 Final invoices count: ${finalCount.length}');
    } else {
      print('✅ Database already has ${existingInvoices.length} invoices');
    }
  } catch (e, stackTrace) {
    print('❌ ERROR in _initializeSampleData: $e');
    print('Stack trace: $stackTrace');
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
      
      // ✅ اللغة العربية
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('en', 'US'),
      ],
      
      // ✅ الوضع الفاتح - تصميم واضح تماماً
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // ✅ الألوان الأساسية
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        
        // ✅ ColorScheme واضح
        colorScheme: ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          background: const Color(0xFFF5F5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
        ),
        
        // ✅ AppBar بتصميم واضح
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        
        // ✅ حقول الإدخال واضحة جداً
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          
          // حدود واضحة
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          
          // نصوص واضحة
          labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        ),
        
        // ✅ الكروت
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // ✅ الأزرار العائمة
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        
        // ✅ شريط التنقل السفلي
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          height: 70,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          indicatorColor: AppConstants.primaryColor.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            );
          }),
          
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(
                color: AppConstants.primaryColor,
                size: 28,
              );
            }
            return const IconThemeData(
              color: Color(0xFF757575),
              size: 24,
            );
          }),
        ),
        
        // ✅ النصوص
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
      
      // ✅ الوضع الداكن
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        
        primaryColor: AppConstants.darkPrimary,
        scaffoldBackgroundColor: AppConstants.darkBackground,
        
        colorScheme: ColorScheme.dark(
          primary: AppConstants.darkPrimary,
          secondary: AppConstants.accentColor,
          background: AppConstants.darkBackground,
          surface: AppConstants.darkSurface,
        ),
        
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.darkSurface,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.darkSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF404040), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF404040), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.darkPrimary, width: 2.5),
          ),
        ),
        
        cardTheme: CardTheme(
          color: AppConstants.darkSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppConstants.darkSurface,
          height: 70,
          elevation: 8,
          indicatorColor: AppConstants.darkPrimary.withOpacity(0.2),
        ),
      ),
      
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      
      // ✅ اتجاه النصوص من اليمين لليسار
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
