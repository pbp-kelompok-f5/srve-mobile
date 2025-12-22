import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/api.dart';
import '../models/profile_model.dart';

class ProfileService {
  static Future<UserProfileModel?> getProfile(BuildContext context) async {
    final request = Provider.of<CookieRequest>(context, listen: false);

    try {
      final response = await request.get(
        "http://localhost:8000/accounts/ajax/profile/",
      );
      if (response["success"] == true) {
        return UserProfileModel.fromJson(response["data"]);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    return null;
  }
}
