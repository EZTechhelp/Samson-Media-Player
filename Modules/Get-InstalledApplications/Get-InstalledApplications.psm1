<#
    .Name
    Get-InstalledApplications

    .Version 
    0.1.1

    .SYNOPSIS
    Retrieves all installed Desktop and Microsoft Store(UWP) Apps  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-GameManager

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>
#---------------------------------------------- 
#region Get-InstalledApplications Function
#----------------------------------------------
function Get-InstalledApplications() 
{
  [cmdletbinding(DefaultParameterSetName = 'GlobalAndAllUsers')]
  Param (
    [Parameter(ParameterSetName='Global')]
    [switch]$Global,
    [Parameter(ParameterSetName='GlobalAndCurrentUser')]
    [switch]$GlobalAndCurrentUser,
    [Parameter(ParameterSetName='GlobalAndAllUsers')]
    [switch]$GlobalAndAllUsers,
    [Parameter(ParameterSetName='CurrentUser')]
    [switch]$CurrentUser,
    [Parameter(ParameterSetName='AllUsers')]
    [switch]$AllUsers,
    [switch]$VerboseLog,
    [switch]$enable_stopwatch,
    [switch]$GetAppx,
    [switch]$GetAppxOnly,
    [switch]$VerboseDebug
  )
  
  # Excplicitly set default param to True if used to allow conditionals to work
  if ($PSCmdlet.ParameterSetName -eq 'GlobalAndAllUsers') 
  {
    $GlobalAndAllUsers = $true
  }
  if($enable_stopwatch)
  {
    $GetApps_stopwatch = [System.Diagnostics.Stopwatch]::new()
    $GetApps_stopwatch.start()
    Write-EZLogs '>>>> StopWatch Timer Started' -Color cyan -showtime -LogFile $logfile
  }
  
  # Check if running with Administrative privileges if required
  $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($RunningAsAdmin -eq $false) 
  {
    Write-EZLogs 'Finding all user applications requires administrative privileges' -color red -showtime -LogFile $logfile
    break
  }
  
  # Empty array to store applications
  $Apps = @()
  $32BitPath = 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
  $64BitPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
  if ($GlobalAndAllUsers -and !$GetAppxOnly) 
  {
    
    if($VerboseLog)
    {
      Write-EZLogs 'Getting software from registry and user profiles' -showtime -LogFile $logfile
    }
    #Retreive globally installed applications
    if ($VerboseLog)
    {
      Write-EZLogs 'Processing global hive' -showtime -LogFile $logfile
    } 
    $Apps += Get-ItemProperty "HKLM:\$32BitPath"
    $Apps += Get-ItemProperty "HKLM:\$64BitPath"

    if ($VerboseLog)
    {
      Write-EZLogs 'Processing current user hive' -showtime -LogFile $logfile
    }
    $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$32BitPath"
    $Apps += Get-ItemProperty "Registry::\HKEY_CURRENT_USER\$64BitPath"    
    
    if ($VerboseLog)
    {
      Write-EZLogs 'Collecting hive data for all users' -ShowTime  -LogFile $logfile
    }
    $AllProfiles = Get-CimInstance Win32_UserProfile | select LocalPath, SID, Loaded, Special | where {
      $_.SID -like 'S-1-5-21-*'
    }
    $MountedProfiles = $AllProfiles | where {
      $_.Loaded -eq $true
    }
    $UnmountedProfiles = $AllProfiles | where {
      $_.Loaded -eq $false
    }
    if ($VerboseLog)
    {
      Write-EZLogs 'Processing mounted hives' -ShowTime -LogFile $logfile
    }
    $MountedProfiles | % {
      $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$32BitPath"
      $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$64BitPath"
    }
    if ($VerboseLog)
    {
      Write-EZLogs 'Processing unmounted hives' -ShowTime -LogFile $logfile
    }
    $UnmountedProfiles | % {
      $Hive = "$($_.LocalPath)\NTUSER.DAT"
      if ($VerboseLog)
      {
        Write-EZLogs "-> Mounting hive at $Hive" -ShowTime  -LogFile $logfile
      }
      if (Test-Path $Hive) 
      {
        try
        {
          $null = Invoke-Command  {
            reg.exe LOAD HKU\temp $Hive
          } 2> $null   
          $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$32BitPath"
          $Apps += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$64BitPath"
        }
        catch
        {
          if ($VerboseLog)
          {
            Write-EZLogs "[ERROR] Unable to mount hive at $Hive - $($PSItem.Exception.Message)" -showtime -color red -LogFile $logfile
          }           
        }            
        try
        {
          $null = Invoke-Command  {
            reg.exe UNLOAD HKU\temp
          } 2> $null
        }
        catch
        {
          if ($VerboseLog)
          {
            Write-EZLogs "[ERROR] Unable to unload hive at $hive - $($PSItem.Exception.Message)" -showtime -color red -LogFile $logfile
          }
        }      
      }
      else 
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to access registry hive at $Hive" -ShowTime -color Red  -LogFile $logfile
        }
      }
    }
    if($VerboseLog)
    {
      Write-EZLogs ">>>> Number of desktop apps retrieved: $($apps.count)" -showtime -color Cyan -LogFile $logfile
    }
    $apps | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Desktop'
  }
  if ($GetAppx -or $GetAppxOnly)
  { 
    if($VerboseLog)
    {
      Write-EZLogs 'Getting Appx Packages from all user profiles' -showtime -LogFile $logfile
    }
    $Appx = Get-AppxPackage -AllUsers | Select-Object -ErrorAction Continue
    if(!$Appx)
    {
      Write-EZLogs '[ERROR] Getting appx packages failed for all users' -ShowTime -color red -LogFile $logfile
      Write-EZLogs 'Retrying Get-AppxPackage without -AllUsers' -ShowTime -LogFile $logfile
      $Appx = Get-AppxPackage | Select-Object -ErrorAction Continue
    } 
    $Appx_apps = $Appx | Select-Object -Property `
    @{n='DisplayName'
      e={
        #Code to translate Appx names into normal Display Names
        #TODO: Move into own function
        <# 
            C# code to expose SHLoadIndirectString(), derived from:
            Title:  Expand-IndirectString.ps1
            Author: Jason Fossen, Enclave Consulting LLC (www.sans.org/sec505)
            Date:   20 September 2016
            URL:    https://github.com/SamuelArnold/StarKill3r/blob/master/Star%20Killer/Star%20Killer/bin/Debug/Scripts/SANS-SEC505-master/scripts/Day1-PowerShell/Expand-IndirectString.ps1
            Jason has released his code to public domain.
        #>
        $CSharpSHLoadIndirectString = @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class IndirectStrings
{
	[DllImport("shlwapi.dll", BestFitMapping = false, CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = false, ThrowOnUnmappableChar = true)]
	internal static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, uint cchOutBuf, IntPtr ppvReserved);
	public static string GetIndirectString(string indirectString)
	{
		StringBuilder lptStr = new StringBuilder(1024);
		int returnValue = SHLoadIndirectString(indirectString, lptStr, (uint)lptStr.Capacity, IntPtr.Zero);
		return returnValue == 0 ? lptStr.ToString() : null;
	}
}
'@
        #Add the IndirectStrings type to PowerShell
        Add-Type -TypeDefinition $CSharpSHLoadIndirectString -Language CSharp

        #Get a count of Appx packages
        $AppxSum = $_.Count

        # Create an array to store Appx identities
        Class AppxIdentity {
          [ValidateNotNullOrEmpty()][string]$Name
          [string]$DisplayNameResolved
          [string]$DisplayNameRaw
        }
        [AppxIdentity[]]$AppxIdentities = [AppxIdentity[]]::New($AppxSum)
        for ($i = 0; $i -lt $AppxSum; $i++) 
        {
          #These variables help make the code more compact
          #AXN, AXF and AXI respectively mean AppX Name, AppX Fullname and AppX Identity
          $AXN = $_[$i].Name
          $AXF = $_[$i].PackageFullName
          $AXI = New-Object -TypeName AppxIdentity
          $regpath  = "Registry::HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages\$AXF"
          $regpath2  = "Registry::HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages\$AXF"
          #The first property is easy to acquire
          $AXI.Name = $AXN
 
          #The display name is stored in the Registry
          If (Test-Path $regpath) 
          {
            try 
            { 
              $AXI.DisplayNameRaw = (Get-ItemProperty -Path $regpath -Name DisplayName).DisplayName
              if(!$AXI.DisplayNameRaw)
              {
                $AXI.DisplayNameRaw = (Get-ItemProperty -Path $regpath2 -Name DisplayName).DisplayName
                Write-Host $AXI.DisplayNameRaw
              }
              
              if ($AXN -eq '1527c705-839a-4832-9118-54d4Bd6a0c89')
              {
                $NameResolved = 'Microsoft File Picker (System App)'
              }
              elseif ($AXN -eq 'Windows.PrintDialog')
              {
                $NameResolved = 'Microsoft Print UI (System App)'
              }
              elseif ($AXI.DisplayNameRaw -match '^@') 
              {
                $AXI.DisplayNameResolved = [IndirectStrings]::GetIndirectString( $AXI.DisplayNameRaw )
                $NameResolved = $AXI.DisplayNameResolved
                if ($NameResolved -eq '') 
                {
                  if ($VerboseLog)
                  {
                    Write-EZLogs "Could not resolve the display name for $($AXN)." -showtime -Warning -LogFile $logfile
                  }
                  $NameResolved = $_.Name
                }  
              } 
              else 
              {
                $AXI.DisplayNameResolved = $AXI.DisplayNameRaw
                $NameResolved = $AXI.DisplayNameResolved
                if ($AXI.DisplayNameRaw -match '^ms-resource\:') 
                {
                  if ($VerboseLog)
                  {
                    Write-EZLogs "For the want of an `@, a kingdom is lost. $($AXN) has a bad display name." -showtime -Warning -LogFile $logfile
                  }
                }
              }
            } 
            catch 
            {
              if ($VerboseLog)
              {
                Write-EZLogs "There are no display names associated with $($AXN)." -showtime -Warning -LogFile $logfile
              }
            }
          }
        }
        #Pass Resolved APPX Name to DisplayName 
        $NameResolved
    }},
    @{n='DisplayNameRaw'
      e={
        $_.Name
    }},
    @{n='DisplayVersion'
      e={
        $_.Version
    }},
    @{n='Publisher'
      e={
        $_.publisher
    }},
    @{n='UserProfiles'
      e={
        $_.PackageUserInformation.UserSecurityID.Username
    }},
    @{n='InstallState'
      e={
        $_.PackageUserInformation.InstallState
    }},
    @{n='InstallDate'
      e={
        $_.InstallDate
    }},
    @{n='UninstallPath'
      e={
        $_.UninstallPath
    }},
    @{n='UninstallString'
      e={
        "Get-AppxPackage -Name $($_.Name) -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue"
    }},
    @{n='QuietUninstallString'
      e={
        $null
    }},
    @{n='InstallSource'
      e={
        $_.InstallSource
    }},
    InstallLocation,
    @{n='Comments'
      e={
        $_.comments
    }},
    @{n='Type'
      e={
        'UWP'
    }},
    @{n='PackageFamilyName'
      e={
        $_.PackageFamilyName
    }},    
    @{n='LaunchCommand'
      e={
        $('Shell:AppsFolder\' + $_.PackageFamilyName + '!' + $((Get-AppxPackageManifest $_.PackageFullName).Package.Applications.Application.id   | select -First 1))
    }},
    Status,Architecture,NonRemovable,PublisherID | Sort-Object -Property DisplayName #-Unique -ErrorAction Continue
    
    $apps += $Appx_apps | Select-Object 
    if($VerboseLog)
    {
      Write-EZLogs ">>>> Number of UWP apps retrieved: $($Appx_apps.count)" -showtime -color Cyan -LogFile $logfile
    }
  }
  foreach ($a in $apps)
  {
    if($VerboseDebug)
    {    
      Write-EZLogs "`n[DEBUG - InstalledApps] Processing app $($a.DisplayName)" -color DarkYellow -LogFile $logfile -LogTime:$false
    }
    $a_InstallDate = $a.InstallDate
    $displayname = $Null
    
    if(!$a.DisplayName -and $_.Type -eq 'UWP')
    {
      $displayname = $a.DisplayNameRaw
    }
    else
    {
      $displayname = $a.DisplayName
    }
    $a_EstimatedSize = $null
    $Executable = $null
    $StoreIDs = $null
    $b_InstallFolder = $Null
    $estimatedsize = $Null
    $a_EstimatedSize = $a.EstimatedSize
    $a_InstallPath = $null
    $a_InstallPath = $a.InstallPath
    $a_InstallLocation = $null
    $a_InstallLocation = $a.InstallLocation
    $a_UninstallString = $Null
    $a_UninstallString = $a.UninstallString
    $appxlog = $Null    
    if(!$a_InstallLocation -and $a.InstallPath)
    {
      $a_InstallLocation = $a.InstallPath
    }  
    [System.Globalization.CultureInfo]$provider = [System.Globalization.CultureInfo]::InvariantCulture
    [System.DateTime]$parsedDate = Get-Date
    If ($a_InstallDate)
    {
      try
      { 
        $ErrorActionPreference = 'stop'
        if ([datetime]::TryParseExact($a_InstallDate,'yyyyMMdd',$provider,[System.Globalization.DateTimeStyles]::None,[ref]$parseddate))
        {
          $apps_installdate_before = [datetime]::ParseExact($a_InstallDate,'yyyyMMdd',$provider)
        }
        elseif([datetime]::TryParseExact($a_InstallDate,'ddd MMM dd HH:mm:ss yyyy',$provider,[System.Globalization.DateTimeStyles]::None,[ref]$parseddate))
        {
          $apps_installdate_before = [datetime]::ParseExact($a_InstallDate,'ddd MMM dd HH:mm:ss yyyy',$provider)
        }
        else
        {
          $apps_installdate_before = $a_InstallDate
        }
        $apps_installdate_formatted = Get-Date -Date $apps_installdate_before -Format 'MM-dd-yyy'
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "The InstallDate value ($($a.InstallDate)) for app ($($displayname)) is invalid or was unable to be formatted" -showtime -Warning -LogFile $logfile
        }
        $apps_installdate_formatted = $($a.InstallDate)
      }
    }
    elseif($a_InstallLocation)
    {
      try
      {
        if(Test-Path -LiteralPath $a_InstallLocation)
        {
          $b_InstallFolder = $a_InstallLocation -replace '"', ''
        }
        else
        {
          $b_InstallFolder = [System.IO.Path]::GetDirectoryName(($a_InstallLocation.Split('"') | where {
                $_
          } | select -First 1)) 2>$null
        }
        $b_InstallDate = Get-ItemProperty $b_InstallFolder | select CreationTime
        $apps_installdate_before = [datetime]::ParseExact($b_InstallDate.CreationTime.tostring('MM/dd/yyyy hh:mm:ss tt'),'MM/dd/yyyy hh:mm:ss tt',$provider)
        $apps_installdate_formatted = Get-Date -Date $apps_installdate_before -Format 'M-dd-yyy HH:mm:ss tt'
        $apps_installdate_formatted = $apps_installdate_formatted
        if($VerboseDebug)
        {
          Write-EZLogs " | Installdate ($apps_installdate_formatted) retrieved from Installfolder ($b_InstallFolder) from ($a_InstallLocation)" -color DarkMagenta -LogFile $logfile
        }
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to get Creation Time value to use for InstallDate for app ($($displayname)) - $_" -showtime -Warning -LogFile $logfile
        } 
        $apps_installdate_formatted = $null
      } 
    }
    elseif($a.Type -eq 'UWP')
    {
      try
      {
        $appxlog = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-AppxDeploymentServer/Operational';ID=613;ProviderName='Microsoft-Windows-AppxDeployment-Server'} | where {
          $_.Properties[1].value -match "$($a.DisplayNameRaw)"
        } | select * -First 1
        $apps_installdate_before = [datetime]::ParseExact($appxlog.TimeCreated.tostring('MM/dd/yyyy hh:mm:ss tt'),'MM/dd/yyyy hh:mm:ss tt',$provider)
        $apps_installdate_formatted = Get-Date -Date $apps_installdate_before -Format 'M-dd-yyy HH:mm:ss tt'
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to get Time Created value from Get-Appxlog to use for InstallDate for app ($($a.DisplayNameRaw)) - $_" -showtime -Warning -LogFile $logfile
        } 
        $apps_installdate_formatted = $null
      } 
    }    
    elseif($a_UninstallString -and $a_UninstallString -notmatch 'MsiExec.exe')
    {
      try
      {
        $b_InstallFolder = [System.IO.Path]::GetDirectoryName(($a_UninstallString.Split('"') | where {
              $_
        } | select -First 1)) 2>$null
        if (Test-Path -LiteralPath $b_InstallFolder)
        {
          $b_InstallDate = Get-ItemProperty $b_InstallFolder | select CreationTime
          $apps_installdate_before = [datetime]::ParseExact($b_InstallDate.CreationTime.tostring('MM/dd/yyyy hh:mm:ss tt'),'MM/dd/yyyy hh:mm:ss tt',$provider)
          $apps_installdate_formatted = Get-Date -Date $apps_installdate_before -Format 'M-dd-yyy HH:mm:ss tt'
          $apps_installdate_formatted = $apps_installdate_formatted
        }
        else
        {
          $b_InstallFolder = $($a_UninstallString -replace '"', '').Split('/')
          $b_InstallFolder = $b_InstallFolder[0].Trim()
          $b_InstallFolder = [System.IO.Path]::GetDirectoryName($b_InstallFolder) 2>$null
          $b_InstallDate = Get-ItemProperty $b_InstallFolder | select CreationTime
          $apps_installdate_before = [datetime]::ParseExact($b_InstallDate.CreationTime.tostring('MM/dd/yyyy hh:mm:ss tt'),'MM/dd/yyyy hh:mm:ss tt',$provider)
          $apps_installdate_formatted = Get-Date -Date $apps_installdate_before -Format 'M-dd-yyy HH:mm:ss tt'
          #Update-LogWindow  -Content "($($a.DisplayName)) InstallDate from Uninstall Path: $apps_installdate_formatted" -showtime -foregroundcolor cyan -enablelogs
          $apps_installdate_formatted = $apps_installdate_formatted 
        }
        if($VerboseDebug)
        {
          Write-EZLogs " | Installdate ($apps_installdate_formatted) retrieved from UninstallString folder ($b_InstallFolder) from ($a_UninstallString)" -color DarkMagenta -LogFile $logfile
        }
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to get Uninstall Path creation time value to use for InstallDate for app ($($displayname)) - $_" -showtime -Warning -LogFile $logfile
        } 
        $apps_installdate_formatted = $null
      }
    }
    else
    {
      $apps_installdate_formatted = $null
    }
    #Get estimated size
    If ($a_EstimatedSize)
    {
      $estimatedsize = $([Math]::Round([int64]($a.EstimatedSize)/1MB,1))
      if ($estimatedsize -ige 1)
      {
        $estimatedsize = "$([Math]::Round([int64]($a.EstimatedSize)/1MB,2)) GB"
      }
      else
      {
        $estimatedsize = "$([Math]::Round([int64]($a.EstimatedSize)/1KB,0)) MB"
      }
    }
    elseif($a_InstallLocation)
    {
      try
      {
        $a_InstallLocation = $a_InstallLocation -replace '"', ''
        $FSO = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
        $TotalBytes = $FSO.GetFolder($a_InstallLocation).Size
        $TotalBytes = [decimal] $TotalBytes
        $TotalMBytes = [math]::Round(([decimal] $TotalBytes / 1MB), 2)
        $TotalGBytes = [math]::Round(([decimal] $TotalBytes / 1GB), 2)
        
        $estimatedsize = $TotalGBytes
        if ($estimatedsize -ile 0.99)
        {
          $estimatedsize = "$($TotalMBytes) MB"
        }
        else
        {
          $estimatedsize = "$($TotalGBytes) GB"
        }
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to get InstallLocation size to use for EstimatedSize for app ($($displayname)) from folder ($a_InstallLocation) - $_" -showtime -Warning -LogFile $logfile
          $estimatedsize = $null
        }
      }    
    }
    elseif($b_InstallFolder)
    {
      try
      {
        $FSO = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
        $TotalBytes = $FSO.GetFolder($b_InstallFolder).Size
        $TotalBytes = [decimal] $TotalBytes
        $TotalMBytes = [math]::Round(([decimal] $TotalBytes / 1MB), 2)
        $TotalGBytes = [math]::Round(([decimal] $TotalBytes / 1GB), 2)
        
        $estimatedsize = $TotalGBytes
        if ($estimatedsize -ile 0.99)
        {
          $estimatedsize = "$($TotalMBytes) MB"
        }
        else
        {
          $estimatedsize = "$($TotalGBytes) GB"
        }
      }
      catch
      {
        if ($VerboseLog)
        {
          Write-EZLogs "Unable to get UninstallPath size to use for EstimatedSize for app ($($displayname)) from folder ($b_InstallFolder) - $_" -showtime -Warning -LogFile $logfile
          $estimatedsize = $null
        }      
      }
    }
    $software_name = "$($displayname)"
    $AppType = $null
    $StoreIDs = $null
    if ($a.Type -eq 'UWP')
    {
      $Type = 'UWP'
      #$appx_manifest = (Get-AppxPackage $a.DisplayNameRaw -AllUsers | Get-AppxPackageManifest).package
      #$Executable = $appx_manifest.applications.application.Executable
      #$AppType = $appx_manifest.applications.application.Id
      $config_file = "$($a.InstallLocation)\MicrosoftGame.config"
      $test_path = test-path $config_file -PathType Leaf
      if($test_path){
        if($VerboseLog){write-ezlogs " | Found XboxPC appx package $displayname config file: $config_file" -enablelogs -showtime -color Green}
        $Game_Config = Get-ChildItem "$($a.InstallLocation)\MicrosoftGame.config" | Select-String "StoreId","Executable"
        $StoreIDs = $(($Game_Config | Select-String "StoreId").Line.trim() | foreach {([string]$_ -replace '<storeId>','' -split('<'))[0]} | ? { $_ } | % { ([string]$_).trim() } | ? { $_ }) -join ','
        $pattern = " Name=`"(?<value>.*)"
        if($Game_Config){$search_string = ($Game_Config | Select-String " Name=").Line.trim() | select -last 1 -ErrorAction SilentlyContinue}
        $Executable = ([regex]::matches($search_string, $pattern)| %{$_.groups[1].value} ).split('"')[0]
        
        <#        if(!$StoreIDs){
            $StoreIDs = $(($Game_Config | Select-String "TitleId").Line.trim() | foreach {([string]$_ -replace '<TitleId>','' -split('<'))[0]} | ? { $_ } | % { ([string]$_).trim() } | ? { $_ }) -join ','
        }#>
        $AppType = 'Game'   
      }
      else
      {
        if($VerboseLog){write-ezlogs " | Unable to find $config_file for $displayname. Checking for xboxservices.config" -enablelogs -showtime -Warning}
        $config_file = "$($a.InstallLocation)\xboxservices.config"
        $test_path = test-path $config_file -PathType Leaf
        if($test_path -and $displayname -ne "Xbox Console Companion"){
          if($VerboseLog){write-ezlogs " | Found XboxPC appx package $displayname config file: $config_file" -enablelogs -showtime -color Green}
          $appx_manifest = (Get-AppxPackage $a.DisplayNameRaw -AllUsers | Get-AppxPackageManifest).package
          $Executable = $appx_manifest.applications.application.Executable
          #$StoreIDs = $appx_manifest.applications.application.Id
          $AppType = 'Game' 
        }
      }     
    }
    else
    {
      $Type = 'Desktop'
    }    
    $all_apps_output = New-Object -TypeName 'System.Collections.ArrayList'     
    $newRow = New-Object PsObject -Property @{
      'Software' = $software_name
      'Display Name' = $displayname
      'PackageName' = $a.PackageFamilyName
      'StoreID' = $StoreIDs      
      'Executable' = $Executable
      'AppType' = $AppType
      'Display Version' = $a.DisplayVersion
      'Publisher' = $a.Publisher
      'InstallDate' = $apps_installdate_formatted
      'InstallSource' = $a.InstallSource  
      'Install Location' = $a.InstallLocation
      'InstallPath' = $a.InstallPath
      'EstimatedSize' = $estimatedsize
      'User Profiles' = $a.UserProfiles
      'UninstallString' = $a.UninstallString
      'QuietUninstallString' = $a.QuietUninstallString
      'Modify Path' = $a.ModifyPath
      'Readme' = $a.Readme
      'URLInfo About' = $a.URLInfoAbout
      'URLUpdate Info' = $a.URLUpdateInfo
      'Windows Installer' = $a.WindowsInstaller
      'Help Link' = $a.HelpLink
      'Comments' = $a.Comments
      'LaunchCommand' = $a.LaunchCommand
      'Type' = $Type
    }
    $null = $all_apps_output.Add($newRow)
    Write-Output $all_apps_output | where {$_.'Display Name'}
  }
  if($enable_stopwatch)
  {
    Write-EZLogs ">>>> Get-InstalledApplications StopWatch Timer Stopped - Total Seconds Taken: $($GetApps_stopwatch.Elapsed.TotalSeconds)" -showtime -color cyan -LogFile $logfile
    $GetApps_stopwatch.stop()
    $GetApps_stopwatch.reset()
  }  
}
#---------------------------------------------- 
#endregion Get-InstalledApplications Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-InstalledApplications')