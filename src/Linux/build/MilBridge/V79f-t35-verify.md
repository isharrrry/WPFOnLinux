# V79f — `t35` 独立复验：`t34`（模板牙收窄 ＋ 生产路径接线 ＋ 注释更正）＋ `t33`（记录更正）

**判词：`pass`**（五条验收全过）。本件**只读真树**；四条反极性腿全在 `~/w35a` 的**夹具副本**上跑，真树零写入；
本件在仓内的唯一写入 ＝ 本文件。**不复述任何人的读数** —— 下面每一格都是我自己的命令 ＋ 我自己的读时刻。

**我的现取时刻**：`2026-09-28T01:58:50 … 02:01:27+08:00`（逐格标注）。
**资源现取**（`01:58:50`）：`df_avail_kB=91686692`（≈87 GB）｜`mem_avail_MB=5431`｜全程零 `dotnet`、零 Xvfb、零进程收杀（未枚举、未收）。

---

## 0. 承重件指纹（我的读时刻 `01:58:57 / 01:59:58 / 02:00:03`）

| 件 | sha16 | 尺寸 | mtime | 与 `HEAD`／父提交的关系 |
|---|---|---|---|---|
| `build/close-wave.sh` | **`04b12127a4297434`** | 61,921 B | `2026-09-28 00:49:57` | `== HEAD`；`6a245bd^:` = `06d52a92e2661d47`（**本波被改**） |
| `build/MilBridge/tools/wave-freeze-consistency-check.py` | **`e4393879eaca84f0`** | 56,563 B | `2026-09-28 00:51:20` | `== HEAD`；`6a245bd^:` = `f038a9b9655bc5ad`（**本波被改**） |
| `build/MilBridge/tools/column-floor-check.sh` | **`e997d316515e4128`** | 65,548 B | `2026-09-25 22:19:36` | `== HEAD == 6a245bd^:`；末次改动 `97a446e`（`09-26 00:22`） |
| `build/MilBridge/tools/arm-log-sha-check.sh` | **`d6045edbfc7b06fc`** | — | — | `== HEAD == 6a245bd^:`；末次改动 `a394a47`（`09-20`） |
| `~/w186a/w79/w79freeze/w79-record.txt`（canonical 模板） | **`52571ef51842467d`** | 27,021 B / 75 行 | `2026-09-27 12:21` | 仓外件 |
| `build/MilBridge/P0-w78-report.md` | **`bdf5644f4aa51300`** | 66,982 B / 439 行 | `2026-09-28 01:59:08` | `??`（未跟踪） |
| `~/w21-verify/w27-freeze.py`（`--template auto` 的解析源） | — | 147,341 B | `2026-09-28 01:12` | 仓外件 |

`HEAD = 6a245bd5042598cef56f12a467b05618299562ec`（**提交时刻 `2026-09-28 01:46:07`**，父 `993eb5d`）
⇒ **`t34` 的两处改动（`close-wave.sh` ＋ 牙）随这一提交入册**（`git log -1 --  <两件>` 均指向 `6a245bd`，且工作树与 `HEAD` blob **逐字节相同**）。
⚠️ **边界（`NOINFO`）**：本仓 `feat-Linux` **没有远程跟踪分支**（`git rev-parse @{u}` ⇒ `fatal: 上游分支 … 没有存储为一个远程跟踪分支`）⇒ 「已推送」这一格我**不判**（不属本件验收）。

---

## ① 生产路径上**真判** —— 现取证明

**（a）接线行现取**（`01:58:57`）：
```
$ grep -n 'wave-freeze-consistency-check' build/close-wave.sh
382:build/MilBridge/tools/wave-freeze-consistency-check.py \        ← fp_inputs 清单行
657:run "[5c/6] wave-freeze-consistency-check.py" python3 … --root "$ROOT" --template auto
```
⇒ **带 `--template auto`**。主控给的 `close-wave.sh:654 ← 无 --template` **两处都过期**（行号 `654→657`，因为 `t34` 在其上追加了 3 行注释；内容也从"无"变成"有"）。

**（b）该行**在脚本里**无条件可达**：`if [ "$SKIP_VERIFY" = 1 ]` 起于 `:621`、**`:625` 就 `fi`**（`--skip-verify-all` 只包 `:622/:624` 的 `[5/6]`）⇒ `[5b/6]`（`:648`）与 `[5c/6]`（`:657`）**不在任何分支里**。`bash -n build/close-wave.sh` ⇒ `syntax_rc=0`。

**（c）我按该行**逐字形态**真跑**（仓根、只读，`01:59:24`）：
```
$ python3 build/MilBridge/tools/wave-freeze-consistency-check.py --root "$PWD" --template auto
WFREEZE_TEMPLATE_AUTO src=freezer-GENS path=/home/links-dev/w186a/w79/w79freeze/w79-record.txt
WFREEZE_TEMPLATE=PASS path=…/w79-record.txt hits=0 notes=9
WFREEZE_BLOCKVALUES=PASS gen=#79 keys=9 declared_shifts=0 bad=0 noinfo=0 cfg=Release
WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS blockvalues=PASS
rc=0   stderr_bytes=0   skipped(no-template-given) 命中 = 0
```
`auto` 解析到的**就是** canonical（`52571ef51842467d`）⇒ 接线没有走形。

**（d）「该判词在总体状态里」—— 口径更正（我推翻半句）**：模板面**不以具名格**出现在 `WFREEZE_CONSISTENCY=` 行里（该行只有 `rootdefault/decl/nineauth/blockvalues` 四格）；它是**折进 `blockvalues=`** 再进总体的。两条我自造的腿把这个耦合**证死**：
- 模板 `FAIL`（腿②）⇒ `WFREEZE_BLOCKVALUES=FAIL bad=1` ⇒ **总体 `FAIL`**、`rc=1`；
- 模板**缺席**（`--template /nonexistent/…`）⇒ `WFREEZE_TEMPLATE=NOINFO reason=template-absent` ⇒ `blockvalues=NOINFO noinfo=1` ⇒ **总体 `NOINFO`**、**`rc=3`**（**不是 0**）；
- `auto` 取不到（`--freezer /nonexistent/…`）⇒ `WFREEZE_TEMPLATE=NOINFO reason=template-auto-undecidable` ⇒ 总体 `NOINFO`、`rc=3`。
⇒ 「缺模板不再是静默 PASS」**成立**；但请后代按"**折叠**"记，不要按"具名格"记。

---

## ② 四条两极化腿（形态**我自造**，夹具全在 `~/w35a`，真树零写入）

夹具 = canonical 的**行定位**副本（不是全文替换，避免 `t34` 报过的那种"换错位置"）：

| 腿 | 夹具 | 夹具 sha16 | 现取判词（`02:01` 前后） |
|---|---|---|---|
| ① canonical 本体 | `~/w186a/w79/w79freeze/w79-record.txt` | `52571ef51842467d` | `WFREEZE_TEMPLATE=PASS … hits=0 notes=9`、`WFREEZE_CONSISTENCY=PASS`、**rc=0** |
| ② 九位行塞回裸 hex | `~/w35a/tpl-nineliteral.txt`（`:67` 的 `{PRV}` → `609192a419d125f2`） | `8b6994b94e489613` | `WFREEZE_TEMPLATE_HIT kind=nine line=67` ＋ `WFREEZE_TEMPLATE=FAIL hits=1 notes=9` ＋ **总体 `FAIL`**、**rc=1** |
| ③ `inputs_fp` 行塞回裸 hex | `~/w35a/tpl-infp-literal.txt`（`:70` 的 `{INFP}` → `4c096e9c0705a95d`） | `375cb9b1817c3222` | `WFREEZE_TEMPLATE_HIT kind=inputs_fp line=70 text=…4c096e9c0705a95d…` ＋ `FAIL hits=1 notes=9` ＋ **总体 `FAIL`**、**rc=1** |
| ④ 篡改一条 `ARM-LOG-SHA` | `~/w35a/tpl-armlog-tamper.txt`（`:62` 的 `1c43a12dcaa5718a` → `…8b`） | `72cb88638964b4be` | **`WFREEZE_TEMPLATE=PASS hits=0 notes=9`**、**rc=0**、总体 `PASS`；**只出** `WFREEZE_TEMPLATE_NOTE kind=other line=62 text=# ARM-LOG-SHA arm=tab-anchor sha16=1c43a12dcaa5718b` |

腿④ 的**分界证**：`diff`(canonical 输出, 腿④ 输出) **只差两处** —— 一行 `WFREEZE_TEMPLATE_AUTO`（腿A 有、腿④ 无）与 `:62` 那个**被篡改的末位 nibble**（`…8a`→`…8b`）⇒ 篡改**看得见、但只列不判**，与 `t34` 的说法一致。**真树未被任何腿碰过**。

**附加边界（两条，`t33` 表格的独立复现）**：按"全局替换"重建两份副本 ⇒ 我自算的**行/值两口径**与 `t33` 的表**逐格吻合**：
```
L2  ({PRV} → 裸 hex, 全局) sha16=12fbda5d5fc6c422  census 行=11 值=15  命中行=[15,16,17,61,62,63,64,65,66,67,68]
L2b ({WIC} → 裸 hex, 全局) sha16=75dd938afdbc9d14  census 行=11 值=15  命中行=[…同上…]
（新牙对这两份：hits=1 notes=10 —— 只判 `:67`；`:68` 属"其余行"⇒ NOTE）
```

---

## ③ 邻牙没被打断 ＋ 抽取代码**逐字节未改**

我自己的实跑（`01:59:58`）：
```
bash build/MilBridge/tools/arm-log-sha-check.sh      ⇒ rc=0 stderr=0
  ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
  ARMLOG_ARM=tab-anchor PASS decl=1c43a12dcaa5718a live=1c43a12dcaa5718a nlink=1 （五臂同形）
bash build/MilBridge/tools/column-floor-check.sh     ⇒ rc=0 stderr=0
  COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
  COLUMN_FLOOR_CORPUS=PASS file=…/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
  COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 reg=2209966ee1d2c5cc base=901619543b3d913b corpus=0cebc0afd5142fbf
```
**"逐字节未改"的证据（三重）**：`column-floor-check.sh` 的 sha16 **`e997d316515e4128` ＝ `git show HEAD:`＝ `git show 6a245bd^:`（＝`t34` 之前的提交）**，且末次改动是 `97a446e`（`09-26 00:22`）、`mtime` 停在 `09-25 22:19` ⇒ **本波（含 `t34`）没碰过它**（`arm-log-sha-check.sh` 同法：`d6045edbfc7b06fc` 三方相同，末改 `a394a47` `09-20`）。
邻牙面**比我被要求的还要宽一层**：`ARMLOG_SHA` 与 `COLUMN_FLOOR_ARMLOG` **各 5 臂逐条 `decl==live`**，`COLUMN_FLOOR` 三格 `pass=3 fail=0`。

牙自身判据**没被放宽**（我自己跑它的 `--selftest`，`02:00:36`）：`WFREEZE_CONSISTENCY_SELFTEST=PASS cases=16 pass=16 fail=0`，`arm_lines=16`，其中 **`S9`（九位行塞裸 hex ⇒ FAIL 点名 `kind=nine`）** 与 **`S9b`（裸 hex 只在 `ARM-LOG-SHA` ⇒ PASS ＋ NOTE，`只列不判` 的边界臂）** 都在册 ⇒ 腿数 15→16、**无一条被删**。

---

## ④ `t33` 的记录更正（承重不变量成立；其"落仓 sha16"已过期）

**（a）前 377 行逐字节不变**（`02:00:03`）：
```
head -377 build/MilBridge/P0-w78-report.md | sha256sum | cut -c1-16   ⇒ 71b264bf4c827137   （＝ t25 交付态，逐字节已验）
head -377 … | wc -c                                                   ⇒ 54894
```
**（b）🔴 现件已被别人改写（如实入册）**：`t33` 报的落仓态 `7131ffad2ebac068 / 432 行 / 64,963 B` 在我读时**已失效** ——
现读 **439 行 / 66,982 B / `bdf5644f4aa51300`**，`mtime = 2026-09-28 01:59:08`；件尾多出 `【dated 更正 · 2026-09-28T01:59:07+08:00（t36）】` 段（**正在我复验窗口内写入**）。⇒ 承重不变量（377 行前缀）**不受影响**，但**"报告现件 sha16"作承重判据的有效期极短**。

**（c）计数已改成 13 值/9 行 ＋ 两口径并列**：`§11.14`（现件 `:387`）逐字含「同一命令**现取** ⇒ **13 个值／9 行**」「被漏掉的是 **`:16` 行的 `f17c41239ffa1408`**」「逐值点名 … **2＋1＋4＋1＋5 = 13 值／9 行**」，并有**行数/值数两列表格**（`L1 9/13`、`L2 11/15`、`L2b 11/15`）＋ 一句「`hits=` 数的是"行"，不是"值"」。
**我独立复算同一命令**（`02:00:14`，canonical 模板）：
```
guarded(牙同款正则) 行的数=9  值的数=13     plain grep -ac / -aoE|wc -l 也是 9 / 13
逐行分解: :15=2  :16=1  :17=4  :61=1  :62..:66 各 1   ⇒ 2+1+4+1+5=13，9 行
```
⇒ `t33` 的更正**数字准确**，连"漏掉的是 `:16` 的 `f17c41239ffa1408`"也**独点吻合**。
**位置更正也对**：我现取件里 `§11.4` 在 `:271`、被更正的原句在 `:362`（属 `§11.11`，节头 `:354`）⇒ 「不在 §11.4」成立。

**（d）三条口径句逐字在位**（`02:00:36`，`grep` 命中行）：
- `:405` 「**消息乱序**：**「主控消息乱序时，取'与盘上现态一致'的那一条；并点名哪一条被 supersede」**」（实例：`17ca2241446d3000` 被 `52571ef51842467d` supersede，权威态 `b3115b9680b0039f`）
- `:407` 「**链在跑期间不写仓内件**：**「起链 → 冻后两趟跑完，任何人不写任何仓内件（含 `.md` 报告）」**」（实例：`t25` 那笔落仓 `13:32:12` 落在 `13:30:44` 起的窗口内、无损害是运气；`t33 deps=[t23]` 即产物）
- `:410` 「**"纯追加"两条腿**：**「'纯追加'必须两条腿一起验：**前缀逐字节相同 ∧ 每个新增单元恰出现 1 次**」**」＋ 同节 `:412` 教训逐字「**只验前缀的守卫，其射程小于"纯追加"这个性质本身**」、`§11.15` 标题下亦含「**守卫的射程必须与被保证的性质对齐**」（我 `grep` 到 2 处同句：`:410` 与教训行）。

---

## ⑤ 我**推翻／更正**了哪些话（承重，逐条）

1. **主控给的 `close-wave.sh:654 ← 无 --template`**：两处都过期 ⇒ 现读 **`:657`，且带 `--template auto`**，并已随 `6a245bd`（`01:46:07`）入 `HEAD`。
2. **主控的「该判词在总体状态里」**：表述不准 —— 总体行**没有**模板具名格，是**折进 `blockvalues=`**；耦合本身**为真**（FAIL⇒总体 FAIL rc=1／NOINFO⇒总体 NOINFO rc=3）。**判据不许按"具名格"复述**。
3. **`t33` 的落仓读数 `7131ffad2ebac068 / 432 行`**：我读时已被 `t36`（`01:59:07`）追加改写 ⇒ **`bdf5644f4aa51300 / 439 行 / 66,982 B`**；其承重不变量（`head -377 = 71b264bf4c827137`）**仍成立**。
4. **未被推翻的**：`t34` 的 `:657` 行号、`--template auto` 的解析源＝冻结器 `GENS`、`--selftest 16/16`（含 `S9b`）、canonical `PASS hits=0 notes=9`；`t33` 的 `13 值/9 行`、`L2/L2b = 11 行/15 值`、三句口径、位置更正 —— 我全部**独立复现**。

## ⑥ 边界 / 观察（**不构成 `needs_revision`**，如实划界）

- **O1（`D-G136` 家族陈旧一处，低危）**：`build/close-wave.sh:653` 的 `say` 仍写「**[5c/6] 冻结期一致性（三档：ROOTDEFAULT／DECL／NINEAUTH）**」，而现读实为**四档**（`+ blockvalues`，模板面即折在其中）。只是标签文本，不影响判词；建议随下次同趟改成四档。
- **O2（收窄后的残余边界，低危）**：把字面量写进**第 68 行**（`{PREV}` 箭头散文行，`… ``{PRV_PREV}`` → ``{PRV}`` …`）⇒ 我自造夹具 `~/w35a/tpl-line68prev-literal.txt`（`c044256297e354a1`）得 **`WFREEZE_TEMPLATE=PASS hits=0 notes=10`、总体 `PASS`、rc=0**。即：该行"只列不判"，而它**没有** `ARM-LOG-SHA`／`COLUMN-CORPUS` 那样的活牙；这是 `t34` **明文声明**的边界（不是隐匿）。`t26 F1` 的目标（接线 ＋ 可满足 ＋ canonical 不再误红）**不受影响**。
- **O3**：本件在我复验窗口内被并行改写（见 ④b）⇒ 报告类件的 sha16 不宜作长期承重。
- **O4（我的口径边界）**：`REPORTID` 现读数本件**之前**即为 `FAIL`（语料 `build/MilBridge/*report*.md`，点名 `P0-w79-report.md:43/:51` 的 `D-G170/D-G171/D-G172`）；本件文件名**不含 `report`** ⇒ **不进该语料**，我不新增红（落仓后复跑见文末）。

## ⑦ 落仓与自指

本件 `build/MilBridge/V79f-t35-verify.md`（仓内唯一写入；`temp+rename`，`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
