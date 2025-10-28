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
    print('📱 InvoicesListScreen: initState called');
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    print('🔄 Starting to load invoices...');
    setState(() => _isLoading = true);
    
    try {
      final invoices = await _dbService.getAllInvoices();
      print('✅ Loaded ${invoices.length} invoices from database');
      
      for (var i = 0; i < invoices.length && i < 3; i++) {
        print('   Invoice $i: ${invoices[i].invoiceNumber} - ${invoices[i].customerName}');
      }
      
      if (mounted) {
        setState(() {
          _allInvoices = invoices;
          _applyFilters();
          _isLoading = false;
        });
        print('✅ UI updated successfully');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR loading invoices: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _applyFilters() {
    List<Invoice> filtered = _allInvoices;

    if (_filterStatus != 'الكل') {
      filtered = filtered.where((invoice) => invoice.status == _filterStatus).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((invoice) {
        return invoice.customerName.toLowerCase().contains(query) ||
            invoice.invoiceNumber.toLowerCase().contains(query);
      }).toList();
    }

    final Map<String, List<Invoice>> grouped = {};
    for (var invoice in filtered) {
      grouped.putIfAbsent(invoice.customerName, () => []).add(invoice);
    }

    setState(() {
      _filteredInvoices = filtered;
      _groupedInvoices = grouped;
    });
    
    print('📊 Filters applied: ${filtered.length} invoices, ${grouped.length} customers');
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
    print('🎨 Building InvoicesListScreen - Loading: $_isLoading, Invoices: ${_allInvoices.length}');
    
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
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ عداد الفواتير بتصميم واضح
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'إجمالي الفواتير: ${Helpers.toArabicNumbers(_allInvoices.length.toString())}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // حقل البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو رقم الفاتورة...',
              prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor),
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
              fillColor: Colors.grey[100],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppConstants.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد فواتير',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإنشاء فاتورة جديدة من الزر أدناه',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // زر إضافة بيانات تجريبية
            ElevatedButton.icon(
              onPressed: () async {
                Helpers.showLoadingDialog(context, message: 'جاري إضافة البيانات...');
                
                final now = DateTime.now();
                final testInvoice = Invoice(
                  invoiceNumber: 'TEST${now.millisecondsSinceEpoch}',
                  customerName: 'زبون تجريبي',
                  invoiceDate: now,
                  previousBalance: 10000,
                  amountPaid: 5000,
                  notes: 'فاتورة تجريبية',
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
              label: const Text('إضافة فاتورة تجريبية', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    print('📋 Building list with ${_groupedInvoices.length} customer groups');
    
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedInvoices.length,
        itemBuilder: (context, index) {
          final customerName = _groupedInvoices.keys.elementAt(index);
          final customerInvoices = _groupedInvoices[customerName]!;
          
          print('   Building card for customer: $customerName (${customerInvoices.length} invoices)');
          
          return _buildCustomerCard(customerName, customerInvoices);
        },
      ),
    );
  }

  Widget _buildCustomerCard(String customerName, List<Invoice> invoices) {
    final totalRemaining = invoices.fold(0.0, (sum, invoice) => sum + invoice.remainingBalance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : '؟',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          title: Text(
            customerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'المتبقي: ${Helpers.formatCurrency(totalRemaining)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: totalRemaining > 0 ? AppConstants.dangerColor : AppConstants.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.expand_more, color: AppConstants.primaryColor),
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
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _deleteInvoice(invoice),
            backgroundColor: AppConstants.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Helpers.getStatusColor(invoice.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt,
              color: Helpers.getStatusColor(invoice.status),
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '#${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  'الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (invoice.remainingBalance > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                    style: const TextStyle(
                      color: AppConstants.dangerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: Icon(Icons.chevron_left, color: Colors.grey[400]),
          onTap: () => _showInvoiceDetails(invoice),
        ),
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تفاصيل الفاتورة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppConstants.accentColor),
                        onPressed: () {
                          Navigator.pop(context);
                          _editInvoice(invoice);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('رقم الفاتورة', '#${invoice.invoiceNumber}'),
                    _buildDetailRow('اسم الزبون', invoice.customerName),
                    _buildDetailRow('التاريخ', Helpers.formatDate(invoice.invoiceDate)),
                    _buildDetailRow('الحالة', invoice.status),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'الحسابات',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('مجموع الفاتورة', Helpers.formatCurrency(invoice.total)),
                    if (invoice.previousBalance > 0)
                      _buildDetailRow('الحساب السابق', Helpers.formatCurrency(invoice.previousBalance)),
                    _buildDetailRow('الإجمالي الكلي', Helpers.formatCurrency(invoice.totalWithPrevious), isBold: true),
                    if (invoice.amountPaid > 0)
                      _buildDetailRow('المبلغ الواصل', Helpers.formatCurrency(invoice.amountPaid)),
                    _buildDetailRow('المتبقي', Helpers.formatCurrency(invoice.remainingBalance), isBold: true),
                    
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'ملاحظات',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(invoice.notes!, style: const TextStyle(fontSize: 15)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppConstants.primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
