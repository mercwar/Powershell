#Requires -Version 5.1
<#
.SYNOPSIS
    Validates and installs the MercWar build environment (MSVC, Windows SDK, VC++ Redists, Git, LLVM, CMake, PHP, Node.js, Notepad++).
.PARAMETER CheckOnly
    Audits the environment without installing missing packages.
#>
[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

$x86Pf       = if (${env:ProgramFiles(x86)}) { ${env:ProgramFiles(x86)} } else { $env:ProgramFiles }
$x64Pf       = $env:ProgramFiles
$btDir       = Join-Path $x86Pf "Microsoft Visual Studio\2022\BuildTools"
$vsSetup     = Join-Path $x86Pf "Microsoft Visual Studio\Installer\setup.exe"
$vcVars      = Join-Path $btDir "VC\Auxiliary\Build\vcvars64.bat"
$sdkRoot     = Join-Path $x86Pf "Windows Kits\10"
$sdkInc      = Join-Path $sdkRoot "Include"
$sdkLib      = Join-Path $sdkRoot "Lib"
$stageDir    = Join-Path $env:TEMP "mercwar_env_stage"
$stagedBtExe = Join-Path $stageDir "vs_BuildTools.exe"
$btUrl       = "https://aka.ms" + "/vs/17/release/vs_BuildTools.exe"

$vsWorkloadArgs = @(
    "--passive",
    "--norestart",
    "--add", "Microsoft.VisualStudio.Workload.VCTools",
    "--includeRecommended"
)
$vsOverrideStr = "--passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

# MercWar core & supporting stack definitions
$packages = @(
    [ordered]@{
        Key          = "VCRedistX64"
        Name         = "VC++ Redistributable (x64)"
        WingetId     = "Microsoft.VCRedist.2015+.x64"
        CheckPaths   = @(
            (Join-Path $env:SystemRoot "System32\vcruntime140.dll"),
            (Join-Path $env:SystemRoot "System32\msvcp140.dll")
        )
        CheckCmds    = @()
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "VCRedistX86"
        Name         = "VC++ Redistributable (x86)"
        WingetId     = "Microsoft.VCRedist.2015+.x86"
        CheckPaths   = @(
            (Join-Path $env:SystemRoot "SysWOW64\vcruntime140.dll"),
            (Join-Path $env:SystemRoot "SysWOW64\msvcp140.dll")
        )
        CheckCmds    = @()
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "VSBuildTools"
        Name         = "VS 2022 Build Tools (MSVC + SDK)"
        WingetId     = "Microsoft.VisualStudio.2022.BuildTools"
        CheckPaths   = @($btDir, $vcVars)
        CheckCmds    = @()
        IsBuildTools = $true
    },
    [ordered]@{
        Key          = "Git"
        Name         = "Git for Windows"
        WingetId     = "Git.Git"
        CheckPaths   = @(
            (Join-Path $x64Pf "Git\cmd\git.exe"),
            (Join-Path $x64Pf "Git\usr\bin\bash.exe")
        )
        CheckCmds    = @("git")
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "LLVM"
        Name         = "LLVM / Clang Toolchain"
        WingetId     = "LLVM.LLVM"
        CheckPaths   = @(
            (Join-Path $x64Pf "LLVM\bin\clang.exe"),
            (Join-Path $x64Pf "LLVM\bin\lld-link.exe")
        )
        CheckCmds    = @("clang")
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "CMake"
        Name         = "CMake Build System"
        WingetId     = "Kitware.CMake"
        CheckPaths   = @(
            (Join-Path $x64Pf "CMake\bin\cmake.exe")
        )
        CheckCmds    = @("cmake")
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "PHP"
        Name         = "PHP Runtime"
        WingetId     = "PHP.PHP.8.5"
        CheckPaths   = @("C:\php\php.exe")
        CheckCmds    = @("php")
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "NodeJS"
        Name         = "Node.js LTS"
        WingetId     = "OpenJS.NodeJS.LTS"
        CheckPaths   = @(
            (Join-Path $x64Pf "nodejs\node.exe")
        )
        CheckCmds    = @("node", "npm")
        IsBuildTools = $false
    },
    [ordered]@{
        Key          = "NotepadPlusPlus"
        Name         = "Notepad++"
        WingetId     = "Notepad++.Notepad++"
        CheckPaths   = @(
            (Join-Path $x64Pf "Notepad++\notepad++.exe")
        )
        CheckCmds    = @("notepad++")
        IsBuildTools = $false
    }
)

function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-FileNonEmpty {
    param([string]$Path)
    if (-not $Path) { return $false }
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $false }
    if ($item.PSIsContainer) { return $true }
    return ($item.Length -gt 0)
}

function Test-FullMercWarEnvironment {
    [CmdletBinding()]
    param([switch]$Quiet)

    $result = [ordered]@{
        WingetOk      = $false
        WingetVersion = $null
        MsvcTools     = [ordered]@{}
        SdkFilesOk    = $false
        Packages      = [ordered]@{}
        AnyInstalled  = $false
        AllReady      = $false
    }

    $wgCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wgCmd) {
        $result.WingetOk = $true
        $result.WingetVersion = (& winget --version 2>$null)
        if (-not $Quiet) {
            Write-Host "[OK] winget: $($result.WingetVersion) ($($wgCmd.Source))" -ForegroundColor Green
        }
    } elseif (-not $Quiet) {
        Write-Host "[FAIL] winget not found in PATH." -ForegroundColor Red
    }

    foreach ($pkg in $packages) {
        $foundPath = $null
        foreach ($p in $pkg.CheckPaths) {
            if (Test-FileNonEmpty -Path $p) {
                $foundPath = $p
                break
            }
        }

        $foundCmd = $null
        if (-not $foundPath -and $pkg.CheckCmds.Count -gt 0) {
            foreach ($c in $pkg.CheckCmds) {
                $cmdObj = Get-Command $c -ErrorAction SilentlyContinue
                if ($cmdObj -and (Test-FileNonEmpty -Path $cmdObj.Source)) {
                    $foundCmd = $cmdObj.Source
                    break
                }
            }
        }

        $isPresent = ($null -ne $foundPath) -or ($null -ne $foundCmd)
        if ($isPresent) { $result.AnyInstalled = $true }

        $result.Packages[$pkg.Key] = [ordered]@{
            Name         = $pkg.Name
            WingetId     = $pkg.WingetId
            Installed    = $isPresent
            Resolved     = if ($foundPath) { $foundPath } else { $foundCmd }
            IsBuildTools = $pkg.IsBuildTools
        }

        if (-not $Quiet) {
            if ($isPresent) {
                $loc = if ($foundPath) { $foundPath } else { $foundCmd }
                Write-Host "[OK]   $($pkg.Name) -> $loc" -ForegroundColor Green
            } else {
                Write-Host "[MISS] $($pkg.Name) ($($pkg.WingetId))" -ForegroundColor Yellow
            }
        }
    }

    # Validate MSVC binaries via vcvars64.bat
    foreach ($exe in @("cl.exe", "rc.exe", "link.exe", "lib.exe")) {
        $result.MsvcTools[$exe] = $null
    }

    if (Test-FileNonEmpty -Path $vcVars) {
        $probe = "`"$vcVars`" >nul 2>&1 && where cl.exe rc.exe link.exe lib.exe"
        $lines = @(cmd.exe /c $probe 2>$null)
        foreach ($exe in @("cl.exe", "rc.exe", "link.exe", "lib.exe")) {
            $match = $lines | Where-Object { $_ -like "*\$exe" } | Select-Object -First 1
            if ($match -and (Test-FileNonEmpty -Path $match)) {
                $result.MsvcTools[$exe] = $match
                if (-not $Quiet) { Write-Host "[TOOL] $exe -> $match" -ForegroundColor Green }
            } elseif (-not $Quiet) {
                Write-Host "[MISS] $exe not resolved via vcvars64.bat" -ForegroundColor Red
            }
        }
    }

    # Validate core Windows SDK headers and libraries
    $winHdr = $null
    $krnLib = $null
    if (Test-Path -LiteralPath $sdkInc) {
        $winHdr = Get-ChildItem -LiteralPath $sdkInc -Directory -ErrorAction SilentlyContinue |
                  Sort-Object Name -Descending |
                  ForEach-Object { Join-Path $_.FullName "um\Windows.h" } |
                  Where-Object { Test-FileNonEmpty -Path $_ } |
                  Select-Object -First 1
    }
    if (Test-Path -LiteralPath $sdkLib) {
        $krnLib = Get-ChildItem -LiteralPath $sdkLib -Directory -ErrorAction SilentlyContinue |
                  Sort-Object Name -Descending |
                  ForEach-Object { Join-Path $_.FullName "um\x64\kernel32.lib" } |
                  Where-Object { Test-FileNonEmpty -Path $_ } |
                  Select-Object -First 1
    }

    $result.SdkFilesOk = ($null -ne $winHdr) -and ($null -ne $krnLib)
    if (-not $Quiet) {
        if ($result.SdkFilesOk) {
            Write-Host "[SDK]  Windows.h    -> $winHdr" -ForegroundColor Green
            Write-Host "[SDK]  kernel32.lib -> $krnLib" -ForegroundColor Green
        } else {
            Write-Host "[MISS] Windows 10/11 SDK headers or x64 libs not found under $sdkRoot" -ForegroundColor Red
        }
    }

    $allPkgsOk  = ($result.Packages.Values | Where-Object { -not $_.Installed }).Count -eq 0
    $allToolsOk = ($result.MsvcTools.Values | Where-Object { $null -eq $_ }).Count -eq 0
    $result.AllReady = $allPkgsOk -and $allToolsOk -and $result.SdkFilesOk

    return [pscustomobject]$result
}

function Install-VSBuildTools {
    param([bool]$Admin)

    if ((Test-FileNonEmpty -Path $vsSetup) -and (Test-Path -LiteralPath $btDir)) {
        Write-Host "[INST] Modifying existing VS 2022 Build Tools to add VCTools..." -ForegroundColor Cyan
        $modArgs = "modify --installPath `"$btDir`" $vsOverrideStr"
        $proc = if ($Admin) {
            Start-Process -FilePath $vsSetup -ArgumentList $modArgs -Wait -PassThru
        } else {
            Start-Process -FilePath $vsSetup -ArgumentList $modArgs -Verb RunAs -Wait -PassThru
        }
        return $proc.ExitCode
    }

    if (-not (Test-Path -LiteralPath $stageDir)) {
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
}
Write-Host "[INST] Downloading vs_BuildTools.exe..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $btUrl -OutFile $stagedBtExe -UseBasicParsing
Write-Host "[INST] Running VS 2022 Build Tools installer..." -ForegroundColor Cyan
$instArgs = "--wait $vsOverrideStr"
$proc = if ($Admin) {
Start-Process -FilePath $stagedBtExe -ArgumentList $instArgs -Wait -PassThru
} else {
Start-Process -FilePath $stagedBtExe -ArgumentList $instArgs -Verb RunAs -Wait -PassThru
}
return $proc.ExitCode
}

============================================================================


Main Execution


============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  MERCWAR ENVIRONMENT AUDIT & PROVISIONER" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
$isAdmin = Test-IsAdmin
Write-Host "[INFO] Elevated Administrator: $isAdmin" -ForegroundColor Gray
$status = Test-FullMercWarEnvironment
if ($CheckOnly -or $status.AllReady) {
Write-Host ""
if ($status.AllReady) {
Write-Host "[READY] All MercWar toolchain components and SDK files are verified." -ForegroundColor Green
} else {
Write-Host "[AUDIT] CheckOnly mode complete. Missing components listed above." -ForegroundColor Yellow
}
return
}
Write-Host ""
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  INSTALLING MISSING COMPONENTS" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Cyan
$needBuildTools = (-not $status.Packages["VSBuildTools"].Installed) -or
($null -eq $status.MsvcTools["cl.exe"]) -or
($null -eq $status.MsvcTools["rc.exe"]) -or
(-not $status.SdkFilesOk)
if ($needBuildTools) {
$btExit = Install-VSBuildTools -Admin $isAdmin
if ($btExit -notin @(0, 3010)) {
Write-Host "[WARN] VS Build Tools exited with code: $btExit" -ForegroundColor Yellow
}
}
if ($status.WingetOk) {
foreach ($key in $status.Packages.Keys) {
$pkg = $status.Packages[$key]
if ($pkg.IsBuildTools -or $pkg.Installed) { continue }
Write-Host "[INST] Installing $($pkg.Name) ($($pkg.WingetId))..." -ForegroundColor Cyan
& winget install --id $pkg.WingetId -e --source winget --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
Write-Host "[WARN] winget install for $($pkg.WingetId) returned exit code $LASTEXITCODE" -ForegroundColor Yellow
}
}
} elseif (-not $needBuildTools) {
Write-Host "[ERROR] Cannot install remaining packages because winget is not available." -ForegroundColor Red
}
Write-Host ""
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  POST-INSTALL VERIFICATION" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Cyan
$finalStatus = Test-FullMercWarEnvironment
Write-Host ""
if ($finalStatus.AllReady) {
Write-Host "[SUCCESS] MercWar environment is completely installed and verified!" -ForegroundColor Green
} else {
Write-Host "[INCOMPLETE] Some components still require a reboot or manual attention." -ForegroundColor Yellow
}
