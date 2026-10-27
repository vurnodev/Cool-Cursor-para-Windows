$ErrorActionPreference='Stop'
$compiler=Join-Path ([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'csc.exe'
if(!(Test-Path -LiteralPath $compiler)){
 $compiler=Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
}
if(!(Test-Path -LiteralPath $compiler)){throw 'Compilador C# do .NET Framework nao encontrado.'}
& $compiler /nologo /target:winexe /optimize+ /platform:anycpu (('/out:')+(Join-Path $PSScriptRoot 'ReaplicarSilencioso.exe')) (Join-Path $PSScriptRoot 'ReaplicarSilencioso.cs')
if($LASTEXITCODE -ne 0){throw 'Falha ao compilar o lancador sem console.'}
Write-Output 'ReaplicarSilencioso.exe compilado como aplicativo Windows (sem console).'
