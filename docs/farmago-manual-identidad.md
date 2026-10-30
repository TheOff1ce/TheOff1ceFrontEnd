# FarmaGo — Manual de identidad y sistema de diseño

Este documento define la imagen de marca de FarmaGo y las reglas para mantenerla unificada en cualquier interfaz (escritorio y móvil): marca, color, tipografía, espaciado, forma, ventanas, componentes, voz y accesibilidad. Describe elementos y parámetros; no fija el diseño de pantallas concretas ni la tecnología con la que se implementen. El Anexo A reúne los tokens de diseño (valores exactos) en CSS.

> **En este repo (Flutter):** el Anexo A está traducido 1:1 en `lib/app/theme/farmago_tokens.dart` (`FgColors`, `FgSpace`, `FgRadius`, `FgBorder`, `FgShadow`, `FgSize`, `FgBreakpoint`, `FgMotion`, `FgText`, `FarmaGoTheme`). Ese archivo es la fuente numérica en código.

## Contenido

§0 Cómo usar este manual · §1 Esencia · §2 Logo · §3 Color · §4 Tipografía · §5 Espaciado, rejilla y estructura · §6 Forma · §7 Ventanas y avisos · §8 Componentes · §9 Patrones de composición · §10 Responsivo · §11 Voz · §12 Formatos de datos · §13 Iconos, imágenes y movimiento · §14 Accesibilidad · §15 Implementación · §16 Inventario · §17 Reglas de oro · §18 Lista de verificación · §19 Pendientes · Anexo A: tokens de diseño

## 0. Cómo usar este manual (reglas para el agente)

1. **Precedencia:** `farmago-tokens.css` (Anexo A, números) > este manual (reglas) > ejemplos. Si hay contradicción, gana el de mayor precedencia y la señalas.
2. **Cero valores sueltos:** ningún color, tamaño, radio, sombra, z-index ni duración literal en el código. Usa las variables de los tokens (por ejemplo `var(--azul-600)`) o su equivalente exacto en el sistema de estilos del proyecto. Excepción: `#FFFFFF` (texto sobre fondos de color) y los valores del anillo de foco.
3. **No inventes:** si el manual no especifica algo, compón con componentes existentes, elige el valor más cercano de la escala y déjalo registrado como pendiente de diseño (qué, dónde, qué elegiste). No crees componentes nuevos sin ese registro.
4. **No inventes reglas de negocio:** estados, umbrales, plazos, textos legales y flujos vienen del backend o de los documentos del proyecto. Lo no definido está en §19.
5. **Mobile-first:** se diseña primero a 360 px de ancho y luego se amplía. Móvil < 768 px · tablet 768–1199 px · desktop ≥ 1200 px.
6. **Antes de entregar una pantalla:** recorre la lista de §18.
7. **Mismo nombre, mismo comportamiento:** los componentes se llaman como en §16 y se reutilizan; no se duplican con variantes propias.

## 1. Esencia de la marca

- **Qué es FarmaGo:** plataforma que orquesta la logística y el cumplimiento de medicamentos pendientes (plazo máximo de 48 h) y el domicilio voluntario, conectando EPS, farmacias, repartidores y pacientes.
- **Qué NO es:** no toma decisiones clínicas, no define cobertura ni autorización, no consulta inventario. La interfaz NO DEBE sugerir lo contrario.
- **Personalidad:** confiable (muestra fechas y estados con claridad), clara (letra grande, una acción principal), en movimiento (la rueda y las estelas del logo).
- **Un solo gesto atrevido:** el **reloj de 48 h** (§8.13), un anillo con la forma de la rueda del logo. Todo lo demás es sobrio: no añadas adornos, gradientes ni ilustraciones decorativas fuera de lo que este manual permite.
- **Públicos y dispositivos:**

| Público | Dispositivo | Prioridad de diseño |
|---|---|---|
| Paciente (adultos mayores, crónicos, gestantes, movilidad reducida) | Móvil primero; web de escritorio secundaria | Legibilidad máxima, una acción por pantalla, lenguaje sencillo |
| Repartidor | Solo móvil, al aire libre, una mano | Botones grandes, contraste alto, una tarea por pantalla |
| Farmacia / punto de dispensación | Escritorio y tablet | Lista de trabajo clara, acciones rápidas |
| EPS / gestor farmacéutico | Escritorio | Lectura densa, semáforo de riesgo, reportes |

## 2. Logo

- Rueda con "F" y estelas curvas azul→verde; wordmark "FarmaGo" (Farma en azul, Go en verde); lema "De la farmacia a tu puerta".
- **Archivo actual:** PNG 470×373 con **fondo blanco opaco**. **Pendiente:** SVG, variante sin lema, variante horizontal (ícono + nombre), ícono de la rueda solo y versión para fondo oscuro.
- **Zona de respeto:** un espacio libre igual al alto de la "F" de la rueda en los cuatro lados. Nada (texto, bordes, imágenes) entra en esa zona.
- **Tamaños:** completo (con lema) mínimo **120 px** de ancho; por debajo de **160 px** debe usarse la variante sin lema (hasta que exista, no se muestra el logo por debajo de 160 px).
- **Fondos permitidos:** solo `--superficie` (#FFFFFF) y `--fondo` (#F3F8FA). Sobre cualquier otro fondo, foto o degradado: NO.
- **Prohibido:** recolorear, estirar, rotar, añadir sombra, brillo o contorno, recortar para improvisar un ícono, redibujar el logo, cambiar el lema.
- **Ubicación (provisional hasta tener las variantes):**

| Contexto | Tamaño del logo | Posición |
|---|---|---|
| Pantalla de bienvenida (splash), móvil | 240 px de ancho | Centrado en la pantalla |
| Inicio de sesión, móvil | 200 px de ancho | Centrado arriba, 32 px de separación con el formulario |
| Inicio de sesión, desktop | 240 px de ancho | Centrado sobre la tarjeta del formulario |
| Barra lateral desktop | 168 px de ancho | Cabecera de la barra, padding 24 px |
| Encabezado móvil | No se muestra el logo; se muestra el título de la pantalla | — |

- **Favicon / ícono de app:** pendiente (requiere el ícono de la rueda solo).

## 3. Color

Todos los colores salen del logo y se ajustaron por cálculo: el texto cumple **AAA (≥ 7:1)**; botones y texto grande, ≥ 4.5:1; bordes de controles, ≥ 3:1. Los valores exactos están en `farmago-tokens.css` (Anexo A).

### 3.1 Marca

| Token | Hex | Uso | Contraste |
|---|---|---|---|
| `--azul-100` | #E3F1F9 | Hover de botón secundario, fila seleccionada, nav activo, burbuja del usuario | texto `--ink` 12:1 |
| `--azul-200` | #BFDDF0 | Pressed de secundario/ghost | texto `--azul-800` 6.3:1 |
| `--azul-600` | #0474AC | **Primario**: fondo de botón, arcos del reloj, checkbox/radio/switch activos, borde de foco de campo | blanco sobre él 5.1:1 |
| `--azul-700` | #035C8C | Hover del botón primario | blanco 7.2:1 |
| `--azul-800` | #034E78 | **Texto azul y enlaces**, pressed del primario, anillo de foco | 8.9:1 sobre blanco |
| `--verde-700` | #2F6F2F | Acento de marca: botón secundario de marca, texto grande | 6.1:1 |
| `--cian-500`, `--verde-400` | #0488B4, #8CBC4C | **Solo decorativos** (degradado `--grad-marca`, estelas). Nunca texto ni datos | — |

### 3.2 Neutros y superficies

| Token | Hex | Uso |
|---|---|---|
| `--ink` | #12303F | Texto principal (13.8:1) |
| `--ink-soft` | #35505E | Texto secundario, iconos inactivos (8.5:1) |
| `--placeholder` | #5E7683 | Placeholder (4.8:1). Nunca contiene información esencial |
| `--fondo` | #F3F8FA | Fondo de pantalla |
| `--fondo-hundido` | #E9F1F4 | Encabezado de tabla, áreas internas de una tarjeta, track del segmented control |
| `--superficie` | #FFFFFF | Tarjetas, paneles, ventanas, inputs |
| `--linea` | #C9DCE3 | Divisores y bordes decorativos (1.4:1). Nunca el único borde de un control |
| `--linea-control` | #6B8795 | Borde de controles: input, checkbox, radio, switch apagado, chip (3.8:1) |
| `--deshabilitado-bg` / `-fg` | #E3ECF0 / #4B6573 | Controles deshabilitados |
| `--track` | #C3D6DE | Pista del reloj de 48 h |
| `--skeleton` | #DDE8ED | Esqueletos de carga |
| `--scrim` / `--scrim-suave` | rgb(18 48 63 / .56) / rgb(18 48 63 / .32) | Fondo detrás de diálogos y hojas / detrás del panel lateral |

### 3.3 Estados del plazo y avisos

| Estado | Fondo (solo avisos suaves) | Texto | Sólido (arco, círculo del sello destacado) | Forma en el reloj | Símbolo |
|---|---|---|---|---|---|
| Vigente | `--vigente-bg` #E3F1F9 | `--vigente-fg` #034E78 | `--vigente-solid` #0474AC | Arco azul parcial | Reloj |
| Por vencer (umbral pendiente) | `--riesgo-bg` #FFF1D6 | `--riesgo-fg` #6B3F00 | `--riesgo-solid` #B35C00 | Arco ámbar corto | "!" |
| Incumplido | `--incumplido-bg` #FDE7E5 | `--incumplido-fg` #8C1D18 | `--incumplido-solid` #B3261E | Anillo rojo discontinuo | "x" |
| Cumplido | `--cumplido-bg` #E4F3E6 | `--cumplido-fg` #18552A | `--cumplido-solid` #23703A | Anillo verde completo | Check |
| Neutro (informativo) | `--neutro-bg` #EEF2F4 | `--neutro-fg` #35505E | `--linea-control` | — | — |

- **Siempre forma + símbolo + palabra.** Nunca solo color. El estado se muestra con el **sello** (§8.8): anillo en miniatura + palabra, sin fondo de color.
- `VIGENTE / CUMPLIDO / INCUMPLIDO` los calcula el backend. "Por vencer" es un estado de interfaz cuyo **umbral no está definido (BR-007)**: se lee de configuración/API; no se inventa. Mientras no exista, no se muestra.
- **Verde de marca ≠ verde de éxito.** `--verde-700` y `--verde-400` no se usan para indicar estado; "Cumplido" usa `--cumplido-*`.
- Destructivo: `--peligro` #B3261E (hover `--peligro-hover`, pressed `--peligro-pressed`), solo para acciones irreversibles.

### 3.4 Proporciones y reglas

- ~85 % neutros, ~12 % azul, ~3 % verde/degradado.
- El degradado `--grad-marca` solo se usa en la pantalla de bienvenida y como franja decorativa ≤ 8 px de alto en cabeceras; nunca en botones, fondos de datos ni texto.
- Fondos de pantalla: `--fondo`. Tarjetas y ventanas: `--superficie`. No uses otros fondos.
- Sin modo oscuro (pendiente de definir).

## 4. Tipografía (prioridad: legibilidad para personas con discapacidad)

- **Una sola familia: Atkinson Hyperlegible Next** (títulos, cuerpo, botones, tablas), creada con el Braille Institute para baja visión; distingue I/l/1 y O/0. Fallbacks: `system-ui, -apple-system, "Segoe UI", Arial, sans-serif`. Pesos cargados: 400, 500, 600, 700.
- **Sin mitos:** no hay evidencia sólida de una letra "para dislexia". Pesan más el tamaño, el espacio y el lenguaje sencillo. No uses fuentes decorativas, cursivas largas ni pesos < 400.
- **Tamaños en `rem`, nunca px fijos.** Se respeta el tamaño del sistema y el selector A / A+ / A++ (100 / 125 / 150 %, atributo `data-texto` en `<html>`, persistente en ajustes).

| Estilo | Clase | Tamaño | Peso | Interlineado | Uso |
|---|---|---|---|---|---|
| Display | `.t-display` | 48 px (`--text-4xl`) | 700 | 1.1 | Cifras grandes: KPI, reloj L |
| Título de pantalla | `.t-h1` | 30 px móvil / 38 px tablet y desktop | 700 | 1.2 | Un solo `<h1>` por pantalla |
| Título de sección / ventana | `.t-h2` | 24 px | 700 | 1.2 | Secciones, título de diálogo y hoja |
| Título de tarjeta | `.t-h3` | 20 px | 700 | 1.3 | Nombre de medicamento, título de tarjeta |
| Cuerpo | `.t-body` | 18 px | 400 | 1.6 | Texto general |
| Cuerpo paciente | `.t-body-lg` | 20 px | 400 | 1.6 | Texto en la app del paciente |
| Etiqueta | `.t-label` | 18 px | 600 | 1.3 | Labels de formulario, nav |
| Texto de botón | — | 18 px (md), 20 px (lg), 16 px (sm) | 700 | 1.3 | Botones |
| Celda de tabla | `.t-cell` | 17 px | 400 | 1.4 | Tablas desktop |
| Meta / caption | `.t-caption` | 16 px (mínimo absoluto) | 400 | 1.5 | Fechas secundarias, ayudas |

- `letter-spacing: normal` siempre. Sin mayúsculas sostenidas, sin cursivas largas, sin subrayado fuera de enlaces.
- **Párrafos:** interlineado 1.6; separación entre párrafos 24 px; ≤ 3 líneas en pantallas del paciente; línea ≤ 66 caracteres (`--w-lectura`). Alineado a la izquierda: NO justificar. NO texto sobre imágenes.
- **Enlaces:** color `--azul-800`, subrayado siempre (2 px, offset 3 px; hover 3 px). No se distinguen solo por color.
- **Números:** fechas, horas, contadores, cifras y columnas numéricas con `.num` (`font-variant-numeric: tabular-nums`).
- El sistema debe reflujar a 200 % de zoom y a 320 px de ancho sin scroll horizontal.

## 5. Espaciado, rejilla y estructura de página

### 5.1 Escala de espaciado (base 4 px)

| Token | px | Uso típico |
|---|---|---|
| `--sp-1` | 4 | Entre icono y texto en badge muy compacto; espacio dentro de nav |
| `--sp-2` | 8 | Entre label e input; icono y texto en botón; separación mínima entre objetivos táctiles |
| `--sp-3` | 12 | Padding vertical de ítems de menú; gap checkbox-texto |
| `--sp-4` | 16 | Margen lateral móvil; gap entre tarjetas en móvil; padding de banner (16 20) |
| `--sp-4h` | 20 | Padding de tarjeta en móvil y de la hoja inferior (único valor intermedio permitido) |
| `--sp-5` | 24 | Padding de tarjeta desktop; gap entre campos de formulario; margen lateral tablet |
| `--sp-6` | 32 | Margen lateral desktop; padding de diálogo; gap entre secciones en móvil |
| `--sp-7` | 48 | Gap entre secciones en desktop |
| `--sp-8` | 64 | Separación entre bloques grandes (hero, vacíos) |
| `--sp-9` | 96 | Espacio superior de pantallas de bienvenida |

Solo se usan estos valores. Prohibido 5, 10, 15, 18, 28, 40 px, etc.

**Espaciados semánticos**

| Relación | Valor |
|---|---|
| Label → input | 8 |
| Input → texto de ayuda o error | 8 |
| Campo → campo (formulario) | 24 |
| Icono → texto | 8 |
| Tarjeta → tarjeta | 16 móvil / 24 desktop |
| Título de sección → contenido | 16 |
| Sección → sección | 32 móvil / 48 desktop |
| Objetivo táctil → objetivo táctil | ≥ 8 |
| Botón principal → botón secundario | 16 |

### 5.2 Rejilla y márgenes

| | Móvil < 768 | Tablet 768–1199 | Desktop ≥ 1200 |
|---|---|---|---|
| Columnas | 4 | 8 | 12 |
| Gutter | 16 | 24 | 24 |
| Margen lateral | 16 | 24 | 32 |
| Ancho máximo del contenido | 100 % | 100 % | 1280 px, centrado (contenido de lectura: 960 px) |

Clases listas: `.contenedor` (margen + ancho máx.) y `.rejilla` (columnas + gutter).

### 5.3 Alturas y anchos estructurales

| Elemento | Valor | Token |
|---|---|---|
| Encabezado móvil | 56 px | `--h-header-movil` |
| Barra de navegación inferior móvil | 72 px + safe-area inferior | `--h-nav-movil` |
| Barra de acción fija (móvil) | 88 px = 16 + botón 56 + 16 (+ safe-area) | `--h-barra-accion` |
| Barra superior desktop | 64 px | `--h-topbar` |
| Barra lateral expandida (≥ 1200) | 264 px | `--w-sidebar` |
| Barra lateral colapsada (tablet) | 72 px, solo iconos con tooltip | `--w-sidebar-colapsado` |
| Contenido máximo | 1280 px | `--w-contenido` |
| Fila de tabla | 56 px (compacta 48 px); encabezado 48 px | `--h-fila-tabla` |

- Usa `dvh` (no `vh`) en móvil para alturas de pantalla completa, y `env(safe-area-inset-*)` para notch y barra de gestos.
- El encabezado móvil y la barra inferior son `position: sticky/fixed` con `--z-sticky`/`--z-nav`; el contenido tiene padding inferior suficiente para no quedar tapado.

## 6. Forma: radios, bordes, sombras, capas

### 6.1 Radios

| Token | px | Se aplica a |
|---|---|---|
| `--r-xs` | 4 | Indicador de pestaña, barras decorativas |
| `--r-sm` | 8 | Inputs, textarea, checkbox, imágenes, tooltip, ítems de menú, esqueletos de texto |
| `--r-md` | 14 | **Botones, tarjetas, tablas, popover/menú, toast, banner, segmented control, campos de búsqueda de página** |
| `--r-lg` | 24 | Diálogo, hoja inferior (esquinas superiores), panel lateral (esquinas izquierdas), burbujas de chat |
| `--r-pill` | 999 | Sello destacado, chips, switch, indicador de nav, avatar, handle de la hoja |

**Regla del radio anidado:** el radio de un elemento interior = radio exterior − padding, redondeado al token más cercano (mínimo `--r-xs`). Ejemplo: contenedor `--r-md` (14) con padding 4 → el interior usa 10 → se redondea a `--r-sm` (8). Así las esquinas nunca se ven "dobles".
**Prohibido** cualquier radio fuera de esta tabla y esquinas rectas (0) en componentes visibles, salvo bordes que tocan el borde de pantalla (hoja inferior abajo, barras a todo el ancho).

### 6.2 Bordes

| Token | px | Uso |
|---|---|---|
| `--bw-1` | 1 | Divisores y bordes decorativos (`--linea`): tarjetas, tablas, barras |
| `--bw-2` | 2 | Bordes de controles (`--linea-control`): input, chip, checkbox, radio, switch apagado, botón secundario (`--azul-600`) |
| `--bw-foco` | 3 | Anillo de foco (outline) |
| `--bw-4` | 4 | Marcador de fila seleccionada, nodo actual del stepper, indicador de pestaña, conectores del stepper |

### 6.3 Sombras (elevación)

| Nivel | Token | Valor | Se aplica a |
|---|---|---|---|
| 0 | `--e0` | ninguna | Contenido de página, tablas (usan borde `--linea`), filas |
| 1 | `--e1` | `0 1px 2px rgb(18 48 63/.08), 0 2px 8px rgb(18 48 63/.06)` | Tarjetas en reposo |
| 2 | `--e2` | `0 4px 12px rgb(18 48 63/.12)` | Tarjeta interactiva en hover (solo desktop), encabezado con scroll, segmented seleccionado |
| 3 | `--e3` | `0 8px 24px rgb(18 48 63/.16)` | Popover, menú, toast, tooltip |
| 4 | `--e4` | `0 16px 48px rgb(18 48 63/.24)` | Diálogo, panel lateral |
| ↑ | `--e-arriba` | `0 -4px 16px rgb(18 48 63/.12)` | Barra de navegación inferior, hoja inferior, barra de acción fija |

- **Tarjeta aislada:** borde 1 px `--linea` + `--e1`. **Tarjeta plana:** solo borde 1 px `--linea`, sin sombra; se usa en listas de 2 o más tarjetas, KPIs y paneles densos para no saturar. No hay sombras de color, ni sombras internas, ni brillos.
- El nivel sube solo con la altura real del elemento sobre el contenido; no se usa sombra para decorar.

### 6.4 Capas (z-index)

| Capa | Token | Valor |
|---|---|---|
| Contenido | `--z-base` | 0 |
| Encabezados y barras pegajosas | `--z-sticky` | 100 |
| Barra lateral y barra inferior | `--z-nav` | 200 |
| Menús, popovers, selects | `--z-dropdown` | 300 |
| Panel lateral | `--z-panel` | 400 |
| Scrim (fondo oscuro) | `--z-scrim` | 500 |
| Diálogo y hoja inferior | `--z-modal` | 510 |
| Toasts | `--z-toast` | 600 |
| Tooltips | `--z-tooltip` | 700 |

Nunca valores fuera de esta tabla (`z-index: 9999` está prohibido).

## 7. Ventanas y capas superpuestas

### 7.1 Cuándo usar cada una

| Tipo | Úsala para | Desktop / tablet | Móvil (< 768) |
|---|---|---|---|
| **Diálogo** (modal) | Confirmar una acción, formulario corto (≤ 5 campos) | Centrado, 480/640/800 px | **Hoja inferior** (sm) o **pantalla completa** (md, lg) |
| **Diálogo de alerta** | Acción **irreversible** (cancelar solicitud, eliminar) | Centrado 480 px, sin botón X | Hoja inferior, sin handle arrastrable |
| **Hoja inferior** | Elegir una opción, confirmar, ver ayuda | No se usa (usa diálogo/menú) | Desde abajo, hasta 90 dvh |
| **Panel lateral** | Ver detalle sin salir de la lista (detalle de pendiente en la tabla), filtros avanzados | Derecha, 480/640 px | **Pantalla completa** |
| **Pantalla completa** | Flujos largos, formularios largos, detalle | No se usa (usa panel o página) | Navegación hacia adelante con botón atrás |
| **Popover / menú** | Acciones de una fila, menú de usuario, selector | Anclado al disparador | ≥ 3 ítems → hoja inferior de acciones |
| **Tooltip** | Nombre de un icono, ayuda breve | Hover y foco | No se usa |
| **Toast** | Confirmar algo que ya ocurrió | Abajo a la izquierda | Abajo, sobre la barra inferior |
| **Banner** | Aviso persistente que pide atención (superficie clara con el círculo de color del toast) | En el flujo del contenido | En el flujo del contenido |
| **Nota** | Aclaración silenciosa y permanente (sin fondo) | En el flujo del contenido | En el flujo del contenido |

**Reglas generales de ventanas**
1. Prefiere **en línea** (inline) antes que modal: un error de campo va bajo el campo, no en un diálogo.
2. **Una sola ventana modal a la vez.** Nunca un modal sobre otro: reemplaza el contenido o usa pasos dentro de la misma ventana.
3. Una ventana modal siempre tiene: título (`<h2>`), forma de cerrar visible, foco atrapado, `Esc` para cerrar, retorno del foco al disparador, bloqueo del scroll del fondo.
4. Solo la acción **irreversible** pide confirmación. No confirmes acciones reversibles.
5. Nada crítico (plazos, estados, errores bloqueantes) vive solo en un toast o tooltip.

### 7.2 Diálogo

| Propiedad | Valor |
|---|---|
| Ancho | sm **480** (confirmaciones) · md **640** (formularios ≤ 5 campos) · lg **800** (vistas previas, p. ej. reporte) |
| Alto máximo | `calc(100dvh - 96px)` (mínimo 48 px de margen arriba y abajo) |
| Fondo / radio / sombra | `--superficie` · `--r-lg` (24) · `--e4` |
| Estructura | **Encabezado** padding 24 32 · título `.t-h2` + botón icono cerrar 48×48 (arriba derecha) · **Cuerpo** padding 0 32 24, hace scroll interno · **Pie** padding 24 32, botones alineados a la derecha |
| Divisores | 1 px `--linea` entre encabezado/cuerpo y cuerpo/pie, solo cuando hay scroll |
| Pie | Secundario a la izquierda, primario a la derecha, gap 16. En móvil (si fuese hoja) apilados a ancho completo, primario arriba |
| Scrim | `--scrim`, ocupa toda la pantalla, capa `--z-scrim`; clic en el scrim cierra **solo** si es no destructivo y no hay cambios sin guardar |
| Entrada | 220 ms: opacidad 0→1 y escala .96→1, `--ease`. Salida: 120 ms, fundido, `--ease-salida` |
| Accesibilidad | `role="dialog"` + `aria-modal="true"` + `aria-labelledby` (título) + `aria-describedby` (descripción). Foco inicial: primer elemento enfocable (o el título si es solo lectura). Foco atrapado. `Esc` cierra |
| Alerta (irreversible) | `role="alertdialog"`, ancho 480, **sin botón X**, el botón **Cancelar tiene el foco inicial**, acción destructiva `--peligro` a la derecha con verbo específico ("Cancelar solicitud") |

### 7.3 Hoja inferior (solo móvil)

| Propiedad | Valor |
|---|---|
| Posición | Pegada abajo, ancho 100 % (en tablet vertical: ancho máx. 640 centrado) |
| Fondo / radio / sombra | `--superficie` · `--r-lg` solo esquinas superiores (24 24 0 0) · `--e-arriba` |
| Altura | Según contenido, mínimo 240 px, máximo **90 dvh**; el cuerpo hace scroll |
| Handle | Barra 40×4 px, `--r-pill`, `--linea-control`, centrada, a 12 px del borde superior. **Decorativa**: arrastrar no es la única forma de cerrar |
| Estructura | Encabezado: título `.t-h2` + botón cerrar 48×48 · Cuerpo padding 0 20 24 · Pie sticky padding 16 20 + safe-area, botón primario ancho completo |
| Cierre | Botón X visible, `Esc`/gesto atrás, clic en scrim (si es no destructiva) y arrastre hacia abajo (> 30 % de la altura) |
| Entrada | 320 ms, `translateY(100%)→0`, `--ease`. Salida: 220 ms, `--ease-salida` |
| Scrim | `--scrim` |
| Accesibilidad | Igual que el diálogo (`role="dialog"`, foco atrapado, retorno del foco) |

### 7.4 Panel lateral (desktop y tablet)

| Propiedad | Valor |
|---|---|
| Posición | Borde derecho, alto 100 dvh |
| Ancho | **480** (detalle) · **640** (ancho) · en tablet máx. 90 % del ancho |
| Fondo / radio / sombra | `--superficie` · `--r-lg` solo esquinas izquierdas (24 0 0 24) · `--e4` |
| Estructura | Encabezado sticky padding 24 32 (título `.t-h2` + cerrar 48×48) · Cuerpo con scroll padding 0 32 · Pie sticky padding 24 32 |
| Scrim | `--scrim-suave` (.32): se ve el contexto detrás; clic en el scrim cierra |
| Entrada | 320 ms, `translateX(100%)→0`. Salida 220 ms |
| Capas | Panel `--z-panel`, scrim `--z-scrim` |
| Móvil | Se convierte en **pantalla completa** con botón atrás |

### 7.5 Pantalla completa (móvil)

- Navegación hacia adelante (push): entra desde la derecha en 320 ms (movimiento reducido: fundido). El botón atrás (48×48, izquierda del encabezado) y el gesto atrás regresan.
- Encabezado de 56 px: botón atrás + título `.t-h3`-`.t-h2` de la pantalla (una línea, recortado con puntos suspensivos) + máx. 2 botones icono a la derecha.
- Acción principal: **barra de acción fija** abajo (88 px, `--e-arriba`, safe-area) con un botón `lg` de ancho completo. El contenido tiene padding inferior de 88 px.

### 7.6 Popover y menú

| Propiedad | Valor |
|---|---|
| Fondo / borde / radio / sombra | `--superficie` · 1 px `--linea` · `--r-md` (14) · `--e3` |
| Padding / separación del disparador | 8 px · 8 px |
| Ancho | mín. `--w-menu-min` 240 · máx. `--w-menu-max` 360 |
| Ítem | Alto 48 (desktop 44), padding 0 16, `--r-sm`, texto 18 px; icono 24 + gap 12; hover/foco: fondo `--fondo`; seleccionado: `--azul-100` |
| Separador | 1 px `--linea`, margen vertical 8 |
| Comportamiento | Abre debajo y alineado a la izquierda del disparador; se invierte si no cabe. Navegación con flechas, `Home/End`, `Esc` cierra y devuelve el foco. Capa `--z-dropdown` |
| Móvil | Menús con ≥ 3 ítems → hoja inferior de acciones |

### 7.7 Tooltip

- Fondo `--ink`, texto blanco 16 px, padding 8 12, `--r-sm`, `--e3`, ancho máx. 280 px, separación 8 px del disparador. Capa `--z-tooltip`.
- Aparece con hover (retardo 300 ms) **y con foco de teclado**; `Esc` lo oculta; no contiene elementos interactivos; el disparador referencia el tooltip con `aria-describedby`.
- No se usa en móvil. Nunca es la única fuente de información crítica.

### 7.8 Toast

| Propiedad | Valor |
|---|---|
| Posición | Móvil: abajo, márgenes laterales 16, **sobre la barra inferior** (bottom = 72 + 16 + safe-area; sin barra: 16). Desktop: abajo a la izquierda, 24 de margen, ancho 480 |
| Fondo / texto / radio / sombra | `--ink` · blanco 18 px · `--r-md` · `--e3`; padding 16 20 |
| Contenido | Icono en círculo de 28 px con símbolo blanco de 16 px (éxito `--cumplido-solid` + check; error `--peligro` + "x"; info `--azul-600` + "i") + mensaje + (opcional) una acción en texto `#8CC8EA` subrayado + cerrar 40×40 |
| Duración | Éxito/info: 6 s mínimo (pausa con hover/foco); **errores no se cierran solos** |
| Apilado | Máx. 3, gap 8; el más reciente abajo |
| Entrada / salida | 220 ms `translateY(16px)` + fundido / 120 ms fundido |
| Accesibilidad | `role="status"` (`aria-live="polite"`); errores `role="alert"`. Capa `--z-toast` |
| Texto | Nombra la acción y su resultado: "Entrega confirmada", "No pudimos guardar la entrega. Revisa la conexión y vuelve a intentarlo." |

### 7.9 Banner y nota (avisos en línea)

**Banner:** de la misma familia que el toast (mismo círculo de color con símbolo blanco) pero de superficie clara: va en el flujo de la pantalla, sin sombra, y puede traer título.

| Propiedad | Valor |
|---|---|
| Superficie | Fondo `--superficie`, borde 1 px `--linea`, `--r-md` (14), sin sombra (`--e0`), padding 16 20 |
| Icono | El mismo círculo de 28 px del toast con símbolo blanco de 16 px: info `--azul-600` ("i"), aviso `--riesgo-solid` ("!"), error `--peligro` ("x"), éxito `--cumplido-solid` (check) |
| Texto | Título opcional 18/700 `--ink`; mensaje 18/400 `--ink-soft` |
| Acción | Una sola, a la derecha (en móvil, debajo del texto): enlace 18/700 `--azul-800` subrayado |
| Cierre | Opcional: botón icono de 40×40. Los de error no se cierran solos |
| Ubicación | Arriba del contenido de la pantalla o del formulario al que se refiere. Máx. 1 banner visible por pantalla |
| Roles | `status` (info, éxito) o `alert` (aviso, error) |
| Banner de sistema | (sin conexión, mantenimiento) a ancho completo bajo el encabezado, sin radio ni borde lateral, alto mínimo 48 |

**Diferencia con el toast:** el toast es oscuro, flota con sombra, aparece y desaparece; el banner es claro, vive en la pantalla hasta que se resuelve.

**Nota:** versión silenciosa para aclaraciones permanentes (por ejemplo, "Esta información no reemplaza a tu médico ni a tu EPS."). Sin fondo ni borde: círculo de 24 px `--azul-600` con "i" blanca (símbolo de 14 px) + texto 16/400 `--ink-soft`, gap 12. Rol: ninguno (es contenido). Úsala cuando el aviso no pide acción ni atención inmediata; si pide atención, usa un banner.

## 8. Componentes

Cada componente especifica medidas, estados y accesibilidad. Los estados son: **reposo, hover (solo puntero), foco, pressed, deshabilitado, carga, error** cuando aplican. Transiciones de color/borde: `--dur-rapida`, `--ease`.

### 8.1 Botón (`Button`)

| Tamaño | Alto | Padding X | Texto | Icono | Uso |
|---|---|---|---|---|---|
| `lg` | 56 | 32 | 20 / 700 | 24 | Acción principal móvil; inicio de sesión; confirmar entrega |
| `md` | 48 | 24 | 18 / 700 | 24 | Estándar |
| `sm` | 40 | 16 | 16 / 700 | 20 | **Solo desktop denso** (acciones en fila de tabla). Nunca en móvil |

Radio `--r-md` (14). Ancho: móvil `lg` primario = 100 %; desktop = según contenido (mín. 120 px). Gap icono-texto 8 px. Un texto, una línea; máx. 28 caracteres (a 20 px caben unos 28 en 328 px de ancho). Si el nombre de la acción es más largo, el botón dice la acción corta ("Generar reporte") y el título de la pantalla dice el nombre completo.

| Variante | Reposo | Hover | Pressed | Foco |
|---|---|---|---|---|
| **Primario** | fondo `--azul-600`, texto blanco | `--azul-700` | `--azul-800` | outline 3 px `--azul-800`, offset 2 |
| **Secundario** | fondo transparente, borde 2 px `--azul-600`, texto `--azul-800` | fondo `--azul-100` | fondo `--azul-200` | igual |
| **Terciario (ghost)** | sin borde, texto `--azul-800` | fondo `--azul-100` | fondo `--azul-200` | igual |
| **Peligro** | fondo `--peligro`, texto blanco | `--peligro-hover` | `--peligro-pressed` | igual |

- **Deshabilitado:** fondo `--deshabilitado-bg`, texto `--deshabilitado-fg`, sin borde, `cursor: not-allowed`, `aria-disabled="true"`. **Prefiere no deshabilitar:** deja el botón activo y explica el error al enviar. Deshabilita solo durante carga.
- **Carga:** el texto cambia a gerundio ("Guardando…"), aparece a la izquierda el **spinner de rueda** (arco de 270° de 20 px, trazo 3 px, gira 800 ms lineal; con movimiento reducido: sin giro, solo "Guardando…"), el ancho no cambia, `aria-busy="true"` y no admite clics.
- **Reglas:** un solo botón primario por pantalla/ventana. El primario va a la derecha (desktop) o arriba (móvil). Peligro nunca junto a un primario sin separación (≥ 16 px) y nunca como primario por defecto.
- **Botón icono (`IconButton`):** 48×48 (40×40 solo desktop denso), `--r-md`, icono 24 px, hover `--azul-100`, **`aria-label` obligatorio**.

### 8.2 Enlace (`Link`)

`--azul-800`, subrayado 2 px (offset 3 px), hover 3 px. Visitado: igual. Dentro de texto de 18 px; objetivo táctil ampliado con padding vertical si está solo. Externo: abre en la misma pestaña salvo que descargue; si abre otra pestaña, lo dice ("(se abre en otra pestaña)").

### 8.3 Campo de texto (`TextField`) y textarea

```
Etiqueta (18/600)                 ← label SIEMPRE visible, arriba; "(opcional)" en 18/400 --ink-soft
[ Texto del campo...           ]  ← input 56 móvil / 48 desktop, borde 2px, radio 8
Texto de ayuda (16/400 --ink-soft)
```

| Propiedad | Valor |
|---|---|
| Alto input | 56 móvil / 48 desktop (`--h-input-*`); textarea mín. 120, redimensiona en vertical |
| Padding | 0 16 (textarea 12 16) |
| Texto | 18 px (20 en app del paciente), color `--ink` |
| Fondo / borde / radio | `--superficie` · 2 px `--linea-control` · `--r-sm` |
| Hover | borde `--ink-soft` |
| Foco | borde `--azul-600` + outline 3 px `--azul-800` offset 2 |
| Error | borde 2 px `--peligro`; debajo (gap 8) icono "!" 20 px + mensaje 16 px `--incumplido-fg` que dice qué corregir. `aria-invalid="true"` + `aria-describedby` |
| Deshabilitado | fondo `--deshabilitado-bg`, texto `--deshabilitado-fg`, sin borde |
| Solo lectura | fondo `--fondo-hundido`, borde 2 px `--linea`, texto `--ink` |
| Placeholder | `--placeholder`; nunca reemplaza la etiqueta |

- Los campos **obligatorios no llevan marca**; los **opcionales** dicen "(opcional)". Gap vertical entre campos: 24.
- Teclado móvil correcto (`inputmode`, `autocomplete`, `type`). No uses `maxlength` que corte sin avisar.
- Búsqueda: icono 24 a la izquierda (padding-izq. 52), botón "limpiar" 48×48 a la derecha cuando hay texto.
- Selector (`Select`): se usa el `<select>` nativo con chevron de 24 px a la derecha (mejor accesibilidad y teclado móvil); mismo estilo que el input.
- Validación: al salir del campo (blur) y al enviar; el resumen de errores va en un banner de error arriba del formulario con enlaces a los campos.

### 8.4 Casillas, radios e interruptor

| Control | Medidas | Estados |
|---|---|---|
| **Checkbox** | Caja 28×28, `--r-sm` (8), borde 2 `--linea-control` | Marcado: fondo y borde `--azul-600`, check blanco 20 px (trazo 3). Mixto: raya. Foco: outline. Error: borde `--peligro` |
| **Radio** | Círculo 28×28, borde 2 `--linea-control` | Marcado: borde `--azul-600`, punto interno 14 px `--azul-600` |
| **Switch** | Pista 56×32 `--r-pill`, pomo 24 | Apagado: fondo blanco, borde 2 `--linea-control`, pomo `--linea-control`. Encendido: fondo y borde `--azul-600`, pomo blanco con check. **Siempre lleva texto** "Activado"/"Desactivado" al lado |

El área tocable es la **fila completa** (mín. 48 de alto): caja + etiqueta de 18 px con gap 12. Grupos de radios/checkbox con `<fieldset>` y `<legend>`; gap vertical entre filas 8.

### 8.5 Control segmentado (`SegmentedControl`)

2–4 opciones, alto 48. Contenedor `--fondo-hundido`, `--r-md`, padding 4. Segmento con `--r-sm` (por la regla del radio anidado), mín. 96 de ancho, texto 16/600. Seleccionado: fondo `--superficie`, `--e2`, texto `--azul-800` y 700. No seleccionado: `--ink-soft`. `role="radiogroup"`.

### 8.6 Chips (`Chip`, filtros)

Alto 48 móvil / 40 desktop, padding 0 16, `--r-pill`, borde 2 `--linea-control`, texto 16/600 `--ink`, fondo `--superficie`. Seleccionado: fondo `--superficie` (sin relleno de color), borde 2 px `--azul-600`, texto `--azul-800` 700 y check de 20 a la izquierda (gap 8). Fila de chips: gap 8; en móvil se permite scroll horizontal (única excepción), con el borde del último chip visible a medias para indicar que hay más. `aria-pressed`.

### 8.7 Pestañas (`Tabs`)

Alto 48, texto 18/600. Activa: texto `--azul-800` + indicador de 4 px `--azul-600` abajo (`--r-xs` arriba). Inactiva: `--ink-soft`. Línea base 1 px `--linea`. Móvil: scroll horizontal si no caben. `role="tablist"`, flechas para moverse.

### 8.8 Sello de estado (`StatusBadge`)

El estado se muestra con un **anillo en miniatura** (la forma del reloj, §8.13) más la palabra.

| Variante | Medidas y color | Uso |
|---|---|---|
| **Sello** (por defecto) | Alto 32, **sin fondo ni borde**. Anillo de 24 px con trazo 3 y el símbolo del estado dentro; gap 8; palabra 16/700 en el color `*-fg` del estado | Tablas, listas, resúmenes |
| **Sello destacado** | Alto 40, `--r-pill`, fondo `--ink`, padding 0 16 0 8. Círculo de 24 px del color del estado con símbolo blanco de 14 px; palabra 16/700 blanca | **Uno por pantalla**: héroe del detalle y encabezado del panel lateral |

Anillo por estado (mismo trazo en ambas variantes): Vigente = arco parcial `--vigente-solid` con reloj; Por vencer = arco corto `--riesgo-solid` con "!"; Incumplido = anillo discontinuo `--incumplido-solid` con "x"; Cumplido = anillo completo `--cumplido-solid` con check. Pista `--track`. Textos: "Vigente", "Por vencer", "Incumplido", "Cumplido". Variante neutra (informativa): anillo `--linea-control` y palabra `--neutro-fg`. Siempre forma + símbolo + palabra.

### 8.9 Tarjeta (`Card`)

- Fondo `--superficie`, borde 1 px `--linea`, `--r-md`, `--e1`.
- Padding: **20 móvil / 24 desktop**. Gap interno 16.
- **Interactiva** (toda la tarjeta es un enlace/botón): alto mínimo 96; hover (solo desktop) `--e2` + borde `--azul-200`; pressed: `--e1` + fondo `--fondo`; foco: outline 3 px; chevron de 24 px al extremo derecho.
- **Nunca una tarjeta dentro de otra.** Las subáreas usan un bloque `--fondo-hundido`, `--r-sm`, padding 12–16.
- Gap entre tarjetas: 16 móvil / 24 desktop.
- **Variantes:** *aislada* (borde 1 px + `--e1`) para una tarjeta sola (héroe del detalle); *plana* (solo borde 1 px, sin sombra) para listas de 2 o más tarjetas, KPIs y paneles densos. Solo el hover de una tarjeta interactiva en desktop sube a `--e2`.

### 8.10 Tarjeta de pendiente (`PendienteCard`, móvil)

```
┌────────────────────────────────────────────┐  ← tarjeta plana: borde 1px --linea, radio 14, padding 20
│ Orden OM-1042                          ›  │  ← caption 16/400 --ink-soft; chevron 24
│ Metformina 850 mg  (+2 más)               │  ← .t-h3 20/700, máx. 2 líneas
│                                            │
│  (◔)   31 h 20 min                         │  ← reloj S 72 + tiempo 28/700 .num
│   72   Vigente                             │  ← estado: palabra 16/700 en color *-fg (sin fondo)
│        vence 26 oct 2026, 9:15 a. m.      │  ← 16/400 --ink-soft .num
└────────────────────────────────────────────┘
```

- Cuando el estado es Incumplido o Cumplido, la primera línea (28/700, color `*-fg`) es la palabra del estado ("Incumplido", "Cumplido"), la segunda es "Venció hace 3 h 10 min" o "Entregado a tiempo" y la tercera la fecha. El anillo ya muestra la forma y el símbolo.
- Toda la tarjeta es un solo objetivo táctil (no hay botón dentro).
- Si hay varios medicamentos: primero el nombre del primero y "(+N más)"; el detalle completo está en la pantalla de detalle.
- Orden por defecto: **fecha límite ascendente** (lo más urgente primero).

### 8.11 Tabla (`DataTable`, desktop)

| Parte | Valor |
|---|---|
| Contenedor | `--superficie`, borde 1 `--linea`, `--r-md`, `overflow: hidden`, sin sombra (`--e0`) |
| Encabezado | Alto 48, fondo `--fondo-hundido`, texto 16/700 `--ink`, sticky arriba; ordenable: botón con flecha 20 y `aria-sort` |
| Fila | Alto 56 (compacta 48, conmutable), padding celda 0 16, texto `.t-cell` 17 px, divisor 1 `--linea` |
| Hover de fila | fondo `--fondo` |
| Fila seleccionada | fondo `--azul-100` + marcador izquierdo 4 px `--azul-600` |
| Foco de fila | outline 3 px `--azul-800` (inset) |
| Columnas | Texto a la izquierda; números a la derecha con `.num`; estado = sello (`StatusBadge`, §8.8); acciones a la derecha con botones icono 40 |
| Orden inicial | Por fecha límite ascendente |
| Paginación | Pie 64 px: "Mostrando 1–25 de 128" a la izquierda, selector de filas por página (25/50/100) y botones anterior/siguiente (`md`) a la derecha |
| Filtros | Fila de chips + campo de búsqueda (ancho 320) sobre la tabla, gap 16 |
| Vacío / carga | Fila de `EmptyState` / esqueleto de 5 filas |
| Móvil | **No se usa tabla**: se convierte en lista de tarjetas (sin scroll horizontal) |

### 8.12 Navegación

**Barra inferior móvil (`BottomNav`)**
- Alto 72 + safe-area, fondo `--superficie`, borde superior 1 `--linea`, `--e-arriba`, capa `--z-nav`. Máx. **4 destinos**, ancho igual.
- Ítem: icono 24 dentro de un indicador 64×32 `--r-pill`; etiqueta 16/600 debajo (gap 4). Activo: indicador `--azul-100`, etiqueta `--azul-800` 700. Inactivo: `--ink-soft`. Área tocable 72×72. `aria-current="page"`.
- En flujos de una sola tarea no se usa barra inferior: se usa encabezado + barra de acción fija.

**Encabezado móvil (`AppHeader`)**: 56 px, `--superficie`, borde inferior 1 `--linea` (al hacer scroll: `--e2`), botón atrás 48×48 a la izquierda (si no es raíz), título 20/700 a una línea, ≤ 2 botones icono a la derecha. `--z-sticky`.

**Barra lateral desktop (`SideNav`)**: ancho 264 (colapsada 72 en tablet), fondo `--superficie`, borde derecho 1 `--linea`, padding 16. Cabecera con logo (§2). Ítems de 48 de alto, `--r-md`, padding 0 16, icono 24 + etiqueta 18/600, gap 12. Activo: fondo `--azul-100`, texto `--azul-800`. Hover: `--fondo`. Colapsada: solo iconos con tooltip.

**Barra superior desktop (`TopBar`)**: 64 px, `--superficie`, borde inferior 1 `--linea`; a la derecha el menú de usuario (avatar 40 + nombre + chevron → popover). Búsqueda global opcional a la izquierda.

**Migas de pan (`Breadcrumb`)**: solo desktop en páginas de detalle; texto 16 px, separador chevron 20.

**Avatar:** círculo 40 px, fondo `--azul-100`, iniciales 16/700 `--azul-800`.

### 8.13 Reloj de 48 h (`DeadlineRing`) — la firma visual

Anillo que se vacía hasta la fecha límite. Tiene la forma de la rueda del logo.

| Tamaño | Lado | Trazo | Contenido central | Dónde |
|---|---|---|---|---|
| `xs` | 40 | 5 | Símbolo de estado (16 px) | Filas de tabla |
| `s` | 72 | 8 | Símbolo de estado (28 px) | `PendienteCard` |
| `m` | 120 | 12 | Horas restantes ("31 h") 28/700 | Detalle móvil |
| `l` | 200 | 18 | Horas ("31 h") 48/700 y minutos ("20 min") 24/600 en dos líneas; la leyenda "para la fecha límite" (18 px) va **fuera** del anillo, debajo | Detalle desktop, héroe |

- **Geometría:** círculo de radio = (lado − trazo)/2, extremos redondos. Pista `--track` (círculo completo). El **arco** parte a las 12 en punto y avanza en sentido horario; su longitud = `tiempo restante / plazo total` (plazo total = `fechaLimite − fechaEvento` que entrega el backend; 48 h por defecto, configurable). El arco **se acorta** con el tiempo (el extremo se acerca al inicio).
- **Color y forma por estado** (§3.3): Vigente = arco `--vigente-solid`; Por vencer = arco `--riesgo-solid` corto; Incumplido = anillo **discontinuo** `--incumplido-solid` (trazos de ≈ 8 % de la circunferencia con huecos de ≈ 4 %), sin progreso; Cumplido = anillo **completo** `--cumplido-solid` con check.
- **Texto de tiempo** (junto al anillo, en una línea; dentro de `m` y `l` solo caben las horas y minutos como arriba): `N h M min` (≥ 1 h), `N min` (< 1 h), vencido: "Venció hace N h M min", cumplido: "Entregado 25 oct 2026, 4:40 p. m.". Se actualiza **cada minuto**; no se anuncia cada actualización con `aria-live`, solo los cambios de estado.
- **Accesibilidad:** `role="img"` con `aria-label` completo: "Quedan 31 horas y 20 minutos para la fecha límite, 26 de octubre de 2026, 9:15 a. m. Estado: vigente."
- **La fecha viene del backend.** Una notificación tardía no reinicia el reloj. Nunca calcules la fecha límite en el frontend.
- **Animación:** al cargar, el arco se dibuja en 600 ms (`--ease`); con movimiento reducido aparece directo.

### 8.14 Seguimiento de entrega (`TrackingStepper`)

Secuencia: **Recibido → Asignado → En camino → Entregado**. Único lugar donde se permiten pasos numerados/secuenciales.
- **Vertical** (móvil y detalles): nodo 32×32, conector vertical 4 px, 48 px entre nodos; etiqueta 18/700 a la derecha (gap 16) y hora debajo 16/400 `--ink-soft`.
- **Horizontal** (desktop): nodos unidos por línea de 4 px; etiqueta debajo, centrada.
- **Completado:** nodo `--azul-600` con check blanco 20, conector `--azul-600`. **Actual:** nodo blanco con borde 4 `--azul-600` y punto interno de 12; etiqueta `--azul-800` 700. **Futuro:** nodo blanco con borde 2 `--linea-control`, etiqueta `--ink-soft`, conector `--linea`.
- `<ol>`; el paso actual lleva `aria-current="step"`; cada paso dice su estado en texto ("Completado", "En curso", "Pendiente").

### 8.15 Estados vacíos, carga y error

- **Vacío (`EmptyState`):** centrado, padding 64 vertical; ilustración simple de 160 px (la rueda con una estela, en `--linea-control` y `--azul-200`; **pendiente** de diseñar); título `.t-h2`; texto 18 `--ink-soft` (máx. 2 líneas) que dice qué falta y qué hacer; botón opcional `md`. Ej.: "No tienes pendientes. Cuando una entrega quede incompleta, la verás aquí."
- **Carga (`Skeleton`):** bloques `--skeleton` con el mismo radio y tamaño que el contenido final; brillo que recorre en 1400 ms (movimiento reducido: sin brillo). No uses spinners de pantalla completa. Si tarda > 10 s, muestra un mensaje.
- **Error de pantalla:** banner de error + botón "Reintentar"; conserva el contenido anterior si existe. Mensaje: qué pasó + qué hacer, sin culpar ni disculparse.
- **Sin conexión:** banner de sistema (§7.9).

### 8.16 Burbujas de chat (`ChatBubble`)

- Burbuja del usuario: fondo `--azul-100`, texto `--ink` 18 px, radios 24 24 8 24, alineada a la derecha, ancho máx. 85 %.
- Burbuja del asistente: fondo `--superficie`, borde 1 px `--linea`, texto `--ink` 18 px, radios 24 24 24 8, alineada a la izquierda, ancho máx. 85 %.
- Padding 12 16; separación vertical entre burbujas 12. Campo de mensaje fijo abajo de 72 px con botón de enviar de 48×48.

### 8.17 Tarjeta de indicador (`KpiCard`)

Tarjeta plana (§8.9). Cifra `.t-display` (el color de la cifra sigue el estado solo si la métrica ES un estado: por vencer `--riesgo-fg`, incumplidos `--incumplido-fg`; las demás `--ink`) y etiqueta 18 px `--ink-soft` debajo. No se inventan variaciones ni porcentajes que no entregue el sistema.

### 8.18 Lienzo de firma (`SignaturePad`)

Ancho completo, alto 200, fondo `--superficie`, borde 2 px punteado `--linea-control`, `--r-md`. Botón terciario "Borrar firma" debajo.

## 9. Patrones de composición

Reglas para componer cualquier pantalla con los componentes de §8. No describen pantallas concretas: cada equipo decide qué pantallas necesita su servicio.

| Patrón | Estructura | Parámetros |
|---|---|---|
| **Lista** | Título de pantalla (`.t-h1`) + filtros (`Chip`) + lista de tarjetas planas | Móvil: tarjetas a ancho completo, gap 16, ordenadas por urgencia (fecha límite ascendente). Desktop: `DataTable` en lugar de tarjetas |
| **Detalle** | Encabezado con botón atrás (móvil) o migas (desktop) + bloque principal (reloj o dato clave + sello destacado) + secciones con `.t-h2` | Un solo sello destacado por pantalla; secciones separadas 32 móvil / 48 desktop |
| **Formulario** | Campos de una columna (`TextField`, `Select`, controles) + acción principal | Gap entre campos 24; errores bajo el campo; resumen de errores en `Banner`; un solo botón primario |
| **Panel de datos (desktop)** | `SideNav` + `TopBar` + título + indicadores (`KpiCard`) + filtros + `DataTable` | Márgenes 32; indicadores en la rejilla de 12 columnas; detalle en `SidePanel` |
| **Flujo de una sola tarea (móvil)** | Encabezado de 56 + contenido + barra de acción fija de 88 con un botón `lg` | Sin barra inferior; el contenido deja 88 libres abajo |

Todas las pantallas definen su estado de **carga** (esqueleto), **vacío** y **error** (banner + reintentar), y siguen la lista de §18.

## 10. Comportamiento responsivo (desktop → móvil)

| Elemento | Desktop | Móvil |
|---|---|---|
| Barra lateral | 264 px (72 en tablet) | Barra inferior de hasta 4 destinos, o ninguna (flujos de una sola tarea) |
| Tabla | `DataTable` | Lista de `PendienteCard` / tarjetas de fila |
| Panel lateral | Derecha 480/640 | Pantalla completa |
| Diálogo | Centrado | Hoja inferior / pantalla completa |
| Menú | Popover | Hoja inferior de acciones (≥ 3 ítems) |
| Tooltip | Hover/foco | No se usa |
| Botón primario | Ancho por contenido, a la derecha | `lg` ancho completo, barra de acción fija |
| Formularios | Una columna ≤ 640 px (dos columnas solo para pares cortos como fecha/hora) | Una columna siempre |
| Título de pantalla | 38 px | 30 px |
| Padding de tarjeta | 24 | 20 |
| Gap entre tarjetas | 24 | 16 |
| Margen lateral | 32 (tablet 24) | 16 |

Probar siempre en **360 px**, **768 px** y **1280 px**, y con el texto al 150 %.

## 11. Voz y contenido (español de Colombia)

- **Tú** para pacientes (coherente con "a tu puerta"); tono neutro-profesional en las herramientas de gestión (EPS, farmacia). Evita "usted" y "vos".
- Verbos activos y oraciones cortas. Mayúscula solo inicial (sentence case) en títulos, botones y etiquetas.
- **Vocabulario fijo (dominio):** Pendiente, Fecha límite, Novedad, Cumplido, Incumplido, Orden de medicamento. No mezclar sinónimos ("faltante", "atraso", "retraso").
- Un botón conserva su nombre en todo el flujo: "Confirmar entrega" → toast "Entrega confirmada".
- **Errores:** qué pasó + qué hacer; sin disculpas ni culpa; sin códigos técnicos.
- **Vacíos:** dicen qué falta y qué hacer.
- **Asistente IA:** se rotula "Asistente informativo"; NO da consejo clínico ni promete cobertura; ante ambigüedad ofrece contactar a la EPS o al médico.
- **Privacidad:** no muestres documento completo ni dirección completa en listas; documento enmascarado ("CC •••• 4321"); dirección resumida (barrio/localidad) hasta el detalle.

| Contexto | Sí | No |
|---|---|---|
| Botón | Confirmar entrega | Enviar |
| Botón | Generar reporte | Reportar |
| Error de red | No pudimos guardar la entrega. Revisa la conexión y vuelve a intentarlo. | ¡Ups! Algo salió mal. |
| Vacío | No tienes pendientes. Cuando una entrega quede incompleta, la verás aquí. | Sin datos |
| Estado | Pasó la fecha límite. Puedes generar un reporte de incumplimiento. | Pendiente vencido |
| Asistente | Asistente informativo. Para decidir sobre tu tratamiento, consulta a tu médico. | Te recomendamos cambiar tu dosis. |

## 12. Formatos de datos

| Dato | Formato | Ejemplo |
|---|---|---|
| Fecha | `d MMM aaaa` (mes abreviado, minúscula, sin punto) | 24 oct 2026 |
| Fecha y hora | `d MMM aaaa, h:mm a. m./p. m.` (12 h) | 24 oct 2026, 3:30 p. m. |
| Zona horaria | Siempre `America/Bogota` (UTC−5, sin cambio de hora) | — |
| Relativo | Solo en Novedades y menos de 24 h; siempre con la fecha completa disponible | hace 3 h |
| Duración | `N h M min` | 31 h 20 min |
| Número | Punto para miles, coma decimal | 1.234,5 |
| Moneda | COP, sin decimales, símbolo con espacio | $ 12.500 |
| Porcentaje | Número + espacio + % | 85 % |
| Teléfono | `+57 3XX XXX XXXX` | +57 300 123 4567 |
| Documento | Enmascarado, últimos 4 | CC •••• 4321 |
| Identificador de orden | Tal como lo entrega el backend, con `.num` | OM-1042 |

## 13. Iconografía, imágenes y movimiento

### 13.1 Iconos
- Un solo conjunto de iconos coherente, de la librería que elija el equipo. Trazo 2 px, extremos redondeados, `currentColor`. Tamaños: 20 (`--icono-sm`, en badges, tablas, mensajes), 24 (`--icono-md`, estándar), 32 (`--icono-lg`, vacíos).
- Los iconos que comunican algo llevan texto al lado; los que van solos (botón icono) llevan `aria-label` y tooltip en desktop. Iconos decorativos: `aria-hidden="true"`.
- Símbolos de estado del reloj y los sellos: reloj, "!", "x", check (§3.3).

### 13.2 Imágenes
- Solo con contenido útil (fotos de prueba de entrega, mapas). Radio `--r-sm`; proporción 4:3; `alt` descriptivo. Sin fotos de stock decorativas.
- **Estelas del logo** (curvas azul/cian/verde, opacidad ≤ .55): solo decoración en bienvenida, inicio de sesión y estados vacíos; nunca detrás de datos o texto.

### 13.3 Movimiento

| Uso | Duración | Curva | Propiedad |
|---|---|---|---|
| Color, borde, foco | 120 ms (`--dur-rapida`) | `--ease` | color, background, border-color |
| Diálogo, popover, toast (entrada) | 220 ms (`--dur-media`) | `--ease` | opacidad, escala .96→1, translateY 16 |
| Hoja inferior, panel lateral, navegación entre pantallas | 320 ms (`--dur-lenta`) | `--ease` | transform |
| Salida de ventanas | 120–220 ms | `--ease-salida` | opacidad, transform |
| Reloj al cargar | 600 ms | `--ease` | longitud del arco |
| Spinner | 800 ms lineal, infinito | linear | rotación |
| Esqueleto | 1400 ms | linear | brillo |

- Solo animar respuestas a acciones y el reloj. No animar la entrada de secciones, ni efectos de hover decorativos, ni rebotes.
- `prefers-reduced-motion`: todo con duración ≈ 0 (fundidos instantáneos), sin giros ni brillos.

## 14. Accesibilidad (mínimos exigibles)

- **WCAG 2.2:** texto AAA (7:1) con `--ink`, `--ink-soft`, `--azul-800` y pares `*-fg/*-bg`; botones y texto grande ≥ 4.5:1; bordes de controles ≥ 3:1.
- **Información nunca solo por color:** forma + símbolo + palabra.
- **Foco visible siempre:** `outline: 3px solid var(--azul-800); outline-offset: 2px` (blanco sobre fondos oscuros). Orden de foco lógico; sin trampas de teclado excepto ventanas modales (que atrapan y devuelven el foco).
- **Teclado completo** en escritorio: `Tab`, `Shift+Tab`, `Enter`, `Espacio`, flechas en menús/pestañas/radios, `Esc` cierra capas.
- **Lectores de pantalla:** `lang="es-CO"`; un solo `<h1>` por pantalla y jerarquía de títulos sin saltos; regiones (`header`, `nav`, `main`); `aria-live="polite"` para cambios de estado y toasts; `role="alert"` para errores; `aria-label` en botones icono; tablas con `<th scope>`.
- **Objetivos táctiles ≥ 48×48 px** (56 en acciones críticas del móvil), separación ≥ 8 px. Todo con un toque; sin gestos obligatorios (arrastrar, pellizcar); sin límites de tiempo (o permitir extenderlos).
- **Texto:** 18 px base (20 px paciente), reflujo a 200 % de zoom y 320 px, selector A / A+ / A++.
- **Movimiento:** sin parpadeos; `prefers-reduced-motion` respetado.
- **Lenguaje sencillo:** frases cortas, sin jerga normativa ante el paciente; errores asociados al campo con `aria-describedby`.
- **Validación:** antes de dar la accesibilidad por aprobada, probar con personas reales (baja visión, dislexia, lector de pantalla, uso con una mano).

## 15. Implementación (independiente de la tecnología)

El stack lo define cada equipo para su servicio. Este manual solo fija lo que se ve y cómo se comporta:

- **Tokens:** los valores del Anexo A son variables CSS; si el proyecto usa otro sistema de estilos, se traducen uno a uno con los mismos nombres y valores. Los valores no se redefinen.
- **Breakpoints:** móvil < 768 px, tablet 768–1199 px, desktop ≥ 1200 px. Mobile-first.
- **Componentes:** se llaman como en §16 y se reutilizan; las pantallas solo **componen** estos componentes, no estilizan desde cero.
- **Accesibilidad de ventanas:** foco atrapado, retorno del foco y roles ARIA son obligatorios (§7 y §14), sea cual sea la forma de implementarlos.
- **Fechas y zona horaria:** siempre `America/Bogota`, con el formato de §12; nunca cálculos manuales con la zona del dispositivo.
- **Sin reglas de negocio en el frontend:** estados y fechas límite vienen del backend; el frontend solo los presenta.
- **Dependencias nuevas:** no se agregan sin aprobación del equipo.

## 16. Inventario de componentes

| Componente | Sección |
|---|---|
| `Button`, `IconButton`, `Link` | 8.1, 8.2 |
| `TextField`, `Textarea`, `Select`, `SearchField` | 8.3 |
| `Checkbox`, `RadioGroup`, `Switch` | 8.4 |
| `SegmentedControl`, `Chip`, `Tabs` | 8.5–8.7 |
| `StatusBadge`, `Card`, `PendienteCard` | 8.8–8.10 |
| `DataTable` | 8.11 |
| `AppShell`, `AppHeader`, `BottomNav`, `SideNav`, `TopBar`, `Breadcrumb`, `Avatar` | 8.12 |
| `DeadlineRing`, `TrackingStepper` | 8.13, 8.14 |
| `EmptyState`, `Skeleton`, `Spinner` (rueda) | 8.15, 8.1 |
| `Dialog`, `AlertDialog`, `BottomSheet`, `SidePanel`, `Popover/Menu`, `Tooltip`, `Toast`, `Banner`, `Nota` | 7 |
| `ChatBubble`, `KpiCard`, `SignaturePad` | 8.16–8.18 |

## 17. Reglas de oro (resumen en diez líneas)

1. Solo tokens: ningún valor suelto. 2. Un `<h1>` y un botón primario por pantalla. 3. Estado = forma + símbolo + palabra. 4. Texto ≥ 18 px (≥ 16 px en metadatos), AAA. 5. Objetivos ≥ 48 px. 6. Radios: 8 controles, 14 botones/tarjetas, 24 ventanas. 7. Tarjeta aislada = borde 1 px + `--e1`; en listas y KPIs, plana (solo borde); ventanas `--e4`. 8. Una ventana modal a la vez; móvil = hoja inferior o pantalla completa. 9. Nunca inventes estados, umbrales ni textos legales. 10. Si falta algo, el valor más cercano de la escala y déjalo registrado como pendiente de diseño.

## 18. Lista de verificación por pantalla (criterios de aceptación)

1. ¿Solo valores de los tokens, sin hex ni px sueltos (salvo los de §0.2)?
2. ¿Un `<h1>`, un botón primario, jerarquía de títulos sin saltos?
3. ¿Cada estado muestra forma, símbolo y palabra?
4. ¿Radios, sombras y z-index de las tablas §6?
5. ¿Probada a 360, 768 y 1280 px, y con texto al 150 %?
6. ¿Objetivos ≥ 48 px, separación ≥ 8 px y foco visible?
7. ¿Teclado completo y `Esc` en capas? ¿Foco devuelto al cerrar?
8. ¿Estados de carga, vacío y error definidos?
9. ¿Vocabulario de §11 y formatos de §12? ¿Sin reglas de negocio inventadas?
10. ¿Movimiento según §13.3 y respeta `prefers-reduced-motion`?

## 19. Pendientes de definir (diseño)

- **Logo:** SVG, variante sin lema, variante horizontal (ícono + nombre), ícono de la rueda solo y versión para fondo oscuro; favicon e ícono de app.
- **Umbral de "por vencer"** y **tipos de `Novedad`** (para iconos y colores).
- **Ilustración** de los estados vacíos.
- **Gráficos:** si se añaden, usar solo los colores de estado y el mismo texto AAA.
- **Modo oscuro.**
- **Fuente tipográfica:** cómo se carga (lo define cada equipo) y qué librería de iconos se usa.

---

## Anexo A — `farmago-tokens.css`

Guárdalo como archivo de tokens del proyecto (por ejemplo `farmago-tokens.css`) y cárgalo una vez en la raíz. Si el proyecto no usa CSS plano, se traduce con los mismos nombres y valores. (En este repo: `lib/app/theme/farmago_tokens.dart`.)

```css
/* ==========================================================================
   FarmaGo — design tokens
   Fuente de verdad numérica. El manual explica el uso.
   Reglas: (1) ningún componente declara colores, tamaños, radios, sombras ni z-index
   literales: solo estas variables. (2) Si falta un valor, NO lo inventes: usa el más
   cercano de la escala y déjalo registrado como pendiente de diseño.
   Breakpoints (no se pueden usar var() en @media): móvil < 768px · tablet 768–1199px · desktop >= 1200px.
   ========================================================================== */

/* La fuente "Atkinson Hyperlegible Next" (pesos 400, 500, 600 y 700) debe estar disponible en el proyecto; cómo se carga lo decide cada equipo. */

:root {
  /* ---------- Color: marca (muestreada del logo, ajustada para contraste) ---------- */
  --azul-100: #E3F1F9;   /* fondo suave: hover secundario, fila seleccionada, nav activo, burbuja del usuario */
  --azul-200: #BFDDF0;   /* pressed de secundario/ghost, borde de selección suave */
  --azul-600: #0474AC;   /* PRIMARIO: fondo de botón (texto blanco 5.1:1), arcos, checkbox, switch, foco de borde */
  --azul-700: #035C8C;   /* hover del primario (blanco 7.2:1) */
  --azul-800: #034E78;   /* TEXTO azul y enlaces (8.9:1 s/ blanco), pressed del primario, anillo de foco */
  --verde-700: #2F6F2F;  /* acento de marca: botón secundario de marca o texto grande (6.1:1). No es verde de éxito */
  --cian-500: #0488B4;   /* solo decorativo */
  --verde-400: #8CBC4C;  /* solo decorativo */
  --grad-marca: linear-gradient(100deg, var(--azul-600) 0%, var(--cian-500) 45%, var(--verde-400) 100%);

  /* ---------- Color: neutros y superficies ---------- */
  --ink: #12303F;            /* texto principal (13.8:1 s/ blanco) */
  --ink-soft: #35505E;       /* texto secundario (8.5:1 s/ blanco; 8.0:1 s/ fondo) */
  --placeholder: #5E7683;    /* placeholder (4.8:1). Nunca lleva información esencial */
  --fondo: #F3F8FA;          /* fondo de pantalla */
  --fondo-hundido: #E9F1F4;  /* encabezado de tabla, áreas internas, segmented control */
  --superficie: #FFFFFF;     /* tarjetas, paneles, ventanas, inputs */
  --linea: #C9DCE3;          /* divisores y bordes DECORATIVOS (1.4:1; nunca el único borde de un control) */
  --linea-control: #6B8795;  /* borde de controles (3.8:1 s/ blanco): inputs, checkbox, radio, switch, chips */
  --deshabilitado-bg: #E3ECF0;
  --deshabilitado-fg: #4B6573; /* 5.1:1 s/ deshabilitado-bg */
  --track: #C3D6DE;          /* pista del reloj de 48 h (decorativa) */
  --skeleton: #DDE8ED;       /* esqueletos de carga */
  --scrim: rgb(18 48 63 / .56);       /* detrás de diálogos y hojas */
  --scrim-suave: rgb(18 48 63 / .32); /* detrás del panel lateral */

  /* ---------- Color: estados del plazo y avisos (texto AAA >= 7:1). Siempre forma + símbolo + palabra ---------- */
  --vigente-fg: #034E78;   --vigente-bg: #E3F1F9;   --vigente-solid: #0474AC;
  --riesgo-fg: #6B3F00;    --riesgo-bg: #FFF1D6;    --riesgo-solid: #B35C00;   /* umbral de "por vencer": PENDIENTE (BR-007) */
  --incumplido-fg: #8C1D18; --incumplido-bg: #FDE7E5; --incumplido-solid: #B3261E;
  --cumplido-fg: #18552A;  --cumplido-bg: #E4F3E6;  --cumplido-solid: #23703A;
  --neutro-fg: #35505E;    --neutro-bg: #EEF2F4;
  --peligro: #B3261E;  --peligro-hover: #9C1F18;  --peligro-pressed: #8C1D18; /* botón destructivo (blanco >= 6.5:1) */

  /* ---------- Tipografía (una sola familia; tamaños en rem para respetar la preferencia del usuario) ---------- */
  --font: "Atkinson Hyperlegible Next", system-ui, -apple-system, "Segoe UI", Arial, sans-serif;
  --text-xs: 1rem;       /* 16 — mínimo absoluto: metadatos, captions */
  --text-sm: 1.0625rem;  /* 17 — celdas de tabla desktop */
  --text-base: 1.125rem; /* 18 — cuerpo estándar, botones md, inputs */
  --text-lg: 1.25rem;    /* 20 — cuerpo de la app del paciente, botones lg, título de tarjeta */
  --text-xl: 1.5rem;     /* 24 — título de sección, título de ventana */
  --text-2xl: 1.875rem;  /* 30 — título de pantalla móvil */
  --text-3xl: 2.375rem;  /* 38 — título de pantalla desktop */
  --text-4xl: 3rem;      /* 48 — cifras grandes (KPI, reloj L) */
  --leading-body: 1.6;
  --leading-ui: 1.3;     /* etiquetas, botones, tarjetas */
  --leading-title: 1.2;
  --leading-number: 1.1;
  --para-gap: 1.5rem;

  /* ---------- Espaciado (base 4 px) ---------- */
  --sp-0: 0; --sp-1: 4px; --sp-2: 8px; --sp-3: 12px; --sp-4: 16px; --sp-4h: 20px; --sp-5: 24px;
  --sp-6: 32px; --sp-7: 48px; --sp-8: 64px; --sp-9: 96px;

  /* ---------- Forma ---------- */
  --r-xs: 4px;     /* marcas pequeñas: indicador de pestaña, barras */
  --r-sm: 8px;     /* inputs, checkbox, imágenes, tooltip, ítems de menú, textarea */
  --r-md: 14px;    /* botones, tarjetas, tablas, popover, toast, banner, segmented */
  --r-lg: 24px;    /* diálogo, hoja inferior, panel lateral, burbujas de chat */
  --r-pill: 999px; /* badges, chips, switch, indicador de nav, avatar */

  /* ---------- Bordes ---------- */
  --bw-1: 1px;     /* divisores y bordes decorativos */
  --bw-2: 2px;     /* controles (inputs, chips, botón secundario) */
  --bw-foco: 3px;  /* anillo de foco */
  --bw-4: 4px;     /* marcador de fila seleccionada, nodo actual del stepper, indicador de pestaña */

  /* ---------- Elevación ---------- */
  --e0: none;                                                                    /* plano: contenido de página */
  --e1: 0 1px 2px rgb(18 48 63 / .08), 0 2px 8px rgb(18 48 63 / .06);            /* tarjeta en reposo */
  --e2: 0 4px 12px rgb(18 48 63 / .12);                                          /* tarjeta interactiva en hover, encabezado con scroll */
  --e3: 0 8px 24px rgb(18 48 63 / .16);                                          /* popover, menú, toast, tooltip */
  --e4: 0 16px 48px rgb(18 48 63 / .24);                                         /* diálogo, panel lateral */
  --e-arriba: 0 -4px 16px rgb(18 48 63 / .12);                                   /* barra inferior, hoja inferior, barra de acción fija */

  /* ---------- Capas (z-index) ---------- */
  --z-base: 0; --z-sticky: 100; --z-nav: 200; --z-dropdown: 300; --z-panel: 400;
  --z-scrim: 500; --z-modal: 510; --z-toast: 600; --z-tooltip: 700;

  /* ---------- Tamaños de controles y estructura ---------- */
  --h-ctrl-sm: 40px;   /* solo desktop denso (acciones en fila de tabla) */
  --h-ctrl-md: 48px;   /* estándar; también objetivo táctil mínimo */
  --h-ctrl-lg: 56px;   /* acción principal en móvil */
  --h-input-movil: 56px; --h-input-desktop: 48px;
  --tap-min: 48px;
  --h-header-movil: 56px; --h-nav-movil: 72px; --h-barra-accion: 88px;
  --h-topbar: 64px; --w-sidebar: 264px; --w-sidebar-colapsado: 72px;
  --h-fila-tabla: 56px; --h-fila-tabla-compacta: 48px; --h-encabezado-tabla: 48px;
  --w-dialog-sm: 480px; --w-dialog-md: 640px; --w-dialog-lg: 800px;
  --w-panel: 480px; --w-panel-lg: 640px; --w-toast: 480px; --w-menu-min: 240px; --w-menu-max: 360px;
  --w-contenido: 1280px; --w-contenido-paciente: 960px; --w-lectura: 66ch;
  --icono-sm: 20px; --icono-md: 24px; --icono-lg: 32px;

  /* ---------- Movimiento ---------- */
  --dur-rapida: 120ms;  /* feedback: color, foco, salida de ventanas */
  --dur-media: 220ms;   /* entrada de diálogo, toast, popover */
  --dur-lenta: 320ms;   /* hoja inferior, panel lateral, navegación entre pantallas */
  --ease: cubic-bezier(.2, .7, .2, 1);     /* entrada */
  --ease-salida: cubic-bezier(.4, 0, 1, 1); /* salida */
}

/* ---------- Base ---------- */
html { font-size: 100%; }
[data-texto="grande"] { font-size: 125%; }      /* selector A+ */
[data-texto="muy-grande"] { font-size: 150%; }  /* selector A++ */
body { margin: 0; font-family: var(--font); font-size: var(--text-base); line-height: var(--leading-body); color: var(--ink); background: var(--fondo); -webkit-text-size-adjust: 100%; }
a { color: var(--azul-800); text-decoration: underline; text-decoration-thickness: 2px; text-underline-offset: 3px; }
a:hover { text-decoration-thickness: 3px; }
:focus-visible { outline: var(--bw-foco) solid var(--azul-800); outline-offset: 2px; }
.sobre-oscuro :focus-visible { outline-color: #FFFFFF; }
.num { font-variant-numeric: tabular-nums; }

/* ---------- Estilos de texto (usar estas clases o su equivalente exacto) ---------- */
.t-display { font-size: var(--text-4xl); font-weight: 700; line-height: var(--leading-number); }
.t-h1 { font-size: var(--text-2xl); font-weight: 700; line-height: var(--leading-title); }          /* móvil */
@media (min-width: 768px) { .t-h1 { font-size: var(--text-3xl); } }                                /* tablet y desktop */
.t-h2 { font-size: var(--text-xl); font-weight: 700; line-height: var(--leading-title); }
.t-h3 { font-size: var(--text-lg); font-weight: 700; line-height: var(--leading-ui); }
.t-body { font-size: var(--text-base); font-weight: 400; line-height: var(--leading-body); max-width: var(--w-lectura); }
.t-body-lg { font-size: var(--text-lg); font-weight: 400; line-height: var(--leading-body); max-width: var(--w-lectura); } /* app del paciente */
.t-label { font-size: var(--text-base); font-weight: 600; line-height: var(--leading-ui); }
.t-caption { font-size: var(--text-xs); font-weight: 400; line-height: 1.5; color: var(--ink-soft); }
.t-cell { font-size: var(--text-sm); font-weight: 400; line-height: 1.4; }
p { margin-block: 0 var(--para-gap); text-align: left; }
h1, h2, h3 { margin: 0; }

/* ---------- Layout ---------- */
.contenedor { width: 100%; max-width: var(--w-contenido); margin-inline: auto; padding-inline: var(--sp-4); }       /* móvil: margen 16 */
@media (min-width: 768px) { .contenedor { padding-inline: var(--sp-5); } }                                          /* tablet: 24 */
@media (min-width: 1200px) { .contenedor { padding-inline: var(--sp-6); } }                                         /* desktop: 32 */
.rejilla { display: grid; gap: var(--sp-4); grid-template-columns: repeat(4, minmax(0, 1fr)); }                     /* móvil: 4 col, gutter 16 */
@media (min-width: 768px) { .rejilla { gap: var(--sp-5); grid-template-columns: repeat(8, minmax(0, 1fr)); } }      /* tablet: 8 col, gutter 24 */
@media (min-width: 1200px) { .rejilla { grid-template-columns: repeat(12, minmax(0, 1fr)); } }                      /* desktop: 12 col, gutter 24 */

/* ---------- Superficies ---------- */
.tarjeta { background: var(--superficie); border: var(--bw-1) solid var(--linea); border-radius: var(--r-md); box-shadow: var(--e1); padding: var(--sp-5); }
.scrim { position: fixed; inset: 0; background: var(--scrim); z-index: var(--z-scrim); }
.safe-bottom { padding-bottom: env(safe-area-inset-bottom); }

/* ---------- Movimiento reducido ---------- */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: .01ms !important; animation-iteration-count: 1 !important; transition-duration: .01ms !important; scroll-behavior: auto !important; }
}
```
