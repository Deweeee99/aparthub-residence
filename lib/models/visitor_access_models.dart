class VisitorAccessRecord {
  const VisitorAccessRecord({
    required this.id,
    required this.visitorName,
    required this.visitorPhone,
    required this.visitDate,
    required this.estimatedArrivalTime,
    required this.guestCount,
    required this.visitPurpose,
    required this.status,
    required this.registrationSource,
    required this.qrAvailable,
    required this.approvedAt,
    required this.rejectedAt,
    required this.cancelledAt,
    required this.checkedInAt,
    required this.checkedOutAt,
    required this.expiresAt,
    required this.accessCardNumber,
    required this.identityPhotoUrl,
    required this.unit,
    required this.timeline,
    required this.cancellationReason,
    required this.rejectionReason,
  });

  final int id;
  final String visitorName;
  final String visitorPhone;
  final String visitDate;
  final String estimatedArrivalTime;
  final int guestCount;
  final String visitPurpose;
  final String status;
  final String registrationSource;
  final bool qrAvailable;
  final String approvedAt;
  final String rejectedAt;
  final String cancelledAt;
  final String checkedInAt;
  final String checkedOutAt;
  final String expiresAt;
  final String accessCardNumber;
  final String identityPhotoUrl;
  final VisitorUnit unit;
  final List<Map<String, dynamic>> timeline;
  final String cancellationReason;
  final String rejectionReason;

  factory VisitorAccessRecord.fromJson(Map<String, dynamic> json) {
    return VisitorAccessRecord(
      id: _readInt(json['id']),
      visitorName: _readString(json['visitor_name']),
      visitorPhone: _readString(json['visitor_phone']),
      visitDate: _readString(json['visit_date']),
      estimatedArrivalTime: _readString(json['estimated_arrival_time']),
      guestCount: _readInt(json['guest_count']),
      visitPurpose: _readString(json['visit_purpose']),
      status: _readString(json['status']),
      registrationSource: _readString(json['registration_source']),
      qrAvailable: _readBool(json['qr_available']),
      approvedAt: _readString(json['approved_at']),
      rejectedAt: _readString(json['rejected_at']),
      cancelledAt: _readString(json['cancelled_at']),
      checkedInAt: _readString(json['checked_in_at']),
      checkedOutAt: _readString(json['checked_out_at']),
      expiresAt: _readString(json['expires_at']),
      accessCardNumber: _readString(json['access_card_number']),
      identityPhotoUrl: _readString(json['identity_photo_url']),
      unit: VisitorUnit.fromJson(_readMap(json['unit'])),
      timeline: _readTimeline(json['timeline']),
      cancellationReason: _readString(json['cancellation_reason']),
      rejectionReason: _readString(json['rejection_reason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'visit_date': visitDate,
      'estimated_arrival_time': estimatedArrivalTime,
      'guest_count': guestCount,
      'visit_purpose': visitPurpose,
      'status': status,
      'registration_source': registrationSource,
      'qr_available': qrAvailable,
      'approved_at': approvedAt,
      'rejected_at': rejectedAt,
      'cancelled_at': cancelledAt,
      'checked_in_at': checkedInAt,
      'checked_out_at': checkedOutAt,
      'expires_at': expiresAt,
      'access_card_number': accessCardNumber,
      'identity_photo_url': identityPhotoUrl,
      'unit': unit.toJson(),
      'timeline': timeline,
      'cancellation_reason': cancellationReason,
      'rejection_reason': rejectionReason,
    };
  }
}

class VisitorUnit {
  const VisitorUnit({
    required this.id,
    required this.code,
    required this.tower,
    required this.floor,
  });

  final int id;
  final String code;
  final String tower;
  final int floor;

  factory VisitorUnit.fromJson(Map<String, dynamic> json) {
    return VisitorUnit(
      id: _readInt(json['id']),
      code: _readString(json['code']),
      tower: _readString(json['tower']),
      floor: _readInt(json['floor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'tower': tower, 'floor': floor};
  }

  String get displayLabel {
    final parts = <String>[
      if (tower.trim().isNotEmpty) tower.trim(),
      if (code.trim().isNotEmpty) code.trim(),
    ];
    return parts.isEmpty ? '-' : parts.join(' - ');
  }
}

class VisitorPaginationMeta {
  const VisitorPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory VisitorPaginationMeta.fromJson(Map<String, dynamic> json) {
    return VisitorPaginationMeta(
      currentPage: _readInt(json['current_page']),
      lastPage: _readInt(json['last_page']),
      perPage: _readInt(json['per_page']),
      total: _readInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}

class VisitorQrPass {
  const VisitorQrPass({
    required this.visitorId,
    required this.qrPayload,
    required this.accessCode,
    required this.validUntil,
    required this.status,
  });

  final int visitorId;
  final String qrPayload;
  final String accessCode;
  final String validUntil;
  final String status;

  factory VisitorQrPass.fromJson(Map<String, dynamic> json) {
    return VisitorQrPass(
      visitorId: _readInt(json['visitor_id']),
      qrPayload: _readString(json['qr_payload']),
      accessCode: _readString(json['access_code']),
      validUntil: _readString(json['valid_until']),
      status: _readString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitor_id': visitorId,
      'qr_payload': qrPayload,
      'access_code': accessCode,
      'valid_until': validUntil,
      'status': status,
    };
  }
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
  return value.toString();
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'available';
  }
  return false;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _readTimeline(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .where((item) => item != null)
      .map((item) => _readMap(item))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
