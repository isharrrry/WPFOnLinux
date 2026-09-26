# HANDOFF-NEXT —— wpf-linux 现场交接（**现读现算**；生成 2026-09-24 14:3x，取代此前所有过期版本）
> ⚠️ **本件数值随波变动**：下面所有 sha16／字节数／step 数**一律以 §7 现算为准**；本件是**导航**，不是判据。
> ⚠️ 本件的**唯一权威来源是现场**。若本件与现场冲突，**以现场读数为准**，并按 §7 的七条命令重取。
> ⚠️ **不引行号**（纪律 31）：本仓有若干件**每代重写**、且同一句会**多处出现**（如基线件的「九位」行现盘在 `:14` 与 `:77`，历史块共 7 处）⇒ **一律引内容锚**。

## §1 世代与冻结（现读）
- 冻结哨兵：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#77 sha16=e3ebc811641bd467 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（现取；⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己。）
  （⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己。）
- 基线件：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `e3ebc811641bd467`／**1,138,219 B**（世代链：`#73` `f747350edf97a74a` → `#74` `8b303228ff088349` → `#75` `3b9e463e70220e11` → `#76` `954df351a119d36f` → **`#77` `e3ebc811641bd467`**；现取）。
- 九位（`#77` 冻结值；取法见 §7-2）：`bridge 4e25e4b27d4d5ae1`｜`pc 53fd7fffcdb30243`｜`pf 4fcd2ca021c39064`｜`windowsbase 07c89f1872c1a3c1`｜`provider 4041df9a704abfed`｜`win32shim fc60c34d51fd9247`｜`wic f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf b07f801556e1a511`。
  ⚠️ **`#77` 五位位移（`pc`／`pf`／`windowsbase`／`provider`／`dwf`）＝ 路径承载体**：`#76` 的九位是**从旧树 `O` 拷进 `N` 的**，`#77` 是 `N` 内**第一次真重建** ⇒ 托管件 DEBUG 目录里嵌的 `*.pdb` **绝对路径**变成 `N` 的路径；**字节大小与 `#76` 冻结值逐位相同**（`3601408`／`6123520`／`1111552`／`104448`／`39936`）⇒ **非产品回归**。`bridge`／`win32shim`／`wic_shim` 是原生/发布件、本波未重建 ⇒ 逐位未变（反证）。口径句：**"托管程序集的哈希是路径承载体；凡跨树位置比较产物哈希，先问『它是在哪个树里产出的』。"**
  （`pf` 仍是**环成员**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 不许当漂移/回归判据，`D-G92`。）
  （`pf` 是**环成员**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 不许当漂移/回归判据，`D-G92`。）
- `inputs_fp`（`#77` 落地后，**覆盖面 211 件**）：`b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c`
  （`#62` 后 = `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`／158 件；`#61` 后 = `a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`／157 件。**改动覆盖面内任一件必移**，属设计性变更。）
- **步数**：`verify-all.sh` = **50 步**（`#77` 加 `[48] WIRING-COVERAGE`／`[49] PARSER-GUARD`／`[50] PROTO-ATTR`；首行 `DECL` 声明的步数 == 现取 `run_step` 数，**`DECL` 行数 ≠ 步数**，纪律 46）；覆盖面 **211 件**（`[42] --expect 211`）。
- 推送（`#77` 冻结时点，**推送前**现取）：`feat-Linux` 本地 HEAD = `fd9a9a1886d25575ae625d44741d45620d554185`（`t1` 两笔：`7027be06e7fddb793ea22411c1f0645626474a73` ＋ `fd9a9a1886d25575ae625d44741d45620d554185`，**随本波推送带走**）；上一波远端值 = `5d45064ab4b5e2003fe509753d3d0689a78eff1e`（**本波两笔**：波件 `9cea5cc4786b8cc3abdc9f9f281aba113c042e82` ＋ **主控登记批** `5d45064ab4b5e2003fe509753d3d0689a78eff1e`；clone = `~/netTest/GitProj/WPFOnLinux`，`origin`=gitee、`upstream`=dotnet/wpf；**本行与其后提交若不一致，以 §7-6 现取为准**）。
- 放行标记：`~/w21-verify/w*-POST.done` 现取 21 件：w56-POST.done／w57-POST.done／w58-POST.done／w59-POST.done／w60-POST.done／w61-POST.done／w62-POST.done／w63-POST.done／w64-POST.done／w65-POST.done／w66-POST.done／w67-POST.done／w68-POST.done／w69-POST.done／w70-POST.done／w71-POST.done／w72-POST.done／w73-POST.done／w74-POST.done／w75-POST.done／w76-POST.done（真时刻一律 `stat` 取）。

## §2 在飞（**先读这节再动手**）
- **在飞**：**`#77`**（仪器波；五件 ＝ `TASK-0740`＋`0742`＋`0744`＋`0745` ＋ 主控同趟追加的「仓根 `Directory.Build.props`/`.targets` 缺席牙」＋ **21 件旧路径重指向**）—— `verify-all.sh` **50 步**／覆盖面 **211 件**；冻结／推送／哨兵读数见本节现取（本件是**导航**，不是判据）。无其它链在跑（槽 `FREE` 时方可起新重活）。
- **下一波 `#64`＝`TASK-0717`**（把「基线率闸」做成牙）：入口 = 新件 `build/MilBridge/tools/baseline-rate-gate.sh`；规格输入 = `~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`）＋ `~/w157a/bin/baseline-rate-gate.py`（`0dac2ea941b56f4f`，**无第三方依赖**，已逐位复现仓内四个 `REQUIRED_N_ALT`）。
- **待命车道（都已交付包、等落地窗口）**：W180A（`#77`：`0740`＋`0742`＋`0744`＋`0745`）｜W181A（`0747`：`SHAppBarMessage` 返 0）｜W182A（`D-G147` 工作区语义）｜W183A（`TASK-0739`③ 显示号租借）｜W184A（`0744-FU`：装置附 socket 身份）。

## §3 队列（一条改动 → 一次冻结）
1. **`#77` 已落地**：`TASK-0740`＋`0742`＋`0744`＋`0745`（W180A 包）＋ 主控同趟追加（仓根 props 牙，**折叠进 `[9]`、不动步数**）＋ **21 件旧路径重指向**：步数 `47→50`／覆盖面 `205→211`／`--expect` **同趟现取**。随后 **`0747`**（W181A，`wsh` 必动 ⇒ 冻结闸 `allow_changed` 要含它）；再 **`#78`**＝`D-G147`＋显示号租借＋`0744-FU`（串行落地、数字现取）。
2. 未闭 `[Next]`（现取）：`TASK-0747`（W181A 包已就绪、等落地窗口；`0740`／`0742`／`0744`／`0745` 已由 `#77` 办）；`TASK-0720`／`0721`／`0732`／`0741`／`0746` **本批已翻 ✅**；`TASK-0709`–`0719`／`0722`–`0739`／`0743` 早已 ✅。
3. 未绿 `[MVP]`：`TASK-0007`（富文本 23／流文档 24 `rc=134`，真因 `TASK-0302`）｜`TASK-0201`（静默 `rc=139`，上界已收到 4.87%）｜`TASK-0302`（PTS／原生 LineServices 缺口 **可操作 88／实现口径 97**，现读 `工具口径 100`）。
4. `TASK-0111` = ✅ **归档为「不可判 ＋ 已知无产品价值」**（号不撤）：① 该红已被 `#54`/`TASK-0210` 修掉（现行桥 `4e25e4b27d4d5ae1` 上 `0/12` 红 vs 旧件 `12/12`）⇒ **产品价值 = 0**；② `A` 臂红率**随时间漂移**（`12/12 = 100%` → `7/28 = 25.0%`）⇒ `P1` 被排除 ⇒ **整批 `VOID-PREMISE`、40 腿不跑**；`N1` 作为修法**撤回**。判据件：`~/w156a/{criteria.md,leg-plan.md,AMENDMENT-1.md,AMENDMENT-2.md,WAVE-PREREG-0111.md}`｜装置 `~/w155a/device/wpfhintsgate.so 3c2a36580a7806f6`。

### §4-追（`t17` dated 更正，2026-09-26；**§1–§3 原文保留**）
- **`#77` 冻结块九位行的 `provider` 是上一代值**（`1f9511a7ef395bfe`），同块位移行与全部 `BASELINE tier=` 机读行写现值 `4041df9a704abfed` ⇒ **同块自相矛盾**；根因＝记录模板写死字面量 ∧ 冻结器三道核不含 `provider`（`D-G149`）。**不改冻结块**；处置见 `docs/WAVE77-PREREGISTRATION.md §8.3`。
- **`provider` 的规约权威 = `build/DirectWrite.Linux/Provider/bin/<CFG>/…`**（工程产出目录；冻结器 `NINE` 与 `applocal-expect.py` 都用它）；`build/PresentationCore.Linux/bin/<CFG>/…` 是**副本**，须与之相等（`D-G150`，牙 = `WFREEZE_NINEAUTH`）。⚠️ 副本刷成权威后，**在册九位的 `provider` 与现场不再相同**（`4041df9a704abfed` → `609192a419d125f2`，冻结点之后的重建位移）。
- **`#77` 的 5 处 `dirname` 层数回归已修**（`D-G149` 同批账；牙 = `WFREEZE_ROOTDEFAULT`，接在 `close-wave.sh [5c/6]`）；覆盖面 **211 → 212**、`inputs_fp = 99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`。
- **`~/w153a/bin/infp.sh`** 已按契约改为**可覆盖默认值**（原硬编码旧路径；`t7` 撤链接后它会静默失能成 `NOINFO`）。
- **`TASK-0745` 的活件状态**：主控已把 `E1+E2` 从活冻结器回退（现读 `6bf3c5c77eee8dd8`，`grep -c check_record_forms` = 0）；返工设计见 `build/MilBridge/P0-w77-repair-report.md §F7`。

## §4 近期新登记（要看细节读登记册）
- **`D-G115`（判据装置缺陷 · 判词方向）**：`regression-decision.py` 的 `subkind=rate-aggravated` 及判词**不判方向**（`p ≤ alpha ∧ 旧件也红` 就印"本波把速率**显著加重**"）⇒ 在**下行腿/必要性**设计里打印**反结论**（现场：`--old 24/27 --new 0/40` 印"显著加重"，事实是**降到 0**）。**已修**（`#63`）：加 `REGDEC_DIRECTION=` ＋ 下行改 `rate-mitigated`，**上行口径逐字保留**。口径句：**"判词带方向断言 ⇒ 判据必须真的判方向；双尾显著 ≠ 上行显著。"**
- **`D-G116`（臂与腿的有效性）· 7 实例**：① 对照臂改体制（`drop`/`noop` 让 WM 失明 ⇒ 加装饰 ⇒ `m_ok=0`）② **单格判红**（退化/死腿也报 `r_ok2=0`）⇒ **判红 = 四件合取** `START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes` ③ 腿基线跨腿串味（`xfwm4` 记忆 ⇒ 需 `wmstate` 复位）④ 把"被干涉项的在场"当入分母条件 ⇒ 干涉臂无分母（改用 `TARGET_ATTEMPT_IN_BEAT` ＋ 各臂忠实性断言）⑤ 族识别谓词错（**按 `type` 不按 `prop`**）⑥ "条件同一性"须含 **X 会话寿命/WM 冷热态与时间稳定性** ⑦ **把结果算进体制 ⇒ 用"保护可比性"的名义否掉可比性**。**牙已落地**（`#63`：`regime-identity-check.sh`，**体制列 = 输入侧四列**，结果侧只作诊断、不进 `rc`）。
- **`D-G117`（判据显示层）**：步自报抽取器只认 `KEY=PASS|FAIL|NOINFO` ⇒ `PREREG4=NA`／`…_SUMMARY`／`…_OUT-OF-SCOPE` **不上屏** ⇒ **半可见 = 假绿方向**。**已修**（`#63`，两半）：批次首行带四态计数 ＋ 择一表纳入 `NA`／`SKIP`／`REPORT` ＋ 三类行出口；**显示窗 12 → 16**（现最大 8 行、无步骤触窗）。
- **`D-G118`（判据/功效前提 · 基线率漂移）**：**用历史速率反推 `N`，而速率本身随时间漂移 ⇒ 功效前提被证伪**。口径句：**"条件同一性必须包含『世界的时间稳定性』；凡登记速率都必须带时间窗，且用于定 `N` 之前必须在同窗现取一道基线率闸。"** ⇒ **全仓警示**：`24/27 = 88.9%`／`M2:R2 = 3/33`／`6%→0% 需 131 腿` **在册速率全部隐含"09-23 那个时间窗"**。
- **`D-G119`（判据装置缺陷 · 域选错）**：**掩码域**（假阴性）／**枚举域**（假阳性）／**heredoc 域**（假阳性）／**注释域**（假绿）。**对偶判据**：**「注释里的调用不算调用」的对偶 = 「注释里的『排除』不算证明」** ⇒ **证据域 = 剥注释后的代码文本，且非 shell heredoc 体置空**。
- **`D-G108` 第二种机制（发布完整性）**：**产物只落工作树、从未入库 ⇒ 声明表路由锚指向"远端不存在"的版本**（`handoff.md` 压缩版 333 行 mtime `09:17:44` 晚于 `2e15b61` 8 分钟；声明 `HO` 却已是压缩版）⇒ 由 `#62` 收尾链同趟补推。
- **`D-G114`**（`shell-quote-trap-check.sh:325` 帧栈泄漏 ⇒ 整份文件判据降级为诊断）／**`D-G113`**（假旋钮：开关只改打印）／**`D-G103` 族**（按模式匹配进程的自匹配，本会话 ≥ 9 例）**均已修**（`#60`/`#61`）。
- 登记册自洽：`DEFREG=PASS declared=155 route_ids=155`｜`DECLDRIFT=0`。

## §5 闸门与纪律（本会话血的教训，逐条都有现场证据）
1. **闸门 = 完成制标记 ＋ 主控显式 GO**。**"闸门字面满足 ≠ 可以写共享 `$R`"**；写前必须确认 ① 收尾/构建链不在跑 ② 重活槽未被别人持 ③ 冻后链已完成。**闸门口径的任何细化必须同趟广播给所有在飞车道**。
2. **逐径 `git add`，绝不 `-A`**（`D-G108`）；推送前先 `ls-remote` 判**快进**（⚠️ `git fetch origin feat-Linux` **不更新** `origin/feat-Linux`），非快进 ⇒ 停手报主控。
3. **进程只按 PID 收**；**绝不** `pkill`/`pgrep -f`（`D-G103`，本会话 ≥ 9 例）。扫 `/proc` 找链/找进程时**必须显式排除 `$$` 与自己的祖先链**（漏排 `$$` 是最常见变体）。
4. **重活一律走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 -- <cmd>`；`HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **都不是读数**。
5. **长任务走后台作业**（前台超 600 s 会被工具链 SIGTERM ⇒ 读数作废）。
6. **写盘 temp + `rename`**；改动前 `cp -p` 备份 —— ⚠️ **备份必须取在"任何写之前"**（`#63` 实测一次取在第一次写之后 ⇒ 备份是混合态，真回滚会回到混合态）。
7. **显示号只用 `:2xx` 空闲号、几何 `1280x1024x24`**（`D-G105`）；**每腿只要新起 `Xvfb`/WM 就与"长寿会话"不同体制**（`D-G116` 实例 ⑥）。
8. **冻结链的每一步都要独立复算**：`步骤通过/失败`、`用例通过`、日志 sha16、`config=` 互证九位、`设备上没有空间` = 0。
9. **对"会反复改写的车道"，单次采样不足以定罪**（反极性序列的中间态看起来像"异物写入"）—— 看时间序列或直接问车道。
10. **`--emit` 是把声明表打到 stdout**（`defect-registry-check.sh --emit > declared.tsv`）；核对"声明 ↔ 现场"先看**被写文件的 mtime**。
11. **指纹类读数（`inputs_fp` 等）只在树静止时有意义**：链在跑时算出的值会漂（现场实测同一命令先后不同）；取指纹**必须在无链在跑时**，并**连算两次比稳**。
12. **「拿哈希去 grep 文件名」是范畴错误**：要举证「某件在覆盖面内」，先让工具**打印清单**再 grep。
13. **派单里的期望读数必须标明出自哪个装置/哪一位**（`WPTD_*` ≠ `TLINE_GATE` ≠ `GEOM*`）。
14. **「必须成为 `head -1`」的插入，锚必须是**位置**，不能是上一代的文本**：解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插。
15. **冻结只要改写了路由件（`KD`/`CS`/`HO`/`AB`/`KRJ`…），就必须重发 `declared.tsv`**：`req=`/`present=` 是**路由状态快照**。⇒ 冻结那一刻**立刻报主控**由主控重发（`#60`／`#61`／`#62`／`#63` 四次实测：主控都在冻后 `verify-all` 走到 `[10]` **之前**发出）。
16. **`python3 - <<EOF`（stdin 脚本）里不许用 `__file__`**：stdin 下恒为 `<stdin>` ⇒ 反推仓根会静默指到别处 ⇒ 由 bash 侧显式导出仓根并加自测钉住。
17. **改"读数行/报告行"必须断言命中数**：`str.replace` 静默 no-op 是最隐蔽的假更新（车道自伤三次）⇒ 逐字段断言重建或替换后立刻 `grep -c` 复核。**替换/撤销类脚本一律断言 `hits`**。
18. **"两趟对拍"的合格线 = 判词行逐字一致**；跑次戳（`outdir=`／`rundir=`／随机后缀）、仪器计数漂移（实测 `magenta_frames=38 vs 40`）**不算差异，但必须在报告里点名并列出实际数**。
19. **追加"历史行"必须用插入**（不许"替换前缀＋跳到行尾"）；改完 `grep -c` 核旧行仍在。
20. **判据的"生效边界"必须可见**：早于生效代的证据件打 `SKIP` ＋逐件点名 `reason=pre-effective`，与 `PASS` **分开计数**。**禁止**用"放低边界/删掉该件"换取好过。
21. **新牙落地同趟必须过 `PIPEFAIL-SIGPIPE` 牙**：新件一进仓就改 `files=`／`sites=` 读数；凡 `printf … | grep -q` 一律改成 `case`／`[[ == *pat* ]]`／**逐行 `[[ =~ ]]` ＋ here-string**（⚠️ `[[ "$out" =~ $pat ]]` 是**整串**匹配 ⇒ 多行必须逐行）。**该族本会话咬 5 次**。
22. **`echo "post$i_rc=$?"` 是错的**：bash 把 `$i_rc` 当一个未绑定变量（`set -u` 直接退出 ⇒ **少跑一趟**）⇒ 写 **`${i}_rc`**。
23. **"冻前恰 1 处声明类红"是有条件的**：条件是**本波重取过臂／改过被声明件**；仪器波若不动臂与声明件 ⇒ **冻前可以全绿**（`#58`/`#61`/`#62`/`#63` 实测全绿）。派单里的期望读数**必须带条件**。
24. **记录模板里"花括号全大写"会被冻机器当占位符并 `assert` 炸掉** ⇒ 用 `$VAR` 或 `<NAME>`；落地前用机读校验器过一遍。
25. **"恒 0 守卫"是死代码**：守卫/断言必须**用一条已知为真的输入证明它真的会亮**；`==`/`if` 两侧类型要同类（`len(x) == 0` 而非 `x == 0`）。
26. **幂等守卫只判"`NEW` 在不在"**：`NEW` 逐字**包含** `OLD` 时，"新在 ∧ 旧不在"**永不成立** ⇒ 重跑会再插一遍（`#62` 实测）；**守卫只写一半比没有更危险**。
27. **任何对拍/解析在任一侧为空时必须响亮失败**，不许静默判等/判空（本会话三次同族：空文件 `diff` 假报 IDENTICAL／解析取空 ⇒ 假违反／`rc` 取自管道末段）。
28. **引"行号"前必须先 `sed -n` 打出该行原文再写**，不许凭记忆写"权威某行"。
29. **凡"我已推送 X"的断言，必须逐件核到远端**（`git cat-file blob HEAD:<path>`／`ls-remote` ＋ 逐件比），**不许用"那一批推了"代指单件**。
30. **复现别人的"集合类"读数时，成员集合必须先现场取**（如 `bash ~/w153a/bin/infp.sh list`），不许凭记忆列名单。
31. **禁止对"随世代重写或同句多处出现"的文件引绝对行号** ⇒ 一律用**内容锚**（或现场 `grep -n` 取数并声明取数时刻）。
32. **`echo` 的双引号里不许出现反引号**（`QUOTE-TRAP` 会**真的执行命令替换** ⇒ 打 `… 未找到命令` 并啃掉行内容）；`grep -c` 的 `0` 且 `rc=1` ⇒ `|| echo 0` 会得 `"0\n0"`（算术致命）⇒ 先取数再归零。
33. **回复点（备份）集合必须在"读完全部落地目标"之后才冻结**：漏备**不响**（覆盖成功、`sha` 断言也成功 —— 因为断言比的是**覆盖前现读值**，不是**备份件**）⇒ 落地前必须**逐件断言**"有备份 ∧ 备份 `sha16` == 覆盖前现读 `sha16`"，缺一**拒落**。（`D-G126`，波 `#65` 现场：派单 A 表**第 1 件**在无备份状态下被覆盖，靠 fork 克隆 `HEAD:` ＋ 另一份 `backup/*.orig` **两独立来源逐位相同**才救回。）
34. **任何"影子／隔离／回退树"在**写**之前必须逐件断言 `stat -c %h == 1`（实体），不满足即**拒写**：`cp -al`／`cp -l`／`ln` 造出来的不是隔离，是**与权威树同 inode 的农场** ⇒ 一次原地写就**写穿 `$R`**（现场：`#65` 落地后抽样 `$R` 下 17 个 `*.sh`，**16 个 `link>1`**；`shell-quote-trap-check.sh` `%h=4`，孪生在三处车道影子里）。`D-G101` 的旧牙射程是**仓内**跨区、且在 `verify-all` 里**恒不为 PASS** ⇒ 这个方向**没有任何一步会红**。收尾必须交**权威树完好证明**（`find $R -newermt <开工时刻> -type f` 无本方产物 ∧ 本方碰过的每件 `$R` 侧 sha16 == 拷贝时刻读值）。（`D-G127`）
35. **账目对齐**：凡波报告里写下的"已办／已跑／判词"，**必须同趟写回在册状态位**；两处不一致时**以报告里的机器读数为准**，并在发现当趟把另一侧改齐 —— 否则下一位接手者会**按假前提派活**（现场：`TASK-0301` 的反极性腿在 `W70A-report.md` §5 早有判词 `C7 成立`，而 `ROUTES.md` 一直写"未跑" ⇒ 主控据此**多派了一整条车道**）。（`D-G129`）
36. **判据必须声明输入来源并在取数前断言其身份**：输入若是**瞬时/派生**状态（`shadow/`／`out/`／`logs/` 下的中间物）⇒ 一律**先重造**再判（或判 `NOINFO`），否则结论会变成"环境此刻长什么样"的函数、**换一双跑法结论就变**（现场：两件仪器从 `shadow/tree` 取源树，被另一双跑法清空后**照样出结论**；修法是自建源树 ＋ `before-sha256-mismatch` 响亮失败）。（`D-G130`）
37. **"取最新"靠第一行，插入锚必须动态取那一行**：凡用 `sed … | head -1` 取"第一行声明／最新声明"的抽取器，**必须把口径写在件头**；凡往那种块里**插入**新声明，锚一律**动态取"文件里第一行"** ＋ 断言 `hits==1` —— 否则你按"当时的最新行"插，别人再往头部插一行，你的新声明就**落到旧声明之下**，工具读到**上一代** ⇒ `FAIL count-mismatch`（**假红 ＋ 整波返工**）。（`D-G131`，波 `#67` 预备实测）
38. **装置通过环境变量接收"目标"时，开跑前必须断言自己拿到了**：`DISPLAY`／`WDISP`／根目录／臂目录这类目标，缺一个就**拒跑**（非零 rc），并把**实际取到的值印进产物** —— 现场：某腿脚本认 `WDISP` 而调用者只设了 `DISPLAY` ⇒ **4 条腿全打在并不存在的 `:235` 上**、**整批作废**，靠被试件自己打出的 `XOpenDisplay(":235") 失败` 才被发现。**"没打在目标上"与"打上去没反应"在读数里长得一模一样** ⇒ 必须由装置自证落点。（`2026-09-24` W159A 事故；同族 `D-G130` 是"输入取自瞬时状态"，本条是"输入压根没送到"）
39. **输出体积纪律（宿主 OOM 事故后加）**：**几 MB 级文件/日志绝不读进会话** —— 只许 `wc`／`head -n 20`／`tail -n 20`／`grep -c`／`grep -m 5`；自己产生的过 MB 日志**同一条命令里压成一行计数**，原始件只报**路径＋`sha16`＋行数**；**长跑（>120 s）一律放托管后台作业**（`nohup … >> log 2>&1 &`，**不要 `tee` 回灌会话**）并报 **PID＋日志路径**。现场（`2026-09-24 17:24`）：宿主进程 `V8::FatalProcessOutOfMemory`，**同一分钟掐掉了三条会话里的前台长跑**（含一趟冻前 `verify-all`）—— 这不是"省点带宽"，是**别人的读数会被你葬掉**。
40. **报数一律现算，不引用前一次列印**：任何"我报的 `sha16`／字节数"都必须在**发出那条消息的同一条命令里**现取；凡"读数表"，表里每个 `sha` 都要有**机器读者**（逐行现算，不符即 `STALE<<<` ＋ `FAIL`），且**解析不了的行必须 `FAIL`**（"没匹配上" ≠ "通过"，否则那一行永远不在覆盖里）。现场（`2026-09-24` W158A）：**件与表都对，错的只是消息**（把 17:56 的列印抄进 17:57 的消息）；同一轮它还发现表里有**两件挤一行** ⇒ 读者解析不了 ⇒ **那行零检查**。（`D-G125` 实例②）
41. **冻结基线件一旦被误写：唯一安全的修复 = 从 git 取回该世代的逐字节原件**（`git -C <clone> cat-file -p HEAD:samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）—— **车道不许手工重建 header、不许从中间态备份拼接**（现场：波 `#67` 一条车道为"回到冻前态"按 `[#66 块起点:]` 重写基线件 ⇒ **连带删掉开头 54 行 `BASELINE-HEADER`** ⇒ `BASELINESHA=FAIL`；主控从 git 回灌后逐字节复原）。⇒ **遇基线件损坏：停手、报主控、由主控回灌。**
42. **写冻结基线前必须先留一份 `B.pre-freeze.<gen>.bak`**：`w27-freeze.py` 目前**不备份基线件** ⇒ 一旦写坏，唯一退路是 git（而 git 里只有**已推送过**的世代）⇒ 本波若尚未推送，**没有退路**。（方向已入 `[Next]`，本波不动冻结器。）
43. **长跑前必须现取宿主余量 ＋ 临时件必须可回收（满盘事故后加）**：任何链式长跑（`close-wave`／`verify-all`／整波）**开跑前**先取 `df -m` 的 `available`（**≥ 5 GB** 才放行），并把读数写进**链日志头**；整链中间件**不许**落 `/tmp`（落各自车道目录）；会写临时目录的装置**件头必须写回收策略**。**清理他人临时件必须过两闸**：**①无活进程引用 ②仓内零引用（或远端可逐字取回）** —— **禁用"看着像中间件"当理由**。（现场：`r-gate-step.sh:563` 默认 `OUT` 永不回收 ⇒ 三天 66 件/6.8 GB 撑满 `187G` 宿主，反手把正在跑的波写成 0 B 假红；事故同时**摧毁了六条车道会话**。）
44. **件头自述涉及"装在哪、被谁调用"时必须与代码形状一致，且必须由牙读出来**：凡件头写"未接线／不进 `verify-all`"的件，若 `grep '^run_step "'` **命中该件** ⇒ 必红；反向（自述"已接线"而零命中）⇒ 也必红。（现场：`prereg-four-requirements-check.sh` 件头自称"未接线"而它早已是第 `[34]` 步 ⇒ `D-G136`。）
45. **`NA`／"本波不适用"类声明一律走机读行形态**：新波预登记必须写 `PREREG-NO-REGRESSION-DECISION: <非空且非否定令牌>`（**判据节内**）；"行首锚定声明句"这一形态**只留给历史件**（其残余洞＝行首即声明句、随后自我否定仍算声明，已登记 `D-G135`）。（现场：`#60` 起的整节正则 ⇒ **提到即算**，主控复现"只提及、四要件全缺"也判 `NA rc=0`。）
46. **凡断言两条计数相等，先证明它们在现场真的相等**：把"应该是"当"就是"写进断言，等于给落地器埋一道**永远拒跑**的门。（现场：主控要求 `#75` 断言"`DECL` 数 == `run_step` 数"，而现场 **35 vs 39**（有 4 个"不动步数"的波没加 `DECL` 行）⇒ 照字面写落地器永远拒跑；**真不变量＝首行 `DECL` 声明的步数 == 现取 `run_step` 数**，且**插入前**首行 `DECL` 的 `gen=` 必是**上一波**，不得与 `--wave-gen` 比。）
47. **落地/推送脚本的"派生路径"必须在**参数解析之后**由**同一个 `R`** 现推，并**逐条断言落在 `$R` 之下（两道闸）**：①**字面前缀**闸 `case "$X" in "$R"/*) 拒跑`；②`readlink -f` **解析后**前缀闸（防"`$R` 下的符号链接指到仓外"）。**排练必须两极化证明这两道闸真会红**：**E1（正极）** 异树 `--repo` ⇒ 落地成功且**源树零写入**（`find $R -newermt` 前后对账 ＋ 逐件 `sha` 比对）；**E2（反极）** 派生路径为**指向 `$R` 的符号链接** ⇒ **点名拒跑 ＋ 写入件数 0**。（现场：`2026-09-26` 波 `#76` 窗口内，一条预备车道在沙箱排练 `--apply`，脚本把 `VA/CW/FPMS` **绑在参数解析之前**（用默认 `R`）⇒ **真 `$R` 被写两件**（`verify-all.sh`／`build/close-wave.sh`，窗口 ≈1 分钟，两件 `%h==1` 未写穿，当场还原并逐位复核），并**连带作废**同窗口内正在跑的整趟波读数 —— `close-wave.sh` **正是当时在跑的脚本**。⇒ `D-G130` 实例 ④。）

## §6 未结清的账（主控侧）
- **我（主控）的推送账**：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`／`README.md` 已于 **`f158988cf770`** 推上远端（逐件 `HEAD:` 核对 **5/5 MATCH**，`porcelain=0`）。它们**都不在 `fp_inputs()`**（改它们不动指纹），但**每次改完都要重发 `declared.tsv`**（`DEFREG` 判"route 文件里的编号是否都已声明"，改了却漏发 ⇒ `DEFREG=FAIL reason=undeclared-id-in-route`）。
- **app-local（仓外共享目录）**：`~/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0` 已由主控用 `sync-applocal.sh` 修好（`drift=3 → 0`，**其中一件曾是修前桥 `feef049e9d0e313a`**）。**后续任何"探针测到陈旧件"的现象先查这里**。
- **两处哨兵**：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`（`cmp IDENTICAL`）；`handoff.md`（`HO` 键）与**本件**不同：前者是**上游/入口文档的压缩版**，后者是本交接件。
- **车道报告入库约定**：收尾波的车道报告放 `build/MilBridge/<LANE>-report.md` 并随该波提交推送。

## §7 七条命令重建存活态（**先跑这七条，再动手**）
```bash
R=/home/links-dev/netTest/GitProj/WPFOnLinux
# 1) 冻结世代与基线件
sed -n '9p' $R/docs/CURRENT-STATE.md
# 2) 九位（与 §1 逐位比对；pf 是环成员、只作现场值）
for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do sha256sum $R/$f | cut -c1-16; done
# 3) 登记册自洽
bash $R/build/MilBridge/tools/defect-registry-check.sh | tail -3
# 4) 输入指纹（覆盖面 205 件）—— 用已校准的复算器（**只借不改**）
bash ~/w153a/bin/infp.sh fp        # 期望 bb54413c…（#76 冻结值；每波现取）
bash ~/w153a/bin/infp.sh list | wc -l   # 期望 205
# 5) 步数与自检 / 放行标记与记录件
grep -c '^run_step "' $R/verify-all.sh; bash $R/build/MilBridge/tools/verify-all-step-check.sh | grep VERIFYALL_SELF
ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null
# 6) 推送面（本地 vs 远端 vs 工作树）
git -C ~/netTest/GitProj/WPFOnLinux log --oneline -3; git -C ~/netTest/GitProj/WPFOnLinux ls-remote origin refs/heads/feat-Linux | cut -c1-16; git -C ~/netTest/GitProj/WPFOnLinux status --porcelain | wc -l
# 7) 重活槽与内存
flock -n ~/heavy.lock -c 'echo SLOT=FREE' || echo SLOT=HELD; free -m | awk 'NR==2{print "avail="$7"MB"}'
```
