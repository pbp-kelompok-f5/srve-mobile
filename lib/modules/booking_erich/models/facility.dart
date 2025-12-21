class Facility {
  final int id;
  final String name;
  final String sport;          // "tennis" | "badminton" | "padel"
  final String sportDisplay;   // "Tennis" | ...
  final String city;
  final String address;
  final bool indoor;
  final int pricePerHour;
  final int defaultSlotMinutes;
  final String? imageUrl;      // opsional (kalau backend mengirim)

  Facility({
    required this.id,
    required this.name,
    required this.sport,
    required this.sportDisplay,
    required this.city,
    required this.address,
    required this.indoor,
    required this.pricePerHour,
    required this.defaultSlotMinutes,
    this.imageUrl,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is int) return v != 0;
    return fallback;
  }

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      sport: (json['sport'] ?? '').toString(),
      sportDisplay: (json['sport_display'] ?? json['sport'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      indoor: _toBool(json['indoor']),
      pricePerHour: _toInt(json['price_per_hour']),
      defaultSlotMinutes: _toInt(json['default_slot_minutes'], fallback: 60),
      imageUrl: json['image_url']?.toString(),
    );
  }
}
