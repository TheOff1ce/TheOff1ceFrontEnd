/// Every user-facing error sentence lives here, so wording stays consistent.
abstract final class ErrorMessages {
  static const network =
      'Parece que no tienes conexión. Revisa tu internet e inténtalo de nuevo.';
  static const timeout =
      'Esto está tardando más de lo normal. Vuelve a intentarlo en un momento.';
  static const server =
      'Algo falló de nuestro lado. Inténtalo de nuevo en unos minutos.';
  static const invalidResponse =
      'Recibimos una respuesta inesperada del servicio. Inténtalo de nuevo en unos minutos.';
  static const unexpected =
      'Algo no salió como esperábamos. Inténtalo de nuevo; si sigue pasando, escríbenos con el código de referencia.';
  static const validation = 'Revisa los datos ingresados e inténtalo de nuevo.';
  static const forbidden =
      'No tienes permiso para hacer esto. Si crees que es un error, escribe a soporte.';
  static const notFound =
      'Esta opción no está disponible en este momento. Inténtalo más tarde.';
  static const conflict =
      'La información cambió mientras la usabas. Vuelve a intentarlo.';
  static const rateLimit =
      'Hiciste muchos intentos seguidos. Espera unos minutos y vuelve a intentarlo.';

  // Authentication
  static const invalidCredentials =
      'El correo o la contraseña no coinciden. Revísalos e inténtalo de nuevo.';
  static const invalidCode =
      'El código no es correcto o ya expiró. Revisa tu correo o pide uno nuevo.';
  static const sessionEnded =
      'Tu sesión terminó. Inicia sesión de nuevo para continuar.';
  static const accountExists =
      'Ya existe una cuenta con este correo. Inicia sesión o recupera tu contraseña.';
  static const accountBlocked =
      'Tu cuenta no puede iniciar sesión en este momento. Escribe a soporte para revisarla.';
  static const resetCodeExpired =
      'Tu código caducó o ya no es válido, así que la contraseña no se cambió. Pide un código nuevo para continuar.';
  static const sessionUnverified =
      'No pudimos comprobar tu sesión porque el servicio no respondió. Revisa tu conexión e inténtalo de nuevo.';
  static const emailDelivery =
      'No pudimos enviar el código a tu correo. Inténtalo de nuevo en unos minutos.';

  // Prescription analysis
  static const invalidFile =
      'No pudimos leer esa imagen. Toma otra foto o elige una imagen JPG, PNG o WEBP de hasta 10 MB.';
  static const unsupportedFile =
      'Ese tipo de archivo no es compatible. Elige una imagen JPG, PNG o WEBP.';
  static const unreadableAnalysis =
      'No pudimos interpretar la fórmula. Intenta con una foto más nítida, completa y bien iluminada.';
  static const analysisUnavailable =
      'El análisis no está disponible en este momento. Inténtalo de nuevo en unos minutos.';
  static const analysisTimeout =
      'El análisis tardó más de lo normal. Vuelve a intentarlo en un momento.';
  static const fileTooLarge =
      'La imagen pesa más de 10 MB. Toma la foto de nuevo o elige una imagen más liviana.';
  static const analysisRequest =
      'No pudimos enviar la imagen. Elígela de nuevo e inténtalo otra vez.';

  // Google sign-in callback codes
  static const googleConflict =
      'Ya tienes una cuenta con este correo. Inicia sesión con tu correo y contraseña.';
  static const googleState =
      'No pudimos confirmar el inicio con Google. Inténtalo de nuevo.';
  static const googleFailed =
      'Google no confirmó tu acceso. Inténtalo de nuevo o usa tu correo y contraseña.';

  // Home deliveries and tracking
  static const orderNotAvailable =
      'Otro repartidor ya tomó este pedido. Elige otro de la lista.';
  static const orderNotCancellable =
      'Este domicilio ya no se puede cancelar porque el repartidor lo recogió.';
  static const deliveryNotFound = 'No encontramos este domicilio. Actualiza la lista.';
  static const addressNotFound =
      'No encontramos una de las direcciones. Revísala (calle, número y ciudad) e inténtalo de nuevo.';
  static const routeNotFound =
      'No hay una ruta disponible entre la farmacia y tu dirección. Revisa las direcciones.';
  static const mapsUnavailable =
      'El servicio de mapas no responde en este momento. Inténtalo de nuevo en unos minutos.';
  static const trackingUnavailable =
      'El seguimiento de domicilios no está disponible ahora. Inténtalo de nuevo en unos minutos.';
  static const invalidStatusTransition =
      'El estado del domicilio cambió. Actualiza la pantalla para ver el estado actual.';
  static const trackingNotActive =
      'La ubicación solo se comparte mientras llevas el pedido.';
  static const locationDisabled =
      'Activa la ubicación del teléfono para compartir tu recorrido con el paciente.';
  static const locationPermission =
      'Permite el acceso a tu ubicación para que el paciente pueda seguir el domicilio.';
  static const locationUnavailable =
      'No pudimos obtener tu ubicación. Revisa el GPS; lo intentaremos de nuevo.';

  // Local device
  static const imagePick =
      'No pudimos abrir la imagen. Revisa que la app tenga permiso para usar la cámara o la galería e inténtalo otra vez.';
}
