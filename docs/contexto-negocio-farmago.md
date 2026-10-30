# FarmaGo — Contexto de proyecto y negocio

Especificación funcional y técnica del proyecto FarmaGo, pensada para procesamiento, análisis e interpretación por LLMs y asistentes de IA. Es la fuente de contexto de negocio del proyecto: ante dudas sobre alcance, flujos, roles o reglas normativas, este documento manda.

**Documentos relacionados:**
- `PRODUCT.md` (raíz del repo): contexto de producto del módulo Pendientes (historias, reglas de presentación, decisiones técnicas, contradicciones abiertas). Complementa este documento; si una regla de producto contradice la normativa o el alcance descritos aquí, este documento manda.
- `docs/farmago-manual-identidad.md`: manual de identidad y sistema de diseño.

---

## 1. Resumen ejecutivo y alcance

### 1.1 Definición del sistema

FarmaGo es una plataforma tecnológica que actúa como orquestador logístico y de cumplimiento normativo dentro del sistema de salud colombiano. Su función principal es conectar a Entidades Promotoras de Salud (EPS) y gestores farmacéuticos con pacientes, repartidores y una red distribuida de puntos de dispensación/droguerías aliadas, asegurando visibilidad completa y trazabilidad en tiempo real.

### 1.2 Límites claros del sistema (fuera de alcance)

- NO toma decisiones clínicas.
- NO define la disponibilidad, cobertura o autorización de medicamentos (responsabilidad exclusiva de la EPS, gestor o junta médica).
- NO consulta ni administra el inventario de la red de farmacias.
- Alcance delimitado: gestión logística, orquestación de entregas y trazabilidad del proceso.

---

## 2. Vías de entrada y flujos operativos

La plataforma canaliza todas las operaciones mediante dos modalidades independientes sobre la misma infraestructura:

| Variable | Domicilio voluntario | Gestión de pendientes |
|---|---|---|
| Condición de activación | Medicamento disponible y previamente autorizado por la EPS. El paciente prefiere entrega en residencia. | Medicamento no entregado en el punto original (presencial/virtual) por falta de existencias. |
| Mecanismo de notificación | Solicitud directa del paciente en la aplicación. | Notificación de la EPS o gestor farmacéutico a la plataforma indicando la orden no entregada. |
| Asignación de origen | Punto de dispensación asignado originalmente. | La EPS/gestor indica el punto alterno donde sí hay disponibilidad. La plataforma no consulta inventarios. |
| Tiempo de entrega | Según agendamiento del paciente. | Plazo estricto máximo de 48 horas (cumplimiento regulatorio). |
| Financiación del envío | 100% asumido por el paciente (tarifa de conveniencia). | 100% asumido por la EPS o gestor farmacéutico. |

---

## 3. Roles y matriz de interfaces

| Actor / rol | Función principal | Interfaz / herramienta |
|---|---|---|
| EPS y gestores farmacéuticos | Monitoreo de cumplimiento de pendientes, control de tiempos frente a límites normativos y generación de reportes consolidados para entes de control. | Panel web de cumplimiento |
| Puntos de dispensación / farmacias | Alistamiento del medicamento tras la designación de la orden (original o reasignada) por parte de la EPS/gestor. | Módulo/portal de dispensación |
| Repartidores | Aceptación de pedidos, optimización de rutas de última milla y captura de pruebas de entrega verificables. | Aplicación móvil |
| Pacientes | Seguimiento en tiempo real, soporte por entregas incompletas e interacción con asistencia informativa por IA. | Aplicación móvil / web pacientes |

---

## 4. Diagnóstico del sector y marco regulatorio

### 4.1 Problemática contextual

- **Volumen de quejas:** ~2.2 millones de quejas en 2025 ante la Contraloría General de la República por entregas inoportunas.
- **Ineficiencias actuales:** uso de llamadas telefónicas y hojas de cálculo manuales, lo que genera:
  - Ausencia de visibilidad consolidada en tiempo real.
  - Procesos lentos de reasignación manual (riesgo de superar el límite de 48 h).
  - Dificultad para estructurar reportes de auditoría para la Superintendencia Nacional de Salud.
  - Incertidumbre del paciente sobre el estado de su envío.
  - Inconsistencias y errores de digitación en fórmulas médicas.
  - Confusión entre pendientes logísticos (desabastecimiento) y trámites administrativos (MIPRES).

### 4.2 Marco regulatorio relevante

- **Circular Externa 017 de mayo de 2026 (Ministerio de Salud):** impone a EPS y gestores la obligación de resolver medicamentos pendientes en un plazo máximo de 48 horas mediante redes alternas y canales domiciliarios.

---

## 5. Estrategia de despliegue y segmentación

### 5.1 Segmentación de clientes

- **Cliente institucional (pagador):** EPS y gestores farmacéuticos (suscripción + pago por despacho de pendientes).
- **Usuarios operativos:** personal de puntos de dispensación y repartidores de última milla.
- **Beneficiarios finales:** pacientes afiliados al sistema de salud.

### 5.2 Piloto inicial

- **Ubicación:** Bogotá (cobertura inicial en localidades o zonas específicas con alta densidad de pacientes prioritarios).
- **Población objetivo prioritaria:**
  - Pacientes con esquemas farmacológicos recurrentes (enfermedades crónicas o de alto costo).
  - Pacientes con enfermedades huérfanas.
  - Mujeres gestantes.
  - Adultos mayores o personas con movilidad reducida.
- **Objetivo del piloto:** validar tiempos reales de resolución de pendientes, ajustar la operación con una EPS/gestor aliado y preparar el escalamiento nacional.

---

## 6. Modelo de negocio y fuentes de ingreso

- **Tarifa de domicilio voluntario:** cobro directo al paciente al programar el envío. El despacho se confirma tras el pago en la app.
- **Tarifa por despacho de pendientes:** cobro facturado a la EPS / gestor por cada pendiente reasignado y entregado con éxito en el plazo de ≤ 48 horas.
- **Suscripción / fee de plataforma:** cobro recurrente a la EPS / gestor por el uso del panel de cumplimiento, analítica y generación de reportes regulatorios.

---

## 7. Especificación de módulos del sistema

```
[Módulo A: Gestión de Pendientes] ────► [Módulo B: Logística y Última Milla]
                 │                                        │
                 ▼                                        ▼
[Módulo C: Cumplimiento y Reportería]    [Módulo E: Domicilio Voluntario]
                 ▲                                        ▲
                 └────────── [Módulo D: Asistencia IA] ───┘
```

- **Módulo A — Gestión de pendientes:** registro inmediato tras notificación de la EPS; recepción del punto alterno designado por la EPS; asignación de repartidores por cercanía/tiempo; escalamiento de alertas según el avance del plazo de 48 h; separación de pendientes logísticos de trámites MIPRES.
- **Módulo B — Logística y última milla:** unificación de solicitudes (voluntarias y obligatorias); seguimiento de estados (Recibido → Asignado → En camino → Entregado); validación con firma digital, foto y verificación de identidad.
- **Módulo C — Cumplimiento y reportería:** dashboard operativo con semáforos de riesgo; alertas tempranas de vencimiento normativo; exportación de reportes para la Superintendencia Nacional de Salud; mapas de desabastecimiento e historiales.
- **Módulo D — Asistencia e inteligencia artificial:**
  - *OCR / NLP:* extracción de datos en fórmulas/autorizaciones médicas; detección de inconsistencias o vencimientos antes de radicar ante la EPS; orientación al paciente si requiere contactar al médico. Escalamiento a revisión humana en casos ambiguos.
  - *RAG (base normativa):* consultas contextuales sobre el Plan de Beneficios en Salud (PBS) para informar al paciente sobre trámites y requisitos.
- **Módulo E — Domicilio voluntario:** solicitud y pago en app; recordatorio automático de renovación (~20 días antes de autorizar tratamiento recurrente); confirmación/modificación de franja horaria de entrega; integración al flujo unificado de seguimiento.

---

## 8. Arquitectura tecnológica (definida)

| Capa | Tecnologías seleccionadas |
|---|---|
| Frontend | React, TypeScript, Tailwind CSS (web/móvil responsiva + dashboard web institucional). |
| Backend | Node.js, NestJS (API REST, autenticación RBAC, cron jobs para vencimientos). |
| Bases de datos | PostgreSQL (transaccional/relacional), MongoDB (documentos, logs, eventos). |
| Inteligencia artificial | Python (scikit-learn), APIs de LLM (OpenAI / Gemini), base vectorial (pgvector / Pinecone). |
| Infraestructura | Docker, Cloud (AWS / Azure), Vercel (frontend), GitHub (control de versiones). |

---

> **Nota para este repo (Flutter):** la implementación móvil del frontend de este repositorio sigue el manual de identidad en `docs/farmago-manual-identidad.md`. La pila descrita en la sección 8 es la arquitectura objetivo del sistema completo y no describe necesariamente el código actual de este repo.
