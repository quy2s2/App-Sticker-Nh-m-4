import 'dart:io';
import 'package:flutter/material.dart';

import '../../../data/models/reminder_model.dart';
import '../../../data/database/reminder_database.dart';
import '../../../data/database/app_database.dart';
import '../../../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// sticker
  String? selectedStickerPath;
  String? selectedAlbum;

  /// ================= PICK DATE =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// ================= PICK TIME =================
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  /// ================= PICK STICKER (ALBUM) =================
  Future<void> _pickStickerFromAdmin() async {
    final stickers = await AppDatabase.instance.getAllStickers();

    if (stickers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có sticker nào')),
      );
      return;
    }

    /// nhóm sticker theo album
    final Map<String, List<Map<String, dynamic>>> albums = {};
    for (var s in stickers) {
      final album = s['album'] ?? 'Khác';
      albums.putIfAbsent(album, () => []).add(s);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        String currentAlbum = selectedAlbum ?? albums.keys.first;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final albumStickers = albums[currentAlbum]!;

            return Column(
              children: [
                /// ===== ALBUM TABS =====
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: albums.keys.map((album) {
                      final isActive = album == currentAlbum;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(album),
                          selected: isActive,
                          onSelected: (_) {
                            setModalState(() => currentAlbum = album);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(),

                /// ===== STICKER GRID =====
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: albumStickers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final path =
                          albumStickers[index]['imagePath'] as String;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedStickerPath = path;
                            selectedAlbum = currentAlbum;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: File(path).existsSync()
                              ? Image.file(File(path), fit: BoxFit.cover)
                              : const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ================= SAVE =================
  Future<void> _save() async {
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

    final reminder = ReminderModel(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dateTime: dateTime,
      stickerPath: selectedStickerPath!,
    );

    final id = await ReminderDatabase.instance.insertReminder(reminder);
    reminder.id = id;

    await NotificationService.instance.scheduleReminder(
      id: id,
      title: reminder.title,
      body: reminder.description.isEmpty
          ? 'Bạn có một nhắc nhở'
          : reminder.description,
      dateTime: reminder.dateTime,
      stickerPath: reminder.stickerPath,
    );

    Navigator.pop(context, reminder);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nhắc nhở'),
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
              title: Text(selectedDate == null
                  ? 'Chọn ngày'
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(selectedTime == null
                  ? 'Chọn giờ'
                  : selectedTime!.format(context)),
              onTap: _pickTime,
            ),

            const SizedBox(height: 12),

            /// ===== STICKER =====
            InkWell(
              onTap: _pickStickerFromAdmin,
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: selectedStickerPath != null
                    ? Image.file(File(selectedStickerPath!), fit: BoxFit.cover)
                    : const Icon(Icons.collections, size: 40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedAlbum == null
                  ? 'Chọn sticker'
                  : 'Album: $selectedAlbum',
              style: const TextStyle(fontSize: 12),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Lưu nhắc nhở'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
