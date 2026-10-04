# 证据索引（docs.Linux/evidence）

[English](README.md) | **中文** | [Español](README.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。

> ⚠️ **本区为历史证据，勿据此判现状。**
> 本区（以及本区所索引的一切件）记录的是"**当时**做了什么、读数是多少"。
> **现状一律以** [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md)（机器行 `:9` = 冻结基线）与
> [`docs/ROUTES.md`](../../docs/ROUTES.md)（权威路线图）**为准**。

---

## 1. 裁定：走"**索引折中**"，物理件留在原位

阶段 0 的《证据件读者清点表》把候选件 **84 件**逐件清了读取端，结论是**走索引折中**：
本区**一个字节都不动**被机器读取的件，**只做导航 ＋ 横幅声明**。

**依据（清点表原文在哪）**：[`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) §4「裁定」逐条列了理由，摘要如下 ——

- **高风险 6 件移动代价 ≫ 收益**：`handoff.md`（它同时是 ~18 个测试/工具的**仓库根哨兵** ⇒ 移出仓根会让这些工具**根解析全部失败**）、
  `docs/CURRENT-STATE.md`（**4 个门禁步**机读它）、`docs/ROUTES.md`／`docs/unimplemented.md`（`pts-gap-count-check.sh` 以**现值锚点**机读）、
  `docs/PORT-SPEC.md`／`docs/INDEX.md`（孪生件登记表读其 sha16）。
- **中风险 63 件**（`docs/WAVE*-PREREGISTRATION.md`）：被四处**全域 glob**机读；移动它们会让历史报告里逐字引用的
  `docs/WAVE…md:NN` 行号锚**全部指向失效路径**。而 `docs/INDEX.md §4` 白纸黑字写着"**刻意不做大搬家**"。
- **低风险 17 件**虽零机读，但量少且分散，单独成波不值当；留原位对门禁**零影响**。
- **折中的安全性**：不动任何被读取件 ⇒ `[G4]` 四端、`handoff` 哨兵、四个基线步、pts 锚点、孪生件对拍**全部保持绿**。

> 若将来仍要改判"移动"：前置是**先清全部机读端**，并按"防误读微调"（每件顶加横幅、散文段折叠、**不改名**）**作一整波**做，`verify-all.sh` ×2 复跑 `64 ✅ / 0 ❌`。见清点表 §4 末段。

---

## 2. 导航：东西都在哪（**都在原位**）

| 我想找 | 去 |
|---|---|
| **某一波的预登记**（判据先写死的四要件） | `docs/WAVE<NN>-PREREGISTRATION.md`（现读全域 **63 件**；顶层 `WAVE*.md` 共 **67 件**） |
| **逐波技术账（交接账）** | 仓根 [`handoff.md`](../../handoff.md)（已压缩，只保留 `DEFREG` 路由键要求的编号行） |
| **权威状态机 / 路线图** | [`docs/ROUTES.md`](../../docs/ROUTES.md)（`§13` 任务树、`§15x+` 逐波记录） |
| **车道报告**（每条的读数、复算命令、`NOINFO`） | `build/MilBridge/<车道号>-report.md`（`repin-generation.py --check` 会读其中几件 ⇒ **不要移动/删除**） |
| **孤立的历史文档** | [`docs/history/`](../../docs/history/)（4 件） |
| **验收截图** | [`docs/m7c-accept.png`](../../docs/m7c-accept.png)、[`docs/m7c-accept-zero-probe.png`](../../docs/m7c-accept-zero-probe.png) |
| **门禁在册红** | [`build/MilBridge/known-red.json`](../../build/MilBridge/known-red.json) ＋ 声明表 |
| **接手件（新会话先读）** | [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md) |
| **重写前根 README 的 dated 更正段（原文）** | [`README-dated-archive.md`](README-dated-archive.md) |

## 3. 本区已有的阶段 0／阶段 1 产物

- [`_PHASE0-READERS-INVENTORY.md`](_PHASE0-READERS-INVENTORY.md) —— 《证据件读者清点表》（84 件逐行；**阶段 2 的输入**）。
- [`README-dated-archive.md`](README-dated-archive.md) —— 根 `README.md` 重写**前**的 dated 更正段（`T-A33`…`T-B24`）**原文另存**（附重写前全文），**不许丢原文**。

## 4. 引用证据时的三条纪律

1. **写明口径与出处**：读数是"哪一代、哪一件、哪条命令、什么时间"（引用要能复算）。
2. **dated 只增不改**：要更正就在后面追加 `⏪ dated` 行，**不要改原文**——那正是本区存在的理由。
3. **`NOINFO` 照抄**：证据里写"取不到"的，引用时也不许改写成"通过"。

---

[English](README.md) | **中文** | [Español](README.es.md) · [移植侧文档总线](../README.zh-CN.md) · [清点表](_PHASE0-READERS-INVENTORY.md) · [dated 存档](README-dated-archive.md)
