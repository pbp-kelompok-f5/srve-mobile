import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:srve_mobile/modules/matches/models/match.dart';
import 'package:srve_mobile/modules/matches/models/submatch.dart';
import 'package:srve_mobile/modules/matches/screens/match_list.dart';
import 'package:srve_mobile/modules/matches/screens/match_edit_form.dart';

class MatchDetailPage extends StatefulWidget {
  final Match match;
  final int currentUserId;
  final bool isHost;

  const MatchDetailPage({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.isHost,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  final Color primaryGreen = const Color(0xFF6B7E5A);
  String? selectedPairing = "Single (1 vs 1)";
  bool isLoading = false;
  List<SubMatch> submatches = [];
  bool hasGeneratedPairings = false;

  @override
  void initState() {
    super.initState();
    _loadSubmatches();
  }

  // Load submatches dari backend
  Future<void> _loadSubmatches() async {
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(
        'http://localhost:8000/match/${widget.match.pk}/submatches/',
      );

      debugPrint("Submatches response: $response");

      if (response != null && response['status'] == 'success') {
        final List<dynamic> data = response['data'];
        setState(() {
          submatches = data.map((json) => SubMatch.fromJson(json)).toList();
          hasGeneratedPairings = submatches.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Error loading submatches: $e");
      setState(() {
        hasGeneratedPairings = false;
      });
    }
  }

  Future<void> _generatePairings(CookieRequest request) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Generate Pairings"),
          content: Text("Generate $selectedPairing pairings for this match?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => isLoading = true);

                final matchType = selectedPairing == "Single (1 vs 1)" ? "single" : "double";

                try {
                  final response = await request.postJson(
                    'http://localhost:8000/match/${widget.match.pk}/generate-pairings-flutter/',
                    jsonEncode({'match_type': matchType}),
                  );

                  debugPrint("Generate pairings response: $response");

                  if (!context.mounted) return;

                  if (response['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Pairings generated: $selectedPairing"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload submatches setelah generate
                    await _loadSubmatches();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? "Failed to generate pairings"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error generating pairings: $e");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: const Text("Generate", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error in generate pairings dialog: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateScore(CookieRequest request, int submatchId, String team) async {
    try {
      final response = await request.postJson(
        'http://localhost:8000/match/submatch/$submatchId/update-score-flutter/',
        jsonEncode({'team': team}),
      );

      debugPrint("Update score response: $response");

      if (response['status'] == 'success') {
        // Update local state
        setState(() {
          final index = submatches.indexWhere((s) => s.id == submatchId);
          if (index != -1) {
            submatches[index] = SubMatch(
              id: submatchId,
              playersA: submatches[index].playersA,
              playersB: submatches[index].playersB,
              scoreA: response['score_A'],
              scoreB: response['score_B'],
            );
          }
        });
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to update score"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error updating score: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _endMatch(CookieRequest request) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("End Match"),
          content: const Text("Are you sure you want to end this match?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => isLoading = true);

                final response = await request.post(
                  'http://localhost:8000/match/${widget.match.pk}/end-match-flutter/',
                  {},
                );

                setState(() => isLoading = false);

                if (!context.mounted) return;

                if (response['status'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Match ended successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MatchListPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? "Failed to end match"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("End Match", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Details", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: widget.isHost ? [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Match',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchEditFormPage(match: widget.match),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
          ),
        ] : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.match.fields.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "● LIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.match.fields.lokasi,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "${widget.match.fields.tanggal.day.toString().padLeft(2, '0')}-${widget.match.fields.tanggal.month.toString().padLeft(2, '0')}-${widget.match.fields.tanggal.year}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Players Section
                  Text(
                    "Players",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.match.fields.players.length}/${widget.match.fields.maxPlayers} Joined",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.match.fields.players.length,
                            itemBuilder: (context, index) {
                              final playerId = widget.match.fields.players[index];
                              final isHostPlayer = playerId == widget.match.fields.host;

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: primaryGreen,
                                            child: Text(
                                              playerId.toString()[0].toUpperCase(),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "User $playerId",
                                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isHostPlayer)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "HOST",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate Pairings Section (only if host)
                  if (widget.isHost) ...[
                    Text(
                      "Generate Pairings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedPairing,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: [
                                "Single (1 vs 1)",
                                "Double (2 vs 2)",
                              ]
                                  .map((pairing) => DropdownMenuItem(
                                        value: pairing,
                                        child: Text(pairing, style: const TextStyle(fontFamily: 'Poppins')),
                                      ))
                                  .toList(),
                              onChanged: (String? value) {
                                setState(() => selectedPairing = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _generatePairings(request),
                                child: const Text(
                                  "Generate Pairings",
                                  style: TextStyle(
                                    color: Colors.white,
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
                    const SizedBox(height: 24),

                    // LIVE SCORING SECTION
                    if (hasGeneratedPairings) ...[
                      Row(
                        children: [
                          Icon(Icons.bar_chart, color: primaryGreen, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Live Scoring",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // List of Pairings
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: submatches.length,
                        itemBuilder: (context, index) {
                          final submatch = submatches[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Player A
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          submatch.playersA,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          submatch.scoreA.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateScore(request, submatch.id, 'A'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text(
                                            "+ Add Score",
                                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // VS
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      "VS",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  
                                  // Player B
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          submatch.playersB,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          submatch.scoreB.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateScore(request, submatch.id, 'B'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text(
                                            "+ Add Score",
                                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Button - End Match (only if host)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _endMatch(request),
                        child: const Text(
                          "End Match Session",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          // Navigate to edit page for cancel match
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchEditFormPage(match: widget.match),
                            ),
                          );
                        },
                        child: const Text(
                          "Cancel Match",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}