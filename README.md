# Farma Go — Frontend móvil y web

Aplicación Flutter para pacientes de FARMA GO. Permite acceder a la plataforma, gestionar su sesión y analizar fórmulas médicas como parte de una operación que conecta EPS, gestores farmacéuticos, droguerías, repartidores y pacientes. Funciona en Android, iOS y Web.

## Requisitos

- Flutter instalado (`flutter --version`).
- Python 3.11 o superior para el backend.
- Una clave válida de OpenAI o Gemini configurada solamente en el backend. Nunca pongas claves en Flutter ni las subas a Git.

El frontend necesita que el repositorio hermano `TheOff1ceAI` esté ejecutándose en el puerto `8000`. Para el acceso, registro, recuperación de contraseña y Google OAuth también necesita `TheOff1ceAuth` en el puerto `3000`.

## Paso 1: iniciar el backend de IA

Abre una primera terminal de PowerShell:

```powershell
cd "C:\Users\julia\Desktop\TRABAJOS U\8 semestre\SWNT\FarmaGo\TheOff1ceAI"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edita `.env` y configura un proveedor. Ejemplo:

```dotenv
AI_PROVIDER=openai
OPENAI_API_KEY=tu_clave_privada
OPENAI_MODEL=gpt-4.1-mini
MAX_FILE_SIZE_MB=10
CONFIDENCE_THRESHOLD=0.75
```

Inicia el servidor y déjalo abierto:

```powershell
uvicorn app.main:app --reload
```

Verifica que responde en [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs), o ejecuta:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

Debe devolver `status: ok`.

## Paso 2: preparar el frontend

Abre una segunda terminal, sin cerrar la del backend:

```powershell
cd "C:\Users\julia\Desktop\TRABAJOS U\8 semestre\SWNT\FarmaGo\TheOff1ceFrontEnd"
flutter create .
flutter pub get
```

`flutter create .` solo se necesita la primera vez; crea las carpetas nativas de Android, iOS y Web si no existen.

## Paso 3: ejecutar Farma Go

### Chrome / Web

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

El backend permite automáticamente los puertos locales que Flutter asigna. Si aparece `CORS error`, reinicia Uvicorn.

Para probar Google OAuth con una URL local estable, usa el servidor web en el puerto `5173`:

```powershell
flutter run -d web-server --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=AUTH_BASE_URL=http://localhost:3000
```

En `TheOff1ceAuth`, `FRONTEND_URL` debe ser `http://localhost:5173` y el redirect URI autorizado en Google debe ser `http://localhost:3000/auth/google/callback`. El callback temporal del navegador es `/auth/google/callback`; al terminar, la aplicación limpia esa dirección y muestra una ruta de usuario.

Para comprobar una compilación local con rutas directas (por ejemplo, recargando `/login`), ejecuta:

```powershell
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=AUTH_BASE_URL=http://localhost:3000
node tool/local_web_server.js
```

### Android Emulator

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` es la dirección especial que usa Android Emulator para llegar a tu computador. No uses `localhost` en el emulador.

### iOS Simulator

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Teléfono físico

Conecta teléfono y computador a la misma red Wi-Fi. Ejecuta `ipconfig`, identifica la IPv4 de tu computador y úsala, por ejemplo:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Para producción usa HTTPS; nunca expongas las claves ni el servidor de desarrollo a Internet.

## Paso 4: probar el flujo

1. Confirma que Uvicorn sigue ejecutándose.
2. En Farma Go presiona **Analizar fórmula**.
3. Elige cámara o galería.
4. Selecciona una imagen JPG, JPEG, PNG o WEBP que sea legible.
5. Comprueba la vista previa completa, sin recortes.
6. Presiona **Analizar fórmula**.
7. Revisa medicamentos, dosis, frecuencia, duración, cantidad, confianza y advertencias.
8. Usa **Analizar otra fórmula** para empezar de nuevo.

## Problemas frecuentes

| Problema | Solución |
| --- | --- |
| Queda analizando | Revisa la terminal del backend: el proveedor de IA puede tardar o no tener una clave válida. |
| `CORS error` | Reinicia el backend con `uvicorn app.main:app --reload`. |
| Error `415` | Usa JPG, JPEG, PNG o WEBP reales; no cambies manualmente la extensión de otro archivo. |
| Sin conexión | Confirma que el backend está en el puerto `8000` y que `API_BASE_URL` corresponde a la plataforma. |
| Cámara no abre | Acepta el permiso que pide Android, iOS o el navegador. |
| `flutter` no se reconoce | Cierra y abre una nueva terminal o revisa el PATH de Flutter. |

## Arquitectura

- `lib/app`: tema Material 3, rutas declarativas y configuración global.
- `lib/pages`: acceso, inicio, carga, análisis, resultado y cuenta.
- `lib/components`: UI reutilizable.
- `lib/hooks`: estado con `ChangeNotifier`.
- `lib/services`: cámara/galería y carga multipart.
- `lib/types`: modelos y errores.

La imagen se envía en `multipart/form-data`, campo `file`, al endpoint `POST /analyze`. Las páginas no hacen llamadas HTTP directamente.

## Rutas de la aplicación

| Ruta | Uso |
| --- | --- |
| `/` | Información de la plataforma. |
| `/login`, `/register` | Inicio de sesión y creación de cuenta. |
| `/forgot-password`, `/reset-password` | Recuperación de contraseña. |
| `/home` | Inicio protegido de la persona autenticada. |
| `/analyze-prescription` | Selección y análisis de una fórmula. |
| `/notifications` | Centro de actualizaciones de análisis del usuario. |
| `/account` | Datos de cuenta y cierre de sesión. |

Las rutas privadas redirigen a `/login` cuando no existe sesión. Las rutas de análisis sin una imagen o resultado activo explican cómo retomar el flujo en vez de mostrar una pantalla vacía. Las rutas anteriores en español se redirigen a sus equivalentes en inglés para conservar los enlaces existentes.

## Calidad

```powershell
dart analyze
flutter test
```
