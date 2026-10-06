# `TASK-O1-O4-O6` 收尾报告 —— 结构「单一来源」化波（O1／O2／O4／O6；O3 未做）

> 落点：`feat-Linux`。本件逐项给「改了什么（文件＋关键行）／成对读数／反极性原文／是否达成」。
> 现状（开工前现取）：`feat-Linux = b1302088e`，工作区干净，`verify-all` **66 ✅ / 0 ❌**，`[5c/6]` 四档 `PASS`。
> ⚠️ 本波**不改产品逻辑、不改落点、不削弱任何判据**；九位**逐位未变**（不跑整波重建）。

---

## 0. 总览（现取）

| 项 | 前 | 后 |
|---|---|---|
| `verify-all` 步数（`^run_step "`） | 66 | **67**（加 `NO-HARDCODEDCFG`） |
| 覆盖面件数（`fp_inputs()`） | 239 | **242**（+3：牙 ＋ 豁免表 ＋ `nine-paths.tsv`） |
| `inputs_fp`（`~/w153a/bin/infp.sh fp`） | `8251d459b8cf4d36…` | `931bc19a775b21b1…` |
| 九位 | （见 §1） | **逐位未变** |
| `[5c/6]` 四档 | `PASS` | **`PASS`**（新增 `WFREEZE_NINESYNC=PASS`） |
| `docs/CURRENT-STATE.md:9` | `gen=#84 sha16=d530038a13ca9251` | **不变**（本波不重冻产品件） |

`git status --short`（末态）：**干净**（见收尾）。

---

## 1. O1 · 九位权威路径表**单一来源**化 ＋ 一致牙 —— ✅ 达成

**改了什么**
- `src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py`：
  - 新增 `--emit-nine`（只读导出端，打印 `路径<TAB>键`）与 `emit_nine()`；
  - 新增 `sec_ninesync(root, freezer)`（一致牙：断言「冻结器实际用的九条路径 == 仓内 `NINE_PATHS`」，不等即红并**逐条点名**）→ 并入 `decl` 档（保持 `[5c/6]` **四档**口径）；
  - `_freezer_record_txt(freezer, root)` 支持**仓内相对路径**解析（O4 用）。
- `src/Linux/build/MilBridge/nine-paths.tsv`（**新建·入库**）：由 `--emit-nine` 生成（`path<TAB>key`，9 行）。
- `~/w21-verify/w27-freeze.py`（**仓外**，先备份）：`NINE = [...]` 字面量 → **读 `nine-paths.tsv`**（`_load_nine()`，`{CFG}` 替换）。
- `src/Linux/build/MilBridge/wfreeze-root-sites.tsv`：`--emit-roster` **重发**（`derived 181→182 files 149→150`：新牙的 `HERE=…dirname…${BASH_SOURCE[0]}` 站点）。

**成对读数**
```
前：NINE_PATHS（仓内）  ⊕  NINE = [ …8 条字面量 ]（冻结器）—— 两份表手工同步 ⇒ 本波前 NINE 就曾写旧落点
后：python3 …/wave-freeze-consistency-check.py --root . | grep NINESYNC
   ⇒ WFREEZE_NINESYNC=PASS rows=9 src=reads-tsv       （冻结器已改读 tsv、且不再持 `NINE = [` 字面量）
   同跑 [5c/6]：WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS blockvalues=PASS
```

**反极性（真跑）**：把 `nine-paths.tsv` 的 `bridge` 行改坏一条 ⇒
```
WFREEZE_NINESYNC=FAIL rows=9 src=reads-tsv :: key=bridge tsv=src/Linux/build/WRONG/wpfgfx_cor3.so nine=src/Linux/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
WFREEZE_CONSISTENCY=FAIL rootdefault=PASS decl=FAIL nineauth=PASS blockvalues=PASS（四档互不代偿）
```
（逐条点名、且 `[5c/6]` 整体转 `FAIL`；复原后回 `PASS`。）

**是否达成**：✅。注：一致牙**并入 `[5c/6]` 的 decl 档**（非另开 `verify-all` 步）—— 为使「`O2` 后步数 == 67」成立（派单 §⑧A）。

---

## 2. O2 · 防回归牙：**禁止未登记的 `bin/Debug` 字面量** —— ✅ 达成（加一步 66 → 67）

**改了什么**
- **新建** `src/Linux/build/MilBridge/tools/no-hardcoded-config-literal-check.sh`：扫 `src/Linux`／`src/Microsoft.DotNet.Wpf.Linux`／`Guide.Linux` 下 `*.sh *.py *.csproj *.props *.targets` 的**代码行**（`sh/py` 整行 `#` 注释、XML `<!-- … -->` 块**不算命中**）里的 `bin/Debug`；命中且**不在豁免表**即红、**逐条点名**；三态 `PASS|FAIL|NOINFO`，`NOINFO` 不算绿。
- **新建** `src/Linux/build/MilBridge/hardcoded-config-exempt.tsv`：**76 行**豁免（`file<TAB>anchor16<TAB>class<TAB>registered<TAB>why`；`anchor16` = 内容锚），全挂**已入册** `D-G47`（自产件配置单一来源族）。豁免行挂**未入册**号 ⇒ 该豁免不成立、命中照旧红。
- **逐处三分类 ＋ 改干净真消费点**（shell/python 改走唯一声明）：
  - `src/Linux/build/close-wave.sh`（`:742` 哨兵 msg 的 `pc` 读 Debug）→ `bin/$SELFBUILT_CONFIG`；
  - `src/Linux/tests/…/Presentation.Tests/run-wpftextdemo.sh`（`:709`／`:743`）／`run-wpfprobe.sh`（`:302`／`:324`）；
  - `src/Linux/build/MilBridge/tools/`：`retake-arms-w21.sh`／`shim-in-artifact.sh`／`t1b-d3-acceptance.sh`／`t1b-live-window.sh`／`t1c-census.sh`／`t1d-probe.sh`／`t1c-inputtrace-verify.py`（＋各件补 `source selfbuilt-config.sh`）；
  - `src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/FallbackCriteria/run-df1-criteria.sh`。
  - **豁免**（class ＋ why 逐行上屏）：`wic-shim/check-applocal-sync.sh`（60 行沙箱夹具 `$tmp/…`）／`fp-inputs-hygiene-check.sh`（3 行夹具）／`artifact-src-fp.py`（3 行 docstring/自测字符串）／`selfbuilt-config.sh`（4 行**自身** grep 图案）／三个 DirectWrite harness ＋ `WiringSmoke/fix-deps.py`（**自建输出**目录，`-c Debug`）／`shim-in-artifact.sh` 用法 heredoc。
- **接线**：`Guide.Linux/verify-all.sh` 加第 `[+]` 步 `NO-HARDCODEDCFG`（**裸静态牙**，同时被 `STATIC-JAWS` 捕获式复跑）。
- **四处声明 ＋ 覆盖面 ＋ `--expect`**：`# VERIFYALL-STEPS-DECL: 67 gen=#85` ／ 头注释口径句 `**`#85` 收官起 = 67 步**` ／ `STEP-NAMES`（66 → 67 项）／ 新建 `docs/WAVE85-PREREGISTRATION.md`；`close-wave.sh` 的 `fp_inputs()` **+3 行**；第 `[42]` 步 `--expect 239 → 242`。
- `src/Linux/build/MilBridge/tools/wiring-closure-check.sh`：B 方向豁免表 **+1 行**（本牙参数误用分支门禁不可达）。

**成对读数**
```
前：grep -rl "bin/Debug" 于 34 件（*.sh/*.py/*.csproj/*.props）⇒ 无牙看着（selfbuilt-config.sh --debt 只是"只许减"的棘轮）
后：bash …/no-hardcoded-config-literal-check.sh
   ⇒ NOHARDCODEDCFG=PASS hits=76 files=10 exempt=76 unknown=0     （rc=0）
```

**反极性（真跑，两向）**
```
A（真消费点塞一处）：往 src/Linux/build/integration-wave.sh 追加
   echo "P src/Microsoft.DotNet.Wpf.Linux/src/PresentationCore/bin/Debug/PresentationCore.dll"
 ⇒ NOHARDCODEDCFG_HIT file=src/Linux/build/integration-wave.sh anchor=8b9d15258e2e330e line=…
   NOHARDCODEDCFG=FAIL hits=77 files=11 exempt=76 unknown=1 unregistered-exempt=0   （rc=1）
B（豁免挂未入册号）：把豁免表一行 `D-G47` 改成 `D-G999`
 ⇒ NOHARDCODEDCFG_HIT … registered=D-G999（不在已入册域 ⇒ 豁免不成立）
   NOHARDCODEDCFG=FAIL hits=76 files=10 exempt=75 unknown=1 unregistered-exempt=1   （rc=1）
```

**是否达成**：✅（`verify-all` 66 → 67）。

---

## 3. O3 · `verify-all.sh` 数据驱动化 —— ❌ **未做 ＋ 原因**（§⑦ 回退）

**为什么不做**：低风险形态下**「等价性 ＋ 66/0」与「表驱动」不能同时成立** —— 门禁的**自指牙**
`verify-all-step-check.sh` 抽取现场步名的**唯一口径**是 `sed -n 's/^run_step "\([^"]*\)".*/\1/p'`（锚 `^run_step "`）。
把 `run_step "NAME" cmd` 字面量行换成「读 `verify-all-steps.tsv` 再 `run_step`」后，**树上再无 `^run_step "` 行** ⇒ 牙看到 `names=0` ⇒ 必红。**实测**（变体在沙箱，真跑牙本体）：
```
$ bash verify-all-step-check.sh --file /tmp/o3-variant-verify-all.sh
VERIFYALL_SELF=FAIL names=0 decl=67 gen=#85 …
  ∟ count-mismatch(现场 0 ≠ 声明 67)
  ∟ name-set-differs(现场独有=[无] 声明独有=[…67 名…])
```
⇒ 要保住牙，就必须**保留** `run_step "NAME"` 字面量；而那正是「三处手工同步」的根。**三种做法**（① 纯表驱动 ／ ② 表驱动 ＋ 改牙的抽取源 ／ ③ 保留字面量 ＋ 表只作旁证）里：① 破牙；② 把牙变成"表 vs 表"的恒真牙（＝**把牙关掉**，违背 §⑦「禁止削弱任何判据」）；③ **不构成**"把步表抽出来"（仍是同一份声明）。
⇒ 按 §⑦ **回退该项**（`Guide.Linux/verify-all.sh` **未做 O3 改动**；末态 66/67 的步数来自 O2 的 +1）。
**建议（给出路）**：若要做，"同意等价性证明" 应同时改 `verify-all-step-check.sh` 的抽取口径为「**表 ↔ 现场执行轨迹**」（用 `--trace` / 结论区印实际执行轨迹），使牙不恒真 —— 那是**另一趟**、且**同趟**动门禁本体与覆盖面。

---

## 4. O4 · 冻结**记录段**进仓（外部只留"现场哨兵"） —— ✅ 达成

**改了什么**
- **新建** `docs.Linux/evidence/freeze/w85-record.txt`（三段 `BANNER/FROZEN/RECORD`；承载现取值的行**全用 `{…}` 占位符**）。
- `~/w21-verify/w27-freeze.py`：**新增** `GENS['#85']`，其 `TXT = 'docs.Linux/evidence/freeze/w85-record.txt'`（**仓内可寻址·相对仓根**）；**旧代（`#84` 及更早）`TXT` 一字未改**（旧绝对路径**保留兼容读**）。
- `wave-freeze-consistency-check.py`：`_freezer_record_txt()` 支持**相对路径按仓根解析**（`--template auto` 取值处）。

**成对读数**
```
前：WFREEZE_TEMPLATE_AUTO src=freezer-GENS path=/home/links-dev/w21-verify/w84/freeze/w84-record.txt   （仓外）
后：WFREEZE_TEMPLATE_AUTO src=freezer-GENS path=/home/links-dev/netTest/GitProj/WPFOnLinux/docs.Linux/evidence/freeze/w85-record.txt  （**仓内**）
    WFREEZE_TEMPLATE=PASS path=…/docs.Linux/evidence/freeze/w85-record.txt hits=0 notes=6
    WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS blockvalues=PASS（四档互不代偿）
```
**旧代仍可读（成对）**：`GENS['#84'].TXT` ＝ `/home/links-dev/w21-verify/w84/freeze/w84-record.txt`（**未改**）且该件现存在 ⇒ 旧代记录**照旧可寻址**（"旧代不回填"）。

**是否达成**：✅（`--template auto` 取到**仓内**记录段；`[5c/6]` 四档 `PASS`）。
⚠️ **如实划界**：本波**不重冻产品件**（九位逐位未变）⇒ **不写 `# RE-FROZEN #85` 块**、`docs/CURRENT-STATE.md:9` 保持 `#84`；`#85` 记录段作为**下一次真冻结的模板**已进仓。

---

## 5. O6 · 入口边界厘清（**清单式**，不搬迁） —— ✅ 达成

- **新建** `Guide.Linux/README.md`：**一键入口清单** —— 三入口（`verify-all.sh`／`integration-wave.sh`／`close-wave.sh`）的用途／典型调用／前置条件／判据（三条命令逐条可跑）。
- 根门面 ＋ 移植侧文档总线**各 1 行**指向它：`README.md`／`README.zh-CN.md`／`README.es.md`（「去哪看」表）＋ `docs.Linux/README.md`／`README.zh-CN.md`／`README.es.md`（「我想……→去读」表）。
- `docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md` **追加 §6**（具名登记理由）。
- **被引面（现取）**：`git grep -l <入口>` ⇒ `verify-all.sh` **591**／`close-wave.sh` **501**／`integration-wave.sh` **181** 件（派单记 588／497／175；§⑦「数一律现取」）；**多颗牙真调用它们**。
⇒ **不搬迁**（成本 ≫ 收益）。

---

## 6. 外带读数

- **`w27-freeze.py` 备份**：`/home/links-dev/w21-verify/w27-freeze.py.bak-pre-o1o4`；
  `sha256 = ee7d9c5b0cb18f003398c74d9e1d58d1b40a5a94f6582f99749f6c32200f34ee`（sha16 `ee7d9c5b0cb18f00`）。
- **九位（前 == 后，逐位未变）**：`bridge 848014567a1e29a5`／`pc e0108ff2c98dddbd`／`pf d124eea5b299b634`／`windowsbase 42a9c4728647fc7b`／`provider 7ef51cf912234384`／`win32shim 5f9ed647c68197ae`／`wic_shim f7b3026c8c019be2`／`hbtextline a40fe0a1151ebd0f`／`dwf 84f3b2d47af514e3`。
- **`HANDOFF-NEXT.md`**：追加 `cell=#1/#2/#3`（两次，后者取代前者）＋ `cell=#5` 更正行（`inputs_fp` 必移 ＋ 覆盖面 239 → 242 ＋ 步数 66 → 67）。
- **`verify-all ×2`**：原始读数见 §7。

---

## 7. 验收（终态，现取）

| 判据 | 读数 |
|---|---|
| A `verify-all ×2` | 两趟各 **67 ✅ / 0 ❌**（`步骤通过 67  ❌ 失败 0` ＋ `结论：✅ 全部通过` ＋ `EXIT=0`） |
| B 第三方形态 | `THIRDPARTY=PASS frames=42 max_colors=1644 min_colors=800`（**≥ 800**，空帧无回归） |
| C `[5c/6]` ＋ 八颗关键牙 | `[5c/6]` 四档 `PASS`（`WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS blockvalues=PASS`）；牙 `rc=0`：`VERIFYALL_SELF=PASS names=67 decl=67 gen=#85`／`ROOT_ALLOW=PASS unknown_fs=0`／`HANDOFF_MV=PASS mismatch=0`／`DEFREG=PASS declared=225`／`FP_INPUTS_HYGIENE=PASS coverage_n=242`／`BASELINESHA=PASS`／`SSC=PASS`（哨兵）/`COLUMN_FLOOR=PASS`／`PTSGAP=PASS`／`NOHARDCODEDCFG=PASS` |
| D O1/O2/O4/O6 反极性 | 见 §1（`WFREEZE_NINESYNC=FAIL`）／§2（`NOHARDCODEDCFG=FAIL` 两向）／§4（`--template auto` 取仓内）／§5 |
| E git | `git status --short` **干净**；本波提交见 `git log --oneline`（一笔代码+报告：`feat(tooling): 结构「单一来源」化波 O1/O2/O4/O6（+1 步；O3 未做）`） |

**复算清单**
```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
git status --short && git log --oneline -3
bash Guide.Linux/verify-all.sh                                             # 期望 67 ✅ / 0 ❌
python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py --root . --template auto
bash src/Linux/build/MilBridge/tools/no-hardcoded-config-literal-check.sh   # 期望 NOHARDCODEDCFG=PASS
python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py --emit-nine
bash src/Linux/build/MilBridge/tools/handoff-machine-values-check.sh        # 期望 HANDOFF_MV=PASS
```
