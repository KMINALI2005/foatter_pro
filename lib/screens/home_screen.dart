import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'invoices_list_screen.dart';
import 'products_screen.dart';
import 'auditing_screen.dart';
import 'create_invoice_screen.dart';
import 'settings_screen.dart';
import 'add_edit_product_screen.dart';

// ==== تم التأكد من أن هذه الدالة كاملة وصحيحة ====
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
              child: const Icon(Icons.receipt_long, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('الإصدار ${AppConstants.appVersion}', style: Theme.of(context).textTheme.bodySmall),
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

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    InvoicesListScreen(),
    ProductsScreen(),
    AuditingScreen(),
    SettingsScreen(),
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
    ).then((result) {
      if (result == true) setState(() {});
    });
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditProductScreen()),
    ).then((result) {
      if (result == true) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = ['الفواتير', 'المنتجات', 'مراجعة الحسابات', 'الإعدادات', 'حول التطبيق'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'الفواتير'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'المنتجات'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), label: 'المراجعة'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'حول'),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: _navigateToCreateInvoice,
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      );
    }
    if (_selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
        backgroundColor: AppConstants.accentColor,
      );
    }
    return null;
  }
}
