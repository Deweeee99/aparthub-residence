class ResidentFacility {
  const ResidentFacility({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.status,
    required this.capacity,
    required this.description,
    required this.activeBookingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String location;
  final String category;
  final String status;
  final int capacity;
  final String description;
  final int activeBookingCount;
  final String createdAt;
  final String updatedAt;

  factory ResidentFacility.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ResidentFacility(
      id: _readInt(source['id']),
      name: _readString(source['name']),
      location: _readString(source['location']),
      category: _readString(source['category']),
      status: _readString(source['status']),
      capacity: _readInt(source['capacity']),
      description: _readString(source['description']),
      activeBookingCount: _readInt(source['active_booking_count']),
      createdAt: _readString(source['created_at']),
      updatedAt: _readString(source['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'category': category,
      'status': status,
      'capacity': capacity,
      'description': description,
      'active_booking_count': activeBookingCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get capacityLabel => capacity <= 0 ? '-' : 'Max $capacity guests';

  bool get canBook {
    final normalized = status.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'available';
  }
}

class ResidentFacilityAvailability {
  const ResidentFacilityAvailability({
    required this.facility,
    required this.bookingDate,
    required this.operationalStatus,
    required this.requestedTimeSlot,
    required this.isAvailable,
    required this.bookedTimeSlots,
    required this.reason,
  });

  final ResidentFacility facility;
  final String bookingDate;
  final String operationalStatus;
  final String requestedTimeSlot;
  final bool? isAvailable;
  final List<String> bookedTimeSlots;
  final String reason;

  String get facilityStatus => operationalStatus;

  List<String> get blockedSlots => bookedTimeSlots;

  factory ResidentFacilityAvailability.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ResidentFacilityAvailability(
      facility: ResidentFacility.fromJson(_mapOf(source['facility'])),
      bookingDate: _readString(source['booking_date']),
      operationalStatus: _readString(
        source['operational_status'] ?? source['facility_status'],
      ),
      requestedTimeSlot: _readString(source['requested_time_slot']),
      isAvailable: _readNullableBool(source['is_available']),
      bookedTimeSlots: _readList(
        source['booked_time_slots'] ?? source['blocked_slots'],
        _readSlotLabel,
      ),
      reason: _readString(source['reason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility': facility.toJson(),
      'booking_date': bookingDate,
      'operational_status': operationalStatus,
      'requested_time_slot': requestedTimeSlot,
      'is_available': isAvailable,
      'booked_time_slots': bookedTimeSlots,
      'reason': reason,
    };
  }

  bool get facilityCanBook {
    final normalized = facilityStatus.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'available';
  }

  bool isSlotBlocked(String slot) {
    final normalized = slot.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return blockedSlots.any((item) {
      final value = item.trim().toLowerCase();
      return value == normalized ||
          value.startsWith('$normalized ') ||
          value.startsWith('$normalized-');
    });
  }
}

class FacilityBookingRecord {
  const FacilityBookingRecord({
    required this.id,
    required this.facilityId,
    required this.bookingTitle,
    required this.bookingDate,
    required this.timeSlot,
    required this.notes,
    required this.status,
    required this.cancellationReason,
    required this.facility,
    required this.residentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int facilityId;
  final String bookingTitle;
  final String bookingDate;
  final String timeSlot;
  final String notes;
  final String status;
  final String cancellationReason;
  final ResidentFacility facility;
  final String residentId;
  final String createdAt;
  final String updatedAt;

  factory FacilityBookingRecord.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    final facility = ResidentFacility.fromJson(_mapOf(source['facility']));
    return FacilityBookingRecord(
      id: _readInt(source['id']),
      facilityId: _readInt(source['facility_id']) == 0
          ? facility.id
          : _readInt(source['facility_id']),
      bookingTitle: _readString(
        source['booking_title'] ?? source['title'] ?? source['facility_name'],
      ),
      bookingDate: _readString(source['booking_date'] ?? source['date']),
      timeSlot: _readString(source['time_slot'] ?? source['slot']),
      notes: _readString(source['notes']),
      status: _readString(source['status']),
      cancellationReason: _readString(source['cancellation_reason']),
      facility: facility,
      residentId: _readString(source['resident_id']),
      createdAt: _readString(source['created_at']),
      updatedAt: _readString(source['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facility_id': facilityId,
      'booking_title': bookingTitle,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'notes': notes,
      'status': status,
      'cancellation_reason': cancellationReason,
      'facility': facility.toJson(),
      'resident_id': residentId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get displayCode => id == 0 ? '-' : 'FB-$id';

  String get facilityName {
    if (facility.name.trim().isNotEmpty) {
      return facility.name;
    }
    return bookingTitle.trim().isEmpty ? '-' : bookingTitle;
  }

  String get facilityLocation {
    return facility.location.trim().isEmpty ? '-' : facility.location;
  }

  bool get canCancel {
    final normalized = status.trim().toLowerCase();
    return normalized != 'cancelled' &&
        normalized != 'completed' &&
        normalized != 'rejected';
  }
}

class FacilityBookingPaginationMeta {
  const FacilityBookingPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;

  factory FacilityBookingPaginationMeta.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return FacilityBookingPaginationMeta(
      currentPage: _readInt(source['current_page']),
      lastPage: _readInt(source['last_page']),
      perPage: _readInt(source['per_page']),
      total: _readInt(source['total']),
      from: _readInt(source['from']),
      to: _readInt(source['to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
    };
  }
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<T> _readList<T>(dynamic value, T Function(dynamic item) mapper) {
  if (value is! List) {
    return const [];
  }
  return value
      .where((item) => item != null)
      .map(mapper)
      .toList(growable: false);
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

bool? _readNullableBool(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'available') {
    return true;
  }
  if (normalized == 'false' ||
      normalized == '0' ||
      normalized == 'no' ||
      normalized == 'booked' ||
      normalized == 'blocked') {
    return false;
  }
  return null;
}

String _readSlotLabel(dynamic item) {
  if (item is String || item is num) {
    return item.toString().trim();
  }
  final source = _mapOf(item);
  return _readString(
    source['time_slot'] ??
        source['slot'] ??
        source['requested_time_slot'] ??
        source['label'],
  );
}
