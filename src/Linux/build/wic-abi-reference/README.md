# Skia C API 参考事实（实测，非推测）—— 供 WIC shim 使用

> **建立者**：主控（2026-09-10）。**用途**：T2 的 WIC shim（`build/DirectWrite.Linux/wic-shim/`）要在 C 里直接调
> `libSkiaSharp.so` 的 C API 解码，而**机器上没有任何 `sk_*.h`**（`find / -name sk_codec.h` → 空）。
> 本目录用**可复现的实测**替代头文件，逐条给出结论与证据。
>
> **复现**：`cd build/wic-abi-reference/AbiProbe && PNG=<某 PNG 绝对路径> dotnet run -c Release`
> 原始输出见同目录 `abi-proof-output.txt`。探针不依赖本工程任何其它代码，只用 SkiaSharp 2.88.9（T0 锁定的版本）。

---

## 0. 一句话结论

`libSkiaSharp.so` 的 `sk_imageinfo_t` 布局**不是**上游 Skia 公开头文件里的那个顺序。
按公开头文件的顺序写，`sk_codec_get_pixels` 返回 **5（`InvalidParameters`）**——
**这正是 T2 上一轮 `GET_PIXELS=5` 的根因**（不是枚举猜错，是**结构体字段顺序**错）。
按实测顺序写，返回 **0**，且**全缓冲区 1,920,000 字节与托管 `SKBitmap.Decode` 逐字节相同（0 处不同）**。

---

## 1. `sk_imageinfo_t` 布局（**A/B 对照实测**）

```
偏移  字段         类型
  0   colorspace   void*      (sk_colorspace_t*)
  8   width        int32
 12   height       int32
 16   colorType    int32      (sk_colortype_t，注意用下表的值)
 20   alphaType    int32      (sk_alphatype_t)
                      总大小 24 字节（x86-64）
```

**A/B 实测（同一个 `sk_codec_get_info` 入口，只换结构体声明）**：

| 布局 | `sk_codec_get_info` 填出来的内容 |
|---|---|
| **A（实测正确）** `{colorspace,width,height,colorType,alphaType}` | `w=800 h=600 colorType=6 alphaType=1 cs=<有效指针>` ✅ |
| **B（上游公开头文件顺序）** `{colorType,alphaType,colorspace,width,height}` | `colorType=<垃圾> alphaType=<垃圾> w=6 h=1` ❌ |

⇒ 结论：**SkiaSharp 2.88.9 自带的 `libSkiaSharp.so` 用的是 A**。这与上游 Skia `include/c/` 的公开文档**不一致**，
所以**必须以实测为准，不要照抄网上找到的头文件**。

> **来源**：A 的字段顺序不是猜的，是从 `SkiaSharp.dll` **元数据**里读出来的内部结构
> `SkiaSharp.SKImageInfoNative`（`[StructLayout]` + `Marshal.OffsetOf` 逐字段测偏移，`Marshal.SizeOf` = 24）。
> 它是 SkiaSharp 托管侧 P/Invoke 真正 marshal 的那个结构 —— 因此**定义上**就是 native ABI。

## 2. `sk_codec_result_t`（来自托管 `SKCodecResult` 枚举，同名同值）

| 值 | 名 | | 值 | 名 |
|---|---|---|---|---|
| 0 | `Success` | | 5 | **`InvalidParameters`** |
| 1 | `IncompleteInput` | | 6 | `InvalidInput` |
| 2 | `ErrorInInput` | | 7 | `CouldNotRewind` |
| 3 | `InvalidConversion` | | 8 | `InternalError` |
| 4 | `InvalidScale` | | 9 | `Unimplemented` |

## 3. ⚠️ `sk_colortype_t` 的 C API 值 **≠** 托管 `SKColorType` 值 —— 必须用这一列

| 值 | C API (`SKColorTypeNative`) | 托管 `SKColorType`（**不要用**） |
|---|---|---|
| 0 | Unknown | Unknown |
| 1 | Alpha8 | Alpha8 |
| 2 | Rgb565 | Rgb565 |
| 3 | Argb4444 | Argb4444 |
| 4 | Rgba8888 | Rgba8888 |
| 5 | Rgb888x | Rgb888x |
| **6** | **Bgra8888** | **Bgra8888**（一致） |
| 7 | Rgba1010102 | Rgba1010102（一致） |
| **8** | **Bgra1010102** | Rgba1010102=7… 托管侧 `Bgra1010102`= **19** ❌ |
| **9** | **Rgb101010x** | 托管侧 `Rgb101010x`= **8** ❌ |
| **10** | **Bgr101010x** | 托管侧 `Bgr101010x`= **20** ❌ |
| **11** | **Gray8** | 托管侧 `Gray8`= **9** ❌ |
| **12** | **RgbaF16Norm** | 托管侧 `RgbaF16Clamped`= 11 ❌ |
| **13** | **RgbaF16** | 托管侧 `RgbaF16`= **10** ❌ |
| 14 | RgbaF32 | RgbaF32（一致） |
| 15 | R8g8Unorm | Rg88=13 ❌ |
| 16 | A16Float | Alpha16=16（同名不同值） |
| 17 | R16g16Float | RgF16=15 ❌ |
| 18 | A16Unorm | — |
| 19 | R16g16Unorm | — |
| 20 | R16g16b16a16Unorm | — |

**从 8 起两套值就分叉了**，而 `Bgra8888 = 6` 恰好一致 —— 这也是为什么 T2 上一轮
`colorType=6 alphaType=1` **看起来是对的**（Bgra8888/Opaque），却仍然失败：**问题在结构体布局，不在枚举值**。

`sk_alphatype_t`（两边一致）：`Unknown=0, Opaque=1, Premul=2, Unpremul=3`。

## 4. 函数契约（实测可用的调用序列）

```c
typedef struct { void* colorspace; int32_t width, height, colorType, alphaType; } sk_imageinfo_t;   /* 24 B */

void*  sk_data_new_with_copy (const void* src, size_t length);   /* 返回 sk_data_t* */
void   sk_data_unref         (sk_data_t*);                       /* ⚠️ 没有 sk_data_destroy 这个符号 */
void*  sk_codec_new_from_data(sk_data_t*);                       /* 返回 sk_codec_t*，失败为 NULL */
void   sk_codec_destroy      (sk_codec_t*);
void   sk_codec_get_info     (sk_codec_t*, sk_imageinfo_t* out); /* ⚠️ 返回 void —— 别读它的返回值 */
int    sk_codec_get_pixels   (sk_codec_t*, const sk_imageinfo_t* info,
                              void* pixels, size_t rowBytes,
                              const sk_codec_options_t* options); /* 返回 sk_codec_result_t */
```

- **`info` 是「指针」入参**：C 侧要传 `&info`。传值 / 传错间接层 ⇒ 直接 `InvalidParameters(5)`。
- **`options` 可以传 `NULL`** —— 实测 `hr=0`，不需要构造 `sk_codec_options_t`。
- `rowBytes` 对 `Bgra8888` = `width * 4`；缓冲区需 `rowBytes * height` 字节。
- ⚠️ **`sk_codec_get_info` 的返回值是垃圾**（实测 `hr=495380192` / `1944996944` 之类随机值），
  它**没有 HRESULT 语义**，**不要拿它判断成败** —— 只看它有没有把结构体填对，或改看 `sk_codec_get_pixels` 的返回。

## 5. 实测输出（`abi-proof-output.txt` 摘录）

```
[managed SKBitmap.Decode] 800x600 colorType=Bgra8888 alphaType=Opaque
--- A: measured layout {colorspace,width,height,colorType,alphaType} ---
  get_info w=800 h=600 colorType=6 alphaType=1 cs=0x636373EE4C50
  get_pixels hr=0
  FULL-BUFFER compare: bytes=1920000 mismatchBytes=0 firstBadOffset=-1
  STRICT_EQUAL=True   (raw C API vs managed SKBitmap.Decode)
  first NON-WHITE pixel at (22,16) BGRA=102,51,34,255
--- B: classic header order ---
  get_info colorType=<垃圾> alphaType=<垃圾> w=6 h=1
```

**证据强度**：不是"两个采样点相同"，而是 **1,920,000 字节全缓冲区逐字节比较 0 处不同**，
且图**确实有非白内容**（`(22,16)` = BGRA `102,51,34,255`）—— 排除"两边都是空白图所以相等"的假绿。
