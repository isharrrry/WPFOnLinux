# W79A 报告 —— `TASK-0502`：GIF 多帧解码 ＋ 帧时序（R5 图像）

> **重派说明**：本条原为车道 `W73A`（会话挂起时中途死掉，未交报告，只在 `~/w73a/fix/` 留了一张 197 B 的测试 GIF）。
> 我开工前复算过"仓内无半截改动"：`build/DirectWrite.Linux/wic-shim/wic_proxy.c` mtime = **09-19 12:16**（正是 `#49` 冻结前的那一版），
> `libwpfwic.so` sha16 = **`56278c14b4ecd672`**（`#40` 波 F 重建后一直未变）。**下述"修前读数"全部是这一版现场实测，不是转述。**
>
> **本件属于波 `#50` 的第一批落地件**（波 `#49` 已于 2026-09-21 冻结：`BASELINE-FROZEN gen=#49 sha16=f1d340d66c7c6ba3`，`docs/CURRENT-STATE.md:9`；
> 本件改的是 `libwpfwic.so` ⇒ **`wic_shim` 那一位必动**，位移清单见 §6）。

---

## 0 结论（先给判词）

| 项 | 读数 |
|---|---|
| 判定点 | `build/DirectWrite.Linux/wic-shim/wic_proxy.c` **修前 `:1030-1035`**：`IWICBitmapDecoder_GetFrameCount_Proxy` **恒 `*pFrameCount = 1;`**（`:1034`）；`GetFrame` 同步把 `index != 0` 一律 `E_INVALIDARG`（`:1043`） |
| 修前帧数 | 3 帧 GIF ⇒ `COUNT=1`（真值 3）；4 帧 GIF ⇒ `COUNT=1`（真值 4） |
| 修后帧数 | 同上 ⇒ `COUNT=3` / `COUNT=4`（**逐帧像素与真值逐字节相同**） |
| 帧时序 | `/grctlext/Delay` 修前 = `WINCODEC_ERR_UNSUPPORTEDOPERATION`（**读不到**）⇒ 修后 `VT_UI2` 逐帧相符（10/20/30 cs 与 5/10/15/20 cs） |
| 三侧 | **正 PASS（`fails=0 noinfo=0`，rc=0）｜反 FAIL（rc=1）｜假修 3/3 全被打红（`SELFTEST=PASS liars=3 caught=3`）** |
| 零回归 | 单帧 PNG / JPEG / 单帧 GIF 的第 0 帧 **逐字节相同**（4 例，含 3 帧 GIF 的第 0 帧） |
| 新 `wic_shim` | **`f7b3026c8c019be2`**（74984 B；修前 `56278c14b4ecd672` / 70728 B）；导出集合 **仍 96 条、逐条相同**（无新导出／无掉导出） |
| 动的世代位 | **只有 `wic_shim`**（依据：`build/close-wave.sh:362`）；`inputs_fp` **不动**（覆盖面不含本目录，见 §6） |
| 已知边界 | `disposal=2` 的**后续帧** Skia 自己报 `kInvalidConversion(3)` ⇒ 我们**如实失败**（`E_UNEXPECTED`），**不假装成功**（§7 `NOINFO-2`） |

---

## 1 判定点（文件:行，全部现场读过）

修前（现已在备份件 `$HOME/w79a/pre/wic_proxy.c`，sha16 `d0ff278005c315d5` 里逐字复核）：

```
build/DirectWrite.Linux/wic-shim/wic_proxy.c:1030  int32_t IWICBitmapDecoder_GetFrameCount_Proxy(void *decoder, uint32_t *pFrameCount)
build/DirectWrite.Linux/wic-shim/wic_proxy.c:1034      *pFrameCount = 1;                    /* 本 shim 只支持静态图：1 帧 */
build/DirectWrite.Linux/wic-shim/wic_proxy.c:1043      if (index != 0) return E_INVALIDARG;  /* 静态图只有第 0 帧 */
```

**上游契约**（我读的是仓内上游源，不是记忆）：
- `upstream/.../PresentationCore/System/Windows/Media/Imaging/BitmapDecoder.cs:1438`
  `HRESULT.Check(UnsafeNativeMethods.WICBitmapDecoder.GetFrameCount(_decoderHandle, out numFrames));`
  ⇒ `Frames.Count` 直接等于这一格的返回值 ⇒ **恒 1 就等于"这张 GIF 只有一帧"**（`GifBitmapDecoder` 只是 `BitmapDecoder` 的薄壳，见 `GifBitmapDecoder.cs:24-70`）。
- 帧的元数据入口 `BitmapFrameDecode.cs:636`：`if (hr != (int)WinCodecErrors.WINCODEC_ERR_UNSUPPORTEDOPERATION) HRESULT.Check(hr);`
  ⇒ **该码被容忍**（`_metadata = null`）——这正是修前"读不到延迟"的表现形态。

**往前推一格（本件新增的机器事实）**：帧数**取不到真值**不是因为 Skia 没有这个能力，而是因为 shim 从来没去问。
`libSkiaSharp.so` 实测导出 `sk_codec_get_frame_count`（`nm -D` 现场：`0000000000074270 T sk_codec_get_frame_count`），
且 `sk_codec_get_pixels` 的 `options` 里**有 `fFrameIndex` 这一格**（反推依据见 §3.1）。

---

## 2 修前读数（现场，冻结件 `56278c14b4ecd672`）

夹具（自造，真值可预言；生成器 = `frames-gen.py`，**自己写 GIF 编码器**因为 Pillow 9.0.1 的 GIF 写出会把
"子矩形 + 透明"摊平成整幅不透明黑 —— 实测 4 帧 rect 全丢，那种夹具根本测不到子矩形/透明两格）：

| 夹具 | 结构（我的解析器给的，非意图） | 三方独立核对 |
|---|---|---|
| `g1-3f-solid.gif` | 32×24，3 帧整幅纯色，rect 全 `(0,0,32,24)`，delay `10/20/30` cs，disposal 1，无透明 | Pillow 帧数 3 ✓；`identify` `0:32x24 d=10 1:32x24 d=20 2:32x24 d=30` ✓ |
| `g2-4f-partial.gif` | 40×30，4 帧，rect `(0,0,40,30)/(2,2,8,8)/(20,10,10,10)/(5,20,10,10)`，帧 1..3 **透明**，delay `5/10/15/20` cs | `identify` `0:40x30 d=5 1:8x8 d=10 2:10x10 d=15 3:10x10 d=20` ✓ |
| `g6-disposal2.gif` | 24×20，3 帧，帧 1 disposal=**2**（还原背景） | `identify` 3 帧 ✓ |
| `g5-1f.gif` / `g3-1f.png` / `g4-1f-jfif.jpg` | 单帧 GIF / PNG(17×13，含 α=128) / 仓内既有 JPEG 夹具副本 | — |

**探针**（`frames-probe.c`，走 shim 的 `*_Proxy` 导出 —— 与 PC 同一批入口）：

```
# 修前：3 帧 GIF
GETFRAMECOUNT_HR=0 COUNT=1                       ← 判定点读数：真值 3
OOR_INDEX=1 OOR_HR=-2147024809 (0x80070057 E_INVALIDARG) OOR_HANDLE=null
GETFRAME i=0 HR=0                                ← 只有第 0 帧拿得到
FRAME  i=0 SIZE=32x24 COPY_HR=0 FIRST=0000FFFF FNV=535c51f9fb7ee183
FRAMEMETA i=0 HR=-2003292287 (0x88982F81 UNSUPPORTEDOPERATION) READER=null    ← 延迟读不到
# 修前：4 帧子矩形 GIF
GETFRAMECOUNT_HR=0 COUNT=1                       ← 真值 4
FRAME  i=0 SIZE=40x30 COPY_HR=0 FIRST=FFFFFFFF FNV=2afeb1939588b1c3
FRAMEMETA i=0 HR=-2003292287 READER=null
```

**逐帧内容**：修前"第 1..N-1 帧"**根本取不到**（`GetFrame(1)` 就是 `E_INVALIDARG`）——
不是"取了但内容不对"，是**连帧都拿不到**。
**时长**：`/grctlext/Delay` 修前一律 `UNSUPPORTEDOPERATION`（PC 侧 `BitmapFrameDecode.cs:636` 容忍 ⇒ `Metadata == null`）。

---

## 3 修法（逐处；`wic_proxy.c` `d0ff278005c315d5` → `f0d3d1501aebcd8c`，120512 → 130592 B）

改动**只落在一个文件**：`build/DirectWrite.Linux/wic-shim/wic_proxy.c`。11 处，逐处如下（行号是**修后**现场行号）：

| # | 位置（修后行号） | 改了什么 | 为什么 |
|---|---|---|---|
| 1 | `:563-569` | 新增 `sk_codec_options_t`（`{i32 zero_initialized; i32 _pad; void*subset; i32 frame_index; i32 prior_frame;}`，24 B） | 选帧要靠 `fFrameIndex`；**布局是反推的**（§3.1），注释里写了依据 |
| 2 | `:627` | `skia_load()` 增 `dlsym(..., "sk_codec_get_frame_count")` | 可选绑定：**不进** `return` 的与式 ⇒ 老 Skia 不该让整个解码面失效 |
| 3 | `:121-122` | `wic_obj` 加 `frame_index` / `frame_count` 两格 | 帧对象要记住"我是第几帧"；解码器缓存已探明帧数（幂等） |
| 4 | `:189-190` | 新增 `is_gif_bytes()` | 容器识别（与既有 `is_png_bytes`/`is_jpeg_bytes` 同族） |
| 5 | `:202-272` | 新增 `gif_frame_delay_cs()` —— **自己按 GIF89a 走块结构**取 GCE 的 Delay | Skia 的 C API **不暴露**帧延迟；`/grctlext/Delay` 本来就是**容器自己**的语义。只读、不分配；结构不认识就返回 0（→ `PROPERTYNOTFOUND`），**不猜** |
| 6 | `:393-402` | 新增 `pv_set_ui2()` | GIF 延迟在 WIC 里是 `ushort`（上游 `PropVariant.cs:18`「ushort <=> VT_UI2」、`:516` ToObject 分支） |
| 7 | `:407-435`（GIF 分支 `:413-417`） | `meta_has_any()`：**GIF 的帧**若确有 GCE ⇒ 1 | 否则 `GetMetadataQueryReader` 一律 `UNSUPPORTEDOPERATION`，延迟永远不可达。**只对 `KIND_FRAME` 生效**，解码器级元数据面一字不变 |
| 8 | `:1171-1186` | 新增 `decode_frame_count()`（**单一取数点**） | `sk_codec_get_frame_count` 真值；缺符号 / 返回 ≤0 ⇒ 按 1 帧**并打具名台账** `FRAME_COUNT_NOINFO reason=…`（**不是静默降级**） |
| 9 | `:1189-1202` | `GetFrameCount` 改为"开解码器 → 问真帧数" | 判定点本体。开不出解码器 ⇒ 返回那个 hr（可达性论证见 §6 脚注） |
| 10 | `:1205-1232` | `GetFrame` 改为"越界才失败"，并给帧对象写 `frame_index`（`:1228`） | 越界仍 `E_INVALIDARG`（**沿用既有语义**：上游 `wgx_error.cs` 里**没有** `FRAMEMISSING` 这一类，不无中生有） |
| 11 | `:691-720`（`decode_pixels`，帧分支 `:711-720`）＋ `:1470-1481`（`GetMetadataByName`） | `frame_index > 0` 时 options 带 `fFrameIndex = o->frame_index`（`:716`）；`/grctlext/Delay` 分支返回 `VT_UI2` | 逐帧像素 + 帧时序 |

### 3.1 `SkCodec::Options` 的布局是**反推**的（不是抄头文件）

`objdump -d libSkiaSharp.so` 里 `sk_codec_get_pixels`（`0x740b0`）收 NULL options 时，会在 .so 内部构造一份默认值：

```
207f7b: mov $0x5,%ebp            ; 5 = kInvalidParameters（像素指针为 NULL 时的返回码，与既有注释吻合）
208011: movl $0x1,0x30(%rsp)     ; +0  = 1   （kNo_ZeroInitialized = Skia 默认）
208019: movq $0x0,0x38(%rsp)     ; +8  = NULL（fSubset）
208022: movabs $0xffffffff00000000,%rax
20802c: mov %rax,0x40(%rsp)      ; +16 = 0（fFrameIndex）｜+20 = -1（kNoFrame）
20803b: mov 0x8(%r13),%rax       ; options+8 被当**指针**解引用（进一步坐实 fSubset 的位置）
```

**四变体实测**（`explore_opts.c`，直接绑 Skia；两份夹具 × `{NULL, 独立解, 从 0 重放} × {zi=0,1}`）：

| 变体 | 3 帧整幅 | 4 帧子矩形 | 结论 |
|---|---|---|---|
| `V1` NULL（＝修前 shim 的调用） | 永远第 0 帧 | 永远第 0 帧 | 病根 |
| `V2` 独立解 `{.zi=1, subset=NULL, frame=i, prior=-1}` | 逐帧真值 **逐字节相同** | 逐帧真值 **逐字节相同** | **采用这一条** |
| `V3` 同 V2 但 `zi=0` | 同 V2 | 同 V2 | 两值等价 ⇒ 用 Skia 默认值 `1` |
| `V4`/`V5` 从 0 重放（`prior=k-1`） | 同 V2 | 同 V2 | **V2 ≡ V4 逐位相同** ⇒ 不必重放（Skia 自己按 `frameInfo.requiredFrame` 补前置帧） |

⇒ 修法选 **V2**：一次解码/帧、无 O(N²) 开销。**逐字段照抄默认值**，只改 `frame_index`。

### 3.2 帧延迟的真值三方一致

`sk_codec_get_frame_info_for_index(codec,i,buf)` 的 `+4` 是 duration(ms)：实测 3 帧 = `100/200/300`，
与**我构造的** `10/20/30` cs 逐值相符；`identify` 也报 `d=10/20/30`。但**实现**没走这条路（那又是一处未文档化的 ABI 面），
而是走 §3.5 的自带 GIF 解析 ⇒ 探针里 `DELAY` 与真值 TSV（由 `frames-gen.py` 独立解析得出）逐帧相同。

---

## 4 三侧读数（正 / 反 / 假修）

判据 runner：`build/DirectWrite.Linux/wic-shim/frames-check.sh`（三态 + 一档 `PARTIAL`；`rc=0` **只在 `PASS` 且 `noinfo=0`**）。
硬判据 6 格：`H1` 帧数、`H2` 逐帧内容（**逐字节**比真值）、`H3` 帧间互不相同、`H4` 越界必须失败、
`H5` 倒序/正序**逐字节**相同、`D1` 帧时序（未实现 ⇒ `NOINFO`，`NA`）、`Z1` 零回归（`--baseline`）。

### 4.1 正极性（新件 `f7b3026c8c019be2`）

```
case g1-3f-solid:   PASS H1=PASS(count=3) H2=PASS(逐字节) H3=PASS(n=3 两两不同) H4=PASS(GetFrame(3) hr=-2147024809) H5=PASS(倒序/正序逐字节相同) D1=PASS(VT_UI2 逐帧相符)
case g2-4f-partial: PASS H1=PASS(count=4) H2=PASS(逐字节) H3=PASS(n=4 两两不同) H4=PASS(GetFrame(4) hr=-2147024809) H5=PASS(倒序/正序逐字节相同) D1=PASS(VT_UI2 逐帧相符)
case g5-1f:         PASS H1=PASS(count=1) H2=PASS(逐字节) H3=NA(单帧)          H4=PASS(GetFrame(1) hr=-2147024809) H5=PASS(倒序/正序逐字节相同) D1=PASS(VT_UI2 逐帧相符)
case g3-1f:         PASS H1=PASS(count=1) H2=PASS(逐字节) H3=NA(单帧)          H4=PASS(GetFrame(1) hr=-2147024809) H5=PASS(倒序/正序逐字节相同) D1=NA(非 GIF)
case g4-1f-jfif:    PASS H1=PASS(count=1) H2=PASS(逐字节) H3=NA(单帧)          H4=PASS(GetFrame(1) hr=-2147024809) H5=PASS(倒序/正序逐字节相同) D1=NA(非 GIF)
WICFRAMES=PASS fails=0 noinfo=0 obs=g6-disposal2:FAIL shim16=f7b3026c8c019be2      rc=0
```
（`obs=` 那一格是**观测档**，刻意写进结论行 ⇒ 不许被读成"全都好"；它的 FAIL 见 §7。）

### 4.2 反极性（**还原修法** ⇒ 必须回到"只出第 0 帧"）

`--selftest` 用**文本手术**在源码副本上造三只撒谎 shim（每处断言"锚恰好出现 1 次"，造不出来就 `LIAR_SURGERY=FAIL`，
**不许静默跳过**）：

| 撒谎 shim | 手术（锚 ⇒ 替换） | 模拟的真实假修形态 | 实测判词 |
|---|---|---|---|
| `neg` | `if (o->frame_count > 0) return o->frame_count;` ⇒ 强制 1 | **把修法还原**（＝修前行为） | `WICFRAMES=FAIL fails=2`（H1/H2/H3/H5 三格连带）→ **被打红** ✓ |
| `fake_px` | `opts.frame_index = o->frame_index;` ⇒ `= 0` | 帧数真、**像素恒第 0 帧**（"静默 no-op"式假修） | `FAIL fails=2`（**H2 逐字节 + H3 两两不同**抓住）→ ✓ |
| `fake_pair` | `if (index >= (uint32_t)n) {` ⇒ `if (0) {` | **`GetFrameCount` 仍 1、却给得出第 1 帧**（声明与行为不一致） | `FAIL fails=5`（H1+H4 直接点破）→ ✓ |

```
SELFTEST=PASS liars=3 caught=3（三只撒谎 shim 全部被打红）      rc=0
```

**为什么 `fake_px` 必须被内容格抓住**：它 `H1` 帧数对、`COPY_HR=0` 全绿 —— 只查状态码的判据**对它零射程**。
本案的 `H2`（逐字节比真值）＋`H3`（帧间两两不同）就是那两颗牙。

### 4.3 越界与序（两格的现场读数）

```
OOR:   GetFrame(3) on 3-frame GIF → hr=-2147024809（E_INVALIDARG），handle=null     ← 不许"给得出第 3 帧"
次序:  倒序取(pass0) 与 正序取(pass1) 逐帧 **逐字节相同**（H5）
幂等:  同一帧取两次同码同内容（H2 两趟都查）
```

---

## 5 零回归（单帧图逐位不变）

`--baseline <修前 shim>` 模式：同一探针、同一夹具、只换 shim，比第 0 帧的 BGRA 缓冲**逐字节**。

```
case Z1-g3-1f:      PASS 第 0 帧与基线逐字节相同 sha16=fb456f2b32d28e43     （PNG 17×13，含 α=128）
case Z1-g4-1f-jfif: PASS 第 0 帧与基线逐字节相同 sha16=0636c17d86c9f5c7     （JPEG 8×8）
case Z1-g5-1f:      PASS 第 0 帧与基线逐字节相同 sha16=d114a30cb04c88dd     （单帧 GIF）
case Z1-g1-3f-solid:PASS 第 0 帧与基线逐字节相同 sha16=2719505479289ffd     （3 帧 GIF 的第 0 帧）
```

**为什么它按构造不变**：`decode_pixels` 只在 `frame_index > 0` 时改走 options 分支（`:711-720`，帧号写在 `:716`）——
第 0 帧与静态图**仍然那一行 `options=NULL` 的老调用、一字未改**；`GetFrameCount` 对 PNG/JPEG 问出来仍是 1。
**导出集合也逐条相同**（`diff <(nm -D 修前) <(nm -D 修后)` → `EXPORT SET IDENTICAL`，96 条）⇒ 不动任何 `[DllImport]` 面。

---

## 6 新 `wic_shim` 与"会动哪些世代位"

```
build/DirectWrite.Linux/wic-shim/libwpfwic.so
   修前 56278c14b4ecd672  70728 B   （= #49 冻结口径里的 `wic_shim`）
   修后 f7b3026c8c019be2  74984 B
build/DirectWrite.Linux/wic-shim/wic_proxy.c
   修前 d0ff278005c315d5 120512 B
   修后 f0d3d1501aebcd8c 130592 B
```

| 指纹 | 会不会动 | 依据（现场读过） |
|---|---|---|
| **`wic_shim`** | **必动** | `build/close-wave.sh:362` `wic_shim=$(sha16 build/DirectWrite.Linux/wic-shim/libwpfwic.so)` |
| `bridge` / `pc` / `pf` / `windowsbase` / `provider` / `win32shim` / `hbtextline` / `dwf` | **本件不动**（我一件产物都没重建） | `close-wave.sh:356-364` 逐位列；我只跑了 `build-wic-shim.sh` |
| `inputs_fp` | **不动** | 覆盖面是 `src/WpfGfx.Linux.Native/**/*.{c,h}`（`close-wave.sh:124-125`）、`build/shims/**/*.cs`（`:108`）、`src/WpfGfx.Linux/**/*.cs`（`:115`）、四个路由件、以及 `:211-212` 点名的仪器清单 —— **`build/DirectWrite.Linux/wic-shim/**` 不在其中**（我只新增了 `frames-*.{c,py,sh}`，也没改 `check-applocal-sync.sh` / `applocal-expect.py` 这两个**在册**的读者） |
| `BRIDGE_SRC_FP` | 不动 | 桥源 FP 与 wic shim 无关（`publish-milbridge.sh:31/44` 只是把 shim **拷**进 publish 目录） |

⚠️ **一个流程注意（不是我造成的、但会被我触发）**：`close-wave.sh` 的第 `[4/6]` 步断言 `IN_FP_0 == IN_FP_1`，
而 `#49` 已经把 `src/WpfGfx.Linux.Native/**/*.c` 纳进覆盖面，并写明"**改原生源必须安排在 `IN_FP_0` 采样之前**"（`:123`）。
本件改的是 `build/DirectWrite.Linux/wic-shim/` ⇒ **不在那条约束里**。

### 6.1 波尾必做的两件（**我没做，也不该由我做**）

1. **app-local 副本刷新**（权威件换了 sha ⇒ 4 份副本变 `STALE`）：
   ```
   bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply     # 判据本体 = check-applocal-sync.sh
   ```
   现场 B/A：修前 `APPSYNC=MISMATCH（MISMATCH=1[STALE=1]）` ⇒ 修后 **`MISMATCH=5[STALE=5]`**，新增 4 条点名如下
   （`check-applocal-sync.sh` 自己声明"**本脚本不改写任何目录**"）：
   ```
   STALE build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/libwpfwic.so  EXPECT f7b3026c8c019be2 ACTUAL 56278c14b4ecd672
   STALE build/MilBridge/.artifacts/bin/ClosedLoop/release/libwpfwic.so                       EXPECT f7b3026c8c019be2 ACTUAL 56278c14b4ecd672
   STALE samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwic.so                              EXPECT f7b3026c8c019be2 ACTUAL 56278c14b4ecd672
   STALE samples/ThirdPartyMini/bin/Debug/net10.0/libwpfwic.so                                 EXPECT f7b3026c8c019be2 ACTUAL 56278c14b4ecd672
   ```
   （`close-wave.sh:335` 会把 `APPSYNC` 非 PASS 打出来 ⇒ 不刷副本，波尾就会多一条**可解释但多余**的红。）
2. **硬链接已断**（如实报）：修前 `libwpfwic.so` 是 **2 链接**（仓内 + `~/w62a/negrepo/...` 的**另一条车道的负样例仓**）。
   我用 `build-wic-shim.sh` 重建后：仓内 = **1 链接**、`~/w62a/...` 那份**仍是旧字节 `56278c14b4ecd672`**。
   ⇒ **没有**把别人保存的负样例悄悄换掉（这是好事），但**两份已不再是硬链接**；后续若有人按"硬链接"假设去比对，会得到不同结论。

### 6.2 接线点（波尾自行决定；**我不改 `verify-all.sh`**）

```bash
run_step "WIC-FRAMES" bash build/DirectWrite.Linux/wic-shim/frames-check.sh
```
判据自带反极性：`bash build/DirectWrite.Linux/wic-shim/frames-check.sh --selftest`（三只撒谎 shim 必须全红）。

---

## 7 `NOINFO` 清单（既不算绿也不算红，逐条给"谁在读/读不到会怎样"）

| # | 条目 | 现状 | 边界与理由 |
|---|---|---|---|
| 1 | **托管级端到端**（真的用 `GifBitmapDecoder` 跑一个 WPF 应用） | **未跑** | 本件全程**零 dotnet**（用户内存纪律：同时只跑一个重活；本轮机器可用内存只有 2–3 GB）＋ `samples/**` 里**没有任何 GIF 载体**（加一个会落进别人的写域）。**代理级契约已证**：我调的就是 PC 调的那批 `*_Proxy`（`GetFrameCount` / `GetFrame` / `CopyPixels` / 帧元数据）⇒ 未证的是"PC 拿到 `Frames.Count=3` 之后的行为"，那属于 PC 侧既有代码（`BitmapDecoder.cs:1438`） |
| 2 | `disposal=2` 的**后续帧** | **Skia 自己拒绝**：`sk_codec_get_pixels` 返 `res=3`（`kInvalidConversion`）⇒ shim 返 `E_UNEXPECTED`（`COPY_HR=-2147418113`），**如实失败** | 四种选帧变体（V2/V3 独立解 zi=1/0、V4/V5 从 0 重放 zi=1/0）**全都 res=3** ⇒ 不是我选错参数。⇒ "还原背景"语义这一格**本轮不落地**（不假装成功）。要真做需自己按 disposal 维护画布（`gif_frame_delay_cs` 那层结构已经在了，是下一步的落点） |
| 3 | 帧延迟的**消费方** | 修后"读得到"（`VT_UI2`，逐帧相符），但**谁在 managed 侧读它**：WPF 自己的 `GifBitmapDecoder` **不读**（薄壳，无计时器）；Windows 上动图是**应用**自己用 `BitmapFrame.Metadata.GetQuery("/grctlext/Delay")` + 定时器做的 | 所以本件给的是**能力**（该查询从 `UNSUPPORTEDOPERATION` 变成 `VT_UI2`），不是"WPF 会自动播动图"——**WPF 在 Windows 上也不会**。⚠️ 附带行为变化：GIF 帧的 `BitmapFrame.Metadata` 由 `null` 变成**非 null** 的 `BitmapMetadata`（构造器只存句柄 `BitmapMetadata.cs:608-621`；`GetQuery` 对 `PROPERTYNOTFOUND` **返回 null**（`:1098`）⇒ 未取到的键仍是 null，不会新增抛点） |
| 4 | 非 GIF 的多帧格式（APNG / 动画 WebP / 多页 TIFF） | **未测**（无夹具） | 修法对它们**同样生效**（走的是 Skia 的帧数/帧号，与容器无关），但"逐帧内容正确"这一格**只有 GIF 有读数** ⇒ 按未测记 |
| 5 | 大 GIF / 长动画的性能 | **未测** | 现在每帧一次解码、无缓存；`GetFrame(i)` 是 O(1) 次解码（**不是** O(i)）⇒ 比"重放"方案好，但"PC 逐帧遍历 N 帧"总代价 = O(N)。N=100 的动图没测过 |
| 6 | `FRAMEMISSING`（越界帧的上游专用码） | **未采用** | 仓内上游 `wgx_error.cs` 里检索 **0 命中**（`grep -rn FRAMEMISSING upstream/.../PresentationCore` = 空）⇒ 沿用既有的 `E_INVALIDARG`，**不无中生有**造一个新错误码给 PC 去映射 |
| 7 | `wic_proxy.c:202` 的 **3 个真 NUL 字节** | **未动**（别人的既有件） | 那是注释里把 `\0` 写成了**实字节**（`keyword\0 compFlag …`）⇒ `file` 判它 `data`、`grep -n` 只肯说"匹配到二进制文件"**不给行号**。**这条会影响所有 grep 这个文件的人**（纪律 55 的"grep 陷阱"又多一格），我没顺手改（会污染本件 diff），建议主控登记 |

---

## 8 内存三值（用户强制纪律）

```
开工免费：MemAvailable = 2162 MB（total 7923 / used 5429）
收工免费：MemAvailable = 2969 MB（total 7923 / used 4649）
本件最低（我实际采到的）：2162 MB（开工那一下）
```
- **本轮零 dotnet、零应用、零 Xvfb**（`frames-*.sh` 全是 gcc + python3 + C 探针）⇒ `heavy-slot.sh` **一次都没用上**，
  也不存在"同时两条重活"。
- ⚠️ 如实说：**"最低"这一格我没有连续采样**（只在开工/收工各取一次 + 中途几次 `free -m`）⇒ 若要求"全程最低"的严格读数，那属于 `NOINFO`（未连续监测）。

---

## 9 大白话小结（≤6 行）

1. **病根**：WIC 代理里有一行"帧数恒等于 1"，于是不管 GIF 有几帧，WPF 都只当它是单张图 —— 多出来的帧连"拿"的机会都没有。
2. **修法**：改成向 Skia 问真实帧数（`sk_codec_get_frame_count`），并让 `GetFrame(i)` 真的解第 i 帧（Skia 的 `options` 里本来就有"帧号"这一格，位置是从二进制里量出来的）。
3. **顺手把"帧时长"也接上了**：GIF 帧的 `/grctlext/Delay` 以前一律读不到，现在读得到（毫秒→1/100 秒的那种单位），因为 GIF 的壳子本来就是我们自己在解析。
4. **三面都验过**：新件全绿；把修法还原回去立刻变红；三种"假修"（尤其"帧数说 3 帧、像素全给第 0 帧"这种）**全部被逐字节的内容判据抓住** —— 这份判据不是只查状态码的空尺子。
5. **静态图一个字节都没动**（PNG/JPEG/单帧 GIF 逐位相同），导出符号也没增没减。
6. **还差两件**：① 有一种 GIF（前一帧声明"还原背景"）的**后续帧 Skia 自己拒绝解** ⇒ 我们如实报错，没假装成功；② 权威件换了 sha，波尾要**刷 4 份 app-local 副本**，否则 `close-wave` 会多打一条 APPSYNC 告警。

---

## 10 复算命令（逐条可跑）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# 判定点（修前那两行在哪里）
sed -n '1030,1045p' "$HOME/w79a/pre/wic_proxy.c"            # 修前件（本件开工时的备份，sha16 d0ff278005c315d5）
echo '修前 sha16：'; sha256sum "$HOME/w79a/pre/libwpfwic.so" | cut -c1-16   # 56278c14b4ecd672

# 判据（三态 + 反极性 + 零回归）
cd /tmp && bash "$R/build/DirectWrite.Linux/wic-shim/frames-check.sh"                  # WICFRAMES=PASS … rc=0
         bash "$R/build/DirectWrite.Linux/wic-shim/frames-check.sh" --selftest          # SELFTEST=PASS caught=3 … rc=0
         bash "$R/build/DirectWrite.Linux/wic-shim/frames-check.sh" \
              --shim "$HOME/w79a/pre/libwpfwic.so"                                     # 修前件 ⇒ WICFRAMES=FAIL rc=1
         bash "$R/build/DirectWrite.Linux/wic-shim/frames-check.sh" \
              --shim "$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so" \
              --baseline "$HOME/w79a/pre/libwpfwic.so"                                 # 追加 Z1 零回归四例

# Skia 侧 ABI 事实（选项布局、帧数符号、帧时长）
nm -D --defined-only "$R/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so" | grep -E 'sk_codec_(get_frame_count|get_frame_info|get_pixels)'
objdump -d --start-address=0x208011 --stop-address=0x208031 "$R/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so"
$HOME/w79a/bin/explore_opts "$R/build/DirectWrite.Linux/wic-shim/libSkiaSharp.so" /tmp/w79a-final/fix/g2-4f-partial.gif /tmp/exp-dump

# 位移与副作用
echo "wic_shim=$(sha256sum "$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so" | cut -c1-16)"
diff <(nm -D --defined-only "$HOME/w79a/pre/libwpfwic.so" | awk '{print $3}' | sort) \
     <(nm -D --defined-only "$R/build/DirectWrite.Linux/wic-shim/libwpfwic.so" | awk '{print $3}' | sort)  # 空 = 导出集合相同
timeout 180 bash "$R/build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh" | grep -E 'libwpfwic|APPSYNC='   # 4 条 STALE（待波尾刷）

# 本件新增件
for f in frames-probe.c frames-gen.py frames-compare.py frames-check.sh frames-.sh; do :; done
for f in frames-probe.c frames-gen.py frames-compare.py frames-check.sh; do
  printf '%-18s %s\n' "$f" "$(sha256sum "$R/build/DirectWrite.Linux/wic-shim/$f" | cut -c1-16)"; done
```

**本件新增/改动的件一览（仓内）**

| 件 | 状态 | sha16 |
|---|---|---|
| `build/DirectWrite.Linux/wic-shim/wic_proxy.c` | 改（11 处） | `f0d3d1501aebcd8c`（修前 `d0ff278005c315d5`） |
| `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | 重建 | **`f7b3026c8c019be2`**（修前 `56278c14b4ecd672`） |
| `build/DirectWrite.Linux/wic-shim/frames-probe.c` | 新建（C 探针） | `761ed2d6b8bac1bc` |
| `build/DirectWrite.Linux/wic-shim/frames-gen.py` | 新建（夹具＋真值生成器） | `2dc16474fa34f9bc` |
| `build/DirectWrite.Linux/wic-shim/frames-compare.py` | 新建（判据本体） | `f877719effb31bd8` |
| `build/DirectWrite.Linux/wic-shim/frames-check.sh` | 新建（三态 runner） | `11a7f2a07c0fe2d0` |
| `build/MilBridge/W79A-report.md` | 新建（本报告） | 见文件尾（写完正文再补） |
| **写域外** | **一字节未碰** | 四个路由件 / `known-red.json` / `defect-registry-declared.tsv` / `verify-all.sh` / `build/shims/**` / `src/**` 全部未改 |

> 复核方式：`find "$R" -newermt '-90 minutes' -type f -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*'`
> 会列出本件之外**别的车道同时段**改过的件（现场那一刻：`W81A-report.md`、`W81AWindowProbe/**`、`W77A-report.md`、
> `defect-registry-declared.tsv`、`build-hygiene-roster.tsv`、`KNOWN-DEFECTS.md`、`ROUTES.md` 等）——
> 那些**不是我的改动**，我一件都没碰；我的改动集合就是上表 6 行（`find` 已现场核过：写域内 18:18 之后只有那 7 个件）。

---

## 11 边界与我没做到的事（一句话清单）

1. **托管级端到端没跑**（零 dotnet，见 §7-1）——代理级契约已证，PC 侧行为未实测。
2. **`disposal=2` 后续帧**：Skia 自己拒绝（`kInvalidConversion`）⇒ 如实失败，**没有**自己维护画布去合成（§7-2）。
3. **非 GIF 多帧格式（APNG/WebP）未测**（无夹具；修法通用，但没读数）。
4. **性能未测**（长动画 O(N) 次解码，N 大没试过）。
5. **app-local 4 份副本未刷**（不是我的写域；命令已给 §6.1）。
6. **`wic_proxy.c` 里那 3 个 NUL 字节没顺手改**（会污染本件 diff；已登记建议 §7-7）。
7. 本报告自身的 sha16 见文末机器行；**该值覆盖的是「不含末行」的正文**（自指哈希不可能自洽 —— 这里如实写明口径，而不是给一个编出来的值）。


> W79A-REPORT-BODY sha16=7f8c7fd14abe8ff8（正文 sha，不含本行）file=build/MilBridge/W79A-report.md
