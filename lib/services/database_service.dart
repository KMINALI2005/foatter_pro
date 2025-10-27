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
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.invoicesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_name TEXT NOT NULL,
        invoice_date TEXT NOT NULL,
        previous_balance REAL NOT NULL DEFAULT 0,
        amount_paid REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.invoiceItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (invoice_id) REFERENCES ${AppConstants.invoicesTable} (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_invoice_customer ON ${AppConstants.invoicesTable} (customer_name)');
    await db.execute('CREATE INDEX idx_invoice_date ON ${AppConstants.invoicesTable} (invoice_date)');
    await db.execute('CREATE INDEX idx_invoice_items ON ${AppConstants.invoiceItemsTable} (invoice_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    //
  }

  // ============= عمليات المنتجات =============

  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert(AppConstants.productsTable, product.toMap());
    return product.copyWith(id: id);
  }

  Future<Product?> getProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(AppConstants.productsTable, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query(AppConstants.productsTable, orderBy: 'name ASC');
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
    return await db.delete(AppConstants.productsTable, where: 'id = ?', whereArgs: [id]);
  }

  // ==== تم إضافة الدالة هنا ====
  Future<int> deleteAllProducts() async {
    final db = await instance.database;
    return await db.delete(AppConstants.productsTable);
  }

  // ============= عمليات الفواتير =============

  Future<Invoice> createInvoice(Invoice invoice) async {
    final db = await instance.database;
    final id = await db.insert(AppConstants.invoicesTable, invoice.toMap());
    for (var item in invoice.items) {
      await db.insert(AppConstants.invoiceItemsTable, item.copyWith(invoiceId: id).toMap());
    }
    return invoice.copyWith(id: id);
  }

  Future<Invoice?> getInvoice(int id) async {
    final db = await instance.database;
    final invoiceMaps = await db.query(AppConstants.invoicesTable, where: 'id = ?', whereArgs: [id]);
    if (invoiceMaps.isEmpty) return null;

    final invoice = Invoice.fromMap(invoiceMaps.first);
    final itemsMaps = await db.query(AppConstants.invoiceItemsTable, where: 'invoice_id = ?', whereArgs: [id]);
    invoice.items = itemsMaps.map((json) => InvoiceItem.fromMap(json)).toList();
    return invoice;
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final result = await db.query(AppConstants.invoicesTable, orderBy: 'invoice_date DESC, created_at DESC');
    final List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      final itemsMaps = await db.query(AppConstants.invoiceItemsTable, where: 'invoice_id = ?', whereArgs: [invoice.id]);
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
    final List<Invoice> invoices = [];
    for (var map in result) {
      final invoice = Invoice.fromMap(map);
      final itemsMaps = await db.query(AppConstants.invoiceItemsTable, where: 'invoice_id = ?', whereArgs: [invoice.id]);
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

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await instance.database;
    final result = await db.update(
      AppConstants.invoicesTable,
      invoice.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    await db.delete(AppConstants.invoiceItemsTable, where: 'invoice_id = ?', whereArgs: [invoice.id]);
    for (var item in invoice.items) {
      await db.insert(AppConstants.invoiceItemsTable, item.copyWith(invoiceId: invoice.id).toMap());
    }
    return result;
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete(AppConstants.invoicesTable, where: 'id = ?', whereArgs: [id]);
  }

  // ==== تم إضافة الدالة هنا ====
  Future<int> deleteAllInvoices() async {
    final db = await instance.database;
    return await db.delete(AppConstants.invoicesTable);
  }

  // ============= إحصائيات =============

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await instance.database;
    final customersCountResult = await db.rawQuery('SELECT COUNT(DISTINCT customer_name) as count FROM ${AppConstants.invoicesTable}');
    final invoicesCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.invoicesTable}');
    
    final invoices = await getAllInvoices();
    double totalRemaining = 0;
    double totalGrand = 0;
    double totalPaid = 0;

    for (var invoice in invoices) {
      // ==== تم إصلاح المشكلة هنا ====
      totalGrand += invoice.totalWithPrevious;
      totalRemaining += invoice.remainingBalance;
      totalPaid += invoice.amountPaid;
    }

    return {
      'customersCount': Sqflite.firstIntValue(customersCountResult) ?? 0,
      'invoicesCount': Sqflite.firstIntValue(invoicesCountResult) ?? 0,
      'totalPaid': totalPaid,
      'totalGrand': totalGrand,
      'totalRemaining': totalRemaining,
    };
  }

  Future<double> getCustomerBalance(String customerName) async {
    final invoices = await getInvoicesByCustomer(customerName);
    double sum = 0.0;
    for (final invoice in invoices) {
      sum += invoice.remainingBalance;
    }
    return sum;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
