import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
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
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getAllProducts();
      if(mounted) {
        setState(() {
          _allProducts = products;
          _filterProducts(_searchController.text);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToAddEditProduct({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditProductScreen(product: product)),
    ).then((result) {
      if (result == true) {
        _loadProducts();
      }
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'تأكيد الحذف',
      message: AppConstants.confirmDeleteProduct,
    );

    if (confirm == true && mounted) {
      try {
        await _dbService.deleteProduct(product.id!);
        Helpers.showSuccessSnackBar(context, AppConstants.productDeleted);
        _loadProducts();
      } catch (e) {
        if(mounted) Helpers.showErrorSnackBar(context, 'حدث خطأ: ${e.toString()}');
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
  
  // ==== تم التأكد من أن هذه الدالة كاملة وصحيحة ====
  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي المنتجات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(20)),
                child: Text(Helpers.toArabicNumbers(_allProducts.length.toString()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث عن منتج...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _filterProducts(''); })
                  : null,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
            onChanged: _filterProducts,
          ),
        ],
      ),
    );
  }

  // ==== تم التأكد من أن هذه الدالة كاملة وصحيحة ====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(AppConstants.noProductsFound, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('ابدأ بإضافة منتج جديد', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
            onPressed: (_) => _navigateToAddEditProduct(product: product),
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppConstants.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2, color: AppConstants.primaryColor, size: 28),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: (product.notes != null && product.notes!.isNotEmpty)
              ? Text(product.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Helpers.formatCurrency(product.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
              const Text('السعر', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          onTap: () => _navigateToAddEditProduct(product: product),
        ),
      ),
    );
  }
}
