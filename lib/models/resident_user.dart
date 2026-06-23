class ResidentUnit {
  const ResidentUnit({
    required this.id,
    required this.code,
    required this.tower,
    required this.floor,
  });

  final int id;
  final String code;
  final String tower;
  final int floor;

  factory ResidentUnit.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};

    return ResidentUnit(
      id: _readInt(source['id']),
      code: _readString(source['code']),
      tower: _readString(source['tower']),
      floor: _readInt(source['floor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'tower': tower, 'floor': floor};
  }
}

class ResidentUser {
  const ResidentUser({
    required this.id,
    required this.name,
    required this.residentType,
    required this.email,
    required this.mobileNo,
    required this.contractEndDate,
    required this.unit,
    this.token,
  });

  final int id;
  final String name;
  final String residentType;
  final String email;
  final String mobileNo;
  final String contractEndDate;
  final ResidentUnit unit;
  final String? token;

  factory ResidentUser.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};

    return ResidentUser(
      id: _readInt(source['id']),
      name: _readString(source['name']),
      residentType: _readString(source['resident_type']),
      email: _readString(source['email']),
      mobileNo: _readString(source['mobile_no']),
      contractEndDate: _readString(source['contract_end_date']),
      unit: ResidentUnit.fromJson(_readMap(source['unit'])),
      token: _readNullableString(source['token']),
    );
  }

  ResidentUser copyWith({
    int? id,
    String? name,
    String? residentType,
    String? email,
    String? mobileNo,
    String? contractEndDate,
    ResidentUnit? unit,
    String? token,
  }) {
    return ResidentUser(
      id: id ?? this.id,
      name: name ?? this.name,
      residentType: residentType ?? this.residentType,
      email: email ?? this.email,
      mobileNo: mobileNo ?? this.mobileNo,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      unit: unit ?? this.unit,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'resident_type': residentType,
      'email': email,
      'mobile_no': mobileNo,
      'contract_end_date': contractEndDate,
      'unit': unit.toJson(),
      'token': token,
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

  return int.tryParse('${value ?? ''}') ?? 0;
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString();
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  return null;
}
