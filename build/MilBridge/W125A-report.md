# W125A 报告 —— 握手退让（`TASK`：清「构建产物区与仓外夹具同 inode」）

**结论先行：本车道按任务书握手第 2 条「立刻停手、退让、不许并跑」执行，未处置任何文件。**
理由＝**W123A 此刻正在处置同一批目标件**（`bin/`＋`obj/`＋6 件产品 DLL），有活进程为证（§2）。我全趟对 `$R` 的写入 = **仅本报告这一件新件**，**零 `cp`／零 `mv`／零 `rename`／零 `pkill`**，夹具侧只读过（`stat`／`sha256sum`）。

- 车道：**W125A**｜冻结基线 `#51 38e67e834430d75c`｜`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- 判据：`~/w125a/criteria.md`（**先写**，见 §1）｜进度凭据：`~/w125a/STATUS.md`
- 处置量：**0 件**（退让）｜本报告自身 sha16 见文末（现场算，未手抄）

---

## §1 判据（先写，未据此处置）

全文见 `~/w125a/criteria.md`（写于 09:02:4x，**早于任何动作**——本趟唯一动作就是退让）。要点：

1. **主判据（逐件、处置前后成对）**：R 侧 `cp -p` 到临时名 ＋ `mv` 覆盖后 ⇒ ①内容 `sha256sum` 前 16 位**逐位不变**；②`mode` 与 `mtime` **逐件保持**；③`links` **恰好 −1** 且 inode **必变**；④夹具侧 `sha256sum` 前后**逐位相同**且**绝不写**；⑤处置后该件与**任何仓外路径**不再同 inode。
2. **顺序**：先 6 件产品 DLL，再分批 `bin/`（2957）＋`obj/`（1631），每批报 `ok/skip/bad`。
3. **保护**：件被在跑的构建持有、或清它连带动到身份记录／`ARTIFACT-SRC-FP` 类判据 ⇒ **跳过单列**；写者自保用 `%i`＋`sha16` 双向守卫（`SKIP_CHANGED_UNDER_ME`）；一律 temp＋rename；备份到 `~/w125a/backup/`。
4. **两级化**：甲＝沙箱里"原地截断写 ⇒ 对手变"与"temp＋rename ⇒ 对手不变"成对；乙＝真树复枚举 ⇒ 跨区构建产物 = 0。
5. **`upstream/` 声明残留**（主控裁定逐字）：`upstream/**` 与夹具同 inode ⇒ **不破链，因为无写者**；**若将来有人要在 `upstream/**` 原地写，必须先破链**。
6. `NOINFO` 既不算绿也不算红。**并发写者介入时，"处置后"读数只有在该写者停止后取得才有效**——本趟正因此**未取**（这条就是退让的判据依据）。

---

## §2 握手读数（决定性问题：W123A 在做吗？）

### 2.1 第 1 查：`STATUS.md` 单看**不足以**判定（09:01:47）

```bash
stat -c '%y %s %n' ~/w123a/STATUS.md      # 2026-09-23 08:55:48 +0800   7069   (距今 5m59s，在 10 分钟内)
tail -5 ~/w123a/STATUS.md
```
`tail` 显示它**已经是收尾段**：`[T25] 08:56 收工复核` ＋ `## 未做` 段里**字面**写着「口径外 11011 件未处置（写域外，含 §6.1 的 6 件产品 DLL）」。
⇒ **命中 mtime 条件，但字面语义是"已收工、这批是未做"** ⇒ 任务书给的两个条件**互相矛盾**，我**不据此放行**，改用活进程判据（下一查）。**这是本件第一条方法论读数：`STATUS.md` 会滞后于实际进程，不能单独当握手凭据。**

### 2.2 第 2 查：活进程 ⇒ **它在跑**（09:01:5x）

```bash
ps -eo pid,ppid,lstart,etime,stat,cmd | grep w123a | grep -v grep
```
```
PID 337562  PPID 3952004  STARTED Wed Sep 23 09:00:43 2026  ELAPSED 01:23  STAT Ss
cmd = bash -c R=/home/... ; cd ~/w123a && awk -F'\t' '...' <(sed ... list.dlls.txt) target.partners.txt
      ... echo "  剩余批次的夹具侧对手路径数 =", len(keep) ... bash snap2.sh clean.F.txt clean.F.pre.tsv ...
子进程: 362167  bash snap2.sh clean.F.txt clean.F.pre.tsv   (ELAPSED 00:24)
```
逐字证据：`awk` 里有一句 `# 已清的那 6 件 DLL 的对手方，排除`，且注释为 **"剩余批次"** ⇒ 它**已经清完 DLL、正在为 `bin/`＋`obj/` 剩余批次取改前基线**。

### 2.3 它在写的中间件（只读）：6 件产品 DLL **已被它清完**（09:02:0x）

```bash
cat ~/w123a/list.dlls.txt                      # 6 行 = 主控点名的那 6 件（PC/PF/ReachFramework/Provider/WindowsBase/WpfGfx.Linux）
head -3 ~/w123a/dll.R.pre.tsv ; head -3 ~/w123a/dll.R.post.tsv
wc -l ~/w123a/skip.dlls.txt                    # 0
```

| 件（DLL） | R 侧 `links` 前→后 | inode 前→后 | sha16 前＝后 | mode/mtime |
|---|---|---|---|---|
| `DirectWrite.Linux.Provider.dll` | 3 → **1** | 5019103 → **5022299** | `1f9511a7ef395bfe` 相同 | 644／1789787649 保持 |
| `PresentationCore.dll` | 2 → **1** | 5126522 → **5144513** | `722e0ab8205b7c3f` 相同 | 644／1790080270 保持 |
| `PresentationFramework.dll` | 2 → **1** | 5018442 → **5022301** | `bc2c47ac7b067bad` 相同 | 644／1790080315 保持 |

⇒ **"已上膛未击发"那条最危险的 6 件，已由 W123A 断链完毕，`skip=0`**（这是本报告最有价值的一条：主控派的活**已经做掉了一半**，而我差点和它撞上）。

### 2.4 第 3 查：新活进程 ⇒ **它正在写 `bin/`／`obj/`**（09:02:52 → 09:03:34）

```bash
ps -eo pid,etime,stat,cmd | grep w123a | grep -v grep
```
```
09:02:52  PID 392386  etime 00:10  cmd 内含  B=/home/links-dev/w123a/backup-clean
          子进程 396802  cp -p -- .../build/MilBridge/tests/TextLineProto/bin/Debug/runtimes/...   STAT=D(不可中断I/O)
          ~/w123a/backup-clean/ 09:02:44 ｜ backup-clean.list.txt 09:02:52 (211841 B)

09:03:34  PID 409766  etime 00:16
          cmd = bash -c cd ~/w123a && for b in batch.bin.00 batch.bin.01 batch.bin.02 batch.obj; do echo "--- $b 开始 $(date '+%H%M%S')" ...
          ~/w123a/skip.batch.bin.00.txt  09:03:17 (0 B)  ⇒ 第一批已开始
          find $R -name '*.w123a-tmp*' | wc -l  =  1   ⇒ R 里正有它的半成品临时件
```

**判定：W123A 在 09:00:43–09:03:34 全程活着，且在 09:02:44 之后进入 `bin/`／`obj/` 批次处置；我的目标件就是它的目标件。** 依任务书握手第 2 条 ⇒ **我退让，不并跑**（同一批文件两个写者 = 事故）。

---

## §3 处置前枚举（**未做完整枚举**，只给能安全取到的部分 ＋"没扫什么"）

**没扫什么**：我没有跑"全 R 跨区件"枚举（口径内 13375 件级、含 `stat` 逐件），因为①**W123A 正在改这批件**，任何此刻的读数**在它停下来之前都是中间态**；②枚举会与它的快照争 I/O。⇒ 完整枚举**移交**（它自己 `snap2.sh` 产出的 `clean.R.pre.tsv`／`clean.F.pre.tsv` 就是权威版）。

能安全取到的（只读）：

| 读数 | 值 | 来源命令 |
|---|---|---|
| `bin/` 批次 | **2957** | `wc -l ~/w123a/batch.bin.all.txt` |
| `obj/` 批次 | **1631** | `wc -l ~/w123a/batch.obj.txt` |
| 剩余批次合计（＝R 侧待清） | **4588** | `wc -l ~/w123a/clean.rem.R.txt` |
| 夹具侧对手路径 | **4588** | `wc -l ~/w123a/clean.F.txt` |
| R `build/**/{bin,obj}` 下 `links>1`（09:02:5x 现场，**中间态**） | **2454** | `find $R/build -type d \( -name bin -o -name obj \) -prune -print0 \| xargs -0 -I{} find {} -type f` ＋ 逐件 `stat -c %h` |
| 口径外 `upstream/` | **6417** | W123A `STATUS.md` `[T23] 08:54`（我未复算，标**引用**） |

主控点名 4 件**现况**（只读，09:02:5x）：

| 件 | R 侧 | 夹具侧 | 判定 |
|---|---|---|---|
| `libwpfwin32.so` | ⚠️ **主控给的路径不存在**——真身在 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `~/w113a/fixture/repo/src/WpfGfx.Linux.Native/bin/libwpfwin32.so` `links=1 ino=5018302` | **已独立**（路径更正见 §8） |
| `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` | `links=1 ino=5144513` | `links=1 ino=5126522` | **已独立** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `links=1 ino=5022301` | `links=1 ino=5018442` | **已独立** |
| `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` | `links=1 ino=5144515` | `links=1 ino=5126541` | **已独立** |

⇒ **主控任务书里"仍共享 `2/5126522`"那三个读数已经过时**：它们现在是 `links=1` 且 inode 与夹具不同（W123A 在 08:57:57–08:58:03 清掉的，见 §2.3）。**夹具侧那三个 inode（5126522／5018442／5126541）与主控给的值逐位相同 ⇒ 夹具侧未被写。**

---

## §4 逐件/逐批处置前后 `stat` ＋ 两侧 sha16 对照

**未做 —— 因退让，我没有处置任何件**，故没有"我的处置前后"对照。可提供的是 **W123A 的第三方读数**（§2.3，6 件 DLL：`links` −1、inode 变、sha16 不变、mode/mtime 保持、`skip=0`）与 **W123A 自己落的 `clean.R.pre.tsv`／`clean.F.pre.tsv` 成对基线**（09:01:42／09:02:35，`4588` 件同批）。接手者应以**它停止后**的 `clean.R.post.tsv`／`clean.F.post.tsv` 为准。

---

## §5 两级化

### 5.1 甲·写穿是真的（**已做**，`~/w125a/sandbox/`，零接触 `$R` 与夹具）

装置在**我自己的目录**里，与 `$R`／夹具无任何接触（故与 W123A 不构成并跑，**在退让判定之后补做**，如实标注）：

```bash
cd ~/w125a/sandbox && printf 'ORIGINAL-CONTENT-v1\n' > a && ln a b
stat -c 'links=%h ino=%i %n' a b          # links=2 ino=5395198 a ／ links=2 ino=5395198 b
sha256sum a b | cut -c1-16                # 两侧同为 1d0b5df096de2aa2
```

**甲① 原地截断写**（`printf ... > a`，即 `open(...,'w')`／`sed -i` 形态）：

| 步 | a sha16 | b sha16 | b 内容 |
|---|---|---|---|
| 写前 | `1d0b5df096de2aa2` | `1d0b5df096de2aa2` | `ORIGINAL-CONTENT-v1` |
| 写后 | `2a84c6538c9b2683` | **`2a84c6538c9b2683`** | **`MUTATED-BY-TRUNCATE`（被改）** |

⇒ **`WRITE_THROUGH=YES`**：只写 `a`，**对手 `b` 当场跟着变** —— 这就是"打穿夹具"的机制。

**甲② temp＋rename 写**（本件修法；装置重置回 `links=2 ino=5395198`／两侧 `1d0b5df096de2aa2`）：

| 项 | a | b |
|---|---|---|
| sha16 写后 | `9e82963de29749a7`（新内容） | **`1d0b5df096de2aa2`（逐字节未变）** |
| inode | `5395199`（**换了**） | `5395198`（不变） |
| `links` | **1** | **1** |
| 内容 | `MUTATED-BY-TEMP-RENAME` | `ORIGINAL-CONTENT-v1` |

⇒ **`WRITE_THROUGH=NO`**：`rename` 换的是目录项 ⇒ 对手拿到**独立 inode**，逐字节不受影响。**甲的两极成对成立。**

### 5.2 乙·真树已断 —— **未做**（`NOINFO`）

真树复枚举**在 W123A 停手前跑出来的是废数**（它当时正在 `batch.bin.00/01/02/obj` 内逐个 `cp -p`＋`sha256sum`），故我**不取**。可用的替代凭据＝W123A 自己的 `clean.R.pre.tsv`(09:01:42)／`clean.F.pre.tsv`(09:02:35) 及其后续 post 对；接手者应以**它进程退出后**的读数为准。读数**标 `NOINFO`**，不许推断填空。

---

## §6 清完牙读数

**未跑**。`bash build/MilBridge/tools/hygiene-tooth.sh` 是只读复跑，但**此刻跑出来的 `multilink=`／`cross_region=` 是中间态废数**（W123A 正改这批件）⇒ 我**不取**，避免产出误导读数。

已只读核对：牙件 `build/MilBridge/tools/hygiene-tooth.sh` sha16 ＝ **`dc1e79a23dbb7eb2`**，与任务书给的值逐位相同 ⇒ **未被本趟改动**（`sha256sum ... | cut -c1-16` 现场算）。

---

## §7 `upstream/` 声明残留（按主控裁定逐字落文）

> `upstream/**` 与夹具同 inode ⇒ **不破链，因为无写者**；**若将来有人要在 `upstream/**` 原地写，必须先破链**。

现场数：**6417**（来源＝W123A `STATUS.md [T23] 08:54`，**我未复算**，标"引用"）。对手方分布：**未取**（`NOINFO`，我未跑夹具侧枚举，避免与 W123A 争 I/O）。本条**已声明**，不由本车道处置。

---

## §8 跳过件清单与理由 ＋ 一条路径更正

- **跳过件清单**：不适用（我未进入处置阶段）。真正的"跳过"发生在**车道级**：**整条 W125A 跳过处置**，理由 ＝ 与 W123A 目标件完全重叠（`bin/`／`obj/`／6 件 DLL 同一批）。
- **路径更正（推翻主控任务书一句）**：任务书写的 `libwpfwin32.so` 在 R 侧 `.../src/WpfGfx.Linux.Native/build/` —— **该路径不存在**（`statx: 没有那个文件或目录`）；真身是 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`。
- **另一条更正**：任务书给的"`PresentationCore.dll`／`PresentationFramework.dll`／`WindowsBase.dll` 仍共享 `2/<ino>`"**已过时**（现 `links=1`、inode 与夹具不同），成因＝W123A 08:57:57–08:58:03 的 DLL 批。

---

## §9 `NOINFO` 与未做（逐条）

| 项 | 状态 | 原因 |
|---|---|---|
| 完整处置前枚举（全 R 跨区件逐件 `stat`） | **未做** | 有并发写者；正确版本在 W123A 的 `clean.*.pre.tsv` |
| 我的逐批 `ok/skip/bad` | **NOINFO** | 未处置 |
| 甲·沙箱写穿实验 | **已做（两极成对成立）** | 在我自己目录内，零接触 `$R`／夹具（§5.1） |
| 乙·真树复枚举 | **未做** | 退让；并发写者停手前是废数（§5.2） |
| 牙读数（`HYGIENE_TOOTH`／`HYGIENE_INODE`／`multilink`／`cross_region`） | **未取** | 中间态；且**未跑**以免产出废数 |
| `upstream/` 对手方分布 | **NOINFO** | 未跑夹具侧枚举 |
| 夹具侧是否被写 | **已核：未被写**（三个 inode 与主控值逐位相同） | `stat` 只读 |
| 我是否 `pkill`／碰禁改件 | **没有**；`R` 内我造的 `.w123a-tmp` 残渣 = 0（现场那 1 个是 W123A 的） | `find` 只读 |
| 对 `$R` 的写入 | **仅本报告**（1 件新件，`links=1`，不进 `bin/`/`obj/`，不影响 `multilink` 口径） | — |

---

## §10 复算命令（逐条，接手者可直接跑）

```bash
# 1) 握手：W123A 是否在做（活进程判据，比 STATUS.md 可靠）
ps -eo pid,etime,stat,cmd | grep w123a | grep -v grep
# 2) 它在写什么（它的中间件，只读）
ls -lt --time-style=+%H:%M:%S ~/w123a/ | head -12
# 3) 6 件 DLL 已清的证据（links 前→后、sha16 前=后）
paste <(head -6 ~/w123a/dll.R.pre.tsv) <(head -6 ~/w123a/dll.R.post.tsv)
# 4) 批次规模
wc -l ~/w123a/batch.bin.all.txt ~/w123a/batch.obj.txt ~/w123a/clean.rem.R.txt ~/w123a/clean.F.txt
# 5) 主控点名件的现况（R 侧 vs 夹具侧 inode）
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
stat -c '%h %i %n' $R/build/PresentationCore.Linux/bin/Release/PresentationCore.dll \
                   ~/w113a/fixture/repo/build/PresentationCore.Linux/bin/Release/PresentationCore.dll
# 6) 牙件未被改
sha256sum $R/build/MilBridge/tools/hygiene-tooth.sh | cut -c1-16   # dc1e79a23dbb7eb2
# 7) 退让期间我在 R 内的临时残渣
find $R -name '*.w125a-tmp*' | wc -l    # 0
```

---

## §11 大白话小结（≤6 行）

1. 任务书让我先握手：**结果 W123A 正在做这件事，我就没动手**——这是对的，两个写者抢同一批文件会出事故。
2. 它比任务书写得走得远：**主控点名的那 6 件产品 DLL 它 08:57 就已经清完了**（`links` 掉到 1、inode 换了、内容 sha16 一字未变、一个都没跳过）。
3. 09:02:44 起它进了 `bin/`＋`obj/` 共 **4588 件**的批次，我 09:03:34 还看到活进程在跑 `batch.bin.00/01/02/obj`，现场有半成品临时件。
4. 所以主控给我的三个"仍共享 2/<ino>"读数**已经过时**（现在都独立了）；夹具侧 inode 与主控给的值逐位相同 ⇒ **夹具没被写**。
5. 我按纪律退了：**只写了 `STATUS.md`／`criteria.md`／本报告**，`$R` 内 0 处置、0 `pkill`、0 残渣；唯一补做的是**沙箱写穿实验**（在我自己目录里，两极成对：原地截断写 ⇒ 对手当场被改 `2a84c6538c9b2683`；temp＋rename ⇒ 对手一字不变 `1d0b5df096de2aa2`）；真树复枚举／牙读数**标未做/NOINFO**，没有编数。
6. 一条要改的路径：`libwpfwin32.so` 在 `src/WpfGfx.Linux.Native/`**bin**/` 下，任务书写的 `.../Native/build/` 不存在。

---
*报告 sha16（口径＝本文件全文，去掉本行）：见 `~/w125a/W125A-report.selfsha`（现场 `sha256sum` 计算，未手抄）。*
