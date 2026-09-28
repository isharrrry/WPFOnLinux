# P1-w2-close-verify —— `t25`（W1／W2／W3 关账）**独立复核判词**（`verifier` / `t26`）

- **被核交件**：`t25`（成员 `scribe`）的交件 —— 提交 **`18617a1734111920253900640f540a04e236d79f`**（`%cI = 2026-09-28T16:23:33.000000000+08:00`（`%cI` 秒级），父 `0f12688029eef53f1b8a99db593c27c743400a22`）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜我开工 `HEAD=1b9002b`（`16:24:47`）；**收尾仍 `1b9002b`**。
- **逐条读取时刻（**亚秒**，本仓 P1 复核面要求）**：开工 `2026-09-28T16:24:52.396908543+08:00`｜W1 逐件现取 `16:25:11.851401487+08:00`｜覆盖面孔 `16:25:56.820984180+08:00`｜收尾 `16:26:25.081757699+08:00`（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-w2-close-verify.md`）＝我唯一写入的件。沙箱/夹具在 `~/wv87y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/整波/应用；未 `git add/commit/push`。**不复述** `t25` 的结论 —— 每条我自己现取、**每个极化我自己造夹具重跑**（我也**没有**引用我上一件 `t15` 的输出当证据：那张表我从 `git show 7bad6ba:` **现取**后逐行比）。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | **W1**：15 件 sha16 全表自算对拍 | **成立**（13/15 **逐位**相符；另 2 格现取不符 —— 第 `15` 行**块内已显式声明**自指口径 ✓、第 `11` 行**未声明** ⇒ **V1（low）**）；与我 `t15` §3 表**15 格逐位相同** ✓ |
| 2 | **W2 `D-G182`**：立号占用 ＋ 条目体例 ＋ 发现/配号如实记 | **成立**（四件 route 件 pre **全 `0`** → KD `1`；改前 `declared` 最大号 **`181`**；标题命中 `1`、**八段齐**；「**由 `t15` 发现、队长配号**」**双处**如实记；无冲突） |
| 3 | **W2 修 ＋ 两极化（我重跑）** | **成立**（四缺法各自点名 `dirs=`；三目录齐＋针 ⇒ `FAIL` 点名 `build/Foo.cs:2`；三目录齐＋非针件 ⇒ `PASS`；**空 `path=` 与 `no-paths-file` 断言 ＝ `0`**；**成对**：改前件同沙箱 ⇒ `NOINFO reason=no-paths-file path=`；`--selftest 11/11`、stderr `0`） |
| 4 | **覆盖面位移逐件归因 ＋ `--expect`** | **成立**（入口 `e9f95ec005715b3a`／`226` → 出口 `8c4ce894d04eae7b`／`226`；`t25` 六件中**只有牙 `in-list=1`**；`--expect 226` **未改**且该步实跑 `PASS files_n=226 declared_expect=226` ⇒ **无 `files-n-mismatch`**） |
| 5 | **W3**：侦察件两处打架 ＋ 以正文为准 ＋ 责任链 | **成立**（两处**逐字点名**；**以正文为准**已写；真件现取 `2200 B`／`mtime 2026-09-27 11:51:43`／`sha16 10d62946231cc809`；`tools/` 下 **ABSENT**；责任链（侦察 §4 → 队长 → `t14` 顶回 → 本席更正）如实记；**两处原文仍在**） |
| 6 | **越域 ＋ 两牙 ＋ 未 add** | **成立**（`t25` 名下**零脏件**；`DEFREG=PASS declared=217 route_ids=217` ＋ `DECLDRIFT=0`；`REPORTID` 增量**逐件归因**；暂存区 `0`） |
| — | **我推翻的话** | **`none`**（三处**口径/器材**需补：V1／V2，见 §3） |

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 W1：15 件 sha16 全表自算
```bash
cd $N && sed -n '137,158p' build/MilBridge/P1-w2-report.md          # 读表（含 inFP 列）
bash ~/w153a/bin/infp.sh list > ~/wv87y/list.txt ; wc -l < ~/wv87y/list.txt
# 我把表逐行抄成 TSV（件 / 表内 sha16 / 表内 inFP），再逐行现取
while IFS=$'\t' read -r f s16 infp; do
  now=$(sha256sum "$f" | cut -c1-16); innow=$(grep -cF "$f" ~/wv87y/list.txt)
  printf '%-52s 表=%s 现取=%s  inFP 表=%s 现=%s\n' "$f" "$s16" "$now" "$infp" "$innow"
done < ~/wv87y/table.tsv
# 与我 t15 §3 表比（**从 git 现取，不引述我自己**）
git show 7bad6ba:build/MilBridge/P1-w2-verify.md | grep -E '^\| 1[45]? \|' | cut -c1-100
```

### 1.2 W2：立号 ＋ 条目 ＋ 极化（**我自己的夹具**）
```bash
cd $N && for f in samples/WpfFeatureProbe/KNOWN-DEFECTS.md docs/CURRENT-STATE.md handoff.md samples/WpfTextDemo/ACCEPTANCE-BASELINE.md; do \
   printf '%-50s pre=%s commit=%s now=%s\n' "$f" "$(git show 18617a1^:$f|grep -c 'D-G182')" "$(git show 18617a1:$f|grep -c 'D-G182')" "$(grep -c 'D-G182' $f)"; done
git show 18617a1^:build/MilBridge/tools/defect-registry-declared.tsv | grep '^ID' | cut -f2 | sed 's/D-G//' | sort -n | tail -1
grep -cE '^#{2,4}.*D-G182' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
grep -nP '^ID\tD-G182\t' build/MilBridge/tools/defect-registry-declared.tsv
# 改前件（git ＋ 备份 双路，先核指纹）
git show 18617a1^:build/MilBridge/tools/pkg-src-retiredpath-check.sh > $T/tooth.pre
sha256sum $T/tooth.pre ; sha256sum ~/w281-scribe/bak/pkg-src-retiredpath-check.sh.pre-t25
# 夹具：只建 X（覆盖四缺法）／三目录齐＋针／三目录齐＋非针／三目录齐＋空
mk() { d=$1; shift; rm -rf $d; for x in "$@"; do mkdir -p $d/$x; done; }
mk $T/f_build build ; mk $T/f_tests tests ; mk $T/f_src src ; mk $T/f_none
mk $T/f_all build tests src ; printf '// probe\nconst string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";\n' > $T/f_all/build/Foo.cs
mk $T/f_clean2 build tests src ; printf '// probe\nconst string Root = "$HOME/netTest/wpf-linux/wpf-linux";\n' > $T/f_clean2/build/Foo.cs
mk $T/f_clean build tests src
for d in f_build f_tests f_src f_none f_all f_clean2 f_clean; do \
  bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree --root $T/$d --provenance $T/none ; echo "rc=$?"; done
bash $T/tooth.pre --tree --root $T/f_build --provenance $T/none ; echo "rc=$?"      # 成对（改前件）
bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --selftest 2>ss.err | tail -1
bash build/MilBridge/tools/pkg-src-retiredpath-check.sh --tree 2>&1 | tail -1        # 真树正极
# 空 path= / no-paths-file 断言（**剥掉判词括注后**判字段）
python3 - <<'PY'
import re
txt=open('/home/links-dev/wv87y/postfix.out',encoding='utf-8').read().split('\n')
strip=[re.sub(r'（[^）]*）','',l) for l in txt if l.startswith('RETIREDPATH=')]
bad=[l[:100] for l in strip for m in re.finditer(r'path=([^\s）)]*)',l) if m.group(1)=='']
print('RETIREDPATH= 行数',len(strip),'剥括注后空 path= 字段',len(bad),'reason=no-paths-file',sum('reason=no-paths-file' in l for l in strip))
PY
```

### 1.3 覆盖面 ＋ `--expect` ＋ 同趟性 ＋ W3 ＋ 两牙
```bash
cd $N && bash ~/w153a/bin/infp.sh fp | cut -c1-16 ; wc -l < ~/wv87y/list.txt
for f in <t25 动的六件>; do printf '%s in-list=%s\n' "$f" "$(grep -cF "$f" ~/wv87y/list.txt)"; done
grep -n 'run_step "FP-MANIFEST-TEETH"' verify-all.sh
bash build/MilBridge/tools/fp-manifest-step.sh --expect 226 2>&1 | tail -2
sed -n '2p' build/MilBridge/tools/defect-registry-declared.tsv | sed 's/.*KD=\([0-9a-f]*\).*/\1/'
sha256sum samples/WpfFeatureProbe/KNOWN-DEFECTS.md | cut -c1-16
sed -n '114p' build/MilBridge/tools/defect-registry-declared.tsv | cat -A
bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG_DECLDRIFT'
stat -c '%n %y' samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/tools/defect-registry-declared.tsv
sed -n '1p' build/MilBridge/tools/defect-registry-declared.tsv
diff <(git show 18617a1^:build/MilBridge/tools/defect-registry-declared.tsv) build/MilBridge/tools/defect-registry-declared.tsv
bash build/MilBridge/tools/defect-registry-check.sh --emit > ~/wv87y/emit.tsv
tail -n +2 build/MilBridge/tools/defect-registry-declared.tsv > a ; tail -n +2 ~/wv87y/emit.tsv > b ; cmp a b
grep -n 'retired-path-provenance' build/MilBridge/P1-tail-scout.md
sed -n '517p' build/MilBridge/P1-tail-scout.md | grep -c 'retired-path-provenance'
sed -n '570,575p' build/MilBridge/P1-tail-scout.md
sha256sum build/MilBridge/retired-path-provenance.tsv | cut -c1-16
bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG='
bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -1
# REPORTID 增量成对归因
cp -a build/MilBridge/*report*.md $S/build/MilBridge/ ; bash … --root $S | tail -1
rm -f $S/build/MilBridge/P1-v-close-report.md ; bash … --root $S | tail -1
git status --porcelain ; git diff --cached --numstat | wc -l
```

---

## §2 逐格对照表

### 2-1 W1：15 件逐件（**现取时刻 `2026-09-28T16:25:11.851401487+08:00`**）

| # | 件 | 表内 sha16 | 我现取 sha16 | 判 | `inFP` 表 / 现 |
|---|---|---|---|---|---|
| 1 | `build/DirectWrite.Linux/WicSeamProbe/Program.cs` | `b36728870f822a23` | `b36728870f822a23` | ✓ | 0 / 0 ✓ |
| 2 | `build/MilBridge/tests/BboxProbe/Program.cs` | `2001427e88b7f709` | `2001427e88b7f709` | ✓ | 0 / 0 ✓ |
| 3 | `build/MilBridge/tests/CoverageProbe/Program.cs` | `c78ed88fc1fd34f4` | `c78ed88fc1fd34f4` | ✓ | 0 / 0 ✓ |
| 4 | `build/MilBridge/tests/FrameProbe/Program.cs` | `b6d00269cf6f6aad` | `b6d00269cf6f6aad` | ✓ | 0 / 0 ✓ |
| 5 | `build/MilBridge/tests/IcuBreakParity/Program.cs` | `52f0ab739aaacf3b` | `52f0ab739aaacf3b` | ✓ | 0 / 0 ✓ |
| 6 | `build/MilBridge/tests/LsProbe/Program.cs` | `f536e535d6903227` | `f536e535d6903227` | ✓ | 0 / 0 ✓ |
| 7 | `build/MilBridge/tests/PcLineOracle/Program.cs` | `a23b7476833da140` | `a23b7476833da140` | ✓ | 0 / 0 ✓ |
| 8 | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | `ca6f1bea560f2326` | `ca6f1bea560f2326` | ✓ | 0 / 0 ✓ |
| 9 | `build/MilBridge/tests/T2eLineHeight/Program.cs` | `1f719638830afdde` | `1f719638830afdde` | ✓ | 0 / 0 ✓ |
| 10 | `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `a70aeb1d988ebc9e` | `a70aeb1d988ebc9e` | ✓ | 1 / 1 ✓ |
| **11** | `build/MilBridge/tools/pkg-src-retiredpath-check.sh` | `60009734108344bd` | **`231ae30326a4fb31`** | **✗ 现取不符**（V1） | 1 / 1 ✓ |
| 12 | `build/MilBridge/tools/pts-pages-guard.sh` | `7074a774739efaf2` | `7074a774739efaf2` | ✓ | 1 / 1 ✓ |
| 13 | `build/MilBridge/repo-alias-allow.tsv` | `19496f3615ccb45a` | `19496f3615ccb45a` | ✓ | 1 / 1 ✓ |
| 14 | `build/MilBridge/P1-w2-criteria.md` | `ceecddcccda8521f` | `ceecddcccda8521f` | ✓ | 0 / 0 ✓ |
| **15** | `build/MilBridge/P1-w2-report.md` | `80e1583d2680b382` | **`f934e6c8972cfc68`** | **✗ 现取不符**（**块内已声明口径** ✓） | 0 / 0 ✓ |

- **与我 `t15` §3 表的比（从 `git show 7bad6ba:` 现取）**：**15 格逐位相同**（含第 `11`／`12`／`13`／`14`／`15` 行）⇒ 表内那句「15 格与 `t15` §3 表逐位相同、无一格不同」**成立** ✓。
- **第 `15` 行**：表值＝`t14` 交付态全文（`80e1583d2680b382`）；现取＝`f934e6c8972cfc68`。**块内显式声明**：「本追加块落定后，本件 `head -n -1` 的值已不是 `e37f0270a525e815`…**全文** sha16 由 `P1-w2-close-report.md` 现算登记（本件末行带自身口径 ⇒ 全文值不可能自指）」⇒ **自指不可免、已声明** ✓。
- **块内两处自洽我都复算**：现盘 `head -n -1` ＝ **`44f578c12a64431b`**（＝块内所写 ✓）；追加前（`18617a1^`，`136` 行）`head -n -1` ＝ **`e37f0270a525e815`**（✓）、全文 ＝ **`80e1583d2680b382`**（＝第 `15` 行表值 ✓）。

### 2-2 W2：立号 ＋ 条目

| 项 | 我现取 | 判 |
|---|---|---|
| **占用（四件 route 件）** | `KD` pre **`0`** → commit **`1`** → now `1`；`CS`／`HO`／`AB` 全 `0`／`0`／`0` | ✓ **改前 0／改后 ≥1** |
| 改前 `declared` 最大 ID 号 | **`181`** ⇒ `D-G182` **未被占用** ✓ | ✓ |
| `declared` 行 | `:114` ＝ `ID⟶D-G182⟶req=KD⟶present=KD`；`KD` 内 `D-G182` 命中 **`1`** ⇒ `req=KD` 与现取一致 ✓ | ✓ |
| 标题形态 | `### 🆕 **\`D-G182\`** —— …`，**条目形态标题计数 ＝ `1`** | ✓ |
| 八段齐（`sed -n '3713,3722p'` 逐段） | `现象（逐字，t15 逐字点名）`／`根因`／`机器证（我现取自算，三条读数；t25，读时 2026-09-28T16:21:08+0800）`／`判据（机器，三条并列）`／`🔴 口径句（永久，逐字）`／`两极化（真跑，逐条给原始读数）`／`边界（如实划界）`／`同族（不合并）` | ✓ **八段齐** |
| **「由 `t15` 发现、队长配号」** | **标题**里逐字 ＋ **边界①** 逐字（「**由 `t15` 发现、队长配号** —— 发现路径与号码来源如实记，非发现者自领」）⇒ **双处** | ✓ **如实记** |
| 边界②「预存在、非 `t14` 引入」 | 逐字在位 | ✓ |
| 全仓引用 | `KD:3713`（条目）／`declared:114`／`P1-w2-close-report.md`（`t25` 自己的报告，非 route 件）⇒ **无与既有号冲突** | ✓ |

### 2-3 W2：**我自己重跑的两极化**（改后件 `231ae30326a4fb31`；改前件 `60009734108344bd` —— git 与 `bak/*.pre-t25` **双路同值**）

| 腿 | 我现取的原始机读行 | `rc` | 判 |
|---|---|---|---|
| 缺 `tests,src`（**只建 `build/`**） | `RETIREDPATH=FAIL reason=tree-dir-missing dirs=tests,src root=…/f_build（射程面三目录必须齐；**不许**降成 NOINFO、**不许**空 path=）` | `1` | ✓ **点名** |
| 缺 `build,src`（只建 `tests/`） | `… dirs=build,src …` | `1` | ✓ |
| 缺 `build,tests`（只建 `src/`） | `… dirs=build,tests …` | `1` | ✓ |
| **全缺** | `… dirs=build,tests,src …` | `1` | ✓ **逐目录点名** |
| 三目录齐 ＋ 针 | `  build/Foo.cs:2 kind=code rule=code-retired-path` ＋ `RETIREDPATH_SCAN mode=tree files=1 hits=1 code=1 …` ⇒ `RETIREDPATH=FAIL` | `1` | ✓ **file＋line 点名** |
| 三目录齐 ＋ **非针件** | `RETIREDPATH=PASS mode=tree files=1 hits=0 code=0 declared=0 self_skip=0 needle=wpf-linux-20260906` | `0` | ✓ |
| 三目录齐 ＋ **空语料** | `RETIREDPATH=NOINFO reason=empty-corpus mode=tree` | `3` | ✓ **零语料不当绿** |
| **成对：改前件 × 同一沙箱（只建 `build/`）** | `RETIREDPATH=NOINFO reason=no-paths-file path=` | `3` | ✓ **成对成立**（同一夹具，唯一变量＝牙的版本） |
| **断言**（剥掉判词括注后判字段） | `RETIREDPATH=` 行 **`6`**；**空 `path=` 字段 ＝ `0`**；`reason=no-paths-file` 命中 ＝ **`0`** | — | ✓ **不出现空 `path=`／不出现 `no-paths-file`** |
| `paths` 面语义未变 | 清单缺席 ⇒ `NOINFO reason=corpus-unreadable mode=paths path=…/does-not-exist`（**非空 `path=`**）rc=3；清单在＋针 ⇒ `FAIL` 点名 `build/Foo.cs:2 kind=code（即将入仓的件…）` rc=1 | `3`／`1` | ✓ |
| `--selftest` | `RETIREDPATH_SELFTEST=PASS cases=11 pass=11 fail=0`；**stderr `0` 行** | `0` | ✓ |
| 真树正极 | `RETIREDPATH=PASS mode=tree files=568 hits=3 code=0 declared=3 self_skip=1 needle=wpf-linux-20260906` | `0` | ✓（`files` `567`→**`568`** 是并发写者加件的**点读数**，`code=0` 不变） |

### 2-4 覆盖面位移逐件归因（现取 `2026-09-28T16:25:56.820984180+08:00`）

| 项 | 我现取 | 判 |
|---|---|---|
| `inputs_fp` | 入口（`t25` 声称）`e9f95ec005715b3a…` → **出口现取 `8c4ce894d04eae7b…`** | ✓ 与声称的出口值**逐位相同** |
| 覆盖面件数 | **`226`** | ✓ 未变 |
| **逐件归因** | `t25` 动的六件里：`tools/pkg-src-retiredpath-check.sh` ⇒ **`in-list=1`**（＝**唯一**动因）；`P1-w2-report.md`／`P1-tail-scout.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／`P1-w2-close-report.md` ⇒ **全 `0`** | ✓ **100% 归因该牙** |
| 现盘是否还有别的 `in-list` 脏件 | `HANDOFF-NEXT.md`（`in-list=0`）／`P1-w1-report.md`（`in-list=0`）⇒ **无** | ✓ 位移归因穷尽 |
| `[42] --expect` | `verify-all.sh:1195` ＝ **`--expect 226`**（**未改**）；实跑 ⇒ `FP_MANIFEST_TEETH=PASS reason=ok files_n=226 files_n_uniq=226 blank_n=0 declared_expect=226`／`FP_MANIFEST_STEP_RC=0` | ✓ **件数不变 ⇒ 无需同趟改；无 `files-n-mismatch`** |

### 2-5 `--emit` 同趟性（**按队长更正后的三不变量**）

| 不变量 | 我现取 | 判 |
|---|---|---|
| ① `DECL-ANCHORS` 的 `KD=` == `KD` 现取 sha16 | 锚 `540de62c051f0875` ≡ `sha256sum samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＝ `540de62c051f0875` | ✓ |
| ② 新号有 `ID` 行且 `req`／`present` 与现取一致 | `:114` ＝ `ID⟶D-G182⟶req=KD⟶present=KD`；`KD` 内该号命中 `1` | ✓ |
| ③ `DECLDRIFT=0` | `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` ＋ `DEFREG_DECLDRIFT_KEYS=-` | ✓ |
| **「真的重发了」的证据** | `KD mtime 16:21:08.750967659` **＜** `declared mtime 16:21:20.186965845`；`# DECL-GEN = (--emit) 2026-09-28 16:21:20 +0800`（＝表 mtime 的秒）；表 sha16 `d9db8ed740145643 → 5559af5443888348`；行数 `225 → 226`、数据行 `216 → 217` | ✓ **重发属实** |
| **与「上一代」表的 diff** | 现取恰 **3 行**：`1,2c1,2`（`DECL-GEN` ＋ `DECL-ANCHORS` 的 `KD=`）＋ `113a114`（新 `ID` 行）⇒ **逐行可归因** | ✓（`t25` 顶出的那个"表述含糊"我复现并同意其更正） |
| **旁证**（不得当主判据） | 现跑 `--emit` 与**现盘表**：`tail -n +2` 两侧 **`cmp` `IDENTICAL`**（含锚行）、`diff` **`0`** 行 | ✓ |

### 2-6 W3：侦察件两处打架

| 项 | 我现取 | 判 |
|---|---|---|
| 两处**逐字点名** | 更正段 ① 点名：**正文**（内容锚＝`### W2 ·` 小节里「**入口（原文照抄）**」那条第 `2` 项）＝「豁免通道 ＝ `build/MilBridge/retired-path-provenance.tsv`（`kind=code` **永不豁免**）」【正确】；**§4 分波表**（现取 `:517`）＝ `build/MilBridge/tools/retired-path-provenance.tsv`【错】 | ✓ |
| **以正文为准** | 更正段 ② 逐字「**以正文那句为准**」 | ✓ |
| 真件现取 | `build/MilBridge/retired-path-provenance.tsv`：`2200 B`／`mtime 2026-09-27 11:51:43`／`sha16` **`10d62946231cc809`**（与更正段所写**逐位相同**）；`build/MilBridge/tools/` 下 **ABSENT**（`ls` 失败） | ✓ |
| **原文一字未删** | 正文那句 `grep -c` ＝ `2`（原句 ＋ 更正段引文）；`§4 :517` 行现取仍在（含该错路径） | ✓ |
| 责任链 | 更正段 ③ 逐字：侦察 **§4 分波表**写错 ⇒ 队长据此写进 `t14` 契约的 `inScope` ⇒ 被 **`t14` 如实顶回**（其报告 §2 末段点名该路径不存在）⇒ 本席同趟在册更正；**「`t14` 处置正确、不计其错；错源在侦察」** | ✓ **如实入册** |

### 2-7 越域 ＋ 两牙

| 项 | 我现取 | 判 |
|---|---|---|
| `porcelain` 逐行 | ` M build/MilBridge/HANDOFF-NEXT.md`（`in-list=0`）／` M build/MilBridge/P1-w1-report.md`（`in-list=0`）／`?? build/MilBridge/P1-task0201-criteria.md`（`t7`）／`?? build/MilBridge/P1-v-close-report.md`（另一车道）／`?? build/MilBridge/tools/timestamp-order-check.sh`（另一车道的新牙）⇒ **全部不在 `t25` 的提交里** | ✓ **`t25` 名下零脏件** |
| 未 add/commit/push | `git diff --cached --numstat` 行数 ⇒ **`0`** | ✓ |
| `DEFREG` | `DEFREG_DECL=n=217 route_ids=217` ＋ `DEFREG=PASS declared=217 route_ids=217` | ✓ 未退化 |
| `REPORTID` | `REPORTID=PASS files=198 ids=2060 declared=217` | ✓ `declared` 未变 |
| **增量逐件归因** | `t25` 读时 `197／2053` → 我现取 `198／2060`（`+1 文件／+7 ids`）：**成对读数**（沙箱去掉 `P1-v-close-report.md` ⇒ `files=197 ids=2057`）⇒ 该**新件**贡献 `+1 文件／+3 ids`；**其余 `+4 ids`** 来自 `P1-w1-report.md` 的**就地编辑**（mtime `16:25:52`，`porcelain` 现为 `M`）⇒ **两件合计 `+1／+7`，逐件可归因** | ✓ |
| 我自己历件是否扰动语料 | 我六件（`P1-{w2,dg179,w1,dg181,w1-close,w3}-verify.md`）**全部不匹配 `*report*.md`** ⇒ 我的写入**不动** `files`/`ids` | ✓ |

---

## §3 我点名的具名差异（**我推翻的话 ＝ `none`**）

### V1（low）：W1 表**第 `11` 行**是 `t14` 交付态，而**同一笔提交**已把该件改成 `231ae30326a4fb31` ⇒ 逐件"现取对拍"有 **1 格未声明的**不符
- 现取：表内第 `11` 行 ＝ `60009734108344bd`（＝`t14` 交付态，且与我 `t15` §3 表**逐位相同** ✓）；**现盘** ＝ `231ae30326a4fb31`（`t25` 本笔的 `W2` 修法所致，`numstat 34/1`、`279→312` 行）。
- 对照：第 `15` 行同样"现取不符"，但**块内已显式声明**自指口径（`head -n -1`／全文两组值）⇒ **可判**；**第 `11` 行没有任何口径注**（块内「口径提醒」只提了本件自身）。
- ⇒ acceptance 要求的「逐件现取 vs 表内值，不一致即点名」下，**15 格里 `2` 格不符、其中 `1` 格已声明、`1` 格未声明**。**实质没错**（表是 `t14` 交付态、"与 `t15` §3 逐位相同"也成立）；缺的是一句口径。
- 建议：dated 追加一句 —— 「表内第 `11` 行 ＝ `t14` 交付态；**本笔 `W2` 修法已把该件改为 `231ae30326a4fb31`（`312` 行）**，此后引用该件以现取为准」。

### V2（low）：牙的失败判词**内嵌 `path=` 字样**，会让任何按字段名 grep 的断言**误命中**
- 现取：`RETIREDPATH=FAIL reason=tree-dir-missing dirs=…（射程面三目录必须齐；**不许**降成 `NOINFO`、**不许**空 `path=`）` —— 括注里写着「空 `path=`」。
- ⇒ 我第一版断言器 `grep -c 'path='` ⇒ **`4`**（看似 4 处空 `path=`），**全是括注文字**；**剥掉「（…）」后**重算 ⇒ **空 `path=` 字段 `0`、`no-paths-file` 命中 `0`** ✓。若我照第一版写出去就是**假红**。
- 建议：把括注里的 `path=` 改成不含字段同形的写法（如「`path` 字段」），或在本件头注明「判词括注中含字样、断言必须判**字段**」。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | 「表是谁写进文件的」（写者身份） | **`NOINFO`** | 我只能证**内容不变量**（`KD` 锚/新 ID 行/`DECLDRIFT=0`）＋**时间戳**（`DECL-GEN 16:21:20` ＝ 表 mtime 秒；`KD mtime` 早 `11.44 s`）⇒ 「**重发属实**」可判；**"由 `t25` 本人写"不可判**（`--emit` 只打 stdout，落盘动作可由任何写者执行）。 |
| N2 | `P1-v-close-report.md`／`P1-w1-report.md` 两件的**写者归属** | **`NOINFO`** | 只按 mtime／`porcelain` 归因（均不在 `t25` 的 `numstat` 里）；未逐件核其契约。 |
| N3 | 真树 `files=568`（`t25` 读时 `567`） | 已核（非 `NOINFO`） | **点读数**：并发写者加件所致；`code=0` 与 `PASS` 判词不变 ⇒ 不判不一致。 |
| N4 | `--expect` 是否**将来**需要改 | 已核（非 `NOINFO`） | 本波件数 `226→226` ⇒ **本次无需改**；W4 若把新牙接进 `fp_inputs()` 则须同趟改（`t24` 已登记该责任）。 |
| N5 | `B-*`／`C-1` 等**上一代**条目 | **本件不判** | 派单 `inScope` 只限 W1／W2／W3 三处；我未跑门禁/整波。 |
| N6 | 未跑门禁/构建/整波/应用 | **未做（边界明写）** | 唯一实跑的"步"是 `[42]` 的**独立步**（`fp-manifest-step.sh --expect 226`，纯读＋计数）＋两颗只读检查器 ＋ 牙的 `--selftest`。 |

---

## §5 我的自伤与更正（如实记）

1. **断言器第一版会假红**（**当场识别并修**）：我用 `grep -c 'path='` 数「空 `path=`」⇒ 得 **`4`**；看清原文才发现命中的是牙判词**括注里**的「**不许**空 `path=`」字样，**不是字段**。改法：**先剥掉 `（…）` 括注再判字段** ⇒ 空字段 **`0`**、`no-paths-file` **`0`** ✓。⇒ 记为本件 **V2** 的发现来源；若不改，我会把"没病"写成"有病"。
2. **我第一版夹具的标签写反**：我嘴上写「缺 `tests`」，实际夹具是「**只建 `tests/`**」⇒ 它给的是 `dirs=build,src`。**读数没错、标签错**；报告里已按**实际夹具**（只建 `X`）逐条写清，并把四缺法（`dirs=build`／`tests`／`src`／三者齐缺）全部覆盖。
3. **行号引用纪律**：本件引 `:114`／`:517`／`:3713`–`:3722`／`:1195`／`:137`–`:158` **均先 `sed -n`/`grep -n` 打过原文**。

---

## §6 收尾

- `$N` 内我**只写本件**；被判件（`P1-w2-report.md`／`P1-tail-scout.md`／`tools/pkg-src-retiredpath-check.sh`／`KNOWN-DEFECTS.md`／`declared.tsv`）**一字未动**（两件 `M` 是并发写者的）。
- 沙箱与夹具全在 `~/wv87y/`（**不落 `/tmp`**）；未跑门禁/构建/整波/应用；未 `git add/commit/push`（暂存区 `0`）。
- ⏪ **追加（本件落盘之后 `16:27:38.680182656+08:00` 现取，只补不删）**：① 契约 `Verify` 三条原样现跑 ⇒ `wc -l` ＝ **`241`**｜`sha256sum | cut -c1-16` ＝ **`24e7270f24c390b9`**｜`infp.sh fp` ⇒ **`8c4ce894d04eae7b…`**（与 §2-4 出口值同；全程未变）、`infp.sh list` 行数 ⇒ **`226`**｜`DEFREG=PASS declared=217 route_ids=217`｜`REPORTID=PASS files=198 ids=2060 declared=217`。
- ⏪ **追加（同上）②**：`porcelain` 现为 **`6`** 行 ＝ 上表 `5` 行 ＋ `?? build/MilBridge/P1-w2-close-verify.md`（**本件**）⇒ **`t25` 名下仍零脏件**；暂存区仍 `0`。
- ⏪ **追加（同上）③**：本件名不匹配 `*report*.md` 语料（`P1-w2-close-**verify**.md`）⇒ 本件不扰动 `REPORTID` 的 `files`/`ids`。

- **判词尾行**：`P1-W2-CLOSE-VERIFY: W1=[13/15 逐位同; #11 未声明口径; #15 已声明; == t15§3 全 15 格] W2=[占用 pre0→KD1; 最大号181; 标题1; 八段齐; 由t15发现+队长配号 双处; 极化 4缺法点名/针点名/PASS/空语料NOINFO; 空path=0 no-paths-file=0; 改前件成对 NOINFO; selftest 11/11 stderr0] fp=[e9f95ec0→8c4ce894 226→226; 唯一 in-list=1 是牙; expect 226 未改且实跑 PASS] emit=[KD锚≡现取; D-G182 行 req=KD; DECLDRIFT=0; 重发属实(时间戳+规模+3行 diff); 旁证 cmp IDENTICAL] W3=[两处逐字点名+以正文为准+责任链; 原文仍在] teeth=[DEFREG PASS 217/217 drift0, REPORTID 198/2060 +1/+7 逐件归因] scope=[t25 dirty=0] overturned=none V1=low V2=low NOINFO=6`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `ad1bfd9e230d5a7e` ／ FULL `ad1bfd9e230d5a7efc7c4b548884d59d9e8a721a8c1b5d4e2fe90e9a162c1973` ／ `wc -l` ＝ 244 行（**不含**本行）／末次读取时刻 `2026-09-28T16:27:38.680182656+08:00`（亚秒）／写入方式 **temp ＋ rename**。
