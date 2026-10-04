# Ejecutar muestras

[English](running-samples.md) | [中文](running-samples.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md). Requisito previo: compilar primero según [building.es.md](building.es.md).

---

## 1. La muestra de la puerta: `WpfTextDemo` (un comando)

```bash
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both
```

- Arranca su **propio** `Xvfb :97` (1280x1024x24; `:99` es de `verify-all.sh`) y solo mata el proceso que él arrancó.
- **Los dos niveles deben pasar**; que pase uno solo es un fallo:
  - el **nivel por defecto** limpia todas las variables de fuente `WPF_LINUX_*` / `HLWPF_*` (esa es la configuración que recibe una aplicación real);
  - el **nivel env** es solo un control.
- Cuatro criterios: proceso vivo + `未画种类 0` + captura no vacía ni de color plano + recuentos de color.
- Líneas de máquina: `WPTD_SUMMARY` / `WPTD_GATE`, más la ruta PNG de cada fotograma.

## 2. La muestra de forma de terceros: `ThirdPartyMini`

```bash
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25
```

- Se cablea solo por `build/third-party/WpfLinux.props`, **no** está en la solución y sus artefactos se **copian fuera del árbol** antes de ejecutar.
- La receta está en [`docs/THIRD-PARTY-APPS.md`](../../docs/THIRD-PARTY-APPS.md); es un paso de `verify-all.sh`.

## 3. Otras muestras y sondas

| Muestra | Para qué | Entrada |
|---|---|---|
| `samples/HelloWpf` | la aplicación WPF mínima | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh` |
| `samples/HelloMil` | verificación mínima directa a MIL (sin XAML) | ver `samples/HelloMil/` |
| `samples/WpfFeatureProbe` | la **sonda de características** | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh`; registro [`KNOWN-DEFECTS.md`](../../samples/WpfFeatureProbe/KNOWN-DEFECTS.md) |
| `samples/WpfTextDemo` | la **muestra de la puerta** | ver §1 |

## 4. Suites de prueba (`tests/`)

- `tests/WpfGfx.Linux.Tests/{Commands,ManagedLayer,Rendering,Windowing,Presentation,HelloMil}.Tests` — proyectos `dotnet test` por dominio.
- `tests/parity/**` — corpus comparados con los valores de Windows (dos JSON grandes están en `.gitignore`: **excluir ≠ borrar**).
- `tests/golden/**`, `tests/U1-golden/**`, `tests/Rendering.Harness`, `tests/flaky-loop.sh`.

## 5. Máquinas sin cabecera y números de pantalla

| Pantalla | Quién la usa |
|---|---|
| `:97` | `run-wpftextdemo.sh` |
| `:99` | `verify-all.sh` |
| otras | dispositivos privados de cada carril; `verify-all.sh --no-x` no arranca Xvfb (los casos sin `DISPLAY` se saltan: eso es cobertura ausente, no un pase) |

## 6. Leer líneas de máquina (tres reglas)

1. **Quieres la línea de veredicto, no el código de salida**: `WPTD_GATE=`, `BASELINE … result=`, `PTSGAP=`, `DEFREG=`.
2. **`NOINFO` no es verde**.
3. **Lecturas emparejadas**: antes/después (o puerta abierta/cerrada) son la evidencia.

---

[English](running-samples.md) | [中文](running-samples.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [primeros pasos](getting-started.es.md) · [compilación](building.es.md)
