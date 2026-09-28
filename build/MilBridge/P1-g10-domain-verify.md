# P1-G10-DOMAIN-VERIFY —— `t76`（G10 域前提修正）**独立复核判词**

> 复核者 `verifier`（任务 `t77`）。**只读仓树**：未改 `t76` 的任何件、未跑整趟门禁、未构建、未跑应用腿、未占显示位、未 `git add/commit/push`；**唯一写入 ＝ 本件**（`build/MilBridge/P1-g10-domain-verify.md`）。
> 夹具全部在我车道 `~/wv88y/t77/**`（`legs-A…H` 腿目录 ＝ 真实腿目录 `~/p1-ptsname/legs-after` 的副本 ＋ 只改 `entry=` 名；`faketree/` ＝ 我造的**假声明树**）。**未引 `t76` 的输出当证据**（其报告只用于对照它**自称**的改动集），**未引我自己早前报告**。

---

## §0 快照（现取，逐条带亚秒 `ts=`）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`ab1ac00`**（`docs(#81): t75 LS 族缺口面侦察入账…`，`2026-09-28T23:01:06+08:00`） | `2026-09-28T23:03:06.473710820+08:00` |
| 判据件（核心） | `build/MilBridge/tools/pts-pages-guard.sh`：**改前像（＝`HEAD` 版）`59bffc8e5b5a621a`／483 行** ⇒ **现盘 `b74d2be6f9093115`／572 行**｜索引 `100644`／工作树 `644` | `23:03:06.473710820` |
| `t76` 载体／原则件 | `build/MilBridge/P1-g10-domain-report.md` ＝ `419cddd5cc964e52`／91 行（**未跟踪新件**）｜`build/MilBridge/P1-ptsname-result.md` ＝ `77f1163ded31495f`／89 行 | 同上 |
| 真实腿目录 | `~/p1-ptsname/legs-after`（16 件），其 `app_g1.log` 的 `entry=` 面现取 ＝ **`2 entry=LoSetDoc`** | `23:03:37.046054305` |
| `porcelain` | 14 行（**写域内存在未提交差异，归属未核**；口径＝只说明「工作树 vs `HEAD` 的差」，**不说明写者数**） | `23:03:06.473710820` |

---

## ① 只增不改／零越域：**成立（附 3 件非 `t76` 申报面的点名）**

- **核心件成对逐位**：`HEAD` 版 ＝ **`59bffc8e5b5a621a`／483 行**（＝ `t76` 自称改前值，**逐位相同**）⇒ 现盘 ＝ **`b74d2be6f9093115`／572 行**；`git diff --numstat HEAD` ＝ **`95 6`**（与自称一致）。
- **6 个删行我逐行现取**：`off=""`／`for nm in $names_all; do`／`*$'\n'"$nm"$'\n'*) ;;`／`*) off="$off$nm," ;;`／`echo "PTS_G10_NAME=FAIL …"`／`echo "PTS_G10_NAME=PASS …"` ⇒ **全部是 bash 代码行，prose 0 删** ✓（「只增不改」指的是 prose／既有判词文本未被删）。
- **`t76` 申报面**（任务登记 `changedPaths`，我以 `team.json` 只读读出）＝ `pts-pages-guard.sh`／`HANDOFF-NEXT.md`／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／`P1-g10-domain-report.md`。**现取工作树 vs `HEAD` 差集 8 件**：其申报的 5 个跟踪件**全部在内** ✓（`1 0 HANDOFF-NEXT.md`／`3 2 declared.tsv`／`95 6 pts-pages-guard.sh`／`7 0 ROUTES.md`／`12 0 KNOWN-DEFECTS.md`）＋ 载体为未跟踪新件。
- **另有 3 件不在其申报面**（逐条点名）**`O1`**：`15 1 build/MilBridge/P1-ptsname-result.md`（**原则件自身**）｜`1 1 …/evidence/device/xfwm.log`｜`17 27 …/evidence/session.txt` ⇒ 三者**归属未核**（他笔在飞）；**我现取未见「`t76` 在申报面之外实改」的证据** ⇒ **不判越域**。

## ② 域判定口径是否机器可核：**成立（内容锚 ＋ 写死 ＋ 正则注入不可绕）＋ 1 处我骗过 ⇒ 判红点名**

- **写死/内容锚**：`ROSTER_SRC`（`:84`，缺省 ＝ `src/WpfGfx.Linux.Native/src/win32_pts.c`）与 `DECL_TREE`（`:102`，缺省 ＝ `upstream/wpf`）**写死在件内**，可被 `PTS_G10_*` env 覆盖（件内自测要用，见 `:383–384` 的 export）；PTS 域判定 ＝ 取 `k_pts_entries[]` 表体后**换行包裹的精确匹配**（`:204` `*$'\n'"$nm2"$'\n'*`）｜非 PTS 域判定 ＝ 正则 `DllImport[^)]*EntryPoint[[:space:]]*=[[:space:]]*"$nm"`（`decl_hit()`，`:105–107`）。
- **抽取面把注入堵住了（我实测）**：`entry=` 的抽取是 `grep -o 'entry=[A-Za-z0-9_]*'`（`:185–186`）⇒ 名字**只可能**是 `[A-Za-z0-9_]`；我造腿 `entry=LoSetD.c` ⇒ 抽取截断为 `LoSetD` ⇒ **`FAIL unattributable`**（既不能前缀匹配 `LoSetDoc`、也无法把 `.` 当正则注入）✓；腿 `LoSetDo`（真名前缀）⇒ 同样 **`FAIL`** ✓。
- **`F1`（medium，判红点名）—— 我骗过了非 PTS 域判定**：判据只要求「声明树里**同一行**同时出现 `DllImport` 与 `EntryPoint="<名>"`」，**不分辨「声明」与「注释/字面量」**。夹具（仓外，命令原文）：
  ```bash
  mkdir -p ~/wv88y/t77/faketree/a
  printf '// 这不是声明：示例文本 DllImport(Whatever, EntryPoint="LoCommentOnly") 仅供读者参考\n' > ~/wv88y/t77/faketree/a/Fake.cs
  cp -r ~/p1-ptsname/legs-after ~/wv88y/t77/legs-G && python3 - <<'PY'   # 只把 entry= 改成 LoCommentOnly
  import re,sys;p='/home/links-dev/wv88y/t77/legs-G/app_g1.log';s=open(p,encoding='utf-8',errors='replace').read()
  open(p,'w',encoding='utf-8').write(re.sub(r'entry=[A-Za-z0-9_]*','entry=LoCommentOnly',s))
  PY
  env PTS_G10_DECL_TREE=~/wv88y/t77/faketree bash build/MilBridge/tools/pts-pages-guard.sh --legs ~/wv88y/t77/legs-G
  ```
  现取原样：**`PTS_G10_NAME=PASS observed=LoCommentOnly names=1 roster=10 domains=dllimport-entry decl=…/faketree/a/Fake.cs:1`**（`ts=23:04:02.263560737`）⇒ **一条注释里的示例两串就足以把「不可归因」的假名判成绿**。**对照隔离**：同一假名、声明树换回真树 ⇒ **`FAIL frontier=LoCommentOnly off-roster=LoCommentOnly domains=unattributable`**（`ts=23:04:02`）⇒ 差异**只**来自声明树内容。
  **修法建议（不代改，供队长/写者）**：把该正则锚到**声明行**（例：行首允许空白后必须是 `[DllImport(`，或要求命中行不含行首 `//`／不被字符串包住），或把命中范围收紧到 `upstream/**/TextFormatting/**`（仍是内容锚，只收紧、不放宽）。

## ③ `G10b` 没被放宽（本件红线）：**成立**

- **PTS 域假名（不在 `k_pts_entries[]`）**：腿 `legs-D`，`entry=CreateDocContextX` ⇒ **`PTS_G10_NAME=FAIL frontier=CreateDocContextX off-roster=CreateDocContextX roster=10 domains=unattributable decl=none`**（`ts=23:03:49.705418157`）⇒ **仍必红并点名** ✓
- **PTS 域真名（十名之一）**：腿 `legs-E`，`entry=CreateDocContext` ⇒ **`PASS observed=CreateDocContext names=1 roster=10 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）`** ⇒ 在册表仍是**唯一绿门** ✓（假名的绿只可能来自**非 PTS 域**那一格，且必须带 `decl=` 对拍位）。

## ④ 三极化（我自己跑，原样输出）：**成立**

| 腿 | 夹具 `entry=` | `rc`（`--g10-name`） | 判词行原样 |
|---|---|---|---|
| a（PTS 域假名） | `CreateDocContextX` | **`1`** | `PTS_G10_NAME=FAIL … off-roster=CreateDocContextX … domains=unattributable decl=none` |
| b（非 PTS 域真名） | `LoSetDoc` | **`0`** | `PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=…/LineServices.cs:1470` |
| c（非 PTS 域假名） | `LoBogusName` | **`1`** | `PTS_G10_NAME=FAIL … off-roster=LoBogusName … domains=unattributable decl=none` |

（腿两两只在 `entry=` 名一处不同，其它件逐字节复制自真实腿目录；`ts=23:03:49.705418157`）

## ⑤ 现树真读数（`~/p1-ptsname/legs-after`，捕获式）：**成立 —— 是真绿，不是折叠**

- 修后（现盘，`ts=23:04:02.263560737`）：**`rc=1`**｜`PTS_G10_NAME=PASS observed=LoSetDoc names=1 roster=10 domains=dllimport-entry decl=/home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470`｜**`PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) cannot=- diag=- direction=in-file phase=degraded`**
- **成对（修前像我自己跑）**：`git show HEAD:… > ~/wv88y/t77/guard-head.sh`（`59bffc8e5b5a621a`／483 行）＋**显式注入名单源**（`PTS_G10_ROSTER_SRC=…/win32_pts.c`；不注入则 `SELF_DIR/../../..` 会指错根 ⇒ 假红）⇒ 同一腿目录 **`rc=1`／`PTS_G10_NAME=FAIL frontier=LoSetDoc off-roster=LoSetDoc roster=10`** ⇒ **同一输入红→绿，且绿是带 `decl=` 对拍位的**（`ts=23:04:46.131277748`）。
- **不判折叠**：另一条红 `native-ledger-absent(PTS_GAP n=0)` **原样保留**、相位仍 `phase=degraded`（未被改成 `realized`）、阈值未见放宽；`off-roster` 字段与「不在册即红」的规矩**未被删除**。

## ⑥ 三态不减字段 ＋ 判词行不缺席：**成立**

- **三态 `rc` 成对**（`--g10-name` 单点）：`PASS` ⇒ **`0`**（腿 b）｜`FAIL` ⇒ **`1`**（腿 a／c）｜`NOINFO(decl-tree-absent)` ⇒ **`2`**（`PTS_G10_DECL_TREE=/nonexistent` ＋ `entry=LoSetDoc` ⇒ `PTS_G10_NAME=NOINFO reason=decl-tree-absent tree=/nonexistent frontier=LoSetDoc roster=10`）⇒ **`NOINFO` 永不当绿**（`G10_RC=2` 折进 `cannot=`）✓
- `PTS_GUARD=` 行字段齐全：`legs=`／`fails=`／`cannot=`／`diag=`／`direction=`／`phase=`（现取原样见 ⑤）✓；新增字段只增（`domains=`／`decl=`），既有字段（`frontier=`／`off-roster=`／`roster=`／`form=`／`reason=`）一字未减 ✓
- 件内自测现取：**`PTS_GUARD_SELFTEST=PASS pass=37 fail=0`**（捕获式 `rc=0`）⇒ 与自称 37/0 一致（旧例零退化这一点我**未逐例复核** ⇒ 见 `NOINFO` 3）。

## ⑦ 指纹／不变量：**成立（附 1 处「位移未留痕」的点名与 1 条「不该重写哨兵」的判定）**

- **四条不变量现取（`ts=23:04:18.002068304`）**：`^run_step "` ＝ **`62`**｜`--expect` ＝ **`234`**｜`# VERIFYALL-STEPS-DECL: 62 gen=#81`｜覆盖面（`infp.sh list | wc -l`）＝ **`234`** ⇒ **四条不变**（判据件改动未碰接线面）✓
- **两枚哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ＝ **`IDENTICAL`**；其 `FP=d697b1e10ff48881`／`SHA=4e25e4b27d4d5ae1`／`WAVE=w80-freeze`／`BASELINE_SHA16=b27ff6332f263495`；哨兵 `mtime 2026-09-28 23:00:10.798284112` ⇒ **本席判定：不该重写哨兵** —— 哨兵的 `FP` 是 **`BRIDGE_SRC_FP`**，与 `inputs_fp` **同名不同物**（仓内已 dated 钉死：`docs/ROUTES.md:834`），本次判据件改动落在 `inputs_fp` 面、与哨兵面无关；**写不写是队长的事**，我只给判定。
- **`inputs_fp` 位移留痕（逐次现取）**：`0581db21fe4cf1a2`（`ts=23:03:37.046054305`）→ `8ea520791f2a98324774774b5a285a0e`（`ts=23:04:18.002068304`）→ `ead7b6488922c1c069142157a5f056ad`（`ts=23:04:27.209464571`）。判据件**确在覆盖面内**（`infp.sh list | grep -c pts-pages-guard.sh` ＝ **`1`**）⇒ 其内容变动**必然**改 `inputs_fp`；**`t76` 已把「它那一刻」的值 `0581db21fe4cf1a2` 记进 `HANDOFF-NEXT.md` 与它的载体**（我以 `grep -rl '0581db21fe4cf1a2'` 现取，命中恰这两件）⇒ **留痕成立（带时点）**；**其后两次位移由他车道写入、无人留痕**（归属未核）⇒ 记观察 `O2`，建议收口时以 dated 追加补记现值（**我不代写**）。
- 相关牙现取（附）：`SHELL_QUOTE_TRAP`／`PIPEFAIL`／`HANDOFF_MV`／`STATICJAWS` 等**不是本件的复核面**，我**未复跑**（见 `NOINFO` 3）。

## ⑧ 落地与边界自证

- 载体：`build/MilBridge/P1-g10-domain-verify.md`（**新建**，UTF-8，**首记号 ＝ `# P1-G10-DOMAIN-VERIFY`，不是 `# ⏪ `**），mode **`644`**，末行为机读自报行（`head -n -1` 口径值见交件消息）。
- 边界遵守自证：本回合**唯一写入 ＝ 本件**；`porcelain` 里本件行为 `?? build/MilBridge/P1-g10-domain-verify.md`；未跑整趟门禁／未构建／未跑应用腿／未占显示位／未 `git add/commit/push`；`t76` 的任何件**一字未改**（其核心件现取仍 `b74d2be6f9093115`／572 行，与复核前一致）；全部夹具在仓外 `~/wv88y/t77/**`。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未取得第二实现)`：本件对域判定用的是**同一实现**（判据件自身）＋我自己造的夹具；**没有**独立写第二个域判定实现 ⇒ 「判据实现与我的复算是否同源」这一点**未验**（我验的是**极点行为**：假名必红、真名必绿、注释可骗）。
2. `NOINFO(reason=未跑整趟门禁)`：`verify-all` 未跑（一跑即构建）⇒ 判据件在门禁内的**端到端**表现未验；只验四条不变量与单点模式。
3. `NOINFO(reason=未逐例复核 selftest 37 例)`：我现取只确认 `PASS pass=37 fail=0`；**未逐例**核「旧例零退化」。
4. `NOINFO(reason=他车道在飞)`：`P1-ptsname-result.md`／`evidence/device/xfwm.log`／`evidence/session.txt` 与本回合的三次 `inputs_fp` 位移（后两次）**归属未核**，不计入本判词。
5. `NOINFO(reason=未核非 PTS 域真名的 native 侧不存在性)`：`LoSetDoc` 在 `src/**` 的 `grep -rl` 我**未复算**（`t76` 自称 0 件）⇒ 该格不判。

## 推翻的话 ＋ 结论

- **推翻／点名**：**`F1`（medium）** —— 「非 PTS 域归因」的判据**可被注释/字面量里的同名两串骗过**（我造的 `faketree` 夹具现取 `PASS … domains=dllimport-entry decl=…/Fake.cs:1`，同假名换真树即 `FAIL`）⇒ 该格「声明位」的内容锚**不分辨声明与注释**，建议按 ② 的修法收紧；**`O1`** —— 工作树差集里 3 件不在 `t76` 申报面（归属未核）；**`O2`** —— `inputs_fp` 后两次位移未留痕（非 `t76` 之责）。
- **不推翻（逐条成立）**：核心件「只增不改」（6 删行全为代码、prose 0 删）｜`G10b` 未放宽（PTS 假名必红／真名仍绿）｜三极化行为（含前缀假名与 `entry=LoSetD.c` 注入企图均红）｜现树真读数红→绿**带对拍位**且另一条红原样保留（**非折叠**）｜三态与字段齐全、`NOINFO` 不绿｜四条不变量与两哨兵（`cmp IDENTICAL`）。
- **结论**：复核项 ①–⑧ **逐条成立**，附 **1 处 medium（`F1`，判红点名）＋ 2 处观察（`O1`／`O2`）＋ 5 条 `NOINFO`**；`t76` 的**红线（`G10b` 不放宽）与「非折叠」两点我独立复现成立**。

P1-G10-DOMAIN-VERIFY: t77 attempt 1 | ① 只增不改/零越域 成立（guard 59bffc8e5b5a621a/483 → b74d2be6f9093115/572，numstat 95 6，6 删行全为代码 prose 0 删；t76 申报 5 跟踪件全在差集内＋载体未跟踪；另 3 件不在其申报面：P1-ptsname-result.md 15/1、evidence/device/xfwm.log 1/1、evidence/session.txt 17/27，归属未核）｜② 域判定口径 内容锚＋写死成立（ROSTER_SRC :84／DECL_TREE :102；relo 精确匹配 :204；decl_hit 正则 :105）；抽取面 [A-Za-z0-9_]* 堵住注入（loSetD.c ⇒ LoSetD ⇒ FAIL；LoSetDo ⇒ FAIL）；**F1 medium 判红：注释里的 DllImport…EntryPoint="LoCommentOnly" 被我造 faketree 骗过 ⇒ PASS domains=dllimport-entry decl=…/Fake.cs:1，同假名换真树 ⇒ FAIL unattributable**｜③ G10b 未放宽 成立（CreateDocContextX ⇒ FAIL off-roster domains=unattributable；CreateDocContext ⇒ PASS domains=pts-declared）｜④ 三极化自跑 成立（a rc=1 FAIL／b rc=0 PASS decl=…/LineServices.cs:1470／c rc=1 FAIL）｜⑤ 现树真读数 成立非折叠（修后 rc=1；PTS_G10_NAME=PASS observed=LoSetDoc … decl=…:1470；PTS_GUARD=FAIL legs=2/2 fails=native-ledger-absent(PTS_GAP n=0) … phase=degraded；修前像同腿 59bffc8e 版 ⇒ FAIL off-roster=LoSetDoc）｜⑥ 三态与字段成立（PASS rc=0／FAIL rc=1／NOINFO decl-tree-absent rc=2；PTS_GUARD 六字段齐；selftest PASS pass=37 fail=0）｜⑦ 四条不变量 62/234/62 gen=#81/234；两哨兵 cmp IDENTICAL（FP=d697b1e10ff48881=BRIDGE_SRC_FP ≠ inputs_fp ⇒ 不该重写）；inputs_fp 三次现取 0581db21fe4cf1a2→8ea520791f2a9832→ead7b6488922c1c0（前者 t76 已留痕于 HANDOFF-NEXT 与载体，后两次归属未核）｜⑧ 载体新建 UTF-8 首记号 # P1-G10-DOMAIN-VERIFY mode 644 末行自报｜HEAD ab1ac00｜NOINFO 5 条
SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-g10-domain-verify.md | sha256sum | cut -c1-16`）= `7a9fbcab1afedd5a`
