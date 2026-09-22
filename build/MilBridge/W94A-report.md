# W94A 报告 —— 波 `#50` 收尾链**前半段（步骤 1–4）**

> 车道 **W94A** ｜ 2026-09-22 **15:02 → 15:4x +0800** ｜ kernel 6.8.0-138-generic ｜ `nproc=3`
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）
> **范围 = 步骤 1–4**：①整波重建/应用 → ②WIC 权威件同步 → ③重取五臂 → ④`repin-generation.py --why` 重钉。
> **后半段（门禁 ×2 → 冻前 `verify-all` → 冻结 `#50` → 冻后 ×2 → 记录 → 推送 → app-local 刷新）由 `W95A` 接手，本件未做。**
> 判据**先写、读数后取**：本波所有预测都写在 `~/w94a/STATUS.md`（追加式，逐条带时刻），**先于**对应读数。
> 交付另含 `~/w94a/STATUS.md`（接力用断点续跑台账）与 `~/w94a/logs/*.log`（六趟原始输出）。

---

## §0 结论摘要（先看这五条）

1. **步骤 1–4 全部跑完，四步 `rc` 全 `0`**（整波 ×4 趟、WIC 同步、五臂重取、世代重钉）。
2. **本波九位位移 = `pc`／`pf`／`win32shim`／`wic_shim`／`dwf` 五位**（`bridge`／`windowsbase`／`provider`／`hbtextline` 逐位未变）。
3. 🔴 **`pf` 不是可复现值**：**四趟逐字相同的整波重建给出四个不同的 `pf` sha16**（`881c56e26808269f`／`decd920092287b03`／`581c864a7f2ad36c`／`f34bc297d19778fd`），
   而 `ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同**、隔离 `-t:Rebuild` 连跑两次**同值**。
   ⇒ **冻结块里 `pf` 那个数字不构成"构建身份"**，见 §3（本条是本趟最要紧的发现，直接落在 `W95A` 的冻结动作上）。
4. **任务书给我的一栏"`#49` 冻结值"有四处不是 `#49` 冻结值**（`pc`／`pf`／`win32shim`／`wic_shim` 四个数其实是**本波现树值**），见 §2.1。本报告一律以 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN #49` 块为准。
5. **五臂重取：只有 `tline` 一个文件变字节，且 100% 可归因于"运行相关字段"**（app-local 同步行、耗时、被同步的权威件 sha、自指 artifact、日期戳文件名、`mktemp` 路径）⇒ **不是产品位移信号**；其余四臂与 `#49` 冻结值**逐位相同**。

---

## §1 步骤 1–4 逐步读数（命令 + `rc` + `HEAVYSLOT=` 行 + 耗时）

原始日志：`~/w94a/logs/`（`01`/`01b`/`01c`/`01d`＝整波四趟，`02`＝PF 确定性实验，`03`＝重取五臂）。

### 步骤 ① 整波重建/应用 —— `build/integration-wave.sh`

命令（四趟逐字相同）：

```
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 600 -- \
  timeout 1150 env WAVE_OWNER=W94A bash build/integration-wave.sh
```

| 趟 | 日志 | `HEAVYSLOT=` 行 | `rc` | 耗时 | 「集成波结束」 |
|---|---|---|---|---|---|
| **1（正式）** | `01-integration-wave.log` | `ACQUIRED waited=0s` / `MEMOK avail=3054MB min_avail=1500MB` / `RELEASED rc=0 held=221s max_hold=1200s` | **0** | **221 s** | 失败步骤 **0** |
| 1b（复算） | `01b-integration-wave-2.log` | `ACQUIRED waited=0s` / `RELEASED rc=0 held=196s` | **0** | 196 s | 失败步骤 **0** |
| 1c（复算） | `01c-integration-wave-3.log` | `ACQUIRED waited=0s` / `RELEASED rc=0 held=195s` | **0** | 195 s | 失败步骤 **0** |
| **1d（最终整波态）** | `01d-integration-wave-4.log` | `ACQUIRED waited=0s` / `RELEASED rc=0 held=193s` | **0** | **193 s** | 失败步骤 **0** |

关键原文（四趟一致，逐字）：

```
APPLIER_AUDIT_SUMMARY appliers=27 ok=92 miss=0 red=0 rc=0
  身份自检：System.Xaml.dll / WindowsBase.dll / PresentationCore.dll / PresentationFramework.dll / DirectWriteForwarder.dll 全部「已签名(带公钥)」
  波前指纹 == 波后指纹 == f7e054ad91c07aed74c533b7a7dfa7adf6ef2d4a5aed51859fe1bbe772c6af5b
  ✅ 一致 ⇒ 本轮构建结果与"波后树"对得上（没有编辑竞态）
ARTIFACT_SRC_FP proj=PresentationCore     fp=3ae4746cd655023b n=1374 state=written
ARTIFACT_SRC_FP proj=WindowsBase          fp=0cf7e7daa70eb8a9 n=327  state=written
ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362 state=written
```

**为什么跑了四趟**（不是"多跑保险"，是**判据驱动的**）：第一趟后我算出 `dwf`（无任何源改动）也位移了，
⇒ 成立一个必须先答的问题：**"同一命令连跑两次是否同值"**（`#49` 先例：`W70A` 已证同值 ⇒ 值构成的位移才是信号）。
第 1b 趟就是这条两极化实验；第 1b→1c→1d 的追加由 §3 的 `pf` 漂移逼出来的（每趟的**预测都先写进 `STATUS.md`，再取读数**）。

### 步骤 ② WIC 权威件同步 —— `build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh`

**这一趟实际由整波的 `3.5/5` 步执行的**（口径唯一实现 = `check-applocal-sync.sh`；本脚本只执行它的结论）。
波内逐条原文（4 份 WIC 副本，来源全是 `#49` 冻结值 `56278c14b4ecd672`）：

```
REFRESH  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/libwpfwic.so  56278c14b4ecd672 → f7b3026c8c019be2  （权威 f7b3026c8c019be2；副本曾早 10576 秒）
REFRESH  build/MilBridge/.artifacts/bin/ClosedLoop/release/libwpfwic.so                       56278c14b4ecd672 → f7b3026c8c019be2  （副本曾早 184959 秒）
REFRESH  samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwic.so                             56278c14b4ecd672 → f7b3026c8c019be2  （副本曾早 166960 秒）
REFRESH  samples/ThirdPartyMini/bin/Debug/net10.0/libwpfwic.so                                56278c14b4ecd672 → f7b3026c8c019be2  （副本曾早 184959 秒）
APPSYNC-REFRESH=refreshed=79 newer=0 applied=1
APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0] DIVERGENT=0 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）
```

波后**显式复核**（本趟另跑，独立读数）：

```
$ bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh          # 干跑
  （没有 STALE / NEWER-DIFF / DIVERGENT 落单者：同类加载源副本都已是权威 sha）
  APPSYNC-REFRESH=refreshed=0 newer=0 applied=0                              rc=0
$ bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply
  APPSYNC-REFRESH=refreshed=0 newer=0 applied=1
```

⇒ **WIC 权威件同步完成且已收敛**（波前 `MISMATCH=61[STALE=61] DIVERGENT=3` → 波后 `STALE=0 DIVERGENT=0`）。
⚠️ 校验器仍 `exit=1`，因为 `UNEXPECTED=6[DECL-GAP-EQ=6]` 这一类**是登记在册的声明类缺口**（`close-wave.sh:159-160` 会长期打印 `[⚠️ APPSYNC 非 PASS]`）；
波前那一趟还有一个 `DECL-GAP-DIFF=1`，波后**收敛为 0**。**这不是新问题**，详见 `#49` 冻结块同一句。

### 步骤 ③ 重取五臂 —— `build/MilBridge/tools/retake-arms-w23.sh`

```
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 600 -- \
  timeout 1150 env ARMS_OUT=$HOME/w94a/arms bash build/MilBridge/tools/retake-arms-w23.sh

HEAVYSLOT=ACQUIRED waited=0s
HEAVYSLOT=MEMOK avail=2536MB min_avail=1500MB
ARMS_DISPLAY=:97 source=none ⇒ 自起 Xvfb
ARMS_DISPLAY=:97 source=self-started xvfb_pid=2345561（跑完按 PID 收回）
HEAVYSLOT=RELEASED rc=0 held=307s max_hold=1200s
ARMS_RC=0 elapsed=307s
```

脚本自报身份行（判"是不是同一棵树"）：

```
shim      = 921ba9c65e9fb3be      ← hbtextline，未变
pc        = 722e0ab8205b7c3f      ← 本波值
run.sh    = 711f39f468f61cc8      ← 未变
Parity.cs = 149dd986a642fdfc      ← 未变
```

**`:97` 由脚本自起**（`source=self-started`，PID 2345561）⇒ 不是 `D-G77` 的"没有 X 静默拿 X-混淆读数"那一形态。
收工核对：`pgrep -c Xvfb` = **0**、`pgrep -c dotnet` = **0**、`xdpyinfo -display :97` = **已收** ⇒ **残留进程 0**。

### 步骤 ④ 世代重钉 —— `build/MilBridge/tools/repin-generation.py`

```
$ python3 build/MilBridge/tools/repin-generation.py --check          # 重钉前
REPIN_GENERATION=FAIL n=2（逐处：）
  · generation.arm_logs.tline 不一致
  · generation.evidence_log_sha256 声明=2103f88183b17a6a 现场=6ce993ad974d32ad
                                                                      rc=1
$ python3 build/MilBridge/tools/repin-generation.py --why "$(cat ~/w94a/repin-why.txt)"   # 唯一一趟
REPIN_GENERATION=APPLIED
  generation.instr_run_sh     = 711f39f468f61cc8
  generation.instr_program_cs = 149dd986a642fdfc
  generation.instr_shim       = 921ba9c65e9fb3be
  generation.evidence_log_sha256 = 6ce993ad974d32ad
  entries[*].caliber 改动字段数 = 0
                                                                      rc=0
$ python3 build/MilBridge/tools/repin-generation.py --check          # 重钉后
REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致）
                                                                      rc=0
```

`known-red.json`：`a747b713532e7631`（65,143 B / 422 行）→ **`8a0c0f221e35f42b`**（68,538 B / 426 行）。
重钉前的备份：`~/w94a/known-red.before-repin.json`（`a747b713532e7631`）。

---

## §2 九位现场重算 + 逐位位移表

### §2.1 ⚠️ 先更正任务书里的一栏（否则 §2.2 会被读错）

任务书 §② 写的「相对 `#49` 冻结值」一栏给的九个数字里，**有四个不是 `#49` 冻结值**：

| 位 | 任务书写"`#49` 冻结值" | `ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN #49` 块**实际值** | 任务书那个数其实是 |
|---|---|---|---|
| `pc` | `5aa6361a5ba02991` | **`56ee75ced8d6aece`** | W88A 的**定向重建**值＝本波现树值 |
| `pf` | `2a5b7641f6fba0fb` | **`6375fabf89ac7fef`** | 本波**波前**现树值 |
| `win32shim` | `33352e5797031999` | **`c493639d15678803`** | W89A 落地后的现树值 |
| `wic_shim` | `f7b3026c8c019be2` | **`56278c14b4ecd672`** | W79A 落地后的现树值 |

（`bridge feef049e9d0e313a`／`windowsbase 2e4e46e539a72cd7`／`provider 1f9511a7ef395bfe`／`hbtextline 921ba9c65e9fb3be`／`dwf de2d555105b7d04b` 五个**两边一致**。）
**本报告一律以基线文件为准**（可复算：`sed -n '9,40p' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）。
若 `W95A` 沿用任务书那一栏做"位移对账"，会把 `pc`／`pf`／`win32shim`／`wic_shim` 四位**读成"未变"**。

### §2.2 位移表（现场 `sha256sum | cut -c1-16`，未手抄）

| 位 | `#49` 冻结值 | **波前现树** | **最终整波态（现值）** | 位移 | 字节数 | 可复现性（四趟整波） |
|---|---|---|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | **`feef049e9d0e313a`** | **未变** | 5,028,208 | — |
| `pc` | `56ee75ced8d6aece` | `5aa6361a5ba02991` | **`722e0ab8205b7c3f`** | **变** | 3,601,408 | ✅ 四趟同值 |
| `pf` | `6375fabf89ac7fef` | `2a5b7641f6fba0fb` | **`f34bc297d19778fd`** | **变** | 6,123,008 | 🔴 **四趟四值** |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | **`2e4e46e539a72cd7`** | **未变** | 1,111,552 | ✅ |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | **`1f9511a7ef395bfe`** | **未变** | 103,936 | ✅ |
| `win32shim` | `c493639d15678803` | `33352e5797031999` | **`33352e5797031999`** | **变** | 327,248 | ✅ 四趟同值 |
| `wic_shim` | `56278c14b4ecd672` | `f7b3026c8c019be2` | **`f7b3026c8c019be2`** | **变** | 74,984 | ✅ 四趟同值 |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | **`921ba9c65e9fb3be`** | **未变** | 293,165 | ✅ |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | **`ce3469f49efcbcfa`** | **变** | 39,936 | ✅ 四趟同值（**第 1 趟即到位**） |

复算命令（逐字）：

```
$R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so   → bridge
$R/build/PresentationCore.Linux/bin/Release/PresentationCore.dll                          → pc
$R/build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll                → pf
$R/build/WindowsBase.Linux/bin/Release/WindowsBase.dll                                    → windowsbase
$R/build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll             → provider
$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so                                             → win32shim
$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so                                          → wic_shim
$R/build/shims/PresentationCore.HbTextLine.cs                                             → hbtextline
$R/build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll                    → dwf
（配置口径 = `bash build/selfbuilt-config.sh` ⇒ **Release**，与 `close-wave.sh` 的 `SELFBUILT_CONFIG` 同一来源）
```

### §2.3 逐位归因

| 位 | 归因（源改动，逐条可查） |
|---|---|
| `pc` | **W88A 修 `D-G85`**：新应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py`（`b13172b944707620`）注入生成物 `build/PresentationCore.Linux/MouseDevice.Linux.cs` 的 `Capture(null)` 释放分支。⚠️ 定向重建给 `5aa6361a5ba02991`，**整波**给 `722e0ab8205b7c3f` —— 这正是 `#49` 冻结块里已具名登记的 **`D-G46` 族**（"同一个源、不同的构建范围/顺序会给出不同字节"），冻结取**整波值**。 |
| `pf` | **W86A `TASK-0304`/`TASK-0305`**：`build/PresentationFramework.Linux/reapply-patches.py` 生成 `FlowDocumentView.Linux.cs`／`PtsCache.Linux.cs`。🔴 但**位移的"值"不可复现**，见 §3。 |
| `win32shim` | **三条产品修法**（都进 `src/WpfGfx.Linux.Native/`）：① **W82A 修 `D-G83`**（`win32_core.c` `9aa0d2d1b1ed8d55` ＋ `win32_internal.h` `c3dbf6b936a36239`：抽 `wpf_ask_minmaxinfo_apply_hints` 并在首次 map 后重发 `WM_GETMINMAXINFO`/`WM_NORMAL_HINTS`，`DefWindowProcW` 那格回 no-op）；② **W89A 修 `D-G81`**（`win32_x11.c` `6477af56fdcfdf20`：新增 `PropertyNotify` 采纳 `_NET_WM_STATE` ＋ 幂等状态同步）；③ **W86A `A1`**（新增 `win32_pts.c` `e6559d0bba3c1044`）。 |
| `wic_shim` | **W79A `TASK-0502`**：`build/DirectWrite.Linux/wic-shim/wic_proxy.c` GIF 多帧解码＋帧时序（帧数与逐帧访问如实）。 |
| `dwf` | ⚠️ **没有可归因的源改动**：`build/DirectWriteForwarder.Linux/**` 本波**只有 `bin/Release/*.dll`/`.pdb` 变了**（无源、无 csproj、无生成物）；其声明引用（`WindowsBase` `2e4e46e539a72cd7`／`DirectWrite.Linux.Provider` `1f9511a7ef395bfe`／SkiaSharp）**逐位未变**。位移**只发生在第 1 趟整波**，此后三趟稳定在同一值 ⇒ 与 `D-G46` 族"构建范围/顺序"同形，**但本件未证到机制**（见 §7 NOINFO）。 |
| `bridge`／`windowsbase`／`provider`／`hbtextline` | **未变**（`hbtextline` 未变是设计：本波无零墨类改动 ⇒ `instr_shim` 仍 `921ba9c65e9fb3be`）。 |

---

## §3 🔴 `pf` 不是可复现值 —— 四趟整波四值（本件最要紧的发现）

### §3.1 读数（判据先写：预测写在 `~/w94a/STATUS.md` 的 `[STEP 1c]`／`[STEP 1d]`，先于对应读数）

| 趟 | `pf` sha16 | `ARTIFACT_SRC_FP proj=PresentationFramework` | 备注 |
|---|---|---|---|
| 1（15:07） | `881c56e26808269f` | `fp=5b38ea7420b26377 n=1362` | |
| 1b（15:13） | `decd920092287b03` | `fp=5b38ea7420b26377 n=1362`（**逐位相同**） | **与第 1 趟之间没有任何干预** |
| 1c（15:20） | `581c864a7f2ad36c` | `fp=5b38ea7420b26377 n=1362` | |
| 1d（15:2x） | `f34bc297d19778fd` | `fp=5b38ea7420b26377 n=1362` | **最终整波态** |

- 命令：四趟**逐字相同**（§1 步骤①那一行）；耗时 221/196/195/193 s，四趟都 `失败步骤 0`。
- `inputs_fp` 四趟的**波前==波后**都等于 `f7e054ad91c07aed74c533b7a7dfa7adf6ef2d4a5aed51859fe1bbe772c6af5b` ⇒ 树在每趟内是静止的（不是编辑竞态）。
- **最干净的一对是第 1 趟 vs 第 1b 趟**：两趟之间我**只**做了只读/归档动作（`cp` 归档旧臂日志、九位重算、`artifact-src-fp.py --check`、`sync-applocal-authority.sh` 干跑＋`--apply`「`refreshed=0`」），**没有动任何产品源**。

### §3.2 二进制级差异（把"到底差在哪"钉到字段）

`pf` 的两个不同构建件都在盘上（第 1 趟的件被 `3.5` 步刷进了 `build/ReachFramework.Linux/bin/Release/PresentationFramework.dll`）：

```
$ cmp -l <wave1件> <wave2件> | wc -l          → 72          （大小相同：6,123,008 B，两侧逐字节只差 72 字节）
差异簇（1-based offset）：
  137..140        4 B    = PE COFF `TimeDateStamp`（e_lfanew=0x80 ⇒ 字段在 136..139）
  5656773..5656788 16 B   = 元数据 MVID
  6119961..6119964  4 B   = 调试目录项
  6120045..6120060 16 B   = 调试目录项（PDB GUID/checksum）
  6120197..6120228 32 B   = 调试目录项（可复现构建的哈希项）
```

⇒ **不是"随机时间戳污染"**：两个 `TimeDateStamp` 都 ≥ `0x80000000`（Roslyn **确定性构建**的"内容哈希"形态；
`0x81DAC06D` 与 `0x895081A6`），即**编译内容本身**不同。R 不是 git 仓库 ⇒ 也不是 `SourceRevisionId`。

### §3.3 已做的排除（逐条都取过读数）

| 假设 | 实验 | 读数 | 判定 |
|---|---|---|---|
| H1「PF 工程就没开确定性」 | `dotnet msbuild -getProperty:Deterministic` | `Deterministic=true`／`PathMap=""`／`DebugType=portable`／`SignAssembly=true` | **否**（声明可复现） |
| H2「PF 单独构建就不可复现」 | 隔离 `dotnet build … -t:Rebuild` **连跑两次**（槽内，`held=84s`） | `PF1 = decd920092287b03`，`PF2 = decd920092287b03` | **否**（**PF 单独构建是确定性的**；⇒ 漂移由**波内别的一步**引入） |
| H3「`reapply-patches.py` 的 csproj 注入每波累积 ⇒ 输入变」 | 读 wave3 末 / 手跑一次 / 再手跑一次 / 读 wave4 step2 后 | `d3f54cd7c0354385` → `8dc2ac5475fe616e` → `8dc2ac5475fe616e`（饱和） → **wave4 step2 后回到 `d3f54cd7c0354385`** | **否**（csproj **每波末态可复现**；但**确实**暴露了 `reapply-patches.py` 对 csproj **不是幂等**这一独立事实，见 §7） |
| H4「源变了但指纹没看出来」 | `ARTIFACT_SRC_FP` 四趟对比 | `fp=5b38ea7420b26377 n=1362` **四趟逐位相同** | 指纹**看不见**这个差异 ⇒ 漂移落在**指纹覆盖面之外**的某个编译输入上 |

### §3.4 这对 `W95A` 的冻结意味着什么（请务必读）

- `#49` 冻结块的口径是"**冻结取整波值**"。本波实测该口径对 `pf` **没有牙**：整波值本身就是**每跑一次换一个**的。
  ⇒ 冻结块里 `pf` 那一格**不能当作"这份二进制就是这份源编出来的"的身份**；它只等于"冻结那一刻硬盘上是这个"。
- 我**没有**把这一点写成"已修"或"已绕过"：**本件零产品改动**（W94A 只在 §6 列的两个登记文件上写）。
- 建议（**供 `W95A`／主控裁定，不是本件的动作**）：冻前先跑一趟整波、**冻后立刻复算 `pf`**；若冻后那趟 `pf` 变了，
  则"冻后 ×2 全绿"里的 `pf` 一致性**不可作为判据**，而应把本条的复算命令（§3.1／§3.2）连同读数一起记进冻结块，
  并把"`pf` 构建不可复现"单独立项追（需要一条能看见**全部编译输入**的指纹，`ARTIFACT_SRC_FP` 现在的覆盖面不够）。

---

## §4 `inputs_fp` 新旧值 + 位移归因（清单式）

| 口径 | `inputs_fp` |
|---|---|
| `#49` 冻结 | `9f2199b212bed2b212035f87ff6006672605ff7bea6221c0be540301b1a8380b` |
| **波前 == 波后（四趟一致）** | **`f7e054ad91c07aed74c533b7a7dfa7adf6ef2d4a5aed51859fe1bbe772c6af5b`** |
| **重钉后（现树终值，`W95A` 用这个）** | **`f3fb5db87480ada8fd1502148f3c889549be756c0e60912bfc38109a4a3cc730`** |

复算命令（照 `close-wave.sh` 的 `fp_inputs()`，**不重写实现**）：

```
$ sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh > /tmp/fpfn.sh
$ bash -c 'source /tmp/fpfn.sh; fp_inputs'      # ⚠️ 该函数**自己**返回最终哈希；再套一层 sha256sum 会得到"哈希的哈希"
```

⚠️ **口径提醒（本件实测踩到）**：`fp_inputs()` 的内部管道已是 `… | sort | xargs sha256sum | sha256sum | cut -d' ' -f1`
⇒ **直接取它的输出**就是指纹（`close-wave.sh:281` 的 `IN_FP_0="$(fp_inputs)"` 即此意）。

### 归因：覆盖面 **147 件**（`#49` 时 **143 件**，本波 **+4**），其中 **12 件**在本波被改动/新增

覆盖面构成为现场点算：`src/WpfGfx.Linux/**` 70 ＋ `src/WpfGfx.Linux.Native/**` 41 ＋ `build/MilBridge/**` 17 ＋ `build/shims/**` 13 ＋ `build/DirectWrite.Linux/**` 2 ＋ `samples/ThirdPartyMini/**` 1 ＋ `build/port-lib.py`／`build/integration-wave.sh`／`build/close-wave.sh` 各 1 = **147**。
判"本波改动"的口径 = 覆盖面成员 `find <f> -newermt '2026-09-21 17:00'`（即 `#49` 冻结时刻之后）：

| # | 件（覆盖面成员） | 现值 sha16 | 改动者／性质 |
|---|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py` | `b13172b944707620` | **W88A** 新增应用器（`D-G85`） |
| 2 | `build/integration-wave.sh` | `0ac2eed4c66cd43d` | **W84A**（R-GATE 第 `[26]` 步接线）／**W91A**（`APPLIERS_EXPLICIT` 注册） |
| 3 | `build/close-wave.sh` | `f440ccdb4e29a942` | **W91A**：`fp_inputs()` 纳入两件 R-GATE 判据件 |
| 4 | `src/WpfGfx.Linux.Native/src/win32_pts.c` | `e6559d0bba3c1044` | **W86A `A1`** 新增源 |
| 5 | `src/WpfGfx.Linux.Native/src/win32_core.c` | `9aa0d2d1b1ed8d55` | **W82A**（`D-G83`） |
| 6 | `src/WpfGfx.Linux.Native/src/win32_x11.c` | `6477af56fdcfdf20` | **W89A**（`D-G81`） |
| 7 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | `c3dbf6b936a36239` | **W82A**（`D-G83`） |
| 8 | `build/MilBridge/known-red.json` | `8a0c0f221e35f42b` | **本件步骤④**重钉（`#49` 重钉件的后继） |
| 9 | `build/MilBridge/tools/product-entry-step.sh` | `4fdf5de43f1a211a` | `#49` 波尾（`W76A`，`9-21 17:21`，落在 `#49` 冻结**之后**） |
| 10 | `build/MilBridge/tools/build-hygiene-import-check.sh` | `545f3bd1d21b6ee8` | **W81A**（`build-hygiene-roster.tsv` 同趟） |
| 11 | `build/MilBridge/tools/r-gate-step.sh` | `23b6ee91a4a8dc9b` | **W84A** 新建（`D-G85` 的 `c06`）＋**W90A** 加强读数 |
| 12 | `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` | `93f914d6c041c88d` | **W84A** 新建装置 |

**`close-wave.sh` 自己就在覆盖面里**（点名成员）⇒ 改它必然改 `inputs_fp`（设计使然，`#28` 已登记）。
另注：**`build/shims/PresentationCore.HbTextLine.cs` 不在上表** ⇒ 逐位未变（`921ba9c65e9fb3be`），与九位表一致。

---

## §5 五臂重取读数（`ARM-LOG-SHA` 五行 ＋ 每臂通过/失败计数 ＋ 本该变/不该变）

### §5.1 五臂 sha16：新值 vs `#49` 冻结值

| 臂 | 本趟（重取） | `#49` 冻结 | 判定 | 本趟 `mtime` |
|---|---|---|---|---|
| `tline` | **`6ce993ad974d32ad`** | `2103f88183b17a6a` | **变** | 15:27:33 |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | 逐位不变 | 15:28:04 |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | 逐位不变 | 15:30:24 |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | 逐位不变 | 15:30:29 |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | 逐位不变 | 15:30:37 |

旧臂日志已归档（**`ln` 语义未被破坏**：`arm-logs/` 是 `ln -f` 硬链接进 `$OUT`，`links=2`）：
`~/w94a/arms-pre/*.log`，五件 sha16 **逐位对上** `#49` 冻结块的 `ARM-LOG-SHA` 五行（可复算的反极性）。

### §5.2 每臂通过/失败计数

| 臂 | 判词原文 | `rc` |
|---|---|---|
| `tline` | `通过 22 / 失败 2`（两条既有 ❌：`T3 Collapse 与真机一致`、`T3b 折叠明细契约级断言`） | 1 |
| `tab-zero` | `TAB_LINES 退出码=1（未登记失败 1 / 失败共 1）` —— 唯一失败 = `notab-control@w40@em24@RTL@tab0`（＝ `known-red.json` `entries[3]`，**在册**）；`START 最大差=0.0000` | 1 |
| `tab-anchor` | `START 红=0 绿=615 判定行=615 NOINFO=0`；`OVERFLOWED 红=0 绿=421 判定行=421`；`退出码=0` | 0 |
| `tab-rtl` | `合计 cases=84 判定过=8 结构败=0`；`退出码=0` | 0 |
| `textlineproto` | `== 探针：通过 4 / 失败 2 ==`；`== 通过 10 / 失败 0 ==` | 1 |

⚠️ `tline`／`tab-zero`／`textlineproto` 的 `rc=1` **不是回归**：三臂各带**在册**的既有红（`#49` 冻结块同一批 ❌ 逐字相同，
`tab-anchor` 的 `绿=615`／`绿=421` 也**逐字命中**冻结块的 `COLUMN-FLOOR … judged_min=615 / 421`）。

### §5.3 「哪几臂本该变、哪几臂不变」＋ `tline` 的 36 行 diff 逐处归因

**本该变的**：只有 `tline` —— 它的日志**内嵌运行相关字段**：`[applocal]` 同步行、被同步的权威件 sha、`已用时间`、
`T0.7` 一致性行里的 PC/DWF 值、**自指**的上一趟 artifact（`gen/t2d-width-diff.txt`）、**日期戳**文件名、`mktemp` 路径。
⇒ `tline.log` **程序上不可复算**（`#48`／`#49` 已两次登记同一事实）。
**反过来说：`tline` 变了这件事本身不构成任何产品位移信号** —— 判据只能是它在 §5.2 里的**判词**（`通过 22 / 失败 2`，与 `#49` 逐字相同）。

`diff ~/w94a/arms-pre/tline.log build/MilBridge/arm-logs/tline.log` = **36 行、全部是上面那几类**，逐处点名：

```
 7c7   [applocal] DirectWriteForwarder.dll：已与权威一致（de2d555105b7d04b） → 陈旧 de2d… → 已同步为权威 ce3469f49efcbcfa
 9c9   [applocal] PresentationCore.dll：已与权威一致（56ee75ced8d6aece） → （722e0ab8205b7c3f）
13c13  已用时间 00:00:01.05 → 00:00:01.45
44c44  [T0.7] PresentationCore.dll 副本/权威 56EE75CE… → 722E0AB8…
46c46  [T0.7] DirectWriteForwarder.dll 副本/权威 DE2D5551… → CE3469F4…
49c49  一致 4/4（权威 PC=56EE75CED8D6AECE → 722E0AB8205B7C3F cfg=Release）
67c67  [隔离矩阵] before（上一趟 artifact … mtime=2026-09-21 16:29:53 → 2026-09-22 15:27:33）   ← 自指
145c145 记账行级清单 … tline-ledger-lines-20260921-1629.txt → -20260922-1527.txt                  ← 日期戳
228c228 原始日志保留在 /tmp/tmp.HCHzkbuuGi/ → /tmp/tmp.BpYN686efc/                                  ← mktemp
```

**本该不变的**：`tab-zero`／`tab-anchor`／`tab-rtl`／`textlineproto` **四臂逐位不变** —— 判据是
`hbtextline`（`instr_shim`）**未变**、四臂的判词与 `#49` 逐字相同、`tab-anchor` 的 `615/421` 命中冻结块的 `judged_min`。
**这四臂的"不变"是有牙的**（不是空成立）：它们各自带的在册红一条也没多、也没少。

### §5.4 重钉后的一致性复核（顺手取的两条闸门读数，供 `W95A` 做冻前对照）

```
$ bash build/MilBridge/tools/arm-log-sha-check.sh
ARMLOG_ARM=tline PASS decl=6ce993ad974d32ad live=6ce993ad974d32ad nlink=2
ARMLOG_ARM=tab-zero PASS / tab-rtl PASS / tab-anchor PASS / textlineproto PASS
ARMLOG_SHA=PASS shape=flat required=5 declared=5 pass=5 fail=0 noinfo=0        rc=0

$ bash build/MilBridge/tools/column-floor-check.sh
  [COLUMN_FLOOR_ARMLOG] arm=tab-anchor OK / tab-zero OK / tab-rtl OK / textlineproto OK
  [COLUMN_FLOOR_ARMLOG] arm=tline **MISMATCH** 冻结块声明=2103f88183b17a6a 登记表=6ce993ad974d32ad
COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
COLUMN_FLOOR_SELFREPORT=PASS
COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS
```

⇒ **冻前形态逐字命中设计**：恰好 **1 处声明类红 = `COLUMN-FLOOR`**（`bad= tline`：冻结块还是 `#49` 的臂 sha，登记表已重钉）
＋ `COLUMN_FLOOR_SELFREPORT=PASS` ⇒ 与 `#49` 完全同形，**冻结后必须转绿**。**不要**把它读成失败，也不要为了让它绿去放宽判据。

---

## §6 步骤⑤/⑥ 相关（本件只做只读复核 + 登记，未改路由件）

### §6.1 `BRIDGE_SRC_FP` 两侧 —— **同值** ✅

```
现树     BRIDGE_SRC_FP = 0a8f69b3c5fabd43           （bash build/bridge-src-fp.sh）
发布记录 BRIDGE_SRC_FP = 0a8f69b3c5fabd43           （…/release_linux-x64/bridge-src-fp.txt）
```

⇒ `close-wave.sh:301-304` 的桥身份自检**会过**；`NEED_BRIDGE=0`（**无需重发桥**），与 `bridge` 位 `feef049e9d0e313a` 未变一致。
`BRIDGE_SRC_FP` 与 `#49` 冻结值（`0a8f69b3c5fabd43`）**也同值**。

### §6.2 继承件复核 —— `build/close-wave.sh` **未被改坏**

| 判据 | 读数 |
|---|---|
| `bash -n` | `rc=0` |
| 整份 sha16 | **`f440ccdb4e29a942`**（与任务书给的继承值**逐位相同**） |
| `fp_inputs()` 里两件 R-GATE 判据件 | `:153 build/MilBridge/tools/r-gate-step.sh` ＋ `:154 build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` **都在** |
| 残留缺口注释 | `:141-144` 在（`verify-all.sh`／`reapply-patches.py`／PF `*.Linux.cs` 仍不可见） |

⇒ 按任务书要求：**只复核、未重写**。备份仍在 `~/w91a/precheck/close-wave-before.sh`。

### §6.3 顺手取到的旁证（`W95A` 会用到）

```
VERIFYALL_SELF=PASS names=26 decl=26 gen=#50 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=227623000850ca5d
（⇒ W84A 的四处同趟声明 25→26 已落地；第 [26] 步 R-GATE 在位，判据件 41,641 B / 装置 24,148 B）
```

### §6.4 本件在仓内的写入面（**零产品改动**）

| 文件 | 动作 | before → after sha16 |
|---|---|---|
| `build/MilBridge/known-red.json` | 步骤④重钉 | `a747b713532e7631` → **`8a0c0f221e35f42b`** |
| `build/MilBridge/W94A-report.md` | 本报告（新建） | —— |
| （构建产物：九位中变化的那几位 ＋ 各 app-local 副本） | 整波自带 | 见 §2.2 |

**未碰**：`docs/ROUTES.md`／`docs/CURRENT-STATE.md`／`handoff.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／
`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`verify-all.sh`／
`build/MilBridge/tools/**`（除 `known-red.json` 这条**配方指定**的重钉产物）／四个路由件。**未跑** `integration-wave`／`close-wave`／`verify-all` 之外的波级脚本；
`close-wave.sh`／`integration-wave.sh` **一字节未改**。

---

## §7 `NOINFO` / 作废趟 / 纪律偏离（逐条如实）

### §7.1 `NOINFO`

1. **`pf` 漂移的**根因**未归因** —— 已排除：工程确定性开关（`Deterministic=true`）、PF 单独构建（两次同值）、csproj 内容（每波末态可复现）；
   已证：源指纹四趟相同而产物四趟不同、72 字节差异全在 `TimeDateStamp`/MVID/调试目录。
   **要什么样的读数**：一个能覆盖 **PF 全部编译输入**（含 `obj/` 生成源、引用件、`Compile` 项集合与次序）的指纹。
   **怎么取**：`dotnet build … -p:UseSharedCompilation=false -v:diag` 抓 `csc` 命令行，两趟逐字 diff；或给 `build/artifact-src-fp.py` 扩覆盖面到 `-getItem:Compile`。
2. **`dwf` 的位移机制未归因** —— 无源改动、引用件逐位未变，位移只在第 1 趟整波发生且此后三趟稳定（**值可复现**）。
   ⇒ 值可用来冻结，但"为什么第 1 趟会变"是 `NOINFO`。
3. **`D-G77` 形态未做反极性**：本趟 `:97` 全程不存在 ⇒ 走的是 `source=self-started` 支；
   "起不来 ⇒ `exit 5`"那一支本件**未实测**（`ARMS_XVFB_BIN` 反极性留给专门车道）。
4. **`UNEXPECTED=6[DECL-GAP-EQ=6]`** 未逐条归因（`#49` 已认定为**在册**声明类缺口；本件只确认"不会因本波变多"：波前 6、波后 6）。

### §7.2 作废趟（**不入读数**）

1. **裸跑（未过重活槽）的 PF 实验第 1 趟** —— 我在启动 `02-pf-determinism` 时**漏了 `~/heavy-slot.sh`**，违反任务书硬纪律。
   **自纠**：按 PID（`2186861` → 其子 `2186955`）止损，`pgrep -c dotnet` 回 0，随后**同一实验重挂槽**（`held=84s`）。
   该裸跑的任何输出**作废、未入任何表**；偏离已登记进 `~/w94a/STATUS.md`。
2. **无** `HEAVYSLOT=NOINFO`／`MAXHOLD_KILL` 趟（本件全程 `MEMOK`，四趟整波 `avail` 3054/…/2536 MB）。

### §7.3 纪律偏离（逐条写理由）

1. **重取五臂用 `--max-hold 1200`（任务书说"其余步骤一律 300"）** —— 本步是**原子长步**：
   读数 `held=307s`、`#49` 先例 `held=329s/333s` ⇒ **300 s 物理上装不下**，用它只会得到 `MAXHOLD_KILL`（＝作废趟、拿不到任何读数）。
   按 `~/w71a/BRIEF.md` §1 与 `#49` 先例用 `1200`；**`--min-avail 1500` 未动**，耗时已如实上报（307 s）。
2. **整波跑了四趟**（任务书只要求一趟）—— 由 `dwf` 无源位移逼出的"可复现性"判据驱动，每趟的**预测都先写后取**；
   第 1d 趟同时承担"把树恢复到整波末态"的职责。
3. **我手跑了两次 `build/PresentationFramework.Linux/reapply-patches.py`**（`H3` 实验）—— **它改了 csproj**
   （`d3f54cd7c0354385` → `8dc2ac5475fe616e`）⇒ 树一度离开整波末态。
   **如何还原**：第 1d 趟整波的 `step 1`（port-lib 重生成）＋ `step 2`（重放补丁）把 csproj **还原为 `d3f54cd7c0354385`**（现场复核）；
   最终交付的是**第 1d 趟（整波末态）**。该次实验已公告并留痕（`STATUS.md` 的 `[STEP 1d]`）。
4. **本件顺手多跑了两条只读闸门**（`arm-log-sha-check.sh`／`column-floor-check.sh`，共 <2 s，不属重活）—— 只为给 `W95A` 冻前对照，**未改任何判据**。

### §7.4 内存三值 / 残留

`MemAvailable` 开工 **3214 MB** → 整波内 **3054 MB** → 收工 **2848 MB**（`total 7923 / used 4733 / free 974`）；
`oom_kill` **0**；`loadavg` 收工 `0.71 1.29 1.82`；**残留进程 0**（`Xvfb` 0／`dotnet` 0／`:97` 已收）；**零 `pkill -f`**（全部按 PID）。

---

## §8 给 `W95A` 的第一条命令与接手要点

**第一条命令**（照 `W71A/BRIEF.md` §1 步骤 4；本件已把树停在整波末态、五臂已重取、世代已重钉）：

```
cd $R && export PATH="$HOME/.dotnet:$PATH" && export DOTNET_gcServer=0
# 门禁 ×2（先 rm -f 行文件；第一趟带 WPTD_BASELINE_OUT），两趟都要 rc=0 且机读行 6/6 result=PASS
```

接手要点（**逐条都有本件读数背书**）：

1. **九位现值取 §2.2 那一列**，**不要**用任务书 §② 那一栏（其中四个数不是 `#49` 冻结值，见 §2.1）。
2. **`inputs_fp` 用 `f3fb5db87480ada8fd1502148f3c889549be756c0e60912bfc38109a4a3cc730`**（重钉后终值，§4）。
3. **冻前预期恰好 1 处声明类红 = `COLUMN-FLOOR`（`bad= tline`）**，形态见 §5.4；**冻后必须转绿**。
4. 🔴 **`pf` 的不可复现性必须先裁定**（§3.4）：`W95A` 若在冻结前后各跑一趟整波/`verify-all`，**`pf` 很可能又换一个值**。
   建议把 §3.1／§3.2 的复算命令与读数**写进冻结块的显眼处**，并把"`pf` 构建身份不可复现"单独立项。
5. 本件**未做**：门禁 ×2、冻前 `verify-all`、`w27-freeze.py '#50'`、冻后 ×2、`w50-record.txt`、推送 fork、app-local 最终刷新。

---

## §9 ≤8 行大白话小结

1. 步骤 1–4 全跑完，四步 `rc` 都是 0；整波跑了四趟（第一趟正式，另三趟为验证"同命令是否同值"）。
2. 本波动了五位：`pc`／`pf`／`win32shim`／`wic_shim`／`dwf`；`bridge`／`windowsbase`／`provider`／`hbtextline` 一动没动。
3. 任务书给我对照的"`#49` 冻结值"里，`pc`／`pf`／`win32shim`／`wic_shim` 四个数其实是**现树值**，不是 `#49` 的值——按基线文件更正了。
4. **最要紧的发现**：`pf` 每次整波重建都换一个值（四趟四个 sha），可源指纹四趟完全一样、单独重建又稳定 ⇒ **`pf` 现在不是一个可信的"构建身份"**。
5. 造成这事的范围我排除了工程开关、单独构建、csproj 三条，但**真凶没抓到**，如实记 `NOINFO` 并给了复算配方。
6. 五臂只有 `tline` 变了字节，而且 36 行差异**全是**运行相关的（同步行、耗时、被同步件的 sha、自指 artifact、日期戳、`mktemp`），**不是产品位移**；其余四臂与 `#49` 逐位相同。
7. 世代重钉：`APPLIED` → `--check` = `PASS`；`known-red.json` `a747b713532e7631` → `8a0c0f221e35f42b`，只改了证据日志与 `tline` 臂两处语义字段。
8. 我自己犯过一次"没走重活槽"的纪律错（PF 实验第一趟），按 PID 止损并重挂槽，那趟作废；全过程零 `pkill -f`、残留进程 0。

---

*报告件 sha16：**`e4874939ba67850b`**（正文 36664 B / 485 行）—— 口径 = 本文件去掉末尾「空行 + 本条」两行后的整份；复算 `head -n -2 build/MilBridge/W94A-report.md | sha256sum | cut -c1-16`。现场算，未手抄。*
