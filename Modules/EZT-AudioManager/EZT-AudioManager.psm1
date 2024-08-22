<#
    .Name
    EZT-AudioManager

    .Version 
    0.1.0

    .SYNOPSIS
    Leverages cscore to provide advanced management of Windows audio sessions

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
#region Get-AudioSessions Function
#----------------------------------------------
function Get-AudioSessions
{
  Param (
    $thisApp,
    $synchash,
    [switch]$start_Paused,
    [switch]$Startup,
    [switch]$Update_MediaTransportControls,
    [switch]$Verboselog
  )
  try{ 
    $cscore_scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        [switch]$start_Paused = $start_Paused,
        [switch]$Startup = $Startup,
        [switch]$Update_MediaTransportControls = $Update_MediaTransportControls,
        [switch]$Verboselog = $Verboselog
      )
      try{
        if(!$synchash.Managed_AudioSession_Processes -or $Startup){
          $synchash.Managed_AudioSession_Processes = [System.Collections.Generic.List[Object]]::new()
        }      
        #TODO: SET ALL AUDIO SESSIONS SPAWNED FOR APP TO SAME GROUPINGPARAM
        write-ezlogs ">>>> Getting Default Audio Output device" -loglevel 2 -logtype Libvlc
        $default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)
        if($default_output_Device){
          write-ezlogs "| Found Default Audio Output Device: $($default_output_Device) - PID: $($PID)" -loglevel 2 -logtype Libvlc
          $synchash.AudiosessionManager = [CSCore.CoreAudioAPI.AudioSessionManager2]::FromMMDevice($default_output_Device)
          $synchash.AudioSessions = $synchash.AudiosessionManager.GetSessionEnumerator()
          foreach($session in ($synchash.AudioSessions).GetEnumerator()){
            try{
              $session2 = $session.QueryInterface([CSCore.CoreAudioAPI.AudioSessionControl2])
              $audionsessioncontrol = [CSCore.CoreAudioAPI.AudioSessionControl2]::new($session2)
              if($thisApp.Config.Dev_mode){write-ezlogs " | Checking Audio Session: ProcessID: $($audionsessioncontrol.ProcessID) - Process Name: $($audionsessioncontrol.Process.ProcessName)" -loglevel 2 -logtype Libvlc -Dev_mode}
              if($audionsessioncontrol.Process.ProcessName -like "p*w*s*" -and $audionsessioncontrol.ProcessID -eq $PID){
                $audionsessioncontrol.DisplayName = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_version)"
                $audionsessioncontrol.IconPath = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"            
                $synchash.Current_Audio_Session = $audionsessioncontrol              
                write-ezlogs " | Found current Audio Session: $($synchash.Current_Audio_Session.Process)" -loglevel 2 -logtype Libvlc
                #lock-object -InputObject $synchash.Managed_AudioSession_Processes.SyncRoot -ScriptBlock {
                if($synchash.Managed_AudioSession_Processes -notcontains $audionsessioncontrol.ProcessID){
                  write-ezlogs " | Registering Audio Session Notifications for $($audionsessioncontrol.ProcessID)" -loglevel 2 -logtype Libvlc
                  $null = $synchash.Managed_AudioSession_Processes.add($audionsessioncontrol.ProcessID)
                }                 
                #}
                #TODO: FUTURE FOR MANAGING/GETTING VOLUME MIXER LEVELS AND AUDIO METER?
                #$synchash.audiometereinfo = [CSCore.CoreAudioAPI.AudioMeterInformation]::FromDevice($default_output_Device)
                #$simplevolume = $session.QueryInterface([CSCore.CoreAudioAPI.SimpleAudioVolume])
                #$synchash.SimpleVolumeControl = [CSCore.CoreAudioAPI.SimpleAudioVolume]::new($simplevolume)

                #TODO: FUTURE: audio ducking is what controls the auto sound compression/normalization
              }
            }catch{ 
              write-ezlogs "An exception occurred enumerating AudioSessions $($session)" -catcherror $_
            }          
          }
          if($synchash.AudioSessions){
            $Null = $synchash.AudioSessions.Dispose()
            $synchash.AudioSessions = $null
            $Null = $synchash.Remove('AudioSessions')
          }
          if($synchash.AudiosessionManager){
            $Null = $synchash.AudiosessionManager.dispose()
            $synchash.AudiosessionManager = $Null
            $Null = $synchash.Remove('AudiosessionManager')
          }
        }
      }catch{
        write-ezlogs "An exception occurred in AudioSessions_Scripblock" -catcherror $_
      }finally{
        if($default_output_Device){
          $Null = $default_output_Device.dispose()
          $default_output_Device = $Null
        }
      }
    }
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    start-runspace -scriptblock $cscore_scriptblock -thisApp $thisApp  -synchash $synchash -runspace_name 'Get_AudioSessions_Runspace' -ApartmentState MTA -Variable_list $Variable_list #-RestrictedRunspace -function_list 'write-ezlogs'
    $Variable_list = $Null
    $keys = $null
    $cscore_scriptblock = $Null
  }catch{
    write-ezlogs 'An exception occurred in Get-AudioSessions' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-AudioSessions Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-AudioSessions Function
#----------------------------------------------
function Set-AudioSessions
{
  Param (
    $thisApp,
    $synchash,
    $ProcessID,
    [switch]$start_Paused,
    [switch]$Startup,
    [switch]$EnableRouting,
    [switch]$Update_MediaTransportControls,
    [switch]$Verboselog
  )
  try{ 
    #TODO: Need to register with an event when new audio sessions are created, then check it there
    try{
      $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Set_AudioSessions_Runspace' -check
      if($existing_Runspace){
        write-ezlogs "Set-AudioSessions runspace already exists, halting another execution to avoid a race condition" -warning
        return
      }
    }catch{
      write-ezlogs " An exception occurred checking for existing runspace 'Set_AudioSessions_Runspace'" -showtime -catcherror $_
    }
    $YoutubeWebProcessID = $synchash.YoutubeWebview2.CoreWebview2.BrowserProcessId
    $SpotifyWebProcessID = $synchash.Webview2.CoreWebview2.BrowserProcessId
    $WebbrowserProcessID = $synchash.WebBrowser.CoreWebview2.BrowserProcessId
    write-ezlogs "[Set-AudioSessions-NORUNSPACE] | Youtube: $($YoutubeWebProcessID) -- Spotify: $($SpotifyWebProcessID) -- Webbrowser: $($WebbrowserProcessID)" -loglevel 2 -logtype Libvlc -Dev_mode
    $cscore_Scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $ProcessID = $ProcessID,
        [switch]$start_Paused = $start_Paused,
        [switch]$Startup = $Startup,
        [switch]$EnableRouting = $EnableRouting,
        [switch]$Update_MediaTransportControls = $Update_MediaTransportControls,
        [switch]$Verboselog = $Verboselog
      )
      try{
        write-ezlogs "[Set-AudioSessions] #### Looking for New Orphaned Audio Sessions" -loglevel 2 -logtype Libvlc -linesbefore 1
        $default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)
        $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe'")
        $searcher = [System.Management.ManagementObjectSearcher]::new($query)
        $webviewProcesses = $searcher.get()
        $searcher.Dispose()
        if($default_output_Device){
          write-ezlogs "[Set-AudioSessions] | Found Default Audio Output Device: $($default_output_Device) - Current_Audio_Session_Group: $($synchash.Current_Audio_Session.GroupingParam)" -loglevel 2 -logtype Libvlc
          $synchash.AudiosessionManager = [CSCore.CoreAudioAPI.AudioSessionManager2]::FromMMDevice($default_output_Device)
          $synchash.AudioSessions = $synchash.AudiosessionManager.GetSessionEnumerator()
          $sessions = ($synchash.AudioSessions).GetEnumerator()
          foreach($session in $sessions){
            try{
              $Process = $Null
              $session2 = $Null
              $webplayer_process = $Null
              $ParentProcessId = $null
              $session2 = $session.QueryInterface([CSCore.CoreAudioAPI.AudioSessionControl2])
              $audionsessioncontrol = [CSCore.CoreAudioAPI.AudioSessionControl2]::new($session2)
              if($thisApp.Config.Dev_mode){write-ezlogs "[Set-AudioSessions] >>>> Checking Audio Session: DisplayName: $($audionsessioncontrol.DisplayName) - ProcessID: $($audionsessioncontrol.ProcessID) - Process Name: $($audionsessioncontrol.Process.ProcessName)" -loglevel 2 -logtype Libvlc -Dev_mode}
              if($audionsessioncontrol.GroupingParam -eq $synchash.Current_Audio_Session.GroupingParam -or $audionsessioncontrol.ProcessID -eq $synchash.Current_Audio_Session.ProcessID){                            
                if($audionsessioncontrol.DisplayName -ne "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_version)" -and $audionsessioncontrol.DisplayName -notmatch "WebPlayer EQ"){
                  write-ezlogs "[Set-AudioSessions] | Updating Default Audio Output Device session DisplayName from ($($audionsessioncontrol.DisplayName)) to ($($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_version)) - GroupParam: $($synchash.Current_Audio_Session.GroupingParam)" -loglevel 2 -logtype Libvlc
                  $audionsessioncontrol.DisplayName = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_version)"
                }
                if($audionsessioncontrol.IconPath -ne "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"){
                  write-ezlogs "[Set-AudioSessions] | Updating Default Audio Output Device session IconPath from ($($audionsessioncontrol.IconPath)) to ($($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico) - GroupParam: $($synchash.Current_Audio_Session.GroupingParam)" -loglevel 2 -logtype Libvlc
                  $audionsessioncontrol.IconPath = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico" 
                }
                if($synchash.Current_Audio_Session.GroupingParam -and $audionsessioncontrol.GroupingParam -ne $synchash.Current_Audio_Session.GroupingParam){
                  write-ezlogs "[Set-AudioSessions] | Adding audio session (Group: $($audionsessioncontrol.GroupingParam)) to main GroupParam: $($synchash.Current_Audio_Session.GroupingParam)" -loglevel 2 -logtype Libvlc
                  $audionsessioncontrol.GroupingParam = $synchash.Current_Audio_Session.GroupingParam
                }         
              }elseif($audionsessioncontrol.Process.ProcessName -ne 'Idle' -and -not [string]::IsNullOrEmpty($synchash.Current_Audio_Session.GroupingParam) -and $audionsessioncontrol.GroupingParam -ne $synchash.Current_Audio_Session.GroupingParam -and (($audionsessioncontrol.Process.ProcessName -like "p*w*s*" -and $audionsessioncontrol.Process.MainWindowTitle -match "$($thisApp.Config.App_Name)") -or $audionsessioncontrol.Process.ProcessName -eq "msedgewebview2")){
                if($audionsessioncontrol.IsSingleProcessSession){
                  $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE ProcessId = '$($audionsessioncontrol.ProcessID)'")
                  $searcher = [System.Management.ManagementObjectSearcher]::new($query)
                  $Process = $searcher.get() 
                  $searcher.Dispose()
                  $ParentProcessId = $Process.ParentProcessId
                  $WebView_UserData = "$($thisApp.Config.Temp_Folder)"
                  write-ezlogs "[Set-AudioSessions] | Audio session (ProcessID: $($audionsessioncontrol.ProcessID)) is IsSingleProcessSession, ParentProcessId: $ParentProcessId" -loglevel 2 -logtype Libvlc
                  $webplayer_process = $webviewProcesses | Where-Object {$_.ParentProcessId -eq $PID}
                  if($webplayer_process){
                    write-ezlogs "[Set-AudioSessions] | Audio session is from a Web Player $($webplayer_process.ProcessId)" -loglevel 2 -logtype Libvlc
                    #lock-object -InputObject $synchash.Managed_AudioSession_Processes.SyncRoot -ScriptBlock {
                    if($synchash.Managed_AudioSession_Processes -notcontains $webplayer_process.ProcessId){
                      write-ezlogs " | Registering Audio Session for WebPlayer process id: $($webplayer_process.ProcessId)" -loglevel 2 -logtype Libvlc
                      $null = $synchash.Managed_AudioSession_Processes.add($webplayer_process.ProcessId)
                    }                 
                    #}
                  }                  
                }
                if((($audionsessioncontrol.Process.ProcessName -eq "msedgewebview2" -and ($audionsessioncontrol.ProcessID -eq $synchash.Webview2.CoreWebview2.BrowserProcessId -or $audionsessioncontrol.ProcessID -eq $synchash.WebBrowser.CoreWebview2.BrowserProcessId`
                    -or $audionsessioncontrol.ProcessID -eq $synchash.YoutubeWebview2.CoreWebview2.BrowserProcessId)) -or $audionsessioncontrol.ProcessID -eq $PID -or $ParentProcessId -eq $synchash.YoutubeWebview2.CoreWebview2.BrowserProcessId`
                -or $ParentProcessId -eq $synchash.WebBrowser.CoreWebview2.BrowserProcessId -or $ParentProcessId -eq $synchash.Webview2.CoreWebview2.BrowserProcessId -or $Process.CommandLine -match [regex]::Escape($WebView_UserData)) -and !$audionsessioncontrol.IsSystemSoundSession){
                  write-ezlogs "[Set-AudioSessions] | Found orphaned Audio Session (DisplayName: $($audionsessioncontrol.DisplayName) -- ProcessName $($audionsessioncontrol.Process.ProcessName)) -- ProcessID $($audionsessioncontrol.ProcessID)) -- ParentProcessId: $($ParentProcessId) -- adding to Main App Audio Session group: $($synchash.Current_Audio_Session.GroupingParam)" -loglevel 2 -logtype Libvlc -Success
                  $audionsessioncontrol.GroupingParam = $synchash.Current_Audio_Session.GroupingParam
                  $audionsessioncontrol.DisplayName = "$($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_version)"
                  $audionsessioncontrol.IconPath = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
                  #lock-object -InputObject $synchash.Managed_AudioSession_Processes.SyncRoot -ScriptBlock {
                  if($synchash.Managed_AudioSession_Processes -notcontains $audionsessioncontrol.ProcessID){
                    write-ezlogs " | Registering Audio Session for PID: $($audionsessioncontrol.ProcessID)" -loglevel 2 -logtype Libvlc
                    $null = $synchash.Managed_AudioSession_Processes.add($audionsessioncontrol.ProcessID)
                  }                 
                  #}              
                }                        
              }elseif($audionsessioncontrol.GroupingParam -eq $synchash.Current_Audio_Session.GroupingParam){
                if($thisApp.Config.Dev_mode){write-ezlogs "[Set-AudioSessions] | Audio Session process already managed and added to main group: DisplayName: $($audionsessioncontrol.DisplayName) - ProcessName: $($audionsessioncontrol.Process.ProcessName) - PID: $($audionsessioncontrol.ProcessID) - GroupParam: $($audionsessioncontrol.GroupingParam)" -loglevel 2 -logtype Libvlc -Dev_mode}              
              }elseif($audionsessioncontrol.Process.ProcessName -ne 'Idle'){
                if($thisApp.Config.Dev_mode){write-ezlogs "[Set-AudioSessions] | Audio Session process already managed or owned by someone else for Process: DisplayName: $($audionsessioncontrol.DisplayName) - ProcessName: $($audionsessioncontrol.Process.ProcessName) - PID: $($audionsessioncontrol.ProcessID)" -loglevel 2 -logtype Libvlc -Dev_mode}
              }
              if($audionsessioncontrol){
                $Null = $audionsessioncontrol.Dispose()
              }             
            }catch{
              write-ezlogs "[Set-AudioSessions] An exception occurred while enumerating audio session $($session | out-string)" -catcherror $_
            }
          }
          if($synchash.AudioSessions){
            $Null = $synchash.AudioSessions.Dispose()
            $synchash.AudioSessions = $null
            $Null = $synchash.Remove('AudioSessions')
          }
          if($synchash.AudiosessionManager){
            $Null = $synchash.AudiosessionManager.dispose()
            $synchash.AudiosessionManager = $Null      
            $Null = $synchash.Remove('AudiosessionManager')
          }
        }
      }catch{
        write-ezlogs "[Set-AudioSessions] An exception occurred in Set-AudioSessions" -catcherror $_
      }finally{
        if($default_output_Device){
          $Null = $default_output_Device.dispose()
          $default_output_Device = $null
        }
        if($webviewProcesses){
          $null = $webviewProcesses.Dispose()
          $webviewProcesses = $null
        }
      }
    }
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    #$Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant" -and !$_.Name -in $PSBoundParameters.keys}
    start-runspace -scriptblock $cscore_Scriptblock -thisApp $thisApp  -synchash $synchash -runspace_name 'Set_AudioSessions_Runspace' -ApartmentState MTA -Variable_list $Variable_list -RestrictedRunspace -function_list 'write-ezlogs'
    $Variable_list = $Null
    $keys = $null
    $cscore_scriptblock = $Null
  }catch{
    write-ezlogs 'An exception occurred in Get-AudioSessions' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Set-AudioSessions Function
#----------------------------------------------

#---------------------------------------------- 
#region Set-ApplicationAudioDevice Function
#---------------------------------------------- 
function Set-ApplicationAudioDevice
{
  Param (
    $thisApp,
    $synchash,
    $ProcessID,
    [string]$ProcessName,
    [switch]$start,
    [switch]$Check_Runspace,
    [switch]$Use_Cscore,
    [switch]$stop,
    [switch]$wait,
    [switch]$Startlibvlc,
    [switch]$Stoplibvlc,
    [switch]$Verboselog
  )
  #Download App
  #$start_time2 = Get-Date
  try{
    if($Stop){
      $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Set_VirtualAudio_Runspace' -force
    }
    if($Check_Runspace){
      try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Set_VirtualAudio_Runspace' -check
        if($existing_Runspace){
          write-ezlogs "Set-ApplicationAudioDevice runspace already exists, halting another execution to avoid a race condition" -warning
          return
        }                
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace 'Set_VirtualAudio_Runspace'" -showtime -catcherror $_
      }
    }
    $cscore_VirtualAudio_Scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $ProcessID = $ProcessID,
        [string]$ProcessName = $ProcessName,
        [switch]$start = $start,
        [switch]$Use_Cscore = $Use_Cscore,
        [switch]$stop = $stop,
        [switch]$wait = $wait,
        [switch]$Stoplibvlc = $Stoplibvlc,
        [switch]$Startlibvlc = $Startlibvlc
      )
      try{
        #$paths = [Environment]::GetEnvironmentVariable('Path') -split ';'
        #$paths2 = $env:path -split ';'
        $soundviewpath = "$($thisApp.Config.Current_Folder)\Resources\Audio\soundvolumeview\"
        <#        if($soundviewpath -notin $paths2){
            $env:path += ";$soundviewpath"
            if($soundviewpath -notin $paths){
            [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$soundviewpath",[EnvironmentVariableTarget]::User)
            }
        }#>
        $Set_ApplicationAudioDevice_Measure = [system.diagnostics.stopwatch]::StartNew()
        # Run app process
        $all_Audio_Devices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::All)
        $capture_device = $all_Audio_Devices | Where-Object {$_.friendlyname -match 'CABLE Input \(VB-Audio Virtual Cable\)'}
        if($start){
          if($ProcessID){
            write-ezlogs "[Set-ApplicationAudioDevice] >>>> Looking up process with provided id $($ProcessID)"
            $webviewProcesses = [System.Diagnostics.Process]::GetProcessById($ProcessID)
            $Process = $webviewProcesses.Id
          }else{
            if($ProcessName){
              write-ezlogs "[Set-ApplicationAudioDevice] >>>> Looking for process name $ProcessName"
              if($ProcessName -match '\.exe'){
                $processes = [System.Diagnostics.Process]::GetProcessesByName([System.IO.Path]::GetFileNameWithoutExtension($ProcessName))
              }else{
                $processes = [System.Diagnostics.Process]::GetProcessesByName($ProcessName)
              }             
              if($Processes){
                write-ezlogs "[Set-ApplicationAudioDevice] | Found process with name: $($ProcessName) - IDs: $($Processes.Id)" -Success
                $Process = $ProcessName
              }elseif($wait){
                $timeout = 0
                write-ezlogs "[Set-ApplicationAudioDevice] | Waiting until process '$($ProcessName)' becomes available"
                while(!$Processes -and $timeout -lt 600){
                  $timeout++
                  $processes = [System.Diagnostics.Process]::GetProcessesByName($ProcessName)
                  start-sleep -Milliseconds 5
                }
                if($timeout -eq 600){
                  write-ezlogs "[Set-ApplicationAudioDevice] Timed out waiting for process '$($ProcessName)' EQ will not be enabled" -warning -AlertUI
                  $Process = $null
                }else{
                  write-ezlogs "[Set-ApplicationAudioDevice] | Found process with name: $($ProcessName) - IDs: $($Processes.ProcessId)" -Success
                  $Process = $ProcessName
                }
              }
            }else{
              write-ezlogs "[Set-ApplicationAudioDevice] >>>> Looking for all webview2 processes"
              $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe' AND CommandLine LIKE '%AudioService%' AND CommandLine LIKE '%$([regex]::Escape("$($thisApp.Config.Temp_Folder)"))%'")
              $searcher = [System.Management.ManagementObjectSearcher]::new($query)
              $AudioProcess = $searcher.get() 
              $searcher.Dispose()               
              if(-not [string]::IsNullOrEmpty($AudioProcess) -and $AudioProcess.count -gt 0){
                write-ezlogs "[Set-ApplicationAudioDevice] | Found webvieww2 process with AudioService in commandline: $($AudioProcess.ProcessId)" -Success
                $Process = $AudioProcess.ProcessId
              }elseif($wait){
                $timeout = 0
                if($AudioProcess -is [System.IDisposable]){
                  $null = $AudioProcess.dispose()
                  $AudioProcess = $Null
                }
                write-ezlogs "[Set-ApplicationAudioDevice] | Waiting until webview2 with audio becomes available"
                while(!$AudioProcess.ProcessId -and $timeout -lt 600){
                  $timeout++
                  $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe' AND CommandLine LIKE '%AudioService%' AND CommandLine LIKE '%$([regex]::Escape("$($thisApp.Config.Temp_Folder)"))%'")
                  $searcher = [System.Management.ManagementObjectSearcher]::new($query)
                  $AudioProcess = $searcher.get() 
                  $searcher.Dispose()  
                  start-sleep -Milliseconds 5
                }
                if($timeout -eq 600){
                  write-ezlogs "Timed out waiting for a webview2 process playing audio - using process name" -warning
                  $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe'")
                  $searcher = [System.Management.ManagementObjectSearcher]::new($query)
                  $AudioProcess = $searcher.get() 
                  $searcher.Dispose() 
                  if($AudioProcess.name){
                    $Process = $AudioProcess.name[0]
                  }
                }else{
                  write-ezlogs "[Set-ApplicationAudioDevice] | Found webview2 process with Audio: $($AudioProcess.ProcessId)" -Success
                  $Process = $AudioProcess.ProcessId
                }            
              }else{
                $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe'")
                $searcher = [System.Management.ManagementObjectSearcher]::new($query)
                $AudioProcess = $searcher.get() 
                $searcher.Dispose() 
                if($AudioProcess.name){
                  $Process = $AudioProcess.name[0]
                }
                write-ezlogs "[Set-ApplicationAudioDevice] | Couldnt find webview2 process with audio, using process name: $($Process)"
              } 
              if($AudioProcess -is [System.IDisposable]){
                $null = $AudioProcess.dispose()
                $AudioProcess = $Null
              } 
            }
          }     
          if($Process){
            if($Startlibvlc){
              write-ezlogs "[Set-ApplicationAudioDevice] | Executing Update-MainPlayer and creating libvlc session for dshow://"
              $allDevices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::All)
              $capture_device = $allDevices | Where-Object {$_.friendlyname -match 'CABLE Input \(VB-Audio Virtual Cable\)'}
              if($thisApp.Config.Enable_EQ -and !$synchash.libvlc){  
                try{
                  write-ezlogs "[Set-ApplicationAudioDevice] >>>> Creating new Libvlc instance for webplayer EQ" -logtype Libvlc -linesbefore 1
                  if($capture_device){
                    $vlcArgs = [System.Collections.Generic.List[String]]::new()
                    $null = $vlcArgs.add('--file-logging')
                    $null = $vlcArgs.add("--logfile=$($thisapp.config.Vlc_Log_file)")
                    $null = $vlcArgs.add("--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
                    $null = $vlcArgs.add("--osd")
                    [double]$doubleref = [double]::NaN
                    if(-not [string]::IsNullOrEmpty($thisApp.Config.Libvlc_Global_Gain) -and [double]::TryParse($thisApp.Config.Libvlc_Global_Gain,[ref]$doubleref)){
                      write-ezlogs "[Set-ApplicationAudioDevice] | Applying custom global gain for libvlc: $($thisApp.Config.Libvlc_Global_Gain)" -logtype Libvlc -loglevel 2
                      $null = $vlcArgs.add("--gain=$($thisApp.Config.Libvlc_Global_Gain)")
                    }else{
                      write-ezlogs "[Set-ApplicationAudioDevice] | Setting default global gain for libvlc: 4" -logtype Libvlc -loglevel 2
                      $null = $vlcArgs.add('--gain=4.0') #Set gain to 4 which is default that VLC uses but for some reason libvlc does not
                    }                   
                    $null = $vlcArgs.add("--logmode=text")
                    #$null = $vlcArgs.add("--volume-step=2.56")
                    if($Enable_normalizer){
                      #$vlc_options = "--audio-filter=normalizer"
                      $null = $vlcArgs.add("--audio-filter=normalizer")
                    }
                    if($thisapp.config.Enable_EQ2Pass){
                      $null = $vlcArgs.add("--equalizer-2pass")
                    }else{
                      $vlc_eq2pass = $null
                    }
                    if($thisApp.Config.Use_Visualizations){ 
                      $null = $vlcArgs.add("--video-on-top")
                      $null = $vlcArgs.add("--spect-show-original")
                      if($thisApp.Config.Current_Visualization -eq 'Spectrum'){
                        #$effect = "--effect-list=spectrum"             
                        $null = $vlcArgs.add("--audio-visual=Visual")
                        $null = $vlcArgs.add("--effect-list=spectrum")
                      }else{
                        #$effect = "--effect-list=spectrum"
                        $null = $vlcArgs.add("--audio-visual=$($thisApp.Config.Current_Visualization)")
                        $null = $vlcArgs.add("--effect-list=spectrum")
                      }                                                                      
                    }
                    if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
                      try{
                        foreach($a in $thisapp.config.vlc_Arguments -split ','){
                          if([regex]::Escape($a) -match '--' -and $vlcArgs -notcontains $a){
                            write-ezlogs "[Set-ApplicationAudioDevice] | Adding custom Libvlc option: $($a)" -loglevel 2 -logtype Libvlc
                            $null = $vlcArgs.add("$($a)")
                          }else{
                            write-ezlogs "[Set-ApplicationAudioDevice] Cannot add custom libvlc option $($a) - it does not meet the required format or is already added!" -warning -loglevel 2 -logtype Libvlc
                          }
                        }
                      }catch{
                        write-ezlogs "[Set-ApplicationAudioDevice] An exception occurred processing custom VLC arguments" -catcherror $_
                      }          
                    }
                    [String[]]$libvlc_arguments =  foreach($a in $vlcArgs){
                      write-ezlogs "[Set-ApplicationAudioDevice] | Applying Libvlc option: $($a)" -loglevel 2 -logtype Libvlc
                      if([regex]::Escape($a) -match '--'){
                        $a
                      }else{
                        write-ezlogs "[Set-ApplicationAudioDevice] Cannot apply libvlc option $($a) - it does not meet the required format!" -warning -loglevel 2 -logtype Libvlc
                      }
                    }
                    if($thisApp.Config.Libvlc_Version -eq '4'){
                      $synchash.libvlc = [LibVLCSharp.LibVLC]::new($libvlc_arguments)
                    }else{
                      $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new($libvlc_arguments) 
                    }
                    $synchash.libvlc.SetUserAgent("$($thisApp.Config.App_Name) Media Player - WebPlayer EQ","HTTP/User/Agent")
                    if($thisApp.Config.Installed_AppID){
                      $appid = $thisApp.Config.Installed_AppID
                    }else{
                      $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
                    }
                    #$startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"
                    if($appid -and $synchash.libvlc){
                      $synchash.libvlc.SetAppId($appid,$thisApp.Config.App_Version,"$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
                    }
                  }else{
                    write-ezlogs "[Set-ApplicationAudioDevice] Unable to find required 'CABLE Input (VB-Audio Virtual Cable)' audio device - cannot enable EQ for Webplayer!" -AlertUI -Warning -logtype Libvlc
                  }      
                }catch{
                  write-ezlogs "[Set-ApplicationAudioDevice] An exception occurred creating new libvlcsharp instance for Spotify audio routing" -showtime -catcherror $_
                }
              }
              Update-MainPlayer -synchash $synchash -thisApp $thisApp -Add_VideoView -New_MediaPlayer -vlcurl "dshow://" -media_link "dshow://"
            } 
            write-ezlogs "[Set-ApplicationAudioDevice] >>> Redirecting audio output for process: $($Process) to virtual audio cable" -logtype Libvlc   
            try{
              write-ezlogs "[Set-ApplicationAudioDevice] Rerouting audio for process '$process' to deviceid: $($capture_device.DeviceID)" -showtime
              $newProc = [System.Diagnostics.ProcessStartInfo]::new("$soundviewpath`svcl.exe")
              $newProc.WindowStyle = 'Hidden'
              $newProc.Arguments = "/Stdout /SetAppDefault $($capture_device.DeviceID) All $Process"
              $newProc.UseShellExecute = $false
              $newProc.CreateNoWindow = $true
              $newProc.RedirectStandardOutput = $true
              $Process = [System.Diagnostics.Process]::Start($newProc) 
            }catch{
              write-ezlogs "An exception occurred executing svcl" -catcherror $_
            }finally{
              if($Process.StandardOutput){
                $svlc_ouptput = $Process.StandardOutput.ReadToEnd()
              }            
              if($Process -is [System.IDisposable]){
                $Process.dispose()
              }
            }
            #$svlc_ouptput = ."$soundviewpath`svcl.exe" /Stdout /SetAppDefault "$($capture_device.DeviceID)" All "$Process"
            write-ezlogs "[Set-ApplicationAudioDevice] | Soundvolumeview: $($svlc_ouptput)" -Dev_mode -logtype Libvlc
            write-ezlogs "[Set-ApplicationAudioDevice] | VLC VLC_IsPlaying_State: $($synchash.VLC_IsPlaying_State) - isPlaying: $($synchash.vlc.isPlaying)" -Dev_mode -logtype Libvlc
            if($thisApp.Config.Enable_EQ -and !$synchash.VLC_IsPlaying_State -and !$synchash.VLC_PlaybackCancel -and ($([string]$synchash.vlc.media.Mrl).StartsWith("dshow://") -or $wait)){
              write-ezlogs "[Set-ApplicationAudioDevice] EQ is enabled but Vlc is not playing, waiting for vlc to begin" -Warning -logtype Libvlc
              $vlctimeout = 0
              while(!$synchash.VLC_IsPlaying_State -and $vlctimeout -lt 20 -and !$synchash.VLC_PlaybackCancel){
                $vlctimeout++
                if($([string]$synchash.vlc.media.Mrl).StartsWith("dshow://") -and ($vlctimeout -eq 5 -or $vlctimeout -eq 10)){
                  write-ezlogs "[Set-ApplicationAudioDevice] | VLC media is loaded but after ($vlctimeout) secs is not yet playing, executing play()" -Warning -logtype Libvlc
                  $synchash.vlc.play()
                }
                start-sleep 1
              } 
              if($vlctimeout -eq 20){
                write-ezlogs "[Set-ApplicationAudioDevice] Timed out waiting for vlc playback to begin for Web EQ!" -warning -logtype Libvlc
              }elseif($synchash.VLC_PlaybackCancel){
                write-ezlogs "[Set-ApplicationAudioDevice] Playback for current media was canceled or changed!" -warning -logtype Libvlc
              }
            }
            #svcl /Stdout /SetAppDefault "VB-Audio Virtual Cable\Device\CABLE Input\Render" All $webviewProcesses.Name
            #svcl /Stdout /SetAppDefault "$($capture_device.DeviceID)" 1 $synchash.AudioSessionControl2.Process.Id
            #$synchash.allDevices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::All)
            # $capture_device = $synchash.allDevices | where {$_.friendlyname -match 'CABLE Input'}

            #TODO: Failed attempt to do audio routing manually with cscore and creating custom EQ - maybe revist
            if($capture_device -and -not [string]::IsNullOrEmpty($svlc_ouptput) -and $svlc_ouptput -notmatch 'No items found' -and $Use_Cscore){
              write-ezlogs "[Set-ApplicationAudioDevice] >>> Starting capture of virtual audio device $($capture_device | out-string) -- svlc_ouptput: $($svlc_ouptput | out-string)" -logtype Libvlc
              $synchash.current_Capture = [CSCore.SoundIn.WasapiLoopbackCapture]::new()
              $synchash.current_Capture.Device = $capture_device
              $synchash.current_Capture.Initialize()
              $synchash.current_soundInsource = [CSCore.Streams.SoundInSource]::new($synchash.current_Capture)
              $synchash.current_soundInsource.FillWithZeros = $true
              $synchash.current_soundInsource = [CSCore.FluentExtensions]::ToStereo($synchash.current_soundInsource)
              $synchash.current_soundInsource = [CSCore.FluentExtensions]::ToSampleSource($synchash.current_soundInsource)         
              #$synchash.current_soundout = [CSCore.SoundOut.WasapiOut]::new($true,[CSCore.CoreAudioAPI.AudioClientShareMode]::Shared,[int]1)
              $synchash.Current_VirtualEQ = [CSCore.Streams.Effects.Equalizer]::Create10BandEqualizer($synchash.current_soundInsource)
              $synchash.current_soundInsource = [CSCore.FluentExtensions]::ToWaveSource($synchash.Current_VirtualEQ)          
              $synchash.current_soundout = [CSCore.SoundOut.WasapiOut]::new()
              $synchash.current_soundout.Initialize($synchash.current_soundInsource)
              $synchash.current_soundout.Latency = 1
              $synchash.current_Capture.start()
              $synchash.current_soundout.Play()

              #Set Volume
              #$synchash.current_soundout.Volume = [float]1

              #Set EQ
              if($thisapp.Config.Enable_EQ){ 
                $eq_9 = $thisApp.Config.EQ_Bands[9].Band_Value
                $eq_8 = $thisApp.Config.EQ_Bands[8].Band_Value
                $eq_7 = $thisApp.Config.EQ_Bands[7].Band_Value
                $eq_6 = $thisApp.Config.EQ_Bands[6].Band_Value
                $eq_5 = $thisApp.Config.EQ_Bands[5].Band_Value
                $eq_4 = $thisApp.Config.EQ_Bands[4].Band_Value
                $eq_3 = $thisApp.Config.EQ_Bands[3].Band_Value
                $eq_2 = $thisApp.Config.EQ_Bands[2].Band_Value
                $eq_1 = $thisApp.Config.EQ_Bands[1].Band_Value
                $eq_0 = $thisApp.Config.EQ_Bands[0].Band_Value
              }else{
                $eq_9 = 0
                $eq_8 = 0
                $eq_7 = 0
                $eq_6 = 0
                $eq_5 = 0
                $eq_4 = 0
                $eq_3 = 0
                $eq_2 = 0
                $eq_1 = 0
                $eq_0 = 0
              }
              $synchash.Current_VirtualEQ.SampleFilters[9].AverageGainDB = $eq_9
              $synchash.Current_VirtualEQ.SampleFilters[8].AverageGainDB = $eq_8 #6
              $synchash.Current_VirtualEQ.SampleFilters[7].AverageGainDB = $eq_7 #0
              $synchash.Current_VirtualEQ.SampleFilters[6].AverageGainDB = $eq_6 #-10
              $synchash.Current_VirtualEQ.SampleFilters[5].AverageGainDB = $eq_5 #0
              $synchash.Current_VirtualEQ.SampleFilters[4].AverageGainDB = $eq_4 #4
              $synchash.Current_VirtualEQ.SampleFilters[3].AverageGainDB = $eq_3 #0
              $synchash.Current_VirtualEQ.SampleFilters[2].AverageGainDB = $eq_2 #2
              $synchash.Current_VirtualEQ.SampleFilters[1].AverageGainDB = $eq_1 #5
              $synchash.Current_VirtualEQ.SampleFilters[0].AverageGainDB = $eq_0 #7

              #Custom filters - Add Frequency
              <#          $eqfilter = [CSCore.Streams.Effects.EqualizerFilter]::new()
                  #$eqchannelfilter = [CSCore.Streams.Effects.EqualizerChannelFilter]::new([int]SampleRate,[double]Freq,[double]Bandwidth,[double]Gain)
                  $eqchannelfilter = [CSCore.Streams.Effects.EqualizerChannelFilter]::new([int]48000,[double]20,[double]18,[double]5)
                  $Null = $eqfilter.Filters.Add(0,$eqchannelfilter) #Left Channel
                  $Null = $eqfilter.Filters.Add(1,$eqchannelfilter) #Right Channel
              $Null = $synchash.Current_VirtualEQ.SampleFilters.Add($eqfilter)#>
            }elseif($Use_Cscore){
              write-ezlogs "[Set-ApplicationAudioDevice] Unable to find capture device - CSCORE capture device: $($capture_device) - svlc_ouptput: $($svlc_ouptput | out-string)" -Warning
            }
          }else{
            write-ezlogs "[Set-ApplicationAudioDevice] Unable to find process $($ProcessID) in order to route audio to virtual audio cable" -warning
          }
        }
        if($stop){
          #Stop and Dispose
          if($ProcessID){
            write-ezlogs "[Set-ApplicationAudioDevice] >>> Looking up process with provided id $($ProcessID)"
            $webviewProcesses = [System.Diagnostics.Process]::GetProcessById($ProcessID)
            $Process = $webviewProcesses.Id
          }elseif($ProcessName){
            write-ezlogs "[Set-ApplicationAudioDevice] >>> Looking up process with name: $($ProcessName)"
            $Processes = [System.Diagnostics.Process]::GetProcessesByName($ProcessName)
            if($Processes){
              write-ezlogs "[Set-ApplicationAudioDevice] | Found process with name: $($ProcessName) - IDs: $($Processes.ProcessId)" -Success
              $Process = $ProcessName
            }
          }else{
            write-ezlogs "[Set-ApplicationAudioDevice] >>> Looking for all webview2 processes"
            $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe' AND CommandLine LIKE '%AudioService%' AND CommandLine LIKE '%$([regex]::Escape("$($thisApp.Config.Temp_Folder)"))%'")
            $searcher = [System.Management.ManagementObjectSearcher]::new($query)
            $AudioProcess = $searcher.get() 
            $searcher.Dispose()
            if(-not [string]::IsNullOrEmpty($AudioProcess) -and $AudioProcess.count -gt 0){
              write-ezlogs "[Set-ApplicationAudioDevice] | Found webvieww2 process with AudioService in commandline: $($AudioProcess.ProcessId)" -Success
              $Process = $AudioProcess.ProcessId
            }else{
              if($AudioProcess -is [System.IDisposable]){
                $null = $AudioProcess.dispose()
                $AudioProcess = $Null
              } 
              $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'msedgewebview2.exe'")
              $searcher = [System.Management.ManagementObjectSearcher]::new($query)
              $AudioProcess = $searcher.get() 
              $searcher.Dispose()
              if($AudioProcess.name){
                $Process = $AudioProcess.name[0]
              }
              write-ezlogs "[Set-ApplicationAudioDevice] | Couldnt find webview2 process with audio, using process name: $($Process)"
            }
            if($thisApp.Config.Use_Spicetify){
              write-ezlogs "[Set-ApplicationAudioDevice] >>> Looking for all Spotify processes"
              $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name = 'Spotify.exe'")
              $searcher = [System.Management.ManagementObjectSearcher]::new($query)
              $SpotifyProcesses = $searcher.get() 
              $searcher.Dispose() 
            }
            if($AudioProcess -is [System.IDisposable]){
              $null = $AudioProcess.dispose()
              $AudioProcess = $Null
            }                             
          }
          #$default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)
          #$svlc_ouptput = svcl /Stdout /SetAppDefault "$($default_output_Device.DeviceID)" All $webviewProcesses.Name[0]
          if($Process){
            write-ezlogs "[Set-ApplicationAudioDevice] >>>> Resetting audio output for process: $Process to DefaultRenderDevice"
            try{
              $newProc = [System.Diagnostics.ProcessStartInfo]::new("$soundviewpath`svcl.exe")
              $newProc.WindowStyle = 'Hidden'
              $newProc.Arguments = "/Stdout /SetAppDefault DefaultRenderDevice All $Process"
              $newProc.UseShellExecute = $false
              $newProc.CreateNoWindow = $true
              $newProc.RedirectStandardOutput = $true
              $Process = [System.Diagnostics.Process]::Start($newProc) 
            }catch{
              write-ezlogs "An exception occurred executing svcl" -catcherror $_
            }finally{
              if($Process.StandardOutput){
                $svlc_ouptput = $Process.StandardOutput.ReadToEnd()
              }            
              if($Process -is [System.IDisposable]){
                $Process.dispose()
              }
            }
            #$svlc_ouptput = ."$soundviewpath`svcl.exe" /Stdout /SetAppDefault "DefaultRenderDevice" All "$Process"
            if($svlc_ouptput){
              write-ezlogs "[Set-ApplicationAudioDevice] | Soundvolumeview: $($svlc_ouptput)"
            }            
          }elseif($SpotifyProcesses.processid){
            write-ezlogs "[Set-ApplicationAudioDevice] >>>> Resetting audio output for Spotify process: $($SpotifyProcesses.processid) to DefaultRenderDevice"
            try{
              $newProc = [System.Diagnostics.ProcessStartInfo]::new("$soundviewpath`svcl.exe")
              $newProc.WindowStyle = 'Hidden'
              $newProc.Arguments = "/Stdout /SetAppDefault DefaultRenderDevice All Spotify.exe"
              $newProc.UseShellExecute = $false
              $newProc.CreateNoWindow = $true
              $newProc.RedirectStandardOutput = $true
              $Process = [System.Diagnostics.Process]::Start($newProc) 
            }catch{
              write-ezlogs "An exception occurred executing svcl" -catcherror $_
            }finally{
              if($Process.StandardOutput){
                $svlc_ouptput = $Process.StandardOutput.ReadToEnd()
              }            
              if($Process -is [System.IDisposable]){
                $Process.dispose()
              }
            }
            #$svlc_ouptput = ."$soundviewpath`svcl.exe" /Stdout /SetAppDefault "DefaultRenderDevice" All "Spotify.exe"
            if($svlc_ouptput){
              write-ezlogs "[Set-ApplicationAudioDevice] | Soundvolumeview: $($svlc_ouptput)"
            }            
          }else{
            write-ezlogs "[Set-ApplicationAudioDevice] >>>> No processes found/provided to reset audio output"
          }  
          if($Stoplibvlc){
            write-ezlogs "[Set-ApplicationAudioDevice] | Executing Update-MainPlayer to stop libvlc session for dshow://" -Dev_mode
            Update-MainPlayer -synchash $synchash -thisApp $thisApp -Stoplibvlc
          }         
          if($synchash.current_soundout -and $synchash.current_soundout.PlaybackState -ne 'Stopped'){
            write-ezlogs "[Set-ApplicationAudioDevice] | Stopping and disposing current_soundout"
            $synchash.current_soundout.stop()
            $synchash.current_soundout.Dispose() 
          }else{
            write-ezlogs "[Set-ApplicationAudioDevice] No current_soundout instance is recording or available to stop" -warning -Dev_mode
          }
          if($synchash.current_soundInsource){
            write-ezlogs "[Set-ApplicationAudioDevice] | Disposing current_soundInsource"
            $synchash.current_soundInsource.Dispose()
          } 
          if($synchash.Current_VirtualEQ){
            write-ezlogs "[Set-ApplicationAudioDevice] | Disposing Current_VirtualEQ"
            $synchash.Current_VirtualEQ.Dispose()
          }
          if($capture_device){
            write-ezlogs "[Set-ApplicationAudioDevice] | Disposing capture_device" -Dev_mode
            $capture_device.Dispose()
            $capture_device = $Null
          }
          if($synchash.current_Capture -and $synchash.current_Capture.RecordingState -ne 'Stopped'){
            write-ezlogs "[Set-ApplicationAudioDevice] | Stopping and Disposing current_Capture"
            $synchash.current_Capture.Stop()
            $synchash.current_Capture.Dispose()
          }else{
            write-ezlogs "[Set-ApplicationAudioDevice] No current_Capture instance is recording or available to stop" -warning -Dev_mode
          } 
        } 
      }catch{
        write-ezlogs "An exception occurred in Set-ApplicationAudioDevice" -catcherror $_
      }finally{
        if($Set_ApplicationAudioDevice_Measure){
          $Set_ApplicationAudioDevice_Measure.stop()
          write-ezlogs "Set-ApplicationAudioDevice Measure" -PerfTimer $Set_ApplicationAudioDevice_Measure
          $Set_ApplicationAudioDevice_Measure = $Null
        }
        if($all_Audio_Devices){
          write-ezlogs "[Set-ApplicationAudioDevice] | Disposing All_Audio_Devices" -Dev_mode
          $Null = $all_Audio_Devices.dispose()
          $all_Audio_Devices = $Null
        }
      }   
    }
    #$Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    start-runspace -scriptblock $cscore_VirtualAudio_Scriptblock -thisApp $thisApp  -synchash $synchash -runspace_name 'Set_VirtualAudio_Runspace' -ApartmentState MTA -Variable_list $Variable_list -RestrictedRunspace -function_list 'write-ezlogs','Update-MainPlayer'
    $Variable_list = $null
    $cscore_VirtualAudio_Scriptblock = $Null
  }catch{
    write-ezlogs "An exception occurred in Set-ApplicationAudioDevice" -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Set-ApplicationAudioDevice Function
#---------------------------------------------- 
Export-ModuleMember -Function @('Get-AudioSessions','Set-AudioSessions','Set-ApplicationAudioDevice')