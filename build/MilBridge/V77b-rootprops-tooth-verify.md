# `V77b-rootprops-tooth-verify.md` —— `#79-A` 两颗新牙的独立复验（车道 `verifier` / `t16`）

- 对象：`root-entries-allowlist-check.sh`（`TASK-0750`，现取 sha16 `0983051ab8212bc2`）与 `wiring-closure-check.sh`（`TASK-0751`，`178055f40d3a1cf0`）＋ 接线/覆盖面/`[42] --expect` 同趟一致性
- `N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜`HEAD`＝工作树（**时刻读数 12:0x**：`verify-all.sh` sha16 `5c75efcead70dac8`、`close-wave.sh` `882da76e644522f5`；⚠️ 12:1x 再取已变成 `52b4d0a7e687328d`／`fcb56d02e66d7b89` ⇒ **别的车道正在改这两件**，见 §6-8）｜只读 `$N`（除本报告）；一切两极化的形态都在 `~/w28x/t16/**` 我自己的沙箱里造
- 判据先写＝本文件 §0 的清单（开工前已定「每条怎么证伪/什么算不一致」）

## 0. 结论一句话

**两颗牙的判据本体我逐条复现通过**：白名单牙是**真白名单**（沙箱里放一个**清单外的新文件** `foo.txt` ⇒ **红并点名**）、**两个来源都生效**、**一次放两件也点名两件**；接线闭合牙的 **A/B 两个方向我自己的形态都红并点名**，**合法 `NOINFO` 不误报**。**但现盘有两处真不一致**：① 覆盖面现取 **225** ≠ `[42] --expect` **219**（差 6，来自**别的车道**在我复验期间新增的件）⇒ 下一次整跑第 `[42]` 步会 `files-n-mismatch`；② 两条新登记的「三处一致」只做到两处。⇒ **判 `failed`**（findings 见 §6；两件牙本身可用）。

---

## 1. 根级条目白名单牙（我自己造形态，不看它的 `--selftest`）

夹具：`~/w28x/t16/fx`（我自己的 `git init` 仓，根条目**只放清单内**的 22 项）。`.editorconfig` 用上游逐字件（`git show origin/main:.editorconfig` ⇒ **76,255 B**、sha16 **`bf84100e2afbd3d2`**，与派单给的值逐位相同）。

| 腿 | 形态（我造） | 现取读数 | 判定 |
|---|---|---|---|
| T1 正极 | 沙箱只有清单内条目（`--root` 指沙箱） | `ROOT_ALLOW=PASS examined=22 tracked_n=22 worktree_n=22 allowed_n=25 unknown_tracked=0 unknown_fs=0` rc=0 | ✓ 非空绿 |
| **T6 白名单语义（最重要）** | 沙箱放入**清单外的、新的**根级文件 `foo.txt` | `ROOT_ALLOW_HIT entry=foo.txt source=test-e rule=not-in-allowlist` ⇒ `ROOT_ALLOW=FAIL … unknown_fs=1 unknown= foo.txt` rc=1 | ✓ **不是枚举黑名单** |
| T7 上游件 | 放入上游 `Microsoft.Dotnet.Wpf.sln` | `HIT entry=Microsoft.Dotnet.Wpf.sln source=test-e rule=not-in-allowlist` rc=1 | ✓ |
| T2 `.editorconfig` | 上游逐字件（tracked） | **两条** HIT：`source=git-ls-files` ＋ `source=test-e`，`entry=.editorconfig`，rc=1 | ✓ 点名 |
| T3 `Directory.Build.props` | 上游件（tracked） | 同上（两来源各一条 HIT）rc=1 | ✓ 点名 |
| T4 `NuGet.config` | **未跟踪**（只可能被工作树来源看见） | `HIT entry=NuGet.config source=test-e`，`unknown_tracked=0 unknown_fs=1` rc=1 | ✓ **工作树来源真生效** |
| T5 一次放两件 | `Directory.Build.props` ＋ `NuGet.config` | **两条** HIT（两件都点名）rc=1 | ✓ 不是"只报第一件" |
| T8 清单件缺席 | `--allow /nonexistent/allow.tsv` | `ROOT_ALLOW=NOINFO reason=allowlist-absent` rc=**3** | ✓ 不判绿 |
| T9 非 git 树 | `--root` 指向普通目录 | `ROOT_ALLOW=NOINFO reason=not-a-git-tree` rc=**3** | ✓ 来源①取不到就不判绿 |
| T1b 回正 | 与 T1 同 | `ROOT_ALLOW=PASS examined=22` rc=0 | ✓ 上面的红都非空转 |

- **判据域（来源两个都跑）**：T3（只 tracked）与 T4（只 fs）分别命中**不同**来源 ⇒ 两支都真跑（不是只跑一支）。
- **"加回那一刻就响"**：T2/T3 的读数**不需要跑构建**（`bash <牙> --root <沙箱>` 秒级即红）；`MSB4236`（求值期）与分析器 `error`（编译期）都不是它的判据，我也**没有**用它们替代。
- **机读行**：命中行 `ROOT_ALLOW_HIT entry=<名> source=<git-ls-files|test-e> rule=not-in-allowlist` + 汇总 `ROOT_ALLOW=… examined/tracked_n/worktree_n/allowed_n/unknown_tracked/unknown_fs/unknown/rc`，另有 `ROOT_ALLOW_NOTE excluded=.git`、`sources …`、`source-skew …` ⇒ **判定来源印出来了**（见 §6-F4 的两处缺口）。

## 2. 接线闭合性牙（A 方向 / B 方向，各我自己造）

夹具：`~/w28x/t16/wc/root`（`build/MilBridge/tools/{good.sh,newtooth.sh}` ＋ 我自己的 `verify-all.sh`）。

| 腿 | 形态 | 读数 | 判定 |
|---|---|---|---|
| 正极 | 交付牙已接线、入口牙无黑名单判词 | `WIRING_CLOSURE=PASS steps=2 jaws_n=1 undeclared=0 …` rc=0 | ✓ |
| **A 方向** | 新放一件**带 `--selftest` 但没接线、也不在册**的 `newtooth.sh` | `WIRING_CLOSURE_HIT rule=undeclared-jaw file=build/MilBridge/tools/newtooth.sh（带 --selftest 却既没接线、也不在声明册里）` ⇒ FAIL rc=1 | ✓ 点名该件 |
| A 方向回正 | 给它加一行 `run_step "NEWTOOTH" bash …` | `WIRING_CLOSURE=PASS … undeclared=0` rc=0 | ✓ 红非空转 |
| **B1 方向** | 某步入入口牙的**代码行**里出现黑名单 reason（`reason=usage:--cases-needs-file`） | `HIT rule=didnt-judge-reason step=GOOD jaw=build/MilBridge/tools/good.sh key=usage:--cases-needs-file hits=1` rc=1 | ✓ **点名步 + 点名牙路径** |
| **B1b 合法 NOINFO** | 同一位置换成**非黑名单** reason（`sock-id-absent`）＋ `cases=5` | `WIRING_CLOSURE=PASS` rc=0 | ✓ **不误报**（没把 NOINFO 一律当红） |
| **B2 字段形态** | 合法 reason 但 `cases=0` | `HIT rule=didnt-judge-casecount step=GOOD jaw=… key=FIELD:cases=0 hits=1` rc=1 | ✓ |
| 件路径身份 | 命中行给的是 `jaw=build/MilBridge/tools/good.sh`（**路径**，来自该 `run_step` 行的第一个 `bash <仓内路径>`） | 与拼写无关（`D-G132` 族）✓ | ✓ |

- **真树现取**：`WIRING_CLOSURE=FAIL steps=53 jaws_n=52 undeclared=2 … fails=2 rc=1`；点名的是 `build/MilBridge/tools/report-id-domain-check.sh` 与 `pkg-src-retiredpath-check.sh`（**别的车道 `??` 未跟踪的在飞件**，见 §6-F2）——`t20` 已如实声明这一格。

## 3. 判据域 / 互补性

- **`#78` 的教训（机器常数不在覆盖面里）**：本波两颗牙的**声明输入都内嵌在牙本体**（`read_allow()` 的 `ALLOWLIST` heredoc：白名单 23 行；`wiring` 的 `ROSTER`/`EXEMPT` 亦为内嵌 heredoc，仅 `WCX_ROSTER_FILE`/`WCX_EXEMPT_FILE` 可被测试覆写）⇒ 声明随件进覆盖面 ⇒ **不存在"常数在覆盖面之外"那一族**（与 `FP-MANIFEST-TEETH --expect` 的旧形态不同）。
- **互补、不代偿**：同一棵真树上两条牙的现取状态**不同步**——`WIRING_CLOSURE=FAIL undeclared=2` 而 `WIRING_COVERAGE`（`TASK-0740`）仍是 `missing_n=0` 档；我的沙箱腿里也只让**一条**变红（A1/B1）而另一条的判据面（覆盖面）根本没被触及 ⇒ **任一条通过不得被读成另一条通过**这句成立。

## 4. 落地后的计数与 `PROTO-ATTR`

```
grep -c '^run_step "' verify-all.sh                 → 53
# VERIFYALL-STEPS-DECL: 53 gen=#79（首行）｜STEP-NAMES = 53 名
VERIFYALL_SELF=PASS names=53 decl=53 gen=#79 dup=0 order=OK prose=OK prereg=PASS vfile_sha16=5c75efcead70dac8
run_step "PROTO-ATTR" bash build/MilBridge/tools/proto-attribution-check.sh --cases build/MilBridge/tools/proto-attribution-cases.tsv --expect 18
PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1
PROTO_ATTR=ATTRIBUTED cases=18 pass=3 fail=2 noinfo=13 rc=0
```
- `--cases` **在位** ⇒ 走**真判**分支（**不是** `reason=usage:--cases-needs-file`）✓；`--expect 18` 在位 ✓；`verify-all.sh` **不在** `fp_inputs()` 覆盖面（`list|grep -c verify-all.sh` = **0**）✓。
- ⚠️ 派单里那组「`steps=50`／`--expect 211`／`names=50 decl=50` 逐格不变」的期望值**已被 `#79-A` 取代**（`t20` 同趟声明加两步 ⇒ 53/219/53）——我核的是**取代后的值自洽**（见 §6-F1 的例外）。

## 5. 两条新登记：我自己的复算

- **九位的路径承载性**（自己复算，不看报告）：五个托管件 `strings -a` 各命中 **1** 条 `GitProj/WPFOnLinux` 路径串、**0** 条旧路径串；字节数 **`pc 3601408`／`pf 6123520`／`windowsbase 1111552`／`provider 104448`／`dwf 39936`**，与 `#76` 冻结值**逐位相同** ⇒ "同尺寸、内容不同 = 路径承载体"✓（`D-G46` 更强形态）。
- **方法射程边界**（`-getProperty`/`-getItem:Compile` 覆盖不到 `.editorconfig` 这类编译器级输入）：`getProperty` 在 `docs/ROUTES.md`（1 处）与**缺陷册**（2 处）都在 ✓；`HANDOFF-NEXT.md` 无该字样（见 §6-F6 的如实划界）。

## 6. findings / 我推翻的话

1. 🔴 **覆盖面与机器常数现取不一致**：`infp.sh list | wc -l` = **225**，而 `verify-all.sh:1177` 的 `--expect` = **219** ⇒ 下一次整跑第 `[42]` 步会 `FAIL reason=files-n-mismatch delta=+6`。**归因（逐件）**：以我 11:41 的快照（217）为基，现读多出的 8 件 = `t20` 的两颗牙（`root-entries-allowlist-check.sh` 11:51、`wiring-closure-check.sh` 11:59）＋ **另外 6 件**（`blockvalues-shift.tsv` 11:47／`retired-path-provenance.tsv` 11:51／`pkg-src-retiredpath-check.sh` 11:51／`book-entry-required.tsv` 11:54／`report-id-domain-check.sh` 11:55／`wfreeze-root-sites.tsv` 12:02）⇒ `t20` 的算术（217＋2＝219）在**它落地那一刻是对的**，**当前的不一致是后续（并发的）覆盖面无同步扩面造成的**（本仓 `#78` 已记过同一族）。**处置**：把 `[42] --expect` 同趟改成**现取一次算准**的值（225），或把后 6 件退回/合并进一次「扩面波」。
2. 🟠 **A 方向把"在飞的未接线牙"判红 ⇒ 门禁此刻是红的**：`WIRING_CLOSURE=FAIL undeclared=2` 点名的两件是**别的车道** `??` 未跟踪件（`report-id-domain-check.sh`／`pkg-src-retiredpath-check.sh`）⇒ 这是该牙**设计的行为**，但意味着**整跑现在会红在第 `WIRING-CLOSURE` 步**，直到 `t27` 接线或这两件被撤。
3. ⚠️ **根级白名单牙的件头自述与内嵌表不一致**：件头把 `.editorconfig` 列在「③ fork 治理件（**允许清单**）」里，而 `read_allow()` 的 23 行表**没有** `.editorconfig`（这正是它 `--selftest` 的 `N3` 腿能变红的前提）⇒ 读者按件头会以为它被允许（`D-G136` 族：自述 vs 件）。
4. ⚠️ **绿档的"判定路径"不可见**：汇总行印了 `tracked_n/worktree_n/allowed_n/unknown*` 与逐条 `source=`，但**不印**被扫的 `root=`，也**不印**用的是内嵌清单还是 `--allow FILE`（只有 NOINFO 档才印 `file=`）⇒ 同一牙在两种清单下都可能印出形态相同的 `PASS`。
5. ⚠️ **来源标签与实现不符**：工作树来源的标签是 `source=test-e`，而实现是 `ls -A`（件头亦写 `ls -A`）⇒ 标签/实现口径不一（低危）。
6. ℹ️ **两条新登记的"三处一致"只做到两处**：`getProperty` 射程边界 = `ROUTES.md` 1 ＋ **缺陷册 2**（`HANDOFF-NEXT.md` 无该字样）；`路径承载` = `ROUTES.md` 1 ＋ `HANDOFF-NEXT.md` 1 ＋ **缺陷册 0**（我按该措辞找不见；可能以别的名字在册 ⇒ 记 `NOINFO`，不判死）。
8. ℹ️ **我复验期间真树被并发改动**：`verify-all.sh`／`close-wave.sh` 的 sha16 在 12:0x 与 12:1x 两次现取**不同**（`5c75efcead70dac8→52b4d0a7e687328d`／`882da76e644522f5→fcb56d02e66d7b89`），覆盖面也在同一窗口里从 219 涨到 225 ⇒ 本报告里所有"现取"值都**带时刻**；§6-1 的 `--expect` 不一致因此**每况愈下**，修它必须与扩面**同趟**做。
7. ℹ️ **派单里的期望值过期**：`steps=50/--expect 211/names=50 decl=50` 已被 `#79-A` 的 53/219/53 取代（`t20` 同趟声明）⇒ 我按**取代后**的值核（三处一致、`VERIFYALL_SELF=PASS`）。

**边界与 `NOINFO`**：① 覆盖面历史值（`t20` 落地那一刻是否恰 219）我**没有**机器可复算（缺那一刻的 `close-wave.sh` 备份）⇒ 只能给"217＋2"的算术归因；② `HANDOFF-NEXT.md` 里两条登记的对应段落我按字样未找到，未逐段通读；③ 两件牙的 `--selftest` 我只**另跑**看读数（10/10、11/11 PASS），判据一律用**我自己造的形态**；④ 未做并发两极化（两个租借者/两条牙同时被改）；⑤ `wiring` 的 B 方向"数据块不识别"射程（多行单引号内的登记表按代码行算）我**未**造形态验证。

## 7. 复算命令索引

```
# 根级白名单牙（我自己的沙箱）
git init ~/w28x/t16/fx && …（只放清单内条目）; bash build/MilBridge/tools/root-entries-allowlist-check.sh --root ~/w28x/t16/fx
git show origin/main:.editorconfig > ~/w28x/t16/fx/.editorconfig   # 76,255 B / bf84100e2afbd3d2
# 接线闭合牙（我自己的沙箱）
bash build/MilBridge/tools/wiring-closure-check.sh --root ~/w28x/t16/wc/root --verify-all ~/w28x/t16/wc/root/verify-all.sh
# 计数/覆盖面/PROTO-ATTR
grep -c '^run_step "' verify-all.sh ; bash build/MilBridge/tools/verify-all-step-check.sh
bash ~/w153a/bin/infp.sh fp ; bash ~/w153a/bin/infp.sh list | wc -l ; grep -n -- '--expect 219' verify-all.sh
grep -n '^run_step "PROTO-ATTR"' verify-all.sh ; bash build/MilBridge/tools/proto-attribution-check.sh --cases … --expect 18
# 路径承载性
for f in <五个托管件>; do stat -c %s $f; strings -a $f | grep -c 'GitProj/WPFOnLinux'; done
```

`V79A_TOOTH_VERIFY=DONE verdict=FAIL rootallow=我自造反极全红并点名(editorconfig/props/nuget/自建foo.txt/两件同放)+两来源都生效+绿档非空转 wiring=我自造A/B双方向红并点名+合法NOINFO不误报 counts=53/53/53+VERIFYALL_SELF=PASS expect=219≠list=225(差6,别人加件所致) protoattr=真判(–cases在位,examined=18) pathcarrier=5件各1条N路径串+字节与#76逐位同 findings=7`
`SELF_SHA16=9c61ef0dc8bc4614`（口径＝去掉本行：`head -n -1 build/MilBridge/V77b-rootprops-tooth-verify.md | sha256sum | cut -c1-16`）
