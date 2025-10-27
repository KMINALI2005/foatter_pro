import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/database_service.dart';
import '../services/print_service.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AuditingScreen extends StatefulWidget {
  const AuditingScreen({super.key});

  @override
  State<AuditingScreen> createState() => _AuditingScreenState();
}

class _AuditingScreenState extends State<AuditingScreen> {
  final _dbService = DatabaseService.instance;
  final _searchController = TextEditingController();

  Map<String, List<Invoice>> _customerInvoices = {};
  Map<String, List<Invoice>> _filteredCustomers = {};
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _dbService.getAllInvoices();
      final stats = await _dbService.getStatistics();

      // تجميع الفواتير حسب الزبون
      final Map<String, List<Invoice>> grouped = {};
      for (var invoice in invoices) {
        grouped.putIfAbsent(invoice.customerName, () => []).add(invoice);
      }

      setState(() {
        _customerInvoices = grouped;
        _filteredCustomers = grouped;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customerInvoices;
      } else {
        _filteredCustomers = Map.fromEntries(
          _customerInvoices.entries.where((entry) {
            return entry.key.toLowerCase().contains(query.toLowerCase());
          }),
        );
      }
    });
  }

  double _calculateCustomerTotal(List<Invoice> invoices) {
    return invoices.fold(0, (sum, invoice) => sum + invoice.grandTotal);
  }

  double _calculateCustomerPaid(List<Invoice> invoices) {
    return invoices.fold(0, (sum, invoice) => sum + invoice.amountPaid);
  }

  double _calculateCustomerRemaining(List<Invoice> invoices) {
    return invoices.fold(0, (sum, invoice) => sum + invoice.remainingBalance);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (!_isLoading) _buildStatistics(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCustomers.isEmpty
                  ? _buildEmptyState()
                  : _buildCustomersList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن زبون...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterCustomers('');
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
        onChanged: _filterCustomers,
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'عدد الزبائن',
                  Helpers.formatNumberInt(_statistics['customersCount'] ?? 0),
                  Icons.people,
                  AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'عدد الفواتير',
                  Helpers.formatNumberInt(_statistics['invoicesCount'] ?? 0),
                  Icons.receipt_long,
                  AppConstants.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'إجمالي المبالغ',
                  Helpers.formatCurrency(_statistics['totalGrand'] ?? 0),
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'إجمالي المتبقي',
                  Helpers.formatCurrency(_statistics['totalRemaining'] ?? 0),
                  Icons.account_balance_wallet,
                  AppConstants.dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noCustomersFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد حسابات للمراجعة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    // ترتيب الزبائن حسب المتبقي (من الأكبر للأصغر)
    final sortedCustomers = _filteredCustomers.entries.toList()
      ..sort((a, b) {
        final aRemaining = _calculateCustomerRemaining(a.value);
        final bRemaining = _calculateCustomerRemaining(b.value);
        return bRemaining.compareTo(aRemaining);
      });

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: sortedCustomers.length,
        itemBuilder: (context, index) {
          final entry = sortedCustomers[index];
          final customerName = entry.key;
          final invoices = entry.value;
          
          return _buildCustomerCard(customerName, invoices);
        },
      ),
    );
  }

  Widget _buildCustomerCard(String customerName, List<Invoice> invoices) {
    final totalAmount = _calculateCustomerTotal(invoices);
    final paidAmount = _calculateCustomerPaid(invoices);
    final remainingAmount = _calculateCustomerRemaining(invoices);
    final lastInvoiceDate = invoices.isNotEmpty
        ? invoices.map((i) => i.invoiceDate).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          )
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 3,
      child: InkWell(
        onTap: () => _showCustomerDetails(customerName, invoices),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppConstants.primaryColor,
                    radius: 28,
                    child: Text(
                      customerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.receipt, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${Helpers.toArabicNumbers(invoices.length.toString())} فاتورة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              Helpers.formatDate(lastInvoiceDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _buildAmountColumn(
                      'الإجمالي',
                      totalAmount,
                      Colors.blue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      'المدفوع',
                      paidAmount,
                      AppConstants.successColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      'المتبقي',
                      remainingAmount,
                      remainingAmount > 0
                          ? AppConstants.dangerColor
                          : AppConstants.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Helpers.formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showCustomerDetails(String customerName, List<Invoice> invoices) {
    // ترتيب الفواتير حسب التاريخ (من الأحدث للأقدم)
    final sortedInvoices = List<Invoice>.from(invoices)
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final totalAmount = _calculateCustomerTotal(invoices);
          final paidAmount = _calculateCustomerPaid(invoices);
          final remainingAmount = _calculateCustomerRemaining(invoices);

          return Column(
            children: [
              // Handle
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppConstants.primaryColor,
                      radius: 24,
                      child: Text(
                        customerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${Helpers.toArabicNumbers(invoices.length.toString())} فاتورة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareCustomerStatement(customerName, invoices),
                      tooltip: 'مشاركة كشف الحساب',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => _printCustomerStatement(customerName, invoices),
                      tooltip: 'طباعة كشف الحساب',
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // ملخص الحساب
              Container(
                margin: const EdgeInsets.all(AppConstants.paddingMedium),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('الإجمالي الكلي', totalAmount),
                    const Divider(height: 16),
                    _buildSummaryRow('المبالغ المدفوعة', paidAmount, color: AppConstants.successColor),
                    const Divider(height: 16, thickness: 2),
                    _buildSummaryRow(
                      'المتبقي',
                      remainingAmount,
                      isBold: true,
                      color: remainingAmount > 0
                          ? AppConstants.dangerColor
                          : AppConstants.successColor,
                    ),
                  ],
                ),
              ),
              
              // قائمة الفواتير
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الفواتير',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  itemCount: sortedInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = sortedInvoices[index];
                    return _buildInvoiceItem(invoice);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Helpers.formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceItem(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
                  fontSize: 10,
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
            Text(
              'الإجمالي: ${Helpers.formatCurrency(invoice.grandTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (invoice.remainingBalance > 0)
              Text(
                'المتبقي: ${Helpers.formatCurrency(invoice.remainingBalance)}',
                style: const TextStyle(
                  color: AppConstants.dangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _printCustomerStatement(String customerName, List<Invoice> invoices) async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحضير للطباعة...');
      
      final printService = PrintService.instance;
      await printService.printCustomerStatement(customerName, invoices);
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _shareCustomerStatement(String customerName, List<Invoice> invoices) async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحضير للمشاركة...');
      
      final shareService = ShareService.instance;
      await shareService.shareCustomerStatement(customerName, invoices);
      
      if (mounted) {
        Helpers.hideLoadingDialog(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }
}
