import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../../../../models/service_request_models.dart';
import '../../../../services/api_service.dart';
import 'service_request_routes.dart';
import 'utils/service_request_helpers.dart';

class ServiceRequestFlowController extends ChangeNotifier {
  ServiceRequestFlowController({required ApiService apiService})
    : _apiService = apiService;

  static const priorities = ['Low', 'Medium', 'High', 'Emergency'];

  final ApiService _apiService;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final preferredScheduleController = TextEditingController();
  final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');

  ServiceRequestCatalog? catalog;
  List<ServiceTicketRecord> tickets = const [];
  ServiceCategory? selectedCategory;
  ServiceSubcategory? selectedSubcategory;
  ServiceTicketRecord? createdTicket;
  ServiceTicketRecord? trackingTicket;
  List<String> attachmentPaths = const [];

  var priority = 'Medium';
  var historyFilter = 'All';
  var isLoadingCatalog = false;
  var isLoadingHistory = false;
  var isLoadingTicketDetail = false;
  var isSubmitting = false;
  String? errorMessage;

  ServiceTicketRecord? get activeTicket => trackingTicket ?? createdTicket;

  List<String> get historyFilters {
    final statuses = <String>{
      for (final ticket in tickets)
        if (ticket.status.trim().isNotEmpty) ticket.status.trim(),
    }.toList()..sort();
    return ['All', ...statuses];
  }

  List<ServiceTicketRecord> get filteredTickets {
    if (historyFilter == 'All') {
      return tickets;
    }
    return tickets.where((ticket) => ticket.status == historyFilter).toList();
  }

  Future<void> loadCatalog() async {
    isLoadingCatalog = true;
    errorMessage = null;
    notifyListeners();

    try {
      catalog = await _apiService.getServiceRequestCatalog();
    } catch (error) {
      errorMessage = error is ApiServiceException
          ? error.message
          : 'Data layanan belum bisa dimuat. Coba lagi.';
    } finally {
      isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    isLoadingHistory = true;
    errorMessage = null;
    notifyListeners();

    try {
      tickets = await _apiService.getServiceRequests();
    } catch (error) {
      errorMessage = error is ApiServiceException
          ? error.message
          : 'Data layanan belum bisa dimuat. Coba lagi.';
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<ServiceTicketRecord?> submitRequest() async {
    isSubmitting = true;
    notifyListeners();

    try {
      final ticket = await _apiService.createServiceRequest(
        categoryId: selectedCategory!.id,
        subcategoryId: selectedSubcategory!.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        priority: priority,
        residentId: catalog?.residentId == 0 ? null : catalog?.residentId,
        preferredSchedule: preferredScheduleController.text.trim().isEmpty
            ? null
            : preferredScheduleController.text.trim(),
        attachmentPaths: kIsWeb ? const [] : attachmentPaths,
      );
      createdTicket = ticket;
      trackingTicket = ticket;
      tickets = [ticket, ...tickets];
      historyFilter = 'All';
      return ticket;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ServiceTicketRecord?> fetchTicketDetail(int ticketId) async {
    isLoadingTicketDetail = true;
    errorMessage = null;
    notifyListeners();

    try {
      final detail = await _apiService.getServiceRequestDetail(ticketId);
      trackingTicket = detail;
      if (createdTicket?.id == detail.id) {
        createdTicket = detail;
      }
      _upsertTicket(detail);
      return detail;
    } catch (error) {
      errorMessage = error is ApiServiceException
          ? error.message
          : 'Data layanan belum bisa dimuat. Coba lagi.';
      return null;
    } finally {
      isLoadingTicketDetail = false;
      notifyListeners();
    }
  }

  Future<ServiceTicketRecord?> refreshActiveTicket() async {
    final ticket = activeTicket;
    if (ticket == null) {
      return null;
    }
    return fetchTicketDetail(ticket.id);
  }

  void selectCategory(ServiceCategory category) {
    selectedCategory = category;
    selectedSubcategory = null;
    notifyListeners();
  }

  void selectSubcategory(ServiceSubcategory subcategory) {
    selectedSubcategory = subcategory;
    notifyListeners();
  }

  void setPriority(String value) {
    priority = value;
    notifyListeners();
  }

  void setHistoryFilter(String value) {
    historyFilter = value;
    notifyListeners();
  }

  void setTrackingTicket(ServiceTicketRecord ticket) {
    trackingTicket = ticket;
    _upsertTicket(ticket);
    notifyListeners();
  }

  void addAttachment(String path) {
    final selectedPath = path.trim();
    if (selectedPath.isEmpty ||
        attachmentPaths.contains(selectedPath) ||
        attachmentPaths.length >= 3) {
      return;
    }
    attachmentPaths = [...attachmentPaths, selectedPath];
    notifyListeners();
  }

  void removeAttachment(String path) {
    attachmentPaths = attachmentPaths
        .where((item) => item != path)
        .toList(growable: false);
    notifyListeners();
  }

  void resetCreateFlow() {
    selectedCategory = null;
    selectedSubcategory = null;
    createdTicket = null;
    trackingTicket = null;
    attachmentPaths = const [];
    priority = 'Medium';
    errorMessage = null;
    titleController.clear();
    descriptionController.clear();
    preferredScheduleController.clear();
    notifyListeners();
  }

  String formatDateTime(String raw) {
    return formatServiceDateTime(raw, _dateTimeFormat);
  }

  String routeForServiceStatus(ServiceTicketRecord ticket) {
    final status = normalizedServiceStatus(ticket);
    if (status == 'completed' || status == 'done') {
      return ServiceRequestRoutes.completed(ticket.id);
    }
    if (status == 'in progress' || status == 'progress') {
      return ServiceRequestRoutes.progress(ticket.id);
    }
    if (status == 'assigned' ||
        status == 'submitted' ||
        status == 'open' ||
        status == 'pending') {
      return ServiceRequestRoutes.assigned(ticket.id);
    }
    return ServiceRequestRoutes.progress(ticket.id);
  }

  String normalizedServiceStatus(ServiceTicketRecord ticket) {
    final status = ticket.status.trim().isNotEmpty
        ? ticket.status.trim()
        : ticket.rawStatus.trim();
    return status.toLowerCase();
  }

  bool isCompletedTicket(ServiceTicketRecord ticket) {
    final status = normalizedServiceStatus(ticket);
    return ticket.completedAt.trim().isNotEmpty ||
        status == 'completed' ||
        status == 'done';
  }

  bool canShowCompletionAction(ServiceTicketRecord ticket) {
    return isCompletedTicket(ticket);
  }

  bool hasAssignedStaff(ServiceTicketRecord ticket) {
    return ticket.assignedTo.trim().isNotEmpty;
  }

  void _upsertTicket(ServiceTicketRecord ticket) {
    final index = tickets.indexWhere((item) => item.id == ticket.id);
    if (index == -1) {
      tickets = [ticket, ...tickets];
      return;
    }
    tickets = [
      for (var i = 0; i < tickets.length; i++)
        if (i == index) ticket else tickets[i],
    ];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    preferredScheduleController.dispose();
    super.dispose();
  }
}
