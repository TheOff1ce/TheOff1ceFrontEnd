import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/camera_capture_page.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/card.dart';
import '../components/farmago/dialogs.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/inputs.dart';
import '../components/signature_pad.dart';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../errors/error_messages.dart';
import '../hooks/driver_delivery_controller.dart';
import '../services/image_service.dart';

/// Abre "Registrar entrega" encima del envío. Devuelve `true` si la entrega quedó registrada.
///
/// Es una ventana de una sola tarea (como la cámara): la foto y la firma viven en memoria y no
/// tienen sentido como dirección propia del enrutador.
Future<bool> showRegisterDeliveryProof(
  BuildContext context, {
  required String address,
  required Future<AppError?> Function(DeliveryProofDraft draft) onSubmit,
  Future<XFile?> Function(BuildContext context)? takePhoto,
  ImageService? images,
}) async {
  final registrada = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => RegisterDeliveryProofPage(
      address: address,
      onSubmit: onSubmit,
      takePhoto: takePhoto,
      images: images,
    ),
  ));
  return registrada ?? false;
}

/// CU-14 — el repartidor registra la entrega: foto del pedido entregado, firma de quien recibe,
/// su nombre (opcional) y la ubicación, que se toma al confirmar.
class RegisterDeliveryProofPage extends StatefulWidget {
  const RegisterDeliveryProofPage({
    super.key,
    required this.address,
    required this.onSubmit,
    this.takePhoto,
    this.images,
  });

  /// Tope del servicio para la foto.
  static const maxPhotoBytes = 3 * 1024 * 1024;

  /// Tope del servicio para la firma.
  static const maxSignatureBytes = 512 * 1024;

  static const maxReceiverNameLength = 80;

  final String address;

  /// Devuelve `null` si quedó entregado, o el error (ya humano) a mostrar.
  final Future<AppError?> Function(DeliveryProofDraft draft) onSubmit;

  /// Cámara inyectable (pruebas). En la web, por defecto, la cámara de la app: el selector de
  /// archivos del navegador abre el explorador en el escritorio.
  final Future<XFile?> Function(BuildContext context)? takePhoto;
  final ImageService? images;

  @override
  State<RegisterDeliveryProofPage> createState() => _RegisterDeliveryProofPageState();
}

class _RegisterDeliveryProofPageState extends State<RegisterDeliveryProofPage> {
  late final ImageService _images = widget.images ?? ImageService();
  final _firma = SignaturePadController();
  final _nombre = TextEditingController();
  final _errorKey = GlobalKey();

  Uint8List? _foto;
  String _tipoFoto = 'image/jpeg';
  String? _errorFoto;
  bool _tomandoFoto = false;
  bool _enviando = false;
  AppError? _error;

  static const _pistaCamara = 'Encuadra el pedido entregado en la puerta, con buena luz.';

  @override
  void initState() {
    super.initState();
    _firma.addListener(_cambioFirma);
  }

  @override
  void dispose() {
    _firma
      ..removeListener(_cambioFirma)
      ..dispose();
    _nombre.dispose();
    super.dispose();
  }

  bool _firmaVacia = true;

  /// Solo importa si pasó de vacía a firmada (o al revés); el trazo lo redibuja el propio panel.
  void _cambioFirma() {
    if (!mounted || _firma.isEmpty == _firmaVacia) return;
    setState(() => _firmaVacia = _firma.isEmpty);
  }

  bool get _listo => _foto != null && _firma.isNotEmpty;
  bool get _hayDatos => _foto != null || _firma.isNotEmpty || _nombre.text.trim().isNotEmpty;

  /// Qué falta para poder confirmar (el botón deshabilitado dice por qué).
  String? get _falta => switch ((_foto == null, _firma.isEmpty)) {
        (true, true) => 'Para confirmar, faltan la foto y la firma.',
        (true, false) => 'Para confirmar, falta la foto.',
        (false, true) => 'Para confirmar, falta la firma.',
        (false, false) => null,
      };

  Future<void> _tomarFoto() async {
    if (_tomandoFoto || _enviando) return;
    setState(() {
      _tomandoFoto = true;
      _errorFoto = null;
    });
    try {
      final archivo = await _abrirCamara();
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;
      if (bytes.lengthInBytes > RegisterDeliveryProofPage.maxPhotoBytes) {
        setState(() => _errorFoto = ErrorMessages.proofPhotoTooLarge);
        return;
      }
      setState(() {
        _foto = bytes;
        _tipoFoto = _tipoDe(archivo);
        _error = null;
      });
    } on AppError catch (error) {
      ErrorReporter.report(error);
      if (mounted) setState(() => _errorFoto = error.userMessage);
    } catch (error, stackTrace) {
      ErrorReporter.reportUnexpected(error, stackTrace);
      if (mounted) setState(() => _errorFoto = ErrorMessages.imagePick);
    } finally {
      if (mounted) setState(() => _tomandoFoto = false);
    }
  }

  Future<XFile?> _abrirCamara() {
    final propia = widget.takePhoto;
    if (propia != null) return propia(context);
    if (kIsWeb) return showCameraCapture(context, hint: _pistaCamara);
    return _images.deliveryPhoto();
  }

  /// El servicio acepta JPG, PNG o WEBP; la cámara del teléfono entrega JPG.
  static String _tipoDe(XFile archivo) {
    const aceptados = {'image/jpeg', 'image/png', 'image/webp'};
    final mime = archivo.mimeType;
    if (mime != null && aceptados.contains(mime)) return mime;
    final nombre = archivo.name.toLowerCase();
    if (nombre.endsWith('.png')) return 'image/png';
    if (nombre.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _confirmar() async {
    final foto = _foto;
    if (!_listo || foto == null || _enviando) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    AppError? error;
    try {
      final firma = await _firma.toPng();
      if (firma == null || firma.lengthInBytes > RegisterDeliveryProofPage.maxSignatureBytes) {
        error = AppError(
          kind: AppErrorKind.invalidFile,
          userMessage: ErrorMessages.proofSignatureFailed,
          retryable: true,
          code: 'SIGNATURE_EXPORT',
        );
        ErrorReporter.report(error);
      } else {
        final nombre = _nombre.text.trim();
        error = await widget.onSubmit(DeliveryProofDraft(
          photo: foto,
          photoContentType: _tipoFoto,
          signaturePng: firma,
          receiverName: nombre.isEmpty ? null : nombre,
        ));
      }
    } catch (e, stackTrace) {
      ErrorReporter.reportUnexpected(e, stackTrace);
      error = ErrorMapper.fromException(e);
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _enviando = false;
      _error = error;
    });
    // El aviso queda a la vista, junto a la acción; lo ya hecho (foto, firma y nombre) se conserva.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final destino = _errorKey.currentContext;
      if (destino != null && destino.mounted) {
        Scrollable.ensureVisible(destino, duration: FgMotion.reducir(destino, FgMotion.media));
      }
    });
  }

  Future<void> _salir() async {
    if (_enviando) return;
    if (!_hayDatos) {
      Navigator.of(context).pop(false);
      return;
    }
    final salir = await showFgConfirm(
      context,
      titulo: '¿Salir sin registrar la entrega?',
      mensaje: 'Se descartan la foto y la firma. El pedido sigue en camino y puedes registrarlo después.',
      confirmar: 'Salir sin registrar',
      cancelar: 'Seguir registrando',
    );
    if (salir && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final falta = _falta;
    return PopScope(
      canPop: !_hayDatos && !_enviando,
      onPopInvokedWithResult: (cerro, _) {
        if (!cerro) _salir();
      },
      child: DeliveryScaffold(
        title: 'Registrar entrega',
        onBack: _salir,
        barraAccion: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (falta != null && !_enviando)
              Padding(
                padding: const EdgeInsets.only(bottom: FgSpace.sp2),
                child: Text(falta, style: FgText.caption, textAlign: TextAlign.center),
              ),
            FgButton(
              label: 'Confirmar entrega',
              icon: Icons.task_alt,
              size: FgButtonSize.lg,
              expand: true,
              loading: _enviando,
              loadingLabel: 'Registrando entrega…',
              onPressed: _listo && !_enviando ? _confirmar : null,
            ),
          ],
        ),
        children: [
          Text('Entregar en', style: FgText.caption),
          const SizedBox(height: FgSpace.sp1),
          Text(widget.address, style: FgText.bodyLg),
          const SizedBox(height: FgSpace.sp5),
          _pasoFoto(),
          const SizedBox(height: FgSpace.sp5),
          FgCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Paso 2 de 2', style: FgText.caption),
                const SizedBox(height: FgSpace.sp2),
                SignaturePad(controller: _firma, enabled: !_enviando),
                const SizedBox(height: FgSpace.sp5),
                FgTextField(
                  label: 'Nombre de quien recibe',
                  controller: _nombre,
                  opcional: true,
                  ayuda: 'Útil si lo recibe otra persona, por ejemplo un familiar o el portero.',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(RegisterDeliveryProofPage.maxReceiverNameLength),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: FgSpace.sp5),
          const FgNota(
            texto: 'Al confirmar tomamos tu ubicación para comprobar que estás en la dirección de entrega. '
                'Si no puedes registrar la foto o la firma, el paciente puede cerrar la entrega con tu código.',
          ),
          const SizedBox(height: FgSpace.sp5),
          KeyedSubtree(key: _errorKey, child: ErrorBanner(error: _error)),
          // Espacio para el texto de lo que falta sobre la barra de acción.
          const SizedBox(height: FgSpace.sp6),
        ],
      ),
    );
  }

  Widget _pasoFoto() {
    final foto = _foto;
    final errorFoto = _errorFoto;
    return FgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Paso 1 de 2', style: FgText.caption),
          const SizedBox(height: FgSpace.sp1),
          Text('Foto de la entrega', style: FgText.label),
          const SizedBox(height: FgSpace.sp1),
          Text('Toma una foto del pedido en manos de quien lo recibe o en la puerta.', style: FgText.caption),
          const SizedBox(height: FgSpace.sp3),
          if (foto != null) ...[
            Semantics(
              image: true,
              label: 'Vista previa de la foto de la entrega',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FgRadius.md),
                child: ColoredBox(
                  color: FgColors.fondoHundido,
                  child: SizedBox(
                    height: FgSize.fotoPruebaAlto,
                    width: double.infinity,
                    child: ExcludeSemantics(
                      child: Image.memory(
                        foto,
                        fit: BoxFit.contain,
                        cacheHeight: (FgSize.fotoPruebaAlto * MediaQuery.devicePixelRatioOf(context)).round(),
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(FgSpace.sp4),
                            child: Text(
                              'No pudimos mostrar la vista previa, pero la foto se guardó. Puedes repetirla si quieres.',
                              style: FgText.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: FgSpace.sp3),
          ],
          if (errorFoto != null) ...[
            FgBanner(kind: FgBannerKind.error, message: errorFoto),
            const SizedBox(height: FgSpace.sp3),
          ],
          FgButton(
            label: foto == null ? 'Tomar la foto' : 'Repetir la foto',
            icon: foto == null ? Icons.photo_camera_outlined : Icons.refresh,
            variant: FgButtonVariant.secondary,
            expand: true,
            loading: _tomandoFoto,
            loadingLabel: 'Abriendo la cámara…',
            onPressed: _enviando ? null : _tomarFoto,
          ),
        ],
      ),
    );
  }
}
