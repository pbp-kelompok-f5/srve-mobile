import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../providers/booking_provider.dart';
import '../models/facility.dart';
import '../utils/formatters.dart';
import 'facility_detail_page.dart';

enum FacilitySort {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}

String facilitySortLabel(FacilitySort s) {
  switch (s) {
    case FacilitySort.nameAsc:
      return "Name (A–Z)";
    case FacilitySort.nameDesc:
      return "Name (Z–A)";
    case FacilitySort.priceAsc:
      return "Price (Low → High)";
    case FacilitySort.priceDesc:
      return "Price (High → Low)";
  }
}

class FacilityListPage extends StatefulWidget {
  const FacilityListPage({super.key});

  @override
  State<FacilityListPage> createState() => _FacilityListPageState();
}

class _FacilityListPageState extends State<FacilityListPage> {
  String _query = '';
  String _sportFilter = 'all'; // all | tennis | badminton | padel
  FacilitySort _sort = FacilitySort.nameAsc; // default: A–Z

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      context.read<BookingProvider>().loadFacilities(request);
    });
  }

  /// Filter berdasarkan sport + query (name/city)
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

  /// Filter + Sort (Nama/Harga)
  List<Facility> _applyFilterAndSort(List<Facility> data) {
    final out = _applyFilter(data);

    out.sort((a, b) {
      switch (_sort) {
        case FacilitySort.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case FacilitySort.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case FacilitySort.priceAsc:
          return a.pricePerHour.compareTo(b.pricePerHour);
        case FacilitySort.priceDesc:
          return b.pricePerHour.compareTo(a.pricePerHour);
      }
    });

    return out;
  }

  PopupMenuButton<FacilitySort> _buildSortMenu() {
    PopupMenuItem<FacilitySort> item(FacilitySort v) {
      final selected = _sort == v;
      return PopupMenuItem(
        value: v,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(facilitySortLabel(v)),
            if (selected) const Icon(Icons.check, size: 18),
          ],
        ),
      );
    }

    return PopupMenuButton<FacilitySort>(
      icon: const Icon(Icons.sort),
      tooltip: "Sort",
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (context) => [
        item(FacilitySort.nameAsc),
        item(FacilitySort.nameDesc),
        const PopupMenuDivider(),
        item(FacilitySort.priceAsc),
        item(FacilitySort.priceDesc),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Court'),
        actions: [
          IconButton(
            onPressed: () => context
                .read<BookingProvider>()
                .loadFacilities(request, force: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          _buildSortMenu(), // ✅ tombol sort
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, prov, _) {
          final filtered = _applyFilterAndSort(prov.facilities); // ✅ sudah disort

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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

                const SizedBox(height: 10),

                // Sort label kecil (biar user tahu lagi mode apa)
                Text(
                  "Sort: ${facilitySortLabel(_sort)}",
                  style: const TextStyle(color: Colors.black54),
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
                            builder: (_) =>
                                FacilityDetailPage(facility: filtered[i]),
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
            Text(
              f.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '${f.sportDisplay} • ${f.city} • ${f.indoor ? "Indoor" : "Outdoor"}',
            ),
            const SizedBox(height: 6),
            Text(
              '${BookingFormat.rupiah(f.pricePerHour)} / jam • Slot ${f.defaultSlotMinutes} menit',
            ),
          ],
        ),
      ),
    );
  }
}
