using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace U1SystemFontsOracle
{
    /// <summary>
    /// Minimal ordered JSON writer (same shape as U1Parity's J.cs): the scene tree is
    /// built as plain objects and serialized directly, so the emitted spec can never
    /// drift from what was rendered.
    /// </summary>
    internal static class Json
    {
        public static string Serialize(object o)
        {
            var sb = new StringBuilder(1 << 18);
            Write(sb, o, 0);
            sb.Append('\n');
            return sb.ToString();
        }

        public static string Str(string s)
        {
            var sb = new StringBuilder(s.Length + 2);
            WriteStr(sb, s);
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
            if (o is float ff) { sb.Append(Num(ff)); return; }
            if (o is int ii) { sb.Append(ii.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is long ll) { sb.Append(ll.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is uint uu) { sb.Append(uu.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is byte by) { sb.Append(by.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is sbyte sb2) { sb.Append(sb2.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is short sh) { sb.Append(sh.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is ushort us) { sb.Append(us.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is ulong ul) { sb.Append(ul.ToString(CultureInfo.InvariantCulture)); return; }
            if (o is decimal de) { sb.Append(Num((double)de)); return; }
            if (o is Enum enm) { sb.Append(Convert.ToInt64(enm, CultureInfo.InvariantCulture).ToString(CultureInfo.InvariantCulture)); return; }
            if (o is Uri uri) { WriteStr(sb, uri.ToString()); return; }
            if (o is CultureInfo ci) { WriteStr(sb, ci.Name); return; }
            if (o is DateTime dt) { WriteStr(sb, dt.ToString("o", CultureInfo.InvariantCulture)); return; }

            if (o is JObj map)
            {
                if (map.Count == 0) { sb.Append("{}"); return; }
                sb.Append("{\n");
                bool first = true;
                foreach (KeyValuePair<string, object> kv in map.Items)
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

            if (o is IEnumerable en)
            {
                var items = new List<object>();
                foreach (object it in en) items.Add(it);
                if (items.Count == 0) { sb.Append("[]"); return; }

                bool allScalar = true;
                foreach (object it in items)
                    if (!(it == null || it is string || it is bool || it is double || it is int || it is long || it is float))
                    { allScalar = false; break; }

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

            throw new Exception("Json.Write: unsupported type " + o.GetType().FullName);
        }
    }

    /// <summary>Ordered JSON object.</summary>
    internal sealed class JObj
    {
        public readonly List<KeyValuePair<string, object>> Items = new List<KeyValuePair<string, object>>();

        public int Count => Items.Count;

        public JObj Add(string key, object value)
        {
            Items.Add(new KeyValuePair<string, object>(key, value));
            return this;
        }
    }

    internal static class J
    {
        public static JObj O() => new JObj();

        public static List<object> L(params object[] items) => new List<object>(items);
    }
}
