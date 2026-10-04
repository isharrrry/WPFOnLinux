# P1-w3-verify —— `t23`（W3a）＋`t24`（W3b）**合并交付独立复核判词**（`verifier` / `t22`）

- **被核交件**（原 `t21` 整批判 `failed` 后由队长拆分为两条，本件从「依赖已失败的 `t21`」**改接**为依赖 `t23`＋`t24`）：
  - **W3a ＝ `t23`**：提交 **`1a04da6e5475feef9590b0b9270abda873191304`**（`%cI = 2026-09-28T16:15:44+08:00`）—— 哨兵键序／字节规范入册 ＋ 新牙 `sentinel-spec-check.sh` ＋ 四例两极化 ＋ `§15af` 的 `C-1` 关账。
  - **W3b ＝ `t24`**：提交 **`192b573ff1b04f8009cd9b6448c3d2030aa9b53d`**（`%cI = 2026-09-28T16:18:37+08:00`）—— 仓内哨兵写入端 `build/MilBridge/tools/wave-push.sh` ＋ 搬仓等价自证 ＋ `B-2`／`B-6`／`B-13`／`B-14` 登记。
- **仓**：`$N=/home/links-dev/netTest/GitProj/WPFOnLinux`｜我开工 `HEAD=192b573`；**收尾 `HEAD=0f12688`**（`16:20:50`，`t25` 的 `D-G181` 关账批 —— 期间并发写者在动）。
- **读取时刻**：本件全部读数在 **`2026-09-28T16:20:46` – `2026-09-28T16:22:2x +0800`** 之间**现取**（命令与读数为同一趟）。
- **载体**：本件（`build/MilBridge/P1-w3-verify.md`）＝我唯一写入的件。沙箱/夹具在 `~/wv86y/`（**不落 `/tmp`**）。
- **边界**：`$N` 只读；不跑门禁/构建/整波/应用/显示位；未 `git add/commit/push`。**不复述** `t23`／`t24` 的结论 —— 每条我自己现取、每条极化我自己重跑。

---

## §0 逐条判词速览

| # | 复核项 | 判词 |
|---|---|---|
| 1 | **搬仓等价性可判**（清单逐件可比 ＋ 权威归属 ＋ 原件保留 ＋ 只搬那一小段） | **成立**（`--dry-run` 13 行 vs 两枚生产哨兵 **`cmp` IDENTICAL ×2**、sha16 `6cb3f97388c3c4dc`；沙箱写路 **`WPW=PASS` ＋ 三方 cmp 全等**；权威归仓内件、原件 `5015004b0f0d917e` **保留**；仓内件 **推送语义命中 `0`**） |
| 2 | **哨兵规范可对拍**（行数／键名集合＋键序 逐项；正反极化我重跑） | **成立**（两枚哨兵现取 **`13` 行／13 键／固定键序**，与规范逐字相同；**七条极化我全部重跑**，见 §2-2／§2-3） |
| 3 | **`build/close-wave.sh`**（逐行改动 ＋ 指纹逐件归因 ＋「未跑整波」机器证） | **成立**（**未被本波改**：sha16 `f9a2ee3ee35baff8`、`worktree==HEAD`、`4a97a0d..HEAD` 内 **0 笔**、mtime `10:21:57`；`fp_inputs()` 是**显式列举**、覆盖面 `226`；**未跑整波**四条机器证）｜⚠️ **指纹零位移已不可复现**（§4-N3，动因**逐件归因**为第三方件） |
| 4 | **`B-2`／`B-6`／`B-13口径`／`B-14` 逐条** | **成立**（四条各有落地形态＋现取读数；`B-2`／`B-6` 如实标**未闭**）｜⚠️ 附 V1（`B-13` 那句坐标错） |
| 5 | 两牙 ＋ 越域 ＋ 未 add | **成立**（`DEFREG=PASS declared=217 route_ids=217` ＋ `DECLDRIFT=0 keys=-`；`REPORTID=PASS files=197 ids=2053 declared=217`；`porcelain` 逐行全属 **`t25`／`t7`** ⇒ `t23`／`t24` **名下零脏件**；暂存 `0`） |
| 6 | 载体 ＋ 自报 sha16 ＋ 读取时刻 | **成立**（§6） |
| — | **我推翻的话** | **`none`**（两处**口径/坐标**需补：V1／V3） |

---

## §1 复算命令**原文**（逐条照抄）

### 1.1 哨兵现取 ＋ 规范对拍
```bash
cd $N && for f in /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag; do wc -l < $f; cat -n $f; \
   echo "CR=$(grep -c $'\r' $f)  末字节=$(tail -c1 $f | xxd -p)"; done
cd $N && grep -o '^[A-Z_0-9]*=' /tmp/bridge-frozen.flag | tr -d '=' | tr '\n' ' '
cd $N && grep -n "SPEC_KEYS=" build/MilBridge/tools/sentinel-spec-check.sh
cd $N && cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag && echo IDENTICAL
cd $N && sed -n '326,339p' build/MilBridge/HANDOFF-NEXT.md          # 规范 7 条现取
cd $N && sed -n '830p' docs/ROUTES.md                               # C-1 关账行（含内容锚 :818）
cd $N && sed -n '818p' docs/ROUTES.md
```

### 1.2 极化（**全部我自己造夹具、自己跑**；`SSC_S1`／`SSC_S2` 为牙的覆盖口）
```bash
cd $N && bash build/MilBridge/tools/sentinel-spec-check.sh                 # 正极（真树）
cd $N && bash build/MilBridge/tools/sentinel-spec-check.sh --selftest 2>~/wv86y/ssc-stderr.txt ; echo rc=$? ; wc -l < ~/wv86y/ssc-stderr.txt
# A 键序打乱（printf/python 显式重排，不用 sed 行号）
python3 - <<'PY'
src=[l for l in open('/tmp/bridge-frozen.flag').read().split('\n') if l]
open('/home/links-dev/wv86y/ssc/disorder','w').write('\n'.join([src[0],src[2],src[1]]+src[3:])+'\n')
PY
SSC_S1=$T/disorder SSC_S2=$T/disorder bash build/MilBridge/tools/sentinel-spec-check.sh
cp $T/real $T/sameorder ; SSC_S1=$T/sameorder SSC_S2=$T/sameorder bash build/MilBridge/tools/sentinel-spec-check.sh   # 成对对照
# B 字段清空 / C none() / D 缺一枚 / 附加 行数14 / 附加 CR
sed 's/^WIC=.*/WIC=/' $T/real > $T/empty        ; SSC_S1=$T/empty SSC_S2=$T/empty bash build/MilBridge/tools/sentinel-spec-check.sh
sed 's/^WIC=.*/WIC=none(未取到)/' $T/real > $T/none ; SSC_S1=$T/none SSC_S2=$T/none bash build/MilBridge/tools/sentinel-spec-check.sh
SSC_S1=$T/real SSC_S2=$T/does-not-exist bash build/MilBridge/tools/sentinel-spec-check.sh
{ cat $T/real; echo 'EXTRA=x'; } > $T/lines14 ; SSC_S1=$T/lines14 SSC_S2=$T/lines14 bash build/MilBridge/tools/sentinel-spec-check.sh
sed 's/^SHA=.*/SHA=4e25e4b27d4d5ae1\r/' $T/real > $T/cr ; SSC_S1=$T/cr SSC_S2=$T/cr bash build/MilBridge/tools/sentinel-spec-check.sh
```

### 1.3 搬仓等价性
```bash
cd $N && cat -n build/MilBridge/tools/wave-push.sh                     # 全件 85 行
cd $N && bash build/MilBridge/tools/wave-push.sh --dry-run > $L/wpw.dry 2>$L/wpw.dry.err
cmp $L/wpw.dry /tmp/bridge-frozen.flag && echo IDENTICAL
cmp $L/wpw.dry ~/wfp-runs/bridge-frozen.flag && echo IDENTICAL
diff $L/wpw.dry /tmp/bridge-frozen.flag | wc -l
mkdir -p $L/sb && WPW_S1=$L/sb/flagA WPW_S2=$L/sb/flagB bash build/MilBridge/tools/wave-push.sh --write
cmp $L/sb/flagA $L/sb/flagB && cmp $L/sb/flagA /tmp/bridge-frozen.flag && cmp $L/sb/flagB ~/wfp-runs/bridge-frozen.flag
cd $N && grep -nciE 'git +push|ls-remote|origin |gitee|ssh |scp |rsync|curl|wget' build/MilBridge/tools/wave-push.sh   # 期望 0
cd $N && ls -l ~/w79c/bin/w79-push.sh ; sha256sum ~/w79c/bin/w79-push.sh | cut -c1-16 ; wc -l < ~/w79c/bin/w79-push.sh
cd $N && tail -22 ~/w79c/bin/w79-push.sh                                # 原件尾部写哨兵那一小段
```

### 1.4 承重件 ＋ 指纹 ＋ 未跑整波
```bash
cd $N && sha256sum build/close-wave.sh | cut -c1-16 ; git log -1 --format='%h %cI %s' -- build/close-wave.sh
cd $N && git diff --quiet HEAD -- build/close-wave.sh && echo SAME ; git log --oneline 4a97a0d..HEAD -- build/close-wave.sh | wc -l
cd $N && sed -n "$(grep -n 'fp_inputs()' build/close-wave.sh | head -1 | cut -d: -f1),+12p" build/close-wave.sh
cd $N && bash ~/w153a/bin/infp.sh list > $L/listA.txt ; wc -l < $L/listA.txt
cd $N && for f in build/MilBridge/tools/wave-push.sh build/MilBridge/tools/sentinel-spec-check.sh build/MilBridge/tools/defect-registry-check.sh build/close-wave.sh; do \
   printf '%s in-list=%s\n' "$f" "$(grep -cF "$f" $L/listA.txt)"; done
cd $N && bash ~/w153a/bin/infp.sh fp | cut -c1-16
# 进程面（**排除自身与祖先**，按 PID 语义）
cd $N && ps -eo pid,ppid,args > $L/ps.txt
awk -v me=$BASHPID -v pp=$PPID '$1==me || $1==pp {next} /close-wave|verify-all|integration-wave/ && !/awk|grep/ {c++} END{print c+0}' $L/ps.txt
# 时间线
cd $N && find . -path ./.git -prune -o -type f -newermt '2026-09-28 16:05' \( -name '*POST.done' -o -name '*record.txt' -o -name '*close-wave*' -o -name '*.log' \) -print | grep -vE '\.agent-teams|/bak/'
cd $N && stat -c '%n %y' ~/w21-verify/w80-POST.done /tmp/bridge-frozen.flag build/close-wave.sh
```

### 1.5 四条目 ＋ 两牙 ＋ 越域 ＋ 提交级 sha16
```bash
cd $N && grep -n 'B-14` 已闭\|B-13` 口径钉死\|B-2` 登记\|B-6` 登记' build/MilBridge/HANDOFF-NEXT.md
cd $N && sed -n '832,838p' docs/ROUTES.md
cd $N && bash build/MilBridge/tools/defect-registry-check.sh 2>&1 | grep -E '^DEFREG=|^DEFREG_DECL=|^DEFREG_DECLDRIFT'
cd $N && bash build/MilBridge/tools/report-id-domain-check.sh 2>&1 | tail -1
cd $N && git status --porcelain ; git diff --cached --numstat | wc -l
cd $N && for f in build/MilBridge/HANDOFF-NEXT.md docs/ROUTES.md build/MilBridge/tools/sentinel-spec-check.sh build/MilBridge/P1-w3a-criteria.md build/MilBridge/P1-w3a-report.md; do \
   printf '%-50s %s\n' "$f" "$(git show 1a04da6:$f | sha256sum | cut -c1-16)"; done
cd $N && git show --numstat --format='%H %P %cI' 1a04da6 ; git show --numstat --format='%H %P %cI' 192b573
cd $N && for f in build/MilBridge/HANDOFF-NEXT.md docs/ROUTES.md; do printf '%s ^-= %s\n' "$f" "$(git diff 192b573^ 192b573 -- $f | grep -c '^-[^-]')"; done
cd $N && head -c $(stat -c %s <(git show 192b573^:build/MilBridge/HANDOFF-NEXT.md)) <(git show 192b573:build/MilBridge/HANDOFF-NEXT.md) | cmp - <(git show 192b573^:build/MilBridge/HANDOFF-NEXT.md) && echo PREFIX-IDENTICAL
cd $N && stat -c '%h %n' build/MilBridge/tools/wave-push.sh build/MilBridge/tools/sentinel-spec-check.sh build/close-wave.sh /tmp/bridge-frozen.flag
```

---

## §2 逐格对照表

### 2-1 哨兵**现取**（判据 2 的基准）

| 项 | 我现取 | 判 |
|---|---|---|
| 行数 | **`13`**（两枚同） | ✓ 与规范第 ① 条相同 |
| 键名＋**键序**（逐字） | `SHA`｜`FP`｜`PC`｜`PF`｜`WB`｜`WIN32SHIM`｜`HBTL`｜`WIC`｜`PROVIDER`｜`DWF`｜`WAVE`｜`BASELINE`｜`BASELINE_SHA16` | ✓ 与规范第 ② 条**逐字相同**；与牙的 `SPEC_KEYS`（`sentinel-spec-check.sh:21` 现取）**逐字相同** |
| 字节格式 | `CR` 计数 = **`0`**；末字节 = **`0a`**；无空行 | ✓ 规范第 ③ 条 |
| 两枚关系 | `cmp` ⇒ **`IDENTICAL`**；`sha16 = 6cb3f97388c3c4dc`；各 **279 B**；mtime `13:48:27` | ✓ 规范第 ④ 条 |
| 键值现取（例） | `SHA`=`4e25e4b27d4d5ae1`／`FP=d697b1e10ff48881`／`PROVIDER=24e4e0a731dbed40`／`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` | ✓ 与 `NINE_PATHS`／`BRIDGE_SRC_FP`／`CS:9`（`gen=#80`／`b96d4312565a3c49`）逐项一致 |
| **写规矩的偏差（侦察件）** | 侦察 `§C-1` 写「**十键**固定序」；现取 **13 键** | ✓ `t23` **如实记**该不符（规范节 + `§15af` 关账行） |

### 2-2 哨兵牙**两极化（我全部重跑，原始机读行）**

| 腿 | 我现取的原始机读行 | `rc` | `t23` 声称 | 判 |
|---|---|---|---|---|
| **正极（真树）** | 逐条 `SSC_LINES/KEYSET/CR/BLANK/EMPTY=PASS` ×2 ＋ `SSC_CMP=PASS` ＋ 九键＋`FP`＋三键 `SSC_VALUE=PASS` ⇒ **`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`** | `0` | 同 | ✓ |
| **A 键序打乱**（我造：`SHA,PC,FP,…`） | **`SSC_KEYSET=FAIL sentinel=a got=[SHA PC FP PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16 ] want=[SHA FP PC PF …]`** ＋ `SSC=FAIL 规范不满足（逐条见上）` | `1` | 同（得=乱序、want=规范序） | ✓ **点名** |
| **A 对照**（同一夹具、键序复原） | `SSC_KEYSET=PASS … order=spec` ⇒ **`SSC=PASS`** | `0` | —（我加的成对对照） | ✓ **成对成立**（唯一变量＝键序） |
| **B 字段清空**（`WIC=`） | **`SSC_EMPTY=FAIL sentinel=a 空值行=8,（取不到须写 none(<reason>)）`** ×2 ＋ `SSC=FAIL` | `1` | 同 | ✓ |
| **C `none(<reason>)` 占位**（`WIC=none(未取到)`） | `SSC_EMPTY=PASS` ＋ **`SSC_NONE=ALLOWED sentinel=a keys= WIC（规范允许的占位形态，上屏不判红）`** ⇒ **`SSC=PASS`** | `0` | 同 | ✓ **允许且不判红** |
| **D 缺一枚哨兵** | **`SSC=NOINFO reason=sentinel-absent path=…（**缺一枚不许静默判等**）`** | **`2`** | 同 | ✓ **非零且非静默判等** |
| 附加：行数 14 | `SSC_LINES=FAIL sentinel=a got=14 want=13` ＋ `SSC_KEYSET=FAIL`（多出 `EXTRA`）＋ `SSC=FAIL` | `1` | 规范第 ① 条 | ✓ |
| 附加：含 `CR` | `SSC_CR=FAIL sentinel=a 含 CR` ×2 ＋ `SSC=FAIL` | `1` | 规范第 ③ 条 | ✓ |
| `--selftest` | `SSC_SELFTEST=PASS cases=4 pass=4 fail=0`；**stderr 行数 ＝ `0`** | `0` | 4/4、stderr 零行 | ✓ |

### 2-3 搬仓等价性（判据 1）

| 项 | 我现取 | 判 |
|---|---|---|
| 件规模 | 仓内 `build/MilBridge/tools/wave-push.sh` ＝ **85 行／5572 B／`755`／sha16 `b1a167146f9dcb35`**（＝ `t24` 声称，且在 `192b573` 提交上**逐位相同**）｜仓外原件 `~/w79c/bin/w79-push.sh` ＝ **248 行／23251 B／sha16 `5015004b0f0d917e`**（＝ `t24` 声称） | ✓ |
| **「同一趟清单」逐件可比** | `--dry-run` ⇒ `rc=0`、**13 行**、`stderr` 一行 `WPW=DRYRUN lines=13 keys=13`；与 `/tmp/bridge-frozen.flag` **`cmp` IDENTICAL**、与 `~/wfp-runs/bridge-frozen.flag` **`cmp` IDENTICAL**；`diff` 各 **`0`** 行；`sha16 ＝ 6cb3f97388c3c4dc`（＝两枚生产哨兵现取） | ✓ **13 键逐键 ＋ 两枚逐件全等** |
| 沙箱写路（我的车道） | `WPW_S1=$L/sb/flagA WPW_S2=$L/sb/flagB … --write` ⇒ **`WPW=PASS sentinels=2 cmp=IDENTICAL lines=13 keys=13`**（`rc=0`）；随后 **三方 `cmp` 全等**（沙箱 A ↔ 沙箱 B ↔ 生产） | ✓ |
| 生产哨兵未被写 | 前后 `cmp` 未变；`mtime` 仍 **`2026-09-28 13:48:27.398116209`** | ✓ |
| **只搬那一小段（非整件照搬）** | 仓内件 **推送语义命中 `0`**（`git push`／`ls-remote`／`origin`／`gitee`／`ssh`／`scp`／`rsync`／`curl`／`wget` 计数 0）；原件尾部**确有**推送账语义（`REMOTE_PER_COMMIT`／`git rev-list`／`ls-remote` 等）⇒ **未搬** | ✓ |
| **权威归属** | `HANDOFF-NEXT.md:344`（`B-14` 已闭）＋ `docs/ROUTES.md §15ag:834` **两处都写清**：「权威 ＝ **仓内** `wave-push.sh`（键序／取值规则）；仓外 `~/w79c/bin/w79-push.sh` **降为留档**（在册、不再作口径来源）」 | ✓ **写清** |
| **原件是否保留** | **保留**：`ls -l` 命中、`sha16 5015004b0f0d917e`、`23251 B`；保留理由在册（`ROUTES §15ag` 行「源（不删）」） | ✓ |
| 牙／件 `%h` | `wave-push.sh`／`sentinel-spec-check.sh`／`close-wave.sh`／两枚哨兵 ⇒ **全 `1`** | ✓ 无硬链接 |

### 2-4 承重件 `build/close-wave.sh`（判据 3）

| 项 | 我现取 | 判 |
|---|---|---|
| **逐行改动** | `sha16 = f9a2ee3ee35baff8`；`git diff --quiet HEAD -- <件>` ⇒ **`SAME`**；`git log --oneline 4a97a0d..HEAD -- <件>` ⇒ **`0` 笔**；`mtime = 2026-09-28 10:21:57.131884451`（＝`#80` 冻结时代）⇒ **本波对它的改动 ＝ `0` 行** | ✓ **未改，不存在"必要之外"的改动** |
| **`D-G130` 实例④ 形态**（派生路径绑在参数解析之前／符号链接绕过前缀闸） | 无改动 ⇒ **不可能由本波引入**；且 `fp_inputs()` 现取是**显式 `find` 列举**（非 glob 展开），`provider` 走工程产出目录（`NINE_PATHS` 同口径） | ✓ 不成立 |
| `fp_inputs()` 形态 | 现取为**手写列举**函数（`close-wave.sh:70`），**不是 glob** ⇒ 「新增件不会自动进指纹」这一点机械可查（见下行） | ✓ |
| **覆盖面件数** | `infp.sh list` 的行数 ⇒ **`226`**（与 `t24` 声称 `226/226` 相同） | ✓ |
| **新增两件在覆盖面内吗** | `wave-push.sh` ⇒ **`in-list=0`**；`sentinel-spec-check.sh` ⇒ **`in-list=0`**（对照 `defect-registry-check.sh` ⇒ `1`、`close-wave.sh` ⇒ `1`）⇒ **本波新增件不扰动指纹** | ✓ |
| **`inputs_fp` 入口／出口** | `t24` 声称 `e9f95ec005715b3a…`（入口＝出口、零位移）；**我现取 ＝ `8c4ce894d04eae7b…`** | ⚠️ **已不可复现** ⇒ §4-N3：动因**逐件归因**为第三方改的 `build/MilBridge/tools/pkg-src-retiredpath-check.sh`（`in-list=1`、`numstat 34/1`、`worktree≠HEAD`）；**其余全部被改件 `in-list` 全 `0`** |
| **「本波未跑整波链」机器证（四条）** | ① **进程面**：`ps -eo pid,ppid,args` 排除 `$$`／`$PPID`／`awk`／`grep` 后命中 **`0`**（`close-wave`／`verify-all`／`integration-wave`）｜② **生产哨兵 `mtime` 未变**（`13:48:27.398116209` —— 若跑过写路/整波就会刷新）｜③ **产物面**：`find -newermt '2026-09-28 16:05'` 按 `*POST.done`／`*record.txt`／`*close-wave*`／`*.log` 过滤 ⇒ **空**｜④ **标记面**：`~/w21-verify/w80-POST.done` mtime ＝ **`2026-09-28 11:51:17`**（`#80` 收口时），之后无新标记 | ✓ **机器证齐** |

### 2-5 `B-2`／`B-6`／`B-13口径`／`B-14`（判据 4）

| 条 | 落地形态（现取） | 现取读数 | 判 |
|---|---|---|---|
| **`B-14`** | **已闭**：写入端搬仓 ⇒ 仓内新件 `wave-push.sh`；`HANDOFF-NEXT.md:344` ＋ `ROUTES §15ag` 双处登记；**推送逻辑不搬**；原件保留、降留档 | `--dry-run` 13 行 `cmp` 全等；沙箱 `--write` `WPW=PASS`；推送语义命中 `0` | ✓ |
| **`B-13`口径** | **钉死**：`HANDOFF-NEXT.md:346` 写「哨兵 … `FP` 的语义是 **`BRIDGE_SRC_FP`**（`bash build/bridge-src-fp.sh`），**不是** `inputs_fp`；两者**必须不等**，相等 ⇒ 按红处理」；`ROUTES §15ag:836` 同句 | `BRIDGE_SRC_FP = d697b1e10ff48881`（现取）**≠** `inputs_fp = 8c4ce894d04eae7b`（现取，`t24` 时是 `e9f95ec0…`）⇒ **不等** ✓；`wave-push.sh` 内以注释钉死同一句 | ✓ ｜⚠️ **V1**（那句里的"第 11 行起"是错坐标） |
| **`B-2`** | **只登记（未闭，如实标）**：`HANDOFF-NEXT.md:347` —— 冻结点之后 `--prev-check-only` 单独复跑 ⇒ **假红**；归因 = 判据输入的**瞬时状态**依赖（家族 `D-G130`）；**成本**（把"上一冻结点"改为落盘不变量：哨兵＋车道目录双读）＋**下一步**（与 `D-G130` 一并） | 我**未跑** `--prev-check-only`（不在本件边界）⇒ 该条**只判"登记形态与内容"**：`成本`／`下一步` 均在位、且**标了未闭** | ✓（落地形态成立；机制读数 `NOINFO`，见 §4-N4） |
| **`B-6`** | **只登记（未闭，如实标）**：`HANDOFF-NEXT.md:348` —— `FILES` 是**累积语义**（历趟累加、非当趟快照）⇒ 反复重发会重复计数、跨趟对账须先按 `basename` 去重；**成本**＋**下一步**（与 W4 接线同趟排期） | 同上：登记形态成立；机制读数 `NOINFO`（未跑整波） | ✓ |
| `C-1` 关账（`t23`，配套） | `docs/ROUTES.md:830` —— 关账对象**内容锚**「哨兵的键序／字节格式无规范」＝ `:818`（**我现取该行逐字含该串** ✓）；规范载体 ＝ `HANDOFF` 纪律区那一行；判据件 sha16 `8c8470a3b3dd0c0d`（现取相同）；三态 `0/1/2`；**不接线** | `wave-push.sh`／`sentinel-spec-check.sh` 在 `close-wave.sh`／`verify-all.sh`／`integration-wave.sh` 里**命中各 `0`** ⇒ **不接线**属实 | ✓ |

### 2-6 只增不改（提交级）＋ 越域

| 件 | `t23`／`t24` 提交的 `numstat` | `^-[^-]` | 前缀 `cmp` | 判 |
|---|---|---|---|---|
| `HANDOFF-NEXT.md` | `1a04da6` `13 0`；`192b573` `12 0` | `0`／`0` | `192b573`：`92128 → 94627` B，**前缀 `IDENTICAL`** | ✓ |
| `docs/ROUTES.md` | `1a04da6` `1 0`；`192b573` `8 0` | `0`／`0` | `192b573`：`348147 → 349150` B，**前缀 `IDENTICAL`** | ✓ |
| `tools/sentinel-spec-check.sh`（新） | `1a04da6` `118 0` | `0` | — | ✓ |
| `tools/wave-push.sh`（新） | `192b573` `85 0` | `0` | — | ✓ |
| `P1-w3a-criteria/report`／`P1-w3b-criteria/report` | `28/0`／`41/0`／`31/0`／`48/0` | `0` | — | ✓ |
| **`t23` 声称的五个 sha16** | `HANDOFF 9099414a189fdcd2`／`ROUTES 1e86b6f577ce9e14`／牙 `8c8470a3b3dd0c0d`／criteria `df1db45904804947`／report `eadba91b2371c5ec` ⇒ **我在 `1a04da6` 提交上逐件复现，五格逐位相同** | — | — | ✓ |
| **越域** | `porcelain` 逐行：`M P1-tail-scout.md`／`M P1-w2-report.md`／`M tools/defect-registry-declared.tsv`／`M tools/pkg-src-retiredpath-check.sh`／`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`?? P1-task0201-criteria.md`／`?? P1-w2-close-report.md` ⇒ **全部为 `t25`／`t7`／W2 的件**（`~/w281-scribe/bak/*.pre-t25` 备份件名可佐证）；暂存区 **`0`** 行 | — | — | ✓ **`t23`／`t24` 名下零脏件** |

---

## §3 我点名的具名差异（**我推翻的话 ＝ `none`**）

### V1（low）：`B-13` 口径句里的「**第 11 行起**」是错坐标
- 现取原文（`HANDOFF-NEXT.md:346`）：「**`B-13` 口径钉死（防串口径）**：哨兵**第 11 行起** `FP` 的语义是 **`BRIDGE_SRC_FP`**…」。
- **现取**：`FP` 在哨兵**第 `2` 行**（`grep -n '^FP=' /tmp/bridge-frozen.flag` ⇒ `2:FP=d697b1e10ff48881`）；**第 `11`–`13` 行**是 `WAVE`／`BASELINE`／`BASELINE_SHA16`。
- ⇒ 句子把「第 11 行起（三键）」的坐标**挂到了 `FP` 上**；**实质口径（`FP` = `BRIDGE_SRC_FP` ≠ `inputs_fp`）不受影响**、且同句已点明键名与取数命令。属本仓**反复出现的"坐标/量名挂错"族**（`t70` 未来戳 → `t71` `:788` → `t16` F1 → `t18`/`t19` 同秒戳 → **本条**）。
- 建议：dated 追加一句把坐标改为「`FP`（第 `2` 行）」并保留「第 `11`–`13` 行 ＝ `WAVE`／`BASELINE`／`BASELINE_SHA16`」的对照。

### V2（low）：`wave-push.sh --write` 的**失败路径**有「部分写 ＋ reason 未点名真因」
- 现象（我在自己沙箱里**第一趟就撞到**）：把 `WPW_S1` 指向一个**父目录不存在**的路径时 ⇒ `install: 无法创建普通文件 '…/flagA': 没有那个文件或目录`（A **未写**）；脚本随后 `mkdir -p "$(dirname "$S_B")"` 后 `install … "$S_B"`（B **写成功**）⇒ `cmp` 不等 ⇒ 输出 `WPW=FAIL reason=sentinels-differ`、**`rc=1`**。
- 两点：① **部分写**（B 更新、A 保持旧）—— 生产路径上 `S_A=/tmp/…` 恒存在，故实际触发面窄；② **`reason` 未点真因**（真因是 A 的 `install` 失败，只在 `install` 的 stderr 里）⇒ `D-G104`（读数器输出语义）同族。
- **方向安全**：非零 `rc` ＋ 明确 `FAIL`，**没有静默判绿** ✓（这也是我要的"任一侧为空 ⇒ 响亮失败"）。
- 修法建议：`emit > T` 后**先**对 `$S_A` 也做 `mkdir -p "$(dirname "$S_A")"`，并在 `install` 失败时把 `reason=install-failed path=$S_A` 作为**第一条**判词行。

### V3（low，非 `t23`／`t24` 责任）：`inputs_fp` 的「入口＝出口」**是带时刻的读数**，现已不可复现
- `t24` 报「入口=出口 `e9f95ec005715b3a…`、覆盖面 `226/226` 零位移」；**我现取 `8c4ce894d04eae7b…`**（覆盖面仍 `226`）。
- **逐件归因（我自己做的）**：工作树里被改的件中**只有** `build/MilBridge/tools/pkg-src-retiredpath-check.sh` 是 `in-list=1`（其余全 `0`）⇒ **100% 的位移由它引起**，而它是**第三方（`t25`）在 `t24` 之后**动的手（`numstat 34/1`、`worktree≠HEAD`、`~/w281-scribe/bak/pkg-src-retiredpath-check.sh.pre-t25` 在位）。
- 建议：今后写「零位移」时必须写成「**入口/出口 ＋ 读取时刻 ＋ 覆盖面件数**」，并注明「任何第三方改动覆盖面内任一件都会推翻本读数」。

---

## §4 边界与 `NOINFO`（逐条具名）

| # | 事项 | 判 | 具名原因 |
|---|---|---|---|
| N1 | `t21`（原 W3 整批）的判词 | **不适用** | 该任务已 `failed`、**零写入**；本件按队长裁定**只复核 `t23`＋`t24`**。 |
| N2 | `B-2` 的机制读数（冻后 `--prev-check-only` 假红） | **`NOINFO(未跑：不在本件边界)`** | 跑它需要**冻结点上的整波链**语义（属 W4），本件不跑门禁/整波 ⇒ 我只判「登记形态与内容」（成本＋下一步＋如实标未闭）成立。 |
| N3 | `t24` 的 `inputs_fp` 「入口＝出口 零位移」 | **`NOINFO(第三方已改覆盖面内件 ⇒ 该时刻指纹不可回溯)`** | 见 §3-V3；替代路 = **逐件归因**（只有 `pkg-src-retiredpath-check.sh` 是 `in-list=1` 的脏件）＋ 覆盖面 `226` 仍成立。 |
| N4 | `B-6` 的机制读数（`FILES` 累积语义会重复计数） | **`NOINFO(未跑整波)`** | 复现它要连跑整波两次；本件边界不许跑整波 ⇒ 只判登记形态成立。 |
| N5 | `t25`／`t7`／W2 的并发写者各自**写域归属** | **`NOINFO`** | 我只按 `git log`／`numstat`／备份件名归因，未逐件核它们的契约；本件只需判「**不计入 `t23`／`t24`**」，该点成立 ✓。 |
| N6 | 未跑门禁/构建/整波/应用/显示位 | **未做（边界明写）** | 本件全在只读件与我自己的车道沙箱上完成（**唯一"写"是我的沙箱哨兵副本与报告件**）。 |
| N7 | `C-1` 关账句里「本轮现取 `:818`」 | 已核（非 `NOINFO`） | 我现取 `sed -n '818p'` ⇒ 该行**逐字含**「哨兵的键序／字节格式无规范」✓（全件 `grep -n '哨兵的键序'` ⇒ `818 830`）。 |

---

## §5 我的自伤与更正（如实记）

1. **进程面自查第一版是"自匹配"**：我用 `ps -eo args | grep -cE 'close-wave|verify-all'` 得 **`3`** —— 后来发现那 3 行里**包含我自己的 `bash -c` 命令行**（模式字面出现在我自己的参数里）⇒ 典型 **`D-G103` 同族自匹配**。**当场改法**：`ps -eo pid,ppid,args` 落盘 + `awk` **排除 `$$`／`$PPID`／`awk`／`grep`** ⇒ **净命中 `0`** ✓。（若不改，我会把"我自己"读成"整波在跑"。）
2. **沙箱写路首轮失败是我没建父目录**：`WPW_S1=$L/sb/flagA` 而 `$L/sb` 不存在 ⇒ `install` 失败、`WPW=FAIL`。**该失败反过来成了 §3-V2 的发现**（部分写 ＋ reason 未点名真因）；我随后 `mkdir -p` 重跑拿到 **`WPW=PASS` ＋ 三方 `cmp` 全等**。
3. **行号引用纪律**：本件引 `:818`／`:830`／`:344`／`:346`／`:347`／`:348`／`§15ag:834/836`／`sentinel-spec-check.sh:21`／`close-wave.sh:70` **均先 `sed -n` 打过原文**。

---

## §6 收尾

- `$N` 内我**只写本件**；被判件（`wave-push.sh`／`sentinel-spec-check.sh`／`close-wave.sh`／`HANDOFF-NEXT.md`／`ROUTES.md`／两枚生产哨兵）**一字未动**（两枚哨兵 `mtime` 仍 `13:48:27.398116209`；`close-wave.sh` `mtime 10:21:57`）。
- 所有沙箱与夹具在 `~/wv86y/`（**不落 `/tmp`**，唯一例外是**只读**读生产哨兵）；未跑门禁/构建/整波/应用/显示位；未 `git add/commit/push`（暂存区 `0`）。
- ⏪ **追加（本件落盘之后 `16:23:4x` 现取，只补不删）**：① 契约 `Verify` 三条原样现跑 ⇒ `wc -l` ＝ **`232`**｜`sha256sum | cut -c1-16` ＝ **`038da825bb36be83`**｜`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **`IDENTICAL`**、`wc -l` ＝ **`13`**（逐键：`SHA FP PC PF WB WIN32SHIM HBTL WIC PROVIDER DWF WAVE BASELINE BASELINE_SHA16`）｜`infp.sh fp` ⇒ **`8c4ce894d04eae7b…`**（动因见 §3-V3，**逐件归因已完成**）。
- ⏪ **追加（同上）②**：`porcelain` 现为 **`2`** 行 —— `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）＋ `?? build/MilBridge/P1-w3-verify.md`（**本件**）⇒ 期间 `t25` 的脏件已提交 ⇒ **`t23`／`t24` 名下仍零脏件**。
- ⏪ **追加（同上）③**：本件名 **不匹配** `*report*.md` 语料（`case` 现取 ＝ `no`）⇒ 本件不扰动 `REPORTID` 的 `files`/`ids`。

- **判词尾行**：`P1-W3-VERIFY: movein=[dryrun 13 lines cmp IDENTICAL x2 sha16 6cb3f97388c3c4dc; sandbox write WPW=PASS 3way IDENTICAL; push-semantics 0; original kept 5015004b0f0d917e; authority=in-repo] spec=[13 lines 13 keys fixed order ok; pol A FAIL+ctrl PASS / B FAIL empty=8 / C none ALLOWED+PASS / D NOINFO rc2 / L14 FAIL / CR FAIL / selftest 4/4 stderr 0] closewave=[sha16 f9a2ee3ee35baff8 unchanged 0 commits; coverage 226; new files in-list 0; no-full-wave proof x4] fp=[e9f95ec0 -> 8c4ce894 attributed to t25 pkg-src-retiredpath-check.sh in-list=1] B2/B6=registered-open B13=pinned B14=closed teeth=[DEFREG PASS 217/217 drift0, REPORTID PASS 197/2053/217] scope=[t23/t24 dirty=0] overturned=none V1=low V2=low V3=low NOINFO=7`
**自报 sha16**（口径：**本行之前的全文**，即 `head -n -1 <本件> | sha256sum`）＝ `20e62b9ebcd48057` ／ FULL `20e62b9ebcd4805741d94a99fa67dc9601bf2a7e2e1d12e837bc366e363678f7` ／ `wc -l` ＝ 235 行（**不含**本行）／末次读取时刻 `2026-09-28T16:23:5x+08:00`／写入方式 **temp ＋ rename**。
