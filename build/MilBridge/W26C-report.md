# W26C 报告 —— `D-G13`（仪器级）：`--selftest` 的 `SELFTEST_M2` 竞态 ⇒ **`NOINFO`，不再 `FAIL`**

> 车道 **W26C**｜2026-09-17 14:00→14:5x +0800｜kernel 6.8.0-138-generic｜`nproc=3`｜**零 `dotnet`**（一个都没跑）｜未跑 `--apply`／未跑 `sync-applocal-authority.sh` 任何模式｜未 `pkill`｜未用 `pgrep -f` 定人。
> 派单：`docs/WAVE26-PREREGISTRATION.md`（`7d663bf886a79be8`）§1/§4/§5/§6；缺陷登记 = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`cf6d8ea871950d9d`）`:1073-1077` 的 `D-G13`。

## §0 写域清单（**逐条 before/after sha16**）

| 路径 | before sha16 | after sha16 | 说明 |
|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `7bc9364091a28fd4`（945 行 / 86,734 B） | **`27ecae1580a07527`**（1,024 行 / 94,564 B） | **唯一改动件**：+91 / −12 行（删掉的 12 行 = 被同名改写的那 12 行本身） |
| 备份 | `$HOME/w26c-backups/check-applocal-sync.sh.before` = `7bc9364091a28fd4`（`cp -p`） | — | 纪律 16 |

**未碰**：`applocal-expect.py`、`sync-applocal-authority.sh`、`known-red-PC-copies.md`、`build/MilBridge/known-red.json`、`verify-all.sh`、`CoverageProbe/Program.cs`、`docs/**`、`handoff.md`、基线文件、真桥两份副本与发布记录（`d567c26f197ec1e3`）。全部装桩/还原只发生在 `$HOME/w26c/**` 与 `mktemp -d` 沙箱里。
**行文口径**：本报告所有 sha 一律现场 `sha256sum | cut -c1-16` 计算，无手抄。

## §1 结论（先给答案）

1. **`D-G13` 已修**：`SELFTEST_M2` 的三态落地 —— **同一棵树 ⇒ 判该次运行内部一致性（`PASS`/`FAIL`）**；**两个时刻的仓库不同 ⇒ `NOINFO`**（不再冒充红）；快照算不出来 ⇒ `NOINFO`。
2. **`--selftest` 改后 18 例全 `PASS` / 0 `FAIL` / rc=0**（`34d80971f9403a55`；改前同读数 `d42dc0f8334d4f95`）——**一条都没坏**。
3. **反极性两个方向都有成对读数**：竞态场景下 **改前 `SELFTEST_M2=FAIL` rc=1 ⇒ 改后 `SELFTEST_M2=NOINFO` rc=3**；而**真坏**（同一棵树、告诫真没印 / 印了但数字错）**改后仍 `FAIL` rc=1**。
4. **顺带把判据面加严了一处**（新牙）：以前只查"告诫字样在不在"，**不查数字对不对** ⇒ "印了但印错数"能过（实测：**改前 18/18 PASS 而改后 `FAIL`**）。现在 `另有 **N 条只读点未印**` / `补扫的写点 **N 处**` 里的 N 必须**逐位等于**枚举器自报值，且自报 0 时**不许**出现对应告诫。
5. **⚠️ 发现同族的第二个假红源（新，`D-G13` 派单书没写）**：`SELFTEST_M` 那三条断言写成 `printf '%s' "$outM" | grep -q PAT`，在 `set -o pipefail` 下**会因 `SIGPIPE` 假红**——**实测三条合计 ≈ 6.6–6.8%/次**。**已就地改成 here-string（0/400）**；**其余 14 个同形调用点未改**（见 §7，留给主控裁定）。
6. **判定面零位移**：静树上全量（不带 `--selftest`）的**整份输出与改前逐字节相同**（`static.before.log` 与 `static.quiet.log` 的 sha16 **同值 `33e759c22654fb6d`**），`APPSYNC=`/全部计数器与 `#25` 逐字一致。

## §2 改动逐处（新文件行号；`diff` = `$HOME/w26c/w26c.diff` `e0ee74d44a258805`，6 个 hunk）

| hunk（新行） | 内容 |
|---|---|
| `:119-131` | 文件头：`M2` 三态口径 + `--selftest` 退出码 `0/1/3` + **第二个假红源（`SIGPIPE`）**的实测记录 |
| `:139-148` | 用法段：`--selftest` 退出码三态；"本自检必须在静树上跑"的既有纪律的显式化 |
| `:545-548` | `SELFTEST_NOINFO=0` 初始化（子例第三态计数器） |
| `:762-780` | **M 段**：`mSnap()`/`mField()` + `snapPre`/`snapPost` **夹住** `outM` 那次运行（= **把 M 时刻的自报序列化**）；三条断言 `printf\|grep -q` → **here-string**（`:776-777`） |
| `:785-839` | **M2 段**：三态判定（`:800-810`）+ 数字相符的四条加严牙（`:812-826`）+ `PASS`/`FAIL` 出口（`:827-837`） |
| `:945-952` | 尾部：`rc=0` **只在全 `PASS`** 时给（`:948-949`）；有 `NOINFO` ⇒ `SELFTEST=NOINFO`（`:951`）+ `exit 3`（`:952`） |

**关键 hunk 原文（节选，逐字）**

```sh
766:    mSnap()  { python3 "$EXPECT_TOOL" "$PREV_AUTH" "$PREV_AUTH" 2>/dev/null | grep -m1 '^#SUMMARY|'; }
767:    mField() { printf '%s' "$1" | sed -n "s/.*|$2=\([0-9]*\).*/\1/p"; }
768:    snapPre="$(mSnap)"
769:    outM="$(AUTH_ROOT="$PREV_AUTH" "$0" 2>&1)"
770:    snapPost="$(mSnap)"
...
776:    if grep -q "本校验器看不见的拷贝点" <<<"$outM" \
777:       && grep -q "\[写点\]" <<<"$outM" && grep -q "不会被本校验器报出" <<<"$outM"; then
...
795:    capM="$(mField "$snapPost" invisible_capped)";  extM="$(mField "$snapPost" invisible_ext_write)"
796:    capM2="$(mField "$expM2" invisible_capped)";    extM2="$(mField "$expM2" invisible_ext_write)"
798:    extOut="$(printf '%s' "$outM" | sed -n 's/.*补扫的写点 \*\*\([0-9]*\) 处\*\*.*/\1/p' | head -1)"
799:    capOut="$(printf '%s' "$outM" | sed -n 's/.*另有 \*\*\([0-9]*\) 条只读点未印\*\*.*/\1/p' | head -1)"
800:    if [ -z "$snapPre" ] || [ -z "$snapPost" ] || [ -z "$capM" ] || [ -z "$extM" ] \
801:       || [ -z "$expM2" ] || [ -z "$capM2" ] || [ -z "$extM2" ]; then
802:        echo "SELFTEST_M2=NOINFO（参考快照算不出来：applocal-expect.py 不可用 / 无 #SUMMARY ⇒ **无信息**，不是判据失败）"
803:        SELFTEST_NOINFO=$((SELFTEST_NOINFO+1))
804:    elif [ "$snapPre" != "$snapPost" ]; then
805:        echo "SELFTEST_M2=NOINFO（M 那次运行的**窗口内**仓库就变了 ⇒ 那次运行看到的是哪一棵树不可知 ⇒ **无信息**）"
806:        SELFTEST_NOINFO=$((SELFTEST_NOINFO+1))
807:    elif [ "$capM" != "$capM2" ] || [ "$extM" != "$extM2" ]; then
808:        echo "SELFTEST_M2=NOINFO（**两次取数之间仓库变了** ⇒ **无信息**：M 时刻 capped=$capM ext_write=$extM ｜ M2 时刻 capped=$capM2 ext_write=$extM2；判据本身没有失败）"
809:        SELFTEST_NOINFO=$((SELFTEST_NOINFO+1))
810:    else
811:        okM2=1; whyM2=""
...
```

**`mSnap` 为什么用两个参数**：与脚本自己 `:217` 那次调用（`python3 "$EXPECT_TOOL" "$REPO" "$HINTPATH_ROOTS"`）**同形**，保证快照与"M 那次运行看到的"是同一口径。已实测**一参数与两参数输出的 `#SUMMARY` 逐字节相同**（`diff` 空，见 §10 命令 ②）。

## §3 `--selftest` 读数（缺一不算完成的那一项）

| 趟 | 文件 sha16 | 逐例 | rc | WALL |
|---|---|---|---|---|
| 改前 | `check-applocal-sync.sh` = `7bc9364091a28fd4` | **A…P 共 18 例全 `PASS`**（`d42dc0f8334d4f95`） | 0 | 57.27 s |
| 改后（第一版 M2 改动） | `e12831d315839120` | **18 例全 `PASS`**（`54c61ffffb9f3cf9`） | 0 | 54.31 s |
| **改后（最终 `27ecae1580a07527`）** | `27ecae1580a07527` | **A…P 共 18 例全 `PASS` / 0 `FAIL` / 0 `NOINFO`**（`34d80971f9403a55`） | **0** | 55.84 s |

逐例状态（最终趟，逐字）：`A B C D E F G H I J K L L2 N M M2 O P` 全 `=PASS`（顺序即脚本打印顺序）。
`SELFTEST_M2=PASS（同一棵树（snapPre==snapPost==expM2）：invisible_capped=3 ⇒ 截断自称**且数字相符**；invisible_ext_write=4 ⇒ 补扫自称且逐条印）` ⇒ **数字牙在真件上也是绿的**（3 与 4 逐位相符）。
`SELFTEST=PASS`（尾行）。**本趟运行期间有其它车道在跑（`dotnet` 进程数 = 1）**；M 窗口 `snapPre == snapPost` ⇒ 该趟是"同一棵树"，读数有效（如实登记）。

## §4 反极性矩阵（**每一格都有日志与 sha16**）

夹具 = `$HOME/w26c/repro-*/`（`check-applocal-sync.sh` 的**副本** + 同名 `applocal-expect.py` = 透传夹具 `flipwrap.py` `5112f4d95a8053f2`）。夹具按**调用序号**把 `#SUMMARY` 的 `invisible_capped` 改成 `0`，从而**确定性复现**"M 那次运行看到 capped=0、M2 时刻重算看到真值 3"的竞态。**调用序号由夹具自己的轨迹日志自证**（old：1 参数调用 = `call 22`；new：`call 24`；`hit=` 列显示是否被改写）——不是猜的。

| 场景 | 改前 `7bc9364091a28fd4` | 改后 `27ecae1580a07527` |
|---|---|---|
| **静树**（真件，无夹具） | 18/18 PASS，rc=0 `d42dc0f8334d4f95` | **18/18 PASS，rc=0** `34d80971f9403a55` |
| **竞态**（两时刻仓库不同） | **`SELFTEST_M2=FAIL（capped=3 ext_write=4 ok=0）`，rc=1** `46674cb45836c172` | **`SELFTEST_M2=NOINFO（**两次取数之间仓库变了** … M 时刻 capped=0 ext_write=4 ｜ M2 时刻 capped=3 ext_write=4）` + `SELFTEST=NOINFO`，rc=3** `acee16aa505f4517` |
| **真坏①**（同一棵树、删掉"截断自称"分支） | `SELFTEST_M2=FAIL`，rc=1 `b1963bedb3a66488` | **`SELFTEST_M2=FAIL（**同一棵树**（capped=3 ext_write=4）而自称缺失/数字不符：自报 capped=3 却没印「只读清单**不完整**」；截断数不符：输出自报 [] ≠ 枚举器 [3]）`，rc=1** `796508ef6313c2e4` |
| **真坏②**（同一棵树、`**$INVIS_CAPPED**` → `**$(( INVIS_CAPPED + 1 ))**`：串在、数错） | **`SELFTEST_M2=PASS`，18/18 PASS，rc=0（瞎）** `57c76545b3311337` | **`SELFTEST_M2=FAIL（…截断数不符：输出自报 [4] ≠ 枚举器 [3]）`，rc=1** `ac91c13136cdde49` |
| **真坏③**（M1：删掉 `[写点]` 打印） | （机制同前，未单独跑） | **`SELFTEST_M=FAIL`，rc=1** `20ec6a483f2c2ea9` |

**逐条读法**

- **①（该红的还红）**：`case3b`/`case5c`/`case7` 三格全部 `FAIL` + rc=1 ⇒ **红检测一条都没被放松**；`case5c` 还是**新牙**独有的判别力（改前那格是绿的）。
- **②（只是仓库被改 ⇒ `NOINFO`）**：`case2b` 的判据行**逐字**打印了两时刻的值（`M … capped=0` vs `M2 … capped=3`）⇒ 夹具的改写**确实只落在 M2 那次重算上**，竞态是**真的**被复现出来的，不是"改后不红了"的空证。
- **额外读数（改后的好处，附赠）**：`case1`（改前）在 M2 `FAIL` 后**立即 `exit 1`** ⇒ `O`/`P` 两例**从未跑**（日志里只有 16 例）；`case2b`（改后）在 M2 `NOINFO` 后**继续**跑完 `O`/`P` ⇒ **17 `PASS` + 1 `NOINFO`**，读数一个都没吞。

## §5 `NOINFO` 的接线（取舍与理由，附读数）

- **取舍**：`--selftest` 的退出码落地为 **`0` = 全 `PASS`｜`1` = 有子例 `FAIL`｜`3` = 无 `FAIL` 但有子例 `NOINFO`**。
- **理由**：① 本工程铁律 **`rc=0` 只在全 `PASS` 时给出** ⇒ `NOINFO` **不给 0**（"仪器未能自证"不是通过）；② 但 `NOINFO` **也不许冒充红** ⇒ **不与 `FAIL` 的 `rc=1` 合并**（否则又回到 `D-G13` 那个假红）；③ `3` **不是新发明的码**——本文件本来就用 `3` 表示 `NOINFO`（`:526` `ITEMS_SYNC=NOINFO … exit 3`、`:1013` `APPSYNC=NOINFO … exit 3`，文件头/在册红段 `:968` 亦记载"退出码只有 `0=PASS`／`1=MISMATCH`／`3=NOINFO`"）。
- **落地细节**：`FAIL` 仍在各自分支**立即 `exit 1`**（一条红都不吞）；只有 `NOINFO` 走 `SELFTEST_NOINFO` 计数并**继续**后续子例。
- **读数**：`case2b` → `SELFTEST=NOINFO（1 例为 NOINFO ⇒ **仪器未能自证**：无信息 ≠ 通过（**不给 rc=0**），也 ≠ 判据失败（**不混进 rc=1**）；逐例见上）` + `rc=3`；静树趟 → `SELFTEST=PASS` + rc=0。

## §6 静树读数（判定面零位移）

静树窗口探测（`dotnet` 进程数按 `/proc/<pid>/comm` 扫描计，**不用 `pgrep -f`**）：第 20 次探测（间隔 5 s）拿到 `dotnet=0`，即在该窗口跑全量：

```
$ bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh      # 静树、dotnet=0
rc=1
计数：OK=63  MISMATCH=1（STALE=1  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0
APPSYNC=MISMATCH（MISMATCH=1[STALE=1 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0 —— 见上；本脚本**不改写任何目录**）
```

- 与 `#25` 的对照：`MISMATCH=1[STALE=1]`、`UNEXPECTED=1[DECL-GAP-EQ=1]`、`DIVERGENT=1`、`BRIDGE-ANCHOR=0`、`BRIDGE-NOINFO=0`、`rc=1` ⇒ **逐字一致**。
- **更强的证**：改前静树趟与改后静树趟的**整份输出逐字节相同** —— `static.before.log` 与 `static.quiet.log` 的 sha16 **同为 `33e759c22654fb6d`**（`diff` = 0 行）。⇒ 我对判定面的改动量 = **0**。

## §7 ⚠️ 新发现：`--selftest` 的**第二个假红源**（同族，派单书未登记）

**现场**：`SELFTEST_M` 那三条断言原来写成 `printf '%s' "$outM" | grep -q PAT`（`outM` = **全仓那趟的输出，36,260 B、多行**）。在 **`set -o pipefail`**（`:147`）下：`grep -q` 命中即退出 ⇒ `printf` 若还在**分块写**就吃 **`SIGPIPE`** ⇒ 整条管道非零 ⇒ **"串在、却判成不在"** ⇒ `SELFTEST_M=FAIL`（**假红**）。

**实测（`outM` 真实内容，各 400 次）**

| 形式 | `本校验器看不见的拷贝点` | `[写点]` | `不会被本校验器报出` |
|---|---|---|---|
| `printf '%s' "$X" \| grep -q PAT`（**原形**） | **假红 9/400** | **假红 7/400** | **假红 11/400** |
| `grep -q PAT <<<"$X"`（**改后**） | 0/400 | 0/400 | 0/400 |

⇒ 三条 `&&` 串起来：**每次 `--selftest` 有 ≈ 6.6% 的概率在 M 例上假红**。**本件现场撞到过 1 次**（`case5`：三串在、计数一致，却 `SELFTEST_M=FAIL`；随后同输入单跑即 `PASS`，见 `case5b`）。
**旁证（不是纯尺寸效应）**：合成多行 blob 的假红率 4 KB→2/300、8 KB→0/300、16 KB→2/300、32 KB→1/300 —— **结构相关**（分块写与 `grep -q` 提前退出的相对时序），所以**不能**只按"输出小就安全"来外推。

**本次处理（只改我这一对，其余登记待裁）**：

- **已改**：M 段 3 条 + **M2 段我自己新加的 4 条**（`$outM` 36 KB、`$expM2` 也是多行）→ 一律 `grep -q PAT <<<"$VAR"`。判据（要哪几条串）**一字未改**，只是不再有管道。
- **未改（如实登记，请主控裁定）**：全脚本仍有 **39 处 `| grep -q`**，其中**同形的 `printf '%s' "$VAR" | grep -q` 真站点 14 处**：`:568,574,575,584,593,639,655,656,681,682,730,753,754,755`（子例 A/B/C/D/F/G/I/L/N）。它们的 `$outX` 是**沙箱**那趟的输出（比 36 KB 小），**本次未逐点测**（**NOINFO**）⇒ 残余假红风险**未量化**；建议下一波按同一手法（`<<<`）**机械替换并逐点做"负例仍非零"的差分验证**。
- **不改的理由**：那 14 处在**既有 17 例（A…O）**的判据体内，派单书写明"**语义与阈值一字不许动**"；我这一趟已经动了 M/M2（本件写域所指），**不再扩大**。

## §8 我推翻／更正了哪句话（纪律 47）

1. **`D-G13` 的"结构上必然"只对一半**：派单书把假红**全部**归因于"M 的旧输出 vs M2 时刻新算的 `expM2`"这一条机制。实测存在**第二条、独立**的假红机制（§7 的 `SIGPIPE`），它**不需要仓库变动**、**每次运行都有 ≈6.6% 概率**、而且落在 **M 例**（不是 M2）。⇒ `--selftest` 的假红是**两个**来源，本件把**两个**都按"假红 ⇒ 不许冒充"的口径处理（M2 → `NOINFO`；M1 → 消除管道）。
2. **`--selftest` 的"改前基线 18/18"要带上条件**：18 例**数目与判据**确实是 18，但**改前的 18/18 不是每趟都能拿到**（M 例 ≈6.6% 假红；本件在并发读数时撞到 1 次）。⇒ 派单书"改前基线就是 18/18"这句话**作为单趟读数是对的、作为稳定性质是不对的**。
3. **`KNOWN-DEFECTS.md:1077` 的波尾纪律要加强**：那一段说"`--selftest` 必须在静树上跑"。静树**必要但不充分**——§7 的假红与静树无关（它只取决于本进程内的管道时序）。⇒ **必须同时**把我这两处 `<<<` 化推广到其余 14 处，否则静树上照样会假红。
4. **未推翻**：`D-G13` 关于 `SELFTEST_M2` 的机制描述（M 时刻 `outM` 一次性取数、M2 段 `:750-762` 要求旧输出含告诫、而"该不该有告诫"由 M2 时刻的 `expM2` 决定）**逐条属实**，我按它落地（并把它**加强**为"夹逼快照 + 两时刻比较"的可核形态）。

## §9 NOINFO / 未测清单（如实登记）

1. **未测**：14 处同形 `printf|grep -q` 站点的**逐点**假红率（只测了 M 段的三条与 M2 段的四条，及合成 blob 的曲线）⇒ 残余风险**未量化**。
2. **未测**：`SELFTEST_M2` 的 `NOINFO` 分支在**真件上**（当场有车道改写 `.sh`/`csproj` 时）自然出现——本次只在**沙箱副本**里确定性复现（真件上不制造写动作，纪律：不许让别人的树变脏）。
3. **NOINFO**：`snapPre != snapPost`（M 窗口内仓库变动）这一支**未被读数覆盖**（夹具只在 M2 那次改数）。机制与 `case2b` 同族，代码路径已写、未取数。
4. **NOINFO**：`参考快照算不出来`（`expM2` 空 / `snapX` 空）这一支**未取数**（要让 `applocal-expect.py` 真的坏掉才好取，会污染其他子例）。
5. **未取到**：`--selftest` 改前的 M1 假红**发生时刻**（`case5` 是"事后归因"：三串俱在 + 同输入单跑 `PASS` + 合成复现率 ≈6.6% ⇒ 归因成立，但**不是当场抓到**；如实标"归因为高置信度、非直接观测"）。
6. **未跑**：`dotnet`（零，硬约束）；`--apply`；`sync-applocal-authority.sh` 写模式；`verify-all.sh`／`close-wave.sh`（纪律 51：会自建/自跑探针）。

## §10 复现命令（全部只读、零 `dotnet`）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; SH=$R/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh
# ① 改前/改后 sha16
sha256sum "$SH" | cut -c1-16 ; sha256sum "$HOME/w26c-backups/check-applocal-sync.sh.before" | cut -c1-16
# ② 快照口径等价（一参数 vs 两参数，逐字节）
diff <(python3 "$R/build/DirectWrite.Linux/wic-shim/applocal-expect.py" "$R" "$R") \
     <(python3 "$R/build/DirectWrite.Linux/wic-shim/applocal-expect.py" "$R")   # ⇒ 空
# ③ 全量自检（静树上做：先确认 /proc/*/comm 里没有 dotnet）
bash "$SH" --selftest ; echo "rc=$?"        # ⇒ SELFTEST=PASS，18/18，rc=0
# ④ 静树全量（判定面）
bash "$SH" > "$HOME/w26c/static.quiet.log" 2>&1 ; echo "rc=$?"   # ⇒ APPSYNC=MISMATCH + 逐字计数，rc=1
diff "$HOME/w26c/static.before.log" "$HOME/w26c/static.quiet.log"   # ⇒ 空（逐字节相同）
# ⑤ 反极性（夹具在 $HOME/w26c/**；K = 夹具轨迹里那个 1 参数调用的序号：old=22 / new=24）
$HOME/w26c/run_case.sh repro-old         22 $HOME/w26c/case1.old.race.log     # FAIL rc=1
$HOME/w26c/run_case.sh repro-new         24 $HOME/w26c/case2b.new.race.log    # NOINFO rc=3
$HOME/w26c/run_case.sh repro-newbrokenA   0 $HOME/w26c/case3b.new.brokenA.log # FAIL rc=1
$HOME/w26c/run_case.sh repro-newbrokenB   0 $HOME/w26c/case5c.new.brokenB.log # FAIL rc=1（新牙）
$HOME/w26c/run_case.sh repro-newM1broken  0 $HOME/w26c/case7.newM1broken.log  # SELFTEST_M=FAIL rc=1
```

**产物清单（`$HOME/w26c/**`，全部 sha16）**：`w26c.diff` `e0ee74d44a258805`｜`flipwrap.py` `5112f4d95a8053f2`｜`run_case.sh` `02a1f7bd2d9a02a4`｜`selftest.before.log` `d42dc0f8334d4f95`｜`selftest.v2.log` `34d80971f9403a55`｜`static.before.log` = `static.quiet.log` = `33e759c22654fb6d`｜`case1.old.race.log` `46674cb45836c172`｜`case2b.new.race.log` `acee16aa505f4517`｜`case3b.new.brokenA.log` `796508ef6313c2e4`｜`case4.old.brokenA.log` `b1963bedb3a66488`｜`case5c.new.brokenB.log` `ac91c13136cdde49`｜`case6.old.brokenB.log` `57c76545b3311337`｜`case7.newM1broken.log` `20ec6a483f2c2ea9`。
**副本夹具 sha16**：`repro-old`（= 改前原件）`7bc9364091a28fd4`｜`repro-new`（= 改后成品）`27ecae1580a07527`｜`repro-newbrokenA` `c146663eb67eb86c`｜`repro-newbrokenB` `c2c7b6b2695f6f31`｜`repro-newM1broken` `edef9bdf88571f81`｜`repro-oldbrokenA` `8d126dc5fd840c23`｜`repro-oldbrokenB` `df67010f3eb89b96`。

**写域自证（NOINFO 声明）**：本机**没有 `git`**（`bash: git: 未找到命令`）⇒ 拿不到"只有我改了这两份"的**机器证**。写域声明因此是**构造性**的：本趟在仓内只写过两个路径 —— 编辑 `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`、新建 `build/MilBridge/W26C-report.md`；**其余一切产物都在 `$HOME/w26c/**` 与 `/tmp`**（夹具、日志、副本沙箱）。真桥两份副本与发布记录**零写操作**。
