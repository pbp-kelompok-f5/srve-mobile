import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:srve_mobile/config/api.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;

  // Profile fields
  String bio = "";
  String? skillLevel;
  String preferredLocation = "";
  String instagram = "";
  String? dateOfBirth;
  String? profilePictureUrl;

  File? _imageFile;

  final dobController = TextEditingController();

  final List<String> skillOptions = [
    "Beginner",
    "Intermediate",
    "Advanced",
  ];

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

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final request = Provider.of<CookieRequest>(context, listen: false);

  try {
    final response =
        await request.get("https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/accounts/ajax/profile/");

      if (response["success"] == true) {
        final data = response["data"];

        final rawSkill =
            (data["skill_level"] ?? "").toString().toLowerCase();

        String? normalizedSkill;
        if (rawSkill == "beginner") normalizedSkill = "Beginner";
        if (rawSkill == "intermediate") normalizedSkill = "Intermediate";
        if (rawSkill == "advanced") normalizedSkill = "Advanced";

        setState(() {
          bio = data["bio"] ?? "";
          skillLevel = normalizedSkill;
          preferredLocation = data["preferred_location"] ?? "";
          instagram = data["instagram_username"] ?? "";
          dateOfBirth = data["date_of_birth"];
          profilePictureUrl = data["profile_picture"];
          dobController.text = dateOfBirth ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load profile error: $e");
      setState(() => isLoading = false);
    }
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // ================= UPLOAD PHOTO =================
  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    final request = Provider.of<CookieRequest>(context, listen: false);

    final uri = Uri.parse(
      "${Env.baseUrl}/accounts/ajax/profile/update-photo/",
    );

    final multipartRequest = http.MultipartRequest("POST", uri);

    multipartRequest.files.add(
      await http.MultipartFile.fromPath(
        "profile_picture",
        _imageFile!.path,
      ),
    );

    multipartRequest.headers["cookie"] =
        request.cookies.entries
            .map((e) => "${e.key}=${e.value.value}")
            .join("; ");

    final response = await multipartRequest.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated")),
      );
      _imageFile = null;
      await _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload photo")),
      );
    }
  }

  // ================= SAVE PROFILE =================
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

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Update failed"),
        ),
      );
    }
  }

  // ================= UI =================
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
              child: Column(
                children: [
                  // ===== AVATAR =====
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFFD4D3C9),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (profilePictureUrl != null &&
                                        profilePictureUrl!.isNotEmpty
                                    ? NetworkImage(
                                        "${Env.baseUrl}$profilePictureUrl")
                                    : null) as ImageProvider?,
                            child: (_imageFile == null &&
                                    (profilePictureUrl == null ||
                                        profilePictureUrl!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF6B7E5A),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6B7E5A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_imageFile != null)
                    TextButton(
                      onPressed: _uploadProfilePicture,
                      child: const Text("Upload Photo"),
                    ),

                  Text(
                    "Tap avatar to change photo",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),

                  const SizedBox(height: 24),

                  // ===== FORM =====
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: bio,
                          decoration:
                              const InputDecoration(labelText: "Bio"),
                          maxLines: 2,
                          onSaved: (v) => bio = v ?? "",
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: skillLevel,
                          decoration:
                              const InputDecoration(labelText: "Skill Level"),
                          items: skillOptions
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          validator: (v) =>
                              v == null ? "Skill level required" : null,
                          onChanged: (v) => setState(() => skillLevel = v),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: preferredLocation,
                          decoration: const InputDecoration(
                              labelText: "Preferred Location"),
                          onSaved: (v) => preferredLocation = v ?? "",
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: instagram,
                          decoration: const InputDecoration(
                              labelText: "Instagram Username"),
                          onSaved: (v) => instagram = v ?? "",
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: dobController,
                          readOnly: true,
                          decoration: const InputDecoration(
                              labelText: "Date of Birth"),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              dateOfBirth =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              dobController.text = dateOfBirth!;
                            }
                          },
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF6B7E5A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _saveProfile,
                            child: const Text("Save Changes"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
