<#
    .Name
    Start-SpotifyMedia

    .Version 
    0.1.0

    .SYNOPSIS
    Plays provided media files within vlc controls  

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
#region Start-SpotifyMedia Function
#----------------------------------------------
function Start-SpotifyMedia{
  [CmdletBinding()]
  param (
    $Media,
    $synchash,
    $thisApp,
    [switch]$use_WebPlayer = $thisapp.config.Spotify_WebPlayer,
    [switch]$Show_notifications = $thisApp.config.Show_notifications,
    [switch]$RestrictedRunspace = $thisapp.config.Spotify_WebPlayer
  )
  try{
    $Start_SpotifyMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    write-ezlogs "##### Start-SpotifyMedia Executed for $($Media.title)" -loglevel 2 -linesbefore 1   
    [void](Stop-Runspace -thisApp $thisApp -runspace_name 'Spotify_Play_media' -force)
  }catch{
    write-ezlogs " An exception occurred stopping existing runspace 'Spotify_Play_media'" -showtime -catcherror $_
  }
  try{
    #Clear various tracking variables  
    $synchash.Start_media = $null
    $synchash.Last_Played = $Null
    $synchash.VLC_PlaybackCancel = $true     
    $synchash.Youtube_WebPlayer_URL = $null
    $synchash.Youtube_WebPlayer_title = $null   
    $synchash.Spotify_WebPlayer_URL = $null
    $synchash.Current_Video_Quality = $Null
    $synchash.Current_Audio_Quality = $null
    $synchash.WebPlayer_State = $null
    $Background_cached_image = $null
    $synchash.Spotify_WebPlayer_title = $null
    if(-not [string]::IsNullOrEmpty($synchash.Spotify_WebPlayer_State.playbackstate)){
      $synchash.Spotify_WebPlayer_State.playbackstate = 0
    }
    $synchash.Session_SpotifyId = $Null
    #$synchash.Spotify_WebPlayer = $null
    $synchash.Session_Spotifytype = $Null
    $synchash.Current_Spotify_Deviceid = $null
    if($synchash.Start_media_timer){
      $synchash.Start_media_timer.stop() 
    }
    Reset-MainPlayer -thisApp $thisApp -synchash $synchash -SkipSpotify:$use_WebPlayer
    if(!$use_WebPlayer){
      Set-SpotifyWebPlayerTimer -synchash $synchash -thisApp $thisApp
    }else{
      $sprocess = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
      if($sprocess){
        write-ezlogs "Forcing Spotify client to close since we are using the webplayer.." -showtime -warning
        foreach($p in $sprocess){
          $p.kill()
          $p.dispose()
        }
      }
    }
    #Reset UI
    #Update-MainPlayer -synchash $synchash -thisApp $thisApp -Now_Playing_Title "LOADING..." -Clear_Now_Playing_Artist -Clear_DisplayPanel_Bitrate
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Title_Label' -Property 'DataContext' -value 'LOADING...'
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'DisplayPanel_Bitrate_TextBlock' -Property 'text' -value '' -NullValue
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -value '' -NullValue

    #Make sure last played is removed from queue
    if($synchash.Current_playing_media.id -ne $media.id -and $thisapp.config.Current_Playlist.values -contains $synchash.Current_playing_media.id){
      write-ezlogs "| Removing last played from Queue: $($synchash.Current_playing_media.title)" -LogLevel 2
      Update-PlayQueue -Remove -ID $synchash.Current_playing_media.id -thisApp $thisApp -synchash $synchash -UpdateHistory                            
    }
    $synchash.Current_playing_media = $Null
    $synchash.Youtube_webplayer_current_Media = $Null
    $thisApp.Config.Current_Playing_Media = $null 
    $synchash.ChatView_URL = $null
    Update-ChatView -synchash $synchash -thisApp $thisApp -Disable -Hide
    $synchash.Media_Current_Title = ''
    #Make Sure Spotify status is stopped
    $synchash.Spotify_Status = 'Stopped'  
    if($Synchash.Timer.isEnabled){
      if($thisApp.Config.Dev_mode){write-ezlogs "| Stopping Media Timer" -showtime -Dev_mode}
      $Synchash.Timer.stop()
    }
    if($synchash.vlc.IsPlaying -or $synchash.Vlc.state -match 'Paused'){
      write-ezlogs ">>>> Stopping Vlc and unsetting media"
      $synchash.vlc.media = $Null
      $synchash.VLC_IsPlaying_State = $false
      $synchash.vlc.stop()
      #$synchash.vlc.media = $Null
    } 
  }catch{
    write-ezlogs " An exception occurred resetting media or UI states" -showtime -catcherror $_
  }
  try{
    if($Media){ 
      #$synchash.update_Queue_timer.start()
      $spotify_scriptblock = {
        param (
          $Media = $Media,
          $synchash = $synchash,
          $thisApp = $thisApp,
          [switch]$use_WebPlayer = $use_WebPlayer,
          [switch]$Show_notifications = $Show_notifications,
          [switch]$RestrictedRunspace = $RestrictedRunspace
        )
        try{
          write-ezlogs ">>>> Selected Spotify Media to play $($Media.title)" -showtime
          if($thisApp.Config.Dev_mode){write-ezlogs "Media object: $($Media | out-string)" -showtime -Dev_mode}
          if(@($Media).count -gt 1){
            write-ezlogs "More than 1 media object was provided. Selecting first only to continue" -showtime -warning
            $media = $Media | Select-Object -first 1
          }
          #$mediatitle = $($Media.title)
          $artist = $Media.Artist
          $url = $($Media.url) 
          $Spotify_Path = $("$($env:APPDATA)\Spotify\Spotify.exe")     
          try{
            $newProc = [System.Diagnostics.ProcessStartInfo]::new("$env:SYSDIR32\NETSTAT.EXE")
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "-an"
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $newProc.RedirectStandardOutput = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
            while(!$Process.StandardOutput.EndOfStream -and !$netStat){
              $line = $Process.StandardOutput.ReadLine()
              if(($line -match '127.0.0.1:8974' -or $line -match '0.0.0.0:8974') -and ($line -match 'LISTENING' -or $line -match 'ESTABLISHED')){
                $netStat = $line
              }
            } 
          }catch{
            write-ezlogs "An exception occurred executing: $env:SYSDIR32\NETSTAT.EXE" -catcherror $_
          }finally{
            if($Process -is [System.IDisposable]){
              $Process.dispose()
            }
          }        
          if($RestrictedRunspace){
            write-ezlogs ">>>> Using restricted runspace, importing required modules"
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\EZT-AudioManager\EZT-AudioManager.psm1" -NoClobber -DisableNameChecking -Scope Local
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -NoClobber -DisableNameChecking -Scope Local
          }
          #$netstat = (NETSTAT.EXE -an) | Where-Object {($_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974') -and ($_ -match 'LISTENING' -or $_ -match 'ESTABLISHED')}
          if($thisApp.config.Use_Spicetify -and $netstat){
            try{   
              write-ezlogs ">>>> Spicetify in use - Netstat Status: $($netstat | out-string)" -showtime
              write-ezlogs "| Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- Spicetify.is_paused: $($synchash.Spicetify.is_paused)" -showtime
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
              $synchash.Spicetify = ''
            }catch{
              write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
              $synchash.Spicetify = ''
              $sprocess = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
              if($sprocess){
                foreach($p in $sprocess){
                  $p.kill()
                  $p.dispose()
                }
              }             
            }
          }elseif($synchash.current_track_playing.is_playing){
            try{
              $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
              $device = $devices | where-Object {$_.is_active -eq $true}
              if(!$device){
                $device = $devices | Select-Object -last 1
              }
              write-ezlogs ">>>> Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($device.id) " -showtime
              $synchash.Spicetify = ''
              $synchash.current_track_playing = $Null
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $device.id
            }catch{
              write-ezlogs "An exception occurred executing Suspend-Playback for device $($device.id)" -showtime -catcherror $_
              $synchash.Spicetify = ''
              $sprocess = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
              if($sprocess){
                foreach($p in $sprocess){
                  $p.kill()
                  $p.dispose()
                }
              }             
            }      
          }  
          Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -Add_First $media.id -RefreshQueue
          <#      [array]$existingitems = $thisApp.config.Current_Playlist.values 
              if(!$thisApp.config.Current_Playlist){
              $thisApp.config.Current_Playlist = [SerializableDictionary[int,string]]::new()
              }
              if($thisApp.config.Current_Playlist.values -notcontains $media.id){
              $null = $thisApp.config.Current_Playlist.clear()
              $index = 0
              write-ezlogs "[Start-SpotifyMedia] | Adding $($media.id) to Play Queue" -showtime -logtype Spotify
              $null = $thisApp.config.Current_Playlist.add($index,$media.id) 
              foreach($id in $existingitems){
              $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisApp.config.Current_Playlist.add($index,$id)
              }    
          }#>
        }catch{
          write-ezlogs "[Start-SpotifyMedia] An exception occurred updating current_playlist" -showtime -catcherror $_
        } 
        try{
          $Spotify_Path = $("$($env:APPDATA)\Spotify\Spotify.exe")
          if($Media.type -eq 'Playlist'){
            if($use_WebPlayer){
              $Spotify_ID = $Media.Playlist_ID
              $playback_url = "https://open.spotify.com/playlist/$($Spotify_ID)"
            }else{
              $Spotify_ID = $Media.Playlist_URL
              $playback_url = $($Spotify_ID)
            }         
          }else{
            if($use_WebPlayer){
              if($Media.Spotify_id){
                $Spotify_ID= $Media.Spotify_id
                #$playback_url = "https://open.spotify.com/track/$($Spotify_ID)"
              }
              if($media.Url -match 'track'){
                if($media.Url -match "track\:"){
                  $Spotify_ID = ($($media.Url) -split('track:'))[1].trim()
                }elseif($media.Url -match '\/track\/'){
                  $Spotify_ID = ($($media.Url) -split('\/track\/'))[1].trim() 
                }
                $playback_url = "https://open.spotify.com/track/$($Spotify_ID)"                   
              }elseif($media.Url -match "episode"){
                if($media.Url -match 'episode\:'){
                  $Spotify_ID = ($($media.Url) -split('episode:'))[1].trim()  
                }elseif($media.Url -match '\/episode\/'){
                  $Spotify_ID = ($($media.Url) -split('\/episode\/'))[1].trim()  
                }
                if($Spotify_ID -match '\?si\='){
                  $Spotify_ID = ($($Spotify_ID) -split('\?si\='))[0].trim()
                }                       
                $playback_url = "https://open.spotify.com/episode/$($Spotify_ID)"                  
              }elseif($media.Url -match "show"){  
                if($media.Url -match 'episode\:'){
                  $Spotify_ID = ($($media.Url) -split('show:'))[1].trim() 
                }elseif($media.Url -match '\/show\/'){
                  $Spotify_ID = ($($media.Url) -split('\/show\/'))[1].trim()  
                } 
                if($Spotify_ID -match '\?si\='){
                  $Spotify_ID = ($($Spotify_ID) -split('\?si\='))[0].trim()
                }
                $playback_url = "https://open.spotify.com/show/$($Spotify_ID)"                  
              }         
            }else{
              $Spotify_ID = $media.Url         
              $playback_url = $($media.Url)
            }        
          }
          if($use_WebPlayer){
            write-ezlogs ">>>> Using Spotify Web Player with playback url $playback_url" -showtime
            if($syncHash.WebView2 -eq $null -or $synchash.Webview2.CoreWebView2 -eq $null){
              $synchash.Initialize_WebPlayer_timer.start()
            }
            $Name = $media.title            
            $Artist = $media.Artist
            $title = "$($Name) - $($Artist)"      
            if($Spotify_ID -and $playback_url){
              $synchash.Spotify_WebPlayer_URL = [Uri]$playback_url          
            }else{
              write-ezlogs "Unable to get Spotify_ID and Playback_URL, cannot continue! Media $($media | out-string)" -showtime -warning
              Update-Notifications -Level 'WARNING' -Message "Unable to get Spotify_ID and Playback_URL, cannot continue! See logs" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
              $synchash.Stop_media_timer.start()           
              return
            }                                                             
            #$synchash.Window.Dispatcher.invoke([action]{     
            if($media.duration_ms){
              $synchash.MediaPlayer_CurrentDuration = $media.duration_ms 
              [int]$hrs = $($([timespan]::FromMilliseconds($media.duration_ms)).Hours)
              [int]$mins = $($([timespan]::FromMilliseconds($media.duration_ms)).Minutes)
              [int]$secs = $($([timespan]::FromMilliseconds($media.duration_ms)).Seconds)   
            }  
            #$total_time = "$mins`:$secs" 
            if($hrs -lt 1){
              $hrs = '0'
            }  
            $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
            <#            if($playback_url -and $synchash.txtUrl){
                Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'txtUrl' -Property 'text' -value $playback_url
            }#>                    
            $synchash.Media_Current_Title = $title 
            $synchash.Spotify_WebPlayer_title = $title      
            $synchash.Spotify_WebPlayer_URL = [Uri]$playback_url
            $synchash.Last_Played = ($Media.id)
            $synchash.Current_playing_media = $media
            $synchash.Last_Played_title = $Name
            Set-SpotifyWebPlayerTimer -synchash $synchash -thisApp $thisApp
            #$synchash.Spotify_WebPlayer_timer.start()    
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Label' -Property 'Visibility' -value 'Visible'
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Label' -Property 'DataContext' -value "PLAYING"   
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -value "$($Artist)"
            if($thisApp.Config.Enable_EQ){  
              try{
                write-ezlogs ">>>> Enabling EQ support for Spotify Media" -logtype Libvlc
                $allDevices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::All)
                $capture_device = $allDevices | Where-Object {$_.friendlyname -match 'CABLE Input \(VB-Audio Virtual Cable\)'}
                if($capture_device){
                  $vlcArgs = [System.Collections.Generic.List[String]]::new()
                  [void]$vlcArgs.add('--file-logging')
                  [void]$vlcArgs.add("--logfile=$($thisapp.config.Vlc_Log_file)")
                  [void]$vlcArgs.add("--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
                  [void]$vlcArgs.add("--osd")
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
                    [void]$vlcArgs.add("--video-on-top")
                    [void]$vlcArgs.add("--spect-show-original")
                    if($thisApp.Config.Current_Visualization -eq 'Spectrum'){
                      #$effect = "--effect-list=spectrum"             
                      [void]$vlcArgs.add("--audio-visual=Visual")
                      [void]$vlcArgs.add("--effect-list=spectrum")
                    }else{
                      #$effect = "--effect-list=spectrum"
                      [void]$vlcArgs.add("--audio-visual=$($thisApp.Config.Current_Visualization)")
                      [void]$vlcArgs.add("--effect-list=spectrum")
                    }                                                                      
                  }
                  if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
                    try{
                      $thisapp.config.vlc_Arguments -split ',' | & { process {                 
                          if([regex]::Escape($_) -match '--' -and $vlcArgs -notcontains $_){
                            write-ezlogs "| Adding custom Libvlc option: $($_)" -loglevel 2 -logtype Libvlc
                            [void]$vlcArgs.add("$($_)")
                          }else{
                            write-ezlogs "Cannot add custom libvlc option $($_) - it does not meet the required format or is already added!" -warning -loglevel 2 -logtype Libvlc
                          }
                      }}
                    }catch{
                      write-ezlogs "[Start-SpotifyMedia] An exception occurred processing custom VLC arguments" -catcherror $_
                    }          
                  }
                  [String[]]$libvlc_arguments = $vlcArgs | & { process {
                      if($thisApp.Config.Dev_mode){write-ezlogs "| Applying Libvlc option: $($_)" -loglevel 2 -logtype Libvlc -Dev_mode}
                      if([regex]::Escape($_) -match '--'){
                        $_
                      }else{
                        write-ezlogs "Cannot apply libvlc option $($_) - it does not meet the required format!" -warning -loglevel 2 -logtype Libvlc
                      }
                  }}
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
                    $thisApp.Config.Installed_AppID = $appid
                  }
                  if($appid -and $synchash.libvlc){
                    $synchash.libvlc.SetAppId($appid,$thisApp.Config.App_Version,"$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
                  }
                  Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -wait -Startlibvlc
                }else{
                  write-ezlogs "Unable to find required 'CABLE Input (VB-Audio Virtual Cable)' audio device - cannot enable EQ for Webplayer!" -AlertUI -Warning
                }      
              }catch{
                write-ezlogs "An exception occurred creating new libvlcsharp instance for Spotify audio routing" -showtime -catcherror $_
              }finally{
                if($allDevices){
                  $allDevices.dispose()
                  $allDevices = $Null
                }
                if($capture_device){
                  $capture_device.Dispose()
                  $capture_device = $null
                }
              }
            }                                                   
          }else{    
            $start_Waittimer = 0   
            Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -Force -NoClobber -DisableNameChecking -Scope Local    
            if(![System.IO.File]::Exists($Spotify_Path)){
              try{
                if($psversiontable.PSVersion.Major -gt 5){
                  try{
                    write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning
                    Import-module Appx -usewindowspowershell
                  }catch{
                    write-ezlogs "An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
                  }
                }             
                $Spotify_app = (Get-appxpackage 'Spotify*')
                #$Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify' -or $_.'Display Name' -eq 'Spotify Music'} | select -Unique
                if($Spotify_app){
                  $Spotify_Path = "$($Spotify_app.InstallLocation)\Spotify.exe"
                }
              }catch{
                write-ezlogs "An exception occurred looking for Spotify install" -showtime -catcherror $_
              }
            }elseif([System.IO.File]::Exists($Spotify_Path)){
              $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
              if($Spotify_Process){
                write-ezlogs ">>>> Spotify process is currently running" -showtime -color cyan                          
              }else{   
                write-ezlogs ">>>> Spotify is installed but not running, starting process minimized" -showtime
                if($thisApp.Config.Dev_mode){
                  #$Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru  
                  $Spotify_Process = Start-Process $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru
                }else{
                  #$Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru  
                  $Spotify_Process = Start-Process $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --enable-developer-mode --remote-debugging-port=9222 --no-default-browser-check" -PassThru
                }
              }
              $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
              Set-WindowState -InputObject $Spotify_Process -State HIDE
              #wait for spotify to launch
              #start-sleep 1
            }else{
              write-ezlogs "Unable to find Spotify installed!" -showtime -Warning
              if($thisApp.Config.Install_Spotify){
                write-ezlogs ">>>> Attempting to installing Spotify via chocolatey" -showtime    
                Update-Notifications -Level 'WARNING' -Message "Spotify is not installed! Attempting to install latest version via chocolatey" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
                if(!$(get-command choco*)){
                  $null = confirm-requirements -thisApp $thisApp -noRestart
                }
                write-ezlogs "----------------- [START] Install Spotify via chocolatey [START] -----------------" -showtime  -logtype Spotify
                $chocoappmatch = choco list Spotify
                write-ezlogs "$($chocoappmatch)" -showtime -logtype Spotify
                $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                if(-not [string]::IsNullOrEmpty($appinstalled) -and $appinstalled -notmatch 'Removing incomplete install for'){               
                  if([System.IO.Directory]::Exists("$($env:APPDATA)\Spotify")){
                    $appinstalled_Version = (Get-ItemProperty "$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
                    if($appinstalled_Version){
                      write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)). Also detected installed exe: $($appinstalled_Version). Will continue to attemp to update Spotify..." -showtime -warning -logtype Spotify
                    }
                  }else{
                    write-ezlogs "Chocolatey says Spotify is installed (Version: $($appinstalled)), yet it does not exist. Choco database likely corrupted or out-dated, performing remove of Spotify via Chocolately.." -showtime -warning -logtype Spotify
                    $chocoremove = choco uninstall Spotify --confirm --force
                    write-ezlogs "Verifying if Choco still thinks Spotify is installed..." -showtime -logtype Spotify
                    $chocoappmatch = choco list Spotify
                    $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                    if(-not [string]::IsNullOrEmpty($appinstalled)){
                      write-ezlogs "Choco still thinks Spotify is installed, unable to continue! Check choco logs at: $env:ProgramData\chocolatey\logs\chocolatey.log" -showtime -warning -logtype Spotify
                      return
                    }
                  }
                }
                $choco_install = choco upgrade Spotify --confirm --force --acceptlicense 4>&1 | Out-File -FilePath $thisApp.Config.SpotifyMedia_logfile -Encoding unicode -Append
                write-ezlogs "----------------- [END] Install Spotify via chocolatey [END] -----------------" -showtime -logtype Spotify
                write-ezlogs "Verifying if Spotify was installed successfully...." -showtime
                $chocoappmatch = choco list Spotify
                if($chocoappmatch){
                  $appinstalled = $($chocoappmatch | Select-String Spotify | out-string).trim()
                } 
                if(-not [string]::IsNullOrEmpty($appinstalled)){
                  if($appinstalled -match 'spotify'){
                    $appinstalled = $appinstalled.replace('spotify','').trim()
                    if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
                      write-ezlogs ">>>> Checking for spotify at $($env:APPDATA)\Spotify\Spotify.exe" -showtime
                      $Spotify_directory = $("$($env:APPDATA)\Spotify\Spotify.exe") | Split-Path -parent
                      $Spotify_Path = $("$($env:APPDATA)\Spotify\Spotify.exe")
                    }
                  }                                
                }                      
                if([System.IO.File]::Exists($Spotify_Path)){
                  write-ezlogs "Spotify is now installed, continuing to launch process" -showtime -Success
                  Update-Notifications -Level 'INFO' -Message "Spotify installed successfully! Attempting to start, you may need to login with your Spotify account!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
                  if($playback_url){
                    $Spotify_Process = Start-Process $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru
                  }else{
                    $Spotify_Process = Start-Process $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru
                  }              
                  #wait for spotify to launch   
                }else{
                  write-ezlogs "Spotify did not appear to install or unable to find, cannot continue" -showtime -warning
                  Update-Notifications -Level 'WARNING' -Message "Spotify was unable to install automatically. You may need to install it manually" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
                  return
                }     
              }else{
                Update-Notifications -Level 'WARNING' -Message "Spotify is not installed! You must manually install Spotify or enable the 'Install Spotify' option under Settings" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
                write-ezlogs "Auto installation of Spotify is not enabled, skipping install. Spotify must be manually installed for Spotify features to function" -showtime -warning
              }
            }
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name            
            $device = $devices | Where-Object {$_.is_active -eq $true} 
            if(!$device){
              $device = $devices | Select-Object -last 1
            } 
            write-ezlogs ">>>> Getting available spotify devices for app $($thisApp.config.App_Name) - Device: $device" -showtime           
            #$Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
            if(!$device){
              write-ezlogs "| No spotify devices available from api, waiting for spotify to start" -showtime
              if(!$Spotify_Process.MainWindowHandle){ 
                while(!$Spotify_Process.MainWindowHandle -and $start_waittimer -le 120){
                  write-ezlogs "....Waiting for Spotify Process" -showtime
                  $start_waittimer++
                  $Spotify_Process = (Get-Process -Name 'Spotify*')
                  start-sleep -Milliseconds 100
                }
                Set-WindowState -InputObject $Spotify_Process -State HIDE
              }                    
              $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name 
              $device = $devices | Where-Object {$_.is_active -eq $true} 
              if(!$device){
                $device = $devices | Select-Object -last 1
              }         
              if($device){
                write-ezlogs "| Found Spotify device $($device | out-string)" -showtime 
                if(!$thisApp.config.Use_Spicetify){
                  $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id  
                }       
              }                 
            }else{
              if($thisApp.Config.Dev_mode){write-ezlogs "| Found Spotify device $($device | out-string)" -showtime -Dev_mode}
              $Spotify_Process = (Get-Process -Name 'Spotify*')            
            }
            if($Spotify_Process.id){
              write-ezlogs ">>>> Found Spotify Process $($Spotify_Process.Id)" -showtime
              try{
                write-ezlogs "| Hiding Spotify Process window" -showtime    
                Set-WindowState -InputObject $Spotify_Process -State HIDE
              }catch{
                write-ezlogs "An exception occurred in Set-WindowState" -showtime -catcherror $_
              } 
              if($thisApp.Config.Enable_EQ){
                try{
                  Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -start -wait -Startlibvlc -ProcessName 'spotify.exe'
                }catch{
                  write-ezlogs "An exception occurred executing Set-ApplicationAudioDevice for Spotify" -showtime -catcherror $_
                }           
              }                            
            }elseif($start_waittimer -ge 120){
              write-ezlogs "Timed out waiting for Spotify process to start, cannot continue!" -showtime -warning -AlertUI
              return
            }              
            #$current_track = $Null 
            $waittimer = 0      
            if($thisApp.config.Use_Spicetify){
              try{
                write-ezlogs ">>>> Using Spicetify - starting playback with command http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime
                Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing                                
              }catch{
                write-ezlogs "An exception occurred in Start-Playback using Invoke-RestMethod for url http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime -catcherror $_
              }                                          
              while((!$synchash.Spicetify.is_playing -or $synchash.Spicetify.title -notmatch $media.title) -and $waittimer -lt 60){
                write-ezlogs "| Waiting for Spotify Playback to begin...Spicetify: $($synchash.Spicetify | out-string)" -showtime
                if($waittimer -eq 10 -and !(Get-Process Spotify*)){
                  write-ezlogs "Spotify should have started by now, lets restart Spotify" -showtime -warning
                  $Spotify_Process = Start-Process $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --enable-developer-mode --show-console --remote-debugging-port=9222 --no-default-browser-check" -PassThru
                }
                if((Get-Process Spotify*) -and $waittimer -eq 5){
                  try{
                    Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing                                         
                  }catch{
                    write-ezlogs "[Start-SpotifyMedia] An exception occurred in Start-Playback using Invoke-RestMethod for url http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime -catcherror $_
                  }
                }
                $waittimer++
                start-sleep 1
              }
              if($Spotify_Process){
                try{
                  write-ezlogs "| Hiding Spotify Process window..again?" -showtime    
                  $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
                  Set-WindowState -InputObject $Spotify_Process -State HIDE
                }catch{
                  write-ezlogs "An exception occurred in Set-WindowState" -showtime -catcherror $_
                } 
              }
            }else{
              if($Media.type -eq 'Playlist'){
                try{
                  if($($Media.Playlist_URL)){
                    $url = $($Media.Playlist_URL)
                  }elseif($($Media.url)){
                    $url = $($Media.url)
                  }
                  write-ezlogs ">>>> Starting playback of spotify playlist: $($url)" -showtime
                  Start-Playback -ContextUri $url -ApplicationName $thisApp.config.App_Name -DeviceId $device.id
                }catch{
                  write-ezlogs "An exception occurred in Start-Playback for url $($url)" -showtime -catcherror $_
                } 
              }elseif($Media.type -eq 'Track'){
                if($Media.Playlist_URL){
                  write-ezlogs ">>>> Starting playback of spotify track: $($Media.title) -- from playlist: $($Media.Playlist) -- URL: $($media.Url) -- Device: $($device.id)" -showtime        
                  try{               
                    $start_playback = Start-Playback -TrackUris $media.Url -ApplicationName $thisApp.config.App_Name -DeviceId $device.id
                    write-ezlogs "| Setting Spotify Volume to: $($thisapp.Config.Media_Volume)" -showtime
                    Set-PlaybackVolume -VolumePercent $($thisapp.Config.Media_Volume) -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
                  }catch{
                    write-ezlogs "An exception occurred in Start-Playback Playlist URL: $($Media.Playlist_URL) -- Track URL: $($media.Url)" -showtime -catcherror $_
                  }                        
                }else{
                  write-ezlogs ">>>> Starting playback of Spotify track: $($Media.Title)" -showtime
                  try{
                    Start-Playback -TrackUris $media.Url -ApplicationName $thisApp.config.App_Name -DeviceId $device.id
                    write-ezlogs "| Setting Spotify Volume to: $($thisapp.Config.Media_Volume)" -showtime
                    Set-PlaybackVolume -VolumePercent $($thisapp.Config.Media_Volume) -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
                  }catch{
                    write-ezlogs "An exception occurred in Start-Playback for track url $($media.Url)" -showtime -catcherror $_
                  }                         
                }
              }          
              $waittimer = 0
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id        
              while(!$current_track.is_playing -and $waittimer -lt 60 -and !$current_track.item.name){
                try{  
                  write-ezlogs "| Waiting for Spotify playback to start...Current Track: $($current_track)" -showtime
                  $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id              
                  $synchash.current_track_playing = $current_track
                }catch{
                  write-ezlogs "An exception occurred getting the current track" -showtime -catcherror $_
                }
                $waittimer++
                start-sleep 1
              }            
            } 
            if($thisApp.Config.Dev_mode){write-ezlogs "Now Spotify Track item: $($current_track.item | out-string)" -showtime -Dev_mode }  
            if($waittimer -ge 60){
              write-ezlogs "Timed out waiting for Spotify playback to begin!" -showtime -warning
              Update-Notifications -Level 'WARNING' -Message "Timed out waiting for Spotify playback to begin! Cannot continue" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
              $synchash.Stop_media_timer.start()
              return        
            }
            if(!$thisApp.config.Use_Spicetify){
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id 
            }  
          }
          if($Media.id){
            $synchash.Last_Played = ($Media.id)        
          }        
          if($thisApp.Config.Enable_AudioMonitor){
            Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchash -Action Begin
          }
          if((Test-ValidPath $Media.cached_image_path -Type URLorFile)){
            $image = $Media.cached_image_path
          }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){    
            $image = $Media.thumbnail
          }elseif(($Media.images).url){
            $image = ($Media.images | Where-Object {$_.Width -le 300} | select-Object -First 1).url
            if(!$image){
              $image = ($Media.images | where-Object {$_.Width -ge 300} | select-Object -last 1).url
            }
            if(!$image){
              $image = (($Media.images).psobject.Properties.Value).url | select-Object -First 1
            }
          }else{
            $image = $null
          }   
          $image_Cache_path = $Null
          $imageid = $null
          if($image)
          {
            if($thisApp.Config.Dev_mode){write-ezlogs "Media Image found: $($image)" -showtime -Dev_mode}       
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              if($thisApp.Config.Dev_mode){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime -Dev_mode}
              [void][System.IO.Directory]::CreateDirectory($thisApp.config.image_Cache_path)
            }
            $encodeduri = $Null  
            if($media.Album_ID){
              $imageid = $media.Album_ID
            }else{
              $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
              $imageid = [System.Convert]::ToBase64String($encodedBytes)         
            }                   
            $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($imageid).png")
            if([System.IO.File]::Exists($image_Cache_path)){
              $cached_image = $image_Cache_path
              if($thisApp.Config.Dev_mode){write-ezlogs "| Found cached image: $cached_image" -showtime -Dev_mode}
            }elseif($image){         
              if($thisApp.Config.Dev_mode){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime -Dev_mode}
              try{
                if([System.IO.File]::Exists($image)){
                  if($thisApp.Config.Dev_mode){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime -Dev_mode}
                  $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
                }else{
                  try{
                    $uri = [system.uri]::new($image)
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime -Dev_mode}
                    $webclient = [System.Net.WebClient]::new()
                    $null = $webclient.DownloadFile($uri,$image_Cache_path)
                  }catch{
                    write-ezlogs "An exception occurred downloading file $($uri) to path $($image_Cache_path)" -catcherror $_
                  }finally{
                    if($webclient){
                      $webclient.Dispose()
                      $webclient = $Null
                    }
                  }
                }             
                if([System.IO.File]::Exists($image_Cache_path)){
                  $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                  $image.BeginInit()
                  $image.CacheOption = "OnLoad"
                  #$image.CreateOptions = "DelayCreation"
                  #$image.DecodePixelHeight = 229;
                  $image.DecodePixelWidth = 500
                  $image.StreamSource = $stream_image
                  $image.EndInit()    
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze()
                  if($thisApp.Config.Dev_mode){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs -Dev_mode}
                  $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                  $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                  $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                  $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                  $encoder.Save($save_stream)
                  $save_stream.Dispose()
                  $cached_image = $image_Cache_path       
                }else{
                  write-ezlogs "Unable to find cached image at $image_Cache_path" -showtime
                  $cached_image = $Null
                }                           
              }catch{
                $cached_image = $Null
                write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
              }           
            }else{
              write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
              $cached_image = $Null        
            }                                      
          }
          if([System.IO.File]::Exists($cached_image)){       
            $Background_cached_image = $cached_image
          }else{
            $Background_cached_image = $null
          }  
          if([System.IO.File]::Exists($Background_cached_image)){
            write-ezlogs ">>>> Stamping cached media image: $($Background_cached_image)"
            $stamped_image = Merge-Images -synchash $synchash -thisApp $thisApp -LargeImage $Background_cached_image -StampIcon 'Spotify' -StampIcon_Pack "PackIconMaterial" -StampIcon_Color '#FF1ED760' -decode_Width '500'
          }else{
            $stamped_image = $null
          }
          if([System.IO.File]::Exists($stamped_image)){
            $Background_cached_image = $stamped_image
            if($synchash.MediaView_Image){
              write-ezlogs ">>>> Setting MediaView_Image source to Spotify media image: $stamped_image"
              Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaView_Image' -Property 'Source' -value $stamped_image
              Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'VLC_Grid_Row1' -Property 'Height' -value "100*"
            }
          }else{
            write-ezlogs "No Spotify media image available, clearing MediaView_image source" -showtime -warning
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaView_Image' -Property 'Source' -value $Null -ClearValue
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'VLC_Grid_Row1' -Property 'Height' -value "*"
          }                                            
          if($thisApp.config.Show_notifications){
            try{
              $spotify_startapp = Get-AllStartApps *spotify
              if($spotify_startapp){
                $spotify_appid = $spotify_startapp.AppID
              }elseif($thisApp.Config.Installed_AppID){
                $spotify_appid =  $thisApp.Config.Installed_AppID
              }else{
                $spotify_appid = $Spotify_Path
              }              
              if(!$cached_image){
                $applogo = "$($thisApp.Config.Current_folder)\Resources\Spotify\Material-Spotify.png"
              }else{
                $applogo = $cached_image
              }
              [int]$hrs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Hours)
              [int]$mins = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Minutes)
              [int]$secs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Seconds)                 
              $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
              $Message = "Song : $($Name) - $($Artist)`nPlay Duration : $total_time`nSource : Spotify"
              Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local           
              New-BurntToastNotification -AppID $spotify_appid -Text $Message -AppLogo $applogo

            }catch{
              write-ezlogs "An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_
            }
          }                              
          if(($current_track -or $synchash.Spicetify) -and !$use_WebPlayer){
            if($thisApp.Config.Use_Spicetify){
              $Name = $synchash.Spicetify.title
              $Artist = $synchash.Spicetify.ARTIST             
            }elseif($use_WebPlayer){
              $Name = $media.title            
              $Artist = $media.Artist
            }else{
              $Name = $current_track.item.name
              $Artist = $current_track.item.artists.name         
            } 
            if(!$thisApp.config.Use_Spicetify){
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id 
            }                               
            $synchash.current_track_playing = $current_track
            if($thisApp.Config.Verbose_logging){
              if($thisApp.Config.Use_Spicetify){
                write-ezlogs ">>>> Spicetify Current Track Playing: $($synchash.Spicetify | out-string)" -showtime
              }else{
                write-ezlogs ">>>> Current Track Playing: $($current_track | out-string)" -showtime
              }         
            }              
            if($thisApp.Config.Use_Spicetify){
              while((!$synchash.Spicetify.is_playing -or $synchash.Spicetify.title -notmatch $media.Title)){
                try{                   
                  $Name = $synchash.Spicetify.title
                  $Artist = $synchash.Spicetify.ARTIST  
                  $status = $synchash.Spicetify.is_Playing
                  $pause = $synchash.Spicetify.is_paused 
                  $synchash.Last_Played_title = $Name                    
                  write-ezlogs "| Waiting for Spicetify (Status: $status) - (Pause: $pause) - (Title: $($Name) - (Track Name: $($media.title)))" -showtime -warning                            
                }catch{
                  write-ezlogs "An exception occurred getting the current track" -showtime -catcherror $_
              
                }
                start-sleep -Milliseconds 500
              }              
            }else{
              $current_Track_wait = 0
              while((!$Name -or !$current_track.is_playing -and ($current_Track_wait -lt 60))){
                try{    
                  write-ezlogs "Waiting for Get-CurrentTrack status to indicate Spotify is playing and responding with playing title $name..." -showtime -warning
                  $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $device.id
                  write-ezlogs "| Current Track: $($Current_Track | out-string)"
                  $Name = $current_track.item.name
                  write-ezlogs "| Name: $($Name)"
                  $Artist = $current_track.item.artists.name    
                  write-ezlogs "| Artist: $($Artist)"
                  $progress = $current_track.progress_ms 
                  write-ezlogs "| Progress: $($progress)"
                  $synchash.Last_Played_title = $Name      
                  write-ezlogs "| Is_Playing: $($current_track.is_playing)" 
                  Start-sleep -Milliseconds 500
                  $current_Track_wait++        
                }catch{
                  write-ezlogs "An exception occurred getting the current track" -showtime -catcherror $_           
                }
                start-sleep -Milliseconds 500
              }
              if($current_Track_wait -ge 60){
                write-ezlogs "Timed out waiting for status of current playing Spotify media!" -showtime -warning
                Update-Notifications -Level 'WARNING' -Message "Timed out waiting to get status of current playing Spotify media!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
                return
              
              }
            }             
            #$synchash.Window.Dispatcher.invoke([action]{    
            if($thisApp.Config.Use_Spicetify){
              $Name = $synchash.Spicetify.title
              $Artist = $synchash.Spicetify.ARTIST             
            }else{
              $Name = $current_track.item.name
              $progress = $current_track.progress_ms
              $Artist = $current_track.item.artists.name
            } 
            $title = "$($Name) - $($Artist)"  
            $synchash.Media_Current_Title = "$($Name) - $($Artist)"                 
            $synchash.Last_Played_title = $Name           
            $synchash.Current_playing_media = $media
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaPlayer_Slider' -Property 'Maximum' -value $([timespan]::FromMilliseconds($current_track.item.duration_ms)).TotalSeconds     
            [int]$hrs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Hours)
            [int]$mins = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Minutes)
            [int]$secs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Seconds)     
            $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
            #$total_time = "$mins`:$secs" 
            if($Current_track.item.external_urls.spotify -and $synchash.txtUrl.text){
              Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'txtUrl' -Property 'text' -value $Current_track.item.external_urls.spotify
            }                       
            $synchash.current_track_playing = $current_track
            $synchash.Last_Played_title = $Name
            $synchash.Spotify_Status = 'Playing'
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Label' -Property 'Visibility' -value 'Visible'
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Label' -Property 'DataContext' -value "PLAYING"   
            Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'text' -value "$($Artist)"
            write-ezlogs ">>>> Updating UI for media state" -showtime
            if($synchash.update_Queue_timer -and !$synchash.update_Queue_timer.isEnabled -and !$synchash.Playlists_Update_Timer.isEnabled){
              $synchash.update_Queue_timer.Tag = 'UpdatePlaylists'
              [void]$synchash.update_Queue_timer.start() 
            }  
            Update-MediaState -thisApp $thisApp -synchash $synchash -Background_cached_image $Background_cached_image  
            try{
              try{
                $newProc = [System.Diagnostics.ProcessStartInfo]::new("$env:SYSDIR32\NETSTAT.EXE")
                $newProc.WindowStyle = 'Hidden'
                $newProc.Arguments = "-an"
                $newProc.UseShellExecute = $false
                $newProc.CreateNoWindow = $true
                $newProc.RedirectStandardOutput = $true
                $Process = [System.Diagnostics.Process]::Start($newProc)
                while(!$Process.StandardOutput.EndOfStream -and !$netStat){
                  $line = $Process.StandardOutput.ReadLine()
                  if(($line -match '127.0.0.1:8974' -or $line -match '0.0.0.0:8974') -and ($line -match 'LISTENING' -or $line -match 'ESTABLISHED')){
                    $netStat = $line
                  }
                }
              }catch{
                write-ezlogs "An exception occurred executing: $env:SYSDIR32\NETSTAT.EXE" -catcherror $_
              }finally{
                if($Process -is [System.IDisposable]){
                  $Process.dispose()
                }
              } 
              if($thisapp.config.Use_Spicetify -and $synchash.Spicetify.is_playing -and $netstat){
                write-ezlogs ">>>> Spotify with Spicetify is now playing: $($synchash.Spicetify.title) - $($synchash.Spicetify.ARTIST)"
                write-ezlogs " | Setting playback volume (http://127.0.0.1:8974/SETVOLUME?$($thisApp.Config.Media_Volume)) for Spotify to $($thisApp.Config.Media_Volume)"        
                Invoke-RestMethod -Uri "http://127.0.0.1:8974/SETVOLUME?$($thisApp.Config.Media_Volume)" -UseBasicParsing 
                if($synchash.Spicetify.is_paused){
                  write-ezlogs "Spotify is paused, Unpausing Spotify with command http://127.0.0.1:8974/PLAY" -showtime -warning
                  Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PLAY' -UseBasicParsing  
                }         
              }else{
                write-ezlogs " | Setting playback volume for Spotify to $($thisApp.Config.Media_Volume)"
                Set-PlaybackVolume -VolumePercent $($thisApp.Config.Media_Volume) -ApplicationName $thisapp.config.App_Name
              }
            }catch{
              write-ezlogs "An exception occurred setting volume for spotify to $($thisApp.Config.Media_Volume)" -catcherror $_
            }
            if($Synchash.Timer){
              write-ezlogs ">>>> Starting Media Timer" -showtime
              $Synchash.Timer.start()      
            }                       
            $Name = $media.title
            $progress = 1
            start-sleep 1   
            $synchash.Spotify_Status = 'Playing'                                                   
            #while($current_track.is_playing -and $synchash.Spicetify.is_paused -eq $false -and $synchash.Spicetify.is_playing -and ($thisApp.Config.Spotify_Status -ne 'Stopped' -or $thisApp.Config.Spotify_Status -ne $null) ){
            while(($synchash.Spotify_Status -ne 'Stopped') -and ($progress -ne $null) -and $media.title -match $Name -and  ($progress -ne 0)){
              try{
                if($thisApp.Config.Use_Spicetify){
                  $Name = $synchash.Spicetify.title
                  $status = $synchash.Spicetify.is_Playing
                  $pause = $synchash.Spicetify.is_paused
                  $Artist = $synchash.Spicetify.ARTIST
                  try{
                    if($synchash.Spicetify.POSITION -ne $Null){
                      #$progress = [timespan]::Parse($synchash.Spicetify.POSITION).TotalMilliseconds
                      $progress = [timespan]::ParseExact($synchash.Spicetify.POSITION, "%m\:%s",[System.Globalization.CultureInfo]::InvariantCulture).TotalMilliseconds
                    }else{
                      $progress = $($([timespan]::FromMilliseconds(0)).TotalMilliseconds)
                    }
                  }catch{
                    write-ezlogs "An exception occurred parsing Spicetify position timespan" -showtime -catcherror $_
                  }                 
                }else{
                  $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name  -DeviceId $device.id            
                  $Name = $current_track.item.name
                  $Artist = $current_track.item.artists.name
                  $status = $current_track.is_Playing
                  $progress = $current_track.progress_ms
                  $synchash.current_track_playing = $current_track
                } 
                $synchash.Last_Played_title = $name                          
                #$synchash.current_track = $current_track         
                if($thisApp.Config.Dev_mode){write-ezlogs "Track '$($Name)' (Should be Name: $($media.title)) is playing (Status: $status) - (Pause: $pause) - (State: $($synchash.Spicetify.state)) with progress $($progress)" -showtime -Dev_mode}
              }catch{
                write-ezlogs "An exception occurred getting the current track" -showtime -catcherror $_
              
              }
              start-sleep -Milliseconds 250
            }
            if($media.title -notmatch [regex]::Escape($Name)){
              write-ezlogs ">>>> A different track is now playing (og: $($media.title)) - (Now: $Name)" -showtime
            }
            if(!$progress){
              write-ezlogs ">>>> Progress is now null or 0: $progress" -showtime
            }
            if($synchash.Spotify_Status -eq 'Stopped'){
              write-ezlogs ">>>> Spotify_Status is now 'Stopped'" -showtime
            }
            if(!$synchash.Timer.isEnabled){
              write-ezlogs ">>> Media timer isn't running, starting to make sure auto-advance or stop media occurs" -warning
              $synchash.Timer.Start()
            } 
            $synchash.current_track_playing = $null
            $synchash.Spotify_Status = 'Stopped'
            $synchash.current_track = $null          
            write-ezlogs ">>>> Playback of track '$($media.title)' finished" -showtime
            if($thisApp.config.Use_Spicetify -and $synchash.Spicetify){
              write-ezlogs "| Stopping Spotify playback with command http://127.0.0.1:8974/PAUSE" -showtime
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
              if($thisapp.Config.Enable_EQ -and $([string]$synchash.vlc.media.Mrl).StartsWith("dshow://") -and $synchash.VLC_IsPlaying_State){
                write-ezlogs "| Stopping vlc playback for Spotify routed audio dshow://" -Warning
                $synchash.VLC_IsPlaying_State = $false
                $synchash.vlc.stop()           
              }               
            }else{
              #write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($device.id)" -showtime -color cyan
              #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $device.id          
            }             
          }elseif($use_WebPlayer){
            if($synchash.update_Queue_timer -and !$synchash.update_Queue_timer.isEnabled -and !$synchash.Playlists_Update_Timer.isEnabled){
              $synchash.update_Queue_timer.Tag = 'UpdatePlaylists'
              [void]$synchash.update_Queue_timer.start() 
            }
            Update-MediaState -thisApp $thisApp -synchash $synchash -Background_cached_image $Background_cached_image          
          }else{
            write-ezlogs "Unable to get current playing Spotify track info!" -showtime -warning
            Update-Notifications -Level 'WARNING' -Message "Unable to get current playing Spotify track info!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout       
          } 
        }catch{
          write-ezlogs "An exception occurred attempting to start Spotify/Playback" -showtime -catcherror $_
          Update-Notifications -Level 'ERROR' -Message "An exception occurred attempting to start Spotify/Playback - See logs" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
        }         
      }    
    }else{
      write-ezlogs "Provided media is null or invalid! Cannot continue!" -showtime -warning -AlertUI
    }
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}  
    $Runspace_Args = @{
      'scriptblock' = $spotify_scriptblock
      'arguments' = $PSBoundParameters
      'thisApp' = $thisApp
      'synchash' = $synchash
      'runspace_name' = 'Spotify_Play_Media'
      'PSProviders' = 'Function','Registry','Environment','FileSystem','Variable'
      'RestrictedRunspace' = $RestrictedRunspace
      'ApartmentState' = 'STA'
      'function_list' = 'write-ezlogs',
      'Import-SerializedXML',
      'Export-SerializedXML',
      'Get-AllStartApps',
      'Update-MediaState',
      'Get-SpectrumAnalyzer',
      'Merge-Images',
      'Get-MediaProfile',
      'Get-SongInfo',
      'Update-PlayQueue',
      'Update-Notifications',
      'Update-MainWindow',
      'Start-Runspace',
      'Update-ChatView',
      'Update-MainPlayer',
      'Test-ValidPath',
      'Set-ApplicationAudioDevice',
      'Set-WindowState',
      'Set-SpotifyWebPlayerTimer'
    }
    Start-Runspace @Runspace_Args
    #Start-Runspace $spotify_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Spotify_Play_media" -thisApp $thisApp -ApartmentState STA
  }catch{
    write-ezlogs " An exception occurred in Start-SpotifyMedia" -showtime -catcherror $_
  }finally{
    if($Start_SpotifyMedia_Measure){
      $Start_SpotifyMedia_Measure.stop()
      write-ezlogs ">>>> Start-SpotifyMedia Measure" -PerfTimer $Start_SpotifyMedia_Measure
    } 
  }
}
#---------------------------------------------- 
#endregion Start-SpotifyMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-SpotifyMedia')