# Farma Go — Frontend móvil y web

Aplicación Flutter para pacientes de FARMA GO: registro e inicio de sesión (correo + código, o Google en web), análisis de fórmulas médicas con IA, resultados y notificaciones. Plataformas soportadas: **Android, iOS y Web**.

## Requisitos

- Flutter estable (`flutter --version`).
- `TheOff1ceAuth` en el puerto 3000 y `TheOff1ceAI` en el puerto 8000 (por ejemplo con `docker compose -f docker-compose-up.yml up --build` desde la carpeta raíz de FarmaGo).
- Nunca se configuran claves ni secretos en Flutter. El access token de Auth vive solo en memoria y se envía a AI como `Authorization: Bearer`.

## Preparar

```powershell
flutter pub get
flutter analyze
flutter test
```

## Ejecutar

```powershell
# Web en un puerto fijo (necesario para Google OAuth y para que Auth acepte el origen)
flutter run -d web-server --web-hostname localhost --web-port 5173 `
  --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=AUTH_BASE_URL=http://localhost:3000

# Android Emulator (10.0.2.2 llega al computador)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=AUTH_BASE_URL=http://10.0.2.2:3000

# iOS Simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=AUTH_BASE_URL=http://localhost:3000
```

Sin `--dart-define`, **Auth y la IA apuntan a los servicios desplegados en Azure** (`https://farmago-auth-jl.azurewebsites.net` y `https://farmago-ai-jl.azurewebsites.net`). Para usar los locales, pásalos explícitamente (`--dart-define=AUTH_BASE_URL=http://localhost:3000 --dart-define=API_BASE_URL=http://localhost:8000`). Orders y Geolocation siguen por defecto en local: en web el mismo host que sirve la página (puertos 3002 y 3001) y en Android `10.0.2.2`.

Atajo para usar los servicios de Azure (puerto 5173 obligatorio, es el origen permitido por CORS):

```powershell
flutter run -d web-server --web-hostname localhost --web-port 5173
```

En `TheOff1ceAuth`, `FRONTEND_URL` debe ser exactamente el origen del frontend (por ejemplo `http://localhost:5173`), y en `TheOff1ceAI`, `ALLOWED_ORIGINS` debe incluirlo. El redirect URI de Google es `http://localhost:3000/auth/google/callback`.

## Compilar para desplegar (web)

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://ai.tu-dominio --dart-define=AUTH_BASE_URL=https://auth.tu-dominio
node tool/local_web_server.js   # prueba local de build/web con rutas directas (SPA) en el puerto 5173
```

Publica `build/web` en cualquier hosting estático con *fallback* a `index.html`. Para que la cookie de refresh funcione, el frontend y Auth deben compartir dominio (por ejemplo `app.tu-dominio` y `auth.tu-dominio`).

## Estructura

```text
lib/
├── app/            tema (tokens Material 3), router (go_router), composición de dependencias
├── auth/           sesión (refresco a los 600 s), recuperación de contraseña, repositorio de Auth
├── errors/         AppError + ErrorMapper + mensajes en español (único lugar)
├── services/       cliente de AI con Bearer, utilidades HTTP con timeouts, imágenes
├── hooks/          estado del análisis
├── pages/ · components/ · notifications/ · types/ · utils/
assets/fonts/       Manrope (OFL)
tool/               servidor local para probar build/web
```

## Domicilios y seguimiento

- **Paciente**: en Inicio, *Pedir medicamento a casa* (farmacia, dirección y productos) y *Mis domicilios*. Cada pedido abre el **seguimiento en vivo**: mapa con la ruta, la ubicación del repartidor, la ETA y el estado.
- Las listas muestran el estado real del envío (Geolocation): *Buscando repartidor*, *En camino*, *Entregado*…; el paciente solo puede cancelar antes de que el repartidor recoja el pedido, y el repartidor deja de ver en *Mis entregas* las que ya terminó.
- **Repartidor** (rol `DELIVERY_DRIVER`): *Domicilios disponibles* para tomar un pedido, ver qué recoger y dónde entregarlo, y avanzar el estado (*Ya recogí el pedido* → *Empezar viaje* → *Marcar como entregado*). Mientras lleva el pedido, la app envía su ubicación cada 10 s y deja de hacerlo al entregar.
- Servicios: `TheOff1ceOrderDelivery` (puerto 3002) y `TheOff1ceGeolocation` (puerto 3001, REST y Socket.IO `/tracking`). Todas las llamadas llevan el `Authorization: Bearer` de Auth; en Socket.IO el token va en el handshake (`auth.token`), nunca en la URL. Si el token vence con el socket abierto, la app lo refresca y se reconecta sola.

```powershell
flutter run -d web-server --web-hostname localhost --web-port 5173 `
  --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=AUTH_BASE_URL=http://localhost:3000 `
  --dart-define=ORDERS_BASE_URL=http://localhost:3002 --dart-define=GEOLOCATION_BASE_URL=http://localhost:3001 `
  --dart-define=MAPS_API_KEY=<clave de cliente, opcional>
```

**Mapa:** sin `MAPS_API_KEY` se muestra una vista simplificada (ruta y puntos dibujados, sin teselas), suficiente para probar con `MAPS_PROVIDER=fake` en Geolocation. Con clave, se usa `google_maps_flutter`. La clave del cliente es **distinta** de la del servidor:

| Plataforma | Dónde va | Restricción en Google Cloud |
|---|---|---|
| Web | `--dart-define=MAPS_API_KEY=...` (la app carga Maps JavaScript API) | *HTTP referrers* (`http://localhost:5173/*`, tu dominio) + solo *Maps JavaScript API* |
| Android | `MAPS_API_KEY=...` en `android/local.properties` (no se sube a git) | App Android (paquete + SHA-1) + solo *Maps SDK for Android* |
| iOS | `MAPS_API_KEY=...` en `ios/Flutter/Secrets.xcconfig` (lo incluyen Debug/Release y no se sube a git) | App iOS (bundle ID) + solo *Maps SDK for iOS* |

La clave del cliente nunca debe tener habilitadas Routes ni Geocoding (esas solo las usa el backend).
