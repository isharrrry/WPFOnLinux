# P1-w2-verify —— `t14` W2 装置牙批甲的**独立复核判词**（`verifier` / `t15`）

- **被核交件**：`t14`（成员 `scribe`）的 W2 装置牙批甲 —— 提交 **`e6b25b776f208974176c52b24fffd2a9dd1b8b9e`**（`%cI = 2026-09-28T16:07:32+08:00`，父 `39f23d0623086e40…`）中 **`t14` 自己的 15 件**（`13` 改 ＋ `2` 新建）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`；**我开工时** `HEAD=72d78b8`（`16:07:44`，承载我上一件 `t13` 的载体）。
- **读取时刻**：本件全部读数在 **`2026-09-28T16:07:48` – `2026-09-28T16:11:09 +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-w2-verify.md`）＝我唯一写入的件。沙箱/夹具在 `~/wv83y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/应用/显示位；未 `git add/commit/push`。**不复述** `t14` 的任何结论 —— 每条我自己现取、每腿我自己跑。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | **四条两极化自己重跑** | **成立**（每条**成对**、原始机读行齐、**无空侧**）｜① `.cs` 塞回 ⇒ `FAIL` ＋ 点名 `build/probe/Foo.cs:2`｜② 白名单上限 1（孪生 2）⇒ `FAIL allowed-tree-grown`｜③ 显示号被占 ⇒ `rc=3` 拒跑（**沙箱 ＋ 真 `/tmp/.X11-unix/X237` 两条都做**）｜④ G10 具名改回旧名 ⇒ `FAIL` 点名 |
| 2 | **顺序证据**（先 `.cs` 后牙） | **成立**（**两条独立证据**：`mtime` 序列 ＋ **反事实**「新牙 × B-3 之前的九件 ⇒ `files=9 hits=12 code=12`」） |
| 3 | **覆盖面/指纹位移逐件归因** | **成立**：入口 `abc76bd55…`／`226` → 出口 `e9f95ec005715b3a…`／**`226`**；**`inFP=1` 恰 `4` 件**（`repo-alias-allow.tsv`／`session_inner.sh`／`pkg-src-retiredpath-check.sh`／`pts-pages-guard.sh`），其余 `11` 件 `inFP=0` ⇒ 件数不变 ⇒ `[42] --expect 226` **未改且无需改**；现跑 `[42]` ⇒ `PASS files_n=226 declared_expect=226`（**无 `files-n-mismatch`**） |
| 4 | **件级复核** | **成立**（含 `1` 格 `NOINFO`）：退役路径 `.cs` **命中 `0` 件**；`tree` 面**真覆盖 `*.cs`**（由会红的输入证明，`files 229 → 565` 且我按同一 corpus 规则复算 `566 − 1 self-skip = 565`）；`--selftest` 两件 `8/8`、`24/24` |
| 5 | `NOINFO` 具名 ／ 越域为零 ／ 未 add | **成立**（`porcelain` 逐行归属**全部为并发写者**；`t14` 名下**零脏件**） |
| — | **我推翻的话** | **`none`** —— 我测到的 `t14` 每一条声称**逐格复现**（只记两处**点读数**随并发写者增长，见 §4-N6） |

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 构件与基线
```bash
cd $N && git show --numstat --format='%H %P %cI' e6b25b7
cd $N && git show --numstat --format='%h %cI %s' 72d78b8
cd $N && git show --numstat --format='' e6b25b7 | awk '{print $3}' | grep -v 'P1-w1-verify.md' | while read f; do printf '%s  %s\n' "$(sha256sum "$f" | cut -c1-16)" "$f"; done
cd $N && git show --numstat --format='' e6b25b7 | awk '{print $3}' | grep -v 'P1-w1-verify.md' | xargs stat -c '%y  %n' | sort
# 改前基线（t14 声称值，我用 git 独立现取）
for p in build/MilBridge/tools/pkg-src-retiredpath-check.sh build/MilBridge/repo-alias-allow.tsv build/MilBridge/tools/pts-pages-guard.sh build/MilBridge/tests/PtsPagesProbe/session_inner.sh; do printf '%s %s\n' "$(git show e6b25b7^:$p | sha256sum | cut -c1-16)" "$p"; done
```

### 1.2 腿 ①（退役路径）
```bash
L=~/wv83y; mkdir -p $L/l1/build/probe $L/l1/tests $L/l1/src
printf '// probe\nconst string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";\n' > $L/l1/build/probe/Foo.cs
bash $N/build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree --root $L/l1 --provenance $L/l1/none
# 对照：同箱只去掉该行
mkdir -p $L/l1b/build/probe $L/l1b/tests $L/l1b/src
printf '// probe\nconst string Root = "$HOME/netTest/wpf-linux/wpf-linux";\n' > $L/l1b/build/probe/Foo.cs
bash $N/build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree --root $L/l1b --provenance $L/l1b/none
# 空语料边 / 缺目录边
mkdir -p $L/l1c/build $L/l1c/tests $L/l1c/src && bash … --tree --root $L/l1c --provenance $L/l1c/none
mkdir -p $L/l1d/build/probe && bash … --tree --root $L/l1d --provenance $L/l1d/none
# 正极（真树）
cd $N && bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree 2>&1 | tail -1
# 我按同一 corpus 规则复算 files=
{ find . -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.cs' \); find build tests src -type f \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' -o -name '*.cs' \); } 2>/dev/null | sed 's|^\./||' | grep -vE '\.md$|\.txt$|\.log$|\.json$|\.tsv$|\.csv$|\.png$|\.jpg$|\.pyc$|\.so$|\.dll$' | grep -vE '/upstream/|/\.git/|/\.artifacts/|/obj/|/bin/|/gen/|/__pycache__/' > $L/corpus.txt
wc -l < $L/corpus.txt ; grep -vc '^build/MilBridge/tools/pkg-src-retiredpath-check.sh$' $L/corpus.txt
# 老树面（不含 *.cs）反推
find build tests src -type f \( -name '*.sh' -o -name '*.py' -o -name '*.c' -o -name '*.h' \) 2>/dev/null | wc -l
```

### 1.3 腿 ②（白名单上限）
```bash
mkdir -p $L/l2r/sub $L/l2x/negrepo
printf 'alpha\n' > $L/l2r/sub/a.txt; printf 'beta\n' > $L/l2r/sub/b.txt
ln $L/l2r/sub/a.txt $L/l2x/negrepo/a.txt; ln $L/l2r/sub/b.txt $L/l2x/negrepo/b.txt   # 夹具＝**真硬链接**（被测牙判定对象就是硬链接孪生）
stat -c '%h %n' $L/l2x/negrepo/*.txt
printf '/home/links-dev/wv83y/l2x/negrepo\t1\tfixture\n' > $L/allow1.tsv
printf '/home/links-dev/wv83y/l2x/negrepo\t2\tfixture\n' > $L/allow2.tsv
cd $N && bash build/MilBridge/tools/repo-alias-check.sh --root $L/l2r --roots $L/l2x --maxdepth 3 --allow $L/allow1.tsv --tsv $L/m1.tsv   # 期望 FAIL allowed-tree-grown
cd $N && bash build/MilBridge/tools/repo-alias-check.sh --root $L/l2r --roots $L/l2x --maxdepth 3 --allow $L/allow2.tsv --tsv $L/m2.tsv   # 期望 PASS known-alias-trees
cd $N && bash build/MilBridge/tools/repo-alias-check.sh --root $L/l2r --roots $L/l2x --maxdepth 3 --tsv $L/m3.tsv                        # 期望 FAIL out-of-repo-alias
cd $N && bash build/MilBridge/tools/repo-alias-check.sh --allow build/MilBridge/repo-alias-allow.tsv --tsv $L/m4.tsv                     # 真树
```

### 1.4 腿 ③（显示号占用）
```bash
mkdir -p $L/l3/x11free $L/l3/x11ocup $L/l3/emptywork
python3 -c "import socket,os;s=socket.socket(socket.AF_UNIX);s.bind(os.path.expanduser('~/wv83y/l3/x11ocup/X237'));s.listen(1)"
# 反极（沙箱占用）
WPF_X11_DIR=$L/l3/x11ocup W67_WORK=$L/l3/emptywork W67_DISPLAY=:237 bash build/MilBridge/tests/PtsPagesProbe/session_inner.sh v83 0
# 正极（空闲；W67_WORK 指空沙箱 ⇒ 不进应用）
WPF_X11_DIR=$L/l3/x11free W67_WORK=$L/l3/emptywork W67_DISPLAY=:237 bash build/MilBridge/tests/PtsPagesProbe/session_inner.sh v83 0
# **真显示位腿**（默认 /tmp/.X11-unix，现取 X237 存在）
W67_WORK=$L/l3/emptywork W67_DISPLAY=:237 bash build/MilBridge/tests/PtsPagesProbe/session_inner.sh v83 0
ls -l /tmp/.X11-unix/
```

### 1.5 腿 ④（G10 具名）
```bash
cp -a $N/build/MilBridge/tests/PtsPagesProbe/evidence/. $L/l4/
cd $N && bash build/MilBridge/tools/pts-pages-guard.sh --legs $L/l4            # 正极
sed -i 's/entry=LoCreateContext/entry=CreateInstalledObjectsInfo/g' $L/l4/app_g1.log
cd $N && bash build/MilBridge/tools/pts-pages-guard.sh --legs $L/l4            # 反极
cd $N && bash build/MilBridge/tools/pts-pages-guard.sh --selftest 2>&1 | tail -1
cd $N && bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --selftest 2>&1 | tail -1
```

### 1.6 顺序反事实
```bash
mkdir -p $L/ord/build $L/ord/tests $L/ord/src
for f in $(cd $N && git show --numstat --format='' e6b25b7 | awk '{print $3}' | grep '\.cs$'); do mkdir -p "$L/ord/$(dirname $f)"; (cd $N && git show e6b25b7^:"$f") > "$L/ord/$f"; done
bash $N/build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree --root $L/ord --provenance $L/ord/none 2>&1 | tail -3
bash $N/build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree --root $L/ord --provenance $L/ord/none 2>&1 | grep -c 'rule=code-retired-path'
```

### 1.7 指纹／覆盖面／退役残留／两牙／越域
```bash
cd $N && bash ~/w153a/bin/infp.sh fp && bash ~/w153a/bin/infp.sh list > $L/listA.txt && wc -l < $L/listA.txt
cd $N && grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh
cd $N && bash build/MilBridge/tools/fp-manifest-step.sh --expect 226 2>&1 | tail -3
for f in $(git show --numstat --format='' e6b25b7 | awk '{print $3}' | grep -v 'P1-w1-verify.md'); do printf '%s\n' "$(grep -cF "$f" $L/listA.txt) $f"; done
cd $N && git ls-files '*.cs' | xargs grep -l 'wpf-linux-20260906' 2>/dev/null | wc -l
cd $N && grep -rn 'wpf-linux-20260906' --include='*.cs' --include='*.sh' --include='*.py' build/MilBridge build/DirectWrite.Linux 2>/dev/null
cd $N && grep -rn 'wpf-linux-20260906' build/MilBridge/tests build/DirectWrite.Linux 2>/dev/null | awk -F: '{print $1}' | sed 's/.*\.//' | sort | uniq -c | sort -rn
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | tail -1 && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -2
cd $N && git status --porcelain && flock -n ~/heavy.lock -c 'echo SLOT=FREE' || echo SLOT=HELD
```

---

## §2 逐格对照表（左＝我自算，右＝`t14` 声称）

### 2-1 腿 ①（`.cs` 塞回 ⇒ 必红点名）

| 腿 | 我现取的原始机读行 | `rc` | `t14` 声称 | 判 |
|---|---|---|---|---|
| **①-A 反极**（沙箱 `.cs` 第 `2` 行含针） | `RETIREDPATH=FAIL` ＋ `  build/probe/Foo.cs:2 kind=code rule=code-retired-path` ＋ `RETIREDPATH_SCAN mode=tree files=1 hits=1 code=1 declared=0 self_skip=0 needle=wpf-linux-20260906` | `1` | 同（`build/probe/Foo.cs:2 kind=code rule=code-retired-path`） | ✓ **file＋line 双点名** |
| **①-B 对照**（同箱、只去掉该行） | `RETIREDPATH=PASS mode=tree files=1 hits=0 code=0 declared=0 self_skip=0 needle=…` | `0` | —（我加的成对对照） | ✓ 唯一变量＝那一行 |
| **①-C 空语料边** | `RETIREDPATH=NOINFO reason=empty-corpus mode=tree` | `3` | 同（`NOINFO reason=empty-corpus rc=3`） | ✓ **零语料不当绿** |
| **①-D 缺目录边**（我的仪器观察） | `RETIREDPATH=NOINFO reason=no-paths-file path=` | `3` | 未报 | ⚠️ **`reason` 误导**（见 §5-W2） |
| **正极（真树）** | `RETIREDPATH=PASS mode=tree **files=565** hits=3 code=0 declared=3 self_skip=1 needle=wpf-linux-20260906` | `0` | `files=229 → 565` | ✓ **域真变了**（不是只改打印） |
| 我按同一 corpus 规则复算 `files` | 我的清单 `566` 行；**减去牙自身（`self_skip=1`）＝ `565`** ⇒ **逐位相符** | — | — | ✓ |
| 老树面反推 | `find build tests src -type f \( '*.sh' -o '*.py' -o '*.c' -o '*.h' \)` ⇒ **`229`** | — | `改前 files=229` | ✓ 改前值亦复现 |
| `--selftest` | `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0` | `0` | `8/8` | ✓ |

### 2-2 腿 ②（白名单上限）

| 腿 | 我现取的原始机读行 | `rc` | `t14` 声称 | 判 |
|---|---|---|---|---|
| **②-A 上限 `1`（孪生 `2`）** | `ALIAS=FAIL examined=2 linked_gt1=2 aliased_out=2 aliased_allowed=2 aliased_unallowed=0 roots=1 maxdepth=3 wall_s=0.00 rc=1 **reason=allowed-tree-grown**` | `1` | `上限 1 ⇒ FAIL … rc=1 reason=allowed-tree-grown` | ✓ |
| **②-B 上限 `2`** | `ALIAS=PASS … aliased_allowed=2 aliased_unallowed=0 … rc=0 **reason=known-alias-trees**` | `0` | `上限 2 ⇒ PASS … rc=0` | ✓ |
| **②-C 无白名单** | `ALIAS=FAIL examined=2 linked_gt1=2 aliased_out=2 aliased_allowed=0 **aliased_unallowed=2** rc=1 **reason=out-of-repo-alias**` | `1` | `无白名单 ⇒ FAIL … aliased_unallowed=2 rc=1 reason=out-of-repo-alias` | ✓ |
| **②-D 真树（现取）** | `ALIAS=PASS **examined=18123** linked_gt1=0 aliased_out=0 aliased_allowed=0 aliased_unallowed=0 roots=1 maxdepth=16 wall_s=7.17 rc=0 **reason=no-out-of-repo-alias**` | `0` | `examined=18075 … wall_s=12.06`（其读时） | ✓（`examined`/`wall_s` 是**点读数**，见 §4-N6） |
| 夹具保真 | 孪生 `%h` ⇒ `2 /home/links-dev/wv83y/l2x/negrepo/a.txt`、`2 …/b.txt`（**真硬链接**；被测牙的判定对象就是它） | — | — | ✓ |
| **被比量** | 三腿互证 ⇒ **比的是「该前缀下的孪生计数」**，不是该树物理件数 | — | 同 | ✓ |

### 2-3 腿 ③（显示号占用 ⇒ 拒跑）

| 腿 | 我现取的原始机读行 | `rc` | `t14` 声称 | 判 |
|---|---|---|---|---|
| **③-A 反极（沙箱占住 `:237`）** | `DISPLAY_OCCUPIED=:237 sock=/home/links-dev/wv83y/l3/x11ocup/X237 ⇒ 拒跑（号已被占；请用 W67_DISPLAY=<空闲号> 或先按 PID 收净）` | **`3`** | `DISPLAY_OCCUPIED… rc=3 拒跑` | ✓ **非零 rc ＋ 具名拒跑** |
| **③-B 正极（号空闲）** | `DISPLAY_LEASE=free display=:237 sock=/home/links-dev/wv83y/l3/x11free/X237` ＋ `G1 MISSING-SHIM …/emptywork/dlls/0.libwpfwin32.so` ＋ `ALL_GROUPS_DONE` | `0` | `正极 DISPLAY_LEASE=free` | ✓（自证行在位；**未进应用** —— `W67_WORK` 指空沙箱，`MISSING-SHIM` 即短路） |
| **③-C 真显示位腿（我加的）** | 默认 `WPF_X11_DIR=/tmp/.X11-unix`：`DISPLAY_OCCUPIED=:237 sock=**/tmp/.X11-unix/X237** ⇒ 拒跑` | **`3`** | `真 :237 腿＝NOINFO(heavy-slot 被占)` | ✓ **我把它从 `NOINFO` 抬成真读数**（现取 `ls -l /tmp/.X11-unix/` ⇒ `X237`／`X238` 在，`X237` 为 `srwxrwxrwx`） —— 该腿**不需要槽**（拒跑发生在任何应用动作之前） |

### 2-4 腿 ④（G10 具名 ⇔ 现取前沿）

| 腿 | 我现取的原始机读行 | `rc` | `t14` 声称 | 判 |
|---|---|---|---|---|
| **④ 正极（原证据）** | `PTS_G10_NAME=PASS header=LoCreateContext observed=LoCreateContext` ＋ `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded` | `0` | 同 | ✓ |
| **④ 反极（沙箱日志前沿名改回旧名）** | `PTS_G10_NAME=FAIL header=LoCreateContext observed=CreateInstalledObjectsInfo（件头具名与现取前沿不一致 ⇒ 红并点名）` | `1` | 同（`FAIL` 点名 `rc=1`） | ✓ |
| `--selftest` | `PTS_GUARD_SELFTEST=PASS pass=24 fail=0` | `0` | `24/24` | ✓ |
| B-8 ① 口径句入件 | `grep -c '零证据力' build/MilBridge/tools/pts-pages-guard.sh` ⇒ **`1`** | — | `零证据力 0 → 1` | ✓ |

### 2-5 顺序证据（**先 `.cs` 后牙**）

**证据 A（`mtime` 序列，现取 `stat -c '%y %n'`，按时间排序）**：

| 时刻 | 件 |
|---|---|
| `16:02:35.200243679` | `build/MilBridge/P1-w2-criteria.md`（判据件，先写） |
| **`16:03:11.794280077` – `16:03:11.807280091`** | **`9` 件 `.cs`**（`T2eLineHeight`／`PcLineOracle`／`CoverageProbe`／`FrameProbe`／`ResolverGuardProbe`／`BboxProbe`／`LsProbe`／`IcuBreakParity`／`WicSeamProbe`） |
| **`16:03:21.506290010`** | **`build/MilBridge/tools/pkg-src-retiredpath-check.sh`（＝牙）** |
| `16:04:55.160391093` | `build/MilBridge/repo-alias-allow.tsv` |
| `16:05:02.986399944`／`.991399950` | `build/MilBridge/tools/pts-pages-guard.sh`／`tests/PtsPagesProbe/session_inner.sh` |
| `16:06:25.969497220` | `build/MilBridge/P1-w2-report.md` |

⇒ **`.cs`（`16:03:11`）严格早于牙（`16:03:21`）约 `9.7 s`** ✓（不是"报告叙述"，是 `stat` 现取）

**证据 B（反事实，我自己造的沙箱）**：把 `e6b25b7^` 的 **9 件 `.cs`** 还原进沙箱，用**改后的新牙**扫 ⇒
```
  build/MilBridge/tests/IcuBreakParity/Program.cs:62 kind=code rule=code-retired-path
  build/DirectWrite.Linux/WicSeamProbe/Program.cs:15 kind=code rule=code-retired-path
RETIREDPATH=FAIL
RETIREDPATH_SCAN mode=tree files=9 hits=12 code=12 declared=0 self_skip=0 needle=wpf-linux-20260906
rc=1     （`grep -c 'rule=code-retired-path'` ⇒ 12）
```
⇒ **若先扩域，这 9 件当场判红**（`files=9 hits=12 code=12`，与 `t14`/侦察的读数**逐格相同**）⇒「先 `.cs` 后牙」**必要**，且与证据 A 的先后一致 ✓。

### 2-6 覆盖面／指纹位移逐件归因

| 量 | 入口（`#80` 冻值／`t14` 改前） | 出口（现取） | 判 |
|---|---|---|---|
| `inputs_fp` | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`（我另证：该值**逐字**等于 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 里的冻结值） | **`e9f95ec005715b3a7bff1a7bca4b525fafad98068e7a389ad8b9b91b8a9dc5a3`** | **位移成立**（与 `t14` 报的出口值逐位相同） |
| 覆盖面件数 | `226` | **`226`** | **不变** |
| `[42] --expect` | `226` | `226`（`verify-all.sh:1195`，`grep -n 'run_step "FP-MANIFEST-TEETH"'` 现取） | **未改 ⇒ 也无需改** |
| `[42]` 现跑 | — | `FP_MANIFEST_TEETH=PASS reason=ok files_n=226 files_n_uniq=226 blank_n=0 declared_expect=226`／`FP_MANIFEST_STEP_RC=0` | ✓ **无 `files-n-mismatch`** |

**逐件归因（`grep -cF <件> ~/w153a/bin/infp.sh list`，逐行现取）**：

| 件 | `inFP` |
|---|---|
| `build/MilBridge/repo-alias-allow.tsv` | **1** |
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | **1** |
| `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | **1** |
| `build/MilBridge/tools/pts-pages-guard.sh` | **1** |
| 其余 `11` 件（`9 .cs` ＋ `P1-w2-criteria.md` ＋ `P1-w2-report.md`） | **0** |

⇒ **`inFP=1` 恰 `4` 件 ＝ 位移的全部动因**；`9 .cs` **不在覆盖面** ⇒ **件数不变（`226`）** ✓ ⇒ 与 `t14` 的归因**逐件相同**。

### 2-7 退役路径零残留（逐类点名）

| 范围 | 我现取 | 判 |
|---|---|---|
| `git ls-files '*.cs' \| xargs grep -l 'wpf-linux-20260906'` | **`0` 件**（`wc -l` ＝ 0） | ✓ 侦察 `B-3` 判据①满足 |
| 验收 scope：`--include='*.cs' --include='*.sh' --include='*.py'` ×（`build/MilBridge`＋`build/DirectWrite.Linux`） | **`5` 行，全在 `build/MilBridge/tools/pkg-src-retiredpath-check.sh`**：`:7`（件头文档）、**`:59`（`RETIRED_NEEDLE='wpf-linux-20260906'` ＝ 针的定义）**、`:241`／`:246`／`:255`（`--selftest` 的**夹具 `printf`**） | ✓ **针＋自测夹具**，被牙 `self_skip=1` 跳过；**非残留** |
| 同目录全类（不加 include） | `2022` 行 ⇒ 按扩展名：`txt 1684`／`json 282`／`editorconfig 27`／`cache 22`／`md 5`／`c 2` | ✓ **全在证据/台账/产物面**（牙的设计即"报告/日志/台账/产物一律不判 —— 那是历史事实，改了就是篡改证据"）；其中 `.c` 2 处正是被 `RETIREDPATH_DECLARED kind=code-evidence-source … registered=D-G151` 具名的那两个探针 |
| 真树正极的 `hits=3 declared=3 code=0` | 与上一致（`code=0` ＝ **无未声明的可执行行命中**） | ✓ |

### 2-8 `B-3` 修法形态（`9` 件 `.cs`）

| 检查 | 我现取 | 判 |
|---|---|---|
| 旧形 `const string … Root =`（内嵌退役树） | `9` 件**全部 `0` 处** | ✓ |
| 新形（env 注入 ＋ 缺则响亮失败） | `9` 件均有 `Environment.GetEnvironmentVariable`；`T2eLineHeight:24-25` ＝ `Environment.GetEnvironmentVariable("WPF_PROBE_T2E_ROOT") ?? throw new InvalidOperationException("死根已清：未设 …")`；`BboxProbe:24-25` 同形 | ✓ |
| `--selftest` 两件 | `RETIREDPATH_SELFTEST=PASS cases=8 pass=8 fail=0`／`PTS_GUARD_SELFTEST=PASS pass=24 fail=0` | ✓ |
| 改前基线（`git` 独立现取，非抄报告） | 牙 `d54a5a14c1934bac`／白名单 `5813863882022812`／guard `bfa6414eb7104f85`／session `f687ad65fd05f6e2` —— **四格与 `t14`／侦察的「改前」值逐位相同** | ✓ |
| **改后逐件 sha16** | 我现取 15 件（§3 表）—— **`t14` 报告未逐件列改后 sha16** | ⚠️ 该格 `NOINFO(写者未给)`，由我补（§5-W1） |

### 2-9 `B-7` 量名口径

| 量 | 我现取 | `t14` 声称 | 判 |
|---|---|---|---|
| 孪生计数（牙的被比量） | `linked_gt1=0`（真树） | `现取孪生 ＝ 0` | ✓ |
| `find /home/links-dev/w62a/negrepo -type f \| wc -l` | **`12918`** | `12918` | ✓ **物理件数 ≠ 孪生计数**（侦察写「现取 `0` 件」只对孪生计数成立）—— `t14` **已如实具名**该歧义 ✓ |
| 白名单件实体 | `build/MilBridge/repo-alias-allow.tsv` 数据行仍 `6417` ＋ `t14` 的 dated 现取补注（`8/0` 新增） | 保留该行 ＋ 补注 | ✓ |

### 2-10 两牙与越域

| 项 | 我现取 | 判 |
|---|---|---|
| `DEFREG` | `DEFREG=PASS declared=215 route_ids=215` | ✓ 未退化 |
| `REPORTID` | `REPORTID=PASS files=194 ids=2042 declared=215`（`declared` 未变） | ✓ 未退化（`files/ids` 是**点读数**，见 §4-N6） |
| `porcelain` 逐行归属 | ` M build/MilBridge/HANDOFF-NEXT.md`／` M build/MilBridge/P1-dg179-report.md`／` M build/MilBridge/tools/defect-registry-declared.tsv`／` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`?? build/MilBridge/P1-task0201-criteria.md` —— **逐件核对 `e6b25b7` 的 `numstat`：一件都不在其中** | ✓ **`t14` 名下零脏件** |
| 并发写者的独立证据 | `declared.tsv` 的 diff 现取 **只 `1` 行**（`# DECL-GEN = (--emit) … 16:10:28`，`# DECL-ANCHORS` 逐字未变）；`P1-dg179-report.md` mtime `16:10:48`、`P1-w1-report.md` mtime `16:08:26` | ✓ 均为**并发写者**（**不计入 `t14`**） |
| 未 add/commit/push | 暂存区 **`0` 行**（`git diff --cached --numstat` 现取空）；`HEAD` 仍 `72d78b8`（我开工值） | ✓ |
| 槽 | `flock -n ~/heavy.lock` ⇒ **`SLOT=HELD`**；`~/w281-scribe/slot-probe.log` 现取 `69 B`／`HEAVYSLOT=TIMEOUT waited=5s cmd=… slot_rc=9` | ✓ `t14` 的 `NOINFO(heavy-slot 被占)` **读数属实**（**未当腿**） |

---

## §3 我现取的 `t14` 15 件 sha16（补 `t14` 未给的「改后」格）

| # | 件 | 我现取 sha16 | `inFP` |
|---|---|---|---|
| 1 | `build/DirectWrite.Linux/WicSeamProbe/Program.cs` | `b36728870f822a23` | 0 |
| 2 | `build/MilBridge/tests/BboxProbe/Program.cs` | `2001427e88b7f709` | 0 |
| 3 | `build/MilBridge/tests/CoverageProbe/Program.cs` | `c78ed88fc1fd34f4` | 0 |
| 4 | `build/MilBridge/tests/FrameProbe/Program.cs` | `b6d00269cf6f6aad` | 0 |
| 5 | `build/MilBridge/tests/IcuBreakParity/Program.cs` | `52f0ab739aaacf3b` | 0 |
| 6 | `build/MilBridge/tests/LsProbe/Program.cs` | `f536e535d6903227` | 0 |
| 7 | `build/MilBridge/tests/PcLineOracle/Program.cs` | `a23b7476833da140` | 0 |
| 8 | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | `ca6f1bea560f2326` | 0 |
| 9 | `build/MilBridge/tests/T2eLineHeight/Program.cs` | `1f719638830afdde` | 0 |
| 10 | `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `a70aeb1d988ebc9e` | **1** |
| 11 | `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `60009734108344bd` | **1** |
| 12 | `build/MilBridge/tools/pts-pages-guard.sh` | `7074a774739efaf2` | **1** |
| 13 | `build/MilBridge/repo-alias-allow.tsv` | `19496f3615ccb45a` | **1** |
| 14 | `build/MilBridge/P1-w2-criteria.md`（新建） | `ceecddcccda8521f` | 0 |
| 15 | `build/MilBridge/P1-w2-report.md`（新建） | `80e1583d2680b382` | 0 |

`t14` 自报送载体：`P1-w2-report.md` `head -n -1` ＝ **`e37f0270a525e815`** ／ `136` 行 ⇒ **我现算逐位相同** ✓；`P1-w2-criteria.md` ＝ `ceecddcccda8521f` ⇒ **逐位相同** ✓。
**未动件**（现取）：`verify-all.sh 600274f130cfe913`｜`build/close-wave.sh f9a2ee3ee35baff8` —— `git status --porcelain -- <这两件>` 现取**为空** ✓。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | `B-3`②`CoverageProbe` **三支臂**（重活 ＋ 显示位） | **`NOINFO(reason=heavy-slot 被占)`** | 现取 `flock -n ~/heavy.lock` ⇒ `SLOT=HELD`；`slot-probe.log` 现取 `HEAVYSLOT=TIMEOUT waited=5s slot_rc=9`。我**未**取得槽、**未**把它当读数；`t14` 自报的同一 `NOINFO` **读数属实**。 |
| N2 | `B-9` 的**真 `:237` 跑腿**（起真应用） | **`NOINFO`（未做，`=不许跑应用` 的边界）** | 我**只**做了拒跑那一侧（③-C，真 `/tmp/.X11-unix/X237` 在 ⇒ `rc=3`）。"号空闲＋真起应用"不在本件边界（不跑应用/显示位）⇒ 不判。 |
| N3 | `t14` 报告**未逐件列改后 sha16** | **`NOINFO(写者未给)`** | 我通读其 `136` 行：只有「改前」两格（牙、白名单）＋自报载体两格；13 件改后值得由我补（§3 全表）。**不影响判词**（我的值就是现取值）。 |
| N4 | 契约 `inScope` 写的 `build/MilBridge/tools/retired-path-provenance.tsv` | **不存在**（真件在 `build/MilBridge/`） | 我现取：`tools/` 下**无**该件；`build/MilBridge/retired-path-provenance.tsv` 在（`2200 B`，mtime `2026-09-27 11:51:43`，`git log` 末笔 `6a245bd`）⇒ **`t14` 未新建/未改它**（不在其 `numstat`）。**`t14` 已在报告 §2 如实点名该路径不符** ✓ ⇒ 属**侦察件 §4 W2 行**的路径错（见 §5-W3）。 |
| N5 | 牙的 `reason=no-paths-file` 语义 | 已核（非 `NOINFO`） | 见 §5-W2：`tree` 模式下任一 `build`/`tests`/`src` 缺失即报此 reason（**预存在**行为，`t14` 只改了那两行 `find`）。 |
| N6 | `examined`／`wall_s`／`REPORTID files/ids` 等**点读数** | 已核（非 `NOINFO`） | 它们随并发写者**增长**：`examined` `18075`（`t14` 读时）→ `18115` → `18123`（我读）；`REPORTID` `194/2036`（`t13` 收尾）→ **`194/2042`** ⇒ `+6 ids` 的动因我逐件现取：`P1-dg179-report.md` mtime **`16:10:48`** 与 `P1-w1-report.md` mtime **`16:08:26`** 被**再次编辑**（**非 `t14`**：其 `numstat` 无这两件）⇒ **不计入 `t14`**，也不判不一致。 |
| N7 | 未跑门禁/构建 | **未做（派单边界明写）** | 我**跑过的唯一门禁相关件**是 `[42] FP-MANIFEST-TEETH` 的**独立步**（`fp-manifest-step.sh --expect 226`，纯读＋计数，秒级）——目的是核「漏改 `--expect` ⇒ `files-n-mismatch`」这一条，**不是**跑 `verify-all.sh`。 |

---

## §5 我点名的具名差异（均不改结论；**我推翻的话 ＝ `none`**）

### W1（low）：`t14` 报告未逐件列 13 件改后 sha16
- 我通读 `build/MilBridge/P1-w2-report.md`（`80e1583d2680b382`／`136` 行）**现取**：其 `sha16` 只出现在 ① 改前两格（牙 `d54a5a14c1934bac`、白名单 `5813863882022812`）② 自报载体两格。**13 件改后值缺**。
- ⇒ 本仓惯例题级交接要「件＋字段＋sha16」；建议由写者**dated 追加**一张 15 件表（我已给现取值，见 §3）。

### W2（low，**预存在**、非 `t14` 引入）：牙的 `reason=no-paths-file` 在 `tree` 模式下**语义误导**
- 我现取：沙箱 `--tree --root` 指向一个**只缺 `tests/`／`src/` 子目录**（但语料非空、含 `build/probe/Foo.cs`）的根 ⇒ 报 `RETIREDPATH=NOINFO reason=no-paths-file path=`。
- 机制：`collect_corpus()` 的 `tree` 分支最后一条 `find "$ROOT/build" "$ROOT/tests" "$ROOT/src" …` 在**任一目录缺失**时 `find` 返回非零 ⇒ 整个函数返回非零 ⇒ 判词把原因写成「缺 paths-file」（**`path=` 还是空的**）。
- ⇒ 三态（`NOINFO`）**方向正确**（算不出不给绿），但 **reason 指错方向**（`D-G104` 同族：读数器输出语义被读错）。`t14` 只改了那两行 `-name`，**未引入**本行为；建议另立条目、改 reason 为「corpus-unreadable（缺 build/tests/src）」。

### W3（low，侦察件）：`P1-tail-scout.md §4 W2` 行的 `retired-path-provenance.tsv` **路径写错**
- 侦察写 `build/MilBridge/**tools/**retired-path-provenance.tsv`；我现取该路径**不存在**，真件是 `build/MilBridge/retired-path-provenance.tsv`（`2200 B`）。
- ⇒ `t14` **已如实点名**（其报告 §2 末段）⇒ **未被静默**；但侦察件在册，建议 dated 更正（否则后续波会照抄错路径）。

### 具名不对拍（不判假）
| # | 句 | 现取 | 说明 |
|---|---|---|---|
| ①' | `t14` 报告「真树 `ALIAS=PASS examined=18075 … wall_s=12.06`」 | 我现取 `examined=18115/18123`／`wall_s=7.17/7.50` | **点读数**：期间仓内件被并发写者增加（`examined` 单调增）⇒ 不判不一致 |
| ②' | `t14` 报告「`REPORTID=PASS files=… ids=…`」 | 我现取 `194/2042` | 同上（§4-N6 逐件归因） |

---

## §6 我的自伤与更正（如实记）

1. **首轮腿 ① 空转**：我第一版沙箱**只建了 `build/`**，`--tree` 当场给 `NOINFO reason=no-paths-file`（`rc=3`）——**反极腿根本没被判**。若就此收工会把「反极腿没跑」当成「反极腿没红」。**当场发现**并补齐 `tests/`／`src/` 两个空目录后重跑，才拿到 `FAIL ＋ build/probe/Foo.cs:2` ✓（该"坑"反过来成了 §5-W2 的发现）。
2. **`.cs` 零残留的两种口径**：我先用**不带 include** 的 `grep -rn` 扫 `build/MilBridge/tests build/DirectWrite.Linux` ⇒ 得 **`2022`**，若直接写出去就是**假红**。**当场**按扩展名分解（`txt 1684`／`json 282`／…）并改用验收给的 `--include` 三项 ⇒ **`5` 行且全在牙自身**，另用 `git ls-files '*.cs'` 独立得 **`0`**。
3. **`ln` 的使用说明**：腿 ② 的夹具必须造**真硬链接**（被比量就是硬链接孪生计数），我在**自己车道** `~/wv83y/l2x/` 用 `ln` 造了 `2` 对（`%h=2`）；**未**用 `cp -al`、未在任何仓内路径造链接。

---

## §7 收尾

- `$N` 内我**只写本件**；`t14` 的 15 件／两颗牙／`verify-all.sh`／`build/close-wave.sh`／`docs/ROUTES.md` **一字未动**（§3 表 ＋ §2-10 的 `git status --porcelain -- <件>` 为空）。
- 沙箱与夹具全在 `~/wv83y/`（**不落 `/tmp`**，唯一例外是**只读**查看 `/tmp/.X11-unix/`）；未跑门禁/构建/应用/显示位；未 `git add/commit/push`。
- ⏪ **追加（本件落盘之后 `16:12:0x` 现取，只补不删）**：① `porcelain` 现为 **`6`** 行 ＝ 上表 `5` 行 ＋ `?? build/MilBridge/P1-w2-verify.md`（**本件自身**）⇒ **`t14` 名下仍为零脏件**，越域结论不变。
- ⏪ **追加（同上）② 契约 `Verify` 三条原样现跑**：`wc -l` ＝ **`321`**；`sha256sum | cut -c1-16` ＝ **`d88246d26d55a198`**；`infp.sh fp` ⇒ **`e9f95ec005715b3a7bff1a7bca4b525fafad98068e7a389ad8b9b91b8a9dc5a3`**；`infp.sh list | wc -l` ⇒ **`226`**；`grep -n 'FP-MANIFEST-TEETH' verify-all.sh | tail -2` ⇒ `:1195 run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 226`（`--expect` **未动**）；`grep -rn 'wpf-linux-20260906' --include='*.cs' --include='*.sh' --include='*.py' build/MilBridge build/DirectWrite.Linux | wc -l` ⇒ **`5`**（**全部落在牙自身**：针 `:59` ＋ 件头 `:7` ＋ 自测夹具 `:241/:246/:255` —— 逐行清单见 §2-7）。
- ⏪ **追加（同上）③**：`[42]` 独立现跑 ⇒ `FP_MANIFEST_TEETH=PASS reason=ok files_n=226 files_n_uniq=226 blank_n=0 declared_expect=226`／`FP_MANIFEST_STEP_RC=0` ⇒ **无 `files-n-mismatch`**。

- **判词尾行**：`P1-W2-VERIFY: legs4=[RETIREDPATH FAIL+file:line ok,REPO_ALIAS cap-grown ok,DISPLAY_OCCUPIED rc=3 ok(real /tmp/.X11-unix/X237 also),PTS_G10_NAME FAIL ok] order=[mtime .cs 16:03:11 < tooth 16:03:21; counterfactual files=9 hits=12 code=12] fp=[abc76bd55->e9f95ec005715b3a 226->226 expect=226 step PASS] residue=[.cs=0, scope5 all-in-tooth, rest all-evidence] selftests=[8/8,24/24] t14dirty=0 overturned=none NOINFO=7`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `af6272d41c25fe20` ／ FULL `af6272d41c25fe2040fb0fc4551d6b8777dc9870a3956719e298d84ee3947d43` ／ `wc -l` ＝ 324 行（**不含**本行）／末次读取时刻 `2026-09-28T16:12:0x+08:00`／写入方式 **temp ＋ rename**。
