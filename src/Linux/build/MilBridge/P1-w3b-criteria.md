# P1-W3b 判据（先写 · `t24` · 搬仓批：**仓内哨兵写入端**）

> 本件**写在任何落仓之前**（判据先于证据）。判据项只许收紧，不许就结果回调。
> 工作根 `$N=/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）。引行号**仅本次有效**，判据一律**内容锚**。
> 纪律：**只增不改**（原文一字不删，更正一律 `⏪` 起头 dated 追加）；写前 `stat -c %h`（须 ==1）→ `cp -p` 备份 → `temp + rename`；报数一律**现算**。

## 0 · 本件要解决的问题（`B-14`）

仓外仪器 `~/w79c/bin/w79-push.sh`（sha16 **`5015004b0f0d917e`**）在尾部 `install -m 644` 两行写出哨兵。
现取 `grep -rln 'BASELINE_SHA16' --include='*.sh' --include='*.py' .` ⇒ **0 命中**：
即哨兵**在仓内既无写者也无读者**，清一次车道目录即成孤儿。本件只搬**「写哨兵那一小段」**进仓，**不搬推送逻辑**。

## 1 · 判据项（逐条现算，`NOINFO` 既不算绿也不算红）

| # | 判据 | 取法（现算） |
|---|---|---|
| **C-1** | 仓内**新增** `build/MilBridge/tools/wave-push.sh`，且**只含哨兵写入 slice** | `test -f`；`grep -c` 该件**不得**出现推送语义（`git push`／`git commit`／`git add`）；`bash -n` 语法绿 |
| **C-2** | **键序／字节**遵 `HANDOFF-NEXT.md` dated 哨兵规范：13 行／13 键固定序、行尾单 `\n`、无 CR、无空行 | `bash wave-push.sh --dry-run` 输出：`wc -l`==13、键序 `cut -d= -f1` 逐位等于 13 键序、`file`/`od` 查 CR |
| **C-3** | **取值口径**：九键走 `NINE_PATHS`（`CFG=Release`）、`provider` **走工程产出目录**、`FP` **= `BRIDGE_SRC_FP`（≠ `inputs_fp`）**、`WAVE/BASELINE/BASELINE_SHA16` ⇔ `docs/CURRENT-STATE.md:9` | 逐键与**权威路径现值**比对（本趟现算）；`FP` 与 `infp.sh fp` 的 `inputs_fp` **必须不等**（不等才证明口径没串） |
| **C-4** | **搬仓等价**：同一趟内**逐件可比** | ① `--dry-run` 的 13 行 vs **现存两枚哨兵**逐行 `diff`（期望 0 差）② `cmp /tmp/bridge-frozen.flag $HOME/wfp-runs/bridge-frozen.flag` ⇒ `IDENTICAL` ③ 「件数 13」逐键有值（无 `none(`） |
| **C-5** | **权威归属声明**：仓外原件**保留不删**，权威路径写清 | 仓外 `~/w79c/bin/w79-push.sh` 现取 sha16 **必须仍是 `5015004b0f0d917e`／字节不变**（未被我动过）；本件报告点名「谁是权威、谁是留档」 |
| **C-6** | **未闭项只登记**（`B-2` 冻后 `--prev-check-only` 假红／`B-6` `FILES` 累积语义）＋**口径面**（`B-13`：哨兵 `FP` = `BRIDGE_SRC_FP` ≠ `inputs_fp`）入册 | `HANDOFF-NEXT.md` dated 追加块内 `grep -c` 三键名各≥1；`docs/ROUTES.md` 同趟追加 1 行路由（只增不改） |
| **C-7** | **指纹归因**：`bash ~/w153a/bin/infp.sh fp` 与 `infp.sh list \| wc -l` 两趟（入口／出口）现算；若 `fp_inputs()` 输入集有变 ⇒ **逐件归因** | 两趟 `inputs_fp` ＋ coverage 数在报告内列出；`build/close-wave.sh` sha16 两趟相同（**本趟未改**，理由见报告） |

## 2 · 本件**不做**（越域即停手报队长）

- **不**跑整波链（`close-wave.sh` 全跑／`verify-all.sh` 门禁长跑）；`dotnet`／构建／应用／显示位**一律不碰**。
- **不**接线（`fp_inputs()` 加新齿、`[42] --expect 226→227`、step 55→56 归 **W4**）。
- **不**动 `verify-all.sh`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`build/MilBridge/tools/{defect-registry-check,sentinel-spec-check,pkg-src-retiredpath-check}.sh`／`build/MilBridge/P1-tail-scout.md`／`build/MilBridge/tests/**`／`src/**`。
- **不** `git add`／`git commit`／`git push`；进程只按 PID 收。
- `build/MilBridge/tools/retired-path-provenance.tsv` **不存在**（真件在 `build/MilBridge/retired-path-provenance.tsv`）⇒ 契约给的路径**越域**，不动、登记。
