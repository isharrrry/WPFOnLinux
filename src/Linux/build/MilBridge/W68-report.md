# 波 `#68` 交付报告（`TASK-0722`）· 车道 **W162A-W68PREP**（owner）

> 放行件 `~/w129a/dispatch-W68-landing.md`（`84f20f1f89ed2c96`）｜判据先写 `~/w162a/criteria.md`（`74a5dae9d6d19106`）
> 落仓前置闸 `~/w162a/land/apply.sh`（`93d8fef391384cd7`）＋ `land/commit.sh`（`93d8fef391384cd7` 同目录）｜链条 `~/w162a/w68/**`
> **本波 = 判据装置波 · 零产品改动**（九位里只有环成员 `pf` 变）。

## §1 本波交了什么（逐件 before → after／新建）
| 落点 | before | after | 说明 |
|---|---|---|---|
| `verify-all.sh` | `9d28301987351fd1` | **`cf0a4dd317bb48ac`**（137,887 B） | 加第 `[39]` 步 `SILENT-HIT-V2` ＋ 四处声明里的三处 |
| `build/close-wave.sh` | `7281832adf70a02d` | **`622624a27c8bf6e0`**（41,193 B） | `fp_inputs()` 白名单 **+2 行**（**第三手**） |
| `build/MilBridge/tools/silent-hit-v2-check.sh` | （新建） | **`9eccf056bf2d7417`**（23,313 B／426 行） | 判据端牙（**单一实现**：`judge()` 一处） |
| `build/MilBridge/tools/silent-hit-v2-cases.tsv` | （新建） | **`7bc8a739cb66927c`**（1,632 B／表头＋12 行） | 确定性用例台账 |
| `docs/WAVE68-PREREGISTRATION.md` | （新建） | **`c48fb294a991c640`**（6,054 B／54 行） | 标题含 `#68`；**NA 声明落在「判据」节内** |

**写盘纪律**：逐件 `stat -c %h == 1` 前置断言（不满足**拒写**）→ `cp -a` 备份（`~/w162a/land/backup/*.before-w68`）→ `mv` 原子替换 → 写后现算 `sha16` 对账（`COMMIT_TOTAL_FAIL=0`）。
**未碰**：`KNOWN-DEFECTS.md`／`ROUTES.md`／`HANDOFF-NEXT.md`／`declared.tsv`／`known-red.json`（主控写域）。

## §2 判据（`D-G123` 的 v2 口径；本波落成**会咬的牙**）
`SILENT_SEGV_HIT ⇔ APP_TEXT_BYTES_TRIMMED == 0 ∧ STACKOVF == 0 ∧ 死于 SIGSEGV（SEGV_BRANCH ∈ {rc139, fate, term, stop-signo11}，命中时**必须印出哪一支**）`；两条前置闸：`UNDECLARED_TAG_LINES>0 ⇒ NOINFO`／收进程期死亡不计命中；**两个字节数都印**；剔除集**从文件读、行首锚定**（禁子串包含式）。
三态与 `rc`：`PASS=0`／`FAIL=1`／`NOINFO=2`（**空表／缺列／非整数／零行被检查** ⇒ `NOINFO`，**永不 PASS**）／用法错 `=3`。
`build/MilBridge/tools/silent-hit-v2-check.sh` 形态：`--selftest`（9 例）｜`--gate-selftest`（12 例）｜**`--cases <台账> --expect 12`**（`verify-all` 走这条）｜`--legs-from`（产出端一致性闸，本波**不接线**）｜`--denom`（跨件代禁合池）｜`--posctl`／`--polarity`。
**阳性对照＝门槛**：台账里**至少一行 `role=POSCTL` 且真判 `HIT`**，否则 `FAIL reason=untriggerable`（`D-G123` 口径句）。本波阳性对照来自**在册 4 条历史真命中**（`W071`／`W077`／`L1B024`／`W8AA-04`；逐条带件代与第三支）。

## §3 两极化（**落地前在真拷贝树里全部真跑**，非重活）
| # | 正极 | 反极 | 实测 |
|---|---|---|---|
| ① 声明链 | `VERIFYALL_SELF=PASS names=39 decl=39 gen=#68 dup=0 order=OK prose=OK prereg=PASS` | **删 `run_step` 行保声明 ⇒ `FAIL names=38 decl=39`** | rc=0／**rc=1** |
| ② 判据端 | 台账 12 行 ⇒ `SILENTHIT_CASES rows=12 examined=12 hits=6 nothit=4 noinfo=2 mismatch=0 posctl=2/2` | 空台账／缺列 ⇒ **`NOINFO rc=2`** | rc=0／rc=2（两例） |
| ③ 变体在位 | 屏上 `sha16` == 树里 `sha16` ⇒ `POLARITY=PASS` | 树里换未变体 ⇒ **`FAIL` 点名 `VARIANT_INPLACE`** | rc=0／**rc=1** |
| ④ 判据本体 | `--selftest` 9 例（三态齐备；`degenerate_flips=3`） | 退化实现不翻 ⇒ 红 | rc=0 |
| ⑤ 门槛/极性 | `--gate-selftest` 12/12 | 坏表／空表／缺列／无产出端**各有具名红** | rc=0 |
| ⑥ 预登记 | `PREREG4=NA rc=0` | NA 声明写在**节外** ⇒ 牙读不到（`#66` 的坑） | rc=0 |

## §4 覆盖面位移（`fp_inputs()`）
**第三手**：`#66` → 163、`#67` → 165 ⇒ 本波 **165 → 167**（白名单 +2 行）。**逐件归因（成员表差分，非照抄）**：只退 `silent-hit-v2-check.sh` ⇒ 166｜只退 `-cases.tsv` ⇒ 166｜**两件都退 ⇒ 与基点成员表逐位相同**⇒ **无第三隐形位移**。
⚠️ **`FP=NOINFO` 的口径保留**：两件未落到树里时 `xargs sha256sum` 必失败 ⇒ **指纹不可算，不许给形状完好的假值**；本波落仓后由整波现算（见记录件 `FROZEN` 段的 `inputs_fp`）。

## §5 `UNWIRED` 两条（逐字，已写进 `DECL` 首行）
① `producer=UNWIRED-IN-STEP`：产出端（腿驱动）**仍在车道**（8 份同形副本），`verify-all` 里**没有任何一步调用它** —— 判据口径**限定到代码形状**（`grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` **= 0**），**全文 `grep` 命中只作旁证**（`D-G119` 实例㉔）⇒ **不许把 `--cases` 的 `PASS` 读成「现件代已复现／已清零」**。
② `legacy-copies=DEPRECATED×7`（`w118a`／`wc06`／`wc07`／`wc08`／`wc11`／`w155a w65d109`／`w159a`；`w128a/bin/one128.sh` 留作历史真命中的产出者证据）⇒ 收编归 `TASK-0726`（排 `#69`）。

## §6 自伤与旧读数作废（如实留痕，四条）
1. **覆盖面基数作废**：我先前的 `162 件／4c1056dd…` 是**过期 `/tmp` 清单**（窗口内 `#66`／`#67` 白名单手已落）⇒ 现读 **165 件／`ab58dd61…`**；`nl-intent-check.sh`／`pts-pages-guard.sh` 命中**各 1**（原"命中 0"作废）。**教训：临时清单也是旧值。**
2. **needle provenance 假 MISS**：用"整文件按 utf-16-le 解码后再找"核 `[HC-UNHANDLED]` —— 该字面量在 dll 里落在**奇字节偏移（199831）** ⇒ 整文件解码**错位**；改**字节搜**后命中。且其**件内字面量行尾不带空格** ⇒ 我原写法会**永远剔不到**（已按件内实测改正）。
3. **判据咬到了判据自己**：第一版只声明 6 条剔针，跑真腿 `wo-off-1` 时闸**当场红**（`UNDECL=28`：`[WINSTATE_DIAG]`×26 ＋ `[WMCK_DIAG]`×2 ＝ 正常**诊断趟**）⇒ 补出**第二集**（13 条「已声明但不剔」）＋ 新 gate `DIAG:excluded-from-denominator`（腿有效、不进命中率分母）。
4. **补丁基线两次被别处改动打停**：`KNOWN-DEFECTS.md` 在窗口内被追加（`D-G131`、`D-G124` 机制取证）⇒ 我的 `S0` 基线牙两次把 `apply.sh` 停在 `rc=9` 并强制重新基 —— **"照着旧件打补丁"不会静默发生**。

## §7 射程边界与 `NOINFO`
- **本步只证**「判据装置还活着 ∧ 不许把不可判当零命中」；**不证**「现件代静默 SEGV 已复现／已清零」（产出端 `UNWIRED`）。
- **现件代应用级阳性对照**＝`pending-heavy-slot`（需真腿；属 `TASK-0722` 收口腿）。
- `--legs-from` **本波不接线**（无产出端 ⇒ 报 `NOINFO reason=no-producer-lines`，**不许静默通过**）。
- `--denom` 的「分母 = 应用真的跑过的腿数」仍只在判据文本与用例表层面，**未落到表的列上**（改表会破 W155A 四张自证夹具）⇒ 记 `TASK-0722` 残项。
- 仓自带读者输出里的 `dynamic_trace=NOINFO` 是**既有状态**，本波未改。

## §8 冻结与链条读数（**现读**，`~/w162a/w68/logs/`）
- **整波** `close-wave.sh --skip-verify-all` 槽内 **rc=0**（`held=217s`）｜`inputs_fp = ddf948f39c57213ee9fbd57f3e4538ad5fbc6ad534d157dc43538bfe6a7c0b45`（我的独立算法 `fp-coverage.py` 现算 **167 件／同一指纹** ⇒ 两条独立算法互证）｜**九位里恰好只有环成员 `pf` 变**（`cbd1884faeb4837e → ddb412ee7efa4b65`）⇒ 与 `allow_changed={'pf'}` 一致。
- **应用级门禁 ×2**（`run-wpftextdemo.sh`）：**判据件** `w68-rows-r{1,2}.txt` 各 = **6 行、6 行全 `result=PASS`**（冻结器要的就是它，且冻结器的三条断言都过：`len==6 ∧ 全 result=PASS ∧ pc/pf 是终态`）。⚠️ **外部读数两趟不对称（如实）**：pass1 日志 44,043 B 完整（`WPTD_SUMMARY=PASS tiers_passed=2/2`／`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`／尾 `HEAVYSLOT=RELEASED rc=0 held=197s`）；**pass2 控制台日志被满盘截断**（28,672 B ＝ 4 KiB 整数倍，`WPTD_GATE=`／`WPTD_SUMMARY=` **命中 0**，尾行是半个 `ls -l`）⇒ pass2 的 **`WPTD_*` 行记 `NOINFO reason=enospc-truncated-log`**，**不声称**"两趟判词行逐字相同"；判据只依赖 rows 文件（完整）。
- **门禁 ×2 ＋ 冻前 `verify-all`**：**三趟各** `步骤通过 39  ❌ 失败 0` ∧ `用例通过 875  跳过 2` ∧ `结论：✅ 全部通过`；`[11] VERIFYALL_SELF=PASS names=39 decl=39 gen=#68 dup=0 order=OK prose=OK prereg=PASS`；`[17] PIPEFAIL_SIGPIPE=PASS files=85 sites=85 hit=0`；`[38] PTS_GUARD=PASS legs=2/2`；**`[39] SILENTHIT=PASS`**；`[7] BASELINESHA=PASS live=3137b1d5728eeb97`（冻前＝上一代值）。
- **冻结（四格守卫）**：`FREEZE_RC=0`；**`BASELINE_SHA16 = a51071d05d6d7896`**（≠ 上一代 `3137b1d5728eeb97`）；`CURRENT-STATE`：`BASELINE-FROZEN gen=#68 sha16=a51071d05d6d7896`；`# RE-FROZEN #68` 命中 1；残留占位符 0。**冻结前已留** `~/w162a/w68/w68freeze/B.pre-freeze.#68.bak`（976,590 B）。
- ⚠️ **`FAULT-INJECT` 事故与恢复（如实）**：链条首轮 `gate1 rc=1／gate2 rc=1／pre rc=1`，根因 = **宿主磁盘写满（ENOSPC）**（`/home` 剩 79 MB；主控清理后 15→31 GB）⇒ **不是本波件的问题**：清盘后**只从 `gate2` 起重跑**（不提整波、不重跑应用级门禁）⇒ `gate2 rc=0`／`pre rc=0`、`39 ✅/0 ❌`；同一趟里 `GEOM-BEAT` 由 `❌ rc=120` 变 **✅**（反证定性成立）。

## §9 「守卫真的在工作」——两处**当场拦下的**自伤（正面证据，非事后自述）
1. **冻结器的 `inputs_fp 变了（停条件②）`当场拦下我的手误**：`prep-freeze.py` 更新 `infp` 的正则写成非贪婪 `('#68': dict\(.*?infp=')` ⇒ 第一个合法终点落在**同块的 `prev_infp='`** 上 ⇒ `prev_infp` 被改成本波值、而 `infp` 留在 `__INFP_PENDING__`。冻结器**没有**接受"看起来对"的表，直接 `assert INFP == G['infp']` **红了并停手**（`FREEZE_RC=1`，**未写盘**）。⇒ 这条守卫是**机器在守**，不是靠人记性；我已把该正则改成**只许命中行首缩进后的 `infp='`** 并加 `nsubn==1` 断言。
2. **我自己的 `S0` 基线牙两次把 `apply.sh` 停在 `rc=9`**：窗口内 `KNOWN-DEFECTS.md` 被别处追加（`D-G131`／`D-G124` 机制取证）⇒ 拒跑并要求重新基 ⇒ **"照着旧件打补丁"不会静默发生**。
3. 另：冻结器首跑 `rc=1` 的第二个原因是我把冻前日志传了**相对路径**（冻结器会先 `cd $R`）⇒ `FileNotFoundError`；两次失败**均未写盘**（`AB` 现读始终 `3137b1d5728eeb97`）。

## §10 链条产物索引
见记录件 `~/w21-verify/w68-record.txt`（冻结器读它）与 `~/w162a/w68/logs/{w68-wave-*,w68-gate1-*,w68-gate2-*,w68-pre-*}.log`；冻结四格守卫日志 `~/w162a/w68/w68freeze/logs/w68-freeze.{out,DONE|STOP}`。

`LANE=W162A TASK=0722 R_TOUCHED=verify-all.sh,build/close-wave.sh,+3 新建 DONE=yes NOINFO=4`
