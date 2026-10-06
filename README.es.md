# WPF en Linux — portar `dotnet/wpf` para compilar y renderizar de forma nativa en Linux

[English](README.md) | [中文](README.zh-CN.md) | **Español**

**Windows / original** | [**Linux / port**](docs.Linux/README.md)

**Qué es.** Este repositorio hace que una aplicación WPF **se compile desde el código fuente en Linux, abra una ventana, dibuje de verdad y responda al ratón y al teclado**.
**Límite (dicho claro):** la compatibilidad con binarios WPF **compilados en Windows** queda **explícitamente fuera de alcance** — ese límite elimina toda la ruta de compatibilidad binaria.
La instantánea del upstream está en `upstream/wpf/` (copia de solo lectura de `dotnet/wpf`, MIT); el README original del upstream se conserva literalmente en [`README-Window.md`](README-Window.md).

---

## 1. Qué funciona hoy (lecturas; todas recalculables)

| Capacidad | Lectura actual | Cómo recalcular |
|---|---|---|
| **Compilar** la capa administrada de WPF | seis ensamblados (`PresentationCore` / `PresentationFramework` / `WindowsBase` / `System.Xaml` / `DirectWriteForwarder` / `DirectWrite.Linux.Provider`) con **0 errores** (Release) | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **Lado nativo** | `libwpfwin32.so` (Win32/GDI/OEM/GDI+), `libwpfwic.so` (WIC → Skia), `wpfgfx_cor3.so` (milcore AOT) | `bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build` |
| **Abrir ventana y renderizar** (muestra del repo) | `samples/WpfTextDemo`: `14/14` fotogramas no vacíos, `未画种类 0` | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **Forma de terceros** (criterio del repo) | `samples/ThirdPartyMini`: solo a través de `build/third-party/WpfLinux.props`, fuera de la solución, artefactos copiados fuera del árbol | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25` |
| **Aceptación en un comando** | `verify-all.sh`: **64 pasos** (actual `64 ✅ / 0 ❌`, `rc=0`) | `bash verify-all.sh` |
| **Línea base congelada** | `docs/CURRENT-STATE.md:9` = `gen=#82` / `sha16=05c5e521c3b14ace` / `1,248,947 B` | `bash build/MilBridge/tools/baseline-sha-check.sh` |
| **Defectos registrados** | `DEFREG=PASS declared=225` | `bash build/MilBridge/tools/defect-registry-check.sh` |
| **PTS / LineServices nativo** | 🟡 **vía larga (no bloqueante)**: lectura **可操作 42／实现口径 42**; cada entrada restante está nombrada y probada como fin legítimo | `bash build/MilBridge/tools/pts-gap-count-check.sh` |

---

## 2. Tres comandos (compilar → ventana → aceptación)

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # 1. portar + compilar
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # 2. ventana + render
bash verify-all.sh                                                                   # 3. aceptación (64 pasos)
```

> ⚠️ `WAVE_OWNER` es una **restricción estructural**: sin él `integration-wave.sh` termina.
> Las ediciones manuales de `build/*.Linux/*.csproj` se borran en la siguiente regeneración de `port-lib.py`: el cableado vive en los **aplicadores** (`src/WpfGfx.Linux.Native/tools/patch-*.py`).
> Preparación del entorno: [`docs.Linux/guide/building.md`](docs.Linux/guide/building.md) · Primeros pasos: [`docs.Linux/guide/getting-started.md`](docs.Linux/guide/getting-started.md) · Muestras: [`docs.Linux/guide/running-samples.md`](docs.Linux/guide/running-samples.md).

---

## 3. Dónde mirar (navegación)

| Entrada | Qué es |
|---|---|
| [`README-Window.md`](README-Window.md) | el **README original de `dotnet/wpf`**, conservado literalmente |
| [`docs/README.md`](docs/README.md) | bus de documentación del **lado original / Windows** (normativo / actual / evidencia / historia) |
| [`docs.Linux/README.md`](docs.Linux/README.md) | bus de documentación del **lado port / Linux** — tabla tema × idioma y «quiero X → leo Y» ([中文](docs.Linux/README.zh-CN.md) · [Español](docs.Linux/README.es.md)) |
| [`Guide.Linux/README.md`](Guide.Linux/README.md) | **lista de puntos de entrada en un comando** — los tres puntos de entrada (`verify-all.sh` / `integration-wave.sh` / `close-wave.sh`): uso, invocación típica, requisitos previos y criterio |

Las dos raíces son la regla: **`X` = lado original / Windows**, **`X.Linux` = lado port / Linux**
(convención congelada: [`docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`](docs.Linux/design/_PHASE0-NAMING-CONVENTION.md)).

---

## 4. Límites conocidos (lista honesta)

- La configuración autoritativa de compilación es **`Release`** (única declaración: `build/SelfBuiltConfig.props`; autocomprobación `bash build/selfbuilt-config.sh --check`).
- Los nueve artefactos autoritativos **no** están en git (`src/WpfGfx.Linux.Native/bin/` está ignorado): un clon limpio debe **recompilarlos**.
- Funciones solo de Windows: se degradan cuando existe degradación (DWM = "hay DWM, composición apagada"); si no, **fallan con honestidad** (código de error, sin fingir éxito).
- La evidencia real de terceros (la muestra HandyControl) vive **fuera** del repositorio: es un hecho de producto, **no** un criterio interno; el criterio interno es `samples/ThirdPartyMini`.
- Detalles: [`docs/CURRENT-STATE.md`](docs/CURRENT-STATE.md), [`docs/ROUTES.md`](docs/ROUTES.md), [`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](samples/WpfFeatureProbe/KNOWN-DEFECTS.md), [`build/MilBridge/HANDOFF-NEXT.md`](build/MilBridge/HANDOFF-NEXT.md).
- El `README.md` de la raíz **anterior** a esta reescritura (con las correcciones fechadas `T-A33`…`T-B19`) se archiva literalmente en [`docs.Linux/evidence/README-dated-archive.md`](docs.Linux/evidence/README-dated-archive.md).

---

## 5. Licencia

- Upstream `upstream/wpf/**`: **MIT** (ver `upstream/wpf/LICENSE.TXT`).
- `build/fonts/*.ttf`: **SIL OFL 1.1** (ver `build/fonts/LICENSE-OFL.txt`).
- Todo lo añadido por este repositorio (`build/`, `src/WpfGfx.Linux*`, `samples/`, `tests/`, `docs/`, `docs.Linux/`, …) se publica con la licencia de este repositorio.

---

[English](README.md) | [中文](README.zh-CN.md) | **Español** · [bus de documentación Linux / port](docs.Linux/README.md) · [bus de documentación Windows / original](docs/README.md)
