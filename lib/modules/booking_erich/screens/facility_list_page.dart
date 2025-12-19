import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/facility.dart';
import '../services/booking_api_service.dart';


import '../screens/facility_detail_page.dart';


class FacilityListPage extends StatefulWidget {
  const FacilityListPage({super.key});

  @override
  State<FacilityListPage> createState() => _FacilityListPageState();
}

class _FacilityListPageState extends State<FacilityListPage> {
  final _service = const BookingApiService();
  late Future<List<Facility>> _future;

  @override
  void initState() {
    super.initState();
    // future diisi di didChangeDependencies (karena butuh context/provider)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = context.read<CookieRequest>();
    _future = _service.fetchFacilities(request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Court'),
      ),
      body: FutureBuilder<List<Facility>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gagal memuat data facility.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final request = context.read<CookieRequest>();
                      setState(() => _future = _service.fetchFacilities(request));
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada facility.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final f = data[i];
              return _FacilityCard(facility: f);
            },
          );
        },
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final f = facility;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailPage(facility: f),
          ),
        );
      },
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
            Text('Rp ${f.pricePerHour} / jam • Slot ${f.defaultSlotMinutes} menit'),
          ],
        ),
      ),
    );
  }
}
