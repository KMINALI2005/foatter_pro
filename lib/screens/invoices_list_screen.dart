import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

// ملاحظة: تم إضافة هذا الجزء المؤقت لضمان عمل الكود، 
// تأكد من أن لديك ملف ثوابت حقيقي في مشروعك.
class AppConstants {
  static const paddingMedium = 16.0;
  static const darkSurface = Colors.black;
  static const cardBackground = Colors.white;
  static const borderRadiusSmall = 8.0;
}

/// 🔥 نسخة مبسطة للتشخيص - بدون أي تعقيدات
class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final _dbService = DatabaseService.instance;
  final _searchController = TextEditingController();

  // دالة الحاوي المرئي للحقول - نفس الحل المستخدم في create_invoice_screen.dart
  Widget _buildVisualInputContainer({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 1.0,
      color: isDark ? AppConstants.darkSurface : AppConstants.cardBackground,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: child,
      ),
    );
  }

  List<Invoice> _allInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🟢 InvoicesListScreen: initState');
    _loadInvoices();
  }

  // ملاحظة: تم إضافة هذه الدالة لأن الكود يستدعيها
  void _applyFilters() {
    // سيتم إضافة منطق البحث هنا لاحقاً
    setState(() {
      // حالياً لا تفعل شيئاً
    });
  }

  Future<void> _loadInvoices() async {
    print('🟢 Loading invoices...');
    
    try {
      final invoices = await _dbService.getAllInvoices();
      print('🟢 Got ${invoices.length} invoices from database');
      
      // طباعة تفاصيل كل فاتورة
      for (var i = 0; i < invoices.length; i++) {
        print('   Invoice $i: ${invoices[i].invoiceNumber} - ${invoices[i].customerName}');
      }
      
      if (mounted) {
        setState(() {
          _allInvoices = invoices;
          _isLoading = false;
        });
        print('🟢 setState done, UI should update now');
      }
    } catch (e, stack) {
      print('🔴 ERROR loading invoices: $e');
      print('🔴 Stack: $stack');
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 Building InvoicesListScreen - Loading: $_isLoading, Count: ${_allInvoices.length}');
    
    return Scaffold(
      backgroundColor: Colors.grey[100], // خلفية رمادية فاتحة
      body: SafeArea(
        child: Column(
          children: [
            // العداد
            _buildCounter(),
            
            // المحتوى
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري التحميل...', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    )
                  : _allInvoices.isEmpty
                      ? _buildEmptyState()
                      : _buildSimpleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          _buildVisualInputContainer(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث بالاسم أو رقم الفاتورة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد فواتير',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleList() {
    print('🔵 Building simple list with ${_allInvoices.length} invoices');
    
    return Container(
      color: Colors.grey[100], // تأكيد الخلفية
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _allInvoices[index];
          print('🔵 Building card $index: ${invoice.customerName}');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white, // كارت أبيض
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green, // حدود خضراء
                width: 3, // حدود عريضة جداً
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            invoice.customerName.isNotEmpty 
                                ? invoice.customerName[0].toUpperCase() 
                                : '؟',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.customerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '#${invoice.invoiceNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24, thickness: 1),
                  
                  // التفاصيل
                  _buildInfoRow('التاريخ', Helpers.formatDate(invoice.invoiceDate)),
                  const SizedBox(height: 8),
                  _buildInfoRow('الإجمالي', Helpers.formatCurrency(invoice.totalWithPrevious)),
                  const SizedBox(height: 8),
                  _buildInfoRow('المتبقي', Helpers.formatCurrency(invoice.remainingBalance)),
                  const SizedBox(height: 8),
                  
                  // الحالة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'مسددة') return Colors.green;
    if (status == 'مسددة جزئياً') return Colors.orange;
    return Colors.red;
  }
}
