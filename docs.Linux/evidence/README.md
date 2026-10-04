# Evidence index (docs.Linux/evidence)

**English** | [中文](README.zh-CN.md) | [Español](README.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md).

> ⚠️ **This area is historical evidence; do not read it as current state.**
> It records what was done **at the time** and what the readings were.
> **Current state follows** [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) (machine line `:9` = the frozen baseline) and [`docs/ROUTES.md`](../../docs/ROUTES.md) (authoritative roadmap).

---

## 1. The ruling: an "index compromise" — the physical files stay where they are

The phase-0 reader inventory walked all **84 candidate files** and concluded with an **index compromise**: nothing in this area is moved; what is added is navigation and a banner.

**Where the reasoning lives**: [`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) §4, summarised:

- **Six high-risk files cost far more to move than they are worth**: `handoff.md` (it is also the **repository-root sentinel** for ~18 tests/tools — moving it out of the root breaks their root resolution), `docs/CURRENT-STATE.md` (read by **four gate steps**), `docs/ROUTES.md` / `docs/unimplemented.md` (read by `pts-gap-count-check.sh` as **current-value anchors**), `docs/PORT-SPEC.md` / `docs/INDEX.md` (read as sha16 by the twin-file table).
- **63 medium-risk files** (`docs/WAVE*-PREREGISTRATION.md`) are read by four **whole-glob** sites; moving them would invalidate every verbatim `docs/WAVE…md:NN` line anchor in the historical reports. `docs/INDEX.md §4` states plainly that this repository "**deliberately does not do big moves**".
- **17 low-risk files** have no machine reader, but they are few and scattered; leaving them costs the gates nothing.
- **Why the compromise is safe**: no read file is touched, so all four `[G4]` sites, the `handoff` sentinel, the four baseline steps, the pts anchors and the twin-file comparison stay green.

> If a future ruling does decide to move them: first clear every machine reader, then do it as **one whole wave** with the "anti-misreading" touches (banner on each file, prose sections folded, **no renames**), re-running `verify-all.sh` twice at `64 ✅ / 0 ❌`.

---

## 2. Navigation: where things are (all **in place**)

| Looking for | Go to |
|---|---|
| **A wave's pre-registration** | `docs/WAVE<NN>-PREREGISTRATION.md` (currently **63** files matching the glob; **67** top-level `WAVE*.md`) |
| **The wave-by-wave technical ledger** | the repository root [`handoff.md`](../../handoff.md) |
| **The authoritative state machine / roadmap** | [`docs/ROUTES.md`](../../docs/ROUTES.md) |
| **Lane reports** | `build/MilBridge/<lane>-report.md` (**do not move or delete** — `repin-generation.py --check` reads some of them) |
| **Isolated historical documents** | [`docs/history/`](../../docs/history/) (4 files) |
| **Acceptance screenshots** | [`docs/m7c-accept.png`](../../docs/m7c-accept.png), [`docs/m7c-accept-zero-probe.png`](../../docs/m7c-accept-zero-probe.png) |
| **Registered reds** | [`build/MilBridge/known-red.json`](../../build/MilBridge/known-red.json) plus the declaration table |
| **The handover file (read first in a new session)** | [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) |
| **The pre-rewrite root README's dated corrections (verbatim)** | [`README-dated-archive.md`](README-dated-archive.md) |

## 3. Artefacts of phases 0 and 1 already here

- [`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) — the reader inventory (84 rows; the **input to phase 2**).
- [`README-dated-archive.md`](README-dated-archive.md) — the dated corrections of the root `README.md` **before** the rewrite (`T-A33`…`T-B24`), archived verbatim, plus the full pre-rewrite text.

## 4. Three rules for citing evidence

1. **State the caliber and the source**: which generation, which file, which command, what time — a citation you cannot recompute is not a citation.
2. **Dated entries are append-only**: to correct something, append a `⏪ dated` line; **do not edit the original** — that is the whole point of this area.
3. **`NOINFO` stays `NOINFO`**: if the evidence says "could not be computed", do not paraphrase it into "passed".

---

**English** | [中文](README.zh-CN.md) | [Español](README.es.md) · [port-side docs bus](../README.md) · [reader inventory](_PHASE0-READERS-INVENTORY.md) · [dated archive](README-dated-archive.md)
