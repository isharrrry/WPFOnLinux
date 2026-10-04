# Getting started

**English** | [中文](getting-started.zh-CN.md) | [Español](getting-started.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md) ([中文](../README.zh-CN.md) · [Español](../README.es.md)).

**What it is**: this repository makes a WPF application **compile from source on Linux, open a window, actually draw, and respond to mouse and keyboard**.
**What it is not**: compatibility with WPF binaries **built on Windows** — that route is deliberately cut.

---

## 1. Prerequisites

| Need | Note |
|---|---|
| Linux (x86-64) and an X server | Samples need an X; headless machines use `Xvfb` (both `verify-all.sh` and the sample runner start their own) |
| .NET SDK | [`global.json`](../../global.json) pins **`10.0.111`** (`rollForward=latestFeature`); check with `dotnet --version` |
| C toolchain | the native shims need `gcc` + `libx11-dev`; the AOT milcore needs `clang` |
| System libraries | `zlib1g-dev`; acceptance also wants `xvfb` / `x11-utils` / `imagemagick` / `fontconfig` |

One-shot environment setup and self-check:

```bash
bash build/setup-env.sh      # ⚠️ writes a China-mirror NuGet source (NUGET_MIRROR in the script); switch back to nuget.org on a normal network
bash build/verify-env.sh     # prints the environment inventory, OK/WARN/FAIL per item
```

---

## 2. Three steps

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # port + build
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # window + render
bash verify-all.sh                                                                   # acceptance (64 steps)
```

- The first command is the single "port + build" entry point and **must be claimed** (`WAVE_OWNER`) — see [building.md](building.md).
- The second starts its own `Xvfb :97`, screenshots, and judges four things (process alive / `未画种类 0` / screenshot non-empty and non-solid / per-feature colour counts) — see [running-samples.md](running-samples.md).
- The third is the gate itself (`Xvfb :99`); it runs far more than "our tests" — a good part of it are **instruments for the instruments**.

---

## 3. Vocabulary (ten terms to know first)

| Term | Meaning |
|---|---|
| **upstream / vendored** | `upstream/wpf/**` = the **read-only** snapshot of `dotnet/wpf` (the build input). Touching it breaks the "upstream bytes are re-computable" evidence |
| **port-lib** | `build/port-lib.py`: turns upstream csproj into Linux-buildable csproj, **rewriting** `build/<Project>.Linux/*.csproj` wholesale |
| **applier** | `src/WpfGfx.Linux.Native/tools/patch-*.py`: writes wiring patch-style into generated files (idempotent, `--check`, anchor-count assertions). **Hand-edited csproj is erased by port-lib — wiring goes here** |
| **pre-applier** | `tools/wire-*.py`: it changes **port-lib's input**, so it must run before port-lib |
| **wave** | one whole "port + build + accept" batch; it **must be claimed** (`WAVE_OWNER`) and leaves an audit line in `build/wave-audit.log` |
| **jaw** | a criterion file in `build/MilBridge/tools/*.sh|py`: read-only, seconds, usually wired into a `verify-all.sh` step; three states `PASS/FAIL/NOINFO`, and **`NOINFO` is not green** |
| **five arms** | `tline` / `tab-*` / `textlineproto`: line-by-line comparison against Windows truth values, with a declared sha |
| **frozen baseline** | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` is the only authority; its whole-file sha is declared **only** by the machine line `docs/CURRENT-STATE.md:9` |
| **nine artefacts** | the sha16 of nine authoritative binaries, recorded in the freeze block; they are **not** in git, so a clean clone must rebuild them |
| **known red** | `build/MilBridge/known-red.json` plus the declaration table: a red must be **registered**, never excused verbally |

---

## 4. Five common pitfalls

1. **Assuming `build/*.Linux/*.csproj` can be hand-edited** — it can, but the next `integration-wave.sh` erases it **without an error**. Wiring belongs in the appliers.
2. **Assuming `src/Microsoft.DotNet.Wpf/` holds our Windows source** — `src/` currently holds **only the port's additions** (`WpfGfx.Linux`, `WpfGfx.Linux.Native`); the Windows source is `upstream/wpf/**` (read-only). See [`../upstream/layout.md`](../upstream/layout.md).
3. **Treating `NOINFO` as green** — the discipline here: not being able to compute something is not a pass.
4. **Assuming the docs describe the current state** — only [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) (machine line `:9`) and [`docs/ROUTES.md`](../../docs/ROUTES.md) do.
5. **Assuming the real third-party evidence is in the repository** — the real one (the HandyControl sample) is **outside**; the in-repo criterion is `samples/ThirdPartyMini`.

---

## 5. Where next

- Build details → [building.md](building.md)
- Samples / seeing a window → [running-samples.md](running-samples.md)
- Architecture and data flow → [../design/architecture.md](../design/architecture.md)
- Start changing code → [../design/contributing.md](../design/contributing.md) plus the spec [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md)
- Current state → [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) / handover [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md)

---

**English** | [中文](getting-started.zh-CN.md) | [Español](getting-started.es.md) · [port-side docs bus](../README.md) · [building](building.md) · [running samples](running-samples.md)
