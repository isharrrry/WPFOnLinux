# P1-w2-heavy-criteria —— `t14`（W2）遗留两条重活腿的**补跑判据**（**先写，后跑**）

> 车道 `runner`／任务 `t20`。**本件在任何一条腿开跑之前落盘**；跑完只许**追加**（dated append），不许改上面的判词。
> **写作时刻**：`2026-09-28T20:2x+08:00`（§0 逐格现取）。**任务**：把 `t14` 报告里因**槽被占**而记 `NOINFO(reason=heavy-slot 被占)` 的两条腿 —— **`B-3②`（`CoverageProbe` 三支 tab 臂）** 与 **`B-9`（`session_inner.sh` 真 `:237` 被真 `Xvfb` 占用腿）** —— 换成**真读数**（或如实记**仍不可得的具名原因**）。

---

## §0 元信息（全部**现取**）

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | 见 §7 复算（跑前现取） | `git rev-parse HEAD` |
| 臂宿主 | `build/MilBridge/tests/CoverageProbe/Program.cs` ＝ **`c78ed88fc1fd34f4`** | `sha256sum` |
| 臂产物（跑它，不重建） | `build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll` ＝ **`7d8ebb1e987a3b4b`** | 现取（mtime `09-28 10:31`） |
| 三支语料 | `tab-zero-oracle.json` **`256007ce706c7d3f`**｜`tab-anchor-oracle.json` **`0cebc0afd5142fbf`**｜`tab-rtl-oracle.json` **`01934a73b7d5655`** | `sha256sum` |
| `B-4` 牙 | `build/MilBridge/tools/pkg-src-retiredpath-check.sh` ＝ **`e0ab7bd668ffa8a1`** | `sha256sum` |
| `B-9` 被测件 | `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` ＝ **`a70aeb1d988ebc9e`** | `sha256sum` |
| 五臂门禁（只作对照读，**不跑**） | `build/MilBridge/tools/tline-gate.sh` ＝ **`747c078dbf040862`** | `sha256sum` |
| 显示位 | **`:236`（占用腿，我起 Xvfb）**／**`:235`（空号对照腿）** —— 只用 `:2xx` 私有号、几何 **`1280x1024x24`** | 起前 `[ -S /tmp/.X11-unix/X<d> ]` 断言 |
| 槽 | `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <批脚本>`，**后台作业** | — |
| 车道根 | `~/t20-runner`（台账／日志只落这里；**不落 `/tmp`**） | — |

**在册入口（逐字照抄，不改）**：
- 三支 tab 臂（`build/MilBridge/arm-logs/README.md` `:15`–`:17` 的形）：
  `(cd build/MilBridge/tests/CoverageProbe/bin/Release && dotnet PresentationCore.Tests.dll --tab-lines-oracle <repo>/tests/parity/windows/<臂>/out/<臂>-oracle.json)`
  臂 ∈ `tab-zero`／`tab-anchor`／`tab-rtl`。
- `B-9`：`W67_DISPLAY=<号> bash build/MilBridge/tests/PtsPagesProbe/session_inner.sh <tag> A:1`（脚本自足；`W67_WORK`／`W67_BIN` 可覆盖）。

**两条已现取的**结构事实**（决定了判据怎么写）**：
1. `Program.cs:141` ⇒ `--tab-lines-oracle` **提前 `return`**，**永不**走到 `:158` 的自检块（那里才会打印 `Root + "/build/fonts/NotoSans-Regular.ttf"`）⇒ **三支臂的日志在结构上不可能带根路径签名** ⇒ 在册 `NOINFO(臂日志零签名)` 的成因**是"判法选错了取证口"**，不是"面一定死"。⇒ 本件改用**根敏感性**判活/死（§2 腿 5）。
2. `Program.cs:88` ⇒ `Root` 是**静态字段 ＋ `?? throw`** ⇒ `WPF_PROBE_COVERAGE_ROOT` **未设**时进程在 `Main` 之前就**响亮失败** ⇒ 这给出一条**可判的两极腿**（§2 腿 4）。

---

## §1 通用纪律（每条腿都适用）

1. 重活**一律**走槽（外层 `--min-avail 2500 --max-hold 1800 --wait 3600`）＋**后台作业**；批内子命令走 `NESTED_SKIP`。
2. 批开跑前现取并写进日志头：`MemAvailable`／`SwapFree`（停手线 **2500 MB**／**512 MB**）＋ `df -Pk` 余量（≥ **5 GB**）。
3. `HEAVYSLOT=TIMEOUT`／`NOINFO low-memory`／`MAXHOLD_KILL` **都不是读数** ⇒ 该腿**不入分母**并**点名**。
4. 进程**只按 PID** 收（先 `TERM` 后 `KILL`）；**禁** `pkill`／`killall`／`pgrep -f`；扫 `/proc` 时显式排除 `$$` 与祖先链。
5. **显示位只许我起**：起 `Xvfb :236` 时把 PID 落 `~/t20-runner/xvfb236.pid`；收尾**只按该 PID**；收尾后必须复扫 `/proc` 断言**零残留**。
6. 台账落 `~/t20-runner/**`；过 MB 日志只许 `wc`／`head`／`tail`／`grep -c`。
7. **不许**改任何仓内既有件（本波**取读数**）；不 `git add/commit/push`；不跑 `verify-all`／不构建。

---

## §2 `B-3②` 判据（`CoverageProbe` 三支 tab 臂 ＋ 死根面）

**分母 ＝ 5 条腿**（腿 1–5），逐腿判：

| 腿 | 形态 | 期望（**先写**） | 不成立（⇒ 判红／点名） |
|---|---|---|---|
| **1** | `tab-zero`，`WPF_PROBE_COVERAGE_ROOT=$N` | 产出 `TAB_LINES START …` 与 `TAB_LINES OVERFLOWED …` 机器行 ∧ 末行 `TAB_LINES 退出码=0…` | 缺机器行／`退出码≠0`／进程非零退出 |
| **2** | `tab-anchor`，同上 | 同上 | 同上 |
| **3** | `tab-rtl`，同上 | 同上 | 同上 |
| **4** | `tab-anchor`，**`WPF_PROBE_COVERAGE_ROOT` 不设**（反极） | **响亮失败**：输出含 `死根已清：未设 WPF_PROBE_COVERAGE_ROOT` ∧ 非零 rc | **静默跑通**（有机器行 ∧ rc=0）⇒ 判红并点名（说明 B-3① 的 `throw` 没接线） |
| **5** | `tab-anchor`，`WPF_PROBE_COVERAGE_ROOT=<**不存在**的目录>`（根敏感性） | 与腿 2 **逐格比**（见下） | 跑不出可判读数 ⇒ `NOINFO` |

**腿 1–3 的逐格对照（与在册臂日志）**：对每支臂，把现跑日志的机器行与 `build/MilBridge/arm-logs/<臂>.log` 的对应行**逐字段**比 —— `START`：`红`／`绿`／`判定行`／`NOINFO`／`非零真值行判定`；`OVERFLOWED`：`红`／`绿`／`判定行`／`NOINFO`／`真值True`；末行 `退出码`。**任一处不同 ⇒ 点名**（可能是"现树 vs 在册代"的位移，也可能是回归 —— 两者都必须具名，不许并成一句"一样"）。

**腿 5 的判词规则（死根面判活/死；这是本件要消解的那个 `NOINFO`）**：
- 腿 5 的机器行与腿 2 **逐字相同 ∧ rc 相同** ⇒ **该路径不消费 `Root`** ⇒ **「死根面」在这三支臂的路径上判「死」**（旧硬编码退役路径对这三支臂而言是死的 ⇒ B-3① 的清除**正确且必要**，因为它把"死面"从字面量变成**显式注入**）。⇒ 在册 `NOINFO(臂日志零签名)` **消解为「面＝死」**（附腿 4 证明"根仍是**进程级**必需"）。
- 腿 5 **失败**或机器行**有差异** ⇒ **消费 `Root`** ⇒ **「面＝活」** ⇒ `NOINFO` 消解为「面＝活」并**点名**第一处差异。
- 腿 5 因**与根无关**的原因失败（如缺语料）⇒ `NOINFO`（点名），**不许**当"面死"。

**签名读数（辅助，不当绿也不当红）**：逐腿印 `grep -c 'wpf-linux-20260906'`（退役 needle）与 `grep -c '<$N 的绝对路径>'`；**零签名只作说明**（因为 §0 事实 1 ⇒ 结构上不可能有签名）。

**分母口径**：作废（不入分母、必须点名）：`HEAVYSLOT=*` 非 `ACQUIRED`／`PROBE_ARTIFACT_MISSING`／`CORPUS_MISSING`／批超 `MAXHOLD_KILL`。`NOINFO`：腿 4/5 判不出（缺可判读数）、腿 5 因与根无关原因失败。

---

## §3 `B-9` 判据（`session_inner.sh` 真占用腿）

**分母 ＝ 2 条腿**：

| 腿 | 形态 | 期望（**先写**） | 不成立 |
|---|---|---|---|
| **A**（反极 · 真占用） | **我起** `Xvfb :236 -screen 0 1280x1024x24`（PID 落盘，`xdpyinfo` 自证几何）⇒ `W67_DISPLAY=:236 WPF_X11_DIR=/tmp/.X11-unix bash session_inner.sh T20-OCC A:1` | stderr 含 **`DISPLAY_OCCUPIED=:236 sock=/tmp/.X11-unix/X236 ⇒ 拒跑`**（**原文照抄进报告**）∧ **rc=3** ∧ **未起应用**（无 `dotnet HandyControlDemo` 子进程 ∧ 无 app 日志） | rc≠3／无该行／**仍去起应用**（静默复用别人的号）⇒ 判红并点名 |
| **B**（正极 · 空号） | `:235` **无** socket ⇒ `W67_DISPLAY=:235 WPF_X11_DIR=/tmp/.X11-unix W67_WORK=~/t20-runner/w67-empty bash session_inner.sh T20-FREE A:1` | stderr 含 **`DISPLAY_LEASE=free display=:235 sock=/tmp/.X11-unix/X235`** ∧ **不含** `DISPLAY_OCCUPIED`；随后按装置行为退出（缺 `$DLLS` 工件 ⇒ 应在**起应用之前**退出；退出点逐字记） | 出现 `OCCUPIED`／无声退出／rc=3 ⇒ 判红并点名 |

**装置自证**：腿 A 的 `xdpyinfo` 几何必须 `1280x1024`；`[ -S /tmp/.X11-unix/X236 ]` 必须为真（否则腿 A 无效 ⇒ 作废点名）。腿 B 的 `[ -S /tmp/.X11-unix/X235 ]` 必须为假。
**收尾**：`kill <xvfb236.pid>`（先 TERM 后 KILL）⇒ 复扫 `/proc/*/cmdline` 里 `Xvfb :23` **零命中**。

---

## §4 三态（什么算成立／不成立／`NOINFO`）

- **成立**：该腿的期望（上表）逐条满足，且**两个方向**都被真跑（`B-3②`：正极 vs 缺根／根敏感性；`B-9`：占用 vs 空号）。
- **不成立**：期望的任一条被违背 ⇒ **判红点名**（`B-3②` 腿 4 静默跑通、腿 1–3 机器行不符、`B-9` 腿 A 不拒跑或拒而不发声）。
- **`NOINFO`**：**判不出**（缺可判读数／与判据无关的失败／槽非 `ACQUIRED`）⇒ 逐条**具名**原因；**既不算绿也不算红**，且**不许**把"没跑成"写成"通过"。
- **反极性自证（先于读数）**：每条腿都**能**变红 —— 腿 4（缺根）与腿 A（占用）**本身就是反极腿**；若它们不按期望走，本件**必须**判红而不是记 `NOINFO`。

---

## §5 件位断言（**跑前／跑后各一次**；托管件哈希是路径承载体，只在本树内自比）

`pkg-src-retiredpath-check.sh`／`session_inner.sh`／`CoverageProbe/Program.cs`／`CoverageProbe/bin/Release/PresentationCore.Tests.dll`／三支语料／`tline-gate.sh` —— 逐件打印 sha16，**跑前 == 跑后**；任一变化 ⇒ `NOINFO reason=artifact-moved-under-test`。
另核：`git status --porcelain` 里**不得**出现本席写域之外的改动（本席只新增两件报告 ＋ `~/t20-runner/**`）。

---

## §6 我先列的"可能推翻 `t14` 哪句话"（跑完再判）

1. `t14` §1 判据③ 写「`CoverageProbe` 死根面 ＝ `NOINFO`」，并暗示"需三支臂真跑" ⇒ 若真跑后证明**三支臂的结构路径根本不消费 `Root`** ⇒ 那句的**判法**（"臂日志签名"）应被换成"**根敏感性**"（本件即以此为判；此为**方法学更正**，不是产品缺陷）。
2. `t14` §5 的 `B-9` 两极化是在**沙箱 `X11` 目录**里做的（`WPF_X11_DIR` 注入）⇒ 真 `Xvfb` 占用腿若与沙箱腿**逐格同**（同一行原文、同一 rc）⇒ 说明沙箱注入**等价**于真占用（反之则点名差异）。
3. `t14` §7 的 `HEAVYSLOT=TIMEOUT waited=5s slot_rc=9` 是"槽被占"的读数 ⇒ 本件在**槽空**时复跑，若仍拿不到读数（例如产物缺失／语料缺失），则把"被占"与"不可得"**分开点名**。

---

## §7 复算命令（写完即冻结）

```bash
N=/home/links-dev/netTest/GitProj/WPFOnLinux; L=$HOME/t20-runner
# ① 件位（跑前/跑后各一次）
sha256sum $N/build/MilBridge/tools/pkg-src-retiredpath-check.sh $N/build/MilBridge/tests/PtsPagesProbe/session_inner.sh \
          $N/build/MilBridge/tests/CoverageProbe/Program.cs \
          $N/build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
          $N/tests/parity/windows/tab-{zero,anchor,rtl}/out/*-oracle.json $N/build/MilBridge/tools/tline-gate.sh | cut -c1-16
# ② 三支臂（正极）：root = 现树
cd $N/build/MilBridge/tests/CoverageProbe/bin/Release
WPF_PROBE_COVERAGE_ROOT=$N dotnet PresentationCore.Tests.dll --tab-lines-oracle $N/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json
# ③ 缺根反极
env -u WPF_PROBE_COVERAGE_ROOT dotnet PresentationCore.Tests.dll --tab-lines-oracle <同上>
# ④ 根敏感性（不存在目录）
WPF_PROBE_COVERAGE_ROOT=$L/root-none dotnet PresentationCore.Tests.dll --tab-lines-oracle <同上>
# ⑤ B-9 占用腿 / 空号腿
Xvfb :236 -screen 0 1280x1024x24 & echo $! > $L/xvfb236.pid; sleep 2
W67_DISPLAY=:236 WPF_X11_DIR=/tmp/.X11-unix bash $N/build/MilBridge/tests/PtsPagesProbe/session_inner.sh T20-OCC A:1; echo "rc=$?"
W67_DISPLAY=:235 WPF_X11_DIR=/tmp/.X11-unix W67_WORK=$L/w67-empty bash $N/build/MilBridge/tests/PtsPagesProbe/session_inner.sh T20-FREE A:1; echo "rc=$?"
kill "$(cat $L/xvfb236.pid)"
# ⑥ 台账
cat $L/legs.tsv ; bash $L/bin/finalize.sh
```

**边界（本判据件自身）**：① 本件**只**把这 7 条腿的观测变成读数，**不**判 `TASK-*` 状态、**不**判"W2 收口"；② 三支臂的机器行**只**与在册臂日志逐格对照，**不**重新裁定登记表（`known-red.json` 不在写域）；③ `B-9` 腿 B 的"缺工件即退出"是**装置设计**（缺 shim 不静默），不是缺陷；④ 用户现场（`xrdp`＋`xfwm4`）**不外推**。
