# The Linux overlay — the other half, written beside upstream

**English** | [中文](linux-overlay.zh-CN.md) | [Español](linux-overlay.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md). The project-by-project table is [`layout.md`](layout.md).

**In one line**: the upstream `dotnet/wpf` tree exists in this repository in **two places** — `upstream/wpf/**` (the **read-only source**, the build input) and the **overlay** (what this fork adds). The overlay is not "editing upstream"; it is **sitting beside it**: upstream source is left untouched, and added files live in `src/**`, `build/shims/**`, `build/*.Linux/**` and the appliers.

---

## 1. The four blocks of the overlay

1. **Managed port code** — `src/WpfGfx.Linux/**`
   `WpfGfx.Linux.csproj` (a leaf project, first in the rebuild order) plus seven directories:
   `Commands/` (MIL command decoding/dispatch/layout), `Contracts/` (`MilCmd`, `MilDrawCommand`, `MilPrimitives`…),
   `Interop/` (`Duce`, `HResult`, `MilEnums`), `Rendering/` (draw-instruction census, glyph-run census, path geometry parser),
   `Resources/` (`MilChannel`, `MilResourceTable`, `MilVisualNode`), `Text/` (`GlyphRunLayout`, `GlyphRunPainter`, font sets),
   `Windowing/` (`X11Display`, `X11PresentationTarget`, `WindowEvent`, `X11Native`).
2. **Native shims (C) and appliers** — `src/WpfGfx.Linux.Native/**`
   `src/win32_*.c` (`win32_core`, `win32_msg`, `win32_x11`, `win32_gdiplus`, `win32_oem`, `win32_pts`, `win32_exports`, `win32_unicode_tables`, `win32_classification`),
   `include/`, `build-shim.sh` (builds `libwpfwin32.so` and emits `exports.txt`),
   `tools/patch-*.py` (the **appliers**: they patch wiring into generated files, idempotently, with `--check` and anchor-count assertions) and `tools/wire-*.py` (pre-appliers).
3. **Per-project shims and generated files** — `build/shims/**` (the `*.Shim.cs` files plus one `<Project>.shims.txt` list each; turning that list into csproj items is `port-lib.py`'s job),
   `build/<Project>.Linux/*.Linux.cs` (the Linux override implementations, e.g. `HwndSource.Linux.cs`, `FlowDocumentView.Linux.cs`, `Dispatcher.Linux.cs`),
   `build/<Project>.Linux/ARTIFACT-SRC-FP.txt` and `PORT-CHANGES.md`.
4. **Build-side facilities** — `build/port-lib.py` (**rewrites** the csproj wholesale), `build/integration-wave.sh` (the single port+build entry point),
   `build/excludes/*.txt` (measured exclusion lists), `build/*.props` (`Directory.Upstream.props` cuts Arcade inheritance; `SelfBuiltConfig.props` is the single Release declaration),
   `build/DirectWrite.Linux/**` (the DirectWrite/WIC bridge, `wic-shim/`, `Provider/` and probes), `build/third-party/**` (third-party recipe `WpfLinux.props`), `build/MilBridge/**` (the AOT milcore bridge, the five arms, the gates and the freeze tooling).

## 2. The three native artefacts: a replacement implementation

- `libwpfwin32.so` — the Win32 / message / GDI / OEM / GDI+ surface shim (**caliber**: do for real whatever can be done for real; otherwise **fail honestly**, never pretend).
- `libwpfwic.so` — the WIC → Skia decoding bridge (source under `build/DirectWrite.Linux/wic-shim/`, including `wic_proxy.c` and the probes).
- `wpfgfx_cor3.so` — the **AOT milcore** renderer (upstream's counterpart is the VC++ implementation under `WpfGfx/`).

None of the three is in git (`src/WpfGfx.Linux.Native/bin/` is ignored), so a clean clone **must rebuild** them:
`bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build`.

## 3. Three hard lines the overlay must not cross

- **Never edit upstream source**: `upstream/wpf/**` is read-only; editing it invalidates the "upstream bytes are re-computable" evidence.
- **Never hand-edit generated files**: `build/*.Linux/*.csproj` is produced by `port-lib.py`; hand edits are erased on the next regeneration **without an error**, so wiring belongs in the **appliers**.
- **Never degrade silently**: whatever cannot be done must be **named** (an error code, a read-only ledger) — that is the caliber the defect register and the gates use.

## 4. Naming, and where "aligning with upstream" stands

- **Naming rule** (frozen: [`../design/_PHASE0-NAMING-CONVENTION.md`](../design/_PHASE0-NAMING-CONVENTION.md)):
  everything comes in pairs — `X` (original / Windows side) and `X.Linux` (Linux side); docs `docs` / `docs.Linux`,
  source (target shape) `src/Microsoft.DotNet.Wpf` / `src/Microsoft.DotNet.Wpf.Linux`, scripts `Guide` / `Guide.Linux`.
  One directory suffix picks the platform; nobody has to inspect files level by level.
- **The chosen route is "A + C"**: A = document the **mapping layer** first (this page and [`layout.md`](layout.md) are A's output),
  C = later move the Windows source into `src/Microsoft.DotNet.Wpf/**` (for compiling) while `upstream/wpf/**` stays as the byte-verification copy or becomes a per-file manifest.
  The staged plan is [`docs/UPSTREAM-ALIGN-PLAN.md`](../../docs/UPSTREAM-ALIGN-PLAN.md) (a **proposal**; this page does not declare it done).
- ⚠️ **Do not read "mapped" as "moved"**: physically the layout today is still "`upstream/wpf/**` read-only source + generated projects under `build/*.Linux/**`", and `src/` holds **only** the port's additions (`WpfGfx.Linux`, `WpfGfx.Linux.Native`).

---

**English** | [中文](linux-overlay.zh-CN.md) | [Español](linux-overlay.es.md) · [port-side docs bus](../README.md) · [upstream layout](layout.md)
