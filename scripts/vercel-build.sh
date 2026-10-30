#!/usr/bin/env bash
# Build de Flutter Web para Vercel: la imagen de build de Vercel no trae Flutter, así que se
# descarga la versión fijada en FLUTTER_VERSION y se compila en build/web (outputDirectory).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.8}"
FLUTTER_HOME="${HOME}/flutter-${FLUTTER_VERSION}"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  command -v xz >/dev/null 2>&1 || dnf install -y xz
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${HOME}"
  mv "${HOME}/flutter" "${FLUTTER_HOME}"
fi
export PATH="${FLUTTER_HOME}/bin:${PATH}"
git config --global --add safe.directory "${FLUTTER_HOME}"

flutter config --no-analytics >/dev/null
flutter --version

# Las variables de entorno del proyecto en Vercel se pasan como --dart-define solo si existen;
# sin ellas valen los defaults de lib/utils/constants.dart (servicios desplegados).
defines=()
for name in API_BASE_URL AUTH_BASE_URL PENDIENTES_BASE_URL ORDERS_BASE_URL GEOLOCATION_BASE_URL MAPS_API_KEY; do
  if [ -n "${!name:-}" ]; then defines+=("--dart-define=${name}=${!name}"); fi
done

flutter pub get
flutter build web --release "${defines[@]}"
