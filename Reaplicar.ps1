$ErrorActionPreference='Stop'
$selection=Join-Path $PSScriptRoot 'tema-selecionado.txt'
if(!(Test-Path -LiteralPath $selection)){exit 0}
try{
 $theme=(Get-Content -LiteralPath $selection -Raw).Trim()
 & (Join-Path $PSScriptRoot 'Instalar.ps1') -Tema $theme -SemPersistencia
 (Get-Date -Format o)+' OK '+$theme | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'ultima-reaplicacao.txt')
}catch{
 (Get-Date -Format o)+' ERRO '+$_.Exception.Message | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'ultima-reaplicacao.txt')
 exit 1
}
