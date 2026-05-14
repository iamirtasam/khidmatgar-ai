class Booking {
  final String bookingId;
  final String userName;
  final String service;
  final String location;
  final String dateTime;
  final String providerName;
  final String price;
  final String status;
  final String? notes;

  const Booking({
    required this.bookingId,
    required this.userName,
    required this.service,
    required this.location,
    required this.dateTime,
    required this.providerName,
    required this.price,
    required this.status,
    this.notes,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: _s(json['BookingID'] ?? json['booking_id']),
      userName: _s(json['UserName'] ?? json['user_name']),
      service: _s(json['Service'] ?? json['service']),
      location: _s(json['Location'] ?? json['location']),
      dateTime: _s(json['DateTime'] ?? json['date_time']),
      providerName: _s(json['ProviderName'] ?? json['provider_name']),
      price: _s(json['Price'] ?? json['price']),
      status: _s(json['Status'] ?? json['status']),
      notes: json['Notes']?.toString() ?? json['notes']?.toString(),
    );
  }

  static String _s(dynamic v) => v?.toString() ?? '';
}
