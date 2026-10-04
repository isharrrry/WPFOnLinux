# 阶段 0 · 命名约定冻结件（`_PHASE0-NAMING-CONVENTION.md`）

> **状态：冻结（阶段 0 定稿）。** 本件是"向上游靠 ＋ win/linux 共存"重构的**命名地基**，
> 供阶段 1（文档面）、阶段 2（证据件归位）、阶段 3（根目录瘦身）、阶段 4（布局上游化）**共同引用**。
> 来源：`docs/UPSTREAM-ALIGN-PLAN.md` §2.2（五条口径）、§2.3、§2.5、§4.3；本件**不改**任何既有件。
>
> ⚠️ **本件冻结的是"约定"，不是"落地"。** 物理搬迁在阶段 3／4 执行；阶段 0 只建骨架
> （`docs.Linux/**`、`docs/guide/`、`docs/evidence/`）。

---

## §1 一条规矩

**全仓每类东西都成对 —— `X`（原始 / Windows 侧）＋ `X.Linux`（linux 侧）。**

于是"看哪个平台"永远只需认**一个目录后缀**，**不必**在每层目录里挑文件、判断某个件属哪个平台
（`docs/UPSTREAM-ALIGN-PLAN.md` §2.2 口径 4）。

| 类别 | 原始 / Windows 侧 | linux 侧 | 落点（目标） |
|---|---|---|---|
| 源码 / 产品码 | `src/Microsoft.DotNet.Wpf/` | `src/Microsoft.DotNet.Wpf.Linux/` | 阶段 4（C 期） |
| 仓内设施（原仓没有） | — | `src.Linux/{build,tests,samples,tools}/`＋`wpf-linux.sln` | 阶段 3 |
| 脚本 / 一键入口 | `Guide/`（`build.cmd`、`Restore.cmd`…） | `Guide.Linux/`（`verify-all.sh`＋其它） | 阶段 3／4 |
| 文档 | `docs/`（原始 / Windows 侧） | `docs.Linux/`（移植 / Linux 侧） | **阶段 0 已建骨架** |

> `src.Linux/` 是**linux 侧独有的"仓内设施"根**（原仓 `dotnet/wpf` 没有 `build/ tests/ samples/ tools/`），
> 按口径把 `build/ tests/ samples/ tools/ wpf-linux.sln` 收进 `src.Linux/`，**根上不新留散件**。

---

## §2 三类近例（本阶段实际会碰到的）

1. **文档**：`docs/`（win 侧四分类：规范 / 现状 / 证据 / 历史）｜`docs.Linux/`（linux 侧：`guide/ design/ upstream/ evidence/`）。
   - 两**根**均存在，各自内部再分子目录；**不另建 `Documentation/`**（`UPSTREAM-ALIGN-PLAN.md` §4.3）。
2. **脚本**：`Guide/`（win 侧根脚本）｜`Guide.Linux/`（linux 侧一键入口，如 `verify-all.sh`）。
3. **源码**：`src/Microsoft.DotNet.Wpf/`（win，与上游逐件一致）｜`src/Microsoft.DotNet.Wpf.Linux/`（linux，旁挂镜像同名子树）。

---

## §3 目标根布局（阶段 3／4 收口后）

```
WPFOnLinux/
├── src/                 ← 产品码成对：原始 / linux
│   ├── Microsoft.DotNet.Wpf/            （win，与上游逐件一致）
│   ├── Microsoft.DotNet.Wpf.Linux/      （linux 覆盖层，镜像同名子树）
│   └── WpfGfx.Linux.Native/             （原生 shim，不属上游任何工程）
├── src.Linux/           ← linux 侧仓内设施（原仓没有）
│   ├── build/  tests/  samples/  tools/
│   └── wpf-linux.sln
├── Guide/               ← win 侧根脚本
├── Guide.Linux/         ← linux 侧一键入口（verify-all.sh …）
├── docs/                ← 原始 / Windows 侧文档（guide/ ＋ evidence/）
├── docs.Linux/          ← 移植 / Linux 侧文档（guide/ design/ upstream/ evidence/）
├── README.md  README.zh-CN.md  README-Window.md（名称保留不改）
└── LICENSE.TXT  SECURITY.md  .github/  .gitignore  .gitattributes …（治理面）
```

---

## §4 边界与例外（冻结时一并定，防阶段 3／4 走偏）

| # | 例外 | 依据 |
|---|---|---|
| 1 | **`build/`、`tests/` 保留其"大结构"**，只是整体移入 `src.Linux/`；**不**按上游工程拆散 | §2.5 口径 3 |
| 2 | **`README-Window.md` 名称保留不改** | §6.10（改名代价 > 收益） |
| 3 | **根目录不新增目录**；根上只留"原仓也有"的件 ＋ 成对的根 | §2.2 |
| 4 | **`upstream/wpf/**`** 按 C2 收法在阶段 4 移除，改由 `docs.Linux/upstream/` 的逐件清单承担校验 | §2.4 |
| 5 | **被冻结机器读取的证据件（`docs/WAVE*`、`handoff.md`、`docs/ROUTES.md`）本阶段一个字节不动** | 阶段 0 边界；清点表另出 |

---

## §5 判据（可复算 · 供后续阶段复核）

- 成对存在：`ls -d src docs Guide docs.Linux 2>/dev/null` 应列出成对根（落地后）。
- 命名一致：`*.Linux` 后缀恒指 linux 侧；`X` 恒指原始 / Windows 侧。
- 骨架就位（阶段 0）：`find docs.Linux docs/guide docs/evidence -type f | wc -l` ≥ 5，
  且 `docs.Linux/{guide,design,upstream,evidence}` 四个子目录存在。

---

## §6 主动披露（阶段 0 现场）

- `src.Linux/`、`Guide/`、`Guide.Linux/`、`src/Microsoft.DotNet.Wpf.Linux/` 在本阶段**仅为约定**，
  **未**建目录（阶段 0 只允许建 `docs.Linux/**` 与 `docs/{guide,evidence}/`）。
- `docs/CURRENT-STATE.md:9` 的冻结基线声明行按边界**保持原样**，未动。
