// B2/B3/B4 oracle · 反射驱动的通用 dump
//
// 【为什么要反射】主控明确说过："不要只 dump 你猜有用的那几个属性 —— 我现在还不知道
// TextLineBreak 有哪些消费者，你的 dump 就是发现它的手段。"
// 所以这里对**每个输出对象**都遍历它的全部公开属性，而不是硬编码字段清单；
// 属性表本身也 dump 成 api-surface.json 存档（见 Probe）。

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using System.Text.Json.Nodes;

namespace WpfOracleLayout
{
    internal static class Dumper
    {
        private const int MaxDepth = 3;
        private static readonly HashSet<Type> LeafTypes = new HashSet<Type>
        {
            typeof(string), typeof(bool), typeof(char), typeof(byte), typeof(sbyte),
            typeof(short), typeof(ushort), typeof(int), typeof(uint),
            typeof(long), typeof(ulong), typeof(float), typeof(double), typeof(decimal),
        };

        /// <summary>遍历公开属性；索引器与已知会抛的属性跳过（记录原因，不静默吞）。</summary>
        public static JsonObject Props(object o, int depth = 0)
        {
            var result = new JsonObject();
            if (o == null) return result;

            foreach (PropertyInfo p in o.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance))
            {
                if (p.GetIndexParameters().Length > 0) continue;
                if (!p.CanRead) continue;

                string name = p.Name;
                try
                {
                    object v = p.GetValue(o);
                    result[name] = Value(v, depth);
                }
                catch (Exception e)
                {
                    result[name] = "THROW:" + e.GetType().Name + ":" + Short(e.Message);
                }
            }
            return result;
        }

        /// <summary>把任意值转成 JSON（受控深度；不可序列化的类型退化成 ToString）。</summary>
        public static JsonNode Value(object v, int depth = 0)
        {
            if (v == null) return null;
            Type t = v.GetType();

            if (v is string s) return JsonValue.Create(s);
            if (v is bool b) return JsonValue.Create(b);
            if (v is char c) return JsonValue.Create((int)c)?.AsValue();
            if (LeafTypes.Contains(t))
            {
                try { return JsonValue.Create(Convert.ToDouble(v, CultureInfo.InvariantCulture)); }
                catch { return JsonValue.Create(v.ToString()); }
            }
            if (t.IsEnum) return JsonValue.Create(v.ToString());

            // 结构体/对象：深度够就展开属性，否则 ToString
            if (depth >= MaxDepth) return JsonValue.Create(v.ToString());

            if (v is IEnumerable en && !(v is string))
            {
                var arr = new JsonArray();
                int n = 0;
                foreach (object item in en)
                {
                    if (n++ >= 64) { arr.Add("…more"); break; }
                    arr.Add(item == null ? null : Value(item, depth + 1));
                }
                return arr;
            }

            // WPF 的 Point/Rect/Thickness 这类结构体展开属性很好看
            JsonObject po = Props(v, depth + 1);
            if (po.Count > 0) return po;
            return JsonValue.Create(v.ToString());
        }

        /// <summary>只 dump 有名的几个标量属性（用在批量处，避免 JSON 爆炸）。</summary>
        public static JsonObject Pick(object o, params string[] names)
        {
            var r = new JsonObject();
            if (o == null) return r;
            Type t = o.GetType();
            foreach (string n in names)
            {
                PropertyInfo p = t.GetProperty(n, BindingFlags.Public | BindingFlags.Instance);
                if (p == null) { r[n] = "ABSENT"; continue; }
                try { r[n] = Value(p.GetValue(o)); }
                catch (Exception e) { r[n] = "THROW:" + e.GetType().Name; }
            }
            return r;
        }

        /// <summary>方法是否存在（用于"该重载到底有没有"这类负结论）。</summary>
        public static JsonObject MethodExists(Type t, string name, int paramCount)
        {
            bool found = false;
            string sig = null;
            foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static))
            {
                if (m.Name != name) continue;
                if (paramCount >= 0 && m.GetParameters().Length != paramCount) continue;
                found = true;
                sig = m.ToString();
                break;
            }
            return new JsonObject { ["name"] = name, ["paramCount"] = paramCount, ["exists"] = found, ["signature"] = sig };
        }

        private static string Short(string s) => s == null ? "" : (s.Length > 120 ? s.Substring(0, 120) + "…" : s);
    }
}
