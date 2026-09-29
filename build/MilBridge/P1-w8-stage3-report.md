# P1-W91 · W8 第三阶段（`t154`→`t168`）翻册进 `docs/ROUTES.md`（`§13`／`§15af`）

**本件是翻册件，不实现**：只往 `docs/ROUTES.md` **只增不改**地落两处 dated 块（`§13` 的 `TASK-0302` 子树 ＋ `§15af` 尾部），
并把"同趟牙"读数一并落册。**本席未跑腿、未构建、未跑整趟门禁**；下文所有第三方读数**一律标注引自哪件、哪一代、什么时刻，并注明「本席未独立复算」**。

---

## 1. 只增不改（硬判据）

| 项 | 读数 |
|---|---|
| `docs/ROUTES.md` 改前 | `sha16=8065dcd86dd19c25`（979 行，`mode=644`，`links=1`） |
| `docs/ROUTES.md` 改后 | `sha16=feff0fd943caa9a7`（1003 行，`mode=644`，`size=453193`） |
| `git diff --numstat`（相对 `HEAD`） | **`24 0`**（加 24／**删 0**） |
| `diff <(git show HEAD:docs/ROUTES.md) 现盘` | 删行数（`^<`）＝ **0** ；加行数（`^>`）＝ **24** |
| hunks | `189a190,205` 与 `979a996,1003`（**两次都是纯 `a`（追加），无 `c`／`d`**） |
| 落盘方式 | `temp + os.replace`（保留原 `mode 644`）；备份 `~/w281-scribe/t171/bak/ROUTES.md.pre-t171`（`cp -p`、写前 `links=1`） |
| 相位位 | 判据件 `pts-pages-guard.sh` 现取 `962fec114b2d0692`（＝`t157` 交件值，**未动**）、`sed -n '51p'` ⇒ `phase=degraded`（**未翻**） |

⚠️ **如实记一次自伤与更正（同趟内自捕）**：第一遍落盘的**锚选错**——脚本按**首次匹配** `t71` 会话收尾行插入，
而那条锚第一次出现在 **`TASK-0007`** 子树 ⇒ 块落进了**错的子树**（`§13` 内的 `TASK-0007` 段）。
**处置**：从备份**逐字还原**（`8065dcd86dd19c25`／979 行）后，把锚改成
「先定位 `TASK-0302 [MVP] 🔴 PTS / 原生 LineServices` 行，再取**该行之后**的第一条 `t71` 收尾行」，
并加一条**前置断言**「锚区间里必须含 `dated 翻册（t143`」才写。⇒ 终态**删行数仍为 0**（上面两行读数即终态）。

---

## 2. 新增行逐条清单（**行号仅本次有效**）

**`§13` 块（16 行，行号 `257–272`）**——位置：紧接 **`t143` 翻册块末行**（`相位翻转口径（不变，重申）` 那条 bullet）之后、
**`t71` 会话收尾行**之前（**在 `TASK-0302` 子树内**，缩进层级 `│   │   `）。

| 新行号 | 内容锚（该行以什么开头／讲什么） | 引用载体 ＋ 代际 |
|---|---|---|
| 257 | `⏪ **dated 翻册（t171／scribe，读时 2026-09-29T19:11:38+0800…` 块头 | — |
| 258 | `· **驱动链三级全通（判词）**`：`+80`⇒`nms=0x2`（`t146`）→`+136`⇒`nmp=0x3`（`t151`）→`+176`⇒`h1=0x4`／`h2=0x5`（`t156`，非幂等、两次都被 `+192` 回收）；`WINDOW-INSENSITIVE(有据)`；T3 换料闭合 | `P1-drive-probe3-report.md` `8324d45a3015d75a`（226 行／`17:53`）＋`P1-drive-probe3-criteria.md`（`17:14`） |
| 259 | 〔引自…**本席未独立复算**〕 | 同上 |
| 260 | `· **nmp 的托管侧身份（t155）**`：`ContainerParagraph`、**就是** `0x2` 的 `_firstChild` | `P1-nmp-type-report.md` `f780c77863845f1a`（189 行／`17:31`） |
| 262 | `· **段落列表接线（t160）**`：七条合取全中（`fill 1085/1113`、`resolve=ok` 各 33、四类错误各 0、`h0==keep`）；`pfsparaclient` 偏移 `+16` 三形态齐；`SELFRECYCLE` 反腿⇒`P4` 必红；`ABA` 反腿⇒`rc` 不能区分身份 | `P1-paralist-wire-report.md` `a3ca7725e9935eef`（174 行／`18:08`）＋`P1-paralist-wire-criteria.md`（`17:57`） |
| 264 | `· **t161／t162／t163**`：`FsQuerySubtrackDetails` 判「钥匙」（八步链）／`pfspara` 成"本侧自有可认领真对象"／`FSIMETHODS` 17 槽"回调面无源、诚实源在引擎侧" | `P1-subtrack-criteria.md` `01b00c39ad6f1e84`（326 行／`18:12`）／`P1-pfspara-report.md` `0e546bea6156f282`（155 行／`18:27`）／`P1-fsimethods-recon.md` `c26b675ecc5d05a4`（238 行／`18:16`） |
| 266 | `· **t164→t168**`：铁律「准入 ＝ 本侧是该值的作者」；`E2` 净结果 `D1` use-after-return／`D2`＝`SLOT-ORDER-OK`／`THUNK-LIVENESS` 升读数／槽 3 真调用但 `-100002`；**唯一硬阻塞 `PRECOND-NATIVE-FORMAT-ENTRY-MISSING`** | `P1-format-frame-recon.md` `5474ac003dbb167b`／`P1-engine-drive-report.md` `df43720c9cf33f50`／`P1-fsimethods-abi-recon.md` `62283f54aae6f967`／`P1-fsimethods-snapshot-report.md` `287b88f1b283d6c2`／`P1-fsimethods-drive-report.md` `e1d50d10d7091b42`／`P1-fsformatsubtrack-recon.md` `f610e8fd71e570d2`（行数／mtime 逐件在正文） |
| 268 | `· **三条假绿通道（在册，逐条已堵）**`：`N4`（`t145`）／单样本当机制（`t148`）／**帧面不可复现**（`t152`⇒`t157`，**已实证发生**：主表三行 β 判词「全绿」；β 已并入三成员 `FRAME_EMPTY_SET`） | `P1-frame-determinism2-report.md` `7bc694c16ecd0167`（247 行）／`P1-frameset-d1d2-report.md` `3085a6424b2e20dd`（159 行／`17:56`） |
| 270 | `· **同趟牙（本席现取…）**`：四颗牙原始读数（见 §3） | 本席现取 |
| 271 | `⚠️ **具名待办（本件不执行）**`：`DECL` 件主应在同代重读 `DEFREG_DECLDRIFT` | — |
| 272 | `· **载体**：build/MilBridge/P1-w8-stage3-report.md` | 本件 |

（257–272 中间的空位行即各 bullet 的"〔引自…〕"证据行 259／261／263／265／267／269，逐条带**代际 ＋ 行数 ＋ mtime**。）

**`§15af` 块（8 行，行号 `996–1003`，追加在文件末）**：

| 新行号 | 内容锚 | 引用载体 ＋ 代际 |
|---|---|---|
| 996 | `- ⏪ **dated 阶段三索引（t171／scribe…` 块头 | — |
| 997 | `- **五条族级纪律**`：判词保真（`t147`）／未触达的绿不是绿（`t157`）／不可归因须双向（`t157`）／**多趟采样件：逐趟记代际指纹 ＋ 批内代际守卫**（`t152`／裁定四十）／**准入 ＝ 本侧是该值的作者**（`t164`／裁定五十一） | `P1-ptsname-result.md` `2dd64c6d2ed18c69`（648 行／`19:03`） |
| 998 | 〔①–⑤ 的在册处 … 未独立复算〕 | 同上 |
| 999 | `- **红榜新增两条**`：`P9`（`t163`／裁定四十九）／`P10`（`t165` 自伤／裁定五十二） | 同上 |
| 1000 | `- **口决若干**`：`P8`（`t161`／裁定四十八）／「数据可值化、可调用体**在窗内也可值化**」（`t166` 修订 `t165`）／「`NOINFO` 是取不到，不是定义没写清」／「副本的意义…」／**身份判据三条禁令**（不靠 `rc`／不靠数值形态／不靠可碰撞伪指针） | 同上 ＋ `P1-paralist-wire-report.md`（`ABA` 反腿） |
| 1001 | `- **相位翻转口径（不变，重申）**`：`N1`／`N3`（判红但效力降 `NOINFO(帧面不定性)`）／`N4`（`NOINFO`）＋ **`PRECOND-FRAME-DETERMINISM` 仍未满足**（裁定四十二）⇒ **今天不得翻** | `P1-ptsname-result.md` `2dd64c6d2ed18c69` |
| 1002 | `- **同趟牙（本席现取…）**` | 本席现取 |
| 1003 | `- **载体**：build/MilBridge/P1-w8-stage3-report.md` | 本件 |

---

## 3. 同趟牙（四颗，本席现取；**他者在飞 ⇒ 读数不可比时如实记、不"对齐"**）

| 牙 | 落盘**前**（`2026-09-29T19:1x+0800`） | 落盘**后**（`19:12+0800`） | 说明 |
|---|---|---|---|
| `DEFREG`（两遍） | `DEFREG_DECL=n=224 route_ids=224`；`DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`（两遍**相同**） | `DEFREG_DECLDRIFT=0 keys=-`（**仍 0**；机读行 `DEFREG_DECLDRIFT_KEYS=-`） | 我的追加**未**使该读数变化（如实记；DECL 刷新与否由 DECL 件主在同代定，本件不执行） |
| `REPORTID` | `REPORTID=PASS files=286 ids=2208 declared=224` | `REPORTID=PASS files=287 ids=2208 declared=224` | **两次不同**（期间他者新增报告件）⇒ 如实记，不"对齐" |
| `PTSGAP` | `PTSGAP=PASS tool=90 dead=11 artifact=1 ops=78 impl=81 so16=291ef08a33f9b6e4 exports=665`（`rc=0`） | `PTSGAP=PASS … so16=352855f8dfbf8dc7 exports=669`（`rc=0`） | **同趟内 `.so` 又换代**（`t172` 在飞）⇒ 记两代；`SITE-HISTORICAL-ONLY` 命中 **2**（两行同为 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 ops／impl `hist=1`） |
| 覆盖面指纹（第四颗） | `infp fp` ＝ `c0f84a18ad87ffc06a6545fcc33b507fcb56828d3e9dea6b8989eca35faaec6d` | 同（本件不改覆盖面内件；**只改 `docs/ROUTES.md`**） | `docs/**` 不在覆盖面内（本波口径） |

`PTSGAP_FRONTIER`（现取附记）：`before=LoCreateContext@3 after=FsQueryTrackParaList@1117`、
`carrier_sha16=84db0eb62d15e0b2 carrier_mtime=2026-09-29 14:12:09`、`ts=2026-09-29T19:10:12`（**引自该工具自身输出，本席未独立复算**）。

---

## 4. 具名 `NOINFO`／未跑未核（主动点名）

1. **未跑腿、未构建、未跑整趟门禁**（本件是翻册件）⇒ 第三阶段的**任何数据读数本席都未复算**；`§13` 块内每条都在"〔引自…〕"里写明**载体路径 ＋ `sha16` ＋ 行数 ＋ `mtime`**，并标注「**本席未独立复算**」。
2. **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 的当前状态 ＝ `NOINFO`（本席未核）**：只按 `t168` 载体（`P1-fsformatsubtrack-recon.md`）与 `P1-ptsname-result.md` 记为"**唯一硬阻塞**"；它**是否**在我这趟里被解掉，**未核**。
3. **`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `SITE-HISTORICAL-ONLY` 两行**：工具自己写"现值位当在别件、全树口径见 `PTSGAP=NOINFO reason=…`"；**本席未追**该全树口径（不属本件射程）。
4. **`HANDOFF-NEXT.md` 的 `cell=#1`**：**未碰**（队长收口）。本件改到的件**只有 `docs/ROUTES.md`**，它**不在覆盖面指纹内** ⇒ **无 `cell=#1` 事项**（「有意未登记」的适用面 ＝ 覆盖面内件；本件为零）。
5. **`DECL` 刷新**：**未执行**（`defect-registry-declared.tsv` 在 `build/MilBridge/tools/**`，**不在本件写域**）；已作为"具名待办"落在册。
6. **第一遍落盘的错子树**：**已更正并在册**（§1 末段）；终态 `删行数=0`。
7. **`t169`／`t172` 在飞**：`PTSGAP` 的 `so16` 在我这趟内变了两次读数 ⇒ 本件**不据此下任何结论**，只记两代读数（跨代不可比，照裁定四十）。

---

## 5. 纪律

- **写域**：只写 `docs/ROUTES.md`（＋本载体）。**未碰**：`build/MilBridge/HANDOFF-NEXT.md`、`build/MilBridge/tools/**`、`src/**`、任何 `.cs`、两枚哨兵；**判据件现取未动**（`pts-pages-guard.sh` `962fec114b2d0692`、`phase=degraded`）。
- 未 `git add`／`commit`／`push`；未占显示位、未起 Xvfb、未跑腿、未构建。
- 翻册器与备份全在**仓外**：`~/w281-scribe/t171/apply.py`、`~/w281-scribe/t171/bak/ROUTES.md.pre-t171`。
- 行号一律标「**仅本次有效**」；引用一律**内容锚**（块头句／bullet 首句）而非行号。

self16=0620c42b7b4fb3c1
