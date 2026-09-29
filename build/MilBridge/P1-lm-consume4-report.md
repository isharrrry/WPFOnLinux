# `t207` · `t206` 裁决 ＋ `t208` 复核的六处 dated 收窄（只增不改、删行数 0）

## §0 依赖解除的依据（写进本载体，照队长口径）

`t207` 原被 `t205`（**`failed`**／runner）挡住；队长把 `t207` 的 `dependencies` **置空**解除之，理由是：
**本件做的是既有载体/报告件的文件内 dated 追加，正文全部取自已完成并复核过的件**
（`t206` 裁决载体 `build/MilBridge/P1-lm-consume3-verify.md` 自证 `818df822191c0c31`；`t208` 复核载体 `build/MilBridge/P1-e3-replay-verify.md` 自证 `7f150f960eb6a591`），
**不需要 `t205` 任务对象本身"完成"**；`t205` 已被判**诚实失败的合法终点**（具名 `PRECOND-E3-REPLAY-FIXTURE-MISSING`），**不需要重做**，也不应由本席越域接手其 `src/**`。

## §1 逐件改前／改后（**删行数全 0**；写前 `cp -p` 备份 ＋ `temp+rename` ＋ 锚区间前置断言）

| 件 | 改前（现取） | 改后 | 组别 |
|---|---|---|---|
| `build/MilBridge/P1-lm-consume2-verify.md` | 110 行／`31dfda00ef739289` | **122 行／`32cb3dd8cbff8897`**（+12） | `A-1` |
| `build/MilBridge/P1-host-consume-route-criteria.md` | 234 行／`c7306d4327e47411` | **245 行／`25ace5ee4aa331fe`**（+11） | `A-2` |
| `build/MilBridge/P1-lm-consume2-report.md` | 142 行／`05bfd3b4f1080624` | **153 行／`e3aa7bbd425511d6`**（+11） | `A-2` |
| `build/MilBridge/P1-lm-consume-witness-criteria.md` | 204 行／`2e479e6b5e41fa1b` | **215 行／`955fe3525bf208c1`**（+11） | `A-2` |
| `build/MilBridge/P1-lm-consume3-report.md` | 133 行／`67da86e40e3e3ef1` | **146 行／`a89272e6e723f153`**（+13） | `A-3` |
| `build/MilBridge/P1-e3-replay-report.md` | 78 行／`bcb0b2abf998c030` | **105 行／`8bc3098c6c5fa0d9`**（+27） | `E-1..E-3` |

- 备份：`~/w281-scribe/t207/bak/<件名>.md.pre-t207`（写前 `cp -p`）；**逐件 `diff` 删行数 ＝ 0**；**六件末行自证均当场复算 MATCH**。
- **锚区间前置断言**：每件必须先满足 ① 行数/`sha16` ＝ 现取；② 该件被更正**原文锚**在场；③ 末行为自证行 ⇒ 否则 `exit 3` **不写**。
  ⚠️ **本轮两次拒写**：`P1-lm-consume3-report.md` 首轮因 A-3 块引用两处而该件 `求真值` **仅 1 处** ⇒ `SECOND-OCC-FAIL` / `LINEOF-FAIL` **零写入**；改夹具（仅 1 处时 `l2` 取该处 ＋ 单独重跑该件与 E 件）后才落盘。

## §2 六处写入内容（逐条）

- **`A-1`（`P1-lm-consume2-verify.md`）**：把写死的两句收窄 —— 「唯一填写者 ＝ `PtsHelper.cs:633`」与「`PtsHelper.cs:174-180` 不可达」
  **在 `subtrack-path`（`ContainerParaClient.cs:70→:72`）成立；在 `track-path`（`PtsHelper.cs:134→:137`）不成立**；
  索引行逐处点名本件相关原文（**本席现取**，行号**仅本次有效**）：`:3`／`:33`／`:34`／`:37`／`:38`；原句**一字未删**。
- **`A-2`（三件）**：`PRECOND-PARADESC-SOURCE-MISSING` 补 **`scope=subtrack-path`**（`track-path` 不适用）；各件登记处（现取）：route-criteria／consume2-report／witness-criteria **各 2 处**；原句未删。
- **`A-3`（`P1-lm-consume3-report.md`）**：「描述符字段**求真值**」改词为「**本侧模型值**（常量 `seg_h=16`／`top_sp=0`）」并**明写零判别力**（常量 ⇒ 不区分任何状态；**不得**因此改判成"有判别力"）；该词本件**仅 1 处**（件题，行 `:1`）。与 `win32_pts.c` 注释的关系＝**只引用、不改字**（`src/**` 不在写域）。
- **`E-1`**：`:11`「8 条腿共 **15** 条真按下」⇒ dated 更正为真值 **18**（原方向保守）；原句保留。
- **`E-2`**：`:50`「本闸正确地**拒收**」⇒ dated 更正为「**非候选 ⇒ 按设计交付 ⇒ 支路未被行使**」（与同件 `drop=0`／`e3=DELIVER(…)` 自洽）；原句保留。
- **`E-3`**：`:19`／`:20`／`:21` 行号跳代混用 ⇒ 标清 **交付代 `:1335`／`:1354`、闸 `:1357-1394`、push `:1395`**（**照引 `t208`，本席未独立复算**；行号**仅本次有效**）；并记一行**候选建议**（**不是判据、不是承诺**）：候选支路可考虑**第三条通道（evdev/uinput 或 XI2，带真实服务器时间戳）**。

## §3 引用与代际

| 被引件 | 自证／代际（照引） | 标注 |
|---|---|---|
| `build/MilBridge/P1-lm-consume3-verify.md`（`t206` 裁决） | 自证 `818df822191c0c31` | **未独立复算** |
| `build/MilBridge/P1-e3-replay-verify.md`（`t208` 复核，`pass`） | 109 行／自证 `7f150f960eb6a591` | **未独立复算** |
| 各落点件自证 | 见 §1（六件均 MATCH） | 本席现取现算 |

## §4 具名 `NOINFO`／未做

1. `t206`／`t208` 的读数（含 `E-1` 的真值 18、`E-3` 的三组坐标）**照引、本席未独立复算**。
2. `t205` 的状态（`failed`）**未被本件触碰**；其 `PRECOND-E3-REPLAY-FIXTURE-MISSING` **未解除**（不在本件射程）。
3. `evdev/uinput`／`XI2` 只作**候选建议**一行，**未做**、**未承诺**。
4. 本件**未跑腿、未构建、未起 Xvfb、未占显示位**（开工与落盘两次现取 `/tmp/.X11-unix`：开工 `X0 X1`；落盘时含**他者**新起的 `X263`，非本件所起）；**未碰** `src/**`（含 `win32_x11.c`／`win32_pts.c`，仅引用行号）／`tools/**`／`.cs`／`upstream/**`／csproj／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`；未 `git add/commit/push`。

self16=029624a5f72ebe92
