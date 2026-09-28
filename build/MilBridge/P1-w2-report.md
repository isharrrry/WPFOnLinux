# P1-W2 装置牙批甲 收口报告（`t14`）—— B-3／B-4／B-7／B-8／B-9

`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜基点 `HEAD=39f23d0`｜写者 `scribe`｜判据件（**先写**）＝ `build/MilBridge/P1-w2-criteria.md`
依据件 ＝ `build/MilBridge/P1-tail-scout.md`（`493808af2699c40a`）**W2 行** ＋ `### B-3 ·`／`### B-4 ·`／`### B-7 ·`／`### B-8 ·`／`### B-9 ·`（**已现取读过原文**）
**波内顺序（硬约束）已遵守**：**B-3（9 件 `.cs`）先落 → B-4（扩 `tree` 面）后落**。顺序证据见 §2。

## §0 五条逐条判词

| 条 | 判 | 关键现取读数 |
|---|---|---|
| **B-3** | **已修**（①③）／**②`NOINFO`** | 退役字面量 `9 件/12 处` → **`0`**；`git ls-files '*.cs' \| xargs grep -l` ＝ **`0`**；缺根＝**响亮 `throw`**；`CoverageProbe` 三支臂 **`NOINFO(reason=heavy-slot 被占)`** |
| **B-4** | **已修 ＋ 两极化真跑** | `files=229 → 565`、`code=0` ⇒ `RETIREDPATH=PASS`；反极 ⇒ `FAIL` 点名 `build/probe/Foo.cs:2`；`--selftest` `8/8` |
| **B-7** | **只登记（保留该行）＋ 两极化真跑** | 真树 `ALIAS=PASS examined=18075 linked_gt1=0 … rc=0`；沙箱三腿：cap2 `PASS`／cap1 `FAIL allowed-tree-grown`／无白名单 `FAIL out-of-repo-alias` |
| **B-8** | **已修 ＋ 两极化真跑** | `零证据力` `0 → 1`；G10 名 `CreateInstalledObjectsInfo → LoCreateContext`；正极 `PTS_G10_NAME=PASS`；反极 `FAIL` 点名 `rc=1`；`--selftest` `24/24` |
| **B-9** | **已修 ＋ 两极化真跑（沙箱 `X11` 注入）** | 反极 `DISPLAY_OCCUPIED=:237 … rc=3`（拒跑）；正极 `DISPLAY_LEASE=free …`；**真 `:237` 占用腿＝`NOINFO(reason=heavy-slot 被占)`** |

## §1 B-3 —— 九件 `.cs` 死根面（**已修 ①③／`NOINFO` ②**）

**改前现取（逐件）**：`git ls-files '*.cs' | xargs grep -l 'wpf-linux-20260906' | wc -l` ＝ **`9`**（12 处：`T2eLineHeight:24`／`PcLineOracle:171`／`CoverageProbe:88,1028,1159,1240`／`FrameProbe:309`／`ResolverGuardProbe:40`／`LsProbe:9`／`BboxProbe:23`／`IcuBreakParity:62`／`WicSeamProbe:15`）。
**改法（统一口径）**：字面量 → **env 注入 ＋ 缺则 `throw`（响亮失败）**；`const` 派生量同步去 `const`（全部用法都是语句/表达式位置 ⇒ 无 `const` 上下文，编译安全由逐点 `grep` 举证）。
**改后逐字（抽样三件；其余六件同形）**：

`build/MilBridge/tests/T2eLineHeight/Program.cs` `:24`–`:29`：
```
    private static readonly string Root = Environment.GetEnvironmentVariable("WPF_PROBE_T2E_ROOT")
        ?? throw new InvalidOperationException("死根已清：未设 WPF_PROBE_T2E_ROOT（本件不再内嵌退役树路径）");
    private static readonly string Dir = Root + "/tests/parity/windows/layout-b34";
    private static readonly string CasesPath = Dir + "/cases-cd2.json";
    private static readonly string ResultsPath = Dir + "/results-cd2.json";
    private static readonly string FontLat = Root + "/build/fonts/NotoSans-Regular.ttf";
```
`build/MilBridge/tests/LsProbe/Program.cs` `:9`–`:10`：
```
        string shim = Environment.GetEnvironmentVariable("WPF_PROBE_SHIM")
            ?? throw new InvalidOperationException("死根已清：未设 WPF_PROBE_SHIM（本件不再内嵌退役树路径）");
```
`build/MilBridge/tests/CoverageProbe/Program.cs` `:88`–`:89`（另三处 local 同形，`1028/1159/1240` 与其 `fontPath` 各去 `const`）：
```
        private static readonly string Root = Environment.GetEnvironmentVariable("WPF_PROBE_COVERAGE_ROOT")
            ?? throw new InvalidOperationException("死根已清：未设 WPF_PROBE_COVERAGE_ROOT（本件不再内嵌退役树路径）");
```
**判据 ①**：`git ls-files '*.cs' | xargs grep -l 'wpf-linux-20260906' | wc -l` ⇒ **`0`**（全仓 `*.cs` 命中亦 `0`）｜**判据 ②**：每处都是 `?? throw new InvalidOperationException("死根已清：未设 <VAR>…")` ⇒ **缺根不静默**（`PcLineOracle` 那一处是**现取无任何使用点**的符号 ⇒ 用 `?? ""` 兜底，如实点名）。
**判据 ③（`CoverageProbe` 死根面）＝ `NOINFO`**：需三支臂真跑（重活＋显示位），`heavy-slot` 现取 **`HEAVYSLOT=TIMEOUT waited=5s slot_rc=9`**（`t7` 在飞长占）⇒ **`NOINFO(reason=heavy-slot 被占，三支臂未跑)`**；**未当绿、未改判据绕开**。

## §2 B-4 —— 守卫射程洞（**已修 ＋ 两极化**）与**顺序证据**

**改前现取**：`pkg-src-retiredpath-check.sh` ＝ `d54a5a14c1934bac`；`collect_corpus()` 的 `tree` 面**只扫** `*.sh/*.py/*.c/*.h` ⇒ `RETIREDPATH=PASS mode=tree files=229 hits=3 code=0` 而同一 needle 在 `*.cs` 里命中 **9 件** ⇒ **射程洞成立**。
**改后逐字**（`:108`–`:110`）：
```
      find "$ROOT" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.cs' \) 2>/dev/null
      find "$ROOT/build" "$ROOT/tests" "$ROOT/src" -type f \
           \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' -o -name '*.cs' \) 2>/dev/null
```
**正极**：`RETIREDPATH=PASS mode=tree files=565 hits=3 code=0 declared=3 self_skip=1 needle=wpf-linux-20260906` ⇒ **`files=229 → 565`（域真变了，不是只改打印）**；`--selftest` ⇒ `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0`。
**反极（沙箱，`*.cs` 塞回退役路径）**：`RETIREDPATH=FAIL` ＋ 点名 **`build/probe/Foo.cs:2 kind=code rule=code-retired-path`**（`rc=1`）；对照（拿掉该件）⇒ `RETIREDPATH=NOINFO reason=empty-corpus rc=3`（**零语料不当绿**）。
**顺序证据（硬约束）**：用**新牙**扫「**B-3 之前**」那 9 件（沙箱 `~/w281-scribe/sbx-b4pre`）⇒ `RETIREDPATH_SCAN mode=tree files=9 hits=12 code=12` ＋ 逐件点名 ⇒ **若先扩域，这 9 件当场判红**（正确的红）⇒ 先 `.cs` 后牙的次序**必须**如此。
⚠️ **一处现取不符（如实报）**：契约 `inScope` 列的 `build/MilBridge/tools/retired-path-provenance.tsv` **现取不存在**（`stat` 失败）；真件是 **`build/MilBridge/retired-path-provenance.tsv`**（`2200 B`，脚本默认 `PROV="$ROOT/build/MilBridge/retired-path-provenance.tsv"`）⇒ 该件**不在本契约写域** ⇒ **本席一件未碰**（B-4 也无需动它：`code=0` ⇒ 无新增豁免需求）。

## §3 B-7 —— `arm-logs` 白名单上限（**只登记：保留该行**）

**改前现取**：白名单件 `5813863882022812`；唯一数据行上限 `6417`。真树现跑 ⇒ `ALIAS=PASS examined=18075 linked_gt1=0 aliased_out=0 aliased_allowed=0 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=5.42 rc=0 reason=no-out-of-repo-alias`。
**改后逐字（只增注释，`:28`–`:36`）**：
```
# ⏪ **dated 现取补注（`t14`／W2·B-7，读时 2026-09-28T16:02:39+0800）**：本行**保留**，并写明它**今天**该是多少。
#   · **被比量 ＝ 该前缀下的「孪生计数」**，**不是**该树的**物理件数** —— 我沙箱两极化现跑证实（自造孪生 `2` 件）：`上限 1` ⇒ `ALIAS=FAIL … rc=1 reason=allowed-tree-grown`；`上限 2` ⇒ `ALIAS=PASS … rc=0 reason=known-alias-trees`；**无白名单** ⇒ `ALIAS=FAIL … aliased_unallowed=2 rc=1 reason=out-of-repo-alias`。
#   · **现取孪生 ＝ `0`**（真树：`ALIAS=PASS examined=18075 linked_gt1=0 aliased_out=0 aliased_allowed=0 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=5.42 rc=0 reason=no-out-of-repo-alias`）⇒ **`allowed-tree-grown` 现取恒不触发** —— 这是**真实边界**，不是牙坏了。
#   · ⚠️ **量名歧义（如实记）**：`find /home/links-dev/w62a/negrepo -type f | wc -l` 现取 ＝ **`12918`** ⇒ 侦察件 §B-7 §1 的「对着一个现取 **0** 件的树」**只对"孪生计数"成立**、对该树**物理件数不成立**（两个量不是一回事）。
#   · **本波不删该行**：删 ⇒ 牙回到最严档（任何孪生即红），那是**另一项决定**（须队长裁）；本波只登记现取事实与量名口径。
#   · 口径句（上一行，**逐字、不得改写**）**仍有效**：**"允许清单是声明式豁免，不是把牙关掉。"**

```
**两极化真跑（沙箱 `~/w281-scribe/sbx-b7`，自造孪生 `2` 件）**：`上限 2` ⇒ `ALIAS=PASS … rc=0 reason=known-alias-trees`｜`上限 1` ⇒ **`ALIAS=FAIL … rc=1 reason=allowed-tree-grown`**｜**无白名单** ⇒ **`ALIAS=FAIL … aliased_unallowed=2 rc=1 reason=out-of-repo-alias`** ⇒ 三腿都有原始机读行。
⇒ **被比量 ＝「孪生计数」**（不是树的物理件数）：现取孪生 `0` ⇒ `allowed-tree-grown` **恒不触发**（真实边界）；**量名歧义如实记**：`find ~/w62a/negrepo -type f | wc -l` ＝ **`12918`** ⇒ 侦察 §B-7 §1 的「0 件」**只对孪生计数成立**。

## §4 B-8 —— 「零证据力」口径入件 ＋ G10 具名（**已修 ＋ 两极化**）

**改前现取**：`grep -c '零证据力' pts-pages-guard.sh` ＝ **`0`**；件头 `:22` 逐字含 **`PTS_GAP entry=CreateInstalledObjectsInfo`**（**旧前沿**），而现取前沿（`evidence/app_g1.log`）＝ **`entry=LoCreateContext` × 3**。
**改后逐字（口径块 `:102`–`:105` ＋ 自检函数 `:106`–`124`）**：
```
# ⏪ **dated 口径入件（`t14`／W2·B-8，读时 2026-09-28T16:02:39+0800）**：本判据件的**射程边界**（原先只写在 `build/MilBridge/P0-mvp-pts-report.md`，现**搬进判据件自身**）：
#   · **本步只读 `leg_*.env` 的列，不读 `entry=` ⇒ 它的绿对"前沿位移"零证据力。**
#   · 因此本件**自带一条具名对拍**：件头 `G10` 描述的 `entry=<名>` 与 `--legs <dir>/app_g1.log` 的**现取前沿名**必须**逐字相同** ⇒ 不同即 `FAIL` 并点名（`PTS_G10_NAME=FAIL header=… observed=…`）；算不出来（缺件/无日志）⇒ `NOINFO`，**不许当绿**。
#   · ⚠️ **`verify-all.sh` 的行号必须现取、不许写死**（历史在册句引 `:1173`，现取命中行不是它）⇒ 本件不写步号、不写行号。
# 【`t14`／W2·B-8】件头 G10 具名 ⇔ 现取前沿（**口径搬进判据件自身**；不符 ⇒ 红并点名；算不出 ⇒ NOINFO）
g10_name_check() {
  local dir="$1" hdr obs
  hdr="$(sed -n 's/.*G10 至少一条 native `PTS_GAP entry=\([A-Za-z0-9_]*\)`.*/\1/p' "${BASH_SOURCE[0]}" | head -1)"
  obs="$(grep -o 'entry=[A-Za-z0-9_]*' "$dir/app_g1.log" 2>/dev/null | sed 's/^entry=//' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
  if [ -z "$hdr" ] || [ -z "$obs" ]; then
    echo "PTS_G10_NAME=NOINFO reason=算不出来 header='${hdr}' observed='${obs}'（**不许当绿**）"
    return 0
  fi
  if [ "$hdr" != "$obs" ]; then
    echo "PTS_G10_NAME=FAIL header=$hdr observed=$obs（件头具名与现取前沿不一致 ⇒ 红并点名）"
    return 1
  fi
  echo "PTS_G10_NAME=PASS header=$hdr observed=$obs"
  return 0
}

judge_legs() {
  local dir="$1"
```
**读数**：`零证据力` 命中 **`1`**；件头 G10 名 ＝ **`LoCreateContext`**（＝现取前沿，逐字相同）。
**正极**：`PTS_G10_NAME=PASS header=LoCreateContext observed=LoCreateContext` ＋ `PTS_GUARD=PASS legs=2/2 … rc=0`。
**反极（沙箱：把前沿日志副本改回旧名）**：`PTS_G10_NAME=FAIL header=LoCreateContext observed=CreateInstalledObjectsInfo（件头具名与现取前沿不一致 ⇒ 红并点名）` ⇒ **`rc=1`**。
`--selftest` ⇒ `PTS_GUARD_SELFTEST=PASS pass=24 fail=0`（未退化）。

## §5 B-9 —— `session_inner.sh` 显示号占用断言（**已修 ＋ 两极化**）

**改前现取**：`D="${W67_DISPLAY:-:237}"` ⇒ **无占用断言**（成立）；`evidence/device.txt` ＝ `X_UP=yes display=:237`。
**改后逐字（`:19`–`:25`）**：
```
# ⏪【`t14`／W2·B-9，读时 2026-09-28T16:02:39+0800】默认显示号**占用探测**（`D-G139` 同族：长跑自起的显示位必须按 PID 收净；**不许静默复用别人的号**）
XDIR="${WPF_X11_DIR:-/tmp/.X11-unix}"
if [ -S "$XDIR/X${D#:}" ]; then
  echo "DISPLAY_OCCUPIED=$D sock=$XDIR/X${D#:} ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）" >&2
  exit 3
fi
echo "DISPLAY_LEASE=free display=$D sock=$XDIR/X${D#:}" >&2
```
**两极化真跑（沙箱 `X11` 目录注入，零 `Xvfb`、零显示位冲突）**：**反极**＝沙箱里占住 `:237` ⇒ `DISPLAY_OCCUPIED=:237 sock=~/w281-scribe/x11-occ/X237 ⇒ 拒跑…` ＋ **`rc=3`**（不静默复用）｜**正极**＝空目录 ⇒ `DISPLAY_LEASE=free display=:237 sock=…/x11-free/X237` 后继续（组 `99` 因缺 shim 快速退出 `rc=0`）。
**真 `:237` 被真 `Xvfb` 占用**那一档 ⇒ **`NOINFO(reason=heavy-slot 被占 + 显示位冲突风险)`**（`HEAVYSLOT=TIMEOUT`），**未当绿**。

## §6 覆盖面位移（**逐件归因**）

**入口**：`inputs_fp = abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`｜覆盖面 **`226`**
**出口**：`inputs_fp = e9f95ec005715b3a7bff1a7bca4b525fafad98068e7a389ad8b9b91b8a9dc5a3`｜覆盖面 **`226`**
**归因（逐件 `grep -cF <件> <infp list>`）**：**在覆盖面内 `4` 件** ⇒ `repo-alias-allow.tsv`／`tests/PtsPagesProbe/session_inner.sh`／`tools/pkg-src-retiredpath-check.sh`／`tools/pts-pages-guard.sh`（**这 4 件就是位移的全部动因**）；**不在覆盖面 `9` 件** ⇒ 九件 `.cs`（`inFP=0` 逐件现取）⇒ **件数不变 ⇒ `[42] --expect 226` 不动**（`verify-all.sh` 未碰）。

## §7 越域 / 两牙 / 槽

`git status --porcelain` ＝ **`M` × 13**（全部本波 `inScope`，逐件见上）＋ **`??` × 3**：`P1-w2-criteria.md`（**本席**）／`P1-task0201-criteria.md`（**`t7` 的**）／`P1-w1-verify.md`（**非本席，W1 复核件**）⇒ **本席零越域**（`t7` 的件**未读未改**）。
`DEFREG=PASS declared=215 route_ids=215`（两牙未退化）｜`REPORTID=PASS files=192 ids=2034 declared=215`｜`run_step` ＝ `55`（未变，本波不加步）｜**未** `git add/commit/push`；临时件残留 `0`。
**槽**：`~/heavy-slot.sh --min-avail 1500 --max-hold 60 --wait 5 -- …` ⇒ **`HEAVYSLOT=TIMEOUT waited=5s slot_rc=9`**（`t7` 长占）⇒ B-3③／B-9 真显示腿 **`NOINFO`**，**未用任何"反正不跑"绕开判据**。
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ **`e37f0270a525e815`**（整 64 hex 见交件消息）／本件 `wc -l` ＝ **`136` 行**（含本行；不含本行 `135` 行）／末次现取时刻 ＝ `2026-09-28T16:06:25+0800`／写入方式 ＝ **temp ＋ `rename`**／同趟自证：`DEFREG=PASS declared=215 route_ids=215`；`REPORTID=PASS files=193 ids=2035 declared=215`（rc=0）；`git ls-files '*.cs' | xargs grep -l 'wpf-linux-20260906' | wc -l` ＝ `0`；`RETIREDPATH=PASS mode=tree files=565 code=0`；`HEAVYSLOT=TIMEOUT waited=5s slot_rc=9`（B-3③／B-9 真显示腿＝`NOINFO`）。

⏪ **dated 追加 · W1 关账（`t25`，读时 2026-09-28T16:20:54+0800）** —— `t15` §5-W1 点名的 low 收口：以下 **15 件**（13 改 ＋ 2 新建）**改后 sha16 全表**由 **本席现取自算**（**未照抄** `t15` §3；现取时刻 ＝ 2026-09-28T16:20:54+0800）。
⏪ 逐件（件 ＋ 字段 ＋ sha16 ＋ `inFP` 现取）：
⏪ 1. `build/DirectWrite.Linux/WicSeamProbe/Program.cs` ⇒ `b36728870f822a23`（`inFP=0`）
⏪ 2. `build/MilBridge/tests/BboxProbe/Program.cs` ⇒ `2001427e88b7f709`（`inFP=0`）
⏪ 3. `build/MilBridge/tests/CoverageProbe/Program.cs` ⇒ `c78ed88fc1fd34f4`（`inFP=0`）
⏪ 4. `build/MilBridge/tests/FrameProbe/Program.cs` ⇒ `b6d00269cf6f6aad`（`inFP=0`）
⏪ 5. `build/MilBridge/tests/IcuBreakParity/Program.cs` ⇒ `52f0ab739aaacf3b`（`inFP=0`）
⏪ 6. `build/MilBridge/tests/LsProbe/Program.cs` ⇒ `f536e535d6903227`（`inFP=0`）
⏪ 7. `build/MilBridge/tests/PcLineOracle/Program.cs` ⇒ `a23b7476833da140`（`inFP=0`）
⏪ 8. `build/MilBridge/tests/ResolverGuardProbe/Program.cs` ⇒ `ca6f1bea560f2326`（`inFP=0`）
⏪ 9. `build/MilBridge/tests/T2eLineHeight/Program.cs` ⇒ `1f719638830afdde`（`inFP=0`）
⏪ 10. `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` ⇒ `a70aeb1d988ebc9e`（`inFP=1`）
⏪ 11. `build/MilBridge/tools/pkg-src-retiredpath-check.sh` ⇒ `60009734108344bd`（`inFP=1`）
⏪ 12. `build/MilBridge/tools/pts-pages-guard.sh` ⇒ `7074a774739efaf2`（`inFP=1`）
⏪ 13. `build/MilBridge/repo-alias-allow.tsv` ⇒ `19496f3615ccb45a`（`inFP=1`）
⏪ 14. `build/MilBridge/P1-w2-criteria.md` ⇒ `ceecddcccda8521f`（`inFP=0`）
⏪ 15. `build/MilBridge/P1-w2-report.md` ⇒ `80e1583d2680b382`（`inFP=0`）
⏪ **对拍结论**：15 格与 `t15` §3 表**逐位相同、无一格不同**（本席独立自算 ⇒ **不是转述**）；第 `11`／`12`／`13` 件的现取来源是成对的两颗牙与本波白名单。
⏪ **载体两格复算**（`t14` 自报）：`P1-w2-criteria.md` ＝ `ceecddcccda8521f` ⇒ 逐位相同；`P1-w2-report.md` **追加前** `head -n -1` ＝ `e37f0270a525e815`（`wc -l` ＝ `136`）⇒ 逐位相同。
⏪ ⚠️ **口径提醒**：本追加块落定后，本件 `head -n -1` 的值**已不是** `e37f0270a525e815`（追加行都在末尾）⇒ 此后引用本件 sha16 **必须写明时刻**（`t14` 写入时刻 vs `t25` 追加后）；`t14` 原句**一字未删**。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-w2-report.md` ＝ `44f578c12a64431b`（口径＝**末行之前的全文**；末行＝**本行**）；**全文** sha16 由 `build/MilBridge/P1-w2-close-report.md` 现算登记（本件末行带自身口径 ⇒ 全文值不可能自指）。

⏪ **dated 追加 · V1（15 件表内第 `11` 行补口径）（`t31`，读时 2026-09-28T16:33:26.546+0800）** —— `t26` 判词 §3-V1 点名：表内**第 `11` 行**那格是 `t14` **交付态**值，而**同一笔提交的 W2 修法（B-4）已把该件改掉** ⇒ 逐件现取对拍有 **1 格未声明的不符**（对照：**第 `15` 行**那格**已显式声明**自指口径）。
⏪ **口径（此后一律按此读）**：第 `11` 行 `build/MilBridge/tools/pkg-src-retiredpath-check.sh` ⇒ **`60009734108344bd` ＝ `t14` 交付态值**（与本块「与本席 §3 表逐位相同」一致）；**该件现值 ＝ `231ae30326a4fb31`（`312` 行）** ＝ `t14` 那一笔里的 W2 修法（B-4）之后的值 ⇒ **此后引用该件一律以现取为准**。
⏪ **与第 `15` 行写法对齐（两格同构）**：第 `15` 行属「现取不符」但**块内已声明**其口径（本件自身 `head -n -1`／全文两组值 ＋ 时刻）；第 `11` 行**在本笔之前无任何口径注** ⇒ 本笔补齐 ⇒ 两格此后**同构**：「**表内值 ＝ 某时刻／某交付态**」＋「**现值另给**」。
⏪ **实质不变**：15 格与原表**一字未动**、与本席 §3 表**逐位相同**；本笔**只补口径**，不改任何数值、不动原表一行、不删一字。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-w2-report.md` ＝ `c731f344172400bd`（口径＝**末行之前的全文**；末行＝**本行**）；上一行（`t25` 落）的 `44f578c12a64431b` 是其**写入时刻**的口径 ⇒ **此后以本行为准**。

⏪ **dated 追加 · F1（`:161` 的「现值」格更正）（`t37`，读时 2026-09-28T16:47:10.490+0800）** —— `t32` §1.3 点名（medium）：该格写的现值**不是**真实现值。
⏪ **真现值（本席现算）**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh` ⇒ **sha16 ＝ `3bd03726089bf949`**、**`317` 行**。**可复算命令原文**：`sha256sum build/MilBridge/tools/pkg-src-retiredpath-check.sh | cut -c1-16` ⇒ `3bd03726089bf949`；`wc -l build/MilBridge/tools/pkg-src-retiredpath-check.sh` ⇒ `317`。
⏪ **`:161` 写的 `231ae30326a4fb31`（`312` 行）＝「本笔 V2 修法（`t31`）之前」的值** ⇒ **该格不是「`t14` 交付态」的对照值**：`t14` 交付态值仍是 `60009734108344bd`（表内第 `11` 行），`231ae30326a4fb31` 是**同一件在 B-4 之后、`t31` 措辞修之前**的中途值 ⇒ 三种值各归其位。
⏪ **为何是「口径错」而非「时效漂移」（本席现算）**：该件**落盘 `mtime` ＝ `2026-09-28 16:32:51.925195455`**，而 `:161` 所在追加块的**读时戳 ＝ `2026-09-28T16:33:26.546+0800`** ⇒ **落盘比该句读时早 `34.621 s`** ⇒ 写这句时该件**已经是** `t31` 修后的值，写者却写进了修前的值 ⇒ **不是时序漂移、是口径错**（`D-G125` 族：件与总和都对、错的只是消息）。
⏪ **读法（此后一律）**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh` 现取 **`3bd03726089bf949`／`317` 行**（读时见本行行首戳）；`60009734108344bd`（`t14` 交付态）与 `231ae30326a4fb31`（V2 修法后／`t31` 前）**均只作历史对照、不作现取依据**。
⏪ **追加后口径**：`head -n -1 build/MilBridge/P1-w2-report.md` ＝ `31ad2fd229d2f1f7`（口径＝**末行之前的全文**；末行＝**本行**）；上一行（`t31` 落）的 `c731f344172400bd` 是其**写入时刻**的口径 ⇒ 此后以本行为准。
