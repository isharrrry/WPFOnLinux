# docs.Linux — bus de documentación del lado port / Linux

[English](README.md) | [中文](README.zh-CN.md) | **Español**

**Windows / original** | **Linux / port** (esta página)　·　[fachada del repositorio](../README.md) · [bus de documentación original / Windows](../docs/README.md)

Este directorio es el **lado port / Linux** de las dos raíces emparejadas: `docs/` (lado original / Windows) y `docs.Linux/` (aquí).
Dos reglas:

1. **Cada página en tres idiomas**: `.md` (por defecto · inglés), `.zh-CN.md` (**original autoritativo**), `.es.md` (traducción). Cada página lleva arriba su línea de cambio de idioma y las tres versiones se enlazan.
2. **Nombres emparejados**: `X` = lado original / Windows, `X.Linux` = lado port / Linux
   (convención congelada: [`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md)).

> 📌 **Este directorio no es la autoridad sobre el estado actual.** Contiene los capítulos de inicio / diseño / alineación con el upstream del lado port.
> Para «dónde estamos hoy» lee [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) (línea base congelada, línea de máquina en la 9) y [`docs/ROUTES.md`](../docs/ROUTES.md) (hoja de ruta autoritativa).
> La evidencia histórica (olas, informes de carril, traspaso) se indexa en [`evidence/README.md`](evidence/README.md) — **esa zona es evidencia histórica, no la leas como estado actual**.

---

## 1. Tema × idioma

| Tema | Versiones | Qué cubre |
|---|---|---|
| **Primeros pasos** | [English](guide/getting-started.md) · [中文](guide/getting-started.zh-CN.md) · [Español](guide/getting-started.es.md) | Qué es este repositorio, si se puede ejecutar ya, los tres pasos mínimos, el vocabulario (`port-lib`, aplicadores, dientes, olas…), errores comunes |
| **Compilación** | [English](guide/building.md) · [中文](guide/building.zh-CN.md) · [Español](guide/building.es.md) | Dependencias y `setup-env.sh` / `verify-env.sh`, el modelo generativo (`port-lib.py` **reescribe** el csproj entero), disciplina de aplicadores, las cuatro etapas de `integration-wave.sh`, la única declaración de Release |
| **Ejecutar muestras** | [English](guide/running-samples.md) · [中文](guide/running-samples.zh-CN.md) · [Español](guide/running-samples.es.md) | `WpfTextDemo` (la muestra de la puerta), `ThirdPartyMini` (forma de terceros), `HelloMil` / `HelloWpf` / `WpfFeatureProbe`, `Xvfb` y los dos niveles, cómo leer las líneas de máquina |
| **Arquitectura** | [English](design/architecture.md) · [中文](design/architecture.zh-CN.md) · [Español](design/architecture.es.md) | Las cuatro capas (generador de port → seis ensamblados administrados → shims nativos → milcore AOT), el flujo de datos, los nueve artefactos y la línea base congelada, instrumentos para los instrumentos |
| **Contribuir** | [English](design/contributing.md) · [中文](design/contributing.zh-CN.md) · [Español](design/contributing.es.md) | Reclamar una ruta, dominios de escritura, `WAVE_OWNER`, la cadena de olas, el cableado va en los aplicadores, la disciplina `NOINFO`, las reglas de idioma y nombres |
| **Alineación con el upstream** | [English](upstream/layout.md) · [中文](upstream/layout.zh-CN.md) · [Español](upstream/layout.es.md) | Los **21 subárboles de proyecto** del upstream, una fila cada uno: ruta upstream ↔ dónde aterriza aquí ↔ sobrescritura/sustitución Linux |
| **Capa Linux** | [English](upstream/linux-overlay.md) · [中文](upstream/linux-overlay.zh-CN.md) · [Español](upstream/linux-overlay.es.md) | De qué se compone la capa (`src/WpfGfx.Linux/**`, `src/WpfGfx.Linux.Native/**`, `build/shims/**`, los aplicadores) y cómo se alinean los tres artefactos nativos |
| **Índice de evidencia** | [English](evidence/README.md) · [中文](evidence/README.zh-CN.md) · [Español](evidence/README.es.md) | **Navegación**: dónde están los pre-registros de ola, los informes de carril, `handoff`, `ROUTES` y `history`, y por qué **se quedan donde están** |

> Los dos artefactos de la fase 0 (internos, sin traducir): [`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md) y
> [`evidence/_PHASE0-READERS-INVENTORY.md`](evidence/_PHASE0-READERS-INVENTORY.md).

---

## 2. Quiero X → leo Y

| Quiero… | Lee |
|---|---|
| **ponerlo en marcha primero** | [guide/getting-started.es.md](guide/getting-started.es.md) |
| **compilar desde cero** | [guide/building.es.md](guide/building.es.md) → luego `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **ver una ventana / ejecutar una muestra** | [guide/running-samples.es.md](guide/running-samples.es.md) → luego `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **aceptación en un comando (64 pasos)** | `bash verify-all.sh` (calibre en [guide/building.es.md](guide/building.es.md)) |
| **encontrar los puntos de entrada (qué script ejecutar)** | [../Guide.Linux/README.md](../Guide.Linux/README.md) — lista de puntos de entrada (`verify-all.sh` / `integration-wave.sh` / `close-wave.sh`) |
| **entender el conjunto** | [design/architecture.es.md](design/architecture.es.md) |
| **empezar a tocar código / reclamar tarea** | [design/contributing.es.md](design/contributing.es.md) y la especificación [`docs/PORT-SPEC.md`](../docs/PORT-SPEC.md) |
| **ver dónde aterriza un proyecto del upstream** | [upstream/layout.es.md](upstream/layout.es.md) |
| **ver qué cambiamos o sustituimos** | [upstream/linux-overlay.es.md](upstream/linux-overlay.es.md) |
| **buscar evidencia histórica** | [evidence/README.es.md](evidence/README.es.md) |
| **ver el estado actual autoritativo** | [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) (línea `:9`) y [`docs/ROUTES.md`](../docs/ROUTES.md) |
| **retomar en una sesión nueva** | [`build/MilBridge/HANDOFF-NEXT.md`](../build/MilBridge/HANDOFF-NEXT.md) |
| **entender los nombres (por qué `.Linux`)** | [design/_PHASE0-NAMING-CONVENTION.md](design/_PHASE0-NAMING-CONVENTION.md) |
| **leer el README del upstream** | [`README-Window.md`](../README-Window.md) |

---

## 3. Reglas para escribir en esta zona

- **Alcance trilingüe**: una página nueva son tres archivos homónimos `.md` / `.zh-CN.md` / `.es.md`, cada uno con su línea de idioma arriba; **los enlaces de navegación y los comandos deben estar completos y ser correctos**.
- **El chino es el original autoritativo**; inglés y español son traducciones (pueden ser más breves, pero **no pueden faltar enlaces ni comandos**).
- **Los hechos salen del árbol**: los comandos deben ejecutarse de verdad (`bash verify-all.sh`); nunca fijes cifras viejas (el número de pasos siempre se cita del `VERIFYALL-STEPS-DECL` **actual** — hoy **64 gen=#82**).
- **Esta zona no es la autoridad del estado actual**: toda afirmación de «cómo está hoy» apunta a [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) / [`docs/ROUTES.md`](../docs/ROUTES.md).

---

[English](README.md) | [中文](README.zh-CN.md) | **Español** · [fachada del repositorio](../README.md) · [bus docs/](../docs/README.md) · [índice de evidencia](evidence/README.es.md)
