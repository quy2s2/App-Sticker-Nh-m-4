import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  // ================= INIT =================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stickit.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE =================

  Future<void> _onCreate(Database db, int version) async {
    /// USERS
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    /// REMINDERS
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        remindTime TEXT,
        sticker TEXT,
        createdAt TEXT
      )
    ''');

    /// 👑 ADMIN MẶC ĐỊNH
    await db.insert('users', {
      'username': 'hoa',
      'password': '123',
      'role': 'admin',
    });
  }

  // ================= UPGRADE =================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // thêm cột role nếu DB cũ
      await db.execute(
        "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'",
      );

      // đảm bảo tài khoản hoa là admin
      await db.update(
        'users',
        {'role': 'admin'},
        where: 'username = ?',
        whereArgs: ['hoa'],
      );
    }
  }

  // ================= USER =================

  /// Đăng ký → LUÔN là USER
  Future<bool> registerUser(String username, String password) async {
    final db = await database;
    try {
      await db.insert('users', {
        'username': username,
        'password': password,
        'role': 'user',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login + lấy role (BẮT BUỘC cho phân quyền)
  Future<String?> loginAndGetRole(
    String username,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isEmpty) return null;
    return result.first['role'] as String;
  }

  /// Lấy role theo username
  Future<String?> getUserRole(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['role'],
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first['role'] as String : null;
  }

  /// Admin → lấy danh sách user
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  /// Admin → đổi quyền user
  Future<void> updateUserRole(int id, String role) async {
    final db = await database;
    await db.update(
      'users',
      {'role': role},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Admin → xóa user
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= REMINDER =================

  Future<int> insertReminder(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('reminders', data);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await database;
    return await db.query(
      'reminders',
      orderBy: 'createdAt DESC',
    );
  }
}
