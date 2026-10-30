import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../services/prescription_service.dart';
import '../types/analysis_response.dart';

/// Explicit request state: exactly one of these at a time (frontend-guardian §8.2).
sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisRunning extends AnalysisState {
  const AnalysisRunning();
}

class AnalysisSucceeded extends AnalysisState {
  const AnalysisSucceeded(this.result);
  final AnalysisResponse result;
}

class AnalysisFailed extends AnalysisState {
  const AnalysisFailed(this.error);
  final AppError error;
}

class PrescriptionController extends ChangeNotifier {
  PrescriptionController(this._service);

  final PrescriptionService _service;
  AnalysisState state = const AnalysisIdle();
  int _generation = 0;

  AnalysisResponse? get result => switch (state) {
        AnalysisSucceeded(:final result) => result,
        _ => null,
      };

  Future<void> analyze(XFile image) async {
    final generation = ++_generation;
    _emit(const AnalysisRunning());
    AnalysisState next;
    try {
      next = AnalysisSucceeded(await _service.analyzePrescription(image));
    } on AppError catch (error) {
      ErrorReporter.report(error);
      next = AnalysisFailed(error);
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      next = AnalysisFailed(ErrorMapper.fromException(error));
    }
    // A cancelled or superseded analysis never overwrites the newer state.
    if (generation == _generation) _emit(next);
  }

  /// Abandons the analysis in progress; its late answer is ignored.
  void cancel() {
    _generation++;
    if (state is AnalysisRunning) _emit(const AnalysisIdle());
  }

  void reset() {
    _generation++;
    _emit(const AnalysisIdle());
  }

  void _emit(AnalysisState next) {
    state = next;
    notifyListeners();
  }
}
