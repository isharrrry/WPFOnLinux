# `#77` 独立复验报告（t6 / verifier）

- 复验对象：`N=/home/links-dev/netTest/GitProj/WPFOnLinux`（git 树，`HEAD=d2dec07772946d8f73f816120886458fc7171454`，分支 `feat-Linux`）
- 复验者：`verifier`（独立车道，**不是** `waveman` 的复述；凡他报的数我都用**同一条命令自己再算一遍**，并优先去找"它会不会红"的那一面）
- 判据：**先写**于 `~/w27x/criteria.md`（21:50 之前，早于一切读数）
- 区间：2026-09-26 21:50 → 22:08（北京时间；第三趟 `verify-all` 21:51:21 起、22:07:15 止，`held=954s`）
- 写域：本报告是**唯一**写入 `$N` 的件（新增）；其余一切读数与夹具都在 `~/w27x/**`
- 资源现取（每趟重活前）：`df -Pk /` 第 4 列 = `111174096 KB`；`MemAvailable` = `9173 MB`；`swapfree` = `1301 MB`

---

## 0. 结论一句话

`#77` 的**主链读数**（冻结 sha、步数、覆盖面、冻后 `verify-all` ×3、推送、两哨兵、五臂日志 sha、四条牙的两极化）**逐项复算通过**，
但有 **7 句现场被推翻 / 打折扣**（全文见 §7）：① 冻结块九位行的 `provider` 是上一代值；② 「21 件旧路径重指向」里有 **5 处算错层数**，
新默认值指向 `$N/build` 而不是仓根（我**真跑了**那一行，不是看文本）；③ `porcelain=0` 现取是 **16 件脏**（跑前 15）；
④ 「九位只 `pf` 动」与⑤ 「两趟 post 唯一原始差异是 `wall_s`」两句与现场不符；⑥ 「`TASK-0745` 补丁未落」已被主控落地取代；
⑦ 「`app-local STALE=0 ∧ DIVERGENT=0`」只是点读数（本波内部两次就不一致），且我钉出**两个"权威"路径没有牙钉住相等**。
⇒ **本轮验收判 FAIL**（判词与命令原文全在下面；主链本身可用，修的是这几件声明与件）。

---

## 1. 独立复算清单与逐条读数（命令原文 ＋ 现算值）

### 1.1 九位 sha16（`bash -lc` 直取，路径逐字取自契约）

```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for f in \
  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
  build/PresentationCore.Linux/bin/Release/PresentationCore.dll \
  build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll \
  src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
  build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll \
  build/DirectWrite.Linux/wic-shim/libwpfwic.so \
  build/shims/PresentationCore.HbTextLine.cs \
  build/WindowsBase.Linux/bin/Debug/WindowsBase.dll \
  build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do
  sha256sum "$f" | cut -c1-16; done
```

| # | 位 | 现取（2026-09-26 21:50） | `#76` 冻结值 | `#77` 块**九位行** | `#77` 块**机读行**（`BASELINE tier=`） | 判定 |
|---|---|---|---|---|---|---|
| 1 | `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | 同 | 同 | 未动 ✓ |
| 2 | `pc` | `53fd7fffcdb30243` | `722e0ab8205b7c3f` | `53fd7fffcdb30243` | `53fd7fffcdb30243` | 位移（已声明）✓ |
| 3 | `pf` | `4fcd2ca021c39064` | `963c59991fd1f709` | `4fcd2ca021c39064` | `4fcd2ca021c39064` | 位移（环成员）✓ |
| 4 | `windowsbase` | `07c89f1872c1a3c1` | `2e4e46e539a72cd7` | `07c89f1872c1a3c1` | `07c89f1872c1a3c1` | 位移（已声明）✓ |
| 5 | `provider` | `4041df9a704abfed` | `1f9511a7ef395bfe` | **`1f9511a7ef395bfe`** | **`4041df9a704abfed`** | 🔴 **九位行陈旧**（见 §7-①） |
| 6 | `win32shim` | `fc60c34d51fd9247` | `fc60c34d51fd9247` | 同 | 同 | 未动 ✓ |
| 7 | `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 同 | 同 | 未动 ✓ |
| 8 | `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 同 | 同 | 未动 ✓ |
| 9 | `dwf` | `b07f801556e1a511` | `ce3469f49efcbcfa` | `b07f801556e1a511` | `b07f801556e1a511` | 位移（已声明）✓ |

- **五位位移的机械归因我独立证实**（不是引用冻结块的话）：五个受托管控件里各含 **恰好 1 条** `.../GitProj/WPFOnLinux/...pdb` 字符串、**0 条**旧路径字符串：

```
strings -a <五个件> | grep -c 'GitProj/WPFOnLinux'   # 每个都是 1
strings -a <五个件> | grep -c 'wpf-linux-20260906'  # 每个都是 0
例：build/PresentationCore.Linux/bin/Release/PresentationCore.dll
    → /home/links-dev/netTest/GitProj/WPFOnLinux/build/PresentationCore.Linux/obj/Release/PresentationCore.pdb
```
  且现取字节数与 `#76` 冻结值逐位相同（`pc 3601408`／`pf 6123520`／`windowsbase 1111552`／`provider 104448`／`dwf 39936`）⇒ 与"路径承载体（`D-G92` 同族）"一致。
- 证伪腿（防"我算错路径所以恒同一串"）：三条非托管件（`bridge`／`win32shim`／`wic_shim`）**本波未重建 ⇒ 逐位未变**，反证位移只发生在被重建的托管件上。

### 1.2 步数三处（＋1 条控制腿）

```
grep -c '^run_step "' verify-all.sh      → 50
grep -c  '^run_step'  verify-all.sh      → 51   ← 控制腿：少引号会变，证明我的模式有判别力
sed -n '1p' …(首个 DECL 行)              → # VERIFYALL-STEPS-DECL: 50 gen=#77
awk 'NR==113' verify-all.sh | tr '|' …   → 50 个步名
```
- `#76` 侧同法：`git show fd9a9a1:verify-all.sh | grep -c '^run_step "'` = **47**、`# VERIFYALL-STEPS-DECL: 47 gen=#76`；
  集合差 = **恰 3 个新名**（`WIRING-COVERAGE`／`PARSER-GUARD`／`PROTO-ATTR`）、**无删无改名**。
- **强一点的一刀**：把 `#77` 冻后日志里**真跑过的 50 个步名**抽出来与 `VERIFYALL-STEP-NAMES` 声明比 ⇒ **逐字相同（50==50）**。

### 1.3 覆盖面四处一致

```
bash ~/w153a/bin/infp.sh fp          → b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c（连算两遍同值）
bash ~/w153a/bin/infp.sh list | wc -l        → 211
bash ~/w153a/bin/infp.sh list | sort -u | wc -l → 211   ← 控制腿：无重复行虚增
[12] 机读行 → FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=211 artifact_n=0 missing_n=0 stderr_bytes=0
[42] 步本体 → run_step "FP-MANIFEST-TEETH" … --expect 211
[42] 机读行 → FP_MANIFEST_TEETH=PASS reason=ok files_n=211 files_n_uniq=211 declared_expect=211
```
⇒ `infp.sh fp`／`list|wc -l`／`[12] coverage_n`／`[42] --expect` **四者同值**，且与冻结块声明 `205 → 211`、`fp=b67560f2…` 逐字相符。

### 1.4 冻结块的其他现算对账

| 项 | 声明 | 现算 | 判定 |
|---|---|---|---|
| 基线整份 sha16 | `e3ebc811641bd467` | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `e3ebc811641bd467` | ✓ |
| 基线字节 | `BASELINE_BYTES=1138219` | `stat -c %s` = `1138219` | ✓ |
| `docs/CURRENT-STATE.md:9` | `gen=#77 sha16=e3ebc811641bd467` | 逐字同 | ✓ |
| `BRIDGE_SRC_FP` | `d697b1e10ff48881` | `bash build/bridge-src-fp.sh` = `d697b1e10ff48881` | ✓ |
| `[11]` 自指 sha | `vfile_sha16=9811e86e32fdfcb9` | `sha256sum verify-all.sh` = `9811e86e32fdfcb9` | ✓ |
| 五臂日志 sha16 | 块内 `# ARM-LOG-SHA arm=…` 五行 | 逐臂现算：`tab-anchor 1c43a12dcaa5718a`／`tab-zero 9150c3a26a3cb789`／`tab-rtl 92570318851ca7e8`／`tline 59a203de30d745a8`／`textlineproto 4bceceeed570ba70` | **5/5 逐位相符** ✓ |
| `COLUMN-CORPUS` | `0cebc0afd5142fbf` | `sha256sum tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` = `0cebc0afd5142fbf` | ✓ |
| 两哨兵 | BASELINE=#77、BASELINE_SHA16=`e3ebc811641bd467` | `cmp` IDENTICAL ＋ 内容与我现算九位逐位相同 | ✓ |

---

## 2. 冻后两趟 `verify-all` 的**逐趟**复算 ＋ 我自己跑的第三趟

### 2.1 两趟（`t5` 跑的）逐趟复算

| 趟 | 日志 | rc | 步骤 ✅ | 步骤 ❌ | 用例通过 | 跳过 | 结论行 |
|---|---|---|---|---|---|---|---|
| post1 | `~/w185a/w77/logs/w77-post1-20260926-211723.log` | 0 | **50** | **0** | 875 | 2 | `结论：✅ 全部通过` |
| post2 | `~/w185a/w77/logs/w77-post2-20260926-213212.log` | 0 | **50** | **0** | 875 | 2 | `结论：✅ 全部通过` |

- `❌` 在本仓日志里**同时**是"失败标记"又是汇总行的**字面**（`步骤通过 50  ❌ 失败 0`）⇒ 我不用 `grep -c ❌` 判红，改用 `步骤通过/失败 N` 与步骤横幅计数（**控制腿**：本波 `gate1` 第一趟曾真红过一次（`步骤通过 49 ❌ 失败 1`），证明这两个计数器**不是恒零**）。
- **判词行逐字一致性**：抽出两趟各 **129 行**判词域（`自报口径` 行 ＋ `机读 K=V` 行 ＋ 步骤横幅 ＋ 汇总），先做**归一化**（`/home/links-dev/*`→`<P>`、`/tmp/*`→`<TMP>`、时间戳→`<TS>`、`avail_kb|avail_gb|avail|mem_mb|wall_s|held`→占位）⇒ **差异 0 行**；**归一化之前**的原始差异是 **24 行**，逐条看全是路径/tmpdir/时间戳/内存余量/耗时（`LABEL_ONLY_DIFF` 一类），**没有任何 `result=`／计数／判词差异**。
- 🔴 因此记录里那句「**唯一**原始差异 ＝ `wall_s=4.16/4.27`」**不准确**（见 §7-⑤）。

### 2.2 我的第三趟（独立）

```
cd $N && DISPLAY=:236 bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 -- bash verify-all.sh
```
（驱动器 `~/w27x/post3.sh`；跑前现取 `df`/`free` 并写进日志头；显示位由我自己的 `pick_display` 口径选空闲号）

| 趟 | rc | 步骤 ✅ | 步骤 ❌ | 用例通过／跳过 | 关键机读行 |
|---|---|---|---|---|---|
| post3（我） | **0** | **50** | **0** | 875／2 | `VERIFYALL_SELF=PASS names=50 decl=50 gen=#77 … vfile_sha16=9811e86e32fdfcb9`／`BASELINESHA=PASS live=decl=e3ebc811641bd467`／`FP_INPUTS_HYGIENE=PASS coverage_n=211`／`FP_MANIFEST_TEETH=PASS files_n=211 declared_expect=211`／`WIRING_COVERAGE=PASS missing_n=0`／`PARSER_GUARD=PASS`／`PROTO_ATTR_GATE=PASS examined=18 posctl=2/2` |

```
HEAVYSLOT=ACQUIRED waited=0s ／ MEMOK avail=9173MB ／ HEAVYSLOT=RELEASED rc=0 held=954s max_hold=1800s
porcelain：跑前 15 → 跑后 16（+1 = 本报告自身，`??` 未跟踪）
```
日志：`~/w27x/logs/t6-post3-20260926-215121.log`（8863 B ⇒ 超 MB 只用 `wc/head/tail/grep -c`）。

**跑后九位复测（关键）**：跑完再算一遍九位 ⇒ **九位逐位不变**（含 `provider 4041df9a704abfed`）⇒ 冻结点在这棵树上**对门禁重跑稳定**。
**跑后 `porcelain` 增量为 0 件**（除我自己的报告）⇒ 我这趟门禁**没有**新弄脏任何受版控件。

### 2.3 三趟同结论 ⇒ 我给出的判决口径

- 三趟**同一命令、同一树、同一世代**：`步骤通过 50 / ❌ 失败 0`、`用例通过 875 / 跳过 2`、`结论：✅ 全部通过` —— **三趟逐字一致**。
- 判词域各 **129 行**；归一化（路径/tmpdir/时间戳/`avail*`/`mem_mb`/`wall_s`/`held`）后：
  `post1↔post2` 差异 **0 行**；`post1↔post3` 差异 **8 行**，逐条如下（**全部是状态/标签类，没有一条判据字段**）：

| 差异行 | post1 | post3 | 我的判读 |
|---|---|---|---|
| `FRAMEPRESENCE` | `frames=80 max_colors=4113 magenta_frames=39` | `… magenta_frames=38` | 两次**真跑应用**的帧计数 ±1；判据字段（`min_colors=200`／`PASS`）不变 ⇒ `LABEL_ONLY_DIFF` |
| `THIRDPARTY` | `frames=43 max_colors=1642` | `frames=42` | 同上（第三方 mini 应用真跑） |
| `NULBYTES` | `files=1558 bytes=288185350` | `files=1559 bytes=288246392` | **+1 件 / +61,042 B ＝ 我这份报告自己**（我的足迹污染了读数，如实标出） |
| `ALIAS` | `examined=17461` | `examined=17519`（+58） | 我这趟重建新增的派生件被扫到；`linked_gt1=0`／`reason=no-out-of-repo-alias` 不变 |

- 判定口径照 `D-G138`：跑次戳/标签/临时目录/环境余量/由**我自己的存在**引起的文件数变化 ⇒ `LABEL_ONLY_DIFF`（**不算**读数差异）；`result=` 计数或判词不同 ⇒ 我判 `FAIL`（本件**零例**）。

---

## 3. 四条 `TASK` 的两极化（**我自己的输入**，不看对方的 `--selftest` 输出）

### 3.1 `TASK-0740`（`wiring-coverage-check.sh`，sha16 `fa356ae278497e07`）

| 腿 | 输入（我造的） | 读数原文 | rc |
|---|---|---|---|
| 正极 | 真树 | `WIRING_COVERAGE=PASS run_step=50 wiring_n=47 coverage_n=211 missing_n=0 examined=47` | 0 |
| 反极①（已接线∧件存在∧未入名单） | `verify-all.sh` 副本 ＋ `run_step "T6-FAKE-UNCOVERED" bash build/bridge-src-fp.sh` | `WIRING_COVERAGE_FAIL rule=wired-but-uncovered file=build/bridge-src-fp.sh …` ＋ `missing_n=1` | **1** |
| 反极②（接线指名不存在的件） | 追加 `run_step … bash build/MilBridge/tools/t6-not-there.sh` | `WIRING_COVERAGE_FAIL rule=wired-path-absent file=…/t6-not-there.sh` ＋ `absent_n=1` | **1** |
| 空边 | 零 `run_step` 的副本 | `WIRING_COVERAGE=NOINFO reason=run-step-zero examined=0 run_step=0` | **3** |

※ 三条反极**必红必点名**；空边**响亮 NOINFO**（不静默零）。
※ 我自己先踩过一次坑：`cmd | tail` 后的 `$?` 是**管道** rc，第一次读到的三条"rc=0"是假读数，改用"先取 rc 再管道"重测才得到 1/1/3（纪律已经在册，我照抄现场教训）。

### 3.2 `TASK-0742`（`parser-guard-check.sh`，sha16 `750f1303ded9c2ed`）

| 腿 | 输入 | 读数原文 | rc |
|---|---|---|---|
| 正极 | 真树 | `PARSER_GUARD=PASS examined=8 sites_env=4 sites_parser=0 exempt_used=0 dynamic_n=4 fails=0` | 0 |
| 反极① | `--expect-sites 9999` | `PARSER_GUARD_FAIL rule=examined-n-mismatch examined=8 declared_expect=9999` | 1 |
| **反极②（格式不符）** | 我改坏**声明件**（把 `PARAM SCREEN` 记录的字段砍成 3 段 ⇒ `ere` 空） | `PARSER_GUARD_FAIL rule=guard-no-teeth param=SCREEN kind=geometry arm=bad（畸形值**没被拒**）out=PARSER_GUARD_VALUE=OK value=1280x1024x24 ere=` | **1** |
| 反极③（声明件不可认） | 空声明件 | `PARSER_GUARD=NOINFO reason=decl-header-unrecognized` | 3 |

※ 关键点：**畸形声明不会把牙静默关掉** —— 它由**动态面**当场咬住（`guard-no-teeth`）。这正是"格式不符 ⇒ 必红或 `NOINFO`，不许静默零"。

### 3.3 `TASK-0744`（`proto-attribution-check.sh`，sha16 `49bb6126b499c2cd`）

| 腿 | 输入 | 读数原文 | rc |
|---|---|---|---|
| 正极 | `--cases …proto-attribution-cases.tsv --expect 18` | `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1` | 0 |
| 反极① | `--expect 17` | `PROTO_ATTR_GATE=FAIL reason=row-count-mismatch examined=18 mismatch=0` | 1 |
| **反极②（我改写语料）** | 把 `N-SYM` 行的 `expect` 从 `NOINFO` 改成 `NOT_ATTRIBUTED` | `PROTO_ATTR_ROWS … mismatch=1` ＋ `PROTO_ATTR_GATE=FAIL reason=case-mismatch` | **1** |
| 反极③（畸形 `SCREEN`） | `--screen abc` / `--screen 1280` | `mismatch=6` ∧ `posctl_att=1` ⇒ `FAIL reason=case-mismatch` | **1** |
| 反极④（空边） | 不给 `--cases` | `PROTO_ATTR=NOINFO reason=usage:--cases-needs-file` | 3 |
| **真腿模式** | 仓内归档腿目录 `build/MilBridge/geom-corpus/W134A-A1-OLD-6` ＋ `…-NEW-8` | 每腿 `verdict=NOINFO reason=sock-id-absent … SYM_ONLY=never-sufficient … would_be=NOT_ATTRIBUTED`；汇总 `sock_id_absent=2` ＋ `PROTO_ATTR_NOTE ATTRIBUTED 在真腿上不可达…` | 3 |

- 「**符号级没有 `CALL` 永不算 `NOT_ATTRIBUTED`**」——我的反极②直接证到：`N-SYM`（`op0=-`、`sym_call=none`）被判 `NOINFO reason=symbol-level-not-evidence`，一旦我把它声明成 `NOT_ATTRIBUTED` 就**红**。
- 🔴 「**线上等长替换 `XWRAP_CUT_PROTO` ⇒ 服务器侧无该 CN ∧ 末态不变**」这条腿**我没能独立复跑**：仓内 `grep -rl 'XWRAP_CUT_PROTO\|NoOperation\|cut_proto' build/MilBridge/geom-corpus/` = **0 命中**（语料/装置不在手）⇒ 记 `NOINFO`（见 §8）。能独立证到的是**确定性语料**里那条 `cut_proto=present` 的判例真在判（`cut_and_pair=1`，且我改写它必红）。

### 3.4 `TASK-0745`（**对象 = 活冻结器**，不是车道排练副本）

我做了一件与车道排练**不同**的事：把**主控现场活件** `~/w21-verify/w27-freeze.py`（现取 `sha16=f9fb7bcac0353a61`）里的
`_BLK_HDR`／`_NINE_HDR`／`_PREV_SRC`／`_TIER_MAP`／`_block_of_prev`／`check_prev_values`／`check_record_forms`／`GENS`
用 `ast` **逐字抽出后 `exec`**（无一处重新实现），语料用**冻结器自己写出来的真 `#77` 块**（不是桩）。
驱动器：`~/w27x/arms745b.py`，读数：`~/w27x/logs/arms745-live.txt`。

| 臂 | 输入 | 读数 | 判定 |
|---|---|---|---|
| A0 | 生产路径复放：`check_prev_values('#77', GENS['#77'], 冻结前备份)` | `PREVCHECK … keys=7 checked=7 skipped=0 base=954df351a119d36f`（逐行与冻结日志同形） | ✓ 复放成功 |
| A1 | 真 `#77` 块 × `GENS['#77']`（表项 = **上一代**值） | `bad=7`（5 条 `MISMATCH` ＋ 2 条 `TIER-DISAGREE`） | 语义侦察（见 §7-⑥） |
| A1b | 真 `#77` 块 × `G_now`（表项 = 九位行现值） | `bad=[] checked=7 skipped=[]` | ✓ |
| **A2** | A1b 的输入，把九位行 `provider` `1f9511a7…`↔现场真值 `4041df9a…` | **结论逐字不变**（`bad=[] checked=7`） | 🔴 形态核**对 provider 全盲** |
| **A3** | 去掉 `GENS['#77'].prev_wb` | `keys(checked) 7→6` ∧ `skipped=['prev_wb']`（并印 `PREVCHECK-SKIP key=prev_wb reason=gens-has-no-key`） | ✓ **"keys= 必减 ∧ skipped= 必点名"两条同时成立** |
| A3b | 同一跳过进形态核 | `checked=6 skipped=[('prev_wb','not-in-gens')]` | ✓ |
| A4（控制腿） | 与 A1b 成对：把九位行 `pf` 写错 | 写成 ⇒ `bad=[]`；写错 ⇒ `bad=1` 且**点名 `prev_pf`** | ✓ 牙**会红** |
| A5（控制腿） | 删掉 `inputs_fp` 行 | `bad=HITS!=1 key=prev_infp … hits=0` | ✓ |
| A6（控制腿） | 九位行两条 | `bad=九位行命中 2 条（要求恰 1）` | ✓ |

`ARMS745_INDEP=PASS arms=9 pass=9 fail=0 freezer_sha16=f9fb7bcac0353a61`
※ 键表现取：`_PREV_SRC` 共 **7** 键（`prev_bsfp/prev_dwf/prev_infp/prev_pc/prev_pf/prev_wb/prev_wsh`）⇒ **不含** `provider`／`bridge`／`wic_shim`／`hbtextline`。

---

## 4. 推送逐件核、`porcelain`、两哨兵

### 4.1 远端与本地

```
git rev-parse HEAD                                   → d2dec07772946d8f73f816120886458fc7171454
git ls-remote origin refs/heads/feat-Linux           → d2dec07772946d8f73f816120886458fc7171454
git merge-base --is-ancestor 0666559 HEAD            → 0（是祖先）
git merge-base --is-ancestor 7027be06 HEAD           → 0（t1 主提交，是祖先）
git merge-base --is-ancestor fd9a9a18 HEAD           → 0（t1 报告收口，是祖先）
```

### 4.2 **逐件**核（不是"那一批推了"）

```
for p in $(git diff --name-status fd9a9a1..HEAD | awk '{print $NF}'); do
  b=$(git cat-file blob "HEAD:$p" | sha256sum | cut -c1-64); w=$(sha256sum "$p" | cut -c1-64);
  [ "$b" = "$w" ] && echo SAME || echo DIFF; done
```
- 件数 **38**：**37 件 `SAME`**（本地 blob 与工作树逐字节相同）；**1 件** = `.editorconfig`（提交状态是 `D` = **删除**，工作树里当然没有 ⇒ 不是不符）。
- 远端 tip == 本地 tip ⇒ 这 38 条变更路径**全部可达于远端**（内容寻址）。变更状态分布：`A=7  D=1  M=30`。

### 4.3 `porcelain`

```
git status --porcelain | wc -l   → 跑前 15 ／ 跑后（现取）16
```
| 件 | mtime | HEAD 里是什么 | 成因 |
|---|---|---|---|
| `build/*/SR.g.cs` ×8、`build/*/ARTIFACT-SRC-FP.txt` ×3、`build/WindowsBase.Linux/PORT-CHANGES.md`、`build/.applocal-selftest.log`、`build/wave-audit.log`（共 14 件） | 19:49–19:52 | **旧路径**（最后一次提交是 9/20 `a394a47` / 9/22 `62c7a7b` / P0 `7027be0`） | 本波 19:43／19:49 两次整波重建**把旧路径写成新路径**；本波"逐径 `git add`"没有收编它们 |
| `tests/parity/linux/parity-results.json` | 21:51 | 旧路径 | **我这趟 post3** 刚写的 |
| `build/MilBridge/V77-verify-report.md` | 22:0x | —（`??` 未跟踪） | **本报告自己** |

🔴 **`porcelain` 现取 ≠ 0**（见 §7-④）。且这不是"一次性的历史遗留"：上面 14 件的**内容**由构建路径驱动，
只要再跑一次整波/门禁就会再次变脏 —— 除非把它们也提交（或把路径从生成内容里去掉）。

### 4.4 两哨兵

```
cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag → IDENTICAL
stat -c '%h %i %s' … → 两份都是 %h=1、inode 不同、332 B、mtime 21:49:22
哨兵内容里的九位／BASELINE_SHA16 与我现算逐位相同（SHA=4e25e4b27d4d5ae1 PC=53fd7fffcdb30243 PROVIDER=4041df9a704abfed BASELINE=#77 BASELINE_SHA16=e3ebc811641bd467）
```
※ 附加读数（不是判据）：哨兵脚本 `w77-sentinel.sh` 取 `WB`/`PROVIDER` 用的是**另一套路径**
（`build/WindowsBase.Linux/bin/Release/WindowsBase.dll`、`build/DirectWrite.Linux/Provider/bin/Release/…Provider.dll`），与九位的权威路径不同；
21:49 那一刻两套路径**恰好同内容**（`07c89f18…`／`4041df9a…`），但**现在**后者已被我这趟重建写成 `609192a419d125f2`（权威路径仍 `4041df9a704abfed`）⇒ 这是一颗**安静的哑弹**：谁若在跑过门禁之后重生成哨兵，就会把 `PROVIDER=` 写成与九位不一致的值。

---

## 5. 旧路径重指向的独立复核

### 5.1 文本域（声明口径内）复算 —— 通过

```
cd $N && grep -rn 'wpf-linux-20260906' --include='*.sh' --include='*.py' . | grep -v '^./upstream/'   → 0 行
不带 grep -v 的同一命令                                                                              → 0 行（过滤器在本命令上**空成立**，不算独立证据）
控制腿：在车道目录造一个含旧路径的 probe.sh ⇒ 同一命令命中 1 行 ✔（命令真的会中）
波前（fd9a9a1）同口径：git grep -l … | wc -l = 21 件；出现行数 = 23 处   ← 与声明"21 件／23 处"逐字相符
```
⚠️ 域只有 `*.sh`／`*.py`。**仓内 tracked 件（排除 `upstream/`）现取仍有 192 件**带旧路径
（绝大多数是历史报告/证据，**但也包括 §4.3 的那些生成件**）⇒ 把这句读成"全仓零残留"就错了。

### 5.2 **执行域**复核 —— 🔴 5 处不符（我推翻了"默认值由仓根现推"）

方法：把每处**改动段的表达式**取出，把 shell 的 `${BASH_SOURCE[0]}`／python 的 `__file__` 注入成**该件在仓里的真实路径**
（运行时它们就是这个值），**写成一个临时脚本真跑**，再把值与 `$N` 逐字比（驱动器 `~/w27x/repoint-exec.py`）。
共执行 **22** 条替换表达式（覆盖全部 21 件；`backup-completeness-gate.sh` 的两处旧值收成一个 `WPF_BCG_DEFROOT` 间接）。

| 件 | 现算根 | 期望 | 判定 |
|---|---|---|---|
| 17 处（`*.sh` 全数 ＋ `PtsPagesProbe` 等） | `/home/links-dev/netTest/GitProj/WPFOnLinux` | 同 | ✓ |
| `build/DirectWrite.Linux/wic-shim/frames-gen.py:33` | `/…/WPFOnLinux/build` | `/…/WPFOnLinux` | 🔴 |
| `build/MilBridge/tools/analyze-layout-b34.py:12` | `/…/WPFOnLinux/build` | 同上 | 🔴 |
| `build/MilBridge/tools/extract-layout-b34.py:13` | `/…/WPFOnLinux/build` | 同上 | 🔴 |
| `build/MilBridge/tools/t1c-inputtrace-verify.py:32` | `/…/WPFOnLinux/build` | 同上 | 🔴 |
| `build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py:28` | `/…/WPFOnLinux/build` | 同上 | 🔴 |

**后果现取**（不是推演）：这 5 个变量的**第一个消费点**与现算根拼接后，路径**都不存在**；用**改前的旧值**（仓根）拼接则**都存在**：

```
frames-gen REPO     $N + build/DirectWrite.Linux/wic-shim/fixtures-jfif.jpg              存在=True ／ $N/build + 同后缀  存在=False
w81a SHIM           $N + src/WpfGfx.Linux.Native/bin/libwpfwin32.so                      存在=True ／ $N/build + 同后缀  存在=False
t1c APPLIER         $N + src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py 存在=True ／ $N/build + 同后缀 存在=False
analyze-layout SRC  $N + build/MilBridge/gen/layout-b34-compact.json                     存在=True ／ $N/build + 同后缀  存在=False
extract-layout SRC  $N + tests/parity/windows/layout-b34/windows-results.json            存在=True ／ $N/build + 同后缀  存在=False
```
- 归因（`dirname` 层数）：`build/MilBridge/tools/*.py` 与 `build/DirectWrite.Linux/wic-shim/*.py` 需 **4** 层、代码给了 **3**；
  `build/MilBridge/tests/W81AWindowProbe/*.py` 需 **5** 层、代码给了 **4**。
- **影响面如实**：这 5 件**都不在** `verify-all.sh` 接线里（`grep -c` = 0）、**也都不在** `fp_inputs()` 覆盖面（`grep -c covpaths` = 0）
  ⇒ 门禁**看不见**它（正是 `TASK-0740` 那颗牙的射程之外：它只判"**已接线**的件 ⊆ 覆盖面"）。

---

## 6. 迁移是否成立：**`#77` 链的读数与 `#76` 冻结口径可比**

**判决：可比。** 差异**逐条点名**如下（没有任何"不可解释"的位移）：

| 项 | `#76` | `#77` | 性质 |
|---|---|---|---|
| 步数 | `47`（`git show fd9a9a1:verify-all.sh` 现取） | `50` | 声明内加三步；**集合差恰为 3 个新名、无删无改名** ⇒ 逐步可比 |
| 覆盖面 | `205` | `211` | 声明内 +6（5 新件 ＋ 被收编的 `verify-cmd-layout.py`） |
| `inputs_fp` | `bb54413c8a3f0474a3d04e41dc08ec29fb993f7ea7a8ab689ae29f372904eb9a` | `b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c` | 覆盖面位移所致（设计内） |
| 九位 | `pc/pf/windowsbase/provider/dwf` = `722e0ab8/963c5999/2e4e46e5/1f9511a7/ce3469f4` | `53fd7fff/4fcd2ca0/07c89f18/4041df9a/b07f8015` | 五位位移；**归因机械，我用 `strings` 独立证实**（PDB 路径承载体），字节数逐位相同 |
| `BRIDGE_SRC_FP` | `d697b1e10ff48881` | 同 | 未动 |
| `ARM-LOG-SHA arm=tline` | `59a203de30d745a8` | 同 | 未动（其余四臂亦同） |
| 冻结口径 | `PREVCHECK` 7 键、`--expect` 与活清单同趟 | 同法 | 同法可比 |
| `verify-all` 结果 | （`#76` 收官时同法全绿） | 冻后三趟 `50/0` | 同法可比 |

⇒ 交付 `#77` 的**主链**可信；本件的 FAIL 判在 §7 的四条**声明/件**上，不在迁移是否成立上。

---

## 7. 我推翻了哪几句话（逐条，含现场读数与命令）

1. **「九位行里 `provider = 1f9511a7ef395bfe`」** —— 现取 `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll` = `4041df9a704abfed`；
   同一块的位移行与**全部** `BASELINE tier=` 机读行都写 `4041df9a704abfed` ⇒ **九位行是上一代值**。
   机制可定位到记录模板 `~/w185a/w77/w77freeze/w77-record.txt:29`：同行其它位是 `{BR}`/`{PC}`/`{PF}`… 占位符，**`provider`（与 `wic_shim`）被写成了字面量**，渲染后原样落纸（`wic_shim` 恰好没动才没露馅）。
   该块自己写「九位只许从最新冻结块的九位行**或** `BASELINE tier=` 机读行取」⇒ **两个授权来源互相矛盾**；冻结器的三道核（`_PREV_SRC` 7 键／`_TIER_MAP` 5 位）**都不含 `provider`**，所以我用活件函数跑的 A2 臂（真块里把 provider 换成正误两态）**结论逐字不变**。
2. **「九位只 `pf`（环成员）动」** —— 实为**五位**（`allow_changed={'pc','pf','windowsbase','provider','dwf'}`、`pf_required=False`，见活件 `GENS['#77']` 与冻结日志第 20–21 行）；FROZEN ⑩/⑥ 里那句 `allow_changed={'pf'}` ＋ `pf_required=True` 是**预登记文本**，与冻结器实际配置不一致。
3. **「21 件旧路径重指向 ⇒ 默认值由仓根现推」** —— 文本域对（21 件／23 处 → 0），**执行域 5 处不符**（§5.2）。
4. **「`porcelain=0`」** —— 现取 **16 件**（14 件由本波两次整波重建产生、1 件由我这趟 post3 写、1 件 = 本报告自身；跑前读数是 15）。
5. **「两趟 post 的唯一原始差异是 `wall_s`」** —— 原始差异 **24 行**（全部标签/环境类）；**归一化后 0 行**（"判词行逐字相同"这句成立，错的只是"唯一"这个量词）。
6. **「`TASK-0745` 的补丁未落、冻结器一字节未动」** —— **冻结当时为真**（21:16 用的快照 `w27-freeze.py.w77d-6bf3c5c77eee8dd8` 里 `grep -c 'def check_record_forms'` = **0**）；但**现取**活件 `f9fb7bcac0353a61`（mtime 21:51:23）**已经带了** `check_record_forms` ＋ 调用点 ＋ `keys/checked/skipped` 三格打印 ⇒ 主控在冻结后把它落进了活件，记录 ④/BANNER ④ 现在是**过期文本**。
   ⚠️ 同日同趟的**旁证读数**（不是本波判决面，主控写域可能仍在飞）：以**现行调用**（`G = GENS[gen]`，`prev_*` = 上一代值）跑**真 `#77` 块**，`check_record_forms` 返 `bad=7`；把表项换成九位行现值后 `bad=[]` ⇒ 这颗新牙在"**有位移的世代**"上会拒冻，值得主控复核（见 §3.4 的 A1／A1b／A2）。
7. **「`app-local` 合格线 `STALE=0 ∧ DIVERGENT=0`」是一个"点读数"，不是可重跑的状态读数** ——
   - 该句的来源是**整波内部的 `APPSYNC-REFRESH`**：`~/w185a/w77/logs/integration-wave.log:164-165` 是 `APPSYNC-REFRESH=refreshed=16` ⇒ `MISMATCH=0[STALE=0] DIVERGENT=0`；
     **同一波第二次整波**（`integration-wave2.log:290-291`）是 `refreshed=182` ⇒ `STALE=0` 但 **`DIVERGENT=1`** ⇒ 连本波内部两次读数都不相同。
   - 我现取（22:0x，跑完第三趟 `verify-all` 之后）：`APPSYNC=MISMATCH（MISMATCH=52[STALE=52 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=0 DECL-GAP-DIFF=6] DIVERGENT=1 …）rc=1`。
   - **机制我钉到了**（不是猜）：同名的 `DirectWrite.Linux.Provider.dll` 在仓里有**两个都自称权威**的路径——
     · 九位/哨兵/`BASELINE tier=` 用的是 `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll`（现取 `4041df9a704abfed`，跑门禁前后**都没变**）；
     · `app-local` 判据（`build/DirectWrite.Linux/wic-shim/applocal-expect.py:104`）用的是 `build/DirectWrite.Linux/Provider/bin/<CFG>/DirectWrite.Linux.Provider.dll`（**我这趟 post3 在 21:51:41 把它重建成 `609192a419d125f2`**，此前它与前者同值）。
     ⇒ 判据输出直接印 `EXPECT 609192a419d125f2  ACTUAL 4041df9a704abfed（副本早 7220 秒 ⇒ 必须刷新）`，52 条副本全判 `STALE`，另有 6 条 `UNEXPECTED-DIFF`。
   - **如实归属**：这次分叉是**我这趟门禁运行**造成的（我按纪律**不写 `$N`**，因此**不自行回滚**）；下一趟整波的 `APPSYNC-REFRESH` 会自愈（本波实测 `refreshed=182`）。
     但这暴露的是**结构性风险**：两个"权威"没有一颗牙**钉住它们相等**，谁重建其一都会让 app-local 变红/变绿（`D-G130` 家族：判据输入取自瞬时派生状态），**而 `verify-all` 里根本没有这一步**（`grep -n applocal verify-all.sh` 无 `run_step`）⇒ 门禁看不见它。

---

## 8. 边界与 `NOINFO`（既不算绿也不算红）

| # | 项 | 原因 |
|---|---|---|
| N1 | `TASK-0744` 的**线上等长替换 `XWRAP_CUT_PROTO`** 真腿 | 仓内零装置/语料（`grep -rl 'XWRAP_CUT_PROTO\|NoOperation\|cut_proto' build/MilBridge/geom-corpus/` = 0）⇒ 我**没有**独立复跑；可独立证到的是确定性语料里 `cut_proto=present` 的判例**真在判**（改它必红） |
| N2 | 活冻结器的**在飞状态** | `~/w21-verify/w27-freeze.py` 是主控写域、mtime `21:51:23`（正在被改）⇒ §7-⑥ 的后半是**快照读数**，时点已写死，不作判决面 |
| N3 | `app-local` 的 `APPSYNC=MISMATCH（STALE=52 … DIVERGENT=1）` 读数 | 它出现在**我自己 post3 运行之后**，机制已钉（§7-⑦：两个"权威"路径分叉）。⇒ 我**不**把它当波的红，只当"结构性风险 ＋ 我的足迹"两条事实；`verify-all` 里没有这一步（无 `run_step`），所以它对三趟 `50/0` 无影响 |
| N4 | `upstream/` 树内部 | 边界外（本件不判上游内容） |
| N5 | `w77-POST.done` 的**时点语义** | 该 0 字节标记由冻结驱动脚本在**跑到 post 之前** `touch`（`w77-freeze-then-post.sh:27` 在 `:30 :31` 之前）；且它的 mtime `21:17:27` 比 post1 的跑次戳 `21:17:23` **晚 4 秒**（与脚本内的先后顺序相反，我**没能**钉出是哪一个启动者写的）。⇒ 我**不**把它的存在当"post 跑完了"的证据，真正的证据是两趟日志内容 ＋ `POST2_DONE 2026-09-26T21:46:52+08:00` |

---

## 9. 复算环境、我自己的仪器坑与真树零污染

- 复算环境：`nproc=3`；`verify-all` 单趟走 `~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800`（**后台作业**）；进程只按 PID 收；过 MB 日志只用 `wc/head/tail/grep -c`。
- 我自己的**三处**仪器自伤（如实留档，全部当场咬住）：
  ① `cmd | tail` 后的 `$?` 是**管道** rc ⇒ 第一轮 0740 三条臂都读成 `rc=0`（假读数），改成"先取 rc 再管道"重测得 `0/1/1/3`；
  ② `git grep -l <rev>` 输出带 `fd9a9a1:` 前缀，我直接当路径用 ⇒ 第一轮重指向 diff 抽成空集（0 行），`sed 's/^[^:]*://'` 后得 23 处；
  ③ 我的第一版"重指向执行核"把注入的自指路径又套了一层引号（`""/path"`）⇒ 22 处全 `BAD`（假红），改成"写成临时脚本再跑"后得 `17 命中 / 5 不符`。
- 真树零污染：`$N` 内**只新增**本报告 1 件；其余一切落在 `~/w27x/**`（`criteria.md`／`post3.sh`／`arms745b.py`／`repoint-exec.py`／`fix740|fix742|fix744/`／`logs/`）。
  跑过门禁 ⇒ 派生件必然被重建（§4.3），这一条**不是我独有的**，已在 §4.3 点名。

---

## 10. 复算命令索引（便于第三者重跑）

```
# 九位 / 步数 / 覆盖面
cd /home/links-dev/netTest/GitProj/WPFOnLinux && for f in <九个路径>; do sha256sum "$f" | cut -c1-16; done
grep -c '^run_step "' verify-all.sh ; grep -c '^run_step' verify-all.sh    # 50 / 51（控制腿）
sed -n '1p' <首个 DECL 行> ; awk 'NR==113' verify-all.sh | sed 's/^# VERIFYALL-STEP-NAMES: //' | tr '|' '\n' | grep -c .
bash ~/w153a/bin/infp.sh fp ; bash ~/w153a/bin/infp.sh list | wc -l
# 两趟 post 的逐趟复算与归一化对比  → ~/w27x/logs/{post1,post2}-judge.txt, judge-diff-norm.txt
# 我自己的第三趟                          → ~/w27x/logs/t6-post3-*.log（驱动 ~/w27x/post3.sh）
# 四条牙两极化                            → ~/w27x/logs/arms{740,742,744}.txt、arms745-live.txt
# 重指向执行核                            → python3 ~/w27x/repoint-exec.py
# 推送逐件核                              → 本报告 §4.2 的 for 循环
```

`V77VERIFY=DONE verdict=FAIL(见 §7) nine=8/9+1陈旧 steps=50/50 coverage=211/211 post_runs=3(50✅/0❌) push=38件(37SAME+1删除) sentinel=IDENTICAL repoint_live=17/22 porcelain=16 noinfo=5`

`SELF_SHA16=ea82b1a2bcc8a9f6`（**口径 = 去掉本行**：`head -n -1 build/MilBridge/V77-verify-report.md | sha256sum | cut -c1-16`；报数纪律：本件自指 ⇒ 只报这一个口径，第三者按上式可逐位复算）