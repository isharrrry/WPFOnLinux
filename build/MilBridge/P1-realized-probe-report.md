# P1-W43 · `N3` 对照腿判别实验（`clicks=[23,24]`）＋ `N1/N2/N4` 现取读数

> **本件是探针件**：契约 ＝ `build/MilBridge/P1-realized-criteria-report.md`（146 行，sha16 **`55d6f050ecbe4c7d`**，现取复算相符）的 `N1–N4` ＋ §2「截图同趟自证」通用要件。全部读数**本趟现取**；命令与输出原样贴出。
> **本件不引任何既有报告当证据**（判据件只作契约引用）。
> **读取时刻**：`ts=2026-09-29T11:23`（起）→ `ts=2026-09-29T11:31`（末取）。

---

## §0 一句话判词

**`N3` 两条腿的帧 `sha256` 逐字节相同（去重计数 ＝ 1）**，而**两页确实都加载了、两次点击都命中、进程活着**；同时 **`AE(boot,k23)>0` 与 `AE(boot,k24)>0` 都成立**（`15385/15385`）⇒ ⇒ **判 `（乙）`不成立、判 `（甲）`「两页本来就同貌」成立**（**证据**：两页的 XAML **内容截然不同**，若各自绘出则**不可能**逐字节相同；且两页的**内容 token 一个都没出现在画面里**）。

**但 `（甲）` 不是"两页本来就长得一样"，而是"两页**都没有把自己的内容绘出来**、都停在同一个空态/回退画面上"** —— 这由 `N2` 的 **`ENFE_TOTAL=1152`（`FsCreatePageBottomless` ×1151 ＋ `FsCreatePageFinite` ×1）** 解释：渲染循环里**每次布局都抛** `EntryPointNotFoundException`。⇒ **`N3` 本条按契约判红**（两帧不同这一要求**未**达成），并给出上面那条可判证据。

---

## §1 `N3`（主项）：对照腿 `clicks=[23,24]`

### 1.1 怎么跑的（**装置件一字未改**，如实交代）
装置缺省次序**写死**在 `run-pts-pages-legs.sh:167`：`LEG_GROUPS=("A:24,23")`，**无 env 覆盖点**（现取 `grep` 无 `PTS_GUARD_*CLICK*`）。而 `LEG_GROUPS` 是"调用方 argv 次序"的载体 ⇒ 次序**只能由调用方决定**。
- **第一次尝试（已否决并如实记）**：我直接调 `session_inner.sh` 传 `"A:23,24"` ⇒ 腿**跑起来了**（两页都 `alive=yes`），但**漏了 `run-pts-pages-legs.sh:197` 的 `cp -a shots` 与 `:170` 的 `tee session.txt`** ⇒ `session.txt` 与仓内 `shots/` **不同趟**（那次派生出的"帧"我也如实备份在车道 `~/t119-runner/bak/run-N3-shots/`，但**不作为证据**）。
- **正式做法（本件的读数全部来自它）**：
  ```
  sed 's|LEG_GROUPS=("A:24,23")|LEG_GROUPS=("A:23,24")|' 装置 → 车道副本
  cp -a 车道副本 → build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh   # 临时，跑完立刻还原
  env PTS_GUARD_DISPLAY=:249 W67_DISPLAY=:249 PTS_GUARD_REPO=$N bash <装置> <证据目录>
  ```
  ⇒ 跑完后**立即** `git checkout -- build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`；现取 `git diff --stat -- build/MilBridge/tests/PtsPagesProbe/` **只剩 `evidence/**` 的 `M` 行**（装置件零改动，见 §7）。**`diff` 的唯二差异行就是 `:167` 与 `:168` 的 `A:24,23→A:23,24`。**

### 1.2 三件读数（契约 `N3` 要求）
```
去重计数 = 1                      （期望 2 ⇒ 未达成）
AE(k23,k24) = 0
AE(boot,k23) = 15385
AE(boot,k24) = 15385
帧 sha256: boot=b21eb530afd3c66c │ k23=1a76488aa4a790b3 │ k24=1a76488aa4a790b3 │ last=1a76488aa4a790b3
两条 LEG: LEG k=23 … ns=…RichTextBoxDemo  ae=15385 ink=480000
          LEG k=24 … ns=…FlowDocumentDemo ae=0     ink=480000
```
**注意 `ae` 语义（现取校正）**：`leg_24.env` 的 `ae=0` 并**不**表示"第 24 页没重绘" —— 同一趟的 `AE(boot,k24)=15385 ≠ 0` ⇒ 该 `ae` 字段量的是**"本帧与上一帧"**（第 2 次点击时上一帧就是 `k23`）⇒ 它是**"两页相同"的读数**，不是"没重绘"的读数。**这正是本件要判的那件事。**

### 1.3 判词与证据（**（甲）成立，（乙）不成立**）
| 要件 | 现取 | 判 |
|---|---|---|
| 两次点击都**命中** | 两条 `CLICK` 行均 `expect_hit=yes`、`try=1`、`ns_delta=1` | ✅ 导航**发生了** |
| 两页**都真加载** | `[NS] loaded …RichTextBoxDemo`（`:573`）、`[NS] loaded …FlowDocumentDemo`（`:1746`） | ✅ 两页**都被创建** |
| 帧**位移**（boot→各帧） | `AE(boot,k23)=AE(boot,k24)=15385` **>0** | ✅ 画面**确实从 boot 变过** |
| 两页**之间**位移 | `AE(k23,k24)=0` | ❌ **零** |

**⇒ 为什么判「同貌」而不是「没重绘」**（这是本件的承重论证，**可机核**）：
1. 两页的**内容定义截然不同**（仓外第三方演示，**只读**现取）：
   - `RichTextBoxDemo.xaml`（23 行）：`<RichTextBox Width=400 Height=300>` ＋ `<FlowDocument>` ＋ 两段重复文本；
   - `FlowDocumentDemo.xaml`（114 行）：`FlowDocument` 里有 **`Neptune` 行星长文**、`<Figure>`、`<Floater>`＋`<Table>`、`ColumnWidth=400` 等。
   ⇒ 若两页**各自把自己的内容绘出来**，两帧**不可能**逐字节相同。
2. 两页的**内容 token 在整份日志里命中 0**：`grep -ci 'neptune'` ＝ **0**（`N4` 的反例 token）——`FlowDocumentDemo` 的正文词**一次都没出现**。
3. 而 `AE(boot,·)=15385>0` 证明**画面不是"冻在 boot"**：`boot→点击后`确实重绘过；**是"两个点击后状态彼此相同"**。
⇒ 结论：**（乙）"第 23 页根本没重绘"被这两条否掉**（若 23 页没重绘，则 `k23` 应等于 `boot`，而 `AE(boot,k23)=15385≠0`）；**（甲）"两页同貌"成立**，且其成因是**两页都未绘出自己的内容**（`N2`）。**证据齐、判词可判，不含糊。**

### 1.4 与装置缺省次序那一趟的对照（**跨趟，只作旁证**）
缺省 `[24,23]` 那趟（`03:14`）三帧 ＝ `ef3fd6765f18f51b`；本趟 `[23,24]` 三帧 ＝ `1a76488aa4a790b3`。
- **两趟不同**、**各自内部三帧相同**（`k23=k24=last`）⇒ 换了点击次序**帧内容随之变**（说明画面随导航状态变），但**同一趟内两页仍分不开**。⇒ 进一步支持"两页同貌"而非"仪器呆滞"。
- ⚠️ **跨趟不可拼**（纪律）：上面两组数字**只用于对照**，**未**与任何本趟 `.env` 混合。

---

## §2 `N1`：帧身份 ＋ 帧位移（**双要件**，`ink` 已降级）

```
① 帧身份：k23 = 1a76488aa4a790b3 ∉ 空态参照集{ef3fd6765f18f51b}  ⇒ 是（∉）
          k24 = 1a76488aa4a790b3 ∉ 空态参照集{ef3fd6765f18f51b}  ⇒ 是（∉）
② 帧位移：AE(boot,k23)=15385 > 0  ∧  AE(boot,k24)=15385 > 0
③ ink：k23=480000、k24=480000（boot 也 480000）⇒ 与契约 §1 现取完全一致：**四帧同值、零区分力**
```
- **⇒ `N1` 双要件均满足**（帧身份 ∉ 空态参照集 **且** 帧位移 >0）。**按契约写法，`ink>0` 只记"必要不充分"**，本件**未**拿它当内容证据。
- ⚠️ **但 `N1` 的满足不等于"内容对"**：`N1①` **只对"已登记的空态参照集"有分辨力**；本趟两帧虽然 ∉ **旧参照集**（它们换了一版），却**仍然彼此相同**且内容未绘（`N2`/`N4`）⇒ **这恰好说明"参照集必须随空态换版同趟重登记"**（契约 §6-`NOINFO④` 的维护项**今天仍然欠着**）。
- ⚠️ **`N1②` 的"每次点击后 `AE(上一帧,本帧)>0`"**：第 1 次点击 `AE(boot,k23)=15385>0` ✅；第 2 次点击 `AE(k23,k24)=0` ⇒ **不满足**，且本件**已按 `N3` 的例外支给出"同貌"证据**（§1.3）⇒ 该例外**成立**，故 `N1②` 不因此单独判红。

---

## §3 `N2`：`ENFE_TOTAL` ＋ 按入口名直方图

```
ENFE_TOTAL = 1152
按入口名：  1151  FsCreatePageBottomless
               1  FsCreatePageFinite
[HC-UNHANDLED] 计数 = 1152（每条 ENFE 一行）
```
- **`ENFE_TOTAL>0` ⇒ 按契约 `N2②`：不得给「排版绿」**（除非该批名被显式列入非目标 allowlist、逐名可核）。**本件不给任何"排版绿"。**
- **归因按入口名过滤**（`N2③`）：本趟只出现 **2 个**入口名，**没有**混入其它族/其它 shim 的 ENFE。
- **机制（现取，解释 §1.3 的"两页都没绘出"）**：`[NS] loaded …RichTextBoxDemo`（`:573`）**紧邻** `#1` ENFE；`[NS] loaded …FlowDocumentDemo`（`:1746`）**紧邻** `#771 FsCreatePageFinite`；其后持续 `FsCreatePageBottomless`（`:775+`）⇒ **两页的布局/渲染循环每次都被这个缺符号打断** ⇒ 内容出不来。
- ⚠️ **与台账口径不是同一个量**（契约 §3 口径句，逐字遵守）：本件所引**全部**为**托管具名异常面**（`^\[HC-UNHANDLED\] … Unable to find an entry point named '…'`）；**未**引台账口径（`^PTS_GAP entry=`）。
- **三条代价随引用一并写**（契约 §3 要求）：① 该面只给"名字＋次数"，给不出 native 侧状态；② 发射方是**第三方应用**（不在本仓写域，只能读）；③ 它会混入任何 ENFE ⇒ 归因**必须按入口名过滤**（本件已过滤）。

---

## §4 `N4`：内容身份（负身份可达；**正身份 `NOINFO`，不折绿**）

```
负身份（＝ N1①）：k24 = 1a76488aa4a790b3 ∉ 旧空态参照集 ⇒ 可达 ✓
正身份（该页专属期望指纹）：**无载体** ⇒ NOINFO
LEG k=24 … ns=HandyControlDemo.UserControl.FlowDocumentDemo      ← ns= 只证"加载了那个类型"
grep -ci 'neptune' app_g1.log = 0                                 ← 该页正文词一次都没出现
```
- **`ns=` 不承担内容身份**（契约 `N4③`）：本趟**又是**一个干净反例 —— `ns=…FlowDocumentDemo` **成立**（`:1746` 已 loaded），而该页的正文词 `neptune` **命中 0**、画面与第 23 页**逐字节相同** ⇒ **"加载了对的类型"与"内容是那一页的"是两件事**，本件用**同一趟**证据把它钉住。
- **正身份 `NOINFO`**：今天**没有**"该页专属期望指纹"的登记（契约 §6-`NOINFO①`）⇒ **如实记 `NOINFO(无正身份载体)`，不折绿**。**消掉需要**：另派单登记一次"已知良好渲染"的该页帧 `sha256`（或该页专属结构读数）。
- ⚠️ 本件**未**把 `colors/magenta/ink` 或 `ns=` 中的任何一项读成"内容正确"。

---

## §5 截图同趟自证（通用要件，三件逐格）

```
① 截图 sha256：boot = b21eb530afd3c66c │ k23 = 1a76488aa4a790b3 │ k24 = 1a76488aa4a790b3
② 同趟字段：   session.txt: clicks=[23,24] 11:25:21 │ shim_sha16=a131ea4e6f5cc4f5 │ pf_sha16=2988f5154ecac5dd
               leg_24.env DEV 行: shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd
               现盘 .so = a131ea4e6f5cc4f5（= 装置 POSTSHIM；本趟 .so/pf 未换代 ⇒ 同趟无疑）
③ shotstat 现读 vs leg_*.env 逐格：
     shotstat  k23: colors=384 magenta=0 ink=480000   │ leg_23.env colors=384 magenta=0 ink=480000   ⇒ 逐格相等 ✓
     shotstat  k24: colors=384 magenta=0 ink=480000   │ leg_24.env colors=384 magenta=0 ink=480000   ⇒ 逐格相等 ✓
     shotstat  boot: colors=386 magenta=0 ink=480000  │ （boot 不落 env，与 session.txt 的 boot 行 386 一致）
三件 mtime：boot 11:25:30 │ k23 11:25:36 │ k24 11:25:41 │ session.txt 11:25:45 │ leg_*.env 11:25:46 ⇒ 同一趟
```
⇒ **三要件齐备 ⇒ 本件截图可作承重件**。
⚠️ **如实记一处"已修的不同趟"**：本件**第一次**（直调 `session_inner.sh`，11:23）漏了装置的 `cp -a shots` 步骤 ⇒ 当时仓内 `shots/` 仍是 `03:14` 那趟的帧（`ef3fd6765f18f51b`）、而 `leg_*.env` 是 11:24 的 ⇒ **那一刻是不同趟**。我**没有**拿它当证据；已用**正式跑（11:25）**把三者对齐，并把第一次的帧另存车道（`~/t119-runner/bak/run-N3-shots/`）留档。**这一条与契约 §2 实例（`02:48` 那趟）是同一类陷阱**，本件**现场又踩到一次**，故如实登记。

---

## §6 症状零回归 ／ 哨兵 ／ 受影响牙

```
两页症状（本趟）：k23 alive=yes app_rc=143 magenta=0 colors=384 ns=…RichTextBoxDemo  ae=15385 ink=480000
                  k24 alive=yes app_rc=143 magenta=0 colors=384 ns=…FlowDocumentDemo ae=0     ink=480000
APP_RC=143（SIGTERM，仪器收的）⇒ 零回归（无 134/139）
哨兵：SSC=PASS lines=13 keys=13 cmp=IDENTICAL（.so/pf 本趟未换代 ⇒ 无陈旧位；写哨兵是队长的动作，本件未自改）
牙：PIPEFAIL_SIGPIPE=PASS rc=0（files=114 runs=12）
    REPORTID=PASS rc=0（files=252 ids=2202 declared=224）
    HANDOFF_MV=PASS rc=0（cells=9 equal=8 manual=1 mismatch=0）← 本趟追写 `cell=#1`（654→655 行，纯 `>>`）
    DEFREG：未跑（本件未改路由/注册表件）
```
⚠️ **`HANDOFF_MV` 一开始是 `DIVERGED`**：因为 `evidence/**` **在 `fp_inputs()` 覆盖面内**（现取 `close-wave.sh:245-252` 明写"装置四件＋`evidence/` 十六件"）⇒ 我重取证据**必然**移动 `inputs_fp`（`2a69c310…`/`b1624c7b…` → **`f027a1025aa404924f1e3ab5272509c4de10b13ed751a623ea47df9e1cea565e`**）⇒ 按纪律第 `28` 条同趟追写 `cell=#1` 后转 **PASS**。

---

## §7 边界遵守自证

**写域**：`build/MilBridge/P1-realized-probe-report.md` ✓｜`build/MilBridge/tests/PtsPagesProbe/evidence/**` ✓（同趟重取）｜`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行 ✓。

**未动（硬条款）**：`src/**`｜`build/PresentationCore.Linux/**`／`build/WindowsBase.Linux/**`｜`build/MilBridge/tools/**`（守卫）｜`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`｜**判据件一字未改**。
⚠️ **装置件 `run-pts-pages-legs.sh` 曾被临时替换（为换点击次序）**，**跑完立即 `git checkout` 还原**；现取 `git diff --stat -- build/MilBridge/tests/PtsPagesProbe/` **只剩 `evidence/**`**。**这是"临时借用装置目录"，不是"改装置"** —— 如实点名，不当作没发生。

**`git status --porcelain`（`M` 行，收尾现取）**：
```
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/{app_g1.log,device.txt,device/xfwm.log,leg_23.env,leg_24.env,session.txt}
 M build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png
```
⇒ **全部在写域内**。

**纪律**：**28** `cell=#1` 纯 `>>`（654→655）＋ `inputs_fp` 现取 ⇒ `HANDOFF_MV=PASS`｜**29** 改动前整目录备份 `~/t119-runner/bak/evidence.pre-t119`（29 件）＋ `HANDOFF-NEXT.md.pre-t119`；第一次（非正式）那趟的帧与 `app_g1.log` 另存 `run-N3-shots/`／`run-N3-app_g1.log` 留档｜**30** 本件所引读数**全部是批式件读数**（`sha256sum`／`compare`／`shotstat.py`／`grep -c`）＋ `session_inner.sh` 的**每趟**字段，**不含**"进程内状态敏感仪器"的跨趟引用；**两种误导形态**：① **"带历史的红＝假红"**本件实测一例（第一次那趟帧与 env **不同趟**，若拿它当证据会得出错判）；② **"净腿不崩＝假绿"**在本族的表现是**"进程活着但两页都没绘出内容"**（`alive=yes` ∧ `ENFE_TOTAL=1152` ∧ 两帧相同）⇒ 本件**未**以 `alive=yes` 为内容证据。
**显示位**：只用 `:248`／`:249`（私有 `:2xx`），几何 `1280x1024x24`；**按 PID 收尾**（`REAPED xvfb=… xfwm=…`）；**未用** `pkill`／`pgrep -f`；跑前后扫 `/proc`（排除 `$$` 与祖先链）**零残留**、`/tmp/.X11-unix` 只剩 `X0 X1`。
**未** `git add`／`commit`／`push`；**未**跑整趟门禁。

---

## §8 未做项与原因

| 项 | 状态 | 缺什么 |
|---|---|---|
| `N4` 正身份（该页专属期望指纹） | **NOINFO** | 需另派单登记"已知良好渲染"的该页帧 `sha256` 或该页专属结构读数（契约 §6-`NOINFO①`） |
| `N1` 的空态参照集维护 | **欠着** | 本趟空态已换版（`ef3fd676…` → `1a76488a…`）而参照集未更新 ⇒ 需一个"谁在何时重登记"的归属（契约 §6-`NOINFO④`） |
| `N2` 的守卫接线 | **NOINFO** | 让守卫读 `ENFE_TOTAL` 落在 `build/MilBridge/tools/**`（**不在本件写域**）⇒ 另派单 |
| 「两页真排版」 | **不成立**（本件复核） | `ENFE_TOTAL=1152`（`FsCreatePageBottomless` ×1151）；画面是空态/回退页 ⇒ 与契约 §4 的"相位翻转硬前置"一致：**此刻翻相位 ⇒ 判据放松** |
| `N3` 的"两帧必须不同" | **未达成（判红）** | 已按例外支给出**可判证据**（§1.3）；**未**改点击坐标/改仪器去凑"不同"（硬条款） |

---

⏪ **dated 追记（`t136`／scribe，读时 `2026-09-29T14:3x+0800`；只增不改 —— 本件上方原文一字未删）**：本件当初在 `N1②`（"每次点击后 `AE(上一帧,本帧)>0`"）上**引用 `N3` 的例外支免红**。按 `t136` 把**例外支条件写死**后的口径 —— **例外仅当两页「内容定义」相同**（须有该相同的**正证据声明**）**且两页都确已绘出内容**（两腿 `ink>0`）；**「两页都没绘出内容」不构成例外** —— **本例不满足例外**（本件 §1／§2 自陈两页**都没有把自己的内容绘出来**、都停在同一个空态／回退画面）⇒ **该"免红"不成立**，`N3` 的"两帧必须不同"**维持红**。⇒ 本件 §2（其「该例外**成立**，故 `N1②` 不因此红」处）与 §5 表格里"已按例外支给出可判证据"的读法，**按本行作废**（原文保留、以本行为准）。判据侧写死条件见 `build/MilBridge/P1-realized-criteria-report.md` 的 `t136` dated 段③；守卫侧实现与成对读数见 `build/MilBridge/P1-guard-n1-n3-tighten-report.md`。
⚠️ **本件末行自证仍是字面 `PLACEHOLDER`**（本席**未**改写它 —— 派单禁"就地改写原文任何一行"）⇒ 按同口径（`head -n -1 <本件> | sha256sum | cut -c1-16`）：**本行插入前**（177 行版式）＝ **`ca38c9d5a569ed4c`**（可用备份 `~/w281-scribe/t136/bak/P1-realized-probe-report.md.pre-t136` 复算）；**本行插入后**的正确填值**不得**写在件内（写进来就等于把自己的哈希算进去 ⇒ **自指**）⇒ 该值已记在 `build/MilBridge/P1-guard-n1-n3-tighten-report.md` 的成对读数里，**件主（`t119`／`t120` 车道）填该行时按那条读数取用**。
`P1-REALIZED-PROBE-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ PLACEHOLDER（口径＝末行之前的全文；末行＝本行）`
