# 贡献（contributing）

[English](contributing.md) | **中文** | [Español](contributing.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> **规范本体**是 [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md)（中文单语），本页只是入口与"最容易踩的三件事"。

---

## 1. 开工前必读（按顺序）

1. [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) —— 判据纪律／取证纪律／写域纪律／缺陷登记／发波链／并行约定／推翻流程。
2. [`docs/ROUTES.md`](../../docs/ROUTES.md) —— 10 条路线（`R1…R10`）的现状与写域；**§11「怎么认领一条路线」照抄那段即可开工**。
3. [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) —— 现在到哪了（机器行 `:9` = 冻结基线）。
4. [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) —— 新会话先读这个（纪律 ＋ 重建存活态的命令）。

## 2. 认领一条路线（四步）

1. **写预登记**：在你的车道报告开头（或 `docs/WAVE<NN>-PREREGISTRATION.md`）写"路线号 ＋ 目标 ＋ 判据（含反极性）＋ 写域 ＋ 预期位移"。
2. **建私有装置**：私有应用目录（`bash build/MilBridge/tools/sync-applocal.sh <dir>`）＋ 私有 X display（**有 WM / 无 WM 各一条腿** —— 本工程有整类缺陷只在有 WM 的会话里出现）。
3. **取修前读数**（"成对"的一半），再动手；动手后取另一半。
4. **写报告**：`build/MilBridge/<车道号>-report.md` —— 自报 sha16、开工/收工件 sha16、读数表、复算命令、边界与 `NOINFO`，以及**你推翻了哪句话**。

## 3. 最容易踩的三件事

1. **改错地方**：`build/*.Linux/*.csproj` 与 `build/*.Linux/*.Linux.cs` 里有一部分是**生成物**，会被 `port-lib.py`／应用器**整体重写**。
   ⇒ **接线写应用器**（`src/WpfGfx.Linux.Native/tools/patch-*.py`，幂等 + `--check`）；改的是 port-lib 的输入时，用**预应用器**（`tools/wire-*.py`）。
2. **没认领就发波**：`WAVE_OWNER` 缺失 ⇒ `integration-wave.sh` **直接退出**。这是结构约束，不是礼貌 —— 无人认领的重建会让所有并行车道的"当前件读数"集体作废。
3. **把 `NOINFO` 当绿**：三态纪律，取不到就说取不到；**"没红" ≠ "验过"**。同理：判据件本身也要被看着（覆盖面、反极性、引号陷阱……）。

## 4. 改动面与对应判据（速查）

| 你改了什么 | 至少跑什么 |
|---|---|
| `build/shims/**`、`src/**`、应用器 | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh`（会重放应用器并做应用器审计） |
| 只改文档 / 判据件 | 相关牙 ＋ `bash verify-all.sh` 的对应步（至少 `verify-all-step-check.sh`、`baseline-sha-check.sh`、`defect-registry-check.sh`） |
| 动了九个权威产物 | 走 [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md) §5 的**整波链**重冻（基线机器行只许一处声明：`docs/CURRENT-STATE.md:9`） |
| 新增/删除**根级条目** | 同趟改 `build/MilBridge/tools/root-entries-allowlist-check.sh` 的内嵌 `ALLOWLIST`（`<名>\t<why>`，`why` 不许空），并跑：`bash build/MilBridge/tools/root-entries-allowlist-check.sh` ＋ `--selftest` |
| 新增**文档页** | 三语同名三件（`.md`／`.zh-CN.md`／`.es.md`）＋ 顶部语言切换行；命令必须真能跑；口径不许写死旧数 |

## 5. 文档与命名纪律（本仓特有）

- **成对命名**：`X` = 原始 / Windows 侧，`X.Linux` = 移植 / Linux 侧（冻结件 [`_PHASE0-NAMING-CONVENTION.md`](_PHASE0-NAMING-CONVENTION.md)）。
- **文档两根**：`docs/`（原始 / Windows 侧）＋ `docs.Linux/`（移植 / Linux 侧）；**不另建** `Documentation/`。
- **中文是权威原文**，英 / 西是译文（可精简，但导航链接与命令不许缺）。
- **被冻结机器读取的件不许搬**（`docs/WAVE*-PREREGISTRATION.md`、`docs/ROUTES.md`、`docs/CURRENT-STATE.md`、`handoff.md`…）——
  依据 `docs/INDEX.md §4`；读者清点见 [`../evidence/_PHASE0-READERS-INVENTORY.md`](../evidence/_PHASE0-READERS-INVENTORY.md)。
- **历史证据 vs 现状**：证据件只讲"当时"，现状一律以 [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) 为准（见 [`../evidence/README.zh-CN.md`](../evidence/README.zh-CN.md)）。

## 6. 提交与许可

- 上游 `upstream/wpf/**` 是 **MIT**（`upstream/wpf/LICENSE.TXT`）；上游源**只读**，改它等于打穿"字节可复算"。
- 本仓新增部分随本仓许可发布；`build/keys/WcpPublicKey.snk` 是**公钥**，不含私钥，可入库。
- 发布前清单见 [`docs/RELEASE-READINESS.md`](../../docs/RELEASE-READINESS.md)。

---

[English](contributing.md) | **中文** | [Español](contributing.es.md) · [移植侧文档总线](../README.zh-CN.md) · [架构](architecture.zh-CN.md) · [命名约定](_PHASE0-NAMING-CONVENTION.md)
