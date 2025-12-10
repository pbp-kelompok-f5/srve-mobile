import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfileModel? profile;
  bool isLoading = false;

  Future<void> loadProfile(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    profile = await ProfileService.getProfile(context);

    isLoading = false;
    notifyListeners();
  }
}
