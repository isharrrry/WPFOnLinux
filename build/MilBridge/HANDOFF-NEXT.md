# HANDOFF-NEXT —— wpf-linux 现场交接（**现读现算**；生成 2026-09-24 00:2x，取代此前所有过期版本）
> ⚠️ **本件数值随波变动**：下面所有 sha16／字节数／step 数**一律以 §7 现算为准**；本件是**导航**，不是判据。

> ⚠️ 本件的**唯一权威来源是现场**。若本件与现场冲突，**以现场读数为准**，并按 §7 的七条命令重取。

## §1 世代与冻结（现读）
- 冻结哨兵：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#59 sha16=02f80e388d308c4d file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`
  （⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己 —— 核对时先读 `file=`。）
- 基线件：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `02f80e388d308c4d`／**846,233 B**（`#55` 785,675 → `#56` 807,869）。
- 九位（`#56`）：`bridge 4e25e4b27d4d5ae1`｜`pc 722e0ab8205b7c3f`｜`pf b4c81eb3f1376f86`｜`windowsbase 2e4e46e539a72cd7`｜`provider 1f9511a7ef395bfe`｜`win32shim 2067cb1c97728791`｜`wic_shim f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf ce3469f49efcbcfa`
  （`pf` 是**环成员**：整波重建必变、**同尺寸** ⇒ 不许当漂移/回归判据，`D-G92`。）
- `inputs_fp`：**`#56` 冻结时刻** = `1a999e79f236303891b06c54ef659fe989262cd841140641a13ad27acf12254e`；⚠️ **写成这份交接件时现场已变为 `ecaf53ddc2b5f508e790d64e2a9c024f1e3e7f70b0c6d4457218c0e71d69bd9b`** —— 因为 `#57` 改动 `src/WpfGfx.Linux.Native/src/{win32_msg.c,win32_core.c}`，而**它们在 `fp_inputs()` 覆盖面内**（`#49` 的 `B4` 纳入）。⇒ **该值随 native 源改动必变，属设计性变更，不是漂移**；取新值请照 §7 第 4 条现算。
- 推送：`feat-Linux` @ **`bc0879d30bfd39c67dd011dcfe6441e33a1db08d`**（本地 == 远端）；clone = `~/netTest/GitProj/WPFOnLinux`（**`$R` 本身不是 git 仓**）。

## §2 在飞（**先读这节再动手**）
- **`#57` = `TASK-0211`**（三处窄 `TOCTOU`／生命周期缺陷：`win32_msg.c` 的 `PostMessageW`／`PostThreadMessageW` ＋ `wpf_thread_destroy` 的 fd），车道 **W146A** 持链；落地件 `win32_msg.c=4a88fffb1a0cd7f1`／`win32_core.c=e7f6a37a30f5a037`／`libwpfwin32.so=d2b76a0a56a41be1`（导出 547），**已命中 `/tmp` 干跑预测值**；三点反极性（`aeb179a2d3d9ca44`／`d60f056672f7b4d5`／`5d58b2c18791c369`）**各自成对**已取。
- **放行标记**：`~/w21-verify/w56-POST.done`（`#56` 冻后 ×2 两趟都绿）＝ **已存在**；`~/w21-verify/w57-POST.done` ＝ **由 `#57` 链在⑧两趟都绿后创建**，它是 **`#58`／`#59` 的唯一放行信号**。
- ⚠️ **在 `#57` 在飞期间**，§7 第 2 条的九位里第 4 位（`win32shim`）会读到 **`d2b76a0a56a41be1`**（= `#57` 的落地件）而不是 §1 记的 `2067cb1c97728791`（`#56` 冻结值）；**这是正常的在飞状态**，冻结值仍以 §1 与 `w56-record.txt` 为准。
- 备线车道：**W150A**（`#58`：回归判定四要件整包 ＋ `regression-decision.py` 的 F-A/F-B 修复）｜**W151A**（`#59`：两牙接线 31→33 步）。两者闸都是 `w57-POST.done`。

## §3 队列（一条改动 → 一次冻结）
1. **`#57`** `TASK-0211`（在跑）→ ② **`#58`** 回归判定四要件整包（`TASK-0705` 的模板 6 处 ＋ 新牙 `prereg-four-requirements-check.sh` ＋ `D-G99` 追加位点的 F-A/F-B/F-C）→ ③ **`#59`** 改题后的 `TASK-0110`（`geom-revert-beat-check.sh 9412ec0149111348` ＋ `geom-resend-regression-check.sh cd375326b62f7982` 接线，31→33 步，各带 `C6` 分辨率自检）。
2. 未闭 `[Next]`：`TASK-0211`（`#57`）｜`TASK-0705`（`#58`）｜`TASK-0110`（`#59`，🟡 已改题）。
3. 未绿 `[MVP]`：`TASK-0007`（富文本 23／流文档 24 `rc=134`，真因 `TASK-0302`）｜`TASK-0201`（静默 `rc=139`，上界已收到 3.55%）｜`TASK-0302`（PTS／LineServices 111 条缺口，月级长线）。
4. `TASK-0111` = 🟡 **判 `NOINFO`／`N1` 暂缓（不撤号）**：`W115A` 报告现场判"必要性 `NOINFO` ＋ 充分性被证伪"（`none 0/200`／`hints 0/200`／`hints+geom 200/200`，`Fisher=1`）⇒ 分支 A 的判词不存在、**落地处置被禁**；判据与预备 diff 备档 `~/w144a/`。

## §4 本轮新登记（要看细节读登记册）
- **`D-G112`（新号）**：**用必然无效的分辨率做否定断言** ⇒ "WM 没把退出最大化的几何收回去"在**六条车道**里存活，实为**欠采样伪影**（150 ms 观测器在红腿上 `0/132`、在绿腿上 `52`）。**牙 `C6`**：判"某事件是否发生过"必须**事件锚定**或 `T ≤ D/4`；**176 ms 级口径一律 `NOINFO`**。
- **`D-G42` 追加位点**：`build/MilBridge/tools/known-red-arms-check.sh:280`（`set -uo pipefail` 下的 `printf | grep -q` ⇒ 假 FAIL；**修法 = 换喂法 `<<<`**，判据一字未动）。**本波新接的牙抓出了本波自己带进来的假红**。
- **`D-G99` 追加位点**：`regression-decision.py` 三处 —— `F-A`（`--old-repro yes` 支路**永不检查 ④**，**假绿**）／`F-B`（③ 只查"给没给"⇒ 假陈述／假分类）／`F-C`（三位小数显示翻转判词）。⚠️ **`F-B` 守卫必须放分母守门之后**（否则台账行 `DG94-denominator-counts-skipped` 的覆盖被静默丢掉 ——`run_cases` **只比 `state`+`rc`**）。口径句：**"判定一律用机器行原值，三位小数只作显示。"**
- **`D-G103` 追加**：本会话**咬 5 次**（`pkill -f` 本体／`pgrep -P $$ -f`／看门狗自伤／数进程自匹配／cmdline 子串自匹配），全零损害。口径句：**"按模式匹配命令行收进程/数进程必须先排除 `$$`/`$PPID`；能按 PID 就绝不按模式。"**
- **`D-G97` 追加位点**：`build/MilBridge/tools/shell-quote-trap-check.sh` **不扫 `*/bin/*`**（射程缺口，假绿方向）。
- 登记册自洽：`DEFREG=PASS declared=148`｜`DECLDRIFT=0`。

## §5 闸门与纪律（本会话血的教训，逐条都有现场证据）
1. **闸门 = 完成制标记 ＋ 主控显式 GO**。**"闸门字面满足 ≠ 可以写共享 `$R`"**；写前必须确认 ① 收尾/构建链不在跑 ② 重活槽未被别人持 ③ 冻后链已完成。**闸门口径的任何细化必须同趟广播给所有在飞车道**（本会话同一窗口发生 3 起越界，全零损伤，根因都在"闸门是静态条件"）。
2. **逐径 `git add`，绝不 `-A`**，也**不许**从 `git status` 生成路径清单（`D-G108`）：推送前先 `git fetch`，非快进 ⇒ 停手报主控。
3. **进程只按 PID 收**；**绝不** `pkill`/`pgrep -f`（`D-G103`，本会话 5 次）。
4. **重活一律走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1800 --wait 1800 -- <cmd>`；`HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **都不是读数**。
5. **长任务走后台作业**（前台超 600 s 会被工具链 SIGTERM ⇒ 读数作废）。
6. **写盘 temp + `rename`**；改动前 `cp -p` 备份。
7. **显示号只用 `:2xx` 空闲号、几何 `1280x1024x24`**（`D-G105`）。
8. **冻结链的每一步都要独立复算**：`步骤通过/失败`、`用例通过`、日志 sha16、`config=` 互证九位、`设备上没有空间` = 0。
9. **对"会反复改写的车道"，单次采样不足以定罪**（反极性序列的中间态看起来像"异物写入"）—— 要看时间序列或直接问车道。
11. **指纹类读数（`inputs_fp` 等）只在树静止时有意义**：`verify-all` 的构建类步（如 `[13] hiddenonly`）会改**覆盖面内**的生成件 ⇒ 链在跑时算出的值会漂（现场实测同一命令先得 `cdfba971…`、几分钟后稳定在 `abd349fd…`，**前者作废**）。取指纹**必须在无链在跑时**，并**连算两次比稳**。
12. **「拿哈希去 grep 文件名」是范畴错误**：要举证「某件在覆盖面内」，先让工具**打印清单**（把 `fp_inputs()` 尾部的 `| sha256sum | cut -d' ' -f1` 剥掉）再 grep；直接对**哈希** grep 文件名会得 0 并**否掉正确归因**（本会话已发生一次，车道自纠）。
21. **新牙落地的同趟必须过 `PIPEFAIL-SIGPIPE` 牙**：它的扫描面是全树 `*.sh`，**新件一进仓就会改 `files=`／`sites=` 读数**（实测 `files 75→76 sites 79→82`，`undeclared_hit=3`）；且该牙的 `DECL` 表按**文件:行号**锚 ⇒ 新牙里凡 `printf … | grep -q` 一律改成 `case`／`[[ == *pat* ]]`（**不许消费管道 rc**）。这是该族**第三次**咬人（`D-G42` 本体 → `known-red-arms-check.sh:280`（`#56`）→ `prereg-four-requirements-check.sh`（`#58`））。
22. **`echo "post$i_rc=$?"` 是错的**：bash 把 `$i_rc` 当**一个**未绑定变量（`set -u` 下直接退出 ⇒ **少跑一趟**，形态是"缺趟"不是假绿）⇒ 必须写 **`${i}_rc`**。
23. **"冻前恰 1 处声明类红"是有条件的**：它的成立条件是**本波重取过臂／改过被声明件**（声明值与现场不再一致）。**仪器波若不动臂与声明件 ⇒ 冻前可以是全绿**（`#58` 实测 `31 ✅/0 ❌`、声明类红项 `[]`、冻结器走"全绿"分支）。派单里的期望读数**必须带条件**，否则会误导下一波。
19. **追加"历史行"的编辑必须用**插入**，不许用"替换前缀＋跳到行尾"**：`verify-all.sh` 的 `VERIFYALL-STEPS-DECL`／口径句是**累积历史**，按行替换会把上一代那行**整行吃掉**（实测一次）；改完必须 `grep -c` 核旧行仍在（本次靠该计数发现并回滚重做）。
20. **判据的"生效边界"必须可见**：早于生效代的证据件打 **`SKIP` ＋逐件点名 `reason=pre-effective`**，且与 `PASS` **分开计数**（超出射程 ≠ 通过，也 ≠ 违规）。**禁止**用"放低边界/删掉该件"换取好过；`--min-wave` 一类覆盖口只作**参数**。
18. **"两趟对拍"的合格线 = 判词行逐字一致**；跑次戳（`outdir=`）、临时目录随机后缀、仪器计数漂移（实测 `magenta_frames=38 vs 39`，而 `frames/max_colors/min_colors` 相同）**不算差异，但必须在报告里点名并列出实际数**。阈值：**任一判词行不同，或计数跑出观察到的带（38–39）⇒ 停手**。
24. **记录模板里的"花括号全大写"会被冻机器当占位符并 `assert` 炸掉**：`w27-freeze.py` 的占位符正则认的是「`{` ＋ 全大写名字 ＋ `}`」，而记录正文里常写 shell 变量（`${VAR}`／`{A,B}` 之类）⇒ **一律写成 `$VAR` 或用尖括号占位**（`<NAME>`），**不要**在模板正文里用花括号包大写词。落地前用机读校验器过一遍（`W62_DRAFT_CHECK` 同款）。
25. **"恒 0 守卫"是死代码**：实测一处把 `res['hits'] == 0` 写成 **list 比 int**（恒假）⇒ 那格"零命中守卫"**永不生效**，零命中的树被**误判绿**（由树级两极化暴露）。⇒ 凡守卫/断言，必须**用一条已知为真的输入**证明它**真的会亮**；`==`/`if` 两侧类型要**同类**（`len(x) == 0` 而不是 `x == 0`）。
16. **`python3 - <<EOF`（stdin 脚本）里取脚本自身位置一律不许用 `__file__`**：实测它在 stdin 下恒为 `<stdin>` ⇒ 反推仓根会**静默指到别处**（现场表现为 `NOINFO reason=registry-absent:/home/build/…` —— **不报错、只判错**，在 `verify-all` 里就是一个 ❌）。落法 = 由 bash 侧**显式导出**仓根（如 `GEOMBEAT_REPO`），并加一条自测钉住它。
17. **改"读数行/报告行"必须断言命中数**：用 `str.replace` 静默 no-op 是最隐蔽的假更新（本会话车道自伤两次：漏写 `land=`、漏更新 `new_findings`）。落法 = 逐字段断言重建，或替换后立刻 `grep -c` 复核。
14. **「必须成为 `head -1`」的插入，锚必须是**位置**，不能是上一代的文本**：`verify-all.sh` 的 `VERIFYALL-STEPS-DECL` 首行每代都会被上一波在**其之上**再插一行（实测 `#56`→`#57`：1053→1055 行），照抄上一代句子会把新行插到下面、`head -1` 取到旧代号。落法 = 解析首个 `^#\s*VERIFYALL-STEPS-DECL:\s*(\d+)\s+gen=(#\d+)` ＋ **先断言 `DECL 数 == grep -c '^run_step "'`** 再插。
15. **冻结只要改写了路由件（`KD`/`CS`/`HO`/`AB`），就必须重发 `declared.tsv`**（`defect-registry-check.sh --emit > …`）：`req=`/`present=` 是**路由状态快照**、不是不变量。本会话实测：`#57` 冻结改了 `AB`（基线件）⇒ 下一次 `verify-all` 的 `[10]` 直接 `DEFREG=FAIL reason=declared-id-missing-in-route`（而**不是**产品/链缺陷）。另：**每个世代重写"上一代的 banner 区"是既定行为**（`#55→#56` 亦丢 49 行 banner 文本）—— 别把它误判成"冻结丢内容"。
13. **派单里的期望读数必须标明出自哪个装置**：`6/6 result=PASS` 属 `#56` 的 `WPTD_*`；`TLINE_GATE=PASS` ＋ `judge=t1b3-tline-gate/7` 属 `#57` 的 tline 门禁 —— 照抄上一波的形状会给出**不存在的合格线**。
10. **`--emit` 是把声明表打到 stdout**（`defect-registry-check.sh --emit > declared.tsv`）；核对"声明 ↔ 现场"先看**被写文件的 mtime**。

## §6 未结清的账（主控侧）
- **我的三件本地领先**（`docs/ROUTES.md` / `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` / `build/MilBridge/tools/defect-registry-declared.tsv`）**待 `#57` 链跑完后推送**（避免撞成非快进）。它们**都不在 `fp_inputs()`**（已核 `inputs_fp` 未动）。
- **7 张往波账页**在 `$R`、不在 clone：`build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt`、`…20260923-{0926,1245}.txt` ⇒ 随下一波同批推或正式排除。
- **`~/wfp-runs/bridge-frozen.flag` 与 `/tmp/bridge-frozen.flag`** 是"哨兵两处"（`cmp IDENTICAL`）；`build/MilBridge/HANDOFF-NEXT.md`（本件）与 `handoff.md` 的旧版已过期，**以本件为准**。
- 车道报告入库约定：收尾波的车道报告放 `build/MilBridge/<LANE>-report.md` 并随该波提交推送（`W142A`／`W143A`／`W148A` 已在库）。

## §7 七条命令重建存活态（**先跑这七条，再动手**）
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 1) 冻结世代与基线件
sed -n '9p' $R/docs/CURRENT-STATE.md
# 2) 九位（与 §1 逐位比对；pf 是环成员、只作现场值）
for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do sha256sum $R/$f | cut -c1-16; done
# 3) 登记册自洽
bash $R/build/MilBridge/tools/defect-registry-check.sh | tail -3
# 4) 输入指纹（覆盖面 155 件）
bash -c "cd $R; awk '/^fp_inputs\(\)/,/^\}/' build/close-wave.sh > /tmp/fp.sh; . /tmp/fp.sh; fp_inputs"
# 5) 放行标记与记录件
ls -l ~/w21-verify/w5*-POST.done ~/w21-verify/w5*-record.txt 2>/dev/null
# 6) 推送面（本地 vs 远端 vs 工作树）
git -C ~/netTest/GitProj/WPFOnLinux log --oneline -3; git -C ~/netTest/GitProj/WPFOnLinux ls-remote origin refs/heads/feat-Linux | cut -c1-16; git -C ~/netTest/GitProj/WPFOnLinux status --porcelain | wc -l
# 7) 重活槽与内存
flock -n ~/heavy.lock -c 'echo SLOT=FREE' || echo SLOT=HELD; free -m | awk 'NR==2{print "avail="$7"MB"}'
```
