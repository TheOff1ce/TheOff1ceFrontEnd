import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'errors/app_error.dart';
import 'pages/system_pages.dart';

void main() {
  if (kIsWeb) usePathUrlStrategy();
  installGlobalErrorHandling();
  runApp(const FarmaGoApp());
}

/// App-level "error boundary" (FE-006): build errors render a friendly
/// fallback and every uncaught error is logged with its stack trace.
void installGlobalErrorHandling() {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    ErrorReporter.reportUnexpected(details.exception, details.stack);
    if (kDebugMode) previousOnError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ErrorReporter.reportUnexpected(error, stackTrace);
    return true;
  };
  if (!kDebugMode) ErrorWidget.builder = (details) => const AppCrashView();
}
