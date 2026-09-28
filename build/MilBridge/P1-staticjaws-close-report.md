# P1-staticjaws-close 报告（`t65`）—— `t62` 收口：三格 dated 追写 ＋ 第 `28` 条（维护契约升格）＋ 自指手法 ＋ 成本旁注

**本件口径（写死）**：**只增不改**（本件新建；`HANDOFF-NEXT.md` 的原有文字**一字未删**，全部以 dated 更正行追写）；读数一律**捕获式取 `rc`**（`cmd >out 2>err; echo $?`，**不接管道** —— 会话第 `27` 条）；每格带**亚秒 `ts=`**；`NOINFO` 具名（§6）。**不含任何代码改动**（本趟只动 2 件：`HANDOFF-NEXT.md` ＋ 本件）。

## 0. 一句话
`t62` 唯一未达的那条验收已补齐：把 `HANDOFF-MV` 的 `cell=#1`／`#2`／`#5` 三格**同趟 dated 追写**进 `build/MilBridge/HANDOFF-NEXT.md` ⇒ **`[HANDOFF-MV]` 由 `rc=1`／`DIVERGED mismatch=3` 回 `rc=0`／`PASS cells=9 equal=8 manual=1 mismatch=0`**；随之 **`static-jaws-check.sh` 正极由 `FAIL fails=1` 回 `PASS n=31 excluded=31 noinfo=1`**。同趟把这条维护契约**升格为第 `28` 条**（含**不自指**的条在位自检命令、两个实例具名、以及 `static-jaws-check.sh` **单趟 ≈41.1 s** 的成本旁注）。

## 1. 写域（**2 件**）与写入前后成对读数
| 件 | 写前 `sha16`／行 | 写后 `sha16`／行 | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|
| `build/MilBridge/HANDOFF-NEXT.md` | `41ea67b3323295da`／`560` | **`0dd39973e560f1ed`／`575`** | `644` | `100644` |
| `build/MilBridge/P1-staticjaws-close-report.md`（本件，新建） | — | 见末行自证 | `644` | 未入索引 |

- **写前**（`ts=2026-09-28T19:31:33.586+0800`）：`hl=1`／`wt=644`／`idx=100644`／`560` 行／`41ea67b3323295da`（与 `t62` 交件里记的写前值**逐位相同** ⇒ `t62` 确实**没动过**该件）。写前未新建备份（本件为**纯追加**，且写前值已在上句与 `t62` 两处留痕）；落盘用 `cat >>`（**追加**，不重写文件 ⇒ 模式与权限不动）。
- **模式守恒自证（两口径成对）**：`HANDOFF-NEXT.md` 写前写后均 `644`／`100644`（**逐位相同**）；本件新建 `644`／未入索引。**本趟零模式位移。**
- **三格成对（过时值 → 现值；同一趟现取）**：
  - `cell=#1`（覆盖面内件指纹）：`3984df956342e2757464d40a18e6621acee5fa764463f17fee7209ad7653478e` → **`fe923e2ece0115374a39dde202f317e1f0743f156ab86c238b2d8c22b8d56897`**（命令 `bash ~/w153a/bin/infp.sh fp`；`rc=0`；`ts=2026-09-28T19:31:33.586+0800`）
  - `cell=#2`（覆盖面件数）：`233` → **`234`**（命令 `bash ~/w153a/bin/infp.sh list | wc -l`）
  - `cell=#5`（门禁步数）：`61` → **`62`**（命令 `grep -c '^run_step "' verify-all.sh`）
- **`§9` 逐字沿用**：三条更正行的文本照 `t62` 载体 `build/MilBridge/P1-staticjaws-report.md` §9（仅把 `ts` 换成本趟亚秒值、`fp` 换成现取值）。

## 2. 第 `28` 条（本趟入册的内容）
- **编号现取**：本区编号块最后一条 ＝ **第 `27` 条**（`t60` 落，内容锚「dated 修法账 ＋ 纪律追加 · 第 `27` 条」，块头现取 `:528`，仅本次有效）⇒ 本条 ＝ **第 `28` 条**。
- **口径句（逐字，已在册）**：**「凡改动覆盖面内任一件、或改动覆盖面件数/门禁步数 ⇒ 必须同趟追写 `HANDOFF-MV` 的 `cell=#1`／`#2`／`#5` 更正行；否则下一次整趟门禁的 `[HANDOFF-MV]` 步必红。」**
- **条在位自检命令（可重跑；`rc` 捕获式取；命令字面不自指）**：`grep -c '否则下一次整趟门禁[的]' build/MilBridge/HANDOFF-NEXT.md` ⇒ **现取 `rc=0`／`n=1`**（`ts=2026-09-28T19:32:06.542+0800`）。
- **自指手法（附带口径；本会话第 `3` 次同类）**：**条在位自检命令必须不自指** —— 「命令字面与判据正则不得互相命中」。首版把受检串原样写进命令 ⇒ **命令字面自身命中**（现取 `n=2` ＝ 口径句 `1` ＋ 命令 `1`）⇒ 改**字符类** `[的]`（命令字面含 `[的]`、正则只匹配裸 `的`）⇒ **命中恰 `1`**。同族先例：第 `27` 条首版自检命令（`t60` 同趟 dated 更正）／第 `24` 条那一族。（本条已按队长要求**写进第 `28` 条块**。）
- **实例①（本次 `t62`）**：改了两个覆盖面内件（`verify-all.sh`／`build/close-wave.sh`）＋ 覆盖面 `233 → 234` ＋ 步数 `61 → 62` ⇒ 三格同趟过时；`[HANDOFF-MV]` 修前 `rc=1`／`DIVERGED mismatch=3`（逐格 `in-repo=3984df95… / 233 / 61` vs `live=fe923e2e… / 234 / 62`）。该契约原**只写在牙头** ⇒ 派单与写者都看不见；写者按铁律**不越域**、改为报队长 ＋ 在仓外副本上先证明补救能回 `PASS`。⇒ 口径句后半句＝**把代价写进册**。同类疏漏**第二次**（`t54`／`t57` 亦漏交件载体 ⇒ 平台拒收 `changedPaths`）。
- **实例②（此前那一态，结构性的）**：本件**九格表「现取值」列**是**手抄现跑** ⇒ `t48` 块逐字「**9 格表**是**手抄现跑**、此后**每代必陈旧**，而**仓内零读者**」＝**立牙的动因**（`B-11`）；自 `t48` 起该列**转为留档**（口径句①：判据面在**更正行**，逐格 `table=`／`corrected=`／`live=` 三值都上屏）⇒ **表列陈旧不再是红，但更正行陈旧仍是红** ⇒ 第 `28` 条治的正是后者。
- **成本旁注（`t62` 实测）**：`static-jaws-check.sh` **单趟 ≈ `41.1 s`**（`31` 颗牙；最慢 `PRODUCT-ENTRY` `13.9 s`、`WIRING-CLOSURE` `5.7 s`；`SJC_TIMEOUT` 默认 `40 s`）。

## 3. 两条成对读数（**原样输出**）
**`[HANDOFF-MV]`（捕获式）**
```
# 修前 ts=2026-09-28T19:31:33.586+0800   rc=1   stderr=0 行
HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=5 manual=1 mismatch=3 uncomparable=0 reasons=,#1:covered-file-changed-since-ts,#2:count-changed-since-ts,#5:count-changed-since-ts
HANDOFF_MV_HIT cell=#1 anchor=§7-4 输入指纹 rule=cell-mismatch reason=covered-file-changed-since-ts in-repo=3984df956342e2757464d40a18e6621acee5fa764463f17fee7209ad7653478e live=fe923e2ece0115374a39dde202f317e1f0743f156ab86c238b2d8c22b8d56897
HANDOFF_MV_HIT cell=#2 anchor=§7-4 覆盖面件数 rule=cell-mismatch reason=count-changed-since-ts in-repo=233 live=234 cmd=bash ~/w153a/bin/infp.sh list | wc -l
HANDOFF_MV_HIT cell=#5 anchor=§7-5 步数 rule=cell-mismatch reason=count-changed-since-ts in-repo=61 live=62 cmd=grep -c '^run_step "' verify-all.sh
# 修后 ts=2026-09-28T19:32:06.542+0800   rc=0   stderr=0 行
HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
```
**`static-jaws-check.sh` 正极（捕获式）**
```
# 修前（t62 现取，ts=2026-09-28T19:26:31.917+0800）  rc=1
STATICJAWS=FAIL fails=1 n=31 excluded=31 noinfo=1 n_total=62
STATICJAWS_HIT step=HANDOFF-MV jaw=…/build/MilBridge/tools/handoff-machine-values-check.sh rc=1 stderr=0行 ms=3806
# 修后（本趟现取，ts=2026-09-28T19:32:03.174+0800）  rc=0   stderr=0 行
STATICJAWS=PASS n=31 excluded=31 noinfo=1 n_total=62
STATICJAWS_SCOPE 射程＝已接线的裸静态牙；构建/显示位/腿批/带参步**不在射程内**（见上面 STATICJAWS_EXCLUDED 逐条）⇒ 本牙绿**不等于**整趟门禁绿（NOINFO）
STATICJAWS_NOINFO step=FrameProbe-frame … reason=rc2-rc-noinfo-convention rc=2（**不算红**）
```
⇒ **唯一那颗红（`HANDOFF-MV`）消失**，`0` 行 `STATICJAWS_HIT`。

## 4. 不变量与红线（现取，`ts=2026-09-28T19:32:06.542+0800`，`HEAD=e37f771`）
`^run_step "` ＝ **`62`**｜覆盖面 ＝ **`234`**｜首行 `DECL` ＝ **`62 gen=#81`**｜`--expect` ＝ **`234`** ⇒ **四条不变量未变**｜两枚哨兵 `cmp` **`rc=0`（IDENTICAL）**、各 `6cb3f97388c3c4dc`（**未写**）｜**未跑整趟门禁**｜未 `git add`／`commit`／`push`。
**未越域自证（写域外各件与本趟前逐位相同，`sha16` 现取）**：`verify-all.sh` **`63b767b894e4292d`**／`1326` 行｜`build/close-wave.sh` **`bce5c297692f6a0e`**／`721` 行｜`build/MilBridge/tools/static-jaws-check.sh` **`ff4a85ae5ee1d59e`**／`stat -c %a` ＝ `644`｜`docs/WAVE81-PREREGISTRATION.md` **`a622e86f32d0412f`**／`41` 行｜`src/**`、`docs/ROUTES.md`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`build/MilBridge/tools/defect-registry-declared.tsv`、两枚哨兵**一字未动**。
`porcelain` 现取：`M build/MilBridge/HANDOFF-NEXT.md`（本趟）＋ `M build/close-wave.sh`／`M docs/WAVE81-PREREGISTRATION.md`／`M verify-all.sh`（`t62` 那三件，**本趟未动**）＋ `?? build/MilBridge/P1-staticjaws-report.md`／`?? build/MilBridge/tools/static-jaws-check.sh`（`t62` 新建）＋ `?? build/MilBridge/P1-task0201-criteria.md`／`?? build/MilBridge/P1-task0201-recheck-report.md`（**别的车道**，未读未改）。

## 5. 自伤与当场更正（如实记，零损伤）
1. **条在位自检命令首版自指**（`t65` 预验证时当场发现）：首版 `grep -c '否则下一次整趟门禁的' …` ⇒ **命令字面自身命中** ⇒ 现取 `n=2`（口径句 `1` ＋ 命令 `1`）。**改成字符类** `[的]` ⇒ `n=1`；**改名前后各复跑一次**（本趟现取见 §2／§3）。⇒ 该手法已按队长要求写进第 `28` 条块。
2. **预验证用的仓外副本**（`/tmp/hn28.md` 两次）与本趟的 `/tmp/t65-block.md` **均已删**（`temp_removed=YES`）；仓内零夹具残留；`HANDOFF-NEXT.md` 用 `cat >>` **追加**（未重写文件 ⇒ 模式不动）。

## 6. `NOINFO`（具名，既不算绿也不算红）
1. **未跑整趟门禁**（会构建 ⇒ `provider` 位位移，`B-18` 在册）⇒ **端到端绿未验**；本趟只跑该两牙 ＋ 四条不变量 ＋ 哨兵。
2. **实例②「当时」的手抄值本席未见**（九格表列自 `t48` 起为留档、原文未存）⇒ 只引 `t48` 块**逐字自述**，**不声称**复核过那些手抄值。
3. `static-jaws-check.sh` 射程外的 **`31` 步**（构建／显示位／腿批／带参）本趟**未跑**（其 `STATICJAWS_SCOPE` 句每次上屏）。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-staticjaws-close-report.md | sha256sum | cut -c1-16`）**：`71f0d445417c3a0b`（**整件全文 `sha256` 只在交件消息里给**，第 `24` 条）。
