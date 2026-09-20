// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：几何 oracle 对拍驱动（Linux 侧）。
//
//   dotnet run --project tools/GeometryOracle -- generate <cases.json>
//   dotnet run --project tools/GeometryOracle -- run      <cases.json> <linux-results.json>
//   dotnet run --project tools/GeometryOracle -- compare  <cases.json> <win.json> <lin.json> <summary.json> [report.md]
//   dotnet run --project tools/GeometryOracle -- one      <cases.json> <id>      # 单例调试（打两侧摘要）

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace WpfGfx.Linux.Parity.Geometry
{
    internal static class Program
    {
        private static readonly JsonSerializerOptions Options = new JsonSerializerOptions
        {
            WriteIndented = true,
            // 用例里故意带 NaN / ±INF（上游确实会产出这些值），必须允许命名浮点字面量。
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowNamedFloatingPointLiterals,
            // CaseComparison 用的是 public 字段而不是属性，不开这个就只会序列化出 IsMatch。
            IncludeFields = true,
        };

        private static int Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.Error.WriteLine("用法: generate|run|compare|one ...");
                return 2;
            }

            switch (args[0])
            {
                case "generate": return Generate(args);
                case "run": return Run(args);
                case "compare": return Compare(args);
                case "one": return One(args);
                default:
                    Console.Error.WriteLine("未知命令: " + args[0]);
                    return 2;
            }
        }

        private static GeometryCaseFile LoadCases(string path) =>
            JsonSerializer.Deserialize<GeometryCaseFile>(File.ReadAllText(path), Options);

        private static List<CaseResult> LoadResults(string path)
        {
            JsonNode root = JsonNode.Parse(File.ReadAllText(path));
            return JsonSerializer.Deserialize<List<CaseResult>>(root["results"].ToJsonString(), Options);
        }

        private static int Generate(string[] args)
        {
            string outPath = args.Length > 1 ? args[1] : "cases.json";
            var file = new GeometryCaseFile
            {
                Description =
                    "U1c 几何 oracle 输入集：Linux 侧实现 vs Windows 真身 wpfgfx_cor3.dll 的 MilUtility_* 导出。" +
                    "所有几何输入都是独立手搓的 MIL_PATHGEOMETRY 十六进制字节块（不经我方序列化器）。",
                Cases = CaseCatalog.Build(),
            };
            File.WriteAllText(outPath, JsonSerializer.Serialize(file, Options));
            Console.WriteLine($"写出 {outPath}：{file.Cases.Count} 个用例");
            foreach (var g in file.Cases.GroupBy(c => c.Fn).OrderBy(g => g.Key))
                Console.WriteLine($"  {g.Key,-46} {g.Count(),3}");
            return 0;
        }

        private static int Run(string[] args)
        {
            if (args.Length < 3) { Console.Error.WriteLine("run <cases.json> <linux-results.json>"); return 2; }
            GeometryCaseFile file = LoadCases(args[1]);
            var runner = new LinuxGeometryRunner();
            var results = new List<CaseResult>();
            foreach (GeometryCase c in file.Cases)
            {
                CaseResult r = runner.Run(c);
                results.Add(r);
                if (r.Error != null) Console.WriteLine("ERR " + c.Id + " :: " + r.Error);
            }

            var payload = new JsonObject
            {
                ["schema"] = "wpfgfx-geometry-oracle-results/1",
                ["side"] = "linux-managed",
                ["dotnetVersion"] = Environment.Version.ToString(),
                ["results"] = JsonSerializer.SerializeToNode(results, Options),
            };
            File.WriteAllText(args[2], payload.ToJsonString(Options));
            Console.WriteLine($"写出 {args[2]}：{results.Count} 个结果，异常 {results.Count(r => r.Error != null)} 个");
            return 0;
        }

        private static int One(string[] args)
        {
            if (args.Length < 3) { Console.Error.WriteLine("one <cases.json> <id>"); return 2; }
            GeometryCaseFile file = LoadCases(args[1]);
            GeometryCase c = file.Cases.FirstOrDefault(x => x.Id == args[2]);
            if (c == null) { Console.Error.WriteLine("没有这个 case: " + args[2]); return 2; }
            CaseResult r = new LinuxGeometryRunner().Run(c);
            Console.WriteLine("win? (需要 windows-results.json 才能看)");
            Console.WriteLine("linux: " + ResultComparer.Summarize(r));
            return 0;
        }

        private static int Compare(string[] args)
        {
            if (args.Length < 5)
            {
                Console.Error.WriteLine("compare <cases.json> <win.json> <lin.json> <summary.json> [report.md]");
                return 2;
            }

            GeometryCaseFile cases = LoadCases(args[1]);
            var byId = cases.Cases.ToDictionary(c => c.Id, c => c);
            List<CaseResult> win = LoadResults(args[2]);
            List<CaseResult> lin = LoadResults(args[3]);
            var winById = win.ToDictionary(r => r.Id, r => r);
            var linById = lin.ToDictionary(r => r.Id, r => r);

            var comparisons = new List<CaseComparison>();
            foreach (GeometryCase c in cases.Cases)
            {
                winById.TryGetValue(c.Id, out CaseResult w);
                linById.TryGetValue(c.Id, out CaseResult l);
                comparisons.Add(ResultComparer.Compare(w, l, byId[c.Id]));
            }

            var summary = new JsonObject
            {
                ["schema"] = "wpfgfx-geometry-oracle-summary/1",
                ["windowsSide"] = JsonNode.Parse(File.ReadAllText(args[2]))["abiNote"]?.DeepClone(),
                ["counts"] = new JsonObject
                {
                    ["total"] = comparisons.Count,
                    ["identical"] = comparisons.Count(x => x.Verdict == Verdict.Identical),
                    ["close"] = comparisons.Count(x => x.Verdict == Verdict.Close),
                    ["reordered"] = comparisons.Count(x => x.Verdict == Verdict.Reordered),
                    ["deviation"] = comparisons.Count(x => x.Verdict == Verdict.Deviation),
                    ["structural"] = comparisons.Count(x => x.Verdict == Verdict.Structural),
                },
                ["byFunction"] = BuildByFunction(comparisons),
                ["cases"] = JsonSerializer.SerializeToNode(comparisons, Options),
            };
            File.WriteAllText(args[4], summary.ToJsonString(Options));

            Console.WriteLine($"对拍 {comparisons.Count} 例：" +
                $"identical={summary["counts"]["identical"]} close={summary["counts"]["close"]} " +
                $"reordered={summary["counts"]["reordered"]} deviation={summary["counts"]["deviation"]} " +
                $"structural={summary["counts"]["structural"]}");

            foreach (CaseComparison x in comparisons.Where(x => !x.IsMatch))
            {
                Console.WriteLine($"  [{x.Verdict}] {x.Id} ({x.Fn})");
                Console.WriteLine($"      {x.Why}");
            }

            if (args.Length > 5)
            {
                File.WriteAllText(args[5], BuildMarkdown(comparisons, summary), Encoding.UTF8);
                Console.WriteLine("写出 " + args[5]);
            }
            return 0;
        }

        private static JsonObject BuildByFunction(List<CaseComparison> comparisons)
        {
            var o = new JsonObject();
            foreach (var g in comparisons.GroupBy(c => c.Fn).OrderBy(g => g.Key, StringComparer.Ordinal))
            {
                o[g.Key] = new JsonObject
                {
                    ["total"] = g.Count(),
                    ["identical"] = g.Count(x => x.Verdict == Verdict.Identical),
                    ["close"] = g.Count(x => x.Verdict == Verdict.Close),
                    ["reordered"] = g.Count(x => x.Verdict == Verdict.Reordered),
                    ["deviation"] = g.Count(x => x.Verdict == Verdict.Deviation),
                    ["structural"] = g.Count(x => x.Verdict == Verdict.Structural),
                };
            }
            return o;
        }

        private static string BuildMarkdown(List<CaseComparison> comparisons, JsonObject summary)
        {
            var sb = new StringBuilder();
            sb.AppendLine("# U1c 几何 oracle 对拍摘要（自动生成）");
            sb.AppendLine();
            sb.AppendLine($"- 用例总数：{comparisons.Count}");
            sb.AppendLine($"- 逐位相同：{summary["counts"]["identical"]}");
            sb.AppendLine($"- 浮点容差内相同：{summary["counts"]["close"]}");
            sb.AppendLine($"- 几何等价但发射顺序不同：{summary["counts"]["reordered"]}");
            sb.AppendLine($"- 我方偏差：{summary["counts"]["deviation"]}");
            sb.AppendLine($"- 结构性不一致（HRESULT / 键集合 / 异常）：{summary["counts"]["structural"]}");
            sb.AppendLine();
            sb.AppendLine("## 逐函数");
            sb.AppendLine();
            sb.AppendLine("| 函数 | 用例 | 逐位 | 容差内 | 顺序 | 偏差 | 结构 |");
            sb.AppendLine("|---|---|---|---|---|---|---|");
            foreach (var g in comparisons.GroupBy(c => c.Fn).OrderBy(g => g.Key, StringComparer.Ordinal))
            {
                sb.AppendLine($"| `{g.Key}` | {g.Count()} | {g.Count(x => x.Verdict == Verdict.Identical)} | " +
                    $"{g.Count(x => x.Verdict == Verdict.Close)} | {g.Count(x => x.Verdict == Verdict.Reordered)} | " +
                    $"{g.Count(x => x.Verdict == Verdict.Deviation)} | {g.Count(x => x.Verdict == Verdict.Structural)} |");
            }
            sb.AppendLine();
            sb.AppendLine("## 非一致明细");
            sb.AppendLine();
            foreach (CaseComparison x in comparisons.Where(x => !x.IsMatch))
            {
                sb.AppendLine($"### `{x.Id}` — {x.Verdict}");
                sb.AppendLine();
                if (!string.IsNullOrEmpty(x.Note)) sb.AppendLine($"- 意图：{x.Note}");
                sb.AppendLine($"- 结论：{x.Why}");
                sb.AppendLine($"- Windows：`{x.WindowsSummary}`");
                sb.AppendLine($"- Linux　：`{x.LinuxSummary}`");
                if (x.Details.Count > 0)
                {
                    sb.AppendLine("- 差异明细：");
                    foreach (string d in x.Details.Take(12)) sb.AppendLine($"  - `{d}`");
                }
                sb.AppendLine();
            }
            return sb.ToString();
        }
    }
}
