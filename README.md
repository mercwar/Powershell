## 🗝️ Mercwar Tools
<div style="text-align: center; margin-bottom: 24px;">
    <a target="_self" title="CLICK HERE to ENTER the GATEWAY FREE!" href="https://mercwar.github.io/Constellation/index.html">
    <img 
        src="https://raw.githubusercontent.com/mercwar/Robo-Knight-Gallery/refs/heads/main/Version%207/image_d2a07390.png" 
        alt="Mercwar Constellation - Gateway Access" 
        style="width:100%; height:auto; border-radius:12px; box-shadow:0 6px 16px rgba(0,0,0,0.6);"
    />
    </a>
</div>



> **Gateway Access:** Enter the [Mercwar Constellation Gateway](https://mercwar.github.io/Constellation/index.html) for interactive constellation exploration, 3D nodes, and project portals.

---

### ⚡ Quick-Launch Scripts

#### 1. Full Programming & Build Environment Installer

Downloads `install.ps1` to `%TEMP%` so self-elevation via `$PSCommandPath` works cleanly, then validates, stages, installs/reinstalls, or uninstalls core build dependencies (VC++ Redistributables, VS 2022 Build Tools / MSVC / Windows SDK, Git, LLVM/Clang, CMake, PHP, Node.js, and Notepad++).

```powershell
$p = Join-Path $env:TEMP "mercwar_install.ps1"; irm "https://raw.githubusercontent.com/mercwar/Powershell/main/install.ps1" -OutFile $p; & $p

```

#### 2. `dc2url` & `ECLIPSE` Preview Installer

Runs the `dc2url` setup script directly in memory to bootstrap `dc2url` and preview `ECLIPSE`.

```powershell
irm "https://raw.githubusercontent.com/mercwar/dc2url/main/install.ps1" | iex

```

<div style="text-align: center; margin-bottom: 24px;">

  ![mwps1](images/mwps1.png)
  
</div>

---

### 📚 Win32 & Build Tutorials

| Module | Topic | Uplink |
| --- | --- | --- |
| **Registry & Uninstall** | Register Windows 11 x64 apps in **Add / Remove Programs** for InstallShield / Win32 installers | [Add/Remove Programs Registration Tutorial](https://www.google.com/search?q=reg/README.md) |
| **Resource Compiler (`rc.exe`)** | Echo `HELLO` in your first compiled `.rc` resource script using a compact Windows batch workflow | [Resource Compiler Pure Batch Tutorial](https://www.google.com/search?q=rc_tutorial/README.md) |

---

### 🛠️ Recommended Workflow

1. **Provision the stack:** Run the `mercwar_install.ps1` one-liner above and complete any UAC elevation prompt.
2. **Launch `dc2url` & `ECLIPSE`:** Run the `dc2url` installer snippet to set up networking utilities and the `ECLIPSE` preview.
3. **Package & ship:** Follow the [Add/Remove Programs Registration Tutorial](https://www.google.com/search?q=reg/README.md) and [Resource Compiler Pure Batch Tutorial](https://www.google.com/search?q=rc_tutorial/README.md) to wire up uninstaller metadata and compiled Win32 resources.
