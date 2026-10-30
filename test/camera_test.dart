import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/camera_capture_page.dart';
import 'package:farma_go/pages/upload_page.dart';
import 'package:farma_go/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' as picker;

class _NoGallery extends ImageService {
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<picker.XFile?> camera() async {
    cameraCalls++;
    return null;
  }

  @override
  Future<picker.XFile?> gallery() async {
    galleryCalls++;
    return null;
  }
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('"Tomar foto" opens the in-app camera, not the file picker', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final images = _NoGallery();
    var cameraOpened = 0;
    await tester.pumpWidget(_app(UploadPage(
      onBack: () {},
      onAnalyze: (_) {},
      images: images,
      takePhoto: (_) async {
        cameraOpened++;
        return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'foto.jpg', mimeType: 'image/jpeg');
      },
    )));
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(cameraOpened, 1);
    expect(images.cameraCalls, 0, reason: 'the file-input camera of image_picker is not used');
    expect(images.galleryCalls, 0);
    expect(find.text('Imagen seleccionada.'), findsOneWidget);
  });

  testWidgets('"Elegir de galería" still uses the gallery picker', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final images = _NoGallery();
    await tester.pumpWidget(_app(UploadPage(onBack: () {}, onAnalyze: (_) {}, images: images, takePhoto: (_) async => null)));
    await tester.tap(find.text('Elegir de galería'));
    await tester.pumpAndSettle();
    expect(images.galleryCalls, 1);
  });

  testWidgets('without a camera it explains it and offers to go back', (tester) async {
    await tester.pumpWidget(_app(CameraCapturePage(loadCameras: () async => const [])));
    await tester.pumpAndSettle();
    expect(find.text(CameraIssue.notFound.message), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('a denied permission explains how to enable it and allows retrying', (tester) async {
    await tester.pumpWidget(_app(CameraCapturePage(
      loadCameras: () async => throw CameraException('CameraAccessDenied', 'denied'),
    )));
    await tester.pumpAndSettle();
    expect(find.text(CameraIssue.denied.message), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  test('maps browser camera errors to clear messages', () {
    expect(CameraIssue.fromCode('cameraNotFound'), CameraIssue.notFound);
    expect(CameraIssue.fromCode('CameraAccessDenied'), CameraIssue.denied);
    expect(CameraIssue.fromCode('cameraPermission'), CameraIssue.denied);
    expect(CameraIssue.fromCode('NotReadableError'), CameraIssue.busy);
    expect(CameraIssue.fromCode('somethingElse'), CameraIssue.failed);
  });
}
