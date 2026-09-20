T1/M7c2 —— 纯 C 探针：完全不经过 .NET，用 dlopen/dlsym 调 wpfgfx_cor3.so 的导出。

用法：
  gcc -O1 -o /tmp/mb-cprobe/probe build/MilBridge/tools/cprobe/probe.c -ldl
  LD_LIBRARY_PATH=<publish 目录> /tmp/mb-cprobe/probe \
      <publish 目录>/wpfgfx_cor3.so <repo>/build/fonts/NotoSans-Regular.ttf

⚠️ LD_LIBRARY_PATH 必须带：libSkiaSharp.so 不是 .so 的 DT_NEEDED（SkiaSharp 走
   运行时 dlopen），而纯 C 宿主不会调 MilBridge_SetNativeDir，AOT 镜像就不知道
   自己的目录。不带时所有调用返回 0（不是"符号没导出"）。
   托管路径不受影响 —— MilCoreDllImportResolver 会注入目录。

原始输出留档：build/MilBridge/gen/cprobe-output.txt
