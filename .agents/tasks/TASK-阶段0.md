# 任务：WPFOnLinux 结构上游化 · 阶段 0（共同依赖 —— **单一执行体，禁并行**）

> 你**独自**完成本任务。它是后续所有阶段的地基，**不许**派子代理、**不许**并行改多块。
> 先读方案全文：`/home/links-dev/netTest/GitProj/WPFOnLinux/docs/UPSTREAM-ALIGN-PLAN.md`（重点 §2.2、§2.5、§4、§5、§6）。

---

## ① 任务目标

为"向上游靠 + win/linux 共存"的仓库重构**打地基**，产出四件东西，且**一个字节都不动被机器读取的既有件**：

1. **冻结命名约定**：全仓"`X`（原始/Windows 侧）＋ `X.Linux`（linux 侧）"成对；
   源码 `src`/`src.Linux`、脚本 `Guide`/`Guide.Linux`、文档 `docs`/`docs.Linux`。
2. **《证据件读者清点表》**：逐件列出候选移动件的**读取端**（哪个脚本/工具在读它），
   以及"移动它要改哪几处、是否要动 `inputs_fp` / `[42] --expect` / `close-wave.sh` 覆盖面"。
3. **目录骨架**：把两处文档根的**空目录**建好（带占位），供阶段 1 直接写内容。
4. **"移动 or 索引折中"二选一裁定**：对证据件给出结论 + 依据（用清点表的改动面说话）。

**为什么重要**：本仓是"判据驱动"，`docs/` 里的 `WAVE*-PREREGISTRATION.md`、`handoff.md`、`ROUTES.md`
是**被冻结机器读取**的证据件（`docs/INDEX.md §4` 明令"刻意不做大搬家"）。不先清点就搬 ⇒ 当场打红。

---

## ② 边界条款

**只允许创建**：
- `docs.Linux/` 及其子目录 `guide/`、`design/`、`upstream/`、`evidence/`（用占位文件保证 git 可见）；
- `docs/guide/`、`docs/evidence/`（占位文件）；
- `docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md`（清点表本体，下一步阶段 2 要用）；
- `docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`（命名约定冻结件）。

**禁止**（一个字节都不许动）：
- 移动 / 删除 / 改内容：任何既有 `docs/*.md`、`handoff.md`、`ROUTES.md`、`samples/**`、`tests/**`、
  `build/**`、`src/**`、`upstream/**`、`verify-all.sh`、`wpf-linux.sln`、`README*.md`。
- 改 `docs/CURRENT-STATE.md:9` 的基线声明行。
- `git commit` / `git add`（把工作区留给主控裁决）。

**尝试上限**：清点手段最多 2～3 种；仍无法判定某件的读取端 ⇒ 在表里**如实写"未见读取端（NOINFO）"**，别猜。

---

## ③ 验收标准（可计算）

| # | 判据 | 命令 / 读数 |
|---|---|---|
| A | 骨架就位 | `find docs.Linux docs/guide docs/evidence -type f \| wc -l` ≥ 5，且四个子目录存在 |
| B | 清点表存在且逐件有结论 | 表内行数 == 候选件数；每行"读取端"列**非空**（或显式 `NOINFO`） |
| C | 既有件零改动 | `cd /home/links-dev/netTest/GitProj/WPFOnLinux && git status --short` **不含**对既有 tracked 件的 ` M `（只允许 `??` 新件） |
| D | 门禁不新增红 | `bash build/MilBridge/tools/verify-all-step-check.sh` `rc=0`；`bash build/MilBridge/tools/baseline-sha-check.sh` `rc=0` |

---

## ④ 候选移动件清单（至少覆盖这些）

`docs/WAVE*-PREREGISTRATION.md`（40+ 件）、`handoff.md`、`docs/ROUTES.md`、`docs/INDEX.md`、`docs/PORT-SPEC.md`、
`docs/CURRENT-STATE.md`、`docs/ARCHITECTURE.md`、`docs/UPSTREAM-PROVENANCE.md`、`docs/history/**`、
`docs/m7c-*.png`、`docs/THIRD-PARTY-APPS.md`、`docs/unimplemented.md`、`docs/PREREG-TEMPLATE.md`、`docs/WIN-INTEROP.md`。

**清点方法（照抄）**：

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
# 对每件，按"文件名"和"仓内路径"两种口径各扫一遍
for f in docs/WAVE*.md handoff.md docs/ROUTES.md docs/INDEX.md docs/PORT-SPEC.md docs/CURRENT-STATE.md \
         docs/ARCHITECTURE.md docs/UPSTREAM-PROVENANCE.md docs/THIRD-PARTY-APPS.md docs/unimplemented.md \
         docs/PREREG-TEMPLATE.md docs/WIN-INTEROP.md; do
  b=$(basename "$f")
  echo "== $b"
  grep -rlF "$b" verify-all.sh build tests samples tools .github 2>/dev/null | grep -v '^upstream/' | sort -u
  grep -rlF "$f" verify-all.sh build tests samples tools .github 2>/dev/null | grep -v '^upstream/' | sort -u
done
# docs/history/ 与 docs/m7c-*.png 同理，用相对/绝对两种写法各扫一遍
# 另外扫 build/MilBridge/tools/*.sh 与 build/close-wave.sh、build/integration-wave.sh 的"点名清单"
```

若某件只在**其它 `docs/` 散文**里被引用（无脚本/工具读）⇒ 归入"低风险可移"，但仍要在表里点名引用它的散文。

---

## ⑤ 失败报告格式

- 已试方案；实际命令与**输出原文**；当前怀疑；是否已建骨架（便于回退）。

## ⑥ 完成报告格式

- 四件产物路径 + 关键读数（`find`/`grep` 原文）。
- **清点表摘要**：高风险（被脚本/工具读）件数 vs 低风险件数。
- **裁定**：证据件走"移动"还是"索引折中"，**写出依据**（引用清点表的具体行）。
- **主动披露**：任何与方案不符、或方案没预见到的读取端（例如某件被 `*.json` 名单点名）。
- 明确"下一个阶段（阶段 1 文档面）可以直接开工"的前置已就绪。
