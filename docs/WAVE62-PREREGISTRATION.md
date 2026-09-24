# WAVE62-PREREGISTRATION（波 `#62`）—— 装置欠账批 C（`TASK-0714`）＋ 文档收尾（`TASK-0715`）

> 波 `#62`｜车道 `W154A`｜判据 = `~/w154a/criteria.md`（**§0–§6 写定于取任何自有读数之前**；§7 为读树/写原型后的**加注**）

## §1 判据（先写）

PREREG-NO-REGRESSION-DECISION: yes（本波不做任何回归判定；本判据节内逐字声明）

**本波不做任何回归判定** —— 本波没有两臂对拍、没有成对归因臂、不复现、不做 Fisher 精确检验，
因此回归判定四要件（① 两臂同刻 ② 成对归因臂 ③ 复现性 ④ Fisher 精确检验）**对本波不适用（`NA`）**；
本判据节的判词只有三态 `PASS`／`FAIL`／`NOINFO`（`NOINFO` 既不算绿也不算红），**不产出任何回归判定**。
⇒ 按 `#60` 起的 `PREREG4=NA` 口径：**这是"这一刻不适用"的声明，不是"我已经做过"的声明**。

1. **牙的判据**：凡按模式匹配**命令行文本**来收/数进程的调用，必须能证明它把"承载本调用的那条进程链"排除在外 ——
   且排除必须**同时**覆盖 `$$` 与 `$PPID`（只排一个不算证明；`pgrep -P "$$" -f …` **不算**，它只是**集合限定**）。
2. **证据域**（`criteria.md` §2.0，挂 `D-G119`）：**剥注释后的代码文本，且非 shell heredoc 体置空**。
   三域反例：**掩码域→假阴性**（引号里的 `/proc/…/cmdline` 被抹 ⇒ 靠"看不见"过关）／**全文域→假阳性**／**注释域→假绿**（注释里的"排除"不算证明）。
3. **三态**：`PROCGUARD=PASS|FAIL|NOINFO`；`FAIL` 逐处点名 `file:line`；**缺声明 ≠ 通过**；**红优先于 `NOINFO`**；`NOINFO` 既不算绿也不算红。
4. **接线那一刻树必须绿**：新步进 `verify-all` 后 `partial=0 ⇒ PASS`（`partial>0→FAIL`｜`files<--min-files→NOINFO`｜零命中→活性证明｜否则 `PASS`）。

## §2 两极化（成对读数，逐条给机读行）

| 臂 | 操作 | 期望 |
|---|---|---|
| A | 干净树 | `PASS`（零命中 ＋ 活性自证） |
| **B** | 注入一处裸 `pkill -f` | **`FAIL`** ＋ 点名 `inj.sh:2 form=P1 verdict=partial proof=missing-any-proof` |
| C | 撤回注入 | 回 `PASS` |
| D | 仓根不存在 | `NOINFO`（`rc=2`） |
| E（钉子） | 只把"排除"写在**注释**里 | **必红**（自测格 `bad-proof-in-comment-only`） |

## §3 闸基线（现读，整行照抄）

```
PROCGUARD_SCOPE files=161 hits=15 na=2 full=9 partial=6 noinfo=0
PROCGUARD=FAIL reason=missing-self-exclusion
```
历史读数链 `7/1/6 → 9/3/6 → 15/9/6`：**`partial=6` 的集合始终是同样那 6 处** ⇒ 判定语义与落地范围未变；
多出的 6 个 `full` = `run-wpfprobe.sh:115-117`／`run-wpftextdemo.sh:351-353`（`argv-identity@loop`，本来就已证明、以前"看不见"）。
落地后预期：`files=162`（**牙自己进了 `build/MilBridge/tools/`**）＋ `partial=0` ⇒ `PROCGUARD=PASS reason=all-hits-proved`。

## §4 预期位移（先写死）

- 九位：**只 `pf` 同尺寸位移**（环成员 `D-G92`）；**出现第二处 ⇒ 停手上报**。
- `inputs_fp`：**必移**（① 牙入名单 ＋ ① 新件 ② `close-wave.sh` **自含**于覆盖面且被改）；成对记账 ＋ 交叉表见 `~/w154a/report.md` §11.1／§12.5。
- 步数 `34 → 35`（**四处声明同趟**）。
- 牙：**进树后逐字节 == `43fbe8a830526b6d`**。

## §5 边界／`NOINFO`（照录，不许缩小）

牙**只判仓内 `*.sh`/`*.py` 的静态文本**：变量间接／`eval`／非 sh-py 调用方／非 shell heredoc 体／交互式命令／**仓外脚本**判不了
（本会话 5 次咬里多发生在 `$HOME/**` 车道目录）⇒ **"牙 PASS" ≠ "这台机器上不再有自匹配事故"**；
`proof=full` 是"**能证明**"不是"已证明跑对"（构造本身写错看不见）。

## §6 引用

`D-G119`（判据装置缺陷 · 域选错：四域＋对偶判据）／`D-G116`（跨臂体制同一性牙）／`D-G103`（按模式收进程族）。
