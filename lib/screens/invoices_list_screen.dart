import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
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
    if (!mounted) return;
    
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
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'خطأ: ${e.toString()}');
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // ✅ خلفية رمادية فاتحة واضحة
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                  )
                : _filteredInvoices.isEmpty
                    ? _buildEmptyState()
                    : _buildInvoicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ عداد بارز وواضح
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'إجمالي الفواتير: ${Helpers.toArabicNumbers(_allInvoices.length.toString())}',
                  style: const TextStyle(
                    fontSize: 22,
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
              prefixIcon: const Icon(Icons.search, color: Color(0xFF10b981)),
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildFilterChip('الكل'),
          _buildFilterChip('غير مسددة'),
          _buildFilterChip('مسددة جزئياً'),
          _buildFilterChip('مسددة'),
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
        selectedColor: const Color(0xFF10b981),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: const Color(0xFF10b981).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد فواتير',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإنشاء فاتورة جديدة',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    print('📋 Building ${_groupedInvoices.length} customer cards');
    
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      color: const Color(0xFF10b981),
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
    final totalRemaining = invoices.fold(0.0, (sum, inv) => sum + inv.remainingBalance);

    // ✅ الحل: كارت أبيض مع حدود ملونة واضحة!
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ خلفية بيضاء
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10b981), // ✅ حدود خضراء واضحة
          width: 2.5, // ✅ حدود عريضة
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : '؟',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          title: Text(
            customerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Color(0xFF1a1a1a),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: Color(0xFF666666)),
                    const SizedBox(width: 6),
                    Text(
                      'عدد الفواتير: ${Helpers.toArabicNumbers(invoices.length.toString())}',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 18, color: Color(0xFF666666)),
                    const SizedBox(width: 6),
                    Text(
                      'المتبقي: ${Helpers.formatCurrency(totalRemaining)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: totalRemaining > 0 ? const Color(0xFFfb7185) : const Color(0xFF4ade80),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.expand_more, color: Color(0xFF10b981), size: 32),
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
            backgroundColor: const Color(0xFFfbbf24),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _deleteInvoice(invoice),
            backgroundColor: const Color(0xFFfb7185),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // ✅ خلفية رمادية فاتحة جداً
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Helpers.getStatusColor(invoice.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt,
              color: Helpers.getStatusColor(invoice.status),
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '#${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Helpers.getStatusColor(invoice.status),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  invoice.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التاريخ: ${Helpers.formatDate(invoice.invoiceDate)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإجمالي: ${Helpers.formatCurrency(invoice.totalWithPrevious)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                if (invoice.remainingBalance > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                    style: const TextStyle(
                      color: Color(0xFFfb7185),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_left, color: Color(0xFF999999)),
          onTap: () => _showInvoiceDetails(invoice),
        ),
      ),
    );
  }

  void _editInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateInvoiceScreen(invoice: invoice)),
    ).then((result) {
      if (result == true) _loadInvoices();
    });
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'تأكيد الحذف',
      message: 'هل تريد حذف هذه الفاتورة؟',
    );

    if (confirm == true && mounted) {
      try {
        await _dbService.deleteInvoice(invoice.id!);
        Helpers.showSuccessSnackBar(context, 'تم حذف الفاتورة');
        _loadInvoices();
      } catch (e) {
        Helpers.showErrorSnackBar(context, 'خطأ: ${e.toString()}');
      }
    }
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تفاصيل الفاتورة',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
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
                    const Text('الحسابات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDetailRow('مجموع الفاتورة', Helpers.formatCurrency(invoice.total)),
                    if (invoice.previousBalance > 0)
                      _buildDetailRow('الحساب السابق', Helpers.formatCurrency(invoice.previousBalance)),
                    _buildDetailRow('الإجمالي الكلي', Helpers.formatCurrency(invoice.totalWithPrevious), isBold: true),
                    if (invoice.amountPaid > 0)
                      _buildDetailRow('المبلغ الواصل', Helpers.formatCurrency(invoice.amountPaid)),
                    _buildDetailRow('المتبقي', Helpers.formatCurrency(invoice.remainingBalance), isBold: true),
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
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF10b981) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
