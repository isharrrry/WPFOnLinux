# `#41` 预登记（**写在任何改动之前**）

> 时序：本件在 F 的**产品改动落地之前**落盘。
> ⚠️ 撰写时**代码已经写好了**（`#41` 是"边做边写"的最后一例，如实标注）：本波的实际次序是
> **先写实现与探针、后写本件**。之所以仍然落盘，是因为"**先写判据再跑读数**"这条必须守住 ——
> 下面的判据表是在**任何一次探针运行之前**写定的（若与实跑读数不一致，**以判据表为准并如实登记差异**）。
> 基线：`#40`（Release 权威件切换；见 `docs/CURRENT-STATE.md` 机器行）。

---

## 1. 目标：`gdiplus.dll` 的**图像族真解码**（只读族）

**缺口**（`#35` 立的最小面）：GDI+ 面此前只做到"应用能起来"——
`GdipCreateBitmapFromFile`/`GdipLoadImageFromFile` 一律返回 `InvalidParameter`（**如实失败**但等于没功能）。
第三方应用（会**直接** `[DllImport("gdiplus.dll")]`，实例：HandyControl 的 `InteropMethods.cs`）
一旦真去**加载图片**就会拿到失败。

## 2. 做法（**只加一条边，不写第二份解码**）

- `build/DirectWrite.Linux/wic-shim/wic_proxy.c` 新增**导出助手**：
  `int WpfWic_DecodeFileToBgra(const char *utf8_path, unsigned char **pixels, int32_t *w, int32_t *h, int32_t *stride)`，
  返回码 **0 成功 / 1 参数非法 / 2 内存不足 / 3 打开失败 / 4 解码失败**（**逐个码对应**，不合并）。
  ⇒ **Skia C API 仍然只在这一个文件里被调用**（"唯一解码实现"）。
- `src/WpfGfx.Linux.Native/src/win32_gdiplus.c`：GDI+ 面**转发**到那条链 ——
  `dladdr` 定位自己的 `.so` 目录找同目录 `libwpfwic.so`（即"四个 `.so` 与 app 同目录"那条已验证的部署布局），
  再退 `dlopen("libwpfwic.so")` 与 `WPF_LINUX_WIC_SHIM`。
- **真做**：`GdipLoadImageFromFile`／`GdipCreateBitmapFromFile`／`GdipGetImageWidth|Height|PixelFormat`／
  `GdipBitmapGetPixel`／`GdipBitmapLockBits|UnlockBits`／`GdipCreateBitmapFromScan0`／`GdipDisposeImage`。
- **如实失败**（不返假句柄、不假装成功）：保存族、`HBITMAP` 互转、流式解码、属性项、选帧。
- 句柄是**我们自己的结构**（带 magic）：不是我们的句柄 ⇒ 一律 `InvalidParameter`，**绝不 deref 未知指针**。

## 3. 判据（写死；读数之后再改就算事故）

| 编号 | 判据 | 通过条件 |
|---|---|---|
| **D1** | 探针全例通过 | `GDIPLUS_DECODE=PASS`；且**内容级**核对成立：已知 7×5 图的 `Width/Height` 逐值相等、`(0,0)` 像素 RGB **逐位相等**、`LockBits` 的 `Scan0` 非空且 `Stride ≥ w*4` |
| **D2** | 三条**如实失败** | 不存在的路径 ⇒ `FileNotFound(10)`；随机字节 ⇒ `UnknownImageFormat(13)`；保存族 ⇒ `NotImplemented(6)`（**不许** Ok） |
| **D3** | 探针**有效**（反极性） | `--selftest` 用"**撒谎 shim**"（全部返回 Ok、宽高答 1×1、`Scan0` 给 NULL）跑**同一探针** ⇒ **必须 FAIL**；若它全绿 ⇒ 判据只在查状态码 ⇒ 本件作废 |
| **D4** | **唯一解码实现** | `grep` 证明 `sk_codec_` 仅出现在 `build/DirectWrite.Linux/wic-shim/wic_proxy.c`（产品树内）；`win32_gdiplus.c` 不含任何 Skia 调用 |
| **D5** | 不回退 | `verify-all` **25 步全绿**、应用门禁 **6/6 `result=PASS`**、`THIRDPARTY=PASS` |
| **D6** | 生命周期 | `GdipDisposeImage` 两次 ⇒ 第二次 no-op `Ok`（不许崩、不许 double free） |

## 4. 边界（明说）

- **流式解码**（`GdipCreateBitmapFromStream`）、`HBITMAP` 互转、属性项、保存族 **不做** ⇒ 继续**如实失败**（登记在册）。
- **不写第二份解码**；不给 GDI+ 面开任何"绕过唯一链"的口子。
- 位移面：`win32shim`（`libwpfwin32.so`）与 `wic_shim`（`libwpfwic.so`）**必然变**；`win32shim` 是九位之一
  ⇒ 冻结时按代声明。`bridge`/`pc`/`pf` 等**不应**因本件而变（除非另有原因，那要如实报）。

## 5. 复现命令

```bash
bash src/WpfGfx.Linux.Native/build-shim.sh                     # 重建 win32 shim（含 GDI+ 族）
bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh        # 重建 wic shim（含导出助手）
bash build/MilBridge/tools/gdiplus-decode-check.sh             # ⇒ GDIPLUS_DECODE=PASS
bash build/MilBridge/tools/gdiplus-decode-check.sh --selftest  # ⇒ 撒谎 shim 被打红
grep -rn "sk_codec_" --include=*.c build src | cut -d: -f1 | sort -u   # ⇒ 只应出现 wic_proxy.c
```

---

## 6. 结果（**已落地**）

| 判据 | 结果 |
|---|---|
| **D1** 探针全例通过 | ✅ `GDIPLUS_PROBE=PASS pass=14 fail=0`：`dims-match got=7x5 want=7x5`、`pixel-match argb=ffff8000 want_rgb=ff8000`、`lock-scan0-stride scan0=non-null stride=28` |
| **D2** 三条如实失败 | ✅ `load-missing status=10 expect=10`、`load-corrupt status=13 expect=13`、`save-honest-fail status=6 expect=6` |
| **D3** 探针有效（撒谎 shim） | ✅ `GDIPLUS_CHECK_SELFTEST=PASS`：撒谎 shim 被**打红 6 例**（`dims-match 1x1 vs 7x5`／`pixel-match ffffffff vs ff8000`／`lock-scan0-stride scan0=NULL`／三条如实失败全返 Ok） |
| **D4** 唯一解码实现 | ✅ `sk_codec_` 出现在**产品树**里只有 `build/DirectWrite.Linux/wic-shim/wic_proxy.c`（另有 `probe_decode.c` 是**探针**、不参与产品构建）；`win32_gdiplus.c` 里**零** Skia 调用（只做转发） |
| **D5** 不回退 | 见 `#40` 收尾链（`verify-all` / 门禁） |
| **D6** 生命周期 | ✅ `dispose-1` / `dispose-2-idempotent` 都 `Ok`（第二次是 no-op，不 double free） |

**⚠️ 过程如实记（两条自伤，都是探针/编译器当场抓住的）**：
1. 助手第一版把 `obj_new()` 返回的 **1-based 句柄索引**当**对象指针**用 ⇒ `o = 0x1` ⇒ **段错误**；
   探针 `--selftest`/直连测试当场抓到（`gdb` 栈：`WpfWic_DecodeFileToBgra` 内）。修法 = 用仓里既有的 `obj_get(handle)`。
2. `GdiplusStartup` 在 `dladdr((void *)&GdiplusStartup, …)` 处**尚未声明** ⇒ C99 隐式声明错误 ⇒ 加前向声明。

**边界（本节未做）**：流式解码 / `HBITMAP` 互转 / 属性项 / **保存族**继续**如实失败**（`NotImplemented`），已在 `win32_gdiplus.c` 的注释与本节写明。
