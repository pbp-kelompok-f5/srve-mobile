import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../providers/booking_provider.dart';
import '../models/facility.dart';
import '../utils/formatters.dart';
import 'facility_detail_page.dart';

class FacilityListPage extends StatefulWidget {
  const FacilityListPage({super.key});

  @override
  State<FacilityListPage> createState() => _FacilityListPageState();
}

class _FacilityListPageState extends State<FacilityListPage> {
  String _query = '';
  String _sportFilter = 'all'; // all | tennis | badminton | padel

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      context.read<BookingProvider>().loadFacilities(request);
    });
  }

  List<Facility> _applyFilter(List<Facility> data) {
    final q = _query.trim().toLowerCase();

    return data.where((f) {
      final sportOk = _sportFilter == 'all' || f.sport == _sportFilter;

      if (!sportOk) return false;
      if (q.isEmpty) return true;

      final hay = '${f.name} ${f.city}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Court'),
        actions: [
          IconButton(
            onPressed: () => context.read<BookingProvider>().loadFacilities(request, force: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, prov, _) {
          final filtered = _applyFilter(prov.facilities);

          return RefreshIndicator(
            onRefresh: () => prov.loadFacilities(request, force: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name/city...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),

                // Sport chips
                Wrap(
                  spacing: 8,
                  children: [
                    _SportChip(
                      label: 'All',
                      active: _sportFilter == 'all',
                      onTap: () => setState(() => _sportFilter = 'all'),
                    ),
                    _SportChip(
                      label: 'Tennis',
                      active: _sportFilter == 'tennis',
                      onTap: () => setState(() => _sportFilter = 'tennis'),
                    ),
                    _SportChip(
                      label: 'Badminton',
                      active: _sportFilter == 'badminton',
                      onTap: () => setState(() => _sportFilter = 'badminton'),
                    ),
                    _SportChip(
                      label: 'Padel',
                      active: _sportFilter == 'padel',
                      onTap: () => setState(() => _sportFilter = 'padel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (prov.facilitiesLoading) ...[
                  const SizedBox(height: 40),
                  const Center(child: CircularProgressIndicator()),
                ] else if (prov.facilitiesError != null) ...[
                  Text(
                    'Gagal memuat facilities:\n${prov.facilitiesError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => prov.loadFacilities(request, force: true),
                    child: const Text('Coba lagi'),
                  ),
                ] else if (filtered.isEmpty) ...[
                  const SizedBox(height: 50),
                  const Center(child: Text('Tidak ada facility yang cocok.')),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _FacilityCard(
                      facility: filtered[i],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FacilityDetailPage(facility: filtered[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SportChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback onTap;

  const _FacilityCard({
    required this.facility,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final f = facility;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('${f.sportDisplay} • ${f.city} • ${f.indoor ? "Indoor" : "Outdoor"}'),
            const SizedBox(height: 6),
            Text('${BookingFormat.rupiah(f.pricePerHour)} / jam • Slot ${f.defaultSlotMinutes} menit'),
          ],
        ),
      ),
    );
  }
}
