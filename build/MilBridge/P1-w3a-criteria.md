# P1-W3a 判据（**先写**）—— 哨兵键序/字节规范 ＋ `sentinel-spec-check.sh`（`scribe`/`t23`）

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=4a97a0d`｜写域＝`HANDOFF-NEXT.md`／`docs/ROUTES.md`（＋新建 牙／判据／报告）；**不碰 `build/close-wave.sh`**（W3b）

## 0 现取基数（开工现算，早于任何写）
- 两枚哨兵：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` ⇒ **13 行／13 键**、`cmp` **IDENTICAL**、无 CR（`grep -c $'\r'`=0）、尾字节 `0a`
- 键名＋键序（现取，逐字）：`SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16`
- 权威路径（CFG=**Release**，`provider` 走**工程产出目录**）九个值我逐个现取，**与哨兵九键逐位相同**；`FP` ⇔ `bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881`（**不是** `inputs_fp`）
- `docs/CURRENT-STATE.md:9` ⇒ `gen=#80 sha16=b96d4312565a3c49` ⇔ 哨兵 `WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49`

## 1 判什么（六条，与牙一一对应）
| # | 判据 | 牙的机读行 | 红 |
|---|---|---|---|
| ① | 行数=13 ∧ 键名集合∧键序 == 现取规范 | `SSC_LINES=`／`SSC_KEYSET=` | 不等 |
| ② | 无 CR ∧ 无空行 | `SSC_CR=`／`SSC_BLANK=` | 有 |
| ③ | 两枚 `cmp` 相同 | `SSC_CMP=` | 不同 |
| ④ | 九键值 == 权威路径现取（`provider` 禁副本） | `SSC_VALUE=PASS/FAIL key=…` | 不等 |
| ⑤ | `FP` == `BRIDGE_SRC_FP`（**非** `inputs_fp`）；`WAVE`／`BASELINE`／`BASELINE_SHA16` ⇔ `CS:9` | 同上 ＋ `SSC_CS=NOINFO`（取不到 ⇒ `NOINFO`） | 不等 |
| ⑥ | **任何空值 ⇒ 红**；`none(<reason>)` 形态 **允许且上屏、不判红** | `SSC_EMPTY=FAIL`／`SSC_NONE=ALLOWED` | 空值 |

三态：`PASS rc=0`｜`FAIL rc=1`｜`NOINFO rc=2`（**缺一枚哨兵 ⇒ `NOINFO`，不许静默判等**；权威件缺席 ⇒ 该键记 `NOINFO` 而非红）。

## 2 两极化（**四例，先用夹具证明牙真的会红**）
① 键序打乱 ⇒ `SSC_KEYSET=FAIL` 点名 got/want｜② 字段清空 ⇒ `SSC_EMPTY=FAIL` 点名行号｜③ 缺一枚 ⇒ `SSC=NOINFO reason=sentinel-absent`（rc=2）｜④ `none(<reason>)` ⇒ `SSC_NONE=ALLOWED` 且总判 `PASS`（占位形态不得被判红）。
**夹具自证（教训）**：我第一版的乱序夹具用 `sed -n '1p;3p;2p;4,13p'` 构造 ⇒ **`sed` 按行号升序打印 ⇒ 夹具根本没乱**，牙对"未变的件"给 `PASS`（**正确**）⇒ **该腿一度是空腿**；改用 `printf` 显式重排后 `SSC_KEYSET=FAIL` 才出现 ⇒ **"先证明夹具真的会红"这一条本波亲自咬到我自己**。

## 3 边界
本件**只登记规范 ＋ 落牙 ＋ 沙箱两极化**；**不接线**（归 W4）、**不碰 `close-wave.sh`**（归 W3b）、不跑整波/门禁/构建、不 commit／push。
