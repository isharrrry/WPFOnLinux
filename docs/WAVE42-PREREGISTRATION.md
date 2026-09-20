# `#42` 预登记 —— `D-T4`：**tab 步长在产品入口上不生效**（先定位读数，修法独立）

> 时序：本件在探针（`build/MilBridge/tests/TabGapProbe/`）与 runner（`build/MilBridge/tools/tab-gap-check.sh`）
> **落地之前**写定判据；**修法本身不在本波范围**（见 §5 边界）。
> 基线：`#40`（Release 权威件切换；机器行见 `docs/CURRENT-STATE.md`）。

---

## 1. 缺陷是什么（`D-T4`，登记在册）

- **现象（机器证，`#33` W33C）**：`tab-anchor` 语料的 `tab0 ↔ default` 配对里，
  **真机行数变化 `60/119`**，而**我方 `0/119`** ⇒ 我方**完全不受 tab 步长影响**。
- **它在帧列上的可见后果**：`frame-step.sh` 的 **3 条结构族红**（`known-red-frame-structural.md`）
  ＋ `PcLineOracle/known-red.txt` 的同 id 条目（`修前: 行数 期望=2 实得=4`）。
- **代码面（本波只读定位）**：三处 tab 逻辑**都存在**——
  `build/shims/PresentationCore.HbTextLine.cs:2895`（`defaultIncrementalTab → tabInterval`）、
  `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1764-1784`（`idealIncrementalTab` 与
  `Tabs == null && DefaultIncrementalTab > 0` 的谓词）、
  `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:1010`（对 `DefaultIncrementalTab` 的参数校验）。
  ⇒ **缺口在"接线"而不是"实现不存在"**（这正是要先把它做成**产品入口读数**的理由：
  三支 tab 臂直接调工厂，证明不了产品入口这一层）。

## 2. 本波做什么（**只加读数，不改产品**）

新增**纯读者**两件：

| 件 | 内容 |
|---|---|
| `build/MilBridge/tests/TabGapProbe/`（新探针） | 用 **public** API `TextFormatter.Create()` + `FormatLine`，同一段 `"a\tb\tc"` × 4 个 `DefaultIncrementalTab`（0/4/24/48），打印**行数与每行宽度**；机读行 `TABGAP …` / `TABGAP_RESPONSIVE=yes|no` |
| `build/MilBridge/tools/tab-gap-check.sh`（新 runner） | 三态：`PASS`（yes）/ `KNOWN-RED`（no = 复现 `D-T4`，rc=1）/ `NOINFO`（编不出、跑不起来、无判词） |

## 3. 判据（写死）

| 编号 | 判据 | 通过条件 |
|---|---|---|
| **T1** | 探针**能跑**且判词自明 | `TABGAP_BASELINE` 与 4 条 `TABGAP tab=…` 与 `TABGAP_RESPONSIVE=` 都在；缺任一 ⇒ `NOINFO`（不许当绿） |
| **T2** | **复现 `D-T4`** | 在当前权威件下 `TABGAP_RESPONSIVE=no` ⇒ `TABGAP_CHECK=KNOWN-RED`（**这就是它在册的证据**，不是新事故） |
| **T3** | 探针**有判别力**（反极性） | 把探针指向一个**改变 tab 值就必须变化**的引擎状态是不可能的（本探针只读）⇒ 判别力改由"**真机真值**"提供：`tests/parity/windows/tab-anchor/` 的 `tab0`/`default` 配对里真机 `60/119` 变 ⇒ 同一段语料在真机上**确实会变**。⇒ 若本探针报 `no` 而真值报"会变"，就是**我方缺陷**、不是判据假红 |
| **T4** | 修好后的读数（留给下一波） | 修法落地后同一探针必须 `TABGAP_RESPONSIVE=yes`（`TABGAP_CHECK=PASS`）；且 `frame-step.sh` 的 `结构红 3 → 0`（`#33` 的 E2 方子） |

## 4. 为什么**不在本波修**

修法会**同时**触发四件昂贵且互相牵动的事，必须在独立一波里一次做完：
① 改 `build/shims/PresentationCore.HbTextLine.cs` ⇒ **`GEN_KEYS` 变** ⇒ 按纪律**重取五臂 ＋ 重钉四处声明**；
② **改像素**（tab 位置变化 ⇒ 帧列/行宽读数变）⇒ 应用门禁 6 条机读行与冻结块全部重取；
③ `PcLineOracle/known-red.txt` 的 `tab0` 族 **136 条**要重取；
④ `known-red-frame-structural.md` 的 3 条撤登记（连同两本册子**同趟**删）。
⇒ 在**没把"产品入口读数"建起来之前**动它，等于"改了却说不清改没改好"。本波先把 T1–T3 建起来。

## 5. 边界（明说）

- 本波**不碰** `build/shims/**`、不改 `pc` 的任何生成物、不改 `known-red*.json`、不改 `verify-all.sh`。
- 位移：**本波不改任何九位**（新探针工程与 runner 都是仪器件；`TabGapProbe` 已在卫生名册里登记为
  `notneeded`/`no-compile-glob`，`CAND_MIN` 已同趟 85 → 86）。
- **不许**为了让 `TABGAP_CHECK` 变绿而改探针语料/判词（那是改判据换绿）。

## 6. 复现命令

```bash
bash build/MilBridge/tools/tab-gap-check.sh          # ⇒ TABGAP_CHECK=KNOWN-RED（复现 D-T4）；修好后应为 PASS
bash build/MilBridge/tools/build-hygiene-import-check.sh   # 名册/CAND_MIN 同趟一致
```

---

## 7. 结果（**已落地**；读数与预登记 §3 的对照）

```bash
$ bash build/MilBridge/tools/tab-gap-check.sh
  TABGAP_BASELINE tab=0 EXCEPTION EntryPointNotFoundException: Unable to find an entry point
                   named 'LoCreateContext' in shared library 'PresentationNative_cor3.dll'.
  TABGAP tab=0  EXCEPTION EntryPointNotFoundException: LoCreateContext …
  TABGAP tab=4  lines=1 width0=32.797  widthlast=32.797  widthsum=32.797
  TABGAP tab=24 lines=1 width0=56.797  widthlast=56.797  widthsum=56.797
  TABGAP tab=48 lines=1 width0=104.797 widthlast=104.797 widthsum=104.797
  TABGAP_NARROW tab=0  EXCEPTION …    TABGAP_NARROW tab=4  lines=1 widthsum=32.797
  TABGAP_NARROW tab=24 EXCEPTION …    TABGAP_NARROW tab=48 EXCEPTION …
  TABGAP_RESPONSIVE=yes   TABGAP_NARROW_RESPONSIVE=yes
TABGAP_CHECK=FAIL reason=fallback-bailed-to-native-LineServices n_exception=6
```

### ⭐ 两条结论（第一条**推翻了 `D-T4` 的一半措辞**，第二条是**新缺陷**）

1. **`D-T4` 的"tab 步长完全没生效"不成立**（至少在产品入口上）：`DefaultIncrementalTab` 取
   4 / 24 / 48 时，行宽**依次为 32.797 / 56.797 / 104.797** —— **确实随 tab 值变**。
   ⇒ `D-T4` 那句"我方 `0/119` 变"更可能的机制**不是**"属性没接到"，而是**下面第 2 条**：
   `tab0` 档（以及 tab 步长大于容器时的折行档）**根本没跑到托管路径**（落到不存在的原生 LS）。
   ⚠️ **如实更正**：`D-T4` 的措辞需要重写（"完全没生效" → "**`tab0` 档会落到原生 LS**"），
   而"重取 136 条真值"的必要性也随之要重新评估 —— **本波不改登记册**（改登记要有独立证据与同趟删改）。
2. **新缺陷（已登记 `D-G48`）**：HB 兜底**接不住时**，产品路径落到 `TextMetrics.FullTextLine`
   （原生 LineServices）⇒ Linux 上 `LoCreateContext` 不存在 ⇒ **`EntryPointNotFoundException` ⇒ 应用直接崩**。
   两个已复现的触发条件：**`DefaultIncrementalTab = 0`**；**tab 步长 > 容器宽**（`tab=24/48` × 容器 40 DIP）。
   ⇒ 判据（本 runner 已落地）：**只要出现 `EXCEPTION` 就 `TABGAP_CHECK=FAIL`**（崩永远不可接受，
   哪怕响应性成立）。这与 `D-G47`（`Debug.Assert`）同族：**都是"真实应用会被直接终止"**。

### 判据对照（§3 表）

| 编号 | 结果 |
|---|---|
| **T1**（探针能跑、判词自明） | ✅ 11 条 `TABGAP*` 机读行齐 |
| **T2**（复现 `D-T4`） | ⚠️ **部分推翻**：`TABGAP_RESPONSIVE=yes` ⇒ "完全没生效"不成立；**新发现** `tab0` 档崩 |
| **T3**（判别力来自真机真值） | ✅ 真机 `tab-anchor` 配对 `60/119` 变 ⇒ 真机上 tab 值**确实**影响行数/宽度 |
| **T4**（修好后应为 `PASS`） | 未到：当前是 `FAIL`（原因是**崩**，不是响应性）⇒ 修法留给下一波（§4 的四件昂贵事） |

### 边界（本波**没做**，如实写）

- **没改任何产品件**（`build/shims/**`、`pc` 生成物、`known-red*.json` 均未动）。
- **没改 `D-T4` 的登记措辞**（推翻它需要独立一波：同趟改两本册子 + 撤登记条件）。
- 本波新增的**仪器**：`build/MilBridge/tests/TabGapProbe/`、`build/MilBridge/tools/tab-gap-check.sh`
  （＋卫生名册一行 `notneeded`/`no-compile-glob`、`CAND_MIN` 85 → 86）。
