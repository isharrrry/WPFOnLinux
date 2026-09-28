# P1-W4b 独立复核判词（`t50`）—— 对 `t48` 交件（`B-11` 牙面 ／ `B-15` 推送标记 ／ `B-18` 免钉定则 ＋ 同趟接线四处声明）

> **复核者**：`scout`（独立复核者）。**一切读数自己现取、自己造夹具重跑**；**不复述** `t48` 的报告或交件消息当证据。
> **改写面**：本件是本次复核**唯一**写入 `$N` 的件（`temp+rename`）。被复核的任何件**一字未改**（§8 逐件给改前／改后读数）。
> **全文 `sha16` 只在交件消息里给**（第 `24` 条口径）；本件末行只携带 `head -n -1` 自证值。
> **所有读数带亚秒 `ts=`**；`ts` 是**该条命令跑完那一刻**的现取时刻。

---

## §0 快照

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD`（复核开始时） | `1d136ca`（W4a 接线；`docs(#81): W4a 接线 —— 三颗交付牙同趟进仓根 verify-all.sh（步数 55→58）＋ 覆盖面 226→229`） | `2026-09-28T17:54:40.157+0800` |
| `HEAD`（复核进行中**被推进**） | **`3aaaa3e`**（`docs(#81): W4b 合波 —— B-11 机器值牙 / B-15 推送标记 / B-18 免钉定则 同趟接线（覆盖面 229→233，步数 58→61）`；提交时刻 `2026-09-28 17:55:01 +0800`） | `2026-09-28T17:55:19.592+0800` |
| 工作树 `porcelain`（开始） | **12** 行：` M`×7（`HANDOFF-NEXT.md`／`sentinel-spec-check.sh`／`timestamp-order-check.sh`／`wave-push.sh`／`close-wave.sh`／`WAVE81-PREREGISTRATION.md`／`verify-all.sh`）＋ `??`×5（`P1-task0201-criteria.md`／`P1-w4b-report.md`／四个新件中的…见下行） | `2026-09-28T17:54:40.157+0800` |
| 工作树 `porcelain`（`3aaaa3e` 之后） | **1** 行：`?? build/MilBridge/P1-task0201-criteria.md` | `2026-09-28T17:57:31.572+0800` |
| 暂存 | `git diff --cached --name-only \| wc -l` ＝ **0** | `2026-09-28T17:54:40.157+0800` |
| 冻结哨兵（`docs/CURRENT-STATE.md:9`） | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `2026-09-28T17:56:30.038+0800` |
| 步数（三值） | `grep -c '^run_step "'` ＝ **61**｜首行 `DECL` ＝ `# VERIFYALL-STEPS-DECL: 61 gen=#81`｜`STEP-NAMES` 项数 ＝ **61** | `2026-09-28T17:56:57.398+0800` |
| 覆盖面 | `bash ~/w153a/bin/infp.sh list \| wc -l` ＝ **233**；`[42]` ＝ `--expect 233` | `2026-09-28T17:56:57.398+0800` |
| 静态语法 | `bash -n` 在 9 件上**全 `rc=0`**（含三件被改的牙） | `2026-09-28T17:57:31.522+0800` |

🔴 **必须记的时序事实**：本波在**我复核进行中**被提交（`1d136ca → 3aaaa3e`，`17:55:01` 提交／`17:55:19` 我观察到）。⇒ 本件 §1 的两条判词**因此从"可复现"变成"不可复现"**（见 §1-①、§1-②）；这是**现取到的机器事实**，不是叙述。
⚙️ 另：现取有**他人**在跑的进程 `timeout -k 5 50 dotnet HandyControlDemo.dll`（PID `2104668`／`2104672`，`etimes=40 s`，`ts=2026-09-28T17:57:00.720+0800`）⇒ 机器上有别的车道在动（**不是** `t48` 的整趟门禁痕迹，见 §7）。

---

## §1 逐条判词

### ①（对应派单第 1 条）`B-11` 牙的对拍射程 —— **部分成立；按契约字面判「不成立」**

**契约要求**：自跑须印 `HANDOFF_MV=PASS cells=9`；自造篡改一字符 ⇒ 必红且点名该格，且 `cell=/anchor=/in-repo=/live=` 四格都打了；只报总判不点名、或"解析不了就跳过" ⇒ 不成立。

**（a）正极实跑 —— 不成立（未印 `PASS cells=9`）**
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh        # ts=2026-09-28T17:55:37.435+0800
HANDOFF_MV_CELL cell=#1 anchor=§7-4 输入指纹 state=equal live=cf1db0977551a6d7213c0293a4cbf8545a025184caf14f1d5a6823f41de6ba7d
HANDOFF_MV_CELL cell=#2 anchor=§7-4 覆盖面件数 state=equal live=233
HANDOFF_MV_CELL cell=#3 anchor=§7-1 冻结世代 state=equal live=> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
HANDOFF_MV_CELL cell=#4 anchor=§7-3 登记册自洽 state=equal live=DEFREG=PASS declared=218 route_ids=218（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
HANDOFF_MV_CELL cell=#5 anchor=§7-5 步数 state=equal live=61
HANDOFF_MV_CELL cell=#6 anchor=§7-5 放行标记（**行内 glob 只覆盖 `w6*`**） state=equal live=w*-POST.done=25／*record*=49
HANDOFF_MV_HIT cell=#7 anchor=§7-6 推送面 in-repo=1d136ca live=3aaaa3e cmd=git log --oneline -1 | cut -c1-7
HANDOFF_MV_HIT cell=#8 anchor=§2 在飞 in-repo=11 live=1 cmd=git status --porcelain | grep -v 'build/MilBridge/HANDOFF-NEXT.md' | grep -v 'build/MilBridge/P1-w4b-report.md' | wc -l
HANDOFF_MV_CELL cell=#9 anchor=§1 九位 state=equal live=f951e80b55e85782
HANDOFF_MV=FAIL cells=9 equal=7 manual=0 mismatch=2 file=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/HANDOFF-NEXT.md
$ echo $?   ⇒ 1
```
⇒ **`HANDOFF_MV=PASS cells=9` 现取不可复现**（`equal=7 mismatch=2`，`rc=1`）。**被对拍件 `build/MilBridge/HANDOFF-NEXT.md` 现取 `ce0e80aab999b2ac`／507 行，与 `t48` 自报值逐位相同**（`ts=2026-09-28T17:55:47.685+0800`）⇒ 差别**不在件**，而在**件被对拍的那个世界**。
⇒ **牙自身也红了**：
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --selftest   # ts=2026-09-28T17:55:47.685+0800
HANDOFF_MV_SELFTEST_CASE case=S1 kind=positive rc=1 verdict=FAIL 原样=HANDOFF_MV=FAIL cells=9 equal=7 manual=0 mismatch=2 file=…/HANDOFF-NEXT.md
HANDOFF_MV_SELFTEST_CASE case=S2 kind=negative rc=1 verdict=FAIL-named 原样=HANDOFF_MV_HIT cell=#7 anchor=§7-6 推送面 in-repo=1d136ca live=3aaaa3e cmd=git log --oneline -1 | cut -c1-7
HANDOFF_MV_SELFTEST_CASE case=S3 kind=noinfo rc=2 verdict=NOINFO 原样=HANDOFF_MV=NOINFO reason=table-rows!=9 got=8 anchor=逐格对照…
HANDOFF_MV_SELFTEST=FAIL cases=3 pass=2 fail=1
$ echo $?   ⇒ 1        # ts=2026-09-28T17:56:01.882+0800
```

**（b）自造反极性（**我自己的夹具**）—— 成立（点名射程真在）**
在**副本**上把 `cell=#2` 的**最后一条**更正行的现值改一个字符（`233` → `230`，副本路径 `/home/links-dev/w-scout-t50/fix/tamper-correction.md`，**仓内件一字未动**）：
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --file ~/w-scout-t50/fix/tamper-correction.md   # ts=2026-09-28T17:56:11.933+0800
HANDOFF_MV_HIT cell=#2 anchor=§7-4 覆盖面件数 in-repo=230 live=233 cmd=bash ~/w153a/bin/infp.sh list | wc -l
…  #7/#8 仍各自一条 HIT
HANDOFF_MV=FAIL cells=9 equal=6 manual=0 mismatch=3 file=…/tamper-correction.md
$ echo $?   ⇒ 1
```
⇒ **`cell=`／`anchor=`／`in-repo=`／`live=` 四格齐全**（另带 `cmd=`），**逐格点名**，`mismatch` 由 `2` 升到 `3` 且**新增的那条正是被篡改格**。⇒ 派单里"只报总判不点名"这条**不成立**（牙确实点名）。

**（c）第三条腿（我自造）：表行数 ≠ 9 ⇒ `NOINFO`（不许静默判绿）—— 成立**
删掉副本的 `| 9 |` 行：
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --file ~/w-scout-t50/fix/rows8.md   # ts=2026-09-28T17:57:42.040+0800
HANDOFF_MV=NOINFO reason=table-rows!=9 got=8 anchor=逐格对照（「现取值」全部由右侧命令现跑取得 file=…/rows8.md
$ echo $?   ⇒ 2
```

**（d）射程边界（我自造，**不利读数，如实记**）：表格「现取值」列在 9 格上**全部被更正行取代** ⇒ 改它**看不见**
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --file ~/w-scout-t50/fix/tamper-row2.md   # 只把表 #2 行 `226` 改成 `999`
HANDOFF_MV_CELL cell=#2 anchor=§7-4 覆盖面件数 state=equal live=233
HANDOFF_MV=FAIL cells=9 equal=7 manual=0 mismatch=2     # ⇒ 与未篡改时**完全同形**，无新 HIT
$ echo $?   ⇒ 1        # ts=2026-09-28T17:56:25.774+0800
```
⇒ 机制上成立（更正行**优先级 ①**已在牙头写死、`corr_of()` 取**最后一条**），**不是缺陷**；但它意味着**"表原文"这一列已经完全没有判据力**（9/9 格都有更正行）⇒ 派单里"把 9 格表里某一格篡改一个字符 ⇒ 必红"这句**在"表列"上不成立、只在"更正行"上成立**。如实记。

**判词①**：**不成立**（按契约字面：须印 `HANDOFF_MV=PASS cells=9`，现取 `FAIL mismatch=2`）。**点名射程这一半成立**（四格齐全、逐格点名、`NOINFO` 不静默），**`PASS` 这一半不成立且是结构性的** —— 见 §5「推翻的话」第 1 条。

---

### ②（对应派单第 2 条）9 格的真值 —— **7/9 同、2/9 不同 ⇒ 不成立**

**我自己现跑生成**（**不照抄** `t48` 的表；抽取器＝我自写：扫描**每格最后一条**更正行取 `现值 ＝ \`X\`` 与 `命令：\`Y\``，然后**在 `$R` 里 `bash -c Y` 取 stdout 首行去尾空白**）：
`ts=2026-09-28T17:56:30.038+0800`

| 格 | 处（内容锚） | 件内文本（＝最后一条更正行） | 我现取值 | 同否 | 我现跑的命令（原文） |
|---|---|---|---|---|---|
| `#1` | `§7-4 输入指纹` | `cf1db0977551a6d7213c0293a4cbf8545a025184caf14f1d5a6823f41de6ba7d` | 同 | **同** | `bash ~/w153a/bin/infp.sh fp` |
| `#2` | `§7-4 覆盖面件数` | `233` | `233` | **同** | `bash ~/w153a/bin/infp.sh list \| wc -l` |
| `#3` | `§7-1 冻结世代` | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 同 | **同** | `sed -n '9p' docs/CURRENT-STATE.md` |
| `#4` | `§7-3 登记册自洽` | `DEFREG=PASS declared=218 route_ids=218（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）` | 同 | **同** | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -1` |
| `#5` | `§7-5 步数` | `61` | `61` | **同** | `grep -c '^run_step "' verify-all.sh` |
| `#6` | `§7-5 放行标记` | `w*-POST.done=25／*record*=49` | `w*-POST.done=25／*record*=49` | **同** | `printf 'w*-POST.done=%s／*record*=%s' "$(ls -1 ~/w21-verify/w*-POST.done 2>/dev/null \| wc -l)" "$(ls -1 ~/w21-verify/*record* 2>/dev/null \| wc -l)"` |
| `#7` | `§7-6 推送面` | **`1d136ca`** | **`3aaaa3e`** | **不同** | `git log --oneline -1 \| cut -c1-7` |
| `#8` | `§2 在飞` | **`11`** | **`1`** | **不同** | `git status --porcelain \| grep -v 'build/MilBridge/HANDOFF-NEXT.md' \| grep -v 'build/MilBridge/P1-w4b-report.md' \| wc -l` |
| `#9` | `§1 九位` | `f951e80b55e85782` | `f951e80b55e85782` | **同** | `sed -n '104,115p' build/MilBridge/tools/wave-freeze-consistency-check.py \| sha256sum \| cut -c1-16` |

**逐格证据（件＋字段＋亚秒时刻）**
- `#1`：件 `build/MilBridge/HANDOFF-NEXT.md`（`ce0e80aab999b2ac`）§「机器值『现取生成契约』」块末尾更正行 `⏪ **机器值契约更正 · cell=#1**`（三块中**最后一块**，`ts=2026-09-28T17:51:30.670+0800`）；我现跑 `ts=2026-09-28T17:56:30.038+0800`。
- `#7` **关键**：件内该格的值**恒等于"写它那一刻的 `HEAD` 短哈希"** —— 现取 `HEAD` ＝ `3aaaa3e`，件内写 `1d136ca` ＝ **`t48` 当时的 `HEAD`**。⇒ 这一格的对拍对象是**可变量**。
- `#8` **关键**：命令**排除**了 `HANDOFF-NEXT.md` 与 `P1-w4b-report.md`，但**没有排除** `verify-all.sh`／`build/close-wave.sh`／`docs/WAVE81-PREREGISTRATION.md`／三件 `W4a` 牙 ⇒ 该格的值**必然**在"本波被提交"的那一刻从 `11` 掉到 `1`。⇒ 也是**可变量**。

**关于"表内已声明的 3 个陈旧格须已改成「以现取为准 ＋ `ts=`」形态且带亚秒戳"**：
- 现取 `grep -c '机器值契约更正' build/MilBridge/HANDOFF-NEXT.md` ＝ **31**；`grep -c 'ts='` ＝ **56**。
- **9 格全部**都有更正行（不止 3 格），且**每一条都带 `ts=2026-09-28T17:4x–17:5x+0800` 亚秒戳**、形态逐字为 `⏪ **机器值契约更正 · cell=#N**：以现取为准；\`ts=…\` 时 现值 ＝ \`X\`（命令：\`Y\`）`。⇒ **"3 个陈旧格已改"这一条成立且超额**（9/9）。
- ⚠️ 但注意：**"以现取为准"这句话本身只在 `ts=` 那一刻为真**（`#7`／`#8` 在 `17:55:01` 就失效）⇒ 形态**成立**、**内容生命周期 ≤ 本波**。

**判词②**：**不成立**（9 格逐格自算得 **2 格与现取不符**）。⇒ 与判词①同因。

---

### ③（对应派单第 3 条）`B-15` 两极 —— **成立**

**我自造的三个夹具**（`~/w-scout-t50/fix/pm/{empty,missing,none}/m.done`），跑 `--dir` 模式：
```
$ bash build/MilBridge/tools/push-marker-check.sh --dir ~/w-scout-t50/fix/pm/empty      # ts=2026-09-28T17:56:40.199+0800
PUSHMARKER_HIT file=/home/links-dev/w-scout-t50/fix/pm/empty/m.done field=push_rc rule=empty-value
PUSHMARKER_DIR dir=…/pm/empty markers=1 bad=1
$ echo $? ⇒ 1
$ bash build/MilBridge/tools/push-marker-check.sh --dir ~/w-scout-t50/fix/pm/missing    # 同一命令串
PUSHMARKER_HIT file=…/pm/missing/m.done field=stop_line rule=missing-field
PUSHMARKER_DIR dir=…/pm/missing markers=1 bad=1
$ echo $? ⇒ 1
$ bash build/MilBridge/tools/push-marker-check.sh --dir ~/w-scout-t50/fix/pm/none      # 同一命令串
PUSHMARKER_DIR dir=…/pm/none markers=1 bad=0
$ echo $? ⇒ 0
```
⇒ **空值 ⇒ 必红并点名 `field=push_rc rule=empty-value`（成立）**；**缺行 ⇒ 必红并点名 `field=stop_line rule=missing-field`（成立）**；**`none(<reason>)` ⇒ `bad=0`／`rc=0`（放行、不判红）（成立）**。

**默认（集成）模式我另跑一遍**：
```
$ bash build/MilBridge/tools/push-marker-check.sh     # ts=2026-09-28T17:56:44.512+0800
PUSHMARKER_ANTIPOLE empty-value=red-named missing-field=red-named
PUSHMARKER=PASS mode=integration fields=3 antipole-empty-value=red antipole-missing-field=red writer=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/tools/push-marker-write.sh
$ echo $? ⇒ 0
```
**写入端「取不到 ⇒ 写 `none(<reason>)` 且上屏」我单独验**：写入端**不带** `--push-rc/--stop-line/--remote` 时三字段默认即 `none(reason=not-run)`，成功输出行逐字为 `MARKER=PASS file=<f> fields=3 push_rc=<a> stop_line=<b> remote=<c>` ⇒ **值确实上屏**（由**写入端**承担）。
⚠️ **观察（不判红，如实记）**：**判据端**在**两种**模式下都**不印逐字段值行** —— 集成模式 `judge_marker "$T/m.done" >/dev/null`；`--dir` 模式 `scan_dir` 把 `judge_marker` 的 stdout 也丢掉（只在失败时 `grep HIT`）⇒ 好标记`none(...)`的**具体值**只出现在**写入端**的输出里。派单那句"`none(<reason>)` **上屏**"因此**由写入端成立、由判据端不成立**。

**覆盖面核对（我逐行核对该路径）**：
```
$ bash ~/w153a/bin/infp.sh list > /tmp/t50-list.txt ; sed 's/^[0-9a-f]\{64\}  //' /tmp/t50-list.txt | sort > /tmp/t50-paths.txt
$ wc -l < /tmp/t50-paths.txt     ⇒ 233
$ grep -cx build/MilBridge/tools/push-marker-write.sh  /tmp/t50-paths.txt  ⇒ 1
$ grep -cx build/MilBridge/tools/push-marker-check.sh  /tmp/t50-paths.txt  ⇒ 1
$ grep -cx build/MilBridge/tools/handoff-machine-values-check.sh /tmp/t50-paths.txt ⇒ 1
$ grep -cx build/MilBridge/tools/provider-repro-check.sh /tmp/t50-paths.txt ⇒ 1
```
`ts=2026-09-28T17:56:44.512+0800` ⇒ **「仓内写标记的件」`push-marker-write.sh` 确实在覆盖面内**（命中 1）。**判词③：成立。**

---

### ④（对应派单第 4 条）`B-18` 免钉定则的可见性 —— **成立**

**我自造两个假产物目录**（`PRC_ROOT` 隔离；`~/w-scout-t50/fix/prc/{same,diff}`）：
```
$ PRC_ROOT=~/w-scout-t50/fix/prc/same bash build/MilBridge/tools/provider-repro-check.sh --a x/p.dll --b y/p.dll   # ts=2026-09-28T17:56:49.019+0800
PROVIDER_REPRODUCIBLE=yes a=x/p.dll b=y/p.dll sha16=cb1ad2119d8fafb6
$ echo $? ⇒ 0
$ PRC_ROOT=~/w-scout-t50/fix/prc/diff bash build/MilBridge/tools/provider-repro-check.sh --a x/p.dll --b y/p.dll   # 同一命令串
PROVIDER_REPRODUCIBLE=no a=x/p.dll a_sha16=cb1ad2119d8fafb6 b=y/p.dll b_sha16=dcdb704109a45478（两值逐位不同 ⇒ **上屏、不判红**；按在册设计态，本牙只保证「位移可见」）
$ echo $? ⇒ 0
$ PRC_ROOT=~/w-scout-t50/fix/prc/diff bash build/MilBridge/tools/provider-repro-check.sh --a x/p.dll --b z/p.dll   # 同一命令串
PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=z/p.dll
$ echo $? ⇒ 3
```
⇒ **`no` 时两个值都点名上屏（`a_sha16=`／`b_sha16=`）且 `rc=0` 不判红 —— 不静默（成立）**；**`yes` 时印 `yes`（成立）**；**缺席 ⇒ `NOINFO`（不算绿）（成立）**。

**真腿（两次真实构建）的记法**：
- 牙件头（`build/MilBridge/tools/provider-repro-check.sh`，`8b9662e5c01c377d`）逐字写：`⚠️ **射程边界（如实写）**：本牙**不**判「构建是否确定」——它只把**读数**变可见；` `「连跑两次真构建」的真腿**归重活波**（`t48` 记 `NOINFO(reason=真腿归重活波)`）。`
- 交件报告 `build/MilBridge/P1-w4b-report.md`（`c52924f89f932965`）的 `NOINFO` 段第 ① 条逐字：`**`B-18` 真腿**（连跑两次真实 `dotnet build`）**归重活波**（`reason=真腿归重活波`）—— 本波只落牙与口径，两极化用**自造夹具**跑通`。
⇒ **真腿**被**如实记为 `NOINFO(reason=真腿归重活波)`，没有被当成已测证据**（不是假绿）。**判词④：成立。**
（现取的生产默认档读数：`PROVIDER_REPRODUCIBLE=no a_sha16=24e4e0a731dbed40 b_sha16=7e8a217b4165a6b9`，`rc=0`；`ts=2026-09-28T17:56:49.019+0800` ⇒ 与 §7 的"未构建"一致。）

---

### ⑤（对应派单第 5 条）四处声明逐字一致 —— **成立（附一处具名点名）**

```
$ grep -c '^run_step "' verify-all.sh                                     ⇒ 61
$ grep -n '^# VERIFYALL-STEPS-DECL:' verify-all.sh | head -1              ⇒ 72:# VERIFYALL-STEPS-DECL: 61 gen=#81   ← ⏪ `t48`／W4b **合波加三步**（58 → 61）…
$ grep -m1 '^# VERIFYALL-STEP-NAMES:' verify-all.sh | sed 's/^# VERIFYALL-STEP-NAMES: //' | tr '|' '\n' | grep -c .   ⇒ 61
$ bash ~/w153a/bin/infp.sh list | wc -l                                   ⇒ 233
$ grep -o 'fp-manifest-step.sh --expect [0-9]*' verify-all.sh             ⇒ fp-manifest-step.sh --expect 233
$ bash build/MilBridge/tools/verify-all-step-check.sh | grep VERIFYALL_SELF
VERIFYALL_SELF=PASS names=61 decl=61 gen=#81 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=742175bffd5a175d
$ echo $? ⇒ 0
```
`ts=2026-09-28T17:56:57.398+0800`（前五行）／`ts=2026-09-28T17:57:37.567+0800`（末三行）

| 声明 | 值 | 与 `run_step` 数（61） | 与覆盖面（233） |
|---|---|---|---|
| ① 首行 `# VERIFYALL-STEPS-DECL:`（`decl_line()` **只取第一条**，现取 `:72`） | `61 gen=#81` | **一致** | 不适用 |
| ② 头注释口径句 | `**`#81` 收官起 = 61 步**` | **一致** | 不适用 |
| ③ `# VERIFYALL-STEP-NAMES:` | **61 项** | **一致** | 不适用 |
| ④ 预登记 `docs/WAVE81-PREREGISTRATION.md` | dated 追加行含 `# VERIFYALL-STEPS-DECL: 61 gen=#81` 与 `步数 **58 → 61**` | **一致** | 不适用 |
| `[42]` 步 `--expect` | `233` | 不适用 | **一致** |

⇒ **四处全一致**（`VERIFYALL_SELF=PASS … decl=61 … prereg=PASS` 为机器读者）。
⚠️ **具名点名（不判红）**：预登记件 §1 的**原文行**仍写 `= 58 步`／`覆盖面 226 → 229`（`t47` 时点）—— 现取该件内 `= 58 步` 与 `= 61 步` **各 1 处**（`ts=2026-09-28T17:57:37.567+0800`）。按本仓"只增不改 ＋ dated 追加取代"纪律，**以 dated 追加为准**，故不判红；但**读者若只读 §1 会得到 58**，如实点名。
**判词⑤：成立。**

---

### ⑥（对应派单第 6 条）既有史实行一字未改（**提交级** numstat ＋ 备份 `cmp`）—— **成立（有 3 处删行，逐行说明必要性）**

**（a）提交级 numstat（**不是** `git diff --numstat`；本仓在已提交件上后者恒空转、恒绿＝`D-G181`）**
```
$ git show --numstat --format='%H%n%ci%n%s' 3aaaa3e                # ts=2026-09-28T17:55:22.754+0800
3aaaa3e47d414c01a4e1887dbd93ff07e88585ba
2026-09-28 17:55:01 +0800
docs(#81): W4b 合波 —— B-11 机器值牙 / B-15 推送标记 / B-18 免钉定则 同趟接线（覆盖面 229→233，步数 58→61）
60      0       build/MilBridge/HANDOFF-NEXT.md
21      0       build/MilBridge/P1-w4b-report.md
180     0       build/MilBridge/tools/handoff-machine-values-check.sh
56      0       build/MilBridge/tools/provider-repro-check.sh
104     0       build/MilBridge/tools/push-marker-check.sh
50      0       build/MilBridge/tools/push-marker-write.sh
1       0       build/MilBridge/tools/sentinel-spec-check.sh
1       0       build/MilBridge/tools/timestamp-order-check.sh
1       0       build/MilBridge/tools/wave-push.sh
5       1       build/close-wave.sh
2       0       docs/WAVE81-PREREGISTRATION.md
12      2       verify-all.sh
```
**（b）3 处删行逐行说明**（原文照抄）：
1. `build/close-wave.sh`（`-1`）：`-            build/MilBridge/tools/timestamp-order-check.sh` ⇒ 改为该行尾加续行符 `\`，以便在其后追加 4 行白名单。**必要性：充分**（不删这一行无法追加；新行内容包含旧行全部文本）。
2. `verify-all.sh`（`-1`）：`-# VERIFYALL-STEP-NAMES: 主工程 WpfGfx.Linux | … | SENTINEL-SPEC | WAVE-PUSH | TS-ORDER` ⇒ 同一行追加 `| HANDOFF-MV | PUSH-MARKER | PROVIDER-REPRO`。**必要性：充分**。我独立验证**旧行是新行的严格前缀**：
   `$ case "$NEW" in "$OLD"*) echo NEW_STARTS_WITH_OLD=yes;; esac` ⇒ `NEW_STARTS_WITH_OLD=yes`（`ts=2026-09-28T17:57:06.432+0800`）。
3. `verify-all.sh`（`-1`）：`-run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 229` ⇒ 改成 `--expect 233`。**必要性：充分**（本仓成文规则：覆盖面变 ⇒ `--expect` **同趟**改；且 §5 已现取 `coverage=233`）。

**（c）历史 `# VERIFYALL-STEPS-DECL:` 行**（本仓明令"史实行只许追加、不许改"）：
```
$ diff <(git show 1d136ca:verify-all.sh | grep '^# VERIFYALL-STEPS-DECL:') <(git show HEAD:verify-all.sh | grep '^# VERIFYALL-STEPS-DECL:')
0a1
> # VERIFYALL-STEPS-DECL: 61 gen=#81   ← ⏪ `t48`／W4b **合波加三步**（58 → 61）：…
```
⇒ **差集只有"在首行之前插入 1 行"**（`0a1`），**其余每一条历史 `DECL` 行逐字节相同**。`ts=2026-09-28T17:57:06.393+0800`

**（d）备份 `cmp`（**我找到并逐件核过** `t48` 的 `cp -p` 备份，`/home/links-dev/w281-scribe/bak/*.pre-t48`）**：
```
$ for 7 对（repo 路径 : 备份名）: cmp <bak>/<name>.pre-t48  <(git show 1d136ca:<repo>)
IDENTICAL  backup=324af17e7318a4a0  gitpre=324af17e7318a4a0  verify-all.sh
IDENTICAL  backup=be7a581b5f88621d  gitpre=be7a581b5f88621d  build/close-wave.sh
IDENTICAL  backup=0ba2174ffa88fc1d  gitpre=0ba2174ffa88fc1d  build/MilBridge/HANDOFF-NEXT.md
IDENTICAL  backup=f2938319558f5e91  gitpre=f2938319558f5e91  docs/WAVE81-PREREGISTRATION.md
IDENTICAL  backup=8c8470a3b3dd0c0d  gitpre=8c8470a3b3dd0c0d  build/MilBridge/tools/sentinel-spec-check.sh
IDENTICAL  backup=6ace8e29f3cf6357  gitpre=6ace8e29f3cf6357  build/MilBridge/tools/timestamp-order-check.sh
IDENTICAL  backup=abc03532b87d6c0e  gitpre=abc03532b87d6c0e  build/MilBridge/tools/wave-push.sh
```
`ts=2026-09-28T17:57:21.355+0800`。⇒ **备份 == `git` 改前逐字节原件，7/7**（备份不是"混合态"，`D-G126` 口径满足）。
**判词⑥：成立**（删行 3 处**全部**是"同一行的续行/同值替换/追加前缀"，**无一处删除语义**；且**历史 `DECL` 行逐字节未改**）。

---

### ⑦（对应派单第 7 条）未跑整趟门禁 —— **成立**

**（a）构建产物 `sha16` ＋ `mtime`（**都在 `t48` 窗口 `17:47–17:55` 之前**）**
```
$ stat -c '%y  %s  %n' <两处 provider 与 win32shim 等>            # ts=2026-09-28T17:56:57.488+0800
2026-09-28 13:11:49.073048849 +0800  104448  build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll
2026-09-28 10:24:21.358108926 +0800  104448  build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll
2026-09-28 10:30:08.405917592 +0800  336984  src/WpfGfx.Linux.Native/bin/libwpfwin32.so
2026-09-28 10:28:06.518135058 +0800 3601408  build/PresentationCore.Linux/bin/Release/PresentationCore.dll
$ sha256sum <同四件> | cut -c1-16  ⇒ 24e4e0a731dbed40 ／ 7e8a217b4165a6b9 ／ 6825dd7071387a46 ／ 5b6cfda3e12b84fc
```
⇒ `provider`（canon）`24e4e0a731dbed40` ＋ mtime `13:11:49`、`win32shim` `6825dd7071387a46` ＋ mtime `10:30:08` —— **两者都在 `t48` 开工（`17:47:04`）之前 4.5 小时以上** ⇒ **本波期间没有任何构建落地**。

**（b）`build/`／`src/` 下 `17:40` 之后被写过的**全部** 11 件**（逐件列举，**零构建产物**）：
```
$ find build src -newermt '2026-09-28 17:40' -type f | sort        # ts=2026-09-28T17:57:00.720+0800
build/close-wave.sh
build/MilBridge/HANDOFF-NEXT.md
build/MilBridge/P1-task0201-criteria.md
build/MilBridge/P1-w4b-report.md
build/MilBridge/tools/handoff-machine-values-check.sh
build/MilBridge/tools/provider-repro-check.sh
build/MilBridge/tools/push-marker-check.sh
build/MilBridge/tools/push-marker-write.sh
build/MilBridge/tools/sentinel-spec-check.sh
build/MilBridge/tools/timestamp-order-check.sh
build/MilBridge/tools/wave-push.sh
```
⇒ 11 件**全是** `.sh`／`.md`，**没有 `bin/`／`obj/`／`*.dll`／`*.so`**。

**（c）整趟门禁的运行痕迹：**
```
$ find ~ -maxdepth 3 -newermt '2026-09-28 17:40' \( -name '*verify-all*' -o -name '*gate*' \) | head      ⇒ 空
$ ls -lt --time-style=full-iso ~/w21-verify/ | head -3
-rw-r--r-- 1 links-dev links-dev 150036 2026-09-28 15:54:56.394981633 +0800 w27-freeze.py
-rw-r--r-- 1 links-dev links-dev      0 2026-09-28 11:51:17.112475971 +0800 w80-POST.done
$ ls ~/w21-verify/w*-POST.done | wc -l    ⇒ 25        # 无 w81-POST.done
```
`ts=2026-09-28T17:57:31.572+0800` ⇒ **无 `w81` 放行标记、无新门禁日志**；`~/w21-verify` 最新件是 `15:54:56` 的 `w27-freeze.py`（**早于 `t48` 开工**）。
⇒ `t48` 报告 `NOINFO` ③ `**未跑整趟 `verify-all`**（会构建 ⇒ `provider` 位位移…）` **与机器证据一致**。
**判词⑦：成立。**（⚠️ 同刻机器上有**他人**在跑 `dotnet HandyControlDemo.dll`，见 §0 —— **不是** `t48` 的门禁痕迹。）

---

### ⑧（对应派单第 8 条）未越域 —— **部分成立、部分不成立**

```
$ 对 5 件：pre＝git show 1d136ca:<件> | sha256sum -c1-16 ；now＝sha256sum <件>      # ts=2026-09-28T17:57:21.449+0800
UNCHANGED  pre=26841d6ed6fe8085 now=26841d6ed6fe8085   docs/ROUTES.md
UNCHANGED  pre=6a1ca425a94c4fae now=6a1ca425a94c4fae   samples/WpfFeatureProbe/KNOWN-DEFECTS.md
UNCHANGED  pre=caac65d50ca90c3b now=caac65d50ca90c3b   build/MilBridge/tools/defect-registry-declared.tsv
CHANGED    pre=8c8470a3b3dd0c0d now=063cfab87fc40876   build/MilBridge/tools/sentinel-spec-check.sh
CHANGED    pre=6ace8e29f3cf6357 now=5c0320c779e71fc8   build/MilBridge/tools/timestamp-order-check.sh
$ cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag  ⇒ IDENTICAL（rc=0）
$ sha256sum <两枚哨兵> | cut -c1-16  ⇒ 6cb3f97388c3c4dc（两枚同值）；stat ⇒ 279 B，mtime 2026-09-28 13:48:27.398116209 +0800（两枚同 mtime）
```

| 件 | 改前 | 改后 | 判 |
|---|---|---|---|
| `docs/ROUTES.md` | `26841d6ed6fe8085` | `26841d6ed6fe8085` | **未改** ✔ |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `6a1ca425a94c4fae` | `6a1ca425a94c4fae` | **未改** ✔ |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `caac65d50ca90c3b` | `caac65d50ca90c3b` | **未改** ✔ |
| `/tmp/bridge-frozen.flag` | `6cb3f97388c3c4dc`／279 B／mtime `13:48:27.398116209` | 同值 | **未写**（`cmp` IDENTICAL）✔ |
| `~/wfp-runs/bridge-frozen.flag` | `6cb3f97388c3c4dc`／279 B／同 mtime | 同值 | **未写** ✔ |
| `build/MilBridge/tools/sentinel-spec-check.sh` | `8c8470a3b3dd0c0d`（模式 `100755`） | `063cfab87fc40876`（模式 `100644`） | **🔴 被改**（`+1` 行，且**丢掉可执行位**） |
| `build/MilBridge/tools/timestamp-order-check.sh` | `6ace8e29f3cf6357`（模式 `100755`） | `5c0320c779e71fc8`（模式 `100644`） | **🔴 被改**（同上） |

**（a）被改的那 1 行是什么、以及它造成的机器后果**（`git show 3aaaa3e --summary` 现取：`mode change 100755 => 100644` 三处 —— 含 `wave-push.sh`）。插入行**不在注释块内**（**行首无 `#`**），逐字（`sentinel-spec-check.sh` 第 `4` 行）：
```
⏪ **dated 更正（`t48`／W4b，读时 2026-09-28T17:47:04.418+0800）**：**已接线**：`verify-all.sh` 步名 `SENTINEL-SPEC`（`run_step "SENTINEL-SPEC" bash build/MilBridge/tools/sentinel-spec-check.sh`）＋ **覆盖面已计入**（`build/close-wave.sh` 的 `fp_inputs()`；现取件数 **233**）⇒ 上一行的「接线归 W4」**自此过期**（**原句一字未删**，以本行为准）。
```
⇒ `bash` 把 `⏪` 当**命令**执行，并对该行里的反引号做**命令替换**。**三件各自实测**（**stderr 与 stdout 分开取**）：
```
$ bash build/MilBridge/tools/sentinel-spec-check.sh  >/tmp/t50-ss.out 2>/tmp/t50-ss.err ; echo rc=$?   # ts=2026-09-28T17:55:00.555+0800
rc=0
$ cat /tmp/t50-ss.err          # 7 行
{file}: 行 4: t48: 未找到命令
{file}: 行 4: verify-all.sh: 未找到命令
{file}: 行 4: SENTINEL-SPEC: 未找到命令
{file}: 行 4: run_step: 未找到命令
{file}: 行 4: build/close-wave.sh: 权限不够
{file}: command substitution: 行 5: 语法错误：未预期的文件结束符
{file}: 行 4: ⏪: 未找到命令
$ bash build/MilBridge/tools/timestamp-order-check.sh >/tmp/t50-ts.out 2>/tmp/t50-ts.err ; echo rc=$?   # ts=2026-09-28T17:55:08.918+0800
rc=0 ; stderr_lines=7（同形，含 `command substitution: 行 6: 语法错误：未预期的文件结束符`）
$ bash build/MilBridge/tools/wave-push.sh --dry-run >/tmp/t50-wp.out 2>/tmp/t50-wp.err ; echo rc=$?      # 同一命令串
rc=0 ; stderr_lines=8（同形，行号 `21`）
```
⇒ **三件都把错误打到 `stderr`、`rc` 仍 `0`、判词行（`SSC=PASS`／`TSORDER=PASS`／`WPW=DRYRUN`）照常**。`verify-all.sh` 的 `run_step` 现取实现为 `"$@" > "$log" 2>&1` ⇒ 这些错误行会**进入该步日志**（不会被当判词行显示，日志末尾 `rm -f`），**不改 `rc`**。
**并且**：那条未闭合的 `command substitution` **吃掉了紧随其后的注释行**（`行 5: 语法错误`；`sentinel-spec-check.sh` 的第 `5` 行 `#`）⇒ **件头注释块被破坏**（有内容被判为命令替换体）。
⚠️ **`bash -n` 看不见这一族**：我对 9 件跑 `bash -n` **全 `rc=0`**（含这三件，`ts=2026-09-28T17:57:31.522+0800`）⇒ 行是**语法合法**的普通命令，只有**运行期**才炸。这正是 `t48` §6 那句"`bash -n` 9 件全过"**为真却漏掉本缺陷**的原因（与 `D-G119`「注释域/证据域」同族）。
**（b）我另跑两颗可能被反引号咬的牙**（自证不是全域污染）：`bash build/MilBridge/tools/shell-quote-trap-check.sh` ⇒ `rc=0`（末行 `SHELL_QUOTE_DIAGN kind=PY-BACKTICK-FILE n_files=76 n_lines=2032`）；`bash build/MilBridge/tools/pipefail-sigpipe-check.sh` ⇒ `PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=97 hit=0 low=8 diag=4 safe=85 runs=12`，`rc=0`。`ts=2026-09-28T17:57:47.488+0800` ⇒ **未牵连其它牙**。

**判词⑧**：**部分成立、部分不成立**。`ROUTES.md`／`KD`／`declared.tsv`／两枚哨兵 **5 件逐位未变、哨兵 `cmp` IDENTICAL（成立）**；**`sentinel-spec-check.sh` 与 `timestamp-order-check.sh` 本体被改（不成立）**，且改动**引入运行期 stderr 污染（含一处语法错误）＋ 丢掉 `100755` 可执行位**（`wave-push.sh` 同样丢位）。

---

## §2 `verified` 汇总（逐条）

| # | 复核项 | 判词 | 关键读数 |
|---|---|---|---|
| 1 | `B-11` 牙对拍射程（含自造反极） | **不成立**（点名射程这一半成立） | `HANDOFF_MV=FAIL cells=9 equal=7 mismatch=2 rc=1`；自造篡改 ⇒ 新增 `cell=#2 … in-repo=230 live=233` |
| 2 | 9 格真值逐格自算 | **不成立** | 7 同／2 不同（`#7` `1d136ca` vs `3aaaa3e`；`#8` `11` vs `1`） |
| 3 | `B-15` 两极（自造夹具） | **成立** | `field=push_rc rule=empty-value` rc=1；`field=stop_line rule=missing-field` rc=1；`none()` `bad=0` rc=0；写入端在覆盖面内命中 1 |
| 4 | `B-18` 免钉定则可见性 | **成立** | `=no a_sha16=… b_sha16=…` rc=0；`=yes` rc=0；缺席 `NOINFO` rc=3；真腿记 `NOINFO(reason=真腿归重活波)` |
| 5 | 四处声明逐字一致 | **成立** | 61／61／61；`[42] --expect 233`；`VERIFYALL_SELF=PASS names=61 decl=61 prereg=PASS` |
| 6 | 只增不改（提交级 numstat ＋ 备份 `cmp`） | **成立** | `3aaaa3e`：`verify-all.sh 12/2`、`close-wave.sh 5/1`；3 处删行逐行说明；历史 `DECL` 行 `diff 0a1`；7 件备份 `cmp` IDENTICAL |
| 7 | 未跑整趟门禁 | **成立** | `provider` `24e4e0a731dbed40` mtime `13:11:49`、`win32shim` `6825dd7071387a46` mtime `10:30:08`；`17:40` 后新写 11 件**零构建产物**；无 `w81-POST.done` |
| 8 | 未越域 | **部分不成立** | 5 件逐位未变＋哨兵 `cmp IDENTICAL`（成立）；`sentinel-spec-check.sh`／`timestamp-order-check.sh` **被改**（各 `+1` 行、`100755→100644`）且新行**不在注释块内** |

---

## §3 `NOINFO`（具名，既不算绿也不算红）

1. **第 1 条的"`HANDOFF_MV=PASS cells=9` 是否曾在 `t48` 的量取时刻成立"**：`NOINFO(reason=无法在不移动 `HEAD`／不改工作树的前提下重建 `t48` 量取时刻的世界；`t48` 自报 `equal=9`，我现取 `equal=7`，两者不可同槽复算)`。**机制证明**（不是猜测）：`#7` 的件内值 `1d136ca` **恰等于** `t48` 当时的 `HEAD`，现取 `HEAD` 已推进 ⇒ 该格**必然**由绿转红。
2. **第 4 条"真腿（连跑两次真实构建）"**：`NOINFO(reason=重活；本件只读、不跑构建)` —— 且**这正是 `t48` 自己的记法**（`NOINFO(reason=真腿归重活波)`），故**逐条判词④不因此变色**。
3. **第 3 条"仓外历史标记（`~/w14a` 10 枚／缺行 6）"**：`NOINFO(reason=非本波写域、不在 `verify-all.sh` 的语料里；我未跑 `--dir ~/w14a`（避免把仓外状态读成判据）)`。
4. **第 8 条"三件牙丢失的 `100755` 可执行位是否影响生产"**：`NOINFO(reason=现取 `verify-all.sh` 一律以 `bash <件>` 调用（`run_step` 逐条现取均形如 `bash build/MilBridge/tools/…`）⇒ 位丢失在本仓调用形态下无功能后果；但仓外/他人若直接执行该件 ⇒ 会 `Permission denied`，本件无法穷举仓外调用者)`。
5. **第 7 条"他人 `dotnet HandyControlDemo.dll`（PID `2104668`／`2104672`）属谁"**：`NOINFO(reason=本件不按模式匹配进程身份；只按 PID 现取到 `etimes=40 s`，未读 `/proc/<pid>/cmdline` 之外的归属信息，也不属于被复核范围)`。

---

## §4 「推翻的话」（逐条具名）

1. **推翻 `t48` §1 的 `HANDOFF_MV=PASS cells=9 equal=9` 与 `HANDOFF_MV_SELFTEST=PASS cases=3 pass=3 fail=0`**：现取（`HEAD=3aaaa3e`，被对拍件 `HANDOFF-NEXT.md` 与 `t48` 自报值**逐位相同**）⇒ `HANDOFF_MV=FAIL cells=9 equal=7 mismatch=2 rc=1`、`HANDOFF_MV_SELFTEST=FAIL cases=3 pass=2 fail=1 rc=1`。**根因不是执行失误，是判据自我否定**：`#7` 的对拍对象是 `HEAD` 短哈希、`#8` 的对拍对象是工作树脏件数 ⇒ **本波一旦被提交（本仓流水线的下一步）这两格必崩**。⇒ 在 `verify-all.sh` 里 `HANDOFF-MV` 这一步**现在会显示 ❌**（`run_step` 现取实现：`rc != 0` ⇒ 计入失败）。**这是本复核最重要的一条。**
2. **推翻 `t48` §1 反极"改最后一次更正一位 ⇒ `cell=#9`"的**可复用性**：我照它的做法（改**最后一条**更正行）跑，输出的首条 `HIT` 是 `cell=#7` —— 因为 `selftest` 里 `grep -m1 'HANDOFF_MV_HIT'` 取的是**第一条**，而被篡改的格（`#8`）排在后面 ⇒ **`S2` 的"点名"与"被篡改格"不保证同格**。（我的自造反极改 `#2`、读到 `mismatch 2→3` 且新增行正是 `#2` ⇒ **牙本身的点名能力成立**，问题只在 `selftest` 的取样行。）
3. **推翻 `t48` §6「`bash -n` 9 件全过」被当作充分证据的用法**：`bash -n` 现取确实 **9/9 `rc=0`**（**那句话为真**），但**三件被改的牙在运行期**各打 7–8 行 `stderr`（含 `command substitution: 行 5: 语法错误：未预期的文件结束符`）⇒ **`bash -n` 结构上看不见这一族**。⇒ 应收紧为"落仓后必须**真跑**该件并断言 `stderr` 空"。
4. **点名 `t48` §9 的路径笔误**：交件报告写 `063cfab87fc40876`（`data/MilBridge/tools/sentinel-spec-check.sh`），实际路径是 `build/MilBridge/tools/sentinel-spec-check.sh`（`data/` 不存在该件）。sha16 现取**逐位相同**（`063cfab87fc40876`）⇒ **只是路径笔误，不是读数错**。
5. **收紧派单第 1 条里"把那张 9 格表里某一格篡改一个字符 ⇒ 牙必红"这句话的射程**：现取 **9/9 格都有更正行**（更正行优先级 ①）⇒ **改"表格「现取值」列"完全不可见**（我的 `tamper-row2.md` 夹具：`equal=7 mismatch=2`，与未篡改同形）。**必须改成"篡改该格最后一条更正行的值"**才成立。
6. **收紧派单第 3 条"`none(<reason>)` 上屏"的射程**：现取**判据端两种模式都不印逐字段值行**（集成模式 `judge_marker … >/dev/null`；`--dir` 模式 `scan_dir` 亦丢弃 stdout）⇒ **"上屏"由写入端承担**，判据端只出汇总行。**判词③仍成立**（写入端确凿上屏），但"上屏"的载体必须写明是写入端。
7. **点名派单第 8 条的期望与现场不符**：派单把 `sentinel-spec-check.sh`／`timestamp-order-check.sh` 当作"未越域"的对照件，而现取它们是**本波唯二被改的本体**（各 `+1` 行、位 `100755→100644`）。⇒ 要么把它们移出"未越域清单"并另立"件头更正是否允许改本体"的判据，要么要求更正行**写成注释行**（`# ⏪ …`）以免运行期污染。
8. **对 `t48` §2 的一处**口径收紧**（非推翻，属补强）**：`t48` §2 写"`DECL` 首行 `61 gen=#81`（`:71`）`／`--expect` `233`（`:1199`）" —— 我现取 `grep -n '^# VERIFYALL-STEPS-DECL:' verify-all.sh \| head -1` ⇒ **`:72`**；`grep -n 'fp-manifest-step.sh --expect' verify-all.sh` 见 `:1195`。**值一致、行号不同**（`t48` 用 `:71`／`:1199` 是**它写值那一刻的插入前坐标**）⇒ 再次印证本仓纪律 31「引行号必须先 `sed -n` 现取」。

---

## §5 边界（如实划界）

- **只读**：被复核的每一件（`HANDOFF-NEXT.md`／`verify-all.sh`／`build/close-wave.sh`／`WAVE81-PREREGISTRATION.md`／三件 `W4a` 牙／四个新件／两枚哨兵／`ROUTES.md`／`KD`／`declared.tsv`）**一字未改**；夹具全部落在 `/home/links-dev/w-scout-p1`／`~/w-scout-t50/**` 与 `/tmp/t50-*`。本件是**唯一**写入 `$N` 的件（`temp+rename`）。
- **未跑整趟门禁、未构建、未起显示位、未跑腿批、未推送、未 `git add/commit`**。
- **`HEAD` 在我复核期间被他人推进**（`1d136ca → 3aaaa3e`）—— 这是**现取事实**，本件按两档分别标注（§0）；**判词①/② 的"不成立"因此不是"复核者故意挑时点"，而是"判据在本仓流水线的下一步就自证伪"**。
- 我**未**判 `t48` 的其它面（`inputs_fp` 归因、`SELFDESC-WIRING` 成对、`WIRING_CLOSURE` 修复）；派单未要求，且本件不做超范围结论。

---

`P1-W4B-VERIFY 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 91dc87b5dffe0293（口径＝末行之前的全文；末行＝本行；全文 `sha16` 只在交件消息里给）`
