import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService.instance;

  final _customerNameController = TextEditingController();
  final _previousBalanceController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _itemNotesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<InvoiceItem> _items = [];
  List<String> _customerSuggestions = [];
  List<Product> _productSuggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🟢 CreateInvoiceScreen: initState');
    _loadInitialData();
    if (widget.invoice != null) {
      _populateFormForEdit();
    }
  }

  Future<void> _loadInitialData() async {
    final customers = await _dbService.getAllCustomerNames();
    if (mounted) {
      setState(() => _customerSuggestions = customers);
    }
  }

  void _populateFormForEdit() {
    final invoice = widget.invoice!;
    _customerNameController.text = invoice.customerName;
    _previousBalanceController.text = invoice.previousBalance.toString();
    _amountPaidController.text = invoice.amountPaid.toString();
    _notesController.text = invoice.notes ?? '';
    _selectedDate = invoice.invoiceDate;
    _items = List.from(invoice.items);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _previousBalanceController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _itemNotesController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _productSuggestions = []);
      return;
    }
    final products = await _dbService.searchProducts(query);
    if (mounted) {
      setState(() => _productSuggestions = products);
    }
  }

  void _addItem() {
    if (_productNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      Helpers.showErrorSnackBar(context, 'الرجاء إدخال بيانات المنتج كاملة');
      return;
    }

    final quantity = Helpers.parseDouble(_quantityController.text);
    final price = Helpers.parseDouble(_priceController.text);

    if (quantity == null || quantity <= 0) {
      Helpers.showErrorSnackBar(context, 'الرجاء إدخال كمية صحيحة');
      return;
    }

    if (price == null || price < 0) {
      Helpers.showErrorSnackBar(context, 'الرجاء إدخال سعر صحيح');
      return;
    }

    final item = InvoiceItem(
      productName: _productNameController.text.trim(),
      quantity: quantity,
      price: price,
      notes: _itemNotesController.text.isEmpty
          ? null
          : _itemNotesController.text.trim(),
    );

    setState(() {
      _items.add(item);
      _productNameController.clear();
      _quantityController.clear();
      _priceController.clear();
      _itemNotesController.clear();
      _productSuggestions = [];
    });

    Helpers.showSuccessSnackBar(context, 'تم إضافة المنتج');
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    Helpers.showSnackBar(context, 'تم حذف المنتج');
  }

  double get _currentItemsTotal =>
      _items.fold(0, (sum, item) => sum + item.total);
  double get _totalWithPrevious =>
      (Helpers.parseDouble(_previousBalanceController.text) ?? 0) +
      _currentItemsTotal;
  double get _remainingBalance =>
      _totalWithPrevious -
      (Helpers.parseDouble(_amountPaidController.text) ?? 0);

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      Helpers.showErrorSnackBar(context, 'الرجاء إضافة منتج واحد على الأقل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (widget.invoice == null) {
        final newInvoice = Invoice(
          invoiceNumber: Helpers.generateInvoiceNumber(),
          customerName: _customerNameController.text.trim(),
          invoiceDate: _selectedDate,
          previousBalance:
              Helpers.parseDouble(_previousBalanceController.text) ?? 0,
          amountPaid: Helpers.parseDouble(_amountPaidController.text) ?? 0,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          items: _items,
          createdAt: now,
          updatedAt: now,
        );
        await _dbService.createInvoice(newInvoice);
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'تم إنشاء الفاتورة بنجاح');
        }
      } else {
        final updatedInvoice = widget.invoice!.copyWith(
          customerName: _customerNameController.text.trim(),
          invoiceDate: _selectedDate,
          previousBalance:
              Helpers.parseDouble(_previousBalanceController.text) ?? 0,
          amountPaid: Helpers.parseDouble(_amountPaidController.text) ?? 0,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          items: _items,
          updatedAt: now,
        );
        await _dbService.updateInvoice(updatedInvoice);
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'تم تحديث الفاتورة بنجاح');
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 Building CreateInvoiceScreen');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'فاتورة جديدة' : 'تعديل الفاتورة'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveInvoice,
              tooltip: 'حفظ الفاتورة',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('معلومات الزبون'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _customerNameController,
              label: 'اسم الزبون *',
              icon: Icons.person,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _previousBalanceController,
                    label: 'الحساب السابق',
                    icon: Icons.account_balance_wallet,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _amountPaidController,
                    label: 'المبلغ الواصل',
                    icon: Icons.payment,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('إضافة منتج'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _productNameController,
              label: 'اسم المنتج *',
              icon: Icons.inventory,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'الكمية',
                    icon: Icons.shopping_cart,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'السعر',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    onPressed: _addItem,
                    tooltip: 'إضافة المنتج',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _itemNotesController,
              label: 'ملاحظات المنتج (اختياري)',
              icon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_items.isNotEmpty) ...[
              _buildSectionTitle('المنتجات المضافة (${_items.length})'),
              const SizedBox(height: 12),
              _buildItemsList(),
              const SizedBox(height: 24),
            ],
            _buildTotalsCard(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'ملاحظات الفاتورة (اختياري)',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveInvoice,
        backgroundColor: Colors.green,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ الفاتورة'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            locale: const Locale('ar'),
          );
          if (date != null) {
            setState(() => _selectedDate = date);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الفاتورة',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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

  Widget _buildItemsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'الكمية: ${Helpers.formatNumber(item.quantity)} × ${Helpers.formatCurrency(item.price)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Helpers.formatCurrency(item.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 4,
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('مجموع الفاتورة الحالية:', _currentItemsTotal),
            if ((Helpers.parseDouble(_previousBalanceController.text) ?? 0) >
                0) ...[
              const SizedBox(height: 8),
              _buildTotalRow(
                'الحساب السابق:',
                Helpers.parseDouble(_previousBalanceController.text) ?? 0,
              ),
            ],
            const Divider(height: 20, thickness: 2),
            _buildTotalRow('الإجمالي الكلي:', _totalWithPrevious, isMain: true),
            if ((Helpers.parseDouble(_amountPaidController.text) ?? 0) > 0) ...[
              const SizedBox(height: 8),
              _buildTotalRow(
                'المبلغ الواصل:',
                Helpers.parseDouble(_amountPaidController.text) ?? 0,
                color: Colors.green,
              ),
              const Divider(height: 20, thickness: 2),
              _buildTotalRow(
                'المتبقي:',
                _remainingBalance,
                isMain: true,
                color: _remainingBalance >= 0 ? Colors.red : Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isMain = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 18 : 16,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Helpers.formatCurrency(amount),
          style: TextStyle(
            fontSize: isMain ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.green,
          ),
        ),
      ],
    );
  }
}
