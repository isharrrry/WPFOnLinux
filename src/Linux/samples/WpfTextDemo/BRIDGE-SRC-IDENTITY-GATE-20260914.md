# 桥→源 身份闸门（`src/** → 桥`）· 实跑真阳性记录 — 2026-09-14（T3）

**一句话**：这道闸门**上线第一次实跑就抓到了与"事故 D"同一类的事** —— `src/**` 已改、部署的桥未重发。
不是仪器坏，是**真阳性**（主控 2026-09-14 已核对确认）。

## 1. 为什么加这道闸门（漏洞本身）

- **事故现场**：`#6` 冻结用的桥是 **22:24:35** 发的，而 T2b 在 **22:37:39 / 22:37:52** 改了
  `src/WpfGfx.Linux/Rendering/{SkiaRenderBackend,DrawInstructionCensus}.cs`
  ⇒ **#6 的桥不含那两个修法**，而当时**所有读数看起来一切正常**。
- **为什么没有闸门能发现**：`WFP_SRC_STALE` 只看 `build/*.Linux/**`（且只在 probe runner 里、还是 advisory）；
  `hbtextline_shim_stale` 只看 `build/shims/**` ⇒ **`src/** → 桥` 这条链上没有任何覆盖** ⇒ 静默陈旧。
- **判据依据（直接测量）**：主控实测 **AOT 发布逐字节可复现** —— 同一份源、同一 `ArtifactsPath` 连发两次
  `ndiff=0`；`-t:Rebuild` 全量重编后**仍是同一 sha** ⇒ "源指纹相同 ⇒ 产物 sha 相同"有实测支撑，
  不是代理指标。

## 2. 实现（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh`）

| 位 | 何时跑 | 判据 | 红/绿语义 |
|---|---|---|---|
| **便宜位** `WPTD_BRIDGE_SRC_STALE` | **每趟默认算** | 发布目录 `bridge-src-fp.txt`（发布时写入的源指纹）vs **现树重算** | `yes` = 部署的 .so 不是当前源编的 ⇒ **本趟读数作废**；这是 **advisory**（不单独判红），但**必须打出来** |
| **直接测量位** | 只在 `--bridge-identity-selftest` | 同一 `ArtifactsPath` 重发，比"重发前/后 sha" | `DIFF` = 判红 |
| 辅助位 `so_file_match` | 每趟默认算 | fp 文件记录的 `BRIDGE_SO_SHA256` vs **实际部署的 .so** | `no` = 发布后件被换过 |

- **指纹实现只调** `build/bridge-src-fp.sh`（主控指定"**唯一实现**"）——
  **禁止内联重写**：两份实现迟早漂移，而漂移的表现恰好是"红/绿取决于谁算的"，**比没有闸门更坏**。
- **⚠️ `bridge-src-fp.txt` 缺失 / 解析不出 ⇒ `NOINFO`（无信息），绝不许报 `no`**。
  依据：本项目"缺读数被当绿"已发生两次（`hbtextline_shim_stale` 按构造恒 `no`；桥契约对**整行**判 `[`）。
- **⚠️ 牙的语义突变边界**：必须改**语义**（常量/参数序）——**AOT 会丢注释**，
  **只改注释不会改 sha** ⇒ 那种突变会让"能变红"这一极成为**假绿**。这条已写进脚本注释。
- 落锁协议：直接测量位会重写 `.so` ⇒ 跑前 `: > /tmp/bridge-republish.lock`、跑完 `rm -f`
  （T1b/M7b 已被告知"见锁不开跑加载桥的东西"）。

## 3. 真阳性实跑读数（**逐字**，2026-09-14 00:15 前后，`~/wfp-runs/smoke-fp6`）

```
WPTD_ARTIFACTS bridge_sha=f68f01c10e456982 bridge_bytes=4950336 pc_sha=23567d420f0dbbaa pf_sha=bfb10fe2a01a986b provider_sha=71ba86c6495347fe win32shim_sha=f84d65a62e0c7fa4 wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=5a04875ae87a294d hbtextline_shim_stale=no hbtextline_stale_basis=auth hbtextline_src_mtime=1789309064 pc_compare_mtime=1789309385 windowsbase_sha=8c073fab0da88169
WPTD_BRIDGE_SRC_STALE=yes basis=pub=0dec99db900ef654 now=ffb56d3bacd3d152 so_file_match=yes
   ⚠️ 桥→源：**部署件比当前源旧**（pub=0dec99db900ef654 now=ffb56d3bacd3d152）⇒ 本趟读数作废，先重发桥再重跑
WPTD_TIER_SUMMARY=minimal passed=0/3 failed=3 inconclusive=0
WPTD_SUMMARY=NOT_RUN（本次只跑了诊断档）
WPTD_GATE=FAIL acceptance=0/1 line_advance=NA
WPTD_BRIDGE_SRC_STALE=yes basis=pub=0dec99db900ef654 now=ffb56d3bacd3d152 so_file_match=yes
```

**我判定的依据（三步，全部可复核）**
1. `bash build/bridge-src-fp.sh`（**唯一实现**，不是我的重写）现树实跑 = `BRIDGE_SRC_FP=ffb56d3bacd3d152 BRIDGE_SRC_N=77`；
2. 发布记录 `…/release_linux-x64/bridge-src-fp.txt` 写的是 `BRIDGE_SRC_FP=0dec99db900ef654 BRIDGE_SRC_N=77`、
   `PUBLISHED_AT=2026-09-14T00:00:07+08:00`（`N` 相同 ⇒ 没有增删文件，是**内容**变了）；
3. `find` 出**发布之后**被改过的桥输入文件（排除 `bin/obj/.artifacts/tests/alt-route-b/spike`）：
```
2026-09-14 00:13:42.3804031200  src/WpfGfx.Linux/Rendering/VisualBrushSource.cs
2026-09-14 00:14:14.2080440680  src/WpfGfx.Linux/Rendering/SkiaRenderBackend.cs
```
⇒ T2b 的"矩阵组合空间同族扫荡"在发布**之后**又改了这两份 ⇒ 部署件 `f68f01c1…` **不含**这两次改动。
**注意 `so_file_match=yes`**：fp 文件记录的 .so 与实际部署的 .so **一致** ——
即"发布动作本身没问题"，出问题的是**源在发布之后又动了**。两个位各管一件事，这里恰好只红了该红的那个。

**处置**：主控裁定**先不冻 `#7`**，等 T2b"源已定"→ 重发桥（新 sha）→ 更新 `/tmp/bridge-frozen.flag` → 再由我**一轮跑完**。
（用旧桥先跑一遍会被作废，还白占应用槽。）

## 4. 牙 A：便宜位谓词三极性（**不碰桥、不跑应用**）

`bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh --bridge-fp-selftest` ⇒ **PASS**：
```
BRIDGE_FP_SELFTEST 缺失=NOINFO（basis=no-file，期望 NOINFO/no-file）｜ 值不符=yes（期望 yes）｜ 值相符=no（期望 no）
BRIDGE_FP_SELFTEST 身份谓词 同=SAME 异=DIFF 缺=NOINFO ｜ so_file_match 缺文件=NOINFO
BRIDGE_FP_SELFTEST=PASS（缺失⇒无信息、不符⇒yes、相符⇒no；身份谓词三极全对）
```
**最关键的是第一极**：文件缺失时报的是 **`NOINFO`**，不是 `no` —— 这正是本项目栽过两次的那一极。
（造临时目录做三极，**不触碰真桥**。）

## 5. 牙 B：直接测量位（重发三连）—— 设计

`bash …/run-wpftextdemo.sh --bridge-identity-selftest --no-build`
极性：① 重发**两次** ⇒ `SAME`（幂等）；② **语义**突变 `DrawInstructionCensus.cs` 的 `MaxGeomLines 60→61` ⇒
便宜位 `yes`、重发后 sha `DIFF`（闸门必须红）；③ 还原 ⇒ 重发 ⇒ **sha 逐字节回到基准**、便宜位 `no`。

**健壮性（防被"移动的树"骗）**：基准取**重发一次之后**的产物（不是重发前的部署件）——
牙测的是"同源重发 ⇒ 逐字节相同"这条**仪器前提**；牙跑期间若现树指纹变了（有别的车道在改），
判 **`INCONCLUSIVE`（exit 3）**，**不当 FAIL 也不当 PASS** —— "仪器没能稳定采样" ≠ "牙坏了"。
哨兵不一致只作为**证据**打印，不算牙的失败。

**安全**：`src/**` 不是我的车道 ⇒ 突变前备份源码**与**部署 `.so`，`trap`（EXIT/INT/TERM）保证还原，
还原后校验源码 sha 与原值一致；最后一道网是从备份恢复 `.so`。**回报里会写明是否动用了这道网。**

### 5.1 牙 B 实跑（2026-09-14，新哨兵 `c66083443200115d` / `FP=ffb56d3bacd3d152`）⇒ **PASS**

```
部署件 SO_DEPLOYED=c66083443200115d ｜ 哨兵 SHA=c66083443200115d FP=ffb56d3bacd3d152 ｜ 现树 FP=ffb56d3bacd3d152
部署件 == 哨兵声明 ✅      现树源码指纹 == 哨兵声明 ✅
① 建立基准（重发一次）：c66083443200115d → c66083443200115d rc=0 ｜ 现树 FP ffb56d3bacd3d152 → ffb56d3bacd3d152
① 幂等重发：c66083443200115d → c66083443200115d ⇒ SAME（期望 SAME）rc=0
② 语义突变：private const int MaxGeomLines = 60; → 61，文件 sha 0894965736c60d7a→1a46f59ae7463aef，便宜位 BRIDGE_SRC_STALE=yes（期望 yes）
   突变后重发：after=6e3ca80907fbc1b8 ⇒ DIFF（期望 DIFF ⇒ 闸门必须红）rc=0
③ 还原源码：sha=0894965736c60d7a，便宜位 BRIDGE_SRC_STALE=yes（期望 yes：上次发布是突变版）
   还原后重发：after=c66083443200115d ⇒ SAME（期望 SAME 且逐字节回到基准 c66083443200115d）rc=0
   便宜位终值 BRIDGE_SRC_STALE=no（期望 no）
[tooth] 源码已还原并校验：DrawInstructionCensus.cs sha=0894965736c60d7a ✅
[tooth] 锁已释放：/tmp/bridge-republish.lock
BRIDGE_IDENTITY_SELFTEST=PASS（直接测量位能红能绿；便宜位也能红能绿；还原后 sha 逐字节回原值）
```

**这趟牙同时独立复证了主控的"AOT 发布逐字节可复现"**：同源连发两次 sha 相同；
**改一个语义常量（60→61）⇒ sha 变**；还原后 ⇒ **sha 逐字节回原值**。⇒ 闸门的两条腿都不是空判据。
**牙后状态复核**（主控要求）：部署 `.so=c66083443200115d` ✓、现树指纹 `=ffb56d3bacd3d152` ✓、
`DrawInstructionCensus.cs` sha `=0894965736c60d7a`（= 原值）✓、锁已释放 ✓、**无残留 `MaxGeomLines = 61`** ✓
（最后一道"从备份恢复 .so"的网**没有被动用** —— 三次重发自己就回到了原值）。

**⚠️ 突变边界（实测确认）**：`60→61` 是**语义**改动，它的确改了产物 sha；
反过来说 —— **只改注释不会改 sha（AOT 丢注释）**，那种突变会让本牙"能变红"这一极变成**假绿**。

## 6. 边界与状态

- 便宜位是 **advisory**（主控口径），但**缺失 ⇒ `NOINFO`**，绝不当绿。
- **只改了 runner**（我的车道）；`src/**` 仅由牙在**临时突变+还原**的意义上触碰。
- 本次冒烟顺带跑到诊断档 `minimal`（`passed=0/3`）：该档的可视树**故意没有**本样例特性控件，
  runner 对"特性色"这条判据**显式标不适用**；且我的新增代码只在
  ① 两个 selftest 早退分支 ② 装配阶段 echo ③ 末尾汇总 echo，**不参与任何档位判据** ⇒ 与它无关（未深究，非验收档）。
- **状态：等主控 ③（新 sha 哨兵）→ 一轮跑完**：门禁 + 冻 `#7` + RTL 三条 + `tline` 六项 + `--only=textbox-edit` +（顺路）真走到 EOP 分支的 dump。
- `getTextRunSpans`（T1b 核实）：调用点全在 PresentationFramework，**离线取不到** ⇒ 必须在
  `--only=textbox-edit` 那趟取并贴 `HB_TEXTLINE …` **整行原文**（现有落盘那趟是 `getTextRunSpans=0`、
  `lines=1/paragraphs=1/fallbackCalls=1`）。
