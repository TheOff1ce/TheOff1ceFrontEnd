import 'package:image_picker/image_picker.dart';

import '../errors/error_mapper.dart';
import '../types/analysis_response.dart';
import 'api_service.dart';

class PrescriptionService {
  PrescriptionService(this._api);

  final ApiService _api;

  Future<AnalysisResponse> analyzePrescription(XFile image) async {
    final json = await _api.uploadImage(image);
    try {
      return AnalysisResponse.fromJson(json);
    } on TypeError catch (error) {
      throw ErrorMapper.fromException(FormatException('Unexpected analysis payload: $error'));
    }
  }
}
