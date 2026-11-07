# Órdenes y autorizaciones: notas de diseño e implementación

Rama `feature/pantalla-ordenes-autorizaciones`, 7 nov 2026. Fuente de diseño: `handoff-diseno-front-ordenes.md`. Guía de identidad: `docs/farmago-manual-identidad.md`, usado como guía y no como regla fija. Este archivo no modifica el manual: lista lo que convendría actualizar para que lo decida el equipo.

## 1. Qué se construyó

| Capa | Archivos |
|---|---|
| Tipos y servicio | `lib/types/ordenes.dart`, `lib/services/ordenes_service.dart`, `ErrorMapper.fromOrdenes`, `AppError.detalles`, `ORDENES_BASE_URL` |
| Estado | `lib/hooks/ordenes_controller.dart`, `lib/hooks/domicilio_orden_controller.dart` |
| Componentes | `lib/components/farmago/ordenes/` (panel de consulta, tarjeta de orden y fila, barra de pedido, diálogo y hoja), `sello_estado.dart` (anillo y sello genéricos), `entrada.dart` (entrada escalonada, conteo, punto «en vivo», filete de marca) |
| Pantalla y rutas | `lib/pages/ordenes_page.dart`, `/ordenes` y `/ordenes/:ordenId` (solo `PATIENT`), acceso desde el inicio del paciente |
| Pruebas | `test/ordenes_test.dart` (modelos, errores, controladores), `test/ordenes_visual_test.dart` (estados, desbordes a 320 px y texto ×2, accesibilidad) |

Las capturas (goldens) son opcionales porque dependen de la plataforma que rasteriza el texto: `ORDENES_GOLDENS=1 flutter test test/ordenes_visual_test.dart --update-goldens`.

## 2. Supuestos que hay que confirmar

1. **Contrato de la API.** `handoff-front-ordenes.md`, que manda sobre el handoff de diseño, no está en el repo ni en Descargas. Se asumió lo que describen §5.3 y §6 del handoff de diseño:
   - `GET /v1/ordenes` → `{ consultadoEn, eps: {nombre}, documentoEnmascarado, ordenes: [{ ordenId, fechaOrden, vencimiento, vigencia, permiteDomicilio, soloLectura, medicamentos: [{ medicamentoId, dci, concentracion, formaFarmaceutica, cantidad, unidad, laboratorioFabricante, autorizacion, reclamacion, elegibleParaDomicilio, motivosNoElegible }] }] }`.
   - `POST /v1/ordenes/{id}/domicilio/verificacion` y `POST /v1/ordenes/{id}/domicilio` con `{ medicamentoIds }` (y `solicitudId` en el segundo); el 202 trae `referencia`.
   - Errores con `code` (en la raíz o dentro de `error`) y `detalles` (`orden`, `cambios`, `documentoEnmascarado`).
   - Los nombres de campo se leen con alternativas (`medicamentoId`/`id`, `ordenId`/`id`); si el contrato real difiere, el cambio está en `lib/types/ordenes.dart`.
   - `spec.md` describe otro contrato (`tipo: BLOQUEO` con HTTP 200). No se siguió.
2. **URL del servicio.** `ORDENES_BASE_URL` no tiene URL desplegada por defecto: en local usa el puerto 3004 (supuesto). Se agregó a `scripts/vercel-build.sh`.
3. **Enlace a Pendientes (AC-25).** La API de órdenes no trae `tienePendiente` y la lista de Pendientes solo trae `ordenMedicamentoId` por pendiente, no por medicamento. El handoff pide verificar el cruce antes de implementarlo, así que la fila ya tiene el enlace («Este medicamento tiene un pendiente. Ver en Pendientes») pero la pantalla no lo alimenta todavía.
4. **Destinos (D9).** «Revisar mis datos» lleva a Mi cuenta y «Seguir en Domicilios» lleva a Mis domicilios (`/orders`). El handoff proponía que este último solo cerrara el modal.
5. **Navegación.** La pantalla usa `FgScreen` con botón atrás, igual que Pendientes, y no `FgAppShell`, que hoy solo envuelve el inicio. En escritorio hay un destino «Órdenes y autorizaciones» en la barra lateral. En móvil la barra inferior ya tiene cuatro destinos (el máximo del manual), así que se llega con el botón «Ver mis órdenes» del inicio.
6. **Valores fuera de escala del handoff.** El arco usa `DeadlineRingSize.s` (72/8) y no 88/8 ni 72/7; el padding del panel usa 32 en escritorio y 24/20/20 en móvil (el handoff decía 36·32·28); la referencia del pedido usa `FgText.cifra` (28) y no 30.

## 3. Decisiones D1 a D11 del handoff

Todas siguen pendientes de registro en el manual antes de mezclar. Lo implementado:

| # | Estado |
|---|---|
| D1 | Arco de vigencia en la orden, calculado contra `consultadoEn` (`OrdenArco`, `ArcoOrden`) |
| D2 | Duración en días, horas o minutos dentro del arco |
| D3 | Panel `azul100` con filete de marca de 4 px, que se desplaza mientras carga |
| D4 | Sellos nuevos con `SelloEstado` + `AnilloMarca`: No requiere, Por autorizar, Sin información, Vencida |
| D5 | Tarjeta con selección: borde `azul600` y `e2` |
| D6 | Fondo `riesgo-bg` que se desvanece en 2,4 s en filas cambiadas por un 409, más la etiqueta fija |
| D7 | «Por reclamar» |
| D8 | Filtros locales sobre la respuesta |
| D10 | Verificación previa al abrir el diálogo |
| D11 | `FgMotion.escalon` (60 ms) y `FgMotion.pulso` (2000 ms); entrada escalonada, conteo, punto «en vivo», filete. Con movimiento reducido todo aparece directo |

## 4. Reglas del manual que convendría actualizar

Ordenadas de mayor a menor impacto. «Contradicción interna» significa que dos partes del propio manual se contradicen.

1. **§13.3 «No animar la entrada de secciones».** D11 la rompe a propósito. Conviene reformularla: se anima la llegada de un dato real de la EPS (una sola vez por respuesta), no el scroll ni el hover. Hay que registrar los tokens `escalon` y `pulso`.
2. **§3.4 y §22, barra de degradado.** Hoy es una excepción solo para el panel de estado de la home. La pantalla de órdenes cumple la misma función (foco del estado principal). Propuesta: generalizar a «el panel del estado principal de una pantalla, sin texto encima».
3. **§8.12 frente a §21, barra inferior.** §8.12 describe iconos de 24 px con indicador y §21 dice «solo texto, sin iconos» (y §20 manda). Además, el máximo de cuatro destinos ya no alcanza para el paciente: Inicio, Domicilios, Pendientes y Cuenta. Hace falta una regla para el quinto destino (por ejemplo, un destino «Más»).
4. **§5.1, escala de espaciado.** Prohíbe 28 px, pero §8.4 fija la casilla en 28×28 y `FgSize` usa 28 para símbolos. Contradicción interna: conviene dejar 28 como tamaño de control permitido.
5. **§8.6 frente a §14, chips.** El chip mide 40 px en escritorio y §14 exige objetivos de 48 px. La prueba de accesibilidad de Flutter falla con 40. Se usó 48 para el paciente; conviene que el manual lo diga.
6. **§7.1, diálogo `md` en móvil.** El manual manda pantalla completa para `md` y `lg`; el handoff usa hoja inferior de hasta el 90 %. Conviene decidir una de las dos.
7. **§8.8, sellos.** Define Vigente, Por vencer, Incumplido y Cumplido más la variante neutra. Faltan «No requiere», «Por autorizar» (que no es «Por vencer»), «Vencida» frente a «Incumplido» y «Sin información». Registrar la tabla de D4.
8. **§8.17 y §20, cifras de indicador.** Las tres cifras del panel son una composición libre con filete de 2 px, no `KpiCard`. Impeccable desaconseja la plantilla de cifra grande con etiqueta pequeña. Aquí cada cifra es una acción («Ver cuáles»), pero queda como decisión de diseño abierta.
9. **§8.9, tarjeta.** «Solo el hover sube a `e2`». D5 agrega un segundo caso: la tarjeta con selección activa.
10. **§11, vocabulario.** Agregar «Vigente / Vencida» para órdenes, «Por reclamar / Ya reclamado» para la reclamación, «Por autorizar / Autorizado» y la frase «Estados según tu EPS».
11. **§21 frente a la práctica.** El manual dice que la navegación vive siempre en el shell, pero las pantallas internas (Pendientes, Órdenes) usan `FgScreen` con botón atrás. Conviene documentar ambos patrones.
12. **Referencias a `PRODUCT.md`.** El manual (§22) y `contexto-negocio-farmago.md` lo citan «en la raíz del repo» y no existía. Se creó un borrador en `PRODUCT.md`, con lo inferido marcado.

## 5. Pendiente

- Verificar en navegador a 320, 375, 768, 1024 y 1440 px con el servicio real o un servicio simulado; aquí solo se verificó con pruebas de widget y capturas de 360, 768 y 1280.
- Confirmar los supuestos de la sección 2.
- Registrar D1 a D11 en el manual.
- Los goldens existentes de inicio, seguimiento y trayecto fallan al correr en Windows con este SDK; no los toca esta rama (el inicio solo suma un botón y un destino opcionales que las pruebas no pasan). Se regeneran en Linux.
