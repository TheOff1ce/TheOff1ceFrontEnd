import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/upload_page.dart';
import '../services/api_service.dart';
import '../hooks/prescription_hook.dart';
import '../services/prescription_service.dart';
import '../utils/constants.dart';
import 'theme/app_theme.dart';

class FarmaGoApp extends StatefulWidget {
  const FarmaGoApp({super.key});
  @override
  State<FarmaGoApp> createState() => _FarmaGoAppState();
}

class _FarmaGoAppState extends State<FarmaGoApp> {
  late final ApiService api;
  late final PrescriptionController controller;
  @override
  void initState() {
    super.initState();
    api = ApiService(AppConfig.apiBaseUrl);
    controller = PrescriptionController(PrescriptionService(api));
  }

  @override
  void dispose() {
    controller.dispose();
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Farma Go',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: HomePage(controller: controller),
      );
}
