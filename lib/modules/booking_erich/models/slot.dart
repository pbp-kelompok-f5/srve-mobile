class Slot {
  final String start;   // "HH:MM"
  final String end;     // "HH:MM"
  final String label;   // "HH:MM – HH:MM"
  final bool booked;
  final int price;

  const Slot({
    required this.start,
    required this.end,
    required this.label,
    required this.booked,
    required this.price,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == "true";
    if (v is int) return v != 0;
    return fallback;
  }

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      start: (json["start"] ?? "").toString(),
      end: (json["end"] ?? "").toString(),
      label: (json["label"] ?? "").toString(),
      booked: _toBool(json["booked"]),
      price: _toInt(json["price"]),
    );
  }
}
