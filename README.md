# Auditorias Azure
Diferentes scripts de PowerShell para realizar auditorias de Azure.
# Prerrequisitos
Instalar modulo Az
```powershell
Install-Module -Name Az -AllowClobber -Scope AllUsers
```
# PuertosAbiertosVMsAzure.ps1
Busca todas las VMs de Azure asociadas a la cuenta que lo ha ejecutado y devuelve los puertos expuestos hacia internet de dichas VMs.
