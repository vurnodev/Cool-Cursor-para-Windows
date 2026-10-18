Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$ErrorActionPreference='Stop'
$form=New-Object System.Windows.Forms.Form
$form.Text='Ponta suave - Escolher cor'
$form.Size=New-Object System.Drawing.Size(435,250)
$form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$label=New-Object System.Windows.Forms.Label
$label.Text='Escolha a cor dos seus cursores:'
$label.Location=New-Object System.Drawing.Point(22,20)
$label.AutoSize=$true
$combo=New-Object System.Windows.Forms.ComboBox
$combo.Location=New-Object System.Drawing.Point(22,52)
$combo.Size=New-Object System.Drawing.Size(370,30)
$combo.DropDownStyle='DropDownList'
[void]$combo.Items.AddRange([object[]]@('Azul pervinca','Branco','Laranja','Menta','Violeta','Vermelho e preto','Preto e vermelho'))
$current=(Get-Item 'HKCU:\Control Panel\Cursors').GetValue('')
$combo.SelectedIndex=5
for($i=0;$i -lt $combo.Items.Count;$i++){
 if($current -eq "Ponta suave - $($combo.Items[$i])"){$combo.SelectedIndex=$i}
}
$apply=New-Object System.Windows.Forms.Button
$apply.Text='Aplicar cor'
$apply.Location=New-Object System.Drawing.Point(22,100)
$apply.Size=New-Object System.Drawing.Size(155,34)
$restore=New-Object System.Windows.Forms.Button
$restore.Text='Restaurar anteriores'
$restore.Location=New-Object System.Drawing.Point(190,100)
$restore.Size=New-Object System.Drawing.Size(202,34)
$status=New-Object System.Windows.Forms.Label
$status.Location=New-Object System.Drawing.Point(22,152)
$status.Size=New-Object System.Drawing.Size(370,46)
$status.Text='Selecione uma cor e clique em Aplicar cor.'
function Apply-Selection([bool]$restorePrevious){
 $apply.Enabled=$false; $restore.Enabled=$false
 $status.Text='Aplicando...'
 $form.Refresh()
 try{
  $info=New-Object System.Diagnostics.ProcessStartInfo
  $info.FileName=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $scriptPath=Join-Path $PSScriptRoot 'Instalar.ps1'
  $info.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$scriptPath+'" '
  if($restorePrevious){$info.Arguments+='-Restaurar'}
  else{$info.Arguments+='-Tema "'+[string]$combo.SelectedItem+'"'}
  $info.UseShellExecute=$false
  $info.CreateNoWindow=$true
  $info.RedirectStandardOutput=$true
  $info.RedirectStandardError=$true
  $process=[System.Diagnostics.Process]::Start($info)
  $outTask=$process.StandardOutput.ReadToEndAsync()
  $errTask=$process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  $output=$outTask.Result; $err=$errTask.Result
  if($process.ExitCode -ne 0){throw $err}
  if($restorePrevious){$status.Text='Cursores anteriores restaurados.'}
  else{$status.Text='Cor aplicada: '+[string]$combo.SelectedItem}
 }catch{
  $status.Text='Nao foi possivel aplicar. Veja a mensagem de erro.'
  [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Ponta suave - Erro','OK','Error')
 }finally{$apply.Enabled=$true; $restore.Enabled=$true}
}
$apply.Add_Click({Apply-Selection $false})
$restore.Add_Click({Apply-Selection $true})
$form.Controls.AddRange([System.Windows.Forms.Control[]]@($label,$combo,$apply,$restore,$status))
[void]$form.ShowDialog()
