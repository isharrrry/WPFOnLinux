# T24 独立复验报告 —— 波 `#79`（九位逐键／步数与覆盖面／冻后两趟差异域／推送逐笔与哨兵／落地件判据）

**task `t24` / attempt `e1143902-0166-4344-b566-5b42cb419f4a`｜lane=`janitor`｜2026-09-28 01:51:39–01:53:35（+0800）**
仓 `$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜`HEAD=6a245bd5042598cef56f12a467b05618299562ec`｜kernel `6.8.0-138-generic`
**立场**：不复述 `t23`/`t20`/`t21`/`t27`/`t31` 的读数 —— 每一步我自己现取。**全程只读真树**；沙箱全在 `/tmp`（已删净）；进程只按 PID（本任务**未收任何进程**）；未用 `pkill/killall/pgrep -f`。
**资源现取（01:51:39）**：`df -Pk /` 第 4 列 = **91,699,328 KB**（≥5 GB ✓）；`SwapFree` = **1,515 MB**（≠0 ✓）。本任务**未走槽**（纯读、零长跑、无构建）。

---

## 0. 判词

# **verdict = `pass`**

五条验收项**全部通过**。三条落地件（`t19`／`t20`／`t21`）的**判据一条没被放宽**（见 §5 的机器证）。
**无阻塞 finding。** 附 3 条**非阻塞具名读数**（不改变 `pass`）：§3.3 的域间差异分类比主控描述更细；§4.2 的 `--tree` 用法坑；§6 的三件 record/`wave-freeze` 侧历史不入本件射程的边界。

---

## 1. 验收① 九位**逐键**三方对拍（现取，读取时刻 01:51:42–01:52:02）

**三方的字节来源（逐字）**
- **源 A（九位行）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:66`（`#79` 块；块头 `:7` 逐字 `# RE-FROZEN #79 —— ✅ **当前冻结基线**`）。
- **源 B（机读行）**：**同一块**的 `BASELINE tier=` 行 `:74–79`（**6 条**，`config=` 逐字同一串）。⚠️ **口径更正**：合同写"7 条 `BASELINE tier=` 行"，实测该块**是 6 条**；且机读行**按设计只覆盖 7 键**（`hbtextline_shim` 键名不同、`windowsbase`／`dwf` **本来就不在机读行里** —— 这一条由 `wave-freeze-consistency-check.py:494/504/523` 逐字自述）。
- **源 C（现取）**：权威路径表 = `build/MilBridge/tools/wave-freeze-consistency-check.py:104-115` 的 `NINE_PATHS`（与 `~/w21-verify/w27-freeze.py` 的 `NINE` 同源），逐件 `sha256sum | cut -c1-16`。
  （我按同一份表核了它的现取值：`pc`／`pf`／`win32shim` **三格与冻结块逐位相同** ⇒ 该路径表不是陈旧表。）

| 键 | 源 A 九位行 | 源 B `BASELINE tier=`（6 条逐字相同） | 源 C 现取 | 差 | 判 |
|---|---|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1`（5,028,208 B） | 0 | ✅ |
| `pc` | `38ae477949238306` | `38ae477949238306` | `38ae477949238306`（3,601,408 B） | 0 | ✅ |
| `pf` | `12fb36e7b0df1802` | `12fb36e7b0df1802` | `12fb36e7b0df1802`（6,123,520 B） | 0 | ✅ |
| `windowsbase` | `ed04eb65081c2d3a` | **（机读行按设计无此键）** | `ed04eb65081c2d3a`（1,111,552 B） | 0 | ✅（A↔C） |
| **`provider`** | `759ac1686e5ef87d` | `759ac1686e5ef87d` | `759ac1686e5ef87d`（104,448 B） | **0** | ✅ **不再错** |
| `win32shim` | `e8127a3d7128d417` | `e8127a3d7128d417` | `e8127a3d7128d417`（336,592 B） | 0 | ✅ |
| **`wic_shim`** | `f7b3026c8c019be2` | `f7b3026c8c019be2` | `f7b3026c8c019be2`（74,984 B） | **0** | ✅ **不再写死** |
| `hbtextline` | `921ba9c65e9fb3be` | **（键名为 `hbtextline_shim`，机读行有）** `921ba9c65e9fb3be` | `921ba9c65e9fb3be`（293,165 B） | 0 | ✅ |
| `dwf` | `0d25f64a7dbb4c78` | **（机读行按设计无此键）** | `0d25f64a7dbb4c78`（39,936 B） | 0 | ✅（A↔C） |

⇒ **九键零差**（每键都以**现取**为准的三方一致或"机读行按设计不含"。凡不等处**必须**两值同印——本趟**无一处不等**，故无红格）。
**主控点名的两格（`#78` 的错值格）逐条对照**：`#78` 块 `:139` 逐字 `provider` `609192a419d125f2`／`wic_shim` `f7b3026c8c019be2`；**`#79` 块** `provider` **`759ac1686e5ef87d`**（＝现取）⇒ **那一代的错值形态已不复现**。且 `#79` 块 `:68` 有一行**自述**该修法：`` `wic_shim` `f7b3026c8c019be2` → `f7b3026c8c019be2`（**`#79` 起由 `fmt` 键现取** —— 此前是写死的字面量，见 `D-G166`/`D-G149` 第二代）``。
**附加独立证（两哨兵）**：`/tmp/bridge-frozen.flag` 的九键 + `BASELINE=#79` + `BASELINE_SHA16=901619543b3d913b` 与上表**逐位一致**。

## 2. 验收② 冻结器写的块 ≠ 记录模板的字面量（现取，01:52:09）

| 件 | sha16 | 九位行所在 | 该行里的 `[0-9a-f]{16}` 裸值 | `{…}` 占位符 |
|---|---|---|---|---|
| `~/w186a/w78/w78freeze/w78-record.txt`（**`#78` 模板，故意保留**） | `e7abc00e76f08338` | `:67` | **2 个**：`609192a419d125f2`（provider，**已证错**）、`f7b3026c8c019be2`（wic_shim） | 9 |
| `~/w79c/w79-record.txt`（**本代 `#79` 模板**） | `17ca2241446d3000` | `:67` | **0 个** | **11** |

- `#78` 模板行逐字（节选）：``…`windowsbase` `{WB}`／`provider` **`609192a419d125f2`**／`win32shim` `{WSH}`／`wic_shim` **`f7b3026c8c019be2`**／…``
- `#79` 模板行逐字（节选）：``…`windowsbase` `{WB}`／`provider` **`{PRV}`**／`win32shim` `{WSH}`／`wic_shim` **`{WIC}`**／…``
- 占位符集合：`#78` = `{BR}{BRSZ}{PC}{PF}{PFSZ}{WB}{WSH}{HB}{DWF}`（**9**）；`#79` = **追加 `{PRV}`／`{WIC}`** ⇒ **11**。
⇒ **本代九位行不含任何硬编码 hex**：九位各自有占位符（`bridge` 连字节数都有 `{BRSZ}`）⇒ 冻结器**无法**再"写死那一刻的现取"。这正是 `#78` 那格 `provider` 的**结构性**成因被消灭的机械证。

## 3. 验收③ 步数三处 ＋ 覆盖面四处（全部现取，01:52:14–01:52:49）

**步数三处**
```
run_step 计数      = 55        （grep -c '^run_step "' verify-all.sh）
DECL 首行          = 55 gen=#79 （# VERIFYALL-STEPS-DECL:）
STEP-NAMES 名字数  = 55        （尾四项 = ROOT-ENTRIES | WIRING-CLOSURE | RETIRED-PATH | REPORT-ID-DOMAIN）
VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=3c80498ab2896955
```
⇒ **三处一致（55/55/55）** 且自洽器同趟 PASS。

**覆盖面四处**
```
[42] 步本体（verify-all.sh:1179）= run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 225
fp_inputs() 现取件数（生产管线 ~/w-infp-at.sh n）= 225
[42] 实跑  = FP_MANIFEST_TEETH=PASS reason=ok files_n=225 files_n_uniq=225 blank_n=0 shape_bad=0 dup_n=0 declared_expect=225
              FP_MANIFEST_STEP_RC=0 names_n=225 expect=225
```
⇒ **四处一致（225）**。⚠️ `verify-all.sh` 里另有 7 个 `--expect` 属于**别的步**（12/172/18/192/194/205/219 是历史口径句里的记载值），**不是**同一条命令的多个值 —— 我只认 `[42]` 那一条。

## 4. 验收④ 冻后两趟差异域 ＋ 推送逐笔 ＋ 两哨兵

### 4.1 日志事实（现取，01:52:21）
| 项 | post1 | post2 | 判 |
|---|---|---|---|
| 文件 | `~/w79-close/logs/w79-post1-20260928-011239.log` | `~/w79-close/logs/w79-post2-20260928-012847.log` | — |
| `mtime` | `2026-09-28 01:28:47.756` | `2026-09-28 01:44:43.050` | **均 > 冻结点** `01:12:39.371`（`w79-freeze.log` mtime；`w79-POST.done` 01:12）✓ |
| 结论行 | `步骤通过 55  ❌ 失败 0` | `步骤通过 55  ❌ 失败 0` | **两趟各 55 / 0 失败** ✓ |
| 大小／行数 | 21,102 B / 240 行 | 21,102 B / 240 行 | 同长 |

⚠️ **仪器陷阱（具名）**：结论行里的 `❌` 是**标签对的字面符号**（`步骤通过 N  ❌ 失败 M`），故 `grep -c '❌'` **假阳 1**；判失败**必须**看 `失败 0`。

### 4.2 两域各自的数（先写域，再写差异 —— 本波硬要求）
**归一化规则（逐字，机器执行）**
```
N1  (w34-framepresence-)\d{6}          → \1<T>      时间戳帧目录
N2  (w37-tpm-)\d{6}                    → \1<T>      时间戳第三方位
N3  (tline-gate-)\d{8}-\d{6}           → \1<T>      时间戳门禁 outdir
N4  (/tmp/[A-Za-z0-9_.-]+\.)[A-Za-z0-9]{6} → \1<R>  mktemp 随机后缀
N5  \b(mem_mb|avail_gb|avail_kb|bytes|wall_s|magenta_frames)=\d+ → \1=<N>  资源/读数键
N6  \b20\d\d-\d\d-\d\d[T ]\d\d:\d\d:\d\d → <TS>
N7  \b\d\d:\d\d:\d\d\b                 → <T>
```

| 域 | 抽取域定义 | A | B | 差异行总数 | 环境/标签类 | **读数类** |
|---|---|---|---|---|---|---|
| **域①** | **仅** `· 自报口径` 行 | 95 | 95 | **10** | **9** | **1** |
| **域②** | **全日志逐行** | 241 | 241 | **14** | **11** | **3** |

**域① 读数类逐条（1 条）**：`ALIAS` 的 `wall_s=4.86 → 5.53`（**本步自身的耗时**）。
**域① 环境/标签类逐条点名（9 条，归一化后逐字相同）**：`TLINE_GATE`(`outdir` 时间戳)｜`COLUMN_FLOOR_SELFREPORT`(`outdir` mktemp)｜`FRAMEPRESENCE`(`dir` 时间戳 ＋ `magenta_frames`)｜`THIRDPARTY_BUILD`(`log` 时间戳)｜`THIRDPARTY_IMAGE`(`path` 时间戳)｜`THIRDPARTY`(`dir` 时间戳)｜`DISK_HEADROOM`(`avail_gb`/`avail_kb`)｜`R_GATE`(`mem_mb`)｜`NULBYTES`(`bytes`，289,497,447→289,504,145)。
**域② 读数类逐条（3 条）**：`L2 HEAVYSLOT=MEMOK avail=7532MB→7433MB`｜`L194 ALIAS wall_s=4.86→5.53`（＝域①的那条）｜`L240 HEAVYSLOT=RELEASED … held=968s→955s`。
**域② 环境/标签类（11 条）**：8 条路径/目录/日志标签 ＋ 2 条时间戳行 ＋ 1 条其它。

**结论句（按本波要求形态）**：
> 归一化时间戳后，**域①**（`· 自报口径` 域）差异 = **读数类仅 1（`ALIAS wall_s`）** ＋ **环境/标签类 9**（逐条点名见上）；**域②**（全日志域）差异 = **读数类仅 3**（`HEAVYSLOT avail`／`ALIAS wall_s`／`HEAVYSLOT held`）＋ **环境/标签类 11**；除这两类外**逐字相同**。

🔎 **一条比主控描述更强的机械证**：主控说"域①（判词行域）唯一读数类差异 = `THIRDPARTY frames`（42↔43）"。我现取**两趟的 `THIRDPARTY` 行 `frames=42` 逐字相同**（差异只在 `dir=`），`FRAMEPRESENCE` 两趟也**同为 `frames=80`**。⇒ **产品级/判据级帧计数两趟零差**；那 42↔43 在那对日志里**不存在**（应是别的一对或更早一趟）。**这不是主控错**，而是"抽取域/日志对没写清就必然对不上"（`D-G138`）的又一现场例。

### 4.3 推送逐笔（现取，01:52:41–01:52:44）
```
$ git log --oneline d2dec07..HEAD     ⇒ 6 笔（count=6）
  6a245bd / 993eb5d / f4c93e5 / 3b5af06 / 192f54e / 3c302ce
$ git fetch origin feat-Linux:refs/remotes/origin/feat-Linux
  1fe6cec..6a245bd  feat-Linux -> origin/feat-Linux
$ git rev-list d2dec07..HEAD | while read c; do git merge-base --is-ancestor $c origin/feat-Linux; done
  6 笔**全部** ancestor_of_remote=YES，且逐笔 `^{tree}` 对象在本地**均 present**
$ git ls-remote origin refs/heads/feat-Linux ⇒ 6a245bd5042598cef56f12a467b05618299562ec
$ local HEAD = 6a245bd5042598cef56f12a467b05618299562ec ；两树对象同一：ecae182ab8540aee0543d17e39c971fd6cde39a6
```
⇒ **`d2dec07..HEAD` 全部 6 笔都在远端**（逐笔 ancestry ＋ 对象在场 ＋ 远端 tip == 本地 tip ＋ 两侧 tree 同一）✓
**两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；两件 `sha256|cut -c1-16` 均 **`7e3aa8fa47fc0087`**；内容 `WAVE=w79-freeze`／`BASELINE=#79`／`BASELINE_SHA16=901619543b3d913b` ✓

## 5. 验收⑤ 三道落地件**判据有没有被放宽**（独立判断）

### 5.1 `--expect` 是不是"跟着现取走"的假牙 ⇒ **不是**（我自己跑反极性）
```
$ bash build/MilBridge/tools/fp-manifest-step.sh --expect 224      # 现取 225
FP_MANIFEST_TEETH=FAIL reason=files-n-mismatch files_n=225 expect=224 delta=1（件数对不上 ⇒ …**形状可以完全合法**，只有这一格看得见）
FP_MANIFEST_STEP_RC=1   rc=1                                      ← 真牙
$ bash build/MilBridge/tools/fp-manifest-step.sh --expect 225      ⇒ PASS rc=0
```
且 `verify-all.sh:1179` 的 `--expect 225` 是**行内硬编码常数**（该行**不读** `close-wave.sh`／不读现取）⇒ 满足"另一把尺"的要求。**未放宽。**

### 5.2 四颗牙的 `--selftest` 与**红腿是否被真跑**（现取，01:52:54–01:53:35）
| 牙 | sha16 | `--selftest` | **其中 `expect_rc≠0` 的腿数** | 真树现读 |
|---|---|---|---|---|
| `root-entries-allowlist-check.sh` | `d050d78198e6093c` | **18/18 PASS** | **11**（N1/N1b/N2/N3/N3b/D1/D2/D3b/N4 各 `rc=1` 点名；N5/N6 `rc=3 NOINFO`） | `ROOT_ALLOW=PASS examined=22 tracked_n=22 worktree_n=25 allowed_n=25 unknown_tracked=0 unknown_fs=0 rc=0` |
| `wiring-closure-check.sh` | `a1ae1257ffd2638e` | **11/11 PASS** | **8**（N1/N2/N3/N4/N5/N6/N7 各 `rc=1` 并**点名 rule=**；N9 `rc=3 NOINFO`） | `WIRING_CLOSURE=PASS steps=55 jaws_n=52 undeclared=0 reasonless=0 fails=0 rc=0` |
| `pkg-src-retiredpath-check.sh` | `d54a5a14c1934bac` | 8/8 PASS | 3（含 `未入册号 ⇒ FAIL 并点名 file:line:id`） | `RETIREDPATH=PASS mode=tree files=228 hits=3 code=0 declared=3 self_skip=1 needle=wpf-linux-20260906` |
| `report-id-domain-check.sh` | `e1ed9a71200a20a9` | 7/7 PASS | ≥3（`未入册号`／`册内删一条⇒点名 D-G1`／`要求成条而册无条目`，均 `rc=1`） | （t27 步内） |

**我自造的注入腿（不是读它的 selftest 当判据）**：`/tmp` 里 `git init` 的沙箱树 ＋ 放一个未白名单的根级件 ⇒
```
ROOT_ALLOW=FAIL root=/tmp/t24-git-XXXX allow_src=embedded examined=2 unknown_tracked=2 unknown_fs=2
   unknown= not-in-allowlist.txt root-entries-allowlist-check.sh
rc=1
```
⇒ **牙真会红并逐个点名**；同牙在真树 `PASS`、在缺 `git` 的非仓沙箱 **`NOINFO reason=not-a-git-tree`（不判绿）** ⇒ 三态齐全。
⇒ **`t19`／`t20`／`t21` 的判据一条都没被放宽**：腿数**只增不减**（root-entries 10→**18**、wiring-closure 11、retiredpath 8、reportid 7），红腿**真跑且真红**，`NOINFO` 档**仍在**。

## 6. 我没能证明的 / 边界（逐条）

1. **合同写"7 条 `BASELINE tier=` 行"，实测该块是 6 条**；机读行按设计覆盖 7 键（键名 `hbtextline_shim`；`windowsbase`／`dwf` 无）⇒ 我用 `#79` 块的 6 条 ＋ 该牙自述的键映射核的。**这不是缺失，是合同口径与实现口径的差**，已具名。
2. **`THIRDPARTY frames 42↔43` 在那对日志里不存在**（两趟同为 42；`FRAMEPRESENCE` 同为 80）⇒ 主控那条"唯一读数类差异"在本对日志上**不成立**；我**没有**去找它出自哪一对（射程外）⇒ 记 `NOINFO`。
3. **`witness` 之外的三个 record 侧/牙侧件**（`w79-record.txt`／`w78-record.txt`／`wave-freeze-consistency-check.py`）**只在 sha16 与九位行层面核过**，未逐字复核其全文（射程外）。
4. **`retiredpath --tree` 的沙箱红腿我未能构造成功**：`--tree` 是**旗标**、目录由 `--root` 给（`pkg-src-retiredpath-check.sh:66/67`），但沙箱树仍报 `NOINFO reason=no-paths-file`（真树报 `PASS … files=228`）⇒ 该腿**以"真树正极 × 4 牙 selftest 红腿 11+8+3+3 条"替代**，**未**独立构造 `--tree` 反极性 ⇒ 记 `NOINFO`（**不影响 §5.1 的 `--expect` 真牙证**）。
5. **`~` 根 `w79c/w79-record.txt` mtime `09-27 12:19`** 早于本波（`09-28 01:12` 冻结）—— 它是**模板**（占位符化即本代修法），非本波产物；我按模板核的。
6. **我的唯一写入**是本报告；真树其余零写入（未碰 `ACCEPTANCE-BASELINE.md`／`verify-all.sh`／`close-wave.sh`／`~/w21-verify/**`）。全部沙箱在 `/tmp`，已 `rm -rf` 删净。

## 8. 追加：主控 01:45 两条收紧判据（标记／哨兵）—— 判别式成立，实例已具名

⚠️ **总纲**：主控 01:45:38 的三条现取（未推送／哨兵写 `#78`／标记不含 `push_rc`）**在我读完之前就被写者自己推翻了**。我逐格带**我读的时刻**报，不照抄、也不把"现在绿了"读成"机制自己发现过陈旧"。

### 8.1 标记存在 ≠ 链成功（成立）
`~/w79c/logs/W79_PRE2END.done`（我读 01:46:07，434 B/6 行）**四个字段、两种状态**：`MARKER=W79_FREEZE2END`（对状态**零信息**）｜`date=2026-09-28T01:44:43+08:00`｜`freeze_last=`（只盖②冻结、**不盖④推送**）｜**`stop_line=` 空**｜`push_rc=9 note=…④被守护拦停…（**01:46:06 追加**）`。
**根因（机读）**：驱动 `~/w79c/bin/w79-freeze2end.sh` 逐字写 `stop_line=$(grep -aoE 'STOP=[a-z-]+' $OUTF|tail -1)`，而本轮④的真实输出（`w79c/logs/w79-freeze2end.driver.log` 尾）**没有 `STOP=` 这个 token**：
```
PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list: build/MilBridge/tools/boundary-decl-check.sh ⇒ 停手，不推送
PUSH_RC=9
```
⇒ 抓到空；姐妹链能抓到（`w79c/logs/w79-pre2end.log` 里是 `STOP=freeze-red`）⇒ **grep 形态与输出格式不匹配**（结构性，非偶发）。
**⇒ 判别式（照主控收紧判据）**：判"链是否走完"**只认 driver 尾 `PUSH_RC=` ＋ 远端/本地对比**；本实例 = 标记**在** ∧ `stop_line` **空** ∧ 当时**未推送** ⇒ 「标记字段与该状态**不相称**」。

### 8.2 哨兵 `cmp` 相同 ≠ 当代（成立）
两哨兵（我读 01:50:48）：`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag`，**279 B、sha16 均 `7e3aa8fa47fc0087`、`cmp` IDENTICAL**，内容 `BASELINE=#79`／`BASELINE_SHA16=901619543b3d913b`（＝现场 `ACCEPTANCE-BASELINE.md` 现算值）／`WAVE=w79-freeze` ⇒ **主控收紧后的内容锚现已兑现**。
**🔴 决定性的是 mtime**：两件 mtime = **`2026-09-28 01:46:12.730`／`.729`** ⇒ **在主控 01:45:38 取数之后 ~34 s 被写者刷新**。⇒ **那一刻 `cmp IDENTICAL` 为真而内容是 `#78`** —— 正是要禁的组合（`D-G137`／`D-G140` 同族）。**如实记法**：判据现取已兑现；但那一刻它是未兑现的，**两个时刻都具名，不因现在绿了记成"一直绿"**。
九位独立核（我读 01:51:00）：`PC 38ae477949238306`／`PF 12fb36e7b0df1802`／`WB ed04eb65081c2d3a`／`WIN32SHIM e8127a3d7128d417`／`DWF 0d25f64a7dbb4c78` **5 键＝现场**；`HBTL`／`WIC`／`PROVIDER` 三键**本机对应产物路径不存在** ⇒ 记 `NOINFO`（路径不可得，**非不符**）。

### 8.3 推送状态（我读到的已不是"未推送"）
| 读数 | 主控 01:45:38 | 我 **01:46:14** |
|---|---|---|
| 本地 `HEAD` | `993eb5d` | **`6a245bd5042598cef56f12a467b05618299562ec`** |
| `ls-remote feat-Linux` | `993eb5d5…` | **同 `6a245bd…`** ⇒ 本地==远端 |
| `porcelain` | 34 | **3**（全 `??`） |
`~/w79c/logs/w79-push-run2.log`（mtime 01:46）逐字含 `PUSH_LIST_GAP=PASS`／`staged=31`／`FF=yes`／`993eb5d..6a245bd HEAD -> feat-Linux`／`REMOTE_PER_COMMIT=PASS n=1`／`SENTINELS-IDENTICAL` ⇒ **补清单后重推成功**；`boundary-decl-check.sh` 那条拦截是**真阳性**（不是把牙改松）。

**三条可复用判别式**：① 标记存在 ≠ 链成功（认 `PUSH_RC=` ＋ 远端/本地）；② 哨兵 `cmp` 相同 ≠ 当代（认 `BASELINE=`／`BASELINE_SHA16=` 内容锚）；③ **凡"字段/文件长相"被当状态的地方，都要问"它是谁、在什么时候写绿的"** —— §8.1／§8.2 两条实例的答案都是「**写者在我取数之后手工改绿的**」。

> 更早（`t24` 未解锁时）的两格只读复算落在仓外 `~/w-t24-addendum-evidence.md`（sha16 `2794a0b89caf108f`，18,569 B）：锚漂移 = 2 键（`CS`／`AB`）、`DEFREG_DECLDRIFT` 进不了冻后日志（四份 post 日志 `grep -c` 全 0）。

## 9. 产出件与自报 sha16

| 件 | sha16 | 字节 | 读取/生成时刻 |
|---|---|---|---|
| `$N/build/MilBridge/T24-report.md`（本件） | 旁车件 `~/w-t24-report.sha16` 承载（自指剔除口径 ＋ raw 整体值 ＋ 字节数） | 见旁车件 | 2026-09-28 01:55 |
| （本任务的只读证据附录，仓外）`~/w-t24-addendum-evidence.md` | `2794a0b89caf108f` | 18,569 B | 2026-09-28 01:5x |

**权威 sha16**：合同 `sha256sum ~/w-janitor-final-report.md` 形态对**本件** = `sha256sum build/MilBridge/T24-report.md | cut -c1-16`，现取见旁车件 `~/w-t24-report.sha16`（正文不含自 sha 数字，避免自指恒动）。

> SELFSHA 现取（正文不含自 sha 数字，以免自指恒动）：`sha256sum build/MilBridge/T24-report.md | cut -c1-16` ⇒ 见 `~/w-t24-report.sha16`
