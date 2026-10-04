# P1-W100（`t183`）· `t180` 两条 medium 必修的落账（dated、只增不改）

**结论（两块）**
① `F-1`（medium）**已落**：`[FSFORMATSUBT]` 的六个 token（含 `rc=0`）**是格式串字面** ⇒ 「逐条现取」措辞**收窄**为「**存在性见证**（该族行出现过 ⇒ 本侧入口 `FsFormatSubtrackFinite` 确被调用过）」，六 token **不得当读数**；**改引**驱动侧回读（`o_fsfmtr` 与 `rc` **同步翻转**：X/X2 `o_fsfmtr=1`＋`rc=0` vs Y `o_fsfmtr=0`＋`rc=-100002`）；并写下"把打印改成真回读／删除常量字段"的**建议**（native 写域，本件不实现）。
② `F-2`（medium）**已落**：`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 改为**逐「入口」**登记表（`FsFormatSubtrackFinite` **已解除（仅行为面）**／`FsQuerySubtrackDetails` **仍开**／其余同族 **未查＝`NOINFO`**），并写明"解除必须写清「授权出处 ＋ 射程 ＋ 粒度 ＋ 逐入口状态」"。

**载体指向**：落点 ＝ `build/MilBridge/P1-fsformatsubtrack-report.md` 末尾 dated 段（`⏪ t183（P1-W100）dated 更正 · t180 两条 medium 必修`）；本件 ＝ `build/MilBridge/P1-f1f2-verifyfix-report.md`（新建）。

---

## 1. 逐件改前／改后（判据①）

| 件 | 改前 | 改后 | `numstat` | 只增不改 |
|---|---|---|---|---|
| `build/MilBridge/P1-fsformatsubtrack-report.md`（落点，`t173` 载体） | `105 行`／`sha16=657aa706a681a56f`／`size=10163`／`mode=644`／`links=1` | **`143 行`／`sha16=18ed4d7def636003`** | **`38 0`**（单 hunk `105a106,143` ＝ 纯追加） | `diff <(git show HEAD:<路径>) 现盘` ⇒ **删行数 0**；对 `cp -p` 备份件同样 **删 0**（备份：`~/w281-scribe/t183/bak/P1-fsformatsubtrack-report.md.pre-t183`，逐位等于改前值） |
| `build/MilBridge/P1-f1f2-verifyfix-report.md`（本件） | （新建） | 见 §4 | `??` | — |

- 该件**在 `HEAD` 里**（`git cat-file -e HEAD:<路径>` ⇒ `IN-HEAD=yes`）且改前**无本地改动** ⇒ 「只增不改」按**对 `HEAD` 的硬口径**给出（上表）。
- **落盘带锚区间前置断言**（照裁定五十七 (a) 的教训）：① 行数＝105 且 `sha16=657aa706a681a56f`；② 四处**被更正原文锚**在场（`逐条现取`／`[FSFORMATSUBT]`／`可解除`／`PRECOND-NATIVE-FORMAT-ENTRY-MISSING`）；③ 末行为自证行。任一不成立 ⇒ **不写**（脚本 `exit 3`）。
  ⚠️ **该断言当场生效过一次**：第一遍锚写成 `可解除（就`（原文里 `**` 夹在中间 ⇒ 该串不在件内）⇒ 脚本**拒绝落盘**（`ANCHOR-FAIL`），改正锚为 `可解除` 后才写 ⇒ 这是"断言有牙"的现场证据（**未产生任何写入**）。
- 新末行自证 `1c41e43195a0c941`；`head -n -1 | sha256sum | cut -c1-16` **当场复算 MATCH=YES**（**上一条自证行原文保留在上方**，现取 `自证` 命中 2 处）。
- 原文一字未删（抽样现取）：`逐条现取` 3／`[FSFORMATSUBT]` 10／`可解除` 2／`FsQuerySubtrackDetails` 3。

## 2. `F-1` 更正的**现取原文**（判据②）

**（a）"格式串字面 vs 回读"的区分**（**本席现取源码**，`src/WpfGfx.Linux.Native/src/win32_pts.c` 现代 ＝ **4352 行／`sha16=02d4c89fa432d4d2`／`mtime 2026-09-29 19:36:39`**；`t181` 在飞 ⇒ **行号仅本次有效**）：
`[FSFORMATSUBT]` 的打印在**第 1555 行**，其**格式串里**含 `rc=0`／`OUT kstop=1`／`dvrUsed=0`／`bbox=flat`／`kclearOut=0`／`topSpace=0`（连同 `ppfsSubtrack=(nil)`／`brkOut=(nil)`／`mcOut=(nil)`）＝ **字面常量**；真写入在同一函数**上方**（`*out_brk_subtrack = NULL`／`*out_ppfs_subtrack = NULL` 等）。带**真回读**的是另一族 `[LMM2] … kstop=%d dvrUsed=%d …`（打 `out_fsfmtr_kstop` 等实读值）—— **本趟三条腿 `[LMM2]` 行数 ＝ 0**。

**（b）改引后的**驱动侧回读**（本席现取自 `/home/links-dev/t123-runner/logs/t173/<腿>.log`，读时 `2026-09-29T20:0x+0800`）**：

| 腿 | `[FSPARALIST-EDRIVE] phase=slot3` 的 `rc` | 回读字段 | `[FSFORMATSUBT]` 行数 |
|---|---|---|---|
| X ＝ `app-m1`（有 `M1`） | **`rc=0`** | **`o_fsfmtr=1 o_dvrUsed=0 o_dvrTopSpace=0 o_breakpos=0`** | 1 |
| X2 ＝ `app-m1b`（有 `M1`） | **`rc=0`** | **`o_fsfmtr=1`** | 1 |
| Y ＝ `app-nom1`（**无** `M1`） | **`rc=-100002`** | **`o_fsfmtr=0`** | **0** |

⇒ **同步翻转对**（`o_fsfmtr` `1→0` ∧ `rc` `0→-100002`）就是**可证伪**的 witness。

## 3. `F-2` 的**逐入口登记表**（判据③；本席现取，读时 `2026-09-29T20:0x+0800`）

| 入口 | 状态 | 依据（本席现取） |
|---|---|---|
| `FsFormatSubtrackFinite` | **已解除（仅行为面）** | 同副本只差 `M1` 的三腿成对：`app-m1`／`app-m1b` `rc=0` ＋ `[FSFORMATSUBT]` 各 1 行；`app-nom1` `rc=-100002` ＋ `[FSFORMATSUBT]` **0** 行 |
| `FsQuerySubtrackDetails` | **仍开** | 三腿各 **2** 条具名缺失行 `named 'FsQuerySubtrackDetails'`（**含 M1 腿**）⇒ 与 `M1` 无关 |
| 其余同族成员 | **未查（`NOINFO`）** | 名单面现取未取到（`k_pts_entries` 段 0 命中 ⇒ 形态已变，本件未追）⇒ **不冒充**"已解除／仍开" |

⚠️ **导出面不适用（如实记）**：现取 `.so`（`sha16=352855f8dfbf8dc7`／`mtime 2026-09-29 19:36:47`，`t181` 在飞）里 **两枚命中都是 0**（对照 `FsQueryTrackParaList=1`）⇒ 本件**不**用 `nm` 导出面给这两个入口定"已解除／仍开"。

## 4. 本件载体自证（判据④）

`build/MilBridge/P1-f1f2-verifyfix-report.md`：`mode=644`／`links=1`；末行自证与 `head -n -1 | sha256sum | cut -c1-16` **当场复算 MATCH**（值见交件消息与末行）。

## 5. 具名 `NOINFO`（判据⑤）

1. **"其余同族成员"的逐条状态**：**未查**（名单面未取到；未冒充）。
2. **导出面**：两个入口在现 `.so` 里命中均 0 ⇒ **导出面对本判定不适用**（也**不**据此反推"未实现"）。
3. **`[LMM2]` 真回读族**：本趟三腿行数均 0 ⇒ 该族**本趟不可用**（改用 `[FSPARALIST-EDRIVE]` 的 `o_*`）。
4. **`t180` 的"`PtsSubClaimOk`／`Bad`／`SelfTestMask` 无哨兵"**：**照录、本席未独立复算**。
5. **`win32_pts.c` 的行号/内容**：`t181` 在飞（现代 `02d4c89fa432d4d2`）⇒ 本件所引行号**仅本次有效**，跨代须重取。
6. 本件**未跑腿、未构建、未跑整趟门禁、未占显示位**（`/tmp/.X11-unix` 现取 `X0 X1`）；未 `git add/commit/push`。

self16=e29b771d25d75d1c
