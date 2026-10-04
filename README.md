# WPF on Linux — port `dotnet/wpf` so it builds and renders natively on Linux

**English** | [中文](README.zh-CN.md) | [Español](README.es.md)

**Windows / original** | [**Linux / port**](docs.Linux/README.md)

**What it is.** This repository makes a WPF application **compile from source on Linux, open a window, actually draw, and respond to mouse and keyboard**.
**Boundary (stated plainly):** compatibility with WPF binaries **built on Windows** is explicitly **out of scope** — that boundary removes the whole binary-compatibility route.
The upstream snapshot lives in `upstream/wpf/` (a read-only copy of `dotnet/wpf`, MIT); the upstream README is kept byte-for-byte as [`README-Window.md`](README-Window.md).

---

## 1. What works today (readings; each one is re-computable)

| Capability | Current reading | Re-run with |
|---|---|---|
| **Build** the managed WPF layer | six assemblies (`PresentationCore` / `PresentationFramework` / `WindowsBase` / `System.Xaml` / `DirectWriteForwarder` / `DirectWrite.Linux.Provider`) at **0 error** (Release) | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **Native side** | `libwpfwin32.so` (Win32/GDI/OEM/GDI+), `libwpfwic.so` (WIC → Skia decoding), `wpfgfx_cor3.so` (AOT milcore renderer) | `bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build` |
| **Open a window and render** (in-repo sample) | `samples/WpfTextDemo`: `14/14` frames non-empty, `未画种类 0` | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **Third-party shape** (in-repo criterion) | `samples/ThirdPartyMini`: wired only through `build/third-party/WpfLinux.props`, outside the solution, artefacts copied out of the tree before running | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25` |
| **One-command acceptance** | `verify-all.sh`: **64 steps** (current `64 ✅ / 0 ❌`, `rc=0`) | `bash verify-all.sh` |
| **Frozen baseline** | `docs/CURRENT-STATE.md:9` = `gen=#82` / `sha16=05c5e521c3b14ace` / `1,248,947 B` | `bash build/MilBridge/tools/baseline-sha-check.sh` |
| **Registered defects** | `DEFREG=PASS declared=225` | `bash build/MilBridge/tools/defect-registry-check.sh` |
| **PTS / native LineServices** | 🟡 **long-run item (not a blocker)**: reading **可操作 42／实现口径 42**; every remaining entry is named and has been proven a legitimate end point | `bash src/Linux/build/MilBridge/tools/pts-gap-count-check.sh` |

**"Re-computable" is a hard requirement here**: every conclusion has a command that recomputes it, and the criterion files are themselves watched (a good part of the 64 steps are instruments for the instruments).

---

## 2. Three commands (build → window → acceptance)

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # 1. port + build (claimed)
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # 2. window + render
bash verify-all.sh                                                                   # 3. acceptance (64 steps)
```

> ⚠️ `WAVE_OWNER` is a **structural constraint**, not a courtesy: without it `integration-wave.sh` exits.
> Hand edits to `build/*.Linux/*.csproj` are erased by the next `port-lib.py` regeneration — wiring belongs in the **appliers** (`src/WpfGfx.Linux.Native/tools/patch-*.py`).
> Environment setup (dependencies, `setup-env.sh`, `verify-env.sh`) is in [`docs.Linux/guide/building.md`](docs.Linux/guide/building.md);
> start with [`docs.Linux/guide/getting-started.md`](docs.Linux/guide/getting-started.md);
> run samples per [`docs.Linux/guide/running-samples.md`](docs.Linux/guide/running-samples.md).

---

## 3. Where to look (navigation)

| Entry point | What it is |
|---|---|
| [`README-Window.md`](README-Window.md) | the **upstream `dotnet/wpf` README**, kept verbatim (upstream identity and licence stay traceable) |
| [`docs/README.md`](docs/README.md) | **original / Windows-side** documentation bus (normative / current / evidence / history) |
| [`docs.Linux/README.md`](docs.Linux/README.md) | **port / Linux-side** documentation bus — topic × language table plus "I want to X → read Y" ([中文](docs.Linux/README.zh-CN.md) · [Español](docs.Linux/README.es.md)) |

The two roots are the rule: **`X` = original / Windows side**, **`X.Linux` = port / Linux side**
(the frozen convention is [`docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`](docs.Linux/design/_PHASE0-NAMING-CONVENTION.md)).

---

## 4. Known boundaries (honest list)

- The authoritative build configuration is **`Release`** (single declaration: `build/SelfBuiltConfig.props`; self-check `bash build/selfbuilt-config.sh --check`).
- The nine authoritative artefacts are **not** in git (`src/WpfGfx.Linux.Native/bin/` is ignored) — a clean clone cannot fetch them and **must rebuild** them.
- Windows-only features: degrade where a degradation exists (DWM = "there is a DWM, composition off"), otherwise **fail honestly** (return an error code instead of pretending).
- Real third-party evidence (the HandyControl sample) lives **outside** this repository: it is a product fact, but **not** an in-repo criterion; the in-repo criterion is `samples/ThirdPartyMini`.
- Details: [`docs/CURRENT-STATE.md`](docs/CURRENT-STATE.md) (**read this one first when taking over**), [`docs/ROUTES.md`](docs/ROUTES.md) (authoritative roadmap), [`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](samples/WpfFeatureProbe/KNOWN-DEFECTS.md) (defect register), [`build/MilBridge/HANDOFF-NEXT.md`](build/MilBridge/HANDOFF-NEXT.md) (handover).
- The pre-rewrite root `README.md` (including the wave-by-wave dated corrections `T-A33`…`T-B19`) is archived verbatim at [`docs.Linux/evidence/README-dated-archive.md`](docs.Linux/evidence/README-dated-archive.md).

---

## 5. Licence

- Upstream `upstream/wpf/**`: **MIT** (see `upstream/wpf/LICENSE.TXT`).
- `build/fonts/*.ttf`: **SIL OFL 1.1** (see `build/fonts/LICENSE-OFL.txt`).
- Everything added by this repository (`build/`, `src/WpfGfx.Linux*`, `samples/`, `tests/`, `docs/`, `docs.Linux/`, …) is released under this repository's licence.

---

[English](README.md) | [中文](README.zh-CN.md) | [Español](README.es.md) · [Linux / port docs bus](docs.Linux/README.md) · [Windows / original docs bus](docs/README.md)
