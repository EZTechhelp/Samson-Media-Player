<#
    .Name
    Uninstall-Application

    .Version 
    0.1.0

    .SYNOPSIS
    Uninstalls and removes all components for the provided application 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Uninstall-Application Function
#----------------------------------------------
function Uninstall-Application
{
  <#
      .Name
      Uninstall-Application

      .Version 
      0.1.0

      .SYNOPSIS
      Uninstalls and removes all components for the provided application 

      .DESCRIPTION
       
      .Configurable Variables

      .Requirements
      - Powershell v3.0 or higher
      - Module designed for Samson Media Player

      .OUTPUTS
      System.Management.Automation.PSObject

      .Author
      EZTechhelp - https://www.eztechhelp.com

      .NOTES

  #>
  Param (
    $thisApp,
    $synchash,
    [system.diagnostics.stopwatch]$globalstopwatch = $globalstopwatch,
    [switch]$Verboselog
  )
  try{
    #---------------------------------------------- 
    #region Detect Install and Launch
    #----------------------------------------------
    try{
      #Detect install
      #$install_properties = (Get-ItemProperty "Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -Filter $app_name) | where {$_.DisplayName -match $app_name}
      $setup_startup_stopwatch = [system.diagnostics.stopwatch]::StartNew()
      $app_Name = $thisApp.Config.App_Name
      $Current_Folder = $thisApp.Config.Current_Folder
      Write-EZLogs "######## Starting Uninstaller for $app_name ########" -logtype Uninstall -linesbefore 1
      $valid_secrets = @( 
        'TwitchClientId'
        'TwitchClientSecret'
        'TwitchRedirectUri'
        'Twitchexpires'
        'Twitchaccess_token'
        'Twitchscope'
        'Twitchrefresh_token'
        'Twitchtoken_type'
        'TwitchUserId'
        'TwitchUsername' 
        'Twitchprofile_image_url'
        'SpotyClientId'
        'SpotyClientSecret'
        'SpotyRedirectUri'
        'Spotyexpires'
        'Spotyaccess_token'
        'Spotyscope'
        'Spotyrefresh_token' 
        'Spotytoken_type'
        'YoutubeAccessToken'
        'Youtubeexpires_in'
        'Youtubecode'
        'Youtuberefresh_token'
      )
      $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default') 
      foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {
        if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
          $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
        }
      }  
      if(!$install_folder){
        $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
        foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {  
          if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
            $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
          }
        }
      } 
      [void]$Registry.Dispose()
      if($install_folder){
        write-ezlogs ">>>> Found install folder from registry: $install_folder" -logtype Uninstall
        $ExePath = [System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).exe")
      }else{
        write-ezlogs ">>>> Unable to find install folder from registry: $install_folder" -logtype Uninstall -Warning
      }
      #$Main_Script = [System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).ps1")
      [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      $oReturn=[System.Windows.Forms.MessageBox]::Show("[UNINSTALL] Do you wish to remove all of the following components that were installed as part of $app_Name`?`n`nApp: Streamlink`nApp: Spicetify`nModule: BurntToast`nModule: SecretManagement`nApp: Chocolatey","$app_name",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question) 
      switch ($oReturn){
        "Yes" {
          write-ezlogs ">>>> User wish to remove all components" -logtype Uninstall
          #Streamlink
          try{
            #$env:ChocolateyInstall = "$env:SystemDrive\Users\Public\chocolatey"
            if($env:ChocolateyInstall -and ([System.IO.File]::Exists("$env:ChocolateyInstall\Choco.exe") -or [System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe"))){          
              $chocoappmatch = choco list Streamlink
              $appinstalled = $($chocoappmatch | Select-String Streamlink | out-string).trim()
            }
            if($appinstalled){
              write-ezlogs ">>>> Removing Streamlink via Chocolatey" -logtype Uninstall
              choco uninstall Streamlink --confirm --force
            }elseif([System.IO.File]::Exists("$("${env:ProgramFiles(x86)}\Streamlink\uninstall.exe")")){
              write-ezlogs ">>>> Removing Streamlink using uninstaller" -logtype Uninstall
              start-process "${env:ProgramFiles(x86)}\Streamlink\uninstall.exe" -Wait
            }elseif([System.IO.File]::Exists("$("${env:ProgramFiles}\Streamlink\uninstall.exe")")){
              write-ezlogs ">>>> Removing Streamlink using uninstaller" -logtype Uninstall
              start-process "${env:ProgramFiles}\Streamlink\uninstall.exe" -Wait
            }  
            if([System.IO.Directory]::Exists("$env:APPDATA\streamlink")){
              write-ezlogs ">>>> Removing streamlink files: $env:APPDATA\streamlink" -logtype Uninstall
              [void][System.IO.Directory]::Delete("$env:APPDATA\streamlink",$true)
            }
          }catch{
            write-ezlogs "An exception occurred removing Streamlink" -CatchError $_ -logtype Uninstall
          }    
          #Spicetify
          try{
            if([System.IO.File]::Exists("$($env:USERPROFILE)\spicetify-cli\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\.spicetify\config-xpui.ini")){
              write-ezlogs ">>>> Removing spicetify from $($env:USERPROFILE)\spicetify-cli\spicetify.exe" -logtype Uninstall
              write-ezlogs "| Restoring any changes to Spotify" -logtype Uninstall  
              spicetify restore                          
            }
            if([System.IO.Directory]::Exists("$env:USERPROFILE\.spicetify")){
              write-ezlogs "| Removing Spicetify files: $env:USERPROFILE\.spicetify" -logtype Uninstall
              [void][System.IO.Directory]::Delete("$env:USERPROFILE\.spicetify",$true)
            }
            if([System.IO.Directory]::Exists("$env:USERPROFILE\spicetify-cli")){
              write-ezlogs "| Removing Spicetify files: $env:USERPROFILE\spicetify-cli" -logtype Uninstall
              [void][System.IO.Directory]::Delete("$env:USERPROFILE\spicetify-cli",$true)
            }
            if([System.IO.Directory]::Exists("$env:APPDATA\spicetify")){
              write-ezlogs "| Removing Spicetify files: $env:APPDATA\spicetify" -logtype Uninstall
              [void][System.IO.Directory]::Delete("$env:APPDATA\spicetify",$true)
            }                           
          }catch{
            write-ezlogs "An exception occurred removing Spicetify" -CatchError $_ -logtype Uninstall
          }
  
          #vb-cable
          try{
            $appinstalled = $Null
            if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe").versioninfo.fileversion -replace ', ','.'
              $vbcablesetup = "$($Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe"
            }elseif([System.IO.File]::Exists("${env:ProgramFiles}\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("${env:ProgramFiles}\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
              $vbcablesetup = "$($Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe"
            }
            if($appinstalled){
              write-ezlogs ">>>> Removing vb-cable version: $appinstalled" -logtype Uninstall
              Start-Process "$vbcablesetup" -ArgumentList '-u -h' -Wait -Verb RunAs
            } 
          }catch{
            write-ezlogs "An exception occurred removing vb-cable" -CatchError $_ -logtype Uninstall
          }

          #Modules
          try{
            if((Get-Module Burnttoast -ErrorAction SilentlyContinue)){
              write-ezlogs ">>>> Removing module BurntToast" -logtype Uninstall  
              Uninstall-Module BurntToast -Force -ErrorAction Continue
              Remove-Module BurntToast -Force -ErrorAction Continue
            }  
          }catch{
            write-ezlogs "An exception occurred removing module BurntToast" -CatchError $_ -logtype Uninstall
          }       
          #secretvault 
          try{
            $SecretManagement_Modules = "$Current_Folder\Modules\Microsoft.PowerShell.SecretManagement\Microsoft.PowerShell.SecretManagement.psd1"
            $SecretStore_Modules = "$Current_Folder\Modules\Microsoft.PowerShell.SecretStore\Microsoft.PowerShell.SecretStore.psd1"
            $SecretStoreExtension_Modules = "$Current_Folder\Modules\Microsoft.PowerShell.SecretStore\Microsoft.PowerShell.SecretStore.Extension\Microsoft.PowerShell.SecretStore.Extension.psd1"
            if([system.io.file]::Exists($SecretManagement_Modules)){
              Import-Module $SecretManagement_Modules
            }
            if([system.io.file]::Exists($SecretStore_Modules)){
              Import-Module $SecretStore_Modules
            }
            if([system.io.file]::Exists($SecretStoreExtension_Modules)){
              Import-Module $SecretStoreExtension_Modules
            }
            if((get-command -module Microsoft.PowerShell.SecretManagement)){           
              if((Get-SecretVault -name $app_name)){
                write-ezlogs ">>>> Removing $app_name Secret Vault" -logtype Uninstall
                Reset-SecretStore -Password:$($app_name | ConvertTo-SecureString -AsPlainText -Force) -Force
                Unlock-SecretStore -password:$($app_name | ConvertTo-SecureString -AsPlainText -Force) -ErrorAction SilentlyContinue
                foreach($secret in $valid_secrets){
                  if((Get-Secret -Name $secret -VaultName $app_name -ErrorAction SilentlyContinue)){
                    write-ezlogs "| Removing Secret $($secret)" -logtype Uninstall
                    Remove-secret -Name $($secret.name) -Vault $app_name -ErrorAction SilentlyContinue
                  }
                }
                write-ezlogs "| Unregistering Secret Vault $app_name" -logtype Uninstall
                Unregister-SecretVault -SecretVault (Get-SecretVault -name $app_name -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue           
                Remove-Module Microsoft.PowerShell.SecretManagement -Force -ErrorAction SilentlyContinue
                if((get-command -module Microsoft.PowerShell.SecretStore -ErrorAction SilentlyContinue)){
                  Remove-Module Microsoft.PowerShell.SecretStore -Force -ErrorAction SilentlyContinue
                }          
              }else{
                write-ezlogs "No Secret Vault found with name: $app_name" -logtype Uninstall -Warning
              }
            }  
          }catch{
            write-ezlogs "An exception occurred removing Secrets and module SecretManagement" -CatchError $_ -logtype Uninstall
          }    
          #Choco removal
          if([System.IO.Directory]::Exists($env:ChocolateyInstall) -or ([System.IO.File]::Exists("$env:ProgramData\chocolatey\Choco.exe")) -or ([System.IO.Directory]::Exists("$env:ProgramData\chocolatey\")) -or [System.IO.Directory]::Exists("$env:SystemDrive\Users\Public\chocolatey")){
            try{
              Uninstall-Chocolatey -thisApp $thisApp
              if([System.IO.Directory]::Exists($env:ChocolateyInstall)){
                write-ezlogs ">>>> Removing Chocolately from path: $env:ChocolateyInstall" -logtype Uninstall
                $Null = Remove-item "$env:ChocolateyInstall" -Recurse -Force
              }elseif([System.IO.Directory]::Exists("$env:ProgramData\chocolatey\")){
                write-ezlogs ">>>> Removing Chocolately from path: $env:ProgramData\chocolatey\" -logtype Uninstall
                $Null = Remove-item "$env:ProgramData\chocolatey\" -Recurse -Force
              }elseif([System.IO.Directory]::Exists("$env:SystemDrive\Users\Public\chocolatey")){
                write-ezlogs ">>>> Removing Chocolately from path: $env:SystemDrive\Users\Public\chocolatey" -logtype Uninstall
                $Null = Remove-item "$env:SystemDrive\Users\Public\chocolatey" -Recurse -Force
              }
            }catch{
              write-ezlogs "An exception occurred attempting to remove Chocolately - ($env:ChocolateyInstall)" -CatchError $_ -logtype Uninstall
            }
          }  
          #Temp Files Removal
          if([System.IO.Directory]::Exists("$($env:temp)\$app_name")){
            try{
              write-ezlogs ">>>> Removing temp directory: $($env:temp)\$app_name" -logtype Uninstall
              [void][System.IO.Directory]::Delete("$($env:temp)\$app_name",$true)
            }catch{
              write-ezlogs "An exception occurred attempting to remove temp directory - ($($env:temp)\$app_name)" -CatchError $_ -logtype Uninstall
            }
          } 
          #High DPI Reg Removal
          if([System.IO.Directory]::Exists($ExePath)){
            try{ 
              $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
              $keys = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\")
              $Keyname = $keys.GetValueNames() | & { process {
                  if($_ -eq $ExePath -or $_ -match "$($thisApp.Config.App_Name).exe"){
                    $_
                  }
              }}
              if($Keyname){
                write-ezlogs ">>>> Removing High DPI registry key: $Keyname" -logtype Uninstall
                $null = Remove-ItemProperty -Path 'Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\' -Name $Keyname -Force -ErrorAction SilentlyContinue
              }
            }catch{
              write-ezlogs "An exception occurred checking for or removing high DPI registry key for process: $ExePath" -CatchError $_
            }finally{
              if($Registry -is [System.IDisposable]){
                $Registry.dispose()
              }
              if($keys -is [System.IDisposable]){
                $keys.dispose()
              }
            }
          }                     
        } 
        "No" {
          write-ezlogs ">>>> User DID NOT wish to remove all components" -logtype Uninstall
        } 
      }
      $oReturn=[System.Windows.Forms.MessageBox]::Show("[UNINSTALL] Do you wish to remove all user data for $app_Name`? Includes:`n`n-Media Library Profiles`n-Playlist Profiles`n-App Config Settings`n-Custom EQ/Audio Settings`n`nNOTE: Log files will remain and can be manually deleted at $env:APPDATA\$app_Name\Logs","$app_name",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question) 
      switch ($oReturn){
        "Yes" {
          write-ezlogs ">>>> User wishes to remove all user data" -logtype Uninstall
          #user data excluding logs
          try{
            if([System.IO.Directory]::Exists("$env:APPDATA\$app_Name\MediaProfiles")){
              write-ezlogs "| Removing: $env:APPDATA\$app_Name\MediaProfiles" -logtype Uninstall
              $null = Remove-item "$env:APPDATA\$app_Name\MediaProfiles" -Force -Recurse
            }
            if([System.IO.Directory]::Exists("$env:APPDATA\$app_Name\PlaylistProfiles")){
              write-ezlogs "| Removing: $env:APPDATA\$app_Name\PlaylistProfiles" -logtype Uninstall
              $null = Remove-item "$env:APPDATA\$app_Name\PlaylistProfiles" -Force -Recurse
            }
            if([System.IO.Directory]::Exists("$env:APPDATA\$app_Name\EQPresets")){
              write-ezlogs "| Removing: $env:APPDATA\$app_Name\EQPresets" -logtype Uninstall
              $null = Remove-item "$env:APPDATA\$app_Name\EQPresets" -Force -Recurse
            }        
            if([System.IO.File]::Exists("$env:APPDATA\$app_Name\$app_Name-Config.xml")){
              write-ezlogs "| Removing: $env:APPDATA\$app_Name\$app_Name-Config.xml" -logtype Uninstall
              $null = Remove-item "$env:APPDATA\$app_Name\$app_Name-Config.xml" -Force -Recurse
            } 
            if([System.IO.File]::Exists("$env:APPDATA\$app_Name\$app_Name-SConfig.xml")){
              write-ezlogs "| Removing: $env:APPDATA\$app_Name\$app_Name-SConfig.xml" -logtype Uninstall
              $null = Remove-item "$env:APPDATA\$app_Name\$app_Name-SConfig.xml" -Force -Recurse
            }                              
          }catch{
            write-ezlogs "An exception occurred attempting to remove user data" -CatchError $_ -logtype Uninstall
            $oReturn=[System.Windows.Forms.MessageBox]::Show("[UNINSTALL ERROR] An exception occurred attempting to remove user data, you may need to remove files/folders manually at: $env:APPDATA\$app_Name`n`n$($_ | out-string)","ERROR - $app_name",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
          }           
        } 
        "No" {
          write-ezlogs ">>>> User DID NOT wish to remove user data" -logtype Uninstall
        } 
      }
      try{
        if([System.IO.Directory]::Exists($Current_Folder) -and ![System.IO.Directory]::Exists($install_folder) -and ![System.IO.File]::Exists($ExePath) -and ![System.Diagnostics.Process]::GetProcessesByName("unins000")){
          write-ezlogs "[TODO_NOT_IMPLEMENTED]>>>> Removing all application, script, module and resource files" -logtype Uninstall
          #[void][System.IO.Directory]::Delete($Current_Folder,$true)
        }
      }catch{
        write-ezlogs "An exception occurred removing exe at: $ExePath" -CatchError $_ -logtype Uninstall
      }
    }catch{
      write-ezlogs "An exception occurred in Uninstall-Application" -CatchError $_ -logtype Uninstall
    }
    #---------------------------------------------- 
    #endregion Detect Install and Launch
    #----------------------------------------------
  }catch{
    write-ezlogs "An exception occurred in Uninstall-Application" -CatchError $_ -showtime
  }finally{
    if($error){
      write-ezlogs "Encountered errors during uninstall" -PrintErrors -ErrorsToPrint $error -logtype Uninstall
    }
    if($setup_startup_stopwatch){
      $setup_startup_stopwatch.Stop()
      write-ezlogs "Uninstall Execution Time" -logtype Uninstall -PerfTimer $setup_startup_stopwatch -Perf
    }
    write-ezlogs "######## Exiting Uninstaller And Application ########" -logtype Uninstall
    Stop-EZlogs -stoptimer -logfile $thisApp.Config.Uninstall_Log_File -logOnly -enablelogs -thisApp $thisApp -ShutdownWait -globalstopwatch $globalstopwatch
    Stop-Process $pid -Force
  }
}
#---------------------------------------------- 
#endregion Uninstall-Application Function
#----------------------------------------------

#---------------------------------------------- 
#region Uninstall-Chocolatey Function
#----------------------------------------------
function Uninstall-Chocolatey
{
  <#
      .Name
      Uninstall-Chocolatey

      .Version 
      0.1.0

      .SYNOPSIS
      Uninstalls and removes all components for Chocolatey

      .DESCRIPTION
       
      .Configurable Variables

      .Requirements
      - Powershell v3.0 or higher
      - Module designed for Samson Media Player

      .OUTPUTS
      System.Management.Automation.PSObject

      .Author
      EZTechhelp - https://www.eztechhelp.com

      .NOTES

  #>
  Param (
    $thisApp,
    [switch]$Verboselog
  )
  try{
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    $VerbosePreference = 'Continue'
    if (-not $env:ChocolateyInstall) {
      $message = @(
        "The ChocolateyInstall environment variable was not found."
        "Chocolatey is not detected as installed. Nothing to do."
      ) -join "`n"

      Write-EZLogs $message -logtype Uninstall -Warning
      return
    }

    if (-not (Test-Path $env:ChocolateyInstall)) {
      $message = @(
        "No Chocolatey installation detected at '$env:ChocolateyInstall'."
        "Nothing to do."
      ) -join "`n"

      Write-EZLogs $message -logtype Uninstall -Warning
      return
    }

    <#
        Using the .NET registry calls is necessary here in order to preserve environment variables embedded in PATH values;
        Powershell's registry provider doesn't provide a method of preserving variable references, and we don't want to
        accidentally overwrite them with absolute path values. Where the registry allows us to see "%SystemRoot%" in a PATH
        entry, PowerShell's registry provider only sees "C:\Windows", for example.
    #>
    $userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    $machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\',$true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    $backupPATHs = @(
      "User PATH: $userPath"
      "Machine PATH: $machinePath"
    )
    $backupFile = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    $warningMessage = @"
    This could cause issues after reboot where nothing is found if something goes wrong.
    In that case, look at the backup file for the original PATH values in '$backupFile'.
"@

    if ($userPath -like "*$env:ChocolateyInstall*") {
      Write-EZLogs ">>>> Chocolatey Install location found in User Path. Removing..." -logtype Uninstall
      Write-EZLogs $warningMessage -logtype Uninstall -Warning

      $newUserPATH = @(
        $userPath -split [System.IO.Path]::PathSeparator |
        Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
      ) -join [System.IO.Path]::PathSeparator

      # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
      # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
      $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }

    if ($machinePath -like "*$env:ChocolateyInstall*") {
      Write-Verbose "Chocolatey Install location found in Machine Path. Removing..."
      Write-Warning $warningMessage

      $newMachinePATH = @(
        $machinePath -split [System.IO.Path]::PathSeparator |
        Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
      ) -join [System.IO.Path]::PathSeparator

      # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
      # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
      $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
    }

    # Adapt for any services running in subfolders of ChocolateyInstall
    $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
    if ($agentService -and $agentService.Status -eq 'Running') {
      $agentService.Stop()
    }
    # TODO: add other services here
    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force -ErrorAction SilentlyContinue
    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | & { Process {
        foreach ($scope in 'User', 'Machine') {
          [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }}
    $machineKey.Close()
    $userKey.Close()
  }catch{
    write-ezlogs "An exception occurred in Uninstall-Chocolatey" -CatchError $_ -showtime
  }finally{
    if($stopwatch){
      $stopwatch.Stop()
      write-ezlogs "Uninstall-Chocolatey Execution Time" -logtype Uninstall -PerfTimer $stopwatch -Perf
    }
  }
}
#---------------------------------------------- 
#endregion Uninstall-Chocolatey Function
#----------------------------------------------
Export-ModuleMember -Function @('Uninstall-Application','Uninstall-Chocolatey')