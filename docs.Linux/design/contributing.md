# Contributing

**English** | [中文](contributing.zh-CN.md) | [Español](contributing.es.md)

> Part of **docs.Linux** — back to the [port-side docs bus](../README.md).
> The **spec itself** is [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md); this page is the entry point plus the three easiest mistakes.

---

## 1. Read first, in this order

1. [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) — criterion discipline, evidence discipline, write domains, defect registration, the wave chain, parallel work, the overturn procedure.
2. [`docs/ROUTES.md`](../../docs/ROUTES.md) — the ten routes (`R1…R10`) with their current state and write domains; **§11 "how to claim a route" can be copied verbatim to start**.
3. [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) — where we are (machine line `:9` = the frozen baseline).
4. [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) — read this first in a new session.

## 2. Claiming a route (four steps)

1. **Write the pre-registration**: at the top of your lane report (or in `docs/WAVE<NN>-PREREGISTRATION.md`) write "route + goal + criteria (including the anti-polarity leg) + write domain + expected drift".
2. **Build a private rig**: a private app directory (`bash build/MilBridge/tools/sync-applocal.sh <dir>`) and a private X display — **one leg with a WM and one without**: this project has whole classes of defects that appear only in a WM session.
3. **Take the before reading** (half of the pair) before touching anything, then the after reading.
4. **Write the report**: `build/MilBridge/<lane>-report.md` — self-reported sha16, before/after sha16, a reading table, the recompute commands, boundaries and `NOINFO`, and **which statement you overturned**.

## 3. The three easiest mistakes

1. **Editing the wrong place**: some files under `build/*.Linux/*.csproj` and `build/*.Linux/*.Linux.cs` are **generated** and get rewritten wholesale by `port-lib.py` and the appliers.
   ⇒ **Wiring goes in the appliers** (`src/WpfGfx.Linux.Native/tools/patch-*.py`, idempotent, `--check`); when you are changing port-lib's *input*, use a **pre-applier** (`tools/wire-*.py`).
2. **Starting a wave without claiming it**: without `WAVE_OWNER`, `integration-wave.sh` **exits**. That is a structural constraint, and unclaimed rebuilds invalidate every parallel lane's "current artefact" readings.
3. **Treating `NOINFO` as green**: three-state discipline — if it cannot be computed, say so. Likewise, the criteria are themselves watched (coverage, anti-polarity legs, quote traps…).

## 4. What to run for what you changed

| You changed | At least run |
|---|---|
| `build/shims/**`, `src/**`, appliers | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` (it replays appliers and audits them) |
| Docs / criteria only | the relevant jaws plus the matching `verify-all.sh` steps (at minimum `verify-all-step-check.sh`, `baseline-sha-check.sh`, `defect-registry-check.sh`) |
| Any of the nine authoritative artefacts | the full wave chain in [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) §5 (the baseline is declared in exactly one place: `docs/CURRENT-STATE.md:9`) |
| A **root entry** added/removed | update the embedded `ALLOWLIST` in `build/MilBridge/tools/root-entries-allowlist-check.sh` in the same pass (`<name>\t<why>`, `why` non-empty), then run it plus `--selftest` |
| A **documentation page** | three same-named files (`.md` / `.zh-CN.md` / `.es.md`) with a top language switch line; commands must really run; never hard-code stale figures |

## 5. Documentation and naming discipline

- **Paired naming**: `X` = original / Windows side, `X.Linux` = port / Linux side (frozen: [`_PHASE0-NAMING-CONVENTION.md`](_PHASE0-NAMING-CONVENTION.md)).
- **Two documentation roots**: `docs/` and `docs.Linux/`; **no** separate `Documentation/`.
- **Chinese is the authoritative original**; English and Spanish are translations (condensed is fine, missing links/commands is not).
- **Files read by frozen machines must not move** (`docs/WAVE*-PREREGISTRATION.md`, `docs/ROUTES.md`, `docs/CURRENT-STATE.md`, `handoff.md`…) — per `docs/INDEX.md §4`; the reader inventory is [`../evidence/_PHASE0-READERS-INVENTORY.md`](../evidence/_PHASE0-READERS-INVENTORY.md).
- **Evidence vs current state**: evidence files speak only about "then"; current state always follows [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) — see [`../evidence/README.md`](../evidence/README.md).

## 6. Commits and licence

- Upstream `upstream/wpf/**` is **MIT** (`upstream/wpf/LICENSE.TXT`) and **read-only**: editing it breaks the "bytes are re-computable" evidence.
- Everything added here is released under this repository's licence; `build/keys/WcpPublicKey.snk` is a **public** key and safe to commit.
- Pre-release checklist: [`docs/RELEASE-READINESS.md`](../../docs/RELEASE-READINESS.md).

---

**English** | [中文](contributing.zh-CN.md) | [Español](contributing.es.md) · [port-side docs bus](../README.md) · [architecture](architecture.md) · [naming convention](_PHASE0-NAMING-CONVENTION.md)
