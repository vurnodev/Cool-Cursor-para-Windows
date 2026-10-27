using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

[assembly: AssemblyTitle("Ponta suave - Reaplicacao sem console")]
[assembly: AssemblyVersion("1.0.1.0")]
[assembly: AssemblyFileVersion("1.0.1.0")]

internal static class ReaplicarSilencioso
{
    [STAThread]
    private static int Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        try
        {
            string script = Path.Combine(root, "Reaplicar.ps1");
            if (!File.Exists(script))
                throw new FileNotFoundException("Script de reaplicacao nao encontrado.", script);
            var start = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
                    @"WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + script + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using (Process child = Process.Start(start))
            {
                if (child == null) throw new InvalidOperationException("Nao foi possivel iniciar a reaplicacao.");
                child.WaitForExit();
                return child.ExitCode;
            }
        }
        catch (Exception error)
        {
            // Falhas permanecem diagnosticaveis sem abrir console nem caixas de dialogo.
            try
            {
                File.WriteAllText(Path.Combine(root, "ultima-reaplicacao.txt"),
                    DateTimeOffset.Now.ToString("o") + " ERRO lancador: " + error.Message,
                    new UTF8Encoding(false));
            }
            catch { }
            return 1;
        }
    }
}
