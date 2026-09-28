# P1-W19 · `t88` 余项处置报告（`t90`／`scribe`）—— `F-1` 库名形状 ＋ `F-3` 长度纪律 ＋ `F-2`/`F-4`/`F-5`/`O-1` 口径 ＋ 队长错前提更正

写者 `scribe`（`t90` attempt 1／`3e75f75a-d532-4c15-8d5f-273183831dba`）｜读时 `ts=2026-09-29T00:1x–00:3x+0800`｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）
**一切读数现取自算**（含对 `t87` 原件做 A/B 时都自己重跑夹具；**未转述任何人的结论**）。仪器**全部仓外、零构建**：`pwsh 7.6.6` 反射现盘 Release 件（`Assembly.LoadFrom` ＋ `DllImportResolver`）＋ `Marshal.GetDelegateForFunctionPointer` 直调现盘 `.so`。
**写域** ＝ `build/PresentationFramework.Linux/PtsCache.Linux.cs`（唯一产品件）＋ 本载体（新建）＋ `build/MilBridge/P1-entry-attribution-verify.md`（dated 追加）＋ `build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行。**未动** `src/**`／`build/MilBridge/tools/**`／`verify-all.sh`／`close-wave.sh`／哨兵／`docs/ROUTES.md`／`tests/PtsPagesProbe/evidence/**`。

## §0 一句话

`t88` 的五条 `low` ＋ 一条观察**逐条处置**：`F-1` **修**（库名形状放宽到本栈真件名形 `wpfgfx_cor3.so`，**同时收紧**字符面 ⇒ 旧码真收过的 `lib foo.so`／`lib:1.so`／`lib=1.so` 现在**拒**）；`F-3` **在托管侧落长度纪律**（截断名**再也到不了** `entry=`：`cap=5 ⇒ <null> ⇒ unknown`），native 侧真修法**入册未改**（`src/**` 不在写域，附建议补丁）；`F-2` **修**（措辞循环 `return` → `continue`，`unknown` → `dll:x.dll`）；`F-4` **只改注释**（「最近一条缺口」与实现不符——我自算两缺口态复现，实现两代逐字同）；`F-5`／`O-1` **落口径句**（值不改，理由在册）；**队长派单错前提更正入册（队长认账）**。现树正极：`rc=0`／`PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule … domains=pts-declared`／`PTS_GUARD=PASS legs=2/2 fails=-`；零症状回归成对**通过**（`alive`／`app_rc`／`ns`／`native_gap` 逐字同）。

## §1 改动面（逐件现取）＋ 构建

- **产品件** `build/PresentationFramework.Linux/PtsCache.Linux.cs`：`git diff --numstat` ＝ **`92 21`**；件值 `ab5851116641cc5c`（1236 行）→ **`6c4913b9ef462294`（1307 行／83583 B／mode 644）**（`ts=00:26`）。
  **那 21 个删行全在这 5 处改写点上**（逐条点名，**无一处是"顺手删"**）：① `NativeEntryName()` 的 XML 注释 1 行；② 其 ②路旧读法 6 行（定长 `byte[128]` ＋ `PtsGapEntryNameNative(...) == 1` ＋ `CStr` 判非空）；③ `EntryNameFromException()` ①路下**一句错位的重复 `<summary>`**（是 `NativeError` 的注释串了行 ⇒ 注释面缺陷，一并更正）＋ ②路承重注释 1 行 ＋ ②路循环里 `return "unknown"` 1 行；④ `IsLibraryNameShape()` 旧实现 10 行（旧：`StartsWith("lib")` 前缀硬条件）。**口径句/判据/正文无一处删除。**
- **构建**：`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1 -v:m` 经 `bash ~/heavy-slot.sh --wait 900 --max-hold 900 --min-avail 2000 -- …` ⇒ `HEAVYSLOT=ACQUIRED waited=0s`／`0 警告 0 错误`／`已用时间 00:00:33.29`。`bin/Release/PresentationFramework.dll`：`b3f0d129f0234b58` → **`83ba5884bb603296`**。
  ⚠️ 本席 `t87` 踩过的坑已避开：**先 `touch` 源件再构建**（`cp -p` 回拷会让源 mtime 反旧 ⇒ MSBuild 静默跳过编译）；本次源件 mtime `00:22:44` 晚于旧产物 `00:05:42` ⇒ 真编译（`0 警告 0 错误`）。
- **部署件** `~/w67-work/app/PresentationFramework.dll`：`sync-applocal.sh --check` 首趟 `SYNC-APPLOCAL=DRIFT drift=1` ⇒ 跑写模式后 `PASS drift=0`，现取 `83ba5884bb603296`（＝权威件）。两条腿 `POSTSHIM: shim=3bd193e54785b5db pf=83ba5884bb603296（== authority ⇒ 读数可归因）`。`libwpfwin32.so` **未动**（`3bd193e54785b5db`）。

## §2 `F-1` 库名形状（**修**：放宽到真件 ＋ 收紧字符面）

**新口径（逐字，已写进代码注释）**：基名（先去目录）须 ① 只用 `[A-Za-z0-9_.+-]` 且不以 `.` 起头；② `*.dll` 茎非空；③ `*.so` 茎非空（**不要求 `lib` 前缀**）；④ `*.so.<纯数字段>(.<纯数字段>)…`；⑤ 其余 **false**。⇒ **没有**放宽到"任何带点的串"（后缀 ＋ 字符面双判）。

**A/B 两代都是真产物**：**旧** ＝ 部署件（`b3f0d129f0234b58`，与本件头那一代**在册腿证据同一件**）；**新** ＝ 新 Release 件。夹具 33 格，**10 格变、23 格逐字不变**：

| 格 | 输入 | 旧 | 新 | 判 |
|---|---|---|---|---|
| `M11` | `'wpfgfx_cor3.so'`（**本栈真件**） | `unknown` | `dll:wpfgfx_cor3.so` | 放宽（`F-1` 正题） |
| `L7` | `'/opt/x/y/wpfgfx_cor3.so'`（去目录） | `unknown` | `dll:wpfgfx_cor3.so` | 放宽 |
| `M16` | `'lib.so'` | `unknown` | `dll:lib.so` | 放宽 |
| `M17` | `'libfoo.so.1.2'` | `unknown` | `dll:libfoo.so.1.2` | 放宽 |
| `D7` | `'a.b.so'` | `unknown` | `dll:a.b.so` | 放宽（后缀判据） |
| `T5` | `'NotImplemented.so'` | `unknown` | `dll:NotImplemented.so` | 放宽（**如实点名**：它**确实是**库名形状；"该库真存在否"是另一层，本件不承诺） |
| `T1` | `'lib foo.so'`（茎含空格） | `dll:lib foo.so` | `unknown` | **收紧**（旧码无字符面判据） |
| `T2` | `'lib:1.so'` | `dll:lib:1.so` | `unknown` | **收紧** |
| `T3` | `'lib=1.so'` | `dll:lib=1.so` | `unknown` | **收紧** |
| `S1` | 见 §4 | `unknown` | `dll:x.dll` | 放宽（`F-2`） |

**未放松的负样例（两代同判 `unknown`）**：`U1` 长措辞＋`'NotImplemented'`／`U2` `System.NotImplementedException: 'NotImplemented'`／`U3` 裸 `'NotImplemented'`／`U5` 日志行形／`D1` `'foo.bar'`／`D2` `'v1.2'`／`D3` `'x.txt'`／`D4` `'libfoo.so.x'`／`D5` `'.so'`／`D6` `'libfoo.so.1.beta'`／`D9` 只有目录／空串／`<null>` 异常。**未变的正样例**：入口名三格（`E1`／`E2`／`E3` ⇒ **入口名原样**）＋ `L1`／`L2`／`L3`／`L8`／`L9`／`D8`／`T6`／`T7` 逐字同。
**产物侧正极**：本席本趟腿目录 `five_pre_g1.txt` 现取**逐行含** `wpfgfx_cor3.so=4e25e4b27d4d5ae1` ⇒ 「本栈真件名形」是**现盘五件清单里就有的**，不是编的（`F-1` 的立案依据）。

## §3 `F-3` 长度纪律（**托管侧修**；native 真修法入册）

**① native 裸口（两代同值；`B` 面 16 行 A/B 逐字相同）**：`rc=1` 只表示"idx 在册"，**不论有没有截断**。

```
idx=1(LoAcquirePenaltyModule)  cap=4  => rc=1 name=[LoA]
idx=1                          cap=5  => rc=1 name=[LoAc]
idx=1                          cap=12 => rc=1 name=[LoAcquirePe]
idx=1                          cap=128=> rc=1 name=[LoAcquirePenaltyModule]
idx=0(GetFloaterHandlerInfo)   cap=5  => rc=1 name=[GetF]
idx=2（越界）                  cap=128=> rc=0 name=[]
```

**② 托管纪律（新增，同进程同台账）**：旧代 `GapEntryNameAt` ＝ `METHOD-ABSENT`；新代 `GapEntryNameAt(idx,cap)`：

```
cap=4  ⇒ <null>（idx0/idx1 均）        cap=5  ⇒ <null>（idx0/idx1 均）
cap=12 ⇒ <null>（idx0/idx1 均）        cap=128⇒ idx0=GetFloaterHandlerInfo ／ idx1=LoAcquirePenaltyModule
```

纪律两条（代码内逐字）：**①富余判据** `strlen < cap-1`（截断时长度恒为 `cap-1` ⇒ 不认；名字恰好 `cap-1` 长时也判 `unknown` ＝**宁可误报 unknown**）；**②形状判据**（入口名 ＝ C 标识符）。生产路 `GapNameCap = 128`：现册**最长名 32 B**（`LoGetPenaltyModuleInternalHandle`；名册 12 名，我自算）⇒ 富余 **95 B** ⇒ 富余判据在现册**必真**；名册若出现 ≥127 B 的名字则**保守判 `unknown`**（收紧方向，不是放松）。
⚠️ **native 侧不改**（`src/**` 越域）：`t88` 建议的"长度不足返 0"需要在 native 改，**建议补丁**（逐字，供 `src/**` 持有者）：

```c
/* WpfLinuxWin32_PtsGapEntryName：截断即响亮报 0，绝不回一个貌似完整的短名 */
        if (seen == idx) {
            size_t need = strlen(k_pts_entries[i]) + 1;
            if ((size_t)cap < need) { buf[0] = '\0'; return 0; }   /* 长度不足 ⇒ 0（可判） */
            memcpy(buf, k_pts_entries[i], need);
            return 1;
        }
```
配套须同趟处理 `WpfLinuxWin32_PtsGapReport()` 的同类面（`O-1`）与所有读该导出的判据 ⇒ **另一次派单**。

**③「若返回截断名会骗过判据」夹具（跑的是在册牙本体）**：`bash build/MilBridge/tools/pts-pages-guard.sh --g10-name <目录>`（目录内 `app_g1.log` 放一行 `entry=<值>`）：

| 值 | 语义 | 读数 |
|---|---|---|
| `LoAc` | **裸口 cap=5 的截断值** | `FAIL frontier=LoAc off-roster=LoAc roster=12 domains=unattributable` **rc=1** |
| `LoAcquirePe` | 裸口 cap=12 的截断值 | `FAIL … off-roster=LoAcquirePe …` **rc=1** |
| `LoAcquirePenaltyModule` | **纪律读口的真值** | `PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared` **rc=0** |
| `LoSetDoc`（**构造**） | 「截断名恰好落在**另一个在册真名**上」 | `PASS observed=LoSetDoc … domains=pts-declared` **rc=0** |

⇒ 三点如实：(a) 判据按**值**在册对拍 ⇒ **只要**截断值落在某个真名上就会**假绿**（第 4 行证明"值面确实收"，其情境是**构造的**：现册 12 名**无前缀包含对** ⇒ 今天截断只会落到没在册的串上 ⇒ 现实风险是**假红**（第 1／2 行），假绿是**潜在**的）；(b) 潜在假绿的成因**不是名册**，是**读口无纪律**；(c) 纪律把两条路一起关掉：截断值**到不了** `entry=`，生产 cap 只可能给出**带富余的完整名**或 `unknown`。

## §4 `F-2` 措辞循环短路（**修**）

输入 `S1`：`Unable to load DLL 'NotImplemented' or one of its dependencies: unable to find it in DLL 'x.dll'.` ⇒ 旧 `unknown`（首措辞命中、形状不合即 `return` ⇒ 后段**合法库名**被掐掉）→ 新 **`dll:x.dll`**（改 `continue` 续扫四条措辞；**形状校验一格未松**；闭合引号缺失也改为续扫）。
**①路（入口名措辞）刻意保持短路** `return "unknown"`：那里"措辞命中而名字不是 C 标识符"说明**入口名措辞给了假名**，此时改报库名会把"入口名归因"偷换成"库名归因" ⇒ 保留短路并**写进代码注释**（不对称是**有意的**）。

## §5 `F-4` 注释与实现不符（**只改注释**）

**我自算的两缺口读数**（同一进程：**先**调 idx7 `LoAcquirePenaltyModule`、**后**调 idx4 `GetFloaterHandlerInfo`）：

```
D gap_count=2（驱动序：LoAcquirePenaltyModule idx7 → GetFloaterHandlerInfo idx4）
B idx=0 cap=128 => GetFloaterHandlerInfo      ← 在册**表序**首个有计数者（= `anchor=`）
B idx=1 cap=128 => LoAcquirePenaltyModule     ← 在册**表序**末个（= ②路 `idx=count-1`）
D NativeEntryName() => LoAcquirePenaltyModule
D report anchor=[GetFloaterHandlerInfo] frontier=[LoAcquirePenaltyModule] report_len=291
```

⇒ 「**最近调用**的」是 `GetFloaterHandlerInfo`，而 ②路／`anchor=` 给 `LoAcquirePenaltyModule` ⇒ 旧注释「native 台账里**最近一条缺口**的入口名」**与实现不符**（`t88` 的 `F-4` 成立，本席**独立复现**）。**实现不动**（native 侧没有 recency 字段；改实现＝改 native＝越域）⇒ 改注释为「**在册表序**最后一个有缺口计数的入口名（**不是**最近一次调用；与 `wpf_pts_frontier()` 的**调用序**口径不同）」。**旧代/新代 `D` 面 8 行逐字相同**（除新增 `C` 面）⇒ **零行为改动**。

## §6 `F-5`／`O-1`（**只落口径句**，值不改）

- **`F-5`**：我自算 native `#define WPF_PTS_ERR_NOT_IMPLEMENTED (-10000)`（`win32_pts.c:51`）与托管 `A1_STUB_ERR = -10000`（本件现取**同值**）⇒ `NativeError()` 读不到与读到时**都打 `err=-10000`** ⇒ **`err=` 面不能自证"读到没有"**。**本件不改值**：`-10000` 是在册面（`leg_*.env` 的 `native_err=-10000`、台账行 `err=-10000`、判据件对拍都用它）⇒ 换"域外哨兵"会**改动判据面**，属**另一次派单**（须同趟与判据件＋在册证据对齐）。口径句已写进 `A1_STUB_ERR` 上方：**判"读到没读到"只许看旁边那几格**（`entry=`／`native_gap=`／`PTS_GAP entry=…` 台账行），**不许**只看 `err=`。
- **`O-1`**：我自算 native 原文 `if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }` ⇒ "写不下"时 `buf` 是一条**被截断且以 nul 结尾的行**（`t88` 夹具读数 `CAP 250/251/256 buflast_is_nul=True` 与之相符）⇒ **忽略 `rc` 的读者会读到貌似完整的短行**（与 `F-3` 同族）。托管侧守法 ＝ `rc <= 0 ⇒ continue`（**先看 `rc`**），口径句已写进 `NativeReport()`：**绝不许**把 `buf` 的 nul 结尾当作"读到了一条完整行"的证据。

## §7 队长派单错前提更正（**队长认账**）

`t88` 派单背景那句「该名不在声明树（上游无 `DllImport` 声明）」**与现取不符** —— **队长已认账**。**我自算双锚**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs:1569` ＝ `[DllImport(DllImport.PresentationNative, EntryPoint = "LoAcquirePenaltyModule")]`（`:1570` 是它的 `extern LsErr` 声明；`grep -rl 'LoAcquirePenaltyModule' upstream/wpf --include=*.cs | wc -l` ＝ **2**）＋ `src/WpfGfx.Linux.Native/src/win32_pts.c:78` ＝ 在册表 `"LoAcquirePenaltyModule",`。⇒ 「native 侧是 stub」**不等于**「上游无声明」：它**双锚**（在册表 ＋ 上游声明）⇒ 后人**不得**沿用错误前提去弱化 `G10_NAME` 的域判据。

## §8 现树正极 ＋ 零症状回归

```
正极（我自己的腿目录 ~/w281-scribe/t90/legs-after；ts≈00:25）：
  bash build/MilBridge/tools/pts-pages-guard.sh --legs /home/links-dev/w281-scribe/t90/legs-after
  rc=0
  PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared
  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
  `app_g1.log` 现取 `3 entry=LoAcquirePenaltyModule`；`HC-UNHANDLED` **1**（设计内闩）；`five_pre == five_post`（cmp 同）
零回归（成对，**不逐位相等**）：旧极 ＝ 在册 `evidence/leg_*.env`（载 pf=b3f0d129f0234b58）｜新极 ＝ 本趟重跑（载 pf=83ba5884bb603296）
  leg_23 alive yes→yes ｜ app_rc 143→143 ｜ magenta 49943→49943 ｜ colors 844→844 ｜ ae 141283→141283 ｜ ink 428456→428456 ｜ ns 逐字同 ｜ native_gap 1→1 ｜ native_err -10000→-10000
  leg_24 alive yes→yes ｜ app_rc 143→143 ｜ magenta 54533→54533 ｜ colors 852→851 ｜ ae 221857→221246 ｜ ink 423798→423798 ｜ ns 逐字同
```
⇒ **现状＝正极绿 ＋ 零症状回归成立**；`leg_24` 的 `colors −1`／`ae −611` 与 `t88` 记的 ±518／±452 **同量级**（重跑抖动）⇒ 本件**不宣称**逐位相等，只宣称四面逐字同（`alive`／`app_rc`／`ns`／`native_gap`）。

## §9 不变量 / 指纹 / 牙 / 哨兵（现取）

```
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `VERIFYALL-STEPS-DECL: 62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
指纹：`bash ~/w153a/bin/infp.sh fp` ＝ 18e07fc22ff246f64cd1ff20fa8b2be638f646bceeef38515f9e9e3c3f9104f9（ts=2026-09-29T00:27:17.286792021+0800）
      ⇒ 与 `HANDOFF-NEXT.md` 末条 `cell=#1`（ts=00:16:25，我 `t89` 第二趟所写）**同值** ⇒ `HANDOFF_MV=PASS`；
      ⚠️ **本件改动面不在覆盖面内**（`infp.sh list | grep -c 'PtsCache'` ＝ **0**）⇒ 我的改动**不移指纹**（构建产物亦不在覆盖面内：构建前后 fp 同值）。
牙：HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none
    SHELL_QUOTE_TRAP=PASS ｜ PIPEFAIL_SIGPIPE=PASS ｜ REPORTID=PASS files=237 ids=2200 declared=224（`files` 含本载体 ⇒ 落盘后复算）｜ DEFREG=PASS（declared=224 route_ids=224）
    STATICJAWS=FAIL fails=1 n=32 excluded=30 noinfo=1 n_total=62，唯一 HIT ＝ `STATICJAWS_HIT step=SENTINEL-SPEC rc=1`
哨兵：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**
```
**两处非我红（如实点名，未越域去改）**：
① **`SSC_VALUE=FAIL key=PF got=b3f0d129f0234b58 want=83ba5884bb603296`** —— **本件 rebuild 的直接后果**（哨兵里 `PF` 还是旧值）⇒ **哨兵需重写**（按边界属**队长动作**：`wave-push.sh --write`；本席**从未写哨兵**）。
② **`DEFREG_DECLDRIFT=1 keys=KD`** —— `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 被**他者**改过而未同趟 `--emit`；本席**未动**该件与 `declared.tsv`（`t87` 已点过名，至本件仍开）。

## §10 仪器与世界（仓外件清单 ＋ 复盘）

- **夹具驱动器** `~/w281-scribe/t90/probe.ps1`（`pwsh 7.6.6`）：`Assembly.LoadFrom` ＋ `DllImportResolver` 映射到现盘 `.so` ＋ `Add-Type` 造 4 个 `[UnmanagedFunctionPointer(Cdecl)]` 委托类型直调导出（`PtsGapCount`／`PtsGapEntryName`／`PtsGapReport`／`LoAcquirePenaltyModule`／`GetFloaterHandlerInfo`）＋ 反射调私有静态 `EntryNameFromException`／`NativeEntryName`／`GapEntryNameAt`。三份日志：`before-old.out`（部署件旧代）／`after-new.out`（新 Release 件）／`before.out`（旧代首跑，仅留档）。
- **腿目录** `~/w281-scribe/t90/legs-after`（仓外；`SESS_LOGDIR=~/w67-work/logs/legs-after`）⇒ **在册 `evidence/**` 一件未动**（`porcelain` 里 `evidence/arm_A/**` 的 `??` 是**先前**留下的未跟踪项，不是本趟产物）。
- **`--g10-name` 夹具目录** `~/w281-scribe/t90/g10/{naive5,naive12,disciplined,collision}`。
- **踩坑复盘**：① `Marshal.GetDelegateForFunctionPointer` 收**泛型** `Func<>` 类型会抛 `The specified Type must not be a generic type` ⇒ 必须自带具体委托类型（本席用 `Add-Type` 造）。② `pwsh` 把脚本块转成 `DllImportResolver` 委托**可用**（`DELEG-OK`）。③ 备份/回拷纪律照 `t87` 的教训：本件**不回拷源件**，只在树上直接编辑（**先 `stat -c %h` 验硬链＝1 ＋ `cp -p` 备份**，见 §11）。
- 显示位：只用默认 `:237`（属 `:23x`），**未**把 `PTS_GUARD_DISPLAY` 写在命令行上（`t87` 的自判占用坑）。进程按 **PID** 收（无 `pkill`／`pgrep -f`）。

## §11 未做项 / `NOINFO`（具名）＋ 边界自证 ＋ 备份面

- **`NOINFO`①（native 侧真修）**：`WpfLinuxWin32_PtsGapEntryName` 的"长度不足返 0"**未做** —— 该导出在 `src/WpfGfx.Linux.Native/src/win32_pts.c`，**不在本件写域**。**缺什么**：一次持有 `src/**` 的写者的派单（含 §3 的建议补丁 ＋ `PtsGapReport()` 的同类面 `O-1` ＋ 同趟判据/证据对齐）。**本件已把纪律落在判据实际消费的托管读口**，故 native 未改**不构成**"截断名骗过判据"的通路（`cap=4/5/12` 实测全 `<null>`）。
- **`NOINFO`②（`F-5` 换哨兵）**：未做（会改判据面）—— 见 §6，需另派单。
- **`NOINFO`③（多缺口 × 真腿）**：多缺口态只在本席**仓外夹具进程**里造过（`gap_count=2`）；**真腿**始终 `native_gap=1` ⇒ 「多缺口下的腿面读数」**未验**（要造多缺口世界）。
- **`NOINFO`④（截断假绿的现实发生）**：现册 12 名**无前缀包含对** ⇒ 「截断值落在真名上」**不可在现盘真实发生** ⇒ 该格是**构造**情境（§3 表第 4 行已逐字标注）。
- **未跑整趟门禁**（按边界）：只跑判据本体（`--legs` ⇒ `rc=0`）＋静态牙（`static-jaws-check.sh`，唯一 HIT ＝ `SENTINEL-SPEC`，成因见 §9①）。
- **边界自证**：`git status --porcelain` 里**本席**的改动只有 ` M build/PresentationFramework.Linux/PtsCache.Linux.cs` ＋ 本载体・`P1-entry-attribution-verify.md`・`HANDOFF-NEXT.md`；**未** `git add/commit/push`；**未**动 `src/**`／`tools/**`／哨兵／`docs/ROUTES.md`／`evidence/**`。
- **备份面 ≡ 改动面（第 `29` 条自证）**：改动面 ＝ 4 件（产品件、本载体、`P1-entry-attribution-verify.md`、`HANDOFF-NEXT.md` 的 `cell=#1` 一行）；备份面 ＝ `~/w281-scribe/bak/{PtsCache.Linux.cs,P1-entry-attribution-verify.md,HANDOFF-NEXT.md}.pre-t90`（**写前**逐件 `stat -c %h` ＝ **1** 且 `cp -p` 后 `cmp` 通过；本载体为**新建**无前像）；**落盘一律 temp + rename**（`mv` 前后 `mode 644` 已复核）。
- **只增不改自证（`P1-entry-attribution-verify.md`）**：原 94 行**逐字保留为前缀**（`cmp <(cat 原) <(head -n 94 新)` 通过；原末行 `SELF-SHA16 ＝ 9a34a170cd8482f1` 仍在第 94 行），新末行才是**现全文**自报值；现件 **235 行／32552 B／mode 644／sha16 `b259bcb94db89ac3`**。

**本件自证**：`head -n -1 build/MilBridge/P1-entry-attribution-fix2-report.md | sha256sum | cut -c1-16` ＝ 0799a1a4175ea4bf（本行系末行；上列各节即被哈希的全文）

---

## ⏪ 落盘后补记（`t90` 同趟；`ts=2026-09-29T00:2x+0800`，**只增不改**）

- 本件**之后**还落了一笔（写域内、最后写）：`build/MilBridge/HANDOFF-NEXT.md` 本件末行追加 `cell=#1` **一行**（626 → **627** 行）⇒ 现取 `400171e13c4cc307`；那行的 `ts=00:27:33`、携带值 ＝ `18e07fc22ff246f64cd1ff20fa8b2be638f646bceeef38515f9e9e3c3f9104f9`（与上一条**同值**：本件改动面不在覆盖面内 ⇒ **不是位移**）。`bash build/MilBridge/tools/handoff-machine-values-check.sh` 复算 ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**。
- 落盘后复算：`PtsCache.Linux.cs` ＝ **`6c4913b9ef462294`／1307 行／`92 21`**（未再动）；`P1-entry-attribution-verify.md` ＝ **`b259bcb94db89ac3`／235 行**（未再动）；`REPORTID=PASS files=237 ids=2200 declared=224`（本载体计入）；`infp.sh fp` ＝ `18e07fc2…`（未移）。
- 本补记**不改变** §0–§11 的任何读数与判词（那条 `cell=#1` 与本节均为**登记面**，无产品行为）。
**本件自证（末行；`t90` 落盘后重算）**：`head -n -1 build/MilBridge/P1-entry-attribution-fix2-report.md | sha256sum | cut -c1-16` ＝ 6b4b6f295ea368a2

⏪ 口径更正（`t90` 同趟，`ts=2026-09-29T00:28:07.055710403+0800）：上文那句 `＝ 0799a1a4175ea4bf（本行系末行；上列各节即被哈希的全文）` 是**补记加入之前**全文的自报值 ⇒ 其中"本行系末行"**已作废**（只增不改：原句保留）；**现全文**自报值看**本件末行**。
**本件自证（末行 · 最终）**：`head -n -1 build/MilBridge/P1-entry-attribution-fix2-report.md | sha256sum | cut -c1-16` ＝ 6d353d7d0d41c029

⏪ 收尾复算（`t90` 同趟最后一笔，`ts=2026-09-29T00:29:18.287185422+0800；**只增不改**）：上列 §9 的 `STATICJAWS=FAIL fails=1`（唯一 HIT ＝ `SENTINEL-SPEC`）是**本件 rebuild 之后、哨兵重写之前**那一瞬的读数；同一趟**他者**（按边界＝队长动作）已重写哨兵（`~/wfp-runs/bridge-frozen.flag`，现取 `PF=83ba5884bb603296`／`SHA=4e25e4b27d4d5ae1`／`WIN32SHIM=3bd193e54785b5db`，mtime `2026-09-29 00:25:56.830178652`；**本席从未写哨兵**）⇒ 现取复算：`bash build/MilBridge/tools/sentinel-spec-check.sh` ⇒ **`rc=0`／`SSC=PASS`**，`bash build/MilBridge/tools/static-jaws-check.sh` ⇒ **`STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`（0 HIT）**。⇒ §9① 那处红**已消解**（不是本席改的），§9② 的 `DEFREG_DECLDRIFT=1 keys=KD` **仍未闭**（他者面）。
**本件自证（末行 · 收尾最终）**：`head -n -1 build/MilBridge/P1-entry-attribution-fix2-report.md | sha256sum | cut -c1-16` ＝ 534011faa64c3e75
