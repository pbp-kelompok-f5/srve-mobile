import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:srve_mobile/config/erich_booking_api.dart';

class BookingSmokeTestPage extends StatefulWidget {
  const BookingSmokeTestPage({super.key});

  @override
  State<BookingSmokeTestPage> createState() => _BookingSmokeTestPageState();
}

class _BookingSmokeTestPageState extends State<BookingSmokeTestPage> {
  String log = '';
  int? facilityId;
  int? lastBookingId;

  void append(String s) => setState(() => log = '$log\n$s');

  String tomorrowIso() {
    final d = DateTime.now().add(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('Erich Booking API Smoke Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    append('GET alive => ${ErichBookingEnv.alive}');
                    final res = await request.get(ErichBookingEnv.alive);
                    append('alive response: $res');
                  },
                  child: const Text('Alive (seed CSRF)'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    append('GET facilities => ${ErichBookingEnv.facilities}');
                    final res = await request.get(ErichBookingEnv.facilities);

                    if (res is List && res.isNotEmpty && res.first is Map) {
                      facilityId = (res.first as Map)['id'] as int?;
                      append('facilities count=${res.length}, picked facilityId=$facilityId');
                      append('sample: ${jsonEncode(res.first)}');
                    } else {
                      append('Unexpected facilities response: $res');
                    }
                  },
                  child: const Text('Facilities'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (facilityId == null) {
                      append('⚠️ facilityId null. Tekan Facilities dulu.');
                      return;
                    }
                    final dateIso = tomorrowIso();
                    final url = ErichBookingEnv.availability(facilityId!, dateIso);
                    append('GET availability => $url');

                    final res = await request.get(url);
                    append('availability response (short): ${jsonEncode(res).substring(0, 200)}...');
                  },
                  child: const Text('Availability (tomorrow)'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (facilityId == null) {
                      append('⚠️ facilityId null. Tekan Facilities dulu.');
                      return;
                    }
                    // penting: panggil alive dulu biasanya biar CSRF cookie ada
                    await request.get(ErichBookingEnv.alive);

                    final body = {
                      "facility": facilityId,
                      "date": tomorrowIso(),
                      "start": "10:00",
                    };

                    append('POST book => ${ErichBookingEnv.book}');
                    append('payload: $body');

                    final res = await request.postJson(
                      ErichBookingEnv.book,
                      jsonEncode(body),
                    );

                    append('book response: $res');

                    if (res is Map && res["ok"] == true) {
                      lastBookingId = res["booking_id"];
                      append('✅ booking_id=$lastBookingId');
                    }
                  },
                  child: const Text('Book (10:00)'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (lastBookingId == null) {
                      append('⚠️ lastBookingId null. Book dulu.');
                      return;
                    }
                    await request.get(ErichBookingEnv.alive);

                    final body = {"id": lastBookingId};
                    append('POST cancel => ${ErichBookingEnv.cancel}');
                    append('payload: $body');

                    final res = await request.postJson(
                      ErichBookingEnv.cancel,
                      jsonEncode(body),
                    );

                    append('cancel response: $res');
                  },
                  child: const Text('Cancel last booking'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
