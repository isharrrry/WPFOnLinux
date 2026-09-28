# P1-w1-verify —— `t10`（W1 文档口径批）**独立复核判词**（`verifier` / `t11`）

- **被核交件**：`t10`（成员 `scribe`）的 W1 文档口径批 —— `docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv` ＋ 仓外 `~/w21-verify/w27-freeze.py`（仅注释）。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜**我开工时基点** `HEAD=88ab841414b6b5e27ec257315179596ab5294633`（`15:58:21` 现取）。
- **读取时刻**：本件全部读数在 **`2026-09-28T15:58:21` – `2026-09-28T16:01:07 +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-w1-verify.md`）＝我唯一写入的件。
- **沙箱/输出目录**：`~/wv81y/`（**不落 `/tmp`**）；`$N` 只读；不跑门禁/构建/应用/显示位；不 `git add/commit/push`。
- **禁则遵守**：**不复述** `t10` 的结论 —— 每格我自己现取、每条腿我自己跑。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | `HANDOFF-NEXT` 机器值可复现性（**本波主判据**） | **部分成立**：B-11 契约表 9 格里 **7 格逐字复现**、1 格时间性取代、**1 格（`§1` 九位的 `provider`）不复现** ⇒ 「该节的每个机器值都能被现取复现」**不成立（具名）** |
| 2 | `B-17` `§13` 两口径**从零复算** | **成立**（`79／77／2`、唯一 id `79`、口径 β 取标签后 `74／1／2／0` **逐格相同**；口径句「取标签后那一个」在位）｜⚠️ 附 F1（两处「本轮现取」行号是**插入前坐标**） |
| 3 | `B-16` 前缀口径 | **成立**（`head -568` ⇒ `0dbc62b1d1cf86ee` **与行内值逐位相同**；整件 `720e12fceb761941`／`582` 行；口径词「前缀快照」在位 ×3；`cmp` 级等价我已自查） |
| 4 | `B-5` 冻结器（只注释变 ＋ 可编译） | **成立**（diff **只 1 hunk**：**1 注释行 → 2 注释行**；**非注释行 0 删 0 增**；`compile()` **OK**）｜⚠️ 附 F3（报告两处行号引用现取不符） |
| 5 | `B-13` 哨兵 `FP` ≠ `inputs_fp` | **成立**（三个值**各自现取**且与现文所引逐字相同） |
| 6 | 队长更正的「覆盖面洞 2 件」 | **成立**（**两把尺子**各 `226` 行且**集合 `cmp` IDENTICAL**；`pts-gap-count-check.sh` **A=1／B=1** 且原行逐字与队长给的一致；`verify-all.sh` `0／0`；`display-lease.sh` `0／0` ⇒ **洞 ＝ 2 件**；现文 `:827` 如实标注**侦察原句经队长推翻**） |
| 7 | `--emit` 逐字节对拍 ＋ `DECLDRIFT` ＋ `BOOK_ENTRY_*` | **成立**（除 `# DECL-GEN` 外 **`cmp` IDENTICAL**；`DECL-ANCHORS` 逐字相同；`DECLDRIFT=0 keys=-`；三行摘录见 §2-7） |
| 8 | `B-11` **落地形态**可判真假 | **`NOINFO`**：既**不是脚本**也**不是牙** ⇒ 无法按落地形态判真假（两件拟建牙**都不存在**，现取 `exists=NO`）｜我用「**逐格现跑它自己的生成命令**」替代并逐格比（§2-1） |

**我推翻的话：4 句**（§3）＋ 3 处行号/射程具名不对拍。

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 构件对账与基线
```bash
cd $N && git rev-parse HEAD && git status --porcelain && git diff --numstat && git diff --cached --numstat
cd $N && sha256sum docs/ROUTES.md build/MilBridge/HANDOFF-NEXT.md samples/WpfFeatureProbe/KNOWN-DEFECTS.md build/MilBridge/tools/defect-registry-declared.tsv ~/w21-verify/w27-freeze.py build/MilBridge/P1-tail-scout.md | cut -c1-16,66-
cd $N && for f in ROUTES.md HANDOFF-NEXT.md KNOWN-DEFECTS.md; do sha256sum ~/w281-scribe/bak/$f.pre-t10 | cut -c1-16; done
cd $N && sha256sum ~/w281-scribe/bak/defect-registry-declared.tsv.pre-t10 ~/w281-scribe/bak/w27-freeze.py.pre-t10 | cut -c1-16
```

### 1.2 机器值（本波主判据）
```bash
cd $N && sed -n '9p' docs/CURRENT-STATE.md
cd $N && sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16 && stat -c '%s' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
cd $N && for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do printf '%s  %s\n' "$(sha256sum "$f" | cut -c1-16)" "$(basename $f)"; done
cd $N && bash ~/w153a/bin/infp.sh fp && bash ~/w153a/bin/infp.sh list | wc -l
cd $N && grep -c '^run_step "' verify-all.sh && grep -m1 'VERIFYALL-STEPS-DECL' verify-all.sh
cd $N && ls ~/w21-verify/w*-POST.done | wc -l && ls ~/w21-verify/w6*-POST.done | wc -l && ls ~/w21-verify/w6*-record.txt | wc -l && ls ~/w21-verify/*record* | wc -l && ls ~/w21-verify/*record* | tail -1
cd $N && git log --oneline -1 && git ls-remote origin refs/heads/feat-Linux | cut -c1-16
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG'
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -3
cd $N && sed -n '104,115p' build/MilBridge/tools/wave-freeze-consistency-check.py
cd $N && sed -n '148,164p' build/MilBridge/HANDOFF-NEXT.md        # 被引原文的逐字核对
cd $N && grep -c 'D-G176' samples/WpfFeatureProbe/KNOWN-DEFECTS.md && grep -o 'D-G176' samples/WpfFeatureProbe/KNOWN-DEFECTS.md | wc -l
cd $N && grep -c 'WFREEZE_BLOCKVALUES_HIT' build/MilBridge/tools/wave-freeze-consistency-check.py && grep -n 'WFREEZE_BLOCKVALUES_HIT key=' build/MilBridge/tools/wave-freeze-consistency-check.py
cd $N && test -e build/MilBridge/tools/handoff-machine-values-check.sh; echo "exists=$?"
cd $N && test -e build/MilBridge/tools/routes-tree-count-check.sh; echo "exists=$?"
```

### 1.3 `§13` 两口径（**我自己写的抽取器** `~/wv81y/s13.py`，不复用 scout/t10 的实现）
```bash
cd ~/wv81y && python3 s13.py
# 域 = '^## §13 ' 头 :161 → 下一个 '^## §' 头 :408 之前（即 :162..:407）
# 口径 α「全行 tree-form」= 剥掉树绘制前缀后行首匹配 ^TASK-\d{4}
# 口径 β「带 [kind]」     = 行内匹配 TASK-\d{4}\s*\[[A-Za-z]+\]
```

### 1.4 `B-16` 前缀口径（`cmp` 级）
```bash
cd $N && head -568 build/MilBridge/W78A-report.md | sha256sum | cut -c1-16
cd $N && sha256sum build/MilBridge/W78A-report.md | cut -c1-16 && wc -l < build/MilBridge/W78A-report.md
cd $N && grep -n 'TASK-0303 \[Next\]' docs/ROUTES.md
head -568 $N/build/MilBridge/W78A-report.md > ~/wv81y/w78.head568
head -c $(stat -c %s ~/wv81y/w78.head568) $N/build/MilBridge/W78A-report.md > ~/wv81y/w78.prefix
cmp ~/wv81y/w78.head568 ~/wv81y/w78.prefix && echo IDENTICAL
```

### 1.5 `B-5` 冻结器（**逐行 diff 点名 ＋ 语法编译**）
```bash
diff ~/w281-scribe/bak/w27-freeze.py.pre-t10 ~/w21-verify/w27-freeze.py
python3 - <<'PY'   # difflib 逐 opcode 分类 COMMENT / CODE
import difflib
a=open('/home/links-dev/w281-scribe/bak/w27-freeze.py.pre-t10',encoding='utf-8').read().split('\n')
b=open('/home/links-dev/w21-verify/w27-freeze.py',encoding='utf-8').read().split('\n')
sm=difflib.SequenceMatcher(None,a,b,autojunk=False)
nc=nl=0
for tag,i1,i2,j1,j2 in sm.get_opcodes():
    if tag=='equal': continue
    print('op=%s old:%d-%d new:%d-%d'%(tag,i1+1,i2,j1+1,j2))
    for x in a[i1:i2]:
        t=x.strip(); nc += 0 if t.startswith('#') else 1; print('   - %s'%x.strip()[:150])
    for x in b[j1:j2]:
        t=x.strip(); nl += 0 if t.startswith('#') else 1; print('   + %s'%x.strip()[:150])
print('REMOVED non-comment =',nc,' ADDED non-comment =',nl)
PY
cd $N && python3 -c "import sys;src=open('/home/links-dev/w21-verify/w27-freeze.py').read();compile(src,'w27-freeze.py','exec');print('PY_COMPILE=OK',len(src))"
cd $N && for s in 759ac1686e5ef87d 8cb1b50619f4c133 7e8a217b4165a6b9; do printf '%-18s -> ' "$s"; grep -n "$s" build/MilBridge/P0-w80-report.md | cut -d: -f1 | tr '\n' ' '; echo; done
cd $N && grep -n "^ *#" ~/w21-verify/w27-freeze.py | grep -c '8cb1b50619f4c133'   # 注释内计数
cd $N && grep -n 'prev_provider' ~/w21-verify/w27-freeze.py
cd $N && grep -n 'prev_provider' ~/w281-scribe/bak/w27-freeze.py.pre-t10
```

### 1.6 `B-13` ＋ 覆盖面孔（**两把尺子**）
```bash
cd $N && grep '^FP=' /tmp/bridge-frozen.flag && bash build/bridge-src-fp.sh && bash ~/w153a/bin/infp.sh fp
cd $N && bash ~/w153a/bin/infp.sh list > ~/wv81y/listA.txt; wc -l < ~/wv81y/listA.txt
cd $N && bash ~/w-p0mig/bin/infp-n.sh list > ~/wv81y/listB.txt; wc -l < ~/wv81y/listB.txt
cd $N && for f in verify-all.sh build/MilBridge/tools/display-lease.sh build/MilBridge/tools/pts-gap-count-check.sh; do printf '%-46s A=%s B=%s\n' "$f" "$(grep -cF "$f" ~/wv81y/listA.txt)" "$(grep -cF "$f" ~/wv81y/listB.txt)"; done
cd $N && grep -F 'pts-gap-count-check.sh' ~/wv81y/listA.txt
cd $N && sort ~/wv81y/listA.txt > ~/wv81y/A.s; sort ~/wv81y/listB.txt > ~/wv81y/B.s; cmp ~/wv81y/A.s ~/wv81y/B.s && echo IDENTICAL
```

### 1.7 `--emit` 逐字节对拍 ＋ 三态
```bash
cd $N && bash build/MilBridge/tools/defect-registry-check.sh --emit > ~/wv81y/emitted-live.tsv
cd $N && tail -n +2 build/MilBridge/tools/defect-registry-declared.tsv > ~/wv81y/live-no1.tsv
cd $N && tail -n +2 ~/wv81y/emitted-live.tsv > ~/wv81y/emit-no1.tsv
cd $N && cmp ~/wv81y/live-no1.tsv ~/wv81y/emit-no1.tsv && echo "BYTE_IDENTICAL(tail -n +2)"
cd $N && diff ~/wv81y/live-no1.tsv ~/wv81y/emit-no1.tsv | wc -l
cd $N && sed -n '1,2p' build/MilBridge/tools/defect-registry-declared.tsv
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG_DECLDRIFT'
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -3
```

---

## §2 逐格对照表

### 2-1 `HANDOFF-NEXT` B-11 契约表**逐格**（我**跑它自己写的生成命令**，与件内「现取值」比）

| # | 处 | 件内「现取值」 | 我现跑生成命令的读数 | 判 |
|---|---|---|---|---|
| 1 | §7-4 输入指纹 | `abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f` | **同**（逐字） | ✓ |
| 2 | §7-4 覆盖面件数 | `226` | **226** | ✓ |
| 3 | §7-1 冻结世代 | `BASELINE-FROZEN gen=#80 sha16=b96d4312565a3c49 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | **同**（逐字） | ✓ |
| 4 | §7-3 登记册自洽 | `DEFREG=PASS declared=215 route_ids=215` | **同** | ✓ |
| 5 | §7-5 步数 | `55`（首行声明 `# VERIFYALL-STEPS-DECL: 55 gen=#79`） | **55** ＋ 该 `DECL` 行**逐字同** | ✓ |
| 6 | §7-5 放行标记 | `w6*-POST.done=10`／`w6*-record.txt=10`；全量 `w*-POST.done=25`／`*record*=49`，最末 `w77-record.txt` | **10／10／25／49／`w77-record.txt`** 全同 | ✓ |
| 7 | §7-6 推送面 | 本地 `HEAD` == `ls-remote` == `88ab841414b6b5e2` | `15:59:03` ⇒ 两者同 = **`e122f8d4104e032c`**；`16:01:07` ⇒ 两者同 = **`39f23d0623086e40`** | **时间性取代**（见 §2-2） |
| 8 | §2 在飞 | **无链在跑**（`#80` 已全链闭环） | `CS:9 = gen=#80` ＋ `porcelain` 仅 1 个未跟踪件（`t7` 的判据件）⇒ 与「无链在跑」一致 | ✓（定性，§5-N3） |
| 9 | §1 九位 | 指向件内 `dated 对齐` 行的 `#80` 九值 ＋ 权威路径表 `wave-freeze-consistency-check.py:104-115` | **九位现取：8/9 逐位复现**；**`provider` 不复现**：在册 `7e8a217b4165a6b9`（`#80` 块**声明值**）vs **现取 `24e4e0a731dbed40`**（权威路径 `build/DirectWrite.Linux/Provider/bin/Release/…`，`104448 B`，mtime `13:11:49`） | **✗ 1 格不复现**（具名，归因见下） |

**`provider` 那格的归因**：现取 `wave-freeze-consistency-check.py` 的 `NINE_PATHS`（`:104-115`）**确实**把 `provider` 指到工程产出目录（权威路径）⇒ 权威路径表**对**；不复现的原因是**已注册**的 `D-G176`／`HANDOFF-NEXT` 第 `18` 条「门禁是构建驱动 ⇒ 冻后跑门禁必使 `PROVIDER` 位位移」（`13:11:49` 那次重建把权威路径值从 `7e8a217b4165a6b9` 改成 `24e4e0a731dbed40`）。**但**：`t10` 自己在 `B-1` 证据③ 给的恰是**现值** `24e4e0a731dbed40` ⇒ **同一件内两处并存**（`§1` dated 行的块值与 `B-1` 的现取值）—— 于是「该节的每个机器值都能被现取复现」**不成立**（差 1 格）。
⇒ 形态建议：把 `§1` 的 `provider` 也加一条 dated 现取行（或在该格旁注「块声明值 ≠ 现取值，见第 `18` 条」），**不改数**。

### 2-2 我开工到收工之间**别人落的提交**（如实记，非 `t10` 的错）

| 时刻 | `HEAD` | 事件 |
|---|---|---|
| `15:58:21`（我开工） | `88ab841414b6b5e2` | `porcelain` **11** 行（`t10` 四件 ＋ 各复核载体未提交） |
| `15:58:54` | **`e122f8d4104e032c`** | 「P1-W1 文档口径批 + D-G179 入册 + t5 侦察件」**被提交并已推送**（`numstat` 含 `t10` 四件 ＋ 四个复核载体） |
| `16:00:58` | **`39f23d0623086e40`** | 「P1 F1/F2/F3 三条 dated 追加」（对我 `t8` 判词的关账） |

⇒ 契约表 **第 7 格**的件内值 `88ab841414b6b5e2` 在 `t10` 读时（`15:53–15:56`）是**正确的现取值**，被**随后的提交**取代 ⇒ 记「**点读数、时间性取代**」，**不判错**。**`t10` 四件内容在我全趟复核期间 sha16 一字节未变**（§2-4），故所有逐格比对成立。

### 2-3 `B-17` `§13` 两口径（**从零复算**，域＝`## §13 ` 头 `:161` → 下一个 `## §` 头 `:408` 之前，即 `:162..:407`）

| 量 | 现文报值 | 我自算 | 判 |
|---|---|---|---|
| 口径 α（全行 tree-form）行数 | `79` | **79** | ✓ |
| 口径 β（带 `[kind]` 标签）行数 | `77` | **77** | ✓ |
| 不带 `[kind]` 行数 | `2`（`TASK-0202`／`TASK-0204`） | **2**（**同两个号**） | ✓ |
| `79 = 77 + 2` | 是 | 是 | ✓ |
| tree-form 唯一 id 数 | `79` | **79** | ✓ |
| 口径 β·**取标签后那一个记号** | ✅`74`／🟡`1`／🔴`2`／⚪`0` | **✅74／🟡1／🔴2／⚪0**（和 77） | ✓ **逐格相同** |
| 口径 β·整行任一命中 | （更早的 `t66`／`t70` 行给 ✅`75`／🟡`2`／🔴`5`／⚪`0`） | **✅75／🟡2／🔴5／⚪0**（和 82） | ✓ |
| 口径 α·桶 | 现文**显式声明「只报行数、不报桶」** | 我自算：整行法 **✅77／🟡2／🔴5／⚪0**（和 84）；取标签后法 **✅74／🟡1／🔴2／⚪0**（**2 行无可取记号被跳过**） | 声明理由**成立**；α 的桶供补 |
| 「取记号规则」是否写清 | `:179` ③ 逐字「**取标签后那一个记号**」 | 与我的复算一致 | ✓ |

**额外交叉核**：我在 `t72`（另一趟、对另一笔）独立算过同区的「字面域／严格域」，现取得 **字面域（`§13` 内含 `[kind]` 者）＝ `78`**、**严格域（行首即 `[kind]`）＝ `77`**，**差集恰 `{`:167`}`**（`t66` 更正行引文）—— 与本次的 `77` 同集合，两组数互不矛盾（`78` 与 `79` 是两个**不同**的域，差在「引文行」与「2 行无标签行」）。

### 2-4 构件与基线（判据 1／6 的底账）

| 件 | 我开工现取 sha16 | `t10` 声称「改后」 | 收工再取 | 判 |
|---|---|---|---|---|
| `docs/ROUTES.md` | `f87f19e76165d76e` | `f87f19e76165d76e` | `f87f19e76165d76e` | ✓ 三趟同 |
| `build/MilBridge/HANDOFF-NEXT.md` | `80e66cae6a8db00a` | `80e66cae6a8db00a` | `80e66cae6a8db00a` | ✓ |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `a2621851cce4527f` | `a2621851cce4527f` | `a2621851cce4527f` | ✓ |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `a53190901616b80a` | `a53190901616b80a` | `a53190901616b80a` | ✓ |
| `~/w21-verify/w27-freeze.py`（仓外） | `008975d871fbf030` | `008975d871fbf030` | `008975d871fbf030` | ✓ |
| 改前基线（`~/w281-scribe/bak/*.pre-t10`，**我独立现取**） | `ROUTES 3fc6b1598fb4e043`／`HN 61c34bb9d4168f65`／`KD fa1715f3edefb7eb`／`tsv 2f9f55f41cf57622`／`freeze.py 7e3d0fecefa9f20c` | 与 `t10` 声称的五格**逐位相同** | — | ✓ |

`git diff --numstat`（开工）：`24 0 HANDOFF-NEXT.md`｜`2 2 defect-registry-declared.tsv`｜`5 0 docs/ROUTES.md`｜`19 0 KNOWN-DEFECTS.md` ⇒ **三件纯增（删 0）**；`declared.tsv` 的 `2 2` ＝ `# DECL-GEN` ＋ `KD=` 锚行。

### 2-5 `B-5` 冻结器：**只有注释变**（逐行点名）

`diff pre-t10 ↔ live` 现取 **只有 1 个 hunk**：
```
444c444,445
<  #  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33）与 `8cb1b50619f4c133` ⇒ 三个时刻都写进 `P0-w80-report.md` §六）
>  #  `Provider` 产物先后被重建为 `8cb1b50619f4c133`（02:23:33，＝哨兵现取、亦即下行 `prev_provider`）
>  #  与 `7e8a217b4165a6b9`（`#80` 块九位行声明值）⇒ 三个时刻都写进 `P0-w80-report.md` §六）
```
- **difflib 逐 opcode 分类**：该 hunk ＝ `replace`，**删 1 行（COMMENT）／增 2 行（COMMENT）**；`REMOVED non-comment lines = 0`／`ADDED non-comment lines = 0` ⇒ **逻辑零改动** ✓
- 行数 `1749 → 1750`（+1）✓｜`compile(src)` ⇒ **`PY_COMPILE=OK 119961`** ✓（**不写盘**）
- 三个 `sha16` 在 `build/MilBridge/P0-w80-report.md`（`3cc9becdc15f2211`／`104` 行）里**逐字命中**：`759ac1686e5ef87d`@**`:72`**｜`8cb1b50619f4c133`@**`:72`**｜`7e8a217b4165a6b9`@**`:68`**、`:72` ✓
- 计数（**射程**）：**注释内** 三个值各 `1` 次 ✓；**全件** `8cb1b50619f4c133` `2` 次（第 `2` 次在**代码行** `prev_provider='8cb1b50619f4c133'`，现取 `:448`，**未动**）⇒ 见 §3-④
- ⚠️ 措辞：「＝**哨兵现取**」的依据是 `P0-w80-report.md:72` 逐字「`8cb1b50619f4c133`（**哨兵值** ＝ `GENS['#80']['prev_provider']`，`02:23:33` 重建后）」；但**现盘**哨兵 `PROVIDER=24e4e0a731dbed40` ⇒ 该措辞**只在 `#79`／`#80` 纪元语境**成立（低危具名，见 §3-具名②）

### 2-6 `B-16` 前缀口径（`cmp` 级自查）

| 量 | 现文／行内值 | 我自算 | 判 |
|---|---|---|---|
| `head -568` 的快照 sha16 | `0dbc62b1d1cf86ee` | **`0dbc62b1d1cf86ee`** | ✓ 逐位相同 |
| 整件 sha16 | `720e12fceb761941` | **`720e12fceb761941`** | ✓ |
| 整件行数 | `582` | **582** | ✓ |
| `head -N` 的等价性 | —（口径词要求） | `head -568` 的输出 与 整件**字节前缀**（`head -c $(stat -c %s …)`）`cmp` ⇒ **IDENTICAL** | ✓ |
| 口径词在位 | `:180` 含「前缀快照」 | `grep -o '前缀快照'` = **3** 次，且写明「当行内值 ≠ 整件 sha16 时不得省略该口径词」 | ✓ |
| `TASK-0303` 行现取位置 | `:180` 写「本轮现取 `:240`」 | **`:242`**（pre-t10 备份现取 **`:240`**） | **✗ 插入前坐标**（§3-①） |

### 2-7 `--emit` ＋ 三态逐字摘录

```
# DECL-GEN = (--emit) 2026-09-28 15:55:05 +0800                          ← 件内现值＝我现取（t10 声称 15:55:05 ✓）
# DECL-ANCHORS = KD=a2621851cce4527f CS=13077b52c938f8af HO=a4d8ffcf4c37f6fe AB=b96d4312565a3c49 KRJ=6351a46296d17b28 KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
```
| 对拍 | 我现取 | 判 |
|---|---|---|
| `--emit` 输出 vs 现场 `declared.tsv`（`tail -n +2`，即**除 `# DECL-GEN`**） | **`cmp` `IDENTICAL`**；`diff` 行数 **0**；两侧 sha16 均 **`5ea03690cbd11758`** | ✓ **逐字节** |
| `# DECL-ANCHORS` 行 | 两侧 `:2` 行 sha16 均 **`a717b584aae30f14`** | ✓ 逐字相同 |
| 行数/注释/数据 | `224` 行／注释 `9`／**数据 `215`**（两侧同） | ✓（⚠️ 见 §3-③ 计数标签） |
| `DECLDRIFT` | `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` ＋ `DEFREG_DECLDRIFT_KEYS=-` | ✓ |
| `BOOK_ENTRY_*` 三行 | `BOOK_ENTRY_UNREQUIRED_MISSING n=15 ids=D-E1 D-F1b-ABSENT D-G D-G1 D-G156 D-G159 D-G161 D-G165 D-G33 D-G5 D-G6 D-O1 D-R2 D-R4 D-T1 （**已登记的缺口：可见、不判红**）`／`BOOK_ENTRY_BINDING required=5 present=5 missing=0`／`REPORTID=PASS files=192 ids=2034 declared=215 glob=build/MilBridge/*report*.md` | ✓ 与 `t10` 报告 §9 逐字相同 |
| `DEFREG_*` | `DEFREG_DECL=n=215 route_ids=215`／`DEFREG_ROUTES=KD=a2621851cce4527f …`／`DEFREG=PASS declared=215 route_ids=215` | ✓ |
| `REPORTID` 归因 | 开工 `191／2012` → 本件落盘后 `192／2034`；`P1-w1-report.md` 体内 `D-G[0-9]+` 命中 **22** ＝ `ids` 增量 | ✓ **逐件可归因** |

### 2-8 队长更正的「覆盖面洞 2 件」（**两把尺子**）

| 尺子 | 件 | `list` 行数 |
|---|---|---|
| A | `~/w153a/bin/infp.sh list` | **226** |
| B | `~/w-p0mig/bin/infp-n.sh list` | **226** |

两把尺子的**成员集合**排序后 `cmp` ⇒ **`IDENTICAL`**（比"两把尺子"更强：同集）。

| 被查件 | A 命中 | B 命中 | 判 |
|---|---|---|---|
| `build/MilBridge/tools/pts-gap-count-check.sh` | **1** | **1** | **在覆盖面内**（原行照抄：`7675737500702c8ae49eddd5abcf0db53abfb6e9f5eadaf430c7c41c99957f71  build/MilBridge/tools/pts-gap-count-check.sh`，与队长给的行**逐字相同**） |
| `verify-all.sh` | **0** | **0** | **洞** |
| `build/MilBridge/tools/display-lease.sh` | **0** | **0** | **洞** |

⇒ **覆盖面洞 ＝ `2` 件** ✓ 与队长 `15:49:23` 的现取**一致**；侦察 §5 第 `9` 条那半句（「`pts-gap-count-check.sh` 也不在」）**经我独立复算＝不成立**。**现文 `docs/ROUTES.md:827`** 照更正后写法落册：**逐字引侦察原句** ＋ **明写「该半句经队长 `2026-09-28T15:49:23` 现取推翻」** ＋ 两把尺子的逐件命中数 ✓ **如实入册，未静默**。

### 2-9 `B-13` 三个值（各自现取）

| 物件 | 现取 | 现文 `:826` 所引 | 判 |
|---|---|---|---|
| 哨兵 `FP` | `grep '^FP=' /tmp/bridge-frozen.flag` ⇒ **`FP=d697b1e10ff48881`** | `d697b1e10ff48881` | ✓ 逐字 |
| `BRIDGE_SRC_FP` | `bash build/bridge-src-fp.sh` ⇒ **`BRIDGE_SRC_FP=d697b1e10ff48881 BRIDGE_SRC_N=78`** | 同 | ✓ |
| `inputs_fp` | `bash ~/w153a/bin/infp.sh fp` ⇒ **`abc76bd55f513b8def295692e64b9d89e2ff99e807be8210aa7ee57f3289601f`** | 同 | ✓ |
| 两枚哨兵 | `279 B`／`sha16 6cb3f97388c3c4dc`／`cmp` **IDENTICAL**／mtime `13:48:27` | 现文所引一致 | ✓ |

⇒ 「哨兵 `FP` ≠ `inputs_fp`（同名不同物）」**成立**，且「现值恰相等时要分开报」的限定句在位 ✓。

---

## §3 我**推翻**的话

### ① `docs/ROUTES.md` `:179`／`:180` 的「**本轮现取**」行号 —— **是插入前坐标**
- `:179` 逐字：「…含不带 `[kind]` 标签的 `2` 行：`TASK-0202`／`TASK-0204`，**本轮现取 `:221`／`:228`**，**仅本次有效**」；`:180` 逐字：「…（**本轮现取 `:240`**，**仅本次有效**）」。
- **现取**：`TASK-0202`＝**`:223`**、`TASK-0204`＝**`:230`**、`TASK-0303`＝**`:242`**。
- **基线现取**（`~/w281-scribe/bak/ROUTES.md.pre-t10`）：**`:221`／`:228`／`:240`** ⇒ 那三个数是**本笔插入前**的坐标；本笔在 `:179`／`:180` 各插 `1` 行、两处都在其前 ⇒ **全体 `+2`**。
- ⇒ 「本轮现取」这四格**为假**（同族：`t72` 判词里 `t71` 那笔「现取 `:788`」＝父代坐标，当时我判 **`medium`**）。**影响面低**：三处都带内容锚（TASK 号唯一可检索）且已标「仅本次有效」。

### ② `build/MilBridge/P1-w1-report.md:29` 的 `grep -c 'D-G176'` 「改后 **`13`**」 —— **不成立**
- `:29` 逐字：「`grep -c 'D-G176'` ＝ **`1`**（改前）→ **`13`**（改后，全为本条目与引文）」。
- **现取**：`grep -c 'D-G176' build/.../KNOWN-DEFECTS.md` ⇒ **`2`**（行）／`grep -o … | wc -l` ⇒ **`3`**（处）。改前（`HEAD=88ab841` 的 blob 与 `pre-t10` 备份**两者**）⇒ **`1`**。
- 现取的两行＝`:3589`（条目形态标题）＋`:3606`（本笔 dated 追加行）。
- ⇒ 该格**不复现**（差 `11`）。**不影响结论**（`D-G176` 条目早已存在的判词仍成立），但这是**本波主判据**名下的一个**真不复现格**。

### ③ `P1-w1-report.md:162` 的「**`224` 行数据行**逐字节不变」 —— **计数标签错**
- 现取：`wc -l` ＝ **`224`**、`grep -c '^#'` ＝ **`9`**、`grep -vc '^#'` ＝ **`215`**（牙自吐 `DEFREG_DECL=n=215`）⇒ **数据行是 `215`**，`224` 是**含 9 行注释的全文行数**。
- **实质断言（数据行逐字节不变）我复算＝成立**（`tail -n +2` 的 `cmp` `IDENTICAL`、`diff` `0` 行）。
- ⚠️ **同族已第二次**：`t6` 的 `P1-dg179-report.md:66` 有**同一句**（我在 `t8` 判词 §3-① 已推翻），本轮 `t10` 报告再次出现 ⇒ 建议在册直接写死「`224` 行 = 数据 `215` ＋ 注释 `9`」的口径。

### ④ `P1-w1-report.md:52` 的「改后**每个 `sha16` 各出现一次**」 —— **射程未写，全件不成立**
- 现取：**注释内** `759ac1686e5ef87d`／`8cb1b50619f4c133`／`7e8a217b4165a6b9` ＝ **`1／1／1`** ✓（该格按「注释里」读时成立）；
- **全件**：`8cb1b50619f4c133` ＝ **`2`** 次（第 2 次在**代码行** `prev_provider='8cb1b50619f4c133'`，现取 `:448`，**未动**）。
- ⇒ 句子需限定为「**该段注释里**各出现一次」才成立。

### 具名不对拍（不判假，逐条给现取）

| # | 句 | 现取 | 说明 |
|---|---|---|---|
| ①' | `P1-w1-report.md:52`「逐字均可在 `P0-w80-report.md` §6 里找到：`:72` 两值与 **`:63`** 的 `7e8a217b4165a6b9`」 | `7e8a217b4165a6b9` 现取在 **`:68`** 与 `:72`；**`:63`** 现取是「⇒ **归因口径（主控裁定）**…」，**不含任何 sha16** | 行号引用不符（内容锚未给 ⇒ 建议改为「`§6` 的 `时刻①` 行」） |
| ②' | `P1-w1-report.md:52`③「（`:446`）的 `prev_provider='8cb1b50619f4c133'` 未动」 | 现取 **`:448`**（`pre-t10` 备份 **`:447`**，因本笔 +1 行） | 行号不符；**内容确未动** ✓ |
| ③' | `P1-w1-report.md:29`「`WFREEZE_BLOCKVALUES_HIT` **形态命中 `1` 处**（`wave-freeze-consistency-check.py:660`）」 | 该串在件内 **`4`** 处（`print` 站点 `:620`／`:624`／`:656`／`:660`）；**`key=… probs=… block9=… tier=… live=` 的规范形态**＝ **`1`** 处（`:660`） | **射程未写**：按"该串全部"读＝4，按"规范形态"读＝1 |
| ④' | `P1-w1-report.md:52`① 的措辞「＝**哨兵现取**」 | `P0-w80-report.md:72` 逐字是「**哨兵值** ＝ `GENS['#80']['prev_provider']`」；而**现盘**哨兵 `PROVIDER=24e4e0a731dbed40` | 在 `#79`／`#80` 纪元语境下成立；脱离语境会误读为"现盘哨兵值" |

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | `B-11` 的**牙面落地**（新牙 `handoff-machine-values-check.sh`） | **`NOINFO(reason=落地件不在本波写域)`** | 现取 `test -e` ⇒ **不存在**；与 `t10` 自述一致（写域外三处：新牙件／`close-wave.sh`／`verify-all.sh`）。我以「**逐格现跑其生成命令**」替代（§2-1），并把**唯一不复现格**点名（`cell#9 provider`）。 |
| N2 | `B-17` 的**牙面落地**（新牙 `routes-tree-count-check.sh`） | 同上 | 现取**不存在**；我以自写抽取器等价复算（§2-3）。 |
| N3 | §2「**无链在跑**」 | **不能完全独立判定** | 只能证「`CS:9 = gen=#80`（已冻结）＋ `porcelain` 仅 1 个非本波未跟踪件」；「无链在跑」的完备判据（槽 `/proc` 面）不属本件写域。 |
| N4 | `§3` 里 `TASK-0201` 的 **`4.87%`**（统计口径） | **`NOINFO(未复算: 属 t7 车道正在进行的 TASK-0201 复测面)`** | 本件不含该统计量的复算器；不引上一代数。 |
| N5 | `--emit` 只证「同趟生成」 | 不判 | 我能证带 `KD=` 锚 ＝ 改后册（内容证）、`cmp` 逐字节、`DECLDRIFT=0`；**不能**证「回填过程无第三方介入」（无审计日志）。 |
| N6 | 三笔并发提交（`e122f8d4`／`39f23d0`）的**写者身份** | **`NOINFO`** | `commit` 由主控/写者落，无我可见的 attribution 记录；我按**时间线**如实记（§2-2），**不把后来者算到 `t10` 头上**。 |
| N7 | `docs/ROUTES.md` `:828`（§5-8 口径句）的**「改 ROUTES/HANDOFF 要不要重发」精化** | **成立**（非 `NOINFO`） | 我现取复算：`defect-registry-check.sh` 的 `ALLKEYS='KD CS HO AB KRJ KRF KRP'` **不含** `ROUTES.md`／`HANDOFF-NEXT.md`；`grep -c 'ROUTES'` 该件＝**1**（**打印行** `DEFREG_ROUTES=…`，不是键）、`grep -c 'HANDOFF'`＝**0** ⇒ 精化句与机制一致。 |
| N8 | `B-11` 的「**代价**」格（覆盖面 `226 → 227`、步数 `55 → 56`） | **不判** | 属**假设性**推演（若落牙才成立）；其**前提数**（`226`／`55`）我现取复现 ✓，推演本身不是判据。 |

---

## §5 我的自伤与更正（如实记）

1. **一条 `grep` 写坏**：我首轮为取 `[42] --expect` 用了 `grep -n 'FP-MANIFEST-TEETH' verify-all.sh | grep -o 'expect [0-9]*' | head -2` ⇒ 命中**别的步骤**的 `expect 194／192`，差点写错数。**当场改用行锚**：`grep -n 'run_step "FP-MANIFEST-TEETH"'` ⇒ `:1195 … --expect 226` ✓。教训：**用具名锚，不用子串管道**。
2. **heredoc 引号自伤**：另一条计数命令里我把 `\"` 写进双引号 ⇒ bash 报「未预期的 EOF」、该行**没跑**。已改用 `grep -c '<literal>'` 重跑（`WFREEZE_BLOCKVALUES_HIT` ＝ `4`）。
3. **我没有取到 `t10` 的 `--emit` 那一刻的现场 cp**；我用「**带 `KD=` 锚 ＋ `cmp` 逐字节 ＋ 重跑 `--emit` 与现场相同**」三条并证取代（§2-7），并把「回填者身份」记为 `NOINFO`（§4-N5）。

---

## §6 收尾

- `$N` 内我**只写本件**；`docs/ROUTES.md`／`HANDOFF-NEXT.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／两颗牙／`verify-all.sh`／`build/close-wave.sh` **一字未动**（四件 sha16 三趟同值，见 §2-4）。
- 沙箱与中间件全在 `~/wv81y/`（不落 `/tmp`）；未跑门禁/构建/应用/显示位；未 `git add/commit/push`。
- `porcelain` 收尾现取（本件落盘**之前**）：**只有 `?? build/MilBridge/P1-task0201-criteria.md`**（`t7` 的件）；**无 `t10` 名下的未提交残留**。
- ⏪ **追加（本件落盘之后 `16:0x` 现取，只补不删）**：`porcelain` 现为 **3** 行 —— `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）／`?? build/MilBridge/P1-w1-verify.md`（**本件自身**）／`?? build/MilBridge/P1-w2-criteria.md`（**另一写者的 W2 判据件，非本件、非 `t10`**）⇒ 「本件是唯一由我写入的件」这一条**不受影响**。
- **判词尾行**：`P1-W1-VERIFY: verdicts=[PARTIAL,PASS,PASS,PASS,PASS,PASS,PASS,NOINFO] cells9=[7ok,1time-superseded,1not-reproduced(provider)] s13=[79,77,2,uid79,beta74/1/2/0 ok] emit=BYTE_IDENTICAL(-DECL-GEN) declrift=0 hole=2(pts-in-coverage) freeze=comment-only(0 code lines) pycompile=OK overturned=4 named=4 t10files_sha16_unchanged=yes`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `2199e3af0f5df6f8` ／ FULL `2199e3af0f5df6f89530711ec377f3bb4accda008688a4aa1242f3f36c1b015a` ／ `wc -l` ＝ 319 行（**不含**本行）／末次读取时刻 `2026-09-28T16:02:0x+08:00`／写入方式 **temp ＋ rename**。
