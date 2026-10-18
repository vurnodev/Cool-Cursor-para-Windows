param(
 [ValidateSet('Azul pervinca','Branco','Laranja','Menta','Violeta','Vermelho e preto','Preto e vermelho')]
 [string]$Tema='Vermelho e preto',
 [switch]$Restaurar,
 [switch]$Validar,
 [switch]$Escolher,
 [switch]$SemPersistencia
)
$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PontaSuaveNative {
 [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern IntPtr LoadCursorFromFile(string path);
 [DllImport("user32.dll")] public static extern bool DestroyCursor(IntPtr cursor);
 [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool SystemParametersInfo(uint action,uint param,IntPtr value,uint flags);
}
'@
$roles=@('Arrow','Help','AppStarting','Wait','Crosshair','IBeam','NWPen','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll','UpArrow','Hand','Pin','Person')
$dest=Join-Path $env:LOCALAPPDATA 'PontaSuave'
$backup=Join-Path $dest 'cursores-anteriores.json'
$keyPath='HKCU:\Control Panel\Cursors'
function Restore-Values($entries){
 $reg=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Control Panel\Cursors',$true)
 try{
  foreach($entry in $entries){
   if($entry.Exists){$reg.SetValue([string]$entry.Name,$entry.Value,[Enum]::Parse([Microsoft.Win32.RegistryValueKind],$entry.Kind))}
   else{$reg.DeleteValue([string]$entry.Name,$false)}
  }
 }finally{$reg.Dispose()}
}
if($Validar){
 $files=@(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'temas') -Recurse -File)
 foreach($file in $files){
  $handle=[PontaSuaveNative]::LoadCursorFromFile($file.FullName)
  if($handle -eq [IntPtr]::Zero){throw "Windows rejeitou: $($file.FullName)"}
  [void][PontaSuaveNative]::DestroyCursor($handle)
 }
 Write-Output "Windows carregou os $($files.Count) arquivos CUR/ANI."
 exit
}
if($Escolher){
 $temas=@('Azul pervinca','Branco','Laranja','Menta','Violeta','Vermelho e preto','Preto e vermelho')
 for($i=0;$i -lt $temas.Count;$i++){Write-Host "$($i+1). $($temas[$i])"}
 Write-Host '0. Restaurar os cursores anteriores'
 $choice=Read-Host 'Escolha o tema'
 if($choice -eq '0'){$Restaurar=$true}
 elseif($choice -match '^[1-7]$'){$Tema=$temas[[int]$choice-1]}
 else{throw 'Escolha invalida'}
}
if($Restaurar){
 if(!(Test-Path -LiteralPath $backup)){throw 'Backup dos cursores anteriores nao encontrado'}
 $saved=Get-Content -LiteralPath $backup -Raw | ConvertFrom-Json
 if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Persistencia.ps1')){& (Join-Path $PSScriptRoot 'Persistencia.ps1') -Restaurar}
 Restore-Values $saved
 if(!( [PontaSuaveNative]::SystemParametersInfo(0x57,0,[IntPtr]::Zero,0))){throw "Nao foi possivel atualizar os cursores: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"}
 Write-Output 'Cursores anteriores restaurados.'
 exit
}
New-Item -ItemType Directory -Path $dest -Force | Out-Null
if([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($dest)){
 foreach($name in @('temas','Instalar.ps1','Persistencia.ps1','Reaplicar.ps1','Selecionar-cor.ps1','Escolher-tema.cmd','Restaurar.cmd','LEIA-ME.txt','Previa-7-temas.png','cores.json')){
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $dest -Recurse -Force
 }
}
$key=Get-Item -LiteralPath $keyPath
$names=@('','Scheme Source')+$roles
if(!(Test-Path -LiteralPath $backup)){
 $saved=foreach($name in $names){
  $exists=$key.GetValueNames() -contains $name
  [pscustomobject]@{Name=$name;Exists=$exists;Value=if($exists){$key.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}else{$null};Kind=if($exists){$key.GetValueKind($name).ToString()}else{'String'}}
 }
 $saved | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $backup -Encoding UTF8
}
# Validate every selected file before changing registry values.
foreach($role in $roles){
 $ext=if($role -in @('Wait','AppStarting')){'.ani'}else{'.cur'}
 $path=Join-Path $dest "temas\$Tema\$role$ext"
 $h=[PontaSuaveNative]::LoadCursorFromFile($path)
 if($h -eq [IntPtr]::Zero){throw "Cursor invalido: $path"}
 [void][PontaSuaveNative]::DestroyCursor($h)
}
try{
 foreach($role in $roles){
  $ext=if($role -in @('Wait','AppStarting')){'.ani'}else{'.cur'}
  New-ItemProperty -Path $keyPath -Name $role -Value (Join-Path $dest "temas\$Tema\$role$ext") -PropertyType String -Force | Out-Null
 }
 Set-Item -Path $keyPath -Value "Ponta suave - $Tema"
 New-ItemProperty -Path $keyPath -Name 'Scheme Source' -Value 1 -PropertyType DWord -Force | Out-Null
 if(!([PontaSuaveNative]::SystemParametersInfo(0x57,0,[IntPtr]::Zero,0))){throw "Nao foi possivel atualizar os cursores: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"}
}catch{
 Restore-Values (Get-Content -LiteralPath $backup -Raw | ConvertFrom-Json)
 [void][PontaSuaveNative]::SystemParametersInfo(0x57,0,[IntPtr]::Zero,0)
 throw
}
if(!$SemPersistencia){& (Join-Path $dest 'Persistencia.ps1') -Tema $Tema}
Write-Output "Instalado e ativado: Ponta suave - $Tema"
Write-Output "Seletor de cores: $dest\Escolher-tema.cmd"
Write-Output "Backup: $backup"
