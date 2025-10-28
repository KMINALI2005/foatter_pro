import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'invoices_list_screen.dart';
import 'products_screen.dart';
import 'auditing_screen.dart';
import 'create_invoice_screen.dart';
import 'settings_screen.dart'; // تأكد من استيراد شاشة الإعدادات

// =============== شاشة "حول التطبيق" ===============
// تم إنشاء هذه الشاشة البسيطة هنا لسهولة الوصول إليها
// يمكنك لاحقاً نقلها إلى ملف منفصل إذا أردت
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الإصدار ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'تطبيق شامل لإدارة الفواتير والمنتجات وحسابات الزبائن. يعمل بدون إنترنت مع دعم كامل للغة العربية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== الشاشة الرئيسية (HomeScreen) ===============
class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // قائمة تحتوي على جميع الشاشات الخمس للتطبيق
  static const List<Widget> _screens = <Widget>[
    InvoicesListScreen(),
    ProductsScreen(),
    AuditingScreen(),
    SettingsScreen(),
    AboutScreen(),
  ];

  // دالة لتغيير الشاشة المعروضة عند الضغط على أيقونة في الشريط السفلي
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // دالة للانتقال إلى شاشة إنشاء فاتورة جديدة
  void _navigateToCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateInvoiceScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // يمكنك إضافة منطق لتحديث البيانات هنا إذا لزم الأمر
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // قائمة بأسماء الشاشات لعرضها في الشريط العلوي
    final List<String> titles = [
      'الفواتير',
      'المنتجات',
      'مراجعة الحسابات',
      'الإعدادات',
      'حول التطبيق'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          // زر تغيير الوضع الليلي/النهاري
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: widget.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
          ),
        ],
      ),
      // استخدام IndexedStack للحفاظ على حالة الشاشات عند التنقل بينها
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // زر الإضافة العائم يظهر فقط في شاشة الفواتير
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateInvoice,
              icon: const Icon(Icons.add),
              label: const Text('فاتورة جديدة'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // شريط التنقل السفلي الذي يحتوي على 5 أقسام
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        elevation: 8,
        // هذا الخيار يضمن ظهور أسماء الأيقونات دائماً
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, 
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'الفواتير',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'المنتجات',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'المراجعة',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'حول',
          ),
        ],
      ),
    );
  }
}
