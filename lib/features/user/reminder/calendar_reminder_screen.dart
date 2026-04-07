import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/models/reminder_model.dart';
import '../../../data/database/reminder_database.dart';
import 'edit_reminder_screen.dart';

class CalendarReminderScreen extends StatefulWidget {
  const CalendarReminderScreen({super.key});

  @override
  State<CalendarReminderScreen> createState() =>
      _CalendarReminderScreenState();
}

class _CalendarReminderScreenState extends State<CalendarReminderScreen> {
  late ValueNotifier<List<ReminderModel>> _selectedReminders;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<ReminderModel> _allReminders = [];

  @override
  void initState() {
    super.initState();
    _selectedReminders = ValueNotifier(_getRemindersForDay(_selectedDay));
    _loadReminders();
  }

  @override
  void dispose() {
    _selectedReminders.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await ReminderDatabase.instance.getAllReminders();
      if (!mounted) return;
      
      // Tự động đánh dấu những reminder đã đến thời gian (chỉ những reminder đã được schedule notification)
      // Chỉ đánh dấu nếu thời gian đã qua ít nhất 1 phút để tránh đánh dấu reminder vừa tạo
      final now = DateTime.now();
      for (final reminder in reminders) {
        if (!reminder.isNotified && 
            reminder.id != null && 
            reminder.dateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
          await ReminderDatabase.instance.markAsNotified(reminder.id!);
        }
      }
      
      // Load lại để có dữ liệu mới nhất
      final updatedReminders = await ReminderDatabase.instance.getAllReminders();
      if (!mounted) return;
      setState(() {
        _allReminders = updatedReminders;
      });
      _selectedReminders.value = _getRemindersForDay(_selectedDay);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải nhắc nhở: $e')),
      );
    }
  }

  List<ReminderModel> _getRemindersForDay(DateTime day) {
    return _allReminders.where((reminder) {
      final reminderDate = reminder.dateTime;
      return reminderDate.year == day.year &&
          reminderDate.month == day.month &&
          reminderDate.day == day.day;
    }).toList();
  }

  Set<DateTime> _getMarkedDates() {
    return _allReminders.map((reminder) {
      final date = reminder.dateTime;
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editReminder(ReminderModel reminder) async {
    final result = await Navigator.push<ReminderModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(reminder: reminder),
      ),
    );

    if (result != null) {
      _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch nhắc nhở'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          TableCalendar<ReminderModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getRemindersForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _selectedReminders.value = _getRemindersForDay(selectedDay);
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder<List<ReminderModel>>(
              valueListenable: _selectedReminders,
              builder: (context, reminders, _) {
                if (reminders.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có nhắc nhở nào trong ngày này',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final isNotified = reminder.isNotified;

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
                      child: ListTile(
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isNotified ? Colors.grey.shade700 : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reminder.description.isNotEmpty)
                              Text(
                                reminder.description,
                                style: TextStyle(
                                  color: isNotified ? Colors.grey.shade600 : null,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _formatDate(reminder.dateTime),
                                  style: TextStyle(
                                    color: isNotified
                                        ? Colors.grey.shade600
                                        : null,
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
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editReminder(reminder),
                        ),
                        onTap: () => _editReminder(reminder),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

