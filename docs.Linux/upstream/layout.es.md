# Correspondencia con el layout del upstream (una fila por proyecto)

[English](layout.md) | [中文](layout.zh-CN.md) | **Español**

> Parte de **docs.Linux** — vuelve al [bus de documentación del lado port](../README.es.md) ([English](../README.md) · [中文](../README.zh-CN.md)).

**La pregunta que responde esta página**: para un proyecto del upstream `dotnet/wpf`, **¿dónde aterrizó en este repositorio?** (¿quién lo compila, quién lo sobrescribe?).

- **Instantánea del upstream**: `upstream/wpf/` (solo lectura, entrada de compilación; base `1cfc37f708f91ff4556bd25af414546c446f3a16`).
- **La compilación aquí es generativa**: `build/port-lib.py` **lee el código fuente** de `upstream/wpf/**` y **reescribe entero** `build/<Proyecto>.Linux/<Proyecto>.Linux.csproj` — cada elemento del upstream suele aparecer en **tres sitios**: `upstream/wpf/**`, `build/<Proyecto>.Linux/**` y la capa de sobrescritura (`src/WpfGfx.Linux*/**`, `build/shims/**`, aplicadores `patch-*.py`).
- **Calibre**: las filas son los **subárboles de proyecto** bajo `upstream/wpf/src/Microsoft.DotNet.Wpf/src/`; el **archivo** `Directory.Build.Props` de ese directorio no es una fila (lo lee `upstream_nowarn()` de `port-lib.py`).

| Proyecto del upstream (`upstream/wpf/src/Microsoft.DotNet.Wpf/src/…`) | Dónde aterriza aquí | Sobrescritura / sustitución Linux |
|---|---|---|
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/` | resuelto por `port-lib.py` como `$(WpfCommonDir)` / `$(WpfCodeGenDir)`; lo leen `build/gen-sr.py` y `build/port-pbt.sh` | sin contraparte; la generación de recursos/código ocurre en el árbol (`build/*.Linux/SR.g.cs`) |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/DirectWriteForwarder/` | `build/DirectWriteForwarder.Linux/` (**escrito a mano**, no lo regenera `port-lib.py`) | `build/DirectWriteForwarder.Linux/{ProviderAdapters,ManagedSurface,NativeMirrors,AssemblyAttrs}.cs` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Extensions/` | `build/System.Windows.Extensions.Linux/` (**escrito a mano**; consumido por XAML/WB/PC/PF vía `HintPath`) | `System.Windows.Extensions.Linux.cs` — el sustituto nativo; estado en `PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PenImc/` | **no entra en la compilación administrada** | ninguna; la falta va al registro de defectos |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/` | `build/port-pbt.sh` transforma el csproj del upstream → `build/PresentationBuildTasks.Linux/` | objetivo único `net10.0`, separadores de ruta, generación de SR (`PORT-CHANGES.md`) |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/` | `port-lib.py PresentationCore` **reescribe** `build/PresentationCore.Linux/PresentationCore.Linux.csproj`; exclusiones en `build/excludes/PresentationCore.txt` | `build/PresentationCore.Linux/*.Linux.cs` + `build/shims/PresentationCore.*.cs` (incluido el shim `HbTextLine`) + `src/WpfGfx.Linux/{Text,Windowing,Rendering,Commands,Interop}/**` + aplicadores `patch-presentationcore-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/` | `port-lib.py PresentationFramework` **reescribe** `build/PresentationFramework.Linux/…csproj`; más la variante `.Classic` | `build/PresentationFramework.Linux/*.Linux.cs` (`FlowDocument*`, `DocumentPage*`, `PtsHelper`, `PtsCache`…) + `build/shims/PresentationFramework.*.cs` + aplicadores `patch-presentationframework-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/` | `build/CycleStub.PresentationUI.Linux/` (**stub de ciclo**: `ApiSubset.cs`, `FindToolBar.ApiSubset.cs`, `ThemeInfo.Linux.cs`) | la completitud de diccionarios de tema pertenece a la cadena de reparación del demo hc (`T-B16`…`T-B19`) |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/` | `port-lib.py ReachFramework` → `build/ReachFramework.Linux/`; se referencia de verdad con PF, así que `build/CycleStub.ReachFramework.Linux/` rompe el ciclo | `build/CycleStub.ReachFramework.Linux/ApiSubset.cs`, `SR.g.cs`, `reapply-patches.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/` | varias `*.Linux.csproj` lo incluyen vía `$(WpfSharedDir)` | aplicadores `patch-shared-hwndwrapper-diag.py`, `patch-shared-invariant-failfast.py` (cambian **cableado y generados**, nunca el fuente del upstream) |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/` | `build/System.Printing.Linux/` (**escrito a mano**) | `PORT-CHANGES.md`; `printcontext.cs` y compañía quedan fuera de PC |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/` | **no entra en la compilación administrada** | ninguna |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/` | `port-lib.py System.Windows.Input.Manipulations` → `build/System.Windows.Input.Manipulations.Linux/` | `SR.g.cs` + `PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Presentation/` | **sin proyecto Linux propio** (su superficie la aportan PC/PF) | ninguna |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Primitives/` | **no entra en la compilación administrada** | ninguna |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/` | `port-lib.py System.Xaml` → `build/System.Xaml.Linux/` | `SR.g.cs` + `PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Themes/` | **sin proyecto Linux propio**: los diccionarios viajan con los stubs de PF / PresentationUI | `build/CycleStub.PresentationUI.Linux/Themes/Generic.xaml` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/` | solo aterrizan **dos** subproyectos: `build/UIAutomationTypes.Linux/` y `build/UIAutomationProvider.Linux/` (`UIAutomationClient` **no** se compila) | `build/shims/Accessibility.Shim.cs`, `build/shims/Win32ShimResolver.cs`, `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs`, pre-aplicador `wire-uiautomation-resolver.py` (**antes de port-lib**) + `patch-uiautomationtypes-reservedvalue.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/` | `port-lib.py WindowsBase` **reescribe** `build/WindowsBase.Linux/WindowsBase.Linux.csproj`; exclusiones en `build/excludes/WindowsBase.txt` | `build/WindowsBase.Linux/*.Linux.cs` + `build/shims/{WindowsWin32,WindowsBase.EventTrace}.Shim.cs` + aplicadores `patch-windowsbase-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/` | **no entra en la compilación administrada** | PF usa `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WpfGfx/` | **no entra en la compilación administrada** (el upstream es el renderizador nativo VC++) | sustituido por `wpfgfx_cor3.so` (milcore AOT) más los shims nativos ⇒ [`linux-overlay.es.md`](linux-overlay.es.md) |

---

## Recalcular el calibre de esta tabla

```bash
# (1) subárboles de proyecto (el número de filas): se espera 21
ls -d upstream/wpf/src/Microsoft.DotNet.Wpf/src/*/ | wc -l
# (2) entradas en ese directorio (= subárboles + el archivo Directory.Build.Props): se espera 22
ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/ | wc -l
# (3) filas de esta tabla: se espera 21
grep -c '^| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/' docs.Linux/upstream/layout.es.md
```

⚠️ **Dicho claro**: `ls … | wc -l` da **22** porque en ese directorio hay además un **archivo**, `Directory.Build.Props` (136 B).
Esta tabla lista los **21 subárboles**, así que `(1)` y `(3)` coinciden y difieren de `(2)` exactamente en uno: ese archivo de props.

---

## Límites y lo que no está en la tabla

- **`build/*.Linux/` es generado**: `port-lib.py` **reescribe** el csproj entero; el cableado debe vivir en los **aplicadores**.
- **Proyectos escritos a mano**: `DirectWriteForwarder.Linux`, `System.Printing.Linux`, `System.Windows.Extensions.Linux`, `CycleStub.*`, `build/DirectWrite.Linux/Provider/`, `src/WpfGfx.Linux/`. Fuente: `build/integration-wave.sh:106-107`.
- **Ya no hay una segunda copia del fuente de Windows en la raíz**: se eliminó en `7027be06e` (19 rutas); razones y recálculo en `build/MilBridge/P0-migrate-report.md`.

---

[English](layout.md) | [中文](layout.zh-CN.md) | **Español** · [bus del lado port](../README.es.md) · [capa Linux](linux-overlay.es.md)
