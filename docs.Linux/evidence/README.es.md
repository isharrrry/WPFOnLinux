# Índice de evidencia (docs.Linux/evidence)

[English](README.md) | [中文](README.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md).

> ⚠️ **Esta zona es evidencia histórica; no la leas como estado actual.**
> Registra lo que se hizo **en su momento** y cuáles eran las lecturas.
> **El estado actual sigue** [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) (línea `:9` = línea base congelada) y [`docs/ROUTES.md`](../../docs/ROUTES.md).

---

## 1. El fallo: un «compromiso de índice» — los archivos físicos se quedan donde están

La fase 0 revisó los **84 archivos candidatos** y concluyó con un **compromiso de índice**: aquí no se mueve nada; solo se añade navegación y un banner.

**Dónde está el razonamiento**: [`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) §4, en resumen:

- **Seis archivos de alto riesgo cuestan mucho más de lo que valen**: `handoff.md` (es además el **centinela de la raíz del repositorio** para ~18 pruebas/herramientas), `docs/CURRENT-STATE.md` (lo leen **cuatro pasos de puerta**), `docs/ROUTES.md` / `docs/unimplemented.md` (los lee `pts-gap-count-check.sh` como **anclas de valor actual**), `docs/PORT-SPEC.md` / `docs/INDEX.md` (tabla de archivos gemelos, sha16).
- **63 archivos de riesgo medio** (`docs/WAVE*-PREREGISTRATION.md`) los leen cuatro sitios con **glob completo**; moverlos invalidaría cada ancla `docs/WAVE…md:NN` de los informes históricos. `docs/INDEX.md §4` dice claramente que este repositorio «**no hace mudanzas grandes a propósito**».
- **17 archivos de bajo riesgo** no tienen lector máquina, pero son pocos y dispersos.
- **Por qué el compromiso es seguro**: no se toca ningún archivo leído, así que los cuatro sitios `[G4]`, el centinela `handoff`, los cuatro pasos de línea base, las anclas de pts y la comparación de gemelos siguen verdes.

---

## 2. Navegación: dónde está cada cosa (todo **en su sitio**)

| Busco | Voy a |
|---|---|
| **El pre-registro de una ola** | `docs/WAVE<NN>-PREREGISTRATION.md` (hoy **63** archivos con el glob; **67** `WAVE*.md` en total) |
| **El libro técnico ola a ola** | [`handoff.md`](../../handoff.md) en la raíz |
| **La máquina de estados autoritativa / hoja de ruta** | [`docs/ROUTES.md`](../../docs/ROUTES.md) |
| **Informes de carril** | `build/MilBridge/<carril>-report.md` (**no mover ni borrar**) |
| **Documentos históricos aislados** | [`docs/history/`](../../docs/history/) (4 archivos) |
| **Capturas de aceptación** | [`docs/m7c-accept.png`](../../docs/m7c-accept.png), [`docs/m7c-accept-zero-probe.png`](../../docs/m7c-accept-zero-probe.png) |
| **Rojos registrados** | [`build/MilBridge/known-red.json`](../../build/MilBridge/known-red.json) |
| **El archivo de traspaso** | [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) |
| **Correcciones fechadas del README raíz anterior (literales)** | [`README-dated-archive.md`](README-dated-archive.md) |

## 3. Artefactos de las fases 0 y 1 ya presentes

- [`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) — el inventario de lectores (84 filas; **entrada de la fase 2**).
- [`README-dated-archive.md`](README-dated-archive.md) — las correcciones fechadas del `README.md` raíz **antes** de la reescritura, conservadas literalmente.

## 4. Tres reglas para citar evidencia

1. **Di el calibre y la fuente**: qué generación, qué archivo, qué comando, qué hora.
2. **Lo fechado solo se añade**: para corregir, añade una línea `⏪ dated`; **no edites el original**.
3. **`NOINFO` se queda en `NOINFO`**: si la evidencia dice «no se pudo calcular», no lo parafrasees como «pasó».

---

[English](README.md) | [中文](README.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [inventario de lectores](_PHASE0-READERS-INVENTORY.md) · [archivo fechado](README-dated-archive.md)
