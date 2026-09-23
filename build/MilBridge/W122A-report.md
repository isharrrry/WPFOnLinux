# 车道 `W122A` 报告 —— 新登记 `D-G101`（登记件与仓外夹具**同 inode**）＋ 新 `TASK-0707` ＋ 三处裁定 ＋ `D-G98`/`D-G96` 追加 ＋ 第十一笔推送

> lane=W122A｜**2026-09-23 08:35:46 → 2026-09-23 09:0x +0800**
> `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜fork 克隆 `C=~/netTest/GitProj/WPFOnLinux`
> 冻结基线 = **`#51` `38e67e834430d75c`**｜开工 `DEFREG=PASS declared=136`｜**零 `dotnet`／零构建／零门禁（`verify-all`）／零应用／不占槽／零 `pkill`**
> 纪律：**纯文本编辑 ＋ 一次推送**｜判据**先写**：`~/w122a/criteria.md`（**60 行**，写成本刻 `08:39:39`，**早于本车道任何仓内写动作**）
> 环境：kernel 见 `uname -r`｜开工 `loadavg 3.09 2.48 1.23`、`MemAvailable 2304 MB`
> ⚠️ 本报告**全部哈希／inode／行号均为现场现算**（`sha256sum`／`stat`／`wc -l`／`grep -n`），**零手抄**。

---

## §0 一句话结论

**六件事全部办完**：① 新登记 **`D-G101`**（**登记件与仓外夹具同 inode ⇒ 原地截断写写穿夹具**；**方向与 `D-G80` 相反**）＋ 主控转来 `W119A` 牙读数的**追加 bullet**；② 新 **`TASK-0707` [Next] 🔴**（把"硬链接/同 inode 共享"并进装置卫生牙）；③ **三处裁定**（口径澄清**复核**／数字更正**点名**／`TASK-0111` **顺序**）＋ **跨车道冲突待解**一行；④ **`D-G98` 追加**（`W115A` 中间结论五项要件）＋ **`D-G96` 追加**（仓外 2 处同形活实例）；⑤ 声明表 `--emit` 重生成（**ID 数 136 → 137，恰好 +1**）＋ `DEFREG` **两遍** `PASS declared=137 route_ids=137`／`DECLDRIFT=0`／`rc=0`；⑥ **第十一笔推送**。
**三条本件现场核出的更正／新发现**（都**只报不改上游**）：**(a)** 主控转来的 `W119A` 牙读数 `multilink=1388` 与本件**全树**普查 `12432` **不是矛盾、是同现象的两种口径**（本件按牙的 `skipdirs` 复算 ⇒ **1388，逐位相同**）；**(b)** 主控说的"改 `repin-generation.py` **会动 `inputs_fp`**" **不成立**（该件**不在** `fp_inputs()` 覆盖面，现场机械核 = **0 命中**）；**(c)** 本件全程在**移动靶**上作业 —— `W123A` 的**断链**把 `$R` 全树 `links>1` 从 **12432 打到 11011**、"源码/文档/登记表件的跨区同 inode"清成 **0** ⇒ **凡引本条必须带"读于何时"**。

---

## §1 开工/收工锚（**全是现场算**）

| 件 | 开工 sha16 | 收工 sha16 | 行数 | inode（开工→收工） | `links` |
|---|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `d85d0de47acb550c` | **`8c23214ab3b66af0`** | 2676 → **2717** | `5282308 → 5282507` | `1 → 1` |
| `docs/ROUTES.md` | `fe3e3fde0f456250` | **`af8b55a2f3a8906a`** | 564 → **589** | `4852680 → 4853013` | `1 → 1` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `dea8c731369ba0ed` | **`041e04f21cd37943`** | 145 → **146**（ID `136 → 137`） | `5383439 → 5387945` | `1 → 1` |
| **新建** `build/MilBridge/W122A-report.md`（本件） | — | 见文末自报行 | — | — | — |

**绝对禁区（开工 = 收工，逐位相同；本件现场复算）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`38e67e834430d75c`**｜`docs/CURRENT-STATE.md` **`b7b2d513cfdab2eb`**｜`handoff.md` **`e4dc264200b421d0`**｜`verify-all.sh` **`1aa2ae4e94827cf3`**｜`build/close-wave.sh` **`c757fd5058f1bfd4`**｜`build/integration-wave.sh` **`39e52f0049373059`**｜`build/MilBridge/known-red.json` **`089b7324ba12e022`**｜`build/MilBridge/tools/regression-decision.py` **`1eda9e3575960cba`**｜`docs/PREREG-TEMPLATE.md` **`75dfc5f3fbc9df40`**｜`build/MilBridge/tools/hygiene-tooth.sh` **`dc1e79a23dbb7eb2`**。**本件一个字节都没写它们**，也没碰 `~/w62a/negrepo/**`（夹具）、`~/w115a/**`／`~/w118a/**`／`~/w119a/**`／`~/w121a/**`。

---

## §2 ① `D-G101` 判词逐字（落点：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2687-2717`）

**标题行（逐字）**：
```
### `D-G101`（**装置缺陷 · 登记件与仓外夹具同 inode**）：判据/登记件与 `$HOME` 下的**负控夹具硬链接同一 inode** ⇒ **原地截断写会顺着共享 inode 写坏别人的夹具**（**方向与 `D-G80` 相反**：那条坏在"**读到旧的**"，这条坏在"**写坏别人的**"）
```
**要件（六条，逐条落）**：**① 判定点** = `stat -c '%h %i %n'` 逐件给 inode／`links`（表见下）｜**② 危险动作** = `> 件`／`sed -i`／`--emit > 件`（**原地截断**）｜**③ 后果** = 把**别人的负控夹具**改掉 ⇒ 污染他人判据（**且静默**：写者自己看不出）｜**④ 本次未被触发** = W120A 一律 `temp ＋ rename`，三个孪生夹具件 sha16 **开工 = 收工**｜**⑤ 教训** = 落盘一律 **`temp ＋ rename`**；涉及"传件进夹具"的实验**必须先查 inode/links**｜**⑥ 交叉引用** = `D-G80`（同族、**方向相反**）／`D-G96`（**证据保全**）／`D-G93`／`D-G94`；落地 = **`TASK-0707`**。

**判定点表（本件现场现算，`find ~ -xdev -inum` 现取孪生路径）**：

| `$R` 侧件 | inode | `links` | 同 inode 的**仓外**孪生件 |
|---|---|---|---|
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**冻结基线**） | `4983625` | `2` | `~/w62a/negrepo/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| `docs/CURRENT-STATE.md` | `5260312` | `2` | `~/w62a/negrepo/docs/CURRENT-STATE.md` |
| `handoff.md` | `5260310` | `2` | `~/w62a/negrepo/handoff.md` |
| `build/close-wave.sh` | `5018638` | `2` | `~/w113a/fixture/fp-farm/build/close-wave.sh` |
| `build/MilBridge/known-red.json` | `5251064` | **`3`** | `~/w62a/negrepo/…` **＋** `~/w113a/fixture/fp-farm/…` |
| `build/MilBridge/tools/defect-registry-check.sh` | `5254340` | **`3`** | `~/w62a/negrepo/…` **＋** `~/w113a/fixture/fp-farm/…` |

**射程（全树普查，不是抽样；口径 = 两侧逐文件 `lstat` 取 `st_ino`，按 inode 取交集）**：`$R` 共 **13374** 件，`links>1` = **12432 件（93.0%）**，**全部**在 `$R` 之外有孪生件（**`$R` 内部自链 = 0**）；孪生件区分布 = `~/w62a/negrepo` **12407**｜`~/w113a/fixture/fp-farm` **150**｜`~/w26d-G9` **6**｜`~/w110a` **5**；按 `$R` 顶节目录 = `upstream` **6417**｜`build` **3053**｜`tests` **2003**｜`samples` **699**｜`src` **150**｜`docs` **64**｜`tools` **38**｜仓根 **8**；剔除 `*/bin/*`／`*/obj/*` 后**仍有 7838 件**。**12432 对孪生件内容逐对相同**（同 inode 必同内容）⇒ **夹具与 `$R` 当时同形**。

### 2.1 追加 bullet（主控转来 `W119A` 牙读数 ＋ 主控裁定）—— 落 `:2710-2717`

| 要件 | 逐字要点（本件现场复核过每一条） |
|---|---|
| **① 三个链接点** | `$R/build/MilBridge/known-red.json` ＋ `~/w62a/negrepo/build/MilBridge/known-red.json` ＋ `~/w113a/fixture/fp-farm/build/MilBridge/known-red.json` —— **同 inode `5251064`、`nlink=3`**（现场 `find` 现取） |
| **② 写者行（决定性）** | `build/MilBridge/tools/repin-generation.py:112` 逐字 = `json.dump(d, open(REG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)` ⇒ **`open(...,"w")` 是原地写** ⇒ 下一次"重钉世代"**当场改掉两个车道的夹具**、**静默** |
| **③ 根因** | 夹具用 **`cp -al`（硬链接克隆）** 建 ⇒ **"副本"与本体同 inode** ⇒ 任何**原地写**都**穿透到夹具**。与 `D-G80`（`cp -al` 的"**读到旧的**"）是**同一手段的两个反面**：**`cp -al` 省钱，但把"读"与"写"都变成共享** ⇒ **要么真拷贝（`cp -a`／`cp -p`／reflink），要么所有写者一律 `temp ＋ rename`**，**不许只靠"记得别覆盖"** |
| **④ 规模 ＋ 两口径换算** | 牙 `multilink=1388`／`cross_region=1383`（牙口径：`HYG_SKIPDIRS='.git obj bin .artifacts upstream node_modules __pycache__ .vs TestResults .dotnet'`、夹具根 2 个）vs 本件全树 **12432** ⇒ **同现象两口径**；本件按牙的 `skipdirs` 复算全树名单 = **1388**（**与牙逐位相同** ⇒ 换算闭合）。⇒ `~/w62a/negrepo/**` 基本是 `$R` 的**硬链接农场**（**含两颗牙 `pc-line-step.sh`／`frame-step.sh`**）⇒ **只报不判红**（不在覆盖面）**但要点名** |
| **⑤ 处置（主控裁定）** | **两条都做**：① **断链**（`$R` 侧 `temp ＋ rename`，**只改 inode、内容 sha16 逐位相同**）② **改写者**（`repin-generation.py` 改 `temp ＋ rename`，行为等价 ＋ 同输入同 sha16）。**正在由车道 W123A 执行** |
| **⑥ 只报（仓外 `D-G96` 同形）** | 牙点到 `~/w63a/bin/control.sh:15` 与 `~/w63a/bin/campaign.sh:52`，逐字均为 `: > "$PROG"`（**本件现场逐行复核**）⇒ 见 §3.4 |

### 2.2 ⚠️ 本件现场机械核出的**一处更正**（如实记，不替主控改判）

主控原话：「两者都必须排在 `IN_FP_0`（`close-wave.sh:202`）之前（**该件在 `fp_inputs()` 名单内 ⇒ 会动 `inputs_fp`**）」。**本件现场复算 `close-wave.sh` 的 `fp_inputs()` 全链**（**4 条 `find`**：`:104`／`:108`／`:115`／`:124`　＋　**`:214` 起的 `printf` 显式名单**）：

```
$ cd $R && { <4 条 find 原样> ; printf '%s\n' <:214 起的 20 件原样> ; } | grep -c 'repin-generation'
0
$ ... | grep -c .      # 覆盖面件数
149
$ ... | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1
72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015
```

⇒ **`repin-generation.py` 不在覆盖面**（`build/MilBridge/tools/**` 只进了 `printf` 名单里**显式列举**的那几件；`find build` 那条的有效 `-maxdepth` = **1**、且名字只收 `patch-*.py`／`port-lib.py`／`integration-wave.sh`／`close-wave.sh`）⇒ **改它本身不动 `inputs_fp`**。
**但** `build/MilBridge/known-red.json` **在名单里**（`:214` 逐字列举）⇒ **断链只改 inode、内容 sha16 逐位相同 ⇒ `inputs_fp` 也不变**（该函数是**内容**指纹：`find … | LC_ALL=C sort | xargs sha256sum | sha256sum`）。
⇒ **口径**：「排在 `IN_FP_0` 之前」**仍是稳妥做法**（断链会动上**万件**的 inode、其中含名单内 **1 件**），**但"必然移动 `inputs_fp`"这个理由对 `repin-generation.py` 不成立**。

### 2.3 📉 本件在**移动靶**上作业（必须带"读于何时"，防误引）

**§2 的 `12432`（以及牙的 `1388`）是"`W123A` 断链之前"的读数**。本件收工前现场复算：

| 读数 | 值 |
|---|---|
| `$R` 全树 `links>1` | **11011**（**全部**落在 `upstream/**` **6417** 或 `*/bin/*`／`*/obj/*`） |
| `find $R -type f -links +1 \| grep -v '/bin/' \| grep -v '/obj/' \| grep -v '^upstream/'` | **0 行** ⇒ **"源码/文档/登记表件的跨区同 inode"已清成 0** |
| 五件"禁区/冻结件" | **现在全 `links=1`**：`ACCEPTANCE-BASELINE.md` `4983625 → 4853230`｜`CURRENT-STATE.md` `5260312 → 4853422`｜`handoff.md` `5260310 → 4853421`｜`close-wave.sh` `5018638 → 4853284`｜`defect-registry-check.sh` `5254340 → 4853419` |
| `known-red.json` | **`$R` 侧已断**（`5251064 links=3 → 4853410 links=1`）；**夹具侧两件仍互为 `links=2`（同 inode `5251064`）**、内容 sha16 **`089b7324ba12e022` 三处逐位相同** |
| 牙在同一时刻 | `HYGIENE_INODE_ROSTER repo_files=1494 fixture_files=13132 **multilink=0 cross_region=0** fixture_roots=2 missing=0` ⇒ `HYGIENE_INODE=**PASS**` ＋ `HYGIENE_TOOTH=**PASS** roots=PASS evidence=PASS inode=PASS scope=REPORT semantic_undecidable=7 … code_files=72`、**`rc=0`**（本件现场跑） |

⇒ 与主控转来的**断链前**快照（`HYGIENE_TOOTH=FAIL … inode=FAIL … multilink=1388 cross_region=1383`）**不同**。**判词本体（缺陷存在、机制、教训）不因断链失效** —— 断链只**治好了这一处的现状**，**成因（`cp -al` × 原地写者）仍在**。

---

## §3 ② `TASK-0707` ＋ ③ 三处裁定 ＋ `D-G98`／`D-G96` 追加（逐字落点）

### 3.1 `TASK-0707`（`docs/ROUTES.md:463-468`）
```
- `TASK-0707` [Next] 🔴 **把"硬链接/同 inode 共享"并进装置卫生牙**（来源 = **`D-G101`** 的落地；主控已把这一类**追加**给正在做前三类的车道 **W119A**）：
```
**三格** = ① 列 `links>1` 的件 ② 列**跨区同 inode 对**（`$R` ↔ `$HOME` 夹具区）③ 对登记夹具件做"**开工 = 收工 sha16**"可复算断言。**三态** = 跨区对存在 ⇒ `FAIL` **逐对点名**／**仅 `links>1` 无跨区对**（同区自链，如 `*/bin/*`）⇒ **只报行不判红**（判红就是**造假红**）／查不动 ⇒ `NOINFO`。**`--selftest` 两例两极化** = 造硬链接对 ⇒ **必红**；改 `temp ＋ rename` ⇒ **必回绿**。**正在由车道 W119A 实现**。

### 3.2 裁定一 · 口径澄清**复核**（`KNOWN-DEFECTS.md:2662`）

| 复核项 | 现场机械证 |
|---|---|
| **两处同文** | `docs/ROUTES.md:432-436` vs `KNOWN-DEFECTS.md:2652`：关键子句 `当只有"一腿一个样本"时`／`new-only 也必须判`／`rate-aggravated`／`131`／`NOINFO` —— **两处各命中 1 次** |
| **原话未改** | 地图 `:431` 与册 `:2651` 的 ③ 原话**都仍在**（`grep -F '在旧件上也要能复现该红'` **两处各 1 命中**） |
| **改前独有行 = 0** | `git diff 846243d^ 846243d -- docs/ROUTES.md \| grep -c '^-'` = **0**；同笔 `KNOWN-DEFECTS.md` = **1 插入 0 删除** |

### 3.3 裁定二 · 数字更正**点名**（`docs/ROUTES.md:450`）

**发现**：`W120A` 的更正 bullet（`:449`）里写的是"**上一行**" —— **没有点名**。⚠️ 而"上一行"**字面也不对**：`:449` 的上一行是 `:448`（讲工具的），被更正的 `20/20` 在 **`:443`**（**隔着 6 行**）。
**追加**（原文一字未动）：被更正的那一行 = **`docs/ROUTES.md:443`**；**W120A 动手前 = `:438`**（W120A 在 `:431` 之后插了 **5 行** dated 澄清 ⇒ 顺移）⇒ **两个号都记**。
**现场复算（两遍 `cmp` IDENTICAL，`rc=0`）**：`REGDEC_SELFTEST_ROSTER cases=22 pass=22 fail=0`｜**`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`**｜`ST_ATTEST=PASS`（`sha16=1eda9e3575960cba`）⇒ **正确值 = `22/22`**。
⚠️ **本件现场自己纠了一处**：我第一版写成"全件 `grep -n '20/20'` **唯一命中** `:443`" —— 现场核出 **追加前 = 3 命中**（`:443`／`:449`／`:557`），**只有 `:443` 是"登记错值"那一行**、另两处是**更正 bullet 自己的引文**。**该假机读断言已被本件自己改正**（逐字见 `:450`）。

### 3.4 裁定三 · `TASK-0111` 状态与顺序（`docs/ROUTES.md:560-561`）＋ 跨车道冲突

- **先落 `N3`**（归因面扩到 `XChangeProperty`／`XSendEvent`／`XSetWMNormalHints`／`XSetInputFocus`／`XRaiseWindow`，**在红腿上对齐**）；**`N1` 暂缓** —— **依据 = 引 `W115A` 成对读数**（属性写对几何**零贡献**：`hints` 臂 **`0/136`**、`Fisher(hints vs none) = p = 1`）⇒ 先落 `N1` 只拿到"**红率不变**"的空结果。**状态位仍 `🔴`、不许写 ✅**。
- **跨车道冲突待解（主控追问）**：`W115A` 的 `maxhint` **`0/120`**（⇒ 读作"**不强制 `PMaxSize`**"）vs `W93A` `H2-b`（`xdotool windowsize 1000x800` ⇒ **被压回 `667x500`**，⇒ 读作"**WM 严格执行提示**"）—— **两句不能同时为真**；**正在由 W115A 同屏同配方并排量，结论未出前两句话都不许当已定**。⚠️ 本件现场核：`W115A` 报告 §5 **只**自报了"与 `D-G88` 不冲突"（`D-G88` 说的是**提示到不了 X**），**没有**处理与 `H2-b` 这一格 ⇒ **这一格确实待解**。

### 3.5 `D-G98` 追加（`KNOWN-DEFECTS.md:2647-2654`）—— ⚠️ **两组 `N` 都过期**

**五项要件**（主控原话逐字落）：**①** `hints` 臂 `0/N` ⇒ "该写本身造不出'被打回'"**成立**｜**②** 必要性纯 X **判不了 ⇒ `NOINFO`**（探针自己**既是客户又是写者**），**明写"不许读成'不必要'"**｜**③** 支持的是「**纯 X 口径下"被打回"必须有一次客户几何请求；属性写可有可无**」｜**④** "必须属性写＋几何写同时发生"**无支持读数**（**既不许写成"已证伪"，也不许写成"成立"**）｜**⑤** 与 `W114A` 的关系**逐字照抄**："不是同一机制的两半，而是**两个层面的排除互相咬合** …"。

**⚠️ 本件现场核出的读数漂移（如实记）**：

| 来源 | `none` | `hints` | `hints+geom` | `maxhint` | `maxhint+oversize` |
|---|---|---|---|---|---|
| **主控转来的中间快照** | `0/144` | `0/144` | `144/144` | `0/130` | `130/130` |
| **本件现场读 `W115A` 报告 §4 表**（`08:4x`，报告 **372 行**） | **`0/137`** | **`0/136`** | **`136/136`** | **`0/120`** | **`0/119`（`OTHER-GEOM`）** |

`Fisher(hints vs none)` 两版都 **`p = 1`**；`Fisher(hints+geom vs none)` 现为 **`1.368e-81`**；`hints` 的 95% 单侧上界 **`2.18%`**。该报告**自己**写着"**本版生成时两批都还在跑**（`:182` = **368/600**、`:183` = **198/400**）⇒ 由 `~/w115a/bin/await-and-finalize.sh` 在两批跑满后**自动重算并就地替换**" ⇒ **两组数都只是快照**，**结论不因计数变化**（`hints` 的 `0/n` 上界在 `n=99/123/200` = `2.98%`／`2.41%`／`1.48%`，**全都 < 应用侧 6%**）。⇒ **引本条必须带"读于何时 ＋ 报告哪一版"**。
⚠️ 另：主控说的"`W115A` 报告 `:182` 记 **144 趟/臂**" —— 本件现场读 **`:182` = `maxhint` vs `none`：`0/120` vs `0/137` ⇒ `p = 1`**，**不是** 144/臂 ⇒ 那个行号引用**已过期**。

### 3.6 `D-G96` 追加一行（`KNOWN-DEFECTS.md:2588`）
**仓外仍有 2 处同形活实例未修（只报不改）**：`~/w63a/bin/control.sh:15` 与 `~/w63a/bin/campaign.sh:52`，两处逐字均为 **`: > "$PROG"`**（截断写，指向 `*.progress` 形态的**跨趟固定**证据名）—— **本件现场逐行复核**。⇒ 该册"全 `$HOME` 还有几处"那一格从 `NOINFO` **收窄为"至少还有这 2 处（仓外、未修）"**，**仍未逐处枚举 ⇒ 仍是 `NOINFO`**。

---

## §4 ④ 改了哪几件（before/after sha16 ＋ 只加不删 ＋ 落盘方式）

| 件 | before sha16 | after sha16 | `git diff --numstat`（增/删） | `comm -23` 改前独有行 | `wc -l` |
|---|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `d85d0de47acb550c` | **`8c23214ab3b66af0`** | **41 / 0** | **0** | 2676 → **2717** |
| `docs/ROUTES.md` | `fe3e3fde0f456250` | **`af8b55a2f3a8906a`** | **25 / 0** | **0** | 564 → **589** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `dea8c731369ba0ed` | **`041e04f21cd37943`** | 3 / 2（只动 `DECL-GEN` 时间戳与 `KD` 锚 ＋ 1 行新 ID） | —（机械重生成件） | 145 → **146** |

**落盘方式（本件的承重纪律，因为本件登记的正是"原地截断写"这条缺陷）**：**全部 4 次写动作一律 `temp ＋ os.replace`（`rename`）**，`--emit` 的输出**先落到 `$HOME` 临时件**（`~/w122a/decl.new.tsv`）**再 `mv` 就位**；**零** `>`／`sed -i`／`tee 件`。
**inode 逐次现算（证明不是原地写）**：`KNOWN-DEFECTS.md` `5282308 → 5282327 → 5282308 → 5282507`｜`ROUTES.md` `4852680 → 4852611 → 4853013`｜声明表 `5383439 → 5387945`。
⚠️ **一处诚实提醒（本件现场踩到）**：`KNOWN-DEFECTS.md` 第二次落盘时 `rename` **恰好复用了上一次释放的 inode `5282308`**（与**开工 inode 相同**）⇒ **"inode 变了吗"这个自检会给出假阴性** ⇒ 该自检**必须与"内容 sha16 是否按预期变"配对用**，**单看 inode 不可靠**。

**零污染（成对证明，开工 = 收工，逐位相同）**：`~/w62a/negrepo/docs/PORT-SPEC.md` **`7f36186d68a18332`**｜`~/w62a/negrepo/docs/INDEX.md` **`c36ed5fe2a5904a7`**｜`~/w62a/negrepo/build/MilBridge/tools/defect-registry-declared.tsv` **`934a29ed9ab399ab`**｜`~/w62a/negrepo/build/MilBridge/known-red.json` **`089b7324ba12e022`**｜`~/w113a/fixture/fp-farm/build/MilBridge/known-red.json` **`089b7324ba12e022`**。另：`find ~/w122a -type f -links +1` = **0**（全程**零 `ln`**）。

---

## §5 ⑤ `DEFREG` 两条机读行（**现场跑两遍、`cmp` IDENTICAL、`rc=0`**）

```
DEFREG_DECL=n=137 route_ids=137 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=137 route_ids=137（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```
**`--emit` 重生成**：`bash build/MilBridge/tools/defect-registry-check.sh --emit > ~/w122a/decl.new.tsv`（`rc=0`）⇒ 新增行 **`ID	D-G101	req=KD	present=KD`** ⇒ **ID 数 `136 → 137`（恰好 +1）**。**`CS`／`HO`／`AB` 三条锚逐位未变**（`b7b2d513cfdab2eb`／`e4dc264200b421d0`／`38e67e834430d75c`）。⚠️ 引用编号前**已现场确认 `D-G101` 原先不存在**（`grep -c 'D-G101'` = **0**）⇒ 无幻影声明行。

---

## §6 ⑥ 推送（第十一笔）＋ `BYTECHECK`

| 项 | 值 |
|---|---|
| **推送前 head** | **`b1d3ad6a8da723f6908c0bea729916df789b3ed4`**（现场 `git rev-parse HEAD` ＋ `git ls-remote origin feat-Linux` **双核**，逐位相同） |
| **提交 A**（本笔件） | **`2192c5a7c57f29e8c93cf73b736b5f5e1b411028`** —— 3 件：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`41+/0−`）｜`docs/ROUTES.md`（`25+/0−`）｜`build/MilBridge/tools/defect-registry-declared.tsv`（`3+/2−`） |
| `git fetch` | `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 陷阱**；push **前**一次、push **后**再一次） |
| `git push` | 输出逐字 = `b1d3ad6..2192c5a  feat-Linux -> feat-Linux` |
| **push 后重新 fetch ＋ 与 `ls-remote` 交叉核** | `local = 2192c5a7c57f29e8c93cf73b736b5f5e1b411028` **＝** `remote = 2192c5a7c57f29e8c93cf73b736b5f5e1b411028` ✅（**先 fetch 再核** ⇒ 避开 W107A 踩过的"取到 push 前的 ref ⇒ 假 MISMATCH"） |
| `--symref` | **`ref: refs/heads/feat-Linux\tHEAD`**（**仍 `feat-Linux`**）✅ |
| **`BYTECHECK`（逐件字节核对本笔件）** | **`ok=3 mismatch=0 nobody=0`** —— 口径 = `git cat-file blob 2192c5a7…:<path> \| sha256sum` **vs** 盘上 `sha256sum`：`build/MilBridge/tools/defect-registry-declared.tsv` `041e04f21cd37943`｜`docs/ROUTES.md` `af8b55a2f3a8906a`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` `8c23214ab3b66af0` 三件**逐位相同** |

**提交 B（本报告）**：`build/MilBridge/W122A-report.md` **单独一笔**（**报告装不进自己的 blob** ⇒ 其自身 `BYTECHECK` 只能在 push 后补算，读数写在 `~/w122a/STATUS.md`，**本报告不预测**）。
**`git add` 纪律**：**逐径 `git add`，零 `-A`／零 `--force`**；提交 A 前 fork 工作树 `git status --porcelain` **恰好只有本笔 3 件**（现场核）。
**⚠️ 不推别家在飞件（**只报不推**）**：`build/MilBridge/tools/hygiene-tooth.sh`（W119A，`dc1e79a23dbb7eb2`）｜`build/MilBridge/W115A-report.md`／`W118A-report.md`／`W119A-report.md`／`W121A-report.md`｜`build/MilBridge/tools/uia-door-check.sh`／`ime-landing-check.sh`（W121A，均**不在**本笔）｜native 源与产品件｜`tests/parity/**` 大件｜W113A 的 4 件 —— **一件都没进本笔**。

---

## §7 ⑦ `fp_inputs` 影响（机械证；**现值仍是 `72c5f226…`**）

**现场真调用**（复算 `close-wave.sh` 的 `fp_inputs()` 全链：**4 条 `find` ＋ `:214` 起的 `printf` 显式名单**）：
```
72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015      # 覆盖面 149 件
```
**逐位 = `§15i`／`§15j` 记的现件值** ⇒ **本笔零位移**。**归因机械证**：本笔编辑的 **4 件**（`KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/W122A-report.md`）**在 149 件覆盖面里命中全 0**（`defect-registry-check.sh` 在名单里，**声明表本身不在**；`docs/**` 一件都不在）。
⚠️ **本件没跑** `close-wave.sh`／`verify-all.sh`／`integration-wave.sh`（只**只读地**抽了 `fp_inputs()` 的函数体现算）。⚠️ 若 `W123A` 的**断链**在 `IN_FP_0` 之后完成，**它也不会移动** `inputs_fp`（内容未变）—— 但**按惯例仍应安排在 `IN_FP_0` 之前**（见 §2.2 的口径更正）。

---

## §8 ⑧ `NOINFO`／未做

1. **`NOINFO`：`$R` ↔ fork 克隆 `~/netTest/GitProj/WPFOnLinux` 之间的同 inode 关系未判** —— 本件普查把 `$HOME/netTest/**` 整体排除在外（fork 克隆就在里面）。
2. **`NOINFO`：这些硬链接"是哪个车道/哪一步造出来的"未归因** —— 本件只量"现在是什么状态"。**机制**已由 `W119A`／本件指到 `cp -al`，但**建夹具的那条命令/那一趟没被机械定位**。
3. **未做：`~/w62a/negrepo` 夹具的"建夹具方式"治理**（改成 `cp -a`／reflink）—— 不在写域，**只报不改**。
4. **未做：`~/w63a/bin/control.sh`／`campaign.sh` 两处 `: > "$PROG"` 未修**（仓外、别的车道的件）—— 按主控要求**只在 `D-G96` 条追加一行"只报"**。
5. **未做：`TASK-0707` 的实现**（立号件是纯文本登记波；实现**由 W119A 承担**，本件**不替它报任何数**）。
6. **未端到端复跑任何门禁** —— 本件**零 `dotnet`／零门禁**（任务书明令）。
7. **`W115A` 的读数仍在漂移**（报告自标两批未跑满）⇒ 本件记的 `137/136/136/120/119` **也只是快照**；**"报告哪一版"未固定**（该报告尚无冻结版本号）⇒ 该格**只能带"读于何时"**。
8. **本件自纠一处**：§3.3 末尾那条"唯一命中"的假机读断言（**已改正并留档**）。
9. **未做：`W123A` 断链的独立复核** —— 本件只记"断链正在进行"的当刻读数（`links>1` 12432 → **11011**、源码/文档/登记表件 = **0**），**没有**验证它"只改 inode、内容 sha16 逐位相同"这条约束是否对**全部**件成立。

---

## §9 ⑨ 大白话小结（≤6 行）

1. **立了一条新缺陷 `D-G101`**：`$R` 有**上万件**与 `$HOME` 下的**负控夹具硬链接同一 inode**（`cp -al` 建夹具造成的），所以 `> 件`／`sed -i`／`--emit > 件` 这类**原地截断写会把别人的夹具一起改掉**，**而且静默**——**方向与 `D-G80` 正好相反**（那条是"读到旧的"，这条是"写坏别人的"）。
2. **最险的几件都在链上**：**冻结基线 `ACCEPTANCE-BASELINE.md`**、`CURRENT-STATE.md`、`handoff.md`、`close-wave.sh`、`known-red.json`（`links=3`）——本件全程**只用 `temp ＋ rename`**，并**成对证明**夹具 sha16 开工=收工。
3. **因果链被钉死了**：夹具是 `cp -al` 建的 ＋ `repin-generation.py:112` 用 `open(REG,"w")` **原地写** ⇒ **下一次重钉世代就会改掉两个车道的夹具** ⇒ 处置＝**断链 ＋ 改写者**（`W123A` 正在做）。
4. **顺手更正主控两处**：①牙的 `1388` 与本件的 `12432` **不是矛盾**（同一现象两种口径，按牙的 `skipdirs` 复算 = **1388 逐位相同**）；②改 `repin-generation.py` **不会**动 `inputs_fp`（它**不在** 149 件覆盖面里）。
5. **三处裁定 ＋ 两组追加都落册了**（口径澄清复核、`20/20` 更正**点名到 `:443`**、`TASK-0111` **先 `N3` 后 `N1`**；`D-G98` 五项要件、`D-G96` 仓外 2 处）——**所有上游判词原文一字未动**，改前独有行 = **0**。
6. **`DEFREG` 两遍 `PASS declared=137`／`DECLDRIFT=0`／`rc=0`**（136 → 137，恰好 +1）；⚠️ **本条在移动靶上写的**：`W123A` 断链已把源码/文档/登记表件的跨区同 inode 清成 **0**，**引本条必须带"读于何时"**。

---

<!-- SHA16-W122A 见下（口径：`grep -v '^<!-- SHA16' 本文件 | sha256sum | cut -c1-16`） -->
<!-- SHA16 2840d3fa120d76cf -->
