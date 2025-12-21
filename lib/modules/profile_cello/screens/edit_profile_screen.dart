import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;

  // Fields
  String bio = "";
  String? skillLevel;           
  String preferredLocation = "";
  String instagram = "";
  String? dateOfBirth;

  final dobController = TextEditingController(); 

  final List<String> skillOptions = ["Beginner", "Intermediate", "Advanced"];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    dobController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
  final request = Provider.of<CookieRequest>(context, listen: false);

  try {
    final response =
        await request.get("https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/profile/");

    if (response["success"] == true) {
      final data = response["data"];

      final rawSkill = (data["skill_level"] ?? "").toString().toLowerCase();

      String? normalizedSkill;

      if (rawSkill == "beginner") normalizedSkill = "Beginner";
      else if (rawSkill == "intermediate") normalizedSkill = "Intermediate";
      else if (rawSkill == "advanced") normalizedSkill = "Advanced";

      setState(() {
        bio = data["bio"] ?? "";
        skillLevel = normalizedSkill;      
        preferredLocation = data["preferred_location"] ?? "";
        instagram = data["instagram_username"] ?? "";
        dateOfBirth = data["date_of_birth"];

        dobController.text = dateOfBirth ?? "";

        isLoading = false;
      });
    }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => isLoading = false);
    }
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    final request = Provider.of<CookieRequest>(context, listen: false);

    final response = await request.post(
      "https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/profile/update/",  // <-- FIX endpoint
      {
        "bio": bio,
        "skill_level": skillLevel ?? "",
        "preferred_location": preferredLocation,
        "instagram_username": instagram,
        "date_of_birth": dateOfBirth ?? "",
      },
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to update profile")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFFD4D3C9),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Bio
                    TextFormField(
                      initialValue: bio,
                      decoration: const InputDecoration(labelText: "Bio"),
                      maxLines: 2,
                      onSaved: (v) => bio = v ?? "",
                    ),
                    const SizedBox(height: 16),

                    // Skill Level Dropdown
                    DropdownButtonFormField<String>(
                      value: skillLevel,  // <-- FIX: null allowed
                      decoration: const InputDecoration(labelText: "Skill Level"),
                      items: skillOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      validator: (value) =>
                          value == null ? "Skill level is required" : null,
                      onChanged: (v) => setState(() => skillLevel = v),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      initialValue: preferredLocation,
                      decoration: const InputDecoration(labelText: "Preferred Location"),
                      onSaved: (v) => preferredLocation = v ?? "",
                    ),
                    const SizedBox(height: 16),

                    // Instagram
                    TextFormField(
                      initialValue: instagram,
                      decoration: const InputDecoration(labelText: "Instagram Username"),
                      onSaved: (v) => instagram = v ?? "",
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    TextFormField(
                      controller: dobController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "Date of Birth"),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          dateOfBirth =
                              "${picked.year}-${picked.month}-${picked.day}";

                          dobController.text = dateOfBirth!; // <-- FIX
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7E5A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
