import 'dart:io';
import 'package:flutter/material.dart';

import '../../../data/models/reminder_model.dart';
import '../../../data/database/reminder_database.dart';
import '../../../services/notification_service.dart';
import 'add_reminder_screen.dart';
import 'edit_reminder_screen.dart';
import 'calendar_reminder_screen.dart';

class MyReminderScreen extends StatefulWidget {
  const MyReminderScreen({super.key});

  @override
  State<MyReminderScreen> createState() => _MyReminderScreenState();
}

class _MyReminderScreenState extends State<MyReminderScreen>
    with SingleTickerProviderStateMixin {
  List<ReminderModel> reminders = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await NotificationService.instance.init();
    await _loadReminders();
  }

  // ================= LOAD =================
  Future<void> _loadReminders() async {
    try {
      final data = await ReminderDatabase.instance.getAllReminders();
      if (!mounted) return;

      // Tự động đánh dấu những reminder đã đến thời gian
      final now = DateTime.now();
      for (final reminder in data) {
        if (!reminder.isNotified &&
            reminder.id != null &&
            reminder.dateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
          await ReminderDatabase.instance.markAsNotified(reminder.id!);
        }
      }

      // Load lại để có dữ liệu mới nhất
      final updatedData = await ReminderDatabase.instance.getAllReminders();
      if (!mounted) return;
      setState(() => reminders = updatedData);
    } catch (e) {
      _show('Tải nhắc nhở thất bại: $e');
    }
  }

  // ================= ADD =================
  Future<void> _addReminder() async {
    final result = await Navigator.push<ReminderModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddReminderScreen()),
    );

    if (result != null) {
      await _loadReminders();
      _show('Đã thêm nhắc nhở');
    }
  }

  // ================= DELETE =================
  Future<void> _deleteReminder(ReminderModel r) async {
    if (r.id == null) return;

    try {
      await NotificationService.instance.cancelReminder(r.id!);
      await ReminderDatabase.instance.deleteReminder(r.id!);
      await _loadReminders();
      _show('Đã xóa nhắc nhở');
    } catch (e) {
      _show('Xóa thất bại: $e');
    }
  }

  // ================= EDIT =================
  Future<void> _editReminder(ReminderModel reminder) async {
    final result = await Navigator.push<ReminderModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(reminder: reminder),
      ),
    );

    if (result != null) {
      await _loadReminders();
    }
  }

  // ================= UTILS =================
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _buildSticker(ReminderModel r) {
    if (r.stickerPath.isEmpty) {
      return const Icon(Icons.notifications, size: 40);
    }

    final file = File(r.stickerPath);
    if (!file.existsSync()) {
      return const Icon(Icons.broken_image, size: 40);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc nhở của tôi'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Danh sách'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Lịch'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ================= List View với Pull-to-Refresh =================
          reminders.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có nhắc nhở',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final r = reminders[index];
                      final isNotified = r.isNotified;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        color: isNotified ? Colors.grey.shade100 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isNotified ? Colors.green : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildSticker(r),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      r.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isNotified
                                            ? Colors.grey.shade700
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (r.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        r.description,
                                        style: TextStyle(
                                          color: isNotified
                                              ? Colors.grey.shade600
                                              : null,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _formatDate(r.dateTime),
                                            style: TextStyle(
                                              color: isNotified
                                                  ? Colors.grey.shade600
                                                  : null,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isNotified)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editReminder(r);
                                  } else if (value == 'delete') {
                                    _deleteReminder(r);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Chỉnh sửa'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Xóa'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          // ================= Calendar View =================
          const CalendarReminderScreen(),
        ],
      ),
    );
  }
}
