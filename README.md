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

Sin `--dart-define`, en web se usa el mismo host que sirve la página (puertos 8000 y 3000), y en Android `10.0.2.2`.

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
