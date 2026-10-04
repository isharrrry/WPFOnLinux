# `P0-w79-report.md` —— 波 `#79` 收尾链逐条读数（`t23`；现取带时刻）

## §0 世代与头部
| 项 | 值 | 读取时刻 |
|---|---|---|
| 冻结世代 | `#79` | 2026-09-28T01:12:39+08:00 |
| 基线件 sha16 | **901619543b3d913b** | 冻结日志 `~/w79-close/logs/w79-freeze.log` |
| `docs/CURRENT-STATE.md:9` | `> BASELINE-FROZEN gen=#79 sha16=901619543b3d913b` | 01:12:39 后 |
| 推送提交 | **6a245bd5042598cef56f12a467b05618299562ec**（本地==远端） | 01:46 后 |
| 两哨兵 | `cmp` IDENTICAL ｜ 内容 `WAVE=w79-freeze BASELINE=#79 BASELINE_SHA16=901619543b3d913b`（两件同） | 01:47 |

## §1 冻结读数（逐条）
```
基线已重冻为 #79；整份 sha16 = 901619543b3d913b
BASELINESHA=PASS live=901619543b3d913b decl=901619543b3d913b ｜ BASELINEGEN=PASS decl_gen=#79
PREVCHECK=PASS gen=#79 keys=7 checked=7 skipped=0 base=d60b414d5e99cf72
BLOCKVALUE=PASS keys=9 tier_keys=8 bsfp=1 infp=1         ← 验收①：九位行逐键 == 现取值
相对开工前变化的位 = ['pc','pf','windowsbase','provider','dwf'] ⊂ allow_changed（实测五键）
inputs_fp = 4c096e9c0705a95d8a2a69617f777df06686e48b8e0ce40ae16eec75e095f180 ｜ BRIDGE_SRC_FP = d697b1e10ff48881
ARMLOG_SHA=PASS required=5 declared=5 pass=5 ｜ COLUMN_FLOOR=PASS corpus=0cebc0afd5142fbf
```
九位现写入块（**provider 已不是写死字面量**）：bridge `4e25e4b27d4d5ae1`／pc `38ae477949238306`／pf `12fb36e7b0df1802`／windowsbase `ed04eb65081c2d3a`／provider `759ac1686e5ef87d`／win32shim `e8127a3d7128d417`／wic `f7b3026c8c019be2`／hb `921ba9c65e9fb3be`／dwf `0d25f64a7dbb4c78`

## §2 链条（每步 rc 落盘并断言）
- `pre` `55 ❌ 0`（`w79-pre-20260928-005408.log`）；**冻结首跑曾按设计停手**（`STOP=freeze-red`，未写 `POST.done`）⇒ 主控修两处仪器缺陷后从第②步接跑。
- `post1` `w79-post1-20260928-011239.log` mtime `01:28:47` `55 ❌ 0`｜`post2` `w79-post2-20260928-012847.log` mtime `01:44:43` `55 ❌ 0`（皆 > 冻结点 `01:12:39`）。
- `~/w21-verify/w79-POST.done` 写在**真冻结之后**（`01:12:39`）；拒冻路径不写该标记（`D-G161` 族未踩）。

## §3 推送（第二笔；第一笔被守护拦停）
```
第一笔：PUSH_RC=9 ｜ PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list: build/MilBridge/tools/boundary-decl-check.sh ⇒ 停手（stage 之前 return ⇒ **零部分推送**）
第二笔（补清单后）：PUSH_RC=0 ｜ PUSH_LIST_GAP=PASS ｜ staged=31 ｜ COMMIT=6a245bd ｜ FF=yes
INFP_AT_PUSH == FROZEN_INFP = 4c096e9c…5f180 ⇒ INFP_FREEZE_PUSH_MATCH=PASS ｜ INFP_COUNT_RULER=PASS（live=225 == 声明常数 225）
REMOTE_PER_COMMIT=PASS n=1（主射程 993eb5d5..HEAD）｜ **超集 d2dec07..HEAD 计 6 笔全在场（REMOTE_PER_COMMIT_SUPER=PASS）**
REMOTE_AFTER=6a245bd5042598cef56f12a467b05618299562ec == local ｜ PORCELAIN=3 ｜ SENTINELS-IDENTICAL
```
- `porcelain=3` 逐件解释：`build/MilBridge/V79d-provider-disposition-verify.md`／`V79e-prefer-reds-close-verify.md`／`t22-report.md` —— **他车道（verifier）的未跟踪复验报告**，非本波落地件、非我写域 ⇒ 交 `t40` 那一笔或具名声明。

## §4 🔴 两条**陷阱**（照主控原话，**不写成已修**）
1. **哨兵**：本波重跑④前，两哨兵仍是 `BASELINE=#78`／`d60b414d5e99cf72` 且 `cmp` **IDENTICAL** ⇒ **两哨兵一致在哨兵根本没更新时照样成立**。本波已重写为本代（`#79`／`901619543b3d913b`），报告**同时给 `cmp` 与内容两读**。
2. **标记**：`~/w79c/logs/W79_PRE2END.done` 原先 `stop_line=` 空且**无 `PUSH_RC`** ⇒ **只看标记会读成链全绿完成**（主控的等待作业即如此，靠再读 driver 尾才看见 `PUSH_RC=9`）。本波对该标记 **append** 了一行 `push_rc=9 note=…`（**原文保留**）；驱动器标记块的补丁**未成功落**（我的锚未命中）⇒ 列入未落地项。

## §5 `D-G172`（本笔自带，具名）
- 本笔推送的 `build/MilBridge/tools/defect-registry-declared.tsv` **第 2 行有 2 键不实**：声明 `CS=e3f1d5cd98ea3404`／`AB=d60b414d5e99cf72`，现场 `CS=746a08e646370614`／`AB=901619543b3d913b`；实测 `DEFREG_DECLDRIFT=2`（读数时刻 `2026-09-28T01:14:50／01:15:26`＋我同区间现取）。
- 两趟 post 日志 `grep -c DEFREG_DECLDRIFT` **均为 0** ⇒ **该读数根本进不了冻后日志**（与主控在 `#78` 两份 post 上的 0 相符）。
- 关账归 `t40`（登记四号 → 最后 `--emit` → 成对重测 → 第二笔推送）；**不许重冻**（基线仍 `901619543b3d913b`）。

## §6 未落地项（**待下一趟、各自带 freeze**）
1. 驱动器标记块未携带 `push_rc=`（本波以 append 行代替）⇒ 下一趟改 `~/w79c/bin/w79-freeze2end.sh` 的标记块。
2. 重活下限三处分叉（`stage_gateapp`/`stage_verify` 1500 vs `stage_wave` 2500）⇒ 改**单一常数** ＋ 两极化腿。
3. `D-G170`／`D-G171`／`D-G172` 与 `--emit` 重出、`DECLDRIFT` 进冻后日志、反极性副本树必出声 ⇒ 归 `t40`。
4. `porcelain=3` 的三件他车道复验报告 ⇒ 交 `t40` 一笔或具名声明。
5. 我那份 `~/w79c/w79-record.txt`（`17ca2241446d3000`）⇒ `SUPERSEDED-BY=~/w186a/w79/w79freeze/w79-record.txt（52571ef51842467d）`，保留留证。

### §6-追 标记字段与状态不相称是**结构性**的（`t42`，2026-09-28T01:52 现取）
- **形态不匹配（根因，非偶发）**：驱动 `~/w79c/bin/w79-freeze2end.sh:27` 逐字为
  `stop_line=$(grep -aoE 'STOP=[a-z-]+' "$OUTF" | tail -1)` —— 它假设输出里有 `STOP=` token；
  而**本波 ④ 的真实输出**里只有 `PUSH_LIST_GAP=FAIL … ⇒ 停手，不推送` 与 `PUSH_RC=9`（**没有 `STOP=`**）
  ⇒ **grep 形态 ↔ 输出格式不匹配 ⇒ 必然抓空**（姐妹链 `w79-pre2end.log` 里写的是 `STOP=freeze-red`，所以那条路径抓得到）。
  读数时刻：现场取自 `~/w79c/logs/w79-freeze2end.log:34-36`（本轮 `01:44:43`–`01:46` 区间）与我 `2026-09-28T01:52` 的现取。
- **修法**：原因**从驱动自己的输出**取（先看 `停手，不推送` ⇒ `stop_line=push-blocked`，否则 `PUSH_RC=0` ⇒ `none(all-steps-ok)`），
  并显式写 `push_rc=` 与失败时的具名缺口 `push_list_gap=`（本轮＝`build/MilBridge/tools/boundary-decl-check.sh`），
  另抄一行 `stop_reason=`（逐字原文）。原字段 `MARKER`／`date`／`baseline_sha16`／`freeze_last` **保留**。
  驱动 sha16：改前 `4e2b53e31567cb75` → 终态 **`8c761d19f4eed7a0`**（两次均 `temp+rename`）。
- **两条极性腿**（`--marktest` 钩子**只跑标记块、块本体一字不改**，避免"第二实现"）：
  ```
  腿① 干净（注入 PUSH_RC=0）      ⇒ push_rc=0 ｜ stop_line=none(all-steps-ok)              ⇒ 非空且可读 ✔
  腿② 模拟停手（逐字复现本轮两行）⇒ push_rc=9 ｜ stop_line=push-blocked ｜ push_list_gap=PUSH_LIST_GAP=FAIL dirty-covered-files-not-in-list: build/MilBridge/tools/boundary-decl-check.sh ｜ stop_reason=… ⇒ 停手，不推送 ✔
  ```
- 🔴 **并列具名的第二条**（与上条同族）：**哨兵 `cmp` 相同 ≠ 当代** —— 我 `01:45:38` 取数时读到的是"两件 IDENTICAL"，
  而两哨兵 mtime 实为 **`01:46:12.730` / `.729`**（**比我取数晚 34 秒被手工刷新**）⇒ 结论必须**同时给 `cmp` 与内容/mtime**，否则"一致"会掩盖"不是本代"。
- ⚠️ **我在本趟自伤并已逐字节修复（如实入册）**：加 `--marktest` 钩子时我把它放在 `rm -f "$MARK"` **之后** ⇒ 钩子生效前 `rm -f` 先执行，
  **删掉了历史标记 `~/w79c/logs/W79_PRE2END.done`**。修法＝① 把钩子移到 `rm -f` **之前**（驱动 sha16 → `8c761d19f4eed7a0`）；
  ② 按已知原文**逐字节恢复**该标记并复原 mtime（`touch -d '2026-09-28 01:46:06'`）：恢复后 **`sha16 = 76011344c87b7d27`**，**与删除前现读完全相同** ⇒ 恢复**逐字节成立**；③ 复跑两条腿后该标记仍 `76011344c87b7d27`（未被再碰）。
  口径句：**「测试钩子必须排在"清理/写标记"之前；凡带 `rm -f "$MARK"` 的驱动器，任何 argv 覆盖都必须先于它生效」**。
