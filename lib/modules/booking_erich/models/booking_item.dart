class BookingItem {
  final int id;
  final int facilityId;
  final String facilityName;
  final String date;       // "YYYY-MM-DD"
  final String startTime;  // "HH:MM" (kita normalisasi)
  final String endTime;    // "HH:MM" (kita normalisasi)
  final String? createdAt; // optional (kadang ISO string)

  const BookingItem({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Django bisa ngirim "10:00:00" atau "10:00"
  static String _normalizeTime(dynamic v) {
    final s = (v ?? "").toString();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: _toInt(json["id"]),
      facilityId: _toInt(json["facility_id"]),
      facilityName: (json["facility_name"] ?? "").toString(),
      date: (json["date"] ?? "").toString(),
      startTime: _normalizeTime(json["start_time"]),
      endTime: _normalizeTime(json["end_time"]),
      createdAt: json["created_at"]?.toString(),
    );
  }
}
