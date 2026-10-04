# V80 · `t72` 重开 —— 对 HEAD 那一笔 `6cdb7df9` 的**独立复核判词**（`verifier`）

- **被核对象**：`6cdb7df9408ee230b9c2fb01ef5c65a8eb179750`（`HEAD`），父 `3295f3e509b5a2f463aba0f5f2fa2f0f92e44df3`，`%cI = 2026-09-28T13:48:20+08:00`。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）。
- **读取时刻**：本件所有读数在 **`2026-09-28T14:00:44` – `2026-09-28T14:07:08 +0800`** 之间现取（逐条命令见 §1；命令与其读数是同一趟的）。
- **载体**：本件（`build/MilBridge/V80-t71FIX-verify-report.md`）。我**只写这一件**；`$N` 内其余件一字未动（收尾 `porcelain=0`，见 §5-末）。
- **判据先行**：本件判据逐字抄自队长派单五条 ＋ `~/wcaptain-audit/KICKOFF-NEXT-WAVE.md` §7 第一条（**只读引用**）；**我不复述任何既有报告/提交信息的说法** —— 下面每个数字都是我自己写的抽取器算的。

---

## §0 结论速览（逐条判词）

| # | 判据 | 判词 |
|---|---|---|
| 1 | 三组域值自算（`86/84/82`） | **成立**（三组逐格复现，与现文**逐字相同**）；⚠️ 附一条**口径缺口** F3：该行未声明"区" |
| 2 | `6／1` 未改 | **成立**（🔴 `6` 行、⚪ `1` 行**逐行复活**，且**新增 4 行未扰动该域**：父代与本笔逐格相同） |
| 3 | 五处未来戳（原名保留 ＋ 更正句给真实读时） | **(a) 成立**（5 行**逐字节相同**）；**(b) 成立**（更正句在位、秒级、读时 < 落盘）；⚠️ 附 F2（`9 分 53 秒` 与同句 mtime 不符）与 F5（`13:47:44` 不可对拍） |
| 4 | 六个内容锚 ＋ "行号仅本次有效" | **成立**（六号"读时/写后"两组值**逐格复现**；内容锚与声明在位）；⚠️ 附 F4（`TASK-0201` 锚在 `§13` 内**非唯一**） |
| 5 | 推送与哨兵次序 | **取值成立 /次序部分不符**：哨兵**十键全部＝现取值**（我独立重算 10/10，含块值反证）；"哨兵是最后一个动件动作"**机器证成立**；但"**冻结**与哨兵是最后两个动作"**字面读法不符**（冻结与本哨兵相隔 **22 笔**提交）⇒ **具名 F5** |
| — | **我推翻的话（§4）** | **两条**：① 两处新行写的「**现取** `docs/ROUTES.md:788` ＝ 本批未登记行」**为假**（现取 `:790`；`:788` 是另一行）；② §13 实测 ⑤ 规则漏"区" |

**不阻塞下游**：F1–F5 均为**文本层**缺陷，不动产品件、不动基线、不动九位；`porcelain=0`。

---

## §1 复算命令**原文**（逐条照抄；命令与读数为同一趟）

### 1.0 形态与不变量（"只增不改"这条自述）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git show --numstat --format='%H %P %cI' 6cdb7df9408ee230b9c2fb01ef5c65a8eb179750
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git diff --numstat 3295f3e509b5a2f463aba0f5f2fa2f0f92e44df3 6cdb7df9408ee230b9c2fb01ef5c65a8eb179750
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git rev-list --count 3295f3e509b5a2f463aba0f5f2fa2f0f92e44df3..6cdb7df9408ee230b9c2fb01ef5c65a8eb179750
```
我**另写**一段"逐行子序列"证明（不只看 `numstat`）：把父代 blob 的 **810** 行按序在 HEAD blob 的 **814** 行里对齐 ⇒ **未被找到的父代行 = 0**，多出来的行**恰 4**（HEAD `:169`／`:172`／`:799`／`:801`）。⇒ **父代每一行都逐字节留在现文**，本笔是**纯插入**。`numstat` = `4	0	docs/ROUTES.md`，`git diff --numstat` 同上（**只有这一件**；`git show --numstat --format=''` 只列 `docs/ROUTES.md`）。

### 1.1 我自写的抽取器（判据①，**不用** `~/w14a/*` 的实现）

```bash
cd /home/links-dev/wv80x && python3 dom13_v80.py                       # HEAD 工作树
cd /home/links-dev/wv80x && python3 dom13_v80.py 3295f3e5...44df3      # 父代（作"改前"对照）
```
**域定义（本件逐字写死，作为我自己口径的声明）**：
- **区** ＝ `grep -n '^## §13 '` 那一行 起，**到下一个以 `## §` 起头的行之前**。HEAD 现取 = **`:161` … `:399`**（下一条 `## §` 在 `:400`）；父代现取 = `:161 … :397`（下一条在 `:398`）。
- `KIND = re.compile(r'TASK-\d{4}\s*\[[A-Za-z]+\]')`；**严格域** ＝ 行首剥掉树绘制前缀（`│├─└┌┐┘┤┬┴┼` 与空白）后 `KIND` **匹配于位置 0**；**字面域** ＝ 该行**任意位置**含 `KIND`；**排 `⏪` 域** ＝ 字面域再剔除**行内含 `⏪`** 的行。
- **口径②·整行法** ＝ 行区间取**整行（含标签段之前）**，每行**逐记号去重**计 1；**口径②·标签后法** ＝ 行区间取**标签命中处之后**，同样逐记号去重；**口径①** ＝ 标签命中处之后**第一个**记号（每行至多计 1）。

### 1.2 判据② 的逐行复活依据

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for L in 181 211 216 233 286 287; do printf '[%s] ' "$L"; sed -n "${L}p" docs/ROUTES.md | cut -c1-60; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for t in 'TASK-0007 \[MVP\]' 'TASK-0201 \[MVP\]' 'TASK-0203 \[Next\]' 'TASK-0302 \[MVP\]' 'TASK-0718 \[Next\]' 'TASK-0719 \[Next\]'; do printf '%-22s hits_in_§13=%s\n' "$t" "$(sed -n '161,399p' docs/ROUTES.md | grep -c "$t")"; done
```

### 1.3 判据③ 的五处未来戳

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -c '13:52' docs/ROUTES.md && grep -n '13:52' docs/ROUTES.md | cut -c1-120
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for L in 168 170 171 798 800; do printf '[%s] ' "$L"; sed -n "${L}p" docs/ROUTES.md | cut -c1-160; echo; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && stat -c '%n mtime=%y ctime=%z' docs/ROUTES.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git log -1 --format='%h %cI' HEAD
```
五行的**逐字节同一性**用 python 逐行 `sha256` 比父代/HEAD（结果见 §2-3）。

### 1.4 判据④ 的六个内容锚

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for L in 179 209 214 231 284 285; do printf '%s: ' "$L"; git show 3295f3e5:docs/ROUTES.md | sed -n "${L}p" | cut -c1-60; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for L in 181 211 216 233 286 287; do printf '[%s] ' "$L"; sed -n "${L}p" docs/ROUTES.md | cut -c1-60; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for L in 176 206 211 228 281; do printf '[%s] ' "$L"; sed -n "${L}p" docs/ROUTES.md | cut -c1-60; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for R in 9e29de9 1acdbf5 d3377f155 3295f3e5; do printf '%-10s :788=[' "$R"; git show $R:docs/ROUTES.md | sed -n '788p' | cut -c1-70; printf ']\n'; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git show 3295f3e5:docs/ROUTES.md | sed -n '788p' > ~/wv80x/p788.txt; sed -n '790p' docs/ROUTES.md > ~/wv80x/h790.txt; cmp ~/wv80x/p788.txt ~/wv80x/h790.txt && echo IDENTICAL
```

### 1.5 判据⑤ 的哨兵与次序

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux && cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag && sha256sum /tmp/bridge-frozen.flag | cut -c1-16 && ls -l --time-style=+%F_%T /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag && cat /tmp/bridge-frozen.flag
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do printf '%s  %s\n' "$(sha256sum "$f" | cut -c1-16)" "$f"; done
cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/bridge-src-fp.sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '66p' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-260
cd /home/links-dev/netTest/GitProj/WPFOnLinux && sed -n '9p' docs/CURRENT-STATE.md && sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git ls-remote origin refs/heads/feat-Linux | cut -c1-40 && git rev-parse HEAD && git status --porcelain | wc -l
cd /home/links-dev/netTest/GitProj/WPFOnLinux && git log -S'BASELINE-FROZEN gen=#80' --format='%h %cI %s' -- docs/CURRENT-STATE.md
cd /home/links-dev/netTest/GitProj/WPFOnLinux && find . -path ./.git -prune -o -type f -newermt '2026-09-28 13:48:27' -print | grep -v -E '/(obj|bin|artifacts|parity)/'
cd /home/links-dev/netTest/GitProj/WPFOnLinux && grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' . | grep -v '^./upstream/'; echo "count=0"
```
**取数路径的纪律**：`PROVIDER` 的**权威路径** ＝ `build/DirectWrite.Linux/Provider/bin/<CFG>/…`（在册取数规则，`docs/ROUTES.md` `§15af` 的 `t68` 规则行逐字点名；**禁用** `build/PresentationCore.Linux/bin/<CFG>/…` 副本）。我**第一次用错了副本路径**，当场被自己的"块值反证"抓住 ⇒ 见 §6-①。

---

## §2 逐格对照表（左＝我自算，右＝现文；**"现文"＝ HEAD 工作树同一趟现取**）

### 2-1 判据① 三组域值（区 ＝ `§13` `:161–:399`）

| 域 | 行数（自算 / 现文） | 口径②·整行法（自算 / 现文） | 口径②·标签后法（自算 / 现文） | 口径①（自算；现文未在此行给） |
|---|---|---|---|---|
| 字面域 | **78 / 78** ✓ | 和 **86** ＝ ✅**76**／🟡**3**／🔴**6**／⚪**1** / **同** ✓ | 和 **84** ＝ ✅**76**／🟡**3**／🔴**5**／⚪**0** / **同** ✓ | 和 78 ＝ ✅74／🟡2／🔴2／⚪0 |
| 严格域 | **77 / 77** ✓ | 和 **82** ＝ ✅**75**／🟡**2**／🔴**5**／⚪**0** / **同** ✓ | 和 **82** ＝ 与整行法**同值** / 现文写"两种行区间同值" ✓ | 和 77 ＝ ✅74／🟡1／🔴2／⚪0 |
| 排 `⏪` 域 | **76 / 76** ✓ | 和 **81** ＝ ✅**74**／🟡**2**／🔴**5**／⚪**0** / 同上一条 `t70` 行原值 ✓ | 和 81 ＝ 同值 | 和 76 ＝ ✅73／🟡1／🔴2／⚪0 |

**"另一组数"已按要求另列**：现文**显式声明**「口径② 的行区间 ＝ 整行（含标签段之前）」，且**同时给出标签后法的 `84/76🟡3🔴5⚪0`** ⇒ **口径声明与另列一组数两件事都做到了**（判据①的硬要求）。

**`5／0` 与 `6／1` 之争的落点（我额外钉死）**：两种行区间法的差集**只有一个格子**：
```
whole-only cells: [(167, '⚪'), (167, '🔴')]      after-only cells: []
```
⇒ 整行法与标签后法的全部差额由**同一行**（`§13` 的 `t66` 更正行）的**两个记号**（🔴、⚪）承担；这两个记号出现在该行**标签命中处之前**。现文那句「`t71` 的 `5／0` 与上一行的 `6／1` 之争正是此因」**成立且可复现**。

### 2-2 判据② `6／1`（逐行复活依据）

**🔴 `6` 行**（HEAD 行号 / 父代行号 / 复活锚）：

| # | HEAD | 父代 | 内容锚（唯一句；**行号只是"读时"括注**） |
|---|---|---|---|
| 1 | `:167` | `:167` | **紧随内容锚 `` 现取计数（`#80`，`t14` 现算） `` 之后那一条以 `⏪` 起头的行**（我现取：`:166` 是那条 `现取计数` 行、`:167` 就是这条 `⏪` 行 ✓） |
| 2 | `:181` | `:179` | `` TASK-0007 [MVP] `` ＋ 「切「富文本」23／「流文档」24 **必死 rc=134**」 |
| 3 | `:211` | `:209` | `` TASK-0201 [MVP] `` ＋ 「静默 `rc=139`＋0 字节日志」 |
| 4 | `:233` | `:231` | `` TASK-0302 [MVP] `` ＋ 「PTS / 原生 LineServices」 |
| 5 | `:286` | `:284` | `` TASK-0718 [Next] `` ＋ 「给 `shell-quote-trap-check.sh` 补「续行中的注释」一类」 |
| 6 | `:287` | `:285` | `` TASK-0719 [Next] `` ＋ 「给基线率闸补「公式/口径」判据」 |

**⚪ `1` 行** ＝ 第 1 行（`t66` 更正行）本身。

**"未改"是机器证，不是复述**：我在**同一条命令**下对**父代 blob** 跑同一抽取器，得到
`LITERAL 78 whole sum=86 ✅76 🟡3 🔴6 ⚪1 | after sum=84 ✅76 🟡3 🔴5 ⚪0 | STRICT 77 sum=82 ✅75 🟡2 🔴5 ⚪0` ——
与 HEAD **逐格相同**；父代 🔴 行 = `[167,179,209,231,284,285]`、⚪ 行 = `[167]`，与 HEAD 的 `[167,181,211,233,286,287]`/`[167]` 是**同一个集合经 `+2` 位移**。⇒ 本笔**没动 `6／1`，也没动任何一桶**。

### 2-3 判据③ 五处未来戳

`grep -c '13:52'` = **7**（5 处**自带** `读时 …T13:52+08:00` 的戳 ＋ 2 处**新增行里的引文**）。

| # | 载体行（HEAD） | 父代行 | 原名一字未删 | 更正句（位置 / 读时） |
|---|---|---|---|---|
| 1 | `:168`（`§13` 域裁决＋三域对照） | `:168` | **逐字节相同** ✓（3311 B） | `:172` 覆盖（"上面三条 `t70` 行"）／读时 `2026-09-28T13:47:15+08:00` |
| 2 | `:170`（`§13` 机理更正） | `:169` | **逐字节相同** ✓（1995 B） | 同上 |
| 3 | `:171`（`§13` 自指更正） | `:170` | **逐字节相同** ✓（864 B） | 同上 |
| 4 | `:798`（`§15af` 域裁决） | `:796` | **逐字节相同** ✓（1608 B） | `:801` 覆盖（"本节两条 `t70` 行"）／读时同上 |
| 5 | `:800`（`§15af` 内容锚化） | `:797` | **逐字节相同** ✓（668 B） | 同上 |

- **(a) 成立**：不仅这 5 行逐字节相同，**父代 810 行全部**逐字节在位（§1.0 的子序列证明 ⇒ 删 0）。
- **(b) 成立**：更正句在 `:172`／`:801` **在位**，给的是**秒级**读时 `13:47:15`，且
  **读时 `13:47:15` < 载体现取落盘时刻 `docs/ROUTES.md` mtime `2026-09-28T13:48:04.581086271+08:00` < 提交 `13:48:20`** ⇒ **读时早于落盘**。（"写 `13:47:44`"这一自述**不可对拍** ⇒ F2b，见 §4。）
- 附注：本件 mtime 带**纳秒**（`…04.581086271`），与现文所引 `…39.322691670` 同为纳秒粒度 ⇒ 粒度不是问题。

### 2-4 判据④ 六个内容锚

| # | 内容锚（原文） | 原写（作废） | 读时实际（父代现取） | 本笔写后（HEAD 现取） | 判 |
|---|---|---|---|---|---|
| 1 | `` TASK-0007 `` | `:176` | **`:179`** ✓ | **`:181`** ✓ | 成立 |
| 2 | `` TASK-0201 `` | `:206` | **`:209`** ✓ | **`:211`** ✓ | 成立（锚唯一性见 F4） |
| 3 | `` TASK-0203 `` | `:211` | **`:214`** ✓ | **`:216`** ✓ | 成立 |
| 4 | `` TASK-0302 `` | `:228` | **`:231`** ✓ | **`:233`** ✓ | 成立 |
| 5 | `` TASK-0718 `` | `:281` | **`:284`** ✓ | **`:286`** ✓ | 成立 |
| 6 | `` TASK-0719 `` | `:282` | **`:285`** ✓ | **`:287`** ✓ | 成立 |

- **两组值逐格复现**（读时组对**父代 blob** `sed -n` 现取、写后组对 HEAD 现取）；`+2` 与"本笔在 `:169`／`:172` 处各插 1 行"**结构自洽**。
- **原写的 6 号在 HEAD 已指向别的内容**（我逐条打过原文）：`:176` ＝ `TASK-0002 [MVP] ✅ B 能开窗渲染`；`:206` ＝ `⚠️ **反极性 = VACUOUS** …`；`:211` ＝ `TASK-0201`（**注意：恰好是另一个 TASK，最容易被"看起来对"蒙过去**）；`:228` ＝ `世代位：hbtextline …`；`:281` ＝ `TASK-0713`；⇒ **作废成立**。
- **声明在位**：`:172` 「同为"仅本次有效"」＋ `:169` 「括号里的行号只是"读时"括注、"仅本次有效"」＋ `:799` 「（读时 `:167`，**仅本次有效**）」。

### 2-5 判据⑤ 哨兵十键 ⇔ 现取（**禁只比 sha16**，逐键照抄 ＋ 逐键重算）

| # | 键 | 哨兵值（逐键照抄） | 我独立重算 | 一致 |
|---|---|---|---|---|
| 1 | `SHA` | `4e25e4b27d4d5ae1` | `sha256sum …/release_linux-x64/wpfgfx_cor3.so` = `4e25e4b27d4d5ae1` | ✓ |
| 2 | `FP` | `d697b1e10ff48881` | `bash build/bridge-src-fp.sh` ⇒ `BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78` | ✓ |
| 3 | `PC` | `5b6cfda3e12b84fc` | `…/PresentationCore.Linux/bin/Release/PresentationCore.dll` = `5b6cfda3e12b84fc` | ✓ |
| 4 | `PF` | `b9a4f3a0e48e688d` | `…/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = `b9a4f3a0e48e688d` | ✓ |
| 5 | `WB` | `9e860cbeecb352e1` | `…/WindowsBase.Linux/bin/Debug/WindowsBase.dll` = `9e860cbeecb352e1` | ✓ |
| 6 | `WIN32SHIM` | `6825dd7071387a46` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = `6825dd7071387a46` | ✓ |
| 7 | `HBTL` | `921ba9c65e9fb3be` | `build/shims/PresentationCore.HbTextLine.cs` = `921ba9c65e9fb3be` | ✓ |
| 8 | `WIC` | `f7b3026c8c019be2` | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` = `f7b3026c8c019be2` | ✓ |
| 9 | `PROVIDER` | `24e4e0a731dbed40` | **权威路径** `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` = `24e4e0a731dbed40`（104,448 B，mtime `13:11:49.073048849`） | ✓ |
| 10 | `DWF` | `c83be96f18759edc` | `…/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll` = `c83be96f18759edc` | ✓ |
| 11-13 | `WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` | 照抄 | `docs/CURRENT-STATE.md:9` ＝ `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 …` 现取 **一致**；块件现算 `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`b96d4312565a3c49`** | ✓ |

**"用现取值、不是块内冻结值"的反证（这条是本判据的承重读数）**：`#80` **块内九位行**现取
`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66` ⇒ `provider` ＝ **`7e8a217b4165a6b9`**，
而**哨兵**里 `PROVIDER` ＝ **`24e4e0a731dbed40`** ⇒ **哨兵带的正是现取值**（不是块值）。**10/10 逐键对上现取**。
哨兵文件：`279 B`；`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` **同时刻 `2026-09-28_13:48:27`**、`cmp` ⇒ `IDENTICAL`、`sha16` ＝ **`6cb3f97388c3c4dc`**。

### 2-6 判据⑤ 三者次序（冻结 → 哨兵 → 推送）

| 动作 | 现取时刻 | 来源（可复核） |
|---|---|---|
| **冻结**（波 `#80` 收口冻结，基线 `901619543b3d913b → b96d4312565a3c49`） | **`2026-09-28T12:21:19+08:00`** | `git log -S'BASELINE-FROZEN gen=#80' -- docs/CURRENT-STATE.md` ⇒ `57cd937` |
| 载体写（`docs/ROUTES.md`） | `13:48:04.581086271` | `stat` mtime |
| **提交** | `13:48:20` | `git show --format='%cI'`（`reflog` 同为 `13:48:20`） |
| **哨兵写** | **`13:48:27`** | 两枚 `stat` mtime（同刻） |
| **推送** | **不可取时刻**（`NOINFO`） | 见下 |

- **"哨兵是最后一个动件的动作"＝机器证成立**：`find . -newermt '2026-09-28 13:48:27'` 排掉 `obj|bin|artifacts|parity` 后**只剩 4 件，全部在 `.agent-teams/` 下**（团队态，非仓内容件；`.agent-teams/` 在 `.git/info/exclude:8` 里 ⇒ 不计入 `porcelain`）⇒ **哨兵之后没有任何产品件/文档件被写**。
- **"冻结与哨兵是最后两个动作"＝字面读法不符（具名，不静默）**：冻结（`12:21:19`）与本次哨兵（`13:48:27`）之间**相隔 `git rev-list --count 57cd937..HEAD` ＝ 22 笔提交**，其中 `docs/ROUTES.md` 被写了 6 次以上 ⇒ **冻结不是"最后两个动件动作"里的那个**。
- **但规则要防的实质（九位是重建驱动）成立**：哨兵 10 键与现取**逐位相同**（§2-5）⇒ **冻后无任何重建**（若有重建，`PROVIDER` 位必位移）。
- 在册先例（**现取原文，一处**）：`build/MilBridge/P1-docs-close-report.md` 里那句「**口径（如实）**：**哨兵写…早于提交②…** —— 因提交②只带一处空行（**不含任何产品件、不含 `CURRENT-STATE`／基线件**）⇒ 哨兵内容不受影响」⇒ 本仓**已有**"哨兵与提交/冻结的先后要按实质影响判、并按名字具名"的先例。

---

## §3 五条判据逐条判词

1. **判据①（三组域值自算）＝ 成立。** `78` 行·整行法 和 `86` ＝ `✅76／🟡3／🔴6／⚪1`；`78` 行·标签后法 和 `84` ＝ `✅76／🟡3／🔴5／⚪0`；`77` 行·整行法 和 `82` ＝ `✅75／🟡2／🔴5／⚪0`（严格域两法同值）—— **三组与现文逐格相同**，且"标签前的记号线算进去"的那一法**已显式声明为另一种口径并另列一组数**。**附缺陷 F3**（未声明"区"，见 §4-②）。
2. **判据②（`6／1` 未改）＝ 成立。** 🔴 `6` 行、⚪ `1` 行**逐行在现文复活**（内容锚 ＋ 行号双给），且**父代同法复算逐格相同** ⇒ 本笔未换数、未改集合。与现文**无差异**。
3. **判据③（五处未来戳）＝ 成立**：`(a)` 5 行**逐字节未删**（更强：父代全 810 行纯插入式保留，删 0）；`(b)` 更正句在位、给秒级真实读时、读时 `13:47:15` 早于载体落盘 `13:48:04.581086271`。**附 F2**（`9 分 53 秒` 与同句点名的 mtime 不符 ／ `13:47:44` 不可对拍）。
4. **判据④（六个内容锚）＝ 成立**：六处**都给 TASK 号作内容锚** ＋ 「仅本次有效」声明；"读时（父代）"与"写后（HEAD）"两组行号**逐格复现**，原六号在现文**确已指向别的内容**。**附 F4**（`TASK-0201` 的锚在 `§13` 内**非唯一**）。
5. **判据⑤（推送与哨兵次序）＝ 取值成立、次序部分不符**：哨兵**十键全部 ＝ 现取值**（含块值 `provider 7e8a217b4165a6b9` ↔ 哨兵 `24e4e0a731dbed40` 的反证）；`cmp IDENTICAL`、`279 B`、`sha16 6cb3f97388c3c4dc`；`ls-remote` ＝ `HEAD` ＝ `git rev-parse HEAD` ＝ `6cdb7df9…`。
   - 「**哨兵 → 推送**」**成立**（哨兵之后无任何非 `.agent-teams` 文件被写 ⇒ 哨兵是最后一个动件动作）；
   - 「**冻结 → 哨兵**」按**字面**规则（"最后两个动作"）**不符**：相隔 **22 笔**提交（`12:21:19` → `13:48:27`），**具名 F5**；
   - 「**推送时刻**」**`NOINFO`**：`push` 不在本机留 reflog；`.git/logs/refs/remotes/origin/feat-Linux` 末次更新 `2026-09-28_13:29:11`、其最后一笔是 `fetch`（到 `282dc35b`，**早于本笔提交**）⇒ **本机无 `6cdb7df9` 的 `push` 记录**，只能证"**现取** HEAD ＝ 远端"。
   - 附带复现 `HANDOFF-NEXT.md` 第 14 条自述：`grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .`（排除 `upstream/`）⇒ **0 命中** ⇒ 哨兵确无仓内写者/读者。

---

## §4 我**推翻**的话（逐条给出可复算的证伪命令与读数）

**编号对照（本件通篇一致）**：`F1` ＝ 本条 ① ｜ `F2` ＝ 本条 ③（`9 分 53 秒` 量名/数值不符）＋ 本条 ④（`13:47:44` 不可对拍，记 `NOINFO`）｜ `F3` ＝ 本条 ②（域声明缺"区"）｜ `F4` ＝ 本条 ⑤（`TASK-0201` 锚非唯一）｜ `F5` ＝ §3-5（"冻结与哨兵是最后两个动作"字面不符）。

### ① 「**现取** `docs/ROUTES.md:788` ＝ 「`- **本批未登记（等落地配号）**：…`」」—— **假**（两处新行都带这句）

- 现文出处：`:172` ④ 逐字「**现取** `docs/ROUTES.md:788` ＝ 「`- **本批未登记（等落地配号）**：…`」（**非空行**）」；`:801` ② 逐字「（现取 `:788` ＝ 「本批未登记（等落地配号）」行…）」。
- **现取（我打的原文）**：
  - `sed -n '788p' docs/ROUTES.md` ⇒ `- **`#76` ＝合波四件**（`TASK-0732` 主件 ＋ …`
  - `grep -n '本批未登记（等落地配号）' docs/ROUTES.md` ⇒ **`:790`**（不是 `788`）
  - 父代 `git show 3295f3e5:docs/ROUTES.md` 的 `:788` **就是** `本批未登记（等落地配号）`，且 `cmp(p788, h790)` ⇒ **IDENTICAL**。
- **根源（可机器复现）**：本笔在 `:169`、`:172` 各插 1 行，**两处都在 `:788` 之前** ⇒ `:788 → :790`。所以那句自称"现取"的坐标，实际是**父代的坐标** —— **正是这一笔自己刚宣布失效的"插入前坐标"读法**。
- **影响面**：`:172` ④ 的**实质判词**（`:171` 写的"`:788` 现取为空行"**不成立**）**是对的**（`:788` 现取确为非空）；错的只是它自己的坐标与引文。
- **建议（不改数、只追加）**：dated 追加一句「现取 `:788` ＝ `#76 ＝合波四件` 行；`本批未登记（等落地配号）` 行现取 `:790`（纳秒级 mtime/提交时刻另注），以此为准」，并保留原句。

### ② 「三组可复算值」的**域声明缺"区"这一项** —— 按其自述规则**复算不出自己的三个数**

- 现文出处：`:169`（与 `:799` 配套）逐字给「**① 域（行集）**：**字面域 ＝ 含标签形态 `TASK-NNNN [kind]` 的 `78` 行**…」＋「**⑤ 规则**：**「此后引用任何桶计数，必须同时写『域名 ＋ 行数 ＋ 口径② 的行区间』」**」。
- **证伪读数（同一抽取器，只换作用范围）**：把**它自己写的那条"字面域"定义**套到**全件** ⇒ **`79` 行**、整行法 和 **`87**、标签后法 和 **`85**（而不是 `78／86／84`）。多出来的那一行是 **`:150`**（`§12` 区内）＝ `- - TASK-0301 [MVP] ✅ **两极都成立（…）`，**含 `TASK-NNNN [kind]` 标签 ＋ `✅`**。
- `grep -o '§13' :169` ⇒ **0**（该行**全文不含 `§13`**）；区界只在**上一行**（`:168` 的 `脚本口径` 段）里写着 `域＝`## §13 ` 行至下一个 `## §` 行之前`。
- ⇒ `78／86／84` **本身成立**（我按 §13 区内复现了），但**⑤ 那条"此后一律照此"的规则漏了『区』** ⇒ 后人按规则复算会得到 `79／87／85` 并判成"现文错"。**这是本仓 `D-G130` 同族（判据输入未写全 ⇒ 复算不出）**。

### ③ 两处**量名与数不符**（同句内自相矛盾）

- 出处：`:172` ① 与 `:801` ① 都写「**载体写入时刻 ＝ `docs/ROUTES.md` mtime `2026-09-28T13:41:39.322691670+08:00`**，**载体的最后一笔提交 `3295f3e5…` ＝ `2026-09-28T13:42:07+08:00`** ⇒ 原戳**晚于载体写入 `9` 分 `53` 秒**」。
- **现算**：`13:52:00 − 13:41:39.322691670` ＝ **`10 分 20.677308 秒`**（620.677 s）；`13:52:00 − 13:42:07` ＝ **`9 分 53 秒`**（593 s）。
- ⇒ 「`9` 分 `53` 秒」只对**提交时刻**成立，对**同句点名的 mtime** 差 **27.68 s**。同句另一格「晚于本笔读时 `4` 分 `45` 秒」（`13:52:00 − 13:47:15`）**现算精确成立**。
- **建议**：把该句的量名改为「晚于**载体的最后一笔提交** `9` 分 `53` 秒（对 mtime 为 `10` 分 `20.677308` 秒）」—— 原文保留、dated 追加。

### ④ 「**本笔即教训：读 `13:47:15`／写 `13:47:44`**」——**不可对拍**（非推翻，记为 NOINFO ＋ 具名差异）

- **现取**：`docs/ROUTES.md` mtime ＝ **`2026-09-28T13:48:04.581086271+08:00`**、ctime ＝ `13:48:07.787090444`；本笔提交 `13:48:20`。
- 该窗口内**只有 `docs/ROUTES.md` 一件内容件被写**（`find -newermt '13:42:08' ! -newermt '13:48:28'` 排派生目录后 ⇒ `docs/ROUTES.md` ＋ 两个 `.agent-teams/*.jsonl`）。
- ⇒ 自述的 `13:47:44` 与唯一可现取的落盘时刻 `13:48:04.581086271` **差 `20.58 s`**。**我不判它假**（可能是"先写一版再写一版"，mtime 只留最后一次），但**它不可对拍** ⇒ `NOINFO`：机制未定、需写者自证。

### ⑤ 「内容锚」对 `TASK-0201` **不是唯一锚**

- `sed -n '161,399p' docs/ROUTES.md | grep -c 'TASK-0201 \[MVP\]'` ⇒ **2**（`:167` 的 `t66` 更正行**引文里**也含这一串 ＋ `:211` 本体行）。其余五个锚在 `§13` 内各 **1** 次。
- ⇒ 「一律改内容锚」对五个成立；对 `TASK-0201` 需限定为**行首锚**（严格域）才唯一。建议追加一句把该锚写成「**行首**即 `TASK-0201 [MVP]` 的那一行」。

---

## §5 边界与未做项（`NOINFO` 逐条 ＋ 具名原因）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | **推送时刻** | `NOINFO` | `push` 不留本地 reflog；`.git/logs/refs/remotes/origin/feat-Linux` 末次更新 `13:29:11` 且末笔是 `fetch`（到 `282dc35b`，**早于本笔**）。只能证"**现取** `HEAD` ＝ `ls-remote`"。 |
| N2 | 「读时 `13:47:15`」这个**秒级自述值本身** | `NOINFO` | 无独立记录；我只判"是否早于落盘时刻"（成立）。 |
| N3 | 「载体写入 mtime `13:41:39.322691670`」（父代历史读数） | `NOINFO` | 本机不可回溯核历史 mtime（git 不存 mtime）；**且**与同句的 `9 分 53 秒` 不符（§4-③）。 |
| N4 | 哨兵 `13:48:27` 的**写入者/写入命令** | `NOINFO` | 仓内 `grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .` ⇒ **0**（我复现了 `HANDOFF-NEXT.md` 第 14 条），仓外仪器不可核。 |
| N5 | 哨兵十键的**同一时刻性** | 边界 | 我只能在 `14:04–14:06` 现取；除 `PROVIDER`（构建驱动位，`13:11:49` 后再未重建）外皆非构建驱动 ⇒ 逐位相同。**若期间有人重建，`PROVIDER` 会变**（本趟未变）。 |
| N6 | `~/w14a/{rows70,dom70c}.py` 两个脚本**自身** | `NOINFO`（不适用） | 现文引它们为脚本口径；**我的判据是自算**，未跑它们（两件现存：`1792 B` mtime `13:41`／`1059 B` mtime `13:46`）。 |
| N7 | `:788` 那句的**哪一个字才是"正确修法"** | 不判 | 我只判"该处自称现取不成立"；修法属写者写域（本件不给改法，只给现取读数）。 |
| N8 | 波 `#80` 的**冻前/冻后 `verify-all`** | **未做（本件不需要）** | 本件极轻、不跑门禁、不跑 `heavy-slot`、不跑 `dotnet`。 |
| N9 | `DEFREG` / `REPORTID` 两条牙 | **未复核** | 派单未列；且**不许**改声明表 ⇒ 交回队长/下一件。 |
| N10 | 「五处未来戳」之外**全件是否还有别的 `13:52` 类未来戳** | 已查（非 NOINFO） | `grep -c '13:52'` ＝ 7 ＝ 5 处自带戳 ＋ 2 处新增行引文；**无第 6 处自带戳**。 |

---

## §6 我自己的自伤与更正（如实记，不缩小）

1. **用错了 `PROVIDER` 的取数路径（当场被自己的判据抓住）**：我先按派单 `Verify` 行里的
   `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll` 取值 ⇒ `7e8a217b4165a6b9`，
   与哨兵 `24e4e0a731dbed40` **不符**，一度准备判"哨兵用块值、位移"。**纠错依据**：`#80` **块内九位行**
   （`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66`）正是 `provider 7e8a217b4165a6b9`，而 `§15af` 的 `t68`
   取数规则行**逐字点名**"**`PROVIDER`＝`build/DirectWrite.Linux/Provider/bin/<CFG>/…`（工程产出＝权威；**禁**用
   `build/PresentationCore.Linux/bin/<CFG>/…` 副本）**" ⇒ 我换用**权威路径**重算 ＝ `24e4e0a731dbed40` ⇒ **哨兵对**。
   **教训**：派单 `Verify` 行里的路径是"九位文件的现取清单"，**不等于取数口径**；同名产物多权威路径（`D-G150` 同族）。
2. **行数口径**：`wc -l docs/ROUTES.md` ＝ **813**，我自写的抽取器报 **813 行**（末字节 `0a`，尾空串已剔除）；
   父代同法 **809**。与在册说法（`809 → 813`）**一致**。我引 `:NNN` 一律用 `sed -n`／`awk`（同一约定），**引前先打原文**。

---

## §7 收尾（不变量）

- `git status --porcelain | wc -l` ＝ **0**（**写入本件之前**现取）。**写入本件之后**现取 ＝ **1**，唯一一行是 `?? build/MilBridge/V80-t71FIX-verify-report.md` ＝ **本件自身**（未跟踪、我未 `git add`／未提交：本件写域只有这一件，其余 `$N` 内件一字未动；如需在册请由队长/写者 `git add <本件>`）。
- 本件写入方式 ＝ **temp ＋ `rename`**（`~/wv80x/report-body.md` → `build/MilBridge/V80-t71FIX-verify-report.md`）。
- **唯一的写者动作**就是本件；`$N` 下 `docs/ROUTES.md`／`verify-all.sh`／`build/close-wave.sh`／基线件／声明表**一字未动**。
- `$N` 其余可核读数（本件 §2-5 已表）：`HEAD` ＝ `ls-remote` ＝ `6cdb7df9408ee230b9c2fb01ef5c65a8eb179750`；块件 `b96d4312565a3c49`；`CURRENT-STATE.md:9` ＝ `gen=#80`。
- **判词尾行**：`V80-T71FIX: HEAD=6cdb7df9 parent=3295f3e5 numstat=4/0 additive=PROVEN criteria=5 verdicts=[PASS,PASS,PASS,PASS,PARTIAL] overturned=2 findings=[F1,F2,F3,F4,F5] NOINFO=10 sentinel=6cb3f97388c3c4dc ident=yes block=b96d4312565a3c49`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `a216b988dd881f11` ／ FULL `a216b988dd881f1147d72d042119fcb8a96ede13c19087ae6cdc7d6ab082a257` ／ `wc -l` ＝ 292 行（**不含**本行）／末次读取时刻 `2026-09-28T14:08:5x+08:00`／写入方式 **temp ＋ rename**。
