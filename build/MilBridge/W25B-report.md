# W25B —— `D-A2-r` **方案 B** 落地报告（`check-applocal-sync.sh` 的桥绝对锚判据）

lane=**W25B** ｜ 2026-09-17 12:25 → 12:35 +0800 ｜ kernel `6.8.0-138-generic` ｜ `nproc=3` ｜
loadavg 开工 `5.36 1.82 0.76` → 收工 `4.96 4.51 2.67` ｜ `MemAvailable` 开工 3,438,508 kB / 最低 2,890,424 kB /
收工 2,890,424 kB ｜ **零 `dotnet`** ｜ **未跑 `--apply`** ｜ **未跑 `sync-applocal-authority.sh` 的写模式**（只跑了它的默认**干跑**）｜ 未 `pkill`。
预登记 = `docs/WAVE25-PREREGISTRATION.md` §3 / §8；设计文档 = `~/w25-recon/da2r-plan.md`（`fabd8ae7cb81975f`）。

---

## 0. 结论在前

**落地成功，今天 0 条新红，判据能红、且能抓住两种假修。**

| 项 | 读数 |
|---|---|
| 改动件 | `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`：`fc4c249851fa1d71`（71,502 B / 778 行）→ **`7bc9364091a28fd4`**（86,734 B / 945 行） |
| 方案 | **B**（独立只读锚检查，**绝不把桥配进 `ITEMS`**）—— `ITEMS` 那一行**一个字节的语义都没动**（`exp` 仍是空串） |
| 新计数器（逐字） | **`CNT_BRIDGE_ANCHOR`**（摘要名 `BRIDGE-ANCHOR`）｜**`CNT_BRIDGE_NOINFO`**（摘要名 `BRIDGE-NOINFO`）—— **两者都红** |
| 进 `rc` 的确切行 | **`:935`**（判定链 `elif`）＋ **`:936`**（`APPSYNC=MISMATCH` 行）；调用点 **`:884`**；摘要格 **`:886`** |
| `--selftest` | **18 例全 PASS / 0 FAIL / rc=0**（改前 17 例；新例 **`SELFTEST_P`**，插在 `O` 之后、`echo "SELFTEST=PASS"`（`:873`）之前） |
| 今天（真仓、默认扫描根） | `BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`，**其余 12 个计数器逐字与改前相同**，`rc=1` 与改前相同 ⇒ **0 条新红** |
| 反极性（真件形态沙箱，两副本一起换成旧桥 `caf7baf9e67719aa`） | **旧件 `APPSYNC=PASS` rc=0**（`D-A2-r` 现场）→ **新件 `APPSYNC=MISMATCH` rc=1 `BRIDGE-ANCHOR=2`**；`cp -p` 还原 ⇒ `cmp` 逐字节 IDENTICAL + 输出**逐字节回到 STATE A** |
| 真件是否被动过 | **没有**：发布目录 / `bin/…/native` 两份 `.so` 与记录，sha16 `d567c26f197ec1e3 / d567c26f197ec1e3 / 1fa1cf4ca77dfebc`，size 与 mtime **逐位与侦察记录相同**（见 §6.2） |

---

## 1. 写域清单（本件只写了两个文件）

| 文件 | before sha16 / size / mtime | after sha16 / size / mtime |
|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `fc4c249851fa1d71` ｜ 71,502 B ｜ `2026-09-17 09:42:41.689426719` | **`7bc9364091a28fd4`** ｜ 86,734 B ｜ `2026-09-17 12:27:48.220138554` |
| `build/MilBridge/W25B-report.md`（本文件） | —（新建） | 见最终回复的现场 `sha256sum` |

备份（`cp -p`，纪律 16）：`$HOME/w25b-stage/backup/check-applocal-sync.sh.before`（`fc4c249851fa1d71`，size/mtime 与 before 逐位相同）；
改前的**可执行副本**（正控用）`$HOME/w25b-stage/prev/check-applocal-sync.sh` + 同目录 `applocal-expect.py`。
**没有第三件**：`applocal-expect.py` / `sync-applocal-authority.sh` / `known-red-PC-copies.md` / `ITEMS` 相关件 / `docs/**` / `handoff.md` **全部未动**（`find -newermt` 复核：改动时刻只有本件 + 另两条车道自己的文件）。

### 1.1 改动逐处（8 个 hunk，全部是**加**；`diff` 统计：新增 173 行 / 删除 6 行，删除的 6 行**逐字**如下）

```
< #   总判定：MISMATCH>0 或 DIVERGENT>0 或 RETIRED>0 或 UNEXPECTED>0 或 **AUTH-MISSING>0** ⇒ APPSYNC=MISMATCH + exit 1；
< # 环境：AUTH_ROOT（权威根，默认仓库根）/ SCAN_ROOTS（冒号分隔）
<  "wpfgfx_cor3.so||**不覆盖**：由集成波逐波重建（publish 输出即权威，无跨波稳定的期望 sha）→ 由发布脚本的并排 sha 打印负责"
< echo "计数：OK=$CNT_OK … AUTH-MISSING=$CNT_AUTHMISS"
< elif [ "$CNT_MISMATCH" != 0 ] || … || [ "$CNT_AUTHMISS" != 0 ]; then
<     echo "APPSYNC=MISMATCH（… AUTH-MISSING=$CNT_AUTHMISS —— 见上；本脚本**不改写任何目录**）"; exit 1
```

⇒ **没有任何既有判据被删除或放宽**：6 条删除行全部是"被同名改写的那一行本身"（注释口径行、环境行、`ITEMS` 说明串、摘要行、判定链行、`APPSYNC` 行），每条都在新文本里保留并**只做追加**。
**自检 A–O 的用例体一行未动**（唯一落在 selftest 区段的 hunk 是 `@@ -706,6 +801,75 @@`：它在 `O` 的失败分支之后**插入** `P`，被索引到的 6 行上下文原样保留；`echo "SELFTEST=PASS"; exit 0` 现在是 `:873` 且逐字未变）。

| # | 位置（after 行号） | 动作 |
|---|---|---|
| 1 | `:31-66` | 文件头新增 **⑦** 口径块（判据、两格语义、"为什么独立不进 `ITEMS`"、**射程四条**、沙箱豁免）＋ `:34` 总判定行追加 `或 **BRIDGE-ANCHOR>0 / BRIDGE-NOINFO>0**（⑦）` |
| 2 | `:92-132` | 自检清单新增 **P** 的说明；`:132` 环境行追加 `BRIDGE_REC` |
| 3 | `:145` | `ITEMS` 里 `wpfgfx_cor3.so` 的**说明串**改写（更正"无跨波稳定的期望 sha"这句**只对一半**）—— **`exp` 字段仍是空串，一个字符没动** |
| 4 | `:161-168` | 新计数器定义：`CNT_BRIDGE_ANCHOR=0; CNT_BRIDGE_NOINFO=0`（`:168`） |
| 5 | `:253-316` | 新函数 `bridge_anchor_check()`（`:262` 起、`:312` 止）＋ `BRIDGE_REC` 默认值（`:261`） |
| 6 | `:801-875` | 新自检用例 **P**（5 个子断言：绿 / 两份一起换旧 / 只还原一份 / 整份还原 / 删锚行） |
| 7 | `:880-884` | 调用点：紧跟 `scanrc` 打印之后、`计数：` 摘要之前 ⇒ **`bridge_anchor_check`（`:884`）** |
| 8 | `:886 / :935 / :936` | 摘要格、判定链、`APPSYNC=MISMATCH` 行各追加两格 |

### 1.2 关键 hunk（`diff -u` 原文节选）

```diff
@@ -129,6 +161,11 @@
 CNT_DECLGAP_EQ=0; CNT_DECLGAP_DIFF=0
+# ⑦（`D-A2-r`，W25B 2026-09-17）：桥的**绝对锚**判据（见文件头 ⑦，实现 `bridge_anchor_check()`）。
+#     BRIDGE-ANCHOR  某份桥副本 sha ≠ 发布记录的 `BRIDGE_SO_SHA256`（**只看 sha**，mtime 只进诊断文字）
+#     BRIDGE-NOINFO  记录缺失 / 解析不出 64 位 hex / 本次扫描根内 0 份桥副本（**没测到 ≠ 一致，不许当绿**）
+CNT_BRIDGE_ANCHOR=0; CNT_BRIDGE_NOINFO=0
@@ -216,6 +253,64 @@
+BRIDGE_REC="${BRIDGE_REC:-$REPO/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt}"
+bridge_anchor_check() {
+    … find "$SCAN_ROOTS" -name 'wpfgfx_cor3.so' … sed -n 's/.*BRIDGE_SO_SHA256=\([0-9a-f]\{64\}\).*/\1/p' …
+}
@@ -716,8 +880,11 @@
 printf 'scan() 内部 rc=%s（…）\n' "$scanrc"
+# 【⑦ 调用点（W25B）】必须在下面 `计数：` 摘要行**之前**（否则摘要格恒 0 ⇒ "红了但读不出来"）。
+bridge_anchor_check
@@ -765,8 +932,8 @@
-elif [ … ] || [ "$CNT_AUTHMISS" != 0 ]; then
+elif [ … ] || [ "$CNT_AUTHMISS" != 0 ] || [ "$CNT_BRIDGE_ANCHOR" != 0 ] || [ "$CNT_BRIDGE_NOINFO" != 0 ]; then
```

**行首标签用的是 `ANCHOR-OK` / `ANCHOR-DIFF` / `BRIDGE-NOINFO`，绝不生成 `STALE` / `NEWER-DIFF`** ⇒
`sync-applocal-authority.sh:76-77` 的 `awk` 结构上抓不到它 ⇒ **不进那条 `cp -f` 写路径**（这是方案 B 相对方案 A 的核心理由）。
**实证**：`sync-applocal-authority.sh` 干跑（只读）输出里 `grep -c 'wpfgfx_cor3'` = **0**，rc=0 ⇒ 本判据没有给刷新器造出任何新写目标。

---

## 2. 判据口径（**照主控裁决，未自行改宽**）

1. **只看 sha，不看 mtime/权限**：mtime 只在 `ANCHOR-DIFF` 的诊断括号里出现，措辞逐字写明「**只看 sha ⇒ 红**；"记录过期"与"件被换"都红、本判据不给成因」。
2. **`NOINFO` 不许当绿且必须接进 `rc`**：三条路径（记录整份缺失 / 记录里解析不出 64 位小写 hex / 本次扫描根内 0 份桥副本）都 `CNT_BRIDGE_NOINFO++`，而 `:935` 消费它。
3. **绝不把桥配进 `ITEMS`**（方案 B）：`ITEMS:145` 的 `exp` 仍为空串；因此 `:225` 的 `continue` 行为、`sync` 的 `cp -f` 写路径、`applocal-expect.py` 的 `#EXPECT` 基数、`--list-items` 的对表**全都不受影响**（`--list-items` 实测 `ITEMS_SYNC=YES` rc=0）。
4. **沙箱豁免（自杀式收窄的自称）**：当"本次扫描根内 0 份桥副本"**且**"记录所在的发布目录也不在本次扫描根内"⇒ 印
   `BRIDGE-ANCHOR=SKIPPED …（**收窄 SCAN_ROOTS 会连它一起收窄**）`、**不计数**。理由：`--selftest` 的 17 个既有沙箱都是这个形态，
   若把"0 份副本"一律判 NOINFO，**既有 17 例会被自己的新判据打成假红**（那等于把判据加在了错误的对象上）。
   默认全仓扫描（5 个根含 `$REPO/build`，`.artifacts/**` 在其中）**永远覆盖发布目录** ⇒ 正常路径**永远判定**；
   豁免只对"显式收窄且不含发布目录"的调用生效，且**自称可见**。

---

## 3. `--selftest` 全量读数（要求 2）

命令：`bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh --selftest` ｜ **`rc=0`** ｜ 日志 `$HOME/w25b-stage/selftest.final.log`（sha16 `f33e90c8ae42377c`）

```
SELFTEST_A=PASS SELFTEST_B=PASS SELFTEST_C=PASS SELFTEST_D=PASS SELFTEST_E=PASS SELFTEST_F=PASS
SELFTEST_G=PASS SELFTEST_H=PASS SELFTEST_I=PASS SELFTEST_J=PASS SELFTEST_K=PASS SELFTEST_L=PASS
SELFTEST_L2=PASS SELFTEST_N=PASS SELFTEST_M=PASS SELFTEST_M2=PASS SELFTEST_O=PASS SELFTEST_P=PASS
SELFTEST=PASS
```

**PASS 计数 = 18，FAIL 计数 = 0**（`grep -c 'SELFTEST_[A-Z0-9]*=PASS'`／`…=FAIL`）。
**旧例一条没坏**：`A…O` 逐条 PASS（上表逐例列出）。改前同一命令的基线（`$HOME/w25b-stage/selftest.before.log` `7bbfb381b8d248a9`）也是 17/17 PASS、rc=0 ⇒ **新增 1 例、0 例回退**。

⚠️ **口径更正（我推翻派单书/预登记的一个数）**：派单书写「`--selftest` 现在 **20 例** A…O」，实测
`grep -c 'SELFTEST_[A-Z0-9]*=PASS'` = **17**（改前）、`grep -c '=== 自检'` = **17**；
标签是 `A B C D E F G H I J K L L2 M M2 N O`（`M2` 排在 `N` 之后，`L2`/`M2` 是后缀例）。
⇒ "21 例全 PASS"这个**要求**按实际基数兑现为 **18/18 PASS / 0 FAIL**（17 旧 + 1 新）。

新例 `SELFTEST_P` 的逐字读数：
```
SELFTEST_P=PASS（锚一致 exit=0 绿｜两份一起换旧 exit=1 红[BRIDGE-ANCHOR=2]｜只还原一份 exit=1 红[=1]｜整份还原 exit=0 绿｜记录删锚行 exit=1 红[BRIDGE-NOINFO=1]；判定计数器三趟逐字相同 ⇒ 红**只**来自 ⑦）
```

---

## 4. 新例 P 的判别力（要求 3）——**故意改坏 ⇒ P 红**（成对读数）

做法：把**已落地的新判据件**复制到 `$HOME`（另配一份 `applocal-expect.py`），各做**一处**假修，再跑**同一个** `--selftest`：

| 变体 | 假修（相对落地件的唯一 diff） | 旧例 A–O | **`SELFTEST_P`** | rc |
|---|---|---|---|---|
| 落地件（真修） | — | 17 PASS | **PASS** | 0 |
| **假修 1（锚比较恒真）** `$HOME/w25b-stage/fake1/check-applocal-sync.sh`（`ef03312102231132`） | `:294` `if [ "$asha" = "$want" ]; then` → `if [ -n "$asha" ]; then` | 17 PASS | **`FAIL（rc=0/0/1/0/1/0）`** | 1 |
| **假修 2（`NOINFO` 当绿）** `$HOME/w25b-stage/fake2/check-applocal-sync.sh`（`649f54c513e6a7b0`） | `:935` 判定链里摘掉 `|| [ "$CNT_BRIDGE_NOINFO" != 0 ]` | 17 PASS | **`FAIL（rc=0/1/1/0/0/0）`** | 1 |

**判别力逐条读**：
- 假修 1：`rc2=0` —— 两份副本一起换成别的二进制，由于比较恒真被读成"一致" ⇒ **P 的 `[ "$pRc2" != 0 ]` 断言当场红**。
- 假修 2：`rc5=0` —— 记录里删掉锚行（`BRIDGE-NOINFO=1` 计到了，但判定链不消费它）⇒ **P 的 `[ "$pRc5" != 0 ]` 断言当场红**，正好是"NOINFO 被当绿"这种作弊的指纹。
- 两个假修的**旧例 A–O 全部仍然 PASS** ⇒ 红**定位在新判据上**，不是"改坏了别的东西"。

⚠️ 一处**如实登记的仪噪**：fake1 的**第一次**跑在 `SELFTEST_M2=FAIL（capped=3 ext_write=4 ok=0）` 处停住、没走到 P。
复核后判定为**与另一条车道抢文件的竞态**（不是本件引入）：同一分钟 `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`
mtime `12:30:42`、sha16 由 `476994e35d31a7e1` 变 `7374308a00c55572`（W25A 正在重建），而 `M2` 的判据是"`M` 时刻的整份输出"与"`M2` 时刻现算的 `#SUMMARY`"相比 —— 两次取数之间仓库在变。
**证据**：同一条命令**重跑**即 `SELFTEST_M2=PASS`，且 `SELFTEST_P=FAIL（rc=0/0/1/0/1/0）`（`$HOME/w25b-stage/fake1/ST2.log`）；
真实件在同一时段的两趟全量自检也都 `M2=PASS`。⇒ 这是**既有**的自检脆弱性（`M2` 跨时刻取数），**登记但不属于本件写域**。

---

## 5. 反极性 + 正控（要求 4/5）

**在 `$HOME` 下的"真形态"沙箱里做，一个真件字节都没碰**（派单书硬约束 3）：
`$HOME/w25b-stage/repo` = 完整复刻 7 件权威 + 真桥（`cp -p`）+ 真发布记录（`cp -p`，sha16 `1fa1cf4ca77dfebc`）+ 两份真桥副本 + `.artifacts/bin/.../native` 布局；
`AUTH_ROOT=$HOME/w25b-stage/repo`、`SCAN_ROOTS=$HOME/w25b-stage/repo/build`。**旧桥**现场算 `caf7baf9e67719aa`（4,983,696 B，`$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`）。

| 状态 | 旧件（改前 `fc4c249851fa1d71`，= 正控"退化成原样"） | 新件（`7bc9364091a8fd4`） |
|---|---|---|
| **A**：两份副本 == 记录（今天） | `APPSYNC=PASS` rc=**0** | `APPSYNC=PASS` rc=**0**，`BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`，`ANCHOR-OK` ×2 |
| **B（反极性）**：**两份一起**换成旧桥 | **`APPSYNC=PASS` rc=0 ⇒ `D-A2-r` 现场（静默通过）** | **`APPSYNC=MISMATCH` rc=1**，`BRIDGE-ANCHOR=2 BRIDGE-NOINFO=0`，`ANCHOR-DIFF` ×2 |
| **B′**：只换一份（第二极性） | `APPSYNC=MISMATCH` rc=1（`DIVERGENT=1` 兜底） | `APPSYNC=MISMATCH` rc=1，另 `BRIDGE-ANCHOR=1` |
| **C**：`cp -p` 整份还原 | — | rc=0，**输出与 STATE A 逐字节相同**；`cmp` IDENTICAL |
| **F**：记录整份移走 | `APPSYNC=PASS` rc=0 | rc=1，`BRIDGE-NOINFO=1`（"发布记录**整份不存在**"） |
| **G**：记录里删掉锚行 | — | rc=1，`BRIDGE-NOINFO=1`（"**解析不出** BRIDGE_SO_SHA256"） |
| **H**：两份副本都移走（默认扫描下 0 份） | `APPSYNC=PASS` rc=0 | rc=1，`BRIDGE-NOINFO=1`（"本次扫描根内**一份桥副本都没有**"） |
| **J**：`SCAN_ROOTS` 收窄到空目录 | rc=0 | rc=0，`BRIDGE-ANCHOR=SKIPPED …`（自称、不计数） |

**STATE B 的逐字读数**（新件）：
```
    ANCHOR-DIFF   build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so RECORD d567c26f197ec1e3  ACTUAL caf7baf9e67719aa（诊断：副本不早于记录 76702 秒 —— **只看 sha ⇒ 红**；"记录过期"与"件被换"都红、本判据不给成因）
    ANCHOR-DIFF   build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so RECORD d567c26f197ec1e3  ACTUAL caf7baf9e67719aa（诊断：副本不早于记录 76702 秒 —— **只看 sha ⇒ 红**；"记录过期"与"件被换"都红、本判据不给成因）
    ⇒ 本次枚举到桥副本 2 份：与记录一致 0 份 / **不符 2 份**
计数：OK=4  MISMATCH=0（STALE=0  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=0[DECL-GAP-EQ=0 DECL-GAP-DIFF=0]  DIVERGENT=0  NO-AUTHORITY=0  LIB-COPY=0  SKIP(obj)=0  SKIP(stub)=0  SKIP(ref)=0  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=2  BRIDGE-NOINFO=0
APPSYNC=MISMATCH（… AUTH-MISSING=0 BRIDGE-ANCHOR=2 BRIDGE-NOINFO=0 —— 见上；本脚本**不改写任何目录**）
```

**正控（要求 5，证"红只来自新判据"）三重**：
1. **同一装桩状态换判据**：STATE B 下把判据换成**改前那份**（`$HOME/w25b-stage/prev/check-applocal-sync.sh`，sha16 与 `fc4c249851fa1d71` 逐位相同）
   ⇒ 立刻回到**今天的读数** `APPSYNC=PASS` rc=0。**两份计数行对照**（除新增两格外逐字相同）：
   ```
   旧：计数：OK=4  MISMATCH=0（STALE=0  NEWER-DIFF=0） … RETIRED=0  AUTH-MISSING=0
   新：计数：OK=4  MISMATCH=0（STALE=0  NEWER-DIFF=0） … RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=2  BRIDGE-NOINFO=0
   ```
2. **自检内建**：`SELFTEST_P` 断言 `pLold(P1) == pLold(P2)`（剥掉两格后逐字相同）⇒ 红了也**不许**动别的格子。
3. **真仓零位移**：见 §6.1 的 `diff`（真仓默认扫描下，除 3 处**新增**外**逐行相同**，12 个既有计数器读数全部未变，`rc` 仍为 1）。

**还原证明（逐字节）**：`cp -p` 从 `$HOME/w25b-stage/repo/backup/` 还原 ⇒ 三件 `cmp` **IDENTICAL**，sha16 与 mtime 逐位回到
`d567c26f197ec1e3 / d567c26f197ec1e3 / 1fa1cf4ca77dfebc`（mtime `2026-09-16 15:10:32.340624471 / .546627325`），
且新件的整份输出 `diff A.new.log K.new.log` **无差异**。

---

## 6. 读数表（要求 7）

### 6.1 真仓默认扫描（零位移证据）

```
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh      # rc=1（与改前同）
diff before.log after.log   →  只有 3 处，全部是**新增**：
  ① ITEMS:145 的说明串改写（`exp` 字段未动）
  ② 新的 `--- wpfgfx_cor3.so ★绝对锚判据` 段（6 行）
  ③ 摘要行 / APPSYNC 行各追加 `BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`（＋一行说明）
计数（before）：OK=63 MISMATCH=1(STALE=1) MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 NO-AUTHORITY=39 LIB-COPY=0 SKIP(obj)=7 SKIP(stub)=6 SKIP(ref)=10 RETIRED=0 AUTH-MISSING=0
计数（after） ：……（逐字相同）…… AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
新段逐字：
--- wpfgfx_cor3.so ★绝对锚判据（发布记录 BRIDGE_SO_SHA256；独立只读、不进 ITEMS）
    锚记录 build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt
    锚值 BRIDGE_SO_SHA256=d567c26f197ec1e3（记录 mtime=2026-09-16 15:10:32；**mtime 只作诊断，本判据只看 sha**）
    ANCHOR-OK     …/release_linux-x64/wpfgfx_cor3.so d567c26f197ec1e3（== 发布记录）
    ANCHOR-OK     …/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so d567c26f197ec1e3（== 发布记录）
    ⇒ 本次枚举到桥副本 2 份：与记录一致 2 份 / **不符 0 份**
```
⇒ **§8 停条件 5 未触发**（今天**0 条新红**）。

### 6.2 件与读数

| 项 | 值 |
|---|---|
| lane / 时间 | **W25B** ｜ 2026-09-17 12:25 → 12:35 +0800 |
| kernel / nproc / loadavg | `6.8.0-138-generic` ｜ 3 ｜ 开工 `5.36 1.82 0.76` → 收工 `4.96 4.51 2.67` |
| `MemAvailable` | 开工 3,438,508 kB ｜ 最低 2,890,424 kB ｜ 收工 2,890,424 kB |
| 判据件（唯一写域） | `fc4c249851fa1d71`（778 行 / 71,502 B）→ **`7bc9364091a28fd4`**（945 行 / 86,734 B） |
| 锚记录（**只读**） | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt` ｜ `1fa1cf4ca77dfebc` ｜ 376 B ｜ mtime `2026-09-16 15:10:32.546627325` |
| 桥副本 #1（publish，**只读**） | 同上目录 `wpfgfx_cor3.so` ｜ `d567c26f197ec1e3` ｜ 4,987,840 B ｜ mtime `2026-09-16 15:10:32.340624471` |
| 桥副本 #2（bin/native，**只读**） | `.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so` ｜ `d567c26f197ec1e3` ｜ 4,987,840 B ｜ mtime 同上 |
| 旧桥留档件（沙箱用） | `$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so` ｜ **`caf7baf9e67719aa`** ｜ 4,983,696 B |
| `applocal-expect.py`（未动） | `7becc5266636c405` ｜ `sync-applocal-authority.sh`（未动）`b56a85afd70c2321` |
| 日志留档 | `selftest.before.log` `7bbfb381b8d248a9`｜`default.before.log` `e234b7c299f7d616`｜`default.after.log`｜`selftest.final.log` `f33e90c8ae42377c`｜`A/B/C/D/F/G/H/I/J/K.new.log` + 对应 `.prev.log`（全在 `$HOME/w25b-stage/`） |

⚠️ **期间仓库在被别的车道改**（如实登记）：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` 12:30:42 由 `476994e35d31a7e1` 变 `7374308a00c55572`
（W25A 在重建 `pc`）⇒ 真仓的 `MISMATCH=1/DIVERGENT=1` 等读数在这段时间里**可能随刻变化**。本件所有"零位移"结论都取自**同一分钟内 before/after 两趟**，且 before 泛数（`OK=63 …NO-AUTHORITY=39…`）与 W24D 报告里 `#24` 的读数**逐字相同**。

---

## 7. 射程：这个判据**覆盖不到**什么（要求 6，逐条）

1. **只覆盖 `SCAN_ROOTS` 里 `find -name wpfgfx_cor3.so` 得到的现存副本**。桥今天之所以能被扫到，是因为两份副本**恰好**落在
   `$REPO/build` 下（`build/MilBridge/.artifacts/…`；`SCAN_ROOTS` 含 `$REPO/build` ⇒ `.artifacts/**` **在**范围内，别再抄"`.artifacts` 不在扫描根"这句）。**若桥将被发布到 5 个根之外**，本判据一份也扫不到 ⇒ 只出 `BRIDGE-NOINFO`（**红**，不是绿）。
2. **不是防篡改（integrity）判据**：记录与副本同权限、同在 `.artifacts` 下 ⇒ "**副本 + 记录一起改成同一个旧值**"仍然静默通过。本判据是"**发布状态一致性**"判据。
3. **"记录过期"与"件被换"不可分**（今天没有任何量能区分）⇒ 报红**不给成因**，诊断文字同时列出两种可能。已知**误报来源**：`publish-milbridge.sh:84` 只写记录一侧、**从不**触碰 `.artifacts/bin/…/native/` 那一份（全文 `grep 'bin/MilBridge'` = 0）⇒ "跑了 build 而没跑 publish"会造成 `ANCHOR-DIFF` 但成因是"记录过期"；`run-wpftextdemo.sh:191` 在 `--bridge-identity-selftest` 下 `cp -f`（**不带 `-p`**）还原发布目录那一份也会造成同形态。
4. **`.so.dbg`（5,984,488 B）完全无判据**：记录里只有 `BRIDGE_SO_SHA256`，没有 `BRIDGE_DBG_SHA256`。
5. **源级陈旧不归它管**：`BRIDGE_SRC_FP`（源指纹 vs 现源）由 `run-wpftextdemo.sh` 的 `BRIDGE_SRC_STALE` 与 `close-wave.sh` 管 —— 两层**不重复计数**。
6. **`UNEXPECTED`/`MISSING` 那套期望模型与它无关**：桥不进 `ITEMS`、不进 `applocal-expect.py` ⇒ 它**不会**产生 `MISSING`/`UNEXPECTED`，也**不享受**期望集合的"删除也能报"能力（桥副本**被删**只在"0 份副本"这一格才体现，见 §5 STATE H）。
7. **"桥被删掉一份"**（还剩 1 份且 == 记录）⇒ `ANCHOR-OK` ×1、`BRIDGE-ANCHOR=0` ⇒ **本判据报绿**（"少了一份"不是"内容不对"；这一层由跨副本分组/期望模型管，而桥不在那里）。**这是本件明确的射程缺口，不是漏测。**
8. **沙箱豁免**（§2.4）：调用方显式收窄 `SCAN_ROOTS` 且不含发布目录、0 份副本 ⇒ 自称 `SKIPPED`、不计数 ⇒ 这种调用下本判据**不判**。
9. **未测**：本件**没跑** `--apply`、**没跑** `publish-milbridge.sh`（会跑 `dotnet`，硬禁止）、**没跑** `close-wave.sh`/`verify-all`（别的车道在构建）；`integration-wave.sh` 里的接线位置**未复核**（不在我的写域）。

---

## 8. 我推翻/更正了哪句话（如实登记）

1. **派单书/预登记**「`--selftest` 现 **20 例** A…O」⇒ **实测 17 例**（`grep -c 'SELFTEST_[A-Z0-9]*=PASS'` = 17；段头 `=== 自检` 也是 17）。
   ⇒ "21 例全 PASS"按实际基数兑现为 **18/18 PASS / 0 FAIL**（17 旧 + 新例 `P`）。
2. **侦察 `da2r-plan.md` §6.1**「发布目录（`.artifacts/**`）不在任何 `SCAN_ROOTS`」**自相矛盾且不准**：`SCAN_ROOTS:105` 含 `$REPO/build`，
   而两份桥副本都在 `build/MilBridge/.artifacts/…` 下 ⇒ **今天就在范围内**（W23C 已更正过同一句话，本件复核为**正确**：真正漏扫过的只有 `tools/`）。
   该节想说的"射程缺口"应改写成"**若桥被发布到 5 个根之外**"（本报告 §7.1 已按此措辞）。
3. **侦察 `da2r-plan.md` §3.4 的用例清单**（P 的 5 个子断言）**完全可用**，但"`--selftest` 20 例 A…O"这一数**与 1 同错**。
4. `SELFTEST_M2` 存在**既有竞态**（把"`M` 时刻的整份输出"与"`M2` 时刻现算的 `#SUMMARY`"相比）⇒ 仓库在被改时会**偶发假红**（本件撞到一次，重跑即 PASS）。
   这是**既有**缺陷、**不在本件写域**，登记待裁决。

---

## 9. `NOINFO` 清单

- 未跑 `--apply` / `publish-milbridge.sh` / `close-wave.sh` / `verify-all` ⇒ "落地后这些入口上的行为"**本件未实测**（按代码推定：`publish` 会在 `:107` 打印新摘要行，`close-wave` 只看 `APPSYNC=`，两者的 grep 模式都不受新行影响）。
- 真件（仓内两份桥副本 + 记录）在整个过程中**从未被装桩** ⇒ 反极性的证据全部来自 `$HOME` 沙箱；"真件上装桩"这一趟**未做**（按硬约束 3 属允许但不必需，且会与正在跑的 `close-wave`/构建抢件）。
- `known-red-PC-copies.md` 在读数期间被 W25C 改写 ⇒ 本报告里的 `show_registry` 相关读数**未纳入**（与本判据无关）。
