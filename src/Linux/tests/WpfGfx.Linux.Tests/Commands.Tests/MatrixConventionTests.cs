// Licensed to the .NET Foundation under one or more agreements.
//
// 锁死 MilMatrix3x2D → SKMatrix 的行/列约定（TransformResolver.FromMil）。
//
// 背景：FromMil 曾把 M12 / M21 转置了（写成 SkewX = S_12, SkewY = S_21）。
// 因为**对称矩阵（M12 == M21）在两种写法下结果完全相同**，此前所有用例都恰好
// 是对称矩阵，bug 一直没暴露；直到出现非对称矩阵 (M11=2, M12=0, M21=1.5, M22=1)
// 才炸出来。本文件把"对称看不出差别 / 非对称必须分行列"这件事显式固化。
//
// 约定（上游 PresentationCore/System/Windows/Media/Composition.cs 的
// TransformToMilMatrix3x2D / MilMatrix3x2DToMatrix 为证，字段直接对应不交换）：
//   S_11 = WPF M11, S_12 = WPF M12, S_21 = WPF M21, S_22 = WPF M22
//
//   WPF（行向量 p' = p·M）:  x' = M11·x + M21·y + DX
//                            y' = M12·x + M22·y + DY
//   Skia（列向量 p' = M·p）:  x' = ScaleX·x + SkewX·y + TransX
//                            y' = SkewY·x  + ScaleY·y + TransY
//   ⇒ ScaleX=M11, SkewX=M21, SkewY=M12, ScaleY=M22   （M12/M21 交叉映射）

using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    public class MatrixConventionTests
    {
        // ==================================================================
        //  1. 非对称矩阵：两种写法必须分得开，且必须落在 WPF 语义上
        // ==================================================================

        [Fact]
        public void FromMil_asymmetric_matrix_follows_wpf_row_vector_convention()
        {
            // (M11=2, M12=0, M21=1.5, M22=1)，变换点 (2,3)：
            //   WPF:  x' = 2·2 + 1.5·3 = 8.5 , y' = 0·2 + 1·3 = 3
            //   转置:  x' = 2·2 + 0·3   = 4   , y' = 1.5·2 + 1·3 = 6
            SKMatrix m = FromMil(m11: 2.0, m12: 0.0, m21: 1.5, m22: 1.0, dx: 0, dy: 0);

            SKPoint p = m.MapPoint(2, 3);
            Assert.Equal(8.5f, p.X, 3);
            Assert.Equal(3.0f, p.Y, 3);
        }

        [Fact]
        public void FromMil_maps_M12_and_M21_crosswise_onto_skia_skew()
        {
            // 直接钉字段映射，不经过点变换：Skia 的 SkewX 吃的是 M21，SkewY 吃的是 M12。
            SKMatrix m = FromMil(m11: 2.0, m12: 0.0, m21: 1.5, m22: 1.0, dx: 7, dy: -4);

            Assert.Equal(2.0f, m.ScaleX, 5);   // M11
            Assert.Equal(1.5f, m.SkewX, 5);    // M21（不是 M12）
            Assert.Equal(0.0f, m.SkewY, 5);    // M12（不是 M21）
            Assert.Equal(1.0f, m.ScaleY, 5);   // M22
            Assert.Equal(7.0f, m.TransX, 5);   // DX
            Assert.Equal(-4.0f, m.TransY, 5);  // DY
        }

        [Fact]
        public void FromMil_asymmetric_result_differs_from_transposed_writing()
        {
            // 显式对照：非对称矩阵下"正确写法"与"转置写法"的结果必须不同，
            // 且实际结果等于正确写法。防止有人把断言硬编码成一个碰巧的数字。
            const double m11 = 2.0, m12 = 0.0, m21 = 1.5, m22 = 1.0;
            const double dx = 3.0, dy = -2.0;

            SKPoint actual = FromMil(m11, m12, m21, m22, dx, dy).MapPoint(5, 7);
            (float wx, float wy) = Wpf(m11, m12, m21, m22, dx, dy, 5, 7);
            (float tx, float ty) = Transposed(m11, m12, m21, m22, dx, dy, 5, 7);

            Assert.NotEqual((wx, wy), (tx, ty));   // 这个用例确实能区分两种写法
            Assert.Equal(wx, actual.X, 3);
            Assert.Equal(wy, actual.Y, 3);
        }

        // ==================================================================
        //  2. 对称矩阵：两种写法结果相同 —— bug 当年就是在这里隐身的
        // ==================================================================

        [Fact]
        public void FromMil_symmetric_matrix_cannot_distinguish_the_two_writings()
        {
            // M12 == M21 == 1.5：转置前后是同一个矩阵，所以结果必然一致。
            // 这条测试说明"为什么老测试全绿"，它不检验 FromMil 的行列约定。
            const double m11 = 2.0, m12 = 1.5, m21 = 1.5, m22 = 1.0;
            const double dx = 0.0, dy = 0.0;

            SKPoint actual = FromMil(m11, m12, m21, m22, dx, dy).MapPoint(2, 3);
            (float wx, float wy) = Wpf(m11, m12, m21, m22, dx, dy, 2, 3);
            (float tx, float ty) = Transposed(m11, m12, m21, m22, dx, dy, 2, 3);

            Assert.Equal((wx, wy), (tx, ty));     // 对称 ⇒ 区分不出来
            Assert.Equal(wx, actual.X, 3);
            Assert.Equal(wy, actual.Y, 3);
        }

        // ==================================================================
        //  3. 与已独立验证的 Rotation 交叉校验
        // ==================================================================

        [Theory]
        [InlineData(30)]
        [InlineData(90)]
        public void FromMil_rotation_matrix_matches_direct_rotation_helper(double degrees)
        {
            // WPF 绕原点旋转 θ（y 轴向下、顺时针为正）的矩阵：
            //   M11=cosθ, M12=sinθ, M21=-sinθ, M22=cosθ
            // 这是**非对称**的，两种写法互为逆旋转，是极好的判别用例：
            // 转置写法会把 θ 转成 -θ。
            double rad = degrees * System.Math.PI / 180.0;
            double cos = System.Math.Cos(rad), sin = System.Math.Sin(rad);

            SKMatrix viaMatrix = FromMil(cos, sin, -sin, cos, 0, 0);
            SKMatrix viaHelper = TransformResolver.Rotation((float)degrees);

            SKPoint a = viaMatrix.MapPoint(10, 4);
            SKPoint b = viaHelper.MapPoint(10, 4);
            Assert.Equal(b.X, a.X, 3);
            Assert.Equal(b.Y, a.Y, 3);
        }

        // ==================================================================
        //  4. 走真实命令路径 MilCmdMatrixTransform (0x77)
        // ==================================================================

        [Fact]
        public void Matrix_transform_command_0x77_resolves_to_wpf_semantics()
        {
            // encoder → dispatcher → 资源表 → TransformResolver，全链路断言，
            // 确保 0x77 这条路径上没有第二处转置。
            var ch = new TestChannel();
            MilMatrixTransform res = ch.Create<MilMatrixTransform>(
                DUCE.ResourceType.TYPE_MATRIXTRANSFORM, out DUCE.ResourceHandle h);

            var mil = new MilMatrix3x2D(2.0, 0.0, 1.5, 1.0, 0.0, 0.0);
            ch.Send(MilCommandEncoder.MatrixTransform(h, mil));

            // 先确认命令层是原样搬运（字节级），没有偷偷重排字段。
            Assert.True(mil.Equals(res.Matrix), "0x77 命令层应原样搬运矩阵，不得重排字段");

            SKPoint p = TransformResolver.Resolve(ch.Channel, h).MapPoint(2, 3);
            Assert.Equal(8.5f, p.X, 3);
            Assert.Equal(3.0f, p.Y, 3);
        }

        [Fact]
        public void MilMatrix3x2D_field_order_matches_wpf_matrix_fields()
        {
            // 钉住 MilMatrix3x2D 自身的字段顺序：s11,s12,s21,s22,dx,dy 与
            // WPF Matrix(M11,M12,M21,M22,OffsetX,OffsetY) 一一对应、不交换。
            var m = new MilMatrix3x2D(11, 12, 21, 22, 5, 6);
            Assert.Equal(11.0, m.S_11);
            Assert.Equal(12.0, m.S_12);
            Assert.Equal(21.0, m.S_21);
            Assert.Equal(22.0, m.S_22);
            Assert.Equal(5.0, m.DX);
            Assert.Equal(6.0, m.DY);
        }

        // ==================================================================
        //  辅助
        // ==================================================================

        private static SKMatrix FromMil(
            double m11, double m12, double m21, double m22, double dx, double dy)
            => TransformResolver.FromMil(new MilMatrix3x2D(m11, m12, m21, m22, dx, dy));

        /// <summary>WPF 语义（正确写法）：x' = M11·x + M21·y + DX，y' = M12·x + M22·y + DY。</summary>
        private static (float X, float Y) Wpf(
            double m11, double m12, double m21, double m22, double dx, double dy, float x, float y)
            => ((float)(m11 * x + m21 * y + dx), (float)(m12 * x + m22 * y + dy));

        /// <summary>转置写法（曾经的 bug 行为）：把 M12/M21 同名直连到 SkewX/SkewY。</summary>
        private static (float X, float Y) Transposed(
            double m11, double m12, double m21, double m22, double dx, double dy, float x, float y)
            => ((float)(m11 * x + m12 * y + dx), (float)(m21 * x + m22 * y + dy));
    }
}
