"""Testa o lancador com scripts inofensivos, sem alterar os cursores do usuario."""
from pathlib import Path
import shutil, struct, subprocess, tempfile

root = Path(__file__).parent
binary = root / 'ReaplicarSilencioso.exe'
assert binary.exists(), 'Lancador ainda nao compilado'
data = binary.read_bytes()
pe = struct.unpack_from('<I', data, 0x3c)[0]
assert data[pe:pe+4] == b'PE\0\0'
assert struct.unpack_from('<H', data, pe+24+68)[0] == 2, 'Executavel precisa usar Windows GUI, sem console'
with tempfile.TemporaryDirectory(prefix='Ponta suave teste ') as folder:
    work = Path(folder)
    exe = work / binary.name
    shutil.copy2(binary, exe)
    missing = subprocess.run([str(exe)], capture_output=True, timeout=30)
    assert missing.returncode == 1, 'Script ausente deve sinalizar falha'
    assert 'ERRO' in (work/'ultima-reaplicacao.txt').read_text(encoding='utf-8-sig')
    script = '''Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ConsoleProbe {
 [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
}
'@
[ConsoleProbe]::GetConsoleWindow().ToInt64() | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'console.txt')
exit 7
'''
    (work/'Reaplicar.ps1').write_text(script, encoding='utf-8-sig')
    child = subprocess.run([str(exe)], capture_output=True, timeout=30)
    assert child.returncode == 7, 'Codigo de saida do PowerShell precisa ser preservado'
    assert (work/'console.txt').read_text(encoding='utf-8-sig').strip() == '0', 'PowerShell nao deve possuir janela de console'
print('OK: subsistema GUI, erro sem dialogo, caminhos com espacos, filho sem console e codigo de saida preservado.')
