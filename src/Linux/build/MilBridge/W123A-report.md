# W123A 报告 —— 消除「`$R` 的件与仓外夹具硬链接同 inode」这个活着的危险（`D-G101` 落地）

- **车道**：W123A ｜ **基线**：`#51 38e67e834430d75c` ｜ `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- **纪律遵守**：**零 `dotnet`／零构建／零应用／不占槽**；纯文件级；**仓外夹具零写入（一个字节、一个 inode 都没动）**；全程 **temp ＋ `rename`** 落盘，**未用** `>`／`sed -i`／`truncate` 写仓内任何件；未 `pkill`。
- **判据先写**：`~/w123a/criteria.md`（2026-09-23 08:40，**早于任何改动**）；台账 `~/w123a/STATUS.md`（每步即追）。
- **本件结论一句话**：`$R` 侧**口径内跨区共享 1421 件 → 0 件**（内容两侧逐字节不变），并把**写者**`repin-generation.py` 从「原地写」改成「temp ＋ `rename`」（产出字节逐位等价）；**口径外仍有 11011 件**（构建产物 ＋ 第三方源），其中 **6 件是产品 DLL、与 `~/w113a/fixture/**` 同 inode、已上膛未击发** —— 逐条见 §6。

---

## 1. 判据（先写；逐字见 `~/w123a/criteria.md`）

| 判据 | 内容 | 结果 |
|---|---|---|
| **A1/A2** | 口径内逐件列出；`口径内 + 口径外 == 全树 links>1` 必须自洽 | ✅ 1421 ＋ 11011 = 12432 |
| **A3** | `$R` **内部零共享 inode**（否则断链会打断仓内链接 ⇒ 停手） | ✅ 0 行（处置前后各测一次） |
| **B1** | 每件处置前后 `$R` 侧 `sha256` 逐字节相同 | ✅ 1421/1421 |
| **B2** | 每件 inode 必须改变 | ✅ 1421/1421 全变 |
| **B3** | 每件 `$R` 侧 `links` 必须变 1 | ✅ 1421/1421 = 1 |
| **B4** | **夹具侧零写入**：全部对手方 `sha256` 不变 | ✅ 1556/1556 |
| **B5** | 权限／属主／`mtime` 保持（`cp -p` 语义） | ✅ 1421/1421 |
| **B6** | **承重件硬约束**：`known-red.json` `sha16` 前后逐位相同 | ✅ `089b7324ba12e022`（前=后） |
| **C 甲** | 危险是真的（原地写穿透）＋ 修法有效（temp+rename 不穿透） | ✅ 两半都成立（§4） |
| **C 乙** | 真树同口径复枚举 ⇒ 跨区 = 0；且两侧 `sha16` 成对不变 | ✅（§3、§6） |
| **D** | `repin-generation.py` 写盘方式：原地 vs temp+rename | ✅ **原地写**（`file:line` 见 §5） |

**口径（写死，全报告同一口径）**：
`find $R \( -path $R/upstream -o -name obj -o -name bin -o -name .artifacts \) -prune -o -type f -links +1 -print`
**"跨区共享"判定基准**：对 `/home/links-dev` 做**单遍 `-xdev` 全量索引**（`find … -printf '%i\t%n\t%p\n'`，本趟 `FIND_RC=0`，**257556** 行），再按 **inode 连接**。**不靠猜、不靠例子**。

---

## 2. 枚举：口径内 1421 件，**全部**跨区共享（逐件表见**附录 A**）

**现场规模**（`find`／`stat` 现场算）：

| 量 | 值 |
|---|---|
| `$R` 全部件（`-type f`） | **13375** |
| `$R` 内 `links>1` 的件（**不排除任何目录**） | **12432** |
| **口径内** `links>1`（本件处置对象） | **1421** |
| 口径外 `links>1`（**未处置**，见 §6） | **11011** |
| `$R` 内**两件共享同一 inode** 的情形 | **0**（判据 A3） ⇒ 多余链接**全部在 `$R` 之外** |

⇒ **关键结构发现**：口径内 1421 件**无一例外**都有仓外对手方（1290 件 1 个、129 件 2 个、2 件 **4** 个，合计 **1556** 条仓外路径）：

| 对手方区域 | 路径数 | 说明 |
|---|---|---|
| `~/w62a/negrepo/` | 1401 | **`$R` 的硬链接镜像**（它自身 12918 件里 12412 件 `links>1`） |
| `~/w113a/fixture/` | 144 | W113A 的负控夹具 |
| `~/w110a/arms/` | 5 | W110A 的臂装置 |
| `~/w26d-G9/tree{A,B,C}/` | 6 | W26D-G9 的三棵负控树 |

**两个"4 个对手"的件**（同一 inode 同时挂在三棵 w26d-G9 树 ＋ negrepo 上）：
`build/MilBridge/run.sh`（ino `4866304`）、`build/MilBridge/tests/HbTextLineParity/Program.cs`（ino `5111935`）。

**没扫什么（逐类点数，避免把"没扫"读成"干净"）**：

| 未纳入枚举的区域 | `links>1` 件数 | 理由 |
|---|---|---|
| `upstream/`（第三方源） | 6417 | 只有人手动改才危险；本趟按任务口径排除 |
| `obj/`（构建中间产物） | 1631 | 构建会重写；**口径排除 ⇒ 未处置**（§6 留作残留） |
| `bin/`（构建产物，含**产品 DLL**） | 2963 | 同上，**且这 6 件与 `~/w113a/fixture` 同 inode**（§6） |
| `.artifacts/` | 0 | 现场不存在此目录 |
| 符号链接 | 未跟随 | 本件只处理硬链接（同 inode）；符号链接是另一形态 |
| `/home/links-dev` 之外的路径 | 未扫 | 索引范围 = `/home/links-dev`（**单文件系统 `-xdev`**） |

**点名四件**（任务书给的例子）现场：

| 件 | 我开工时状态 | 结论 |
|---|---|---|
| `docs/PORT-SPEC.md` | `links=1 ino=4852681` | 已由 **W120A** 断链（不在我的 1421 内） |
| `docs/INDEX.md` | `links=1 ino=4852682` | 同上 |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `links=1 ino=5383439` | 同上（该件在我收工前又被别的车道重写成 `ino=5387945`，**不是我**：§7 自纠 E5） |
| `build/MilBridge/known-red.json` | **`links=3 ino=5251064`** | **危险仍活着 ⇒ 由本件处置** |

---

## 3. 处置（只断链、不改内容）与**成对证明**

**处置方法**（唯一实现 `~/w123a/relink.sh`，**彩排与真跑跑的是同一份代码**）：
对每件：`s1=sha256(源)` → `cp -p 源 → 同目录 .<名>.w123a-tmp.$$` → `s2=sha256(源)`、`sc=sha256(临时件)` → **若 `s1≠s2` 或 `s1≠sc`（有人在眼皮下改它）则跳过并点名（判据 S5）** → `mv -f -- 临时件 源`（同目录 ⇒ 同一文件系统 ⇒ `rename(2)`，不复制）。

**过程台账**：备份 `cp -p` 1421 件 → `~/w123a/backup/`（253 MB）并逐件校验（1421/1421 内容相同）→ 彩排（真跑同一函数，对副本）`ok=1421 skip=0 bad=0` → **真件处置 `08:48:20 → 08:48:48`（27.6 s）`ok=1421 skip=0 bad=0`**（**零跳过** ⇒ 处置窗口内没有任何件被别的车道改动）。

| 判据 | 读数 |
|---|---|
| **B1** `$R` 侧内容 `sha16` 前 vs 后 | **EQUAL=1421 DIFF=0**（断链那一刻） |
| ⚠️ **B1′** `$R` 侧内容 `sha16` 前 vs **收工** | **EQUAL=1420 DIFF=1** —— 唯一差异 = `build/MilBridge/tools/repin-generation.py`（`a2ca0a26bf99dc7a → 711a1fc30764d84c`），那是 §5【追加二】**有意**的写者修法；**断链本身**对 1421 件的读数仍是 `EQUAL=1421 DIFF=0` |
| **B4** 夹具侧内容 `sha16` 前 vs 后 | **EQUAL=1556 DIFF=0** |
| **B2** `$R` 侧 inode 前 vs 后 | **CHANGED=1421 SAME=0**（例：`4851292→4852620`、`4851297→4852651`） |
| **B3** `$R` 侧 `links` 后 | **全部 = 1**（唯一取值） |
| **B5** `mode` 前 vs 后 ／ `mtime` 前 vs 后 | **EQUAL=1421 DIFF=0** ／ **EQUAL=1421 DIFF=0** |
| **夹具侧 `links`** | 前 `{2:1290, 3:258, 5:8}` → 后 `{1:1290, 2:258, 4:8}` ⇒ **每件恰好 −1**（= 断链的定义，不是写入） |

**承重件 `build/MilBridge/known-red.json`（B6 硬约束）**：

```
sha16  前 = 089b7324ba12e022      后 = 089b7324ba12e022     ← 逐位相同 ✅
sha256 后 = 089b7324ba12e022834242e3de50009c2561bc21f5bc133b3597e1d7f9d7c78e   （现场算，未手抄）
links  3 → 1        inode 5251064 → 4853410        mode 600（未变）
三份副本内容 sha16（$R／~/w62a/negrepo／~/w113a/fixture/fp-farm）后 = 089b7324ba12e022 ×3（内容一致）
```

> ⚠️ **只报不改**：两个**夹具之间**仍互为硬链接（`~/w62a/negrepo/.../known-red.json` ↔ `~/w113a/fixture/fp-farm/.../known-red.json`，`links=2 ino=5251064`）——**不在我写域**，一个 inode 都没动。该残留的危险已由 §5 的**写者侧修法**拆掉（写者不再原地写）。

**逐件 `stat` 对照**：附录 A 给每件的 `links前／inode前／size／sha16前=后／对手方全路径`；`inode 后` = 现场 `post.R.tsv`（判据 B2 已逐件比对全变）。**机器可复算**：
```bash
bash ~/w123a/snap2.sh ~/w123a/list.in_scope.R.txt /tmp/x.tsv   # 现算
bash ~/w123a/cmp2.sh ~/w123a/pre.R2.tsv /tmp/x.tsv 1 1 "内容"   # 期望 EQUAL=1421 DIFF=0
```

---

## 4. 两级化证明（逐字读数）

### 甲 · 危险是真的（**沙箱**里演，不动真件；`~/w123a/sandbox/demoA|demoB`）

**甲① 写穿（原地截断）**：
```
建链后   links=2 ino=5384392 size=20  a / b      写前 sha16: 1d0b5df096de2aa2  a = b
动作     printf 'CORRUPTED-BY-INPLACE-TRUNCATE-v2\n' > a
写后     links=2 ino=5384392 size=33  a / b      写后 sha16: 721c7bbf8a618193  a = b
b 的内容逐字 = CORRUPTED-BY-INPLACE-TRUNCATE-v2      ⇒ WRITE-THROUGH=YES（b 被写穿）
```

**甲② 修法有效（temp ＋ `rename`）**：
```
建链后   links=2 ino=5384409 size=20  a / b      写前 sha16: 1d0b5df096de2aa2  a = b
动作     cp -p a .a.w123a-tmp.$$ ; 改临时件 ; mv -f -- 临时件 a
写后     links=1 ino=5384410 size=31  a          sha16: 4f5b1b822df85a15  a   （**换 inode**）
         links=1 ino=5384409 size=20  b          sha16: 1d0b5df096de2aa2  b   （**逐位不变**）
b 的内容逐字 = ORIGINAL-CONTENT-v1                  ⇒ B-UNCHANGED=YES
```
⇒ **甲成立**：同 inode 的原地写**必然**改对手；temp＋`rename` **不**改对手（因为它换掉了 inode）。

### 乙 · 真树已断

- **乙①（同口径复枚举）**：口径内 `links>1` 件数 **1421 → 0**；`$R` 内部共享 inode **0 → 0**。
- **乙②（成对证明）**：`$R` 侧 1421 件 `sha16` 前=后（`EQUAL=1421 DIFF=0`）**且** 夹具侧 1556 条 `sha16` 前=后（`EQUAL=1556 DIFF=0`）。
- **乙③**：处置后 `$R` 侧 `links>1` 的**口径内**件数 = **0**。

---

## 5. 【追加二】写者侧：`repin-generation.py` 从「原地写」改成「temp ＋ `rename`」

### 5.1 改前：确认是**原地写**（`文件:行` ＋ 逐字）

`build/MilBridge/tools/repin-generation.py`（改前 `sha16 a2ca0a26bf99dc7a`，`mode 600`）：
```python
111:        ar["why"] = args.why
112:    json.dump(d, open(REG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
113:    open(REG, "a", encoding="utf-8").write("\n")
```
`:112` 以 `"w"` 模式 `open(REG)`（`REG = <repo>/build/MilBridge/known-red.json`，`:30`）⇒ **原地截断**；`:113` 再以 `"a"` 追加换行，**仍是同一 inode**。⇒ **不是** temp+rename。
（独立旁证：W119A 的牙第 `[138]` 行的原地写字面量登记与本读数一致；该牙的判据正是"搜字面量"。）

### 5.2 改后：temp ＋ `rename`（`os.replace`）

```python
    tmp = "%s.w123a-tmp.%d" % (REG, os.getpid())
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
            f.write("\n")
            f.flush(); os.fsync(f.fileno())
        try:
            os.chmod(tmp, os.stat(REG).st_mode & 0o7777)   # 保住旧实现的权限位（现场 600）
        except OSError:
            pass
        os.replace(tmp, REG)                                # rename(2)：原子，且换 inode ⇒ 不穿透
    except BaseException:
        try: os.unlink(tmp)
        except OSError: pass
        raise
```
- `sha16`：**`a2ca0a26bf99dc7a` → `711a1fc30764d84c`**（`mode 600` 未变，`size 5413 → 6928`，`links=1`）
- 落地方式：写临时件 → `diff` 逐字核对 → `compile()` 语法复验 → `chmod 600` → `mv -f`（**temp ＋ rename，未用 `>`／`sed -i`**）
- 现场字面量：`open(REG, "w"` 命中 **0**；`os.replace(` 命中 **1** ⇒ 该牙的第四类从此把本件判成 **`temp-rename`**（与它 `:138` 预先登记的 rename 字面量 `os.replace(` 吻合）

### 5.3 判据：行为等价（同一输入 ⇒ 同字节）＋ 写穿成对（沙箱，`~/w123a/sandbox-repin.sh`）

装置：两棵等价沙箱树（各含 `run.sh`／`Program.cs`／`PresentationCore.HbTextLine.cs`／五臂 `arm-logs`／**真件 `known-red.json` 的逐字节副本**），每棵树里把 repo 的 `known-red.json` 与"夹具"做**真硬链接**；`old` 树放改前脚本、`new` 树放改后脚本。

```
装置自检   old: repo sha16=089b7324ba12e022 ino=5387976 links=2   fix ino=5387976 links=2
           new: repo sha16=089b7324ba12e022 ino=5387993 links=2   fix ino=5387993 links=2
           old_script=a2ca0a26bf99dc7a   new_script=711a1fc30764d84c
           ✔ 跑前已取基线: PRE_OLD_FIX=089b7324ba12e022  PRE_NEW_FIX=089b7324ba12e022
跑两侧     两版都印 REPIN_GENERATION=APPLIED；instr_run_sh=030b169b0ccad24d、instr_program_cs=396982ce5bb5ce91、
           instr_shim=fcef902b2ab07efd、evidence_log_sha256=604d5a66df10cfa9、caliber 改动字段数=12（**逐行相同**）
判据1      old_out sha16=de4b21c3354e9586 size=68896   new_out sha16=de4b21c3354e9586 size=68896
           BEHAVIOR_EQUIVALENT=YES（cmp 逐字节相同）  产出权限位 old=600 new=600
判据2      OLD（原地写）      夹具 前=089b7324ba12e022 后=de4b21c3354e9586 ⇒ **WRITE_THROUGH=YES**
           NEW（temp+rename）  夹具 前=089b7324ba12e022 后=089b7324ba12e022 ⇒ **WRITE_THROUGH=NO**
                              （NEW 侧夹具 links 2→1、inode 仍 5387993 ⇒ 只是少了一条链接）
```
⇒ **两条判据都成立**：改后**产出字节逐位等价**，且**不再穿透**硬链接对手。

### 5.4 `inputs_fp` 影响判断（**机械核，并更正任务书的一条前提**）

⚠️ **任务书说"该件在 `fp_inputs()` 覆盖面内"——现场核为**不成立**：
```bash
sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh > ~/w123a/fp_inputs.fn.sh
bash ~/w123a/fp.sh members     # 覆盖面成员数 = 149
grep -c -E 'repin-generation|hygiene-tooth' ~/w123a/fp.members.txt   # ⇒ 0
```
| `inputs_fp` 现场值 | 读数 |
|---|---|
| 改 `repin-generation.py` **之前**（连测 3 遍） | `72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`（3/3 逐位相同） |
| 改 `repin-generation.py` **之后**（连测 3 遍） | `72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`（**逐位不变**） |

⇒ **本件对 `inputs_fp` 零影响**（**不是**设计性变更，`#51` 收尾链**不必**为本件重钉 `inputs_fp`）。理由逐字：`fp_inputs()` 的四条 `find` 只吃 `patch-*.py`／`port-lib.py`／`integration-wave.sh`／`close-wave.sh`／`shims/*.cs`／`src/WpfGfx.Linux/**/*.cs`／`Native/**/*.{c,h}`，外加一条 **20 件写死清单**；`build/MilBridge/tools/repin-generation.py` **不在**其中任何一条里。（**残留缺口**：改名成 `patch-repin.py` 就会被吃进 ⇒ 该件属"改它零机器红"一族，建议 W122A 决定是否纳入。）

### 5.5 牙的复验（【追加一】）

| 时刻 | 牙的第四类读数 |
|---|---|
| W119A 断链**前**（主控转述） | `HYGIENE_TOOTH=FAIL … inode=FAIL … multilink=1388 cross_region=1383` |
| **我断链后**（本车道实跑，`bash build/MilBridge/tools/hygiene-tooth.sh`，**只读调用、未改该件**，`sha16 dc1e79a23dbb7eb2`） | `HYGIENE_INODE=PASS multilink=0 cross_region=0`；`HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS … multilink=0 cross_region=0`（`rc=0`） |
| **写者改后**（再跑一遍） | `HYGIENE_INODE_WRITERS build/MilBridge/known-red.json\|build/MilBridge/tools/repin-generation.py\|**temp-rename**\|rename-literal:os.replace(`；`HYGIENE_INODE=PASS multilink=0 cross_region=0`；`HYGIENE_TOOTH=PASS` |

**口径差说明（为何牙说 0、我全树还有 11011）**：牙的 `HYG_SKIPDIRS='.git obj bin .artifacts upstream node_modules __pycache__ .vs TestResults .dotnet'` ⇒ **牙的口径 = 我的口径 − `__pycache__`**（1421 − 33 = **1388**，与 W119A 报的 `multilink=1388` 逐位吻合）。**牙的 PASS 自带有射程句**（`HYGIENE_BOUNDARY`），没有把 `obj/bin/upstream` 说成干净 ✅。**按追加一要求如实报**：断链后**牙的口径**跨区 = 0，但**全树仍有 11011 件跨区共享**（§6）。

---

## 6. 断链后复枚举 ⇒ 跨区 = 0（**口径内**）；**口径外 11011 件仍在**（如实报，未处置）

| 区域（`$R` 侧） | `links>1` 件数 | 对手方区域 | 危险评估 |
|---|---|---|---|
| `bin/`（构建产物） | 2963 | `~/w62a/negrepo` **2958**／`~/w113a/fixture` **6** | ⚠️ **构建会重写 ⇒ 活跃** |
| `obj/`（构建中间） | 1631 | `~/w62a/negrepo` 1631 | ⚠️ 构建会重写 |
| `upstream/`（第三方源） | 6417 | `~/w62a/negrepo` 6417 | 低（只有人手动改才危险） |
| **合计** | **11011** | | 详见下 |

### 6.1 六件"**已上膛未击发**"的产品 DLL（最该先看的一条）

```
./build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll   ino=5019103 links=3 size=103936
./build/PresentationCore.Linux/bin/Release/PresentationCore.dll                  ino=5126522 links=2 size=3601408
./build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll        ino=5018442 links=2 size=6123520
./build/ReachFramework.Linux/bin/Release/ReachFramework.dll                     ino=5138421 links=2 size=627712
./build/WindowsBase.Linux/bin/Release/WindowsBase.dll                           ino=5126541 links=2 size=1111552
./src/WpfGfx.Linux/bin/Release/net10.0/WpfGfx.Linux.dll                         ino=5138198 links=2 size=342016
       ↳ 对手方（全部在 ~/w113a/fixture/repo/** 同一相对路径）
```
**时间线证据（只读 `stat`）**：这些 DLL 的 `mtime = 2026-09-22 20:31:10`（最后一次写入库），而 `ctime = 2026-09-22 22:10:45` = `~/w113a/fixture/repo/.../bin/Release` **目录的 ctime** ⇒ 夹具是 **22:10:45 用 `cp -al` 建的**（link 数变化 ⇒ ctime 更新），**晚于**最后一次构建。
⇒ **结论**：写穿**尚未发生**（夹具 DLL 与 `$R` DLL 现在内容相同），但**下一次重写这些 DLL 的构建就会静默改掉 `~/w113a/fixture/**`**（**已上膛、未击发**）。⚠️ **我没测"`dotnet build` 是否原地写这 6 件"**（本车道零 `dotnet`）⇒ 该点标 **`NOINFO`**；但"它们至今仍 `links=2`"本身说明**自 22:10:45 以来没有构建重写过它们**，与"原地写"兼容。

### 6.2 根因（【追加三】，只写报告、未动任何夹具）
夹具是用 **`cp -al`（硬链接克隆）** 建的 ⇒ **"副本"与本体同 inode** ⇒ 任何**原地写**都会**穿透到夹具**。这与 `D-G80`（"读到旧的"）是**同一手段的两个反面**：`cp -al` 省了空间与时间，却把**"写"和"读"都变成了共享**。

---

## 7. 不接线（本件只做处置 ＋ 读数）：**这段给 W119A 的牙**

建议该牙（`hygiene-tooth.sh` 第四类）断言这四条：
1. **写者形态 × 跨区同 inode**：对登记表 F 的每个 `(target, writer)` 对，抽 writer 件里的 `lit_in`／`lit_rn` 字面量 ⇒ 判 `inplace`／`temp-rename`／`unconfirmed`；**`inplace` ∧ target 跨区同 inode ⇒ FAIL**（现在就是这么判的 ✅）。建议补一条：**`unconfirmed` 不许当绿**（今天只印 `HYGIENE_INODE_UNCHECKED`，人容易读成过）。
2. **构建产物要单列一档**：`obj/`／`bin/` 下的跨区同 inode，危险来源是**构建**而不是"手写者" ⇒ 建议按"下一构建即穿透"单列（如 `HYGIENE_INODE_BUILDARMED n=…`），否则这 6 件 DLL 会被 `HYG_SKIPDIRS` 的沉默吃掉。
3. **口径射程必须随 PASS 一起印**：牙的口径排除了 `obj/bin/upstream/__pycache__` ⇒ 它有义务把"全树仍有 N 件跨区"作为**口径差**印出来（它今天印了 `HYGIENE_BOUNDARY` ✅，建议把 `HYGIENE_INODE_UNCHECKED` 也并进总行）。
4. **`cp -al` 夹具区要登记（只计不判）**：把 `~/w62a/negrepo`／`~/w113a/fixture`／`~/w110a/arms`／`~/w26d-G9/tree*` 登记为"硬链接农场根"，**报数进总行但默认不进 `rc`**（仓外状态不是仓的性质）。

---

## 8. `NOINFO` / 未做（逐条）

1. **口径外 11011 件未处置**（写域外）：`bin/` 2963 ＋ `obj/` 1631 ＋ `upstream/` 6417。⇒ **危险没有全域消除**，尤其 §6.1 那 **6 件 DLL**。若主控要清，命令与代价：**约再占几十 MB～数 GB 磁盘**（本机现余 31 G），一条命令即可（把 `list` 换成 `find $R -type f -links +1 -print`），**但会动构建产物区**，我**没有**越权做。
2. **`dotnet build` 是否原地重写那 6 件 DLL：`NOINFO`**（零 `dotnet` 纪律）。只给了"上膛未击发"的时间线证据。
3. **未在真树上跑 `repin-generation.py`**（它写 `known-red.json` 这个承重件）⇒ 行为等价只在**沙箱**里证（输入 = 真件的逐字节副本）。**真件 `sha16` 全趟未变**：`089b7324ba12e022`。
4. **两个夹具之间**仍互为硬链接（`known-red.json` `links=2 ino=5251064`）——**未动、只报**（写域外）。
5. **未跟随符号链接**；**未扫 `/home/links-dev` 之外**；`~/w62a/**`、`~/w113a/**` 等夹具区**只读**（索引只取 `stat`／`sha256`）。
6. **未跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`defect-registry-check.sh`（纪律禁止）。
7. **牙的"其余原地写形态未机械解析"**（它自己 `HYGIENE_INODE_UNCHECKED` 已声明：`sed -i`／`tee`／`cp`／`mv`／python `open(w)`）⇒ 我**只**核了登记表里那一件写者。

### 8.1 自纠（我自己犯的错，逐条留档）
- **E1**：`STATUS.md` 第一版我**预填了尚未执行的步**（把计划写成已做完）⇒ 08:40 立即整份重写为"只记已完成 ＋ 独立 PLAN 段"。**未据此产出任何读数**。
- **E2**：备份脚本用 `sed 's|/[^/]*$||'` 求目录 ⇒ **8 个顶层件**（`global.json`／`README.md`／`.gitignore`／`handoff.md`／`wpf-linux.sln`／`BuildHygiene.props`／`.gitattributes`／`README-Window.md`）在备份目录里被 `mkdir -p` 成**目录**，`cp -p` 把件拷进了目录里 ⇒ 备份自检当场报 **8 处 DIFF**（`EQUAL=1413`）。修：改用 `awk -F/ 'NF>1{…}'`，**整份重建备份并复验 1421/1421**。**只影响我的备份，`$R` 一个字节没动**。
- **E3**：`snap.sh` 里 `stat -c '%h\t%i…'` 输出的是**字面 `\t`**（不是真制表符）⇒ 列错位 ⇒ 我第一版"inode 全变／mode·mtime 保持"的比对**是空转的**（比的是路径 vs 路径）。修：改用 `stat --printf`，新写 `snap2.sh`＋`cmp2.sh`，**所有前后对照全部重算**（本报告的 §3 读数全部来自修正后的工具）。⇒ **这条正是本项目的"仪器自伤"老毛病，我当场留档。**
- **E4**：我用 `python3 -m py_compile` 复验语法，它往仓内写了 `build/MilBridge/tools/__pycache__/repin-generation.py.cpython-310.pyc`（`mode 644`、`08:51` = 我造的；同目录另三个 `.pyc` 是 9/13–9/16 的旧件）⇒ **已删除我造的那一个**，其余未动；此后改用 `compile()` 内存复验（不落 `.pyc`）。⚠️ 遗留：该 `__pycache__` **目录**的 mtime 被我改成 `08:52`（目录时间戳，非内容）。
- **E5**：牙两次报 `defect-registry-declared.tsv` 的 `repo_sha`／`ino` 不同（`dea8c731…/5383439` → `041e04f2…/5387945`）—— **不是我**：我全趟没碰该件（**W122A 在办登记**）。记此以免被误归因。

---

## 9. 大白话小结（≤6 行）

1. `$R` 的件与仓外夹具**同 inode** 不是 4 件，是 **1421 件**（都是 `~/w62a/negrepo` 这份"硬链接克隆"夹具的镜像）——我按判据**逐件断链**，`$R` 拿新 inode、**两侧内容逐字节不变**，口径内跨区共享 **1421 → 0**。
2. **写穿是真的**（沙箱里原地写 `a`，`b` 当场被改）；**temp ＋ `rename` 就不穿透**（`a` 换 inode，`b` 逐位不变）——两级化都成立。
3. **承重件 `known-red.json` 只换 inode、内容一字未动**（`sha16 089b7324ba12e022` 前=后）。
4. 真正的"下一次爆炸"在**写者**：`repin-generation.py:112` 当时是**原地写**——已改成 **temp ＋ `os.replace`**，**同一输入产出字节逐位相同**（`de4b21c3354e9586`），且**不再穿透夹具**；该件**不在 `fp_inputs` 覆盖面**（`inputs_fp` 前后逐位不变，**这不是**设计性变更）。
5. 牙（`hygiene-tooth.sh`）第四类由 `FAIL` 转 **`PASS multilink=0 cross_region=0`**，写者形态被认成 **`temp-rename`**。
6. **没做完的**：口径外还剩 **11011 件**跨区共享（`bin/` 2963 ＋ `obj/` 1631 ＋ `upstream/` 6417），其中 **6 件是产品 DLL、与 `~/w113a/fixture/**` 同 inode**——**已上膛未击发**，下一次重写它们的构建就会打穿 W113A 的夹具。

---

## 10. 产物与复算入口

| 产物 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/W123A-report.md` | 见末行 | 本报告 |
| `build/MilBridge/tools/repin-generation.py` | `a2ca0a26bf99dc7a` → **`711a1fc30764d84c`** | **本件唯一改的仓内件**（写者，temp ＋ rename） |
| `~/w123a/criteria.md` | `9557dc58a986d106` | 判据（先写） |
| `~/w123a/STATUS.md` | `9c78ae6920f61d78` | 台账 |
| `~/w123a/relink.sh` | `773708987f67764d` |（v1，§3 断链那 1421 件）|
| `~/w123a/relink2.sh` | `523137372f1715eb` |（v2，多一道 inode 守卫；§11 这批用）| 处置函数（唯一实现，彩排＝真跑） |
| `~/w123a/snap2.sh`／`cmp2.sh`／`fp.sh` | `431a12a9c7bbd973`／`3cb038857fa23968`／`07b2e66205deceea` | | 读数三件套（改后版） |
| `~/w123a/sandbox-repin.sh` | `c4f40e0219178dc5` | | 追加二：等价 ＋ 写穿成对 |
| `~/w123a/pre.R2.tsv`／`post.R.tsv` | — | `$R` 侧前后快照（1421 行） |
| `~/w123a/pre.fixture2.tsv`／`post.fixture.tsv` | — | 夹具侧前后快照（1556 行，**只读**） |
| `~/w123a/enumeration` | — | 逐件枚举（**附录 A** 已内嵌本报告） |
| `~/w123a/backup/` | — | 1421 件 `cp -p` 备份（253 MB）；`~/w123a/backup-repin/repin-generation.py.before` | 
| `~/w123a/sandbox/` | — | 甲①② 沙箱 ＋ 追加二沙箱树 |
| `~/w123a/backup-clean/` | — | §11 那 4588 件的 `cp -p` 备份（4.1 G）|
| `~/w123a/clean.R.pre.tsv`／`clean.R.post.tsv` | — | §11 `$R` 侧 4588 件前后快照（现场算）|
| `~/w123a/clean.F.pre.tsv`／`clean.F.post.tsv` | — | §11 夹具侧 4588 条前后快照（**只读**）|
| `~/w123a/report-section11-13.md` | — | §11–13 追加节的源文（供复核改写）|

---

## 11. 【追加节 · 主控裁定一】清理 `bin/`＋`obj/` 跨区共享（＋那 6 件产品 DLL）

> 主控要求把本批写成"§9 追加节"；本报告 §9 已被「大白话小结」占用、§10 为产物表，**为不覆盖已有节号**，本批记为 **§11**（内容即主控所指的追加节）。

**授权范围（主控裁定一，逐字照办）**：✅ 清 `bin/`（2963）＋`obj/`（1631）＋那 6 件产品 DLL；❌ **`upstream/`（6417）不破**（见 §11.7）。

**开工前安全核（两条，都是现场读数）**
- **无进程持有目标件**：只读扫 `/proc/[0-9]*/fd/*` 找指向 `$R` 的句柄 ⇒ **0 条** ⇒ 无需跳过任何件（`~/w118a` 当时在槽里跑的是 `dotnet HandyControlDemo.dll` ＋ `gdb`，**不写 `obj/`/`bin/`**，我也**没打断它**、**没占槽**）。
- **判据 A3**：`$R` 内部共享 inode **0 行**（处置前）。

### 11.1 第一步：6 件产品 DLL（`08:57:57 → 08:58:03`，`RELINK[dlls] ok=6 skip=0 bad=0`）

| # | 件（`$R` 相对路径） | sha16 前→后 | inode 前→后 | links 前→后 | mode | mtime |
|---|---|---|---|---|---|---|
| 1 | `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` | `1f9511a7ef395bfe` → 同 | `5019103→5022299` | **3→1** | `644→644` | 不变 |
| 2 | `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` | `722e0ab8205b7c3f` → 同 | `5126522→5144513` | **2→1** | `644→644` | 不变 |
| 3 | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `bc2c47ac7b067bad` → 同 | `5018442→5022301` | **2→1** | `644→644` | 不变 |
| 4 | `build/ReachFramework.Linux/bin/Release/ReachFramework.dll` | `58a24724a42a8e31` → 同 | `5138421→5144514` | **2→1** | `644→644` | 不变 |
| 5 | `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` | `2e4e46e539a72cd7` → 同 | `5126541→5144515` | **2→1** | `644→644` | 不变 |
| 6 | `src/WpfGfx.Linux/bin/Release/net10.0/WpfGfx.Linux.dll` | `374b5a538ea955aa` → 同 | `5138198→5144516` | **2→1** | `644→644` | 不变 |

**夹具侧（`~/w113a/fixture/repo/**`，只读）**：6/6 **sha16 逐位不变**、**inode 逐位不变**（`5019103`／`5126522`／`5018442`／`5138421`／`5126541`／`5138198`）、`links` 各 **−1**（`3→2` 与 `2→1` 五件）。⇒ **夹具零写入**。
**`skip.dlls.txt` = 0 行**（没有任何件被并发改动）。

### 11.2 第二步：`bin/`＋`obj/` 分批（每批 **开工前** 记一行、**完成后** 记一行，见 `STATUS.md`）

| 批 | 开工 | 完成 | 件数 | 读数 |
|---|---|---|---|---|
| `batch.bin.00` | 09:03:17 | 09:04:1x | 1056 | `ok=1056 skip=0 bad=0` |
| `batch.bin.01` | 09:04:16 | 09:05:0x | 1032 | `ok=1032 skip=0 bad=0` |
| `batch.bin.02` | 09:05:01 | 09:05:2x | 869 | `ok=869 skip=0 bad=0` |
| `batch.obj` | 09:05:28 | 09:05:56 | 1631 | `ok=1631 skip=0 bad=0` |
| **合计** | | **09:05:56** | **4588** | **`ok=4588 skip=0 bad=0`（跳过清单 0 行）** |

⇒ **没有任何件被正在跑的进程持有而需要跳过**（§11 开头那条 fd 扫描已先证）。处置函数为 **v2**（`~/w123a/relink2.sh`，比 v1 多一道 **inode 守卫**：若源件在"读"与"覆盖"之间被换掉则跳过并单列）——本批该守卫**零触发**。

### 11.3 成对证明（**4588 件 ＋ 夹具侧 4588 条，逐件**）

| 判据 | 读数 |
|---|---|
| `$R` 侧内容 `sha16` 前 vs 后 | **EQUAL=4588 DIFF=0** |
| **夹具侧**内容 `sha16` 前 vs 后 | **EQUAL=4588 DIFF=0** |
| `$R` 侧 inode 前 vs 后 | **CHANGED=4588 SAME=0** |
| **夹具侧 inode** 前 vs 后 | **EQUAL=4588 DIFF=0**（一个 inode 都没动） |
| `$R` 侧 `mode` ／ `mtime` | **EQUAL=4588 DIFF=0** ／ **EQUAL=4588 DIFF=0** |
| **夹具侧** `mode` ／ `mtime` | **EQUAL=4588 DIFF=0** ／ **EQUAL=4588 DIFF=0** |
| `$R` 侧 `links` 后 | **全部 = 1** |
| **夹具侧** `links` | 前 `{2:4588}` → 后 `{1:4588}`（**每件恰 −1**） |

### 11.4 身份记录：**未连带动到 ⇒ 未触发停手条件**（主控点名的红旗）

`ARTIFACT-SRC-FP.txt` 有 **维度 B（peer）**＝"本工程 csproj 引用的**本仓内产物字节**"（8–9 个 `.dll`），**这正是我清的那类件** ⇒ 必须实测。清完 `bin/`＋`obj/`（含 6 件 DLL）后只读复检：
```
ARTIFACT_SRC_FP proj=PresentationCore      fp=3ae4746cd655023b n=1374 peer_fp=e442fdc0c64f3379 peer_n=8 state=ok
ARTIFACT_SRC_FP proj=WindowsBase           fp=0cf7e7daa70eb8a9 n=327  peer_fp=2a2ed993f748365d peer_n=2 state=ok
ARTIFACT_SRC_FP proj=PresentationFramework fp=01a078bf78c6ed18 n=1363 peer_fp=0e31c2dc0c4e31c4 peer_n=9 state=ok
```
⇒ **`state=ok` ×3、`peer_fp` 逐位不变** = 内容没动 ⇒ **身份记录未被连带动到**。另：那 6 个 DLL 的 `sha16` 全仓只出现在**历史报告 `.md`** 里（不是判据/声明件），而**内容未变** ⇒ 那些历史记录**依然准确**。

### 11.5 清完后复枚举（**口径内／口径外分开报**）

| 口径 | 读数 |
|---|---|
| **口径内**（`prune upstream/ obj bin .artifacts`）`links>1` | **0 件** |
| **全树** `links>1` | **6417 件**，**全部属 `upstream/`**（逐类分类：`upstream/` 6417、`obj/` 0、`bin/` 0、其他 0） |
| 判据 **A3**（`$R` 内部共享 inode） | **0 行** |

**总账**：原始跨区共享 **12432** = 本件处置 **1421**（§3）＋ **6**（DLL）＋ **4588**（`bin/`＋`obj/`）＋ **声明不破 6417**（`upstream/`） → `1421+6+4588 = 6015`，`6015+6417 = 12432` ✅

**磁盘**（现场 `df`）：开工 `29G` → 备份后 `25G` → 清完后 **`21G`**（备份 `4.1G` ＋ 新副本 `4.09G`）。

### 11.6 牙的第四类（只读复跑，`hygiene-tooth.sh` **未改**，`sha16` 仍 = `dc1e79a23dbb7eb2`）

```
HYGIENE_INODE_ROSTER repo_files=1499 fixture_files=13132 multilink=0 cross_region=0 fixture_roots=2 missing=0
HYGIENE_INODE_WRITERS build/MilBridge/known-red.json|build/MilBridge/tools/repin-generation.py|temp-rename|rename-literal:os.replace(
HYGIENE_INODE=PASS multilink=0 cross_region=0
HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS scope=REPORT semantic_undecidable=7 multilink=0 cross_region=0 ext_ext_hits=0 ext_strict=0 code_files=72
```
⇒ `HYGIENE_TOOTH=`**`PASS`** ｜ `HYGIENE_INODE=`**`PASS`** ｜ `multilink=`**`0`** ｜ `cross_region=`**`0`**（**牙的口径**）。**口径差**（必须读）：牙的 `HYG_SKIPDIRS` 含 `obj bin upstream __pycache__` ⇒ 它的 `0` **不等于**全树干净 —— 全树仍有 **6417 件**（= `upstream/`）。

### 11.7 `upstream/` 声明残留（**不破链**；口径句逐字 ＋ 我自己的现场数）

**口径句（逐字，主控裁定）**：
> 「`upstream/**` 与夹具同 inode ⇒ **不破链，因为无写者**；**若将来有人要在 `upstream/**` 原地写，必须先破链**」

**我现场算的对手方分布**（不引别人数）：`upstream/` 下 `links>1` 的 **inode 数 = 6417**（与件数 1:1）；对手方路径 **6417 条，全部在 `~/w62a/negrepo/`**（`w113a/fixture` **0** 条、`w110a/arms` 0 条、`w26d-G9` 0 条）。⇒ 该残留只暴露 W62A 一份夹具，且**无写者**（vendored 快照、按约定只读；applier 写的是 `build/**` 副本）。

### 11.8 本批的流程违规（主控点名，我认）
- 主控指出**我的 `STATUS.md` 滞后于真实动作**（W125A 一度据此误判"未做"）⇒ **台账确实滞后**：4 个批的"开工/完成"两行我是在**四批全部跑完之后**才补记的（真实时刻取自运行输出）。⇒ 从 §11.5 起的后续步骤（复枚举／牙／身份记录／本报告）**台账均为"做前一行、做后一行"**，不再事后补。

---

## 12. 主控的两条更正（写进报告留档）

### 12.1 更正一：`repin-generation.py` **不在** `fp_inputs()` 覆盖面（**主控认错**）
主控原派单写"该件在 `fp_inputs()` 名单内、属设计性变更、必须排在 `IN_FP_0` 之前"。**机械核为不成立**：覆盖面 **149** 件、`grep -c -E 'repin-generation|hygiene-tooth'` = **0**；`inputs_fp` 改前=改后=**`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`**（各连测 3 遍）⇒ **不是**设计性变更，`#51` 收尾链**不必**为本件重钉。主控已在派单里认下这条错（"又一次没机械核就下结论"）。

### 12.2 更正二：写者修法的**可复算验收口径**（逐字留档）＋ 残留口径缺口
**断言（可复算）**：**同一输入 ⇒ 两版产出逐字节相同**（`sha16 = de4b21c3354e9586`、`size = 68896`、`mode = 600`）**＋ 沙箱里 OLD `WRITE_THROUGH=YES` / NEW `WRITE_THROUGH=NO`**。
复算入口：`bash ~/w123a/sandbox-repin.sh`（输入 = 真件 `known-red.json` 的逐字节副本 ＋ 两棵等价沙箱树；`old` 树放 `~/w123a/backup-repin/repin-generation.py.before`，`new` 树放现件）。
**残留缺口（建议登记车道立一条口径句）**：`fp_inputs()` 的 glob 里有 `-name 'patch-*.py'` ⇒ **把本件改名成 `patch-repin.py` 就会被覆盖面吃进**；今天它**不在**覆盖面 ⇒ 属"**改它零机器红**"一族（与 `D-G80` 同族）。⇒ 建议口径句：「`build/MilBridge/tools/repin-generation.py` 是**判据承重件**（它写 `known-red.json` 的世代绑定）⇒ **改它必须看得见**；若不纳入 `fp_inputs()`，则须由别的牙看住它的**写盘形态**（现已由 `hygiene-tooth.sh` 第四类看住）。」

---

## 13. 仪器**静默空转**独立节（主控裁定三：必须单独成节 ＋ 说清结论是否被改）

### 13.1 症状（`snap.sh` 的 `\t`）
`snap.sh` 用 `stat -c '%h\t%i\t%s\t%a\t%u:%g\t%Y'` 取元数据，但 **GNU `stat -c` 把 `\t` 原样输出为两个字符（反斜杠 ＋ t）**，而 `printf '%s\t%s\t%s\n'` 里的 `\t` 才是真制表符。⇒ 每行**只有 3 个真字段**：
`[sha16]  ⟨真TAB⟩  [links\tino\tsize\tmode\tuid:gid\tmtime 一整串字面量]  ⟨真TAB⟩  [path]`
⇒ 我按"8 列"写的比对**全部错位**：`cut -f3` 拿到的是 **path**（不是 inode）；`cut -f5,7` **根本不存在**（两侧都是空串 ⇒ 恒等）。

### 13.2 空转版的原结论 vs **重算后**的结论（**逐条对照**）

| # | 空转版的"结论" | 它实际比的是什么 | **重算后**（`snap2.sh`） | 是否被改 |
|---|---|---|---|---|
| 1 | inode 全换（`CHANGED=1421`） | 比的是 **path vs path**（两个目录前缀不同 ⇒ 必然全"不同"） | inode **1421/1421 全换** | **不变**（但空转版是巧合，不是证据） |
| 2 | `mode`／`mtime` 保持（`META_KEPT=1421`） | 比的是**两个不存在的字段**（两侧皆空 ⇒ 恒等） | `mode` **1421/1421 保持**、`mtime` **1421/1421 保持** | **不变**（同上） |
| 3 | `links` 分布 = 全 1 | `cut -f2 \| uniq -c` 打出 **1421 行**各带计数 `1`（那是"1421 个唯一串"的计数，**极易被读成"1421 个 links=1"**） | `links` **全部 = 1** | **不变**（同样的巧合） |

⇒ **结论：三条结论逐条与重算版相同，没有任何一条结论被改过。** 但必须说清两件事：
1. **空转版不构成证据** —— 它的三条都是"拿错东西比出来的"，只是**碰巧**与真值一致；这些结论今天**有证据**，靠的是重算。
2. **受影响范围 = 仅"彩排"阶段的 inode／meta／links 三项**。**内容类读数全程有效**（真字段 1 = `sha16`，位置正确）；**真件处置、全部收工验证、以及 §11 这一批的成对证明，全部用 `snap2.sh` 产出**（`sha16` = `431a12a9c7bbd973`）。

### 13.3 同族第二例（本节新增，同一形态：**读数静默错、不报错**）
`awk` 求和把 `bin/`＋`obj/` 待清集合的总字节打成 **`2147483647`**（= `2^31−1`，**int32 上溢钳位**），而真值是 **`4387006694`**（4.09 GiB，Python 复算）。⇒ 若我据此判"磁盘够用"，**会低估到一半以下**。两例的共同形态与 `D-G39`（SIGPIPE 伪红）**同族**：**读数器自身坏了、不报警、数字看起来很正常** ⇒ 结论：**凡"总和／分布"类读数，必须用第二种工具复算一次**（本报告全部关键量均已双算）。

---

---

## 附录 A · 逐件枚举表（口径内 `links>1` 的 **1421 件**，处置前现场）

列：`#` ｜ `$R` 相对路径 ｜ `links`(前) ｜ `inode`(前) ｜ `size` ｜ `sha16`(前=后) ｜ `跨区` ｜ 对手方路径（**全部**，仓外 **只读**）

生成方式：`python3 ~/w123a/gen-appendix.py`（读 `pre.R2.tsv`／`post.R.tsv`／`ino-partners.txt`，**不手抄任何哈希**）

| # | 件（`$R` 相对路径） | links前 | inode前 | size | sha16前=后 | 跨区 | 对手方路径 |
|---|---|---|---|---|---|---|---|
| 1 | `docs/U2-PresentationCore-scan.md` | 2 | 4851292 | 38925 | `bf7e7119581cbb98` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-PresentationCore-scan.md` |
| 2 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/TestScene.cs` | 2 | 4851297 | 12266 | `ab7149b139f331a1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/TestScene.cs` |
| 3 | `tests/artifacts/rendering/image_brush.png` | 2 | 4851306 | 3549 | `2044a124a7796abd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/image_brush.png` |
| 4 | `docs/duce-commands.txt` | 2 | 4851317 | 3506 | `275186ebc52e9bed` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/duce-commands.txt` |
| 5 | `docs/T0T1-report.md` | 2 | 4851318 | 6015 | `e648dcf6b7c0ec20` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/T0T1-report.md` |
| 6 | `docs/T9-roadmap.md` | 2 | 4851320 | 3847 | `b84742ed0d6a7317` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/T9-roadmap.md` |
| 7 | `build/NuGet.config` | 2 | 4851323 | 767 | `f88b268b5295e94f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/NuGet.config` |
| 8 | `build/fonts/NotoSans-Regular.ttf` | 2 | 4851326 | 431364 | `f3961a9cde016d41` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/NotoSans-Regular.ttf` |
| 9 | `build/fonts/NotoSans-Bold.ttf` | 2 | 4851327 | 432376 | `87cb2d84472a7d66` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/NotoSans-Bold.ttf` |
| 10 | `build/fonts/NotoSans-Italic.ttf` | 2 | 4851328 | 446880 | `678288f868807d4d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/NotoSans-Italic.ttf` |
| 11 | `build/fonts/NotoSans-BoldItalic.ttf` | 2 | 4852165 | 441936 | `3d367743f371f286` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/NotoSans-BoldItalic.ttf` |
| 12 | `build/fonts/SHA256SUMS` | 2 | 4852236 | 347 | `c56104d99146d2a5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/SHA256SUMS` |
| 13 | `build/WindowsBase.Linux/TextServicesLoader.Linux.cs` | 2 | 4852240 | 17820 | `92c2ab584b4e48a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/TextServicesLoader.Linux.cs` |
| 14 | `build/setup-env.sh` | 2 | 4852256 | 6752 | `34b4376d6c042675` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/setup-env.sh` |
| 15 | `build/verify-env.sh` | 2 | 4852257 | 5466 | `5ca7f01f30361703` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/verify-env.sh` |
| 16 | `build/PresentationBuildTasks.Linux/PORT-CHANGES.md` | 2 | 4852267 | 3690 | `3923c1d722e85265` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationBuildTasks.Linux/PORT-CHANGES.md` |
| 17 | `build/port-pbt.sh` | 2 | 4852270 | 12503 | `fb1776465d806a8d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/port-pbt.sh` |
| 18 | `build/PresentationBuildTasks.Linux/Directory.Build.targets` | 2 | 4852271 | 100 | `55902bea9ee1570f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationBuildTasks.Linux/Directory.Build.targets` |
| 19 | `build/PresentationBuildTasks.Linux/SR.g.cs` | 2 | 4852272 | 25441 | `b1aeab39c06c7db7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationBuildTasks.Linux/SR.g.cs` |
| 20 | `build/gen-sr.py` | 2 | 4852273 | 3752 | `df3aa842872b19e3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/gen-sr.py` |
| 21 | `build/WpfMarkupCompile.Linux.targets` | 2 | 4852274 | 1449 | `2f31238248728f36` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WpfMarkupCompile.Linux.targets` |
| 22 | `tests/parity/linux/diff/scene12_arc_ellipse.diff.png` | 2 | 4852279 | 3458 | `56fd4fb9f0f32ac8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene12_arc_ellipse.diff.png` |
| 23 | `build/WindowsBase.Linux/PORT-CHANGES.md` | 2 | 4852286 | 1483 | `c678a7657c8b8d96` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/PORT-CHANGES.md` |
| 24 | `build/WindowsBase.Linux/SR.g.cs` | 2 | 4852287 | 93345 | `d217d689516922f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/SR.g.cs` |
| 25 | `tests/golden/image_brush.png` | 2 | 4852291 | 3549 | `2044a124a7796abd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/image_brush.png` |
| 26 | `tests/parity/linux/diff/scene13_arc_degenerate.diff.png` | 2 | 4852295 | 3532 | `9080040b86ec516a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene13_arc_degenerate.diff.png` |
| 27 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenRenderTests.cs` | 2 | 4852296 | 40670 | `3e5722cbeae76af5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenRenderTests.cs` |
| 28 | `build/System.Xaml.Linux/PORT-CHANGES.md` | 2 | 4852299 | 665 | `857e278c954e1a7d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Xaml.Linux/PORT-CHANGES.md` |
| 29 | `build/System.Xaml.Linux/SR.g.cs` | 2 | 4852300 | 62377 | `f7f3c9dec294a942` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Xaml.Linux/SR.g.cs` |
| 30 | `build/PresentationCore.Linux/reapply-patches.py` | 2 | 4852306 | 19613 | `bf18b988deb5a4be` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/reapply-patches.py` |
| 31 | `build/shims/Accessibility.Shim.cs` | 3 | 4852309 | 1400 | `28fb0e85318f343e` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/Accessibility.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/Accessibility.Shim.cs` |
| 32 | `src/WpfGfx.Linux/Interop/HResult.cs` | 3 | 4852313 | 1473 | `3258dd39321aae12` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/HResult.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/HResult.cs` |
| 33 | `src/WpfGfx.Linux/Interop/Duce.cs` | 3 | 4852314 | 6976 | `4de4dbef01d6404a` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/Duce.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/Duce.cs` |
| 34 | `src/WpfGfx.Linux/Interop/MilEnums.cs` | 3 | 4852315 | 4608 | `dd2242c2fdc9558c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilEnums.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilEnums.cs` |
| 35 | `src/WpfGfx.Linux/Interop/MilValueTypes.cs` | 3 | 4852316 | 11057 | `251c01f0c89f08dc` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilValueTypes.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilValueTypes.cs` |
| 36 | `src/WpfGfx.Linux/Interop/GlobalUsings.cs` | 3 | 4852318 | 617 | `493694930553a1e3` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/GlobalUsings.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/GlobalUsings.cs` |
| 37 | `src/WpfGfx.Linux/Commands/MilCommandStructs.cs` | 3 | 4852321 | 56655 | `c3dd11cd37fe4cad` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilCommandStructs.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilCommandStructs.cs` |
| 38 | `src/WpfGfx.Linux/Commands/MilCommandEncoder.cs` | 3 | 4852323 | 55319 | `56f375b8e2a9deac` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilCommandEncoder.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilCommandEncoder.cs` |
| 39 | `src/WpfGfx.Linux/Commands/MilCommandDecoder.cs` | 3 | 4852324 | 8350 | `474ba6a19e06cab0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilCommandDecoder.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilCommandDecoder.cs` |
| 40 | `src/WpfGfx.Linux/Commands/MilRenderData.cs` | 3 | 4852325 | 8729 | `778caf0f48e8f034` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilRenderData.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilRenderData.cs` |
| 41 | `src/WpfGfx.Linux/Commands/MilResource3D.cs` | 3 | 4852327 | 15119 | `821e1782923e4717` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilResource3D.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilResource3D.cs` |
| 42 | `src/WpfGfx.Linux/Commands/MilBitmapSource.cs` | 3 | 4852328 | 9291 | `f557af99b477212e` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilBitmapSource.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilBitmapSource.cs` |
| 43 | `src/WpfGfx.Linux/Rendering/AssemblyInfo.cs` | 3 | 4852330 | 704 | `ca38d3b403ccef37` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/AssemblyInfo.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/AssemblyInfo.cs` |
| 44 | `src/WpfGfx.Linux/Rendering/MilResourceProvider.cs` | 3 | 4852331 | 5411 | `1121e6105406fa58` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/MilResourceProvider.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/MilResourceProvider.cs` |
| 45 | `src/WpfGfx.Linux/Rendering/SkiaColor.cs` | 3 | 4852332 | 3102 | `17e2371119fb79cf` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaColor.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaColor.cs` |
| 46 | `src/WpfGfx.Linux/Rendering/SkiaPen.cs` | 3 | 4852334 | 5529 | `a9803a839e9e2143` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaPen.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaPen.cs` |
| 47 | `src/WpfGfx.Linux/Rendering/SkiaGeometry.cs` | 3 | 4852336 | 5768 | `6b2f46cdeffc7165` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaGeometry.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaGeometry.cs` |
| 48 | `src/WpfGfx.Linux/Rendering/SkiaEffect.cs` | 3 | 4852339 | 9016 | `fdec72a4437cee4d` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaEffect.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaEffect.cs` |
| 49 | `src/WpfGfx.Linux/Windowing/WindowEvent.cs` | 3 | 4852342 | 4265 | `4e15aeeda1364ca7` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/WindowEvent.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/WindowEvent.cs` |
| 50 | `src/WpfGfx.Linux/Windowing/X11Display.cs` | 3 | 4852343 | 15204 | `a56fae3f14749848` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/X11Display.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/X11Display.cs` |
| 51 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-hwndtarget-trace.cpython-310.pyc` | 2 | 4852344 | 9698 | `214b9fdf54b5bc99` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-hwndtarget-trace.cpython-310.pyc` |
| 52 | `src/WpfGfx.Linux/Windowing/X11PresentationTarget.cs` | 3 | 4852345 | 5930 | `9861117f89383476` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/X11PresentationTarget.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/X11PresentationTarget.cs` |
| 53 | `src/WpfGfx.Linux/Windowing/X11Structs.cs` | 3 | 4852346 | 7143 | `7590e2f10de49790` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/X11Structs.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/X11Structs.cs` |
| 54 | `src/WpfGfx.Linux/Text/TextFontDescription.cs` | 3 | 4852348 | 2901 | `f5a816007c9ebbcf` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/TextFontDescription.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/TextFontDescription.cs` |
| 55 | `src/WpfGfx.Linux/Text/GlyphRunRequest.cs` | 3 | 4852350 | 3306 | `2a5408c9d11be453` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/GlyphRunRequest.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/GlyphRunRequest.cs` |
| 56 | `src/WpfGfx.Linux/Text/GlyphRunLayout.cs` | 3 | 4852351 | 6137 | `0b138f7670d144ea` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/GlyphRunLayout.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/GlyphRunLayout.cs` |
| 57 | `src/WpfGfx.Linux/Text/GlyphRunPainter.cs` | 3 | 4852352 | 2199 | `a78355990321fe0b` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/GlyphRunPainter.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/GlyphRunPainter.cs` |
| 58 | `src/WpfGfx.Linux/Text/MilGlyphRunAdapter.cs` | 3 | 4852353 | 3261 | `a7d56c5a087ab497` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/MilGlyphRunAdapter.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/MilGlyphRunAdapter.cs` |
| 59 | `src/WpfGfx.Linux/Text/TextRenderer.cs` | 3 | 4852354 | 9884 | `15d1ffcb26dc4105` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/TextRenderer.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/TextRenderer.cs` |
| 60 | `src/WpfGfx.Linux/Text/AssemblyInfo.cs` | 3 | 4852355 | 712 | `f3689611c3921200` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/AssemblyInfo.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/AssemblyInfo.cs` |
| 61 | `src/WpfGfx.Linux/Resources/MilResources.cs` | 3 | 4852357 | 18114 | `88d1d12b7c31bbbe` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/MilResources.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Resources/MilResources.cs` |
| 62 | `src/WpfGfx.Linux/Resources/MilResourceTable.cs` | 3 | 4852358 | 11848 | `8dc815a5d1a5f808` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/MilResourceTable.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Resources/MilResourceTable.cs` |
| 63 | `src/WpfGfx.Linux/Resources/MilVisualNode.cs` | 3 | 4852360 | 2631 | `a6213cb425a75e19` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/MilVisualNode.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Resources/MilVisualNode.cs` |
| 64 | `src/WpfGfx.Linux/WpfGfx.Linux.csproj` | 2 | 4852362 | 1125 | `e0e60edc6420b1d1` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/WpfGfx.Linux.csproj` |
| 65 | `src/WpfGfx.Linux/Contracts/MilPrimitives.cs` | 3 | 4852364 | 1913 | `f67e91469658427d` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Contracts/MilPrimitives.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Contracts/MilPrimitives.cs` |
| 66 | `src/WpfGfx.Linux/Contracts/Interfaces.cs` | 3 | 4852365 | 7021 | `fe354a4fac329226` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Contracts/Interfaces.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Contracts/Interfaces.cs` |
| 67 | `src/WpfGfx.Linux/Contracts/MilCmd.cs` | 3 | 4852366 | 8318 | `70ab5d1b195b6c57` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Contracts/MilCmd.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Contracts/MilCmd.cs` |
| 68 | `src/WpfGfx.Linux/Contracts/MilResourceType.cs` | 3 | 4852367 | 3095 | `998c90ac5303ee52` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Contracts/MilResourceType.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Contracts/MilResourceType.cs` |
| 69 | `src/WpfGfx.Linux/Contracts/MilDrawCommand.cs` | 3 | 4852368 | 1880 | `27b52f19b3f6ded0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Contracts/MilDrawCommand.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Contracts/MilDrawCommand.cs` |
| 70 | `tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` | 2 | 4852374 | 2683 | `04d9884234fc8c9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj` |
| 71 | `tests/WpfGfx.Linux.Tests/Commands.Tests/CommandLayoutTests.cs` | 2 | 4852375 | 16078 | `1344bd6810324aab` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/CommandLayoutTests.cs` |
| 72 | `tests/WpfGfx.Linux.Tests/Commands.Tests/TestChannel.cs` | 2 | 4852376 | 1752 | `9fae08c1cef5b65d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/TestChannel.cs` |
| 73 | `tests/WpfGfx.Linux.Tests/Commands.Tests/ChannelStateMachineTests.cs` | 2 | 4852378 | 17225 | `a8312603c5d3358b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/ChannelStateMachineTests.cs` |
| 74 | `tests/WpfGfx.Linux.Tests/Commands.Tests/CommandCoverageTests.cs` | 2 | 4852380 | 10443 | `50559c6143d61c22` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/CommandCoverageTests.cs` |
| 75 | `tests/WpfGfx.Linux.Tests/Commands.Tests/MatrixConventionTests.cs` | 2 | 4852381 | 8783 | `a9bcd8887a7fc8bf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/MatrixConventionTests.cs` |
| 76 | `tests/WpfGfx.Linux.Tests/Commands.Tests/Command3DTests.cs` | 2 | 4852382 | 30130 | `e156a4533ed0c82e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/Command3DTests.cs` |
| 77 | `tests/WpfGfx.Linux.Tests/Commands.Tests/MilBitmapSourceTests.cs` | 2 | 4852383 | 23864 | `539dec826b466cf0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/MilBitmapSourceTests.cs` |
| 78 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` | 2 | 4852385 | 3081 | `fa1abe39e5acf816` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj` |
| 79 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/RepoLayout.cs` | 2 | 4852386 | 2405 | `581c1c1c5c6f0bbc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/RepoLayout.cs` |
| 80 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenOptions.cs` | 2 | 4852387 | 2366 | `83c9529ab5d673f1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenOptions.cs` |
| 81 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/ImageComparer.cs` | 2 | 4852388 | 5707 | `e76dbca8f66d2b7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/ImageComparer.cs` |
| 82 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/PackagedFont.cs` | 2 | 4852389 | 4710 | `d9202d10a2975eb8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/PackagedFont.cs` |
| 83 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/RenderHarness.cs` | 2 | 4852390 | 5772 | `78df57ea6a4b971d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/RenderHarness.cs` |
| 84 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/PathGeometryBuilder.cs` | 2 | 4852392 | 6643 | `0734c8470705fca9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/PathGeometryBuilder.cs` |
| 85 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenRunner.cs` | 2 | 4852393 | 4846 | `a1885338eb755da1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/GoldenRunner.cs` |
| 86 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/update-golden.sh` | 2 | 4852395 | 958 | `aa05478eb1f91300` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/update-golden.sh` |
| 87 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/FontDeterminismTests.cs` | 2 | 4852397 | 2365 | `3bdb1676527a51c4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/FontDeterminismTests.cs` |
| 88 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/EffectTests.cs` | 2 | 4852398 | 23567 | `24f63857835c6896` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/EffectTests.cs` |
| 89 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/EffectGoldenTests.cs` | 2 | 4852399 | 12226 | `6f3f8f77f0a86e7a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/EffectGoldenTests.cs` |
| 90 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` | 2 | 4852401 | 3193 | `8bb5767bfde2339f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj` |
| 91 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/TestLayout.cs` | 2 | 4852402 | 3131 | `9dd2fe3941090f77` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/TestLayout.cs` |
| 92 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/GoldenImage.cs` | 2 | 4852403 | 7624 | `577c6476e066d814` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/GoldenImage.cs` |
| 93 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/X11Guard.cs` | 2 | 4852404 | 4878 | `1018de664e7ddfe2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/X11Guard.cs` |
| 94 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/X11ScreenCapture.cs` | 2 | 4852405 | 7372 | `c48ce9a31cc35432` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/X11ScreenCapture.cs` |
| 95 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh` | 2 | 4852406 | 1537 | `bc716d9a997b358f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh` |
| 96 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/GlyphRunHookTests.cs` | 2 | 4852408 | 7817 | `97bff633d8a5bc74` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/GlyphRunHookTests.cs` |
| 97 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/GlyphRunRenderTests.cs` | 2 | 4852409 | 13762 | `b96e4e5eaa0dc6fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/GlyphRunRenderTests.cs` |
| 98 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/TextDeterminismTests.cs` | 2 | 4852410 | 8212 | `a778c99e73c952d3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/TextDeterminismTests.cs` |
| 99 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/TextTestScene.cs` | 2 | 4852411 | 2530 | `c8b1b8593fcdd69b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Text/TextTestScene.cs` |
| 100 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11WindowTests.cs` | 2 | 4852413 | 7568 | `bb7c704f80bf4957` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11WindowTests.cs` |
| 101 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11PresentationTargetTests.cs` | 2 | 4852414 | 7752 | `0c41adcd608d6acf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11PresentationTargetTests.cs` |
| 102 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11RealInputEventTests.cs` | 2 | 4852415 | 13989 | `d54badd94875d29d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11RealInputEventTests.cs` |
| 103 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11DisplayOpenTests.cs` | 2 | 4852416 | 6786 | `eee4f88392ae99e7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/Windowing/X11DisplayOpenTests.cs` |
| 104 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_milglyphrun_hook.png` | 2 | 4852418 | 1647 | `8973b7d528c5065b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_milglyphrun_hook.png` |
| 105 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_bold_24.png` | 2 | 4852419 | 3280 | `87b7e68273e9b6a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_bold_24.png` |
| 106 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_baseline_shift.png` | 2 | 4852420 | 3247 | `8b40d64d5309c63c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_baseline_shift.png` |
| 107 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_regular_24.png` | 2 | 4852421 | 3247 | `79a35ecb42f37a7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_regular_24.png` |
| 108 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_italic_24.png` | 2 | 4852422 | 4344 | `f7fda1687a6ab8b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_italic_24.png` |
| 109 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_small_11.png` | 2 | 4852423 | 1546 | `c01a73fdfad26413` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/golden/text_small_11.png` |
| 110 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_milglyphrun_hook.png` | 2 | 4852425 | 1647 | `8973b7d528c5065b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_milglyphrun_hook.png` |
| 111 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_bold_24.png` | 2 | 4852426 | 3280 | `87b7e68273e9b6a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_bold_24.png` |
| 112 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_baseline_shift.png` | 2 | 4852427 | 3247 | `8b40d64d5309c63c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_baseline_shift.png` |
| 113 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_regular_24.png` | 2 | 4852428 | 3247 | `79a35ecb42f37a7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_regular_24.png` |
| 114 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_italic_24.png` | 2 | 4852429 | 4344 | `f7fda1687a6ab8b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_italic_24.png` |
| 115 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_small_11.png` | 2 | 4852430 | 1546 | `c01a73fdfad26413` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/text_small_11.png` |
| 116 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/x11_present_capture.png` | 2 | 4852431 | 2680 | `555fb58686d8cf70` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/artifacts/x11_present_capture.png` |
| 117 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/X11InputInjector.cs` | 2 | 4852432 | 6249 | `1ec3f6a723518a1d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/X11InputInjector.cs` |
| 118 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` | 2 | 4852434 | 3264 | `354e8d1f636870d2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj` |
| 119 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilEndToEnd.cs` | 2 | 4852437 | 3437 | `a207397717c15ce7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilEndToEnd.cs` |
| 120 | `tests/fonts/NotoSans-BoldItalic.ttf` | 2 | 4852440 | 441936 | `3d367743f371f286` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/fonts/NotoSans-BoldItalic.ttf` |
| 121 | `tests/fonts/NotoSans-Bold.ttf` | 2 | 4852441 | 432376 | `87cb2d84472a7d66` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/fonts/NotoSans-Bold.ttf` |
| 122 | `tests/fonts/NotoSans-Italic.ttf` | 2 | 4852442 | 446880 | `678288f868807d4d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/fonts/NotoSans-Italic.ttf` |
| 123 | `tests/fonts/NotoSans-Regular.ttf` | 2 | 4852443 | 431364 | `f3961a9cde016d41` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/fonts/NotoSans-Regular.ttf` |
| 124 | `tests/golden/dash_stroke.png` | 2 | 4852445 | 1034 | `c7f8b2adb961b02f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/dash_stroke.png` |
| 125 | `tests/golden/solid_rectangle.png` | 2 | 4852446 | 746 | `b8554c5fdaf315bc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/solid_rectangle.png` |
| 126 | `tests/golden/radial_gradient.png` | 2 | 4852447 | 14823 | `9f760d2d540194c6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/radial_gradient.png` |
| 127 | `tests/golden/animate_static_end_value.png` | 2 | 4852448 | 2509 | `0acc72cbb849b45a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/animate_static_end_value.png` |
| 128 | `tests/golden/linear_gradient.png` | 2 | 4852449 | 1782 | `b0acb3e3fda859c0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/linear_gradient.png` |
| 129 | `tests/golden/clip_path.png` | 2 | 4852450 | 1797 | `41fa6c125349f773` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/clip_path.png` |
| 130 | `tests/golden/opacity.png` | 2 | 4852451 | 734 | `455dfdfc525525ec` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/opacity.png` |
| 131 | `tests/golden/ellipse_fill_and_stroke.png` | 2 | 4852452 | 5333 | `e5dc29667e5bf976` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/ellipse_fill_and_stroke.png` |
| 132 | `tests/golden/transform_nested.png` | 2 | 4852453 | 5194 | `d49197944fbfd71a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/transform_nested.png` |
| 133 | `tests/golden/rounded_rectangle.png` | 2 | 4852454 | 3668 | `f609501e8ccb7dc9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/rounded_rectangle.png` |
| 134 | `tests/golden/clip_rect.png` | 2 | 4852455 | 755 | `934a4dc6f1a43de9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/clip_rect.png` |
| 135 | `tests/golden/path_geometry.png` | 2 | 4852456 | 6849 | `f41b4557eb6193e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/path_geometry.png` |
| 136 | `tests/golden/effect_blur_clipped.png` | 2 | 4852457 | 9668 | `b8fe036d66a0c3c1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/effect_blur_clipped.png` |
| 137 | `tests/golden/effect_drop_shadow.png` | 2 | 4852458 | 2809 | `5d40edf7d5e9f970` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/effect_drop_shadow.png` |
| 138 | `tests/golden/effect_blur.png` | 2 | 4852459 | 11889 | `82f442c54e6b2032` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/effect_blur.png` |
| 139 | `tests/artifacts/rendering/dash_stroke.png` | 2 | 4852462 | 1034 | `c7f8b2adb961b02f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/dash_stroke.png` |
| 140 | `tests/artifacts/rendering/solid_rectangle.png` | 2 | 4852463 | 746 | `b8554c5fdaf315bc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/solid_rectangle.png` |
| 141 | `tests/artifacts/rendering/radial_gradient.png` | 2 | 4852464 | 14823 | `9f760d2d540194c6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/radial_gradient.png` |
| 142 | `tests/artifacts/rendering/animate_static_end_value.png` | 2 | 4852465 | 2509 | `0acc72cbb849b45a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/animate_static_end_value.png` |
| 143 | `tests/artifacts/rendering/linear_gradient.png` | 2 | 4852466 | 1782 | `b0acb3e3fda859c0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/linear_gradient.png` |
| 144 | `tests/artifacts/rendering/clip_path.png` | 2 | 4852467 | 1797 | `41fa6c125349f773` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/clip_path.png` |
| 145 | `tests/artifacts/rendering/opacity.png` | 2 | 4852468 | 734 | `455dfdfc525525ec` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/opacity.png` |
| 146 | `tests/artifacts/rendering/ellipse_fill_and_stroke.png` | 2 | 4852469 | 5333 | `e5dc29667e5bf976` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/ellipse_fill_and_stroke.png` |
| 147 | `tests/artifacts/rendering/transform_nested.png` | 2 | 4852470 | 5194 | `d49197944fbfd71a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/transform_nested.png` |
| 148 | `tests/artifacts/rendering/rounded_rectangle.png` | 2 | 4852471 | 3668 | `f609501e8ccb7dc9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/rounded_rectangle.png` |
| 149 | `tests/artifacts/rendering/clip_rect.png` | 2 | 4852472 | 755 | `934a4dc6f1a43de9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/clip_rect.png` |
| 150 | `tests/artifacts/rendering/path_geometry.png` | 2 | 4852473 | 6849 | `f41b4557eb6193e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/path_geometry.png` |
| 151 | `tests/artifacts/rendering/effect_blur_clipped.png` | 2 | 4852474 | 9668 | `b8fe036d66a0c3c1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/effect_blur_clipped.png` |
| 152 | `tests/artifacts/rendering/effect_drop_shadow.png` | 2 | 4852475 | 2809 | `5d40edf7d5e9f970` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/effect_drop_shadow.png` |
| 153 | `tests/artifacts/rendering/effect_blur.png` | 2 | 4852476 | 11889 | `82f442c54e6b2032` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/effect_blur.png` |
| 154 | `tests/flaky-loop.sh` | 2 | 4852477 | 2879 | `ba37185c05a0dc7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/flaky-loop.sh` |
| 155 | `samples/HelloWpf/App.xaml` | 2 | 4852480 | 621 | `a9fabe795e809318` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloWpf/App.xaml` |
| 156 | `samples/HelloWpf/App.xaml.cs` | 2 | 4852481 | 298 | `d1fe7d4405196e5f` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloWpf/App.xaml.cs` |
| 157 | `samples/HelloWpf/MainWindow.xaml.cs` | 2 | 4852482 | 394 | `e08b66df42e13ae9` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloWpf/MainWindow.xaml.cs` |
| 158 | `samples/HelloWpf/MainWindow.xaml` | 2 | 4852483 | 2788 | `6e48db45858f20bd` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloWpf/MainWindow.xaml` |
| 159 | `samples/HelloMil/HelloMil.csproj` | 2 | 4852486 | 2686 | `8aafe53a0c6eed14` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/HelloMil.csproj` |
| 160 | `samples/HelloMil/HelloMilPaths.cs` | 2 | 4852487 | 4309 | `e893a18ec69fb0e9` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/HelloMilPaths.cs` |
| 161 | `samples/HelloMil/HelloMilScreenshot.cs` | 2 | 4852488 | 4345 | `1b78e18222abc0a9` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/HelloMilScreenshot.cs` |
| 162 | `samples/HelloMil/screenshot.png` | 2 | 4852489 | 58776 | `f98815e51929704b` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/screenshot.png` |
| 163 | `samples/HelloMil/PathGeometryBuilder.cs` | 2 | 4852490 | 5521 | `93625434411fca69` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/PathGeometryBuilder.cs` |
| 164 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilTests.cs` | 2 | 4852491 | 36962 | `8367a97e2b8e1166` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilTests.cs` |
| 165 | `samples/HelloMil/Program.cs` | 2 | 4852492 | 8387 | `8ccfea9a3353192d` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/Program.cs` |
| 166 | `global.json` | 2 | 4852493 | 111 | `49307341ea4847e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/global.json` |
| 167 | `tests/parity/linux/actual/scene14_combine_union_xor.png` | 2 | 4852494 | 8141 | `a5df3aeab11f72ba` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene14_combine_union_xor.png` |
| 168 | `build/MilBridge/W52A-report.md` | 2 | 4852496 | 38180 | `540d897e8c0270ab` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W52A-report.md` |
| 169 | `build/MilBridge/W55A-report.md` | 2 | 4852498 | 37538 | `a8f5ce68c8f92010` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W55A-report.md` |
| 170 | `src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py` | 3 | 4852512 | 17853 | `e0e1966593fdde89` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py` |
| 171 | `build/WindowsBase.Linux/DispatcherSynchronizationContext.Linux.cs` | 2 | 4852523 | 7237 | `c96e768c84026759` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/DispatcherSynchronizationContext.Linux.cs` |
| 172 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-focus-wait.cpython-310.pyc` | 2 | 4852531 | 16443 | `dec6615d4343399c` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-focus-wait.cpython-310.pyc` |
| 173 | `README-Window.md` | 2 | 4852542 | 6547 | `ba1c9456d0821393` | 是（1 条） | `/home/links-dev/w62a/negrepo/README-Window.md` |
| 174 | `build/shims/PresentationCore.HbTextLine.cs` | 2 | 4852544 | 293165 | `921ba9c65e9fb3be` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationCore.HbTextLine.cs` |
| 175 | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` | 2 | 4852579 | 78950 | `17f251a6d382dd42` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` |
| 176 | `build/MilBridge/W58A-report.md` | 2 | 4852585 | 28821 | `78ad9a9d7b5ad5ff` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W58A-report.md` |
| 177 | `tests/golden/drawing_brush_tile_repeat.png` | 2 | 4861249 | 1110 | `3a0d0e3363784d61` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_tile_repeat.png` |
| 178 | `build/wave-audit.log` | 2 | 4861272 | 70565 | `ac3722da2e1fac5f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/wave-audit.log` |
| 179 | `tests/parity/linux/diff/scene07_opacity.diff.png` | 2 | 4861320 | 2632 | `9091941e8c6e4b17` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene07_opacity.diff.png` |
| 180 | `src/WpfGfx.Linux/Interop/MilNative.Media.cs` | 3 | 4861362 | 6916 | `2f81aad31d342213` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Media.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Media.cs` |
| 181 | `tools/GeometryOracle/GeometryOracle.csproj` | 2 | 4865683 | 1424 | `42914ece1a1d74d4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tools/GeometryOracle/GeometryOracle.csproj` |
| 182 | `tests/WpfGfx.Linux.Tests/Commands.Tests/MilExportTests.cs` | 2 | 4865685 | 105142 | `3b55d060e29bb28c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/MilExportTests.cs` |
| 183 | `tests/artifacts/rendering/drawing_brush_tile_repeat.png` | 2 | 4865689 | 1110 | `3a0d0e3363784d61` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_repeat.png` |
| 184 | `build/PresentationCore.Linux/FontCacheUtil.Linux.cs` | 2 | 4865706 | 39066 | `b7a5621f00aad1cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/FontCacheUtil.Linux.cs` |
| 185 | `tests/parity/geometry/harness/LinuxGeometryRunner.cs` | 2 | 4865717 | 23304 | `2d1607125bb45bbe` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/harness/LinuxGeometryRunner.cs` |
| 186 | `build/DirectWriteForwarder.Linux/ManagedSurface.cs` | 2 | 4865955 | 66491 | `80627fe4a6eb8075` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWriteForwarder.Linux/ManagedSurface.cs` |
| 187 | `build/PresentationCore.Linux/HwndSource.Linux.cs` | 2 | 4865984 | 144768 | `4b88cb1be27d41b5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/HwndSource.Linux.cs` |
| 188 | `tests/golden/drawing_brush_tile_flipy.png` | 2 | 4865991 | 1041 | `0a22f5e4dc0e7171` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_tile_flipy.png` |
| 189 | `tests/golden/drawing_brush_tile_none.png` | 2 | 4865996 | 881 | `a3425c12fa09a0b7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_tile_none.png` |
| 190 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-securityzone.py` | 3 | 4866003 | 14393 | `131bd986945b71e8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-securityzone.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-securityzone.py` |
| 191 | `tests/golden/drawing_brush_tile_flipx.png` | 2 | 4866006 | 1124 | `dd98b1ab50506b49` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_tile_flipx.png` |
| 192 | `build/PresentationCore.Linux/InputManager.Linux.cs` | 2 | 4866047 | 42892 | `70a5d54ba859fdd7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/InputManager.Linux.cs` |
| 193 | `tests/golden/drawing_brush_brush_transform.png` | 2 | 4866064 | 3402 | `9a4c76fc8f8afd7f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_brush_transform.png` |
| 194 | `tests/parity/windows/streams/u1b-scenes-rtb-reldefer-variant.stream` | 2 | 4866102 | 46807 | `ff98b119db57aca1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1b-scenes-rtb-reldefer-variant.stream` |
| 195 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/NotDrawnSummaryTests.cs` | 2 | 4866105 | 3073 | `efa8f3a4faee4aa3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/NotDrawnSummaryTests.cs` |
| 196 | `build/PresentationCore.Linux/OleServicesContext.Linux.cs` | 2 | 4866139 | 9566 | `91077d36783d221c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/OleServicesContext.Linux.cs` |
| 197 | `build/PresentationCore.Linux/SecurityHelper.Linux.cs` | 2 | 4866145 | 7965 | `04b64eaaf77572ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/SecurityHelper.Linux.cs` |
| 198 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-textbox-textdp-trace.cpython-310.pyc` | 2 | 4866151 | 35647 | `38c9ce26022a34b1` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-textbox-textdp-trace.cpython-310.pyc` |
| 199 | `build/UIAutomationProvider.Linux/SR.g.cs` | 2 | 4866176 | 1241 | `86974dbbcef68328` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationProvider.Linux/SR.g.cs` |
| 200 | `tests/U1-golden/README.md` | 2 | 4866187 | 1594 | `3554377a8d0ef915` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/U1-golden/README.md` |
| 201 | `build/System.Windows.Input.Manipulations.Linux/SR.g.cs` | 2 | 4866201 | 2996 | `3a05deaf3f3dcf2b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Input.Manipulations.Linux/SR.g.cs` |
| 202 | `build/PresentationCore.Linux/FamilyCollection.Linux.cs` | 2 | 4866207 | 102630 | `19a42240f59af073` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/FamilyCollection.Linux.cs` |
| 203 | `build/WindowsBase.Linux/Dispatcher.Linux.cs` | 2 | 4866212 | 131416 | `ec8259ed4c14fd3a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/Dispatcher.Linux.cs` |
| 204 | `build/PresentationCore.Linux/MimeTypeMapper.Linux.cs` | 2 | 4866221 | 11210 | `d816fd8379184813` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/MimeTypeMapper.Linux.cs` |
| 205 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-swe-linux.cpython-310.pyc` | 2 | 4866241 | 9648 | `5fdc4246683f420f` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-swe-linux.cpython-310.pyc` |
| 206 | `build/System.Windows.Input.Manipulations.Linux/System.Windows.Input.Manipulations.Linux.csproj` | 2 | 4866258 | 6128 | `3200fcc669377fc6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Input.Manipulations.Linux/System.Windows.Input.Manipulations.Linux.csproj` |
| 207 | `build/System.Windows.Input.Manipulations.Linux/PORT-CHANGES.md` | 2 | 4866265 | 708 | `f3fe3d8bb9e17821` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Input.Manipulations.Linux/PORT-CHANGES.md` |
| 208 | `tests/artifacts/rendering/drawing_brush_tile_flipy.png` | 2 | 4866271 | 1041 | `0a22f5e4dc0e7171` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_flipy.png` |
| 209 | `build/PresentationCore.Linux/SR.g.cs` | 2 | 4866285 | 125389 | `66cc785da6da9f87` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/SR.g.cs` |
| 210 | `build/UIAutomationTypes.Linux/SR.g.cs` | 2 | 4866287 | 6115 | `220aa0013406ce18` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationTypes.Linux/SR.g.cs` |
| 211 | `build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj` | 2 | 4866290 | 12411 | `cba4d8e076a19e9a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj` |
| 212 | `build/MilBridge/run.sh` | 5 | 4866304 | 16705 | `711f39f468f61cc8` | 是（4 条） | `/home/links-dev/w26d-G9/treeA/build/MilBridge/run.sh`<br>`/home/links-dev/w26d-G9/treeB/build/MilBridge/run.sh`<br>`/home/links-dev/w26d-G9/treeC/build/MilBridge/run.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/run.sh` |
| 213 | `build/UIAutomationTypes.Linux/PORT-CHANGES.md` | 2 | 4866307 | 675 | `605ccd0ed09148c4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationTypes.Linux/PORT-CHANGES.md` |
| 214 | `tests/artifacts/rendering/drawing_brush_tile_none.png` | 2 | 4866311 | 881 | `a3425c12fa09a0b7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_none.png` |
| 215 | `build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj` | 2 | 4866312 | 7734 | `9f7a4c820328058c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj` |
| 216 | `src/WpfGfx.Linux.Native/tools/__pycache__/check-shim-coverage.cpython-310.pyc` | 2 | 4866319 | 11551 | `9d31cc5f78a8eaf3` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/check-shim-coverage.cpython-310.pyc` |
| 217 | `build/UIAutomationProvider.Linux/PORT-CHANGES.md` | 2 | 4866329 | 677 | `19e7736eafc3add4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationProvider.Linux/PORT-CHANGES.md` |
| 218 | `build/MilBridge/W17C-report.md` | 2 | 4866331 | 48890 | `a6b0632b13d5b908` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W17C-report.md` |
| 219 | `tests/parity/windows/shaping/out-layout/dwrite-layout-oracle.txt` | 2 | 4866397 | 9717 | `ec4411e81c2cf6b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-layout/dwrite-layout-oracle.txt` |
| 220 | `docs/m7c-accept-zero-probe.png` | 2 | 4866404 | 56055 | `f3e58d4bc6495149` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/m7c-accept-zero-probe.png` |
| 221 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-mimetype.cpython-310.pyc` | 2 | 4866411 | 18028 | `6d6e28bf49610b5a` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-mimetype.cpython-310.pyc` |
| 222 | `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py` | 2 | 4866416 | 11824 | `b07cce3f2e7cf51a` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/check-shim-coverage.py` |
| 223 | `tests/artifacts/rendering/drawing_brush_tile_flipx.png` | 2 | 4866433 | 1124 | `dd98b1ab50506b49` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_flipx.png` |
| 224 | `build/MilBridge/tools/__pycache__/t1c-trace-args-scope.cpython-310.pyc` | 2 | 4866444 | 13022 | `04477f055e7034f2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/__pycache__/t1c-trace-args-scope.cpython-310.pyc` |
| 225 | `samples/WpfTextDemo/MainWindow.xaml` | 2 | 4866449 | 14282 | `a04dc85945f25aa1` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/MainWindow.xaml` |
| 226 | `samples/WpfTextDemo/MainWindow.xaml.cs` | 2 | 4866468 | 34763 | `8de0d59fbdf628da` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/MainWindow.xaml.cs` |
| 227 | `tests/artifacts/rendering/linear_gradient.diff.png` | 2 | 4866471 | 764 | `51b9a441babff404` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/linear_gradient.diff.png` |
| 228 | `docs/U2-M7b-patch-round-report.md` | 2 | 4866544 | 23255 | `625b122658f6d06d` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-M7b-patch-round-report.md` |
| 229 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-registry.cpython-310.pyc` | 2 | 4866549 | 16845 | `80755a4dbf4564fe` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-registry.cpython-310.pyc` |
| 230 | `tests/parity/linux/diff/scene15_combine_intersect_exclude.diff.png` | 2 | 4866581 | 3874 | `66697c85665e9f2a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene15_combine_intersect_exclude.diff.png` |
| 231 | `build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs` | 2 | 4866632 | 39106 | `f56e647e21c29ef0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs` |
| 232 | `src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py` | 3 | 4866648 | 11060 | `9bfffec10cf6936c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py` |
| 233 | `build/WindowsBase.Linux/HwndWrapper.Linux.cs` | 2 | 4866651 | 16508 | `0ab3046ec34ac844` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/HwndWrapper.Linux.cs` |
| 234 | `build/PresentationCore.Linux/PORT-CHANGES.md` | 2 | 4866655 | 1078 | `e5c3472efa7724ec` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/PORT-CHANGES.md` |
| 235 | `build/excludes/WindowsBase.txt` | 2 | 4866666 | 1011 | `66d8392a22e73edc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/excludes/WindowsBase.txt` |
| 236 | `docs/unimplemented.md` | 2 | 4866667 | 49144 | `66abdab7fc342cab` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/unimplemented.md` |
| 237 | `build/MilBridge/tools/__pycache__/pick-feat-line.cpython-310.pyc` | 2 | 4866675 | 7059 | `d94ea54d240b85fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/__pycache__/pick-feat-line.cpython-310.pyc` |
| 238 | `samples/WpfTextDemo/README.md` | 2 | 4866680 | 24735 | `c109dd580a7e262e` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/README.md` |
| 239 | `docs/U1a-parity-report.md` | 2 | 4866696 | 27193 | `68e0479fc54e2904` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U1a-parity-report.md` |
| 240 | `tests/parity/windows/scene01_solid.png` | 2 | 4866805 | 953 | `51bc78bc373b32c9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene01_solid.png` |
| 241 | `build/PresentationCore.Linux/InputProviderSite.Linux.cs` | 2 | 4866847 | 4354 | `3a079a8f23dbdc02` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/InputProviderSite.Linux.cs` |
| 242 | `build/PresentationFramework.Linux/TextEditorTyping.Linux.cs` | 2 | 4866855 | 111631 | `bb4f98dc236d5e25` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/TextEditorTyping.Linux.cs` |
| 243 | `docs/U1-command-stream-golden-plan.md` | 2 | 4866859 | 6797 | `f1fed16c0f66fd38` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U1-command-stream-golden-plan.md` |
| 244 | `build/PresentationFramework.Linux/TextContainer.Linux.cs` | 2 | 4866862 | 162952 | `2859b73dd347fd8b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/TextContainer.Linux.cs` |
| 245 | `src/WpfGfx.Linux/Rendering/VisualBrushSource.cs` | 3 | 4866878 | 9424 | `02bcafd23856699f` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/VisualBrushSource.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/VisualBrushSource.cs` |
| 246 | `build/PresentationFramework.Linux/TextBoxBase.Linux.cs` | 2 | 4866884 | 77427 | `a371e5b48b40447b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/TextBoxBase.Linux.cs` |
| 247 | `src/WpfGfx.Linux.Native/src/win32_unicode_tables.c` | 3 | 4866899 | 227003 | `046738b2c67d9d4a` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_unicode_tables.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_unicode_tables.c` |
| 248 | `build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs` | 2 | 4866905 | 26700 | `9854366f0ef5d747` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs` |
| 249 | `src/WpfGfx.Linux.Native/tests/queue_invariant.c` | 3 | 4866907 | 9406 | `dc82fb2fa74fb8ab` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tests/queue_invariant.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tests/queue_invariant.c` |
| 250 | `tests/artifacts/rendering/drawing_brush_brush_transform.png` | 2 | 4866922 | 3402 | `9a4c76fc8f8afd7f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_brush_transform.png` |
| 251 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py` | 3 | 4866924 | 44490 | `19a2e6cafba38627` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py` |
| 252 | `build/WindowsBase.Linux/DependencyObject.Linux.cs` | 2 | 4866944 | 184597 | `2985c671c57c7775` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/DependencyObject.Linux.cs` |
| 253 | `src/WpfGfx.Linux.Native/tools/patch-presentationframework-texteditor-trace.py` | 3 | 4866946 | 54192 | `f8dbac9ac4c5a5ea` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationframework-texteditor-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationframework-texteditor-trace.py` |
| 254 | `build/PresentationFramework.Linux/TextBox.Linux.cs` | 2 | 4866958 | 79003 | `6d769e8508f42b40` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/TextBox.Linux.cs` |
| 255 | `build/PresentationFramework.Linux/DeferredTextReference.Linux.cs` | 2 | 4866959 | 3805 | `6d508ccc41d0e07b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/DeferredTextReference.Linux.cs` |
| 256 | `build/MilBridge/tools/t1c-trace-args-scope.py` | 2 | 4866975 | 22695 | `35b68f03d8a54f71` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1c-trace-args-scope.py` |
| 257 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/DrawingBrushTests.cs` | 2 | 4867029 | 21633 | `277dffda49f74bd1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/DrawingBrushTests.cs` |
| 258 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/DrawInstructionCensusTests.cs` | 2 | 4867041 | 5918 | `8ab3c86c40cf2aac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/DrawInstructionCensusTests.cs` |
| 259 | `src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py` | 3 | 4867063 | 27454 | `c6cbd41cb29153fc` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py` |
| 260 | `build/shims/UIAutomationProvider.shims.txt` | 2 | 4867070 | 33 | `7387f01da2f2777b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/shims/UIAutomationProvider.shims.txt` |
| 261 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-olecontext.cpython-310.pyc` | 2 | 4867121 | 12176 | `a5a9ff31a8c21da0` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-olecontext.cpython-310.pyc` |
| 262 | `build/PresentationFramework.Linux/FrameworkElement.Linux.cs` | 2 | 4867140 | 292005 | `3af06981155e89aa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/FrameworkElement.Linux.cs` |
| 263 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-textservices.cpython-310.pyc` | 2 | 4867152 | 18472 | `018b972a71d71fe9` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-textservices.cpython-310.pyc` |
| 264 | `tests/parity/windows/shaping/out-cjk/dwrite-cjk-shaping-oracle.json` | 2 | 4867217 | 94739 | `393c231a16d9f4f8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-cjk/dwrite-cjk-shaping-oracle.json` |
| 265 | `tests/parity/windows/shaping/out-cjk/dwrite-cjk-shaping-oracle.txt` | 2 | 4867224 | 5981 | `ca6aa0cc0f1ac7b4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-cjk/dwrite-cjk-shaping-oracle.txt` |
| 266 | `tests/parity/windows/probe.json` | 2 | 4867225 | 11405 | `f074efbba32e9e3b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/probe.json` |
| 267 | `tests/parity/windows/shaping/out-cjk/cjk-comparison.json` | 2 | 4867227 | 34283 | `5db9b02e27f55430` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-cjk/cjk-comparison.json` |
| 268 | `tests/parity/windows/shaping/out-cjk/cjk-comparison.txt` | 2 | 4867229 | 2871 | `4c2a77f8c8a2945b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-cjk/cjk-comparison.txt` |
| 269 | `tests/parity/windows/shaping/src/CjkOracle/Interop.cs` | 2 | 4867250 | 7916 | `b1580222424e1350` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/CjkOracle/Interop.cs` |
| 270 | `tests/parity/windows/shaping/src/CjkOracle/Program.cs` | 2 | 4867251 | 13993 | `3d2e1eb48b47ed0c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/CjkOracle/Program.cs` |
| 271 | `tests/parity/windows/shaping/src/CjkOracle/CjkOracle.csproj` | 2 | 4867252 | 521 | `cbeadce8afbeab03` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/CjkOracle/CjkOracle.csproj` |
| 272 | `tests/parity/windows/shaping/src/CjkOracle/run.ps1` | 2 | 4867253 | 1678 | `e2fc90d071590b37` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/CjkOracle/run.ps1` |
| 273 | `tests/parity/linux/actual/scene03_ellipse.png` | 2 | 4867255 | 6348 | `be0ec05950cf3fb4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene03_ellipse.png` |
| 274 | `build/shims/WindowsWin32.Shim.cs` | 3 | 4867257 | 23855 | `3387fb7ce53ad117` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/WindowsWin32.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/WindowsWin32.Shim.cs` |
| 275 | `tests/parity/windows/shaping/src/CjkOracle/compare_cjk.py` | 2 | 4867258 | 3504 | `07c5dcfcecd2e9a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/CjkOracle/compare_cjk.py` |
| 276 | `tests/parity/windows/layout-b34/verify-report.txt` | 2 | 4867265 | 10269 | `2dd87487dd6919b3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/verify-report.txt` |
| 277 | `tests/parity/windows/layout-b34/src/LayoutOracle/Dumper.cs` | 2 | 4867280 | 5100 | `2ae774e3d8eefead` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/Dumper.cs` |
| 278 | `build/MilBridge/T1d-perline-dump.md` | 2 | 4867336 | 7664 | `d997a61707119018` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1d-perline-dump.md` |
| 279 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-mirror-trace.cpython-310.pyc` | 2 | 4867339 | 27287 | `e673ca81ff09bc4b` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-mirror-trace.cpython-310.pyc` |
| 280 | `tests/parity/windows/scene02_roundrect.png` | 2 | 4867480 | 2795 | `24c83a6d1ff4b785` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene02_roundrect.png` |
| 281 | `tests/parity/windows/scene03_ellipse.png` | 2 | 4867481 | 5416 | `74b948eefcb58a2d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene03_ellipse.png` |
| 282 | `build/shims/UIAutomationTypes.shims.txt` | 2 | 4867482 | 67 | `bda5abcfe9adac1a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/shims/UIAutomationTypes.shims.txt` |
| 283 | `tests/parity/windows/scenes.json` | 2 | 4867485 | 95485 | `c0af3ba69a12a3b7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scenes.json` |
| 284 | `tests/parity/windows/scene04_linear_gradient.png` | 2 | 4867490 | 2707 | `71d5696394a7e264` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene04_linear_gradient.png` |
| 285 | `tests/parity/windows/scene05_radial_gradient.png` | 2 | 4867510 | 28490 | `2ff98fe4ca1126c3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene05_radial_gradient.png` |
| 286 | `build/keys/WcpPublicKey.snk` | 2 | 4867512 | 160 | `6fe03f0bbe162b4b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/keys/WcpPublicKey.snk` |
| 287 | `tests/parity/windows/scene06_dash.png` | 2 | 4867513 | 1686 | `62ba3e8ecc453928` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene06_dash.png` |
| 288 | `tests/parity/windows/scene07_opacity.png` | 2 | 4867515 | 3327 | `3bcb947e59582d3d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene07_opacity.png` |
| 289 | `tests/parity/windows/scene08_clip_rect.png` | 2 | 4867517 | 986 | `de4c21f5da455fe8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene08_clip_rect.png` |
| 290 | `tests/parity/windows/scene09_clip_path_fillrule.png` | 2 | 4867520 | 14439 | `376bc8f095e3c9a5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene09_clip_path_fillrule.png` |
| 291 | `tests/parity/windows/scene10_transform.png` | 2 | 4867521 | 6131 | `8be2d0c592de151f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene10_transform.png` |
| 292 | `tests/parity/windows/scene11_arc_sweep_large.png` | 2 | 4867522 | 8267 | `b0e61edac3b2eace` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene11_arc_sweep_large.png` |
| 293 | `tests/parity/windows/scene12_arc_ellipse.png` | 2 | 4867526 | 4917 | `d535f6e7e4c12b84` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene12_arc_ellipse.png` |
| 294 | `tests/parity/windows/scene13_arc_degenerate.png` | 2 | 4867527 | 5089 | `7854738241745219` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene13_arc_degenerate.png` |
| 295 | `tests/parity/windows/shaping/out-layout/kinsoku-table.json` | 2 | 4867550 | 16970 | `96d9b5a2f0250bf7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-layout/kinsoku-table.json` |
| 296 | `tests/parity/windows/scene14_combine_union_xor.png` | 2 | 4867563 | 7296 | `5f22bdf95227d91b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene14_combine_union_xor.png` |
| 297 | `tests/golden/drawing_brush_group_transform.png` | 2 | 4867588 | 864 | `592d44a0ebab6f1b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_group_transform.png` |
| 298 | `tests/golden/drawing_brush_group_opacity_mask.png` | 2 | 4867589 | 882 | `b77c1fcd9eea43b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/golden/drawing_brush_group_opacity_mask.png` |
| 299 | `tests/parity/windows/shaping/out-layout/dwrite-layout-oracle.json` | 2 | 4867595 | 43118 | `34e2b7d6ed23a184` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-layout/dwrite-layout-oracle.json` |
| 300 | `tests/parity/windows/scene15_combine_intersect_exclude.png` | 2 | 4871411 | 5779 | `41e392e2ce2771cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/scene15_combine_intersect_exclude.png` |
| 301 | `build/WindowsBase.Linux/WindowsBase.Linux.csproj` | 2 | 4872571 | 50251 | `f92471498f3bd7a5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/WindowsBase.Linux.csproj` |
| 302 | `tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py` | 2 | 4886251 | 4945 | `a0a64d89c10594f7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/tools/verify-cmd-layout.py` |
| 303 | `tests/artifacts/rendering/drawing_brush_group_transform.png` | 2 | 4886263 | 864 | `592d44a0ebab6f1b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_group_transform.png` |
| 304 | `tests/artifacts/rendering/drawing_brush_group_opacity_mask.png` | 2 | 4886265 | 882 | `b77c1fcd9eea43b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_group_opacity_mask.png` |
| 305 | `tests/parity/windows/verify_u1a_data.py` | 2 | 4886267 | 3018 | `3e651a359af839ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/verify_u1a_data.py` |
| 306 | `build/PresentationBuildTasks.Linux/PresentationBuildTasks.Linux.csproj` | 2 | 4886294 | 20229 | `1c3447aeb1bf1bb0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationBuildTasks.Linux/PresentationBuildTasks.Linux.csproj` |
| 307 | `build/PresentationBuildTasks.Linux/Directory.Build.props` | 2 | 4886295 | 939 | `27018e91c370b6cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationBuildTasks.Linux/Directory.Build.props` |
| 308 | `tests/parity/windows/shaping/src/LayoutOracle/Com.cs` | 2 | 4887175 | 12789 | `bc58513d2becf0e6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/Com.cs` |
| 309 | `tests/parity/windows/shaping/src/LayoutOracle/Dw.cs` | 2 | 4887177 | 10216 | `d8e647c2a50c5c24` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/Dw.cs` |
| 310 | `tests/parity/windows/shaping/src/LayoutOracle/Program.cs` | 2 | 4887189 | 14134 | `2ce3c57385288b0a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/Program.cs` |
| 311 | `tests/parity/windows/shaping/src/LayoutOracle/LayoutOracle.csproj` | 2 | 4887230 | 527 | `72fb5b3c41effdd7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/LayoutOracle.csproj` |
| 312 | `tests/parity/windows/shaping/src/LayoutOracle/run.ps1` | 2 | 4887480 | 801 | `c5e07c3bc23343c7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/run.ps1` |
| 313 | `tests/parity/linux/README.md` | 2 | 4887589 | 2054 | `59a54df0c5b1e768` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/README.md` |
| 314 | `tests/U1-golden/PROVENANCE.md` | 2 | 4887592 | 4620 | `f2bbcfff03ff24d2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/U1-golden/PROVENANCE.md` |
| 315 | `tests/parity/windows/layout-b34/src/LayoutOracle/Cases.cs` | 2 | 4887650 | 26179 | `5b8d2be897e420b1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/Cases.cs` |
| 316 | `build/shims/LinuxAssemblyIdentity.cs` | 3 | 4887764 | 2200 | `693b56ac590ef85d` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/LinuxAssemblyIdentity.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/LinuxAssemblyIdentity.cs` |
| 317 | `build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj` | 2 | 4887831 | 5879 | `0d29a4d9bd5e21b4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj` |
| 318 | `build/System.Xaml.Linux/System.Xaml.Linux.csproj` | 2 | 4888109 | 26731 | `df23abff67a39982` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Xaml.Linux/System.Xaml.Linux.csproj` |
| 319 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilProbe.cs` | 2 | 4888112 | 3375 | `68ff4a35c3edaf08` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMilProbe.cs` |
| 320 | `src/WpfGfx.Linux/Interop/AssemblyInfo.cs` | 3 | 4888113 | 2212 | `9eeebbae355972c8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/AssemblyInfo.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/AssemblyInfo.cs` |
| 321 | `tests/parity/linux/diff/scene03_ellipse.diff.png` | 2 | 4888153 | 3371 | `677ab1f66e6d0f38` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene03_ellipse.diff.png` |
| 322 | `build/DirectWriteForwarder.Linux/AssemblyAttrs.cs` | 2 | 4888642 | 1049 | `793fac11e94bb910` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWriteForwarder.Linux/AssemblyAttrs.cs` |
| 323 | `samples/HelloMil/TestScene.cs` | 2 | 4888645 | 46574 | `5399e9c5d78c1895` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloMil/TestScene.cs` |
| 324 | `tests/parity/windows/layout-b34/cases.json` | 2 | 4888655 | 800499 | `597b99158285befc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/cases.json` |
| 325 | `build/Directory.Upstream.props` | 2 | 4888702 | 10756 | `61f3d6cf1f880f29` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/Directory.Upstream.props` |
| 326 | `build/shims/PresentationCore.AssemblyAttrs.cs` | 3 | 4888712 | 1378 | `fa0137aea3c4acde` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationCore.AssemblyAttrs.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationCore.AssemblyAttrs.cs` |
| 327 | `build/fonts/LICENSE-OFL.txt` | 2 | 4888714 | 4377 | `0dab92d0544f7b23` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/LICENSE-OFL.txt` |
| 328 | `build/PresentationFramework.Linux/SR.g.cs` | 2 | 4888729 | 233813 | `7f27cbcfa50ca41f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/SR.g.cs` |
| 329 | `docs/U2-PresentationCore-prep.md` | 2 | 4888757 | 49057 | `5a57e63c551f87f0` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-PresentationCore-prep.md` |
| 330 | `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | 2 | 4888759 | 207241 | `e22a7457dc4a8010` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` |
| 331 | `src/WpfGfx.Linux.Native/tools/__pycache__/gen-unicode-tables.cpython-310.pyc` | 2 | 4888760 | 17541 | `dc922813feb792cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/gen-unicode-tables.cpython-310.pyc` |
| 332 | `build/PresentationFramework.Linux/PORT-CHANGES.md` | 2 | 4888761 | 827 | `c08adb7a0ba9fa78` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/PORT-CHANGES.md` |
| 333 | `tests/artifacts/rendering/transform_nested.diff.png` | 2 | 4888765 | 3702 | `708a940a03f78c7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/transform_nested.diff.png` |
| 334 | `tests/artifacts/rendering/transform_nested.PREFIX-actual.png` | 2 | 4888799 | 5194 | `d49197944fbfd71a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/transform_nested.PREFIX-actual.png` |
| 335 | `tests/parity/linux/actual/scene08_clip_rect.png` | 2 | 4888957 | 944 | `98b3fea2d4fb0d5b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene08_clip_rect.png` |
| 336 | `build/SelfBuiltConfig.props` | 2 | 4888982 | 2194 | `25491b2c97b3dcb1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/SelfBuiltConfig.props` |
| 337 | `build/shims/WindowsBase.shims.txt` | 2 | 4888983 | 810 | `23a1fec326b3cd03` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/shims/WindowsBase.shims.txt` |
| 338 | `build/CycleStub.PresentationFramework.Linux/ApiSubset.cs` | 2 | 4888991 | 13699 | `7cbf63227e439540` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.PresentationFramework.Linux/ApiSubset.cs` |
| 339 | `build/CycleStub.ReachFramework.Linux/CycleStub.ReachFramework.Linux.csproj` | 2 | 4888992 | 4070 | `ac186b7d5ac930db` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.ReachFramework.Linux/CycleStub.ReachFramework.Linux.csproj` |
| 340 | `src/WpfGfx.Linux.Native/Makefile` | 2 | 4889016 | 2361 | `617390fc28976c6f` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/Makefile` |
| 341 | `build/CycleStub.ReachFramework.Linux/ApiSubset.cs` | 2 | 4889017 | 4876 | `9d02bb30ac7ea269` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.ReachFramework.Linux/ApiSubset.cs` |
| 342 | `build/CycleStub.PresentationFramework.Linux/CycleStub.PresentationFramework.Linux.csproj` | 2 | 4889028 | 5981 | `67576038c9dde5b5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.PresentationFramework.Linux/CycleStub.PresentationFramework.Linux.csproj` |
| 343 | `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs` | 3 | 4889055 | 44900 | `21221bf12e176e69` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs` |
| 344 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py` | 3 | 4889059 | 10460 | `00d0d8c22cb1a1db` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py` |
| 345 | `build/shims/PresentationCore.OleApi.Stubs.cs` | 3 | 4889060 | 19969 | `9e685cd9c69df69b` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationCore.OleApi.Stubs.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationCore.OleApi.Stubs.cs` |
| 346 | `tools/GeometryOracle/Program.cs` | 2 | 4889063 | 11122 | `cfa21d8c9404b53d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tools/GeometryOracle/Program.cs` |
| 347 | `build/ReachFramework.Linux/SR.g.cs` | 2 | 4889064 | 14555 | `9757df76790d14d9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/ReachFramework.Linux/SR.g.cs` |
| 348 | `tests/parity/linux/diff/scene01_solid.diff.png` | 2 | 4889067 | 931 | `91f559d56ac612ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene01_solid.diff.png` |
| 349 | `tests/parity/geometry/windows-harness/Program.cs` | 2 | 4889068 | 4747 | `6309b08d7fc40176` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/windows-harness/Program.cs` |
| 350 | `build/DirectWriteForwarder.Linux/NativeMirrors.cs` | 2 | 4889073 | 10194 | `8ac674e5df0248a5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWriteForwarder.Linux/NativeMirrors.cs` |
| 351 | `tests/parity/geometry/harness/CaseCatalog.cs` | 2 | 4889075 | 55397 | `4b3b456638507b56` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/harness/CaseCatalog.cs` |
| 352 | `docs/U2-PresentationFramework-prep.md` | 2 | 4889078 | 52487 | `fc0d03dc531217df` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-PresentationFramework-prep.md` |
| 353 | `tests/parity/geometry/windows-harness/GeometryOracle.Win.csproj` | 2 | 4889081 | 452 | `9d7bad84572f2d4a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/windows-harness/GeometryOracle.Win.csproj` |
| 354 | `tests/parity/geometry/harness/NativeGeometryRunner.cs` | 2 | 4889103 | 37531 | `d4705d371764d710` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/harness/NativeGeometryRunner.cs` |
| 355 | `build/shims/PresentationFramework.shims.txt` | 2 | 4889113 | 1097 | `4c2be063b8210d0d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/shims/PresentationFramework.shims.txt` |
| 356 | `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` | 3 | 4889118 | 4495 | `a76b6a7edd8bfd8a` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` |
| 357 | `build/shims/PresentationFramework.AssemblyAttrs.Shim.cs` | 3 | 4889121 | 2508 | `4429ff9a973a8375` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationFramework.AssemblyAttrs.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationFramework.AssemblyAttrs.Shim.cs` |
| 358 | `build/shims/PresentationCore.shims.txt` | 2 | 4889125 | 2397 | `e94786d6e2b11b5d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/shims/PresentationCore.shims.txt` |
| 359 | `build/WindowsBase.Linux/SecurityHelper.Linux.cs` | 2 | 4889134 | 9710 | `77568d3be60cdf67` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/SecurityHelper.Linux.cs` |
| 360 | `tests/parity/geometry/harness/GeometryRunner.cs` | 2 | 4889154 | 18839 | `a152d7bc7a1ab6e6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/harness/GeometryRunner.cs` |
| 361 | `tests/parity/geometry/show.py` | 2 | 4889156 | 3939 | `3fe9f61878ad5730` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/show.py` |
| 362 | `tests/parity/linux/actual/scene11_arc_sweep_large.png` | 2 | 4889181 | 7351 | `69c11ccac479ba8c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene11_arc_sweep_large.png` |
| 363 | `tests/parity/linux/actual/scene10_transform.png` | 2 | 4889182 | 5875 | `49156bd4c4edff78` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene10_transform.png` |
| 364 | `tests/parity/linux/actual/scene15_combine_intersect_exclude.png` | 2 | 4889185 | 6236 | `a200cc7660f8ad0c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene15_combine_intersect_exclude.png` |
| 365 | `tests/parity/linux/actual/scene06_dash.png` | 2 | 4889186 | 1056 | `40f484432f01a1cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene06_dash.png` |
| 366 | `build/excludes/PresentationCore.txt` | 2 | 4889187 | 14060 | `ef8f93f5b6373d47` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/excludes/PresentationCore.txt` |
| 367 | `tests/parity/linux/diff/scene14_combine_union_xor.diff.png` | 2 | 4889190 | 4303 | `2b81ca5d36c5846f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene14_combine_union_xor.diff.png` |
| 368 | `tests/parity/linux/diff/scene05_radial_gradient.diff.png` | 2 | 4889191 | 22208 | `44ac7974f045fd9b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene05_radial_gradient.diff.png` |
| 369 | `tests/parity/linux/actual/scene01_solid.png` | 2 | 4889192 | 923 | `3a8d4b6373fc3f51` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene01_solid.png` |
| 370 | `tests/parity/linux/actual/scene04_linear_gradient.png` | 2 | 4889194 | 2190 | `affb5717253357a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene04_linear_gradient.png` |
| 371 | `tests/parity/linux/diff/scene04_linear_gradient.diff.png` | 2 | 4889196 | 2665 | `e289c19db8fa969e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene04_linear_gradient.diff.png` |
| 372 | `wpf-linux.sln` | 2 | 4889198 | 4548 | `9d9c2625dda6a905` | 是（1 条） | `/home/links-dev/w62a/negrepo/wpf-linux.sln` |
| 373 | `tests/parity/linux/actual/scene02_roundrect.png` | 2 | 4889200 | 2597 | `81b333c14ae2e2ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene02_roundrect.png` |
| 374 | `tests/parity/linux/diff/scene09_clip_path_fillrule.diff.png` | 2 | 4889201 | 6778 | `b274e3046c19bebc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene09_clip_path_fillrule.diff.png` |
| 375 | `tests/parity/linux/diff/scene11_arc_sweep_large.diff.png` | 2 | 4889202 | 5471 | `d1710e3c0a7142a7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene11_arc_sweep_large.diff.png` |
| 376 | `tests/parity/linux/actual/scene05_radial_gradient.png` | 2 | 4889204 | 26314 | `682c45cc339c2fbd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene05_radial_gradient.png` |
| 377 | `tests/parity/linux/parity-results.json` | 2 | 4889206 | 41813 | `55d5b4179bace831` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/parity-results.json` |
| 378 | `tests/parity/linux/diff/scene08_clip_rect.diff.png` | 2 | 4889207 | 949 | `4d8565ccb346a51c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene08_clip_rect.diff.png` |
| 379 | `tests/parity/linux/diff/scene06_dash.diff.png` | 2 | 4889208 | 1234 | `53008a848ed69ad8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene06_dash.diff.png` |
| 380 | `tests/parity/linux/diff/scene02_roundrect.diff.png` | 2 | 4889210 | 2046 | `58d4f66cda44111e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene02_roundrect.diff.png` |
| 381 | `tests/parity/linux/actual/scene13_arc_degenerate.png` | 2 | 4889211 | 4693 | `bb9f5348ca330c27` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene13_arc_degenerate.png` |
| 382 | `tests/parity/linux/actual/scene07_opacity.png` | 2 | 4889212 | 3218 | `a007c8baad93ba31` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene07_opacity.png` |
| 383 | `tests/parity/linux/actual/scene09_clip_path_fillrule.png` | 2 | 4889222 | 11411 | `9abc0eb20cd2d366` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene09_clip_path_fillrule.png` |
| 384 | `tests/parity/geometry/cases.json` | 2 | 4889223 | 212548 | `f51cb675f83da8f3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/cases.json` |
| 385 | `tests/parity/geometry/linux-results.json` | 2 | 4889224 | 270817 | `912a607b107d4f84` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/linux-results.json` |
| 386 | `tests/parity/geometry/harness/GeometryCases.cs` | 2 | 4889226 | 18116 | `05b8dc32513b26a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/harness/GeometryCases.cs` |
| 387 | `build/ReachFramework.Linux/ReachFramework.Linux.csproj` | 2 | 4889227 | 46294 | `06b68dc09efcb013` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/ReachFramework.Linux/ReachFramework.Linux.csproj` |
| 388 | `build/ReachFramework.Linux/PORT-CHANGES.md` | 2 | 4889228 | 715 | `ca2cf77589a2a840` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/ReachFramework.Linux/PORT-CHANGES.md` |
| 389 | `build/CycleStub.PresentationUI.Linux/CycleStub.PresentationUI.Linux.csproj` | 2 | 4889237 | 5409 | `6871f9b1e375d053` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.PresentationUI.Linux/CycleStub.PresentationUI.Linux.csproj` |
| 390 | `build/shims/ReachFramework.AssemblyAttrs.Shim.cs` | 3 | 4889251 | 804 | `82abae0a2bd561ce` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/ReachFramework.AssemblyAttrs.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/ReachFramework.AssemblyAttrs.Shim.cs` |
| 391 | `build/CycleStub.PresentationUI.Linux/FindToolBar.ApiSubset.cs` | 2 | 4889254 | 6692 | `d79bc4c0c3747b31` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/CycleStub.PresentationUI.Linux/FindToolBar.ApiSubset.cs` |
| 392 | `build/System.Printing.Linux/System.Printing.Linux.csproj` | 2 | 4889259 | 6511 | `af864f692acf1009` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Printing.Linux/System.Printing.Linux.csproj` |
| 393 | `build/ReachFramework.Linux/reapply-patches.py` | 2 | 4889262 | 8659 | `c080755c8522c565` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/ReachFramework.Linux/reapply-patches.py` |
| 394 | `src/WpfGfx.Linux.Native/tools/wire-managed-layer.py` | 2 | 4889301 | 4586 | `dc5bea1bf220f295` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/wire-managed-layer.py` |
| 395 | `tests/parity/linux/diff/scene10_transform.diff.png` | 2 | 4889320 | 4043 | `50ba3ff05e499ce5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/diff/scene10_transform.diff.png` |
| 396 | `tests/parity/linux/actual/scene12_arc_ellipse.png` | 2 | 4889330 | 4282 | `23d0679b42584e51` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/linux/actual/scene12_arc_ellipse.png` |
| 397 | `tests/parity/geometry/windows-results.json` | 2 | 4889333 | 679826 | `2cd8d2322a9faec9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/windows-results.json` |
| 398 | `tests/parity/geometry/summary.json` | 2 | 4889336 | 229862 | `d7b745ec69e3059d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/summary.json` |
| 399 | `tests/parity/geometry/summary.md` | 2 | 4889337 | 78789 | `beb20a4afbbf6bc8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/summary.md` |
| 400 | `docs/history/U2-resource-pipeline-audit.md` | 2 | 4889385 | 19159 | `52116dad420716e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/history/U2-resource-pipeline-audit.md` |
| 401 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-compositefont.cpython-310.pyc` | 2 | 4889399 | 97661 | `fc37833bbbcfef8f` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-compositefont.cpython-310.pyc` |
| 402 | `src/WpfGfx.Linux/Interop/MilExportTypes.cs` | 3 | 4889415 | 17713 | `f879988be61d31f0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilExportTypes.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilExportTypes.cs` |
| 403 | `build/PresentationFramework.Linux/SystemResources.Linux.cs` | 2 | 4889424 | 86164 | `e62edb1f82ba753a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/SystemResources.Linux.cs` |
| 404 | `src/WpfGfx.Linux/Interop/MilNative.Geometry.cs` | 3 | 4889427 | 52900 | `463bbf98912da2f3` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Geometry.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Geometry.cs` |
| 405 | `build/MilBridge/spike/AotLib/Exports.cs` | 2 | 4889430 | 1268 | `cbd09bbca5975b96` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/spike/AotLib/Exports.cs` |
| 406 | `build/PresentationCore.Linux/resource-manifest.txt` | 2 | 4889433 | 1807 | `5e670cb1395bc063` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/resource-manifest.txt` |
| 407 | `src/WpfGfx.Linux.Native/src/win32_exports.c` | 3 | 4889435 | 18885 | `37c73c85ff263527` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_exports.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_exports.c` |
| 408 | `src/WpfGfx.Linux/Rendering/PathGeometryParser.cs` | 3 | 4889436 | 10994 | `9d6c1e87c50e15cd` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/PathGeometryParser.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/PathGeometryParser.cs` |
| 409 | `build/MilBridge/spike/AotLib/AotLib.csproj` | 2 | 4889438 | 1680 | `cf2b90f68f100b07` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/spike/AotLib/AotLib.csproj` |
| 410 | `src/WpfGfx.Linux.Native/tests/abi_layout.c` | 3 | 4889441 | 8907 | `932de9d7339c1dd1` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tests/abi_layout.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tests/abi_layout.c` |
| 411 | `tests/parity/windows/all-scenes-contact-sheet.png` | 2 | 4890584 | 52960 | `79a7740900f62ad0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/all-scenes-contact-sheet.png` |
| 412 | `build/MilBridge/tools/cprobe/probe.c` | 2 | 4890810 | 2086 | `cecab294ec651c5f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/cprobe/probe.c` |
| 413 | `src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py` | 2 | 4890824 | 23610 | `d8720e590f8c63a2` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py` |
| 414 | `docs/U2-M7b-win32-inventory.md` | 2 | 4890825 | 61734 | `984108886bb8bd9f` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-M7b-win32-inventory.md` |
| 415 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-registry.py` | 3 | 4890849 | 19154 | `f1a8f73ff9a4e1f8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-registry.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-registry.py` |
| 416 | `tests/U1-golden/u1b-scenes-rtb-raw.stream` | 2 | 4890940 | 46807 | `5fbe76be4626618e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/U1-golden/u1b-scenes-rtb-raw.stream` |
| 417 | `tests/WpfGfx.Linux.Tests/Commands.Tests/GoldenBinaryReplayTests.cs` | 2 | 4890945 | 10750 | `39c3a7b45dbadd3d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/GoldenBinaryReplayTests.cs` |
| 418 | `tests/artifacts/rendering/transform_nested.PREFIX-diff.png` | 2 | 4890966 | 3702 | `708a940a03f78c7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/transform_nested.PREFIX-diff.png` |
| 419 | `build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt` | 2 | 4890984 | 3776 | `f605fccc9b574c4f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt` |
| 420 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-lineheight-trace.cpython-310.pyc` | 2 | 4891014 | 17640 | `1c87b22e23244007` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-lineheight-trace.cpython-310.pyc` |
| 421 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-apartment.cpython-310.pyc` | 2 | 4891015 | 18518 | `4988f75c94287ace` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-apartment.cpython-310.pyc` |
| 422 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-fontcache.cpython-310.pyc` | 2 | 4891016 | 10182 | `bc4644386e775984` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-fontcache.cpython-310.pyc` |
| 423 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-securityzone.cpython-310.pyc` | 2 | 4891017 | 12337 | `c9c7d608d2bde00c` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-securityzone.cpython-310.pyc` |
| 424 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-xamlaccess.cpython-310.pyc` | 2 | 4891019 | 10357 | `8d2dedf8e3b85ecc` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-xamlaccess.cpython-310.pyc` |
| 425 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-uiautomationtypes-reservedvalue.cpython-310.pyc` | 2 | 4891020 | 11291 | `86dd709b20c730c2` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-uiautomationtypes-reservedvalue.cpython-310.pyc` |
| 426 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-shared-invariant-failfast.cpython-310.pyc` | 2 | 4891021 | 10615 | `54543d21a360f430` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-shared-invariant-failfast.cpython-310.pyc` |
| 427 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-shared-hwndwrapper-diag.cpython-310.pyc` | 2 | 4891022 | 10484 | `c215cd4dba7f6b23` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-shared-hwndwrapper-diag.cpython-310.pyc` |
| 428 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-hbtextline-shimsha.cpython-310.pyc` | 2 | 4891027 | 15349 | `80f7cfc53c0d02da` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-hbtextline-shimsha.cpython-310.pyc` |
| 429 | `tests/parity/windows/layout-b34/src/LayoutOracle/LayoutOracle.csproj` | 2 | 4891029 | 904 | `b3cd17768c1ebcc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/LayoutOracle.csproj` |
| 430 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-inputsite-trace.cpython-310.pyc` | 2 | 4891030 | 11000 | `df3295523bc5e9a1` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-inputsite-trace.cpython-310.pyc` |
| 431 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-texteditor-trace.cpython-310.pyc` | 2 | 4891031 | 52299 | `06eb4e54cf0bc7fb` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationframework-texteditor-trace.cpython-310.pyc` |
| 432 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-entry-flatten-trace.cpython-310.pyc` | 2 | 4891036 | 18186 | `f5a8a62557d2151e` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-entry-flatten-trace.cpython-310.pyc` |
| 433 | `build/MilBridge/tools/gen-exports.py` | 2 | 4891046 | 19225 | `4dee8d7e7607a79d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/gen-exports.py` |
| 434 | `build/check-appliers.sh` | 2 | 4891061 | 592 | `025d7f5148af36b9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/check-appliers.sh` |
| 435 | `src/WpfGfx.Linux.Native/src/win32_classification.c` | 3 | 4891065 | 13661 | `1e17b8331c2d3d73` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_classification.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_classification.c` |
| 436 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputsite-trace.py` | 3 | 4891066 | 11411 | `e257247a3dacdb6e` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputsite-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputsite-trace.py` |
| 437 | `src/WpfGfx.Linux.Native/tools/gen-unicode-tables.py` | 2 | 4891068 | 22138 | `29b826b7e1ad0300` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/gen-unicode-tables.py` |
| 438 | `src/WpfGfx.Linux.Native/src/win32_abi.h` | 3 | 4891070 | 24787 | `c02e0cb85eac59a8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_abi.h`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_abi.h` |
| 439 | `tests/WpfGfx.Linux.Tests/Commands.Tests/MilNativeTests.cs` | 2 | 4891074 | 19404 | `83888828b93ce5aa` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/MilNativeTests.cs` |
| 440 | `build/MilBridge/tools/check-mil-guids.py` | 2 | 4891078 | 4694 | `7987c1a557a5cfa1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/check-mil-guids.py` |
| 441 | `src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py` | 3 | 4891080 | 10370 | `8e694cf5cd187121` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py` |
| 442 | `build/MilBridge/tools/cprobe/README.txt` | 2 | 4891087 | 738 | `e0cccafd25e95268` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/cprobe/README.txt` |
| 443 | `samples/HelloWpf/HelloWpf.csproj` | 2 | 4891122 | 29343 | `9c0e683dc7481dcb` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/HelloWpf/HelloWpf.csproj` |
| 444 | `build/PresentationCore.Linux/StylusLogic.Linux.cs` | 2 | 4891152 | 31406 | `fd57318ade379427` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/StylusLogic.Linux.cs` |
| 445 | `docs/m7c-accept.png` | 2 | 4891156 | 46916 | `3db12fba00f51fdc` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/m7c-accept.png` |
| 446 | `build/PresentationCore.Linux/WispTabletDeviceCollection.Linux.cs` | 2 | 4891179 | 31480 | `18ef64f370306faf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/WispTabletDeviceCollection.Linux.cs` |
| 447 | `build/PresentationCore.Linux/TextCompositionManager.Linux.cs` | 2 | 4891180 | 43469 | `8c94b39877a62b52` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/TextCompositionManager.Linux.cs` |
| 448 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-olecontext.py` | 3 | 4891182 | 12566 | `13dac17d5a798f53` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-olecontext.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-olecontext.py` |
| 449 | `docs/U2-Themes-prep.md` | 2 | 4891190 | 17721 | `51ec51fc81815788` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-Themes-prep.md` |
| 450 | `docs/U2-M7c-report.md` | 2 | 4891196 | 241337 | `d3056cf1f5950ef9` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-M7c-report.md` |
| 451 | `tests/parity/windows/shaping/src/ShapingOracle.csproj` | 2 | 4891621 | 529 | `a862c22ef9c9b130` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/ShapingOracle.csproj` |
| 452 | `tests/parity/windows/shaping/src/Program.cs` | 2 | 4891622 | 16411 | `b680621768622b5c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/Program.cs` |
| 453 | `tests/parity/windows/shaping/src/Interop.cs` | 2 | 4891623 | 7312 | `c5a9e89b1615401a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/Interop.cs` |
| 454 | `tests/parity/windows/shaping/src/compare_hb.py` | 2 | 4891624 | 4050 | `d109fa0c228d6f7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/compare_hb.py` |
| 455 | `tests/parity/windows/shaping/src/generate.ps1` | 2 | 4891628 | 1818 | `5527b9185d3c8781` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/generate.ps1` |
| 456 | `tests/parity/windows/shaping/src/stab.ps1` | 2 | 4891632 | 1096 | `9a9c81dbc6d974f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/stab.ps1` |
| 457 | `tests/parity/windows/shaping/out/dwrite-shaping-oracle.json` | 2 | 4891633 | 187351 | `ba875d7c47a794f6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out/dwrite-shaping-oracle.json` |
| 458 | `tests/parity/windows/shaping/out/dwrite-shaping-oracle.txt` | 2 | 4891636 | 35919 | `427735de4b902bec` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out/dwrite-shaping-oracle.txt` |
| 459 | `tests/parity/windows/shaping/out/hb-comparison.json` | 2 | 4891637 | 88450 | `8dd6b200494d356c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out/hb-comparison.json` |
| 460 | `tests/parity/windows/shaping/out/hb-comparison.txt` | 2 | 4891638 | 4993 | `9afc6fd547df8dca` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out/hb-comparison.txt` |
| 461 | `tests/parity/windows/shaping/src/SDK_dwrite.h.reference` | 2 | 4891639 | 220303 | `e991bb9037949bb1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/SDK_dwrite.h.reference` |
| 462 | `tests/parity/windows/shaping/PROVENANCE.md` | 2 | 4891643 | 31237 | `dd9aa5e28dc34a68` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/PROVENANCE.md` |
| 463 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py` | 3 | 4891663 | 19680 | `0a52507b8acd350d` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py` |
| 464 | `src/WpfGfx.Linux.Native/tools/patch-windowsbase-entry-flatten-trace.py` | 3 | 4891664 | 19034 | `909df7198f6fafef` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-windowsbase-entry-flatten-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-windowsbase-entry-flatten-trace.py` |
| 465 | `build/MilBridge/T1d-bidi-decision.md` | 2 | 4891727 | 12541 | `83a6860ea6fb7086` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1d-bidi-decision.md` |
| 466 | `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` | 2 | 4891734 | 5219 | `e63b3c07056e2621` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` |
| 467 | `build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt` | 2 | 4891735 | 3237 | `ded67ae46fc205a8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt` |
| 468 | `tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json` | 2 | 4892512 | 265652 | `f6d47b5a844fbcdf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json` |
| 469 | `build/PresentationFramework.Linux/TextBlock.Linux.cs` | 2 | 4892523 | 180552 | `6067276d0fc3a8da` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Linux/TextBlock.Linux.cs` |
| 470 | `tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.txt` | 2 | 4892595 | 36799 | `34e8a977d0868194` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.txt` |
| 471 | `tests/parity/windows/layout-b34/evidence-cd2.md` | 2 | 4892690 | 5760 | `fa73b31729bc4f6c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/evidence-cd2.md` |
| 472 | `tests/parity/windows/layout-b34/cases-cd2.json` | 2 | 4892702 | 158409 | `cdd624dfa5814098` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/cases-cd2.json` |
| 473 | `tests/parity/windows/shaping/src/LayoutOracle/run2.ps1` | 2 | 4892747 | 1278 | `8ec90db92bf8e86b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/shaping/src/LayoutOracle/run2.ps1` |
| 474 | `tests/parity/windows/layout-b34/windows-results.json` | 2 | 4892802 | 57715362 | `dbd95d5af30c1899` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/windows-results.json` |
| 475 | `tests/parity/windows/layout-b34/src/LayoutOracle/Runner.cs` | 2 | 4893002 | 37794 | `5257f51f9900c9e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/Runner.cs` |
| 476 | `build/MilBridge/tools/t2d-extent-detail.sh` | 2 | 4893063 | 2295 | `8d8f6c4b6ae9d20b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t2d-extent-detail.sh` |
| 477 | `tests/parity/windows/layout-b34/results-cd2.json` | 2 | 4893072 | 5174412 | `78426638e7747a06` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/results-cd2.json` |
| 478 | `tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs` | 2 | 4893150 | 7901 | `1e0fa041caf90508` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs` |
| 479 | `tests/artifacts/rendering/drawing_brush_tile_flipy.diff.png` | 2 | 4893429 | 1263 | `02780ad696746e9e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_flipy.diff.png` |
| 480 | `tests/parity/windows/layout-b34/probe.json` | 2 | 4893507 | 26313 | `8c27e8b9c9ebe2e4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/probe.json` |
| 481 | `samples/WpfTextDemo/App.xaml.cs` | 2 | 4893512 | 515 | `406862c564e298e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/App.xaml.cs` |
| 482 | `samples/WpfTextDemo/App.xaml` | 2 | 4893527 | 549 | `4bfa793f166c1399` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/App.xaml` |
| 483 | `tests/artifacts/rendering/drawing_brush_tile_flipx.diff.png` | 2 | 4893536 | 1359 | `65af0af326d83450` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_flipx.diff.png` |
| 484 | `tests/parity/windows/layout-b34/verify.py` | 2 | 4893538 | 12792 | `50a35c65da974e68` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/verify.py` |
| 485 | `samples/WpfTextDemo/WpfTextDemo.csproj` | 2 | 4893541 | 14075 | `c407c660de4c1047` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WpfTextDemo.csproj` |
| 486 | `tests/parity/windows/layout-b34/evidence-cd1.md` | 2 | 4893555 | 13384 | `6784c0830ef87aa1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/evidence-cd1.md` |
| 487 | `build/MilBridge/tools/t1b-ls-selftest` | 2 | 4893641 | 16408 | `9887a6ddde5a6024` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1b-ls-selftest` |
| 488 | `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs` | 2 | 4893680 | 6204 | `23240b70aaddc2c9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs` |
| 489 | `tests/parity/windows/layout-b34/cases-cd1.json` | 2 | 4893682 | 280075 | `c6c1c2165db4190c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/cases-cd1.json` |
| 490 | `tests/parity/windows/layout-b34/results-cd1.json` | 2 | 4893686 | 9505240 | `57145faed26d39e0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/results-cd1.json` |
| 491 | `tests/artifacts/rendering/drawing_brush_brush_transform.diff.png` | 2 | 4893704 | 4994 | `9d87808997005513` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_brush_transform.diff.png` |
| 492 | `tests/artifacts/rendering/image_brush.diff.png` | 2 | 4893714 | 1806 | `c4df7c3d91b380cf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/image_brush.diff.png` |
| 493 | `tests/artifacts/rendering/drawing_brush_tile_repeat.diff.png` | 2 | 4893719 | 1164 | `ea338abf3e65f2c8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/artifacts/rendering/drawing_brush_tile_repeat.diff.png` |
| 494 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | 2 | 4893885 | 69432 | `fa058b134c64e068` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/TextFormatterImp.Linux.cs` |
| 495 | `build/MilBridge/tools/t1b-d3-acceptance.sh` | 2 | 4893942 | 4907 | `fc605260ae947eb2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1b-d3-acceptance.sh` |
| 496 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/TransformProvenanceTests.cs` | 2 | 4893969 | 6361 | `18d76a9aadca2bdd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/TransformProvenanceTests.cs` |
| 497 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` | 3 | 4894059 | 100096 | `3610e096981daab8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py` |
| 498 | `src/WpfGfx.Linux/Text/GlyphFaceCensus.cs` | 3 | 4894092 | 11357 | `765fbc25fce06a9c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/GlyphFaceCensus.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/GlyphFaceCensus.cs` |
| 499 | `build/PresentationCore.Linux/SimpleTextLine.Linux.cs` | 2 | 4894937 | 82727 | `5f729e403fc6c7b1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/SimpleTextLine.Linux.cs` |
| 500 | `build/WindowsBase.Linux/Invariant.Linux.cs` | 2 | 4894968 | 11754 | `d0a35feec973655e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/Invariant.Linux.cs` |
| 501 | `build/MilBridge/tools/gdiplus-liar.c` | 2 | 4895356 | 2617 | `96f09250c0f3adcf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/gdiplus-liar.c` |
| 502 | `tests/WpfGfx.Linux.Tests/Commands.Tests/xunit.runner.json` | 2 | 4895627 | 179 | `7ef2fb403da55cac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/xunit.runner.json` |
| 503 | `tests/WpfGfx.Linux.Tests/Windowing.Tests/xunit.runner.json` | 2 | 4895630 | 179 | `7ef2fb403da55cac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Windowing.Tests/xunit.runner.json` |
| 504 | `tests/WpfGfx.Linux.Tests/HelloMil.Tests/xunit.runner.json` | 2 | 4895640 | 179 | `7ef2fb403da55cac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/HelloMil.Tests/xunit.runner.json` |
| 505 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/xunit.runner.json` | 2 | 4895641 | 179 | `7ef2fb403da55cac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/xunit.runner.json` |
| 506 | `src/WpfGfx.Linux.Native/tools/__pycache__/wire-uiautomation-resolver.cpython-310.pyc` | 2 | 4895673 | 11679 | `def0408d027a5654` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/wire-uiautomation-resolver.cpython-310.pyc` |
| 507 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-textline-fallback.cpython-310.pyc` | 2 | 4895676 | 65355 | `9cfbad484d3f9bdd` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-textline-fallback.cpython-310.pyc` |
| 508 | `build/MilBridge/T1b-family-ledger.md` | 2 | 4895694 | 34044 | `396fdaa7f26370cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1b-family-ledger.md` |
| 509 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-msgflow.cpython-310.pyc` | 2 | 4895723 | 26007 | `0727f357411cfa0a` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-msgflow.cpython-310.pyc` |
| 510 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/OpacityMaskTests.cs` | 2 | 4895742 | 8611 | `1a3443971ca0df7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/OpacityMaskTests.cs` |
| 511 | `build/MilBridge/T1d-tab-and-modifier.md` | 2 | 4896806 | 151298 | `1ae408bc42880d8d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1d-tab-and-modifier.md` |
| 512 | `build/MilBridge/tools/__pycache__/applier-audit.cpython-310.pyc` | 2 | 4932605 | 14020 | `aba7f47d6961157a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/__pycache__/applier-audit.cpython-310.pyc` |
| 513 | `build/MilBridge/W24B-report.md` | 2 | 4932618 | 48085 | `89309b0fdb905bda` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W24B-report.md` |
| 514 | `build/MilBridge/W24C-report.md` | 2 | 4932628 | 28644 | `bc9f3af81a312ef0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W24C-report.md` |
| 515 | `build/fonts/README.md` | 2 | 4932647 | 1344 | `3d4c1bf95917615c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts/README.md` |
| 516 | `build/MilBridge/W47A-report.md` | 2 | 4932653 | 35372 | `68bfb1301c67d485` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W47A-report.md` |
| 517 | `src/WpfGfx.Linux.Native/src/win32_oem.c` | 3 | 4932659 | 9375 | `ca500dcefe716835` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_oem.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_oem.c` |
| 518 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py` | 3 | 4932675 | 10261 | `1ac574eb8c9f5576` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py` |
| 519 | `build/PresentationCore.Linux/HwndTarget.Linux.cs` | 2 | 4932676 | 117790 | `309c5280207061e0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/HwndTarget.Linux.cs` |
| 520 | `build/publish-milbridge.sh` | 2 | 4932682 | 7517 | `6c570029fd1d8a2a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/publish-milbridge.sh` |
| 521 | `build/MilBridge/tools/column-floor-check.sh` | 3 | 4932684 | 52716 | `2be59234f7266e0f` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/column-floor-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/column-floor-check.sh` |
| 522 | `build/MilBridge/known-red.json.bak-20260917-151210` | 2 | 4932695 | 35310 | `5aead470c23a99ff` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/known-red.json.bak-20260917-151210` |
| 523 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-inputtrace.cpython-310.pyc` | 2 | 4932698 | 41570 | `562c14ae4144a631` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-presentationcore-inputtrace.cpython-310.pyc` |
| 524 | `docs/WAVE46-PROGRESS.md` | 2 | 4932700 | 20106 | `1143dc859e10b23a` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE46-PROGRESS.md` |
| 525 | `build/MilBridge/W21B-report.md` | 2 | 4932709 | 52574 | `66a78a99bf1b3847` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W21B-report.md` |
| 526 | `docs/WAVE28-PREREGISTRATION.md` | 2 | 4932715 | 18326 | `7b006ef0d7c4c7cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE28-PREREGISTRATION.md` |
| 527 | `docs/WAVE29-PREREGISTRATION.md` | 2 | 4932728 | 17956 | `ced44a5068e0db56` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE29-PREREGISTRATION.md` |
| 528 | `docs/WAVE30-PREREGISTRATION.md` | 2 | 4932733 | 13613 | `a2df283703194da0` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE30-PREREGISTRATION.md` |
| 529 | `docs/WAVE31-PREREGISTRATION.md` | 2 | 4932740 | 19337 | `b6a363c751082d8c` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE31-PREREGISTRATION.md` |
| 530 | `docs/WAVE47-PREREGISTRATION.md` | 2 | 4932744 | 10785 | `19b37da5e261905a` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE47-PREREGISTRATION.md` |
| 531 | `build/MilBridge/W47B-report.md` | 2 | 4932747 | 22819 | `760e56072d7f90ef` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W47B-report.md` |
| 532 | `build/MilBridge/W46I-report.md` | 2 | 4932749 | 31115 | `194ffc33fb453c80` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46I-report.md` |
| 533 | `src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-dpvalue-trace.cpython-310.pyc` | 2 | 4932755 | 61823 | `a1e471bc5ff2c080` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/__pycache__/patch-windowsbase-dpvalue-trace.cpython-310.pyc` |
| 534 | `docs/WAVE48-PREREGISTRATION.md` | 2 | 4932764 | 8224 | `a9dde474b96393ab` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE48-PREREGISTRATION.md` |
| 535 | `src/WpfGfx.Linux/Interop/MilGeometryEngine.cs` | 3 | 4980859 | 59786 | `b12f24d83fa794ed` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilGeometryEngine.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilGeometryEngine.cs` |
| 536 | `build/MilBridge/gen/milcore-dllimports.json` | 2 | 4980860 | 81714 | `4414a1e1624ea0c1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/milcore-dllimports.json` |
| 537 | `build/MilBridge/spike/SmokeTest/SmokeTest.csproj` | 2 | 4980863 | 1175 | `f3a43c8c9fbef35c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/spike/SmokeTest/SmokeTest.csproj` |
| 538 | `build/MilBridge/spike/SmokeTest/Program.cs` | 2 | 4980864 | 4456 | `f4eddc41d6c184ea` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/spike/SmokeTest/Program.cs` |
| 539 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DispatcherPumpTests.cs` | 2 | 4980902 | 13449 | `0585177e3686bcc7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DispatcherPumpTests.cs` |
| 540 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/XTool.cs` | 2 | 4980903 | 5392 | `b7f5aa794c16bfe1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/XTool.cs` |
| 541 | `build/MilBridge/gen/side-by-side.txt` | 2 | 4980905 | 21633 | `a773dff765e74954` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/side-by-side.txt` |
| 542 | `build/MilBridge/NuGet.config` | 2 | 4980938 | 562 | `3cbe8e6d483ca1cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/NuGet.config` |
| 543 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/Win32AbiLayoutTests.cs` | 2 | 4980948 | 13718 | `6de6aa13c6a861f8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/Win32AbiLayoutTests.cs` |
| 544 | `build/MilBridge/gen/cprobe-output.txt` | 2 | 4981077 | 714 | `96f01ac824c9ce39` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/cprobe-output.txt` |
| 545 | `build/MilBridge/src/MilBridge.Linux/Exports.g.cs` | 2 | 4981093 | 59955 | `fdb9cec5f56ea922` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Linux/Exports.g.cs` |
| 546 | `build/DirectWrite.Linux/Directory.Build.props` | 2 | 4981145 | 2375 | `73b9ea80d6886341` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Directory.Build.props` |
| 547 | `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` | 2 | 4981147 | 2686 | `7c674ac0059407cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` |
| 548 | `build/DirectWrite.Linux/Provider/MetricsFactory.cs` | 2 | 4981256 | 15413 | `7b2122b712becda5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/MetricsFactory.cs` |
| 549 | `build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj` | 2 | 4981258 | 1761 | `4774df3ecc2a4e4b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj` |
| 550 | `build/DirectWrite.Linux/Provider/FontHandleTable.cs` | 2 | 4981259 | 12090 | `2f82735e5836b1f0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FontHandleTable.cs` |
| 551 | `build/DirectWrite.Linux/Provider/LinuxFontFile.cs` | 2 | 4981260 | 8364 | `158852b9577e461b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/LinuxFontFile.cs` |
| 552 | `build/MilBridge/tests/ClosedLoop/Program.cs` | 2 | 4981271 | 65847 | `a9f92ef5e8524727` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ClosedLoop/Program.cs` |
| 553 | `build/MilBridge/gen/closed-loop-output.txt` | 2 | 4981300 | 8362 | `9571c0d933bb91dc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/closed-loop-output.txt` |
| 554 | `tests/parity/windows/src/U1Recorder/recorder-report-diagnosis.txt` | 2 | 4981304 | 13366 | `7f55d1797045ec9b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Recorder/recorder-report-diagnosis.txt` |
| 555 | `build/shims/WindowsBase.EventTrace.Shim.cs` | 3 | 4981307 | 9066 | `b20e7c9c01668123` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/WindowsBase.EventTrace.Shim.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/WindowsBase.EventTrace.Shim.cs` |
| 556 | `build/WindowsBase.Linux/reapply-patches.py` | 2 | 4981308 | 10090 | `05314aa6f39446a1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/WindowsBase.Linux/reapply-patches.py` |
| 557 | `tests/WpfGfx.Linux.Tests/Commands.Tests/GeometryOracleTests.cs` | 2 | 4981309 | 22630 | `c4282b9ed8bfda80` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Commands.Tests/GeometryOracleTests.cs` |
| 558 | `build/DirectWrite.Linux/Provider/FaceSelector.cs` | 2 | 4981310 | 8115 | `2422140ab8bce2bf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FaceSelector.cs` |
| 559 | `build/DirectWrite.Linux/Provider/LinuxFontCollection.cs` | 2 | 4981311 | 21766 | `e07ac1329fec10fa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/LinuxFontCollection.cs` |
| 560 | `build/MilBridge/tools/scan-milcore-dllimports.py` | 2 | 4981312 | 6220 | `27e663c2e5875392` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/scan-milcore-dllimports.py` |
| 561 | `build/MilBridge/gen/export-symbols.txt` | 2 | 4981315 | 3222 | `a3ed47409d06acdf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/export-symbols.txt` |
| 562 | `build/MilBridge/alt-route-b/ProbeB/ProbeB.csproj` | 2 | 4981333 | 2552 | `932d72eeaf9b8cf2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/alt-route-b/ProbeB/ProbeB.csproj` |
| 563 | `build/MilBridge/gen/landing-table.md` | 2 | 4981335 | 10000 | `5fac7b00d2663e30` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/landing-table.md` |
| 564 | `tests/parity/windows/src/U1Recorder/recorder-report-capture.txt` | 2 | 4981381 | 13366 | `7f55d1797045ec9b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Recorder/recorder-report-capture.txt` |
| 565 | `tests/parity/windows/src/U1Recorder/recorder-report-window.txt` | 2 | 4981382 | 15125 | `f1e6d3dc90a42b26` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Recorder/recorder-report-window.txt` |
| 566 | `build/DirectWrite.Linux/Tests/TestLayout.cs` | 2 | 4981389 | 5868 | `bcbf78a235366b57` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/TestLayout.cs` |
| 567 | `build/DirectWrite.Linux/Tests/PlacementTests.cs` | 2 | 4981397 | 15367 | `ffc9d6a210bd0318` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/PlacementTests.cs` |
| 568 | `build/MilBridge/alt-route-b/ProbeB/UpstreamMirrors.cs` | 2 | 4981398 | 2360 | `47de70ded6342a61` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/alt-route-b/ProbeB/UpstreamMirrors.cs` |
| 569 | `build/MilBridge/alt-route-b/ProbeB/NaiveCallSites.cs` | 2 | 4981399 | 2684 | `e4262b775e24bb38` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/alt-route-b/ProbeB/NaiveCallSites.cs` |
| 570 | `build/DirectWrite.Linux/FallbackCriteria/run-df1-criteria.sh` | 2 | 4981402 | 7320 | `5d45016767624269` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/run-df1-criteria.sh` |
| 571 | `build/DirectWrite.Linux/FallbackCriteria/seg-instrument.sh` | 2 | 4981403 | 11886 | `5c9b63ba4cdef6b6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/seg-instrument.sh` |
| 572 | `build/MilBridge/W46H-report.md` | 2 | 4981414 | 38825 | `7fa30d7fd839b49b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46H-report.md` |
| 573 | `build/MilBridge/gen/route-b-diagnostics.txt` | 2 | 4981431 | 2899 | `66f5eadddad3a917` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/route-b-diagnostics.txt` |
| 574 | `build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj` | 2 | 4981438 | 2397 | `e0d703376d7fd45e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Probe/DirectWrite.Linux.Probe.csproj` |
| 575 | `build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` | 2 | 4981488 | 1667 | `347d4a475ab62197` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` |
| 576 | `build/DirectWrite.Linux/Provider/OpenTypeFontData.cs` | 2 | 4981498 | 33162 | `30232c6c587d83a8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/OpenTypeFontData.cs` |
| 577 | `tests/parity/windows/src/U1Parity/J.cs` | 2 | 4981503 | 4824 | `66b2261d55784940` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Parity/J.cs` |
| 578 | `tests/parity/windows/src/U1Parity/Program.cs` | 2 | 4981504 | 17199 | `43be7ea166e01371` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Parity/Program.cs` |
| 579 | `tests/parity/windows/src/U1Parity/R.cs` | 2 | 4981505 | 12151 | `a201dd2202b945b3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Parity/R.cs` |
| 580 | `tests/parity/windows/src/U1Parity/Scenes.cs` | 2 | 4981506 | 37584 | `e8001e19a149d907` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Parity/Scenes.cs` |
| 581 | `tests/parity/windows/src/U1Parity/U1Parity.csproj` | 2 | 4981507 | 625 | `102c5560a1673cff` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Parity/U1Parity.csproj` |
| 582 | `tests/parity/windows/src/U1Recorder/Program.cs` | 2 | 4981508 | 32787 | `80ac39a9ff849f03` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Recorder/Program.cs` |
| 583 | `tests/parity/windows/src/U1Recorder/U1Recorder.csproj` | 2 | 4981509 | 646 | `ed4787d66cf80132` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Recorder/U1Recorder.csproj` |
| 584 | `tests/parity/windows/src/nuget.config` | 2 | 4981510 | 402 | `c96b6b61f5e1be13` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/nuget.config` |
| 585 | `tests/parity/windows/streams/u1a-scenes-rtb-managedhook-partial.stream` | 2 | 4981511 | 18927 | `89978b0552eec407` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1a-scenes-rtb-managedhook-partial.stream` |
| 586 | `build/DirectWrite.Linux/Tests/ProviderShapeTests.cs` | 2 | 4981516 | 17132 | `4ac68b237a72523c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/ProviderShapeTests.cs` |
| 587 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/LinuxEnvironmentDiagnosticsTests.cs` | 2 | 4981517 | 13699 | `b36990100e12b9c7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/LinuxEnvironmentDiagnosticsTests.cs` |
| 588 | `docs/U1-windows-probe.md` | 2 | 4981518 | 32263 | `68d961def360f2b9` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U1-windows-probe.md` |
| 589 | `build/DirectWrite.Linux/Provider/GlyphMapper.cs` | 2 | 4981520 | 12632 | `d4a49c65da3f1f11` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/GlyphMapper.cs` |
| 590 | `build/DirectWrite.Linux/Tests/OpenTypeOracleTests.cs` | 2 | 4981524 | 15868 | `04f616cfa3843dbd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/OpenTypeOracleTests.cs` |
| 591 | `build/DirectWrite.Linux/Tests/GlyphIndexTests.cs` | 2 | 4981527 | 18109 | `92d7a91a69b62049` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/GlyphIndexTests.cs` |
| 592 | `build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj` | 2 | 4981528 | 2901 | `7db47d37b943f312` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj` |
| 593 | `src/WpfGfx.Linux.Native/README.md` | 2 | 4981530 | 6131 | `71a7a12e9abd3ba0` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/README.md` |
| 594 | `docs/U1c-geometry-oracle.md` | 2 | 4981533 | 25026 | `d890b6f8dd4cfa9b` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U1c-geometry-oracle.md` |
| 595 | `build/MilBridge/alt-route-b/ProbeB/AdaptedCallSites.cs` | 2 | 4981534 | 3362 | `65eb3ef3add1e827` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/alt-route-b/ProbeB/AdaptedCallSites.cs` |
| 596 | `src/WpfGfx.Linux.Native/tools/shim-depth.py` | 2 | 4981536 | 7771 | `292803106ba81d7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/shim-depth.py` |
| 597 | `build/DirectWrite.Linux/Probe/ProbeDigest.cs` | 2 | 4981537 | 17549 | `8fef4bb5508df771` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Probe/ProbeDigest.cs` |
| 598 | `docs/T3-hellowpf-csproj.md` | 2 | 4981558 | 45999 | `9bdfb41171f20fe8` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/T3-hellowpf-csproj.md` |
| 599 | `build/DirectWrite.Linux/Probe/Program.cs` | 2 | 4981559 | 3687 | `30304759ddc4dddf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Probe/Program.cs` |
| 600 | `build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` | 2 | 4981577 | 4976 | `244ed6aad02b25de` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/DirectWrite.Linux.Tests.csproj` |
| 601 | `build/port-lib.py` | 3 | 4981595 | 37751 | `900dad4a3d1ca2d2` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/port-lib.py`<br>`/home/links-dev/w62a/negrepo/build/port-lib.py` |
| 602 | `build/DirectWrite.Linux/Tests/DigestTests.cs` | 2 | 4981596 | 7838 | `64f65459fd145cea` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/DigestTests.cs` |
| 603 | `docs/U2-M7b-report.md` | 2 | 4981597 | 39029 | `2511425c711dd888` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/U2-M7b-report.md` |
| 604 | `build/DirectWrite.Linux/Tests/M1ConsistencyTests.cs` | 2 | 4981598 | 17664 | `a37e9bb2168e26dc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/M1ConsistencyTests.cs` |
| 605 | `build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs` | 2 | 4981628 | 1736 | `da73fd4ee9da722f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs` |
| 606 | `build/DirectWrite.Linux/Tests/FontFixture.cs` | 2 | 4981631 | 3879 | `fcbc5f3e4996cd65` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/FontFixture.cs` |
| 607 | `build/DirectWrite.Linux/Provider/FontModel.cs` | 2 | 4981632 | 14384 | `2118b673c2283363` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FontModel.cs` |
| 608 | `build/MilBridge/gen/t1b-ls-live-hellowpf.txt` | 2 | 4981636 | 1020 | `442fc35f534a3099` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-ls-live-hellowpf.txt` |
| 609 | `build/DirectWrite.Linux/artifacts/probe-summary.txt` | 2 | 4981771 | 68193 | `69765a2d9b8da2cf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/artifacts/probe-summary.txt` |
| 610 | `build/DirectWrite.Linux/artifacts/probe-digest.txt` | 2 | 4981774 | 231 | `8b0a6fb8719ce81a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/artifacts/probe-digest.txt` |
| 611 | `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs` | 2 | 4981775 | 8180 | `d2e034e81ce265bc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs` |
| 612 | `build/DirectWrite.Linux/Provider/MetricModels.cs` | 2 | 4981776 | 14663 | `b7a7cb3d32c1d71e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/MetricModels.cs` |
| 613 | `build/DirectWrite.Linux/WiringSmoke/Program.cs` | 2 | 4981785 | 41590 | `08207ef8b70d6a90` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WiringSmoke/Program.cs` |
| 614 | `build/DirectWrite.Linux/Tests/FontLayoutStrippingTests.cs` | 2 | 4981788 | 26022 | `d7e2944129e22597` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/FontLayoutStrippingTests.cs` |
| 615 | `build/DirectWrite.Linux/Provider/GlyphPositioner.cs` | 2 | 4981845 | 11326 | `94d71cee948cae6e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/GlyphPositioner.cs` |
| 616 | `build/DirectWrite.Linux/Tests/MetricsTests.cs` | 2 | 4981852 | 12291 | `742eea43f63c5ca9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/MetricsTests.cs` |
| 617 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityScenes.cs` | 2 | 4981855 | 34758 | `aac169794c5e9dbe` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityScenes.cs` |
| 618 | `build/shims/PresentationCore.FontBridge.cs` | 3 | 4981856 | 19407 | `d06088eb854df1ab` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationCore.FontBridge.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationCore.FontBridge.cs` |
| 619 | `build/DirectWrite.Linux/PNSE-INVENTORY.md` | 2 | 4981857 | 14426 | `4280c091213b81b2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/PNSE-INVENTORY.md` |
| 620 | `build/DirectWrite.Linux/WIRING.md` | 2 | 4981859 | 46775 | `bba1fa916b54f762` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WIRING.md` |
| 621 | `build/DirectWriteForwarder.Linux/ProviderAdapters.cs` | 2 | 4981860 | 10772 | `671732780ceac659` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWriteForwarder.Linux/ProviderAdapters.cs` |
| 622 | `build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj` | 2 | 4981869 | 4347 | `f242ede737b37b13` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WiringSmoke/DirectWrite.Linux.WiringSmoke.csproj` |
| 623 | `build/DirectWrite.Linux/Tests/WiringTests.cs` | 2 | 4981932 | 15286 | `2519657572d78b6d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/WiringTests.cs` |
| 624 | `build/DirectWrite.Linux/README.md` | 2 | 4981936 | 5449 | `49aff4c67783a144` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/README.md` |
| 625 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityCompare.cs` | 2 | 4981940 | 13725 | `10e00196911c5004` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityCompare.cs` |
| 626 | `build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs` | 2 | 4981949 | 9721 | `e32d24ca00be2b91` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs` |
| 627 | `tests/parity/windows/src/U1Proxy/reorder_releases.py` | 2 | 4981963 | 2569 | `ff23d26cf6ad58cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/reorder_releases.py` |
| 628 | `tests/parity/windows/streams/u1b-scenes-rtb-raw.stream` | 2 | 4981964 | 46807 | `5fbe76be4626618e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1b-scenes-rtb-raw.stream` |
| 629 | `tests/parity/windows/streams/u1b-channel2-raw.stream` | 2 | 4981965 | 2544 | `75275a5ad552a070` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1b-channel2-raw.stream` |
| 630 | `tests/parity/windows/streams/u1b-channel0-raw.stream` | 2 | 4981966 | 90 | `bd67564ce1d458a5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1b-channel0-raw.stream` |
| 631 | `tests/parity/windows/streams/u1b-channel3-raw.stream` | 2 | 4981967 | 510 | `06aa62bb70b4f031` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/u1b-channel3-raw.stream` |
| 632 | `tests/parity/windows/src/U1Proxy/pe_exports.py` | 2 | 4981969 | 4386 | `ed4adb2b63e28e10` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/pe_exports.py` |
| 633 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DP1ReproTests.cs` | 2 | 4981971 | 42781 | `2a471ffa79b9ee9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DP1ReproTests.cs` |
| 634 | `tests/parity/windows/src/U1Proxy/gen_proxy.py` | 2 | 4981972 | 2713 | `f25a60c79218583c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/gen_proxy.py` |
| 635 | `tests/parity/windows/src/U1Proxy/proxy.c` | 2 | 4981973 | 8933 | `7afd894a97f266e6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/proxy.c` |
| 636 | `tests/parity/windows/src/U1Proxy/build.ps1` | 2 | 4981974 | 1538 | `8ecb6751529437eb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/build.ps1` |
| 637 | `tests/parity/windows/src/U1Proxy/runproxy2.ps1` | 2 | 4981975 | 1549 | `3af38f9257f53ba1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/runproxy2.ps1` |
| 638 | `tests/parity/windows/src/U1Proxy/exports.json` | 2 | 4981976 | 11488 | `2327707f3387b7f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/exports.json` |
| 639 | `tests/parity/windows/src/U1Proxy/built_exports.json` | 2 | 4981977 | 23301 | `2b65497cf2898f86` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/built_exports.json` |
| 640 | `tests/parity/windows/src/U1Proxy/proxy_exports.h` | 2 | 4981978 | 4480 | `ad437b6759d64d31` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/proxy_exports.h` |
| 641 | `tests/parity/windows/src/U1Proxy/stubs.s` | 2 | 4981979 | 12332 | `b968a78aa31feacd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/stubs.s` |
| 642 | `tests/parity/windows/src/U1Proxy/out/wpf-proxy.log` | 2 | 4981981 | 425 | `396bb5da6e9b0fd0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/out/wpf-proxy.log` |
| 643 | `tests/parity/windows/src/U1Proxy/out/recorder-report.txt` | 2 | 4981982 | 13513 | `65c46f3c525d8244` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/out/recorder-report.txt` |
| 644 | `tests/parity/windows/src/U1Proxy/out/real_wpfgfx_cor3.dll` | 2 | 4981983 | 1952016 | `f4f7a44a3480c0b7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/out/real_wpfgfx_cor3.dll` |
| 645 | `tests/parity/windows/src/U1Proxy/out/wpfgfx_cor3.dll` | 2 | 4981984 | 208384 | `3cde4be43afb16f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/src/U1Proxy/out/wpfgfx_cor3.dll` |
| 646 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cChainTests.cs` | 2 | 4981986 | 24273 | `ec66b9648c405767` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cChainTests.cs` |
| 647 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/X11WindowWrapTests.cs` | 2 | 4982149 | 8087 | `e876dac09cad86a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/X11WindowWrapTests.cs` |
| 648 | `build/DirectWrite.Linux/SystemFontsProbe/Program.cs` | 2 | 4982150 | 9446 | `5968579c80c285d2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/SystemFontsProbe/Program.cs` |
| 649 | `build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj` | 2 | 4982151 | 3998 | `1230ce4162779597` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/SystemFontsProbe/DirectWrite.Linux.SystemFontsProbe.csproj` |
| 650 | `tests/parity/windows/streams/README.md` | 2 | 4982152 | 1112 | `5a22c8bd10bd3990` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/streams/README.md` |
| 651 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/RenderingSemanticsTests.cs` | 2 | 4982153 | 23655 | `c251cc1e0bea634e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/RenderingSemanticsTests.cs` |
| 652 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityTests.cs` | 2 | 4982155 | 46887 | `922d71254cca1042` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityTests.cs` |
| 653 | `build/PresentationFramework.Classic.Linux/PresentationFramework.Classic.Linux.csproj` | 2 | 4982156 | 12362 | `464ad4e32fb2252c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Classic.Linux/PresentationFramework.Classic.Linux.csproj` |
| 654 | `src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs` | 3 | 4982248 | 8738 | `13042855412721bc` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.NotificationWindow.cs` |
| 655 | `src/WpfGfx.Linux/Interop/MilNative.Window.cs` | 3 | 4982251 | 19319 | `37718ff6c2b3ab58` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Window.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Window.cs` |
| 656 | `build/MilBridge/src/MilBridge.Linux/Diagnostics.cs` | 2 | 4982255 | 10422 | `614fe31b6ed59661` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/src/MilBridge.Linux/Diagnostics.cs` |
| 657 | `src/WpfGfx.Linux/Interop/MilNative.Glyph.cs` | 3 | 4982256 | 10538 | `0a6d71c33c1d27c0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Glyph.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Glyph.cs` |
| 658 | `src/WpfGfx.Linux/Interop/MilNative.Exports.cs` | 3 | 4982257 | 17251 | `908d17937e9f8ad0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Exports.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Exports.cs` |
| 659 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/xunit.runner.json` | 2 | 4982282 | 175 | `5dea9f6480af0e4f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/xunit.runner.json` |
| 660 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/xunit.runner.json` | 2 | 4982284 | 175 | `5dea9f6480af0e4f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/xunit.runner.json` |
| 661 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` | 2 | 4982289 | 5679 | `365f54dbe3c08723` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` |
| 662 | `build/PresentationFramework.Classic.Linux/PORT-CHANGES.md` | 2 | 4982290 | 721 | `03a634f0cdbab3fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Classic.Linux/PORT-CHANGES.md` |
| 663 | `build/PresentationFramework.Classic.Linux/reapply-patches.py` | 2 | 4982292 | 14000 | `f90919df1ce025ce` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationFramework.Classic.Linux/reapply-patches.py` |
| 664 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cProbe/HelloWpfProbe.cs` | 2 | 4982352 | 39419 | `b8654338061693a9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cProbe/HelloWpfProbe.cs` |
| 665 | `build/DirectWrite.Linux/Provider/LayoutFeatureReader.cs` | 2 | 4982355 | 11318 | `434a889bd44b051f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/LayoutFeatureReader.cs` |
| 666 | `build/DirectWrite.Linux/Provider/FontTableStripper.cs` | 2 | 4982356 | 13262 | `66e9f21c4b964273` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FontTableStripper.cs` |
| 667 | `build/DirectWrite.Linux/WiringSmoke/fix-deps.py` | 2 | 4982357 | 1195 | `239ef2d23bd18f7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WiringSmoke/fix-deps.py` |
| 668 | `build/DirectWrite.Linux/Provider/LayoutLookupCoverage.cs` | 2 | 4982358 | 14061 | `b51cb2c11189ec71` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/LayoutLookupCoverage.cs` |
| 669 | `build/DirectWrite.Linux/Provider/TypographyMaskEstimator.cs` | 2 | 4982359 | 13705 | `6cdd7f2bc07733bf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/TypographyMaskEstimator.cs` |
| 670 | `build/DirectWrite.Linux/Tests/TypographyGateTests.cs` | 2 | 4982361 | 21270 | `81422d7702c53e8e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/TypographyGateTests.cs` |
| 671 | `build/gen-ui-font.py` | 2 | 4982363 | 10925 | `2ccf476bd054fb33` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/gen-ui-font.py` |
| 672 | `build/fonts-ui/UI-NoLayout.ttf` | 2 | 4982364 | 332736 | `b008d486c4e02941` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts-ui/UI-NoLayout.ttf` |
| 673 | `build/fonts-ui/SHA256SUMS` | 2 | 4982365 | 82 | `a6cbfff011f4819f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/fonts-ui/SHA256SUMS` |
| 674 | `build/MilBridge/tests/T2Repro/T2Repro.csproj` | 2 | 4982368 | 1964 | `fd65cfe42abb4644` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/T2Repro/T2Repro.csproj` |
| 675 | `build/MilBridge/tests/T2Repro/Program.cs` | 2 | 4982369 | 12040 | `cbe4842f4826ed34` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/T2Repro/Program.cs` |
| 676 | `build/MilBridge/gen/t2repro-output.txt` | 2 | 4982394 | 1851 | `8ead573ba78ee0ec` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2repro-output.txt` |
| 677 | `src/WpfGfx.Linux/Text/FontSet.cs` | 3 | 4982398 | 8038 | `5bc39e07a9cb9174` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Text/FontSet.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Text/FontSet.cs` |
| 678 | `build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj` | 2 | 4982400 | 1305 | `41be9c3d96256bef` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicSeamProbe/DirectWrite.Linux.WicSeamProbe.csproj` |
| 679 | `build/DirectWrite.Linux/WicSeamProbe/Program.cs` | 2 | 4982401 | 3085 | `08f7bd96d1c33f22` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicSeamProbe/Program.cs` |
| 680 | `build/DirectWrite.Linux/wic-shim/probe_decode` | 2 | 4982431 | 26616 | `8be52bfc4265a6fa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_decode` |
| 681 | `build/DirectWrite.Linux/wic-shim/probe_decode.c` | 2 | 4982432 | 5593 | `8a3c6ed5ee95c8b0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_decode.c` |
| 682 | `build/MilBridge/tests/HbSpike/HbSpike.csproj` | 2 | 4982435 | 2194 | `07a2fcc9cf0ecba9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/HbSpike/HbSpike.csproj` |
| 683 | `build/MilBridge/tests/HbSpike/HbSpike.cs` | 2 | 4982436 | 21585 | `d951189035d1e53c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/HbSpike/HbSpike.cs` |
| 684 | `build/MilBridge/gen/hbspike-output.txt` | 2 | 4982455 | 2989 | `db3d488cff4492ba` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/hbspike-output.txt` |
| 685 | `build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` | 2 | 4982494 | 1084 | `fc1bce9d74814834` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` |
| 686 | `build/wic-abi-reference/AbiProbe/Program.cs` | 2 | 4982496 | 5117 | `420176ba1114413b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/wic-abi-reference/AbiProbe/Program.cs` |
| 687 | `build/wic-abi-reference/abi-proof-output.txt` | 2 | 4982497 | 872 | `8bd83ce1b0de3cd3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/wic-abi-reference/abi-proof-output.txt` |
| 688 | `build/wic-abi-reference/AbiProbe/AbiProbe.csproj` | 2 | 4982498 | 925 | `079941617a70ad5a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/wic-abi-reference/AbiProbe/AbiProbe.csproj` |
| 689 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c` | 2 | 4982558 | 130595 | `8dc634b9254295f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/wic_proxy.c` |
| 690 | `build/wic-abi-reference/README.md` | 2 | 4982559 | 6586 | `875779c0f782dbe8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/wic-abi-reference/README.md` |
| 691 | `build/DirectWrite.Linux/Provider/FontLayoutStripping.cs` | 2 | 4982560 | 9521 | `b59f1b194215e219` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FontLayoutStripping.cs` |
| 692 | `build/DirectWrite.Linux/wic-shim/probe_refcount.c` | 2 | 4982561 | 4747 | `87095a77486df5d6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_refcount.c` |
| 693 | `build/DirectWrite.Linux/wic-shim/probe_shim.c` | 2 | 4982562 | 6394 | `70ce3371e672f6f6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_shim.c` |
| 694 | `build/DirectWrite.Linux/wic-shim/probe_shim` | 2 | 4982563 | 16720 | `0096708201a15690` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_shim` |
| 695 | `build/DirectWrite.Linux/wic-shim/libSkiaSharp.so` | 2 | 4982564 | 9244960 | `a02cd03f1ebcbb97` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so` |
| 696 | `build/DirectWrite.Linux/Provider/LinuxFontFace.cs` | 2 | 4982566 | 31491 | `69875ecde79b22d3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/LinuxFontFace.cs` |
| 697 | `build/DirectWrite.Linux/Tests/StripLayoutSmokeTests.cs` | 2 | 4982567 | 7472 | `7073d6559204fff7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/StripLayoutSmokeTests.cs` |
| 698 | `build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` | 2 | 4982568 | 3689 | `8ee7dd3feb1a6df3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` |
| 699 | `build/DirectWrite.Linux/wic-shim/probe_encode.c` | 2 | 4982647 | 2195 | `ebd98aea0cd9a580` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_encode.c` |
| 700 | `build/DirectWrite.Linux/wic-shim/probe_encode` | 2 | 4982653 | 16192 | `f246a2e48f78a617` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_encode` |
| 701 | `src/WpfGfx.Linux/Interop/MilNative.Misc.cs` | 3 | 4982655 | 63271 | `f773d38f6f0e027b` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.Misc.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.Misc.cs` |
| 702 | `build/DirectWrite.Linux/wic-shim/probe_refcount` | 2 | 4982659 | 16192 | `e603791e9addd9a3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_refcount` |
| 703 | `build/MilBridge/tests/ContractProbe/ContractProbe.csproj` | 2 | 4982660 | 2291 | `8ba16750c3515188` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ContractProbe/ContractProbe.csproj` |
| 704 | `build/DirectWrite.Linux/WicClosedLoop/run-harness.sh` | 2 | 4982662 | 3713 | `0e1f66b4ba9682c7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicClosedLoop/run-harness.sh` |
| 705 | `build/MilBridge/tests/ContractProbe/Program.cs` | 2 | 4982664 | 13165 | `bd4f4958578daeaa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ContractProbe/Program.cs` |
| 706 | `build/DirectWrite.Linux/WicClosedLoop/fixtures/dpi300-title.png` | 2 | 4982751 | 167 | `32209dbd7bc369a2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicClosedLoop/fixtures/dpi300-title.png` |
| 707 | `build/DirectWrite.Linux/WicClosedLoop/fixtures/jfif150.jpg` | 2 | 4982752 | 22 | `a5739ab04ee3fa0a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicClosedLoop/fixtures/jfif150.jpg` |
| 708 | `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` | 2 | 4982754 | 3694 | `19fd9a1c6f9cbe35` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` |
| 709 | `build/DirectWrite.Linux/WicWriteClosedLoop/run-write-harness.sh` | 2 | 4982756 | 3723 | `57642b8223f54ca3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/run-write-harness.sh` |
| 710 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cRealAttachmentTests.cs` | 2 | 4982777 | 22624 | `5fdc2cd333af577b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cRealAttachmentTests.cs` |
| 711 | `build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/dpi300-title.png` | 2 | 4982844 | 167 | `32209dbd7bc369a2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/dpi300-title.png` |
| 712 | `build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/jfif150.jpg` | 2 | 4982845 | 323 | `d19588d6ff625d54` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/jfif150.jpg` |
| 713 | `build/DirectWrite.Linux/wic-shim/probe_premul.c` | 2 | 4982874 | 4271 | `b009573e8c201c97` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_premul.c` |
| 714 | `build/DirectWrite.Linux/wic-shim/probe_write_loop.c` | 2 | 4982875 | 6599 | `95e91a6c94d9e8a9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_write_loop.c` |
| 715 | `build/DirectWrite.Linux/wic-shim/probe_write_loop` | 2 | 4982876 | 16480 | `3d1b7768e8f24a08` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_write_loop` |
| 716 | `build/DirectWrite.Linux/FontEntryClosedLoop/Program.cs` | 2 | 4982878 | 7904 | `616e29ea6b03e82e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FontEntryClosedLoop/Program.cs` |
| 717 | `build/DirectWrite.Linux/wic-shim/fixtures-jfif.jpg` | 2 | 4982965 | 323 | `d19588d6ff625d54` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/fixtures-jfif.jpg` |
| 718 | `build/MilBridge/gen/textline-proto.png` | 2 | 4982966 | 4722 | `f442be49706592e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/textline-proto.png` |
| 719 | `build/DirectWrite.Linux/wic-shim/probe_premul` | 2 | 4982967 | 16424 | `7c110f81e260a3b4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_premul` |
| 720 | `build/DirectWrite.Linux/WicWriteClosedLoop/Program.cs` | 2 | 4982968 | 16676 | `e342faf695bc936f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/Program.cs` |
| 721 | `build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/itxt-comment.png` | 2 | 4982969 | 210 | `233e11f9c1e002a7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/itxt-comment.png` |
| 722 | `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` | 2 | 4982971 | 3695 | `d94254348ae8db03` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` |
| 723 | `build/DirectWrite.Linux/FontEntryClosedLoop/run-font-harness.sh` | 2 | 4982973 | 3725 | `db296e6f2422ef2a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FontEntryClosedLoop/run-font-harness.sh` |
| 724 | `build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/exif-make.jpg` | 2 | 4983057 | 496 | `296b2a4e0ea2b612` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicWriteClosedLoop/fixtures/exif-make.jpg` |
| 725 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/MilWicQueryInterfaceTests.cs` | 2 | 4983061 | 25801 | `84717ad4c4f87eb8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/MilWicQueryInterfaceTests.cs` |
| 726 | `build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj` | 2 | 4983080 | 3433 | `c84b0fc124abfbae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CompositeFontProbe/CompositeFontProbe.csproj` |
| 727 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cMilStreamTests.cs` | 2 | 4983081 | 16659 | `05b0a803945e214e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cMilStreamTests.cs` |
| 728 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mimetype.py` | 3 | 4983623 | 19836 | `dc41b2541071bea5` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-mimetype.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-mimetype.py` |
| 729 | `docs/WAVE34-PREREGISTRATION.md` | 2 | 4983624 | 78859 | `6f1692973f572d88` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE34-PREREGISTRATION.md` |
| 730 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | 2 | 4983625 | 668062 | `38e67e834430d75c` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 731 | `build/System.Windows.Extensions.Linux/System.Windows.Extensions.Linux.csproj` | 2 | 4983705 | 2336 | `0732e440e800af75` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Extensions.Linux/System.Windows.Extensions.Linux.csproj` |
| 732 | `build/System.Windows.Extensions.Linux/PORT-CHANGES.md` | 2 | 4983707 | 1925 | `ab169d1b1dd5625e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Extensions.Linux/PORT-CHANGES.md` |
| 733 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-1400rate.sh` | 2 | 4983913 | 6193 | `1442cc9466deccdf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-1400rate.sh` |
| 734 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py` | 3 | 4984422 | 20467 | `9ea2222bca1bfb58` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py` |
| 735 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cInputPathTests.cs` | 2 | 4984621 | 29305 | `bd986620764c73c0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cInputPathTests.cs` |
| 736 | `build/MilBridge/gen/tline-ledger-lines-20260914-0919.txt` | 2 | 4985126 | 1734 | `dff49a7222eda72d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0919.txt` |
| 737 | `build/MilBridge/gen/tline-ledger-lines-20260914-0918.txt` | 2 | 4985152 | 1734 | `dff49a7222eda72d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0918.txt` |
| 738 | `tests/parity/geometry/u14/cases-u14.json` | 2 | 4985441 | 16477 | `96d6449c4cf7a76a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/cases-u14.json` |
| 739 | `build/MilBridge/gen/tline-ledger-lines-20260914-1001.txt` | 2 | 4985982 | 1734 | `9e5e555d26e8bdce` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1001.txt` |
| 740 | `tests/parity/geometry/u14/windows-results-u14.json` | 2 | 4986149 | 1610662 | `03a053ce4106f709` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/windows-results-u14.json` |
| 741 | `build/MilBridge/gen/compositefont-before.txt` | 2 | 4986441 | 14254 | `ce226ca75b493047` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/compositefont-before.txt` |
| 742 | `build/MilBridge/gen/compositefont-simulated-shortcircuit.txt` | 2 | 4986442 | 8636 | `b76ffcde9397c89c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/compositefont-simulated-shortcircuit.txt` |
| 743 | `tests/parity/geometry/u14/u14-pointsets.json` | 2 | 4986511 | 11670 | `e5ba2b0be59b6e9a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/u14-pointsets.json` |
| 744 | `tests/parity/geometry/u14/u14-density.md` | 2 | 4986512 | 2423 | `b1399d5d587426c3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/u14-density.md` |
| 745 | `build/MilBridge/gen/tline-ledger-lines-20260914-0917.txt` | 2 | 4986811 | 1734 | `151b1372ae1d8aaf` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0917.txt` |
| 746 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh` | 2 | 4986816 | 35517 | `7c832278d150c3a7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh` |
| 747 | `build/DirectWrite.Linux/wic-shim/probe_foreign` | 2 | 4986839 | 16352 | `161a6f80a4ff172b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_foreign` |
| 748 | `build/MilBridge/gen/layout-b34-accounting.txt` | 2 | 4986913 | 27318 | `56073c2c7aa06cac` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/layout-b34-accounting.txt` |
| 749 | `build/MilBridge/gen/layout-b34-compact.json` | 2 | 4986942 | 3187473 | `c691a11039ed740b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/layout-b34-compact.json` |
| 750 | `build/DirectWrite.Linux/wic-shim/probe_foreign.c` | 2 | 4986958 | 7201 | `4db663b0ea238fe4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_foreign.c` |
| 751 | `src/WpfGfx.Linux/Interop/Win32UiFont.cs` | 3 | 4987095 | 9306 | `007f2011e7ec35bd` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/Win32UiFont.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/Win32UiFont.cs` |
| 752 | `build/MilBridge/gen/t1b-tline.txt` | 2 | 4987249 | 13838 | `126f03686fbaf2d4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-tline.txt` |
| 753 | `build/MilBridge/gen/t1b-icu.txt` | 2 | 4987251 | 3286 | `b7d8c8abc62c9bea` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-icu.txt` |
| 754 | `build/MilBridge/gen/t1b-textline.txt` | 2 | 4987252 | 7550 | `013fa060df74b0e0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-textline.txt` |
| 755 | `build/MilBridge/gen/t1b-ls-tripwire-selftest.txt` | 2 | 4987253 | 1715 | `78ade0f35e790f84` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-ls-tripwire-selftest.txt` |
| 756 | `build/DirectWrite.Linux/wic-shim/probe_lock.c` | 2 | 4987258 | 6701 | `51c6ccf0c4322fa8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_lock.c` |
| 757 | `build/MilBridge/gen/t1b-ls-lifecycle-probe.txt` | 2 | 4987259 | 13139 | `13c55b6c6203daff` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-ls-lifecycle-probe.txt` |
| 758 | `build/MilBridge/gen/t1b-ls-lifecycle-tripwire.txt` | 2 | 4987260 | 845 | `36ae00978b1128cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-ls-lifecycle-tripwire.txt` |
| 759 | `build/DirectWrite.Linux/wic-shim/probe_lock` | 2 | 4987263 | 16240 | `3a6fd8d9541d4cf5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_lock` |
| 760 | `build/MilBridge/gen/t1b-ls-live-wpftextdemo.txt` | 2 | 4987265 | 1066 | `ce78321adedb4eeb` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b-ls-live-wpftextdemo.txt` |
| 761 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/CwicWrapperBitmapTests.cs` | 2 | 4987268 | 11654 | `32bc5864792cb3e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/CwicWrapperBitmapTests.cs` |
| 762 | `build/DirectWrite.Linux/Provider/FamilyCoverage.cs` | 2 | 4987272 | 8652 | `daa6d6b083f005ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FamilyCoverage.cs` |
| 763 | `build/DirectWrite.Linux/Tests/FamilyCoverageTests.cs` | 2 | 4987273 | 3632 | `a51a1025d0c40820` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/FamilyCoverageTests.cs` |
| 764 | `build/MilBridge/T2b-rtl-ctm-report.md` | 2 | 4987555 | 57438 | `5e123bd81f28b5a1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T2b-rtl-ctm-report.md` |
| 765 | `build/DirectWrite.Linux/Provider/DefaultFontFamily.cs` | 2 | 4987562 | 7854 | `d574c3acd6cc6939` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/DefaultFontFamily.cs` |
| 766 | `build/DirectWrite.Linux/Tests/DefaultFamilyTests.cs` | 2 | 4987566 | 3677 | `3e7544b33c6b57f9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Tests/DefaultFamilyTests.cs` |
| 767 | `build/MilBridge/W27A-report.md` | 2 | 4989201 | 34147 | `d74700706abb9e39` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W27A-report.md` |
| 768 | `build/MilBridge/W27B-report.md` | 2 | 4989216 | 24642 | `dbef220a99cfd925` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W27B-report.md` |
| 769 | `build/MilBridge/W27C-report.md` | 2 | 4989218 | 32533 | `7adcad13e3e38d43` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W27C-report.md` |
| 770 | `build/MilBridge/gen/tline-ledger-lines-20260920-0017.txt` | 2 | 4989333 | 958 | `a88d3bad8d7bdc39` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260920-0017.txt` |
| 771 | `build/MilBridge/gen/tline-ledger-lines-20260919-0031.txt` | 2 | 4989340 | 958 | `b467499e8120416e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-0031.txt` |
| 772 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedWindowTests.cs` | 2 | 4989391 | 31029 | `0fa9849bd76b7dcc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedWindowTests.cs` |
| 773 | `tests/parity/geometry/u14/Program.cs` | 2 | 4990166 | 40647 | `1f879d22b0faccb3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/Program.cs` |
| 774 | `build/MilBridge/tests/BboxProbe/Program.cs` | 2 | 4990351 | 3044 | `c06f605002cb5d48` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/BboxProbe/Program.cs` |
| 775 | `build/MilBridge/tests/Directory.Build.targets` | 2 | 4990742 | 1735 | `1324fcde93604349` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/Directory.Build.targets` |
| 776 | `tests/parity/geometry/u14/U14.csproj` | 2 | 4990956 | 1500 | `1936ad70116cca57` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/U14.csproj` |
| 777 | `build/MilBridge/W27D-report.md` | 2 | 4991108 | 21021 | `83cd40cf1e9d6c97` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W27D-report.md` |
| 778 | `docs/WAVE27-PREREGISTRATION.md` | 2 | 4991155 | 16121 | `7f9be51161349ed0` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE27-PREREGISTRATION.md` |
| 779 | `docs/WAVE26-PREREGISTRATION.md` | 2 | 4991184 | 17685 | `7f850589b67c4ff7` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE26-PREREGISTRATION.md` |
| 780 | `docs/ARCHITECTURE.md` | 2 | 4991185 | 74738 | `22578f2991e56e51` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/ARCHITECTURE.md` |
| 781 | `build/MilBridge/W46H2-report.md` | 2 | 4991216 | 16444 | `12b9313b0f6b1f53` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46H2-report.md` |
| 782 | `build/MilBridge/gen/tline-ledger-lines-20260919-2057.txt` | 2 | 4991469 | 958 | `513d592ff4839fea` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-2057.txt` |
| 783 | `build/MilBridge/gen/tline-ledger-lines-20260919-1514.txt` | 2 | 4991470 | 958 | `40e146f269294c2d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-1514.txt` |
| 784 | `build/MilBridge/T2b-classname-report.md` | 2 | 4991590 | 7331 | `4e0079844b4ab54a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T2b-classname-report.md` |
| 785 | `build/MilBridge/T1d-report.md` | 2 | 4991636 | 61936 | `1b7b18394a475ec4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1d-report.md` |
| 786 | `build/MilBridge/tests/InputTraceProbe/WpfLinuxInputTrace.extracted.cs` | 2 | 4992303 | 22451 | `96c8f5f9765db8e4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/InputTraceProbe/WpfLinuxInputTrace.extracted.cs` |
| 787 | `build/MilBridge/tests/InputTraceProbe/InputTraceProbe.csproj` | 2 | 4992304 | 1252 | `3013e1dd5c9d021d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/InputTraceProbe/InputTraceProbe.csproj` |
| 788 | `build/MilBridge/tests/InputTraceProbe/Program.cs` | 2 | 4992305 | 6323 | `9f9ef7d085a0b5ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/InputTraceProbe/Program.cs` |
| 789 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-mutation.sh` | 2 | 4992337 | 5038 | `2969c104da60a9d9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-mutation.sh` |
| 790 | `build/MilBridge/T2b-unimplemented-audit.md` | 2 | 4992653 | 5977 | `af7c129cadab968d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T2b-unimplemented-audit.md` |
| 791 | `build/MilBridge/gen/tline-ledger-lines-20260919-0230.txt` | 2 | 4993106 | 958 | `e94d91b98184a46d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-0230.txt` |
| 792 | `build/MilBridge/M7b-F2-report.md` | 2 | 4994884 | 37503 | `053cc78ed07152c3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/M7b-F2-report.md` |
| 793 | `build/MilBridge/T1c-inputtrace-report.md` | 2 | 4995124 | 120975 | `a1e99c8d3b1e10b5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1c-inputtrace-report.md` |
| 794 | `build/MilBridge/gen/tline-ledger-lines-20260919-0342.txt` | 2 | 4995300 | 958 | `ccc2c277f024418b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-0342.txt` |
| 795 | `build/MilBridge/gen/tline-ledger-lines-20260913-2119.txt` | 2 | 4995892 | 1734 | `462a20ff00b01934` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260913-2119.txt` |
| 796 | `build/MilBridge/gen/tline-detail-20260913-1703.txt` | 2 | 4995907 | 474 | `5cc8391444df4ed4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-20260913-1703.txt` |
| 797 | `build/MilBridge/gen/tline-detail-20260913-1710.txt` | 2 | 4995908 | 21596 | `b9e634e04d8a2f66` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-20260913-1710.txt` |
| 798 | `build/MilBridge/M7b-msgflow-report.md` | 2 | 4995910 | 26770 | `1d2d0738d834c78f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/M7b-msgflow-report.md` |
| 799 | `tests/parity/windows/layout-b34/src/LayoutOracle/Probe.cs` | 2 | 4996732 | 14385 | `a550c6f26b3630a2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/Probe.cs` |
| 800 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-inputleg-tooth.sh` | 2 | 4997443 | 3924 | `807ff8fe74a7d8c0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-inputleg-tooth.sh` |
| 801 | `build/MilBridge/gen/tline-detail-20260913-1730.txt` | 2 | 4998068 | 21954 | `3eea3e742df82cc7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-20260913-1730.txt` |
| 802 | `build/MilBridge/gen/tline-detail-full.txt` | 2 | 4998069 | 107549 | `e888bb09ed96920b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-full.txt` |
| 803 | `tests/parity/geometry/u14/probe-pointsets.json` | 2 | 4998350 | 13393 | `daff5a1e63c6ec0b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/probe-pointsets.json` |
| 804 | `tests/parity/geometry/u14/probe-density.md` | 2 | 4998351 | 2642 | `44d28bf50bf7775c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/probe-density.md` |
| 805 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/rtl-ink-profile.py` | 2 | 4998775 | 5127 | `74d89d213e0a30f0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/rtl-ink-profile.py` |
| 806 | `build/MilBridge/T1d-bidi-scoping.md` | 2 | 4998913 | 91242 | `b3747ccc3855b001` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1d-bidi-scoping.md` |
| 807 | `build/MilBridge/W53A-report.md` | 2 | 4998927 | 30438 | `77b1a7560eb48b57` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W53A-report.md` |
| 808 | `build/MilBridge/W54A-report.md` | 2 | 4999341 | 33660 | `549153f5c85694ca` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W54A-report.md` |
| 809 | `tests/parity/geometry/u14/linux-results-u14.json` | 2 | 4999365 | 123918748 | `32eca5dc0dbe258f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/linux-results-u14.json` |
| 810 | `src/WpfGfx.Linux.Native/src/win32_misc.c` | 3 | 5000085 | 79361 | `b09058febe5954e4` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_misc.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_misc.c` |
| 811 | `build/MilBridge/W56A-report.md` | 2 | 5000275 | 33902 | `dac0e01285d03874` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W56A-report.md` |
| 812 | `docs/FORK-AND-PUSH.md` | 2 | 5000464 | 10655 | `78de7d2158f430e3` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/FORK-AND-PUSH.md` |
| 813 | `README.md` | 2 | 5000465 | 17885 | `456d8b86e0ffb179` | 是（1 条） | `/home/links-dev/w62a/negrepo/README.md` |
| 814 | `docs/history/README.md` | 2 | 5000467 | 1702 | `a1acc60df035d2eb` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/history/README.md` |
| 815 | `build/shims/PresentationCore.Factory.Linux.cs` | 3 | 5002602 | 23423 | `125cfaa3c9851cfd` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/PresentationCore.Factory.Linux.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/PresentationCore.Factory.Linux.cs` |
| 816 | `build/DirectWrite.Linux/wic-shim/probe_subrect` | 2 | 5003443 | 16320 | `28e7e349a58692aa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_subrect` |
| 817 | `tests/parity/geometry/u14/U14-flatten-density.md` | 2 | 5003605 | 17951 | `5719a0fd8727b2bf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/geometry/u14/U14-flatten-density.md` |
| 818 | `build/MilBridge/tests/CompositeFontProbe/Program.cs` | 2 | 5005720 | 32437 | `6cf17867abddcd47` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CompositeFontProbe/Program.cs` |
| 819 | `build/DirectWrite.Linux/wic-shim/probe_subrect.c` | 2 | 5005844 | 3586 | `a6a25db46379544b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_subrect.c` |
| 820 | `src/WpfGfx.Linux/Commands/MilVisualTransformDiag.cs` | 3 | 5006895 | 10517 | `019b7e070b65be41` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilVisualTransformDiag.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilVisualTransformDiag.cs` |
| 821 | `tests/parity/windows/layout-b34/src/LayoutOracle/Program.cs` | 2 | 5006953 | 2087 | `d2bb078f7e37f39f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/src/LayoutOracle/Program.cs` |
| 822 | `build/MilBridge/M7b-vistrans-report.md` | 2 | 5007582 | 6984 | `62055275aaf05a83` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/M7b-vistrans-report.md` |
| 823 | `build/MilBridge/gen/icu-break-parity.txt` | 2 | 5007972 | 28630 | `7d20c605b7cbbce4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/icu-break-parity.txt` |
| 824 | `build/MilBridge/gen/tline-detail-20260913-2110.txt` | 2 | 5008792 | 22450 | `33af2411af00bf37` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-20260913-2110.txt` |
| 825 | `build/MilBridge/gen/tline-ledger-lines-20260913-2100.txt` | 2 | 5008797 | 1734 | `d622a3ca36d88a35` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260913-2100.txt` |
| 826 | `.gitignore` | 2 | 5008930 | 5683 | `b00da80374898ab4` | 是（1 条） | `/home/links-dev/w62a/negrepo/.gitignore` |
| 827 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | 2 | 5010828 | 7312 | `fbcd89b206f9f25c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` |
| 828 | `build/MilBridge/gen/tline-ledger-lines-20260913-2219.txt` | 2 | 5010869 | 1734 | `8304bd1102f089f9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260913-2219.txt` |
| 829 | `src/WpfGfx.Linux/Resources/TransformProvenance.cs` | 3 | 5011039 | 8135 | `8a1dc8a72659f21f` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/TransformProvenance.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Resources/TransformProvenance.cs` |
| 830 | `src/WpfGfx.Linux/Rendering/GlyphRunCensus.cs` | 3 | 5011042 | 17996 | `3dc890edcaac0c5d` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/GlyphRunCensus.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/GlyphRunCensus.cs` |
| 831 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/VisualTransformToWorldTests.cs` | 2 | 5011044 | 9706 | `74948dcaac82bccd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/VisualTransformToWorldTests.cs` |
| 832 | `src/WpfGfx.Linux/Resources/VisualProjection.cs` | 3 | 5011046 | 10261 | `968ee04e123cb006` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/VisualProjection.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Resources/VisualProjection.cs` |
| 833 | `docs/RELEASE-READINESS.md` | 2 | 5011118 | 7346 | `a5125bee7930be42` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/RELEASE-READINESS.md` |
| 834 | `build/bridge-src-fp.sh` | 2 | 5011615 | 5221 | `03ec025bfb370071` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/bridge-src-fp.sh` |
| 835 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/ContentTransformSpaceTests.cs` | 2 | 5011629 | 8551 | `89e36b9531c6a992` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/ContentTransformSpaceTests.cs` |
| 836 | `build/MilBridge/tools/check-export-numbers.py` | 2 | 5011643 | 7534 | `688a7e25bb896034` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/check-export-numbers.py` |
| 837 | `docs/WAVE37-PREREGISTRATION.md` | 2 | 5011768 | 18097 | `b4506f5ce39e26f7` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE37-PREREGISTRATION.md` |
| 838 | `build/MilBridge/tools/applier-audit.py` | 2 | 5012234 | 18706 | `67e18dd64a33ac0a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/applier-audit.py` |
| 839 | `samples/WpfTextDemo/NEXT-WAVE-12-CHECKLIST.md` | 2 | 5012493 | 7591 | `e80c7dccf8afca0a` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/NEXT-WAVE-12-CHECKLIST.md` |
| 840 | `build/MilBridge/gen/tline-detail-20260913-2030.txt` | 2 | 5012982 | 22270 | `c46697970ccae4ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-detail-20260913-2030.txt` |
| 841 | `build/MilBridge/tools/verify-all-step-check.sh` | 3 | 5013178 | 31491 | `41d702168f191b2a` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/verify-all-step-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/verify-all-step-check.sh` |
| 842 | `samples/ThirdPartyMini/App.xaml` | 2 | 5013210 | 234 | `1ed54b6fe96ec169` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/App.xaml` |
| 843 | `samples/ThirdPartyMini/App.xaml.cs` | 2 | 5013230 | 219 | `77321752d57a1123` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/App.xaml.cs` |
| 844 | `samples/ThirdPartyMini/MainWindow.xaml` | 2 | 5013231 | 4370 | `12889e30184d1c28` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/MainWindow.xaml` |
| 845 | `samples/ThirdPartyMini/MainWindow.xaml.cs` | 2 | 5013233 | 3887 | `d38ba9beb47f3157` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/MainWindow.xaml.cs` |
| 846 | `samples/ThirdPartyMini/ThirdPartyMini.csproj` | 2 | 5013234 | 3836 | `bea59353c18ac8ab` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/ThirdPartyMini.csproj` |
| 847 | `tests/parity/windows/font-fallback/src/FontFallback.csproj` | 2 | 5013430 | 459 | `cebecb9beec42a76` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/src/FontFallback.csproj` |
| 848 | `tests/parity/windows/font-fallback/src/run.ps1` | 2 | 5013431 | 2471 | `cced8a61a29116cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/src/run.ps1` |
| 849 | `samples/ThirdPartyMini/run-thirdparty-mini.sh` | 3 | 5013604 | 12440 | `0ed2bb05ea806432` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/samples/ThirdPartyMini/run-thirdparty-mini.sh`<br>`/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/run-thirdparty-mini.sh` |
| 850 | `tests/parity/windows/font-fallback/src/Program.cs` | 2 | 5013694 | 37695 | `e5217bcd6d7c9d78` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/src/Program.cs` |
| 851 | `build/MilBridge/gen/tline-ledger-lines-20260913-2120.txt` | 2 | 5014847 | 1734 | `d23abaf36f49d45f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260913-2120.txt` |
| 852 | `build/MilBridge/gen/tline-ledger-lines-20260913-2121.txt` | 2 | 5014849 | 1734 | `d23abaf36f49d45f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260913-2121.txt` |
| 853 | `build/MilBridge/tools/build-hygiene-import-check.sh` | 3 | 5014900 | 68488 | `545f3bd1d21b6ee8` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/build-hygiene-import-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/build-hygiene-import-check.sh` |
| 854 | `samples/ThirdPartyMini/README.md` | 2 | 5014901 | 6473 | `07cad28a49f62f8b` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/ThirdPartyMini/README.md` |
| 855 | `tests/parity/windows/font-fallback/analyze.py` | 2 | 5015185 | 18693 | `ada560dea5ea0c69` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/analyze.py` |
| 856 | `build/MilBridge/gen/tline-ledger-lines-20260914-2207.txt` | 2 | 5015299 | 1605 | `1cd9016fd2869a73` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2207.txt` |
| 857 | `tests/parity/windows/modifier-close/src/ModifierClose.csproj` | 2 | 5015306 | 461 | `291a0913391d45e7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/src/ModifierClose.csproj` |
| 858 | `tests/parity/windows/modifier-close/src/run.ps1` | 2 | 5015307 | 2479 | `0355697dd2d3c119` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/src/run.ps1` |
| 859 | `tests/parity/windows/modifier-close/PROVENANCE.md` | 2 | 5015311 | 7528 | `6935fd9b7861a93a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/PROVENANCE.md` |
| 860 | `tests/parity/windows/font-fallback/out/font-fallback-raw.json` | 2 | 5015351 | 160206 | `62e2d45dd04d36e2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/out/font-fallback-raw.json` |
| 861 | `tests/parity/windows/font-fallback/out/font-fallback-raw.txt` | 2 | 5015353 | 34214 | `b43e3206954db775` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/out/font-fallback-raw.txt` |
| 862 | `tests/parity/windows/font-fallback/out/font-fallback-oracle.json` | 2 | 5015354 | 182634 | `d7b6e3db20b78b9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/out/font-fallback-oracle.json` |
| 863 | `tests/parity/windows/font-fallback/out/font-fallback-oracle.txt` | 2 | 5015355 | 28470 | `20a8c413a0bac785` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/out/font-fallback-oracle.txt` |
| 864 | `tests/parity/windows/font-fallback/PROVENANCE.md` | 2 | 5015357 | 11167 | `a44d1457580c27ab` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/font-fallback/PROVENANCE.md` |
| 865 | `tests/parity/windows/modifier-close/src/Program.cs` | 2 | 5015457 | 17276 | `3fa85210ed422095` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/src/Program.cs` |
| 866 | `build/__pycache__/artifact-src-fp.cpython-310.pyc` | 2 | 5015458 | 22647 | `da9d2b1c7d21d8fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/__pycache__/artifact-src-fp.cpython-310.pyc` |
| 867 | `tests/parity/windows/modifier-close/analyze.py` | 2 | 5015728 | 14337 | `4afc60dd99dbb0eb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/analyze.py` |
| 868 | `tests/parity/windows/modifier-close/out/modifier-close-raw.json` | 2 | 5015743 | 74507 | `514f25c457b1bd05` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/out/modifier-close-raw.json` |
| 869 | `tests/parity/windows/modifier-close/out/modifier-close-raw.txt` | 2 | 5015744 | 1705 | `c72644c2a4296f28` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/out/modifier-close-raw.txt` |
| 870 | `tests/parity/windows/modifier-close/out/modifier-close-oracle.json` | 2 | 5015745 | 78367 | `3a2d0b6115d7844f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/out/modifier-close-oracle.json` |
| 871 | `tests/parity/windows/modifier-close/out/modifier-close-oracle.txt` | 2 | 5015746 | 24550 | `8b68902082c28588` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-close/out/modifier-close-oracle.txt` |
| 872 | `build/MilBridge/gen/tline-ledger-lines-20260914-2210.txt` | 2 | 5015899 | 1605 | `6d5635219072e006` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2210.txt` |
| 873 | `build/MilBridge/T1b2-report.md` | 2 | 5016020 | 69208 | `9fa189e4ff824225` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1b2-report.md` |
| 874 | `build/MilBridge/gen/tline-ledger-lines-20260914-2212.txt` | 2 | 5016168 | 1605 | `6d5635219072e006` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2212.txt` |
| 875 | `samples/WpfTextDemo/WAVE24-FINAL-ROUND.md` | 2 | 5016178 | 12049 | `c3390a90178af540` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WAVE24-FINAL-ROUND.md` |
| 876 | `build/MilBridge/gen/tline-ledger-lines-20260915-1022.txt` | 2 | 5016263 | 1001 | `29859a0acc574ee5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1022.txt` |
| 877 | `build/MilBridge/gen/tline-ledger-lines-20260915-1024.txt` | 2 | 5016271 | 1001 | `31162922ae0008af` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1024.txt` |
| 878 | `samples/WpfTextDemo/NEXT-WAVE-13-CHECKLIST.md` | 2 | 5016279 | 35293 | `ceacf562577b2852` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/NEXT-WAVE-13-CHECKLIST.md` |
| 879 | `build/MilBridge/W46K-report.md` | 2 | 5016641 | 18167 | `88809b2148016bd3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46K-report.md` |
| 880 | `build/MilBridge/gen/tline-ledger-lines-20260915-1034.txt` | 2 | 5016793 | 1002 | `036931f2d4cf5ed9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1034.txt` |
| 881 | `build/MilBridge/gen/tline-ledger-lines-20260915-1035.txt` | 2 | 5016795 | 1605 | `b3502a4adf2b296a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1035.txt` |
| 882 | `build/MilBridge/tools/sync-applocal.sh` | 3 | 5016816 | 24673 | `9805a0123770416c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/sync-applocal.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/sync-applocal.sh` |
| 883 | `build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` | 2 | 5017042 | 2956 | `e566405b5698e53a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/FallbackCriteria.csproj` |
| 884 | `build/artifact-src-fp.py` | 2 | 5017043 | 28025 | `e856e2e65e6c59ca` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/artifact-src-fp.py` |
| 885 | `build/MilBridge/T1c-report.md` | 2 | 5017062 | 272131 | `04422985ebba1f58` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1c-report.md` |
| 886 | `samples/WpfTextDemo/WAVE25-FINAL-ROUND.md` | 2 | 5017067 | 14650 | `637114ecc174368e` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WAVE25-FINAL-ROUND.md` |
| 887 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/pick-postwrite-line.py` | 2 | 5017784 | 5515 | `aa1c38adc95997a2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/pick-postwrite-line.py` |
| 888 | `build/DirectWrite.Linux/FallbackCriteria/advance_from_font.py` | 2 | 5017818 | 4476 | `9e7b353c8aa9cfba` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/advance_from_font.py` |
| 889 | `build/MilBridge/tests/TextLineProto/Program.cs` | 2 | 5017821 | 25312 | `34e31d95b29a1bd1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/TextLineProto/Program.cs` |
| 890 | `build/DirectWrite.Linux/FallbackCriteria/eval-df1-criteria.py` | 2 | 5017879 | 31870 | `fc808896f23390f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/eval-df1-criteria.py` |
| 891 | `build/DirectWrite.Linux/FallbackCriteria/Program.cs` | 2 | 5017882 | 36569 | `2c97104bf86a3d85` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/Program.cs` |
| 892 | `build/MilBridge/T1b3-tline-gate-report.md` | 2 | 5018238 | 20726 | `6d5dfb4634f30680` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1b3-tline-gate-report.md` |
| 893 | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | 2 | 5018619 | 74984 | `f7b3026c8c019be2` | 是（1 条） | `/home/links-dev/w113a/fixture/repo/build/DirectWrite.Linux/wic-shim/libwpfwic.so` |
| 894 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py` | 2 | 5018633 | 20917 | `b13172b944707620` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-mousecapture-release.py` |
| 895 | `build/close-wave.sh` | 2 | 5018638 | 36725 | `c757fd5058f1bfd4` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/close-wave.sh` |
| 896 | `build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` | 2 | 5018911 | 9850 | `09e5bab7c3d246f6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/mem-sampler.sh` |
| 897 | `build/DirectWrite.Linux/REPORT.md` | 2 | 5019163 | 308611 | `2e9a3c91040dbe66` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/REPORT.md` |
| 898 | `build/DirectWrite.Linux/evidence/mem-D-F1c/df1c-localize-REPORT.md` | 2 | 5019207 | 11632 | `474cb57daeeb9b10` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/df1c-localize-REPORT.md` |
| 899 | `build/DirectWrite.Linux/evidence/mem-D-F1c/df1c-afterFIX-REPORT.md` | 2 | 5019208 | 5629 | `51765eaa5b36eea9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/df1c-afterFIX-REPORT.md` |
| 900 | `build/DirectWrite.Linux/evidence/mem-D-F1c/window3-REPORT.md` | 2 | 5019209 | 6749 | `037b1b3599429b45` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/window3-REPORT.md` |
| 901 | `build/DirectWrite.Linux/evidence/mem-D-F1c/window4-REPORT.md` | 2 | 5019210 | 6102 | `65b67e95e06d3430` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/window4-REPORT.md` |
| 902 | `build/DirectWrite.Linux/evidence/mem-D-F1c/window5-REPORT.md` | 2 | 5019211 | 3939 | `61130a57ad79ad7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/window5-REPORT.md` |
| 903 | `build/DirectWrite.Linux/evidence/mem-D-F1c/window6-REPORT.md` | 2 | 5019212 | 4633 | `d0fc79ff21ca0db8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/window6-REPORT.md` |
| 904 | `build/DirectWrite.Linux/evidence/mem-D-F1c/window6b-maps-REPORT.md` | 2 | 5019213 | 3577 | `a155a0f76dae00de` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/window6b-maps-REPORT.md` |
| 905 | `build/DirectWrite.Linux/evidence/mem-D-F1c/meta-all-windows.txt` | 2 | 5019214 | 51100 | `1c55986786d83a86` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/meta-all-windows.txt` |
| 906 | `build/DirectWrite.Linux/evidence/mem-D-F1c/maps-at-peak-1038466.txt` | 2 | 5019215 | 68684 | `39301679fb5cc84f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/maps-at-peak-1038466.txt` |
| 907 | `build/DirectWrite.Linux/evidence/mem-D-F1c/smaps-at-peak-1038466.txt` | 2 | 5019216 | 500743 | `2b144411b1e167b3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/smaps-at-peak-1038466.txt` |
| 908 | `build/DirectWrite.Linux/evidence/mem-D-F1c/snap-ok.txt` | 2 | 5019217 | 80 | `9bfcf11a2c33ab5b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/snap-ok.txt` |
| 909 | `build/DirectWrite.Linux/evidence/mem-D-F1c/diag-lines-all-windows.txt` | 2 | 5019218 | 39083 | `964c1e3b1c9286e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/diag-lines-all-windows.txt` |
| 910 | `build/DirectWrite.Linux/evidence/mem-D-F1c/INDEX.md` | 2 | 5019219 | 3095 | `bc8ec2f78aa99530` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/evidence/mem-D-F1c/INDEX.md` |
| 911 | `build/DirectWrite.Linux/Provider/SkiaFontDataCache.cs` | 2 | 5019222 | 5599 | `054ab29d10fc74e9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/SkiaFontDataCache.cs` |
| 912 | `src/WpfGfx.Linux/Interop/MilNative.FontFace.cs` | 3 | 5019226 | 14934 | `46d6a64e501a9423` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.FontFace.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.FontFace.cs` |
| 913 | `src/WpfGfx.Linux/Interop/SkiaFontFileCache.cs` | 3 | 5019230 | 11439 | `7602480948483d1a` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/SkiaFontFileCache.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/SkiaFontFileCache.cs` |
| 914 | `src/WpfGfx.Linux/Interop/MilHandleTables.cs` | 3 | 5019232 | 56794 | `083b02d09956d42c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilHandleTables.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilHandleTables.cs` |
| 915 | `docs/WAVE15-PREREGISTRATION.md` | 2 | 5019429 | 48009 | `f7aa6744fbc6ff9b` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE15-PREREGISTRATION.md` |
| 916 | `build/MilBridge/gen/tline-ledger-lines-20260915-1252.txt` | 2 | 5019517 | 958 | `d98cc5dd5dd54d15` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1252.txt` |
| 917 | `build/check-fp-polarity.sh` | 2 | 5019520 | 3732 | `f91d12bed2494889` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/check-fp-polarity.sh` |
| 918 | `build/MilBridge/W48B-report.md` | 2 | 5020208 | 20628 | `074ac18bba4d433b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W48B-report.md` |
| 919 | `build/MilBridge/gen/tline-ledger-lines-20260919-2307.txt` | 2 | 5020244 | 958 | `513d592ff4839fea` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-2307.txt` |
| 920 | `docs/WAVE38-PREREGISTRATION.md` | 2 | 5020598 | 10144 | `a21111fe172f65f0` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE38-PREREGISTRATION.md` |
| 921 | `build/System.Windows.Extensions.Linux/System.Windows.Extensions.Linux.cs` | 2 | 5020606 | 10344 | `0248b6780760da76` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/System.Windows.Extensions.Linux/System.Windows.Extensions.Linux.cs` |
| 922 | `src/WpfGfx.Linux.Native/tools/patch-swe-linux.py` | 3 | 5020680 | 11403 | `1e29cf7d3d0b8600` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-swe-linux.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-swe-linux.py` |
| 923 | `docs/WAVE15-RUNBOOK.md` | 2 | 5021073 | 11044 | `707ea1830f456210` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE15-RUNBOOK.md` |
| 924 | `build/DirectWrite.Linux/FallbackCriteria/seg-sampler.py` | 2 | 5021074 | 13522 | `9934771b1bff861b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/FallbackCriteria/seg-sampler.py` |
| 925 | `docs/WAVE16-PREREGISTRATION.md` | 2 | 5021272 | 62836 | `f526d0dad3f32d89` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE16-PREREGISTRATION.md` |
| 926 | `build/MilBridge/gen/tline-ledger-lines-20260915-1718.txt` | 2 | 5021281 | 958 | `7048eabcaa68d15d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1718.txt` |
| 927 | `build/MilBridge/gen/tline-ledger-lines-20260915-1737.txt` | 2 | 5021302 | 957 | `48f8f2c5def79e7d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1737.txt` |
| 928 | `build/MilBridge/gen/tline-ledger-lines-20260915-1744.txt` | 2 | 5021309 | 957 | `4b1055b1619dc57e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1744.txt` |
| 929 | `build/MilBridge/gen/tline-ledger-lines-20260915-1748.txt` | 2 | 5021319 | 957 | `0be717c0941d9421` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1748.txt` |
| 930 | `build/MilBridge/gen/tline-ledger-lines-20260915-1754.txt` | 2 | 5021327 | 957 | `5477413524c2070b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1754.txt` |
| 931 | `build/MilBridge/gen/tline-ledger-lines-20260915-1759.txt` | 2 | 5021335 | 957 | `4f4da125beee5ecc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1759.txt` |
| 932 | `build/MilBridge/gen/tline-ledger-lines-20260915-1804.txt` | 2 | 5021343 | 957 | `31acaefca07bf4b6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1804.txt` |
| 933 | `build/MilBridge/gen/tline-ledger-lines-20260915-1810.txt` | 2 | 5021350 | 957 | `dbd50045366a5624` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1810.txt` |
| 934 | `build/MilBridge/gen/tline-ledger-lines-20260915-1818.txt` | 2 | 5021357 | 957 | `0a8d75a98742505a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1818.txt` |
| 935 | `build/MilBridge/gen/tline-ledger-lines-20260915-1823.txt` | 2 | 5021364 | 957 | `2baa73952ae04a94` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1823.txt` |
| 936 | `build/MilBridge/gen/tline-ledger-lines-20260915-1830.txt` | 2 | 5021373 | 957 | `13853a4b0eb2fdb4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1830.txt` |
| 937 | `build/MilBridge/tools/shim-in-artifact.sh` | 2 | 5021942 | 16612 | `e2e1a42b5f0e5b45` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/shim-in-artifact.sh` |
| 938 | `build/MilBridge/T17A-report.md` | 2 | 5021978 | 30681 | `de044cb22c77c9c8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T17A-report.md` |
| 939 | `build/MilBridge/gen/tline-ledger-lines-20260917-0036.txt` | 2 | 5021979 | 958 | `7d6799e8c1560b5d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260917-0036.txt` |
| 940 | `build/MilBridge/gen/tline-ledger-lines-20260915-1852.txt` | 2 | 5022000 | 958 | `4e994215f78a9d0d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260915-1852.txt` |
| 941 | `build/DirectWrite.Linux/TAPPS-blind-half-report.md` | 2 | 5022003 | 49882 | `9071d4bcf39918b8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/TAPPS-blind-half-report.md` |
| 942 | `build/MilBridge/TDT2-boundary-report.md` | 2 | 5022004 | 53018 | `6388461b4ecd0de7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/TDT2-boundary-report.md` |
| 943 | `build/MilBridge/R17A-recon.md` | 2 | 5022538 | 66490 | `f0a8f3a65b2770cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/R17A-recon.md` |
| 944 | `build/MilBridge/R17B-recon.md` | 2 | 5022539 | 53879 | `9c8f11eb6f29d15f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/R17B-recon.md` |
| 945 | `build/MilBridge/R17C-audit.md` | 2 | 5022545 | 51904 | `d5062f8b95369574` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/R17C-audit.md` |
| 946 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs` | 2 | 5022547 | 11710 | `caf58e239062f7b6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs` |
| 947 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/SystemParametersInfoTests.cs` | 2 | 5022548 | 15857 | `bf97579c7e6db160` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/SystemParametersInfoTests.cs` |
| 948 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs` | 2 | 5022549 | 12808 | `e393137a8309d4b8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs` |
| 949 | `build/MilBridge/gen/tline-ledger-lines-20260919-1121.txt` | 2 | 5022622 | 1010 | `b3ad3e9b7812aff3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-1121.txt` |
| 950 | `build/MilBridge/gen/tline-ledger-lines-20260919-1136.txt` | 2 | 5022623 | 958 | `13e24de28a7f2a15` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260919-1136.txt` |
| 951 | `build/PresentationCore.Linux/HbTextLineShimSha.targets` | 2 | 5022639 | 5192 | `3127e82b76ce8c24` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/HbTextLineShimSha.targets` |
| 952 | `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | 2 | 5022651 | 209282 | `89fe3ca70f5c776f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/PresentationCore.Linux/PresentationCore.Linux.csproj` |
| 953 | `build/MilBridge/tests/ShimShaReader/ShimShaReader.csproj` | 2 | 5022660 | 2183 | `2c8b7779d686fdec` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ShimShaReader/ShimShaReader.csproj` |
| 954 | `build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj` | 2 | 5022662 | 4582 | `edf8452b097fa688` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj` |
| 955 | `build/MilBridge/gen/tline-ledger-lines-20260916-1851.txt` | 2 | 5022732 | 958 | `e7e3a8e6318ef0d8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260916-1851.txt` |
| 956 | `build/MilBridge/gen/tline-ledger-lines-20260916-1545.txt` | 2 | 5022940 | 958 | `49a5d5f274aea7e9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260916-1545.txt` |
| 957 | `build/MilBridge/tests/PcLineOracle/known-red.txt` | 2 | 5022974 | 17501 | `89324f1f643167e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/PcLineOracle/known-red.txt` |
| 958 | `build/DirectWrite.Linux/wic-shim/probe_describe.c` | 2 | 5023640 | 3433 | `02e88e0c6d203415` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_describe.c` |
| 959 | `build/DirectWrite.Linux/wic-shim/probe_describe` | 2 | 5023641 | 16368 | `ec95c5209b3cab97` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/probe_describe` |
| 960 | `build/MilBridge/gen/t2e-lineheight.txt` | 2 | 5023650 | 2618 | `a8bca445786c1397` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2e-lineheight.txt` |
| 961 | `build/MilBridge/gen/t2d-extent-mismatches.txt` | 2 | 5024319 | 105434 | `426cf85934666691` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2d-extent-mismatches.txt` |
| 962 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/MatrixCompositionSpaceTests.cs` | 2 | 5025334 | 9561 | `5d2fa7bfaa6e3b96` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/MatrixCompositionSpaceTests.cs` |
| 963 | `build/MilBridge/gen/tline-ledger-lines-20260914-0030.txt` | 2 | 5025631 | 1734 | `e208cc1953418905` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0030.txt` |
| 964 | `build/MilBridge/gen/tline-ledger-lines-20260914-0938.txt` | 2 | 5027232 | 1734 | `493223537c119d62` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0938.txt` |
| 965 | `build/MilBridge/gen/tline-ledger-lines-20260914-0945.txt` | 2 | 5027237 | 1734 | `493223537c119d62` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-0945.txt` |
| 966 | `build/MilBridge/gen/tline-ledger-lines-20260914-1827.txt` | 2 | 5027349 | 1734 | `9e5e555d26e8bdce` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1827.txt` |
| 967 | `build/MilBridge/gen/t2d-width-diff.txt` | 2 | 5027350 | 123815 | `7b4289ad3b56dbe3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2d-width-diff.txt` |
| 968 | `build/MilBridge/gen/tline-ledger-lines-20260914-1829.txt` | 2 | 5027351 | 1734 | `9e5e555d26e8bdce` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1829.txt` |
| 969 | `build/MilBridge/gen/tline-ledger-lines-20260914-1838.txt` | 2 | 5027352 | 4016 | `2f85e7a6af5e3c55` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1838.txt` |
| 970 | `build/MilBridge/gen/tline-ledger-lines-20260914-1839.txt` | 2 | 5027353 | 4016 | `2f85e7a6af5e3c55` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1839.txt` |
| 971 | `build/MilBridge/gen/tline-ledger-lines-20260914-1841.txt` | 2 | 5027366 | 4016 | `3d7a366deadafd23` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1841.txt` |
| 972 | `build/MilBridge/gen/tline-ledger-lines-20260914-1852.txt` | 2 | 5027377 | 4016 | `fe79b53b68e292db` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1852.txt` |
| 973 | `build/MilBridge/gen/tline-ledger-lines-20260914-1901.txt` | 2 | 5027397 | 28919 | `b1d8fbd3e4b84c3a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1901.txt` |
| 974 | `build/MilBridge/gen/tline-ledger-lines-20260914-1902.txt` | 2 | 5027398 | 6450 | `078b991eb8cbd032` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1902.txt` |
| 975 | `build/MilBridge/gen/tline-ledger-lines-20260914-1903.txt` | 2 | 5027399 | 4016 | `fe79b53b68e292db` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1903.txt` |
| 976 | `build/MilBridge/gen/tline-ledger-lines-20260914-1905.txt` | 2 | 5027400 | 4016 | `fe79b53b68e292db` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1905.txt` |
| 977 | `build/MilBridge/gen/tline-ledger-lines-20260914-1907.txt` | 2 | 5027401 | 1734 | `6912cb8bf6c96167` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1907.txt` |
| 978 | `build/MilBridge/gen/tline-ledger-lines-20260914-1908.txt` | 2 | 5027402 | 1734 | `ac835a7a3eac56e9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1908.txt` |
| 979 | `build/MilBridge/gen/tline-ledger-lines-20260914-1917.txt` | 2 | 5027406 | 1734 | `7a556b298c5e79a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1917.txt` |
| 980 | `build/MilBridge/gen/tline-ledger-lines-20260914-1918.txt` | 2 | 5027407 | 1734 | `7a556b298c5e79a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1918.txt` |
| 981 | `build/MilBridge/gen/tline-ledger-lines-20260914-1923.txt` | 2 | 5027572 | 1734 | `7a556b298c5e79a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1923.txt` |
| 982 | `build/MilBridge/gen/t2d-width-diff.provenance.txt` | 2 | 5027573 | 2034 | `30aaeae0174aa249` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2d-width-diff.provenance.txt` |
| 983 | `build/MilBridge/gen/tline-ledger-lines-20260914-1934.txt` | 2 | 5027574 | 1734 | `396cf5ea2a9b83cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1934.txt` |
| 984 | `build/MilBridge/gen/tline-ledger-lines-20260914-1937.txt` | 2 | 5027575 | 1734 | `9c5c29e5a20eccac` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1937.txt` |
| 985 | `build/MilBridge/gen/tline-ledger-lines-20260914-1945.txt` | 2 | 5027581 | 1734 | `9c5c29e5a20eccac` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1945.txt` |
| 986 | `build/MilBridge/gen/t2d-family-baseline.txt` | 2 | 5027602 | 486 | `d02dc5feb191f8e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2d-family-baseline.txt` |
| 987 | `build/MilBridge/gen/t2d-family-matrix.txt` | 2 | 5027603 | 703 | `4fcd3b23d8d288ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t2d-family-matrix.txt` |
| 988 | `build/MilBridge/gen/tline-ledger-lines-20260914-1958.txt` | 2 | 5027604 | 2360 | `fc24445ecf7a3666` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-1958.txt` |
| 989 | `build/MilBridge/gen/tline-ledger-lines-20260914-2021.txt` | 2 | 5027621 | 2360 | `acaa1b127719e19f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2021.txt` |
| 990 | `build/MilBridge/gen/tline-ledger-lines-20260914-2022.txt` | 2 | 5027631 | 1605 | `90a4d9cff35333cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2022.txt` |
| 991 | `build/MilBridge/gen/tline-ledger-lines-20260914-2023.txt` | 2 | 5027634 | 2360 | `c44758fd6c12b268` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2023.txt` |
| 992 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` | 2 | 5027646 | 15874 | `2618aed85a598d96` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` |
| 993 | `build/MilBridge/gen/tline-ledger-lines-20260914-2024.txt` | 2 | 5027647 | 2360 | `0ffc29e17691654f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2024.txt` |
| 994 | `build/MilBridge/gen/tline-ledger-lines-20260914-2025.txt` | 2 | 5027648 | 2360 | `0ffc29e17691654f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2025.txt` |
| 995 | `build/MilBridge/gen/tline-ledger-lines-20260914-2026.txt` | 2 | 5027649 | 1734 | `9c5c29e5a20eccac` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2026.txt` |
| 996 | `build/MilBridge/gen/t1b2-rowdump-final.txt` | 2 | 5027650 | 28481 | `1cae6e1e04688103` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/t1b2-rowdump-final.txt` |
| 997 | `build/MilBridge/gen/tline-ledger-lines-20260914-2027.txt` | 2 | 5027651 | 1604 | `e35a23888246e92d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2027.txt` |
| 998 | `build/MilBridge/gen/tline-ledger-lines-20260914-2028.txt` | 2 | 5027652 | 2359 | `2ad44c8786799974` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2028.txt` |
| 999 | `build/MilBridge/gen/tline-ledger-lines-20260914-2030.txt` | 2 | 5027653 | 2359 | `2ad44c8786799974` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2030.txt` |
| 1000 | `build/MilBridge/gen/tline-ledger-lines-20260914-2032.txt` | 2 | 5027654 | 1605 | `ddebeada2b9cc4fa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2032.txt` |
| 1001 | `build/MilBridge/gen/tline-ledger-lines-20260914-2033.txt` | 2 | 5027655 | 1605 | `1cd9016fd2869a73` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2033.txt` |
| 1002 | `build/MilBridge/gen/tline-ledger-lines-20260914-2034.txt` | 2 | 5027656 | 1605 | `e12769dc7aef4ff6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/gen/tline-ledger-lines-20260914-2034.txt` |
| 1003 | `build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs` | 2 | 5111872 | 206286 | `ebccdb1ee65e6f76` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs` |
| 1004 | `build/MilBridge/W52C2-report.md` | 2 | 5111873 | 26185 | `85cee85687487dd0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W52C2-report.md` |
| 1005 | `build/MilBridge/W52C-report.md` | 2 | 5111874 | 30846 | `c4d9a539cb63be56` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W52C-report.md` |
| 1006 | `build/MilBridge/W52C3-report.md` | 2 | 5111875 | 20049 | `31b9d1dc209e6c26` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W52C3-report.md` |
| 1007 | `build/MilBridge/tests/HbTextLineParity/Program.cs` | 5 | 5111935 | 129831 | `149dd986a642fdfc` | 是（4 条） | `/home/links-dev/w26d-G9/treeA/build/MilBridge/tests/HbTextLineParity/Program.cs`<br>`/home/links-dev/w26d-G9/treeB/build/MilBridge/tests/HbTextLineParity/Program.cs`<br>`/home/links-dev/w26d-G9/treeC/build/MilBridge/tests/HbTextLineParity/Program.cs`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tests/HbTextLineParity/Program.cs` |
| 1008 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/DpiScaleCompositionTests.cs` | 2 | 5112043 | 5222 | `c15ea89431700ccc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/DpiScaleCompositionTests.cs` |
| 1009 | `build/MilBridge/tests/CoverageProbe/refs/README.md` | 2 | 5112096 | 1467 | `5337b6bccb831cc3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/refs/README.md` |
| 1010 | `build/MilBridge/tests/CoverageProbe/known-red.txt` | 2 | 5112373 | 579 | `e37603a8825d85ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/known-red.txt` |
| 1011 | `samples/WpfTextDemo/BRIDGE-SRC-IDENTITY-GATE-20260914.md` | 2 | 5112374 | 10189 | `5d8dd1583c60bdcb` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/BRIDGE-SRC-IDENTITY-GATE-20260914.md` |
| 1012 | `src/WpfGfx.Linux/Commands/MilCommandLayout.cs` | 3 | 5112632 | 13707 | `d13821c359c30db9` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Commands/MilCommandLayout.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Commands/MilCommandLayout.cs` |
| 1013 | `build/DirectWrite.Linux/Directory.Build.targets` | 2 | 5113258 | 3587 | `dd081aebd7d926e4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Directory.Build.targets` |
| 1014 | `tests/parity/windows/bidi/out/bidi-oracle.json` | 2 | 5113268 | 159657 | `3453da98cca60452` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/out/bidi-oracle.json` |
| 1015 | `tests/parity/windows/bidi/out/bidi-oracle.txt` | 2 | 5113273 | 6216 | `0b9fefc21ad6fd76` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/out/bidi-oracle.txt` |
| 1016 | `tests/parity/windows/bidi/src/Program.cs` | 2 | 5113274 | 19966 | `3929137212cd9121` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/src/Program.cs` |
| 1017 | `tests/parity/windows/bidi/src/BidiOracle.csproj` | 2 | 5113275 | 443 | `9a3bccd0fc9edeb7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/src/BidiOracle.csproj` |
| 1018 | `tests/parity/windows/bidi/src/run.ps1` | 2 | 5113276 | 724 | `d3ae9d9123aac81b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/src/run.ps1` |
| 1019 | `tests/parity/windows/bidi/PROVENANCE.md` | 2 | 5113392 | 8808 | `abbfd77ce6f3128f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/bidi/PROVENANCE.md` |
| 1020 | `build/third-party/WpfLinux.props` | 2 | 5113533 | 10020 | `bdc3954b4a129112` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/third-party/WpfLinux.props` |
| 1021 | `build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj` | 2 | 5117502 | 2357 | `0cd720008d3ddf4f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/IcuBreakParity/IcuBreakParity.csproj` |
| 1022 | `build/MilBridge/tests/IcuBreakParity/Program.cs` | 2 | 5117524 | 16273 | `1b2815e197638a23` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/IcuBreakParity/Program.cs` |
| 1023 | `docs/WAVE17-PREREGISTRATION.md` | 2 | 5126478 | 50387 | `d2ecf2b9e82e2a78` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE17-PREREGISTRATION.md` |
| 1024 | `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` | 2 | 5126519 | 24148 | `93f914d6c041c88d` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` |
| 1025 | `src/WpfGfx.Linux.Native/src/win32_pts.c` | 2 | 5126520 | 13404 | `e6559d0bba3c1044` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_pts.c` |
| 1026 | `build/MilBridge/tests/ShimShaReader/Program.cs` | 2 | 5126741 | 17872 | `0ef57677afef9f6d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ShimShaReader/Program.cs` |
| 1027 | `build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` | 2 | 5126903 | 24508 | `c68a3a474119b36c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/known-red-PFWB-copies.md` |
| 1028 | `docs/WAVE49-PREREGISTRATION.md` | 2 | 5127028 | 124652 | `7f77e932d92d379a` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE49-PREREGISTRATION.md` |
| 1029 | `tests/parity/windows/layout-b34/evidence-cd2.py` | 2 | 5127891 | 8748 | `dfb54c6b0949c4c8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/evidence-cd2.py` |
| 1030 | `build/MilBridge/tools/extract-layout-b34.py` | 2 | 5129783 | 6363 | `17e70c2438f1882d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/extract-layout-b34.py` |
| 1031 | `build/MilBridge/tests/DirectBranchCheck/DirectBranchCheck.csproj` | 2 | 5129797 | 3354 | `40236656223e9619` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/DirectBranchCheck/DirectBranchCheck.csproj` |
| 1032 | `build/MilBridge/tests/DirectBranchCheck/Probe.cs` | 2 | 5129807 | 3490 | `301e1d7efd04a00c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/DirectBranchCheck/Probe.cs` |
| 1033 | `tests/parity/windows/layout-b34/PROVENANCE.md` | 2 | 5130330 | 16465 | `2e516bc1163b522b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/PROVENANCE.md` |
| 1034 | `build/MilBridge/tools/analyze-layout-b34.py` | 2 | 5130530 | 10692 | `c6f1f4c24cbcdbae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/analyze-layout-b34.py` |
| 1035 | `build/MilBridge/W17A-report.md` | 2 | 5130558 | 36241 | `19f6fe04d165cfd9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W17A-report.md` |
| 1036 | `build/MilBridge/W17B-report.md` | 2 | 5131642 | 41116 | `995595e2487a94e7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W17B-report.md` |
| 1037 | `build/MilBridge/tests/MinMaxProbe/MinMaxProbe.csproj` | 2 | 5131714 | 3933 | `69d7f19ca70c0a90` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/MinMaxProbe/MinMaxProbe.csproj` |
| 1038 | `build/MilBridge/tests/MinMaxProbe/Program.cs` | 2 | 5131809 | 20528 | `cfcf464457163280` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/MinMaxProbe/Program.cs` |
| 1039 | `build/MilBridge/W17D-report.md` | 2 | 5131889 | 31508 | `cfa5b12a813f807f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W17D-report.md` |
| 1040 | `tests/parity/windows/layout-b34/evidence-cd1.py` | 2 | 5132301 | 9883 | `1ab7ff79fdf2af20` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/layout-b34/evidence-cd1.py` |
| 1041 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py` | 3 | 5133174 | 18345 | `81f821ae225eb3a0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py` |
| 1042 | `docs/WAVE18-PREREGISTRATION.md` | 2 | 5133886 | 17498 | `dbea3237d2edf950` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE18-PREREGISTRATION.md` |
| 1043 | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | 2 | 5133897 | 24970 | `76caccc4693bf4a1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ResolverGuardProbe/Program.cs` |
| 1044 | `build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj` | 2 | 5133898 | 2630 | `ece22ef0afc8b176` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj` |
| 1045 | `src/WpfGfx.Linux/Windowing/X11Native.cs` | 3 | 5134002 | 17068 | `8ede4d8a13cb3a28` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/X11Native.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/X11Native.cs` |
| 1046 | `build/shims/Win32ShimResolver.cs` | 3 | 5134003 | 35815 | `670d4e37592c3a64` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/shims/Win32ShimResolver.cs`<br>`/home/links-dev/w62a/negrepo/build/shims/Win32ShimResolver.cs` |
| 1047 | `build/DirectWrite.Linux/WicClosedLoop/Program.cs` | 2 | 5134004 | 28709 | `f7c7fd61ef5c8ad8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/WicClosedLoop/Program.cs` |
| 1048 | `build/MilBridge/V18A-report.md` | 2 | 5134642 | 58346 | `2d7809699ebf51d4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/V18A-report.md` |
| 1049 | `src/WpfGfx.Linux/Rendering/SkiaBrush.cs` | 3 | 5134752 | 50837 | `a5594f886565fcdc` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaBrush.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaBrush.cs` |
| 1050 | `src/WpfGfx.Linux/Rendering/RenderDiagnostics.cs` | 3 | 5134854 | 5459 | `4701416fa8e4b536` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/RenderDiagnostics.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/RenderDiagnostics.cs` |
| 1051 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/VisualBrushWiringTests.cs` | 2 | 5134975 | 12504 | `28b5ce48dd14cd6b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/VisualBrushWiringTests.cs` |
| 1052 | `build/MilBridge/W51A-report.md` | 2 | 5135207 | 25644 | `24e562b723757b52` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W51A-report.md` |
| 1053 | `build/MilBridge/tools/t1b-ls-selftest.c` | 2 | 5135226 | 3505 | `936fda22bfe2f092` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1b-ls-selftest.c` |
| 1054 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo-minrepro.sh` | 2 | 5135263 | 2318 | `7dcc120e351f5fe8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo-minrepro.sh` |
| 1055 | `docs/WAVE19-PREREGISTRATION.md` | 2 | 5135654 | 15502 | `9e900975e18bc2ca` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE19-PREREGISTRATION.md` |
| 1056 | `build/MilBridge/tests/LsProbe/LsProbe.csproj` | 2 | 5136274 | 1195 | `a62cd5acb8cde57a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/LsProbe/LsProbe.csproj` |
| 1057 | `build/MilBridge/tests/LsProbe/Program.cs` | 2 | 5136275 | 978 | `b8dba8fbbc05a327` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/LsProbe/Program.cs` |
| 1058 | `build/MilBridge/W19A-report.md` | 2 | 5136517 | 43450 | `699cc39187268297` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W19A-report.md` |
| 1059 | `build/MilBridge/W19B-report.md` | 2 | 5136542 | 34024 | `da1d5fe7f55adfb6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W19B-report.md` |
| 1060 | `build/MilBridge/tools/t1b-live-window.sh` | 2 | 5136554 | 4313 | `2e81b4c6e6c08e20` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1b-live-window.sh` |
| 1061 | `docs/WAVE39-PREREGISTRATION.md` | 2 | 5136767 | 16127 | `ace9bc6c9d179482` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE39-PREREGISTRATION.md` |
| 1062 | `build/selfbuilt-config.sh` | 2 | 5136770 | 6661 | `1cc47960f8ea79ed` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/selfbuilt-config.sh` |
| 1063 | `build/MilBridge/tools/frame-step.sh` | 2 | 5136779 | 15162 | `67583d58b2eacddb` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/frame-step.sh` |
| 1064 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/TileFlipTruthTests.cs` | 2 | 5137392 | 33369 | `269d95275f29a3b1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/TileFlipTruthTests.cs` |
| 1065 | `src/WpfGfx.Linux.Native/tools/patch-uiautomationtypes-reservedvalue.py` | 3 | 5137415 | 12252 | `4313c3b6812844f0` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-uiautomationtypes-reservedvalue.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-uiautomationtypes-reservedvalue.py` |
| 1066 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/BitmapScalingModeTruthTests.cs` | 2 | 5137429 | 17255 | `17504b913e403734` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/BitmapScalingModeTruthTests.cs` |
| 1067 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/GlyphRunCensusTests.cs` | 2 | 5137650 | 15845 | `94bd6452e5b64a15` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/GlyphRunCensusTests.cs` |
| 1068 | `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py` | 3 | 5137660 | 66916 | `5203f958c234882f` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py` |
| 1069 | `build/MilBridge/W48A-report.md` | 2 | 5137661 | 39829 | `422c1c643a9ccfe7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W48A-report.md` |
| 1070 | `docs/WAVE20-PREREGISTRATION.md` | 2 | 5137666 | 11618 | `cc450f731caf1f92` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE20-PREREGISTRATION.md` |
| 1071 | `src/WpfGfx.Linux.Native/tools/patch-presentationframework-mirror-trace.py` | 3 | 5137671 | 30630 | `1b9852b037da70f1` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationframework-mirror-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationframework-mirror-trace.py` |
| 1072 | `build/MilBridge/tools/t1c-census-summary.py` | 2 | 5138083 | 6067 | `5782b7316e158659` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1c-census-summary.py` |
| 1073 | `build/MilBridge/tests/StrictTierProbe/StrictTierProbe.csproj` | 2 | 5138097 | 3678 | `33a0d318dfb0e76a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/StrictTierProbe/StrictTierProbe.csproj` |
| 1074 | `build/MilBridge/tools/t1c-census.sh` | 2 | 5138192 | 19449 | `5eac3bda23b117b6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1c-census.sh` |
| 1075 | `build/MilBridge/tests/CoverageProbe/ProbeIdentity.targets` | 2 | 5138258 | 3912 | `75b9ce4beaab763e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/ProbeIdentity.targets` |
| 1076 | `build/MilBridge/tests/CoverageProbe/Program.cs` | 2 | 5138259 | 143827 | `a6d0352b86467111` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/Program.cs` |
| 1077 | `build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj` | 2 | 5138261 | 5745 | `59abb3e2b9e268c4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj` |
| 1078 | `src/WpfGfx.Linux/Resources/MilChannel.cs` | 2 | 5138290 | 42809 | `24f3028f84426165` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Resources/MilChannel.cs` |
| 1079 | `build/MilBridge/tests/StrictTierProbe/Program.cs` | 2 | 5138495 | 23557 | `d628ce429240b37c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/StrictTierProbe/Program.cs` |
| 1080 | `build/MilBridge/W20B-report.md` | 2 | 5138583 | 30425 | `ff9e599897f9c90a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W20B-report.md` |
| 1081 | `docs/history/WAVE32-PREREGISTRATION.md` | 2 | 5138840 | 10069 | `ab8dcb2028df0ddf` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/history/WAVE32-PREREGISTRATION.md` |
| 1082 | `build/MilBridge/W20A-report.md` | 2 | 5138872 | 41129 | `3a51800d36bb7007` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W20A-report.md` |
| 1083 | `build/DirectWrite.Linux/Provider/FamilyCoverageSelfTest.cs` | 2 | 5138890 | 22864 | `795d1ab4b573eb91` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/Provider/FamilyCoverageSelfTest.cs` |
| 1084 | `build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj` | 2 | 5138892 | 2208 | `ea184312d841d816` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj` |
| 1085 | `build/MilBridge/tests/FamilyCoverageSelfTest/Program.cs` | 2 | 5138894 | 6565 | `4b26026218835449` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/FamilyCoverageSelfTest/Program.cs` |
| 1086 | `build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj` | 2 | 5138976 | 2695 | `19462bb2c966de2f` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/T2eLineHeight/T2eLineHeight.csproj` |
| 1087 | `build/MilBridge/tests/T2eLineHeight/Program.cs` | 2 | 5139058 | 10574 | `26abfba8bbd1ac17` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/T2eLineHeight/Program.cs` |
| 1088 | `build/MilBridge/arm-logs/README.md` | 2 | 5139643 | 7282 | `7de8a8cb069be60a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/arm-logs/README.md` |
| 1089 | `build/MilBridge/W48D-report.md` | 2 | 5139727 | 33693 | `ffa4de4a47d4078a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W48D-report.md` |
| 1090 | `build/MilBridge/tests/BboxProbe/BboxProbe.csproj` | 2 | 5140038 | 1248 | `2379f34e6931ebe6` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/BboxProbe/BboxProbe.csproj` |
| 1091 | `BuildHygiene.props` | 2 | 5140081 | 4766 | `3a5fd92cd1331f36` | 是（1 条） | `/home/links-dev/w62a/negrepo/BuildHygiene.props` |
| 1092 | `build/MilBridge/W21D-report.md` | 2 | 5140182 | 89937 | `c473dfc1dcbff583` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W21D-report.md` |
| 1093 | `build/MilBridge/W21C-report.md` | 2 | 5140233 | 55649 | `0dd5cf70f7e5d673` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W21C-report.md` |
| 1094 | `build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` | 2 | 5140316 | 4883 | `6113515a5519f74b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` |
| 1095 | `build/MilBridge/tests/TextLineProto/TextLineProto.csproj` | 2 | 5140317 | 4068 | `db91b8670168e284` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/TextLineProto/TextLineProto.csproj` |
| 1096 | `build/MilBridge/tests/PcLineOracle/Program.cs` | 2 | 5140408 | 113209 | `a787a9db23c3302c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/PcLineOracle/Program.cs` |
| 1097 | `build/MilBridge/W49A-report.md` | 2 | 5140442 | 23350 | `461fd983f85551ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W49A-report.md` |
| 1098 | `build/MilBridge/tools/t1d-probe.sh` | 2 | 5140600 | 5191 | `3cda4dea032361c1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1d-probe.sh` |
| 1099 | `build/MilBridge/W21A-report.md` | 2 | 5141084 | 43641 | `b6865b2409091298` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W21A-report.md` |
| 1100 | `docs/WAVE21-PREREGISTRATION.md` | 2 | 5141086 | 48047 | `64502b036b7a8b42` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE21-PREREGISTRATION.md` |
| 1101 | `build/MilBridge/tools/retake-arms-w21.sh` | 2 | 5141088 | 3109 | `b952cdd66466e73e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/retake-arms-w21.sh` |
| 1102 | `build/MilBridge/tools/pc-line-step.sh` | 2 | 5141092 | 5921 | `a6a2f0fc1b40783e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/pc-line-step.sh` |
| 1103 | `build/MilBridge/W50A-report.md` | 2 | 5141248 | 45056 | `680b4c2812b1014e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W50A-report.md` |
| 1104 | `build/MilBridge/W51B-report.md` | 2 | 5141271 | 29084 | `e0880bf44c189b31` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W51B-report.md` |
| 1105 | `src/WpfGfx.Linux.Native/src/win32_msg.c` | 2 | 5142095 | 55506 | `4ad790f4c26a907c` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_msg.c` |
| 1106 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | 2 | 5142099 | 35015 | `e4f2de8d038e4780` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_internal.h` |
| 1107 | `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py` | 2 | 5142111 | 16146 | `ce76657c1b020562` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py` |
| 1108 | `docs/WAVE22-PREREGISTRATION.md` | 2 | 5142273 | 53939 | `72655c84db6f12b5` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE22-PREREGISTRATION.md` |
| 1109 | `build/MilBridge/tests/FrameProbe/FrameProbe.csproj` | 2 | 5142294 | 4715 | `a9ef8d1e1c8a95e4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/FrameProbe/FrameProbe.csproj` |
| 1110 | `build/MilBridge/W22A-report.md` | 2 | 5142456 | 32230 | `72586d4a85883022` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W22A-report.md` |
| 1111 | `build/MilBridge/W22D-report.md` | 2 | 5142557 | 51063 | `44461001f9d10eaa` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W22D-report.md` |
| 1112 | `build/MilBridge/W22B-report.md` | 2 | 5142597 | 34467 | `c98c71f106fec8d7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W22B-report.md` |
| 1113 | `build/MilBridge/W22C-report.md` | 2 | 5142673 | 46497 | `93d66fa348ddbb3a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W22C-report.md` |
| 1114 | `docs/WAVE23-PREREGISTRATION.md` | 2 | 5142688 | 58952 | `7aca2f1f6a064004` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE23-PREREGISTRATION.md` |
| 1115 | `build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj` | 2 | 5142702 | 4595 | `956549f11282a18b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj` |
| 1116 | `build/MilBridge/W23C-report.md` | 2 | 5142859 | 32129 | `b6601b828475a636` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W23C-report.md` |
| 1117 | `build/MilBridge/W23D-report.md` | 2 | 5142928 | 54848 | `91e98f471efed019` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W23D-report.md` |
| 1118 | `build/MilBridge/tests/D5CbrProbe/Program.cs` | 2 | 5143146 | 38405 | `92694cf0c9c5d392` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/D5CbrProbe/Program.cs` |
| 1119 | `build/MilBridge/W23A-report.md` | 2 | 5143812 | 38468 | `4eb5c407d5d0948a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W23A-report.md` |
| 1120 | `build/MilBridge/W23B-report.md` | 2 | 5143816 | 31861 | `1e65c548ac3d0ad7` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W23B-report.md` |
| 1121 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-lineheight-trace.py` | 3 | 5144765 | 19435 | `4eccc308340a7c23` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-lineheight-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-lineheight-trace.py` |
| 1122 | `src/WpfGfx.Linux.Native/src/win32_gdiplus.c` | 3 | 5145034 | 15660 | `892d021b9ea14f1c` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/src/win32_gdiplus.c`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/src/win32_gdiplus.c` |
| 1123 | `build/MilBridge/tools/gdiplus-decode-probe.c` | 2 | 5145035 | 6774 | `ef1c8baffd585a59` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/gdiplus-decode-probe.c` |
| 1124 | `build/MilBridge/tools/gdiplus-decode-check.sh` | 2 | 5145039 | 3724 | `663be6e596fd1b8d` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/gdiplus-decode-check.sh` |
| 1125 | `docs/WAVE41-PREREGISTRATION.md` | 2 | 5145042 | 6319 | `a0319e8212d4b82c` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE41-PREREGISTRATION.md` |
| 1126 | `docs/WAVE24-PREREGISTRATION.md` | 2 | 5146069 | 53666 | `412412e30b349099` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE24-PREREGISTRATION.md` |
| 1127 | `build/MilBridge/tools/repin-generation.py` | 2 | 5146168 | 5413 | `a2ca0a26bf99dc7a` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/repin-generation.py` |
| 1128 | `build/MilBridge/tests/TabGapProbe/TabGapProbe.csproj` | 2 | 5146199 | 4016 | `49598e9131df8277` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/TabGapProbe/TabGapProbe.csproj` |
| 1129 | `build/MilBridge/tests/TabGapProbe/Program.cs` | 2 | 5146201 | 9298 | `b06b4bfc4c09dc7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/TabGapProbe/Program.cs` |
| 1130 | `docs/WAVE42-PREREGISTRATION.md` | 2 | 5146203 | 7960 | `11aee5e3f27fa049` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE42-PREREGISTRATION.md` |
| 1131 | `build/MilBridge/tests/FrameProbe/Program.cs` | 2 | 5146464 | 43380 | `503e6ebd86d70303` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/FrameProbe/Program.cs` |
| 1132 | `build/MilBridge/W24D-report.md` | 2 | 5146529 | 36537 | `484738db104b56f2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W24D-report.md` |
| 1133 | `build/MilBridge/W24A-report.md` | 2 | 5147132 | 33697 | `4b517c6e8d1f76e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W24A-report.md` |
| 1134 | `build/MilBridge/known-red-frame-structural.md` | 2 | 5148534 | 15212 | `ab09235afd949bc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/known-red-frame-structural.md` |
| 1135 | `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` | 2 | 5148544 | 25656 | `3c9e3a309b990d31` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` |
| 1136 | `build/MilBridge/W25C-report.md` | 2 | 5148568 | 23244 | `0dac420628c926c8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W25C-report.md` |
| 1137 | `docs/WAVE25-PREREGISTRATION.md` | 2 | 5148571 | 24747 | `ad7691326e66846a` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE25-PREREGISTRATION.md` |
| 1138 | `build/MilBridge/W25B-report.md` | 2 | 5148590 | 24955 | `fb7469b4bc107312` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W25B-report.md` |
| 1139 | `build/MilBridge/W25A-report.md` | 2 | 5148676 | 38273 | `2bb495e622b9ec19` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W25A-report.md` |
| 1140 | `docs/UPSTREAM-PROVENANCE.md` | 2 | 5149371 | 27126 | `5fcf0c989165eb4d` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/UPSTREAM-PROVENANCE.md` |
| 1141 | `build/MilBridge/W26D-report.md` | 2 | 5149772 | 36891 | `491fd9f8def6d2d8` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W26D-report.md` |
| 1142 | `build/MilBridge/W26B-report.md` | 2 | 5149935 | 33036 | `209deb193af68ef4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W26B-report.md` |
| 1143 | `build/MilBridge/W26C-report.md` | 2 | 5149983 | 20717 | `f58dcba766731ebe` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W26C-report.md` |
| 1144 | `build/MilBridge/W26A-report.md` | 2 | 5150129 | 25464 | `5244e218631572ee` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W26A-report.md` |
| 1145 | `build/MilBridge/tools/tab-gap-check.sh` | 2 | 5151736 | 7629 | `d5289956570e5519` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/tab-gap-check.sh` |
| 1146 | `build/MilBridge/tools/tabgap-display-polarity.sh` | 2 | 5151741 | 7855 | `c5cb6642980828ad` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/tabgap-display-polarity.sh` |
| 1147 | `docs/THIRD-PARTY-APPS.md` | 2 | 5151747 | 11472 | `8fd407fda70bdacb` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/THIRD-PARTY-APPS.md` |
| 1148 | `docs/WAVE43-PREREGISTRATION.md` | 2 | 5152078 | 25355 | `4b02f005a6c1ea22` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE43-PREREGISTRATION.md` |
| 1149 | `.gitattributes` | 2 | 5152307 | 1923 | `fc2a35f6a24b6116` | 是（1 条） | `/home/links-dev/w62a/negrepo/.gitattributes` |
| 1150 | `docs/WAVE46-CLOSEOUT-RUNBOOK.md` | 2 | 5153143 | 65442 | `9dd8f4c1e116c571` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE46-CLOSEOUT-RUNBOOK.md` |
| 1151 | `docs/WAVE46-DG54-CRITERIA.md` | 2 | 5153145 | 13586 | `73cf7f9057630a55` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE46-DG54-CRITERIA.md` |
| 1152 | `src/WpfGfx.Linux/Interop/MilNative.cs` | 3 | 5153158 | 34616 | `e1d7bfa0fd03a01f` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilNative.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilNative.cs` |
| 1153 | `docs/WAVE46-PERTARGET-PRESENT-DESIGN.md` | 2 | 5153160 | 47451 | `9486f38c9a3d4898` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE46-PERTARGET-PRESENT-DESIGN.md` |
| 1154 | `src/WpfGfx.Linux/Interop/MilPresentation.cs` | 3 | 5153161 | 80195 | `8b44b61f944aeeaa` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Interop/MilPresentation.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Interop/MilPresentation.cs` |
| 1155 | `tests/parity/brushes/src/Cases.cs` | 2 | 5242886 | 29227 | `726918496ea91d21` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/src/Cases.cs` |
| 1156 | `tests/parity/brushes/src/Json.cs` | 2 | 5242887 | 5041 | `11abc6115b41cc47` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/src/Json.cs` |
| 1157 | `tests/parity/brushes/src/Program.cs` | 2 | 5242888 | 57770 | `c60e7f01802ea3d2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/src/Program.cs` |
| 1158 | `tests/parity/brushes/src/Sources.cs` | 2 | 5242889 | 9587 | `57fe24996ce19cd0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/src/Sources.cs` |
| 1159 | `tests/parity/brushes/cases.json` | 2 | 5242970 | 49724 | `7e1c61eef3db779b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/cases.json` |
| 1160 | `tests/parity/brushes/windows-results.json` | 2 | 5242971 | 6639160 | `dda7486bda2f9d21` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/windows-results.json` |
| 1161 | `tests/parity/brushes/src/U1BrushOracle.csproj` | 2 | 5242972 | 798 | `c9ad13afcd77c306` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/src/U1BrushOracle.csproj` |
| 1162 | `samples/WpfFeatureProbe/rtl-baseline-20260913.json` | 2 | 5243023 | 11514 | `9ef12be68c9343f1` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-baseline-20260913.json` |
| 1163 | `tests/parity/brushes/out/alpha_flipx_v2tiling_opaque_bg.png` | 2 | 5243036 | 5547 | `38cf844f2c470998` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/alpha_flipx_v2tiling_opaque_bg.png` |
| 1164 | `tests/parity/brushes/out/alpha_flipy_v2tiling_transparent_bg.png` | 2 | 5243037 | 4652 | `839cb1e295a82439` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/alpha_flipy_v2tiling_transparent_bg.png` |
| 1165 | `tests/parity/brushes/out/alpha_tile_v2tiling_opaque_bg.png` | 2 | 5243038 | 4914 | `3d5ebf9dbda2c9dc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/alpha_tile_v2tiling_opaque_bg.png` |
| 1166 | `tests/parity/brushes/out/alpha_tile_v2tiling_transparent_bg.png` | 2 | 5243039 | 5245 | `0310fe01d8f2b5a6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/alpha_tile_v2tiling_transparent_bg.png` |
| 1167 | `tests/parity/brushes/out/core_drawing_flipx_v1same.png` | 2 | 5243040 | 1388 | `6c8a1092c8ffd0bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipx_v1same.png` |
| 1168 | `tests/parity/brushes/out/core_drawing_flipx_v2tiling.png` | 2 | 5243041 | 2207 | `ed4b7b4dbc473e40` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipx_v2tiling.png` |
| 1169 | `tests/parity/brushes/out/core_drawing_flipx_v3offset.png` | 2 | 5243042 | 2150 | `91f9a074264d74f7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipx_v3offset.png` |
| 1170 | `tests/parity/brushes/out/core_drawing_flipxy_v1same.png` | 2 | 5243043 | 1388 | `6c8a1092c8ffd0bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipxy_v1same.png` |
| 1171 | `tests/parity/brushes/out/core_drawing_flipxy_v2tiling.png` | 2 | 5243044 | 2104 | `a81736366dff8311` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipxy_v2tiling.png` |
| 1172 | `tests/parity/brushes/out/core_drawing_flipxy_v3offset.png` | 2 | 5243045 | 2147 | `1daf0793d50c5829` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipxy_v3offset.png` |
| 1173 | `tests/parity/brushes/out/core_drawing_flipy_v1same.png` | 2 | 5243046 | 1388 | `6c8a1092c8ffd0bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipy_v1same.png` |
| 1174 | `tests/parity/brushes/out/core_drawing_flipy_v2tiling.png` | 2 | 5243047 | 1916 | `1a3bf23a621d5767` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipy_v2tiling.png` |
| 1175 | `tests/parity/brushes/out/core_drawing_flipy_v3offset.png` | 2 | 5243048 | 1936 | `ff9a23171c6236fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_flipy_v3offset.png` |
| 1176 | `tests/parity/brushes/out/core_drawing_none_v1same.png` | 2 | 5243049 | 1388 | `6c8a1092c8ffd0bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_none_v1same.png` |
| 1177 | `tests/parity/brushes/out/core_drawing_none_v2tiling.png` | 2 | 5243050 | 1238 | `8edb8840844cb5fc` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_none_v2tiling.png` |
| 1178 | `tests/parity/brushes/out/core_drawing_none_v3offset.png` | 2 | 5243051 | 1245 | `fd4cfdea6e5b2dab` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_none_v3offset.png` |
| 1179 | `tests/parity/brushes/out/core_drawing_tile_v1same.png` | 2 | 5243052 | 1388 | `6c8a1092c8ffd0bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_tile_v1same.png` |
| 1180 | `tests/parity/brushes/out/core_drawing_tile_v2tiling.png` | 2 | 5243053 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_tile_v2tiling.png` |
| 1181 | `tests/parity/brushes/out/core_drawing_tile_v3offset.png` | 2 | 5243054 | 1882 | `4b1041fa3d7fd8c1` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_drawing_tile_v3offset.png` |
| 1182 | `tests/parity/brushes/out/core_image_flipx_v1same.png` | 2 | 5243055 | 4024 | `0674799233914b82` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipx_v1same.png` |
| 1183 | `tests/parity/brushes/out/core_image_flipx_v2tiling.png` | 2 | 5243056 | 6296 | `ab170f8d59ee022c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipx_v2tiling.png` |
| 1184 | `tests/parity/brushes/out/core_image_flipx_v3offset.png` | 2 | 5243057 | 5509 | `b317baec1e5d9e35` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipx_v3offset.png` |
| 1185 | `tests/parity/brushes/out/core_image_flipxy_v1same.png` | 2 | 5243058 | 3820 | `44bb49b7d199ce58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipxy_v1same.png` |
| 1186 | `tests/parity/brushes/out/core_image_flipxy_v2tiling.png` | 2 | 5243059 | 5565 | `ca468d5868be4629` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipxy_v2tiling.png` |
| 1187 | `tests/parity/brushes/out/core_image_flipxy_v3offset.png` | 2 | 5243060 | 5348 | `8a19ec3197b9a3f4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipxy_v3offset.png` |
| 1188 | `tests/parity/brushes/out/core_image_flipy_v1same.png` | 2 | 5243061 | 3955 | `46b9b4f52511b9dd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipy_v1same.png` |
| 1189 | `tests/parity/brushes/out/core_image_flipy_v2tiling.png` | 2 | 5243062 | 4966 | `def95c0e1156f764` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipy_v2tiling.png` |
| 1190 | `tests/parity/brushes/out/core_image_flipy_v3offset.png` | 2 | 5243063 | 4967 | `45193d217b531ebf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_flipy_v3offset.png` |
| 1191 | `tests/parity/brushes/out/core_image_none_v1same.png` | 2 | 5243064 | 3820 | `44bb49b7d199ce58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_none_v1same.png` |
| 1192 | `tests/parity/brushes/out/core_image_none_v2tiling.png` | 2 | 5243065 | 1956 | `55659da5f00bb6e5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_none_v2tiling.png` |
| 1193 | `tests/parity/brushes/out/core_image_none_v3offset.png` | 2 | 5243066 | 1978 | `903f85b96673fbf5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_none_v3offset.png` |
| 1194 | `tests/parity/brushes/out/core_image_tile_v1same.png` | 2 | 5243067 | 4221 | `5457e9f5c4bb19bd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_tile_v1same.png` |
| 1195 | `tests/parity/brushes/out/core_image_tile_v2tiling.png` | 2 | 5243068 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_tile_v2tiling.png` |
| 1196 | `tests/parity/brushes/out/core_image_tile_v3offset.png` | 2 | 5243069 | 4969 | `0af132b5b795fb20` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/core_image_tile_v3offset.png` |
| 1197 | `tests/parity/brushes/out/frac_drawing_flipx_v2tiling.png` | 2 | 5243070 | 7322 | `4c7163a408a36b9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/frac_drawing_flipx_v2tiling.png` |
| 1198 | `tests/parity/brushes/out/frac_image_flipx_v2tiling.png` | 2 | 5243071 | 7642 | `878a6b5032dab51c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/frac_image_flipx_v2tiling.png` |
| 1199 | `tests/parity/brushes/out/frac_image_none_v1same.png` | 2 | 5243072 | 4116 | `7fcc08f51d838231` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/frac_image_none_v1same.png` |
| 1200 | `tests/parity/brushes/out/frac_image_tile_v2tiling.png` | 2 | 5243073 | 8090 | `44d6c6c391261142` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/frac_image_tile_v2tiling.png` |
| 1201 | `tests/parity/brushes/out/stretch_fill_center_v1same.png` | 2 | 5243074 | 3820 | `44bb49b7d199ce58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_fill_center_v1same.png` |
| 1202 | `tests/parity/brushes/out/stretch_fill_center_v2tile.png` | 2 | 5243075 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_fill_center_v2tile.png` |
| 1203 | `tests/parity/brushes/out/stretch_fill_left_v1same.png` | 2 | 5243076 | 3820 | `44bb49b7d199ce58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_fill_left_v1same.png` |
| 1204 | `tests/parity/brushes/out/stretch_fill_left_v2tile.png` | 2 | 5243077 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_fill_left_v2tile.png` |
| 1205 | `tests/parity/brushes/out/stretch_none_center_v1same.png` | 2 | 5243078 | 1111 | `b0daa92b29513e65` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_none_center_v1same.png` |
| 1206 | `tests/parity/brushes/out/stretch_none_center_v2tile.png` | 2 | 5243079 | 1598 | `394bfadce461fc57` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_none_center_v2tile.png` |
| 1207 | `tests/parity/brushes/out/stretch_none_left_v1same.png` | 2 | 5243080 | 1118 | `9935b7379c2b4fc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_none_left_v1same.png` |
| 1208 | `tests/parity/brushes/out/stretch_none_left_v2tile.png` | 2 | 5243081 | 1649 | `8a0e7c6771c90f4e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_none_left_v2tile.png` |
| 1209 | `tests/parity/brushes/out/stretch_uniform_center_v1same.png` | 2 | 5243082 | 3194 | `a20b0ea07d981e4a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniform_center_v1same.png` |
| 1210 | `tests/parity/brushes/out/stretch_uniform_center_v2tile.png` | 2 | 5243083 | 3975 | `b47f77cf5af50968` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniform_center_v2tile.png` |
| 1211 | `tests/parity/brushes/out/stretch_uniform_left_v1same.png` | 2 | 5243084 | 3189 | `430af1770daa0d5a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniform_left_v1same.png` |
| 1212 | `tests/parity/brushes/out/stretch_uniform_left_v2tile.png` | 2 | 5243085 | 4075 | `21360d26db490726` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniform_left_v2tile.png` |
| 1213 | `tests/parity/brushes/out/stretch_uniformtofill_center_v1same.png` | 2 | 5243086 | 4209 | `5ef58ac17db3cbc9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniformtofill_center_v1same.png` |
| 1214 | `tests/parity/brushes/out/stretch_uniformtofill_center_v2tile.png` | 2 | 5243087 | 3808 | `149f4a4c08821fad` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniformtofill_center_v2tile.png` |
| 1215 | `tests/parity/brushes/out/stretch_uniformtofill_left_v1same.png` | 2 | 5243088 | 4477 | `c33b73a025432d6b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniformtofill_left_v1same.png` |
| 1216 | `tests/parity/brushes/out/stretch_uniformtofill_left_v2tile.png` | 2 | 5243089 | 4020 | `e47c4737fd66f323` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/stretch_uniformtofill_left_v2tile.png` |
| 1217 | `tests/parity/brushes/out/units_drawing_viewbox_subregion_2x_flipx.png` | 2 | 5243090 | 1168 | `1c38c96b0042c7a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/units_drawing_viewbox_subregion_2x_flipx.png` |
| 1218 | `tests/parity/brushes/out/units_viewbox_subregion_2x_tile.png` | 2 | 5243091 | 2821 | `dea11e10e27375b2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/units_viewbox_subregion_2x_tile.png` |
| 1219 | `tests/parity/brushes/out/units_vpabs_viewboxabs_tile.png` | 2 | 5243092 | 5018 | `f671fc6ab10e66b9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/units_vpabs_viewboxabs_tile.png` |
| 1220 | `tests/parity/brushes/out/units_vpabs_viewboxrel_tile.png` | 2 | 5243093 | 5018 | `f671fc6ab10e66b9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/units_vpabs_viewboxrel_tile.png` |
| 1221 | `tests/parity/brushes/out/units_vprel_viewboxrel_flipx.png` | 2 | 5243094 | 5509 | `b317baec1e5d9e35` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/units_vprel_viewboxrel_flipx.png` |
| 1222 | `tests/parity/brushes/out/visual_flipx_v1same.png` | 2 | 5243095 | 1939 | `c8bbe76aeed246ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipx_v1same.png` |
| 1223 | `tests/parity/brushes/out/visual_flipx_v2tiling.png` | 2 | 5243096 | 2699 | `3a2c3dcee59e8650` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipx_v2tiling.png` |
| 1224 | `tests/parity/brushes/out/visual_flipx_v3offset.png` | 2 | 5243097 | 3196 | `fe1b3bf2f89465c4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipx_v3offset.png` |
| 1225 | `tests/parity/brushes/out/visual_flipxy_v1same.png` | 2 | 5243098 | 1939 | `c8bbe76aeed246ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipxy_v1same.png` |
| 1226 | `tests/parity/brushes/out/visual_flipxy_v2tiling.png` | 2 | 5243099 | 2663 | `1a89fa2bbde25957` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipxy_v2tiling.png` |
| 1227 | `tests/parity/brushes/out/visual_flipxy_v3offset.png` | 2 | 5243100 | 2739 | `a7f59ff4767e9a7b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipxy_v3offset.png` |
| 1228 | `tests/parity/brushes/out/visual_flipy_v1same.png` | 2 | 5243101 | 1939 | `c8bbe76aeed246ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipy_v1same.png` |
| 1229 | `tests/parity/brushes/out/visual_flipy_v2tiling.png` | 2 | 5243102 | 2196 | `bcaabc67e31bb903` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipy_v2tiling.png` |
| 1230 | `tests/parity/brushes/out/visual_flipy_v3offset.png` | 2 | 5243103 | 2247 | `e241e52cbb8eb730` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_flipy_v3offset.png` |
| 1231 | `tests/parity/brushes/out/visual_none_v1same.png` | 2 | 5243104 | 1939 | `c8bbe76aeed246ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_none_v1same.png` |
| 1232 | `tests/parity/brushes/out/visual_none_v2tiling.png` | 2 | 5243105 | 1449 | `bfb4ff549367cdfb` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_none_v2tiling.png` |
| 1233 | `tests/parity/brushes/out/visual_none_v3offset.png` | 2 | 5243106 | 1444 | `0384de8b94feed6f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_none_v3offset.png` |
| 1234 | `tests/parity/brushes/out/visual_tile_v1same.png` | 2 | 5243107 | 1939 | `c8bbe76aeed246ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_tile_v1same.png` |
| 1235 | `tests/parity/brushes/out/visual_tile_v2tiling.png` | 2 | 5243108 | 2219 | `e2cbe8498a83d374` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_tile_v2tiling.png` |
| 1236 | `tests/parity/brushes/out/visual_tile_v3offset.png` | 2 | 5243109 | 2509 | `b8d6f5ef6b3c0c99` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/visual_tile_v3offset.png` |
| 1237 | `tests/parity/brushes/out/run-normal.log` | 2 | 5243110 | 9738 | `665178087641afec` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/run-normal.log` |
| 1238 | `build/MilBridge/staging/README.md` | 2 | 5243115 | 1398 | `9ecbc7c8adf08381` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/staging/README.md` |
| 1239 | `tests/parity/brushes/out/b2_cachebrush_cache_scale2_tile.png` | 2 | 5243281 | 4169 | `4c441968734ab64a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_cachebrush_cache_scale2_tile.png` |
| 1240 | `tests/parity/brushes/out/run-sabotage.log` | 2 | 5243388 | 24410 | `2444c4e9964e8da6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/run-sabotage.log` |
| 1241 | `samples/WpfFeatureProbe/rtl-after-fix1b-20260913.json` | 2 | 5243514 | 9232 | `14283fa681c24da9` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-after-fix1b-20260913.json` |
| 1242 | `samples/WpfFeatureProbe/rtl-after-fix1-20260913.json` | 2 | 5243545 | 11496 | `73cd502d26fe28cc` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-after-fix1-20260913.json` |
| 1243 | `tests/parity/brushes/PROVENANCE.md` | 2 | 5243636 | 17172 | `1d6cb463ea577d61` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/PROVENANCE.md` |
| 1244 | `samples/WpfFeatureProbe/rtl-provenance2-20260913.json` | 2 | 5243803 | 6712 | `35dc4bc2b4880241` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-provenance2-20260913.json` |
| 1245 | `samples/WpfFeatureProbe/rtl-after-mirrorprobe-20260913.json` | 2 | 5243804 | 7440 | `0cc7a4274b4e5206` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-after-mirrorprobe-20260913.json` |
| 1246 | `samples/WpfFeatureProbe/rtl-origin-ctm-20260913.json` | 2 | 5243805 | 2490 | `d6eec287b33e64ce` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-origin-ctm-20260913.json` |
| 1247 | `samples/WpfFeatureProbe/rtl-transformprovenance-20260913.json` | 2 | 5243806 | 1928 | `aa98b14812bcc8f2` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-transformprovenance-20260913.json` |
| 1248 | `samples/WpfFeatureProbe/rtl-vistrans-20260913.json` | 2 | 5243807 | 7597 | `2f39b139d4181d94` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-vistrans-20260913.json` |
| 1249 | `samples/WpfFeatureProbe/rtl-after-fix2-20260913.json` | 2 | 5243810 | 10748 | `49631165351278a7` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/rtl-after-fix2-20260913.json` |
| 1250 | `tests/parity/systemfonts/PROVENANCE.md` | 2 | 5244341 | 11434 | `667fb646c883a979` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/PROVENANCE.md` |
| 1251 | `build/MilBridge/T1-report.md` | 2 | 5245394 | 141733 | `846b0848b6dfe730` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1-report.md` |
| 1252 | `tests/parity/brushes/PROVENANCE-2.md` | 2 | 5245447 | 13826 | `95e605a8e29488f3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/PROVENANCE-2.md` |
| 1253 | `tests/parity/brushes/out/b2_cachebrush_cache_tile.png` | 2 | 5245448 | 6478 | `aa191fdc7bfe10ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_cachebrush_cache_tile.png` |
| 1254 | `tests/parity/brushes/out/b2_cachebrush_nocache_tile.png` | 2 | 5245449 | 6478 | `aa191fdc7bfe10ac` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_cachebrush_nocache_tile.png` |
| 1255 | `tests/parity/brushes/out/b2_dpi120_drawing_tile_v2.png` | 2 | 5245450 | 2712 | `0e7e8d1a4f32e984` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_drawing_tile_v2.png` |
| 1256 | `tests/parity/brushes/out/b2_dpi120_image_flipx_v2.png` | 2 | 5245451 | 6837 | `5385f635795c0a09` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_image_flipx_v2.png` |
| 1257 | `tests/parity/brushes/out/b2_dpi120_image_none_v1same.png` | 2 | 5245452 | 4885 | `feb6fa56ecc18d1d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_image_none_v1same.png` |
| 1258 | `tests/parity/brushes/out/b2_dpi120_image_tile_v2.png` | 2 | 5245453 | 5368 | `79eeb4d65b46f568` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_image_tile_v2.png` |
| 1259 | `tests/parity/brushes/out/b2_dpi120_visual_tile_v2.png` | 2 | 5245454 | 2857 | `16f4bd15fb7504d4` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_visual_tile_v2.png` |
| 1260 | `tests/parity/brushes/out/b2_dpi144_drawing_tile_v2.png` | 2 | 5245455 | 2252 | `6499968ee7199424` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_drawing_tile_v2.png` |
| 1261 | `tests/parity/brushes/out/b2_dpi144_image_flipx_v2.png` | 2 | 5245456 | 8306 | `8da5cd0a0cc46501` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_image_flipx_v2.png` |
| 1262 | `tests/parity/brushes/out/b2_dpi144_image_none_v1same.png` | 2 | 5245457 | 5442 | `7f1c236fe062ab2d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_image_none_v1same.png` |
| 1263 | `tests/parity/brushes/out/b2_dpi144_image_tile_v2.png` | 2 | 5245458 | 6390 | `fc195ef6bf03f164` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_image_tile_v2.png` |
| 1264 | `tests/parity/brushes/out/b2_dpi144_visual_tile_v2.png` | 2 | 5245459 | 2690 | `e3bbe83968dfdf81` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_visual_tile_v2.png` |
| 1265 | `tests/parity/brushes/out/b2_dpi96_drawing_tile_v2.png` | 2 | 5245460 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_drawing_tile_v2.png` |
| 1266 | `tests/parity/brushes/out/b2_dpi96_image_flipx_v2.png` | 2 | 5245461 | 6296 | `ab170f8d59ee022c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_image_flipx_v2.png` |
| 1267 | `tests/parity/brushes/out/b2_dpi96_image_none_v1same.png` | 2 | 5245462 | 3820 | `44bb49b7d199ce58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_image_none_v1same.png` |
| 1268 | `tests/parity/brushes/out/b2_dpi96_image_tile_v2.png` | 2 | 5245463 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_image_tile_v2.png` |
| 1269 | `tests/parity/brushes/out/b2_dpi96_visual_tile_v2.png` | 2 | 5245464 | 2219 | `e2cbe8498a83d374` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_visual_tile_v2.png` |
| 1270 | `tests/parity/brushes/out/b2_gap_none_center_flipx_v2tiling.png` | 2 | 5245465 | 1796 | `fce4b3d45876b1bd` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_flipx_v2tiling.png` |
| 1271 | `tests/parity/brushes/out/b2_gap_none_center_flipxy_v2tiling.png` | 2 | 5245466 | 1697 | `4e17ceb9890f9b00` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_flipxy_v2tiling.png` |
| 1272 | `tests/parity/brushes/out/b2_gap_none_center_flipy_v2tiling.png` | 2 | 5245508 | 1544 | `0f7e23654eaee2ff` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_flipy_v2tiling.png` |
| 1273 | `tests/parity/brushes/out/b2_gap_none_center_none_v1same.png` | 2 | 5245512 | 1111 | `b0daa92b29513e65` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_none_v1same.png` |
| 1274 | `tests/parity/brushes/out/b2_gap_none_center_none_v2tiling.png` | 2 | 5245516 | 1113 | `e64c3087b4236498` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_none_v2tiling.png` |
| 1275 | `tests/parity/systemfonts/out/run.log` | 2 | 5245519 | 344 | `31dcdd2f34b2f04a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/out/run.log` |
| 1276 | `tests/parity/systemfonts/windows-results.json` | 2 | 5245520 | 89389 | `b56f4c49dd53ff41` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/windows-results.json` |
| 1277 | `tests/parity/systemfonts/out/run-sabotage.log` | 2 | 5245521 | 451 | `1f12ced40314c941` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/out/run-sabotage.log` |
| 1278 | `tests/parity/systemfonts/src/Json.cs` | 2 | 5245522 | 6004 | `f733e99d1c30b067` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/src/Json.cs` |
| 1279 | `tests/parity/systemfonts/src/Program.cs` | 2 | 5245523 | 32971 | `2ae1dcc6095f8a76` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/src/Program.cs` |
| 1280 | `tests/parity/systemfonts/src/U1SystemFontsOracle.csproj` | 2 | 5245524 | 1015 | `0eaa2a8cf030e373` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/systemfonts/src/U1SystemFontsOracle.csproj` |
| 1281 | `tests/parity/brushes/out/b2_gap_none_center_tile_v1same.png` | 2 | 5245525 | 1111 | `b0daa92b29513e65` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_tile_v1same.png` |
| 1282 | `tests/parity/brushes/out/b2_gap_none_center_tile_v2tiling.png` | 2 | 5245526 | 1598 | `394bfadce461fc57` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_center_tile_v2tiling.png` |
| 1283 | `tests/parity/brushes/out/b2_gap_none_left_flipx_v2tiling.png` | 2 | 5245527 | 1863 | `cdf2d4199680c29b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_flipx_v2tiling.png` |
| 1284 | `tests/parity/brushes/out/b2_gap_none_left_flipxy_v2tiling.png` | 2 | 5245528 | 1799 | `d821bb250d99c9cf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_flipxy_v2tiling.png` |
| 1285 | `tests/parity/brushes/out/b2_gap_none_left_flipy_v2tiling.png` | 2 | 5245529 | 1607 | `60b5843516bae709` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_flipy_v2tiling.png` |
| 1286 | `tests/parity/brushes/out/b2_gap_none_left_none_v1same.png` | 2 | 5245530 | 1118 | `9935b7379c2b4fc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_none_v1same.png` |
| 1287 | `tests/parity/brushes/out/b2_gap_none_left_none_v2tiling.png` | 2 | 5245531 | 1118 | `9935b7379c2b4fc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_none_v2tiling.png` |
| 1288 | `tests/parity/brushes/out/b2_gap_none_left_tile_v1same.png` | 2 | 5245532 | 1118 | `9935b7379c2b4fc2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_tile_v1same.png` |
| 1289 | `tests/parity/brushes/out/b2_gap_none_left_tile_v2tiling.png` | 2 | 5245533 | 1649 | `8a0e7c6771c90f4e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_left_tile_v2tiling.png` |
| 1290 | `tests/parity/brushes/out/b2_gap_none_right_flipx_v2tiling.png` | 2 | 5245534 | 1538 | `7f1dd1030f149667` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_right_flipx_v2tiling.png` |
| 1291 | `tests/parity/brushes/out/b2_gap_none_right_flipxy_v2tiling.png` | 2 | 5245535 | 1509 | `9dd9f60bfdd82080` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_right_flipxy_v2tiling.png` |
| 1292 | `tests/parity/brushes/out/b2_gap_none_right_flipy_v2tiling.png` | 2 | 5245536 | 1396 | `d84e9669f7b4f274` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_right_flipy_v2tiling.png` |
| 1293 | `tests/parity/brushes/out/b2_gap_none_right_none_v2tiling.png` | 2 | 5245537 | 1114 | `411d64b0e253758f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_right_none_v2tiling.png` |
| 1294 | `tests/parity/brushes/out/b2_gap_none_right_tile_v2tiling.png` | 2 | 5245538 | 1438 | `d94eddb7ab0e24a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_gap_none_right_tile_v2tiling.png` |
| 1295 | `tests/parity/brushes/out/b2_scale_down_drawing_highquality.png` | 2 | 5245539 | 5269 | `fb44cdf0bbc5a66b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_drawing_highquality.png` |
| 1296 | `tests/parity/brushes/out/b2_scale_down_drawing_linear.png` | 2 | 5245540 | 5269 | `fb44cdf0bbc5a66b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_drawing_linear.png` |
| 1297 | `tests/parity/brushes/out/b2_scale_down_drawing_nearestneighbor.png` | 2 | 5245541 | 1842 | `7c3c73faac998748` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_drawing_nearestneighbor.png` |
| 1298 | `tests/parity/brushes/out/b2_scale_down_drawing_unspecified.png` | 2 | 5245542 | 5269 | `fb44cdf0bbc5a66b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_drawing_unspecified.png` |
| 1299 | `tests/parity/brushes/out/b2_scale_down_image_highquality.png` | 2 | 5245543 | 5204 | `0b3d2dfa9105558c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_image_highquality.png` |
| 1300 | `tests/parity/brushes/out/b2_scale_down_image_linear.png` | 2 | 5245544 | 2912 | `9b58f6a984d4d547` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_image_linear.png` |
| 1301 | `tests/parity/brushes/out/b2_scale_down_image_nearestneighbor.png` | 2 | 5245545 | 1912 | `9c7aa1fa9239ec09` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_image_nearestneighbor.png` |
| 1302 | `tests/parity/brushes/out/b2_scale_down_image_unspecified.png` | 2 | 5245546 | 2912 | `9b58f6a984d4d547` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_down_image_unspecified.png` |
| 1303 | `tests/parity/brushes/out/b2_scale_up_drawing_highquality.png` | 2 | 5245547 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_drawing_highquality.png` |
| 1304 | `tests/parity/brushes/out/b2_scale_up_drawing_linear.png` | 2 | 5245548 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_drawing_linear.png` |
| 1305 | `tests/parity/brushes/out/b2_scale_up_drawing_nearestneighbor.png` | 2 | 5245549 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_drawing_nearestneighbor.png` |
| 1306 | `tests/parity/brushes/out/b2_scale_up_drawing_unspecified.png` | 2 | 5245550 | 1985 | `9589ffb7b59cc050` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_drawing_unspecified.png` |
| 1307 | `tests/parity/brushes/out/b2_scale_up_image_highquality.png` | 2 | 5245551 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_image_highquality.png` |
| 1308 | `tests/parity/brushes/out/b2_scale_up_image_linear.png` | 2 | 5245552 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_image_linear.png` |
| 1309 | `tests/parity/brushes/out/b2_scale_up_image_nearestneighbor.png` | 2 | 5245553 | 1668 | `d068ed1f1887c4a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_image_nearestneighbor.png` |
| 1310 | `tests/parity/brushes/out/b2_scale_up_image_unspecified.png` | 2 | 5245554 | 5524 | `cf3a79a724564242` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_scale_up_image_unspecified.png` |
| 1311 | `tests/parity/brushes/out/b2_text_display_flipx.png` | 2 | 5245555 | 4368 | `7ab33e9f5cb6af4e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_text_display_flipx.png` |
| 1312 | `tests/parity/brushes/out/b2_text_display_tile.png` | 2 | 5245556 | 3230 | `2c902ce90739d68a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_text_display_tile.png` |
| 1313 | `tests/parity/brushes/out/b2_text_ideal_flipx.png` | 2 | 5245557 | 2699 | `3a2c3dcee59e8650` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_text_ideal_flipx.png` |
| 1314 | `tests/parity/brushes/out/b2_text_ideal_tile.png` | 2 | 5245558 | 2219 | `e2cbe8498a83d374` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_text_ideal_tile.png` |
| 1315 | `tests/parity/brushes/cases-2.json` | 2 | 5245559 | 43823 | `865bed4c174750b7` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/cases-2.json` |
| 1316 | `tests/parity/brushes/windows-results-2.json` | 2 | 5245560 | 5905780 | `73b7d8ca40fb1b08` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/windows-results-2.json` |
| 1317 | `tests/parity/brushes/out/run-normal-batch2.log` | 2 | 5245561 | 10214 | `9088c252adcd817b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/run-normal-batch2.log` |
| 1318 | `tests/parity/brushes/out/run-sabotage-batch2.log` | 2 | 5245562 | 19890 | `c6ca73cf1342ee5b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/run-sabotage-batch2.log` |
| 1319 | `tests/parity/brushes/out/b2_dpi120_image_none_stretch_left_tile.png` | 2 | 5245584 | 3503 | `7868f344f0d8c755` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi120_image_none_stretch_left_tile.png` |
| 1320 | `tests/parity/brushes/out/b2_dpi144_image_none_stretch_left_tile.png` | 2 | 5245586 | 3811 | `44d25a8f68a7fb92` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi144_image_none_stretch_left_tile.png` |
| 1321 | `tests/parity/brushes/out/b2_dpi96_image_none_stretch_left_tile.png` | 2 | 5245587 | 1649 | `8a0e7c6771c90f4e` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/brushes/out/b2_dpi96_image_none_stretch_left_tile.png` |
| 1322 | `build/MilBridge/T1b-report.md` | 2 | 5245620 | 115402 | `9a20225c77bbde5c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/T1b-report.md` |
| 1323 | `build/MilBridge/tools/tline-gate.sh` | 3 | 5250406 | 97933 | `747c078dbf040862` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/tline-gate.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/tline-gate.sh` |
| 1324 | `build/MilBridge/tests/ProductEntryArm/inputs.json` | 2 | 5250445 | 4733 | `10764e2f796bf65b` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ProductEntryArm/inputs.json` |
| 1325 | `build/MilBridge/tests/ProductEntryArm/extract-inputs.py` | 2 | 5250446 | 3721 | `14a63ec7b14908fd` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ProductEntryArm/extract-inputs.py` |
| 1326 | `build/MilBridge/tests/ProductEntryArm/ProductEntryArm.csproj` | 2 | 5250719 | 4783 | `6f4b51e1c3332f75` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ProductEntryArm/ProductEntryArm.csproj` |
| 1327 | `build/MilBridge/known-red.json` | 3 | 5251064 | 68896 | `089b7324ba12e022` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/known-red.json`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/known-red.json` |
| 1328 | `build/MilBridge/tests/ProductEntryArm/Program.cs` | 2 | 5252153 | 45064 | `e1c6f736cc6bd8e1` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tests/ProductEntryArm/Program.cs` |
| 1329 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | 3 | 5252412 | 85549 | `6c5707169950fcab` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` |
| 1330 | `docs/WAVE33-PREREGISTRATION.md` | 2 | 5253440 | 12813 | `07137533f7917cfe` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE33-PREREGISTRATION.md` |
| 1331 | `build/MilBridge/tools/arm-log-sha-check.sh` | 3 | 5253759 | 19321 | `d6045edbfc7b06fc` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/arm-log-sha-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/arm-log-sha-check.sh` |
| 1332 | `build/MilBridge/tools/hidden-only-step.sh` | 3 | 5253764 | 53575 | `505f315026092584` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/hidden-only-step.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/hidden-only-step.sh` |
| 1333 | `build/MilBridge/tools/fp-inputs-hygiene-check.sh` | 3 | 5253769 | 23594 | `68ef01bfb9c6a8ee` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/fp-inputs-hygiene-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/fp-inputs-hygiene-check.sh` |
| 1334 | `build/MilBridge/tools/shell-quote-trap-check.sh` | 3 | 5253772 | 55980 | `e5d4cf05ef5fc2ea` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/shell-quote-trap-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/shell-quote-trap-check.sh` |
| 1335 | `build/MilBridge/tools/baseline-sha-check.sh` | 3 | 5254132 | 12508 | `e3b4a98fc9507854` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/baseline-sha-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/baseline-sha-check.sh` |
| 1336 | `build/MilBridge/tools/t1b-ls-tripwire.sh` | 2 | 5254171 | 10091 | `82f6a05afb1f9db9` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1b-ls-tripwire.sh` |
| 1337 | `build/MilBridge/tools/defect-registry-check.sh` | 3 | 5254340 | 28118 | `dc0aeba08f9a7928` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/defect-registry-check.sh`<br>`/home/links-dev/w62a/negrepo/build/MilBridge/tools/defect-registry-check.sh` |
| 1338 | `samples/WpfFeatureProbe/MainWindow.xaml.cs` | 2 | 5254554 | 8150 | `1bd652e0dba3bd6b` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/MainWindow.xaml.cs` |
| 1339 | `docs/WAVE44-PREREGISTRATION.md` | 2 | 5259785 | 13951 | `d2165f03a2327d67` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE44-PREREGISTRATION.md` |
| 1340 | `handoff.md` | 2 | 5260310 | 1082833 | `e4dc264200b421d0` | 是（1 条） | `/home/links-dev/w62a/negrepo/handoff.md` |
| 1341 | `docs/CURRENT-STATE.md` | 2 | 5260312 | 373207 | `b7b2d513cfdab2eb` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/CURRENT-STATE.md` |
| 1342 | `docs/history/WAVE45-PREREGISTRATION.md` | 2 | 5261577 | 5110 | `62d5ad60bb016109` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/history/WAVE45-PREREGISTRATION.md` |
| 1343 | `docs/WAVE46-PREREGISTRATION.md` | 2 | 5261816 | 15048 | `c84edbc486ff84bd` | 是（1 条） | `/home/links-dev/w62a/negrepo/docs/WAVE46-PREREGISTRATION.md` |
| 1344 | `src/WpfGfx.Linux/Windowing/X11Window.cs` | 3 | 5262414 | 28726 | `ea6c653493f05a93` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Windowing/X11Window.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Windowing/X11Window.cs` |
| 1345 | `build/MilBridge/W46A-report.md` | 2 | 5262666 | 20853 | `56377332c1d4ce7e` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46A-report.md` |
| 1346 | `build/MilBridge/W46C-report.md` | 2 | 5262729 | 24364 | `35bb23b845a734a4` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46C-report.md` |
| 1347 | `build/DirectWrite.Linux/wic-shim/applocal-expect.py` | 2 | 5263978 | 48582 | `b5dccf135afd6de4` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/DirectWrite.Linux/wic-shim/applocal-expect.py` |
| 1348 | `build/MilBridge/W46G-report.md` | 2 | 5264167 | 34140 | `06eaf6b9988b4be3` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/W46G-report.md` |
| 1349 | `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | 2 | 5264901 | 14055 | `5dbb7eb006d4dba0` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/WpfFeatureProbe.csproj` |
| 1350 | `samples/WpfFeatureProbe/App.xaml` | 2 | 5264918 | 370 | `0ed2f59dea8e8124` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/App.xaml` |
| 1351 | `samples/WpfFeatureProbe/App.xaml.cs` | 2 | 5264919 | 1070 | `cc4b111d9c8ce5aa` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/App.xaml.cs` |
| 1352 | `samples/WpfFeatureProbe/MainWindow.xaml` | 2 | 5264972 | 1596 | `9e629e6418f4bd79` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/MainWindow.xaml` |
| 1353 | `src/WpfGfx.Linux.Native/tools/patch-shared-invariant-failfast.py` | 3 | 5267094 | 11123 | `e2a7da444a2e7080` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-shared-invariant-failfast.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-shared-invariant-failfast.py` |
| 1354 | `build/MilBridge/tools/product-entry-step.sh` | 2 | 5273900 | 26836 | `4fdf5de43f1a211a` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/product-entry-step.sh` |
| 1355 | `samples/WpfFeatureProbe/README.md` | 2 | 5278840 | 53777 | `d981b520b901306c` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/README.md` |
| 1356 | `src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs` | 3 | 5279083 | 25416 | `54289f72b81a432e` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/DrawInstructionCensus.cs` |
| 1357 | `src/WpfGfx.Linux/Rendering/SkiaRenderBackend.cs` | 3 | 5279100 | 41995 | `ec11937e86bd3617` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux/Rendering/SkiaRenderBackend.cs`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux/Rendering/SkiaRenderBackend.cs` |
| 1358 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/CensusPushFieldTruthTests.cs` | 2 | 5279106 | 6338 | `c3b2ea37c0a4f029` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/CensusPushFieldTruthTests.cs` |
| 1359 | `tests/WpfGfx.Linux.Tests/Rendering.Tests/t2b-test.sh` | 2 | 5279109 | 3439 | `19af5b32ef487c9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Rendering.Tests/t2b-test.sh` |
| 1360 | `build/MilBridge/tools/t1c-dp1-leg-audit.py` | 2 | 5280381 | 22697 | `965d8a32d9b31d26` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1c-dp1-leg-audit.py` |
| 1361 | `build/MilBridge/tools/pick-feat-line.py` | 2 | 5281047 | 6562 | `94f542e367b5be4c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/pick-feat-line.py` |
| 1362 | `build/MilBridge/tools/t1c-inputtrace-verify.py` | 2 | 5281848 | 16932 | `434402f4c36719a0` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/tools/t1c-inputtrace-verify.py` |
| 1363 | `src/WpfGfx.Linux.Native/tools/patch-presentationframework-textbox-textdp-trace.py` | 3 | 5282358 | 37563 | `9206ea83512f6fd5` | 是（2 条） | `/home/links-dev/w113a/fixture/fp-farm/src/WpfGfx.Linux.Native/tools/patch-presentationframework-textbox-textdp-trace.py`<br>`/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/patch-presentationframework-textbox-textdp-trace.py` |
| 1364 | `samples/WpfTextDemo/BASELINE-CANDIDATE-8-prepatch.md` | 2 | 5282907 | 8129 | `9e2ecba2ebefaa22` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/BASELINE-CANDIDATE-8-prepatch.md` |
| 1365 | `samples/WpfTextDemo/WAVE21-FINAL-ROUND.md` | 2 | 5284496 | 8231 | `5325c472c7708585` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WAVE21-FINAL-ROUND.md` |
| 1366 | `build/MilBridge/staging/PresentationCore.HbTextLine.cs` | 2 | 5287623 | 102453 | `c580f2df9362de55` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/staging/PresentationCore.HbTextLine.cs` |
| 1367 | `tests/parity/windows/modifier-scope/closeindex-check.py` | 2 | 5373954 | 7449 | `c500066cec6db0b9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/closeindex-check.py` |
| 1368 | `tests/parity/windows/modifier-scope/closeindex-addendum.md` | 2 | 5373955 | 8162 | `f80d0bcc6933e8e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/closeindex-addendum.md` |
| 1369 | `tests/parity/windows/tab-anchor/analyze.py` | 2 | 5373956 | 43169 | `f4780fbb12efbc7c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/analyze.py` |
| 1370 | `build/MilBridge/tools/r-gate-step.sh` | 2 | 5374797 | 41531 | `aa9d7188b6b01a2f` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/r-gate-step.sh` |
| 1371 | `build/MilBridge/tools/nul-bytes-check.sh` | 2 | 5377012 | 37672 | `409d83d945f7d563` | 是（1 条） | `/home/links-dev/w113a/fixture/fp-farm/build/MilBridge/tools/nul-bytes-check.sh` |
| 1372 | `build/MilBridge/arm-logs/tline.log` | 2 | 5379701 | 23483 | `9d29470d63791d64` | 是（1 条） | `/home/links-dev/w110a/arms/tline.log` |
| 1373 | `build/MilBridge/arm-logs/tab-zero.log` | 2 | 5379702 | 19182 | `9150c3a26a3cb789` | 是（1 条） | `/home/links-dev/w110a/arms/tab-zero.log` |
| 1374 | `build/MilBridge/arm-logs/tab-anchor.log` | 2 | 5379704 | 118027 | `1c43a12dcaa5718a` | 是（1 条） | `/home/links-dev/w110a/arms/tab-anchor.log` |
| 1375 | `build/MilBridge/arm-logs/tab-rtl.log` | 2 | 5379705 | 17418 | `92570318851ca7e8` | 是（1 条） | `/home/links-dev/w110a/arms/tab-rtl.log` |
| 1376 | `build/MilBridge/arm-logs/textlineproto.log` | 2 | 5379706 | 7926 | `4bceceeed570ba70` | 是（1 条） | `/home/links-dev/w110a/arms/textlineproto.log` |
| 1377 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/probe-block-registry.py` | 2 | 5381407 | 3349 | `39c6fb91e68ee9cf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/WpfGfx.Linux.Tests/Presentation.Tests/probe-block-registry.py` |
| 1378 | `samples/WpfFeatureProbe/BLOCK-MATRIX-20260914.md` | 2 | 5381568 | 7436 | `72c7b2f6da77e6cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfFeatureProbe/BLOCK-MATRIX-20260914.md` |
| 1379 | `build/artifact-src-fp.sh` | 2 | 5381600 | 1417 | `e33f0fb1b83fd1bb` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/artifact-src-fp.sh` |
| 1380 | `samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md` | 2 | 5381608 | 8497 | `c2993d3c286a1256` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md` |
| 1381 | `tests/parity/windows/tab/out/tab-oracle.json` | 2 | 5381622 | 298055 | `c43303d570de0846` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/out/tab-oracle.json` |
| 1382 | `tests/parity/windows/tab/out/tab-oracle.txt` | 2 | 5381623 | 32183 | `382dda6d6c73ff22` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/out/tab-oracle.txt` |
| 1383 | `tests/parity/windows/tab/src/Program.cs` | 2 | 5381624 | 22131 | `b0e9bbfb66bc20e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/src/Program.cs` |
| 1384 | `tests/parity/windows/tab/src/TabOracle.csproj` | 2 | 5381625 | 441 | `a2b6800367c746b8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/src/TabOracle.csproj` |
| 1385 | `tests/parity/windows/tab/src/run.ps1` | 2 | 5381626 | 743 | `42272cf2aff87d28` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/src/run.ps1` |
| 1386 | `tests/parity/windows/tab/PROVENANCE.md` | 2 | 5381627 | 9128 | `6c3e579ebaf66815` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab/PROVENANCE.md` |
| 1387 | `tests/parity/windows/tab-zero/out/tab-zero-oracle.json` | 2 | 5382076 | 238351 | `256007ce706c7d3f` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/out/tab-zero-oracle.json` |
| 1388 | `tests/parity/windows/tab-zero/out/tab-zero-oracle.txt` | 2 | 5382081 | 16419 | `23a2c3251ddc2b6c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/out/tab-zero-oracle.txt` |
| 1389 | `tests/parity/windows/tab-zero/src/Program.cs` | 2 | 5382082 | 20072 | `e8fcf0a57a9c4965` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/src/Program.cs` |
| 1390 | `tests/parity/windows/tab-zero/src/TabZeroOracle.csproj` | 2 | 5382083 | 449 | `542eda9eaa8ef785` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/src/TabZeroOracle.csproj` |
| 1391 | `tests/parity/windows/tab-zero/src/run.ps1` | 2 | 5382084 | 783 | `0b0a9121cb86dcff` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/src/run.ps1` |
| 1392 | `tests/parity/windows/tab-zero/PROVENANCE.md` | 2 | 5382087 | 9110 | `63654c6500c6a484` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-zero/PROVENANCE.md` |
| 1393 | `tests/parity/windows/tab-rtl/out/tab-rtl-oracle.json` | 2 | 5382611 | 297654 | `a01934a73b7d5655` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/out/tab-rtl-oracle.json` |
| 1394 | `tests/parity/windows/tab-rtl/out/tab-rtl-oracle.txt` | 2 | 5382613 | 45418 | `17587e1989706a71` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/out/tab-rtl-oracle.txt` |
| 1395 | `tests/parity/windows/tab-rtl/src/Program.cs` | 2 | 5382614 | 26407 | `fa197fe05387403a` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/src/Program.cs` |
| 1396 | `tests/parity/windows/tab-rtl/src/TabRtlOracle.csproj` | 2 | 5382615 | 447 | `c09068027cc0884b` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/src/TabRtlOracle.csproj` |
| 1397 | `tests/parity/windows/tab-rtl/src/run.ps1` | 2 | 5382616 | 778 | `4964bef31726806d` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/src/run.ps1` |
| 1398 | `tests/parity/windows/tab-rtl/PROVENANCE.md` | 2 | 5382618 | 8445 | `abd7470f9c82e3ae` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-rtl/PROVENANCE.md` |
| 1399 | `samples/WpfTextDemo/WAVE22-FINAL-ROUND.md` | 2 | 5383225 | 7936 | `5eb7e1f304afa505` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WAVE22-FINAL-ROUND.md` |
| 1400 | `build/MilBridge/M7b-DP1-repro-report.md` | 2 | 5383236 | 61885 | `9f8e548592ba858c` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/M7b-DP1-repro-report.md` |
| 1401 | `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json` | 2 | 5383269 | 1196289 | `88559d670f1bb955` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json` |
| 1402 | `samples/WpfTextDemo/WAVE23-FINAL-ROUND.md` | 2 | 5384732 | 7649 | `b0ae90ac7973cf68` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/WAVE23-FINAL-ROUND.md` |
| 1403 | `tests/parity/windows/tab-anchor/src/TabAnchorOracle.csproj` | 2 | 5384735 | 453 | `726a6424823bbd9c` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/src/TabAnchorOracle.csproj` |
| 1404 | `tests/parity/windows/tab-anchor/src/Program.cs` | 2 | 5384736 | 40998 | `e6651272200f7fb6` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/src/Program.cs` |
| 1405 | `tests/parity/windows/tab-anchor/src/run.ps1` | 2 | 5384737 | 2216 | `718ee0bcf16a1ce5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/src/run.ps1` |
| 1406 | `tests/parity/windows/tab-anchor/out/tab-anchor-raw.txt` | 2 | 5384753 | 155957 | `e509b0bd66e850b5` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/out/tab-anchor-raw.txt` |
| 1407 | `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` | 2 | 5384754 | 1252008 | `0cebc0afd5142fbf` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` |
| 1408 | `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.txt` | 2 | 5384755 | 197644 | `34bab0b1032d2cd2` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.txt` |
| 1409 | `tests/parity/windows/tab-anchor/PROVENANCE.md` | 2 | 5384759 | 17594 | `61617b4f244b1166` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/tab-anchor/PROVENANCE.md` |
| 1410 | `src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py` | 2 | 5384796 | 14571 | `1b428ff42a6aaa73` | 是（1 条） | `/home/links-dev/w62a/negrepo/src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py` |
| 1411 | `samples/WpfTextDemo/NEXT-WAVE-11-CHECKLIST.md` | 2 | 5384812 | 12319 | `064e3b63ce32d6cd` | 是（1 条） | `/home/links-dev/w62a/negrepo/samples/WpfTextDemo/NEXT-WAVE-11-CHECKLIST.md` |
| 1412 | `tests/parity/windows/modifier-scope/src/ModifierScope.csproj` | 2 | 5384869 | 461 | `2f69f5fd78eebc58` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/src/ModifierScope.csproj` |
| 1413 | `tests/parity/windows/modifier-scope/src/run.ps1` | 2 | 5384875 | 2575 | `c84774b3b5c17f25` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/src/run.ps1` |
| 1414 | `tests/parity/windows/modifier-scope/src/Program.cs` | 2 | 5384876 | 40103 | `392e3bd9fa8d2284` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/src/Program.cs` |
| 1415 | `tests/parity/windows/modifier-scope/out/modifier-scope-raw.json` | 2 | 5384885 | 498838 | `6818b4783061cda3` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/out/modifier-scope-raw.json` |
| 1416 | `tests/parity/windows/modifier-scope/analyze.py` | 2 | 5384886 | 27963 | `85ef04770638e237` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/analyze.py` |
| 1417 | `tests/parity/windows/modifier-scope/out/modifier-scope-raw.txt` | 2 | 5384887 | 76286 | `a66f11763e134cd9` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/out/modifier-scope-raw.txt` |
| 1418 | `tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json` | 2 | 5384888 | 504676 | `cc4b722e7ee52659` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json` |
| 1419 | `tests/parity/windows/modifier-scope/out/modifier-scope-oracle.txt` | 2 | 5384889 | 85122 | `b32c620734d293e8` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/out/modifier-scope-oracle.txt` |
| 1420 | `tests/parity/windows/modifier-scope/PROVENANCE.md` | 2 | 5384890 | 15051 | `e70d094a76930810` | 是（1 条） | `/home/links-dev/w62a/negrepo/tests/parity/windows/modifier-scope/PROVENANCE.md` |
| 1421 | `build/MilBridge/M7b-keystate-probe-report.md` | 2 | 5385082 | 59971 | `2186791f2fd4ac75` | 是（1 条） | `/home/links-dev/w62a/negrepo/build/MilBridge/M7b-keystate-probe-report.md` |

**表内自洽检查**：行数 = 1421（= 判据 A 口径内件数）；每一行 `跨区` 均为「是」；`sha16前=后` 已逐件与 `post.R.tsv` 比对（见 §3）。

**本报告自身 `FULL sha256` = `b39be875461f988ce339ea824d18222e58b43d182c0f304854d96b51d43c8978`**（口径：`head -n -2 <本件> | sha256sum`，即第 1..N−2 行 —— 本行与下一条尾行都**不在**该口径内）
**本报告自身 `sha16` = `b4c9ad1c598ce12d`**（口径：`head -n -1 <本件> | sha256sum | cut -c1-16`，即不含本条尾行本身）
