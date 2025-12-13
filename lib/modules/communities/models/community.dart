// lib/models/community.dart

class Community {
  final String slug;
  final String name;
  final String description;
  final String sport;
  final String skillLevel;
  final bool openToPublic;
  final int membersCount;
  final bool isAdmin;
  final bool isMember;

  Community({
    required this.slug,
    required this.name,
    required this.description,
    required this.sport,
    required this.skillLevel,
    required this.openToPublic,
    required this.membersCount,
    required this.isAdmin,
    required this.isMember,
  });

  /// Factory untuk bikin objek Community dari 1 item JSON
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      // sesuaikan kalau di Django key-nya berbeda, misal "skill_level"
      skillLevel: json['skill_level'] as String? ?? '',
      // sesuaikan dengan key di JSON, misal "open_to_public"
      openToPublic: json['open_to_public'] as bool? ?? false,
      // jaga-jaga kalau terkadang dikirim sebagai string
      membersCount: json['members_count'] is int
          ? json['members_count'] as int
          : int.tryParse(json['members_count']?.toString() ?? '0') ?? 0,
      isAdmin: json['is_admin'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
    );
  }

  /// Convert objek ke Map (buat kirim balik ke backend)
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'description': description,
      'sport': sport,
      'skill_level': skillLevel,
      'open_to_public': openToPublic,
      'members_count': membersCount,
      'is_admin': isAdmin,
      'is_member': isMember,
    };
  }

  /// Helper kalau kamu mau update sebagian field aja
  Community copyWith({
    String? slug,
    String? name,
    String? description,
    String? sport,
    String? skillLevel,
    bool? openToPublic,
    int? membersCount,
    bool? isAdmin,
    bool? isMember,
  }) {
    return Community(
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      skillLevel: skillLevel ?? this.skillLevel,
      openToPublic: openToPublic ?? this.openToPublic,
      membersCount: membersCount ?? this.membersCount,
      isAdmin: isAdmin ?? this.isAdmin,
      isMember: isMember ?? this.isMember,
    );
  }

  /// Helper kalau response-nya berupa List<dynamic>
  static List<Community> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => Community.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
