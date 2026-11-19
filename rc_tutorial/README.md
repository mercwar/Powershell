# Pure-CMD Windows Resource (`.res`) Compilation & Extraction Guide
run associate file in explorer then when uyou click your ps1 files it will ask to associate the file , or try to run associate file in explorer

once your powershell is in your choose programs list , click powershell after you try to double click a ps1 file in your explorer.
now your power shell should open when you click the files , other wise take these steps 

To associate a file extension with a program using the Windows UI (Windows 10 and Windows 11), open Settings > Apps > Default apps and assign your program to the file extension, or use File Explorer's "Open with" menu.

Method 1: Windows Settings (Sets Default for All Files of That Extension)


On Windows 11

1. Press Win + I to open Settings.
2. Click Apps in the left sidebar, then select Default apps.
3. Click the Enter a file type or link type search box at the top and type your extension (e.g., .rc or .json).
4. Click the search result box below it.
5. In the pop-up list, select your program (or scroll down, click Choose an app on your PC, and browse to your .exe).
6. Click Set default.

On Windows 10

1. Press Win + I to open Settings, then click Apps > Default apps.
2. Scroll down and click Choose default apps by file type.
3. Scroll down the alphabetical list on the left to find your extension (e.g., .rc or .json).
4. Click the current app (or Choose a default) on the right and select your program (or Look for another app on this PC).

Method 2: File Explorer "Open with" (Quickest Way)

1. Right-click any file with the extension you want to associate in File Explorer.
2. Hover over Open with and click Choose another app.
3. Select your program from the list (or click Choose an app on your PC / More apps to browse for your .exe).
4. Check the box labeled Always use this app to open .[ext] files (or click Always on Windows 11).
Would you like to add these Windows UI steps into your README tutorial so end-users know how to bind the file extension manually?



Now install this Microsoft Build Tools for FREE!

```powershell
& {
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
    $btUrl       = "https://aka.ms/vs/17/release/vs_BuildTools.exe"

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
            Key         = "VCRedistX64"
            Name        = "VC++ Redistributable (x64)"
            WingetId    = "Microsoft.VCRedist.2015+.x64"
            CheckPaths  = @(
                (Join-Path $env:SystemRoot "System32\vcruntime140.dll"),
                (Join-Path $env:SystemRoot "System32\msvcp140.dll")
            )
            CheckCmds   = @()
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "VCRedistX86"
            Name        = "VC++ Redistributable (x86)"
            WingetId    = "Microsoft.VCRedist.2015+.x86"
            CheckPaths  = @(
                (Join-Path $env:SystemRoot "SysWOW64\vcruntime140.dll"),
                (Join-Path $env:SystemRoot "SysWOW64\msvcp140.dll")
            )
            CheckCmds   = @()
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "VSBuildTools"
            Name        = "VS 2022 Build Tools (MSVC + SDK)"
            WingetId    = "Microsoft.VisualStudio.2022.BuildTools"
            CheckPaths  = @($btDir, $vcVars)
            CheckCmds   = @()
            IsBuildTools = $true
        },
        [ordered]@{
            Key         = "Git"
            Name        = "Git for Windows"
            WingetId    = "Git.Git"
            CheckPaths  = @(
                (Join-Path $x64Pf "Git\cmd\git.exe"),
                (Join-Path $x64Pf "Git\usr\bin\bash.exe")
            )
            CheckCmds   = @("git")
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "LLVM"
            Name        = "LLVM / Clang Toolchain"
            WingetId    = "LLVM.LLVM"
            CheckPaths  = @(
                (Join-Path $x64Pf "LLVM\bin\clang.exe"),
                (Join-Path $x64Pf "LLVM\bin\lld-link.exe")
            )
            CheckCmds   = @("clang")
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "CMake"
            Name        = "CMake Build System"
            WingetId    = "Kitware.CMake"
            CheckPaths  = @(
                (Join-Path $x64Pf "CMake\bin\cmake.exe")
            )
            CheckCmds   = @("cmake")
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "PHP"
            Name        = "PHP Runtime"
            WingetId    = "PHP.PHP.8.5"
            CheckPaths  = @("C:\php\php.exe")
            CheckCmds   = @("php")
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "NodeJS"
            Name        = "Node.js LTS"
            WingetId    = "OpenJS.NodeJS.LTS"
            CheckPaths  = @(
                (Join-Path $x64Pf "nodejs\node.exe")
            )
            CheckCmds   = @("node", "npm")
            IsBuildTools = $false
        },
        [ordered]@{
            Key         = "NotepadPlusPlus"
            Name        = "Notepad++"
            WingetId    = "Notepad++.Notepad++"
            CheckPaths  = @(
                (Join-Path $x64Pf "Notepad++\notepad++.exe")
            )
            CheckCmds   = @("notepad++")
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
            Packages      = @{}
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
                Name        = $pkg.Name
                WingetId    = $pkg.WingetId
                Installed   = $isPresent
                Resolved    = if ($foundPath) { $foundPath } else { $foundCmd }
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

        # Validate core Windows SDK headers & libs
        $sdkChecks = @(
            (Join-Path $sdkInc "um\windows.h"),
            (Join-Path $sdkInc "shared\winapifamily.h")
        )
        if (Test-Path -LiteralPath $sdkInc) {
            $ucrtH = Get-ChildItem -LiteralPath $sdkInc -Filter "corecrt.h" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ucrtH) { $sdkChecks += $ucrtH.FullName }
        }
        if (Test-Path -LiteralPath $sdkLib) {
            $k32Lib = Get-ChildItem -LiteralPath $sdkLib -Filter "kernel32.lib" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($k32Lib) { $sdkChecks += $k32Lib.FullName }
        }

        $missingSdk = @()
        foreach ($sf in $sdkChecks) {
            if (-not (Test-FileNonEmpty -Path $sf)) {
                $missingSdk += $sf
            }
        }
        $result.SdkFilesOk = ($missingSdk.Count -eq 0) -and ($sdkChecks.Count -ge 3)
        if (-not $Quiet) {
            if ($result.SdkFilesOk) {
                Write-Host "[OK]   Windows SDK headers & x64 libraries validated" -ForegroundColor Green
            } else {
                Write-Host "[MISS] Windows SDK headers/libraries incomplete" -ForegroundColor Yellow
            }
        }

        $coreKeys = @("VCRedistX64", "VCRedistX86", "VSBuildTools", "Git")
        $coreOk = ($coreKeys | Where-Object { -not $result.Packages[$_].Installed }).Count -eq 0
        $msvcOk = (($result.MsvcTools.Values | Where-Object { -not $_ }).Count -eq 0)
        $result.AllReady = ($coreOk -and $msvcOk -and $result.SdkFilesOk)

        return [PSCustomObject]$result
    }

    function Get-StagedFiles {
        param([switch]$WingetOk)

        if (-not (Test-Path -LiteralPath $stageDir)) {
            New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
        }

        Write-Host "[*] Downloading vs_BuildTools.exe to $stagedBtExe..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $btUrl -OutFile $stagedBtExe -UseBasicParsing
        if (-not (Test-FileNonEmpty -Path $stagedBtExe) -or ((Get-Item -LiteralPath $stagedBtExe).Length -lt 100000)) {
            throw "Downloaded vs_BuildTools.exe is missing or invalid."
        }
        Write-Host "[OK] Staged vs_BuildTools.exe ($([math]::Round((Get-Item -LiteralPath $stagedBtExe).Length / 1MB, 2)) MB)" -ForegroundColor Green

        if ($WingetOk) {
            foreach ($pkg in $packages) {
                Write-Host "[*] Pre-fetching winget package: $($pkg.WingetId)..." -ForegroundColor Gray
                winget download --id $pkg.WingetId -e --accept-source-agreements --accept-package-agreements --download-directory $stageDir 2>$null | Out-Null
            }
        }
    }

    function Install-SinglePackage {
        param(
            [hashtable]$Pkg,
            [switch]$WingetOk,
            [switch]$Reinstall
        )

        Write-Host ""
        Write-Host "--- Processing $($Pkg.Name) ($($Pkg.WingetId)) ---" -ForegroundColor Cyan

        if ($Pkg.IsBuildTools) {
            $code = 1
            $done = $false

            if ($WingetOk) {
                if ($Reinstall) {
                    winget install --id $Pkg.WingetId -e --force --accept-source-agreements --accept-package-agreements --override $vsOverrideStr
                } else {
                    winget upgrade --id $Pkg.WingetId -e --accept-source-agreements --accept-package-agreements --override $vsOverrideStr
                    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
                        winget install --id $Pkg.WingetId -e --accept-source-agreements --accept-package-agreements --override $vsOverrideStr
                    }
                }
                $code = $LASTEXITCODE
                if ($code -eq 0 -or $code -eq 3010) { $done = $true }
            }

            if (-not $done) {
                if ($Reinstall -and (Test-Path -LiteralPath $vsSetup) -and (Test-Path -LiteralPath $btDir)) {
                    $proc = Start-Process -FilePath $vsSetup -ArgumentList (@("modify", "--installPath", $btDir) + $vsWorkloadArgs) -Wait -PassThru
                    $code = $proc.ExitCode
                } else {
                    if (-not (Test-FileNonEmpty -Path $stagedBtExe)) {
                        Get-StagedFiles -WingetOk:$WingetOk
                    }
                    $proc = Start-Process -FilePath $stagedBtExe -ArgumentList $vsWorkloadArgs -Wait -PassThru
                    $code = $proc.ExitCode
                }
            }
            Write-Host "[*] $($Pkg.Name) exit code: $code" -ForegroundColor $(if ($code -eq 0 -or $code -eq 3010) { "Green" } else { "Yellow" })
            return
        }

        if (-not $WingetOk) {
            Write-Host "[WARN] winget unavailable; skipping $($Pkg.Name)." -ForegroundColor Yellow
            return
        }

        if ($Reinstall) {
            winget install --id $Pkg.WingetId -e --force --silent --accept-source-agreements --accept-package-agreements
        } else {
            winget upgrade --id $Pkg.WingetId -e --silent --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
                winget install --id $Pkg.WingetId -e --silent --accept-source-agreements --accept-package-agreements
            }
        }
        Write-Host "[*] $($Pkg.Name) exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) { "Green" } else { "Yellow" })
    }

    function Invoke-InstallAll {
        param(
            [switch]$WingetOk,
            [switch]$Reinstall
        )

        Get-StagedFiles -WingetOk:$WingetOk

        foreach ($pkg in $packages) {
            try {
                Install-SinglePackage -Pkg $pkg -WingetOk:$WingetOk -Reinstall:$Reinstall
            } catch {
                Write-Host "[ERROR] Failed on $($pkg.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    function Invoke-UninstallAll {
        param([switch]$WingetOk)

        Write-Host ""
        Write-Host "--- UNINSTALL PROMPT ---" -ForegroundColor Yellow
        $confirm = Read-Host "Are you sure you want to UNINSTALL MercWar dependencies & Build Tools? Type YES to confirm"
        if ($confirm -ne "YES") {
            Write-Host "[!] Uninstall cancelled." -ForegroundColor Yellow
            return
        }

        if ($WingetOk) {
            # Uninstall in reverse order (tools/runtimes first, redistributables last)
            for ($i = $packages.Count - 1; $i -ge 0; $i--) {
                $pkg = $packages[$i]
                Write-Host "[*] Uninstalling $($pkg.Name) ($($pkg.WingetId))..." -ForegroundColor Gray
                winget uninstall --id $pkg.WingetId -e --silent --accept-source-agreements 2>$null | Out-Null
                Write-Host "    Exit code: $LASTEXITCODE" -ForegroundColor Gray
            }
        }

        if ((Test-Path -LiteralPath $vsSetup) -and (Test-Path -LiteralPath $btDir)) {
            Write-Host "[*] Running VS Installer uninstall on BuildTools..." -ForegroundColor Gray
            $proc = Start-Process -FilePath $vsSetup -ArgumentList @("uninstall", "--installPath", $btDir, "--passive", "--norestart") -Wait -PassThru
            Write-Host "    Exit code: $($proc.ExitCode)" -ForegroundColor Gray
        }
    }

    if (-not (Test-IsAdmin)) {
        Write-Host "[!] Elevating to Administrator..." -ForegroundColor Yellow
        $tmpScript = Join-Path $env:TEMP ("mercwar_full_env_" + [guid]::NewGuid().ToString("N") + ".ps1")
        try {
            Set-Content -LiteralPath $tmpScript -Value ("& {`r`n" + $MyInvocation.MyCommand.ScriptBlock.ToString() + "`r`n}") -Encoding UTF8
            $pwshExe = (Get-Process -Id $PID).Path
            $proc = Start-Process -FilePath $pwshExe `
                -ArgumentList @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmpScript) `
                -Verb RunAs `
                -Wait `
                -PassThru
            if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
                Write-Host "[ERROR] Elevated session exited with code: $($proc.ExitCode)" -ForegroundColor Red
            }
        } finally {
            Remove-Item -LiteralPath $tmpScript -Force -ErrorAction SilentlyContinue
        }
        return
    }

    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "  MERCWAR FULL ENVIRONMENT VALIDATION & LIFECYCLE MANAGER" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan

    $initial = Test-FullMercWarEnvironment

    Write-Host ""
    if ($initial.AnyInstalled) {
        Write-Host "[!] Existing MercWar environment components detected." -ForegroundColor Yellow
        Write-Host "Choose an action:" -ForegroundColor Cyan
        Write-Host "  [R] Reinstall / Repair All Components & Validate Files"
        Write-Host "  [I] Install Missing Components & Validate Files"
        Write-Host "  [V] Download/Validate Files & Environment Only"
        Write-Host "  [U] Uninstall Components (with confirmation)"
        Write-Host "  [Q] Quit"
        $choice = (Read-Host "Enter choice (R/I/V/U/Q)").Trim().ToUpperInvariant()

        switch ($choice) {
            "R" { Invoke-InstallAll -WingetOk:$initial.WingetOk -Reinstall }
            "I" { Invoke-InstallAll -WingetOk:$initial.WingetOk -Reinstall:$false }
            "V" { Get-StagedFiles -WingetOk:$initial.WingetOk }
            "U" { Invoke-UninstallAll -WingetOk:$initial.WingetOk }
            default {
                Write-Host "[*] Exiting without changes." -ForegroundColor Gray
                return
            }
        }
    } else {
        Write-Host "[!] No existing MercWar environment components detected." -ForegroundColor Yellow
        $choice = (Read-Host "Install full MercWar environment now? (Y/N)").Trim().ToUpperInvariant()
        if ($choice -eq "Y" -or $choice -eq "YES") {
            Invoke-InstallAll -WingetOk:$initial.WingetOk -Reinstall:$false
        } else {
            Write-Host "[*] Install skipped." -ForegroundColor Gray
            return
        }
    }

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "  POST-ACTION FILE & ENVIRONMENT VALIDATION" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan

    $final = Test-FullMercWarEnvironment

    Write-Host ""
    if ($final.AllReady) {
        Write-Host "[PASS] Full MercWar build environment, VC++ redistributables, SDK files, and tools validated." -ForegroundColor Green
    } elseif (-not $final.AnyInstalled) {
        Write-Host "[INFO] Environment components are uninstalled / absent." -ForegroundColor Cyan
    } else {
        Write-Host "[WARN] Some optional or core components are still missing; review status lines above." -ForegroundColor Yellow
    }
}
```
or

``` powershell 
irm "https://githubusercontent.com" | iex

```
A zero-dependency workflow for embedding text or key-value data inside compiled Windows Resource (`.res`) binaries using the Microsoft Resource Compiler (`rc.exe`) and reading it directly from `cmd.exe`.

---

## Prerequisites

* **Windows 10 / 11**
* **MSVC Build Tools (`rc.exe`)** installed and available in your system `PATH` (either via a Developer Command Prompt or system-wide environment registration).

---

## How It Works

When `rc.exe` compiles a resource script (`.rc`) into a binary `.res` file, it prepends a **64-byte binary header** (32-byte empty RES signature + 32-byte `RCDATA` header) containing raw size and ID bytes, including accidental `0x0A` newline characters. 

To extract your payload cleanly in pure `cmd.exe` without garbled header bytes:
1. Wrap your inline `RCDATA` text with leading and trailing `\r\n` line breaks.
2. Prefix each payload line with a unique marker (such as `::`).
3. Filter the binary using `findstr /b "::"` and strip the prefix using `for /f`.

---

## Step 1: Create the Resource Script (`.rc`)
https://github.com/mercwar/Powershell/tree/main/rc_tutorial
Create a file named `msg.rc` containing an inline `RCDATA` block:

```rc
101 RCDATA
BEGIN
  "\r\n::Hello from inside the resource file\r\n"
END
```

Or generate it directly from the command line:

```bat
(
echo 101 RCDATA
echo BEGIN
echo   "\r\n::Hello from inside the resource file\r\n"
echo END
) > msg.rc
```

---

## Step 2: Compile to a Binary `.res` File

Run `rc.exe` to compile `msg.rc` into `msg.res`:

```bat
rc /nologo msg.rc
```

---

## Step 3: Extract and Print in Pure `cmd.exe`

### Interactive Command Prompt (`cmd.exe`)
Run the following command to print the embedded text cleanly:

```bat
for /f "tokens=* delims=:" %A in ('findstr /b "::" msg.res') do @echo %A
```

**Output:**
```text
Hello from inside the resource file
```

### Inside a Batch Script (`.bat`)
When using this inside a `.bat` file, double the percent signs (`%%A`):

```bat
@echo off
for /f "tokens=* delims=:" %%A in ('findstr /b "::" msg.res') do (
    echo %%A
)
```

---

## Advanced: Storing Multiple Key-Value Settings

You can store multiple configuration values inside a single `.res` binary and load them directly into batch environment variables.

### 1. Define Multi-Line `RCDATA` (`config.rc`)
```rc
101 RCDATA
BEGIN
  "\r\n::APP_NAME=FireGem\r\n"
  "::APP_VERSION=2.0.0\r\n"
  "::BUILD_ARCH=x64\r\n"
END
```

### 2. Compile (`rc.exe`)
```bat
rc /nologo config.rc
```

### 3. Load Into Batch Variables (`load_config.bat`)
```bat
@echo off
setlocal EnableDelayedExpansion

for /f "tokens=1,2 delims=:=" %%A in ('findstr /b "::" config.res') do (
    set "%%A=%%B"
)

echo App Name : %APP_NAME%
echo Version  : %APP_VERSION%
echo Arch     : %BUILD_ARCH%
```

**Output:**
```text
App Name : FireGem
Version  : 2.0.0
Arch     : x64
```
