# Building

**English** | [中文](building.zh-CN.md) | [Español](building.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md). This page covers "how to compile it"; to run it see [running-samples.md](running-samples.md), and for per-project landings see [`../upstream/layout.md`](../upstream/layout.md).

**One command** (the single entry point):

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh
```

`WAVE_OWNER` is a **structural constraint**, not a courtesy: without it the script **exits**; every run appends a traceable record (time / pid / ppid / tty / command line / owner) to `build/wave-audit.log`.

---

## 1. Dependencies and environment

```bash
sudo apt-get install -y gcc libc6-dev libx11-dev zlib1g-dev clang                       # native shims + AOT
sudo apt-get install -y xvfb x11-apps x11-utils imagemagick fontconfig libfontconfig1   # acceptance + samples
dotnet --version                                                                        # global.json pins 10.0.111
bash build/setup-env.sh && bash build/verify-env.sh                                     # set up, then self-check
```

## 2. The build model is **generative** (the pitfall to know first)

```
upstream/wpf/** (read-only upstream source; the only build input)
      │  build/port-lib.py : drops Windows-only source, pulls in generated *.Linux.cs, **rewrites** the csproj wholesale
      ▼
build/<Project>.Linux/<Project>.Linux.csproj  ──dotnet build──▶  six managed assemblies
      │  applier replay (src/WpfGfx.Linux.Native/tools/patch-*.py: patch-style wiring, idempotent, --check, anchor assertions)
      ▼
three native artefacts: libwpfwin32.so / libwpfwic.so / wpfgfx_cor3.so
```

- ⚠️ **Hand edits to `build/*.Linux/*.csproj` are erased by the next `port-lib.py` run, without an error** ⇒ wiring belongs in the **appliers**.
- ⚠️ **Pre-appliers change port-lib's input** (e.g. `wire-uiautomation-resolver` writes `build/shims/*.shims.txt`, and "list → csproj" is port-lib's job) ⇒ the order must be "pre-appliers → targeted port-lib → remaining appliers → build".
- **Hand-written projects** (never regenerated): `DirectWriteForwarder.Linux`, `System.Printing.Linux`, `System.Windows.Extensions.Linux`, `CycleStub.*`, `build/DirectWrite.Linux/Provider/`, `src/WpfGfx.Linux/`.

## 3. The nine stages of `integration-wave.sh`

| Stage | What it does |
|---|---|
| `1/4` | regenerate the eight projects' csproj with the current `port-lib.py` (unified signing + resource pipeline + identity files) |
| `2/4` | replay every project applier (idempotent; a missed replay is dropped silently, so all are replayed) |
| `2.5/5` | **applier audit**: registered but not effective ⇒ red |
| `3/4` | rebuild in dependency order (one project at a time, `-m:1`; see `ORDER` in the script) |
| `3.5/5` | app-local copy refresh (authoritative build → lagging load-source copies) |
| `3.6/5` | artefact identity fingerprints (source identity of PC / WindowsBase / PF) |
| `3.7/5` | criterion self-check (the app-local verifier's `--selftest`) |
| `4/4` | identity self-check (each self-built assembly: exact file by project name + public key present) |
| `5/5` | input stability (were any hand-written inputs changed during the wave) |

## 4. Configuration: exactly one declaration

- Authoritative configuration = **`Release`**; the only declaration is `build/SelfBuiltConfig.props`, the only shell reader is `build/selfbuilt-config.sh`.
- Self-check: `bash build/selfbuilt-config.sh --check`. Changing a consumer while missing the declaration is what the gates bite on.

## 5. The three native artefacts (each rebuilt separately)

```bash
bash src/WpfGfx.Linux.Native/build-shim.sh                    # libwpfwin32.so (+ exports.txt)
bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh       # libwpfwic.so
bash build/MilBridge/run.sh build                             # wpfgfx_cor3.so (AOT milcore)
```

⚠️ None of them is in git (`src/WpfGfx.Linux.Native/bin/` is ignored) ⇒ a clean clone cannot fetch them and **must rebuild**.

## 6. Acceptance (the gate itself)

```bash
bash verify-all.sh          # 64 steps; uses :99 by itself
```

- **Step-count caliber**: always quote the **current** `VERIFYALL-STEPS-DECL` — currently **`64 gen=#82`** (never hard-code an old figure: it moved 55 → 58 → 61 → 62 → 64).
- The gate covers build, tests, the **five arms**, the application gate and the frozen baseline, plus a pile of "instruments for the instruments" (quote traps, `pipefail`/SIGPIPE census, coverage self-checks…).
- Individual jaws you can run on their own:

```bash
bash build/MilBridge/tools/verify-all-step-check.sh         # step names / count / caliber prose, three-way
bash build/MilBridge/tools/baseline-sha-check.sh            # the frozen-baseline machine line
bash build/MilBridge/tools/defect-registry-check.sh         # defect register (DEFREG)
bash build/MilBridge/tools/root-entries-allowlist-check.sh  # root entries ⊆ allow-list
bash build/MilBridge/tools/pts-gap-count-check.sh           # current PTS gap values
```

## 7. When it fails, look here first

- The last line of `build/wave-audit.log`: who started this run and when (`owner=` / `ppid_cmd=`).
- `build/<Project>.Linux/PORT-CHANGES.md`: item by item, what the port changed.
- `build/MilBridge/<lane>-report.md`: past readings and treatments of the same class of problem.
- Three-state discipline: **not computable ≠ pass** (`NOINFO` needs a human).

---

**English** | [中文](building.zh-CN.md) | [Español](building.es.md) · [port-side docs bus](../README.md) · [getting started](getting-started.md) · [running samples](running-samples.md)
