# Primeros pasos

[English](getting-started.md) | [中文](getting-started.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md) ([English](../README.md) · [中文](../README.zh-CN.md)).

**Qué es**: este repositorio hace que una aplicación WPF **se compile desde el fuente en Linux, abra una ventana, dibuje de verdad y responda al ratón y al teclado**.
**Qué no es**: compatibilidad con binarios WPF **compilados en Windows** — esa ruta se corta deliberadamente.

---

## 1. Requisitos

| Necesitas | Nota |
|---|---|
| Linux (x86-64) y un servidor X | Las muestras necesitan X; en máquinas sin cabecera se usa `Xvfb` (tanto `verify-all.sh` como el runner arrancan el suyo) |
| .NET SDK | [`global.json`](../../global.json) fija **`10.0.111`** (`rollForward=latestFeature`) |
| Cadena de C | los shims nativos necesitan `gcc` + `libx11-dev`; el milcore AOT necesita `clang` |
| Bibliotecas | `zlib1g-dev`; la aceptación usa además `xvfb` / `x11-utils` / `imagemagick` / `fontconfig` |

```bash
bash build/setup-env.sh      # ⚠️ escribe un origen NuGet espejo (NUGET_MIRROR); en redes normales vuelve a nuget.org
bash build/verify-env.sh     # inventario del entorno con OK/WARN/FAIL por ítem
```

---

## 2. Tres pasos

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # portar + compilar
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # ventana + render
bash verify-all.sh                                                                   # aceptación (64 pasos)
```

- La primera es la única entrada de «portar + compilar» y **debe reclamarse** (`WAVE_OWNER`) — ver [building.es.md](building.es.md).
- La segunda arranca su propio `Xvfb :97`, captura y juzga cuatro cosas (proceso vivo / `未画种类 0` / captura no vacía ni de color plano / recuentos de color por característica).
- La tercera es la puerta misma (`Xvfb :99`); buena parte de sus pasos son **instrumentos para los instrumentos**.

---

## 3. Vocabulario (diez términos)

| Término | Significado |
|---|---|
| **upstream / vendored** | `upstream/wpf/**` = instantánea **de solo lectura** de `dotnet/wpf` (la entrada de compilación) |
| **port-lib** | `build/port-lib.py`: convierte csproj del upstream en csproj compilables en Linux, **reescribiéndolos** enteros |
| **aplicador** | `src/WpfGfx.Linux.Native/tools/patch-*.py`: escribe el cableado en los generados (idempotente, `--check`, aserciones de anclas). **Editar el csproj a mano se borra** |
| **pre-aplicador** | `tools/wire-*.py`: cambia la **entrada** de port-lib, así que corre antes |
| **ola (wave)** | un lote completo de «portar + compilar + aceptar»; **debe reclamarse** (`WAVE_OWNER`) y deja línea de auditoría |
| **diente (jaw)** | archivo de criterio en `build/MilBridge/tools/*.sh|py`: solo lectura, segundos; estados `PASS/FAIL/NOINFO`, y **`NOINFO` no es verde** |
| **cinco brazos** | `tline` / `tab-*` / `textlineproto`: comparación línea a línea contra los valores de Windows |
| **línea base congelada** | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` es la única autoridad; su sha se declara **solo** en `docs/CURRENT-STATE.md:9` |
| **nueve artefactos** | los sha16 de nueve binarios autoritativos; **no** están en git, así que un clon limpio debe recompilarlos |
| **rojo conocido** | `build/MilBridge/known-red.json` más la tabla de declaraciones: un rojo debe estar **registrado** |

---

## 4. Cinco errores comunes

1. **Suponer que `build/*.Linux/*.csproj` se puede editar a mano** — se puede, pero la siguiente `integration-wave.sh` lo borra **sin error**.
2. **Suponer que `src/Microsoft.DotNet.Wpf/` guarda nuestro fuente de Windows** — `src/` solo tiene lo añadido por el port; el fuente está en `upstream/wpf/**`.
3. **Tomar `NOINFO` por verde** — aquí, no poder calcular algo no es aprobar.
4. **Suponer que la documentación describe el estado actual** — solo lo hacen [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) y [`docs/ROUTES.md`](../../docs/ROUTES.md).
5. **Suponer que la evidencia real de terceros está en el repositorio** — está **fuera**; el criterio interno es `samples/ThirdPartyMini`.

---

## 5. Siguiente paso

- Compilación → [building.es.md](building.es.md)
- Muestras / ver una ventana → [running-samples.es.md](running-samples.es.md)
- Arquitectura → [../design/architecture.es.md](../design/architecture.es.md)
- Empezar a tocar código → [../design/contributing.es.md](../design/contributing.es.md)
- Estado actual → [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) / traspaso [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md)

---

[English](getting-started.md) | [中文](getting-started.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [compilación](building.es.md) · [muestras](running-samples.es.md)
