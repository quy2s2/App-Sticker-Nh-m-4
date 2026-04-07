import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static bool _isOpening = false;

  AppDatabase._init();

  // ================= INIT DATABASE =================
  Future<Database> get database async {
    if (_database != null) return _database!;

    // 🔥 tránh mở DB nhiều lần gây treo
    if (_isOpening) {
      await Future.delayed(const Duration(milliseconds: 200));
      return database;
    }

    _isOpening = true;
    _database = await _initDB('stickit.db');
    _isOpening = false;

    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE TABLE =================
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        fullName TEXT,
        phone TEXT,
        dob TEXT,
        email TEXT,
        avatarPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        stickerPath TEXT,
        createdAt TEXT NOT NULL,
        isNotified INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        coverImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        caption TEXT,
        albumId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE feedbacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // ✅ FIX: KHÔNG gọi insertUser ở đây nữa (tránh treo)
    await db.insert('users', {
      'username': 'khang',
      'password': '123',
      'role': 'admin',
      'fullName': 'Admin khang',
      'phone': '',
      'dob': '',
      'email': '',
      'avatarPath': null,
    });
  }

  // ================= UPGRADE DATABASE =================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN fullName TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN dob TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN avatarPath TEXT');
      } catch (_) {}
    }
  }

  // ================= USERS =================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'id ASC');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> registerUser(
    String username,
    String password, {
    required String fullName,
    required String phone,
    required String dob,
    required String email,
  }) async {
    final db = await database;

    try {
      final id = await db.insert('users', {
        'username': username,
        'password': password,
        'role': 'user',
        'fullName': fullName,
        'phone': phone,
        'dob': dob,
        'email': email,
        'avatarPath': null,
      });

      return id;
    } catch (e) {
      print("REGISTER ERROR: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginAndGetUser(String username, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return {
        'userId': result.first['id'] as int,
        'role': result.first['role'] as String,
      };
    }

    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUserAvatar(int id, String avatarPath) async {
    final db = await database;
    return db.update(
      'users',
      {'avatarPath': avatarPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
// ================= UPDATE USER ROLE =================
Future<int> updateUserRole(int id, String role) async {
  final db = await database;
  return db.update(
    'users',
    {'role': role},
    where: 'id = ?',
    whereArgs: [id],
  );
}

// ================= DELETE USER =================
Future<int> deleteUser(int id) async {
  final db = await database;
  return db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
}
  // ================= ALBUMS =================
  Future<int> insertAlbum(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('albums', data);
  }

  Future<List<Map<String, dynamic>>> getAllAlbums() async {
    final db = await database;
    return db.query('albums', orderBy: 'createdAt DESC');
  }

  Future<int> deleteAlbum(int id) async {
    final db = await database;
    await db.delete('stickers', where: 'albumId = ?', whereArgs: [id]);
    return db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  // ================= STICKERS =================
  Future<int> insertSticker(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('stickers', data);
  }

  Future<int> updateSticker(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('stickers', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSticker(int id) async {
    final db = await database;
    return db.delete('stickers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getStickersByAlbum(int albumId) async {
    final db = await database;
    return db.query(
      'stickers',
      where: 'albumId = ?',
      whereArgs: [albumId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllStickers() async {
    final db = await database;
    return db.query('stickers', orderBy: 'id DESC');
  }

  // ================= REMINDERS =================
  Future<int> insertReminder(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('reminders', data);
  }

  Future<List<Map<String, dynamic>>> getAllReminders() async {
    final db = await database;
    return db.query('reminders', orderBy: 'dateTime ASC');
  }

  Future<int> updateReminder(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('reminders', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markReminderAsNotified(int id) async {
    final db = await database;
    return db.update('reminders', {'isNotified': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ================= FEEDBACKS =================
  Future<int> insertFeedback(String username, String content) async {
    final db = await database;
    return db.insert('feedbacks', {
      'username': username,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    final db = await database;
    return db.query('feedbacks', orderBy: 'createdAt DESC');
  }

  Future<int> deleteFeedback(int id) async {
    final db = await database;
    return db.delete('feedbacks', where: 'id = ?', whereArgs: [id]);
  }
}