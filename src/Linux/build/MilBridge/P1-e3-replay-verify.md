# P1-W109 独立复核（`verifier`／`t208`）—— `t205`（`E3` 抓取重放去重）

> **判词：`pass`** —— 去重逻辑**真落且位置对**、"真点击一条未丢"可复核、两条反腿的判读**方向诚实**（判定支路未被行使 ≠ 判据错）、非副本口径如实自陈。另点名 **3 条 low**（`E-1` 计数与其表不符／`E-2` "拒收"措辞与读数矛盾／`E-3` 行号跨代混用）＋ 3 条观察，**均不改变本判词**。
>
> **被核件（本席现取，读时 `2026-09-29T23:17–23:20+0800`）**
> | 件 | 行数 | sha16 | 自证（复算） |
> |---|---|---|---|
> | `build/MilBridge/P1-e3-replay-report.md`（`t205` 载体） | **78** | `bcb0b2abf998c030` | `f435138d9286a5fe` **MATCH ✓** |
> | `build/MilBridge/P1-e3-replay-criteria.md`（`t203`） | **106** | `a48c8de388a84218` | `abc84baa197b1e78` **MATCH ✓** |
> | `build/MilBridge/P1-e3-grab-recon.md`（`t204`） | **93** | `58ffdfe40bc76546` | `ef948fb00b3211d1` **MATCH ✓** |
> - 产品件 `src/WpfGfx.Linux.Native/src/win32_x11.c` 现取 **`4576fc68bcbbf329`／2189 行**（＝其自陈收尾代 ✓）；**改前件** `~/t123-runner/bak/win32_x11.c.pre-t205` 现取 **`8177fb1dee6c6951`／2102 行** ✓；`git diff --numstat HEAD` ＝ **`87 0`**（删行 **0**）✓
> - 主链 `.so` 现取 **`26da177686acb1f0`**／`exports.txt` **669 行** ✓
> - **§A 自用**：行号一律整行取；本件**只读文件＋用已有日志**（未起 `Xvfb`／未跑腿，遵派单资源约束）；未改任何人写的件、未 `git add/commit/push`。

---

## §1 判据① 去重逻辑真落、位置对、读数无条件（**逐行现取**）

**闸＝交付代 `:1357-1394`，交付点＝`:1395 push(...)`／`:1397 produced++`** ⇒ **闸在交付点之前** ✓（改前代 `:1308` 即该 `push`，见 §6 与 `E-3`）。三条件逐行：
```
1359:                 const int is_btn123 = (b == Button1 || b == Button2 || b == Button3);
1360:                 if (is_btn123 && down) {
1361:                     const int dt = (g_x_e3_live_button == (int)b)
1362:                                  ? (int)(ev.xbutton.time - g_x_e3_live_time) : -1;
1364:                     if (g_x_e3_live_button == 0) {          /* 新点击：② 开窗 */
1370:                     } else if (g_x_e3_live_button == (int)b && dt >= 0 && dt <= wpf_e3_dt_bound_ms()) {
1372:                         g_x_e3_cand++; g_x_e3_replay_set |= (1UL << (b & 31));
1373:                         if (wpf_e3_dedup_on()) {
1374:                             g_x_e3_drop++; g_x_e3_drop_set |= (1UL << (b & 31));
1377:                             break;                          /* ← 不交付：produced 不涨 */
1382:                     } else {   /* ③′ 不成立 ⇒ 照常交付并重置基准 */
1386:                                     dt, 0, 0, "DELIVER(other-button-or-dt-too-big)");
1389:                 } else if (is_btn123 && !down) {  if (g_x_e3_live_button == (int)b) g_x_e3_live_button = 0;
```
⇒ **条件与自陈逐字相符** ✓：同 button ∧ 无中间 release（窗口在 `:1389-1390` release 处关闭）∧ **序关系** `dt ≥ 0` ∧ `dt ≤ bound`。**`dt` 单位/口径**：`ev.xbutton.time` 的差（ms）✓；`bound` 缺省 250、`<1 ⇒ 1`（`win32_x11.c:329-336` 现取）✓、`WPF_E3_REPLAY_DEDUP` **缺省开**（`:326-327`：只有显式 `0` 才关）✓。
**读数行无条件 ✓（新纪律落地）**：`wpf_e3_note`（`:337-354`）在 **4 条 press 分支 ＋ release 分支**都被调用（`:1368/:1375/:1380/:1386/:1391`），打印体（`:344-352`）含 `press/deliver/drop/cand/replay_set/drop_set/subset_ok/dt_ms/bound_ms/bound_declared/dedup/live_btn/e3=…gran=single-click via=…noinfo=…` ⇒ **无阈值、无静默门** ✓。
**① NC 路径真在闸前 `break` ✓**：交付代 NC-press `:1307 if (ht != HTCLIENT) { … :1335 break; }`、NC-release `:1338-1354 break` ⇒ 两者都在闸（`:1357`）**之前** ⇒ 「本侧唯一显式抓取（`wpf_x11_pointer_grab`，用途＝NC 拖动）产生的 press 永不进闸」**结构性成立** ✓（唯一显式抓取现取 `:2102 void wpf_x11_pointer_grab`；recon §5 表① 已分离）。

## §2 判据② "真点击一条未丢" 可复核（**本席自算，逐腿**）

**逐腿累计（`grep -a '\[E3-REPLAY\]' <腿> | tail -1` 现取）**：
| 腿 | press | deliver | drop | cand | 该腿 `e3=` 取值集 |
|---|---|---|---|---|---|
| `nav11` | 1 | 1 | 0 | 0 | `DELIVER(first-press)`／`DELIVER(release)` |
| `probeclick` | 2 | 2 | 0 | 0 | 同上 |
| `open1`／`open2` | 2／2 | 2／2 | 0 | 0 | 同上 |
| `real3` | 4 | 4 | 0 | 0 | 同上 |
| `dup1` | 3 | 3 | 0 | 0 | 同上 |
| `dupoff` | 2 | 2 | 0 | 0 | 同上（`dedup=off` ✓） |
| `slowdt` | 2 | 2 | 0 | 0 | 同上 |
| **小计（8 条"真点击"腿）** | **18** | **18** | **0** | **0** | — |
| `on1`／`on2`／`on3`／`off1` | 3／3／3／3 | 同 | **0** | **0** | ＋`DELIVER(other-button-or-dt-too-big)` |
⇒ ① **`deliver == press`、`drop=0`、`cand=0` 逐腿成立** ✓（12 腿合计 30 pressed／30 delivered／0 dropped；其中 4 条为替身 press，见 §4）；② **`press` 真加得起来**：**8 条腿 ＝ 18**，不是载体 §0 所写的 **15**（见 `E-1`——其 §3 表逐行与日志**都对**，只有 §0 那句数错）。
**产品可见读数（本席现取，日志在册）**：`hs4.log:4` ＝ `AE(open1)=29866 children_before=7 children_after=8`；同件 `:10` `AE(open2)=29866 children_before=7 children_after=8`；另 `:24/:30/:36` 为 `dupoff/slowdt/real3` **同值** ⇒ 「子窗 7→8 ∧ 全屏 `AE=29866`」**可复核** ✓（2 独立样本 `open1`／`open2` 同值 ✓）。

## §3 判据③ 两条反腿的判读 —— **区分清楚："夹具没送到" ≠ "判据错"**

**① `subset_ok=1` 是平凡真 ⇒ 它自己不当绿 ✓**：载体 `:14`（"⚠️ 已打印且判为 1（`subset_ok=1`），但**两集合今天皆空 ⇒ 判定为平凡真（vacuous）**，**不得**当绿"）、`:31`（§2 行③同义）、`:71` 三处到位 ✓；且 `drop=cand=0` ⇒ 集合确实皆空 ✓ ⇒ **判词没把它算绿** ✓（全件无一处把 `subset_ok=1` 当成就）。
**② 两条合成路 = "夹具没送到"（不是"闸做对了"，也不是"闸错了"）**：`dupoff`／`dup1`／`slowdt` 三腿 `cand=0` ⇒ 从未出现"同 button 无 release 的第二条 press"；`slowdt` 现取 `press#2 x_time=13411708 → release 13412900`（Δ≈1192 ms）⇒ 中间那条 `mousedown` **没有产生事件** ✓（与其 §4 一致）；`on1-3`／`off1` 的替身 press 现取 `x_time=1`、`dt_ms=-13552196`、`e3=DELIVER(other-button-or-dt-too-big)`；夹具自陈行 `fix-on1.out` ＝ `E3FIX sent=1 win=0x200004 time=1 x=660 y=345 sleep_ms=180 send_event=1` ✓。⇒ **本席判**：这是**判据未被行使**（`cand=0`，丢弃支路零实例）＋**替身被按设计交付**（`dt<0` 非候选），**不是**"闸正确地丢弃了它"（见 `E-2` 措辞），**更不是**"闸错了"；载体 §0 行 3（"**未能在本装置真跑** ⇒ `NOINFO`"）＋ §4＋§7 把这条**如实挂账** ✓ ⇒ **方向诚实** ✓（红榜 `P10` 的反向用法正确：没有把"没测到"写成"测出来是安全的"）。

## §4 判据④ 副产品读数的强度（现取）＋与 `WAVE46 §10` 的关系

- **四腿读数 ✓**：`hs6.log:4/:10/:16/:22` 现取 —— `LEG(on1) … children base=7 after_replay=8 after_release=7 AE_mid_end=22607`（`on2`／`on3`／`off1` **逐字同**）⇒ 「替身 press 一旦被交付 ⇒ 下拉**真被关掉**」**现场可复现** ✓；对照腿（真点击）终态子窗 **8**（`hs4.log` 现取）✓。⚠️ 口径观察（非缺陷）：两侧的**量格**并不同（夹具腿是 `after_replay/after_release` 三格、真点击腿是 `children_before/after` 两格）⇒ 载体 §5① 的"**同点位**保持 8"若写成"真点击腿终态 8（`hs4.log`）／夹具腿 `after_release=7`（`hs6.log`）"更贴读数。
- **与 `docs/WAVE46-PREREGISTRATION.md` §10 的关系**：本席现取 `:144-154` —— §10 的"关键更正"把当时"同一次点击 **2 条** `Executed`"归因于**探针自身**（`manualExecute`），并写「炮口 鼠标重放 去重实验｜**已全部撤除**｜三个判据都被反证；**产品侧不需要它**」⇒ 载体 §5② 的转述**准确** ✓；且它明确**不推翻**、只补"只要真存在第二条 press，下拉就会被关"的读数、并把真因留待真实重放上取 `cand` ⇒ **"不推翻只补读数"这一自称成立** ✓（属**保守**表述：产品侧去重本已由判据件 §5 授权落地，授权链写在载体头 ✓）。

## §5 判据⑤ `#if` 与导出面 ＋ 口径（**非副本**）

- **无 `#if` 门 ✓**：闸区间 `:1270-1400` 现取 `grep '#if|#endif'` ⇒ **0 行** ⇒ 这是**产品件改动**（与载体 §6 自陈一致）；改前件里 `E3-REPLAY`／`g_x_e3_`／`WPF_E3_REPLAY` 命中各 **0** ⇒ 该机制确为本次新增 ✓。
- **导出面 ✓**：`.so` 现取 `26da177686acb1f0`（开工 `352855f8dfbf8dc7`）；`exports.txt` **669 行不变** ✓（载体 §6 写明"未新增导出；状态只经 `stderr` 暴露"）。
- **口径 ✓（关键红线未触）**：载体 §6 表头**逐字**写「**产品件口径，不是副本"逐字节不变"口径**」；全件 `逐字节` 命中 **1**（＝该否定句）、`MAIN_BYTE_IDENTICAL` 命中 **0** ⇒ **没有把副本口径套到产品件上** ✓ ⇒ 派单给的 `needs_revision` 触发条件**未触发** ✓。

## §6 判据⑥ 具名前置与挂号口径

- **`PRECOND-E3-REPLAY-FIXTURE-MISSING` 可执行 ✓**：载体 `:51` 给出两条**具名且已实测排除/保留**的通道（① 真实服务器重放 —— `t204` 已判本侧不掌握该次抓取 ⇒ 并挂 `NOINFO-REPLAY-SOURCE`；② 能携带**有序服务器时间**的事件注入通道 —— `XTest`／`XSendEvent` 均实测不可用），射程＝候选/丢弃支路、粒度＝单次点击 ✓；`:52` 还写死**禁止**放宽判据（不接受 `time=0/1`）⇒ 下一位可直接按此开工 ✓。
- **三条 `NOINFO` 全保留 ✓**：`NOINFO-GRAB-COUNT-CALIBER`／`NOINFO-REPLAY-SOURCE`／`NOINFO-TOUCHPAD-SYNTH`（载体 `:67-69`）逐条在场，且 `NOINFO-TOUCHPAD-SYNTH` 明写"**未认定安全**" ✓。
- **无一处把未验证的修复当已绿 ✓**：`§0` 状态＝**`failed`（诚实终点）**、行 3 ＝ 🔴 未真跑、`:71` 的"合法终点声明"逐条否定（没把"没丢真点击"写成"重放被忽略"；没把空集合 `subset_ok=1` 当绿）⇒ 本席**未发现假绿** ✓。

## §7 反腿（本席自造，一对）—— 可证伪边界

**反腿①「夹具把 press 真送到了、但闸没丢它」**（本席构造＋代码核对）：若某腿出现"同 button ∧ 无中间 release ∧ `0 ≤ dt ≤ bound`"的第二条 press 而读数仍 `drop=0`／`e3=DELIVER(…)`，**即证闸的丢弃支路失效**。本席现取 12 腿：**`cand=0` 零实例**（§2/§3）⇒ 该反腿**今天造不出**（`XTest` 第二条 press 被服务器忽略、`XSendEvent` 的 `time=1` 使 `dt<0`）；只能**代码面**核对丢弃支路存在（`:1370-1377`：`cand++` → `dedup_on()` → `drop++` → `break` 不交付）⇒ **可证伪边界＝"闸的丢弃支路为代码面成立、运行期零实例"**，而载体已如实标注（§0 行 3 `NOINFO`＋具名前置）✓。
**反腿②「闸丢了真点击」**：现取 12 腿 `drop=0` 且真点击腿产品可见面正常（`children 7→8`、`AE=29866`）⇒ **被现有读数证伪** ✓（即"以丢真点击换下拉不被关"的红线路径今天未发生）。
**建设性补充（本席给，非缺陷）**：要**合法**打到候选支路，除载体已列的两条通道外，可加**第三条**：**`evdev`／`uinput`（或 XI2）注入**——这类事件经内核输入设备进入 X 服务器，会带上**真实的服务器时间戳**与真实设备路径 ⇒ `dt` 为真实正差、很可能落进 `[0,250]` ⇒ 比 `XSendEvent` 更接近"抓取重放"的形态。建议下一件把它写进该前置的可执行清单。

## §8 推翻的话

**`none`（就本件的实质面）** —— 我没能推翻：去重逻辑落仓与位置（§1）、"真点击一条未丢"（§2，18/18）、两条反腿的**方向**判读（§3）、副产品读数（§4）、`#if` 与导出面（§5）、具名前置与三条 `NOINFO`（§6）。我只找到 **3 条 low**（计数 `E-1`／措辞 `E-2`／行号 `E-3`），**均不改判词**。

## §9 具名 `NOINFO`

- **`N-1`** 闸的**丢弃支路**运行期零实例（`cand=0`×12 腿）⇒ "丢弃是否真发生"**不可判**（与 `t205` 的同名前置同向；本席只核到代码面）。
- **`N-2`** 托管侧 `Executed` 调用次数（判据件 §5② 的**原口径**）：今日**无该读数**（`t203` §4 已判；本件按 outOfScope 未动 `.cs`）⇒ `t205` 用**输入层代理**（`deliver=1`）替代并**不外推** ✓ ⇒ 该格仍 `NOINFO`。
- **`N-3`** 触摸板合成事件：**无样本**（`t205` 明写替身 `send_event=1` **不**代表触摸板）⇒ 保留 `NOINFO-TOUCHPAD-SYNTH`。
- **`N-4`** `nm -D | grep -c ' T '`＝666 与其 `exports.txt` 669 行的**口径差**：本件只核了 `exports` 669 行 ✓，未独立复算 666（标"未独立复算"）。
- **`N-5`** 本件**未起 Xvfb／未跑腿**（遵派单资源约束：dsh 堆高水位）⇒ 一切读数来自**已有日志**＋文件现取；`/tmp/.X11-unix` 未重取。

## §10 新发现的问题（点名 `文件:行` ＋ 机制；**本件不修**）

- **`E-1`（low）｜§0 的计数与其自己的表不符**：`P1-e3-replay-report.md:11` 写「8 条腿共 **15 条真按下** ⇒ `press=15 deliver=15 drop=0 cand=0`」，而其 `:38-44` 的逐腿值与**日志**都是 **1+2+2+2+4+3+2+2 ＝ 18**（本席逐腿现取，见 §2 表）⇒ **§0 那句数错**（方向**保守**：少报，不影响"未丢"结论）。`requiredFix`：把该句改为 **18**（或按实际口径说明哪几条未计入）。
- **`E-2`（low）｜"拒收"措辞与读数矛盾**：`P1-e3-replay-report.md:50` 写「本闸**依序关系正确地拒收**（`e3=DELIVER(other-button-or-dt-too-big)`）」——**读数是"照常交付"**（`drop=0`；落在 `:1382-1387` 的 else 分支＝`deliver++`），**不是丢弃**。正确说法＝「替身事件因 `dt<0` **非候选** ⇒ 按设计**交付**；**候选/丢弃支路未被行使**」（同段末句"候选支路**未被打到**"已写对）。`requiredFix`：把"正确地拒收"改为"按设计**照常交付**（非候选）⇒ 判定支路未被行使"。
- **`E-3`（low）｜行号跨代混用**：`P1-e3-replay-report.md:19-21` 混用了**改前代**与**交付代**的行号（`:1308` 是改前件的 `push` 交付点、`:1286` 是改前件的 NC-press `break`；而 `:1355` 近交付代的闸起点）。**交付代**（`4576fc68bcbbf329`／2189 行）现取为：NC-press break **`:1335`**、NC-release break **`:1354`**、闸 **`:1357-1394`**、交付点 `push` **`:1395`**／`produced++` **`:1397`**。`requiredFix`：按交付代重取该段行号并加"（交付代；行号仅本次有效）"标注。

## §11 证据在册 ＋ 资源 ＋ 自证

- 本件唯一写入：`build/MilBridge/P1-e3-replay-verify.md`（`temp → os.replace`；临时件落 `/tmp/p1-e3-replay-verify.tmp`）。
- 只读来源（现取）：`P1-e3-replay-report.md`／`P1-e3-replay-criteria.md`（§4/§5）／`P1-e3-grab-recon.md`（§5）；`src/WpfGfx.Linux.Native/src/win32_x11.c`（`:325-356`／`:1280-1400`／`:2102` 整行）；`~/t123-runner/bak/win32_x11.c.pre-t205`（改前代）；`bin/{libwpfwin32.so,exports.txt}`；`~/t123-runner/logs/t205/**`（`app-*.log` × 12 腿、`hs4.log`／`hs6.log`、`fix-*.out`、`nav-*.out`、`report.body`、改前/后脚本 `final*.sh`）；`docs/WAVE46-PREREGISTRATION.md:142-171`。
- **资源（§A #10）**：`MemAvailable` 三次现取 ＝ **13379528 kB**（`23:19:54`）／**13397552 kB**（`23:19:55`）／**13396780 kB**（`23:19:56`）；`df -h /home` ⇒ `/dev/sda2 187G 107G 71G 61% /`；`MemTotal`／`SwapFree` 未逐项打印（本件为纯只读复核、未起重活，遵派单"尽量只读"）。
- **`P9`／`P10` 用在自己身上**：判"反腿②是夹具没送到而非闸做对"之前，先**三条互不依赖**取证（`slowdt` 的 press→release Δ≈1192 ms；`fix-*.out` 的 `time=1 send_event=1`；`on*` 腿的 `dt_ms=-13552196` 与 `drop=0`）；判"去重逻辑真落"之前，先把**改前件**（`8177fb1dee6c6951`）里三类 token 命中**0** 作为"新机制而非改旧"的对照。

**本件自证（落盘后）**：`head -n -1 build/MilBridge/P1-e3-replay-verify.md | sha256sum | cut -c1-16` ＝ 7f150f960eb6a591（末行不计入自身；末行＝本行）
