import 'package:srve_mobile/config/api.dart';

class Facility {
  final int id;
  final String name;
  final String sport;
  final String sportDisplay;
  final String city;
  final String address;
  final bool indoor;
  final int pricePerHour;
  final int defaultSlotMinutes;
  final String? imageUrl; 

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

  String? get resolvedImageUrl {
    final u = imageUrl;
    if (u == null || u.trim().isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/')) return '${Env.baseUrl}$u';
    return '${Env.baseUrl}/$u';
  }

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      sport: (json['sport'] ?? '').toString(),
      sportDisplay: (json['sport_display'] ?? json['sportDisplay'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      indoor: (json['indoor'] ?? false) as bool,
      pricePerHour: (json['price_per_hour'] as num).toInt(),
      defaultSlotMinutes: (json['default_slot_minutes'] as num).toInt(),
      imageUrl: (json['image_url'] ?? '').toString().isEmpty ? null : (json['image_url']).toString(),
    );
  }
}
