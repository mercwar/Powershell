Mercwar Tools

For all of the free programming tools and installations
```powershell
$p = Join-Path $env:TEMP "mercwar_install.ps1"; irm "https://raw.githubusercontent.com/mercwar/Powershell/main/install.ps1" -OutFile $p; & $p

```

For dc2url and the eclipse preview
```powershell
irm "https://raw.githubusercontent.com/mercwar/dc2url/main/install.ps1" | iex
```
