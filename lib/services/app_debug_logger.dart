import 'dart:math' as math;

import 'package:flutter/foundation.dart';

void appDebugLog(String scope, String message) {
  if (!kDebugMode) {
    return;
  }

  debugPrint('[$scope] $message');
}

String maskToken(String? token) {
  if (token == null || token.isEmpty) {
    return '(empty)';
  }

  final prefixLength = math.min(6, token.length);
  final suffixLength = token.length > 10 ? 4 : 0;
  final prefix = token.substring(0, prefixLength);
  final suffix = suffixLength == 0 ? '' : token.substring(token.length - 4);

  return suffix.isEmpty ? '$prefix***' : '$prefix...$suffix';
}
