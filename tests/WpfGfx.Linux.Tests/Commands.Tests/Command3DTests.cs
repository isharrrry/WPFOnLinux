// Licensed to the .NET Foundation under one or more agreements.
//
// 3D 命令（0x29–0x30 视觉树 8 条 + 0x57–0x6b 资源 21 条，共 29 条 A 类）的测试。
//
// 分三层断言：
//   (A) 字节层：Encode(值) → ReadFixed<线格结构体>() 后字段相等。
//       编码器的偏移常量与结构体的 FieldOffset 是两份独立誊写的数据，
//       任一侧写错这层就红。
//   (B) 语义层：Dispatch(字节) 后 MilResource3DTable 里的状态等于原值。
//       这层证明解码分支把字段接到了正确的对象字段上。
//   (C) 边界：零值 / 极值 / 无效句柄 / 类型不符 / 长度不足。
//
// 与上游逐 FieldOffset 的比对由 CommandLayoutTests + tools/verify-cmd-layout.py 负责，
// 本文件不重复那件事——(A)+(B) 都过只证明「编解码两侧自洽」。
//
// 【为什么要补 0x57–0x6b 那 21 条】
// MilCommandEncoder.cs 的注释从上一轮起就写着「双向校验由 Command3DTests 负责」，
// 但这个文件当时没写出来——21 条命令只有编码器、没有 round-trip。本轮补齐。

using System;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using S = WpfGfx.Linux.Commands.MilCommandStructs;

namespace WpfGfx.Linux.Tests.Commands
{
    public class Command3DTests
    {
        private static MilResource Own(TestChannel ch, DUCE.ResourceHandle h) =>
            ch.Channel.Resources.Lookup(h);

        // ============================================================
        //  0x29–0x2b · Viewport3DVisual
        // ============================================================

        [Fact]
        public void RoundTrip_Viewport3DVisualSetCamera()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var hCamera = ch.Create(DUCE.ResourceType.TYPE_PERSPECTIVECAMERA);

            byte[] cmd = MilCommandEncoder.Viewport3DVisualSetCamera(h, hCamera);

            // (A) 字节层：hCamera 必须在偏移 8，不能落到 4（那是 Handle 自己的位置）
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VIEWPORT3DVISUAL_SETCAMERA>(cmd);
            Assert.Equal(MilCmd.MilCmdViewport3DVisualSetCamera, s.Type);
            Assert.Equal(h, s.Handle);
            Assert.Equal(hCamera, s.HCamera);
            Assert.Equal(12, cmd.Length);

            // (B) 语义层
            ch.Send(cmd);
            Assert.Equal(hCamera, MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, h)).HCamera);
        }

        [Fact]
        public void RoundTrip_Viewport3DVisualSetViewport()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var viewport = new MilRect(10.5, -20.25, 640.125, 480.75);

            byte[] cmd = MilCommandEncoder.Viewport3DVisualSetViewport(h, viewport);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VIEWPORT3DVISUAL_SETVIEWPORT>(cmd);
            Assert.Equal(viewport, s.Viewport);
            Assert.Equal(40, cmd.Length);          // 8 头 + Rect(4×double)

            ch.Send(cmd);
            Assert.Equal(viewport, MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, h)).Viewport);
        }

        [Fact]
        public void RoundTrip_Viewport3DVisualSet3DChild()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var hChild = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            byte[] cmd = MilCommandEncoder.Viewport3DVisualSet3DChild(h, hChild);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VIEWPORT3DVISUAL_SET3DCHILD>(cmd);
            Assert.Equal(hChild, s.HChild);

            ch.Send(cmd);
            Assert.Equal(hChild, MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, h)).HChild);
        }

        /// <summary>三条 Viewport3DVisual 命令各写各的字段，互不覆盖。</summary>
        [Fact]
        public void Viewport3DVisual_三条命令互不覆盖()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var hCamera = ch.Create(DUCE.ResourceType.TYPE_PERSPECTIVECAMERA);
            var hChild = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var viewport = new MilRect(1, 2, 3, 4);

            ch.Send(MilCommandEncoder.Viewport3DVisualSetCamera(h, hCamera));
            ch.Send(MilCommandEncoder.Viewport3DVisualSetViewport(h, viewport));
            ch.Send(MilCommandEncoder.Viewport3DVisualSet3DChild(h, hChild));

            var r = MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, h));
            Assert.Equal(hCamera, r.HCamera);
            Assert.Equal(viewport, r.Viewport);
            Assert.Equal(hChild, r.HChild);
            Assert.Equal(MilCmd.MilCmdViewport3DVisualSet3DChild, r.LastCommand);
        }

        // ============================================================
        //  0x2c–0x30 · Visual3D
        // ============================================================

        [Fact]
        public void RoundTrip_Visual3DSetContent()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var hContent = ch.Create(DUCE.ResourceType.TYPE_MODEL3DGROUP);

            byte[] cmd = MilCommandEncoder.Visual3DSetContent(h, hContent);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL3D_SETCONTENT>(cmd);
            Assert.Equal(hContent, s.HContent);
            Assert.Equal(12, cmd.Length);

            ch.Send(cmd);
            Assert.Equal(hContent, MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h)).HContent);
        }

        [Fact]
        public void RoundTrip_Visual3DSetTransform()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var hTransform = ch.Create(DUCE.ResourceType.TYPE_TRANSFORM3DGROUP);

            byte[] cmd = MilCommandEncoder.Visual3DSetTransform(h, hTransform);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL3D_SETTRANSFORM>(cmd);
            Assert.Equal(hTransform, s.HTransform);

            ch.Send(cmd);
            Assert.Equal(hTransform, MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h)).HTransform);
        }

        /// <summary>
        /// 0x30 的插入 / 0x2f 的移除 / 0x2e 的清空——子节点列表是真的在增删，
        /// 这是这三条命令与「返回 S_OK 但啥也没干」的分界线。
        /// </summary>
        [Fact]
        public void Visual3D_子节点真的在增删()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var a = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var b = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var c = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, a, 0));
            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, b, 1));
            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, c, 0));   // 插到最前
            var r = MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h));
            Assert.Equal(new[] { c, a, b }, r.Children);

            ch.Send(MilCommandEncoder.Visual3DRemoveChild(h, a));        // 移除中间的
            Assert.Equal(new[] { c, b }, r.Children);

            ch.Send(MilCommandEncoder.Visual3DRemoveAllChildren(h));
            Assert.Empty(r.Children);
        }

        /// <summary>下标越界：与 2D 的 MilCmdVisualInsertChildAt 同约定——钳到末尾，不报错。</summary>
        [Theory]
        [InlineData(1u)]            // 恰好等于 Count：正常追加
        [InlineData(2u)]            // 刚好越过 1
        [InlineData(999u)]
        [InlineData(uint.MaxValue)]
        public void Visual3DInsertChildAt_下标越界钳到末尾(uint index)
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var a = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var b = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, a, 0));
            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, b, index));

            var r = MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h));
            Assert.Equal(2, r.Children.Count);
            Assert.Equal(a, r.Children[0]);
            Assert.Equal(b, r.Children[1]);         // 无论 index 多大都追加到末尾
        }

        [Fact]
        public void Visual3DInsertChildAt_空列表时下标0是合法的()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var a = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, a, 0));

            var r = MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h));
            Assert.Single(r.Children);
            Assert.Equal(a, r.Children[0]);
        }

        /// <summary>移除不存在的子节点：List.Remove 语义，无操作、不报错。</summary>
        [Fact]
        public void Visual3DRemoveChild_移除不存在的子节点不报错()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var a = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);
            var ghost = new DUCE.ResourceHandle(0xDEAD);

            ch.Send(MilCommandEncoder.Visual3DInsertChildAt(h, a, 0));
            ch.Send(MilCommandEncoder.Visual3DRemoveChild(h, ghost));

            var r = MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h));
            Assert.Single(r.Children);
            Assert.Equal(a, r.Children[0]);
        }

        /// <summary>对空列表调 RemoveAllChildren 是合法的无操作。</summary>
        [Fact]
        public void Visual3DRemoveAllChildren_空列表是合法无操作()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            ch.Send(MilCommandEncoder.Visual3DRemoveAllChildren(h));

            var r = MilResource3DTable.Lookup<MilVisual3D>(Own(ch, h));
            Assert.Empty(r.Children);
            Assert.Equal(MilCmd.MilCmdVisual3DRemoveAllChildren, r.LastCommand);
        }

        // ============================================================
        //  0x29–0x30 · 边界
        // ============================================================

        /// <summary>零值：全零载荷必须能解且落得下去（尤其 Rect 全零）。</summary>
        [Fact]
        public void 视觉树3D_零值载荷()
        {
            var ch = new TestChannel();
            var hView = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var hVis = ch.Create(DUCE.ResourceType.TYPE_VISUAL3D);

            ch.Send(MilCommandEncoder.Viewport3DVisualSetCamera(hView, DUCE.ResourceHandle.Null));
            ch.Send(MilCommandEncoder.Viewport3DVisualSetViewport(hView, MilRect.Empty));
            ch.Send(MilCommandEncoder.Viewport3DVisualSet3DChild(hView, DUCE.ResourceHandle.Null));
            ch.Send(MilCommandEncoder.Visual3DSetContent(hVis, DUCE.ResourceHandle.Null));
            ch.Send(MilCommandEncoder.Visual3DSetTransform(hVis, DUCE.ResourceHandle.Null));

            Assert.Equal(DUCE.ResourceHandle.Null,
                MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, hView)).HCamera);
            Assert.Equal(MilRect.Empty,
                MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, hView)).Viewport);
            Assert.Equal(DUCE.ResourceHandle.Null,
                MilResource3DTable.Lookup<MilVisual3D>(Own(ch, hVis)).HContent);
        }

        /// <summary>极值：double 的有限极值必须原样往返（NaN 不测——M1 不做规范化）。</summary>
        [Fact]
        public void 视觉树3D_极值Rect往返()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            var extreme = new MilRect(double.MinValue, double.MaxValue, double.Epsilon, -double.MaxValue);

            ch.Send(MilCommandEncoder.Viewport3DVisualSetViewport(h, extreme));

            Assert.Equal(extreme, MilResource3DTable.Lookup<MilViewport3DVisual>(Own(ch, h)).Viewport);
        }

        [Fact]
        public void 视觉树3D_句柄为空返回EINVALARG()
        {
            var ch = new TestChannel();
            byte[] cmd = MilCommandEncoder.Viewport3DVisualSetCamera(
                DUCE.ResourceHandle.Null, new DUCE.ResourceHandle(7));

            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(cmd));
        }

        [Fact]
        public void 视觉树3D_句柄不在表内返回EHANDLE()
        {
            var ch = new TestChannel();
            var ghost = new DUCE.ResourceHandle(0xBEEF);
            byte[] cmd = MilCommandEncoder.Visual3DSetContent(ghost, new DUCE.ResourceHandle(7));

            Assert.Equal(HResult.E_HANDLE, ch.Dispatch(cmd));
        }

        /// <summary>
        /// 类型不符：把 Visual3D 的命令发给 Viewport3DVisual 的资源，必须 E_INVALIDARG。
        /// 这条守住 Require3D 的类型校验——3D 资源在表里全是占位 MilOpaqueResource，
        /// 没有 CLR 子类型可区分，只能靠 DUCE.ResourceType 判定。
        /// </summary>
        [Fact]
        public void 视觉树3D_资源类型不符返回EINVALARG()
        {
            var ch = new TestChannel();
            var hView = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);

            Assert.Equal(HResult.E_INVALIDARG,
                ch.Dispatch(MilCommandEncoder.Visual3DSetContent(hView, new DUCE.ResourceHandle(7))));
            Assert.Equal(HResult.E_INVALIDARG,
                ch.Dispatch(MilCommandEncoder.Viewport3DVisualSetCamera(
                    ch.Create(DUCE.ResourceType.TYPE_VISUAL3D), new DUCE.ResourceHandle(7))));
        }

        [Theory]
        [InlineData(0)]
        [InlineData(4)]
        [InlineData(9)]     // SetCamera 需要 12 字节，给 9 字节
        public void 视觉树3D_命令长度不足返回EINVALARG(int length)
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VIEWPORT3DVISUAL);
            byte[] cmd = MilCommandEncoder.Viewport3DVisualSetCamera(h, new DUCE.ResourceHandle(7));

            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(cmd[..Math.Min(length, cmd.Length)]));
        }

        // ============================================================
        //  0x57–0x6b · 21 条 3D 资源（上一轮实现、当时缺 round-trip，本轮补齐）
        // ============================================================

        [Fact]
        public void RoundTrip_3D旋转()
        {
            var ch = new TestChannel();
            var hAxis = ch.Create(DUCE.ResourceType.TYPE_AXISANGLEROTATION3D);
            var hQuat = ch.Create(DUCE.ResourceType.TYPE_QUATERNIONROTATION3D);
            var axis = new MilPoint3F(0.5f, -0.25f, 1.75f);
            var q = new MilQuaternionF(0.1f, 0.2f, 0.3f, 0.4f);

            ch.Send(MilCommandEncoder.AxisAngleRotation3D(hAxis, 1.5707963267948966, axis));
            ch.Send(MilCommandEncoder.QuaternionRotation3D(hQuat, q));

            var ra = MilResource3DTable.Lookup<MilAxisAngleRotation3D>(Own(ch, hAxis));
            Assert.Equal(1.5707963267948966, ra.Angle);
            Assert.Equal(axis, ra.Axis);

            var rq = MilResource3DTable.Lookup<MilQuaternionRotation3D>(Own(ch, hQuat));
            Assert.Equal(q, rq.Quaternion);
        }

        [Fact]
        public void RoundTrip_3D相机()
        {
            var ch = new TestChannel();
            var hPer = ch.Create(DUCE.ResourceType.TYPE_PERSPECTIVECAMERA);
            var hOrtho = ch.Create(DUCE.ResourceType.TYPE_ORTHOGRAPHICCAMERA);
            var hMat = ch.Create(DUCE.ResourceType.TYPE_MATRIXCAMERA);
            var hTransform = ch.Create(DUCE.ResourceType.TYPE_TRANSFORM3DGROUP);
            var pos = new MilPoint3F(1, 2, 3);
            var look = new MilPoint3F(0, 0, -1);
            var up = new MilPoint3F(0, 1, 0);
            var view = MilMatrix4x4F.Identity;
            var proj = new MilMatrix4x4F(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

            ch.Send(MilCommandEncoder.PerspectiveCamera(hPer, 0.125, 100.5, 45.0, pos, look, up, hTransform));
            ch.Send(MilCommandEncoder.OrthographicCamera(hOrtho, 0.25, 200.75, 10.0, pos, look, up, hTransform));
            ch.Send(MilCommandEncoder.MatrixCamera(hMat, view, proj, hTransform));

            var rp = MilResource3DTable.Lookup<MilPerspectiveCamera>(Own(ch, hPer));
            Assert.Equal(0.125, rp.NearPlaneDistance);
            Assert.Equal(100.5, rp.FarPlaneDistance);
            Assert.Equal(45.0, rp.FieldOfView);
            Assert.Equal(pos, rp.Position);
            Assert.Equal(look, rp.LookDirection);
            Assert.Equal(up, rp.UpDirection);
            Assert.Equal(hTransform, rp.HTransform);

            // 正交相机的第 4 个 double 位是 Width 而不是 FieldOfView——两个结构体
            // 前 96 字节布局同构，正是这里容易串位。
            var ro = MilResource3DTable.Lookup<MilOrthographicCamera>(Own(ch, hOrtho));
            Assert.Equal(0.25, ro.NearPlaneDistance);
            Assert.Equal(200.75, ro.FarPlaneDistance);
            Assert.Equal(10.0, ro.Width);

            var rm = MilResource3DTable.Lookup<MilMatrixCamera>(Own(ch, hMat));
            Assert.Equal(view, rm.ViewMatrix);
            Assert.Equal(proj, rm.ProjectionMatrix);
            Assert.Equal(hTransform, rm.HTransform);
        }

        [Fact]
        public void RoundTrip_3D光照()
        {
            var ch = new TestChannel();
            var hAmb = ch.Create(DUCE.ResourceType.TYPE_AMBIENTLIGHT);
            var hDir = ch.Create(DUCE.ResourceType.TYPE_DIRECTIONALLIGHT);
            var hPoint = ch.Create(DUCE.ResourceType.TYPE_POINTLIGHT);
            var hSpot = ch.Create(DUCE.ResourceType.TYPE_SPOTLIGHT);
            var white = new MilColorF(1, 1, 1, 1);
            var tinted = new MilColorF(0.25f, 0.5f, 0.75f, 0.875f);
            var dir = new MilPoint3F(-1, -1, -1);

            ch.Send(MilCommandEncoder.AmbientLight(hAmb, white));
            ch.Send(MilCommandEncoder.DirectionalLight(hDir, tinted, dir));
            ch.Send(MilCommandEncoder.PointLight(hPoint, tinted, 25.5, 1.0, 0.5, 0.25,
                new MilPoint3F(3, 4, 5)));
            ch.Send(MilCommandEncoder.SpotLight(hSpot, tinted, 30.25, 1.0, 0.5, 0.25,
                60.0, 20.0, new MilPoint3F(6, 7, 8), dir));

            Assert.Equal(white, MilResource3DTable.Lookup<MilAmbientLight>(Own(ch, hAmb)).Color);

            var rd = MilResource3DTable.Lookup<MilDirectionalLight>(Own(ch, hDir));
            Assert.Equal(tinted, rd.Color);
            Assert.Equal(dir, rd.Direction);

            var rpt = MilResource3DTable.Lookup<MilPointLight>(Own(ch, hPoint));
            Assert.Equal(tinted, rpt.Color);
            Assert.Equal(25.5, rpt.Range);
            Assert.Equal(1.0, rpt.ConstantAttenuation);
            Assert.Equal(0.5, rpt.LinearAttenuation);
            Assert.Equal(0.25, rpt.QuadraticAttenuation);
            Assert.Equal(new MilPoint3F(3, 4, 5), rpt.Position);

            var rs = MilResource3DTable.Lookup<MilSpotLight>(Own(ch, hSpot));
            Assert.Equal(tinted, rs.Color);
            Assert.Equal(30.25, rs.Range);
            Assert.Equal(60.0, rs.OuterConeAngle);
            Assert.Equal(20.0, rs.InnerConeAngle);
            Assert.Equal(new MilPoint3F(6, 7, 8), rs.Position);
            Assert.Equal(dir, rs.Direction);
        }

        [Fact]
        public void RoundTrip_3D模型与网格()
        {
            var ch = new TestChannel();
            var hGroup = ch.Create(DUCE.ResourceType.TYPE_MODEL3DGROUP);
            var hGeo = ch.Create(DUCE.ResourceType.TYPE_GEOMETRYMODEL3D);
            var hMesh = ch.Create(DUCE.ResourceType.TYPE_MESHGEOMETRY3D);
            var hTransform = ch.Create(DUCE.ResourceType.TYPE_TRANSFORM3DGROUP);
            var hMaterial = ch.Create(DUCE.ResourceType.TYPE_DIFFUSEMATERIAL);
            var hBack = ch.Create(DUCE.ResourceType.TYPE_SPECULARMATERIAL);

            var child1 = ch.Create(DUCE.ResourceType.TYPE_GEOMETRYMODEL3D);
            var child2 = ch.Create(DUCE.ResourceType.TYPE_GEOMETRYMODEL3D);

            ch.Send(MilCommandEncoder.Model3DGroup(hGroup, new[] { child1, child2 }, hTransform));
            ch.Send(MilCommandEncoder.GeometryModel3D(hGeo, hTransform, hMesh, hMaterial, hBack));
            ch.Send(MilCommandEncoder.MeshGeometry3D(hMesh,
                new[] { new MilPoint3F(0, 0, 0), new MilPoint3F(1, 1, 1) },
                new[] { new MilPoint3F(0, 1, 0) },
                new[] { new MilPoint(0.25, 0.75) },
                new[] { 0, 1, 2 }));

            var rg = MilResource3DTable.Lookup<MilModel3DGroup>(Own(ch, hGroup));
            Assert.Equal(hTransform, rg.HTransform);
            Assert.Equal(new[] { child1, child2 }, rg.Children);

            var rgeo = MilResource3DTable.Lookup<MilGeometryModel3D>(Own(ch, hGeo));
            Assert.Equal(hTransform, rgeo.HTransform);
            Assert.Equal(hMesh, rgeo.HGeometry);
            Assert.Equal(hMaterial, rgeo.HMaterial);
            Assert.Equal(hBack, rgeo.HBackMaterial);

            // 四段数组宽度不同（12/12/16/4），串段是这里的典型 bug
            var rm = MilResource3DTable.Lookup<MilMeshGeometry3D>(Own(ch, hMesh));
            Assert.Equal(2, rm.Positions.Count);
            Assert.Equal(new MilPoint3F(1, 1, 1), rm.Positions[1]);
            Assert.Single(rm.Normals);
            Assert.Equal(new MilPoint3F(0, 1, 0), rm.Normals[0]);
            Assert.Single(rm.TextureCoordinates);
            Assert.Equal(new MilPoint(0.25, 0.75), rm.TextureCoordinates[0]);
            Assert.Equal(new[] { 0, 1, 2 }, rm.TriangleIndices);
        }

        /// <summary>空网格是合法输入（ChildrenSize 四段全 0），不该抛。</summary>
        [Fact]
        public void MeshGeometry3D_空数组是合法输入()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_MESHGEOMETRY3D);

            ch.Send(MilCommandEncoder.MeshGeometry3D(h,
                Array.Empty<MilPoint3F>(), Array.Empty<MilPoint3F>(),
                Array.Empty<MilPoint>(), Array.Empty<int>()));

            var r = MilResource3DTable.Lookup<MilMeshGeometry3D>(Own(ch, h));
            Assert.Empty(r.Positions);
            Assert.Empty(r.Normals);
            Assert.Empty(r.TextureCoordinates);
            Assert.Empty(r.TriangleIndices);
        }

        [Fact]
        public void RoundTrip_3D材质()
        {
            var ch = new TestChannel();
            var hGroup = ch.Create(DUCE.ResourceType.TYPE_MATERIALGROUP);
            var hDiff = ch.Create(DUCE.ResourceType.TYPE_DIFFUSEMATERIAL);
            var hSpec = ch.Create(DUCE.ResourceType.TYPE_SPECULARMATERIAL);
            var hEmis = ch.Create(DUCE.ResourceType.TYPE_EMISSIVEMATERIAL);
            var hBrush = ch.Create(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);
            var m1 = ch.Create(DUCE.ResourceType.TYPE_DIFFUSEMATERIAL);
            var m2 = ch.Create(DUCE.ResourceType.TYPE_SPECULARMATERIAL);

            var color = new MilColorF(0.1f, 0.2f, 0.3f, 0.4f);
            var ambient = new MilColorF(0.5f, 0.6f, 0.7f, 0.8f);

            ch.Send(MilCommandEncoder.MaterialGroup(hGroup, new[] { m1, m2 }));
            ch.Send(MilCommandEncoder.DiffuseMaterial(hDiff, color, ambient, hBrush));
            ch.Send(MilCommandEncoder.SpecularMaterial(hSpec, color, 42.5, hBrush));
            ch.Send(MilCommandEncoder.EmissiveMaterial(hEmis, color, hBrush));

            Assert.Equal(new[] { m1, m2 }, MilResource3DTable.Lookup<MilMaterialGroup>(Own(ch, hGroup)).Children);

            var rd = MilResource3DTable.Lookup<MilDiffuseMaterial>(Own(ch, hDiff));
            Assert.Equal(color, rd.Color);
            Assert.Equal(ambient, rd.AmbientColor);
            Assert.Equal(hBrush, rd.HBrush);

            var rs = MilResource3DTable.Lookup<MilSpecularMaterial>(Own(ch, hSpec));
            Assert.Equal(color, rs.Color);
            Assert.Equal(42.5, rs.SpecularPower);
            Assert.Equal(hBrush, rs.HBrush);

            var re = MilResource3DTable.Lookup<MilEmissiveMaterial>(Own(ch, hEmis));
            Assert.Equal(color, re.Color);
            Assert.Equal(hBrush, re.HBrush);
        }

        [Fact]
        public void RoundTrip_3D变换()
        {
            var ch = new TestChannel();
            var hGroup = ch.Create(DUCE.ResourceType.TYPE_TRANSFORM3DGROUP);
            var hTrans = ch.Create(DUCE.ResourceType.TYPE_TRANSLATETRANSFORM3D);
            var hScale = ch.Create(DUCE.ResourceType.TYPE_SCALETRANSFORM3D);
            var hRot = ch.Create(DUCE.ResourceType.TYPE_ROTATETRANSFORM3D);
            var hMat = ch.Create(DUCE.ResourceType.TYPE_MATRIXTRANSFORM3D);
            var t1 = ch.Create(DUCE.ResourceType.TYPE_TRANSLATETRANSFORM3D);
            var t2 = ch.Create(DUCE.ResourceType.TYPE_SCALETRANSFORM3D);
            var hRot3D = ch.Create(DUCE.ResourceType.TYPE_AXISANGLEROTATION3D);
            var m = new MilMatrix4x4F(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);

            ch.Send(MilCommandEncoder.Transform3DGroup(hGroup, new[] { t1, t2 }));
            ch.Send(MilCommandEncoder.TranslateTransform3D(hTrans, 1.5, -2.5, 3.5));
            ch.Send(MilCommandEncoder.ScaleTransform3D(hScale, 2, 3, 4, 5, 6, 7));
            ch.Send(MilCommandEncoder.RotateTransform3D(hRot, 8, 9, 10, hRot3D));
            ch.Send(MilCommandEncoder.MatrixTransform3D(hMat, m));

            Assert.Equal(new[] { t1, t2 }, MilResource3DTable.Lookup<MilTransform3DGroup>(Own(ch, hGroup)).Children);

            var rt = MilResource3DTable.Lookup<MilTranslateTransform3D>(Own(ch, hTrans));
            Assert.Equal(1.5, rt.OffsetX);
            Assert.Equal(-2.5, rt.OffsetY);
            Assert.Equal(3.5, rt.OffsetZ);

            var rsc = MilResource3DTable.Lookup<MilScaleTransform3D>(Own(ch, hScale));
            Assert.Equal(2, rsc.ScaleX);
            Assert.Equal(3, rsc.ScaleY);
            Assert.Equal(4, rsc.ScaleZ);
            Assert.Equal(5, rsc.CenterX);
            Assert.Equal(6, rsc.CenterY);
            Assert.Equal(7, rsc.CenterZ);

            var rr = MilResource3DTable.Lookup<MilRotateTransform3D>(Own(ch, hRot));
            Assert.Equal(8, rr.CenterX);
            Assert.Equal(9, rr.CenterY);
            Assert.Equal(10, rr.CenterZ);
            Assert.Equal(hRot3D, rr.HRotation);

            Assert.Equal(m, MilResource3DTable.Lookup<MilMatrixTransform3D>(Own(ch, hMat)).Matrix);
        }

        // ============================================================
        //  0x57–0x6b · 边界
        // ============================================================

        [Fact]
        public void 资源3D_句柄为空返回EINVALARG()
        {
            var ch = new TestChannel();
            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(
                MilCommandEncoder.AmbientLight(DUCE.ResourceHandle.Null, new MilColorF(1, 1, 1, 1))));
        }

        [Fact]
        public void 资源3D_句柄不在表内返回EHANDLE()
        {
            var ch = new TestChannel();
            var ghost = new DUCE.ResourceHandle(0xBEEF);
            Assert.Equal(HResult.E_HANDLE, ch.Dispatch(
                MilCommandEncoder.AmbientLight(ghost, new MilColorF(1, 1, 1, 1))));
        }

        /// <summary>把 AmbientLight 的命令发给 PointLight 的资源：类型不符，必须 E_INVALIDARG。</summary>
        [Fact]
        public void 资源3D_资源类型不符返回EINVALARG()
        {
            var ch = new TestChannel();
            var hPoint = ch.Create(DUCE.ResourceType.TYPE_POINTLIGHT);

            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(
                MilCommandEncoder.AmbientLight(hPoint, new MilColorF(1, 1, 1, 1))));
        }

        /// <summary>变长命令尾部被截断：必须 E_INVALIDARG，不许读越界字节。</summary>
        [Fact]
        public void 资源3D_变长尾部截断返回EINVALARG()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_MODEL3DGROUP);
            var child = ch.Create(DUCE.ResourceType.TYPE_GEOMETRYMODEL3D);

            byte[] full = MilCommandEncoder.Model3DGroup(h, new[] { child });
            Assert.Equal(HResult.S_OK, ch.Dispatch(full));

            // 砍掉尾部 4 字节（一个句柄）：ChildrenSize 仍写着 4，但字节不够
            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(full[..(full.Length - 4)]));
        }

        /// <summary>ChildrenSize 不是 4 的倍数（句柄宽度 4），必须拒绝而不是读半截句柄。</summary>
        [Fact]
        public void 资源3D_ChildrenSize非4的倍数返回EINVALARG()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_MODEL3DGROUP);

            // 手工构造：16 字节头 + ChildrenSize=3（非 4 的倍数），尾部给足字节，
            // 这样如果解码器不校验对齐，它会读越界而不是返回 E_INVALIDARG。
            byte[] cmd = new byte[20];
            BitConverter.GetBytes((int)MilCmd.MilCmdModel3DGroup).CopyTo(cmd, 0);
            BitConverter.GetBytes((uint)h).CopyTo(cmd, 4);
            BitConverter.GetBytes(3u).CopyTo(cmd, 12);

            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(cmd));
        }
    }
}
