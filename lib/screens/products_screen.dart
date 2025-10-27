import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();

  // Method لعرض Dialog من HomeScreen
  void showAddProductDialog(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProductsScreenState>();
    state?._showAddEditDialog();
  }
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _dbService = DatabaseService.instance;
  final _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'تأكيد الحذف',
      message: AppConstants.confirmDeleteProduct,
    );

    if (confirm && mounted) {
      try {
        await _dbService.deleteProduct(product.id!);
        Helpers.showSuccessSnackBar(context, AppConstants.productDeleted);
        _loadProducts();
      } catch (e) {
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _showAddEditDialog({Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(
      text: product?.price.toString(),
    );
    final notesController = TextEditingController(text: product?.notes);
    final formKey = GlobalKey<FormState>();

    // Focus nodes للانتقال التلقائي
    final nameFocus = FocusNode();
    final priceFocus = FocusNode();
    final notesFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل المنتج' : 'منتج جديد'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  focusNode: nameFocus,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج *',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => priceFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppConstants.requiredField;
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  focusNode: priceFocus,
                  decoration: const InputDecoration(
                    labelText: 'السعر *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => notesFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppConstants.requiredField;
                    }
                    final price = Helpers.parseDouble(value);
                    if (price == null || price < 0) {
                      return AppConstants.invalidPrice;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  focusNode: notesFocus,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveProduct(
                    context,
                    formKey,
                    nameController,
                    priceController,
                    notesController,
                    product,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _saveProduct(
              context,
              formKey,
              nameController,
              priceController,
              notesController,
              product,
            ),
            child: Text(isEdit ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      priceController.dispose();
      notesController.dispose();
      nameFocus.dispose();
      priceFocus.dispose();
      notesFocus.dispose();
    });
  }

  Future<void> _saveProduct(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController priceController,
    TextEditingController notesController,
    Product? existingProduct,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final product = Product(
      id: existingProduct?.id,
      name: nameController.text.trim(),
      price: Helpers.parseDouble(priceController.text)!,
      notes: notesController.text.isEmpty 
          ? null 
          : notesController.text.trim(),
    );

    try {
      if (existingProduct == null) {
        await _dbService.createProduct(product);
        if (mounted) {
          Helpers.showSuccessSnackBar(context, AppConstants.productCreated);
        }
      } else {
        await _dbService.updateProduct(product);
        if (mounted) {
          Helpers.showSuccessSnackBar(context, AppConstants.productUpdated);
        }
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      _loadProducts();
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsList(),
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
          // عدد المنتجات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المنتجات:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Helpers.toArabicNumbers(_allProducts.length.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث عن منتج...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
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
            onChanged: _filterProducts,
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
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noProductsFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتج جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Slidable(
      key: ValueKey(product.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showAddEditDialog(product: product),
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => _deleteProduct(product),
            backgroundColor: AppConstants.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (product.notes != null && product.notes!.isNotEmpty) ...[
                Text(
                  product.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatCurrency(product.price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const Text(
                'السعر',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          onTap: () => _showAddEditDialog(product: product),
        ),
      ),
    );
  }
}
