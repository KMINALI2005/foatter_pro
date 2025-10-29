import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService.instance;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product != null ? widget.product!.price.toString() : '');
    _notesController = TextEditingController(text: widget.product?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final price = Helpers.parseDouble(_priceController.text);
    final notes = _notesController.text.trim();

    if (price == null || price < 0) {
      if(mounted) Helpers.showErrorSnackBar(context, AppConstants.invalidPrice);
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.product == null) {
        // إنشاء منتج جديد
        final newProduct = Product(
          name: name,
          price: price,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbService.createProduct(newProduct);
        if (mounted) Helpers.showSuccessSnackBar(context, AppConstants.productCreated);
      } else {
        // تحديث منتج موجود
        final updatedProduct = widget.product!.copyWith(
          name: name,
          price: price,
          notes: notes.isEmpty ? null : notes,
          updatedAt: DateTime.now(),
        );
        await _dbService.updateProduct(updatedProduct);
        if (mounted) Helpers.showSuccessSnackBar(context, AppConstants.productUpdated);
      }

      if (mounted) Navigator.pop(context, true); // إرجاع 'true' للإشارة إلى النجاح

    } catch (e) {
      if (mounted) Helpers.showErrorSnackBar(context, 'خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'منتج جديد' : 'تعديل المنتج'),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProduct,
              tooltip: 'حفظ المنتج',
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'اسم المنتج *',
              icon: Icons.inventory_2,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppConstants.requiredField : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'السعر *',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return AppConstants.requiredField;
                final price = Helpers.parseDouble(value);
                if (price == null || price < 0) return AppConstants.invalidPrice;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'ملاحظات (اختياري)',
              icon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return _buildVisualInputContainer(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        autofocus: widget.product == null,
      ),
    );
  }
}
