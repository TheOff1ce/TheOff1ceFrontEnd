# Farma Go — Frontend móvil

Aplicación Flutter para tomar o seleccionar una fórmula médica, enviarla al agente de Farma Go y mostrar los medicamentos identificados. Funciona en Android, iOS y Web.

## Requisitos

- Flutter instalado (`flutter --version`).
- Python 3.11 o superior para el backend.
- Una clave válida de OpenAI o Gemini configurada solamente en el backend. Nunca pongas claves en Flutter ni las subas a Git.

El frontend necesita que el repositorio hermano `TheOff1ceAI` esté ejecutándose en el puerto `8000`.

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

- `lib/app`: tema Material 3 y configuración global.
- `lib/pages`: inicio, carga, preview, análisis y resultado.
- `lib/components`: UI reutilizable.
- `lib/hooks`: estado con `ChangeNotifier`.
- `lib/services`: cámara/galería y carga multipart.
- `lib/types`: modelos y errores.

La imagen se envía en `multipart/form-data`, campo `file`, al endpoint `POST /analyze`. Las páginas no hacen llamadas HTTP directamente.

## Calidad

```powershell
dart analyze
flutter test
```
