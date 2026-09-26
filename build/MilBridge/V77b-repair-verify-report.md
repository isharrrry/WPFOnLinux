# `V77b-repair-verify-report.md` —— `t18`：`#77` **关账**的独立复验（车道 `verifier`）

- 对象：`t17` 对 `t6` 判 `failed` 那批账（F1–F7）的关闭情况。`N=/home/links-dev/netTest/GitProj/WPFOnLinux`，`HEAD=3c302ce4d0c1b418cd43d15d50135d982ca570f1`
- 判据：**先写**于 `~/w27x/criteria-t18.md`（早于一切读数）｜方法：与 `t6` 同法 —— **把那一行真跑**（不是看源码），且凡写"零命中"必先让判据**红一次**
- 区间：2026-09-26 22:21 → 22:4x｜资源现取（重活前）：`df -Pk /` 第 4 列 = `113601392 KB`；`MemAvailable` = `8932 MB`；`free -m` `Swap` 行 `free` = `1312 MB`（`#77` 收尾曾掉到 1306 ⇒ 本件**未**跑 `verify-all`，无长跑）
- 写域：本报告是**唯一**写入 `$N` 的件；`~/w21-verify/**` **零写入**（只读）；夹具/日志在 `~/w27x/**`

---

## 0. 结论一句话

**F1–F7 七条验收我逐条独立复算，全部通过**（F1 = 22/22 真跑解析到 `$N` ＋ 扩面 188 件/147 条派生式**零洞** ＋ 控制腿 5/5 会红；F2 = `porcelain=0` 且**不是丢弃**凑的；F3 = 冻结块逐位未改、dated 更正落对件、待办可执行；F4/F5/F6 = 断言**真会红**；F7 = 7 臂两极化独立复现、活冻结器已回退且**可逆**）。
**但同一族（仓外可执行默认值）没有清干净**：我**有界**扫到 **4 处**非注释旧路径默认值不在 `t17` 清单里，其中 **`~/w183a/new/display-lease.sh:41`** 是 `~/w183a/landing.sh:70` 明确引用的**待命包源件**、而仓内**尚无**该件 ⇒ **一旦落地就把旧路径带进仓**（`R_DEFAULT` 现指**已被撤除**的符号链接），且**新牙的 roster 看不见它**（只覆盖 22 条在册派生式）。详见 §8-①。

---

## 1. F1（本环最重要）：22 条派生式**真跑** ＋ **主动扩面**

### 1.1 22 条逐条真跑（不是看源码）

方法（`~/w27x/repoint-exec.py`，`t6` 用过的那一支）：把 `${BASH_SOURCE[0]}`／`__file__` **注入成该件在仓里的真实路径**（运行时 shell/python 给的就是这个值），写成临时脚本**真执行**，再与 `readlink -f $N` 逐字比。

```
REPOINT_LIVE=PASS 处数=22 命中(==N) 22 不符 0
（`N` = /home/links-dev/netTest/GitProj/WPFOnLinux；`readlink -f $N` 与 `$N` 逐字相同 ⇒ 物理路径同一）
```
- **22/22 命中**；对比 `t6` 的读数 **`17/22`（5 处不符）** ⇒ 5 处 `dirname` 层数确实被修好。
- 5 处修复件的 sha16 **与我现取逐一相同**（＝它自报的 after 值）：`frames-gen.py` `87d8cd0dfcf3a665`／`analyze-layout-b34.py` `c783ff683ebaea2e`／`extract-layout-b34.py` `59b563eb57b62cee`／`t1c-inputtrace-verify.py` `5cec72436bfb0ac8`／`w81a-a0-analyze.py` `317da8dc21cedf5e`；`git diff 3c302ce4^..3c302ce4` 五件**全为 `M`**。

### 1.2 消费点存在性（**5/5**，含判别力约定）

| 件 | 变量 | 消费后缀 | 拼接结果存在 | **错根形态**存在 |
|---|---|---|---|---|
| `frames-gen.py:33` | `REPO` | `build/DirectWrite.Linux/wic-shim/fixtures-jfif.jpg` | **True** | False |
| `w81a-a0-analyze.py:28` | `_ROOT77` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **True** | False |
| `analyze-layout-b34.py:12` | `ROOT` | `build/MilBridge/gen/layout-b34-compact.json` | **True** | False |
| `extract-layout-b34.py:13` | `ROOT` | `tests/parity/windows/layout-b34/windows-results.json` | **True** | False |
| `t1c-inputtrace-verify.py:32` | `ROOT` | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py` | **True** | False |

`消费点存在 5/5`（与牙自报 `consume=5 consume_ok=5` 同值）；"错根形态不存在"这一列是**判别力**的体现：用错根拼出来的路径**不该**存在，否则那一档会失去意义。

### 1.3 **扩面搜索**（主判据；含未在 21 件名单里的件）

范围与命令（可复算）：
```
cd $N && find . -path ./upstream -prune -o -path ./.git -prune -o -type f \
     \( -name '*.sh' -o -name '*.py' \) -print      # SCAN_SET = 188 件
命中式 = 行内同时含 dirname 链 与 ${BASH_SOURCE[0]} / ${BASH_SOURCE} / __file__   ⇒ 147 条
每条：真跑求值 → 比 readlink -f $N；再取**第一个字面消费点后缀**判 os.path.exists
```
| 判定 | 条数 | 说明 |
|---|---|---|
| 根解析 == `$N`（且仓根相对消费点全在） | **34** | 含 roster 的 22 条 **∪ 12 条不在 roster 的根变量站点**（`verify-all.sh:194`／`build/close-wave.sh:31`／`build/integration-wave.sh:15`／`frame-step.sh:60`／`hidden-only-step.sh:158`／`pc-line-step.sh:33`／`product-entry-step.sh:44`／`publish-milbridge.sh:24`／`bridge-src-fp.sh:38`／`check-fp-polarity.sh:17`／`tests/flaky-loop.sh:18`／`scan-milcore-dllimports.py:14` …） |
| 根解析 ≠ `$N` 且**消费点缺件**（判洞） | **0** | —— |
| 根解析 ≠ `$N` 但消费点都在（BENIGN） | **113** | 全是**自指目录**类（`HERE/SELF_DIR/SCRIPT_DIR/here` 等，语义上就该 ≠ 仓根）＋ 1 条经复核后归此类：`build/MilBridge/run.sh:27  MB=$N/build/MilBridge`（**MilBridge 自己的目录**；其 20+ 个消费点**全部存在** ⇒ 按"消费点"这条决定性判据判 BENIGN，不是洞） |

`F1_V2 exprs=147 root_ok=34 suspects=0 benign=113` ⇒ **仓内零洞**。
- ⚠️ 我**把 v1 的假阳性也留档**：v1 把 `$(basename …)` 这类**动态后缀**当字面量 ⇒ 12 条"洞"全是假的；v2 收紧成"字面后缀 ∧ 以仓根顶级目录名起头"＋"动态后缀一律 BENIGN"。**不写这一段就等于掩盖我自己的仪器缺陷。**

### 1.4 控制腿（证明"零洞"不是恒绿）

- **控制腿 A（同一判据跑修复前的件）**：把 `3c302ce4^:<5 件>` 的那一行表达式注入**真实自指路径**真跑 ⇒ 解析结果 `$N/build`（`frames-gen.py` 为 `$N/build/DirectWrite.Linux/wic-shim`）⇒ 我的判据**5/5 全判洞**。
- **控制腿 B（牙自身在我造的形态上会红）**：沙箱镜像里把 **`t1c-inputtrace-verify.py`**（**不是**它 selftest 用的那一件）砍掉一层 `dirname` ⇒ 牙打 `WFREEZE_ROOTDEFAULT_HIT file=build/MilBridge/tools/t1c-inputtrace-verify.py line=32 var=ROOT …` ＋ `WFREEZE_ROOTDEFAULT=FAIL exprs=22 ok=21 bad=1`。

### 1.5 牙自身我复核了什么

- `ROSTER` **22 条**：逐条取现盘第 N 行 ⇒ **行号/变量名 0 条不符**；件集合与我从 `git grep` 独立推出的 21 件**逐件相同**（两个方向的差集都为空）。
- 它在真树：`WFREEZE_ROOTDEFAULT=PASS exprs=22 ok=22 bad=0 consume=5 consume_ok=5`；`--selftest` ⇒ `cases=5 pass=5 fail=0`。

---

## 2. F2：`porcelain=0` **不是靠丢弃**凑的

```
git status --porcelain | wc -l      → 0
```
⚠️ 这一读数是**在本报告落盘之前**取的（读数时刻 `porcelain=0`）；本报告落盘后 `porcelain` = **1**（= 本报告自身 `??` 未跟踪），与本条验收无关。

```
git show --name-only 3c302ce4 | grep -cE 'SR.g.cs|ARTIFACT-SRC-FP|PORT-CHANGES|applocal-selftest|wave-audit|parity-results|V77-verify-report'  → 16
```
逐件核（**16/16 在提交里**，且**每一件都与父提交 blob 不同** ⇒ 是"带新内容入笔"而不是"退回旧内容再提交"）：

| 件类 | 读数 |
|---|---|
| `build/*/SR.g.cs` ×8、`PORT-CHANGES.md`、`parity-results.json` | HEAD 带**新路径**（`GitProj/WPFOnLinux`）1～3 处、**旧路径 0 处**、与父**不同** |
| `build/*/ARTIFACT-SRC-FP.txt` ×3、`.applocal-selftest.log` | 内容是指纹/日志（本就不含路径）；**与父不同** |
| `tests/parity/linux/parity-results.json` | 新路径 1、旧路径 0、与父不同 |
| `build/wave-audit.log` | 🔎 HEAD 里旧路径 **154** 处 —— 这是**历史日志行**（`cwd=…旧路径…` 是当时的现场记录），**不是**丢弃；与父不同（新增了本波条目） |
| `build/MilBridge/V77-verify-report.md` | 🔎 旧路径 2 处 —— 是 **`t6` 报告正文里的引文**（旧路径重指向那张表的"改前"列）；与父不同（本波新增） |

- **反丢弃的三条判据齐**：① `porcelain=0`；② 16 件逐件 `git cat-file blob HEAD:` 现取比对（工作树 == HEAD）；③ **HEAD 内容 ≠ 父提交内容**（`git restore` 的形态恰好相反：退回旧内容 ⇒ 与新提交逐字节相同且**带旧路径**）。
- **控制腿**：同一"旧路径"探测器打在**父提交** blob 上 ⇒ 报出 1／154／3／1…（能命中）⇒ 上面"新路径在、旧路径 0"不是恒零的假证据。
- 我**没有**去猜他们的命令历史（不可见）；我判的是**内容形态**，这与 `D-G108`（隐藏状态）要的正是同一件事。

---

## 3. F3：冻结块**未被改** ＋ 更正落对件 ＋ 待办可执行

```
sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16   → e3ebc811641bd467   （== #77 冻结值，逐位相同）
git log --oneline -3 -- samples/WpfTextDemo/ACCEPTANCE-BASELINE.md  → 0666559 / 9cea5cc / f56d879
```
⇒ 最后碰它的是 **`#77` 的落仓提交 `0666559`**，**不是**本修复提交 ⇒ 冻结块**没被改**。

dated 更正（现取打印到的行）：
- `docs/WAVE77-PREREGISTRATION.md:207-209` §8.3 —— 逐字写出事实：「`#77` 冻结块的**九位行**写 `provider` `1f9511a7ef395bfe`（＝`#76` 值），而同块位移行与**全部** `BASELINE tier=` 机读行写现值 `4041df9a704abfed` ⇒ 同块两个授权来源互相矛盾」＋根因（模板写死字面量、`_PREV_SRC` 7 键与 `_TIER_MAP` 5 位都不含 `provider`）。
- `docs/ROUTES.md:724+`（§15ae 波 `#77` 修复记账）／`build/MilBridge/HANDOFF-NEXT.md:31`（§4-追 dated 更正）同在。
- **可执行的待办**：§8.3 第 212–213 行给出了**改哪个键表、加什么、期望读数**：`_PREV_SRC` 增 `'prev_provider'`／`'prev_wic'`（含逐字正则 ``'`provider` `([0-9a-f]{16})`'``）＋ `_TIER_MAP` 增两条 ＋ `GENS[gen]` 相应增键（并写明"否则 `skipped=` 会响亮点名"）⇒ **具体到可执行**，不是"要补一下"。

---

## 4. F4／F5：更正与读数一致，且断言**真会红**

**F4**（我自己现算，不看它的日志）：

```
判词域行数 post1=129 post2=129
diff post1 post2 | grep -c '^[<>]'   → 24          （= 12 行 × 两侧）
逐字段分类（python 逐 K=V 比）：
  路径/临时目录/跑次戳目录（含 at= 时间戳） 8 处 ｜ 环境余量（avail/avail_kb/mem_mb） 3 处 ｜ 耗时（wall_s/held） 2 处
  **OTHER（＝读数域字段）= 0 处**
```
⇒ 更正文本「**读数域差异 0；标签/环境类差异 24 行**（路径／跑次戳／环境余量／耗时逐类点名）」与现算**逐项相符**；它**没有**再写"唯一差异是 `wall_s`"。

**F5**（两极化我**自己**跑，用**生产旋钮 `--root`**，不用它 selftest 的 `--decl-override`）：

| 腿 | 输入（我造的） | 读数 | 判定 |
|---|---|---|---|
| 正极 | 沙箱 `docs/` 放**真** `WFREEZE-DECL:` 行 | `WFREEZE_DECL=PASS gen=#77 allow_changed_decl=dwf,pc,pf,provider,windowsbase allow_changed_gens=… pf_required_decl=False pf_required_gens=False` | ✓ |
| 反极① | 把 `pf_required` 改成 `True` | `WFREEZE_DECL_HIT pf_required decl=True gens=False` ⇒ `WFREEZE_DECL=FAIL` | ✓ **真会红** |
| 反极② | 把 `allow_changed` 从五格改成 `pf`（＝`t6` 抓到的那个字段） | `WFREEZE_DECL_HIT allow_changed decl=pf gens=dwf,pc,pf,provider,windowsbase` ⇒ `FAIL` | ✓ **真会红** |

机读声明行现取存在（2 处）且与冻结器 `GENS['#77']` 逐字段一致；牙档②用 **AST 只读抽 `GENS`**（我读了源码确认不是文本 grep）。

---

## 5. F6：两条「权威」路径的牙**真会红** ＋ 权威判定**有依据**

- 真树：`WFREEZE_NINEAUTH=PASS pairs=2 ok=2 bad=0`。
- **我造的形态（生产旋钮 `--root` 沙箱）**：两条路径内容**相同** ⇒ `PASS`；把 `build/PresentationCore.Linux/bin/Release/…Provider.dll` 改成不同内容 ⇒
  `WFREEZE_NINEAUTH_HIT kind=diverged canon=build/DirectWrite.Linux/Provider/bin/Release/…=559aead08264d579 copy=build/PresentationCore.Linux/bin/Release/…=df7e70e5021544f4` ⇒ `FAIL pairs=2 ok=1 bad=1` **并点名两条路径与各自 sha16** ✓。
- **「哪一条是规范权威」的依据（三条读者，现取）**：
  ```
  ~/w21-verify/w27-freeze.py:1377   ('provider', f'build/DirectWrite.Linux/Provider/bin/{CFG}/DirectWrite.Linux.Provider.dll')
  build/DirectWrite.Linux/wic-shim/applocal-expect.py:104   REPO + "/build/DirectWrite.Linux/Provider/bin/" + CFG + "/…"
  build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:191  $REPO/build/DirectWrite.Linux/Provider/bin/$SELFBUILT_CONFIG/…
  ```
  ⇒ 判据的**读者**都在读它 ⇒ "规约权威 = 工程产出目录"不是随便选的名字 ✓（`CFG` 现取 `Release`，与唯一声明 `build/SelfBuiltConfig.props:28` 一致——我在 F7 驱动器里现取断言过）。
- ⚠️ **随之的现场后果（如实，不是它的缺陷，但要记账）**：副本被刷成权威后 `provider` 权威值 = `609192a419d125f2`，而**在册九位/`#77` 冻结块**仍是 `4041df9a704abfed`（块的九位行更旧：`1f9511a7ef395bfe`）⇒ **"现读九位 vs 冻结记录"这一对今天仍不一致**；牙档③只钉"两条路径彼此相等"，**不钉"与冻结记录相等"**。

---

## 6. F7：私有沙箱**独立两极化** ＋ 回退状态与可逆性

驱动器 `~/w27x/f7-indep.py`（从**归档件** `versions/w27-freeze.py.w77e-0745-installed-f9fb7bcac0353a61` 用 `ast` 逐字抽出 `_BLK_HDR/_NINE_HDR/_PREV_SRC/_TIER_MAP/_block_of_prev/check_prev_values/check_record_forms/GENS/NINE` 后 `exec`；语料 = 冻结器自己写出的**真 `#77` 块**）。

| 臂 | 读数（我的复算） | 与它自报比 |
|---|---|---|
| ARM1 现行语义（`check_prev_values`，表 = `GENS[#77]` 的 `prev_*`，搜**本代块**） | `bad=7 checked=2 skipped=[]`；**MISMATCH=5**（`prev_dwf/prev_infp/prev_pc/prev_pf/prev_wb`）＋ **TIER-DISAGREE=2**（`prev_pc/prev_pf`） | **逐条相同**（含"5＋2、checked=2"）✓ |
| ARM1b 交叉核（`check_record_forms` 同一块同一表） | `bad=7`（同 7 条）／`checked=7` | 我另加：**同一现象、不同计数口径**（该函数把"命中数==1"的键全计入，`check_prev_values` 只计"相符"的）——两处口径不同但**不冲突** |
| ARM2 同一块 × **块内现值表** | `bad=0 checked=7` | 同它 ✓（⇒ 现象归因于**语义**而非块） |
| ARM3 v2 设计（键表 = 九位全部含 `provider` ＋ `inputs_fp` ＋ `BRIDGE_SRC_FP`）跑**真块** × **本代值** | `bad=2`：`provider`（块 `1f9511a7…` vs 现值 `609192a4…`）＋ `_nfp`（块 `b67560f2…` vs 现值 `99db4fb5…`）—— **分开点名** | 同它 ✓ |
| **ARM3B 写对的本代块** | **`bad=0`** | ✓ ——**"有位移的真实世代必须 `bad=[]`"这一格成立**（被咬过的那一格） |
| ARM4 机读形态**缺失**（删 `inputs_fp` 行） | `bad=1`：`HITS!=1 key=_nfp hits=0` | ✓ |
| ARM5 形态**重复**（整行复制） | `bad=1`：`HITS!=1 key=_nfp hits=2` | ✓ |

`F7_INDEP=PASS arms=7 pass=7 fail=0`
- v2 的**规格由它公布、实现由我重写**（另有它自己的 `~/w186a/w77rep/bin/f7_design.py` 作第二实现）：两套实现**结论逐条一致**。
- **回退状态与可逆性**（现取）：
  ```
  sha256sum ~/w21-verify/w27-freeze.py                                   → 6bf3c5c77eee8dd8
  grep -c 'def check_record_forms' ~/w21-verify/w27-freeze.py            → 0
  ls ~/w21-verify/versions/w27-freeze.py.w77e-0745-installed-f9fb7bcac0353a61 → 在位（140282 B，mtime 21:51）
  sha256sum 该归档件                                                     → f9fb7bcac0353a61  （== `t6` 记录的"已装"版）
  sha256sum versions/w27-freeze.py.w77d-6bf3c5c77eee8dd8                → 6bf3c5c77eee8dd8  （== 活件）
  ```
  ⇒ **已回退** ∧ **已装版有归档** ⇒ **可逆** ✓（我**没有**写 `~/w21-verify/**`）。

---

## 7. 账目同趟（我独立复算）

| 项 | 它自报 | 我现算 | 判定 |
|---|---|---|---|
| 覆盖面 | 211 → **212** | `infp.sh list \| wc -l` = **212**；`sort -u` = 212 | ✓ |
| `inputs_fp` | `99db4fb5…` | `99db4fb5 92aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709` | ✓ |
| **独立第二实现** | （它说保留 `~/w-infp-at.sh` 为互核材料） | `bash ~/w-infp-at.sh $N fp` = **同值**；`n` = **212** | ✓（⇒ `infp.sh` 被本波改过，但值经**两条独立实现**互证） |
| 第 `[42]` 步常数 | 212 | `verify-all.sh:1173 run_step "FP-MANIFEST-TEETH" … --expect 212` | ✓ |
| 新牙入覆盖面 | 是 | `build/close-wave.sh:374` 白名单里有 `wave-freeze-consistency-check.py` | ✓ |
| 接线位置 | `close-wave.sh [5c/6]` 冻前 | `build/close-wave.sh:641` `run "[5c/6] …" python3 … --root "$ROOT"`，位于 `[5/6] verify-all`（:609-611）与 `[6/6] 汇总`（:644）**之间**；注释逐字写明"此时读的是最终态 ∧ 红 ⇒ `run()` 当场 `exit` ⇒ 汇总与两哨兵都不落" | ✓ |
| 冻结器 | 一字节未动 | 活件 `6bf3c5c77eee8dd8`、`check_record_forms`=0（见 §6） | ✓ |
| 牙自身 | `--selftest 5/5` | 我另跑 ⇒ `cases=5 pass=5 fail=0`；真树三档 `PASS` | ✓ |
| `DEFREG` | `declared=182`（三个建议号**不在** ID 域） | 未复算（见 §9-N5） | NOINFO |

---

## 8. 我推翻/打折扣的话（逐条）

1. 🔴 **「仓外可执行默认值一族已清干净」——**不成立**（同一族还剩 4 处，且其中一处会把旧路径带进仓）**。
   有界扫描范围与命令：`grep -rn --include='*.sh' --include='*.py' 'wpf-linux-20260906' ~/w18?a ~/w19?a ~/*.sh`，再剔掉 `:` 起头为注释的行；命中的**非注释**站点逐条判：

   | 站点 | 形态 | 判读 |
   |---|---|---|
   | **`~/w183a/new/display-lease.sh:41`** | `R_DEFAULT="…/wpf-linux-20260906/wpf-linux"` ＋ `:42 R="${R:-$R_DEFAULT}"` | 🔴 **待命包源件**：`~/w183a/landing.sh:70` `SRC_DEV="$PKG/new/display-lease.sh"` → 落到 `build/MilBridge/tools/display-lease.sh`；**仓内现无该件** ⇒ **落地即把旧路径写进仓**（`R_DEFAULT` 指的路径**已不存在**：`…/wpf-linux-20260906/` 下现在只有 `README-why-this-link-stays.md`）。`t17` 的清单里有 `w183a/landing.sh`／`w183a/rehearse.sh`，**没有这一件** |
   | **`~/w184a/stage/landing.sh:26-27`** | `R=…` ／ `AUTHORITY=…`（行内注"权威树真路径（逃逸闸③的判据）"） | 🔴 落地/排练驱动自身带旧路径默认值；**直接推翻它那句「`w184a` 无（其 9 处命中全是注释/报告）」** |
   | `~/w183a/sandbox/src-dev.sh:41`、`~/w183a/sandbox/repo/…/display-lease.sh:41` | 同上（+`R=`） | 沙箱副本 ⇒ 按它的划界属"证据类"（**不改**是对的），但与上面那件**同源** ⇒ 修包件时要知道沙箱里那份也是旧值 |
   | （旁证）`~/w185a/w77/out/*.py`：21、`~/w185a/w77/staging/0745/patched-freezer.py:21`、`~/w186a/w77rep/backup/**`、`~/w185a/w77/bin/{docs77,repoint,patch2}.py` 里的旧路径 | 数据/字符串/备份 | **不改**是对的（备份若被改就不是备份） |
   - **为什么这条值钱**：它正是你在派单里点名的"**门禁看不见的洞**" —— 新牙的 roster 是**固定 22 条**（我核过：行号/变量/件集合都对，但**不在名单里的站点它看不见**），所以**"落地时把旧路径带回来"这件事今天没有任何牙会响**（`verify-all` 的 `[48] WIRING-COVERAGE` 只管"已接线的件 ⊆ 覆盖面"）。
2. ⚠️ **「（F1 的）22 条」与"全仓根派生式"不是一回事（打折扣，不推翻）**：我扫到 **34** 条根变量站点，其中 **12 条不在 roster**（`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`frame-step.sh` …）。它们**今天全部解析正确**，但**同样没有牙看着**。它的报告 §F1-射程缺口已如实写"只覆盖 roster 22 条" ⇒ 我把**具体漏在哪 12 条**补上（这是它没给的粒度）。
3. ⚠️ **`checked` 口径**（打折扣）：它 ARM1 报 `checked=2`，我复算**同值**（用 `check_prev_values`）；但若用 **`check_record_forms`** 跑同一块同一表 ⇒ 同一 7 条 bad、`checked=7`。两处**口径不同**（"相符键数" vs "命中数==1 的键数"），**不是矛盾**，但报告里若不写清，下一位复核者按另一支读会对不上。
4. ⚠️ **"F6 已关账"要加一句**：牙钉住的是**两条路径彼此相等**，**不钉**"与冻结记录（在册九位）相等"；今天 `provider` 现读 `609192a419d125f2` ≠ 在册 `4041df9a704abfed`（块内更旧 `1f9511a7ef395bfe`）⇒ 这条**仍需主控在下一版冻结里一次性收口**。
5. ⚠️ **牙的 `--root` 默认与相对式**（边界）：`sec_rootdefault` 的 `.sh` 支路 `bash -c 'set -u\n<行>\necho "${VAR}"'` **不 `cd`**；今天 roster 的 22 条都是 `${BASH_SOURCE[0]}` 绝对式（与 cwd 无关）⇒ 无影响；**若**将来 roster 收进 `$(cd .. && pwd)` 这类相对式，判定会取决于调用者 cwd（记 `NOINFO`）。

---

## 9. 边界与 `NOINFO`

| # | 项 | 原因 |
|---|---|---|
| N1 | 仓外**全量**（1,299 处）的"证据类 vs 可执行件"分类 | 我只做了**有界**扫描（`~/w18?a`／`~/w19?a`／`~/` 顶层 `*.sh`）；`~/w*/tree|sandbox|backup|staging|patch` 这类证据位**未逐件判**（判了就等于要改证据件） |
| N2 | `w183a/new/display-lease.sh` 是"待命包源件"还是"历史档" | 我按 `w183a/landing.sh:70` 的 `SRC_DEV=` 引用判为**待命包**；**归属由主控裁** |
| N3 | 我**未**跑 `verify-all`（本件无重活） | 本任务不需要；因此不改 `inputs_fp`、不写 `$N` 任何派生件 |
| N4 | `t17` 的仓外重指向是否**逐件**两极化（E1/E2 逃逸闸那一套） | 我只看**现盘解析**与 `landing.sh` 的调用点，未复跑它的排练链 |
| N5 | `DEFREG declared=182` 与三个建议号（`D-G149/150/151`）是否入册 | 不在本件验收面（属登记册写域）；它自己也已如实报"建议号不进 ID 域" |
| N6 | `TASK-0744` 线上等长替换真腿 | 与 `t6` 同（仓内零装置）⇒ 仍未独立复跑（沿用它的 `NOINFO`） |
| N7 | 我**没有**验证 `~/w21-verify/**` 之外的"主控写域" | 按派单不碰 |

---

## 10. 复算命令索引（第三者可按此重跑）

```
# F1：22 条真跑 ＋ 扩面
python3 ~/w27x/repoint-exec.py            # 22/22（旧版 v1 的 5 处不符读数留档在同文件的历史输出）
python3 ~/w27x/f1-expand2.py              # 188 件/147 条派生式/root_ok=34/holes=0/benign=113
python3 ~/w27x/f1-expand.py               # v1（含我自己的假阳性 12 条，留档用）
# F1 控制腿（修复前的件必须被判洞）
git show 3c302ce4^:build/MilBridge/tools/analyze-layout-b34.py | …（见报告 §1.4 的脚本）
# F2
git status --porcelain | wc -l ; git show --name-only 3c302ce4 ; git cat-file blob HEAD:<16 件> vs HEAD^:<同件>
# F3
sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16 ; git log -3 -- <baseline>
grep -n 'provider' docs/WAVE77-PREREGISTRATION.md   # §8.3 / §8.4 / §7.7
# F4
grep -E '…' ~/w185a/w77/logs/w77-post{1,2}-*.log > judge.txt ; diff … | grep -c '^[<>]'   # 24
# F5/F6 两极化（生产旋钮）
bash ~/w27x/tooth-polarity.sh
# F7
python3 ~/w27x/f7-indep.py                # F7_INDEP=PASS arms=7 pass=7
# 账目
bash ~/w153a/bin/infp.sh fp ; bash ~/w153a/bin/infp.sh list | wc -l ; bash ~/w-infp-at.sh $N fp
grep -n 'wave-freeze-consistency' build/close-wave.sh
```

`V77BVERIFY=DONE verdict=pass(F1-F7 七条全过) f1=22/22+expand188/147/holes0 f1_control=5/5_red f2=porcelain0_16件入笔 f3=baseline_unchanged_e3ebc811641bd467 f5=decl_2极真红 f6=nineauth_2极真红 f7=7臂独立复现+回退可逆 residual=仓外一族4处(2处为landing包源件) noinfo=7`

`SELF_SHA16=b764d994bae696ca`（**口径 = 去掉本行**：`head -n -1 build/MilBridge/V77b-repair-verify-report.md | sha256sum | cut -c1-16`；自指件只报这一个口径，第三者按上式可逐位复算）
