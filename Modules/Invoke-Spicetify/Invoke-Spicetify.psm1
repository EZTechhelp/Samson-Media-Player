<#
    .Name
    Invoke-Spicetify

    .Version 
    0.1.0

    .SYNOPSIS
    Executes spicetify to apply, backup or remove customizations to Spotify 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher

    .RequiredModules

    .EXAMPLE

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
#>

#----------------------------------------------
#region Enable-Spicetify Function
#----------------------------------------------
function Enable-Spicetify
{
  param (
    $synchash,
    $thisapp,
    $thisScript,  
    [switch]$Verboselog
  )
  try{
    write-ezlogs ">>>> Verifying Spotify installation" -showtime
    if([System.IO.File]::Exists("$($env:APPDATA)\\Spotify\\Spotify.exe")){
      write-ezlogs " | Spotify is installed at $($env:APPDATA)\\Spotify\\Spotify.exe" -showtime
      $synchash.Spotify_install_status = 'Installed'
      $Spotify_Path = "$($env:APPDATA)\\Spotify\\Spotify.exe"
    }elseif((Get-appxpackage 'Spotify*')){
      write-ezlogs ">>>> Spotify installed as $Spotify_Path" -showtime
      $Spotify_Path = "$((Get-appxpackage 'Spotify*').InstallLocation)\\Spotify.exe"
      $synchash.Spotify_install_status = 'StoreVersion'
      Update-Notifications -id 1 -Level 'ERROR' -Message "You are using Spotify Windows Store version, which is not supported with Spicetify.`nYou must remove the Windows Store version and install the normal version!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash -open_flyout
      return      
    }else{
      write-ezlogs "Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!" -warning
      $synchash.Spotify_install_status = 'NotInstalled'
      Update-Notifications -id 1 -Level 'ERROR' -Message "Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash -open_flyout
      return
    }   
    
    if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
      $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")
      if(!$appinstalled){
        $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
      }           
    }
    if(!$appinstalled){
      write-ezlogs ">>>> Installing Spicetify" -showtime    
      start-sleep -Milliseconds 500
      if($hash.Window.Dispatcher){       
        $hash.Window.Dispatcher.invoke([action]{
            $hash.More_Info_Msg.Visibility = 'Visible'
            $hash.More_info_Msg.text = "Installing Spicetify"
        },'Normal')  
      }               
      Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression -Verbose
      Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1" | Invoke-Expression -Verbose
      if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
        $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini").Backup.with
        if(!$appinstalled){
          $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
        }
      }    
    }        
  }catch{
    write-ezlogs "An exception occurred attempting to install Spicetify" -showtime -catcherror $_
  }
  if($appinstalled){
    if(!(Get-command -Module Pode)){         
      try{
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Pode\2.6.2\Pode.psm1" -Force         
      }catch{
        write-ezlogs "An exception occurred Importing required module Pode" -showtime -catcherror $_
        return $false
      }     
    }   
    $custom_webnowplaying = "$($thisapp.config.Current_Folder)\\Resources\\Spicetify\\webnowplaying.js"
    $webnowplaying_file = "$($env:userprofile)\\spicetify-cli\Extensions\\webnowplaying.js"
    $webnowplaying_file_backup = "$($env:userprofile)\\spicetify-cli\Extensions\\webnowplaying.js.bak"  
    try{
      $custom_webnowplaying_content = Get-Content $custom_webnowplaying -ReadCount 0 -Force -Encoding UTF8 -Verbose:$thisapp.Config.Verbose_logging
      $Spotify_pref = ($appinstalled).Setting.prefs_path  
      $Spotify_ini_Path = $appinstalled.setting.spotify_path    
      if(!([System.IO.Directory]::Exists($Spotify_pref))){
        write-ezlogs "Spicetify spotify pref path not valid at $Spotify_pref" -showtime -warning
        if([System.IO.Directory]::Exists( "$($env:userprofile)\AppData\Roaming\Spotify\prefs")){
          write-ezlogs "Updating spotify pref with path $($env:userprofile)\AppData\Roaming\Spotify\prefs"
          $pref_content = Get-Content "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force
          $pref_content = $pref_content -replace [regex]::escape($Spotify_pref),"$($env:userprofile)\AppData\Roaming\Spotify\prefs"
          $pref_content | Out-File "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force          
        }
      }
      if(!([System.IO.Directory]::Exists($Spotify_ini_Path))){
        write-ezlogs "Spicetify spotify path not valid at $Spotify_ini_Path" -showtime -warning
        if([System.IO.Directory]::Exists("$([System.IO.Directory]::GetParent($Spotify_Path).FullName)")){
          write-ezlogs "Updating spotify pref with path $($env:userprofile)\AppData\Roaming\Spotify\prefs"
          $path_content = Get-Content "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force
          $path_content = $path_content -replace [regex]::escape($Spotify_ini_Path),"$([System.IO.Directory]::GetParent($Spotify_Path).FullName)"
          $path_content | Out-File "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force          
        }
      }      
    }catch{
      write-ezlogs "An exception occurred checking spicetify spotify pref path $Spotify_pref" -showtime -catcherror $_
    }
    if(![System.IO.File]::Exists($webnowplaying_file)){
      write-ezlogs '>>>> Webnowplaying extension not found, forcing install of Spicetify and Spicetify marketplace' -showtime -color cyan
      Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1' | Invoke-Expression
      Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1' | Invoke-Expression        
      spicetify.exe backup 
      spicetify.exe config inject_css 0 replace_colors 0
      spicetify.exe config extensions webnowplaying.js
      if(Get-Process *Spotify* -ErrorAction SilentlyContinue){Get-Process *Spotify* | Stop-Process -Force -ErrorAction SilentlyContinue}
    }
    $webnowplaying_file_content = Get-Content $webnowplaying_file -ReadCount 0 -Force -Verbose:$thisapp.Config.Verbose_logging
    $webnowplaying_compare = Compare-Object $custom_webnowplaying_content -DifferenceObject $webnowplaying_file_content -Verbose:$thisapp.Config.Verbose_logging
    if (!$webnowplaying_compare)
    {
      Write-ezlogs '>>>> Webnowplaying extension already patched, skipping...' -color cyan -showtime
    }
    else
    {
      try
      {         
        write-ezlogs '>>>> Executing Spicetify backup' -showtime -color cyan
        spicetify.exe backup          
        write-ezlogs '>>>> Creating Backup of existing webnowplaying.js' -Color cyan -showtime
        $null = Copy-Item $webnowplaying_file -Destination ([System.IO.Path]::Combine("$($env:userprofile)\\spicetify-cli\Extensions", 'backup_webnowplaying.js')) -Force -ErrorAction stop -Verbose:$thisapp.Config.Verbose_logging  
        #backup js file within directory
        if(![System.IO.File]::Exists($webnowplaying_file_backup)){
          $null = Rename-Item -Path $webnowplaying_file -NewName 'webnowplaying.js.bak' -Force -ErrorAction Continue -Verbose:$thisapp.Config.Verbose_logging
        }
        write-ezlogs ' | Adding patched webnowplaying.js' -showtime 
        $null = Set-Content $webnowplaying_file -value $custom_webnowplaying_content -Force -Encoding UTF8 -ErrorAction stop -Verbose:$thisapp.Config.Verbose_logging    
        Write-ezlogs '[SUCCESS] Successfully patched webnowplaying.js' -Color Green -showtime                   
      }
      catch
      {
        write-ezlogs 'An error occurred while applying customized webnowplaying.js' -showtime -catcherror $_
      }
    } 
    try
    {              
      write-ezlogs '>>>> Applying Spicetify customizations' -Color cyan -showtime
      if($hash.Window){
        $hash.Window.Dispatcher.invoke([action]{
            $hash.More_Info_Msg.Visibility = 'Visible'
            $hash.More_info_Msg.text = 'Applying Spicetify customizations to Spotify'
        },'Normal')
      }
      #spicetify apply        
      $spicetifyupgrade_logfile = "$env:temp\\spicetify_upgrade.log"
      if([System.IO.FIle]::Exists($spicetifyupgrade_logfile)){
        $null = Remove-Item $spicetifyupgrade_logfile -Force
      }
      $command = "& `"spicetify`" upgrade *>$spicetifyupgrade_logfile"   
      $block = 
      {
        Param
        (
          $command
      
        )
        $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
      }   
      #Remove all jobs and set max threads
      Get-Job | Remove-Job -Force
      $MaxThreads = 3
  
      #Start the jobs. Max 4 jobs running simultaneously.
      While ($(Get-Job -state running).count -ge $MaxThreads)
      {Start-Sleep -Milliseconds 3}
      Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
      $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
      Write-EZLogs '-----------Spicetify Log Entries-----------'            
      #Wait for all jobs to finish.
      $break = $false
      While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if (!([System.IO.FIle]::Exists($spicetifyupgrade_logfile)))
        {Start-Sleep -Milliseconds 3}
        else
        {
          #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $spicetifyupgrade_logfile -force -Tail 1 -wait | ForEach-Object {
            $count++
            Write-EZLogs "$($_)" -showtime
            $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
            $pattern2 = 'Install size: (?<value>.*) MiB'               
            if($_ -match 'Spotify is spiced up!'){
              $spicetifyexit_code = $_ 
            break}  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($break){break}
            if($(Get-Job -State Running).count -eq 0){
              write-ezlogs 'Ended due to job ending, loop once more then break'
              $break = $true
            }
          }
        }      
      }  
      #Get information from each job.
      foreach($job in Get-Job)
      {$info = Receive-Job -Id ($job.Id)}
  
      #Remove all jobs created.
      Get-Job | Remove-Job -Force 
      Write-EZLogs '---------------END Log Entries---------------' -enablelogs
      Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
      write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime
       
      #spicetify restore backup apply
      $spicetifyrestorebackup_logfile = "$env:temp\\spicetify_restorebackup.log"
      if([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)){$null = Remove-Item $spicetifyrestorebackup_logfile -Force}
      $command = "& `"spicetify`" restore backup *>$spicetifyrestorebackup_logfile"   
      $block = 
      {
        Param
        (
          $command
      
        )
        $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
      }   
      #Remove all jobs and set max threads
      Get-Job | Remove-Job -Force
      $MaxThreads = 3
  
      #Start the jobs. Max 4 jobs running simultaneously.
      While ($(Get-Job -state running).count -ge $MaxThreads)
      {Start-Sleep -Milliseconds 3}
      Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
      $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
      Write-EZLogs '-----------Spicetify Log Entries-----------'            
      #Wait for all jobs to finish.
      $break = $false
      While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if (!([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)))
        {Start-Sleep -Milliseconds 3}
        else
        {
          #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $spicetifyrestorebackup_logfile -force -Tail 2 -wait | ForEach-Object {
            $count++
            Write-EZLogs "$($_)" -showtime
            $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
            $pattern2 = 'Install size: (?<value>.*) MiB'               
            if($_ -match 'Spotify is spiced up!'){
              $spicetifyexit_code = $_ 
            break}  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($break){break}
            if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
              $break = $true
            }
          }
        }      
      }  
      #Get information from each job.
      foreach($job in Get-Job)
      {$info = Receive-Job -Id ($job.Id)}
  
      #Remove all jobs created.
      Get-Job | Remove-Job -Force 
      Write-EZLogs '---------------END Log Entries---------------' -enablelogs
      Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
      write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime        
        
      try{
        write-ezlogs '>>>> Launching Spotify and letting it check for updates with argument --allow-upgrades --update-immediately'
        if([System.IO.File]::Exists("$Spotify_Path")){
          $spotifyprocess = Start-Process $Spotify_Path -ArgumentList '--allow-upgrades --minimized --update-immediately'
          Start-Sleep 1
        }else{write-ezlogs "Unable to find Spotify exe at path $Spotify_Path" -showtime -warning}
        if(Get-Process Spotify* -ErrorAction SilentlyContinue){
          write-ezlogs ' | Waiting for Spotify to open and run...' -showtime
          Start-Sleep 5
          write-ezlogs ' | Closing and reopening Spotify' -showtime 
          Get-Process Spotify* -ErrorAction SilentlyContinue | Stop-Process -Force
          Start-Sleep 1
          $spotifyprocess = Start-Process $Spotify_Path -ArgumentList '--allow-upgrades --minimized --update-immediately'
          Start-Sleep 2
        }
      }catch{write-ezlogs 'An exception occurred launching Spotify' -showtime -catcherror $_}

      #spicetify backup apply
      write-ezlogs ' | Executing Spicetify backup apply' -showtime        
      $spicetifybackupapply_logfile = "$env:temp\\spicetify_backupapply.log"
      if([System.IO.FIle]::Exists($spicetifybackupapply_logfile)){$null = Remove-Item $spicetifybackupapply_logfile -Force}
      $command = "& `"spicetify`" backup apply *>$spicetifybackupapply_logfile"   
      $block = 
      {
        Param
        (
          $command
      
        )
        $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
      }   
      #Remove all jobs and set max threads
      Get-Job | Remove-Job -Force
      $MaxThreads = 3
  
      #Start the jobs. Max 4 jobs running simultaneously.
      While ($(Get-Job -state running).count -ge $MaxThreads)
      {Start-Sleep -Milliseconds 3}
      Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
      $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
      Write-EZLogs '-----------Spicetify Log Entries-----------'            
      #Wait for all jobs to finish.
      $break = $false
      While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if (!([System.IO.FIle]::Exists($spicetifybackupapply_logfile)))
        {Start-Sleep -Milliseconds 3}
        else
        {
          #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $spicetifybackupapply_logfile -force -Tail 2 -wait | ForEach-Object {
            $count++
            Write-EZLogs "$($_)" -showtime
            $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
            $pattern2 = 'Install size: (?<value>.*) MiB' 
            if($_ -match  'You are using Spotify Windows Store version, which is only partly supported'){
              write-ezlogs "You are using Spotify Windows Store version, which is only partly supported" -showtime -warning
              $spicetify_warning = "$($_ -replace '','')"
            }              
            if($_ -match 'Spotify is spiced up!'){
              $spicetifyexit_code = "$($_)" 
            break}  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($break){break}
            if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
              $break = $true
            }
          }
        }      
      }  
      #Get information from each job.
      foreach($job in Get-Job)
      {
        $info = Receive-Job -Id ($job.Id)
      }
  
      #Remove all jobs created.
      Get-Job | Remove-Job -Force 
      Write-EZLogs '---------------END Log Entries---------------' -enablelogs
      Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
      write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime

      write-ezlogs ' | Applying Spicetify customizations' -showtime
      spicetify.exe config inject_css 0 replace_colors 0
      spicetify.exe config extensions webnowplaying.js     
        
      $spicetifyapply_logfile = "$env:temp\\spicetify_apply.log"
      if([System.IO.FIle]::Exists($spicetifyapply_logfile)){$null = Remove-Item $spicetifyapply_logfile -Force}
      $command = "& `"spicetify`" apply *>$spicetifyapply_logfile"   
      $block = 
      {
        Param
        (
          $command
      
        )
        $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
      }   
      #Remove all jobs and set max threads
      Get-Job | Remove-Job -Force
      $MaxThreads = 3
  
      #Start the jobs. Max 4 jobs running simultaneously.
      While ($(Get-Job -state running).count -ge $MaxThreads)
      {Start-Sleep -Milliseconds 3}
      Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
      $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
      Write-EZLogs '-----------Spicetify Log Entries-----------'            
      #Wait for all jobs to finish.
      $break = $false
      While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if (!([System.IO.FIle]::Exists($spicetifyapply_logfile)))
        {Start-Sleep -Milliseconds 3}
        else
        {
          #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $spicetifyapply_logfile -force -Tail 4 -wait | ForEach-Object {
            Write-EZLogs "$($_)" -showtime 
            $count++
            if($_ -match 'panic:' -or "$_" -match 'runtime error'){
              write-ezlogs "[ERROR] Spicetify encountered an critical error" -showtime -color red
              $synchash.Spicetify_apply_status = "$($_)"
            }  
            start-sleep -Milliseconds 500                
            $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
            $pattern2 = 'Install size: (?<value>.*) MiB'               
            if($_ -match 'Spotify is spiced up!'){
            $spicetifyexit_code = $_ }  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($break){break}
            if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
              $break = $true
            }
          }
        }      
      }  
      #Get information from each job.
      foreach($job in Get-Job)
      {
        $info = Receive-Job -Id ($job.Id)
      }
  
      #Remove all jobs created.
      Get-Job | Remove-Job -Force 
      Write-EZLogs '---------------END Log Entries---------------' -enablelogs
      Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan   
      write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime
      $full_log = Get-Content -Path $spicetifyapply_logfile
      foreach($l in $full_log){
        if($l -match 'panic:' -or $l -match 'runtime error'){
          write-ezlogs "[ERROR] Log shows Spicetify encountered an critical error" -showtime -color red
          $synchash.Spicetify_apply_status = $l
          $Fatal_Error = $l
          return $false
        }
      }
      if($synchash.Spicetify_apply_status){    
        write-ezlogs "Returning false due to error" -showtime
        return $false
      }else{
        return $true
      }                                  
    }
    catch
    {
      write-ezlogs 'An error occurred while applying Spicetify customizations' -showtime -catcherror $_
    }  
  }else{
    write-ezlogs "Unable to verify Spicetify is installed successfully, cannot continue" -showtime -warning
    return $false
  }    
}
#---------------------------------------------- 
#endregion Enable-Spicetify Function
#----------------------------------------------

#----------------------------------------------
#region Disable-Spicetify Function
#----------------------------------------------
function Disable-Spicetify
{
  param (
    $synchash,
    $thisapp,
    $thisScript,  
    [switch]$Verboselog
  )
  try{
    if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
      $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini").Backup.with
      if(!$appinstalled){
        $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
      }           
    }
    if(!$appinstalled){
      write-ezlogs ">>>> Installing Spicetify" -showtime            
      Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression -Verbose
      Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1" | Invoke-Expression -Verbose
      if([System.IO.File]::Exists("$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\\.spicetify\\config-xpui.ini")){
        $appinstalled = (Get-iniFile "$($env:USERPROFILE)\\.spicetify\\config-xpui.ini").Backup.with
        if(!$appinstalled){
          $appinstalled = "$($env:USERPROFILE)\\spicetify-cli\\spicetify.exe"
        }
      }    
    }        
  }catch{
    write-ezlogs "An exception occurred attempting to install Spicetify" -showtime -catcherror $_
  }
  write-ezlogs ">>>> Verifying Spotify installation" -showtime
  if([System.IO.File]::Exists("$($env:APPDATA)\\Spotify\\Spotify.exe")){
    write-ezlogs " | Spotify is installed at $($env:APPDATA)\\Spotify\\Spotify.exe" -showtime
    $synchash.Spotify_install_status = 'Installed'
    $Spotify_Path = "$($env:APPDATA)\\Spotify\\Spotify.exe"
  }elseif((Get-appxpackage 'Spotify*')){
    $Spotify_Path = "$((Get-appxpackage 'Spotify*').InstallLocation)\\Spotify.exe"
    $synchash.Spotify_install_status = 'Installed'
    write-ezlogs ">>>> Spotify installed as $Spotify_Path" -showtime
  }else{
    write-ezlogs "Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!" -warning
    $synchash.Spotify_install_status = 'NotInstalled'
    Update-Notifications -id 1 -Level 'ERROR' -Message "Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash
    return
  }   
  if($appinstalled){
    try
    {                                 
      write-ezlogs '>>>> Removing Spicetify customizations' -showtime
      #spicetify restore backup
      #spicetify apply    
      $spicetifyrestorebackup_logfile = "$env:temp\\spicetify_restorebackup.log"
      if([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)){$null = Remove-Item $spicetifyrestorebackup_logfile -Force}
      $command = "& `"spicetify`" restore backup *>$spicetifyrestorebackup_logfile"   
      $block = 
      {
        Param
        (
          $command
      
        )
        $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
      }   
      #Remove all jobs and set max threads
      Get-Job | Remove-Job -Force
      $MaxThreads = 3
  
      #Start the jobs. Max 4 jobs running simultaneously.
      While ($(Get-Job -state running).count -ge $MaxThreads)
      {Start-Sleep -Milliseconds 3}
      Write-EZLogs ">>>> Executing Spicetify`n" -showtime
      $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
      Write-EZLogs '-----------Spicetify Log Entries-----------'            
      #Wait for all jobs to finish.
      $break = $false
      While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if (!([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)))
        {Start-Sleep -Milliseconds 3}
        else
        {
          #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $spicetifyrestorebackup_logfile -force -Tail 1 -wait | ForEach-Object {
            $count++
            Write-EZLogs "$($_)" -showtime
            $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
            $pattern2 = 'Install size: (?<value>.*) MiB'               
            if($_ -match 'Everything is ready, you can start applying now'){
              $spicetifyexit_code = $_ 
            break}  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($break){break}
            if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
              $break = $true
            }
          }
        }      
      }  
      #Get information from each job.
      foreach($job in Get-Job)
      {$info = Receive-Job -Id ($job.Id)}
  
      #Remove all jobs created.
      Get-Job | Remove-Job -Force 
      Write-EZLogs '---------------END Log Entries---------------' -enablelogs
      Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime           
      write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime 
      $full_log = Get-Content -Path $spicetifyrestorebackup_logfile
      foreach($l in $full_log){
        if($l -match 'panic:' -or $l -match 'runtime error'){
          write-ezlogs "[ERROR] Log shows Spicetify encountered an critical error" -showtime -color red
          $synchash.Spicetify_apply_status = $l
          $Fatal_Error = $l
          return $false
        }
      }
      if($synchash.Spicetify_apply_status){    
        write-ezlogs "Returning false due to error" -showtime
        return $false
      }else{
        return $true
      }                      
    }
    catch
    {
      write-ezlogs 'An error occurred while removing Spicetify customizations' -showtime -catcherror $_
    }  
  }    
}
#---------------------------------------------- 
#endregion Disable-Spicetify Function
#----------------------------------------------
Export-ModuleMember -Function @('Enable-Spicetify','Disable-Spicetify')