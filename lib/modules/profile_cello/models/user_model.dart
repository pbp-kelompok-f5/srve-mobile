class UserProfile {
  final String? profilePicture;
  final String? profilePictureUrl;
  final String? bio;
  final String? dateOfBirth;
  final int? age;
  final String? sportsInterests;
  final String skillLevel;
  final String? preferredLocation;
  final String? instagramUsername;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.profilePicture,
    this.profilePictureUrl,
    this.bio,
    this.dateOfBirth,
    this.age,
    this.sportsInterests,
    required this.skillLevel,
    this.preferredLocation,
    this.instagramUsername,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      profilePicture: json['profile_picture'],
      profilePictureUrl: json['profile_picture_url'],
      bio: json['bio'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      sportsInterests: json['sports_interests'],
      skillLevel: json['skill_level'] ?? 'BEGINNER',
      preferredLocation: json['preferred_location'],
      instagramUsername: json['instagram_username'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_picture': profilePicture,
      'bio': bio,
      'date_of_birth': dateOfBirth,
      'sports_interests': sportsInterests,
      'skill_level': skillLevel,
      'preferred_location': preferredLocation,
      'instagram_username': instagramUsername,
    };
  }

  UserProfile copyWith({
    String? profilePicture,
    String? profilePictureUrl,
    String? bio,
    String? dateOfBirth,
    int? age,
    String? sportsInterests,
    String? skillLevel,
    String? preferredLocation,
    String? instagramUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      sportsInterests: sportsInterests ?? this.sportsInterests,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getSkillLevelDisplay() {
    switch (skillLevel) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
        return 'Advanced';
      case 'EXPERT':
        return 'Expert';
      default:
        return 'Beginner';
    }
  }
}

class User {
  final int id;
  final String username;
  final String? email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? profile;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'USER',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? profile,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isUser => role == 'USER';
  bool get isGuest => role == 'GUEST';

  String getRoleDisplay() {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'USER':
        return 'User';
      case 'GUEST':
        return 'Guest';
      default:
        return 'User';
    }
  }
}