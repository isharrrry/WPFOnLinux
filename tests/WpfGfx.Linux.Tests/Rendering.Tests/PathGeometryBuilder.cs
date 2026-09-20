// 手工拼 PathGeometry 的序列化字节块。
//
// 布局与 Rendering/PathGeometryParser.cs 的读取约定逐字节对应（后者又是照上游
// wgx_core_types.cs 的 MIL_PATHGEOMETRY / MIL_PATHFIGURE / MIL_SEGMENT_* 抄的）：
//
//   MIL_PATHGEOMETRY  48B : Size@0 Flags@4 Bounds@8(32B) FigureCount@40 Pad@44
//   MIL_PATHFIGURE    40B : BackSize@0 Flags@4 Count@8 Size@12 StartPoint@16(16B)
//                           OffsetToLastSegment@32 Pad@36
//   段头              16B : Type@0 Flags@4 BackSize@8 (Arc 用 @12 放大弧标志)
//     Line            32B : + Point×1 @16
//     Bezier          64B : + Point×3 @16
//     QuadraticBezier 48B : + Point×2 @16
//     Arc             64B : LargeArc@12 Point@16 Size@32 XRotation@48 Sweep@56 Pad@60
//     Poly*      16+16n B : Count@12 Points@16
//
// 【这是测试的"另一端"】
//   解码器（T3）与解析器（T4）是同一套布局的两个读者。这里独立实现一遍**写**，
//   相当于给 Parse 加了一个反向交叉验证：如果两边对布局的理解有任何偏差，
//   path 用例的 golden 图立刻会不对。

using System;
using System.Collections.Generic;
using System.IO;
using WpfGfx.Linux.Interop;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal sealed class PathGeometryBuilder
    {
        private const int GeometryHeaderSize = 48;
        private const int FigureHeaderSize = 40;

        private readonly List<byte[]> _figures = new List<byte[]>();

        /// <summary>开一个新 Figure。返回 figure 构造器，Dispose/End 时封口。</summary>
        public Figure AddFigure(double startX, double startY, bool isClosed = false)
            => new Figure(this, startX, startY, isClosed);

        public byte[] Build()
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);

            // 占位：先写头，最后回填 Size 与 FigureCount
            w.Write(0u);                 // Size@0，稍后回填
            w.Write(0u);                 // Flags@4
            for (int i = 0; i < 4; i++) w.Write(0.0);   // Bounds@8..40
            w.Write((uint)_figures.Count);              // FigureCount@40
            w.Write(0u);                                // Pad@44

            foreach (byte[] f in _figures) w.Write(f);

            byte[] bytes = ms.ToArray();
            BitConverter.GetBytes((uint)bytes.Length).CopyTo(bytes, 0);
            return bytes;
        }

        internal void Commit(Figure figure) => _figures.Add(figure.ToBytes());

        internal sealed class Figure
        {
            private readonly PathGeometryBuilder _owner;
            private readonly double _sx, _sy;
            private readonly bool _closed;
            private readonly MemoryStream _body = new MemoryStream();
            private readonly BinaryWriter _w;
            private int _segmentCount;

            internal Figure(PathGeometryBuilder owner, double sx, double sy, bool closed)
            {
                _owner = owner;
                _sx = sx;
                _sy = sy;
                _closed = closed;
                _w = new BinaryWriter(_body);
            }

            public Figure Line(double x, double y) => Segment(MilSegmentType.Line, w =>
            {
                w.Write(0u);            // ForcePacking@12
                w.Write(x);
                w.Write(y);
            });

            public Figure Bezier(double c1x, double c1y, double c2x, double c2y, double x, double y)
                => Segment(MilSegmentType.Bezier, w =>
                {
                    w.Write(0u);
                    w.Write(c1x); w.Write(c1y);
                    w.Write(c2x); w.Write(c2y);
                    w.Write(x); w.Write(y);
                });

            public Figure Quadratic(double cx, double cy, double x, double y)
                => Segment(MilSegmentType.QuadraticBezier, w =>
                {
                    w.Write(0u);
                    w.Write(cx); w.Write(cy);
                    w.Write(x); w.Write(y);
                });

            public Figure Arc(double x, double y, double rx, double ry, double xRotation, bool largeArc, bool sweep)
                => Segment(MilSegmentType.Arc, w =>
                {
                    w.Write(largeArc ? 1u : 0u);    // @12
                    w.Write(x); w.Write(y);          // @16
                    w.Write(rx); w.Write(ry);        // @32
                    w.Write(xRotation);              // @48
                    w.Write(sweep ? 1u : 0u);        // @56
                    w.Write(0u);                     // @60 Pad
                });

            /// <summary>抬笔移动：SegIsAGap 段，只改变当前点不产生墨迹。</summary>
            public Figure MoveTo(double x, double y)
                => Segment(MilSegmentType.Line, w =>
                {
                    w.Write(0u);
                    w.Write(x);
                    w.Write(y);
                }, MilCoreSegFlags.SegIsAGap);

            public Figure Close()
                => Segment(MilSegmentType.None, _ => { }, MilCoreSegFlags.SegClosed);

            private Figure Segment(MilSegmentType type, Action<BinaryWriter> body, MilCoreSegFlags flags = 0)
            {
                _w.Write((uint)type);
                _w.Write((uint)flags);
                _w.Write(0u);           // BackSize@8（前向遍历用不到）
                body(_w);
                _segmentCount++;
                return this;
            }

            internal byte[] ToBytes()
            {
                _w.Flush();
                byte[] body = _body.ToArray();

                using var ms = new MemoryStream();
                using var w = new BinaryWriter(ms);
                w.Write(0u);                                    // BackSize@0
                w.Write(_closed ? (uint)MilPathFigureFlags.IsClosed : 0u);
                w.Write((uint)_segmentCount);                   // Count@8
                w.Write((uint)(FigureHeaderSize + body.Length)); // Size@12
                w.Write(_sx); w.Write(_sy);                      // StartPoint@16
                w.Write(0u);                                     // OffsetToLastSegment@32
                w.Write(0u);                                     // Pad@36
                w.Write(body);

                return ms.ToArray();
            }

            /// <summary>封口并把 figure 交回外层。</summary>
            public PathGeometryBuilder End()
            {
                _owner.Commit(this);
                return _owner;
            }
        }
    }
}
