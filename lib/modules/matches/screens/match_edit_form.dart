import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:srve_mobile/modules/matches/models/match.dart';
import 'package:srve_mobile/modules/matches/screens/match_list.dart';

class MatchEditFormPage extends StatefulWidget {
  final Match match;

  const MatchEditFormPage({super.key, required this.match});

  @override
  State<MatchEditFormPage> createState() => _MatchEditFormPageState();
}

class _MatchEditFormPageState extends State<MatchEditFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late String _title;
  late String _lokasi;
  late String _jenisOlahraga;
  late DateTime _selectedDate;
  late int _maxPlayers;

  final List<String> _sportOptions = ["TENNIS", "BADMINTON", "PADEL"];

  @override
  void initState() {
    super.initState();
    // Isi data awal form dengan data match yang sudah ada
    _title = widget.match.fields.title;
    _lokasi = widget.match.fields.lokasi;
    _jenisOlahraga = widget.match.fields.jenisOlahraga;
    _selectedDate = widget.match.fields.tanggal;
    _maxPlayers = widget.match.fields.maxPlayers;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Boleh edit tanggal masa lalu? Sesuaikan.
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Fungsi Delete
  Future<void> _deleteMatch(CookieRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // GANTI URL sesuai endpoint delete kamu
      final response = await request.post(
        'http://10.0.2.2:8000/match/delete-flutter/${widget.match.pk}/', 
        jsonEncode({}),
      );

      if (context.mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match deleted successfully")));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MatchListPage()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed to delete")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Match', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F0),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteMatch(request),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: "Match Title",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _title = value),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Date
              GestureDetector(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                initialValue: _lokasi,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _lokasi = value),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Sport Type
              DropdownButtonFormField<String>(
                value: _sportOptions.contains(_jenisOlahraga) ? _jenisOlahraga : _sportOptions.first,
                decoration: const InputDecoration(
                  labelText: "Sport",
                  border: OutlineInputBorder(),
                ),
                items: _sportOptions.map((sport) => DropdownMenuItem(value: sport, child: Text(sport))).toList(),
                onChanged: (value) => setState(() => _jenisOlahraga = value!),
              ),
              const SizedBox(height: 16),

              // Max Players
              TextFormField(
                initialValue: _maxPlayers.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Max Players",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _maxPlayers = int.tryParse(value) ?? _maxPlayers),
                validator: (value) => int.tryParse(value!) == null ? "Must be a number" : null,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E5A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // GANTI URL sesuai endpoint edit kamu
                      final response = await request.postJson(
                        "http://10.0.2.2:8000/match/edit-flutter/${widget.match.pk}/",
                        jsonEncode(<String, dynamic>{
                          'title': _title,
                          'lokasi': _lokasi,
                          'tanggal': "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                          'jenis_olahraga': _jenisOlahraga,
                          'max_players': _maxPlayers,
                        }),
                      );

                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match updated successfully!")));
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const MatchListPage()),
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update match")));
                        }
                      }
                    }
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}