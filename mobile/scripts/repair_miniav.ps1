<#
.SYNOPSIS
Re-applies local fixes for miniav_ffi (pub cache) so the native build works on
Windows/MSVC 19.51 (VS 18 2026) and skips the broken WGC screen-capture backend.

WHY
  miniav_ffi 0.7.1 has three Windows-specific build bugs:
    1. MSVC 19.51 promotes the <experimental/coroutine> deprecation (STL1011) to
       a hard error; C++/WinRT still pulls it in transitively.
    2. The WGC backend uses C++/WinRT but never compiles winrt/base.cpp, so the
       DLL fails to link (WINRT_IMPL_RoGetActivationFactory unresolved).
    3. screen_api.c references WGC symbols unconditionally, so WGC cannot simply
       be turned off without also guarding those references.
  Fix 2 by disabling WGC (DXGI remains the Windows screen-capture backend).

USAGE
  Run after any `flutter pub get` that reinstalls miniav_ffi, and before the
  first Windows build/test:
      powershell -ExecutionPolicy Bypass -File scripts\repair_miniav.ps1
  The script then clears the stale native build cache so the fixes take effect.

  Idempotent: already-patched files are left untouched (output shows SKIP).

NOTES
  - Android/iOS builds are unaffected (all patches are Windows-only).
  - Remove this script + stop running it once upstream PracticalXR/miniAV fixes
    the package.
#>

[CmdletBinding()]
param(
    [string]$PackagePath,
    [switch]$SkipCacheClean
)

$ErrorActionPreference = 'Stop'

function Resolve-PackagePath {
    if ($PackagePath) { return $PackagePath }
    $pubRoot = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
    $hosted = Join-Path $pubRoot 'hosted\pub.dev'
    $ffiDirs = Get-ChildItem $hosted -Directory -Filter 'miniav_ffi-*' -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.Name -replace 'miniav_ffi-', '') } -Descending
    if (-not $ffiDirs) { throw "miniav_ffi not found under $hosted. Run 'flutter pub get' first." }
    return $ffiDirs[0].FullName
}

function Apply-Patch {
    param([string]$File, [string]$Old, [string]$New, [string]$Label)
    $raw = [System.IO.File]::ReadAllText($File)
    $content = $raw -replace "`r`n", "`n"
    if ($content.Contains($New)) { Write-Host "SKIP  $Label (already applied)"; return }
    if (-not $content.Contains($Old)) { Write-Warning "SKIP  $Label (pattern not found - version drift?)"; return }
    $content = $content.Replace($Old, $New)
    $content = $content -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($File, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "PATCH $Label"
}

$pkg = Resolve-PackagePath
Write-Host "Patching: $pkg"
$cmake     = Join-Path $pkg 'miniav_c\CMakeLists.txt'
$screenApi = Join-Path $pkg 'miniav_c\src\screen\screen_api.c'
foreach ($f in @($cmake, $screenApi)) {
    if (-not (Test-Path $f)) { throw "Expected file missing: $f" }
}

# --- Patch 1: silence MSVC 19.51 <experimental/coroutine> hard error (STL1011) ---
$p1Old = "project(miniav_c LANGUAGES C CXX)`n"
$p1New = @'
project(miniav_c LANGUAGES C CXX)

# STL1011: MSVC 19.51 turns the <experimental/coroutine> deprecation into an
# error, but C++/WinRT still pulls it in transitively. Silence until upstream
# migrates to <coroutine>.
add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
'@
Apply-Patch -File $cmake -Old $p1Old -New $p1New -Label "CMakeLists: silence experimental/coroutine (STL1011)"

# --- Patch 2: WGC disabled by default (DXGI becomes the Windows screen backend) ---
$p2Old = 'option(MINIAV_BACKEND_WIN_WGC "Enable WGC for Windows screen capture" ON)'
$p2New = 'option(MINIAV_BACKEND_WIN_WGC "Enable WGC for Windows screen capture" OFF)'
Apply-Patch -File $cmake -Old $p2Old -New $p2New -Label "CMakeLists: disable WGC backend by default"

# --- Patch 3: guard WGC include/externs in screen_api.c ---
$p3Old = @'
#ifdef _WIN32
#include "windows/screen_context_win_wgc.h"
extern const ScreenContextInternalOps g_screen_ops_win_wgc;
extern MiniAVResultCode
miniav_screen_context_platform_init_windows_wgc(MiniAVScreenContext *ctx);
#include "windows/screen_context_win_dxgi.h"
'@
$p3New = @'
#ifdef _WIN32
#ifdef MINIAV_BACKEND_WIN_WGC_ENABLED
#include "windows/screen_context_win_wgc.h"
extern const ScreenContextInternalOps g_screen_ops_win_wgc;
extern MiniAVResultCode
miniav_screen_context_platform_init_windows_wgc(MiniAVScreenContext *ctx);
#endif
#include "windows/screen_context_win_dxgi.h"
'@
Apply-Patch -File $screenApi -Old $p3Old -New $p3New -Label "screen_api.c: guard WGC declarations"

# --- Patch 4: guard the WGC entry in the backend table ---
$p4Old = @'
#ifdef _WIN32
    {"Windows Graphics Capture", &g_screen_ops_win_wgc,
     miniav_screen_context_platform_init_windows_wgc},
    {"DXGI", &g_screen_ops_win_dxgi,
     miniav_screen_context_platform_init_windows_dxgi},
#endif
'@
$p4New = @'
#ifdef _WIN32
#ifdef MINIAV_BACKEND_WIN_WGC_ENABLED
    {"Windows Graphics Capture", &g_screen_ops_win_wgc,
     miniav_screen_context_platform_init_windows_wgc},
#endif
    {"DXGI", &g_screen_ops_win_dxgi,
     miniav_screen_context_platform_init_windows_dxgi},
#endif
'@
Apply-Patch -File $screenApi -Old $p4Old -New $p4New -Label "screen_api.c: guard WGC backend entry"

# --- Clear stale native build cache so the WGC=OFF option actually takes effect ---
if (-not $SkipCacheClean) {
    $mobileDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $hookCache = Join-Path $mobileDir '.dart_tool\hooks_runner\shared\miniav_ffi'
    if (Test-Path $hookCache) {
        Remove-Item -Recurse -Force $hookCache
        Write-Host "CLEARED stale native build cache: $hookCache"
    } else {
        Write-Host "No stale native build cache to clear."
    }
}

Write-Host "Done."