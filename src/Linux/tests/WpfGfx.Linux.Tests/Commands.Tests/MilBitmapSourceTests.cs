// Licensed to the .NET Foundation under one or more agreements.
//
// 命令字 0x0c MilCmdBitmapSource / 0x0d MilCmdBitmapInvalidate 的测试。
//
// 三件事分开测，避免"解码成功"被当成"画出来了"：
//   1. 结构偏移（§A）—— 与上游逐字节对齐的机械护栏
//   2. 命令语义（§B–§D）—— 令牌传递 / 格式 / 尺寸边界 / 失效
//   3. 真的画出来了（§E）—— 离屏渲染后**逐像素断言**
//
// 【§E 为什么必须存在】
//   前两层只能证明"位图对象被正确登记到了资源上"。要证明位图真的进入了
//   渲染管线，必须走 命令字节 → 资源状态 → BitmapResolver 钩子 → SKCanvas
//   → 像素 这条完整链路，并在**目标矩形内外**各取一点：
//     内点 == 位图颜色  → 位图真的画出来了
//     外点 == 背景色    → 画的是那个矩形，不是糊满整张画布
//   同时断言 Diagnostics.NotDrawn 为空 —— 否则渲染层可能静默跳过了这条指令，
//   而背景色恰好也是白色，光看像素会漏判。

using System;
using System.Buffers.Binary;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using S = WpfGfx.Linux.Commands.MilCommandStructs;

namespace WpfGfx.Linux.Tests.Commands
{
    public class MilBitmapSourceTests
    {
        // ==============================================================
        //  §A 结构偏移（审计结论的机械护栏）
        // ==============================================================

        /// <summary>
        /// 0x0c 的权威源是 C++ 头 wgx_commands.h:86（C# 生成版没有这个结构），
        /// 所以 verify-cmd-layout.py 比对不到它 —— 这条测试是它**唯一**的机械护栏。
        /// </summary>
        [Fact]
        public void 位图源命令偏移与上游C加加头一致()
        {
            // 上游：MILCMD Type; HMIL_RESOURCE Handle; IWICBitmapSource* pIBitmap;
            //   HMIL_RESOURCE == UINT32（wgx_core_types.h:60），指针 8 字节且自然对齐到 8
            //   → 0/4/8，sizeof == 16。Linux 侧把最后 8 字节改作位图令牌，宽度不变。
            Assert.Equal(0, Marshal.OffsetOf<S.MILCMD_BITMAP_SOURCE>("Type").ToInt32());
            Assert.Equal(4, Marshal.OffsetOf<S.MILCMD_BITMAP_SOURCE>("Handle").ToInt32());
            Assert.Equal(8, Marshal.OffsetOf<S.MILCMD_BITMAP_SOURCE>("BitmapToken").ToInt32());
            Assert.Equal(16, Marshal.SizeOf<S.MILCMD_BITMAP_SOURCE>());
            Assert.Equal(16, MilCommandLayout.FixedSize(MilCmd.MilCmdBitmapSource));
        }

        [Fact]
        public void 位图失效命令偏移与上游C井版一致()
        {
            // 上游 C# 版 wgx_commands.cs:62：Type@0 Handle@4 UseDirtyRect@8 DirtyRect@12
            Assert.Equal(0, Marshal.OffsetOf<S.MILCMD_BITMAP_INVALIDATE>("Type").ToInt32());
            Assert.Equal(4, Marshal.OffsetOf<S.MILCMD_BITMAP_INVALIDATE>("Handle").ToInt32());
            Assert.Equal(8, Marshal.OffsetOf<S.MILCMD_BITMAP_INVALIDATE>("UseDirtyRect").ToInt32());
            Assert.Equal(12, Marshal.OffsetOf<S.MILCMD_BITMAP_INVALIDATE>("DirtyRect").ToInt32());
            Assert.Equal(28, Marshal.SizeOf<S.MILCMD_BITMAP_INVALIDATE>());
            Assert.Equal(28, MilCommandLayout.FixedSize(MilCmd.MilCmdBitmapInvalidate));
        }

        /// <summary>
        /// DirtyRect 的字段顺序必须等于 Windows RECT（left/top/right/bottom）。
        /// 不走反射查字段名（GetFields 的顺序没有规范保证），直接用字节流验：
        /// 把 1/2/3/4 写进偏移 12..27，读出来必须还是 1/2/3/4。
        /// </summary>
        [Fact]
        public void 脏矩形字节序与WindowsRECT一致()
        {
            byte[] cmd = InvalidateCommand(
                new DUCE.ResourceHandle(0x1234), useDirtyRect: true,
                new MilRectI(left: 1, top: 2, right: 3, bottom: 4));

            S.MILCMD_BITMAP_INVALIDATE s = MemoryMarshal.Read<S.MILCMD_BITMAP_INVALIDATE>(cmd);
            Assert.Equal(1, s.DirtyRect.Left);
            Assert.Equal(2, s.DirtyRect.Top);
            Assert.Equal(3, s.DirtyRect.Right);
            Assert.Equal(4, s.DirtyRect.Bottom);
        }

        // ==============================================================
        //  §B 令牌传递语义
        // ==============================================================

        [Fact]
        public void 位图源命令往返后位图挂在资源上()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);

            SKBitmap bmp = Solid(8, 8, SKColors.Red);

            // 令牌登记表是**进程内全局**的，别的用例可能留下尚未取走的条目
            // （比如"句柄非法"那几条，Require3D 先失败、令牌就没人取），
            // 所以这里只能断言增量，不能断言绝对值。
            int before = MilBitmapSourceTable.PendingCount;
            ulong token = MilBitmapSourceTable.Register(bmp);

            Assert.True(token > 0, "合法位图必须领到非 0 令牌（0 恒为非法值）");
            Assert.Equal(before + 1, MilBitmapSourceTable.PendingCount);

            Assert.Equal(HResult.S_OK, ch.Dispatch(SourceCommand(h, token)));

            // 取出即注销：登记表不残留，对应上游"引用交给从端后不再由传输层持有"
            Assert.Equal(before, MilBitmapSourceTable.PendingCount);
            Assert.Same(bmp, MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(h)));

            MilBitmapSourceState state = MilBitmapSourceTable.LookupState(ch.Resources.Lookup(h));
            Assert.Equal(1, state.Version);

            bmp.Dispose();
        }

        /// <summary>
        /// 上游的引用协议：AddRef → 传输 → 从端接手 → **替换时释放旧的**。
        /// 本实现：Register → Take → 替换时 Dispose 旧的。两边一一对应。
        /// </summary>
        [Fact]
        public void 再次下发位图会释放上一张()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);

            SKBitmap first = Solid(8, 8, SKColors.Red);
            SKBitmap second = Solid(8, 8, SKColors.Blue);

            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(first))));
            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(second))));

            Assert.Same(second, MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(h)));
            Assert.Equal(IntPtr.Zero, first.Handle);   // 旧的那张已被 Dispose

            Assert.Equal(2, MilBitmapSourceTable.LookupState(ch.Resources.Lookup(h)).Version);
            second.Dispose();
        }

        /// <summary>
        /// 令牌非法时返回 **E_HANDLE**，不是 E_INVALIDARG。
        /// 我们是接收侧（CMilSlaveBitmap::ProcessSource），上游的空对象校验是
        /// IFCNULL(...) → E_HANDLE（instrumentationapi.h:915）；
        /// E_INVALIDARG 属于发送侧 apifunc.cpp:728 的 CHECKPTRARG。
        /// </summary>
        [Theory]
        [InlineData(0UL)]            // 令牌 0 == 上游空指针
        [InlineData(0xDEADBEEFUL)]   // 从未登记过 == 上游拿到野指针
        public void 非法令牌返回E_HANDLE(ulong token)
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);

            Assert.Equal(HResult.E_HANDLE, ch.Dispatch(SourceCommand(h, token)));
            Assert.Null(MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(h)));
        }

        [Fact]
        public void 空句柄返回错误而不是崩()
        {
            var ch = new TestChannel();
            SKBitmap bmp = Solid(4, 4, SKColors.Red);

            Assert.Equal(HResult.E_INVALIDARG,
                ch.Dispatch(SourceCommand(DUCE.ResourceHandle.Null, MilBitmapSourceTable.Register(bmp))));
            bmp.Dispose();
        }

        /// <summary>资源类型不匹配时拒绝：位图状态不许挂到别的类型上。</summary>
        [Fact]
        public void 句柄指向别的资源类型时拒绝()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_VISUAL);
            SKBitmap bmp = Solid(4, 4, SKColors.Red);

            Assert.Equal(HResult.E_INVALIDARG,
                ch.Dispatch(SourceCommand(h, MilBitmapSourceTable.Register(bmp))));
            bmp.Dispose();
        }

        // ==============================================================
        //  §C 格式覆盖
        // ==============================================================

        // WPF 的像素格式 → Skia 颜色类型：
        //   Bgra32/Pbgra32 → Bgra8888（WPF 内部主用）
        //   Rgba32/Prgba32 → Rgba8888
        //   Rgb24/Bgr24    → Rgb888x（3 字节打包进 4 字节，末字节未用）
        //   Gray8          → Gray8
        //
        // 只验**原样往返**（格式在传递过程中不被转换/丢失）。
        // 不在这里验绘制 —— 这些格式能否直接上 SKCanvas 是 Skia 的能力问题，
        // 与本命令的传递语义无关；§E 的像素断言用 Bgra8888 单独验。
        public static IEnumerable<object[]> PixelFormats => new List<object[]>
        {
            new object[] { SKColorType.Bgra8888, SKAlphaType.Premul,  "Bgra32" },
            new object[] { SKColorType.Rgba8888, SKAlphaType.Premul,  "Rgba32" },
            new object[] { SKColorType.Rgb888x,  SKAlphaType.Opaque,  "Rgb24"  },
            new object[] { SKColorType.Gray8,    SKAlphaType.Opaque,  "Gray8"  },
        };

        [Theory]
        [MemberData(nameof(PixelFormats))]
        public void 各像素格式都能原样往返(SKColorType colorType, SKAlphaType alphaType, string wpfName)
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);

            var bmp = new SKBitmap(new SKImageInfo(4, 4, colorType, alphaType));
            Assert.False(bmp.IsNull, $"{wpfName} 位图创建失败");

            Assert.Equal(HResult.S_OK,
                ch.Dispatch(SourceCommand(h, MilBitmapSourceTable.Register(bmp))));

            SKBitmap bound = MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(h));
            Assert.Same(bmp, bound);
            Assert.Equal(colorType, bound.ColorType);
            Assert.Equal(4, bound.Width);
            Assert.Equal(4, bound.Height);

            bmp.Dispose();
        }

        // ==============================================================
        //  §D 尺寸边界
        // ==============================================================

        [Fact]
        public void 尺寸1x1的位图可以绑定()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            SKBitmap bmp = Solid(1, 1, SKColors.Green);

            ulong token = MilBitmapSourceTable.Register(bmp);
            Assert.True(token > 0);
            Assert.Equal(HResult.S_OK, ch.Dispatch(SourceCommand(h, token)));

            SKBitmap bound = MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(h));
            Assert.Equal(1, bound.Width);
            Assert.Equal(1, bound.Height);
            Assert.Equal(SKColors.Green, bound.GetPixel(0, 0));

            bmp.Dispose();
        }

        /// <summary>
        /// 0 尺寸的位图必须**被拒绝**（Register 返回 0），而不是登记进去后
        /// 在下游某处炸掉。命令侧再补一刀：拿 0 令牌下发必须返错而不是崩。
        /// </summary>
        [Theory]
        [InlineData(0, 4)]
        [InlineData(4, 0)]
        [InlineData(0, 0)]
        public void 零尺寸位图被拒绝登记(int w, int h)
        {
            var bmp = new SKBitmap(new SKImageInfo(w, h, SKColorType.Bgra8888, SKAlphaType.Premul));

            // 0 尺寸在 Skia 侧就会落到 IsNull；不管走哪条路，结论都必须是一样的
            Assert.Equal(0UL, MilBitmapSourceTable.Register(bmp));

            var ch = new TestChannel();
            DUCE.ResourceHandle res = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            Assert.Equal(HResult.E_HANDLE, ch.Dispatch(SourceCommand(res, 0UL)));
            Assert.Null(MilBitmapSourceTable.LookupBitmap(ch.Resources.Lookup(res)));

            bmp.Dispose();
        }

        [Fact]
        public void 空位图被拒绝登记()
        {
            Assert.Equal(0UL, MilBitmapSourceTable.Register(null));
        }

        /// <summary>发送失败时的补做清理：Discard 对应上游失败分支的 ReleaseInterface。</summary>
        [Fact]
        public void 丢弃令牌会释放位图()
        {
            SKBitmap bmp = Solid(4, 4, SKColors.Red);
            int before = MilBitmapSourceTable.PendingCount;
            ulong token = MilBitmapSourceTable.Register(bmp);
            Assert.Equal(before + 1, MilBitmapSourceTable.PendingCount);

            MilBitmapSourceTable.Discard(token);

            Assert.Equal(before, MilBitmapSourceTable.PendingCount);
            Assert.Equal(IntPtr.Zero, bmp.Handle);
        }

        // ==============================================================
        //  §E 0x0d 失效命令
        // ==============================================================

        [Fact]
        public void 已绑定位图时失效命令记录脏矩形()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            SKBitmap bmp = Solid(8, 8, SKColors.Red);
            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(bmp))));

            Assert.Equal(HResult.S_OK, ch.Dispatch(InvalidateCommand(h, true, new MilRectI(0, 0, 4, 4))));
            Assert.Equal(HResult.S_OK, ch.Dispatch(InvalidateCommand(h, true, new MilRectI(4, 4, 8, 8))));

            MilBitmapSourceState state = MilBitmapSourceTable.LookupState(ch.Resources.Lookup(h));
            Assert.Equal(2, state.DirtyRectCount);
            Assert.Equal(new MilRectI(4, 4, 8, 8), state.LastDirtyRect);

            bmp.Dispose();
        }

        /// <summary>
        /// UseDirtyRect == 0 表示"整图失效"：计数照加，但不记录矩形。
        /// 与上游一致 —— 上游只在 pData->UseDirtyRect 为真时才取 pDirtyRect。
        /// </summary>
        [Fact]
        public void 整图失效不记录矩形()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            SKBitmap bmp = Solid(8, 8, SKColors.Red);
            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(bmp))));

            Assert.Equal(HResult.S_OK, ch.Dispatch(InvalidateCommand(h, false, default)));

            MilBitmapSourceState state = MilBitmapSourceTable.LookupState(ch.Resources.Lookup(h));
            Assert.Equal(1, state.DirtyRectCount);
            Assert.Null(state.LastDirtyRect);

            bmp.Dispose();
        }

        /// <summary>
        /// 上游 bitmapres.cpp:88：m_pIBitmap 为空时什么都不做，但仍然返回 S_OK
        /// （Cleanup 里只调 NotifyOnChanged）。本实现保持一致。
        /// </summary>
        [Fact]
        public void 未绑定位图时失效命令静默成功()
        {
            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);

            Assert.Equal(HResult.S_OK, ch.Dispatch(InvalidateCommand(h, true, new MilRectI(0, 0, 2, 2))));

            // 没有位图就没有状态：上游不会凭空造一个
            Assert.Null(MilBitmapSourceTable.LookupState(ch.Resources.Lookup(h)));
        }

        // ==============================================================
        //  §F 离屏渲染：证明位图真的画出来了
        // ==============================================================

        [Fact]
        public void 离屏渲染把位图画进目标矩形()
        {
            const int W = 64, H = 64;
            var rect = new SKRect(16, 16, 48, 48);   // 目标矩形，四周留出背景

            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            SKBitmap src = Solid(8, 8, SKColors.Red);

            // 1) 位图经由**真实的 0x0c 命令字节**绑到资源上（不是直接塞进内部表）
            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(src))));

            // 2) 挂上渲染层的 BitmapResolver 钩子（Rendering/ 一行都不改）
            var provider = new MilChannelResourceProvider(ch.Channel);
            MilBitmapSourceTable.AttachTo(provider);

            // 3) 一条 MilDrawImage 指令
            var data = new MilRenderData();
            data.InstructionList.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawImage,
                Geometry = new MilResourceHandle(h.Value),   // 非 Animate 走 Geometry 字段
                Rect = rect,
            });

            // 4) 离屏渲染（Skia CPU 后端，不需要 X server）
            var backend = new SkiaRenderBackend(provider);
            var info = new SKImageInfo(W, H, SKColorType.Rgba8888, SKAlphaType.Premul,
                                       SKColorSpace.CreateSrgb());
            using SKSurface surface = SKSurface.Create(info);
            Assert.NotNull(surface);

            SKCanvas canvas = surface.Canvas;
            canvas.ResetMatrix();
            backend.RenderVisualTree(new MilVisual { Content = data }, canvas, new RenderContext
            {
                Width = W,
                Height = H,
                Dpi = RenderContext.FixedDpi,
                ClearColor = SKColors.White,
            });
            canvas.Flush();

            using SKImage image = surface.Snapshot();
            using SKBitmap pixels = SKBitmap.FromImage(image);

            // 5) 三条断言缺一不可
            //    a. 目标矩形内 == 位图颜色 → 位图真的画出来了
            Assert.Equal(SKColors.Red, pixels.GetPixel(32, 32));
            Assert.Equal(SKColors.Red, pixels.GetPixel(17, 17));
            Assert.Equal(SKColors.Red, pixels.GetPixel(47, 47));

            //    b. 矩形外 == 背景色 → 画的是那个矩形，不是糊满整张画布
            Assert.Equal(SKColors.White, pixels.GetPixel(4, 4));
            Assert.Equal(SKColors.White, pixels.GetPixel(60, 60));
            Assert.Equal(SKColors.White, pixels.GetPixel(32, 4));

            //    c. 没有指令被静默跳过 —— 否则上面两组可能只是"碰巧背景是白的"
            Assert.Equal(1, backend.Diagnostics.InstructionCount);
            Assert.Empty(backend.Diagnostics.NotDrawn);

            src.Dispose();
        }

        /// <summary>
        /// 反证：没挂 BitmapResolver 时，同一条指令必须被记为"未画出"且画布保持全白。
        /// 有了这条，§F 的红像素才不能是别的东西（比如背景或某个兜底填充）画出来的。
        /// </summary>
        [Fact]
        public void 没挂位图解析器时图像指令被记为未画出()
        {
            const int W = 32, H = 32;

            var ch = new TestChannel();
            DUCE.ResourceHandle h = ch.Create(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            SKBitmap src = Solid(8, 8, SKColors.Red);
            Assert.Equal(HResult.S_OK, ch.Dispatch(
                SourceCommand(h, MilBitmapSourceTable.Register(src))));

            // 故意 **不** 调 AttachTo
            var provider = new MilChannelResourceProvider(ch.Channel);

            var data = new MilRenderData();
            data.InstructionList.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawImage,
                Geometry = new MilResourceHandle(h.Value),
                Rect = new SKRect(0, 0, 32, 32),
            });

            var backend = new SkiaRenderBackend(provider);
            using SKSurface surface = SKSurface.Create(new SKImageInfo(
                W, H, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb()));
            SKCanvas canvas = surface.Canvas;
            backend.RenderVisualTree(new MilVisual { Content = data }, canvas, new RenderContext
            {
                Width = W, Height = H, ClearColor = SKColors.White,
            });
            canvas.Flush();

            using SKImage image = surface.Snapshot();
            using SKBitmap pixels = SKBitmap.FromImage(image);

            Assert.Equal(SKColors.White, pixels.GetPixel(16, 16));
            Assert.Equal(1L, backend.Diagnostics.NotDrawn[MilDrawCommand.MilDrawImage]);

            src.Dispose();
        }

        // ==============================================================
        //  工具
        // ==============================================================

        /// <summary>造一张纯色位图（默认 Bgra8888/Premul，WPF 内部主用格式）。</summary>
        private static SKBitmap Solid(int w, int h, SKColor color,
                                     SKColorType ct = SKColorType.Bgra8888,
                                     SKAlphaType at = SKAlphaType.Premul)
        {
            var bmp = new SKBitmap(new SKImageInfo(w, h, ct, at));
            using (var canvas = new SKCanvas(bmp))
                canvas.Clear(color);
            return bmp;
        }

        /// <summary>0x0c：Type(4) + Handle(4) + BitmapToken(8) = 16。</summary>
        private static byte[] SourceCommand(DUCE.ResourceHandle handle, ulong token)
        {
            byte[] buf = new byte[MilCommandLayout.FixedSize(MilCmd.MilCmdBitmapSource)];
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(0), (int)MilCmd.MilCmdBitmapSource);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(4), handle.Value);
            BinaryPrimitives.WriteUInt64LittleEndian(buf.AsSpan(8), token);
            return buf;
        }

        /// <summary>0x0d：Type(4) + Handle(4) + BOOL(4) + RECT(16) = 28。</summary>
        private static byte[] InvalidateCommand(DUCE.ResourceHandle handle, bool useDirtyRect,
                                                MilRectI dirtyRect)
        {
            byte[] buf = new byte[MilCommandLayout.FixedSize(MilCmd.MilCmdBitmapInvalidate)];
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(0), (int)MilCmd.MilCmdBitmapInvalidate);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(4), handle.Value);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(8), useDirtyRect ? 1u : 0u);
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(12), dirtyRect.Left);
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(16), dirtyRect.Top);
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(20), dirtyRect.Right);
            BinaryPrimitives.WriteInt32LittleEndian(buf.AsSpan(24), dirtyRect.Bottom);
            return buf;
        }
    }
}
