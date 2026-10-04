# W97A 报告 —— `TASK-9907`：把 `D-G82` 的普查做成**牙**（只读核对器 `nul-bytes-check.sh`）

- **lane = W97A**｜`TASK-9907`｜波 `#50` 已冻结（`#50 1f4189c1257737a9`，`VERIFYALL-STEPS-DECL: 26 gen=#50`）
- 仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下称 `$R`）
- 时间：开工 `2026-09-22 17:41`｜收工 `2026-09-22 17:56`（+0800）
- `nproc=3`｜kernel **`6.8.0-138-generic`**（`uname -r` 现场读）｜`loadavg` 开工 `1.47, 1.17, 1.12` → 收工 `1.50, 1.48, 1.29`
- **零 `dotnet`（本件全程未跑任何 `dotnet`／未跑任何构建／未起任何应用、未开任何 X、未占重活槽）**
- **写域：只 2 件** —— 新建 `build/MilBridge/tools/nul-bytes-check.sh` ＋ 本报告。**既有一字节未碰**
  （机器证见 §8：开工后全树只 6 件被动过，另 4 件属并发车道 **W99A** 的登记写；**W98A** 在 `$HOME` 里跑应用腿）

---

## 0 · 结论（结论在前）

1. **新牙已建、未接线**：`build/MilBridge/tools/nul-bytes-check.sh`，**683 行**，sha16 **`409d83d945f7d563`**。
   **本件只交付工具＋自检，`verify-all.sh` 一个字节未动**（`#50` 刚冻结 ⇒ 加步会把冻结的步数声明打成过期，属 `#51`）。
2. **现场读数**：`NULBYTES=PASS files=1170 hits=0 bytes=249913357 … canary=ok`，`rc=0`，**耗时 0.4 s**。
   ⇒ 今天仓内**判据覆盖面里 0 件含真 NUL**（与 `#50` W83A 修完 `wic_proxy.c` 之后应然一致）。
3. **`--selftest` 31/31 PASS（rc=0，1.2 s）**，含四条"必红"与三条"必 NOINFO"的反极性：
   ①**注入 1 个 NUL ⇒ 必红**（逐字点名 `path=a.c offset=17 line=3 n=1`）②**还原 ⇒ 回绿**（成对）
   ③NUL 放进**白名单外扩展名**⇒ 按声明**不算命中**（但进"没扫"清单，可见）④NUL 放进**排除目录** `obj/`
   ⇒ **不算命中** ⑤空覆盖面／缺解释器／**弄瞎扫描器**／**金丝雀故意弄坏** ⇒ **`NOINFO`（不绿、也不冒充红）**
   ⑥**9 MiB 大件尾部的 NUL** 必红（`offset=9437186 line=2`）⇒ 分块读**不漏尾**。
4. **历史重放（本件最硬的一条证）**：把 W83A 留的**修前**备份（`$HOME/w83a-backup/wic_proxy.c.before`，
   sha16 `f0d3d1501aebcd8c`）放进沙箱、按真路径摆好 ⇒ 本件 **`NULBYTES=FAIL hits=1`** 且逐字给出
   `offset=15873 line=289 n=3` —— **与 W83A 的独立读数（15873/15902/15921、`:289`、3 个）逐个吻合**；
   同趟换成**修后**件（`8dc634b9254295f4`）⇒ `PASS hits=0`。
   ⇒ **本件本来就能抓住 `D-G82`**，不是"为已经修好的东西补个形式"。
5. **独立第二仪器（libmagic）交叉核**：对判据覆盖面 1170 件跑 `file --mime-type` ⇒
   非 `text/*` 仅 `application/json` 55 件（合法）＋ `inode/x-empty` 1 件（`build/.wave-done`，0 字节、无 NUL）；
   **`data` / `application/octet-stream` 命中 0 件** ⇒ **两台仪器同结论**。
6. **`#50` W83A 留的那格 `NOINFO`（`.log` 14 件）本件关掉了**：`.log` **纳入**声明 ⇒ 现场
   `SCANEXT … .log=14`，NUL **全为 0**。代价（将来含 NUL 的日志会红）**逐字写死在件头**，不静默豁免。
7. **`inputs_fp` 影响（机械核，不是推理）**：**新建本件不动 `inputs_fp`** ——
   覆盖面件清单（147 件）在"建件前/建件后"**逐字节相同**、本件在清单里 **0 命中**，
   真 `fp_inputs()` 三读（17:43／17:47／17:51）**同为** `ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`。
   ⚠️ **但接线时若按仓内惯例把它纳入 `fp_inputs()` 的 `printf` 名单，就必动**（$HOME 副本模拟：
   `ee543f44…` → `80c6fa0fa91f4fbe746f91fba78cbabbdd633e2bd3588e3bc0f2be75e5fff3e7`）
   ⇒ **那一改必须安排在 `IN_FP_0` 采样之前**（见 §5、§6）。
8. **另一条此前没人登记过的射程**：`build/integration-wave.sh:97-99` 的 `wave_fp()` 覆盖面里有
   `find build/MilBridge/src build/MilBridge/tools build/MilBridge/tests …` ⇒ **本件落在它的覆盖面里**
   （逐字复制该子句实测件数 **106 → 107**）。那是**波内 before/after** 指纹（不冻结、不跨波比对）
   ⇒ **无害**，但"新建判据件会被 `wave_fp` 看见"这件事本身**此前无人登记**，记在此处。
9. **本件落进两颗已接线牙的扫描集**（`build/MilBridge/tools/**.sh`）：当场跑过两趟、**都仍 PASS 且本件 0 命中** ——
   `SHELL_QUOTE_TRAP=PASS traps=0 files=151`（rc=0）、`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 files=68 sites=81`（rc=0）。
10. **边界（不许被读成"全仓 0 件"）**：本件的绿**只**等于「**声明覆盖面里** 0 件含 NUL」。
    判据外仍有三类**未判**：`upstream/**`（6417 件，按"非本仓自有代码"不扫 ⇒ 该域**未测**）、
    11 件**无扩展名 ELF 编译产物**、280 件**按定义就是二进制**的件；其中前两类里含 NUL 的，
    本件**只 `DIAG` 点名不判红**（理由与边界逐字见 §1.4、§7.2）。

---

## 1 · ① 覆盖面声明（**含"没扫什么"，可复算**）

### 1.1 声明在哪、为什么这么放

声明**只有一份**，就是 `build/MilBridge/tools/nul-bytes-check.sh` 里的五个变量；python 侧**不另写一份**
（bash 把五个变量当 argv 传进去）。这是照 `#28`「**同一份逻辑存在两处必然分叉**」那条教训办：
声明与判据**同体**，改声明就是改判据（因此会被 `QUOTE-TRAP`／`PIPEFAIL` 那族"判据件被看着"的纪律覆盖到）。

现场把声明**打印出来**（可复算，不必读源码）：

```
NULBYTES_SCOPE exts=35 names=5 globs=1 skipdirs=9 binexts=41 root=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux anchors=strict min_files=800 min_tools=15
NULBYTES_SCOPE_EXTS .c .h .cs .sh .py .md .props .targets .tsv .csproj .sln .txt .xaml .xml .json .yml .yaml .config .cmake .inc .def .rc .manifest .in .patch .diff .log .editorconfig .tpl .template .mk .mak .ps1 .s .reference
NULBYTES_SCOPE_NAMES .gitignore .gitattributes Makefile SHA256SUMS .wave-done
NULBYTES_SCOPE_GLOBS *.bak-*
NULBYTES_SCOPE_SKIPDIRS upstream .git node_modules .artifacts obj bin __pycache__ .vs TestResults
NULBYTES_SCOPE_BINEXTS .png .jpg .jpeg .gif .webp .bmp .ico .tif .tiff .ttf .otf .woff .woff2 .so .dll .a .o .obj .pyc .snk .nupkg .zip .gz .xz .bz2 .pdf .bin .stream .dat .db .sqlite .exe .pdb .class .jar .wasm .xwd .wav .mp3 .mp4 .webm
```

三点设计说明（都是**取舍**，如实写）：

- **`NULB_NAMES`／`NULB_GLOBS` 两条是"扩展名看不见的地方"**：`.gitignore`/`.gitattributes`/`Makefile`/
  `SHA256SUMS`/`.wave-done` **没有真扩展名**（`os.path.splitext('.gitignore')` 的 ext 是空串）
  ⇒ 只靠扩展名会把 6 件文本件**静默漏掉**；`known-red.json.bak-20260917-151210` 这种
  `.bak-<时间戳>` 也只有基名 glob 抓得住（W83A 点过这件的名，但没给它一条覆盖面规则）。
- **`.log` 纳入**（现场 14 件、NUL 全 0）：`#50` W83A 把它排除后留成 `NOINFO`，本件把它变成**有读数**。
  代价逐字写在件头：将来含 NUL 的日志会让本步红 ⇒ 那时该判"真出了二进制日志"（红是对的）
  还是"把 `.log` 移出白名单"（改声明），**由主控裁定**；本件**不静默豁免**。
- **`*.ps1` / `*.s` / `*.reference` 纳入**（现场 15＋1＋1 件，全在 `tests/parity/windows/**`）：
  它们按定义是文本（PowerShell 脚本、汇编、SDK 头参照）⇒ 纳入后 `otherext` 现场归 **0**。

### 1.2 判什么（进 `rc`）

扩展名 ∈ `NULB_EXTS`、或基名 ∈ `NULB_NAMES`、或基名匹配 `NULB_GLOBS` 的件
⇒ 文件体里 **≥1 个 `0x00` 字节**即 `FAIL`，逐件点名「路径 ＋ 首个 NUL 偏移 ＋ **所在行号** ＋ NUL 计数 ＋ 字节数」。

### 1.3 现场"判了多少"（机读行，逐字）

```
NULBYTES_ROSTER files=1170 bytes=249913357 tools_sh=30 skipdir_dirs=141
NULBYTES_SCANEXT (by-name)=6 .bak-20260917-151210=1 .c=30 .config=3 .cs=350 .csproj=88 .h=3 .json=65 .log=14 .md=257 .props=6 .ps1=15 .py=83 .reference=1 .s=1 .sh=68 .sln=1 .targets=6 .tsv=2 .txt=162 .xaml=8
```

- 判 **1170 件 / 249,913,357 B**（分块 1 MiB／无大小上限；现场有 3 件 >8 MiB，最大
  `tests/parity/geometry/u14/linux-results-u14.json` 123.9 MB）。
- `tools_sh=30`：`build/MilBridge/tools/*.sh` 30 件（含本件）—— 这是**锚**之一（下限 15）。

### 1.4 现场"没扫什么"（**逐条可列：`--list-notscanned` / `--list-skipped-dirs`**）

```
NULBYTES_NOTSCANNED binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 binext_all=.dll=2 .jpg=4 .png=255 .snk=1 .so=2 .stream=7 .ttf=9 otherext_all=
NULBYTES_SKIPDIRNAME .artifacts:1 TestResults:1 __pycache__:4 bin:67 obj:67 upstream:1
```

| 没扫的类 | 件数 | 为什么 | 现场有没有藏着 NUL |
|---|---|---|---|
| `upstream/**` 子树 | **6417** | vendored 的 dotnet/wpf 镜像 ⇒ 不是本仓自有代码，`D-G82` 的定义域是"本仓自有代码的源卫生" | **未测**（`NOINFO`，见 §7.1） |
| 被排除目录子树（141 个目录：`obj` 67／`bin` 67／`__pycache__` 4／`.artifacts` 1／`TestResults` 1／`upstream` 1） | **5461** | 构建产物（另有一族牙在管：`BuildHygiene`）；数由减法复核：`6922 − 1170 − 280 − 11 − 0 = 5461` ✅ | 未扫（按定义不含"本意是文本"的源件） |
| `NULB_BINEXTS`（`.png .ttf .stream .jpg .dll .so .snk`） | **280** | 按定义就是二进制 ⇒ 扫它们对 `D-G82` 零信息 | `.png`/`.dll`/`.so` 按定义**满是 NUL** ⇒ 不列（列出来是噪音） |
| **无扩展名**件 | **11** | 无法由声明判定"是不是文本" | **有**：11/11 含 NUL，且**首个 NUL 恒在偏移 7**（ELF 头 `\x7fELF\x02\x01\x01\x00`）⇒ **真二进制**（正是 W83A 点名的那 11 件 `probe_*` 10 件 ＋ `t1b-ls-selftest`）。**`diag_noext_nonelf=0`** ⇒ 没有任何"非 ELF 的无扩展名件含 NUL" |
| **未认领扩展名** | **0** | 不在白名单也不在二进制名单的扩展名 | 无（`otherext_all=` 为空）；**若将来出现且含 NUL ⇒ 逐条 `NULBYTES_DIAG` 点名**（自测 S14 钉住这条通路） |

⚠️ `--list-skipped-dirs` 现场头几行（逐条可列的机器证）：

```
NULBYTES_SKIPDIRS_LIST_BEGIN
upstream
build/__pycache__
build/CycleStub.PresentationFramework.Linux/bin
build/CycleStub.PresentationFramework.Linux/obj
build/CycleStub.PresentationUI.Linux/bin
```

---

## 2 · ② 三态与机读行

| 态 | `rc` | 触发（**现场可复算**） | 机读行 |
|---|---|---|---|
| `PASS` | `0` | 覆盖面非空 ∧ 读到了字节 ∧ 锚齐 ∧ 金丝雀 ok ∧ `hits=0` | `NULBYTES=PASS files=… hits=0 …` |
| `FAIL` | `1` | 覆盖面里 **≥1 件含 NUL** | `NULBYTES=FAIL hits=N files=…` ＋ 每件一行 `NULBYTES_HIT` |
| `NOINFO` | `2` | 见下（**一律 `rc≠0` ⇒ 在门禁里同样是 ❌**） | `NULBYTES=NOINFO reason=… files=… hits=…` |

`NOINFO` 的**全部触发面**（顺序即代码里的优先序；`reason=` 逐字）：`python-missing`／`root-missing`／
`mktemp-failed`／`scanner-error`（解释器非 0 退出**或写 stderr**）／`scanner-blinded`／`canary-blind`／
`scan-errors`／`empty-roster`／`zero-bytes-read`（覆盖面非空但**一个字节都没读**）／
`too-few-files`／`anchor-missing:verify-all.sh`／`anchor-missing:…/wic_proxy.c`／`too-few-tools`／`bad-arg`。

⚠️ 这一族正是 `D-R4`「**射程悄悄缩到零而它还是绿的**」的对治：
- 三条**仓内锚**：`verify-all.sh` 必须在覆盖面里、`build/DirectWrite.Linux/wic-shim/wic_proxy.c`
  （`D-G82` 的宿主件）必须在覆盖面里、`build/MilBridge/tools/*.sh ≥ 15`；
- 一条与锚无关的**件数下限** `min_files=800`（现场 1170，留 31% 余量）；
- 两条**"读不出东西就不许绿"**：`empty-roster`、`zero-bytes-read`。

### 2.1 **内置金丝雀**（每次真跑都先自证，不是只跑在自测里）

```
NULBYTES_CANARY=ok hits=1 path=ctrl_nul.c off=17 line=3 scanned=2
```

每次真跑之前，本件在自己的 `TMPDIR` 下造 4 个夹具并**要求**扫描器给出上面这一行：

| 夹具 | 内容 | 必须的结果 |
|---|---|---|
| `ctrl_nul.c` | `line1\nline2\nline3<0x00>tail\n`（**偏移 17、第 3 行**） | **命中 1 件**，且 `off=17 line=3` **逐字正确** |
| `ctrl_clean.c` | 干净 | 不命中 |
| `ctrl_nul.png` | 同一 NUL，**扩展名不在白名单** | **必须不被判**（声明真按声明走） |
| `obj/ctrl_nul.c` | 同一 NUL，**在排除目录里** | **必须不被判**（排除真生效） |

⇒ 一次钉三件事：**没瞎**（含 NUL 能命中）＋ **算得对**（偏移/行号）＋ **声明被遵守**。
不符 ⇒ `NOINFO reason=canary-blind`（**不绿、也不冒充红**）。
⚠️ 前提**记在这里**：金丝雀的 17/17 是**手算**的（`6+6+5=17`，第 3 行），
并已用**独立**手段复核（`od -c` 打印 `3 \0 t a i l \n`；python 现算 `bytes 23 first_nul 17 line 3 n 1`）
⇒ 它与扫描器的读数是**两条独立路径**，不是自证。

---

## 3 · ③ 现场读数（`hits=0`？—— **是**）

### 3.1 一趟真跑（逐字，`rc=0`）

```
NULBYTES_ROSTER files=1170 bytes=249913357 tools_sh=30 skipdir_dirs=141
NULBYTES_NOTSCANNED binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 binext_all=.dll=2 .jpg=4 .png=255 .snk=1 .so=2 .stream=7 .ttf=9 otherext_all=
NULBYTES_SKIPDIRNAME .artifacts:1 TestResults:1 __pycache__:4 bin:67 obj:67 upstream:1
NULBYTES_CANARY=ok hits=1 path=ctrl_nul.c off=17 line=3 scanned=2
NULBYTES=PASS files=1170 hits=0 bytes=249913357 skipdir_dirs=141 binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 canary=ok
NULBYTES_SELF path=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/tools/nul-bytes-check.sh sha16=409d83d945f7d563
```

（另有 11 行 `NULBYTES_DIAG kind=noext-nul …` 逐条点名那 11 个 ELF 产物，见 §1.4；此处略。）
**成本：首趟（冷）`real 0m0.405s user 0m0.227s sys 0m0.117s`；热趟 `real 0m0.276s`**（同一棵树、同一解释器）。

### 3.2 两趟之间的 `bytes=` 差 57 B —— **是别人的并发写，不是本件**

`bytes=249913300`（17:47 趟）→ `bytes=249913357`（17:51 趟）。两趟之间**另有车道（W99A）在写覆盖面内的件**
（机器证：`find -newermt '2026-09-22 17:41:00'` 命中 `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/W99A-report.md` —— **都不是本件**，见 §8）。
⇒ `files=` 也因此从 1169 → **1170**（另一条车道新增/改写了覆盖面内的件）。**收工前第三读 `files=1171`**
（W99A 仍在写）⇒ 本报告里那个 `1170` 是 **17:51 那一趟的现场值**，不是"稳定值"；下游若要引用，
**请以自己那趟的 `NULBYTES_ROSTER files=` 为准**（本件的判据本身与件数无关，只与 `hits=` 有关）。

### 3.3 独立第二仪器：libmagic（对同一份覆盖面清单）

```
$ file --mime-type -f $HOME/w97a-run/roster_live.txt   # 1170 件，rc=0，3.6 s
解析到 1170 行 / 覆盖面 1170
  874  text/plain        83  text/x-script.python   68  text/x-shellscript
   55  application/json  47  text/x-c++              37  text/x-c
    3  text/xml           1  inode/x-empty           1  text/x-makefile   1  text/x-asm
== D-G82 签名（data / application/octet-stream）== 0 件
```

⇒ **两台独立仪器（自写 NUL 计数器／libmagic）对 1170 件同结论**：
没有一件是"被判二进制、本意是文本"。唯一的非 `text/*` 是 `application/json`（55 件，合法，
与 W83A 那次 54 件的口径一致）与 `inode/x-empty` 1 件（`build/.wave-done`，**0 字节**、无 NUL）。

### 3.4 🔴 历史重放：**本件本来就能抓住 `D-G82`**（对真件的两极化成对读数）

沙箱里按**真路径**摆一件 `build/DirectWrite.Linux/wic-shim/wic_proxy.c`，分别放**修前/修后**两份内容：

| 侧 | 件 sha16 | 字节数 | 本件读数 | `rc` |
|---|---|---|---|---|
| **修前**（`$HOME/w83a-backup/wic_proxy.c.before`，W83A 留的备份） | **`f0d3d1501aebcd8c`** | 130592 | `NULBYTES=FAIL hits=1` ＋ `NULBYTES_HIT path=build/DirectWrite.Linux/wic-shim/wic_proxy.c offset=15873 line=289 n=3 bytes=130592` | **1** |
| **修后**（仓内现行件） | **`8dc634b9254295f4`** | 130595 | `NULBYTES=PASS files=1 hits=0 … canary=ok` | **0** |

- 修前侧的 `offset=15873 line=289 n=3` **与 W83A 的独立读数逐个吻合**
  （缺陷册 `D-G82:2344` 记「3 个 NUL 全在 `:289`，偏移 15873/15902/15921」；W83A 报告 §1.4 同）
  ⇒ 两条独立路径（W83A 的普查脚本／本件的扫描器）对**同一个历史现场**给同一组数字。
- 这次重放**只在 `$HOME` 沙箱里**做，**仓内件一字节未动**（修后件的 sha16 收工复核仍是 `8dc634b9254295f4`）。

---

## 4 · ④ `--selftest` 逐例成对读数（**31 例，31 PASS，`rc=0`，1.2 s**）

`bash build/MilBridge/tools/nul-bytes-check.sh --selftest`（逐字，只略去重复的空白对齐）：

```
ST_ATTEST=OPEN self=…/build/MilBridge/tools/nul-bytes-check.sh sha16=409d83d945f7d563
SELFTEST CASE S01-clean                = PASS rc=0 want=0 state=PASS hits=0
SELFTEST ASSERT S01 覆盖面恰 4 件（a.png/a.zzz/blob/obj 都不判） = PASS
SELFTEST ASSERT S01 「没扫什么」三类都点了名 = PASS
SELFTEST CASE S02-inject-1-nul         = PASS rc=1 want=1 state=FAIL hits=1
SELFTEST ASSERT S02 点名 a.c ＋ offset=17 ＋ line=3 ＋ n=1 = PASS
SELFTEST CASE S03-restore              = PASS rc=0 want=0 state=PASS hits=0
SELFTEST CASE S04-nul-in-png           = PASS rc=0 want=0 state=PASS hits=0
SELFTEST ASSERT S04 「没扫」清单可逐条列出（不是静默跳过） = PASS
SELFTEST ASSERT S04 带 NUL 的那份 .png 出现在「没扫」清单里 = PASS
SELFTEST CASE S05-nul-in-obj           = PASS rc=0 want=0 state=PASS hits=0
SELFTEST ASSERT S05 排除目录被点名（skipdir_dirs=1/obj:1） = PASS
SELFTEST CASE S06-empty-roster         = PASS rc=2 want=2 state=NOINFO hits=0
SELFTEST ASSERT S06 空覆盖面 ⇒ NOINFO reason=empty-roster = PASS
SELFTEST CASE S07-anchor-broken        = PASS rc=2 want=2 state=NOINFO hits=0
SELFTEST ASSERT S07 锚断 ⇒ NOINFO reason=anchor-missing = PASS
SELFTEST CASE S08-too-few-files        = PASS rc=2 want=2 state=NOINFO hits=0
SELFTEST ASSERT S08 件数低于下限 ⇒ NOINFO reason=too-few-files = PASS
SELFTEST CASE S09-python-missing       = PASS rc=2 want=2 state=NOINFO hits=none
SELFTEST ASSERT S09 解释器缺失 ⇒ NOINFO reason=python-missing = PASS
SELFTEST CASE S10-blinded              = PASS rc=2 want=2 state=NOINFO hits=0
SELFTEST ASSERT S10 弄瞎 ⇒ NOINFO（不绿、不冒充红） = PASS
SELFTEST CASE S11-canary-broken        = PASS rc=2 want=2 state=NOINFO hits=0
SELFTEST ASSERT S11 金丝雀弄坏 ⇒ NOINFO reason=canary-blind = PASS
SELFTEST CASE S12-big-tail-nul         = PASS rc=1 want=1 state=FAIL hits=1
SELFTEST ASSERT S12 9 MiB 尾部 NUL：offset/line 定点命中 = PASS
SELFTEST CASE S13-tmp-isolated         = PASS rc=0 want=0 state=PASS hits=0
SELFTEST ASSERT S13 临时目录落在 $TMPDIR=…/tmp 之下 = PASS
SELFTEST CASE S14-unknown-ext          = PASS rc=0 want=0 state=PASS hits=0
SELFTEST ASSERT S14 未认领扩展名的 NUL 进了 DIAG（可见） = PASS
SELFTEST CASE S15-live-tree            = PASS rc=0 want=LIVE state=PASS hits=0
SELFTEST ASSERT S16 共享 /tmp 上 nulb-run.* 残留 = 0 = PASS
NULBYTES_SELFTEST_SELF self=…/nul-bytes-check.sh sha16=409d83d945f7d563
NULBYTES_SELFTEST_ROSTER sandbox=/tmp/nulb-selftest.h8t3U5 cases=31 pass=31 fail=0 not-as-expected=0 tmpbase=/tmp/nulb-selftest.h8t3U5/tmp
NULBYTES_SELFTEST=PASS total=31 pass=31 fail=0
ST_ATTEST=PASS self=…/nul-bytes-check.sh sha16=409d83d945f7d563（自测期间本件未变 ⇒ 读数可归因）
```

逐例要点（**判据先写、读数后取**；每条"必红/必 NOINFO"都是**两极化**而不是单点）：

| 例 | 构造 | 期望 | 它防的坑 |
|---|---|---|---|
| `S01-clean` | 合成树：白名单 4 件（`a.c`/`b.h`/`c.md`/`sub/e.py`）＋ `.png` 1 ＋ 未认领 `.zzz` 1 ＋ 无扩展名 1 ＋ `obj/` 里 1 | `rc=0` 且 **覆盖面恰 4 件** | "声明真按声明走"的定点读数（不是"大概扫了"） |
| `S02`/`S03` | **注入 1 个 NUL** → **还原** | `rc=1` 且点名 `offset=17 line=3 n=1` → `rc=0` | **"注入必红"＋"还原回绿"成对**（防"检查器抓不住东西却永远绿"） |
| `S04` | 同一 NUL 放进 **`.png`** | `rc=0`（**不算命中**），且该件**出现在 `--list-notscanned` 清单里** | 反极性 +「看不见 ≠ 没发生」：不判它，但**必须看得见** |
| `S05` | 同一 NUL 放进 **`obj/a.c`** | `rc=0`，且 `NULBYTES_SKIPDIRNAME obj:1` | 证明排除目录**真的**被排除（不是"恰好没扫到"） |
| `S06` | 空树 | `rc=2 NOINFO reason=empty-roster` | **空覆盖面不许当绿** |
| `S07` | 合成树上开 `NULB_ANCHORS=strict`（无 `verify-all.sh`） | `rc=2 NOINFO reason=anchor-missing` | **射程缩水不许绿** |
| `S08` | `NULB_MIN_FILES=999999` | `rc=2 reason=too-few-files` | 件数下限是**活的**（不是写死的装饰） |
| `S09` | `NULB_PYTHON=/nonexistent/python3` | `rc=2 reason=python-missing` | 仪器缺失 ⇒ `NOINFO`（不是"没命中所以绿"） |
| `S10` | 树里**真有** NUL ＋ `NULB_TEST_BLIND=1`（扫描器不读内容） | `rc=2 reason=scanner-blinded` | **弄瞎后既不绿、也不冒充红** |
| `S11` | `NULB_CANARY_BREAK=1`（把 NUL 只放到白名单外的夹具） | `rc=2 reason=canary-blind` | 证明内置金丝雀**是活的**（不是"永远 ok"） |
| `S12` | 9 MiB 干净件 ＋ 尾部 NUL | `rc=1` 且 `offset=9437186 line=2` | **分块读（1 MiB）不许漏尾** —— W83A 骨架里那套 `MAXSZ` 分叉路径的回归 |
| `S13` | 传 `NULB_TMPDIR` 后看 `NULBYTES_TMPDIR=` | 落在 `$TMPDIR` 之下 | 并发车道各跑各的（纪律 63：`#28` 有车道没隔离 `TMPDIR` ⇒ 同脚本三次三结果） |
| `S14` | 未认领扩展名 `.zzz` 里注入 NUL | `rc=0` ＋ `NULBYTES_DIAG kind=otherext-nul path=a.zzz` | 判据外的 NUL **只报不判但可见** |
| `S15-live-tree` | **真树**、锚全开 | **不许 `NOINFO`**；`rc=0 ⇒ hits=0`／`rc=1 ⇒ hits>0`（**状态与 rc 自洽**）＋ `canary=ok` | 生产路径也在自测里跑（不是只测夹具） |
| `S16` | 共享 `/tmp` 上 `nulb-run.*` 计数 | `= 0` | 生产临时目录**必须自清**（`--debug-tmp` 才保留） |

另外两条**自证**（`D-G41` 家族）：`ST_ATTEST=OPEN/PASS`（**自测期间本件被改写就报 `NOINFO rc=2`**，
免得"父进程按旧版造夹具、子进程按新版判定"出凭空的红）；`SELFTEST_ROSTER` 行里带 `not-as-expected=0`
（"rc 与期望不符"的例单独计数，不与其它失败混）。

---

## 5 · ⑤ 接线草案（**逐字，不落地** —— 属于波 `#51`）

⚠️ **本件没有落地任何一条**：`verify-all.sh`／`build/close-wave.sh`／`docs/WAVE*-PREREGISTRATION.md`
**一个字节未动** —— 现场（本件收工时刻现算）`verify-all.sh` sha16 **`227623000850ca5d`**、
`build/close-wave.sh` sha16 **`f440ccdb4e29a942`**（后者与 `#50` 收尾链自报值一致 ⇒ 无人动过它）。

### 5.1 为什么它适合当门禁步

| 维度 | 现场实测 |
|---|---|
| 判据形态 | 纯读（`open(...,'rb')`）、**零 `dotnet`**、**不动树**（不写、不删、不改 mtime） |
| 成本 | **0.405 s／趟**（1170 件 / 249.9 MB）；自测 1.2 s（**不进**门禁路径） |
| 世代成本 | **零**：不动九位／不动 `GEN_KEYS`／不动 `known-red.json` |
| 失败方向 | 算不出来 ⇒ `NOINFO`（`rc=2`）⇒ 门禁判 ❌；四条锚 ＋ 两条"读不出就不许绿"防射程缩水 |
| 它防的事 | `D-G82` 那一族**今天没有牙**（W83A 报告 §6 第 2 条自己点名的"可选的新牙"）：谁再敲进一个 NUL，**没有任何东西会响** |

### 5.2 逐字补丁草案

**（1）`verify-all.sh` 头注释的 `DECL` 块 —— 在最上面插一行**（旧行 `26 gen=#50` **原样保留**在下面；
读者 `decl_line()` 取**第一条** ⇒ 第一条才是当前口径；史实行只许追加、不许改）：

```
# VERIFYALL-STEPS-DECL: 27 gen=#51   ← `#51` **加一步**（26 → 27）：第 `[27]` 步 `NUL-BYTES` —— `D-G82` 的牙（`TASK-9907`）：判「**被判二进制、本意是文本**的源件」，即**声明覆盖面**（扩展名白名单 ＋ 基名清单 ＋ 基名 glob，排除 `upstream/**` 与 `obj|bin|.artifacts|__pycache__|TestResults`）里**不许有真 NUL 字节**（现场 1170 件 / 249.9 MB，`hits=0`）。三态 `NULBYTES=PASS|FAIL|NOINFO` ＋ **内置金丝雀**（每次真跑先自证扫描器没瞎、偏移/行号算得对、声明被遵守）；**纯读、零 `dotnet`、≈0.4 s**；本步不改产品件 ⇒ 九位逐位不动。四处声明（`DECL`／`STEP-NAMES`／口径句／预登记 H1）**同趟**改。**步数：26 → 27**）
```

**（2）同文件头注释的「收官起 = N 步」口径句 —— 在最上面（`#50` 那段之前）插一段**
（判据是 `grep -qF "**\`#51\` 收官起 = 27 步**"` ⇒ 这半句**必须逐字出现**）：

```
#   **`#51` 收官起 = 27 步**（**加一步**：第 `[27]` 步 `NUL-BYTES` —— `TASK-9907`／`D-G82`：
#     判据 = `build/MilBridge/tools/nul-bytes-check.sh`（声明覆盖面里不许有真 NUL 字节；
#     三态机读行 `NULBYTES=`；**内置金丝雀**每次真跑先自证）。**纯读、零 `dotnet`、≈0.4 s**、
#     不动九位。⚠️ 若同趟把它纳入 `fp_inputs()` 的 `printf` 名单，**必须安排在 `IN_FP_0` 采样之前**。
#     判据与逐例自测（31 例）见 `build/MilBridge/W97A-report.md`。）
```

**（3）同文件头注释的 `STEP-NAMES` 行 —— 第一行末尾追加**

```
 | NUL-BYTES
```

即第一行由 `… | THIRD-PARTY | R-GATE（连续交互）` 变为 `… | THIRD-PARTY | R-GATE（连续交互） | NUL-BYTES`
（⚠️ ` | ` 分隔、**名字一字不差**：现场 `run_step "NUL-BYTES" …` 的第一个参数必须**逐字相同**，
包括这条里的空格 —— `verify-all-step-check.sh` 比的是**多重集合＋次序＋无重名**）。

**（4）步骤本体 —— 在 `[26] R-GATE` 的 `run_step` 之后、结论区之前插入**（锚用现成的 `run_step` 行，
**不许**用 `echo "====="`——它在本文件里有 4 处）：

```
# ── 【`#51` W97A 加：第 `[27]` 步 `NUL-BYTES` —— 「被判二进制、本意是文本」的源件牙（`D-G82`）】──
#   `D-G82`（缺陷册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2340`）：源件里出现**真 NUL 字节** ⇒
#   `file` 判 `data`／`grep -n` **rc=0 但 stdout 0 字节**（行号静默消失），而本仓**一切判据都建在
#   「文件:行」上**。`#50` W83A 修掉了仓内唯一一件（`wic_proxy.c:289` 的 3 个 NUL），并明确登记
#   "**修了一次、没有牙**" ⇒ 本步就是那颗牙（新建工具 ＋ 判据见 `build/MilBridge/W97A-report.md`）。
#   判据：声明覆盖面里 `hits` 必须为 0；三态 `NULBYTES=PASS|FAIL|NOINFO`（`NOINFO` 在门禁里同样是 ❌）。
#   **纯读、零 `dotnet`、≈0.4 s**（现场 1170 件 / 249.9 MB）。
echo
echo "[27] 源卫生：声明覆盖面里不许有真 NUL 字节（D-G82 的牙；只读、零 dotnet、≈0.4 s；#51 加）"
run_step "NUL-BYTES" bash build/MilBridge/tools/nul-bytes-check.sh
```

**（5）预登记 —— 加在 `docs/WAVE51-PREREGISTRATION.md` 的 H 段（机器行，逐字）**

```
> `#51` H1：门禁加第 `[27]` 步 `NUL-BYTES`（`TASK-9907`／`D-G82` 的牙）——
> 步数 **26 → 27**；判据 = `build/MilBridge/tools/nul-bytes-check.sh`（sha16 见 W97A 报告）；
> 现场读数 = `NULBYTES=PASS files=1170 hits=0`（rc=0，0.405 s）；四处声明**同趟**改。
> ⚠️ 若同趟把该件纳入 `fp_inputs()` 的 `printf` 名单 ⇒ **`inputs_fp` 必变**（设计性变更，须在 `IN_FP_0` 之前完成）。
```

**（6）可选但推荐（**第 5 处**，属"判据改了自己没人看着"那条纪律）：`fp_inputs()` 纳入本件**

在 `build/close-wave.sh` 的 `printf '%s\n' …` 名单里插一行（放在其它判据件同一组，例如
`build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh \` **之前**）：

```
          build/MilBridge/tools/nul-bytes-check.sh \
```

⚠️ 代价**必须同趟声明**：这一改**会**动 `inputs_fp`（§6 有机械证），流程上**必须安排在 `IN_FP_0` 采样之前**。

### 5.3 接线时**不必**改的件（免得白改）

- `build/MilBridge/tools/verify-all-step-check.sh`：它的判据是**从现场现算**（`decl_line` 取第一条口径句、
  `extract_names` 取 `^run_step "`）⇒ 四处声明改对了它自然绿，**不许**去改它。
- `build/close-wave.sh` 的 `GEN_KEYS` 与九位：本步**不改产品件** ⇒ 九位逐位不动（现场 `tools_sh=30` 只影响
  `fp_inputs`／`wave_fp`，不影响九位）。
- `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（冻结基线）：本步与它无关，**不许碰**。

---

## 6 · ⑥ `inputs_fp` 影响判断（**机械核**）

### 6.1 方法（不重写逻辑）

照 `build/MilBridge/tools/fp-inputs-hygiene-check.sh` 的**同码路径拦截**手法：把 `build/close-wave.sh` 里
`fp_inputs()` 的**函数体原样抽出**（`sed -n '/^fp_inputs()/,/^}/p'`，**一字不改**），在 `PATH` 前置一个同名
`sha256sum` shim 记录它收到的 argv，再 `exec /usr/bin/sha256sum` ⇒ 拿到**真正被哈希的件清单**。
真值则直接 `eval` 同一份函数体跑 `fp_inputs`。

### 6.2 读数（三件事实）

| 项 | 建件前 | 建件后 | 结论 |
|---|---|---|---|
| 覆盖面**件清单**（147 行） | sha16 `7391e7521604d292` | sha16 `7391e7521604d292` | `diff` **逐字节相同** ⇒ 清单没变 |
| 本件 `build/MilBridge/tools/nul-bytes-check.sh` 在清单里？ | — | **0 命中** | ⇒ 新建它**不进**覆盖面 |
| 真 `fp_inputs()` | `ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48` | 同值（三读：17:43／17:47／17:51） | ⇒ **`inputs_fp` 不动** |

⇒ **本件的交付（新建工具）对 `inputs_fp` 影响 = 零**（这一点很重要：波 `#50` 已冻结，
交付本身不许碰任何冻结位）。

### 6.3 但"接线"会动（$HOME 副本模拟，**不碰仓内件**）

把本件路径按 §5.2(6) 插进 `printf` 名单的**副本** ⇒

```
接线前 fp = ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48
接线后 fp = 80c6fa0fa91f4fbe746f91fba78cbabbdd633e2bd3588e3bc0f2be75e5fff3e7
逐位相同? False
```

⇒ **它一定会动 `inputs_fp`** ⇒ 按仓内既有流程代价（`tline-gate.sh`／`known-red.json`／四件判据件同族）：
**"改门禁/改覆盖面成员" 必须安排在 `IN_FP_0` 采样之前**，否则 `close-wave.sh` 自己的 `[4/6]`
输入稳定性会 `exit 5`。

### 6.4 另一条**已确认无害但此前无人登记**的射程

`build/integration-wave.sh:97-99` 的 `wave_fp()` 里有（逐字复制该子句现场跑）：

```
find build/MilBridge/src build/MilBridge/tools build/MilBridge/tests -type f \
    \( -name '*.cs' -o -name '*.csproj' -o -name '*.sh' -o -name '*.py' \) \
    ! -path '*/bin/*' ! -path '*/obj/*'
```

⇒ 件数 **106 → 107**，本件**在里面**（`find build/MilBridge/tools -maxdepth 1 -name 'nul-bytes-check.sh'` = 1）。
它是 `integration-wave.sh` **自己的**"波前/波后"指纹（同一次运行内两读，**不落盘、不冻结、不跨波比对**）
⇒ **无害**；但"**新建判据件会被 `wave_fp` 看见**"这件事，此前**没有人在任何报告里登记过**（W83A 只核了
`fp_inputs()`）⇒ 记在此处备查。

---

## 7 · ⑦ `NOINFO` / 边界（**不许被读成"全仓 0 件"**）

1. **`upstream/**` 域未测**（6417 件）：按"非本仓自有代码"排除 ⇒ 该格**`NOINFO`**（与 W83A 同口径）。
   本报告里的"全仓"严格指**本仓自有代码**（排除 `upstream/` 与产物目录）。
2. **判据外三类的 NUL 只 `DIAG` 不判红**：11 件无扩展名件（**全含 NUL，首 NUL 恒在偏移 7 ⇒ 真 ELF**）
   ＋ 未认领扩展名件（现场 0 件）＋ `NULB_BINEXTS` 类（280 件，按定义就是二进制）。
   ⇒ 本件的 **`PASS` 只等于「声明覆盖面里 0 件含 NUL」**；主控若要**把判据外那两类也判红**，
   改**一处**即可（`kind in ('noext','otherext')` 那段的分支），但那时要接受"真二进制被误伤"的风险
   —— **本件不替主控做这个裁定**，只保证它**可见**（`diag_noext_nonelf=`／`diag_otherext_nul=` ＋ 逐条 `DIAG` 行）。
3. **那 11 件 ELF 编译产物"该不该留在源码树里"仍未判** ⇒ `NOINFO`（W83A 已登记，本件只点数、不处置；
   现场 `noext=11` 与 W83A 的 11 件**同集合**）。
4. **`.log` 的取舍代价**：纳入 ⇒ 今天有读数（14 件、NUL=0）；将来若某车道产出含 NUL 的日志 ⇒ 本步红。
   那时"红是对的"还是"该移出白名单"**由主控裁定**（件头已写死，不静默豁免）。
5. **本件不判"该文件该不该存在于这棵树下"**（那是 `BuildHygiene` 一族的事）；也不判
   "`\0` 是不是该写成转义"（`D-G82` 的判据是"**有没有真 NUL 字节**"）。
6. **`NOINFO` 例的诚实边界**：`S09-python-missing` 那例的 `hits=none`（因为根本走不到扫描）
   —— 这**正是 `NOINFO` 该有的样子**（不绿、也不冒充红），逐字留在 §4 的读数里。
7. **本件不改任何既有件**：`wic_proxy.c`（已修）、11 件 ELF、任何 `.log` **一件未处置**（派单书要求）。

---

## 8 · ⑧ 重活 / 负载台账（**本件应为 0 重活** —— 实测 0）

| 项 | 值 |
|---|---|
| `dotnet` 调用次数 | **0**（`dotnet` 不在 `PATH` 也没被调用过；本件只用 `bash`／`python3`／`file`／`find`／`od`／`sha256sum`） |
| 构建 / 应用 / X | **0**（未跑 `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／任何 `dotnet`；未起 Xvfb／未跑 hc 应用） |
| 重活槽 | **未占**（W98A 的长跑不受本件影响） |
| 跑过的**只读**已接线牙 | `shell-quote-trap-check.sh`（`SHELL_QUOTE_TRAP=PASS traps=0 files=151`，rc=0）、`pipefail-sigpipe-check.sh`（`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 files=68 sites=81`，rc=0）—— 两者**都扫 `build/MilBridge/tools/**.sh`** ⇒ 本件落在它们扫描集里，**必须**当场自证不把它们打红（**本件 0 命中**，两趟都 PASS） |
| 本件自身成本 | 真跑 **0.405 s**／自测 **1.2 s** |
| `loadavg` | 开工 `1.47, 1.17, 1.12` → 收工 `1.50, 1.48, 1.29`（同机另有两条车道在跑） |
| `MemAvailable` | `2462120` kB（单点读数，**未做连续采样 ⇒ 不声明最低值**） |
| 临时件 | 全部落在**自己的** `mktemp -d "$TMPDIR/nulb-*"` 之下，收尾自清（自测 S13／S16 钉住；`--debug-tmp` 才保留） |

**写域自查（机器，逐条）**：`find . -path ./upstream -prune -o -type f -newermt '2026-09-22 17:41:00' -print`
（再排除产物目录）现场命中**恰好 6 件**，**其中只有 2 件是本件**：

```
./build/MilBridge/tools/nul-bytes-check.sh        ← 本件（新建工具）
./build/MilBridge/W97A-report.md                  ← 本件（本报告）
./build/MilBridge/W99A-report.md                  ← **W99A**（登记车道，不是本件）
./build/MilBridge/tools/defect-registry-declared.tsv ← **W99A**
./docs/ROUTES.md                                  ← **W99A**
./samples/WpfFeatureProbe/KNOWN-DEFECTS.md        ← **W99A**
```

⇒ **本件写域外零写入**（另一条车道 **W98A** 在跑应用腿、只写 `$HOME/w98a/STATUS.md`，**未写仓内件**）。
⇒ 这也是 §3.2 那 57 B `bytes=` 差的来源（W99A 在改动覆盖面内的登记/路由件）。

---

## 9 · ⑨ ≤6 行大白话小结

1. `D-G82` 那种事（源件里混进一个真 NUL，害得 `grep -n` **说成功却不给行号**）此前**修了但没人看着**，
   本件给它造了那颗牙：`build/MilBridge/tools/nul-bytes-check.sh`（sha16 `409d83d945f7d563`），**没接线**。
2. 现在全仓**该看的 1170 件里 0 件含 NUL**（`NULBYTES=PASS files=1170 hits=0`，0.4 秒），另一台独立仪器
   （libmagic）对同一份清单也说"没有一件被判成二进制"。
3. 最能说明它有用的实验：把 W83A 留的**修前**旧文件放进沙箱，它当场报
   `offset=15873 line=289 n=3`，**和 W83A 当年独立算出来的数字一模一样** ⇒ 它本来就能抓住这个缺陷。
4. 自测 31 例全过，其中"**注入 1 个 NUL 必红、还原回绿**""NUL 放到非白名单/排除目录里**不算命中**"
   "把扫描器**弄瞎**或**读不出东西**⇒ 一律 `NOINFO`（不许绿）"都是成对读数，不是单点。
5. 它**没接进门禁**（`#50` 刚冻结，加步会打破步数声明）；报告 §5 给了**四处＋两处的逐字补丁**，
   接线那一趟必须**同趟**改，且若把工具纳入 `fp_inputs()`，**必须赶在 `IN_FP_0` 采样之前**。
6. 交付本身**不动任何冻结位**（机械核：`inputs_fp` 三读同值 `ee543f44…`）；唯一的意外发现是
   `integration-wave.sh` 的 `wave_fp()` **本来就会看见新判据件**（106→107 件）—— 无害，但以前没人登记过。

---

## 附 · 给主控的三条落地建议（**本件都不落**，因写域外）

1. **接线**（波 `#51`）：按 §5.2 的 (1)(2)(3)(4)(5) **同趟**改四处声明 ＋ 插一步；顺手把 §5.2(6)
   纳入 `fp_inputs()` 并在预登记里声明"`inputs_fp` 设计性位移"，**全部安排在 `IN_FP_0` 之前**。
2. **登记**：把本件写进 `docs/ROUTES.md` 的树行与任务表（建议新任务号 `TASK-9907` 已由派单书给出；
   若地图里那个号被占用请顺延），判词逐字可抄本报告 §0.2 的机读行。
3. **要不要把"判据外的 NUL"也判红**（§7.2）：本件**故意不替主控裁定** —— 若要判，改一处分支；
   若不判，建议把 `diag_noext_nonelf=`／`diag_otherext_nul=` 两格写进下一波的登记（让"看见"这件事有留痕）。
