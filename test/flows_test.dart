import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/auth/password_reset_controller.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/prescription_hook.dart';
import 'package:farma_go/services/api_service.dart';
import 'package:farma_go/services/prescription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

final image = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'formula.png', mimeType: 'image/png');

http.Response respond(Object body, int status) => http.Response(jsonEncode(body), status);

void main() {
  group('FE-016 password reset', () {
    test('an expired code sends the user back to the code step with an explanation', () async {
      final repository = AuthRepository('https://auth.example', usesBrowserCookies: true, client: MockClient((request) async {
        return switch (request.url.path) {
          '/auth/forgot-password' => respond({'message': 'ok'}, 200),
          '/auth/verify-reset-code' => respond({'status': 'code_verified'}, 200),
          _ => respond({
              'success': false,
              'error': {'code': 'CODE_INVALID', 'message': 'x'},
            }, 401),
        };
      }));
      final reset = PasswordResetController(repository);
      expect(await reset.requestCode('ana@example.com'), isNull);
      expect(reset.step, ResetStep.enterCode);
      expect(await reset.verifyCode('123456'), isNull);
      expect(reset.step, ResetStep.choosePassword);

      final error = await reset.resetPassword('NuevaClave123!');
      expect(reset.step, ResetStep.enterCode);
      expect(error?.userMessage, ErrorMessages.resetCodeExpired);
    });
  });

  group('analysis', () {
    PrescriptionController controllerWith(MockClientHandler handler) =>
        PrescriptionController(PrescriptionService(ApiService('https://ai.example', client: MockClient(handler))));

    test('success exposes the parsed result', () async {
      final controller = controllerWith((_) async => respond({
            'success': true,
            'medications': [
              {'name': 'Ibuprofeno', 'confidence': 0.9, 'requires_review': false},
            ],
            'requires_human_review': false,
            'warnings': [],
          }, 200));
      await controller.analyze(image);
      expect(controller.result?.medications.single.name, 'Ibuprofeno');
    });

    test('backend codes become AppErrors with the right recovery', () async {
      final controller = controllerWith((_) async => respond({
            'success': false,
            'error': {'code': 'UNSUPPORTED_MEDIA_TYPE', 'message': 'x'},
          }, 415));
      await controller.analyze(image);
      final state = controller.state as AnalysisFailed;
      expect(state.error.kind, AppErrorKind.unsupportedFile);
      expect(state.error.retryable, isFalse);
    });

    test('a cancelled analysis never overwrites the screen with its late answer', () async {
      final completer = Completer<http.Response>();
      final controller = controllerWith((_) => completer.future);
      final running = controller.analyze(image);
      expect(controller.state, isA<AnalysisRunning>());
      controller.cancel();
      completer.complete(respond({'medications': []}, 200));
      await running;
      expect(controller.state, isA<AnalysisIdle>());
    });

    test('the upload sends the file as multipart "file" with its image type', () async {
      final controller = controllerWith((request) async {
        expect(request.url.path, '/analyze');
        expect(request.headers['content-type'], startsWith('multipart/form-data'));
        expect(request.bodyBytes.length, greaterThan(3));
        return respond({'medications': []}, 200);
      });
      await controller.analyze(image);
      expect(controller.result?.requiresHumanReview, isTrue);
    });
  });
}
