import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/booking_item.dart';
import '../services/booking_api_service.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final _service = const BookingApiService();

  bool _loading = true;
  String? _error;
  List<BookingItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final request = context.read<CookieRequest>();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchBookings(request);
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelBooking(BookingItem b) async {
    final request = context.read<CookieRequest>();

    // konfirmasi dulu
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel booking?"),
        content: Text("${b.facilityName}\n${b.date} • ${b.startTime}-${b.endTime}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, cancel")),
        ],
      ),
    );

    if (ok != true) return;

    // Optimistic update: remove dulu, kalau gagal balikin
    final idx = _items.indexWhere((x) => x.id == b.id);
    final removed = b;
    setState(() => _items.removeWhere((x) => x.id == b.id));

    try {
      final success = await _service.cancelBooking(request, b.id);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking canceled.")),
        );
      }
    } catch (e) {
      // rollback kalau gagal
      if (!mounted) return;
      setState(() {
        if (idx >= 0 && idx <= _items.length) {
          _items.insert(idx, removed);
        } else {
          _items.add(removed);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cancel gagal: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        "Gagal memuat booking.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text("Coba lagi"),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text("Belum ada booking.")),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = _items[i];
                          return _BookingCard(
                            booking: b,
                            onCancel: () => _cancelBooking(b),
                          );
                        },
                      ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingItem booking;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return Container(
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
            b.facilityName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text("${b.date} • ${b.startTime}-${b.endTime}"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text("Cancel"),
            ),
          ),
        ],
      ),
    );
  }
}
