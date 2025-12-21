import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/facility.dart';
import '../models/slot.dart';
import '../models/booking_item.dart';
import '../models/booking_result.dart';
import '../services/booking_api_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _api;
  BookingProvider({BookingApiService? api}) : _api = api ?? const BookingApiService();

  // Facilities
  List<Facility> facilities = [];
  bool facilitiesLoading = false;
  String? facilitiesError;

  // Slots cache: key = "facilityId|YYYY-MM-DD"
  final Map<String, List<Slot>> _slotsCache = {};
  bool slotsLoading = false;
  String? slotsError;

  // Bookings list
  List<BookingItem> bookings = [];
  bool bookingsLoading = false;
  String? bookingsError;

  // Action states
  bool bookingSubmitting = false;
  String? bookingSubmitError;

  final Set<int> cancellingIds = {};

  String _slotKey(int facilityId, String dateIso) => '$facilityId|$dateIso';

  List<Slot>? getCachedSlots(int facilityId, String dateIso) {
    return _slotsCache[_slotKey(facilityId, dateIso)];
  }

  Future<void> loadFacilities(CookieRequest request, {bool force = false}) async {
    if (!force && facilities.isNotEmpty) return;

    facilitiesLoading = true;
    facilitiesError = null;
    notifyListeners();

    try {
      facilities = await _api.fetchFacilities(request);
    } catch (e) {
      facilitiesError = e.toString();
    } finally {
      facilitiesLoading = false;
      notifyListeners();
    }
  }

  Future<List<Slot>> loadSlots(
    CookieRequest request, {
    required int facilityId,
    required String dateIso,
    bool force = false,
  }) async {
    final key = _slotKey(facilityId, dateIso);

    if (!force && _slotsCache.containsKey(key)) {
      return _slotsCache[key]!;
    }

    slotsLoading = true;
    slotsError = null;
    notifyListeners();

    try {
      final data = await _api.fetchAvailability(
        request,
        facilityId: facilityId,
        dateIso: dateIso,
      );
      _slotsCache[key] = data;
      return data;
    } catch (e) {
      slotsError = e.toString();
      rethrow;
    } finally {
      slotsLoading = false;
      notifyListeners();
    }
  }

  void clearSlotCacheForFacilityDay(int facilityId, String dateIso) {
    _slotsCache.remove(_slotKey(facilityId, dateIso));
    notifyListeners();
  }

  Future<BookingResult> bookSlot(
    CookieRequest request, {
    required int facilityId,
    required String dateIso,
    required String startHHmm,
  }) async {
    bookingSubmitting = true;
    bookingSubmitError = null;
    notifyListeners();

    try {
      final res = await _api.bookSlot(
        request,
        facilityId: facilityId,
        dateIso: dateIso,
        startHHmm: startHHmm,
      );
      if (!res.ok) bookingSubmitError = res.error ?? "Booking gagal";
      return res;
    } catch (e) {
      bookingSubmitError = e.toString();
      return BookingResult(ok: false, error: bookingSubmitError);
    } finally {
      bookingSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings(CookieRequest request, {bool force = false}) async {
    bookingsLoading = true;
    bookingsError = null;
    notifyListeners();

    try {
      bookings = await _api.fetchBookings(request);
    } catch (e) {
      bookingsError = e.toString();
    } finally {
      bookingsLoading = false;
      notifyListeners();
    }
  }


  bool isCancelling(int bookingId) => cancellingIds.contains(bookingId);

  Future<void> cancelBooking(CookieRequest request, int bookingId) async {
    cancellingIds.add(bookingId);
    notifyListeners();

    try {
      await _api.cancelBooking(request, bookingId);
      bookings.removeWhere((b) => b.id == bookingId);
    } catch (e) {
      // penting: biar UI bisa show SnackBar error
      rethrow;
    } finally {
      cancellingIds.remove(bookingId);
      notifyListeners();
    }
  }

}
