import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/api_service.dart';
import 'service_request/pages/service_create_step_page.dart';
import 'service_request/pages/service_history_step_page.dart';
import 'service_request/service_request_flow_controller.dart';
import 'service_request/service_request_flow_scope.dart';
import 'service_request/service_request_routes.dart';

enum ServiceRequestInitialMode { create, history }

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({
    super.key,
    required this.onBack,
    required this.initialMode,
    this.apiService,
    this.attachmentPicker,
  });

  final VoidCallback onBack;
  final ServiceRequestInitialMode initialMode;
  final ApiService? apiService;
  final Future<String?> Function(ImageSource source)? attachmentPicker;

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  late final ServiceRequestFlowController _controller =
      ServiceRequestFlowController(
        apiService: widget.apiService ?? ApiService(),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.initialMode == ServiceRequestInitialMode.history
        ? const ServiceHistoryRequestPage()
        : const ServiceCreateRequestPage();

    return ServiceRequestFlowScope(
      controller: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            widget.onBack();
          }
        },
        child: child,
      ),
    );
  }
}

extension ServiceRequestRouteNavigation on BuildContext {
  void goToServicesHub() => go(ServiceRequestRoutes.services);
}
