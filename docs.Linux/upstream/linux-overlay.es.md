# La capa Linux — la otra mitad, escrita al lado del upstream

[English](linux-overlay.md) | [中文](linux-overlay.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md). La tabla proyecto a proyecto es [`layout.es.md`](layout.es.md).

**En una línea**: el árbol `dotnet/wpf` del upstream existe en este repositorio en **dos sitios** — `upstream/wpf/**` (el **fuente de solo lectura**, entrada de compilación) y la **capa de sobrescritura** (lo que añade este fork). La capa no «edita el upstream»: **se coloca al lado**. El fuente del upstream queda intacto y lo añadido vive en `src/**`, `build/shims/**`, `build/*.Linux/**` y los aplicadores.

---

## 1. Los cuatro bloques de la capa

1. **Código portado administrado** — `src/WpfGfx.Linux/**` (`WpfGfx.Linux.csproj` más `Commands/`, `Contracts/`, `Interop/`, `Rendering/`, `Resources/`, `Text/`, `Windowing/`).
2. **Shims nativos (C) y aplicadores** — `src/WpfGfx.Linux.Native/**`: `src/win32_*.c`, `include/`, `build-shim.sh` (construye `libwpfwin32.so` y emite `exports.txt`), `tools/patch-*.py` (los **aplicadores**) y `tools/wire-*.py` (pre-aplicadores).
3. **Shims por proyecto y generados** — `build/shims/**` (`*.Shim.cs` y una lista `<Proyecto>.shims.txt` por proyecto), `build/<Proyecto>.Linux/*.Linux.cs`, `ARTIFACT-SRC-FP.txt`, `PORT-CHANGES.md`.
4. **Instalaciones del lado de la compilación** — `build/port-lib.py` (**reescribe** el csproj entero), `build/integration-wave.sh` (única entrada de port + compilación), `build/excludes/*.txt`, `build/*.props` (`Directory.Upstream.props` corta la herencia de Arcade; `SelfBuiltConfig.props` es la única declaración de Release), `build/DirectWrite.Linux/**`, `build/third-party/**`, `build/MilBridge/**` (puente milcore AOT, los cinco brazos, las puertas y las herramientas de congelación).

## 2. Los tres artefactos nativos: implementación sustitutiva

- `libwpfwin32.so` — shim de la superficie Win32 / mensajes / GDI / OEM / GDI+ (**calibre**: hacer de verdad lo que se puede hacer de verdad; si no, **fallar con honestidad**).
- `libwpfwic.so` — puente de decodificación WIC → Skia (fuente en `build/DirectWrite.Linux/wic-shim/`).
- `wpfgfx_cor3.so` — el **milcore AOT** (la contraparte del upstream es la implementación VC++ de `WpfGfx/`).

Ninguno está en git (`src/WpfGfx.Linux.Native/bin/` está ignorado), así que un clon limpio **debe reconstruirlos**:
`bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build`.

## 3. Tres límites duros

- **Nunca editar el fuente del upstream**: `upstream/wpf/**` es de solo lectura.
- **Nunca editar a mano los generados**: `build/*.Linux/*.csproj` lo produce `port-lib.py`; las ediciones manuales se borran en la siguiente regeneración **sin error**. El cableado va en los **aplicadores**.
- **Nunca degradar en silencio**: lo que no se puede hacer debe quedar **nombrado** (código de error, libro de solo lectura).

## 4. Nombres y estado de la alineación con el upstream

- **Regla de nombres** (congelada: [`../design/_PHASE0-NAMING-CONVENTION.md`](../design/_PHASE0-NAMING-CONVENTION.md)): todo en pares — `X` (lado original / Windows) y `X.Linux` (lado Linux); docs `docs` / `docs.Linux`, fuente (forma objetivo) `src/Microsoft.DotNet.Wpf` / `src/Microsoft.DotNet.Wpf.Linux`, scripts `Guide` / `Guide.Linux`.
- **La ruta elegida es «A + C»**: A = documentar primero la **capa de correspondencia** (esta página y [`layout.es.md`](layout.es.md)); C = trasladar más adelante el fuente de Windows a `src/Microsoft.DotNet.Wpf/**` (para compilar) dejando `upstream/wpf/**` como copia de verificación byte a byte. Plan por fases: [`docs/UPSTREAM-ALIGN-PLAN.md`](../../docs/UPSTREAM-ALIGN-PLAN.md) (una **propuesta**).
- ⚠️ **No leas «mapeado» como «movido»**: hoy el layout físico sigue siendo «`upstream/wpf/**` fuente de solo lectura + proyectos generados en `build/*.Linux/**`», y `src/` contiene **solo** lo añadido por el port.

---

[English](linux-overlay.md) | [中文](linux-overlay.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [correspondencia con el upstream](layout.es.md)
