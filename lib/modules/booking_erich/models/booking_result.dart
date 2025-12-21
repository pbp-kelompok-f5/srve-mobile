class BookingResult {
  final bool ok;
  final int? bookingId;
  final String? redirect;
  final String? error;

  const BookingResult({
    required this.ok,
    this.bookingId,
    this.redirect,
    this.error,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      ok: json["ok"] == true,
      bookingId: (json["booking_id"] is int) ? json["booking_id"] as int : null,
      redirect: json["redirect"]?.toString(),
      error: json["error"]?.toString(),
    );
  }
}
