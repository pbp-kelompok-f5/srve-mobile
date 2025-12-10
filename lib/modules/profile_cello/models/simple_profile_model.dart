class SimpleProfile {
  final String username;
  final String? bio;
  final String skillLevel;
  final String? preferredLocation;
  final String? instagramUsername;
  final String? dateOfBirth;

  SimpleProfile({
    required this.username,
    this.bio,
    required this.skillLevel,
    this.preferredLocation,
    this.instagramUsername,
    this.dateOfBirth,
  });

  factory SimpleProfile.fromJson(Map<String, dynamic> json) {
    return SimpleProfile(
      username: json['username'],
      bio: json['bio'],
      skillLevel: json['skill_level'],
      preferredLocation: json['preferred_location'],
      instagramUsername: json['instagram_username'],
      dateOfBirth: json['date_of_birth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "bio": bio,
      "skill_level": skillLevel,
      "preferred_location": preferredLocation,
      "instagram_username": instagramUsername,
      "date_of_birth": dateOfBirth,
    };
  }
}
