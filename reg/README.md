# Windows Installation & Uninstallation Tutorial
<div style="text-align: center; margin-bottom: 24px;">
    <a target="_self" title="CLICK HERE to ENTER the GATEWAY FREE!" href="https://mercwar.github.io/Constellation/index.html">
    <img 
        src="https://raw.githubusercontent.com/mercwar/Robo-Knight-Gallery/refs/heads/main/Version%207/image_d2a07390.png" 
        alt="Mercwar Constellation - Gateway Access" 
        style="width:100%; height:auto; border-radius:12px; box-shadow:0 6px 16px rgba(0,0,0,0.6);"
    />
    </a>
</div>
This step-by-step tutorial walks through setting up a Windows application with full Command Prompt/PowerShell integration, `Win+R` Run dialog support, a custom URI protocol handler, and Add/Remove Programs registration—followed by a clean uninstallation process.

---

## Standardized Placeholders

Replace the following placeholders with your application's actual paths and metadata before running the commands:

| Placeholder | Descriptions of your own files |
| :--- | :--- |
| `<APP_NAME>` | Application identifier and URI scheme name |
| `<EXE_PATH>` | Full file path to the primary executable |
| `<EXEC_DIR>` | Directory containing the executable, DLLs, and `.bat` wrapper |
| `<VERSION_DIR>` | Root versioned installation directory containing `uninstall.bat` |
| `<ICON_PATH>` | Full file path to the `.ico` display icon |
| `<VERSION>` | Display version string |
| `<PUBLISHER>` | Publisher name string |
| `<ANY_DLL>` | Filename of the network subsystem DLL | Not Required
| `<NETWORK_DLL>` | Filename of the network subsystem DLL | Not Required
| `<HEADLESS_DLL>` | Filename of the headless engine DLL | Not Required
| `<SIZE_KB>` | Estimated installation size in kilobytes (integer) |

This is the complete install shield use for Eclipse

---

## Part 1: Windows Installation Steps

<div style="text-align: center; margin-bottom: 24px;">

  ![mwps1](../images/mwps1.png)
  
</div>



### Step 1: Verify Binaries & Set Folder Permissions
Confirm that the main executable exists in `<EXEC_DIR>`, then grant full read/write/execute permissions to standard users on `<VERSION_DIR>` so the application can update or manage local files without elevation prompts:

```bat
if not exist "<EXE_PATH>" (
    echo [ERROR] Executable missing in: <EXEC_DIR>
    exit /b 1
)

icacls "<VERSION_DIR>" /grant Users:(OI)(CI)F /t >nul 2>&1
```

---

### Step 2: Create the CLI Wrapper & Configure Environment `PATH`
Create a lightweight `.bat` wrapper inside `<EXEC_DIR>` so all command-line arguments (`%*`) forward cleanly to `<EXE_PATH>`:

```bat
echo @echo off > "<EXEC_DIR>\<APP_NAME>.bat"
echo "<EXE_PATH>" %%* >> "<EXEC_DIR>\<APP_NAME>.bat"
```

Next, register `<APP_NAME>` and `<APP_NAME>_path` in the current user's environment and prepend `<EXEC_DIR>` to the User `PATH` using PowerShell (which avoids the 1024-character truncation limit of `setx`):

```bat
reg add "HKCU\Environment" /v "<APP_NAME>" /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
reg add "HKCU\Environment" /v "<APP_NAME>_path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1

powershell -NoProfile -Command "$p=[System.Environment]::GetEnvironmentVariable('PATH','User') -split ';' | Where-Object {$_ -ne ''}; if($p -notcontains '<EXEC_DIR>'){ [System.Environment]::SetEnvironmentVariable('PATH',((@('<EXEC_DIR>')+$p) -join ';'),'User') }" >nul 2>&1
```

If running with **Administrator privileges**, also register the system-wide environment variable and Machine `PATH`:

```bat
net session >nul 2>&1
if %errorlevel% equ 0 (
    reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "<APP_NAME>_path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
    powershell -NoProfile -Command "$m=[System.Environment]::GetEnvironmentVariable('PATH','Machine') -split ';' | Where-Object {$_ -ne ''}; if($m -notcontains '<EXEC_DIR>'){ [System.Environment]::SetEnvironmentVariable('PATH',((@('<EXEC_DIR>')+$m) -join ';'),'Machine') }" >nul 2>&1
)
```

---

### Step 3: Register Windows `App Paths` (`Win+R` & Shell Execution)
Register both `<APP_NAME>.exe` and `<APP_NAME>.bat` under Windows `App Paths` so users can launch the tool from the Run dialog (`Win+R`), File Explorer, or `start` commands across 64-bit, user, and 32-bit (`Wow6432Node`) contexts:

```bat
:: 64-Bit Machine & User Executable Paths
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1

:: 64-Bit Machine & User Batch Wrapper Paths
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /ve /t REG_SZ /d "<EXEC_DIR>\<APP_NAME>.bat" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /ve /t REG_SZ /d "<EXEC_DIR>\<APP_NAME>.bat" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1

:: 32-Bit SysWOW64 Redundancy
reg add "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
reg add "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1
```

---

### Step 4: Register Custom URI Protocol & Subsystem Keys
Bind `<APP_NAME>://` links to your executable so web browsers and external apps can invoke it directly, and store the runtime DLL locations under `HKCU\Software\<APP_NAME>\Launcher`:

```bat
:: Custom URI Protocol Handler (<APP_NAME>://)
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>" /ve /t REG_SZ /d "URL:<APP_NAME> Protocol" /f /reg:64 >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>" /v "URL Protocol" /t REG_SZ /d "" /f /reg:64 >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>\shell\open\command" /ve /t REG_SZ /d "\"<EXE_PATH>\" \"%%1\"" /f /reg:64 >nul 2>&1

:: Launcher & Runtime DLL Paths
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "InstallPath" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "NetworkSubsystem" /t REG_SZ /d "<EXEC_DIR>\<NETWORK_DLL>" /f >nul 2>&1
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "HeadlessEngine" /t REG_SZ /d "<EXEC_DIR>\<HEADLESS_DLL>" /f >nul 2>&1
```

---

### Step 5: Register in Windows Add/Remove Programs (All 5 Registry Locations)
Populate all 5 Windows `Uninstall` registry locations so the application appears in **Settings > Apps > Installed apps** and **Control Panel > Programs and Features** regardless of user elevation or 32-bit/64-bit view:

1. `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>` (`/reg:64`)
2. `HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>` (`/reg:64`)
3. `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`
4. `HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`
5. `HKCU\Software\Classes\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`

Run the following block for each target key `<UNINSTALL_KEY>` (adding `/reg:64` to the two `HKLM` keys):

```bat
reg add "<UNINSTALL_KEY>" /v "DisplayName" /t REG_SZ /d "<APP_NAME>" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "UninstallString" /t REG_SZ /d "\"<VERSION_DIR>\uninstall.bat\"" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "InstallLocation" /t REG_SZ /d "<VERSION_DIR>" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "DisplayIcon" /t REG_SZ /d "<ICON_PATH>" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "DisplayVersion" /t REG_SZ /d "<VERSION>" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "Publisher" /t REG_SZ /d "<PUBLISHER>" /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "EstimatedSize" /t REG_DWORD /d <SIZE_KB> /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "NoModify" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "<UNINSTALL_KEY>" /v "NoRepair" /t REG_DWORD /d 1 /f >nul 2>&1
```

---

### Step 6: Broadcast Environment Changes to Active Shells
Send a `WM_SETTINGCHANGE` (`0x001A`) broadcast so open Command Prompt, PowerShell, and Explorer windows recognize the updated `PATH` and environment variables immediately without requiring a reboot:

```bat
powershell -NoProfile -Command "$api = '[DllImport(\"user32.dll\", SetLastError=true)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, String lParam);'; $type = Add-Type -MemberDefinition $api -Name 'Win32' -Namespace 'Win32Functions' -PassThru; [Win32Functions.Win32]::SendNotifyMessage([IntPtr]0xffff, 0x001A, [IntPtr]::Zero, 'Environment') | Out-Null" >nul 2>&1
```

---

## Part 2: Windows Uninstallation Steps

To cleanly reverse all changes made during installation, perform these steps in order:

### Step 1: Delete All Registry Keys
Remove the URI protocol handler, launcher settings, all 6 `App Paths` keys, and all 5 Add/Remove Programs keys:

```bat
:: Remove URI Protocol & Launcher Configuration
reg delete "HKLM\SOFTWARE\Classes\<APP_NAME>" /f /reg:64 >nul 2>&1
reg delete "HKCU\Software\<APP_NAME>" /f >nul 2>&1

:: Remove App Paths
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f /reg:64 >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /f /reg:64 >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f /reg:64 >nul 2>&1
reg delete "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f >nul 2>&1

:: Remove All 5 Uninstall Registry Keys
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f /reg:64 >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f /reg:64 >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
reg delete "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
```

### Step 2: Clean Environment Variables & `PATH`
Delete the custom environment variables, filter `<EXEC_DIR>` out of User and Machine `PATH`, and re-broadcast `WM_SETTINGCHANGE`:

```bat
reg delete "HKCU\Environment" /v "<APP_NAME>" /f >nul 2>&1
reg delete "HKCU\Environment" /v "<APP_NAME>_path" /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "<APP_NAME>_path" /f /reg:64 >nul 2>&1

powershell -NoProfile -Command "$u=[System.Environment]::GetEnvironmentVariable('PATH','User') -split ';' | Where-Object {$_ -ne '' -and $_ -ne '<EXEC_DIR>'}; [System.Environment]::SetEnvironmentVariable('PATH',($u -join ';'),'User')" >nul 2>&1
powershell -NoProfile -Command "$m=[System.Environment]::GetEnvironmentVariable('PATH','Machine') -split ';' | Where-Object {$_ -ne '' -and $_ -ne '<EXEC_DIR>'}; [System.Environment]::SetEnvironmentVariable('PATH',($m -join ';'),'Machine')" >nul 2>&1

powershell -NoProfile -Command "$api = '[DllImport(\"user32.dll\", SetLastError=true)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, String lParam);'; $type = Add-Type -MemberDefinition $api -Name 'Win32' -Namespace 'Win32Functions' -PassThru; [Win32Functions.Win32]::SendNotifyMessage([IntPtr]0xffff, 0x001A, [IntPtr]::Zero, 'Environment') | Out-Null" >nul 2>&1
```

### Step 3: Delete Application Files & Directory
Change the working directory out of `<VERSION_DIR>` so Windows does not lock the folder, then remove `<VERSION_DIR>` and all remaining binaries, wrappers, and scripts:

```bat
cd /d "%TEMP%"
rmdir /s /q "<VERSION_DIR>" >nul 2>&1
```
