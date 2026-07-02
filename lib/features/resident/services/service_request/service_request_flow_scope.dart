import 'package:flutter/widgets.dart';

import 'service_request_flow_controller.dart';

class ServiceRequestFlowScope
    extends InheritedNotifier<ServiceRequestFlowController> {
  const ServiceRequestFlowScope({
    super.key,
    required ServiceRequestFlowController controller,
    required super.child,
  }) : super(notifier: controller);

  static ServiceRequestFlowController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ServiceRequestFlowScope>();
    assert(scope != null, 'ServiceRequestFlowScope is missing.');
    return scope!.notifier!;
  }
}
