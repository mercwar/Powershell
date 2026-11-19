Mercwar Tools

For all of the free programming tools and installations
```powershell
$p = Join-Path $env:TEMP "mercwar_install.ps1"; irm "https://raw.githubusercontent.com/mercwar/Powershell/main/install.ps1" -OutFile $p; & $p

```

For dc2url and the eclipse preview
```powershell
irm "https://raw.githubusercontent.com/mercwar/dc2url/main/install.ps1" | iex
```

Echo your first compiled resource file in a small batch script
Resource Compiler pure batch <a href="rc_tutorial/README.md">tutorial </a>


Learn how to register windows programs
Resource Compiler pure batch <a href="reg/README.md">tutorial </a>
