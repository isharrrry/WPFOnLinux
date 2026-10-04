# W52C2 报告 —— `#49` §10 裁定落地：`CROSS-CONFIG`（`D-G62`）＋ `C1b`（声明件不许静默回退）

> **一句话**：裁定 ② 与 ③ 都已落地；**改格前后真实树的 `APPSYNC=` 行逐字相同、计数行只多一格**（⇒ 新格**只增加可见性**：没新增红、也没压掉任何红），
> `--selftest` **18/18 PASS、rc=0**，两极化成对读数齐（§3／§4）。另**自查自伤一处**（我写坏了一个 ITEMS 注记，被本仓两颗牙当场抓住，见 §6.1），
> 并**量化上交**一个新发现（`applocal-expect.py:88` 的硬编码 `Debug` 只影响 34 条红里的 **2 条**，见 §6.3）。

---

## §0 环境与件 sha16

| 量 | 值 |
|---|---|
| 车道 | `W52C2`（`#49` §10 裁定 ②③ 落地；承接 `W52C`，报告 `2d13cae7b56242d1`） |
| 时间窗 | 2026-09-20 10:23 → 10:36（+0800） |
| 内核 / `nproc` | `6.8.0-138-generic` ／ 3 |
| `loadavg` | 收工实测 `0.69 0.99 0.96` |
| `MemAvailable` | 收工实测 **2,552 MB**（> 1,200 MB，无等待） |
| `SELFBUILT_CONFIG` | **`Release`**（`build/SelfBuiltConfig.props:28`；`bash build/selfbuilt-config.sh` 现场读回） |
| 纪律 | 零 `dotnet`、零构建、零 `pkill -f`；未跑 `verify-all.sh` / `close-wave.sh` / `integration-wave.sh`；**未跑 `sync-applocal-authority.sh --apply`**（裁定 ①：仍不手工 apply） |

### 件 sha16（本趟改前 → 改后）

| 件 | 改前 sha16（= `W52C` 末态） | 改后 sha16 | 改后字节 | 改后 mtime |
|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `d82e920b49bb0f0f` | **`40c3b35cf4ec7fc1`** | 108,983 | 2026-09-20 10:33:20 |
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | `a7e05921b77524c2` | **`dff2d29c800e4ba4`** | 32,101 | 2026-09-20 10:30:29 |
| `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | `7b113a11934c54c4` | **`2a584c547247c3fc`** | 21,401 | 2026-09-20 10:35:49 |
| `build/MilBridge/W52C2-report.md`（本报告） | —（新建） | 见 §7 末行（**正文定稿后回填**） | — | — |

`cp -p` 全份备份（回退证用，逐字节）：`/tmp/w52c2-check.bak` = `d82e920b49bb0f0f`、`/tmp/w52c2-expect.bak` = `a7e05921b77524c2`、`/tmp/w52c2-registry.bak` = `7b113a11934c54c4`。

---

## §1 逐处改动（`文件:行` + 为什么）

### 1.1 裁定 ② —— `NO-AUTHORITY`（死格）⇒ `CROSS-CONFIG=<n>`（具名诊断格）

| # | 位置 | 改动 | 为什么 |
|---|---|---|---|
| ① | `check-applocal-sync.sh:19-31`（文件头口径表） | `NO-AUTHORITY` 一行**整段替换**为 `CROSS-CONFIG` 一行：定义（**副本所在路径的配置 ≠ 声明配置**）、两条硬约束（**不判红**／**不给任何副本免红**）、来历（旧格是死格 + 旧行为是 `continue` 豁免 ⇒ 新格是**加严**）、**射程**（`obj`/`stub` 不进本格；RID `release_*` 归 Release；认不出配置的路径不进本格） | 裁定 ② 明文要求"同趟把散文/口径句改成与现场一致（摘要格与散文句必须逐字对账）" |
| ② | `:37`（文件头总判定句） | `仅 NO-AUTHORITY / LIB-COPY / SKIP(*) > 0 ⇒ PASS` → `仅 CROSS-CONFIG / LIB-COPY / SKIP(*) > 0 ⇒ PASS` | 同上：判定式里的**名字**必须与摘要格一致 |
| ③ | `:100-102`（文件头自检例表 D） | 旧 D（"无权威 ⇒ 计 `NO-AUTHORITY` 且 exit=0"）→ 新 D（"跨配置副本必须**具名可见、且照样判红**"，含 (a)/(b) 两条） | 自检例是**判据的镜像**，判据改了它必须同趟改（否则它是**假绿**） |
| ④ | `:176`（Provider 的 ITEMS 注记） | 删掉两条过期文案（"权威只按 Debug"、"Release 副本见 `NO-AUTHORITY`"），改写为指向现行 `CROSS-CONFIG` 口径 | 旧注记**引用的是已删的死格** ⇒ 留着就是"文档说豁免、代码在判红" |
| ⑤ | `:185-187` | 计数器 `CNT_NOAUTH` **删除**，新增 `CNT_CROSSCFG=0` | 死格不留计数器（留一个恒 0 的格子本身会误导） |
| ⑥ | `:203-209`（判定口径注释） | 第 2 条重写：`CROSS-CONFIG` **只提示、且不豁免任何副本**（并写明为什么两个方向都错：混为一谈 ⇒ 狼来了；豁免 ⇒ 切一次配置全仓判据集体失效） | 同上 |
| ⑦ | `:211-216` | **删除** `is_debug_auth()`（死格专用；`grep -c` 现场复核 = 0 处引用），**新增** `path_cfg()` 与 `is_cross_config()` | ⚠️ 关键设计：`path_cfg()` 的 Release 那一臂**复用 `is_release_path()`**（`:214`），**不写第二个正则** —— 跨副本分组与本格用**同一把尺子**（本仓最恨"同一语义两处实现"） |
| ⑧ | `:402-412`（`scan()` 的分支 ④） | 旧分支（`is_release_path "$f" && is_debug_auth "$exp"` ⇒ 计数 + `continue`）→ 新分支（`is_cross_config "$f"` ⇒ 计数 + 打印，**不 `continue`**） | **这就是裁定 ② 的全部实质**：旧格 `continue` = **豁免**；新格落到 ⑤/⑥ ⇒ 跨配置副本**照样**拿 `LIB-COPY`/`OK`/`STALE`/`NEWER-DIFF`/`UNEXPECTED-*` |
| ⑨ | `:1038-1039`（摘要行） | `NO-AUTHORITY=$CNT_NOAUTH` → `CROSS-CONFIG=$CNT_CROSSCFG`（并加一行括号说明：不判红／不免红／旧格已删） | 摘要格与散文句**逐字对账** |
| ⑩ | `:1104-1105`（`APPSYNC=PASS` 附提示支路） | `CNT_NOAUTH` → `CNT_CROSSCFG`，且文案改成"跨配置副本**只提示、且不放行** —— 它们该红的仍在 MISMATCH/UNEXPECTED 里" | 同上；**判定式一行未动**（`CROSS-CONFIG` **没有**进 `rc` 条件） |
| ⑪ | `:626-663`（自检 D **整体重写**） | 改为**同一沙箱内的成对两极化**：`prov`（权威副本）+ `AppS`/`AppX`（各用 `HintPath + Private=true` 把 prov 产物**声明**进自己输出目录）⇒ (a) 在**另一个配置**目录里放陈旧副本；(b) 同一份挪进**声明配置**目录 | 旧 D 测的是死格（"判不了 ⇒ exit 0"）。新 D 测裁定 ② 的两条判据**逐字对应**：`CROSS-CONFIG=1` **且仍 `STALE`**／`CROSS-CONFIG=0` **仍 `STALE`** |

⚠️ **行为差的唯一一处**（必须写清）：旧格对跨配置副本是 **`continue`（不看内容）**；新格**看内容并按同代判据判**。
⇒ 方向是 **加严**（可能出现"以前静默、现在报红"的条目），**不可能**出现"以前红、现在绿"（因为新格不产生任何豁免）。

### 1.2 裁定 ③ —— `applocal-expect.py` 不许静默回退 `Debug`

| # | 位置 | 改动 | 为什么 |
|---|---|---|---|
| ⑫ | `applocal-expect.py:40-56` | 新增 `_decl_candidates()`：候选**按顺序**①`<argv[1]>/build/SelfBuiltConfig.props` ②**脚本相对** `<本文件>/../../../build/SelfBuiltConfig.props`（与 `check-applocal-sync.sh:150` **同一处**）；`_selfbuilt_config()` 改成**遍历候选**、只接受 `Debug`/`Release`，**读不到 ⇒ `None`**（删掉两处 `return "Debug"`） | 裁定 ③ 正文：**不许有默认值** |
| ⑬ | `applocal-expect.py:58-68` | 模块级：`CFG is None` ⇒ 印 `#NOINFO\|config-decl\|…`（stdout）+ 一行说明（stderr）+ **`sys.exit(2)`** | "`NOINFO` 不许当绿"：非 0 退出 ⇒ 调用方 `check-applocal-sync.sh` 的 `EXPECT_OK≠1` ⇒ `APPSYNC=NOINFO` + **`exit 3`**（§4 实测） |
| ⑭ | `applocal-expect.py:31`（`--list-items` 兼容面） | 未改脚本；但 ⑬ 的 `sys.exit(2)` 会让"第二张表读不出来"时 `ITEMS_SYNC=NOINFO`（**不是** `YES`） | 该模式早已把"读不出来"定义为 `NOINFO`（`check-applocal-sync.sh:528`），此处**行为一致**，无需改 |

**没有做的**：`PROPS` 里那处硬编码（`:88`，`"WpfLinuxSelfBuiltConfiguration": "Debug"`）**没动** —— 它不在裁定 ③ 的改法里，且它影响 `REFDIR` 判据面（会改变真实树读数）。影响已**量化上交**：§6.3。

---

## §2 `--selftest` 汇总

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest ; echo $?   →  0
SELFTEST_A=PASS（两类错件都被报红，exit=1）
SELFTEST_B=PASS（exit=0，全绿：.so + .dll + 产出目录那份，且都有声明式来源）
SELFTEST_C=PASS（旧 provider dll 被跨副本判定抓出）
SELFTEST_D=PASS（(a) 跨配置目录（Debug）里的陈旧副本 ⇒ CROSS-CONFIG=1 **且仍 STALE**、exit=1；(b) 同一份挪进声明配置（Release）目录 ⇒ CROSS-CONFIG=0 **仍 STALE**、exit=1 ⇒ 跨配置不放行）
SELFTEST_E=PASS（… 沙箱八件权威俱全，目录随 SELFBUILT_CONFIG=Release）
SELFTEST_F=PASS ／ SELFTEST_G=PASS ／ SELFTEST_H=PASS ／ SELFTEST_I=PASS ／ SELFTEST_J=PASS
SELFTEST_K=PASS（期望基数 删前=10 / 删后=10 **不变**；删⇒MISSING 红 exit=1；整份还原⇒绿 exit=0）
SELFTEST_L=PASS ／ SELFTEST_L2=PASS ／ SELFTEST_N=PASS ／ SELFTEST_M=PASS
SELFTEST_M2=PASS（同一棵树（snapPre==snapPost==expM2）：invisible_capped=26 ⇒ 截断自称**且数字相符**；invisible_ext_write=5 ⇒ 补扫自称且逐条印）
SELFTEST_O=PASS（权威俱全 exit=0 绿；移走一份权威 exit=1 红[AUTH-MISSING=1]；cp -p 还原 exit=0 绿；…）
SELFTEST_P=PASS（锚一致 exit=0 绿｜两份一起换旧 exit=1 红[BRIDGE-ANCHOR=2]｜只还原一份 exit=1 红[=1]｜整份还原 exit=0 绿｜记录删锚行 exit=1 红[BRIDGE-NOINFO=1]；…）
SELFTEST=PASS
```

- **`PASS` 例数 = 18**（`grep -cE '^SELFTEST_[A-Z0-9]+=PASS'` 现场算）；**`rc=0`** ⇒ 没有 `NOINFO` 混进"绿"（`rc=3` 才是 `NOINFO`）。
- **P 段照旧全绿**（裁定 ③ 的判据 (c) 逐字满足）：它靠的是候选**路径①** —— 沙箱 `$PREPO` 自带 `build/SelfBuiltConfig.props`（`W52C` 就在那里补的）。
- 其余 17 例的**判据一字未改**；唯一被重写的是 D（判据本体的镜像，见 §1.1 ⑪）。

---

## §3 裁定 ② 的两极化读数（**原文计数行**）

### 3.1 沙箱成对（可复算：`bash /tmp/w52c2-Dpair.sh`；现场 `SELFBUILT_CONFIG=Release`、`OTHER_CFG=Debug`）

**(a) 跨配置目录（`AppX/bin/Debug`）里放一份 sha≠权威 的副本**：

```
rc=1
计数：OK=1  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=0[DECL-GAP-EQ=0 DECL-GAP-DIFF=0]  DIVERGENT=0  CROSS-CONFIG=1  LIB-COPY=0  SKIP(obj)=0  SKIP(stub)=0  SKIP(ref)=0  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
APPSYNC=MISMATCH（MISMATCH=1[STALE=1 NEWER-DIFF=0] … —— 见上；本脚本**不改写任何目录**）
    CROSS-CONFIG  AppX/bin/Debug/DirectWrite.Linux.Provider.dll   ACTUAL cdf9acfd3b6e065f（副本配置=Debug ≠ 声明配置=Release ⇒ **只增加可见性**：本份照样走下面的判据，`STALE`/`NEWER-DIFF` 一条都不会因此豁免）
    STALE         AppX/bin/Debug/DirectWrite.Linux.Provider.dll   EXPECT 1f9511a7ef395bfe  ACTUAL cdf9acfd3b6e065f（副本早 211979649 秒 ⇒ 必须刷新）
```

⇒ **同一个路径同时出现 `CROSS-CONFIG` 与 `STALE`** —— 这就是裁定 ② 要求的"`CROSS-CONFIG≥1` **且**该份仍在 `MISMATCH/STALE`"。

**(b) 同一份挪进声明配置目录（`AppS/bin/Release`）**：

```
rc=1
计数：OK=1  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=0[DECL-GAP-EQ=0 DECL-GAP-DIFF=0]  DIVERGENT=1  CROSS-CONFIG=0  LIB-COPY=0  SKIP(obj)=0  SKIP(stub)=0  SKIP(ref)=0  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
    STALE         AppS/bin/Release/DirectWrite.Linux.Provider.dll EXPECT 1f9511a7ef395bfe  ACTUAL cdf9acfd3b6e065f（副本早 211979649 秒 ⇒ 必须刷新）
```

⇒ `CROSS-CONFIG=0`、**仍 `STALE`**（判红与"跨不跨配置"**无关** ⇒ 跨配置**不是**免红券）。
（该趟 `DIVERGENT=1` 是沙箱副作用：同组里同时存在 prov 的权威副本与 AppS 的陈旧副本 ⇒ 两种 sha；与本判据无关。）

### 3.2 真实树上的同一条（**不是只有沙箱成立**）

```
全树 CROSS-CONFIG 明细行 = 101（按件：Provider 25、WindowsBase 25、PresentationCore 21、WpfGfx.Linux 10、
                              PresentationFramework 9、ReachFramework 9、libwpfwic 1、libwpfwin32 1）
全树 STALE = 35；其中 PF/WB = 34
  PF/WB STALE 里**同时**带 CROSS-CONFIG 行的 = 29（⇒ 跨配置而**照样判红**）
  PF/WB STALE 里不带 CROSS-CONFIG 行的 = 5（全是 `…/bin/Release/…`，同配置陈旧 ⇒ `STALE` 照判）：
      build/MilBridge/tests/CompositeFontProbe/bin/Release/WindowsBase.dll
      build/MilBridge/tests/MinMaxProbe/bin/Release/WindowsBase.dll
      build/MilBridge/tests/StrictTierProbe/bin/Release/WindowsBase.dll
      build/MilBridge/tests/T2eLineHeight/bin/Release/WindowsBase.dll
      build/MilBridge/tests/TabGapProbe/bin/Release/WindowsBase.dll
  STALE 中非 PF/WB 的 1 条 = tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll（PC 册表 B，早已在册）
```

### 3.3 "只增加可见性"的机器证（**改格前后的差分**）

```
$ diff <(旧件 grep '^APPSYNC=') <(新件 grep '^APPSYNC=')        →  APPSYNC 行逐字相同 ✅
$ diff <(旧件 计数行 | 剔掉 NO-AUTHORITY=*) <(新件 计数行 | 剔掉 CROSS-CONFIG=*)  →  逐字相同 ✅
```

⇒ 新格**没有**新增红、**没有**压掉任何红、**没有**改动 `rc`（`rc` 仍是 1，来自那 35 条 `STALE` + 16 条 `UNEXPECTED` + 5 组 `DIVERGENT`）。

---

## §4 裁定 ③ 的两极化读数

脚本 `/tmp/w52c2-c1b.sh`（可复算）。布局：`$S1` = scratch 根里的**新件**（该根**没有**声明件）；`$S0` = 同形布局里的**改前件**；`$AR` = `argv[1]`（**也没有**声明件）⇒ **两条候选都不存在**。

| 步骤 | 动作 | 改前件（`a7e05921b77524c2`） | 新件（`dff2d29c800e4ba4`） |
|---|---|---|---|
| **(a)** | `python3 <件> $AR`（两条候选都缺） | **`rc=0`（静默）**，`#SUMMARY\|…expect=8…` 正常印出，且 `#EXPECT` 里出现 **`…/bin/Debug/…`**：<br>`#EXPECT\|/tmp/w52c2-argroot/src/WpfGfx.Linux/bin/Debug/net10.0\|WpfGfx.Linux.dll\|权威件本身的目录`<br>⇒ **无声地把权威路径按 Debug 拼了出来**（而声明配置是 Release） | **`rc=2`**；stdout：`#NOINFO\|config-decl\|<两条候选路径>\|读不到配置声明 ⇒ 不猜默认值（改前静默回退 Debug）`；stderr 同一句；**`#EXPECT` 条数 = 0**（⇒ 没有"猜出来的权威路径"） |
| **(b)** | 把声明件放回**路径①**（`$AR/build/SelfBuiltConfig.props`）⇒ `python3 $S1 $AR` | — | **`rc=0`**；路径按**声明值**拼出：`/bin/Release/` 命中 1、`/bin/Debug/` 命中 **0** |
| **(b′)** | 只靠**路径②**（`argv[1]` 无声明、脚本在完好 checkout 里）：`python3 <真仓件> $AR` | — | **`rc=0`**；`#EXPECT\|/tmp/w52c2-argroot/build/DirectWrite.Linux/Provider/bin/**Release**\|…`（⇒ 兜住了"沙箱自己没声明、但工具在完好 checkout 里"这一形态） |
| **(c)** | P 段沙箱夹具 | — | **`SELFTEST_P=PASS`**（它自带声明件 ⇒ 走路径①；见 §2 的 18/18） |
| **(d)** | 真仓正常跑：`python3 <真仓件> $REPO` | — | `rc=0`，`#SUMMARY\|refdirs=14\|expect=190\|projects=86\|unknown=1\|unresolved_hintpath=34\|…`（与改前**逐字相同**） |

### 4.1 调用方的后果：`NOINFO` ⇒ **非 0**、且**不许当绿**（实测）

`check-applocal-sync.sh` 的 `EXPECT_OK` 只在"枚举器命令成功"时为 1 ⇒ **任何**工具级 `NOINFO` 都落到
`APPSYNC=NOINFO` + `exit 3`。现场实测（把工具**临时移走**≈40 s，随即 `cp -p` 还原并双证）：

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh ; echo $?      →   3
    ⚠️ 期望集合**算不出来**（applocal-expect.py 不可用）：本趟只查了现存副本 ⇒ **不等于通过**
APPSYNC=NOINFO（期望集合算不出来 ⇒ **不等于通过**；见上EXPECT=UNKNOWN清单）
```

- 工具还原后 sha16 = `dff2d29c800e4ba4`（== 移走前）、`diff -q` **逐字节相同**；
- ⚠️ **这是本趟唯一一次扰动共享树**（窗口 ~40 s，只读观测面），已在此披露；选择它的理由：这是"工具级 `NOINFO` ⇒ 调用方非 0"的**唯一**端到端证法（见 §6.2 的结构性说明）。
- **结构性说明**：裁定 ③ 给的顺序里，**路径②**在真仓永远能命中（两个脚本同目录）⇒ "声明件被挪走 ⇒ 调用方报 `NOINFO`"在**真仓里不可构造**（挪走真声明件会让检查器自己先在 `set -u` 上死掉）；所以 (a) 的成对读数在**工具层**取，(d) 在调用方层取。两者都是现场实测，没有推测。

---

## §5 真实树读数（改前 → 改后）

```bash
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh ; echo $?     # 改前 rc=1 → 改后 rc=1
```

| | 计数行（原文） |
|---|---|
| **改前**（`W52C` 末态） | `计数：OK=135  MISMATCH=35（STALE=35  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4]  DIVERGENT=5  NO-AUTHORITY=0  LIB-COPY=33  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0` |
| **改后** | `计数：OK=135  MISMATCH=35（STALE=35  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4]  DIVERGENT=5  CROSS-CONFIG=101  LIB-COPY=33  SKIP(obj)=14  SKIP(stub)=20  SKIP(ref)=12  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0` |

- 差值 = **一格**（`NO-AUTHORITY=0` → `CROSS-CONFIG=101`），其余**逐字相同**（§3.3 的 `diff` 双证）；
- `APPSYNC=` 行：`APPSYNC=MISMATCH（MISMATCH=35[STALE=35 NEWER-DIFF=0] MISSING=0 UNEXPECTED=16[DECL-GAP-EQ=12 DECL-GAP-DIFF=4] DIVERGENT=5 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0 —— 见上；本脚本**不改写任何目录**）` —— **改前/改后逐字相同**（`.sh` 与 `.py` 两件都换了，但判定面零位移）；
- `#SUMMARY|`：`refdirs=14|expect=190|projects=86|unknown=1|unresolved_hintpath=34|invisible_copysites=76|invisible_write=11|invisible_read=65|invisible_capped=26|invisible_ext_write=5|invisible_ext_read=0|invisible_indirect_write=13` —— **改前/改后逐字相同**；
- 登记段（`W52C` 接的线仍有效）：`在册 13 条：仍红 1 ｜ 已转绿 12`（PC 册）＋ `在册 38 条：仍红 38 ｜ 已转绿 0`（PFWB 册）—— **逐字未变**。

---

## §6 边界、未做、自查自伤与新发现

### 6.1 ⚠️ 自查自伤：我把一个 ITEMS 注记写坏，被**本仓两颗牙**当场抓住（已修）

- 症状①：`--list-items` 报 `ITEMS_SYNC=NO`，且 .sh 侧多出三条**垃圾"件名"**（`Debug是  之前的事实，且Release` 等）；
- 症状②：`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=2`（`check-applocal-sync.sh:176` col 260/264）。
- **同一个根因**：我在双引号注记里写了 `"…"` 与一对**反引号**（`` `#39` ``）⇒ 双引号提前闭合 + 反引号被当命令替换 ⇒ `ITEMS` 数组被**拆成多条**。
- 影响面：`scan()` 对无 `|` 的垃圾元素 `continue` ⇒ **读数未受影响**（那趟 `--selftest` 仍 18/18），但**表结构已坏** —— 这正是"牙比读数先发现"的现场。
- 修法：注记改用 `「」` 与**无反引号**措辞；复核：`ITEMS（9 项）`、`ITEMS_SYNC=YES`、`SHELL_QUOTE_TRAP=PASS traps=0`（`rc=0`）。
- **教训（写给后人）**：`ITEMS` 是**双引号字符串**，里面**不许**出现 `"` 与反引号 —— 本仓两颗牙会抓，别绕过它们。

### 6.2 `CROSS-CONFIG` 的射程（**没有测到**的东西，不许读成"同配置"）

1. **`obj/**` 与 `CycleStub.*` 里的跨配置副本不进本格**（本格与旧格**同槽**，在 ③/④ 的 `continue` 之后）—— 它们按构造不是加载源；
2. **路径里认不出配置的副本不进本格**（`bin/` 直下、自定义目录）⇒ 那些副本**既不算跨配置**、也**照样**按同代判据判 ⇒ 不是"漏判"，是"少一格可见性"；
3. **`RID` 目录（`release_*`）归 `Release`** ⇒ 若声明配置是 `Release`，RID 副本**不算跨配置**（但它们照旧按同代判）；
4. **本格不判红**：`CROSS-CONFIG>0` 而 `MISMATCH=0` 时 `APPSYNC=PASS`（附提示）—— 这是裁定 ② 的明文（"仍不判红"）；反过来说，**本格今天没有任何判据能力**，它只是**可见性**。

### 6.3 ⚠️ 新发现（**量化上交，本趟未改**）：`applocal-expect.py:88` 的硬编码 `Debug` 影响本册 2 条红

`PROPS["WpfLinuxSelfBuiltConfiguration"] = "Debug"`（`:88`）把 csproj 里的 `$(WpfLinuxSelfBuiltConfiguration)`
**替换成 Debug**（现场声明是 `Release`）⇒ `REFDIR`（"被 HintPath 引用 ⇒ 解析源"那张表）**按 Debug 口径拼出来**。
现场量化（同一个工具，只把该行改成 `CFG`，两趟都跑真仓）：

| 量 | 现件（硬编码 Debug） | 跟随声明 |
|---|---|---|
| `#REFDIR` 条数 | **14** | **23** |
| `#EXPECT` 行差异 | — | **0 行**（`expect=190` 不变） |
| 只在现清单里的目录 | `build/PresentationFramework.Classic.Linux/bin/Debug`（唯一 1 个） | — |
| 只在跟随声明清单里的目录 | — | 10 个（`build/*/bin/Release` 一族） |

对本册 34 条 `STALE` 逐行归因：**24 条**所在目录是启动宿主（与 `REFDIR` 无关）＋ **8 条**目录在两种 `REFDIR` 里都在
（还有 csproj **写死** `bin/Debug` 的 HintPath）⇒ **32 条与 `:88` 无关**；**只有 2 条**（`build/PresentationFramework.Classic.Linux/bin/Debug/{PresentationFramework,WindowsBase}.dll`）
是**只**因 `:88` 的 Debug 口径才成为"解析源"。
⚠️ 方向：把 `:88` 跟随声明会**新增 10 个 Release 解析源**（多半是**加严**），不是放松。
⇒ **不在裁定 ③ 的改法里，故未改**；若要改，应作为**独立一项**（它动的是 `REFDIR` 判据面，会让真实树读数整体位移）。

### 6.4 未做（如实列）

1. **`--apply`**：裁定 ① 明示"你仍然不要手工 `--apply`" ⇒ 本趟**只跑干跑**之外**连干跑也没重跑**（38 份的清单已在 `W52C` 记录，且本趟未改任何副本）；
2. **`C1c`（`samples/ThirdPartyMini` 的 4 条 `UNEXPECTED-DIFF` 处置）与 `C6`（波尾跑 `--selftest`）**：主控自办 ⇒ 未做；
3. **`KNOWN-DEFECTS.md` / 声明表**：未动（`D-G62` 的登记放波内做，避免重演 `#48` 那次 `declared 96→97` 漂移）；
4. **`applocal-expect.py:88`**：见 §6.3（量化上交，未改）；
5. **`sync-applocal-authority.sh`**：未动（裁定 ① 的处置时机在波内 `3.5`）；
6. `W52C-report.md`（第一趟报告）**未改**（不在本趟写域）⇒ 它里面的 `NO-AUTHORITY` 字样**已过期**，读者请以本报告 + 现场为准。

### 6.5 牙与棘轮（本趟末态）

```
SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=141 sh=63 py=78 diag=64 allow=0        rc=0
PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=63 sites=77 hit=1 low=10 diag=2 safe=64 runs=12   rc=0
SELFCONFIG_DEBT_CHECK=PASS live=140 max=167（只许减少；降到 0 = 阶段 3 完成）          rc=0
bash -n build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh  → 通过（无输出）
python3 -c "import ast;ast.parse(open(...applocal-expect.py...).read())"  → 通过
```

棘轮：`W52C` 末态 **141** → 本趟 **140**（**净减 1**；两件都不含新增的"写死 `bin/Debug`"代码）。

---

## §7 复算命令（逐条，可粘贴）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"

# ① 现配置与两张表一致
bash build/selfbuilt-config.sh                                   # → Release
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --list-items | grep -E 'ITEMS（|ITEMS_SYNC'

# ② 自检（18/18；退出码 0）
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest; echo "rc=$?"
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest | grep -cE '^SELFTEST_[A-Z0-9]+=PASS'   # → 18

# ③ 真实树（rc=1 是预期）+ 新格
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -E '^计数：|^APPSYNC='
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh | grep -c '^    CROSS-CONFIG'                    # → 101

# ④ 裁定② 的成对（沙箱，约 20 s；脚本正文见报告 §3.1）
bash /tmp/w52c2-Dpair.sh

# ⑤ 裁定③ 的成对（工具层 + 路径①②）
bash /tmp/w52c2-c1b.sh
python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py "$PWD" 2>/dev/null | grep -m1 '^#SUMMARY|'      # → expect=190

# ⑥ §6.3 的量化（`:88` 影响）：把该行换成 CFG 再跑真仓、比 #REFDIR
mkdir -p /tmp/l88/build && cp -p build/DirectWrite.Linux/wic-shim/applocal-expect.py /tmp/l88/build/x.py
sed -i 's/^    "WpfLinuxSelfBuiltConfiguration": "Debug",/    "WpfLinuxSelfBuiltConfiguration": CFG,/' /tmp/l88/build/x.py
diff <(python3 build/DirectWrite.Linux/wic-shim/applocal-expect.py "$PWD" 2>/dev/null | grep '^#REFDIR') \
     <(python3 /tmp/l88/build/x.py "$PWD" 2>/dev/null | grep '^#REFDIR') | grep -c '^[<>]'                     # → 11

# ⑦ 牙与语法
bash build/MilBridge/tools/shell-quote-trap-check.sh | grep '^SHELL_QUOTE_TRAP'   # → PASS traps=0
bash build/MilBridge/tools/pipefail-sigpipe-check.sh | grep '^PIPEFAIL_SIGPIPE'   # → PASS
bash build/selfbuilt-config.sh --debt-check                                       # → PASS live=140 max=167
bash -n build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh

# ⑧ 回退（全份还原本趟起点 = W52C 末态）
cp -p /tmp/w52c2-check.bak    build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh
cp -p /tmp/w52c2-expect.bak   build/DirectWrite.Linux/wic-shim/applocal-expect.py
cp -p /tmp/w52c2-registry.bak build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md
sha256sum build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh build/DirectWrite.Linux/wic-shim/applocal-expect.py | cut -c1-16
#   → d82e920b49bb0f0f / a7e05921b77524c2
```

### 本报告自身

- 路径：`build/MilBridge/W52C2-report.md`
- `head -n -1 build/MilBridge/W52C2-report.md | sha256sum | cut -c1-16` = **`2aa8f7fefd05b957`**（口径：**去掉本行之后的正文**整份 sha256 前 16 位；正文 298 行，本行不计入 ⇒ 本值可现场复算相等）
