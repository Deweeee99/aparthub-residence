import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/community_announcement_models.dart';
import '../models/resident_user.dart';
import '../models/service_request_models.dart';
import '../models/visitor_access_models.dart';
import 'api_client.dart';
import 'app_debug_logger.dart';
import 'auth_storage_service.dart';

class ApiServiceException implements Exception {
  const ApiServiceException(this.message);

  final String message;

  @override
  String toString() => 'ApiServiceException($message)';
}

class ApiService {
  ApiService({ApiClient? client, AuthStorageService? authStorageService})
    : _client = client ?? ApiClient(),
      _authStorageService = authStorageService ?? AuthStorageService();

  final ApiClient _client;
  final AuthStorageService _authStorageService;

  Future<ResidentUser?> getCachedResident() async {
    try {
      final residentJson = await _authStorageService.getResidentJson();
      if (residentJson == null || residentJson.isEmpty) {
        appDebugLog('ApiService', 'No cached resident session available');
        return null;
      }

      final decoded = jsonDecode(residentJson);
      if (decoded is! Map) {
        appDebugLog('ApiService', 'Cached resident session has invalid shape');
        return null;
      }

      final resident = ResidentUser.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      appDebugLog(
        'ApiService',
        'Loaded cached resident session for "${resident.name}"',
      );
      return resident;
    } catch (error) {
      appDebugLog(
        'ApiService',
        'Failed to read cached resident session: $error',
      );
      return null;
    }
  }

  Future<ResidentUser> loginResident({
    required String login,
    required String password,
  }) async {
    appDebugLog('ApiService', 'Login started for "$login"');

    try {
      final response = await _client.post(
        '/resident/login',
        data: {'login': login, 'password': password},
      );

      final data = _readResponseData(response.data);
      final resident = ResidentUser.fromJson(data);
      final token = resident.token;

      if (token == null || token.isEmpty) {
        throw const ApiServiceException(
          'Login gagal. Periksa kembali akun dan password Anda.',
        );
      }

      await _authStorageService.saveToken(token);
      await _authStorageService.saveResidentJson(jsonEncode(resident.toJson()));

      appDebugLog(
        'ApiService',
        'Login success for "${resident.name}" with token ${maskToken(token)}',
      );
      return resident;
    } catch (error) {
      appDebugLog('ApiService', 'Login failed for "$login": $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Login gagal. Periksa kembali akun dan password Anda.',
      );
    }
  }

  Future<ResidentUser> getResidentMe() async {
    final token = await _authStorageService.getToken();
    if (token == null || token.isEmpty) {
      appDebugLog('ApiService', 'Session check failed: token missing');
      throw const ApiServiceException('Sesi login Anda sudah berakhir.');
    }

    appDebugLog(
      'ApiService',
      'Validating resident session with token ${maskToken(token)}',
    );

    try {
      final response = await _client.get('/resident/me', token: token);
      final data = _readResponseData(response.data);
      final resident = ResidentUser.fromJson(data).copyWith(token: token);

      await _authStorageService.saveResidentJson(jsonEncode(resident.toJson()));

      appDebugLog(
        'ApiService',
        'Resident session valid for "${resident.name}"',
      );
      return resident;
    } catch (error) {
      appDebugLog('ApiService', 'Resident session validation failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Sesi login Anda sudah berakhir.',
      );
    }
  }

  Future<void> logoutResident() async {
    final token = await _authStorageService.getToken();
    appDebugLog(
      'ApiService',
      'Logout started${token == null || token.isEmpty ? ' without token' : ' with token ${maskToken(token)}'}',
    );

    try {
      if (token != null && token.isNotEmpty) {
        await _client.post('/resident/logout', token: token);
        appDebugLog('ApiService', 'Remote logout completed');
      } else {
        appDebugLog(
          'ApiService',
          'Remote logout skipped because token missing',
        );
      }
    } catch (error) {
      appDebugLog(
        'ApiService',
        'Remote logout failed but session will clear: $error',
      );
    } finally {
      await _authStorageService.clearSession();
      appDebugLog('ApiService', 'Local session cleared');
    }
  }

  Future<ServiceRequestCatalog> getServiceRequestCatalog() async {
    final token = await _requireToken();
    appDebugLog('ApiService', 'Fetching service request catalog');

    try {
      final response = await _client.get(
        '/service-request-catalog',
        token: token,
      );
      final data = _readResponseData(response.data);
      final catalog = ServiceRequestCatalog.fromJson(data);
      appDebugLog(
        'ApiService',
        'Service request catalog loaded with ${catalog.categories.length} categories',
      );
      return catalog;
    } catch (error) {
      appDebugLog('ApiService', 'Service request catalog failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Data layanan belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<List<ServiceTicketRecord>> getServiceRequests() async {
    final token = await _requireToken();
    appDebugLog('ApiService', 'Fetching service request history');

    try {
      final response = await _client.get('/service-requests', token: token);
      final data = _readResponseList(response.data);
      final tickets = data
          .map((item) => ServiceTicketRecord.fromJson(item))
          .toList();
      appDebugLog(
        'ApiService',
        'Service request history loaded with ${tickets.length} tickets',
      );
      return tickets;
    } catch (error) {
      appDebugLog('ApiService', 'Service request history failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Data layanan belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<List<CommunityAnnouncement>> getResidentAnnouncements() async {
    final token = await _requireToken();
    appDebugLog(
      'ApiService',
      'Fetching resident announcements from /resident/announcements',
    );

    try {
      final response = await _client.get(
        '/resident/announcements',
        token: token,
      );
      final data = _readResponseList(response.data);
      final announcements = data
          .map((item) => CommunityAnnouncement.fromJson(item))
          .toList();
      appDebugLog(
        'ApiService',
        'Resident announcements loaded (${response.statusCode ?? 'no-status'}) with ${announcements.length} items',
      );
      return announcements;
    } catch (error) {
      appDebugLog('ApiService', 'Resident announcements failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Pengumuman belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<CommunityAnnouncement> getResidentAnnouncementDetail(
    String announcementId,
  ) async {
    final token = await _requireToken();
    appDebugLog(
      'ApiService',
      'Fetching resident announcement detail from /resident/announcements/$announcementId',
    );

    try {
      final response = await _client.get(
        '/resident/announcements/$announcementId',
        token: token,
      );
      final data = _readResponseData(response.data);
      final announcement = CommunityAnnouncement.fromJson(data);
      appDebugLog(
        'ApiService',
        'Resident announcement detail loaded (${response.statusCode ?? 'no-status'}) for ${announcement.id}',
      );
      return announcement;
    } catch (error) {
      appDebugLog('ApiService', 'Resident announcement detail failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Detail pengumuman belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<List<VisitorAccessRecord>> getResidentVisitors({
    String? status,
  }) async {
    final token = await _requireToken();
    final normalizedStatus = status?.trim();
    final queryParameters =
        normalizedStatus == null ||
            normalizedStatus.isEmpty ||
            normalizedStatus.toLowerCase() == 'all'
        ? null
        : {'status': normalizedStatus};

    appDebugLog(
      'ApiService',
      'Fetching resident visitors${queryParameters == null ? '' : ' with status "$normalizedStatus"'}',
    );

    try {
      final response = await _client.get(
        '/resident/visitors',
        token: token,
        queryParameters: queryParameters,
      );
      final data = _readResponseList(response.data);
      final visitors = data
          .map((item) => VisitorAccessRecord.fromJson(item))
          .toList();
      appDebugLog(
        'ApiService',
        'Resident visitors loaded (${response.statusCode ?? 'no-status'}) with ${visitors.length} items',
      );
      return visitors;
    } catch (error) {
      appDebugLog('ApiService', 'Resident visitors failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Data visitor belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<VisitorAccessRecord> getResidentVisitorDetail(int visitorId) async {
    final token = await _requireToken();
    appDebugLog(
      'ApiService',
      'Fetching resident visitor detail for $visitorId',
    );

    try {
      final response = await _client.get(
        '/resident/visitors/$visitorId',
        token: token,
      );
      final data = _readResponseData(response.data);
      final visitor = VisitorAccessRecord.fromJson(data);
      appDebugLog(
        'ApiService',
        'Resident visitor detail loaded (${response.statusCode ?? 'no-status'}) for ${visitor.id}',
      );
      return visitor;
    } catch (error) {
      appDebugLog('ApiService', 'Resident visitor detail failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Detail visitor belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<VisitorQrPass> getResidentVisitorQr(int visitorId) async {
    final token = await _requireToken();
    appDebugLog('ApiService', 'Fetching resident visitor QR for $visitorId');

    try {
      final response = await _client.get(
        '/resident/visitors/$visitorId/qr',
        token: token,
      );
      final data = _readResponseData(response.data);
      final qrPass = VisitorQrPass.fromJson(data);
      appDebugLog(
        'ApiService',
        'Resident visitor QR loaded (${response.statusCode ?? 'no-status'}) for ${qrPass.visitorId}; status="${qrPass.status}", hasPayload=${qrPass.qrPayload.trim().isNotEmpty}, hasAccessCode=${qrPass.accessCode.trim().isNotEmpty}, validUntil="${qrPass.validUntil}"',
      );
      return qrPass;
    } on DioException catch (error) {
      appDebugLog(
        'ApiService',
        'Resident visitor QR failed: status=${error.response?.statusCode}, body=${error.response?.data}',
      );
      throw _mapToFriendlyException(
        error,
        fallback: 'QR visitor belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    } catch (error) {
      appDebugLog('ApiService', 'Resident visitor QR failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'QR visitor belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<VisitorAccessRecord> createResidentVisitor({
    required String visitorName,
    required String visitorPhone,
    required String visitDate,
    required String estimatedArrivalTime,
    required int guestCount,
    required String visitPurpose,
  }) async {
    final token = await _requireToken();
    appDebugLog('ApiService', 'Creating resident visitor registration');

    try {
      final response = await _client.post(
        '/resident/visitors',
        token: token,
        data: {
          'visitor_name': visitorName.trim(),
          'visitor_phone': visitorPhone.trim(),
          'visit_date': visitDate.trim(),
          'estimated_arrival_time': estimatedArrivalTime.trim(),
          'guest_count': guestCount,
          'visit_purpose': visitPurpose.trim(),
        },
      );
      final data = _readResponseData(response.data);
      final visitor = VisitorAccessRecord.fromJson(data);
      appDebugLog(
        'ApiService',
        'Resident visitor registration created (${response.statusCode ?? 'no-status'}) with id ${visitor.id}',
      );
      return visitor;
    } catch (error) {
      appDebugLog('ApiService', 'Create resident visitor failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Registrasi visitor belum bisa dibuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<ServiceTicketRecord> createServiceRequest({
    required int categoryId,
    required int subcategoryId,
    required String title,
    required String description,
    required String priority,
    int? residentId,
    String? requestedDate,
    String? requestedTime,
    String? preferredSchedule,
    List<String>? attachmentPaths,
  }) async {
    final token = await _requireToken();
    appDebugLog(
      'ApiService',
      'Creating service request for category $categoryId',
    );

    try {
      final formData = FormData.fromMap({
        'subcategory_id': subcategoryId.toString(),
        'title': title.trim(),
        'description': description.trim(),
        'priority': priority,
        if ((preferredSchedule ?? '').isNotEmpty)
          'preferred_schedule': preferredSchedule!.trim(),
      });

      for (final path in (attachmentPaths ?? const <String>[]).take(3)) {
        final trimmedPath = path.trim();
        if (trimmedPath.isEmpty) {
          continue;
        }
        formData.files.add(
          MapEntry('attachments[]', await MultipartFile.fromFile(trimmedPath)),
        );
      }

      final response = await _client.post(
        '/service-requests',
        token: token,
        data: formData,
      );
      final data = _readResponseData(response.data);
      final ticket = ServiceTicketRecord.fromJson(data);
      appDebugLog(
        'ApiService',
        'Service request created with ticket ${ticket.ticketNumber}',
      );
      return ticket;
    } on DioException catch (error) {
      _debugPrintCreateServiceRequestError(error);
      throw _mapToFriendlyException(
        error,
        fallback:
            'Service request belum bisa dikirim. Coba beberapa saat lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    } catch (error) {
      appDebugLog('ApiService', 'Create service request failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback:
            'Service request belum bisa dikirim. Coba beberapa saat lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<ServiceTicketRecord> getServiceRequestDetail(int ticketId) async {
    final token = await _requireToken();
    appDebugLog('ApiService', 'Fetching service request detail for $ticketId');

    try {
      final response = await _client.get(
        '/service-requests/$ticketId',
        token: token,
      );
      final data = _readResponseData(response.data);
      final ticket = ServiceTicketRecord.fromJson(data);
      appDebugLog(
        'ApiService',
        'Service request detail loaded for ${ticket.ticketNumber}',
      );
      return ticket;
    } catch (error) {
      appDebugLog('ApiService', 'Service request detail failed: $error');
      throw _mapToFriendlyException(
        error,
        fallback: 'Data layanan belum bisa dimuat. Coba lagi.',
        unauthorizedMessage: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
  }

  Future<String> _requireToken() async {
    final token = await _authStorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiServiceException(
        'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }
    return token;
  }

  ApiServiceException _mapToFriendlyException(
    Object error, {
    required String fallback,
    String? unauthorizedMessage,
  }) {
    if (error is ApiServiceException) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 422) {
        return ApiServiceException(
          unauthorizedMessage ??
              'Login gagal. Periksa kembali akun dan password Anda.',
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const ApiServiceException(
          'Tidak dapat terhubung ke server. Coba lagi sebentar.',
        );
      }
    }

    return ApiServiceException(fallback);
  }

  void _debugPrintCreateServiceRequestError(DioException error) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[ApiService] ❌ Create service request failed');
    debugPrint('[ApiService] Method: ${error.requestOptions.method}');
    debugPrint('[ApiService] Path: ${error.requestOptions.path}');
    debugPrint('[ApiService] Status: ${error.response?.statusCode}');
    debugPrint('[ApiService] Response body:');
    debugPrint('${error.response?.data}');

    final headers = error.response?.headers.map;
    if (headers != null && headers.isNotEmpty) {
      debugPrint('[ApiService] Response headers:');
      debugPrint('$headers');
    }

    final data = error.requestOptions.data;
    if (data is FormData) {
      debugPrint('[ApiService] Submitted FormData fields:');
      for (final field in data.fields) {
        debugPrint('  ${field.key}: ${field.value}');
      }

      debugPrint('[ApiService] Submitted files count: ${data.files.length}');
      for (final file in data.files) {
        debugPrint('  file field: ${file.key}');
      }
      return;
    }

    debugPrint('[ApiService] Request body: $data');
  }
}

Map<String, dynamic> _readResponseData(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    if (data is List && data.isNotEmpty) {
      return _readMap(data.first);
    }
  }

  throw const ApiServiceException(
    'Terjadi kendala saat membaca data akun resident.',
  );
}

List<Map<String, dynamic>> _readResponseList(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    final data = responseData['data'];
    if (data is List) {
      return data
          .where((item) => item != null)
          .map((item) => _readMap(item))
          .toList();
    }
  }

  return const <Map<String, dynamic>>[];
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
