# P1-W3a 收口报告 —— 哨兵键序/字节规范 ＋ 新牙 `sentinel-spec-check.sh`（`scribe`/`t23`）

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=4a97a0d`｜写域：`build/MilBridge/HANDOFF-NEXT.md`／`docs/ROUTES.md`（＋新建 牙／判据／报告）；**未碰 `build/close-wave.sh`**（归 W3b）、**未接线**（归 W4）
判据件（**先写**）＝ `build/MilBridge/P1-w3a-criteria.md`；本件写入方式 ＝ temp＋`rename`；末次现取时刻见末行。

## §1 现取基数（开工现算）
- 两枚哨兵 `/tmp/bridge-frozen.flag`・`~/wfp-runs/bridge-frozen.flag`：**13 行／13 键**、`cmp` **IDENTICAL**、`grep -c $'\r'`＝**0**、末字节 `0a`
- **键名＋键序（逐字）**：`SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16` ⇒ **侦察件 §C-1 的「十键固定序」与现场不符**（如实记）
- 九键值 ⇔ `NINE_PATHS`（`CFG=Release`；`provider` 走**工程产出目录**、禁副本）**逐位命中**；`FP` ⇔ `bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881`（**不是** `inputs_fp`）
- `docs/CURRENT-STATE.md:9` ⇒ `gen=#80 sha16=b96d4312565a3c49` ⇔ 哨兵 `WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49`

## §2 交付
| 件 | 改动 | sha16 |
|---|---|---|
| `build/MilBridge/HANDOFF-NEXT.md` | **+13／删 0**（规范 7 条，落纪律区 EOF） | `084bdaec14ed5536 →` **见 §5** |
| `docs/ROUTES.md` | **+1／删 0**（`§15af` 的 `C-1` dated 关账） | `bfa16fa3ffd7cdea →` **见 §5** |
| **新建** `build/MilBridge/tools/sentinel-spec-check.sh` | 新牙（**不接线**） | **`8c8470a3b3dd0c0d`** |
| 新建 `build/MilBridge/P1-w3a-criteria.md` | 判据（先写） | 见 §5 |

**规范 7 条（逐字）**：① 行数＝`13`｜② 键名集合 ∧ **键序**逐字固定（上列 13 键）｜③ 字节格式：`<KEY>=<VALUE>`、行尾单个 `\n`、无空行、无 `CR`｜④ 两枚 `cmp` 相同｜⑤ 各键值 == 权威路径现取（`provider` **禁副本**；`FP`＝`BRIDGE_SRC_FP`；`WAVE`／`BASELINE`／`BASELINE_SHA16` ⇔ `CS:9`）｜⑥ **任何空值 ⇒ 红**，取不到写 **`none(<reason>)`**（**允许、上屏、不判红**）｜⑦ **缺一枚 ⇒ `NOINFO(rc=2)`，不许静默判等**。

## §3 两极化（真跑，原始机读行）
- **正极（真树）**：`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（rc=0，**13 键值逐键**命中权威路径）
- **反极①键序打乱**：`SSC_KEYSET=FAIL got=[SHA PC FP PF …] want=[SHA FP PC PF …]` ⇒ `SSC=FAIL`（**rc=1**）
- **反极②字段清空**：`SSC_EMPTY=FAIL 空值行=2`（取不到须写 `none(<reason>)`）⇒ `SSC=FAIL`（**rc=1**）
- **反极③缺一枚**：`SSC=NOINFO reason=sentinel-absent path=…/nope`（**rc=2**，**未静默判等**）
- **反极④`none()`**：`SSC_NONE=ALLOWED keys= WIC` ∧ `SSC=PASS`（**rc=0**）⇒ 占位形态**不被判红**（判据不放松、也不做恒红）
- `--selftest`：`SSC_SELFTEST=PASS cases=4 pass=4 fail=0`（四例同上述），**stderr 零行**

### ⚠️ 本波的自伤（如实记，已被自己的判据咬到）
我第一版"键序打乱"沙箱夹具用 `sed -n '1p;3p;2p;4,13p'` 构造 ⇒ **`sed` 按行号升序打印 ⇒ 夹具根本没乱**，牙对"**未变的件**"给 `PASS` —— 该行为**正确**，但**那条腿一度是空腿**；改用 `printf` 显式重排后 `SSC_KEYSET=FAIL` 才出现 ⇒ **"先证明夹具真的会红"这条纪律本波亲自咬到我自己**（如实记）。
另：牙的首版 `trap 'rm -rf "$T"' EXIT` 在 `local T` 出作用域后触发 `set -u` 报 `T: 未绑定的变量`（stderr 一行）⇒ 已改 `${T:-}` 并复核 **stderr 零行**。

## §4 `C-1` 关账（`docs/ROUTES.md` `§15af`）
以本区内含「哨兵的键序／」字样的那条 `dated 缺口入册（t68…）` 行为**内容锚**，落 **dated 关账**（`:830`，删行 0）：规范载体＝`HANDOFF-NEXT.md` 纪律区那行；牙路径与 **sha16 `8c8470a3b3dd0c0d`**；**现取 13 键逐字**；**如实记侦察原句「十键」与现场不符**；值口径（`FP`＝`BRIDGE_SRC_FP`、`provider` 禁副本）逐字。

## §5 两牙 / 指纹 / 越域
`DEFREG=PASS declared=216 route_ids=216`｜`REPORTID=PASS files=194 ids=2042 declared=216`（**均未退化**）
**`inputs_fp` ＝ `e9f95ec005715b3a…`／覆盖面 `226` ⇒ 零位移**（逐件归因：本波两件 `HANDOFF-NEXT.md`／`docs/ROUTES.md` **均不在 `fp_inputs()`**；新牙**未接线** ⇒ 也**不在**覆盖面）⇒ **`[42] --expect 226` 不动**、`verify-all.sh` 未碰。**W4 接线时**：新牙入覆盖面 ⇒ 件数 `226 → 227` ＋ `[42] --expect` 同趟改（**代价与位置已逐字留在规范行内**）。
`git diff --numstat` 仅两件（`13/0`、`1/0`）＋ 新件 3（牙／判据／本报告）；其余 `M`／`??`（`t18` 的四件、`t7` 的 `P1-task0201-criteria.md`、verifier 的 `P1-w2-verify.md`）**非本席**，未读未改 ⇒ **零越域**；**未** `git add`／`commit`／`push`；临时件残留 `0`。
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ **`0abc3e3a0d674f72`**（整 64 hex 见交件消息）／本件 `wc -l` ＝ **`41` 行**（含本行；不含本行 `40` 行）／末次现取时刻 ＝ `2026-09-28T16:14:56+0800`／写入方式 ＝ **temp ＋ `rename`**／同趟自证：`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`（rc=0）｜`SSC_SELFTEST=PASS cases=4 pass=4 fail=0`｜`DEFREG=PASS declared=216 route_ids=216`｜`REPORTID=PASS files=194 ids=2042 declared=216`｜`inputs_fp=e9f95ec005715b3a…`／226（零位移）。
