# WC04 报告 —— `TASK-0111` 的 `N3` 归因终局落册 ＋ 一条纪律事故 ＋ 一条方法学口径

> **口径**：本报告 sha16 = `head -n -2 build/MilBridge/WC04-report.md | sha256sum | cut -c1-16`（现场现算，见 §9）。
> 车道 = **WC04**（会话级前缀，目录 `~/wc04/`）｜`R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**）。
> 本件 = **纯文本 ＋ 一次推送**：**零 `dotnet`／零构建／零 `verify-all`／零应用／不占槽**。**未改任何产品件**（`src/**` 一字未碰）。
> ⚠️ **本波前提与派单书不符（如实记）**：派单书写"冻结 `#52`…远端 head 应 ≈ `33df6aa1…`"且"`#53` 正在被另一会话跑"；**现场读数** = **`#53` 已冻结并推送**（§15s，整份 `a2e49b786d0a1b02`）、**`D-G110` 已占**、`declared` 基线 = **`146`（不是 `145`）** ⇒ 本件**按现场为准**：新号 **`D-G111`**、新 TASK **`TASK-0210`**。

---

## §0 一句话判决（**结论在前**）

> **五组内容全部落册、门禁两趟逐字相同、`declared 146 → 147`、推送一笔并逐件字节核对。**
> ① `D-G98` 追加「**归因终局（`N3`）**」＝ **发起方 = `wpfgfx_cor3.so`（MIL 桥／合成器）在自己那条 X 连接（`fd=135`）上发的裸 `ConfigureWindow`**（`win=0xc00004 mask=0x000c`、**`1280x1024`**、**WM 真还原后 `+85 ms`**）；
> ② 新 **`TASK-0210`**（桥侧几何重发／接管，**产品改动 ⇒ 排在 `#53` 冻结之后**；现场 `#53` 已冻 ⇒ 前置满足）；
> ③ 新登记 **`D-G111`**（**装置的手伸出了沙箱**：`9` 趟真点击跑到用户 `:0`／`:1` 上）；
> ④ **方法学口径 ＋ 三件可复用仪器**并入 **`D-G107`**（**不新号**，理由先写）；
> ⑤ `DEFREG=PASS declared=147 route_ids=147`／`DECLDRIFT=0`／**两趟 `cmp` IDENTICAL**。
> ⚠️ 本件**只登记、只落册**：**`K3`／`§15m`／`TASK-0111` 的原文一字未动**（§5 有机械证），**未把任何红写成绿**。

## §1 判据（**先写**，含位置与 sha16）

- 判据文件 **`~/wc04/criteria.md`**：**动手改任何仓内件之前**写成（**先写版 sha16 = `bb89bd3ca305ce96`**、`62` 行）。
- 先写的机读判据：**J1** 编号不撞车（`D-G111`／`TASK-0210` 全仓 `0` 命中）｜**J2** 五组全落｜**J3** 口径"一字不动"（diff **只许有 `+` 行**）｜**J4** `declared 146 → 147` 且**零幻影行**｜**J5** 门禁两趟逐字相同｜**J6** `CS`／`HO`／`AB` **逐位不变**｜**J7** 行锚定 ＋ `wc -l` 差值 == 插入行数｜**J8** 推送纪律（逐径 `add`、零 `-A`、`BYTECHECK`）｜**J9** 射程如实。
- 先写的**预登记预测** `P1`–`P7`（**逐条现场对**，见 §3）。

## §2 本波五组内容（**artifact ＋ 字段 ＋ sha16**，逐条）

**共同出处** = `build/MilBridge/WC03-report.md`：**FULL** `sha256sum` = **`4d279f76ec38f7d2a7fe2e16c9fdc1e1d3e1457c55dea356f284472cba712c8b`**｜**去行口径**（`head -n -2 … | sha256sum | cut -c1-16`）= **`1fa17dc1461a774f`**｜**280 行**（本件现场现算，**两口径都给** = `D-G104` 第三条；**两者逐位等于派单书给的值**）。判据先写 = `~/wc03/criteria.md`，本件现算 = **`c961391dcc094dbd`**（＝ 报告自记的"追加 §8 之后"值）。

| # | 内容 | 落点（artifact） | 关键字段 |
|---|---|---|---|
| ① | `D-G98` 追加「**归因终局（`N3`）**」 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`D-G98` 段末，`12` 行 bullet ＋ 子条） | `fd=135`｜`ConfigureWindow win=0xc00004 mask=0x000c w=1280 h=1024`｜`+85 ms`／落地 `6.2 ms`｜红 `5/5` 有·绿 `6/6` 无、`p=2.2e-3`｜协议级 cut **4/5 转绿**、同臂未切红 `8/10`｜`xmaxrepro 48/48` 复现不出 |
| ② | 新 `TASK-0210` ＋ `TASK-0111` 指针 | `docs/ROUTES.md` §13 树（`TASK-0111` 行下，`6` 行） | 判定点 = 桥在还原后 `+85 ms` 用裸 `ConfigureWindow` 改回最大化几何｜**产品改动 ⇒ 排在 `#53` 冻结之后**｜状态 **`[Next] 🔴`** |
| ③ | 新登记 `D-G111` | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 文末（`### D-G111`，`9` 行） | `9` 趟 **`:0`／`:1`**｜每趟 `800x600` 窗口 ＋ **`3` 次点击**｜约 `25 s` 按 **PID** 收｜`leg.sh` **白名单硬闸** `rc=9`｜`NOINFO` = 点击落点 |
| ④ | 方法学口径 ＋ 三件仪器 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 **`D-G107`** 段末（**并入、不新号**，`4` 行） | `~/wc03/bin/xwrap.so` **`b5c1c1dbc4c0f13d`**｜`xobs` **`fb3fe379eb943994`**｜`xmaxrepro` **`a058dad4a6691c15`** |
| ⑤ | `DEFREG` ＋ 推送 | `build/MilBridge/tools/defect-registry-declared.tsv`（**仅 `--emit` 重生成**）＋ 克隆 | 见 §4／§6 |

**④ 的"并入而不新号"理由（先写后判，逐字）**：`D-G107` 要件② 已写死「**取值时射程必须按该对象的真实结构定义**」⇒ 本次坏的正是**同一要件的"测量层级"一侧**（仪器**假设**"预加载能看见该进程全部 X 调用"，**真实结构**是"**有一条绕开预加载的调用路径**"）⇒ **射程不足 ⇒ 错误否定**（把"**我读不到**"读成"**它没发**"），与该条**危险方向（漏判）同向**；⚠️ **`D-G104` 被机械排除**（那条坏在"**打了但语义被读错**"，本次是"**根本没打出来**"）。

## §3 独立复算（口径 = **不经 WC03 汇总表**）与预登记预测逐条对

**(a) 本件现场现算的读数**（全部现取，无手抄）：

| 项 | 本件读数 | 判 |
|---|---|---|
| `WC03-report.md` FULL | `4d279f76ec38f7d2a7fe2e16c9fdc1e1d3e1457c55dea356f284472cba712c8b` | **逐位等于**派单书值（`P3` ✓） |
| 同上 去行口径 ／ 行数 | `1fa17dc1461a774f` ／ `280` | **逐位等于**派单书值 |
| `~/wc03/criteria.md` | `c961391dcc094dbd` | = 报告自记"追加 §8 之后"值 |
| 三件仪器 sha16 | `b5c1c1dbc4c0f13d`／`fb3fe379eb943994`／`a058dad4a6691c15` | **逐位等于**报告值（`P7` ✓） |
| 白名单硬闸 | `~/wc03/bin/leg.sh:30-31`：`:18[0-9]) : ;;` ＋ `*) echo "REFUSE_DISPLAY=… rc=9"; exit 9;;` | **现场在位**（`P6` ✓） |
| 作废留痕 | `VOIDED-b4-on-display-1` **9** 项（`M1R2-05/06`、`M2R2-01/02/03`、`NOWM-01/02`、`NOWRAP-01/02`）｜`VOIDED-b5-on-display-1` **2** 项（`M1R2-07/08`）｜`VOIDED-b5b-overlap` **3** 项（`M1R2-07/08/09`） | **现场在位**（`P6` ✓） |

**(b) ★请求字节逐字段复算（本件自己的算法，`P5` ✓）**：派单书给的那串 **`20 B`** 与 X 协议**自洽** —— `ConfigureWindow` 长度 = `12 + 4×popcount(mask)` = `12 + 4×2` = **`20 B`**；逐字段解出 `opcode=0x0c`、`len=5×4`、`window=0x00c00004`、`mask=0x000c`、`w=1280`、`h=1024`。而报告 §4.4 打的 **`24 B`** 台账 = **这 `20 B` ＋ 紧随其后的 `GetInputFocus`**（`opcode=0x2b` = **43**、`len=1` ⇒ **`2b 18 01 00`**，恰 `4 B`）⇒ **两个口径逐字节对齐**（与该段"同一腿上还有一条 `op0=43`"自洽）。

**(c) 预测逐条**：`P1` ✓（`D-G111`／`TASK-0210`）｜`P2` ✓（`declared 146→147`、**零幻影行**）｜`P3` ✓｜`P4` ✓（本件**没有**把 `N3` 写成"取代 `K3`"，而是"**补上 `K3` 自记的那格 `NOINFO`**"）｜`P5` ✓｜`P6` ✓｜`P7` ✓ —— **七条全中**。

## §4 `DEFREG`（**两遍逐字相同**）

```
DEFREG_DECL=n=147 route_ids=147 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_ROUTES=KD=7f7770acd3ec24b9 CS=81b35c059717b7a8 HO=e4dc264200b421d0 AB=a2e49b786d0a1b02
DEFREG_EXTRA=KRJ=f108775906eac9aa KRF=ab09235afd949bc2 KRP=3c9e3a309b990d31
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN
DEFREG=PASS declared=147 route_ids=147（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
```

- **两趟 `rc=0/0`、两份输出 `cmp` = `IDENTICAL`**。
- `--emit` 用 **temp ＋ rename**（`mktemp` → `mv`，**不用 `>` 覆盖**）：`diff` 与旧件**只有两行头变化**（`DECL-GEN` 时间戳、`DECL-ANCHORS` 的 `KD=` 因册子改了而变）＋ **恰好新增一行 `ID<TAB>D-G111<TAB>req=KD<TAB>present=KD`** ⇒ **零幻影声明行**；`tsv` 行数 `155 → 156`。
- **J6 ✓**：`CS`／`HO`／`AB` 三格与开工基线**逐位相同**（`81b35c059717b7a8`／`e4dc264200b421d0`／`a2e49b786d0a1b02`）⇒ **本件未碰** `docs/CURRENT-STATE.md`／handoff／`ACCEPTANCE-BASELINE.md`。

## §5 行锚定 ＋ "一字不动"的**机械证**（`J3`／`J7`）

| 件 | 改前 `wc -l` | 改后 `wc -l` | 差值 ＝ 插入行数 | `diff` vs 远端 commit |
|---|---|---|---|---|
| `docs/ROUTES.md` | `726` | **`744`** | **`+18`** | **`added=18 deleted=0`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2864` | **`2893`** | **`+29`** | **`added=29 deleted=0`** |

- 口径 = `diff <(git show HEAD:<path>) $R/<path>`：**删除行 `0`、改动块 `0`** ⇒ **既有判词与既有追加段一字未动**（`J3` ✓）；`wc -l` 差值 **恰好等于**插入行数 ⇒ **零吞行**（`J7` ✓）。
- **`K3`／`§15m`／`TASK-0111` 的原文**：本件**只在其后追加**，且新写的"关系句"明确写「**不冲突、也不互相取代**」＋「**补上 `K3` 自己写下的那格 `NOINFO`**」。

## §6 推送前后 head ＋ `BYTECHECK` ＋ 件对账（`J8`）

**推送前**（现场现取）：`HEAD` = `origin/feat-Linux` = **`4bc517d6c06caf3cb0432680eed071e960206e50`**，`git status --porcelain` = **`0`** 行（工作区干净）。

**本笔 4 件**（`cp -p` 逐件 ＋ **逐径 `git add <file>`**，**无 `-A`**）：

| 件 | 磁盘 sha256（= 推后要核的"磁盘"侧） |
|---|---|
| `docs/ROUTES.md` | `0cba40fe79f523336fac4568541c2a53eeacaad3958d8d1ab6e0e34d53a90a55` |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `7f7770acd3ec24b9e31df4fe0974adcf7d663ae45f409264520456654eda03b` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `9be486681bd47451b454f0505e2b42e9e55c60c4f9df84d376e50a9a924c65e0` |
| `build/MilBridge/WC04-report.md` | （本报告 —— **自身 sha 属自指 ⇒ 见 §9**） |

- **推送后读数（`fetch` ＋ `ls-remote --symref` 交叉核 ＋ `BYTECHECK`）** —— ⚠️ **本报告与它自己的推送在同一笔里** ⇒ 推后的 head／`BYTECHECK` **无法写进本文件**（自指）：**逐字读数记在 `~/wc04/STATUS.md`**（仓外，终稿现场算），并在给主控的回复里给出。**口径**：`BYTECHECK` = 对每件 `git cat-file blob origin/feat-Linux:<path> | sha256sum` vs `sha256sum $R/<path>`，**两者相等才算通过**；`symref` 必须仍是 **`ref: refs/heads/feat-Linux`**。
- **纪律**：**逐径 `add`**／**零 `-A`**／**零 `--force`**；推前 `status --porcelain` 行数与暂存件数、`cp -p` 件数**逐件对账**（三者相等）。

## §7 `$R ↔ 远端` 不同件（**机械对账**，本件现场现算）

口径 = 对**远端树的每一个 tracked 件**（`git ls-files -s`，**`15271`** 件）现算 `$R/<path>` 的 blob sha1（`git hash-object`）并与远端 blob 比：

| 格 | 读数 | 判 |
|---|---|---|
| **内容不同** | **恰好 `3` 件** = 本件改的那三件（`ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`） | **无第 4 件**（推送前） |
| `$R` 缺（远端有、`$R` 无） | **`7366`** 件 | **结构性**，非本波漂移：全部是**克隆根目录那份 dotnet/wpf 树**（`src/` **6821**、`eng/` **272**、`packaging/` **214**、`.github/` **11**…）—— 即 `README.md` 登记的「**账一（已知重复）**」：**构建只读 `upstream/wpf/**`**（`$R` 侧 `upstream/` 有 **6415** 件）。⚠️ 该格**本件未逐件归因** ⇒ `NOINFO`（**不声称**"已解释完"） |
| `$R` 独有 | 见 §8`NOINFO`（未枚举） | — |

⚠️ **`#53` 的在办件一件未碰**：`verify-all.sh`／`docs/WAVE53-PREREGISTRATION.md`／`known-red.json`／`src/**` 三件 native 源／`build/wave-audit.log`／`arm-logs/tline.log`／`gen/t2d-*` **全部未 `add`、未改、未当声明值**（对账表里它们**不在**"内容不同"的 `3` 件里 ⇒ 机械证）。

## §8 `NOINFO` ／没做到的事（**逐条，不猜**）

1. **桥为什么"只在此臂重发"**（`M1:R2` 88.9% vs `M2:R2` 9.1% 的臂间差成因）⇒ `NOINFO`（**要读取数须给桥侧加插桩 = 改产品**，本件写域外；随 ① 登记）。
2. **桥那条连接为何绕过 `LD_PRELOAD`** 的**机制** ⇒ `NOINFO`（`RTLD_DEEPBIND` 只是最像的一条）。
3. **事故里那些点击的落点** ⇒ `NOINFO`（**逐字保留、不许缩小**）。
4. 「全 `$HOME` 还有几处装置**不硬闸显示号**」／「还有几处仪器**只靠符号级 hook 做否定断言**」／「`$R` 独有件清单」—— **均未逐处枚举** ⇒ `NOINFO`。
5. **本件未复核的**（**引用**而非"已复算"）：WC03 的**全部腿级读数**（`11` 腿配对、`CUTP-*` 5 腿、`48/48` 复算、`xobs` 时间轴）—— 本件**只复算了**报告身份（两口径 ＋ 行数）、判据 sha16、三件仪器 sha16、硬闸与留痕在位、以及**请求字节的协议自洽性**（§3b），**没有**重跑任何腿。
6. **推送后 head／`BYTECHECK` 未能写进本文件**（自指）⇒ 记 `~/wc04/STATUS.md` ＋ 主控回复（**不是**"没做"）。
7. **本件未跑**：任何构建／`verify-all`／`close-wave`／`integration-wave`／冻结器／应用。**未新增任何牙**。

## §9 报告两行口径

| 口径 | 值 |
|---|---|
| **FULL**（整份文件）`sha256sum build/MilBridge/WC04-report.md` | **因"自我指涉"不写进本行** —— 按惯例记在 `~/wc04/STATUS.md`（终稿现场算） |
| **去行口径** `head -n -2 … \| sha256sum \| cut -c1-16` | 见文件末自证行（脚本现算） |

## §10 ≤5 行大白话小结

1. **那 0.1 秒里的几何申请抓到主了**：不是 WM、不是 shim、不是"没人发"，是 **MIL 桥 `wpfgfx_cor3.so` 用自己那条 X 连接（`fd=135`）直发了一条裸 `ConfigureWindow`**，把窗改回 `1280x1024` —— 而它在**绿腿上一次都不发**。
2. 我没有只抄结论：**报告的两口径 sha、判据 sha、三件仪器 sha、白名单硬闸与作废留痕**都现场复算了（逐位相符），还把那条 **20 字节**按 X 协议逐字段拆了一遍（与报告 24 字节台账**逐字节对齐**）。
3. 五组内容都落了册：`D-G98` 归因终局、新 `TASK-0210`、新 `D-G111`（**仪器跑到用户 `:0`/`:1` 上**）、方法学口径并入 `D-G107`、`DEFREG` 与推送。
4. **纪律**：口径"一字不动"我给了**机械证**（`diff` 只有加法：`+18`／`+29`，**删除 `0`**）；门禁**两趟逐字相同**、`declared 146→147`、`CS`/`HO`/`AB` 未动。
5. 我没做到的：**桥为什么只在部分腿上重发**、**为何绕过 `LD_PRELOAD`**、**事故点击的落点** —— 三条都如实 `NOINFO`，**没写成绿**。
WC04-report.md 正文口径 sha16 = `5401ef790680ac70`（＝ `head -n -2 build/MilBridge/WC04-report.md | sha256sum | cut -c1-16`）｜**FULL sha256 因"自我指涉"不写进本行**，按惯例记在 `~/wc04/STATUS.md`（终稿现场算）｜现场现算，未手抄
