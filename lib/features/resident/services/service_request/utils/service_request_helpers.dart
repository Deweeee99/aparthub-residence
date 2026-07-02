import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/service_request_models.dart';

String formatServiceDateTime(String raw, DateFormat formatter) {
  if (raw.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  return formatter.format(parsed.toLocal());
}

String serviceSlaLabel(ServiceSla sla) {
  final parts = <String>[];
  if (sla.low > 0) {
    parts.add('Low ${sla.low}m');
  }
  if (sla.medium > 0) {
    parts.add('Medium ${sla.medium}m');
  }
  if (sla.high > 0) {
    parts.add('High ${sla.high}m');
  }
  if (sla.emergency > 0) {
    parts.add('Emergency ${sla.emergency}m');
  }
  return parts.isEmpty ? 'SLA not available' : parts.join(' • ');
}

IconData serviceCategoryIcon(String category) {
  return switch (category) {
    'Plumbing' => Icons.plumbing_outlined,
    'Electrical' => Icons.bolt_outlined,
    'Air Conditioning' => Icons.ac_unit_outlined,
    'Housekeeping' => Icons.cleaning_services_outlined,
    'Internet / Wi-Fi' => Icons.wifi_outlined,
    'General Maintenance' => Icons.handyman_outlined,
    _ => Icons.handyman_outlined,
  };
}
