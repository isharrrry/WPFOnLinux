# VPts-S — `t56` 独立复核：`t55` 关 `t13` 的 F-A–F-D

**判词：`pass`**（五条验收逐条**我自己现取/现算**通过；另附一条**观察**：§8.2 未逐名列出那 15 件旧代，见 §5）。
- 车道 `verifier`（`t56`，attempt `ab0b7410-f354-4cf0-88d6-f1bfdf061e03`）；读时刻 `2026-09-28T09:51:33 … 09:51:59+08:00`。
- **零重活**：无槽、无应用、无构建；只读 `$N` 与 `~/w12a`。资源现取（`09:51:33`）：`df_avail_kB=85,218,620`、`mem_avail_MB=7426`。

## §1 F-A（在册证据 ↔ 车道本趟）—— **逐字节同 ＋ 我自跑 `infp`**

两处**同一份**（我 `cmp` 逐件，`09:51:41`）：
```
build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log   mtime=2026-09-28 09:32:46  size=116911  sha16=eb6af2e16ba2bcfb
~/w12a/pts-legs-C/app_g1.log                              mtime=2026-09-28 09:32:46  size=116911  sha16=eb6af2e16ba2bcfb
CMP_app_g1: IDENTICAL        CMP_session: IDENTICAL
在册 app_g1.log 的具名行：3× entry=LoCreateContext，0× entry=CreateInstalledObjectsInfo   ← 旧代是 3a3544fe9d6f8132／3× 旧名
```
**抽查 `cmp` 全绿**（在册 ↔ 车道）：`session.txt`／`five_pre_g1.txt`／`five_post_g1.txt`／`leg_23.env`／`leg_24.env`／`device.txt`／`shots/g1/{boot,k24,k23,last}.png`／`arm_A/{leg_23,leg_24,device}.env|txt` ⇒ **13 件全部 IDENTICAL** ⇒ **同一趟** ✓。
**同趟自洽性（我逐件现取 mtime）**：`device/xvfb.log 09:32:20` → `device/xfwm.log 09:32:22` → `five_pre 09:32:25` → `boot.png 09:32:33` → `k24.png 09:32:40` → `k23.png 09:32:44` → `last.png 09:32:45` → `app_g1.log 09:32:46` → `five_post 09:32:46` → `session.txt 09:32:48` → `leg_23/24.env`＋`device.txt`＋`arm_A/*` `09:32:49` ⇒ **全部落在 09:32:20–09:32:49 的 29 秒窗口**（run 戳一致）✓。
**`inputs_fp` 我自己跑**（`09:51:41+08:00`）：
```
bash ~/w153a/bin/infp.sh fp  ⇒ 5aa65b7d9d706d50d9440ff172d4069e768e5656805bfb104803d6cf2c2d2aeb     （files=226）
```
⇒ **与 `t55` 声明的"新值"逐位相同**（其读时刻 `2026-09-28T09:47:25+08:00`；旧值 `37d4c6ab22f9606e…` ＝ `#79` 冻后声明值）✓。

## §2 F-B（§7.3 的 dated 更正 ＋ 同趟自洽性 ＋ 零证据力口径）

- **原句保留**：§8.2 先逐字引用 §7.3 原句（「新证据已入 `evidence/`…」），再给 **`dated 2026-09-28T09:47:25+08:00`** 的更正：**写下那一刻（09:33）只入了 3 件（`leg_23.env`／`leg_24.env`／`device.txt`），其余 15 件仍是 09-24 20:43 旧代 ⇒ 当时是两代混装、不能解释成同一趟**；并指回 §8.1 的整目录替换 ✓。
- **同趟自洽性读数在位**：`ls -l --time-style=+%F_%T` 逐件 14 项 ＋ 「run 戳 = `09:32:2x–09:32:49`」 ⇒ 与我 §1 的独立读数**逐项相符** ✓。
- **零证据力口径句逐字在位**：「门禁步 `PTS-PAGES`（`verify-all.sh:1173`，默认读本目录）**只读 `leg_*.env` 的列，不读 `entry=`** ⇒ **它的绿对"前沿位移"零证据力**。⇒ 本报告里凡引用 `PTS_GUARD=PASS`，一律**不得**被读成"前沿已位移"；前沿位移的**唯一**载体是 `app_g1.log` 的具名行」✓。
- 报告现取指纹：`d79a0c009515b3c4`／190 行（`09:51:51`）。

## §3 F-C（二选一：走"乙"）—— 三处 `NOINFO` ＋ 归属 ＋ 下一波点名

```
:183  NOINFO reason=detector-not-implemented（N2-b'：成功但 *pInstalledObjects=NULL ⇒ 判据必须红）
:184  NOINFO reason=detector-not-implemented（N2-c：只改报告/台账文本伪造前沿 ⇒ 台账不是真值来源）
:185  NOINFO reason=detector-not-implemented（N3：一次做两跳 ⇒ rc=134 仍未实测；~/w302-pts/report.md:229 自认"推算"）
:186  归属＝归 t12 遗留项（t4 设计 criteria.md:151-154 有定义、无实现）；下一波候选（甲）：win32_pts.c 加只读门控（如 WPF_LINUX_PTS_STUB_MODE=1）
```
⇒ 三条 `NOINFO` 逐条在位、**归属具名**、**下一波谁做（甲）已写成可执行候选** ✓。**走"乙"⇒ 无需**核 `N3` 的 `rc=134` 实测（本件**不声称**实测，报告明文写"仍未实测"）✓。

## §4 F-D（注释改准后 `PTSGAP` 仍 PASS）

`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 现读（`09:51:46`）：机读行 `# PTSGAP-DECL: tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 w66pre16=bf6b683d94549087`；其下 `#78` 重锚注释已改为 **`impl=95`**（原 `97`）✓。
**我自己跑牙**：
```
PTSGAP_CITED=PASS refs=1 strict=1
PTSGAP=PASS tool=100 dead=11 artifact=1 ops=88 impl=95 so16=6825dd7071387a46 exports=556 root=/home/links-dev/netTest/GitProj/WPFOnLinux
```
⇒ 五个字段与验收给定的期望**逐位相同** ✓。

## §5 未推送 / 未重冻（我自己 `git ls-remote` 现取）＋ 观察

- `ACCEPTANCE-BASELINE.md = 901619543b3d913b` ✓；`HEAD = 71603bd3762059b3e1791be4a5eac2359657e01ec`；`git ls-remote origin refs/heads/feat-Linux = 71603bd3762059b3e1791be4a5eac2359657e01f` ⇒ **HEAD == remote** ⇒ **未重推、未重冻** ✓。
- **观察（不构成 findings）**：§8.2 的"新/旧代"叙述**具名了那 3 件新代**、旧代只给**计数 15**（未逐名）；`§8.1` 的 18 件表给出了**全量件名**＋落仓后 sha16＋落/不落理由 ⇒ 可推导出那 15 件是谁。若要求"逐名列出旧代 15 件"，建议在 §8.2 补一行指向 §8.1 表的全量清单（**一行即可**）。

## §6 边界 / `NOINFO`

- 本件**零重活**：未跑应用腿、未跑 `verify-all`；所有读数均带读时刻（`09:51:33–09:51:59`）。
- 我只核 `t55` 的四处落点（`evidence/**` 18 件、报告 §7.3→§8.1/8.2、§8.3 三处 `NOINFO`、`pts-gap-decl.txt:36`）；**未**复核 `t55` 未声称的部分（例如 `N3` 的实现）。

## §7 落仓与自指

车道件 `~/w30x/t56-review.md` 与仓内件 `build/MilBridge/VPts-t55-close-review.md`（逐字节相同、`temp+rename`、`%h=1`）。
自指口径：`head -n -1 <本件> | sha256sum | cut -c1-16`。
