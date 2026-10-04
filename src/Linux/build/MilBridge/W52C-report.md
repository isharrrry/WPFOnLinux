# W52C 报告 —— `#49` `C1`：把 `PresentationFramework.dll` / `WindowsBase.dll` 纳入 app-local 副本校验器

> **一句话**：两份权威已纳入（`ITEMS` 6 → 8，两张表同趟改，`ITEMS_SYNC=YES`）；`--selftest` **18/18 全 PASS、rc=0**；
> 真实树立刻暴露出 **34 份 `STALE` + 4 份 `UNEXPECTED-DIFF` + 4 组 `DIVERGENT`**（全部逐条登记进新建的 `known-red-PFWB-copies.md`）；
> 两极化（删副本 ⇒ 具名 `MISSING` + `rc=1`／`cp -p` 整份还原 ⇒ 回绿）**实测成立**，而**改前同一实验完全静默**。
> 另**推翻任务书与预登记的两条前提**（见 §6.1／§6.2），并在**夹具**层面修掉 4 例因 `#39` 切配置而**早已变红**的自检子例。

---

## §0 环境与件 sha16

**读数纪律**：本报告每一行数字都由 `lane=W52C` 本趟现场 `sha256sum`／`stat` 取得（无一处手抄或凭记忆）。

| 量 | 值 |
|---|---|
| 车道 | `W52C`（任务 `C1`） |
| 时间窗 | 2026-09-20 10:04:48 → 10:21:06（+0800） |
| 内核 | `6.8.0-138-generic` |
| `nproc` | 3 |
| `loadavg` | **实测两次**：10:15 → `1.01 0.89 0.71`；10:21 → `1.13 1.07 0.84`。⚠️ **本车道开工那一刻的 loadavg 我没有记**（自伤：第一条命令只取了 `free`/`nproc`）⇒ 起点值**写 `未取到`**，不编 |
| `MemAvailable` | 10:04 → 2,919 MB ／ 10:15 → 2,796 MB ／ 10:21 → 2,925 MB（始终 > 1,200 MB ⇒ 无等待） |
| `SELFBUILT_CONFIG` | **`Release`**（`build/SelfBuiltConfig.props:28` ⇒ `bash build/selfbuilt-config.sh` 现场读回） |

### 件 sha16（改前 → 改后）

| 件 | 改前 sha16 | 改前字节 | 改后 sha16 | 改后字节 | 改后 mtime |
|---|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `a5102051114c80e1` | 94,418 | **`d82e920b49bb0f0f`** | 102,043 | 2026-09-20 10:19:15 |
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | `219516c6cf3bf376` | 28,769 | **`a7e05921b77524c2`** | 29,553 | 2026-09-20 10:07:32 |
| `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | —（新建） | — | **`7b113a11934c54c4`** | 19,658 | 2026-09-20 10:16:33 |
| `build/MilBridge/W52C-report.md`（本报告） | —（新建） | — | 见文末 §7 末行（**正文写完后回填**） | — | — |

改前件逐字节留档（回退证用）：`/tmp/w52c-check-applocal-sync.sh.bak` = `a5102051114c80e1`（94,418 B）、`/tmp/w52c-applocal-expect.py.bak` = `219516c6cf3bf376`（28,769 B）—— 均为 `cp -p` 全份备份。

### 两份新权威（本册全部"红"的裁判；现场 `sha256sum`）

| 件 | 权威路径（`$SELFBUILT_CONFIG=Release`） | sha16 | 字节 | mtime |
|---|---|---|---|---|
| `PresentationFramework.dll` | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1011da6390c3bf1e` | 6,119,424 | 2026-09-20 00:13:43 |
| `WindowsBase.dll` | `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` | `79740e9ba7fbf9ca` | 1,111,552 | 2026-09-20 00:12:23 |

### 环境相关位移（如实报，非本车道所为）

- `build/SelfBuiltConfig.props` mtime = **2026-09-19 11:11:43**，而 `check-applocal-sync.sh` 改前 mtime = **2026-09-19 11:03:51**
  ⇒ **配置切到 `Release` 发生在该检查器最后一次改动之后 8 分钟** ⇒ **切配置后没有人重跑过 `--selftest`**（§2.4 的四条红就是这么来的）。
- 全程**零 `dotnet`**、**零构建**、**零 `pkill -f`**；未跑 `verify-all.sh` / `close-wave.sh` / `integration-wave.sh`；
  未改 `verify-all.sh`、`build/MilBridge/tools/**`、`docs/**`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`handoff.md`（写域外一件未动）。

---

## §1 改了什么（逐处 `文件:行` + 为什么）

### 1.1 判据面（**唯一的"覆盖面"改动**）

| # | 位置 | 改动 | 为什么 |
|---|---|---|---|
| ① | `check-applocal-sync.sh:167` | `ITEMS` 增 `"PresentationFramework.dll\|$REPO/build/PresentationFramework.Linux/bin/$SELFBUILT_CONFIG/PresentationFramework.dll\|…"` | `C1` 的本体：此前 PF **一条逐份判据都没有** ⇒ 删掉任何一份副本**连 `MISSING` 都不报**（`D-A2` 同族）。权威路径写法照既有条目：**配置跟随唯一声明**（不写死 Debug/Release） |
| ② | `check-applocal-sync.sh:168` | `ITEMS` 增 `"WindowsBase.dll\|$REPO/build/WindowsBase.Linux/bin/$SELFBUILT_CONFIG/WindowsBase.dll\|…"` | 同上（WB） |
| ③ | `applocal-expect.py:73-79` | 同一张表加 `("PresentationFramework.dll", …+ CFG +…)` 与 `("WindowsBase.dll", …+ CFG +…)` | **两处 ITEMS 必须一致**（该文件 `:61` 自己的纪律）；不加则**删副本不报 `MISSING`**（另一半洞）。路径文本与 ① ② 逐字相同 |
| ④ | `check-applocal-sync.sh:1017-1018`、`:1058` | **第二本册子**接线：`REGISTRY2=…/known-red-PFWB-copies.md`；`show_registry()` 增可选参数；末尾多印一段 | 检查器原先**只读** `known-red-PC-copies.md` 一本（`REGISTRY="${REGISTRY_FILE:-…}"`）⇒ 新册子会"写了没人看"。**只读只打印**，不改任何 `CNT_*`／`rc`／目录；显式 `REGISTRY_FILE` 时**只读那一本**（向后兼容实测：两处调用变 1 段） |

**判据一行没放松**：没有改任何阈值、分类规则、`NO-AUTHORITY`/`SKIP` 口径、`APPSYNC` 判定式或退出码。

### 1.2 自检夹具（**因 `ITEMS` 6→8 与 `#39` 切配置而必须同趟跟上**；判据语义一字未改）

| # | 位置 | 改动 | 为什么（每条都有实测读数） |
|---|---|---|---|
| ⑤ | `:101`、`:612`、`:645`、`:857` | 文案"六件权威"→"**八件权威**" | 权威数由 `ITEMS` 长度决定；夹具/注释必须跟上，否则读者按旧基数理解 `AUTH-MISSING=0` |
| ⑥ | `:614-623`（E 段）`mkdir`/`cp` | 沙箱权威目录一律 `bin/$SELFBUILT_CONFIG`；**新增 PF/WB 两份权威** | ① `ITEMS` 6→8 ⇒ 沙箱必须齐八件；② 夹具原先把权威一律摆 `bin` 下的 **Debug** 目录，而 `ITEMS` 找 `bin/Release` ⇒ 实测**改前件 `AUTH-MISSING=4`／本件 `AUTH-MISSING=6`** ⇒ E 断言的是 `AUTH-MISSING=0` ⇒ **该条改前就已经是红的**（§2.4 实测） |
| ⑦ | `:855-871`（O 段）`mkdir`/`cp`/`mv`/还原 | 同上（含"移走一份权威"与 `cp -p` 还原两处路径） | 同 ⑥；`D-G8` 的反极性要"移走 `ReachFramework.dll` ⇒ `AUTH-MISSING=1`"，路径必须指向**真的**权威位 |
| ⑧ | `:907-925`（P 段）`mkdir`/`cp` + **新增** `cp "$REPO/build/SelfBuiltConfig.props" "$PREPO/build/SelfBuiltConfig.props"`（`:925`） | 权威目录 config 化 + 新增 PF/WB + **沙箱自带配置声明** | 前者同上；**后者是本趟新发现的跨文件不一致**（§6.3）：两张表读配置的**相对位置不同** ⇒ 合成权威根里一侧 Release、一侧静默回退 Debug ⇒ `MISSING=5` 假红。夹具把同一份声明复制进沙箱即消（判据与断言一字未改） |
| ⑨ | `:598-605`（D 段） | 新增合成"只声明 Debug"的临时声明件，并以 `SBC_DECL="$tmp/decl-Debug.props"` 跑这一趟 | D 要测的判据 `:369` `is_release_path && is_debug_auth` **只在"权威是 Debug"时可达**；`#39` 切到 Release 后该类**结构性不可达** ⇒ 该条变**假红**（实测：改前 `SELFTEST_D=FAIL`，根因 = `UNEXPECTED-EQ`）。夹具用一张临时声明把"权威配置 ≠ 副本配置"**如实造出来**，要断言的 `NO-AUTHORITY`／`NO-AUTHORITY=1`／`rc=0` **逐字未改** |
| ⑩ | `:757`、`:776`、`:788`（L／L2／N 段） | `$REPO/src/WpfGfx.Linux/bin/Debug/…` → `…/bin/$SELFBUILT_CONFIG/…` | L2 断言"**内容 == 权威**"⇒ 取样路径必须是**真权威**（切配置后 Debug 取样 ≠ Release 权威 ⇒ 会退化成 `UNEXPECTED-DIFF` ⇒ 假红） |

**夹具改动自证**：`bash -n` 通过；`SHELL_QUOTE_TRAP=PASS traps=0`；`SELFCONFIG_DEBT_CHECK=PASS live=141 max=167`
（本件自身 `bin/Debug` 行数 **91 → 69**：夹具权威路径 config 化让本件欠账**净减 22 行**，改前全仓 163 → 现 141，**棘轮只减不增**）。
⚠️ 自查自伤一处：我第一版注释里写了 3 行含 `bin/Debug` 字面串的散文，会让这把棘轮**加账**；已改写成不含该字面串的措辞
（注：那 3 行的净账被上面 22 行的减账覆盖，实测仍是净减）。

**没有动的东西**：`sync-applocal-authority.sh`（只跑干跑）、任何 app-local 副本、`known-red-PC-copies.md`（一字未动）。

---

## §2 自检 18 例结果

### 2.1 改后（全绿）

命令与读数（原文照录）：

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest
SELFTEST_A=PASS（两类错件都被报红，exit=1）
SELFTEST_B=PASS（exit=0，全绿：.so + .dll + 产出目录那份，且都有声明式来源）
SELFTEST_C=PASS（旧 provider dll 被跨副本判定抓出）
SELFTEST_D=PASS（无权威 ⇒ 计入 NO-AUTHORITY、exit=0，不再冒充 MISMATCH）
SELFTEST_E=PASS（权威同 sha ⇒ exit=0 绿；权威换 sha ⇒ exit=1 红；两趟 AUTH-MISSING=0 ⇒ 沙箱八件权威俱全，目录随 SELFBUILT_CONFIG=Release）
SELFTEST_F=PASS（桩件被 SKIP(stub) 打出来但不判不一致，exit=0）
SELFTEST_G=PASS（obj 只 SKIP；bin 的落后副本仍报红、exit=1）
SELFTEST_H=PASS（库输出 1 份 LIB-COPY 不判；宿主里那份被判定、exit=1）
SELFTEST_I=PASS（小写 release/ 的落单副本被抓出，exit=1）
SELFTEST_J=PASS（有 HintPath ⇒ 判定并报红 exit=1；无 HintPath ⇒ LIB-COPY 不判 exit=0）
SELFTEST_K=PASS（期望基数 删前=10 / 删后=10 **不变**；删⇒MISSING 红 exit=1；整份还原⇒绿 exit=0）
SELFTEST_L=PASS（多余副本被报 UNEXPECTED 且计红 exit=1）
SELFTEST_L2=PASS（内容==权威的未声明副本被**具名**报出且仍然红 exit=1 —— 不许洗绿）
SELFTEST_N=PASS（内容≠权威的未声明副本走 DIFF 类、硬失败 exit=1）
SELFTEST_M=PASS（summary + 写点清单 + "删除不会被报出"三件都在）
SELFTEST_M2=PASS（同一棵树（snapPre==snapPost==expM2）：invisible_capped=26 ⇒ 截断自称**且数字相符**；invisible_ext_write=5 ⇒ 补扫自称且逐条印）
SELFTEST_O=PASS（权威俱全 exit=0 绿；移走一份权威 exit=1 红[AUTH-MISSING=1]；cp -p 还原 exit=0 绿；判定计数器两趟逐字相同 ⇒ 红只来自该新信号）
SELFTEST_P=PASS（锚一致 exit=0 绿｜两份一起换旧 exit=1 红[BRIDGE-ANCHOR=2]｜只还原一份 exit=1 红[=1]｜整份还原 exit=0 绿｜记录删锚行 exit=1 红[BRIDGE-NOINFO=1]；判定计数器三趟逐字相同 ⇒ 红**只**来自 ⑦）
SELFTEST=PASS
$ echo $?   →   0
```

- **`SELFTEST_[A-Z0-9]+=PASS` 计数 = 18**（`grep -c` 现场算）；**`SELFTEST=PASS` + `rc=0`** ⇒ 末态为 `0` 而非 `3`（**没有** `NOINFO` 混进"绿"）。
- ⚠️ **任务书写的是"17 例"，现场实测是 18 例**（A,B,C,D,E,F,G,H,I,J,K,L,L2,N,M,M2,O,P ⇒ 18 个子例；文件头 `:142` 自己也写 18）⇒ 以现场为准，任务书那个数**少了一个**（大概是漏数了 `L2`）。

### 2.2 我**没有**做的事（防"绿得可疑"）

- **没有**为了让树变绿而改任何判据、阈值或分类；**没有**把任何 `NOINFO` 当绿；
- `--selftest` 是**改后**跑的，且**同一趟**里 `AUTH-MISSING` 逐趟为 0（E/O/P 三处都断言了它）。

### 2.3 中间态（如实留档，别读成"一次就过"）

改后第一趟 **`SELFTEST_P=FAIL`**（rc=1/1/1/1/1/1，`MISSING=5`）。根因**不是**桥的锚判据，而是**两条 ITEMS 表读配置的基准路径不同**（§6.3），夹具修法 = P 沙箱自带配置声明（`:925`）。修完即 18/18。

### 2.4 ⚠️ 推翻"17 例本来全绿"这个前提（改前实测 4 例已红）

**改前件**（`/tmp/w52c-check-applocal-sync.sh.bak`，sha16 `a5102051114c80e1`）的 `--selftest` 第一趟实测：

```
$ bash /tmp/w52c-check-applocal-sync.sh.bak --selftest   # 注：放在自带 applocal-expect.py 的目录形态下跑
...
SELFTEST_D=FAIL（rc=1）
  计数：… UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] …   ← D 的沙箱副本落到 ⑥ ⇒ APPSYNC=MISMATCH ⇒ rc=1
$ echo $?   →   1        （FAIL 立即 exit 1 ⇒ E/F/G/H/I/J/K/L/L2/N/M/M2/O/P **全都没跑到**）
```

且**改前的 E/O 也是红的**（它们断言 `AUTH-MISSING=0`）。直接反极性实测（`/tmp/w52c-proofE.sh`，沙箱照改前夹具的摆法，权威一律摆 `bin` 下的 Debug 目录）：

| 跑哪个件 | 沙箱里的权威 | 实测 `AUTH-MISSING` | 实测 rc | E/O 的断言 `AUTH-MISSING=0` |
|---|---|---|---|---|
| 改前件（6 件 ITEMS） | Debug 布局（6 件俱全） | **4** | 1 | **不可能成立** |
| 改后件（8 件 ITEMS） | 同上 | **6** | 1 | 不可能成立（夹具不改的话） |

⇒ **`#39` 把权威配置切到 `Release` 之后，`--selftest` 的 D/E/O/P 四例当场变红，而没有任何报告登记过它**（`SelfBuiltConfig.props` mtime `2026-09-19 11:11:43` **晚于**该检查器最后一次改动 `11:03:51` 八分钟）。
**本车道把它修在夹具层面**（§1.2 ⑥⑦⑧⑨），并把这条**独立发现**单列在 §6.4 —— 它不是 `C1` 的产物，但 `C1` 要求"自检仍然全绿"，所以必须同趟收掉。

---

## §3 真实树 delta（改前／改后逐条）

### 3.1 命令与 rc

```bash
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh ; echo $?
# 改前：rc=1    改后：rc=1（**rc 不变**：改前那 1 条红是 PC 册表 B 的 `tools/GeometryOracle`）
$ python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py "$PWD" 2>/dev/null | grep -m1 '^#SUMMARY|'
# 改前：#SUMMARY|refdirs=14|expect=125|projects=86|unknown=1|unresolved_hintpath=34|invisible_copysites=66|invisible_write=7|invisible_read=59|invisible_capped=20|invisible_ext_write=5|invisible_ext_read=0|invisible_indirect_write=13
# 改后：#SUMMARY|refdirs=14|expect=190|projects=86|unknown=1|unresolved_hintpath=34|invisible_copysites=76|invisible_write=11|invisible_read=65|invisible_capped=26|invisible_ext_write=5|invisible_ext_read=0|invisible_indirect_write=13
```

⚠️ 枚举器的**拷贝点清单**也随件名变化（`invisible_copy_sites*()` 的 `names` 就是 `ITEMS` 的 basename）：
`invisible_write 7→11`、`invisible_read 59→65`、`invisible_capped 20→26`（`resolved` 字段 `unresolved_hintpath=34` **不变**）。
⇒ 这不是判据改动，是"**清单里多了两个件名**"的必然结果；`SELFTEST_M2` 的"自报数 == 输出里印的数"断言本趟仍 `PASS`（`:2.1`）。

### 3.2 计数行（原文照录，两趟同一形态命令）

```
改前  计数：OK=116  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=12[DECL-GAP-EQ=12 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=0  LIB-COPY=21  SKIP(obj)=10  SKIP(stub)=12  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
改后  计数：OK=135  MISMATCH=35（STALE=35  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4]  DIVERGENT=5  NO-AUTHORITY=0  LIB-COPY=33  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
```

| 计数器 | 改前 | 改后 | Δ | 增量全部来自 |
|---|---|---|---|---|
| `OK` | 116 | 135 | **+19** | 逐条分类实测（PF+WB 两段合计）：`OK 19`／`STALE 34`／`LIB-COPY 12`／`SKIP(obj) 4`／`SKIP(stub) 8`／`UNEXPECTED-DIFF 4` ⇒ **`+19` 全是 PF/WB 中与权威同 sha 的副本**；`+4 SKIP(obj)`、`+8 SKIP(stub)` 同理 |
| `MISMATCH`（`STALE`） | 1 | 35 | **+34** | **全部**是 PF（7）/WB（27）的陈旧副本；**没有一条**是旧有的（改前那 1 条 = `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`，PC 册表 B，**与本任务无关**） |
| `UNEXPECTED` | 12[EQ=12 DIFF=0] | 16[EQ=12 DIFF=4] | **+4 DIFF** | `samples/ThirdPartyMini` × {PF,WB} × {Debug,Release}：**内容 ≠ 权威**的未声明副本 ⇒ `DECL-GAP-DIFF` 硬红 |
| `DIVERGENT` | 1 | 5 | **+4 组** | `PresentationFramework.dll [Release]／[Debug]`、`WindowsBase.dll [Release]／[Debug]` |
| `MISSING` | 0 | 0 | 0 | 完好树上无缺件；**缺件判据另有反极性读数（§4）** |
| `NO-AUTHORITY` | 0 | 0 | 0 | 见 §6.2（这一类在现场配置下**结构性不可达**） |
| `LIB-COPY` / `SKIP(obj)` / `SKIP(stub)` | 21/10/12 | 33/14/20 | +12/+4/+8 | 非判定类的分类增量（库输出目录 / 中间件 / 循环桩），**不是红** |
| `AUTH-MISSING` / `BRIDGE-*` / `RETIRED` | 0 | 0 | 0 | — |

**期望集合**：`expect 125 → 190`（**+65** 条 = 各工程对 PF/WB 的 `<Reference>` 闭包）。旧枚举器（`219516c6cf3bf376`）对 PF/WB 的 `#EXPECT` 条目数 = **0**（实测 `grep -c`）⇒ **改前删一份 PF 副本，期望模型里根本没有它**。

### 3.3 逐条点名（完整 38 条见 `known-red-PFWB-copies.md` 表 A/B/C；此处只点任务书指定的两条）

| 任务书指定的现场 | 实测（2026-09-20 10:15，`Release` 权威） | 结论 |
|---|---|---|
| `build/PresentationFramework.Linux/bin/$cfg/WindowsBase.dll` **与** `build/WindowsBase.Linux/bin/$cfg/WindowsBase.dll` **sha 不同** | `$cfg=Release`：**两处相同**（都 `79740e9ba7fbf9ca`，== 权威 ⇒ 均 `OK`）；`$cfg=Debug`：**两处不同**（`b39730566b1b480f` vs `19de048ecb968daa`） | **预登记的措辞要更正**（§6.1）：该现象**只在 Debug 口径成立**；`Release` 口径下 WB 组的 DIVERGENT 是由 `samples/ThirdPartyMini/bin/Release/net10.0/WindowsBase.dll 19de048ecb968daa` 造成的 |
| 该条必须**具名报出** | ✅ `WindowsBase.dll [Debug]` 组（10 种 sha、24 名成员）里**两处都在成员清单里**（逐字可核；见登记册表 D） | **成立** |

---

## §4 两极化读数（①删 ⇒ 具名 `MISSING` + `rc≠0`；②`cp -p` 整份还原 ⇒ 回绿）

脚本 `/tmp/w52c-polarity2.sh`（可复算）。被测副本两份（**都在启动宿主目录里**、都在期望集合里）：

| 步骤 | 动作 | 改前件（`a5102051114c80e1`） | 改后件（`d82e920b49bb0f0f`） |
|---|---|---|---|
| A | 完好树上跑 | `OK=116 MISMATCH=1 MISSING=0 UNEXPECTED=12 DIVERGENT=1 LIB-COPY=21 …` rc=1；输出里 PF/WB 字样命中 **0** | `OK=135 MISMATCH=35 MISSING=0 UNEXPECTED=16 DIVERGENT=5 LIB-COPY=33 …` rc=1 |
| B | `cp -p` 备份后**移走** `samples/HelloWpf/bin/Debug/net10.0/{PresentationFramework.dll,WindowsBase.dll}` | 备份 sha16：`68d31452be50a89c` / `1b4ef36832ddca03` | 同 |
| C | 缺件树上跑 | **`OK=116 MISMATCH=1 MISSING=0 UNEXPECTED=12 DIVERGENT=1 LIB-COPY=21 …`（与 A **逐字相同**）** ⇒ **静默**；PF/WB 字样命中 **0** | — |
| D | 缺件树上跑（后件） | — | `MISSING=2` + `rc=1`，**两条都具名**（原文）：<br>`MISSING  samples/HelloWpf/bin/Debug/net10.0/WindowsBase.dll  ← 期望来源：samples/HelloWpf/HelloWpf.csproj 的 <Reference Include="WindowsBase">`<br>`MISSING  samples/HelloWpf/bin/Debug/net10.0/PresentationFramework.dll  ← 期望来源：samples/HelloWpf/HelloWpf.csproj 的 <Reference Include="PresentationFramework">` |
| E | `cp -p` **整份还原** + 双证 | — | `PF 68d31452be50a89c`／`WB 1b4ef36832ddca03`（**== 删前**）；`cmp`/`diff -q` 两份都 `OK` |
| F | 还原后复跑 | — | `OK=135 MISMATCH=35 MISSING=0 …` ⇒ **回到 A 的读数，计数行与改后基线逐字相同**（脚本自印 `SAME`） |

- 「改前静默」是**同一趟里做出来的 A/B**（同脚本、同沙箱、同命令形态），不是我的回忆；
- 移走用的是 `mv`（不是 `rm`），窗口 = 步骤 C+D 两次跑（≈90 s），全程**同一趟 bash 调用内闭合**，还原后又 `sha256sum` + `diff -q` 双证；
- 另一条口径读数：删这两份**不影响**任何其它计数器（`MISMATCH` 由 35→33 也只是因为这两份从 `STALE` 变成"不存在"）。

---

## §5 收敛结果与登记

### 5.1 刷新器**干跑**（一个字节都没写）

```bash
$ bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh          # 默认 = 干跑
...  REFRESH  ×34（逐份 STALE） + REFRESH(group) ×4（DIVERGENT 落单）
    APPSYNC-REFRESH=refreshed=38 newer=0 applied=0
    校验器：刷新前 exit=1 / 刷新后 exit=1        # 干跑 ⇒ 前后同
$ echo $? → 0
```

- 38 份 = 34 `STALE` + 4 `DIVERGENT` 落单者（`newer=0` ⇒ **没有"不早于权威、需人判"的条目**）；
- 落点分布（现场算）：`…/Debug/…` **31 份** / `…/Release/…` **7 份**；
- 按件：`PresentationFramework.dll` 9 份、`WindowsBase.dll` 29 份（含 group）。

### 5.2 本车道**故意没有** `--apply`（三条理由，**可反驳**）

1. **写域**：本车道写域只有 4 个文件；`--apply` 会写 **31 份别的车道的 `…/bin/Debug/…` 副本** ⇒ 超出授权形状。
2. **它是跨配置改写**：31/38 落在 **Debug** 目录，而权威是 **Release** 件 ⇒ 等于把 Release 框架件塞进 Debug 应用目录。
   刷新器**自己**把这一类叫"**放错配置**"（`sync-applocal-authority.sh:18-20`：`路 2` 有护栏，`路 1`（`STALE`）**没有**）⇒ 一次 `--apply` 会**静默跨配置**。
3. **"该不该红"本身待裁定**：`NO-AUTHORITY` 在现场配置下**结构性不可达**（§6.2）⇒ "Debug 副本 vs Release 权威"这一整类**没有任何豁免口径**。改口径不是 `C1` 的授权（纪律 1）。

⇒ 本车道**登记 + 上交裁定**；`--apply` 的决定权与后果说明见 §6.2。**这也是唯一一件"任务书步骤 6（可选）未执行"的动作，理由逐条如上。**

### 5.3 登记结果

新建 `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md`（`7b113a11934c54c4`，19,658 B，141 行）：

| 表 | 内容 | 条数 |
|---|---|---|
| 表 A | PF 副本 `STALE` | **7** |
| 表 B | WB 副本 `STALE` | **27** |
| 表 C | `UNEXPECTED-DIFF`（`samples/ThirdPartyMini` × {PF,WB} × {Debug,Release}） | **4** |
| 表 D | `DIVERGENT` 组（信息性；第 2 列**不是** sha ⇒ **不被** `show_registry()` 当登记条目解析，避免"组"被读成"份"） | **4 组** |
| 合计被解析的登记行 | 表 A+B+C | **38** |

检查器现场回读（接线生效的机器证）：`在册 38 条：**仍红 38** ｜ 已转绿 0 ｜ 缺件 0`（另印 PC 册 `在册 13 条：仍红 1 ｜ 已转绿 12`，**一字未动**）。
**登记 ≠ 已容忍**：`APPSYNC` 仍是 `MISMATCH`、`rc` 仍是 1（登记段不参与判定）。

---

## §6 边界、未做、与被推翻的前提

### 6.1 ⚠️ 推翻预登记 §3 `C1` 的一处措辞（附带判据）

预登记 `:128` 写"`build/PresentationFramework.Linux/bin/$cfg/WindowsBase.dll` 与 `build/WindowsBase.Linux/bin/$cfg/WindowsBase.dll` **今天 sha 不同**"。
**现场实测**：`Release`（= 现配置）**两处相同**（`79740e9ba7fbf9ca`）；`Debug` 两处不同（`b39730566b1b480f` vs `19de048ecb968daa`）。
⇒ 该句**只在 Debug 口径成立**；预登记 `:55-60` 的"与 **Debug 权威**不同的宿主副本 5/19 份、Release 口径 12 份按 `NO-AUTHORITY` 只提示"同样**是按旧配置写的**（现现场见 §3.2）。**不给预测打补丁**：以现场为准，且该条要照样**具名报出**（§3.3 已成立）。

### 6.2 ⚠️ `NO-AUTHORITY` 在现场配置下**结构性不可达**（新发现，需主控裁定）

- 判据原文（`:369`）：`if is_release_path "$f" && is_debug_auth "$exp"`；`is_debug_auth`（`:199`）= `*/bin/debug/*` 匹配**权威路径**。
- 现场 `SELFBUILT_CONFIG=Release` ⇒ **所有** `ITEMS` 权威都在 `bin/Release` ⇒ **恒 false** ⇒ `NO-AUTHORITY=0`（实测）。
- **后果**：Debug 布局的副本被拿 Release 权威判红（本趟 +34 条里 **31 条**是这样来的）。
  ⇒ "Release 口径副本按 `NO-AUTHORITY` 只提示"这句旧口径，在**切配置之后方向反了**。
- **我不改它**（改分类规则 = 改判据，纪律 1）。**要反驳本趟的登记只需两件事之一**：
  ① 证明"把 38 份 `cp -f` 成 Release 权威"是**要**的行为（那登记册表 A/B/D 应整体改判为"已收敛"并删除）；
  ② 证明 `NO-AUTHORITY` 的**方向性**（只认 Debug 权威）是 bug（那该修判据，本册随整体重算）。

### 6.3 ⚠️ 两张 ITEMS 表**读配置的基准不同**（新发现，本趟只修夹具）

| 侧 | 读哪份声明 | 读不到时 |
|---|---|---|
| `check-applocal-sync.sh:150` | `$(dirname "$0")/../../../build/SelfBuiltConfig.props`（**脚本相对**） | `selfbuilt-config.sh` 报错退出（`return 2`） |
| `applocal-expect.py:48` | `<argv[1]>/build/SelfBuiltConfig.props`（**AUTH_ROOT 相对**） | **静默回退 `Debug`**（`:52-54`） |

真仓里两者同源 ⇒ 没问题；**合成权威根**（自检沙箱、或任何人用 `AUTH_ROOT=` 指向别处）里就会**一侧 Release、一侧 Debug** ⇒ `MISSING=5` 假红（本趟实测，§2.3）。
本趟处理：**只修夹具**（P 沙箱自带声明，`:925`）。**没改工具语义**（改 `argv` 语义会动 `--list-items` 之外的调用面）。⇒ 若主控认为该回退默认值应当消失，那是**另一个**独立改动。

### 6.4 ⚠️ 独立发现：`#39` 切配置后 `--selftest` **早已 4 例全红**且无登记

现象/证据/修法见 §2.4（`D/E/O/P`，改前件实测 `SELFTEST_D=FAIL` rc=1，D 之后的 14 例**根本没跑到**）。
本趟**修在夹具层面**（§1.2），**判据一字未改**；但这说明 `#39` 阶段 2/3 的"切配置"动作**漏了一条收尾**：切权威配置必须同趟重跑 `--selftest`（本文件 `:144-145` 自己要求"必须在静树上跑"）。建议主控把它接进波流程。

### 6.5 本趟**没能测**的（如实列，不许读成"绿"）

1. **`--apply` 之后树长什么样**：本车道没跑 ⇒ 那 38 份的"刷完是否真的收敛、是否引发跨配置运行期问题"**本趟不可测**。
2. **`UNEXPECTED-DIFF` 那 4 条谁对**：`samples/ThirdPartyMini` 到底**该不该**随包带 PF/WB，取决于该样例的部署意图（`run-thirdparty-mini.sh` 的需要）——**未查**，因此登记册只写"补声明图 **或** 刷新"两条可能处置。
3. **`NEWER-DIFF` 分支**：本趟 0 条 ⇒ "副本不早于权威"这条分支**没有被本任务触发**（判据本身由既有自检 A/E 覆盖）。
4. **PF/WB 的"**最小**权威集合"**：`build/PresentationFramework.Classic.Linux`（另一份 PF 构建，`68d31452be50a89c`）与 `build/ReachFramework.Linux/bin/Debug/PresentationFramework.dll` 这类"**另一个构建/另一个配置的产物**"是否该有独立口径 —— 本趟按现行规则一律判红/登记，**未做裁定**。
5. **`Release` 口径下 `NO-AUTHORITY` 的死活**：见 §6.2（需要主控裁定，不是我能单方面定的）。

### 6.6 并发披露

本趟全程另有车道在写盘（本趟观测到 `loadavg` 0.5→1.13、`MemAvailable` 2.9 GB 上下）。所有"逐字相同/逐字不变"的断言都取自**单趟内**的成对读数（§4）；`SELFTEST_M2` 的"同一棵树"夹逼（`snapPre==snapPost==expM2`）本趟**三趟都成立**（若树在动它会报 `NOINFO`＋rc=3，本趟没出现）。

---

## §7 复算命令（逐条，可粘贴）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"

# ① 现配置（权威件的配置来源）
bash build/selfbuilt-config.sh                      # → Release

# ② 两张权威表必须一致（本趟改了**两处**）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --list-items | tail -1     # → ITEMS_SYNC=YES

# ③ 自检（本趟 18/18 全 PASS；退出码 0）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest; echo "rc=$?"
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest | grep -cE '^SELFTEST_[A-Z0-9]+=PASS'   # → 18

# ④ 真实树读数（rc=1 是**预期**：登记在册的红照样计）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^计数：|^APPSYNC='
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py "$PWD" 2>/dev/null | grep -m1 '^#SUMMARY|'

# ⑤ 只取本任务新增的红
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^    STALE' | grep -E 'PresentationFramework\.dll|WindowsBase\.dll' | wc -l          # → 34
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^    UNEXPECTED-DIFF' | grep -E 'PresentationFramework\.dll|WindowsBase\.dll' | wc -l  # → 4
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -cE 'DIVERGENT +(PresentationFramework|WindowsBase)\.dll'                                # → 4

# ⑥ 登记段（接线是否生效）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^--- 在册红|^    在册 [0-9]+ 条'
#   → 两段：PC 册「在册 13 条：仍红 1 ｜ 已转绿 12」＋ PFWB 册「在册 38 条：仍红 38 ｜ 已转绿 0」
#   显式指定只读一本（向后兼容）：REGISTRY_FILE=$PWD/build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md bash … | grep -cE '^--- 在册红'   # → 1

# ⑦ 收敛（本车道只跑了**干跑**，不写盘）
bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh | grep -E '^    APPSYNC-REFRESH'   # → refreshed=38 newer=0 applied=0
#   真要收敛（**主控裁定后**）：bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply

# ⑧ 两极化（自造，约 4 分钟；脚本正文见本报告 §4）
bash /tmp/w52c-polarity2.sh

# ⑨ 夹具反极性取证（证明改前 D/E/O/P 已红）
bash /tmp/w52c-proofE.sh          # → 改前件 AUTH-MISSING=4 / 改后件 =6（均 rc≠0）

# ⑩ 牙与棘轮
bash build/MilBridge/tools/shell-quote-trap-check.sh | grep '^SHELL_QUOTE_TRAP'   # → PASS traps=0
bash build/MilBridge/tools/pipefail-sigpipe-check.sh | grep '^PIPEFAIL_SIGPIPE'   # → PASS
bash build/selfbuilt-config.sh --debt-check                                       # → PASS live=141 max=167（改前 163）

# ⑪ 回退（全份还原改前件；判据件与夹具一并回退）
cp -p /tmp/w52c-check-applocal-sync.sh.bak build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh
cp -p /tmp/w52c-applocal-expect.py.bak     build/DirectWrite.Linux/wic-shim/applocal-expect.py
sha256sum build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | cut -c1-16   # → a5102051114c80e1
sha256sum build/DirectWrite.Linux/wic-shim/applocal-expect.py     | cut -c1-16   # → 219516c6cf3bf376
```

### 本报告自身

- 路径：`build/MilBridge/W52C-report.md`
- `head -n -1 build/MilBridge/W52C-report.md | sha256sum | cut -c1-16` = **`2d13cae7b56242d1`**（口径：**去掉本行之后的正文**整份 sha256 前 16 位；正文 356 行，本行不计入 ⇒ 本值可现场复算相等）
