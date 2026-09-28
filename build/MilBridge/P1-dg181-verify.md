# P1-dg181-verify —— `t18`（I1 立号 `D-G181` ＋ I2/I3/I4）**独立复核判词**（`verifier` / `t19`）

- **被核交件**：`t18`（成员 `scribe`）的交件 —— 提交 **`f590acaa1ba755e6b73cc43ced883c6176f3cef4`**（`%cI = 2026-09-28T16:12:16+08:00`，父 `4a97a0d3a71d341a5051651f33a450d13490fb9e`）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜我开工时 `HEAD=7bad6ba`（`16:17:24`）；**收尾时** `HEAD=192b573`（`16:18:37`，W3b 的搬仓批）。
- **读取时刻**：本件全部读数在 **`2026-09-28T16:17:38` – `2026-09-28T16:18:53 +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-dg181-verify.md`）＝我唯一写入的件。沙箱/中间件在 `~/wv85y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/应用/显示位；未 `git add/commit/push`。**不复述** `t18` 的结论 —— 每条我自己现取、每腿我自己跑（**不引我上一件 `t13` 的输出当证据**）。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | **`D-G181` 条目成条且体例一致**（含「责任在队长」） | **成立**（八段齐，逐段点名见 §2-1；「责任在队长」**逐字在位**）｜⚠️ 附 V2（段序与既有一条不同，无实质影响） |
| 2 | **口径句逐字在位 ＋ 机制我重跑** | **成立**（句在 `HANDOFF-NEXT.md:322`，**位于纪律区 `## §下一波未闭项`** 之下；四个核心子串各 `1` 次；与 `f590aca` 版**同 sha16**；**三读数我现跑全部复现**：工作树级**空**／提交级 **`4 0`**／前缀 `cmp` **IDENTICAL**） |
| 3 | **立号未被占用** | **成立**：四件 route 件 **pre（`f590aca^`）＝ `0／0／0／0`** → commit 后 **KD `1`、CS／HO／AB `0`**；`declared` 新增行 `:113 ID→D-G181→req=KD→present=KD`；**无与既有号冲突**（全仓只有 4 处引用，全部为本号自己的登记） |
| 4 | **I2／I3／I4 三条 dated 追加** | **成立**：`^-[^-]` ＝ **`0`**（`numstat` `3 0`）；三条数值**我自算复现**（§2-4）；戳 **早于提交 `88 s`**｜⚠️ 附 V1（**同秒戳，第二次**） |
| 5 | **`--emit` 同趟性 ＋ 两牙** | **成立**：现跑 `--emit` 与现场表**从第 `2` 行起逐字节 `IDENTICAL`**（连锚行都相同）；`DEFREG=PASS declared=216 route_ids=216` ＋ `DECLDRIFT=0 keys=-` ＋ `rc=0`；`REPORTID` 增量**逐件归因**（§2-6） |
| 6 | 越域为零 ／ 未 add ／ 载体 | **成立**：`t18` 名下**零脏件**；`porcelain` 收敛到 `1` 行（`t7` 的件）；暂存区 `0` |
| — | **我推翻的话** | **`none`**（一处**戳口径**需补：V1；一处**段序**建议：V2） |

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 构件与只增不改
```bash
cd $N && git show --numstat --format='%H %P %cI' f590aca
cd $N && for f in samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/tools/defect-registry-declared.tsv \
                build/MilBridge/P1-dg179-report.md build/MilBridge/HANDOFF-NEXT.md; do \
   printf '%-56s ^-= %s\n' "$f" "$(git diff f590aca^ f590aca -- $f | grep -c '^-[^-]')"; done
cd $N && for f in <同四件>; do printf '%s → %s  now=%s\n' "$(git show f590aca^:$f|wc -l)" "$(git show f590aca:$f|wc -l)" "$(wc -l < $f)"; done
```

### 1.2 机制重跑（**口径句的机器证，我自己现跑**）
```bash
cd $N && git diff --numstat -- build/MilBridge/P1-dg179-report.md          # ① 工作树级（已提交、干净）⇒ 期望空
cd $N && git show --numstat f590aca -- build/MilBridge/P1-dg179-report.md  # 本笔自己的改动
cd $N && git diff --numstat e122f8d4 39f23d0 -- build/MilBridge/P1-dg179-report.md   # ② 条目引的那两 sha
cd $N && git diff --numstat 39f23d0^ 39f23d0 -- build/MilBridge/P1-dg179-report.md   # 同值
cd $N && head -c 17360 build/MilBridge/P1-dg179-report.md > ~/wv85y/pfx.trunc          # ③ 前缀 cmp
cmp ~/w281-scribe/bak/P1-dg179-report.md.pre-t12 ~/wv85y/pfx.trunc && echo IDENTICAL
```

### 1.3 口径句在位 ＋ 所属区 ＋ 未被后续写者改动
```bash
cd $N && grep -n '恒真假绿通道' build/MilBridge/HANDOFF-NEXT.md
cd $N && for s in '凡用 `git diff --numstat -- <路径>` 判' '必须先证明它没在空转' '已提交件上该命令恒空、恒绿' '这是恒真假绿通道'; do \
   printf '%-46s n=%s\n' "$s" "$(grep -c "$s" build/MilBridge/HANDOFF-NEXT.md)"; done
cd $N && awk 'NR<=322 && /^## /{n=NR;h=$0} END{print n": "h}' build/MilBridge/HANDOFF-NEXT.md
cd $N && grep '恒真假绿通道' build/MilBridge/HANDOFF-NEXT.md | sha256sum | cut -c1-16
cd $N && git show f590aca:build/MilBridge/HANDOFF-NEXT.md | grep '恒真假绿通道' | sha256sum | cut -c1-16
# t18 的六行在现盘是否仍在（**必须用 `grep -nF --`**，否则以 `-` 起头的行会被当选项）
cd $N && for L in 320 321 322 323 324 325; do pat=$(git show f590aca:build/MilBridge/HANDOFF-NEXT.md | sed -n "${L}p"); \
   printf '[%s] → 现盘:%s\n' "$L" "$(grep -nF -- "$pat" build/MilBridge/HANDOFF-NEXT.md | head -1 | cut -d: -f1)"; done
```

### 1.4 立号占用
```bash
cd $N && for f in samples/WpfFeatureProbe/KNOWN-DEFECTS.md docs/CURRENT-STATE.md handoff.md samples/WpfTextDemo/ACCEPTANCE-BASELINE.md; do \
   printf '%-50s pre=%s commit=%s now=%s\n' "$f" "$(git show f590aca^:$f|grep -c 'D-G181')" "$(git show f590aca:$f|grep -c 'D-G181')" "$(grep -c 'D-G181' $f)"; done
cd $N && grep -nE '^#{2,4}.*D-G181' samples/WpfFeatureProbe/KNOWN-DEFECTS.md
cd $N && grep -nP '^ID\tD-G181\t' build/MilBridge/tools/defect-registry-declared.tsv
cd $N && grep -rn 'D-G181' --include='*.md' --include='*.tsv' --include='*.json' samples/ build/MilBridge/ docs/
```

### 1.5 I2／I3／I4 数值自算 ＋ 戳
```bash
B=~/w281-scribe/bak/declared.tsv.pre-t6; D=$N/build/MilBridge/tools/defect-registry-declared.tsv
echo "全注释域: 原始输出行=$(diff <(grep '^#' $B) <(grep '^#' $D) | wc -l)  内容行=$(diff <(grep '^#' $B) <(grep '^#' $D) | grep -c '^[<>]')"
echo "单键域  : 原始输出行=$(diff <(grep '^# DECL-ANCHORS' $B) <(grep '^# DECL-ANCHORS' $D) | wc -l)  内容行=$(diff <(grep '^# DECL-ANCHORS' $B) <(grep '^# DECL-ANCHORS' $D) | grep -c '^[<>]')"
cd $N && stat -c '%n mtime=%y ctime=%z' build/MilBridge/P1-dg179-criteria.md     # I4 旁证
cd $N && stat -c '%n mtime=%y ctime=%z' build/MilBridge/P1-dg179-report.md       # I2/I3/I4 落盘
# I3 不变量（我自己的沙箱成对读数；语料＝全量 196 件报告件）
cp -a build/MilBridge/*report*.md $S/build/MilBridge/ ; bash build/MilBridge/tools/report-id-domain-check.sh --root $S
rm -f $S/build/MilBridge/P1-dg179-report.md ; bash build/MilBridge/tools/report-id-domain-check.sh --root $S
```

### 1.6 `--emit` 同趟性 ＋ 两牙 ＋ 越域
```bash
cd $N && bash build/MilBridge/tools/defect-registry-check.sh --emit > ~/wv85y/emitted.tsv
cd $N && sed -n '1,2p' ~/wv85y/emitted.tsv ; sed -n '1,2p' build/MilBridge/tools/defect-registry-declared.tsv
cd $N && tail -n +3 build/MilBridge/tools/defect-registry-declared.tsv > ~/wv85y/live3.tsv ; tail -n +3 ~/wv85y/emitted.tsv > ~/wv85y/emit3.tsv ; cmp ~/wv85y/live3.tsv ~/wv85y/emit3.tsv && echo IDENTICAL
cd $N && tail -n +2 build/MilBridge/tools/defect-registry-declared.tsv > ~/wv85y/live2.tsv ; tail -n +2 ~/wv85y/emitted.tsv > ~/wv85y/emit2.tsv ; cmp ~/wv85y/live2.tsv ~/wv85y/emit2.tsv && echo IDENTICAL
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG=|^DEFREG_DECL=|^DEFREG_DECLDRIFT'
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -1
cd $N && git status --porcelain ; git diff --cached --numstat | wc -l
cd $N && for f in <t18 四件>; do printf '%-56s worktree==HEAD: %s\n' "$f" "$(git diff --quiet HEAD -- $f && echo YES || echo NO)"; done
```

---

## §2 逐格对照表

### 2-1 `D-G181` 条目（判据 1）

| 项 | 我现取 | 判 |
|---|---|---|
| 条目位置 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3702`（批头 `## P1 复核关账批` 在 `:3700`） | ✓ |
| 标题形态 | `### 🆕 **\`D-G181\`** —— **`git diff --numstat -- <路径>` 在**已提交件**上**空转** ⇒ 「只增不改」类 `verify` 恒绿**`；**条目形态标题计数 ＝ `1`** | ✓ 与 `D-G179`／`D-G180` **同形** |
| 段（逐段点名，`awk` 现取）：`现象`／`根因`／`机器证`／`判据（机器，三条并列）`／`🔴 口径句（永久，逐字）`／`两极化`／`边界（如实划界）`／`同族（不合并）` | 八段齐 | ✓（acceptance 点名的七段全在） |
| **「责任在队长」** | 边界①逐字：`① **责任在队长** —— 该 \`verify\` 原文由**队长**写给 \`t12\` 的契约，**不是写者（\`scribe\`）的错**；本条目**如实记此点**。` | ✓ **如实记**（acceptance 要求项） |
| 判据段可执行性 | 逐字：`① …必须用**提交级**…；② 或用**备份前缀 \`cmp\`**…；③ 若坚持用工作树级命令，**必须先证明它没在空转**…⇒ 输出为空时**判 \`NOINFO\`，不许判绿**。` | ✓ 三条款齐，且**「空输出不许判绿」**写死 |
| 未立新号的同族归因 | `同族（不合并）`：`D-G130`／`D-G125`／`D-G172` | ✓ |

### 2-2 口径句 ＋ 机制重跑（判据 2）

| 项 | 我现取 | 判 |
|---|---|---|
| 句在册 | `build/MilBridge/HANDOFF-NEXT.md:322` | ✓ |
| **所属区** | 最近 `## ` 标题 ＝ **`:278 ## §下一波未闭项（具名，不许静默）`** ⇒ 正是「**纪律区**」 | ✓ 与条目自述落点一致 |
| 逐字 | 四个核心子串（`凡用 \`git diff --numstat -- <路径>\` 判`／`必须先证明它没在空转`／`已提交件上该命令恒空、恒绿`／`这是恒真假绿通道`）在现盘**各 `1` 次** | ✓ |
| **未被后续写者改动** | 该行 sha16 现盘 ＝ `f590aca` 版 ＝ **`2518f6837981768c`**（逐位相同） | ✓（`HANDOFF` 之后被 W3a／W3b 追加到 `350` 行，但**此句未动**） |
| `t18` 的六行（`f590aca:320`–`:325`）仍在 | 现盘定位 ⇒ **`:320`／`:322`／`:323`／`:324`／`:325`**（六行全在，位置未变） | ✓ |
| **机制读数 ①（工作树级，已提交干净件）** | `git diff --numstat -- build/MilBridge/P1-dg179-report.md` ⇒ **空输出**；`^-` 计数 ⇒ **`0`** | ✓ **空转复现** |
| **机制读数 ②（提交级）** | `git diff --numstat e122f8d4 39f23d0 -- <同件>` ⇒ **`4	0`**；`git diff --numstat 39f23d0^ 39f23d0 -- <同件>` ⇒ **`4	0`**（同值） | ✓ **复现** |
| **机制读数 ③（前缀 `cmp`）** | `cmp ~/w281-scribe/bak/P1-dg179-report.md.pre-t12 <(head -c 17360 现件)` ⇒ **`IDENTICAL`**（备份 `17360 B` / 现件 `24849 B`） | ✓ |
| **两极化（同件、同改动、两条命令）** | ① 空 ↔ ② `4 0` ⇒ **一条给空、一条给数** ⇒ 该通道**真的会假绿** | ✓ **不是恒真断言** |

### 2-3 立号未被占用（判据 3）

| 件（route 键） | pre（`f590aca^`） | commit（`f590aca`） | now | 判 |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`KD`） | **`0`** | **`1`** | `1` | ✓ |
| `docs/CURRENT-STATE.md`（`CS`） | `0` | `0` | `0` | ✓ |
| `handoff.md`（`HO`） | `0` | `0` | `0` | ✓ |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`AB`） | `0` | `0` | `0` | ✓ |

- `declared.tsv` 新增行：**`:113` ＝ `ID⟶D-G181⟶req=KD⟶present=KD`** ✓（与 `req=KD` 一致：本号只在 `KD` 出现）。
- **冲突核**：全仓（`samples/`／`build/MilBridge/`／`docs/`，`*.md`／`*.tsv`／`*.json`）现取 `D-G181` **只有 4 处** —— 条目 `KD:3702`｜声明表 `:113`｜`HANDOFF:320`（入册标题）｜`HANDOFF:323`（同条目号）⇒ **全部是本号自己的登记，无别义占用** ✓。
- 条目自述 `KD 3699 → 3711`（`+12`）⇒ 我现取行数 **`3699 → 3711`** ✓。

### 2-4 I2／I3／I4 三条（判据 4）

| 条 | 我现取自算 | `t18` 报值 | 判 |
|---|---|---|---|
| **只增不改** | `f590aca` 对 `P1-dg179-report.md` 的 `numstat` ＝ **`3 0`**；`^-` 计数 ＝ **`0`**；行数 **`174 → 177`** | `174 → 177`／`^-`＝0 | ✓ |
| **I2 全注释域** | 原始 `diff` 输出行 ＝ **`6`**／内容行（`^[<>]`）＝ **`4`**（命令：`diff <(grep '^#' bak/declared.tsv.pre-t6) <(grep '^#' 现表)`） | `6`／`4` | ✓ **逐格同** |
| **I2 单键域** | `^# DECL-ANCHORS` 域 ⇒ 原始 **`4`**／内容 **`2`** | `4`／`2` | ✓ |
| **I2 结论** | 原句的 `4` ＝ **内容行数**（不是原始输出行数 `6`）⇒ 同一件事三种行数 | 同 | ✓ |
| **I3 不变量** | **我自己的沙箱成对读数（全量 `196` 件语料）**：含 `P1-dg179-report.md` ⇒ `files=196 ids=2046`；只去掉它 ⇒ `files=195 ids=1991` ⇒ **增量 `+1 文件／+55 ids`** | `+1／+55` | ✓ **逐格同**（绝对值为点读数，见 §4-N3） |
| **I4 旁证（我按纳秒逐位算）** | 判据件 `mtime 15:44:06.153013319`／`ctime 15:44:08.416004191` ⇒ **差 `2.262990872 s`** | `2.262990872 s`（≈`2.263`） | ✓ **逐位同** |
| **I4 划界** | `mtime` 半可由 `cp -p` 备份回溯；`ctime` 半**无回溯源** ⇒ `NOINFO` 写法正确 | 同 | ✓ |
| **戳** | 三条读时均 **`2026-09-28T16:10:48+0800`**；本件落盘 `mtime=2026-09-28 16:10:48.905708995`；提交 **`16:12:16`** | 「早于落盘」 | ⚠️ **同秒**（§4-N1＋V1）；**以提交为上界早 `88 s`** ✓ ⇒ 不 `FAIL` |

### 2-5 `--emit` 同趟性（判据 5）

| 对拍 | 我现取 | 判 |
|---|---|---|
| `--emit` 现跑 | `rc=0`；`# DECL-GEN = (--emit) 2026-09-28 16:18:24 +0800`；`# DECL-ANCHORS = KD=242d8322b7a38ede CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31` | — |
| 现场表 | `# DECL-GEN = (--emit) 2026-09-28 16:10:49 +0800`；**锚行与现跑逐字相同** | ✓ |
| **除前两行外** | `tail -n +3` 两侧 **`cmp` `IDENTICAL`**（`diff` 计 `0` 行） | ✓ |
| **只除第 `1` 行** | `tail -n +2` 两侧 **`cmp` `IDENTICAL`** ⇒ **锚行也逐字相同**（比 acceptance 要求更强） | ✓ |
| 规模 | 两侧各 `225` 行／数据行 **`216`**（`grep -c '^ID'`） | ✓ |
| **同趟性（内容锚）** | `KD=` 锚 `242d8322b7a38ede` ＝ `KNOWNDEFECTS.md` 现取 sha16 **逐位相同**；`DECL-GEN 16:10:49` **＞** `KD mtime 16:10:48.896709019` ⇒ `--emit` 确实在册改动**之后** | ✓ |

### 2-6 两牙 ＋ 增量归因（判据 5）

| 项 | 我现取 | 判 |
|---|---|---|
| `DEFREG` | `DEFREG_DECL=n=216 route_ids=216`／`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`／`DEFREG_DECLDRIFT_KEYS=-`／`DEFREG=PASS declared=216 route_ids=216`；`rc=0` | ✓ **未退化**（`declared 215 → 216` ＝ **`+1`，100% 归因 `D-G181`**，见 §2-3） |
| `REPORTID` | `REPORTID=PASS files=196 ids=2046 declared=216` | ✓ `declared` 未变 |
| `REPORTID` 增量归因 | 我在**自己的沙箱**做**成对**读数：把 `P1-dg179-report.md` 去掉 ⇒ `files=195 ids=1991` ⇒ 该件贡献 **`+1 文件／+55 ids`**（与 I3 的不变量同值）；**绝对值的其余增长**来自并发写者的报告件（§4-N3） | ✓ 逐件可归因 |

---

## §3 我的自伤与更正（如实记）

1. **`grep -nF --` 漏了 `--`**：我第一版核「`t18` 的六行在现盘是否仍在」时写成 `grep -nF "$pat"`，其中 4 个 `pat` 以 `-` 起头（`- **入册落点**…`）⇒ `grep` 把它们当**选项**、报 `grep: 无效的选项 --` 并返回 **NOT-FOUND**。**当场看出是自伤**（stderr 就在眼前）⇒ 改用 **`grep -nF --`** 重跑，六行**全部定位成功**（`:320`／`:322`／`:323`／`:324`／`:325`）。⇒ 教训：**凡拿"行内容"当模式，必须 `--`**（`D-G141` 同族：命令写错会给出恒不中的假证据）。
2. **`python3 strptime('%f')` 只吃 6 位**：I4 的纳秒差用 `%f` 解析 9 位小数直接 `ValueError` ⇒ 我改用**逐位算术**（`8.416004191 − 6.153013319`）得 `2.262990872 s`，与写者值逐位一致。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | I2／I3／I4 的「**读时早于落盘**」 | **`NOINFO(同秒不可对拍)`** | 戳 `16:10:48`（秒级）与 `P1-dg179-report.md` 落盘 `mtime=16:10:48.905708995`（`KD` 亦 `16:10:48.896709019`）**同秒** ⇒ 秒级判不出先后。替代路：提交 `f590aca`＝`16:12:16`（早 `88 s`）⇒ **不 `FAIL`**。见 §5-V1（**同族第二次**）。 |
| N2 | 条目「机器证」所引的 `e122f8d4..39f23d0` | 已核（非 `NOINFO`） | 我现跑 ⇒ `4 0`；`39f23d0^..39f23d0` ⇒ `4 0` ⇒ **逐格复现**。 |
| N3 | `t18` 在 I3 里引的**真树绝对值** `files=194 ids=2042 declared=215` | **`NOINFO(点读数)`** | 那是它读时（`16:1x`）的值；我现取为 `files=196 ids=2046 declared=216`（期间并发写者新增了报告件、`declared` 因本号 `+1`）。**不变量 `+1／+55` 我独立复现**✓ ⇒ 该条实质成立，绝对值不判不一致。 |
| N4 | acceptance 说「三件 route 件」 | **口径按四件办** | 本仓 route 键为 `KD/CS/HO/AB` **四件**（`defect-registry-check.sh` 的 `ALLKEYS` 现取含四个）；我**四件全报**（§2-3），结论相同。 |
| N5 | `t18` 各件的**写者归属**（`HANDOFF` 之后的 `W3a`／`W3b` 追加） | 已核（非 `NOINFO`） | 我按 `numstat` 与 `git log` 归因：`HANDOFF` 现 `350` 行（`f590aca` 到 `325`；`W3a` 到 `338`；`W3b` 到 `350`）⇒ **其后改动全部不计入 `t18`**；且我逐字核过**口径句一行未被改动**（sha16 相同）。 |
| N6 | 未跑门禁/构建/应用 | **未做（派单边界明写）** | 本件全在只读件与自己的车道目录上完成；**唯一跑的牙是两颗只读检查器与一次 `--emit`**（后者按 acceptance 要求）。 |

---

## §5 我点名的具名差异（**我推翻的话 ＝ `none`**）

### V1（medium）：**同秒戳** —— `t17` 报过的 V2 **第二次出现**，且我在册件里**查不到它已入册**
- 现取：I2／I3／I4 三条更正句都写 `读时 2026-09-28T16:10:48+0800`；而 `P1-dg179-report.md` 的落盘 `mtime` ＝ **`2026-09-28 16:10:48.905708995`**、`KD` 的 `mtime` ＝ `16:10:48.896709019` ⇒ **同一秒** ⇒ 「**读时早于落盘**」这一格在**秒级不可对拍**。
- **我另现取**（`grep -rn '同秒\|亚秒'` 于 `KNOWN-DEFECTS.md`／`HANDOFF-NEXT.md`／`docs/ROUTES.md`）⇒ **无命中** ⇒ 我 `t17` 判词里的 **V2 尚未入册**，本条**是同一族的第二次**（`t70` 未来戳 → `t12` 的 `13:47:44` 不可对拍 → `t17` V2 同秒 → 本次）。
- ⇒ 我**不判 `FAIL`**（戳不晚于任何可证落盘时刻；以提交为上界早 `88 s`），但**建议一次立号/入册把这一族结掉**：**① 戳写亚秒**（`%Y-%m-%dT%H:%M:%S.%N%z`）或 **② 保持秒级但让落盘落在下一秒**（读时后 `sleep 1`）。任一都能把该格从"判不了"变成"可对拍"。

### V2（low）：条目**段序**与同册既有条目不同
- `D-G181` 的段序（`awk` 现取）：`现象` → `根因` → `机器证` → `判据` → **`🔴 口径句`** → **`两极化`** → `边界` → `同族`。
- 同册 `D-G179`／`D-G180`（我 `t8`／`t11` 逐段对拍过）的段序是：`现象` → `根因` → `证据` → `判据` → **`两极化`** → **`🔴 口径句`** → `边界`。
- ⇒ **七段全在**（acceptance 点名的都在）、只是 `口径句` 与 `两极化` 的先后互换；**无实质影响**（两段都是"先例/口径"性质）。建议（可选）：统一为 `… 判据 → 两极化 → 口径句 → 边界`，让后人能按固定次序机器抽取。

### 具名不对拍（不判假）
| # | 句 | 现取 | 说明 |
|---|---|---|---|
| ①' | `t18` 的 I3 真树绝对值 `files=194 ids=2042 declared=215` | 我现取 `196／2046／216` | 点读数（§4-N3）；**不变量 `+1／+55` 一致** |
| ②' | `t18` 的「两牙」`REPORTID=PASS files=194 ids=2042 declared=216` | 我现取 `196／2046／216` | 同上；`declared=216` 一致 |

---

## §6 收尾

- `$N` 内我**只写本件**；`t18` 的四件与两颗牙**一字未动**（`KD`／`declared.tsv`／`P1-dg179-report.md` 现盘 == `HEAD` ✓；`HANDOFF-NEXT.md` 的现盘改动**全属 `W3a`／`W3b`**）。
- 沙箱与中间件全在 `~/wv85y/`（**不落 `/tmp`**）；未跑门禁/构建/应用/显示位；未 `git add/commit/push`（暂存区 `0` 行）。
- `porcelain` 收尾现取：**`1` 行**（`?? build/MilBridge/P1-task0201-criteria.md`，`t7` 的）＝ **`t18` 名下零脏件** ✓。
- ⏪ **追加（本件落盘之后 `16:19:4x` 现取，只补不删）**：① 契约 `Verify` 三条原样现跑 ⇒ `wc -l` ＝ **`214`**｜`sha256sum | cut -c1-16` ＝ **`1041152900e7f089`**｜`git show --numstat HEAD -- build/MilBridge/P1-dg179-report.md` ⇒ **空**（`HEAD=192b573` 是 W3b 的搬仓批、**不含**该件）＋ `git diff --numstat -- <同件>` ⇒ **空** ⇒ **两段都空**，正是 `D-G181` 正文所描述的空转形态；`DEFREG=PASS declared=216 route_ids=216`｜`REPORTID=PASS files=196 ids=2046 declared=216`。
- ⏪ **追加（同上）②**：`porcelain` 现为 **`2`** 行 —— `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）＋ `?? build/MilBridge/P1-dg181-verify.md`（**本件**）⇒ **`t18` 名下仍零脏件**。
- ⏪ **追加（同上）③**：本件名 **不匹配** `*report*.md` 语料（`case` 现取 ＝ `no`）⇒ 本件的写入**不扰动** `REPORTID` 的 `files`/`ids`。

- **判词尾行**：`P1-DG181-VERIFY: verdicts=[PASS,PASS,PASS,PASS,PASS,PASS] entry=[8seg ok, 责任在队长 ok] calib=[handoff:322 in 纪律区, sha16 2518f6837981768c unchanged] mech=[worktree empty ↔ commit 4/0 ↔ prefix cmp IDENTICAL] id=[pre 0 → KD 1 CS/HO/AB 0 no-conflict] I234=[^- 0, I2 6/4 & 4/2, I3 +1/+55, I4 2.262990872s] emit=[tail -n +2 BYTE_IDENTICAL, teeth 216/216 drift0 rc0] scope=[t18 dirty=0] overturned=none V1=medium(repeat) V2=low NOINFO=6`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `25fbd04dee297613` ／ FULL `25fbd04dee2976132f58c0c55064adba2222a52d99b9fec16e53f1c86db57af3` ／ `wc -l` ＝ 217 行（**不含**本行）／末次读取时刻 `2026-09-28T16:19:5x+08:00`／写入方式 **temp ＋ rename**。
