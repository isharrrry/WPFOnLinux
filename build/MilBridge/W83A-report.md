# W83A 报告 —— 修 `D-G82`（`wic_proxy.c` 注释里的 3 个真 NUL 字节）＋ 全仓源卫生普查

- **lane = W83A**｜波 `#50`（`#49` 已于 2026-09-21 冻结，本件属 `#50` 的第一批落地件）
- 仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下称 `$R`）
- 时间：开工 `2026-09-21 23:03:06 +0800`，收工 `2026-09-21 23:06:29 +0800`
- `nproc=3`｜kernel `6.8.0-138-generic`｜`loadavg` 开工 `0.64, 0.28, 0.19` → 收工 `1.48, 0.80, 0.41`
- **零 `dotnet`**（本件全程未跑任何 `dotnet` 命令；只用了 `grep`/`file`/`cmp`/`python3`/`gcc`，`gcc` 只编译到 `$HOME`，`heavy-slot.sh` 未使用）
- 写域内改动 **1 件**：`build/DirectWrite.Linux/wic-shim/wic_proxy.c`（只把 3 个 NUL 字节改成文本 `\0`）＋ 本报告。**写域外一字节未碰。**

---

## 0 · 结论（结论在前）

1. **`D-G82` 已修**：`wic_proxy.c` 的 3 个真 NUL 字节已改成**正常的转义写法** `\0`（文本两字节），**注释语义一字未改**，**除第 `289` 行外无任何一行变动**（机器证见 §2.2）。
2. **修前/修后成对读数**：`file` `data` → `C source, Unicode text, UTF-8 text`；`grep -n '<已知串>' <件>` 修前 **rc=0 但 stdout 0 字节**（只往 stderr 吐一句"匹配到二进制文件"）→ 修后**逐行给行号**（同一次查询 stdout 527 字节、7 行）。
3. **产物零回归（强证）**：把**修后**源按 `build-wic-shim.sh:7-8` 的原样命令编译 ⇒ `libwpfwic.so` **与仓内权威件逐字节相同**（`f7b3026c8c019be2`，74984 B）。目标文件 `-c` 亦逐字节相同。⇒ **不需要重建、不移动任何世代位**。
4. **全仓普查（`D-G82:2337` 记为 `NOINFO` 的那一格）**：`$R` 自有代码内**"被判二进制、但本意是文本"的件 = 恰好 1 件**，就是 `wic_proxy.c`（现已被本件修掉 ⇒ 普查后归零）。另有 **11 件无扩展名 ELF 可执行体**同样被判二进制，但它们是**货真价实的二进制**（编译产物），不是 `D-G82` 的实例。
5. **两极化成立**：把 3 个 NUL 放回**副本** ⇒ 副本 sha16 回到 `f0d3d1501aebcd8c`（与修前**逐字节相同**）、`file` 回到 `data`、`grep -n` 回到"无行号、stdout 0 字节"。
6. **🔴 我推翻缺陷册的一处引注**：`D-G82` 条目（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2334`）写的是 **`:202`**；**实测那 3 个 NUL 在 `:289`**（且行 202 是 `static int gif_frame_delay_cs(...)` 的函数头，不是那条注释）。详见 §5.1。
7. **"一切都建在文件:行上"这个危害的实际射程比册子里写的窄**：`$R` 内**没有任何判据/脚本用 `grep`/`sed` 按行读这个文件**（§5.3 的现场搜索为 0 命中）⇒ 它今天伤的是**人**（读、引用、review、`grep -rn` 顾问）而**不是某条已接线的判据**；`frames-check.sh` 的突变手术用的是 `open(...,"rb")`（`frames-check.sh:74`）⇒ 不受影响。

---

## 1 · ① 改动前的成对读数与量化

### 1.1 起点（现场算，非手抄）

| 量 | 值 |
|---|---|
| 件 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c` |
| sha16（修前） | **`f0d3d1501aebcd8c`** |
| 字节数 | `130592` |
| mtime | `2026-09-21 18:30:56.523764007 +0800` |
| 行数 | `2667` 个 `\n` |

> 旁证：此 sha16 与 `build/MilBridge/W79A-report.md:84` 所记的 W79A 修后值一致（该行逐字：``## 3 修法（逐处；`wic_proxy.c` `d0ff278005c315d5` → `f0d3d1501aebcd8c`，120512 → 130592 B）``；另见同报告 `:205`/`:324`）⇒ **本件修的正是 W79A 交出来的那一版**（不是我拿到的某个中间态）。

### 1.2 `file` 成对读数

```
$ file build/DirectWrite.Linux/wic-shim/wic_proxy.c
build/DirectWrite.Linux/wic-shim/wic_proxy.c: data
```

### 1.3 `grep -n` 的行为（**这是本缺陷的要害：不是报错，是"rc 说成功、stdout 空"**）

```
$ grep -n 'is_png_bytes' <件>   # 修前
grep: build/DirectWrite.Linux/wic-shim/wic_proxy.c: 匹配到二进制文件
rc=0        stdout=0 字节        stderr='匹配到二进制文件'
```

矩阵（修前，逐条现场跑）：

| 命令 | rc | stdout/stderr |
|---|---|---|
| `grep -n 'is_png_bytes' <件>` | **0** | stdout **0 字节**；stderr `匹配到二进制文件` |
| `grep -c 'is_png_bytes' <件>` | 0 | stdout `7`（计数**给**，行号**不给**） |
| `grep -q 'is_png_bytes' <件>` | 0 | 空（静默"命中"） |
| `grep -a -n 'is_png_bytes' <件>` | 0 | stdout 有行号（**这是既有的绕法**，见 §2.4） |
| `grep -n 'ZZ_NO_SUCH_STRING_ZZ' <件>` | 1 | 空（**与命中时的 rc 无法区分**：命中=0/空，未命中=1/空） |
| `grep -rlI --include='wic_proxy.c' .` | 0 | **0 件**（`-I` 直接把它当二进制跳过 ⇒ 任何"文本件普查"都看不见它） |

⚠️ **量化结论**：缺陷册（`:2334`）说"只报匹配到二进制文件，不给行号"——**实测比这更坏**：`grep -n` 的 **rc 仍是 0**，而 stdout **恰好 0 字节** ⇒ 一个写 `out=$(grep -n PAT f)` 的判据会**拿到空串却以为成功**（"命中"与"未命中"在 `rc` 上不可分）。这一格是本件新加的读数。

### 1.4 3 个字节的量化

```
$ wc -c < <件>                 -> 130592
$ tr -d '\0' < <件> | wc -c    -> 130589
$ tr -dc '\0' < <件> | wc -c   -> 3
```

字节级定位（0-based 偏移 / 1-based 偏移 / 行号 / 列）：

| # | 偏移(0-based) | 偏移(1-based) | 行 | 列 |
|---|---|---|---|---|
| 1 | `15873` | `15874` | **289** | 31 |
| 2 | `15902` | `15903` | **289** | 60 |
| 3 | `15921` | `15922` | **289** | 79 |

`sed -n '289p' | od -c`（修前，逐字）：

```
0000000
0000020                   /   *       k   e   y   w   o   r   d  \0
0000040   c   o   m   p   F   l   a   g       c   o   m   p   M   e   t
0000060   h   o   d       l   a   n   g   T   a   g  \0       t   r   a
0000100   n   s   l   a   t   e   d   K   e   y   w   o   r   d  \0
0000120   t   e   x   t       *   /  \n
```

即那一行是：`                    /* keyword␀ compFlag compMethod langTag␀ translatedKeyword␀ text */`
—— 本意是 **PNG `iTXt` 块的字段布局**（字段间以 NUL 分隔），把 `\0` **写成了实字节**。

**同文件内已有 3 处把同一惯用法写对了**（现场读到的行，这是"本意是文本"的直接证据）：

- `:449` `if (m == 0xE1 && seglen >= 8 && memcmp(b + i + 4, "Exif\0\0", 6) == 0) {`（C 字符串字面量，正确）
- `:866` `for (int m = 0; m < enc->meta_count; m++) {   /* tEXt: keyword\0text */`（注释，正确）

---

## 2 · ② 修法（含还原证明）

### 2.1 改动逐处

**只改 1 处**：把 `:289` 那 3 个实字节 NUL 改成**文本两字节** `\0`（反斜杠 + 数字 0）。
**未动**：注释语义（仍是"字段以 NUL 分隔"）、缩进（20 空格）、行序、周围任何一行。因为每个 NUL（1 B）→ `\0`（2 B）是**不可避免的 3 B 增长**，所以该行由 88 字符变 91 字符（`sed -n '289p' | wc -c` = 91，含换行）。

| | 修前 | 修后 |
|---|---|---|
| sha16 | **`f0d3d1501aebcd8c`** | **`8dc634b9254295f4`** |
| 字节数 | `130592` | `130595`（+3） |
| 行数 | `wc -l` = `2667`（`split('\n')` 得 2668 段，末段为空） | 同左（`2667` / 2668 段） |
| `file` | `data` | `C source, Unicode text, UTF-8 text` |
| NUL 字节数 | `3` | **`0`** |
| mtime | `2026-09-21 18:30:56 +0800` | `2026-09-21 23:04:51 +0800` |

修后该行逐字：

```
                    /* keyword\0 compFlag compMethod langTag\0 translatedKeyword\0 text */
```

修后全文件文本 `\0` 出现 6 处（`(15873,289) (15903,289) (15923,289) (23460,449) (23462,449) (43165,866)`）＝ 新加的 3 处 ＋ 原本就对的 3 处。

### 2.2 最小性证明（**行级 + 字节级，两个独立证**）

- **行级**：逐行比对修前/修后 ⇒ `changed line numbers: [289]`（**只有一行**，2668 行里恰好 1 行不同）。原文：

```
  OLD: b'                    /* keyword\x00 compFlag compMethod langTag\x00 translatedKeyword\x00 text */'
  NEW: b'                    /* keyword\\0 compFlag compMethod langTag\\0 translatedKeyword\\0 text */'
```

- **字节级还原证明**：只在这 3 个位置把新插入的 2 字节换回 1 个 `\x00` ⇒ **重建件与修前件逐字节相同**：

```
len(rev)=130592  len(old)=130592   BYTE_FOR_BYTE_EQUAL=True
rev_sha16 = f0d3d1501aebcd8c       old_sha16 = f0d3d1501aebcd8c
```

### 2.3 零回归（编译级，**强证**）

按 `build/DirectWrite.Linux/wic-shim/build-wic-shim.sh:7-8` 的原样旗标（`gcc -O2 -fPIC -shared -Wall -Wextra -Wno-unused-parameter … -ldl -lz`），在 `$HOME` 下对**修前件**与**修后件**各做一遍（两份都放在各自目录里、文件名同为 `wic_proxy.c`，避免路径串进产物）：

| 证 | 修前 | 修后 | 结论 |
|---|---|---|---|
| `gcc -fsyntax-only -Wall -Wextra` | rc=0，**2 条**告警 | rc=0，**2 条**告警 | **告警文本 `cmp` 逐字节相同** |
| 预处理输出 `gcc -E`（注释被剥掉） | `26b5dcbeaed7af0e` | `26b5dcbeaed7af0e` | **逐字节相同**（注释改动不进行为流） |
| 目标文件 `gcc -c -O2 -fPIC` | `143b8eb940783bac`（79928 B） | `143b8eb940783bac`（79928 B） | **`cmp` 逐字节相同** |
| 共享库 `-shared` | — | `f7b3026c8c019be2`（74984 B） | **与仓内权威 `libwpfwic.so` 逐字节相同** |

- **仪器正控（必须的）**：同一套命令对**真改了一处代码**的副本 ⇒ 目标文件 `4bcc40a76ff1d915` ≠ `143b8eb940783bac` ⇒ 上面的"相同"不是"仪器对什么都报相同"。
- 那 **2 条**告警是**既有**的 `-Wcomment`（`wic_proxy.c:2315:86` 与 `:2315:89`，`"/*" within comment`），**修前修后同文本**（`gcc` 输出各 4 行 = 2 条 `warning:` ＋ 源码行 ＋ 脱字符行）；其中**没有**任何一条与 NUL 有关（`grep -ci 'null character'` = 0；`-Wpedantic` 亦然）。

⚠️ **因此我没有重建 `libwpfwic.so`（它在写域外）**：修后源**产出的就是仓内那一份字节**，重建是**零信息动作**。仓内 `libwpfwic.so` 仍是 `f7b3026c8c019be2`（`74984 B`，mtime `9月 21 18:32`），**未被本件触碰**。

### 2.4 既有的绕法（写给以后要读这个文件的人）

`grep -a -n 'PAT' <件>` 修前就能给行号（`-a` 关掉二进制启发式）。修后 `-a` 已无必要，但**不构成回归**：`grep -a` 与 `grep` 在文本件上输出一致（现场：`grep -n` 与 `grep -a -n` 修后同样 7 行）。

---

## 3 · ③ 全仓普查（`D-G82:2337` 标为 `NOINFO` 的那一格）

### 3.1 判据与覆盖面（**先把"没扫什么"写在前面**）

- **遍历根** `$R`；**排除目录**：`upstream/`（上游 `dotnet/wpf` 镜像，非本仓自有代码）、`.git/`、`obj/`、`bin/`、`node_modules/`、`.artifacts/`。
- **扫描对象**（两趟，互相印证）：
  - **A 趟（扩展名白名单）**：`*.c *.h *.cs *.sh *.py *.md *.props *.targets *.tsv *.csproj *.txt *.json *.xml *.yml` 等 **63 类**（含 `*.xaml`/`*.config`/`*.log`/`*.s`/无扩展名共 63 个条目，见 `$HOME/w83a-run/census2.py` 的 `TEXT_EXT`）⇒ **1155 件**。
  - **B 趟（catch-all，最严）**：**除**明确二进制扩展名（`.png .jpg .gif .webp .bmp .ico .ttf .otf .woff .so .dll .a .o .pyc .snk .nupkg .zip .gz .xz .pdf .bin .stream .dat .db .sqlite .exe .pdb .class .jar .wasm .log`）**外的一切文件** ⇒ 扫了 **1142 件**，跳过的二进制扩展名 **328 件**，树内总件数 **1470**。
- **判据**：文件体里 **≥1 个 `0x00` 字节**。
- **仪器正控**：合成一对 `ctrl_nul.c`（含 1 个 NUL）/`ctrl_clean.c`（不含）⇒ 脚本对前者报 `nul=1`、后者 `nul=0`，且 `file` 分别报 `data` / `ASCII text`；`grep -n` 分别"无行号" / `3:line3` ⇒ **仪器对两极化都敏感**。
- **独立第二仪器（libmagic）**：对 A 趟的 1155 件跑 `file --mime-type`，非 `text/*` 的 67 件分桶为：`application/json` 54（合法）、`application/x-pie-executable` 11、`application/octet-stream` **1**（= `wic_proxy.c`）、`inode/x-empty` 1（`build/.wave-done`，0 字节，无 NUL）。⇒ **两个独立仪器指向同一结论**。

### 3.2 普查清单：**恰好 1 件**（"被判二进制、本意是文本"）

| 路径 | 首个 NUL 偏移 | NUL 数 | 是否同样的 `\0` 写法 | 处置 |
|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/wic_proxy.c` | `15873`（`:289`） | `3` | **是**（`keyword\0 … langTag\0 translatedKeyword\0`） | **本件已修** ⇒ `8dc634b9254295f4`，NUL=0 |

**修后复跑同一普查 ⇒ 该类件归零**（A 趟 `found` 由 12 降到 11，且降掉的那一件正是 `wic_proxy.c`；B 趟同样只剩下面那 11 件）⇒ 这是普查仪器本身的**正/负极性成对读数**。

### 3.3 另外 11 件被判二进制 —— 但**不是**本缺陷的实例（如实区分）

| 路径 | 大小 | NUL 数 | 首个 NUL | 是什么 |
|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/probe_decode` | 26616 | 15092 | 7 | ELF 64-bit LSB pie executable |
| `…/probe_describe` | 16368 | 12266 | 7 | 同上 |
| `…/probe_encode` | 16192 | 12685 | 7 | 同上 |
| `…/probe_foreign` | 16352 | 10398 | 7 | 同上 |
| `…/probe_lock` | 16240 | 10244 | 7 | 同上 |
| `…/probe_premul` | 16424 | 11496 | 7 | 同上 |
| `…/probe_refcount` | 16192 | 11285 | 7 | 同上 |
| `…/probe_shim` | 16720 | 10470 | 7 | 同上 |
| `…/probe_subrect` | 16320 | 12266 | 7 | 同上 |
| `…/probe_write_loop` | 16480 | 10275 | 7 | 同上 |
| `build/MilBridge/tools/t1b-ls-selftest` | 16408 | 11658 | 7 | ELF 64-bit LSB pie executable |

- 首个 NUL 一律在**偏移 7** ⇒ 正是 ELF 头的 `\x7f E L F \x02 \x01 \x01 \x00`（`EI_OSABI` 那一字节）⇒ **它们本来就是二进制**，`file` 判二进制是**对的**。
- 它们是**无扩展名的编译产物**：`probe_*.c` **10 份源**就在同目录（`build/DirectWrite.Linux/wic-shim/probe_*.c`，逐名对得上 10 个可执行体）；`t1b-ls-selftest` 由同目录的 `t1b-ls-selftest.c`（3505 B，`9月11 16:43`）编出。
- ⇒ **不算 `D-G82` 的实例**（`D-G82` 判的是"**本意是文本**的件被判二进制"）。但作为**源卫生观察**值得登记：**11 个无扩展名 ELF 编译产物留在源码树里**，任何按 `find -type f` 做的普查都会把它们当"文本候选"，且 `grep -rIl` 会静默跳过它们。**本件只普查、不处置**（批量清理要独立一波＋判据）。

### 3.4 我**没扫**什么，为什么

1. **`upstream/**`**：上游 `dotnet/wpf` 镜像（非本仓自有代码；本缺陷的定义域是"本仓自有代码的源卫生"）。⇒ 该域**未测**。
2. **`obj/` `bin/` `.artifacts/`**：构建产物（不参与"源卫生"；且本仓已有 `BuildHygiene.props` 一族在管）。
3. **328 个明确二进制扩展名的件**（`.png` 255、`.pyc` 34、`.ttf` 9、`.stream` 7、`.jpg` 4、`.so` 2、`.dll` 2、`.snk` 1）：**按定义就是二进制**，扫它们对 `D-G82` 零信息。⚠️ 但为免"用扩展名把问题藏起来"，我做了 **B 趟 catch-all**（不靠扩展名、只排除上面清单），结论不变。
4. **`.log` 已在 B 趟被排除**（14 件）——**这里是我的一个判据选择，如实标出**：日志文件既可能是文本也可能含 NUL，我按"非自有源码"排除。为不留白，我单独点了名：`ls` 显示它们都不在 `build/DirectWrite.Linux/wic-shim/**`。⇒ 若主控认为 `.log` 应纳入，这一格为 **`NOINFO`**。
5. **`build/MilBridge/known-red.json.bak-20260917-151210`**（`.bak-<时间戳>` 扩展名，35310 B）：`file` 判 `JSON data`、NUL=**0** ⇒ **不是**实例（它已被 B 趟 catch-all 覆盖）。
6. **本件只普查、不批量改**（派单书要求）：除 `wic_proxy.c` 外**一件未改**。

---

## 4 · ④ 两极化

| 侧 | 构造 | `file` | `grep -n 'is_png_bytes'` | sha16 |
|---|---|---|---|---|
| **正极**（修后，仓内件） | 本件修法 | `C source, Unicode text, UTF-8 text` | **给行号**：7 行，stdout **527 B**（`185:`、`376:`、`424:`、`849:`、`1482:`、`1555:`、`2016:`），stderr 空，rc=0 | `8dc634b9254295f4` |
| **负极**（把 3 个 NUL 放回**副本** `$HOME/w83a-run/reverted.c`） | 对副本做逐行 `\0`→`\x00` | **`data`** | **无行号**：stderr `匹配到二进制文件`，stdout **0 B**，rc=**0** | **`f0d3d1501aebcd8c`**（与修前件**逐字节相同**） |

⇒ 负极**必须**回到"二进制、无行号"——**成立**；而且负极副本的 sha16 **恰好等于修前件**，这同时是"修法可逆且最小"的第三个独立证。
（反极性操作**在 `$HOME` 的副本上**做，仓内件未被往复改动。）

---

## 5 · 我没做到的事 / 我推翻的话 / 射程

### 5.1 🔴 推翻缺陷册的引注：`:202` → 实测 `:289`

- 册子（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2334`）逐字写：**"`build/DirectWrite.Linux/wic-shim/wic_proxy.c:202` 的注释把 `\0` 写成了实字节 NUL"**；
- 溯源：这条来自 `build/MilBridge/W79A-report.md`（`:257` 第 7 行），它同时把自己的新增块写成 `:202-272`（`W79A-report.md:94`）；
- **实测**（在本件起点 sha16 `f0d3d1501aebcd8c`，即 W79A 自己记的修后值上）：3 个 NUL 全在 **第 `289` 行**，偏移 `15873/15902/15921`；而 **`sed -n '202p'` 是 `static int gif_frame_delay_cs(const unsigned char *b, size_t n, int32_t index, uint16_t *out)`** —— 是**函数头**，不是那条注释。
- 那条注释的**宿主函数**是 `png_get_text()`（定义在 `:276`），**在 W79A 的插入块 `:202-272` 之外** ⇒ 与 W79A 自述"未动（别人的既有件）"**不矛盾**：它只是把行号记错了。
- ⚠️ **这正是 `D-G82` 自己的反讽**：一个"按行引用会静默失效"的缺陷，**第一次被登记时就引错了行号**（`:202` 是真注释**上方 87 行**的函数头）。⇒ 主控落登记块/更正时，请用 **`:289`**（修前编号）／修后同一行仍是 `:289`。

### 5.2 世代位：本件**不动任何世代位**（独立复核，不是抄 W79A）

- `build/close-wave.sh:104-107` 的 `fp_inputs()` 第一行是 `find src/WpfGfx.Linux.Native/tools build \( -maxdepth 2 -name 'patch-*.py' -o -maxdepth 1 -name 'port-lib.py' -o … \)`：**名字过滤器**是 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`，**改不到 `.c`**；`-maxdepth` 生效值是链尾的 `1`（`:91-96` 自述），而 `wic_proxy.c` 在 `build/` 下**深度 3**。
- `:108` 只收 `build/shims/**/*.cs`；`:115` 只收 `src/WpfGfx.Linux/**/*.cs`；`:124-125` 只收 `src/WpfGfx.Linux.Native/**` 的 `*.c|*.h`。**`build/DirectWrite.Linux/**` 不在覆盖面任何一条里** ⇒ **`inputs_fp` 不移位**。（另：本件改的是**注释**，`libwpfwic.so` 逐字节不变 ⇒ `wic_shim` 位也不动，§2.3 已证。）
- 未跑 `close-wave.sh`/`verify-all.sh`（派单书与纪律均禁）。

### 5.3 危害的**实际**射程（比册子写的窄，如实说）

- 现场搜 `$R` 内所有 `*.sh`/`*.py` 里**按名字 grep/sed/awk 这个文件**的命令 ⇒ **0 命中**（`grep -rn --include='*.sh' --include='*.py' -E '(grep|sed|awk)[^|]*wic_proxy' .`）。
- 真正读它的只有两处，**都不受 NUL 影响**：
  - `build/DirectWrite.Linux/wic-shim/build-wic-shim.sh:6`（把它交给 `gcc`；`gcc` 对注释里的 NUL 不告警，§2.3 已实测）；
  - `build/DirectWrite.Linux/wic-shim/frames-check.sh:37` + `:74` 的突变手术用 **`open(src,"rb")`**（字节模式）⇒ 不受影响。
- ⇒ `D-G82:2335` 说"会让后续所有按行引用失效"——**对"人"成立**（`grep -rn` 顾问、评审、报告引注），**对"已接线的判据"今天不成立**（没有判据这样读它）。⚠️ **这不降低它的价值**：本仓把"文件:行"当**证据格式**，而 §5.1 正是"引错行号"的现场实例。

### 5.4 `NOINFO` 清单

1. **`upstream/**` 域未普查**（§3.4-1）⇒ "全仓"一词在本报告里严格指"**仓内自有代码（排除 `upstream/` 与产物目录）**"。
2. **`.log` 14 件按"非自有源码"排除**（§3.4-4）⇒ 若主控要纳入，这一格为 `NOINFO`。
3. **11 个无扩展名 ELF 产物**：是否**应当**留在源码树里（是否有脚本按名调用它们）**未判** ⇒ `NOINFO`（本件只普查、不处置）。
4. **`wic_shim` 之外是否还有别的判据件把 `wic_proxy.c` 的 sha16 钉死**：我只核了 `close-wave.sh` 的覆盖面与 `build-wic-shim.sh`/`frames-check.sh`/`check-applocal-sync.sh` 三个脚本的读法；**仓库里是否有别的报告/登记表引用了修前 sha16 `f0d3d1501aebcd8c`（会因本件改字节而"过期"）未逐件核** ⇒ `NOINFO`（W79A 报告里那一处**已知**会过期，属正常留档，不是判据）。
5. **4 条既有 `-Wcomment` 告警（`wic_proxy.c:2315`）未处置**（不属本件；记在此处以免被当成我引入的）。

---

## 6 · ⑥ 读数表（纪律 32：谁跑的、什么时候、机器状态）

| 项 | 值 |
|---|---|
| lane | `W83A`（本会话） |
| 时间 | 开工 `2026-09-21 23:03:06 +0800`｜收工 `2026-09-21 23:06:29 +0800` |
| kernel | `6.8.0-138-generic` |
| `nproc` | `3` |
| `loadavg` | 开工 `0.64, 0.28, 0.19`｜收工 `1.48, 0.80, 0.41` |
| `MemAvailable` | 开工 `2823776` kB｜收工 `2813952` kB（⚠️ **未做连续采样 ⇒ 本件不声明"最低值"**） |
| `SwapFree` | 开工 `1080292` kB |
| `wic_proxy.c` sha16 | 修前 `f0d3d1501aebcd8c`（130592 B）→ 修后 **`8dc634b9254295f4`**（130595 B） |
| `libwpfwic.so` sha16 | **`f7b3026c8c019be2`**（74984 B）——**未重建、未触碰**；且用修后源现场重编得**同一 sha** |
| `gcc` | `gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0` |
| 备份 | `$HOME/w83a-backup/wic_proxy.c.before`（sha16 `f0d3d1501aebcd8c`，`cp -p` 原件） |
| 草稿/证据 | `$HOME/w83a-run/`（`census2.py`、`census3.py`、`cmp/{a,b}/`、`reverted.c`、`mut.c`、`g.out/f.out/r.out`、控制对 `ctrl_*.c`） |
| 并发观察 | 普查趟之间树内新增 **1 件**：`build/MilBridge/W82A-report.md`；**另有两条不属于我的改动**：`src/WpfGfx.Linux.Native/src/win32_core.c`（`a6b12aa3b4c96176`，`23:06:11`）与 `src/WpfGfx.Linux.Native/src/win32_internal.h`（`c3dbf6b936a36239`，`23:06:13`）——**是另一条车道（W82A）在跑，不是本件**（这两件在 `close-wave.sh:124-125` 的覆盖面里 ⇒ **`inputs_fp` 会因它们移位，与本件无关**）。`wic_proxy.c` 的 sha16 在报告落盘前**复核仍为 `8dc634b9254295f4`** |
| 写域合规（机器证） | `find . -newermt '2026-09-21 23:03:00' -type f`（排除 `upstream/`、产物目录）只命中 5 件：本件 2 件（`wic_proxy.c`、本报告）＋**别的车道 3 件**（上格）⇒ **本件写域外零写入** |
| 未跑的禁项 | `dotnet`（**零次**）、`heavy-slot.sh`、`verify-all.sh`、`close-wave.sh`、`pkill`、`pgrep -f`、`ps\|grep` 定人 |

---

## 7 · ⑦ ≤6 行中文大白话小结

1. 那 3 个 NUL 是有人把注释里的 `\0` 直接敲成了**真字节**，害得整个 `.c` 被当成二进制。
2. 害处不是报错：`grep -n` 会**说"成功"（rc=0）但一个字都不吐**，行号全丢——比册子写的"只回一句二进制文件"更坏。
3. 我只把那 3 个字节改成 `\0` 两个字符，**全文件只有第 289 行变了**，把字节放回去就**一模一样**。
4. 顺手证了**产物零回归**：用修好的源重编，`libwpfwic.so` 与仓里那份**逐字节相同**，所以**不用重建、不动世代位**。
5. 全仓普查：**本意是文本却被判二进制的件就这一件**（现已归零）；另有 11 个无扩展名的 ELF 编译产物是**真二进制**，不算这毛病，但值得单独清。
6. 顺手抓到册子引错行号：写的是 `:202`，**真位置是 `:289`**——一个"行号会静默失效"的缺陷，登记时自己就引错了行。

---

## 附 · 给主控的两条落地建议（**本件不落**，因写域外）

1. **更正引注**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2334` 的 `wic_proxy.c:202` ⇒ **`:289`**（修前/修后同号）；并在 `:2337` 把已普查的结论补上："**仓内自有代码普查后 = 1 件，已由 W83A 修掉（`8dc634b9254295f4`）**"，附"11 个无扩展名 ELF 产物属另一类"。
2. **可选的新牙（本件不建）**：一条只读核对器，判据 = "扩展名白名单内**不许**有件含 NUL 字节"，三态 `0/1/2`，自带 `--selftest`（含"注入 1 个 NUL ⇒ 必红"的成对反极性）。本件的 `$HOME/w83a-run/census2.py` 可直接当骨架；注意它的覆盖面要**排除 `upstream/`、产物目录**，且 `.log` 类的取舍要**写死在声明里**（否则就是"又一个手工维护的清单"）。
