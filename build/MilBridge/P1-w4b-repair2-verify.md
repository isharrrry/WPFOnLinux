# P1-W4b **修复二轮**独立复核判词（`t58`，review-round-3）—— 对 `t57`（修 `t55` 判的 `needs_revision`：G1–G4）

> **复核者**：`scout`。**一切自己现取、自己造夹具**；**不复述** `t57` 的报告与交件消息当证据。
> **载体件命名**：本轮**不用**契约里那个 `build/MilBridge/P1-w4b-verify.md`（那是 `t50` 的载体，**已被提交**为 `2ccbdbf`）⇒ 本件落 **`build/MilBridge/P1-w4b-repair2-verify.md`**（与 `t57` 的 `P1-w4b-repair2-report.md` 配对）。
> **本件是本次复核唯一写入 `$N` 的件**（`temp+rename`）；被判的每一件**一字未改**；夹具全落 `~/w-scout-t58/**`、`/tmp/t58/**`。
> **全文 `sha16` 只在交件消息里给**；末行只携带 `head -n -1` 自证值。**所有读数带亚秒 `ts=`**。
> **纪律**：不拿 `bash -n` 当机器证；**凡读脚本 rc，一律不经管道**（`cmd >f 2>e; echo $?` —— 本条是本轮我自己的教训，见 §4-9）。

---

## §0-0 判词速览

| 复核项 | 判词 |
|---|---|
| ① `B-11` 牙射程（自造反极） | **成立** —— 正极 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 rc=0 stderr=0`；我自造 7 条夹具逐条命中点名 |
| ② 9 格真值（我自跑） | **成立** —— **8 同 ＋ 1 manual（`#7`）／0 不同** |
| ③ `B-15` 两极 | **成立** |
| ④ `B-18` 可见性 | **成立** |
| ⑤ 四处声明 ＋ 四条不变量 | **成立**（61／61／61／233／233，`VERIFYALL_SELF=PASS names=61 decl=61 prereg=PASS`） |
| ⑥ 只增不改（提交级 numstat ＋ 备份 `cmp`） | **成立**（3 件；2 件 `pre-t57` 备份 `cmp` IDENTICAL；无新模式位移） |
| ⑦ 未跑整趟门禁 | **成立** |
| ⑧ 未越域 | **成立**（`t57` 只动 3 件；`KD`／`declared.tsv` 的变动归 `t51`/`t53`/W5 车道） |
| `t50` G1／G2／G3／G4 | **四条全部按我给的修法落地并实测通过** |
| **🔴 新发现 H1（blocker）** | **`t57` 新引入 2 处 `DQ-BACKTICK`（`纪律 32` 明令禁止的形态）⇒ 已接线的 `[QUOTE-TRAP]` 步现取 `SHELL_QUOTE_TRAP=FAIL rc=1`；新写的那句判词被**静默吃掉 `#7`**。** |
| 新发现 H2 / H3 / H4（medium-low） | S5 参与闸而自述说"信息腿"（`D-G136` 同族）／ `#4` 的 `reason=foreign-lane-activity` 却落在 `DIVERGED` 头（`FOREIGN` 未启用）／ `#8` 新谓词判别力≈0（"在飞"信号自此**无判据**） |

---

## §0 快照（`ts=2026-09-28T18:24:39.407+0800` 起）

| 项 | 现取值 |
|---|---|
| `HEAD` | **`2ccbdbf`**（`docs(#81): t50 独立复核载体落仓 —— P1-w4b-verify.md（对 t48 判 needs_revision）`） |
| 本轮被判的修复提交 | **`4d04cb5`**（`docs(#81): t57 修复 —— G1-G4 收口：HANDOFF-MV 判据收回到「被门禁覆盖的世界」`，提交时刻 `2026-09-28 18:25:11 +0800`） |
| 祖先链（现取） | `2ccbdbf → 4d04cb5 → 5756671 → 2ee0657 → 05148bb → df5b6d1 → fcb5cd4 → 3aaaa3e → 1d136ca` |
| 工作树 `porcelain` | **1 行**：`?? build/MilBridge/P1-task0201-criteria.md`（**他人**的既存未跟踪件，我未读未改） |
| 暂存 | `git diff --cached --name-only \| wc -l` ＝ **0** |

**被判件现取（sha16／行数）**：牙 `build/MilBridge/tools/handoff-machine-values-check.sh` ＝ **`cde265d7eaad36d5`／238 行**｜`build/MilBridge/HANDOFF-NEXT.md` ＝ **`3044dd66c84cc903`／526 行**｜交件载体 `build/MilBridge/P1-w4b-repair2-report.md` ＝ **`c80058bfabbb580e`／53 行**（**与 `t57` 自报逐位相同**）｜`verify-all.sh` `742175bffd5a175d`／1322 行｜`build/close-wave.sh` `69c39feabe148c62`／720 行。
**四条不变量**（`ts=2026-09-28T18:27:18.658+0800`）：`^run_step "` ＝ **61**｜`DECL` 首行 ＝ **`61 gen=#81`**｜`STEP-NAMES` 项数 ＝ **61**｜`[42] --expect` ＝ **233** ＝ 现取覆盖面 **233**；机器读者 `VERIFYALL_SELF=PASS names=61 decl=61 gen=#81 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=742175bffd5a175d`。

---

## §1 逐条判词（1–8；末尾两条 ＝ 队长本波特加）

### ① `B-11` 牙的对拍射程（自造反极）—— **成立**
**（a）正极**（`ts=2026-09-28T18:24:44.880+0800`）
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh
…
HANDOFF_MV_DIAG cell=#4 declared_live=222 route_ids_live=222 declared_inrepo=222 route_ids_inrepo=222（**计数不是被判量**）
HANDOFF_MV_CELL cell=#4 anchor=§7-3 登记册自洽 state=equal …（判据＝前缀 ∧ 两值相等）
HANDOFF_MV_CELL cell=#7 anchor=§7-6 推送面 state=manual table=本地 HEAD == ls-remote == 88ab841414b6b5e2 corrected=- live=-（该格不对拍：见牙头口径句①②④）
HANDOFF_MV_CELL cell=#8 anchor=§2 在飞（本波预登记在位谓词（锚已在更正行改写；表内原锚='§2 在飞'） state=equal … corrected=in-wave-81-registered live=in-wave-81-registered
HANDOFF_MV_NOTE lane-activity=0（= 写域面（build/ docs/ samples/ src/ 根件）之外的脏件数；**旁注，不进 equal 计数、不影响 rc**）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
$ echo $? ⇒ 0        stderr_bytes = 0
```
**（b）我自造的 7 条夹具**（副本改**该格最后一条更正行**，仓内件未动）——**逐条点名正确**：

| 夹具 | 被改动 | 原样判词（节选） | rc |
|---|---|---|---|
| `t1.md` | `#1` 现值 → `DEADBEEF…` | `HANDOFF_MV_HIT cell=#1 anchor=§7-4 输入指纹 rule=cell-mismatch reason=covered-file-changed-since-ts in-repo=DEADBEEF00000000 live=75d21468…` ＋ `HANDOFF_MV=DIVERGED reason=cell-mismatch … reasons=,#1:covered-file-changed-since-ts` | 1 |
| `t2.md` | `#2` → `999` | `HIT cell=#2 … rule=cell-mismatch reason=count-changed-since-ts` ＋ `DIVERGED … reasons=,#2:count-changed-since-ts` | 1 |
| `t5.md` | `#5` → `999` | `HIT cell=#5 … reason=count-changed-since-ts` | 1 |
| `t8.md` | `#8` → `no-registration` | `HIT cell=#8 anchor=§2 在飞（本波预登记在位谓词…） rule=cell-mismatch reason=cell-value-changed-since-ts` | 1 |
| `t9.md` | `#9` → `…80` | `HIT cell=#9 … reason=external-state-changed-since-ts` | 1 |
| `rows8.md` | 删 `| 9 |` 行 | `HANDOFF_MV=NOINFO reason=table-rows!=9 got=8` | 2 |
| `t7.md` | `#7` **改回机读形态** | `HIT cell=#7 … rule=cell-7-not-comparable-to-HEAD reason=not-comparable` ＋ `HANDOFF_MV=FOREIGN reason=cell-not-comparable … uncomparable=1` | 1 |
| `t5git.md` | `#5` 命令 → `git status --porcelain \| wc -l` | `HIT cell=#5 … rule=cell-not-comparable-to-pipeline-state reason=not-comparable` ＋ `FOREIGN … uncomparable=1` | 1 |

（全套 `ts=2026-09-28T18:25:25.073–18:25:46.352+0800`）
⇒ **`cell=/anchor=/rule=/reason=/in-repo=/live=/cmd=` 齐全、逐格点名、`DIVERGED`/`FOREIGN`/`NOINFO` 三分到位**（G2／G3 的验收由我独立复现）。
**（c）`#4` 的新形态判据我另造 3 条腿**（`ts=2026-09-28T18:27:25.680+0800`）：live 改 `DEFREG=FAIL` ⇒ `HIT cell=#4 rule=route-file-changed-since-ts`；live 改 `declared=222 route_ids=221` ⇒ 同样点名（`HANDOFF_MV_DIAG … declared_live=222 route_ids_live=221`）；live 改 `DEFREG=NOINFO` ⇒ 同样点名 ⇒ **`#4` 收窄后仍抓住"状态词翻转 ∧ 两值不等 ∧ NOINFO"三类**，不是空判据。
**判词①：成立。**

### ② 9 格真值（我自跑生成，不照抄）—— **成立**
我自写抽取器（扫每格**最后一条**更正行取 `现值`／`命令`，再在 `$R` 里 `bash -c` 取 stdout 首行）。`ts=2026-09-28T18:27:09.142+0800`

| # | 判 | in-repo | live | 命令 |
|---|---|---|---|---|
| `#1` | **同** | `75d21468cc3d495e7d055f515f4ff61bc9d2db8c7e047683ec4f39a4181f07f5` | 同值 | `bash ~/w153a/bin/infp.sh fp` |
| `#2` | **同** | `233` | `233` | `bash ~/w153a/bin/infp.sh list \| wc -l` |
| `#3` | **同** | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 同值 | `sed -n '9p' docs/CURRENT-STATE.md` |
| `#4` | **同** | `DEFREG=PASS declared=222 route_ids=222（…）` | 同值 | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -1` |
| `#5` | **同** | `61` | `61` | `grep -c '^run_step "' verify-all.sh` |
| `#6` | **同** | `w*-POST.done=25／*record*=49` | 同值 | `printf 'w*-POST.done=%s／*record*=%s' "$(ls -1 ~/w21-verify/w*-POST.done \| wc -l)" "$(ls -1 ~/w21-verify/*record* \| wc -l)"` |
| `#7` | **manual** | `<非机读>`（口径句①②④） | — | — |
| `#8` | **同** | `in-wave-81-registered` | 同值 | `test -s docs/WAVE81-PREREGISTRATION.md && echo in-wave-81-registered \|\| echo no-registration` |
| `#9` | **同** | `f951e80b55e85782` | 同值 | `sed -n '104,115p' build/MilBridge/tools/wave-freeze-consistency-check.py \| sha256sum \| cut -c1-16` |

⇒ **8 同／1 manual／0 不同**（`t55` 那两处失配：`#4` 已用形态判据收口、`#8` 已换稳定谓词）。**判词②：成立。**

### ③ `B-15` 两极 —— **成立**（我自造夹具，`ts=2026-09-28T18:27:12.292+0800`）
```
empty   : PUSHMARKER_HIT file=…/empty/m.done field=push_rc rule=empty-value   ; PUSHMARKER_DIR … bad=1 ; RC=1
missing : PUSHMARKER_HIT file=…/missing/m.done field=stop_line rule=missing-field ; bad=1 ; RC=1
none    : PUSHMARKER_DIR dir=…/none markers=1 bad=0                            ; RC=0
集成腿  : PUSHMARKER_ANTIPOLE empty-value=red-named missing-field=red-named
          PUSHMARKER=PASS mode=integration fields=3 antipole-empty-value=red antipole-missing-field=red ; RC=0
覆盖面  : coverage_n=233；四件（write／check／handoff-machine-values／provider-repro）各 grep -cx = 1
```

### ④ `B-18` 可见性 —— **成立**（我自造两态夹具，`ts=2026-09-28T18:27:12.292+0800`）
```
YES    : PROVIDER_REPRODUCIBLE=yes a=x/p.dll b=y/p.dll sha16=cb1ad2119d8fafb6        ; RC=0
NO     : PROVIDER_REPRODUCIBLE=no a=x/p.dll a_sha16=cb1ad2119d8fafb6 b=y/p.dll b_sha16=dcdb704109a45478（两值逐位不同 ⇒ **上屏、不判红**…） ; RC=0
ABSENT : PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=z/p.dll            ; RC=3
```

### ⑤ 四处声明 ＋ 四条不变量 —— **成立**（见 §0；命令与两值：`run_step`=61／`names`=61／`decl=61 gen=#81`／`expect`=233／`coverage`=233）
⚠️ **具名点名（不判红）**：预登记 `docs/WAVE81-PREREGISTRATION.md` §1 原文行仍写 `= 58 步`／`226 → 229`（`t47` 时点），dated 追加给 `58 → 61`；按"只增不改 ＋ dated 取代"不判红。

### ⑥ 只增不改（提交级 numstat ＋ 备份 `cmp`）—— **成立**
```
$ git show --numstat --format='%H %ci %s' 4d04cb5              # ts=2026-09-28T18:27:18.658+0800
4d04cb5582672ddfb96e70fef6532cb2a26f627e  2026-09-28 18:25:11 +0800  docs(#81): t57 修复 —— G1-G4 收口…
10      0       build/MilBridge/HANDOFF-NEXT.md
53      0       build/MilBridge/P1-w4b-repair2-report.md
165     125     build/MilBridge/tools/handoff-machine-values-check.sh
$ git show 4d04cb5 --summary | grep -i 'mode change'   ⇒ (none)   # 无新模式位移
$ cmp <bak>/handoff-machine-values-check.sh.pre-t57 <(git show fcb5cd4:build/MilBridge/tools/handoff-machine-values-check.sh)
IDENTICAL  backup=e4c13eea198753ff  gitpre=e4c13eea198753ff
IDENTICAL  backup=b81567e26c29a527  gitpre=b81567e26c29a527   （HANDOFF-NEXT.md）
```
⇒ 牙的 `165/125` 是**功能改写**（新增 `REJECT_ERE`／`#7` 真牙／`make_fixture`／S5／报头四分），**旧行内容在 `git show fcb5cd4:` 可取回**；两件备份与 `git` 改前原件**逐位相同**（不是混合态，`D-G126` 口径满足）。**判词⑥：成立。**

### ⑦ 未跑整趟门禁 —— **成立**
```
$ stat -c '%y %s %n' …   # ts=2026-09-28T18:27:18.853+0800
2026-09-28 13:11:49.073048849 +0800  104448  build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll  (24e4e0a731dbed40)
2026-09-28 10:30:08.405917592 +0800  336984  src/WpfGfx.Linux.Native/bin/libwpfwin32.so                                       (6825dd7071387a46)
$ find build src -newermt '2026-09-28 18:18' -type f | sort
build/MilBridge/HANDOFF-NEXT.md
build/MilBridge/P1-dg184-verify.md
build/MilBridge/P1-w4b-repair2-report.md
build/MilBridge/tools/handoff-machine-values-check.sh      ⇒ 4 件**全为 .md/.sh**，零构建产物
$ ls ~/w21-verify/w*-POST.done | wc -l  ⇒ 25（**无 w81**）
```
⇒ `provider`／`win32shim` 的 `sha16`＋`mtime` 仍为 `t48` 之前的旧值 ⇒ 本波窗口内**零构建、零整趟门禁**。

### ⑧ 未越域 —— **成立**
```
# ts=2026-09-28T18:27:18.853+0800
UNCHANGED  pre=26841d6ed6fe8085 now=26841d6ed6fe8085   docs/ROUTES.md
CHANGED    pre=6a1ca425a94c4fae now=58acad853a8dd7d5   samples/WpfFeatureProbe/KNOWN-DEFECTS.md   ⇒ 归 t53（`05148bb`），非 t57
CHANGED    pre=3e6865661c0c4a8e now=850c185b2cf04aa9   build/MilBridge/tools/defect-registry-declared.tsv ⇒ 归 W5（`df5b6d1`）＋t53，非 t57
UNCHANGED  pre=7887de15d07b1f0d now=7887de15d07b1f0d   build/MilBridge/tools/sentinel-spec-check.sh
UNCHANGED  pre=05dbf89b6c5e776e now=05dbf89b6c5e776e   build/MilBridge/tools/timestamp-order-check.sh
UNCHANGED  pre=bb7440867a646b32 now=bb7440867a646b32   build/MilBridge/tools/wave-push.sh
UNCHANGED  pre=742175bffd5a175d now=742175bffd5a175d   verify-all.sh
UNCHANGED  pre=69c39feabe148c62 now=69c39feabe148c62   build/close-wave.sh
$ cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag ⇒ IDENTICAL(rc=0)；两枚各 6cb3f97388c3c4dc（**未写**）
```
**归因（`git log --oneline -3 -- <件>`）**：`KNOWN-DEFECTS.md` ← `05148bb`(t53)｜`declared.tsv` ← `05148bb`(t53) ＋ `df5b6d1`(W5) ⇒ **两处都不是 `t57` 动过**（`4d04cb5` 的 numstat 只有 3 件）。`t57` 的写域**正好 3 件**，`src/**`／`build/*.Linux/**` 全窗零命中。**判词⑧：成立。**

### ⑨（队长特加①）`HANDOFF-MV` 判据面是否已"收回到被门禁覆盖的世界" —— **成立（并附 H4 观察）**
- `#8` 的现行命令 ＝ `test -s docs/WAVE81-PREREGISTRATION.md && echo in-wave-81-registered || echo no-registration`（**现取原文**）⇒ **不含 `git`**、不含 `HEAD`、不含工作树状态 ⇒ 与提交阶段、与别的车道脏件**无关**。
- `#8` 的旧命令（`git status …` 脏件计数）**在更正行里被逐字作废**：`⏪ **机器值契约更正 · cell=#8**：… **旧命令（\`git status …\` 脏件计数）自本行起作废**`。
- 「其它车道在飞」改由 `HANDOFF_MV_NOTE lane-activity=<n>` 承担，脚本第 `144–145` 行现取实现为**先算后 `echo` 一条 NOTE**，`equal`／`rc` 的计算路径里**没有**它（第 `146–155` 行的分叉只看 `uncomparable`／`mism`）⇒ **旁注不进判据** ✔。
⚠️ **H4（medium-low，观察）**：该谓词的判别力 ≈ 0 —— 它**只在 `docs/WAVE81-PREREGISTRATION.md` 被删或清空时才翻**（`test -s`）。⇒ 原锚「§2 在飞」所指的"有没有链在跑"这件事，**自此不再有任何判据**（我自造 `t8.md` 证明该格**会**红，但那只证明牙活着，不证明它测的是"在飞"）。**建议**：把这条**具名登记**为"在飞信号待立真牙"的欠账（`D-G132` 同族：不许把已知缺口静默掉），或改用我的原例（进程面／`POST.done` 面）里任一**稳定且同义**的谓词。

### ⑩（队长特加②）`QUOTE-TRAP` 与其它牙是否被牵连 —— **🔴 不成立（H1）**
```
$ bash build/MilBridge/tools/shell-quote-trap-check.sh >/tmp/o 2>/tmp/e ; echo $?      # ts=2026-09-28T18:26:28.624+0800
1
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/handoff-machine-values-check.sh line=94 col=176
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/handoff-machine-values-check.sh line=94 col=179
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/timestamp-order-check.sh line=112 col=59
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/timestamp-order-check.sh line=112 col=67
SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=4 files=202 sh=113 py=89 diag=76 allow=0
$ grep -n 'run_step "QUOTE-TRAP"' verify-all.sh   ⇒ 977:run_step "QUOTE-TRAP" bash build/MilBridge/tools/shell-quote-trap-check.sh
```
**归因（我用 `QT_ROOT` 沙箱把"唯一变量＝那颗牙"钉住）**：同一份件集（`build/MilBridge/tools/**` ＋ `verify-all.sh` 锚，`files=88 sh=73 py=15`），只换那颗牙：
```
A) 牙 = fcb5cd4 版（`t57` 之前）：SHELL_QUOTE_TRAP=FAIL reason=dq-backtick **traps=2**（两处都在 timestamp-order-check.sh:112）  rcA=1
B) 牙 = 4d04cb5 版（`t57` 之后）：SHELL_QUOTE_TRAP=FAIL reason=dq-backtick **traps=4**（多出的两处 = handoff-machine-values-check.sh:94） rcB=1
```
`ts=2026-09-28T18:26:59.754–18:27:02.689+0800`
⇒ **① `t57` 新引入 2 处 `DQ-BACKTICK`**（`fcb5cd4`／`3aaaa3e` 该件的 `grep -c 'echo ".*\`'` ＝ **0**；`4d04cb5` ＝ **1 行 2 处**）；**② 该步在 `t57` 之前就是红的**（`traps=2`，来自 `t47`/W4a 的 `timestamp-order-check.sh:112`，逐字与 `3aaaa3e` 相同）。
**机器后果（`纪律 32`：`echo` 双引号里不许出现反引号）**：新写的那句判词被**静默吃掉**了 `#7` —— 我自造 `t7.md` 跑出的原样是
`HANDOFF_MV_HIT cell=#7 … cmd=git log --oneline -1 | cut -c1-7（ 是推送面/流水线敏感量 ⇒ 不许呈机读形态）`
（`` `#7` `` 被执行成命令替换、替换为空 ⇒ 句子里**只剩一个孤零零的空格**）。`stderr` 为 **0 行**（`#` 起头的替换体被当注释 ⇒ **连报错都没有**）⇒ **静默的"消息损坏"，不是响亮的失败**（`D-G125` 同族）。
**判词⑩：不成立** —— `t57` 把一个**已接线的门禁步**从 `traps=2` 推到 `traps=4`，并让新加的判词行**丢字**。

---

## §2 `t55` 四条 finding 的闭合判定 ＋ 本轮新发现

| finding | `t57` 的处置 | 本轮判定 | 证据 |
|---|---|---|---|
| **G1**（high，`#8` 摆动假红） | 弃 `git status` 脏件计数，改「本波预登记在位谓词」；锚同趟改写；`lane-activity` 降为 NOTE | **已闭**（判据已与机器状态解耦；NOTE 不进 `equal`／`rc`） | 正极 `#8 state=equal corrected=in-wave-81-registered`；`HANDOFF_MV_NOTE lane-activity=0`；脚本 `144–155` 行的计算路径不带 NOTE；`t8.md` 证明该格会红。⚠️ 附 **H4**（判别力≈0） |
| **G2**（medium，汇总行不归因） | 报头四分 `PASS`／`DIVERGED reason=cell-mismatch`／`FOREIGN reason=cell-not-comparable`／`NOINFO`；逐格 `reason=` 机读 | **已闭** | 我 7 条夹具里三条分别得到 `DIVERGED`（`t1/t2/t5/t8/t9`）与 `FOREIGN`（`t7`／`t5git`）与 `NOINFO`（`rows8`），逐格 `reasons=` 点名。⚠️ 附 **H3**（`#4` 的 `reason=foreign-lane-activity` 却落在 `DIVERGED` 头） |
| **G3**（medium，`#7` 无牙） | `#7` 机读形态 ⇒ `rule=cell-7-not-comparable-to-HEAD`；**拒收族**正则 ⇒ `rule=cell-not-comparable-to-pipeline-state` | **已闭**（我给的"或"两条它**都**做了） | `t7.md` ⇒ `HIT cell=#7 … rule=cell-7-not-comparable-to-HEAD` ＋ `FOREIGN … uncomparable=1`；`t5git.md` ⇒ `HIT cell=#5 … rule=cell-not-comparable-to-pipeline-state` |
| **G4**（medium，自测不自主） | S1 改**自造夹具**（`make_fixture`，仓外 `mktemp -d`）；闸 S1–S4；S5 自主性证明；S6 活件如实 | **已闭**（我用**自己的**沙箱独立复现，不只读它的 S5） | 正极自测 `HANDOFF_MV_SELFTEST=PASS cases=5 pass=5 fail=0 rc=0`；我建 `HMVC_ROOT=/tmp/t58/auto`（陈旧活件副本）⇒ **`--selftest` rc=0 PASS**，而**同沙箱活件腿** `HANDOFF_MV=DIVERGED … mismatch=4`（`ts=18:27:34.110`）。⚠️ 附 **H2**（自述"闸只含 S1–S4"与实现不符） |

### 本轮新发现
| # | severity | 内容（机器证） |
|---|---|---|
| **H1** | **blocker** | 见 §1-⑩：`t57` 新引入 2 处 `DQ-BACKTICK` ⇒ **已接线**的 `[QUOTE-TRAP]` 步 `SHELL_QUOTE_TRAP=FAIL traps=4 rc=1`；新判词行**静默丢 `#7`**。**修法**：把第 `94` 行那句的**内层反引号去掉**（改 ``（`#7` 是…）`` → `（#7 是…）` 或 `（\`#7\`…）` 用单引号拼接），并按 `纪律 32` 的三种改法之一过一遍；**同趟**处理既存的那处（`timestamp-order-check.sh:112` 的 ``\`date -d\` ``）—— 否则该步**永远回不到绿**。 |
| **H2** | medium | 自述与实现不一致（`D-G136` 同族）：收尾行印 `……（闸只含 S1–S4；S5／S6 为信息腿）`，而第 `218` 行 `if [ "$s5" = PASS ] && [ "$rc" = 0 ]; then np=$((np+1)); else nf=$((nf+1)); fi` ⇒ **S5 参与闸**（`cases=5` 正是 S1–S4 ＋ S5）；S6 才真是信息腿。**修法**：把括注改成"闸含 S1–S4 ＋ S5（自主性）；S6 为信息腿"，或把 S5 也移出 `np`／`nf`。 |
| **H3** | low-medium | `#4` 的逐格判词写 `rule=route-file-changed-since-ts **reason=foreign-lane-activity**`（明确的"外部原因"），但汇总头给的是 `**DIVERGED** reason=cell-mismatch`（而非 `FOREIGN`）⇒ 同一件事在**同一条输出里**被贴了两个口径标签，与口径句⑤"差异源不在本件写域 ⇒ `FOREIGN`"的表述**对不上**。**修法**：把 `#4` 归入 `FOREIGN`（或把 `reason=` 改成 `route-file-changed-since-ts` 不带 `foreign-lane-activity` 字面）。 |
| **H4** | medium-low | 见 §1-⑨：`#8` 新谓词 `test -s docs/WAVE81-PREREGISTRATION.md` **判别力 ≈ 0**（只在文件被删/清空时翻）⇒ 原锚"§2 在飞"所指的信号**再无判据**。**修法**：具名登记欠账，或换同义的稳定谓词。 |

---

## §3 `NOINFO`（具名，既不算绿也不算红）

1. **"`QUOTE-TRAP` 步在本波之前是否曾是绿的"**：`NOINFO(reason=我只能证明"同一份件集里，牙换成 fcb5cd4 版 ⇒ traps=2 ⇒ 仍 FAIL"；要证明"W4a 那一刻现场是否已红"需重建 3aaaa3e 的整棵树，本件不跑)`。**已给的机械事实**：`timestamp-order-check.sh:112` 的该行在 `3aaaa3e`／`fcb5cd4`／现在**逐字相同**，且 QUOTE-TRAP 的判据是 `traps>0 ⇒ FAIL`（现取 `reason=dq-backtick traps=4`，`rc=1`）。
2. **"两次真实构建"真腿**：`NOINFO(reason=重活；本件不跑构建)` —— `t48`/`t57` 本就如此记（`reason=真腿归重活波`）。
3. **`#8` 谓词换成"预登记在位"是否接受**：`NOINFO(reason=这是**设计取舍**而非可判真假的事实；我给出判别力分析（H4）与两个同义替代谓词，取舍归队长/写者)`。
4. **`lane-activity` 在长跑中是否可能恒为 0 而掩盖真泄漏**：`NOINFO(reason=该值只作旁注、不进判据，我未对"旁注本身是否够用"下结论)`。

---

## §4 「推翻的话」（逐条具名）

1. **推翻"`QUOTE-TRAP` 与本次修复无关"这一隐含口径**：`t57` 的 `4d04cb5` **新引入 2 处 `DQ-BACKTICK`**（`fcb5cd4`／`3aaaa3e` 该件为 **0** 处），把已接线步从 `traps=2` 推到 `traps=4`（沙箱钉住唯一变量）。⇒ **这是 `t57` 引入的真回归**，不是既存。
2. **推翻 `t57` 那句新判词的**文本**完整性**：它写的句子里 `` `#7` `` **不会上屏**（被执行成命令替换、替换为空），原样输出是 `（ 是推送面/流水线敏感量 ⇒ 不许呈机读形态）`；且 `stderr` **0 行** ⇒ **静默损坏**（`D-G125` 同族）。一个判据的**自述句**被自己的引号吃掉，属 `纪律 32` 的教科书反例。
3. **推翻 `t57` 自述"闸只含 S1–S4"**：`np`／`nf` 在 S1–S4 **＋ S5** 上都累加（第 `218` 行）⇒ `cases=5` 的构成本身就证明 S5 在闸内（H2）。
4. **推翻"`#8` 现在测的是『在飞』"**：现取命令是 `test -s docs/WAVE81-PREREGISTRATION.md …` ⇒ 它测的是"预登记件在位"，**不测在飞**；口径句③ 已把这件事**如实改写**（锚改写可见），但**"在飞"这个信号自此无人判**（H4）。
5. **更正我自己刚写下的两句（我在本件初稿里误信了派单摘要，已当场改正）**：我原写「`t57` 报告 §6 自报 `HANDOFF-NEXT.md` 现值 **524／525 行**」与「§6 未给牙的**改后** sha16」——**两句都不成立**。现读该报告 §6 原文逐字：``牙 `e4c13eea198753ff`／198 行 ⇒ **`cde265d7eaad36d5`／`238` 行**（模式 `644` 保位）｜**`HANDOFF-NEXT.md`** `b81567e26c29a527`／516 行 ⇒ **`3044dd66c84cc903`／`526` 行**`` ⇒ **成对读数两个值都给、且与我现取逐位相同**。`524／525` 那个数字出自**派单摘要**（任务描述里的依赖段），**不是报告原文** ⇒ **该摘要陈旧**；`t57` 的报告本身**准确**。
6. **点名 `t57` 报告的一处措辞过宽（不是读数错）**：§6 写「（模式 `644` 保位）」—— 该牙**改前改后都是 `100644`**（`git ls-files -s` 现取 `100644`；`git show 4d04cb5 --summary` 无 `mode change`）⇒ 说"保位"成立，但读者可能误以为它曾被改成 `755`；建议写成「模式 `644`－`644`（无位移）」。
7. **我如实更正 `t55`／`t50` 里我自己的一处错**（见 §4-9）。

### §4-9（**我自己的教训，如实记**）
`t50` 我写过「我另跑 `shell-quote-trap-check.sh`（rc=0）… ⇒ **未牵连其它牙**」。那个 `rc=0` **是管道末段 `tail` 的 rc，不是该牙的 rc** —— 现取把它**不经管道**跑，得 `rc=1`、`SHELL_QUOTE_TRAP=FAIL traps=4`；而 `3aaaa3e` 期的同一颗牙在该件上也至少有 `traps=2` ⇒ **`#81` 波自 W4a 起就带着一个红的 `QUOTE-TRAP` 步，而我上一件把它读成了绿**。⇒ 口径句（此后我照此执行）：**「凡报脚本 rc，一律 `cmd >out 2>err; echo $?`，不许从管道末段取 `$?`」**（这是 `纪律 27`「`rc` 取自管道末段」的同一族；我在 `t55` 也犯过一次同形错 —— 但那次我取的是 `tail` 的 rc 而结论仍是"stderr 0"，未被污染）。

---

## §5 边界（如实划界）

- **只读**：`verify-all.sh`／`build/close-wave.sh`／那颗牙／`HANDOFF-NEXT.md`／两份报告／两哨兵／`ROUTES.md`／`KD`／`declared.tsv`／`src/**`／`build/*.Linux/**` **一字未改**；夹具全在 `~/w-scout-t58/**`、`/tmp/t58/**`（含 `QT_ROOT` 沙箱与 `HMVC_ROOT` 沙箱）。本件是**唯一**写入 `$N` 的件（`temp+rename`）。
- **未跑整趟门禁、未构建、未起显示位、未跑腿批、未推送、未 `git add/commit`**。
- 我**未**复核 `t57` 之外的其它面（`t53` 登记批、W5 的 `defect-registry-check.sh` 改动、`P1-dg184-verify.md` 等）；派单未要求。
- **`HEAD` 在我复核期间被推进**（`05148bb → 5756671 → 2ccbdbf`；`t57` 的修复以 `4d04cb5` 落地）—— 逐条按 §0 的档位标注。

---

`P1-W4B-REPAIR2-VERIFY 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 544044e47c918725（口径＝末行之前的全文；末行＝本行；全文 `sha16` 只在交件消息里给）`
