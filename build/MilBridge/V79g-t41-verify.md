# V79g — `t41` 独立复核：`t40`（D-G172 声明表重出 ＋ D-G173 第二声明点 ＋ 两条牙 ＋ 成对重测 ＋ 推送）

**判词：`pass`**（契约七条款逐条由我自己现取复算；**未采信任何人的数字**）。
真树**只读**；反极性腿的夹具全在 `~/w41a`（副本/单变量覆盖），**真树零写入**；本件在仓内的唯一写入 = 本文件。
我的读时刻：`2026-09-28T03:28:19 … 03:31:45+08:00`。资源现取（`03:28:24`）：`df_avail_kB=89184576`、`mem_avail_MB=3998`；全程零 `dotnet`、零 Xvfb、零进程枚举/收杀。

## 0. 承重件指纹（我的读时刻）

| 件 | 现取 sha16 | 备注 |
|---|---|---|
| `HEAD` | **`71603bd3762059b3e1791be4a5eac2359657e01f`** | `t40: 关 D-G170…D-G173`，`ci=2026-09-28 03:25:20`，父 `6a245bd` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `bbdf0b5945ffb525` | 8,738 B；`:1` `DECL-GEN = (--emit) 2026-09-28 02:22:34` |
| `build/MilBridge/tools/defect-registry-check.sh` | `c2d0773e5561a9d1` | 29,174 B，mtime `02:21:40` |
| `build/MilBridge/tools/baseline-sha-check.sh` | `2ce23747f87e9988` | 18,987 B，mtime `02:44:30` |
| `build/MilBridge/tools/nul-bytes-check.sh` | `2902c14fa1081a5c` | mtime `02:45:52` |
| `verify-all.sh` | `bb7a286b99dba757` | 173,013 B，mtime `02:21:40` |
| `docs/CURRENT-STATE.md`（route 键 `CS`） | `90a22e10619a8485` | 933 行 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`KD`） | `ac13076c17ca8f8f` | 814,316 B |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`AB`） | **`901619543b3d913b`** | 1,195,664 B |
| 两哨兵 `/tmp/bridge-frozen.flag` ↔ `~/wfp-runs/bridge-frozen.flag` | 均 `d87d575ae8732003` | 279 B，mtime `03:25:37`，`cmp` IDENTICAL |

---

## ① 7 键**逐件现算** ↔ 声明表（同一趟，分钟级）

我的命令（`03:28:24`）＝对每条 route/登记件的**权威路径**直接 `sha256sum | cut -c1-16`（不走牙的取数支路）：

| 键 | 我的现算 | `defect-registry-declared.tsv:2` 的 `DECL-ANCHORS` | 牙 `DEFREG_ROUTES`／`DEFREG_EXTRA`（同趟） | 逐位 |
|---|---|---|---|---|
| `KD` | `ac13076c17ca8f8f` | `ac13076c17ca8f8f` | `ac13076c17ca8f8f` | ✅ |
| `CS` | `90a22e10619a8485` | `90a22e10619a8485` | `90a22e10619a8485` | ✅ |
| `HO` | `a4d8ffcf4c37f6fe` | `a4d8ffcf4c37f6fe` | `a4d8ffcf4c37f6fe` | ✅ |
| `AB` | `901619543b3d913b` | `901619543b3d913b` | `901619543b3d913b` | ✅ |
| `KRJ` | `2209966ee1d2c5cc` | `2209966ee1d2c5cc` | `2209966ee1d2c5cc` | ✅ |
| `KRF` | `ab09235afd949bc2` | `ab09235afd949bc2` | `ab09235afd949bc2` | ✅ |
| `KRP` | `3c9e3a309b990d31` | `3c9e3a309b990d31` | `3c9e3a309b990d31` | ✅ |

同趟（`T0=03:28:24`→`T1=03:28:28`，同一分钟）的牙读数：
```
DEFREG_DECL=n=210 route_ids=210 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG_DECLDRIFT_KEYS=-  # 机读差集键行
DEFREG=PASS declared=210 route_ids=210        rc=0  stderr=0 B
```
`declared` 我**自己也数了一遍**（`awk -F'\t' '$1=="ID"'`）＝ **210**，与牙的 `n=210` 相同。

## ② 反极性腿（我自己造，真树零写入）

| 腿 | 单变量 | 夹具 sha16 | 现取判词 |
|---|---|---|---|
| L1 **声明侧漂移 `AB`** | `DRC_DECL=<副本 tsv>`（`AB=…3b`→`…30`） | `fdec2d11785fe56b` | `DEFREG_DECLDRIFT=1 … keys=AB` ＋ **`DEFREG_DECLDRIFT_KEYS=AB`**；`DEFREG=PASS` 不变 |
| L2 **声明侧漂移 `CS`** | 同上（`CS=…85`→`…80`） | `1337977122fe40d1` | `DEFREG_DECLDRIFT=1 … keys=CS` ＋ **`_KEYS=CS`** |
| L3 **现场侧漂移 `AB`** | `DRC_AB=<副本 AB>`（偏移 1000 翻 1 位，尺寸不变） | `500a040f19906bb9` | `DEFREG_ROUTES=…AB=500a040f19906bb9` ⇒ `DEFREG_DECLDRIFT=1 … keys=AB` |
| 对照 | **真树**（无覆盖） | — | `DEFREG_DECLDRIFT=0 … keys=-`（见 ①） |

⇒ 「漂移**具名到键**」这一格成立（改前只有计数）；且**漂移不改变 `DEFREG` 三态**（三条腿里 `DEFREG` 全 `PASS`），与牙头声明的"诊断行、不判红"一致。

**`D-G173` 的新牙 `CSDECL`（`baseline-sha-check.sh`，`BSC_STATE` 单变量）**：
```
真树          ⇒ BASELINESHA=PASS / BASELINEGEN=PASS / BASELINEDUP=PASS / CSDECL=PASS n_decl_lines=1 auth_line=8   rc=0
L4 `:8` 塞回 `（现在 #99）`（副本 sha16 53a038cef5b831cc）
              ⇒ CSDECL=FAIL reason=auth-line-carries-literal-value line=8 tokens=#99   rc=1（三档仍 PASS ⇒ 指名到位）
L5 复制一条机器行（副本 5461a3579b23806f）
              ⇒ CSDECL=FAIL reason=duplicate-decl-line n=2   rc=1
```
**假绿通道的独立证**（这是我额外加的一格）：拿 `t40` 的**改前件**（`~/w79c/t40/pre/build_MilBridge_tools_baseline-sha-check.sh`，sha16 `e3b4a98fc9507854`，**＝ `git show 6a245bd:` 版本**）跑**同一个** `#99` 夹具 ⇒
```
PRE_TOOTH_RC=0   BASELINESHA=PASS / BASELINEGEN=PASS / BASELINEDUP=PASS   CSDECL 行数 = 0
```
⇒ 「第二声明点在改前**三档全绿**」是真的（新牙 `2ce23747f87e9988` 把它关掉）。

## ③ 「漂移读数真进**日志文件**」（不看报告散文）

两趟冻后日志（`t40` 自己在 `pair-evidence.txt` 里指名的正是这两份，且是**完整** `verify-all` 运行，非抽取件）：

| 日志（`~/w79-close/logs/`） | sha16 | 行数 | mtime | `DEFREG_DECLDRIFT=` | `_KEYS=` | 计数 |
|---|---|---|---|---|---|---|
| `w79-post1-20260928-024622.log` | `25714ec572bd2b35` | 243 | `03:06:22` | `:68` `=0 … keys=-` | `:69` `=-` | 各 1 |
| `w79-post2-20260928-030626.log` | `14433d6550a5f566` | 243 | `03:24:42` | `:68` `=0 … keys=-` | `:69` `=-` | 各 1 |

两趟还各自带：`步骤通过 55` ／ `❌ 失败 0` ／ `用例通过 875  跳过 2` ／ `结论：✅ 全部通过` ／ `BASELINESHA=PASS` ／ `CSDECL=PASS` ／ `VERIFYALL_SELF=PASS`；日志首行是 `HEAVYSLOT=ACQUIRED`、根目录行 `2026-09-28 02:46:22` / `03:06:26`（与文件名一致）。
**接力码现取**：`verify-all.sh:852` = `run_step "DEFECT-REGISTRY" bash build/MilBridge/tools/defect-registry-check.sh`；`:863-867` 把牙 stdout 里的 `^DEFREG_DECLDRIFT=`／`^DEFREG_DECLDRIFT_KEYS=` **原样**打进 `· 自报口径` 显示窗（`grep -m1` + here-string）。日志里 `:68/:69` 两行的形态与牙直出**逐字同构**。
⚠️ **边界**：我没有把"漂移=1 也能进日志"端到端跑通（那要跑一趟完整 `verify-all`）⇒ 该**子格**只做到"读码 + 形态同构"，未执行 ⇒ 记 `NOINFO`（不影响本条款：契约只要求 `≥2 且值 0`）。

## ④ `t23` 那一笔的漂移量 —— **独立确认 = 2 键（`CS`／`AB`）**

在 `t23` 的推送提交 `6a245bd` 上，我用**该提交里**的声明表（`DECL-GEN = 2026-09-28 00:47:15`）与该**提交里**的 7 件逐件现算（`git show 6a245bd:<path> | sha256sum`）对拍：

| 键 | `6a245bd` 里 `DECL-ANCHORS` | `6a245bd` 里的现算 | 差 |
|---|---|---|---|
| `KD` | `c89631d5a09df584` | `c89631d5a09df584` | — |
| **`CS`** | `e3f1d5cd98ea3404` | **`746a08e646370614`** | **漂** |
| `HO` | `a4d8ffcf4c37f6fe` | `a4d8ffcf4c37f6fe` | — |
| **`AB`** | `d60b414d5e99cf72` | **`901619543b3d913b`** | **漂** |
| `KRJ` / `KRF` / `KRP` | `2209966ee1d2c5cc` / `ab09235afd949bc2` / `3c9e3a309b990d31` | 逐位相同 | — |

⇒ **漂移键集 = {`CS`,`AB`}，计数 = 2**，与 `t23` 的结论**逐键吻合**（未推翻）。

## ⑤ 四条新号在册 ＋ `declared` 差值（**我推翻"+4"这个总差值**）

两次独立计数（`awk -F'\t' '$1=="ID"{print $2}' | sort` + `comm`）：
```
6a245bd 里的 TSV（DECL-GEN 00:47:15）： 204 条 ID 行
现场     的 TSV（DECL-GEN 02:22:34）： 210 条 ID 行
差集：新增恰 6 个 = D-G170 D-G171 D-G172 D-G173 D-G174 D-G175 ；删除 0 个
```
逐号在册（`KD` 现取命中数 / `6a245bd` 时命中数 / 旧 TSV / 新 TSV）：`D-G170` 2/0/0/1｜`D-G171` 2/0/0/1｜`D-G172` **2**/0/0/1｜`D-G173` 1/0/0/1｜`D-G174` 1/0/0/1｜`D-G175` 1/0/0/1。
🔴 **契约写的"`declared` 与登记前的差值恰 +4"不成立**：真实总差值 = **+6** = **+4（本件四号）＋ +2（`t43` 的 `D-G174` 与 `t45` 的 `D-G175` —— 已登记但未 `--emit` 的欠账，被 `t40` 这一笔一并补清）**。`t40` 的报告原文也写的是 `204→210（+6）` 并逐项归因 ⇒ **不是隐匿**，是契约把前提写小了。四条新号本身**在册齐全**（`KD` ＋ 声明表双向都在），且 `DEFREG=PASS declared=210 route_ids=210` 自洽。
旁证：`REPORTID` 现取 **`PASS files=182 ids=1876 declared=210`**（`rc=0`）—— `t40` 登记后那四条既存点名（原在 `P0-w79-report.md`）**确已关闭**（我自己跑的）。

## ⑥ 成对重测 / 哨兵 / 推送逐件 / 基线未动

- **两趟 post**：见 ③（各 `55 ✅ / 0 ❌`、`BASELINESHA=PASS`）。
- **哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；两份 sha16 均 `d87d575ae8732003`；内容 13 行：`WAVE=w79-freeze`／`BASELINE=#79`／`BASELINE_SHA16=901619543b3d913b`（**题定值两条都在**）。
- **推送逐件**：`git ls-remote origin refs/heads/feat-Linux` ⇒ `71603bd3762059b3e1791be4a5eac2359657e01f` **== 本地 `HEAD`**；`git fetch origin feat-Linux` 后 `git diff --name-only HEAD FETCH_HEAD` = **0 行**；`t40` 清单 18 件**逐件** `HEAD:<p>` vs `FETCH_HEAD:<p>` blob ⇒ **same=18 / diff=0**（清单与 `git status` 的双向差集我不重做——**推送件集合**已由"逐件 blob 相同＋树无差"覆盖）。
- **基线未动**：`sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`901619543b3d913b`**（`CS:9` 机器行声明值相同）。
- **`CURRENT-STATE.md` 改动面**：`diff <(git show 6a245bd:docs/CURRENT-STATE.md) <(现件)` = **1 处（`:8c8`，1 删 1 增）**，`:9` **逐字节相同**（各 97 B，`cmp` 通过）；行数 933 = 933；`D-` 编号集合 88 = 88（`diff` 空）；`grep -nE '\(现在[^)]*#[0-9]+'` = **0 命中**（全角 `（现在` 亦 0）。原行含 `（现在 **\`#44\`**；它的**整份 sha 只由下一条机器行声明**…）`，现行为 `（**世代与整份 sha** 都只由下一条机器行声明**…）` ⇒ 第二世代值确已移除。

## ⑦ 哨兵 13 行 ↔ `#79` 声明：**九位八同一位不同**（我自己现取的对照表）

| 位 | `#79` 声明（九位行 `:66`，机读行 `:74-79` 同值） | 哨兵现取 | 我现取（`03:30:22`，权威路径表 `wave-freeze-consistency-check.py:104-115`，`cfg=Release`） | 同? |
|---|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1`（5,028,208 B） | ✅ |
| `pc` | `38ae477949238306` | `38ae477949238306` | `38ae477949238306` | ✅ |
| `pf` | `12fb36e7b0df1802` | `12fb36e7b0df1802` | `12fb36e7b0df1802` | ✅ |
| `windowsbase` | `ed04eb65081c2d3a` | `ed04eb65081c2d3a` | `ed04eb65081c2d3a` | ✅ |
| **`provider`** | **`759ac1686e5ef87d`** | **`8cb1b50619f4c133`** | **`8cb1b50619f4c133`**（Provider/Release） | ❌ |
| `win32shim` | `e8127a3d7128d417` | `e8127a3d7128d417` | `e8127a3d7128d417` | ✅ |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | ✅ |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | ✅ |
| `dwf` | `0d25f64a7dbb4c78` | `0d25f64a7dbb4c78` | `0d25f64a7dbb4c78` | ✅ |
| 桥源指纹 `FP` | `d697b1e10ff48881`（`:68`） | `d697b1e10ff48881` | —（仓外源件） | ✅ |

**差异位的两读（我自己取的 `stat`+`sha256sum`）**：
```
build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll  8cb1b50619f4c133  size=104448  mtime=2026-09-28 02:23:33
build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll    759ac1686e5ef87d  size=104448  mtime=2026-09-27 14:22:19
build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll      759ac1686e5ef87d  mtime=2026-09-27 14:22:18   ← 另一条权威路径
build/PresentationCore.Linux/bin/Debug/DirectWrite.Linux.Provider.dll        759ac1686e5ef87d  mtime=2026-09-27 14:22:18
```
`02:23:33` 那一秒被改写的**是一个 `Provider` 项目的构建产物集**（我 `find` 到的同秒写入：`Provider/obj/Release/*.dll|*.pdb|AssemblyInfo*`、`Provider/bin/Release/*.dll|*.pdb`，以及 `Provider.pdb` 同时落到四个 `build/MilBridge/tests/*/bin/*/`）；那一分钟 `/home/links-dev` 顶层无车道路径活动。**机制我不归因**（主控已指派 `t46` 在冻结 `#80` 时按两个时刻重取）。

**该差异的射程（我自己的现取）与一条**当前真红**：
```
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --root "$PWD" --template auto   @03:30:34  ⇒ rc=1
WFREEZE_NINEAUTH_HIT kind=diverged canon=…/Provider/bin/Release/…=8cb1b50619f4c133 copy=…/PresentationCore.Linux/bin/Release/…=759ac1686e5ef87d
WFREEZE_NINEAUTH=FAIL pairs=1 ok=0 bad=1
WFREEZE_BLOCKVALUES_HIT key=provider probs=nine-vs-live,tier-vs-live block9=759ac1686e5ef87d tier=759ac1686e5ef87d live=8cb1b50619f4c133
WFREEZE_BLOCKVALUES=FAIL bad=1
WFREEZE_CONSISTENCY=FAIL rootdefault=PASS decl=PASS nineauth=FAIL blockvalues=FAIL
```
**射程**：`grep -c 'wave-freeze-consistency' verify-all.sh` = **0**（该牙只挂在 `build/close-wave.sh`，2 处）⇒ 这条红**不在** `verify-all` 的 55 步里，两趟 post 的 `55 ✅/0 ❌` 与它不矛盾；它会在**下一次冻结**的 `[5c/6]` 上现身（`t46` 的 `#80` 重取）。`inputs_fp` 覆盖面里**没有**任何 `DirectWrite.Linux/Provider/bin` 路径（我 `grep` 覆盖清单 = 0 命中）⇒ 这次重建**不**移动 `inputs_fp`。

## ⑧ `inputs_fp` 四值归因（我自己的枚举复算）

我用**自己的** python 复算器（先验证：`sha256(<覆盖清单整块>)` == 官方 `infp.sh fp`，`03:29:47` 两值同为 `3d5ac10b…`），对 `baseline-sha-check.sh`／`defect-registry-check.sh`／`nul-bytes-check.sh` 三件枚举**全部可用版本组合**（各 2–3 个版本 ⇒ 12 组合），在我抓的覆盖清单（226 行）上**剔掉**下条新增件后复算：

| 组合（BL / DR / NU） | 复算 fp | 与谁相等 |
|---|---|---|
| live / live / live | `cb7fbecaf8cd09fb…` | **`t40` 的 03:25 现取** ✅ |
| old / old / t43-era | `42e102ec2286c263…` | **`t40` 的"`t43` 首次越代"** ✅ |
| old / old / old（= `6a245bd`） | `4c096e9c0705a95d…` | **`#79` 块 `:69` 声明的冻后值** ✅ |
| 其余 9 组合 | `a1ebe2c8…`/`b18d6411…`/`5444b9e7…`/… | 无对应 |
| live（**含**新件，226 件） | `3d5ac10b94f8a4e0…` | 现树（见下） |

其中 `nul-bytes-check.sh` 的 `t43` 时代版本我用 `t40` 的改前备份（`~/w79c/t40/pre/nul-bytes-check.prefix-t40.sh` = `ac47b287c955823c`）代入——与 `t43` 自报的终态 sha16 逐位相同。
🔴 **两点如实**：
1. `t40` 的第 ② 值 **`a2a944c7…`（`2026-09-28T02:22:34` 现取）我复算不出来**：它对应 `baseline-sha-check.sh` 的**中间版本**，而该件在 `02:44:30` 又被改过一次（现行 `2ce23747f87e9988`），那个中间字节**已不在盘上**（我把 12 种组合全枚举过，没有一种给出 `a2a944c7`）⇒ 该单值记 **`NOINFO reason=intermediate-version-gone`**。链路两端（`4c096e9c` 声明值 ↔ `cb7fbeca` 03:25 现取）**都逐位复现**，中间两点里 `42e102ec` 也逐位复现。
2. **现树另有第四个值**：`src/WpfGfx.Linux.Native/tests/queue_corrupt_chain_fixture.c` 是**别的车道**在 `03:29:31` 新建的**未跟踪**件（`git status` = `??`），它**落在覆盖面内** ⇒ 覆盖面 225 → **226**、fp 变 `3d5ac10b…`（我 03:29:31 与 03:29:47 两次读还不同：该件在 16 秒内又被改写过一次）。这**不是** `t40` 的问题，但说明"**现树 fp 随时会走**"，任何以它作承重的判据必须带读时刻。

## ⑨ 我**推翻／更正**了哪些话

1. **契约第 ⑤ 条的"`declared` 差值恰 +4"** ⇒ 实测 **+6**（`204→210`），多出的 2 个具名 `D-G174`／`D-G175`（`t43`／`t45` 的登记欠账）；四号本身 **+4** 成立。`t40` 报告里写的也是 `+6`。
2. **`t40` 的第 ② 个 `inputs_fp` 值 `a2a944c7…`** ⇒ **不可复算**（`NOINFO reason=intermediate-version-gone`，12 组合全枚举），其余三值逐位复现。
3. **"哨兵 = 题定值"这句话要分两半**：`BASELINE`／`BASELINE_SHA16`／桥源 `FP` 与声明**逐位相同**，而**九位里 `provider` 一位不同**（哨兵取的是**现树**、声明取的是**冻结时刻**）—— 哨兵是"现取器"不是"声明比对器"，这一位差异**已由主控指派 `t46` 在 `#80` 重取**。
4. **未被推翻的**：7 键逐位、`DECLDRIFT=0 keys=-`、漂移具名到键、`CSDECL` 新牙（含假绿通道已被关）、读数进日志、`t23` 两键（`CS`/`AB`）、四条号在册、两趟 `55/0`、哨兵 `cmp` IDENTICAL、推送 18 件逐件相同、基线 `901619543b3d913b` 未动、`CURRENT-STATE.md` 改动只在 `:8`。

## ⑩ 边界 / `NOINFO`（如实划界）

- **B1**：`a2a944c7…` 不可复算（见 ⑧/⑨-2）。
- **B2**："漂移=1 也进日志"的**端到端**未执行（只做读码＋形态同构）⇒ 子格 `NOINFO`。
- **B3**：现树 fp 与覆盖面件数**正在被别的车道改变**（225→226，`03:29:31`；同一件 16 s 内两次哈希不同）⇒ 我的 `3d5ac10b…` 只在 `03:29:47` 一刻成立。
- **B4**：当前 `WFREEZE_CONSISTENCY=FAIL`（`provider` 位）是**真红**，仅挂在 `close-wave.sh`，不在 `verify-all` 55 步内；我不判它属 `t40`（其验收只要求哨兵 `cmp` ＋ 题定 `BASELINE`／`BASELINE_SHA16`，两条都成立），但**如实报红**并具名射程与两读。

## ⑪ 落仓与自指

本件 `build/MilBridge/V79g-t41-verify.md`（仓内唯一写入；`temp+rename`、`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
