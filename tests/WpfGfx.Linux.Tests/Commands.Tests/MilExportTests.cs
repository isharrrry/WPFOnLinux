// Licensed to the .NET Foundation under one or more agreements.
//
// M7a：94 个新增 MIL 导出的语义测试。
//
// 【测试原则（handoff §6 / 任务书第 3 条）】
//   能验语义的必须验语义，禁止"返回 S_OK 就算过"：
//     · 几何导出   → 数值断言（点数、端点、包围盒、面积、命中与否）
//     · 位图导出   → 查像素
//     · 句柄导出   → 查表断言 + 幂等 + 错误码保真
//     · 纯状态导出 → 句柄闭合、重复调用、错误 HRESULT
//
// 【为什么把进程级状态在每个测试开头清一遍】
//   xunit 默认按测试类并行，而这些导出背后是进程级句柄表（HWND 表、设备对象表、
//   连接表……）。测试类之间互不干扰（别的类不用这些表），但本类内部的顺序不保证，
//   所以用 MilNative.ResetProcessStateForTests() 在每个测试开头建立干净基线。
//   **通道表（MilChannelRegistry）不清**——那是别的测试类在用的共享全局量。

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    public unsafe class MilExportTests : IDisposable
    {
        private readonly List<IntPtr> _channels = new List<IntPtr>();
        private readonly List<IntPtr> _typefaces = new List<IntPtr>();

        public MilExportTests()
        {
            MilNative.ResetProcessStateForTests();
        }

        public void Dispose()
        {
            foreach (IntPtr channel in _channels) MilNative.MilConnection_DestroyChannel(channel);
            _channels.Clear();
            MilNative.ResetProcessStateForTests();
        }

        // ==================================================================
        //  夹具
        // ==================================================================

        private IntPtr NewChannel()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, IntPtr.Zero, out IntPtr channel));
            _channels.Add(channel);
            return channel;
        }

        /// <summary>矩形路径数据（MIL_PATHGEOMETRY 字节块）。</summary>
        private static byte[] PathDataRect(double x, double y, double w, double h)
        {
            using var path = new SKPath();
            path.AddRect(new SKRect((float)x, (float)y, (float)(x + w), (float)(y + h)));
            return MilGeometryEngine.SerializePath(path);
        }

        /// <summary>两个同心矩形的路径数据（用于两种填充规则的面积区分）。</summary>
        private static byte[] PathDataNestedRects(double outer, double innerOffset)
        {
            using var path = new SKPath();
            path.AddRect(new SKRect(0, 0, (float)outer, (float)outer));
            path.AddRect(new SKRect((float)innerOffset, (float)innerOffset,
                                    (float)(outer - innerOffset), (float)(outer - innerOffset)));
            return MilGeometryEngine.SerializePath(path);
        }

        /// <summary>菱形（曲线）：四条 quad 段，用来验证展平确实产生了中间点。</summary>
        private static byte[] PathDataCurvedDiamond(double size)
        {
            using var path = new SKPath();
            float s = (float)size;
            path.MoveTo(s, 0);
            path.QuadTo(0, 0, 0, s);
            path.QuadTo(0, s, s, s);
            path.QuadTo(s, s, s, 0);
            path.Close();
            return MilGeometryEngine.SerializePath(path);
        }

        /// <summary>打包字体的 SKTypeface（与 Rendering.Tests/PackagedFont 同一资产）。</summary>
        private static SKTypeface LoadPackagedTypeface()
        {
            string root = FindRepoRoot();
            string fontPath = Path.Combine(root, "build", "fonts", "NotoSans-Regular.ttf");
            if (!File.Exists(fontPath))
                throw new FileNotFoundException($"打包字体缺失：{fontPath}", fontPath);

            SKTypeface face = SKTypeface.FromFile(fontPath);
            if (face == null) throw new InvalidOperationException($"Skia 无法加载 {fontPath}");
            return face;
        }

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
                dir = dir.Parent;
            }
            throw new InvalidOperationException("找不到仓库根（含 handoff.md）");
        }

        /// <summary>把 MIL 路径数据解析回来（验证导出产出的字节块是**可解析**的）。</summary>
        private static SKPath ParseBack(byte[] data, MilFillRule rule) =>
            PathGeometryParser.Parse(data, rule);

        /// <summary>几何面积（走 MilUtility_GeometryGetArea 的真实现，用于布尔运算结果断言）。</summary>
        private static double AreaOf(byte[] pathData, MilFillRule rule)
        {
            double area = 0.0;
            fixed (byte* p = pathData)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilUtility_GeometryGetArea(rule, p, (uint)pathData.Length, null, 0.1, false, &area));
            }
            return area;
        }

        /// <summary>图形回调的收集器。</summary>
        private sealed class FigureCollector
        {
            public readonly List<(bool Filled, bool Closed, MilPointF[] Points, byte[] Types)> Figures =
                new List<(bool, bool, MilPointF[], byte[])>();

            public unsafe void Callback(
                bool isFilled, bool isClosed, MilPointF* pPoints, uint pointCount, byte* pTypes, uint typeCount)
            {
                var points = new MilPointF[pointCount];
                for (int i = 0; i < pointCount; i++) points[i] = pPoints[i];

                var types = new byte[typeCount];
                for (int i = 0; i < typeCount; i++) types[i] = pTypes[i];

                Figures.Add((isFilled, isClosed, points, types));
            }

            public int TotalSegmentPoints()
            {
                int n = 0;
                foreach ((_, _, _, byte[] types) in Figures)
                {
                    foreach (byte t in types)
                    {
                        n += (t & (byte)MilCoreSegFlags.SegTypeMask) == (byte)MilCoreSegFlags.SegTypeBezier ? 3 : 1;
                    }
                }
                return n;
            }
        }

        // ==================================================================
        //  0. 导出清单 / 覆盖度
        // ==================================================================

        [Fact]
        public void 导出清单包含全部108个MilCore导出名()
        {
            // 上游 [DllImport(DllImport.MilCore)] 实测是 108 个导出名（M7a 固化）。
            // T1/M7c2 在本工程清单里额外加了 1 个**自有**导出
            // （MilFontFace_RegisterFromFile，跨运行时字体面登记），故总数是 109。
            Assert.Equal(109, MilNative.ExportManifest.Count);

            int upstream = 0;
            foreach (string name in MilNative.ExportManifest.Keys)
                if (name != "MilFontFace_RegisterFromFile") upstream++;
            Assert.Equal(108, upstream);
        }

        [Fact]
        public void 清单里每个导出名都有同名public静态方法()
        {
            IReadOnlyCollection<string> missing = MilNative.MissingExports();
            Assert.Empty(missing);
        }

        [Fact]
        public void 既定实现的导出数量与分组一致()
        {
            int real = 0, identity = 0, state = 0, notImpl = 0;
            foreach (ExportDepth depth in MilNative.ExportManifest.Values)
            {
                switch (depth)
                {
                    case ExportDepth.Real: real++; break;
                    case ExportDepth.Identity: identity++; break;
                    case ExportDepth.State: state++; break;
                    case ExportDepth.NotImpl: notImpl++; break;
                }
            }

            // T1/M7c2：清单从"上游 108"变成"上游 108 + 本工程自有 1（跨运行时字体面登记）"
            Assert.Equal(109, real + identity + state + notImpl);
            // ⚠️ 下面四个数是**硬编码总数**（real/identity/state/notImpl），它们**必须一起移动**：
            //    任何人改 `MilNative.Exports.cs` 里某个导出的 ExportDepth（例如 NotImpl→Real），
            //    这四个数就会同时变 —— 那不是"测试坏了"，而是**这个文件在提醒你同步**。
            //    改的时候请顺手在下面这行注释里写清"哪一项、为什么"，别只改数字。
            // 108→109：+MilFontFace_RegisterFromFile（Real）
            // M7c/#24：MilResource_SendCommandBitmapSource 由 NotImpl 升为 Real ⇒ 60→61、28→27
            Assert.Equal(61, real);
            Assert.Equal(9, identity);
            // T1/M7c：MilChannel_SetNotificationWindow 由 NotImpl 升为 State ⇒ 11→12
            Assert.Equal(12, state);
            // 同上：E_NOTIMPL 台账 29→28；M7c/#24 再 −1（SendCommandBitmapSource 已接线）⇒ 27
            // （与上面的 real 是一对：NotImpl→Real 必然让 real+1、notImpl−1，**必须一起改**）
            Assert.Equal(27, notImpl);
        }

        [Fact]
        public void 未实现清单包含21个媒体导出与4个D3D互操作导出()
        {
            IReadOnlyCollection<string> notImpl = MilNative.NotImplExportNames;

            int media = 0;
            foreach (string name in notImpl)
                if (name.StartsWith("MILMedia", StringComparison.Ordinal)) media++;

            Assert.Equal(21, media);
            Assert.Contains("InteropDeviceBitmap_Create", notImpl);
            Assert.Contains("InteropDeviceBitmap_GetAsSoftwareBitmap", notImpl);
            Assert.Contains("MILFactoryCreateMediaPlayer", notImpl);

            // M1 存量的 E_NOTIMPL 只剩**一个**：
            //   T1/M7c 落掉了 SetNotificationWindow（升 State）；
            //   M7c/#24 落掉了 SendCommandBitmapSource（升 Real —— 位图源命令已接线到 0x0c）。
            Assert.Contains("MilResource_SendCommandMedia", notImpl);
            Assert.DoesNotContain("MilResource_SendCommandBitmapSource", notImpl);
        }

        [Fact]
        public void 通道通知窗口已从ENOTIMPL台账移出并归入State档()
        {
            // T1/M7c：这条是 WPF 启动路径（MediaContext.CreateChannels）的必经点，
            // 返回 E_NOTIMPL 会让 Application 起不来，故落地为真实现（登记通知窗口）。
            Assert.DoesNotContain("MilChannel_SetNotificationWindow", MilNative.NotImplExportNames);
            Assert.Equal(ExportDepth.State,
                MilNative.ExportManifest["MilChannel_SetNotificationWindow"]);
        }

        [Theory]
        [InlineData(nameof(MilNative.MilUtility_ArcToBezier))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryBounds))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryCombine))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryFlatten))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryWiden))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryOutline))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryHitTest))]
        [InlineData(nameof(MilNative.MilUtility_PolygonHitTest))]
        [InlineData(nameof(MilNative.MilUtility_PathGeometryHitTestPathGeometry))]
        [InlineData(nameof(MilNative.MilUtility_GeometryGetArea))]
        [InlineData(nameof(MilNative.MilUtility_GetPointAtLengthFraction))]
        [InlineData(nameof(MilNative.MilUtility_GetTileBrushMapping))]
        [InlineData(nameof(MilNative.MilUtility_CopyPixelBuffer))]
        [InlineData(nameof(MilNative.MIL3DCalcProjected2DBounds))]
        [InlineData(nameof(MilNative.MilUtility_PolygonBounds))]
        [InlineData(nameof(MilNative.MilGlyphRun_GetGlyphOutline))]
        [InlineData(nameof(MilNative.MilGlyphRun_ReleasePathGeometryData))]
        [InlineData(nameof(MilNative.MilGlyphRun_SetGeometryAtRenderTime))]
        [InlineData(nameof(MilNative.MilGlyphCache_BeginCommandAtRenderTime))]
        [InlineData(nameof(MilNative.MilGlyphCache_AppendCommandDataAtRenderTime))]
        [InlineData(nameof(MilNative.MilGlyphCache_EndCommandAtRenderTime))]
        [InlineData(nameof(MilNative.MilVisualTarget_AttachToHwnd))]
        [InlineData(nameof(MilNative.MilVisualTarget_DetachFromHwnd))]
        [InlineData(nameof(MilNative.MilContent_AttachToHwnd))]
        [InlineData(nameof(MilNative.MilContent_DetachFromHwnd))]
        [InlineData(nameof(MilNative.WgxConnection_Create))]
        [InlineData(nameof(MilNative.WgxConnection_Disconnect))]
        [InlineData(nameof(MilNative.WgxConnection_ShouldForceSoftwareForGraphicsStreamClient))]
        [InlineData(nameof(MilNative.MilComposition_PeekNextMessage))]
        [InlineData(nameof(MilNative.MilComposition_SyncFlush))]
        [InlineData(nameof(MilNative.MilComposition_WaitForNextMessage))]
        [InlineData(nameof(MilNative.MilCompositionEngine_EnterCompositionEngineLock))]
        [InlineData(nameof(MilNative.MilCompositionEngine_ExitCompositionEngineLock))]
        [InlineData(nameof(MilNative.MilCompositionEngine_EnterMediaSystemLock))]
        [InlineData(nameof(MilNative.MilCompositionEngine_ExitMediaSystemLock))]
        [InlineData(nameof(MilNative.MilCompositionEngine_InitializePartitionManager))]
        [InlineData(nameof(MilNative.MilCompositionEngine_DeinitializePartitionManager))]
        [InlineData(nameof(MilNative.MILSwDoubleBufferedBitmapCreate))]
        [InlineData(nameof(MilNative.MILSwDoubleBufferedBitmapGetBackBuffer))]
        [InlineData(nameof(MilNative.MILSwDoubleBufferedBitmapAddDirtyRect))]
        [InlineData(nameof(MilNative.MILSwDoubleBufferedBitmapProtectBackBuffer))]
        [InlineData(nameof(MilNative.MILRenderTargetBitmapGetBitmap))]
        [InlineData(nameof(MilNative.MILRenderTargetBitmapClear))]
        [InlineData(nameof(MilNative.MILCreateFactory))]
        [InlineData(nameof(MilNative.MILFactoryCreateBitmapRenderTarget))]
        [InlineData(nameof(MilNative.MILFactoryCreateSWRenderTargetForBitmap))]
        [InlineData(nameof(MilNative.MILFactoryCreateMediaPlayer))]
        [InlineData(nameof(MilNative.InteropDeviceBitmap_Create))]
        [InlineData(nameof(MilNative.InteropDeviceBitmap_Detach))]
        [InlineData(nameof(MilNative.InteropDeviceBitmap_AddDirtyRect))]
        [InlineData(nameof(MilNative.InteropDeviceBitmap_GetAsSoftwareBitmap))]
        [InlineData(nameof(MilNative.MilResource_CreateCWICWrapperBitmap))]
        [InlineData(nameof(MilNative.IWICColorContext_GetProfileBytes_Proxy))]
        [InlineData(nameof(MilNative.IWICColorContext_GetType_Proxy))]
        [InlineData(nameof(MilNative.IWICColorContext_GetExifColorSpace_Proxy))]
        [InlineData(nameof(MilNative.MILAddRef))]
        [InlineData(nameof(MilNative.MILRelease))]
        [InlineData(nameof(MilNative.MILQueryInterface))]
        [InlineData(nameof(MilNative.MilVersionCheck))]
        [InlineData(nameof(MilNative.MILCreateEventProxy))]
        [InlineData(nameof(MilNative.MILCreateStreamFromStreamDescriptor))]
        [InlineData(nameof(MilNative.MILIStreamWrite))]
        [InlineData(nameof(MilNative.MilCreateReversePInvokeWrapper))]
        [InlineData(nameof(MilNative.MilReleasePInvokePtrBlocking))]
        [InlineData(nameof(MilNative.GetNextPerfElementId))]
        [InlineData(nameof(MilNative.WpfGfx_SetDisableBoundsCheckProtection))]
        [InlineData(nameof(MilNative.MILUpdateSystemParametersInfo))]
        [InlineData(nameof(MilNative.RenderOptions_ForceSoftwareRenderingModeForProcess))]
        [InlineData(nameof(MilNative.RenderOptions_IsSoftwareRenderingForcedForProcess))]
        [InlineData(nameof(MilNative.RenderOptions_EnableHardwareAccelerationInRdp))]
        [InlineData(nameof(MilNative.MilChannel_CloseBatch))]
        [InlineData(nameof(MilNative.MilChannel_CommitChannel))]
        [InlineData(nameof(MilNative.MilResource_GetRefCountOnChannel))]
        public void 新增导出在MilNative上有public静态方法(string methodName)
        {
            MethodInfo method = typeof(MilNative).GetMethod(
                methodName, BindingFlags.Public | BindingFlags.Static);

            Assert.NotNull(method);
        }

        // ==================================================================
        //  A. 几何
        // ==================================================================

        [Fact]
        public void ArcToBezier四分之一圆产生一段且端点与切线正确()
        {
            var points = new MilPointD[12];
            fixed (MilPointD* p = points)
            {
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(0, 0), new MilSizeD(10, 10), 0.0,
                    fLargeArc: false, MilSweepDirection.Clockwise, new MilPointD(10, 10),
                    null, p, out int pieces);

                Assert.Equal(1, pieces);
                // 圆心 (0,10) 半径 10 的四分之一圆：起点切线沿 +X，
                // 控制点 1 应该在 (10·0.5523, 0) 附近（标准圆弧逼近常数）。
                Assert.InRange(points[0].X, 5.50, 5.55);
                Assert.InRange(points[0].Y, -1e-3, 1e-3);
                // 最后一个是精确终点
                Assert.Equal(10.0, points[2].X, 6);
                Assert.Equal(10.0, points[2].Y, 6);
            }
        }

        [Fact]
        public void ArcToBezier接近整圆的大弧产生四段()
        {
            var points = new MilPointD[12];
            fixed (MilPointD* p = points)
            {
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(0, 0), new MilSizeD(10, 10), 0.0,
                    fLargeArc: true, MilSweepDirection.Clockwise, new MilPointD(0.1, 0),
                    null, p, out int pieces);

                Assert.Equal(4, pieces);

                // 最后一段的终点必须是精确终点
                Assert.Equal(0.1, points[11].X, 6);
                Assert.Equal(0.0, points[11].Y, 6);
            }
        }

        [Fact]
        public void ArcToBezier退化点返回负一()
        {
            var points = new MilPointD[12];
            fixed (MilPointD* p = points)
            {
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(5, 5), new MilSizeD(10, 10), 0.0,
                    fLargeArc: false, MilSweepDirection.Clockwise, new MilPointD(5, 5),
                    null, p, out int pieces);

                Assert.Equal(-1, pieces);
            }
        }

        [Fact]
        public void ArcToBezier零半径退化成直线()
        {
            var points = new MilPointD[12];
            fixed (MilPointD* p = points)
            {
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(0, 0), new MilSizeD(0, 5), 0.0,
                    fLargeArc: false, MilSweepDirection.Counterclockwise, new MilPointD(10, 0),
                    null, p, out int pieces);

                Assert.Equal(0, pieces);
                Assert.Equal(10.0, points[0].X, 6);
                Assert.Equal(0.0, points[0].Y, 6);
            }
        }

        [Fact]
        public void ArcToBezier应用矩阵()
        {
            // 平移 (100, 200)
            double* matrix = stackalloc double[6];
            matrix[0] = 1; matrix[1] = 0; matrix[2] = 0; matrix[3] = 1;
            matrix[4] = 100; matrix[5] = 200;

            var points = new MilPointD[12];
            fixed (MilPointD* p = points)
            {
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(0, 0), new MilSizeD(10, 10), 0.0,
                    fLargeArc: false, MilSweepDirection.Clockwise, new MilPointD(10, 10),
                    matrix, p, out int pieces);

                Assert.Equal(1, pieces);
                Assert.Equal(110.0, points[2].X, 5);
                Assert.Equal(210.0, points[2].Y, 5);
                Assert.InRange(points[0].X, 105.50, 105.55);
            }
        }

        [Fact]
        public void PathGeometryBounds返回矩形紧包围盒()
        {
            byte[] data = PathDataRect(10, 20, 30, 40);
            var bounds = default(MilRectD);

            MilRectD* b = &bounds;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryBounds(
                    null, null, null, MilFillRule.Nonzero, p, (uint)data.Length, null, 0.1, false, false, b));
            }

            Assert.Equal(10.0, bounds.Left, 4);
            Assert.Equal(20.0, bounds.Top, 4);
            Assert.Equal(40.0, bounds.Right, 4);
            Assert.Equal(60.0, bounds.Bottom, 4);
        }

        [Fact]
        public void PathGeometryBounds带笔时向外扩张半个笔宽()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);
            var pen = new MIL_PEN_DATA
            {
                Thickness = 4,
                MiterLimit = 10,
                LineJoin = MilPenLineJoin.Miter,
                StartLineCap = MilPenLineCap.Flat,
                EndLineCap = MilPenLineCap.Flat,
                DashCap = MilPenLineCap.Flat,
            };
            var bounds = default(MilRectD);

            MIL_PEN_DATA* penPtr = &pen;
            MilRectD* b = &bounds;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryBounds(
                    penPtr, null, null, MilFillRule.Nonzero, p, (uint)data.Length, null, 0.1, false, false, b));
            }

            Assert.Equal(-2.0, bounds.Left, 3);
            Assert.Equal(-2.0, bounds.Top, 3);
            Assert.Equal(12.0, bounds.Right, 3);
            Assert.Equal(12.0, bounds.Bottom, 3);
        }

        [Fact]
        public void PathGeometryBounds叠加世界矩阵()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);
            double* world = stackalloc double[6];
            world[0] = 1; world[1] = 0; world[2] = 0; world[3] = 1;
            world[4] = 5; world[5] = 7;

            var bounds = default(MilRectD);
            MilRectD* b = &bounds;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryBounds(
                    null, null, world, MilFillRule.Nonzero, p, (uint)data.Length, null, 0.1, false, false, b));
            }

            Assert.Equal(5.0, bounds.Left, 4);
            Assert.Equal(7.0, bounds.Top, 4);
            Assert.Equal(15.0, bounds.Right, 4);
            Assert.Equal(17.0, bounds.Bottom, 4);
        }

        [Fact]
        public void PathGeometryBounds空指针返回EINVALIDARG()
        {
            var bounds = default(MilRectD);
            MilRectD* b = &bounds;
            {
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_PathGeometryBounds(
                    null, null, null, MilFillRule.Nonzero, null, 100, null, 0.1, false, false, b));
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_PathGeometryBounds(
                    null, null, null, MilFillRule.Nonzero, (byte*)1, 4, null, 0.1, false, false, b));
            }
        }

        [Fact]
        public void PathGeometryFlatten把曲线段变成直线段()
        {
            byte[] data = PathDataCurvedDiamond(100);
            var collector = new FigureCollector();

            MilFillRule outRule;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryFlatten(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.1, false,
                    collector.Callback, out outRule));
            }

            Assert.Equal(MilFillRule.Nonzero, outRule);
            Assert.Single(collector.Figures);

            (bool filled, bool closed, MilPointF[] points, byte[] types) = collector.Figures[0];
            Assert.Equal((true, true), (filled, closed));
            Assert.InRange(points.Length, 11, 100000);

            foreach (byte t in types)
                Assert.Equal((byte)MilCoreSegFlags.SegTypeLine, (byte)(t & (byte)MilCoreSegFlags.SegTypeMask));

            // 起点与显式 Close 之后的图形：点数 = 段数 + 1
            Assert.Equal(points.Length, types.Length + 1);
        }

        [Fact]
        public void PathGeometryFlatten相对容差影响细分密度()
        {
            byte[] data = PathDataCurvedDiamond(100);
            var coarse = new FigureCollector();
            var fine = new FigureCollector();

            fixed (byte* p = data)
            {
                MilNative.MilUtility_PathGeometryFlatten(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.05, true,
                    coarse.Callback, out _);
                MilNative.MilUtility_PathGeometryFlatten(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.001, true,
                    fine.Callback, out _);
            }

            Assert.True(fine.Figures[0].Points.Length > coarse.Figures[0].Points.Length,
                "更小的相对容差必须产生更密的折线");
        }

        [Fact]
        public void PathGeometryFlatten回调为空返回EINVALIDARG()
        {
            byte[] data = PathDataRect(0, 0, 1, 1);
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_PathGeometryFlatten(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.1, false, null, out _));
            }
        }

        [Fact]
        public void PathGeometryOutline保持区域面积()
        {
            byte[] data = PathDataNestedRects(10, 2);   // 外 100，内 6×6=36
            var collector = new FigureCollector();
            MilFillRule outRule;

            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryOutline(
                    null, MilFillRule.EvenOdd, p, (uint)data.Length, 0.1, false,
                    collector.Callback, out outRule));
            }

            Assert.NotEmpty(collector.Figures);
            Assert.Equal(MilFillRule.EvenOdd, outRule);

            // 把回传的图形重建为一条路径并量面积：EvenOdd 下应当是 100 − 36 = 64
            byte[] rebuilt = Rebuild(collector, outRule, closedAlready: true);
            Assert.Equal(64.0, AreaOf(rebuilt, outRule), 1);
        }

        [Fact]
        public void PathGeometryWiden把矩形外扩成描边轮廓()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);
            var pen = new MIL_PEN_DATA
            {
                Thickness = 4,
                MiterLimit = 10,
                LineJoin = MilPenLineJoin.Miter,
            };
            var collector = new FigureCollector();
            MilFillRule outRule;

            MIL_PEN_DATA* penPtr = &pen;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryWiden(
                    penPtr, null, null, MilFillRule.Nonzero, p, (uint)data.Length, 0.1, false,
                    collector.Callback, out outRule));
            }

            Assert.NotEmpty(collector.Figures);

            // 笔宽 4 的描边环：外框 14×14=196，内洞 (10−4)×(10−4)=6×6=36
            // → 面积 196 − 36 = 160（洞比"原矩形"小一圈，因为描边占掉半个笔宽）
            byte[] rebuilt = Rebuild(collector, outRule, closedAlready: true);
            Assert.Equal(160.0, AreaOf(rebuilt, MilFillRule.Nonzero), 1);
        }

        [Fact]
        public void PathGeometryCombine四种模式的面积都正确()
        {
            byte[] a = PathDataRect(0, 0, 10, 10);
            byte[] b = PathDataRect(5, 5, 10, 10);   // 与 a 重叠 5×5=25

            Assert.Equal(175.0, CombineArea(a, b, MilGeometryCombineMode.Union), 1);
            Assert.Equal(25.0, CombineArea(a, b, MilGeometryCombineMode.Intersect), 1);
            Assert.Equal(150.0, CombineArea(a, b, MilGeometryCombineMode.Xor), 1);
            Assert.Equal(75.0, CombineArea(a, b, MilGeometryCombineMode.Exclude), 1);
        }

        private static double CombineArea(byte[] a, byte[] b, MilGeometryCombineMode mode)
        {
            var collector = new FigureCollector();

            fixed (byte* pa = a)
            fixed (byte* pb = b)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryCombine(
                    null, null, MilFillRule.Nonzero, pa, (uint)a.Length,
                    null, MilFillRule.Nonzero, pb, (uint)b.Length,
                    0.1, false, collector.Callback, mode, out MilFillRule outRule));

                byte[] rebuilt = Rebuild(collector, outRule, closedAlready: true);
                return AreaOf(rebuilt, outRule);
            }
        }

        [Fact]
        public void PathGeometryHitTest填充内外与边界()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);

            Assert.Equal(1, HitTest(data, null, 5, 5));
            Assert.Equal(0, HitTest(data, null, 15, 5));
            Assert.Equal(1, HitTest(data, null, 0, 5));       // 边界算命中
            Assert.Equal(0, HitTest(data, null, -0.5, 5));
        }

        [Fact]
        public void PathGeometryHitTest带笔时测描边()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);
            var pen = new MIL_PEN_DATA { Thickness = 4, MiterLimit = 10, LineJoin = MilPenLineJoin.Miter };

            // 中心 (5,5) 在描边环的洞里；边缘 (0,5) 落在 4 宽的描边带上
            MIL_PEN_DATA* penPtr = &pen;
            int centerHit = HitTest(data, penPtr, 5, 5);
            int edgeHit = HitTest(data, penPtr, 0, 5);
            int holeNearBoundary = HitTest(data, penPtr, 3, 5);
            int holeNearBoundaryWithThreshold = HitTest(data, penPtr, 3, 5, threshold: 2.0);

            Assert.Equal((0, 1), (centerHit, edgeHit));
            Assert.Equal((0, 1), (holeNearBoundary, holeNearBoundaryWithThreshold));
        }

        [Fact]
        public void PathGeometryHitTest阈值命中近边界点()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);

            Assert.Equal(0, HitTest(data, null, -0.5, 5));
            Assert.Equal(1, HitTest(data, null, -0.5, 5, threshold: 1.0));
        }

        private static int HitTest(
            byte[] data, MIL_PEN_DATA* pen, double x, double y, double threshold = 0.0)
        {
            var hit = new MilPointD(x, y);
            MilPointD* hp = &hit;
            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryHitTest(
                    null, pen, null, MilFillRule.Nonzero, p, (uint)data.Length,
                    threshold, false, hp, out int contains));
                return contains;
            }
        }

        [Fact]
        public void HitTestPathGeometry四种交集细节()
        {
            byte[] outer = PathDataRect(0, 0, 10, 10);
            byte[] inner = PathDataRect(2, 2, 4, 4);
            byte[] overlapping = PathDataRect(5, 5, 10, 10);
            byte[] disjoint = PathDataRect(50, 50, 5, 5);

            // 【U1c 真机对拍纠正】极性以**第一个参数**为视角，原生写出的就是
            // MilPathsRelation 的值（Disjoint=1/IsContained=2/Contains=3/Overlap=4，
            // wgx_render_types_generated.h:75，与 IntersectionDetail 数值一一对应）。
            // 真机证据（windows-results.json）：
            //   参数1=大矩形, 参数2=内含小矩形 → 3 (FullyContains)
            //   参数1=小矩形, 参数2=外包大矩形 → 2 (FullyInside)
            //   两个形状完全相同           → 4 (Intersects，原生没有"相等"关系)
            Assert.Equal(MilIntersectionDetail.FullyContains, Detail(outer, inner));
            Assert.Equal(MilIntersectionDetail.FullyInside, Detail(inner, outer));
            Assert.Equal(MilIntersectionDetail.Intersects, Detail(outer, overlapping));
            Assert.Equal(MilIntersectionDetail.Empty, Detail(outer, disjoint));
            // 完全相同 → Intersects（初版判成 FullyInside）
            Assert.Equal(MilIntersectionDetail.Intersects, Detail(outer, PathDataRect(0, 0, 10, 10)));
        }

        private static MilIntersectionDetail Detail(byte[] a, byte[] b)
        {
            var detail = MilIntersectionDetail.NotCalculated;
            MilIntersectionDetail* pd = &detail;
            fixed (byte* pa = a)
            fixed (byte* pb = b)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryHitTestPathGeometry(
                    null, MilFillRule.Nonzero, pa, (uint)a.Length,
                    null, MilFillRule.Nonzero, pb, (uint)b.Length,
                    0.1, false, pd));
            }
            return detail;
        }

        [Fact]
        public void GeometryGetArea矩形()
        {
            Assert.Equal(1200.0, AreaOf(PathDataRect(10, 20, 30, 40), MilFillRule.Nonzero), 3);
        }

        [Fact]
        public void GeometryGetArea两种填充规则对同心同向矩形给出不同结果()
        {
            // 外 10×10 = 100；内 6×6 = 36（两个矩形同向）
            byte[] nested = PathDataNestedRects(10, 2);

            // EvenOdd：内圈是洞 → 100 − 36 = 64
            Assert.Equal(64.0, AreaOf(nested, MilFillRule.EvenOdd), 1);

            // Nonzero：内圈绕数 2（不为 0）→ 仍是实心 → 100
            Assert.Equal(100.0, AreaOf(nested, MilFillRule.Nonzero), 1);
        }

        [Fact]
        public void GeometryGetArea面积随矩阵缩放()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);
            double* scale = stackalloc double[6];
            scale[0] = 2; scale[1] = 0; scale[2] = 0; scale[3] = 3;
            scale[4] = 0; scale[5] = 0;

            fixed (byte* p = data)
            {
                double area = 0.0;
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_GeometryGetArea(
                    MilFillRule.Nonzero, p, (uint)data.Length, scale, 0.1, false, &area));
                Assert.Equal(600.0, area, 1);   // 20 × 30
            }
        }

        [Fact]
        public void GeometryGetArea空指针返回EINVALIDARG()
        {
            double* area = stackalloc double[1];
            {
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_GeometryGetArea(
                    MilFillRule.Nonzero, null, 100, null, 0.1, false, area));
            }
        }

        [Fact]
        public void GetPointAtLengthFraction取到中点与切线()
        {
            byte[] data = PathDataRect(0, 0, 10, 10);

            fixed (byte* p = data)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_GetPointAtLengthFraction(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.0,
                    out MilPointD start, out MilPointD tangentAtStart));

                // 起点是 (0,0)，切向沿 +X
                Assert.Equal(0.0, start.X, 3);
                Assert.Equal(0.0, start.Y, 3);
                Assert.Equal(1.0, Math.Abs(tangentAtStart.X), 3);

                // 1/8 处（周长 40，走 5）落在上边中点 (5,0)
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_GetPointAtLengthFraction(
                    null, MilFillRule.Nonzero, p, (uint)data.Length, 0.125,
                    out MilPointD quarter, out _));
                Assert.Equal(5.0, quarter.X, 3);
                Assert.Equal(0.0, quarter.Y, 3);
            }
        }

        [Fact]
        public void GetPointAtLengthFraction空路径返回EINVALIDARG()
        {
            var empty = new byte[MilGeometryEngine.PathGeometryHeaderSize];
            // Size=0/FigureCount=0 的头：解析出来是空路径
            fixed (byte* p = empty)
            {
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_GetPointAtLengthFraction(
                    null, MilFillRule.Nonzero, p, (uint)empty.Length, 0.5, out _, out _));
            }
        }

        [Fact]
        public void GetTileBrushMapping绝对单位Fill填满Viewport()
        {
            var viewport = new MilPointAndSizeD(0, 0, 100, 50);
            var viewbox = new MilPointAndSizeD(0, 0, 10, 10);

            MilNative.MilUtility_GetTileBrushMapping(
                null, null, MilStretch.Fill, MilAlignmentX.Left, MilAlignmentY.Top,
                MilBrushMappingMode.Absolute, MilBrushMappingMode.Absolute,
                null, null, ref viewport, ref viewbox,
                out D3DMATRIX contentToShape, out int empty);

            Assert.Equal(0, empty);
            // Fill：Viewbox(10×10) → Viewport(100×50)，缩放 10×5
            Assert.Equal(10f, contentToShape.M11, 3);
            Assert.Equal(5f, contentToShape.M22, 3);
            Assert.Equal(0f, contentToShape.M41, 3);
            Assert.Equal(0f, contentToShape.M42, 3);
        }

        [Fact]
        public void GetTileBrushMapping相对单位按包围盒换算()
        {
            var bounds = new MilPointAndSizeD(100, 200, 40, 20);
            var viewport = new MilPointAndSizeD(0.5, 0.5, 0.5, 0.5);   // 相对 → (120,210,20,10)
            var viewbox = new MilPointAndSizeD(0, 0, 1, 1);

            MilNative.MilUtility_GetTileBrushMapping(
                null, null, MilStretch.None, MilAlignmentX.Left, MilAlignmentY.Top,
                MilBrushMappingMode.RelativeToBoundingBox, MilBrushMappingMode.Absolute,
                &bounds, null, ref viewport, ref viewbox,
                out D3DMATRIX contentToShape, out int empty);

            Assert.Equal(0, empty);
            Assert.Equal(120.0, viewport.X, 4);
            Assert.Equal(210.0, viewport.Y, 4);
            Assert.Equal(20.0, viewport.Width, 4);
            Assert.Equal(10.0, viewport.Height, 4);

            // Stretch=None + Left/Top 对齐：平移量 = Viewport 左上角
            Assert.Equal(1f, contentToShape.M11, 4);
            Assert.Equal(120f, contentToShape.M41, 3);
            Assert.Equal(210f, contentToShape.M42, 3);
        }

        [Fact]
        public void GetTileBrushMapping空Viewbox把画笔标记为空()
        {
            var viewport = new MilPointAndSizeD(0, 0, 100, 100);
            var viewbox = new MilPointAndSizeD(0, 0, 0, 0);

            MilNative.MilUtility_GetTileBrushMapping(
                null, null, MilStretch.Fill, MilAlignmentX.Left, MilAlignmentY.Top,
                MilBrushMappingMode.Absolute, MilBrushMappingMode.Absolute,
                null, null, ref viewport, ref viewbox, out _, out int empty);

            Assert.Equal(1, empty);
        }

        [Fact]
        public void GetTileBrushMapping相对变换按包围盒绝对化()
        {
            var bounds = new MilPointAndSizeD(0, 0, 100, 100);
            var viewport = new MilPointAndSizeD(0, 0, 100, 100);
            var viewbox = new MilPointAndSizeD(0, 0, 100, 100);

            // RelativeTransform = 平移 (0.1, 0.2) 相对单位 → 绝对 (10, 20)
            D3DMATRIX relative = D3DMATRIX.FromAffine(1, 0, 0, 1, 0.1f, 0.2f);

            MilNative.MilUtility_GetTileBrushMapping(
                null, &relative, MilStretch.None, MilAlignmentX.Left, MilAlignmentY.Top,
                MilBrushMappingMode.Absolute, MilBrushMappingMode.Absolute,
                &bounds, null, ref viewport, ref viewbox,
                out D3DMATRIX contentToShape, out int empty);

            Assert.Equal(0, empty);
            Assert.Equal(10f, contentToShape.M41, 2);
            Assert.Equal(20f, contentToShape.M42, 2);
        }

        [Fact]
        public void CopyPixelBuffer字节对齐按行拷贝()
        {
            byte[] input = new byte[2 * 8];
            for (int i = 0; i < input.Length; i++) input[i] = (byte)(i + 1);
            byte[] output = new byte[2 * 8];

            fixed (byte* pin = input)
            fixed (byte* pout = output)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_CopyPixelBuffer(
                    pout, (uint)output.Length, 8, 0,
                    pin, (uint)input.Length, 8, 0,
                    height: 2, copyWidthInBits: 64));
            }

            Assert.Equal(input, output);
        }

        [Fact]
        public void CopyPixelBuffer按行stride拷贝子矩形()
        {
            // 输入两行各 8 字节，只拷每行前 3 字节到输出（stride 8）
            byte[] input = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
            byte[] output = new byte[16];

            fixed (byte* pin = input)
            fixed (byte* pout = output)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_CopyPixelBuffer(
                    pout, (uint)output.Length, 8, 0,
                    pin, (uint)input.Length, 8, 0,
                    height: 2, copyWidthInBits: 24));
            }

            Assert.Equal(new byte[] { 1, 2, 3, 0, 0, 0, 0, 0, 9, 10, 11, 0, 0, 0, 0, 0 }, output);
        }

        [Fact]
        public void CopyPixelBuffer位偏移时只改目标位()
        {
            byte[] input = { 0b11111000, 0b00000000 };
            byte[] output = { 0b00000111, 0b00000000 };

            fixed (byte* pin = input)
            fixed (byte* pout = output)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_CopyPixelBuffer(
                    pout, (uint)output.Length, 2, 3,
                    pin, (uint)input.Length, 2, 0,
                    height: 1, copyWidthInBits: 5));
            }

            // 逐步按上游算法算一遍（GetOffsetMask 的偏移是"从低位起算"）：
            //   GetNextByteFromInputBuffer(in="11111000", inOffset=0, bits=5)
            //     → mask = GetOffsetMask(0,5) = 0b11111000 → nextByte = 11111000
            //   写入：mask = GetOffsetMask(3,5) = 0b00011111
            //     dst[0] = (dst[0] & ~mask) | ((nextByte >> 3) & mask)
            //            = (00000111 & 11100000) | (00011111 & 00011111) = 0b00011111
            // 断言的是**上游逐位结果**（实现里是逐行移植，不做"看起来更对"的改写），
            // 所以这里期望 31 而不是"把 5 个 1 写到高 5 位"的 248。
            Assert.Equal(0b00011111, output[0]);
            Assert.Equal(0b00000000, output[1]);
        }

        [Fact]
        public void CopyPixelBuffer非法参数返回EINVALIDARG()
        {
            byte[] buffer = new byte[16];
            fixed (byte* p = buffer)
            {
                // stride 太小
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_CopyPixelBuffer(
                    p, 16, 1, 0, p, 16, 1, 0, 1, 64));

                // 位偏移 > 7
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_CopyPixelBuffer(
                    p, 16, 8, 8, p, 16, 8, 0, 1, 8));

                // buffer 太小
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_CopyPixelBuffer(
                    p, 4, 8, 0, p, 16, 8, 0, 3, 64));

                // height 为 0 → 直接成功
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_CopyPixelBuffer(
                    p, 16, 8, 0, p, 16, 8, 0, 0, 64));
            }
        }

        [Fact]
        public void MIL3DCalcProjected2DBounds恒等变换给出原盒()
        {
            D3DMATRIX identity = D3DMATRIX.Identity;
            var box = new MILRect3D { X = 1, Y = 2, Z = 3, LengthX = 4, LengthY = 5, LengthZ = 6 };

            Assert.Equal(HResult.S_OK, MilNative.MIL3DCalcProjected2DBounds(
                &identity, &box, out MilRectF rect));

            Assert.Equal(1f, rect.Left, 4);
            Assert.Equal(2f, rect.Top, 4);
            Assert.Equal(5f, rect.Right, 4);
            Assert.Equal(7f, rect.Bottom, 4);
        }

        [Fact]
        public void MIL3DCalcProjected2DBounds吃缩放矩阵与透视除法()
        {
            D3DMATRIX matrix = D3DMATRIX.Identity;
            matrix.M11 = 2f;
            matrix.M22 = 3f;

            var box = new MILRect3D { X = 1, Y = 1, Z = 0, LengthX = 1, LengthY = 1, LengthZ = 0 };

            Assert.Equal(HResult.S_OK, MilNative.MIL3DCalcProjected2DBounds(
                &matrix, &box, out MilRectF rect));

            Assert.Equal(2f, rect.Left, 4);
            Assert.Equal(3f, rect.Top, 4);
            Assert.Equal(4f, rect.Right, 4);
            Assert.Equal(6f, rect.Bottom, 4);

            // 空指针
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MIL3DCalcProjected2DBounds(null, &box, out _));
        }

        [Fact]
        public void PolygonBounds与PolygonHitTest走点数组路径()
        {
            // 三角形 (0,0) (10,0) (0,10)
            var points = new[]
            {
                new MilPointD(0, 0), new MilPointD(10, 0), new MilPointD(0, 10),
            };
            byte[] types =
            {
                (byte)MilCoreSegFlags.SegTypeLine,
                (byte)MilCoreSegFlags.SegTypeLine,
            };

            var bounds = default(MilRectD);
            MilRectD* b = &bounds;
            fixed (MilPointD* p = points)
            fixed (byte* t = types)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PolygonBounds(
                    null, null, null, p, t, (uint)points.Length, (uint)types.Length,
                    null, 0.1, false, false, b));
            }

            Assert.Equal(0.0, bounds.Left, 4);
            Assert.Equal(0.0, bounds.Top, 4);
            Assert.Equal(10.0, bounds.Right, 4);
            Assert.Equal(10.0, bounds.Bottom, 4);

            var inside = new MilPointD(1, 1);
            var outside = new MilPointD(8, 8);

            MilPointD* pi = &inside;
            MilPointD* po = &outside;
            fixed (MilPointD* p = points)
            fixed (byte* t = types)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PolygonHitTest(
                    null, null, null, p, t, (uint)points.Length, (uint)types.Length,
                    0.1, false, pi, out int containsInside));
                Assert.Equal(1, containsInside);

                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PolygonHitTest(
                    null, null, null, p, t, (uint)points.Length, (uint)types.Length,
                    0.1, false, po, out int containsOutside));
                Assert.Equal(0, containsOutside);
            }
        }

        [Fact]
        public void PolygonBounds与HitTest对空数组返回EINVALIDARG()
        {
            var bounds = default(MilRectD);
            MilRectD* b = &bounds;
            {
                Assert.Equal(HResult.E_INVALIDARG, MilNative.MilUtility_PolygonBounds(
                    null, null, null, null, null, 0, 0, null, 0.1, false, false, b));
            }
        }

        /// <summary>把回调收集到的图形重建成 MIL 路径数据（验证"回传的图形"是可用的）。</summary>
        private static byte[] Rebuild(FigureCollector collector, MilFillRule rule, bool closedAlready)
        {
            using var path = new SKPath { FillType = MilGeometryEngine.FillTypeOf(rule) };

            foreach ((bool _, bool closed, MilPointF[] points, byte[] types) in collector.Figures)
            {
                if (points.Length == 0) continue;

                path.MoveTo(points[0].X, points[0].Y);

                int index = 1;
                foreach (byte t in types)
                {
                    byte kind = (byte)(t & (byte)MilCoreSegFlags.SegTypeMask);
                    if (kind == (byte)MilCoreSegFlags.SegTypeBezier)
                    {
                        path.CubicTo(
                            new SKPoint(points[index].X, points[index].Y),
                            new SKPoint(points[index + 1].X, points[index + 1].Y),
                            new SKPoint(points[index + 2].X, points[index + 2].Y));
                        index += 3;
                    }
                    else
                    {
                        path.LineTo(points[index].X, points[index].Y);
                        index += 1;
                    }
                }

                if (closed || closedAlready) path.Close();
            }

            return MilGeometryEngine.SerializePath(path);
        }

        // ==================================================================
        //  B. 字形
        // ==================================================================

        private IntPtr RegisterPackagedTypeface()
        {
            SKTypeface face = LoadPackagedTypeface();
            IntPtr handle = MilFontFaceTable.Register(face);
            Assert.NotEqual(IntPtr.Zero, handle);
            _typefaces.Add(handle);
            return handle;
        }

        [Fact]
        public void GlyphOutline产出可被路径解析器读回的轮廓()
        {
            IntPtr fontFace = RegisterPackagedTypeface();

            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                fontFace, (ushort)'A', sideways: false, renderingEmSize: 64.0,
                out byte* pData, out uint size, out MilFillRule fillRule));

            Assert.True(pData != null);
            Assert.True(size > MilGeometryEngine.PathGeometryHeaderSize);
            Assert.Equal(MilFillRule.Nonzero, fillRule);

            // 关键断言：导出的字节块必须能被**上游格式的解析器**读回
            var data = new byte[size];
            System.Runtime.InteropServices.Marshal.Copy((IntPtr)pData, data, 0, (int)size);

            using SKPath parsed = ParseBack(data, fillRule);
            Assert.NotNull(parsed);
            Assert.False(parsed.IsEmpty);

            SKRect bounds = parsed.GetTightBounds(out SKRect tight) ? tight : SKRect.Empty;
            // 'A' 在 64px em 下：宽度不超过 em，高度不超过 em
            Assert.InRange(bounds.Width, 1f, 64f);
            Assert.InRange(bounds.Height, 1f, 64f);

            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_ReleasePathGeometryData(pData));
            Assert.Equal(0, MilPathGeometryDataTable.OutstandingCount);
        }

        [Fact]
        public void GlyphOutline竖排旋转90度使包围盒宽高互换()
        {
            IntPtr fontFace = RegisterPackagedTypeface();

            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                fontFace, (ushort)'L', false, 64.0, out byte* pHorizontal, out uint sizeH, out _));
            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                fontFace, (ushort)'L', true, 64.0, out byte* pSideways, out uint sizeS, out _));

            var horizontal = new byte[sizeH];
            System.Runtime.InteropServices.Marshal.Copy((IntPtr)pHorizontal, horizontal, 0, (int)sizeH);
            var sideways = new byte[sizeS];
            System.Runtime.InteropServices.Marshal.Copy((IntPtr)pSideways, sideways, 0, (int)sizeS);

            using SKPath h = ParseBack(horizontal, MilFillRule.Nonzero);
            using SKPath v = ParseBack(sideways, MilFillRule.Nonzero);

            SKRect hb = h.GetTightBounds(out SKRect th) ? th : SKRect.Empty;
            SKRect vb = v.GetTightBounds(out SKRect tv) ? tv : SKRect.Empty;

            Assert.Equal(hb.Width, vb.Height, 1);
            Assert.Equal(hb.Height, vb.Width, 1);

            MilNative.MilGlyphRun_ReleasePathGeometryData(pHorizontal);
            MilNative.MilGlyphRun_ReleasePathGeometryData(pSideways);
        }

        [Fact]
        public void GlyphOutline未登记字体面返回EHANDLE()
        {
            Assert.Equal(HResult.E_HANDLE, MilNative.MilGlyphRun_GetGlyphOutline(
                new IntPtr(0x7777), 65, false, 12.0, out byte* p, out _, out _));
            Assert.True(p == null);
        }

        [Fact]
        public void GlyphOutline非法字号返回EINVALIDARG()
        {
            IntPtr fontFace = RegisterPackagedTypeface();
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilGlyphRun_GetGlyphOutline(
                fontFace, 65, false, 0.0, out _, out _, out _));
        }

        [Fact]
        public void ReleasePathGeometryData对无效指针返回EINVALIDARG()
        {
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilGlyphRun_ReleasePathGeometryData(null));

            IntPtr fontFace = RegisterPackagedTypeface();
            MilNative.MilGlyphRun_GetGlyphOutline(fontFace, 65, false, 32.0, out byte* p, out _, out _);

            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_ReleasePathGeometryData(p));
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilGlyphRun_ReleasePathGeometryData(p));
        }

        // ==================== 跨运行时字体面登记（T1/M7c2）====================

        /// <summary>
        /// 本组测的是**本进程**里的解码与建表逻辑（跨运行时那一跳由
        /// build/MilBridge/tests/ClosedLoop 的 F 组经真 P/Invoke 验证，见 T1 报告 §F）。
        /// </summary>
        [Fact]
        public void 字体面从文件登记的令牌可解析出轮廓()
        {
            string fontPath = Path.Combine(FindRepoRoot(), "build", "fonts", "NotoSans-Regular.ttf");
            byte[] utf8 = System.Text.Encoding.UTF8.GetBytes(fontPath);

            IntPtr token;
            fixed (byte* p = utf8)
            {
                token = MilNative.MilFontFace_RegisterFromFile(p, 0, 0);
            }

            Assert.NotEqual(IntPtr.Zero, token);
            // 令牌确实落在本进程的字体面表里，且能被 GetGlyphOutline 解析
            Assert.True(MilFontFaceTable.TryResolve(token, out SKTypeface face));
            Assert.NotNull(face);
            Assert.True(MilFontFaceTable.TryGetSimFlags(token, out int flags));
            Assert.Equal(0, flags);

            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                token, 36, false, 32.0, out byte* data, out uint size, out _));
            Assert.True(data != null && size > 0);
            MilNative.MilGlyphRun_ReleasePathGeometryData(data);
        }

        [Fact]
        public void 字体面登记失败路径全部返回零而不抛异常()
        {
            string missing = Path.Combine(FindRepoRoot(), "build", "fonts", "NoSuchFont.ttf");
            byte[] bad = System.Text.Encoding.UTF8.GetBytes(missing);
            byte[] ok = System.Text.Encoding.UTF8.GetBytes(
                Path.Combine(FindRepoRoot(), "build", "fonts", "NotoSans-Regular.ttf"));

            fixed (byte* pBad = bad)
            fixed (byte* pOk = ok)
            {
                Assert.Equal(IntPtr.Zero, MilNative.MilFontFace_RegisterFromFile(pBad, 0, 0));   // 文件不存在
                Assert.Equal(IntPtr.Zero, MilNative.MilFontFace_RegisterFromFile(pOk, -1, 0));   // faceIndex < 0
                Assert.Equal(IntPtr.Zero, MilNative.MilFontFace_RegisterFromFile(pOk, 9999, 0)); // faceIndex 越界
                Assert.Equal(IntPtr.Zero, MilNative.MilFontFace_RegisterFromFile(null, 0, 0));   // null 路径
            }

            // 空串（非 NUL 结尾的 0 长度）→ 0，且不能无限扫描
            fixed (byte* empty = new byte[1] { 0 })
            {
                Assert.Equal(IntPtr.Zero, MilNative.MilFontFace_RegisterFromFile(empty, 0, 0));
            }
        }

        [Fact]
        public void 字体面模拟标志按DWrite口径记录并施加()
        {
            string fontPath = Path.Combine(FindRepoRoot(), "build", "fonts", "NotoSans-Regular.ttf");
            byte[] utf8 = System.Text.Encoding.UTF8.GetBytes(fontPath);

            IntPtr bold, oblique;
            fixed (byte* p = utf8)
            {
                bold = MilNative.MilFontFace_RegisterFromFile(p, 0, 1);      // BOLD
                oblique = MilNative.MilFontFace_RegisterFromFile(p, 0, 2);   // OBLIQUE
            }

            Assert.NotEqual(IntPtr.Zero, bold);
            Assert.NotEqual(IntPtr.Zero, oblique);
            Assert.NotEqual(bold, oblique);

            Assert.True(MilFontFaceTable.TryGetSimFlags(bold, out int bf));
            Assert.True(MilFontFaceTable.TryGetSimFlags(oblique, out int of));
            Assert.Equal(1, bf);
            Assert.Equal(2, of);

            byte[] a, b;
            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                bold, 36, false, 32.0, out byte* pb, out uint sb, out _));
            Assert.True(pb != null);
            a = new Span<byte>(pb, (int)sb).ToArray();
            MilNative.MilGlyphRun_ReleasePathGeometryData(pb);

            // 施加点：Bold 的轮廓必须与**不加模拟**的不同（否则 simFlags 是个空参数）
            IntPtr plain;
            fixed (byte* p = utf8)
            {
                plain = MilNative.MilFontFace_RegisterFromFile(p, 0, 0);
            }
            Assert.NotEqual(IntPtr.Zero, plain);
            Assert.Equal(HResult.S_OK, MilNative.MilGlyphRun_GetGlyphOutline(
                plain, 36, false, 32.0, out byte* pp, out uint sp, out _));
            Assert.True(pp != null);
            b = new Span<byte>(pp, (int)sp).ToArray();
            MilNative.MilGlyphRun_ReleasePathGeometryData(pp);

            Assert.NotEqual(Convert.ToHexString(a), Convert.ToHexString(b));
        }

        [Fact]
        public void GlyphCache渲染时三件套按状态机累积命令()
        {
            MilRenderTimeTarget target = MilRenderTimeTargetTable.Register();
            IntPtr handle = target.Handle;

            byte[] head = { 1, 2, 3, 4 };
            byte[] tail = { 5, 6 };

            // 未 Begin 就 Append → E_UNEXPECTED
            fixed (byte* pt = tail)
            {
                Assert.Equal(HResult.E_UNEXPECTED,
                    MilNative.MilGlyphCache_AppendCommandDataAtRenderTime(handle, pt, (uint)tail.Length));
            }

            fixed (byte* ph = head)
            fixed (byte* pt = tail)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilGlyphCache_BeginCommandAtRenderTime(handle, ph, (uint)head.Length, (uint)tail.Length));

                // 嵌套 Begin → E_UNEXPECTED
                Assert.Equal(HResult.E_UNEXPECTED,
                    MilNative.MilGlyphCache_BeginCommandAtRenderTime(handle, ph, (uint)head.Length, 0));

                // 超出预留 → E_INVALIDARG
                Assert.Equal(HResult.E_INVALIDARG,
                    MilNative.MilGlyphCache_AppendCommandDataAtRenderTime(handle, pt, 3));

                Assert.Equal(HResult.S_OK,
                    MilNative.MilGlyphCache_AppendCommandDataAtRenderTime(handle, pt, (uint)tail.Length));
                Assert.Equal(HResult.S_OK, MilNative.MilGlyphCache_EndCommandAtRenderTime(handle));
            }

            // 未 Begin 就 End → E_UNEXPECTED
            Assert.Equal(HResult.E_UNEXPECTED, MilNative.MilGlyphCache_EndCommandAtRenderTime(handle));

            Assert.Single(target.Commands);
            Assert.Equal(new byte[] { 1, 2, 3, 4, 5, 6 }, target.Commands[0]);

            // 未知目标 → E_HANDLE
            Assert.Equal(HResult.E_HANDLE, MilNative.MilGlyphCache_EndCommandAtRenderTime(new IntPtr(0x4242)));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilGlyphCache_BeginCommandAtRenderTime(
                new IntPtr(0x4242), null, 0, 0));
        }

        [Fact]
        public void GlyphRun_SetGeometryAtRenderTime投递整条命令()
        {
            MilRenderTimeTarget target = MilRenderTimeTargetTable.Register();
            byte[] cmd = { 9, 8, 7 };

            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilGlyphRun_SetGeometryAtRenderTime(target.Handle, p, (uint)cmd.Length));
            }

            Assert.Single(target.Commands);
            Assert.Equal(cmd, target.Commands[0]);

            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.E_INVALIDARG,
                    MilNative.MilGlyphRun_SetGeometryAtRenderTime(target.Handle, p, 0));
                Assert.Equal(HResult.E_HANDLE,
                    MilNative.MilGlyphRun_SetGeometryAtRenderTime(new IntPtr(0x5151), p, 3));
            }
        }

        // ==================================================================
        //  C. 窗口绑定（身份映射语义）
        // ==================================================================

        [Fact]
        public void AttachHwnd登记成功而第二次被拒()
        {
            var hwnd = new IntPtr(0x10001);

            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(hwnd));

            MilHwndBinding binding = MilHwndRegistry.Resolve(hwnd);
            Assert.NotNull(binding);
            Assert.Equal(MilHwndRole.VisualTarget, binding.Role);
            Assert.Equal(hwnd, binding.Hwnd);

            // 上游 vt_api.cpp:24：已占用的窗口返回 E_ACCESSDENIED
            Assert.Equal(MilErrors.E_ACCESSDENIED, MilNative.MilVisualTarget_AttachToHwnd(hwnd));
            Assert.Equal(1, MilHwndRegistry.Count);
        }

        [Fact]
        public void DetachHwnd未登记返回EINVALIDARG()
        {
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilVisualTarget_DetachFromHwnd(new IntPtr(0x20002)));
        }

        [Fact]
        public void AttachDetachAttach往返且句柄序号单调()
        {
            var hwnd = new IntPtr(0x30003);

            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(hwnd));
            long first = MilHwndRegistry.Resolve(hwnd).Sequence;

            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_DetachFromHwnd(hwnd));
            Assert.False(MilHwndRegistry.IsAttached(hwnd));

            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(hwnd));
            long second = MilHwndRegistry.Resolve(hwnd).Sequence;

            Assert.True(second > first, "重新登记必须拿到新的序号（句柄/绑定不复用）");
        }

        [Fact]
        public void AttachHwnd空句柄返回EINVALIDARG()
        {
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilVisualTarget_AttachToHwnd(IntPtr.Zero));
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilVisualTarget_DetachFromHwnd(IntPtr.Zero));
        }

        [Fact]
        public void ContentAttachDetach幂等且恒SOK()
        {
            var hwnd = new IntPtr(0x40004);

            Assert.Equal(HResult.S_OK, MilNative.MilContent_AttachToHwnd(hwnd));
            Assert.Equal(HResult.S_OK, MilNative.MilContent_AttachToHwnd(hwnd));   // 幂等
            Assert.Equal(MilHwndRole.Content, MilHwndRegistry.Resolve(hwnd).Role);

            Assert.Equal(HResult.S_OK, MilNative.MilContent_DetachFromHwnd(hwnd));
            Assert.Equal(HResult.S_OK, MilNative.MilContent_DetachFromHwnd(hwnd)); // 幂等
            Assert.False(MilHwndRegistry.IsAttached(hwnd));
        }

        [Fact]
        public void VisualTarget与Content绑定互不干扰()
        {
            var both = new IntPtr(0x50005);      // 同时挂两种角色
            var onlyContent = new IntPtr(0x50006);

            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(both));
            Assert.Equal(HResult.S_OK, MilNative.MilContent_AttachToHwnd(both));
            Assert.Equal(HResult.S_OK, MilNative.MilContent_AttachToHwnd(onlyContent));

            // 两种角色共用一个 HWND 时，表里保留先登记的呈现目标角色
            Assert.Equal(MilHwndRole.VisualTarget, MilHwndRegistry.Resolve(both).Role);
            Assert.Equal(MilHwndRole.Content, MilHwndRegistry.Resolve(onlyContent).Role);

            // 只有 Content 绑定的窗口不能被当成呈现目标解绑
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilVisualTarget_DetachFromHwnd(onlyContent));

            // Content 的 Detach 不会把呈现目标绑定一起摘掉
            Assert.Equal(HResult.S_OK, MilNative.MilContent_DetachFromHwnd(both));
            Assert.True(MilHwndRegistry.IsAttached(both));
            Assert.Equal(MilHwndRole.VisualTarget, MilHwndRegistry.Resolve(both).Role);
        }

        // ==================================================================
        //  C'. 连接 / 后向消息 / 锁
        // ==================================================================

        [Fact]
        public void WgxConnectionCreate按请求映射封送类型()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.WgxConnection_Create(requestSynchronousTransport: true, out IntPtr sync));
            Assert.Equal(HResult.S_OK,
                MilNative.WgxConnection_Create(requestSynchronousTransport: false, out IntPtr async));

            Assert.NotEqual(IntPtr.Zero, sync);
            Assert.NotEqual(sync, async);

            MilConnectionObject syncConnection = MilConnectionTable.Resolve(sync);
            Assert.NotNull(syncConnection);
            Assert.Equal(ChannelMarshalType.ChannelMarshalTypeSameThread, syncConnection.MarshalType);

            MilConnectionObject asyncConnection = MilConnectionTable.Resolve(async);
            Assert.NotNull(asyncConnection);
            Assert.Equal(ChannelMarshalType.ChannelMarshalTypeCrossThread, asyncConnection.MarshalType);
        }

        [Fact]
        public void WgxConnectionDisconnect注销连接()
        {
            MilNative.WgxConnection_Create(true, out IntPtr connection);

            Assert.Equal(HResult.S_OK, MilNative.WgxConnection_Disconnect(connection));
            Assert.Null(MilConnectionTable.Resolve(connection));

            // 陈旧句柄：再断一次必须报错，不能静默成功（句柄不复用）
            Assert.Equal(HResult.E_HANDLE, MilNative.WgxConnection_Disconnect(connection));
            Assert.Equal(HResult.E_INVALIDARG, MilNative.WgxConnection_Disconnect(IntPtr.Zero));
        }

        [Fact]
        public void ShouldForceSoftware为false()
        {
            Assert.False(MilNative.WgxConnection_ShouldForceSoftwareForGraphicsStreamClient());
        }

        [Fact]
        public void SyncFlush提交批次并投递SyncFlushReply()
        {
            IntPtr channel = NewChannel();
            byte[] cmd = WpfGfx.Linux.Commands.MilCommandEncoder.VisualSetAlpha(
                CreateVisual(channel), 0.25);

            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilResource_SendCommand(p, (uint)cmd.Length, false, channel));
            }

            Assert.Equal(HResult.S_OK, MilNative.MilComposition_SyncFlush(channel));
            Assert.Equal(1, MilChannelBackChannel.PendingCount(channel));

            Assert.Equal(HResult.S_OK,
                MilNative.MilComposition_PeekNextMessage(channel, out MilMessage message,
                    new IntPtr(sizeof(MilMessage)), out int retrieved));

            Assert.Equal(1, retrieved);
            Assert.Equal(MilMessageType.SyncFlushReply, message.Type);

            // 队列已空
            Assert.Equal(0, MilChannelBackChannel.PendingCount(channel));
            Assert.Equal(HResult.S_OK,
                MilNative.MilComposition_PeekNextMessage(channel, out MilMessage empty,
                    new IntPtr(sizeof(MilMessage)), out int retrieved2));
            Assert.Equal(0, retrieved2);
            Assert.Equal(MilMessageType.Invalid, empty.Type);
        }

        private static DUCE.ResourceHandle CreateVisual(IntPtr channel)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_CreateOrAddRefOnChannel(channel, DUCE.ResourceType.TYPE_VISUAL, ref h));
            return h;
        }

        [Fact]
        public void SyncFlush非法通道返回错误码()
        {
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilComposition_SyncFlush(IntPtr.Zero));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilComposition_SyncFlush(new IntPtr(0x6666)));
        }

        [Fact]
        public void PeekNextMessage按cbSize部分拷贝()
        {
            IntPtr channel = NewChannel();
            MilNative.MilComposition_SyncFlush(channel);

            // 只给 4 字节：只应拷到 Type（前 4 字节），其余保持 0
            Assert.Equal(HResult.S_OK,
                MilNative.MilComposition_PeekNextMessage(channel, out MilMessage message,
                    new IntPtr(4), out int retrieved));

            Assert.Equal(1, retrieved);
            Assert.Equal(MilMessageType.SyncFlushReply, message.Type);
            Assert.Equal(0, message.Reserved);

            Assert.Equal(HResult.E_HANDLE, MilNative.MilComposition_PeekNextMessage(
                new IntPtr(0x6667), out _, new IntPtr(24), out _));
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilComposition_PeekNextMessage(
                IntPtr.Zero, out _, new IntPtr(24), out _));
        }

        [Fact]
        public void WaitForNextMessage消息已就绪时立即返回WAITOBJECT0()
        {
            IntPtr channel = NewChannel();
            MilNative.MilComposition_SyncFlush(channel);

            Assert.Equal(HResult.S_OK, MilNative.MilComposition_WaitForNextMessage(
                channel, 0, null, 0, 1000, out int waitReturn));

            Assert.Equal(0, waitReturn);
        }

        [Fact]
        public void WaitForNextMessage无消息时超时返回WAITTIMEOUT()
        {
            IntPtr channel = NewChannel();

            Assert.Equal(HResult.S_OK, MilNative.MilComposition_WaitForNextMessage(
                channel, 0, null, 0, 20, out int waitReturn));

            Assert.Equal(MilNative.WaitTimeoutStatus, waitReturn);
            Assert.Equal(258, waitReturn);
        }

        [Fact]
        public void WaitForNextMessage参数校验()
        {
            IntPtr channel = NewChannel();

            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilComposition_WaitForNextMessage(
                IntPtr.Zero, 0, null, 0, 0, out _));

            // nCount > 0 但 pHandles 为空
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilComposition_WaitForNextMessage(
                channel, 1, null, 0, 0, out _));

            // nCount 超过 MAXIMUM_WAIT_OBJECTS-1
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MilComposition_WaitForNextMessage(
                channel, 64, new IntPtr[64], 0, 0, out _));

            Assert.Equal(HResult.E_HANDLE, MilNative.MilComposition_WaitForNextMessage(
                new IntPtr(0x6668), 0, null, 0, 0, out _));
        }

        [Fact]
        public void 合成引擎锁可重入且深度可见()
        {
            Assert.Equal(0, MilCompositionEngineState.CompositionLockDepth);

            MilNative.MilCompositionEngine_EnterCompositionEngineLock();
            Assert.Equal(1, MilCompositionEngineState.CompositionLockDepth);
            Assert.True(MilCompositionEngineState.IsCompositionLockHeld);

            // Win32 CRITICAL_SECTION 是可重入的：同线程再进一次
            MilNative.MilCompositionEngine_EnterCompositionEngineLock();
            Assert.Equal(2, MilCompositionEngineState.CompositionLockDepth);

            MilNative.MilCompositionEngine_ExitCompositionEngineLock();
            Assert.Equal(1, MilCompositionEngineState.CompositionLockDepth);

            MilNative.MilCompositionEngine_ExitCompositionEngineLock();
            Assert.Equal(0, MilCompositionEngineState.CompositionLockDepth);
            Assert.False(MilCompositionEngineState.IsCompositionLockHeld);
        }

        [Fact]
        public void 媒体系统锁可重入()
        {
            MilNative.MilCompositionEngine_EnterMediaSystemLock();
            MilNative.MilCompositionEngine_EnterMediaSystemLock();
            Assert.Equal(2, MilCompositionEngineState.MediaSystemLockDepth);

            MilNative.MilCompositionEngine_ExitMediaSystemLock();
            MilNative.MilCompositionEngine_ExitMediaSystemLock();
            Assert.Equal(0, MilCompositionEngineState.MediaSystemLockDepth);
        }

        [Fact]
        public void 未持锁就退出会抛异常而不是留下坏状态()
        {
            Assert.Throws<InvalidOperationException>(
                () => MilNative.MilCompositionEngine_ExitCompositionEngineLock());
            Assert.Throws<InvalidOperationException>(
                () => MilNative.MilCompositionEngine_ExitMediaSystemLock());

            Assert.Equal(0, MilCompositionEngineState.CompositionLockDepth);
            Assert.Equal(0, MilCompositionEngineState.MediaSystemLockDepth);
        }

        [Fact]
        public void 分区管理器初始化与释放()
        {
            Assert.False(MilCompositionEngineState.IsPartitionManagerInitialized);

            Assert.Equal(HResult.S_OK, MilNative.MilCompositionEngine_InitializePartitionManager(2));
            Assert.True(MilCompositionEngineState.IsPartitionManagerInitialized);
            Assert.Equal(2, MilCompositionEngineState.PartitionManagerPriority);

            // 重复初始化幂等
            Assert.Equal(HResult.S_OK, MilNative.MilCompositionEngine_InitializePartitionManager(2));
            Assert.Equal(2, MilCompositionEngineState.InitializeCount);

            Assert.Equal(HResult.S_OK, MilNative.MilCompositionEngine_DeinitializePartitionManager());
            Assert.False(MilCompositionEngineState.IsPartitionManagerInitialized);

            // 上游恒返回 S_OK（apifunc.cpp:110），这里保持一致
            Assert.Equal(HResult.S_OK, MilNative.MilCompositionEngine_DeinitializePartitionManager());
            Assert.Equal(2, MilCompositionEngineState.DeinitializeCount);
        }

        // ==================================================================
        //  D. 离屏位图 / 渲染目标 / 工厂
        // ==================================================================

        private static readonly Guid Pbgra32 = MilPixelFormats.Pbgra32;

        [Fact]
        public void SwDoubleBufferedBitmapCreate分配双缓冲并回填像素格式()
        {
            Guid format = Guid.Empty;   // DontCare
            Assert.Equal(HResult.S_OK, MilNative.MILSwDoubleBufferedBitmapCreate(
                4, 3, 96.0, 96.0, ref format, IntPtr.Zero, out IntPtr dbb));

            Assert.NotEqual(IntPtr.Zero, dbb);
            Assert.Equal(Pbgra32, format);

            var state = (MilDoubleBufferedState)MilDeviceObjectTable.Resolve(dbb).Payload;
            Assert.Equal(4, state.Width);
            Assert.Equal(3, state.Height);
            Assert.Equal(4 * 3 * 4, (int)state.BackBufferSize);
            Assert.NotNull(state.Front);
            Assert.NotNull(state.Back);
        }

        [Fact]
        public void SwDoubleBufferedBitmapBackBuffer句柄可写像素()
        {
            Guid format = Guid.Empty;
            MilNative.MILSwDoubleBufferedBitmapCreate(2, 2, 96.0, 96.0, ref format, IntPtr.Zero, out IntPtr dbb);

            MilNative.MILSwDoubleBufferedBitmapGetBackBuffer(dbb, out IntPtr backBuffer, out uint size);

            Assert.True(size > 0);
            SKBitmap bitmap = MilPixelBufferTable.Resolve(backBuffer);
            Assert.NotNull(bitmap);

            // 真的写一个像素进去
            bitmap.SetPixel(1, 1, new SKColor(10, 20, 30, 255));
            Assert.Equal(new SKColor(10, 20, 30, 255), bitmap.GetPixel(1, 1));
        }

        [Fact]
        public void SwDoubleBufferedBitmapAddDirtyRect记录脏矩形()
        {
            Guid format = Guid.Empty;
            MilNative.MILSwDoubleBufferedBitmapCreate(8, 8, 96.0, 96.0, ref format, IntPtr.Zero, out IntPtr dbb);
            var state = (MilDoubleBufferedState)MilDeviceObjectTable.Resolve(dbb).Payload;

            var rect = new MilInt32Rect(1, 2, 3, 4);
            MilNative.MILSwDoubleBufferedBitmapAddDirtyRect(dbb, ref rect);

            Assert.Equal(1, state.DirtyRectCount);
            Assert.Equal(rect, state.LastDirtyRect);

            // 未知句柄：静默返回（上游是 void）
            MilNative.MILSwDoubleBufferedBitmapAddDirtyRect(new IntPtr(0x999), ref rect);
            Assert.Equal(1, state.DirtyRectCount);
        }

        [Fact]
        public void SwDoubleBufferedBitmapProtectBackBuffer阻止交换且幂等()
        {
            Guid format = Guid.Empty;
            MilNative.MILSwDoubleBufferedBitmapCreate(2, 2, 96.0, 96.0, ref format, IntPtr.Zero, out IntPtr dbb);
            var state = (MilDoubleBufferedState)MilDeviceObjectTable.Resolve(dbb).Payload;

            Assert.True(state.Swap());
            Assert.Equal(1, state.SwapCount);

            Assert.Equal(HResult.S_OK, MilNative.MILSwDoubleBufferedBitmapProtectBackBuffer(dbb));
            Assert.Equal(HResult.S_OK, MilNative.MILSwDoubleBufferedBitmapProtectBackBuffer(dbb));
            Assert.Equal(2, state.ProtectCount);
            Assert.True(state.BackBufferProtected);

            Assert.False(state.Swap());
            Assert.Equal(1, state.SwapCount);

            Assert.Equal(HResult.E_HANDLE,
                MilNative.MILSwDoubleBufferedBitmapProtectBackBuffer(new IntPtr(0x998)));
        }

        [Fact]
        public void SwDoubleBufferedBitmap未知像素格式被拒()
        {
            Guid format = Guid.Parse("11111111-2222-3333-4444-555555555555");
            Assert.Equal(MilErrors.WINCODEC_ERR_UNSUPPORTEDPIXELFORMAT,
                MilNative.MILSwDoubleBufferedBitmapCreate(4, 4, 96.0, 96.0, ref format, IntPtr.Zero, out IntPtr dbb));
            Assert.Equal(IntPtr.Zero, dbb);

            Guid zeroSize = Guid.Empty;
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MILSwDoubleBufferedBitmapCreate(0, 4, 96.0, 96.0, ref zeroSize, IntPtr.Zero, out _));
        }

        [Fact]
        public void RenderTargetBitmapGetBitmap返回可读像素的句柄()
        {
            Assert.Equal(HResult.S_OK, MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion));

            Assert.Equal(HResult.S_OK, MilNative.MILFactoryCreateBitmapRenderTarget(
                factory, 3, 2, MilPixelFormatEnum.Pbgra32, 96f, 96f,
                MILRTInitializationFlags.MIL_RT_SOFTWARE_ONLY, out IntPtr rt));

            Assert.Equal(HResult.S_OK, MilNative.MILRenderTargetBitmapGetBitmap(rt, out IntPtr bitmapHandle));
            Assert.NotEqual(IntPtr.Zero, bitmapHandle);

            SKBitmap bitmap = MilPixelBufferTable.Resolve(bitmapHandle);
            Assert.NotNull(bitmap);
            Assert.Equal(3, bitmap.Width);
            Assert.Equal(2, bitmap.Height);

            bitmap.SetPixel(0, 0, new SKColor(1, 2, 3, 255));
            Assert.Equal(new SKColor(1, 2, 3, 255), bitmap.GetPixel(0, 0));

            // 重复取回同一个句柄（上游也是同一对象）
            Assert.Equal(HResult.S_OK, MilNative.MILRenderTargetBitmapGetBitmap(rt, out IntPtr again));
            Assert.Equal(bitmapHandle, again);
        }

        [Fact]
        public void RenderTargetBitmapClear把像素清成透明()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);
            MilNative.MILFactoryCreateBitmapRenderTarget(
                factory, 2, 2, MilPixelFormatEnum.Pbgra32, 96f, 96f,
                MILRTInitializationFlags.MIL_RT_SOFTWARE_ONLY, out IntPtr rt);
            MilNative.MILRenderTargetBitmapGetBitmap(rt, out IntPtr bitmapHandle);

            SKBitmap bitmap = MilPixelBufferTable.Resolve(bitmapHandle);
            bitmap.Erase(SKColors.Red);
            Assert.Equal((byte)255, bitmap.GetPixel(0, 0).Alpha);

            Assert.Equal(HResult.S_OK, MilNative.MILRenderTargetBitmapClear(rt));
            Assert.Equal((byte)0, bitmap.GetPixel(0, 0).Alpha);

            var state = (MilRenderTargetState)MilDeviceObjectTable.Resolve(rt).Payload;
            Assert.Equal(1, state.ClearCount);

            Assert.Equal(HResult.E_HANDLE, MilNative.MILRenderTargetBitmapClear(new IntPtr(0x997)));
            Assert.Equal(HResult.E_HANDLE, MilNative.MILRenderTargetBitmapGetBitmap(new IntPtr(0x997), out _));
        }

        [Fact]
        public void MILCreateFactory校验SDK版本()
        {
            Assert.Equal(HResult.S_OK, MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion));
            Assert.NotEqual(IntPtr.Zero, factory);
            Assert.Equal(MilDeviceObjectKind.Factory, MilDeviceObjectTable.Resolve(factory).Kind);

            Assert.Equal(MilErrors.WGXERR_UNSUPPORTEDVERSION,
                MilNative.MILCreateFactory(out IntPtr none, 0x12345678));
            Assert.Equal(IntPtr.Zero, none);
        }

        [Fact]
        public void FactoryCreateBitmapRenderTarget拒绝硬件only与非法尺寸()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);

            Assert.Equal(HResult.E_INVALIDARG, MilNative.MILFactoryCreateBitmapRenderTarget(
                factory, 4, 4, MilPixelFormatEnum.Pbgra32, 96f, 96f,
                MILRTInitializationFlags.MIL_RT_HARDWARE_ONLY, out IntPtr hw));
            Assert.Equal(IntPtr.Zero, hw);

            Assert.Equal(HResult.E_INVALIDARG, MilNative.MILFactoryCreateBitmapRenderTarget(
                factory, 0, 4, MilPixelFormatEnum.Pbgra32, 96f, 96f,
                MILRTInitializationFlags.MIL_RT_SOFTWARE_ONLY, out _));

            Assert.Equal(HResult.E_HANDLE, MilNative.MILFactoryCreateBitmapRenderTarget(
                new IntPtr(0x996), 4, 4, MilPixelFormatEnum.Pbgra32, 96f, 96f,
                MILRTInitializationFlags.MIL_RT_SOFTWARE_ONLY, out _));
        }

        [Fact]
        public void FactoryCreateSWRenderTargetForBitmap共享同一块内存()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);

            var bitmap = new SKBitmap(new SKImageInfo(4, 4, SKColorType.Bgra8888, SKAlphaType.Premul));
            bitmap.Erase(SKColors.Blue);
            IntPtr bitmapHandle = MilPixelBufferTable.Register(bitmap);

            Assert.Equal(HResult.S_OK, MilNative.MILFactoryCreateSWRenderTargetForBitmap(
                factory, bitmapHandle, out IntPtr rt));

            var state = (MilRenderTargetState)MilDeviceObjectTable.Resolve(rt).Payload;
            Assert.Same(bitmap, state.Bitmap);
            Assert.False(state.OwnsBitmap);

            // 通过渲染目标改像素，原位图看得到（同一块内存）
            state.Bitmap.SetPixel(2, 2, new SKColor(7, 7, 7, 255));
            Assert.Equal(new SKColor(7, 7, 7, 255), bitmap.GetPixel(2, 2));

            Assert.Equal(HResult.E_HANDLE, MilNative.MILFactoryCreateSWRenderTargetForBitmap(
                factory, new IntPtr(0x995), out _));
        }

        [Fact]
        public void FactoryCreateMediaPlayer返回ENOTIMPL()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);
            Assert.Equal(HResult.E_NOTIMPL, MilNative.MILFactoryCreateMediaPlayer(
                factory, IntPtr.Zero, true, out IntPtr media));
            Assert.Equal(IntPtr.Zero, media);
        }

        [Fact]
        public void InteropDeviceBitmap在Linux上返回ENOTIMPL()
        {
            Assert.Equal(HResult.E_NOTIMPL, MilNative.InteropDeviceBitmap_Create(
                new IntPtr(0x1234), 96.0, 96.0, 1, IntPtr.Zero, true,
                out IntPtr pdb, out uint w, out uint h));
            Assert.Equal(IntPtr.Zero, pdb);
            Assert.Equal(0u, w);
            Assert.Equal(0u, h);

            // 空 D3D 资源是参数错误，先于"未实现"返回
            Assert.Equal(HResult.E_INVALIDARG, MilNative.InteropDeviceBitmap_Create(
                IntPtr.Zero, 96.0, 96.0, 1, IntPtr.Zero, true, out _, out _, out _));

            Assert.Equal(HResult.E_NOTIMPL,
                MilNative.InteropDeviceBitmap_AddDirtyRect(0, 0, 4, 4, pdb));
            Assert.Equal(HResult.E_NOTIMPL,
                MilNative.InteropDeviceBitmap_GetAsSoftwareBitmap(pdb, out IntPtr source));
            Assert.Equal(IntPtr.Zero, source);

            // Detach 是 void 导出：没有实现也就没有资源，幂等空操作
            MilNative.InteropDeviceBitmap_Detach(pdb);
            MilNative.InteropDeviceBitmap_Detach(IntPtr.Zero);
        }

        [Fact]
        public void CreateCWICWrapperBitmap返回同一张位图的新句柄()
        {
            var bitmap = new SKBitmap(new SKImageInfo(2, 2, SKColorType.Bgra8888, SKAlphaType.Premul));
            IntPtr source = MilPixelBufferTable.Register(bitmap);

            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_CreateCWICWrapperBitmap(source, out IntPtr wrapper));

            Assert.NotEqual(IntPtr.Zero, wrapper);
            Assert.NotEqual(source, wrapper);
            Assert.Same(bitmap, MilPixelBufferTable.Resolve(wrapper));

            Assert.Equal(HResult.E_HANDLE,
                MilNative.MilResource_CreateCWICWrapperBitmap(new IntPtr(0x994), out IntPtr none));
            Assert.Equal(IntPtr.Zero, none);
        }

        // ==================================================================
        //  G. WIC 色彩上下文
        // ==================================================================

        [Fact]
        public void ColorContextProfileBytes与类型可读()
        {
            var profile = new byte[] { 1, 2, 3, 4, 5, 6 };
            IntPtr handle = MilColorContextTable.Register(new MilColorContext
            {
                Type = MilWicColorContextType.WICColorContextProfile,
                ProfileBytes = profile,
                ExifColorSpace = 0xFFFF,
            });

            var buffer = new byte[16];
            Assert.Equal(HResult.S_OK,
                MilNative.IWICColorContext_GetProfileBytes_Proxy(handle, 16, buffer, out uint actual));
            Assert.Equal(6u, actual);
            Assert.Equal(profile, buffer[..6]);

            Assert.Equal(HResult.S_OK, MilNative.IWICColorContext_GetType_Proxy(
                handle, out MilWicColorContextType type));
            Assert.Equal(MilWicColorContextType.WICColorContextProfile, type);

            Assert.Equal(HResult.S_OK, MilNative.IWICColorContext_GetExifColorSpace_Proxy(
                handle, out uint exif));
            Assert.Equal(0xFFFFu, exif);
        }

        [Fact]
        public void ColorContext缓冲区不足时返回INSUFFICIENTBUFFER并回填实际长度()
        {
            var profile = new byte[] { 9, 9, 9, 9 };
            IntPtr handle = MilColorContextTable.Register(new MilColorContext
            {
                Type = MilWicColorContextType.WICColorContextProfile,
                ProfileBytes = profile,
            });

            var buffer = new byte[2];
            Assert.Equal(MilErrors.WINCODEC_ERR_INSUFFICIENTBUFFER,
                MilNative.IWICColorContext_GetProfileBytes_Proxy(handle, 2, buffer, out uint actual));

            Assert.Equal(4u, actual);
            Assert.Equal(new byte[] { 9, 9 }, buffer);
        }

        [Fact]
        public void ColorContext未登记句柄返回EHANDLE()
        {
            var buffer = new byte[4];
            Assert.Equal(HResult.E_HANDLE,
                MilNative.IWICColorContext_GetProfileBytes_Proxy(new IntPtr(0x993), 4, buffer, out uint actual));
            Assert.Equal(0u, actual);

            Assert.Equal(HResult.E_HANDLE,
                MilNative.IWICColorContext_GetType_Proxy(new IntPtr(0x993), out _));
            Assert.Equal(HResult.E_HANDLE,
                MilNative.IWICColorContext_GetExifColorSpace_Proxy(new IntPtr(0x993), out _));
        }

        // ==================================================================
        //  E. 版本 / 引用计数 / 流 / 反向包装 / 进程级开关
        // ==================================================================

        [Fact]
        public void MilVersionCheck比对SDK版本()
        {
            Assert.Equal(HResult.S_OK, MilNative.MilVersionCheck(MilErrors.MilSdkVersion));
            Assert.Equal(MilErrors.WGXERR_UNSUPPORTEDVERSION, MilNative.MilVersionCheck(0));
            Assert.Equal(unchecked((int)0x88982F0B),
                MilNative.MilVersionCheck(MilErrors.MilSdkVersion + 1));
        }

        [Fact]
        public void MILAddRef与MILRelease维护引用计数()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);
            Assert.Equal(1u, MilDeviceObjectTable.Resolve(factory).RefCount);

            Assert.Equal(2u, MilNative.MILAddRef(factory));
            Assert.Equal(3u, MilNative.MILAddRef(factory));

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));
            Assert.Equal(2u, MilDeviceObjectTable.Resolve(factory).RefCount);

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));

            // 归零后摘除
            Assert.Null(MilDeviceObjectTable.Resolve(factory));
            Assert.Equal(HResult.E_HANDLE, MilNative.MILRelease(factory));
        }

        [Fact]
        public void MILRelease对空句柄是noop而对未知句柄报错()
        {
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(IntPtr.Zero));
            Assert.Equal(HResult.E_HANDLE, MilNative.MILRelease(new IntPtr(0x992)));
            Assert.Equal(0u, MilNative.MILAddRef(IntPtr.Zero));
            Assert.Equal(0u, MilNative.MILAddRef(new IntPtr(0x992)));
        }

        [Fact]
        public void MILQueryInterface只认IUnknown()
        {
            MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion);

            Guid iidUnknown = MilNative.IID_IUnknown;
            Assert.Equal(HResult.S_OK, MilNative.MILQueryInterface(
                factory, ref iidUnknown, out IntPtr unknown));

            // IID_IUnknown：返回同一句柄并 AddRef
            Assert.Equal(factory, unknown);
            Assert.Equal(2u, MilDeviceObjectTable.Resolve(factory).RefCount);

            Guid other = Guid.Parse("22222222-3333-4444-5555-666666666666");
            Assert.Equal(HResult.E_NOINTERFACE, MilNative.MILQueryInterface(
                factory, ref other, out IntPtr none));
            Assert.Equal(IntPtr.Zero, none);

            Guid iid = MilNative.IID_IUnknown;
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MILQueryInterface(IntPtr.Zero, ref iid, out _));
            Assert.Equal(HResult.E_HANDLE,
                MilNative.MILQueryInterface(new IntPtr(0x991), ref iid, out _));
        }

        [Fact]
        public void CreateEventProxy登记描述符()
        {
            var descriptor = new IntPtr(0xABC0);

            Assert.Equal(HResult.S_OK, MilNative.MILCreateEventProxy(descriptor, out IntPtr proxy));
            Assert.NotEqual(IntPtr.Zero, proxy);

            MilDeviceObject obj = MilDeviceObjectTable.Resolve(proxy);
            Assert.Equal(MilDeviceObjectKind.EventProxy, obj.Kind);
            Assert.Equal(descriptor, (IntPtr)obj.Payload);

            Assert.Equal(HResult.E_INVALIDARG, MilNative.MILCreateEventProxy(IntPtr.Zero, out IntPtr none));
            Assert.Equal(IntPtr.Zero, none);
        }

        [Fact]
        public void CreateStreamFromStreamDescriptor与IStreamWrite真写入()
        {
            var descriptor = new IntPtr(0xDEF0);
            Assert.Equal(HResult.S_OK,
                MilNative.MILCreateStreamFromStreamDescriptor(descriptor, out IntPtr stream));

            byte[] first = { 1, 2, 3 };
            byte[] second = { 4, 5 };

            Assert.Equal(HResult.S_OK, MilNative.MILIStreamWrite(stream, first, 3, out uint written));
            Assert.Equal(3u, written);
            Assert.Equal(HResult.S_OK, MilNative.MILIStreamWrite(stream, second, 2, out written));
            Assert.Equal(2u, written);

            Assert.Equal(new byte[] { 1, 2, 3, 4, 5 }, MilNative.MilStreamBytes(stream));

            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MILCreateStreamFromStreamDescriptor(IntPtr.Zero, out IntPtr none));
            Assert.Equal(IntPtr.Zero, none);
        }

        [Fact]
        public void IStreamWrite错误码()
        {
            MilNative.MILCreateStreamFromStreamDescriptor(new IntPtr(0xDEF1), out IntPtr stream);

            byte[] data = { 1, 2 };

            Assert.Equal(HResult.E_HANDLE, MilNative.MILIStreamWrite(new IntPtr(0x990), data, 2, out uint written));
            Assert.Equal(0u, written);

            Assert.Equal(HResult.E_INVALIDARG, MilNative.MILIStreamWrite(stream, null, 2, out _));
            Assert.Equal(HResult.E_INVALIDARG, MilNative.MILIStreamWrite(stream, data, 5, out _));
        }

        [Fact]
        public void ReversePInvoke包装登记与释放()
        {
            var function = new IntPtr(0xCAFE);

            Assert.Equal(HResult.S_OK,
                MilNative.MilCreateReversePInvokeWrapper(function, out IntPtr wrapper));
            Assert.Equal(function, wrapper);
            Assert.Equal(1, MilReversePInvokeTable.Count);

            MilNative.MilReleasePInvokePtrBlocking(wrapper);
            Assert.Equal(0, MilReversePInvokeTable.Count);

            // 重复释放：void 导出，静默忽略
            MilNative.MilReleasePInvokePtrBlocking(wrapper);

            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilCreateReversePInvokeWrapper(IntPtr.Zero, out IntPtr none));
            Assert.Equal(IntPtr.Zero, none);
        }

        [Fact]
        public void GetNextPerfElementId单调递增()
        {
            long first = MilNative.GetNextPerfElementId();
            long second = MilNative.GetNextPerfElementId();

            Assert.Equal(first + 1, second);
            Assert.True(first > 0);
        }

        [Fact]
        public void UpdateSystemParametersInfo计数并恒SOK()
        {
            int before = MilCompositionEngineState.SystemParametersUpdateCount;

            Assert.Equal(HResult.S_OK, MilNative.MILUpdateSystemParametersInfo());
            Assert.Equal(HResult.S_OK, MilNative.MILUpdateSystemParametersInfo());

            Assert.Equal(before + 2, MilCompositionEngineState.SystemParametersUpdateCount);
        }

        [Fact]
        public void RenderOptions软件渲染开关值可往返()
        {
            Assert.False(MilNative.RenderOptions_IsSoftwareRenderingForcedForProcess());

            MilNative.RenderOptions_ForceSoftwareRenderingModeForProcess(true);
            Assert.True(MilNative.RenderOptions_IsSoftwareRenderingForcedForProcess());
            Assert.True(MilCompositionEngineState.ForceSoftwareRendering);

            MilNative.RenderOptions_ForceSoftwareRenderingModeForProcess(false);
            Assert.False(MilNative.RenderOptions_IsSoftwareRenderingForcedForProcess());
        }

        [Fact]
        public void RenderOptionsRdp硬件加速开关值可往返()
        {
            Assert.False(MilCompositionEngineState.EnableHardwareAccelerationInRdp);

            MilNative.RenderOptions_EnableHardwareAccelerationInRdp(true);
            Assert.True(MilCompositionEngineState.EnableHardwareAccelerationInRdp);

            MilNative.RenderOptions_EnableHardwareAccelerationInRdp(false);
            Assert.False(MilCompositionEngineState.EnableHardwareAccelerationInRdp);
        }

        [Fact]
        public void 边界检查保护开关值可往返()
        {
            Assert.False(MilCompositionEngineState.DisableBoundsCheckProtection);

            MilNative.WpfGfx_SetDisableBoundsCheckProtection(true);
            Assert.True(MilCompositionEngineState.DisableBoundsCheckProtection);

            MilNative.WpfGfx_SetDisableBoundsCheckProtection(false);
            Assert.False(MilCompositionEngineState.DisableBoundsCheckProtection);
        }

        [Fact]
        public void Channel别名与既有导出语义完全一致()
        {
            IntPtr channel = NewChannel();

            Assert.Equal(MilNative.MilConnection_CloseBatch(channel), MilNative.MilChannel_CloseBatch(channel));
            Assert.Equal(MilNative.MilConnection_CommitChannel(channel), MilNative.MilChannel_CommitChannel(channel));

            Assert.Equal(HResult.E_HANDLE, MilNative.MilChannel_CloseBatch(new IntPtr(0x1234)));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilChannel_CommitChannel(new IntPtr(0x1234)));
        }

        [Fact]
        public void GetRefCountOnChannel返回真实引用计数()
        {
            IntPtr channel = NewChannel();
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;

            Assert.Equal(HResult.S_OK, MilNative.MilResource_CreateOrAddRefOnChannel(
                channel, DUCE.ResourceType.TYPE_VISUAL, ref h));

            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_GetRefCountOnChannel(channel, h, out uint refCount));
            Assert.Equal(1u, refCount);

            Assert.Equal(HResult.S_OK, MilNative.MilResource_CreateOrAddRefOnChannel(
                channel, DUCE.ResourceType.TYPE_VISUAL, ref h));
            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_GetRefCountOnChannel(channel, h, out refCount));
            Assert.Equal(2u, refCount);

            Assert.Equal(HResult.E_HANDLE, MilNative.MilResource_GetRefCountOnChannel(
                channel, DUCE.ResourceHandle.Null, out refCount));
            Assert.Equal(0u, refCount);

            Assert.Equal(HResult.E_HANDLE, MilNative.MilResource_GetRefCountOnChannel(
                channel, new DUCE.ResourceHandle(4242), out _));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilResource_GetRefCountOnChannel(
                new IntPtr(0x1234), h, out _));
        }

        // ==================================================================
        //  F. 媒体（21 个导出全部 E_NOTIMPL + 出参安全默认值）
        // ==================================================================

        [Theory]
        [InlineData("MILMediaOpen")]
        [InlineData("MILMediaStop")]
        [InlineData("MILMediaClose")]
        [InlineData("MILMediaGetPosition")]
        [InlineData("MILMediaSetPosition")]
        [InlineData("MILMediaSetVolume")]
        [InlineData("MILMediaSetBalance")]
        [InlineData("MILMediaSetIsScrubbingEnabled")]
        [InlineData("MILMediaIsBuffering")]
        [InlineData("MILMediaCanPause")]
        [InlineData("MILMediaGetDownloadProgress")]
        [InlineData("MILMediaGetBufferingProgress")]
        [InlineData("MILMediaSetRate")]
        [InlineData("MILMediaHasVideo")]
        [InlineData("MILMediaHasAudio")]
        [InlineData("MILMediaGetNaturalHeight")]
        [InlineData("MILMediaGetNaturalWidth")]
        [InlineData("MILMediaGetMediaLength")]
        [InlineData("MILMediaNeedUIFrameUpdate")]
        [InlineData("MILMediaShutdown")]
        [InlineData("MILMediaProcessExitHandler")]
        public void Media导出全部返回ENOTIMPL并写出安全默认值(string export)
        {
            var media = new IntPtr(0x1234);

            switch (export)
            {
                case "MILMediaOpen":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaOpen(media, "http://example.invalid/x.wmv"));
                    break;
                case "MILMediaStop":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaStop(media));
                    break;
                case "MILMediaClose":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaClose(media));
                    break;
                case "MILMediaGetPosition":
                    long position = -1;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetPosition(media, ref position));
                    Assert.Equal(0, position);
                    break;
                case "MILMediaSetPosition":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaSetPosition(media, 1000));
                    break;
                case "MILMediaSetVolume":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaSetVolume(media, 0.5));
                    break;
                case "MILMediaSetBalance":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaSetBalance(media, 0.0));
                    break;
                case "MILMediaSetIsScrubbingEnabled":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaSetIsScrubbingEnabled(media, true));
                    break;
                case "MILMediaIsBuffering":
                    bool buffering = true;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaIsBuffering(media, ref buffering));
                    Assert.False(buffering);
                    break;
                case "MILMediaCanPause":
                    bool canPause = true;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaCanPause(media, ref canPause));
                    Assert.False(canPause);
                    break;
                case "MILMediaGetDownloadProgress":
                    double download = -1;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetDownloadProgress(media, ref download));
                    Assert.Equal(0.0, download);
                    break;
                case "MILMediaGetBufferingProgress":
                    double progress = -1;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetBufferingProgress(media, ref progress));
                    Assert.Equal(0.0, progress);
                    break;
                case "MILMediaSetRate":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaSetRate(media, 2.0));
                    break;
                case "MILMediaHasVideo":
                    bool hasVideo = true;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaHasVideo(media, ref hasVideo));
                    Assert.False(hasVideo);
                    break;
                case "MILMediaHasAudio":
                    bool hasAudio = true;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaHasAudio(media, ref hasAudio));
                    Assert.False(hasAudio);
                    break;
                case "MILMediaGetNaturalHeight":
                    uint height = 7;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetNaturalHeight(media, ref height));
                    Assert.Equal(0u, height);
                    break;
                case "MILMediaGetNaturalWidth":
                    uint width = 7;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetNaturalWidth(media, ref width));
                    Assert.Equal(0u, width);
                    break;
                case "MILMediaGetMediaLength":
                    long length = -1;
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaGetMediaLength(media, ref length));
                    Assert.Equal(0, length);
                    break;
                case "MILMediaNeedUIFrameUpdate":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaNeedUIFrameUpdate(media));
                    break;
                case "MILMediaShutdown":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaShutdown(media));
                    break;
                case "MILMediaProcessExitHandler":
                    Assert.Equal(HResult.E_NOTIMPL, MilNative.MILMediaProcessExitHandler(media));
                    break;
                default:
                    Assert.Fail($"未覆盖的媒体导出：{export}");
                    break;
            }
        }
    }
}
