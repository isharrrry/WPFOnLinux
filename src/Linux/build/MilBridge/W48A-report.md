# 波 `#47` · 车道 `W48A` 报告 —— 整波链（**只跑链、不冻结**）

> **任务**：产品波 `#47`（修 `D-G55`：`SetCapture/ReleaseCapture` 不派发 `WM_CAPTURECHANGED`）的收尾链
> 「`publish` → 整波重建 → 重取臂 → 重钉 → 闸门 ×2 → 冻前 `verify-all`」，**冻结由主控做**。
> **仓库根**：`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）。
> **本报告的性质**：**只读记账 ＋ 只读复核**（见 §0.3 的分工变更），不是判据、不替代预登记 `docs/WAVE47-PREREGISTRATION.md`。
> **纪律**：SDK 走 `export PATH="$HOME/.dotnet:$PATH"`；`dotnet -m:1`、`DOTNET_gcServer=0`；`nproc=3`；
> 全程**零 `pkill -f`**、零 `pgrep -x dotnet` 取 PID、零 `w27-freeze.py`、零对判定输入的手写改动。

---

## 0 摘要

### 0.1 逐步结论（一句话/步）

| 步 | 谁跑 | rc | 一句话 |
|---|---|---|---|
| 1 `publish-milbridge.sh` | 本车道 | **0** | 桥源未动 ⇒ 产物**逐位未变**（`e3ea092010734f44`／5,019,968 B），16.4 s |
| 2 `WAVE_OWNER=w48a integration-wave.sh` | 本车道 | **0** | `失败步骤 0`；应用器 `miss=0 red=0`；波前==波后；**168 s**；**九位一位未变** |
| 3 `retake-arms-w23.sh` | 本车道（与主控**并发**，见 §4.4） | **0** | 稳态：**只有 `tline` 变**（`e061054f73c9a2e7 → 3a6eca716ada5bdb`），其余四支逐位未变 |
| 4 `repin-generation.py --why` ＋ `--check` | 主控 | **0 / 0** | `APPLIED` → `REPIN_GENERATION=PASS`；`known-red.json 1fa4c4540fe1b69f → 00a75a87ec5ed0d6` |
| 5 闸门 ×2 | 主控 | **0 / 0** | `WPTD_GATE=PASS acceptance=2/2`、`WPTD_SUMMARY=PASS tiers_passed=2/2`；行文件 **6 行 6 `result=PASS`** |
| 6 冻前 `verify-all` | **主控**（本车道**未跑**，任务书要求如此记账） | **1** | `步骤通过 24  ❌ 失败 1`／`用例通过 871 跳过 2`／`结论：❌ 失败项：COLUMN-FLOOR`（**唯一失败项 = 声明类**，与预期一致）；日志 `$HOME/w48a/06-verify-all-pre.log`（sha16 `a09909bb3a76224f`） |

### 0.2 本波真正动了哪一位
相对 `#46` 冻结值：**只有 `win32shim`** `e700c383ec1ecdc8 → abf6879c027c5e73`（这是 `D-G55` 的修法：`win32_core.c:983/:996` 两处派发 ＋ `win32_internal.h:40` 加 `WM_CAPTURECHANGED 0x0215`）。
`bridge`／`pc`／`pf`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf` **八位逐位未变**（其中 `pc`／`pf`／`windowsbase` **被整波重编过**（mtime 22:52:30–22:54:34）但**字节可复现**）。
⇒ 冻结项 `GENS['#47']['allow_changed']={'pc','pf','win32shim'}` 是**超集**（`pc`/`pf` 实测未变），与 `w27-freeze.py:27-40` 一致，不构成风险。

### 0.3 🔴 分工变更（必须记）
任务书把步 1–6 都交给本车道；实际执行中**主控与本车道在同一时段跑了同一条链、并写同一个 `$HOME/w48a/` 目录**，形成一次真实撞车（证据与后果见 §4.4）。主控随后裁定：
**「重活全部由主控跑，本车道只做只读记账＋报告」** ⇒ 步 3 的**证据以我复读的稳态值为准**（主控已按 `tline 3a6eca716ada5bdb` 改写 `$HOME/w21-verify/w47-record.txt` 的 `# ARM-LOG-SHA arm=tline` 行），步 4/5/6 记为主控执行、本车道**只读复核**。
⇒ **本报告不含任何由本车道发起的重活读数**（除步 1–3，那两步是我在收到裁定之前跑的）。

---

## 1 前置检查（P0–P9，全部现场重算）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux; export PATH="$HOME/.dotnet:$PATH"
```

### P0 环境（`22:48`–`22:51`）
```text
nproc                = 3
MemAvailable         = 2364 MB（> 1500）
pgrep -c -x dotnet   = 1   → 1763778 dotnet HandyControlDemo.dll（**别人的 app，不是构建**；按纪律等 30 s 复读）
xdpyinfo -display :97 = UP
```
### P1 配置唯一声明
```text
bash build/selfbuilt-config.sh            ⇒ Release
bash build/selfbuilt-config.sh --check    ⇒ SELFCONFIG_CHECK=PASS（SELFCONFIG_DECL / VALUE / 两张 MSBUILD 图全 PASS）
```
### P2 两颗基线牙
```text
BASELINESHA=PASS live=dd31a7701fc77829 decl=dd31a7701fc77829
BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46
BASELINE_BYTES=527577
BASELINEDUP=PASS n=0
```
（冻结世代仍是 `#46` ⇒ 与 `GENS['#47']['prev']='#46'` 相符，重冻前提成立。）
### P3 其余三颗牙（**开工那一刻**）
```text
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS \
  reg=1fa4c4540fe1b69f base=dd31a7701fc77829 corpus=0cebc0afd5142fbf
DEFREG=FAIL reason=undeclared-id-in-route
  D-G55 first-seen=KD:2038 route=…/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
```
🔴 **`DEFREG=FAIL` 是任务书预期之外的红**（任务书预期"冻前唯一 ❌ 是 `COLUMN-FLOOR`"）。`DEFECT-REGISTRY` 在 `w27-freeze.py` 的 `green` 名单里、**不在** `DECLARATION_CHECKS` ⇒ 它红会**同时**让冻前 `verify-all` 多一个 ❌ **且**让冻结器 `:283 assert _ok` 当场 `AssertionError`。我按纪律（`*.tsv` 是判定输入、runbook §1-P7 明说它是**主控写域**）**没有动它**，而是立刻上报主控。见 §1.1。
### P4 当前九位（口径逐字照 `close-wave.sh` 的 `NINE`／`w27-freeze.py:333-341`）
| 位 | 开工值（22:51） | `#46` 冻结值 | 变？ | 字节 |
|---|---|---|---|---|
| `bridge` | `e3ea092010734f44` | `e3ea092010734f44` | — | 5,019,968 |
| `pc` | `043eff4b1d8ecd7d` | `043eff4b1d8ecd7d` | — | 3,601,408 |
| `pf` | `366e9486536bc291` | `366e9486536bc291` | — | 6,119,424 |
| `windowsbase` | `84a2826c471e60ea` | 同 | — | 1,111,552 |
| `provider` | `1f9511a7ef395bfe` | 同 | — | 103,936 |
| `win32shim` | **`abf6879c027c5e73`** | `e700c383ec1ecdc8` | **✅变** | 299,040 |
| `wic_shim` | `56278c14b4ecd672` | 同 | — | 70,728 |
| `hbtextline` | `e89fed55fd8e32bc` | 同 | — | 290,825 |
| `dwf` | `de2d555105b7d04b` | 同 | — | 39,936 |
### P5 `inputs_fp` 与 `BRIDGE_SRC_FP`
```text
bash -c 'source <(sed -n "/^fp_inputs()/,/^}/p" build/close-wave.sh); fp_inputs'
  ⇒ a47546ec0ed887f8b344a3c8367424cbab55d87eb90dceef5cb6dd3bf3ff0807   （开工＝波前）
bash build/bridge-src-fp.sh              ⇒ BRIDGE_SRC_FP=f10b4b297b2358e6 BRIDGE_SRC_N=78
发布记录 bridge-src-fp.txt                ⇒ f10b4b297b2358e6
```
⇒ **现树 == 发布记录**（本波桥源未动）⇒ `close-wave.sh:301-304` 不会 `exit 5`、闸门不会打 `WPTD_BRIDGE_SRC_STALE=yes`（实测见 §6）。
### P6 native／桥 新鲜度
```text
newest_src=1789829308  auth=1789829310  ⇒ 可跳过重建（权威件 **不比源旧**；shim 源 22:48:28、权威件 22:48:30）
   权威 abf6879c027c5e73  src/WpfGfx.Linux.Native/bin/libwpfwin32.so         （22:48:30 > 源 22:48:28）
```
🔴 **4 份副本全部停在 `e700c383ec1ecdc8`（= `#46` 冻结值）**：`samples/WpfFeatureProbe/bin/Release/net10.0/`、`build/MilBridge/tests/CompositeFontProbe/bin/Release/`、`build/MilBridge/tests/ContractProbe/bin/Release/`、`build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/`。
**`integration-wave.sh` 不做这个同步**（只有 `close-wave.sh` 的 `[2/6]` 做）⇒ 走"直调整波"这条路时，这四份会带着**旧一代 shim**；谁在它们上面取读数，谁测的就是 `#46` 的 shim。已上报主控。
### P7 缺陷编号对账 ⇒ 见 §1.1
### P8 应用器审计
```text
APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0
```
（`ok` 86 = `#46` 现场的 86；**appliers 25 = 本波无新应用器**，与 `patch-presentationcore-hwndtarget-trace` 已在 `#46` 登记一致。）
### P9 哨兵与并发
```text
无重发锁（/tmp/bridge-republish.lock 不存在）
无应用/探针在跑（pgrep -af -- 'run-wpftextdemo|run-wpfprobe|WpfTextDemo|WpfFeatureProbe' 剔掉本调用者后为空）
```

### 1.1 主控处置的两件 ＋ 我的独立复读

| # | 事项 | 主控处置 | **我的复读（现场原文）** |
|---|---|---|---|
| ① | `DEFECT-REGISTRY=FAIL`（`D-G55` 未进声明表） | `defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv`，`22:51:39`（4,815 → 4,878 B） | `grep -c D-G55 …declared.tsv` = **1**；`DEFREG=PASS declared=91 route_ids=91`、`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN` |
| ② | `libwpfwin32.so` 4 份副本陈旧 | `cp -f` 以权威 `abf6879c027c5e73` 覆盖 4 份，`22:51:43` | `find … -exec sha256sum` ⇒ **去重后 1 个值**（`abf6879c027c5e73`）、**计数 5**（权威＋4 副本），逐份 mtime 22:51:43 |

⇒ 两件都是**主控写域**（`*.tsv` 判定输入／`samples/**` 不在本车道写域），处置后**由我独立复读**，读数一致。
⇒ 复读后 `inputs_fp` **未变**（`defect-registry-declared.tsv` 与 `libwpfwin32.so` 都不在 `fp_inputs()` 覆盖面里）——这一点是本车道**先算过覆盖面**（`sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh` 逐行读）才敢下结论的。

---

## 2 步 1 `bash build/publish-milbridge.sh` —— rc = **0**

```bash
(date +%FT%T; time bash build/publish-milbridge.sh) > $HOME/w48a/01-publish.log 2>&1 ; echo $?   # ⇒ 0
```
关键原文（`$HOME/w48a/01-publish.log`）：
```text
2026-09-19T22:51:30
== 发布 MilBridge（绝对 ArtifactsPath）
== 同步同目录依赖（部署契约：三者必须同目录）
  libwpfwic.so ← …/build/DirectWrite.Linux/wic-shim/libwpfwic.so
== 指纹（供核对/记档）
  wpfgfx_cor3.so        5019968 B  e3ea092010734f4441e3d091
  libwpfwic.so            70728 B  56278c14b4ecd6722f4cddf0
  libSkiaSharp.so       9244960 B  a02cd03f1ebcbb972b811bd8
  Wic* 导出数: 13
  BRIDGE_SRC_FP=f10b4b297b2358e6 BRIDGE_SRC_N=78
real	0m16.355s
```
**before == after**：跑前 `e3ea092010734f44`／5,019,968 B，跑后**逐位相同** ⇒ 与预登记 §2「`bridge` 源未动、AOT 可复现（预期不变）」**命中**。
（`publish` 尾段的 `APPSYNC=MISMATCH STALE=5` 是**本次发布引入之外**的既有副本发散：当时含那 4 份陈旧 shim；主控 22:51:43 同步后复读降到 `STALE=1`＝唯一在册 `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`，`BRIDGE-ANCHOR=0`。）

---

## 3 步 2 `WAVE_OWNER=w48a bash build/integration-wave.sh` —— rc = **0**（168 s）

```bash
(date +%FT%T; time env WAVE_OWNER=w48a bash build/integration-wave.sh) > $HOME/w48a/02-integration-wave.log 2>&1
```
原文（`$HOME/w48a/02-integration-wave.log`）：
```text
=== 2.5/5 应用器审计（注册了但没生效 ⇒ 红；债务 #13） ===
APPLIER_AUDIT_SUMMARY appliers=25 ok=86 miss=0 red=0 rc=0
=== 3.5/5 生成物身份指纹（PC/WindowsBase/PF 的源身份；债务 #20 同族） ===
ARTIFACT_SRC_FP proj=PresentationCore    fp=4298d1b991bdfea7 n=1373 peer_fp=4e434fab7468feeb peer_n=8  state=written
ARTIFACT_SRC_FP proj=WindowsBase         fp=7f2850c95f3ad0c2 n=326  peer_fp=2a2ed993f748365d peer_n=2  state=written
ARTIFACT_SRC_FP proj=PresentationFramework fp=4017a35ce854438f n=1362 peer_fp=7c79696509b6cf09 peer_n=9 state=written
=== 3.6/5 app-local 副本刷新 ===
    REFRESH(group) build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll 96851e932a92931c → e7a486530c6030eb
    REFRESH(group) samples/ThirdPartyMini/bin/Debug/net10.0/ReachFramework.dll 33b372daa826733e → f4836ae36cbe80e1
    REFRESH(group) samples/ThirdPartyMini/bin/Debug/net10.0/PresentationCore.dll 659a5dc64156b26a → 043eff4b1d8ecd7d
    APPSYNC-REFRESH=refreshed=3 newer=0 applied=1
    APPSYNC=MISMATCH（MISMATCH=0[STALE=0 NEWER-DIFF=0] … UNEXPECTED=12[DECL-GAP-EQ=12 DECL-GAP-DIFF=0] … BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）
=== 5/5 输入稳定性（波期间手写输入有没有被改动） ===
  波前指纹 a90007e54cdfcad6e365bb1d04614e3f94481c9f28b209b6eb5703ffd4c38909
  波后指纹 a90007e54cdfcad6e365bb1d04614e3f94481c9f28b209b6eb5703ffd4c38909
  ✅ 一致 ⇒ 本轮构建结果与"波后树"对得上（没有编辑竞态）
=== 集成波结束：失败步骤 0 ===
real	3m6.516s
```
**波后复算**（我自己算，不抄脚本）：

| 项 | 波前 | 波后 | 结论 |
|---|---|---|---|
| `inputs_fp`（`fp_inputs()`） | `a47546ec0ed887f8…` | `a47546ec0ed887f8…` | **逐位未变**（无手写输入位移；`defect-registry-declared.tsv` 不在覆盖面） |
| 九位 | §1-P4 | 同 §1-P4（`pc`/`pf`/`windowsbase` mtime 变 22:52:30–22:54:34，**sha 全同**） | **一位未变** |
| `BRIDGE_SRC_FP` 两侧 | `f10b4b297b2358e6` | `f10b4b297b2358e6` | 一致 |

⇒ 与预登记 §2「只有 `win32shim` 必变；`pc`/`pf` **可能**因整波重建变字节（非确定构建）」相比：**`pc`/`pf` 实测未变**（可复现构建）⇒ 记入 §8 偏离①。

---

## 4 步 3 重取五臂 —— rc = **0**（6m22s）

```bash
(date +%FT%T; time env ARMS_OUT=/home/links-dev/w48a/arms bash build/MilBridge/tools/retake-arms-w23.sh) \
  > $HOME/w48a/03-retake-arms.log 2>&1    # ⇒ ARMS_RC=0，同 inode 守卫未触发（干净目录）
```
子臂 rc（与 `#46` 同形）：`tline 1 / tab-zero 1 / tab-anchor 0 / tab-rtl 0 / textlineproto 0`。

### 4.1 逐支读数（**稳态值**，见 §4.4 为什么必须强调"稳态"）
| 臂 | 重取前（`#46` 重取后） | 重取后（稳态） | 变？ | links | mtime |
|---|---|---|---|---|---|
| `tline` | `e061054f73c9a2e7` | **`3a6eca716ada5bdb`** | **✅变** | 2 | 23:07:54 |
| `tab-zero` | `9150c3a26a3cb789` | `9150c3a26a3cb789` | — | 2 | 23:08:33 |
| `tab-anchor` | `1c43a12dcaa5718a` | `1c43a12dcaa5718a` | — | 2 | 23:11:33 |
| `tab-rtl` | `92570318851ca7e8` | `92570318851ca7e8` | — | 2 | 23:11:39 |
| `textlineproto` | `4bceceeed570ba70` | `4bceceeed570ba70` | — | 2 | 23:11:48 |

- **"只有 `tline` 变"** ⇒ 与 runbook §3 的**结论**预测一致（`#44`/`#46` 两次现场也是这一形）。
- `links=2` 且 `mtime` **晚于重取开始（23:05:14）** ⇒ 不是"陈旧日志被洗绿"（runbook §4 的反向陷阱）；`$HOME/w48a/arms/*.log` 与 `build/MilBridge/arm-logs/*.log` **同 inode**（`stat -c %i` 相同）⇒ `ln -f` 生效、没人 `cp` 顶 mtime。
- 复核命令（逐支 + 汇总）：
  ```bash
  for f in tline tab-zero tab-anchor tab-rtl textlineproto; do
    printf '%-16s %s links=%s %s\n' "$f" "$(sha256sum build/MilBridge/arm-logs/$f.log|cut -c1-16)" \
      "$(stat -c %h build/MilBridge/arm-logs/$f.log)" "$(stat -c %y build/MilBridge/arm-logs/$f.log|cut -c1-19)"; done
  bash build/MilBridge/tools/arm-log-sha-check.sh | tail -1   # 重钉前必 FAIL（旧声明）、重钉后 PASS（见 §5）
  ```

### 4.2 🔴 runbook §3 的**机制**预测被推翻（结论对、理由错）
runbook §3 写："只有 `tline` 一支内容会变 —— 它自报权威 `PresentationCore.dll` 的 sha16（`tline.log:6`），而 `pc` 变了"。
**本波 `pc` 逐位未变**（`043eff4b1d8ecd7d` 前后相同），而 `tline` 仍然变了。我把两代日志逐行 `diff`（旧件 `$HOME/w46h/arms/tline.log` 仍有独立 inode，`links=1` 留存）：
```text
$ diff -u $HOME/w46h/arms/tline.log $HOME/w48a/arms/tline.log   # 共 4 处（8 行），全部是运行相关字段
-已用时间 00:00:02.59                                   +已用时间 00:00:01.41
-[隔离矩阵] before（… gen/t2d-width-diff.txt sha16=0B14FFB7202637E0 mtime=2026-09-19 15:14:10 …）
+[隔离矩阵] before（… gen/t2d-width-diff.txt sha16=13408DDB4379A2B1 mtime=2026-09-19 20:57:57 …）
-…⇒ 已写 …/gen/tline-ledger-lines-20260919-2057.txt      +…/tline-ledger-lines-20260919-2307.txt
-  原始日志保留在 /tmp/tmp.4jw0dBwjnF/（未删，供复核）    +  原始日志保留在 /tmp/tmp.E3Mn6Bgryz/（未删，供复核）
```
- 第 6 行的 `[applocal] PresentationCore.dll：已与权威一致（043eff4b1d8ecd7d）` **两代相同** ⇒ **不是**它导致的位移。
- 真正的位移来源是**运行相关字段**：① 耗时；② **上一趟自己产的 artifact `gen/t2d-width-diff.txt` 的 sha16**（自指！）；③ 带日期戳的输出文件名；④ `mktemp` 目录名。
- ⇒ **后果（值得下一波处置）**：`tline.log` **程序上不可复算** —— 每次重取都必然换字节，而 `repin-generation.py` 会把它的 sha **钉成 `generation.evidence_log_sha256` 与 `arm_logs.tline` 的声明值**。也就是说**这条"证据日志"的指纹每波都动，与产品是否变化无关**；"只有 tline 变"因此**不能**当成产品位移的信号。（本波 `tab-*`／`textlineproto` 逐位不变，说明它们**是**确定性的 ⇒ 对比之下更显 `tline` 的自指问题是单支的。）
- 另：`tline` 臂 rc=1 是**既有红**（`T3b` 折叠/记账），前后 `❌` 计数**相同**（`grep -c '❌'` 两代都 = 5），逐条判定行（折叠 4 / Extent 95 / 记账 5 / 判别式红 0/236）**逐字相同** ⇒ **不是本波回归**。

### 4.3 `#47` 修法**未**进入五臂的判据面（如实记，附机器证据）
`tline` 臂编的是 `build/shims/PresentationCore.HbTextLine.cs`（`e89fed55fd8e32bc`，本波未动）＋ `pc`；`tab-*` 三支走 `CoverageProbe`（`TAB_LINES_PROBE sha256=a6d0352b86467111 path=build/MilBridge/tests/CoverageProbe/Program.cs`）；`textlineproto` 会加载 shim（`grep -ic 'libwpfwin32\|shim' textlineproto.log` = 2）但它的读数与捕获语义无关。
**机器证据**：`grep -ric 'capture|SetCapture|ReleaseCapture|WM_LBUTTON|Mouse\.' build/MilBridge/arm-logs/*.log` ⇒ **五支全为 0**；且四支日志在 `win32shim` 变化前后**逐字节相同**。
⇒ 五臂里**没有任何一支**覆盖 `D-G55`（`SetCapture/ReleaseCapture ⇒ WM_CAPTURECHANGED`）。本波重取臂的作用是**纪律动作**（把臂日志与世代同趟钉齐），**不是** `D-G55` 的判据；`D-G55` 的判据在 `samples/WpfFeatureProbe` 第 ⑬ 块 `clickprobe` ＋ 仓外 hc（见 §9.3 与 NOINFO-5）。

---

## 5 步 4 重钉（**主控执行**，本车道只读复核）—— `APPLIED` → `--check` **PASS**

主控命令（原文，见 `$HOME/w48a/04-repin.log`；`known-red.json` 的 `arms_retaken.history` 里留有同一条 `why`）：
```bash
python3 build/MilBridge/tools/repin-generation.py \
  --why '波47：修 D-G55（SetCapture/ReleaseCapture 派发 WM_CAPTURECHANGED）⇒ win32shim 变；整波重建 ⇒ pc/pf 可能变字节；重取五臂后同趟钉齐'
```
**主控读数**：`REPIN_GENERATION=APPLIED`（23:11:54），四项被钉：
```text
generation.instr_run_sh        = 711f39f468f61cc8
generation.instr_program_cs    = 149dd986a642fdfc
generation.instr_shim          = e89fed55fd8e32bc
generation.evidence_log_sha256 = 3a6eca716ada5bdb
entries[*].caliber 改动字段数  = 0
```
**我的只读复核**（`23:13` 现场）：
```text
$ python3 build/MilBridge/tools/repin-generation.py --check   ⇒ REPIN_GENERATION=PASS（rc=0）
  世代三项 + 五臂 + 证据日志 + 4 条 entries 的 caliber 全部一致
$ 直读 known-red.json：evidence_log_sha256=3a6eca716ada5bdb；arm_logs={tline:3a6eca71…, tab-zero:9150c3a2…, tab-anchor:1c43a12d…, tab-rtl:92570318…, textlineproto:4bceceee…}
  history 末条 when=2026-09-19 23:11:54 why='波47：修 D-G55（…）⇒ win32shim 变；整波重建 ⇒ pc/pf 可能变字节；重取五臂后同趟钉齐'
  （`--why` 已给 ⇒ 不会留下 runbook §4 点名的"重钉了但没人知道为什么"的假绿形态）
```
`known-red.json` **before/after**：
```text
before（开工，22:51）: 1fa4c4540fe1b69f  402 行
after （重钉后，23:13）: 00a75a87ec5ed0d6  406 行
```
⇒ **重钉只跑了一次 `--why` 那趟**（任务书要求"只跑一次"）：本车道**没有**重复调用（避免二次写盘的非幂等位移）；`--check` 只读。
⇒ `fp_inputs` 随之位移（`known-red.json` 在覆盖面里）：`a47546ec…` → **`8a8661b926e47489…`**（与 `GENS['#47']['infp']=None`＋`prev_infp='a47546ec…'` 的设计一致）。
⇒ 重钉后三颗相关牙：`ARMLOG_SHA=PASS …pass=5 fail=0`；`COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 … reg=00a75a87ec5ed0d6 base=dd31a7701fc77829`，其子读数 **`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline`**（= 声明块里 `tline` 仍是旧值，**冻后转绿的正是这一格**，不是 `ARM-LOG-SHA` 这颗牙 —— runbook §12-2）。

---

## 6 步 5 闸门 ×2（应用门禁，**主控执行**，本车道只读复核）—— 两趟 **rc=0**

主控命令形态（与 runbook §5.4 逐字同形，含先 `rm -f` 行文件）：
```bash
G=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh
rm -f $HOME/w48a/gate-rows.txt
WPTD_RUN_DIR=$HOME/w48a/gate-e WPTD_BASELINE_OUT=$HOME/w48a/gate-rows.txt timeout 900 bash "$G" 60 --tier both > $HOME/w48a/05-gate-e.log 2>&1   # GATE_E_RC=0
WPTD_RUN_DIR=$HOME/w48a/gate-f                              timeout 900 bash "$G" 60 --tier both --no-build > $HOME/w48a/05-gate-f.log 2>&1   # GATE_F_RC=0
```
**两趟自报（逐字相同）**：
```text
WPTD_SUMMARY=PASS tiers_passed=2/2
WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
WPTD_BRIDGE_SRC_STALE=no basis=pub=f10b4b297b2358e6 now=f10b4b297b2358e6 so_file_match=yes
（行文件内的机读行：BRIDGE_SRC_STALE(桥→源 身份；期望 no；yes=部署件不是当前源编的⇒本趟读数作废) no basis=… so_file_match=yes）
```
**行文件**：`/home/links-dev/w48a/gate-rows.txt`（`sha256sum` 前 16 位 = **`f52631e520251bd3`**，9,298 B，mtime `2026-09-19 23:14:51`）
```text
$ grep -c '^BASELINE ' gate-rows.txt            ⇒ 6
$ grep -o 'result=[A-Z]*' gate-rows.txt | sort | uniq -c   ⇒ 6 result=PASS
# BASELINE-HEADER date=2026-09-19T23:12:01+08:00 display=:97 host=linksdev-VirtualBox kernel=6.8.0-138-generic
#   run_dir=/home/links-dev/w48a/gate-e  repeat=3  timeout=60s  tier=both
config=pc:043eff4b1d8ecd7d,bridge:e3ea092010734f44,pf:366e9486536bc291,provider:1f9511a7ef395bfe,win32shim:abf6879c027c5e73,wic_shim:56278c14b4ecd672,hbtextline_shim:e89fed55fd8e32bc(stale:no)
```
逐行（`tier`/`rep`/`result`）：
```text
tier=default rep=1/2/3  result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14/14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0
tier=env     rep=1/2/3  result=PASS exit=143 drawn=144 notdrawn=0 frames_good=14/14 frames_blank=0 capture=ok scroll=ok shot_dims=938x938 colors=2828 cross_ae=0 max_concurrent_apps=1 leftover_after=0
```
⇒ 满足冻结器 `w27-freeze.py:398-402` 的三条硬要求：**行数 == 6**、**全部 `result=PASS`**、**每行都含终态的 `pc:043eff4b1d8ecd7d` 与 `pf:366e9486536bc291`**（并与现场九位一致）。
⇒ `date=`/`run_dir=` 都是**本趟**的（runbook §9-R13 的"忘了 `rm` 会混上一趟行"陷阱未发生）。

---

## 7 步 6 冻前 `verify-all` —— **由主控跑，本车道未跑**（按主控裁定记账）

- 主控进程现场：`1851980 bash verify-all.sh`，日志 `$HOME/w48a/06-verify-all-pre.log`。
- **本车道没有起过 `verify-all`**（也没有起闸门/构建/重取/重钉中的任何一个 —— 见 §0.3 裁定）；下面是**只读**读日志得到的结论区原文（主控允许"你要读就读"）。

### 7.1 结论区（日志原文，`$HOME/w48a/06-verify-all-pre.log:101-105`）
```text
======================================================
 步骤通过 24  ❌ 失败 1
 用例通过 871  跳过 2
 D-G17 跳过汇总（实测/上限；上限 = 静态＋语料＋X_STATE=available 的 X 项）：Rendering.Tests=2/27 
 SKIP_GUARD=PASS x_state=available x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
 结论：❌ 失败项：COLUMN-FLOOR
======================================================
```
⇒ **失败步名逐个 = `COLUMN-FLOOR`（1 个）**，`[14]` 步原文（`:76-80`）：
```text
[14] 列级下限外挂读者（『D-G27』：登记表⇔冻结块⇔语料复算⇔门禁自报；NOINFO 不许当绿；#31 加）
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=00a75a87ec5ed0d6 base=dd31a7701fc77829 corpus=0cebc0afd5142fbf
```
- **正是声明类那一格**（`bad= tline`：冻结块里的 `# ARM-LOG-SHA arm=tline` 还是旧世代值）⇒ 与任务书预期"唯一 ❌ 是 `COLUMN-FLOOR`（声明类，冻后转绿）"**逐字命中**；`verify-all` 的 rc 由"失败 1"决定为 **1**（该进程的退出码主控自持，本车道未取到；此处按日志结论区读作失败趟）。
- 三颗与本波直接相关的牙**都绿**：`BASELINE-SHA ✅`、`ARM-LOG-SHA ✅`、**`DEFECT-REGISTRY ✅`**（= §1.1 主控 `--emit` 的处置生效，任务书预警的"第二个红"**没有出现**）、`VERIFYALL-SELF ✅`。
- 耗时：日志头部自印起始 `2026-09-19 23:17:55`，文件末次写 `23:32:52` ⇒ **≈ 897 s**（口径 = 日志起始时刻与 mtime 现场算，**不是**脚本自印的 `real`；`#46` 冻前那趟是 863 s）。

### 7.2 冻前我采的牙读数（重钉后、`verify-all` 之前，全部现场算）
```text
DEFREG=PASS declared=91 route_ids=91（每编号在其 req 的每个 route 文件里都在；无未声明编号）   ← 主控处置①后
ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0
COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline          ← **声明类**，冻前必红、冻后转绿
COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=421 frozen=421 corpus_min=421
COLUMN_FLOOR_START_JUDGED_MIN=PASS      arm=tab-oracle-anchor col=START      key=judged_min decl=615 frozen=615 corpus_min=615
COLUMN_FLOOR_START_RELEASED_MIN=PASS    arm=tab-oracle-anchor col=START      key=released_min decl=194 frozen=194 corpus_min=194
COLUMN_FLOOR_CORPUS=PASS file=…/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862
COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=00a75a87ec5ed0d6 base=dd31a7701fc77829 corpus=0cebc0afd5142fbf
```
⇒ 我采的这一组与 §7.1 日志里的 `[14]` 步读数**逐字一致**（两条独立路径得到同一结论）。

### 7.3 顺带只读观测到的"下一步已经发生"（**不是本车道所为**，仅记账）
- 主控的**重冻已完成**：`BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b`、`BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47`、`BASELINE_BYTES=553550`、`BASELINEDUP=PASS n=0`；`grep -c '^# RE-FROZEN #47' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **1**。
- **冻后 ×2 已由另一条车道开跑**（`$HOME/w49a/post-freeze-1.log`，进程 `1880062 … bash verify-all.sh > $HOME/w49a/post-freeze-1.log`，23:34:09 建目录）⇒ **不在本车道职责内**，我未参与、未干预。
- ⇒ 由此可**反证**本报告 §6 的行文件与 §7.1 的日志**满足了冻结器的硬断言**（6 行 6 PASS、每行含 `pc:043eff4b1d8ecd7d`／`pf:366e9486536bc291`、`nfail(1)==len(_expected_red)`、`nstep=25`）——否则重冻不可能落地。

---

## 8 偏离预测的位移（逐条，按 runbook／预登记逐字对账）

| # | runbook／预登记的预测 | 现场 | 判定 |
|---|---|---|---|
| ① | 预登记 §2：`bridge` 源未动 ⇒ 预期不变；`pc`/`pf` **可能**因整波重建变字节（非确定构建） | `bridge` 不变 ✔；`pc`/`pf`/`windowsbase` **被重编但逐位不变** | **位移（方向是"比预测更稳"）**：`allow_changed={'pc','pf','win32shim'}` 因此是**超集**，无风险；如实记 |
| ② | runbook §3：只有 `tline` 会变，**机制**＝它自报 `pc` 的 sha16 而 `pc` 变了 | 只有 `tline` 变 ✔；但**机制不成立**（`pc` 未变）：位移来自耗时／`/tmp` 路径／**上一趟自产 artifact 的 sha**／日期戳文件名（逐行 diff 4 处） | **结论命中、机制被推翻**（runbook 该句只对 `#46` 那一趟成立）⇒ 见 §4.2 |
| ③ | 任务书：冻前唯一 ❌ 应为 `COLUMN-FLOOR`；出现别的非声明类红就停下上报 | **开工时** `DEFREG=FAIL`（`D-G55` 未进声明表）＝第二个红 | **偏离（已上报＋已处置）**：主控 `--emit` 后 `DEFREG=PASS declared=91`（§1.1） |
| ④ | runbook §1-P6：收尾必须做一次 native 副本同步（`#46` 现场 4 份落后） | **本波同样 4 份落后**（`e700c383…` vs 权威 `abf6879c…`），且 **`integration-wave.sh` 不覆盖这一跳** | **复发（同名形态第二次）**：主控手工同步 5/5；**债仍在**（`publish-milbridge.sh`／`integration-wave.sh`／`close-wave.sh:277` 三条链里只有 `close-wave` 管它）⇒ 建议下一波立牙或接链 |
| ⑤ | 任务书：`samples/WpfFeatureProbe` 第 ⑬ 块 `clickprobe` 若在冻前 `verify-all` 里出现 `MISMATCH`／注册表红，报原文 | **结构上不可能**：`verify-all.sh` **不调用** `run-wpfprobe.sh`（全仓零调用点，只有报告里的行号引用）；`WpfFeatureProbe` **不在** `wpf-linux.sln`、`integration-wave.sh` 也不构建它 | **无位移**（预警的这颗红在本链里没有射程）⇒ §9.3 附上我对 `BLOCKS`/`EXPECT` 登记的**只读核对** |
| ⑥ | runbook §5.4：行文件 `WPTD_BASELINE_OUT` 是**追加**语义 ⇒ 必须 `rm -f` | 主控命令含 `rm -f`；行文件 6 行、`date=`/`run_dir=` 为本趟 | **无位移** |
| ⑦ | runbook §0.1／§1-P5：`inputs_fp` 会因覆盖面成员变化而位移 | `a47546ec…`（波前＝波后）→ `8a8661b9…`（**只在重钉后**，因 `known-red.json` 在覆盖面里） | **命中**（两段位移都可归因） |
| ⑧ | **任务书未预测**：两个 `retake-arms` **并发**写同一个 `ARMS_OUT` | 见 §4.4 | **偏离（纪律事件，如实入册）** |

### 4.4 🔴 并发撞车（本报告最值钱的一条现场）

**事实**：本车道的重取跑 `23:05:14 → 23:11:38`（`$HOME/w48a/03-retake-arms.log`）；**同一时段**主控的重取跑 `23:05:21 → 23:11:48`（`$HOME/w48a/03-arms.log`）——**两者用同一个 `ARMS_OUT=/home/links-dev/w48a/arms`**，且都做 `dotnet build CoverageProbe` ＋ 同样五支臂 ＋ 同样的 `ln -f`。两个脚本各自的"arm log shas"表因此出现**瞬态值**：
```text
我的表（23:11:38）   : tab-rtl 05103c6ed23de1b1 ； textlineproto 4bceceeed570ba70
主控的表（23:11:48） : tab-rtl 92570318851ca7e8 ； textlineproto 4bceceeed570ba70
```
**机器证据说明"我那两格是写中途读到的"**：
- 两个文件的 `mtime`（`tab-rtl 23:11:39`、`textlineproto 23:11:48`）**晚于我自己那条链打印的 `=== done 2026-09-19 23:11:38 ===`** ⇒ 在我脚本"自印 sha 表"之后，**仍有写入发生**；
- 随后我在**静默后隔 25 s 复读两遍**：`23:12:08` 与 `23:12:33`，**两遍逐位相同**：
  ```text
  tline          3a6eca716ada5bdb   lnk=21672  mtime 23:07:54
  tab-zero       9150c3a26a3cb789   lnk=19182  mtime 23:08:33
  tab-anchor     1c43a12dcaa5718a   lnk=118027 mtime 23:11:33
  tab-rtl        92570318851ca7e8   lnk=17418  mtime 23:11:39
  textlineproto  4bceceeed570ba70   lnk=7926   mtime 23:11:48
  ```
  ⇒ 与主控表**一致**；且 `textlineproto`／`tab-rtl`／`tab-zero`／`tab-anchor` **与上一世代（`#46` 重取后）逐位相同**（`cmp` 逐字节 IDENTICAL，`/home/links-dev/w46h/arms/*.log` 因 `ln -f` 换链而**保留了旧 inode**，`links=1` ⇒ 可作旧件复算），**`tline` 的差异只有 §4.2 那 4 处运行相关字段** ⇒ **没有任何一格呈现"两写交错导致的破损"**。
- **结论**：证据以**稳态值**为准；**两个脚本自印的 sha 表在并跑下不可钉**（这是一条**可复用的纪律**：`retake-arms-w23.sh` 的第 6 步"报 sha"发生在最后一个写者退出之前，**没有静默等待**）。
⇒ 主控据此**已把 `$HOME/w21-verify/w47-record.txt` 里的 `# ARM-LOG-SHA arm=tline` 改成稳态值 `3a6eca716ada5bdb`**（`23:12` 前后），本报告确认该值 = 我两遍复读值 = `arm-log-sha-check.sh` 的现场值（§7）。

---

## 9 我在只读记账中看到的、值得下一波处置的三条

### 9.1 `tline` 臂日志**程序上不可复算**（自指 artifact ＋ 耗时 ＋ `mktemp` 路径）
见 §4.2：`generation.evidence_log_sha256` 与 `arm_logs.tline` 每波必换字节。建议：把 `tline.log` 里那 4 类字段（耗时、上一趟自产 artifact 的 sha、日期戳文件名、`/tmp/tmp.XXXX`）打上"运行相关"标记并从"证据指纹"的取值面里排除，或让该臂对这些字段做规范化后再落盘。
**为什么值得做**：现在"`tline` 变了"既可能是产品位移、也可能什么都不是 ⇒ 这条读数**不可判**（本波正是后者）。

### 9.2 native 副本同步仍未接链（W1 债第二次复发）
`integration-wave.sh` 不覆盖 `libwpfwin32.so` 副本（只有 `close-wave.sh [2/6]` 覆盖），而任务书给的链是"直调整波"（路 B）⇒ 每一波都会重现"4 份副本停在上一代"。本波由主控手工同步。建议立牙（照 `check-applocal-sync.sh` 的 `ANCHOR-*` 只读形态加一格 shim 锚）或把同步接进 `integration-wave.sh` 的 `3.6/5`。

### 9.3 `clickprobe`（第 ⑬ 块）的登记现场核对（**只读**，任务书点名）
```text
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:325
  BLOCKS="popup anim opacitymask effects controls textbox-edit virtualize transforms text-rtl text-rtl-pure text-dp-min nativecombo clickprobe"
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:609
  "clickprobe:!22D3EE"   # ⑬ 块：静止时不该出现它的测试色（点开下拉才出现）
```
⇒ `BLOCKS` 与 `EXPECT` **都已登记**（`#46` W47B 的欠账已补）；且如前所述，`run-wpfprobe.sh` **不在** `verify-all` 射程内 ⇒ 它不参与本波的冻前红绿。**本波我没跑它**（重活全部由主控跑；它是需要私有 X 的交互探针）。

---

## 10 `NOINFO`

| # | 项 | 为什么填不出来 | 补法 |
|---|---|---|---|
| 1 | ~~冻前 `verify-all` 的 `rc`／通过失败步数／**失败步名逐个**／耗时~~ **已解（§7.1）** | 该趟由**主控**跑（裁定 §0.3），本车道未跑；我**只读**主控日志得到结论区 | 已读：`步骤通过 24 ❌ 失败 1`、`用例通过 871 跳过 2`、`结论：❌ 失败项：COLUMN-FLOOR`、`SKIP_GUARD=PASS`、≈897 s；**唯一进程退出码**仍属主控（本车道按日志读作失败趟 = rc 1） |
| 2 | 并发双跑对五臂**读数内容**的量化影响 | 没有"单跑对照趟"可比（本波只此一趟）；我只能证"稳态值与主控表一致 ＋ 四支与上一世代逐字节相同 ＋ `tline` 逐行 diff 只 4 处运行相关字段" | 下一波若再重取，**先确认无人并跑**（`pgrep -af retake-arms`）并留一趟单跑对照 |
| 3 | `tline` 日志里那 4 类运行相关字段**分别由哪一行代码打印**（`run.sh` 还是 harness） | 本波只做只读记账，未去读 `build/MilBridge/run.sh` / `HbTextLineParity` 的打印点 | `grep -n '已用时间\|原始日志保留在\|tline-ledger-lines' build/MilBridge/**` 定位 |
| 4 | `tier=env` 的 `colors=2828` vs `tier=default` 的 `3960` 差异成因 | 两档判据都 `PASS`（`acceptance=2/2`），本波未判差异 | 跑 `WPTD_RUN_DIR=… bash run-wpftextdemo.sh 60 --tier env` 后逐帧比色 |
| 5 | `D-G55` 的产品判据在**本链**里**没有被任何一步执行** | 五臂不覆盖捕获语义；`clickprobe` 不在 `verify-all` 射程；hc 是仓外应用 ⇒ 预登记 §2 的两条判据都**得单独跑**（本车道未跑，重活已归主控） | 按预登记 §2：`$HOME/w47b-click.sh`（仓内 ⑬ 块）＋ hc 的 `NativeTextBoxDemo` 连做序列 |
| 6 | 闸门 `exit=143` 的语义 | 是 `timeout` 收尾（runner 自身口径），两趟一致且 `result=PASS`；本波未去核 runner 的判定点 | `grep -n '143' tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` |

### 10.1 我自己的两处仪器自伤（如实入册）
1. **等待循环的判据写坏了**：我用
   ```bash
   N=$(pgrep -c -x dotnet 2>/dev/null || echo 0); if [ "$MEM" -ge 1500 ] && [ "$N" -eq 0 ]
   ```
   而 `pgrep -c` 在 0 命中时**先印 `0` 再返回 1** ⇒ `N` 变成 `"0\n0"` ⇒ `[ … ]` 报 `需要整数表达式`（10 次），**那 10 轮"等待判据"实际不可用**（我是靠人工逐行读数决定继续的）。修法：`N=$(pgrep -c -x dotnet || true)` 或 `pgrep -x dotnet | wc -l`。
2. **我把日志写进了主控也在用的目录**：`$HOME/w48a/{01-publish,02-integration-wave,03-retake-arms}.log` 与 `$HOME/w48a/arms/` 恰好与主控选定的同一组路径重合 ⇒ 撞车的一半原因在我（任务书给的就是 `$HOME/w48a/`）。收到裁定后**已停写该目录**，本报告只写仓内 `build/MilBridge/W48A-report.md`。

---

## 11 交付路径与指纹

| 件 | 绝对路径 | sha16 | 用途 |
|---|---|---|---|
| 本报告 | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W48A-report.md` | 见文末 | 车道交付 |
| 闸门行文件（主控跑） | `/home/links-dev/w48a/gate-rows.txt` | **`f52631e520251bd3`** | 冻结器第 2 参数（本波） |
| 冻前 `verify-all` 日志（主控跑） | `/home/links-dev/w48a/06-verify-all-pre.log` | **`a09909bb3a76224f`**（8,664 B） | 冻结器第 1 参数（本波，**已被用于重冻并成功**） |
| 冻结后基线（只读观测） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `live=9b9e3cb7bcb8280b`（553,550 B） | `decl_gen=#47`，`# RE-FROZEN #47` ×1 |
| 步 1 日志 | `/home/links-dev/w48a/01-publish.log` | — | 本车道 |
| 步 2 日志 | `/home/links-dev/w48a/02-integration-wave.log` | — | 本车道 |
| 步 3 日志（本车道） | `/home/links-dev/w48a/03-retake-arms.log` | — | 本车道（含瞬态值，**以 §4.4 稳态值为准**） |
| 步 3 日志（主控） | `/home/links-dev/w48a/03-arms.log` | — | 主控 |
| 步 4 日志（主控） | `/home/links-dev/w48a/04-repin.log` | — | 主控 |
| 闸门两趟日志（主控） | `/home/links-dev/w48a/05-gate-e.log` ／ `05-gate-f.log` | — | 主控 |
| 五臂归档（硬链接，`links=2`） | `build/MilBridge/arm-logs/{tline,tab-zero,tab-anchor,tab-rtl,textlineproto}.log` | 见 §4.1 | 判定输入（本波重钉后） |
| 上一世代 `tline` 旧件（**独立 inode 留存**，供复算 §4.2 的 diff） | `/home/links-dev/w46h/arms/tline.log` | `e061054f73c9a2e7` | 复核用 |

**本报告未改动任何判定输入**：`verify-all.sh`、`known-red.json`（除主控的合规重钉）、`arm-logs/**`（除重取的合规 `ln -f`）、`*.tsv`、`close-wave.sh`、`ACCEPTANCE-BASELINE.md` 全部原样；本车道在仓内只新增本报告一个文件。
**仓内自产件变更汇总（本波，全部由主控/整波链产生）**：`win32shim abf6879c027c5e73`（`#47` 产品修法）、`known-red.json 00a75a87ec5ed0d6`（合规重钉）、五臂日志（`tline` 换、四支同）、`tools/defect-registry-declared.tsv`（主控 `--emit`）、`$HOME/w21-verify/w47-record.txt`（主控按稳态值改写 `tline` 行）。

---

*报告完成时刻：`2026-09-19T23:38 +08:00`；车道 `W48A`；**步 4/5/6（重钉／闸门 ×2／冻前 `verify-all`）由主控执行，本车道只读复核、未跑任何重活**；重冻 `#47` 与冻后 ×2 均不在本车道职责内（§7.3 只作只读观测记账）。*
