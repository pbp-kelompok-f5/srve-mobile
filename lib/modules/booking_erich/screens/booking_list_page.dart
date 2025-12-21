import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../providers/booking_provider.dart';
import '../models/booking_item.dart';
import '../utils/formatters.dart';
import 'package:srve_mobile/modules/profile_cello/screens/login_screen.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  int _segment = 0; // 0 upcoming, 1 past

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      context.read<BookingProvider>().loadBookings(request);
    });
  }

  List<BookingItem> _filtered(List<BookingItem> all) {
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);

    bool isUpcoming(BookingItem b) {
      final d = BookingFormat.parseIsoDate(b.date);
      if (d == null) return true;
      return !d.isBefore(t0); // >= today
    }

    if (_segment == 0) {
      return all.where(isUpcoming).toList();
    } else {
      return all.where((b) => !isUpcoming(b)).toList();
    }
  }

  Future<void> _cancelWithConfirm(BookingItem b) async {
    final request = context.read<CookieRequest>();
    final prov = context.read<BookingProvider>();

    if (!request.loggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

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

    try {
      await prov.cancelBooking(request, b.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking canceled.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cancel gagal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        actions: [
          IconButton(
            onPressed: () => context.read<BookingProvider>().loadBookings(request),
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, prov, _) {
          final items = _filtered(prov.bookings);

          return RefreshIndicator(
            onRefresh: () => prov.loadBookings(request),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // segmented control sederhana
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Upcoming"),
                        selected: _segment == 0,
                        onSelected: (_) => setState(() => _segment = 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Past"),
                        selected: _segment == 1,
                        onSelected: (_) => setState(() => _segment = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (prov.bookingsLoading) ...[
                  const SizedBox(height: 40),
                  const Center(child: CircularProgressIndicator()),
                ] else if (prov.bookingsError != null) ...[
                  Text(
                    'Gagal memuat bookings:\n${prov.bookingsError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => prov.loadBookings(request),
                    child: const Text("Coba lagi"),
                  ),
                ] else if (items.isEmpty) ...[
                  const SizedBox(height: 60),
                  Center(child: Text(_segment == 0 ? "Belum ada booking upcoming." : "Tidak ada booking lampau.")),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = items[i];
                      final cancelling = prov.isCancelling(b.id);

                      return _BookingCard(
                        booking: b,
                        cancelling: cancelling,
                        onCancel: cancelling ? null : () => _cancelWithConfirm(b),
                      );
                    },
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

class _BookingCard extends StatelessWidget {
  final BookingItem booking;
  final bool cancelling;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.cancelling,
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
          Text(b.facilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text("${b.date} • ${BookingFormat.hhmm(b.startTime)}-${BookingFormat.hhmm(b.endTime)}"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: cancelling
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cancel_outlined),
              label: Text(cancelling ? "Canceling..." : "Cancel"),
            ),
          ),
        ],
      ),
    );
  }
}
