# Architecture

**English** | [中文](architecture.zh-CN.md) | [Español](architecture.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md).
> Per-project landings: [`../upstream/layout.md`](../upstream/layout.md); what the overlay is: [`../upstream/linux-overlay.md`](../upstream/linux-overlay.md).
> The deep version (why replacement rather than forking, DPI/fonts/resource pipeline/theme stack) is [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md).

---

## 1. Thirty seconds

```
upstream/wpf/**                 read-only upstream source (never edited; the only build input)
      │  build/port-lib.py      (drops Windows-only source, pulls in generated *.Linux.cs, **rewrites** the csproj)
      ▼
build/<Project>.Linux/*.csproj  ──build──▶  six managed assemblies
      │  applier replay (src/WpfGfx.Linux.Native/tools/patch-*.py: patch-style, idempotent, --check, anchor assertions)
      ▼
three native artefacts: libwpfwin32.so (Win32/GDI/OEM/GDI+; do it for real or **fail honestly**)
                        libwpfwic.so   (WIC → Skia decoding bridge)
                        wpfgfx_cor3.so (the AOT milcore renderer)
```

## 2. The four layers

| Layer | What it is | Where |
|---|---|---|
| **① Port generation** | turn upstream csproj into Linux-buildable csproj (cut Arcade inheritance, expand `$(Wpf*Dir)`, exclusion lists, resource pipeline, signing/identity) | `build/port-lib.py`, `build/port-pbt.sh`, `build/excludes/*.txt`, `build/Directory.Upstream.props` |
| **② Managed port surface** | the six self-built assemblies (`pc` / `pf` / `windowsbase` / `system.xaml` / `dwf` / `provider`) plus per-project `*.Linux.cs` override implementations | `build/<Project>.Linux/**`, `build/shims/**`, `src/WpfGfx.Linux/**` |
| **③ Native shims (C)** | Win32 / message / GDI / OEM / GDI+ surfaces, the WIC bridge and the AOT milcore | `src/WpfGfx.Linux.Native/src/**`, `build/DirectWrite.Linux/**`, `build/MilBridge/**` |
| **④ Criteria and gates** | `verify-all.sh`'s 64 steps plus 107 jaws, the five arms, the frozen baseline and the defect register | `verify-all.sh`, `build/MilBridge/tools/**`, `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`, `build/MilBridge/known-red.json` |

## 3. Data flow (one render)

1. Application (XAML) → `PresentationFramework` → `PresentationCore` → a **MIL command stream**.
2. The stream enters `wpfgfx_cor3.so` (AOT milcore): `src/WpfGfx.Linux/Commands/**` decodes and dispatches it, `Resources/` holds resources and the visual tree.
3. Draw instructions reach Skia through `Rendering/`; glyphs are handled by `src/WpfGfx.Linux/Text/**` plus `build/shims/PresentationCore.HbTextLine.cs` (HarfBuzz text lines).
4. Windows/messages/input go through `src/WpfGfx.Linux.Native/src/win32_{core,msg,x11}.c` ↔ `src/WpfGfx.Linux/Windowing/**` (the X11 presentation target).
5. X11 presents it; on the acceptance side `verify-all.sh` and the sample runners really open a window, really screenshot and really count colours.

## 4. Authoritative artefacts and watched criteria

- **The nine artefacts**: the sha16 of nine authoritative binaries, recorded bit by bit in the freeze block; they are **not** in git, so a clean clone must rebuild them.
- **The frozen baseline**: `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` is the only authority; its whole-file sha is declared **only** by the machine line `docs/CURRENT-STATE.md:9` (currently `gen=#82`).
- **The five arms**: `tline` / `tab-*` / `textlineproto`, compared line by line against Windows truth values.
- **Known red**: `build/MilBridge/known-red.json` plus the declaration table; a red must be **registered**.
- **Instruments for the instruments**: the gate includes quote traps, a `pipefail`/SIGPIPE census, coverage self-checks and the root-entry allow-list — the criteria are themselves watched.

## 5. Design choices, one line each

- **Replacement, not forking**: the native Windows stack (`WpfGfx` and friends) is swapped wholesale for a Linux implementation rather than conditioned at source level, so the upstream tree stays clean and diffable.
- **Rewrite, not in-place edits**: the csproj is a **generated artefact** and wiring goes through appliers, so "changed but not effective" incidents get caught by the audit.
- **Beside, not mixed in**: the Linux surface lives in `src/**`, `build/shims/**`, `build/*.Linux/**`, upstream stays in `upstream/wpf/**` — a directory suffix picks the platform.
- **Do for real what can be done for real; fail honestly otherwise** — never trade a lie for a green screen.

---

**English** | [中文](architecture.zh-CN.md) | [Español](architecture.es.md) · [port-side docs bus](../README.md) · [Linux overlay](../upstream/linux-overlay.md) · [contributing](contributing.md)
