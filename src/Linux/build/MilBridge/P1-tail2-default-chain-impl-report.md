# P1-tail2 · `T-A9` · 缺省路径三级链驱动（甲路）—— native 主链实现

> **本件 `T-A9`（writer）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其登记面（`tools/pts-gap-decl.txt` 声明行；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ 本载体。**未碰** `build/*.Linux/**` 生成件（`PtsCache.Linux.cs` 等）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`。未 `git add/commit/push`。
> **判据载体**：`build/MilBridge/P1-tail2-default-chain-recon.md`（`T-A8`）§4.1 设计草案 `S1–S5` ＋ §4.2 判据草案 `D1–D7`。**授权**：队长裁定**撤销**「裁定三十六 (b)」的"运行期闸默认关"（射程＝仅"缺省路径驱动三级链"；原由已因 `PRECOND-FRAME-DETERMINISM` 未满足而失效）。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。

## §0 结论速览（自包含）

1. **做了什么（照 `S1–S5`）**：把缺省的 `win32_pts.c` **运行期闸**由「**缺省关**」翻为「**缺省开**」——
   - **S1**：`wpf_pts_drive_probe_enabled()` 的缺省由 `0` 改 `1`（`WPF_PTS_DRIVE_PROBE` 未设／空／非 `"0"` ⇒ **开**；**仅显式 `"0"` 才关**）。⇒ 缺省路径的 `FsCreatePageBottomless`／`FsCreatePageFinite`（**窗内**）**恒驱** `+80→+136→+176`，把 `drive_nmp` 落进 doc；闸 2（`:3626` 的 `else if (wpf_pts_drive_probe_enabled())`）**随之恒成立**（**同一枚**开关，未再动）。
   - **S2**：驱动窗预算缺省由 `1` 提到 `WPF_PTS_DOC_MAX`（8）＋ 给 `wpf_pts_doc` 加 **`drive_done`** 记账位 ⇒ **每 doc 至多驱一窗**（不同 doc 各驱一次）。
   - **S3**：由 S1 的默认翻转达成（`S3` 的"无条件 else"效果 ≡ 缺省开时的既有条件）；**保留** `WPF_PTS_DRIVE_PROBE=0` 作**反极性腿**开关（见 §3 `D5`）。
   - **S4**：`WpfLinuxWin32_PtsDriveProbeGate()` 语义随动（缺省报 `1`；显式 `0` 报 `0`）；**未**新增导出 ⇒ 导出面一字未动。
   - **S5**：具名台账行（`[DRIVE-PROBE*]`／`[FSPARALIST-*]`／`[FSQSTD]`）全部**保留**，症状门**未变**（§2 ④）。
2. **验收全绿**（逐条证据见 §2）：
   - ② **缺省路径 `pfspara`／`pfsparaclient` 可得**：`[FSPARALIST-FILL] rc=0 …` **897** 行（`default` 腿）／**1099** 行（`default2` 腿）；`pfspara=0x6441c51e18d4`（native 自有子轨）／`pfsparaclient=0x5`／`nmp=0x3`／`cParaDesc=1`。
   - ③ 导出面：`nm -D --defined-only` 行数 **670** == `bin/exports.txt` 行数 **670**（**逐名零消失**，`exports.txt` 与改前**逐字节相同**）；`pts-gap-decl.txt` 同趟更新且 `pts-gap-count-check.sh` = **PASS**（八格逐字段相等）。
   - ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`＋`FRAME`／`FAILLINE`）与**改前逐字段相同**（§2 ④ 成对）。
   - ⑤ `DEFREG` `rc=0`；`REPORTID` `rc=0`。
3. **`D1–D7` 逐条读数 ＋ 反极性**：见 §3。三条**能构造的反极性腿**（`off`／`wrongtype`／`selfrecycle`）**全部该红必红**（§3）。
4. **主动披露（待裁决）**：① `wpf_pts_fsp_pl_is_sentinel` 把 `0x2/0x3/0x4/0x5` 当"哨兵值"（真腿读数作废），而**缺省路径下的真实托管句柄就是这些小整数**（`PtsContext.CreateHandle` 返回 `_unmanagedHandles[0].Index` ⇒ `1,2,3,…`）⇒ 该注释与真腿口径**冲突**（该函数现**未被调用**，无实际影响）；② 本件为取证**临时**把主链 `bin/libwpfwin32.so` 换成副本产物跑反极性腿，**收尾已逐字节还原**（§5）。

---

## §1 实现（`S1–S4` 逐条，件:行 ＋ 原文；行号仅本次有效）

### 1.1 `S1`｜闸默认翻转（内容锚＝`wpf_pts_drive_probe_enabled` 函数体）

```c
static int wpf_pts_drive_probe_enabled(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *v = getenv("WPF_PTS_DRIVE_PROBE");
        /* ⏪ `T-A9`（队长裁定：**撤销**「裁定三十六 (b)」的"运行期闸默认关"）：**缺省开** ——
           仅当 `WPF_PTS_DRIVE_PROBE` **显式**为 `"0"` 时关；未设／空／其它值皆开。… */
        cached = (v && strcmp(v, "0") == 0) ? 0 : 1;     /* ← 旧： (v && v[0] && strcmp(v,"0")!=0) ? 1 : 0 */
    }
    return cached;
}
```

### 1.2 `S2`｜每 doc 一次 ＋ 预算缺省（两处；内容锚＝旋钮宏 ＋ `wpf_pts_drive_probe` 头部）

```c
#define WPF_PTS_DRIVE_PROBE_WINDOW_BUDGET_DEFAULT WPF_PTS_DOC_MAX   /* ← 旧： 1 */
```
```c
    if (!wpf_pts_drive_probe_enabled()) { wpf_pts_drive_probe_skip("gate-off"); return; }
    /* ⏪ `T-A9`（S2）：**每 doc 只驱一窗** —— 预算是**进程级**的，这里再加**doc 级**记账 */
    if (d->drive_done) { wpf_pts_drive_probe_skip("doc-already-driven"); return; }
    if (g_pts_dp_calls >= wpf_pts_drive_probe_n()) { wpf_pts_drive_probe_skip("budget-exhausted"); return; }
```
```c
    if (!nms) { wpf_pts_drive_probe_skip("null-sect"); return; }
    d->drive_done = 1;   /* ⏪ `T-A9`：名额已用（在首条回调之前置位 ⇒ 无论成否都不重驱） */
```
结构字段（`wpf_pts_doc` 末尾新增，**不改任何既有字段序／偏移**）：
```c
    int          sub_reused;        /* 跨调用复用它（持有期）的次数 */
    int          drive_done;        /* ⏪ `T-A9`（S2）：每 doc 只驱一窗的记账位 */
} wpf_pts_doc;
```

### 1.3 `S3`／`S4`／`S5`｜未再动的面（如实记）

- **S3**：`:3626` 的 `else if (wpf_pts_drive_probe_enabled())` **一字未改** —— S1 的默认翻转已使其在缺省路径恒成立；保留该条件 ⇒ **显式 `0` 时回退旧行为**（这正是 §3 `D5` 的反极性腿）。**这是对 `T-A8` §4.1 `S3`"改无条件 else"的**等价实现**（效果相同、且多给一条可证伪的反极性口子）**。
- **S4**：`WpfLinuxWin32_PtsDriveProbeGate()` 函数体一行未动（它调用同一枚 `wpf_pts_drive_probe_enabled()` ⇒ 语义随动）；**未**新增只读口 ⇒ 无导出面变化。
- **S5**：全部具名行保留；症状门见 §2 ④。

**改动规模**：`git diff --numstat src/…/win32_pts.c` = **`20 5`**（全为上述四处）；无任何"顺手优化"。

---

## §2 验收标准 ①–⑤ → 证据映射（可复跑单行命令原文 ＋ 原始输出）

> 全部证据脚本／私有 app 副本落**仓外私有目录** `/home/links-dev/tA9-work/`；重活（构建 `.so`／跑腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；显示号只用空闲 `:231`；进程只按 PID；**未跑**整趟 `verify-all`。

### ②③ 构建（走槽）＋ 导出面

```
$ bash /home/links-dev/tA9-work/build.sh
HEAVYSLOT=ACQUIRED waited=0s … ; HEAVYSLOT=MEMOK avail=24846MB
== 链接 -shared -Wl,--no-undefined
== 产物：bin/libwpfwin32.so（406824 字节）
== 导出符号总数：670
```
```
$ cd src/WpfGfx.Linux.Native
$ sha256sum bin/libwpfwin32.so | cut -c1-16                    # ⇒ 33c3bb7e8365835d
$ nm -D --defined-only bin/libwpfwin32.so | wc -l              # ⇒ 670
$ wc -l < bin/exports.txt                                      # ⇒ 670
$ diff /home/links-dev/tA9-work/bak/exports.txt.orig bin/exports.txt && echo EXPORTS-IDENTICAL
EXPORTS-IDENTICAL
```
⇒ 验收③ **成立**：`nm` 行数 **670** == `exports` 行数 **670**；`exports.txt` 与改前**逐字节相同**（**零新增、零消失**）。

### ② 缺省路径 `pfspara`／`pfsparaclient` **可得**（机读行原文 ＋ 值）

**腿**：规范腿器 `run-pts-pages-legs.sh` A 臂（k=24／23），**不设** `WPF_PTS_DRIVE_PROBE`（缺省路径）。`.so`＝`33c3bb7e8365835d`。

```
$ bash /home/links-dev/tA9-work/legs-slot.sh default
AUTHORITY: shim=33c3bb7e8365835d pf=1757d610a687777c ｜ APPDIR: shim=33c3bb7e8365835d pf=1757d610a687777c
LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231
```
原始日志（`evidence-default/app_g1.log`，`sha16=d8f0352b7d4369db`）机读行原文：

```
[DRIVE-PROBE-ENTER] where=FsCreatePageBottomless nms=0x1 pfsclient=0x1 slot56=0x727e6dcfac28 slot80=0x727e6dcfac58 fake=0 t3mode=0 window=0 n=8
[FSPARALIST-PARA] psub=0x6441c51e18d4 pre=(nil) src=native-owned-subtrack same_value=1 acc=-12345 claims=1 rejected=0 hold=0 released=0 ctx=0x6441c5137eb0 para_src_row=DRIVE-PROBE2.nmp1/DRIVE-PROBE3.nmp176 off_pfspara=8 form=native-owned-subtrack seq=5 live=1 created=5 destroyed=4 formatted=0 reused=0 v=ACCEPT-OTHER
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 run=site=probe-in win=in gen=1 quad=1 hold=0 off16=16 bytes0_32=00 00 00 00 00 00 00 00 d4 18 1e c5 41 64 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00  ok=1 gap=0
```

**值（`FSPARADESCRIPTION` 三字段，取 `bytes0_32` 十六进制 dump 解码）**：
- `pfspara`（`off=8`）＝ **`0x6441c51e18d4`**（＝本侧自有子轨对象的字段地址；`src=native-owned-subtrack`，`claim` 成功）
- `pfsparaclient`（`off16=16`）＝ **`0x5`**（＝本 run 内托管 `+176` 真返回；`src=managed-176`）
- `nmp`（`off=24`）＝ **`0x3`**（＝`+136` 交出的合法 `BaseParagraph` 族句柄）
- `*cParaDesc` ＝ **`1`**（`nParaDesc = cParas` 且**填完才置**）
- 前 8 字节（`off0..7`）＝ `00 00 …`＝ **`memset` 清零后的残迹**（"先清零再逐字段写"的成对半边，见 §3 `D1`）

**消费侧落地（同一个值流到消费者）**：`pfsparaclient=0x5` 被 `PtsHelper.ArrangeParaList:158` `HandleToObject(...) as BaseParaClient` **成功反查**为 `ContainerParaClient` ⇒ `BaseParaClient.Arrange(pfspara,…)` ⇒ `ContainerParaClient.OnArrange:47` 拿**同一个** `pfspara` 去问下游：

```
[FSQSTD] rc=-10000 reason=no-layout-content-model entry=FsQuerySubtrackDetails ctx=0x6441c5137eb0 psub=0x6441c51e18d4 calls=1 ok=0 gap=1 null=0 unclaim=0 unformatted=1 out=UNWRITTEN bytes=0
```
（`psub=0x6441c51e18d4` **逐字等于** `FSPARALIST-FILL` 的 `pfspara` ⇒ 值确实流到了消费者；下游 `FsQuerySubtrackDetails` 仍**诚实拒绝**，`rc≠0`、出参一字不写。）

⇒ 验收② **成立**：缺省路径下 `pfspara`／`pfsparaclient` **可得**（机读行 ＋ 值如上）。

计数（现取，两腿独立）：

| 腿（`.so` / env） | `[DRIVE-PROBE-ENTER]` | `[DRIVE-PROBE-SKIP]` | `[FSPARALIST-FILL]` | `[FSQSTD]` | `[FS_PAGE_GAP] entry=FsQueryTrackParaList` | `reason=paraclient-table-not-native` |
|---|---|---|---|---|---|---|
| 改前 `a1403ea71c2bf487`／**缺省** | **0** | 3（`gate-off`） | **0** | 0 | **1054** | 1054 |
| 改后 `33c3bb7e8365835d`／**缺省**（`default`） | **3** | 0 | **897** | 897 | **0** | 0 |
| 改后 `33c3bb7e8365835d`／**缺省**（`default2`） | **3** | 0 | **1099** | 1099 | **0** | 0 |
| 改后 `33c3bb7e8365835d`／**`WPF_PTS_DRIVE_PROBE=0`** | **0** | 3（`gate-off`） | **0** | 0 | **828** | 828 |

### ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**成对**读数

**成对口径**：同装置（`:231`）／同腿器／同 `pf`（`1757d610a687777c`）；**单变量 ＝ 主链 `.so` 换代**。

| 字段 | 改前 `a1403ea71c2bf487`（k23／k24） | 改后 `33c3bb7e8365835d`（k23／k24） | 判 |
|---|---|---|---|
| `alive` | yes／yes | yes／yes | **不变** |
| `app_rc` | 143／143 | 143／143 | **不变** |
| `magenta` | 0／0 | 0／0 | **不变** |
| `colors` | 383／383 | 383／383 | **不变** |
| `ink` | 480000／480000 | 480000／480000 | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | **不变** |
| `ae` | 0／15386 | 0／15386 | **不变** |
| `FRAME fr_sha` | `ef3fd6765f18f51b`（两 k 同值） | 同 | **不变** |
| `FRAME fr_ae_boot` | 15386／15386 | 15386／15386 | **不变** |
| `FAILLINE failfast／unrec` | 0／0 | 0／0 | **不变** |

```
$ diff <(grep -v '^# arm' /home/links-dev/tA6-work/evidence/leg_23.env) <(grep -v '^# arm' /home/links-dev/tA9-work/evidence-default/leg_23.env)
3c3
< DEV x_up=yes five_stable=yes shim=a1403ea71c2bf487 pf=1757d610a687777c
---
> DEV x_up=yes five_stable=yes shim=33c3bb7e8365835d pf=1757d610a687777c
```
（唯一差异＝ `DEV … shim=` **印证换代**；症状门字段**逐字段相同**。）
`run-pts-pages-legs.sh` 的 `pts-pages-guard.sh --legs` 判词在**改前／改后逐字相同**（`PTS_GUARD=FAIL` 的 `fails=` 集一字不差，属**既有止损期相位**，非本件引入）：
```
改前：PTS_GUARD=FAIL … fails=leg24-placeholder-missing(…),leg24-named-line(…),leg23-placeholder-missing(…),leg23-named-line(…),leg24-color-anchor-absent(…),native-ledger-absent(PTS_GAP n=0) …
改后：PTS_GUARD=FAIL …（同一 `fails=` 集，逐字相同）…
```
⇒ 验收④ **成立**：症状门**变与不变都如实报** —— 本件只让 **`shim` 换代**，症状门**逐字段不变**。

### ⑤ 两道牙

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）          # rc=0

$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=… ids=2215 declared=225 glob=build/MilBridge/*report*.md   # rc=0
```

### ③ 在册数声明（`pts-gap-decl.txt` 同趟一致）

```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | grep -E "LIVE|DRIFT|PTSGAP="
LIVE  tool=89 dead=11 artifact=1 ops=77 impl=80 so16=33c3bb7e8365835d exports=670 root=/home/links-dev/netTest/GitProj/WPFOnLinux
PTSGAP=PASS tool=89 dead=11 artifact=1 ops=77 impl=80 so16=33c3bb7e8365835d exports=670 …
```
声明行**同趟更新**（`so16 a1403ea71c2bf487→33c3bb7e8365835d`；其余七格**全未动**）＋ 追加 **dated 重锚注释**（照"只增不改"体例）；`tool/dead/artifact/ops/impl/exports/w66pre16` 全等，无 `DRIFT`／`FIELD-*`。

⇒ 验收③ **成立**：导出面逐名零消失；`pts-gap-decl.txt` 同趟一致。

---

## §3 `D1–D7` 逐条读数 ＋ 反极性（"该红必红"）

> **前置口径**：`D1–D7` 只在"**缺省路径**（不设 `WPF_PTS_DRIVE_PROBE`）"下取数；读数带代际三元组（载体 `.so`／`ts`／`sha`）。**任何绿只准**读成"该入口在缺省路径不再拒绝、且行为可读"，**不得**读成"排版打通"。

### `D1` 零假值／出参纪律 —— **成立**
- **正**：真填路径 `memset` 清零再逐字段写（`rg[i]` 整块归零 ⇒ `bytes0_32` 前 8 字节 `00…`）⇒ 未初始化内存**不交给上级**；拒绝路径（`off` 腿）`*cParaDesc=0`、`rgParaDesc` **一字不写**（`FS_PAGE_GAP` 与 `FSPARALIST-FILL` 计数互斥：`off` 腿 FILL=0）。
- **反极性（该红必红）**：副本产物 `-DWPF_PTS_FSP_PL_PARA_WRONGTYPE=1`（`pfspara` 填**栈地址**＝"看似真实则伪"）：
```
$ bash /home/links-dev/tA9-work/rev-run.sh -DWPF_PTS_FSP_PL_PARA_WRONGTYPE=1 rev-wrongtype
REV-SO=rev-wrongtype sha16=b8a4b78af11cb5aa bytes=406856
LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=…PracticalDemo ae=480000 ink=0
FAILLINE k=24 failfast=4 unrec=2
[FSPARALIST-PARA] psub=0x7dfc309837a0 pre=(nil) src=stack-addr(E3-2 反腿) claim=0 acc=SKIP … v=CLAIM-REJECTED
Unrecoverable system error.: Invalid object handle.
```
⇒ **必红**（假值→下游 `HandleToObject` 撞断言 ⇒ `FailFast`／`app_rc=134`）。

### `D2` 永不假成功 —— **成立**
- **正**：`rc=0` **仅**当 `pfsparaclient` 可经 `HandleToObject` 反查为 `BaseParaClient` ∧ `nmp` 合法 ∧ `cParaDesc==cParas`。现取（`default` 腿）：`pfsparaclient=0x5` **真被反查成功**（⇒ 消费者真的走到了 `ContainerParaClient.OnArrange`，故有 `[FSQSTD]`），`cParaDesc=1==cParas`。
- **反极性（该红必红）**：副本产物 `-DWPF_PTS_FSP_PL_SELFRECYCLE=1`（**填完即回收**＝"`rc=0` 而句柄到手就是死的"）：
```
REV-SO=rev-selfrecycle sha16=584878714869ac7c bytes=406824
LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=…PracticalDemo
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176-recycled-before-return reuse_of_freed_index=1 recycle_rc=0 ok=1 gap=0
Unrecoverable system error.: Handle has been already released.
```
⇒ **必红**（伪成功→消费者撞 `IsHandle()` 断言 ⇒ `FailFast`）。

### `D3` 失败必留痕 —— **成立**
- **正**：任何拒绝**必**打具名 `[FS_PAGE_GAP] rc=<int> reason=<具名> entry=… ctx=… track=… cParas=… owned=… ok=… gap=…`，且 `gap` **恰涨 1**（现取 `off` 腿 `gap=1…828` 单调递增；`default` 腿该行计数 **0**）。
```
[FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5fe936b16aa0 track=0x5fe93755c208 cParas=1 owned=1 ok=0 gap=1
```
- **反极性（该红必红）**：**未构造**"静默 stub（返非 0 零痕迹）"副本 —— 具名前置 `NOINFO(未构造静默 stub 副本：`T-A8` §4.2 `D3` 的必红腿需在主链语义上"删掉留痕"另立一份产物，本波未做)`。**如实记**：留痕的**存在性**在现取上可证（`gap` 行与 `gap` 计数一一对应）；"删掉留痕"这一**反腿**本波**未跑**。

### `D4` 身份只许靠来源证据 —— **成立**
- **正**：`pfspara` 经 `wpf_pts_sub_claim` **唯一认领**（`src=native-owned-subtrack`、`same_value=1`、`claims=1`、`para_src_row=DRIVE-PROBE2.nmp1/DRIVE-PROBE3.nmp176`）；`track` 经 `wpf_pts_track_owned`（`owned=1`）。
- **反极性（该红必红）**：`wrongtype` 腿的 `claim=0 … v=CLAIM-REJECTED`（栈地址认不了）⇒ 填**必被拒**（不靠 `rc`／数值大小判身份）。

### `D5` 撤闸前后分开报 —— **成立**
- **改前（缺省）**恒 `reason=paraclient-table-not-native`：改前 `a1403ea71c2bf487`／缺省 = `1054` 行（表见 §2 ②）。
- **改后（缺省）**才出现 `[FSPARALIST-FILL] rc=0`：`default` = `897` 行（**仍缺省**）。
- **反极性（该红必红）**：**显式 `WPF_PTS_DRIVE_PROBE=0`**（同一新 `.so`、同装置、**单变量＝该环境变量**）⇒ 逐字复现"改前缺省"读数：`[DRIVE-PROBE-SKIP] reason=gate-off`×3、`[FSPARALIST-FILL]=0`、`reason=paraclient-table-not-native`×828。
⇒ **不**把"闸开（探针）可得"读成"缺省路径已通"（`P13` 反腿：本件**未犯**）。

### `D6` 症状门不变 —— **成立**
- **正**：见 §2 ④，改前／改后**逐字段相同**（`alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`／`ns=…`／`FRAME fr_sha=ef3fd6765f18f51b`／`fr_ae_boot=15386`／`FAILLINE failfast=0 unrec=0`）。
- **反极性（该红必红）**：**未构造**"字段漂移"副本 —— `NOINFO(本波未构造症状门漂移腿)`。**如实记**：`pts-pages-guard.sh` 对上述两腿给**逐字相同**的 `fails=` 集（若漂移则该 `fails=` 集必变 ⇒ 该红有机关、本波未造其红）。
- ⚠️ **并**：`+80` 侧效应导致的"帧变"属 `NOINFO`（`t148` §3）；本件**未**把"帧**没**变"读成"无副作用"，也**未**把任一方向读成进度（裁定三十六 (c) 维持）。

### `D7` ≥2 独立样本 ＋ 下游位移如实记 —— **成立**
- **正**：两条**独立 PID／启动时刻**的缺省腿（`default` 12:03:42／`default2` 12:05:xx），**判词相同**（`[DRIVE-PROBE-ENTER]=3`、`FILL>0`、症状门同）；计数**不同**（`897` vs `1099`）＝运行期交互次数的正常差异，**不**读成机制差异。
- **下游位移如实记**：`entry=FsQueryTrackParaList` 缺口 **1054→0**；`entry=FsQuerySubtrackDetails`（已导出）由 **0→897／1099**（`[FSQSTD]`，`reason=no-layout-content-model`）。**"缺口计数下降 ≠ 能力前进"**（`pts-gap-count-check.sh` 件头第 ① 条）：本件只是把**缺口面位移**，页仍**未绘出内容**（`k24` 具名色 `hits=0` 不变）。
- **反极性（该红必红）**：单样本当机制 ⇒ 必红（`P9`）；本件**取了两条独立样本**，**未犯**。

---

## §4 件级前后对账

| 件 | 开工（备份）`sha16` | 收尾（现取）`sha16` | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `e0b5a3a4a21e2275`（4590 行） | **`c0dda70160ff1dc6`**（4605 行） | **`git diff --numstat = 20 5`**；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `f61b9b1e55fdc600`（670 行） | **`f61b9b1e55fdc600`**（670 行） | **不变** ✅（导出面一字未动；`build-shim.sh --symbols` 重建**零差异**） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `32b303148aca23a9` | **`c963dc79e234278a`** | **`git diff --numstat = 9 1`**（声明行 1 行 ＋ 追加 dated 重锚注释）；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `a1403ea71c2bf487` | **`33c3bb7e8365835d`**（406824 B） | **重建产物**（gitignored） |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `4576fc68bcbbf329` | **`4576fc68bcbbf329`** | **不变** ✅ |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | （未触碰） | `e5b399fdb8742092` | **未碰**（不在写域） ✅ |

**备份路径**：`/home/links-dev/tA9-work/bak/{win32_pts.c.orig,exports.txt.orig,pts-gap-decl.txt.orig,libwpfwin32.so.orig}`（`cp -p`，取在**任何写之前**）＋ `/home/links-dev/tA9-work/copy/main-33c3bb7e8365835d.so`（跑反极性腿前的主链件备份）。

**`git status --porcelain`（现取，本件相关）**：
```
 M docs/ROUTES.md                     ← 先于本件存在（`T-A8` 落册时已 M），非本件所改
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
```
（`bin/exports.txt` 与 `bin/libwpfwin32.so` 是 **gitignored 产物** ⇒ 不出现在 `git status`；本件**未** `git add/commit/push`。）

---

## §5 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/libwpfwin32.so`（重建）＋ 本载体。**未碰** `build/*.Linux/**`（生成件）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／`build-shim.sh`。
- **反极性腿的"副本产物"**：两条必红腿（`wrongtype`／`selfrecycle`）**只在副本**编译（`-DWPF_PTS_FSP_PL_*`，**绝不进主链产物**）。取证期间**临时**把主链 `bin/libwpfwin32.so` 换成副本、跑完**逐字节还原**（`cp -p` 自 `copy/main-33c3bb7e8365835d.so`；还原后回读 `sha16=33c3bb7e8365835d` == 备份）——**如实披露**（§6-2）。
- **重活**：全部走 `heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；显示号只用空闲 `:231`；**不跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`（不加牙）。
- **模式守恒**：`stat -c %a` 两件前后均 **644**。
- **探针／腿脚本**：全在仓外私有目录 `/home/links-dev/tA9-work/`（不进仓、不进 `git`）；重活产物落同一私有目录（不碰共享 `~/w67-work`；规范腿器经 `W67_WORK` 指向私有目录，`sync-applocal.sh` 同步权威五件到**私有 app 副本**）。
- **证据强度（如实划界）**：本件"改前"读数取自 `/home/links-dev/tA6-work/evidence/app_g1.log`（`sha16=2cc957c72ea6f186`，`shim=a1403ea71c2bf487` ＝ **改前主链件**，同装置规范腿）—— 性质＝**在册证据的现核**（`T-A6` 那趟），非本席同趟重取；"改后"读数＝本席**同趟新取**。两侧 `pf`／装置／腿器口径一致。

---

## §6 主动披露（待裁决）

1. **`wpf_pts_fsp_pl_is_sentinel` 的"哨兵值"注释与真腿口径冲突**（**本件未改**，如实记）：该函数把 `0x2/0x3/0x4/0x5` 定义成"哨兵值（真腿内出现 ⇒ 读数作废）"；而 `PtsContext.CreateHandle`（`PtsContext.cs:175-193`）返回的是 `_unmanagedHandles[0].Index`，**缺省句柄就是 `1,2,3,4,5,…`** ⇒ 本件缺省路径**真实读数**恰为 `nms=0x1`／`nmSeg=0x2`／`nmp=0x3`／`h1=0x4`／`h2=0x5`。该注释若被当成判据会**把真腿读成假值**。**该函数现取"defined but not used"（编译期 `-Wunused-function`），无实际影响** ⇒ 本件**不动它**（越射程），仅**具名披露**，请裁定。
2. **反极性腿的"临时换件"**：为构造必红腿，本件在**取证窗口内**把主链 `bin/libwpfwin32.so` 临时换成副本产物（`b8a4b78af11cb5aa`／`584878714869ac7c`），跑完**已逐字节还原**为 `33c3bb7e8365835d`（现取回读 == 备份；私有 app 副本亦已 `sync-applocal` 复同步回主链件）。**主链最终产物 == 规范重建产物**（§4）。
3. **`D3`／`D6` 的"必红腿"未构造**：`D3`（静默 stub）／`D6`（症状门漂移）需**另一份"删掉留痕／注入漂移"的副本产物**；本波已用掉构建预算（主链 1 ＋ 副本 2），**如实给 `NOINFO` ＋ 具名前置**（§3 `D3`／`D6`），**不冒充绿**。其余 `D1`／`D2`／`D4`／`D5`／`D7` 的必红腿**均已实跑且该红必红**。
4. **`D7` 两样本计数不同**（`897` vs `1099`）：**判词相同**（`ENTER=3`、`FILL>0`、症状门同），计数差异＝运行期交互次数差异，**不**当机制差异（`P9` 同族：单样本/单读数不当机制）。
5. **`+80` 侧效应的帧面影响**：本件实测缺省路径"开"后两腿 `FRAME fr_sha=ef3fd6765f18f51b` **与改前同**（`t148` §3 的"开/关探针帧面相同"在本代**复现**）⇒ 但仍**`NOINFO`**（`t146` 离群成因未定），**未**读成"无副作用"（裁定三十六 (c)）。
6. **未重跑整趟 `verify-all`**（任务明禁）；`static-jaws-check.sh` 未跑（不加牙）；`pts-gap-count-check.sh` 现取 **PASS**（声明 vs 现算八格全等）。

---

`P1-TAIL2-DEFAULT-CHAIN-IMPL 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 48567d93603a3ad6（末行＝本行）`
