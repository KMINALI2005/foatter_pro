import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    // جدول المنتجات
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id $idType,
        name $textType,
        price $doubleType,
        notes $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE ${AppConstants.invoicesTable} (
        id $idType,
        invoice_number $textType UNIQUE,
        customer_name $textType,
        invoice_date $textType,
        previous_balance $doubleType DEFAULT 0,
        amount_paid $doubleType DEFAULT 0,
        notes $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // جدول منتجات الفاتورة
    await db.execute('''
      CREATE TABLE ${AppConstants.invoiceItemsTable} (
        id $idType,
        invoice_id INTEGER NOT NULL,
        product_name $textType,
        quantity $doubleType,
        price $doubleType,
        notes $textTypeNullable,
        created_at $textType,
        FOREIGN KEY (invoice_id) REFERENCES ${AppConstants.invoicesTable} (id) ON DELETE CASCADE
      )
    ''');

    // إنشاء فهرس لتحسين الأداء
    await db.execute('''
      CREATE INDEX idx_invoice_customer ON ${AppConstants.invoicesTable} (customer_name)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoice_date ON ${AppConstants.invoicesTable} (invoice_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoice_items ON ${AppConstants.invoiceItemsTable} (invoice_id)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // سيتم استخدامها في حالة تحديث قاعدة البيانات
  }

  // ============= عمليات المنتجات =============

  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert(AppConstants.productsTable, product.toMap());
    return product.copyWith(id: id);
  }

  Future<Product?> getProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    const orderBy = 'name ASC';
    final result = await db.query(
      AppConstants.productsTable,
      orderBy: orderBy,
    );

    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.productsTable,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      AppConstants.productsTable,
      product.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= عمليات الفواتير =============

  Future<Invoice> createInvoice(Invoice invoice) async {
    final db = await instance.database;
    
    // إنشاء الفاتورة
    final id = await db.insert(AppConstants.invoicesTable, invoice.toMap());
    
    // إضافة المنتجات
    for (var item in invoice.items) {
      await db.insert(
        AppConstants.invoiceItemsTable,
        item.copyWith(invoiceId: id).toMap(),
      );
    }
    
    return invoice.copyWith(id: id);
  }

  Future<Invoice?> getInvoice(int id) async {
    final db = await instance.database;
    
    // جلب الفاتورة
    final invoiceMaps = await db.query(
      AppConstants.invoicesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (invoiceMaps.isEmpty) return null;

    final invoice = Invoice.fromMap(invoiceMaps.first);
    
    // جلب المنتجات
    final itemsMaps = await db.query(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [id],
    );

    invoice.items = itemsMaps.map((json) => InvoiceItem.fromMap(json)).toList();
    
    return invoice;
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.invoicesTable,
      orderBy: 'invoice_date DESC, created_at DESC',
    );

    final invoices = <Invoice>[];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      
      // جلب المنتجات لكل فاتورة
      final itemsMaps = await db.query(
        AppConstants.invoiceItemsTable,
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      
      invoice.items = itemsMaps.map((json) => InvoiceItem.fromMap(json)).toList();
      invoices.add(invoice);
    }

    return invoices;
  }

  Future<List<Invoice>> getInvoicesByCustomer(String customerName) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.invoicesTable,
      where: 'customer_name = ?',
      whereArgs: [customerName],
      orderBy: 'invoice_date DESC',
    );

    final invoices = <Invoice>[];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      
      final itemsMaps = await db.query(
        AppConstants.invoiceItemsTable,
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      
      invoice.items = itemsMaps.map((json) => InvoiceItem.fromMap(json)).toList();
      invoices.add(invoice);
    }

    return invoices;
  }

  Future<List<String>> getAllCustomerNames() async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.invoicesTable,
      columns: ['customer_name'],
      distinct: true,
      orderBy: 'customer_name ASC',
    );

    return result.map((map) => map['customer_name'] as String).toList();
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.invoicesTable,
      where: 'customer_name LIKE ? OR invoice_number LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'invoice_date DESC',
    );

    final invoices = <Invoice>[];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      
      final itemsMaps = await db.query(
        AppConstants.invoiceItemsTable,
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      
      invoice.items = itemsMaps.map((json) => InvoiceItem.fromMap(json)).toList();
      invoices.add(invoice);
    }

    return invoices;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await instance.database;
    
    // تحديث الفاتورة
    final result = await db.update(
      AppConstants.invoicesTable,
      invoice.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    
    // حذف المنتجات القديمة
    await db.delete(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );
    
    // إضافة المنتجات الجديدة
    for (var item in invoice.items) {
      await db.insert(
        AppConstants.invoiceItemsTable,
        item.copyWith(invoiceId: invoice.id).toMap(),
      );
    }
    
    return result;
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    
    // حذف المنتجات أولاً
    await db.delete(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    
    // حذف الفاتورة
    return await db.delete(
      AppConstants.invoicesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= إحصائيات =============

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await instance.database;
    
    // عدد الزبائن
    final customersCount = await db.rawQuery(
      'SELECT COUNT(DISTINCT customer_name) as count FROM ${AppConstants.invoicesTable}'
    );
    
    // إجمالي الفواتير
    final invoicesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.invoicesTable}'
    );
    
    // إجمالي المبالغ
    final totals = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(previous_balance), 0) as total_previous,
        COALESCE(SUM(amount_paid), 0) as total_paid
      FROM ${AppConstants.invoicesTable}
    ''');
    
    // حساب مجموع الفواتير الحالية
    final invoices = await getAllInvoices();
    double totalCurrent = 0;
    double totalRemaining = 0;
    
    for (var invoice in invoices) {
      totalCurrent += invoice.grandTotal;
      totalRemaining += invoice.remainingBalance;
    }
    
    final totalPrevious = (totals.first['total_previous'] as double?) ?? 0.0;
    final totalPaid = (totals.first['total_paid'] as double?) ?? 0.0;

    return {
      'customersCount': customersCount.first['count'] as int,
      'invoicesCount': invoicesCount.first['count'] as int,
      'totalPrevious': totalPrevious,
      'totalPaid': totalPaid,
      'totalCurrent': totalCurrent,
      'totalGrand': totalPrevious + totalCurrent,
      'totalRemaining': totalRemaining,
    };
  }

  Future<double> getCustomerBalance(String customerName) async {
    final invoices = await getInvoicesByCustomer(customerName);
    return invoices.fold(0.0, (sum, invoice) => sum + invoice.remainingBalance);
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
