# P1 判据先写 —— 让「前沿」具名（`TASK-0302`／W7 收尾，队长执行；读时见下行）

## 0 目的（单一）
把 `app_g1.log` 的 `entry=` 面从 `unknown` 变成**具名**，从而让 W7 的验收项「**具名**前沿位移」可判。
**不**推进 PTS 能力本身（那要逐增量补 stub）；**不**声称两页可用。

## 1 依据（`t70` 复核给出的机制，逐字采纳）
- `g_pts_seq` **只在 `wpf_pts_gap()` 内递增**（`src/WpfGfx.Linux.Native/src/win32_pts.c:144`）⇒ **台账非零 ⟺ 六个缺口 stub 之一被调用**。
- 本链**第一个**会留痕的站 ＝ `PTS.CreateDocContext`（`PtsCache.Linux.cs:548`，`win32_pts.c:226`）。
- 本次失败在 `:548` **之前**（台账零行）⇒ 前沿在其**上游**的 DllImport 解析失败 ⇒ **名字在异常里、只是没取**（`Describe()` 只读台账）。
- `err=-10000` 是 `NativeError()` 读不到时的**常量回退**（`:991`／`A1_STUB_ERR :1028`），**不是** native 证词。

## 2 修法（最小、不新增"假成功"面）
在 `Describe(Exception e)` 内：当 `NativeEntryName()` 返回 `unknown` 时，从**原始异常**取入口名/DLL 名
（`EntryPointNotFoundException` 的 `Message` 自带 `named 'X' in DLL 'Y'`；`DllNotFoundException`／`BadImageFormatException` 取 DLL 名）。
- **不加后缀**（名字原样写进 `Entry` ⇒ 与名册可直接对拍）；来源说明只进 `msg`。
- 取不到 ⇒ 仍 `unknown`（**不许**编名字）。

## 3 判据（可判真假）
1. 构建成功（`dotnet build …PresentationFramework.Linux.csproj -c Release -m:1`，`DOTNET_gcServer=0`）。
2. 冷启跑腿后 `app_g1.log` 的 `entry=` 面**出现具名**（≠`unknown`）；给 before/after 成对原样行。
3. `PTS_G10_NAME` 从 `PASS form=unnamed` 变为 `PASS observed=<名>`（或若该名不在名册 ⇒ 如实报 `off-roster` 并处置**名册射程**问题，不许放宽）。
4. **零症状倒退**：两页仍 `alive=yes`／`app_rc` 成对；`EntryPointNotFoundException`／`abort(134)` after 不得增加。
5. 九位位移如实留痕（`pf` 必动）；哨兵按合规动作重写（`wave-push.sh --write`）使 `SENTINEL-SPEC` 绿。
6. 四大不变量（`^run_step "`=62／覆盖面=234／`DECL 62 gen=#81`／`--expect 234`）不变；两枚哨兵 `cmp IDENTICAL`。

## 4 两极化（缺一即作废）
- **反极**：沙箱里造一个**必抛 `EntryPointNotFoundException`** 的路径 ⇒ 取数格必须真的抓到入口名（不许恒空）。
- **正极**：现树跑腿 ⇒ `entry=` 具名。
- **回退证**：把代码改动逐字节复原 ⇒ `entry=` 回到 `unknown`（给前后 sha16）。

## 5 `NOINFO`（预期）
运行期**具体是哪个名字**本件不得预判；`off-roster` 是否出现取决于名册射程（见判据 3）。
