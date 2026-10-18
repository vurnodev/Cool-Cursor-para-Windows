param([string]$Tema,[switch]$Restaurar)
$ErrorActionPreference='Stop'
$root=Join-Path $env:LOCALAPPDATA 'PontaSuave'
$themeKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes'
$backup=Join-Path $root 'preferencia-tema-anterior.json'
$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$taskName='PontaSuave-Persistencia-'+$sid
$service=New-Object -ComObject Schedule.Service
$service.Connect()
$folder=$service.GetFolder('\')
if($Restaurar){
 try{$folder.GetTask($taskName) | Out-Null; $folder.DeleteTask($taskName,0)}catch{if($_.Exception.HResult -ne -2147024894){throw}}
 if(Test-Path -LiteralPath $backup){
  $old=Get-Content -LiteralPath $backup -Raw | ConvertFrom-Json
  if($old.Exists){New-ItemProperty -Path $themeKey -Name ThemeChangesMousePointers -Value ([int]$old.Value) -PropertyType DWord -Force | Out-Null}
  else{Remove-ItemProperty -Path $themeKey -Name ThemeChangesMousePointers -ErrorAction SilentlyContinue}
 }
 Remove-Item -LiteralPath (Join-Path $root 'tema-selecionado.txt') -ErrorAction SilentlyContinue
 return
}
if(!(Test-Path -LiteralPath $backup)){
 $key=Get-Item -LiteralPath $themeKey
 [pscustomobject]@{Exists=($key.GetValueNames() -contains 'ThemeChangesMousePointers');Value=$key.GetValue('ThemeChangesMousePointers')} | ConvertTo-Json | Set-Content -LiteralPath $backup -Encoding UTF8
}
New-ItemProperty -Path $themeKey -Name ThemeChangesMousePointers -Value 0 -PropertyType DWord -Force | Out-Null
$Tema | Set-Content -LiteralPath (Join-Path $root 'tema-selecionado.txt') -Encoding UTF8
# Save a real named scheme using Windows' conventional order (17 entries).
$roles=@('Arrow','Help','AppStarting','Wait','Crosshair','IBeam','NWPen','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll','UpArrow','Hand','Pin','Person')
$paths=foreach($role in $roles){
 $ext=if($role -in @('Wait','AppStarting')){'.ani'}else{'.cur'}
 Join-Path $root "temas\$Tema\$role$ext"
}
New-Item -Path 'HKCU:\Control Panel\Cursors\Schemes' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\Control Panel\Cursors\Schemes' -Name "Ponta suave - $Tema" -Value ($paths -join ',') -PropertyType String -Force | Out-Null
$task=$service.NewTask(0)
$task.RegistrationInfo.Description='Reaplica a cor escolhida do Ponta suave ao entrar, desbloquear ou retomar da suspensao.'
$task.Principal.UserId=$sid
$task.Principal.LogonType=3
$task.Principal.RunLevel=0
$task.Settings.Enabled=$true
$task.Settings.Hidden=$true
$task.Settings.DisallowStartIfOnBatteries=$false
$task.Settings.StopIfGoingOnBatteries=$false
$task.Settings.StartWhenAvailable=$true
$task.Settings.ExecutionTimeLimit='PT1M'
$task.Settings.MultipleInstances=2
$logon=$task.Triggers.Create(9); $logon.UserId=$sid; $logon.Delay='PT5S'
$unlock=$task.Triggers.Create(11); $unlock.UserId=$sid; $unlock.StateChange=8; $unlock.Delay='PT3S'
$resume=$task.Triggers.Create(0)
$resume.Subscription='<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[(Provider[@Name="Microsoft-Windows-Power-Troubleshooter"] and EventID=1) or (Provider[@Name="Microsoft-Windows-Kernel-Power"] and EventID=107)]]</Select></Query></QueryList>'
$resume.Delay='PT3S'
$action=$task.Actions.Create(0)
$action.Path=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$action.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+(Join-Path $root 'Reaplicar.ps1')+'"'
[void]$folder.RegisterTaskDefinition($taskName,$task,6,$sid,$null,3,$null)
Write-Output 'Persistencia configurada: entrada, desbloqueio e retorno da suspensao.'
