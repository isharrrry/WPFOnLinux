# P1 `entry=` **归因退化**修复（`t87`／`scribe`）—— `NativeReport` 读得全 ＋ `EntryNameFromException` 措辞分支与形状校验

写者 `scribe`（attempt 4／`848f2db3-8d7d-4061-8f59-77cf934ba49c`）｜读时 `ts=2026-09-28T23:5x–2026-09-29T00:0x+0800`｜**一切读数现取自算**，每格带亚秒 `ts=`
写域＝`build/PresentationFramework.Linux/PtsCache.Linux.cs`（唯一产品件）＋ 本载体 ＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行；**未动** `src/**`／`tools/**`／哨兵／`evidence/**`／`docs/ROUTES.md`。

## §0 一句话
两处都修：**①** `NativeReport()` 按 native 的**返回约定**（`-1` ＝ 写不下）做**放大缓冲重试**，并把「台账真名」的读取改到**缺口口径**（`last=` → `PtsGapCount()/PtsGapEntryName()` → `anchor=` → 兜底 `frontier=`）；**②** `EntryNameFromException()` 改成**按措辞分支 ＋ 形状校验**，**绝不再产出** `dll:NotImplemented` 这类合成名。**现树正极**：修后 `PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule … domains=pts-declared` ＋ **`PTS_GUARD=PASS legs=2/2 fails=- …`（`rc=0`）**；修前同一世界（只换 managed 件）为 `rc=1`／`FAIL frontier=dll off-roster=dll`。零症状回归：两腿 `alive=yes`／`app_rc=143`／`ns` 面逐字未变。

## §1 ① 缓冲读不全 —— 机制（native 原文）＋ 修法 ＋ 成对读数
- **native 返回约定（现取原文，`src/WpfGfx.Linux.Native/src/win32_pts.c`，行号仅本次有效）**：
  - `int WpfLinuxWin32_PtsGapReport(char *buf, int cap)`；尾部逐字：`if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }` ／ `return n;`
  - ⇒ **`>0` ＝ 写入长度；`-1` ＝ 写不下（不截断、不静默，`buf` 已被终结）**。**没有**「所需长度」语义。
- **修法（口径写死）**：`NativeReport()` 改成 **`for (cap = 256; cap <= 65536; cap *= 16)`** 的**放大重试**：`rc <= 0` ⇒ 放大再试（`256 → 4 KiB → 64 KiB`），`rc > 0` ⇒ 按 `rc`/nul 截取返回；`64 KiB` 仍读不到 ⇒ 空串（**不猜**）。
- **约定实测（仓外 harness，对**同一**现盘 shim 现取；`ts=00:0x`）**：
```
NAT cap=64   => rc=-1  bytes=63    （截断且如实报 -1）
NAT cap=250  => rc=-1  bytes=249   （行内需要 250 字符 ⇒ cap 必须 >250）
NAT cap=251  => rc=250 bytes=250
NAT cap=256  => rc=250 bytes=250   （**空闲态**行 250 B ⇒ 距 255 只剩 5 B 余量）
NAT cap=4096 => rc=250 bytes=250
```
- **「台账真名」的口径（一次中途发现的更正，如实记）**：先只把 `NativeReport()` 修好时，现树读数是 `entry=CreateInstalledObjectsInfo` —— **是条真名，但不是台账里那条**。查 native 得：`frontier=` 走 **`g_pts_seen[]`**（**被问过**，真实现也算），而台账行 `PTS_GAP entry=<名>` 走 **`g_pts_calls[]`**（**只在走 `wpf_pts_gap()` 的 stub 上涨** ＝ 缺口口径）；另 `t81` 压形时把 `last=`（缺口名册末名）**删掉了**，改印 `anchor=`。⇒ 改口径为：**`last=` →（缺口专用读口）`PtsGapCount()`＋`PtsGapEntryName(count-1)` → `anchor=` → 兜底 `frontier=`**（兜底项在判据件注释里注明「不是缺口名」）。
- **成对读数（现树真腿，同一 shim `3bd193e54785b5db`；managed 件换代前后）**：
```
修前（managed `cff36ea4c64455e4`）ts=23:56:2x  entry=dll:NotImplemented ×2   ⇒ 判据 rc=1／FAIL frontier=dll off-roster=dll roster=12 domains=pts-declared,unattributable
修后（managed `b3f0d129f0234b58`）ts=00:06:1x  entry=LoAcquirePenaltyModule ×2 ⇒ 判据 rc=0／PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared
（两趟腿的 native 台账行均为 `PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1` ⇒ 修后**与台账逐字同名**）
```

## §2 ② 异常取数 —— 措辞分支 ＋ 形状校验（仓外 harness，`MS.Internal.PtsHost.WpfLinuxPtsGap.EntryNameFromException` 反射调用）
| # | 输入消息 | 修前 `cff36ea4…` | 修后 `b3f0d129…` |
|---|---|---|---|
| ① | `Unable to find an entry point named 'LoAcquirePenaltyModule' in shared library 'libwpfwin32.so'.` | `LoAcquirePenaltyModule` | `LoAcquirePenaltyModule` ✓ |
| ② | `Unable to find an entry point named 'LoSetDoc' in DLL 'NotImplemented'.` | `LoSetDoc` | `LoSetDoc` ✓ |
| ③ | `Unable to load shared library 'libwpfwin32.so' or one of its dependencies.` | `dll:libwpfwin32.so` | `dll:libwpfwin32.so` ✓ |
| ④ | `Unable to load DLL 'PresentationNative_cor3.dll': The specified module could not be found.` | `dll:PresentationNative_cor3.dll` | 同 ✓ |
| ⑤ | `Unable to load shared library '/usr/lib/x86_64-linux-gnu/libfoo.so.1' or …` | `dll:libfoo.so.1` | 同 ✓ |
| ⑥ | `Unable to load shared library 'NotImplemented' or one of its dependencies.` | **`dll:NotImplemented`** ✗ | **`unknown`** ✓ |
| ⑦ | `System.NotImplementedException: 'NotImplemented'` | **`dll:NotImplemented`** ✗ | **`unknown`** ✓ |
| ⑧ | `Unable to find an entry point named 'LoSetDoc' in shared library 'libwpfwin32.so'.` | `LoSetDoc` | `LoSetDoc` ✓ |
| ⑨ | `<null>` 异常 | ``（空串） | `unknown`（哨兵统一） |
- **新口径（逐字）**：① **入口名措辞** `named 'X'` ⇒ 取**入口名原样**（不加前缀），且必须**是 C 标识符形状**（首字符字母/`_`，其余字母数字/`_`）；② **库名措辞**（`Unable to load shared library 'Y'`／`Unable to load DLL 'Y'`／`in shared library 'Y'`／`in DLL 'Y'`）⇒ 去掉目录、加 **`dll:`** 前缀，且**只接受真库名形状**（`*.dll` 或 `lib*.so`／`lib*.so.<数字>`）；③ 其余（含**措辞命中但形状不合**）⇒ **`unknown`**。`Describe()` 侧把「取不到」哨兵统一成 `"unknown"` 后再决定是否采用。

## §3 ③ 现树正极 ＋ ④ 零症状回归（同一世界、只换 managed 件）
```
③ 修后：bash build/MilBridge/tools/pts-pages-guard.sh --legs /home/links-dev/t87-runner/legs-after3
   rc=0  ts=00:06:19
   PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
   PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
   修前（同一 shim／同一腿目录形态，只换回 managed 前像）：rc=1 ts=00:06:19
   PTS_G10_NAME=FAIL frontier=dll off-roster=dll roster=12 domains=pts-declared,unattributable decl=none（域归因**失败**…）
   PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(dll) cannot=- diag=- direction=in-file phase=degraded
④ 零回归（before → after）：
   leg_23  alive=yes app_rc=143 magenta 50094→49943 colors 843→844 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae 140971→141283 ink 428341→428456
   leg_24  alive=yes app_rc=143 magenta 54684→54533 colors 851→852 ns=HandyControlDemo.UserControl.FlowDocumentDemo ae 221857→221857 ink 423683→423798
   `HC-UNHANDLED` 两趟均 **1**（＝**设计内的闩记录**，逐字：`[HC-UNHANDLED] #1 PtsUnavailableException: PTS 能力已在本进程内判定不可用（首次失败见 InnerException）…`）⇒ **未增加**
   `NAMED` 面两趟均 `managed_unavail=1 err=-10000 native_gap=1 native_err=-10000`；`five_pre == five_post`（各趟内）；
   ⚠️ 同一量级内的微小位移（`magenta ±151`／`ink +115`／`ae ±312`）是**重跑抖动**（占位像素统计），**`alive`／`app_rc`／`ns`／`native_gap` 四面逐字未变** ⇒ 判为**无症状回归**（不宣称逐位相等）。
```

## §4 世界与流程（如实记，含三处被挡与一处临时手段）
- **app 目录必须先同步**：`sync-applocal.sh --check ~/w67-work/app` 首趟 `SYNC-APPLOCAL=DRIFT drift=1`（我重建的 `PresentationFramework.dll` 与私有 app 目录不一致）⇒ 跑 `sync-applocal.sh <appdir>`（写）后 `drift=0`（每个 A/B 半程各做一次，共 2 次；`manifest` 5 行）。
- **两次腿被挡**（都不是腿本身的问题，如实记）：① `device=NOINFO reason=app-stale`（同上的 drift）② `device=NOINFO reason=display-occupied display=:237 pid=…` —— 成因是**我自己**把 `PTS_GUARD_DISPLAY=:237` 写在了命令行上（该脚本的口径：自己的子壳会被当成"别的车道占了显示"）⇒ 改成**不带该 env** 启动即通。显示位只用 `:237`（属 `:23x`）；装置按 **PID** 自收。
- **临时探针（已撤，最终件零残留）**：为定根因，曾用两版临时探针（`NativeError()` 兜底哨兵改 `-424242`；`NativeEntryName()` 返回 `unknown(empty)` 等标记）＋一次探针腿；**最终件** `grep -c 'PROBE-v2\|unknown(empty)\|unknown(norep)\|424242'` ＝ **0**。
- **在册证据未动**：`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 现取 `3729b8b5aa6b3f8d`、`entry=` 面 `entry=LoSetDoc`（**本件只读**；腿产物全在仓外 `~/t87-runner/legs-*`）。
- **仓外件**：harness `~/t87-runner/harness/{t87harness.csproj,Program.cs}`；腿目录 `~/t87-runner/legs-before`／`legs-after2`／`legs-after3`／`legs-probe*`；日志 `~/t87-runner/logs/*.log`；备份 `~/w281-scribe/bak/PtsCache.Linux.cs.pre-t87`。

## §5 不变量／指纹／已接线牙（现取）
```
不变量：`^run_step "` ＝ 62 ｜ coverage ＝ 234 ｜ `# VERIFYALL-STEPS-DECL: 62 gen=#81` ｜ `--expect 234` ⇒ 四条未变
指纹：`inputs_fp` ＝ bf1edb1bf82c15137dab0be3d62a0d7fdc05fb326f02434cda2d230ca1b074de（ts=00:06:42）
      ⚠️ **本件改动面不在覆盖面内**（`bash ~/w153a/bin/infp.sh list | grep -c 'PtsCache.Linux.cs'` ＝ **0**）⇒ 我的改动**不移指纹**
哨兵：两枚 `cmp IDENTICAL`
牙：SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 ｜ HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 ｜ STATICJAWS=<见 §5.1> ｜ REPORTID=PASS files=234 ids=2200 declared=224 ｜ DEFREG=PASS declared=224 route_ids=224
两处**不是本件**的红（如实点名，未越域去改）：
  ① **SENTINEL-SPEC=FAIL** —— 逐字：`SSC_VALUE=FAIL key=PF got=8ef62d37e7c2ce2e want=b3f0d129f0234b58 path=…/PresentationFramework.dll`
     ⇒ **本件 rebuild 让 `pf` 换代**（`8ef62d37e7c2ce2e` → `b3f0d129f0234b58`）而哨兵里 `PF=` 仍是旧值 ⇒ **哨兵需要重写**（按边界**那是队长的动作**；`wave-push.sh --write`。本席**从未写哨兵**）。
  ② **DEFREG_DECLDRIFT=1 keys=KD** —— `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现取 `a92e6e73f2a4f4a5`／`mtime 23:23:19`，而 `declared.tsv` 的 `# DECL-ANCHORS` 载 `KD=95224a4c310900e5` ⇒ **他者改了 KD 但未同趟 `--emit`**（`porcelain` 里该件**未**显示为 `M` ⇒ 已被提交）。`DEFREG` 本体仍 `PASS`（`declared=224 route_ids=224`）。⇒ 归他者/队长补一次 `--emit`；本席**未动**该件与 `declared.tsv`。
```
§5.1 `STATICJAWS` 现取（本件收尾时，`ts=2026-09-29T00:07:38.358+0800`）：**`STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62`**，唯一 HIT ＝ **`SENTINEL-SPEC rc=1`**（＝上表①，**本件 rebuild 的后果**，非判据面）；`STATICJAWS_NOINFO step=FrameProbe-frame rc=2`（约定）。

## §6 第 `29` 条自证（备份面 ≡ 改动面）＋ 边界
- **改动面 ＝ 3 件**：`build/PresentationFramework.Linux/PtsCache.Linux.cs`（`d940a3471aec8e73`／1103 行 → **`ab5851116641cc5c`／1236 行**；`numstat 156 23`）／本载体（新建）／`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` **一行**。
- **备份面 ＝ 3 件**：`~/w281-scribe/bak/{PtsCache.Linux.cs,HANDOFF-NEXT.md}.pre-t87` ＋ 本载体为新建（无前像）⇒ 逐件 `cmp`／`cp -p` 已执行；**未**只备份"我记得要改的那几件"。
- **未改**：`src/**`（native 未动；在册 native 改动系 `t81`／他人）／`build/MilBridge/tools/**`／`verify-all.sh`／`build/close-wave.sh`／哨兵／`docs/ROUTES.md`／`evidence/**`。未跑整趟门禁、未 `git add/commit/push`。

## §7 未做项 ＋ `NOINFO`（具名）
- **`NOINFO`① **本件**未把在册证据换代**（`evidence/app_g1.log` 仍是 `entry=LoSetDoc`＝`t78` 那一代）：门禁里读到的具名是 `LoSetDoc`，而**本轮真前沿**是 `LoAcquirePenaltyModule` ⇒ 「门禁读数 = 现盘前沿」这一条**需另派单**（我不动证据目录）。**缺什么**：一次在册腿重取（同一套重活流程）。
- **`NOINFO`②** 未证 `PtsGapReport` 在**更多缺口**（>1 条）下的名字口径：本轮只有 1 条缺口记录 ⇒ `count-1` 与 `anchor=` 同解；多缺口时的"末名"语义**未验**（要造多缺口世界）。
- **`NOINFO`③** 未跑整趟门禁 ⇒ `PTS-PAGES` 步的端到端绿未验（本件只跑判据本体：`rc=0`／`PTS_GUARD=PASS`）。
- **`NOINFO`④** 未核 `WpfLinuxWin32_PtsGapReport` 的 64 KiB 上限在真实超长行下的行为（未造 >64 KiB 行）。
**本件自证**：`head -n -1 build/MilBridge/P1-entry-attribution-report.md | sha256sum | cut -c1-16` ＝ `dbd9349ba42755c9`（本行系末行；上列各节即被哈希的全文）
