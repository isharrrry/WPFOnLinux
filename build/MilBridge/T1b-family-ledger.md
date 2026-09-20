# T1b · tline 三处红的逐族台账（**只读冻件 #10**，2026-09-14）

## 四元组（每个数字都带；引用时请连它一起引）
| 项 | 值 |
|---|---|
| **件 sha** | shim **`7C2E0107A9C86180…`**（= #10 `hbtextline 7c2e0107a9c86180`）；三份 artifact 头行都自报同一 sha（已核） |
| **仪器/harness** | `bash build/MilBridge/run.sh tline`（产出这三份 artifact 的那一趟）；**本轮不重跑**（T1d 正在动 `build/shims/**`） |
| **判据口径 + artifact/字段** | 块1 `gen/t2d-width-diff.txt`：字段 = **`TextLine.Width` vs 真机 `w`**，桶 `>0.34 DIP`<br>块2 `gen/t2d-extent-mismatches.txt`：字段 = **逐行 `Extent`**，容差 **0.01 DIP**<br>块3 `gen/tline-detail-full.txt` 段1：字段 = **折叠明细 `Len/W/cr(起,长,宽)`**（`236` 的总数来自同一断言） |
| **等式断言** | 47 == 47 ✅；58 == 58 ✅；18 == 236−218 ✅（三条都在下面就地给出） |

## 块1 · 宽度超差 47（族计数之和 == 47 ✅，与头行自报 `>0.34=47` 相等 ✅）
| 族 | 条数 |
|---|---|
| `A1_nbsp_zwsp` | **25** |
| `F_nbsp_zwsp` | **10** |
| `M_modifier` | **7** |
| `B_nbsp_zwsp` | **4** |
| `B_nbsp_zwsp_trim` | **1** |
| **合计** | **47** |

复算（读文件哪一列）：
```bash
grep -c '桶=>0.34 DIP' build/MilBridge/gen/t2d-width-diff.txt      # ⇒ 47
grep '^# 合计' build/MilBridge/gen/t2d-width-diff.txt              # ⇒ 头行 >0.34=47（两处必须相等）
```

## 块2 · Extent 余差 58（族计数之和 == 58 ✅，与头行自报 `合计 58 条` 相等 ✅）
| 族 | 条数 | 裁定级分类 |
|---|---|---|
| `LH_cjk_punct_lh10 / lh22 / lh30 / lh50 / lh30_ac1` | 4×5 = **20** | **结构性不可比（已裁定不算缺陷）**；**「与」构造已核**：5 个族的文本都是 `他说：「今天很好。」（真的吗？）『引号』“双引号”【方括号】`（源 `cases-cd2.json`，只读）⇒ 含 `「`/`」` 5/5 ✅ |
| `A1_nbsp_zwsp` | **21** | **真差**（NBSP/ZWSP 族，与块1 同族） |
| `F_nbsp_zwsp` | **8** | **真差**（同族） |
| `B_nbsp_zwsp` | **4** | **真差**（同族） |
| `B_nbsp_zwsp_trim` | **1** | **真差**（同族） |
| `M_modifier` | **4** | **真差**（`M_modifier` 语义，归 T1c 那族） |
| **合计** | **20 + 34 = 58** | 即：**不可比 20 / 真差 34（NBSP/ZWSP 34 全在其中里 34 = 21+8+4+1，M_modifier 4）** |

⚠️ 更正我上一版的一处粗糙表述：块2 的 `M_modifier` 是 **4** 条（块1 是 7 条；两处口径/字段不同，别混）。

复算：
```bash
awk '!/^#/' build/MilBridge/gen/t2d-extent-mismatches.txt | sed 's/ .*//' | sed 's/_w[0-9]*$//;s/_winf$//' | sort | uniq -c   # ⇒ 上表
grep '^# 合计' build/MilBridge/gen/t2d-extent-mismatches.txt        # ⇒ 合计 58 条（主对拍 38 + LH 组 20）
```
**本表就是判据"余差条数不得因 #11/#12 改动而变"的基线**（重算入口即上面两条命令）。

## 块3 · 折叠明细 18 条（== `236−218` ✅）
| 族 | 条数 |
|---|---|
| `F_nbsp_zwsp` | **10** |
| `M_modifier` | **7** |
| `F_lat_words` | **1** |
| **合计** | **18** |

复算：
```bash
sed -n '/^# 段1/,/^# 段2/p' build/MilBridge/gen/tline-detail-full.txt | grep -c '^[A-Z]'   # ⇒ 18
grep -o '折叠明细 218/236' <本趟日志>                                                      # ⇒ 236−218 = 18
```

## ⭐ 三个"同一性"判定（方法可复算，不靠条数相近）
1. **块1（47）与块3（折叠 18）不是同一批**（按 `(用例, 行#)` 求交，**已实测**）：
   · **交集 17 条** = 折叠 18 里的 **除 `F_lat_words_w560#0` 之外的全部**（10 `F_nbsp_zwsp_*` + 7 `M_modifier_*`）；
   · **仅块1 有 30 条** = `A1_nbsp_zwsp` 25 + `B_nbsp_zwsp` 4 + `B_nbsp_zwsp_trim` 1 ⇒ **这些行的折叠明细是对的**，宽度却超差
     ⇒ **同一 NBSP/ZWSP 族里的另一个机制（行 advance，不是折叠）**；
   · **仅块3 有 1 条** = `F_lat_words_w560#0`（ΔW `+0.0140` ⇒ 落在 `≤0.34` 桶，本来就不该出现在块1）。
   ⇒ **结论**：两者**部分重叠（17）**，但差集是 30 + 1；**重叠部分比的是两个不同字段**（折叠明细的 `W` vs `t2d-width-diff` 的 `TextLine.Width`）。
2. **主控问的"8 条（3 宽度-only + 5 起止±1）"是否 == 块1/块3**：**答不出（无信息）** —— 那个 8 的分层来自 **T1c §39 的分析件**，
   不在我手上，也不在这三份 `#10` artifact 里。**需要什么才能答**：T1c §39 那张表的**文件路径 + 它的字段名**（是对 8 条全量还是对 `F_*` 子集）；
   拿到后我按 `(用例,行#)` 求交，与上面的 17/30/1 直接比。**我不拿"条数接近"去推**（红旗 ③）。
3. **"折叠明细 18" 与 "段1 18" 是同一集合 —— 证成**：同 artifact（`tline-detail-full.txt`）、同 sha（`7C2E0107…`）、
   同口径（段1 就是那条折叠断言的**失败行清单**），且 **`236 − 218 = 18 == 段1 行数 18`**（两处独立计数相等）。⇒ **前两轮的归属无需重挂**。

## 我答不出的项（列成"需要什么才能答"）
| 问题 | 缺什么 |
|---|---|
| "8 条省略号几何"的集合与块1/块3 的交集 | T1c §39 的分层件（路径 + 字段名） |
| 块1 的 30 条"仅宽度"是否与块3 的 10 条 `F_nbsp_zwsp` 同根（机制层） | 需要 shim 侧一次**定向读数**（折叠 vs 行 advance 的分解）——**本轮禁止跑 harness**，故留到"可以动"那一轮 |
| `A1_nbsp_zwsp`（25 条，块1 最大族）的行 advance 归因 | 同上一行；且 `A1` 族在块3 里**一条都没有**（折叠全对）⇒ 优先怀疑**行 advance/空白推进**而非折叠 |

**红旗自查**：① 没有为凑等式合并/放宽族名（族名逐字取自 artifact，`_wNN`/`_winf` 后缀只在计数时归一，未改判据）；② **没有**用 `t2d-width-diff` 的行宽字段解释折叠明细（两处字段在四元组里分列）；③ 未用"条数相近"推断同一批（同一性一律用 `(用例,行#)` 求交，答不出的报无信息）；④ 没有任何估计值。

---

# 附 · #12 定向读数设计 + 断言落点 + 牙 + provenance（**只读设计，未跑 harness**）

## ① `#12` 定向读数（一次跑清）：命令 / 格式 / 判据三分表
**目的**：判定 T1c 的假设「我们把**行尾 NBSP/ZWSP** 当行尾空白扣了，真机计入」（旁证：三族 Extent 差**全为负**）——**旁证不是证据**。

**命令（#11 波落完后执行；`T1B_SHIM_SHA256` 只作断言锚）**
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
T1B_ROW_DUMP='A1_nbsp_zwsp_w20#7,B_nbsp_zwsp_trim#1,A1_nbsp_zwsp_w30#0,A1_nbsp_zwsp_w30#2,A1_nbsp_zwsp_w40#1,A1_nbsp_zwsp_w80#0,F_nbsp_zwsp_w40#3' \
T1B_SHIM_SHA256=7C2E0107A9C8618027D327179269ABEE6D8D329EC1CD89194A412B06B1687274 \
  bash build/MilBridge/run.sh tline 2>&1 | tee /tmp/t1b-rowdump.log
grep -E '^\[ROWD\]|^# 被测 shim sha256' /tmp/t1b-rowdump.log
```
**输出格式（点名行各一段：逐字符一行 + 小计 + VERDICT）**
```
[ROWD] 头：case=A1_nbsp_zwsp_w20 行#7 cp=[a,b)  真值{len,w,ws,witw,extent}  我们{同五字段}
[ROWD] c=<cp> U+XXXX <char> adv=我们/真值 | 累计=我们/真值 | mark=NBSP|ZWSP|我们计入空白|真值计入空白
[ROWD] 小计：adv 和 我们=<x> 真值=<y> Δ=<d> | TrailingWhitespaceLength 我们=<n> 真值=<m>
               | WITW−W 我们=<p> 真值=<q> | Extent 我们=<r> 真值=<s> Δ=<t>
[ROWD] VERDICT=<A|B|C|D>
```
**判据三分表（四结局，含"答不出"）**
| 结局 | 读数特征（**须同时满足**） | 含义 | 下一步 |
|---|---|---|---|
| **A 假设成立** | ① 我们 `ws>0`／该字符被标"我们计入空白"，真值同位置 `ws=0`；② `WITW−W` 我们 == 该字符 advance、真值 == 0；③ `Extent` Δ == −(该字符 advance) | **行尾空白口径差** | 修 `#12`：`ws` 判定与 `WITW−W` 同改；断言 `ws == 真值` |
| **B 假设不成立** | 我们 `ws==0` 且 `WITW−W == 0`（与真值同），但 `Extent` 仍差、且 Δ 不等于任何单字符 advance | 扣的不是"行尾空白"（可能在 advance 求和/folding/行度量） | 转查 advance 和 |
| **C 第二机制** | `ws` 与 `WITW−W` 两侧**都一致**，但 `adv 和` 本身就差 | **行度量/advance**（与折叠无关 —— 正是 `A1_` 在段1 为 0 条的原因） | 归 `#12` 行度量子项或单列一档 |
| **D 答不出** | dump 缺失／字段缺失／`T1B_SHIM_SHA256` ≠ 生成器自报 sha（**跨树**） | 无信息 | **报无信息，不报绿** |

**为什么点这 7 行**：`A1_nbsp_zwsp_w20#7`（T1c 点名）+ `B_nbsp_zwsp_trim#1` + T1c 的 4 条分辨器（"**宽差而 Extent 不动**" ⇒ 若它们落在 A/B 之外，说明"宽差"与"Extent 差"是两回事）+ `F_nbsp_zwsp_w40#3`（负宽那条，作对照）。

## ② 断言落点 + 牙（与 T1d 的修**同波**落）
| # | 落点 | 断言形态 | 当前状态 |
|---|---|---|---|
| 1 | `Program.cs:476`（`okDetail`） | **`cr[0].Width >= 0`**（第一条，硬） | `F_nbsp_zwsp_w40#3` = `−3.0560` ⇒ **必红** |
| 2 | 同上 | `cr[0].TextSourceCharacterIndex == 真机 && cr[0].Length == 真机` | 8 条里 **5 条必红** |
| 3 | 同上 | `|cr[0].Width − 真机| < 0.34`（**沿用既有容差，不放宽**） | 3 条"只差宽度"必红 |
| 4 | `Program.cs:654` 一带（`T2` 记账判定） | 三族**逐族计数 + 等式**（各和 == 总红数），且其它族一位不动 | 新增（隔离矩阵的机器形态） |
| 5 | `T2d` Extent 判定 | 余差条数基线（由 `gen/t2d-extent-mismatches.txt` 重算）；**不改 0.01 容差** | 新增 |

**阳性对照（证明牙活着）**：① 把 `cr.Width` 容差临时设 0 ⇒ 第 3 条那 3 行**必须红**（恢复 ⇒ 绿）；② 把 `cr[0].Width >= 0` 改成 `> −1` ⇒ 第 1 条**必须红**（证明它不是装饰）。
**隔离矩阵**：修完输出"族 × 红数 before/after"表并断言各和 == 总数；**允许变化**的族仅 `A1_nbsp_zwsp`/`B_nbsp_zwsp`/`B_nbsp_zwsp_trim`/`F_nbsp_zwsp`/`F_lat_words`；`M_modifier`、`LH_cjk_punct_*` 等**一位不动**，否则报冲突。

## ③ provenance 缺口：已加 sidecar，**未改 artifact 一个字节**
`gen/t2d-width-diff.provenance.txt` = artifact 名 + **sha256 d1c46e980309df6d888dcdb1b6f73a2b9bfa3b204f4d783805e39ca1952884d4** + 头行原文 + mtime/size + 同趟另两份 artifact 的 sha 行（# 被测 shim sha256 = 7C2E0107A9C8618027D327179269ABEE6D8D329EC1CD89194A412B06B1687274）+ 口径字段名。
**并把"生成器无条件印 `# 被测 shim sha256` 头行"并进 `#12` 的 harness 版本升级**（同一波，**不单独 bump 版本** —— 单独 bump 会让 #10 读数变成"跨 harness 版本不可比"，违反纪律 15）。

---

# 附 · #12 落地件（**设计稿，等主控信号才动 `Program.cs`**；纪律 15：#11 读数未取完/未冻前不许改）

## A. 头行修法（主控 ① 归我）：**源 sha ≠ 编进 PC 的 shim** 必须看得出来
**病**：`ShimSha256()`（`Program.cs:928`）取 `T1B_SHIM_PATH`/默认**源文件**的 sha，标签却写"被测 shim sha256" ⇒ 19:34:12 那趟头行 `B4C7AA82…`（新源）而 `pc 628e7416…`（19:10:18 旧件）。
**修（贴上去就能编译的形态，落在 `ShimSha256()` 调用处与三份 artifact 的头行生成处）**：
```csharp
// Program.cs（同一波改，别单独 bump 版本）
private const string ShimRel = "build/shims/PresentationCore.HbTextLine.cs";
private static string ShimSourceSha() => Sha256Of(Root + "/" + ShimRel);

/// 编进 PC 的那一份 shim 的 sha：从 PC 工程的源指纹表里找这一行（找不到 ⇒ "unknown"，**不猜**）
private static string ShimEmbeddedShaOrUnknown()
{
    string fp = Root + "/build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt";
    if (!File.Exists(fp)) return "unknown(无 ARTIFACT-SRC-FP.txt)";
    foreach (string l in File.ReadAllLines(fp))
        if (l.Replace('\\', '/').Contains(ShimRel)) return l.Split('=')[^1].Trim();
    return "unknown(FP 未列该文件)";
}

private static string ShimStaleFlag()
{
    string s = ShimSourceSha(), e = ShimEmbeddedShaOrUnknown();
    if (e.StartsWith("unknown")) return "unknown";                  // 答不出就报 unknown
    return string.Equals(s, e, StringComparison.OrdinalIgnoreCase) ? "false" : "true";
}
// 头行（三份 artifact 用同一个函数，**无条件印**）：
//   # 被测 shim 源 sha256   = <ShimSourceSha()>
//   # 编进 PC 的 shim sha256 = <ShimEmbeddedShaOrUnknown()>   hbtextline_shim_stale=<ShimStaleFlag()>
//   # 仪器 = run.sh tline @ <DateTime.Now>   pc=<pc dll sha>   applocal=<同步状态>
```
**构造性验证（我落完必做）**：在源文件**改一行注释** ⇒ 不重建 PC ⇒ 重跑 ⇒ 头行必须出现 `源 sha ≠ 编进 PC 的 shim sha256` 且 `hbtextline_shim_stale=true`；把注释改回、重建 PC ⇒ `false`。**只改注释**（不改语义），并按纪律 16 存整份 + 记 sha，验完还原。

## B. #12 断言代码形态（**放进 `okDetail` 那一处，`Program.cs:476`**）
```csharp
// ① 第一判据：宽度不得为负（契约级，当前 F_nbsp_zwsp_w40#3 = −3.0560 ⇒ 必红）
bool crNonNegative = cr != null && cr.Count == 1 && cr[0].Width >= 0;
// ② 起止与真机一致（8 条里 5 条当前必红）
bool crSpanOk = cr != null && cr.Count == 1
    && cr[0].TextSourceCharacterIndex == Ecr.GetProperty("TextSourceCharacterIndex").GetInt32()
    && cr[0].Length == Ecr.GetProperty("Length").GetInt32();
// ③ 宽度容差沿用既有 0.34（**不放宽、也不改桶阈值**）
double eCrW = Ecr.GetProperty("Width").GetDouble();
bool crWidthOk = cr != null && cr.Count == 1 && Math.Abs(cr[0].Width - eCrW) < 0.34;

bool okDetail = collapsed.Length == eLen2 && dW < 0.34 && crNonNegative && crSpanOk && crWidthOk;
if (!crNonNegative) colSamples.Add($"      [契约] {id} 行#{i}: cr.Width={cr[0].Width:F4} < 0 —— 宽度为负不合法");
```
## C. 族计数等式 + 隔离矩阵（`Program.cs:654` 一带，`T2` 判定处）
```csharp
// 逐族红数（键=族名去 _wNN/_winf）+ 等式断言：各和 == 总红数
var famRed = new SortedDictionary<string, int>();
foreach (string k in widthDiffRows.Where(r => r.Contains(">0.34 DIP")).Select(r => FamilyOf(r)))
    famRed[k] = famRed.GetValueOrDefault(k) + 1;
bool famSumOk = famRed.Values.Sum() == widthDeltaLarge;      // 47 == 各和
Console.WriteLine("   [隔离矩阵] 族 × >0.34 红数：" + string.Join("  ", famRed.Select(kv => $"{kv.Key}={kv.Value}"))
                  + $"  各和={famRed.Values.Sum()} == 总数 {widthDeltaLarge} : {(famSumOk ? "OK" : "**FAIL**")}");
// 只允许这些族在本波变化；其它族出现变化 ⇒ 打印 **冲突** 并以非零退出
string[] mayChange = { "A1_nbsp_zwsp", "B_nbsp_zwsp", "B_nbsp_zwsp_trim", "F_nbsp_zwsp", "F_lat_words" };
```
**基线对照方式**：跑前把上一趟的族表落盘（`gen/t2d-family-baseline.txt`），跑后逐族 diff；**允许变化的族仅 `mayChange`**，否则报冲突（不自动改判据）。

## D. 阳性对照（**可执行步骤 + 谁改/谁还原**，纪律 16：改前存整份 + 记 sha）
| 步骤 | 谁 | 改哪一行 | 期望 | 还原 |
|---|---|---|---|---|
| ① | **我**（`build/MilBridge/**` 是我的车道） | `Program.cs:479` 的 `< 0.34` **临时**改 `< 0`（**同一趟只此一处**，改前 `cp Program.cs /tmp/Program.cs.bak-<sha>` 并记 sha） | 3 条"只差宽度"的行（`F_nbsp_zwsp_w40#1`、`w40#3`、`w80#1`）**必须红** | 用备份还原并**再跑一次**确认回到原读数（列出 before/after 两个族表） |
| ② | **我** | 把 `cr[0].Width >= 0` 临时改 `> -1` | 第 1 条（`F_nbsp_zwsp_w40#3`）**必须红** ⇒ 证明它不是装饰 | 同上 |
| ③（可选） | **我** | 把 `hg` 之外不动 | — | — |
**注**：两步都在**同沙箱、同 harness 版本**内做；步骤结束必须回到基线 sha（报告里写 before/after 的 `Program.cs` sha）。

## E. 同波落地顺序（主控 ③-3 的问题）
1. **T1d 先落 shim 的修**（`build/shims/**` 单一 owner）并报 **shim 源 sha + PC 件 sha**；
2. **我在同一趟读数里验**（头行 A 节会同时印"源 sha/编进 PC 的 sha/`hbtextline_shim_stale`" ⇒ 跨树当场可判）；
3. **PC 重建由主控协调**（**不许两人同时发波**）；我这一波只动 `build/MilBridge/**`（`Program.cs` + 生成器头行 + 断言 + 牙 + sidecar 刷新）；
4. 完成后我交：逐族 before/after 表 + 等式断言 + 阳性对照 ①② 的红/绿记录 + 刷新后的 `gen/t2d-width-diff.provenance.txt`。

---

# 附 · #12 开工前更正（主控 ①②，2026-09-14 晚）—— **仪器不存在 + 真值列缺口**

## 更正 1：`T1B_ROW_DUMP` / `[ROWD]` **是待新建的开关，不是既有仪器**
主控实测：`grep -rn "T1B_ROW_DUMP" build/MilBridge/` 只命中本 ledger（第 94 行）、`[ROWD]` 只命中本 ledger（101-103），`run.sh`/`Program.cs` **零命中**（正对照：`TAB_LINES`/`t2d-` 能命中 ⇒ 不是仪器瞎）。
⇒ 我上一节写的是**设计**，但没写清"这是要新建的" ⇒ **并入 #12 的 harness 版本升级清单第 (a) 项**。**#12 四件（同波、我车道）**：
| 项 | 内容 | 归属 |
|---|---|---|
| **(a)** | `[ROWD]` 行级**逐字符** dump 开关（新建：`T1B_ROW_DUMP=<case#line,…>`） | **我** |
| **(b)** | 三族断言 + **`cr.Width >= 0`** | **我** |
| **(c)** | 头行贴标签修（源 sha / 编进 PC 的 sha / `hbtextline_shim_stale`） | **我** |
| **(d)** | `--known-red`（`--tab-lines-oracle` 恒 `exit 0` 那条） | **T1d（CoverageProbe 侧）** |

## 更正 2：🔴 逐字符列**没有真值** —— 不许凭空印
我们的 oracle（`results-cd2.json` 等）**只有行级** `len/w/ws/witw/extent`，**没有逐字符 advance 真值** ⇒ `adv=我们/真值` 会变成"编造的真值"（本项目最忌的一族：仪器打出来的东西 ≠ 它想说的东西）。
**改后的 `[ROWD]` 输出格式（真实形态）**
```
[ROWD] 头：case=A1_nbsp_zwsp_w20 行#7 cp=[a,b)
       我们{len,w,ws,witw,extent}   真值{同五字段, source=tests/parity/windows/layout-b34/results-cd2.json（行级）}
[ROWD] c=<cp> U+XXXX <char> adv_ours=<x> cum_ours=<y> mark=NBSP|ZWSP|blank-tail|other   truth=NA(source=行级 oracle 无逐字符真值)
[ROWD] 小计：adv_ours 和=<x>  Δ行宽 = 我们 − 真值 = <d>  |  ws 我们=<n> 真值=<m>（行级，可比）
              |  WITW−W 我们=<p> 真值=<q>（行级，可比）  |  Extent 我们=<r> 真值=<s> Δ=<t>
[ROWD] VERDICT=<A|B|C|D|E>
```
**承载判别力的算术**（唯一有真值参与的那一步）：**行级真值 + 我们逐字符 advance**
⇒ 若 `Δ行宽 == 该字符的 adv_ours`（且方向一致）⇒ "我们把这一格算进去了／漏掉了"的**直接证据**；`ws` 与 `WITW−W` 两侧都是**行级**字段 ⇒ **可比**，可直接下判。

## 四（+E）结局判据表 · 最终版（每条写清**两侧数据来源**）
| 结局 | 读数特征（数据来源逐条注明） | 含义 | 下一步 |
|---|---|---|---|
| **A 假设成立**（行尾空白口径差） | ① `ws`：**行级可比** —— 我们 `>0` 而真值 `0`；② `WITW−W`：**行级可比** —— 我们 == `adv_ours(该字符)`、真值 == `0`；③ `Δ行宽 == −adv_ours(该字符)`（真值侧来自**行级** `w`） | NBSP/ZWSP 被我们排除、真机计入 | 修 `#12`：`ws` 与 `WITW−W` 同改；断言 `ws == 真值`（行级） |
| **B 假设不成立** | `ws` 与 `WITW−W` 两侧**都一致**（行级可比、且相等），但 `Δ行宽` 仍非 0 且**不等于任何单字符 `adv_ours`** | 扣的不是行尾空白 | 转查 advance 和 / folding |
| **C 第二机制**（行度量） | `ws`/`WITW−W` 一致，而 `adv_ours 和`（我们侧）与行级真值 `w` 的差 **不落单字符** | advance/行度量（与折叠无关） | 归 `#12` 行度量子项或单列一档 |
| **D 答不出（仪器层）** | dump 缺失／字段缺失／`T1B_SHIM_SHA256` ≠ 生成器自报（跨树） | 无信息 | **报无信息，不报绿** |
| **E 答不出（真值层）** | 该列本身**没有真值**（如逐字符 `adv`）⇒ 输出显式 `truth=NA(source=…)` | 无信息 | **报无信息**；只允许用"行级真值 + 我们逐字符"的**算术**间接下判 |

---

# 附 · (c) 头行改动的**最终定性**（主控 2026-09-14 晚自我更正后；**不是"错标"**）

**定性更正（主控读码后推翻了自己的理由，我按新定性写）**：
`HbTextLineParity.csproj:35` = `<Compile Include="$(HbShimSrc)" Link="PresentationCore.HbTextLine.cs" />` ⇒ **harness 把 shim 源文件本身编进自己的程序集**，
且有 **T0.1/T0.2 身份自检 + 探针目录 PC 与权威件 4/4 一致**（`Program.cs:84-129`）
⇒ **`gen/*` 头行那个 sha16 就是"本次读数真正测的那一份"（本 harness 直接编入的源）** ⇒ 读 harness 的人看到的是**对**的；19:34:12 那趟本身就是自洽的。

**仍然要改的两点（定性 = "标签有歧义 + 缺仪器版本"，**不是**"贴错标签"）**：
1. 标签没说清是"**编进本 harness**"还是"**编进 PC**"⇒ 读者会混（主控本人就是这么读错的）；
2. artifact **不带仪器版本**（`run.sh` / `Program.cs` 的 sha16）⇒ 违反纪律 18 的四元组。

**改动后的头行（(c) 最终形态，并进 #12 四件）**
```
# 被测 shim 源 sha256（本 harness 直接编入） = <ShimSourceSha()>
# PC 内 shim sha256                         = <从 ARTIFACT-SRC-FP.txt 取；取不到 ⇒ unknown，不猜>
# hbtextline_shim_stale                     = <true|false|unknown>
# 仪器 = run.sh <sha16> / Program.cs <sha16>    pc=<pc dll sha16>   applocal=<同步状态>
```
**构造性验证（判据不变）**：源改一行注释、**不重建 PC** ⇒ 重跑 ⇒ **两行不同** 且 `stale=true`；改回 + 重建 ⇒ 两行相同、`stale=false`。
**为什么这条验证仍然值钱**：它正好把"我读的是 harness 编入的那份"与"用户/PC 实际在跑的那份"**摆在同一行上**，谁都不用再推理。


---

# 附 · #12 开工记录（2026-09-14，收到"可以动"信号后）

- **纪律 16 起点已存**：`cp -p tests/HbTextLineParity/Program.cs /tmp/t1b-Program.cs.baseline-9f59572075c639ae`，
  基线 `Program.cs` sha256 = `9f59572075c639ae3242f8c40a3659440e7b5fc06ba4463c4e006c0a49ac5f5e`（mtime 用 `cp -p` 一并保住 ⇒ 后续构造性验证不会自己制造 `stale` 假警报）。
- **时间窗**：主控正在跑受认领的收官波（`WAVE_OWNER=close-wave:master`，`/tmp/closewave11b.log`，
  起因 = T3 量到 `hbtextline_shim_stale=yes`，时间线证明是**同内容重写**触发 mtime 谓词）；
  ⇒ **本轮只动 `build/MilBridge/**`**，**波完前不跑重负载 harness**（读数等"波完"信号）。
- **`stale` 谓词登记为已知仪器局限**（基于 mtime，同内容重写会触发）；修法方向 = 改成**内容比对**
  （`ARTIFACT-SRC-FP.txt` 记录的 shim sha vs 现源 sha）—— **不在本轮**；本轮只把**头行印全**（源/PC/stale/仪器版本）。
- **四件清单**（(a)(b)(c) 我 / (d) T1d）与判据四+E 结局表见上文各节；落地后回报：`[ROWD]` 真实输出原文（含 `truth=NA`）、
  四(+E) 判决表最终版、两条阳性对照红绿 + before/after sha、族计数等式与隔离矩阵 **before（预期红：这正是 (b) 要证明"仪器能红"）**，T1d 修落完后再取 **after**。


---

# 附 · 五个数字各有口径（主控/T3 钉住，2026-09-14；**不变式三元组 = 18/58/17**）

| 数字 | 口径（**不是**同一个量） | 取值来源（可复算） |
|---|---|---|
| **12** | **记账行级**（行级记账不一致的**行数**） | `gen/tline-ledger-lines-<时间>.txt` 的 `# 条数`（= 12） |
| **17** | **记账用例级**（记账不一致的**用例数**） | `gen/tline-detail-full.txt` **段3** 的 `# 段3 … 条数 = 17` |
| **47** | **宽度桶**（逐行宽 vs 真机 `w`，落 `>0.34 DIP` 桶的**行数**） | `gen/t2d-width-diff.txt`：`grep -c '桶=>0.34 DIP'` = 47；头行 `>0.34=47` |
| **58** | **Extent 余差**（逐行 Extent，容差 0.01 DIP 的**行数**） | `gen/t2d-extent-mismatches.txt` 的 `# 合计 58 条` |
| **18** | **折叠明细**（折叠断言的**失败行数**） | `gen/tline-detail-full.txt` **段1** 行数 = 18 = `236 − 218` |

**不变式（跨口径，必须同时成立）**：`18 / 58 / 17` 三者是本轮登记的**不变式三元组**（#11/#12 改动不得让它们变化，除非登记并说明）。
**跨口径禁令**：`47`（宽度桶）**不是**"逐行明细清单的条数"——后者是 `gen/t2d-width-diff.txt` 里 **差>0 的行 = 1131 条**；
两者混用会把"桶阈值"当成"清单规模"。本文档此前把 47 一律写作"**>0.34 DIP 桶的行数**"，**未发现把它当明细条数的写法**（本次核对过 `T1b-family-ledger.md` / `T1b-report.md`）。

## 我的角色变更（主控裁定）：**验证者 + 台账所有者**（`Program.cs` 不再由我改）
落实者 = 新车道 **T1b2**，规格 = 本文档尾部四件清单。**T1b2 交付后我独立复核四项**（任一条不成立就报主控，**不替它圆**）：
1. `[ROWD]` 输出里**没有凭空真值列** —— 逐字符列必须 `truth=NA(source=…)`（第 E 结局）；
2. 两条阳性对照**真的红过**（要 **before/after sha**，不接受"应该会红"）；
3. 族计数等式"各和 == 总数"与隔离矩阵"其它族一位不动"是**机器断言**，不是人眼比对；
4. 头行把"**本 harness 编入的那份**"与"**PC 实际在跑的那份**"**摆在同一行上**（`源 sha / PC 内 shim sha / stale / 仪器版本` 四行形态）。
**本波仪器版本**（我留的基线）：`/tmp/t1b-Program.cs.baseline-9f59572075c639ae`，sha256 `9f59572075c639ae3242f8c40a365944…`。


---

# 附 · 只读核实：`#13` 的 open/close 冲突 + T1b2 仪器四条现场事实（2026-09-14）

## ① U1 请核实的冲突 —— **判：冲突是"假"的（就本语料而言），但有一处我未核，按纪律标出**
**①-2 `lbNull` 是什么（给出处）**
- `build/MilBridge/tools/extract-layout-b34.py:108`：`out["lbNull"] = None if lb is None else lb.get("isNull")`
- `build/MilBridge/tools/analyze-layout-b34.py:181-183`：`lbN = sum(… if L["lbNull"] is False)` / `lbNull = sum(… is True)`，打印 `GetTextLineBreak(): null X 行 / 非 null Y 行`
⇒ **`lbNull` 就是"该行 `GetTextLineBreak()` 是否为 null"**（`isNull=true` ⇒ null），**行级**下发（每个 line 记录一份）。
**未核的一处**（不猜）：Windows 侧 recorder 把 `GetTextLineBreak()` 序列化成 `{isNull: …}` 的那**一行**我没定位到 file:line（我核到的是**消费侧**这两处）；要彻底钉死需 `grep -rn "isNull" tests/parity/windows/layout-b34/src/`。

**①-1 位置 45 上客户端返回了什么（给出处 + 原文）**
- 用例与 note：`tests/parity/windows/layout-b34/src/LayoutOracle/Cases.cs:288-297` —— `M：TextModifier 跨越断行 → 实测 TextLineBreak 的非 null 分支`；`Note = "TextModifier 覆盖 [6,45)，跨越换行点：验证 TextLineBreak 何时非 null"`（**"[6,45)" 只出现在 note 文本里**）。
- 客户端源：`tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs:48-54`（`OracleModifier : TextModifier`，注释引 WPF `TextMetrics.cs:299-308`：**只有该行最后一个 run 的 `TextModifierScope != null` 且末 run 不是 `TextEndOfParagraph` 时才 new `TextLineBreak`**）。
- **`grep -rn "TextEndOfSegment" tests/parity/windows/layout-b34/src/` ⇒ 0 命中**（同一条 grep 对 `TextModifier` 有命中 ⇒ 不是 grep 瞎）⇒ **客户端源码里没有任何地方显式返回 `TextEndOfSegment`**。
⇒ **一句话结论**：**冲突是假的（至少不是"语料与新规则不符"）** —— U1 规则里 `closeIndex = "返回配对 `TextEndOfSegment(1)` 的下标（-1 = 从不关闭）"`，而**本语料的客户端从不发 `TextEndOfSegment`** ⇒ `closeIndex = -1`（从不关闭）⇒ 新规则对这些用例预测 **非 null**，与真值 `lbNull=false` **一致**，**不冲突**；note 里的 `[6,45)` 是**作者意图的描述文本**，不是"45 处素材化了一个关闭点"。
**仍未核（要坐实需一步）**：`TextModel.cs:80+` 的 `GetTextRun` 实体（是否在 45/段末返回 `TextEndOfRun`/`TextEndOfLine` 之类会**间接**关闭 scope 的 run）。**我没读到那段**（本轮上下文预算到顶）⇒ 按纪律标"未核"，**不给估计**。核它只需 `sed -n '80,130p' …/TextModel.cs`。
**对 `#13` 的含义**：本语料**证明不了** "必须传两个位置"；但也**没有**给出"45 会关闭"的证据 ⇒ `#13` 的 shim 侧该传"两个位置（open/close）"还是"(start,length)"，**要等上面那一处读完**（以及 U1 的 53 例里有没有真正发 `TextEndOfSegment` 的构造）才能定。

## ② T1b2 仪器的四条现场事实（我独立取数；**未复跑 harness**，除注明外均为文件级核对）
| # | 事实 | 我的取数（命令 + 结果） | 判定 |
|---|---|---|---|
| 1 | `[ROWD]` **没有凭空真值列** | `grep -c 'truth=NA' gen/t1b2-rowdump-final.txt` ⇒ **38**；`grep -cE 'truth=(?!NA)'` ⇒ **0** | ✅ 成立（`truth` 只出现 `NA`） |
| 2 | 两条阳性对照**真的红过** | **我只做了文件级核对，未复跑**（按你给的口径②允许的写法）。需要的话我用当前 live 仪器 `6e077361609f02ad` 复跑两条对照腿并把红绿 + before/after sha 补上 | ⚠️ **未复跑** |
| 3 | 族计数等式 / 隔离矩阵是**机器断言** | `Program.cs:775` `bool famSumOk = famSum == widthDeltaLarge;`；`:820 bool isoOk = isoBaselineOk && isoConflicts.Count == 0;`；`:821 bool isoMachineOk = isoOk && famSumOk;`；`:830/:833` 把两者写进 artifact 头注释（`各和=… == 总数 … : OK/FAIL`、`隔离性 = OK/**冲突**/**未判定（无基线）**`） | ✅ 机器断言成立（两处布尔并进落盘文本；**未逐行核到它们是否并进 `coreOk`/退出码**——这一点我标"未核"） |
| 4 | 头行把两份摆在同一行 | `Program.cs:1447-1450`：`# 被测 shim 源 sha256（本 harness 直接编入） = …` / `# PC 内 shim sha256 = …` / `# hbtextline_shim_stale = …（原因）` / `# 仪器 = run.sh <sha16> …` | ✅ 成立；**`PC 内 shim sha = unknown` 的理由也成立**：`grep -c HbTextLine build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` ⇒ **0**（FP 里确实没有逐文件行） |

**答不出的项（逐条列出"还需要什么"）**：①①-1 的 `GetTextRun` 实体（`sed -n '80,130p' TextModel.cs`）；②②-2 的复跑（一次 harness 跑 + 两条对照腿）；③③ 的 `isoMachineOk` 是否并进 `coreOk`/退出码（`grep -n "isoMachineOk" -A3 -B3 Program.cs`）。


---

# ⚠️ 就地更正（2026-09-14，**保留原文、不涂改历史**）：我的"死代码 ⇒ 退出码可能为 0"结论**部分被推翻**

**我原来的写法（上文"② 现场事实 3"那一节）**："`isoMachineOk`/`famSumOk` 是死代码 ⇒ 基线冲突时只打印 `**冲突**`、**退出码仍可能为 0**"⇒ 我据此判"判定 ③ 成立"作废、改判"判据未接线"。
**T1b2 的反证（原文级）**：`:994/1001 bool machineOk = famSumOk && isoOk;` —— **同一表达式** —— 接了两处：`Check("T2-iso", …)` 与 `:1121 return coreOk && collapseOk && machineOk ? 0 : 1;`。
**我自己的独立复核（本次，只读）**：
```
:1001  bool machineOk = famSumOk && isoOk;
:1121  return coreOk && collapseOk && machineOk ? 0 : 1;
grep -nE '^\s*(bool machineOk|return coreOk)' Program.cs   ⇒ 2 行（1001 / 1121）✅
grep -cE '^\s*bool isoMachineOk'  Program.cs               ⇒ 0 ✅（残留仅注释）
awk 'NR>=960 && NR<=1120 && /return /'                      ⇒ 该区间内无 return（只命中一条注释）
```
⇒ **裁定：T1b2 的反证成立，我原来的风险claim不成立** —— 基线冲突 ⇒ `isoOk=false` ⇒ `machineOk=false` ⇒ 唯一 `return` 的合取项为假 ⇒ `rc=1`。
**我错在哪（同类教训，值得记）**：我**只 grep 了"死变量那个名字"**（`isoMachineOk`），看到"只此一处"就下了"整条判据没接线"的结论 —— 而真正接线的是**逐字等价的另一个名字**（`machineOk`）。
这正是本项目已登记多次的"**一个表达式两个消费者 / 只查一处就收工**"家族（与 `grep -c ExportDepth.NotImpl`、`grep -c 0x0102` 是同一族）。
**降级后的真实风险（T1b2 的处置我也认可）**：有人删掉 `machineOk` 的消费点、而旧名字还留着 ⇒ "看起来还在算"。处置 = **删掉死变量**（已删，`:821` 只剩注释）+ 在 `machineOk` 处写明"**唯二接线点**（`Check("T2-iso")` 与唯一 `return`）+ 机检口径"（已在 `:996-1000` 注释里）。
**它如实说明做不到的一腿（我记下、不要求补）**：本树上 `coreOk`（记账 `1292/1298`）与 `collapseOk`（折叠 `219/236`）本就不成立 ⇒ **两腿 `rc` 都是 1 ⇒ 本树上退出码不具判别力**；退出码通路的保证是**静态的**（唯一 return + `machineOk` 是合取项）——**拒绝写"应该会 0"** 是对的。
**它的阳性对照（实测，我未复跑）**：给基线里**不许变**的族 `M_modifier` 注入假 `>0.34` 行 ⇒ `T2-iso` ❌ + 「隔离性 **冲突**；逐族 diff = `M_modifier 8→7`」；还原 ⇒ ✅；两趟其它读数逐项相同（仅 ✅/❌ 计数 `20/8 → 21/6` 变）。
**仪器版本**：本轮 T3 取数用的定版 = `6652f310591cb8bc`（我先前留的基线 `Program.cs` sha16 = `9f59572075c639ae` 已被 T1b2 的改动取代 ⇒ **以 `6652f310…` 为准**）。
