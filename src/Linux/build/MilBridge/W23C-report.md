# W23C 报告 —— `D-A2`：app-local 检查器的覆盖面（`ITEMS` 补 PC + `SCAN_ROOTS` 补 `tools` + 在册红登记）

- **lane** = `W23C`｜**日期时间**：2026-09-16 23:55:00 → 2026-09-17 00:02（+0800）
- **kernel** = `6.8.0-138-generic`｜`nproc=3`
- **loadavg**：开工 `0.70 0.34 0.14`（23:55）｜最低 `0.34`（同上 1 分钟均值，本车道起点）｜**最高 `3.93`**（00:00）｜收工 `3.87`（00:01）
- **`MemAvailable`**：开工 `3,104,840 kB`｜**最低 `3,104,840 kB`**｜收工 `3,552,376 kB`（期间曾到 `3,657,816 kB`；**本车道全程零 `dotnet`**，只跑 `bash`/`python3`/`sha256sum`/`find`/`grep`）
- **纪律**：未跑 `dotnet`（build/run/restore/msbuild 全 0 次）｜未跑 `verify-all`｜未 `pkill -f`｜改既有文件前均 `cp -p` 备份
- **预登记**：`docs/WAVE23-PREREGISTRATION.md` §3（P3）｜**主控插话**（口径更正：撤回"不到 17 份红即失败"）已并入本报告 §②

## ① 一行结论

**判据已上线，两极化已实测；实测逐份红 = 13 份（12 份 `PresentationCore.dll` + 1 份 `tools/` 漏扫暴露的 `WpfGfx.Linux.dll`），不是 17 份 —— 差的 5 份是 Release 路径副本，走的既有 `NO-AUTHORITY` 豁免（判不了 ≠ 一致）；"17"在权威 `pc` 被重建后才会回来（推演见 §②.3）。**

---

## ② 改动逐处 + before/after

### 2.1 逐处改动（`build/DirectWrite.Linux/wic-shim/`）

| 文件 | before sha16 | after sha16 | before size/mtime | after size/mtime |
|---|---|---|---|---|
| `check-applocal-sync.sh` | **`aad23482f84bdf44`** | **`013df358c0bed2a3`** | 55,520 B / 2026-09-15 18:49:36 | 62,955 B / 2026-09-17 00:00:44 |
| `applocal-expect.py` | **`6eafbea14e7ea41e`** | **`7becc5266636c405`** | 27,314 B / 2026-09-15 18:49:02 | 27,933 B / 2026-09-16 23:57:08 |
| `known-red-PC-copies.md`（**新建**） | —— | **`e5946a8a7ce1cfe0`** | —— | 6,109 B / 2026-09-16 23:58:19 |

备份（`cp -p`，`$HOME/w23c-scratch/backup/`）：`check-applocal-sync.sh` = `aad23482f84bdf44`（55,520 B，mtime 保留 2026-09-15 18:49:36.138526856）、
`applocal-expect.py` = `6eafbea14e7ea41e`（27,314 B，mtime 2026-09-15 18:49:02.519085205）。

**改动 1 —— `SCAN_ROOTS` 补 `$REPO/tools`**（`:93`，改前 `:93` 逐字为
`SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build:$REPO/tests:$REPO/samples:$REPO/src}"`）：

```bash
SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build:$REPO/tests:$REPO/samples:$REPO/src:$REPO/tools}"
```
（+5 行注释记录为什么：`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll` = `16baacfccfcf1df0`、288,768 B、
该目录有 `GeometryOracle.runtimeconfig.json` ⇒ **是启动宿主**，改前**连枚举都没有**。
注释里同时钉死了不许再抄错的那一句：真漏扫的是 `tools/`，**不是** `.artifacts/`。）

**改动 2 —— `ITEMS` 补 `PresentationCore.dll`**（Authority = `$REPO/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`），
插在 `ReachFramework.dll` 与 `wpfgfx_cor3.so` 之间（`ITEMS` 由 6 项 → **7 项**）：

```
 "PresentationCore.dll|$REPO/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll|PC 托管件（Debug 权威）；2026-09-16 W23C 按用户裁决纳入 D-A2（此前 PC 的 32 份非权威副本**没有任何逐份判据**）；暴露出的在册红见同目录 known-red-PC-copies.md（**登记≠已容忍**）"
```

**改动 3 —— `applocal-expect.py` 的 `ITEMS` 同步补 PC**（补在**声明式来源那一路**：权威路径 + 各 csproj 的
`<Reference>`/`<HintPath>`/`<ProjectReference>` 闭包；**没有手写任何副本清单**）：

```python
    ("PresentationCore.dll", REPO + "/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll"),
```
（+5 行注释说明"另一半洞"：PC 不在任何一张 ITEMS 表里 ⇒ **删掉一份 PC 副本连 `MISSING` 都不会报**。）

**改动 4 —— 新增 `--list-items` 只读模式**（本件顺手兑掉的一张空头支票，见 §⑦.4）：把两张权威表并排打印 +
逐项判一致性，输出 `ITEMS_SYNC=YES/NO`（`0/1`；python 不可用 `3=NOINFO`）。**只打印、不扫描、不改文件**。

**改动 5 —— 新增 `show_registry()`（在册红逐条点名，只读只打印）**（见 §③）。**明确不参与判定**。

### 2.2 "没有放松任何判据"的机器证（`diff`）

`diff $HOME/w23c-scratch/backup/check-applocal-sync.sh build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`：
**`<` 行 = 1（唯一被替换掉的就是那行旧 `SCAN_ROOTS`）**，`>` 行 = 93（全是注释 + 1 条 ITEMS + 两个**只打印**的块）。
⇒ 判定分支（① `ref` / ② `stub` / ③ `obj` / ④ `release+Debug`→`NO-AUTHORITY` / ⑤ `LIB-COPY` / ⑥ `UNEXPECTED-EQ|DIFF` / ⑥' `OK|STALE|NEWER-DIFF`）、
所有 `is_*()` 谓词、`CNT_*` 计数器、`APPSYNC=` 字面与**三个退出码（0/1/3）** **一个字节都没动**。
`applocal-expect.py` 的 diff = 纯新增 5 行（+1 条 ITEMS）。

**既有自检仍是机器证**：`bash check-applocal-sync.sh --selftest` ⇒ **`rc=0`、`SELFTEST=PASS`、16 个 A~N 自检全 PASS、`FAIL` 命中 0 次**
（日志 `$HOME/w23c-scratch/logs/SELFTEST.log` sha16 `ea947ab4f57bdc6a`、`SELFTEST2.log` sha16 `a95b6f8fe7cde833`）。
其中 `SELFTEST_B`/`SELFTEST_F` 带**负向断言**（`! grep -qE '^    (STALE|NEWER-DIFF|UNEXPECTED|MISSING|DIVERGENT|RETIRED)'`）⇒
证明新增的两个打印块**没有**伪造出判定行（在册红行一律以 `    [在册红]` 起头）。

### 2.3 "17"与实测 13 的对账（主控插话要求的逐条分类）

`#22`/W22D 的"17"= **内容 ≠ 权威的副本份数**（`W22D-report.md:89` 逐字：
"33 份 = 1 份权威 + 15 份内容相同 + **17 份内容不同**"）。把 W22D 那张表逐行套进**真**判定分支顺序后：

| W22D 的"不同"副本 | 份数 | 接线后的**真**类别 | 红? |
|---|---|---|---|
| `23567d420f0dbbaa` ×5（`DirectWrite.Linux/{FontEntryClosedLoop,SystemFontsProbe,WicClosedLoop,WicWriteClosedLoop,WiringSmoke}/bin/Debug`） | 5 | `STALE` | **红 5** |
| `c0763fc10173e7ff` ×1（`FallbackCriteria/bin/Debug`） | 1 | `STALE` | **红 1** |
| `9adac6b8d8e285c3` ×3 | 3 | `CoverageProbe/bin/Debug`、`WpfFeatureProbe/…/Debug` = `STALE`；`HelloWpf/bin/Release` = **`NO-AUTHORITY`** | **红 2**（1 份判不了） |
| `f4a454c8fe69cdfe` ×3 | 3 | `HbTextLineParity/bin/Debug`、`TextLineProto/bin/Debug` = `STALE`；`StrictTierProbe/bin/Release` = **`NO-AUTHORITY`** | **红 2**（1 份判不了） |
| `684424fea3a0812a` ×2（`CompositeFontProbe/bin/Release`、`T2eLineHeight/bin/Release`） | 2 | 均为 **`NO-AUTHORITY`** | 0 |
| `14086882b1509dcd` ×1（`MinMaxProbe/bin/Release`） | 1 | **`NO-AUTHORITY`** | 0 |
| `95a669cc510337d1` ×1（`PresentationFramework.Classic.Linux/bin/Debug`） | 1 | `STALE`（该目录是 HintPath 解析源 ⇒ 不被 `LIB-COPY` 豁免） | **红 1** |
| `f31822ce4a3e510d` ×1（`HelloWpf/bin/Debug/net10.0`） | 1 | `STALE` | **红 1** |
| **合计** | **17** | **12 `STALE` + 5 `NO-AUTHORITY`** | **红 12** |

⇒ **差 5 份的全部原因 = 既有豁免分支 ④**（`:235` `is_release_path "$f" && is_debug_auth "$exp"`）：
W22D 的模拟把它们也记成了 `STALE/NEWER-DIFF`，**按真分支顺序它们落到 `NO-AUTHORITY`（"判不了，不算不一致"）**。
这正是主控插话要我区分的第一种差别（**判定式/豁免分支与预演不一致** ⇒ 我按真读数报，不按预演报）。
**不是** `pc` 变了（本件全程 `pc` 未变，见 §⑥），也**不是** 3.6 刷新收敛（本次读数里 12 份旧副本一份都没被刷）。

**"17"何时回来（推演，非实测）**：当 `W23B` 把权威 `pc` 重建后，**现在恰好 == 权威 `e7cabff9417ed380` 的 5 份 Debug 副本**
（`build/PresentationFramework.Linux`、`build/ReachFramework.Linux`、`build/System.Printing.Linux`、
`samples/WpfTextDemo/bin/Debug/net10.0`、`tests/…/ManagedLayer.Tests/bin/Debug/net10.0`）
会翻成 `STALE` ⇒ **12 + 5 = 17**。**本件不实测这一步**（不许碰 `build/*.Linux/**` 权威产物；且 `W23B` 正在重建它）。
⇒ 主控插话的结论**成立且更强**：这个数**与"哪一份 `pc` sha 是权威"绑定**，**不是常量**。

---

## ③ 改动后"红"的逐份点名表（实测，`rc=1`）

**读数**：`2026-09-17 00:00:58 → 00:01:06 +0800`｜`bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`
（日志 `$HOME/w23c-scratch/logs/FINAL.log`，sha16 `770f25334ce849cd`，42,715 B）
**权威取现场**：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = **`e7cabff9417ed380`**（4,196,864 B，mtime 2026-09-16 18:47:26）

```
计数：OK=51  MISMATCH=13（STALE=13  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=3  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0
APPSYNC=MISMATCH（MISMATCH=13[STALE=13 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=3 RETIRED=0 —— 见上；本脚本**不改写任何目录**）
```

### 3.1 逐份判定的红（13 份，全部 `STALE`；原样点名行）

```
    STALE         build/MilBridge/tests/HbTextLineParity/bin/Debug/PresentationCore.dll        EXPECT e7cabff9417ed380  ACTUAL f4a454c8fe69cdfe（副本早 11218 秒 ⇒ 必须刷新）
    STALE         build/MilBridge/tests/TextLineProto/bin/Debug/PresentationCore.dll           EXPECT e7cabff9417ed380  ACTUAL f4a454c8fe69cdfe（副本早 11218 秒 ⇒ 必须刷新）
    STALE         build/MilBridge/tests/CoverageProbe/bin/Debug/PresentationCore.dll           EXPECT e7cabff9417ed380  ACTUAL 9adac6b8d8e285c3（副本早 114533 秒 ⇒ 必须刷新）
    STALE         build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll     EXPECT e7cabff9417ed380  ACTUAL 95a669cc510337d1（副本早 527381 秒 ⇒ 必须刷新）；**该目录被 csproj 的 HintPath 引用 ⇒ RAR 会从这里解析传递依赖（解析源，必须与权威一致）**
    STALE         build/DirectWrite.Linux/WicWriteClosedLoop/bin/Debug/PresentationCore.dll    EXPECT e7cabff9417ed380  ACTUAL 23567d420f0dbbaa（副本早 246261 秒 ⇒ 必须刷新）
    STALE         build/DirectWrite.Linux/FallbackCriteria/bin/Debug/PresentationCore.dll      EXPECT e7cabff9417ed380  ACTUAL c0763fc10173e7ff（副本早 85962 秒 ⇒ 必须刷新）
    STALE         build/DirectWrite.Linux/WicClosedLoop/bin/Debug/PresentationCore.dll         EXPECT e7cabff9417ed380  ACTUAL 23567d420f0dbbaa（副本早 246261 秒 ⇒ 必须刷新）
    STALE         build/DirectWrite.Linux/WiringSmoke/bin/Debug/PresentationCore.dll           EXPECT e7cabff9417ed380  ACTUAL 23567d420f0dbbaa（副本早 246261 秒 ⇒ 必须刷新）
    STALE         build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/PresentationCore.dll      EXPECT e7cabff9417ed380  ACTUAL 23567d420f0dbbaa（副本早 246261 秒 ⇒ 必须刷新）
    STALE         build/DirectWrite.Linux/FontEntryClosedLoop/bin/Debug/PresentationCore.dll   EXPECT e7cabff9417ed380  ACTUAL 23567d420f0dbbaa（副本早 246261 秒 ⇒ 必须刷新）
    STALE         samples/WpfFeatureProbe/bin/Debug/net10.0/PresentationCore.dll               EXPECT e7cabff9417ed380  ACTUAL 9adac6b8d8e285c3（副本早 114533 秒 ⇒ 必须刷新）
    STALE         samples/HelloWpf/bin/Debug/net10.0/PresentationCore.dll                      EXPECT e7cabff9417ed380  ACTUAL f31822ce4a3e510d（副本早 431095 秒 ⇒ 必须刷新）
    STALE         tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll                      EXPECT c400ab1638e0c3d2  ACTUAL 16baacfccfcf1df0（副本早 452841 秒 ⇒ 必须刷新）
```

⇒ **PC 12 份 + `tools/` 暴露的 1 份 = 13 份**。逐份的 `路径/sha/权威/类别/首次登记日期/处置` 已写进
**`build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`**（sha16 `e5946a8a7ce1cfe0`）。

### 3.2 分组级红（`DIVERGENT=3`）—— 12 份 Release 副本**不是完全没人管**

```
    DIVERGENT     WpfGfx.Linux.dll [Debug] 有 2 种 sha：          ← 新：`tools/` 那份 16baacfccfcf1df0 进组（10 行）
    DIVERGENT     PresentationCore.dll [Release] 有 5 种 sha：    ← 新：12 行
    DIVERGENT     PresentationCore.dll [Debug] 有 7 种 sha：      ← 新：18 行
```
⇒ 逐份判定把 Release 副本让给了分支 ④（判不了），但"跨副本一致性"分组**仍然把它们算进同配置组**
（`WpfGfx.Linux.dll [Debug]` 由改前的 `CONSISTENT 9 份` 变成 `DIVERGENT 10 行 2 种 sha`）——
所以"Release 副本陈旧也永远不红"这句话**在组级上不成立**（组内 ≥2 种 sha 即 `DIVERGENT` + `rc=1`）。

### 3.3 与改前的差（同一台机器、同一 `pc`）

| 格 | 改前（23:55:58，`BEFORE.log` `5579b1080e0594e3`） | 改后（00:01:06，`FINAL.log` `770f25334ce849cd`） | 归因 |
|---|---|---|---|
| `OK` | 45 | 51 | +6 = PC 的 6 份 `OK` |
| `MISMATCH`（`STALE`） | **0** | **13** | **12 PC + 1 tools** |
| `DIVERGENT` | 0 | **3** | PC[Debug]、PC[Release]、WpfGfx[Debug]（`tools`） |
| `NO-AUTHORITY` | 25 | 39 | +12 PC Release，+2 = 另一条车道的 `D5CbrProbe/bin/Release`（见 §⑦.5） |
| `SKIP(obj)` | 6 | 7 | +1 = `build/PresentationCore.Linux/obj/Debug/PresentationCore.dll` |
| `SKIP(stub)` | 4 | 6 | +2 = 两份 `build/CycleStub.*/bin/Debug/PresentationCore.dll` |
| `UNEXPECTED` | 1 `[DECL-GAP-EQ=1]` | 1 `[DECL-GAP-EQ=1]` | **改前就有的独立红**，与本件无关（见 §⑦.2） |
| `MISSING` | 0 | 0 | 结构性质保住（§⑦.5 有一次 2 的瞬态） |
| 期望副本 / 工程数 | 56 / 81 | 88 / 82 | **+30 = PC**、**+2 与 +1 = 另一条车道新建的 `D5CbrProbe`**（非本件；用改前四根跑仍是 88/82 ⇒ 与 `tools` 无关） |
| `rc` / `APPSYNC` | 1 / `MISMATCH` | 1 / `MISMATCH` | —— |

---

## ④ "在册红"的落地形态与理由（**本件的核心**）

### 4.1 该检查器**没有**既有的"在册红"机制（实测，不是推断）

- `grep -n 'known-red\|registry\|在册' build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` ⇒ **0 命中**
  （改动后命中的只有我新加的 `show_registry` 那一段）。
- 退出码只有 `0=PASS` / `1=MISMATCH` / `3=NOINFO`（`:616-624` 的三个分支），**没有任何"登记后放行"的口子**。
- ⇒ 按用户裁决与主控插话 ④：**不许发明一个让 `rc` 变绿的机制**（那等于把未登记红压成绿）。

### 4.2 落地形态（三层，**没有一层动 `rc`**）

1. **判据上线**（§② 改动 1~3）：PC 的每一份副本现在都有逐份判定，`tools/` 现在在枚举范围内。
2. **书面登记**：新建 `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（sha16 `e5946a8a7ce1cfe0`），
   表 A = 12 份 PC 副本、表 B = 1 份 `tools/` 副本，逐份记 `路径 / 登记时副本 sha16 / 登记时权威 sha16 / 类别 / 首次登记日期 / 处置`，
   并显式声明"**登记时权威 sha 是快照，不是常量**"（本波 `pc` 正在被重建）。
3. **检查器输出里逐条点名**（`REGISTRY=` 在 `:665`、`show_registry()` 定义 `:667-700`、调用 `:701`，**只读只打印**）：
   ```
   --- 在册红（书面登记 build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md；**登记≠已容忍**：本段不参与判定，rc 仍由上面五个计数器决定）
       [在册红] build/DirectWrite.Linux/FontEntryClosedLoop/bin/Debug/PresentationCore.dll 23567d420f0dbbaa（现权威 e7cabff9417ed380；登记时权威 e7cabff9417ed380；类别 STALE；处置 刷新（重编该工程即收敛））
       …
       [在册红] tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll                16baacfccfcf1df0（现权威 c400ab1638e0c3d2；登记时权威 c400ab1638e0c3d2；类别 STALE；处置 刷新（重编 `tools/GeometryOracle` 即收敛））
       在册 13 条：**仍红 13** ｜ 已转绿 0（见上，应从表里删）｜ 缺件 0
       ⇒ 本波之后 close-wave.sh:159-160 会**长期**打印 [⚠️ APPSYNC 非 PASS]：那是**登记在册的**红（APPSYNC 是告警不是硬闸），不是新问题；处置见登记表的处置列。
   ```
   这一段的语义：**逐条点名 + 现权威 + 类别 + 处置**；`[在册红·已转绿]` 是**唯一**的"该条目应从表里删"的自证；
   登记条目**照样计进 `MISMATCH`**（本节读数里 `MISMATCH=13` 与"在册仍红 13"逐条一一对应）。
   实现上有两条**防自欺**的闸（都是实测踩出来的）：
   - 只认"第 2 列是 16 位小写 hex"的行 —— 否则登记文件里的**汇总表**会被当成登记条目
     （实测：加闸之前 6 条汇总行被读成"缺件 ⇒ 在册 19 条"，**虚高 6 条**）；
   - 登记路径**不在本次扫描根内**时逐条标 `（**不在本次扫描根内** ⇒ 本次没枚举它）`
     （实测：`SCAN_ROOTS` 收窄到改前四根时，`tools/` 那条仍会被打印 ⇒ 必须自称"本次没枚举它"，否则读者会以为它被判定过）。

### 4.3 为什么这样落地（理由）

- 该检查器的既有语义是"**判不了 ≠ 不一致**"（口径 v2）；给它加一个"登记即绿"的开关会把**这 12 份真陈旧**洗成非红 ⇒
  与纪律"登记 ≠ 已容忍"、与用户裁决直接冲突。
- 但**只加红不给名字**也不行：`close-wave.sh:159-160` 的 `⚠️ APPSYNC 非 PASS` 会**长期**出现，
  下一个人会去追它。⇒ 书面登记 + 输出点名**同时**给出"这是红"和"这是哪 13 份、谁负责处置"。
- **`build/MilBridge/known-red.json` 一个字节都没动**（那是五臂门禁的登记表，与本检查器不是同一份）。

---

## ⑤ 正 / 反极性（**必须实测**，两趟都留档）

### 5.1 正极性：接线后立刻红（真文件，不是私有拷贝）

- 改前同一命令：`MISMATCH=0`、`rc=1`（唯一的红是既存的 `UNEXPECTED-EQ=1`）。
- 改后：**`MISMATCH=13`（12 PC + 1 tools）**、`DIVERGENT=3`、`rc=1`，逐份点名见 §3.1。
- 其中 **12 份 PC 副本是"判据覆盖从 0 到 1"**：改前 PC 的 32 份非权威副本**没有任何逐份判据**（连 sha 都没被打印，
  因为 PC 不在 `ITEMS` 里 ⇒ `find` 的名字列表里根本没有 `PresentationCore.dll`）。

### 5.2 反极性（防作弊）：刷一份 ⇒ 变绿；改回 ⇒ 又变红（同一命令、同一 `pc`）

对象：`build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll`
（改前：`95a669cc510337d1`、4,068,864 B、mtime 2026-09-10 16:17:45.400643491 +0800、epoch `1789028265`）

| 趟 | 动作 | 该副本 sha16 | 判定行 | 计数 | 在册红段 | 日志 |
|---|---|---|---|---|---|---|
| 0 | 原始 | `95a669cc510337d1` | `STALE … ACTUAL 95a669cc510337d1` | `MISMATCH=13` | 在册 13 ／ 仍红 13 ／ 已转绿 0 | `AFTER3.log` `3f3b8ab31dcf1f84` |
| 1 | `cp <权威> <该副本>`（**刷成权威**） | `e7cabff9417ed380` | `OK            build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll     e7cabff9417ed380；**该目录被 csproj 的 HintPath 引用…**` | **`OK=52 MISMATCH=12`** | **`[在册红·已转绿] …（现权威 e7cabff9417ed380；登记时 95a669cc510337d1 2026-09-16 ⇒ **应从登记表移除**）`＋"仍红 12 ／ 已转绿 1"** | `POLARITY_GREEN.log` `d3fdb2f6dff710af` |
| 2 | `cp -p <备份> <该副本>`（**逐字节复原**） | `95a669cc510337d1` | `STALE … ACTUAL 95a669cc510337d1（副本早 527381 秒 ⇒ 必须刷新）` | **`OK=51 MISMATCH=13`** | 在册 13 ／ 仍红 13 ／ 已转绿 0 | `POLARITY_RED.log` `3f3b8ab31dcf1f84` |

- **复原证明**：`cmp` ⇒ `IDENTICAL`；`sha256sum` ⇒ `95a669cc510337d1`；size ⇒ 4,068,864 B；
  **mtime/epoch 与改前逐位相同**（`1789028265` = 2026-09-10 16:17:45.400643491 +0800）；备份 `$HOME/w23c-scratch/polarity/PFC-PC.orig.dll` sha16 `95a669cc510337d1`。
- **附加证据（很强的一条）**：第 2 趟的日志与第 0 趟的日志 **sha16 完全相同**（`3f3b8ab31dcf1f84`）⇒ 复原后是**逐字节同一次读数**，
  不是"看起来一样"。

### 5.3 `SCAN_ROOTS` 补 `tools` 的极性对照（**不动任何文件**：只换 `SCAN_ROOTS`）

`SCAN_ROOTS="$R/build:$R/tests:$R/samples:$R/src"`（= 改前的四根，同命令同 `pc`）：

| 格 | 四根（改前默认） | 五根（接线后） |
|---|---|---|
| `MISMATCH` | **12**（只有 PC） | **13** |
| `DIVERGENT` | **2**（PC[Debug] + PC[Release]） | **3**（+`WpfGfx.Linux.dll [Debug]`） |
| `16baacfccfcf1df0` 出现在判定行里 | **0 次**（日志里 1 次命中全部来自在册红段，且已自称"不在本次扫描根内"） | 1 次（`STALE tools/GeometryOracle/…/WpfGfx.Linux.dll`） |

日志：`$HOME/w23c-scratch/logs/OLDROOTS.log` sha16 `fe59887384504c02`。
⇒ 改前那份 `WpfGfx.Linux.dll` **确实"连枚举都没有"**（不是"枚举了但判绿"），补根后**多出来的正好是它 1 份**。

### 5.4 `--list-items` 的两极化（新模式的机器证）

用两份脚本的**私有拷贝**（`$HOME/w23c-scratch/itemsync/`，`AUTH_ROOT=$R` 指回真仓）：

| 趟 | 动作 | 输出 | rc |
|---|---|---|---|
| A | 两份原样 | `ITEMS_SYNC=YES（两张权威表的**件名与权威路径逐项一致**）` | **0** |
| B | 把 `.py` 副本里 PC 的权威改成 `…/bin/Release/…` | `✗ PresentationCore.dll：权威路径不一致 —— .sh=[…/bin/Debug/…] .py=[…/bin/Release/…]` + `ITEMS_SYNC=NO` | **1** |
| C | 删掉 `.py` 副本里的 PC 那一行 | `✗ PresentationCore.dll：只在 .sh 里有（.py 缺 ⇒ 期望集合里没有它）` + `ITEMS_SYNC=NO` | **1** |
| D | python 不可用（本次未实测，代码路径：`PYOUT` 为空 ⇒ `ITEMS_SYNC=NOINFO`） | —— | 3（**未实测**） |

---

## ⑥ 豁免分支的核查（哪些副本"被豁免"而非"被判定"）

PC 的 33 份副本在改后读数里的分布（**没有任何一份是"静默"的**，逐条都打印了 sha）：

| 类别 | 份数 | 是"被判定"还是"被豁免" | 逐份 |
|---|---|---|---|
| `STALE`（红） | 12 | **判定** | §3.1 |
| `OK` | 6 | **判定**（其中 1 份是权威自身 ⓪） | `build/PresentationCore.Linux/bin/Debug`（权威）、`build/PresentationFramework.Linux`、`build/ReachFramework.Linux`、`build/System.Printing.Linux`、`samples/WpfTextDemo/bin/Debug/net10.0`、`tests/…/ManagedLayer.Tests/bin/Debug/net10.0` |
| `NO-AUTHORITY` | 12 | **被豁免**（分支 ④，`:235`） | 全部 Release/RID 路径副本（`build/MilBridge/tests/{FrameProbe,CompositeFontProbe,HbTextLineParity,StrictTierProbe,T2eLineHeight,MinMaxProbe,ContractProbe,TextLineProto,CoverageProbe,PcLineOracle,DirectBranchCheck}/bin/Release/PresentationCore.dll` + `samples/HelloWpf/bin/Release/net10.0/PresentationCore.dll`）——**逐份打印 ACTUAL sha，但"判不了"** |
| `SKIP(stub)` | 2 | **被豁免**（分支 ②，`:220`） | `build/CycleStub.PresentationFramework.Linux/bin/Debug`、`build/CycleStub.PresentationUI.Linux/bin/Debug`（两份内容恰好 == 权威 ⇒ "恰好没坏"，**不是**因为判过） |
| `SKIP(obj)` | 1 | **被豁免**（分支 ③，`:227`） | `build/PresentationCore.Linux/obj/Debug/PresentationCore.dll`（内容 == 权威） |
| `LIB-COPY` | **0** | —— | **没有任何一份 PC 副本被 `LIB-COPY` 吞掉**：4 个"库输出目录"里 3 个是 HintPath 解析源（`PresentationFramework.Linux`/`ReachFramework.Linux`/`System.Printing.Linux`/`PresentationFramework.Classic.Linux`）⇒ 走 `is_refdir` 被判定；余下 2 份是 `CycleStub`（走 stub） |
| `MISSING` | 0 | —— | —— |

⇒ **口径 α 的残留（如实报）**：改前 32 份非权威副本**全部**零判据；改后 **17 份有逐份判定**（12 红 + 5 `OK`），
**15 份仍"判不了/按构造不判"**（12 Release + 2 stub + 1 obj）。其中 12 份 Release 副本**不是完全没人管**（组级 `DIVERGENT`，§3.2）。
⚠️ 别把两个 17 混起来：W22D 那个 17 = **内容 ≠ 权威**的份数（含 5 份 Release），本件这个 17 = **有逐份判据**的份数。**两者是不同的集合。**

**豁免分支一个都没扩大/放松**：`NO-AUTHORITY`/`SKIP(obj)`/`SKIP(stub)`/`SKIP(ref)` 的谓词与顺序**逐字节未变**（§2.2 的 diff 证），
且 `--selftest` 的 D/F/G/H/I/J 五条正是盯这些豁免的**两极化**自检，**全 PASS**。

---

## ⑦ `pc` sha 是否在读数期间变过 + 我推翻/发现的话

### ⑦.1 `pc` 现场 sha（纪律 35）

| 读数 | `pc` before | `pc` after | 变? |
|---|---|---|---|
| `BEFORE`（23:55:58） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |
| `AFTER1`（23:57:29） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |
| `AFTER2`（23:58:22） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |
| `POLARITY_GREEN`（23:58:46） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |
| `POLARITY_RED`（23:59:03） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |
| `FINAL`（00:00:58） | `e7cabff9417ed380` | `e7cabff9417ed380` | **否** |

⇒ **本件全部读数共用同一个权威 `pc` = `e7cabff9417ed380`，不存在"哪次读数配哪个 pc"的歧义**。
（`W23B` 当时**尚未**落刀重建；一旦落刀，本报告 §③ 的 12 份会变，登记表的"登记时权威 sha"列就是为此留的。）

### ⑦.2 发现（**改前就存在的红**，不是本件引入）

改前那次读数（`BEFORE.log` `5579b1080e0594e3`）**已经是 `rc=1`**：

```
计数：…  MISMATCH=0（STALE=0  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=0 …
    UNEXPECTED-EQ build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll          c400ab1638e0c3d2（**不在声明图里**，但 **sha == 权威 c400ab1638e0c3d2** ⇒ 未声明的传递依赖副本；**不是陈旧件，也不许当绿**）
```
⇒ 本件**没有**让它变绿、也**没有**把它登记进我的表（它是 `WpfGfx.Linux.dll` 的声明图缺口 `D-A1`，不是 PC 副本）——
**它需要主控单独裁决**（按 `D-A1` 的"声明"路走：把它声明出来，而不是放宽分支）。
**主控若以为"接线前 APPSYNC 是绿的"，那是错的**：接线前就已经是 `MISMATCH`。

### ⑦.3 发现（**未改，交主控裁决**）：`scan()` 的 `rc` 被调用方丢弃

`:654` `scan; scanrc=$?` —— **`scanrc` 赋了值却全脚本再没被用过**（`grep -n 'scanrc'` 只此 1 行命中）。
后果：`scan()` 里 `:212` 的 `[ -f "$exp" ] || { echo "    ⚠ 权威件缺失：$exp"; rc=1; }` **不会**让脚本退出码非 0
（最终退出码只看五个计数器：`MISMATCH/MISSING/UNEXPECTED/DIVERGENT/RETIRED`）。
⇒ "**某件的权威件整份不见了**"今天只印一行告警、`rc` 仍可能 0。**这是判据的洞，但不在本件射程**：
补它会让 `SELFTEST_E` 的沙箱（`$tmp/authB` 里没有 `ReachFramework.dll`/`PresentationCore.dll` 权威）从 `rc=0` 变成非 0 ⇒ **自检会立刻红**，
必须先补沙箱再动判据。**我没有动它**（本件的停条件是"不许放松"，而这是一处**加强**，须主控裁决 + 自检同步改）。

### ⑦.4 推翻/兑掉 `applocal-expect.py` 的一句空头承诺

`applocal-expect.py:41` 逐字写着"权威表（与 `check-applocal-sync.sh` 的 `ITEMS` 保持一致；改一处要同步另一处
—— **由 check 的 `--list-items` 校验**）"。**实测该开关以前根本不存在**：
改动前 `grep -n 'list-items' check-applocal-sync.sh` = **0 命中**（把 `--list-items` 当参数传进去只会被忽略并跑一整趟全仓扫描）。
本件**把这张支票兑成代码**（§② 改动 4），并给了它两极化证明（§5.4）。
⚠️ 遗留：`KNOWN-DEFECTS.md` 若引用过这个不存在的开关，需要更正（**本件未读数、未改文档**）。

### ⑦.5 发现（另一条车道的在飞件，**本件不归因、不登记**）

`AFTER1`（23:57:34）出现 `MISSING=2`（`build/MilBridge/tests/D5CbrProbe/bin/Release/{PresentationCore,DirectWrite.Linux.Provider}.dll`）。
逐条查证 = **`P1` 车道正在新建的 `D5CbrProbe` 工程的构建中间态**：
`D5CbrProbe/` 目录 mtime `2026-09-16 23:57:47`、`D5CbrProbe.csproj` mtime `23:56:58`（= 我两趟读数之间的 91 秒窗口），
其 `bin/Release` 的 dll 稍后才落地（我读数那一刻目录在、文件还没拷进去）。
**证明它不是我的改动引起的**：两条 `MISSING` 都在 `build/` 下（本来就是扫描根），且 `FINAL`（00:01:06）同一命令 `MISSING=0`。
⇒ **`MISSING=0` 这条结构性质今天仍然成立**（这也是主控点名"与 `pc` 无关、值得单独当判据"的那一格：**实测 0**）。

### ⑦.6 不许再抄错的那一条（本件复核为**主控正确**）

`SCAN_ROOTS`（`:93`）**包含** `$REPO/build` ⇒ `.artifacts/**` **在扫描范围内**。
改后日志里 `.artifacts/**` 的副本逐条在册（`build/MilBridge/.artifacts/obj/WpfGfx.Linux/release/…` =
`SKIP(obj)` 与 `NO-AUTHORITY` 各若干，`grep -c artifacts FINAL.log` = **15** 次命中）。⇒ **真漏扫的是 `$REPO/tools`**，已补。

---

## ⑧ 未测清单 / `NOINFO` 清单（**不许读成"通过"**）

1. **"权威 `pc` 重建后红数回到 17" 是推演，未实测**（§②.3）：不许碰 `build/*.Linux/**` 权威产物，且 `W23B` 正在重建它。
   ⇒ 实测值只有 `pc = e7cabff9417ed380` 时的 **12 份 PC 红**。
2. **`--list-items` 的 `ITEMS_SYNC=NOINFO`（python 不可用）分支未实测**（§5.4 趟 D）。
3. **`wpfgfx_cor3.so` 的期望仍算不出**：`EXPECT=UNKNOWN wpfgfx_cor3.so：无单一权威…`（1 个件，逐字在 `FINAL.log:207`）——
   本件**没有**给它造权威（那是 W22D §1.8 草案③，主控未派）。⇒ 它的 2 份副本今天仍只有**互比**（`CONSISTENT 2 份同 sha d567c26f197ec1e3`），
   "两份一起换旧"仍**静默**（`NOINFO`：本件没测）。
4. **`src/` 与 `tests/` 下是否还有别的"整目录漏扫"未普查**：本件只按派单补了 `tools/`（实证漏扫）。
   全仓其他顶层目录（`.artifacts*`/`docs`/`samples` 以外的、如 `staging`/`tools` 的子目录）**未做穷举**。
5. **发布/门禁侧的后果未实测**：主控已查清（`close-wave.sh:159-160` APPSYNC 是告警、`publish-milbridge.sh:100-112` 不改退出码），
   本件**未重跑 `close-wave.sh`**（那是主控的活）⇒ "波不会因这 13 份红中止"**引主控的核查，不是我的读数**。
6. **`APPSYNC` 长期红之后是否有人真去看登记表**：不可测（人因），只在登记文件与输出里都写明了"登记≠已容忍"。

---

## ⑨ 产物与留档

| 产物 | sha16 | size | mtime |
|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `013df358c0bed2a3` | 62,955 B | 2026-09-17 00:00:44 |
| `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | `7becc5266636c405` | 27,933 B | 2026-09-16 23:57:08 |
| `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（**新**） | `e5946a8a7ce1cfe0` | 6,109 B | 2026-09-16 23:58:19 |
| 本报告 `build/MilBridge/W23C-report.md` | `0922061766c5c18c`（= **本行之前的文件内容**读数；随后只改过行号与脚注 ⇒ **最终 sha16 以最终回复里的 `sha256sum` 为准**，31,913 B / 2026-09-17 00:02:53） | —— | —— |

读数留档（`$HOME/w23c-scratch/logs/`）：`BEFORE.log` `5579b1080e0594e3`｜`AFTER1.log` `2a325fce753bbb05`｜
`AFTER2.log` `14004f83713a8e71`｜`AFTER3.log` `3f3b8ab31dcf1f84`｜`POLARITY_GREEN.log` `d3fdb2f6dff710af`｜
`POLARITY_RED.log` `3f3b8ab31dcf1f84`（**与 `AFTER3` 逐字节相同 = 复原证明**）｜`OLDROOTS.log` `fe59887384504c02`｜
`FINAL.log` `770f25334ce849cd`｜`SELFTEST.log` `ea947ab4f57bdc6a`｜`SELFTEST2.log` `a95b6f8fe7cde833`。
备份：`$HOME/w23c-scratch/backup/{check-applocal-sync.sh,applocal-expect.py}`｜极性原件 `$HOME/w23c-scratch/polarity/PFC-PC.orig.dll`（`95a669cc510337d1`）。
