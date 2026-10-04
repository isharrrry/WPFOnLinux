# Contribuir

[English](contributing.md) | [中文](contributing.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus del lado port](../README.es.md).
> La **especificación** es [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md); esta página es la entrada y los tres errores más fáciles.

---

## 1. Leer primero, en este orden

1. [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) — disciplina de criterios, de evidencia, dominios de escritura, registro de defectos, cadena de olas, trabajo en paralelo.
2. [`docs/ROUTES.md`](../../docs/ROUTES.md) — las diez rutas (`R1…R10`); el **§11 «cómo reclamar una ruta»** se puede copiar tal cual para empezar.
3. [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) — dónde estamos (línea `:9` = línea base congelada).
4. [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) — el traspaso.

## 2. Reclamar una ruta (cuatro pasos)

1. **Escribe el pre-registro**: ruta + objetivo + criterios (incluida la pata de anti-polaridad) + dominio de escritura + desplazamiento esperado.
2. **Monta un dispositivo privado**: directorio de aplicación privado (`bash build/MilBridge/tools/sync-applocal.sh <dir>`) y display X privado — **una pata con WM y otra sin WM**.
3. **Toma la lectura previa** (la mitad del par) antes de tocar nada; después, la posterior.
4. **Escribe el informe**: `build/MilBridge/<carril>-report.md` — sha16 propio, sha16 antes/después, tabla de lecturas, comandos de recálculo, límites y `NOINFO`, y **qué afirmación refutaste**.

## 3. Los tres errores más fáciles

1. **Editar el sitio equivocado**: parte de `build/*.Linux/*.csproj` y `build/*.Linux/*.Linux.cs` es **generado**. ⇒ **El cableado va en los aplicadores**; si cambias la *entrada* de port-lib, usa un **pre-aplicador**.
2. **Lanzar una ola sin reclamarla**: sin `WAVE_OWNER`, `integration-wave.sh` **termina**.
3. **Tomar `NOINFO` por verde**: si no se puede calcular, dilo. **«No rojo» ≠ «verificado»**.

## 4. Qué ejecutar según lo que cambies

| Cambiaste | Ejecuta al menos |
|---|---|
| `build/shims/**`, `src/**`, aplicadores | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| Solo documentación / criterios | los dientes correspondientes más los pasos de `verify-all.sh` (mínimo `verify-all-step-check.sh`, `baseline-sha-check.sh`, `defect-registry-check.sh`) |
| Uno de los nueve artefactos | la cadena completa de ola de [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) §5 |
| Una entrada de **raíz** añadida/eliminada | actualiza el `ALLOWLIST` embebido de `build/MilBridge/tools/root-entries-allowlist-check.sh` en la misma pasada, y ejecútalo con `--selftest` |
| Una **página de documentación** | tres archivos homónimos (`.md` / `.zh-CN.md` / `.es.md`) con línea de idioma arriba; comandos que se ejecuten de verdad |

## 5. Disciplina de documentación y nombres

- **Nombres emparejados**: `X` (lado original / Windows) y `X.Linux` (lado Linux), congelado en [`_PHASE0-NAMING-CONVENTION.md`](_PHASE0-NAMING-CONVENTION.md).
- **Dos raíces de documentación**: `docs/` y `docs.Linux/`; **sin** un `Documentation/` aparte.
- **El chino es el original autoritativo**; inglés y español son traducciones.
- **Los archivos que leen máquinas congeladas no se mueven** — ver `docs/INDEX.md §4` y [`../evidence/_PHASE0-READERS-INVENTORY.md`](../evidence/_PHASE0-READERS-INVENTORY.md).
- **Evidencia vs estado actual**: los archivos de evidencia hablan solo del «entonces»; el estado actual sigue [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md).

## 6. Commits y licencia

- El upstream `upstream/wpf/**` es **MIT** y de **solo lectura**.
- `build/keys/WcpPublicKey.snk` es una clave **pública**, segura de versionar.
- Lista de publicación: [`docs/RELEASE-READINESS.md`](../../docs/RELEASE-READINESS.md).

---

[English](contributing.md) | [中文](contributing.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [arquitectura](architecture.es.md) · [convención de nombres](_PHASE0-NAMING-CONVENTION.md)
