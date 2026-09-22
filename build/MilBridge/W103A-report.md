# W103A 报告 —— 修仓外 4 处"等 WM"缺陷形态 ＋ 复核被污染的臂结论

车道 `W103A`｜任务 = `D-G89` 后续 / `D-G95` 的落地项 **`TASK-0704`**（4 处全在**仓外**）＋ `D-G95` 处置里点名要做的**臂结论复核**
`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜冻结基线 `#50 1f4189c1257737a9`
开工 `2026-09-22T19:28+08:00`｜**回填前** sha16 = **`66eba7edebe73ec5`**（308 行；先写正文再补此值；最终 sha16 由主控按 `sha256sum | cut -c1-16` 现算）

**一句话结论**：**4 处全修好、两极化全成立**；**没有任何已登记结论受这处缺陷污染**（`REPORT.md` 自己就把那趟标成了"无 WM"）；
**要更正的是"机制归因"，不是结论** —— `REPORT.md:279` 把"WM 没起来"归因于自己的 `xfwm4` 调用形式，真因是**那个分支根本不可达**（§5 草案）。

---

## 0 交付件与哈希（**全部现场现算，无手抄**）

| 件 | before sha16 | after sha16 | 备份（`cp -p`，逐字节比对通过） |
|---|---|---|---|
| `~/w53a/cell.sh` | `9c4f8e5ac6450f3d` | **`e1301e3b274d6dec`** | `~/w103a/backup/cell.sh.orig` |
| `~/w53a/cell2.sh` | `c370b9ca5b8151bb` | **`208a674183825d23`** | `~/w103a/backup/cell2.sh.orig` |
| `~/w76a/bin/ab.sh` | `73cbe4eec668abe6` | **`3ce92b2d8806e3d7`** | `~/w103a/backup/ab.sh.orig` |
| `~/w63a/bin/wm-leg.sh` | `f556c065aa635d53` | **`aec91a0827bd9cfa`** | `~/w103a/backup/wm-leg.sh.orig` |

工具与判据（**复用，未另造**）：`$R/build/MilBridge/tools/wm-awaited.sh` = **`57a852f6948e1c67`**（与任务书一致）；
判据原文 `~/w102a/criteria.md` = `f0cc9ca03fd610aa`；本件判据 `~/w103a/criteria.md` = **`f802068b298cb838`**（**先写，早于任何改动**）。
辅助现场：`~/w103a/legs.sh`（两极化腿驱动）、`~/w103a/logs/`（逐腿原始输出）、`~/w103a/STATUS.md`（逐步留痕）。

**未碰**：`cell3.sh`（已修好的样板）、任何仓内产品件／判据件／四个路由件／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／`AB` 冻结基线／`~/w101a/**`／`~/w102a/**`。
⚠️ 在 `~/w63a/**` 下**只改了 `bin/wm-leg.sh` 一件**（现场机械核：`find ~/w63a -newermt '2026-09-22 19:00' -type f` 只此一行）。

---

## 1 判据（**先写**于 `~/w103a/criteria.md`；此处摘要，逐字见该件）

- **真判据 = 复用 `wm-awaited.sh`**，`C1∧C2∧C3` **三条件全要**（不是三取二；`C1` 单独可被"死 WM 的鬼影"骗过，§3 附了现场成对读数）。
- **失败要大声**：`FAIL`/`NOINFO` 一律非零退出 ＋ 逐条打三条件读数。
- **`--require-reparent` 只在"已知此刻有客户窗"时用**：`cell.sh`/`cell2.sh`/`ab.sh` 的等待行在**应用起窗之前** ⇒ **不加**（加了会让等待永不可能成功）。
- **两极化**：在**无 WM** 的私有 `Xvfb` 上，**修前形态**（从**备份**抽原文跑）应"静默通过"／**修后形态**应"大声失败"，且把 WM 真起起来时判据 `PASS`。
- **`#4 wm-leg.sh` 语义不同**：不是"等"，而是"**先问真判据，不满足才起 WM，再确认真的起来了**"。
  ⚠️ 它是 `set -uo pipefail`（**无 `-e`**）⇒ 必须**显式判 `rc`**；且**修后腿必须让"那段起 WM 的代码"自己跑**，不许我先起好 WM 再跑一条"看起来通过"的腿（否则＝自证）。
- **臂结论复核三态**：**受影响**（成对证据 ＋ 判据依赖 WM 在场）／**不受影响**（判据不依赖 WM，或来源不是这趟）／**`NOINFO`**（拿不出成对证据 ⇒ 如实写不确定）。

---

## 2 四处改动（逐字 diff 摘要）

四处**同一形态**：把 `xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window` 换成 **`wm-awaited.sh` 真判据**，形态**照抄已修好的 `~/w53a/cell3.sh:40-44`**（未自己发明）。
旧谓词的原文一律**作为注释逐字留档**（"加注不覆盖"），⇒ **可执行代码里旧谓词命中 0 处**（`grep -v '^[[:space:]]*#'… | grep -c 'grep -q window'` 四件全 **0**）。`bash -n` 四件全 OK，权限 `711` 全部保持。

### 2.1 `~/w53a/cell.sh:26` → `:26-38`（**等待循环**）
```diff
-  for _ in $(seq 1 40); do xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window && break; sleep 0.25; done
+  # 【`D-G89` 落地 · 车道 W103A · 2026-09-22】**原第 26 行**（恒真判据）逐字为：
+  #     for _ in $(seq 1 40); do xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window && break; sleep 0.25; done
+  #   …（机制注释，逐字记录了 `rc=0` ＋ stdout 失败文案 ＋ `&& break` 的后果）…
+  WM_TOOL="${WMAWAIT_SH:-…/build/MilBridge/tools/wm-awaited.sh}"
+  [ -r "$WM_TOOL" ] || { say "WM_AWAITED=FAIL reason=tool-missing path=$WM_TOOL"; exit 6; }
+  if ! bash "$WM_TOOL" --wait 10 --display "$DISP" >> "$OUT/steps.txt" 2>&1; then
+    say "WM_AWAITED=FAIL reason=wm-not-ready display=$DISP（三条件逐条读数见 steps.txt 尾部）"; exit 6
+  fi
```
语义 = "**起完 WM（第 25 行自起）等它就绪**"；等不到 ⇒ **`exit 6` 大声停**。本件其余逻辑**一行未动**。

### 2.2 `~/w53a/cell2.sh:26` → `:26-38`
**与 2.1 逐字相同**（两件该区域改前逐字相同，改动后仍逐字相同；after sha16 不同是因为两文件其余部分不同）。

### 2.3 `~/w76a/bin/ab.sh:25-27` → `:25-46`（**等待循环 + 非零退出**）
```diff
-    for _ in $(seq 1 40); do
-        xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window && break; sleep 0.25
-    done
+    …（同样的机制注释，逐字留档原 3 行）…
+    WM_TOOL="${WMAWAIT_SH:-…/wm-awaited.sh}"
+    if [ ! -r "$WM_TOOL" ]; then
+        echo "AB=$LABEL WM_AWAITED=FAIL reason=tool-missing path=$WM_TOOL" | tee -a "$OUT/summary.txt" >&2
+        [ -n "$WMPID" ] && kill "$WMPID" 2>/dev/null; [ -n "$XPID" ] && kill "$XPID" 2>/dev/null
+        exit 6
+    fi
+    if ! bash "$WM_TOOL" --wait 10 --display "$D" >"$OUT/wm-awaited.txt" 2>&1; then
+        echo "AB=$LABEL WM_AWAITED=FAIL reason=wm-not-ready display=$D（三条件逐条读数见 $OUT/wm-awaited.txt）" \
+            | tee -a "$OUT/summary.txt" >&2
+        [ -n "$WMPID" ] && kill "$WMPID" 2>/dev/null; [ -n "$XPID" ] && kill "$XPID" 2>/dev/null
+        exit 6
+    fi
```
- ⚠️ **一处有意的加法（如实公告）**：`ab.sh` **原本没有 `trap`**，失败退出会**泄漏**它自己起的 `xfwm4`/`Xvfb`
  ⇒ 我在**新的失败路径**上补了**按 PID 收**（`kill "$WMPID"`/`"$XPID"`），与它文件末尾既有的清理（`:49-51`）同形。
  **这不是判据改动**，是卫生；但它确实是"照抄形态"之外的**一处自主决定**，故点名。
- 日志通道按该件自身风格用 `echo | tee`（它**没有** `cell3.sh` 的 `say()`）——只换通道，**不换判据形态**。

### 2.4 `~/w63a/bin/wm-leg.sh:19-22` → `:19-46`（🔴 **最坏的一处**：反向恒假）
```diff
-if ! DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window; then
-  ( DISPLAY=$D xfwm4 --compositor=off --replace > "$HOME/w63a/logs/xfwm197.log" 2>&1 & echo $! > "$HOME/w63a/xfwm197.pid" )
-  sleep 3
-fi
+  …（机制注释：谓词恒真 ⇒ `!` 恒假 ⇒ **起 WM 分支永远进不去**）…
+if [ ! -r "$WM_TOOL" ]; then
+  say "WM_AWAITED=FAIL reason=tool-missing path=$WM_TOOL"; exit 6
+fi
+if ! bash "$WM_TOOL" --check --display "$D" >> "$WAITLOG" 2>&1; then
+  say "WM_LEG_START display=$D（真判据未 PASS ⇒ 起 xfwm4）"
+  ( DISPLAY=$D xfwm4 --compositor=off --replace > "$HOME/w63a/logs/xfwm197.log" 2>&1 & echo $! > "$HOME/w63a/xfwm197.pid" )
+else
+  say "WM_LEG_REUSE display=$D（真判据已 PASS ⇒ 复用在场 WM，不起新的）"
+fi
+if ! bash "$WM_TOOL" --wait 10 --display "$D" >> "$WAITLOG" 2>&1; then
+  say "WM_AWAITED=FAIL reason=wm-not-ready display=$D（…）⇒ 本趟作废，不许静默继续"
+  exit 6
+fi
+say "WM_AWAITED=PASS display=$D（WM 真的起来了，独立证据见 logs/wm-awaited.log）"
```
- **起 `xfwm4` 那一行逐字保留**（含 pidfile 约定），只把"**什么时候**起"从"恒假的 `if !`"换成"**真判据 `--check` 非零**"，并**补上"起完再确认真起来了"**（原版只有一个 `sleep 3`，**没有任何确认**）。
- `:4` 头部那句"显示 :197 = Xvfb + xfwm4（已核 `_NET_SUPPORTING_WM_CHECK` 在场）"**逐字未动**（它是当时的自述，留档更好）。

---

## 3 两极化（**每处都成对**；私有 `Xvfb :188`，**无 WM**；`HOME` 重定向到沙箱）

**装置纪律**：只跑"从真件里 `sed` 抽出的**真实代码块**"（**绝不整脚本执行** —— 那些脚本后面会去跑 `dotnet`）；
`HOME` 被重定向到 `~/w103a/legs/home_<label>` ⇒ 原形态即便"进了分支"也只会往**沙箱**写 `w63a/xfwm197.pid`／`wm.progress`，
**不会**覆盖 `~/w63a` 的真证据件（那两件的 mtime 是复核结论链的一环）。

### 3.0 基线（无 WM 的 `:188`）
```
xprop rc=0 stdout=[_NET_SUPPORTING_WM_CHECK:  no such atom on any window.]   ← 缺陷根：rc=0 且失败文案在 stdout
grep -q window rc=0   <== 恒真
同刻真判据（应 FAIL rc=1）：WM_AWAITED_WHY verdict=FAIL : C1=no C2=no C3=no
同刻 --wait 3（应 FAIL 且用满预算）：rc=1 elapsed_s=3.13
```
`wm-awaited.sh --selftest` = `cases=11 pass=11 not-as-expected=0 rc=0`。

### 3.1 成对读数表

| # | 件 | **修前形态**（备份原文，无 WM 上跑） | **修后形态**（当前真代码，无 WM 上跑） | 修后·**WM 真起来**（真代码自己起） |
|---|---|---|---|---|
| 1 | `cell.sh` | `rc=0` **`elapsed_s=0.01`** ⇒ 第一次迭代就 `break`（谓词为假本需 40×0.25=10 s） | **仅等待段** `rc=6`、用满 **10.05 s**、`WM_AWAITED=FAIL reason=wm-not-ready` | 整块 `rc=0`、**2.74 s** 内 PASS |
| 2 | `cell2.sh` | `rc=0` **`elapsed_s=0.02`** ⇒ 同上 | `rc=6`、**10.17 s**、同款大声 FAIL | 整块 `rc=0`、**2.79 s** 内 PASS |
| 3 | `ab.sh` | `rc=0` **`elapsed_s=0.03`** ⇒ 同上 | `rc=6`、**10.32 s**、同款大声 FAIL | 整块 `rc=0`、**2.71 s** 内 PASS |
| 4 | `wm-leg.sh` | `rc=0` **`elapsed_s=0.02`** ⇒ **分支没进**（进了会 `sleep 3` ⇒ ≥3 s） | —（该处语义不是"等"，见下） | 整块 `rc=0`、**2.82 s**：`WM_LEG_START`（**分支进了**）→ `WM_AWAITED=PASS` |

**#4 的"没进／进了"是机械证的**（不只是耗时）：
- **修前**：沙箱里 `find … -name xfwm197.pid | wc -l` = **0**（分支进了就会写），`:188` 上 `_NET_SUPPORTING_WM_CHECK` 仍 `no such atom`，无 `xfwm4` 进程。
- **修后**：日志逐字 `LEGSAY WM_LEG_START display=:188（真判据未 PASS ⇒ 起 xfwm4）`（**分支进了**）→ `LEGSAY WM_AWAITED=PASS display=:188`。

### 3.2 WM 独立证据（**不拿三条件自证**）
四处的"修后·WM 真起来"腿都取了同一组证据（以 `wmleg` 腿为例，逐字取自 `~/w103a/logs/leg-wmleg-after-full.txt`）：
```
WM_C1_ATOM_ID   ok=yes id=0x2000ae raw='_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae'
WM_C2_WM_WINDOW ok=yes exists=yes name_ok=yes class_ok=yes name_raw='_NET_WM_NAME(UTF8_STRING) = "Xfwm4"'
WM_C3_EWMH_SET  ok=yes n=78
[root-child 列表] 0x2019ca 0x20196a 0x2000b9 0x2000ae 0x2000ac
[xclock 起后 --require-reparent 末行] WM_AWAITED=PASS c1=yes c2=yes c3=yes c4=yes   ← **重定父**：WM 真的在管事
[无客户窗时同一条] WM_AWAITED=PASS … c4=0；加 --require-reparent ⇒ rc=1   ← 与判据 §2 的边界声明一致
```

### 3.3 附赠成对读数：**"死 WM 鬼影"**（顺手把判据 `§2` 的设计意图证成了）
把 WM 按 PID 杀掉之后、`Xvfb` 还活着的那一刻：
```
root 属性仍在：_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae     ⇒ C1=yes
真判据：WM_C2_WM_WINDOW ok=no exists=no（BadWindow）⇒ WM_AWAITED=FAIL : C1=yes C2=no C3=yes
旧谓词同刻：rc=0（**仍恒真**）⇒ 会说"WM 就绪"
```
⇒ **`C1` 单独不够**（鬼影能骗过它）、**`C2` 是必需的**；这条是判据"三条件全要"的现场正面读数。
⚠️ 有意思的巧合：这个 `0x2000ae` **正是 `D-G89` 条目里引的 `W54A-report.md` §0.4(1)`xfwm4_alive=no` 那个 id ⇒ 同一个 id 在"活的 WM"与"死 WM 鬼影"两种情形下都会出现，**进一步说明"只查 id"不可靠**。

---

## 4 臂结论复核表（**本件最重要的一步**）

### 4.1 那条腿的**用途与判词**（逐字，`文件:行`）
- **用途**（`~/w63a/bin/wm-leg.sh:3-7` 头部逐字）：
  `# W63A · **WM 腿**（用户现场 = 有窗口管理器的会话；本仓教训 D-G64："无 WM 的验收装置` / `#   永远复现不出一整类缺陷"）。`
  `#   显示 :197 = Xvfb 1024x768 + xfwm4（自建，私有）；仪器全关；gdb 用**修好后的**命令文件`
- **判词/进度行**（`:23` 逐字，**就是它把缺陷暴露出来的那一行**）：
  `say "DISPLAY=$D wm=$(DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | head -1) geom=…"`
  ⇒ 产出 `~/w63a/logs/wm.progress:1` = `DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window. geom=1024x768`

### 4.2 逐条"受影响／不受影响 ＋ 依据"

| # | 结论/读数（`文件:行`） | 是否依赖"当时有 WM"？ | 判定 | 依据 |
|---|---|---|---|---|
| 1 | `REPORT.md:275-294` **§3.4 WM 腿**（`W301/W302/W303`：有 WM ＋ 真点击 ＋ 90 s ⇒ **0/2** 复现致命崩溃） | **是**（它就是"有 WM"那一格） | **不受影响** | 三趟取自 **`:198`**，不是被污染的 `:197`；`logs/xfwm198.log` 逐字 `(xfwm4:231209): xfwm4-WARNING **: 11:37:44.004: Failed to connect to session manager…` ⇒ **真有 xfwm4 进程起来了**；`logs/wm198.progress:1` 逐字 `DISPLAY=:198 wm=[_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae]` ⇒ **C1 解出真 id**；`batches.tsv` 三行 `WM198-W3xx` |
| 2 | `REPORT.md:279`（"我第一版写成 `DISPLAY=x xfwm4 --replace`，**WM 没起来**，`W101` 因此是无 WM 的一趟，**已在表里标明**"） | —— | **结论正确、但机制归因错** | 结论（W101 无 WM）**成立**；但真因不是"调用形式"，而是**分支不可达**（见 §5）。⚠️ **这是本件唯一要更正的东西** |
| 3 | `REPORT.md:309-311` §4.1 频率表（`只启动·gdb·**无 WM**·90s = 1（W101）` vs `…**有 WM**… = 1（W301）`／`点击×8·**有 WM** = 2（W302/W303）`） | —— | **不受影响** | 表里**已经把 `W101` 标成"无 WM"**、把 `W301-303` 标成"有 WM" ⇒ **没有把错腿当 WM 腿算** |
| 4 | `REPORT.md:347` §4.3（"14 趟…**含 3 趟有 WM**、2 趟带 8 击点击"） | **是** | **不受影响** | "3 趟有 WM" = `W301/302/303`（`:198`）；`W101` 计入"4 趟 gdb 腿"里的无 WM 那趟 |
| 5 | `REPORT.md:266`（"它 **17/17** 趟都发生（13 趟旧仪器 ＋ `W101`/`W301`/`W302`/`W303`；另有一趟 `W201` 被我自己 `TERM` 截断，**不入账**）"） | **否**（启动期被处理掉的 SIGSEGV 与 WM 在场与否无关：`W101` 无 WM、`W301-303` 有 WM 都有） | **不受影响** | 两组的 `runs.tsv` 行都 `sigs=SIGNO-0=11,`、`frames=3` ⇒ 现象在**两种 WM 条件下都出现** ⇒ 不依赖 WM |
| 6 | `REPORT.md:412-423` §6.2 自伤清单第 8 条（"`set -u` 下引用只作命令前缀的 `BATCH_ID` ⇒ WM 腿在 `W102` 中止｜丢 2 趟（后来重写为 `wm-leg198.sh`）"） | **否** | **不受影响但"不完整"** | `BATCH_ID` 那条**确实成立**（`logs/wmleg.out` 末行逐字 `/home/links-dev/w63a/bin/wm-leg.sh: 行 32: BATCH_ID: 未绑定的变量`；`batches.tsv` **确无** `WM-W101` 行 ⇒ 它死在写表之前）。**但**披露里**没提**"这一趟跑在无 WM 上"（那件事在 §3.4 说了）⇒ 两条披露**分开**在两个地方，建议合并（§5） |
| 7 | `run/W201`（`:197` 第二次 no-WM 样本） | —— | **不受影响（已入账）** | `REPORT.md:266` 明确写了它"被我 `TERM` 截断，不入账"；`run/W201/meta.txt` **确实截断**（无 `TS_END`/`VERDICT`）、`liveness.txt` 只 261 B ⇒ 一致 |
| 8 | `D-G64`（**产品缺陷**：有 WM 时点击全被吞）`KNOWN-DEFECTS.md:2204` | **是**（"必须有 WM 的腿"） | **不受影响** | 该条的现场来自**别的车道**的 `:95`/`:96` 腿（`KNOWN-DEFECTS.md:2484` 引 `C2B1/C2B2` 逐击 `AE = 348243, 0, 0, …`）；**册内 `W63A`（大写口径）仅 2 处命中**：`:2393`（在 **`D-G87`** 条内）、`:2495`（在 **`D-G95`** 条自己的演示块内）—— **`D-G64` 一个字都没引 `W63A`** ⇒ 来源不是这趟 |
| 9 | `D-G66`（点页签崩）／`D-G69`（不能最大化）`KNOWN-DEFECTS.md:2218/2235` | **否** | **不受影响** | 两条的现场分别来自 W59A 等车道；现场核：册内**大写 `W63A` 的 2 处命中（`:2393`/`:2495`）都不在这两条的条目范围内**（`D-G64`/`D-G66`/`D-G69` 三条条目正文里 0 命中） |
| 10 | `D-G87`（判据缺陷：把"日志体积 ≥1 MB"当判别量会漏判）`KNOWN-DEFECTS.md:~2393` 引 `W63A` 的半句 | **否** | **不受影响** | 它引的是 `W63A` 的"`139`＋0 字节 = 原生层"那条，其依据是 **§2.1 签名标定**（7 种故障形状，`bin/calib.sh` 默认 `DISP=:196`，**无 WM**）⇒ 与 WM 腿无关；且 WM 腿三趟是 `rc=124`（不是 139） |
| 11 | `docs/ROUTES.md:290`（`TASK-0203` 叙事引 `W63A run/C101/meta.txt` 写 `DISP=:196`） | **否** | **不受影响** | 该行**正是把 `C101` 当"无 WM 趟"用**的（"`C101` 本是**无 WM** 趟"）；现场核 `run/C101/meta.txt` 逐字 `DISP=:196`、`VERDICT=crash-abort` ⇒ 引用方向与事实一致 |
| 12 | `D-G95` 自身（`KNOWN-DEFECTS.md:2487-2508`） | —— | **不受影响** | 它登记的是**装置缺陷本体**，其现场读数（`wm.progress:1` 那行）**逐字仍成立**（现场核：该文件 mtime `11:37:08`、内容一字未动） |

**⇒ 汇总：12 条里 0 条"受影响"，1 条（#2）"结论对、机制归因错"，1 条（#6）"披露不完整"。**

### 4.3 不确定项（**如实划，不当读数**）
1. ⚠️ **`:198` 那趟 WM 的"存活时点"与"是否在管事"当时没有记录**：`wm198.progress:1` 只有 **C1**（解出真 id）＋ `xfwm198.log` 的真实启动行。
   按判据 §2，**C1 单独可被"死 WM 鬼影"骗过**（§3.3 我现场证过）⇒ 严格口径下"11:38–11:45 那段时间 WM 一直活着并接管客户窗"应记 **`NOINFO`**（**当时没取 C2/C4**，事后无法补 —— `:198` 的 Xvfb 早已不存在）。
   **但这不改变** 4.2 表里"结论取自 `:198` 而非被污染的 `:197`"这一判断（后者是来源归属问题，前者是"有 WM"这句话的强度问题）。
2. `~/w63a/xfwm197.pid`／`xfwm197.log` 的 mtime 是 `00:24:02`／`00:24:03`（**早于** 11:35）⇒ 那是**更早一版**留下的。
   **读数升级（比 W102A 的"推断"进一步）**：`logs/xfwm197.log` 逐字
   `(xfwm4:222215): xfwm4-WARNING **: 00:24:03.085: Failed to connect to session manager: …`
   ⇒ 这是一条**真实的 xfwm4 启动日志**（带它自己的 PID 222215 与时刻）⇒ **可机械证"00:24 那一版确实执行了起 WM 的调用"**。
   ⚠️ **但**它**不能**证"当时那个**谓词**是对的"（更早一版可能压根不带条件就起 WM）⇒「当时判据是好的」**仍是 `NOINFO`**。
3. 我**没有**那一版的脚本原文（`~/w63a/**` 里没有旧副本、`~/w63a` 不是 git 仓库）⇒ **无法复算**。

### 4.4 一条"差点被误判成受影响"的自伤（诚实记）
我第一次跑"修后·整块"腿时，`wmleg` 那格**看起来**给出了 `C2=no`（`BadWindow`）⇒ **乍看像"那趟 WM 是鬼影"**。
查明后：那是我**上一条腿（`ab.sh`）把 WM 杀掉后留在 root 上的鬼影**，而 `wmleg` 腿当时**因为我自己路径写错**（`wmleg_after.txt` vs `run_leg` 约定的 `*_after_full.txt`）**根本没跑真代码**（`BLOCK_RC=1`）。
⇒ 结论：**那不是我发现的证据，是我的装置噪声**；把 `:188` 重启成干净无 WM 后重跑，`wmleg` 腿才给出 `WM_LEG_START` ＋ `C2=yes`。
**教训**：`C2=no` 这种"看着很有说服力的红"必须先问"是不是我自己的装置造成的"。

---

## 5 更正待办草案（**交主控另派；本件不改册、不改别人的报告**）

### 5.1 【建议 · 必做】更正 `~/w63a/REPORT.md:278-279` 的**机制归因**（**结论不动**）
- **现状逐字**（`:278-279`）：`配方：env DISPLAY=:198 xfwm4 --display=:198 --compositor=off（我第一版写成` / `DISPLAY=x xfwm4 --replace，**WM 没起来**，W101 因此是无 WM 的一趟，已在表里标明）`。
- **要改成**（建议逐字）：把"**WM 没起来**"的**原因**从"调用形式写错"改为"**`bin/wm-leg.sh:19` 的恒真谓词反用 ⇒ 那个起 WM 的分支从未执行**"，
  并注明 **11:35 那趟根本没调用过 `xfwm4`**（机械证：`logs/xfwm197.log` mtime 停在 `00:24:03` ⇒ `>` 重定向未发生；本件 `~/w103a/backup/wm-leg.sh.orig` 的块级复现 = 沙箱里 `xfwm197.pid` **0 命中**、无 WM 进程）。
- **为什么值得改**：这是 `D-G95` 的**要害**——"**静默跑错腿**"（而不是"调用失败"）才是这处缺陷的性质；**照错的归因去修，会去改 `xfwm4` 的调用形式而放过那个恒真谓词**。
- **顺带**：把 §6.2 第 8 条的披露与 §3.4 的"无 WM"披露**合并引用**（现在两处各说一半）。
- ⚠️ **要不要动**：`REPORT.md` 在 `~/w63a`（**仓外**）且**不在本件写域**（我的写域只含那 4 个脚本 + 我的报告）⇒ **我只能给草案**。

### 5.2 【建议 · 可选】`D-G95` 的 `NOINFO` 项可据此收口
`D-G95`（`KNOWN-DEFECTS.md:2507`）写着"**还要复核**它那趟'WM 腿'的判词是否已影响任何已登记结论 ⇒ **若影响**，相关结论须按'无 WM 口径'重取或降级为 `NOINFO`"。
**本件读数 = 不影响**（§4.2 逐条 12/12），⇒ 该分支**不需要**重取／降级；建议在 `D-G95` 追加一条"复核结论：不受影响，依据 = `W103A-report.md` §4"。

### 5.3 【建议 · 新登记一物】`wm-leg.sh` **每次运行都会截断自己的进度日志**（⇒ 重跑即毁证）
- 判定点：`~/w63a/bin/wm-leg.sh:12-13`（**逐字未改**，本件只改了 `:19-22`）：
  `: > "$PROG"` —— 而 `D-G95` 引用的**唯一现场证据**就是 `$PROG`（`logs/wm.progress:1`）那一行。
- ⇒ **任何"修好后重跑一遍"都会当场抹掉该证据**（这正是我 §7 选择**不端到端跑**它的硬理由）。
- 建议修法：`PROG` 改为**追加**或**带时间戳归档**（`wm.progress.$(date +%s)`），并**先把历史那行另行留档**。
- 同类：`bin/wm-leg198.sh:12` 也是 `: > "$PROG"`（它已经这么截断过一次 `wm198.progress`）。
- **性质**：与 `D-G93`/`D-G95` 同族（"装置自己把证据弄没"）⇒ 建议**新取一个号**或并入 `D-G95` 的 bullet（**由主控裁**）。

### 5.4 其余同类写法
- 本件只盘了任务书点名的 4 处 ＋ §3 报告里点到的。**仓外是否还有同款"恒真谓词"未逐处枚举** ⇒ 记 `NOINFO`（W102A 盘到"仓内 0 处、仓外 5 处"，其中 1 处已修、**本件修掉剩下 4 处** ⇒ 就 W102A 的盘点口径而言**已清零**）。

---

## 6 作废趟 / `NOINFO` / 自伤清单

**自伤（全部留痕，逐条改正）**
| # | 事故 | 代价 | 处置 |
|---|---|---|---|
| 1 | `ab` 腿的 harness prelude **漏了 `D`**（`ab.sh` 用 `$D`，真脚本 `:9` `D=:97`）⇒ `set -u` 报 `D: 未绑定的变量`，该腿 `rc=1` | 该腿读数作废 | 补 `D="$DISP"`，重跑 ⇒ `rc=6`、`10.32 s` ✔ |
| 2 | `wmleg` 的抽取文件名写成 `wmleg_after.txt`，而 `run_leg` 取 `*_after_full.txt` ⇒ `source` 失败（`BLOCK_RC=1`） | 该腿读数作废（且**制造了 §4.4 的误判**） | 改文件名，重跑 ⇒ `WM_LEG_START`＋PASS ✔ |
| 3 | `--evidence` 最初在**起 `xclock` 之前**就判 `--require-reparent` ⇒ 恒 `rc=1`（那一刻无客户窗） | 该读数无意义 | 改为"先记无客户窗的 `rc=1`（与判据 §2 边界一致）→ 再起 `xclock` → 再判 ⇒ `c4=yes`" ✔ |
| 4 | `wmleg` 腿第一次跑完**泄漏了一个 `xfwm4`**（原因：该处起 WM 用的是**嵌套子 shell**，不设 `WMPID`，我 harness 的 trap 无可收） | 泄漏 1 个进程 | 核 `/proc/<pid>/environ` 确认 `DISPLAY=:188` 且 `HOME=…/home_wmleg_after_full`（是我的）⇒ **按 PID** 杀掉 ✔（**未用 `pkill -f`**） |
| 5 | 上述泄漏的 WM 死掉后**留下鬼影属性**，被我误读成"证据" | 一次误判 | 重启干净 `:188` 重跑；鬼影**另作 §3.3 的正面读数**用 ✔ |

**`NOINFO`**
1. `:198` 那趟的 **C2/C4 当时未记录** ⇒ "那一刻 WM 活着并管事"严格记 `NOINFO`（§4.3-1）。
2. "当时（00:24 那版）**判据**是好的" ⇒ **仍是 `NOINFO`**（只能证"分支被执行过"，§4.3-2）。
3. 仓外同类写法**是否已彻底清零** ⇒ 只就 W102A 的盘点口径而言清零，**未独立重盘**。
4. 4 处**未端到端跑真脚本**（理由见 §7）。

**未做 / 选择不做**
- **可选第 4 步（端到端跑 4 个修后脚本）**：槽当时**可用**（`no dotnet running`、`MemAvailable=2684 MB`），
  **但仍不做**，硬理由 = §5.3（`wm-leg.sh` 会截断 `D-G95` 的证据行）；另同机 **W101A** 在做整波重建 ⇒ 按纪律让路。
  等价覆盖 = §3 的**块级腿**（跑的就是真代码那几行）。
- 未改 `handoff.md`／`CURRENT-STATE.md`／`KNOWN-DEFECTS.md`／`docs/ROUTES.md`（**均不在本件写域**；`D-G95` 的收口与 §5 的更正**交主控**）。

---

## 7 收工现场（按 PID 收，**零 `pkill -f`**）
- 杀掉：`Xvfb :188`（`3005935`）、我起的 `xfwm4`（`3006163`）、`xclock`×4（各腿内 `kill`）。
- 收工 `pgrep -a Xvfb` 只剩**别人的** `:97`（`2415049`）／`:99`（`2394341`）；`pgrep -a xfwm4` 只剩**用户会话** `646945`；`/tmp/.X11-unix` 里 `X188` 已消失。
- 全程未碰 `:0/:1/:10/:95/:96/:97/:99`（也未碰别人当时在用的 `:183`）。
- 收工时现场另起了 **`:185`（`Xvfb` PID `3009682` ＋ `xfwm4 --display=:185` PID `3009724`）** —— **那是别的车道起的，不是我**（我的号全程只用 `:188`，且已收干净、socket 消失）⇒ **原样留着，未碰**。

---

## 10 【本报告自身的更正】加注不覆盖

1. **`W63A` 在册命中数写错并已订正**：初稿在 §4.2 第 8 行与 §8 写成"**3 处**（`:2393`/`:2495`/`:2502`）"——**错**。
   现场重算（`grep -c 'W63A' samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）= **2**；且 `:2502` 那行**并不含大写 `W63A`**（它写的是"那一趟**自称"WM 腿"**…"）。
   真值：**`:2393` 属 `D-G87` 条、`:2495` 属 `D-G95` 条**（各自条目起始行现场核过：`D-G87@2390`、`D-G95@2487`）。
   **判断的实质结论未变**：`D-G64`（`@2204`）／`D-G66`（`@2218`）／`D-G69`（`@2235`）三条条目正文里 **0 处** `W63A` 引用 ⇒ "来源不是这趟"仍成立。
2. **口径说明**：上条用**大写** `W63A` 计数；若用小写 `w63a`（文件路径 `/home/links-dev/w63a/…`）则会多出若干命中（主要落在 `D-G95` 条内），
   两者**不是同一个口径**，引用者请指名。本报告的两处数字**均按大写口径**并已标明。

---

## 8 复算命令（逐条可跑）
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 0) 本报告自身哈希（回填用）
sha256sum $R/build/MilBridge/W103A-report.md | cut -c1-16
# 1) 四处 after 哈希 + 语法 + 权限（应全 711、bash -n rc=0）
for f in ~/w53a/cell.sh ~/w53a/cell2.sh ~/w76a/bin/ab.sh ~/w63a/bin/wm-leg.sh; do
  bash -n "$f" && printf '%s perm=%s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c %a "$f")" "$f"; done
# 2) 可执行代码里旧谓词命中必须为 0（原文只在注释里）
for f in ~/w53a/cell.sh ~/w53a/cell2.sh ~/w76a/bin/ab.sh ~/w63a/bin/wm-leg.sh; do
  grep -v '^[[:space:]]*#' "$f" | grep -c 'grep -q window'; done
# 3) 工具自检（应 cases=11 pass=11 rc=0）
bash $R/build/MilBridge/tools/wm-awaited.sh --selftest | tail -2
# 4) 两极化重放（需先起私有 Xvfb :188，收工按 PID 杀）
#    bash ~/w103a/legs.sh baseline        # 缺陷根 + 真判据 FAIL + 用满预算
#    bash ~/w103a/legs.sh orig            # 修前形态：4 处全 rc=0 秒回（wmleg 分支没进）
#    bash ~/w103a/legs.sh after_waitonly  # 修后仅等待段：全 rc=6 大声失败
#    bash ~/w103a/legs.sh after_full      # 修后整块：真代码自己起 WM ⇒ PASS + 独立证据
# 5) 复核用到的决策性读数（逐字重取）
grep -n '我第一版写成' ~/w63a/REPORT.md                  # :278-279 机制归因（待更正）
sed -n '308,311p;347p;266p' ~/w63a/REPORT.md            # §4.1 表 / §4.3 / W201 入账
grep -c 'W63A' $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md   # 2（:2393 在 D-G87 内、:2495 在 D-G95 内；D-G64/66/69 未引用）
stat -c '%y %n' ~/w63a/logs/xfwm197.log ~/w63a/logs/wm.progress  # 00:24:03 / 11:37:08（证据未动）
```

---

## 9 大白话小结（≤7 行）

1. **4 处仓外的"等 WM"都修好了**：三处是"等了个寂寞"（谓词恒真 ⇒ 秒回），一处更坏 —— `wm-leg.sh` 把同一个恒真谓词用在 `if !` 上，于是"起 WM"那段代码**从来没执行过**。
2. **两极化都成立**：同一条无 WM 的屏上，旧形态一律"秒回通过"（0.01–0.03 秒），新形态一律**当场大声非零退出**；真代码自己把 WM 起起来后，判据 `PASS`，并另有"窗口被重定父"这一条独立证据证明 **WM 真的在管事**。
3. **被污染的那趟臂，没污染到任何已登记结论**：那趟（`:197`）只出了 1 个样本，而 W63A 自己就在报告里把 `W101` 标成"**无 WM**"，WM 的结论全部取自另一条真的起了 WM 的腿（`:198`）。
4. `D-G64`／`D-G66`／`D-G69` 的册内条目**一个字都没引 W63A**；`ROUTES.md` 引 `C101` 是**当"无 WM 趟"用**的 ⇒ 都不受影响。
5. **但要改的不是结论、是"原因"**：报告把"WM 没起来"说成"我 `xfwm4` 调用形式写错了"，真因是**那个分支根本不可达** —— 照错的归因去修，会去改调用形式而**放过那个恒真谓词**。
6. **顺手抓到一件新的**：`wm-leg.sh` 每跑一次都会**截断**自己的进度日志，而 `D-G95` 引用的证据就在里面 ⇒ **重跑即毁证**（这也是我**没有**端到端重跑它的硬理由）。
7. **我没做到的**：`:198` 那趟"WM 当时一直活着"只有 C1 ＋ 真实启动日志、没取 C2/C4 ⇒ 该子项记 `NOINFO`；00:24 那版脚本原文找不到 ⇒ 「当时判据是好的」仍是推断；4 处未端到端跑真脚本（让路 + 避免毁证）。
