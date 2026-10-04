# docs.Linux — port / Linux-side documentation bus

**English** | [中文](README.zh-CN.md) | [Español](README.es.md)

**Windows / original** | **Linux / port** (this page)　·　[repository facade](../README.md) · [original / Windows-side documentation bus](../docs/README.md)

This directory is the **port / Linux side** of the paired roots: `docs/` (original / Windows side) plus `docs.Linux/` (here).
Two rules:

1. **Every page in three languages**: `.md` (default · English), `.zh-CN.md` (**authoritative original**), `.es.md` (translation). Each page carries a language switch line at the top; all three versions link to each other.
2. **Paired naming**: `X` = original / Windows side, `X.Linux` = port / Linux side
   (frozen convention: [`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md)).

> 📌 **This directory is not the authority on current state.** It holds the port-side getting-started / design / upstream-alignment chapters.
> For "where are we today" read [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) (frozen baseline, machine line at line 9) and [`docs/ROUTES.md`](../docs/ROUTES.md) (authoritative roadmap).
> Historical evidence (waves, lane reports, handover ledger) is indexed at [`evidence/README.md`](evidence/README.md) — **that area is historical evidence, do not read it as current state**.

---

## 1. Topic × language

| Topic | Language versions | What it covers |
|---|---|---|
| **Getting started** | [English](guide/getting-started.md) · [中文](guide/getting-started.zh-CN.md) · [Español](guide/getting-started.es.md) | What this repository is, whether you can run it right away, the minimal three steps, the vocabulary (`port-lib`, appliers, jaws, waves…), common pitfalls |
| **Building** | [English](guide/building.md) · [中文](guide/building.zh-CN.md) · [Español](guide/building.es.md) | Dependencies and `setup-env.sh` / `verify-env.sh`, the generative build model (`port-lib.py` **rewrites** the csproj wholesale), applier discipline, the four stages of `integration-wave.sh`, the single Release declaration |
| **Running samples** | [English](guide/running-samples.md) · [中文](guide/running-samples.zh-CN.md) · [Español](guide/running-samples.es.md) | `WpfTextDemo` (the gate sample), `ThirdPartyMini` (third-party shape), `HelloMil` / `HelloWpf` / `WpfFeatureProbe`, `Xvfb` and the two tiers, how to read the machine lines |
| **Architecture** | [English](design/architecture.md) · [中文](design/architecture.zh-CN.md) · [Español](design/architecture.es.md) | The four layers (port generator → six managed assemblies → native shims → AOT milcore), the data flow, the nine authoritative artefacts and the frozen baseline, instruments for the instruments |
| **Contributing** | [English](design/contributing.md) · [中文](design/contributing.zh-CN.md) · [Español](design/contributing.es.md) | Claiming a route, write domains, `WAVE_OWNER`, the wave chain, wiring belongs in appliers, the `NOINFO` discipline, the trilingual and naming rules |
| **Upstream layout** | [English](upstream/layout.md) · [中文](upstream/layout.zh-CN.md) · [Español](upstream/layout.es.md) | The upstream **21 project subtrees**, one row each: upstream path ↔ where it lands here ↔ Linux override/replacement |
| **Linux overlay** | [English](upstream/linux-overlay.md) · [中文](upstream/linux-overlay.zh-CN.md) · [Español](upstream/linux-overlay.es.md) | What the overlay is made of (`src/WpfGfx.Linux/**`, `src/WpfGfx.Linux.Native/**`, `build/shims/**`, the appliers) and how the three native artefacts line up with upstream |
| **Evidence index** | [English](evidence/README.md) · [中文](evidence/README.zh-CN.md) · [Español](evidence/README.es.md) | **Navigation**: where the wave pre-registrations, lane reports, `handoff`, `ROUTES` and `history` live, and why they **stay in place** |

> The two phase-0 artefacts (internal to this area, untranslated): [`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md) (frozen naming convention) and
> [`evidence/_PHASE0-READERS-INVENTORY.md`](evidence/_PHASE0-READERS-INVENTORY.md) (evidence-file reader inventory).

---

## 2. I want to X → read Y

| I want to… | Read |
|---|---|
| **get it running first** | [guide/getting-started.md](guide/getting-started.md) |
| **build from scratch** (what to install, which command) | [guide/building.md](guide/building.md) → then `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **see a window / run a sample** | [guide/running-samples.md](guide/running-samples.md) → then `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **run one-command acceptance (64 steps)** | `bash verify-all.sh` (caliber in [guide/building.md](guide/building.md)) |
| **understand how it all fits together** | [design/architecture.md](design/architecture.md) |
| **start changing code / claim a task** | [design/contributing.md](design/contributing.md) plus the spec [`docs/PORT-SPEC.md`](../docs/PORT-SPEC.md) |
| **find where an upstream project lands here** | [upstream/layout.md](upstream/layout.md) |
| **see what we changed or replaced upstream** | [upstream/linux-overlay.md](upstream/linux-overlay.md) |
| **look up historical evidence (what a given wave or lane did)** | [evidence/README.md](evidence/README.md) |
| **see the authoritative current state** | [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) (machine line `:9`) plus [`docs/ROUTES.md`](../docs/ROUTES.md) |
| **take over in a fresh session** | [`build/MilBridge/HANDOFF-NEXT.md`](../build/MilBridge/HANDOFF-NEXT.md) |
| **understand the naming (why `.Linux` everywhere)** | [design/_PHASE0-NAMING-CONVENTION.md](design/_PHASE0-NAMING-CONVENTION.md) |
| **read the upstream README** | [`README-Window.md`](../README-Window.md) |

---

## 3. Rules for writing in this area

- **Trilingual reachability**: a new page means three same-named files `.md` / `.zh-CN.md` / `.es.md`, each with a top language switch line; **navigation links and commands must be complete and correct**.
- **Chinese is the authoritative original**; English and Spanish are translations (a condensed form is fine, but **links and commands may not be missing**).
- **Facts must come from the tree**: commands must really run (`WAVE_OWNER=$(whoami) bash build/integration-wave.sh`, `bash verify-all.sh`); never hard-code stale figures (step counts always quote the **current** `verify-all.sh` `VERIFYALL-STEPS-DECL` — currently **64 gen=#82**).
- **This area is not the authority on current state**: every "what is true today" claim points at [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) / [`docs/ROUTES.md`](../docs/ROUTES.md).

---

**English** | [中文](README.zh-CN.md) | [Español](README.es.md) · [repository facade](../README.md) · [docs/ bus](../docs/README.md) · [evidence index](evidence/README.md)
