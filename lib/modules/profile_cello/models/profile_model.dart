class UserProfileModel {
  final String username;
  final String bio;
  final String skillLevel;
  final String preferredLocation;
  final String instagram;
  final String? dateOfBirth;

  UserProfileModel({
    required this.username,
    required this.bio,
    required this.skillLevel,
    required this.preferredLocation,
    required this.instagram,
    required this.dateOfBirth,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json["username"] ?? "",
      bio: json["bio"] ?? "",
      skillLevel: json["skill_level"] ?? "",
      preferredLocation: json["preferred_location"] ?? "",
      instagram: json["instagram_username"] ?? "",
      dateOfBirth: json["date_of_birth"],
    );
  }
}
