# P1-W77 · ① `FRAME_EMPTY_SET` **并入 β**（收紧） ② 修装置 `D-1`／`D-2`

两节都在本件写域内。**第一节是承重件**：把**第三条假绿通道**的具体路径堵掉（不是"设想"，`t152` 主表里**已经发生过**）。
**相位位未翻**（`PTS-DIRECTION … phase=degraded` 改前改后逐字相同，见 §6）；**未** `git add/commit/push`；
`cell=#1` **有意未登记**（覆盖面登记归队长收口）。

---

## 1. 逐件改前／改后（现取：sha16 ＋ 行数 ＋ `numstat`）

| 件 | 改前 sha16（行数） | 改后 sha16（行数） | `numstat`（加/删） |
|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `a37f8330a593c3ae`（1304） | **`962fec114b2d0692`**（1346） | `45 / 3` |
| `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | `0ab03550a11a3e0a`（299） | **`e6eb370def6b4b8e`**（350） | `52 / 1` |
| `build/MilBridge/tests/PtsPagesProbe/session_inner.sh` | `1685358c4e017984`（245） | **`390927970cd8839f`**（266） | `21 / 0` |

- **备份面 ≡ 换代面**（写前 `stat -c %h` ＝ 1，备份取在**任何写之前**）：
  · 守卫：`cp -p` → `~/w281-scribe/t157/bak/pts-pages-guard.sh.pre-t157`（`a37f8330a593c3ae`，与改前现取同）。
  · 两件装置件：本件开头现取 `git diff --numstat` **两件皆空**（⇒ 工作树与 `HEAD` 一致）⇒ 备份如实取自
    `git show HEAD:<路径>`：`~/w281-scribe/t157/bak/{run-pts-pages-legs.sh,session_inner.sh}.pre-t157`
    （逐件 sha16 ＝ `0ab03550a11a3e0a`／`1685358c4e017984`，与改前现取**逐字相同**）。
- `3` 处删除全在守卫：① 旧集合行被新集合行替换（旧值**原文一字未删**，改成注释留档，见 §2）；②③ 两条 selftest 期望串由**硬写两成员字面**改成**从唯一登记处现取**（见 §4，判据未松）。
- 语法：三件 `bash -n` 全 OK；全仓 `shell-quote-trap-check.sh --root . --anchors off` ⇒ **`SHELL_QUOTE_HIT` 命中 0**（我新增的可执行行**无**双引号内反引号）。

---

## 2. `FRAME_EMPTY_SET` 三成员：现取原文 ＋ 逐枚出处 ＋ 读时戳

**现取（唯一登记处，`pts-pages-guard.sh`）**：

```
FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03"
```

（旧值原文留档在紧邻上一行注释里：`FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b"`。）

| 成员 | 出处（内容锚） | 本席读时 | 复核命令 |
|---|---|---|---|
| `1a76488aa4a790b3` | ⚠️ **仓外载体**：`~/t119-runner/bak/run-N3-runner-shots/g1/{k23,k24,last}.png`（现取 `k23.png`＝该值、`189742` B）；口径按 `t144` 已登记（**仓内不可复现**） | `2026-09-29T17:4x+0800`（本席） | `sha256sum ~/t119-runner/bak/run-N3-runner-shots/g1/k23.png \| cut -c1-16` |
| `ef3fd6765f18f51b` | `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24}.png`（现取各＝该值、各 `189716` B；`t136` 读时 `2026-09-29T0x+0800`） | `2026-09-29T17:4x+0800`（本席复核） | `sha256sum build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/k23.png \| cut -c1-16` |
| `b273ebecc332fc03` | **`build/MilBridge/P1-frame-determinism2-report.md`**（`t152` 主表：7/24 样本的 `FRAME` 行同值，含 `:102/:104/:106` 三行；**本席现取该件 247 行、`sha16=7bc694c16ecd0167`、末行自证重算 `0f0819a68e617710`＝该行自declared 值 ⇒ 件完整**） | `2026-09-29T17:4x+0800`（本席） | `sha256sum build/MilBridge/P1-frame-determinism2-report.md \| cut -c1-16` |

**为什么必须并入（第三条假绿通道的具体路径）**：β 是**空态画面**（`colors 391`／`ae_boot 14775`），
却**不在**旧两成员集里 ⇒ 落在 β 的趟 `in_empty_set=no` ⇒ `N1` 要件①「帧身份 ∉ 空态参照集」被读成"成立"
＝裁定三十九第 (c) 条点名的通道。**现成读数**：`t152` 主表那三行 β 样本（`:102/:104/:106`）的**判词列原文＝`全绿`**
⇒ 假绿**发生过**。

**不放松（逐字保留）**：`t136` 的「**必要非充分、永不单独发绿**」与 `t145` 的「**登记须附独立支撑**」照旧；
作废纪律照旧（只有 `N4` 正身份／内容锚正证据才准移出）；**不设 env 旋钮**（判据只许收紧）。

---

## 3. 判据 ① 四条：成对读数（仓外夹具，两极化）

夹具（**仓外** `~/w281-scribe/t157/`）：`fx-a`＝`1a76…`、`fx-b`＝`ef3f…`、`fx-c`＝**β**、`fx-d`＝集外 `deadbeefdeadbeef`；
两份变体守卫：`guard-real.sh`（只把**方向行**改成 `realized`，行号定址）、`guard-real-nobeta.sh`（同 realized ＋ **移出 β**）。
（`realized` 相位只能靠变体：真树方向行是 `degraded`，本件**不移**它。）

| 判据 | 命令 | 读数（原文截取） |
|---|---|---|
| **(a) 三成员各作帧身份 ⇒ 必红并点名** | `guard-real.sh --legs fx-{a,b,c}` | `PTS_N1=FAIL k=24 … in_empty_set=yes … set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criterion=frame-identity(sha16=…∈{三个})`；两腿齐红；`PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(…)),leg23-…`；**rc=1**。三枚**逐枚**都点到名（含 β：`criterion=frame-identity(sha16=b273ebecc332fc03∈{…})`） |
| **(b) 集外值 ⇒ 不单独发绿（`t136` 旧口径）** | `guard-real.sh --legs fx-d` | `PTS_N1=NECESSARY … in_empty_set=no … criteria-satisfied=frame-identity,frame-displacement`（**只算必要条件**）；`PTS_N1_GATE=FAIL phase=realized positive=none … reason=only-necessary-condition-no-positive-evidence`；`PTS_GUARD=FAIL` |
| **(c) 因果对（realized 期）** | `guard-real-nobeta.sh --legs fx-c`（同一个 β 夹具） | `in_empty_set=no` ＋ `PTS_N1=NECESSARY … criteria-satisfied=frame-identity`（**要件①又被读成"成立"**）＋ `PTS_N1_GATE=FAIL reason=only-necessary-condition-no-positive-evidence` ⇒ **假绿归因面复现**；与 (a) 的 `PTS_N1=FAIL` 成对 ⇒ 并入 β **就是**堵住那一步 |
| **(c′) 因果对（degraded 期，真树相位）** | 真树守卫 vs `guard-deg-nobeta.sh`，同一 `fx-c` | β 在集：`PTS_N1=INFO … in_empty_set=yes`；β 移出：`PTS_N1=INFO … in_empty_set=no` ⇒ **归因面**由 `no→yes`（两行都在 `phase=degraded`，本相位**不判红**——这与 `t152` 主表"degraded 下 β 判全绿"完全一致） |
| **(d) `--selftest` 改前／改后** | 见 §4 | 改前 `PASS 80/0`（**本席现取，非转述**）／改后 `PASS 82/0` |

**口径（写死）**：`(c)` 证明的是**要件①的归因面**（"帧身份 ∉ 参照集"这一句是否被误判成立）——
这正是裁定三十九 (c) 点名的通道；`realized` 期另有 `t136` 的 `N1_GATE` 兜底，**degraded 期没有**（`PTS_N1=INFO … 止损期不据此判红`），
所以"目前判词颜色不变"**不等于**"没堵住"：堵住的是**那句归因**与**相位翻转后的必红**。

---

## 4. `--selftest` 成对（含基线自己现取）

| 读数 | 值 |
|---|---|
| 改前（备份件 `…pre-t157`） | **`PTS_GUARD_SELFTEST=PASS pass=80 fail=0`**（＝`t147` 交出的值，**本席现取确认**） |
| 改后（真树件） | **`PTS_GUARD_SELFTEST=PASS pass=82 fail=0`** |
| **因果变体**（真树件**移出 β** 后跑同一份 selftest） | `PTS_GUARD_SELFTEST=FAIL pass=81 fail=1`，唯一红格：`t157·β 点名(三成员集) => no ✗ 期望 sha16=b273…∈{…}` ⇒ **新增的 β 腿有牙**，且"并入 β"正是它转绿的原因 |

**本件对 selftest 的两处改动（都是收紧/防漂移，不是"改期望值凑绿"）**：
1. 两条既有期望串（`N1·点名(帧+要件+参照集)`、`t136·新成员点名(累积集)`）原先**硬写** `{1a76488aa4a790b3,ef3fd6765f18f51b}`；
   现改为 `"sha16=…∈{${FRAME_EMPTY_SET}}"` ⇒ **从唯一登记处现取**。断言的**判据一字未松**（仍是逐字子串断言），
   只是不再会随集合登记漂移（否则每次并入都要再改期望）。**若不改**：改后 `--selftest` 会 `PASS 78/2`（**我实测过**）。
2. **新增** β 极性腿（`c44`，`colors 391`／`ae_boot 14775` 的 β 形状）＋ 点名断言
   ⇒ 三成员**逐枚**都在 selftest 里成腿（`c36`＝`1a76…`、`c40`＝`ef3f…`、`c44`＝β）。**计数由 80 涨到 82**（新增两条断言，非改动既有格）。

---

## 5. 判据 ② 四条极化（`D-1`／`D-2`）——读数绑到**当趟字节**

夹具：`~/w281-scribe/t157/fix2.sh`（runner 端，`PTS_INNER` 注桩、显示固定 `:239`）＋ `fix3.sh`（会话端）。
**跑前/跑后绑定（同趟现取）**：`runner=e6eb370def6b4b8e session=390927970cd8839f guard=962fec114b2d0692`（**跑前＝跑后**）。

| 极 | 夹具 | 读数（原文截取） |
|---|---|---|
| **① 正极（号空闲，连续多趟）** | `p1a`／`p1b` | `DISPLAY_HANDOFF display=:239 env=W67_DISPLAY rule=caller-fixed(PTS_GUARD_DISPLAY)`；`LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none display=:239 rc=0 session_rc=0 conv_rc=0`；`LEGS_RUNNER=PASS`；**双腿账落盘（2）** |
| **② 反极（真 X server 占号）** | 起真 `Xvfb :239`（pid 现取 `4039346`）后 `p2` | `DISPLAY_WAIT display=:239 state=waiting/timeout occupant_pid=4039346`；`device=NOINFO reason=display-not-free display=:239 waited_ms=1000 occupant_pid=4039346`；`LEGSCOUNT … obtained=0 refused=2 reasons=display-not-free=2`；`LEGS_RUNNER=FAIL reason=display-not-free …`；**rc=2**（点名 ＋ 计数可见 ＋ 显式失败） |
| **③ 反极（`D-2` 因果对：命令行含号但**不是** X server）** | `bash -c 'while :; do sleep 1; done' :239`（现取 `comm=bash`）后 `p3` | **不判占用**：直接 `DISPLAY_PICK display=:239 … waited_ms=0` ＋ `LEGS_RUNNER=PASS obtained=2 refused=0` ⇒ 假占用**已堵**（旧形态按字面扫 ⇒ `display-not-free`） |
| **④ 因果对（解除占用）** | 按 PID 收掉真 `Xvfb` 后 `p4` | 同一条命令回正极：`LEGS_RUNNER=PASS obtained=2 refused=0` |
| **⑤ 具名支：件在但无 X server 认领** | `p5`（python 造一个**无人持有**的 `X239` 件） | `DISPLAY_STALE_SOCKET display=:239 sock=/tmp/.X11-unix/X239 holder=none action=reclaim（件在但**无 X server 认领** ⇒ 不算占用）` ＋ `LEGS_RUNNER=PASS`（不再无谓等 30s） |
| **⑥ 会话端（`session_inner.sh`）`D-1` 两条新路径** | `fix3.sh` | `S1`（`W67_DISPLAY=:237` 而 lease 写 `:239`）⇒ `DISPLAY_MISMATCH=:237 lease_display=:239` ＋ `LEASE_REJECT reason=allocated-display-not-passed-through`，**rc=3**；`S2`（`W67_DISPLAY` 未给）⇒ **`DISPLAY_ADOPT display=:239 from=lease`**，随后因夹具里 `XVFB_PID` 是死号 ⇒ `DISPLAY_OCCUPIED`／`LEASE_REJECT reason=lease-xvfb-dead`，rc=3 |

**装置面纪律现取**：跑前 `/tmp/.X11-unix` ＝ `X0 X1`，跑后 ＝ `X0 X1`；夹具进程**逐条按 PID** 收
（`xvfb`／`fake`／`py` 三条自证；`Xvfb`/`xfwm4` 残留扫 = 无）；显示只用 `:239`（在 `:23x` 内）；未占别人的号。
**既有列形状一字未动**：`CLICK`／`FAILLINE`／`FRAME`／`PHASE`／`FILE=`／`APP_RC=` 等**无一行被改**；
新增行只有 `DISPLAY_HANDOFF`（runner）与 `DISPLAY_STALE_SOCKET`（runner）与 `DISPLAY_MISMATCH`／`DISPLAY_ADOPT`（session）。
`t153` 的 `LEGSCOUNT` 计数语义**未退回**：反极趟仍是 `refused=2`。

### `D-2` 的**具名作废**（不许静默：两路里有一路我实测不成立，已弃用）
试过"socket 件 inode ↔ `/proc/<pid>/fd` 的 `socket:[inode]` 反查持有者" —— 本机**现取不成立**：
`stat -c %i /tmp/.X11-unix/X239` ＝ **`4212990`**，而活 `Xvfb` 的 fd 反链是 `socket:[28854481]`
（**sockfs inode ≠ 该路径件的 inode**）⇒ 该路**恒查不到**持有者（实测：真 Xvfb 在跑却判"无人持有"，那一版被我自己跑出来并当场否掉）。
⇒ 占用判据改走契约允许的**另一路**：**X server 进程（`comm`／`exe` 白名单）＋ 其 display 归属（cmdline token）**，
`occupied_by()` 现在**只会**返回真 X server 的 pid（p2 实测 `occupant_pid=4039346` ＝ 真 `Xvfb`）。

---

## 6. ⑥ `degraded` 真树判词：修前／修后（裁定三十四 (b) 的射程）

```
改前：PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),…
改后：PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),…
判词行 cmp 完全相同: YES
```

- 命令：`--legs build/MilBridge/tests/PtsPagesProbe/evidence`（改前用备份件、改后用真树件；两趟都给了
  `PTS_G10_ROSTER_SRC`／`PTS_G10_DECL_TREE` 两个**源指**，因为备份件在仓外、`SELF_DIR/../../..` 推出的不是仓根）。
- **整份输出差异只有 4 行**（前 9 行 / 后 9 行）：只有两腿的 `PTS_N1=INFO … set={…}` 从两成员变三成员；
  判词行**逐字不变**（真树证据面那两帧是 `ef3fd6765f18f51b`＝α ⇒ 旧集里本来就有 ⇒ `in_empty_set=yes` 不变）。
- **相位位不得翻**：`sed -n '51p'` 现取，改前 `phase=degraded`、改后 `phase=degraded` ⇒ **未翻**。
- ⇒ 射程句：本件**不改今天真树的判词颜色**，改的是**归因面**与**相位翻转后的必红**（这正是收紧的正确形态）。

---

## 7. 具名 `NOINFO`（不算绿、也不算红；逐条在册）

1. `PTS_N1_GATE=NOINFO phase=realized reason=necessary-not-satisfied(nec23=no,nec24=no) sha23=… sha24=…`
   —— (a) 三成员夹具上：红已由 `PTS_N1=FAIL` 承担，**正证据闸**因必要件不成立而**不可算**（不重复红、也不发绿）。
2. `PTS_GUARD=FAIL … cannot=enfe-log-absent` —— (b) 集外夹具没有 ENFE 日志 ⇒ 该面**判不了**（不折成绿）。
3. `device=NOINFO reason=display-not-free display=:239 waited_ms=1000 occupant_pid=4039346` —— 反极②：**拒跑**是 FAIL＋计数，**不是** NOINFO 混过去（此行的 `NOINFO` 是"本趟设备自证不足"的既有口径）。
4. **桩自身** `T157_STUB_DISPLAY_SEEN=<unset>`（具名、不掩盖）：桩是**会话替身**，真实 `session_inner.sh` 只把
   `DISPLAY` 传给**应用子进程**（`env DISPLAY="$D" dotnet …`），所以桩看不到它 ⇒ D-1 的下传证据看 **`W67_DISPLAY=:239`**（桩能看到）
   与 S1/S2 两条会话端读数；**不拿 `<unset>` 当反证，也不当绿**。
5. `1a76488aa4a790b3` **仓内不可复现**（该值只在**仓外**载体 `~/t119-runner/bak/run-N3-runner-shots/g1/`）；
   引用它必须连带写"仓外载体"（复核命令见 §2 表）。
6. `D-2` 的 **inode 反查路**：本机**弃用**（理由与实测数字见 §5 末，具名、不静默）。

---

## 8. 写域与未碰面

- **改了**：上面三件 ＋ 本载体。
- **未碰**：`src/WpfGfx.Linux.Native/**`（`runner` 的第三跳在飞）、`docs/**`、任何 `.cs`、两枚哨兵、`HANDOFF-NEXT.md` 的 `cell=#1`。
- **`cell=#1` 有意未登记**（本波覆盖面登记由队长收口）。
- 夹具全在**仓外** `~/w281-scribe/t157/`（`gen.sh`／`fix2.sh`／`fix3.sh` 与 `fx-a..d`／`fx2`／`fx3`／`out/`／`bak/`）；**未进仓**。
- 未跑整趟门禁、**未构建**、腿只在夹具内起（桩会话，`Xvfb` 只用 `:239` 且已按 PID 收净）。

self16=55fb323a4c69ea77
