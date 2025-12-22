import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:srve_mobile/modules/matches/models/match.dart';
import 'package:srve_mobile/modules/matches/screens/match_form.dart';
import 'package:srve_mobile/modules/matches/screens/match_detail.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  final Color primaryGreen = const Color(0xFF6B7E5A);
  final Color bgBeige = const Color(0xFFF5F5F0);
  int? currentUserId;
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final request = context.read<CookieRequest>();

      debugPrint("=== LOADING CURRENT USER ===");
      debugPrint("Request authenticated: ${request.loggedIn}");

      final response = await request.get(
          "http://localhost:8000/accounts/ajax/profile/"
      );

      debugPrint("Profile response: $response");

      if (response != null && response is Map) {
        if (response['success'] == true && response['data'] != null) {
          final userData = response['data'];
          final userId = userData['id'];

          if (userId != null) {
            setState(() {
              currentUserId = userId is int ? userId : int.tryParse(userId.toString());
              isLoadingUser = false;
            });

            debugPrint("✓ Current User ID set to: $currentUserId");
            return;
          }
        }
      }

      debugPrint("✗ Failed to extract user ID from response");
    } catch (e) {
      debugPrint("✗ Error loading current user: $e");
    }

    setState(() {
      isLoadingUser = false;
      currentUserId = null;
    });
  }

  Future<List<Match>> fetchMatch(CookieRequest request) async {
    try {
      debugPrint("=== FETCHING MATCHES ===");
      debugPrint("Current User ID before fetch: $currentUserId");
      debugPrint("Request logged in: ${request.loggedIn}");

      final response = await request.get(
          'http://localhost:8000/match/json/'
      );

      debugPrint("Matches response type: ${response.runtimeType}");

      if (response is! List) {
        throw Exception("Invalid response format from server");
      }

      List<Match> listMatch = [];

      for (var d in response) {
        if (d != null) {
          try {
            final match = Match.fromJson(d);
            listMatch.add(match);

            // Debug each match's host status
            debugPrint(
                "Match ${match.pk}: "
                    "host=${match.fields.host}, "
                    "isHost=${match.fields.isHost}, "
                    "currentUser=$currentUserId"
            );
          } catch (e) {
            debugPrint("✗ Error parsing match: $e");
            continue;
          }
        }
      }

      debugPrint("✓ Successfully loaded ${listMatch.length} matches");
      return listMatch;
    } catch (e) {
      debugPrint("✗ Failed to fetch matches: $e");
      throw Exception("Failed to fetch matches: $e");
    }
  }

  Future<void> joinMatch(CookieRequest request, int matchId) async {
    try {
      final response = await request.post(
        'http://localhost:8000/match/$matchId/join-flutter/',
        {},
      );

      if (!context.mounted) return;

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Berhasil bergabung ke match!"),
          backgroundColor: Colors.green,
        ));
        setState(() {}); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? "Gagal join"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Terjadi kesalahan koneksi"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // Show loading while user data is being fetched
    if (isLoadingUser) {
      return Scaffold(
        backgroundColor: bgBeige,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading user data...", style: TextStyle(fontFamily: 'Poppins')),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgBeige,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MatchFormPage()),
            );
            setState(() {});
          },
          label: const Text(
            'Create Match',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: primaryGreen,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: primaryGreen,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text(
                    "Match Community",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1599474924187-334a405be2fa?q=80&w=2070&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            "Find matches with other players",
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "Ongoing Matches"),
                    Tab(text: "Match History"),
                  ],
                ),
              ),
            ];
          },
          body: FutureBuilder(
            future: fetchMatch(request),
            builder: (context, AsyncSnapshot<List<Match>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(fontFamily: 'Poppins'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Belum ada data match.",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                );
              } else {
                final ongoing = snapshot.data!.where((m) => !m.fields.isCompleted).toList();
                final history = snapshot.data!.where((m) => m.fields.isCompleted).toList();

                return TabBarView(
                  children: [
                    _buildMatchList(ongoing, request, isHistory: false),
                    _buildMatchList(history, request, isHistory: true),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMatchList(List<Match> matches, CookieRequest request, {required bool isHistory}) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isHistory ? "Belum ada history pertandingan." : "Tidak ada match aktif.",
              style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildCard(matches[index], request, isHistory);
      },
    );
  }

  Widget _buildCard(Match match, CookieRequest request, bool isHistory) {
    Color badgeColor;
    switch (match.fields.jenisOlahraga.toUpperCase()) {
      case 'BADMINTON':
        badgeColor = Colors.orangeAccent;
        break;
      case 'PADEL':
        badgeColor = Colors.blueAccent;
        break;
      default:
        badgeColor = const Color(0xFF6B7E5A);
    }

    int joined = match.fields.players.length;
    int max = match.fields.maxPlayers;
    bool isFull = joined >= max;

    // Get isHost directly from backend response
    bool isHost = match.fields.isHost;

    // Detailed debug logging for this card
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("CARD RENDER - Match ${match.pk}");
    debugPrint("Title: ${match.fields.title}");
    debugPrint("Host ID: ${match.fields.host}");
    debugPrint("Current User ID: $currentUserId");
    debugPrint("isHost from backend: $isHost");
    debugPrint("isHistory: $isHistory");
    debugPrint("Should show MANAGE: ${!isHistory && isHost}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isHistory ? Colors.grey : badgeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.fields.jenisOlahraga.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isHistory)
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                if (isHost && !isHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "YOU'RE HOST",
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.fields.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Host: User ${match.fields.host}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7E5A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.fields.lokasi,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7E5A)),
                    const SizedBox(width: 6),
                    Text(
                      "${match.fields.tanggal.day.toString().padLeft(2, '0')}-"
                          "${match.fields.tanggal.month.toString().padLeft(2, '0')}-"
                          "${match.fields.tanggal.year}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Players Joined",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "$joined",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isFull ? Colors.red : Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              "/$max",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ACTION BUTTON - This is the critical part
                    if (!isHistory) ...[
                      if (isHost)
                      // MANAGE BUTTON for hosts
                        ElevatedButton.icon(
                          onPressed: () async {
                            debugPrint("🎯 MANAGE button pressed for match ${match.pk}");
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchDetailPage(
                                  match: match,
                                  currentUserId: currentUserId ?? 0,
                                  isHost: true,
                                ),
                              ),
                            );
                            setState(() {}); // Refresh after returning
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B7355),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text(
                            "MANAGE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                      // JOIN BUTTON for non-hosts
                        ElevatedButton(
                          onPressed: isFull ? null : () => joinMatch(request, match.pk),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B7E5A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            isFull ? "FULL" : "JOIN MATCH",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}