import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:srve_mobile/modules/matches/screens/match_list.dart';
import 'package:srve_mobile/widgets/left_drawer.dart';

class MatchFormPage extends StatefulWidget {
  const MatchFormPage({super.key});

  @override
  State<MatchFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends State<MatchFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";
  String _lokasi = "";
  String _jenisOlahraga = "TENNIS";
  DateTime? _selectedDate;
  String _tanggal = "";
  int _maxPlayers = 2;

  final List<String> _sportOptions = ["TENNIS", "BADMINTON", "PADEL"];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggal = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Match', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F0),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Title Field
              const Text(
                "Match Title",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Enter match title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (String? value) => setState(() => _title = value ?? ""),
                validator: (String? value) => (value == null || value.isEmpty) ? "Match title is required" : null,
              ),
              const SizedBox(height: 20),

              // Date and Location Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Date",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? "Select date"
                                      : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _selectedDate == null ? Colors.grey : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6B7E5A)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: "Enter location",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (String? value) => setState(() => _lokasi = value ?? ""),
                          validator: (String? value) => (value == null || value.isEmpty) ? "Location is required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sports and Player Limit Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sports",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _jenisOlahraga,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _sportOptions
                              .map((sport) => DropdownMenuItem(
                                    value: sport,
                                    child: Text(sport, style: const TextStyle(fontFamily: 'Poppins')),
                                  ))
                              .toList(),
                          onChanged: (String? value) {
                            setState(() => _jenisOlahraga = value ?? "TENNIS");
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Player Limit",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _maxPlayers.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "e.g., 4",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (String? value) {
                            setState(() => _maxPlayers = int.tryParse(value ?? "2") ?? 2);
                          },
                          validator: (String? value) {
                            if (value == null || value.isEmpty) return "Required";
                            final num = int.tryParse(value);
                            if (num == null || num < 2) return "Minimum 2";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Create Match Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E5A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                      final response = await request.postJson(
                        "https://khayru-rafamanda-srve.pbp.cs.ui.ac.id/match/create-flutter/",
                        jsonEncode(<String, String>{
                          'title': _title,
                          'lokasi': _lokasi,
                          'tanggal': _tanggal,
                          'jenis_olahraga': _jenisOlahraga,
                          'max_players': _maxPlayers.toString(),
                        }),
                      );
                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match berhasil disimpan!")));
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MatchListPage()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Terdapat kesalahan, silakan coba lagi.")));
                        }
                      }
                    } else if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a date")));
                    }
                  },
                  child: const Text(
                    "+ Create Match",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
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