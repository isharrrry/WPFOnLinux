# P1-W3 关账（第二轮）报告 · V-1／V-2／V-3（`t35`）

> **开篇 ＝ 判据**（写在任何落仓之前）。判词载体 ＝ `build/MilBridge/P1-w3-close-verify.md`（`t30`，`166` 行／`d7d9113ae25c7f17`，**只读未改**）。
> 写者 `scribe`；工作根 `$N`；分支 `feat-Linux`。纪律：写前 `stat -c %h` 须 `==1`；`cp -p` 备份在任何写之前；`temp + rename`；**只增不改**；`NOINFO` 具名；新增行 `⏪` 起头 ＋ **亚秒戳**。
> §0 判据段读时戳（亚秒）＝ `2026-09-28T16:42:53.604+0800`。

## §0 判据（先写 · 逐条可现算）

- ⏪ **C1（V-1）**：`build/MilBridge/P1-w3-close-report.md` 的 **`:51`（入口）／`:52`（出口）** 两行**各自内联** `ts=<亚秒戳> 时 入口=X 出口=X，覆盖面=N`（第 20 条口径的自足形态）；某行读时**不可回溯源** ⇒ 具名 **`NOINFO(reason=…)`** ＋ 给**可证界**（不许编造亚秒值）。
- ⏪ **C2（V-2）**：`build/MilBridge/tools/wave-push.sh`：**只对两条规范路径**（`/tmp/bridge-frozen.flag`、`$HOME/wfp-runs/bridge-frozen.flag`）自动建父目录；**其它任何路径**必须显式 `WPW_MKDIR_OK=1` 才允许建，否则 **`WPW=FAIL reason=strange-target-path` ＋ 点名 `path=`／`dir=` ＋ `hint=set WPW_MKDIR_OK=1`**（rc=1，拒跑）。
- ⏪ **C3（V-2 两极化真跑）**：① 规范路径（用**假 `HOME`** 把 B 变成规范路径）⇒ **自动建**、rc=0；② 陌生路径 ＋ 无 `WPW_MKDIR_OK` ⇒ **必红点名**；③ 陌生路径 ＋ `WPW_MKDIR_OK=1` ⇒ **放行且上屏**（`WPW_MKDIR_OK …`，不静默）。全程**生产两枚哨兵零改动**。
- ⏪ **C4（V-3）**：更正 `P1-w3-close-report.md` **`:77`** 的形态自查**三格数**（原写「`^[^⏪]`＝`1`（空行）＋ 块头 ＋ `8` 条 `- ⏪`」）⇒ 给**现取三格**（总行／空行／块头／`- ⏪` 行）＋ **两种 `^[^⏪]` 口径**（含空行／不含空行）并写明**数新增行时必须含 `+` 空行**。
- ⏪ **C5（W4 检查项）**：`build/MilBridge/HANDOFF-NEXT.md` 落 dated 追加（**只增不改**）：三颗新牙接线（`sentinel-spec-check.sh`／`wave-push.sh`／`timestamp-order-check.sh`）＋ `--expect`／步数**同趟**＋ **`WPW_MKDIR_OK` 语义**（陌生路径不许静默建树）。
- ⏪ **C6（指纹／牙）**：入口／出口各取 `inputs_fp` ＋ 覆盖面件数（**带值带时刻**）并**逐件归因**；`wave-push.sh` 现取 `in-list=0`（覆盖面外）⇒ 改它**不动 `inputs_fp`**。
- ⏪ **C7（边界／收口）**：越域为零（`porcelain` 逐行归属，他人脏件逐行点名）；**未** `git add/commit/push`；**未碰** `close-wave.sh`／`verify-all.sh`／`P1-w3-close-verify.md`／`P1-w3-verify.md`／`P1-v-close2-report.md`／产品件／基线件；未跑整波／门禁／构建；临时件残留 `0`；本件就位并自报 sha16 ＋ 读取时刻（亚秒）。

## §1 落仓清单（证据行读时戳（亚秒）＝ `2026-09-28T16:43:44.652+0800`）

⏪ 四件（写前 `stat -c %h` 全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/*.pre-t35` 取在**任何写之前**；落仓一律 `temp + rename`）：
⏪ `build/MilBridge/tools/wave-push.sh` `9a518e00b3a78163` → **`213ecfbaee4ebd71`**（121 → 142 行；`numstat` **`24 3 build/MilBridge/tools/wave-push.sh`**；mode 755；`bash -n` **OK**）。
⏪ `build/MilBridge/P1-w3-close-report.md` `dd90b22c3fa9c7e0` → **`a7c304ed6e20a2be`**（79 → 88 行；`numstat` **`9 0 build/MilBridge/P1-w3-close-report.md`**；**删行 `0`**；原文前缀 `cmp` **IDENTICAL**；新自证 `head -n -1` ＝ **`62b4af2386610c64`**）。
⏪ `build/MilBridge/HANDOFF-NEXT.md` `4ce961789433b735` → **`c6233569d1597435`**（378 → 384 行；`numstat` **`6 0 build/MilBridge/HANDOFF-NEXT.md`**；前缀 `cmp` **IDENTICAL**）。
⏪ `build/MilBridge/P1-w3-close2-report.md`（**新建**）＝ 本件（§0 判据**先落**，`15` 行／`4bb682a43d20a96d` 为**判据段**的 sha16、**不是**全文值）。

## §2 C1（V-1）证据：入口／出口行各自内联 `ts=`（或具名 `NOINFO`）

⏪ **入口行（`:51`，仅本次有效）**：原句「`ts=` 起读时刻见 §0／§1」＝**转引、不自足** ⇒ **`NOINFO(reason=入口读数取自开工前侦察命令、其读时未落亚秒戳)`** ＋ **界**：`ts ≤ 2026-09-28T16:28:37.377+0800`（＝本波首笔落仓的读时戳）。
⏪ **出口行（`:52`，仅本次有效）**：原句**完全无 `ts`** ⇒ **`NOINFO(reason=出口读时只余区间界、无亚秒读数)`** ＋ **界**：`2026-09-28T16:33:26.546+0800 < ts ≤ 2026-09-28T16:33:55.980+0800`。
⏪ **现取自足对（此后引用用这一对）**：**`ts=2026-09-28T16:43:25.054+0800` 时 入口 ＝ `c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d` 出口 ＝ 同上，覆盖面 `226`／`226`**。⚠️ 与 `:51`／`:52` 旧值（`8c4ce894…`）**不同** ⇒ 旧值**已过期**（`t31`／`t33` 改了覆盖面内的 `pkg-src-retiredpath-check.sh`），旧两行**数值保留作历史、不作现取依据**。

## §3 C2／C3（V-2）证据：`WPW_MKDIR_OK` 门 ＋ 两极化真跑

⏪ **修法**：`wave-push.sh` 里新增 `ensure_dir()`：**父目录已存在 ⇒ 直接过**；**缺**时 —— **规范路径**（`/tmp/bridge-frozen.flag`／`$HOME/wfp-runs/bridge-frozen.flag`，由 `canon_a`／`canon_b` 现算比较）或 **`WPW_MKDIR_OK=1`** ⇒ 才 `mkdir -p`；**其它任何路径且无该变量** ⇒ **`WPW=FAIL reason=strange-target-path sentinel=A|B path=… dir=… hint=set WPW_MKDIR_OK=1`（拒跑并点名）**；显式放行时**上屏** `WPW_MKDIR_OK …`。既有的「不可写」闸**保留**（对已存在目录同样生效）。
⏪ **① 规范路径（用假 `HOME` 把 B 变成规范路径、其父目录缺失）** ⇒ **rc=0**：`WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13 … sha16=6cb3f97388c3c4dc`；**B 的父目录被自动建**（`test -d` ⇒ YES）、文件 `sha16=6cb3f97388c3c4dc`（**与生产哨兵逐字相同**）。
⏪ **② 陌生路径且无 `WPW_MKDIR_OK`** ⇒ **rc=1**：`WPW=FAIL reason=strange-target-path sentinel=A path=…/strange/sub/a.flag dir=…/strange/sub hint=set WPW_MKDIR_OK=1（**陌生路径不许静默建树**…）`；**陌生目录未被建出**（`test -d` ⇒ NO）、**B 未被写**（内容仍 `OLD-B`）⇒ **正是要堵的那条假绿通道**。
⏪ **③ 陌生路径 ＋ `WPW_MKDIR_OK=1`** ⇒ **rc=0** 且**上屏** `WPW_MKDIR_OK sentinel=A path=… dir=…（**陌生路径显式放行**…）`，随后 `WPW=PASS … sha16=6cb3f97388c3c4dc`；两枚与生产哨兵 `cmp` **IDENTICAL**（`WPW_MKDIR_OK` 只改**是否允许建树**、不改口径）。
⏪ **契约 `verify` 那一条腿（`/tmp/nowhere.$$/`）** ⇒ **rc=1**，前两行含 `reason=strange-target-path` ✓；`--dry-run` 复跑 **rc=0**、末行 `WPW=DRYRUN lines=13 keys=13` ✓；**生产两枚哨兵全程零改动**（各 `6cb3f97388c3c4dc`、`cmp` IDENTICAL）。

## §4 C4（V-3）证据：`:77` 形态三格更正

⏪ **原句两格错**（`:77`，仅本次有效）：写「空行 `1` ＋ 块头 `1` ＋ **`8` 条 `- ⏪`** ⇒ `10` 行」；**只因 `1+1+8 ＝ 2+1+7 ＝ 10` 而总数巧合相符**（`D-G125` 同族）。
⏪ **现取三格（本席自算；`HANDOFF-NEXT.md` 第 `20` 条块现取 `:361`–`:370`，仅本次有效）**：**总行 `10` ＝ 空行 `2` ＋ 块头 `1` ＋ `- ⏪` 行 `7`**；**`^[^⏪]`：含空行 ＝ `10`／不含空行 ＝ `8`**；**首字节即 `⏪` 的行 ＝ `0`** ⇒ **口径写死：数新增行必须含 `+` 空行；报 `^[^⏪]` 必须写明是否含空行**（可复算命令原文已入 `P1-w3-close-report.md` 追加块）。

## §5 C5（W4 检查项）证据

⏪ `HANDOFF-NEXT.md` **EOF dated 追加 `6` 行**（378 → 384；`numstat` `6 0 build/MilBridge/HANDOFF-NEXT.md`；前缀 `cmp` IDENTICAL）：**三颗新牙同趟接线**（`sentinel-spec-check.sh` `8c8470a3b3dd0c0d`／`wave-push.sh` `213ecfbaee4ebd71`／`timestamp-order-check.sh` `6ace8e29f3cf6357`；三颗现取 **`in-list=0`**）＋ **`--expect`／步数同趟声明**（现取 `226` ⇒ 加三颗 `229`；步数现取 `55`）＋ **`WPW_MKDIR_OK` 语义**（陌生路径不许静默建树；非规范路径首跑必须先设该变量、并保留上屏行）＋ **首跑后现算上屏**（两颗 `cmp`＋`sha16`＋带 `ts` 的 `inputs_fp`）。

## §6 C6 证据：指纹（带值带时刻）

⏪ **出口**（本波落定后现取，`ts=2026-09-28T16:43:44.652+0800`）：`inputs_fp` ＝ **`c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`**／覆盖面 **`226`**；**入口**（本波开工现取）＝ `c87cb187f45082e83d3b217d235d50b24f1183f28d37308f1a175de25210403d`／`226` ⇒ **两值逐字相同**。
⏪ **逐件归因（现取 `in-list`）**：`tools/wave-push.sh` **`0`**｜`HANDOFF-NEXT.md` **`0`**｜`P1-w3-close-report.md` **`0`**｜`timestamp-order-check.sh` **`0`** ⇒ **本波三件改动件全在覆盖面外** ⇒ **未动 `inputs_fp`**（**带值带时刻**，非口头声明）；`[42]` 的 `--expect` 因而**本波不需同趟改**（W4 接线时才需要）。

## §7 C7 证据：边界 ／ 自伤 ／ `NOINFO`

⏪ **`porcelain` 逐行归属（现取）**：`M build/MilBridge/HANDOFF-NEXT.md`｜`M build/MilBridge/P1-w3-close-report.md`｜`M build/MilBridge/tools/wave-push.sh`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-w3-close2-report.md` ⇒ **本波三件改动 ＋ 一件新建**；其余 `??` 为**他人件**（`t7` 的 criteria 等，未读未改）⇒ **零越域**；未碰 `close-wave.sh`（`f9a2ee3ee35baff8`）／`verify-all.sh`（`600274f130cfe913`）／`P1-w3-close-verify.md`（`d7d9113ae25c7f17`）／`P1-w3-verify.md`／`P1-v-close2-report.md`／产品件／基线件。
⏪ **自伤**：**本波无中途失败**（与 `t29`／`t33`／`t34` 不同 —— 本波打补丁前**先用 `sed -n` 打出锚原文**、并逐条 `assert` 命中数，**首跑即落**）；**生产哨兵未被任何腿触碰**（两枚 `6cb3f97388c3c4dc` 全程不变）。
⏪ **`NOINFO`（具名）**：① **入口行／出口行的原读时不可回溯源** ⇒ 只给**区间界**（见 §2；**不许**倒推亚秒值）；② 本波**未跑整波／门禁／构建**（派单边界明写）⇒ 不判其效果；③ `wave-push.sh`／`HANDOFF-NEXT.md` **未接线**（`fp_inputs()`／`verify-all.sh` 归 **W4**）⇒ 不判门禁效果；④ **假 `HOME` 腿**只证明「规范路径判定用的是 `$HOME` 现算值」，**未**在真 `$HOME` 下删除 `~/wfp-runs` 复跑（**生产目录不动**）⇒ 该腿的「真缺目录」情形记 `NOINFO(reason=生产目录不许动)`。

## §8 结论

⏪ `t30` 点名的三处 **全部关账**：**V-1** 两行**各自内联**（一为 `NOINFO`＋界、一为 `NOINFO`＋界）＋**给出现取自足对**（带亚秒戳、且写明与旧值的过期关系）｜**V-2** `WPW_MKDIR_OK` 门（**只规范路径自动建／陌生路径必红点名／显式放行必上屏**）＋**三条两极化真跑**＋生产零改动｜**V-3** 三格更正（**含 `+` 空行**口径＋命令原文）。
⏪ **判据只收紧**：**陌生路径静默建树**这条假绿通道被堵（`reason=strange-target-path` ＋ `hint`）；**未**放松任何既有腿（正极、`--dry-run`、生产哨兵 `cmp` 全绿）。
⏪ 本件自证 sha16（口径＝**末行之前的全文**）＝ `ed153fe80a813c0a`（末行＝本行）；**全文** sha16 与末次读取时刻见交件消息（末行只携带 `head -n -1` 口径 ⇒ 全文值不可能自指）。
