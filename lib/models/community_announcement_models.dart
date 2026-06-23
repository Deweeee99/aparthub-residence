class CommunityAnnouncement {
  const CommunityAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isPinned,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final String publishedAt;

  factory CommunityAnnouncement.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};

    return CommunityAnnouncement(
      id: _readString(source['id']),
      title: _readString(source['title']),
      content: _readString(source['content']),
      category: _readString(source['category']),
      isPinned: _readPinnedValue(source['is_pinned']),
      publishedAt: _readString(source['published_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'is_pinned': isPinned,
      'published_at': publishedAt,
    };
  }
}

class AnnouncementPaginationMeta {
  const AnnouncementPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory AnnouncementPaginationMeta.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};

    return AnnouncementPaginationMeta(
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

class CommunityAnnouncementListResponse {
  const CommunityAnnouncementListResponse({
    required this.announcements,
    required this.meta,
  });

  final List<CommunityAnnouncement> announcements;
  final AnnouncementPaginationMeta meta;

  factory CommunityAnnouncementListResponse.fromJson(
    Map<String, dynamic>? json,
  ) {
    final source = json ?? const <String, dynamic>{};
    final data = source['data'];
    final meta = source['meta'];

    return CommunityAnnouncementListResponse(
      announcements: data is List
          ? data
                .where((item) => item != null)
                .map((item) => CommunityAnnouncement.fromJson(_readMap(item)))
                .toList()
          : const <CommunityAnnouncement>[],
      meta: AnnouncementPaginationMeta.fromJson(_readMap(meta)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': announcements.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
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

bool _readPinnedValue(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = _readString(value).trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'pinned';
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return null;
}
