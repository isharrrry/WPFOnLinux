# 波 `#76`（合波四件）· 车道 W176A 报告（仓内版）

> 车道包：`~/w176a/w76/`（`report.md`／`criteria.md`／`polarity.md`／`logs/`）

  # W176A · 波 `#76`（合波四件）· `state=READY`
  
  包 `~/w176a/w76/`；**`$R` 零写入**（写者＝在跑的 `#74` 链 ⇒ 按闸停手）。
  
  - **件1 `TASK-0732`** 新牙 `new/boundary-decl-check.sh`（`41ea8e7c6d13dbf5`，711，`%h=1`）：声明**从预登记语料读回**（牙内零硬编码：`producer=`／`WAVE68`／`SilentHitProbe` 命中 **0**，同命令在语料命中 **1**）；域＝**件路径身份**（argv 归一＋**包装件闭包** ≤3，只认命令形态）；语料 56 件**每次重扫**（`D-G140`）；「没谓词的声明」**逐条点名成红**；**旁观带上限**（`DECL-BOUNDARY-BYSTANDERS: expect=2`，零余量，超出⇒`bystander-tree-grown` 点名；缺行⇒红）。
  - **件2 `TASK-0720`** 折叠 W175A 模块（0 字节件 **0**，sha16 逐件核）；修一处静默陷阱（该牙 `R` 硬指真仓 ⇒ 落仓器必须传 `R=`）＋**主控裁定 (A) 同波修 `D-G114` 同族管道**（两件新落地件的 `printf|grep -q` ⇒ here-string；`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0`；判词与自测逐字未变）。
  - **件3 `TASK-0721`** 不落（主控五件）；文本在 `~/w175a/w76/text/`。
  - **件4 `TASK-0741`** 9 处锚定编辑（逐处 `hits=1`）：件头口径句 ＋ 口径自证闸 ＋ 行尾 `direction=`（前缀语义不改）。自测 `12→17`。**件头零自述触发词**（`未接线`=0，只声明「已接线」，供 `#75` 的 `SELFDESC_WIRING` 读）。
  
  判据 `criteria.md`（`ed4d7082bbd5b55c`）｜读数 `polarity.md`（`4c45b7390adcb448`）＋ `logs/pol-*.out`。正极 `BOUNDARY_DECL=PASS records=2 coverage=4/6 gaps=0 corpus=56 rc=0` ⇒ **两条老声明都成立**。反极全真跑：`route=direct`／`route=transitive`／目标不存在⇒`NOINFO`(防恒挂)／**加新声明不动牙⇒红**／删记录／未覆盖点名／**旁观超上限⇒红**／**缺上限行⇒红**；**只有历史语料(55件)⇒`FAIL records=0`＋6 条 `DECL_BYSTANDER`**(绿依赖本波预登记，已写进件头与预登记)。件4：在位⇒`PTS_GUARD=PASS legs=2/2 … direction=in-file` `rc=0`；删句⇒`PTS_DIRECTION=FAIL` `rc=1`。演练 `W76_LAND=APPLIED steps=43 expect=200 coverage=200` ＋ 回滚路真跑。账（**落仓重取**）：步数 **+1**、覆盖面 **+3** ⇒ `#75` 后 **47／205**。卫生 `SHELL_QUOTE_TRAP=PASS`｜落地件 `$HOME/w` 命中 **0**｜`PREREG4=NA form=machine-line`。
  
  `NOINFO`：①未落仓/未跑整波/未冻结 ②件2 真树实跑绿未验（演练树子集）＋ 依赖主控 8 处替换与 `S1` 改名（否则 `PTSGAP=FAIL`，设计行为）③`W76_SKIP_*` 只演练用过 ④**件4 判据写于实现之后**（已逐字登记）⑤`#75` 的 `SELFDESC_WIRING` 落地前无法验件头。
  
  大意：声明"还成不成立"以后机器每次判（牙按**件路径**求值，改拼写/包壳糊弄不过去，**没谓词的声明当场点名**）。**只等写者让位。**
  
  `W176A: state=READY wave=#76 mod=4 files=8 tooth=41ea8e7c6d13dbf5 prereg=1e80296f38df3f41 land=3e34581a01895563 patcher=ee4694103f8ee883 selftest=13of13 pol=9of9of9 rehearse=APPLIED evidence=logs/rehearse-2-apply.out R_TOUCHED=none DONE=no NOINFO=5`
