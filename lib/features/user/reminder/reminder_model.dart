class ReminderModel {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String? stickerPath;

  ReminderModel({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.stickerPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'stickerPath': stickerPath,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      stickerPath: map['stickerPath'],
    );
  }
}
