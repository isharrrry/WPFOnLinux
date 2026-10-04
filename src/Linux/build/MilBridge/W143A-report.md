# W143A 报告 —— 重复派单，**未开工即被主控叫停**（本趟无任何有效读数）

**车道** W143A ｜ **属主** 主控 `session-3c5bcdcd-c429-4c43-bea8-299485647811`
**写定** 2026-09-23 22:5x +0800 ｜ 报告路径由主控指定 = `~/w143a-report.md`（**故意不写进 `$R`**：W142A 正在跑收尾链，我不在 `$R` 新增任何文件）
**本报告性质**：**只追加**的"叫停前我实际做了什么的证据清单"。**本车道未产出任何链上读数**（整波＝作废趟）。

---

## 0. 结论（一句话）

主控 22:2x 叫停时，我已启动**一条重活（整波）**并把它**按 PID 停在 `[1/6] integration-wave.sh`**
（`CLOSEWAVE_RC=143`，日志逐字 `已终止`）；**未冻结、未推送、未跑五臂/门禁/`verify-all`/`repin`/app-local/哨兵**，
**仓内手写件零改动**（`src/**` 非 bin/obj 改动数 = **0**）。那一趟记为**「作废（主控按 PID 叫停，非读数）」**。

---

## 1. 我叫停前实际跑过的命令（逐条，含 rc 与关键机读行）

### 1.1 轻活／只读取证（零副作用；不构成本趟读数）
| 命令 | 结果 |
|---|---|
| `df --output=avail /` | **70428264 KB = 67.2 GiB**（判据 ≥5 GiB ⇒ PASS） |
| `/tmp` 可写自检 `printf x > /tmp/w143-$$.t && rm` | **TMP_WRITE=OK** |
| `free -m` | 开工 `MemAvailable = 3812 MB`（重活门槛 1500 MB）；`nproc=4` |
| `sha256sum verify-all.sh / build/close-wave.sh / build/MilBridge/known-red.json / ACCEPTANCE-BASELINE.md / docs/WAVE56-PREREGISTRATION.md` | `eb29ced9d81b2345` / 当时 `027e1551b148c29e` / `453d17ca981d3116` / `38320d5e377a0dc8`（785,675 B）/ `5e549908db73fae7` |
| `sed -n '9p' docs/CURRENT-STATE.md` | `> BASELINE-FROZEN gen=#55 sha16=38320d5e377a0dc8 …` |
| `git log/ls-remote`（克隆 `~/netTest/GitProj/WPFOnLinux`） | head = `502f3061cee5e0f0f4713d18b36438633d921875`；`--symref` = `feat-Linux` |
| `sha256sum build/MilBridge/arm-logs/*.log`（五臂 before，**只读**） | 见 §4.2（与 `#55` 冻结点逐位相同） |
| 读 `~/w139a/STATUS.md` / `~/w129a/dispatch-CLOSE-54.md` / `~/w139a/logs/run-*.sh` / `build/close-wave.sh:360-410` | 配方与九位口径（只读） |

### 1.2 ⚠️ 重活：**整波一趟**（本报告要交代的唯一一条）
后台（`nohup`，**绝无前台 600 s**）：
```
nohup bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1200 --wait 1800 -- \
      timeout 1150 bash ~/w143a/logs/run-wave.sh      # 顶层 PID 1912362
```
`~/w143a/logs/run-wave.sh` 内含**两条**命令，日志 `~/w143a/logs/10-wave.log`（135 行）：

1. `bash src/WpfGfx.Linux.Native/build-shim.sh --all`
   ⇒ **`NATIVE_BUILD_RC=0`**；重建前后 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
   `2067cb1c97728791 → 2067cb1c97728791`（**逐字节复现**）｜**导出符号总数 547**（不变）｜ABI 段 `结果：全部一致`
2. `WAVE_OWNER=W143A bash build/close-wave.sh --skip-verify-all`
   ⇒ 起手 `[0/6] ✅ 无应用进程、无重发锁`｜`OUT=/home/links-dev/wfp-runs/close-wave-222813`｜
   计划行：`native 重建=否｜桥重发=否（现树 fp=d697b1e10ff48881 记录=d697b1e10ff48881）｜verify-all=跳过`
   ｜`[[1/6] integration-wave.sh]` 于 **22:28:13** 起跑；
   **主控按 PID 叫停 ⇒ 逐字读数**：
   ```
   已终止
     rc=143  （完整输出：/home/links-dev/wfp-runs/close-wave-222813/close-wave.log）
     ❌ [[1/6] integration-wave.sh] 失败 ⇒ 中止（**不要**在失败后继续后面的步骤…）
   CLOSEWAVE_RC=143
   === [Z] done 2026-09-23T22:29:41+08:00 ===
   HEAVYSLOT=RELEASED rc=0 held=91s max_hold=1200s
   ```
   叫停瞬间集成波正跑到：`dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Release -m:1 --nologo -v q`。
   ⚠️ **注意：没有"失败后继续"** —— `close-wave.sh` 自己在 `[1/6]` 失败即中止，`[2/6]…[6/6]`（含哨兵同步）**一步都没进**。

---

## 2. 我**没有**跑的步骤（逐条，供主控销账）

`retake-arms-w23.sh`（五臂）｜`repin-generation.py`（`--why`/`--check`）｜`run-wpftextdemo.sh` 门禁 ×2｜
`verify-all.sh`（**冻前/冻后都没跑**）｜`~/w21-verify/w27-freeze.py`（**未冻结**）｜
`~/w149a…/sync-applocal-authority.sh`（**app-local 未动**）｜`git add/commit/push`（**未推送**）｜
`nul-bytes-check.sh`／`hygiene-tooth.sh` 等牙本体（**一件未跑**）。

---

## 3. 我留下的进程与显示号（**已按 PID 收净**）

叫停时属我这条链的进程树（含 `integration-wave` 与 `dotnet build`），**按 PID 逐个 `kill -TERM`**：
```
1913457 dotnet build …PresentationCore.Linux.csproj    1913456 bash integration-wave.sh
1912592 bash integration-wave.sh                       1912463 bash close-wave.sh --skip-verify-all
1912371 bash run-wave.sh                               1912370 timeout 1150 …
1912369 timeout …                                      1912362 bash heavy-slot.sh …
```
⇒ 复查（`/proc/*/cmdline` 全表扫 `w143a`）：**零残留**（只剩我自己的取证 shell）。
**未用** `pkill`／`killall`／`pgrep -f`（全程一次都没用）。

**显示号：我这趟自起 Xvfb = 0 个**（叫停发生在门禁/`verify-all` 之前）。
现存 `Xvfb :99`(PID 1293973, 4h30m)／`:97`(1306360)／`:92`(1900383, 叫停前 22:26 起的、**非我**) ⇒ **一件未碰、未收**。

**如实登记（未处置）**：`dotnet` MSBuild **共享**节点进程 `1858991 / 1859068 / 1859081`
（`-nodemode:1 -nodeReuse:true`，可能由我这趟 `dotnet build` 派生）。
**我故意不杀**：它们是 `nodeReuse` 共享构建服务器、此刻 W142A 正在整波构建（杀共享节点有打断它构建的风险）；
且既不是 Xvfb、也不是应用进程。⇒ 交主控裁。

---

## 4. 现场自证（`sha256sum` ＋ `git status --porcelain`）

### 4.1 我**没**动的件（逐件现算，与落仓值对照）
| 件 | 现场 sha16 | 落仓/期望值 | 判定 |
|---|---|---|---|
| `verify-all.sh` | `eb29ced9d81b2345` | `eb29ced9d81b2345` | **未动** ✓ |
| `build/MilBridge/known-red.json` | `453d17ca981d3116` | `453d17ca981d3116` | **未动** ✓ |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `38320d5e377a0dc8`（785,675 B） | `#55` 冻结值 | **未动** ✓ |
| `docs/CURRENT-STATE.md` | `a67e269711686275`；`:9` = `gen=#55` | `gen=#55` | **未动** ✓ |
| 哨兵两处 `/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag` | `c99743dd77352d68` ＋ 同值，`cmp` **IDENTICAL**，mtime 均 **20:57:15**、`SHA=4e25e4b27d4d5ae1`、`WAVE=close-wave-205345` | 未被刷 | **未动** ✓ |
| `src/**` 手写输入（`.cs/.c/.h/.py`，排除 bin/obj，mtime ≥22:28） | **0 件** | — | **未动** ✓ |
| `build/shims/**`、`build/MilBridge/**`、`docs/**`、`samples/WpfTextDemo/**`（mtime ≥22:28） | **0 件** | — | **未动** ✓ |
| 克隆 `~/netTest/GitProj/WPFOnLinux` | `git status --porcelain` = **0 行**；head = `502f3061…92875` = 远端 | 一致 | **未推送/未改动** ✓ |

### 4.2 我**动了**的件（**只有构建生成物**；不是仓内手写件）
- `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`：被 `build-shim.sh --all` 重写，**sha16 逐字节不变** = `2067cb1c97728791`（导出 547）。
- `build/**` 生成物 **97 件**（含 `obj/`、`bin/`）mtime ≥22:28，即被 `[1/6]` 的构建重写；
  **九位身份全部与 `#55` 锚逐位相同**：

| 位 | 现场 sha16 | `#55` 锚 | 判定 |
|---|---|---|---|
| `bridge` | `4e25e4b27d4d5ae1` | `4e25e4b27d4d5ae1` | 同 |
| `pc` | `722e0ab8205b7c3f`（mtime 22:29:34，**被我这趟重编**） | `722e0ab8205b7c3f` | 同 |
| `pf` | `f2df3c2b464b7f00`（mtime 20:55:43，未被我这趟写） | `f2df3c2b464b7f00` | 同 |
| `windowsbase` | `2e4e46e539a72cd7`（mtime 22:28:46） | `2e4e46e539a72cd7` | 同 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 同 |
| `win32shim` | `2067cb1c97728791`（mtime 22:28:13） | `2067cb1c97728791` | 同 |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 同 |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 同 |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | 同 |

⇒ **九位零位移**；我这趟那次"被杀在构建中"**没有改任何产品身份**（`pc`/`windowsbase` 新 mtime 但 sha 可复现）。

- 五臂 before 读数（**只读、未取臂**，与 `#55` 冻结点逐位相同）：
  `tline a46cb0b4e853fa1f`｜`tab-zero 9150c3a26a3cb789`｜`tab-anchor 1c43a12dcaa5718a`｜
  `tab-rtl 92570318851ca7e8`｜`textlineproto 4bceceeed570ba70`；
  别名侧 `~/wfp-runs/arms23/*` 已 **`nlink=1`**（`TASK-0502` 波尾必做②**已办**，我无需再办）。

---

## 5. 遗留物（我未删，供主控/链属主处置）

1. `~/wfp-runs/close-wave-222813/`（`close-wave.log` 等）—— **我那趟作废整波的原始日志**，**故意保留作证据**、未删。
2. `~/w143a/**`（`criteria.md ff3abd545452d501`、`STATUS.md`、`logs/10-wave.log`、`logs/run-wave.sh`）—— 按主控"别删"保留。
3. ### 🦷 一条**真正的仪器发现（登记为主控裁，不是我的动作）**
   `build/integration-wave.sh:83-85`：
   ```
   WAVE_DONE="$REPO/build/.wave-done"
   rm -f "$WAVE_DONE"
   trap 'touch "$WAVE_DONE"' EXIT
   ```
   ⇒ `trap` 是 **EXIT 时无条件 `touch`**（**不看 rc**）。实测后果：我这趟**被 SIGTERM 打断的失败整波**
   也在 22:29 把 `build/.wave-done` **重建了出来** ⇒ 口径句「`.wave-done` **存在** = 上一波已消化，各车道可以写」
   对**被杀/失败的波**并**不成立**（会成为**假绿标记**）。
   **缓解事实**：W142A 的 `integration-wave.sh` 于 **22:31:05** 起手 `rm -f` 已把它清掉，**此刻 `build/.wave-done` 不存在**
   （`ls` 报 `没有那个文件或目录`）⇒ **无现行危害**。
   **建议**（不属我写域，只报）：改成 `trap 'rc=$?; [ $rc -eq 0 ] && touch "$WAVE_DONE"' EXIT` 之类，
   或把"上一波已消化"改成查 `close-wave-summary.txt`／基线号而非空标记。
4. **追加发现**：`build/wave-audit.log` 逐条记了波属主 —— 我的趟 `owner=W143A pid=1912592`（22:28:13）与
   W142A 的趟 `owner=W142A pid=1918013`（**22:31:05**）**不重叠**（我 22:29:41 已终止）⇒ **`integration-wave` 层没有真并发**。

---

## 6. `NOINFO` 逐条（既不算绿也不算红）

1. 我那趟整波 `[1/6]` **未跑完** ⇒ `integration-wave`／`appliers`／波前==波后 三件读数 **NOINFO**（作废趟）。
2. `build/**` 97 件生成物虽九位身份未变，但"这套生成物是不是一趟**自洽完整**的波输出"**NOINFO**
   （被杀在构建中）⇒ 请**一律以 W142A 的新整波为准**。
3. `build-shim.sh --all` 那条 `-Wmisleading-indentation`（`src/win32_misc.c:224`）等既有告警我**未逐条复核** ⇒ NOINFO。
4. 五臂判词（通过/失败数）、门禁、`verify-all`、`repin`、app-local、哨兵刷新：**全部 NOINFO**（本趟未跑）。
5. dotnet 共享 MSBuild 节点 `1858991/1859068/1859081` 的**归属**（是否由我这趟派生）**NOINFO**（未按 PID 追 `ppid` 链到底、未处置）。

---

## 7. 小结（≤5 行）

1. 我**只跑了一条重活**（整波），并在主控叫停后**立刻按 PID 停在 `[1/6]`**（`CLOSEWAVE_RC=143`），**没有"失败后继续"**。
2. **未冻结、未推送、未改 `CURRENT-STATE.md:9`、未动 app-local；哨兵仍是 20:57 那版**（`SHA=4e25e4b27d4d5ae1`）。
3. 仓内**手写件零改动**（`src/**` 非 bin/obj = 0 件；判据件/文档/样本 = 0 件）；克隆 `porcelain=0`、head == 远端。
4. 唯一被动的是**构建生成物**，且**九位身份与 `#55` 锚逐位相同** ⇒ 产品身份零位移；进程已按 PID 收净、**零 Xvfb 属于我**。
5. 顺带抓到一条**真仪器缺口**：`integration-wave.sh:85` 的 `trap 'touch .wave-done' EXIT` **不看 rc** ⇒ 失败/被杀的波也会留下"已消化"假标记（现已由 W142A 起手清除，无现行危害）。
