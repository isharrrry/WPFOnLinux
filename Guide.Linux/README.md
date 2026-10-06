# Guide.Linux —— **一键入口清单**（O6：入口边界厘清，**只做清单、不做搬迁**）

> 派单 `TASK-O1-O4-O6` §O6。裁决：**不搬路径**（搬迁成本 ≫ 收益：被引面 `verify-all.sh` 现取
> **591** 件、`close-wave.sh` **501** 件、`integration-wave.sh` **181** 件，且多颗牙真调用它们）。
> 本件把三个入口的用途／典型调用／前置条件／判据列成**唯一清单**，其余入口一律**指回本件**。

本目录（`Guide.Linux/`）**只有 `verify-all.sh` 一个文件**＋本清单。另两个入口仍在原落点
（`src/Linux/build/`）—— 本波**不搬**。

---

## 1. 三个入口（唯一权威清单）

| # | 入口（现落点） | 用途 | 典型调用 | 前置条件 | 判据（读哪里） |
|---|---|---|---|---|---|
| ① | `Guide.Linux/verify-all.sh` | **一键验收**：Xvfb → 构建 → 6 个测试套件 → 命令线格 → 在册红门禁（五臂）→ PC 侧行对拍 → 帧列 | `bash Guide.Linux/verify-all.sh` | `Xvfb`／`dotnet` 可用；无需 `WAVE_OWNER` | 末段 `步骤通过 N ❌ 失败 0` ＋ `结论：✅ 全部通过` ＋ `EXIT=0`；步数引**现行** `VERIFYALL-STEPS-DECL`（现读 `67 gen=#85`） |
| ② | `src/Linux/build/integration-wave.sh` | **集成波**（重建 PC/PF/WB ＋ 应用器审计 ＋ 生成物指纹 ＋ 副本刷新 ＋ 身份 ＋ 输入稳定性） | `WAVE_OWNER=$(whoami) bash src/Linux/build/integration-wave.sh` | **必须**认领责任人（`WAVE_OWNER`；自 2026-09-14 起**拒绝无责任人的波**） | 该趟 `close-wave.log` 里 `[1/6]` 段 `rc=0`；`inputs_fp` 波前==波后 |
| ③ | `src/Linux/build/close-wave.sh` | **收官序列**（整趟波 = 一条命令）：`[1/6]` integration-wave → `[2/6]` native shim → `[3/6]` 桥 → `[4/6]` 身份自检 → `[5c/6]` 冻结期一致性 → `[6/6]` 汇总（哨兵） | `bash src/Linux/build/close-wave.sh`（`--native`／`--bridge` 强制、`--skip-verify-all` 快跑、`--dry-run`） | **没有**应用在跑、**没有**重发锁 | `rc=0`；汇总件 `close-wave-summary.txt`（八位＋第九位＋桥指纹）；`[5c/6]` 四档 `PASS` |

> ⚠️ 三条命令**逐条可跑**（① 直接；②③ 可先 `--dry-run` 试跑）。`bash` 之外的 shell 未验证。

## 2. 典型链路（波怎么走）

```
integration-wave.sh ──►（重建/审计/指纹/身份）      # ② 集成波
        │
        └── close-wave.sh ──► [1/6]…[6/6]            # ③ 收官（含调 ②、并在 [5/6] 调 ①）
                              └── [5/6] Guide.Linux/verify-all.sh   # ① 全量门禁
```

- 收一波的**规范顺序**：**先把提交做完 → 再 `close-wave` 冻结 → 最后 `verify-all ×2`**（冻后不再新增提交）。
- `close-wave.sh` 的 `[5/6]` 会**真的调用** `Guide.Linux/verify-all.sh`（除非 `--skip-verify-all`）。

## 3. 边界（如实划界）

- 本清单**不**新增/移动任何入口件，只**指路**。
- 被引面**现取**（本波）：`git grep -l <入口>` ⇒ `verify-all.sh` **591**／`close-wave.sh` **501**／`integration-wave.sh` **181** 件
  （派单记 588／497／175；§⑦「数一律现取」）。
- 真调用它们的牙（部分）：`sentinel-spec-check.sh`／`applier-audit.py`／`wiring-coverage-check.sh`／
  `timestamp-order-check.sh`／`wave-push.sh`／`static-jaws-check.sh`／`fp-inputs-hygiene-check.sh`／
  `handoff-machine-values-check.sh` 等。
- 具名登记（证据）：`docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md` §「O6」。
