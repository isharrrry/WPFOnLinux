# P1-W31 · 牙 `pts-gap-count-check.sh` 扫描形状收窄报告（`t106`／`scribe`）—— 历史行不承担现值；现值位写错必红

写者 `scribe`（`t106` attempt 2／`8422af78-d17c-4b8d-9bbf-2e47ffc805ea`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T01:2x–02:3x+0800`
**一切读数现取自算**。本件**不构建、不跑腿、不占显示位、不跑整趟门禁**；只改**牙**＋文档。
**写域** ＝ `build/MilBridge/tools/pts-gap-count-check.sh`（**覆盖面内**）＋ `docs/ROUTES.md`（`§15af` dated 追加）＋ 本载体（新建）＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。

## §0 一句话

把 `one()` 从「**整件** `grep` 后逐值对拍」改为「**逐行分类 ＋ 逐处对拍**」：**自引旧代工件的历史行**（行内 `.<so> <16hex>` ≠ 现盘 `so16`，或 `<N> 导出` ≠ 现盘 `exports`）**不参与现值判定**（在场不红，只印 `PTSGAP_HISTORICAL=n=…`）；**其余命中行逐处对拍**（写错 ⇒ 必红 `SITE-DRIFT <件> <字段> want=… got=…`）；**某字段在全树只剩历史行** ⇒ `PTSGAP=NOINFO reason=current-site-absent fields=…`（`rc=3`，**绝不当绿**）。⇒ 修前 `rc=1`＋三条 `SITE-DRIFT … want=96/84/89 got=97/85/91` ⇒ 修后 **`rc=0`／`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567`**。同趟另修掉本席第一版引入的 **4 处 `DQ-BACKTICK`**（`QUOTE-TRAP` 从 `FAIL traps=4` ⇒ **`PASS traps=0`**）与**一处性能退化**（52.6 s ⇒ **0.83 s**）。

## §1 现取的「现值出处」口径（读现件 ＋ 同族牙后写死）

- 现件里「现值」有**两条来源**：① **现算**（`check-shim-coverage.py --tier all` ⇒ `tool`；`dead`／`artifact` 抽取；`ops`＝`tool−dead−artifact`；`impl`／`so16`／`exports` 取现盘件）——**这是判定基准**；② **声明件** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 的 `# PTSGAP-DECL:` 行 —— 与①**逐字段相等**才算自洽（`DRIFT <k>` 红，`t106` 未动这段）。
- **复述位**（"现值出处"的**文字面**）＝ 6 个件（`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`／`docs/unimplemented.md`）里的 17 条**内容锚 ERE**（`one()` 调用表）。本件**只改这些复述位的扫描形状**，**不改**判定基准、**不改**任何 ERE 本身。
- **历史行 vs 现值行**（**内容锚，不看行号**；逐字写进代码）：一条命中行是**历史行** ⇔ **自引了与现盘不同的工件世代**：① 行内出现 `.<so> <16hex>` 且该 16hex ≠ 现盘 `so16`；② 行内出现 `<N> 导出` 且 `N` ≠ 现盘 `exports`。⇒ 历史行的数字**不参与现值判定**（它描述的是**它引用的那一代**＝裁定九）；其余命中行**逐处**参与。
- **判定的域 ＝ 全树逐字段**（不是"每件每字段"）：某件某字段只剩历史行 ⇒ 只印 `SITE-HISTORICAL-ONLY <件> <字段> hist=n`（**告示**）；**只有**当某字段**在全树**都没有现值位时 ⇒ `PTSGAP=NOINFO reason=current-site-absent fields=…`。**理由（现取）**：`samples/…/KNOWN-DEFECTS.md` 的 `ops`／`impl` 两字段现值位**本就不在该件**（现值由 `pts-gap-decl.txt` 侧同步）⇒ 若按"每件每字段"判，真树会**永久 NOINFO**，牙同样没有牙。
- **没有**放宽到"整件不扫"（`t98` 的教训）：同一件内历史行/现值行**逐处分别归类**；**也没有**采用"只扫第一处"这类脆弱口径（那会让"第二处写错"漏网）。

## §2 改动面（逐件现取）＋ 同趟三处修正

| 件 | 写前 | 写后 |
|---|---|---|
| `build/MilBridge/tools/pts-gap-count-check.sh` | `e490ab4ea9fea678`／338 行／755 | **`920326e9242f5fdd`／440 行／755**（`git diff --numstat` ＝ `108 6`） |
| `docs/ROUTES.md` | `116955a1d915ca9f`／883 行 | **`8e9b7f4b8f46db34`／890 行**（`§15af` dated 追加 7 行；写前像→现值 `diff` 的 `^<` 计数 ＝ **0** ⇒ 纯追加） |
| `build/MilBridge/HANDOFF-NEXT.md` | 647 行 | **649 行**（`cell=#1` **一行**；`ts=2026-09-29T02:32:41.309622423+0800`） |
| 本载体 | —— | 新建 |

**同趟三处修正（都在同一个牙里，如实记）**：
1. **`DQ-BACKTICK`×4（本席第一版引入，`QUOTE-TRAP` 现取红）** —— 双引号内的反引号会被 shell 当**命令替换**执行（本仓老族），现场后果：那两条 `echo` 里的 `` `…` `` 段被**吃成空**。⇒ 改成**具名变量拼装**（`printf` 的 `%s`），**不用** `eval` 绕过。成对：`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=4`（`line=331 col=158/199`、`line=429 col=168/173`）⇒ **`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203`**。
2. **性能退化**（同趟发现）—— 第一版 `one()` 对**全件每一行**跑 `grep` ⇒ 本牙从 `<3 s` 变成 **52.6 s**（`real 0m52.597s`）。⇒ 改为**只喂命中行**（`done < <(grep -E "$re" "$p")`）⇒ **`real 0m0.828s`**。
3. **字段集合去重缺陷**（同趟发现）—— `lab_add()` 的 `case` 写成了「比变量名」⇒ `HISTONLY` 重复累积（`(d)` 夹具曾印 `fields=impl impl impl impl impl impl`）⇒ 改为 `${!1}` 按名取现值 ⇒ 现印 **`fields=impl`**。
**行为不变证据**：三处修正**之后**，同一夹具／同一真树的 `PTSGAP` 判词与 `rc` 与修正前**逐字相同**（真树：`rc=0`／`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567`；内建自测 **`PTSGAP_SELFTEST=PASS pass=12 fail=0 legs=12 must_red=7`**）。

## §3 两极化（**缺一即作废**）—— 4 条**真件**夹具 ＋ 内建自测 3 条新腿

**真件夹具法**（**仓外** `/tmp/t106-fx*`，**用完删**）：把 6 个复述位件与 `docs/WAVE66-PREREGISTRATION.md` 复制到仓外树，`DECL` 指向**现盘声明件**，`R` 仍指针仓根 ⇒ `LIVE` 现算不变、**只动复述位**；辅助轨 `PTSGAP_CITED_STRICT=0`（夹具树里没有那些被引用的 `bash …sh`，否则 `CITED-MISSING` 会**抢戏**成红——真实树仍 `strict=1` 且 `CITED=PASS`）。

| 极性 | 夹具（相对 (a) 的差别） | 现取判词 |
|---|---|---|
| **(a) 历史行在场 ⇒ 不红** | 原样副本（历史行 `97/85/91` ＋ 现值位 `96/…`） | **`PTSGAP=PASS tool=96 … ops=84 impl=89 so16=a2de5ff2b667f33f exports=567`** ＋ `SITE-HISTORICAL-ONLY …/KNOWN-DEFECTS.md ops hist=1`／`impl hist=1` ＋ `PTSGAP_HISTORICAL=n=1` |
| **(b) 现值位写错 ⇒ 必红并点名** | `KNOWN-DEFECTS.md` 现值位 `工具口径 **96** ⇒ **95**` | **`SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md tool want=96 got=95`** ＋ `PTSGAP=FAIL …`（`rc=1`） |
| **(c) 历史行与现值位同时写错 ⇒ 仍必红** | 再叠 `历史行 97 ⇒ 98` | **同 (b)**：`SITE-DRIFT … tool want=96 got=95` ＋ `PTSGAP=FAIL` ⇒ **不因历史行在场而放过现值位** |
| **(d) 现值锚缺失 ⇒ 响亮 NOINFO（绝不当绿）** | 把**所有** `实现口径` 命中行都改写成**历史行**（追加旧代 `.so` 引用） | **`PTSGAP=NOINFO reason=current-site-absent fields=impl`**（`rc=3`） |

**内建自测新增三腿（`--selftest`，与真件夹具同形、随牙长存）**：`H1 历史行在场（自引旧代 ⇒ 不参与）不得假红 ⇒ PASS`／`H2 现值位写错（必须红并点名）⇒ FAIL（含 `SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md tool`）`／`H3 某字段只剩历史行 ⇒ NOINFO（含 `reason=current-site-absent`）`⇒ 总计 **`PTSGAP_SELFTEST=PASS pass=12 fail=0 legs=12 must_red=7`**（原 9 腿，`must_red` 6 → 7）。
**H3 夹具踩过的坑（如实记）**：H3 起初 `FAIL` 而非 `NOINFO` —— 根因是该夹具**没备 `WAVE66-PREREGISTRATION.md`**，而 `W66` 锚取自 `$SITES` ⇒ `FIELD-UNREADABLE live:w66pre16` **抢戏**成红。⇒ 夹具补 `cp -a "$SITES/docs/WAVE66-PREREGISTRATION.md" "$h3/docs/"` 后转 `NOINFO` ✓。

## §4 同趟实证（同一棵树；`so16` 逐次取值不同＝`t103` 正在改 `src/**`）

```
修前（`ts≈01:2x`，`so16=5c2097d35cd89749`）：rc=1
  SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md tool want=96 got=97
  SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md ops  want=84 got=85
  SITE-DRIFT samples/WpfFeatureProbe/KNOWN-DEFECTS.md impl want=89 got=91
  PTSGAP=FAIL tool=96 dead=11 artifact=1 ops=84 impl=89 so16=5c2097d35cd89749 exports=567
修后（`ts≈02:3x`，`so16=a2de5ff2b667f33f`）：rc=0
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md ops hist=1（现值位当在别件 …）
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md impl hist=1（现值位当在别件 …）
  PTSGAP_HISTORICAL=n=1（自引旧代工件的历史行命中数：不参与现值判定，见裁定九）
  PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567 root=…
```
⇒ 「修前必红（且点名文件＋两个数）」与「修后不假红」**成对成立**；`so16` 两值不同是 `t103` 的并发改动，**不是**本件改动面（本件零碰 `src/**`）。

## §5 不变量 / 指纹 / 已接线牙（现取）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `VERIFYALL-STEPS-DECL: 62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
指纹：本席现取 fp ＝ b59779a389683b86c1cde70f9a3c797f4728fc7228983fe4747ced5717eb35cb（ts=2026-09-29T02:32:20.010346116+0800）
      ⇒ 同趟已按纪律**纯追加** `cell=#1` 一行（`docs/ROUTES.md` 与载体**不在覆盖面内**；`tools/pts-gap-count-check.sh` **在**）：
      `HANDOFF-NEXT.md` 647→649 行（`t103` 在 02:23:23 也追加了一行，**不是本席**）；登记后 `HANDOFF_MV=PASS cells=9 equal=8 mismatch=0`。
      ⚠️ `t103` 与本席轮流顶动 `cell=#1` ⇒ 队长已明示「本波收口统一对齐」⇒ 本席**只登记一次**（`ts=02:32:41.309622423+0800`），不追写。
牙：REPORTID=PASS files=245 ids=2201 declared=224（本载体落盘前）｜SHELL_QUOTE_TRAP=PASS traps=0（**修前 traps=4**）｜PIPEFAIL_SIGPIPE=PASS undeclared_hit=0
    HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 ｜ SENTINEL-SPEC 12 项 SSC_VALUE=PASS
    **STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（0 HIT）**（修前该趟唯一 HIT 名单里就有 `QUOTE-TRAP`）
    DEFREG=PASS declared=224 route_ids=224（**`DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD`** 仍未闭 ⇒ 须持 `--emit` 权限者同趟刷新；本件写域不含它）
```

## §6 未做项 / `NOINFO` ＋ 边界自证 ＋ 备份面

- **未做①（`--emit` 刷新）**：写域外 ⇒ 只点名 `DEFREG_DECLDRIFT`。
- **未做②（`KNOWN-DEFECTS.md`／`src/**` 的现值同步）**：**边境硬条款明禁** ⇒ 本件**未动**（历史行与现值出处都保持原样；本件只让牙**不再**因历史行在场而红）。
- **`NOINFO`（历史行的"内部自洽"）**：本件**不**校验历史行与其自引旧代工件的数字是否逐项相符（那需要历史声明件的全世代读数）⇒ 「历史行数字与其引用代的相符性」**未验**（如实记；裁定九只要求它不承担现值职责）。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有 ` M build/MilBridge/tools/pts-gap-count-check.sh`、` M docs/ROUTES.md`、` M build/MilBridge/HANDOFF-NEXT.md`（仅 `cell=#1` 一行）、`?? build/MilBridge/P1-ptsgap-scan-scope-report.md`；`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`src/**`、`build/PresentationFramework.Linux/**`、`verify-all.sh`／`close-wave.sh`／哨兵／`tests/PtsPagesProbe/evidence/**` **零碰**；未构建／未跑腿／未占显示位／未跑整趟门禁／未 `git add|commit|push`；夹具**全部仓外**（`/tmp/t106-*`，含 4 个真件夹具树、2 个脚本），**收尾删净**。
- **备份面 ≡ 改动面（第 `29` 条）**：改动面 3 件（+1 新建无前像），备份面 `~/w281-scribe/bak/{pts-gap-count-check.sh,ROUTES.md,HANDOFF-NEXT.md}.pre-t106`（写前逐件 `stat -c %h` ＝ **1** ＋ `cp -p`；`cmp` 与写前件逐件相同）。
- **第 `30` 条**：本件**不引用任何进程内状态读数**（无自检进程史依赖；`--selftest` 是**批式**判词，不属"进程内状态敏感仪器"）⇒ 该条不产生引用义务。
- **同族的"现值位"提醒（供队长排队）**：`README.md`／`win32_classification.c`／`unimplemented.md`／`HANDOFF-NEXT.md` 的现值位由**各自的写者**同步（本件只改**扫描形状**，不改它们的数）——若它们落后于现值，本牙会**必红并点名**（这正是 (b) 极性的日常面）。

**本件自证**：`head -n -1 build/MilBridge/P1-ptsgap-scan-scope-report.md | sha256sum | cut -c1-16` ＝ 024691a2ff95de2c（本行系末行；上列各节即被哈希的全文）
