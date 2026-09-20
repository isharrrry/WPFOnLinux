// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：Windows 侧 harness 入口。
//
//   u1geom.exe <cases.json> <windows-results.json> [dll 全路径] [abi]
//   u1geom.exe selfcheck [abi] [dll 全路径]
//
// abi ∈ flat | struct | ref（默认 struct）。三种形态必须各起一个进程试：
// 选错的那一次会直接把进程打崩（0xC0000005），在同进程里 try/catch 拦不住。
//
// 默认 dll 路径 = C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using WpfGfx.Linux.Parity.Geometry;

internal static class Program
{
    private const string DefaultDll =
        @"C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll";

    private static int Main(string[] args)
    {
        if (args.Length > 0 && args[0] == "selfcheck")
        {
            NativeGeometryRunner.ArcAbi abi = ParseAbi(args.Length > 1 ? args[1] : "struct");
            string dllPath = args.Length > 2 ? args[2] : DefaultDll;
            Console.WriteLine($"abi={abi} dll={dllPath}");
            string problem = NativeGeometryRunner.SelfCheck(dllPath, abi);
            if (problem == null)
            {
                Console.WriteLine("SELFCHECK_OK");
                return 0;
            }
            Console.WriteLine("SELFCHECK_FAIL: " + problem);
            return 1;
        }

        string casesPath = args.Length > 0 ? args[0] : "cases.json";
        string outPath = args.Length > 1 ? args[1] : "windows-results.json";
        string dll = args.Length > 2 ? args[2] : DefaultDll;
        NativeGeometryRunner.ArcAbi arcAbi = ParseAbi(args.Length > 3 ? args[3] : "struct");

        if (!File.Exists(casesPath))
        {
            Console.Error.WriteLine("找不到 cases.json: " + casesPath);
            return 2;
        }
        if (!File.Exists(dll))
        {
            Console.Error.WriteLine("找不到真身 DLL: " + dll);
            return 3;
        }

        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowNamedFloatingPointLiterals,
        };
        GeometryCaseFile file = JsonSerializer.Deserialize<GeometryCaseFile>(
            File.ReadAllText(casesPath), options);

        long dllSize = new FileInfo(dll).Length;
        Console.WriteLine($"真身 DLL : {dll} ({dllSize} 字节)");
        Console.WriteLine($"用例数   : {file.Cases.Count}");

        var runner = new NativeGeometryRunner(dll, arcAbi);
        Console.WriteLine($"ABI      : {runner.AbiNote}");
        Console.WriteLine($"OS       : {Environment.OSVersion} / .NET {Environment.Version} / 64bit={Environment.Is64BitProcess}");

        var results = new List<CaseResult>();
        foreach (GeometryCase c in file.Cases)
        {
            CaseResult r = runner.Run(c);
            results.Add(r);
            string flag = r.Error != null ? "ERR " : "ok  ";
            Console.WriteLine($"{flag}{c.Id}");
        }

        var payload = new JsonObject
        {
            ["schema"] = "wpfgfx-geometry-oracle-results/1",
            ["side"] = "windows-native",
            ["dllPath"] = dll,
            ["dllSizeBytes"] = dllSize,
            ["dllSha256"] = Sha256(dll),
            ["dotnetVersion"] = Environment.Version.ToString(),
            ["osVersion"] = Environment.OSVersion.ToString(),
            ["abiNote"] = runner.AbiNote,
            ["arcAbi"] = arcAbi.ToString(),
            ["missingExports"] = new JsonArray(ToNodes(runner.MissingExports)),
            ["results"] = JsonSerializer.SerializeToNode(results, options),
        };
        File.WriteAllText(outPath, payload.ToJsonString(options));
        Console.WriteLine("写出: " + Path.GetFullPath(outPath));
        return 0;
    }

    private static NativeGeometryRunner.ArcAbi ParseAbi(string text) => text switch
    {
        "flat" => NativeGeometryRunner.ArcAbi.Flat,
        "ref" => NativeGeometryRunner.ArcAbi.StructRef,
        _ => NativeGeometryRunner.ArcAbi.StructValue,
    };

    private static JsonNode[] ToNodes(List<string> items)
    {
        var nodes = new JsonNode[items.Count];
        for (int i = 0; i < items.Count; i++) nodes[i] = JsonValue.Create(items[i]);
        return nodes;
    }

    private static string Sha256(string path)
    {
        using var sha = System.Security.Cryptography.SHA256.Create();
        using FileStream fs = File.OpenRead(path);
        byte[] hash = sha.ComputeHash(fs);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
