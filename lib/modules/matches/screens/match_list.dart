import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:srve_mobile/modules/matches/models/match.dart';
import 'package:srve_mobile/modules/matches/screens/match_form.dart';
import 'package:srve_mobile/widgets/left_drawer.dart'; // Pastikan path ini benar sesuai struktur teman

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  // Warna Tema SRVE
  final Color primaryGreen = const Color(0xFF6B7E5A);
  final Color bgBeige = const Color(0xFFF5F5F0);

  Future<List<Match>> fetchMatch(CookieRequest request) async {
    // Gunakan 10.0.2.2 untuk Android Emulator
    final response = await request.get('http://10.0.2.2:8000/match/json/');
    var data = response;
    List<Match> listMatch = [];
    for (var d in data) {
      if (d != null) {
        listMatch.add(Match.fromJson(d));
      }
    }
    return listMatch;
  }

  Future<void> joinMatch(CookieRequest request, int matchId) async {
    try {
      final response = await request.post(
        'http://10.0.2.2:8000/match/$matchId/join-flutter/',
        {},
      );

      if (!context.mounted) return;

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Berhasil bergabung ke match!"),
          backgroundColor: Colors.green,
        ));
        setState(() {});
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgBeige,
        drawer: const LeftDrawer(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MatchFormPage()),
            );
            setState(() {});
          },
          label: const Text('Create Match', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
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
                              Colors.black.withValues(alpha: 0.8), // Updated API
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
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Belum ada data match.", style: TextStyle(fontFamily: 'Poppins')));
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
      case 'BADMINTON': badgeColor = Colors.orangeAccent; break;
      case 'PADEL': badgeColor = Colors.blueAccent; break;
      default: badgeColor = const Color(0xFF6B7E5A);
    }

    int joined = match.fields.players.length;
    int max = match.fields.maxPlayers;
    bool isFull = joined >= max;

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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
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
                if (isHistory) const Icon(Icons.check_circle, color: Colors.white, size: 18),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Host: User ${match.fields.host}", style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins')),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7E5A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(match.fields.lokasi, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7E5A)),
                    const SizedBox(width: 6),
                    Text("${match.fields.tanggal.day}-${match.fields.tanggal.month}-${match.fields.tanggal.year}", style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Players Joined", style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins')),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text("$joined", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isFull ? Colors.red : Colors.black, fontFamily: 'Poppins')),
                            Text("/$max", style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                          ],
                        ),
                      ],
                    ),
                    if (!isHistory)
                      ElevatedButton(
                        onPressed: isFull ? null : () => joinMatch(request, match.pk),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7E5A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(isFull ? "FULL" : "JOIN MATCH", style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ),
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