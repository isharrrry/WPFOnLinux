// Licensed to the .NET Foundation under one or more agreements.
//
// 字节布局校验。
//
// 这里做的是**机械比对**，不做人工肉眼核对：
//   1. Marshal.SizeOf<线格结构体>() 必须等于 MilCommandLayout.FixedSize(命令字)
//      —— 两者是独立誊写的两份数据，一侧写错就红。
//   2. 命令头（Type@0 / Handle@4）用 Marshal.OffsetOf 抽查，
//      证明 handoff §3.2「命令类型 1 字节」的说法是错的。
//   3. 变长尾部的步长（MIL_GRADIENTSTOP=24）单独钉死常量。
//
// 结构体本身的每个 FieldOffset 由 tools/verify-cmd-layout.py 与上游
// Generated/wgx_commands.cs 逐项比对（脚本比对全部共有结构体的偏移序列，当前 101 个）。

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using Xunit;
using S = WpfGfx.Linux.Commands.MilCommandStructs;
using WpfGfx.Linux.Interop;

namespace WpfGfx.Linux.Tests.Commands
{
    public class CommandLayoutTests
    {
        /// <summary>
        /// (命令字, 线格结构体) 对照表。101 个已移植结构。
        /// 数量由 对照表覆盖全部已移植结构 自动核对，不靠人工维护这个数字。
        /// </summary>
        public static IEnumerable<object[]> CommandStructs => new List<object[]>
        {
            new object[] { (int)MilCmd.MilCmdPartitionRegisterForNotifications, typeof(S.MILCMD_PARTITION_REGISTERFORNOTIFICATIONS) },
            new object[] { (int)MilCmd.MilCmdChannelRequestTier, typeof(S.MILCMD_CHANNEL_REQUESTTIER) },
            new object[] { (int)MilCmd.MilCmdPartitionSetVBlankSyncMode, typeof(S.MILCMD_PARTITION_SETVBLANKSYNCMODE) },
            new object[] { (int)MilCmd.MilCmdPartitionNotifyPresent, typeof(S.MILCMD_PARTITION_NOTIFYPRESENT) },
            new object[] { (int)MilCmd.MilCmdPartitionNotifyPolicyChangeForNonInteractiveMode, typeof(S.MILCMD_PARTITION_NOTIFYPOLICYCHANGEFORNONINTERACTIVEMODE) },

            // ---- 位图源 (0x0c, 0x0d)，2 条 ----
            // 上一个 agent 在 MilCommandStructs.cs 里加了这两个结构、却忘了往这张表补条目，
            // 于是 对照表覆盖全部已移植结构 报 103 != 101。补上后两边都是 103。
            // 0x0c 的权威源是 C++ 头 wgx_commands.h:86（C# 生成版无此结构），
            // 所以 verify-cmd-layout.py 不会比对它；这里的 Marshal.SizeOf 是它唯一的机械护栏。
            new object[] { (int)MilCmd.MilCmdBitmapSource, typeof(S.MILCMD_BITMAP_SOURCE) },
            new object[] { (int)MilCmd.MilCmdBitmapInvalidate, typeof(S.MILCMD_BITMAP_INVALIDATE) },

            new object[] { (int)MilCmd.MilCmdDoubleResource, typeof(S.MILCMD_DOUBLERESOURCE) },
            new object[] { (int)MilCmd.MilCmdColorResource, typeof(S.MILCMD_COLORRESOURCE) },
            new object[] { (int)MilCmd.MilCmdPointResource, typeof(S.MILCMD_POINTRESOURCE) },
            new object[] { (int)MilCmd.MilCmdRectResource, typeof(S.MILCMD_RECTRESOURCE) },
            new object[] { (int)MilCmd.MilCmdSizeResource, typeof(S.MILCMD_SIZERESOURCE) },
            new object[] { (int)MilCmd.MilCmdMatrixResource, typeof(S.MILCMD_MATRIXRESOURCE) },
            new object[] { (int)MilCmd.MilCmdPoint3DResource, typeof(S.MILCMD_POINT3DRESOURCE) },
            new object[] { (int)MilCmd.MilCmdVector3DResource, typeof(S.MILCMD_VECTOR3DRESOURCE) },
            new object[] { (int)MilCmd.MilCmdQuaternionResource, typeof(S.MILCMD_QUATERNIONRESOURCE) },
            new object[] { (int)MilCmd.MilCmdEtwEventResource, typeof(S.MILCMD_ETWEVENTRESOURCE) },
            new object[] { (int)MilCmd.MilCmdRenderData, typeof(S.MILCMD_RENDERDATA) },

            new object[] { (int)MilCmd.MilCmdVisualSetOffset, typeof(S.MILCMD_VISUAL_SETOFFSET) },
            new object[] { (int)MilCmd.MilCmdVisualSetTransform, typeof(S.MILCMD_VISUAL_SETTRANSFORM) },
            new object[] { (int)MilCmd.MilCmdVisualSetEffect, typeof(S.MILCMD_VISUAL_SETEFFECT) },
            new object[] { (int)MilCmd.MilCmdVisualSetCacheMode, typeof(S.MILCMD_VISUAL_SETCACHEMODE) },
            new object[] { (int)MilCmd.MilCmdVisualSetClip, typeof(S.MILCMD_VISUAL_SETCLIP) },
            new object[] { (int)MilCmd.MilCmdVisualSetAlpha, typeof(S.MILCMD_VISUAL_SETALPHA) },
            new object[] { (int)MilCmd.MilCmdVisualSetRenderOptions, typeof(S.MILCMD_VISUAL_SETRENDEROPTIONS) },
            new object[] { (int)MilCmd.MilCmdVisualSetContent, typeof(S.MILCMD_VISUAL_SETCONTENT) },
            new object[] { (int)MilCmd.MilCmdVisualSetAlphaMask, typeof(S.MILCMD_VISUAL_SETALPHAMASK) },
            new object[] { (int)MilCmd.MilCmdVisualRemoveAllChildren, typeof(S.MILCMD_VISUAL_REMOVEALLCHILDREN) },
            new object[] { (int)MilCmd.MilCmdVisualRemoveChild, typeof(S.MILCMD_VISUAL_REMOVECHILD) },
            new object[] { (int)MilCmd.MilCmdVisualInsertChildAt, typeof(S.MILCMD_VISUAL_INSERTCHILDAT) },
            new object[] { (int)MilCmd.MilCmdVisualSetGuidelineCollection, typeof(S.MILCMD_VISUAL_SETGUIDELINECOLLECTION) },
            new object[] { (int)MilCmd.MilCmdVisualSetScrollableAreaClip, typeof(S.MILCMD_VISUAL_SETSCROLLABLEAREACLIP) },

            new object[] { (int)MilCmd.MilCmdHwndTargetCreate, typeof(S.MILCMD_HWNDTARGET_CREATE) },
            new object[] { (int)MilCmd.MilCmdHwndTargetSuppressLayered, typeof(S.MILCMD_HWNDTARGET_SUPPRESSLAYERED) },
            new object[] { (int)MilCmd.MilCmdTargetUpdateWindowSettings, typeof(S.MILCMD_TARGET_UPDATEWINDOWSETTINGS) },
            new object[] { (int)MilCmd.MilCmdGenericTargetCreate, typeof(S.MILCMD_GENERICTARGET_CREATE) },
            new object[] { (int)MilCmd.MilCmdTargetSetRoot, typeof(S.MILCMD_TARGET_SETROOT) },
            new object[] { (int)MilCmd.MilCmdTargetSetClearColor, typeof(S.MILCMD_TARGET_SETCLEARCOLOR) },
            new object[] { (int)MilCmd.MilCmdTargetInvalidate, typeof(S.MILCMD_TARGET_INVALIDATE) },
            new object[] { (int)MilCmd.MilCmdTargetSetFlags, typeof(S.MILCMD_TARGET_SETFLAGS) },
            new object[] { (int)MilCmd.MilCmdHwndTargetDpiChanged, typeof(S.MILCMD_HWNDTARGET_DPICHANGED) },
            new object[] { (int)MilCmd.MilCmdGlyphRunCreate, typeof(S.MILCMD_GLYPHRUN_CREATE) },

            new object[] { (int)MilCmd.MilCmdTransformGroup, typeof(S.MILCMD_TRANSFORMGROUP) },
            new object[] { (int)MilCmd.MilCmdTranslateTransform, typeof(S.MILCMD_TRANSLATETRANSFORM) },
            new object[] { (int)MilCmd.MilCmdScaleTransform, typeof(S.MILCMD_SCALETRANSFORM) },
            new object[] { (int)MilCmd.MilCmdSkewTransform, typeof(S.MILCMD_SKEWTRANSFORM) },
            new object[] { (int)MilCmd.MilCmdRotateTransform, typeof(S.MILCMD_ROTATETRANSFORM) },
            new object[] { (int)MilCmd.MilCmdMatrixTransform, typeof(S.MILCMD_MATRIXTRANSFORM) },

            new object[] { (int)MilCmd.MilCmdLineGeometry, typeof(S.MILCMD_LINEGEOMETRY) },
            new object[] { (int)MilCmd.MilCmdRectangleGeometry, typeof(S.MILCMD_RECTANGLEGEOMETRY) },
            new object[] { (int)MilCmd.MilCmdEllipseGeometry, typeof(S.MILCMD_ELLIPSEGEOMETRY) },
            new object[] { (int)MilCmd.MilCmdGeometryGroup, typeof(S.MILCMD_GEOMETRYGROUP) },
            new object[] { (int)MilCmd.MilCmdCombinedGeometry, typeof(S.MILCMD_COMBINEDGEOMETRY) },
            new object[] { (int)MilCmd.MilCmdPathGeometry, typeof(S.MILCMD_PATHGEOMETRY) },

            new object[] { (int)MilCmd.MilCmdImplicitInputBrush, typeof(S.MILCMD_IMPLICITINPUTBRUSH) },
            new object[] { (int)MilCmd.MilCmdSolidColorBrush, typeof(S.MILCMD_SOLIDCOLORBRUSH) },
            new object[] { (int)MilCmd.MilCmdLinearGradientBrush, typeof(S.MILCMD_LINEARGRADIENTBRUSH) },
            new object[] { (int)MilCmd.MilCmdRadialGradientBrush, typeof(S.MILCMD_RADIALGRADIENTBRUSH) },
            new object[] { (int)MilCmd.MilCmdImageBrush, typeof(S.MILCMD_IMAGEBRUSH) },
            new object[] { (int)MilCmd.MilCmdDrawingBrush, typeof(S.MILCMD_DRAWINGBRUSH) },
            new object[] { (int)MilCmd.MilCmdVisualBrush, typeof(S.MILCMD_VISUALBRUSH) },
            new object[] { (int)MilCmd.MilCmdBitmapCacheBrush, typeof(S.MILCMD_BITMAPCACHEBRUSH) },

            new object[] { (int)MilCmd.MilCmdBlurEffect, typeof(S.MILCMD_BLUREFFECT) },
            new object[] { (int)MilCmd.MilCmdDropShadowEffect, typeof(S.MILCMD_DROPSHADOWEFFECT) },

            new object[] { (int)MilCmd.MilCmdDashStyle, typeof(S.MILCMD_DASHSTYLE) },
            new object[] { (int)MilCmd.MilCmdPen, typeof(S.MILCMD_PEN) },

            new object[] { (int)MilCmd.MilCmdDrawingImage, typeof(S.MILCMD_DRAWINGIMAGE) },
            new object[] { (int)MilCmd.MilCmdGeometryDrawing, typeof(S.MILCMD_GEOMETRYDRAWING) },
            new object[] { (int)MilCmd.MilCmdGlyphRunDrawing, typeof(S.MILCMD_GLYPHRUNDRAWING) },
            new object[] { (int)MilCmd.MilCmdImageDrawing, typeof(S.MILCMD_IMAGEDRAWING) },
            new object[] { (int)MilCmd.MilCmdVideoDrawing, typeof(S.MILCMD_VIDEODRAWING) },
            new object[] { (int)MilCmd.MilCmdDrawingGroup, typeof(S.MILCMD_DRAWINGGROUP) },

            new object[] { (int)MilCmd.MilCmdGuidelineSet, typeof(S.MILCMD_GUIDELINESET) },
            new object[] { (int)MilCmd.MilCmdBitmapCache, typeof(S.MILCMD_BITMAPCACHE) },

            // ---- 3D 视觉树 (0x29–0x30)，8 条 ----
            new object[] { (int)MilCmd.MilCmdViewport3DVisualSetCamera, typeof(S.MILCMD_VIEWPORT3DVISUAL_SETCAMERA) },
            new object[] { (int)MilCmd.MilCmdViewport3DVisualSetViewport, typeof(S.MILCMD_VIEWPORT3DVISUAL_SETVIEWPORT) },
            new object[] { (int)MilCmd.MilCmdViewport3DVisualSet3DChild, typeof(S.MILCMD_VIEWPORT3DVISUAL_SET3DCHILD) },
            new object[] { (int)MilCmd.MilCmdVisual3DSetContent, typeof(S.MILCMD_VISUAL3D_SETCONTENT) },
            new object[] { (int)MilCmd.MilCmdVisual3DSetTransform, typeof(S.MILCMD_VISUAL3D_SETTRANSFORM) },
            new object[] { (int)MilCmd.MilCmdVisual3DRemoveAllChildren, typeof(S.MILCMD_VISUAL3D_REMOVEALLCHILDREN) },
            new object[] { (int)MilCmd.MilCmdVisual3DRemoveChild, typeof(S.MILCMD_VISUAL3D_REMOVECHILD) },
            new object[] { (int)MilCmd.MilCmdVisual3DInsertChildAt, typeof(S.MILCMD_VISUAL3D_INSERTCHILDAT) },

            // ---- 3D 资源 (0x57–0x6b)，21 条 ----
            new object[] { (int)MilCmd.MilCmdAxisAngleRotation3D, typeof(S.MILCMD_AXISANGLEROTATION3D) },
            new object[] { (int)MilCmd.MilCmdQuaternionRotation3D, typeof(S.MILCMD_QUATERNIONROTATION3D) },
            new object[] { (int)MilCmd.MilCmdPerspectiveCamera, typeof(S.MILCMD_PERSPECTIVECAMERA) },
            new object[] { (int)MilCmd.MilCmdOrthographicCamera, typeof(S.MILCMD_ORTHOGRAPHICCAMERA) },
            new object[] { (int)MilCmd.MilCmdMatrixCamera, typeof(S.MILCMD_MATRIXCAMERA) },
            new object[] { (int)MilCmd.MilCmdModel3DGroup, typeof(S.MILCMD_MODEL3DGROUP) },
            new object[] { (int)MilCmd.MilCmdAmbientLight, typeof(S.MILCMD_AMBIENTLIGHT) },
            new object[] { (int)MilCmd.MilCmdDirectionalLight, typeof(S.MILCMD_DIRECTIONALLIGHT) },
            new object[] { (int)MilCmd.MilCmdPointLight, typeof(S.MILCMD_POINTLIGHT) },
            new object[] { (int)MilCmd.MilCmdSpotLight, typeof(S.MILCMD_SPOTLIGHT) },
            new object[] { (int)MilCmd.MilCmdGeometryModel3D, typeof(S.MILCMD_GEOMETRYMODEL3D) },
            new object[] { (int)MilCmd.MilCmdMeshGeometry3D, typeof(S.MILCMD_MESHGEOMETRY3D) },
            new object[] { (int)MilCmd.MilCmdMaterialGroup, typeof(S.MILCMD_MATERIALGROUP) },
            new object[] { (int)MilCmd.MilCmdDiffuseMaterial, typeof(S.MILCMD_DIFFUSEMATERIAL) },
            new object[] { (int)MilCmd.MilCmdSpecularMaterial, typeof(S.MILCMD_SPECULARMATERIAL) },
            new object[] { (int)MilCmd.MilCmdEmissiveMaterial, typeof(S.MILCMD_EMISSIVEMATERIAL) },
            new object[] { (int)MilCmd.MilCmdTransform3DGroup, typeof(S.MILCMD_TRANSFORM3DGROUP) },
            new object[] { (int)MilCmd.MilCmdTranslateTransform3D, typeof(S.MILCMD_TRANSLATETRANSFORM3D) },
            new object[] { (int)MilCmd.MilCmdScaleTransform3D, typeof(S.MILCMD_SCALETRANSFORM3D) },
            new object[] { (int)MilCmd.MilCmdRotateTransform3D, typeof(S.MILCMD_ROTATETRANSFORM3D) },
            new object[] { (int)MilCmd.MilCmdMatrixTransform3D, typeof(S.MILCMD_MATRIXTRANSFORM3D) },
        };

        [Theory]
        [MemberData(nameof(CommandStructs))]
        public void 结构体尺寸必须等于长度表(int cmdValue, Type structType)
        {
            // MilCmd 是 internal（契约层），public 测试方法的签名里只能用 int 承载
            var cmd = (MilCmd)cmdValue;
            Assert.Equal(Marshal.SizeOf(structType), MilCommandLayout.FixedSize(cmd));
        }

        [Theory]
        [MemberData(nameof(CommandStructs))]
        public void 命令头必须是Type在0Handle在4(int cmdValue, Type structType)
        {
            var cmd = (MilCmd)cmdValue;
            Assert.Equal(0, Marshal.OffsetOf(structType, "Type").ToInt32());

            // 分区级命令（0x03–0x06, 0x3d）没有 Handle 字段。
            bool hasHandle = structType.GetField("Handle") != null;
            if (hasHandle)
            {
                Assert.Equal(4, Marshal.OffsetOf(structType, "Handle").ToInt32());
                Assert.Equal(4, MilCommandDecoder.HeaderHandleOffset);
            }
            else
            {
                Assert.True(cmd == MilCmd.MilCmdPartitionRegisterForNotifications
                            || cmd == MilCmd.MilCmdChannelRequestTier
                            || cmd == MilCmd.MilCmdPartitionSetVBlankSyncMode
                            || cmd == MilCmd.MilCmdPartitionNotifyPresent
                            || cmd == MilCmd.MilCmdPartitionNotifyPolicyChangeForNonInteractiveMode,
                            $"{cmd} 缺少 Handle 字段，但它不是分区级命令");
            }
        }

        [Fact]
        public void 渐变停靠点步长必须是24字节()
        {
            // 托管侧 LinearGradientBrush.cs:179 用 sizeof(DUCE.MIL_GRADIENTSTOP)*count；
            // 原生侧 marshal_generated.cpp:5760 用 % sizeof(MilGradientStop) 校验。
            Assert.Equal(24, MilGradientStop.SizeInBytes);
            Assert.Equal(24, Marshal.SizeOf<MilGradientStop>());
            Assert.Equal(0, Marshal.OffsetOf<MilGradientStop>("Position").ToInt32());
            Assert.Equal(8, Marshal.OffsetOf<MilGradientStop>("Color").ToInt32());
        }

        [Fact]
        public void 基础原语尺寸()
        {
            Assert.Equal(4, Marshal.SizeOf<DUCE.ResourceHandle>());
            Assert.Equal(16, Marshal.SizeOf<MilColorF>());
            Assert.Equal(16, Marshal.SizeOf<MilPoint>());
            Assert.Equal(32, Marshal.SizeOf<MilRect>());
            Assert.Equal(16, Marshal.SizeOf<MilRectI>());
            Assert.Equal(48, Marshal.SizeOf<MilMatrix3x2D>());
            Assert.Equal(28, Marshal.SizeOf<MilRenderOptions>());   // 7 × enum(4)
        }

        [Fact]
        public void NotifyPresent是12字节而不是16()
        {
            // 回归测试：上游 wgx_commands.cs:44 FrameTime 在 FieldOffset(4)。
            // 本项目曾误写成 8（按 8 字节对齐推测），导致该命令整体多 4 字节。
            Assert.Equal(4, Marshal.OffsetOf<S.MILCMD_PARTITION_NOTIFYPRESENT>("FrameTime").ToInt32());
            Assert.Equal(12, Marshal.SizeOf<S.MILCMD_PARTITION_NOTIFYPRESENT>());
        }

        [Fact]
        public void 对照表覆盖全部已移植结构()
        {
            int structCount = typeof(S).GetNestedTypes(
                System.Reflection.BindingFlags.Public |
                System.Reflection.BindingFlags.NonPublic).Length;
            int tableCount = 0;
            foreach (object[] _ in CommandStructs) tableCount++;
            Assert.Equal(structCount, tableCount);
        }
    }
}
