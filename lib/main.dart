import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'auth/auth_controller.dart';
import 'errors/app_error.dart';
import 'pages/system_pages.dart';

void main() {
  if (kIsWeb) usePathUrlStrategy();
  installGlobalErrorHandling();
  // Read before the router replaces the URL: the code lives only in the fragment.
  final googleHandoffCode = kIsWeb ? AuthController.googleHandoffCodeFrom(Uri.base) : null;
  runApp(FarmaGoApp(googleHandoffCode: googleHandoffCode));
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
