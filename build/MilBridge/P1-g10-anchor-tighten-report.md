# P1 G10 **归因锚收紧**（`t82`／`scribe`）—— 非 PTS 域只吃**真声明**：注释/字面量必红、真声明零漏、`G10b` 不放宽

写者 `scribe`（attempt 2／`0109f3f3-e1a5-4919-98e1-8071b83c3b8f`）｜读时 `ts=2026-09-28T23:08:2x–23:11:5x+0800`｜一切读数**现取自算**，每格带亚秒 `ts=`
起因：`t77`（verifier 独立复核，载体 `build/MilBridge/P1-g10-domain-verify.md`，100 行，sha16 `a301e75cc18a10c3`）判 `t76` 的 ①–⑧ 成立，但**独立造夹具**咬出 **`F1`（medium）**：非 PTS 域归因 `decl_hit()` 的旧锚只要求「**同一行**同现 `DllImport` 与 `EntryPoint="<名>"`」⇒ **一条注释就能把任意名字判绿**。

## §0 一句话
把非 PTS 域的归因锚从「两个子串同现」收紧成「**真声明**」：**属性起始行 ∧ 属性块内 `EntryPoint="<名>"` ∧ 属性块后 ≤3 非空行见 `extern` ∧ 先剥行/块注释**。修前**四处**假绿（注释假声明／`//` 注释掉的声明／块注释包着的声明／孤属性行）修后**四处全红并点名**；**真声明一个不漏**（现盘 548 行／452 个去重入口名**逐名命中**，含 `LoSetDoc` 的 `:1470`）；**PTS 域（`G10b`）一格未动**。

## §1 新锚原文（落盘件现取；`decl_hit()` 判据本体）
```
decl_hit() {   # <名> ⇒ 印**真声明**的首个声明位 `file:line`；无命中／树不在 ⇒ 空输出 ＋ rc=1
  local nm="$1" f out=""
  [ -d "$DECL_TREE" ] || return 1
  while IFS= read -r f; do
    out="$(awk -v nm="$nm" '
      function strip(l,   p, q, head, rest, n) {      # 行注释截断 ＋ 块注释逐段剥（inb 跨行保持）
        if (inb) { if (index(l, "*/") > 0) { l = substr(l, index(l, "*/") + 2); inb = 0 } else return "" }
        n = 0
        while (index(l, "/*") > 0 && n < 8) { … }      # 见落盘件（同文件同函数；本处只摘录签名与首尾）
        p = index(l, "//"); if (p > 0) l = substr(l, 1, p - 1)
        return l
      }
      { C[FNR] = strip($0) }
      END {
        for (i = 1; i <= FNR; i++) {
          if (C[i] !~ /^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(/) continue     # ① 属性起始行
          txt = C[i]; j = i
          while (txt !~ /\]/ && j < i + 5 && j < FNR) { j++; txt = txt " " C[j] }        # ② 属性块
          if (txt !~ ("EntryPoint[[:space:]]*=[[:space:]]*\"[[:space:]]*" nm "[[:space:]]*\"")) continue
          for (k = j + 1; …seen < 3…) { if (C[k] ~ /(^|[^A-Za-z0-9_])extern([^A-Za-z0-9_]|$)/) { print FILENAME ":" i; exit } }   # ③ 真方法
        }
      }' "$f" 2>/dev/null)"
    [ -n "$out" ] && break
  done < <(grep -rl --include='*.cs' -E '^[[:space:]]*\[[[:space:]]*DllImport[[:space:]]*\(' "$DECL_TREE" 2>/dev/null | LC_ALL=C sort)
  [ -n "$out" ] || return 1
  printf '%s' "$out"
}
```
- **① 属性起始行**这一条同时把**注释行**（`//`／`/*`／`* `）与**字符串字面量行**（`var s = "…"`）**在形态上排除** —— 它们的行首都不是 `[`。
- **理由：树范围**不收窄**（仍 `upstream/wpf/**/*.cs`）**：本判据要回答的是「**该入口名在其声明树里对拍得上**」；把树收成目录形状（例 `…/TextFormatting/**`）会把「**域的定义**」偷换成「**路径启发式**」⇒ 其它族（`Fs*`／`Nl*`／未来新族）的**真声明会被漏掉**。⇒ 只收紧**锚的形态**，不动**域的射程**。
- **实测支撑（本席自算，`ts=23:08:0x`）**：现盘 `upstream/wpf` 全树 `*.cs` 共 **4188** 件；`^\s*\[\s*DllImport\s*\(` 的属性起始行 **1221** 行（68 件）；其中**同行**带 `EntryPoint="<名>"` 的 **548** 行（去重 **452** 名）；**含 `EntryPoint=` 却不在属性起始行的行数 ＝ 0**（⇒ ① 不吃不漏）；旧锚的「同行两串」判定与真声明的**行集完全相同**（548/548）。

## §2 成对读数（**仓外**夹具 `/tmp/t82-fx*`，由本席**重建**，未引 `t77` 的文件；用完删）
| 腿 | 夹具（本席自写） | 修前（`b74d2be6f9093115`） | 修后（`9b46dc9b3fbfda32`） |
|---|---|---|---|
| ① **注释里的假声明** | `// 本行只是注释里的示例文本：DllImport(Whatever, EntryPoint="LoCommentOnlyZZ") 供读者参考` | **`PASS observed=LoCommentOnlyZZ … domains=dllimport-entry decl=…/faketree/a/Fake.cs:1`**（`ts=23:08:32.323`） | **`FAIL frontier=LoCommentOnlyZZ off-roster=LoCommentOnlyZZ roster=10 domains=unattributable decl=none`**（`ts=23:08:54.881`） |
| ② **注释掉的真声明** | `// [DllImport(DllImport.PresentationNative, EntryPoint="LoCommentedOutZZ")]` ＋ `// internal static extern …` | **`PASS observed=LoCommentedOutZZ …`**（`23:08:32.440`） | **`FAIL … off-roster=LoCommentedOutZZ …`**（`23:08:55.009`） |
| ③ **块注释包着的声明** | `/* … [DllImport(…, EntryPoint="LoBlockCommentZZ")] … extern … */` | **`PASS observed=LoBlockCommentZZ … decl=…/Block.cs:2`**（`23:08:32.560`） | **`FAIL … off-roster=LoBlockCommentZZ …`**（`23:08:55.134`） |
| ④ 字符串字面量 | `var s = "[DllImport(Whatever, EntryPoint=\"LoStringOnlyZZ\")]";` | `FAIL … unattributable`（`23:08:32.687`，**旧锚已挡住**） | `FAIL … unattributable`（`23:08:55.257`） |
| ⑤ **孤属性行（无 `extern`）** | `[DllImport(DllImport.PresentationNative, EntryPoint="LoNoExternZZ")]` 单独一行 | **`PASS observed=LoNoExternZZ …`**（`23:08:32.816`） | **`FAIL … off-roster=LoNoExternZZ …`**（`23:08:55.385`） |
| ⑥ **真声明（正极对照）** | `[DllImport(DllImport.PresentationNative, EntryPoint="LoFakeTreeRealZZ")]` ＋ `internal static extern int LoFakeTreeRealZZ(IntPtr p);` | `PASS … decl=…/realtree/a/Real.cs:1`（`23:08:32.942`） | **`PASS … decl=…/realtree/a/Real.cs:1`**（`23:08:55.515`，**未误伤**） |
⇒ **必红可见**：修后 ①–⑤ 的整步判词都是 `PTS_GUARD=FAIL … fails=g10-name-off-roster(<名>),native-ledger-absent(PTS_GAP n=0)`，**点名在 `frontier=`／`off-roster=` 两处**（`reason` 位在串里：`域归因**失败**：该名**既不在 PTS 在册表、也无「DllImport…EntryPoint=」声明位**`）。
**归因隔离**：①–⑥ 三组「假/真」之间**只换树的文件内容**，腿件、名单源、命令一字不差。

## §3 零漏 ＋ `--selftest` ＋ 现树正极（④）
- **零漏（一次性证明）**：把现盘真树里**全部 452 个**去重入口名一次塞进一条腿 ⇒ 落盘件 `--g10-name` 现取 **`rc=0`**／`PTS_G10_NAME=PASS observed=WTSQuerySessionInformation names=452 roster=10 domains=dllimport-entry,pts-declared decl=…/PresentationFramework/System/Windows/Standard/NativeMethods.cs:2278`（`ts=2026-09-28T23:11:27.084+0800`）⇒ **一个真声明都没漏**。
- **`--selftest`**：写前 **`PASS pass=37 fail=0`** ⇒ 写后 **`PTS_GUARD_SELFTEST=PASS pass=40 fail=0`**（**原 37 例零退化**；新增三格＝注释假声明必红／注释掉的声明必红／真声明绿＋点名声明位）。
- **现树正极（第 ④ 条）**：`bash build/MilBridge/tools/pts-pages-guard.sh --legs /home/links-dev/p1-ptsname/legs-after` ⇒ **`rc=1`**（`ts=23:09:12.505`，捕获式）：
  ```
  PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470（**域前提修正**：非 PTS 域判定为**该入口名在声明树里对拍上**…）
  PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded
  ```
  ⇒ 真声明位 `:1470` **仍在**；`rc=1` 的唯一成因仍是**另一族**的 `native-ledger-absent`（未折叠、未处置）。
- **`G10b` 不放宽（复核）**：本次**未动** PTS 域那一支（`k_pts_entries[]` 命中/落空两格与 `t76` 逐字相同）；`--selftest` 里 `G10c·PTS假名 ⇒ 必红`／`G10c·非PTS真名 ⇒ 不红＋点名`／`G10c·非PTS假名 ⇒ 必红`／`G10c·声明树缺席 ⇒ NOINFO` 四格全绿。

## §4 归属（第 ⑤ 条）：**并入 `D-G189` 的第二面，不新立号**
- **理由**：这是 `D-G189` 的**同一处判据**（非 PTS 域归因）的**强度不足**面 —— 第一面是「**域认错了**」（域取值域未声明假设），本面是「**认的方法太松**」（归因证据只比两个子串）；两面**同件、同口径句**（「判据引用一个观测量之前，必须把它『由谁产生、取值域是什么』写进判据件」）、**同修法路径**（域分格 ＋ 锚收紧）。新立号会让同一个函数的分工在两处对不上。⇒ 只在 `D-G189` 条目里**追加一段 dated 面**。
```
samples/WpfFeatureProbe/KNOWN-DEFECTS.md：`8cfc9315ded2a65a`／3870 行 → **`95224a4c310900e5`／3878 行**（`numstat 20 0`；**删行 0**）
build/MilBridge/tools/defect-registry-declared.tsv：`5c459198c6b5258c` → **`d689bba84c456766`**（同趟 `--emit`；`# DECL-ANCHORS` 的 `KD=8cfc9315ded2a65a` → `95224a4c310900e5`）
DEFREG 两遍（emit 之后）：`DEFREG=PASS declared=224 route_ids=224` ＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`（`ts=23:10:48.388`）
```

## §5 翻册（第 ⑥ 条）：`docs/ROUTES.md` §15af dated 追加（只增不改）
```
docs/ROUTES.md：`bd5197bd7a39e97a`／862 行 → **`c79e68209b5385d4`／863 行**（`numstat 8 0`；**删行现取 0**）
```
内容：本件修法（真声明锚四条合取）＋ **`t77` 的 `F1` 归属**（`medium`，载 `P1-g10-domain-verify.md` `a301e75cc18a10c3`）＋ 修前四处假绿／修后四处必红点名 ＋ 452 名零漏 ＋ `selftest 40/40` ＋ 现树正极仍在 ＋ 并入 `D-G189` 第二面不新号。

## §6 已接线牙复跑 ＋ 不变量 ＋ 哨兵 ＋ 模式（原样）
```
ts=23:11:4x  SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203 sh=114 py=89 diag=76 allow=0
ts=23:11:4x  PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85 runs=12
ts=23:11:51.224  HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
ts=23:11:4x  SSC=PASS lines=13 keys=13 cmp=IDENTICAL      ｜ 哨兵：cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag ⇒ IDENTICAL（同值 `b26b245f75a2ea70`，他者 `23:05:49` 所写；本件未写哨兵）
ts=23:11:4x  REPORTID=PASS files=232 ids=2196 declared=224 glob=build/MilBridge/*report*.md
ts=23:10:48  DEFREG=PASS declared=224 route_ids=224 ＋ DEFREG_DECLDRIFT=0 keys=-
ts=23:14:20.484  STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62（唯一 HIT ＝ `HANDOFF-MV` rc=1 —— **归因见 §7**：他者（`t78`）在本席最后一次追写**之后**又写了**覆盖面内**件 `src/WpfGfx.Linux.Native/src/win32_pts.c`（`mtime 23:14:13.519`）⇒ `inputs_fp` 再移；**不是本件引入的用例红**，本件自己的判据面在 `--selftest 40/40` 与现树正极上全绿）
不变量（写后现取）：`^run_step "` ＝ **62**｜coverage ＝ **234**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜`run_step "FP-MANIFEST-TEETH" … --expect 234` ⇒ **四条全部未变**
模式守恒（两口径成对）：本趟 5 件跟踪件 `stat -c %a` 全 `644`；`git ls-files -s` 的已跟踪件全 `100644`
```

## §7 指纹位移 ＋ 纪律 28（第 ⑦ 条；**两次追写的取值时刻如实记** ＋ 并发归因具名到件）
```
inputs_fp 轨迹（本次写盘面）：
  `0581db21fe4cf1a292e5b54195932bd346fe79ef138807eb4bc34c20869553b2`（`t76` 的 `cell=#1` 值）
  → `b4b1b6fd24b115bb33ce92c4420193ef876d81c0c35e60b4f45417760281d5cf`（本席改判据件之后，`ts≈23:09–23:11`）
  → `48100cb0fa727a595c9a4b1d9f68e7bbd178523f6c9508aeacb7e100ba08f038`（他者写 `win32_pts.c` 之后，`ts≈23:13:0x`）
  → `15598eb84c0dd053e0215ed69986b2f58e4d1aacae613da1eb1d82791a4d2b6e`（他者**再**写 `win32_pts.c`：`mtime 23:14:13.519`）
cell=#1 追写（**两次**，皆纯 `>>` 追加、dated、模式不变 `644`）：
  ① `ts=2026-09-28T23:11:47.229+0800`，值 `b4b1b6fd24b115…d5cf`（HANDOFF-NEXT `593 → 594` 行，sha16 `ebe6916b33cd318d` → `82b4b687875b9526`）⇒ 紧随其后 `ts=23:11:51.224` 现取 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（rc=0）
  ② `ts=2026-09-28T23:13:21.864+0800`，值 `48100cb0fa727a59…f038`（`594 → 595` 行，sha16 `82b4b687875b9526` → `86d930f89134cf0e`）⇒ 紧随其后 `ts=23:13:25.866` 现取 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（rc=0）；写后复读 `fp` 与写入值**逐位相同**
⇒ **「回 PASS」这一条已两次达成，且每次都有紧随的 PASS 读数**。
⚠️ **并发归因（具名到件与时刻；这不是本件的用例红）**：两次追写之后 `inputs_fp` 都被**他者**顶开，而**每次**「追写之后被动过的**覆盖面内**件」经本席逐件 `stat` 枚举**都恰为 1 件** —— `src/WpfGfx.Linux.Native/src/win32_pts.c`（`mtime 23:13:02`，随后 `23:14:13.519`；该件是 `t78`（runner）的在写件，且 `src/**` 属**本单写域之外**）。⇒ 本席**不再**追第三次（追写会在 ≈1 分钟内再次失效、只往格子里灌陈旧值）；按纪律**「一次只一个写者」**，下一格 `cell=#1` 应由**持有最后一次覆盖面写盘者（`t78`）**在它静置后追写，或由队长在 `t78` 收摊后统一刷新（这正是 `t62`→`t65` 那一族「同趟写回被下一个写者立刻打回」的形态）。
本席**未**动 `src/**`、**未**动 `evidence/**`（只读它作腿输入）。

## §8 未做项 ＋ `NOINFO`（具名）＋ 边界自证
- **未做**：未跑整趟门禁（会构建 ⇒ 动九位）；未构建；未跑应用腿、未占显示位；未 `git add/commit/push`（提交归队长）。
- **未改（写域外，逐件可核）**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tests/PtsPagesProbe/evidence/**`（`t78` 在写）／`src/**`（工作树里 `src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `M` 属 `t78`，非本席）／`build/PresentationFramework.Linux/**`／两枚哨兵／`upstream/**`（只读它）。
- **实写 5 件**：`build/MilBridge/tools/pts-pages-guard.sh`（写前 `cp -p` 备份 `~/w281-scribe/bak/pts-pages-guard.sh.pre-t82`，`cmp IDENTICAL`，`%h=1`，`temp+rename` 保 `644`）／本载体／`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`（同趟 `--emit`）；另按纪律 28 契约追写 `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` **一行**。
- **`NOINFO`（既不算绿也不算红）**：① 现树 `PTS_GUARD=FAIL` 的唯一红是 `native-ledger-absent(PTS_GAP n=0)`（**另一族**，本件未处置）⇒ 本件**不声称**该步绿；② 本件**未跑整趟门禁** ⇒ 端到端绿未验；③ 本席**未**独立复算旧世界的 `upstream` 树（只用现盘真树做 548/548 与 452 名零漏）⇒ 对「历史某个时刻的真声明数」不给读数。

## §9 ⏪ **世界在我作业期间移动了**（`ts=2026-09-28T23:15:11+0800`；本段为追加，不改上文读数）
**① 在册表 10 → 12（`t78`／runner）**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `k_pts_entries[]` 被 `t78` 加入 **`LoSetDoc`** 与 **`LoSetBreaking`**（现取 12 名；该件 `mtime 23:15:11.698`；`src/**` **在本单写域之外**，本席一字未动）。⇒ **§3 那条现树正极的读数被世界取代**：本席在 `ts=23:09:12.505` 读到的 `PTS_G10_NAME=PASS observed=LoSetDoc … domains=dllimport-entry decl=…/LineServices.cs:1470`（记在 §3 与 §5 翻册里）**当时成立**；现在同一命令读到的是 **`PASS observed=LoSetDoc names=1 roster=12 domains=pts-declared（形态判据：具名行在在册名单内；PTS 域不写死任何名字）`**＋`PTS_GUARD=FAIL … fails=native-ledger-absent(PTS_GAP n=0)`（`rc=1`）。**这不是缺陷**：判序写死「**先在册表、后声明树**」⇒ 名字被提进 PTS 在册表之后，它**应当**归 PTS 域（`G10b` 那一格），这正是设计意图。
**② 因此**新锚**的正极改由两条**不依赖该世界的证据**承担**（都在本载体里、都可复算）：
  - **真树面**：取一个**不在**在册表、但在 `.cs` 声明树里真有声明的入口名（现取首个：**`AdjustWindowRectEx`**，声明位 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/Standard/NativeMethods.cs:2278`）⇒ `ts=23:16:39.090` 现取 **`rc=0`**／`PTS_G10_NAME=PASS observed=AdjustWindowRectEx names=1 roster=12 domains=dllimport-entry decl=…/NativeMethods.cs:2278`。
  - **合成树面**：`--selftest` 的 `ft3`（本席自建真声明）⇒ `G10c·真声明 ⇒ 绿＋点名` `rc=0` ok。
**③ 本席自己的**夹具腐坏**（当场发现、当场修，如实记）**：`--selftest` 里 ㉖／㉘ 两条把「非 PTS 域真名」**写死**成 `LoSetDoc` ⇒ 名字被 `t78` 提进在册表之后，这两条**随世界腐坏**（`ts=23:14:59` 实测 **`PASS pass=38 fail=2`**，两条都因「PTS 分支先接答」而失配）。**修法**：夹具名改为**现取**（内容锚：`grep -rhoE --include='*.cs' 'EntryPoint…="<名>"' "$DECL_TREE"` 取名字集 − `k_pts_entries[]`，首个即用；取不到才退回合成树），并在载体里写明「**夹具名不许写死**——世界会把名字提进在册表」。修后落盘件现取 **`PTS_GUARD_SELFTEST=PASS pass=40 fail=0`**（`ts=23:16:2x`）。
  ⚠️ 一次**自身实现失误**（同一趟内自查抓到）：派生夹具名的 `grep` 首版**漏了 `--include='*.cs'`** ⇒ 派生出 `AbortPrinter`（只在**非 `.cs`** 文件里出现）⇒ 该名在判据的 `.cs` 射程内找不到声明位 ⇒ 自测仍 38/2；加上 `--include='*.cs'` 后派生出 `AdjustWindowRectEx` ⇒ 40/0。**教训**：**夹具的射程必须与判据的射程同口径**（否则夹具本身就在测另一件事）。
**④ 判据件版本轨迹（本件）**：`b74d2be6f9093115`／572 行（写前）→ `9b46dc9b3fbfda32`／643 行（真声明锚）→ **`944e61f39f24631c`／660 行**（夹具去世界耦合）；三趟对 `HEAD` 的 `git diff --numstat` 分别为 `166 6`（含 `t76` 未提交部分）／同／同；`t82` 专项删行（对写前件）＝ **4 行**，全在 `decl_hit()` 内。
**⑤ `cell=#1` 第三趟**：`ts=2026-09-28T23:16:43.998+0800`，值 **`ec63b28dc68e6468f6c78dda573af9dc5567fc39d67a785379d2941d4a78d3b1`**（HANDOFF-NEXT `595 → 596` 行，sha16 `86d930f89134cf0e` → `10dd845b51005838`）⇒ 紧随其后 `ts=23:16:47.736` 现取 **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（rc=0）。⚠️ 与 §7 同一条并发事实：`t78` 仍在写 `win32_pts.c`（`mtime` 持续前进）⇒ 本格**任何时刻的值都可能在数分钟内被顶开**；**不再追写第四趟**（追写只向格子里灌陈旧值），下一格应由持有最后一次覆盖面写盘者（`t78`）在静置后追写。

## §10 终态牙读数（现取；含一处**瞬时红**的归因）
```
ts=2026-09-28T23:18:49.149+0800  STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（唯一 NOINFO＝`FrameProbe-frame rc=2` 约定）
ts=23:18:4x  HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
ts=23:18:4x  SSC=PASS lines=13 keys=13 cmp=IDENTICAL
（更早的两笔同族读数：`23:14:20.484` `STATICJAWS=FAIL fails=1`／唯一 HIT＝`HANDOFF-MV`（＝`t78` 在 `23:14:13` 再写 `win32_pts.c` 顶开本格）；`23:17:46.221` `STATICJAWS=FAIL fails=1`／唯一 HIT＝`SENTINEL-SPEC`）
```
- **`SENTINEL-SPEC` 那笔是瞬时红**：`t78` 的 `src/**` 增量让 `libwpfwin32.so` **换代**（`2a5165700a8c8579` → **`3bd193e54785b5db`**，本席现取 `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16`），而哨兵里 `WIN32SHIM=` 彼时还是旧值 ⇒ 判定红；**他者随后已刷新哨兵**（现取哨兵第 6 行 `WIN32SHIM=3bd193e54785b5db` ＝ 现场值、两枚 `cmp IDENTICAL`、`SSC=PASS`）⇒ **不需要本席/队长再重写哨兵**（本席按边界**从未写哨兵**）。
- **观察（交队长；不属本单动作）**：同一次换代意味着「九位」里的 `win32shim` 位已离开 `#80` 冻结块所载值 ⇒ 与 `t74` 那族「重冻结」同形；另 `src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `k_pts_entries[]` 被加到 **12** 名 ⇒ 若 `PTS` 域口径要跟（`pts-gap-count-check.sh` 的 `tool/ops/impl` 与 `known-red.json` 的对照面）也需同趟处置。**本席未动**这些面（`src/**`／冻结件／登记表均不在本单写域或未获指示）。
**本件自证**：`head -n -1 build/MilBridge/P1-g10-anchor-tighten-report.md | sha256sum | cut -c1-16` ＝ `ab996a6b57a7d049`（本行系末行；上列各节即被哈希的全文）
