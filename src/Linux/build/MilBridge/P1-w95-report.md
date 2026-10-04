# P1-W95（`t176`）· `t170` 三条点名必修的落账（dated、只增不改）

**结论（三块）**
① `F-1`（high）**已落**：`NOINFO-FSIMETHODS-ABI` 记 **未解除** ＋「槽序未错位」**收窄**为「第 1／3 槽有语义指纹；其余 15 槽仅『非空＋零位一致』」＋ **逐槽登记已验／未验** ＋ 更正「判据明写解除条件」的出处（判据件里没有那句）。
② `F-2`（medium）**已落**：`calls` 的 witness **改引** `[FSPARALIST-EDRIVE]` 行数（**6 vs 0**）＋ `[FSPARAMETH-D3] gate=`，并把两族计数器（`rb_calls` ／ `g_pts_dp3_calls`）**分开点名**。
③ `F-3`（medium）**已落**：点名由 `FsFormatSubtrackFinite` 更正为 **`FsQuerySubtrackDetails`**（`EntryPointNotFoundException`，`[HC-UNHANDLED] #1/#2`），并逐条写清 **`t173` 未白做**。

**载体指向**：落点 ＝ `build/MilBridge/P1-fsimethods-drive-report.md` 末尾 dated 段（`⏪ t176（P1-W95）dated 更正 · t170 三条点名必修`）；本件 ＝ `build/MilBridge/P1-w95-report.md`（新建）。

---

## 1. 落点仅增不改（判据①）

| 项 | 读数（本席现取） |
|---|---|
| 落点件 改前 | `build/MilBridge/P1-fsimethods-drive-report.md`：**107 行**／`sha16=e1d50d10d7091b42`／`size=11671`／`mode=644`／`links=1`／`mtime=2026-09-29 19:02:33` |
| 落点件 改后 | **152 行**／`sha16=63326eeb9ac670ee`（**+45／删 0**） |
| 只增不改 | `diff <备份件> 现盘` ⇒ **删行数 0**、加行数 45（备份件 ＝ `~/w281-scribe/t176/bak/P1-fsimethods-drive-report.md.pre-t176`，`cp -p` 取在**任何写之前**，逐位等于改前值） |
| 原文未删（抽样现取） | `槽序指纹支持` 命中 2／`部分已解除` 命中 2／`FsFormatSubtrackFinite` 命中 5（**含被更正的原句**）／`t173` 命中 2 |
| 自证 | 新末行自证 `86eeec48f329e9f5`；`head -n -1 | sha256sum | cut -c1-16` **当场复算 MATCH=YES**（**上一条自证行原文保留在上方**，现取该件 `自证` 命中 4 处） |
| 只增不改（**对 `HEAD` 的硬口径**，现取 `2026-09-29T19:5x+0800`） | `git cat-file -e HEAD:<落点件>` ⇒ **`IN-HEAD=yes`**；`git diff --numstat -- <落点件>` ⇒ **`45 0`**；`diff <(git show HEAD:<落点件>) 现盘` ⇒ **删行数 0**、加行数 45；**`HEAD` 版 ＝ 107 行／`e1d50d10d7091b42`，与我的 `cp -p` 备份件逐位相同** ⇒ 我改前**无第三方漂移**（`D-G181` 那个"已提交件上空转"的坑在本件**不适用**）。 |
| 落盘方式 | `temp + os.replace`，保留 `mode 644`；**含锚区间前置断言**（照裁定五十七 (a) 的教训）：断言 ① 行数＝107 且 `sha16`＝`e1d50d10d7091b42`；② 三处**被更正原文锚**在场（`槽序指纹支持`／`部分已解除`／`FsFormatSubtrackFinite`）；③ 末行是该件自证行。任一不成立 ⇒ **不写**（脚本 `exit 3`）。 |
| ⚠️ 自伤与更正（同趟自捕） | 第一遍把**自证算在"追加块末尾（不含分隔空行）"上** ⇒ 末行自证与 `head -n -1` 复算**不一致**（`221ee760d2f20714` vs `7af0b8eb3cb5f485`）。处置：从备份**逐字还原**后修脚本（自证算在**含分隔空行的"末行之前全文"**上）重跑 ⇒ 现取 MATCH=YES（终态删行数仍为 0）。**已在册、不掩盖。** |

---

## 2. `F-2` 的成对读数（**本席自己从原始腿日志现取**，读时 `2026-09-29T19:5x+0800`）

原始日志目录：`/home/links-dev/t123-runner/logs/t168/`（只读）。

| 腿 | `[FSPARALIST-EDRIVE]` | `[FSPARAMETH-D3] gate=` | `[FSPARAMETH-READBACK]` | `[FSPARALIST-PARA-IN]` |
|---|---|---|---|---|
| `app-snapdrive` | **6** | 2 | 2 | 2 |
| `app-snap` | **0** | 3 | 3 | 2 |
| `app-null` | **0** | 3 | 3 | 2 |
| `app-allzero` | **0** | 3 | 3 | 2 |

⇒ witness ＝ **`[FSPARALIST-EDRIVE]` 6 vs 0** ＋ `[FSPARAMETH-D3] gate=`（四腿都有）✓；且**两族 `calls=` 不是同一把标尺**（`FSPARAMETH-READBACK` ＝ `rb_calls` 回读序；`FSPARALIST-PARA-IN` ＝ `g_pts_dp3_calls` 窗口计数）⇒ `t170` `F-2` 的"如述不成立"**本席独立成立**。

## 3. `F-3` 的现取读数与「`t173` 未白做」

- `FsFormatSubtrackFinite` 在 `app-snapdrive.log` 命中 **0**；实际具名行：**第 842 行** `[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'FsQuerySubtrackDetails' in shared library 'PresentationNative_cor3.dll'`，**第 848 行** `#2`（行号**仅本次有效**）。
- `t173` 载体现取：`build/MilBridge/P1-fsformatsubtrack-report.md` **105 行**／`sha16=657aa706a681a56f`；`S-1` 成立、`S-2` 维持 `NOINFO`（分列纪律）、`M1` 六条形态全中、`-100002 → 0` 读数 —— **这些成立项不依赖点名** ⇒ 点名更正**不影响** `t173` 的任何读数（"未白做"的依据）。

## 4. 引用与代际（判据③）

| 被引件 | 代际（本席现取） | 时刻 |
|---|---|---|
| `build/MilBridge/P1-fsimethods-verify.md`（`t170` 复核件，三条必修的出处） | **152 行**／`sha16=8aa9a184c9069d9b`／末行自证 `21ea356bacc7faca` | `mtime 2026-09-29 19:2x`（现取 `ls`） |
| `build/MilBridge/P1-fsformatsubtrack-report.md`（`t173`） | **105 行**／`sha16=657aa706a681a56f` | 现取 |
| `build/MilBridge/P1-fsimethods-drive-report.md`（落点） | 改前 `e1d50d10d7091b42` → 改后 `63326eeb9ac670ee` | 落盘 `2026-09-29T19:57:45+0800` |

## 5. 具名 `NOINFO`（本席未做/取不到的，逐条点名）

1. **逐槽「已验／未验」的判定依据**：本席**照抄** `t170` §2.3／§9 的口径（**未独立复算**其指纹数据）。
2. **`t170` `F-1` 里"判据件里 0 命中"那条 `grep`**：**未独立复算**（只在落点段里标注「引自 `t170`／本席未独立复算」）。
3. **`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 的当前状态**：本件**未核**（只落点名更正；是否已解属 `t173`／后续件射程）。
4. **`bin/libwpfwin32.so` 的 pre 值**（`t170` §9 `N-1`）：本席**不可独立复取**（`bin/` 不在 git ＋ 目录已被在飞代际重建）⇒ 沿用 `t170` 的 `NOINFO`。
5. **本件未跑腿、未构建、未跑整趟门禁、未占显示位**（`/tmp/.X11-unix` 现取 `X0 X1`）。
6. **写域说明（请队长确认口径）**：本件除本载体外，**只**改了上表落点件一处（`F-1` 修法原文就指定"在 `drive-report` 做 dated 追加"）；**未碰**任何 `.cs`、`src/**`、`tools/**`、哨兵、`HANDOFF-NEXT.md`；未 `git add/commit/push`。
7. ⏪ **本载体自报口径更正（dated，现取 `2026-09-29T19:5x+0800`；只增不改）**：本载体**初稿**第 1 节曾写「该件**不在 `HEAD`**（`git status --porcelain` 为 `??`）」—— **该句是错的**（当时我只看了被过滤的 `porcelain` 输出就下了推断，**没有**用 `git cat-file -e HEAD:<路径>` 取硬读数）。**现取硬读数**：`IN-HEAD=yes`；`git diff --numstat -- <落点件>` ⇒ `45 0`；`git show HEAD:<落点件>` ＝ **107 行／`e1d50d10d7091b42`**（与我的备份件逐位相同）。⇒ 上表该行**已按硬读数改写**；初稿错句**在此留档**（不删、不掩盖）。

self16=56363a9bad6c72e0
