# P1-W40 · `t115` 余项关账报告（`t116`／`scribe`）—— `F-1` 直接读数落进装置 ＋ `F-2` 行数口径 ＋ `O-1`／`O-3`／`O-4` 口径

写者 `scribe`（`t116` attempt 1／`5494c469-e6bf-4668-99ea-c5e103bd5180`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T03:1x–03:3x+0800`
**一切读数现取自算**（`t115` 的复核只当线索）。本件**判据/装置/口径面**为主：**未**跑整趟门禁、**未**构建、**未**跑腿、**未**占显示位、**未** `git add/commit/push`；夹具**全部仓外**、**用完删**。
**写域** ＝ `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` ＋ `…/legs-to-env.py`（**仅因选 `F-1`（甲）**；两者**在覆盖面内** ⇒ 同趟 `cell=#1`）＋ `build/MilBridge/P1-fontstack-fallback-{criteria,verify,report}.md`（dated 追加）＋ `docs/ROUTES.md §15af`（一行）＋ `build/MilBridge/HANDOFF-NEXT.md`（`cell=#1` 一行）＋ 本载体（新建）。**未**动 `src/**`／`build/PresentationCore.Linux/**`／`build/WindowsBase.Linux/**`／`build/MilBridge/tools/**`／`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`。

## §0 一句话

`F-1` 按**（甲）** 处置：装置新增**机读行** `FAILLINE k=<k> failfast=<n> unrec=<n> src=<app 日志>`（`session_inner.sh` 写在 `CLICK`–`PHASE` 之间；`legs-to-env.py` 带成 `leg_<k>.env` **第四段**）⇒「`FailFast` 位点不再执行」从**间接三证**升级为**直接读数**；`F-2` 的行数差 **33 ＝ `HEADER` 行数**（自报数＝**正文**行数）已写死口径；`O-1`（`form=unnamed` ≠ 具名前进）、`O-3`（c 反腿改**证据面判据**：两方言并存、**不**要求 `resolved=<族>`）、`O-4`（`ink = W×H − magenta − dominant`，粗代理）三条口径均落册。

## §1 `F-1`（low，主项）—— **（甲）** 把「位点不再执行」落成装置里的直接读数

**改动（只加行；既有 `CLICK`／`PHASE` 行与既有三段 env 字段一字未动）**
- `session_inner.sh`：在 `CLICK` printf **之后**、`PHASE` 行**之前**新增
  `printf 'FAILLINE k=%s failfast=%s unrec=%s src=%s\n' "$k" "$(cnt "FailFast" "$GLOG")" "$(cnt "Unrecoverable system error" "$GLOG")" "app_g$gi.log:FailFast|Unrecoverable"`。
- `legs-to-env.py`：docstring 的契约表补第四段；`parse_click` 取可选两格（旧格式 ⇒ `-`）；写 env 时**新增一行** `FAILLINE k=%d failfast=%s unrec=%s src=app_g%s.log:FailFast|Unrecoverable`。
- **口径（逐字）**：`failfast=` ＝ 该腿**原始 app 日志**（`app_g<gi>.log`）里 **`FailFast`** 的行数；`unrec=` ＝ 同日志里 **`Unrecoverable system error`** 的行数（**与既有 `fatal=` 同源同量、逐字等价**；保留 `fatal=` 只为不破坏既有读法）。⇒ 判「位点这次有没有执行」**看 `failfast=`**。

**可判性成对读数（本席现取；不跑应用）**

| 面 | 读数 |
|---|---|
| **修前** | `grep -oE 'failfast=[0-9]+\|unrec=[0-9]+' evidence/**` ⇒ **0 命中**（只有 `session.txt` 的 `fatal=0` ×2）⇒ 该对读数**无载体** |
| **修后（同源干跑该 printf）** | 无标记 ⇒ `FAILLINE k=24 failfast=0 unrec=0 src=app_g1.log:FailFast\|Unrecoverable`；日志里**注入** `FailFast` 与 `Unrecoverable system error` 各一行 ⇒ **`failfast=1 unrec=1`**（**计数器有响应**，不是常量） |
| **转换器往返（仓外夹具 session ＋ 空 `app_g1.log`）** | `leg_24.env` 第四段 ⇒ `FAILLINE k=24 failfast=0 unrec=0 src=app_g1.log:FailFast\|Unrecoverable`；`LEG`／`NAMED`／`DEV` 三段与改前**逐字同形** |
| **反兼容（旧格式 session，删该行）** | 两格 ⇒ **`-`（＝"没测到"，不是 0）**（与 `ink=` 同一约定） |

**装置仍工作（不跑腿的可判证明）**：① 守卫 `pts-pages-guard.sh` 对装置件**零引用**（现取 `grep -c 'session_inner\|legs-to-env' tools/pts-pages-guard.sh` ＝ **0**）⇒ `--legs` 判词与装置改动**无关**；② `bash -n session_inner.sh` 与 Python 编译**均过**；③ 新行落在 `CLICK`–`PHASE` 之间 ⇒ 转换器**既有 region token 扫描自动带走**（未改锚、未新增解析器）；④ 旧格式 session 的**反兼容**读数见上表。
**`NOINFO(未跑腿)`（如实记）**：**没有**一整趟真腿的端到端读数（派单禁跑腿）⇒ "整趟腿仍工作"只有上面四条**间接**证明；装置件改动**未**获端到端确认。

## §2 `F-2`（low）—— 行数差 **33 ＝ `HEADER` 行数**（口径差，不改生成器）

```
生成器（自读 src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py）：
    print(f"[断言] 上游 N 行 → 生成物 {len(out.splitlines())} 行")      ⇒ 数的是**正文 out**
    output = HEADER + out                                             ⇒ 落盘的是**整件**
我自算：HEADER 行数 = 33 ；生成件 wc -l = 2235 （build/PresentationCore.Linux/FamilyCollection.Linux.cs）
       ⇒ 2235 = 2202 + 33  ✓ 差**恰为**头注释块
```
⇒ **口径（逐字）**：该自报**是"正文行数"、不是"整件行数"**；整件 ＝ 正文 ＋ `HEADER`（今天 33 行）；**两者都不参与 `identical` 判定**（后者比整件字节）。**本件不改生成器**（`src/**` 越域 ⇒ 要改另派单，并须同趟 `--check` 复验 `identical`）。

## §3 `O-1`（观察）—— `form=unnamed` **不是**「具名前进」的证据

```
现取：evidence/app_g1.log 里 entry=unknown = 0 、[PTS-UNAVAILABLE] = 0
     守卫 --legs（仓外证据副本）⇒ PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed
```
⇒ **口径（逐字）**：`form=unnamed` 只表示「没有具名行可判 ⇒ 形态判据按其形态通过」；「**具名前进**」的证据面是 **`PTSGAP`／台账**（`^PTS_GAP entry=` 行与 `PTSGAP_FRONTIER` 的 `before→after` 名更换）⇒ **两件事，禁止互相折算**。本趟「具名面为空 ＋ 台账 0 行」**既不是倒退、也不是前进**（第四步把靶心做真 ⇒ 该站具名行**不再出现**，属**预期**）。

## §4 `O-3`（观察）—— c 反腿改**证据面判据**（**（乙）**；只落判据，不实现仪器）

```
现取三元组直方图（evidence/app_g1.log）：
   3  requested=DEJAVU  fallback=no  resolved=none
   2  requested=ARIAL   fallback=yes resolved=none
   1  requested=GEORGIA fallback=no  resolved=none
   ⇒ fallback=no = 7 > fallback=yes = 4（与 t115 记的 no=7>yes=4 相符）；resolved= 今天**恒 none**
```
⇒ 落进 `P1-fontstack-fallback-criteria.md` 的 `t116` 段：`C9` 的 c 格改为**要求同一趟读数里两种方言并存** —— ① `requested=<受控不存在族> … fallback=yes` ≥1；② `requested=<受控存在族> … fallback=no` ≥1；**只有其一 ⇒ 必红并点名**（"两态分不开：疑似永远降级／从不降级"）。
⚠️ **不要求 `resolved=<该族自身>`**：现取恒 `none` ⇒ 那样等于造一条**永不可能绿**的判据（本仓禁此）；记为**未来项**（若 `resolved=` 将来真携带解析结果可收紧）。**（甲）**（可构建副本／旁路开关）**只写要求与代价** ⇒ `src/**` ＋ 构建/跑腿 ⇒ **另派单**。

## §5 `O-4`（观察）—— `ink=` 的口径（自读 `shotstat.py` ＋ **自算复验**）

```
公式（源码注释逐字）：ink = W×H − magenta − dominant（dominant ＝ 出现次数最多的单色像素数；ink<0 ⇒ 0；**无阈值**）
复验（evidence/shots/g1/k24.png，1280x1024）：shotstat.py ⇒ ink=480000
      我按同式自算 ⇒ 480000 = 1310720 − 0 − 830720  ✓（可复算）
"深色像素"（**另一个量**）：复核者 837862 ／ 我按"三通道和<384" 840070
```
⇒ **口径（逐字）**：`ink=` 只作「这页是不是**纯空白**」的粗证（守卫 `realized` 期只用 `magenta==0 ∧ ink>0`）；**不得**用于阈值/比例/逐位断言，**不得**与 `magenta`／`colors` 并列称"同等可复算"。**未改 `shotstat.py`**（其注释已有口径，本件把它抬进判据册）。

## §6 同趟复核 ＋ 不变量/指纹/牙（现取）

```
同趟复核（与 t115 的成立面不冲突）：leg_24 alive=yes app_rc=143 colors=383 ink=480000（现取 leg env）；
      应用日志里 FailFast|Unrecoverable 现取 0 命中（与 F-1 的装置口径**互补**：前者=日志无该串，后者=装置把该计数落成机读格）
      ⚠️ 守卫 --legs 现取仍 PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing…
         ⇒ 这正是 **C6 的红面**（字体栈降级后页面真排版、既有 degraded 相位判据仍在执法），**非**本件引入、**也非**"修好了"的证据；相位翻转另排
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
指纹：本席**现取** fp 后**按纪律纯追加** `cell=#1` 一行（见 §7 的成对哈希）；登记后 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`
牙：REPORTID=PASS files=xxx ids=… declared=224 ｜ DEFREG=PASS ＋ **DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD**（他者面）
    SENTINEL-SPEC 现取 **SSC=PASS**（与队长记的"哨兵不缺位"一致）｜ SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS ｜ STATICJAWS 见回执
```

## §7 改动面 / 备份面（第 `29` 条）＋ **本席同趟两处自查纠错（如实记）**

- **改动面 6 件**：`build/MilBridge/tests/PtsPagesProbe/session_inner.sh`（`53a01752fb09da22`→**`a54d63bac8c17084`**，`numstat 9 0` 纯加）／`…/legs-to-env.py`（`c914e672eb111e1c`→**`277241f33bb94a58`**，`numstat 16 2`：**2 个删行＝我声明的两处改写点**（① docstring 里"三段"那行改成"四段"；② `return dict(...)` 尾行加两个键））／三件 fontstack 载体（dated 追加，各带新自报值：criteria **`1646ab12fee8ab65`**、verify **`dacae10b60e852e2`**、report **`6ab7dbac0d4caef4`**，逐件 `diff` 删行 ＝ **0**）／`docs/ROUTES.md`（+1 行，删行 ＝ 0）／`HANDOFF-NEXT.md`（`cell=#1` 一行）＋ 本载体（新建）。
- ⚠️ **纠错①（备份面）**：我**先改了装置件、后取备份** ⇒ 最初那两份 `cp -p` 备份**装的是"已改"版本**（哈希与现值同值、成对读数作废）⇒ 本席**当场从 `git show HEAD:<path>` 重取了真前像**（`53a01752fb09da22`／`c914e672eb111e1c`）并以此写入 `cell=#1`；**如实记**：这是本席的流程错（第 `29` 条要求"写前备份"），已在本趟内改正。
- ⚠️ **纠错②（`cell=#1` 行）**：第一版该行因**双引号内的反引号被 shell 当命令替换**（`DQ-BACKTICK` 族）而**吃掉一个 token**（`` `t115` ``），并把装置件的"前像"写成**同值对** ⇒ 本席**当场重写该行**（补回 token ＋ 换成 HEAD 真前像的成对哈希）⇒ 现取 `HANDOFF_MV=PASS`。
- 备份面（**改正后**）：`~/w281-scribe/bak/{session_inner.sh,legs-to-env.py}.pre-t116`（HEAD 真前像）＋ `{P1-fontstack-fallback-criteria.md,P1-fontstack-fallback-verify.md,P1-fontstack-fallback-report.md,ROUTES.md,HANDOFF-NEXT.md}.pre-t116`（写前 `stat -c %h` ＝ 1 ＋ `cp -p`）⇒ 与改动面逐件对账 ✓。

## §8 未做项 / `NOINFO` ＋ 边界自证

- **`NOINFO①`（`F-1` 的端到端）**：**未跑腿**（派单禁）⇒ "装置整趟仍工作"只有零引用／语法／夹具往返／反兼容四条间接证明。
- **`NOINFO②`（`O-3` 的（甲）路线）**：（可构建副本／旁路开关）**只写要求与代价**，**未**实现（触 `src/**` ＋ 构建 ⇒ 另派单）。
- **`NOINFO③`（`F-2` 的生成器文案）**：生成器在 `src/**`（越域）⇒ 只写口径，**未**改文案。
- **未做**：`O-4` 的 `shotstat.py` 改动（**不需要**：口径已在其注释里，本件把口径抬进判据册即可）。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有上面那 6 件；`src/**`、`build/PresentationCore.Linux/**`、`build/WindowsBase.Linux/**`、`build/MilBridge/tools/**`、`verify-all.sh`、`close-wave.sh`、哨兵、`samples/**` **零碰**；**未**跑整趟门禁／**未**构建／**未**跑腿／**未**占显示位／**未** `git add|commit|push`；**夹具全在仓外**（`/tmp/t116-fx`、`/tmp/t116-dry.sh`、`/tmp/t116-ev`）⇒ **收尾删净**。
- **第 `30` 条**：本件的 `F-1`／`O-4` 读数都是**批式件读数**（日志计数、PNG 统计）或**同源干跑**；不含"进程内状态敏感仪器"引用 ⇒ 该条不产生引用义务（`O-3` 的环容量纪律已在 `t113` 入册）。
**本件自证**：`head -n -1 build/MilBridge/P1-fontstack-fallback-close-report.md | sha256sum | cut -c1-16` ＝ 3286975df2b82a34（本行系末行；上列各节即被哈希的全文）
