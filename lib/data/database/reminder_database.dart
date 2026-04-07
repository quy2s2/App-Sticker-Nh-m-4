import '../models/reminder_model.dart';
import 'app_database.dart';

class ReminderDatabase {
  ReminderDatabase._init();
  static final ReminderDatabase instance = ReminderDatabase._init();

  /// ================= THÊM NHẮC NHỞ =================
  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await AppDatabase.instance.database;
    return await db.insert(
      'reminders',
      reminder.toMap(),
    );
  }

  /// ================= LẤY DANH SÁCH NHẮC NHỞ =================
  Future<List<ReminderModel>> getAllReminders() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'reminders',
      orderBy: 'dateTime DESC', // ❗ KHÔNG dùng createdAt
    );

    return result.map((e) => ReminderModel.fromMap(e)).toList();
  }

  /// ================= XÓA NHẮC NHỞ =================
  Future<void> deleteReminder(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ================= LẤY 1 NHẮC NHỞ THEO ID (OPTIONAL) =================
  Future<ReminderModel?> getReminderById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ReminderModel.fromMap(result.first);
  }

  /// ================= XÓA TẤT CẢ (DEBUG) =================
  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('reminders');
  }

  /// ================= ĐÁNH DẤU ĐÃ THÔNG BÁO =================
  Future<void> markAsNotified(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'reminders',
      {'isNotified': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ================= LẤY REMINDERS THEO NGÀY =================
  Future<List<ReminderModel>> getRemindersByDate(DateTime date) async {
    final db = await AppDatabase.instance.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'reminders',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'dateTime ASC',
    );

    return result.map((e) => ReminderModel.fromMap(e)).toList();
  }

  /// ================= CẬP NHẬT REMINDER =================
  Future<int> updateReminder(ReminderModel reminder) async {
    if (reminder.id == null) {
      throw Exception('Reminder ID is null');
    }

    final db = await AppDatabase.instance.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }
}
