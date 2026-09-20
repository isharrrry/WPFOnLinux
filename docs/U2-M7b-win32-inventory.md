# M7b · Win32 API 需求清单（从实际编译集合机械提取）

> 本文件由 `src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py` **生成**，
> 不要手改。重跑：
> ```bash
> src/WpfGfx.Linux.Native/build-shim.sh --symbols      # 先产出 bin/exports.txt
> python3 src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py
> ```

## 0. 口径（为什么数字和 U2 扫描报告不同）

| 维度 | 本清单 | docs/U2-PresentationCore-scan.md §2.2 |
|---|---|---|
| 来源 | 两个 csproj 的 `<Compile Include>` 列表（**真的会编进程序集**） | 源码树里出现过 `[DllImport]` 的文件 |
| DLL 名 | 解引用 `ExternDll.*` / `DllImport.*` 常量表 + `WCP_VERSION_SUFFIX=_cor3` | 同上，但只覆盖 PresentationCore |
| 范围 | WindowsBase ∪ PresentationCore | PresentationCore |

统计（**属性条数**，同一函数在多文件声明会重复计）：WindowsBase **386**、
PresentationCore **339**，合计 **725** 条。
按 `(DLL, 名, 签名)` 去重后 **697** 条 —— 下面所有分类都按去重口径。

## 1. 总览

| 档 | 含义 | 条数 | 已由 libwpfwin32.so 实现 |
|---|---|---|---|
| **P0** | 消息泵 + 窗口生命周期（不做就跑不起来） | **83** | **83** |
| **P1** | 能无副作用实现 / 静默降级（不做多数不致命） | **195** | **122** |
| **P2** | 明确不做（各有替代路线或本工程不需要） | **419** | 0 |
| 合计 | | **697** | |

### 1.1 按 DLL 分布（去重口径）

| DLL | 去重条数 | 属性条数 | 档 |
|---|---|---|---|
| `user32.dll` | 139 | 140 | P0/P1 |
| `wpfgfx_cor3.dll` | 110 | 110 | P2 |
| `WindowsCodecs.dll` | 109 | 109 | P2 |
| `PresentationNative_cor3.dll` | 85 | 109 | P0/P1 |
| `msdrm.dll` | 49 | 49 | P2 |
| `kernel32.dll` | 35 | 37 | P0/P1 |
| `gdi32.dll` | 19 | 20 | P0/P1 |
| `imm32.dll` | 18 | 18 | P2 |
| `PenIMC_cor3.dll` | 16 | 16 | P2 |
| `PresentationHost_cor3.dll` | 14 | 14 | P2 |
| `mshwgst.dll` | 14 | 14 | P2 |
| `ole32.dll` | 13 | 13 | P2 |
| `mscms.dll` | 9 | 9 | P2 |
| `Advapi32.dll` | 8 | 8 | P2 |
| `uxtheme.dll` | 7 | 7 | P2 |
| `?Libraries.CompressionNative` | 7 | 7 | P2 |
| `ninput.dll` | 7 | 7 | P2 |
| `urlmon.dll` | 4 | 4 | P2 |
| `msctf.dll` | 4 | 4 | P2 |
| `oleaut32.dll` | 3 | 3 | P2 |
| `shell32.dll` | 3 | 3 | P2 |
| `winspool.drv` | 2 | 2 | P2 |
| `shcore.dll` | 2 | 2 | P2 |
| `wininet.dll` | 2 | 2 | P2 |
| `WtsApi32.dll` | 2 | 2 | P2 |
| `wtsapi32.dll` | 2 | 2 | P2 |
| `ntdll.dll` | 2 | 2 | P2 |
| `WindowsCodecsExt.dll` | 2 | 2 | P2 |
| `api-ms-win-core-winrt-string-l1-1-0.dll` | 2 | 2 | P2 |
| `api-ms-win-core-winrt-l1-1-0.dll` | 2 | 2 | P2 |
| `oleacc.dll` | 1 | 1 | P2 |
| `winmm.dll` | 1 | 1 | P2 |
| `psapi.dll` | 1 | 1 | P2 |
| `Wininet.dll` | 1 | 1 | P2 |
| `?MS.Win32.ExternDll.Ole32` | 1 | 1 | P2 |
| `shfolder.dll` | 1 | 1 | P2 |

## 2. P0 · 必做（消息泵 + 窗口生命周期）

| DLL | 函数（EntryPoint） | 托管签名 | 声明位置 | shim 导出名 |
|---|---|---|---|---|
| `PresentationNative_cor3.dll` | `EnableWindowWrapper` | `bool EnableWindow(IntPtr hWnd, bool enable)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:35` | `EnableWindowWrapper` |
| `PresentationNative_cor3.dll` | `EnableWindowWrapper` | `bool EnableWindow(HandleRef hWnd, bool enable)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:95` | `EnableWindowWrapper` |
| `PresentationNative_cor3.dll` | `GetAncestorWrapper` | `IntPtr GetAncestor(IntPtr hwnd, int gaFlags)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:65` | `GetAncestorWrapper` |
| `PresentationNative_cor3.dll` | `GetParentWrapper` | `IntPtr GetParent(HandleRef hWnd)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:104` | `GetParentWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongPtrWrapper` | `IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex )` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:43` | `GetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongPtrWrapper` | `IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:119` | `GetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongPtrWrapper` | `IntPtr GetWindowLongPtr(HandleRef hWnd, int nIndex)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:122` | `GetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongPtrWrapper` | `NativeMethods.WndProc GetWindowLongPtrWndProc(HandleRef hWnd, int nIndex)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:125` | `GetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongPtrWrapper` | `?` | `../../../../../build/shims/Win32ShimResolver.cs:73` | `GetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongWrapper` | `Int32 GetWindowLong(IntPtr hWnd, int nIndex )` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:40` | `GetWindowLongWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongWrapper` | `Int32 GetWindowLong(HandleRef hWnd, int nIndex )` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:110` | `GetWindowLongWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowLongWrapper` | `NativeMethods.WndProc GetWindowLongWndProc(HandleRef hWnd, int nIndex)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:116` | `GetWindowLongWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowTextLengthWrapper` | `int GetWindowTextLength(HandleRef hWnd)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:131` | `GetWindowTextLengthWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowTextWrapper` | `int GetWindowText(IntPtr hWnd, [Out] StringBuilder lpString, int nMaxCount)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:80` | `GetWindowTextWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowTextWrapper` | `int GetWindowText(HandleRef hWnd, [Out] StringBuilder lpString, int nMaxCount)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:128` | `GetWindowTextWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowWrapper` | `NativeMethods.HWND GetWindow(NativeMethods.HWND hWnd, int uCmd)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:54` | `GetWindowWrapper` |
| `PresentationNative_cor3.dll` | `GetWindowWrapper` | `IntPtr GetWindow(IntPtr hWnd, int uCmd)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:77` | `GetWindowWrapper` |
| `PresentationNative_cor3.dll` | `MapWindowPointsWrapper` | `int MapWindowPoints(NativeMethods.HWND hWndFrom, NativeMethods.HWND hWndTo, [In, Out] ref NativeMethods.RECT rect, int cPoints)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:57` | `MapWindowPointsWrapper` |
| `PresentationNative_cor3.dll` | `MapWindowPointsWrapper` | `int MapWindowPoints(NativeMethods.HWND hWndFrom, NativeMethods.HWND hWndTo, ref NativeMethods.POINT pt, int cPoints)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:60` | `MapWindowPointsWrapper` |
| `PresentationNative_cor3.dll` | `MapWindowPointsWrapper` | `int MapWindowPoints(IntPtr hWndFrom, IntPtr hWndTo, [In, Out] ref NativeMethods.Win32Rect rect, int cPoints)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:83` | `MapWindowPointsWrapper` |
| `PresentationNative_cor3.dll` | `MapWindowPointsWrapper` | `int MapWindowPoints(IntPtr hWndFrom, IntPtr hWndTo, [In, Out] ref NativeMethods.Win32Point pt, int cPoints)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:86` | `MapWindowPointsWrapper` |
| `PresentationNative_cor3.dll` | `MapWindowPointsWrapper` | `int MapWindowPoints(HandleRef hWndFrom, HandleRef hWndTo, [In, Out] ref NativeMethods.RECT rect, int cPoints)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:134` | `MapWindowPointsWrapper` |
| `PresentationNative_cor3.dll` | `SetFocusWrapper` | `IntPtr SetFocus(HandleRef hWnd)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:137` | `SetFocusWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongPtrWrapper` | `IntPtr SetWindowLongPtr(HandleRef hWnd, int nIndex, IntPtr dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:149` | `SetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongPtrWrapper` | `IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:152` | `SetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongPtrWrapper` | `IntPtr SetWindowLongPtrWndProc(HandleRef hWnd, int nIndex, NativeMethods.WndProc dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:155` | `SetWindowLongPtrWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongWrapper` | `Int32 SetWindowLong(HandleRef hWnd, int nIndex, Int32 dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:140` | `SetWindowLongWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongWrapper` | `Int32 SetWindowLong(IntPtr hWnd, int nIndex, Int32 dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:143` | `SetWindowLongWrapper` |
| `PresentationNative_cor3.dll` | `SetWindowLongWrapper` | `Int32 SetWindowLongWndProc(HandleRef hWnd, int nIndex, NativeMethods.WndProc dwNewLong)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:146` | `SetWindowLongWrapper` |
| `gdi32.dll` | `GetStockObject` | `IntPtr CriticalGetStockObject(int stockObject)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:83` | `GetStockObject` |
| `kernel32.dll` | `GetModuleHandle` | `IntPtr IntGetModuleHandle(string modName)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:498` | `GetModuleHandle` |
| `kernel32.dll` | `GetModuleHandleEx` | `bool GetModuleHandleEx( [In] GetModuleHandleFlags dwFlags, [In][Optional][MarshalAs(UnmanagedType.LPTStr)] string lpModuleName, [Out] out IntPtr hModule)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:734` | `GetModuleHandleExW` |
| `kernel32.dll` | `GetProcAddress` | `IntPtr IntGetProcAddress(HandleRef hModule, string lpProcName)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:517` | `GetProcAddress` |
| `kernel32.dll` | `GetProcAddress` | `IntPtr GetProcAddressNoThrow(HandleRef hModule, string lpProcName)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:538` | `GetProcAddress` |
| `kernel32.dll` | `GetTickCount` | `int GetTickCount()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:570` | `GetTickCount` |
| `kernel32.dll` | `QueryPerformanceCounter` | `bool QueryPerformanceCounter(out long lpPerformanceCount)` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:159` | `QueryPerformanceCounter` |
| `kernel32.dll` | `QueryPerformanceFrequency` | `bool QueryPerformanceFrequency(out long lpFrequency)` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:162` | `QueryPerformanceFrequency` |
| `user32.dll` | `CallWindowProc` | `IntPtr CallWindowProc(IntPtr wndProc, IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:513` | `CallWindowProc` |
| `user32.dll` | `ClientToScreen` | `int IntClientToScreen(HandleRef hWnd, ref NativeMethods.POINT pt)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:768` | `ClientToScreen` |
| `user32.dll` | `CreateWindowEx` | `IntPtr IntCreateWindowEx(int dwExStyle, string lpszClassName, string lpszWindowName, int style, int x, int y, int width, int height, HandleRef hWndParent, HandleRef hMenu, HandleRef hInst, [MarshalAs(UnmanagedType.AsAny)] object pvParam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1041` | `CreateWindowEx` |
| `user32.dll` | `DestroyWindow` | `bool IntDestroyWindow(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1060` | `DestroyWindow` |
| `user32.dll` | `DispatchMessage` | `IntPtr DispatchMessage([In] ref System.Windows.Interop.MSG msg)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:214` | `DispatchMessage` |
| `user32.dll` | `GetActiveWindow` | `IntPtr GetActiveWindow()` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:860` | `GetActiveWindow` |
| `user32.dll` | `GetAncestor` | `IntPtr GetAncestor(HandleRef hWnd, int flags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:489` | `GetAncestor` |
| `user32.dll` | `GetCapture` | `IntPtr GetCapture()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:489` | `GetCapture` |
| `user32.dll` | `GetClassName` | `int GetClassName(HandleRef hwnd, StringBuilder lpClassName, int nMaxCount)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:71` | `GetClassName` |
| `user32.dll` | `GetClientRect` | `bool IntGetClientRect(HandleRef hWnd, [In, Out] ref NativeMethods.RECT rect)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:504` | `GetClientRect` |
| `user32.dll` | `GetDesktopWindow` | `IntPtr GetDesktopWindow()` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:779` | `GetDesktopWindow` |
| `user32.dll` | `GetFocus` | `IntPtr GetFocus()` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:306` | `GetFocus` |
| `user32.dll` | `GetForegroundWindow` | `IntPtr GetForegroundWindow()` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:782` | `GetForegroundWindow` |
| `user32.dll` | `GetMessageExtraInfo` | `IntPtr GetMessageExtraInfo()` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:119` | `GetMessageExtraInfo` |
| `user32.dll` | `GetMessagePos` | `int GetMessagePos()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:495` | `GetMessagePos` |
| `user32.dll` | `GetMessageTime` | `int GetMessageTime()` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:165` | `GetMessageTime` |
| `user32.dll` | `GetSystemMetrics` | `int GetSystemMetrics(SM nIndex)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:746` | `GetSystemMetrics` |
| `user32.dll` | `GetWindow` | `IntPtr GetWindow(HandleRef hWnd, int uCmd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:56` | `GetWindow` |
| `user32.dll` | `GetWindowRect` | `bool IntGetWindowRect(HandleRef hWnd, [In, Out] ref NativeMethods.RECT rect)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:501` | `GetWindowRect` |
| `user32.dll` | `GetWindowThreadProcessId` | `int GetWindowThreadProcessId(HandleRef hWnd, out int lpdwProcessId)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:343` | `GetWindowThreadProcessId` |
| `user32.dll` | `IsWindow` | `bool IsWindow(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:984` | `IsWindow` |
| `user32.dll` | `IsWindowUnicode` | `bool IsWindowUnicode(HandleRef hWnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:531` | `IsWindowUnicode` |
| `user32.dll` | `KillTimer` | `bool KillTimer(HandleRef hwnd, int idEvent)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:528` | `KillTimer` |
| `user32.dll` | `MsgWaitForMultipleObjectsEx` | `int IntMsgWaitForMultipleObjectsEx(int nCount, IntPtr[] pHandles, int dwMilliseconds, int dwWakeMask, int dwFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:143` | `MsgWaitForMultipleObjectsEx` |
| `user32.dll` | `PeekMessage` | `bool PeekMessage([In, Out] ref System.Windows.Interop.MSG msg, HandleRef hwnd, WindowMessage msgMin, WindowMessage msgMax, int remove)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:792` | `PeekMessage` |
| `user32.dll` | `PostMessage` | `bool IntPostMessage(HandleRef hwnd, WindowMessage msg, IntPtr wparam, IntPtr lparam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:801` | `PostMessage` |
| `user32.dll` | `PostMessage` | `bool TryPostMessage(HandleRef hwnd, WindowMessage msg, IntPtr wparam, IntPtr lparam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:812` | `PostMessage` |
| `user32.dll` | `RegisterClassEx` | `ushort IntRegisterClassEx(NativeMethods.WNDCLASSEX_D wc_d)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:158` | `RegisterClassExW` |
| `user32.dll` | `RegisterWindowMessage` | `WindowMessage RegisterWindowMessage(string msg)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:49` | `RegisterWindowMessage` |
| `user32.dll` | `ReleaseCapture` | `bool IntReleaseCapture()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:498` | `ReleaseCapture` |
| `user32.dll` | `ScreenToClient` | `int IntScreenToClient(HandleRef hWnd, ref NativeMethods.POINT pt)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:574` | `ScreenToClient` |
| `user32.dll` | `SendMessage` | `IntPtr SendMessage(IntPtr hWnd, WindowMessage msg, IntPtr wParam, IntPtr lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:257` | `SendMessage` |
| `user32.dll` | `SendMessage` | `IntPtr UnsafeSendMessage(IntPtr hWnd, WindowMessage msg, IntPtr wParam, IntPtr lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:262` | `SendMessage` |
| `user32.dll` | `SendMessage` | `IntPtr SendMessage(HandleRef hWnd, WindowMessage msg, IntPtr wParam, NativeMethods.IconHandle iconHandle)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:272` | `SendMessage` |
| `user32.dll` | `SetActiveWindow` | `IntPtr SetActiveWindow(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:870` | `SetActiveWindow` |
| `user32.dll` | `SetCapture` | `IntPtr SetCapture(HandleRef hwnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:556` | `SetCapture` |
| `user32.dll` | `SetForegroundWindow` | `bool SetForegroundWindow(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:863` | `SetForegroundWindow` |
| `user32.dll` | `SetMessageExtraInfo` | `IntPtr SetMessageExtraInfo(IntPtr lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:122` | `SetMessageExtraInfo` |
| `user32.dll` | `SetParent` | `IntPtr SetParent(HandleRef hWnd, HandleRef hWndParent)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:495` | `SetParent` |
| `user32.dll` | `SetTimer` | `IntPtr SetTimer(HandleRef hWnd, int nIDEvent, int uElapse, NativeMethods.TimerProc lpTimerFunc)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:522` | `SetTimer` |
| `user32.dll` | `SetTimer` | `IntPtr TrySetTimer(HandleRef hWnd, int nIDEvent, int uElapse, NativeMethods.TimerProc lpTimerFunc)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:525` | `SetTimer` |
| `user32.dll` | `SetWindowPos` | `bool SetWindowPos(HandleRef hWnd, HandleRef hWndInsertAfter, int x, int y, int cx, int cy, int flags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:53` | `SetWindowPos` |
| `user32.dll` | `ShowWindow` | `bool ShowWindow(HandleRef hWnd, int nCmdShow)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:92` | `ShowWindow` |
| `user32.dll` | `ShowWindowAsync` | `bool ShowWindowAsync(HandleRef hWnd, int nCmdShow)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:48` | `ShowWindowAsync` |
| `user32.dll` | `TranslateMessage` | `bool TranslateMessage([In, Out] ref System.Windows.Interop.MSG msg)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:210` | `TranslateMessage` |
| `user32.dll` | `UnregisterClass` | `int IntUnregisterClass(IntPtr atomString /*lpClassName*/ , IntPtr hInstance)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:172` | `UnregisterClass` |

## 3. P1 · 值得做（真实现 / 降级 / 返回失败三档）

| DLL | 函数（EntryPoint） | 托管签名 | 声明位置 | shim 导出名 |
|---|---|---|---|---|
| `PresentationNative_cor3.dll` | `CreateTextAnalysisSink` | `unsafe void* CreateTextAnalysisSink()` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1589` | **未导出** |
| `PresentationNative_cor3.dll` | `CreateTextAnalysisSource` | `unsafe int CreateTextAnalysisSource(char* text, uint length, char* culture, void* factory, bool isRightToLeft, char* numberCulture, bool ignoreUserOverride, uint numberSubstitutionMethod, void** ppTextAnalysisSource)` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1609` | **未导出** |
| `PresentationNative_cor3.dll` | `FindWindowExWrapper` | `IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string className, string wndName)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:68` | **未导出** |
| `PresentationNative_cor3.dll` | `GetKeyboardLayoutListWrapper` | `int GetKeyboardLayoutList(int size, [Out, MarshalAs(UnmanagedType.LPArray)] IntPtr[] hkls)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:101` | `GetKeyboardLayoutListWrapper` |
| `PresentationNative_cor3.dll` | `GetMenuBarInfoWrapper` | `bool GetMenuBarInfo (IntPtr hwnd, int idObject, uint idItem, ref UnsafeNativeMethods.MENUBARINFO mbi)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:51` | **未导出** |
| `PresentationNative_cor3.dll` | `GetMenuBarInfoWrapper` | `bool GetMenuBarInfo (IntPtr hwnd, int idObject, uint idItem, ref NativeMethods.MENUBARINFO mbi)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:71` | **未导出** |
| `PresentationNative_cor3.dll` | `GetNumberSubstitutionList` | `unsafe void* GetNumberSubstitutionList(void* textAnalysisSink)` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1603` | **未导出** |
| `PresentationNative_cor3.dll` | `GetScriptAnalysisList` | `unsafe void* GetScriptAnalysisList(void* textAnalysisSink)` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1596` | **未导出** |
| `PresentationNative_cor3.dll` | `GetTextExtentPoint32Wrapper` | `int GetTextExtentPoint32(IntPtr hdc, [MarshalAs(UnmanagedType.LPWStr)]string lpString, int cbString, out NativeMethods.SIZE lpSize)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:74` | **未导出** |
| `PresentationNative_cor3.dll` | `GlobalDeleteAtomWrapper` | `short GlobalDeleteAtom(short atom)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:46` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10OrGreater` | `bool IsWindows10OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:154` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10RS1OrGreater` | `bool IsWindows10RS1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:142` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10RS2OrGreater` | `bool IsWindows10RS2OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:138` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10RS3OrGreater` | `bool IsWindows10RS3OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:134` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10RS4OrGreater` | `bool IsWindows10RS4OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:130` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10RS5OrGreater` | `bool IsWindows10RS5OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:126` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10TH1OrGreater` | `bool IsWindows10TH1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:150` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows10TH2OrGreater` | `bool IsWindows10TH2OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:146` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows7OrGreater` | `bool IsWindows7OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:170` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows7SP1OrGreater` | `bool IsWindows7SP1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:166` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows8OrGreater` | `bool IsWindows8OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:162` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindows8Point1OrGreater` | `bool IsWindows8Point1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:158` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsServer` | `bool IsWindowsServer()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:202` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsVistaOrGreater` | `bool IsWindowsVistaOrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:182` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsVistaSP1OrGreater` | `bool IsWindowsVistaSP1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:178` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsVistaSP2OrGreater` | `bool IsWindowsVistaSP2OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:174` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsXPOrGreater` | `bool IsWindowsXPOrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:198` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsXPSP1OrGreater` | `bool IsWindowsXPSP1OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:194` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsXPSP2OrGreater` | `bool IsWindowsXPSP2OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:190` | **未导出** |
| `PresentationNative_cor3.dll` | `IsWindowsXPSP3OrGreater` | `bool IsWindowsXPSP3OrGreater()` | `Shared/System/Windows/Interop/OSVersionHelper.cs:186` | **未导出** |
| `PresentationNative_cor3.dll` | `LoAcquireBreakRecord` | `LsErr LoAcquireBreakRecord( IntPtr ploline, out IntPtr pbreakrec )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1440` | **未导出** |
| `PresentationNative_cor3.dll` | `LoAcquirePenaltyModule` | `LsErr LoAcquirePenaltyModule( IntPtr ploc, // Line Services context out IntPtr penaltyModuleHandle )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1569` | **未导出** |
| `PresentationNative_cor3.dll` | `LoCloneBreakRecord` | `LsErr LoCloneBreakRecord( IntPtr pBreakRec, out IntPtr pBreakRecClone )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1453` | **未导出** |
| `PresentationNative_cor3.dll` | `LoCreateBreaks` | `LsErr LoCreateBreaks( IntPtr ploc, // Line Services context int cpFirst, IntPtr previousBreakRecord, IntPtr ploparabreak, IntPtr ptslinevariantRestriction, ref LsBreaks lsbreaks, out int bestFitIndex )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1522` | **未导出** |
| `PresentationNative_cor3.dll` | `LoCreateContext` | `LsErr LoCreateContext( ref LsContextInfo contextInfo, // const ref LscbkRedefined lscbkRedef, out IntPtr ploc )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1407` | **未导出** |
| `PresentationNative_cor3.dll` | `LoCreateLine` | `LsErr LoCreateLine( IntPtr ploc, int cp, int ccpLim, int durColumn, uint dwLineFlags, IntPtr pInputBreakRec, out LsLInfo plslinfo, out IntPtr pploline, out int maxDepth, out LsLineWidths lineWidths )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1419` | **未导出** |
| `PresentationNative_cor3.dll` | `LoCreateParaBreakingSession` | `LsErr LoCreateParaBreakingSession( IntPtr ploc, // Line Services context int cpParagraphFirst, int maxWidth, IntPtr previousParaBreakRecord, ref IntPtr pploparabreak, [MarshalAs(UnmanagedType.Bool)] ref bool fParagraphJustified )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1533` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDestroyContext` | `LsErr LoDestroyContext( IntPtr ploc )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1414` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDisplayLine` | `LsErr LoDisplayLine( IntPtr ploline, ref LSPOINT pt, uint displayMode, ref LSRECT clipRect )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1486` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDisposeBreakRecord` | `LsErr LoDisposeBreakRecord( IntPtr pBreakRec, [MarshalAs(UnmanagedType.Bool)] bool finalizing )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1446` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDisposeLine` | `LsErr LoDisposeLine( IntPtr ploline, [MarshalAs(UnmanagedType.Bool)] bool finalizing )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1433` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDisposeParaBreakingSession` | `LsErr LoDisposeParaBreakingSession( IntPtr ploparabreak, [MarshalAs(UnmanagedType.Bool)] bool finalizing )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1544` | **未导出** |
| `PresentationNative_cor3.dll` | `LoDisposePenaltyModule` | `LsErr LoDisposePenaltyModule( IntPtr penaltyModuleHandle )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1575` | **未导出** |
| `PresentationNative_cor3.dll` | `LoEnumLine` | `LsErr LoEnumLine( IntPtr ploline, bool reverseOder, bool fGeometryneeded, ref LSPOINT pt )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1494` | **未导出** |
| `PresentationNative_cor3.dll` | `LoGetEscString` | `void LoGetEscStringImpl( ref EscStringInfo escStringInfo )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1564` | **未导出** |
| `PresentationNative_cor3.dll` | `LoGetPenaltyModuleInternalHandle` | `LsErr LoGetPenaltyModuleInternalHandle( IntPtr penaltyModuleHandle, out IntPtr penaltyModuleInternalHandle )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1580` | **未导出** |
| `PresentationNative_cor3.dll` | `LoQueryLineCpPpoint` | `LsErr LoQueryLineCpPpoint( IntPtr ploline, int lscpQuery, int depthQueryMax, IntPtr pSubLineInfo, // passing raw pinned pointer for out array out int actualDepthQuery, out LsTextCell lsTextCell )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1502` | **未导出** |
| `PresentationNative_cor3.dll` | `LoQueryLinePointPcp` | `LsErr LoQueryLinePointPcp( IntPtr ploline, ref LSPOINT ptQuery, // use POINT as POINTUV int depthQueryMax, IntPtr pSubLineInfo, // passing raw pinned pointer for out array out int actualDepthQuery, out LsTextCell lsTextCell )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1512` | **未导出** |
| `PresentationNative_cor3.dll` | `LoRelievePenaltyResource` | `LsErr LoRelievePenaltyResource( IntPtr ploline )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1459` | **未导出** |
| `PresentationNative_cor3.dll` | `LoSetBreaking` | `LsErr LoSetBreaking( IntPtr ploc, int strategy )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1464` | **未导出** |
| `PresentationNative_cor3.dll` | `LoSetDoc` | `LsErr LoSetDoc( IntPtr ploc, int isDisplay, int isReferencePresentationEqual, ref LsDevRes deviceInfo )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1470` | **未导出** |
| `PresentationNative_cor3.dll` | `LoSetTabs` | `unsafe LsErr LoSetTabs( IntPtr ploc, int durIncrementalTab, int tabCount, LsTbd* pTabs )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1478` | **未导出** |
| `PresentationNative_cor3.dll` | `LocbkGetObjectHandlerInfo` | `unsafe LsErr LocbkGetObjectHandlerInfo( IntPtr ploc, // Line Services context uint objectId, // installed object id void* objectInfo // object handler info )` | `PresentationCore/MS/internal/TextFormatting/LineServices.cs:1551` | **未导出** |
| `PresentationNative_cor3.dll` | `LsDisableSpecialCharacterLigature` | `void LsDisableSpecialCharacterLigature(bool fDisable)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:160` | **未导出** |
| `PresentationNative_cor3.dll` | `MILGetClassificationTables` | `void MILGetClassificationTables(out RawClassificationTables ct)` | `PresentationCore/MS/internal/Classification.cs:199` | **未导出** |
| `PresentationNative_cor3.dll` | `SetScrollPosWrapper` | `int SetScrollPos(IntPtr hWnd, int nBar, int nPos, bool bRedraw)` | `Shared/MS/Win32/NativeMethodsSetLastError.cs:89` | **未导出** |
| `gdi32.dll` | `?` | `?` | `../../../../../build/shims/Win32ShimResolver.cs:5` | **未导出** |
| `gdi32.dll` | `CreateBitmap` | `NativeMethods.BitmapHandle PrivateCreateBitmap(int width, int height, int planes, int bitsPerPixel, byte[] lpvBits)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:954` | `CreateBitmap` |
| `gdi32.dll` | `CreateCompatibleBitmap` | `IntPtr CriticalCreateCompatibleBitmap(HandleRef hDC, int width, int height)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:80` | `CreateCompatibleBitmap` |
| `gdi32.dll` | `CreateCompatibleDC` | `IntPtr CriticalCreateCompatibleDC(HandleRef hDC)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:257` | `CreateCompatibleDC` |
| `gdi32.dll` | `CreateDIBSection` | `NativeMethods.BitmapHandle PrivateCreateDIBSection(HandleRef hdc, ref NativeMethods.BITMAPINFO bitmapInfo, int iUsage, ref IntPtr ppvBits, SafeFileMappingHandle hSection, int dwOffset)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:932` | `CreateDIBSection` |
| `gdi32.dll` | `DeleteDC` | `bool IntCriticalDeleteDC(HandleRef hDC)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:988` | `DeleteDC` |
| `gdi32.dll` | `DeleteObject` | `bool IntDeleteObject(HandleRef hObject)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:105` | `DeleteObject` |
| `gdi32.dll` | `DeleteObject` | `bool IntDeleteObject(IntPtr hObject)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:910` | `DeleteObject` |
| `gdi32.dll` | `EndDoc` | `Int32 EndDoc(HDC hdc)` | `Shared/MS/Win32/NativeMethodsOther.cs:1297` | `EndDoc` |
| `gdi32.dll` | `EndPage` | `Int32 EndPage(HDC hdc)` | `Shared/MS/Win32/NativeMethodsOther.cs:1385` | `EndPage` |
| `gdi32.dll` | `ExtEscape` | `unsafe Int32 ExtEscape(HDC hdc, Int32 nEscape, Int32 cbInput, PrinterEscape* lpvInData, Int32 cbOutput, [Out] void* lpvOutData)` | `Shared/MS/Win32/NativeMethodsOther.cs:1331` | `ExtEscape` |
| `gdi32.dll` | `GetBitmapBits` | `int GetBitmapBits(HandleRef hbmp, int cbBuffer, byte[] lpvBits)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:89` | `GetBitmapBits` |
| `gdi32.dll` | `GetDeviceCaps` | `int GetDeviceCaps(HandleRef hDC, int nIndex)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:857` | `GetDeviceCaps` |
| `gdi32.dll` | `GetObject` | `int GetObject(HandleRef hObject, int nSize, [In, Out] NativeMethods.BITMAP bm)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:303` | `GetObject` |
| `gdi32.dll` | `SelectObject` | `IntPtr CriticalSelectObject(HandleRef hdc, IntPtr obj)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:108` | `SelectObject` |
| `gdi32.dll` | `SetEnhMetaFileBits` | `IntPtr SetEnhMetaFileBits(uint cbBuffer, byte[] buffer)` | `Shared/MS/Win32/NativeMethodsOther.cs:194` | `SetEnhMetaFileBits` |
| `gdi32.dll` | `StartDoc` | `unsafe Int32 StartDoc(HDC hdc, ref DocInfo docInfo)` | `Shared/MS/Win32/NativeMethodsOther.cs:1359` | `StartDoc` |
| `gdi32.dll` | `StartPage` | `Int32 StartPage(HDC hdc)` | `Shared/MS/Win32/NativeMethodsOther.cs:1393` | `StartPage` |
| `kernel32.dll` | `?` | `?` | `../../../../../build/shims/Win32ShimResolver.cs:5` | **未导出** |
| `kernel32.dll` | `CloseHandle` | `bool IntCloseHandle(HandleRef handle)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:238` | `CloseHandle` |
| `kernel32.dll` | `CreateFile` | `unsafe SafeFileHandle CreateFile( string lpFileName, uint dwDesiredAccess, uint dwShareMode, [In] NativeMethods.SECURITY_ATTRIBUTES lpSecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:106` | `CreateFile` |
| `kernel32.dll` | `CreateFileMapping` | `unsafe SafeFileMappingHandle CreateFileMapping(SafeFileHandle hFile, NativeMethods.SECURITY_ATTRIBUTES lpFileMappingAttributes, int flProtect, uint dwMaximumSizeHigh, uint dwMaximumSizeLow, string lpName)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:328` | `CreateFileMappingA` |
| `kernel32.dll` | `DeactivateActCtx` | `bool DeactivateActCtx(int flags, IntPtr activationCtxCookie)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPenimc.cs:630` | `DeactivateActCtx` |
| `kernel32.dll` | `DuplicateHandle` | `bool DuplicateHandle( IntPtr hSourceProcess, SafeWaitHandle hSourceHandle, IntPtr hTargetProcessHandle, out IntPtr hTargetHandle, uint dwDesiredAccess, bool fInheritHandle, uint dwOptions )` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:827` | `DuplicateHandle` |
| `kernel32.dll` | `FindNLSString` | `int FindNLSString(int locale, uint flags, [MarshalAs(UnmanagedType.LPWStr)] string sourceString, int sourceCount, [MarshalAs(UnmanagedType.LPWStr)] string findString, int findCount, out int found)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:528` | **未导出** |
| `kernel32.dll` | `FreeLibrary` | `bool FreeLibrary([In] IntPtr hModule)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:741` | `FreeLibrary` |
| `kernel32.dll` | `GetCurrentProcess` | `IntPtr GetCurrentProcess()` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:821` | `GetCurrentProcess` |
| `kernel32.dll` | `GetCurrentThreadId` | `int GetCurrentThreadId()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:486` | `GetCurrentThreadId` |
| `kernel32.dll` | `GetFileSizeEx` | `bool GetFileSizeEx( SafeFileHandle hFile, ref LARGE_INTEGER lpFileSize )` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:755` | `GetFileSizeEx` |
| `kernel32.dll` | `GetLocaleInfoW` | `int GetLocaleInfoW(int locale, int type, string data, int dataSize)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:525` | `GetLocaleInfoW` |
| `kernel32.dll` | `GetModuleFileName` | `int IntGetModuleFileName(HandleRef hModule, StringBuilder buffer, int length)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:173` | `GetModuleFileNameW` |
| `kernel32.dll` | `GetOEMCP` | `int GetOEMCP()` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:777` | `GetOEMCP` |
| `kernel32.dll` | `GetStringTypeEx` | `unsafe bool GetStringTypeEx(uint locale, uint infoType, char* sourceString, int count, ushort* charTypes)` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:146` | `GetStringTypeEx` |
| `kernel32.dll` | `GetSystemPowerStatus` | `bool GetSystemPowerStatus(ref NativeMethods.SYSTEM_POWER_STATUS systemPowerStatus)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:765` | `GetSystemPowerStatus` |
| `kernel32.dll` | `GetTempFileName` | `uint _GetTempFileName(string tmpPath, string prefix, uint uniqueIdOrZero, StringBuilder tmpFileName)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:17` | `GetTempFileNameW` |
| `kernel32.dll` | `IsDebuggerPresent` | `bool IsDebuggerPresent()` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:153` | `IsDebuggerPresent` |
| `kernel32.dll` | `LoadLibrary` | `IntPtr LoadLibrary(string lpFileName)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:541` | `LoadLibraryW` |
| `kernel32.dll` | `LoadLibraryEx` | `IntPtr LoadLibraryEx([In][MarshalAs(UnmanagedType.LPTStr)] string lpFileName, IntPtr hFile, [In] LoadLibraryFlags dwFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:707` | `LoadLibraryExW` |
| `kernel32.dll` | `LocalFree` | `IntPtr LocalFree(IntPtr hMem)` | `Shared/MS/Win32/NativeMethodsOther.cs:564` | `LocalFree` |
| `kernel32.dll` | `MapViewOfFileEx` | `SafeViewOfFileHandle MapViewOfFileEx(SafeFileMappingHandle hFileMappingObject, int dwDesiredAccess, int dwFileOffsetHigh, int dwFileOffsetLow, IntPtr dwNumberOfBytesToMap, IntPtr lpBaseAddress)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:331` | `MapViewOfFileEx` |
| `kernel32.dll` | `MultiByteToWideChar` | `unsafe int MultiByteToWideChar(int CodePage, int dwFlags, byte* lpMultiByteStr, int cchMultiByte, char* lpWideCharStr, int cchWideChar)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:164` | `MultiByteToWideChar` |
| `kernel32.dll` | `OpenProcess` | `IntPtr OpenProcess(int dwDesiredAccess, bool fInherit, int dwProcessId)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:65` | `OpenProcess` |
| `kernel32.dll` | `ProcessIdToSessionId` | `bool ProcessIdToSessionId([In] int dwProcessId, [Out] out int pSessionId)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:482` | `ProcessIdToSessionId` |
| `kernel32.dll` | `SetEvent` | `int SetEvent([In] SafeWaitHandle hHandle)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:727` | `SetEvent` |
| `kernel32.dll` | `UnmapViewOfFile` | `bool IntUnmapViewOfFile(HandleRef pvBaseAddress)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:261` | `UnmapViewOfFile` |
| `kernel32.dll` | `WaitForMultipleObjectsEx` | `int IntWaitForMultipleObjectsEx(int nCount, IntPtr[] pHandles, bool bWaitAll, int dwMilliseconds, bool bAlertable)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:127` | `WaitForMultipleObjectsEx` |
| `user32.dll` | `?` | `?` | `../../../../../build/shims/Win32ShimResolver.cs:5` | **未导出** |
| `user32.dll` | `ActivateKeyboardLayout` | `IntPtr ActivateKeyboardLayout(HandleRef hkl, int uFlags)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:516` | `ActivateKeyboardLayout` |
| `user32.dll` | `AdjustWindowRectEx` | `bool IntAdjustWindowRectEx(ref NativeMethods.RECT lpRect, int dwStyle, bool bMenu, int dwExStyle)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:507` | `AdjustWindowRectEx` |
| `user32.dll` | `AreDpiAwarenessContextsEqual` | `bool AreDpiAwarenessContextsEqual([In] IntPtr dpiContextA, [In] IntPtr dpiContextB)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:666` | `AreDpiAwarenessContextsEqual` |
| `user32.dll` | `BeginPaint` | `IntPtr IntBeginPaint(HandleRef hWnd, [In, Out] ref NativeMethods.PAINTSTRUCT lpPaint)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:819` | `BeginPaint` |
| `user32.dll` | `ChangeWindowMessageFilter` | `bool IntChangeWindowMessageFilter(WindowMessage message, MSGFLT dwFlag)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:186` | `ChangeWindowMessageFilter` |
| `user32.dll` | `ChangeWindowMessageFilterEx` | `bool IntChangeWindowMessageFilterEx(IntPtr hwnd, WindowMessage message, MSGFLT action, [In, Out, Optional] ref CHANGEFILTERSTRUCT pChangeFilterStruct)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:190` | `ChangeWindowMessageFilterEx` |
| `user32.dll` | `CreateCaret` | `bool CreateCaret(HandleRef hwnd, NativeMethods.BitmapHandle hbitmap, int width, int height)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:39` | `CreateCaret` |
| `user32.dll` | `CreateIconIndirect` | `NativeMethods.IconHandle PrivateCreateIconIndirect([In, MarshalAs(UnmanagedType.LPStruct)] NativeMethods.ICONINFO iconInfo)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:969` | `CreateIconIndirect` |
| `user32.dll` | `DestroyCaret` | `bool DestroyCaret()` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:139` | `DestroyCaret` |
| `user32.dll` | `DestroyCursor` | `bool IntDestroyCursor(IntPtr hCurs)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:881` | `DestroyCursor` |
| `user32.dll` | `DestroyIcon` | `bool IntDestroyIcon(IntPtr hIcon)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:889` | `DestroyIcon` |
| `user32.dll` | `EnableNonClientDpiScaling` | `bool EnableNonClientDpiScaling(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:68` | `EnableNonClientDpiScaling` |
| `user32.dll` | `EndPaint` | `bool IntEndPaint(HandleRef hWnd, ref NativeMethods.PAINTSTRUCT lpPaint)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:827` | `EndPaint` |
| `user32.dll` | `EnumDisplayMonitors` | `bool EnumDisplayMonitors( IntPtr hdc, IntPtr lprcClip, NativeMethods.MonitorEnumProc lpfnEnum, IntPtr lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:2747` | `EnumDisplayMonitors` |
| `user32.dll` | `EnumThreadWindows` | `bool EnumThreadWindows(int dwThreadId, NativeMethods.EnumThreadWindowsCallback lpfn, HandleRef lParam)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:232` | `EnumThreadWindows` |
| `user32.dll` | `FillRect` | `int CriticalFillRect(IntPtr hdc, ref NativeMethods.RECT rcFill, IntPtr brush)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:86` | `FillRect` |
| `user32.dll` | `GetCaretBlinkTime` | `int GetCaretBlinkTime()` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:143` | `GetCaretBlinkTime` |
| `user32.dll` | `GetCursor` | `IntPtr GetCursor()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:540` | `GetCursor` |
| `user32.dll` | `GetCursorPos` | `bool IntGetCursorPos(ref NativeMethods.POINT pt)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:309` | `GetCursorPos` |
| `user32.dll` | `GetCursorPos` | `bool IntTryGetCursorPos(ref NativeMethods.POINT pt)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:322` | `GetCursorPos` |
| `user32.dll` | `GetDC` | `IntPtr IntGetDC(HandleRef hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:835` | `GetDC` |
| `user32.dll` | `GetDoubleClickTime` | `int GetDoubleClickTime()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:534` | `GetDoubleClickTime` |
| `user32.dll` | `GetDpiForSystem` | `uint GetDpiForSystem()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:707` | `GetDpiForSystem` |
| `user32.dll` | `GetDpiForWindow` | `uint GetDpiForWindow([In] HandleRef hwnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:687` | `GetDpiForWindow` |
| `user32.dll` | `GetIconInfo` | `bool GetIconInfoImpl(HandleRef hIcon, [Out] ICONINFO_IMPL piconinfo)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:555` | **未导出** |
| `user32.dll` | `GetKeyState` | `short GetKeyState(int keyCode)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:346` | `GetKeyState` |
| `user32.dll` | `GetKeyboardLayout` | `IntPtr GetKeyboardLayout(int dwLayout)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:519` | `GetKeyboardLayout` |
| `user32.dll` | `GetLayeredWindowAttributes` | `bool GetLayeredWindowAttributes( HandleRef hwnd, IntPtr pcrKey, IntPtr pbAlpha, IntPtr pdwFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:280` | `GetLayeredWindowAttributes` |
| `user32.dll` | `GetMessageW` | `int IntGetMessageW([In, Out] ref System.Windows.Interop.MSG msg, HandleRef hWnd, int uMsgFilterMin, int uMsgFilterMax)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1004` | `GetMessageW` |
| `user32.dll` | `GetMonitorInfo` | `bool IntGetMonitorInfo(HandleRef hmonitor, [In, Out] NativeMethods.MONITORINFOEX info)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:546` | `GetMonitorInfo` |
| `user32.dll` | `GetMouseMovePointsEx` | `int GetMouseMovePointsEx( uint cbSize, [In] ref NativeMethods.MOUSEMOVEPOINT pointsIn, [Out] NativeMethods.MOUSEMOVEPOINT[] pointsBufferOut, int nBufPoints, uint resolution )` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:733` | `GetMouseMovePointsEx` |
| `user32.dll` | `GetPointerCursorId` | `bool GetPointerCursorId([In] UInt32 pointerId, [In, Out] ref UInt32 cursorId)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:557` | **未导出** |
| `user32.dll` | `GetPointerDeviceCursors` | `bool GetPointerDeviceCursors([In] IntPtr device, [In, Out] ref UInt32 cursorCount, [In, Out] POINTER_DEVICE_CURSOR_INFO[] cursors)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:527` | **未导出** |
| `user32.dll` | `GetPointerDeviceProperties` | `bool GetPointerDeviceProperties([In] IntPtr device, [In, Out] ref UInt32 propertyCount, [In, Out] POINTER_DEVICE_PROPERTY[] pointerProperties)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:545` | **未导出** |
| `user32.dll` | `GetPointerDeviceRects` | `bool GetPointerDeviceRects([In] IntPtr device, [In, Out] ref RECT pointerDeviceRect, [In, Out] ref RECT displayRect)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:551` | **未导出** |
| `user32.dll` | `GetPointerDevices` | `bool GetPointerDevices([In, Out] ref UInt32 deviceCount, [In, Out] POINTER_DEVICE_INFO[] devices)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:521` | **未导出** |
| `user32.dll` | `GetPointerInfo` | `bool GetPointerInfo([In] UInt32 pointerId, [In, Out] ref POINTER_INFO pointerInfo)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:533` | **未导出** |
| `user32.dll` | `GetPointerInfoHistory` | `bool GetPointerInfoHistory([In] UInt32 pointerId, [In, Out] ref UInt32 entriesCount, [In, Out] POINTER_INFO[] pointerInfo)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:539` | **未导出** |
| `user32.dll` | `GetPointerPenInfo` | `bool GetPointerPenInfo([In] UInt32 pointerId, [In, Out] ref POINTER_PEN_INFO penInfo)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:563` | **未导出** |
| `user32.dll` | `GetPointerTouchInfo` | `bool GetPointerTouchInfo([In] UInt32 pointerId, [In, Out] ref POINTER_TOUCH_INFO touchInfo)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:569` | **未导出** |
| `user32.dll` | `GetRawInputDeviceInfo` | `uint GetRawInputDeviceInfo( IntPtr hDevice, uint command, [In] ref NativeMethods.RID_DEVICE_INFO ridInfo, ref uint sizeInBytes)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:2659` | **未导出** |
| `user32.dll` | `GetRawInputDeviceList` | `uint GetRawInputDeviceList( [In, Out] NativeMethods.RAWINPUTDEVICELIST[] ridl, [In, Out] ref uint numDevices, uint sizeInBytes)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:2653` | **未导出** |
| `user32.dll` | `GetRawPointerDeviceData` | `bool GetRawPointerDeviceData([In] UInt32 pointerId, [In] UInt32 historyCount, [In] UInt32 propertiesCount, [In] POINTER_DEVICE_PROPERTY[] pProperties, [In, Out] int[] pValues)` | `PresentationCore/MS/Win32/UnsafeNativeMethodsPointer.cs:575` | **未导出** |
| `user32.dll` | `GetSysColor` | `int GetSysColor(int nIndex)` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:149` | `GetSysColor` |
| `user32.dll` | `GetThreadDpiHostingBehavior` | `NativeMethods.DPI_HOSTING_BEHAVIOR GetThreadDpiHostingBehavior()` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:720` | `GetThreadDpiHostingBehavior` |
| `user32.dll` | `GetWindowDpiAwarenessContext` | `DpiAwarenessContextHandle GetWindowDpiAwarenessContext([In] IntPtr hwnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:644` | `GetWindowDpiAwarenessContext` |
| `user32.dll` | `GetWindowPlacement` | `bool IntGetWindowPlacement(HandleRef hWnd, ref NativeMethods.WINDOWPLACEMENT placement)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:607` | `GetWindowPlacement` |
| `user32.dll` | `HideCaret` | `bool HideCaret(HandleRef hwnd)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:45` | `HideCaret` |
| `user32.dll` | `InvalidateRect` | `bool InvalidateRect(HandleRef hWnd, IntPtr rect, bool erase)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:352` | `InvalidateRect` |
| `user32.dll` | `IsChild` | `bool IsChild(HandleRef hWndParent, HandleRef hwnd)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:492` | `IsChild` |
| `user32.dll` | `IsIconic` | `bool IsIconic(IntPtr hWnd)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:879` | **未导出** |
| `user32.dll` | `IsProcessDPIAware` | `bool IsProcessDPIAware()` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:62` | `IsProcessDPIAware` |
| `user32.dll` | `IsWinEventHookInstalled` | `bool IsWinEventHookInstalled(int winevent)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:221` | `IsWinEventHookInstalled` |
| `user32.dll` | `IsWindowEnabled` | `bool IsWindowEnabled(HandleRef hWnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:537` | `IsWindowEnabled` |
| `user32.dll` | `IsWindowVisible` | `bool IsWindowVisible(HandleRef hWnd)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:492` | `IsWindowVisible` |
| `user32.dll` | `LoadCursor` | `NativeMethods.CursorHandle LoadCursor(HandleRef hInst, IntPtr iconId)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:565` | `LoadCursor` |
| `user32.dll` | `LoadImage` | `NativeMethods.CursorHandle LoadImageCursor(IntPtr hinst, string stName, int nType, int cxDesired, int cyDesired, int nFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:51` | `LoadImage` |
| `user32.dll` | `MapVirtualKey` | `int MapVirtualKey(int nVirtKey, int nMapType)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:553` | `MapVirtualKey` |
| `user32.dll` | `MessageBeep` | `int MessageBeep(int uType)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:578` | `MessageBeep` |
| `user32.dll` | `MessageBox` | `int MessageBox(HandleRef hWnd, string text, string caption, int type)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:74` | `MessageBox` |
| `user32.dll` | `MonitorFromPoint` | `IntPtr MonitorFromPoint(NativeMethods.POINT pt, int flags)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:513` | `MonitorFromPoint` |
| `user32.dll` | `MonitorFromRect` | `IntPtr MonitorFromRect(ref NativeMethods.RECT rect, int flags)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:510` | `MonitorFromRect` |
| `user32.dll` | `MonitorFromWindow` | `IntPtr MonitorFromWindow(HandleRef handle, int flags)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:549` | `MonitorFromWindow` |
| `user32.dll` | `NotifyWinEvent` | `void NotifyWinEvent(int winEvent, HandleRef hwnd, int objType, int objID)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:816` | `NotifyWinEvent` |
| `user32.dll` | `PrintWindow` | `bool CriticalPrintWindow(HandleRef hWnd, HandleRef hDC, int flags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:111` | `PrintWindow` |
| `user32.dll` | `RedrawWindow` | `bool CriticalRedrawWindow(HandleRef hWnd, IntPtr lprcUpdate, IntPtr hrgnUpdate, int flags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:114` | `RedrawWindow` |
| `user32.dll` | `RegisterPowerSettingNotification` | `unsafe IntPtr RegisterPowerSettingNotification(IntPtr hRecipient, Guid* pGuid, int Flags)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:265` | `RegisterPowerSettingNotification` |
| `user32.dll` | `ReleaseDC` | `int IntReleaseDC(HandleRef hWnd, HandleRef hDC)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:848` | `ReleaseDC` |
| `user32.dll` | `SetCaretPos` | `bool SetCaretPos(int x, int y)` | `Shared/MS/Win32/SafeNativeMethodsOther.cs:136` | `SetCaretPos` |
| `user32.dll` | `SetCursor` | `IntPtr SetCursor(HandleRef hcursor)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:876` | `SetCursor` |
| `user32.dll` | `SetCursor` | `IntPtr SetCursor(SafeHandle hcursor)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:559` | `SetCursor` |
| `user32.dll` | `SetProp` | `bool SetProp(HandleRef hWnd, string propName, HandleRef data)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:796` | `SetProp` |
| `user32.dll` | `SetThreadDpiAwarenessContext` | `DpiAwarenessContextHandle SetThreadDpiAwarenessContext(DpiAwarenessContextHandle dpiContext)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:2684` | `SetThreadDpiAwarenessContext` |
| `user32.dll` | `SetWinEventHook` | `IntPtr SetWinEventHook(int eventMin, int eventMax, IntPtr hmodWinEventProc, NativeMethods.WinEventProcDef WinEventReentrancyFilter, uint idProcess, uint idThread, int dwFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1070` | `SetWinEventHook` |
| `user32.dll` | `SetWindowPlacement` | `bool IntSetWindowPlacement(HandleRef hWnd, [In] ref NativeMethods.WINDOWPLACEMENT placement)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:619` | `SetWindowPlacement` |
| `user32.dll` | `SetWindowText` | `bool IntSetWindowText(HandleRef hWnd, string text)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:544` | `SetWindowText` |
| `user32.dll` | `ShowCaret` | `bool ShowCaret(HandleRef hwnd)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:42` | `ShowCaret` |
| `user32.dll` | `ShowCursor` | `int ShowCursor(bool show)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:543` | `ShowCursor` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, ref NativeMethods.RECT rc, int nUpdate)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:750` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, ref int value, int ignore)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:753` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, ref bool value, int ignore)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:756` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, ref NativeMethods.HIGHCONTRAST_I rc, int nUpdate)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:759` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, [In, Out] NativeMethods.NONCLIENTMETRICS metrics, int nUpdate)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:762` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, [In, Out] NativeMethods.ANIMATIONINFO anim, int nUpdate)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:631` | `SystemParametersInfo` |
| `user32.dll` | `SystemParametersInfo` | `bool SystemParametersInfo(int nAction, int nParam, [In, Out] NativeMethods.ICONMETRICS metrics, int nUpdate)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:634` | `SystemParametersInfo` |
| `user32.dll` | `TrackMouseEvent` | `bool TrackMouseEvent(NativeMethods.TRACKMOUSEEVENT tme)` | `Shared/MS/Win32/SafeNativeMethodsCLR.cs:562` | `TrackMouseEvent` |
| `user32.dll` | `UnhookWinEvent` | `bool UnhookWinEvent(IntPtr winEventHook)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1073` | `UnhookWinEvent` |
| `user32.dll` | `UnregisterPowerSettingNotification` | `unsafe IntPtr UnregisterPowerSettingNotification(IntPtr hPowerNotify)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:268` | `UnregisterPowerSettingNotification` |
| `user32.dll` | `UpdateLayeredWindow` | `unsafe bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, NativeMethods.POINT* pptDst, NativeMethods.POINT* pSizeDst, IntPtr hdcSrc, NativeMethods.POINT* pptSrc, int crKey, ref NativeMethods.BLENDFUNCTION pBlend, int dwFlags)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:867` | `UpdateLayeredWindow` |
| `user32.dll` | `WindowFromPoint` | `IntPtr IntWindowFromPoint(POINT pt)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:1031` | `WindowFromPoint` |
| `user32.dll` | `keybd_event` | `void Keybd_event(byte vk, byte scan, int flags, IntPtr extrainfo)` | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:168` | `keybd_event` |
| `user32.dll` | `mouse_event` | `void Mouse_event(int flags, int dx, int dy, int dwData, IntPtr extrainfo)` | `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:518` | `mouse_event` |

## 4. P2 · 不做（清单 + 理由）

P2 的判据不是「难」，而是**本工程已经有别的承接面，或在 Linux 上没有对象可做**。
逐 DLL 的理由：


| DLL | 条数 | 处置与理由 |
|---|---|---|
| `wpfgfx_cor3.dll` | 110 | MIL/DUCE 原生面。M7a 已把 **108 个导出名**实现成托管方法（`src/WpfGfx.Linux/Interop/MilNative*.cs`），把它们**导出成原生符号**并接上是 M7c 的活；Win32 shim 不该重复承担。 |
| `WindowsCodecs.dll` | 109 | WIC 成像栈（109 条）。M1 已有 Skia 解码/编码能力面，映射关系待 M7c/后续里程碑定；直接 stub 会让图像路径静默失真。 |
| `msdrm.dll` | 49 | Windows DRM/权限管理（49 条）。WPF 用它做 XPS 权限，Linux 无对应物。 |
| `imm32.dll` | 18 | IME（18 条）。Linux 上是 IBus/Fcitx + XIM，属独立里程碑。 |
| `PenIMC_cor3.dll` | 16 | 触笔/手写输入（16 条）。X11 上走 XInput2，属独立里程碑。 |
| `PresentationHost_cor3.dll` | 14 | 见 docs/U2-M7b-report.md 的未做清单 |
| `mshwgst.dll` | 14 | 手写识别（14 条）。无 Linux 对应物。 |
| `ole32.dll` | 13 | OLE 剪贴板/DnD。M4 已裁决**最小诚实 stub**（`build/shims/PresentationCore.OleApi.Stubs.cs`，一律 PlatformNotSupportedException）。 |
| `mscms.dll` | 9 | Windows 色彩管理（9 条）。Linux 上是 colord/ICC，M1 的色彩面另议。 |
| `Advapi32.dll` | 8 | 见 docs/U2-M7b-report.md 的未做清单 |
| `uxtheme.dll` | 7 | 视觉样式（7 条）。WPF 自绘主题，Linux 上无系统主题可问。 |
| `?Libraries.CompressionNative` | 7 | 见 docs/U2-M7b-report.md 的未做清单 |
| `ninput.dll` | 7 | Windows 指针输入（7 条）。X11 上等价物是 XInput2。 |
| `urlmon.dll` | 4 | 见 docs/U2-M7b-report.md 的未做清单 |
| `msctf.dll` | 4 | 见 docs/U2-M7b-report.md 的未做清单 |
| `oleaut32.dll` | 3 | 见 docs/U2-M7b-report.md 的未做清单 |
| `shell32.dll` | 3 | 见 docs/U2-M7b-report.md 的未做清单 |
| `winspool.drv` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `shcore.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `wininet.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `WtsApi32.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `wtsapi32.dll` | 2 | 终端服务会话通知。X11 无对应物。 |
| `ntdll.dll` | 2 | RtlGetVersion 之类。Linux 上等价物是 uname/Environment.OSVersion。 |
| `WindowsCodecsExt.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `api-ms-win-core-winrt-string-l1-1-0.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `api-ms-win-core-winrt-l1-1-0.dll` | 2 | 见 docs/U2-M7b-report.md 的未做清单 |
| `oleacc.dll` | 1 | 见 docs/U2-M7b-report.md 的未做清单 |
| `winmm.dll` | 1 | 多媒体定时器/音频。无对应物（WPF 媒体在 U3 已定暂缓）。 |
| `psapi.dll` | 1 | 见 docs/U2-M7b-report.md 的未做清单 |
| `Wininet.dll` | 1 | 见 docs/U2-M7b-report.md 的未做清单 |
| `?MS.Win32.ExternDll.Ole32` | 1 | 见 docs/U2-M7b-report.md 的未做清单 |
| `shfolder.dll` | 1 | 见 docs/U2-M7b-report.md 的未做清单 |

## 5. P1 里**返回失败**的条目（诚实清单，不假装成功）

这些函数在 Linux 上**没有可表达的对象**，shim 返回 Win32 的失败码并设 LastError。
它们的共同点是：假装成功会让上层拿到一个无效句柄，比失败更危险。

| 函数 | shim 返回 | 理由 |
|---|---|---|
| `LoadLibrary/GetProcAddress` | 真实现 | 查本 .so 导出表 → dlopen；是真实现不是 stub |
| `CreateFile` | INVALID_HANDLE_VALUE | 内核文件句柄，Linux 上应走 BCL 的 FileStream |
| `CreateFileMapping/MapViewOfFileEx` | NULL | 跨进程共享内存；Linux 上应改 memfd/shm_open |
| `CreateEvent/SetEvent/WaitForMultipleObjectsEx` | NULL / FALSE / WAIT_FAILED | 内核事件对象 |
| `OpenProcess/DuplicateHandle` | NULL / FALSE | 跨进程句柄 |
| `GetLocaleInfo/GetStringTypeEx/FindNLSString` | 0 / -1 | NLS 表；Linux 上用 ICU（BCL 已提供） |
| `GetLayeredWindowAttributes/SetLayeredWindowAttributes/UpdateLayeredWindow` | FALSE | 分层窗口是 Windows 合成路径；X11 上等价的正确做法是 ARGB visual + XComposite |
| `SetWinEventHook/NotifyWinEvent` | NULL / no-op | UIA 事件广播；Linux 上是 AT-SPI2 over D-Bus |
| `RegisterPowerSettingNotification` | NULL | WM_POWERBROADCAST 无对应物 |
| `GetMouseMovePointsEx` | -1 | 依赖 Windows 的鼠标输入历史队列 |
| `GetTempFileName` | 0 | 不伪造临时文件语义；BCL 的 Path.GetTempFileName 可用 |
| `MsgWaitForMultipleObjectsEx(nCount>0)` | WAIT_FAILED + ERROR_NOT_SUPPORTED | 不假装能等内核对象。WPF 全树只有 nCount==0 的调用点（Dispatcher.IsInputPending） |

## 6. 复现命令

```bash
# 1) 属性条数 / 去重条数 / 各档统计
python3 src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py --stdout
# 2) 产物里到底导出了哪些符号
nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | awk '{print $3}' | sort
```
