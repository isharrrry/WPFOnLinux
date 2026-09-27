# `V79b-t16close-verify.md` —— `t16` 关账的独立复验（`t28` 三处修 ＋ `t29` 第三处 ＋ ①/⑥ 重新现取）

车道 `verifier`／`t30`。`N=/home/links-dev/netTest/GitProj/WPFOnLinux`；只读 `$N`（除本报告）；夹具/副本在 `~/w28x/t30/**`。
**每条读数带读取时刻**；判据本体（真集合包含、合法 `NOINFO` 不误报）上一趟（`t16`）已独立复现，本趟**只判三处修得对不对、判据域有没有放宽**。

## 0. 判词：**`pass`**（三处修 ＋ 第三处 + ①/⑥ 全部复算通过；0 条阻塞性 finding）

| 件 | 现取 sha16（时刻） | 本趟结论 |
|---|---|---|
| `build/MilBridge/tools/root-entries-allowlist-check.sh` | `e868941384f4bd00`（12:12） | ③④⑤ 三处**都真修好**，判据域**未放宽** |
| `build/MilBridge/HANDOFF-NEXT.md` | `0dfbea6857ec70f8`（12:12） | `t29` §8 方法射程边界**在位** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `b300c4fdfe5c9a7c`（12:12） | `t29` 路径承载性条目**在位** |
| `docs/ROUTES.md` | `f8b43ab042932fb4`（12:12） | `:82` 口径条 ＋ `:763` 已派号 `D-G167` |
| `verify-all.sh` | `52b4d0a7e687328d`（12:12，= `t27` 落仓值） | ① 已解决 |

## 1. ③ 件头↔清单（**我自己的双向对拍**，不用它的函数）

抽取方式（我自己写）：件头 `DOC-CAT3-BEGIN:…:DOC-CAT3-END` 之间的名字集合 ／ 代码常量 `^DOC_CAT3='…'` ／ 内嵌 `ALLOWLIST` heredoc 里 `why` 含「fork 治理件」的行 ／ 清单全部行。

```
件头 DOC 段 n=9：LICENSE.TXT|SECURITY.md|CODEOWNERS|CODE_OF_CONDUCT.md|THIRD-PARTY-NOTICES.TXT|.github|.gitattributes|.gitignore|README-Window.md
常量 DOC_CAT3 n=9：与件头**逐名相同**（差集 = 空）
清单 fork 治理件行 n=9：与上面**逐名相同**
方向A（清单有·件头没写）= 0 条；方向B（件头写了·清单没有）= 0 条 ⇒ 双向都齐
清单总行 n=25；清单里 why 为空的行 = 0
.editorconfig：件头 **False** ／ 清单 **False** ⇒ **两处一致地不在**
```
- **`.editorconfig` 现在的处置与理由**：**不在件头枚举、也不在允许清单** ⇒ 一旦被放回（`git ls-files` 或工作树任一来源）**必红**（见 §3 的 N1 腿，两来源各点名）。理由是它是 `#77` 抓到的**第二件同类漏网**（129 条 `severity = error`）；**允许它等于把已知缺陷放回**。t28 选的修法＝「从件头移除」——我从现场看是**两处都无**，与"移除"一致。
- **③ 我自己造的反极性（在**我的副本**上做，`$N` 零改动）**：`cp -p` 真件到 `~/w28x/t30/tooth-copy.sh`，**删掉清单里 `README-Window.md` 那一行**（件头仍列举它）⇒ 读数逐字：
  ```
  ROOT_ALLOW_DOC_NOTE kind=header-not-in-list entry=README-Window.md why=件头 category ③ 列了它、清单里没有 ⇒ 二者必居其一…
  ROOT_ALLOW=FAIL reason=doc-drift doc_drift=1 root=… allow_src=embedded allow_file=-      rc=1
  ```
  ⇒ **不是静默**（同时给了逐条 NOTE 与汇总 `doc_drift=1`）✓

## 2. ④ 绿档可见性（我自己看那一行）与 ⑤ 来源标签（我自己造反极性）

```
（内嵌档，12:12）ROOT_ALLOW=PASS root=/home/links-dev/netTest/GitProj/WPFOnLinux allow_src=embedded allow_file=- examined=22 tracked_n=22 worktree_n=25 allowed_n=25 … rc=0
（--allow 档，12:12，用我自己的清单文件）ROOT_ALLOW=PASS root=/home/links-dev/netTest/GitProj/WPFOnLinux allow_src=file allow_file=/home/links-dev/w28x/t30/my-allow.tsv examined=22 … rc=0
```
⇒ **两格（`allow_src`／`allow_file`）在两种档下如实不同**，且 `root=` 是绝对路径 ✓
**⑤（我的来源反极性，12:12，沙箱 `~/w28x/t30/fx2`）**：
```
ROOT_ALLOW_HIT entry=tracked-new.txt   source=git-ls-files rule=not-in-allowlist      ← 已跟踪
ROOT_ALLOW_HIT entry=tracked-new.txt   source=worktree     rule=not-in-allowlist      ← 同一件也在盘上
ROOT_ALLOW_HIT entry=untracked-new.txt source=worktree     rule=not-in-allowlist      ← 未跟踪**只**报 worktree
```
⇒ 标签**跟着来源变**且与实现一致（`git ls-files` ↔ `ls -A`）；件头 `:16-17` 逐字写着 `source=git-ls-files ＝ 来源①：git -C <root> ls-files -z`／`source=worktree ＝ 来源②：ls -A <root>`（**四格语义成文**）✓

## 3. 判据域未放宽（三条反极腿**我自己复跑**，形态自造）

```
--selftest（12:12）：ROOT_ALLOW_SELFTEST=PASS cases=18 pass=18 fail=0
腿名现取：P1 P2 N1 N1b N2 N3 N3b D1 D2 D3 D3b D4 D5(--allow) D5b D6 N4 N5 N6
  ⇒ 原有 10 腿（P1/P2/N1…N6）**一条未删**，新腿是 D* 一族 ＋ N1b/N3b
（对当前牙版本 e868941384f4bd00、对我的沙箱根 ~/w28x/t16/fx）
基线            rc=0  ROOT_ALLOW=PASS examined=22 rc=0
N1 .editorconfig（上游逐字件）⇒ rc=1，**两个来源各一条 HIT**（git-ls-files ＋ worktree）
N2 Directory.Build.props      ⇒ rc=1，两个来源各一条 HIT
N3 NuGet.config（未跟踪）      ⇒ rc=1，`source=worktree`
回正            rc=0  ROOT_ALLOW=PASS   ← 红都非空转
真树（12:12）   ROOT_ALLOW=PASS root=$N allow_src=embedded examined=22 unknown_tracked=0 unknown_fs=0 rc=0
```

## 4. 🔴 `t16` 的 ①/⑥ 重新现取：**判为落仓窗口内的瞬时不一致，不是缺陷**

| 项 | 我在 `t16` 读到的（时刻） | 现取（12:12） | 判词 |
|---|---|---|---|
| ① 覆盖面 vs `[42] --expect` | `list=225` 而 `--expect=219`；**该刻 `verify-all.sh` sha16 = `5c75efcead70dac8`**（12:01:57 现取，另一次 12:0x 读到 `run_step=53`／`DECL 53 gen=#79`） | `list=225` ＝ `--expect 225`（`verify-all.sh:1179`）；`run_step=55`／`DECL 55 gen=#79`；`verify-all.sh` sha16 = **`52b4d0a7e687328d`** | **已解决**（瞬时） |
| ⑥ `WIRING_CLOSURE` | `FAIL … undeclared=2`（点名 `report-id-domain-check.sh`／`pkg-src-retiredpath-check.sh`，两件均为别的车道 `??` 在飞件） | `WIRING_CLOSURE=PASS steps=55 jaws_n=52 undeclared=0 reasonless=0 fails=0 rc=0` | **已解决**（瞬时） |

**时间关系（机器证）**：`t27` 两处落仓 mtime ＝ `build/close-wave.sh` **12:03:04.50**／`verify-all.sh` **12:03:19.92**；我在 `t16` 读到 `--expect=219` 时 `verify-all.sh` 的 sha16 是 `5c75efcead70dac8`（**≠** `t27` 落仓后的 `52b4d0a7e687328d`）⇒ 那次读数**发生在 `t27` 落仓之前**，`t27` 的同趟改动（+2 步／覆盖面 +6 行／`--expect 219→225`）把它修掉了 ⇒ **是我读数期间正在落仓造成的窗口内不一致**（本仓 `D-G130` 族），**不判缺陷**；`t27` 与主控的复算与我同值。

## 5. `t29` 第三处（我自己 `grep -c` ＋ 逐字命中行，12:12）

```
getProperty：ROUTES.md=2 ｜ 缺陷册=6 ｜ HANDOFF-NEXT.md=2
路径承载   ：ROUTES.md=2 ｜ 缺陷册=4 ｜ HANDOFF-NEXT.md=2      （我 t16 那次：ROUTES 1／册 0／HANDOFF 1）
命中行逐字（各取一处）：
  docs/ROUTES.md:82  - 🆕 **2026-09-27 补：方法射程边界（**口径条，非缺陷条、不占号**）** …
  docs/ROUTES.md:763 - 🆕 **2026-09-27 派号**：上面这一段的性质已**成条入册并派定编号 `D-G167`**（**九位是路径承载…
  HANDOFF-NEXT.md:124 ## §8 方法射程边界（**`t29` 补**；与 `docs/ROUTES.md`／缺陷册**同一术语、同一结论**）
  HANDOFF-NEXT.md:126 - **射程边界（术语逐字）**：`-getProperty:`／`-getItem:Compile` 这类 **MSBuild 求值级**探针…
  缺陷册:3410 ### 🆕 **路径承载性**（**九位是路径承载体** ⇒ **跨树位置不可复现**；`D-G92`／`D-G46` **同族**）
  HANDOFF-NEXT.md:11  ⚠️ **`#77` 五位位移（pc/pf/windowsbase/provider/dwf）＝ 路径承载体**…
```
⇒ **三处都在**，且**同一术语**（路径承载性／方法射程边界）；无"只在别的名字下存在"的情形 ⇒ 本项判 `pass`（附注：我的计数比 `t29` 自报的各多 1（ROUTES），很可能包含我在 `t16` 写进本仓的报告引文与我未逐条枚举的波块；**我未逐条枚举全部命中**，只逐字给了各件至少一行）。

## 6. 边界与 `NOINFO` / 低危附注

1. `NOINFO`：我**没有**逐条枚举 §5 的全部命中（只各件取一行）；**没有**复算 `.editorconfig` 的 129 vs 131 行 `severity = error` 计数（那是 `t29` 的在册文本，不在本件验收面）。
2. 低危附注①：`③` 的对拍机制是**件头一段标记文本 ＋ 一个常量 ＋ 清单行**三者的自洽，**件头以外的散文**（例如"允许清单 = …③ fork 治理件（…）"这类行）**不在**对拍里 ⇒ 若将来有人只改散文段，本牙看不见（现读散文段与三者一致）。
3. 低危附注②：`④` 的 `allow_file=-` 在**内嵌档**是"无文件"的显式表示；若调用者显式传 `--allow` 指向一个**恰好等于内嵌内容**的文件，`allow_src` 仍为 `file`（如实），但两档的 `fp` 输入不同（覆盖面里的是牙本体）——此点记录在案，不判。
4. 低危附注③：本报告自身会引入"车道路径串"（`~/w28x/**`）——这与 `LANE-PATH` 牙的 `code` 档无关（报告是 data/注释类），但**若**该牙扫到了它，语料里应有对应的 provenance 行；现读 `LANEPATH=PASS code=0`，只作记录。

`T30_CLOSE_VERIFY=DONE verdict=pass tooth③=双向0/0+.editorconfig两处皆无+自造反极doc-drift=1 tooth④=root=+allow_src两档不同 tooth⑤=标签随来源变+件头成文 域未放宽=selftest18/18+三反极我自造反红双来源+真树PASS t16①=225==225(瞬时) t16⑥=WIRING_CLOSURE=PASS f0 t29=三处齐(2/6/2,2/4/2) findings=0阻塞/3低危`
`SELF_SHA16=db0a705e1d574faa`（口径＝去掉本行：`head -n -1 build/MilBridge/V79b-t16close-verify.md | sha256sum | cut -c1-16`）
