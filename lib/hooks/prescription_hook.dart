import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/prescription_service.dart';
import '../types/analysis_response.dart';
import '../types/api_error.dart';

enum PrescriptionStatus { idle, analyzing, success, failure }

class PrescriptionController extends ChangeNotifier {
  PrescriptionController(this._service);
  final PrescriptionService _service;
  PrescriptionStatus status = PrescriptionStatus.idle;
  AnalysisResponse? result;
  ApiError? error;
  Future<void> analyze(XFile image) async {
    status = PrescriptionStatus.analyzing;
    error = null;
    notifyListeners();
    try {
      result = await _service.analyzePrescription(image);
      status = PrescriptionStatus.success;
    } on ApiError catch (e) {
      error = e;
      status = PrescriptionStatus.failure;
    } catch (_) {
      error = const ApiError(
        ApiErrorType.unexpected,
        'Ocurrió un error inesperado.',
      );
      status = PrescriptionStatus.failure;
    }
    notifyListeners();
  }

  void reset() {
    status = PrescriptionStatus.idle;
    result = null;
    error = null;
    notifyListeners();
  }
}
