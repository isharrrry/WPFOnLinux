# `VFinal` 独立验收报告 —— 全环最终验收（`t15`）

- 任务：`t15`（`verification`，attempt 1，`attempt_id 1b7e3b33-ee96-41bd-87f6-26091f188f28`）｜执行人：`verifier`
- 现取窗口：**`2026-09-28T12:37:55 – 13:14+08:00`**（每格另注时刻；**没有一格照抄派单或任何车道的数字**）
- **判词：`needs_revision`**（findings **F1／F2**，两条都是**一行 dated 更正**级；其余 6 条验收**全过**；本报告的推送与"最后动作＝哨兵"两件都已照做）
- 本件是全环**唯一**写入的验收件；`docs/ROUTES.md`／`README.md` 的更正**不在本件写域**（本件 `inScope` 为空，写入＝本报告 ＋ `HANDOFF-NEXT.md` 同节追加 ＋ 两枚哨兵）

---

## §0 判据与口径（**先写**；三态：`PASS`／`FAIL`／`NOINFO`，`NOINFO` 一律不当绿）

1. **哨兵形态（现取原文，13 行）**：十键 `SHA=`／`FP=`／`PC=`／`PF=`／`WB=`／`WIN32SHIM=`／`HBTL=`／`WIC=`／`PROVIDER=`／`DWF=` ＋ `WAVE=`／`BASELINE=`／`BASELINE_SHA16=`。
   - **九位 ＝ `SHA`＋`PC`＋`PF`＋`WB`＋`PROVIDER`＋`WIN32SHIM`＋`WIC`＋`HBTL`＋`DWF`**；**`FP` 是第 10 键，不属九位**。
2. **`FP=` 是 `BRIDGE_SRC_FP`，不是 `inputs_fp`**（哨兵里**没有** `inputs_fp` 这一格）：定义链 `build/close-wave.sh:602`（`FP_NOW2="$(bash build/bridge-src-fp.sh …)"`）→ `:686`（`printf 'FP=%s\n' "$FP_NOW2"`）。**拿 `infp` 的值去比哨兵 `FP` 即假红**。
3. **块件三格**：`docs/CURRENT-STATE.md:9` 的 `sha16=` 指的是**该行 `file=` 所指那一件**的哈希，不是 `CURRENT-STATE.md` 自身；对拍按 `gen` ＋ `file=` ＋ 该件 `sha16`。
4. **`只增不改` 引用口径**：文档里"报告 `sha16` ＋ 行数"这种引用，按**前缀快照**复算（`head -n <行数> | sha256sum`），不是整件哈希。
5. **本件与队长次序的一处偏差（如实声明）**：队长裁定的次序是「清点 → `HANDOFF-NEXT` 追加 → 报告 → 门禁 → …」。我把**门禁提到两笔写件之前**跑，理由＝契约 §二要求门禁跑在 `git status --porcelain` **为空**的静止树上（写件会立刻把 `porcelain` 变成非 0）。为补偿，我在两笔写件**之后**重跑了四个轻量面（`DEFREG`／`REPORTID`／`COLUMN_FLOOR`／`infp`）并证明**零位移**（§6 末）。

---

## §1 现场现取（起点核对）

| 项 | 我的现取 | 时刻 |
|---|---|---|
| `HEAD` | `1637dbc7059a3287f08757e4974f66c7103bbb11`（提交时刻 `12:54:09`） | 12:55:04 |
| 远端 | `git ls-remote origin refs/heads/feat-Linux` ＝ **同值**（逐字相同） | 12:55:04 |
| `porcelain` | **0** | 12:55:04／13:11:12 |
| 块件 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ＝ **`b96d4312565a3c49`**（1,224,932 B；4605 行） | 12:55:04 |
| `CS:9` | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ⇒ **三格自洽**（自身整件 `13077b52c938f8af`） | 12:55:04 |
| `#80` 块九位行 | `ACCEPTANCE-BASELINE.md:66`：`bridge 4e25e4b27d4d5ae1`（5,028,208 B）／`pc 5b6cfda3e12b84fc`／`pf b9a4f3a0e48e688d`（6,123,520 B）／`windowsbase 9e860cbeecb352e1`／`provider 7e8a217b4165a6b9`／`win32shim 6825dd7071387a46`／`wic f7b3026c8c019be2`／`hbtextline 921ba9c65e9fb3be`／`dwf c83be96f18759edc`；`BASELINE tier=` 6 行（`:74`–`:79`）同值 | 13:00:55 |
| 哨兵 | 279 B／`sha16=f2ab94d32b8e1e40`／`cmp` **IDENTICAL**／两枚 mtime `12:54:14.4023383`／`.4013383`（＝最后一笔提交之后 **5 s**） | 12:55:11 |
| 九位 ⇔ 哨兵（**门禁前**） | **9/9 SAME** | 12:55:11 |
| `BRIDGE_SRC_FP` | `d697b1e10ff48881`（`BRIDGE_SRC_N=78`）＝ 哨兵 `FP=` | 12:40:15／12:55:11 |
| `inputs_fp` | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`，`list` ＝ **226 行**（与 `GENS['#80']['infp']` 同 ⇒ 相对 `#80` 冻值**零漂移**） | 12:39:35／13:11:12 |
| 步数 | `grep -c '^run_step "' verify-all.sh` ＝ **55**（`verify-all.sh` ＝ `600274f130cfe913`） | 12:55:04 |
| 覆盖面 | `226`（`FP_MANIFEST_TEETH … files_n=226 declared_expect=226`／`WIRING_COVERAGE … coverage_n=226`／`infp list` 226 行） | 12:55–13:11 |
| 缺陷册 | `DEFREG=PASS declared=215 route_ids=215`｜`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`｜`REPORTID=PASS files=187 ids=1912 declared=215` | 12:56:44／13:02:03 |
| 声明锚 | `DECL-ANCHORS` 四键**逐件现取同值**：`KD=2152460b7e412352`／`CS=13077b52c938f8af`／`HO=a4d8ffcf4c37f6fe`（`handoff.md`）／`AB=b96d4312565a3c49` | 13:01:33 |

**起点对照（派单给的是"只作对拍"）**：派单写 `HEAD=8137240`、`declared=213` ⇒ 两条**均已过期**（现取 `1637dbc`／`215`）；派单写的块件 `b96d4312565a3c49`／`CS:9` `gen=#80`／`REPORTID=PASS`／`porcelain=0` **与现取一致**。

---

## §2 `docs/ROUTES.md` 逐行抽查结账表（**11 行**：全部 5 条原 `[Next]` ＋ 全部 3 条 `[MVP]` ＋ 3 行追加抽样）

抽取域＝`docs/ROUTES.md`（`709ab499060cd6db`，794 行，mtime `12:28:23`）。**判据：记号 ⇔ 我当场现取到的件／字段／`sha16`。**

| # | 行 | 记号 | 我的现取读数（件＋字段＋`sha16`＋时刻） | 判词 |
|---|---|---|---|---|
| 1 | `:320` `TASK-0740` | ✅ | `build/MilBridge/tools/wiring-coverage-check.sh` ＝ `fa356ae278497e07`（21044 B）；接线 `verify-all.sh:1201` `run_step "WIRING-COVERAGE"`；我单跑判词 `WIRING_COVERAGE=PASS run_step=55 wiring_n=53 coverage_n=226 missing_n=0 absent_n=0 allowed_n=0 examined=53`（13:01:53） | **成立**（牙在 ＋ 已接线 ＋ 判词真） |
| 2 | `:322` `TASK-0742` | ✅ | `parser-guard-check.sh` ＝ `750f1303ded9c2ed` ＋ 唯一声明 `parser-guard-decl.txt` ＝ `16f9c8c4bb2dd67c`；接线 `:1202`；判词 `PARSER_GUARD=PASS examined=8 sites_env=4 sites_parser=0 exempt_used=0 dynamic_n=4 fails=0`（13:02:03） | **成立** |
| 3 | `:325` `TASK-0744` | ✅ | `proto-attribution-check.sh` ＝ `62e46ff230f5c2cc` ＋ 语料 `proto-attribution-cases.tsv` ＝ `ebb775d21b225939`；接线 `:1203`（`--expect 18`）；判词 `PROTO_ATTR_GATE=PASS examined=18 mismatch=0 bad_expect=0 posctl=2/2 cut_and_pair=1`（13:01:53） | **成立** |
| 4 | `:326` `TASK-0745` | ✅ | 补丁形态已在车道：`~/w185a/w77/bin/patch745_e12.py` ＝ `cf9f65fe4fa4163b`、`…/out/w77base-patched-w27-freeze.recordform.py` ＝ `1328f1d0b9e7f912`、排练日志 `0745-rehearse-w77.log` ＝ `b4270a10bef828f6`（含 `ANCHOR ok=E1 hits=1`／`ok=E2 hits=1`／`ARM PATCHL FAIL … rc=5`）。**活冻结器现取** `~/w21-verify/w27-freeze.py` ＝ `7e3d0fecefa9f20c`：`grep -c 'def check_record_forms('` ＝ **0**、`E12-ORD` ＝ 0、`W27_RECORD_CHECK_ONLY` ＝ **1**（仅"排练口子"，`:1725-1727` 自述**不参与任何判据**） | **成立但须按行的限定语读**：该行逐字写着「**补丁形态**…本波只交补丁件 ＋ 排练读数，**未碰冻结器**」，且同件 `:756`（§15ad `F7`）已记 `E1+E2` **被主控回退**（`f9fb7bcac0353a61 → 6bf3c5c77eee8dd8`）⇒ ✅ 的正确读法是"**补丁与排练已交付**"，**不是**"冻结器已有该自检"（后者现取**不成立**） |
| 5 | `:329` `TASK-0747` | ✅ | 权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ `6825dd7071387a46`；`nm -D --defined-only … \| grep -c SHAppBarMessage` ＝ **1**（`000000000001f470 T SHAppBarMessage`）（13:00） | **成立** |
| 6 | `:175` `TASK-0007` `[MVP]` | 🔴 | 在册证据（`t55` 同趟落仓）：`tests/PtsPagesProbe/evidence/leg_23.env`＝`9fb8af8d6fdebb45`（`LEG k=23 alive=yes app_rc=143 magenta=50236 colors=843 … ink=428205`）／`leg_24.env`＝`afb1081916bd0d0d`（`… magenta=54826 colors=851 … ink=423547`）／`app_g1.log`＝`eb6af2e16ba2bcfb`（3×`entry=LoCreateContext`）。**我自己重算了两张在册 PNG**（`shotstat.py`，13:00:04）：`k23.png` `colors=843 magenta=50236 ink=428205`｜`k24.png` `colors=851 magenta=54826 ink=423547`｜`boot.png` `colors=386 magenta=0 ink=480000` | **成立**：洋红占位**非 0** ⇒ 23／24 两页**仍未真排版** ⇒ `🔴` 不是"没读数"，是"读数**仍指向未实现**"（行内"必死 `rc=134`"是旧读数、已由 dated 行取代，同件 `:176`／`:386-387` 已具名） |
| 7 | `:205` `TASK-0201` `[MVP]` | 🟡 | 车道台账 `~/w44a/legs.tsv` ＝ `f94be573393b9971`（176 行＝1 表头 ＋ **175 腿**）；`SILENT_SEGV_HIT` 列**全部 175 行＝`no`**（0 命中），`rc` 列全 `124`，`FAMILY` 全 `alive`；在册针表 `tests/SilentHitProbe/silenthit-trim.tsv` ＝ `4270ab3da7a1d6d8`（24 行） | **成立**：`0/175 ⇒ 95% 单侧上界 = 1−0.05^(1/175) = `**`1.6973%`**（我自己算，13:11）⇒ 修法后**零命中**但**上界仍非 0**、且**异源残余**未关 ⇒ 🟡（"已到哪一格＝修法后零命中；缺哪一格＝上界未归零／异源未关"） |
| 8 | `:227` `TASK-0302` `[MVP]` | 🔴 | 仓内工具现跑（13:57→13:11 区间）：`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=…/WPFOnLinux`＋`PTSGAP_CITED=PASS refs=1 strict=1`；PTS 门禁步在我这趟门禁里 `PTS_GUARD=PASS legs=2/2 … direction=in-file phase=degraded` | **成立**：`可操作缺口 88 条／实现口径 95 条` 与现算**逐字同**；两页仍洋红（见 #6）⇒ `🔴` 正确 |
| 9 | `:210` `TASK-0203` | ✅ | 引用件 `build/MilBridge/W98A-report.md` ＝ **`74df2f1a289bcc45`**（与行内引用**逐位同**） | **成立** |
| 10 | `:228` `TASK-0303` | ✅ | 引用件 `build/MilBridge/W78A-report.md`：整件 `720e12fceb761941`／**582 行**；但 `head -568` ⇒ **`0dbc62b1d1cf86ee`**（与行内引用**逐位同**） | **成立**（＝"只增不改"下的**前缀快照**；见 §13 观察 `O-3`） |
| 11 | `:266` `TASK-0701` | ✅ | `~/mvp-accept.sh` 在位（11098 B）；`~/heavy-slot.sh` 含 `--min-avail`＋`--max-hold`（`grep -c min-avail` ＝ 6）；本趟我自己就用它跑的门禁（`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED`） | **成立** |

**结论（验收①）**：**11 行全部"记号 ⇔ 现取读数"对得上 ⇒ 没有一行判 `needs_revision`**；两处**限定语级**提醒见 `O-1`（`TASK-0745`）与 `O-3`（`TASK-0303`）。

---

## §3 `§13` 计数行现取复核（**验收②；不一致 ⇒ 点名 —— 本条点名并升级为 finding F1**）

- 计数行 `docs/ROUTES.md:166` 现取逐字：`│  现取计数（#80，t14 现算）：TASK 行 **77** ＝ ✅**75** ／ 🟡**0** ／ 🔴**2** ／ ⚪**0**`。
- **我自己数（脚本 `~/w31x/s13count.py`，锚＝行首树形符号 `─ TASK-nnnn`，全部现取）**：
  - `§13` 代码块 = `docs/ROUTES.md:164–356`；
  - 树内**唯一 TASK 行 = 79 行**（多出的两行＝`:209 TASK-0202`／`:216 TASK-0204`，**不带** `[MVP]`/`[Next]` 标记）；
  - 其中**带标记的 77 行**的分类＝ **✅74 ／ 🟡1 ／ 🔴2 ／ ⚪0**；非 ✅ 的三行＝`:175 TASK-0007 🔴`／`:205 TASK-0201 🟡`／`:227 TASK-0302 🔴`。
- ⇒ **计数行的行数（77）与"带标记行"同数 ✔，但分类差一格**：它把 `:205` 的 **🟡** 算进了 ✅（差＝🟡`0→1`、✅`75→74`）。**机制**（我复现）：`TASK-0201` 行**正文**里另有一个带 ✅ 的 dated 重取读数（`〔✅ 2026-09-28 现件代重取…`）⇒ 机械取"行内第一个 ✅"就会吞掉 🟡。
- **同错第二处**：`§15af:788` 现取也写 `树内状态现算 ✅75 ／ 🟡0 ／ 🔴2 ／ ⚪0`（该行还把抽取域写成"含 `[Next]` 的行"，却在 🔴 里点了两件 **`[MVP]`** 行 ⇒ 域描述与分类自相矛盾）。
- `:789`（同节）**是对的**：它把 `TASK-0201` 明列入"未绿 `[MVP]` 三条" ⇒ **文内自相矛盾**（`🟡0` vs "未绿"）。

---

## §4 `README.md`「账一」更正的独立性（**验收③；我自己重跑，不采信 `migrator` 结论 → 一半不一致，见 F2**）

- **正面（措辞与读数一致 ✔）**：现取（13:11:41–13:12:13）`test -e Directory.Build.props` ⇒ **absent**（`Directory.Build.targets` 亦 absent）、`git cat-file -e HEAD:Directory.Build.props` ⇒ **失败**（工作树与 `HEAD` **都无**该件）；**两条求值侧机器证据我都在自己的门禁里现取**：`BHYGIENE_ROOTPROPS=PASS exists=0 tracked=0 git=present`｜`BHYGIENE_IMPORT=PASS reason=ok files=41 lines=41 list=41 mention_files=42 mention_lines=84 disappeared=0 dup=0 unlisted=0 file_absent=0 expect_n=41 props=3a5fd92cd1331f36 **undeclared=0** cand=88 cand_min=88 notneeded=29 suspended=18 roster=9b322c7f4967e222 rootprops=PASS …`｜`ROOT_ALLOW=PASS … examined=22 tracked_n=22 worktree_n=25 allowed_n=25 unknown_tracked=0`。**我另跑的直接求值命令**（`~/heavy-slot.sh … dotnet msbuild samples/HelloMil/HelloMil.csproj -getProperty:TargetFramework -nologo`）⇒ `rc=0`、输出 `net10.0`、`grep -c MSB4236` ＝ **0**（13:12:13）⇒ **`N` 上不再报 `MSB4236`**（与 `README.md:180` 的措辞一致）。
- **反面（🔴 不一致 ⇒ F2）**：`README.md:231` 现取逐字仍写「⚠️ **该事实的"入册"（`KNOWN-DEFECTS.md` 新号）尚未落** —— 逐字状态＝**待配号**（… 登记批由 `t57`／队长安排）」，**而现场已是"已入册"**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:3666` 有 `### 🆕 D-G180` 条目（`t58`，读时 `2026-09-28T12:34:49+08:00`），声明表 `build/MilBridge/tools/defect-registry-declared.tsv` 有 `ID D-G180 req=KD present=KD`（`declared=215` 已含它）。
- 归属：`README.md` 最后一笔 `d80ec2a`（`12:30:46`，`t14`）**早于** `t58` 的入册（`12:34:49`）⇒ **是"状态句被后续同环工作作废、但没人回头改"**（与 `HANDOFF-NEXT §下一波未闭项` 第 11 条"手抄机器值每代必陈旧"同族，载体换成 README 的状态句）。

---

## §5 缺陷册自洽（现取）

- `DEFREG=PASS declared=215 route_ids=215`（**真树**，12:56:44）；`DEFREG_DECLDRIFT=0 keys=-`；声明表 215 ID 行、**无重复号**；`D-G179` 行＝`:110 ID D-G179 req=KD present=KD`（**提及即声明**，见 §8）。
- **纪律 15 核算（改了路由件却没重发）**：声明表 `DECL-GEN = 12:35:07`；我逐件现取四键并与 `DECL-ANCHORS` 对拍 ⇒ **四格全同**（`KD 2152460b7e412352`／`CS 13077b52c938f8af`／`HO a4d8ffcf4c37f6fe`／`AB b96d4312565a3c49`）⇒ **无漂移、无漏重发**。
- `REPORTID=PASS files=187 ids=1912 declared=215 glob=build/MilBridge/*report*.md`（13:02:03）。
- `BOOK_ENTRY_UNREQUIRED_MISSING n=16 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 **D-G179** D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1（**已登记的缺口：可见、不判红**）` ⇒ `D-G179` 确在"声明有、条目无"名单里（与我独立复现一致）。

---

## §6 收官门禁（**静止树；`porcelain=0` 起跑**）

`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 2700 --wait 1800 -- bash verify-all.sh`（`12:55:36` 起 → `13:10:xx` 止；`HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=4178MB`／`RELEASED rc=0 held=926s`）

| 门禁 | 我自己现取的判词行（原文） |
|---|---|
| **总判** | `步骤通过 55  ❌ 失败 0`｜`用例通过 875  跳过 2`｜`SKIP_GUARD=PASS x_state=available … total_skipped=2 violations=none reason=none`｜`结论：✅ 全部通过`｜`GATE_RC=0` |
| 在册红门禁（五臂） | `[4]` ✅（`THIRDPARTY`／`FRAMEPRESENCE` 等臂全绿） |
| `[9] BUILD-HYGIENE` | `BHYGIENE_ROOTPROPS=PASS exists=0 tracked=0 git=present`｜`BHYGIENE_IMPORT=PASS reason=ok … cand=88 … undeclared=0` |
| `[10] DEFECT-REGISTRY` | `DEFREG=PASS declared=215 route_ids=215` |
| `[11] VERIFYALL-SELF` | `VERIFYALL_SELF=PASS names=55 decl=55 gen=#79 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=600274f130cfe913` |
| `[12] FP-INPUTS-HYGIENE` | `FP_INPUTS_HYGIENE=PASS reason=clean coverage_n=226 artifact_n=0 missing_n=0 stderr_bytes=0` |
| `FP-MANIFEST-TEETH` | `FP_MANIFEST_TEETH=PASS reason=ok files_n=226 files_n_uniq=226 blank_n=0 declared_expect=226` |
| `COLUMN-FLOOR` | `COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无`｜`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=6351a46296d17b28 base=b96d4312565a3c49 corpus=0cebc0afd5142fbf` |
| `SELFDESC-WIRING` | `SELFDESC_WIRING=PASS examined=65 wired=44 unwired=21 undeclared=50 fails=0 run_step=55` |
| `SHELL-QUOTE-TRAP` | `SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=195 sh=106 py=89 diag=76 allow=0` |
| `BOUNDARY-DECL` | `BOUNDARY_DECL=PASS records=2 pass=2 fail=0 noinfo=0 coverage=4/6 gaps=0 bystanders=2` |
| `PTS-PAGES` | `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded` |
| `[WIRING-COVERAGE]`／`[PARSER-GUARD]`／`[PROTO-ATTR]`／`[WIRING-CLOSURE]`／`[RETIRED-PATH]` | `WIRING_COVERAGE=PASS … coverage_n=226`｜`PARSER_GUARD=PASS …`｜`PROTO_ATTR_GATE=PASS examined=18`｜`WIRING_CLOSURE=PASS steps=55 jaws_n=52 undeclared=0 reasonless=0 exempt_rows=7 … grown=0 fails=0 rc=0`｜`RETIREDPATH=PASS mode=tree files=229 hits=3 code=0 declared=3` |
| `REPORTID` | `REPORTID=PASS files=187 ids=1912 declared=215` |
| 断言：块件 | `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ＝ **`b96d4312565a3c49`**（门禁**前后一致**，13:11:12 复核） |
| 断言：`porcelain` | 门禁**后**仍 **0**（13:11:12）⇒ 门禁未在仓内留下写件 |

**红／异常逐条**：① `grep -c '❌'` ＝ **1**，是**汇总标签行**`❌ 失败 0`的字面符号（**假阳**，同族＝`D-G87` 的"日志量≠签名"）；实际 `失败 0`。② 无其他红。
**写件后的零位移复核**（我两笔写件之后；见 §16 末）：`DEFREG`／`REPORTID`／`COLUMN_FLOOR`／`infp` 四格**逐位不变**。

---

## §7 `wave-freeze-consistency-check.py` 四档全量（**契约 §三-1**）

工具现取：`build/MilBridge/tools/wave-freeze-consistency-check.py` ＝ `e4393879eaca84f0`（918 行；件头自述"**纯读、零 `dotnet`、秒级；不写任何件**"）。两次跑：`12:58:30`（门禁 `[1] 构建` 窗口内，见下"时机"边界）与 **`13:11:17`（门禁后、树静止）**，判词一致：

| 档 | 判词（原文，13:11:17） |
|---|---|
| ① 根站点默认（派生式 roster） | `WFREEZE_ROOTDEFAULT=PASS exprs=168 files=136 ok=35 bad=0 root_n=35 benign=133 consume=5 consume_ok=5 t17=22 t17_lost=0 t17_val_bad=0 cwd_dep=0 anchor=content` |
| ② 预登记 ⇔ `GENS` 配置字段 | `WFREEZE_DECL=PASS gen=#80 allow_changed_decl=dwf,pc,pf,provider,win32shim,windowsbase allow_changed_gens=同 pf_required_decl=False pf_required_gens=False src=WAVE80-PREREGISTRATION.md` |
| ③ 同名产物两条权威路径 | `WFREEZE_NINEAUTH=FAIL pairs=1 ok=0 bad=1`｜`WFREEZE_NINEAUTH_HIT kind=diverged canon=build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll=d093559be572ccbf copy=build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll=7e8a217b4165a6b9` |
| ④ 九位块值 ⇔ 现取 | `WFREEZE_BLOCKVALUES=FAIL gen=#80 keys=9 declared_shifts=0 bad=1 noinfo=0 cfg=Release`｜`WFREEZE_BLOCKVALUES_HIT key=provider probs=nine-vs-live,tier-vs-live block9=7e8a217b4165a6b9 tier=7e8a217b4165a6b9 live=d093559be572ccbf`｜`WFREEZE_BLOCKVALUES_TIER_NA keys=windowsbase,hbtextline,dwf（机读行按设计只覆盖 7 键 ⇒ 不判）` |
| 模板面（显式给） | `WFREEZE_TEMPLATE=PASS path=~/w186a/w80/w80freeze/w80-record.txt hits=0 notes=9`（9 条 `NOTE` 全为"只列不判"）；不给时＝`WFREEZE_TEMPLATE=skipped(no-template-given)`（**不算绿**） |
| 总体 | `WFREEZE_CONSISTENCY=FAIL rootdefault=PASS decl=PASS nineauth=FAIL blockvalues=FAIL（四档互不代偿）`（`rc=1`） |

**🔴 我推翻的那句话（本环最承重的一条）**：**`provider` 在这一环的起点上并不存在"块／哨兵／live 三分叉"。** 现取（12:55:11，门禁起跑前 25 s）：`PROVIDER` live ＝ **`7e8a217b4165a6b9`**，与 `#80` 块九位行（`:66`）＋ `BASELINE tier=`（`:74-79`）＋ 哨兵 `PROVIDER=` **四处同值** ⇒ 若在那一刻跑四档，③④ 在 `provider` 上**应是绿的**。契约 §三-1 给的"三时刻（`759ac1686e5ef87d` 块声明／`8cb1b50619f4c133` 哨兵＝`prev_provider`／`7e8a217b4165a6b9` live）"描述的是 **`#79`→`#80` 的那次换代**，其中第三格（"live"）**在我门禁跑完后就已不是 live**。
**新分歧是我这趟门禁自己造出来的，且我复现了最小机制**：

| # | 时刻 | `PROVIDER` canon 值 | 证据 |
|---|---|---|---|
| 1 | `10:24:21`（`#80` 波构建） | `7e8a217b4165a6b9`（＝块＋tier＋哨兵） | 副本 `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll` 现取同值、mtime `10:24:21` |
| 2 | **`12:55:54`**（**我的门禁 `[1] 构建` 窗口内**） | `d093559be572ccbf`（104,448 B，**大小不变**） | canon mtime `12:55:54.2642120`；九位其余 8 位 mtime 仍 `10:27–10:30`／`09-21`／`09-23`（**未被重建**） |
| 3 | **`13:11:49`**（我**单跑一次** `dotnet build build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj -c Release -m:1 --nologo -v q`，耗时 **4.35 s**、`rc=0`、**输入一件未改**） | **`24e4e0a731dbed40`**（104,448 B） | 重活走 `~/heavy-slot.sh`（`held=5s`）；源码 mtime 仍是 `09-15`／`09-16` |

⇒ **同一输入连续两次构建给出两个不同字节** ⇒ 这是 `D-G176`（"九位跨同一输入两次整波不复现"）的**最小复现**：**不需要整波，一条 `dotnet build` 就够**。⇒ 结论三条：
1. `provider` 的 ③④ 红**不是产品回归**（同趟门禁 `55 ✅/0 ❌`、875 例全绿、五臂全绿 ⇒ 新字节行为一致），是**身份/可复现性**问题（`D-G92`／`D-G176` 族）；
2. **闭合链的顺序在这一族面前不成立**：`门禁×2 → 冻结 → post1/post2 → 推送 → 哨兵` 里只要**冻后再跑一次会 `dotnet build` 的门禁**，冻结块里的 `provider` 就**必然**与 live 分叉 ⇒ 本环的"冻后重跑门禁"与"块值恒真"**在结构上不可兼得**；
3. 因此我**不重钉 `#80` 块**（契约 §五 明令不碰），也**不把 `provider` 红算作本波新红**；我把它按"在册族 ＋ 我新取到的三读数"如实点名，并**写进未闭项**（§16 第 18 条）。
**时机边界（如实）**：我第一次跑该工具是 `12:58:30`，落在门禁 `[1] 构建` 已改写 canon 之后，因此那次读数**不是"门禁前"的样本**；§7 表全部改用 `13:11:17`（树静止）的判词，门禁前的状态由 §1 的九位现取（12:55:11）承担。

---

## §8 `D-G179` 候选：`req` 列在**自动路径**上恒真（**契约 §三-2；两侧都做，真树只读**）

沙箱：`~/w31x/dg179/`（KD 副本 ＋ 声明表副本；**真树零写入**）；工具 `build/MilBridge/tools/defect-registry-check.sh` ＝ **`c2d0773e5561a9d1`**。

| 腿 | 构造 | 我的现取读数 | 判词 |
|---|---|---|---|
| 合法基线 | 真树（真 KD ＋ 真声明表） | `DEFREG=PASS declared=215 route_ids=215`（`rc=0`） | 绿 |
| **① 正侧（契约要求"提一句"）** | KD 副本（`b02d47082788c61a`）里对既有编号 **`D-G152`**（原 `req=AB`；KD 命中 **0**、`handoff.md` 命中 0）**只写一句提及**，`--emit` 重出声明表（`4b0fe3d11119dac4`） | 该行自动变 `ID D-G152 req=KD,AB present=KD,AB`；同趟校验 `DEFREG=PASS declared=215 route_ids=215`（**`rc=0`**） | **恒真成立**：`emit_decl()`（`:134`）的 `req` ＝ `{KD,CS,HO,AB}` 里的**出现集**，校验侧又拿 `req` 判"每个 K 都出现过" ⇒ **生成规则与判定规则是同一个集合** |
| **② 反侧（契约要求"人工加宽"）** | 把副本声明表 `D-G152` 的 `req`/`present` 手工加宽到 **`HO`**（该件命中 0） | `DEFREG=FAIL reason=declared-id-missing-in-route`（**`rc=1`**）＋ 逐条点名 `D-G152 req=HO MISSING-IN=HO route=…/handoff.md`；另有 `DEFREG_DECLMETA` 诊断行（不判红） | **人工改表仍有牙** |
| ③ 我加的第 3 腿 | 把 `req` **收窄**回 `AB`（子集） | `DEFREG=PASS declared=215 route_ids=215`（`rc=0`） | **欠报不可见**（与 ① 同族，供定号取舍） |
| ④ 我加的第 4 腿 | 把 `req` 塞**非 route 键** `KRJ` | `DEFREG=NOINFO reason=decl-unparsable`（**`rc=2`**） | 三态未坏（**没当绿**） |

**"声明有、条目无"侧证（同一编号）**：`KNOWN-DEFECTS.md:3679` 现取是本条编号的**唯一提及**（`grep -c D-G179` ＝ 1），**条目形态 `### 🆕 D-G179` 计数 ＝ 0**；`report-id-domain-check.sh` 把它列进 `BOOK_ENTRY_UNREQUIRED_MISSING n=16 …`（**可见、不判红**）；声明表 `:110` 已有 `ID D-G179 req=KD present=KD` ⇒ **两侧都复现**（"提及即声明 ⇒ 声明存在" ∧ "条目确实没有"）。

---

## §9 哨兵次序 ⇔ 块件 ⇔ 九位（**契约 §三-3**；含 `t61` 式机器核）

- **两枚 mtime vs 最后一笔提交**（我改写前的现取）：`/tmp/bridge-frozen.flag` mtime `12:54:14.4023383`；`~/wfp-runs/bridge-frozen.flag` mtime `12:54:14.4013383`；**最后一笔提交 `1637dbc` 的时刻 ＝ `12:54:09`** ⇒ 哨兵**晚 5 s**（**没有**"提交在哨兵之后"的情形 ⇒ 次序判词**成立**）。
- **两枚 `cmp`**：`IDENTICAL`（279 B／`sha16=f2ab94d32b8e1e40`）。
- **哨兵内容 ⇔ 块件 ⇔ `CS:9` 逐位对拍**（我改写**前**）：`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` ＝ 块件现算 ＝ `CS:9` 三格 ✔；十键里 **9 位 SAME**，**`PROVIDER` 分叉**（哨兵/块 `7e8a217b4165a6b9` vs live `d093559be572ccbf`，成因见 §7）。
- **机器核（照 `t61` 的做法，比只看 `porcelain` 强）**：写完两枚哨兵后，我逐个 `stat -c %Y` **覆盖面内 226 件**并取最大值，与两枚哨兵 mtime 比较 ⇒ 结论与数值见 §16 末（**"其后无一件被写过"**）。

---

## §10 推送与标记（现取）

- **推送（本轮其余）**：`HEAD = ls-remote = 1637dbc7059a3287f08757e4974f66c7103bbb11`（`12:55:04` 现取）⇒ 远端 tip 与本地逐字相同；`57cd937..HEAD` 共 **13 笔**（`t14`／`t57`／`t58`／`t59`／`t60`／`t61`／`t62`／`t63`／`t64`／`t65` 等）**全部是 tip 的祖先** ⇒ 在远端**逐笔可追**（tip 相同 ⇒ 对象树同步，无需 `fetch` 即可判定）。
- **`porcelain=0`**（12:55:04／13:11:12）。
- **推送标记（`.done`）现取（我独立核）**：`~/w14a/` **恰好四枚** —— `W80_DOCSCLOSE.done`（`6a6407dd7e684be6`，mtime 12:31）／`W80_T58.done`（`38d45f104ab511b8`，12:35）／`W80_T60.done`（`28fe0047011b2ff9`，12:41）／`W80_T62.done`（`9c164050ae77a3b9`，12:46），每枚三字段齐全（`push_rc=0`／`stop_line=none(all-steps-ok)`／`remote=<sha>`）；**`t64` 两次推送零标记**（`find ~ -maxdepth 3 -name '*T64*'` ⇒ 命中 **0**）；全 `~` `maxdepth 3` 共 **41** 枚 `.done`；**仓内零读者**（`grep -rIl '\.done' build/MilBridge/tools verify-all.sh build/close-wave.sh` ⇒ **0 命中**）⇒ 已入册（§16 第 15 条）。
- **我这一笔**：见 §16 末（清单逐件、`PUSH_LIST_GAP` 式自核、`push_rc=`／`stop_line=` **非空**）。

---

## §11 目标完成度判决（本环最终问题）

**① `docs/ROUTES.md` 里还有没有未闭 `[Next]`？—— 没有。** 现取口径：`§13` 树内带标记的 77 行里，**5 条本环 `[Next]`（`TASK-0740`／`0742`／`0744`／`0745`／`0747`）全部 ✅**，且每一行都在 §2 表里被我**现取到件＋接线＋真判词**；`§13` 树内 **🔴 2 件全部是 `[MVP]` 行**（`:175 TASK-0007`／`:227 TASK-0302`），**没有一条 `[Next]` 是红的**；`:788` 的"本趟翻转 6 件"我按自己的抽取复算**同数**（`[Next]` 域内非 ✅ 行 0）。

**② 三条未绿 `[MVP]` 各处于什么状态、凭什么**：
- **`TASK-0007`（`🔴`）—— 仍未绿**：机器读数＝23／24 两页**洋红占位非 0**（`k23 50236`／`k24 54826`，**我自己从在册 PNG 重算**，13:00:04）⇒ 页仍是"不支持"占位、**不是真排版**；行内旧句"必死 `rc=134`"已被 dated 行取代（现状＝`alive=yes`／`app_rc=143`／具名 `[PTS-UNAVAILABLE] err=-10000` 在位）。**依据＝洋红像素数 ＋ 在册证据件与我重算一致**。
- **`TASK-0201`（`🟡`）—— 仍未绿**：修法后**现件代 `0/175` 命中**（台账列 `SILENT_SEGV_HIT` 全 `no`）但 **95% 单侧上界 `1.6973%`**（我自算）⇒ "零命中" **不证明**"归零"；且 `D-G109` 的**异源＋残余**那一半仍成立。**依据＝我自己的列统计 ＋ 我自己的上界算术**。
- **`TASK-0302`（`🔴`）—— 仍未绿**：`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95`（我自跑）⇒ **88 条可操作缺口仍在**；前沿只跳到 `LoCreateContext`（在册 `app_g1.log` `eb6af2e16ba2bcfb`，3× `entry=LoCreateContext`、0× 旧名），而**判据侧 `PTS-PAGES` 的绿对前沿位移零证据力**（该口径句仍在报告 `:178`、**未进判据件自身**，见未闭项第 8 条）。

**③ 这三条里哪一条本轮没有**被推进**？—— `TASK-0007` 与 `TASK-0302` **同一件事的两面**（同一条真因），本轮推进的是 **`TASK-0302` 的前沿（`CreateInstalledObjectsInfo → LoCreateContext`，跳数 0→1，`t52`/`t55` 同趟落仓证据）**；**`TASK-0007` 本轮没有独立推进**（它只跟着 0302 走；两页仍是洋红占位，`🔴` 未动）。**`TASK-0201` 本轮被推进到"修法后零命中 ＋ 上界收紧到 `1.6973%`"**（`t44`），但**没有**任何一步把上界做成 0 ⇒ 仍 🟡。

---

## §12 终局资源读数与"有没有出过内存／磁盘事故"

- **终局（`13:12`＋）**：`df -Pk /` ⇒ 可用 **77,873,960 KB ≈ 74.3 GiB**（`use%=58%`）；`free -m` ⇒ `MemAvailable` **3,611 MB**；`SwapFree` **1,219 MB**（`Swap total 2047 MB`）。门禁峰值期间我采样：`avail 4178MB`（`HEAVYSLOT=MEMOK avail=4178MB min_avail=1500MB`）／`3513MB`／`3530MB`；**`SwapFree` 全程样本 `1219–1220 MB`，从未归零**；磁盘**从未接近写满**（最紧时余 74 GiB）。
- **事故判定**：**本环我观测到的窗口内没有发生过 `swapfree` 归零或磁盘写满**；也没有任何读数因此被丢弃。
- **⚠️ `NOINFO`（不许当绿）**：OOM-killer 的**历史**证据取不到 —— `dmesg` 现取返回 `读取内核缓冲区失败: 不允许的操作`（权限不足）⇒ "全程无 OOM"这句我只能以**我自己的活体采样**为据（样本见上），**不是**内核日志级证据。
- 重活全部走 `~/heavy-slot.sh`（本环两次：门禁 `held=926s`；单工程重建 `held=5s`；均 `RELEASED rc=0`），长跑前现取 `df`／`swapfree` 已做。

---

## §13 边界、`NOINFO` 与观察（**不含 finding**）

- `O-1`：`TASK-0745` 的 `✅` 是**补丁形态**闭合，**不是**"冻结器已有该自检"（活件 `grep -c 'def check_record_forms('` ＝ 0）。行内文本与 §15ad `F7` 都已披露，**但读者容易把 ✅ 读成"已生效"** ⇒ 建议下一波在行尾加半句 dated 限定语。
- `O-2`：`§13` 计数行还有一个**口径**问题（不是数值）：树内**唯一 TASK 行 79**、**带标记 77**，计数行只写 `TASK 行 77`、`:788` 写"唯一 TASK 77 个" ⇒ **"TASK 行"的两种口径必须写明**（已并入 `F1` 的 requiredFix）。
- `O-3`：`ROUTES.md:228` 的引用（`W78A-report.md` `0dbc62b1d1cf86ee`／568 行）**成立**，但只在**前缀快照**口径下成立（整件现取 582 行／`720e12fceb761941`）⇒ 引用**未写明口径**时会被误判为 stale。
- `O-4`：`HANDOFF-NEXT.md` 未闭项第 3 条的六件"字面残留"里，**五件路径省了 `build/MilBridge/` 前缀**（`tests/FrameProbe/Program.cs` 等）；我按 `build/MilBridge/tests/…` 解析后**六件 SHA16 与行号全部命中**（`503e6ebd86d70303`／`76caccc4693bf4a1`／`b8dba8fbbc05a327`／`c06f605002cb5d48`／`1b2815e197638a23`／`08f7bd96d1c33f22`）⇒ 指针**可查**，只是**基径未写明**。
- `O-5`：`t59` 曾在 `in_progress` 期间落仓一笔（我 12:37 现取：`ba16fe0` 含 `V80-t58-review.md`）——**只作观察**（队长已裁定：本仓落仓与任务终态不强制同刻）。
- `O-6`：本报告写入后 `REPORTID` 的 `files` 计数会由 187 变 188（我的文件名落在 `build/MilBridge/*report*.md` glob 内）⇒ 我已在写后重跑并给出新值（§16 末）。

---

## §14 我推翻了哪句话（逐条）

1. **推翻"`provider` 是本环在册的既存红（三时刻含 live `7e8a217b4165a6b9`）"**：该三时刻是 **`#79`→`#80` 换代**的历史；**本环起点上块／tier／哨兵／live 四处同值**（12:55:11 现取）⇒ 现在的分叉是**我这趟门禁自己的构建**造成的（canon mtime `12:55:54`），并被我用**一次 4.35 s 的单工程重建**坐实为"**同输入不可复现**"（`7e8a217b… → d093559… → 24e4e0a7…`）。
2. **推翻派单里的两个现值**：`HEAD=8137240…`／`declared=213` 已过期（现取 `1637dbc…`／`215`；`215 = 213 + D-G180 + D-G179(提及即声明)`）。
3. **推翻"`§13` 计数行 `🟡0`"**：树内自己的 `:205` 行是 **🟡** ⇒ 应为 `🟡1 ／ ✅74`（`F1`）。
4. **推翻 `README.md:231`「`D-G180` 入册尚未落／待配号」**：`KNOWN-DEFECTS.md:3666` 有 `### 🆕 D-G180`、声明表有 `ID D-G180`（`F2`）。
5. **我自己的一条疑似发现被我自己否掉（如实记）**：我一度以为 `ROUTES.md:228` 引用的 `W78A-report.md` `sha16`／行数是**陈旧的**（整件现取 582 行／`720e12fceb761941`）；`head -568` 复算后**逐位命中 `0dbc62b1d1cf86ee`** ⇒ 引用**成立**，降级为观察 `O-3`。**疑似 stale 的部分是我的初读口径错，不是它的数错。**

---

## §15 复算命令原文（承重命令逐条；输出见各节）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
# 现场
git rev-parse HEAD; git ls-remote origin refs/heads/feat-Linux | cut -f1; git status --porcelain | wc -l
sed -n '9p' docs/CURRENT-STATE.md; sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
# 九位 ⇔ 哨兵（脚本见 §1 表；九条路径为权威表，含 PROVIDER canon 路径）
sha256sum build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll
bash build/bridge-src-fp.sh                     # FP=d697b1e10ff48881（≠ inputs_fp）
bash ~/w153a/bin/infp.sh fp; bash ~/w153a/bin/infp.sh list | wc -l     # abc76bd55… / 226
stat -c '%s %y' /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag; cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag
# 门禁（唯一重活；heavyslot）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 2700 --wait 1800 -- bash verify-all.sh
bash build/MilBridge/tools/column-floor-check.sh; bash build/MilBridge/tools/defect-registry-check.sh | tail -3
bash build/MilBridge/tools/report-id-domain-check.sh | tail -3
# 四档一致性（纯读）
python3 build/MilBridge/tools/wave-freeze-consistency-check.py
python3 build/MilBridge/tools/wave-freeze-consistency-check.py --template ~/w186a/w80/w80freeze/w80-record.txt
# provider 最小复现（重活；一次构建）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 900 --wait 600 -- dotnet build build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj -c Release -m:1 --nologo -v q
# D-G179 两侧（沙箱 ~/w31x/dg179/；真树只读）
cp samples/WpfFeatureProbe/KNOWN-DEFECTS.md ~/w31x/dg179/KD1 && printf '\n- 边界说明：D-G152 仅提及。\n' >> ~/w31x/dg179/KD1
DRC_KD=~/w31x/dg179/KD1 bash build/MilBridge/tools/defect-registry-check.sh --emit > ~/w31x/dg179/decl1.tsv
DRC_KD=~/w31x/dg179/KD1 DRC_DECL=~/w31x/dg179/decl1.tsv bash build/MilBridge/tools/defect-registry-check.sh   # PASS
awk -F'\t' -v OFS='\t' '$1=="ID"&&$2=="D-G152"{print $1,$2,"req=KD,AB,HO","present=KD,AB,HO";next}{print}' ~/w31x/dg179/decl1.tsv > ~/w31x/dg179/decl2.tsv
DRC_KD=~/w31x/dg179/KD1 DRC_DECL=~/w31x/dg179/decl2.tsv bash build/MilBridge/tools/defect-registry-check.sh   # FAIL 点名
# §13 计数（我自己的抽取器）
python3 ~/w31x/s13count.py
# README 账一（两条求值面）
test -e Directory.Build.props; git cat-file -e HEAD:Directory.Build.props
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 600 --wait 300 -- dotnet msbuild samples/HelloMil/HelloMil.csproj -getProperty:TargetFramework -nologo
# 三 [MVP] 行的现取读数
python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,boot}.png
awk -F'\t' 'NR>1{print $12}' ~/w44a/legs.tsv | sort | uniq -c; python3 -c "print(100*(1-0.05**(1/175)))"
bash build/MilBridge/tools/pts-gap-count-check.sh | tail -2
nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | grep -c SHAppBarMessage   # ⇒ 1
# 资源
df -h /; free -m; dmesg | tail -3     # dmesg ⇒ 权限不足（NOINFO）
```

---

## §16 未闭项入册 ＋ 本件自己的收尾（推送／哨兵／机器核）

- **入册**：`build/MilBridge/HANDOFF-NEXT.md` 的「§下一波未闭项」**同节追加**第 **12–18** 条（现取清点：本节原有 1–11，`t62` 已占 11）：
  - **12** `D-G179` 候选（`req` 恒真；两侧读数 ＋ 我另加两腿）—— **契约 §四 指定**
  - **13** 哨兵 `FP` ≠ `inputs_fp`（同名/近名混口径 ⇒ 假红）—— 队长指定
  - **14** 哨兵由**仓外仪器**写、仓内零读者 —— 队长指定
  - **15** 推送标记（`.done`）适用面/命名不统一、**仓内无强制读者** —— 队长指定
  - **16** `ROUTES.md:228` 引用需写明"前缀快照"口径（`O-3`）
  - **17** `ROUTES.md:166` ＋ `§15af:788` 的计数行分类错一格（`F1`）＋ "TASK 行"两种口径
  - **18** **门禁是构建驱动 ⇒ 冻后跑门禁必使 `provider` 位移**（`D-G176` 最小复现：单工程 `dotnet build` 4.35 s 即换值）＋ 本轮 ④ 红的三读数
- **推送**：一笔（清单＝**逐径** `git add`，**绝不** `-A`、**不**从 `git status` 生成清单）；清单／`push_rc=`／`stop_line=` 由标记件 `~/w31x/W80_T15.done` 承载（**逐字段非空**）。
- **最后动作＝重写两枚哨兵**：十键按**现取原文**重写（`PROVIDER` 用**现取**值，理由＝`close-wave.sh:679-700` 的纪律"**谁重建，谁更新，不留人工步骤**"；照抄冻结值就会复刻 2026-09-14"产物已换代、哨兵还是上一代"的事故）＋ 两枚 `cmp` ＋ 覆盖面 226 件的 `stat` 机器核。
- **两个时刻的口径（如实划界）**：哨兵是**最后动作** ⇒ 本报告落盘／推送时它**尚未发生**，两个时刻由标记件 `~/w31x/W80_T15.done` 与我的收尾报文承载。**改写前**的现取为：末笔提交 `1637dbc` `12:54:09` vs 两枚 mtime `12:54:14.4023383`／`.4013383`（**哨兵晚 5 s**）——即"提交在哨兵之前"的次序**当时成立**。
- **自报指纹**：`head -n -1 | sha256sum | cut -c1-16` ＝ **`aa585b8c9c5ae9c4`**（本行是最后一行 ⇒ 覆盖本件其余全部字节）；整件 `sha256sum`（含本行）＝ 见标记件 `~/w31x/W80_T15.done` 与收尾报文（自指行无法内嵌自身哈希，故只给"除末行外"这一口径）。
