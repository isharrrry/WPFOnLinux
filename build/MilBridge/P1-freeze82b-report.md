# P1 (#82) 重冻入册报告（`T-B24`；冻结收口 · 本趟唯一写者）

> 读取时刻：**2026-10-03T20:4x+08:00**（各条另注）｜车道工作目录 `~/w21-verify/w82/`（`logs/`＝链条日志；`bin/w82-chain.sh`）
> 判据先行：`docs/WAVE81-PREREGISTRATION.md`（仪器波）＋ `docs/WAVE82-PREREGISTRATION.md`（两颗判据牙接线）
> 权威件构建配置 = **Release**（唯一声明 `build/SelfBuiltConfig.props`）｜**本代不打推送**（推送面归后续）。

## §1 结果（现取）

| 项 | 读数 |
|---|---|
| 世代 | `#81 → #82` |
| 基线件 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `7cd1bc5c37a74e8d → **05c5e521c3b14ace**`（`1,238,130 → **1,248,947** B`） |
| `docs/CURRENT-STATE.md:9` | `BASELINE-FROZEN gen=#82 sha16=05c5e521c3b14ace file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 冻前 `verify-all` | **64 步 / 通过 64 / 失败 0**（`rc=0`；875 用例通过 / 2 跳过） |
| 冻后 `verify-all` ×2 | **各 `64 ✅ / 0 ❌`**（`rc=0`×2） |
| 前置排练 | 正常档 `PREVCHECK=PASS gen=#82 keys=7`／错值档 `REFUSE rc=2`／沙箱副本**零字节改动** |
| 哨兵 | 两枚 `cmp IDENTICAL`；`SSC=PASS lines=13 keys=13`（`BASELINE=#82`） |

## §2 九位（现取，`Release` 权威件）

- `bridge` `7152f9ac119e1bb0`（5,073,776 B）
- `pc` `83c71acfb20f26d7`（3,603,456 B）
- `pf` `7ef0dbb210db54e3`（6,180,352 B；**环成员**）
- `windowsbase` `96554b5419761f0a`
- `provider` `4f01368cec2a728b`
- `win32shim` `5f9ed647c68197ae`（`libwpfwin32.so`，`567,456 B`；`exports 846`）
- `wic_shim` `f7b3026c8c019be2`（**逐位未变**）
- `hbtextline` `e2fa9ec9be1a6cf1`（**逐位未变**）
- `dwf` `e0fcfd13ad86b2b4`
- `BRIDGE_SRC_FP` = `75c7883cc3145dc8`（`BRIDGE_SRC_N=79`）
- `inputs_fp` = `fd9b4064ed0f85329e9491c05c9f4c581c601b8875bf8a8eebc603d845034742`（覆盖面 **237**）

**相对 `#81` 冻结值**：`win32shim d406f243cdc2c402 → 5f9ed647c68197ae`（产品：hc demo 修复链）／`bridge 941e69902d82ef02 → 7152f9ac119e1bb0`（产品/重发：`T-B23` AOT 桥 SkiaSharp 解析补应用局部 `runtimes/<rid>/native/` 一档）／`pf 1c6c58df6d757f3f → 7ef0dbb210db54e3`（产品 ＋ 环成员）／`pc ba162811e97e4484 → 83c71acfb20f26d7`（`T-B18` WIC RTB 登记）／`windowsbase`/`provider`/`dwf`（整波重建位移）／`wic_shim`、`hbtextline` **逐位未变**。⇒ 冻结器现取 `changed`（七位）**逐位落在** `allow_changed` 内、**无表外位移**。

## §3 本代内容（合波）

1. **hc demo 修复链（`T-B1..T-B19`，产品波）**：native `src/WpfGfx.Linux.Native/src/win32_pts.c`（真 `v` 几何／跨窗陈旧句柄具名拒发／行盒取段原点／`FsDestroyPageBreakRecord` 第二条认领／附属对象几何真值 ＋ 浮动绕排闸）；托管生成件 `build/PresentationFramework.Linux/{PtsPage,FlowDocumentPage,PtsHelper,DocumentPageView}.Linux.cs`；PresentationUI 主题字典替身 `build/CycleStub.PresentationUI.Linux/`；桥 `src/WpfGfx.Linux/Interop/**`。**结果**：hc demo 三 tab 全可用（tab1 浮动绕排／tab2 分页页视觉换父接回／tab3 修体挪到渲染遍历入口）；**关窗 `rc 134 → 0`**。
2. **WIN-INTEROP（`T-B2` L1 ／ `T-B6` L3）**：框架搜索路径**只加一档**；Windows 短路 ＋ 导出脚本。⚠️ L2 已实现但**默认回退**（实测打破 hc app-local ⇒ 整笔回退）。
3. **率重取（`T-B21`）**：`SILENT_SEGV_HIT 0/175 ⇒ 95%` 单侧上界 `1.697278%`；带窗闸仍 `VOID-PREMISE`（如实）。
4. **`R-GATE` 回归修（`T-B23`，产品波）**：历史绿靠**陈旧 `.so`**，全量重建后暴露 `DUCE.Channel.Commit` `COMException 0x80004005`；修后 `R_GATE=PASS crit=13/13`。
5. **尾波2 后续（`T-A59..A75`，产品波）**：证据换代／带窗率闸可判定／`Fs*`／`Lo*`／LS 族缺口真实现分批（`ops 58 → 42`、`exports 689 → 846`、`stubs 1 → 0`）／契约与状态位。

## §4 链条（逐段现取；日志在 `~/w21-verify/w82/logs/`）

| 段 | 命令 | 判词 |
|---|---|---|
| 应用门禁 ×2 | `w82-chain.sh gateapp` | 两趟各 `rc=0`、`rows=6` 全 `result=PASS`、判词行逐字 `GATE_LINES_IDENTICAL=yes` |
| 冻前 `verify-all` | `w82-chain.sh pre` | `rc=0`；`步骤通过 64 ❌ 失败 0`；`结论：✅ 全部通过` |
| 前置排练 | `w27-freeze.py --prev-check-only '#82' --baseline <沙箱副本>` | 正常档 `PREVCHECK=PASS keys=7 checked=7 skipped=0`／错值档 `PREVCHECK=REFUSE rc=2`；沙箱两件 sha **排练前后逐字节不变** |
| 冻结（干跑） | `W27_RECORD_CHECK_ONLY=1 w27-freeze.py <pre 日志> w82-rows-r1.txt '#82'` | `PREVCHECK=PASS` ＋ `BLOCKVALUE=PASS keys=9 tier_keys=8 bsfp=1 infp=1` 后**在任何写盘之前** `exit 0` |
| 冻结（真跑） | 同上（去干跑口子） | `FREEZE_RC=0`；`基线已重冻为 #82；整份 sha16 = 05c5e521c3b14ace`；`BASELINEGEN=PASS`／`ARMLOG_SHA=PASS`／`COLUMN_FLOOR=PASS` |
| 冻后 `verify-all` ×2 | `w82-chain.sh post1` / `post2` | 各 `rc=0`；各 `步骤通过 64 ❌ 失败 0`；`结论：✅ 全部通过` |
| 哨兵 | 现写两枚（`temp＋rename`） | `cmp IDENTICAL`；`SSC=PASS lines=13 keys=13 cmp=IDENTICAL` |

## §5 硬边界与如实留档

- **冻结 sha 只由脚本算**（`w27-freeze.py`）；`temp＋rename`；写前 `cp -p` 备份（`w27-freeze.py` 自身在写基线前先 `cp -a` 出 `B.pre-freeze.#82.bak`，现取 `nlink=1`、与写前现场基线逐字节相同）。
- **`T-B23` 之后产物又变**（相对 `T-B22` 停手时点）⇒ 本趟**现取**更新了 `GENS['#82']` 的 `infp`（`d400153a… → fd9b4064…`）与 `bs_fp`（`546d5b8c37d1695b → 75c7883cc3145dc8`）；**只改 `#82` 条目**（`diff` 证明改动仅落在 `#82` 区；`#81` 块 sha 逐字节未变）。`prev_*` 七位仍与 `#81` 冻结块**逐位相符**，未改。
- **覆盖面 +1**（`MilPresentProbe.cs`）：`fp_inputs()` ＋ `[42] --expect` 同趟 `236 → 237`（现取 `FP_MANIFEST_TEETH=PASS files_n=237`）。
- **哨兵**由本趟按规范现写（`WAVE=w82-freeze`／`BASELINE=#82`／`BASELINE_SHA16=05c5e521c3b14ace`）；`SENTINEL-SPEC` 与 `docs/CURRENT-STATE.md:9` 的机器行互证。
- **本代不打推送**；`GENS` 老代条目与其它在册件**一字未改**（除上列结账件）。
