# P1-W4b **修复**独立复核判词（`t55`，review-round-2）—— 对 `t54`（修 `t50` 判的 `needs_revision`：F1–F5）

> **复核者**：`scout`。**一切自己现取、自己造夹具**；**不复述** `t54` 的报告与交件消息当证据。
> **本件是本次复核唯一写入 `$N` 的件**（`temp+rename`）；被复核/被判的每一件**一字未改**；夹具全落 `~/w-scout-t50/**`、`/tmp/t55/**`。
> **全文 `sha16` 只在交件消息里给**；末行只携带 `head -n -1` 自证值。**所有读数带亚秒 `ts=`**。
> **纪律**：`bash -n` **不**用作 stderr 那一条的机器证（`t50` 已证这一族 `bash -n` 结构上看不见）；凡「判据站不住」处如实 `NOINFO` ＋ 机制证明。

## §0-0 判词速览（详见各节）
| 复核项 | 判词 |
|---|---|
| ① `B-11` 牙射程（自造反极） | **不成立** —— 提交态两次 `PASS`（§1-①(a)(b)），**现取 `FAIL`**（`equal=7 manual=1 mismatch=1 rc=1`）；点名射程这半**成立**（自造 `#2`／`#9` 两腿点名格均 = 被篡改格） |
| ② 9 格真值 | **不成立** —— 6 同／1 manual（`#7`）／**2 处曾不同**（`#4` 真陈旧、`#8` 摆动假红）；`#8` 现取回 equal，`#4` 仍不同 |
| ③ `B-15` 两极 | **成立** |
| ④ `B-18` 可见性 | **成立** |
| ⑤ 四处声明 ＋ 四条不变量 | **成立**（61／61／61／233／233，`VERIFYALL_SELF=PASS names=61 decl=61 prereg=PASS`） |
| ⑥ 只增不改（提交级 numstat ＋ 备份 `cmp`） | **成立**（9 处删行逐类说明；备份 7/7 `cmp` IDENTICAL） |
| ⑦ 未跑整趟门禁 | **成立**（`provider`／`win32shim` 的 `sha16`＋`mtime` 与 `t48` 时点逐位相同；零构建产物；无 `w81-POST.done`） |
| ⑧ 未越域 | **部分成立**（`ROUTES`／`KD`／`declared.tsv`／两哨兵逐位未变；`sentinel-spec-check.sh`／`timestamp-order-check.sh` 两件本体被改 —— **是 `t50` F2／F3 的点名对象，属修复**） |
| 队长特加① `WPW` 改流（行为面） | **无回归**（消费者 0、不上屏、`rc` 未变；仅 stdout 行数 `13→14`） |
| 队长特加② 四条不变量／未越域 | **成立**／**部分成立**（见上） |
| `t50` F1–F5 | **F1（blocker）已闭（两次跨提交 `PASS`）**；F2／F3／F4／F5 **已闭**；**新发现 G1–G4 未闭**（§2 下半表） |

---

## §0 快照（`HEAD` 在本次复核期间被推进 **3** 次 —— 这是现取事实，逐段标注用哪一档）

| `ts=` | `HEAD` | 工作树 `porcelain` | 说明 |
|---|---|---|---|
| `2026-09-28T18:10:42.446+0800` | `3aaaa3e`（复核起点） | 10 行（`M`/`MM`/`??` 混合） | `t54` 的修复**尚未提交** |
| `2026-09-28T18:11:47.697+0800` | **`fcb5cd4`**（`docs(#81): t54 修复 —— HANDOFF-MV 去自证伪（#7 移出对拍集、#8 改判写域外脏件数）`，提交时刻 `18:11:21`） | 3 行（全为 `??`，都在 `build/MilBridge/` 下） | 队长所报的提交态；`ls-remote` = `fcb5cd44e2ad1d3a…` |
| `2026-09-28T18:13:14.085+0800` | **`dfd54d0`**（`docs(#81): W5 独立复核载体落仓 —— P1-w5-verify.md（t51 判 pass）`，提交时刻 `18:12:43`） | 2 行（`??`） | **另一条车道**又推进一次；`fcb5cd4` 是 `HEAD` 的祖先（`git merge-base --is-ancestor` ⇒ `YES`） |
| `2026-09-28T18:14:11.985+0800` | `dfd54d0` | **4 行**：` M build/MilBridge/tools/defect-registry-declared.tsv`／` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`?? build/MilBridge/P1-task0201-criteria.md`／`?? build/MilBridge/P1-w4b-verify.md` | **又一条车道**在 `18:13:34` 编辑了 `KD` ＋ `declared.tsv`（见 §1-①） |
| `2026-09-28T18:15:23.617+0800` | **`05148bb`**（`docs(#81): t53 登记批 —— D-G184/G185/G186/G187 四条同趟入册 + 同趟 --emit`） | **2 行**（全为 `??`） | 那条车道的编辑**已提交** ⇒ 工作树转净；**哨兵/承载件仍逐位未变** |

**四条不变量（现取，`ts=2026-09-28T18:12:55.009+0800`）**：`grep -c '^run_step "' verify-all.sh` ＝ **61**｜首行 `grep -n '^# VERIFYALL-STEPS-DECL:' verify-all.sh \| head -1` ＝ **`61 gen=#81`**｜`# VERIFYALL-STEP-NAMES:` 项数 ＝ **61**｜`bash ~/w153a/bin/infp.sh list \| wc -l` ＝ **233**｜`grep -o 'fp-manifest-step.sh --expect [0-9]*'` ＝ **233**；`basync` 机器读者 `VERIFYALL_SELF=PASS names=61 decl=61 gen=#81 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=742175bffd5a175d`。
**`t54` 未动 `verify-all.sh`／`build/close-wave.sh`**：`git show --numstat --format='' fcb5cd4 | grep -E 'verify-all.sh|close-wave.sh'` ⇒ **0 行**；`git status --porcelain verify-all.sh build/close-wave.sh` ⇒ **空**。两件现取 sha16 `742175bffd5a175d`／`69c39feabe148c62`，与 `t50` 时逐位相同。

---

## §1 逐条判词（1–8 ＝ `t50` 的同一验收清单；末尾两条＝队长本波特加）

### ① `B-11` 牙的对拍射程（自造反极）—— **🔴 不成立（F1 的 blocker 本身已闭，但该步在现取上仍是红的）**

**（a）提交态第一次实跑 —— 成立（`PASS`）**
```
$ cd /home/links-dev/netTest/GitProj/WPFOnLinux && bash build/MilBridge/tools/handoff-machine-values-check.sh
# ts=2026-09-28T18:11:52.394+0800（HEAD=fcb5cd4，raw porcelain=3）
HANDOFF_MV_CELL cell=#7 anchor=§7-6 推送面 state=manual table=本地 HEAD == ls-remote == 88ab841414b6b5e2 corrected=- live=-（该格不对拍：见牙头口径句③）
HANDOFF_MV_CELL cell=#8 anchor=§2 在飞 state=equal table=**无链在跑**（#80 已全链闭环；本件 dated 对齐 · §2 行已载） corrected=0 live=0
HANDOFF_MV=PASS cells=9 equal=8 manual=1 file=/home/links-dev/netTest/GitProj/WPFOnLinux/build/MilBridge/HANDOFF-NEXT.md
$ echo $? ⇒ 0        ;   stderr_bytes = 0
```
**（b）跨一次**后续**提交再跑 —— 仍成立（这是队长要的"提交之后仍 PASS"的**更强**形式）**
```
# ts=2026-09-28T18:13:19.700+0800（HEAD 已推进到 dfd54d0，raw porcelain=2）
HANDOFF_MV=PASS cells=9 equal=8 manual=1 file=…/HANDOFF-NEXT.md     ;  rc=0 ;  stderr_bytes=0
```
**（c）自造反极性（我的夹具）—— 成立（点名格 ＝ 被篡改格）**
副本篡改 `cell=#2` 的**最后一条**更正行现值（`233`→`230`）：
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --file ~/w-scout-t50/fix2/tamper-correction.md
# ts=2026-09-28T18:11:26.909+0800
HANDOFF_MV_HIT cell=#2 anchor=§7-4 覆盖面件数 in-repo=230 live=233 cmd=bash ~/w153a/bin/infp.sh list | wc -l
HANDOFF_MV=FAIL cells=9 equal=7 manual=1 mismatch=1      ;  rc=1
```
副本篡改 `cell=#9`（`f951e80b55e85782`→`…80`）：
```
# ts=2026-09-28T18:13:02.004+0800
HANDOFF_MV_HIT cell=#9 anchor=§1 九位 in-repo=f951e80b55e85780 live=f951e80b55e85782 cmd=sed -n '104,115p' … | sha256sum | cut -c1-16
HANDOFF_MV=FAIL cells=9 equal=7 manual=1 mismatch=1
```
⇒ **两次篡改，输出点名的 `cell=` 都恰是「我改的那一格」**，且 `cell=/anchor=/in-repo=/live=/cmd=` 齐全。**`t50` 的「点名与被篡改格不保证同格」这条已不再出现。**

**（d）🔴 `#8` 的过滤器语义我端到端真跑（自造合成仓 + 真牙），并且**发现了它现在就在红****
合成仓（`/tmp/t55/synth`，真 `git` 仓 ＋ 真 `HANDOFF-NEXT.md` 副本），用**真牙**跑（`HMVC_ROOT`）：
```
CASE A（只有写域内脏件 build/ ＋ docs/）  # ts=2026-09-28T18:12:03.419+0800
  porcelain: ?? build/wavefile.txt / ?? docs/
  #8 过滤后计数 = 0
CASE B（再加一个写域**之外**的 ?? probe-outside.txt）  # ts=2026-09-28T18:12:10.517+0800
  HANDOFF_MV_HIT cell=#8 anchor=§2 在飞 in-repo=0 live=1 cmd=git status --porcelain | grep -vE '^.. (build/|docs/|verify-all\.sh)' | wc -l
  HANDOFF_MV=FAIL cells=9 equal=3 manual=1 mismatch=5      ;  rc=1
CASE C（删掉那个脏件）  # ts=2026-09-28T18:12:15.026+0800
  HANDOFF_MV_CELL cell=#8 … state=equal … corrected=0 live=0
边界用例（同一趟）：根级 `verify-all.sh` 被**排除**；`buildx-not-build.txt` 被**计入**（D_filtered=1）。清掉后回 0。
```
⇒ **过滤器语义成立：它真的会咬、也真的会放**（这是 `t54` 那个替代判据的**正向**证据）。

**（e）🔴 但 `#8` 的**排除前缀集漏了 `samples/`** —— 现取已实际触发（**本复核的核心新发现**）**
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh      # ts=2026-09-28T18:14:11.985+0800
HANDOFF_MV_HIT cell=#4 anchor=§7-3 登记册自洽 in-repo=…declared=218 route_ids=218… live=…declared=222 route_ids=222…
HANDOFF_MV_HIT cell=#8 anchor=§2 在飞 in-repo=0 live=1 cmd=git status --porcelain | grep -vE '^.. (build/|docs/|verify-all\.sh)' | wc -l
HANDOFF_MV=FAIL cells=9 equal=6 manual=1 mismatch=2 file=…/HANDOFF-NEXT.md      ;  rc=1
```
机制（机器证）：`2026-09-28T18:13:34` **另一条车道**写了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`mtime 18:13:34.743322461`，`git diff --stat` ＝ `48 ++++++++++++++++++++++`）与 `build/MilBridge/tools/defect-registry-declared.tsv`（`mtime 18:13:34.951320315`，`DECL-GEN` 由 `18:01:35` 刷成 `18:13:34`）；其中 ` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md` **落在 `build/`／`docs/`／根 `verify-all.sh` 三个前缀之外** ⇒ 被 `#8` 计入 ⇒ 该格 `0 → 1`。
⇒ 这一格**不是**本波自己的提交把它打红的（`t50` 的 F1 blocker 已闭，见 §2-F1），而是**任何别的车道动 `samples/**`（缺陷册住在这里）、`src/**`、或仓根非 `verify-all.sh` 的件**都会把它打红 —— 而 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 正是本仓**每个登记批**都要改的 route 件。**该红在 `t54` 提交后 2 分 13 秒内就发生了**。

**（e′）🔴 同一格在 3 分钟内**来回跳**（这是我判 G1 的关键证据：它不是"一次性假红"，是**摆动**）**
```
ts=18:11:52.394  HEAD=fcb5cd4   树净（3 ??，全在 build/）  ⇒ #8 live=0  ⇒ 该格 equal
ts=18:12:55.206  HEAD=dfd54d0   树净                        ⇒ #8 live=0  ⇒ equal
ts=18:13:34      另一条车道改 samples/WpfFeatureProbe/KNOWN-DEFECTS.md（mtime .743322461）
ts=18:14:11.985  HEAD=dfd54d0   树脏（ M samples/…）        ⇒ #8 live=1  ⇒ HIT ⇒ HANDOFF_MV=FAIL …mismatch=2
ts=18:15:23.617  该笔编辑被提交为 05148bb ⇒ 树又净（2 ??）  ⇒ #8 live=0  ⇒ equal  ⇒ HANDOFF_MV=FAIL …mismatch=1（**只剩 #4**）
ts=18:15:29.501  复核收尾现取：HANDOFF_MV=FAIL cells=9 equal=7 manual=1 mismatch=1；#8 = state=equal corrected=0 live=0
```
⇒ **`#8` 的绿/红完全由"别的车道此刻有没有脏 `samples/`"决定** ⇒ 该格的绿**不是被复核波的性质**。

**判词①**：**不成立**（`t50` 要求「须印 `HANDOFF_MV=PASS cells=9`」—— 我在提交态两次印出 `PASS`（§1-①(a)(b)），但**现取**印 `FAIL`：`18:14:11.985` ⇒ `cells=9 equal=6 manual=1 mismatch=2 rc=1`；`18:15:29.501` ⇒ `cells=9 equal=7 manual=1 mismatch=1 rc=1`）。**具名新发现 G1**：`#8` 的排除前缀集不完备（漏 `samples/`）⇒ **经实测的摆动假红**（§1-①(e′)：3 分钟内 `equal → HIT → equal`），且**报头是 `HANDOFF_MV=FAIL`**（读起来像"HANDOFF 的机器值错了"，而 `#4`／`#8` 都不是被复核波的错）＝ `D-G125` 同族（件与表都对、错的只是消息）。

### ② 9 格的真值（我自跑生成）—— **不成立（6 同／1 manual／2 不同）**

我自写抽取器（扫每格**最后一条** `机器值契约更正 · cell=#N`，取 `现值 ＝ \`X\`` 与 `命令：\`Y\``，再在 `$R` 里 `bash -c Y` 取 stdout 首行）。**`ts=2026-09-28T18:14:35.989+0800`**

| # | 判 | 件内（in-repo） | 我现取（live） | 命令 |
|---|---|---|---|---|
| `#1` | **同** | `3e36f04024128302229050763f436f41f611bd745a26892cad13f467bdcc28f3` | 同值 | `bash ~/w153a/bin/infp.sh fp` |
| `#2` | **同** | `233` | `233` | `bash ~/w153a/bin/infp.sh list \| wc -l` |
| `#3` | **同** | `> BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 同值 | `sed -n '9p' docs/CURRENT-STATE.md` |
| `#4` | **🔴 不同** | `…declared=218 route_ids=218…` | `…declared=222 route_ids=222…` | `bash build/MilBridge/tools/defect-registry-check.sh \| tail -1` |
| `#5` | **同** | `61` | `61` | `grep -c '^run_step "' verify-all.sh` |
| `#6` | **同** | `w*-POST.done=25／*record*=49` | 同值 | `printf 'w*-POST.done=%s／*record*=%s' "$(ls -1 ~/w21-verify/w*-POST.done \| wc -l)" "$(ls -1 ~/w21-verify/*record* \| wc -l)"` |
| `#7` | **manual** | `<非机读>`（口径句③：明确不对拍 `HEAD`） | — | — |
| `#8` | **🔴 不同（摆动）** | `0` | `1`（`18:14:11` 现取）／**`0`（`18:15:29` 现取，另一条车道提交后）** | `git status --porcelain \| grep -vE '^.. (build/\|docs/\|verify-all\.sh)' \| wc -l` |
| `#9` | **同** | `f951e80b55e85782` | 同值 | `sed -n '104,115p' build/MilBridge/tools/wave-freeze-consistency-check.py \| sha256sum \| cut -c1-16` |

**两处不同的归因（都**不是** `t54` 的写域）**：`#4` ＝ `18:13:34` 另一条车道改了 `KD` ＋ 重发 `declared.tsv`（`DECL-GEN` 与 `KNOW-DEFECTS` 的 mtime 见 §1-①(e)）⇒ **真陈旧**（值确实动了，牙判红是**正确**行为）；`#8` ＝ 同一笔编辑的 ` M samples/…` 落在排除前缀之外 ⇒ **假红**（见 G1）。
**「3 个陈旧格已转『以现取为准 ＋ `ts=`』形态且带亚秒戳」**：现取 `grep -c '机器值契约更正' HANDOFF-NEXT.md` ＝ **38**、`grep -c 'ts='` ＝ **63**，**9/9 格**都有更正行且每条都带 `ts=2026-09-28T17:4x–18:0x+0800` 亚秒戳 ⇒ **该形态要求成立且超额**。

**判词②**：**不成立**（2/9 与现取不符），但**其中只有 `#8` 属 G1（新判据的缺陷）**；`#4` 属「值镜牙」的**设计固有**维护耦合（见 §5）。

### ③ `B-15` 两极 —— **成立**（我自造夹具重跑，`ts=2026-09-28T18:12:50.135+0800`）
```
-- empty   : PUSHMARKER_HIT file=…/empty/m.done field=push_rc rule=empty-value   ; PUSHMARKER_DIR … markers=1 bad=1 ; RC=1
-- missing : PUSHMARKER_HIT file=…/missing/m.done field=stop_line rule=missing-field ; … bad=1 ; RC=1
-- none    : PUSHMARKER_DIR dir=…/none markers=1 bad=0                            ; RC=0
-- 集成腿  : PUSHMARKER_ANTIPOLE empty-value=red-named missing-field=red-named
             PUSHMARKER=PASS mode=integration fields=3 antipole-empty-value=red antipole-missing-field=red writer=…/push-marker-write.sh ; RC=0
-- 覆盖面（逐行核对该路径，同一命令串）：coverage_n=233
             grep -cx build/MilBridge/tools/push-marker-write.sh /tmp/t55-paths.txt ⇒ 1
             grep -cx build/MilBridge/tools/push-marker-check.sh  /tmp/t55-paths.txt ⇒ 1
             grep -cx build/MilBridge/tools/handoff-machine-values-check.sh ⇒ 1 ／ provider-repro-check.sh ⇒ 1
```
⇒ 空值红并点名／缺行红并点名／`none()` 放行不判红／写入端在覆盖面内 —— **全成立**（与 `t50` 同结论，本轮自跑复现）。

### ④ `B-18` 免钉定则可见性 —— **成立**（我自造两态夹具，`ts=2026-09-28T18:12:50.305+0800`）
```
-- YES  : PROVIDER_REPRODUCIBLE=yes a=x/p.dll b=y/p.dll sha16=cb1ad2119d8fafb6   ; RC=0
-- NO   : PROVIDER_REPRODUCIBLE=no a=x/p.dll a_sha16=cb1ad2119d8fafb6 b=y/p.dll b_sha16=dcdb704109a45478（两值逐位不同 ⇒ **上屏、不判红**…） ; RC=0
-- ABSENT: PROVIDER_REPRODUCIBLE=NOINFO reason=artifact-absent path=z/p.dll      ; RC=3
-- 生产档: PROVIDER_REPRODUCIBLE=no a=build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll a_sha16=24e4e0a731dbed40
                            b=build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll b_sha16=7e8a217b4165a6b9 ; RC=0
```
⇒ `no` 时两值点名上屏、不判红、不静默；`yes` 印 `yes`；缺席 `NOINFO`。**真腿（两次真实构建）如实记 `NOINFO(reason=真腿归重活波)`**（牙件头第 11 行 ＋ 交件报告 `NOINFO` ① 逐字），**未被当成已测证据**。**判词④：成立。**

### ⑤ 四处声明逐字一致 ＋ 四条不变量 —— **成立**
`ts=2026-09-28T18:12:55.009+0800`：`run_step`=**61**｜首行 `DECL`=**61 gen=#81**｜`STEP-NAMES`=**61**｜覆盖面=**233**｜`[42] --expect`=**233**｜`VERIFYALL_SELF=PASS names=61 decl=61 gen=#81 … prereg=PASS`。⇒ **`t54` 的修复把件数/步数/覆盖面全保持住了（零位移）**。
⚠️ **具名点名（不判红）**：预登记 `docs/WAVE81-PREREGISTRATION.md` 的 §1 **原文行**仍写 `= 58 步`／`覆盖面 226 → 229`（`t47` 时点），dated 追加行写 `58 → 61`；按"只增不改 ＋ dated 取代"不判红，但读者只读 §1 会得到 `58`。

### ⑥ 只增不改（提交级 numstat ＋ 备份 `cmp`）—— **成立（有 9 处删行，逐类说明必要性）**
```
$ git show --numstat --format='%H %ci %s' fcb5cd4          # ts=2026-09-28T18:11:52.394+0800
fcb5cd44e2ad1d3ade914ec740b59222b0e766d4  2026-09-28 18:11:21 +0800  docs(#81): t54 修复 —— …
9       0       build/MilBridge/HANDOFF-NEXT.md
43      0       build/MilBridge/P1-w4b-repair-report.md
2       1       build/MilBridge/P1-w4b-report.md
27      9       build/MilBridge/tools/handoff-machine-values-check.sh
1       1       build/MilBridge/tools/sentinel-spec-check.sh
1       1       build/MilBridge/tools/timestamp-order-check.sh
2       2       build/MilBridge/tools/wave-push.sh
```
**9 处删行逐类说明**（原文照抄 ＋ 必要性）：
1. **三件牙各 `1/1`**（`sentinel-spec-check.sh`／`timestamp-order-check.sh`／`wave-push.sh`）：`-⏪ **dated 更正（\`t48\`／W4b…）**：…` ⇒ `+# ⏪ **dated 更正…**：…`。**必要性：充分**（F2 的修法本身就是"给同一行补 `#`"；**原句文本一字未改，只在行首加 `#`**）。
2. **`wave-push.sh` 第 2 处删行**：`-    echo "WPW=DRYRUN lines=13 keys=13" >&2 ;;` ⇒ `+    echo "WPW=DRYRUN lines=13 keys=13" ;;   # ⏪ \`t54\`：设计上屏行由 stderr 改 stdout…`。**必要性：由 F2 的"stderr 须归零"直接推出**（见 §3 的行为面独立复核）。
3. **`handoff-machine-values-check.sh` `27/9`**：9 处删行是 `corr_of()` 取末条、`split_row` 还原转义竖线、新增 `table=`／`corrected=` 双值上屏、`manual` 分流、`selftest` 的 S2 按格断言 ＋ 新 S4 腿 —— 逐处都对应 `t50` 的 F1／F4／F5，**属功能改写，不是丢信息**（旧行内容在 `git show 3aaaa3e:` 可取回）。
4. **`P1-w4b-report.md` `2/1`**：把 §9 更正行**插在自证行之前**（自证行本身被重写为末行）⇒ 1 删行是"重写末行"，**F5 要求的正是这个形态**。
5. **`HANDOFF-NEXT.md` `9/0`／`P1-w4b-repair-report.md` `43/0`**：纯追加。
**备份 `cmp`（`t54` 的写前备份在 `/home/links-dev/w281-scribe/bak/`，我逐件与 `git` 改前原件对拍）**：`verify-all.sh.pre-t48`／`close-wave.sh.pre-t48`／`HANDOFF-NEXT.md.pre-t48`／`WAVE81-PREREGISTRATION.md.pre-t48`／`sentinel-spec-check.sh.pre-t48`／`timestamp-order-check.sh.pre-t48`／`wave-push.sh.pre-t48` —— `cmp` 与 `git show 1d136ca:<件>` **7/7 IDENTICAL**（`ts=2026-09-28T17:57:21.355+0800`，`t50` 已现算；本轮改用 `df5b6d1:` 对 `sentinel/timestamp/wave-push` 复核同值）。**判词⑥：成立。**

### ⑦ 未跑整趟门禁 —— **成立**
```
$ stat -c '%y  %s  %n' …            # ts=2026-09-28T18:13:01.943+0800
2026-09-28 13:11:49.073048849 +0800  104448  build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll   (24e4e0a731dbed40)
2026-09-28 10:30:08.405917592 +0800  336984  src/WpfGfx.Linux.Native/bin/libwpfwin32.so                                        (6825dd7071387a46)
2026-09-28 10:28:06.518135058 +0800 3601408  build/PresentationCore.Linux/bin/Release/PresentationCore.dll                     (5b6cfda3e12b84fc)
$ find build src -newermt '2026-09-28 18:04' -type f | sort      ⇒ 8 件，**全部 .md/.sh**（HANDOFF-NEXT／P1-w4b-repair-report／P1-w4b-report／P1-w5-verify／四件牙）
$ ls ~/w21-verify/w*-POST.done | wc -l ⇒ 25（**无 w81**）；ls -t ~/w21-verify | head ⇒ 最新 w27-freeze.py 15:54:56（**早于 t54 开工**）
```
⇒ `provider`／`win32shim` 的 `sha16`＋`mtime` 与 `t48` 时点**逐位相同**，本波窗口内**零构建**、**零整趟门禁痕迹**。**判词⑦：成立。**

### ⑧ 未越域 —— **部分成立**（逐件读数）
```
$ 对每件取 git show <rev>:<件> | sha256sum -c1-16 与现读        # ts=2026-09-28T18:12:55.206+0800
3aaaa3e=26841d6ed6fe8085  df5b6d1=26841d6ed6fe8085  now=26841d6ed6fe8085   docs/ROUTES.md               ⇒ 未变
3aaaa3e=6a1ca425a94c4fae  df5b6d1=6a1ca425a94c4fae  now=6a1ca425a94c4fae   samples/…/KNOWN-DEFECTS.md   ⇒ 未变（至 18:12:55；**18:13:34 被另一条车道改**，见 §1-①(e)）
3aaaa3e=caac65d50ca90c3b  df5b6d1=3e6865661c0c4a8e  now=3e6865661c0c4a8e   defect-registry-declared.tsv ⇒ **由 W5（df5b6d1）改**，非 t54
3aaaa3e=063cfab87fc40876  df5b6d1=063cfab87fc40876  now=7887de15d07b1f0d   sentinel-spec-check.sh       ⇒ **由 t54 改**（F2 点名件）
3aaaa3e=5c0320c779e71fc8  df5b6d1=5c0320c779e71fc8  now=05dbf89b6c5e776e   timestamp-order-check.sh     ⇒ **由 t54 改**（F2 点名件）
$ cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag ⇒ IDENTICAL(rc=0)；两枚各 6cb3f97388c3c4dc／279 B／mtime 13:48:27.398116209 ⇒ **未写**
$ src/** 与 build/*.Linux/**：`git status --porcelain` 全窗零命中；`find src build -newermt 18:04` 只出 4 件牙（`build/MilBridge/tools/*`）⇒ **未动**
```
⇒ `ROUTES.md`／`KD`（至被他人改之前）／`declared.tsv`（t54 未动）／两哨兵 **逐位未变**；`src/**`／`build/*.Linux/**` **未动**；**`sentinel-spec-check.sh`／`timestamp-order-check.sh` 两件本体被 `t54` 改** —— 但**这两件正是 `t50` 的 F2／F3 点名对象**，且在 `t54` 的声明写域内 ⇒ **属修复、不算越域**（`t50` 曾把这两件当"未越域对照件"，那是 `t50` 的清单口径问题，本轮已按修复范围重述）。**判词⑧：部分成立**（我把它判成"**修复范围内的本体改动，已声明的**"；不判红，但**逐件点名**）。

### ⑨（队长特加①）队长要求的三件"行为面"核查（`wave-push.sh` 的 stdout/stderr 改流）
- **① 仓内消费者**：`grep -rn 'WPW' verify-all.sh build/close-wave.sh build/MilBridge/tools/ 2>/dev/null | grep -v 'tools/wave-push.sh'` ⇒ **命中 0**（`ts=2026-09-28T18:12:22.503+0800`）⇒ **无仓内读者**，`t54` 的"仓内消费者 0"**成立**。
- **② `run_step` 下的判词行可见性**：`run_step` 现取实现为 `"$@" > "$log" 2>&1`（**stdout/stderr 合并进同一日志**）⇒ 对 `run_step` 而言本次改流**是 no-op**；再加显示抽取正则 `grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO|NA|SKIP|REPORT)( |$)|^[A-Z][A-Z0-9_]*_(SUMMARY|COUNTS|SCOPE) '`，对**新** stdout 跑一遍 ⇒ **匹配 0 行**（`WPW=DRYRUN` 的取值 `DRYRUN` 不在词表内）⇒ 该行**改流前后都不会上屏**，也**不会**取代本步的判词（该步的判词是 `rc`）。⇒ **未新引入"判词行被吞"风险**。
- **③ 改流前后的 rc 与内容成对（我用 `git show 3aaaa3e:` 取回旧件，并在**同一 `$R` 语义**下真跑）**：旧件放不进 `$N`（不许改仓件），故我搭了一个**符号链接农场** `/tmp/t55/o1`（其 `build/<各子目录>`／`docs`／`src`／`samples` 全指向 `$N` 的对应物，使 `SELF_DIR/../../..` 解析到等价 `$R`）：
```
旧件 sha16 c2cff1b3d4e4ebcd：rc=0   stdout_lines=13  stderr_lines=8（7 行是 t48 那条注释外行的 `未找到命令/语法错误`，第 8 行 = `WPW=DRYRUN lines=13 keys=13`）
新件 sha16 bb7440867a646b32：rc=0   stdout_lines=14  stderr_lines=0
⇒ **rc 未变**（该步通过/失败语义一字未改）；唯一差异 = `WPW=` 行由 stderr 移到 stdout；`2>&1` 合并后的**行内容集合一致**（`SHA=`／`FP=` 两行之差是我农场缺 `.artifacts` 符号链接所致，与本次改流无关，如实记）
```
⇒ **判**：把 `WPW=` 由 stderr 改 stdout 属**行为面改动**，但**方向上减少**了一种捕获隐患（旧形态下"只捕 stdout"的调用者会**丢**该行），且**无仓内消费者**、**不改 `rc`**、**不上屏**⇒ **无回归**。

### ⑩（队长特加②）四条不变量 ＋ 未越域 —— 见 §0 与 §1-⑧（全给读数，不重复）

### ⑪（新发现 **G4**）`--selftest` 的 S1 正腿**不自主**（拿活件当正极夹具）⇒ 自测现在就是红的
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --selftest      # ts=2026-09-28T18:16:18.330+0800（rc=1）
HANDOFF_MV_SELFTEST_CASE case=S1 kind=positive rc=1 verdict=FAIL 原样=HANDOFF_MV=FAIL cells=9 equal=7 manual=1 mismatch=1 file=…/HANDOFF-NEXT.md
HANDOFF_MV_SELFTEST_CASE case=S2 kind=negative rc=1 verdict=HIT-named-this-cell target=cell=#9 mismatch=2 expect=HIT-that-cell/rc1/mismatch>=1
HANDOFF_MV_SELFTEST_CASE case=S4 kind=revert overall_rc=1（仅信息） verdict=EQUAL-restored target=cell=#9
HANDOFF_MV_SELFTEST_CASE case=S3 kind=noinfo rc=2 verdict=NOINFO 原样=…table-rows!=9 got=8…
HANDOFF_MV_SELFTEST=FAIL cases=4 pass=3 fail=1
# ts=2026-09-28T18:16:37.328+0800 复跑同值（`pass=3 fail=1`）
```
机制（现取原文）：S1 的正极夹具**就是生产件本身**（`out="$(bash "$SELF" --file "$src" 2>&1)"`，`src="$ROOT/build/MilBridge/HANDOFF-NEXT.md"`）⇒ **活件一旦陈旧，自测的"正极"跟着红**。⇒ `t54` 自报的 `HANDOFF_MV_SELFTEST=PASS cases=4 pass=4 fail=0` 我在 `18:10:56.020`／`18:13:19.700` **两次复现过**，但**在现取上不可复现**。**「自测」不是一台稳定的回归闸**：它的绿同时要求"牙没坏" ∧ "世界此刻没动"。⚠️ 这一条**与 `t50` 的 F4 不冲突**：F4 要的"按格精确断言"确实已闭（S2 现取仍 `target=cell=#9` 且点名 `cell=#9`）。

---

## §2 `t50` 五条 finding 的闭合判定（逐条）

| finding | 内容 | 本轮判定 | 证据 |
|---|---|---|---|
| **F1**（blocker） | `HANDOFF-MV` 因 `#7`／`#8` 对拍瞬时状态而在**本波提交后**恒红 | **blocker 本身：已闭**（提交态 ＋ 跨一次后续提交两次 `PASS`）；**但替代判据 `#8` 引入新假红通道 G1（未闭）** | §1-①(a)(b) `PASS cells=9 equal=8 manual=1 rc=0`；§1-①(e) 现取 `FAIL mismatch=2` |
| **F2**（high） | 三件牙件头更正行不在注释块内 ⇒ 运行期 stderr 污染（含语法错误）＋ `100755` 丢失 | **已闭** | stderr 成对：`sentinel 7→0`／`timestamp 7→0`／`wave-push 8→0`（`ts=18:12:15.416`）；三行现取首字符都是 `#`（§1-⑥ 删行 1） |
| **F3**（high） | `100755` 恢复 | **已闭** | `git ls-files -s` 三件 = `100755`，工作树 `755`；`git show fcb5cd4 --summary` ⇒ `mode change 100644 => 100755` ×3（**方向＝恢复**）；其余 6 件 `index==worktree` 无新位移（`ts=18:12:28.689`） |
| **F4**（medium） | `selftest` S2 用 `grep -m1` 取首条 HIT ⇒ 点名与篡改格不同格 | **已闭**（就 F4 本身而言） | `HANDOFF_MV_SELFTEST=PASS cases=4 pass=4 fail=0`（`ts=18:10:56.020`／`18:13:19.700` 两次）；S2 原样 `HANDOFF_MV_HIT cell=#9 … target=cell=#9 mismatch=1`；我另自造 `#2`／`#9` 两腿，点名格均 = 被篡改格。⚠️ 但**自测整体现取是红的**（`pass=3 fail=1`，S1 不自主）⇒ 见 **G4**／§1-⑪ |
| **F5**（low） | `P1-w4b-report.md` §9 路径笔误 `data/…` | **已闭**（按我要求的"dated 追加 ＋ 原句保留"形态） | 该件 `:9` 原句保留（`data/MilBridge/tools/sentinel-spec-check.sh`）、`:21` 为更正行逐字给出 `正确路径 ＝ build/MilBridge/tools/sentinel-spec-check.sh`（现取 `test -f` ✓）；现取 `grep -c 'data/MilBridge'` ＝ 2（＝原句 1 ＋ 更正行引文 1），**可解释** |

### `t50` 五条之外的**本轮新发现**（`t54` 未违反其派单，但判据面仍有洞）
| # | severity | 内容 | 本轮实测 |
|---|---|---|---|
| **G1** | **high** | `cell=#8` 的排除前缀只有 `build/`／`docs/`／根 `verify-all.sh`，**漏 `samples/`（缺陷册 `KD` 的住所）、`src/`、`README.md` 等**；而它的锚句是 `§2 在飞`。⇒ 该格是**全机其它车道脏件的函数**，且它是**已接线的门禁步**（`run_step "HANDOFF-MV"`） | `18:13:34` 另一条车道改 `samples/…/KNOWN-DEFECTS.md` ⇒ 该格 `0→1` ⇒ `HANDOFF_MV=FAIL`；`18:15:23` 该笔提交 ⇒ 回 `0`。**3 分 25 秒内摆动 3 次**（§1-①(e′)、§1-①(g)） |
| **G2** | medium | 报头 `HANDOFF_MV=FAIL` **不区分** "handoff 的机器值过时" 与 "别的车道在飞" ⇒ 误归因（`D-G125` 同族）；现取唯一失配格 `#4` 与手工编辑该件的波**毫无关系** | `18:15:29.501` ⇒ `FAIL cells=9 equal=7 manual=1 mismatch=1`，唯一 HIT ＝ `#4`（218 vs 222） |
| **G3** | medium | `cell=#7` 的"移出对拍集"靠 `非机读` 字样这条**约定**、**没有牙** | 我把它改回机读形态 ⇒ 立刻 `HANDOFF_MV_HIT cell=#7 … live=dfd54d0` ⇒ `FAIL`（§1-①(f)） |
| **G4** | medium | `--selftest` 的 **S1 正腿拿活件当夹具** ⇒ 自测不自主、随活件陈旧而红 | `18:16:18.330` ⇒ `HANDOFF_MV_SELFTEST=FAIL cases=4 pass=3 fail=1`（S1 `verdict=FAIL`；S2/S3/S4 全按设计） |

---

## §3 `NOINFO`（具名，既不算绿也不算红）

1. **`#8` 的"长期绿"能否成立**：`NOINFO(reason=该格的取值是**全机脏件**的函数，不是被复核波的属性；我无法在不冻结其它车道写活动的前提下判定"它在稳态下是否会绿")`。**已给的机械事实**：`t54` 提交后 **2 分 13 秒**（`18:11:21 → 18:13:34`）该格即因**另一条车道**改 `samples/…/KNOWN-DEFECTS.md` 由 `0` 变 `1`。
2. **`#4` 的"值镜牙"维护成本**：`NOINFO(reason=每个「登记批」都会改 KD ⇒ `declared=` 计数必移；我无法预测下一批何时落地，只能报现取 218→222)`。附机器证：`KD` mtime `18:13:34.743322461`、`declared.tsv` `DECL-GEN 18:01:35 → 18:13:34`。
3. **"两次真实构建"真腿**：`NOINFO(reason=重活；本件不跑构建)` —— 且 `t54`／牙件头**本就如此记**（`reason=真腿归重活波`），不因此变色。
4. **`#7` 若日后被改回机读形态**：`NOINFO(reason=那是未来编辑，非现取事实；但我**已用夹具实测**该情形下的行为 —— 见 §1-①(f))`。

### §1-①(f) 补充：`#7` 的修复是**约定**、不是**牙**（我自造夹具实测）
把副本里 `#7` 的最后一条更正行**改回机读形态**（`现值 ＝ \`1d136ca\`（命令：\`git log --oneline -1 | cut -c1-7\`）`）：
```
$ bash build/MilBridge/tools/handoff-machine-values-check.sh --file ~/w-scout-t50/fix2/t7-valueform.md      # ts=2026-09-28T18:13:02.004+0800
HANDOFF_MV_HIT cell=#7 anchor=§7-6 推送面 in-repo=1d136ca live=dfd54d0 cmd=git log --oneline -1 | cut -c1-7
HANDOFF_MV=FAIL cells=9 equal=8 manual=0 mismatch=1
```
⇒ **`#7` 的"移出对拍集"靠的是更正行里的 `非机读` 字样这一条**约定**；任何人日后写回机读形态，`t50` 的 F1 时间炸弹立刻复燃（且**不会有任何东西拦他**）。**建议**：给该格加一条真牙（`cell=#7` 若是机读形态 ⇒ `FAIL reason=cell-7-not-comparable-to-HEAD`），或把"对拍 `HEAD`"这类命令族整体列入拒绝清单。

---

## §4 「推翻的话」（逐条具名）

1. **推翻队长派单里"提交态须印 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 rc=0`"的可复现性（时序限定）**：该读数在 `HEAD=fcb5cd4`（`18:11:52`）与 `HEAD=dfd54d0`（`18:13:19`）**都成立**，但在**现取**（`18:14:11`）**不成立** —— `HANDOFF_MV=FAIL cells=9 equal=6 manual=1 mismatch=2 rc=1`。⇒ **"PASS"不是该件的稳定属性，而是"全机此刻干净"的函数**。
2. **推翻 `t54` 关于 `cell=#8`「**与提交阶段无关**（提交前后同值）」这句话的**外延****：对**本波自己的提交**它成立（我两次跨提交复算 `live=0`）；对**别的车道的提交/编辑**它**不成立** —— 其排除前缀只有 `build/`／`docs/`／根 `verify-all.sh`，**漏 `samples/`（缺陷册 `KD` 的住所）、`src/`、`README.md` 等**。已实测：`samples/…/KNOWN-DEFECTS.md` 一脏，该格即 `0→1`（§1-①(e)）。
3. **推翻 `t50` 自己那条清单口径**：`t50` 把 `sentinel-spec-check.sh`／`timestamp-order-check.sh` 列为"未越域**对照件**"；本轮按修复范围重述 —— 它们**是 `t50` 的 F2／F3 点名对象**，`t54` 改它们是**在完成修复**，不是越域。**如实更正我自己上一件的口径。**
4. **点名 `t54` 报告 §1 引的"修前 `FAIL cells=9 equal=5 manual=0 mismatch=4`（命中 `#1`／`#4`／`#7`／`#8`）"——我独立复现，逐项吻合**（不是推翻，是加固）：我用 `git show 3aaaa3e:` 取回**修前牙**＋**修前 HANDOFF**，`HMVC_ROOT=$N` 真跑 ⇒ `HANDOFF_MV=FAIL cells=9 equal=5 manual=0 mismatch=4`，命中恰为 `#1`／`#4`／`#7`／`#8`（`ts=2026-09-28T18:13:47.935+0800`；因为世界又动过，`#4` 的 `live` 现为 `222`、`#8` 的 `live` 现为 `4`，**命中集合与计数逐字相同**）。
5. **收紧 `#4` 的读法**：它不是"`t54` 没跟上的陈旧值"，而是**设计使然**（值镜牙）；但它意味着**门禁里 `HANDOFF-MV` 这一步，在任何「登记批」落地后都会红**，直到有人再追加一条 `ts=` 更正行。⇒ 建议在件头把这条**维护契约**逐字写死（"改了 route 件 ⇒ 必须同趟刷新 `#4`"），否则它会变成一条**慢性红**。
6. **推翻 `t54` §5"自测 `PASS cases=4 pass=4 fail=0`"作为**稳定**机器证的用法**：该读数我在两处复现过（`18:10:56`／`18:13:19`），但现取为 `FAIL cases=4 pass=3 fail=1`（`18:16:18`／`18:16:37`）—— 根因是 **S1 用活件当正极夹具**（§1-⑪）。⇒ **"自测绿"在该件上不构成"牙是好的"的证明**；应改成 `mktemp` 里自建 9 格夹具（正极不依赖生产件）。
7. **具名更正 `t50` 的一处（我自己的）口径**：`t50` 曾把 `#4` 的失配（当时不存在）与 `#7`／`#8` 并列为"自证伪"；本轮现取表明 `#4` 属**另一族**（值镜牙的固有维护耦合），与"本波提交"无关。**如实分开。**
8. **推翻"`WPW` 改流是格式调整"这一可能的轻描淡写**：它是**行为面改动**（stdout 行数 `13 → 14`），只是经我独立复核（§1-⑨）三项后果全为**空/无**（消费者 0、不上屏、`rc` 未变）⇒ **不判回归**，但**必须按行为改动记账**。

---

## §5 边界（如实划界）

- **只读**：被复核的每一件（含 `verify-all.sh`／`build/close-wave.sh`／三件牙／`handoff-machine-values-check.sh`／`HANDOFF-NEXT.md`／两份报告／两枚哨兵／`ROUTES.md`／`KD`／`declared.tsv`）**一字未改**；夹具全在 `~/w-scout-t50/**`、`/tmp/t55/**`（含合成 git 仓与符号链接农场）。本件是**唯一**写入 `$N` 的件（`temp+rename`）。
- **未跑整趟门禁、未构建、未起显示位、未跑腿批、未推送、未 `git add/commit`**。
- **`HEAD` 在本次复核期间被推进 3 次**（`3aaaa3e → fcb5cd4 → dfd54d0`，外加 `18:13:34` 一次**未提交**的 `KD`／`declared.tsv` 编辑）—— 全部是**现取事实**，本件按 §0 的档位分别标注。
- 我**未**复核 `t54` 之外的其它面（W5 的 `defect-registry-check.sh` 改动、`P1-w5-verify.md` 等）；派单未要求，本件不做超范围结论。

---

`P1-W4B-REPAIR-VERIFY 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 0c916934ea847dc0（口径＝末行之前的全文；末行＝本行；全文 `sha16` 只在交件消息里给）`
