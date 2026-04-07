class ReminderModel {
  int? id;

  /// Tiêu đề nhắc nhở
  final String title;

  /// Mô tả nhắc nhở
  final String description;

  /// Thời gian nhắc nhở
  final DateTime dateTime;

  /// Đường dẫn sticker (admin thêm)
  final String stickerPath;

  /// Thời gian tạo (BẮT BUỘC cho DB)
  final DateTime createdAt;

  /// Đã thông báo chưa
  final bool isNotified;

  ReminderModel({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.stickerPath,
    DateTime? createdAt,
    this.isNotified = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// ================= INSERT / UPDATE =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'stickerPath': stickerPath,
      'createdAt': createdAt.toIso8601String(), // ⚠️ QUAN TRỌNG
      'isNotified': isNotified ? 1 : 0,
    };
  }

  /// ================= READ FROM DB =================
  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      stickerPath: map['stickerPath'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isNotified: (map['isNotified'] as int? ?? 0) == 1,
    );
  }
}
