# 任务：结构上游化 · **第 6 轮** —— 先"成对取证"定位**全黑**，修掉它 ＋ 4 条机械红，冲 D2

> 起点：detached **`0eaf3aeec`**（迁移态；落点已是最终形态；`verify-all` = 58✅/8❌，875 用例 0 失败）。
> 先读：`.agents/tasks/TASK-合并波.md`（纪律/落点/D1-D3/回退）＋ `TASK-合并波-R4.md`（上一轮范围与残余清单）。

---

## ① **本轮第一件事：成对取证（不许先改代码）**

**目标**：把"窗口全黑"从症状变成 `文件:行`。

**已知成对事实（主控亲测）**：
- 迁移态 `bash src/Linux/samples/ThirdPartyMini/run-thirdparty-mini.sh 20` ⇒ `THIRDPARTY=FAIL frames=35 **max_colors=1** min_colors=800`，
  且 `THIRDPARTY_DEPLOY=wpfgfx_cor3.so OK **2bdc9ab2ebb4ebe2**`（基线该件是 `7152f9ac119e1bb0`）。
- **基线**（`07a0099d2`）同一条命令 ⇒ `THIRDPARTY=**PASS** max_colors=**1642**`。
- 应用**能启动、能跑托管代码**（`app.log` 里 `THIRDPARTY_IMAGE=PASS 96x96 Bgra32`），只是**画面一色**。

**取证步骤（逐条留原始输出）**：
0. **二分定位"第一坏提交"**（先做这个，最快收敛）：
   ```bash
   git log --oneline 07a0099d2..0eaf3aeec     # 迁移链：ab0f56aad → … → 56faf9561 → e1db565c3 → 0eaf3aeec
   # 逐个 checkout，每次按需重建后只取一行判据：THIRDPARTY=(PASS|FAIL) max_colors=<n>
   #   注意口径：若为省时只重跑样本而不重建，必须在报告里写明（否则读数是混合态的）
   ```
   把"第一次变黑的那笔"钉死，并列出该笔里**与运行期解析有关**的改动（重点：
   `src/Linux/build/MilBridge/src/MilBridge.Resolver/**`、`MilCoreDllImportResolver.cs`、`Win32ShimResolver`、应用侧依赖表、
   `.so` 的 AOT 输入、`deps.json` 生成处）。
1. 在**迁移态**（当前 HEAD）跑一次并**完整保存**：`app.log`、app 目录逐件清单＋sha16、`/proc/<pid>/maps` 里加载的 `.so/dll` 清单、`xwininfo` 的窗口几何/标题。
2. `git checkout 07a0099d2`（基线；**先 `git status` 确认工作区干净**），同样跑一次、同样保存（这次应是 PASS/1642）。
3. **逐件 diff 两组**：① app 目录文件集合与哈希；② `maps` 里加载的原生库；③ 逐行 log diff。
4. 回到迁移态：`git checkout 0eaf3aeec`。
5. 输出一张**成对表**：`项 | 基线 | 迁移 | 差在哪 | 指向`。

**优先怀疑（按可能性排序，逐条给出证实/证伪）**：
- **A. AOT 桥的运行期解析**：`wpfgfx_cor3.so` 重建后字节变了（正常），但它是"渲染核心"；查托管侧找它的路径（`MilNative` / DllImport / `runtimes/<rid>/native` 一档）是否随落点加深而指错——
  本仓历史上有过"靠陈旧 `.so` 才绿、全量重建后暴露"的先例（见 `README` 的 `R-GATE` 记述）。
- **B. 主题/资源 BAML**：自产 `PresentationFramework` 的 theme BAML 是否仍被解析到（控件画不出来但窗口在）。
- **C. app-local 同步集**：`sync-applocal.sh` / `applocal-expect.py` 的期望集合是否随落点漂移（缺件可能**静默**不绘制）。
- **D. 字体**：`PRODUCT-ENTRY` 报"文件式 `FontFamily` 未解析到仓内件"（`build/fonts` → 应为 `src/Linux/build/fonts`）。

> 判据口径：**每一步都要"基线 vs 迁移"两个读数**；只有一边的读数不许下结论。

## ② 修（只改路径/接线；**不许改产品逻辑**）

按 ①的结论定点修。可行手段包括：把运行期解析的"相对基准"按新深度重算、把硬编码路径改指新落点、把 app-local 期望集重发、
把字体/资源目录登记到正确位置。**每一处都要"改前/改后"成对读数**（`max_colors` 是最外层判据，但必须说明**为什么**它变了）。

## ③ 4 条"机械红"收口（`COLUMN-FLOOR`／`SENTINEL-SPEC`／`HANDOFF-MV`／`STATIC-JAWS` 残余）

按 `TASK-合并波-R4.md` §⑤ 给的收口法逐条做：
- 重冻（**只碰声明面**）：`ACCEPTANCE-BASELINE.md` 追加新 `# RE-FROZEN #NN` 并把 5 条 `# ARM-LOG-SHA` 钉到 `known-red.json` 现值
  → `docs/CURRENT-STATE.md:9` 换新 `gen`/`sha16` → 仓外 `~/w153a/bin/infp.sh` 的 `CW=` 改 `$R/src/Linux/build/close-wave.sh`
  → `wave-push.sh`（带写）重发两枚哨兵并 `cmp` 自证 → `docs/ROUTES.md §8` dated 追加；
- `R-GATE`：补 `POS lstitem1` 的来源件（`reason=pos-missing`）；
- ⚠️ **顺手修一处在册隐患**（R4 发现）：`static-jaws-check.sh` 裸跑 `wave-push.sh`（默认**写盘**）会把两枚哨兵重写成现读数，
  与该牙"只读读者"口径不符 ⇒ 让它以只读方式调用（或在牙里声明该副效应并加反极性）。**改它要跑它的自检**。

## ④ 通了之后：收口（照 `TASK-合并波.md` §③）

D1 → **一笔**提交 → 重冻核对 → **D2（`bash Guide.Linux/verify-all.sh` ×2 各 0 ❌）** → **才**前进 `feat-Linux`
（`git checkout feat-Linux && git merge --ff-only <提交>`，或 `git branch -f`）→ 自证 `UPSTREAM-MANIFEST.tsv == 工作树` →
`git rm -r upstream` ＋ 提交 ＋ 再跑一趟确认不新增红。

## ⑤ 边界 / 硬停

- 边界照 `TASK-合并波.md` §④；本轮额外**只许动**①的结论所指的件 ＋ ③点名的件。
- **禁止**削弱判据凑绿（改 `--expect`／加豁免／关开关／把 `NOINFO` 当绿）。`max_colors=1` **不是**可以登记的"具名红"——它是**功能回归**。
- **硬停**：① 的四种怀疑各证伪/证不实到 2～3 种仍不能解释全黑 ⇒ **停手**，输出成对表 ＋ 结论 ＋ 推荐；**不前进 `feat-Linux`、不删 `upstream/`**。

## ⑥ 报告

- ①的**成对表**（原始读数，不许转述）。
- ②每处改动：文件、改前/改后、`max_colors` 成对读数。
- ③的成对读数（重冻前/后）。
- `verify-all` **逐趟**步骤通过/失败数（贴原始行）；九位/`inputs_fp`/基线前后值。
- 结论：**D2 达成**（并列出 `feat-Linux` 新位置、`upstream/` 是否已删）或 **未达 ＋ 具名残余 ＋ 推荐**。
