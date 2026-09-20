using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace U1Parity
{
    /// <summary>
    /// Minimal ordered JSON object model + writer.
    /// The scene description is built as Dictionary&lt;string,object&gt; / List&lt;object&gt; trees and
    /// the SAME tree is fed to the renderer, so scenes.json can never drift from what was drawn.
    /// </summary>
    public static class J
    {
        public static Dictionary<string, object> O(params object[] kv)
        {
            var d = new Dictionary<string, object>();
            for (int i = 0; i < kv.Length; i += 2) d[(string)kv[i]] = kv[i + 1];
            return d;
        }

        public static List<object> L(params object[] items) => new List<object>(items);

        public static double N(object o) => Convert.ToDouble(o, CultureInfo.InvariantCulture);

        public static double D(Dictionary<string, object> m, string k) => N(m[k]);

        public static string S(Dictionary<string, object> m, string k) => (string)m[k];

        public static bool Has(Dictionary<string, object> m, string k)
        {
            object v;
            return m.TryGetValue(k, out v) && v != null;
        }

        public static string Serialize(object o)
        {
            var sb = new StringBuilder(1 << 16);
            Write(sb, o, 0);
            sb.Append('\n');
            return sb.ToString();
        }

        private static string Num(double d)
        {
            if (double.IsNaN(d) || double.IsInfinity(d)) return "null";
            if (d == Math.Floor(d) && Math.Abs(d) < 1e15) return ((long)d).ToString(CultureInfo.InvariantCulture);
            return d.ToString("R", CultureInfo.InvariantCulture);
        }

        private static void WriteStr(StringBuilder sb, string s)
        {
            sb.Append('"');
            foreach (char ch in s)
            {
                if (ch == '"' || ch == '\\') { sb.Append('\\').Append(ch); }
                else if (ch == '\n') sb.Append("\\n");
                else if (ch == '\r') sb.Append("\\r");
                else if (ch == '\t') sb.Append("\\t");
                else if (ch < 0x20) sb.Append("\\u").Append(((int)ch).ToString("x4", CultureInfo.InvariantCulture));
                else sb.Append(ch);
            }
            sb.Append('"');
        }

        private static void Write(StringBuilder sb, object o, int ind)
        {
            if (o == null) { sb.Append("null"); return; }
            if (o is string s) { WriteStr(sb, s); return; }
            if (o is bool b) { sb.Append(b ? "true" : "false"); return; }
            if (o is double dd) { sb.Append(Num(dd)); return; }
            if (o is int ii) { sb.Append(ii.ToString(CultureInfo.InvariantCulture)); return; }

            var map = o as Dictionary<string, object>;
            if (map != null)
            {
                if (map.Count == 0) { sb.Append("{}"); return; }
                sb.Append("{\n");
                bool first = true;
                foreach (var kv in map)
                {
                    if (!first) sb.Append(",\n");
                    first = false;
                    sb.Append(new string(' ', ind + 2));
                    WriteStr(sb, kv.Key);
                    sb.Append(": ");
                    Write(sb, kv.Value, ind + 2);
                }
                sb.Append('\n').Append(new string(' ', ind)).Append('}');
                return;
            }

            var en = o as IEnumerable;
            if (en != null)
            {
                var items = new List<object>();
                foreach (var it in en) items.Add(it);
                if (items.Count == 0) { sb.Append("[]"); return; }
                bool allScalar = true;
                foreach (var it in items)
                    if (!(it == null || it is string || it is bool || it is double || it is int)) { allScalar = false; break; }
                if (allScalar)
                {
                    sb.Append('[');
                    for (int k = 0; k < items.Count; k++)
                    {
                        if (k > 0) sb.Append(", ");
                        Write(sb, items[k], 0);
                    }
                    sb.Append(']');
                    return;
                }
                sb.Append("[\n");
                for (int k = 0; k < items.Count; k++)
                {
                    if (k > 0) sb.Append(",\n");
                    sb.Append(new string(' ', ind + 2));
                    Write(sb, items[k], ind + 2);
                }
                sb.Append('\n').Append(new string(' ', ind)).Append(']');
                return;
            }

            throw new Exception("J.Write: unsupported type " + o.GetType().FullName);
        }
    }
}
