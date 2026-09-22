# W108A 报告 —— 修掉 `TASK-0703` 的最后缺口 ＋ 登记第三种形态 ＋ 收口 `TASK-0703`

- **车道**：W108A｜**日期**：2026-09-22｜**形态**：纯文本 ＋ 一小段脚本语义修正 ＋ 极轻量私有 X 验证
- **纪律**：**零 `dotnet`／零构建／零应用／不占重活槽**；**未**跑 `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何门禁；**未** `pkill -f`（一律按 PID）
- **冻结基线**：`#50` = `1f4189c1257737a9`（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，本件**逐位未动**）
- **判据先写**：`~/w108a/criteria.md`（sha16 **`99da4ba5d0fe8d8c`**，写在任何改动**之前**）
- **仓** `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是** git 仓，无 `.git`）；**fork 克隆** `~/netTest/GitProj/WPFOnLinux`（推送用）

> ⚠️ **口径说明（先讲，免得误读）**：`R` 是工作树、**没有 `.git`**；改动在 `R` 里做，再**逐件复制**到克隆里 `git add` 推送。
> 开工前已机械核过两者**逐件相同**（`W107A-report.md`／`W103A-report.md`／`AB`／`CS`／`HO` 五件 `SAME`，克隆 `git status` **干净**、`declared` **132**）。

---

## §0 一句话结论

`~/w63a/bin/wm-leg198.sh:17` 那个 **glob 恒真守卫**已修成**真判据**，**两极化三条腿全部成立**；
**第四形态普查的活装置命中 = 0**；**`D-G97` 已进册**；**`TASK-0703` 标 ✅**（四条先写判据逐条满足）；
**`DEFREG=PASS declared=133 route_ids=133`**、**`DECLDRIFT=0`**。

---

## §1 判据（**先写**；`~/w108a/criteria.md` `99da4ba5d0fe8d8c`，共 §0–§10）

逐条摘录（**判据先写、后执行**；执行结果见后续各节）：

| 编号 | 判据 |
|---|---|
| `C1.1` | 改前 `cp -p` 备份到 `~/w108a/backup/`；**权限保持**（改前 `644`）；`bash -n` `rc=0` |
| `C1.2` | 旧形态 `case … *window*` **只留注释**；**可执行代码里计数必须为 0** |
| `C1.3` | 真判据直接用 `wm-awaited.sh --check`；取 **`rc`**：`PASS=0` ⇒ 继续；`FAIL`/`NOINFO` ⇒ `say "NOINFO wm-absent（WM 腿的前提不成立）"` ＋ **`exit 9`**（与原形态**退出码一致**） |
| `C1.4` | 工具不可执行 ⇒ **大声失败** `exit 9`，**不许静默放行、不许回退旧形态** |
| `C1.5` | 三条件**全要**（`C1∧C2∧C3`），**不许**只用 `grep 'window id #'` 单条件 |
| `C2.1` | **修前形态**（`sed` 从**备份**抽原文，**不执行整脚本**）喂入无 WM 失败文案 ⇒ **必须走 `:` ＝恒真** |
| `C2.2` | **修后形态**同一输入 ⇒ **必须走 `exit 9`**；**同一输入、两种形态、两个不同分支**（成对，否则不算） |
| `C2.3` | 同屏真 WM ⇒ 真判据 **`rc=0` PASS** ⇒ **不误报缺失**；**WM 真起来要有独立证据**（不许用旧谓词自证） |
| `C3.1`–`C3.4` | 第四形态扫 ≥6 种变形；**分别统计可执行/注释**；可执行命中**逐处点名**；除 `wm-leg198.sh:17` 外**只报不动** |
| `C4.2` | `D-G97` 判词必含四要件（glob 形态／普查射程缺口／实活证据＋sha16／教训＝按语义复核） |
| `C5.1` | **`TASK-0703` → ✅ 的四条件**：①装置侧交件 ②两极化成立 ③**全域重盘可执行活命中 = 0** ④缺口已登记 `D-G97` |
| `C5.2` | 若 ③ **不为 0** ⇒ **维持 🟡** 并逐处点名，**不许改口径凑绿** |
| `C5.3` | 口径句（**fixture/负控/自指不计入活装置缺口**）**必须在做完 §1–§3 之后**才写进地图 |
| `C6.1` | parity 两件**维持不推** 行要注明**依据文件与行**（`.gitignore:47`／`:51`）＋ 理由；**不改** `.gitignore` |
| `C7.2` | `DEFREG=PASS declared=<N> route_ids=<N>`／`DECLDRIFT=0`／`rc=0`，**连跑两遍逐字相同** |
| `C7.3` | `AB`（冻结基线）**逐位不动**；`CS`／`HO` 也**不动** |
| `C7.4` | 改 `ROUTES.md` 用**行锚定**改法，改完复核**未吞下一行** |
| `C8.2` | ⚠️ **push 之后重新 fetch** 再核 `rev-parse HEAD` ＝ `ls-remote origin HEAD`（W107A 踩过假 `MISMATCH`） |
| `C9.1` | `fp_inputs` 影响要给**机械证**（覆盖面逐件命中计数） |
| `C9.2` | `inputs_fp` **可能 ≠ `#50` 冻结值**（W101A/W106A 在飞产品改动）⇒ **如实说明，别当异常** |

---

## §2 `~/w63a/bin/wm-leg198.sh` 修正（唯一装置改动）

### 2.1 before / after ＋ 逐字 diff

| 读数 | 值 |
|---|---|
| before sha16 | **`371220d84d186e81`**（`perm=644`，`size=1790`，`mtime 2026-09-21 11:38:54`） |
| after sha16 | **`80f694dc0000ab55`**（`perm=644` **保持**，`size=4308`） |
| 备份 | `~/w108a/backup/wm-leg198.sh.before`（sha16 `371220d84d186e81`，`perm=644`）**逐位等于改前** |
| `bash -n` | **`rc=0`** |
| 可执行代码里 `*window*` | **0**（原始含注释 = `2`；**剥注释后可执行 = `0`**）|
| 旧形态留存 | **只在注释里**（`#   ⚠️ 旧形态（**恒真**，只留注释、**不再可执行**；原文逐字）：`） |

**逐字 diff（`diff -u 备份 改后`，`DIFF_RC=1` 即"有差异"，符合预期）**：`-` 行**只有一行**（原 `:17`），`+` 行为注释块 ＋ 真判据块：

```diff
@@ -14,7 +14,32 @@
 DISPLAY=$D xdpyinfo >/dev/null 2>&1 || { say "NOINFO no-display $D"; exit 2; }
 wm="$(DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | head -1)"
 say "DISPLAY=$D wm=[$wm] geom=$(DISPLAY=$D xdpyinfo | awk '/dimensions/{print $2}')"
-case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac
+# ---------------------------------------------------------------------------
+# 【W108A 修正（`D-G97`，第三种形态：**前提守卫恒真 · glob 形态**）】
+#   ⚠️ 旧形态（**恒真**，只留注释、**不再可执行**；原文逐字）：
+#     case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac
+#   坏在哪：`$wm` 来自上面 `:15` 的 `xprop -root _NET_SUPPORTING_WM_CHECK | head -1`；
+#     **无 WM 时 `xprop` 把失败文案打在 stdout**（`_NET_SUPPORTING_WM_CHECK:  no such atom on any window.`，
+#     `rc=0`，**不是** stderr）⇒ glob `*window*` 被这句失败文案自己命中 ⇒ 走 `:` ⇒
+#     **"前提成立"守卫恒真** ⇒ 这一趟自称"WM 腿"却静默跑在无 WM 上（`D-G95` 同族危害，但**形态不同**：
+#     `D-G89` = `grep -q window` 恒真；`D-G95` = 同一谓词用在 `if !` 上**反向恒假**；本条 = **glob 恒真**）。
+#   【真判据】不再自己写谓词，直接用仓内现成工具 `build/MilBridge/tools/wm-awaited.sh --check`，
+#     它要 **`C1 ∧ C2 ∧ C3` 三条件全要**（① `_NET_SUPPORTING_WM_CHECK` 能解出 `window id #` 且 ≠`0x0`；
+#     ② 该 id **此刻在树里**（`xwininfo -id` 成功）∧ `_NET_WM_NAME`/`WM_CLASS` 可读非空；③ `_NET_SUPPORTED` 非空）。
+#   【退出码与判词保持与原形态一致】`exit 9` ＋ `NOINFO wm-absent（WM 腿的前提不成立）`（**只换成真判据**）。
+# ---------------------------------------------------------------------------
+R="${WPF_LINUX_REPO:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}"
+WM_AWAITED="$R/build/MilBridge/tools/wm-awaited.sh"
+# ⚠️ 输出名**带时间戳**（**不许**用固定名）：`D-G96` 的教训 = 固定名会被下一次运行**截断**，
+#    为复核而重跑就把要复核的证据毁了；带时间戳 ⇒ **每次运行的原始三条件读数都活下来**。
+WM_AWAITED_OUT="$HOME/w63a/logs/wm-awaited-198.$(date +%Y%m%dT%H%M%S).txt"
+if [ ! -x "$WM_AWAITED" ]; then
+  say "NOINFO wm-absent（WM 腿的前提不成立）真判据工具不可执行：$WM_AWAITED（**大声失败，绝不静默放行**）"; exit 9
+fi
+wmrc=0
+DISPLAY=$D bash "$WM_AWAITED" --check --display "$D" > "$WM_AWAITED_OUT" 2>&1 || wmrc=$?
+if [ "$wmrc" -ne 0 ]; then
+  say "NOINFO wm-absent（WM 腿的前提不成立）wm_awaited_rc=$wmrc $(grep -m1 '^WM_AWAITED=' "$WM_AWAITED_OUT" 2>/dev/null || echo 'WM_AWAITED=<no-line>')"; exit 9
+fi
+say "WM-AWAITED-PASS $(grep -m1 '^WM_AWAITED=' "$WM_AWAITED_OUT" 2>/dev/null || echo 'WM_AWAITED=<no-line>')"
 
 run(){ # run <tag> <mode> <to>
   local tag="$1" mode="$2" to="$3" t0 t1 out bid
```

**设计选择与理由（逐条对应判据）**：
- **`C1.3`/`C1.5` 都满足**：不自写谓词、直接调 `wm-awaited.sh --check`（**只读引用，本件未改它**，`57a852f6948e1c67`），三条件**全要**；**退出码 `9` 与判词逐字不变** ⇒ 调用方/判词**零语义漂移**，**只**把"恒真"换成"真判"。
- **`C1.4`**：工具缺失走 `exit 9` ＋ 大声 `say`，**不静默放行、不回退旧形态**（照 `D-G77` 已修样板与 `TASK-0703` 的"不许静默放行"）。
- **额外（照 `D-G96` 的教训）**：输出名**带时间戳**而非固定名 —— 固定名会被**下一次运行截断**，正是 `D-G96` 记的那类"证据活不过一次重跑"。本次现场因此留下**两件**原始读数（`wm-awaited-198.20260922T195322.txt` 484 B／`…T195348.txt` 2253 B）。
- **未跑整脚本**（它会去起应用，且 `:12` 的 `: > "$PROG"` 会**截断** `wm198.progress`）⇒ 现场核对 `wm198.progress` mtime 仍是 **`2026-09-21 11:45:07`**，**本件一个字节都没写它**；`D-G96` 的截断行 `:12` **仍在**（**不在本件授权内，未改**）。

### 2.2 `xprop` 的"自报参数"（本形态的机理）

```
$ DISPLAY=:189 xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null
_NET_SUPPORTING_WM_CHECK:  no such atom on any window.
$ echo $?
0
```
⇒ **失败文案打在 stdout、`rc=0`**（`2>/dev/null` 挡不住）⇒ 其中 `any window.` 含 **`window`** ⇒ glob `*window*` **被这句失败文案自己命中**。

---

## §3 两极化 —— **三条腿**（**本件核心**；同趟取得，私有 `Xvfb :189`）

**装置纪律**：`Xvfb :189`（`-screen 0 1024x768x24 -nolisten tcp`）＋ `xfwm4 --display=:189 --compositor=off`，**一律按 PID 起、按 PID 收**；**未碰** `:0 :1 :10 :95 :96 :97 :99 :185 :186 :187 :188 :197 :198`（`:189` 起前已核 `ls /tmp/.X11-unix/` 无 `X189`）。收尾核对：两 PID 均 **`GONE`**，`:189` socket 已消失。

### 3.1 `C2.1` 修前形态 × 无 WM ⇒ **恒真**（★本件的"反极性"）

- **输入**（逐字，`:189` 无 WM 时 `xprop` 的真实 stdout）：`_NET_SUPPORTING_WM_CHECK:  no such atom on any window.`
- **形态原文**（`sed -n '17p'` 从**备份**抽出，**原文一字未改**）：`case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac`
- **读数**：`FORM=BEFORE branch=FALLTHROUGH(★前提成立不成立都放行) rc=0` ⇒ **走 `:` 分支**（**没有** `say`、**没有** `exit 9`）⇒ **"前提成立"守卫恒真** ✓
- **两条对照（证明这个"恒真"结论不是仪器假象）**：
  - 同一形态 × **空串** ⇒ `SAY: NOINFO wm-absent（WM 腿的前提不成立）`、`subshell rc=9` ⇒ 形态**本身能走 `*)`**（不是"永远走 `:`"的死代码）；
  - 同一形态 × **真 WM 文本** ⇒ `FORM=BEFORE-REALWM branch=COLON rc=0`。
  ⇒ **恒真的确切含义 = 两种相反输入给同一分支**（见 3.2）。

### 3.2 **"恒真"的直接证法**：同一形态、两种相反输入、**同一分支**

| 输入（都在 `:189` 上取） | 修前形态分支 |
|---|---|
| 无 WM：`_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` | **`:`**（`rc=0`） |
| 有 WM：`_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae` | **`:`**（`rc=0`） |

⇒ 一个"WM 不在"、一个"WM 在场"，**都走 `:`** ⇒ 它**不是"判对了"，是"没在判"**。（这比"输入文案命中"更强：**排除了"恰好这次对"**。）

### 3.3 `C2.2` 修后形态 × **同一份输入** ⇒ `exit 9`（真判据）

- **形态**：从**改后**件 `:31-44` 逐字抽出（`~/w108a/logs/form-after.block`），`D=':189'`、`say()` 照原定义。
- **读数**（逐字）：
  ```
  2026-09-22 19:53:22 NOINFO wm-absent（WM 腿的前提不成立）wm_awaited_rc=1 WM_AWAITED=FAIL c1=no c2=no c3=no c4=0 display=:189 elapsed_s=0.08 attempts=1
  SUBSHELL_RC=9
  ```
- ⇒ **同一输入、两种形态、两个不同分支**（`:`/`rc=0` **vs** `exit 9`）⇒ **成对成立** ✓
- 工具本体点名读数（`wm-awaited.sh --check --display :189`）：`WM_AWAITED=FAIL c1=no c2=no c3=no`、`WM_AWAITED_RC=1`。

### 3.4 `C2.3` 有 WM 腿 ⇒ **不误报缺失**（三条**独立**证据 ＋ 真判据 PASS）

**独立证据（不许用旧谓词自证；都是"真东西"的三条件读数）**：

| # | 条件 | 现场读数（逐字） |
|---|---|---|
| ① | root 上能解出**窗口 id** 且 ≠`0x0` | `_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae` |
| ② | 该 id **此刻在树里**，且 `WM_CLASS`／`_NET_WM_NAME` **可读非空** | `xwininfo -id 0x2000ae` ⇒ `Window id: 0x2000ae "Xfwm4"`；`WM_CLASS(STRING) = "xfwm4", "Xfwm4"`；`_NET_WM_NAME(UTF8_STRING) = "Xfwm4"` |
| ③ | `_NET_SUPPORTED` **非空** | `_NET_SUPPORTED(ATOM) = _NET_ACTIVE_WINDOW, _NET_CLIENT_LIST, …` ⇒ **`n=78`** |

**另两件独立旁证**：`xfwm4` 进程 `kill -0` **ALIVE**（pid `3117852`，起后按 PID 收）；其 stderr 有**真实启动告警** `xfwm4-WARNING **: 19:53:28.146: Failed to connect to session manager…`（`~/w108a/logs/xfwm189.log`）。

**读数（逐字）**：
```
2026-09-22 19:53:48 WM-AWAITED-PASS WM_AWAITED=PASS c1=yes c2=yes c3=yes c4=0 display=:189 elapsed_s=0.06 attempts=1
FORM=AFTER-WM branch=FELLTHROUGH(★正确：继续) rc=0
```
⇒ 真判据在**真 WM** 上 **`PASS`**、**未误报缺失** ✓（`c4=0` 是 `C4 重定父`**默认只报不判** —— 该等待发生在**应用起窗之前**，与 W102A 口径一致；**未加** `--require-reparent`，如实记。）

### 3.5 三条腿汇总（成对）

| 腿 | 输入 | 修前形态 | 修后形态 |
|---|---|---|---|
| ① 无 WM | `…no such atom on any window.` | **`:` ＝"前提成立"**，`rc=0` ⇒ **恒真** | **`exit 9`** ＋ `NOINFO wm-absent` |
| ② **同一台真 WM** | `…window id # 0x2000ae` | **`:`**，`rc=0`（⇒ **分不出**，见 §3.2） | **继续** `WM-AWAITED-PASS` |
| ③ 负控 | 空串 | `*)` ⇒ `exit 9`（证明形态本身**会**走 `*)`） | — |

**未做**：**未跑** `wm-leg198.sh` **整脚本**端到端（它会起应用，且会截断 `wm198.progress`）⇒ 本件只做**块级**两极化。**如实记**（见 §11）。

---

## §4 第四形态普查（`C3`；**只报不动**）

### 4.1 命令与留档（可复算）

| 文件 | 作用 | sha16 |
|---|---|---|
| `~/w108a/survey.sh` | **v1** 形状扫（含过宽的 `\|\| true`） | 现场留档 `~/w108a/survey.txt` |
| `~/w108a/survey2.sh` | **v2** 收窄到守卫位 | 留档 `~/w108a/survey.txt` ＋ `~/w108a/survey2-detail/` |
| `~/w108a/survey3.sh` | **v3** 语义收窄（形状 → 语义） | 留档 `~/w108a/survey3.txt` ＋ `~/w108a/survey3-detail/` |
| `~/w108a/survey4.sh` | **v4** "自报参数"判别式 | 留档 `~/w108a/survey4.txt` |
| `~/w108a/verify.sh` | **收口核对**（三形态活命中计数） | 留档 **`~/w108a/verify.txt`** |

**统一口径**（写在每个脚本头部）：根 = `$R` ＋ `$HOME` 脚本域（`~/w*/` 至两层等）；扩展名 `*.sh`／`*.bash`；排除 `**/.git/**`｜`**/upstream/**`｜`**/node_modules/**`｜`**/logs/**`｜`**/arm-logs/**`｜`**/gen/**`｜`**/obj/**`｜`**/bin/Debug/**`｜`**/bin/Release/**`；**行分类 = 首非空白字符 `#` ⇒ `COMMENT`（不计入缺口），否则 ⇒ `EXEC`**（保守口径）。`SURVEY_NFILES≈1242–1245`。

### 4.2 计数（**可执行／注释分开**）

**v1（形状扫，六种变形）**：

| 形态 | 正则 | EXEC | COMMENT |
|---|---|---|---|
| D1 glob 守卫 | `case "$V" in *WORD*)` | **333** | 5 |
| D2 命令替换非空 | `[ -n "$(cmd)" ]` | **92** | 2 |
| D3 字面空串测试 | `[ -z "" ]` / `[ -n "" ]` | **1** | 2 |
| D4 空模式 grep | `grep -q ''` / `""` / `-e ''` | **1** | 2 |
| D5 `\|\| true` 兜底 | `\|\| true` | **1516** | 9 |
| D6 awk/sed 恒真 | `awk '1'` / 无条件 `exit 0` / `sed -n p` | **0** | 1 |

**v2（把 D5 收窄到守卫位 `if <谓词> || true`）**：**`EXEC=0`／`COMMENT=1`** ⇒ `|| true` **在守卫位**是**干净**的。

> 🩸 **v1 的自伤（留档，不许悄悄改历史）**：v1 把 `|| true` 当一种形态 ⇒ **`EXEC=1516`** —— 它在本域是**通用错误抑制**惯用法（收尾/清进程/可选步骤），**不是**"前提守卫" ⇒ **毫无判别力**。⇒ v2 才收窄，并**保留** v1 计数在此。

**v3（语义收窄：形状 ∧ 承载）**：

| 编号 | 判别式 | EXEC |
|---|---|---|
| `A1` | glob 守卫 **且** 变量在同文件有 `VAR="$( … )"` 赋值 | **210** |
| `A2` | `A1` **且**"前提成立臂 = `:`" ⇒ **`D-G97` 精确形态** | **14** |
| `A3` | `[ -n "$(查询外部世界)" ]`（`xprop`/`xdpyinfo`/`xwininfo`/`xdotool`/`pgrep`/`ps`/`nm`/`find`/`ls`） | **41** |
| `A4` | `A3` **且** 带 `2>/dev/null`（真报错被丢） | **41** |

**`A2` 的 14 处 = 只 2 个不同站点 × 7 份副本**，**人读后 0 个真缺口**：
- `build/MilBridge/tools/t1c-census.sh:179`（＋6 份 witness/backup 副本）：`case "$_xcmd" in *Xvfb*) : ;; *) echo "⚠️ …" >&2 ;; esac`，而 `:178` = `_xcmd="$(tr '\0' ' ' < "/proc/$XPID/cmdline" 2>/dev/null || true)"` ⇒ **失败时 `_xcmd` 为空 ⇒ 走 `*)`**；且 `tr` 的失败文案**不含 `Xvfb`** ⇒ **(c) 中毒条件不成立** ⇒ **正确**。
- `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-mutation.sh:79`（＋6 份副本）：`case "$row_ok" in *"census GlyphRun×"*) : ;; *) tooth_releases=0 ;; esac`，而 `:75` = `row_ok="$(grep -a '^textbox-edit|' … blocks.txt 2>/dev/null | head -1)"` ⇒ **取不到 ⇒ 空串 ⇒ 不匹配 glob ⇒ 走 `*)` ⇒ `tooth_releases=0`（保守报红）** ⇒ **正确**。

**`A4` 的 41 处**：逐处读后**全部良性** —— 主力是 `check-applocal-sync.sh` 的 `[ -n "$(find "$d" -maxdepth 1 -name '*.runtimeconfig.json' -print -quit 2>/dev/null)" ]`（`find -print` **只打真命中**、错误走 stderr 被丢 ⇒ 空即无匹配）＋ 少量 `xdotool search --name <自己给的词>`（`xdotool` 的失败文案**不含**那个词）⇒ **(c) 不成立**。

**v4（"自报参数"判别式 = 本件提出的更准判据）**：命中散落在 `xwininfo -root -tree` 后**又经 `grep -oE '0x[0-9a-f]+'` 过滤**的族（`IsViewable` 那类）⇒ **被测词不是命令参数**、且中间管道已把失败文案滤掉 ⇒ (c) 不成立，**良性**。真判据样例（**不是**缺口）：`~/w101a/run-w101a-legs.sh:70` 与 `~/w93a/run-w93a-legs.sh:68` 的 `case "$WMCHK" in *"window id #"*) …` —— **它们测的是真东西**。

### 4.3 收口核对：三形态**全域可执行活命中 = 0**（`~/w108a/verify.txt`）

**命令**：`bash ~/w108a/verify.sh`（`VERIFY_NFILES=1245`）

| 形态 | `EXEC` | 逐处分类（**人读用途**） | **活装置缺口** |
|---|---|---|---|
| **形态1** `grep -q window` 在 xprop 管道上（`D-G89`） | 13 | 真判据 4（`w101a:66`／`w102a/run-legs:80`／`w93a:64`／`w93a/x-wm-test:36`，都已是 `grep -q 'window id #'`）＋ 正确 5（`w58a/bin/cell.sh:47,50,52`／`startdisp.sh:12,15`，走 `grep -c` 比 0）＋ **负控 fixture 3**（`w102a/old-predicate.sh:17,21,27`）＋ **自指 1**（`w108a/verify.sh:20`） | **0** |
| **形态2** 同谓词用在 `if !` 上（`D-G95`） | 2 | **正确 1**（`w58a/bin/cell.sh:46`：`if ! xprop … >/dev/null 2>&1 \` ＋ `:47` 比 `grep -c = 0` ⇒ 走 **rc＋计数**，不是文本）＋ **自指 1** | **0** |
| **形态3** `case … in *window*`（`D-G97`） | **1** | **自指 1**（`w108a/verify.sh:22` = 本仪器自己的 pattern 字面量） | **0** ✅ |
| 形态3b `case … *…window…*`（含真判据） | 8 | 全部是 `case "$ATM" in *"window id #"*) break` ⇒ **真判据** | **0** |

⇒ **`~/w63a/bin/wm-leg198.sh:17` 是形态3 唯一的活装置命中，已由本件修掉** ⇒ 修后**活命中 0**，其余 **6 处 = fixture 3／负控 1／自指 2**。

### 4.4 🆕 教训：**普查射程必须按"语义"复核，不能只按关键词或只按形状**

| 口径 | 能否看见 `case … *window*` 这一格 | 证据 |
|---|---|---|
| **关键词**（`_NET_SUPPORTING_WM_CHECK` / `grep -q window`） | **看不见** —— 该行**没有 `grep`**（W107A 的口径正是关键词） | `D-G89`／`D-G95` 的两次盘点都漏掉它 |
| **形状**（`case "$V" in *W*)`） | **看得见，但噪声吞信号** | `EXEC=333` → 承载 `210` → 精确形态 `14` → **人读后真缺口 0** |
| **语义三条件合取**（**本件提出的判别式**） | **看得见且可判** | `(a) 形状`（文本测试）**∧ (b) 承载**（被测串是**某命令的 stdout**）**∧ (c) 中毒**（那条命令**失败时也打含该关键词的文案**） |

⇒ 本缺陷**不是"形状"**，是**三条件合取**；**只有 (c) 是语义的**，而 (c) **必须知道"那条命令失败时打什么"**（机械不可判）⇒ **必须人读／或逐命令族建表**。这是本波**第三次**踩"按关键词认对象"（`D-G84`／`D-G93`／本条）。

---

## §5 `D-G97` 登记（判词逐字；**连续取号**，现场末号 = `D-G96`）

**取号依据**：现场 `grep -c '^### \`D-G96\`'` = **1**（存在）、`grep -c 'D-G97'` = **0**（未占用）⇒ 新号 = **`D-G97`**。

**判词逐字（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，标题行 ＋ 结构）**：

```
### `D-G97`（**装置缺陷 · 前提守卫恒真（glob 形态）＋ 普查射程缺口**）：`case "$wm" in *window*)` **被那条命令自己的失败文案命中** ⇒ "前提成立"守卫**恒真**；而且它正是"**用关键词做的普查**"机械上看不见的那一格
- 现象（车道 W108A，2026-09-22；来源 = 车道 W107A 全域重盘的新发现〔见 `D-G89` 条末 🆕 bullet〕＋本车道现场两极化复现）：`~/w63a/bin/wm-leg198.sh:17`（**改造前**）逐字为
  `case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac`
  而 `$wm` 来自同件 `:15` 的 `wm="$(DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | head -1)"`。
- **坏在哪（`xprop` 会"自报参数"）**：**无 WM** 时 `xprop` 的失败文案**打在 stdout、`rc=0`**（不是 stderr ⇒ `2>/dev/null` 挡不住），逐字 = `_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` ⇒ glob `*window*` 被**这句失败文案自己**命中（`any window.` 里的 `window`）⇒ 走 `:` ⇒ **"前提成立"守卫恒真** ⇒ 这一趟**自称"WM 腿"却静默跑在无 WM 上**（危害与 `D-G95` 同类：**静默跑错腿、输出看起来完全正常**；但**形态不同**）。
- 判定点：`~/w63a/bin/wm-leg198.sh:17`（**仓外**装置；仓内不存在此件）。
- **成对两极化（本车道现场，私有 `Xvfb :189`；**三条读数同趟取得**；修前形态用 `sed` 从备份抽 `:17` **原文**跑，不执行整脚本以免去跑应用）**：
  | 腿 | 输入 | 修前形态（glob 守卫） | 修后形态（真判据） |
  |---|---|---|---|
  | **① 无 WM** | `_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` | **走 `:` ＝"前提成立"**，`rc=0` ⇒ **恒真** | **`exit 9`** ＋ `NOINFO wm-absent（WM 腿的前提不成立）`（`wm_awaited_rc=1`）⇒ **真判据** |
  | **② 有 WM（同屏）** | `_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae` | 走 `:`，`rc=0` ⇒ **同一分支** | **继续**（`WM-AWAITED-PASS`，未误报缺失） |
  - **"恒真"的证法 = 两种相反输入给同一分支**：① 与 ② 一个"WM 不在"、一个"WM 在场"，修前形态**都走 `:`** ⇒ 它**分不出**这两件事（不是"判对了"，是"没在判"）。
  - **有 WM 腿的独立证据（不许用旧谓词自证）**：① root 上 `_NET_SUPPORTING_WM_CHECK` 解出 **`window id # 0x2000ae`**（≠`0x0`）；② `xwininfo -id 0x2000ae` **成功**（`"Xfwm4"`）且 `WM_CLASS = "xfwm4", "Xfwm4"`／`_NET_WM_NAME = "Xfwm4"` **可读非空**；③ `_NET_SUPPORTED` **非空 `n=78`**。`xfwm4` 进程按 **PID** 起、按 **PID** 收（事后核 `GONE`），`Xvfb :189` 同（不碰 `:0/:1/:10/:95/:96/:97/:99/:185/:186/:187/:188`）。
- **处置（本车道已修；`#50` 冻后）**：把 `:17` 那行 glob 守卫换成**真判据** —— 直接调用仓内现成工具 `build/MilBridge/tools/wm-awaited.sh --check`（件 `57a852f6948e1c67`，**只读、未改**），要 **`C1 ∧ C2 ∧ C3` 三条件全要**；工具**不可执行时大声失败**（`say` ＋ `exit 9`，**不静默放行、不回退旧形态**）；**退出码 `9` 与判词 `NOINFO wm-absent（WM 腿的前提不成立）` 与原形态逐字一致**。旧形态**只留注释**。机读成对读数：
  | 读数 | 值 |
  |---|---|
  | 件 sha16 | `371220d84d186e81` → **`80f694dc0000ab55`**（`~/w63a/bin/wm-leg198.sh`，`perm=644` 保持） |
  | `bash -n` | `rc=0` |
  | 可执行代码里 `*window*` 计数 | **0**（原始含注释 = 2；**剥注释后可执行 = 0**） |
  | 真判据工具（只读引用） | `57a852f6948e1c67` |
  - 输出**带时间戳**（`~/w63a/logs/wm-awaited-198.$(date +%Y%m%dT%H%M%S).txt`）而**不是固定名** —— 照 `D-G96` 的教训：固定名会被下一次运行截断，**为复核而重跑就把证据毁了**。**未跑整脚本**（它会起应用，且会截断 `wm198.progress`）。
- **普查射程缺口（本条的第二半，也是"为什么它能活到现在"）**：这个形态**在两次既有普查里都机械不可见**，因为两次都是**按关键词**扫的 ——
  - `D-G89` 的盘点口径 = `grep -rn '_NET_SUPPORTING_WM_CHECK'` ⇒ 该行**确实含**这个原子名（能被看见），但**判别的关键词是 `grep -q window`** ⇒ `case … *window*` 这一格**没有 `grep`** ⇒ 落在口径外；
  - `D-G95` 的处所清单按"同一个谓词用在 `if !` 上"枚举 ⇒ `case` 形态**不是 `if`** ⇒ 又落在口径外；
  - 本车道机械核（可复算，留档 `~/w108a/survey3.sh`／`survey4.sh`／`verify.sh`）：**按"形状"扫**虽能看见它，但**噪声吞掉信号** —— `case "$V" in *W*)` 形状全域 **`EXEC=333`**（其中"变量来自命令替换"**`EXEC=210`**、"前提成立臂是 `:`"**`EXEC=14`** 且**只 2 个不同站点、人读后**0 个**是真缺口）⇒ **形状也没有判别力**。
  - ⇒ **本条的判别式（比关键词、比形状都准）= 三条件合取**：**(a) 形状**（守卫是**文本测试**：glob／非空／`grep -q`）**∧ (b) 承载**（被测串是**某命令的 stdout**，不是程序自控变量）**∧ (c) 中毒**（那条命令**失败时也往 stdout 打含"被测关键词"的文案**）—— 三条件**全中**才恒真。本例 (c) 的机制 = `xprop <ATOM>` **自报参数**（打 `<ATOM>:  no such atom…`）。
- **教训（本波第三次踩"按关键词认对象"）**：**普查射程必须按"语义"（谁产生这个串、它失败时打什么）复核，不能只按关键词**（看不见）**或只按形状**（333 条噪声里挑不出 1 条）。同族：`D-G84`（判据射程错）／`D-G93`（按关键词**认错对象**）／`D-G89`（关键词恒真）。
- 交叉引用：`D-G89`（**同族本体**：`grep -q window` 恒真；其现场实例 `~/w53a/cell3.sh:26` 已由 `TASK-0703`／车道 W102A 修掉 `06c6d17fa9906761 → a358f6fd38b3b387`）｜`D-G95`（同一谓词用在 `if !` 上 ⇒ **反向恒假** ⇒ 静默跑错腿；本条是**第三种形态：glob 恒真**）｜`D-G96`（证据保全：本条修法的输出名带时间戳正是照它的教训）｜`D-G88`／`D-G93`／`D-G84`（同族判词不同）。
- 处置边界：本条**只改** `~/w63a/bin/wm-leg198.sh` **这一件仓外装置**（`D-G96` 提到的同件 `:12` `: > "$PROG"` 截断**未改** —— **不在本件授权内**，现场核**仍在**）；其余 6 处可执行命中 = **fixture 3／负控 1／自指 2**（`~/w102a/old-predicate.sh:17,21,27` 三行、`~/w103a/legs.sh:114`、`~/w108a/verify.sh:20,21,22`）⇒ **故意演示旧形态或本件仪器自身**，**一律不动**。
- 边界 / `NOINFO`：① 该装置在**仓外** ⇒ 仓内补不出牙（同 `D-G93`／`D-G95`／`D-G96` 的边界）；② **"全 `$HOME` 还有几处装置被'命令自报参数'命中"未逐处枚举完** —— 本车道只做了三形态定向扫描 ＋"自报参数族（`xprop`／`xdpyinfo`／`xwininfo`）"判别式（`~/w108a/survey4.sh`），**未**把该判别式推广到全部命令族（如 `xdotool`／`pgrep` 的失败文案是否含被测词）⇒ `NOINFO`；③ 本条**不改**任何既有编号的值与判词，**未**把任何红写成绿。
```

**⚠️ 幻影声明行防线（W107A 踩过）**：本条引用的每个编号**都先现场核实"已存在"**再写 ——
`grep -c '^### \`D-Gxx\`'` 逐号：`D-G84`=1｜`D-G88`=1｜`D-G89`=1｜`D-G93`=1｜`D-G95`=1｜`D-G96`=1；`D-G97` 写前 = **0**（本件新立）。
**`--emit` 后声明表里 `D-G97` 只有一行**（`ID D-G97 req=KD present=KD`）⇒ **无幻影**。

**体例遵守**：结构照 `D-G88`…`D-G96`（`### \`D-Gxx\`（**性质**）：标题` ＋ 现象／判定点／机械证表／性质／交叉引用／处置／处置边界／边界 `NOINFO`）。**只做加法**：未删任何既有号、未改任何既有号的值与判词、未把任何红改成绿。

**附带的一处"只加不改"修正**：`KNOWN-DEFECTS.md:2185` 的**段头**（登记批次索引）此前**停在 `D-G94`**（`D-G95`／`D-G96` 虽已进册但未进段头）⇒ 本次**追加** `#50 冻后第三/四/五笔`（`D-G95`／`D-G96`／`D-G97`）并**明写"只加不改"**。该行是**索引**、不是任何编号的**值与判词**。

---

## §6 `TASK-0703` 收口（**按先写判据**）

**先写判据（`C5.1`）**：→ **✅** ⇔ ①装置侧交件 ②两极化成立 ③**全域重盘可执行活命中 = 0** ④缺口已登记 `D-G97`。

| 判据 | 满足？ | 依据（artifact ＋ 字段 ＋ sha16） |
|---|---|---|
| ① 装置侧交件 | ✅ | `build/MilBridge/tools/wm-awaited.sh`（**`57a852f6948e1c67`**，`20,399 B`）**存在且 `-x`**；本件**只读引用、未改**（sha16 改前改后同值） |
| ② 两极化成立 | ✅ | §3：修前 `:`／`rc=0`（恒真）**vs** 修后 `exit 9`（真判据）**vs** 有 WM `WM-AWAITED-PASS`；**同一输入两种形态两个分支** ＋ **两种相反输入同一分支**（`~/w108a/logs/C2.1-*`／`C2.2-*`／`C2.3-*`） |
| ③ 全域重盘可执行**活装置**命中 = 0 | ✅ | §4.3 `~/w108a/verify.txt`：三形态 `EXEC` 逐处分类后**活装置缺口 0**；其余 6 处 = fixture 3／负控 1／自指 2 |
| ④ 普查射程缺口已登记 `D-G97` | ✅ | §5；册 `499c46ce7954d52f`；`--emit` 有 `ID D-G97` |

⇒ **四条全满足** ⇒ **`TASK-0703` 状态位 `🟡` → `✅`**（判词见 §7）。

### 6.1 📌 口径句（**在做完 §2–§4 之后**才写；`C5.3`）

> **fixture／负控／自指不计入"活装置缺口"** —— fixture 与负控**故意**演示旧形态（`~/w102a/old-predicate.sh:17,21,27`、`~/w103a/legs.sh:114`），自指 = **普查仪器自己的 pattern 字面量**（`~/w108a/verify.sh:20,21,22`）⇒ 三者都**不是**"装置里还挂着一个恒真守卫"。**判定"活装置"必须人读用途**，不能只看命中数。

### 6.2 如实记：本件**没有**为了让 `TASK-0703` 变绿而放宽任何口径

- ③ 的判据**先写**为"可执行活命中必须为 0"，**未**改成"可执行命中为 0"（后者会因自指/负控而永不为 0，反而**假红**）；也**未**把 fixture 排除**当作**放宽 —— 排除的是**用途为"故意演示"**的件，且**逐处点名**、**逐处给理由**。
- **`D-G97` 的修法改了 `~/w63a` 里的一件**：这是**新授权**（任务书写明"修 `~/w63a/bin/wm-leg198.sh:17`"），**不是**放宽判据。

---

## §7 地图 / 册 / 声明表：改了哪几件（before → after）

| 件 | before sha16 | after sha16 | 改了什么 |
|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `b79b8cd455746313` | **`499c46ce7954d52f`** | ＋`D-G97` 整条（§5）＋段头 `:2185` 追加三笔批次索引 |
| `docs/ROUTES.md` | `abac9ba3103da336` | **`67e2f06487eb8280`** | ①`:375` 状态位 `🟡`→**`✅`**（**行锚定**）②末尾新增 **§15e**（13 行，`439`→`452` 行） |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `5cddd9ad488e959a` | **`05169ff42874a834`** | `--emit` 重生成（`132` → **`133`** 条；内容 diff 见 §7.2） |
| `build/MilBridge/W108A-report.md` | —（新建） | 见 §12 | 本报告 |
| **仓外** `~/w63a/bin/wm-leg198.sh` | `371220d84d186e81` | **`80f694dc0000ab55`** | §2 的 glob 恒真守卫 → 真判据 |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `1f4189c1257737a9` | **`1f4189c1257737a9`**（**逐位未动**） | **未动**（冻结基线，`C7.3`） |
| `docs/CURRENT-STATE.md` | `1ff381a9be8c3c7a` | **`1ff381a9be8c3c7a`**（**逐位未动**） | **未动**（含 `:9` 机器行） |
| `handoff.md` | `e4dc264200b421d0` | **`e4dc264200b421d0`**（**逐位未动**） | **未动** |

### 7.1 `ROUTES.md` 状态位改动（逐字，**行锚定**）

```diff
-- `TASK-0703` [Next] 🟡 **修掉"等 WM 起来"的恒真判定**（`D-G89` 的落地，波 `#51`）：
+- `TASK-0703` [Next] ✅ **修掉"等 WM 起来"的恒真判定**（`D-G89` 的落地，波 `#51`）：
```
**防"吞下一行"的机械复核（W107A 踩过）**：改后 `wc -l` = **`439`**（**与改前同值**）⇒ **未吞行**；`sed -n '376p'` 仍是原来那行 `  - \`TASK-0703\` 🆕 **装置侧已由车道 W102A 交件…` ⇒ **下一行健在**。

### 7.2 声明表 diff（只做加法的机证）

`--emit` 内容里含**生成时间戳**与 `DECL-ANCHORS` 行 ⇒ 用**去时间戳/锚点**后的 `diff`：
- 与**改前**比：**`＋1` 行、`0` 删、`0` 改**（唯一新增 = `ID	D-G97	req=KD	present=KD`）
- 条数：`132` → **`133`**；`DEFREG_EXTRA` 三件（`KRJ`/`KRF`/`KRP`）**未变**

### 7.3 `ROUTES.md` §15e 新增内容（13 行，逐条）

1. **`TASK-0703` → ✅ 已收口**（状态位改法＋四条判据逐条满足 ＋ 三条两极化读数逐字）
2. 📌 **口径句**（fixture／负控／自指不计入活装置缺口）
3. 🆕 **`D-G97` 摘要**（三形态对照 ＋ 修法 sha16 成对 ＋ 带时间戳输出）
4. ⚠️ **教训**（按语义而非关键词/形状复核 ＋ 三条件合取 ＋ 同族）
5. 📌 **parity 两件维持"不推"口径固定**（见 §8）
6. **`fp_inputs` 影响**指向本报告 §9

---

## §8 parity 两件：维持"不推"（口径固定；`C6`）

| 件 | 大小 | 推不推 | 依据（文件 ＋ 行） | 理由 |
|---|---|---|---|---|
| `tests/parity/**/u14/linux-results-u14.json` | **118.2 MB** | **不推** | **`.gitignore:47`** 明确排除 | ①被 gitignore 排除；②**超 GitHub 单文件 `100 MB` 硬限** |
| `tests/parity/**/layout-b34/windows-results.json` | **53.0 MB** | **不推** | **`.gitignore:51`** 明确排除 | ①被 gitignore 排除；②b34 的**读者都走仓内派生件** |

- 依据来源 = 车道 W107A 报告 §8.3 点名（**未推**）＋ 主控裁定（**维持不推**）；本件**未推**这两件、**未改** `.gitignore`。
- **本件把这条口径写进地图**（`ROUTES.md` §15e 第 5 条）⇒ 免得后人反复复议。

---

## §9 `fp_inputs` 影响判断（`C9`；**机械证**）

**方法**（比"眼估"硬）：把 `close-wave.sh` 的 `fp_inputs()` **函数体真取出来**跑 ——
- `fp_inputs` **本身**返回的是**指纹**（尾管道 `xargs sha256sum | sha256sum`），所以取**覆盖面**要**把尾管道换掉**：`sed 's/} | LC_ALL=C sort .*$/}/'`
- 覆盖面件数：**`148`**（`~/` tmp 留档）
- `close-wave.sh` sha16 = **`f440ccdb4e29a942`**（与 W102A／W96A 记的一致 ⇒ 未被本件与邻道改动）

**逐件命中计数（本件编辑/新建的件）**：

| 件 | `in_fp_inputs` |
|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **0** |
| `docs/ROUTES.md` | **0** |
| `build/MilBridge/tools/defect-registry-declared.tsv` | **0** |
| `build/MilBridge/tools/defect-registry-check.sh` | **0** |
| `build/MilBridge/W108A-report.md` | **0**（新建，且不在覆盖面） |
| `docs/CURRENT-STATE.md`／`handoff.md`／`ACCEPTANCE-BASELINE.md` | **0**（本件本来就没动它们） |

⇒ **本件对 `inputs_fp` 零影响**（覆盖面里 `build/MilBridge/tools/` 只收 `*.py`／`tline-gate.sh`／`known-red.json`，**不收** `defect-registry-*`／`KNOWN-DEFECTS.md`／`ROUTES.md`）。

**⚠️ 现场 `inputs_fp` 真值（如实报，`C9.2`）**：
```
INPUTS_FP_NOW = 21b720ea4ea5693214c97e91a959cb3d7d8928cfd3f943300eb9cd462faeb9f8
```
**它 ≠ `#50` 冻结值 `ee543f44b1090c74…`** —— 但**不是本件造成的**：本件**全部**编辑件在覆盖面里**命中 0**（逐件如上表）⇒ 指纹变动只能来自**覆盖**面内的件。**最可能 = 邻道在飞产品改动**（W101A／W106A 正在改 `src/WpfGfx.Linux.Native/**` 与 `build/PresentationFramework.Linux/**`，二者**都在** `fp_inputs` 覆盖面内）。**按任务书口径：如实说明，不当异常**；**本件不主张**该值为绿或红 —— 它是**当下现场值**（同 `D-G92` 的口径：`pf` 一格不作漂移判据）。**未重钉世代**（`repin-generation` 属收尾链，本件**不跑**）。

---

## §10 `DEFREG` 两条机读行（现场跑两遍，逐字相同）

```
DEFREG_DECL=n=133 route_ids=133 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=499c46ce7954d52f CS=1ff381a9be8c3c7a HO=e4dc264200b421d0 AB=1f4189c1257737a9
DEFREG_EXTRA=KRJ=8a0c0f221e35f42b KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=133 route_ids=133（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
RC=0
```
- **`DEFREG=PASS declared=133 route_ids=133`** ✅｜**`DEFREG_DECLDRIFT=0`** ✅｜**`rc=0`** ✅（**连跑两遍逐字相同**）
- 改前基线 = `declared=132`（本件 ＋`D-G97` 一条 ⇒ `133`）
- **`AB` 锚仍 `1f4189c1257737a9`** ⇒ 冻结基线**逐位未动** ✅（`C7.3`）
- `KD=499c46ce7954d52f` = 本件改后的册 sha16（**与 §7 表一致**，自洽）

---

## §11 `NOINFO` ／ 未做（如实划；既不算绿也不算红）

1. **`NOINFO`：未跑 `wm-leg198.sh` 整脚本端到端。** 硬理由：它会去**起应用**（本件纪律禁），且 `:12` 的 `: > "$PROG"` 会**截断** `wm198.progress`（`D-G96` 的证据保全缺陷）⇒ 本件只做**块级**两极化（`sed` 抽 `:17` 原文 ＋ 抽 `:31-44` 真判据块）。**取不到的读数 = "整脚本在真 WM 上跑通到 `run`"**。
2. **`NOINFO`：`C4 重定父` 未判。** 现场 `c4=0`，但 `wm-awaited.sh` 的默认判决 = `C1∧C2∧C3`（`C4` **只报不判**，因该等待发生在**应用起窗之前**）⇒ 本件**未加** `--require-reparent`。**未把 `c4=0` 当红**（那是**设计如此**）。
3. **未做：`D-G97` 的"自报参数"判别式未推广到全部命令族。** 只覆盖 `xprop`／`xdpyinfo`／`xwininfo`；**`xdotool`／`pgrep`／`find` 等族的失败文案是否含被测词未逐族建表** ⇒ 记为 `NOINFO`（已写进 `D-G97` 边界 ②）。
4. **未做：`D-G96` 的 `~/w63a/bin/wm-leg198.sh:12` 截断行未修**（**不在本件授权内**，现场核**仍在**）。
5. **未做：未改 `docs/CURRENT-STATE.md`／`handoff.md`**（判据只要求"未动"；本件判为**不动**更稳 —— 二者 `D-G` 覆盖只到 `D-G61`，`D-G62+` 一贯 `req=KD`，**无需**动）。
6. **未做：`TASK-0704` 未复看**（W107A 已标 ✅；本件未重盘它那四处）。
7. **未做：`~/netTest/GitProj/WPFOnLinux` 里 `tests/parity/**` 两件未推**（§8，口径固定）。

**🩸 自伤／需人复核之处（留档，未隐藏）**：
1. **v1 普查把一个过宽的形态（`|| true`）当"永不失败的守卫"** ⇒ `EXEC=1516`**毫无判别力**。**已改正**：v2 收窄到守卫位（`EXEC=0`），并**在脚本头与 §4.2 保留 v1 计数**（不许悄悄改历史）。
2. **第一次两极化测试误用 `bash -c` 跑形态** ⇒ 子 shell **看不到 `wm`／`say`** ⇒ 读出**假结果**（`say: 未找到命令` ＋ 走 `*)`）。**已改正**：改用**同 shell `eval`**，并**加两条对照**（空串 ⇒ `*)`；真 WM ⇒ `:`）—— 这**恰好**证明"恒真"结论**不是**仪器假象。**判据未动**。
3. **修法的输出名**：初版写成**固定名** `wm-awaited-198.txt` ⇒ **本身会重犯 `D-G96`**（证据活不过一次重跑）。**已改正**为**带时间戳**（§2.1 diff 可见），并**在注释里写明理由**。
4. **我自己写的普查脚本会命中自己**（`verify.sh:20,21,22` 的 pattern 字面量）⇒ 已**逐处点名**为"自指"并**排除**（**不是**靠放宽口径排除，是靠**人读用途**）。

---

## §12 推送（第六笔）

见 §12 后续小节（推送后在下方**追加**实际执行读数）。本报告自身的 `sha16` 亦在推送前现场重算后追加。

---

## §13 ≤6 行大白话小结

1. `~/w63a/bin/wm-leg198.sh:17` 那个"检查有没有 WM"的守卫是**假检查**：xprop 找不到东西时会把"没找到"这句话打在标准输出上，句子里带 `window` 一词，正好被 `*window*` 匹配上 ⇒ 分支**永远当作"有 WM"**，那一趟自称"WM 腿"其实没 WM。
2. 我把它换成仓内现成的真判据（要求三件事同时成立：能解出窗口号、那个窗口此刻真在、WM 属性表非空），**退出码和判词跟原来一模一样**，坏形态只留注释。件 `371220d84d186e81 → 80f694dc0000ab55`。
3. **两极化成立**：同一句话，改前走"前提成立"、改后走 `exit 9`；反过来在**真 WM** 上，改前改后走的是**同一个分支**（这正说明它原来**没在判**），改后正确放行不误报。
4. **第四形态我扫了个遍**：按"形状"扫出 333 条噪声，一层层收窄到 14 条候选、人读完**真缺口 0**；加上既有三形态，**全域"活装置"命中 = 0**（剩下 6 处是故意演示的 fixture 和我的仪器自己）。**教训**：查这类毛病**不能按关键词或形状**，得问"这串是谁产生的、它失败时打什么"。
5. 新登记 **`D-G97`**（第三种形态），`TASK-0703` 按先写判据**标 ✅**，`ROUTES.md` 只改状态位（行数不变、没吞行），冻结基线一字未动。
6. `DEFREG=PASS declared=133 route_ids=133`、`DECLDRIFT=0`；`fp_inputs` **零影响**（我的件全在覆盖面外）；`inputs_fp` 现值 ≠ `#50` 冻结值是**邻道在飞产品改动**所致，**不是我**。
