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
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _dbService.getAllInvoices();
      setState(() {
        _allInvoices = invoices;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
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
        // نستخدم getter 'status' الذي يحسب الحالة تلقائياً
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
        _loadInvoices(); // إعادة تحميل البيانات بعد الحذف
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
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
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
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          if(selected) {
            setState(() {
              _filterStatus = label;
              _applyFilters();
            });
          }
        },
        selectedColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : null,
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
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noInvoicesFound,
            style: TextStyle(
              fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(AppConstants.paddingMedium),
          leading: CircleAvatar(
            backgroundColor: AppConstants.primaryColor,
            child: Text(
              customerName.isNotEmpty ? customerName[0].toUpperCase() : '؟',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 8,
        ),
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
            // ==== تم التعديل هنا ====
            // استبدال `grandTotal` بـ `totalWithPrevious`
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
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تفاصيل الفاتورة',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pop(context);
                            _editInvoice(invoice);
                          },
                          tooltip: 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareInvoice(invoice),
                          tooltip: 'مشاركة',
                        ),
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () => _printInvoice(invoice),
                          tooltip: 'طباعة',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: [
                    _buildDetailCard(
                      'معلومات الفاتورة',
                      [
                        _buildDetailRow('رقم الفاتورة', '#${invoice.invoiceNumber}'),
                        _buildDetailRow('اسم الزبون', invoice.customerName),
                        _buildDetailRow('التاريخ', Helpers.formatDate(invoice.invoiceDate)),
                        _buildDetailRow('الحالة', invoice.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      'المنتجات (${invoice.items.length})',
                      invoice.items.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text(
                              'الكمية: ${Helpers.formatNumber(item.quantity)} × ${Helpers.formatCurrency(item.price)}',
                            ),
                            trailing: Text(
                              Helpers.formatCurrency(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      'الإجماليات',
                      [
                        _buildDetailRow(
                          'مجموع الفاتورة',
                          Helpers.formatCurrency(invoice.total),
                        ),
                        if (invoice.previousBalance > 0)
                          _buildDetailRow(
                            'الحساب السابق',
                            Helpers.formatCurrency(invoice.previousBalance),
                          ),
                        _buildDetailRow(
                          'الإجمالي الكلي',
                          // ==== تم التعديل هنا ====
                          Helpers.formatCurrency(invoice.totalWithPrevious),
                          isBold: true,
                        ),
                        if (invoice.amountPaid > 0)
                          _buildDetailRow(
                            'المبلغ الواصل',
                            Helpers.formatCurrency(invoice.amountPaid),
                            color: AppConstants.successColor,
                          ),
                        _buildDetailRow(
                          'المتبقي',
                          Helpers.formatCurrency(invoice.remainingBalance),
                          isBold: true,
                          color: invoice.remainingBalance > 0
                              ? AppConstants.dangerColor
                              : AppConstants.successColor,
                        ),
                      ],
                    ),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'ملاحظات',
                        [
                          Text(
                            invoice.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _shareInvoice(Invoice invoice) async {
    try {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('مشاركة الفاتورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('مشاركة كنص'),
                onTap: () => Navigator.pop(context, 'text'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('مشاركة كـ PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('مشاركة عبر WhatsApp'),
                onTap: () => Navigator.pop(context, 'whatsapp'),
              ),
            ],
          ),
        ),
      );

      if (choice != null && mounted) {
        Helpers.showLoadingDialog(context, message: 'جاري المشاركة...');
        final shareService = ShareService.instance;
        switch (choice) {
          case 'text':
            await shareService.shareInvoiceAsText(invoice);
            break;
          case 'pdf':
            await shareService.shareInvoiceAsPDF(invoice);
            break;
          case 'whatsapp':
            await shareService.shareToWhatsApp(invoice);
            break;
        }
        if (mounted) {
          Helpers.hideLoadingDialog(context);
          Helpers.showSuccessSnackBar(context, 'تم المشاركة بنجاح');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _printInvoice(Invoice invoice) async {
    try {
      Helpers.showLoadingDialog(context, message: 'جاري التحضير للطباعة...');
      final printService = PrintService.instance;
      await printService.printInvoice(invoice);
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
