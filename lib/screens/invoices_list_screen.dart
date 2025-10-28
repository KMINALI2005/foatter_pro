import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
import '../services/print_service.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'create_invoice_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final _dbService = DatabaseService.instance;
  final _searchController = TextEditingController();

  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  Map<String, List<Invoice>> _groupedInvoices = {};
  String _filterStatus = 'الكل';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('📱 InvoicesListScreen initialized');
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    print('🔄 Loading invoices...');
    setState(() => _isLoading = true);
    
    try {
      final invoices = await _dbService.getAllInvoices();
      print('✅ Loaded ${invoices.length} invoices');
      
      if (mounted) {
        setState(() {
          _allInvoices = invoices;
          _applyFilters();
          _isLoading = false;
        });
        print('📊 UI updated with invoices');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading invoices: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _applyFilters() {
    List<Invoice> filtered = _allInvoices;

    // تصفية حسب الحالة
    if (_filterStatus != 'الكل') {
      filtered = filtered.where((invoice) {
        return invoice.status == _filterStatus;
      }).toList();
    }

    // تصفية حسب البحث
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((invoice) {
        return invoice.customerName.toLowerCase().contains(query) ||
            invoice.invoiceNumber.toLowerCase().contains(query);
      }).toList();
    }

    // تجميع حسب اسم الزبون
    final Map<String, List<Invoice>> grouped = {};
    for (var invoice in filtered) {
      grouped.putIfAbsent(invoice.customerName, () => []).add(invoice);
    }

    setState(() {
      _filteredInvoices = filtered;
      _groupedInvoices = grouped;
    });
    
    print('📊 Applied filters: ${filtered.length} invoices, ${grouped.length} customers');
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'تأكيد الحذف',
      message: AppConstants.confirmDeleteInvoice,
    );

    if (confirm == true && mounted) {
      try {
        await _dbService.deleteInvoice(invoice.id!);
        Helpers.showSuccessSnackBar(context, AppConstants.invoiceDeleted);
        _loadInvoices();
      } catch (e) {
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _editInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(invoice: invoice),
      ),
    ).then((result) {
      if (result == true) {
        _loadInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building InvoicesListScreen widget');
    
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري التحميل...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : _filteredInvoices.isEmpty
                  ? _buildEmptyState()
                  : _buildInvoicesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ عرض عدد الفواتير
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'إجمالي الفواتير: ${Helpers.toArabicNumbers(_allInvoices.length.toString())}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // ✅ حقل البحث
          TextField(
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
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => _applyFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('الكل'),
          _buildFilterChip(AppConstants.statusUnpaid),
          _buildFilterChip(AppConstants.statusPartial),
          _buildFilterChip(AppConstants.statusPaid),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _filterStatus = label;
              _applyFilters();
            });
          }
        },
        selectedColor: AppConstants.primaryColor,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noInvoicesFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء فاتورة جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          
          // ✅ زر لإضافة بيانات تجريبية للاختبار
          ElevatedButton.icon(
            onPressed: () async {
              Helpers.showLoadingDialog(context, message: 'جاري إضافة البيانات...');
              
              // إضافة فاتورة تجريبية
              final now = DateTime.now();
              final testInvoice = Invoice(
                invoiceNumber: 'TEST${now.millisecondsSinceEpoch}',
                customerName: 'زبون تجريبي',
                invoiceDate: now,
                previousBalance: 0,
                amountPaid: 0,
                notes: 'فاتورة تجريبية للاختبار',
                createdAt: now,
                updatedAt: now,
                items: [],
              );
              
              await _dbService.createInvoice(testInvoice);
              
              if (mounted) {
                Helpers.hideLoadingDialog(context);
                Helpers.showSuccessSnackBar(context, 'تم إضافة فاتورة تجريبية');
                _loadInvoices();
              }
            },
            icon: const Icon(Icons.science),
            label: const Text('إضافة فاتورة تجريبية'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    print('📋 Building invoices list with ${_groupedInvoices.length} customers');
    
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedInvoices.length,
        itemBuilder: (context, index) {
          final customerName = _groupedInvoices.keys.elementAt(index);
          final customerInvoices = _groupedInvoices[customerName]!;
          
          return _buildCustomerCard(customerName, customerInvoices);
        },
      ),
    );
  }

  Widget _buildCustomerCard(String customerName, List<Invoice> invoices) {
    final totalRemaining = invoices.fold(
      0.0,
      (sum, invoice) => sum + invoice.remainingBalance,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: AppConstants.primaryColor,
            radius: 28,
            child: Text(
              customerName.isNotEmpty ? customerName[0].toUpperCase() : '؟',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          title: Text(
            customerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}'),
              const SizedBox(height: 2),
              Text(
                'المتبقي: ${Helpers.formatCurrency(totalRemaining)}',
                style: TextStyle(
                  color: Helpers.getStatusColor(
                    totalRemaining > 0
                        ? AppConstants.statusUnpaid
                        : AppConstants.statusPaid,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: invoices.map((invoice) => _buildInvoiceTile(invoice)).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoiceTile(Invoice invoice) {
    return Slidable(
      key: ValueKey(invoice.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editInvoice(invoice),
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => _deleteInvoice(invoice),
            backgroundColor: AppConstants.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Helpers.getStatusColor(invoice.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: Helpers.getStatusColor(invoice.status),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '#${invoice.invoiceNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Helpers.getStatusColor(invoice.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invoice.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}'),
            const SizedBox(height: 2),
            Text(
              'الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (invoice.remainingBalance > 0) ...[
              const SizedBox(height: 2),
              Text(
                'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                style: const TextStyle(
                  color: AppConstants.dangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _showInvoiceDetails(invoice),
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    // ... (الكود الموجود مسبقاً)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تفاصيل الفاتورة',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('رقم الفاتورة: ${invoice.invoiceNumber}'),
            Text('اسم الزبون: ${invoice.customerName}'),
            Text('الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
