import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  // Getter for database
  Future<Database> get database async {
    return _database ??= await initDB();
  }

  // Initialize the database
  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity REAL,
            date TEXT
          )
        ''');
      },
    );
  }

  // Insert new item with current date
  Future<void> insertItem(String name, double quantity) async {
    final db = await database;
    await db.insert(
      'items',
      {
        'name': name,
        'quantity': quantity,
        'date': DateTime.now().toIso8601String(),
      },
    );
  }

  // Get all items
  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('items', orderBy: 'date DESC');
  }

  // Update only quantity by ID
  Future<void> updateQuantity(int id, double quantity) async {
    final db = await database;
    await db.update(
      'items',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Full update by ID (name + quantity)
  Future<void> updateItem(int id, String name, double quantity) async {
    final db = await database;
    await db.update(
      'items',
      {
        'name': name,
        'quantity': quantity,
        'date': DateTime.now().toIso8601String(), // Optional: update date on edit
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Delete item by ID
  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Filtered data fetch by name and date range
  Future<List<Map<String, dynamic>>> getFilteredItems({
    String? itemName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (itemName != null && itemName.isNotEmpty) {
      whereClauses.add('name LIKE ?');
      whereArgs.add('%$itemName%');
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    return await db.query(
      'items',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
  }
}
