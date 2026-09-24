# HANDOFF-NEXT —— wpf-linux 现场交接（**现读现算**；生成 2026-09-24 14:3x，取代此前所有过期版本）
> ⚠️ **本件数值随波变动**：下面所有 sha16／字节数／step 数**一律以 §7 现算为准**；本件是**导航**，不是判据。
> ⚠️ 本件的**唯一权威来源是现场**。若本件与现场冲突，**以现场读数为准**，并按 §7 的七条命令重取。
> ⚠️ **不引行号**（纪律 31）：本仓有若干件**每代重写**、且同一句会**多处出现**（如基线件的「九位」行现盘在 `:14` 与 `:77`，历史块共 7 处）⇒ **一律引内容锚**。

## §1 世代与冻结（现读）
- 冻结哨兵：`docs/CURRENT-STATE.md:9` = `BASELINE-FROZEN gen=#63 sha16=4ee96c043b472c11 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`
  （⚠️ **被哈希的件由这行的 `file=` 字段指定**，不是 `CURRENT-STATE.md` 自己。）
- 基线件：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `4ee96c043b472c11`／**919,687 B**（`#62` = `845219762aa61fb8`／903,901 B；`#61` = `e4b3d8e460896bf1`／880,779 B；`#60` = `da24cb43d2123612`／864,300 B）。
- 九位（`#63` 冻结值；取法见 §7-2）：`bridge 4e25e4b27d4d5ae1`｜`pc 722e0ab8205b7c3f`｜**`pf 9bf76afe89944ccc`**｜`windowsbase 2e4e46e539a72cd7`｜`provider 1f9511a7ef395bfe`｜`win32shim d2b76a0a56a41be1`｜`wic_shim f7b3026c8c019be2`｜`hbtextline 921ba9c65e9fb3be`｜`dwf ce3469f49efcbcfa`
  （`pf` 是**环成员**：整波重建必变、**同尺寸 6,123,520 B** ⇒ 不许当漂移/回归判据，`D-G92`。）
- `inputs_fp`（`#63` 落地后，**覆盖面 159 件**）：`7836c5fa17cd454893f9a4101fe2210181217f035c306122cbbed259293a772f`
  （`#62` 后 = `1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96`／158 件；`#61` 后 = `a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668`／157 件。**改动覆盖面内任一件必移**，属设计性变更。）
- **步数**：`verify-all.sh` = **36 步**（`#60` 加 `[34] PREREG-FOUR-REQ`、`#62` 加 `[35] PROC-PATTERN-GUARD`、`#63` 加 `[36] REGIME-IDENTITY`；`#61` 不动步数）。
- 推送：`feat-Linux` @ **`3e9d6f96c4c7ced9fdaf84b8dbe69c40d91887ef`**（本地 == 远端，`porcelain=0`）；clone = `~/netTest/GitProj/WPFOnLinux`（**`$R` 本身不是 git 仓**）。
- 放行标记：`~/w21-verify/w{59,60,61,62,63}-POST.done` **全在**（真时刻一律用 `stat` 取；`w63` = `2026-09-24 14:19:54.616048853`）。

## §2 在飞（**先读这节再动手**）
- **当前无在飞链**（`#63` 全链已收官、已推送、已放行；槽 `FREE`、无 `verify-all`/`close-wave`/`dotnet` 构建）。
- **下一波 `#64`＝`TASK-0717`**（把「基线率闸」做成牙）：入口 = 新件 `build/MilBridge/tools/baseline-rate-gate.sh`；规格输入 = `~/w157a/baseline-rate-gate.md`（`c4839dc9e8876bcf`／口径 `57915081ffdbacf8`）＋ `~/w157a/bin/baseline-rate-gate.py`（`0dac2ea941b56f4f`，**无第三方依赖**，已逐位复现仓内四个 `REQUIRED_N_ALT`）。
- **候选车道（都已收官、待命）**：W152A（`#60`／`#63` 仪器与判据件）｜W153A（`#61`）｜W154A（`#62` 装置牙）｜W155A／W156A（`TASK-0111` 装置与预登记）｜W157A（`TASK-0111` 判别批 ＋ 基线率闸方法页）。

## §3 队列（一条改动 → 一次冻结）
1. **`#64`** `TASK-0717`（基线率闸牙）：两极化两例（同窗自洽 ⇒ `PASS`；换掉出 CI 的样本 ⇒ `FAIL`）＋ **空样本／缺时间窗 ⇒ 响亮失败**；是否纳 `fp_inputs()` **落地前报主控**（纳则再挪一次指纹）。
2. 未闭 `[Next]`：**仅 `TASK-0717`**（`#64`）。`TASK-0709`–`TASK-0716` **已全部 ✅ 闭**（`#60`/`#61`/`#62`/`#63`）。
3. 未绿 `[MVP]`：`TASK-0007`（富文本 23／流文档 24 `rc=134`，真因 `TASK-0302`）｜`TASK-0201`（静默 `rc=139`，上界已收到 3.55%）｜`TASK-0302`（PTS／LineServices **可操作 91／实现口径 97**，月级长线；旧「111 条缺口」已证 `TOOL-UNSOUND`）。
4. `TASK-0111` = ✅ **归档为「不可判 ＋ 已知无产品价值」**（号不撤）：① 该红已被 `#54`/`TASK-0210` 修掉（现行桥 `4e25e4b27d4d5ae1` 上 `0/12` 红 vs 旧件 `12/12`）⇒ **产品价值 = 0**；② `A` 臂红率**随时间漂移**（`12/12 = 100%` → `7/28 = 25.0%`）⇒ `P1` 被排除 ⇒ **整批 `VOID-PREMISE`、40 腿不跑**；`N1` 作为修法**撤回**。判据件：`~/w156a/{criteria.md,leg-plan.md,AMENDMENT-1.md,AMENDMENT-2.md,WAVE-PREREG-0111.md}`｜装置 `~/w155a/device/wpfhintsgate.so 3c2a36580a7806f6`。

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

## §6 未结清的账（主控侧）
- **我（主控）的推送账**：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/HANDOFF-NEXT.md`／`README.md` 已于 **`f158988cf770`** 推上远端（逐件 `HEAD:` 核对 **5/5 MATCH**，`porcelain=0`）。它们**都不在 `fp_inputs()`**（改它们不动指纹），但**每次改完都要重发 `declared.tsv`**（`DEFREG` 判"route 文件里的编号是否都已声明"，改了却漏发 ⇒ `DEFREG=FAIL reason=undeclared-id-in-route`）。
- **app-local（仓外共享目录）**：`~/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0` 已由主控用 `sync-applocal.sh` 修好（`drift=3 → 0`，**其中一件曾是修前桥 `feef049e9d0e313a`**）。**后续任何"探针测到陈旧件"的现象先查这里**。
- **两处哨兵**：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag`（`cmp IDENTICAL`）；`handoff.md`（`HO` 键）与**本件**不同：前者是**上游/入口文档的压缩版**，后者是本交接件。
- **车道报告入库约定**：收尾波的车道报告放 `build/MilBridge/<LANE>-report.md` 并随该波提交推送。

## §7 七条命令重建存活态（**先跑这七条，再动手**）
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 1) 冻结世代与基线件
sed -n '9p' $R/docs/CURRENT-STATE.md
# 2) 九位（与 §1 逐位比对；pf 是环成员、只作现场值）
for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so build/PresentationCore.Linux/bin/Release/PresentationCore.dll build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll src/WpfGfx.Linux.Native/bin/libwpfwin32.so build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs build/WindowsBase.Linux/bin/Debug/WindowsBase.dll build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do sha256sum $R/$f | cut -c1-16; done
# 3) 登记册自洽
bash $R/build/MilBridge/tools/defect-registry-check.sh | tail -3
# 4) 输入指纹（覆盖面 159 件）—— 用已校准的复算器（**只借不改**）
bash ~/w153a/bin/infp.sh fp        # 期望 7836c5fa…
bash ~/w153a/bin/infp.sh list | wc -l   # 期望 159
# 5) 步数与自检 / 放行标记与记录件
grep -c '^run_step "' $R/verify-all.sh; bash $R/build/MilBridge/tools/verify-all-step-check.sh | grep VERIFYALL_SELF
ls -l ~/w21-verify/w6*-POST.done ~/w21-verify/w6*-record.txt 2>/dev/null
# 6) 推送面（本地 vs 远端 vs 工作树）
git -C ~/netTest/GitProj/WPFOnLinux log --oneline -3; git -C ~/netTest/GitProj/WPFOnLinux ls-remote origin refs/heads/feat-Linux | cut -c1-16; git -C ~/netTest/GitProj/WPFOnLinux status --porcelain | wc -l
# 7) 重活槽与内存
flock -n ~/heavy.lock -c 'echo SLOT=FREE' || echo SLOT=HELD; free -m | awk 'NR==2{print "avail="$7"MB"}'
```
