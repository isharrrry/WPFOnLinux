# P1-tail2 · `T-A12` · native **枚举子段 ⇒ `cParas` 源**（缺省路径）—— native 主链实现

> **本件 `T-A12`（writer；本轮唯一写者）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 声明行；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ 本载体。**未碰** `build/*.Linux/**` 生成件（`PtsCache.Linux.cs` 等）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／任何 `.cs`；`git add/commit/push` **未做**。
> **判据载体**：`build/MilBridge/P1-tail2-fsqstd2-recon.md`（`T-A11`）§4.2 判据草案 `D1–D6` ＋ §5 `P8` 落点；`build/MilBridge/P1-tail2-default-chain-recon.md`（`T-A8`）§4.1 `S1–S5`；`LM-1`（裁定六十一，`build/MilBridge/P1-layout-model-report.md`）。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：全部走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`；**未跑**整趟 `verify-all`、**未跑** `static-jaws-check.sh`；写前 `cp -p` 备份；模式守恒（`stat -c %a` 前后 **644**）。

---

## §0 结论速览（自包含）

1. **做了什么**：在**缺省路径**（链已由 `T-A9` 驱动、驱动探针**窗内**在跑）里，让 native **主动真枚举子段**——
   - **`E1` 枚举**：新增 `wpf_pts_sub_enum()`，在 `wpf_pts_drive_probe()` **窗内**用托管回调 `+136 pfnGetFirstPara`／`+144 pfnGetNextPara`（帧 B 偏移**在册**：`_Static_assert(… +104 == 144)`）**真枚举**该子轨段落的子段，**穷尽才成功**（`rc≠0`／超界／成环 ⇒ `ok=0`）；计数即 `cParas` 的**唯一来源**（`[SUBENUM] … ok=1 v=ENUM-OK`）。
   - **`E2` 源绑进对象**：枚举结果（计数 ＋ 子段句柄序）绑进 `FSPARALIST` 交给消费者的那个**本侧自有子轨对象**（`c_paras`／`formatted`／`enum_ok`＋`children[]`）；`formatted=0`⇒仍按"未造型"拒。
   - **`E3` 承重格放行**：`FsQuerySubtrackDetails` 新增**成功分支** —— `认领 ∧ formatted ∧ enum_ok` ⇒ 写出参（`cParas`＝**枚举计数**）＋ `rc=0`；否则**逐字保持**旧的三路拒绝（**出参一字不写**）。
   - **`E4` 配对入口**：新增导出 `FsQuerySubtrackParaList`（`PtsHelper.cs:633` 的唯一调用点）—— `cParas>0` 后**必被调**，缺它会把"缺口"退化成 `EntryPointNotFoundException`。
2. **验收全绿／部分**（逐条证据见 §2）：
   - ① `D1–D6` 逐条现取读数 ＋ **反极性**：**6/6 有反极性腿或现成反证**（其中 2 条**实跑必红**：`rev-fake999` ⇒ `cparas-mismatch`；`rev-zero` ⇒ **`app_rc=134`／`alive=no`**）。见 §3。
   - ② **缺省路径 `cParas` 真枚举成功**：`[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 v=ENUM-OK`；值 **`cParas=3`**（另一 doc `cParas=1`）；对象身份证据见 §2 ②。**✅**
   - ③ **导出面**：`nm -D --defined-only` **671** == `bin/exports.txt` **671**；逐名对拍**恰 +1**（`FsQuerySubtrackParaList`）、**零消失**；`pts-gap-decl.txt` 声明行**同趟随动且与现算逐字段全等**（无 `DRIFT`）。**⚠️ `PTSGAP=PASS` 未达成**：唯一失败项 ＝ **复述位 16 处（6 件）**，其中 `docs/**`／`samples/**` 在**黑名单**内、且 `samples/…/KNOWN-DEFECTS.md:2258` 是**已立案的口径分歧行**（见 §6-1，**具名待裁决**）。
   - ④ **症状门与改前成对**：`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`ae`／`FRAME`／`FAILLINE`／`ENFE` **逐字段不变**（§2 ④）。
   - ⑤ `DEFREG` **rc=0**（`DEFREG=PASS declared=225 route_ids=225`）；`REPORTID` **rc=0**（`REPORTID=PASS files=304 …`）。
3. **缺口面位移（如实记，**"计数下降 ≠ 能力前进"**）**：`[FSQSTD] rc=-10000` **1217 → 427**；新出现 `[FSQSPL] rc=0` **988**；`[HC-UNHANDLED]` **1217 → 988**，且**组成变了** —— `PtsException(-10000)` 1217→**427**、**新增 `ArgumentOutOfRangeException` ×561**（首帧 `ArgumentOutOfRangeException.ThrowGreaterEqual[T]`，与 `[FSQSPL]` 相邻）。**页仍没绘出内容**（`magenta=0`／`colors=383`／`ink=480000`／帧 `ef3fd6765f18f51b` 与改前**逐字节相同**）。
4. **主动披露（待裁决）**：① `PTSGAP=PASS` 与黑名单冲突（§6-1）；② 反腿期间**临时**换主链 `.so`，收尾**逐字节还原**（§6-2）；③ 新增 `ArgumentOutOfRangeException` 是**新缺口类别**（§6-3）。

---

## §1 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` = **`242 28`**（全为本件四项）；无"顺手优化"。

### 1.1 `E1`｜窗内真枚举（`+136`／`+144`）

- **帧 B 偏移在册**（`pfnGetNextPara` 绝对偏移 `+144`）：
```c
#define WPF_PTS_SNAP_IDX_GETNEXTPARA       13   /* 40 + 13*8 = 144 */
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETNEXTPARA  * 8 == 144, "下标 GETNEXTPARA 对应绝对偏移 != +144");
```
- **回调签名**（承上游 `PtsHost.cs:613` `GetNextPara(pfsclient, nms, nmpCur, out fFound, out nmpNext)`）：
```c
typedef int (*wpf_pts_fn_get_next_para)(const void *pfsclient, const void *nms, const void *nmp_cur,
                                        int *f_found, void **nmp_next);
_Static_assert(sizeof(wpf_pts_fn_get_next_para) == 8, "回调指针不是 8 B（与快照的 8 B 字假设不符）");
```
- **枚举本体**（内容锚＝`static void wpf_pts_sub_enum(wpf_pts_doc *d, const void *container, const char *where)`）：
  口径写死五条 —— ①**只在窗内**（窗外 `+136` 实测 `-100002`）②**不用任何伪值／常数** ③**穷尽才算成功**（`rc≠0`／超界／成环 ⇒ `ok=0`、`cparas=0`）④**有界 `WPF_PTS_SUB_CHILD_MAX=32` ＋ 成环守卫** ⑤**失败必留痕**（每趟一条具名 `[SUBENUM]`）。
- **调用点**（内容锚＝`if (d->drive_nmp != NULL && !d->sub_enum_ok) wpf_pts_sub_enum(d, d->drive_nmp, where);`，紧随 `if (d->drive_nmp == NULL) d->drive_nmp = (const void *)nmp1;`）：`nmp1` 是真 `ContainerParagraph`（`[NMP-TYPE] … nmp=0x3 … nmp_isISegment=1`）⇒ 对 `ISegment` 成立。

### 1.2 `E2`｜结果绑进子轨对象

`wpf_pts_subtrack` 新增 `enum_ok`／`children[32]`／`child_clients[32]`／`child_clients_made`；`wpf_pts_doc` 新增 `sub_enum_ok`／`sub_cparas`／`sub_children[32]`／`sub_enum_rc136`／`sub_enum_rc144`／`sub_enum_v`。建对象处（内容锚＝`if (dp->sub_enum_ok) { dp->sub->enum_ok = 1; … }`）**仅当枚举穷尽**才置 `formatted=1`／`c_paras`；`[FSPARALIST-PARA]` 行的 `formatted=` 由**写死的 0** 改为**现读**（`formatted=1` 可机读）。

### 1.3 `E3`｜`FsQuerySubtrackDetails` 成功分支

四路判词（顺序写死）：`null-subtrack` → `unclaimable-subtrack` → `no-layout-content-model`（`!formatted` ∨ `!enum_ok`）→ `null-details-out` → **成功**：
```c
o->c_paras = obj->c_paras;   /* ← 承重格：枚举计数（真值来源） */
o->nms = dpx ? (void *)dpx->drive_nmseg : NULL;   /* 透传 +80 live nmSegment */
o->u=0; o->v=0; o->du=WPF_PTS_FSP_FIN_DU; o->dv=WPF_PTS_FSP_FIN_DV;  /* 本侧声明几何 */
o->fskupd=0; o->dvr_shifted=0;   /* NOINFO-FSUPDINF-* */
```
**先 `memset` 清零再逐字段写**；拒绝面**仍一字不写**（`out=UNWRITTEN bytes=0`）。

### 1.4 `E4`｜`FsQuerySubtrackParaList`（**新导出**）

`pfsparaclient` **只由本 run 托管 `+176` 现造**（跨调用复用，不重复造／不返回前回收）；`pfspara`／`nmp` ＝窗内枚举出的子段句柄；`cParas != obj->c_paras` ⇒ `cparas-mismatch` **拒**（**这正是伪真值的牙**，§3 `D1` 反极性）；`dvrUsed`／`dvrTopSpace`／`bbox` **无几何源** ⇒ `0` ＋ 具名 `NOINFO-SUBTRACK-PARA-GEOMETRY`。`k_pts_entries[]` 同趟增名（`WPF_PTS_ENTRY_COUNT` 20→21；`G10` 名单面随动）。

---

## §2 验收标准 ①–⑤ → 证据映射（可复跑单行命令原文 ＋ 原始输出）

> 证据脚本／私有 app 副本落**仓外私有目录** `/home/links-dev/tA12-work/`；重活全走槽；显示号只用空闲 `:231`；**未跑**整趟 `verify-all`。

### ②③ 构建（走槽）＋ 导出面

```
$ bash /home/links-dev/tA12-work/build.sh
== 链接 -shared -Wl,--no-undefined
== 产物：bin/libwpfwin32.so（411352 字节）
== 导出符号总数：671
```
```
$ cd src/WpfGfx.Linux.Native
$ sha256sum bin/libwpfwin32.so | cut -c1-16     # ⇒ e887b27a86b275ff
$ nm -D --defined-only bin/libwpfwin32.so | wc -l   # ⇒ 671
$ wc -l < bin/exports.txt                            # ⇒ 671
$ diff /home/links-dev/tA12-work/bak/exports.txt.orig bin/exports.txt
105a106
> FsQuerySubtrackParaList
```
⇒ 验收③（导出面）**成立**：**671 == 671**；逐名对拍**恰 +1、零消失**；`Stat` 前后 **644**。

```
$ bash /home/links-dev/tA12-work/pts-gap-count-check.sh 同源（仓内 build/MilBridge/tools/pts-gap-count-check.sh）
LIVE  tool=88 dead=11 artifact=1 ops=76 impl=79 so16=e887b27a86b275ff exports=671
  DRIFT …（**零 DRIFT**：声明行 == 现算，逐字段全等）
  SITE-DRIFT docs/ROUTES.md tool want=88 got=89 ……（**仅复述位**，详见 §6-1）
PTSGAP=FAIL tool=88 dead=11 artifact=1 ops=76 impl=79 so16=e887b27a86b275ff exports=671
```
⇒ 声明行**同趟一致**（`PTSGAP-DECL: tool=88 dead=11 artifact=1 ops=76 impl=79 so16=e887b27a86b275ff exports=671 w66pre16=bf6b683d94549087`，**无 DRIFT**）；**`PTSGAP=PASS` 未达成**（唯一原因＝复述位 16 处／6 件，其中 2 件在黑名单）⇒ 如实报、具名待裁决。

### ② 缺省路径 `cParas` **真枚举成功**（机读行原文 ＋ 值 ＋ 对象身份证据）

**腿**：规范腿器 `run-pts-pages-legs.sh`（A 臂，`k=24`／`k=23`），**不设** `WPF_PTS_DRIVE_PROBE`（缺省路径）；`.so`＝`e887b27a86b275ff`／`pf=1757d610a687777c`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`。

**(a) 枚举现取（窗内）**：
```
[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=1 ok_n=1 gap=0 window=in
[SUBENUM] where=FsCreatePageFinite   container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=2 ok_n=2 gap=0 window=in
[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=1 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=3 ok_n=3 gap=0 window=in
```
⇒ **值**：`cParas` ∈ {**3**, **1**}（按 doc 逐值不同 ⇒ **非全局常数**）；`rc136=rc144=0`（**真回调真返回**）；`ok=1 v=ENUM-OK`（**穷尽**）。

**(b) 承重格现取（消费者）**：
```
[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=0x604fde836300 psub=0x604fddf9a224 calls=1 ok=1 gap=0 null=0 unclaim=0 unformatted=0 out=WRITTEN bytes=40 cParas=3 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)
[FSQSTD-SRC] cParas=3 src=subenum(+136/+144) du=768 dv=576 nms=0x2 NOINFO=fsupdinf(no-source),fsrc(declared-geometry)
```
（末次样本：`calls=1415 ok=988 gap=427 … cParas=1 true_cParas=1`。）

**(c) 对象身份证据（`D4` 口径：只许靠来源证据）**：
```
[FSPARALIST-PARA] psub=0x604fddf9a224 pre=(nil) src=native-owned-subtrack same_value=1 acc=-12345 claims=1 rejected=0 hold=0 released=0 ctx=0x604fde836300 para_src_row=DRIVE-PROBE2.nmp1/DRIVE-PROBE3.nmp176 off_pfspara=8 form=native-owned-subtrack seq=5 live=1 created=5 destroyed=4 formatted=1 reused=0 v=ACCEPT-OTHER
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 … bytes0_32=00 … e4 71 e3 6b 53 58 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00
```
⇒ `[FSQSTD].psub` **逐字等于** `[FSPARALIST-FILL]` 的 `pfspara`（`0x604fddf9a224`）⇒ **值确实流到了消费者**；`wpf_pts_sub_claim` **唯一认领**（`claims=1 rejected=0`）。

⇒ 验收② **成立**（真枚举成功 ＋ 值 ＋ 身份证据）。

### ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**成对**读数

**成对口径**：同装置（`:231`）／同腿器（`run-pts-pages-legs.sh` `sha16=330a90f1f0ac28e4`）／同 `pf`（`1757d610a687777c`）；**单变量＝主链 `.so` 换代**。

| 字段 | **改前** `33c3bb7e8365835d`（`T-A10` 在册两腿，k23／k24） | **改后** `e887b27a86b275ff`（本席同趟，k23／k24） | 判 |
|---|---|---|---|
| `alive` | yes／yes | yes／yes | **不变** |
| `app_rc` | 143／143 | 143／143 | **不变** |
| `magenta` | 0／0 | 0／0 | **不变** |
| `colors` | 383／383 | 383／383 | **不变** |
| `ink` | 480000／480000 | 480000／480000 | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | **不变** |
| `ae` | 0／15386 | 0／15386 | **不变** |
| `FRAME fr_sha` | `ef3fd6765f18f51b`（两 k 同值） | 同 | **不变** |
| `FRAME fr_ae_boot` | 15386／15386 | 同 | **不变** |
| `FAILLINE failfast／unrec` | 0／0 | 0／0 | **不变** |
| `ENFE_TOTAL`（`entry point named`） | 0 | **0** | **不变** |

⇒ 验收④ **成立**：症状门**逐字段不变**（仅"缺口面"变，见下）。

**缺口面（如实位移）**：

| 读数 | **改前** `33c3bb7e8365835d`（缺省，`T-A10` 在册） | **改后** `e887b27a86b275ff`（缺省·样本1） | **改后**（缺省·样本2） |
|---|---|---|---|
| `[FSQSTD] rc=-10000` | **1217** | **427** | **347** |
| `[FSQSTD] rc=0` | 0 | **988** | **911** |
| `[FSQSPL] rc=0` | 0（入口不存在） | **988** | **911** |
| `[HC-UNHANDLED]` 行数 | **1217** | **988** | **911** |
| ├ `PtsException(-10000)` | 1217 | **427** | **347** |
| └ `ArgumentOutOfRangeException` | **0** | **561**（**新类别**） | **564** |

### ⑤ 两道牙

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）                    # rc=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=304 ids=2215 declared=225 glob=build/MilBridge/*report*.md   # rc=0
```

---

## §3 `D1–D6` 逐条读数 ＋ 反极性（"该红必红"）

> **前置口径**：`D1–D6` 只在"**缺省路径**（不设 `WPF_PTS_DRIVE_PROBE`）"下取数；任何绿**只准**读成"该入口在缺省路径不再拒绝、且行为可读"，**不得**读成"排版打通"。

### `D1` 承重格（`cParas`）—— **由"无源 ⇒ 必拒"翻为"有源 ⇒ 放行"**✅
- **正**：缺省路径 `[FSQSTD] rc=0 … cParas=3 true_cParas=3`（**988／911**，两样本）；`ok=1`。
- **反极性①（伪真值，**实跑必红**）**：副本 `-DWPF_PTS_SUB_CPARAS_FAKE=1`（`cParas` **恒 999**）：
```
[FSQSTD] rc=0 … cParas=999 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)
[FSQSPL] rc=-10000 reason=cparas-mismatch entry=FsQuerySubtrackParaList … cParas=5→(样本：999) out=UNWRITTEN
（1015 行 `cparas-mismatch`；`[HC-UNHANDLED]`=1015 全 PtsException；症状门**不变**）
REV-SO=rev-fake999 sha16=8fa2124e4a2efa64
```
⇒ **必红**：伪真值**被本侧交叉核对当场拒**（`cparas-mismatch` ＋ `out=UNWRITTEN`），**不许静默通过**。
- **反极性②（写 `cParas=0`＝P8 命名的那条，**实跑必红**）**：副本 `-DWPF_PTS_SUB_CPARAS_FAKE=2`：
```
[FSQSTD] rc=0 … cParas=0 true_cParas=3 …（只 3 行，此后消费者走叶子支）
[FSQSPL] = 0 行（**静默丢整棵嵌套**：`FsQuerySubtrackParaList` 一次都不被调）
LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=…FlowDocumentDemo ae=480000 ink=0
FAILLINE k=24 failfast=4 unrec=2   ｜ LEGS_RUNNER=FAIL requested=2 obtained=1 refused=1
REV-SO=rev-zero sha16=97c2a5e4eb6ab73f
```
⇒ **必红**：**`app_rc=134`（`ABORT`）／`alive=no`** —— 与硬边界"写 `cParas=0` ⇒ 叶子支静默丢嵌套（`P8` 必红）"逐字对应。

### `D2` 零假值／出参纪律 —— **成立**✅
- **正**：成功路径**先 `memset` 清零再逐字段写**（`out=WRITTEN bytes=40`）；拒绝路径**一字不写**（`out=UNWRITTEN bytes=0`，`unclaimable-subtrack` 427 行）；`[FSPARALIST-FILL]` 的 `bytes0_32` 前 8 B `00…`＝清零残迹。
- **反极性**：`rev-fake999` ⇒ 伪值**必然**在下游被检出并拒（`cparas-mismatch` ＋ `out=UNWRITTEN`）；`rev-zero` ⇒ 谎值**必然**在进程层爆红。**未**构造"给拒绝路径补写 out"的"静默半填"副本 ⇒ 具名 `NOINFO(未构造：需另立一份产物)`,**如实记**。

### `D3` 失败必留痕 —— **成立**✅
- **正**：每个拒绝路径**必有**具名行 ＋ 计数：`[FSQSTD] rc=-10000 reason=unclaimable-subtrack … gap=427`（`gap` 恰涨 1，单调）；`[FSQSPL] rc=-10000 reason=<具名>`（`gap` 单调）；两入口**都不静默**。
- **反极性**：**静默 stub**（返非 0 零痕迹）**未构造** ⇒ 具名 `NOINFO(照 T-A9 §3-D3 同处置)`；现取可证的只是"留痕与计数一一对应"。

### `D4` 身份只许靠来源证据 —— **成立**✅（含**现成反证**）
- **正**：`psub` 经 `wpf_pts_sub_claim` **唯一认领**（`claims=1 rejected=0`，`src=native-owned-subtrack`）；子段句柄来自窗内 `+136`／`+144`（`[SUBENUM] first=0x4`）。
- **反极性（现取即反证）**：`FsQuerySubtrackParaList` 交给消费者的 `pfspara` 是**托管子段句柄**（如 `0x4`）⇒ 下游 `ContainerParaClient.OnArrange` 再问 `FsQuerySubtrackDetails` 时，**该值不在本侧台账** ⇒ **必被拒**：`[FSQSTD] rc=-10000 reason=unclaimable-subtrack … psub=0x4`（**427** 行）⇒ **身份不靠数值大小／不靠 `rc`，只靠来源证据**。

### `D5` 闸关与闸开分开报（`P13`）—— **成立**✅
- **改前（缺省）**：恒 `paraclient-table-not-native`（`T-A10` 在册 1054／`T-A9` 897/1099）。
- **改后（缺省）**：`[SUBENUM] ok=1` ＋ `[FSQSTD] rc=0`。
- **反极性（同 `.so`，单变量＝`WPF_PTS_DRIVE_PROBE=0`）**：
```
$ bash /home/links-dev/tA12-work/legs-slot.sh off WPF_PTS_DRIVE_PROBE=0
[DRIVE-PROBE-SKIP]=3(gate-off)  [SUBENUM]=0  [FSQSTD]=0  [FSQSPL]=0  [FSPARALIST-FILL]=0
reason=paraclient-table-not-native 861 行  [HC-UNHANDLED]=861(全 PtsException)
症状门：alive=yes app_rc=143 magenta=0 colors=383 ink=480000 帧 ef3fd6765f18f51b（同）
```
⇒ **两路判词不同**（闸关＝**根本没走到**；闸开＝**认领∧已枚举∧放行**）；**不**把闸关的"没走到"记成"拒绝成功"。

### `D6` ≥2 独立样本 ＋ 幂等双调 —— **成立**✅
- **正**：两条**独立 PID／启动时刻**的缺省腿（`default` 12:27／`default3` 12:35），**判词相同**（`ENUM-OK`／`[FSQSTD] rc=0`／症状门同），**计数不同**（`988/427` vs `911/347`）＝运行期交互次数差异，**不**读成机制差异。
- **幂等**：`[SUBENUM] idem`（`+136` 两次同值）在册；本入口＝**查询**语义，同值双调见 `rc136a=rc136b=0 fSucc1=fSucc2=1 nmp1=nmp2`。
- **反极性**：单样本当机制 ⇒ 必红（`P9`）；本件**取了两条独立样本**，**未犯**。

---

## §4 件级前后对账

| 件 | 开工（`cp -p` 备份）`sha16` | 收尾（现取）`sha16` | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `c0dda70160ff1dc6`（4605 行） | **`a1820ad87bd63b79`**（4819 行） | **`git diff --numstat = 242 28`**；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `c963dc79e234278a` | **`7c9bc0733ab9ac08`** | **`git diff --numstat = 17 1`**（声明行 1 ＋ 追加 dated 重锚注释）；`%a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `f61b9b1e55fdc600`（670 行） | **`1113e6b1d9854f78`**（**671 行**） | **逐名 +1、零消失** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `33c3bb7e8365835d` | **`e887b27a86b275ff`**（411352 B） | **重建产物**（gitignored） |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `4576fc68bcbbf329` | **`4576fc68bcbbf329`** | **不变** ✅ |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | （未触碰） | `e5b399fdb8742092` | **未碰** ✅（不在写域） |

**备份路径**：`/home/links-dev/tA12-work/bak/{win32_pts.c.orig,pts-gap-decl.txt.orig,exports.txt.orig,libwpfwin32.so.orig}` ＋ `/home/links-dev/tA12-work/copy/main-e887b27a86b275ff.so`（反腿前的主链件备份）。

**`git status --porcelain`（现取）**：
```
 M docs/ROUTES.md                     ← **先于本件存在**（`T-A11` 落册时已 M），**非本件所改**
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
?? build/MilBridge/P1-tail2-cparas-impl-report.md   ← 本件
（另有 3 项先于本件存在的 `??`：`P1-tail2-fsqstd2-recon.md`／`tasks-tail2/T-A11.md`／`tasks-tail2/T-A12.md`／`evidence/arm_A/app_g1.log`）
```

---

## §5 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/*`（重建刷新）＋ 本载体。**未碰** `build/*.Linux/**`（生成件）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／`build-shim.sh`。
- **反极性腿的"副本产物"**：两条必红腿**只在副本**编译（`-DWPF_PTS_SUB_CPARAS_FAKE=1|2`，**绝不进主链**）。取证期间**临时**把主链 `.so` 换成副本、跑完**逐字节还原**（`RESTORED sha16=e887b27a86b275ff（对照备份 e887b27a86b275ff）`）——**如实披露**（§6-2）。
- **证据强度（如实划界）**："改前"读数取自**在册** `build/MilBridge/tests/PtsPagesProbe/evidence-tail2/app_g1.log`（`shim=33c3bb7e8365835d`／`log_sha16=5533298d4dc75eab`，`T-A10` 那趟）＝**在册证据的现核**，**非本席同趟重取**；"改后"读数＝本席**同趟新取**。两侧 `pf`／装置／腿器口径一致。

---

## §6 主动披露（待裁决）

1. **🔴 `PTSGAP=PASS` 与**黑名单**冲突（本件**未越域**）**：验收③ 要求 `PTSGAP=PASS`，而现取 `PTSGAP=FAIL` 的**唯一原因**＝**复述位 16 处／6 件**（`DRIFT` **零条**：声明行与现算逐字段全等）。6 件中 **`docs/ROUTES.md`／`docs/unimplemented.md` 在 `T-A12` ② 的黑名单 `docs/**` 内**，其余 4 件（`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）在"**只改**"白名单之外。⇒ 具名前置 **`PRECOND-REGISTERED-COUNTS-RESTATEMENT-OUTSIDE-WRITE-DOMAIN`**。**待随动的逐处清单（`tool 89→88`／`ops 77→76`／`impl 80→79`）**：
   - `docs/ROUTES.md:261`（`可操作缺口 77 条／实现口径 80 条`）、`:369`（`工具口径 **89**`／`**可操作 77**（`／`｜**实现口径 80**`）、`:516`（`**可操作 77 条／实现口径 80 条**`）；
   - `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2258`（`工具口径 **89**`）；
   - `README.md:23`（`**可操作 77／实现口径 80**`）；
   - `build/MilBridge/HANDOFF-NEXT.md:47`（同形）；
   - `src/WpfGfx.Linux.Native/src/win32_classification.c:52`（`可操作 77／实现口径 80 条`）；
   - `docs/unimplemented.md:555`（`工具报缺 **89**` ＋ `⇒ **可操作 77**`）。
   - ⚠️ **其中 `KNOWN-DEFECTS.md:2258` 是**已立案的口径分歧行**（`t104`／`t98` 的 `F-3`：**"历史行只描述它引用件那一代" vs "跟随现值"**；该件原文自带 `⏪ 口径分歧的实质（供队长裁）… 若再被覆盖，本席不再重试`）。`0aab811` 的落仓选择＝**跟随现值**（该行 `90→89`），本件**不擅自重演**该争议 ⇒ **请队长裁定后随动**。同形态先例：`T-A4`（`pts-gap-decl.txt` 内自陈"复述位在写域之外 ⇒ 已如实记、待裁决"）。
   - ⚠️ **`docs/ROUTES.md` 的"dated 落册行"亦同因未加**（`T-A9`／`T-A10`／`T-A11` 三件各在其落地时追加过一行；本件写域不含 `docs/**`）⇒ 请随落仓一并追加。
2. **反极性腿的"临时换件"**：为构造两条必红腿，本件在**取证窗口内**把主链 `bin/libwpfwin32.so` 临时换成副本产物（`8fa2124e4a2efa64`／`97c2a5e4eb6ab73f`），跑完**已逐字节还原**为 `e887b27a86b275ff`（现取回读 == 备份；私有 app 副本亦已 `sync-applocal` 复同步回主链件）。
3. **🔴 新增缺口类别（如实记，非本件"制造失败"）**：`[HC-UNHANDLED]` 组成由"**1217 全 PtsException**"变为"**427 PtsException ＋ 561 ArgumentOutOfRangeException**"（首帧 `ArgumentOutOfRangeException.ThrowGreaterEqual[T] … index ('0') must be less than '0'`，与 `[FSQSPL]` 行**相邻**）。口径：**这是"承重格放行 ⇒ 消费者继续往下走"才暴露的下一跳缺口**（改前 `FsQuerySubtrackDetails` 的 `-10000` **在第一步就把格式化掐断**）⇒ **"计数下降 ≠ 能力前进"，也"新异常类别 ≠ 本件造错"**。**未定位到具名模块** ⇒ 具名 `NOINFO(reason=no-managed-source-anchor-in-write-domain)`；**不得**据本条宣布任何进步（裁定三十六 (c)／四十二 (b) 冻结令维持）。
4. **`fsrc`／`fsupdinf` 的 `NOINFO`（沿用 `T-A11`）**：`fsrc`＝**本侧自定几何**（`du=768 dv=576`，`NOINFO-FSGEOMETRY-LAYOUT`，不与上游 ABI 可比）；`fsupdinf` **无源**（全树 0 消费者 ⇒ `NOINFO-FSUPDINF-CONSUMER`）⇒ 固定 `fskupdInherited/0` 并具名，**不假装拥有**（承 `LM-1` 准入铁律）。
5. **`FsQuerySubtrackParaList` 的子段几何无源**：`dvrUsed`／`dvrTopSpace`／`bbox` 保持 `0` ＋ 具名 `NOINFO-SUBTRACK-PARA-GEOMETRY`（**不**自造几何：那是"声称每段高 0"之外的另一类伪值）。⇒ 子段仍无几何 ⇒ 页仍**未绘出内容**。
6. **未跑**整趟 `verify-all`（任务明禁）；**未跑** `static-jaws-check.sh`（不加牙）；**未** `git add/commit/push`。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-cparas-impl-report.md | sha256sum | cut -c1-16`）= `33ab425584e71796`
