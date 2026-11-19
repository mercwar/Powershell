# Windows Application & CLI Installation Tutorial

A step-by-step guide to registering an application across **DOS/Command Prompt**, **PowerShell**, **Windows Shell (`Win+R`)**, **Custom URI Protocols**, and **Add/Remove Programs** using pure batch (`cmd.exe`) and Windows Registry commands—without requiring manual directory changes or third-party installer builders.

---

## Prerequisites & Standardized Placeholders

Before running the installation steps, define your environment variables at the top of your installer script. Throughout this tutorial, replace the standardized placeholders below with your project's paths and metadata:

| Placeholder | Description |
| :--- | :--- |
| `<APP_NAME>` | Application identifier and custom URI scheme name |
| `<EXE_PATH>` | Full file path to the primary executable (`<EXEC_DIR>\<APP_NAME>.exe`) |
| `<EXEC_DIR>` | Directory containing the executable, DLLs, and `.bat` wrapper |
| `<VERSION_DIR>` | Root versioned installation directory containing `uninstall.bat` |
| `<ICON_PATH>` | Full file path to the `.ico` display icon |
| `<VERSION>` | Display version string |
| `<PUBLISHER>` | Publisher name string |
| `<NETWORK_DLL>` | Filename of the network subsystem DLL |
| `<HEADLESS_DLL>` | Filename of the headless engine DLL |
| `<SIZE_KB>` | Estimated installation size in kilobytes (`REG_DWORD`) |

---

## Step 1: Validate Binaries & Configure Folder Permissions

Before writing registry keys, verify that the target executable exists and grant standard users full read/write permissions to the installation directory so logs, configs, and updates work without elevation prompts.

```bat
if not exist "<EXE_PATH>" (
    echo [ERROR] Execution binaries are missing in: <EXEC_DIR>
    exit /b 1
)

icacls "<VERSION_DIR>" /grant Users:(OI)(CI)F /t >nul 2>&1
```

---

## Step 2: Create a DOS / CLI Wrapper Script

Generating a lightweight `.bat` wrapper alongside your executable ensures that passing arguments (`%*`) from legacy batch scripts or `cmd.exe` forwards cleanly to your binary.

```bat
echo @echo off > "<EXEC_DIR>\<APP_NAME>.bat"
echo "<EXE_PATH>" %%* >> "<EXEC_DIR>\<APP_NAME>.bat"
```

---

## Step 3: Register Environment Variables & Update `PATH`

To make `<APP_NAME>` callable from any terminal window without typing its full directory path:

1. **Inject User Environment Variables (`HKCU\Environment`):**
   ```bat
   reg add "HKCU\Environment" /v "<APP_NAME>" /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
   reg add "HKCU\Environment" /v "<APP_NAME>_path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1
   ```

2. **Prepend `<EXEC_DIR>` to the User `PATH` Safely:**
   Use PowerShell's `[System.Environment]` API rather than `setx` to avoid the 1,024-character truncation limit and duplicate entries:
   ```bat
   powershell -NoProfile -Command "$p=[System.Environment]::GetEnvironmentVariable('PATH','User') -split ';' | Where-Object {$_ -ne ''}; if($p -notcontains '<EXEC_DIR>'){ [System.Environment]::SetEnvironmentVariable('PATH',((@('<EXEC_DIR>')+$p) -join ';'),'User') }" >nul 2>&1
   ```

3. **Register System-Wide Variables (When Running as Administrator):**
   Check for elevation with `net session`. If elevated, register the machine-level variable and system `PATH`:
   ```bat
   net session >nul 2>&1
   if %errorlevel% equ 0 (
       reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "<APP_NAME>_path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
       powershell -NoProfile -Command "$m=[System.Environment]::GetEnvironmentVariable('PATH','Machine') -split ';' | Where-Object {$_ -ne ''}; if($m -notcontains '<EXEC_DIR>'){ [System.Environment]::SetEnvironmentVariable('PATH',((@('<EXEC_DIR>')+$m) -join ';'),'Machine') }" >nul 2>&1
   )
   ```

---

## Step 4: Integrate with Windows Shell (`App Paths`)

Registering your executable and batch wrapper under `App Paths` allows Windows Explorer, the Run dialog (`Win+R`), and the `start` command to locate your program even before a shell restarts.

```bat
:: 64-Bit & Current User Executable Registration
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1

:: DOS Batch Wrapper Registration
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /ve /t REG_SZ /d "<EXEC_DIR>\<APP_NAME>.bat" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /ve /t REG_SZ /d "<EXEC_DIR>\<APP_NAME>.bat" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1

:: SysWOW64 / 32-Bit Redundancy Layer
reg add "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f /reg:64 >nul 2>&1
reg add "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f /reg:64 >nul 2>&1
reg add "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /ve /t REG_SZ /d "<EXE_PATH>" /f >nul 2>&1
reg add "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /v "Path" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1
```

---

## Step 5: Register a Custom URI Protocol (`<APP_NAME>://`)

To allow web browsers and external apps to launch your executable via `<APP_NAME>://` links, register a custom URL protocol handler under `HKLM\SOFTWARE\Classes`:

```bat
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>" /ve /t REG_SZ /d "URL:<APP_NAME> Protocol" /f /reg:64 >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>" /v "URL Protocol" /t REG_SZ /d "" /f /reg:64 >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\<APP_NAME>\shell\open\command" /ve /t REG_SZ /d "\"<EXE_PATH>\" \"%%1\"" /f /reg:64 >nul 2>&1
```

---

## Step 6: Store Subsystem & Runtime DLL Paths

Record the locations of your runtime libraries under `HKCU\Software\<APP_NAME>\Launcher` so your application can dynamically resolve its dependencies:

```bat
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "InstallPath" /t REG_SZ /d "<EXEC_DIR>" /f >nul 2>&1
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "NetworkSubsystem" /t REG_SZ /d "<EXEC_DIR>\<NETWORK_DLL>" /f >nul 2>&1
reg add "HKCU\Software\<APP_NAME>\Launcher" /v "HeadlessEngine" /t REG_SZ /d "<EXEC_DIR>\<HEADLESS_DLL>" /f >nul 2>&1
```

---

## Step 7: Register in Windows Add/Remove Programs (All 5 Hives)

To ensure your application appears in both **Windows Settings (*Apps & Features*)** and **Control Panel (*Programs and Features*)** regardless of user privilege level or 32-bit/64-bit architecture, populate all 5 Uninstall hives:

1. `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>` (`/reg:64`)
2. `HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>` (`/reg:64`)
3. `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`
4. `HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`
5. `HKCU\Software\Classes\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>`

For each hive (`<HIVE_PATH>`), write these 9 standard metadata values:

```bat
reg add "<HIVE_PATH>" /v "DisplayName" /t REG_SZ /d "<APP_NAME>" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "UninstallString" /t REG_SZ /d "\"<VERSION_DIR>\uninstall.bat\"" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "InstallLocation" /t REG_SZ /d "<VERSION_DIR>" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "DisplayIcon" /t REG_SZ /d "<ICON_PATH>" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "DisplayVersion" /t REG_SZ /d "<VERSION>" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "Publisher" /t REG_SZ /d "<PUBLISHER>" /f >nul 2>&1
reg add "<HIVE_PATH>" /v "EstimatedSize" /t REG_DWORD /d <SIZE_KB> /f >nul 2>&1
reg add "<HIVE_PATH>" /v "NoModify" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "<HIVE_PATH>" /v "NoRepair" /t REG_DWORD /d 1 /f >nul 2>&1
```

*(Note: Append `/reg:64` to the `reg add` commands for the two `HKLM` hives.)*

---

## Step 8: Broadcast Environment Changes to Active Shells

Finally, notify Windows Explorer and open command shells that environment variables have changed so users do not need to log out or reboot:

```bat
powershell -NoProfile -Command "$api = '[DllImport(\"user32.dll\", SetLastError=true)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, String lParam);'; $type = Add-Type -MemberDefinition $api -Name 'Win32' -Namespace 'Win32Functions' -PassThru; [Win32Functions.Win32]::SendNotifyMessage([IntPtr]0xffff, 0x001A, [IntPtr]::Zero, 'Environment') | Out-Null" >nul 2>&1
```

---

## Step 9: Uninstalling & Reversing All Registrations

To cleanly uninstall the application from `uninstall.bat`, reverse each registration step in order:

1. **Remove DOS/CLI Wrapper & Environment Variables:**
   ```bat
   del /f /q "<EXEC_DIR>\<APP_NAME>.bat" >nul 2>&1
   reg delete "HKCU\Environment" /v "<APP_NAME>" /f >nul 2>&1
   reg delete "HKCU\Environment" /v "<APP_NAME>_path" /f >nul 2>&1
   reg delete "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "<APP_NAME>_path" /f /reg:64 >nul 2>&1
   ```
2. **Strip `<EXEC_DIR>` from User and Machine `PATH`:**
   ```bat
   powershell -NoProfile -Command "$u=[System.Environment]::GetEnvironmentVariable('PATH','User') -split ';' | Where-Object {$_ -ne '' -and $_ -ne '<EXEC_DIR>'}; [System.Environment]::SetEnvironmentVariable('PATH',($u -join ';'),'User')" >nul 2>&1
   powershell -NoProfile -Command "$m=[System.Environment]::GetEnvironmentVariable('PATH','Machine') -split ';' | Where-Object {$_ -ne '' -and $_ -ne '<EXEC_DIR>'}; [System.Environment]::SetEnvironmentVariable('PATH',($m -join ';'),'Machine')" >nul 2>&1
   ```
3. **Delete All 6 `App Paths` Keys:**
   ```bat
   reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f /reg:64 >nul 2>&1
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f >nul 2>&1
   reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /f /reg:64 >nul 2>&1
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.bat" /f >nul 2>&1
   reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f /reg:64 >nul 2>&1
   reg delete "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths\<APP_NAME>.exe" /f >nul 2>&1
   ```
4. **Delete Custom URI Protocol & Subsystem Keys:**
   ```bat
   reg delete "HKLM\SOFTWARE\Classes\<APP_NAME>" /f /reg:64 >nul 2>&1
   reg delete "HKCU\Software\<APP_NAME>" /f >nul 2>&1
   ```
5. **Delete All 5 Add/Remove Programs Hives:**
   ```bat
   reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f /reg:64 >nul 2>&1
   reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f /reg:64 >nul 2>&1
   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
   reg delete "HKCU\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
   reg delete "HKCU\Software\Classes\Software\Microsoft\Windows\CurrentVersion\Uninstall\<APP_NAME>" /f >nul 2>&1
   ```
6. **Broadcast `WM_SETTINGCHANGE` and Remove `<VERSION_DIR>`:**
   Re-run the `SendNotifyMessage` broadcast from Step 8 and delete the installation directory (`rmdir /s /q "<VERSION_DIR>"`).
