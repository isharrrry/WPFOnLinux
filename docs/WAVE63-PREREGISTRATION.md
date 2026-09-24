# 波 `#63` 预登记（**判据／显示层批 D**：判词方向 ＋ 跨臂体制同一性 ＋ 自报抽取器隐去状态 ＋ 陈旧 `why` 重钉）

> 车道 W152A｜基线 `gen=#62 sha16=845219762aa61fb8`／903,901 B｜本波**零产品改动**（只动判据装置与显示层）
> 判据先写件：`~/w152a/criteria63.md`（写定于取任何"修后"读数之前）｜链报告：`build/MilBridge/W152A-report.md`

## §1 本波是什么

四件，一次冻（`D-G115`／`D-G116`／`D-G117` ＋ `known-red.json` 的陈旧散文）：

| 件 | 任务 | 入口件 | 修前 → 修后 |
|---|---|---|---|
| ① | `D-G115` 判词补「方向」 | `build/MilBridge/tools/regression-decision.py` | `71734fce77842478` → **`6a0e8ccc0c6cb5d7`** |
| ② | `D-G116` 新牙「跨臂体制同一性」 | `build/MilBridge/tools/regime-identity-check.sh` | **新建** → `e43d7b10d0c1d598` |
| ③ | `D-G117` 自报抽取器隐去状态（**两半**） | `build/MilBridge/tools/prereg-four-requirements-check.sh` ＋ `verify-all.sh` | `235d76b61cdc46a4` → **`a40aac9031304a8f`**｜`58422c5f1f2c5682` → **见 §1 实测** |
| ④ | `known-red.json` 陈旧 `why` | `build/MilBridge/known-red.json` | `cc0dd903972d7f73` → **`2209966ee1d2cc`**（前缀） |

台账另加两行：**回归判定台账**（`--cases` 用的那张表）`5d3c26a1c8d83688` → **`de6290cfad8892a1`**（`--cases` 9/9 PASS）。
⚠️ **本预登记刻意不逐字复现那两个"证据串"**（判定工件的机读判词行／回归判定台账的**文件名**）：该牙的「有证据」检测是**全文子串匹配** ⇒ 逐字提到就会被判成"有证据"而走 `FAIL`（**假红方向**）。⇒ 本条是**已登记的射程边界**（第 2 次现场踩到；`#60` 预登记同样踩过一次），**不是**放宽检测。

## §2 承重判据（**继承**，不发明）

### 2.1 `D-G115`：判词必须真的判方向

```
REGDEC_DIRECTION = A高于B | B高于A | 无显著差     ← 由 p 与两臂点估计「现算」，不许抄
A = 新臂（被试件）｜B = 旧臂（对照件）            ← 图例行同趟印，免得读的人猜
判词选词：上行 ⇒ rate-aggravated（既有口径逐字保留）｜下行 ⇒ rate-mitigated ＋ 逐字写「这不是本波引入」
显著 ∧ 两臂点估计相等 ⇒ 方向算不出来 ⇒ NOINFO（**不许印任何方向词**）
```
**口径句（逐字采纳）**：**"判词带方向断言 ⇒ 判据必须真的判方向；双尾显著 ≠ 上行显著。凡『没判方向却写了方向词』的判词，在反向设计里就是伪造结论。"**

### 2.2 `D-G116`：跨臂体制同一性

```
体制列（**判用**）= BASE ｜ MAXGEOM（AFTER_M1 的 geom）｜ START_MAX ｜ m_ok
结果侧（**只诊断** REGIME_OUTCOME_DIAG=，**不进 rc**）= after_R 几何 ｜ r_ok ｜ r_ok2 ｜ fgeom ｜ frame ｜ CFG_HIT ｜ GEOWRITE
PASS   ⟸ 每个「≥2 臂」的 pair 里全部腿的体制四列**逐项相同** ∧ 无「单格判红」违规
FAIL   ⟸ ① 任一多臂 pair 体制不等 ⇒ 标 INCOMPARABLE ＋ 逐腿点名；② 任一腿违反「判红 = 四件合取」
NOINFO ⟸ 语料目录不存在／**空台账**／**任一体制列缺失**／**没有任何「≥2 臂」的 pair** ⇒ **响亮失败**（禁静默判等）
判红 = 四件合取 ⟸ START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes
APP_ALIVE（声明式派生）⟸ 该腿 probe.txt 里 RESULT 行 ∧ AFTER_R2_SETTLED 行 ∧ DONE 行「三条都在」
```
⚠️ **为什么结果侧不许进体制**（`D-G116` 的范畴订正，主控 `2026-09-24` 已裁定）：`fgeom` 是 `AFTER_R2_SETTLED`
那一刻的读数，**与 `r_ok2` 39/39 同向**（修后臂 `800x600@+0+0 ∧ r_ok2=1`；修前臂 `1280x1024@+0+0 ∧ r_ok2=0`）
⇒ 把它算进体制，**A1／POL2（唯一的两个多臂 pair）全部被判不可比** ⇒
**口径句**：**"把结果算进体制，等于用『保护可比性』的名义否掉可比性。"**

### 2.3 `D-G117`：判据说全了，屏幕只露一态 ⇒ 半可见 = 假绿方向

```
半①：批次形态下**最前面**多印 PREREG4=<批次判词> files=… pass=… fail=… na=… noinfo=… out_of_scope=…
      （逐字匹配 verify-all 的自报口径正则 ⇒ 四态计数上屏；**零语义改动**）
半②：抽取器的**值词表**纳入 NA／SKIP／REPORT ＋ **汇总/计数/射程**三类行（…_SUMMARY／…_COUNTS／…_SCOPE）另开出口
      ⇒ 否则**下一个新状态照样被吃掉**（只治批次形态 = 只治一处症状）
```
**口径句（逐字采纳）**：**"判据的沉默/半可见，必须能被证明是『没东西可判』，而不是被显示层吃掉。"**

### 2.4 本波的**回归判定四要件**：**不适用**（逐字声明）

<!-- PREREG-NO-REGRESSION-DECISION: none -->
⚠️ **本波不做任何回归判定** —— 它是**判据装置/显示层**波：只改一颗判词牙的方向、加一颗"可比性"牙、
修显示层，**没有**任何"两臂对拍得出结论"的主张。
⇒ 本条**按条件句读**：它声明的是「**如果**本波在别处声称做过回归判定，**那么**四件必须同时在位」——
**是"这一刻不适用"的声明，不是"我已经做过"的声明**。
⇒ 本波的反极性（同一颗牙、只换被测件一处）**只用于证明牙是活的**，**不**主张任何产品件的回归。

### 2.5 三态

`REGDEC_*`／`REGIME_IDENTITY=PASS|FAIL|NOINFO`／`PREREG4=PASS|FAIL|NA|SKIP|NOINFO`。
**`NOINFO` 既不算绿也不算红**；门禁里 `rc≠0` 一律 `❌`。

## §3 反极性（**已实测**，成对；缺一即本件作废）

| 档 | 输入 | 读数 |
|---|---|---|
| ① `D-G115` 下行 | 旧 `24/27` 红 → 新 `0/40` 红 | 修前 `rate-aggravated`（**印反**）⇒ 修后 `REGDEC_DIRECTION=B高于A` ＋ `rate-mitigated` |
| ①b `D-G115` 上行 | 旧 `10/40` → 新 `35/40` | `REGDEC_DIRECTION=A高于B` ＋ `rate-aggravated`（**既有口径逐字保留**） |
| ② `D-G116` 同体制 | 两臂体制四列逐项相同 | **`PASS`**（结果侧差异**只在诊断行**，不拉红） |
| ②b `D-G116` 换体制 | 某臂 `m_ok 1→0` | **`FAIL`** ＋ `REGIME_INCOMPARABLE` ＋ `state=INCOMPARABLE` |
| ②c `D-G116` 单格判红 | `r_ok2=0` 而 `START_MAX=1`／`APP_ALIVE=no` | **`FAIL`** ＋ `REGIME_RED_VIOLATION` |
| ②d `D-G116` 缺列／空台账 | 删 `m_ok`／无 `probe.txt` | **`NOINFO`**（响亮失败） |
| ③ `D-G117` 复现 | `PREREG4=NA` 存在却不上屏 | 修前只上屏 `PREREG4=PASS` ⇒ 修后批次首行带四态计数 |
| ③b `D-G117` 阳性对照 | 喂「只有 `NA` 态」的步 | `PREREG4=NA` ＋ `PREREG4_SUMMARY …` **都上屏** |

## §4 设计性变更（**必须写，否则下一趟当漂移**）

1. **`inputs_fp` 必变**：`regression-decision.py` ∧ `known-red.json` **都在** `close-wave.sh` 的 `fp_inputs()` 白名单内。
   成对记账 = 落地前后各取一次 ＋ **交叉表** ＋ **全退反证**（见 `W152A-report.md` §4）。
2. **`verify-all.sh` 步数 35 → 36**（四处声明同趟：`DECL` 首行 `36 gen=#63`／`STEP-NAMES` 尾加 `REGIME-IDENTITY`／
   口径句逐字 `**`#63` 收官起 = 36 步**`／本预登记 H1 含字面 `#63`）。
3. **自报口径显示窗 `12 → 16`**（`verify-all.sh` 抽取器）：**只放宽显示窗、判定语义零改动**（与 `#31` 那次 `8 → 12` 同口径）；
   值词表纳入 `NA|SKIP|REPORT` ＋ 三类汇总行出口 ⇒ 本波起**自报口径行的条数与内容会变**（设计性变更）。
4. 九位：本波**零产品改动** ⇒ 只允许 `pf` 环成员同尺寸（`6,123,520 B`）位移；出现第二处 ⇒ 停手报主控。

## §5 **射程边界**（逐条写死，免得被读成本步的全域结论）

- `REGIME-IDENTITY` **只判「可比性」与「判红是否四件合取」**：它**不**重判 `GEOM-BEAT`／`GEOM-RESEND` 的结论，
  **不**测当前桥件（它只读冻结语料），**不**主张"体制同一 ⇒ 结论正确"。
- **`frame-at-base`（T0 装饰/框架几何）未查**：现台账 `probe.txt` **不记录**（`fgeom` 只出现在 `AFTER_R2_SETTLED` 那一行）
  ⇒ 本牙打 `REGIME_NOT_IN_LEDGER frame-at-base` ＋ `REGIME_UNCHECKED=1`，**顶上不冒充"装饰也查过了"**。
  建议后续波给探针加 T0 装饰几何记录 ⇒ 那时本牙才可能真判装饰同一性。
- **单臂 pair 不判**：`B1`／`D1`／`F1`／`POL` 只有一支臂 ⇒ 逐条点名 `state=SINGLE-ARM`（**不进不可比计数**）。
- `APP_ALIVE` 是**声明式派生**（三行都在），**不是**对进程的直接观测；台账若将来提供显式存活性列，本牙应同趟改用它。
- `D-G115` 的**下行词**只改**判词**：`state`／`rc`／`REGDEC_TABLE`／`REGDEC_FISHER` 的语义一字未动。
- `D-G117` 半②**只扩大"上屏面"**：任何 `KEY=VALUE` 的**语义、判定与 `rc`** 一字未动；
  ⚠️ 但**显示窗仍有限**（16 行）⇒ 单步骤若匹配行数超过窗，「总判行」仍可能被截（本波在冻前 `verify-all` 里逐步骤核对）。

## §6 未接入的（**如实登记，逐条**）

- **不给探针加 T0 装饰几何记录**（§5 的射程缺口 ⇒ 建议后续波）。
- **不修** `D-G115` 之外 `regression-decision.py` 的任何语义；`--selftest` 既有例的判据文本一字未改（**只增两例**）。
- **不动** `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
  `build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`（主控写域）。
- **不动臂**、**不动**冻结语料 `build/MilBridge/geom-corpus/**`、**不重取**任何臂日志。
