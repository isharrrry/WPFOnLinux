# 波 `#80` 预登记（**已落** · 主控 `2026-09-28` 落册）
> **状态**：**已落**（主控 `2026-09-28T10:22`；落仓时机＝`t46` 冻前 `verify-all` **全绿之后、冻结之前** —— 此刻链持静止、不写仓）


## §1 本波是什么（`#79` 之后的收口代）
- **产品改动两族**：① 崩溃族（`TASK-0209` 夹具 `src/WpfGfx.Linux.Native/tests/queue_corrupt_chain_fixture.c` ＋ `si_addr` 两点校准；`TASK-0201` 现件代重取 `0/175`）② PTS 增量（`TASK-0302` 首格：`win32_pts.c` 9→7 stub、`libwpfwin32.so` `e8127a3d…→6825dd70…`、`exports 554→556`、`PtsCache.Linux.cs`、`PresentationFramework.dll 12fb36e7…→876f70dd…`）。
- **仪器/账目改动**：`#79` 收口三牙（`CSDECL`／`DEFREG_DECLDRIFT_KEYS`／漂移进日志）＋ `D-G170`–`D-G175` 登记 ＋ `nul-bytes` 判据面划界 ＋ PTS 腿跑器装配口径与两道硬闸 ＋ `pts-gap-decl.txt` 在册数改准。
- **本波为什么必须冻结新代**：`#79` 冻结之后，**覆盖面内**的件被多次改动（`t43` 首次越代 `4c096e9c…→42e102ec…`；`t40` 两工具件；MVP 两族）⇒ 现树覆盖面输入**已不在 `#79` 的声明里**。

## §2 冻结位移声明（**机读行必须与 `GENS['#80']` 逐字段一致**）
```
WFREEZE-DECL: gen=#80 allow_changed=pc,pf,windowsbase,provider,dwf,win32shim pf_required=False
```
**依据（分两段，不许合并成一句）**：
- **实测三位**（`waveman` `2026-09-28T10:05:30` 现取，按 `wave-freeze-consistency-check.py:104-115` 权威路径表）：`pf 12fb36e7b0df1802→876f70dd7c0cbf7a`（PTS 产品改动）｜`provider 8cb1b50619f4c133→7e8a217b4165a6b9`（重建）｜`win32shim e8127a3d7128d417→6825dd7071387a46`（PTS 原生改动）。
- **重建驱动五格**（`D-G92` 族：`pc`／`pf`／`windowsbase`／`provider`／`dwf`）：整波重建会改写托管件内嵌的 `*.pdb` **绝对路径** ⇒ 字节变（`#76`→`#77`、`#77`→`#78`、`#78`→`#79` 三代同形）。
- ⇒ `allow_changed` = 实测三位 ∪ 重建驱动五格 = **`{pc, pf, windowsbase, provider, dwf, win32shim}`**；**`pf_required=False`**（本代**不要求任何特定位必动**）。
- ⚠️ **预登记两次低估的先例**（`#78` 预写 3 实测 6；`#79` 预写 1 实测 5）：**若冻结实测超出本集合 ⇒ 按 dated 追 更正本行（原文逐字保留）**，并在 `P0-w80-report.md` 具名"低估了哪几位、为什么"。

## §3 判据与绿名单
- **绿名单**＝继承 `#79`（同一套 55 步 / 同一批工程），新增/生效的牙：`CSDECL`（唯一权威声明点）／`DEFREG_DECLDRIFT` ＋ `_KEYS`（漂移进日志并点名）／`NULBYTES` 判据面划界／PTS 腿跑器两道硬闸（`app-stale-vs-authority`／`app-swapped-during-run`）／`PTSGAP`（在册数面）。
- **本代必须同趟成立的读数**：`DEFREG=PASS declared=210`（`D-G170`–`D-G175` 在册）｜`REPORTID=PASS`｜`PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556`｜`PTS_GUARD=PASS legs=2/2 … phase=degraded`｜`run_step=55`／`--expect 226`。
- **前沿位移的**唯一**载体**：`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log` 的具名行 `entry=LoCreateContext`（**`PTS-PAGES` 只读 `leg_*.env` 列、不读 `entry=` ⇒ 它的绿对该位移零证据力**）。

### 3.1 回归判定（本波**不做任何回归判定**）

- 本波不做任何回归判定；硬形态机读行（与 `#78`／`#79` 逐字同形）：

`PREREG-NO-REGRESSION-DECISION: not-applicable-product-change-wave-80`
- **为什么**：本波 = **账目/仪器收口 ＋ PTS 命名线推进**合波。`win32shim`／`pf`／`pc`／`windowsbase`／`provider`／`dwf` 六位的位移是**整波重建驱动**的（同输入连做两次整波亦不复现，证据见 `build/MilBridge/P0-w80-report.md` §六），**不含**任何"修前/修后"成对产品对比 ⇒ **四要件对本波不适用**。本行是**硬形态声明**（不是散文"提及"）。
- **三态词表**：`REGRESSION`／`NOINFO`（**皆见本节**；`NOINFO` 不算绿）；判据件路径 `build/MilBridge/tools/regression-decision.py`（**本波不调用它** —— 不适用）。

## §4 停手条件与"不许假冻结"
1. **链必须看冻结 `rc`**：拒冻 ⇒ **不落** `POST.done`、**不跑** post（`#78` 那次"有 `POST.done` 有 post 读数、没有记录"＝假冻结，`D-G155`/`D-G161` 族）。
2. **标记必须携带判词**：`push_rc=`（取不到写 `none(reason)`）／`stop_line=` 永远非空；**标记存在 ≠ 链成功**（认 `PUSH_RC=` ＋ 远端/本地）。
3. **九位是重建驱动的** ⇒ **冻结与哨兵必须是最后两个动作**，并**同时印"冻结那一刻"与"写哨兵那一刻"**两个时刻；不一致 ⇒ 具名差异位/差异量 ＋ 判定"结构性 vs 一次性"。
4. **"远端事实"只许 `git ls-remote` 现取**（本地 tracking ref 是缓存）；**哨兵按内容判**（`cmp` 相同 ≠ 当代）。
5. 推送清单必须覆盖**本波全部拟定落仓件**（不只覆盖面内件）＋ `porcelain` **逐件有归宿**。

## §5 资源闸
- 重活走 `~/heavy-slot.sh`；**每批开跑前**用 `/proc/meminfo` 现取 `MemAvailable`/`SwapFree`（**不用** `free | grep`，本机输出本地化）。
- **停止线**：`MemAvailable<2000MB ∨ SwapFree<512MB` ⇒ **按 PID 停链**、落盘 `CHAIN_ABORTED reason=…`、保留已完成件、报告具名"停在哪一步、为什么"（**不许**静默缩短）。

## §6 未闭项（具名，不许静默）
1. `N2-b'`／`N2-c`／`N3` 三个探测器**本波不实现**（`NOINFO reason=detector-not-implemented`；归属 `t12` 遗留；`N3` 的 `rc=134` 须**两次应用运行实测**）。
2. `PTS-PAGES` 的"零证据力"射程句**已入报告、未入判据件自身**（建议下一波加）。
3. `session_inner.sh:18` 的 `W67_DISPLAY:-:237` ⇒ 改外显示号时 Xvfb 与应用错位（低危，非默认路径；本轮不修以免使 `t53` 的复验失效）。
4. `#79` 块与哨兵的 `provider` **两读不同**（`759ac1686e5ef87d` vs `8cb1b50619f4c133`），且现场已是第三个值 `7e8a217b4165a6b9` ⇒ **三个时刻都写进 `P0-w80-report.md` §六**。
5. X 侧卫生：`2026-09-28 09:50` 的冻前那一步**因 `:99` 被他方 Xvfb（pid 3206112）占用**而 `STOP=pre-red`（`X-CENSUS leaks=1`）⇒ 本波记录"**起链前须查 `:99` 是否被占**；被占 ⇒ 报红并具名 PID，**不许**静默换显示号"。

## §7 复算命令（逐条）
```
bash build/selfbuilt-config.sh                         # 权威配置（Release）
bash build/bridge-src-fp.sh                            # bs_fp
bash build/MilBridge/tools/defect-registry-check.sh     # DEFREG / DECLDRIFT / _KEYS
bash build/MilBridge/tools/pts-gap-count-check.sh       # PTSGAP（在册数面）
bash build/MilBridge/tools/nul-bytes-check.sh --list | grep -c .agent-teams   # 判据面划界（应为 0）
bash verify-all.sh                                     # 冻前/冻后各一趟（55✅/0❌）
bash ~/w79c/bin/w79-push.sh                            # 一笔推送（清单须覆盖全部拟定落仓件）
cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag
```

## §8 落仓读数（本件自身的账）
- 落仓前 / 落仓后两次现取 `inputs_fp` **同值**（主控审计 134）⇒ **本件（`docs/*.md`）不在 `fp_inputs()` 覆盖面内**，加它**不动** `inputs_fp`。
- 本件**只新增、不改任何既有件**；`GENS['#80']` 由主控在**仓外**冻结器落仓。
- 落仓后**链持静止**（`waveman` 不再动仓），直到 `GO`。
