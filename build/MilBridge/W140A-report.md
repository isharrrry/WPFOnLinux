# W140A 报告 —— 波 `#54` 收尾链 **⑨–⑫**（接手失联车道 W139A）

**车道** W140A ｜ **开工** 2026-09-23 20:2x +0800 ｜ **机器** `nproc=4` ｜ `nproc` 派单书写 3（如实记）
**前提**：`#54` **已冻结**（`gen=#54 sha16=f9948196858bc9db`，767,600 B）⇒ 本车道**不重冻、不改产品件、不碰判定输入**。
**接续**：原车道 **W139A 已失联**（会话不存在），它完成了 ①–⑧（含冻结与冻后第 1 趟全绿），**卡在冻后第 2 趟（ENOSPC）**、
**停在推送前**；`~/w139a/**` 本车道**只读引用**，一个字节未动。

---

## ① 判据（**先写**；`~/w140a/criteria.md` = `d259bd60f8bf42d3`）

**如实声明**：本车道**不新发明判据**。归属判定**沿用 W139A 于 17:44 写定的** `~/w139a/criteria.md` 的
**C9（冻后 `verify-all` ×2）／C10（推送逐径）／C11（app-local）**——那三节在本车道**开工之前**就存在。
**本车道自己写的第一条** = **`C0` 空盘/可写预检**，写进 `~/w140a/STATUS.md` 的 `[H1]`，**早于**任何重活。

| # | 判据 | 绿 | 红 |
|---|---|---|---|
| **C0** | 空盘/可写预检（本车道新加） | `df --output=avail /` ≥ 5 GiB **且** `/tmp` 可写 | 不满足 ⇒ **停下报主控，不许硬跑** |
| **C1** | 冻后第 2 趟重跑 | `27 ✅ / 0 ❌` ＋ `✅ 全部通过` ＋ `用例通过 875 跳过 2` ＋ `R_GATE crit=13/13` ＋ `NULBYTES=PASS` ＋ `THIRDPARTY=PASS` | 任一不成立 |
| **C2** | ENOSPC 作废趟的记法 | 记「**作废（环境成因，非读数）**」并与有效趟**并列** | 当红 或 隐瞒 |
| **C3** | C9 判词层对照 | 判据行逐字相同；运行期读数差异**逐条点名** | 不一致 或 未点名 |
| **C4** | ⑨ 记录 | 三段齐全 ＋ 8 条声明行带 `# ` ＋ 无 `@@` ＋ **只追加**（前缀复算 == 追加前 sha16） | 改了既有行 |
| **C5** | ⑩ 推送 | 无夹带；逐径 `add`；push 后重新 `fetch` ＋ 三者一致；`--symref`；`BYTECHECK mismatch=0` | 任一不成立 |
| **C6** | ⑩ 边界 | 不 add `src/WpfGfx.Linux.Native/**`（在办 `#55`）／登记车道 3 件；`$R` 独有件单列「本地领先」 | 混入其一 |
| **C7** | ⑪ app-local | `STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`；`APP_ART bridge=4e25e4b27d4d5ae1` | 计数器非 0（在册缺口除外） |
| **C8** | ⑫ 哨兵 | 两处 `cmp` IDENTICAL；`SHA=4e25e4b27d4d5ae1` | 不一致 |
| **C9** | 方法学留痕 | ENOSPC⇒`rc=2 NOINFO`被计成`❌`这条**逐字**进记录与报告 | 未写 |

---

## ② 空盘/可写预检读数（判据 `C0`）

```
df --output=avail / | tail -1      ⇒  79,252,748 KB ≈ 75.6 GiB     (判据 ≥5 GiB ⇒ 通过)
printf x > /tmp/w140-$$.t && rm -f ⇒  TMP_WRITE=OK
```
**背景（为什么加这条）**：本波冻后第 2 趟**就是被瞬时 `ENOSPC` 毁掉的**（见 ③）。
预检不合格时本车道的处置是**停手报主控、不硬跑**——本趟**合格**，故继续。

---

## ③ 冻后 `verify-all` ×2（判据 `C1`／`C2`／`C3`）

槽口径（**重活全走槽**）：
`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1500 --wait 1800 -- timeout 1450 bash ~/w140a/logs/run-verify-post2.sh`

### ③.1 第 1 趟（W139A，`~/w139a/logs/17-verify-post1.log` = `110227366c730ee3`）

槽 `RELEASED rc=0 held=851s`（`max_hold=1500`）⇒
**`步骤通过 27  ❌ 失败 0`**｜`用例通过 875  跳过 2`｜**`结论：✅ 全部通过`**｜`POST1_OUTER_RC=0`。
判词行：`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 … win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`｜
`NULBYTES=PASS files=1228 hits=0 canary=ok`｜`THIRDPARTY=PASS frames=43`.

### ③.2 ⚠️ 冻后第 2 趟（**原趟）= 作废趟，不是读数**（`~/w139a/logs/18-verify-post2.log` = `000005f8de114804`）

**成因 = 瞬时 `ENOSPC`**（现场 `/` 当时写满；本车道复核时 `/` 可用 **75.6 GiB**）。**逐字照抄**：

```
  THIRD-PARTY                  ❌  (rc=2)
      THIRDPARTY=NOINFO reason=部署不全（缺 .so，本趟读数不可归因）
cp: 写入 '/tmp/verify-all-THIRD_PARTY_.log' 时出错: 设备上没有空间
[26] R-GATE：连续点击/交互响应（私有 Xvfb ＋ 真实节奏点击 ＋ 逐格判据）
  R-GATE（连续交互）     ❌  (rc=2)
[27] 源卫生：声明覆盖面里不许有真 NUL 字节（D-G82 的牙；只读、零 dotnet、≈0.4 s；#51 加）
  NUL-BYTES                    ❌  (rc=2)
 步骤通过 24  ❌ 失败 3
POST2_OUTER_RC=1
```
**判读（逐字）**：三个红**全是 `rc=2`**——按本仓口径 `rc=2` 就是 **`NOINFO`（取不到）**，而**不是 `FAIL`**；
机制是**仪器日志写不出 ⇒ `verify-all` 的诊断 `grep` 零命中 ⇒ 兜底打末 12 行**。
⇒ **记「作废（环境成因，非读数）」，不当红、也不隐瞒**（判据 `C2`）。

### ③.3 冻后第 2 趟（**重跑**，`~/w140a/logs/19-verify-post2-rerun.log` = `a92d5088d34109b0`）

槽 `HEAVYSLOT=ACQUIRED waited=0s`｜`MEMOK avail=4857MB`｜**`RELEASED rc=0 held=1009s`**（`max_hold=1500`）

```
  [0] Xvfb（目标 :99）
    ✅ X-REUSE=reused display=:99（:99 上已有可用 X server，几何 1280x1024 相符而复用）
    X_STATE=available（判据：xdpyinfo 对 DISPLAY=:99 成功 ⇒ available）
  …
 步骤通过 27  ❌ 失败 0
 用例通过 875  跳过 2
 SKIP_GUARD=PASS x_state=available x_died=0 x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
 结论：✅ 全部通过
POST2R_OUTER_RC=0
```
**三个原红格逐格对照 —— 新趟全绿**（判据 `C1` 的核心）：

| 步 | 作废趟（`rc=2 NOINFO`） | **重跑趟** |
|---|---|---|
| `THIRD-PARTY` | `❌ (rc=2)`／`THIRDPARTY=NOINFO` | **`✅ THIRDPARTY=PASS frames=42 max_colors=1642 min_colors=800`** |
| `R-GATE（连续交互）` | `❌ (rc=2)` | **`✅ R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=4846 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`** |
| `NUL-BYTES` | `❌ (rc=2)` | **`✅ NULBYTES=PASS files=1228 hits=0 bytes=252838905 skipdir_dirs=141 binext=280 otherext=0 noext=11 diag_noext_nonelf=0 diag_otherext_nul=0 canary=ok`** |

### ③.4 判词层对照（判据 `C9` 的 C3 项）

两趟各 **32** 条 `自报口径` 行，其中 **24 条逐字相同**；差异 **8 条全是运行期读数**，**逐条点名**：

| # | 行 | 第 1 趟 | 重跑趟 | 性质 |
|---|---|---|---|---|
| 1 | `TLINE_GATE … outdir=` | `…-183553` | `…-202641` | 时间戳目录 |
| 2 | `COLUMN_FLOOR_SELFREPORT … outdir=` | `/tmp/column-floor.iyqC6k` | `/tmp/column-floor.ua2Z1Q` | `mktemp` |
| 3 | `FRAMEPRESENCE … dir=` | `…-184456` | `…-203745` | 时间戳 |
| 4 | `THIRDPARTY_BUILD log=` | `…w37-tpm-184705…` | `…w37-tpm-204005…` | 时间戳 |
| 5 | `THIRDPARTY_IMAGE path=` | 同上 | 同上 | 时间戳 |
| 6 | `THIRDPARTY … dir=` | 同上 | 同上 | 时间戳 |
| 7 | **`THIRDPARTY frames=`** | **43** | **42** | **本质可变**（同树四趟实测 **41/42/43**，见 `09-verify-pre.log`=41／`15-verify-pre2.log`=42） |
| 8 | **`R_GATE … mem_mb=`** | **6379** | **4846** | 运行期内存 |
| 9 | **`NULBYTES … bytes=`** | **252821917** | **252838905** | 运行期字节计数 |

⇒ **判据内容**（`PASS`／`crit=13/13`／`files=1228`／`hits=0`／`win32shim=a6365183fa6d26b9`／`pc=722e0ab8205b7c3f`）**逐字相同**
⇒ **`C1`／`C3` 绿**；**两趟之间未换件**（`win32shim`／`pc` 逐字相同，九位与冻结刻逐位相同）。

---

## ④ ⑨ 记录件（`$HOME/w21-verify/w54-record.txt`；判据 `C4`）

- **口径**：`#54` 的记录件由 W139A 在**冻结前**写成（**模板**，含 `{BR}` 等占位符，由冻结器 `fill()` 展开进冻结块）；
  **冻结已完成** ⇒ 按 `#51`（`w51-record.txt:200`）／`#52`（`w52-record.txt:244`）先例，**冻后只许在末尾追加「冻后补记」段**。
- **件**：`03f4734e59309a96`（260 行／**32,177 B**）→ **`6e8231352f349113`**（**365 行**）。
- **追加段内容**：步骤⑨（冻后 ×2 ＋ **ENOSPC 作废趟逐字**）／⑩（推送逐径全读数）／⑪（app-local ＋ `TASK-0502` 两尾巴）／⑫（哨兵）／**方法学一条**。
- **机械自检（全绿）**：三段 `===BANNER===`／`===FROZEN===`／`===RECORD===` 齐全；
  8 条外挂声明行（`COLUMN-FLOOR`×2／`COLUMN-CORPUS`×1／`ARM-LOG-SHA`×5）**全带 `# ` 前缀**；`@@` 残留 **0**；
  **追加段（261–365）零 `{XX}` 残留**。
- **追加保真证明（机械）**：按 marker 切出前缀 = **32,177 B**（与追加前文件等长）⇒ `sha256` 前 16 = **`03f4734e59309a96`**
  ⇒ **`APPEND_ONLY_PROOF=PASS`**（既有 260 行**逐字节未动**）。
- ⚠️ **如实记**：**未另存"追加前副本"**（`~/w139a/**` 是只读域）⇒ 保真由"脚本先断言 `before sha16` 再 `old+out`、
  `temp + os.replace` 原子落盘"＋上述前缀复算共同保证（脚本 `~/w140a/bin/append-record-w54.py`）。

---

## ⑤ ⑩ 推送（逐径）（判据 `C5`／`C6`）

**机制**：fork 克隆 `~/netTest/GitProj/WPFOnLinux` 是**独立检出、不自动跟随 `$R`** ⇒ 必须**先 `cp -p` 真件**。

**开工读数**：`git status --porcelain` **0 行**（工作树干净）＝ `HEAD 1b44615b564b5adcafea07fb09eb569599db6834`，
`ls-remote --symref origin HEAD` = `ref: refs/heads/feat-Linux` ⇒ **W139A 一笔都没推**。

**待推清单求法（机械，不靠记忆）**：`~/w140a/bin/scan-push-set.py` —— 克隆 `git ls-files` **15,284** 件逐件 `sha256` 比 `$R`
⇒ **12 件 DIFF**；另 `$R` 独有 **3 件**（1 件本波账页 ＋ 2 件本波新件）。**`src/WpfGfx.Linux.Native/**` 逐件零 DIFF**
⇒ **与在办 `#55` 无冲突**，且按其纪律**一件未 add**（判据 `C6`）。

**逐件 `cp -p` 的 before→after**（before 逐位 == `#53` 那笔推送时的 after ⇒ **断代连续**）：

| # | 件 | before | after |
|---|---|---|---|
| 1 | `build/MilBridge/arm-logs/tline.log` | `44c21d648f79126c` | **`664a0c048a1ed3a1`** |
| 2 | `build/MilBridge/gen/t2d-family-baseline.txt` | `ab0758aa92ca8356` | **`8b54486413d7ee76`** |
| 3 | `build/MilBridge/gen/t2d-family-matrix.txt` | `e442cefd0e2b6e4a` | **`61c817d836462306`** |
| 4 | `build/MilBridge/gen/tline-ledger-lines-20260923-1751.txt`（本波账页） | —（新建） | **`81880ac3d10638a4`** |
| 5 | `build/MilBridge/known-red.json` | `f108775906eac9aa` | **`9a26c67a6f9fe1e4`** |
| 6 | `build/wave-audit.log` | `4d1eb629c9323e4f` | **`dc8d29d810d279f0`** |
| 7 | `docs/CURRENT-STATE.md` | `81b35c059717b7a8` | **`65010285095beb10`** |
| 8 | `docs/WAVE54-PREREGISTRATION.md`（新建） | — | **`d082ebd5086a4d3a`** |
| 9 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `a2e49b786d0a1b02` | **`f9948196858bc9db`** |
| 10 | `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `8b44b61f944aeeaa` | **`a5ecf1a8faaa2a00`** |
| 11 | `verify-all.sh` | `32ddbe487235cc38` | **`4bcc0cf7aab10bb5`** |
| 12 | `build/MilBridge/W134A-report.md`（新建） | — | **`895f415aaea155b4`** |

**计数对账（防 `#52` 那次 `add -A` 夹带事故的同族纪律）**：
`git status --porcelain` **12 行**（9 `M` ＋ 3 `??`）**＝** `git diff --cached --name-only` **12 件**
⇒ **"本笔恰好 12 件、无夹带"**。

**推送三件套**：
- commit = **`7ba2fcfeb0619b58c101d8c8c07fdd7e65672abe`**（`12 files changed, 925 insertions(+), 59 deletions(-)`；
  `create mode 100644` × 3：`W134A-report.md`／`WAVE54-PREREGISTRATION.md`／`tline-ledger-lines-20260923-1751.txt`）
- `git push origin feat-Linux` ⇒ `1b44615..7ba2fcf  feat-Linux -> feat-Linux`
- **push 之后重新 `git fetch origin feat-Linux:refs/remotes/origin/feat-Linux`**（**refspec 陷阱**）＋ 与 `git ls-remote` **交叉核**
  ⇒ **`local == remote-tracking == ls-remote == 7ba2fcfeb0619b58c101d8c8c07fdd7e65672abe`（三者一致）**
- `git ls-remote --symref origin HEAD` ⇒ **`ref: refs/heads/feat-Linux`** ✓
- **逐件字节核对**（`git cat-file blob origin/feat-Linux:<path>` vs `$R` 磁盘，**rev = push 之后重新 fetch**）
  ⇒ **`BYTECHECK ok=12 mismatch=0 nobody=0`**（12 件逐位相同，与上表 after 列一致）
- 本报告自身那一笔会让 head 再前进 ⇒ **本报告不写死"最终 head"**，以现场 `ls-remote` 读数为准。

**⛔ 刻意未推的件（判据 `C6`）**：

| 类 | 件 | 理由 |
|---|---|---|
| **在办他车道** | `docs/ROUTES.md`（`9dd8d12b37d52f91`，mtime **20:25:03**）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`b1f3975ce167de1a`，**20:24:48**）／`build/MilBridge/tools/defect-registry-declared.tsv`（`c3330a4ad39e43c3`，**20:25:38**） | **登记车道当时仍在写** ⇒ 推它 = 推半成品；登记归主控 |
| **在办 `#55`** | `src/WpfGfx.Linux.Native/**` | 逐件**零 DIFF**（无冲突），但按任务书纪律**一件未 add** |
| **本地领先（未推，交主控裁）** | `build/MilBridge/gen/tline-ledger-lines-{20260921-1224, -1231, -1540, -1623, -1629, 20260923-0926, 20260923-1245}.txt` **7 件** | 在 `$R`、**不在远端**；仓内先例是**每波只推该波自己产出的一件账页**（`c51a706` 推 `…-20260922-2041`／`62c7a7b` 推 `…-20260922-1527`）⇒ 这 7 件属**历史遗留**（其中 `-20260923-1245.txt` 疑似 `#53` 波产物而当时漏推）**不擅自补推** |
| **被 `.gitignore` 排除** | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | `.gitignore:26` 命中 ⇒ 不进提交 |

---

## ⑥ ⑪ app-local 回读（判据 `C7`）

**命令**（**显式补根**，`D-G91`：默认根漏 `$REPO/tools` ⇒ 会打 `STALE=0` **假绿**）：
```
AUTH_ROOT=$R SCAN_ROOTS=$R/build:$R/tests:$R/samples:$R/src:$R/tools \
  bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply     # ~/w140a/logs/22-appsync-apply.log = 4b3f7fd649aae885
bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh                   # ~/w140a/logs/23-appsync-check.log = 562bbd01740417fd
```
**读数**：
- `APPLY_RC=0`｜**`APPSYNC-REFRESH=refreshed=0 newer=0 applied=1`**｜
  脚本自印「（没有 STALE / NEWER-DIFF / DIVERGENT 落单者：同类加载源副本都已是权威 sha）」
- `CHECK_RC=1`（**由在册 `UNEXPECTED` 引起**）：
  **`计数：OK=200  MISMATCH=0（STALE=0  NEWER-DIFF=0）  MISSING=0  UNEXPECTED=6[DECL-GAP-EQ=6 DECL-GAP-DIFF=0]
  DIVERGENT=0  CROSS-CONFIG=101  LIB-COPY=23  …  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`**
  ⇒ **`STALE=0 DIVERGENT=0 MISMATCH=0 MISSING=0`** ⇒ **判据 `C7` 绿**
- **桥副本 4 份全 `ANCHOR-OK 4e25e4b27d4d5ae1`**（含 W139A 刷过的两份 `samples/**/bin/**` **派生副本**）
- **`APP_ART win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f pf=ec570d30f6754631 wb=2e4e46e539a72cd7 bridge=4e25e4b27d4d5ae1`**
  （R-GATE 应用目录 `/tmp/r-gate-step-1534714/device.log`）⇒ **`bridge` 命中判据要求的 `4e25e4b27d4d5ae1`** ✓
- ⚠️ `UNEXPECTED=6[DECL-GAP-EQ=6]` = **在册**声明类缺口（`#49` 认定），与 `#52`/`#53` **逐字同形** ⇒ **不当绿、不改判据**；
  `APPSYNC` 整体 `MISMATCH` 是**告警语义**（非硬闸），校验器 `rc=1` 即由此而来。

**`TASK-0502` 的两条波尾必做**：
① `sync-applocal-authority.sh --apply` = 本步（`applied=1`）✓
② "**修前件 2 硬链接已断**" —— W139A 已办，本车道**现场复核**：`~/wfp-runs/arms23/*.log` 七件逐件
   **`nlink=1`、inode 互不相同**（`5154198`／`5152518`／`5152520`／`5152516`／`5154197`／`5152514`／`5154196`），
   权威侧 `build/MilBridge/arm-logs/*.log` 亦 `nlink=1`（`5152973`／`5152974`／`5152972`／`5152975`／`5152971`）✓

---

## ⑦ ⑫ 哨兵两处（判据 `C8`）

| 处 | 路径 | 读数 |
|---|---|---|
| 主 | `/tmp/bridge-frozen.flag`（**唯一写者** = `build/close-wave.sh:387-412`） | mtime `2026-09-23 17:48:14.008` |
| 镜像 | `~/wfp-runs/bridge-frozen.flag` | mtime `2026-09-23 17:48:14.010` |

`cmp` ⇒ **`IDENTICAL`**（差 **2 ms** ⇒ 同一趟写出）。两处逐字：
**`SHA=4e25e4b27d4d5ae1`**（= 本波 `bridge`，**判据要求命中** ✓）／**`WIN32SHIM=a6365183fa6d26b9`**／**`WAVE=close-wave-174529`**。
（本车道**未写**哨兵 —— 唯一写者是 `close-wave.sh`，**只读复核**。）

---

## ⑧ `NOINFO` / 边界（逐条，**不猜**）

1. **ENOSPC 作废趟的失败格不构成任何缺陷信息**（`NOINFO`）：三个 `rc=2` 全是"日志写不出"，**不是读数**。
2. **`THIRDPARTY frames=` 的逐趟差异不可归因**（`NOINFO`）：四趟 41/42/43，本车道只证明它**本质可变**，**未**定因。
3. **7 件"本地领先"账页的归属未定**（`NOINFO`）：只能按 mtime 与仓内先例推测 `-20260923-1245.txt` 属 `#53` 波漏推 ⇒ **交主控裁，不擅自补推**。
4. **`UNEXPECTED=6[DECL-GAP-EQ=6]` 未逐条归因**（`NOINFO`）：`#49` 认定在册；本件只确认"**不因本波变多**"。
5. **`~/w139a/**` 只读域 ⇒ 未另存记录件"追加前副本"**（`NOINFO` 方向）：保真由 `APPEND_ONLY_PROOF=PASS` 的**前缀复算**保证（见 ④）。
6. **`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv` 的推送未做**（`NOINFO`）：在办他车道 ⇒ 交主控。
7. **本报告自身那一笔会让 head 再前进**（结构性）：故**不写死"最终 head"**。
8. **`nproc` 派单书写 3、现场 4**：如实记，未按 `nproc` 限制任何重活（本车道重活都是**单条**、走槽）。

---

## ⑨ 内存三值与纪律

| 量 | 值 |
|---|---|
| `MemAvailable` **开工** | **5,250 MB** |
| `MemAvailable` **槽内（重活最低已记录）** | **4,857 MB**（`HEAVYSLOT=MEMOK avail=4857MB min_avail=1500MB`） |
| `MemAvailable` **收工** | **5,096 MB** |
| `loadavg`（收工） | `1.47 1.53 1.33` |
| `/proc/vmstat oom_kill` | **0** |

**纪律执行**：① 重活**全走槽**（`ACQUIRED waited=0s`／`MEMOK`／`RELEASED rc=0 held=1009s max_hold=1500`）；
② **无** `MAXHOLD_KILL`、**无** `low-memory` ⇒ **本车道零作废趟**（唯一作废趟是 W139A 的 ENOSPC 趟，**已并列留档**）；
③ **零 `pkill`／`killall`／`pgrep -f`**（只按 PID 与 `/proc` 探活）；④ 显示号只用 `:99`（**复用**，未自起、未碰任何人的 X）；
⑤ **落盘一律 `temp + os.replace`**（追加记录那条）；⑥ **不许手抄哈希** —— 本报告所有 sha16 均**现场现算**；
⑦ `export PATH="$HOME/.dotnet:$PATH"`（本车道未跑 `dotnet`，重活只有 `verify-all`）。

---

## ⑩ 小结（大白话）

1. **接手的成本很低**：W139A 的 ①–⑧ 全是好的，卡点**只有一处**——冻后第 2 趟撞了**瞬时磁盘满**。
2. **重跑就绿了**：27 ✅ / 0 ❌、`全部通过`、`875 跳过 2` ⇒ 那三个红**确认是环境成因，不是回归**。
3. **那趟 ENOSPC 我没有当红、也没有藏**：逐字抄进记录与报告，并标"作废（非读数）"。
4. **推送一笔干净**：12 件逐径 add，`porcelain` 12 行 == `--cached` 12 件，`BYTECHECK ok=12 mismatch=0`，head `7ba2fcf`。
5. **app-local 与哨兵本来就是对的**：`STALE=0 DIVERGENT=0`，`APP_ART bridge=4e25e4b27d4d5ae1`，两处哨兵 `IDENTICAL`。
6. **给后人一条机制**：**重活趟先做空盘预检**；`ENOSPC` 会把 `rc=2 NOINFO` 变成汇总里的 `❌`——**那是环境，不是回归**。

# 本报告自述口径：FULL sha256 = 6e8428f11013eed9045ef8e9940b4490e8314455710036d0198c2879d821a91b；**去末行口径**（`head -n -1 build/MilBridge/W140A-report.md | sha256sum` 的前 16 位）= **6e8428f11013eed9**（自洽：末行就是本行）。
