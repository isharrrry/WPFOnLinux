# W26D 报告 —— `D-G9` 前半落地：`generation.arm_logs`（结构化）+ 只读核对器

> lane=**W26D** ｜ 2026-09-17 14:00:26 → 14:0x +0800 ｜ kernel `6.8.0-138-generic` ｜ `nproc=3`
> `loadavg` 4.45 3.07 1.63（14:05:15 采样；另见 §10）｜ `MemAvailable` 2987 MB ｜ `SwapFree` 486 MB
> **零 `dotnet`**（本件一个都没跑；**会自行构建的脚本**也一个没跑：`frame-step.sh` / `verify-all.sh` / `pc-line-step.sh` 全未执行；
> `tline-gate.sh` **只在 `$HOME` 沙箱树上跑**，真仓上一次都没跑）｜ 未 `pkill` ｜ 未用 `pgrep -f`/`ps|grep` 下任何结论
> 引注纪律：凡行号**现场读过且带文件名**；凡 sha **现场 `sha256sum` 算**（纪律 49）。

---

## 0. 一句话结论（结论在前）

**已落地，读数正确，且"这颗牙真的会红"已用三种方式证出。**

1. **`generation.arm_logs` 已写入**（**flat** 形态：键 = 臂日志文件名主干、值 = **sha256 全 64 位**），
   值 = **现场实测**：`tline 57d752a3981a9b91…`｜`tab-zero 424d4c6d5ab121cb…`｜`tab-rtl 5e4d9ef3c64f7d7e…`｜
   `tab-anchor 56abc845dbd29e93…`｜`textlineproto 4bceceeed570ba70…`。
2. **核对器 `build/MilBridge/tools/arm-log-sha-check.sh`（sha16 `d0547f94bb3806e6`）已交付**：
   三态、**缺声明 ⇒ `NOINFO`**、**`rc=0` 只在全 PASS**；`--selftest` = **`ALSC_SELFTEST=PASS cases=12 pass=12 fail=0`**，
   其中 **7 例断言"必须红"**（不是只证绿）。
3. **对今天真树的读数 = `ARMLOG_SHA=PASS … pass=5 fail=0 noinfo=0`，`rc=0`**（§5）；
   **落地前**同一脚本对真树给 `ARMLOG_SHA=NOINFO reason=arm_logs-absent`、`rc=1` ⇒ **不假绿**（§5.1）。
4. **"加未知键安全"自己重证了一遍**（不引述）：门禁只按 `GEN_KEYS` 取键、**未知键一律不读**、**全仓无 schema 校验器**；
   三棵只差登记表的沙箱树跑门禁 ⇒ **归一化后 `cmp` 逐字节相同、`TLINE_GATE=PASS`**（§2）。
5. **⚠️ 一条硬时序**：本波 **W26A 正在改 `CoverageProbe/Program.cs`（实测 mtime `14:04:17`）并会重取三支 `tab-*` 臂日志**
   ⇒ 本块那三个值届时必然陈旧、**核对器会正确地报 `FAIL`**（**预期行为，不是缺陷**）⇒ **波尾由主控重算并重注入**（§7）。

---

## 1. 写域清单 + 每个件的 before/after sha16

| 件 | before sha16 | after sha16 | 尺寸 | 说明 |
|---|---|---|---|---|
| `build/MilBridge/known-red.json` | **`e623d2b17d948e3b`** | **`5aead470c23a99ff`** | 32,602 → **35,310 B** | 唯一改动：`+arm_logs` 块、`+_FIELDTABLE` 2 行、`+changelog rev 11` |
| `build/MilBridge/tools/arm-log-sha-check.sh` | **不存在** | **`d0547f94bb3806e6`** | **17,559 B** | **新建**（本波唯一新件） |
| `$HOME/w26d-G9/inject-arm-logs.py` | — | （`$HOME` 脚手架，非仓内件） | 10,0xx B | 外科式注入器 + `--prove`/`--check` |
| `$HOME/w26d-backups/known-red.json.before` | — | `e623d2b17d948e3b` | 32,602 B | 波前全份备份（纪律 16） |

**全份备份**：`cp -p build/MilBridge/known-red.json $HOME/w26d-backups/known-red.json.before`（波前，sha16 `e623d2b17d948e3b` ✔ 与现场逐字相同）。

⚠️ **一处我自己的操作瑕疵，如实记录**：注入器默认在**登记表同目录**写备份，于是它先在仓内落了
`build/MilBridge/known-red.json.bak-20260917-140422`（32,602 B）。我**当场发现并把它移出仓外**
（`mv` 到 `$HOME/w26d-backups/`），事后 `find build/MilBridge -maxdepth 1 -name '*.bak-*' | wc -l` = **0**
⇒ **仓内零残留**。这属于"新件落到写域之外"，虽已清理，仍按纪律登记。

**我一个字都没碰的件**（写域外，逐一实测未变）：
`verify-all.sh`（W26B 的写域）｜`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（W26C）｜
`build/MilBridge/tests/CoverageProbe/Program.cs`（W26A）｜`build/MilBridge/arm-logs/**`（未 `ln`、未 `rm`、未 `cp`）｜
`build/MilBridge/run.sh`｜`build/MilBridge/tests/HbTextLineParity/Program.cs`｜`build/shims/**`｜`docs/**`｜`handoff.md`｜基线文件｜
`build/MilBridge/tools/tline-gate.sh`（sha16 实测 **`b37a5c9f55ae71a4`**，与 `#25` W25J 记录同值）。

---

## 2. 「加未知键的安全性」——**我自己再证一遍**（不引述 W25J）

### 2.1 门禁到底读哪些键（`build/MilBridge/tools/tline-gate.sh`，逐行现场读过）

**`generation` 的全部读取点**（`grep -n 'gen\.get\|gen\[' build/MilBridge/tools/tline-gate.sh` 的完整输出）：

| 行 | 原文（逐字） | 读哪个键 |
|---|---|---|
| `:227` | `    if not gen.get("instr_shim"):` | `instr_shim` |
| `:234` | `GEN_KEYS = ("instr_run_sh", "instr_program_cs", "instr_shim")` | **三项绑定** |
| `:235` | `gen_shas = {k: gen.get(k) for k in GEN_KEYS} if gen else {}` | 只按 `GEN_KEYS` 取 |
| `:237` | `tree_same_as_gen = bool(gen_shas) and all(gen_shas.get(k) and tree[k] == gen_shas[k] for k in GEN_KEYS)` | 只按 `GEN_KEYS` 比 |
| `:240` | `emit("登记表世代    = %s  %s" % (gen.get("id", "<无>"), gen.get("label", "")))` | `id` / `label`（**只印**） |
| `:244` | `emit("  gen 证据日志= %s" % gen.get("evidence_log", "<无>"))` | `evidence_log`（**只印**） |
| `:248-249` | `if gen.get("leg_resolution"):` → `emit("  腿核清      = %s" % gen["leg_resolution"].get("conclusion", "?"))` | `leg_resolution.conclusion`（**只印**，不入判定） |
| `:481`/`:486`/`:636`/`:654` | `gen.get("id")` / `gen.get("label")` | 只用于**措辞** |
| `:661` | `"generation": gen,` | **整块**转存进 `gate-readings.json` |

**`entries[*].caliber` 的读取点全脚本只有一处**：
```
:464  entry_gen_bad = [e.get("case_id", "?") for e in reg_entries
:465                   if any(e.get("caliber", {}).get(k) != gen_shas.get(k) for k in GEN_KEYS)]
```
⇒ **只遍历 `GEN_KEYS` 三项** ⇒ `generation` 多一个键**不可能**产生 `registry-generation-inconsistent`。

**⇒ 判定（机器可核）**：新增 `generation.arm_logs` **不在**任何读取点的键集合里 ⇒ **未知键一律不读**。

**全仓无 schema 校验器**（现场 grep，纪律 55 的正确写法）：
```
$ grep -rn --include='*.sh' --include='*.py' --include='*.ps1' -- 'tline-known-red' .
（0 命中）
$ grep -rn --include='*.sh' --include='*.py' --include='*.ps1' -- 'cross_check' .
（0 命中）      ← D-G9 的现场证据：那张散文表**没有任何机器读者**
```
另：`gate-readings.json` 的**唯一**出现处是写入者 `tline-gate.sh:659`，没有任何消费者
（`grep -rn --include='*.sh' -- 'gate-readings' .` ⇒ 只回 `:659`）⇒ 它变内容不会引起别处位移。
`changelog` 在门禁里被读 **0** 次（`grep -c changelog build/MilBridge/tools/tline-gate.sh` = `0`）。

### 2.2 机器证：三棵只差登记表的沙箱树，门禁两趟

**沙箱造法**（全部在 `$HOME/w26d-G9/`）：仓根骨架用**硬链接**（不是符号链接！原因见下），
登记表用**真拷贝**；三棵树的一切**同名件同 inode、同 mtime、同 sha**：

- `treeA` = 原登记表（`e623d2b17d948e3b`）
- `treeB` = 原登记表 **+ 只插 `arm_logs`**（sha16 `42d2f71c8c5e77c5`）⇒ 隔离"这一个键"
- `treeC` = 原登记表 **+ `arm_logs` + `_FIELDTABLE` 2 行 + `changelog rev 11`**（= **本件最终形态**）
- `build/MilBridge/arm-logs/*.log` 五支**硬链接**进每棵树（`README.md:3-6` 的约定：`-type f` 不认符号链接、`cp` 会顶 mtime）

⚠️ **第一版沙箱我踩了一个坑，如实记录**：我先用**符号链接**做骨架，结果门禁把四支弱配对臂全判
`STALE-WEAK`（`rc=2`、`TLINE_GATE=NOINFO`）—— 因为 `tline-gate.sh:142` 是
`MT_SHIM="$(stat -c %Y "$SH_SHIM" …)"`，而 **GNU `stat` 默认不解引用符号链接** ⇒ `mt_shim` 取到的是
**链接自身的创建时间**（14:01:34），于是"日志 mtime ≥ 世代被测件 mtime"这条判据被架空。
换成**硬链接**后 mtime 逐位相同（三棵树 `shim_mtime=1789575126`），门禁立刻回到 `PASS`。
**⇒ 这条值得进纪律**：给门禁造沙箱树时，**符号链接会篡改"被测件 mtime"**，必须硬链接或 `cp -p`。

**结果（三棵树各跑一趟，`--quiet`，`--outdir` 各自独立）**：

```
treeA rc=0  TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2
treeB rc=0  TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2
treeC rc=0  TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2
```

**归一化**（只把**沙箱路径**替换掉，**不动任何判据文本**）：
`sed -e 's|/home/links-dev/w26d-G9/tree[ABC]|TREE|g' -e 's|out-[ABC]|OUT|g'`

```
$ cmp gate-A.norm gate-B.norm   ⇒ IDENTICAL      （只差 arm_logs）
$ cmp gate-A.norm gate-C.norm   ⇒ IDENTICAL      （整份最终改动）
$ sha256sum gate-{A,B,C}.norm | cut -c1-16
f430e05124148cea  gate-A.norm
f430e05124148cea  gate-B.norm
f430e05124148cea  gate-C.norm
```

**未归一化的残差**（如实列全，一字不多）：
```
$ diff gate-A.txt gate-C.txt
12c12 …       日志 = …/treeA/…/tline.log   →   …/treeC/…/tline.log
18c18 …       （tab-zero）
23c23 …       （tab-anchor）
28c28 …       （tab-rtl）
33c33 …       （textlineproto）
71c71 TLINE_GATE=PASS … outdir=…/out-A     →   …/out-C
```
⇒ 残差 **6 行，全部是沙箱自身的路径**，**0 行判据**。输出里**没有** `loadavg` / 时间戳
（`grep -nE 'loadavg|[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}'` = 0 命中——`say()` 被 `--quiet` 关掉，判定段走 `emit()`）。

**两趟重复性**：`treeA` 再跑一趟（`out-A2`）⇒ 归一化后与第一趟 `cmp` **IDENTICAL**，sha16 同为 `f430e05124148cea`。

**沙箱 ≡ 真仓的额外证据**：`treeC` 的登记表 sha16 = **`5aead470c23a99ff`** —— 与**注入真仓之后**的
`build/MilBridge/known-red.json` sha16 **逐位相同** ⇒ 被门禁读的那份文本在沙箱与真仓里是**同一串字节**，
不是"我另外仿了一份"。其余件是**同 inode 硬链接**（`sha256sum` 与 `stat -c %Y` 都逐位相同）⇒
**沙箱与真仓的唯一差别 = 目录前缀**。

**机读读数 `gate-readings.json` 的 A→C 差异（逐路径机器比）**：
```
added paths (5):   /generation/arm_logs/{tline,tab-zero,tab-rtl,tab-anchor,textlineproto}
removed paths (0)
changed paths (5): /arms/{tline,tab-oracle-zero,tab-oracle-rtl,tab-oracle-anchor,textlineproto}/log   ← 沙箱路径
```
⇒ **判据字段（`verdict`/`reason`/`noinfo_arms`/`registered`/`unregistered`/`arm_caliber`/`entry_generation_inconsistent`）零差异**；
新增的 5 条路径**全部**落在 `/generation/arm_logs/` 之下，正是我加的那一个块。

**结论：加 `arm_logs` 不触发 `registry-generation-inconsistent`，门禁判定逐字节不变。proven。**

---

## 3. 字段落地（外科式插入，**不是** `json.dump`）

### 3.1 形态选择与依据（**我改掉了 W25J 草稿的嵌套式，如实说明**）

- `docs/WAVE26-PREREGISTRATION.md:49`：**「字段 = `generation.arm_logs`（键 = 文件名主干、**值 = 64 位全值**）」**
- `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:1050`（`D-G9` 修法原文）：**「如 `arm_logs: {tline:…, tab-zero:…, …}`」**
- `~/w25j/arm-log-registry.md`（草稿）用的是嵌套式 `arm_logs{logdir,suffix,sha256{…},taken_at,why,how,not_covered}`

两处**权威文本**（预登记 §4 + 缺陷登记本身）都写的是 **flat** ⇒ 我落 **flat**（更少假设、判据面就是那 5 对），
**但核对器同时认嵌套式**（`shape=flat|nested` 会印出来，不静默）⇒ **波尾无论用注入器还是 W25J 的 `apply.py`，判据都成立**。
嵌套式里的 `logdir` 元数据我也支持（`flat` 下同样认 `logdir`）⇒ `--selftest` **case I** 就是拿嵌套形态证 `PASS`。

### 3.2 实际写入的 JSON（**现场回读打印**，值 = 现场 `sha256sum`）

```json
    "arm_logs": {
      "tline": "57d752a3981a9b91f44ecbd92a8adf988b1eb501ba05530a05b137a8fc13b11a",
      "tab-zero": "424d4c6d5ab121cbf43b915964d62eed54181e4362910f0093bbc991b5237bba",
      "tab-rtl": "5e4d9ef3c64f7d7ea8db1dc5fb1bbb41a0a7cae51021b9dd20284d20306bfbf0",
      "tab-anchor": "56abc845dbd29e93016ffe6e43540aa2146abb4eec6492a6b505934e9a87f647",
      "textlineproto": "4bceceeed570ba70eb0e2014352b2505d3648c1edabb4b8ebe859f6cb227ce09"
    },
```
落点 = `generation` 块内、`"leg_resolution": {` **之前**（`known-red.json:46-52`），缩进 4/6 空格（与 `generation` 现有排版一致）。

**为什么值必须是 64 位全值**（口径出处 = `build/MilBridge/tests/ShimShaReader/Program.cs:12` 的原文）：
> `**完整 sha256 逐字相等**才算 no（不许只比 16 位前缀：前缀相等不是内容相等）。`

**顺带交叉核对（信息性，不参与判定）**：同表旧字段 `generation.evidence_log_sha256` 存的确实是
`tline.log` 的 **16 位前缀**（实测长度 **16**，值为 `57d752a3981a9b91`），与 `arm_logs.tline` 的
**前 16 位逐字相同**（`startswith` = `True`）⇒ 新旧两处**不矛盾**，但**位宽不同**：新块是全值、旧字段是前缀。
**我没有改旧字段**（它是 `#23` 的历史记录）。

### 3.3 外科式插入的机器证

**三个锚点，插入前现场计数**（`--prove`）：
```
锚点计数  A1(^    "leg_resolution": {)=1   A2(_FIELDTABLE 的 leg_resolution 行)=1   A3(^  "changelog": [)=1
```
⇒ 三者**各唯一**；注入器在 `!=1` 时**拒绝动手术**（`reason=anchor-not-unique`）。

**改动规模（`diff` 计数，非 `json.dump`）**：
```
$ diff known-red.json.before known-red.json | grep -c '^<'   ⇒ 0
$ diff known-red.json.before known-red.json | grep -c '^>'   ⇒ 16
```
⇒ **删除行 = 0，新增行 = 16**（`arm_logs` 7 行 + `_FIELDTABLE` 2 行 + `changelog` 1 条 7 行）。**纯插入。**

**写后回读校验（`json.load` + 逐项断言，全过）**：
```
schema 未变: tline-known-red/4          顶层键顺序未变: True
GEN_KEY instr_run_sh      unchanged=True  3e513e88a4fa4ec9
GEN_KEY instr_program_cs  unchanged=True  2e458928fc1577c2
GEN_KEY instr_shim        unchanged=True  e89fed55fd8e32bc      ← 硬约束 4：三项一个字未动
instr_pc unchanged: True | evidence_log_sha256 unchanged: True
leg_resolution 逐字节未变: True          note 未变: True   pending 未变: True
entries: 4 == 4  逐条 identical: True
changelog: 10 → 11   [0].rev="11" by=W26D   changelog[1:] == 旧的整份: True
_FIELDTABLE: 30 → 32
generation 子字段: 14 → 15，新增集合恰为 {'arm_logs'}，其余 14 个逐字节未变
arm_logs keys = ['tline','tab-zero','tab-rtl','tab-anchor','textlineproto']，五值均为 64 位小写 hex
```

**⚠️ 注入器的"回滚"机制被真实现场触发过一次（如实登记）**：第一次往 `treeC` 注入时
`_FIELDTABLE` 我漏了一个 JSON 逗号 ⇒ `post-write-verify:JSONDecodeError` ⇒
注入器**自动 `cp -p` 备份回滚**，`treeC` 的登记表回到原 sha `e623d2b17d948e3b`。
修好后重注入通过。⇒ **"写坏了不会留下读不出的登记表"这条不是设计声明，是实测过的。**

**为什么补 `_FIELDTABLE` 与 `changelog`**：`_FIELDTABLE:2` 自述"纯人读、门禁不读"，
但它是**该表自己的字段注释**；不补 ⇒ 新字段变成"读者不知其义"（正是 `D-G9` 同族病）。
`changelog` 是本工程惯例（`known-red.json:23`「每次重钉必须新增一条，并写清旧表错在哪」）。
两者门禁均读 0 次（§2.1）⇒ **零判定风险**。

---

## 4. 核对器 `build/MilBridge/tools/arm-log-sha-check.sh`（sha16 `d0547f94bb3806e6`，17,559 B）

### 4.1 判据（三态）

| 情形 | 判定 | `rc` |
|---|---|---|
| 五臂声明值 == 现场 `<logdir>/<键>.log` 的 sha256 **全 64 位** | `ARMLOG_SHA=PASS` | **0** |
| 声明值 ≠ 现场值（逐字、全 64 位） | `FAIL`（`reason=sha-mismatch`） | 1 |
| 声明的臂**日志文件不存在** | `FAIL`（`reason=log-missing`）—— **声明指向不存在的件 = 假声明**，不是"无信息" | 1 |
| 声明值不是 64 位小写 hex | `FAIL`（`reason=decl-not-64hex`） | 1 |
| 元数据键出现**非字符串**值 | `FAIL`（`reason=decl-non-string-value`） | 1 |
| **整个 `arm_logs` 缺声明** | `NOINFO`（`reason=arm_logs-absent`） | 1 |
| **某支必需臂缺声明** | 该臂 `NOINFO`（`reason=undeclared-required`），汇总 `NOINFO` | 1 |
| 登记表缺件/JSON 坏 | `NOINFO` | 1 |
| 全部逐字相等 | `PASS` | **0** |

**`rc=0` 只在全 PASS**；`FAIL` 与 `NOINFO` 都 `rc=1`（"没声明"必须出声，不许静默绿）。

输出示例（真树）：
```
ARMLOG_ARM=tline PASS decl=57d752a3981a9b91 live=57d752a3981a9b91 nlink=6
…
ARMLOG_SHA=PASS shape=flat logdir=…/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
```

**必需臂集合** = 门禁认臂集合（`tline-gate.sh:91` 的 `ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)`）；
**键 = 文件名主干**，映射取自 `build/MilBridge/arm-logs/README.md:14-18` 的表。

### 4.2 逐条说明我抄了 `baseline-sha-check.sh`（sha16 **`5836b8296b2e4245`**，137 行）的哪些设计

| 抄自它的行 | 抄的是什么 | 在本脚本的落点 |
|---|---|---|
| `:19` | `set -uo pipefail` | 同名同写法 |
| `:21-22` | `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` + `R="$(cd "$HERE/../../.." && pwd)"`（**脚本位置反推仓根**，不靠 `$PWD`） | 逐字照抄（`tline-gate.sh:84-123` 正是这个坑的受害者） |
| `:23-24` | `BASE="${BSC_BASE:-…}"` / `STATE="${BSC_STATE:-…}"` ⇒ **沙箱覆盖环境变量** | `REG="${ALSC_REG:-…}"` / `LOGDIR="${ALSC_LOGDIR:-…}"`（`--selftest` 靠它） |
| `:27` | `run_check() { … }` 一个函数承担全部判定，**正常跑与 `--selftest` 共用它** | `run_check()` 同构 |
| `:29` | 进函数先把三态变量**置为 NOINFO**（默认不绿） | `ARMLOG_SHA=NOINFO` 首行 |
| `:30-31` | 缺件 ⇒ `echo 'BASELINESHA=NOINFO reason=baseline-missing'; return 1` | `reason=registry-missing` / `reason=log-missing` |
| `:44-51` | 抽不出值 ⇒ `NOINFO`；抽出且相等 ⇒ `PASS`；抽出但不等 ⇒ `FAIL`（**三态写法**） | 同构 |
| `:79-80` | 「全 PASS 才 `return 0`，否则 `return 1`」 | 同构（`nfail -eq 0 && nnoinfo -eq 0 && npass -gt 0`） |
| `:83-135` | `--selftest`：`mktemp -d` + `trap 'rm -rf "$T"' EXIT`、`mk()` 造沙箱、`chk()` 逐例印 `SELFTEST case=… expect=… got=… rc=… => yes/no`、末尾 `SELFTEST=… cases= pass= fail=`、**有 fail 即 `rc=1`** | 同构（`mklogs()`/`chk()`/`ALSC_SELFTEST=`） |
| `:99-101` 的**教训** | 「声明缺失时会印出**两行**同名汇总行 ⇒ 抽取必须 `head -1`；本脚本自测 case C 抓到过」 | **我用不同前缀根治**：逐臂行 = `ARMLOG_ARM=`、汇总行 = `ARMLOG_SHA=`，全脚本**只印一行** `ARMLOG_SHA=` ⇒ 抽取天然无歧义（比 `head -1` 更硬） |
| `:113-119` 的**教训** | 「扰动值必须仍是**合法位宽**，否则只证出 NOINFO、没证出 FAIL」 | selftest case B 用"换首位字符"（保持 64 位）；**另加** case D = **前 16 位 + 48 个 0** |

**有意差异（如实披露）**：
1. **值口径更严**：本脚本比 **64 位全值**，对方比文档里的 **16 位** `sha16=`。依据 = `ShimShaReader/Program.cs:12`。
2. **声明载体是 JSON** 而不是文档散文行 ⇒ 用 `python3` 取键（同一份 JSON，门禁 `tline-gate.sh:208-215` 也是 `python3` 在读，同族做法）。
3. **逐臂行印 `nlink=`：信息性，不参与判定**。为什么不当判据：`README.md:3-6` 要求硬链接，但**源件**（如 `$HOME/wfp-runs/**`）被清理时 nlink 会自然掉到 1、**而日志本身没变** ⇒ 拿它当判据会产生**假红**（本工程铁律：假红也是缺陷）。同族惯例 = 登记表里 `instr_pc` 的"信息性，不参与口径判定"。

### 4.3 `--selftest` = **12/12**，其中 **7 例断言"必须红"**

```
SELFTEST case=A expect=PASS   got=PASS   rc=0 => yes      干净：五臂声明==现场
SELFTEST case=B expect=FAIL   got=FAIL   rc=1 => yes      扰动一位（仍合法 64 位）
SELFTEST case=C expect=NOINFO got=NOINFO rc=1 => yes      整个 arm_logs 不在
SELFTEST case=D expect=FAIL   got=FAIL   rc=1 => yes      **前 16 位 + 48 个 0**
SELFTEST case=E expect=FAIL   got=FAIL   rc=1 => yes      声明的臂日志文件不存在
SELFTEST case=F expect=NOINFO got=NOINFO rc=1 => yes      只声明 4/5（缺 tline）
SELFTEST case=G expect=FAIL   got=FAIL   rc=1 => yes      声明值只有 16 位
SELFTEST case=H expect=FAIL   got=FAIL   rc=1 => yes      **D-G9 现场形态：声明不动、日志被换掉**
SELFTEST case=I expect=PASS   got=PASS   rc=0 => yes      嵌套形态 arm_logs.sha256{} 也认
SELFTEST case=J expect=NOINFO got=NOINFO rc=1 => yes      登记表不存在
SELFTEST case=K expect=FAIL   got=FAIL   rc=1 => yes      flat 里混进非字符串值的键
SELFTEST case=L expect=FAIL   got=FAIL   rc=1 => yes      声明里的 logdir 覆盖生效
ALSC_SELFTEST=PASS cases=12 pass=12 fail=0
```

**case D 是"防 16 位退化"的那颗牙，把它的输出逐字抄在这里**（最能说明问题的一行）：
```
ARMLOG_ARM=tab-rtl FAIL reason=sha-mismatch decl=65ad8a315df0893f live=65ad8a315df0893f nlink=1
```
⇒ **`decl` 与 `live` 的 16 位前缀逐字相同，而判定是 `FAIL`** ⇒ 判据面确实是 64 位全值。

`chk()` 还额外扣住"不许静默绿"：断言 `PASS` 时**要求 `rc=0`**，断言 `FAIL`/`NOINFO` 时**要求 `rc≠0`**（`[ "$rc" -ne 0 ] || ok='no'`）。
⇒ **三态与退出码是绑在一起被检验的**，不是只看字符串。

**`--selftest` 沙箱只写 `mktemp -d`**（`/tmp/tmp.XXXXXX`），**仓内零写入**（`trap rm -rf` 收尾）。

---

## 5. 对今天真树的读数

### 5.1 落地**前**（先证"不假绿"）

```
$ bash build/MilBridge/tools/arm-log-sha-check.sh
ARMLOG_SHA=NOINFO reason=arm_logs-absent reg=…/build/MilBridge/known-red.json
rc=1
```
⇒ **字段没落地之前它不会假绿。**

### 5.2 落地**后**（本件的正式读数）

```
$ bash build/MilBridge/tools/arm-log-sha-check.sh          # rc=0
ARMLOG_ARM=tline         PASS decl=57d752a3981a9b91 live=57d752a3981a9b91 nlink=6
ARMLOG_ARM=tab-zero      PASS decl=424d4c6d5ab121cb live=424d4c6d5ab121cb nlink=6
ARMLOG_ARM=tab-rtl       PASS decl=5e4d9ef3c64f7d7e live=5e4d9ef3c64f7d7e nlink=6
ARMLOG_ARM=tab-anchor    PASS decl=56abc845dbd29e93 live=56abc845dbd29e93 nlink=5
ARMLOG_ARM=textlineproto PASS decl=4bceceeed570ba70 live=4bceceeed570ba70 nlink=6
ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
```
**三态 = `PASS`，`rc=0`。** 五支全部逐字相符。

### 5.3 取值时刻（**这一节是给波尾用的，别删**）

| 项 | 值 |
|---|---|
| **写入时刻** | **2026-09-17 14:04:21–14:04:22 +0800** |
| 登记表 after | `5aead470c23a99ff4013b1c93074749d073d9a37625ca824d921ac0c5a588af1`（35,310 B，mtime `14:04:22`） |
| 五支现场 sha16（同一时刻实测） | `tline 57d752a3981a9b91`（mtime 00:36:36）｜`tab-zero 424d4c6d5ab121cb`（09:36:10）｜`tab-rtl 5e4d9ef3c64f7d7e`（09:37:43）｜`tab-anchor 56abc845dbd29e93`（09:37:34）｜`textlineproto 4bceceeed570ba70`（00:38:20） |
| 读数复取时刻 | `14:05:xx`，五支 sha **仍全同** ⇒ `PASS` 成立 |

**⚠️ 与 `#23` 的散文表的对照（`D-G9` 的现场形态，机器化）**：`generation.leg_resolution.cross_check`
（`known-red.json:53`）里写的是 `tab-zero b9d81590f3fcd800`、`tab-rtl 419e8aaa9c72a9a0`、
`tab-anchor … 1a5bc7181d0155c3`，而现场是 `424d4c6d…`／`5e4d9ef3…`／`56abc845…` ⇒ **3/3 逐字不符**。
我**没有改那条散文**（它是 `#23` 的历史记录）；**新块取代了它的数值权威性**，并在 `changelog rev 11` 里写明了这一点。

---

## 6. 反极性（"必须能证出红"）

§4.3 的 12 例自测是**沙箱**反极性（7 例断言红）。此外我还在**真登记表**上做了三趟，**全部只改 `$HOME` 里的副本、仓内零改动**：

| # | 形态 | 命令 | 读数 |
|---|---|---|---|
| **P1** | 声明值扰动一位（`56abc845…` → `16abc845…`） | `ALSC_REG=$HOME/w26d-G9/polar-reg.json bash build/MilBridge/tools/arm-log-sha-check.sh` | `ARMLOG_ARM=tab-anchor FAIL reason=sha-mismatch decl=16abc845dbd29e93 live=56abc845dbd29e93`；汇总 `ARMLOG_SHA=FAIL … pass=4 fail=1`；**`rc=1`** |
| **P2** | **"日志被换过"（`D-G9` 现场形态）**：真登记表 + 沙箱 logdir（五支硬链接自真件，**只把 `tab-anchor` 换成内容不同的副本**） | `ALSC_LOGDIR=$HOME/w26d-G9/polar-logs bash …` | `ARMLOG_ARM=tab-anchor FAIL reason=sha-mismatch decl=56abc845dbd29e93 live=820884716a011f1e`；`ARMLOG_SHA=FAIL … pass=4 fail=1`；**`rc=1`** |
| **P3** | 删声明（副本里 `del generation["arm_logs"]`） | `ALSC_REG=$HOME/w26d-G9/nodecl-reg.json bash …` | `ARMLOG_SHA=NOINFO reason=arm_logs-absent`；**`rc=1`** |
| **对照** | 复原（真登记表 + 真 logdir） | `bash build/MilBridge/tools/arm-log-sha-check.sh` | `ARMLOG_SHA=PASS … pass=5 fail=0`；**`rc=0`** |

⚠️ **我一次都没碰 `build/MilBridge/arm-logs/**`** —— P2 的"换过日志"是通过**沙箱 logdir** 模拟的
（`nlink=1` 那一行就是证据：只有落在沙箱里的那一支不是硬链接）。

**⇒ "该红的红"有三条互相独立的证据链：沙箱自测 7 例 + 真登记表 3 趟反极性 + 落地前的 `NOINFO` 不假绿。**

---

## 7. ⚠️ 硬时序（**必须转达主控**）

1. **本波 W26A 正在改 `build/MilBridge/tests/CoverageProbe/Program.cs`**（现场实测 mtime **`14:04:17`**，
   且 `CoverageProbe/obj|bin/Release` 一串产物 mtime 落在 `14:01:13–14:04:21` ⇒ 它**正在构建**），
   并会**重取三支 `tab-*` 臂日志**（`ln -f`）。
2. ⇒ 我写进 `arm_logs` 的 `tab-zero`/`tab-rtl`/`tab-anchor` 三个值**届时必然陈旧**，
   **核对器会立刻报 `ARMLOG_SHA=FAIL`（点名那三支）**。**那是它该有的行为，不是缺陷。**
   （`tline`/`textlineproto` 两支按预登记 §2 不重取 ⇒ 它们应保持 `PASS`。）
3. **我写值的确切时刻 = `2026-09-17 14:04:21 +0800`**；截至 **14:05:15** 五支现场的 sha 与 mtime
   **与写入时刻逐位相同** ⇒ §5.2 的 `PASS` 成立。**W26A 一旦 `ln -f`，`PASS` 立即变 `FAIL`。**
4. **波尾由主控重算并重注入**（本次的"应该红"正好是一次免费的现场演示）。重注入命令：
   ```bash
   python3 $HOME/w26d-G9/inject-arm-logs.py --prove       # 只看现场值，不写
   python3 $HOME/w26d-G9/inject-arm-logs.py               # 外科式重写（值现场算；幂等；回读校验；坏则回滚）
   bash build/MilBridge/tools/arm-log-sha-check.sh        # 期望 ARMLOG_SHA=PASS、rc=0
   ```
   （注入器目前住在 `$HOME`；若主控希望它进仓，`build/MilBridge/tools/` 是自然落点，但**那不在我的写域**，交主控决定。）
5. **备用路径**：若主控要用 W25J 的 `~/w25j/arm-log-registry-apply.py`（**嵌套式**），**不必改我的核对器** ——
   `--selftest case I` 已证嵌套形态给 `PASS`。

---

## 8. 接线（**不由我做**；预登记 §1 定的是主控波尾接）

**插入点（**按锚点给，不按行号** —— ⚠️ `verify-all.sh` 的**行号是移动目标**，见下）**：
在 `run_step "BASELINE-SHA" bash build/MilBridge/tools/baseline-sha-check.sh`（那一行**之后**）
与第一个 `echo "======================================================"`（**之前**）之间插三行：

```bash
echo
echo "[8] 臂日志 sha 核对（结构化登记 generation.arm_logs vs 现场硬链接件）"
run_step "ARM-LOG-SHA" bash build/MilBridge/tools/arm-log-sha-check.sh
```

**⚠️ 为什么必须按锚点给**：`verify-all.sh` 归 **W26B**，它**正在改**这个文件 —— 我读数期间它变了**两次**：
`14:05:15` 时 `[7]` 在 `:274`、`run_step "BASELINE-SHA"` 在 `:275`（sha16 `741b638acaf02e7a`）；
`14:06:41` 再读时 `[7]` 已到 `:302`、`run_step` 已到 `:303`（sha16 **`c3d988ca2cea7f20`**）。
⇒ **凡引 `verify-all.sh` 行号者，落地时必须现场重读**（纪律 4 的原话：引注前现场重读）。
不变量（两次读数都成立）：`grep -c '^run_step ' verify-all.sh` = **13**；`^echo "\["` 的最大编号 = **`[7]`**。

**步数 13 → 14**（现场实测：`grep -c '^run_step ' verify-all.sh` = **13**，与上面两次读数一致）。

**与 `run_step` 的相容性（现场读码确认，不是推断；行号取自 `verify-all.sh` sha16 `c3d988ca2cea7f20`）**：
- `verify-all.sh:71` `if [ $rc -eq 0 ] || [ $attempt -ge 3 ]; then break; fi` ⇒ 我的 `rc=0/1` 直接可用；
  `:72` 的重试只对 `MSB3021|MSB3027|being used by another process|The process cannot access the file` 触发，
  **我的输出里没有这些串** ⇒ 不会误重试。
- `verify-all.sh:112` 的失败诊断 grep 是 `grep -E "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)"` —
  **我的失败行 `ARMLOG_SHA=FAIL …` / `ARMLOG_SHA=NOINFO …` 命中 `[A-Z][A-Z0-9_]*=(FAIL|NOINFO)`** ⇒ 红的时候屏上能看见原因。
  ⚠️ 这一行**今天在 W26B 手里挪过位**：我 `14:05:15` 读它时在 **`:99`**，`14:06:41` 再读已在 **`:112`**（W26B 在它前面插了绿分支回显）。
  模式串本身**逐字未变** ⇒ **相容性结论不受行号漂移影响**。
- `verify-all.sh:83` 的绿分支还会找 `Total:|总计:`（我没有，走 `:85`/`:89` 的 `✅` 分支）——
  **W26B 正在补"绿分支回显结论行"**，那时 `ARMLOG_SHA=PASS …` 会自然上屏（我的口径行是自报的）。
- 我一律**不依赖** `run_step` 的绿分支格式：`PASS` 的完整口径在**我自己的 `ARMLOG_SHA=` 行**里。

**⛔ 我没有跑 `verify-all.sh`、没有跑真仓 `tline-gate.sh`**（前者会 `dotnet build`、后者归主控波尾）。

---

## 9. 位移复核

| 位/量 | 预期（预登记 §2） | 实测 | 结论 |
|---|---|---|---|
| 九位 | 全不动 | `shim e89fed55fd8e32bc`｜`run.sh 3e513e88a4fa4ec9`｜`Parity 2e458928fc1577c2`｜`pc 7374308a00c55572` 逐位未变 | ✅ |
| `inputs_fp` | 不动 | **机器证非覆盖**：按 `close-wave.sh:68-79` 的管道原样列出 110 个输入件，`grep -c 'known-red.json'` = **0**、`grep -c 'arm-log-sha-check'` = **0**；现场指纹 = `0b8b655965fbc5678c0cb0bb3a7739935cf98997f16289e16cfdf5f663eba2d8`（与 `#25` W25A 记录**逐位相同** ⇒ 覆盖面无位移） | ✅ |
| `generation` 三项（`GEN_KEYS`） | 不动 | 逐字节相同（§3.3 断言 + `leg_resolution` 未动） | ✅ |
| `entries` 4 条 | 不动 | 逐条 `identical: True` | ✅ |
| 三支 `tab-*` 臂日志 | **必变**（W26A 重取） | **我未触碰**；我写入的正是"重取前"的值 | 见 §7 |
| **表外位移** | — | **无**（改动面 = 登记表 16 行纯插入 + 1 个新建 `.sh`） | ✅ |

**顺带（不是我的位移，供主控记账）**：`verify-all.sh` 现场 sha16 在我读数期间**变过两次**
（`14:05:15` = **`741b638acaf02e7a`**／17,608 B；`14:06:41` = **`c3d988ca2cea7f20`**），
与 `#25` 记录的 `279b958dda238447` 都不同 —— 那是 **W26B** 的写域（它在补 `run_step` 回显），**不是我**
（我的 `find -newermt 14:00` 命中清单里没有它）。

---

## 10. 我推翻了 / 更正了什么

1. **我推翻了 W25J 草稿的字段形态**（嵌套 `arm_logs.sha256{}` → 我落 **flat**）。依据：预登记 `:49` 与 `D-G9:1050`
   两处权威文本都写 flat。**核对器两种都认** ⇒ 无论波尾用哪种注入路径判据都成立（§3.1、§4.3 case I）。
2. **我推翻了自己第一版沙箱的做法**：给门禁造沙箱树**不能用符号链接** ——
   `tline-gate.sh:142` 的 `stat -c %Y` **不解引用符号链接** ⇒ 四支弱配对臂被误判 `STALE-WEAK`、
   门禁掉到 `NOINFO rc=2`。**必须硬链接/`cp -p`**。这条值得进纪律（§2.2）。
3. **新事实（本轮才发现）**：`_FIELDTABLE` 在门禁里被读 **0** 次、`changelog` 被读 **0** 次、
   `gate-readings.json` **只有写入者没有消费者**（`grep -rn -- 'gate-readings' .` 只回 `tline-gate.sh:659`）
   ⇒ 这三处都不是"位移风险源"。反之，`generation` 是**整块**塞进 `gate-readings.json` 的（`:661`）⇒
   加键会改那个文件的字节，**但没有读者**（已用 A→C 的逐路径机读差异证死）。
4. **更正一处我自己引注的精度**：`arm-logs/README.md` 的硬链接规定在 **`:3-6`**（三条编号理由），
   我初稿写 `:3-9` ⇒ 已改（`:9` 是空行）。
5. **一条"同族但未修"的记录**（供主控记账，本件不动）：`generation.evidence_log_sha256` 键名叫 `sha256`
   而值是 **16 位前缀**（实测长度 16），与同表新增的 `arm_logs` 的**全 64 位**口径不同。两者前缀一致、不矛盾，
   但**同名不同义**是 `D-G8`/`D-G9` 同族的隐患，建议下一波收编（或改名为 `evidence_log_sha16`）。

---

## 11. `NOINFO` / 未测清单（**如实列，不许读成"已验"**）

1. **W26A 重取后的值**：未测（本波不由我重算）⇒ 见 §7。**登记表里的 `tab-*` 三个值在 W26A 落盘那一刻即陈旧。**
2. **真仓上的 `tline-gate.sh`**：未跑（派单禁止；只在沙箱树上跑）。⇒ "我在真仓上加键之后门禁仍是 `PASS`"
   是**沙箱等价性推断**（三棵树同 inode/mtime/sha、只差登记表），**不是**真仓直接读数。**这一条请主控在波尾直接用真仓复取。**
3. **`verify-all` 第 `[8]` 步**：未接线、未跑（不在我写域）⇒ 第 14 步的实际表现**未测**。
4. **`arm_logs` 与门禁"弱配对"判据的交互**：未测 —— 我的核对器**不**替代门禁的
   「树==世代 ∧ 日志 mtime ≥ 世代被测件 mtime」判据（`tline-gate.sh:454-462`），两者是**互补**关系，我在
   `changelog` 的 `why` 里写明了"本块不证明日志属于登记世代"。**别把 `ARMLOG_SHA=PASS` 读成"世代配对已证"。**
5. **`nlink` 的任何判定义**：**有意不测、有意不当判据**（理由见 §4.2 第 3 条：会产生假红）。
6. **W26J/W26F 等其它车道的读写**：未观察（本报告只声明我自己的写域与实测）。
7. **`--selftest` 的并发安全性**：未测（`D-G13` 那类竞态的教训）—— 本脚本**不读仓内任何件的"两个时刻"状态**
   （每次跑都现场重算 sha），但我**没有**在多车道重负载下重复跑它以证无竞态。建议波尾（静树）再跑一次 `--selftest`。

---

## 12. 交付物

| 件 | sha16 | 尺寸 |
|---|---|---|
| **`build/MilBridge/W26D-report.md`**（本文件） | **自指 sha 必然失真**（写进本行就改了本文件）⇒ 以现场 `sha256sum build/MilBridge/W26D-report.md \| cut -c1-16` 为准；交付时的值印在 W26D 的最终回复里 | 现场 `stat -c %s` |
| `build/MilBridge/known-red.json` | **`5aead470c23a99ff`** | 35,310 B |
| `build/MilBridge/tools/arm-log-sha-check.sh` | **`d0547f94bb3806e6`** | 17,559 B |
| `$HOME/w26d-backups/known-red.json.before`（波前全份） | `e623d2b17d948e3b` | 32,602 B |
| `$HOME/w26d-G9/inject-arm-logs.py`（注入器 + `--prove`/`--check`） | **`811e32cc4aa21948`** | 11,966 B |
| `$HOME/w26d-G9/{gate-A,gate-B,gate-C}.{txt,norm}`（沙箱机器证） | 见 §2.2 | 各 72 行 |
| `$HOME/w26d-G9/selftest.txt`（`--selftest` 全量输出） | 见 §4.3 | — |
| `$HOME/w26d-G9/polar-reg.json` / `polar-logs/` / `nodecl-reg.json`（反极性留档） | 见 §6 | — |
| `$HOME/w26d-G9/fp-inputs.txt`（`fp_inputs()` 的 110 件清单） | 见 §9 | — |

**环境读数**：`date` `2026-09-17 14:05:15 +0800`｜kernel `6.8.0-138-generic`｜`nproc=3`｜
`loadavg` **4.45 3.07 1.63**（14:05:15；含 W26A 的构建负荷）｜`MemAvailable` **2987 MB**｜`SwapFree` **486 MB**｜
我的 `dotnet` 进程数 = **0**（本件零 `dotnet`）｜零 `pkill`。
