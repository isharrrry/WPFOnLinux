# P1-`t200` · `t195` 判词入册：三件 dated 收窄 ＋ 静默阈值禁令

**结论**：`t195`（`needs_revision`）点名的三条 ＋ 两条 low 已按 dated、**只增不改、删行数 0** 落进三件；
新前置 **`PRECOND-PARADESC-SOURCE-MISSING`** 已在三件同趟入册；纪律条款「**读数类打印行禁静默阈值**」入册并列为**恒真断言族第六例候选**。

**载体指向**：落点＝`P1-host-consume-route-criteria.md`／`P1-lm-consume2-report.md`／`P1-lm-consume-witness-criteria.md` 三件末尾各自的 dated 段（同名 `⏪ t200 dated 收窄 · t195 判词…`）。

---

## 1. 逐件改前／改后（**只增不改、删行数 0**）

| 件 | 改前（现取） | 改后 | 只增不改 |
|---|---|---|---|
| `build/MilBridge/P1-host-consume-route-criteria.md` | 171 行／`abfaebc99aa8ec5b`／18721 B／mode 644／links 1 | **206 行／`02fa8bfe55bee21c`**（+35） | vs `cp -p` 备份：**删 0**、加 35；新自证 `7b2ccba25d3acede` 复算 **MATCH** |
| `build/MilBridge/P1-lm-consume2-report.md` | 79 行／`4147b10b124c6445`／7898 B | **114 行／`8f8fedd859225524`**（+35） | 删 0、加 35；新自证 `2edf6c26b22ccc3e` **MATCH** |
| `build/MilBridge/P1-lm-consume-witness-criteria.md` | 141 行／`5c01fae3ddaa026c`／14997 B | **176 行／`6e89e54d04fe51b9`**（+35） | 删 0、加 35；新自证 `522aa065eb3698d4` **MATCH** |

- 备份（写**前** `cp -p`，写前 `links=1`）：`~/w281-scribe/t200/bak/<件名>.md.pre-t200`。
- 落盘：`temp + os.replace`（保留 `mode 644`）；**带锚区间前置断言**：每件必须 ① 行数/`sha16` ＝ 现取；② 该件**被更正原文锚**在场；③ 末行为自证行 ⇒ 任一不成立即 `exit 3` **不写**。
  ⚠️ **断言当场生效一次**：第三件首轮锚用了 `逐字一致`（该件里**不存在**，`逐字` 命中 0）⇒ `ANCHOR-FAIL` **拒写（零写入）**，改用该件真实锚（`[FSPARALIST-FILL]` 等）后才落盘。
- 三件原句**仍在场可核**（现取计数）：`算术唯一确定`＝6（route-criteria）／5（consume2-report）；`到达见证`／`唯一确定` ＝5（witness-criteria）。

## 2. 写入内容（逐条）

- **`W-1`（high）**：凡写「两个操作数都是本侧作者 ⇒ `rcPara.dv` 由**算术唯一确定**」者，**dated 收窄为不成立** —— 依据：`arrayParaDesc[index]` 的唯一填写者 `PtsHelper.cs:633 PTS.FsQuerySubtrackParaList(...)` native **未实现**；**本席现取**（`win32_pts.c` 现代 4506 行／`7212969f6e2cbb9f`／mtime `2026-09-29 22:54:13`，行号**仅本次有效**）该件**第 3803 行**自陈「与 `FsQuerySubtrackParaList`（`PtsHelper.cs:633`），二者都属 **(b)**、**尚未实现**」；**本席现取** `nm -D`（`.so` `352855f8dfbf8dc7`／`exports=669`）：`FsQuerySubtrackParaList` ＝ **0 命中**（同趟 `FsQuerySubtrackDetails`／`FsFormatSubtrackFinite` 亦 0）。⇒ `PtsHelper.cs:174-180` **今天不可达**、两操作数无源；`t194` 引的 `dvrUsed=16/dvrTopSpace=0` 属**格式化出参（另一界面）**。
- **新前置**：**`PRECOND-PARADESC-SOURCE-MISSING`**（射程＝`PtsHelper.cs:174-180` 的 `rcPara.dv` 计算；粒度＝单次 `ArrangeParaList` 调用）。
- **`W-2`（medium）**：① 四腿 `consumes`/`resolve_ok` **无读取载体**（`[LMWIT] part=arrival` 未打印）⇒ 曾为**回显推断**；② 该计数是 `+192` **回收**事件（**本席现取**：声明 `:1141`／`:1142`、自增 `:3658`、合取 `:3661`），前置是"客户端被创建"，**不是** `:174-180` 被执行；③ `arrayParaDesc.Length == subtrackDetails.cParas`（`PtsHelper.cs:629`）而 `LM-1` 自许 `cParas=0` ⇒ **`cParas=0` 时 `:177` 一次不跑而后代回收照旧** ⇒ 到达见证**必须改为落在 `:174-180` 路径上的事件**（做不到即具名）。
- **`W-3`（low）**：自源行号属改前代际；**以本席现取为准** —— `g_pts_fsp_pl_consumes` 声明 **`:1141`**、`g_pts_fsp_pl_resolve_ok` **`:1142`**、自增 **`:3658`**、合取 **`:3661`**（现代 `7212969f6e2cbb9f`；行号**仅本次有效**）。
- **`W-4`（low）**：「A/B **逐字一致**」**粒度越界**（整腿日志自第 138 字节起分叉；**照引 `t195`，本席未独立复算**）⇒ 收窄为「**读数行**逐字一致」。
- **状态声明**：`LM-1` 第 4 条**维持 `NOINFO`／降级见证**；`S-2a` **维持 7/8**（不得写 8/8）。
- **纪律入册**：**读数类打印行禁静默阈值** —— 要么必打，要么打**具名缺省行**，把「**没取到**」与「**没发生**」分为两种可区分形态；**正例**＝无条件打 `consumes=%d`，取不到打 `consumes=NOINFO(reason=no-arrival-leg)`；**反例**＝仅 `>0` 才打印 ⇒ 与"真 0 次"不可分（本波第二次咬人）。列为**恒真断言族第六例候选**（另四例：`t156` `+200` 恒定绿桩／`t161`"数值无判别力"／`t163` `P9` 偷换／`t176`＋`t183` 格式串字面），**待复核确认后升格**。

## 3. 引用与代际

| 被引件 | 本席现取代际 | 标注 |
|---|---|---|
| `build/MilBridge/P1-lm-consume2-verify.md`（`t195`） | 110 行／`sha16=31dfda00ef739289`／自证 `59095ac60f913ea5` | 其 `W-2①`／`W-4` 读数**照引**，**本席未独立复算** |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | 4506 行／`7212969f6e2cbb9f`／mtime `22:54:13` | `W-1`／`W-3` 的**行号与自陈句本席现取**（行号仅本次有效） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `352855f8dfbf8dc7`／`exports=669` | `nm` 三枚 0 命中**本席现取** |

## 4. 具名 `NOINFO`／未做

1. **`FsQuerySubtrackParaList` 何时能实现**：**未核**（native 写域，不在本件）。
2. **`t195` 的 `W-2①`（`[LMWIT] part=arrival` 未打印）与 `W-4`（第 138 字节分叉）**：**照引、未独立复算**。
3. **"落在 `:174-180` 路径上的到达事件"能否做出来**：**本波未证**，按 `PRECOND-PARADESC-SOURCE-MISSING` 记未解除。
4. 本件**未跑腿、未构建、未跑整趟门禁、未占显示位**（`/tmp/.X11-unix` 现取 `X0 X1`）；**未碰** `src/**`／`tools/**`／`tests/**`／`.cs`／`upstream/**`／csproj／两枚哨兵／`HANDOFF-NEXT.md`；未 `git add/commit/push`。

self16=f6765dc040225fdc
