using Microsoft.Win32;
using System.ComponentModel;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using static System.Net.Mime.MediaTypeNames;

static String Get32BitSystemDirectory(Boolean placeInEnvironmentVariable = true)
{
    String sysDir = "";
    sysDir = Environment.ExpandEnvironmentVariables("%windir%\\System32");
    //sysDir = Environment.ExpandEnvironmentVariables("%windir%\\System32");
    if (placeInEnvironmentVariable) Environment.SetEnvironmentVariable("SYSDIR32", sysDir, EnvironmentVariableTarget.User);
    return sysDir;
}
static String GetProgramFiles()
{
    String ProgramFilesDir = "";
    ProgramFilesDir = Environment.ExpandEnvironmentVariables("%ProgramFiles%");
    return ProgramFilesDir;
}

static String GetAppDataRoaming()
{
    String AppDataRoaming = "";
    AppDataRoaming = Environment.ExpandEnvironmentVariables("%appdata%");
    return AppDataRoaming;
}

static void RunPowershell(string[] args)
{
    // create a new process
    StringBuilder sb = new StringBuilder();
    Process pro = new Process();
    string system32 = Get32BitSystemDirectory();
    string programfiles = GetProgramFiles();
    string AppData = GetAppDataRoaming();
    string PSPath;
    string arguments;
    string PS5 = system32 + "\\WindowsPowerShell\\v1.0\\Powershell.exe";
    string PS7 = programfiles + "\\PowerShell\\7\\pwsh.exe";
    string logdirectory = AppData + "\\Samson\\Logs";
    string logfile = logdirectory + "\\Samson-Launcher.log";
    string installpath = "";
    string installfolder = "";
    if (!Directory.Exists(logdirectory))
    {
        Directory.CreateDirectory(logdirectory);
    }
    sb.Append($"\n#### Starting Launcher for Samson Media Player ####");
    
    RegistryKey key = Registry.LocalMachine.OpenSubKey("SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{4C8E33BE-7E0A-4970-A7EC-B70180A6CD8E}_is1");
    if (key != null)
    {
        object objRegisteredValue = key.GetValue("InstallLocation");
        if (objRegisteredValue != null) {
            installfolder = objRegisteredValue.ToString();
            installpath = $"{installfolder}Samson.ps1";
        }    
        key.Dispose();
    }
    else
    {
        installfolder = System.IO.Directory.GetCurrentDirectory();
        installpath = $"{installfolder}\\Samson.ps1";
    }

    if (File.Exists(installpath))
    {
        if (File.Exists(PS7))
        {
            PSPath = PS7;
        }
        else
        {
            PSPath = PS5;
        }       
        arguments = $"-NoProfile -ExecutionPolicy Bypass -windowstyle hidden -NoLogo -file \"{installpath}\"";
        foreach (string arg in args)
        {
            if (File.Exists(arg) && !args.Contains("-MediaFile"))
            {
                arguments += $" -MediaFile \"{arg}\"";
            }
            else if (arg == "-UsePS5")
            {
                PSPath = PS5;
            }
            else
            {
                arguments += $" {arg}";
            }

        }
        sb.Append(Environment.NewLine + $"[{DateTime.Now}] >>>> Launching powershell from path: {PSPath} -- Arguments: {arguments}");
        pro.StartInfo.FileName = PSPath;
        pro.StartInfo.Arguments = arguments;
        pro.StartInfo.CreateNoWindow = true;
        pro.StartInfo.WorkingDirectory = installfolder;
        pro.StartInfo.UseShellExecute = false;
        pro.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
        //Console.Write(arguments);
        pro.Start();
        if (args.Contains("-Uninstall"))
        {
            pro.WaitForExit();
        }
        pro.Dispose();
    }
    else
    {
        sb.Append(Environment.NewLine + $"[{DateTime.Now}] [WARNING] Unable to find Samson install path: {installpath}");
    }
    // write to log
    File.AppendAllText(logfile, $"{sb.ToString() + Environment.NewLine}", Encoding.Unicode);
    sb.Clear();
    Environment.Exit(0);
}

RunPowershell(args);
