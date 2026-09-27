# `V79d-provider-disposition-verify.md` —— `t25` 处置的独立复验（`t9` finding #1 的关账）

车道 `verifier`／`t26`。`N=/home/links-dev/netTest/GitProj/WPFOnLinux`；只读 `$N`（除本报告）；**没有写** `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`~/w186a/w78/**`／`~/w186a/w79/**`／`~/w21-verify/**`（反极性一律在 `~/w28x/t26/` 的**副本**上做）。读数时刻见各节。

## 0. 判词：**`needs_revision`**

| 支 | 现取 | 判 |
|---|---|---|
| ① `#78` 块未改 ＋ 四条引用链 | `d60b414d5e99cf72`（13:32）＋ 四条链逐条自洽 | ✓ **成立** |
| ② dated 更正只增不改，两个值可复算 | `diff` = 234 insertions / **0 deletions**；两个值我现算相符 | ✓ **成立** |
| ③ `BASELINE tier=` 块内 **6**（全件 348） | 我自己数：块内(7–79 行)=**6**、全件=348 ⇒ `t25` 的 6 对、主控早期 7 错 | ✓ **`t25` 判对** |
| ④ 模板占位符化 ＋ 反极性 | 九位行已 `{PRV}`／错值不出现 ／ 我自造反极 ⇒ 命中升到 11 行并点名 | ✓ **成立** |
| **⑤「加牙」这一支** | 牙有 `--template` 面，但**生产路径不给它**（`close-wave.sh:654`）⇒ `skipped(no-template-given)`；**而一旦接上就在 canonical 模板上红**（`WFREEZE_TEMPLATE=FAIL hits=9`，白名单只有 `# ALLOWED-HEX` 前缀，而该前缀会打断 `column-floor-check.sh` 的抽取） | 🔴 **不生效** ⇒ 见 §5-F1 |

## 1. ① 块未被改 ＋ 四条引用链（逐条现取，13:32）

```
sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16   → d60b414d5e99cf72   （== #78 冻结值）
docs/CURRENT-STATE.md:9   → > BASELINE-FROZEN gen=#78 sha16=d60b414d5e99cf72 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
/tmp/bridge-frozen.flag          → BASELINE_SHA16=d60b414d5e99cf72 ｜ PROVIDER=a00895e8158189b9
~/wfp-runs/bridge-frozen.flag    → BASELINE_SHA16=d60b414d5e99cf72 ｜ PROVIDER=a00895e8158189b9
cmp 两哨兵 → IDENTICAL
w78-post1-20260927-110835.log → · 自报口径 BASELINESHA=PASS live=d60b414d5e99cf72 decl=d60b414d5e99cf72
w78-post2-20260927-112348.log → · 自报口径 BASELINESHA=PASS live=d60b414d5e99cf72 decl=d60b414d5e99cf72
```
⇒ 四条链**逐条现取自洽**；附带读数：**两哨兵的 `PROVIDER=` 是 `a00895e8158189b9`**（＝我现算的活树权威值）⇒ 与块内九位行不符，正是 `t9` finding #1 的原样。

## 2. ② dated 更正是否「只增不改」（我自己取 diff）

```
git diff --stat -- build/MilBridge/P0-w78-report.md   → 1 file changed, 234 insertions(+)     deletions = 0
git show HEAD:<件> | wc -l = 143 ；现件 = 377 行；差 = 234
cmp <(git show HEAD:<件>) <(head -n 143 现件)          → IDENTICAL（**HEAD 版是现件的逐字节前缀**）
现件 sha16 = 71b264bf4c827137 ／ HEAD 版 = 4fbf9fee0bfbcc0f
```
- `t25` 声明的基件是 **`t21` 末态**（`948b1f495e6701e1`／228 行），而 `HEAD` 里是更早的 143 行版 ⇒ 我另用算术核：143（HEAD）＋85（`t21` 追加，行 144–228）＋149（`t25` 追加，行 229–377）＝ **377** ✓，且 `§11.8` 位于 `:319`（>228）⇒ `t25` 的追加区间与它自报的 `228a229,377` 相符；**我能机证的部分（HEAD 前缀 ＋ 零删除）都成立**；"基件恰为 228 行"这一点**不可从 git 机证**（`t21` 的落仓未提交）⇒ 记 `NOINFO`（见 §6-N1）。
- **两个值我自己重算**：块内九位行（`ACCEPTANCE-BASELINE.md:66`）`provider` = **`609192a419d125f2`**；活树权威件 `build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll` = **`a00895e8158189b9`** ⇒ 与更正文本 §11.2/:149–151 的记述**逐位相符**，且它把 `609192a419d125f2` 定性改为「**模板写死那一刻的现取值**，不是上一代值」——与 `#77` 块（`:99`）`1f9511a7ef395bfe` 区分开 ✓（这条定性更正我认可：模板 `w78-record.txt:67` 确实是字面量）。

## 3. ③ `BASELINE tier=` 行数（我自己数）

```
grep -c '^BASELINE tier=' 全件                     → 348
sed -n '7,79p' … | grep -c '^BASELINE tier='       → 6      ← #78 块内（抽取域）
sed -n '1,90p' … | grep -c '^BASELINE tier='       → 6      （换域复核，同值）
```
⇒ **块内 = 6**（`t25` 对），全件 = 348（对照口径）。**主控早期的「7 条」是错的**（错因＝把 `PREVCHECK keys=7` 串成块内行数，`t25` 的归因我认可）。**`t25` 没有跟错**：它把两个域分开写、并明确"块内 6／全件 348"。

## 4. ④ 模板占位符化 ＋ 我自己的反极性

（`~/w186a/w79/w79freeze/w79-record.txt`，现取 `52571ef51842467d`／76 行）
```
占位符现取：{PRV}=2 ｜ {WIC}=2 ｜ {PRV_PREV}=1 ｜ {WIC_PREV}=1
:67 **九位（Release 权威件）**…`provider` `{PRV}`／`win32shim` `{WSH}`／`wic_shim` `{WIC}`…
grep 609192a419d125f2 / 1f9511a7ef395bfe 该模板 → 0 命中（错值不在模板里）
#78 模板（`~/w186a/w78/w78freeze/w78-record.txt`）→ e7abc00e76f08338（未变）
```
**我的裸 hex 扫描（自写）**：9 命中行／**13 值** —— `:15(2)`／`:16(1)`／`:17(4)`／`:61–66(各 1)`。
**我的反极性（在我的副本上把 `{PRV}` 换回裸 hex）**：替换 **2** 处 ⇒ 命中升到 **15 值／11 行**，新增命中 **`:67`／`:68`** 被点名 ⇒ 判据**真会动** ✓。
⚠️ 与 `t25` 自报的差异：它写「**12** 值／9 行」，我数 **13 值**（多的是 `:16` 的 `f17c41239ffa1408`）；它把反极性后的读数写成 `hits=11`（那是**行数**）与基线 `12`（那是**值数**）**两个口径混用**。⇒ 见 §5-F2。

## 5. 🔴 独立判：**在不改块的条件下，这条缺陷「关住了」吗？** —— **一半**

**关住的部分（真成立）**：① 块保原样（证据价值）＋ 四条链自洽；② **登记成条且可机查**：`build/MilBridge/blockvalues-shift.tsv:14` 有一行逐字记 `provider 609192a419d125f2 a00895e8158189b9 a00895e8158189b9 D-G166 …`，缺陷册里 `D-G166` 命中 **10** 处、`declared.tsv` 命中 1 处 ⇒ 查册／查 tsv 的读者能找到"块内是错的、现取是哪个"；③ **下一代模板已占位符化**（九位行 `{PRV}`／`{WIC}`，错值不在模板里），`#78` 模板未被改（两代可对照）。

**没关住的部分（判 `needs_revision` 的根据）**：

- **F1（中高）「加牙」这一支在生产路径上不生效，且接上就会红**：
  ```
  build/close-wave.sh:654  run "[5c/6] wave-freeze-consistency-check.py" python3 … --root "$ROOT"     ← **不传 --template**
  牙现取（不带 --template）：WFREEZE_TEMPLATE=skipped(no-template-given)（本面不在总体状态里、不算绿）
  我对 **canonical** 模板显式跑：WFREEZE_TEMPLATE=FAIL path=~/w186a/w79/w79freeze/w79-record.txt hits=9
     命中行 = line=15 16 17 61 62 63 64 65 66（与我自己扫的 9 行完全一致）
  牙的模板面白名单（现取）：`… and not l.lstrip().startswith('# ALLOWED-HEX')` ⇒ **唯一的豁免是行首前缀**
  ```
  ⇒ 两条同时成立：**(i) 生产路径根本不给它 `--template` ⇒ 它永不发声**；**(ii) 若主控按处置把它接上，它会在**canonical 模板**上红（`COLUMN-CORPUS` 1 行 ＋ `ARM-LOG-SHA` 5 行 ＋ 声明常量 3 行），而唯一的豁免口径（`# ALLOWED-HEX` 前缀）会**打断 `column-floor-check.sh` 的 `^# COLUMN-CORPUS`／`^# ARM-LOG-SHA` 抽取**（`t25` §11.4 自己测过并否掉 ⇒ 这条路今天走不通）**。⇒「下一代**不可能**再写死」目前只靠**人的纪律 ＋ 仓外 canonical 件**，**机器上没有一颗在生产路径上会响的牙**（本仓 `D-G136`／`run_step` 接了线但不判那一族）。
- **F2（低）`t25` 的读数与现取有 1 值之差，且口径混用**：§11.4 报「12 值／9 行」，我实测 **13 值／9 行**（多 `:16` 的 `f17c41239ffa1408`）；反极性后 `hits=11` 是**行数**（我实测同值：9 → 11），与基线那个"12（值）"不同口径 ⇒ 同一段里两个数不能直接比。
- **F3（中）只读路线文档的读者仍会被误导**：`docs/ROUTES.md` 里 `609192a419d125f2` 命中 **0**、`D-G166` 命中 **0**（§11.8 的转抄文本**未落**，`t25` 已如实声明"本件不落该件"）；`build/MilBridge/HANDOFF-NEXT.md` 只有 `t21` 加的一处值提及（1 处）。⇒ **权威冻结记录本身仍写着错值且块内没有指针**；能被拦住的读者是"查 `blockvalues-shift.tsv`／缺陷册"的那些。**建议**：把 §11.8 那段落进 `ROUTES.md`（一个有独立读者面的件），或给 `#79` 冻结块的九位行下方加一行 dated 指针（不改 `#78` 块 ⇒ 不破坏四条链）。

## 6. 它判 `NOINFO` 的格：我的「可判/不可判」独立判断

| # | `t25` 的 NOINFO/未落格 | 我的判断 |
|---|---|---|
| N1 | 「基件恰为 `t21` 末态 228 行」不可机证 | **同意不可判**（`t21` 落仓未提交 ⇒ 无 blob 可取）；但**可判的替身**我做了：`HEAD`(143) 是现件前缀 ＋ 删除 0 ＋ 行数算术 143+85+149=377 ⇒ **"只增不改"这一结论可判，且成立** |
| N2 | `docs/ROUTES.md` `#79` 段文本未落（§11.8 只给转抄文本） | **可判**：我现取 `ROUTES.md` 对两个关键字零命中 ⇒ 判「未落」，并把它列为 F3（不是 NOINFO，是**未完成的支**） |
| N3 | 变体 B（`# ALLOWED-HEX` 行首前缀）会打断 `column-floor` 抽取 | **我未复跑**该打断（只核了牙的唯一白名单形态就是这个前缀）⇒ 记 `NOINFO`；但**牙接上后在 canonical 模板上红**这一条我**真跑**了 ⇒ F1 成立 |
| N4 | `wave-freeze-consistency-check.py:24` 注释仍写「7 条」 | **可判且成立**（我 grep 到该注释，属"件头自述 vs 现读 6"一族，低危） |

## 7. 边界与 NOINFO（我自己的）

1. `t21` 落仓前的基件 blob 不可得 ⇒ 「228 行基件」只给算术与 HEAD 前缀两条机器证（不清求完全机证）。
2. 我**没有**复跑「`# ALLOWED-HEX` 前缀会打断 `column-floor`」；只核了牙的白名单形态。
3. 我**没有**在真树跑 `close-wave.sh [5c/6]`（会写/改状态）⇒ 「生产路径不传 `--template`」由**源码现取**判定（`:654` 那一行逐字），属**静态可判**。
4. `~/w186a/w78/**`／`~/w186a/w79/**` 我只读；反极性一律在 `~/w28x/t26/` 的副本上做。

`T26_DISPOSITION_VERIFY=DONE verdict=needs_revision block=d60b414d5e99cf72(13:32) chains=4/4 self-consistent dated-correction=append-only(0 del)+值复算符 tier-block=6(全件348,t25对) template=placeholder-ized(52571ef51842467d)+我自造反极11行点名 加牙=未生效(close-wave:654不传--template ⇒ skipped;显式跑canonical模板=FAIL hits=9) routes-pointer=0 findings=3(F1中高/F2低/F3中) noinfo=4`
`SELF_SHA16=39935a6e99684577`（口径＝去掉本行：`head -n -1 build/MilBridge/V79d-provider-disposition-verify.md | sha256sum | cut -c1-16`）
