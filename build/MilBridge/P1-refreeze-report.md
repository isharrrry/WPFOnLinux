# P1 重冻结批（`t74`，队长执行）—— 对齐「现盘 / 登记表 / 冻结块」三角

读时 `ts=2026-09-28T21:53:26.518+0800`｜执行者＝队长（四个成员当时全部空转，按用户指示「没完成队长要想办法完成」接管）

## 1 起因
`t67` 重建 CoverageProbe 后**重取了三支臂日志** ⇒ 现盘离开冻结 ⇒ 处置前状态：
`ARM-LOG-SHA=FAIL pass=2 fail=3`（登记表＝旧值 vs 现盘＝新值）× `COLUMN-FLOOR=PASS`（登记表旧值＝冻结块旧值）。
两牙的命门 ＝ **只剩同时绿当且仅当「现盘 ＝ 冻结块」**（`t72` 已查清并据裁定 (B) 回退过一次）。

## 2 六处耦合（全部只重钉臂日志派生声明；**世代号不变**）
| # | 件 | 改动 | 成对读数 |
|---|---|---|---|
| ① | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `#80` 块内 `ARM-LOG-SHA` 的 `tab-anchor`／`tab-zero`／`tab-rtl` 三行 sha16 换现盘值（`:61`／`:62`／`:63`）＋ 一条重钉说明（**不以 `# ⏪ ` 起头**） | 件 sha16 `b96d4312565a3c49` → `b27ff6332f263495` |
| ② | `build/MilBridge/known-red.json` | `generation.arm_logs` 三值换**全 64 位** | `6351a46296d17b28` → `29219b6f071c6361` |
| ③ | `build/MilBridge/tools/wave-freeze-consistency-check.py` | `:832` 模板里 `tab-anchor sha16=…` 换新值 | — |
| ④ | `docs/CURRENT-STATE.md` | 第 `9` 行 `sha16=` 随基线件重算 | `b96d4312565a3c49` → `b27ff6332f263495` |
| ⑤ | `build/MilBridge/HANDOFF-NEXT.md` | 第 `28` 条 `cell=#3`（`sed -n '9p'`）与 `cell=#1`（`infp` 指纹）同趟追写 | 见两份 dated 行 |
| ⑥ | `build/MilBridge/tools/defect-registry-declared.tsv` | 同趟 `--emit`（`KRJ` 锚刷新） | `DECLDRIFT=0` |

## 3 三牙读数（修后现取）
- `ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0`
- `COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=29219b6f071c6361 base=b27ff6332f263495 corpus=0cebc0afd5142fbf`
- `DEFREG=PASS declared=223 route_ids=223（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号）`
- `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（`cell=#1` 追写前为 `DIVERGED … #1:covered-file-changed-since-ts`）

## 4 世代号不变的依据（逐字）
本次**只**改「臂日志（派生件）的声明」与其两处承载（基线件 `#80` 块内三行、`known-red.json` 三值）＋ 检查器模板 1 处；
**九位未随本次动作变动**（`provider`／`win32shim` 等的位移发生在 `t63`，不是本次）⇒ 不构成新世代 ⇒
`BASELINE-FROZEN gen=#80` **保持不变**，只更新其 `sha16=`（因为基线件内容变了）。⚠️ 该判断具名在册，供复核者推翻。

## 5 自伤一条（当场修，零残留）
首次落说明行时我用了 `# ⏪ **dated 重钉…**` 起头 ⇒ 被 `column-floor-check.sh` 的块头形态判定算作**块头** ⇒
`COLUMN_FLOOR=NOINFO reason=block-header-form-mismatch hdr_forms=awk61/md60`（两种机制计数不等 ⇒ 它拒绝判）。
修法 ＝ 把该行起头改成带缩进的 `#   （重钉说明…）`（不匹配 `^# (RE-FROZEN #|⏪ )`）⇒ 复跑 `COLUMN_FLOOR=PASS`。
**教训**：在基线件的**块内**加任何行，必须避开该件自己的**块头形态**（`^# ⏪ ` 与 `^# RE-FROZEN #`）。

## 6 `NOINFO`（具名）
① 未跑整趟门禁（会构建 ⇒ 动九位）；② 未重取任何臂日志（本次是**改声明**、不是重取）；③ 本件不声称两页可用（`TASK-0007` 与 `TASK-0201` 的终局见 `§13`／`W8`）。
