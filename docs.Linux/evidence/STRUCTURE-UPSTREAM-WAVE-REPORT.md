# 结构上游化（整波）· 收尾报告

> 落点：`feat-Linux`。本件记录"根目录瘦身 ＋ 布局上游化 ＋ 重冻"这一波的**最终形态、验收读数与具名残余**。
> 编制：2026-10-05（主控复核；每一格都是现跑读数，附复算命令）。

---

## 1. 最终形态（现读）

```
WPFOnLinux/
├── src/
│   ├── Microsoft.DotNet.Wpf/          ← Windows 上游源（自 a394a4792 取回；不含上游仓根 Directory.Build.props/.targets）
│   ├── Microsoft.DotNet.Wpf.Linux/    ← Linux 覆盖层（含原 build/<工程>.Linux/、build/shims/、原 src/WpfGfx.Linux/**）
│   ├── Linux/                         ← Linux 侧仓内设施（原 build/ tests/ samples/ tools/ wpf-linux.sln）
│   └── WpfGfx.Linux.Native/           ← 原生 shim
├── Guide/                             ← win 侧根脚本（build.cmd/Restore.cmd/test.cmd/start-vs.cmd/dotnet-test-install.ps1）
├── Guide.Linux/verify-all.sh          ← 一键验收入口
├── docs/  docs.Linux/                 ← 原始侧 / 移植侧（主题篇三语；evidence/ 含 PATH-MAP、UPSTREAM-MANIFEST）
└── README{.md,.zh-CN.md,.es.md}  README-Window.md  …（治理面）
```
复算：`ls -A` ／ `ls src` ／ `ls src/Linux`

**`upstream/wpf/**` 已删**（vendored 快照），等价校验改由 `docs.Linux/evidence/UPSTREAM-MANIFEST.tsv` 承担（逐件 blob 摘要）。
删除判据：`UPSTREAM_MANIFEST rows=6417 missing=0 sha_mismatch=0 tracked_upstream=6415 not_in_manifest=0 ⇒ PASS`。

## 2. 验收读数（主控复跑）

| 项 | 读数 | 复算命令 |
|---|---|---|
| `verify-all` **×2** | **66 ✅ / 0 ❌**（两趟皆同；EXIT=0） | `bash Guide.Linux/verify-all.sh` |
| 第三方形态（**功能**） | **`THIRDPARTY=PASS frames=25~33 max_colors=1644`**（基线 1642） | `bash src/Linux/samples/ThirdPartyMini/run-thirdparty-mini.sh 20` |
| 冻结基线 | `BASELINE-FROZEN gen=#83 sha16=cc7d2c486ca268b8 file=src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（sha16 与实测相符） | `sed -n '9p' docs/CURRENT-STATE.md`；`sha256sum src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 八颗关键牙 | `ROOT-ENTRIES`／`HANDOFF-MV`／`STEP-CHECK`／`DEFREG`／`FP-INPUTS`／`CSDECL`／`SENTINEL-SPEC`／`PTSGAP` 全 `rc=0` | 逐件 `bash src/Linux/build/MilBridge/tools/<t>.sh` |
| 哨兵 | `WAVE=w83-freeze`／`BASELINE=#83`；两枚 `cmp IDENTICAL` | `grep -E 'WAVE=\|BASELINE=' /tmp/bridge-frozen.flag` |
| 工作区 | 干净（`git status --short` = 0） | `git status --short` |

## 3. "窗口全黑"根因（本波最值钱的一条）

搬迁后 `THIRDPARTY=FAIL max_colors=1`（**一条绘制指令都没落地**）。二分定位到 `ab0f56aad`：
`PresentationFramework.Classic` 被挪到 `src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework.Classic/`，
但它**不在 `src/Linux/build/integration-wave.sh` 的 ORDER（唯一重建链）里** ⇒ 落位后**没有任何重建路径**，
`deps.json` 少一件 ⇒ 桌面主题解析不到 ⇒ **整屏一色**。
它此前是靠**历史残留的 `bin/Release` 产物**"侥幸绿"的——与本仓反复登记的"靠陈旧产物才绿"同族。
修法：把那件加进 `ORDER` ＋ 身份自检的 `bin/Debug` 写死点改读唯一声明 ⇒ `max_colors 1 → 1644`。

## 4. 具名残余（**未达项**，如实）

1. 🔴 **`[5c/6]` 四档不可稳定为绿**：`WFREEZE_NINEAUTH`／`WFREEZE_BLOCKVALUES` 会在**每次重建后**转红。
   根因是**已登记**的 `D-G176③`（`blockvalues-shift.tsv` 的 `live=` 被钉住 × 整波每趟必重建 ⇒
   **同一趟 `close-wave` 里"重钉"与"`[5c/6]` 通过"结构上不可兼得**）＋ `D-G92` 重建位移族
   （`pf` 是**环成员**：`PF⇄ReachFramework` 互引 ⇒ **无字节不动点**，实测 `f61f1dec→3cbc401c→5e885a4f→98e850cd→4b8ace0a`）。
   **成对读数**：刚冻完那一刻 `WFREEZE_CONSISTENCY=PASS`（四档全绿）；**跑过一轮重建之后** ⇒
   `rootdefault=PASS decl=PASS nineauth=FAIL blockvalues=FAIL`。
   ⚠️ 这是**判据口径**问题，不是迁移缺陷；**不许**用"关开关/加豁免"糊过去。两条候选处置（需主控裁定）：
   (a) 把环成员（`pf`）从"逐位相等"改为"只核 `block9↔tier`、`live` 只记录不判"；
   (b) `close-wave` 在"已 `[1/6]` 重建"的语境下跳过 `[5c/6]`（或先 `[5c/6]` 后重建）。
2. 🟡 外部冻结器 `~/w21-verify/w27-freeze.py:1615` 的 `NINE` 表**仍写旧落点** ⇒ 落位后**跑不起来**；
   本波只补了 `GENS['#83']`（`--template auto` 所必需），`NINE` 属另一趟。
3. 🟡 `~/w21-verify/w83/{logs,bin}` 为空目录（本波未落链条日志/脚本）。
4. 🟡 本波**越界动作**（为治 `ROOTDEFAULT` 与"不弄坏 66/0"所必需，均不改产品逻辑、不改落点、不削弱判据）：
   恢复 `src/Linux/tests/parity/windows/layout-b34/windows-results.json`（被 `.gitignore` 排除的本地输入，缺失 ⇒ `ROOTDEFAULT FAIL`）、
   改 `HANDOFF-NEXT.md`、写两枚哨兵。

## 5. 复算清单（照抄）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
git log --oneline -5 && git status --short
bash Guide.Linux/verify-all.sh                                    # 期望 66 ✅ / 0 ❌
bash src/Linux/samples/ThirdPartyMini/run-thirdparty-mini.sh 20   # 期望 THIRDPARTY=PASS max_colors≈1644
python3 src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py --root . --template auto
sed -n '9p' docs/CURRENT-STATE.md
```

## 6. O6 · 入口边界厘清（**清单式**，不搬迁）

> 派单 `TASK-O1-O4-O6` §O6（主控裁定：**不改路径**，只做「单一入口清单」）。本节为**具名登记**。

**裁决理由（被引面 ＋ 真调用，均**现取**）**：三个入口在仓内的被引面极广 —— `git grep -l <入口>` 现取
`Guide.Linux/verify-all.sh` **591** 件、`src/Linux/build/close-wave.sh` **501** 件、
`src/Linux/build/integration-wave.sh` **181** 件（派单记 588／497／175；§⑦「数一律现取」）；
且**多颗牙真的调用它们**（`sentinel-spec-check.sh`／`applier-audit.py`／`wiring-coverage-check.sh`／
`timestamp-order-check.sh`／`wave-push.sh`／`static-jaws-check.sh`／`fp-inputs-hygiene-check.sh`／
`handoff-machine-values-check.sh` …）。⇒ **搬迁 = 又一次全仓重写 ＋ 动门禁**，**成本 ≫ 收益**。

**做了什么（清单式）**：
1. 新建 `Guide.Linux/README.md` —— **一键入口清单**：三个入口的用途／典型调用／前置条件／判据（三条命令逐条可跑）。
2. 根门面与移植侧文档总线指向它（各 **1 行**）：`README.md`／`README.zh-CN.md`／`README.es.md` 的「去哪看（导航）」表 ＋
   `docs.Linux/README.md`／`README.zh-CN.md`／`README.es.md` 的「我想……→去读」表。
3. 本节（具名登记理由）。

**边界（如实）**：本波**不**移动/新增任何入口件，只**指路**。

