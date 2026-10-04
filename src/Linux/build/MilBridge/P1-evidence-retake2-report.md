# P1-W21 · 在册证据再换代报告（`t94`）—— 修 `t91` 点名的 `G-1`（同趟性 `pf` 轴断）＋ `t92` 造成的 `shim` 轴断

> 车道：`runner`（重活/产品增量执行者）｜载体：`build/MilBridge/P1-evidence-retake2-report.md`（新建）
> 本件**全部读数为本趟现取**，命令与输出原样入件；**不引任何既有报告当证据**。
> 读时 `HEAD=fe6f551`（`fix(#81): t92 native 纵深防御落地 …`）。
> 做法与 `t86` 同法：**重跑**（不是搬运），落点＝判据的**默认**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence`。

---

## 0. 一句话结论

**两轴都已恢复同趟**（`t91` 点名的 `pf` 轴 ＋ `t92` 新造成的 `shim` 轴**一起**修好）：
重取后 **`POSTSHIM: shim=657f448c2077ba1f pf=6893d1d3fb1ee110（== authority ⇒ 读数可归因）`** —— 与现权威件**逐位相同**。
· **下一跳入口（运行期读数）**：**`LoAcquirePenaltyModule`**（`entry=` ×3；台账 `PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1`）⇒ **`t92` 改 native 名字读取口后，这一跳没有变**。
· **判据**：`pts-pages-guard.sh --legs <默认目录>` 现取 **`rc=0`**／**`PTS_GUARD=PASS legs=2/2 fails=-`**。
· **第 `29` 条**：改动面 **29** ≡ 备份面 **29**（全目录逐件 `cp -p`），回读 `BACKUP_IDENTICAL`，逐件 `CHANGED=9／SAME=20／NEW=0／MISSING=0`。
· **纪律 28**：`cell=#1` **已被别人（`t95` 侧）在 `ts=00:42:38` 用我重取后的值写对** ⇒ **本件不重复追写**（见 §5）。

---

## 1. ① 前置核对：两轴各自与现盘成对（把"断"用读数钉死）

| 轴 | 在册证据载的（重取前，本趟现取） | 现权威（本趟现取） | 判定 |
|---|---|---|---|
| **`shim`** | `five_pre/five_post_g1.txt` ⇒ `libwpfwin32.so=3bd193e54785b5db`；`leg_23/24.env` ⇒ `DEV … shim=3bd193e54785b5db` | `sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ⇒ **`657f448c2077ba1f`** | **不等 ⇒ `shim` 轴断**（`t92` 重建 `.so` 所致） |
| **`pf`** | 同上两件 ⇒ `PresentationFramework.dll=b3f0d129f0234b58`；`DEV … pf=b3f0d129f0234b58` | `sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ⇒ **`6893d1d3fb1ee110`** | **不等 ⇒ `pf` 轴断**（`t91` 的 `G-1`，随后又被 `t95` 改动推得更远） |
| 部署面对照 | —— | `sha256sum ~/w67-work/app/{libwpfwin32.so,PresentationFramework.dll}` ⇒ **`657f448c2077ba1f`／`6893d1d3fb1ee110`**（与仓库权威**同值**） | 部署面与仓库面一致 ⇒ 重取的腿读数可归因 |
| 另三位 | `wpfgfx_cor3.so=4e25e4b27d4d5ae1`／`PresentationCore.dll=5b6cfda3e12b84fc`／`WindowsBase.dll=9e860cbeecb352e1` | 现取同值 | **同值**（本波未重建这三位） |

⇒ **重取前两轴都断**（`t91` 只点名了 `pf` 轴，`shim` 轴在 `t92` 之后同样断了）——**本件一次修两轴**。

**重取前在册件指纹（现取，供 after 对拍）**：`app_g1.log e348b4ef70ab521e`｜`session.txt 1e9211b90d7aa52d`｜`leg_23.env 5b245a02ae5df8a8`｜`leg_24.env 5cf62452cd3d4fb7`｜`five_pre_g1.txt`＝`five_post_g1.txt b4cd0fc5799063b7`｜`device.txt 6d2cf7572e7323b7`；目录 **29** 件。

---

## 2. ② 重取（在册、重跑、重活槽后台）

```
nohup bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- \
  env PTS_GUARD_REPO=/home/links-dev/netTest/GitProj/WPFOnLinux PTS_GUARD_DISPLAY=:237 \
      PTS_GUARD_APPDIR=/home/links-dev/w67-work/app W67_WORK=/home/links-dev/w67-work \
  bash …/build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh …/build/MilBridge/tests/PtsPagesProbe/evidence \
  > ~/t94-runner/logs/legs.log 2>&1 &
```
· **PID=3005541**（`~/t94-runner/bin/legs.pid`），日志 `~/t94-runner/logs/legs.log`（车道目录，**未落 `/tmp`**）。
· 槽读数（逐字）：`HEAVYSLOT=ACQUIRED waited=0s`｜`HEAVYSLOT=MEMOK avail=…MB min_avail=2500MB`｜`HEAVYSLOT=RELEASED rc=0 held=30s max_hold=1800s`。
· 前置（现取）：`APPSYNC: SYNC-APPLOCAL=PASS target=… items=5 ok=5 synced=0 created=0 **drift=0** noauth=0 same=0 rc=0`（**先 `--check` 得 `drift=0`，故未做 `sync`**）。
· **硬闸成对（可归因的唯一依据）**：跑前 `AUTHORITY: shim=657f448c2077ba1f pf=6893d1d3fb1ee110 ｜ APPDIR: shim=657f448c2077ba1f pf=6893d1d3fb1ee110`（四值**逐字相等**）→ 跑后 **`POSTSHIM: shim=657f448c2077ba1f pf=6893d1d3fb1ee110（== authority ⇒ 读数可归因）`**。
· 装置自证：`X_UP=yes display=:237`（私有 `:23x` ✓）｜同趟：`GROUP 1 arm=A clicks=[24,23] 00:42:07` → `ALL_GROUPS_DONE 00:42:31`；`five_pre_g1.txt` 与 `five_post_g1.txt` **同 sha16**。
· 两条腿：`CLICK k=24 alive=yes expect=FlowDocumentDemo AE=221857 pts_unavail=1 pts_gap=1 guard=1 fatal=0 unh=0`／`CLICK k=23 alive=yes expect=RichTextBoxDemo AE=141283 pts_unavail=2 pts_gap=1 guard=1 fatal=0 unh=0`；`APP_RC=143`（`rc_reading: SIGTERM(仪器收的)`）。
· 收尾（只按 PID）：装置自收 `xvfb.pid`／`xfwm.pid`；**现扫 `/proc/*/exe` ⇒ 0 个** `Xvfb`／`xfwm4`／`HandyControlDemo` 残留；`display-lease` 随装置自撤。扫描排除自身祖先链；全程**无 `pkill`／`killall`／`pgrep -f`**。

---

## 3. ③ 第 `29` 条「备份面 ≡ 换代面」对账（现取）

· **做法**：跑取**之前**把整个证据目录**逐件** `cp -p` 到仓外 `~/t94-runner/bak/evidence-before/`（`find … -print0 | cpio -pdm0`，含 `arm_A/` 下装置同趟副本）。
· **改动面件数 = 备份面件数**：`find <证据目录> -type f | wc -l` ＝ **29**；`find ~/t94-runner/bak/evidence-before -type f | wc -l` ＝ **29** ⇒ **相等 ✔**；备份回读（改动前）`diff` 空 ⇒ **`BACKUP_IDENTICAL`**。
· **逐件对账（改动后现取）**：**CHANGED=9／SAME=20／NEW=0／MISSING=0**

| 件 | before sha16 | after sha16 | 判定 |
|---|---|---|---|
| `app_g1.log` | `e348b4ef70ab521e` | **`c48ce99cb64b2b95`** | CHANGED（换代主件） |
| `session.txt` | `1e9211b90d7aa52d` | `65ab1433f71c9202` | CHANGED |
| `leg_23.env` | `5b245a02ae5df8a8` | `97deae90a81b2160` | CHANGED |
| `leg_24.env` | `5cf62452cd3d4fb7` | `4016890b7aabf6e9` | CHANGED |
| `five_pre_g1.txt` | `b4cd0fc5799063b7` | `c9da761a064acbaf` | CHANGED |
| `five_post_g1.txt` | `b4cd0fc5799063b7` | `c9da761a064acbaf` | CHANGED |
| `device/xfwm.log` | `d461229267763d24` | `69810eb8eb7737b9` | CHANGED |
| `shots/g1/k23.png`／`k24.png`／`last.png` | `b88846d9a2a35e31`／`852da0312d50419a`／`b88846d9a2a35e31` | **逐件 SAME** | SAME（本趟像素与前趟逐字节相同） |
| `shots/g1/boot.png` | `b21eb530afd3c66c` | `b21eb530afd3c66c` | SAME |
| `device.txt`（主） | `6d2cf7572e7323b7` | `6d2cf7572e7323b7` | SAME（都是 `X_UP=yes display=:237`） |
| `device/xvfb.log`（主） | `e3b0c44298fc1c14` | `e3b0c44298fc1c14` | SAME（0 B） |
| `arm_A/**`（12 件） | —— | —— | SAME（装置入口本趟**未重写**那批"上一趟"镜像） |

⇒ **未静默覆盖**：改动面每一件在改动前都已 `cp -p` 落仓外，旧值以现取形式留档（上表 before 列；完整 29 行见 `~/t94-runner/logs/pair.txt`）。

---

## 4. ④ 成对读数（before ＝ 重取前在册件；after ＝ 本趟重取）

### 4.1 `entry=` 面（＝"下一跳入口"的运行期读数）

| | before | after |
|---|---|---|
| `grep -o 'entry=[A-Za-z0-9_:]*' app_g1.log \| sort \| uniq -c` | `3 entry=LoAcquirePenaltyModule` | **`3 entry=LoAcquirePenaltyModule`**（**不变**） |
| `entry=unknown` 计数 | `0` | `0`（**不增** ✔） |
| 具名行原文 | `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoAcquirePenaltyModule err=-10000 action=page-placeholder（已画出页级占位；进程继续）` | **逐字相同** |
| native 台账行 | `PTS_GAP entry=LoAcquirePenaltyModule seq=3 err=-10000 calls=1`（1 行） | **逐字相同**（1 行） |

⇒ **下一跳 ＝ `LoAcquirePenaltyModule`（运行期读数，非静态推断）**：`t92` 只改了**名字读取口**（`F-3`）与**报告返回语义**（`O-1`），**没有**改变链上被撞的入口 —— 名字仍取自**缺口名册口径**（`g_pts_calls`），而那条入口**依旧恒 `-10000`**。

### 4.2 `leg_*.env`（判据真正读的那几列）

| 列 | before | after | 判定 |
|---|---|---|---|
| `k=23/24 alive` | `yes`／`yes` | `yes`／`yes` | **不变**（零回归） |
| `k=23/24 app_rc` | `143`／`143` | `143`／`143` | **不变**（不在 `{134,139}`） |
| `k=23 magenta` | `49943` | `49943` | **逐字相同** |
| `k=24 magenta` | `54533` | `54533` | **逐字相同** |
| `k=23/24 ink` | `428456`／`423798` | `428456`／`423798` | **逐字相同** |
| `ns`（两腿） | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | **不变** |
| `NAMED … native_gap` | `1`（两腿） | `1`（两腿） | **不变**（台账非零保持） |
| `NAMED … native_err` | `-10000` | `-10000` | 不变 |
| `DEV … five_stable` | `yes` | `yes` | 不变 |
| **`DEV … shim`／`pf`** | **`3bd193e54785b5db`／`b3f0d129f0234b58`** | **`657f448c2077ba1f`／`6893d1d3fb1ee110`** | **换代 ＝ 现权威 ⇒ 两轴恢复同趟** |

症状统计（`session.txt` 同趟行）：`pts_unavail=1/2`、`pts_gap=1`（两腿）、`guard=1`、`fatal=0`、`unh=0` ⇒ **未劣化**。

### 4.3 `five_pre/five_post` 哈希与代次

| | before | after |
|---|---|---|
| sha16（两件） | `b4cd0fc5799063b7` | **`c9da761a064acbaf`**（**pre == post** ⇒ 跑腿期间五件未变 ✔） |
| 内容 | `libwpfwin32.so=3bd193e54785b5db`／`…PresentationFramework.dll=b3f0d129f0234b58` | **`libwpfwin32.so=657f448c2077ba1f`／`…PresentationFramework.dll=6893d1d3fb1ee110`**（其余三件同值） |

### 4.4 `PTS-PAGES` 判据（**默认目录、带参数** —— 门禁真读的那条）

```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
before: rc=0
  PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared
  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
after : rc=0
  PTS_G10_NAME=PASS observed=LoAcquirePenaltyModule names=1 roster=12 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
```
⇒ **判词逐字未变、仍 `rc=0`／`PASS`**（本件只换代证据、未碰判据：`pts-pages-guard.sh` 现取 sha16 `b74d2be6f9093115`／572 行）。

---

## 5. ⑤ 纪律 28：`cell=#1` 现状（**已被别人写对 ⇒ 本件不重复追写**）

· 本趟现取（`bash ~/w153a/bin/infp.sh fp`）＝ **`48a3aa54b0f8d7ba1d3c40fb33f9229e713ecf33a58f9e0320d3ae56e6389830`**，且 `FP-MANIFEST-TEETH` 自报 `would_be_fp=`**`48a3aa54b0f8d7ba`**（两者一致）。
· `build/MilBridge/HANDOFF-NEXT.md` **最后一行**（现取）＝
  `⏪ **机器值契约更正 · cell=#1**：以现取为准；`ts=2026-09-29T00:42:38.793784318+0800` 时 现值 ＝ `48a3aa54b0f8d7ba…`（命令：`bash ~/w153a/bin/infp.sh fp`）…`
  ⇒ **那一格的值就是当前值**；上一格（倒数第二行）是 `ts=00:34:09` 的 `f4a21769…`。
· **时序对拍**：我这趟腿 `GROUP 1` 起 `00:42:07`、`ALL_GROUPS_DONE 00:42:31`；证据件 mtime `00:42:29`～`00:42:32`；`cell=#1` 那行写于 `00:42:38` ⇒ **它是在我重取之后写的**，取样点已经包含我的换代。
· **单变量归因（本件亲自做，证明"我这次换代确实推动了该格"）**：把 `evidence/app_g1.log` **只在量指纹那一瞬**换回旧件 ⇒ fp ＝ **`e433f3e66ed0a852…`**；换回新件（`cp -a` ＋ `utime` 复原 mtime）⇒ fp 回到 **`48a3aa54…`**，且复原后 `cmp` 与保留副本 **`RESTORE_IDENTICAL`**、现取 sha16 仍 `c48ce99cb64b2b95`。
· ⇒ **我不重复追写**（派单明示"别反复追写"）：格值已对，追写只会把同一值再写一遍并多添一行历史。**如实交出我的取值时刻**：`ts` ∈ `[00:42:31, 00:45:0x]`（重取完成 → 本件落盘之间）；**我在 `00:45` 前后复取的 fp 与格内值逐位相同**。
· `baseline/handoff` 判据：**`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`**（现取）。`git status --porcelain -- build/MilBridge/HANDOFF-NEXT.md` 现读为 **` M`**，但**那是别的车道在飞**（本件**未**改它：本件只写了 `evidence/**` 与自己的载体 ⇒ 见 §8 的写域清单）。

---

## 6. ⑥ 哨兵现状（如实报，**未写**）

`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **`IDENTICAL`**（sha16 `00c7c159a7ed3758`）。现取哨兵内容：

| 键 | 哨兵内 | 现盘（本趟现取） | 一致？ |
|---|---|---|---|
| `PF` | **`6893d1d3fb1ee110`** | `6893d1d3fb1ee110` | ✔ |
| `WIN32SHIM` | **`657f448c2077ba1f`** | `657f448c2077ba1f` | ✔ |
| `SHA`／`FP`／`PC`／`WB`／`HBTL`／`WIC`／`PROVIDER`／`DWF` | `4e25e4b27d4d5ae1`／`d697b1e10ff48881`／`5b6cfda3e12b84fc`／`9e860cbeecb352e1`／`921ba9c65e9fb3be`／`f7b3026c8c019be2`／`24e4e0a731dbed40`／`c83be96f18759edc` | **逐键同值** | ✔ 八位一致 |
| `WAVE`／`BASELINE` | `w80-freeze`／`#80`（`BASELINE_SHA16=b27ff6332f263495`） | 同 | **与 `HEAD` 的 `#81` 不一致** ⇒ **既在的世代标签陈旧**（不是本件造成；写哨兵＝队长的动作） |

牙 `sentinel-spec-check.sh` ⇒ **`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**（rc=0）⇒ **`t92` 时那条 `SSC=FAIL key=WIN32SHIM` 已随哨兵跟上而消失**。

---

## 7. 不变量与牙（现取）

**四条不变量**：`^run_step "` 计数 **62**＝`VERIFYALL-STEPS-DECL` 现声明 **`62 gen=#81`**；`[42]` 的 `--expect` ＝ **234** ＝ 覆盖面**活清单** `names_n=234 manifest_n=234` ＋ **`FP_MANIFEST_TEETH=PASS reason=ok files_n=234 files_n_uniq=234 blank_n=0 declared_expect=234`**（`would_be_fp=48a3aa54b0f8d7ba`）⇒ **本件未增删任何覆盖面内件**（只换内容）。

**已接线牙（现取，逐条）**：`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=203`｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5`｜**`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`**｜`REPORTID=PASS files=238 ids=2200 declared=224`｜`DEFREG=PASS declared=224 route_ids=224`｜**`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**｜**`STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62`** ⇒ **本趟七条全绿**（`STATIC-JAWS` 与 `SENTINEL-SPEC` 在 `t92` 时曾红：前者是另一族、后者是哨兵位陈旧，**两条现取均已转绿**）。

---

## 8. 未做项与原因（如实）

1. **未写哨兵**（派单明示"写哨兵是队长的动作"）⇒ 只给 §6 的逐键比对与 `cmp`。
2. **未重复追写 `cell=#1`**（派单明示"别反复追写"）：格值已是当前值（§5 给时序与单变量归因）。
3. **未跑整趟门禁**（纪律禁）⇒ 第 `[38]` 步的步级读数未取；本件取的是**同一条命令**在现树上的读数。
4. **未动 `t95` 在飞的 `build/PresentationFramework.Linux/**`**：本趟 `pf` 从 `b3f0d129f0234b58` 变成 **`6893d1d3fb1ee110`**（相对 `t91` 取证时的 `83ba5884bb603296` 又前进了一版）⇒ **若 `t95` 之后再重建 Release 件，`pf` 轴会再次断开**，那是**下一次换代**的事（本件只保证"**我落盘那一刻**两轴与现权威同趟"）。
5. **未动** `src/**`／`build/MilBridge/tools/**`／`verify-all.sh`／`build/close-wave.sh`／哨兵／`docs/ROUTES.md`；**未** `git add/commit/push`。

---

## 9. 边界遵守自证

- **写域内实际被写的件**：`build/MilBridge/tests/PtsPagesProbe/evidence/**`（由**装置入口**一次性产出：9 件换代、20 件逐件 SAME）＋ 本件。**`build/MilBridge/HANDOFF-NEXT.md` 本件一个字都没写**（§5：格值已对 ⇒ 不追写）。
- **第 `29` 条**：改动面 **9** ⊆ 备份面覆盖（备份取的是**全目录 29 件**，逐件 `cp -p`，回读 `BACKUP_IDENTICAL`）⇒ **无漏备份件**。
- **腿跑纪律**：显示位 `:237`（`:23x` ✓）｜进程**只按 PID** 收（装置自收 pid 件；零 `pkill`/`killall`/`pgrep -f`；扫 `/proc` 时排除自身祖先链，现扫 0 残留）｜重活**全走 `heavy-slot.sh` 后台**（PID=3005541、日志在册、`held=30s`）｜**未跑整趟门禁**。
- **台账/中间件**落 `~/t94-runner/`（`bin/`／`logs/`／`bak/evidence-before/`），**未落 `/tmp`**；仓根未留临时件。
- **件位 sha16**：**跑前跑后各算一次**（§3／§4 表内逐件给出）。
- **资源（现取）**：`MemAvailable=4560164 kB`／`SwapFree=1414652 kB`／`df -Pk` 余 `72613368 kB` ⇒ 离停手线（2000 MB／512 MB／5 GB）远。
- **无 `git add`／`commit`／`push`**（全程零）。
本件编排口径（自报可复算）：**正文**（`head -n -1`，186 行）sha16 ＝ `b83862c342d55b3e`；**`inputs_fp` 现值** ＝ `48a3aa54b0f8d7ba1d3c40fb33f9229e713ecf33a58f9e0320d3ae56e6389830`；**改动面 9 ⊆ 备份面 29**（§3）。⚠️ **全文 sha16 是自指量、不可自报** ⇒ 只报正文值与 `inputs_fp`，全文值由读者现算。模式 `644`。
