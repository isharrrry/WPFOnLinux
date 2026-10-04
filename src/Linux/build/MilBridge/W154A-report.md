# W154A 报告 —— 波 `#62` 收尾链（`TASK-0714` 装置欠账批 C ＋ `TASK-0715` 文档收尾）

> 车道 `W154A`｜仓 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜冻结 `#62` = `845219762aa61fb8`
> 判据先写：`~/w154a/criteria.md`（§0–§6 写定于取任何自有读数之前；§7 为读树/写原型后的**加注**，§2.0 为 `D-G119` 落地时补的**证据域**规则）
> 接线预备 `~/w154a/tooth-plan.md`｜文档对齐 `~/w154a/docs-align.md`（`OLD_BLOCK_CHECK ok=15 bad=0`）｜调用点补丁**单一真源** `~/w154a/callsite-fixes.py`（`CALLSITE_VERIFY=PASS`）

---

## §0 一句话

把「**按模式匹配命令行**收/数进程」做成了一颗**带牙的判据**（`build/MilBridge/tools/proc-pattern-guard.sh`，`--selftest 19/19`）并**同趟修掉 6 处真站点**；
两处入口文档对齐现读世代；四处声明同趟改 ⇒ `verify-all` **34 → 35 步**；冻前/冻后 `35 ✅ / 0 ❌`。

## §1 落地清单（全部 `temp ＋ rename`，前后 sha16 双断言）

| 件 | 前 → 后 |
|---|---|
| `build/MilBridge/tools/proc-pattern-guard.sh` | **新**（`43fbe8a830526b6d`，逐字节 = 仓外原型） |
| `build/close-wave.sh` | `053f5820e354c5ed → 07ee249b8f570895`（`fp_inputs()` 纳入牙） |
| `verify-all.sh` | `a79c1169a11ac82e → 58422c5f1f2c5682`（新步 ＋ 四处声明） |
| `docs/WAVE62-PREREGISTRATION.md` | **新**（标题含字面 `#62`；`PREREG4=NA`） |
| `docs/FORK-AND-PUSH.md` | `78de7d2158f430e3 → 8efeefd1136d76a9` |
| `docs/PORT-SPEC.md` | `8a276090e3e6180f → 36ef219617fb8d36` |
| `tests/.../Windowing.Tests/start-xvfb.sh` | `bc716d9a997b358f → 504029b836190d4a` |
| `tests/.../run-wpfprobe.sh` | `6e2e994be056ea10 → 432b232b55b469a3` |
| `tests/.../run-wpftextdemo.sh` | `57180b9fad939748 → d4b9a663673031d2` |
| `tests/.../run-wpfprobe-1400rate.sh` | `1442cc9466deccdf → 690d16898ec5de85` |

## §2 判据（先写）与三态

凡按模式匹配命令行文本收/数进程，**必须能证明排除了自身**（`$$` ∧ `$PPID`；`pgrep -P "$$" -f …` **不算** —— 它只是**集合限定**）。
三态 `PROCGUARD=PASS|FAIL|NOINFO`：**缺声明 ≠ 通过**、**红优先于 `NOINFO`**、`NOINFO` 既不算绿也不算红。
**证据域**（`criteria.md` §2.0／`D-G119`）= **剥注释 ＋ 非 shell heredoc 体置空**后的代码文本。

**闸基线（整行照抄）**：
```
PROCGUARD_SCOPE files=161 hits=15 na=2 full=9 partial=6 noinfo=0
PROCGUARD=FAIL reason=missing-self-exclusion
```
历史读数链 `7/1/6 → 9/3/6 → 15/9/6`：**`partial=6` 的集合始终是同样那 6 处** ⇒ 判定语义与落地范围未变。
**落地后**：
```
PROCGUARD_SCOPE files=162 hits=21 na=4 full=21 partial=0 noinfo=0
PROCGUARD=PASS reason=all-hits-proved
```
（`files 161 → 162` 的成因 = **牙自己进了 `build/MilBridge/tools/`**；`hits 15 → 21` = 6 处修法把裸模式调用换成 `/proc` 枚举后**被判为已证明**。）

## §3 两极化（灵敏度证据）

| 臂 | 读数 |
|---|---|
| A 干净树 | `PROCGUARD=PASS reason=zero-hits-but-scanner-self-tested` |
| **B 注入一处裸 `pkill -f`** | `PROCGUARD_HIT inj.sh:2 form=P1 cmd=pkill verdict=partial proof=missing-any-proof` ⇒ **`PROCGUARD=FAIL`** |
| C 撤回注入 | 回 `PASS` |
| D 仓根不存在 | `PROCGUARD=NOINFO reason=repo-absent`（`rc=2`） |
| E **只把"排除"写在注释里** | **必红**（自测格 `bad-proof-in-comment-only`） |

判词逻辑：`partial>0→FAIL`｜`files<--min-files→NOINFO`｜`len(hits)==0 ∧ na==0→活性证明`｜**否则 `PASS`**
⇒ **6 处修完 `partial=0` 即 `PASS`，与 `full` 的数量无关**。

## §4 成对记账 ＋ 交叉表（`inputs_fp`）

```
before              = a00bf53a64c47531963b0f82aae689fe4cee1363c7b9e670799566cb7963c668（157 件）
only_tooth_in_list  = e2f7cb3fd083abf18880b62c96f4bd543f9253026b37a2ddf528fd99de989c48
only_closewave_changed = f002b4bef022bfd4a076c3f1b55f6ecd9f9c994cb6aad1f97884e0695dcea87c
after（**实测**）     = 1ffd13f7c927dea71fd5dca866f7c6f81e8efce9939c22c85d55c0a35fb20f96（158 件）
R1 只退 cw 那行 sha ⇒ == only_tooth_in_list : OK
R2 只去掉新牙那行   ⇒ == only_cw_changed    : OK
R3 两者都退回       ⇒ 逐位 == before        : OK   ⇒ **100% 归因 ∧ 无第三隐形位移**
R4 after == after_predicted                 : OK
```
归因两件且可点名：① 牙入名单（`coverage_n 157 → 158`）② `close-wave.sh` **自含**于覆盖面且被改。

## §5 整波／门禁／冻结

- 整波（槽内）：`HEAVYSLOT=RELEASED rc=0 held=163s`｜`[4/6]` 桥源两侧一致 `d697b1e10ff48881`／应用器审计 **`miss=0`**／**波前==波后 == `1ffd13f7…`**｜`APPSYNC` 形态与 `#59` 逐字同形（`MISMATCH=0 STALE=0 DIVERGENT=0；UNEXPECTED=6[DECL-GAP-EQ=6]`）⇒ 继承、非本波引入。
- **九位：只有 `pf` 动** `d5de121c1c787193 → 3c808e94034c4514`（环成员 `D-G92`，同尺寸 6,123,520 B）⇒ **无第二处位移**。
- 门禁 ×2：各 `WPTD_SUMMARY=PASS tiers_passed=2/2`／`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`／各 6 行 `result=PASS`；**对拍唯一差异 = `rundir=gate-e` vs `gate-e2`**（点名；其余 `drawn=261/144`、`colors=4112/2945`、`cross_ae=0`、`leftover_after=0` 逐字一致）。
- 冻前 `verify-all` = **`35 ✅ / 0 ❌`**（`rc=0`，875 通过 2 跳过）；**声明类红 = `[]`（全绿，照实报）**。
- 冻结 `#62` = **`845219762aa61fb8`**／903,901 B；`BASELINEGEN=PASS`／`BASELINEDUP=PASS n=0`／`ARMLOG_SHA=PASS 5/5`／`COLUMN_FLOOR=PASS`／世代交叉断言 `树上 #61 == GENS[#62][prev]` ✓。
- 冻后 `verify-all` ×2：各 **`35 ✅ / 0 ❌`**；判词行 **47 行**，分类归一后**不一致 = 0** ⇒ `VERDICT_LINES_EQUAL=YES`（点名三类非参与差异：跑次戳 `w34-framepresence-125043/-130512`、`w37-tpm-125301/-130728`；帧计数 `41/42`；内存读数 `4107/3977` MB）。
- `~/w21-verify/w62-POST.done` 真时刻（`stat`）= **2026-09-24 13:09:14.404562549 +0800**（0 B）。

## §6 自伤（如实入册；全部零残留损害）

**落地器/仪器（本波我自己逮出，共 7 处）**
1. `write_guarded` 不认"新建件" ⇒ ⑤ 崩（①②③④ 已落）⇒ 靠**幂等守卫续跑**恢复，并补新建件分支。
2. **`C5b` 被插两次**（`xvfb_pid_of()` 重复定义）：幂等判据写成 `new in s and old not in s`，而 **`NEW` 逐字包含 `OLD`** ⇒ 永不跳过。⇒ 修（**只判 `NEW` 在不在**）＋ 把件**复原到 run1 后 C6 的精确状态**（`690d16898ec5de85`，与预期逐位相同才算修好）。
3. 预登记**标题缺字面 `#62`** ⇒ `VERIFYALL_SELF=NOINFO reason=prereg-absent`（**缺声明不许当绿**）⇒ 补。
4. ⑥ 幂等**只加在"替换"分支、漏了"插入"分支** ⇒ H6 二次插入（`FORK-AND-PUSH.md` 坏态 `dd9ee978bf59fcbd`）⇒ 从"已复核的空跑产物"复原（`8efeefd1136d76a9`，与 `dry/` 逐字节相同）。**守卫写一半比没有更危险**。
5. 交叉表**落地后三处假红**：`only_tooth_in_list` 仍"合成插入"⇒ 又插一份／`before` 写成 `fp(live)`（落地后那已是 `after`）／退化目标用了新 sha（等于没退化）。
6. **`QUOTE-TRAP` 4 traps（`verify-all.sh:1031`）**：我新加的 `echo` 行**双引号里带反引号** ⇒ **命令替换真跑了**（日志可见 `D-G103: 未找到命令`／`TASK-0714: 未找到命令`）。**这正是 `#59` 记录里我自己引用过的第 ④ 条纪律 —— 引用了没照做。**
7. **`PREREG4=FAIL（missing=8）`**：`NA` 路线要「**判据节内**逐字 `本波.*不做任何回归判定`」；我原写「不做回归判定」**少了「任何」**、且写在 §1 **之上**（`extract_section()` 取**第一个含"判据"的标题**之下的文本）⇒ 搬进 §1 并补机读行。

**判据装置（`D-G119`，由"给自己那 6 处修法做沙箱验证"逼出）**
① **掩码域→假阴性**（引号包住的 `/proc/…/cmdline` 被抹 ⇒ **靠"看不见"过关的假绿**）｜② **枚举域→假阳性**（把"读一个给定 pid"当枚举）｜③ **heredoc 域→假阳性**（`loop_ranges` 算全文 ⇒ Python heredoc 的 `for` 当 shell 循环）｜④ **注释域→假绿**（注释原文当 `probe`）。
**对偶判据（本轮最重要的判据产出）**：`§2` 早写「注释不算调用」，其**对偶**必须成立 —— **注释里的"排除"不算证明**（否则一行 `# 我已排除 $$ 与 $PPID` 就能把红变绿）。钉子 = 自测格 `bad-proof-in-comment-only` **必红**。

**heredoc 自伤第 4 次**：写更新脚本时在内联双引号字符串里又写裸直引号 ⇒ `SyntaxError`（零损害，发生在任何写入之前）。
**教训**：长文本一律写文件 —— 我第三次就立了这条规矩，本轮**没守住**（第三次违规之后又犯）。

## §7 边界／`NOINFO`（照录，不许缩小）

牙**只判仓内 `*.sh`/`*.py` 的静态文本**：变量间接／`eval`／非 sh-py 调用方／非 shell heredoc 体／交互式命令／**仓外脚本**（本会话多次咬发生在 `$HOME/**` 车道目录）**判不了** ⇒「牙 `PASS`」**不**等于"这台机器上不再有自匹配事故"；
`proof=full` 是"**能证明**"不是"已证明跑对"（构造本身写错看不见）⇒ 那三格成对实验本波**没跑**（无 X、无应用腿）。
`--exclude-self` 目前**仓内无任何程序理解它** ⇒ 判据要求它必须与具体 `$$`/`$PPID` 同域出现。

## §8 推送侧发现（**本波最该被人看见的一条**）

**`handoff.md` 的压缩版（5283 → 333 行）从未进过远端**：
- `2e15b61`（**09:09:19**）提交的仍是 **5283 行**版；
- `$R/handoff.md` = **333 行**，mtime **09:17:44**（比那笔提交晚 **8 分钟**）⇒ **从未 commit/push**；
- 而声明表的 `HO` 锚 = `a4d8ffcf4c37f6fe` = **压缩版**的 sha ⇒ **声明已指向压缩版，远端却还是旧版** ⇒ 「结论在远端不可复算」。
⇒ 本波**同趟推 `handoff.md`**（它是 `TASK-0715` 的产物；**不在**主控五件写域内），并在此**点名**。
