import 'dart:io';
import 'package:flutter/material.dart';

import '../../../data/models/reminder_model.dart';
import '../../../data/database/reminder_database.dart';
import '../../../data/database/app_database.dart';
import '../../../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final ReminderModel reminder;

  const EditReminderScreen({
    super.key,
    required this.reminder,
  });

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedStickerPath;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.reminder.title);
    descriptionController =
        TextEditingController(text: widget.reminder.description);
    selectedDate = widget.reminder.dateTime;
    selectedTime = TimeOfDay(
      hour: widget.reminder.dateTime.hour,
      minute: widget.reminder.dateTime.minute,
    );
    selectedStickerPath = widget.reminder.stickerPath;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  /// ================= PICK DATE =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// ================= PICK TIME =================
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  /// ================= PICK STICKER =================
  Future<void> _pickStickerFromAdmin() async {
    final stickers = await AppDatabase.instance.getAllStickers();

    if (stickers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có sticker nào')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (_) => GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: stickers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final path = stickers[index]['imagePath'] as String;

          return InkWell(
            onTap: () {
              setState(() => selectedStickerPath = path);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedStickerPath == path
                      ? Colors.blue
                      : Colors.grey,
                  width: selectedStickerPath == path ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: File(path).existsSync()
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : const Icon(Icons.broken_image),
            ),
          );
        },
      ),
    );
  }

  /// ================= UPDATE REMINDER =================
  Future<void> _update() async {
    if (titleController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        selectedStickerPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian không hợp lệ')),
      );
      return;
    }

    final updatedReminder = ReminderModel(
      id: widget.reminder.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dateTime: dateTime,
      stickerPath: selectedStickerPath!,
      createdAt: widget.reminder.createdAt,
      isNotified: false, // Reset khi chỉnh sửa
    );

    try {
      // 1️⃣ Hủy notification cũ
      if (widget.reminder.id != null) {
        await NotificationService.instance.cancelReminder(widget.reminder.id!);
      }

      // 2️⃣ Cập nhật DB
      await ReminderDatabase.instance.updateReminder(updatedReminder);

      // 3️⃣ Schedule notification mới
      await NotificationService.instance.scheduleReminder(
        id: updatedReminder.id!,
        title: updatedReminder.title,
        body: updatedReminder.description.isEmpty
            ? 'Bạn có một nhắc nhở'
            : updatedReminder.description,
        dateTime: updatedReminder.dateTime,
        stickerPath: updatedReminder.stickerPath ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật nhắc nhở')),
      );

      Navigator.pop(context, updatedReminder);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa nhắc nhở'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate == null
                    ? 'Chọn ngày'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                selectedTime == null
                    ? 'Chọn giờ'
                    : selectedTime!.format(context),
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),

            /// STICKER
            InkWell(
              onTap: _pickStickerFromAdmin,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedStickerPath != null &&
                        File(selectedStickerPath!).existsSync()
                    ? Image.file(File(selectedStickerPath!), fit: BoxFit.cover)
                    : const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Chọn sticker'),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _update,
                child: const Text('Cập nhật nhắc nhở'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



