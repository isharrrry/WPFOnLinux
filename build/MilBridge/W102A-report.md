# W102A 报告 —— `TASK-0703`：修掉"等 WM 起来"的恒真判定（`D-G89` 落地）＋ 全仓同类写法盘点

车道 `W102A`｜`2026-09-22 19:13 → 19:26 (+0800)`｜kernel `6.8.0-138-generic`｜`nproc=3`｜loadavg `0.97~1.10`
仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜冻结基线 `#50 1f4189c1257737a9`（`verify-all` 26 步／`gen=#50`）
**零 `dotnet`／零构建／零产品应用**；只起私有 `Xvfb :186`/`:187`/`:188` ＋ `xfwm4` ＋ `xclock`（**全部按 PID 收干净**）。

---

## §0 结论速览（先看这里）

1. **两极化成立（三条读数齐）**：无 WM 腿 —— 旧谓词 **`rc=0`（恒真）** vs 新判据 **`FAIL rc=1`**；有 WM 腿 —— 新判据 **`PASS rc=0`**（`id=0x4000ae`／`_NET_SUPPORTED n=78`／**重定父独立证据**）；时序腿 —— 同一个 `--wait` 在无 WM 时 **`FAIL rc=1 elapsed_s=4.12`（用满预算）**、等待中起 WM 后 **`PASS rc=0 elapsed_s=0.58`**（原子独立计时 `0.27 s`）。
2. **改了 2 件**：新建 `build/MilBridge/tools/wm-awaited.sh`（**`57a852f6948e1c67`**，`--selftest` **11/11 PASS `rc=0`**）＋ `~/w53a/cell3.sh`（**`06c6d17fa9906761` → `a358f6fd38b3b387`**，只换掉那一行恒真谓词）。
3. ⚠️ **任务书里的路径 `build/MilBridge/W53A/cell3.sh` 在全机不存在**（该目录**从来不在仓里**，`git ls-files` 只有 `W53A-report.md`）⇒ 真身 = **仓外** `~/w53a/cell3.sh:26`（全机 `find` 只有这一份）。我按**真身**改（`cp -p` 备份在 `~/w102a/cell3.sh.before-W102A`），**没有**在仓内新造一个副本（两处必然分叉）。
4. **`fp_inputs` 判定：本件贡献 = 零**（机械证：覆盖面 **147 件**里本件两件**命中 0**）。**收尾实测**：指纹两遍相同且 **`== #50` 冻结值 `ee543f44b1090c74…`**（连测三遍稳定）。
   ⚠️ **中途有一次偏离，必须记清（读数带时刻）**：`19:26` 那次量到的是 **`c138491c…`**（≠ 冻结值），当时覆盖面里最新两件是 `src/WpfGfx.Linux.Native/src/win32_core.c`（`19:20:26`）与 `win32_internal.h`（`19:20:03`），**正是车道 W101A（`TASK-0108`）的写域**；`19:29` 再量已回到 `ee543f44…`，而那两件的 mtime 也回到 `09-21 23:13:03`/`23:06:13` ⇒ **W101A 把它那两处实验性改动按 `cp -p` 口径还原了**（仓内纪律：实验装置类改动事后还原）。⇒ **归因始终不是我**，而且**收尾态与 `#50` 冻结值逐位相同**（见 §7）。
5. **同类写法：仓内脚本 0 处**（仓内该原子只出现在**报告/文档/产品代码/产物**里）；**仓外还有 4 处未修**（`~/w53a/cell.sh:26`／`cell2.sh:26`／`~/w76a/bin/ab.sh:26`／`~/w63a/bin/wm-leg.sh:19`）。其中 `w63a` 那处是**更坏的变体**：同一个恒真谓词用在 `if !` 上 ⇒ **分支永远进不去** ⇒ 该"WM 腿"**永远不会自己起 WM**（见 §8.3，**建议另派**）。
6. **一处真实现场假阴性**（既有工件，非我造）：`~/w53a/logs/C-wm-splash/marks.txt:2` 逐字 `WMPROOF … no such atom on any window.`，而**同一格** `trees.txt` 里 `0x2000ae "Xfwm4"` 在场、且应用窗 `0x200004 "HandyControlDemo"` 被装进框架 `0x400264`（基线坐标 `+245+241` ≠ root）⇒ **WM 真在管事，自证行却说"不在"**。

---

## §1 判据（**先写** · 早于任何改动）

判据原文 = `~/w102a/criteria.md`（**`f0cc9ca03fd610aa`**，`9,352 B`）。写它的时刻 **早于** `wm-awaited.sh` 的创建与 `cell3.sh` 的任何编辑。逐字摘录：

| 代号 | 条件 | 机读形式 |
|---|---|---|
| `C1 ATOM_ID` | root 上 `_NET_SUPPORTING_WM_CHECK` **能解析出窗口 id** | 匹配 `window id # 0x…` 且 **≠ `0x0`** |
| `C2 WM_WINDOW_LIVE` | 该 id **此刻真的存在**，且 WM 自己可读 | `xwininfo -id <id>` **成功** ∧（`_NET_WM_NAME` ∨ `WM_CLASS`）**可读非空** |
| `C3 EWMH_SET` | root 上 `_NET_SUPPORTED` **非空** | 首个 `= ` 之后**按逗号数非空项 ≥1** |
| `C4 REPARENT`（**默认只报不判**） | 存在**被重定父的顶层客户窗** | 某 root 子窗的**子窗**有非空 `WM_CLASS` |

**判决**：`PASS` ⇔ `C1∧C2∧C3`（`--require-reparent` 时再 ∧ `C4>0`）；X 服务器问不到 ⇒ **`NOINFO`**（既不算绿也不算红）；`rc` 三态 `PASS=0／FAIL=1／NOINFO=2`。**失败要大声**：非零退出 ＋ 逐条打三条件实测读数。

**为什么"三个全要"而不是"三取二"**（判据 §2，依据是**既有留档**而非我这次的读数）：
`C1` 单独可为"**死 WM 的鬼影**" —— `build/MilBridge/W54A-report.md` §0.4(1) 与 `~/w53a/logs/WFP3-wm-killwm/report.txt:9` 都记着 `xfwm4_alive=no` 而 root 上**仍留着** `window id # 0x…`。
**为什么 `C4` 默认不判**：本行在**应用起窗之前**（`cell3.sh` 第 4x 行才起应用）⇒ 那一刻**必然没有客户窗**，判进去会让等待**永不可能成功**。

**判据的两处更正（`criteria.md` §5，加注不覆盖）**：
- **`C3` 的解析形状我写错了**：原写"≥1 个 `0x…` 原子"，而真 `xfwm4` 打的是**原子名**（见 §4 逐字原文）⇒ 按十六进制计数**在真机上恒为 0**，真 WM 也会被判 `FAIL`。意图（"`_NET_SUPPORTED` 非空"）不变，只改解析形状，**两种形状都认**。（我的 fixture 恰好用了十六进制形状 ⇒ **自测 11 例全绿而现场全红**；已补 `S9` 专测原子名形状。）
- 补充口径：`--wait N` **每一拍**重跑三条件（不是"等够了再看一次"）。

---

## §2 缺陷本体（`D-G89`）的**现场复现**：先量清"旧谓词到底怎么坏的"

装置：`~/w102a/old-predicate.sh`（`9bf0b155abebbacc`），在**同一个私有 `:186`（无 WM）**上逐项量。逐字读数（`~/w102a/logs/legs-20260922-191931/leg-R.txt`）：

```
XPROP_RAW rc=0
XPROP_RAW stdout='_NET_SUPPORTING_WM_CHECK:  no such atom on any window.|'
XPROP_RAW stderr=''
OLD_PREDICATE rc=0 （无 pipefail；0＝谓词为真）
OLD_PREDICATE_PIPEFAIL rc=0 （cell3.sh 环境；0＝会 break）
OLD_PREDICATE_LOOP break_at_iteration=1 elapsed_s=0.00
```

**三条机制结论**（都有上面的原文支撑）：
1. **失败文案走 stdout、且 `xprop` 退 `0`** —— 所以 `2>/dev/null` **挡不住它**（它不在 stderr），`grep -q window` 拿到的就是这句文案 ⇒ **谓词恒真**。
2. **`set -o pipefail` 也救不了**：`cell3.sh:4` 就有 `pipefail`，但 `xprop` 的 rc 本来就是 `0` ⇒ 管道 rc = `grep` 的 rc = `0` ⇒ `&& break` 成立。⚠️ 这一点**必须现场量**：若 `xprop` 退 `1`，`pipefail` 会把"恒真"变成"恒假"（**另一种坏法**），两者结论完全不同。
3. 后果与登记条一致：等待**第一次迭代就 break**（`iteration=1`、`0.00 s`）⇒ 紧接着的自证行在 **WM 还没宣告的时刻**取样。
   - 本机实测原子出现时刻 = **`0.27 s`**（腿 T 独立轮询，`ATOM_APPEARED_AT_S=0.27 iteration=2`）；既有留档 W54A §0.4(1) 记的是 **≈1.0 s**（机器/版本不同，两个数都如实列出，不取平均）。

---

## §3 改动：`cell3.sh`（before → after）

⚠️ **路径纠正**：任务书写 `build/MilBridge/W53A/cell3.sh`。现场核（三条独立证据）：
```
$ find / -maxdepth 8 -type d -name W53A        → （空）
$ find ~ -name cell3.sh                        → /home/links-dev/w53a/cell3.sh（count=1）
$ git -C ~/netTest/GitProj/WPFOnLinux ls-files | grep W53A → build/MilBridge/W53A-report.md（只有报告）
```
⇒ 该脚本是**仓外实验装置**（`~/w53a/`，W53A 车道私有目录），**从未**在仓里。既有报告（W93A §8、W96A §5.4、`docs/ROUTES.md:370`）写的 `build/MilBridge/W53A/cell3.sh:26` 是**路径笔误**（内容与行号都对得上 `~/w53a/cell3.sh:26`）。**我按真身改**，不在仓内复制第二份。

| 件 | before sha16 | after sha16 | 权限 |
|---|---|---|---|
| `~/w53a/cell3.sh` | **`06c6d17fa9906761`**（8,522 B） | **`a358f6fd38b3b387`**（10,335 B） | `711 → 711`（逐位不变） |
| 备份 `~/w102a/cell3.sh.before-W102A` | — | **`06c6d17fa9906761`**（`cp -p`，与修前逐字节相同） | `711` |

`diff -u`（逐字，仅 WM 等待那一段；**其余逻辑一行未动**）：

```diff
--- /home/links-dev/w102a/cell3.sh.before-W102A	2026-09-20 11:11:24
+++ cell3.sh	2026-09-22 19:20:03
@@ -23,7 +23,25 @@
 if [ "$WM" = wm ]; then
   eval "$(dbus-launch --sh-syntax)" >/dev/null 2>&1
   xfwm4 --display="$DISP" --compositor=off > "$OUT/xfwm4.log" 2>&1 & WMPID=$!
-  for _ in $(seq 1 40); do xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window && break; sleep 0.25; done
+  # 【`D-G89` 落地 · 车道 W102A · 2026-09-22】**原第 26 行**（恒真判据）逐字为：
+  #     for _ in $(seq 1 40); do xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window && break; sleep 0.25; done
+  #   它**恒真**：`xprop` 失败时往 **stdout** 打 `_NET_SUPPORTING_WM_CHECK:  no such atom on any window. `
+  #   （`rc=0`），里面含 `window` ⇒ `grep` 命中 ⇒ `&& break` ⇒ **等待第一次迭代就结束**（现场实测
+  #   `break_at_iteration=1`、`elapsed_s=0.00`；`set -o pipefail` **也拦不住**它，因为 `xprop` 的 rc 本来就是 0）
+  #   ⇒ 紧接着第 29 行那条自证会打出"WM 不在"的**假阴性**（`W53A` 的 `C`/`C2`/`D`/`D2` 四格就是
+  #   `no such atom on any window.`，而同格 `trees.txt` 里 WM 的窗与**重定父框架**都在）。
+  #   换成**真判据**（判据原文 `~/w102a/criteria.md` §1；三条件**全要**）：
+  #     ① `_NET_SUPPORTING_WM_CHECK` **能解析出窗口 id**（≠`0x0`）
+  #     ② 该 id **此刻在树里**（`xwininfo -id` 成功）且 `_NET_WM_NAME`/`WM_CLASS` 可读非空
+  #     ③ `_NET_SUPPORTED` **非空**
+  #   实现 = `build/MilBridge/tools/wm-awaited.sh`（带 `--selftest`；**等不到就非零退出 ＋ 逐条打读数**，
+  #   绝不静默继续）。⚠️ 这里**不加** `--require-reparent`：本行在应用起窗**之前**（第 34 行才起），
+  #   那一刻**必然没有客户窗** ⇒ 加了会让等待永不可能成功（理由见判据 §2）。
+  WM_TOOL="${WMAWAIT_SH:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/tools/wm-awaited.sh}"
+  [ -r "$WM_TOOL" ] || { say "WM_AWAITED=FAIL reason=tool-missing path=$WM_TOOL"; exit 6; }
+  if ! bash "$WM_TOOL" --wait 10 --display "$DISP" >> "$OUT/steps.txt" 2>&1; then
+    say "WM_AWAITED=FAIL reason=wm-not-ready display=$DISP（三条件逐条读数见 steps.txt 尾部）"; exit 6
+  fi
 fi
```

**语义等价性**：预算不变（原 `40 × 0.25 s` = **10 s** ⇒ `--wait 10`）；`exit 6` 会触发 `cell3.sh` 既有的 `trap cleanup EXIT`（按 PID 收 `APID/WMPID/XPID`）⇒ **不留残留**；工具缺失也**大声死**（`tool-missing`），不会静默继续。

---

## §4 两极化成对读数（本件核心证据）

驱动 `~/w102a/run-legs.sh`（`83bc46c225925a7f`）｜证据目录 **`~/w102a/logs/legs-20260922-191931/`**（`xvfb.log` 空 ＝ 无崩溃）。
私有显示 `:186`（`Xvfb :186 -screen 0 1280x1024x24 -nolisten tcp -noreset`），**未碰** `:0/:1/:10/:95/:96/:97/:99`（现场 `:97`/`:99` 有别的车道在用，`~w101a` 同时在 `:184` 跑 —— 我没碰）。

### 腿 R —— 反极（**无 WM**）

| 项 | 读数（逐字） |
|---|---|
| 旧谓词（无 pipefail） | `rc=0` ⇒ **"WM 在"（假）** |
| 旧谓词（`cell3.sh` 的 `pipefail` 环境） | `rc=0` ⇒ **"WM 在"（假）** |
| 旧谓词计时循环 | `break_at_iteration=1 elapsed_s=0.00` |
| 新判据 `--check` | `WM_AWAITED=FAIL c1=no c2=no c3=no c4=0 attempts=1` ⇒ **`rc=1`** |
| 新判据 `--wait 4` | `WM_AWAITED=FAIL … elapsed_s=4.12 attempts=13` ⇒ **`rc=1`**（**用满预算** ＝ "等"真的在等） |

### 腿 T —— 时序（**等待中起 WM**；同一函数由 FAIL 翻 PASS）

```
DISP_ALIVE_BEFORE_WM=yes
DBUS_SESSION_BUS_PID=2962063
XFWM4_STARTED pid=2962064 display=:186 配方='xfwm4 --display=:186 --compositor=off'（照抄 W53A/cell3.sh:25）
ATOM_APPEARED_AT_S=0.27 (iteration=2)        ← 独立轮询（X 服务器自己的属性）
XFWM4_ALIVE=yes
后台那条 --wait 20 的输出：
  WM_AWAITED=PASS c1=yes c2=yes c3=yes c4=0 display=:186 elapsed_s=0.58 attempts=3
  NEW_WAIT20_RC=0
```
⇒ **同一条命令**：无 WM 时 `FAIL`（4.12 s 用满预算），WM 一宣告就 `PASS`（0.58 s）⇒ 证明它是"**等**"，不是"立刻放行"，也不是"永远不放行"。

### 腿 F —— 正极（**有 WM**）+ **独立**在场证据

工具读数（`--check`）：
```
WM_C1_ATOM_ID ok=yes id=0x4000ae raw='_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae'
WM_C2_WM_WINDOW ok=yes exists=yes name_ok=yes class_ok=yes id=0x4000ae
   name_raw='_NET_WM_NAME(UTF8_STRING) = "Xfwm4"' class_raw='WM_CLASS(STRING) = "xfwm4", "Xfwm4"'
WM_C3_EWMH_SET ok=yes n=78 raw='_NET_SUPPORTED(ATOM) = _NET_ACTIVE_WINDOW, _NET_CLIENT_LIST, …（78 项，**原子名形状**）'
WM_C4_REPARENT n=0 required=no ok=na
WM_AWAITED=PASS c1=yes c2=yes c3=yes c4=0 display=:186 elapsed_s=0.04 attempts=1
```
**不用那条恒真判定自证**（`D-G89` 的教训），另取三条独立读数：
1. `WM_ID=0x4000ae`，`xprop -id 0x4000ae _NET_WM_NAME WM_CLASS` ⇒ `"Xfwm4"` / `"xfwm4","Xfwm4"`；
2. `_NET_SUPPORTED` 条数 **78**（工具 `C3 n=78` 与独立逗号计数 **78** **同值**）；
3. **重定父**：起真客户窗 `xclock`（PID `2962300`）后 `xwininfo -root -children` 里出现框架 `0x400264 174x198+553+413`（**有子窗**），工具 `--check --require-reparent` ⇒ `WM_C4_REPARENT n=1 required=yes ok=yes`、**`WM_AWAITED=PASS`、`rc=0`**。

### 收工（按 PID，无 `pkill -f`）
```
PGREP_XVFB_AFTER：2394341 Xvfb :99 ｜ 2415049 Xvfb :97      ← 只剩别人的
PGREP_XFWM4_AFTER：646945 xfwm4（用户会话，全程未碰）
PGREP_XCLOCK_AFTER：（无）    SOCKET_186：没有那个文件或目录
本件会话总线 2962063／at-spi 2962074 ⇒ 逐一体检：gone
```

---

## §5 工具自证：`build/MilBridge/tools/wm-awaited.sh`

`syntax`：`bash -n` OK｜**sha16 `57a852f6948e1c67`**（`20,399 B`，mtime `19:17:45` ⇒ **早于**所有两极化运行 `19:19:31`/`19:20:31`，即**跑的就是这一版**）。
`--selftest`（**`rc=0`**）：`WM_AWAITED_SELFTEST=PASS cases=11 pass=11 not-as-expected=0`（其中"旧谓词恒真"复现例 1 个）：

| 例 | 期望 | 实测 |
|---|---|---|
| `S1` 三条件真 ＋ 有重定父（`--require-reparent`） | PASS/0 | PASS/0 |
| `S1b` 同一 fixture、不要求重定父 | PASS/0 | PASS/0 |
| **`S2` 无 WM（用 `xprop` 的**失败文案**做输入）** | FAIL/1 | FAIL/1 |
| **`S2-old-predicate` 同一份输入喂旧谓词** | `true/0` | `OLD-PREDICATE-TRUE rc=0`（**缺陷被机证复现**） |
| `S3` 陈旧 id（id 能解析、窗已不在） | FAIL/1 | FAIL/1 |
| `S4` `_NET_SUPPORTED` 缺席 | FAIL/1 | FAIL/1 |
| `S5` 要求重定父但无客户窗 | FAIL/1 | FAIL/1 |
| `S6` X 服务器问不到 | **NOINFO/2** | NOINFO/2 |
| `S7` id = `0x0` | FAIL/1 | FAIL/1 |
| `S9` `_NET_SUPPORTED` 为**原子名**形状（🩸补测） | PASS/0 | PASS/0 |
| `S8` **反空转守卫**（空 fixture 必须被拦） | 守卫开火 | `GUARD-FIRED` |

> 🩸 `S8` 的守卫是**被真事逼出来的**：首版 `run_case` 用**用例标签**当 fixture 目录名 ⇒ fixture 写在 `$T/S1`、孩子读 `$T/S1-all-true-…`（空目录）⇒ **除正极性那一例外，全部退化成"读不到 ⇒ FAIL"，而它们的期望恰好是 FAIL** ⇒ "七例通过里六例是空转"。现在空 fixture 会**当场报 NOT-AS-EXPECTED** ⇒ 上表 11 例没有空转。
> `syntax` ＋ 仓内既有牙 `build/MilBridge/tools/shell-quote-trap-check.sh`（只读跑）⇒ `SHELL_QUOTE_TRAP=PASS traps=0 files=152`（我的新件在扫描面内、**0 陷阱**）。

---

## §6 改后 `cell3.sh` 那一段的装置验证（**不能**端到端跑 `cell3.sh`）

`cell3.sh` 第 4x 行会 `dotnet HandyControlDemo.dll` ⇒ 违"零应用"。⇒ 装置 `~/w102a/verify-cell3-block.sh`（`6f5e1d48e8ad3a33`）**用 `sed` 从文件里把 WM 段原文抽出来跑**（不是我抄一份），私有 `:187`：

| 例 | 装置 | 期望 | 实测 |
|---|---|---|---|
| A 反极 | `xfwm4` = "活着但**永不宣告**"的桩（`STUB_PIDFILE` 供按 PID 收） | `exit 6` ＋ marks 落 FAIL | **`CASE_A_RC=6`**；`marks.txt: WM_AWAITED=FAIL reason=wm-not-ready display=:187`；`steps.txt: WM_AWAITED=FAIL … elapsed_s=10.19 attempts=39` ＋ 三条件逐条读数 |
| B 正极 | **真** `xfwm4`（`cell3.sh:25` 配方） | `rc=0` ＋ steps 落 PASS | **`CASE_B_RC=0`**；`marks.txt` **空**（无 FAIL）；`steps.txt: WM_AWAITED=PASS … elapsed_s=0.32 attempts=2` |

证据：`~/w102a/logs/verify-cell3-20260922-192031/`（`block-extracted.txt` 23 行 ＋ `A/B` 两例日志）。
收工：桩（`2962807`）／真 `xfwm4 --display=:187`（`2963849`）／新出现的 3 个 `dbus-daemon`（`2962806`/`2963848`/`2963879`）**逐 PID 收**；`Xvfb :187`（`2962789`）由 `trap` 收 ⇒ 复核**全 gone**。
⚠️【装置留痕（公告）】反极那支用的是**我造的桩 `xfwm4`**（`sleep 90` ＋ 写 pidfile），它**不宣告 WM**；这不是产品的任何行为，只为把"永不宣告"这条腿走到。

---

## §7 `fp_inputs` 影响判断（机械核）

装置 `~/w102a/fp-check.sh`（`fea9f7668411d249`）：**复用** `build/close-wave.sh` 里 `fp_inputs()` 的**原文**（`awk` 抽函数体后 `eval`，只把尾部 `| xargs sha256sum …` 换成"打印文件清单" ⇒ 不手抄覆盖面）。

```
[19:26 那次量]  FP_INPUTS=c138491c611de7d5839964a8c17afa9121aed57af643a1896257f7d5e031e4fb
[19:29 收尾量]  FP_INPUTS_1=ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48
                FP_INPUTS_2=ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48
                FP_INPUTS_3=ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48   ← 连测三遍稳定
                ⇒ **== `#50` 冻结值**（W99A 报告 §130 记的 `ee543f44b1090c74…`）
FP_COVERAGE_FILES=147
grep wm-awaited ⇒ 0 命中 ｜ grep cell3 ⇒ 0 命中 ｜ grep W53A ⇒ 0 命中 ｜ grep W102A ⇒ 0 命中
```

**判断（三条，分开说）**：
1. **本件贡献 = 零**（**机械证**，不是推断）：覆盖面 147 件里我编辑的两件**都不在**——`build/MilBridge/tools/wm-awaited.sh` 是**新件**，而 `fp_inputs()` 里 `build/MilBridge/tools/*` 是**按名枚举**的 15 件白名单（现场清单：`tline-gate.sh`…`verify-all-step-check.sh`，我的新件不在其中）；其余 `find` 支只吃 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`/`build/shims/**.cs`/`src/WpfGfx.Linux/**.cs`/`src/WpfGfx.Linux.Native/**.{c,h}` —— **一条也不匹配**（我改的 `~/w53a/cell3.sh` 是**仓外件**，更不在）。⇒ **无需为本件"重钉世代"**：`#51` 收尾时这一格与 `#50` 逐位相同。
2. ⚠️ **中途偏离一次，已闭合（读数带时刻，不许只看一个数）**：`19:26` 量到 **`c138491c…`**，**不是**我造成的 —— 覆盖面里 **mtime 最新的两件**是

   | mtime（19:26 那次） | 件 | 归属 |
   |---|---|---|
   | `2026-09-22 19:20:26` | `src/WpfGfx.Linux.Native/src/win32_core.c` | **车道 W101A（`TASK-0108`）写域** |
   | `2026-09-22 19:20:03` | `src/WpfGfx.Linux.Native/src/win32_internal.h` | 同上 |
   | `2026-09-22 16:17:53` | `build/MilBridge/tools/r-gate-step.sh` | `#50` 收尾链时期（W91A） |

   `19:29` 复量 ⇒ 回到 `ee543f44…`，且那两件的 mtime 回到 **`2026-09-21 23:13:03` / `23:06:13`**（逐字节同修前）⇒ W101A **按 `cp -p` 口径还原**了它的实验性改动（正是仓内纪律"实验装置类改动必须事后还原"）。
   ⇒ 到本报告收尾为止：**`fp_inputs` 与 `#50` 冻结值逐位相同，且本件贡献为零**；那 3 分钟的偏离**不是本件**，也不该记在本件账上。
   ⚠️ **时间戳巧合提醒**：我编辑 `~/w53a/cell3.sh` 的时刻也是 `19:20:03`（**仓外**路径），与 `win32_internal.h` 同秒 —— **不是同一个件**，别误读。
3. **可复核**：`bash ~/w102a/fp-check.sh`（现算，两遍 ＋ 打印 147 件清单）。

---

## §8 全仓盘点（同类写法逐处）

**口径（公开）**：`grep -rn '_NET_SUPPORTING_WM_CHECK'`，`--include='*.sh'/'*.py'/'*.c'/'*.h'/'*.md'`；**排除** `build/MilBridge/arm-logs/**`（命中 **0**）、`upstream/**`（命中 **0**）；**二进制产物另计**（`*.so`/`*.o` 命中 **6 件**：4 份 `libwpfwin32.so` ＋ `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＋ `obj/win32_x11.o` —— 都是编译产物，**不是判据**）；仓外扫 `$HOME` 下 `depth≤3` 的 `*.sh/*.py`（**907 件**，排除 `app/`、`logs/`、`out/`）。

### 8.1 仓内 —— **可执行装置里 0 处**（这是我这次盘点最重要的结论）

| 处 | 类别 | 原文/位置 | 判断 |
|---|---|---|---|
| `build/MilBridge/tools/wm-awaited.sh` | **本件新件** | 全文 | 真判据；其中 `:17`/`:316` 出现旧谓词是**注释**与**自测的反极性对照**（故意留），**不是**活判据 |
| `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh:127,166` | 装置（唯一会用 `xprop` 的既有脚本） | `xprop -id <xid> WM_NORMAL_HINTS` | **不是**等 WM 的判据（读窗口属性）⇒ **无需改** |
| `src/WpfGfx.Linux.Native/src/win32_x11.c:198`（intern）＋`:1659 wpf_x11_has_ewmh_wm()`＋`:1780 wpf_x11_moveresize()`｜`win32_internal.h:590` | **产品代码** | `XGetWindowProperty(..., XA_WINDOW, …) data && n>=1 && fmt==32` | **不是**恒真谓词（真读属性）⇒ **不属本件**；但见 §8.4 的边界 |
| `build/MilBridge/W{53,54,77,85,89,93,96,98,99}A-report.md`、`docs/ROUTES.md:192,360,370`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2408-2414`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:13` | **文档/报告** | 引用与登记 | **不是**装置 ⇒ 不改（`D-G89` 的路径笔误见 §3，**登记件不属我写域**） |

⇒ **"全仓同类写法"里，仓内没有一处活的恒真判据**。任务书给的唯一"既有实例"（`build/MilBridge/W53A/cell3.sh:26`）**在仓里不存在**（§3）——真身在仓外。

### 8.2 仓外：**同一个恒真谓词当判据用的地方（活代码）**

| # | 文件:行 | 原文（逐字） | 用途 | 状态/建议 |
|---|---|---|---|---|
| 1 | `~/w53a/cell3.sh`（原 `:26`） | `for _ in $(seq 1 40); do xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null \| grep -q window && break; sleep 0.25; done` | 等 WM | **本件已修**（§3） |
| 2 | `~/w53a/cell.sh:26` | 与上**逐字相同** | 等 WM | **未修** ⇒ 建议另派：换 `bash …/wm-awaited.sh --wait 10` 或最小改 `grep -q 'window id #'` |
| 3 | `~/w53a/cell2.sh:26` | 与上**逐字相同** | 等 WM | **未修** ⇒ 同上 |
| 4 | `~/w76a/bin/ab.sh:26` | `xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null \| grep -q window && break; sleep 0.25`（在 `for _ in $(seq 1 40)` 里） | 等 WM | **未修** ⇒ 同上 |
| 5 | `~/w63a/bin/wm-leg.sh:19` | `if ! DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null \| grep -q window; then` | **`if !` ⇒ 起 WM** | **未修 · 更坏（见 §8.3）** |

### 8.3 ⚠️ `~/w63a/bin/wm-leg.sh:19` 是**反向恒假**（同族里最坏的一处，**只报未修**）

谓词恒真 ⇒ `!` **恒假** ⇒ `then` 体（起 `xfwm4`）**永远进不去** ⇒ 该"WM 腿"**永远不会自己起 WM**。**机械证**（私有 `:188` 无 WM，脚本同款文本，`~/w102a/logs/w63a-form-demo.txt`）：

```
W63A_FORM: **没进 if 体**（＝永远起不了 WM）
TRUE_CRITERIA_FORM: 进了 if 体（正确：确实没 WM）
_NET_SUPPORTING_WM_CHECK:  no such atom on any window.      ← 现场原文
xprop rc=0
```

**现场读数支持**（含不确定性，如实划）：
- `~/w63a/logs/wm.progress:1` = `2026-09-21 11:35:25 DISPLAY=:197 wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window. geom=1024x768` ⇒ 自称"**WM 腿**"（头部还引 `D-G64`「无 WM 的验收装置永远复现不出一整类缺陷」）的那一趟**跑在无 WM 上**。
- `~/w63a/bin/wm-leg.sh` mtime = `2026-09-21 11:35:22` ⇒ **早于**该读数 3 s ⇒ 读数由**当前这版**产生。
- ⚠️ `~/w63a/xfwm197.pid`/`xfwm197.log` 的 mtime 是 `2026-09-21 00:24:03`（**更早**）⇒ 那是**更早一版**留下的（说明当时**进得去**分支）；**我没有那一版的原文** ⇒「当时判据是好的」只是**推断**。**能机证的**只有"当前版分支不可达"。
- **建议**：另派车道修 ＋ **复核那一趟的臂结论**（它是在无 WM 下取的，可能要重取）。这条值得登记（**登记不在我写域**，我只报）。

### 8.4 仓外：**正确写法**（解析 `window id #`）与**只记录**——**不用改**，只列供参考

**正确（18 处命中 / 9 件）**：`~/w93a/x-wm-test.sh:36` 与 `run-w93a-legs.sh:64,68`｜`~/w101a/run-w101a-legs.sh:66,70`（`case … *"window id #"*` ＋ `WMEVID=PASS/NOINFO`）｜`~/w54a/bin/{l6_otherwin,l9_probe}.sh:40/:37`、`{drive,drive_old,legrun,legrun_noTab}.sh:62/:70`｜`~/w58a/bin/{cell.sh:47,50,52,startdisp.sh:12,15}`（`grep -c 'window id'`）。
**只记录（15 件；读数是"当时那一刻"的快照，本身不判 ⇒ 不属 `D-G89`，但**取样时机**同源风险）**：`~/w53a/{smoke.sh:23,wfp3.sh:51}`、`~/w53-clickprobe.sh:38`、`~/w58-window-probe.sh:22`、`~/w63a/bin/{wm-leg.sh:23,wm-leg198.sh:15}`、`~/w74a/bin/probeA.sh:20`、`~/w77a/bin/{A,A2,B,C,xup}.sh`、`~/w89a/bin/{hc-arm-inner,probe-arm-inner,xup}.sh`、`~/w98a/bin/batch.sh:14`。

### 8.5 产品侧边界（**只报**，不再动）

`wpf_x11_has_ewmh_wm()` 用的是真 `XGetWindowProperty`（**不是**恒真谓词）⇒ 与 `D-G89` **不同族**。但它**只查"属性在不在"，不查"那个窗还在不在"** —— 而 §1 引用的既有留档证明**WM 死后属性会残留**（`xfwm4_alive=no` 而 `window id # 0x…` 仍在）。⇒ `wpf_x11_moveresize()` 在"WM 已死但属性残留"时会**走 EWMH 分支**（`XSendEvent` 给 root，无人处理）而**不走兜底 `XMoveResizeWindow`** ⇒ 可能**静默丢一次移动**。**我未测产品面**（需跑应用 ⇒ 违本件纪律）⇒ 记 **`NOINFO`**，**建议另立一条**（与 `D-G88`/`H2` 相邻但不同因）。

---

## §9 与 `D-G77` 是否同族：**是同族，且 `D-G77` 是"已修好的那个样板"**

`D-G77`（`retake-arms-w23.sh:78-105` 硬写 `DISPLAY=:97`、无人保证 `:97` 常驻）与 `D-G89` 族属同一条：
**"装置假设某个 X 状态成立，却不在用之前验证"** —— `D-G77` 假设"显示在"，`D-G89` 假设"等待=WM 起来了"。
**但两者的修法形状是同一个**：`D-G77` 的修法 = **先验（`xdpyinfo`）→ 自起（Xvfb，记 PID）→ 起不来就 `exit 5` 大声死**；本件的 `wm-awaited.sh` 就是这条形状在 **WM 侧**的对应物（**先验三条件 → 等不到就非零退出 ＋ 打读数**）。
⇒ 判断：**同族（`D-G77`/`D-G59`/`D-G89` 三条一起看）**，`D-G77` 已是**修好的一支**可当模板；`D-G89` 是本族第三处，**`~/w63a/bin/wm-leg.sh:19`（§8.3）是第四处、且是"反向恒假"新形态**。那件**我没改**（不在写域）。

---

## §10 我自己犯的装置错（诚实留档，都已修）

| # | 错 | 抓到方式 | 修法与代价 |
|---|---|---|---|
| 1 | `run_case` 用**用例标签**当 fixture 目录名 ⇒ 7 例里 6 例**空转通过** | **正极性 `S1` 报 FAIL** | 分开 fixture id 与标签 ＋ **反空转守卫**（空 fixture 当场报 NOT-AS-EXPECTED）＋ `S8` 专测守卫。**若没有 `S1` 那一例，这套自测会"全绿"骗过我** |
| 2 | `C3` 只认 `0x…` 形状 ⇒ **真机恒假**（真 `xfwm4` 打**原子名**） | 腿 T/F 现场 C3=no 而 `_NET_SUPPORTED` 明明有 78 项 | 改成"按逗号数项、两种形状都认"＋补 `S9`；判据 §5.1 加注更正 |
| 3 | `cell3.sh` 的配方**不带 `dbus-launch`** 直接起 `xfwm4` | `xfwm4-CRITICAL: Xfconf could not be initialized` ⇒ WM 当场死 | 我的**驱动**补 `dbus-launch`（`cell3.sh:24` 本来就有这行，**不是**我加的） |
| 4 | `Xvfb` **不带 `-noreset`** ⇒ 腿 R 的 `xprop` 全退出后 X 做一次 reset，`xfwm4` 正好撞进去 | `Gtk-WARNING: cannot open display` 而**同一秒** `xclock` 又能连上 | 驱动加 `-noreset` ＋ 每腿前**现场复核显示存活**；**`cell3.sh` 的配方一字节未动** |
| 5 | 我自己的 `old-predicate.sh:33` 在**双引号里写了反引号**（＝命令替换） | 输出里出现 `…: 未找到命令`；跑仓内 `shell-quote-trap-check.sh` 复核（`traps=0`） | 去掉反引号。**这正是 `D-G42` 族"shell 引号陷阱"**，被我自己踩了一次 |
| 6 | 驱动里"独立计数"也用了 `0x…` 正则 ⇒ 印 `NET_SUPPORTED_N=0` | 与工具自己的 `n=78` **同件两处不一致** | 改成同口径 ＋ 同时印 `HEXTOKENS`（**一眼看出形状**）⇒ 那一刻的"独立"两字差点自欺 |

---

## §11 `NOINFO` / 未做（既不算绿也不算红）

1. **`cell3.sh` 从未端到端跑**（它会 `dotnet HandyControlDemo.dll` ⇒ 违"零应用"）⇒ 只做了**段级**两极化（§6）。真端到端要等哪个允许跑应用的波次。
2. **`w63a` 那趟臂结论的正确性未复核**（§8.3）：我只证"当前版分支不可达 ＋ 11:35 那趟无 WM"，**没有**去重跑/重判它的臂。
3. **产品侧 `has_ewmh_wm()` 的"死 WM 残留 ⇒ 静默丢移动"未实测**（§8.5）⇒ `NOINFO`。
4. **仓外 4 处同类恒真谓词未修**（`w53a/cell.sh`、`w53a/cell2.sh`、`w76a/bin/ab.sh`、`w63a/bin/wm-leg.sh`）—— 任务书写域只给 `cell3.sh` ⇒ 按纪律**只报**。
5. **`~w53a` 的 `cell.sh`/`cell2.sh` 的四格旧结论（`C/C2/D/D2` 的 `WMPROOF` 行）未重跑复核**（它们是在恒真判据下取的自证行；真结论靠 `trees.txt` 的重定父框架仍成立，我只核了 `C-wm-splash` 一格）。
6. **未接线**：`wm-awaited.sh` 未进 `verify-all`/任何门禁（不是本件任务），也**未**进 `fp_inputs()` 覆盖面（`close-wave.sh` 不在我写域）。⚠️ **若主控把它接进任何在仓调用方**，按仓内纪律它应**同时**进覆盖面（"判据改了自己没人看着"同族欠账）。
7. **`TASK-0107`/`TASK-0703` 等地图行我没动**（`docs/ROUTES.md` 不在本件写域）⇒ `TASK-0703` 的 ✅ 标记与 `w63a` 新发现的登记**留给主控**。

---

## §12 交付件总表（现算 sha16）

| 件 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/tools/wm-awaited.sh` | **`57a852f6948e1c67`** | 新建（真判据 ＋ `--selftest 11/11`） |
| `~/w53a/cell3.sh` | **`a358f6fd38b3b387`**（修前 `06c6d17fa9906761`） | 只换恒真那一行 |
| `~/w102a/cell3.sh.before-W102A` | `06c6d17fa9906761` | `cp -p` 备份（与修前逐字节相同） |
| `~/w102a/criteria.md` | **`f0cc9ca03fd610aa`** | 判据（先写）＋ §5 更正/新发现 |
| `~/w102a/old-predicate.sh` | `9bf0b155abebbacc` | 旧谓词读数器 |
| `~/w102a/run-legs.sh` | `83bc46c225925a7f` | 三条腿驱动 |
| `~/w102a/verify-cell3-block.sh` | `6f5e1d48e8ad3a33` | 段级两极化验证 |
| `~/w102a/fp-check.sh` | `fea9f7668411d249` | `fp_inputs` 机械核 |
| `$R/build/MilBridge/W102A-report.md` | 本件（写完现算） | 报告 |

**证据目录**：`~/w102a/logs/legs-20260922-191931/`（**采用**：三腿齐、`DISP_ALIVE` 全 yes、收工干净）｜`~/w102a/logs/verify-cell3-20260922-192031/`（段级 A/B）｜`~/w102a/logs/w63a-form-demo.txt`（§8.3 机证）｜`legs-20260922-191617/191704/191836`（**被弃**：`191617`/`191836` 是 `xfwm4` 起不来的失败趟，`191704` 是 C3 形状错的那趟 —— **三趟全部留在盘上不许删**，它们正是 §10 三个装置错的原始现场）。

---

## §13 大白话小结（6 行）

1. **那句话确实恒真**：`xprop` 查不到属性时**不报错**（`rc=0`），它往**标准输出**打一句带 `window` 的失败文案，于是 `grep -q window` 永远命中、`break` 永远立刻执行 —— 我用 `:186` 空屏实测复现（`break_at_iteration=1`）。
2. **真判据是"三件事全要"**：能解析出窗口 id、那个窗**此刻还在**、`_NET_SUPPORTED` 非空；等不到就**大声死**并逐条打读数。为什么不是只查 id：留档里有"WM 死了属性还在"的读数，只查 id 会被鬼影骗。
3. **两极化成立**：空屏 **FAIL**（`--wait 4` 老老实实等满 4.12 s）、起 WM 后 **PASS**（0.58 s，原子 0.27 s 出现）；有 WM 时另有 `_NET_SUPPORTED 78` 项 ＋ `xclock` 被装进框架的**独立**证据。
4. **要改的那个文件不在仓里**：`build/MilBridge/W53A/cell3.sh` 是路径笔误，真身是仓外 `~/w53a/cell3.sh`；我按真身改（只换一行，`cp -p` 备份），**没在仓里复制第二份**。
5. **同类写法仓内 0 处、仓外还有 4 处**；其中 `~/w63a/bin/wm-leg.sh:19` 最坏 —— 同一个恒真谓词用在 `if !` 上，**起 WM 的分支永远进不去**，而它日志里那趟"WM 腿"真的跑在无 WM 上（**建议另派 ＋ 复核那趟结论**）。
6. **`fp_inputs` 本件零影响**（覆盖面 147 件命中 0），**收尾态与 `#50` 冻结值 `ee543f44…` 逐位相同**（`#51` 收尾不必为本件重钉）。中途 `19:26` 曾量到 `c138491c…` —— 那是 **W101A** 在 `19:20` 改 `win32_core.c`/`win32_internal.h`（它的写域）造成、`19:29` 已被它自己还原，**不是**我。
