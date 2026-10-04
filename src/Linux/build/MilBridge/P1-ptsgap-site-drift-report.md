# P1-PTSGAP-SITE-DRIFT（`t137` · W58：`line_is_hist()` 锚族按**具体形状**扩到"自引旧代锚行" ＋ 堵「只加锚即免红」的伪装口子）

> **来源**：队长现取定位 —— `pts-gap-count-check.sh --check` 残留恰 1 条 `SITE-DRIFT docs/ROUTES.md impl want=81 got=87`，真因是**自引旧代工件的 dated 陈述行**被 `line_is_hist()` 当成**现值位**。本件**修牙的判据**（**不**改 `docs/ROUTES.md` 任何现值位文案）。**方向只有收紧**（新增「dated 措辞」必要件 ⇒ 更多行参与现值判定）。
> **仪器**：仓根相对路径 ＋ `bash`／`sed`／`grep`／`sha256sum`／`git diff`＋本牙自己的 `--check`／`--selftest`＋`SITES`/`DECL` 环境覆盖的**仓外夹具**（`~/w281-scribe/t137/fx/**`，收工已删）。**零构建、零跑腿、零显示位、零整趟门禁、零 git 写、未碰哨兵、未碰 `HANDOFF-NEXT.md` 的 `cell=#1`、未翻相位位。**
> ⚠️ **本轮实测的环境怪癖（如实记）**：**绝对路径**偶发「没有那个文件或目录」（`ls`／`sed`／`bash` 三种都撞过；**同一时刻相对路径正常**）⇒ 本席所有脚本改为 `cd <仓根>` ＋ **相对路径**后一律可复现。

## §1 判据依据：改前 `line_is_hist()` 全文 ＋ 现行锚族（**现取，逐条**）

**改前全文**（`build/MilBridge/tools/pts-gap-count-check.sh`，`920326e9242f5fdd`／440 行；本节为**逐字**引用，仅本次有效）：

```
line_is_hist() {
  local L="$1" h e
  # ⚠️ 本行的 ERE **故意不含反引号**（双引号内的反引号会被 shell 当命令替换 ⇒ `D-G186` 同族坑）
  h=$(printf '%s' "$L" | LC_ALL=C grep -oE '[.]so[^0-9a-f]{0,3}[0-9a-f]{16}' 2>/dev/null | grep -oE '[0-9a-f]{16}' | head -1)
  if [ -n "$h" ] && [ "$h" != "$SO16" ]; then return 0; fi
  e=$(printf '%s' "$L" | grep -oE '[0-9]+ 导出' 2>/dev/null | grep -oE '[0-9]+' | head -1)
  if [ -n "$e" ] && [ "$e" != "$EXPORTS" ]; then return 0; fi
  return 1
}
```

**改前锚族（两条，都是"形状 + 值 ≠ 现盘"）**：① `[.]so[^0-9a-f]{0,3}[0-9a-f]{16}` 且该 16hex ≠ `$SO16`；② `[0-9]+ 导出` 且该数 ≠ `$EXPORTS`。
**改前**：**没有**「dated 措辞」这一要件 ⇒ 任何命中行只要带一个**形状像锚、值又不等于现盘**的 token 就能免红（**伪装口子**）。

## §2 真因复核（本席独立现取；**与派单描述有出入，如实记**）

| 行 | 值 | 锚（现取） | dated 措辞 | 改前判 | 改后判 |
|---|---|---|---|---|---|
| `docs/ROUTES.md:245` | `实现口径 81 条` | 无 | 无 | **现值位**（＝现盘 81 ⇒ 不红） | 同 |
| **`docs/ROUTES.md:247`** | **`实现口径 87 条`** | **`so16` 键 ＋ 16hex（`6825dd7071387a46` ≠ 现盘 `5ddc9d63b5232f96`）** | **有**（`读时 2026-09-28T21:48:04+0800`） | **现值位 ⇒ `got=87` ≠ 81 ⇒ 红（就是那 1 条残留）** | **历史行 ⇒ 不红** ✓ |
| `docs/ROUTES.md:311` | `｜**实现口径 81**` | 裸件名 `win32shim` ＋16hex（≠ 现盘） | **无** | 现值位（值＝现盘 81 ⇒ 不红） | 现值位（同 ⇒ 不红） |
| `docs/ROUTES.md:422` | `实现口径 81 条` | 无 | 无 | 现值位（＝现盘 ⇒ 不红） | 同 |

⇒ **修正派单的前提（如实记）**：真正解掉那条 `got=87` 的是 **`:247`（`so16` 键锚 ＋ dated）**；派单点名的 `:312` 一族（现盘 `:311`）**今天是"现值位且值＝现盘"**（`81`）⇒ 它**本来就没红**，但它**确实**带着一枚裸件名锚 —— 该形状对"**若它改引旧值**"的场合是必需的（其可判性由 §5 的 `H4` 腿与 §3 的 `b3` 夹具证明）。
**改前 `/ 改后` 实测**：`SITE-DRIFT` 命中数 **1 → 0**；`PTSGAP_HISTORICAL` 由 `n=?` 变为 **`n=5`**（现取）。

## §3 四条判据（**全部真跑**；`rc` 与点名原文）

| # | 构造 | 读数（现取） |
|---|---|---|
| **① 正极（真树）** | 无覆盖、直接跑 | **`rc=0`**；`PTSGAP=PASS tool=90 dead=11 artifact=1 ops=78 impl=81 so16=5ddc9d63b5232f96 exports=594`；声明件 `# PTSGAP-DECL: tool=90 dead=11 artifact=1 ops=78 impl=81 so16=5ddc9d63b5232f96 exports=594 …` ⇒ **五个字段逐字段相等** ✓；**`SITE-DRIFT`＝0（1 → 0）** ✓ |
| **② 反极 A（现值位写错必红）** | 仓外夹具 `b1`：现值位 `实现口径 81 条` → `999` | **`rc=1`**；`SITE-DRIFT docs/ROUTES.md impl want=81 got=999`（×2 处命中，**点名到文件＋字段＋两值**）✓ |
| **③ 反极 B（伪装免红必红）** | 仓外夹具 `b2`：**追加一行现值行**（`现值出处（现盘）｜**实现口径 82**（只加假锚：件 win32shim 0000000000000000）`，**无 dated 措辞**） | **`rc=1`**；`SITE-DRIFT docs/ROUTES.md impl want=81 got=82` ⇒ **只加锚不够**、dated 必要件生效 ✓ |
| **④ 边际** | 同 `b2` 的形状**加上** dated 措辞（`🆕 **在册数已现算（主控 2026-09-26，只读车道 W174A）**`）＝夹具 `b3`；另 `b4`＝`⏪ dated 结论（读时 …）` ＋ `so16` 键锚 | `b3`：**`rc=0`、`SITE-DRIFT=0`**（历史行）✓；`b4`：**`rc=0`、`SITE-DRIFT=0`**（`so16` 键锚形状生效）✓ |
| ④′ 真树在场性 | `:247`（so16 锚）与 `:311`（裸件名锚）两行**仍在场** | 现取：两行均在（`grep -c` 各 ＝ 1），且 `--check` `rc=0` ⇒ **在场不红** ✓ |

**因果对**：`b2`／`b3` 只差「行内有无 dated 措辞」⇒ `SITE-DRIFT` **1 → 0**、`rc` **1 → 0** ⇒ 该要件是唯一变量 ✓。

## §4 改后判据（形状表 ＋ 两个必要件；**逐条留证**）

**锚族（四条形状；全部"具体形状"，**禁止**"命中任意 16 hex"过宽规则）**：
1. `[.]so[^0-9a-f]{0,3}[0-9a-f]{16}`（**既有，未动**）；
2. `[0-9]+ 导出`（**既有，未动**）；
3. **裸件名 ＋ 16 hex**（新增）：白名单 `win32shim`／`libwpfwin32`／`wpfgfx_cor3`／`PresentationCore`／`PresentationFramework`／`WindowsBase`／**`so16`**，后随 **≤5 个非 16 进制字符** 再 16 hex；理由：`docs/ROUTES.md` 的自引行写的是 `so16` **`6825dd7071387a46 → 2a5165700a8c8579`**（键与 hex 间恰 5 个非 hex 字符：反引号／空格／两个星号／反引号）⇒ 间隔参数按**实测**取 5；`win32shim fc60c34d51fd9247` 属同族写法；
4. **`exports=<N>`**（新增）。
**第二条必要件（新增，堵伪装口子）**：行内须带**dated 措辞** —— `读时`｜`dated`｜`⏪`｜`历史`｜**裸日期戳 `YYYY-MM-DD`**｜`世代`（最后一枚的动因：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `t134` dated 块自述句「**口径世代仍为** `libwpfwin32.so fc60c34d51fd9247`／`550 导出`」＝**明写**引的是哪一代）。**两件同时成立**才判历史行。
**残留口子（如实记）**：**同时**伪造「锚 ＋ dated 措辞」仍可免红（本件只堵"只加锚"这一路；更严的形态需要"锚值必须能在 git 历史里找到该代工件"一类**跨件**判据，超出本件射程）。

## §5 `--selftest` 成对读数 ＋ 新增三腿

| 时机 | 读数 |
|---|---|
| 改前 | `PTSGAP_SELFTEST=PASS pass=12 fail=0 legs=12 must_red=7` |
| 改后 | **`PTSGAP_SELFTEST=PASS pass=15 fail=0 legs=15 must_red=9`**（**无一条期望被放宽**；新增三腿全部是收紧方向的判定） |

**新增腿（逐条现取读数）**：`H4 自引旧代 dated 锚行（裸件名 ＋ exports=）**不得假红** ⇒ PASS` ✓｜`H5 现值行只加假锚（**无 dated 措辞**）⇒ 仍必红 ⇒ FAIL` ✓｜`H6 现值位 impl 写错 999（**必红并点名 want/got**）⇒ FAIL` ✓。
⚠️ **过程中如实记的两处自身缺陷（已就地修）**：① `H4`／`H5` 初版夹具用了 `（…）` 括注形状，**不被 `one()` 扫**（该形状不在六条模式里）⇒ 两腿**空转**（`H5` 误报 PASS）⇒ 已把两腿夹具改成**会被扫的形状**（`｜**实现口径 N**` ＋ `… 条`）；② `so16` 键锚的间隔参数初取 `{0,4}` ⇒ 与实测（**5**）不符 ⇒ 已按实测改为 `{0,5}`（**不是**放宽判据：形状前缀仍是白名单，且 dated 必要件不变）。

## §6 逐件改动与位移（收尾必交①③⑥）

| 件 | 改前 sha16 / 行数 | 改后 sha16 / 行数 | `numstat`（删除行逐条） |
|---|---|---|---|
| `build/MilBridge/tools/pts-gap-count-check.sh` | `920326e9242f5fdd` / 440 | **`f6b8738a449a1e61`** / 513 | **`75 2`** —— 2 处删除具名可追溯：① `local L="$1" h e`（改为含 `hb eb` 的 4 变量局部声明）；② 自测汇总 `printf` 行的计数（`legs=12 must_red=7` → `legs=15 must_red=9`） |
| 载体 `build/MilBridge/P1-ptsgap-site-drift-report.md` | 新建 | 见 §7 | 新件 |

**③ 声明件** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`：**本件一字未改**（只读）—— 现取 `sha256` 前16 **`5f05b6c1db4a60ee`**、`mtime 2026-09-29 14:14:13`、声明行 `tool=90 dead=11 artifact=1 ops=78 impl=81 so16=5ddc9d63b5232f96 exports=594 w66pre16=bf6b683d94549087`；与 `LIVE`（`PTSGAP=PASS` 行）**逐字段相等** ✓。⚠️ 该件在 `t133` 在飞窗口内由**他者**更新过（`mtime 14:14:13` 在我开工之前）⇒ 本席**未"对齐"**、只如实记现值。
**⑥ 收工读数**：`DEFREG=PASS declared=224 route_ids=224` ＋ **`DEFREG_DECLDRIFT=0 keys=-`**（`rc=0`）；`REPORTID=PASS files=265 ids=2207 declared=224`（`rc=0`）。

**覆盖面与 `cell=#1`（**按派单有意未写**）**：本件改的是覆盖面内件（现取 `infp.sh list | grep -c 'pts-gap-count-check.sh'` ＝ **1**）⇒ 按第 `28` 条**本应**登记 `cell=#1`；派单硬约束**明令不碰** `HANDOFF-NEXT.md` 的 `cell=#1`（「本轮由队长收尾同趟做，**是暂缓不是豁免**」）⇒ 本件**有意未登记**，如实记此条。**指纹现取**（本席收工时刻）＝ **`98c7c2a38f6be824368ce9259f67b45aba9603a5218b719e7017c95eea61ad35`**（成因含本席的工具件 ＋ 他者 `src/**` 在飞）。

## §7 未做项、备份面与自证

- **未做**：不改 `docs/ROUTES.md` **任何**现值位文案（本件只修牙的判据）；不用"任意 16 hex"过宽规则；不放松任何阈值/判词；未 `--emit`；未跑整趟门禁／未构建／未跑腿／未占显示位；未 `git add/commit/push`；未碰 `src/WpfGfx.Linux.Native/**`（`t133` 在飞）、`.cs` 产品件、两枚哨兵、`HANDOFF-NEXT.md` 的 `cell=#1`；相位位 `phase=degraded` **未翻**。
- **备份面（第 `29` 条）**：工具件**写前** `stat -c %h` ＝ 1、`cp -p` 至 `~/w281-scribe/t137/bak/pts-gap-count-check.sh.pre-t137`（`920326e9242f5fdd`／440 行，可复算）；全部补丁脚本与读数日志留 `~/w281-scribe/t137/**`；仓外夹具 `~/w281-scribe/t137/fx/**` 收工已删。
- **边界**：写域 ＝ `build/MilBridge/tools/pts-gap-count-check.sh`（牙本体，派单允许）＋ 本件（新建）＋ 仓外 `~/w281-scribe/t137/**`。

**本件自证**：`head -n -1 build/MilBridge/P1-ptsgap-site-drift-report.md | sha256sum | cut -c1-16` ＝ b6f85f890ae2c8f6（末行不计入自身）
