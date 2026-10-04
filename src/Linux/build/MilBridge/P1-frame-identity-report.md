# `P1`／`t124` 载体：`N1`（帧身份＋帧位移）**装置侧格 ＋ 守卫接线**报告

**一句话**：`t118` 的 `N1`（**帧身份 ∉ 空态参照集** ∧ **帧位移 > 0**）今天从**判据文本**变成**守卫里可判的要件** —— 先补 `t122` 点名的**装置侧取值格**（`FRAME` 行 → `leg_<k>.env` 第五段），再把两要件落进 `build/MilBridge/tools/pts-pages-guard.sh`（**`realized` 期判／`degraded` 期只 `INFO`／取值缺 ⇒ `NOINFO` ＋ `cannot`**），并给四条极性腿、成对读数与因果证明。**只增不改、不动三态与阈值**。

## §1 装置侧取值格（`session_inner.sh` ＋ `legs-to-env.py`）

- **行形（原文）**：`FRAME k=<k> fr_file=<k<k>.png|-> fr_sha=<sha16|-> fr_lsha=<sha16|-> fr_ae_boot=<int|->`
- **现取确认（先查"装置是否已算过"）**：`t124` 之前 `session_inner.sh` 里的 `sha256sum` **只**用于 `five()`（五件）与 `shim_sha16=`／`pf_sha16=`；`last.png` 只被 `cp -f k$k.png last.png` 复制 ⇒ **三帧从未算过 sha** ⇒ 本件是**新增算量**，不是"已算过、只落格"。
- **口径（逐字）**：
  - `fr_file=` ＝ 本腿截图的**文件名**（`k<k>.png`）；截图没落 ⇒ `-`。
  - `fr_sha=` ＝ 该文件 `sha256sum` 的**前 16 位**（**与 `five()`／`shim_sha16=` 同一算口径**）；读不到 ⇒ `-`。
  - `fr_lsha=` ＝ **同一时刻** `last.png` 的前 16 位；装置在该点之前刚做 `cp -f k$k.png last.png` ⇒ **`fr_lsha == fr_sha` 是装配不变量**（不同即装置异常，如实印出）。
  - `fr_ae_boot=` ＝ `compare -metric AE boot.png k<k>.png`（**该帧相对 `boot` 的像素位移**，整数）；算不出 ⇒ `-`。
  - **`-` 的语义 ＝ 没测到**（不是 0、不是绿）——与 `FAILLINE`／`ink=` 同一约定。
- **位置与解析**：落在 `CLICK` 与 `PHASE` 之间 ⇒ 转换器 `legs-to-env.py` 的**既有 region token 扫描自动带走**（**不新增解析器**）。⚠️ **键名一律不含数字**：region 扫描的键词法是 `[A-Za-z_]+`（`fr_sha16` 这类名字**根本扫不到**）——这是本件第一版差点踩空的一格。
- **只增证明（`git diff --numstat` 现取）**：`session_inner.sh` ＝ `28 0`（**零删除**）；`legs-to-env.py` ＝ `20 1`（那 1 行是 `return dict(...)` 的**续行**：同一表达式追加 4 个字段，**无既有字段被删**）；**老产者 env vs 新产者 env ⇒ 每腿只差 1 行（`4a5`：新增 `FRAME` 行）**，既有四段逐字节相同；`need` 列表现取未动（`["alive","AE","pts_unavail","pts_gap","ns_last"]`）。
- **装置仍工作的间接证明（五条，全部现取）**：
  1. `bash -n build/MilBridge/tests/PtsPagesProbe/session_inner.sh` ⇒ **OK**（新块一并过语法）。
  2. `python3 -m py_compile build/MilBridge/tests/PtsPagesProbe/legs-to-env.py` ⇒ **OK**。
  3. **转换器往返**：真 session（**旧格式**，无 `FRAME` 行）⇒ `FRAME k=23 fr_file=- fr_sha=- fr_lsha=- fr_ae_boot=-`（**向后兼容**）；同一 session **注入** `FRAME` 行 ⇒ 转换器给出**真值**（`k=23`: `fr_sha=7e6f97a8ed58739a fr_ae_boot=189862`；`k=24`: `fr_sha=61bf91f386f521f7 fr_ae_boot=221857`）⇒ **计数器有响应**。
  4. **既有解析不破**：同一旧 session 分别喂老/新转换器 ⇒ 每腿仅多 `FRAME` 行，前四段逐字节相同（见上）。**另**：`app_g1.log` 侧交叉核对（`managed err` 两口径一致、`pts_unavail` 计数与具名行一致）仍为**响亮失败**语义，未被触碰。
  5. **抽取自证（真件里那一块原样抽出来跑）**：`sed -n '/^    _fr_sha="\$(sha256sum/,…/p'` 抽出补丁后真件的 17 行到仓外脚本，喂**真 PNG**（`~/w67-work/logs/legs-after/shots/g1/`）⇒ `k=23 ⇒ fr_sha=7e6f97a8ed58739a fr_lsha=- fr_ae_boot=189862`、`k=24 ⇒ fr_sha=61bf91f386f521f7 fr_lsha=- fr_ae_boot=221857`，与独立复算（`sha256sum | cut -c1-16` ＝ `61bf91f386f521f7`、`compare -metric AE boot.png k24.png` ＝ `221857`）**逐位相同**；在仓外目录先 `cp -f k24.png last.png` 再抽 ⇒ `fr_sha=fr_lsha=61bf91f386f521f7`（**装配不变量当场兑现**；静态目录里 `fr_lsha` 与 `fr_sha` 不等只是"那不是同一时刻的 `last.png`"，故**不变量只在装置序列里成立**）。
- **`NOINFO(未跑腿)`**：本件**没有**任何端到端**真腿**读数（派单**禁跑腿**）⇒ 上面五条均为**间接**证明；`FRAME` 行在真腿里的取值**待下一趟腿**。

## §2 守卫接线（`pts-pages-guard.sh`）

- **登记处（件头，唯一）**：`FRAME_EMPTY_SET="1a76488aa4a790b3"` —— 语义 ＝ **已登记**的「空态回退画面」帧身份；**旧登记 `ef3fd6765f18f51b` 作废**（画面换版）；**不设 env 旋钮**（不给"把现帧写进集合即绿"的路子）；重登记触发＝①相位翻转包执行 ②三帧 `sha256` 变化 ⇒ **本件写者**。
- **判定（`judge_legs` 每腿，取值来自 `leg_<k>.env` 的 `FRAME` 行）**：
  - **`realized` 期**：**要件①** `fr_sha` ∉ `FRAME_EMPTY_SET` ∧ **要件②** `fr_ae_boot > 0`；**任一不满足 ⇒ 红并点名** —— 判词行印 `file=`／`fr_sha`／`in_empty_set`／`fr_ae_boot`／`set=`／`criterion=`（`frame-identity(sha16=…∈{…})` 与／或 `frame-displacement(ae_boot=0)`），并附一行 `N1-EMPTY-FRAME`／`N1-NO-DISPLACEMENT` 说清现象；`fails+=("leg$k-n1-frame-unestablished(…)")`。
  - **要件都成立** ⇒ `PTS_N1=PASS … criteria=frame-identity,frame-displacement`（**不进 `fails`**）。
  - **`degraded` 期**：**只印 `PTS_N1=INFO …`**（含实测 `in_empty_set`／`fr_ae_boot`），**不动**本相位判词（**照 `t122` 的做法**）。
  - **取值缺／不可解析**（旧格式腿、截图没落、`-`、非 16 进制）⇒ `PTS_N1=NOINFO reason=frame-cell-missing-or-unparsable(missing=…)` ＋ `cannot+=("leg$k(n1-frame-cell-missing=…)")` ⇒ 判词至少 `NOINFO`（**绝不当绿**）。
  - **不动**：其它要件、三态语义（`PASS`／`FAIL`／`NOINFO`）、阈值（`MAGENTA_FLOOR` 等）、`colors` 诊断带、`ae=0` 诊断、方向口径闸、`G10`／`ENFE`／`C4` 三面。
- **只增证明**：`git diff --numstat build/MilBridge/tools/pts-pages-guard.sh` ＝ **`109 0`（零删除）**；尾部索引块亦为新增。**自测 `PTS_GUARD_SELFTEST=PASS pass=55 fail=0`**（`t122` 后 46 ⇒ 本件 **+9** 条断言：a/b 因果 2 条、位移 0 点名、缺格 `NOINFO`、`degraded` 只 `INFO`、以及 `realized` 侧其余）。

## §3 成对读数（**全部本席现算**；夹具仓外、用完删）

| # | 构造（同一夹具、只动一格） | 判词 | 判据行 |
|---|---|---|---|
| a | `fr_sha=1a76488aa4a790b3`（∈ 登记集） | `PTS_GUARD=FAIL` | `criterion=frame-identity(sha16=1a76488aa4a790b3∈{1a76488aa4a790b3})` |
| b | **只**把 `fr_sha` 改成 `c0ffee1234abcd99`（∉ 集；`diff` 证明每腿**只差 1 行**） | `PTS_GUARD=PASS` | `criteria=frame-identity,frame-displacement` |
| a′ | **修前**（`t122` 后、`t124` 前）的守卫跑同一 (a) 夹具 | `PTS_GUARD=PASS`，**`PTS_N1` 行 0 行** | — |
| c | `fr_ae_boot=0`（其余同 b） | `PTS_GUARD=FAIL` | `criterion=frame-displacement(ae_boot=0)` |
| d | **删掉** `FRAME` 行（其余同 b） | `PTS_GUARD=NOINFO` | `leg2x(n1-frame-cell-missing=fr_sha,fr_ae_boot)` |
| e | `degraded` 期同一夹具（**真值格在位**）：修前 vs 修后 | `PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded` **两条逐字相同** | 修后**多** `PTS_N1=INFO` 两行 |
| f | 转换器只增：老产者 env vs 新产者 env；旧格式 session | 每腿**只差 1 行**（`4a5`）；旧格式 ⇒ `fr_sha=-` 等四格 | — |

**因果证明**：`a`／`b` 两份夹具的 `leg_24.env` 排序后 `diff` ＝ **2 行**（`<`／`>` 各 1，且**只**涉及 `FRAME` 行的 `fr_sha`）⇒ verdict 由 `FAIL` 翻成 `PASS` **只能**由该格引起；`a′`（修前）为 `PASS` 且**无 `PTS_N1` 行** ⇒ 该判据**是**本趟新增的判据、**没有**别的东西在同时改判词。

## §4 现值变化与未闭项（**如实点名**）

- **旧格式腿的判词变化（有意的收紧）**：无 `FRAME` 行的腿在 `degraded` 期多出 `cannot=…n1-frame-cell-missing…`。现场成对（同一**干净**夹具）：修前 `rc=0 PTS_GUARD=PASS` ⇒ 修后 `rc=2 PTS_GUARD=NOINFO`。**仓内在册证据目录** `build/MilBridge/tests/PtsPagesProbe/evidence` 那条：修前/修后 `fails=` **逐字相同**（`FAIL` 由既有 `fails=` 决定），只在 `cannot=` 加 `leg24(n1-frame-cell-missing=…)`／`leg23(…)` 两格。⇒ 与 `t122` 的「缺日志 ⇒ `cannot`」同档：**缺格不许当绿**；打过补丁的装置**一律带格** ⇒ 只影响**历史证据件**。
- **未闭的一格（本席未扩集、只登记）**：在册证据目录**现势**（`shotstat` 现读）：`k23.png` ＝ `1a76488aa4a790b3`（189742 B、`colors=384 magenta=0 ink=480000`）、`k24.png` ＝ `last.png` ＝ `2a60a00fc582e97d`（311 B、**`colors=1 magenta=0 ink=0`** ＝**整屏单色空拍**）、`boot.png` ＝ `b21eb530afd3c66c`。⇒ ① **`t122` 登记前提"三帧同值"在在册证据目录里已不成立**（`k24`/`last` 换成了空拍）；② 空拍帧 **∉ 登记集** 且 `AE(boot,k24)=480000>0` ⇒ **`N1①②` 都不红它**；③ **兜住它的是既有 `ink>0`**（`realized` 期 `ink=0` ⇒ `no-real-ink` 必红）⇒ **不是新洞**。**是否把"整屏单色空拍"并入空态参照集**（＝收紧，且触发②已被本件读数触发）⇒ **建议由守卫写者在收口时裁定**；本件按派单**只写"现取"值 `{1a76488aa4a790b3}`**、未擅自扩集。

## §5 牙读数（**现取 rc**；仓根 `feat-Linux`）

| 牙 | rc | 关键读数 | 归因 |
|---|---|---|---|
| `report-id-domain-check.sh` | 0 | `REPORTID=PASS` | 本件新增引用无未登记编号 |
| `defect-registry-check.sh` | 0 | `DEFREG=PASS declared=224 route_ids=224`；`DEFREG_DECLDRIFT=1 keys=KD`（**只诊断、不判红**） | KD 漂移＝route 文件改后未装盘（见 §6／ROUTES `t124` 段） |
| `handoff-machine-values-check.sh` | 1 → **0** | 修前 `HANDOFF_MV=DIVERGED`：`cell=#1 … rule=cell-mismatch reason=covered-file-changed-since-ts in-repo=064afdae… live=cdacf950…`（本席取值时刻）；**同趟 `cell=#1` 追写后现取 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`** | **本趟覆盖面内件被改**（本件三件）⇒ 按第 `28` 条同趟登记 |
| `sentinel-spec-check.sh` | 0 | `SSC_LINES/KEYSET/CR/BLANK/EMPTY=PASS` | 未动哨兵 |
| `shell-quote-trap-check.sh` | 0 | `SHELL_QUOTE_TRAP=PASS canary=OK` | 新代码无引号陷阱 |
| `pipefail-sigpipe-check.sh` | 0 | `PIPEFAIL_SIGPIPE=PASS` | 新代码无 SIGPIPE 面 |
| `static-jaws-check.sh` | 1 → **0** | 修前 `STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62`，唯一 `HIT` ＝ **`HANDOFF-MV`**；**`cell=#1` 追写后现取 `STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`** | **非**本件判据面；是 `cell=#1` 未追写 ⇒ 同趟追写即清 |
| `pts-gap-count-check.sh --check` | 1 | `PTSGAP=FAIL`；`SITE-DRIFT docs/ROUTES.md impl want=86 got=87`、`so16=d0fe7f836a3ef7c1`、`FRONTIER_STATE=UNNAMED` | **他者项**（`docs/ROUTES.md` 的位点计数与 `.so` 换代）；本件未动 `src/**`、未动该计数字段 |
| `pts-gap-count-check.sh --selftest` | 0 | `PTSGAP_SELFTEST=PASS pass=12 fail=0 legs=12 must_red=7` | — |
| `pts-pages-guard.sh --selftest` | 0 | `PTS_GUARD_SELFTEST=PASS pass=55 fail=0` | 本件新增 9 条断言 |
| `pts-pages-guard.sh --legs <在册证据目录>` | 1 | 修前/修后 `fails=` 逐字相同；`cannot=` 加两格；`PTS_N1=NOINFO` | 见 §4 |
| `pts-pages-guard.sh --c4-ledger <证据目录>` | 0 | `PTS_C4_LEDGER=NOINFO reason=ledger-empty` | 台账空（一以贯之：不当绿） |
| `pts-pages-guard.sh --g10-name <证据目录>` | 0 | `PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed` | 与相位无关、未动 |

## §6 边界自证、不变量与指纹位移

- **写域（严格照派单）**：`build/MilBridge/tests/PtsPagesProbe/session_inner.sh`、`build/MilBridge/tests/PtsPagesProbe/legs-to-env.py`、`build/MilBridge/tools/pts-pages-guard.sh`、`build/MilBridge/P1-realized-criteria-report.md`（dated 追加）、`docs/ROUTES.md` §15af（dated 追加）、`build/MilBridge/HANDOFF-NEXT.md`（`cell=#1` ＋ `--emit` 口径索引一行）、本件。**未碰**：`src/**`、`build/Presentation*.Linux/**`、`build/WindowsBase.Linux/**`、判据件本体（除派单指定的 dated 追加）、`verify-all.sh`／`close-wave.sh`、哨兵、`samples/**`、`defect-registry-check.sh` 与 `defect-registry-declared.tsv`（判为无需改、且装盘归口 route 写者）。
- **备份面 ≡ 换代面（第 `29` 条）**：六件**写前** `stat -c %h` ＝ 1（无硬链接）、`cp -p` 到 `~/w281-scribe/t124/bak/*.pre-t124`，仓外；`docs/ROUTES.md` 一次误用"改写式编辑"后**已按 `cp -p` 备份原样恢复**（恢复后 `sha256sum` 前 16 位与备份**逐位相同** `b5bec159d5caa4e1`）再改为纯追加 ⇒ 现势 `9 0`、前 924 行与备份 `cmp` 相同。
- **不变量**：既有要件／三态／阈值**一字未动**（三件 numstat 删除数：`28 0`／`20 1`（续行表达式）／`109 0`）；`FRAME_EMPTY_SET` 取值**照派单写死**；转换器 `need` 列表未动；老格式向后兼容（`-`）。
- **指纹位移**：本趟改了**覆盖面内**三件（`tools/pts-pages-guard.sh`、`tests/PtsPagesProbe/{session_inner.sh,legs-to-env.py}`）⇒ `bash ~/w153a/bin/infp.sh fp` 现取见 §7（值以 `HANDOFF-NEXT.md` 的 `cell=#1` 行同趟登记为准）。**注意 `t123` 正在改 `src/**`（亦在覆盖面内）** ⇒ 这是**移动靶**：本件**只登记一次**、如实交**本席取值时刻**，收口对齐由队长统一做。**本席取值（现取、登记时刻同趟）**：`ts=2026-09-29T11:44:14.862267441+0800` 时 `bash ~/w153a/bin/infp.sh fp` ＝ `cdacf950562d7cd1ac1760bfddbaf07313146e34fa3316e18ee20a5c7bc823e8`（`HANDOFF-NEXT.md` 的 `cell=#1` 行**同趟**追写该值；追写后 `HANDOFF_MV=PASS`、`STATICJAWS=PASS`）。

## §7 未做项与原因（逐条）

1. **未跑腿**（派单禁跑腿／禁占显示位）⇒ 装置侧只有五条**间接**证明，真腿 `FRAME` 取值记 **`NOINFO(未跑腿)`**。
2. **未执行相位翻转包**（未派单；且硬前置 `N4` 正身份未闭）⇒ `F1`／`F4`／`F5`／`F6` 与 `c1–c19` 期望仍待办；本件只把 `F3` 的 `N1` 面**可判化**。
3. **未扩空态参照集**（§4 的空拍帧）：属"现取"口径之外的新增判定 ⇒ 建议收口裁定。
4. **未动 `defect-registry-declared.tsv`**：`--emit` 的装盘归口 route 写者／收口人（口径与证据见 ROUTES `t124` 段）；本件只用**仓外件**证明机制。
5. **未跑整趟门禁／未构建／未占显示位／未 `git add|commit|push`**（派单硬条款）。

**本件自证**：`head -n -1 build/MilBridge/P1-frame-identity-report.md | sha256sum | cut -c1-16` ＝ 608a6cc611340293（末行不计入自身）
