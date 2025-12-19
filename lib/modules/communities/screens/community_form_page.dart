// lib/communities/screens/community_form_page.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../widgets/navigation_helpers.dart';

class CommunityFormPage extends StatefulWidget {
  /// Kalau null → mode CREATE
  /// Kalau ada Community → mode EDIT
  final Community? community;

  static const routeName = communityFormRoute;

  const CommunityFormPage({super.key, this.community});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  /// Sesuaikan pilihan skill level dengan yang ada di Django (choices skill_level)
  final List<String> _skillLevelOptions = const [
    'beginner',
    'intermediate',
    'advanced',
    'expert'
  ];

  final List<String> _sportOptions = const [
    'tennis',
    'padel',
    'badminton'
  ];

  String? _selectedSport;
  String? _selectedSkillLevel;
  bool _openToPublic = true;

  late bool _isEditMode;
  late CommunityService _communityService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.community != null;

    _nameController = TextEditingController(
      text: widget.community?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.community?.description ?? '',
    );
    _selectedSport = widget.community?.sport.isNotEmpty == true
        ? widget.community!.sport
        : null;

    _selectedSkillLevel = widget.community?.skillLevel.isNotEmpty == true
        ? widget.community!.skillLevel
        : null;

    _openToPublic = widget.community?.openToPublic ?? true;

    // Inisialisasi service dengan CookieRequest dari Provider
    _communityService = CommunityService(context.read<CookieRequest>());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    String? errorMessage;

    if (_selectedSport == null || _selectedSport!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a sport.')),
      );
      return;
    }

    if (_selectedSkillLevel == null || _selectedSkillLevel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a skill level.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final sport = _selectedSport!.trim();
    final skillLevel = _selectedSkillLevel!.trim();

    bool success = false;

    try {
      if (_isEditMode) {
        success = await _communityService.updateCommunity(
          slug: widget.community!.slug,
          name: name,
          description: description,
          sport: sport,
          skillLevel: skillLevel,
          openToPublic: _openToPublic,
        );
      } else {
        success = await _communityService.createCommunity(
          name: name,
          description: description,
          sport: sport,
          skillLevel: skillLevel,
          openToPublic: _openToPublic,
        );
      }
    } catch (e) {
      success = false;
      errorMessage = e.toString();
      debugPrint('Community form submit error: $e');
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Community successfully updated.'
                : 'Community successfully created.',
          ),
        ),
      );
      // kirim true supaya halaman sebelumnya bisa decide untuk refresh
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage != null
                ? 'Error: $errorMessage'
                : 'Error occurred while submitting the form. Please try again later.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateToCommunitiesHome(context),
        ),
        title: Text(_isEditMode ? 'Edit Community' : 'Create Community'),
      ),
      body: !request.loggedIn
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Login required to create or edit a community.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAMA KOMUNITAS
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Community Name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Community Name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SPORT / JENIS OLAHRAGA
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSport,
                      decoration: const InputDecoration(
                        labelText: 'Sport',
                        hintText: 'Choose a sport',
                        border: OutlineInputBorder(),
                      ),
                      items: _sportOptions.map((sport) {
                        return DropdownMenuItem<String>(
                          value: sport,
                          child: Text(sport),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSport = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sport is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SKILL LEVEL (DROPDOWN)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Skill Level',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSkillLevel,
                          isExpanded: true,
                          hint: const Text('Choose a skill level'),
                          items: _skillLevelOptions.map((level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSkillLevel = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DESKRIPSI
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 16),

                    // SWITCH OPEN TO PUBLIC
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Public',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Switch(
                          value: _openToPublic,
                          onChanged: (value) {
                            setState(() {
                              _openToPublic = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // TOMBOL SUBMIT
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Save Changes' : 'Create Community',
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
