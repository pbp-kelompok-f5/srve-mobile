import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'booking_list_page.dart';

class BookingSuccessPage extends StatelessWidget {
  final int? bookingId;
  final String facilityName;
  final String sportDisplay;
  final String city;
  final String dateIso;     // "YYYY-MM-DD"
  final String slotLabel;   // "HH:MM – HH:MM"
  final int pricePerHour;

  const BookingSuccessPage({
    super.key,
    required this.bookingId,
    required this.facilityName,
    required this.sportDisplay,
    required this.city,
    required this.dateIso,
    required this.slotLabel,
    required this.pricePerHour,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Successful"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // balik ke FacilityListPage
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // icon success
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.12),
              ),
              child: const Icon(Icons.check_circle, size: 60, color: Colors.green),
            ),

            const SizedBox(height: 16),
            const Text(
              "Your booking is confirmed!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Card summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facilityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("$sportDisplay • $city"),
                  const SizedBox(height: 10),
                  Text("Date: $dateIso"),
                  Text("Time: $slotLabel"),
                  const SizedBox(height: 10),
                  Text("Price: ${BookingFormat.rupiah(pricePerHour)} / hour"),
                  if (bookingId != null) ...[
                    const SizedBox(height: 10),
                    Text("Booking ID: $bookingId"),
                  ],
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingListPage()),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text("View My Bookings"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.sports_tennis),
                label: const Text("Book Another Court"),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
