# Arquitectura

[English](architecture.md) | [中文](architecture.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md).
> Aterrizaje por proyecto: [`../upstream/layout.es.md`](../upstream/layout.es.md); qué es la capa: [`../upstream/linux-overlay.es.md`](../upstream/linux-overlay.es.md).
> La versión profunda está en [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md).

---

## 1. Treinta segundos

```
upstream/wpf/**                 fuente upstream de solo lectura (nunca se edita; única entrada de compilación)
      │  build/port-lib.py      (descarta fuente solo-Windows, incorpora *.Linux.cs generados, **reescribe** el csproj)
      ▼
build/<Proyecto>.Linux/*.csproj ──compilar──▶  seis ensamblados administrados
      │  reproducción de aplicadores (patch-*.py: idempotente, --check, aserciones de anclas)
      ▼
tres artefactos nativos: libwpfwin32.so / libwpfwic.so / wpfgfx_cor3.so
```

## 2. Las cuatro capas

| Capa | Qué es | Dónde |
|---|---|---|
| **① Generación del port** | convertir el csproj del upstream en csproj compilable en Linux (cortar Arcade, expandir `$(Wpf*Dir)`, listas de exclusión, recursos, firma/identidad) | `build/port-lib.py`, `build/port-pbt.sh`, `build/excludes/*.txt` |
| **② Superficie administrada** | los seis ensamblados propios (`pc` / `pf` / `windowsbase` / `system.xaml` / `dwf` / `provider`) más los `*.Linux.cs` por proyecto | `build/<Proyecto>.Linux/**`, `build/shims/**`, `src/WpfGfx.Linux/**` |
| **③ Shims nativos (C)** | superficies Win32 / mensajes / GDI / OEM / GDI+, el puente WIC y el milcore AOT | `src/WpfGfx.Linux.Native/src/**`, `build/DirectWrite.Linux/**`, `build/MilBridge/**` |
| **④ Criterios y puertas** | los 64 pasos de `verify-all.sh`, 107 dientes, los cinco brazos, la línea base y el registro de defectos | `verify-all.sh`, `build/MilBridge/tools/**`, `build/MilBridge/known-red.json` |

## 3. Flujo de datos (un render)

1. Aplicación (XAML) → `PresentationFramework` → `PresentationCore` → **flujo de comandos MIL**.
2. El flujo entra en `wpfgfx_cor3.so` (milcore AOT): `Commands/**` lo decodifica y despacha; `Resources/` guarda recursos y árbol visual.
3. Las instrucciones de dibujo llegan a Skia vía `Rendering/`; los glifos los manejan `Text/**` y `build/shims/PresentationCore.HbTextLine.cs`.
4. Ventanas/mensajes/entrada pasan por `src/WpfGfx.Linux.Native/src/win32_{core,msg,x11}.c` ↔ `Windowing/**`.
5. X11 lo presenta; en el lado de aceptación `verify-all.sh` y los runners abren ventana, capturan y cuentan colores de verdad.

## 4. Artefactos autoritativos y criterios vigilados

- **Los nueve artefactos**: sus sha16 están en el bloque de congelación; **no** están en git ⇒ hay que reconstruirlos.
- **La línea base congelada**: `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` es la única autoridad; su sha se declara **solo** en `docs/CURRENT-STATE.md:9` (hoy `gen=#82`).
- **Los cinco brazos**: `tline` / `tab-*` / `textlineproto`, comparados línea a línea con los valores de Windows.
- **Rojo conocido**: `build/MilBridge/known-red.json`; un rojo debe estar **registrado**.
- **Instrumentos para los instrumentos**: trampas de comillas, censo `pipefail`/SIGPIPE, autocontroles de cobertura, lista blanca de entradas de raíz.

## 5. Decisiones de diseño (una línea cada una)

- **Sustituir, no hacer fork**: la pila nativa de Windows se cambia entera por una implementación Linux.
- **Reescribir, no editar in situ**: el csproj es **generado** y el cableado va en los aplicadores ⇒ los incidentes «cambiado pero sin efecto» quedan auditables.
- **Al lado, no mezclado**: la superficie Linux vive en `src/**`, `build/shims/**`, `build/*.Linux/**`; el upstream en `upstream/wpf/**`.
- **Hacer de verdad lo que se puede; si no, fallar con honestidad** — nunca cambiar una mentira por una pantalla verde.

---

[English](architecture.md) | [中文](architecture.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [capa Linux](../upstream/linux-overlay.es.md) · [contribuir](contributing.es.md)
