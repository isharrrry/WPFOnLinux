# `#26` 车道 **W26B** 报告 —— `D-G10` 落地：把"绿的时候判了什么"印到屏上

> lane=**W26B**｜2026-09-17 **14:00:26 → 14:2x +0800**｜kernel `6.8.0-138-generic`｜`nproc=3`
> `MemAvailable` 开工 **3,289,344 kB** / 收工 **3,004,580 kB**｜`SwapFree` 收工时 429,836 kB（他车道在跑）
> `loadavg` 开工 `0.75 0.31 0.51` → 收工 `6.59 4.93 2.90`（**他车道并发**：W26A 构建、W26D 改 `known-red.json`）
> **零 `dotnet`**：本车道一次都没跑（含"会自行构建的步骤脚本" —— 见 §12 的机制说明）
> 写域 = `verify-all.sh` + `build/MilBridge/tools/frame-step.sh`（**其余一个字节未动**，§11.3）

---

## §0 结论（结论在前）

1. **`D-G10` 已落地**：`verify-all.sh` 的 `run_step` 现在**绿的时候也会在屏上留下一行「自报口径」**（行 `:104`），红的时候多了**零命中兜底**（`:121-124`）与**被拷走的日志路径**（`:129`）。三颗牙齿的口径行**不需要动牙齿**（`pc-line-step.sh`/`baseline-sha-check.sh` **逐字节未动**，`:103`/`:62-64,:76` 早就在自报）。
2. **`frame-step.sh` 的终局行不再是"一个数字都没有"**：新增 1 行逐腿累加器（`:154`，`set -u` 下用 `${LEGSUM:-}` 就地初始化）＋三条终局**逐腿口径**行（`:204`/`:207`/`:210`，**新键 `FRAME_STEP_LEGS`**，全仓占用 **0** 处）。**改前的终局 `FRAME_STEP=PASS …` 行逐字节未动**（只加不删）。
3. **只加不删（机器证）**：`verify-all.sh` 287→316 行、`frame-step.sh` 195→212 行，**改前独有行 = 0 / 0**；两者 `bash -n` 通过。
4. **反极性成对拿到**：① **真红可见**（`baseline-sha-check` 真红 / `tline-gate --logdir` 真漏报兜底 / 归档真红 frame-step 重放）；② **绿的时候 0 误报**（真绿日志上失败 grep 0 命中、绿回显只印 `=PASS` 形态行）。
5. **现成的真漏报例已复现并治好**：`bash build/MilBridge/tools/tline-gate.sh --logdir`（缺参数）⇒ `rc=3`、旧 grep **0 命中** ⇒ 改前屏上除 `❌` 一字皆无；改后兜底打出 `| NOINFO --logdir 缺参数` + 日志路径。
6. **判据语义零改动**：`rc` 判定、`pass/fail` 计数、`failed_items` 一字未动；同一驱动壳下**改前/改后 13 个用例的 通过/失败 完全相同**（`6/5` vs `6/5`）。
7. **位移**：九位 9/9 与 `inputs_fp` **逐位未动**（§11.1）。**但有两处"口径文字"必须由主控在波尾同步**（§11.2：文档里声明的 `verify-all.sh` sha16 已过期、脚本头注释仍写 12 步）。

---

## §1 改了什么（两个文件；sha16 / 行数 / 关键 hunk）

| 文件 | 改前 sha16 | 改后 sha16 | 行数 | 字节 |
|---|---|---|---|---|
| `verify-all.sh` | `741b638acaf02e7a` | **`ff961780c130734b`** | 287 → **316**（+29） | 17608 → **21005** |
| `build/MilBridge/tools/frame-step.sh` | `37f27df68e52bf8c` | **`a8800cd897606cf7`** | 195 → **212**（+17） | 12429 → **14490** |

mtime：`verify-all.sh` 2026-09-17 14:07:21；`frame-step.sh` 2026-09-17 14:08:47。备份（`cp -p`）在 `~/w26b-backups/{verify-all.sh.orig,frame-step.sh.orig}`（sha16 与上表"改前"逐位相同，已现场核对）。

### 1.1 `verify-all.sh` 关键 hunk（`diff -u`，**只有 `+` 行**）

```diff
@@ -88,6 +88,19 @@   ← 绿分支：内层 fi 之后、外层 else 之前
     else
       printf '  %-28s %s\n' "$name" "✅"
     fi
+    # ── 【`#26` W26B 落地 · `D-G10`：**绿的时候也要在屏上留下"这一步判了什么"**（只加不删）】──────
+    #   ⚠️ 缺口**不在牙齿**：三颗牙齿今天就在自报 …… （逐字见文件）
+    #   ⚠️ 模式**锚定行首**且只认 `PASS|FAIL|NOINFO` 三种**结论值** ……
+    #   ⚠️ 位置在**内层 `fi` 之后、外层 `else` 之前**（改前行号 `:90` / `:91`）……
+    #   ⚠️ 本行**只读 `$log`、只 `echo`**：不碰 `rc`/`pass`/`fail`/`failed_items` ⇒ **判据语义零改动**。
+    grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' "$log" | head -8 | sed 's/^/      · 自报口径 /'
   else
@@ -97,7 +110,22 @@   ← 红分支：宽 grep 之后（零命中兜底）／cp 之后（日志路径）
     grep -E "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)" "$log" | head -12 | sed 's/^/      /'
+    # ── 【`#26` W26B 落地 · **零命中兜底**（只加不删）】……（含实测真例 tline-gate.sh:99）
+    if ! grep -qE "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)" "$log"; then
+      echo "      ⚠️ 诊断 grep 零命中（本步既没自报 KEY=FAIL/NOINFO、也没报编译器错）⇒ 兜底打日志末 12 行："
+      tail -12 "$log" | sed 's/^/      | /'
+    fi
     cp "$log" "/tmp/verify-all-$(echo "$name" | tr -c 'A-Za-z0-9' '_').log"
+    # ── 【`#26` W26B 落地 · 把被拷走的日志路径印上屏（只加不删）】……
+    echo "      完整日志：/tmp/verify-all-$(echo "$name" | tr -c 'A-Za-z0-9' '_').log"
   fi
```

插入点行号（**改后**现件，现场 `grep -n` 读出）：绿回显 `:104`；红分支兜底 `if` `:121`、兜底 `echo` `:122`、`tail -12` `:123`、`fi` `:124`；日志路径 `:129`。`run_step` 现为 `:61`–`:132`。

### 1.2 `frame-step.sh` 关键 hunk

```diff
@@ -144,6 +144,10 @@
     echo "FRAME_STEP 腿 $TAG 机读 判定行=$JR 红行=$RH 帧红=$FR 结构红=$ST 仪器族NOINFO=$NI 结构族NOINFO=$NS 自洽=$OK probe_rc=$PRC"
+    # ── 【`#26` W26B · **逐腿累加器**（1 行；`set -u` ⇒ 用 `${LEGSUM:-}` 就地初始化）】……
+    TN="$(num "$SUM" 真值非零行)"
+    LEGSUM="${LEGSUM:-}${LEGSUM:+, }$TAG[判定行=$JR 红行=$RH 帧红=$FR 结构红=$ST 仪器族NOINFO=$NI 结构族NOINFO=$NS 自洽=$OK 真值非零行=${TN:-NA}]"
 
@@ -187,9 +191,18 @@
 case "$DEC" in
     0) echo "FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1"   ← **逐字节未动**
+       # ── 【`#26` W26B · 终局**逐腿口径**行（只加不删）】……
+       echo "FRAME_STEP_LEGS=PASS 逐腿口径：${LEGSUM:- 无}｜结构族红汇总（未登记、本步不判）：${STRUCT_IDS:- 无}｜pc=$PC_AT_START"
        exit 0 ;;
     1) echo "FRAME_STEP=FAIL 见上面逐腿点名（帧红≠0 或 仪器族NOINFO≠0 或 恒绿退化）"
+       echo "FRAME_STEP_LEGS=FAIL 逐腿已解析口径：${LEGSUM:- 无}"
        exit 1 ;;
     *) echo "FRAME_STEP=NOINFO 见上面逐腿原因（算不出 ⇒ **不是通过**）"
+       echo "FRAME_STEP_LEGS=NOINFO 逐腿已解析口径：${LEGSUM:- 无}"
        exit 2 ;;
```

改后行号：分母字段 `:153`、累加器 `:154`、`FRAME_STEP_LEGS=` 三条 `:204`/`:207`/`:210`。
**为什么是"新键 + 新行"而不是改那一行**：① 预登记 §4 要求**只加不删**（改写终局行 = 删一行）；② 保持终局 `FRAME_STEP=PASS` 行的**文本逐字节不动**（改前 `:189` ⇒ 改后 `:197`，只因本件在它上方插了行；`sed -n '197p'` 与改前 `sed -n '189p'` **逐字节相同**）⇒ 文档/报告里所有引用该行**文本**的文字（`W25C-report.md:86`、`known-red-frame-structural.md:57`、`ACCEPTANCE-BASELINE.md:19` 等）**仍然成立**；③ 两条结论行由**同一个 `case "$DEC"` 分支**打印 ⇒ **结构上不可能互相矛盾**。
⚠️ **行号会漂**：本件在 `:145-153`、`:191-196` 处插行 ⇒ 改后终局三行在 `:197`/`:206`/`:209`（**引用行号前请现场 `grep -n`**，这是本工程反复踩过的陈旧口径族）。
`FRAME_STEP_LEGS` 全仓占用 **0** 处（`grep -rl -- 'FRAME_STEP_LEGS' .` ⇒ 0 个文件）；且现场核对**没有任何脚本解析 `frame-step.sh` 的 stdout**（只有报告/文档引述），故新键**无消费者冲突**。

---

## §2 只加不删的机器证 + 语法

```
comm -23 <(sort 改前) <(sort 改后) | wc -l
  verify-all.sh                    改前独有行 = 0      改后新增行 = 28（去重后；行数 +29 含空行）
  build/MilBridge/tools/frame-step.sh  改前独有行 = 0      改后新增行 = 13（去重后；行数 +17 含空行）
bash -n verify-all.sh                                  → rc=0
bash -n build/MilBridge/tools/frame-step.sh            → rc=0
```
（行数口径：`verify-all.sh` 287→316、`frame-step.sh` 195→212；"去重后新增行"比行差小，因为新增的注释块含重复的 `#`/空行形态。**关键量是"改前独有行 = 0"**。）

---

## §3 `--selftest` 不受影响

```
$ bash build/MilBridge/tools/baseline-sha-check.sh --selftest      # 改后
SELFTEST case=A expect=PASS    got=PASS     rc=0 => yes
SELFTEST case=B expect=FAIL    got=FAIL     rc=1 => yes
SELFTEST case=C expect=NOINFO  got=NOINFO   rc=1 => yes
SELFTEST case=D expect=GENFAIL got=gen:FAIL rc=1 => yes
SELFTEST case=E expect=GENFAIL got=gen:FAIL rc=1 => yes
SELFTEST case=F expect=DUPFAIL got:dup:FAIL rc=1 => yes
BSC_SELFTEST=PASS cases=6 pass=6 fail=0
rc=0
```
（该文件 `sha256sum` = `5836b8296b2e4245` **未变** ⇒ 6/6 是"没被我碰过"的复算，不是"改后仍绿"的强命题 —— 如实标注。）

---

## §4 反极性（成对；**真 `run_step` 驱动，零 dotnet**）

### 4.1 驱动方式（可复核，不是手写仿真）

* `~/w26b-run/harness.sh new|orig`：从**两个版本的 `verify-all.sh`** 里用 `awk '/^parse_counts\(\) \{/,/^\}$/'` 与 `awk '/^run_step\(\) \{/,/^\}$/'` **机械抽出**函数原文（改前抽出 51 行 / sha16 `fdeee01c51b9f038`；改后 80 行 / `2e9a961b5a3ac7c9`），`source` 后**调用真函数**。
* ⚠️ 驱动壳里 `dotnet` 被替换成一个只往 stderr 打印的**影子函数** ⇒ **机制上不可能启动真 dotnet**（本壳的用例也都不含 `dotnet`，影子是双保险）。**没有跑 `verify-all.sh`**，只调它的 `run_step`。
* 读数：`~/w26b-run/harness-orig.out`（改前）、`~/w26b-run/harness-new.out`（改后）。两趟**通过/失败完全相同**（`通过 6  失败 5`）⇒ **判据语义未变**。

### 4.2 ① 真红必须可见（成对）

| 用例 | 驱动 | 改前屏上 | 改后屏上 |
|---|---|---|---|
| **R1** `BASELINE 声明扰动一位`（**真跑**，纯 bash；`BSC_STATE` 指向 `$HOME` 里的副本，现场 pair 未碰） | `baseline-sha-check.sh` → `rc=1` | `❌ (rc=1)` + 1 行 `BASELINESHA=FAIL live=1b4f7473b89d5cfa decl=0b4f7473b89d5cfa` | 同上 **+ `完整日志：/tmp/verify-all-R1_real_red_sha_.log`** |
| **R2** `删掉机器声明行 ⇒ NOINFO`（**真跑**） | `baseline-sha-check.sh` → `rc=1` | `❌ (rc=1)` + 3 行 `BASELINESHA=NOINFO …`/`BASELINEGEN=NOINFO …` | 同上 **+ 日志路径** |
| **R3** ⭐**真漏报例**（见 §5） | `tline-gate.sh --logdir` → `rc=3` | `❌ (rc=3)`，**除它一个字都没有** | `❌ (rc=3)` + **`⚠️ 诊断 grep 零命中…` + `| NOINFO --logdir 缺参数` + 日志路径** |
| **R4** 归档**真红** frame-step stdout 重放（`neg-degen.out` + 新口径行；`rc` 用 `exit 1` 复现） | `rc=1` | 5 行（`FRAME_STEP=FAIL 腿 … 判定行=0 ⇒ 恒绿退化`×3 + 终局 FAIL 行） | **同样的 5 行 + 新的 `FRAME_STEP_LEGS=FAIL …` 被既有失败 grep 直接命中** + 日志路径 |
| **R5** `rc=127` 且**零输出**（极端形态） | `bash -c 'exit 127'` → `rc=127` | `❌ (rc=127)`，一字皆无 | `⚠️ 诊断 grep 零命中…`（日志为空 ⇒ 无尾巴可打）**+ 日志路径** |

⇒ **兜底把 R3/R5 这一类"死在打印结论之前"的步从"屏上只有 ❌"变成"屏上有原文 + 有日志路径"**。（R5 的残留：**零输出时兜底无内容可打**，只能给路径 —— 这是该类问题的物理下限，如实记。）

### 4.3 ② 绿的时候 0 误报（成对）

| 用例 | 驱动（**改后**绿分支会印什么） | 改前 | 改后 |
|---|---|---|---|
| **G1** **真跑** `baseline-sha-check.sh`（纯 bash，`rc=0`） | 3 行 `BASELINESHA=PASS …`/`BASELINEGEN=PASS …`/`BASELINEDUP=PASS …` | `✅`（0 行口径） | `✅` + **3 行口径** |
| **G2** **真跑** `verify-cmd-layout.py`（纯 python3，`rc=0`，`~/w26b-run/real-green-cmdlayout.out`） | 0 行（该步本来就没有机器口径行 —— 如实记） | `✅` | `✅`（**没有**凭空造口径） |
| **G3** 归档**真绿** frame-step stdout 重放（W24B 10:24，`~/w24b-run/frame-step-final.out`） | 1 行 `FRAME_STEP=PASS 三条腿…`（**改前的日志当然没有新行**） | `✅` | `✅` + **1 行口径** |
| **G4** 按 `pc-line-step.sh:103` 模板 + **真探针计数器**重建的终局行 | 1 行 `PCLINE_START_STEP=PASS Start 列 红=0 绿=421 判定行=421 NOINFO=0` | `✅` | `✅` + **1 行口径**（**首次把 `红=0 绿=421 判定行=421` 印到屏上**） |
| **G5** 合成"改后 frame-step 终局两行"（数值 = 我新代码在真日志上的**真输出**，见 §8） | `FRAME_STEP=PASS …` + **`FRAME_STEP_LEGS=PASS 逐腿口径：strict[…真值非零行=133], lenient[…133], strict+prefix40[…421]…pc=7374308a00c55572`** | `✅` | `✅` + **2 行口径** |
| **G6** ⭐**诱饵**：绿日志里**故意**塞 `ARM_DIAG=NOINFO …` / `SPAWN_DIAG=FAIL …`（合成） | 三值模式**会把这两行也回显**（标 `· 自报口径`） | `✅` | `✅` + 3 行（其中 2 行非 PASS） |

**"绿的时候 0 误报"的机器证**：① 在**全部真绿用例（G1–G5）**上，绿分支回显的**非 `=PASS` 形态行 = 0**；② 失败 grep 在**真绿日志上 0 命中**（真跑 `baseline-sha-check` 0、真跑 `verify-cmd-layout` 0、归档真绿 frame-step 0，见 §6.2 的三份真日志）；③ 绿分支的 grep **不参与任何 rc 计算**（只 `echo`）。
⚠️ **G6 是唯一一个能"让 NOINFO/FAIL 出现在绿屏上"的形态**，而且它**不是**真步骤产生的 —— 详见 §6.3（含"要不要改成只印 `=PASS`"的两种加固写法，**由主控裁定**；我按预登记 §4 的 `=(PASS|FAIL|NOINFO)` 原文照做）。

---

## §5 一个**真实的漏报例**（现成、已复现、已治好）

```
$ cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
$ bash build/MilBridge/tools/tline-gate.sh --logdir            # 缺参数（verify-all 第 [4] 步的脚本）
NOINFO --logdir 缺参数
$ echo $?
3
```
* 该行来自 `build/MilBridge/tools/tline-gate.sh:99`：`--logdir) [ $# -ge 2 ] || { echo "NOINFO --logdir 缺参数" >&2; exit 3; }` —— 它**走 stderr** 且**不含 `=`** ⇒ 旧失败 grep（`:99` 那条宽 grep，pattern 要求 `KEY=FAIL|NOINFO`）**0 命中**。
* 完整日志（`run_step` 侧）只有 **26 B**，就是那一行（`~/w26b-run/real-red-tlinegate-noarg.out`）。
* **成对读数**（§4.2 R3）：改前屏上只有 `❌ (rc=3)`；改后屏上 = `⚠️ 诊断 grep 零命中…` + `| NOINFO --logdir 缺参数` + `完整日志：/tmp/verify-all-R3_real_miss_tlinegate_.log`。
* 为什么这条重要：`#24` 那次"没有 dotnet 的 PATH ⇒ 8 步全 `rc=127`"的事故（`verify-all.sh:26-31` 注释记载）**正是同一个形态** —— 死在打印任何结论之前。零命中兜底就是给这一族准备的。

---

## §6 尖锐问题：**全 13 步里有没有 `=NOINFO` 却 `rc=0`？**

### 6.1 逐脚本行号映射（凡引行号均现场读过）

| 步 | 脚本/命令 | `NOINFO` 的自报点 → 退出码 | `FAIL` 的自报点 → 退出码 | 结论形态行 |
|---|---|---|---|---|
| `[1]`×2 | `dotnet build` | 无自报机制（MSBuild 输出） | — | 归档真 build 日志命中 **0**（§6.2） |
| `[2]`×6 | `dotnet test` | 无自报机制（VSTest 汇总 = `已通过! - 失败: 0，…`/`Passed! - Failed: 0…`，`parse_counts` 用的正是它） | — | 三份**归档真 test 日志**命中 **0**（§6.2） |
| `[3]` | `verify-cmd-layout.py` | `sys.exit(2)`（`:79` 未知类型宽度） | `sys.exit(1)`（差异） | 真跑命中 **0** |
| `[4]` | `tline-gate.sh` | `:647` `verdict,rc="NOINFO",NOINFO`（`:622`）⇒ `sys.exit(rc)` `:675` | 同处 `"FAIL",FAIL` | 唯一结论行 = `TLINE_GATE=`（`:647`；`GATE_REASON=` 的值不是三态 ⇒ 不匹配） |
| `[5]` | `pc-line-step.sh` | `:50 :59 :63 :74 :86` 各 `echo PCLINE_START_STEP=NOINFO … ; exit 2` | `:90 :94 :98` 各 `exit 1` | `:103` `=PASS … exit 0` |
| `[6]` | `frame-step.sh` | `case "$DEC"` 的 `*)` ⇒ `exit 2`（`DEC=2` 只在 `:133 :143 :151` 置位） | `case` 的 `1)` ⇒ `exit 1` | `:197` `=PASS`（改前 `:189`；`DEC=0` 时唯一） |
| `[7]` | `baseline-sha-check.sh` | `:30 :31 :39 :46` ⇒ `return 1`（`:79` 只在三项全 PASS 时 `return 0`） | `:49`（`BASELINESHA=FAIL`）、`:74`（`BASELINEDUP=FAIL`）⇒ `return 1` | 3 行（`BASELINESHA=`/`BASELINEGEN=`/`BASELINEDUP=`；`BASELINE_BYTES=` 值是数字 ⇒ 不匹配） |

**读法**：**每一处 `KEY=NOINFO` / `KEY=FAIL` 的打印路径，其同一个分支都必然以非零码结束** —— 三态与 `rc` 是**同一个判定**的两个出口，不存在"印了 NOINFO 却 rc=0"的路径。

### 6.2 真日志上的机器证

| 真日志 | 绿回显形态命中 | 失败 grep 命中 |
|---|---|---|
| `~/w26b-run/real-green-baseline.out`（**今天真跑**，rc=0） | 3（**全 `=PASS`**） | 0 |
| `~/w26b-run/real-green-cmdlayout.out`（**今天真跑**，rc=0） | 0 | 0 |
| `~/w24b-run/frame-step-final.out`（归档**真绿** frame-step，rc=0） | 1（`=PASS`） | 0 |
| `~/wfp-runs/w16-pre/seqf-3-WpfGfx.Linux.Commands.Tests.log`（归档真 `dotnet test`） | 0 | 0 |
| `~/wfp-runs/w15-pre/managedlayer-isolated.log`（归档真 `dotnet test`） | 0 | 0 |
| `~/wfp-runs/w25-gate1-build.log`（归档真 `dotnet build`） | 0 | 0 |
| `/tmp/frame-step/{strict,lenient,strict+prefix40}.log`（**真探针**日志，13:29–13:36） | 0（探针只打 `FRAMEPROBE …`） | 0 |
| `~/wfp-runs/w25-verify13b.out`（**13 步全绿的屏输出**） | 0（口径 0 行 —— 这正是本件的缺口） | 0 |

⇒ **答案：今天不存在**（13 步 × 9 个"步脚本/真日志"证据）。**新回显不会把 `NOINFO` 误读成失败**：它只是**原样回显**，既不置 `fail`、也不加进 `failed_items`、更**不会**把三态合并成第四态（§7）。
**但**：如果**将来**某步 `rc=0` 却自报 `KEY=NOINFO`，那个 `NOINFO` 会**出现在绿屏上**（G6 的实测形态）。按本工程"`NOINFO` **不许当绿**、但也不该冒充红"的规矩，我把它**如实回显、不隐藏**（它正是"静默绿"唯一的可见形态），并在 §6.3 给出两种"只印 `=PASS`"的加固写法供主控裁定。

### 6.3 可选加固（**未落地**；预登记 §4 的原模式是 `=(PASS|FAIL|NOINFO)`，我照做）

```bash
# 变体甲（绿分支只印 PASS 形态行；最贴"绿步的回显只许印 =PASS 形态的结论行"）
grep -E '^[A-Z][A-Z0-9_]*=PASS( |$)' "$log" | head -8 | sed 's/^/      · 自报口径 /'
# 变体乙（口径仍印 PASS；另把非 PASS 行当**异常**单独点名 —— 两边都不放过）
grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' "$log" | head -8 | sed 's/^/      · 自报口径 /'
grep -E '^[A-Z][A-Z0-9_]*=(FAIL|NOINFO)( |$)' "$log" | head -3 \
  | sed 's/^/      · ⚠️ 本步 rc=0 却自报非 PASS 结论行（rc 不改，但请人看一眼）： /'
```
**成本**：两者都只是 `grep|head|sed`，不改任何 rc（§7）；**今天在真日志上，两者的输出与现况逐字节相同**（因为非 PASS 行 = 0 条）。⇒ 纯属"未来防御"，我**没有**擅自加（避免超出登记改动面）。

---

## §7 判据语义零改动（机器证）

* `diff -u` 显示两个文件的改动**全是 `+` 行**（§1）：`rc` 的判定（`:67-79` 重试循环、`:81` 的 `if [ $rc -eq 0 ]`、`:91` 的 `else`）、`pass/fail` 计数（`:82 :92`）、`failed_items`（`:93`）**一字未动**。
* **行为证**：同一个驱动壳（§4.1）下，**改前/改后 11 个用例的逐例 `通过/失败` 完全相同**，汇总同为 `通过 6  失败 5`，失败项集合同为 `R1 R2 R3 R4 R5`。
* **没有第四态**：新代码里出现的三态**全部来自既有变量**（`$DEC`、`$LEGSUM` 旁边没有新的判定）；`NOINFO` 与 `FAIL` **没有合并**（`frame-step` 的 `case "$DEC"` 仍是 3 个分支）。
* 绿分支的两条新命令**不产生任何被后续读取的值**（无命令替换被赋值）⇒ 不可能影响后续逻辑。

---

## §8 `frame-step` 逐腿累加器：真值 + 阳性对照 + "假数"对照

驱动：`~/w26b-run/acc-test.sh`（纯 bash）。它把**改后**文件里的新代码行**机械抽出**（`grep -F`），用 **13:29–13:36 那趟真探针日志**（`/tmp/frame-step/*.log`，由 `#25` 波尾 `verify-all` 第 `[6]` 步产生，日志自报 `被测件…sha16=7374308a00c55572`）里的**真计数器**驱动。输出留档 `~/w26b-run/acc-test.out`。

**真值输出（我新代码的真输出，不是手写）**：
```
FRAME_STEP_LEGS=PASS 逐腿口径：strict[判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 真值非零行=133], lenient[判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 真值非零行=133], strict+prefix40[判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 真值非零行=421]｜结构族红汇总（未登记、本步不判）： strict:3 lenient:3 strict+prefix40:3｜pc=7374308a00c55572
```
* 三腿在**这 7 个字段上数值全同**（`421/3/0/3/0/101/1`）—— 三腿真正的差异在**分母**：`真值非零行` **133 / 133 / 421**。我因此把这**既有字段**（同一条 `汇总` 行里的 `真值非零行=`）并进口径行（`:153` 抽出、`:154` 累加）⇒ 屏上直接看出"**prefix40 那条腿的分母是 421、与另两条不可直接比列**"（正是文件头 ③ 那条口径警告）。**代价**：多 1 行抽取代码，**已披露**。
* **阳性对照**（证明"累加"不是"覆盖"）：用互不相同的合成值（`11/22/33 …`）驱动同一行累加器 ⇒ `legA[判定行=11 …], legB[判定行=22 …], legC[判定行=33 …]`，**判定行去重后 = 3**。
* **"假数"对照**（预登记 §4 警告的形态）：若直接读循环后置变量 `JR/FR` ⇒ 只剩最后一腿那套（`判定行=33 帧红=0 真值非零行=9`），**与三段带 tag 的累加结果形态上可区分**。
* `set -u`：累加器用 `${LEGSUM:-}${LEGSUM:+, }` **就地初始化**（**不需要**另起一行 `LEGSUM=`）；三条终局行用 `${LEGSUM:- 无}`/`${TN:-NA}` ⇒ 无未绑定变量风险。（`bash -n` 通过；`acc-test.sh` 在 `set -u` 下真跑过。）

---

## §9 波尾那趟 `verify-all` 的屏上会多出什么（逐步预期 + 出处）

| 步 | 绿时会新增的屏上行 | 出处/证据 |
|---|---|---|
| `[1]`×2 | （无） | 真 build 日志 0 命中（§6.2） |
| `[2]`×6 | （无） | 真 test 日志 0 命中；`Total:` 计数行照旧印（计数逻辑未动） |
| `[3]` | （无） | 今天真跑 0 命中 |
| `[4]` | `· 自报口径 TLINE_GATE=PASS arms=5 red=… green=… noinfo_arm=0 … generation=#NN tree_gen=same …` | **代码读法**（`:647` 唯一结论行；**无归档 stdout ⇒ 未实测**，见 §13） |
| `[5]` | `· 自报口径 PCLINE_START_STEP=PASS Start 列 红=0 绿=421 判定行=421 NOINFO=0` | G4（真探针计数器 + `:103` 模板重建） |
| `[6]` | `· 自报口径 FRAME_STEP=PASS 三条腿…` **+** `· 自报口径 FRAME_STEP_LEGS=PASS 逐腿口径：…｜pc=…` | G5（我新代码在真日志上的真输出） |
| `[7]` | `· 自报口径 BASELINESHA=PASS live=… decl=…` / `BASELINEGEN=PASS …` / `BASELINEDUP=PASS n=0` | G1（**今天真跑**） |

---

## §10 成本

| 项 | 值 |
|---|---|
| 新增进程 | 绿分支每步 1×`grep`+`head`+`sed`；红分支 1×`grep`（仅在**已失败**的步上） |
| 实测耗时 | 在**本仓最大真步骤日志**（170,620 B）上 10 次绿分支 grep = **37 ms** ⇒ **≈4 ms/步** |
| 输出量 | 每步 ≤8 行（`head -8`）⇒ 13 步最多 +约 12 行 |
| `rc`/既有读法 | **不变**（§7）；`frame-step.sh` 终局 `FRAME_STEP=PASS` 行的**文本**逐字节未动（改前 `:189` → 改后 `:197`）⇒ 引用它的文档仍然成立 |
| 时间预算 | 不涉及 `dotnet`/harness ⇒ 对 `verify-all` 的**总时长影响 ≈ 0**（第 `[6]` 步的 428 s 与第 `[4]` 步的门禁重扫不受影响） |

---

## §11 位移 / 并发 / 必须由主控补的两处"口径文字"

### 11.1 位移：**无**

```
inputs_fp  开工 0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8
           收工 0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8   ← 逐位相同
九位       开工/收工逐位相同：bridge=d567c26f197ec1e3  pc=7374308a00c55572  pf=eb48655d697a4188
           windowsbase=1114a28ec5a03ab7  provider=9aa0d744802aaa31  win32shim=0098234982391bbf
           wic_shim=03b67fbcd7c385b6  hbtextline=e89fed55fd8e32bc  dwf=0ed422ef2dd46445
```
（与预登记 §2 一致：本件只改两个 shell 文件，两者都**不在** `fp_inputs()` 的覆盖面内 —— 它的 find 集合是 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`/`build/shims/**/*.cs`/`src/WpfGfx.Linux/**/*.cs`，`close-wave.sh:73-78` 现场读过。）
基线声明仍在：`docs/CURRENT-STATE.md:6` = `> BASELINE-FROZEN gen=#25 sha16=1b4f7473b89d5cfa file=…`，第 `[7]` 步**今天真跑仍 PASS**（§6.2 第一行）。

### 11.2 ⚠️ 两处必须由主控同步的"口径文字"（我**没有**擅自改）

1. **文档里声明的 `verify-all.sh` sha16 已过期**（这类声明在本工程是"活的"，且有 `BASELINEDUP` 那样的反重复牙齿盯着）：
   * `docs/CURRENT-STATE.md:35`：`verify-all.sh 279b958dda238447 → 0d268f4f0bb441c3 → 741b638acaf02e7a` ← **本件把它换成了 `ff961780c130734b`（`#26` W26B，步数仍 13）**
   * `handoff.md:2840`：同一句 sha 链
   * `docs/WAVE24-PREREGISTRATION.md:428`：`verify-all.sh 0d268f4f0bb441c3 → 741b638acaf02e7a`（归档文件，按 `BASELINEDUP` 的口径**不在射程**，可不动）
   * `build/MilBridge/W25C-report.md:58/301` 记的是 `frame-step.sh 37f27df68e52bf8c`（报告是归档，不必改；**但如果波尾有人拿它当"当前件"就会误导**）
   ⇒ 建议波尾在 `CURRENT-STATE.md` 与 `handoff.md` 各补一句：`verify-all.sh ff961780c130734b（#26 W26B：run_step 绿分支口径回显 + 零命中兜底 + 日志路径）`、`frame-step.sh a8800cd897606cf7（#26 W26B：FRAME_STEP_LEGS 逐腿口径行）`。
2. **`verify-all.sh` 的头注释仍写"12 步"**（第 `:7` 行 `#24 起 = 12 步`、`:8` 行只列到第 12 步），而现件是 **13 步**（`:304` 的 `BASELINE-SHA` 是第 `[7]` 步；`:285` 那段注释自己写着"12 → 13"）。这是 `#24` 后期加步时**没跟进头注释**留下的陈旧口径。
   **我按"只做登记的事"没动它**（预登记 §4 把 W26B 的改动面逐条列清；头注释属**主控的文档同步**）。若主控要改，`verify-all.sh` 只有我能写 ⇒ 请派回或授权，**逐字补丁**（纯新增 1 行，插在 `:9` 之后）：
   ```
   #   （本行 `#26` W26B 更正：上两行未跟进第 `[7]` 步 —— **`#24` 后期起 = 13 步**，第 13 步 = `BASELINE-SHA`；见下方 `:285` 那段注释。）
   ```

### 11.3 我不许碰的文件：逐字节未动（现场 sha16）

| 文件 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/tools/pc-line-step.sh` | `fa62842d8e211b07` | 与任务书给出的现件值一致 |
| `build/MilBridge/tools/baseline-sha-check.sh` | `5836b8296b2e4245` | 同上 |
| `build/MilBridge/run.sh` | `3e513e88a4fa4ec9` | — |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `1b4f7473b89d5cfa` | **与 `CURRENT-STATE.md:6` 的声明逐位相同**（基线未动） |
| `docs/CURRENT-STATE.md` | `91b2f4e861f0cf69` | **他人在 14:10:32 改过**（我 14:04 读到的是 `d470e4a7103a9846`）⇒ 见下 |
| `build/MilBridge/known-red.json` | `5aead470c23a99ff` | **W26D 并发在改**；我从未写它 |
| `build/MilBridge/tests/CoverageProbe/Program.cs` | `f3a797f44fcd10f4` | **W26A 并发在改**；我从未写它 |
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `e12831d315839120` | W26C 的写域；未动 |

⚠️ **并发披露（纪律 35 的同族）**：`docs/CURRENT-STATE.md` 在我 14:04 的第一次 `baseline-sha-check` 读数**之后**（14:10:32）被改动 ⇒ 我**重取**了该读数：两趟 rc=0 且输出**逐字节相同**（`~/w26b-run/real-green-baseline.out` 与 `real-green-baseline2.out` sha16 都是 `75844a5475c60f75`），`BASELINE-FROZEN` 机器行未变 ⇒ 本件结论不依赖那次改动。

---

## §12 "零 `dotnet`"的落实

* 本车道跑过的**全部**命令：读文件 / `grep` / `sed` / `awk` / `sha256sum` / `stat` / `comm` / `mktemp` / `cp` / `python3 verify-cmd-layout.py`（纯 python，脚本内 `sys.exit`，无写文件）/ `bash baseline-sha-check.sh`（纯 bash，只读）/ `bash tline-gate.sh --logdir`（**缺参数 ⇒ 在 `:99` 参数解析处 `exit 3`**，**早于**任何 `mkdir`/python/探针，**不产生任何文件**）。
* **没有跑** `verify-all.sh`（含抽取出来的真 `run_step`，见 §4.1）、**没有跑** `frame-step.sh` / `pc-line-step.sh`（任务书点名禁止的"会自行构建的步骤脚本"）、**没有跑** `close-wave.sh`。
* 驱动壳里 `dotnet` 被替换为影子函数 ⇒ 即使有人误触发重试分支也**不会**启动真 dotnet。收工前按 PID 复查：无属于本车道的 `dotnet`/MSBuild 进程（仅作辅助观察，**未**用 `pgrep -f`/`ps|grep` 下结论）。

---

## §13 `NOINFO` 清单（**我算不出来 / 没实测**的格子）

1. `[4]` `tline-gate.sh` 的**绿屏形态**：**没有归档 stdout**（门禁的 stdout 从不落盘，`run_step:100` 只在失败时 `cp`）⇒ §9 那一行是**代码读法**（`:647`），**未实测**。⇒ 建议波尾那趟 `verify-all` 顺手把它的口径行抄进报告。
2. `frame-step.sh` **改后终局两行**的**端到端真跑**：本件**禁止**跑该脚本 ⇒ `FRAME_STEP_LEGS=PASS` 的真输出是**用真计数器驱动新代码**得到的（§8），**不是**整脚本跑出来的。⇒ 波尾 `verify-all` 会给端到端读数。
3. `R5`（`rc=127` + **零输出**）：兜底**无内容可打**，只能给日志路径 —— 该形态的物理下限，**如实记**。
4. **真红 `frame-step` 的正极性读数**（即"改后脚本真红一次"）：同 2，未跑；用的是 W24B 的归档真红 stdout 重放。
5. `known-red.json` / `CoverageProbe/Program.cs` 的**当前**内容与 `#26` 其它车道的一致性：不属本件写域、且**正被 W26A/W26D 并发改**⇒ 本件不依赖它们（我的判据不读它们）。

---

## §14 读数表（artifact + 字段 + sha16 + 环境）

| 项 | 值 |
|---|---|
| lane / 时间 | `W26B`｜2026-09-17 14:00:26 → 14:2x +0800 |
| kernel / nproc | `6.8.0-138-generic` / 3 |
| `MemAvailable` 开工 / 收工 | 3,289,344 / 3,004,580 kB（本件不跑构建，全程无内存压力） |
| `loadavg` 开工 / 收工 | `0.75 0.31 0.51` / `6.59 4.93 2.90`（他车道并发所致） |
| 交付件 | `verify-all.sh` `ff961780c130734b`（21,005 B / 316 行）｜`build/MilBridge/tools/frame-step.sh` `a8800cd897606cf7`（14,490 B / 212 行） |
| 备份 | `~/w26b-backups/verify-all.sh.orig` `741b638acaf02e7a`｜`frame-step.sh.orig` `37f27df68e52bf8c` |
| 驱动壳 | `~/w26b-run/harness.sh`（抽出文本 `funcs-orig.sh` `fdeee01c51b9f038` / `funcs-new.sh` `2e9a961b5a3ac7c9`） |
| 读数留档 | `harness-orig.out`（改前）/ `harness-new.out`（改后）/ `acc-test.out` / `real-green-baseline{,2}.out` / `real-green-cmdlayout.out` / `real-red-tlinegate-noarg.out` / `selftest-after.out` |
| 真日志来源 | `/tmp/frame-step/{strict,lenient,strict+prefix40}.log`（13:31/13:34/13:36，pc=`7374308a00c55572`）｜`/tmp/pc-line-start-step.out`（13:29）｜`~/w24b-run/frame-step-final.out`（10:24）｜`~/w24b-run/neg-degen.out`｜`~/wfp-runs/w16-pre/*.log`、`w15-pre/*.log`、`w25-gate1-build.log` |
| 改动面 | `verify-all.sh` +29 行 / `frame-step.sh` +17 行，**全部为新增** |

---

## §15 留给主控的动作（按建议顺序）

1. **波尾跑 `verify-all`（13 步）** ⇒ 它现在会把 §9 那批口径行印到屏上；请把 `[4]`/`[6]` 两格的真读数补进 `#26` 的收官记录（本件 §13 标了 NOINFO）。
2. **同步 §11.2 的两处口径文字**（`CURRENT-STATE.md:35`、`handoff.md:2840` 的 `verify-all.sh`/`frame-step.sh` sha16；`verify-all.sh:7-8` 的"12 步"陈旧头注释 —— 后者只有我能写，需要时派回给我或授权）。
3. **裁定 §6.3 的可选加固**是否要落地（今天在真日志上与现况逐字节相同）。
4. `§13` 的 NOINFO 格子如需实测，请在允许"真跑步骤脚本"的波次里补。
