import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fintrack.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        income_source_id INTEGER,
        amount REAL,
        date TEXT,
        description TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        category TEXT,
        date TEXT,
        description TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        value REAL,
        acquisition_date TEXT,
        description TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        due_date TEXT,
        status TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Income methods
  Future<int> insertIncome(Map<String, dynamic> income) async {
    Database db = await database;
    return await db.insert('incomes', income);
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    Database db = await database;
    return await db.query('incomes');
  }

  Future<int> updateIncome(int id, Map<String, dynamic> income) async {
    Database db = await database;
    return await db.update('incomes', income, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIncome(int id) async {
    Database db = await database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedIncomes() async {
    Database db = await database;
    return await db.query('incomes', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markIncomeSynced(int id) async {
    Database db = await database;
    await db.update('incomes', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Expense methods
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    Database db = await database;
    return await db.query('expenses');
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.update('expenses', expense, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    Database db = await database;
    return await db.query('expenses', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markExpenseSynced(int id) async {
    Database db = await database;
    await db.update('expenses', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Asset methods
  Future<int> insertAsset(Map<String, dynamic> asset) async {
    Database db = await database;
    return await db.insert('assets', asset);
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    Database db = await database;
    return await db.query('assets');
  }

  Future<int> updateAsset(int id, Map<String, dynamic> asset) async {
    Database db = await database;
    return await db.update('assets', asset, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAsset(int id) async {
    Database db = await database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAssets() async {
    Database db = await database;
    return await db.query('assets', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAssetSynced(int id) async {
    Database db = await database;
    await db.update('assets', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Debt methods
  Future<int> insertDebt(Map<String, dynamic> debt) async {
    Database db = await database;
    return await db.insert('debts', debt);
  }

  Future<List<Map<String, dynamic>>> getDebts() async {
    Database db = await database;
    return await db.query('debts');
  }

  Future<int> updateDebt(int id, Map<String, dynamic> debt) async {
    Database db = await database;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(int id) async {
    Database db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDebts() async {
    Database db = await database;
    return await db.query('debts', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markDebtSynced(int id) async {
    Database db = await database;
    await db.update('debts', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}