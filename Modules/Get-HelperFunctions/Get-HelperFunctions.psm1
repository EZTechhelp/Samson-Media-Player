<#
    .Name
    Get-HelperFunctions

    .Version 
    0.1.0

    .SYNOPSIS
    Collection of various helper functions for tasks like conversions, matching...etc

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

Function ConvertTo-OrderedDictionary {
  <#
      .SYNOPSIS
      Converts a HashTable, Array, or an OrderedDictionary to an OrderedDictionary.
 
      .DESCRIPTION
      ConvertTo-OrderedDictionary takes a HashTable, Array, or an OrderedDictionary
      and returns an ordered dictionary.
 
      If you enter a hash table, the keys in the hash table are ordered
      alphanumerically in the dictionary. If you enter an array, the keys
      are integers 0 - n.
      .PARAMETER $Hash
      Specifies a hash table or an array. Enter the hash table or array,
      or enter a variable that contains a hash table or array. If the input
      is an OrderedDictionary the key order is the same in the copy.
      .INPUTS
      System.Collections.Hashtable
      System.Array
      System.Collections.Specialized.OrderedDictionary
      .OUTPUTS
      System.Collections.Specialized.OrderedDictionary
      .NOTES
      source: https://gallery.technet.microsoft.com/scriptcenter/ConvertTo-OrderedDictionary-cf2404ba
      converted to function and added ability to copy OrderedDictionary
 
      .EXAMPLE
      PS C:\> $myHash = @{a=1; b=2; c=3}
      PS C:\> .\ConvertTo-OrderedDictionary.ps1 -Hash $myHash
 
      Name Value
      ---- -----
      a 1
      b 2
      c 3
      .EXAMPLE
      PS C:\> $myHash = @{a=1; b=2; c=3}
      PS C:\> $myHash = .\ConvertTo-OrderedDictionary.ps1 -Hash $myHash
      PS C:\> $myHash
 
      Name Value
      ---- -----
      a 1
      b 2
      c 3
 
      PS C:\> $myHash | Get-Member
 
      TypeName: System.Collections.Specialized.OrderedDictionary
      . . .
 
      .EXAMPLE
      PS C:\> $colors = "red", "green", "blue"
      PS C:\> $colors = .\ConvertTo-OrderedDictionary.ps1 -Hash $colors
      PS C:\> $colors
 
      Name Value
      ---- -----
      0 red
      1 green
      2 blue
      .LINK
      about_hash_tables
  #>

  #Requires -Version 3

  [CmdletBinding(ConfirmImpact='None')]
  [OutputType('System.Collections.Specialized.OrderedDictionary')]
  Param (
    [parameter(Mandatory,HelpMessage='Add help message for user', ValueFromPipeline)]
    $Hash
  )

  begin {
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
  } #close begin block

  process {
    write-verbose -Message ($Hash.gettype())
    if ($Hash -is [System.Collections.Hashtable])
    {
      write-verbose -Message '$Hash is a HashTable'
      $dictionary = [ordered] @{}
      $keys = $Hash.keys | sort-object
      foreach ($key in $keys)
      {
        $dictionary.add($key, $Hash[$key])
      }
      $dictionary
    }
    elseif ($Hash -is [System.Array])
    {
      write-verbose -Message '$Hash is an Array'
      $dictionary = [ordered] @{}
      for ($i = 0; $i -lt $hash.count; $i++)
      {
        $dictionary.add($i, $hash[$i])
      }
      $dictionary
    }
    elseif ($Hash -is [System.Collections.Specialized.OrderedDictionary])
    {
      write-verbose -Message '$Hash is an OrderedDictionary'
      $dictionary = [ordered] @{}
      $keys = $Hash.keys
      foreach ($key in $keys)
      {
        $dictionary.add($key, $Hash[$key])
      }
      $dictionary
    }
    else
    {
      Write-Error -Message 'Enter a hash table, an array, or an ordered dictionary.'
    }
  }

  end {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
  } #close end block

} #EndFunction ConvertTo-OrderedDictionary

#---------------------------------------------- 
#region Convert-Color Function
#----------------------------------------------
function Convert-Color {
  <#
      .Synopsis
      This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
      .Description
      This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
      .Parameter RBG
      Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
      .Parameter HEX
      Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
      .Example
      .\convert-color -hex FFFFFF
      Converts hex value FFFFFF to RGB
 
      .Example
      .\convert-color -RGB 123,200,255
      Converts Red = 123 Green = 200 Blue = 255 to Hex value
 
  #>
  param(
    [Parameter(ParameterSetName = "RGB", Position = 0)]
    [ValidateScript( {$_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$'})]
    $RGB,
    [Parameter(ParameterSetName = "HEX", Position = 0)]
    [ValidateScript( {$_ -match '[A-Fa-f0-9]{6}'})]
    [string]
    $HEX
  )
  switch ($PsCmdlet.ParameterSetName) {
    "RGB" {
      if ($RGB[2] -eq $null) {
        Write-error "Value missing. Please enter all three values seperated by comma."
      }
      $red = [convert]::Tostring($RGB[0], 16)
      $green = [convert]::Tostring($RGB[1], 16)
      $blue = [convert]::Tostring($RGB[2], 16)
      if ($red.Length -eq 1) {
        $red = '0' + $red
      }
      if ($green.Length -eq 1) {
        $green = '0' + $green
      }
      if ($blue.Length -eq 1) {
        $blue = '0' + $blue
      }
      Write-Output $red$green$blue
    }
    "HEX" {
      $red = $HEX.Remove(2, 4)
      $Green = $HEX.Remove(4, 2)
      $Green = $Green.remove(0, 2)
      $Blue = $hex.Remove(0, 4)
      $Red = [convert]::ToInt32($red, 16)
      $Green = [convert]::ToInt32($green, 16)
      $Blue = [convert]::ToInt32($blue, 16)
      Write-Output $red, $Green, $blue
    }
  }
}
#---------------------------------------------- 
#endregion Convert-Color Function
#----------------------------------------------

#---------------------------------------------- 
#region ConvertFrom-Roman Function
#----------------------------------------------
function ConvertFrom-Roman {
  <#
      .EXAMPLE
      ConvertFrom-Roman XLVII # 47
      .EXAMPLE
      'dlxxvii' | ConvertFrom-Roman # 577
      .EXAMPLE
      ('mmxx', 'cdxxix', 'di').ForEach{ConvertFrom-Roman $_} # 2020, 429, 501
  #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [ValidatePattern('^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$')]
    [ValidateNotNullOrEmpty()]
    [String]$Number,
    [string]$String_With_Number,
    [switch]$Verboselog
  )
  process {
    if($verboselog){write-ezlogs ">>>> Checking and converting Roman Numerals in $String_With_Number" -showtime -enablelogs -color cyan}
    if($String_With_Number -match '\b(?=[MDCLXVI]+\b)M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\b'){
      $number = $($matches[0])
      if($verboselog){write-ezlogs "Found Roman Numeral $number" -showtime -enablelogs}
      $map = @{I = 1; V = 5; X = 10; L = 50; C = 100; D = 500; M = 1000}
      for ($i, $a = 0, [Char[]]$Number; $i -lt $a.Length; $i++) {
        ${<}, ${>} = "$($a[$i])", "$($a[$i + 1])"
        $dec += [Int64]"$('+-'[$i + 1 -lt $a.Length -and $map[${<}] -lt $map[${>}]])$($map[${<}])"
      }
      if($verboselog){write-ezlogs " | Converted Roman Numeral $number to $dec" -showtime -enablelogs}
      $Coverted_String_With_Number = if($String_With_Number -match '\b(?=[MDCLXVI]+\b)M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\b'){$String_With_Number -replace $matches[0],$dec}
      if($verboselog){write-ezlogs " | Converted string $String_With_Number to $Coverted_String_With_Number" -showtime -enablelogs}
      return $Coverted_String_With_Number
    }
    else{
      if($verboselog){write-ezlogs "No Roman Numerals found in string" -showtime -enablelogs -warning}
      return
    }

  }
}
#---------------------------------------------- 
#endregion ConvertFrom-Roman Function
#----------------------------------------------
#---------------------------------------------- 
#region Grant Ownership Function
#----------------------------------------------
function Grant-Ownership {
  param(
    [String]$Folder,
    [String]$GroupToAdd
  )
  write-color -text ">>>> Attempting to Take Ownership of folder $Folder" -showtime -color cyan
  $takedown_results = takeown.exe /A /F $Folder
  write-color -text "$takedown_results" -showtime
  $CurrentACL = Get-Acl $Folder
  write-color -text "Adding NT Authority\SYSTEM to $Folder" -showtime
  $SystemACLPermission = "NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow"
  $SystemAccessRule = new-object System.Security.AccessControl.FileSystemAccessRule $SystemACLPermission
  Add-NTFSAccess -Path $Folder -Account "NT AUTHORITY\SYSTEM" -AccessRights FullControl -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles -PassThru
  write-color -text "Adding BUILTIN\Administrators to $Folder" -showtime
  Add-NTFSAccess -Path $Folder -Account "BUILTIN\Administrators" -AccessRights FullControl -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles -PassThru
  #$CurrentACL.AddAccessRule($SystemAccessRule)

  if($GroupToAdd)
  {
    write-color -text "Adding $GroupToAdd to $Folder" -showtime
    $AdminACLPermission = $GroupToAdd,"FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $SystemAccessRule = new-object System.Security.AccessControl.FileSystemAccessRule $AdminACLPermission
    Add-NTFSAccess -Path $Folder -Account $GroupToAdd -AccessRights FullControl -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles -PassThru
    #$CurrentACL.AddAccessRule($SystemAccessRule)
  }
  #Set-Acl -Path $Folder -AclObject $CurrentACL
}
#---------------------------------------------- 
#endregion Grant Ownership Function
#----------------------------------------------


#---------------------------------------------- 
#region Test Folder Function
#----------------------------------------------
function Test-Folder($FolderToTest)
{
  write-color -text "`n#### Performing Access Tests on $FolderToTest ####" -color yellow
  $error.Clear()
  $ErrorArray = @()
  $testresults = Get-ChildItem $FolderToTest -Recurse -ErrorAction SilentlyContinue | Select FullName, Attributes
  $testdelete_results = Remove-Item $FolderToTest -Force -Recurse -ErrorAction SilentlyContinue
  #Get-Acl $FolderToTest 
  if ($error) {
    $ErrorArray = $error + $ErrorArray
    foreach ($err in $ErrorArray) {
      write-color -text "`n>>>> Attemping to fix $($err.TargetObject)" -color yellow
      write-color -text "Error: $($err)" -color red -showtime
      if($err.FullyQualifiedErrorId -eq "DirUnauthorizedAccessError,Microsoft.PowerShell.Commands.GetChildItemCommand" -or $err.FullyQualifiedErrorId -eq "RemoveFileSystemItemArgumentError,Microsoft.PowerShell.Commands.RemoveItemCommand") {
        #write-color -text "Unable to access $($err.TargetObject)" -color red -showtime
        #write-color -text "Attempting to take ownership of $($err.TargetObject)" -color red -showtime
        Grant-Ownership -folder $err.TargetObject
      }
      if ($err.FullyQualifiedErrorId -eq "DirIOError,Microsoft.PowerShell.Commands.GetChildItemCommand")
      {
        write-color -text ">>>> Attempting to delete reparsepoints" -color cyan
        fsutil reparsepoint delete $err.TargetObject
        #Rename-Item $($err.TargetObject) $($err.TargetObject + "deleteme") -Force -ErrorAction Continue
      }
      write-color -text ">>>> Retrying Permission Test on $($err.TargetObject) ####" -color cyan -showtime
      $error.Clear()
      $ErrorArray = @()
      $testresults2 = Get-ChildItem $($FolderToTest) -Recurse -ErrorAction SilentlyContinue | Select FullName, Attributes
      if (!$error)
      {
        write-color -text "Repair was successfull" -color green -showtime
        return "Repair was successfull"
      }
      else
      {
        write-color -text "Error: Unable to repair issues with $($err.TargetObject) - Error: $($err)" -color red -showtime
      }
    }
  }
  else
  {
    write-color -text "No permission errors were detected for $FolderToTest" -showtime -color green
  }
}
#---------------------------------------------- 
#endregion Test Folder Function
#----------------------------------------------

#---------------------------------------------- 
#region Get MSI Properties
#----------------------------------------------
function Get-MSIProperties
{
  param(

    [parameter(Mandatory=$true)]

    [ValidateNotNullOrEmpty()] [System.IO.FileInfo]$Path,

    [parameter(Mandatory=$true)]

  [ValidateNotNullOrEmpty()] [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion")] [string]$Property ) 

  Process { 
    try { 
      # Read property from MSI database 
      $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer 
      $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0)) 
      $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'" 
      $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query)) 
      $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null) 
      $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null) 
      $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1) 
      # Commit database and close view 
      $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null) 
      $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null) 
      $MSIDatabase = $null 
      $View = $null 
      # Return the value return 
      $Value 
    } 
    catch 
    { 
      Write-Warning -Message $_.Exception.Message ; break 
  } } 
  End 
  { 
    # Run garbage collection and release ComObject 
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null 
  [System.GC]::Collect() } 
}
#---------------------------------------------- 
#endregion Get MSI Properties
#----------------------------------------------

#---------------------------------------------- 
#region Test-URL Function
#----------------------------------------------
function Test-URL
{
  Param(
    $address,
    [switch]$TestConnection,
    [int]$timeout_milsec
  )
  $uri = $address -as [System.URI]
  if($uri.AbsoluteURI -ne $null -and $uri.Scheme -match 'http|https'){
    if($TestConnection){
      Try{
        $HTTPRequest = [System.Net.WebRequest]::Create($address)
        if($timeout_milsec){
          $HTTPRequest.Timeout = $timeout_milsec
        }
        $HTTPResponse = $HTTPRequest.GetResponse()
        $HTTPStatus = [Int]$HTTPResponse.StatusCode
        
        If($HTTPStatus -ne 200 -and $HTTPStatus -ne 401) {
          Return $False
        }
        $HTTPResponse.Close()
      }
      Catch{
        if($_ -match '\(401\) Unauthorized'){
          return $true
        }else{
          Return $False
        }
      }	
      Return $True    
    }
    else{
      Return $true
    }    
  }
  else{
    return $false
  }
}
#---------------------------------------------- 
#endregion Test-URL Function
#----------------------------------------------

#---------------------------------------------- 
#region Open-FolderDialog Function
#----------------------------------------------
function Open-FolderDialog
{
  param (
    [string]$Title,
    [switch]$MultiSelect,
    $Calling_Window,
    [switch]$ShowFiles,
    [string]$InitialDirectory
  )
  if([string]::IsNullOrEmpty($InitialDirectory)){
    $path = 'file:'
  }else{
    $path = $InitialDirectory
  }
  if($MultiSelect){
    $MultiSelect_arg = "true"
  }else{
    $MultiSelect_arg = "true"
  }  
  try{
    $message = $args[2]
    if($psversiontable.psversion.major -gt 5){
      $source = @"
using System;
using System.Diagnostics;
using System.Reflection;
using System.Windows.Forms;
/// <summary>
/// Present the Windows Vista-style open file dialog to select a folder. Fall back for older Windows Versions
/// </summary>
#pragma warning disable 0219, 0414, 0162
public class FolderSelectDialog {
    private string _initialDirectory;
    private string _title;
    private string _message;
    private string _fileName = "";
    
    public string InitialDirectory {
        get { return string.IsNullOrEmpty(_initialDirectory) ? Environment.CurrentDirectory : _initialDirectory; }
        set { _initialDirectory = value; }
    }
    public string Title {
        get { return _title ?? "Select a folder"; }
        set { _title = value; }
    }
    public string Message {
        get { return _message ?? _title ?? "Select a folder"; }
        set { _message = value; }
    }
    public string FileName { get { return _fileName; } }

    public FolderSelectDialog(string defaultPath="MyComputer", string title="Select a folder", string message=""){
        InitialDirectory = defaultPath;
        Title = title;
        Message = message;
    }
    
    public bool Show() { return Show(IntPtr.Zero); }

    /// <param name="hWndOwner">Handle of the control or window to be the parent of the file dialog</param>
    /// <returns>true if the user clicks OK</returns>
    public bool Show(IntPtr? hWndOwnerNullable=null) {
        IntPtr hWndOwner = IntPtr.Zero;
        if(hWndOwnerNullable!=null)
            hWndOwner = (IntPtr)hWndOwnerNullable;
        if(Environment.OSVersion.Version.Major >= 6){
            try{
                var resulta = VistaDialog.Show(hWndOwner, InitialDirectory, Title, Message);
                _fileName = resulta.FileName;
                return resulta.Result;
            }
            catch(Exception){
                var resultb = ShowXpDialog(hWndOwner, InitialDirectory, Title, Message);
                _fileName = resultb.FileName;
                return resultb.Result;
            }
        }
        var result = ShowXpDialog(hWndOwner, InitialDirectory, Title, Message);
        _fileName = result.FileName;
        return result.Result;
    }

    private struct ShowDialogResult {
        public bool Result { get; set; }
        public string FileName { get; set; }
    }

    private static ShowDialogResult ShowXpDialog(IntPtr ownerHandle, string initialDirectory, string title, string message) {
        var folderBrowserDialog = new FolderBrowserDialog {
            Description = message,
            SelectedPath = initialDirectory,
            ShowNewFolderButton = true
        };
        var dialogResult = new ShowDialogResult();
        if (folderBrowserDialog.ShowDialog(new WindowWrapper(ownerHandle)) == DialogResult.OK) {
            dialogResult.Result = true;
            dialogResult.FileName = folderBrowserDialog.SelectedPath;
        }
        return dialogResult;
    }

    private static class VistaDialog {
        private const string c_foldersFilter = "Folders|\n";
        
        private const BindingFlags c_flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
        private readonly static Assembly s_windowsFormsAssembly = typeof(FileDialog).Assembly;
        private readonly static Type s_iFileDialogType = s_windowsFormsAssembly.GetType("System.Windows.Forms.FileDialogNative+IFileDialog");
        private readonly static MethodInfo s_createVistaDialogMethodInfo = typeof(OpenFileDialog).GetMethod("CreateVistaDialog", c_flags);
        private readonly static MethodInfo s_onBeforeVistaDialogMethodInfo = typeof(OpenFileDialog).GetMethod("OnBeforeVistaDialog", c_flags);
        private readonly static MethodInfo s_getOptionsMethodInfo = typeof(FileDialog).GetMethod("GetOptions", c_flags);
        private readonly static MethodInfo s_setOptionsMethodInfo = s_iFileDialogType.GetMethod("SetOptions", c_flags);
        private readonly static uint s_fosPickFoldersBitFlag = (uint) s_windowsFormsAssembly
            .GetType("System.Windows.Forms.FileDialogNative+FOS")
            .GetField("FOS_PICKFOLDERS")
            .GetValue(null);
        private readonly static ConstructorInfo s_vistaDialogEventsConstructorInfo = s_windowsFormsAssembly
            .GetType("System.Windows.Forms.FileDialog+VistaDialogEvents")
            .GetConstructor(c_flags, null, new[] { typeof(FileDialog) }, null);
        private readonly static MethodInfo s_adviseMethodInfo = s_iFileDialogType.GetMethod("Advise");
        private readonly static MethodInfo s_unAdviseMethodInfo = s_iFileDialogType.GetMethod("Unadvise");
        private readonly static MethodInfo s_showMethodInfo = s_iFileDialogType.GetMethod("Show");

        public static ShowDialogResult Show(IntPtr ownerHandle, string initialDirectory, string title, string description) {
            var openFileDialog = new OpenFileDialog {
                AddExtension = false,
                CheckFileExists = false,
                DereferenceLinks = true,
                Filter = c_foldersFilter,
                InitialDirectory = initialDirectory,
                Multiselect = $MultiSelect_arg,
                Title = title
            };

            var iFileDialog = s_createVistaDialogMethodInfo.Invoke(openFileDialog, new object[] { });
            s_onBeforeVistaDialogMethodInfo.Invoke(openFileDialog, new[] { iFileDialog });
            s_setOptionsMethodInfo.Invoke(iFileDialog, new object[] { (uint) s_getOptionsMethodInfo.Invoke(openFileDialog, new object[] { }) | s_fosPickFoldersBitFlag });
            var adviseParametersWithOutputConnectionToken = new[] { s_vistaDialogEventsConstructorInfo.Invoke(new object[] { openFileDialog }), 0U };
            s_adviseMethodInfo.Invoke(iFileDialog, adviseParametersWithOutputConnectionToken);

            try {
                int retVal = (int) s_showMethodInfo.Invoke(iFileDialog, new object[] { ownerHandle });
                return new ShowDialogResult {
                    Result = retVal == 0,
                    FileName = openFileDialog.FileName
                };
            }
            finally {
                s_unAdviseMethodInfo.Invoke(iFileDialog, new[] { adviseParametersWithOutputConnectionToken[1] });
            }
        }
    }

    // Wrap an IWin32Window around an IntPtr
    private class WindowWrapper : IWin32Window {
        private readonly IntPtr _handle;
        public WindowWrapper(IntPtr handle) { _handle = handle; }
        public IntPtr Handle { get { return _handle; } }
    }
    
    public string getPath(){
        if (Show()){
            return FileName;
        }
        return "";
    }
}
"@
      Add-Type -Language CSharp -TypeDefinition $source -ReferencedAssemblies ("System.Windows.Forms", "System.ComponentModel.Primitives")
      $Result = ([FolderSelectDialog]::new($path, $title, $message)).getPath()
      if ($Result) 
      {
        return $Result
      }
    }
    else{

      $browse = New-object WK.Libraries.BetterFolderBrowserNS.BetterFolderBrowser
      $browse.title = $Title
      $browse.RootFolder = $path
      if($MultiSelect){
        $browse.Multiselect = $true
      }else{
        $browse.Multiselect = $false
      }
      if($Calling_Window){
        $dialogResult = $browse.ShowDialog($Calling_Window)
      }else{
        $dialogResult = $browse.ShowDialog()
      }
      if ($dialogResult -eq 'OK') 
      {
        if($MultiSelect){
          return [array]$browse.SelectedFolders
        }else{
          return $browse.SelectedFolder
        }  
      }


    }
  
 

  }catch{
    write-ezlogs "An exception occurred displaying Open-FolderDialog" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Open-FolderDialog Function
#----------------------------------------------

#---------------------------------------------- 
#region Open-FileDialog Function
#----------------------------------------------
function Open-FileDialog
{
  param (
    [string]$Title = "Select file",
    [switch]$MultiSelect
  )  
  $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
  $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.AddExtension = $true
  #$OpenFileDialog.InitialDirectory = [environment]::getfolderpath('mydocuments')
  $OpenFileDialog.CheckFileExists = $true
  $OpenFileDialog.Multiselect = $MultiSelect
  $OpenFileDialog.Filter = "All Files (*.*)|*.*"
  $OpenFileDialog.CheckPathExists = $false
  $OpenFileDialog.Title = $Title
  $results = $OpenFileDialog.ShowDialog()
  if ($results -eq [System.Windows.Forms.DialogResult]::OK) 
  {
    Write-Output $OpenFileDialog.FileNames
  }
}
#---------------------------------------------- 
#endregion Open-FileDialog Function
#----------------------------------------------

#---------------------------------------------- 
#region Test Stuff
#----------------------------------------------
function New-Runspacetest {
  [cmdletbinding()]
  param ([int] $minRunspaces = 1,
  [int] $maxRunspaces = [int]$env:NUMBER_OF_PROCESSORS + 1)
  $RunspacePool = [RunspaceFactory]::CreateRunspacePool($minRunspaces, $maxRunspaces)
  $RunspacePool.Open()
  return $RunspacePool
}
function Start-Runspacetest {
  [cmdletbinding()]
  param ([ScriptBlock] $ScriptBlock,
    [System.Collections.IDictionary] $Parameters,
  [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool)
  if ($ScriptBlock -ne '') {
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($ScriptBlock)
    if ($null -ne $Parameters) { $null = $runspace.AddParameters($Parameters) }
    $runspace.RunspacePool = $RunspacePool
    [PSCustomObject]@{Pipe = $runspace
      Status             = $runspace.BeginInvoke()
    }
  }
}
function Stop-Runspacetest {
  [cmdletbinding()]
  param([Array] $Runspaces,
    [string] $FunctionName,
    [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool,
  [switch] $ExtendedOutput)
  [Array] $List = While (@($Runspaces | Where-Object -FilterScript { $null -ne $_.Status }).count -gt 0) {
    foreach ($Runspace in $Runspaces | Where-Object { $_.Status.IsCompleted -eq $true }) {
      $Errors = foreach ($e in $($Runspace.Pipe.Streams.Error)) {
        Write-Error -ErrorRecord $e
        $e
      }
      foreach ($w in $($Runspace.Pipe.Streams.Warning)) { Write-Warning -Message $w }
      foreach ($v in $($Runspace.Pipe.Streams.Verbose)) { Write-Verbose -Message $v }
      if ($ExtendedOutput) {
        @{Output   = $Runspace.Pipe.EndInvoke($Runspace.Status)
          Errors = $Errors
        }
      } else { $Runspace.Pipe.EndInvoke($Runspace.Status) }
      $Runspace.Status = $null
    }
  }
  $RunspacePool.Close()
  $RunspacePool.Dispose()
  if ($List.Count -eq 1) { return , $List } else { return $List }
}
function New-ScriptBlockCallback {
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$Callback
  )
  <#
      .SYNOPSIS
      Allows running ScriptBlocks via .NET async callbacks.
 
      .DESCRIPTION
      Allows running ScriptBlocks via .NET async callbacks. Internally this is
      managed by converting .NET async callbacks into .NET events. This enables
      PowerShell 2.0 to run ScriptBlocks indirectly through Register-ObjectEvent.         
 
      .PARAMETER Callback
      Specify a ScriptBlock to be executed in response to the callback.
      Because the ScriptBlock is executed by the eventing subsystem, it only has
      access to global scope. Any additional arguments to this function will be
      passed as event MessageData.
         
      .EXAMPLE
      You wish to run a scriptblock in reponse to a callback. Here is the .NET
      method signature:
         
      void Bar(AsyncCallback handler, int blah)
         
      ps> [foo]::bar((New-ScriptBlockCallback { ... }), 42)                        
 
      .OUTPUTS
      A System.AsyncCallback delegate.
  #>
  # is this type already defined?    
  if (-not ("CallbackEventBridge" -as [type])) {
    Add-Type @"
            using System;
             
            public sealed class CallbackEventBridge
            {
                public event AsyncCallback CallbackComplete = delegate { };
 
                private CallbackEventBridge() {}
 
                private void CallbackInternal(IAsyncResult result)
                {
                    CallbackComplete(result);
                }
 
                public AsyncCallback Callback
                {
                    get { return new AsyncCallback(CallbackInternal); }
                }
 
                public static CallbackEventBridge Create()
                {
                    return new CallbackEventBridge();
                }
            }
"@
  }
  $bridge = [callbackeventbridge]::create()
  Register-ObjectEvent -input $bridge -EventName callbackcomplete -action $callback -messagedata $args > $null
  $bridge.callback
}
#---------------------------------------------- 
#endregion Test Stuff
#----------------------------------------------

#---------------------------------------------- 
#region Show-NotifyBallon Function
#----------------------------------------------
function Show-NotifyBalloon
{
  param (
    [string]$Message,
    [string]$Title,
    [validateset("Info","Error","None","Warning")]
    [string]$TipIcon,
    $thisApp,
    [string]$Icon_path,
    [int]$Timeout,
    [System.EventHandler]$Click_Command
  )
  if($Balloon){
    $Balloon.dispose()
  }
  $null = [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')     
  Remove-Event BalloonClicked_event -ea SilentlyContinue
  Unregister-Event -SourceIdentifier BalloonClicked_event -ea silentlycontinue
  Remove-Event BalloonClosed_event -ea SilentlyContinue
  Unregister-Event -SourceIdentifier BalloonClosed_event -ea silentlycontinue      
  $Global:Balloon = New-Object System.Windows.Forms.NotifyIcon     
  if($TipIcon){
    #$image_bytes = [System.IO.File]::ReadAllBytes($icon_path)
    #$stream_image = [System.IO.MemoryStream]::new($image_bytes)        
    #$baloon_icon = [System.Drawing.Image]::FromStream($stream_image)     
    $Balloon.BalloonTipIcon = $TipIcon
    #$Balloon.Icon = $icon_path 
  }else{
    <#    $imagecontrol = New-Object MahApps.Metro.IconPacks.PackIconBootstrapIcons
        $imagecontrol.width = "16"
        $imagecontrol.Height = "16"
        $imagecontrol.Kind = "MusicPlayerFill"
    $imagecontrol.Foreground = 'White'#>  
    #$Balloon.Icon =  [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $pid | Select-Object -ExpandProperty Path)) 
    $Balloon.BalloonTipIcon =  = "$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.ico"
  }              
  $Balloon.BalloonTipText = $Message          
  $Balloon.BalloonTipTitle = $Title     
  $Balloon.Visible = $true 
  
  [System.EventHandler]$balloonTipClick_Command  = {
    param($sender)
    try{
      $Balloon.Visible = $False
      $Balloon.dispose()
      if($thisapp.Config.Verbose_logging){write-ezlogs ">>> Balloon notification was clicked and disposed" -showtime}
    }catch{
      write-ezlogs "Exception BalloonTipClicked event" -showtime -catcherror $_
    }
  }.GetNewClosure()
 
  if($Click_Command){
    $balloon.Add_BalloonTipClicked($Click_Command)
  }else{
    $balloon.Add_BalloonTipClicked($balloonTipClick_Command)
  }

  #Balloon message closed
  $balloon.Add_BalloonTipClosed({
      try{
        #$Install_hash.Window.Dispatcher.invoke([action]{
        $Balloon.Visible = $False
        $Balloon.dispose()
        #})
      }catch{
        write-ezlogs "Exception BalloonTipClosed event" -showtime -catcherror $_
      }
  })  
  
  if($Timeout){
    $Balloon.ShowBalloonTip($Timeout)
  }else{
    $Balloon.ShowBalloonTip(1000)
  }           
}
#---------------------------------------------
#endregion Show-NotifyBallon Function
#---------------------------------------------

#--------------------------------------------- 
#region Get-CurrentWindow Function
#---------------------------------------------
function Get-CurrentWindow {
  <#
      .LINK
      https://stackoverflow.com/questions/46351885/how-to-grab-the-currently-active-foreground-window-in-powershell
  #>

  param(

  )

  Begin {

    Add-Type  @"
 using System;
 using System.Runtime.InteropServices;
 using System.Text;
public class APIFuncs
   {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
   public static extern int GetWindowText(IntPtr hwnd,StringBuilder
lpString, int cch);
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
   public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
       public static extern Int32 GetWindowThreadProcessId(IntPtr hWnd,out
Int32 lpdwProcessId);
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
       public static extern Int32 GetWindowTextLength(IntPtr hWnd);
    }
"@
  }

  Process {
    $w = [apifuncs]::GetForegroundWindow()
    $len = [apifuncs]::GetWindowTextLength($w)
    $sb = New-Object text.stringbuilder -ArgumentList ($len + 1)
    $rtnlen = [apifuncs]::GetWindowText($w,$sb,$sb.Capacity)
    return $($sb.tostring())
  }
}
#--------------------------------------------- 
#endregion Get-CurrentWindow Function
#---------------------------------------------

function Test-KeyPress
{
  <#
      .SYNOPSIS
      Tests whether keys are currently pressed

      .DESCRIPTION
      Returns $true when ALL of the submitted keys are currently pressed.
      Uses API calls and does not rely on the console. It works in all PowerShell Hosts
      including ISE and VSCode/EditorServices        

      .EXAMPLE
      Test-PsOneKeyPress -Key A,B -SpecialKey Control,ShiftLeft -Wait
      returns once the keys A, B, Control and left Shift were simultaneously pressed

      .EXAMPLE
      Test-PsOneKeyPress -SpecialKey Control -Wait -Timeout 00:00:05 -ShowProgress
      returns once the keys A, B, Control and left Shift were simultaneously pressed

      .EXAMPLE
      Test-PSOneKeyPress -Key Escape -Timeout '00:00:20' -Wait -ShowProgress
      wait for user to press ESC, and timeout after 20 seconds

      .EXAMPLE
      Test-PSOneKeyPress -Key H -SpecialKey Alt,Shift -Wait -ShowProgress
      wait for Alt+Shift+H

      .LINK
      https://powershell.one
  #>
    
  [CmdletBinding(DefaultParameterSetName='test')]
  param
  (
    # regular key, can be a comma-separated list
    [Parameter(ParameterSetName='wait')]
    [Parameter(ParameterSetName='test')]
    [ConsoleKey[]]
    $Key = $null,

    # special key, can be a comma-separated list
    [Parameter(ParameterSetName='wait')]
    [Parameter(ParameterSetName='test')]
    [ValidateSet('Alt','CapsLock','Control','ControlLeft','ControlRight','LeftMouseButton','MiddleMouseButton', 'RightMouseButton','NumLock','Shift','ShiftLeft','ShiftRight','MouseWheel')]
    [string[]]
    $SpecialKey = $null,
    
    # waits for the key combination to be pressed
    [Parameter(Mandatory,ParameterSetName='wait')]
    [switch]
    $Wait,
    
    # timeout (timespan) for the key combination to be pressed
    [Parameter(ParameterSetName='wait')]
    [Timespan]
    $Timeout=[Timespan]::Zero,
    
    # show progress
    [Parameter(ParameterSetName='wait')]
    [Switch]
    $ShowProgress
  )
    
  # at least one key is mandatory:
  if (($Key.Count + $SpecialKey.Count) -lt 1)
  {
    throw "No key specified."
  }
  # use a hashtable to translate string values to integers
  # this could have also been done using a enumeration
  # however if a parameter is using a enumeration as type,
  # the enumeration must be defined before the function
  # can be called. 
  # My goal was to create a hassle-free stand-alone function,
  # so enumerations were no option
  $converter = @{
    Shift = 16
    ShiftLeft = 160
    ShiftRight = 161
    Control = 17
    Alt = 18
    CapsLock = 20
    ControlLeft = 162
    ControlRight = 163
    LeftMouseButton = 1
    RightMouseButton = 2
    MiddleMouseButton = 4
    MouseWheel = 145
    NumLock = 144
  }

  # create an array with ALL keys from BOTH groups
    
  # start with an integer list of regular keys 
  if ($Key.Count -gt 0)
  {
    $list = [System.Collections.Generic.List[int]]$Key.value__
  }
  else
  {
    $list = [System.Collections.Generic.List[int]]::new()
  }
  # add codes for all special characters
  foreach($_ in $SpecialKey)
  {
    $list.Add($converter[$_])
  }
  # $list now is a list of all key codes for all keys to test
    
  # access the windows api
  $Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

  # Add-Type compiles the source code and adds the type [PsOneApi.Keyboard]:
  Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi
    
  # was -Wait specified?
  $isNoWait = $PSCmdlet.ParameterSetName -ne 'wait'
  
  # do we need to watch a timeout?
  $hasTimeout = ($Timeout -ne [Timespan]::Zero) -and ($isNoWait -eq $false)
  if ($hasTimeout)
  {
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  }  
  
  # use a try..finally to clean up
  try
  {
    # use a counter
    $c = 0
    
    # if -Wait was specified, the loop repeats until
    # either the keys were pressed or the timeout is exceeded
    # else, the loop runs only once
    do
    {
      # increment counter
      $c++
      
      # test each key in $list. If any key returns $false, the total result is $false:
      foreach ($_ in $list)
      {
        $pressed = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($_) -eq -32767)
        # if there is a key NOT pressed, we can skip the rest and bail out 
        # because ALL keys need to be pressed
        if (!$pressed) { break }
      }
    
      # is the timeout exceeded?
      if ($hasTimeout)
      {
        if ($stopWatch.Elapsed -gt $Timeout)
        {
          throw "Waiting for keypress timed out."
        }
      }
      
      # show progress indicator? if so, only every second
      if ($ShowProgress -and ($c % 2 -eq 0))
      {
        Write-Host '.' -NoNewline
      }
      # if the keys were not pressed and the function waits for the keys,
      # sleep a little:
      if (!$isNoWait -and !$pressed)
      {
        Start-Sleep -Milliseconds 500
      }
    } until ($pressed -or $isNoWait)
  
    # if this is just checking the key states, return the result:
    if ($isNoWait)
    {
      return $pressed
    }
  }
  finally
  {
    if ($hasTimeout)
    {
      $stopWatch.Stop()    
    }
    if ($ShowProgress)
    {
      Write-Host
    }
  }
}
function Set-WindowState {
  <#
      .LINK
      https://gist.github.com/Nora-Ballard/11240204
  #>

  [CmdletBinding(DefaultParameterSetName = 'InputObject')]
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [Object[]] $InputObject,

    [Parameter(Position = 1)]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
        'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
    'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    [string] $State = 'SHOW',
    [switch] $SuppressErrors = $false,
    [switch] $SetForegroundWindow = $false
  )

  Begin {
    $WindowStates = @{
      'FORCEMINIMIZE'         = 11
      'HIDE'              = 0
      'MAXIMIZE'          = 3
      'MINIMIZE'          = 6
      'RESTORE'           = 9
      'SHOW'              = 5
      'SHOWDEFAULT'       = 10
      'SHOWMAXIMIZED'     = 3
      'SHOWMINIMIZED'     = 2
      'SHOWMINNOACTIVE'   = 7
      'SHOWNA'            = 8
      'SHOWNOACTIVATE'    = 4
      'SHOWNORMAL'        = 1
    }

    $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

    if (!$global:MainWindowHandles) {
      $global:MainWindowHandles = @{ }
    }
  }

  Process {
    foreach ($process in $InputObject | where {$_.MainWindowHandle -ne 0} ) {
      try{
        $handle = $process.MainWindowHandle
        if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
          $handle = $global:MainWindowHandles[$process.Id]
        }

        if ($handle -eq 0) {
          if (-not $SuppressErrors) {
            Write-ezlogs "Main Window handle is '0'...ignoring" -showtime
          }
          continue
        }elseif($WindowStates[$State] -ne $Null){
          $global:MainWindowHandles[$process.Id] = $handle
          $null = $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State])
          if ($SetForegroundWindow) {
            $Win32ShowWindowAsync::SetForegroundWindow($handle) | Out-Null
          }
          write-ezlogs $("Set Window State '{1} on '{0}'" -f $handle, $State) -showtime
          return
        }
      }catch{
        write-ezlogs "An exception occurred processing WindowHandle states for process $($process | out-string)" -showtime -catcherror $_
      }
    }
  }
}

function Add-WPFMenu {
  [CmdletBinding()]
  Param(
    $Control,
    $Items,
    $separator,
    $synchash,
    [switch]$addchild,
    [switch]$AddContextMenu
  )  
  <#  Param([Parameter(ValueFromPipeline = $true)]$Control,
  $Items,$separator,$addchild)#>
  process {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName PresentationFramework
    if($AddContextMenu){
      $contextMenu = New-Object System.Windows.Controls.ContextMenu
      $contextmenu.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty,$true)
      $contextmenu.SetValue([System.Windows.Controls.VirtualizingPanel]::IsVirtualizingProperty,$true)
      $contextmenu.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty,[System.Windows.Controls.VirtualizationMode]::Recycling)
      $contextmenu.SetValue([System.Windows.Controls.VirtualizingPanel]::VirtualizationModeProperty,[System.Windows.Controls.VirtualizationMode]::Recycling)
      $contextmenu.SetValue([System.Windows.Controls.ScrollViewer]::CanContentScrollProperty,$true)
    }
    foreach ($item in $items) {
      if($item.Separator){
        $menu_separator = New-object System.Windows.Controls.Separator
        $menu_separator.OpacityMask = $synchash.Window.TryFindResource($item.Style)
        if($addchild){
          $null = $control.AddChild($menu_separator)
        }else{
          $null = $contextMenu.Items.Add($menu_separator)
        }
      }else{
        $menuItem = new-object System.Windows.Controls.MenuItem -property @{Header = $item.Header}
        if(-not [string]::IsNullOrEmpty($item.Style)){
          $menuItem.Style = $synchash.Window.TryFindResource($item.Style)
        }
        if(-not [string]::IsNullOrEmpty($item.FontWeight)){
          $menuItem.FontWeight = $item.FontWeight
        }
        if(-not [string]::IsNullOrEmpty($item.FontStyle)){
          $menuItem.FontStyle = $item.FontStyle
        }                
        if(-not [string]::IsNullOrEmpty($item.ToolTip)){
          $menuItem.ToolTip = $item.ToolTip
        }
        $menuItem.Foreground = $item.color
        if(-not [string]::IsNullOrEmpty($item.BackGround)){
          $menuItem.BackGround = $item.BackGround
        }                
        #$menuItem.Style = $synchash.Window.TryFindResource("DropDownMenuItemStyle")
        $menuItem.IsEnabled = $item.enabled
        $menuItem.Tag = $control.datacontext
        if($Item.IsCheckable){
          $menuItem.IsCheckable = $Item.IsCheckable
        }elseif(-not [string]::IsNullOrEmpty($item.icon_kind)){
          if(-not [string]::IsNullOrEmpty($item.iconpack)){
            $iconpack = $item.iconpack
          }else{
            $iconpack = 'PackIconMaterial'
          }
          $menuItem_imagecontrol = New-Object MahApps.Metro.IconPacks.$iconpack
          $menuItem_imagecontrol.width = "16"
          $menuItem_imagecontrol.Height = "16"
          $menuItem_imagecontrol.Kind = $item.icon_kind
          $menuItem_imagecontrol.Foreground = $item.icon_color
          if(-not [string]::IsNullOrEmpty($item.icon_margin)){
            $menuItem_imagecontrol.margin = $item.icon_margin
          }
          $menuItem.icon = $menuItem_imagecontrol
        }elseif(-not [string]::IsNullOrEmpty($item.icon_image)){
          #$stream_image = [System.IO.File]::OpenRead($item.icon_image)
          #$image =  [System.Drawing.Image]::FromStream($stream_image)              
          $menuItem_imagecontrol = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes($item.icon_image)))
          if(-not [string]::IsNullOrEmpty($item.icon_margin)){
            $menuItem_imagecontrol.margin = $item.icon_margin
          }
          $menuItem.icon = $menuItem_imagecontrol
        }
        if(-not [string]::IsNullOrEmpty($item.tag)){
          $menuItem.tag = $item.tag
        }
        if(-not [string]::IsNullOrEmpty($item.Command)){
          $menuItem.Add_Click($item.Command)
        }
        if(-not [string]::IsNullOrEmpty($item.Sub_items)){
          foreach($subitem in $item.Sub_items){
            if($subitem.Separator){
              $menu_separator = New-object System.Windows.Controls.Separator
              $menu_separator.OpacityMask = $synchash.Window.TryFindResource($subitem.Style)
              $null = $menuItem.Items.Add($menu_separator)
            }else{
              $SubmenuItem = new-object System.Windows.Controls.MenuItem -property @{Header = $SubItem.header}
              if(-not [string]::IsNullOrEmpty($subitem.Style)){
                $SubmenuItem.Style = $synchash.Window.TryFindResource($subitem.Style)
              }
              if(-not [string]::IsNullOrEmpty($subitem.FontWeight)){
                $SubmenuItem.FontWeight = $subitem.FontWeight
              } 
              if(-not [string]::IsNullOrEmpty($subitem.FontStyle)){
                $SubmenuItem.FontStyle = $subitem.FontStyle
              }                           
              if(-not [string]::IsNullOrEmpty($subitem.ToolTip)){
                $SubmenuItem.ToolTip = $subitem.ToolTip
              }
              if(-not [string]::IsNullOrEmpty($subitem.ForegroundStyle)){
                $SubmenuItem.Foreground = $synchash.Window.TryFindResource($subitem.ForegroundStyle)
              }else{
                $SubmenuItem.Foreground = $subitem.color
              }
              if(-not [string]::IsNullOrEmpty($subitem.tag)){
                $SubmenuItem.tag = $subitem.tag
              }
              if(-not [string]::IsNullOrEmpty($subitem.BackGround)){
                $SubmenuItem.BackGround = $subitem.BackGround
              }
              #$SubmenuItem.Style = $synchash.Window.TryFindResource("DropDownMenuItemStyle")
              $SubmenuItem.IsEnabled = $subitem.enabled
              if($SubItem.IsCheckable){
                $SubmenuItem.IsCheckable = $SubItem.IsCheckable
              }elseif(-not [string]::IsNullOrEmpty($Subitem.icon_kind)){
                if(-not [string]::IsNullOrEmpty($Subitem.iconpack)){
                  $iconpack = $Subitem.iconpack
                }else{
                  $iconpack = 'PackIconMaterial'
                }
                $SubmenuItem_imagecontrol = New-Object MahApps.Metro.IconPacks.$iconpack
                $SubmenuItem_imagecontrol.width = "16"
                $SubmenuItem_imagecontrol.Height = "16"
                $SubmenuItem_imagecontrol.Kind = $Subitem.icon_kind
                $SubmenuItem_imagecontrol.Foreground = $Subitem.icon_color
                if($Subitem.icon_margin){
                  $SubmenuItem_imagecontrol.margin = $Subitem.icon_margin
                }      
                $SubmenuItem.icon = $SubmenuItem_imagecontrol
              }elseif(-not [string]::IsNullOrEmpty($Subitem.icon_image)){                      
                $SubmenuItem_imagecontrol = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes($Subitem.icon_image)))
                if($Subitem.icon_margin){
                  $SubmenuItem_imagecontrol.margin = $Subitem.icon_margin
                }      
                $SubmenuItem.icon = $SubmenuItem_imagecontrol
              }
              if(-not [string]::IsNullOrEmpty($subitem.binding)){
                $Binding = New-Object System.Windows.Data.Binding
                $Binding.Source = $subitem.binding
                $Binding.Path = $subitem.binding_property_path
                $Binding.Mode = $subitem.binding_mode
                $null = [System.Windows.Data.BindingOperations]::SetBinding($SubmenuItem,[System.Windows.Controls.MenuItem]::IsCheckedProperty, $Binding) 
              }
              if(-not [string]::IsNullOrEmpty($Subitem.Command)){
                $SubmenuItem.Add_Click($Subitem.Command)
              }
              if(-not [string]::IsNullOrEmpty($subitem.Sub_items)){
                foreach($subitem_lvl2 in $subitem.Sub_items){
                  $SubmenuItem_lvl2 = new-object System.Windows.Controls.MenuItem -property @{Header = $SubItem_lvl2.header}
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.Style)){
                    $SubmenuItem_lvl2.Style = $synchash.Window.TryFindResource($subitem_lvl2.Style)
                  }
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.FontWeight)){
                    $SubmenuItem_lvl2.FontWeight = $subitem_lvl2.FontWeight
                  } 
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.FontStyle)){
                    $SubmenuItem_lvl2.FontStyle = $subitem_lvl2.FontStyle
                  }                                   
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.ToolTip)){
                    $SubmenuItem_lvl2.ToolTip = $subitem_lvl2.ToolTip
                  }
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.ForegroundStyle)){
                    $SubmenuItem_lvl2.Foreground = $synchash.Window.TryFindResource($subitem_lvl2.ForegroundStyle)
                  }else{
                    $SubmenuItem_lvl2.Foreground = $subitem_lvl2.color
                  }
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.tag)){
                    $SubmenuItem_lvl2.tag = $subitem_lvl2.tag
                  }
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.BackGround)){
                    $SubmenuItem_lvl2.BackGround = $subitem_lvl2.BackGround
                  }
                  $SubmenuItem_lvl2.IsEnabled = $subitem_lvl2.enabled
                  if($SubItem_lvl2.IsCheckable){
                    $SubmenuItem_lvl2.IsCheckable = $SubItem_lvl2.IsCheckable
                  }elseif(-not [string]::IsNullOrEmpty($Subitem_lvl2.icon_kind)){
                    if(-not [string]::IsNullOrEmpty($Subitem_lvl2.iconpack)){
                      $iconpack = $Subitem_lvl2.iconpack
                    }else{
                      $iconpack = 'PackIconMaterial'
                    }
                    $SubmenuItem_lvl2_imagecontrol = New-Object MahApps.Metro.IconPacks.$iconpack
                    $SubmenuItem_lvl2_imagecontrol.width = "16"
                    $SubmenuItem_lvl2_imagecontrol.Height = "16"
                    $SubmenuItem_lvl2_imagecontrol.Kind = $Subitem_lvl2.icon_kind
                    $SubmenuItem_lvl2_imagecontrol.Foreground = $Subitem_lvl2.icon_color
                    if($Subitem_lvl2.icon_margin){
                      $SubmenuItem_lvl2_imagecontrol.margin = $Subitem_lvl2.icon_margin
                    }      
                    $SubmenuItem_lvl2.icon = $SubmenuItem_lvl2_imagecontrol
                  }elseif(-not [string]::IsNullOrEmpty($Subitem_lvl2.icon_image)){                                   
                    $SubmenuItem_lvl2_imagecontrol = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new([System.IO.File]::ReadAllBytes($Subitem_lvl2.icon_image)))
                    if($Subitem_lvl2.icon_margin){
                      $SubmenuItem_lvl2_imagecontrol.margin = $Subitem_lvl2.icon_margin
                    }      
                    $SubmenuItem_lvl2.icon = $Subitem_lvl2.icon_image
                  }
                  if(-not [string]::IsNullOrEmpty($subitem_lvl2.binding)){
                    $Binding = New-Object System.Windows.Data.Binding
                    $Binding.Source = $subitem_lvl2.binding
                    $Binding.Path = $subitem_lvl2.binding_property_path
                    $Binding.Mode = $subitem_lvl2.binding_mode
                    $null = [System.Windows.Data.BindingOperations]::SetBinding($SubmenuItem_lvl2,[System.Windows.Controls.MenuItem]::IsCheckedProperty, $Binding) 
                  } 
                  if(-not [string]::IsNullOrEmpty($Subitem_lvl2.Command)){
                    $SubmenuItem_lvl2.Add_Click($Subitem_lvl2.Command)
                  }
                  $null = $SubmenuItem.Items.Add($SubmenuItem_lvl2)
                }
              }              
              $null = $menuItem.Items.Add($SubmenuItem)           
            }
          }
        }
        if($addchild){
          $null = $control.AddChild($menuItem)
        }else{
          $null = $contextMenu.Items.Add($menuItem)
        }        
      }
    }
    if($AddContextMenu){
      $contextMenu.Style = $synchash.Window.TryFindResource("DropDownMenuStyle")
      $control.ContextMenu = $contextMenu    
    }elseif($addchild){
      $contextMenu.Style = $synchash.Window.TryFindResource("DropDownMenuStyle")
    } 
    $contextMenu.add_Closed({
        #$this.items.clear()
        #$this.Clear()    
    })    
  }
}


#---------------------------------------------- 
#region Get-FolderSize
#---------------------------------------------
<#
    .SYNOPSIS
    Gets folder sizes using COM and by default with a fallback to robocopy.exe, with the
    logging only option, which makes it not actually copy or move files, but just list them, and
    the end summary result is parsed to extract the relevant data.

    There is a -ComOnly parameter for using only COM, and a -RoboOnly parameter for using only
    robocopy.exe with the logging only option.

    The robocopy output also gives a count of files and folders, unlike the COM method output.
    The default number of threads used by robocopy is 8, but I set it to 16 since this cut the
    run time down to almost half in some cases during my testing. You can specify a number of
    threads between 1-128 with the parameter -RoboThreadCount.

    Both of these approaches are apparently much faster than .NET and Get-ChildItem in PowerShell.

    The properties of the objects will be different based on which method is used, but
    the "TotalBytes" property is always populated if the directory size was successfully
    retrieved. Otherwise you should get a warning (and the sizes will be zero).
    
    Online documentation: http://www.powershelladmin.com/wiki/Get_Folder_Size_with_PowerShell,_Blazingly_Fast
    
    MIT license. http://www.opensource.org/licenses/MIT
    
    Copyright (C) 2015-2017, Joakim Svendsen
    All rights reserved.
    Svendsen Tech.
    
    .PARAMETER Path
    Path or paths to measure size of.

    .PARAMETER LiteralPath
    Path or paths to measure size of, supporting wildcard characters
    in the names, as with Get-ChildItem.

    .PARAMETER Precision
    Number of digits after decimal point in rounded numbers.

    .PARAMETER RoboOnly
    Do not use COM, only robocopy, for always getting full details.

    .PARAMETER ComOnly
    Never fall back to robocopy, only use COM.

    .PARAMETER RoboThreadCount
    Number of threads used when falling back to robocopy, or with -RoboOnly.
    Default: 16 (gave the fastest results during my testing).

    .EXAMPLE
    . .\Get-FolderSize.ps1
    PS C:\> 'C:\Windows', 'E:\temp' | Get-FolderSize

    .EXAMPLE
    Get-FolderSize -Path Z:\Database -Precision 2

    .EXAMPLE
    Get-FolderSize -Path Z:\Database -RoboOnly -RoboThreadCount 64

    .EXAMPLE
    Get-FolderSize -Path Z:\Database -RoboOnly

    .EXAMPLE
    Get-FolderSize A:\FullHDFloppyMovies -ComOnly

#>
function Get-FolderSize {
  [CmdletBinding(DefaultParameterSetName = "Path")]
  param(
    [Parameter(ParameterSetName = "Path",
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    [Alias('Name', 'FullName')]
    [string[]] $Path,
    [int] $Precision = 4,
    [switch] $RoboOnly,
    [switch] $ComOnly,
    [Parameter(ParameterSetName = "LiteralPath",
        Mandatory = $true,
    Position = 0)] [string[]] $LiteralPath,
  [ValidateRange(1, 128)] [byte] $RoboThreadCount = 16)
  begin {
    if ($RoboOnly -and $ComOnly) {
      Write-Error -Message "You can't use both -ComOnly and -RoboOnly. Default is COM with a fallback to robocopy." -ErrorAction Stop
    }
    if (-not $RoboOnly) {
      $FSO = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
    }
    function Get-RoboFolderSizeInternal {
      [CmdletBinding()]
      param(
        # Paths to report size, file count, dir count, etc. for.
        [string[]] $Path,
      [int] $Precision = 4)
      begin {
        if (-not (Get-Command -Name robocopy -ErrorAction SilentlyContinue)) {
          Write-Warning -Message "Fallback to robocopy failed because robocopy.exe could not be found. Path '$p'. $([datetime]::Now)."
          return
        }
      }
      process {
        foreach ($p in $Path) {
          Write-Verbose -Message "Processing path '$p' with Get-RoboFolderSizeInternal. $([datetime]::Now)."
          $RoboCopyArgs = @("/L","/S","/NJH","/BYTES","/FP","/NC","/NDL","/TS","/XJ","/R:0","/W:0","/MT:$RoboThreadCount")
          [datetime] $StartedTime = [datetime]::Now
          [string] $Summary = robocopy $p NULL $RoboCopyArgs | Select-Object -Last 8
          [datetime] $EndedTime = [datetime]::Now
          [regex] $HeaderRegex = '\s+Total\s*Copied\s+Skipped\s+Mismatch\s+FAILED\s+Extras'
          [regex] $DirLineRegex = 'Dirs\s*:\s*(?<DirCount>\d+)(?:\s+\d+){3}\s+(?<DirFailed>\d+)\s+\d+'
          [regex] $FileLineRegex = 'Files\s*:\s*(?<FileCount>\d+)(?:\s+\d+){3}\s+(?<FileFailed>\d+)\s+\d+'
          [regex] $BytesLineRegex = 'Bytes\s*:\s*(?<ByteCount>\d+)(?:\s+\d+){3}\s+(?<BytesFailed>\d+)\s+\d+'
          [regex] $TimeLineRegex = 'Times\s*:\s*(?<TimeElapsed>\d+).*'
          [regex] $EndedLineRegex = 'Ended\s*:\s*(?<EndedTime>.+)'
          if ($Summary -match "$HeaderRegex\s+$DirLineRegex\s+$FileLineRegex\s+$BytesLineRegex\s+$TimeLineRegex\s+$EndedLineRegex") {
            New-Object PSObject -Property @{
              Path = $p
              TotalBytes = [decimal] $Matches['ByteCount']
              TotalMBytes = [math]::Round(([decimal] $Matches['ByteCount'] / 1MB), $Precision)
              TotalGBytes = [math]::Round(([decimal] $Matches['ByteCount'] / 1GB), $Precision)
              BytesFailed = [decimal] $Matches['BytesFailed']
              DirCount = [decimal] $Matches['DirCount']
              FileCount = [decimal] $Matches['FileCount']
              DirFailed = [decimal] $Matches['DirFailed']
              FileFailed  = [decimal] $Matches['FileFailed']
              TimeElapsed = [math]::Round([decimal] ($EndedTime - $StartedTime).TotalSeconds, $Precision)
              StartedTime = $StartedTime
              EndedTime   = $EndedTime

            } | Select-Object -Property Path, TotalBytes, TotalMBytes, TotalGBytes, DirCount, FileCount, DirFailed, FileFailed, TimeElapsed, StartedTime, EndedTime
          }
          else {
            Write-Warning -Message "Path '$p' output from robocopy was not in an expected format."
          }
        }
      }
    }
  }
  process {
    if ($PSCmdlet.ParameterSetName -eq "Path") {
      $Paths = @(Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath -ErrorAction SilentlyContinue)
    }
    else {
      $Paths = @(Get-Item -LiteralPath $LiteralPath | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue)
    }
    foreach ($p in $Paths) {
      Write-Verbose -Message "Processing path '$p'. $([datetime]::Now)."
      if (-not (Test-Path -LiteralPath $p -PathType Container)) {
        Write-Warning -Message "$p does not exist or is a file and not a directory. Skipping."
        continue
      }
      # We know we can't have -ComOnly here if we have -RoboOnly.
      if ($RoboOnly) {
        Get-RoboFolderSizeInternal -Path $p -Precision $Precision
        continue
      }
      $ErrorActionPreference = 'Stop'
      try {
        $StartFSOTime = [datetime]::Now
        $TotalBytes = $FSO.GetFolder($p).Size
        $EndFSOTime = [datetime]::Now
        if ($null -eq $TotalBytes) {
          if (-not $ComOnly) {
            Get-RoboFolderSizeInternal -Path $p -Precision $Precision
            continue
          }
          else {
            Write-Warning -Message "Failed to retrieve folder size for path '$p': $($Error[0].Exception.Message)."
          }
        }
      }
      catch {
        if ($_.Exception.Message -like '*PERMISSION*DENIED*') {
          if (-not $ComOnly) {
            Write-Verbose "Caught a permission denied. Trying robocopy."
            Get-RoboFolderSizeInternal -Path $p -Precision $Precision
            continue
          }
          else {
            Write-Warning "Failed to process path '$p' due to a permission denied error: $($_.Exception.Message)"
          }
        }
        Write-Warning -Message "Encountered an error while processing path '$p': $($_.Exception.Message)"
        continue
      }
      $ErrorActionPreference = 'Continue'
      New-Object PSObject -Property @{
        Path = $p
        TotalBytes = [decimal] $TotalBytes
        TotalMBytes = [math]::Round(([decimal] $TotalBytes / 1MB), $Precision)
        TotalGBytes = [math]::Round(([decimal] $TotalBytes / 1GB), $Precision)
        BytesFailed = $null
        DirCount = $null
        FileCount = $null
        DirFailed = $null
        FileFailed  = $null
        TimeElapsed = [math]::Round(([decimal] ($EndFSOTime - $StartFSOTime).TotalSeconds), $Precision)
        StartedTime = $StartFSOTime
        EndedTime = $EndFSOTime
      } | Select-Object -Property Path, TotalBytes, TotalMBytes, TotalGBytes, DirCount, FileCount, DirFailed, FileFailed, TimeElapsed, StartedTime, EndedTime
    }
  }
  end {
    if (-not $RoboOnly) {
      [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($FSO)
    }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
  }
}
#---------------------------------------------- 
#endregion Get-FolderSize
#----------------------------------------------

#---------------------------------------------- 
#region Get-IniFile
#----------------------------------------------
Function Get-IniFile ($file) {
  $ini = @{}

  # Create a default section if none exist in the file. Like a java prop file.
  $section = "NO_SECTION"
  $ini[$section] = @{}

  switch -regex -file $file {
    "^\[(.+)\]$" {
      $section = $matches[1].Trim()
      $ini[$section] = @{}
    }
    "^\s*([^#].+?)\s*=\s*(.*)" {
      $name,$value = $matches[1..2]
      # skip comments that start with semicolon:
      if (!($name.StartsWith(";"))) {
        $ini[$section][$name] = $value.Trim()
      }
    }
  }
  $ini
}
#---------------------------------------------- 
#endregion Get-IniFile
#----------------------------------------------

#---------------------------------------------- 
#region Start-WebNavigation
#----------------------------------------------
Function Start-WebNavigation{
  [CmdletBinding()]
  Param(
    $uri,
    $synchash,
    $thisScript,
    $thisApp,
    $WebView2
  ) 
  try{
    if($uri){
      write-ezlogs ">>>> Navigating to URL $uri" -showtime -color cyan
      if(!(Test-URL -address $uri)){
        if($uri -notmatch 'https://'){
          $uri = "https://$($uri)"
        }
      }
      if($thisApp.Config.Spotify_WebPlayer){
        [uri]$synchash.Spotify_WebPlayer_HTML = "$($thisApp.Config.Current_Folder)\\Resources\\Spotify\\SpotifyWebPlayerTemplate.html"
      }
      #Lets not support youtube so use Invidious which also lets us do fullscreen embed
      if($uri -match "youtube.com"){
        if($uri -match "v=" -and $uri -notmatch 'embed'){
          $youtube_id = ($($uri) -split('v='))[1].trim()
          if($thisApp.Config.Use_invidious){
            $uri = "https://yewtu.be/embed/$youtube_id`&autoplay=1"
            $synchash.Use_invidious_url = $uri
          }else{
            $uri = "https://www.youtube.com/embed/$youtube_id`&autoplay=1&enablejsapi=1"
          }
        }elseif($uri -match 'list=' -and $uri -notmatch 'embed'){
          $playlist_id = ($($uri) -split('list='))[1].trim()
          if($thisApp.Config.Use_invidious){            
            $uri = "https://yewtu.be/embed/videoseries?list=$playlist_id`&autoplay=1"
            $synchash.Use_invidious_url = $uri            
          }else{
            $uri = "https://www.youtube.com/embed/videoseries?list=$youtube_id`?&autoplay=1&enablejsapi=1"
          }                   
        }
      }elseif($uri -match "spotify.com"){
        if($uri -match 'open.spotify.com/track/'){
          $spotify_id = ($($uri) -split('open.spotify.com/track/'))[1].trim()
          if($thisApp.Config.Spotify_WebPlayer){
            #$spotify_WebplayerHTML = "$($thisApp.Config.Temp_Folder)\\SpotifyWebPlayer.html"
            #$spotify_WebplayerTemplateHTML = "$($thisApp.Config.Current_Folder)\\Resources\\Spotify\\SpotifyWebPlayerTemplate.html"           
            try{
              $Spotify_accesstoken = (Get-SpotifyAccessToken -ApplicationName $thisApp.Config.App_name -thisScript $thisScript)      
              #$urihtml = Get-content $synchash.Spotify_WebPlayer_HTML -Force    
            }catch{
              write-ezlogs "An exception occurred getting spotifyaccesstoken" -showtime -catcherror $_
            }
            if($synchash.Spotify_WebPlayer_HTML -and $Spotify_accesstoken){
              $synchash.Session_SpotifyToken = $Spotify_accesstoken
              $synchash.Session_SpotifyId = $spotify_id
              $synchash.Session_Spotifytype = 'track'
              <#              $urihtml = ($embedhtml -replace '!!SPOTIFYACCESSTOKEN!!',$Spotify_accesstoken `
                  -replace '!!SPOTIFYMEDIAID!!',$spotify_id -replace '!!SPOTIFYMEDIATYPE!!','track' | out-string)
              $urihtml | out-file $spotify_WebplayerHTML -Force -encoding utf8#>
              [uri]$uri = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
            }else{
              $uri = "https://open.spotify.com/embed/track/$spotify_id"
              $synchash.Spotify_WebPlayer_URL = $uri
              $synchash.Spotify_WebPlayer_HTML = $Null
              $synchash.Session_SpotifyToken = $null
            }          
          }           
        }elseif($uri -match 'open.spotify.com/playlist/'){
          $spotify_id = ($($uri) -split('open.spotify.com/playlist/'))[1].trim()
          if($thisApp.Config.Spotify_WebPlayer){
            try{
              #$spotify_WebplayerHTML = "$($thisApp.Config.Temp_Folder)\\SpotifyWebPlayer.html"
              #$spotify_WebplayerTemplateHTML = "$($thisApp.Config.Current_Folder)\\Resources\\Spotify\\SpotifyWebPlayerTemplate.html"
              $Spotify_accesstoken = (Get-SpotifyAccessToken -ApplicationName $thisApp.Config.App_name -thisScript $thisScript)            
            }catch{
              write-ezlogs "An exception occurred getting spotifyaccesstoken" -showtime -catcherror $_
            }
            if($synchash.Spotify_WebPlayer_HTML -and $Spotify_accesstoken){
              $synchash.Session_SpotifyToken = $Spotify_accesstoken
              $synchash.Session_SpotifyId = $spotify_id
              $synchash.Session_Spotifytype = 'playlist'
              <#              $urihtml = ($embedhtml -replace '!!SPOTIFYACCESSTOKEN!!',$Spotify_accesstoken `
                  -replace '!!SPOTIFYMEDIAID!!',$spotify_id -replace '!!SPOTIFYMEDIATYPE!!','playlist' -replace '!!SPOTIFYMEDIATYPE!!','track' | out-string)
              $urihtml | out-file $spotify_WebplayerHTML -Force -encoding utf8#>
              #$synchash.Spotify_WebPlayer_URL = $synchash.Spotify_WebPlayer_HTML
              [uri]$uri = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
              $synchash.Spotify_WebPlayer_URL = [uri]$synchash.Spotify_WebPlayer_HTML.AbsoluteUri
            }else{
              $uri = "https://open.spotify.com/embed/track/$spotify_id"
              $synchash.Spotify_WebPlayer_URL = $uri
              $synchash.Spotify_WebPlayer_HTML = $Null
              $synchash.Session_SpotifyToken = $null
            }          
          }          
        }
        [uri]$logo = "$($thisapp.Config.Current_Folder)\Resources\MusicPlayerFilltest.ico"
        if($synchash.Volume_Slider.Value){
          $volume = $synchash.Volume_Slider.Value / 100
        }elseif($thisapp.Config.Media_Volume){
          $Volume = $thisapp.Config.Media_Volume / 100
        }

        if($synchash.SpotifyStartScript_Webview2){
          $synchash.Webview2.CoreWebview2.RemoveScriptToExecuteOnDocumentCreated($synchash.SpotifyStartScript_Webview2)
        }
        if($synchash.Session_SpotifyToken){
          $synchash.SpotifyStartScript_Webview2 = @"
const hash = window.location.hash
.substring(1)
.split('&')
.reduce(function (initial, item) {
  if (item) {
    var parts = item.split('=');
    initial[parts[0]] = decodeURIComponent(parts[1]);
  }
  return initial;
}, {});
window.location.hash = '';
// Set token
let _token = '$($synchash.Session_SpotifyToken)';

// Set up the Web Playback SDK
  var currState = {}
  var SpotifyWeb = {}

window.onSpotifyWebPlaybackSDKReady = () => {
  SpotifyWeb.player = new Spotify.Player({
    name: 'EZT-MediaPlayer',
    getOAuthToken: cb => { cb(_token); }
  });

  // Error handling
  SpotifyWeb.player.on('initialization_error', e => console.error(e));
  SpotifyWeb.player.on('authentication_error', e => console.error(e));
  SpotifyWeb.player.on('account_error', e => console.error(e));
  SpotifyWeb.player.on('playback_error', e => console.error(e));

  // Playback status updates
  SpotifyWeb.currState = {}
  SpotifyWeb.player.on('player_state_changed', state => {
    //console.log(state);
    //`$('#current-track').attr('src', state.track_window.current_track.album.images[0].url);
      `$('#current-track-name').text(```${state.track_window.current_track.name} - EZT-MediaPlayer``);
     SpotifyWeb.currState.current_track = state.track_window.current_track  
     SpotifyWeb.currState.position = state.position;   
     SpotifyWeb.currState.duration = state.duration;
     SpotifyWeb.currState.updateTime = performance.now()
     SpotifyWeb.currState.current_track = state.track_window.current_track;
     let previous = state.track_window.previous_tracks[0];
     console.log(state.track_window.current_track);
     console.log(previous);
    if (
        SpotifyWeb.currState 
        && previous
        && previous.uid == state.track_window.current_track.uid
        && state.paused
        ) {
        console.log('Track ended');
        SpotifyWeb.currState.playbackstate = 0
      } else{
        SpotifyWeb.currState.playbackstate = 1
        SpotifyWeb.currState.paused = state.paused;
      }   
    //console.log(state.track_window.previous_tracks);
  });
//SpotifyWeb.player.addListener('player_state_changed', state => {

//});
  // Ready
  SpotifyWeb.player.on('ready', data => {
    console.log('Ready with Device ID', data.device_id);
    
    // Play a track using our new device ID
    play(data.device_id);
  });

  // Connect to the player!
  SpotifyWeb.player.connect();

}

"@


          $synchash.Webview2.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync($synchash.SpotifyStartScript_Webview2) 

          write-ezlogs "$($synchash.Webview2.CoreWebView2.psobject.methods | where {$_ -match 'Add_'} | out-string)"

        }

        #write-ezlogs "Scriptid: $($scriptid | out-string)" -showtime
      }
      if($WebView2 -ne $null -and $WebView2.CoreWebView2 -ne $null){
        if($uri -match 'youtube.com' -or $uri -match 'google.com'){
          $WebView2.CoreWebView2.Settings.UserAgent = "Chrome"
          $WebView2.CoreWebView2.Settings.UserAgent = "Andriod"
        }else{
          $WebView2.CoreWebView2.Settings.UserAgent = ""
        }   
        if($urihtml){
          write-ezlogs "Navigating with CoreWebView2.NavigateToString: $($urihtml)" -enablelogs -Color cyan -showtime
          $WebView2.CoreWebView2.NavigateToString($urihtml)
        }else{
          write-ezlogs "Navigating with CoreWebView2.Navigate: $($uri)" -enablelogs -Color cyan -showtime
          $WebView2.CoreWebView2.Navigate($uri)
        }
           

        #$synchash.WebView2.CoreWebView2.Navigate($synchash.Youtube_WebPlayer_URL)
      }
      else{
        if($webview.name -eq 'WebBrowser'){
          $synchash.WebBrowser_url = $uri
        }
        if($urihtml){
          write-ezlogs "Adding CoreWebView2InitializationCompleted with navigate to url: $($urihtml)" -enablelogs -Color cyan -showtime  
          $synchash.Youtube_WebPlayer_URL = $urihtml
          $synchash.Spotify_WebPlayer_URL = $urihtml
        }else{
          write-ezlogs "Adding CoreWebView2InitializationCompleted with navigate to url: $($uri)" -enablelogs -Color cyan -showtime  
          $synchash.Youtube_WebPlayer_URL = $uri
          $synchash.Spotify_WebPlayer_URL = $uri
        }             
         
        
        #write-ezlogs "Navigating with Source: $($uri)" -enablelogs -Color cyan -showtime
        #$WebView2.source = $uri
      } 
      #$synchash.txtUrl.text = $uri
    }else{
      write-ezlogs "The provided $Uri was null or invalid!" -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in Start-WebNavigation" -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Start-WebNavigation
#----------------------------------------------

#---------------------------------------------- 
#region Set-SpeakerVolume Function
#----------------------------------------------
function Set-SpeakerVolume
{
  param (
    [double]$Volume,
    [switch]$mute
  )
  Update-LogWindow -content "Setting main system volume" -showtime -color Cyan
  Update-LogWindow -content "Getting All Audio Devices" -showtime
  try
  {
    $all_audio_devices = Get-AudioDevice -list
  }
  catch
  {
    Update-LogWindow -content "[ERROR] An exception occured getting audio devices:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
  }
  if($all_audio_devices)
  {
    foreach ($a in $all_audio_devices)
    {
      Update-LogWindow -content " | Found Audio Device: $($a.name) - Type: $($a.type) - Default: $($a.Default)" -showtime
    }  
  }
  else
  {
    Update-LogWindow -content "[ERROR] No audio devices were found. Unable to continue. Please ensure system has proper audio hardware and updated drivers installed" -showtime -color red -LogFile $logfile
    exit
  }

  try
  {
    Add-Type -Language CSharpVersion3 -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
    // f(), g(), ... are unused COM method slots. Define these if you care
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
    int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
    int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
    int f(); // Unused
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
    static IAudioEndpointVolume Vol()
    {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
        return epv;
    }
    public static float Volume
    {
        get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
    }
    public static bool Mute
    {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
    }
}
'@  
  }
  catch
  {
    Update-LogWindow -content "[ERROR] An exception occured getting access to the windows audio API:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
  }
  if($mute)
  {
    
    try
    {
      #[audio]::Mute = $true  # Set to $false to un-mute
      Update-LogWindow -content " | Muting main system volume" -showtime
      Set-AudioDevice -PlaybackMute 1
      return
    }
    catch
    {
      Update-LogWindow -content "[ERROR] An exception occured muting main system volume:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
    }
  }
  else
  {
    try
    {
      #[audio]::Mute = $false  # Set to $false to un-mute
      Update-LogWindow -content " | Unmuting main system volume" -showtime
      Set-AudioDevice -PlaybackMute 0
      
    }
    catch
    {
      write-ezlogs "[ERROR] An exception occured unmuting main system volume:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
    }
  }
  
  if($volume)
  {
    try
    {
      #write-ezlogs " | Current main system volume: $([Math]::Round(([audio]::Volume) / .01))" -showtime
      Update-LogWindow -content " | Current main system volume: $(Get-audiodevice -PlaybackVolume)" -showtime
      Update-LogWindow -content " | Setting new main system volume: $volume" -showtime
      #[audio]::Volume  = $volume # 0.2 = 20%, etc.
      Set-AudioDevice -PlaybackVolume $volume
    }
    catch
    {
      Update-LogWindow -content "[ERROR] An exception occured setting main system volume:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
    }
  }
  else
  {
    try
    {
      #write-ezlogs " | Current main system volume: $([Math]::Round(([audio]::Volume) / .01))" -showtime
      Update-LogWindow -content " | Current main system volume: $(Get-audiodevice -PlaybackVolume)" -showtime
    }
    catch
    {
      Update-LogWindow -content "[ERROR] An exception occured getting main system volume:`n | $($_.exception.message)`n | $($_.InvocationInfo.positionmessage)`n | $($_.ScriptStackTrace)`n" -showtime -color red -LogFile $logfile
    }    
  }
}
#---------------------------------------------- 
#endregion Set-SpeakerVolume Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-StrongPassword Function
#----------------------------------------------
function Get-StrongPassword ([Parameter(Mandatory=$true)][int]$PasswordLenght)
{
  Add-Type -AssemblyName System.Web
  $PassComplexCheck = $false
  do {
    $newPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLenght,1)
    If ( ($newPassword -cmatch "[A-Z\p{Lu}\s]") `
      -and ($newPassword -cmatch "[a-z\p{Ll}\s]") `
      -and ($newPassword -match "[\d]") `
      -and ($newPassword -match "[^\w]")
    )
    {
      $PassComplexCheck=$True
    }
  } While ($PassComplexCheck -eq $false)
  return $newPassword
}
#---------------------------------------------- 
#endregion Get-StrongPassword Function
#----------------------------------------------

#---------------------------------------------- 
#region Use Run-As Function
#----------------------------------------------
function Use-RunAs 
{    
  # Check if script is running as Adminstrator and if not use RunAs 
  # Use Check Switch to check if admin 
  # http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
    
  param([Switch]$Check,[Switch]$ForceReboot) 
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') 
  if ($Check) { return $IsAdmin }     
  if ($MyInvocation.ScriptName -ne '') 
  {  
    if (-not $IsAdmin -or $ForceReboot)  
    {  
      try 
      {  
        #$arg = "-file `"$($MyInvocation.ScriptName)`""         
        $ScriptPath = [System.IO.Path]::Combine($thisApp.Config.Current_folder,"$($thisApp.Config.App_Name).ps1")
        if(![System.IO.File]::Exists($ScriptPath)){
          $ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)
        }
        write-ezlogs "Script requesting Admin Permissions to install requirments, restarting with Path: $($ScriptPath)" -showtime -warning
        $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($ScriptPath)`""
        if($hash.Window.IsVisible){
          close-splashscreen
        }
        if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
          $process = Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{         
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }
      } 
      catch 
      { 
        Write-ezlogs 'Failed to restart script with runas' -showtime -catcherror $_ 
        break               
      } 
      if($pid){
        stop-process $pid -Force -ErrorAction SilentlyContinue
      }      
      exit # Quit this session of powershell 
    }  
  }  
  else  
  {  
    Write-EZLogs 'Script must be saved as a .ps1 file first' -showtime -LinesAfter 1 -Warning  
    break  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------

#---------------------------------------------- 
#region Confirm Requirements
#----------------------------------------------
function confirm-requirements([switch]$enablelogs,[switch]$Verboselog,$required_appnames,[switch]$FirstRun,$thisApp,$logfile)
{
  
  #region Install Chocolatey
  if (!$env:ChocolateyInstall -or !([System.IO.File]::Exists("$env:ChocolateyInstall\Choco.exe"))){
    if($hash.Window){
      $hash.Window.Dispatcher.invoke([action]{
          $hash.LoadingLabel.Content="Checking Requirements..."
          $hash.More_Info_Msg.Visibility= "Visible"
          $hash.More_info_Msg.text="Installing Required App: Chocolatey"      
      },"Normal") 
    }
    try{
      Use-RunAs      
      write-ezlogs "Chocolatey is not installed, installing...." -showtime -warning
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
      iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex | Out-File -FilePath $logfile -Encoding unicode -Append
      Use-RunAs -ForceReboot
    }catch{
      write-ezlogs "An exception occurred installeding Chocolatey" -showtime -catcherror $_
    }
  }
  else
  {
    #$testchoco = powershell choco -v
    $testchoco = (Get-ItemProperty "$env:ChocolateyInstall\\choco.exe").VersionInfo.ProductVersion
    write-ezlogs ">>>> Chocolatey is installed. Version $testchoco" -showtime -color cyan
  }
  #endregion Install Chocolatey

  #region Update Powershell
  if($($PSVersionTable.PSVersion.Major) -lt 3)
  {
    $MinimumNet4Version = 378389
    $Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
    if ($Net4Version -lt $MinimumNet4Version)
    {
      Write-Output ".NET Framework 4.5.2 or later required.  Use package named `"dotnet4.5` to upgrade. Your .NET Release is `"$MinimumNet4Version`" but needs to be at least `"$MinimumNet4Version`"." -OutVariable message;if($Verboselog){$message | Out-File -FilePath $logfile -Encoding unicode -Append}
    }
    else
    {
      Use-RunAs
      Write-Output "This machine does not meet the minimum requirements to use this script. Your Powershell version is $($PSVersionTable.psversion) and the minimum required is 3`n | Attempting to updating Powershell via Chocolatey...." -OutVariable message;if($Verboselog){$message | Out-File -FilePath $logfile -Encoding unicode -Append}
      choco install powershell -confirm -force 
      if($($PSVersionTable.PSVersion.Major) -ge 3)
      {
        Write-Output " | Powershell was updated successfully" -OutVariable message;if($Verboselog){$message | Out-File -FilePath $logfile -Encoding unicode -Append}
      }
      else
      {
        Write-Output " | Powershell was either not updated successfully, or the system may require a restart. Restart and try again, otherwise update Powershell manually on this system" -OutVariable message;if($Verboselog){$message | Out-File -FilePath $logfile -Encoding unicode -Append}
      }
     
    }
  }
  #endregion Update Powershell
  
  #region install/update required apps
  if(-not [string]::IsNullOrEmpty($required_appnames) -and $firstRun){

    foreach ($app in $required_appnames)
    {
      if($app -eq 'Spotify'){
        if([System.IO.File]::Exists("$($env:APPDATA)\\Spotify\\Spotify.exe")){
          $appinstalled = (Get-ItemProperty "$($env:APPDATA)\\Spotify\\Spotify.exe").VersionInfo.ProductVersion
        }elseif((Get-appxpackage 'Spotify*')){
          write-ezlogs ">>>> Spotify installed as appx" -showtime
          $appinstalled = (Get-ItemProperty "$((Get-appxpackage 'Spotify*').InstallLocation)\\Spotify.exe").VersionInfo.ProductVersion
        }else{
          $appinstalled = ''
        } 
        $Do_Install = $thisApp.Config.Install_Spotify     
        write-ezlogs ">>>> Auto Install $app`: $($thisApp.Config.Install_Spotify)" -showtime  
      }elseif($app -eq 'Spicetify'){      
        if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
          $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini").Backup.with
          if(!$appinstalled){
            $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
          }           
        }
        if($thisApp.Config.Import_Spotify_Media -and $thisApp.Config.use_Spicetify -and !$thisApp.Config.Spotify_WebPlayer -and $thisApp.Config.Install_Spotify){
          $Do_Install = $true
        }else{
          $Do_Install = $false
        }                           
      }elseif($app -eq 'Streamlink'){
        if([System.IO.File]::Exists("$("${env:ProgramFiles(x86)}\\Streamlink\\bin\\streamlink.exe")")){
          #$appinstalled = streamlink --version-check
          $appinstalled = "Streamlink is installed at $("${env:ProgramFiles(x86)}\\Streamlink\\bin\\streamlink.exe")"
        }else{
          $Do_Install = $true
        }
      }else{        
        $chocoappmatch = choco list $app --localonly
        $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
        $Do_Install = $true       
      }     
      if($appinstalled){
        write-ezlogs ">>>> $app is installed. Version $appinstalled" -showtime
      }elseif(!$Do_Install){
        write-ezlogs ">>>> $app is not installed! Auto installation skipped!" -showtime -warning      
      }else{        
        try{
          Use-RunAs
          if($hash.Window){
            $hash.Window.Dispatcher.invoke([action]{
                $hash.LoadingLabel.Content="Checking Requirements..."
                $hash.More_Info_Msg.Visibility= "Visible"
                $hash.More_info_Msg.text="Installing Required App: $app"      
            },"Normal") 
          } 
          if($app -eq 'Spicetify'){
            try{
              write-ezlogs ">>>> Installing Spicetify" -showtime            
              Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression -Verbose
              Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1" | Invoke-Expression -Verbose
              if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
                $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini").Backup.with
                if(!$appinstalled){
                  $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
                }
              }
            }catch{
              write-ezlogs "An exception occurred attempting to install Spicetify" -showtime -catcherror $_
            }
          }else{
            write-ezlogs "$app is not installed! Attempting to install via chocolatey" -showtime -warning             
            $choco_install = choco upgrade $app --confirm --force --acceptlicense
            write-ezlogs "Verifying if $app was installed successfully...." -showtime
            $chocoappmatch = choco list $app --localonly
            if($chocoappmatch){
              $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
            }
          }        
          if($appinstalled){
            write-ezlogs "[SUCCESS] $app was successfully installed. Version $appinstalled" -showtime
          }else{
            write-ezlogs "Unable to verify if $app installed successfully! Choco output: $($choco_install | out-string)" -showtime -warning 
          }
        }catch{
          write-ezlogs "An exception occurred attempting to install app $app via chocolatey" -showtime -catcherror $_
        }
      }
    }
  }
  
  #endregion install/update required apps
  
}

#---------------------------------------------- 
#endregion Confirm Requirements
#----------------------------------------------

#---------------------------------------------- 
#region Test-RegistryValue Function
#----------------------------------------------
function Test-RegistryValue {
  <#
      .SYNOPSIS
      Function to test if registry value exists
		
      .Example
      Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Value "EnableLinkedConnections"

  #>
  param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Path,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Value
  )

  try {

    Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
    return $true
  }

  catch {

    return $false

  }

}
#---------------------------------------------- 
#endregion Test-RegistryValue Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-SingleRegEntry Function
#----------------------------------------------
function Set-SingleRegEntry
{
  [switch]$RestartProcess,
  [string]$processname,
  [string]$regpath,
  [string]$regkeyproperty,
  [string]$regkeypropertyvalue,
  [string]$regkeypropertyvaluetype
  

  #$regentry  = New-Object -Type PSObject
  #$regentry | Add-Member -MemberType NoteProperty -Name 'RegPath' -Value $regpath
  #$regentry | Add-Member -MemberType NoteProperty -Name 'regkeyproperty' -Value $regkeyproperty
  #$regentry | Add-Member -MemberType NoteProperty -Name 'regkeypropertyvalue' -Value $regkeypropertyvalue
  #$regentry | Add-Member -MemberType NoteProperty -Name 'regkeypropertyvaluetype' -Value $regkeypropertyvaluetype
  
  write-output "Setting registry for entry: $regpath"
  
  #Check to see if reg key and property exist
  if(-not (Test-RegistryValue -Path $regpath -Value $regkeyproperty))
  {
    #if path does exist, create it with desired value
    write-output " | Reg Value does not exist, creating..."
    New-ItemProperty -Path $regpath -Name $regkeyproperty -Value $regkeypropertyvalue -PropertyType $regkeypropertyvaluetype -Force
    write-output " | Reg property and value created"
    if ($RestartProcess -and $processname -ne $null)
    {
      #restart process because there was a change
      Get-Process $processname | Restart-Process
      write-output " | $processname process stopped and restarted"
    }
    else {
      write-output " | No process restarted as a process name was not provided or needed"
    }

  }
  else {
    #if the key exists, check if the value is correct
    write-output " | Key already exists, lets check if its value is correct..."

    $val = Get-ItemProperty -Path $regpath -Name $regkeyproperty
    if($val.$regkeyproperty -ne $regkeypropertyvalue)
    {
      #if value does not match desired input update it
      write-output " | Value is not correct, lets update it..."
      set-itemproperty -Path $regpath -Name $regkeyproperty -value $regkeypropertyvalue
      write-output " | Value updated"

      if ($RestartProcess -and $processname -ne $null){
        #restart process because there was a change
        Get-Process $processname | Restart-Process
        write-output " | $processname process stopped and restarted"
      }
      else {
        write-output " | No process restarted as a process name was not provided or needed"
      }
    }
    else
    {
      #if registry property and value exist and are set correctly, we are done
      write-output " | Registry Value is already set to the desired value...we are done here"
    }
  }

}
#---------------------------------------------- 
#endregion Set-SingleRegEntry Function
#----------------------------------------------
$SetWindowComposition = @'
[DllImport("user32.dll")]
public static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref WindowCompositionAttributeData data);

[StructLayout(LayoutKind.Sequential)]
public struct WindowCompositionAttributeData {
    public WindowCompositionAttribute Attribute;
    public IntPtr Data;
    public int SizeOfData;
}

public enum WindowCompositionAttribute {
    WCA_ACCENT_POLICY = 19
}

public enum AccentState {
    ACCENT_DISABLED = 0,
    ACCENT_ENABLE_BLURBEHIND = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND = 4
}

[StructLayout(LayoutKind.Sequential)]
public struct AccentPolicy {
    public AccentState AccentState;
    public int AccentFlags;
    public int GradientColor;
    public int AnimationId;
}
'@
Add-Type -MemberDefinition $SetWindowComposition -Namespace 'WindowStyle' -Name 'Blur'
function Set-WindowBlur {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [int]
    $MainWindowHandle,
    [Parameter(ParameterSetName='Enable',Mandatory)]
    [switch]
    $Enable,
    [Parameter(ParameterSetName='Acrylic',Mandatory)]
    [switch]
    $Acrylic,
    # Color in BGR hex format (for ease, will just be used as an integer), eg. for red use 0x0000FF
    [Parameter(ParameterSetName='Acrylic')]
    [ValidateRange(0x000000, 0xFFFFFF)]
    [int]
    $Color= 0x000000,
    # Transparency 0-255, 0 full transparency and 255 is a solid $Color
    [Parameter(ParameterSetName='Acrylic')]
    [ValidateRange(0, 255)]
    [int]
    $Transparency = 80,
    [Parameter(ParameterSetName='Disable',Mandatory)]
    [switch]
    $Disable
  )
  $Accent = [WindowStyle.Blur+AccentPolicy]::new()
  switch ($PSCmdlet.ParameterSetName) {
    'Enable' {
      $Accent.AccentState = [WindowStyle.Blur+AccentState]::ACCENT_ENABLE_BLURBEHIND
    }
    'Acrylic' {
      $Accent.AccentState = [WindowStyle.Blur+AccentState]::ACCENT_ENABLE_ACRYLICBLURBEHIND
      $Accent.GradientColor = $Transparency -shl 24 -bor ($Color -band 0xFFFFFF)
    }
    'Disable' {
      $Accent.AccentState = [WindowStyle.Blur+AccentState]::ACCENT_DISABLED
    }
  }
  $AccentStructSize = [System.Runtime.InteropServices.Marshal]::SizeOf($Accent)
  $AccentPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($AccentStructSize)
  [System.Runtime.InteropServices.Marshal]::StructureToPtr($Accent,$AccentPtr,$false)
  $Data = [WindowStyle.Blur+WindowCompositionAttributeData]::new()
  $Data.Attribute = [WindowStyle.Blur+WindowCompositionAttribute]::WCA_ACCENT_POLICY
  $Data.SizeOfData = $AccentStructSize
  $Data.Data = $AccentPtr
  $Result = [WindowStyle.Blur]::SetWindowCompositionAttribute($MainWindowHandle,[ref]$Data)
  if ($Result -eq 1) {
    Write-ezlogs "Successfully set Window Blur status."
  }
  else {
    Write-ezlogs "Warning, couldn't set Window Blur status."
  }
  [System.Runtime.InteropServices.Marshal]::FreeHGlobal($AccentPtr)
}




Export-ModuleMember -Function @(
  'ConvertFrom-Roman',
  'Test-URL',
  'Test-Folder',
  'Get-MSIProperties',
  'Grant-Ownership',
  'Open-FileDialog',
  'Open-FolderDialog',
  'Test-KeyPress',
  'Show-NotifyBalloon',
  'Set-WindowState',
  'Add-WPFMenu',
  'Get-FolderSize',
  'Get-IniFile',
  'Start-WebNavigation',
  'confirm-requirements',
  'Test-RegistryValue',
  'ConvertTo-OrderedDictionary',
  'Set-WindowBlur',
  'Convert-Color',
'Use-Runas')
