import 'package:image_picker/image_picker.dart';

import '../types/analysis_response.dart';
import 'api_service.dart';

class PrescriptionService {
  PrescriptionService(this._api);
  final ApiService _api;
  Future<AnalysisResponse> analyzePrescription(XFile image) async =>
      AnalysisResponse.fromJson(await _api.uploadImage(image));
}
