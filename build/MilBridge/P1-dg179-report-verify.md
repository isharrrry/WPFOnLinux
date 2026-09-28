# P1-dg179-report-verify —— `t12` 三条 dated 追加的**独立复核判词**（`verifier` / `t13`）

- **被核交件**：`t12`（成员 `scribe`）在 `build/MilBridge/P1-dg179-report.md` 上落的 **F1／F2／F3 三条 dated 追加**（＋第 `4` 行一条「非新条目」的口径说明）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`；**被核提交** `39f23d0623086e40aed7cb83c8b0b7ff5b08a159`（`%cI = 2026-09-28T16:00:58+08:00`，父 `e122f8d4104e032c…`）。
- **读取时刻**：本件全部读数在 **`2026-09-28T16:04:06` – `2026-09-28T16:05:48 +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-dg179-report-verify.md`）＝我唯一写入的件。沙箱/中间件在 `~/wv82y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/应用；不 `git add/commit/push`。**不复述任何既有报告** —— 每条我自己现取复算。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | **只增不改**（原文仍在、新增行点名） | **成立**（**三层证据**：工作树级 `^-` ＝ `0`｜提交级 `4 0`／`^-` ＝ `0`｜**备份前缀级 `cmp` `IDENTICAL`** ＋ 子序列证明「父代 `171` 行全在位、未匹配 `0`、新增恰 `4` 行」）｜⚠️ 具名 I1 |
| 2a | **F1** 三数（数据行／注释行／全文） | **成立**：`215`／`9`／`224`、`215+9=224`、数据行 diff `0` —— **逐格与写者相同**｜⚠️ 具名 I2 |
| 2b | **F2** `*report*.md` 语料成对读数 | **成立**：我自己的沙箱（**全 `192` 件语料**）`files=192 ids=2034` → 只去本件 `files=191 ids=1979` ⇒ **本件贡献 `+1`／`+55`**，**与写者增量逐格相同**｜⚠️ 具名 I3 |
| 2c | **F3** 时刻两口径 | **成立**：判据件 `mtime=15:44:06.153013319`／`ctime=15:44:08.416004191` **两半逐位相同**；本件 `mtime=15:46:17.823568909` 由 `bak/P1-dg179-report.md.pre-t12` **逐位复现**；机制（`mv` 保 `mtime`／只改 `ctime`；`>>` 同改两值）我**各自现跑复现**｜**本件 `ctime` 那一半 ＝ `NOINFO`**（§4-N2） |
| 3 | **dated 戳合规**（读时 < 落盘、秒级） | **成立**：四行读时均 `2026-09-28T15:59:43+0800`（秒级 ✓）；本件落盘 `mtime=ctime=2026-09-28 16:00:01.423110762` ⇒ **早 `18.42 s`**；< 提交 `16:00:58` |
| 4 | **未越域** | **成立**：`t12` 名下**零脏件**（其唯一改件已提交）；现 `porcelain` 全部脏件**逐件落在侦察分波表的 W2 写者域**（`9` 件 `.cs` 经 §B-3 表逐件命中 ＋ `4` 件牙/tsv）＋ `3` 个 `??`（他人件）⇒ **不计入 `t12`** |
| 5 | `NOINFO` 具名 | **5 条**（§4，含「历史 `ctime` 无回溯源」） |

**总判：`t12` 的三条更正实体层全部成立**；我点名 `3` 处**计数口径/语料规模**的具名差异（均 `low`、均不改结论），并点名 **1 处判据自身的空转**（I1，非 `t12` 责任）。

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 只增不改（三层）
```bash
cd $N && git log -2 --format='%h %cI %s'
cd $N && git diff --numstat -- build/MilBridge/P1-dg179-report.md          # 工作树级（acceptance 原样）
cd $N && git diff -- build/MilBridge/P1-dg179-report.md | grep -c '^-[^-]' # 工作树级
cd $N && git show --numstat --format='%H %P %cI' 39f23d0
cd $N && git diff --numstat e122f8d4 39f23d0 -- build/MilBridge/P1-dg179-report.md          # 提交级
cd $N && git diff e122f8d4 39f23d0 -- build/MilBridge/P1-dg179-report.md | grep -c '^-[^-]' # 提交级
# 备份前缀级（最强行证）
stat -c '%n size=%s mtime=%y ctime=%z' ~/w281-scribe/bak/P1-dg179-report.md.pre-t12
sha256sum ~/w281-scribe/bak/P1-dg179-report.md.pre-t12 | cut -c1-16
head -c $(stat -c %s ~/w281-scribe/bak/P1-dg179-report.md.pre-t12) build/MilBridge/P1-dg179-report.md > ~/wv82y/prefix.trunc
cmp ~/w281-scribe/bak/P1-dg179-report.md.pre-t12 ~/wv82y/prefix.trunc && echo PREFIX_IDENTICAL
# 子序列证明（新增行逐行点名）
python3 - <<'PY'
a=open('/home/links-dev/w281-scribe/bak/P1-dg179-report.md.pre-t12',encoding='utf-8').read().split('\n')
b=open('/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/P1-dg179-report.md',encoding='utf-8').read().split('\n')
j=0; new=[]
for ln in a:
    k=j
    while k<len(b) and b[k]!=ln: new.append((k+1,b[k][:70])); k+=1
    j=k+1
print('new lines =',len(new)); [print('   +%d %s'%n) for n in new]
j=0; miss=0
for ln in a:
    k=j
    while k<len(b) and b[k]!=ln: k+=1
    if k==len(b): miss+=1; j=len(b)
    else: j=k+1
print('parent lines NOT found in order =',miss)
PY
```

### 1.2 F1 三数
```bash
cd $N && TSV=build/MilBridge/tools/defect-registry-declared.tsv
grep -c '^ID' $TSV ; grep -vc '^#' $TSV ; grep -c '^#' $TSV ; wc -l < $TSV
diff <(grep '^ID' ~/w281-scribe/bak/declared.tsv.pre-t6) <(grep '^ID' $TSV) | wc -l
diff <(grep '^#'  ~/w281-scribe/bak/declared.tsv.pre-t6) <(grep '^#'  $TSV) | wc -l
diff <(grep '^#'  ~/w281-scribe/bak/declared.tsv.pre-t6) <(grep '^#'  $TSV)
bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG_DECL='
sed -n '66p' build/MilBridge/P1-dg179-report.md            # F1 被更正的原文仍在
```

### 1.3 F2 成对读数（**我自己的沙箱**）
```bash
S=$HOME/wv82y/sb; mkdir -p $S/build/MilBridge/tools $S/samples/WpfFeatureProbe
cp -a build/MilBridge/*report*.md $S/build/MilBridge/          # 全 192 件语料
cp -a build/MilBridge/tools/defect-registry-declared.tsv $S/build/MilBridge/tools/
cp -a samples/WpfFeatureProbe/KNOWN-DEFECTS.md $S/samples/WpfFeatureProbe/
cp -a build/MilBridge/book-entry-required.tsv $S/build/MilBridge/
stat -c %h $S/build/MilBridge/P1-dg179-report.md               # %h 必须 = 1（无硬链接）
bash build/MilBridge/tools/report-id-domain-check.sh --root $S 2>&1 | tail -1        # 删件前
rm -f $S/build/MilBridge/P1-dg179-report.md
bash build/MilBridge/tools/report-id-domain-check.sh --root $S 2>&1 | tail -1        # 只去掉本件后
bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -1                  # 真树（含本件）
grep -noE '\bD-G[0-9]+\b' build/MilBridge/P1-dg179-report.md | wc -l
sed -n '133p' build/MilBridge/P1-dg179-report.md               # F2 被更正的原文仍在
```

### 1.4 F3 时刻两口径
```bash
cd $N && stat -c '%n mtime=%y ctime=%z' build/MilBridge/P1-dg179-report.md build/MilBridge/P1-dg179-criteria.md
grep -n '落盘 .15:44:08' build/MilBridge/P1-dg179-report.md
stat -c '%n mtime=%y ctime=%z' ~/w281-scribe/bak/P1-dg179-report.md.pre-t12
stat -c '%n mtime=%y ctime=%z' ~/w281-scribe/f3/t.moved        # 写者自证件（只读复核）
# 机制自现跑（我的车道）
printf 'x\n' > ~/wv82y/mvtest.txt; stat -c 'write  : mtime=%y ctime=%z' ~/wv82y/mvtest.txt
sleep 2; mv ~/wv82y/mvtest.txt ~/wv82y/mvtest2.txt; stat -c 'after mv: mtime=%y ctime=%z' ~/wv82y/mvtest2.txt
printf 'a\n' > ~/wv82y/apptest.txt; sleep 2; printf 'b\n' >> ~/wv82y/apptest.txt; stat -c 'after >>: mtime=%y ctime=%z' ~/wv82y/apptest.txt
# 第 4 行的自报口径
head -n 169 build/MilBridge/P1-dg179-report.md | sha256sum | cut -c1-16
```

### 1.5 戳合规 ＋ 越域
```bash
cd $N && for L in 171 172 173 174; do printf '[%s] ' "$L"; sed -n "${L}p" build/MilBridge/P1-dg179-report.md | grep -o '读时 `[^`]*`' | head -1; done
stat -c '%y | %z' build/MilBridge/P1-dg179-report.md ; git log -1 --format=%cI 39f23d0
cd $N && git status --porcelain
cd $N && sed -n '517p' build/MilBridge/P1-tail-scout.md                    # W2 写者域原文
cd $N && sed -n '/^### B-3 ·/,/^### B-4 ·/p' build/MilBridge/P1-tail-scout.md   # B-3 表（9 件 .cs）
bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | tail -1
bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -2
```

---

## §2 逐格对照表（左＝我自算，右＝写者值）

### 2-1 只增不改（判据 1）

| 层 | 我现取 | 写者声称 | 判 |
|---|---|---|---|
| **L1 工作树级**（acceptance 原样） | `git diff --numstat -- <件>` ⇒ **空**；`git diff … \| grep -c '^-[^-]'` ⇒ **`0`** | 「`git diff` 里 `^-[^-]` 计数 ＝ `0`」 | ✓（但**空转**，见 I1） |
| **L2 提交级** | `git diff --numstat e122f8d4 39f23d0 -- <件>` ⇒ **`4	0`**；`^-` 计数 ⇒ **`0`** | 「numstat `4 0`」 | ✓ |
| **L3 备份前缀级** | `bak/P1-dg179-report.md.pre-t12`（`17360 B`／`170` 行／sha16 **`c14328375cf015be`**）与 `head -c 17360 现件` ⇒ **`cmp` `IDENTICAL`** ⇒ **纯字节前缀** | 「`170 → 174` 行」＋改前 `c14328375cf015be…` | ✓ **最强** |
| **子序列证明** | 父代 `171` 行（含尾空串）**全部按序在位**、**未匹配 `0`**、多出来**恰 `4` 行** | 新增行 `@@ -170,0 +171,4 @@` | ✓ |
| 新增行**逐行点名** | `+171` F1 更正行｜`+172` F2 更正行｜`+173` F3 口径说明｜`+174` 「非新条目」自报口径说明（四行开头均 `- ⏪ **dated`；读时戳均 `2026-09-28T15:59:43+0800`） | 同 | ✓ |
| **被更正的两句仍在** | `:66` 含「**`224` 行数据行逐字节不变**」（`grep -c` ⇒ `1`）｜`:133` 含「判据件与报告件都不吃 `*report*.md` 语料」（`grep -c '都不吃'` ⇒ `1`） | 「上引原文一字未删」 | ✓ |

### 2-2 F1 三数（判据 2a）

| 量 | 命令 | 我自算 | 写者值 | 判 |
|---|---|---|---|---|
| 数据行 | `grep -c '^ID' declared.tsv` | **215** | `215` | ✓ |
| （旁证）非注释行 | `grep -vc '^#' declared.tsv` | **215** | — | 一致 |
| 注释行 | `grep -c '^#' declared.tsv` | **9** | `9` | ✓ |
| 全文 | `wc -l < declared.tsv` | **224** | `224` | ✓ |
| 恒等式 | — | `215＋9＝224` ✓ | `215＋9＝224` | ✓ |
| 数据行「逐字节不变」 | `diff <(grep '^ID' bak/declared.tsv.pre-t6) <(grep '^ID' 现取) \| wc -l` | **`0`** | `0` | ✓ |
| 注释锚行差集 | 同一条命令 | **`6`**（`diff` 原始输出行数）／**`4`**（只数 `<`／`>` 内容行） | `4` | ⚠️ 具名 I2 |
| 牙自吐 | `DEFREG_DECL=` | `n=215 route_ids=215` | `215` | ✓ |

`diff` 原文（注释锚行）：
```
1,2c1,2
< # DECL-GEN = (--emit) 2026-09-28 14:29:00 +0800
< # DECL-ANCHORS = KD=2152460b7e412352 CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 …
---
> # DECL-GEN = (--emit) 2026-09-28 15:55:05 +0800
> # DECL-ANCHORS = KD=a2621851cce4527f CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 …
```
⇒ **变的只有那两行** ✓（其余 `7` 行注释逐字未动）；写者的**实质结论**（「变的只有 `# DECL-GEN`／`# DECL-ANCHORS`」）**成立**。
**旁证（`pre-t6` 自身）**：`wc -l ＝ 224`／`grep -c '^ID' ＝ 215`／`grep -c '^#' ＝ 9` ⇒ 三数在改前改后**同值**（`224` 从来就是全文行数，不是数据行数）⇒ 写者「量名与数不符」的定性**成立**。

### 2-3 F2 成对读数（判据 2b；**我自己的沙箱、全 `192` 件语料**）

| 腿 | 我现取 | 写者值 | 判 |
|---|---|---|---|
| 删件前 | `REPORTID=PASS **files=192 ids=2034** declared=215` | `files=2 ids=57`（缩小语料） | 增量同（见下） |
| 只去掉本件后 | `REPORTID=PASS **files=191 ids=1979** declared=215` | `files=1 ids=2` | 同上 |
| **增量** | **`+1` 文件／`+55` ids** | **`+1`／`+55`** | ✓ **逐格相同** |
| 独立旁证 | 本件体内 `grep -noE '\bD-G[0-9]+\b'` ⇒ **`55`** 处 ⇒ 与 `ids` 增量**同值** | — | ✓ |
| 真树（含本件） | `files=192 ids=2034 declared=215` | — | ✓ |
| `F2` 原文仍在 | `:133` `grep -c '都不吃'` ⇒ `1` | 「原文一字未删」 | ✓ |
| 写者沙箱存在性（只读） | `~/w281-scribe/sbx-t12/` 现存 `build/MilBridge/V80-t71FIX-verify-report.md`（**只 `1` 件** ⇒ 即「只去掉本件后」那一腿） | 与「箱内语料 ＝ 本件 ＋ 另一件」一致 | ✓ |

### 2-4 F3 时刻两口径（判据 2c）

| 量 | 我现取 | 写者值 | 判 |
|---|---|---|---|
| 判据件 `mtime` | `2026-09-28 15:44:06.153013319 +0800` | 同 | ✓ **逐位** |
| 判据件 `ctime` | `2026-09-28 15:44:08.416004191 +0800` | 同 | ✓ **逐位** |
| 本件 `mtime`（改前状态） | `~/w281-scribe/bak/P1-dg179-report.md.pre-t12` 的 `mtime = 2026-09-28 15:46:17.823568909` | `15:46:17.823568909` | ✓ **逐位** |
| 本件 `mtime`／`ctime`（**现取**） | `mtime=ctime=2026-09-28 16:00:01.423110762`（＝本笔追加之后） | —（写者引的是追加前状态） | 见 §4-N2 |
| 本件 `ctime`（改前状态） | **不可回溯** | `ctime=15:46:17.823568909` | **`NOINFO`**（§4-N2） |
| 「落盘 `15:44:08`」出处 | 报告 `:4` 逐字「判据件（先写）＝ `…P1-dg179-criteria.md`（`6f10658432b7a995…`，**落盘 `15:44:08`**；…）」 | 同 | ✓ |
| ⇒ 口径判定 | 该自述值 `15:44:08` **＝ 判据件 `ctime` 的秒**（`15:44:08`）而 **≠ 其 `mtime` 的秒**（`15:44:06`） | 「该自述的口径 ＝ `rename` 时刻、不是 `mtime`」 | ✓ **成立** |
| **机制自现跑**（我的车道） | 写盘 ⇒ `mtime=ctime=16:05:10.345408322`；隔 `2 s` `mv` ⇒ `mtime=`**未变**`16:05:10.345408322`／`ctime=16:05:12.348410610` | 「`mv` 保留 `mtime`、只更新 `ctime`」 | ✓ **再现** |
| 追加 `>>` 的对照 | 写盘 ⇒ `mtime=ctime=16:05:12.349410611`；隔 `2 s` `>>` ⇒ `mtime=ctime=16:05:14.351412903`（**两值同刻**） | 「两值同刻」的机制解释 | ✓ **再现** |
| 写者自证件（只读） | `~/w281-scribe/f3/t.moved` ⇒ `mtime=2026-09-28 15:59:23.365083693`／`ctime=2026-09-28 15:59:25.367085051` | 引值**逐位相同** | ✓ **其自证可独立复现** |

### 2-5 第 4 行（「非新条目」自报口径说明）

| 量 | 我现取 | 写者值 | 判 |
|---|---|---|---|
| `head -n 169 <本件> \| sha256sum \| cut -c1-16` | **`1a17cd6b8489e16d`** | `1a17cd6b8489e16d`（且称「与其自报逐位相同」） | ✓ **逐位** |

⇒ 三条追加**落在原末行（自报行）之后**，**原自报行的口径与值不受影响** ✓（我另证：`pre-t12` 备份是现件的**字节前缀** ⇒ 原末行逐字未动）。

### 2-6 戳合规（判据 3）

| 行 | 读时戳 | 秒级？ | 落盘时刻（本件 `mtime`＝`ctime`） | 判 |
|---|---|---|---|---|
| `:171` | `2026-09-28T15:59:43+0800` | ✓ | `2026-09-28 16:00:01.423110762` | **读时早 `18.42 s`** ✓ |
| `:172` | 同 | ✓ | 同 | ✓ |
| `:173` | 同 | ✓ | 同 | ✓ |
| `:174` | 同 | ✓ | 同 | ✓ |
| — | — | — | 提交 `2026-09-28T16:00:58+08:00` | 落盘 < 提交 ✓ |

### 2-7 越域（判据 4）

`porcelain`（`16:04:06` 起多趟现取，逐行归属）：

| 行 | 归属 | 判 |
|---|---|---|
| ` M build/DirectWrite.Linux/WicSeamProbe/Program.cs` 等 **`9` 件 `.cs`** | **W2**（逐件在侦察 `§B-3` 表里命中，`IN-B3-TABLE`） | **不计入 `t12`** |
| ` M build/MilBridge/tools/pkg-src-retiredpath-check.sh`／`pts-pages-guard.sh`／`repo-alias-allow.tsv`／`tests/PtsPagesProbe/session_inner.sh` | **W2**（侦察分波表 W2 行**逐字点名**这四件） | **不计入 `t12`** |
| `?? build/MilBridge/P1-task0201-criteria.md` | **`t7`** | 不计入 |
| `?? build/MilBridge/P1-w1-verify.md` | **`t11`（我上一件的判词载体）** | 不计入 |
| `?? build/MilBridge/P1-w2-criteria.md` | **W2 的判据件** | 不计入 |
| `P1-dg179-report.md` | **`t12`（已提交于 `39f23d0`）** | **零脏件** ✓ |

⇒ **`t12` 名下无可归属的越域脏件**；`git status --porcelain | grep -c 'P1-dg179-report'` ⇒ **`0`**（其唯一改件已提交）。两牙现取未退化：`DEFREG=PASS declared=215 route_ids=215`／`REPORTID=PASS files=192 ids=2034 declared=215`。

---

## §3 我点名的具名差异（均 `low`、均不改结论）

### I1（**非 `t12` 责任**）：acceptance 给的 `Verify` 命令在"改动已提交"后**空转**
- 原样现跑：`git diff --numstat -- build/MilBridge/P1-dg179-report.md` ⇒ **空输出**；`git diff -- build/… | grep -c '^-[^-]'` ⇒ **`0`**。
- ⇒ 这两条**在任何情况下都会给 `0`**（因为工作树与 HEAD 相同）⇒ **证明不了"只增不改"**。真正有判别力的层级是**提交级**（`git diff e122f8d4 39f23d0 -- <件>` ⇒ `4 0`／`^-`＝`0`）与**备份前缀级**（`cmp` `IDENTICAL`）。
- **建议**：把该 Verify 行改成 `git diff --numstat 39f23d0^ 39f23d0 -- <件>`（或 `git show --numstat 39f23d0`）＋ `cmp` 前缀检查；否则下一位复核者会拿到恒真的假绿（`D-G130` 同族）。

### I2：`注释锚行差集 4 行` 的**计数口径未标明**
- 写者句：「同一条命令下**注释锚行**差集 `4` 行」。
- 我现取：**同一条命令**的 `diff` 原始输出有 **`6`** 行（`1,2c1,2` ＋ `---` ＋ `2` 个 `<` ＋ `2` 个 `>`）；若只数 `<`／`>` 内容行则 ＝ **`4`**。
- ⇒ 实质结论（**变的只有那两行**）**成立**；需在册写明是"内容行"还是"`diff` 输出行"。

### I3：F2 成对读数的**绝对值来自缩小语料**，与真树不可直接对拍
- 写者：`files=2 ids=57` → `files=1 ids=2`（其沙箱 `~/w281-scribe/sbx-t12/` 现取确只有 `1` 件报告）。
- 我（**全 `192` 件语料**）：`files=192 ids=2034` → `files=191 ids=1979`。
- ⇒ **增量 `+1`／`+55` 逐格相同**（**不变量成立**）；但若后人拿写者的 `files=2` 去比真树的 `files=192` 会造出假红 ⇒ 建议在册把该句写成「**缩小语料下**的成对读数；**不变量 ＝ 增量 `+1`／`+55`**」。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | `t12` 三条更正**是否引入新 `D-G` 号** | 已核（非 `NOINFO`） | 我现取：本件 `D-G` 匹配数 **`55`**，与 `ids` 增量同值；真树 `REPORTID` `ids=2034` 与 `t11` 时同值 ⇒ **未引入**。 |
| N2 | 本件在 `15:46:17` 那一刻的 **`ctime`** | **`NOINFO`** | **历史 `ctime` 无回溯源** —— `cp -p` 只保 `mtime`（`bak/…pre-t12` 的 `ctime` ＝ `cp` 当时的 `15:59:42.999097333`，不是源的）；`ctime` 不可由任何在册件重建。**旁证但不判定**：同一写者、同一手法、早 `2` 分钟的判据件 `mtime≠ctime`（差 `2.263`s）⇒ 写者的「`mtime=ctime` ⇒ 末次动作是 `>>` 追加」这一解释**值得再读一遍**（若本件也是 `temp+rename` 产出，两值应不同刻）。我**不判它假**。 |
| N3 | `t12` 的沙箱两腿**绝对值**可否在真树复现 | **不可**（已具名 I3） | 箱内只有 `2` 件语料（人为缩小）；真树 `192` 件 ⇒ 绝对值不可对拍，**增量**可。 |
| N4 | `bak/declared.tsv.pre-t6` 是否**真**是 t6 那一笔的改前态 | `NOINFO` | 备份无签名/无在册登记；我只能核其 sha16 与 `t6` 声称的改前值 `e242e3fbc5f76d77…` **逐位相同**（我现取 `sha256sum` ⇒ `e242e3fbc5f76d77`）⇒ **指纹相符**，但"谁在何时取的"不可核。 |
| N5 | 三条更正**内容层的措辞**（是否把"点读数"写成永恒值） | 部分具名 | `:171`-`:174` 都写了读时戳与"现取"；F3 那句引的**本件 `mtime`** 是**追加前**状态（现取已变 `16:00:01.423110762`）⇒ 建议加「**本笔追加之前**」限定（低危，见 §5-①）。 |
| N6 | 我未跑门禁/构建/应用 | **未做（不需要）** | 派单边界明写；本件四条判据全在只读件与沙箱上完成。 |

---

## §5 我的自伤与更正（如实记）

1. **我第一趟把 acceptance 的 `Verify` 原样跑出"全绿"**（`numstat` 空、`^-`＝`0`），若就此收工会得出**恒真的假绿**。**当场发现**该命令在"改动已提交"后**空转**，遂补做**提交级**与**备份前缀级**两层（§2-1）⇒ 记为本件 **I1**（非写者责任，属判据面的射程问题）。
2. **`printf '--- [%s] ---'` 自伤**：首轮打印行号时 `printf` 把 `---` 当选项，报错、那一圈输出没打印；我改用 `printf '%s'` 逐行 `sed -n` 重跑，四条新行**逐行原文**已取到（§2-1 表末行）。

---

## §6 收尾

- `$N` 内我**只写本件**；`build/MilBridge/P1-dg179-report.md`／`declared.tsv`／`KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`HANDOFF-NEXT.md`／两牙 **一字未动**（本件 sha16 全程 `a54d370e4f85db96`／`174` 行；`declared.tsv` 现取 `wc=224`／`ID=215`／`#=9`）。
- 沙箱与中间件全在 `~/wv82y/`（`%h==1`、无硬链接、**不落 `/tmp`**）；未跑门禁/构建/应用；未 `git add/commit/push`。
- ⏪ **追加（本件落盘之后 `16:06:2x` 现取，只补不删）**：① `REPORTID` 现取已变为 **`files=194 ids=2036 declared=215`**（我在 `§2-3` 记的是我读时的 `192／2034`）—— 增量 `+2` 的**逐件归因**：`?? build/MilBridge/P1-w2-report.md`（**W2 的**）＋ `?? build/MilBridge/P1-dg179-report-verify.md`（**本件自身，刚入语料**）⇒ **本件也吃 `*report*.md` 语料**（与 F2 的判定同向，可见化）。
- ⏪ **追加（同上）②**：`porcelain` 现为 **`18`** 行 ＝ 上表 `16` 行 ＋ `?? P1-w2-report.md`（W2）＋ `?? P1-dg179-report-verify.md`（**本件**）⇒ **`t12` 名下仍为零脏件**，结论不变。
- ⏪ **追加（同上）③**：两牙仍 `DEFREG=PASS declared=215 route_ids=215`／`REPORTID=PASS`（`declared=215` 未变）。

- **判词尾行**：`P1-DG179-REPORT-VERIFY: additive=[L1 ok-but-vacuous,L2 4/0 ok^-0,L3 prefix-cmp IDENTICAL] F1=[215/9/224 ok] F2=[192/2034→191/1979 +1/+55 ok] F3=[criteria mtime/ctime both ok;report mtime ok(backup);report ctime NOINFO] stamp=[15:59:43 < 16:00:01.423110762 ok] scope=[t12 dirty=0 all-dirty-are-W2/t7/t11] named=[I1,I2,I3] NOINFO=6`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `61db3f5ff8bd1822` ／ FULL `61db3f5ff8bd182213b191e8cdc5482ae4a198ceb14819fce2a54acbf53e5c3b` ／ `wc -l` ＝ 263 行（**不含**本行）／末次读取时刻 `2026-09-28T16:06:2x+08:00`／写入方式 **temp ＋ rename**。
