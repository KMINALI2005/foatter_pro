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

  // ... كل المتحكمات والمتغيرات الأخرى تبقى كما هي ...
  final _customerNameController = TextEditingController();
  final _previousBalanceController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _itemNotesController = TextEditingController();

  final _customerNameFocus = FocusNode();
  final _previousBalanceFocus = FocusNode();
  final _amountPaidFocus = FocusNode();
  final _productNameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _itemNotesFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  List<InvoiceItem> _items = [];
  List<String> _customerSuggestions = [];
  List<Product> _productSuggestions = [];
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.invoice != null) {
      _populateFormForEdit();
    }
  }

  // ... كل الدوال المنطقية (initState, dispose, _saveInvoice, etc.) تبقى كما هي ...
  Future<void> _loadInitialData() async {
    final customers = await _dbService.getAllCustomerNames();
    setState(() => _customerSuggestions = customers);
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
    _customerNameFocus.dispose();
    _previousBalanceFocus.dispose();
    _amountPaidFocus.dispose();
    _productNameFocus.dispose();
    _quantityFocus.dispose();
    _priceFocus.dispose();
    _itemNotesFocus.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _productSuggestions = []);
      return;
    }
    final products = await _dbService.searchProducts(query);
    setState(() => _productSuggestions = products);
  }

  void _addItem() {
    if (_productNameController.text.isEmpty || _quantityController.text.isEmpty || _priceController.text.isEmpty) {
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
      notes: _itemNotesController.text.isEmpty ? null : _itemNotesController.text.trim(),
    );
    setState(() {
      _items.add(item);
      _productNameController.clear();
      _quantityController.clear();
      _priceController.clear();
      _itemNotesController.clear();
      _productSuggestions = [];
    });
    _productNameFocus.requestFocus();
    Helpers.showSuccessSnackBar(context, 'تم إضافة المنتج');
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    Helpers.showSnackBar(context, 'تم حذف المنتج');
  }

  double get _currentItemsTotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _totalWithPrevious => (Helpers.parseDouble(_previousBalanceController.text) ?? 0) + _currentItemsTotal;
  double get _remainingBalance => _totalWithPrevious - (Helpers.parseDouble(_amountPaidController.text) ?? 0);

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
          previousBalance: Helpers.parseDouble(_previousBalanceController.text) ?? 0,
          amountPaid: Helpers.parseDouble(_amountPaidController.text) ?? 0,
          notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
          items: _items,
          createdAt: now,
          updatedAt: now,
        );
        await _dbService.createInvoice(newInvoice);
        if(mounted) Helpers.showSuccessSnackBar(context, AppConstants.invoiceCreated);
      } else {
        final updatedInvoice = widget.invoice!.copyWith(
          customerName: _customerNameController.text.trim(),
          invoiceDate: _selectedDate,
          previousBalance: Helpers.parseDouble(_previousBalanceController.text) ?? 0,
          amountPaid: Helpers.parseDouble(_amountPaidController.text) ?? 0,
          notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
          items: _items,
          updatedAt: now,
        );
        await _dbService.updateInvoice(updatedInvoice);
        if(mounted) Helpers.showSuccessSnackBar(context, AppConstants.invoiceUpdated);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if(mounted) Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'فاتورة جديدة' : 'تعديل الفاتورة'),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveInvoice, tooltip: 'حفظ الفاتورة'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            _buildSectionTitle('معلومات الزبون'),
            // ==== تم تعديل هذه الويدجت وكل ما يشبهها ====
            _buildCustomerNameField(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildTextField(controller: _previousBalanceController, label: 'الحساب السابق', hint: '0', icon: Icons.account_balance_wallet, keyboardType: TextInputType.number, focusNode: _previousBalanceFocus, nextFocus: _amountPaidFocus)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _amountPaidController, label: 'المبلغ الواصل', hint: '0', icon: Icons.payment, keyboardType: TextInputType.number, focusNode: _amountPaidFocus, onFieldSubmitted: (_) => _productNameFocus.requestFocus())),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('إضافة منتج'),
            _buildProductNameField(),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: _buildTextField(controller: _quantityController, label: 'الكمية', hint: '1', icon: Icons.shopping_cart, keyboardType: TextInputType.number, focusNode: _quantityFocus, nextFocus: _priceFocus)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _buildTextField(controller: _priceController, label: 'السعر', hint: '0', icon: Icons.attach_money, keyboardType: TextInputType.number, focusNode: _priceFocus, nextFocus: _itemNotesFocus)),
              const SizedBox(width: 8),
              Container(margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(12)), child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addItem, tooltip: 'إضافة المنتج')),
            ]),
            const SizedBox(height: 16),
            _buildTextField(controller: _itemNotesController, label: 'ملاحظات المنتج (اختياري)', hint: 'ملاحظات...', icon: Icons.note, maxLines: 2, focusNode: _itemNotesFocus, onFieldSubmitted: (_) => _addItem()),
            const SizedBox(height: 24),
            if (_items.isNotEmpty) ...[_buildSectionTitle('المنتجات المضافة (${_items.length})'), _buildItemsList(), const SizedBox(height: 24)],
            _buildTotalsCard(),
            const SizedBox(height: 16),
            _buildTextField(controller: _notesController, label: 'ملاحظات الفاتورة (اختياري)', hint: 'ملاحظات...', icon: Icons.description, maxLines: 3),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveInvoice,
        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
        label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ الفاتورة'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==== هذا هو الحل النهائي لمشكلة الحقول المخفية ====
  // قمنا بتغليف كل حقل إدخال بـ Material لإعطائه خلفية ولون واضح
  Widget _buildVisualInputContainer({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 1.0,
      color: isDark ? AppConstants.darkSurface : AppConstants.cardBackground,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      child: Padding(
        // padding داخلي لجعل الحقل يبدو أفضل
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: child,
      ),
    );
  }

  Widget _buildCustomerNameField() {
    return _buildVisualInputContainer(
      child: Autocomplete<String>(
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
          return _customerSuggestions.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (selection) {
          _customerNameController.text = selection;
          _previousBalanceFocus.requestFocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          _customerNameController.text = controller.text;
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'اسم الزبون *',
              hintText: 'أدخل اسم الزبون',
              prefixIcon: const Icon(Icons.person),
              border: InputBorder.none, // إزالة الحدود الافتراضية
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? AppConstants.requiredField : null,
            onChanged: (value) => _customerNameController.text = value,
          );
        },
      ),
    );
  }
  
  Widget _buildProductNameField() {
    return _buildVisualInputContainer(
      child: Autocomplete<Product>(
        optionsBuilder: (textEditingValue) async {
          if (textEditingValue.text.isEmpty) return const Iterable<Product>.empty();
          await _searchProducts(textEditingValue.text);
          return _productSuggestions;
        },
        displayStringForOption: (product) => product.name,
        onSelected: (product) {
          _productNameController.text = product.name;
          _priceController.text = product.price.toString();
          _quantityFocus.requestFocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          _productNameController.text = controller.text;
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'اسم المنتج *',
              hintText: 'ابحث أو أدخل اسم منتج جديد',
              prefixIcon: const Icon(Icons.inventory),
              border: InputBorder.none,
            ),
            onChanged: (value) => _productNameController.text = value,
          );
        },
      ),
    );
  }

  Widget _buildTextField({ required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType? keyboardType, int maxLines = 1, FocusNode? focusNode, FocusNode? nextFocus, Function(String)? onFieldSubmitted }) {
    return _buildVisualInputContainer(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onFieldSubmitted: (value) {
          if (onFieldSubmitted != null) onFieldSubmitted(value);
          else if (nextFocus != null) nextFocus.requestFocus();
        },
      ),
    );
  }

  Widget _buildDateField() {
    return _buildVisualInputContainer(
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), locale: const Locale('ar'));
          if (date != null) setState(() => _selectedDate = date);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'تاريخ الفاتورة',
            prefixIcon: Icon(Icons.calendar_today),
            border: InputBorder.none,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // محاذاة النص
            child: Text(Helpers.formatDate(_selectedDate), style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // باقي الدوال المساعدة تبقى كما هي...
  Widget _buildItemsList() { return Card( elevation: 2, child: ListView.separated( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _items.length, separatorBuilder: (context, index) => const Divider(height: 1), itemBuilder: (context, index) { final item = _items[index]; return ListTile( title: Text( item.productName, style: const TextStyle(fontWeight: FontWeight.bold), ), subtitle: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( 'الكمية: ${Helpers.formatNumber(item.quantity)} × ${Helpers.formatCurrency(item.price)}', ), if (item.notes != null && item.notes!.isNotEmpty) Text( item.notes!, style: const TextStyle( fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic, ), ), ], ), trailing: Row( mainAxisSize: MainAxisSize.min, children: [ Text( Helpers.formatCurrency(item.total), style: const TextStyle( fontWeight: FontWeight.bold, color: AppConstants.primaryColor, fontSize: 16, ), ), const SizedBox(width: 8), IconButton( icon: const Icon(Icons.delete, color: AppConstants.dangerColor), onPressed: () => _removeItem(index), ), ], ), ); }, ), ); }
  Widget _buildTotalsCard() { return Card( elevation: 4, color: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Padding( padding: const EdgeInsets.all(AppConstants.paddingMedium), child: Column( children: [ _buildTotalRow( 'مجموع الفاتورة الحالية:', _currentItemsTotal, isMain: false, ), if ((Helpers.parseDouble(_previousBalanceController.text) ?? 0) > 0) ...[ const SizedBox(height: 8), _buildTotalRow( 'الحساب السابق:', Helpers.parseDouble(_previousBalanceController.text) ?? 0, isMain: false, ), ], const Divider(height: 20, thickness: 2), _buildTotalRow( 'الإجمالي الكلي:', _totalWithPrevious, isMain: true, ), if ((Helpers.parseDouble(_amountPaidController.text) ?? 0) > 0) ...[ const SizedBox(height: 8), _buildTotalRow( 'المبلغ الواصل:', Helpers.parseDouble(_amountPaidController.text) ?? 0, isMain: false, color: AppConstants.successColor, ), const Divider(height: 20, thickness: 2), _buildTotalRow( 'المتبقي:', _remainingBalance, isMain: true, color: _remainingBalance >= 0 ? AppConstants.dangerColor : AppConstants.successColor, ), ], ], ), ), ); }
  Widget _buildTotalRow( String label, double amount, { bool isMain = false, Color? color, }) { return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( label, style: TextStyle( fontSize: isMain ? 18 : 16, fontWeight: isMain ? FontWeight.bold : FontWeight.normal, ), ), Text( Helpers.formatCurrency(amount), style: TextStyle( fontSize: isMain ? 20 : 16, fontWeight: FontWeight.bold, color: color ?? Theme.of(context).colorScheme.primary, ), ), ], ); }
}
