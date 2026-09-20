# 波 `#33` 预登记（**落地前**写；⚠️ 如实标注：本文件写在**三条车道已开工之后**，但**在它们任何一处落地之前** —— `#26` 起"落地前先预登记"这条纪律的落点是"**改动落盘之前**"，本波遵守了该落点，但**派单与预登记的顺序**是反的，已记为流程瑕疵，`#34` 起改回"先预登记再派单"）

> 起点 = `#32` 冻结基线（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#32` 块，整份 `5a9d174852453384`）｜九位：`bridge d567c26f197ec1e3`／`pc b877ff3e3437145a`／`pf a1ce403a74225f10`／`windowsbase 1114a28ec5a03ab7`／`provider 9aa0d744802aaa31`／`win32shim 0098234982391bbf`／`wic_shim 03b67fbcd7c385b6`／`hbtextline e89fed55fd8e32bc`／`dwf 0ed422ef2dd46445`。
> 起因 = `#32` 收官时列出的剩余清单里的 **★A**（「`pipefail` ＋ 管道左侧被 SIGPIPE 杀死 ⇒ 判据错」这一族的**全仓普查与修复**）、**★C**（补两个"未取到"的读数）、**★D**（`--selftest` 前提自持的**落地**）、**★E**（`FrameProbe` 的 3 条**结构族红**今天"红着但没登记"）。

## §1 内容（三条车道 ＋ 主控波尾；写域互不重叠）

| 车道 | 干什么 | 构建者？ | 写域 |
|---|---|---|---|
| **W33A** | **★A 全仓普查 ＋ 修高危点**：新建牙 `build/MilBridge/tools/pipefail-sigpipe-check.sh`（三态＋金丝雀＋`--selftest`，**优先判据 = 把站点抽出来真跑**），对全仓 `*.sh` 扫穷尽；修**确认高危**的点（优先 `integration-wave.sh:407`「0 错 0 警」与 `:297/:329`「空操作护栏」、`publish-milbridge.sh:108`、`check-applocal-sync.sh` 的自测段） | 否（零 `dotnet`） | 新牙 ＋ 被修件（**不含** `verify-all.sh`／`close-wave.sh`／`samples/**`／`docs/CURRENT-STATE.md`／`handoff.md`／`known-red.json`／`tests/**`） |
| **W33B** | **★D `--selftest` 前提自持的落地**：落 `#32` W32B 开出的单子（**除**已修的 `build-hygiene case R`）＋ 给**所有** `"$0"`/`bash "$SELF"` 重入自己的自测件加**"本件 sha 自测首尾一致"的自证**（不等 ⇒ `NOINFO` ＋ 点名 `D-G41`）＋ 把 `column-floor` 的"**裸基线**"范式推广到有**扰动实证**的件 | 否（零 `dotnet`） | `build/MilBridge/tools/*.sh` 的 **`--selftest` 段**（**只改自测段**） |
| **W33C** | **★E `FrameProbe` 的 3 条结构族红查清 ＋ "登记还是修"的裁定建议**（数据在盘上：`/tmp/frame-step/{strict,lenient,strict+prefix40}.log` 就是 `#32` 波尾那三趟） | 否（零 `dotnet`，**不许重跑探针**） | **零仓内写入**（只给结论与逐字可粘文本） |
| **主控** | ★C 两个"未取到"的读数 ＋ 接线（若 W33A/W33B 有落地：`fp_inputs` 纳入）＋ 波尾链 ＋ 重冻 `#33` ＋ 文档 | 是（**唯一**构建者，波尾） | `verify-all.sh`／`build/close-wave.sh`／`samples/**`／`docs/**`／`handoff.md` |

**三条写域已划开**：W33A 与 W33B 都碰 `build/MilBridge/tools/*.sh`，但**段位不同**（W33A 生产路径、W33B 自测段）；两车道被要求**动手前看目标件 mtime**，**近 2 分钟被动过就跳过并如实报**（本波引入的并发护栏）。

## §2 位移预测（**表外位移 ⇒ 停**）

| 位/量 | 预期 |
|---|---|
| 九位 | **只有环成员 `pf` 变**（波尾 `[1/6]` 重编惯例）。⚠️ **本波不碰任何产品件**（改的全是 `.sh` 仪器）⇒ `pc`/shim/桥 **不动** |
| `GEN_KEYS` 三项 | **不动** ⇒ **不重取五臂** |
| `inputs_fp` | **必变**（`integration-wave.sh` 与 `close-wave.sh` 都在覆盖面里；W33A/W33B 改了覆盖面成员 ⇒ 设计性变更，须单列） |
| `verify-all.sh` | **不动则步数仍 22**；若 W33A/W33B 的交付需要新步 ⇒ 由**主控**在同趟接（**不许车道自己改**） |
| `BRIDGE_SRC_FP` | **不动**（只改 `.sh`）⇒ 桥不重发 |
| 五臂日志 / `arm_logs` | **不动** |
| `known-red.json` | **不动**（本波无新声明；★E 若裁定"登记"，登记册的**位置**由 W33C 建议、**主控**落） |

## §3 各车道的判据（要点）

- **W33A**：① 牙的三态与**金丝雀**（含"单行左端 ⇒ 必不命中"这条阴性对照）；② **精确**高危站点表（四判据逐条：`pipefail`／非末段多次 `write()`／末段提前退出／rc 被消费），并把我对 `run-wpftextdemo.sh:956/957/1258` 的"够不着/不影响判决"判断**实测复核**（证实或推翻）；③ 每处修法给 **diff ＋ 成对读数**（真阳性仍红／真阴性仍绿）；④ 弄瞎牙 ⇒ `NOINFO`（**不是绿**）。
- **W33B**：① `D-G41` 自证的**成对读数**（正常 ⇒ `PASS`；**自测期间改写该件**（沙箱副本）⇒ `NOINFO` 且点名）；② "裸基线"推广**必须先有扰动实证**（没有实证不许改）；③ 12 件收工表：`cases`/`total`/`pass` **只增不减**、`fail`/`not-as-expected` = **0**。
- **W33C**：① 3 条逐条点名（可复算的取值路径）；② 同一性判据（**不靠名字像**）；③ "已登记/未登记"的**原文对照**；④ 成因侧判断 ＋ **可证伪的实验方子**（写清"跑什么、期望什么、能区分哪两种假设"）；⑤ 裁定建议（登记 vs 修，两条都给 ＋ 撤登记条件）。

## §4 停条件（**触发即停、如实上报**）

1. 九位出现 `{'pf'}` **之外**的位移（尤其 `pc`/shim ⇒ 说明有人碰了产品件）。
2. `verify-all.sh` 的步数或声明块被**车道**改动（那是主控写域）。
3. W33A 的牙**金丝雀不活**却报 `PASS`；或它把"够不着"的站点**当高危**改掉（= 无据扩大射程）。
4. W33B 的 `--selftest` 出现 `fail`/`not-as-expected` ≠ 0，或 `cases`/`pass` **减少**（= 放宽）。
5. W33C 拿不到 `/tmp/frame-step/*.log` 或它的 mtime 不属 `#32` 波尾 ⇒ 停（不许拿旧趟当本轮）。
6. 应用门禁出现 `result=PASS` 少于 **6/6**；或 `verify-all` 任一趟不绿。

## §5 资源与内存纪律

- 并行车道上限 7；本波**没有**独占构建者（三条车道全零 `dotnet`）⇒ 主控的波尾链是**唯一**的构建动作，跑链时**不许**再有车道在跑（**它会在链前确认三车道都已收工**）。
- **预警必须同时看 `swapfree`**：`#30`／`#31` 两次 `swapfree=0MB` 而 `avail` 健康；`#32` 是 `swapfree` 谷底 **70 MB**、`avail` 谷底 1083 MB（**未到 0**）。
- 零 `dotnet` 车道**不许跑会自行构建的步骤脚本**；纯读者件的 `--selftest` 可以跑。
- **不许 `pkill`**；**不许 `pkill -f`/`pgrep -f` 下结论**（`#32` 现场：主控 `pkill -f 'w32-mem'` **把承载它的 shell 一起杀了**）；数进程用 `pgrep -c -x <名>`。
- **不许 `ln`/硬链接**；沙箱 `cp -p`；长循环 `nice -n 15`。
- ⚠️ **零 `dotnet` 车道不许写 route 件**（`KNOWN-DEFECTS.md`／`docs/CURRENT-STATE.md`／`handoff.md`／`ACCEPTANCE-BASELINE.md`）—— 会给出**真红**（新编号未登记）。

## §6 收官清单（顺序不可颠倒 —— 纪律 46）

- [ ] W33A：牙 ＋ 精确站点表 ＋ 高危点修复（含 `integration-wave.sh` 那两处**假绿**）
- [ ] W33B：`D-G41` 自证落地 ＋ 裸基线推广（有实证者）＋ 12 件收工表全绿
- [ ] W33C：3 条结构族红的裁定建议（登记 vs 修）
- [ ] **主控**：★C 两个读数（**已取**，见 §7）＋ 若需接线则同趟落 ＋ `close-wave` ⇒ 五臂 ⇒【零构建窗口】⇒ `verify-all` ×2 ⇒ 门禁 ×2 ⇒ **重冻 `#33`** ⇒ 文档五件
- [ ] 流程瑕疵复盘：**先预登记再派单**（本波反了顺序）

## §7 主控已取的 ★C 读数（开工当趟，供收官引用）

**① `hidden-only-step.sh --selftest`（真树一趟）**：`$HOME/w33m-run/hidden-only.selftest.log` —— 逐例 `S1`–`S12` 全 `=> yes`，含 `S12-restore expect=IDENTICAL got=IDENTICAL（cmp 逐字节复原 b877ff3e3437145a）`。**收尾汇总行（已取到）**：`HIDDEN_ONLY_SELFTEST=PASS cases=16 pass=16 fail=0 skip=0`、`rc=0`、`real 5m33.395s`。逐例要点：`S12`（真实旧产物 `pc=476994e35d31a7e1`）`expect_rc=1 got_rc=1` 且 **`S12-attrib` 目标 4 格全在红名单**（`不符=28`，脚本自己注明"不要求恰 4 格红"）｜`S13`（私目录放权威 `pc` 副本）`rc=0` = **装置健全性闸**｜`S14` 成对读数「原脚本 `rc=1` 真红 ｜ 放宽副本 `rc=0` **假绿**」⇒ 牙的判别力有成对证明。⚠️ 它是本波**唯一**的构建动作（要编 `D5CbrProbe` 并拉 runner）⇒ 与"零 `dotnet` 车道"并行是安全的，但它**证明了** `#32` 记的"该件自测绿是 `#30` 的读数、不是本波的"那条"未取到"**本波已补齐**。
**② `close-wave.sh` 的 `IN_FP` 窗口「成对实验」**（`#31` 记的"只有推理、没有读数"这条洞，本波补上）：
用**同码路径**（`source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh)` ＋ `cd` 进沙箱根）在最小沙箱树上采样两次，中间**故意改一个覆盖面成员**：
```
IN_FP_0 = cf8135ce224cdd242a320cf174506d1d001a20d6aae6bb3a0d9f3cdd600de5ce
（在两次采样之间往 build/MilBridge/tools/tline-gate.sh 追加一行）
IN_FP_1 = d71c233d7dd6a436c79bc99996f7b9a60996f14a9edc756ac2571b6aa5726bea
⇒ 不相等 ⇒ close-wave.sh 的 [4/6] 会 say「❌ 输入稳定性」并 exit 5 —— ✅ 正是它该做的
阴性对照（不手改）⇒ 两次逐位相同（bab9be7f4ba1c85ccc2612fb4f4fc38244d6b23341474df2f932df62dd062dcc）
```
⚠️ **射程如实标注**：该实验在**最小沙箱树**上做（成员集被缩小到"会被 `find` 命中的那些"），它证的**是机制的判别力**（"窗口中间手改 ⇒ 必判不相等"），**不是**"真树那 120 件件都这样"（后者是同一函数、同一码路径 ⇒ 传递性成立）。

## §8 收官（待填）

## §8 收官（`#33` 完成，2026-09-18 16:2x）

**`#33` 已重冻：整份 `sha16=c6b4961ecab48bd3`（425,148 B）**；机器行核对 `rc=0`、`BASELINEGEN=PASS decl_gen=#33 file_newest_gen=#33`、`BASELINEDUP=PASS`。
**两趟 `verify-all` 各 `rc=0` / **23 步** / 871 通过 / 2 跳过 / `SKIP_GUARD=PASS`，结论区逐字相同**（唯二差异 = 根目录那一行的时间戳与 `[0]` 步『启动 Xvfb』↔『复用已有』）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**（`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_BRIDGE_SRC_STALE=no`）；五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7` ＋ `GATE_PROBE=PASS` ＋ `GATE_COLUMN=PASS` ＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂）**。
**§2 位移预测 vs 实际**：九位 **`changed == ['pf']` 逐字命中预测**（`a1ce403a74225f10 → 445a278b4a17ba07`，波尾重编）；**`pc`/shim/桥逐位未动**（本波不碰产品件）；`inputs_fp` **设计性变更** `2b6e4df8… → dc47e9751e0e1405…`（成员 **120 → 121**）；`verify-all.sh` **22 → 23 步**（预测写的是"视接线而定"⇒ 命中）。**§3 停条件①–⑥ 一条未触发。**
**新第 `[17]` 步 `PIPEFAIL-SIGPIPE` 在真趟里是绿的**：`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=1 files=56 sites=73 hit=1 low=10 diag=2 safe=60`（两趟逐字相同）。
**本波三条实质**：① **一个"已被写进结论的不准推理"被推翻**（`#32` 的"小串安全"）⇒ 顺着它把那一族**扫穷尽 ＋ 修 57 处**（其中 `integration-wave.sh` 两处是**假绿**方向）＋**建牙接线**；② **`--selftest` 第一次有"我在跑的时候自己有没有被改"的自证**（11 件）＋ 三处"前提会消失却照印通过"修成 `NOINFO`；③ **3 条结构族红"红着但没登记"这个判断被推翻** —— 早已登记在两本册子，陈旧的是判据件自己那句话；根因 `D-T4` 的"需 Windows 重录"半句**今天不成立** ⇒ **`D-T4` 可直接修**（`#34` 头号）。
**登记与覆盖面**：声明表 **77 → 79**（`D-G42`/`D-G43`）｜`fp_inputs()` **120 → 121**｜`known-red-frame-structural.md` **身份表重锚**（`pc`/判据脚本/三份读数日志的 sha）。
**主控自纠（本波又 2 处，累计 6 处）**：⑤ **`pkill -f 'w32-mem'` 把承载它的 shell 一起杀了**（自匹配）⇒ 改成按 pid 停；⑥ **"按 pid 停"的脚本仍然自杀了第二次** —— 判据是"命令行文本里含那个模式"（我的 `bash -c` 里写着 `w33-mem.sh`）⇒ **真正的护栏是"排除自己的进程树"，而不是"换成 pid"**。⑦ 我用 `sed` 生成波尾脚本时 `#` 分隔符与引号冲突 ⇒ 生成出 **0 字节脚本**并跑了一次"什么都没做"，`rc=0` 一度被我读成"文档已更新"（**"空脚本 rc=0" 是最像成功的一种失败**）⇒ 已改为 Python 生成 ＋ 收工自检逐件打印 sha16。
