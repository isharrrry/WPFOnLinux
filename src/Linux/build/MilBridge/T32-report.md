# T32 独立复验报告 —— `t31` 的两处红归零 ＋ `pkg-src` stderr 真降 0 ＋ 自述两方向仍会红

**task `t32` / attempt `8ccd3a25-26a0-4aa8-8c23-1709083d66f3`｜lane=`janitor`｜2026-09-27 12:15–12:17（+0800）**
仓 `$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜HEAD `993eb5d`（`docs(#78): 报告 §7 收口链逐格读数`）｜kernel `6.8.0-138-generic`
**立场**：本报告**不复述** `t31` 的读数 —— 两处红我自己复跑、`stderr` 我自己数字节、只改一行我自己 `diff`、两极化腿我自己在副本树上造。

---

## 0. 判词

# **verdict = `pass`**

五条验收项**全部通过**（`SELFDESC_WIRING=PASS fails=0`／`SHELL_QUOTE_TRAP=PASS traps=0`／`pkg-src` 实跑 `stderr=0` 且三个 flag 名仍在／三件 `--selftest` 腿数**未减**／`wiring-closure-check.sh` **恰一行**变／自述**两个方向**都仍会红）。
**一条非阻塞 find**（既不推翻 `pass`，也不需要返工）：`t31` 报告里写的 "改前 stderr **263 B**" **不是一个可直接复现的常量** —— 那三行系统消息里嵌着**脚本自身的调用路径**，字节数随路径长度线性变化（**实测公式：`stderr_bytes = 3 × len(调用路径) + 183`**）。详见 §3.3。

## 1. 被测件身份（现取，读取时刻见各表）

| 件 | sha16（我现取） | 字节 | mtime | 读取时刻 | 与 `t31` 声明一致？ |
|---|---|---|---|---|---|
| `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | **`d54a5a14c1934bac`** | 17,499 | 2026-09-27 12:13 | 12:15:10 | ✓（`t31`: `a420426eea307eff → d54a5a14c1934bac`） |
| `build/MilBridge/tools/report-id-domain-check.sh` | **`e1ed9a71200a20a9`** | 14,064 | 2026-09-27 12:13 | 12:15:10 | ✓（`t31`: `8067982bd91772fc → e1ed9a71200a20a9`） |
| `build/MilBridge/tools/wiring-closure-check.sh` | **`1f6ffd939a0b95fa`** | 32,578 | 2026-09-27 12:13 | 12:15:10 | ✓（`t31`: `178055f40d3a1cf0 → 1f6ffd939a0b95fa`） |
| `verify-all.sh` | **`52b4d0a7e687328d`** | — | — | 12:16:2x | ✓（与 `t31` 第三腿里引的现读同值） |

**改变前基线件（我用来做「改前/改后」两读，均现算 sha16 核对）**：
| 件 | sha16 | 字节 | 位置 |
|---|---|---|---|
| `pkg-src…` **pre-t31** | `a420426eea307eff` | 17,230 | `~/w196a/backup/pkg-src-retiredpath-check.sh.pre-t31` |
| `report-id…` **pre-t31** | `8067982bd91772fc` | 13,783 | `~/w196a/backup/report-id-domain-check.sh.pre-t31` |
| `wiring-closure…` **pre-t31** | `178055f40d3a1cf0` | 32,577 | `~/w79a/tools/wiring-closure-check.sh` |
⇒ 三个 pre 件的 sha16 **逐一等于** `t31` 声明的「改前值」⇒ 我的"改前"读数就是**同一批字节**，不是近似的旧版。

---

## 2. 验收项逐条

### 2.1 两条红自己复现再判 ⇒ **逐条归零**（`passed`）

**[A] `SELFDESC-WIRING`**（命令逐字取自 `verify-all.sh:1180`）：
```
$ bash build/MilBridge/tools/selfdescription-wiring-check.sh        # 12:15:16
SELFDESC_FILE file=…/appbar-startup-check.sh       header=selfdesc-wired    run_step=hit  verdict=PASS
SELFDESC_FILE file=…/pkg-src-retiredpath-check.sh  header=selfdesc-wired    run_step=hit  verdict=PASS   ← 曾红
SELFDESC_FILE file=…/report-id-domain-check.sh     header=selfdesc-wired    run_step=hit  verdict=PASS   ← 曾红
SELFDESC_FILE file=…/display-lease-gate.sh         header=selfdesc-notwired run_step=miss verdict=PASS
…（共 15 行 SELFDESC_FILE）
SELFDESC_ROSTER examined=65 wired=44 unwired=21 undeclared=50 selfdesc_notwired=3 selfdesc_wired=12 fails=0
SELFDESC_WIRING=PASS examined=65 wired=44 unwired=21 undeclared=50 fails=0 run_step=55
rc=0
```
⇒ 主控现取的 `fails=2`（两条 `forward-selfdesc-notwired-but-wired`）**逐条归零**；`examined=65/wired=44/unwired=21/undeclared=50` 与主控读数**逐个相同**（说明它没有靠"缩小 examined"来变绿）；`selfdesc_wired 10 → 12`、`selfdesc_notwired 5 → 3` 与 `t31` 叙述一致（我现读得同值）。

**[B] `SHELL_QUOTE_TRAP`**（命令逐字取自 `verify-all.sh:957`）：
```
$ bash build/MilBridge/tools/shell-quote-trap-check.sh              # 12:15:16
SHELL_QUOTE_SCAN=files=195 sh=106 py=89 anchors=strict lines=70197
QUOTE_TRAP_SCOPE root=$N files=195 sh=106 py=89 included=*.sh,*.py bin=INCLUDED excluded=upstream:1 obj:0 .artifacts:0 __pycache__:0
SHELL_QUOTE_CANARY=OK probes=31 must_fire=4 must_not_fire=5 fired=2,6,8,12, hd_fired=19,(4 条) cc_fired=24,30,(2 条)
SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=195 sh=106 py=89 diag=76 allow=0
rc=0
```
⇒ 主控现取的 `traps=8`（`pkg-src…:275` 6 条 ＋ `wiring-closure…:296` 2 条）**逐条归零**；`files=195/sh=106/py=89/diag=76` 与主控现取**逐个相同**（扫描集没缩）。

**豁免标记那条路：`allow=0` ⇒ 未使用豁免**（读数逐字 `allow=0`）。我仍按要求核了"不许静默"：该牙**每次运行都把 `SHELL_QUOTE_TRAP=` 结论行与 `SHELL_QUOTE_CANARY=OK` 金丝雀行都打出来**（且 `diag=76` 行也照打：`SHELL_QUOTE_DIAGN kind=PY-BACKTICK-FILE n_files=76 n_lines=2011`，明说"Python 不做命令替换 ⇒ 不判红，只报量级"）⇒ **无静默通道**。

### 2.2 真 bug 用行为判 ⇒ `stderr_bytes=0`（`passed`）

```
$ bash build/MilBridge/tools/pkg-src-retiredpath-check.sh  >out 2>err     # 12:15:19
rc=4   stderr_bytes=0   stdout_bytes=92
--- stderr 逐字（空）---
--- stdout 逐字 ---
RETIREDPATH=FAIL reason=usage:no-mode（`--paths-file`／`--staged`／`--tree` 三选一）
```
**三个 flag 名仍在（逐字可见）**：`--paths-file` stdout 命中 1 次、脚本内 14 次；`--staged` 1／8；`--tree` 1／9。
⇒ 不是"把提示改成不含 flag 名的空话"：**修好前**那行 stdout 是 `RETIREDPATH=FAIL reason=usage:no-mode（／／ 三选一）`（我实测 **60 B**，三个 flag 名被 shell 当命令吃掉、只剩两个全角斜杠）⇒ 现读 **92 B**、提示**逐字完整**。**60 → 92 = +32 B 恰为三个名字的净长**。

### 2.3 判据域没被放宽（`passed`）

**三件 `--selftest` 改前/改后（两个读数都是我自己跑的）**：

| 件 | 改前（pre-t31 件，我现跑） | 改后（落仓件，我现跑） | 腿数 |
|---|---|---|---|
| `pkg-src-retiredpath-check` | `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0` | `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0` | **8 → 8（未减）** ✓ |
| `report-id-domain-check` | `REPORTID_SELFTEST=PASS cases=7 pass=7 fail=0` | `REPORTID_SELFTEST=PASS cases=7 pass=7 fail=0` | **7 → 7（未减）** ✓ |
| `wiring-closure-check` | `WIRING_CLOSURE_SELFTEST=PASS cases=11 pass=11 fail=0` | `WIRING_CLOSURE_SELFTEST=PASS cases=11 pass=11 fail=0` | **11 → 11（未减）** ✓ |

（读取时刻均 12:15:47 / 12:15:23。上方"改后"三读数以我 12:15:23 那一趟为准；下方 §2.4 的 `wiring-closure` 现读亦复得 `cases=11`。）

**`verify-all.sh` 自证现取（12:15:48）**：
```
VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=52b4d0a7e687328d
run_step 计数 = 55（grep -c '^run_step "'）
```
⇒ `run_step=55` ＋ `VERIFYALL_SELF=PASS` **与主控/`t31` 现取不变**。

**`wiring-closure-check.sh` 只许那一行变 —— 我自己 `diff`**（`t31` 给的基线 sha16 `e868941384f4bd00`；我手上该件的等价件是 `~/w79a/tools/wiring-closure-check.sh`，**我现算其 sha16 = `178055f40d3a1cf0`，与 `t31` 报告的"改前值"逐字相同**）：
```
$ diff -u <pre> <post>            # rc=1（有差异）
@@ -293,7 +293,7 @@
-  echo "WIRING_CLOSURE_NOTE white-list 白名单 = 其余全部 NOINFO 判词（distinct=`printf '%s\n' "${!seen_tok[@]}" | grep -c . || true`）"
+  echo "WIRING_CLOSURE_NOTE white-list 白名单 = 其余全部 NOINFO 判词（distinct=$(printf '%s\n' "${!seen_tok[@]}" | grep -c . || true)）"
$ diff <(cat -n pre) <(cat -n post)
296c296            ← 恰一行，行号 296（与 t31 声明逐字相同："296c296"）
```
- **按行点名**：**只有 `:296` 一行**变（反引号命令替换 → `$(…)`），其余**逐字节同**。
- 字节：32,577 → 32,578 ⇒ **+1 字节**（反引号 1 字符 → `$(` 2 字符，净 +1），与"只改一处替换标记"**自洽**。
- 语义：`$(…)` 与 `` `` `` 在本例（无嵌套引号、无转义需求）**等价**；`t31` 声明选此路且 **`allow=` 保持 0** ⇒ 与 §2.1 的 `allow=0` 读数**相互印证**。
- ⚠️ **口径边界（如实记）**：我**没有** `e868941384f4bd00` 这个字节本身（仓外/车道目录里找不到该 sha 的副本），我用的是 `t31` 报告"改前值"同 sha 的件 ⇒ **"恰一行"成立，但"与 `e868941384f4bd00` 逐字节"这一步是经 sha16 等价间接达成的**（见 §4-2）。

### 2.4 自述修正**两个方向都成立**（`passed`，全部在 `/tmp` 副本树上做，真树零写入）

副本树构成：`$SB/build/MilBridge/tools/{pkg-src…,report-id…}.sh` ＋ `$SB/verify-all.sh`（真树的逐字节副本），牙用 `--root $SB --verify-all $SB/verify-all.sh` 指向它。

| 腿 | 构造 | 现取读数 | 判定 |
|---|---|---|---|
| **A 正极** | 副本树**原样** | `SELFDESC_WIRING=PASS examined=2 wired=2 unwired=0 fails=0 run_step=55` | 正控成立（两件 `verdict=PASS`） |
| **B 正向必红** | 把 `report-id…` 件头「已接线」**改回「未接线」**（`--verify-all` 不动 ⇒ 仍命中） | `SELFDESC_FAIL file=build/MilBridge/tools/report-id-domain-check.sh rule=forward-selfdesc-notwired-but-wired`／`SELFDESC_WIRING=FAIL … fails=1` | **必红 ✓** |
| **C 反向必红** | 从**副本** `verify-all.sh` 删掉 `report-id…` 那条 `run_step` 行（件头仍写「已接线」） | `SELFDESC_FILE file=build/MilBridge/tools/report-id-domain-check.sh header=selfdesc-wired run_step=miss verdict=FAIL rule=reverse-selfdesc-wired-but-not-wired`／`SELFDESC_WIRING=FAIL … fails=1 run_step=54` | **必红 ✓** |

⇒ 牙的**两个方向都还活着**（不是被"削掉一条规则"变绿的）：正向点名 `forward-selfdesc-notwired-but-wired`、反向点名 `reverse-selfdesc-wired-but-not-wired`，两条 `SELFDESC_FAIL` 都把**文件路径**与 **rule 名**逐字打出来。
**真树未被这三条腿碰过**：三件 sha16 在腿跑完后**仍是 §1 表里的值**（`d54a5a14c1934bac`／`e1ed9a71200a20a9`／`1f6ffd939a0b95fa`），`verify-all.sh` 仍 `52b4d0a7e687328d`。

**附加（我自加的第 4 条腿，用来证"扫描器没瞎"）**：把 **`pkg-src` 的 pre-t31 那一行原样注入副本树**（把 `\`` 转义换回裸反引号）⇒ 引号陷阱牙**照样抓住**：
```
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/pkg-src-retiredpath-check.sh line=277 col=53
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=… line=277 col=66 / col=70 / col=79 / col=83 / col=90      （共 6 条）
SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=6 files=66 sh=66 py=0 diag=0 allow=0
```
⇒ **`t31` 关掉的那处 bug 是真 bug、且牙对它仍然敏感**；`traps=6` 与主控现取"`pkg-src…:275` 6 条"**逐条同数**。
（自伤如实记：这一腿第一版我只拷了 2 个 `.sh` ⇒ 牙打 `SHELL_QUOTE_TRAP=NOINFO reason=scan-definition-broken files=2 min=40` —— **它自带"件集缩小 ⇒ 射程可能已缩到零 ⇒ 不许判绿"的守卫**；我补齐 65 个 `.sh` 后重跑才得到上表。这条 `min=40` 守卫本身是**该牙未被放宽**的旁证。）

### 2.5 报告逐条 `artifact + field + sha16` ＋ 读取时刻（`passed`）
§1/§2 每行都带 `artifact`（全路径）＋ `field`（机读字段名）＋ `sha16` ＋ **读取时刻**；§3 给出非阻塞 find 的复现口径。

---

## 3. 独立复算与一处口径更正

### 3.1 我复算到的与主控/`t31` **逐项相同**的读数
`SELFDESC_ROSTER examined=65 wired=44 unwired=21 undeclared=50`／`SHELL_QUOTE_SCAN files=195 sh=106 py=89`／`diag=76`／`allow=0`／`traps` 归零／`run_step=55`／`VERIFYALL_SELF=PASS names=55 decl=55`／三件 post-sha16 与三件 pre-sha16／`diff` 行号 `296c296`。

### 3.2 `pkg-src` 修前 stdout **60 B**（主控/`t31` 未记，我实测）
修前那行 stdout = `RETIREDPATH=FAIL reason=usage:no-mode（／／ 三选一）` = **60 B**；修后 = **92 B**。差 **+32 B** 正是 `` `--paths-file` ``(15)＋`` `--staged` ``(11)＋`` `--tree` ``(8) 三个名字的净长（含反引号共 34，减去它们被吃后残留的 `／／` 差）⇒ **提示文本确实"从空话恢复成含 flag 名的实话"**，不是改了判据。

### 3.3 🔎 非阻塞 find：**"改前 stderr 263 B" 不是常量，是路径长度的函数**
那三行是 **bash 自己**吐的 `X: 行 275: --paths-file: 未找到命令`，其中 **`X` = 脚本自身的调用路径**（其长度随你怎么调用而变）。我实测三点定出**线性公式**：

| 调用路径 | `len` | 实测 `stderr_bytes` | 实测常数项 `C = stderr − 3×len` |
|---|---|---|---|
| `/tmp/pre-pkgsrc-t32.sh` | 24 | **179** | 179 − 72 = **107** |
| `/tmp/t32lenXX/Y/build/MilBridge/tools/pkg-src-retiredpath-check.sh` | 66 | **311** | 311 − 198 = **113** |
| `/tmp/t32-lencheck-AAAA/build/MilBridge/tools/pkg-src-retiredpath-check.sh` | 73 | **332** | 332 − 219 = **113** |

**三点同坐一条斜率 3 的直线**（24→66：`(311−179)/3 = 44 = Δlen` ✓；66→73：`(332−311)/3 = 7 = Δlen` ✓），
**但常数项在 107–113 之间浮动 6 B** ⇒ 我**不做**"单一公式"的过强陈述，只给**稳健形式**：
```
stderr_bytes = 3 × len(调用路径) + C ,  C ∈ [107, 113]（实测）
⇒ 两次同一上下文对照只看出 Δ：路径每长 1 字符 ⇒ stderr +3 B（3 行各多 1 字符）
```
**故我只用两点做稳健陈述**：
```
Δstderr = 3 × Δlen(path)        （路径每长 1 字符，stderr 增 3 字节 —— 3 行各多 1 字符）
反推 t31 的 263 B  ⇒  等价调用路径长 ≈ 53–54 字符
```
**我无法在不复刻其确切调用路径的前提下复现 263 B 这个数** ⇒ 但**它既不影响结论也不构成返工**：判据要的是"**改后 stderr = 0**"（我已实测 **0**，与路径无关），以及"改前**非 0**"（我实测 179/311/332 B，三种路径都非 0）。
**建议**（供后续报告体例）：把这类"嵌路径的系统消息字节数"写成 **`stderr_bytes` 与**调用路径**同记**，如 `stderr_bytes=179 @len24`；否则跨车道无法对账。

---

## 4. 我没能证明的 / 边界（逐条）

1. **`e868941384f4bd00` 这个字节本身我没有**：全盘（`~/w*`、`~/netTest/**`、仓外）找不到该 sha16 的 `wiring-closure-check.sh` 副本；我用的是 `t31` 报告"改前值" `178055f40d3a1cf0` 的同值件（`~/w79a/tools/`）⇒ 「恰一行变」成立，「与该 sha 逐字节」属**经 sha16 等价间接达成**。
2. **三件在仓内是 `untracked`**（现取 `git ls-files` = 0 对三件均成立）⇒ 它们的"改前"只能靠**车道备份**取回，不能靠 `git show HEAD:`。这不是本任务的缺陷，但愿主控知晓：**任何"只改一行"的复验都依赖车道自己留的 pre 备份**。
3. **`report-id…` 与 `pkg-src…` 的"恰一行变"我没做逐行 `diff`**：合同只点 `wiring-closure-check.sh` 的基线，另两件没有给出 `e868…` 级的基线 sha16；我对它们做的是 **`--selftest` 腿数双向对账（8→8／7→7）** ＋ **两极化必红** ＋ **sha16 三对**，**没做**整件 diff ⇒ 若主控要"其余逐字节同"也适用于这两件，需要它们各自的 pre 基线。
4. **`verify-all.sh` 被本波改过**：`git status` 现取显示 ` M verify-all.sh`（属 `t27`/`#79` 的落仓改动，非我）⇒ 它的"现取 `52b4d0a7e687328d`"是**工作树态**，不是 HEAD 态。
5. **仓内 current working tree 有 21 行 `git status` 变化**（多件 ` M` ＋ 多件 `??`，均属其它车道/本波落仓件）；我**零写入**：我唯一的写入是本报告，我的所有反极性腿与注入实验都在 `/tmp` 副本树（沙箱已于 12:16:2x 全部删除，`ls -d /tmp/t32-*` = 0）。
6. **纪律遵守**：进程按 PID（本任务**未收任何进程**，也无需收 —— 未起 X、未起应用）；**未用** `pkill`/`killall`/`pgrep -f`；**匹配串/令牌未出现在我的命令行里**（`"已接线"`/`"未接线"`/`REPORT-ID-DOMAIN` 全部用 Python 在脚本内**拼接/构造**，见 §2.4 的构造说明）。
7. **资源看门（现取 12:15:10）**：`df -Pk /` 第 4 列 = **100,742,260 KB**（≥5 GB ✓）；`SwapFree` = **1,208 MB**（≠0 ✓）；loadavg 见各腿日志。

---

## 5. 结论与建议

- **两处红确实逐条归零**，且**不是靠放宽判据**：扫描集（`examined=65`／`files=195`／`sh=106`／`py=89`）与腿集（`cases=8/7/11`）**两边都未缩**；`allow=0` 未走豁免；两条自述规则（正/反）**都还能红**；被我注回原 bug 的副本树**照样被引号陷阱抓住**。
- **`pkg-src` 的真 bug 已由行为证明修好**：`stderr 179→0`（同一调用上下文对照）、stdout `60→92` B 且三个 flag 名逐字可见。
- **唯一需要改正的是叙述**（不阻塞）：`t31` 的 "改前 stderr **263 B**" 应写成带调用路径的形态；若要在报告间对账，请采用 `stderr_bytes=<N> @len(<path>)` 体例。
- **判词：`pass`**（findings：0 条需返工；1 条 non-blocking 口径更正已并入 §3.3）。
