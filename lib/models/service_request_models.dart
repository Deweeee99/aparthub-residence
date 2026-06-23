class ServiceRequestCatalog {
  const ServiceRequestCatalog({
    required this.residentId,
    required this.categories,
  });

  final int residentId;
  final List<ServiceCategory> categories;

  factory ServiceRequestCatalog.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceRequestCatalog(
      residentId: _readInt(source['resident_id']),
      categories: _readList(
        source['catalog'],
        (item) => ServiceCategory.fromJson(_mapOf(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resident_id': residentId,
      'catalog': categories.map((item) => item.toJson()).toList(),
    };
  }
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final int id;
  final String name;
  final List<ServiceSubcategory> subcategories;

  factory ServiceCategory.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceCategory(
      id: _readInt(source['id']),
      name: _readString(source['name']),
      subcategories: _readList(
        source['subcategories'],
        (item) => ServiceSubcategory.fromJson(_mapOf(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subcategories': subcategories.map((item) => item.toJson()).toList(),
    };
  }
}

class ServiceSubcategory {
  const ServiceSubcategory({
    required this.id,
    required this.name,
    required this.sla,
  });

  final int id;
  final String name;
  final ServiceSla sla;

  factory ServiceSubcategory.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceSubcategory(
      id: _readInt(source['id']),
      name: _readString(source['name']),
      sla: ServiceSla.fromJson(_mapOf(source['sla'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'sla': sla.toJson()};
  }
}

class ServiceSla {
  const ServiceSla({
    required this.low,
    required this.medium,
    required this.high,
    required this.emergency,
  });

  final int low;
  final int medium;
  final int high;
  final int emergency;

  factory ServiceSla.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceSla(
      low: _readInt(source['Low']),
      medium: _readInt(source['Medium']),
      high: _readInt(source['High']),
      emergency: _readInt(source['Emergency']),
    );
  }

  int minutesForPriority(String priority) {
    return switch (priority) {
      'Low' => low,
      'Medium' => medium,
      'High' => high,
      'Emergency' => emergency,
      _ => 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {'Low': low, 'Medium': medium, 'High': high, 'Emergency': emergency};
  }
}

class ServiceTicketRecord {
  const ServiceTicketRecord({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.rawStatus,
    required this.source,
    required this.slaTargetMinutes,
    required this.slaDueAt,
    required this.slaState,
    required this.assignedTo,
    required this.operationalTimestamp,
    required this.createdAt,
    required this.category,
    required this.subcategory,
    required this.unit,
    required this.attachments,
    required this.timeline,
    required this.completedAt,
  });

  final int id;
  final String ticketNumber;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String rawStatus;
  final String source;
  final int slaTargetMinutes;
  final String slaDueAt;
  final String slaState;
  final String assignedTo;
  final String operationalTimestamp;
  final String createdAt;
  final ServiceSimpleRef category;
  final ServiceSimpleRef subcategory;
  final ServiceSimpleRef unit;
  final List<ServiceAttachment> attachments;
  final List<Map<String, dynamic>> timeline;
  final String completedAt;

  factory ServiceTicketRecord.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceTicketRecord(
      id: _readInt(source['id']),
      ticketNumber: _readString(source['ticket_number']),
      title: _readString(source['title']),
      description: _readString(source['description']),
      priority: _readString(source['priority']),
      status: _readString(source['status']),
      rawStatus: _readString(source['raw_status']),
      source: _readString(source['source']),
      slaTargetMinutes: _readInt(source['sla_target_minutes']),
      slaDueAt: _readString(source['sla_due_at']),
      slaState: _readString(source['sla_state']),
      assignedTo: _readString(source['assigned_to']),
      operationalTimestamp: _readString(source['operational_timestamp']),
      createdAt: _readString(source['created_at']),
      category: ServiceSimpleRef.fromJson(_mapOf(source['category'])),
      subcategory: ServiceSimpleRef.fromJson(_mapOf(source['subcategory'])),
      unit: ServiceSimpleRef.fromJson(_mapOf(source['unit'])),
      attachments: _readList(
        source['attachments'],
        (item) => ServiceAttachment.fromJson(_mapOf(item)),
      ),
      timeline: _readList(source['timeline'], (item) => _mapOf(item)),
      completedAt: _readString(source['completed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'raw_status': rawStatus,
      'source': source,
      'sla_target_minutes': slaTargetMinutes,
      'sla_due_at': slaDueAt,
      'sla_state': slaState,
      'assigned_to': assignedTo,
      'operational_timestamp': operationalTimestamp,
      'created_at': createdAt,
      'category': category.toJson(),
      'subcategory': subcategory.toJson(),
      'unit': unit.toJson(),
      'attachments': attachments.map((item) => item.toJson()).toList(),
      'timeline': timeline,
      'completed_at': completedAt,
    };
  }
}

class ServiceAttachment {
  const ServiceAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.url,
  });

  final int id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String url;

  factory ServiceAttachment.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceAttachment(
      id: _readInt(source['id']),
      fileName: _readString(source['file_name']),
      mimeType: _readString(source['mime_type']),
      fileSize: _readInt(source['file_size']),
      url: _readString(source['url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'url': url,
    };
  }
}

class ServiceSimpleRef {
  const ServiceSimpleRef({
    required this.id,
    required this.name,
    required this.code,
    required this.tower,
    required this.floor,
  });

  final int id;
  final String name;
  final String code;
  final String tower;
  final int floor;

  factory ServiceSimpleRef.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServiceSimpleRef(
      id: _readInt(source['id']),
      name: _readString(source['name']),
      code: _readString(source['code']),
      tower: _readString(source['tower']),
      floor: _readInt(source['floor']),
    );
  }

  String get displayLabel {
    if (name.isNotEmpty) {
      return name;
    }
    if (code.isNotEmpty) {
      return code;
    }
    return '-';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'tower': tower,
      'floor': floor,
    };
  }
}

class ServicePaginationMeta {
  const ServicePaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory ServicePaginationMeta.fromJson(Map<String, dynamic>? json) {
    final source = _mapOf(json);
    return ServicePaginationMeta(
      currentPage: _readInt(source['current_page']),
      lastPage: _readInt(source['last_page']),
      perPage: _readInt(source['per_page']),
      total: _readInt(source['total']),
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

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

String _readString(dynamic value) {
  return value == null ? '' : value.toString();
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

List<T> _readList<T>(dynamic value, T Function(dynamic item) mapper) {
  if (value is List) {
    return value.where((item) => item != null).map(mapper).toList();
  }
  return <T>[];
}
