# P1-W20 · native 侧纵深防御报告（`t92`）—— `F-3` 名字读取口不再返回截断名 ＋ `O-1` 报告返回语义可判

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-native-nameguard-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**。
> 读时 `HEAD=e5327ab`（`fix(#81): t90 t88 余项处置 … F-3 长度纪律`）。
> 纪律第 `30` 条（自检调用史敏感）：本件**所有自检读数都标注了 `fresh` / `带历史`**，见 §3、§6。

---

## 0. 一句话结论

**两处都做了真修，且导出面零位移。**
① **`F-3`**：`WpfLinuxWin32_PtsGapEntryName()` 修前是 `snprintf(buf, cap, "%s", 名); return 1;`（**无长度检查** ⇒ `cap=4 ⇒ rc=1 / "LoA"`）；修后**放不下就"没拿到"**：返回 **`0`** 且把 `buf` 写成**空串**（`buf[0]='\0'`）——**绝不返回截断名**；`cap=名长` ⇒ `0`／`""`，`cap=名长+1` ⇒ `1`／全名（**边界档逐档给出**）。
② **`O-1`**：`WpfLinuxWin32_PtsGapReport()` 的"写不下"支**语义不变**（只走 `-1`），但把那条**隐含不变式写成可机器核的三条**（`-1` 唯一失败形态／`strnlen(buf,cap)==cap-1` 被钉住／`cap` 起的尾部区**一个字节都不越界写**），并**同趟落进自检的新格 `80`/`81`**。
③ **导出面零位移**：`nm -D --defined-only` ＝ **561** ＝ `exports.txt` 561，且 `exports.txt` 与 `t92` 之前**逐行相同**（检查口做成 `static`，**不**新增导出符号）。
④ 验证链全过：`PTSGAP=PASS tool=97 ops=85 impl=91 so16=657f448c2077ba1f exports=561`｜冷启腿 `alive=yes app_rc=143`、`entry=LoAcquirePenaltyModule`｜`PTS-PAGES` 在册 **`rc=0`／`PTS_GUARD=PASS`**。

---

## 1. ① `F-3` 真修：原文与返回语义

**修前（现取，`t92` 之前的 `src/win32_pts.c` 原文 ＝ 节 `// 第 idx 个"见过"…`）**：
```c
int WpfLinuxWin32_PtsGapEntryName(int idx, char *buf, int cap)
{
    if (!buf || cap <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (seen == idx) {
            snprintf(buf, (size_t)cap, "%s", k_pts_entries[i]);   // ← 截断时**静默**，仍返回 1
            return 1;
        }
        seen++;
    }
    buf[0] = '\0';
    return 0;
}
```

**修后（本件现件原文，核心支）**：
```c
        if (seen == idx) {
            int need = (int)strlen(k_pts_entries[i]) + 1;      // 名长 + nul
            if (cap < need) {                                  // **放不下** ⇒ 不返回截断名
                buf[0] = '\0';
                return 0;
            }
            snprintf(buf, (size_t)cap, "%s", k_pts_entries[i]);
            return 1;
        }
```

**返回语义（本口定死，逐条）**：

| 情形 | 返回值 | `buf` 内容 | 调用者能否判定"没拿到名" |
|---|---|---|---|
| 命中 ∧ `cap >= 名长+1`（放得下） | **`1`** | **真名**（nul 结尾） | ——（拿到了） |
| 命中 ∧ `cap <= 名长`（放不下） | **`0`** | **空串**（`buf[0]='\0'`） | ✔ **凭 `rc` 或凭空串**都能判 |
| `buf == NULL` ∨ `cap <= 0` | **`0`** | 不写（**连 `cap=0` 的缓冲也不碰**，见 §2 的 `cap=0` 档） | ✔（凭 `rc`） |
| 无此 `idx`（越界／没有该条目） | **`0`** | **空串** | ✔ |

**三条设计选择与理由（逐条）**：
1. **`0` 而不是负值**：`0` 是**本口修前就有的"没有"语义**（越界/无此 idx ⇒ `0`）⇒ 复用同一码**不引入新语义**（`t90` 在托管侧写的 `GapEntryNameAt()` 正是按 `!= 1` 判"没拿到"⇒ **本修与那一层天然相容**）。
2. **同时写空串**：光靠返回值不够 —— 派单要求"**就算忽略返回值也不能拿到貌似完整的短名**" ⇒ 内容侧也归一到空串；**忽略返回值**的读者只会读到 `""`（**量上不可能像名字**）。
3. **不做"按需分配"**（派单明禁）：本修**零分配**、零新语义，只是在写之前加一条 `cap < need` 的比较。

---

## 2. `F-3` 成对与边界档读数（本趟现取；**fresh 进程**）

**探针**：仓外 `~/t92-runner/bin/probe-name.c`（与 `win32_pts.c` **同源编译**、直接调该口；缓冲先全填 `0xA5` canary，再按长度安全打印）。**成对**：同一探针分别与**(a) 本件真实现**、**(b) 修前形态副本**（`~/t92-runner/fixtures/win32_pts.B-prefix-bug.c`，唯一改动＝删掉长度守卫）链接。

| `idx` / `cap` | **(a) 修后（本件）** `rc` / `len` / 内容 | **(b) 修前形态（反腿 B）** `rc` / `len` / 内容 |
|---|---|---|
| `idx=0 cap=0` | `0` / `0` / `""`（缓冲**一个字节都没碰**：`first_byte=0xA5`） | `0` / `0` / `""`（同） |
| `idx=0 cap=1` | **`0`** / `0` / `""` | **`1`** / `0` / `""` |
| `idx=0 cap=2` | **`0`** / 0 / `""` | **`1`** / 1 / **`"L"`** |
| `idx=0 cap=4` | **`0`** / 0 / `""` | **`1`** / 3 / **`"LoA"`** |
| `idx=0 cap=5` | **`0`** / 0 / `""` | **`1`** / 4 / **`"LoAc"`** |
| `idx=0 cap=12` | **`0`** / 0 / `""` | **`1`** / 11 / **`"LoAcquirePe"`** |
| `idx=0 cap=22`（＝**名长**） | **`0`** / 0 / `""` | `1` / 21 / `"LoAcquirePenaltyModul"` |
| `idx=0 cap=23`（＝**名长+1**） | **`1`** / 22 / **`"LoAcquirePenaltyModule"`** | `1` / 22 / 同 |
| `idx=0 cap=31` / `32` / `33` / `128` | `1` / 22 / 全名 | `1` / 22 / 全名 |
| `idx=9999 cap=128`（越界） | `0` / 0 / `""` | `0` / 0 / `""` |
| `idx=-1 cap=128`（负） | `0` / 0 / `""` | `0` / 0 / `""` |
| `buf=NULL cap=128` | `0` | `0` |

⚠️ **本趟那次缺口名册里"最后一条有缺口的入口"是 `LoAcquirePenaltyModule`（22 B）** —— 所以上表 `cap=22/23` 就是**这条**的边界档；`cap=31/32/33` 是**富余档**。

**余量读数（派单点名要的三条，全部现取）**：
- **现册最长名** ＝ `LoGetPenaltyModuleInternalHandle` ＝ **32 B**（`sed -n '/^static const char \*const k_pts_entries\[\] = {/,/^};/p' … | grep -o '"[A-Za-z0-9_]*"' | tr -d '"' | awk '{print length($0), $0}' | sort -rn` 现取；其后 `DestroyInstalledObjectsInfo` 27 B／`CreateInstalledObjectsInfo` 26 B）。
- **生产 `cap`** ＝ **`128`**（`build/PresentationFramework.Linux/PtsCache.Linux.cs` 的 `private const int GapNameCap = 128;`，**只读现取**，本件未改它）。
- ⇒ **余量 ＝ 128 − 33 ＝ 95 B**（要放得下最长名需 `cap ≥ 33`；`128/33 ≈ 3.9×`）⇒ **今天的生产档离边界很远**；即便名册将来加长，最坏也只是**保守地"没拿到"**（返 0 ＋ 空串 ⇒ 托管侧回落 `anchor=`／`frontier=`／`unknown`），**不会**给出假名。

---

## 3. ② `O-1`：报告返回语义"可判、可核"

**修的判断与代价（先回答派单的"若你判断 native 已足够…要给出理由与代价"）**：
· **现状本来就对**：`WpfLinuxWin32_PtsGapReport()` 两支 —— 放得下 ⇒ `return n`（**正的长度**）；`n < 0 || n >= cap` ⇒ `buf[cap-1]='\0'; return -1;` ⇒ **`-1` 已是唯一失败形态**，且**行首到 `cap-2` 是完整前缀、`cap-1` 是 nul**。
· **但它"对"靠的是一条没被写下来的不变式**（尾部字节"恰好没被动"）⇒ **代价＝零**、**风险＝"后人顺手多写一个字节"**（例如为别的目的在尾部加字段）就会把"良构截断"变成"越界写"，而**没有任何读数会响**。
· ⇒ 本件**不改变行为**（`-1` 那一支的语义一字不动），只做两件**加固**：① 把那条不变式写成**代码注释里的三条**；② **同趟落进自检的新格 `80`/`81`**（见 §4），使"越界写/收尾不精确"**当场变红并点名**。

**成对读数（仓外探针 `~/t92-runner/bin/probe-report.c`，与真实现链接；缓冲先填 `0xA5` canary，尾部另留 64 B 探针区）**：

| `cap` | `rc` | `strlen(buf)` | 尾部区（`cap` 起）**是否一个字节没动** | **忽略 `rc` 的读者会读到** | **按 `rc` 判的读者会读到** |
|---|---|---|---|---|---|
| `0` | `-1` | `0` | 干净（**不 deref**：`cap=0` 连 `buf[0]` 都不碰） | 空 | `-1` ⇒ 没拿到完整行 |
| `1` | `-1` | `0` | 干净 | `""` | `-1` |
| `2` | `-1` | `1` | 干净 | `"P"` | `-1` |
| `64` | `-1` | `63` | 干净 | `"PTS_GAP_REPORT mode=honest-f…"`（**良构前缀**） | `-1` |
| `128` | `-1` | `127` | 干净 | 同上（良构前缀，nul 精确落在 `buf[127]`） | `-1` |
| `256` | `-1` | `255` | 干净 | 同上 | `-1` |
| `291` | `-1` | `290` | 干净 | 同上 | `-1` |
| **`300`** | **`292`** | `292` | 干净 | **整行**（`PTS_GAP_REPORT mode=honest-fail … setbrk_rej=…`） | `292` ⇒ 拿到了（与忽略 `rc` 一致） |
| `512` / `4096` | `292` | `292` | 干净 | 整行 | 同 |

⇒ **"忽略 rc 的读者"在写不下时拿到的是"良构前缀 ＋ 精确 nul 收尾"**（**不是**半截行混着未初始化字节：`cap` 起的尾部区**一个字节都没动**，现取 `tail_untouched=1`）；**"按 rc 判的读者"拿到 `-1`**（应用侧 `NativeReport()` 正是这一类，它据此**放大缓冲重试**）。**两边读数都明确、可判、可核。**

**反极性（这一条**有牙**，本趟实测）**：副本 `~/t92-runner/fixtures/win32_pts.C-o1-dirty.c`（唯一改动＝截断支里多写一个**越界**字节 `buf[cap]='X'`）⇒ 同一探针逐档现取 **`tail_untouched=0`**（`cap=1/2/64/128/256` 全部），而放得下的档（`cap=300`）仍 `tail_untouched=1` ⇒ **"越界写"这件事被抓住**（不是"无论怎么写都报干净"的恒真检查）。

---

## 4. ③ 自检新增格 `80`/`81`（**为了"导出面不动"而做的选择**）

**为什么不是导出两个检查口**：派单硬约束"导出面**不该因本件变动**（现 `nm`=**561**）"。我先按"导出 `WpfLinuxWin32_PtsGapReportTailIsClean()` ＋ `…TailUntouched()`"实现过，**实测 `nm` 561 → 563**（`exports.txt` 多两行）⇒ **不合约束** ⇒ 改成 **`static`**：两条不变式由**已有的** `WpfLinuxWin32_PtsGapSelfCheck()` 内部调用（**不新增导出符号**）。

**新增两格（原文要点）**：
```c
        else if (!g_pts_selfcheck_o1_canary())   rc = 80;   /* O-1：-1 ∧ strnlen==cap-1 ∧ 行区良构 ∧ 尾部区未被动 */
        else if (!g_pts_selfcheck_f3_boundary()) rc = 81;   /* F-3：cap=名长 ⇒ 0/"" ; cap=名长+1 ⇒ 1/全名 */
```
· **格号从 `80` 起**：**旧格号一个都没动**（现用号：`1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,20,21,22,23,24,25,26,27,28,29,30,31,32,34,35,40…79,90…` 区间之外；`80/81` **此前未被占用** ⇒ **纪律第 `30` 条（格号语义不许改数）满足**）。
· `80` 格断言四条：`rc == -1` ∧ `strnlen(buf,cap) == cap-1` ∧ 行区良构 ∧ **`cap` 起 32 B 尾部区全是 canary**。
· `81` 格断言四条：对**现册缺口名册最后一个有计数的入口**取 `cap = 名长` ⇒ `0` 且 `buf[0]=='\0'`；再取 `cap = 名长+1` ⇒ `1` 且与名册**逐字相同**。**不写死任何名字/长度**（现册最长名的长度**现算**）⇒ 名册将来变长，本格**自动跟着收紧**。

**三条反腿（同一自检、只换被链的 `.o`；`fresh` 进程）**：
| 版本 | 唯一改动 | `WpfLinuxWin32_PtsGapSelfCheck()` | 点名格号 |
|---|---|---|---|
| **真实现（本件）** | —— | **`1`** | `diag=0` |
| 反腿 **B** `win32_pts.B-prefix-bug.c` | 删掉 `F-3` 长度守卫（＝修前形态） | **`0`** | **`81`** |
| 反腿 **C** `win32_pts.C-o1-dirty.c` | 截断支多写一个**越界**字节 | **`0`** | **`80`** |
| 反腿 **D** `win32_pts.D-lie-rc.c` | 放不下时**写空串但 `rc` 仍报 `1`**（"谎报拿到"） | **`0`** | **`81`** |
⇒ **格 `80`/`81` 有牙**：三条不同的"假形态"都被抓住，且**各自点名到格**；真实现 `1/0`（连跑两次都是 `1`，幂等）。

---

## 5. ④ 验证链（逐条，全部现取）

**① 重建 `.so`**（重活槽、后台；本件只重建 native 件 ⇒ 未跑托管构建，`-m:1`／`gcServer=0` 对本件无作用对象，如实记）：
```
bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- bash …/src/WpfGfx.Linux.Native/build-shim.sh --symbols
HEAVYSLOT=ACQUIRED waited=0s ｜ HEAVYSLOT=MEMOK avail=6299MB min_avail=2500MB ｜ HEAVYSLOT=RELEASED rc=0 held=2s max_hold=1800s
== 产物：bin/libwpfwin32.so（346088 字节）
== 导出符号总数：561
```
**② `nm` / `exports` 相等且仍 561（导出面零位移）**：
```
nm -D --defined-only … | awk '{print $3}' | grep -c .   ⇒ 561
wc -l < bin/exports.txt                                  ⇒ 561
diff <(sort exports.txt.pre-t92) <(sort exports.txt)     ⇒ 空（EXPORTS_IDENTICAL）
```
**③ `pts-gap-count-check.sh` 保持 `PASS`**（同趟把声明件的 `so16` 一位跟着换）：
```
# PTSGAP-DECL: … so16=3bd193e54785b5db → 657f448c2077ba1f（tool/ops/impl/exports/w66pre16 一字未动）
PTSGAP=PASS tool=97 dead=11 artifact=1 ops=85 impl=91 so16=657f448c2077ba1f exports=561 root=/home/links-dev/netTest/GitProj/WPFOnLinux
PTSGAP_FRONTIER_STATE=NAMED frontier=LoAcquirePenaltyModule（具名前沿成立）
```
**④ 冷启腿**（先 `sync-applocal.sh --check` 得 `DRIFT` ⇒ **按要求先 `sync` 到 `drift=0`** 才跑；显示 `:237`；进程只按 PID）：
```
APPSYNC: SYNC-APPLOCAL=PASS … drift=0
AUTHORITY: shim=657f448c2077ba1f pf=83ba5884bb603296 ｜ APPDIR: 同值
X_UP=yes display=:237
CLICK k=24 alive=yes expect=FlowDocumentDemo AE=221857 pts_unavail=1 pts_gap=1 guard=1 fatal=0 unh=0
CLICK k=23 alive=yes expect=RichTextBoxDemo AE=141283 pts_unavail=2 pts_gap=1 guard=1 fatal=0 unh=0
APP_RC=143 ｜ POSTSHIM: shim=657f448c2077ba1f pf=83ba5884bb603296（== authority ⇒ 读数可归因）
HEAVYSLOT=RELEASED rc=0 held=30s
```
症状（`leg_*.env` 现取）：两腿 `LEG … alive=yes app_rc=143 magenta=54533/49943 colors=852/844 ink=423798/428456`｜`NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000`｜`DEV … shim=657f448c2077ba1f pf=83ba5884bb603296`。
`entry=` 面（现取）：**`3 entry=LoAcquirePenaltyModule`**（与 `t86` 那次同形 ⇒ 本件**未**改变被撞的入口）。
**⑤ `PTS-PAGES`（点名的那条：在册证据目录）**：
```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
rc=0
PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
```
（对照：我自己那趟腿的目录同判 `rc=0`／`PASS`。）

---

## 6. ⑤ 纪律 28／第 29 条／哨兵／不变量／牙

**纪律 28（同趟）**：`inputs_fp` 写前 `f4a21769b3d6399339d9ddb2dc99ec106ca6b4e345803d46b36be508abf15834` → **写后同值 `f4a21769…`**（追加 `cell=#1` **不移指纹**——`HANDOFF-NEXT.md` 不在覆盖面内）；`build/MilBridge/HANDOFF-NEXT.md` EOF **纯 `>>`** 追写一行 dated `cell=#1`：写前 sha16 `400171e13c4cc307`／**627** 行 → 写后 `ec7068347be52a9f`／**628** 行，`git diff --numstat` ＝ **`1 0`** ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**。

**第 `29` 条（备份面 ≡ 换代面）**：改动件 **3** 件，逐件 `cp -p` 备份到仓外 `~/t92-runner/bak/`：
| 件 | 写前 sha16 | 写后 sha16 | 备份 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `ddc21eb68d2d67e8` | **`823298d182c6d271`**（878 → **1006** 行，`wc -l` 现取） | `win32_pts.c.pre-t92`（`bba8e3a42a37e353`，＝加完守卫、未加格 80/81 的中间态亦另存 `_prebuild`） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `3bd193e54785b5db` | **`657f448c2077ba1f`**（346032 → 346088 B） | `libwpfwin32.so.pre-t92` |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `aa006983db912eaa`（`t86` 后的现盘值） | **`8400d2440baeec37`**（**只 `so16` 一位**：`3bd193e54785b5db → 657f448c2077ba1f`；`tool/ops/impl/exports/w66pre16` 一字未动） | `pts-gap-decl.txt.pre-t92` ＋ `_prebuild` |
**格号占用现取（纪律第 `30` 条"不许改数"的自证）**：`grep -n 'rc = 8[0-9]\|rc = 7[0-9]' src/win32_pts.c` ⇒ 命中**只有** `:932 rc = 70`／`:933 rc = 71`（格 3 的编排面）与 **`:984 rc = 80`**／**`:985 rc = 81`**（本件新增）⇒ **`80/81` 此前未被占用**，且**旧号一个都没动**。
⇒ **改动面 3 件 ≡ 备份面覆盖 3 件**；另存了一份"守卫已加、格 80/81 未加"的**中间态**（**如实登记**：本趟在该中间态上重建过一次 `.so`（得到 `657f448c…` 之前的一版 `8b984cd395a0537e`／561→**563** 导出）—— 那次**不合**"导出面不动"约束，已 `static` 化后**重新净化并重建**，过程读数见 §4）。

**哨兵（如实报，未写 —— 写是队长的事）**：
```
$ grep -n 'WIN32SHIM' /tmp/bridge-frozen.flag   ⇒ 3bd193e54785b5db
$ sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16   ⇒ 657f448c2077ba1f
$ bash build/MilBridge/tools/sentinel-spec-check.sh  ⇒ rc=1
SSC_VALUE=FAIL key=WIN32SHIM got=3bd193e54785b5db want=657f448c2077ba1f path=…/libwpfwin32.so
SSC=FAIL 规范不满足（逐条见上）
```
⇒ **`.so` 换代后哨兵与之不一致（`WIN32SHIM` 位）**，而**同一牙**的 `PF` 位已跟上（`83ba5884bb603296`）⇒ **只差 `WIN32SHIM` 一位**。`cmp` 两枚哨兵仍 `IDENTICAL`（`ef97d026f99ce450`）。**我未重写哨兵**（边界明令 + 派单"写是队长的事"）；`SENTINEL-SPEC` 由 `t86` 时的 `PASS` 变 **`FAIL`**，**真因就是这一位**，如实点名。

**四条不变量**：`^run_step "` 计数 **62**＝现声明 **`62 gen=#81`**；`[42]` 的 `--expect` ＝ **234**＝覆盖面**活清单** `names_n=234 manifest_n=234` 且 `FP_MANIFEST_TEETH=PASS`（`would_be_fp=f4a21769b3d63993`）⇒ **本件未增删任何覆盖面内件**（只换内容）。

**已接线牙（现取，逐条）**：
| 牙 | 读数 | 判定 |
|---|---|---|
| `QUOTE-TRAP` | `SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203`（rc=0） | 绿 |
| `PIPEFAIL-SIGPIPE` | `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85`（rc=0） | 绿 |
| `HANDOFF-MV` | `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0） | 绿 |
| `REPORT-ID` | `REPORTID=PASS files=237 ids=2200 declared=224`（rc=0） | 绿 |
| `DEFECT-REG` | `DEFREG=PASS declared=224 route_ids=224`（rc=0） | 绿 |
| **`SENTINEL-SPEC`** | **`SSC=FAIL`** ＋ `SSC_VALUE=FAIL key=WIN32SHIM got=3bd193e54785b5db want=657f448c2077ba1f`（rc=1） | **红（真因＝哨兵 `WIN32SHIM` 位陈旧；我未重写）** |
| **`STATIC-JAWS`** | **`STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62`**（rc=1） | **红（另一族，实为"某条裸静态牙自报 `rc≠0`"；与 `t86` 时报的那条同族，属既在项，`build/MilBridge/tools/**` 在禁写域）** |
（`STATIC-JAWS` 的 `STATICJAWS_RAN` 明细行本趟现取共 32 条，形如 `step=… jaw=… rc=0 stderr=0行`；本件未改任何静态牙。）

---

## 7. 未做项与原因（如实）

1. **未重写哨兵**（边界明令 + 派单归属）⇒ 只见 §6 的 `SSC_VALUE=FAIL key=WIN32SHIM` 现取读数。
2. **未跑整趟门禁**（纪律禁）⇒ 第 `[38]` 步的步级读数未取；本件取的是**同一条命令**在现树上的读数。
3. **未跑托管构建**（`-m:1`／`gcServer=0`）：本件只改 `src/WpfGfx.Linux.Native/**`，**无托管件参与** ⇒ 那两档对本件**无作用对象**（如实记，不假装跑过）。
4. **未改 `build/PresentationFramework.Linux/**`**（`t90` 刚改完、`t91` 在看）⇒ `GapNameCap=128` 与 `GapEntryNameAt()` 的长度纪律**保持原样**；本件只保证**native 侧**不再给截断名（两层**相容**，见 §1 的"三条设计选择"第 1 条）。
5. **未改** `build/MilBridge/tools/**`（`t89`/`t90` 刚改）／`verify-all.sh`／`build/close-wave.sh`／哨兵／`docs/ROUTES.md`／`tests/PtsPagesProbe/evidence/**`；**未** `git add/commit/push`。
6. **`STATIC-JAWS` 那条红**：另一族，详见 §6，**未动**。

---

## 8. 边界遵守自证

- **写域内被写的件**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（唯一产品源）＋ `src/WpfGfx.Linux.Native/bin/{libwpfwin32.so,exports.txt}`（构建产物；`exports.txt` 由 `--symbols` 从 `nm -D` 现生成，**与 `t92` 之前逐行相同**）＋ `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（**只 `so16` 一位**）＋ 本件 ＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行（`>>` 追加）。
- **腿跑纪律**：显示位 **`:237`**（`:23x` ✓）｜进程**只按 PID** 收（装置自收 `xvfb.pid`／`xfwm.pid`；全程无 `pkill`／`killall`／`pgrep -f`；扫 `/proc` 时排除自身祖先链）｜重活**全走 `heavy-slot.sh` 后台**（`build.pid=2806023`／`build2.pid`；`ACQUIRED waited=0s`／`MEMOK avail=6299MB`／`RELEASED rc=0 held=2s`；腿 `held=30s`）｜**未跑整趟门禁**。
- **资源（现取）**：`MemAvailable=6525128 kB`／`SwapFree=1431292 kB`／`df -Pk` 余 `72619280 kB` ⇒ 离停手线（2000 MB／512 MB／5 GB）远；收尾扫 `/proc/*/exe` ⇒ **0 个** `Xvfb`／`xfwm4`／`HandyControlDemo` 残留。
- **台账/中间件**落 `~/t92-runner/`（`bin/`／`logs/`／`bak/`／`fixtures/`），**未落 `/tmp`**；仓根未留临时件。
- **件位 sha16**：**跑前跑后各算一次**（§5／§6 表内逐件给出）。
- **无 `git add`／`commit`／`push`**（全程零）；`git status --porcelain` 只列出 `src/WpfGfx.Linux.Native/**` 与 `build/MilBridge/HANDOFF-NEXT.md` ＋ 本件。
本件编排口径（自报可复算）：**正文**（`head -n -1`，250 行）sha16 ＝ `4c39824412077cc3`；**`inputs_fp` 现值** ＝ `f4a21769b3d6399339d9ddb2dc99ec106ca6b4e345803d46b36be508abf15834`；**改动件 3 ≡ 备份面 3**（§6）。⚠️ **全文 sha16 是自指量、不可自报** ⇒ 只报正文值与 `inputs_fp`，全文值由读者现算。模式 `644`。
