# HANDOFF-NEXT —— 新会话开工页（由主控车道在会话交接时落盘）

> **读法**：这份是"怎么开始"，不是"结论"。**所有数值都要现场算**（本页给的命令就是算它的）。
> 权威顺序：**现场重算 > 冻结基线件 > 本页 > 任何报告里的转述**。
> 落盘时刻：2026-09-23 约 10:0x +0800（此后树仍在动 —— 先按 §7 重建状态再用本页）。

---

## §1 两个目录的关系（**最容易搞错的一件，先看这个**）

```
wpf-linux-20260906/
├─ wpf-linux/                     ← 【R】权威工作树：**代码在这里编译与运行**
│     `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
│     · **不是 git 仓库**（没有 `.git`；`git rev-parse` 会直接报"不是 git 仓库"）
│     · 一切构建 / 探针 / 门禁 / 冻结都在这里
│
└─ ~/netTest/GitProj/WPFOnLinux   ← 【克隆】**提交与推送只在这里发生**
      · origin   = git@github.com:isharrrry/WPFOnLinux.git（用户 fork）
      · upstream = https://github.com/dotnet/wpf.git
      · 分支 feat-Linux（**远端默认分支也是它**）
      · **从不在这里构建**（没有 bin/obj）
```

**推送流程**（每条规矩都是从事故里来的）：
1. 改完在 `R`；**逐件 `cp -p`** 进克隆（**不许**在 `R` 里 `git init`）。
2. `git status` 与"本批改了几件"**逐件对账**（有车道漏推过声明表 ⇒ 远端 `DECLDRIFT` 读成 1）。
3. **逐径 `git add <file>`**（**不许 `-A`**）；commit；`git push origin feat-Linux`。
4. push **之后**重新 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`（**refspec 陷阱**：该克隆默认 fetch 只跟 `main`，拿旧 ref 比会得到**假 MISMATCH**）＋ `git ls-remote origin HEAD` 交叉核。
5. **逐件字节核对**：`git cat-file blob origin/feat-Linux:<path> | sha256sum` == `sha256sum $R/<path>`（本仓刻意 `* -text`，**不许**让 git 做行尾归一化）。
6. `git ls-remote --symref origin HEAD` 仍须是 `ref: refs/heads/feat-Linux`。

---

## §2 当前波次与在飞车道

- **冻结基线 = `#51`（`38e67e834430d75c`，668,062 B）**；`docs/CURRENT-STATE.md:9` 是唯一的机器声明行。
- **波 `#52` 收尾链在飞**：产品改动只有一条 `D-G100`（`win32shim` 位移 `8392fc09564779a1 → bd037229be8db4f6`，**它不修 `D-G98`**）＋ 危险处置 `D-G101`（硬链接断链 ＋ `repin-generation.py` 写者改 temp＋`os.replace`）。
- 在飞车道（各自目录在 `~/wNNNa/`，报告在 `build/MilBridge/WNNNA-report.md`）：
  | 车道 | 任务 | 目录 |
  |---|---|---|
  | W126A | `#52` 收尾链（整波→五臂→重钉→门禁×2→冻前 `verify-all`→冻 `#52`→冻后×2→记录→推送→app-local） | `~/w126a/` |
  | W124A | `D-G98` **一格定罪**（红腿上 `xprop -id <client> WM_NORMAL_HINTS` vs "停住几何"） | `~/w124a/` |
  | W127A | 等 `gen=#52` 后落登记（`TASK-0707` ✅／`0203` 收口／今日教训） | `~/w127a/` |
  | W128A | `TASK-0203` **175 趟批**（只为拿一份 `139` 的栈） | `~/w128a/` |

---

## §3 未闭的 TASK（一行一条；状态以 `docs/ROUTES.md` 现场为准）

```
TASK-0007 [MVP] 🔴 页 23/24 内容不可用（真因 TASK-0302，长线）
TASK-0201 [MVP] 🟡 静默 rc=139＋0 字节日志
TASK-0203 [Next] 🟡 精度达成（合并上界 4.86%）＋ 41 趟 0/40；**归因仍 NOINFO**；175 趟批在跑（W128A）
TASK-0302 [MVP] 🔴 PTS/原生 LineServices（111 条 Fs*/Lo* 缺口）
TASK-0303 [Next] 🟡 R3 侦察/设计（A1/A2/A3 已由 0304/0305/0306 落地）
TASK-0109 [Next] 🔴 wpf_x11_has_ewmh_wm() 残留边界（WM 死后属性残留 ⇒ 可能静默丢一次移动）
TASK-0110 [Next] 🟡 几何还原残留（真因部分定位/部分证伪；首选成因 = "过期尺寸约束挡还原"，接 D-G88）
TASK-0111 [Next] 🔴 先落 N3 ＋ 必须加"xprop 一格"（N1 撤销/暂缓）
TASK-0708 [Next] 🔴 「仪器波」：四件新牙接线（verify-all 27 → 31 步）
TASK-0501 [MVP] 🟡 GIF 旧读数（0502 已修多帧）
```

---

## §4 判据件与牙（**改它们 = 改 PASS 的定义**）

| 件 | 作用 | 现状 |
|---|---|---|
| `build/verify-all.sh` | 27 步门禁；声明 `VERIFYALL-STEPS-DECL: 27 gen=#52` | 现场 |
| `build/close-wave.sh` 的 `fp_inputs()` | 覆盖面（**149 件**，显式名单） | 现场 |
| `build/MilBridge/tools/r-gate-step.sh` | 第 `[26]` 步判据（13 格） | 现场 |
| `build/MilBridge/tools/nul-bytes-check.sh` | 第 `[27]` 步（`NULBYTES=`，**绿 = 声明覆盖面内 0 件含 NUL ≠ 全仓**） | 现场 |
| `build/MilBridge/tools/hygiene-tooth.sh` | 装置/口径卫生牙（根集合／证据保全／语义射程／硬链接四类，**未接线**） | 现场 |
| `build/MilBridge/tools/regression-decision.py` | 回归判定四要件（三态；`rc` 0/3/2；**未接线**） | 现场 |
| `build/MilBridge/tools/{uia-door-check.sh,ime-landing-check.sh}` | UIA"无门"／IME"有意降级"两件**故意为红**的仪器（装门/补声明即绿） | 现场 |
| `build/MilBridge/tools/wm-awaited.sh` | "等 WM 起来"的**真判据**（三条件全要） | 现场 |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **冻结基线件**（当前 `#51`；`#52` 冻结中）—— **动一个字节 `BASELINESHA` 就红** | 现场 |

---

## §5 硬纪律（12 条；都是踩出来的）

1. **判据先写、读数后取**；判据文本**不许事后改**（改了要在报告里逐字说明并给新判据的 sha）。
2. **两极化必做**：修 ⇒ 该绿的绿；**复原 ⇒ 必须回到红**（给前后 sha）。
3. **`NOINFO` 既不算绿也不算红**；`rc=127/126` = **没跑过**，不是失败。
4. **不许`pkill`/`killall`/`pgrep -f`**：收进程**只按 PID**，探活**读 `/proc/*/cmdline`**。曾有一条 `pkill -f` **误杀别人批次一趟**且**把自己也杀了 ⇒ 损失清单拿不到**。
5. **判断"某车道是否在动"：活进程第一、`STATUS.md` 第二**（已有两条车道 STATUS 滞后于真实动作）。
6. **重活一律走机器级槽**：`~/heavy-slot.sh --min-avail 1500 --max-hold <N> --wait 1800 -- <命令>`；`HEAVYSLOT=NOINFO reason=low-memory`／`MAXHOLD_KILL` 的趟**作废**。长批**分批入槽、批间释放**。
7. **`export PATH="$HOME/.dotnet:$PATH"`**（否则 `rc=127`）；`dotnet -m:1`、`DOTNET_gcServer=0`；`nproc=3`。
8. **不许手抄哈希**：一律现场算（16 位小写）。报件时**两行口径都给**（`FULL sha256` ＋ `head -n -2`／`-n -1` 的口径值）。
9. **写域排他**：只写自己点名的件；改既有文件前 `cp -p` 备份；**冻结期间**（收尾链在跑）**不许改册/地图/声明表**。
10. **实验装置类改动要公告并留痕**（`cp`／临时换件／`touch`），事后还原；**落盘一律 temp＋`rename`**（`>` 覆盖会穿透硬链接夹具）。
11. **"命令跑了" ≠ "读数有效"**：先机械核（覆盖面／inode／sha16）再下结论；发现被推翻的结论**如实撤回**。
12. **产品改动一次只能有一条未冻结**（"一条改动 → 冻结一次"），否则回归无法归因。

---

## §6 已知会骗你的东西（**开工前先读这段，能省半天**）

- **`pf` 不是构建身份**（`D-G92`）：同源同命令的整波重建会给**不同字节**；它只作"当下现场值"，**不许当漂移/回归判据**。
- **`cp -al` 建的夹具 = 硬链接农场**（`D-G101`）：不是副本、是**别名** ⇒ 任何**原地写**会**穿透**到夹具（别人的负控）。`upstream/**` 6417 件仍同 inode，**声明残留**（无写者 ⇒ 不破链；**若要在 `upstream/**` 原地写，必须先破链**）。
- **`~/w93a/probe/bin/Release/PresentationFramework.dll` 是旧件** ⇒ 指向它的探针会"拿旧 PF 验新 PF"（`D-G80` 族）。
- **日志体积不能当判别量**（`D-G87`）：`134` 族 61 趟里 **14 趟（23%）**只写 18–19 KB 折叠形；`timeout: …已核心转储` 那 43 B **不是应用输出**。
- **按关键词/名字认对象会骗你**（`D-G79`/`D-G84`/`D-G89`/`D-G93`/`D-G95`/`D-G97`/`D-G102`）：恒真谓词、`if !` 反向恒假、glob 形态、`pgrep -f` 假匹配、仪器臂名与动作不匹配（**整臂静默空转**）。
- **小样本判不出回归**（`D-G99`）：`6% vs 0%` 按功效口径要 **131 趟/臂**（`regression-decision.py` 可复算）；"≥40 趟/臂"是**区间口径**，两者不可互相替代。
- **检测力分母**（`D-G94`）：`CLICK … SKIP dead` 是"**没点**"，不是"点了没落地"。
- **总和/分布类读数**要第二种工具复算：`awk` 求和会把 4.09 GiB 打成 `2147483647`（2³¹−1 钳位）。
- **`stat -c '\t'` 打的是字面反斜杠 t**（不是制表符）⇒ 列错位、比对**空转**。

---

## §7 重建状态：照抄这几条（**新会话第一件事**）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
C=$HOME/netTest/GitProj/WPFOnLinux

# 1) 冻结基线与三颗牙
sed -n '9p' $R/docs/CURRENT-STATE.md
bash $R/build/MilBridge/tools/baseline-sha-check.sh   # BASELINESHA / BASELINEGEN / BASELINE_BYTES / BASELINEDUP

# 2) 登记牙（声明数与漂移）
bash $R/build/MilBridge/tools/defect-registry-check.sh | grep -E '^DEFREG'

# 3) 门禁步数与声明
grep -m1 'VERIFYALL-STEPS-DECL' $R/verify-all.sh

# 4) inputs_fp（**照 close-wave.sh 的真函数**，别自己发明）
sed -n '/^fp_inputs()/,/^}/p' $R/build/close-wave.sh > /tmp/fpfn.sh
bash -c "cd $R && source /tmp/fpfn.sh && fp_inputs"

# 5) 九位（现场算；路径见冻结块 samples/WpfTextDemo/ACCEPTANCE-BASELINE.md 的 RE-FROZEN 段）
sha256sum $R/build/PresentationCore.Linux/bin/Release/PresentationCore.dll \
          $R/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll \
          $R/build/WindowsBase.Linux/bin/Release/WindowsBase.dll \
          $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16

# 6) 在飞车道（活进程第一、STATUS 第二）
ps -eo pid,etime,cmd | grep -E 'w1[0-9][0-9]a|heavy-slot|verify-all|dotnet' | grep -v grep
for d in ~/w12*a ~/w11*a; do printf '%s: ' "$d"; tail -1 "$d/STATUS.md" 2>/dev/null; done

# 7) 未闭任务
grep -nE '^- .?TASK-0(107|109|110|111|203|302|303|501|702|703|704|705|706|707|708)' $R/docs/ROUTES.md | tail -30
```

**漂移提醒（本页落盘时的实况）**：`DEFREG=PASS declared=138` 但 **`DECLDRIFT=1`**（`docs/ROUTES.md` 在最后一次 `--emit` 之后被改过）。**修法 = 重跑 `--emit` 重新对齐**（该 tsv **不在 `fp_inputs()` 覆盖面** ⇒ 重生成不动 `inputs_fp`），并注意"声明表必须跟随地图"，不是放宽判据。

---

## §8 第一条活的建议（新会话可以直接从这里挑）

1. **`TASK-0109`**（`wpf_x11_has_ewmh_wm()` 残留边界）：动 `src/WpfGfx.Linux.Native/src/win32_x11.c`，要建"**WM 已死但 EWMH 属性残留**"场景 —— **排在 `#52` 冻后**（守"一条产品改动 → 冻结一次"）。
2. **`TASK-0111`**（几何残留的下一跳）：等 **W124A** 的"一格定罪"读数落地，若命中"过期下限/上限挡收缩"⇒ 做**能撤回/刷新上限的那一半**（`N1` 已裁定暂缓）。
3. **`TASK-0708`**（仪器波）：把四件新牙接线（`verify-all` 27→31 步，四处声明同趟改；两件"在册红"要按 `tline-gate.sh:1302` 的 `all-as-registered` 形态登记进 `known-red.json` 并重钉）。
4. **`TASK-0203` 尾巴**：W128A 的 175 趟批一交数，把判定（同源／异源／`NOINFO`）与上界落册。

---

## §9 两条 2026-09-23 上午新查明的"环境级"陷阱（**开工前必读，都能造成假红/假挂**）

1. **"车道静默挂死"可能根本不是运行时问题，而是宿主重启**：
   `uptime -s` 现读 = **2026-09-23 09:45:54** ⇒ 车道 W126A 在 09:32→09:58 的"静默挂死"**就是这次重启**（它的进程与 watcher 全被杀）。
   ⇒ **以后遇到"车道不动了"**：先 `uptime -s`、再看活进程，**不要一律归因于运行时**（我此前对 09-22 那几条车道的归因**证据不足**，属未定）。
   ⇒ 重启会**留下/遗留**各种 X、锁与临时目录 ⇒ 复位前先 `ps -eo pid,ppid,lstart,cmd | grep -E 'Xvfb|dotnet|gdb'` 看清归属。
2. **`verify-all.sh` 复用外部 Xvfb 时"只验连得上、不验几何"** ⇒ **会挑中别的车道的私有 X**（本次它挑了车道 W128A 的 `:185 -screen 0 1024x768x24`，导致 `Windowing.Tests` 的 `[X11Fact]`/`[X11Theory]` **三条假红**；`#51` 时用例 875 全过、本次 831 ⇒ 差 **44 = 整个 `Windowing.Tests` 套件**）。
   ⇒ **判据**：读 `verify-all` 日志里那行 `✅ 复用已运行的 Xvfb（实测 display :NNN，注意不是 :99）` —— **只要它复用的不是自起的 1280x1024，就怀疑是假红**。
   ⇒ **正确修法（已授权 W126A 落地）**：复用前**必须核几何 == 闸门要求（1280x1024x24）**，不符则跳过并自起；日志三态 `reused`／`skipped-geom-mismatch`／`self-started`。
   ⇒ **同时提醒**：闸门在别人屏上跑 X 相关套件，会**开窗/抢焦点** ⇒ 那个窗口内别人批次的应用腿读数**要单独审计**（W128A 已被告知）。
