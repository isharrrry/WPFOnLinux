# P1-W3b 报告 · 搬仓批（仓内哨兵写入端）

- 任务 `t24`（W3b）；写者 `scribe`；分支 `feat-Linux`；入口 HEAD **`1a04da6`**。所有数字**现算**，无引用上一代列印、无转述他人结论。
- 判据先写在 `build/MilBridge/P1-w3b-criteria.md`（sha16 **`20d7d612e332fa7b`**，31 行），**写于任何落仓之前**。
- 纪律：写前 `stat -c %h` 三件全 `==1`；`cp -p` 备份 `~/w281-scribe/bak/{HANDOFF-NEXT.md,ROUTES.md,declared.tsv}.pre-t24` 取在**任何写之前**；落仓一律 `temp + rename`；**只增不改**（两处追加件的**原文前缀逐字节 `cmp` 相同**，见下）。

## 1 · 落仓清单（本趟**

| 件 | 态 | sha16 | 变更 |
|---|---|---|---|
| `build/MilBridge/tools/wave-push.sh` | **新建** | **`b1a167146f9dcb35`** | 85 行 / 5572 B / mode 755；`bash -n` **SYNTAX-OK**；`grep -cE 'git (push\|add\|commit)'` = **0**（**只搬哨兵写入 slice，不搬推送逻辑**） |
| `build/MilBridge/P1-w3b-criteria.md` | **新建** | **`20d7d612e332fa7b`** | 3933 B |
| `build/MilBridge/HANDOFF-NEXT.md` | 追加 | `9099414a189fdcd2` → **`e94775200994e1dc`** | 338 → 350 行（**+12**）；`git diff --numstat` = **`12 0`**（非空 ⇒ 非空转假绿）；原文前缀 `cmp` = **YES** |
| `docs/ROUTES.md` | 追加 | `1e86b6f577ce9e14` → **`26841d6ed6fe8085`** | 830 → 838 行（**+8**）；`numstat` = **`8 0`**；原文前缀 `cmp` = **YES** |

## 2 · 判据逐条（`NOINFO` 一律点名，既不算绿也不算红）

- **C-1（件形）绿** — 新件存在、`bash -n` 绿、推送语义命中 **0**。
- **C-2（键序／字节）绿** — `--dry-run`：`lines=13`；键序 `SHA,FP,PC,PF,WB,WIN32SHIM,HBTL,WIC,PROVIDER,DWF,WAVE,BASELINE,BASELINE_SHA16`（与 `HANDOFF-NEXT.md` dated 规范 13 键序**逐位相同**）；`CR命中=0`；`空值=0`；`none(` 命中 **0**；stderr `WPW=DRYRUN lines=13 keys=13`。
- **C-3（取值口径）绿** — 九键**逐键与权威路径现值相等**：`SHA 4e25e4b27d4d5ae1`／`PC 5b6cfda3e12b84fc`／`PF b9a4f3a0e48e688d`／`WB 9e860cbeecb352e1`／`PROVIDER 24e4e0a731dbed40`（**工程产出目录**，非副本）／`WIN32SHIM 6825dd7071387a46`／`WIC f7b3026c8c019be2`／`HBTL 921ba9c65e9fb3be`／`DWF c83be96f18759edc`；`CFG=Release`。`FP d697b1e10ff48881` == `bridge-src-fp.sh` ⇒ **`BRIDGE_SRC_FP` 口径**；与 `inputs_fp`（`e9f95ec0…`）**不等** ⇒ **口径未串（`B-13`）**。`WAVE=w80-freeze`／`BASELINE=#80`／`BASELINE_SHA16=b96d4312565a3c49` ⇔ `docs/CURRENT-STATE.md:9` 现值 `gen=#80 sha16=b96d4312565a3c49`。
- **C-4（搬仓等价 · 同一趟逐件可比）绿** — `--dry-run` 13 行 vs 两枚**现存**哨兵**逐行 `diff` = IDENTICAL**（`/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag`，各 13 行、各 sha16 `6cb3f97388c3c4dc`）；现存两哨兵 `cmp` = **IDENTICAL**；写路（`WPW_S1/S2` 指向**沙箱**）产出后**三方 `cmp` = THREE-WAY-IDENTICAL**（沙箱产物 sha16 亦 `6cb3f97388c3c4dc`）。**同一趟刻意只写沙箱路径 ⇒ 生产哨兵零改动**（`--write` 的生产写路未在本趟触发，代价：写路的落盘权限／目录创建仅在沙箱证过，真写留 W4 首跑）。
- **C-5（权威归属）绿** — 仓外原件**保留不删**：`~/w79c/bin/w79-push.sh` 现取 sha16 **`5015004b0f0d917e`**、**23251 B**，与入口读数逐字相同。**权威 = 仓内 `build/MilBridge/tools/wave-push.sh`**（口径基准）；仓外件**降为留档**（在册、不再作口径来源）。**齿名订正**：`P1-tail-scout.md` §4 曾拟 `tools/bridge-flag-write.sh`，本件按任务契约落 **`wave-push.sh`**，已在 HANDOFF 内 `⏪` 钉死。
- **C-6（未闭项只登记 ＋ 口径钉死）绿** — `HANDOFF-NEXT.md` t24 节内 `B-14`／`B-13`／`B-2`／`B-6` 各命中 **1**；`docs/ROUTES.md` 同趟追加 `§15ag` 路由 1 节（只增不改）。`B-2`／`B-6` **只登记不实现**（成本／下一步已入册）。
- **C-7（指纹归因）绿** — 见 §3。

## 3 · 指纹面（入口／出口两趟现算）

- `inputs_fp`：入口 `e9f95ec005715b3a7bff1a7bca4b525fafad98068e7a389ad8b9b91b8a9dc5a3`；出口 **完全相同**。
- 覆盖率：入口 **226** / 出口 **226**（`infp.sh list | wc -l`）。
- `build/close-wave.sh` sha16：入口 `f9a2ee3ee35baff8` / 出口 **相同** ⇒ **本趟未改 `close-wave.sh`**，**零指纹位移**。
- **逐件归因（现算，不是推论）**：`infp.sh list` 内 `wave-push.sh` **in-list=0**、`P1-w3b-criteria.md` **0**、`HANDOFF-NEXT.md` **0**、`ROUTES.md` **0**；对照在册件 `defect-registry-check.sh` **1**、`close-wave.sh` **1**、而 `sentinel-spec-check.sh` **0**。即：`fp_inputs()`（`build/close-wave.sh:70` 起，内容锚）是**显式列举**、**非 glob**，新件**不在输入集**⇒ `inputs_fp` 不动的**原因是机械可查的**，不是空转。**同理在册**：`t23` 的 `sentinel-spec-check.sh` 亦 `in-list=0` ⇒ **W4 接线须同趟把这两枚齿加进 `fp_inputs()`**，并同趟给出 `[42] --expect 226→227`、step `55→56` 的四处声明。
- **未触发**：判据 C-7 的「若 `fp_inputs()` 输入集有变 ⇒ 逐件归因」条件本趟**不成立**（上列 in-list 全 0）；若将来动 `close-wave.sh`，须**先过** `D-G130④` 两道前缀闸＋`%h==1` 才允许改，且改后必须逐件归因。

## 4 · 未闭项（只登记，含成本／下一步）

- **`B-2`** 冻结点之后单跑 `--prev-check-only` **假红** —— 判据输入取自**瞬时状态**（`D-G130` 家族），非转换缺陷。**成本**：把「上一冻结点」由瞬时状态改为**落盘不变量**（哨兵＋车道目录双读，缺一才红），并补一组双向夹具。**下一步**：下一波与 `D-G130` 同趟排。
- **`B-6`** `FILES` 为**累积语义** ⇒ 同趟重发**重复计数**、清单件数**跨趟不可比**（须按 basename 去重）。**成本**：改当趟快照会移动现有对账面，须同趟更新全部引用该数字的判据／报告并补「连跑两趟数字相同」夹具。**下一步**：与 W4 同趟排。
- **`D-G181`（家族提醒，本趟已用 `numstat` 非空自证，未空转）**：`git diff --numstat -- <path>` 空转 ⇒ 恒真假绿。

## 5 · 本件**未做**（越域即停手）

不跑整波链／`verify-all.sh` 门禁长跑；不 `dotnet`／构建／应用／显示位；不接线（W4）；不动 `verify-all.sh`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`tools/{defect-registry-check,sentinel-spec-check,pkg-src-retiredpath-check}.sh`／`P1-tail-scout.md`／`tests/**`／`src/**`；不 `git add/commit/push`；进程只按 PID 收。**`tools/retired-path-provenance.tsv` 不存在**（真件 `build/MilBridge/retired-path-provenance.tsv`）⇒ 契约给的该路径**越域**，不动、登记。**未新增 `D-G` 号** ⇒ `tools/defect-registry-declared.tsv` 无需重发（现取 `d9db8ed740145643` 不变）。

## 6 · 结论

`B-14` **写入端已闭**：仓内有了哨兵写者，且与现存生产哨兵**逐件等价**（13 键逐键 + 三方 `cmp`）。**遗留**：`B-2`／`B-6` 只登记；**接线（`fp_inputs()` ＋ `[42] --expect 227` ＋ step 56）与「生产写路首跑」归 `W4`**。

- 本件自证 sha16（口径=**末行之前的全文**）= ``fe51a1f62d016942``
