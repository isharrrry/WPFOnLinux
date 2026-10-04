# Compilación

[English](building.md) | [中文](building.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md). Esta página cubre «cómo compilarlo»; para ejecutarlo, [running-samples.es.md](running-samples.es.md).

**Un comando** (única entrada):

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh
```

`WAVE_OWNER` es una **restricción estructural**: sin él el script **termina**. Cada pasada añade un registro trazable a `build/wave-audit.log`.

---

## 1. Dependencias y entorno

```bash
sudo apt-get install -y gcc libc6-dev libx11-dev zlib1g-dev clang                       # shims nativos + AOT
sudo apt-get install -y xvfb x11-apps x11-utils imagemagick fontconfig libfontconfig1   # aceptación + muestras
dotnet --version                                                                        # global.json fija 10.0.111
bash build/setup-env.sh && bash build/verify-env.sh
```

## 2. El modelo de compilación es **generativo**

```
upstream/wpf/** (fuente upstream de solo lectura; única entrada de compilación)
      │  build/port-lib.py : descarta fuente solo-Windows, incorpora los *.Linux.cs generados, **reescribe** el csproj entero
      ▼
build/<Proyecto>.Linux/<Proyecto>.Linux.csproj  ──dotnet build──▶  seis ensamblados administrados
      │  reproducción de aplicadores (patch-*.py: cableado idempotente, --check, aserciones de anclas)
      ▼
tres artefactos nativos: libwpfwin32.so / libwpfwic.so / wpfgfx_cor3.so
```

- ⚠️ **Las ediciones manuales de `build/*.Linux/*.csproj` se borran en la siguiente ejecución de `port-lib.py`, sin error** ⇒ el cableado va en los **aplicadores**.
- ⚠️ **Los pre-aplicadores cambian la entrada de port-lib** ⇒ el orden es «pre-aplicadores → port-lib dirigido → resto de aplicadores → compilar».
- **Proyectos escritos a mano** (nunca regenerados): `DirectWriteForwarder.Linux`, `System.Printing.Linux`, `System.Windows.Extensions.Linux`, `CycleStub.*`, `build/DirectWrite.Linux/Provider/`, `src/WpfGfx.Linux/`.

## 3. Las nueve etapas de `integration-wave.sh`

| Etapa | Qué hace |
|---|---|
| `1/4` | regenera con `port-lib.py` el csproj de ocho proyectos (firma unificada + canalización de recursos + archivos de identidad) |
| `2/4` | reproduce todos los aplicadores (idempotente; una omisión se pierde en silencio) |
| `2.5/5` | **auditoría de aplicadores**: registrado pero sin efecto ⇒ rojo |
| `3/4` | reconstruye en orden de dependencias (`-m:1`, ver `ORDER`) |
| `3.5/5` | refresco de copias app-local |
| `3.6/5` | huellas de identidad de los generados (PC / WindowsBase / PF) |
| `3.7/5` | autocomprobación de los criterios (`--selftest` del verificador app-local) |
| `4/4` | autocomprobación de identidad de cada ensamblado propio |
| `5/5` | estabilidad de las entradas (¿cambió algo escrito a mano durante la ola?) |

## 4. Configuración: una sola declaración

- Configuración autoritativa = **`Release`**; única declaración `build/SelfBuiltConfig.props`; único lector shell `build/selfbuilt-config.sh`.
- Autocomprobación: `bash build/selfbuilt-config.sh --check`.

## 5. Los tres artefactos nativos

```bash
bash src/WpfGfx.Linux.Native/build-shim.sh                    # libwpfwin32.so
bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh       # libwpfwic.so
bash build/MilBridge/run.sh build                             # wpfgfx_cor3.so (milcore AOT)
```

⚠️ Ninguno está en git ⇒ un clon limpio **debe reconstruirlos**.

## 6. Aceptación (la puerta)

```bash
bash verify-all.sh          # 64 pasos; usa :99 por sí mismo
```

- **Calibre del número de pasos**: cita siempre el `VERIFYALL-STEPS-DECL` **actual** — hoy **`64 gen=#82`** (nunca fijes cifras viejas: pasó por 55 → 58 → 61 → 62 → 64).
- La puerta cubre compilación, pruebas, los **cinco brazos**, la puerta de aplicación y la línea base congelada, además de muchos «instrumentos para los instrumentos».

Dientes que puedes ejecutar por separado:

```bash
bash build/MilBridge/tools/verify-all-step-check.sh
bash build/MilBridge/tools/baseline-sha-check.sh
bash build/MilBridge/tools/defect-registry-check.sh
bash build/MilBridge/tools/root-entries-allowlist-check.sh
bash build/MilBridge/tools/pts-gap-count-check.sh
```

## 7. Cuando falla, mira primero

- La última línea de `build/wave-audit.log` (quién y cuándo lanzó esta pasada).
- `build/<Proyecto>.Linux/PORT-CHANGES.md` (qué cambió el port, punto por punto).
- `build/MilBridge/<carril>-report.md` (lecturas y tratamientos previos).
- Disciplina de tres estados: **no calculable ≠ aprobado** (`NOINFO` requiere una persona).

---

[English](building.md) | [中文](building.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [primeros pasos](getting-started.es.md) · [muestras](running-samples.es.md)
