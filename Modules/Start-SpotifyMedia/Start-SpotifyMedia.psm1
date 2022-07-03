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
    - Module designed for EZT-MediaPlayer

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

  param (
    $Media,
    $synchash,
    $thisApp,
    $log = $thisApp.Config.SpotifyMedia_logfile,
    $Script_Modules,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    [switch]$use_WebPlayer = $thisapp.config.Spotify_WebPlayer,
    [switch]$Show_notifications = $thisApp.config.Show_notifications
  )
  
  #Reset UI
  if(!(Get-command -Module Spotishell)){
    Import-Module "$($thisApp.Config.Current_folder)\Modules\Spotishell\Spotishell.psm1"
  }
  $existingjob_check = $Jobs | where {$_.powershell.runspace.name -eq 'Spotify_Play_media' -or $_.Name -eq 'Spotify_Play_media'}
  if($existingjob_check){
    try{
      if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false){
        write-ezlogs "Existing Runspace 'Spotify_Play_media' found as busy, stopping before starting new" -showtime -warning -logfile:$log 
        start-sleep -Milliseconds 100
        write-ezlogs "Streams: $($existingjob_check.powershell.Streams.Information  | out-string)" -showtime -Warning
        $existingjob_check.powershell.stop()      
        $existingjob_check.powershell.Runspace.Dispose()
        $existingjob_check.powershell.dispose()        
        $jobs.remove($existingjob_check)            
        #$null = $existingjob_check.powershell.EndInvoke($existingjob_check.Runspace)
      }
    }catch{
      write-ezlogs " An exception occurred stopping existing runspace 'Spotify_Play_media'" -showtime -catcherror $_
    }
  } 
  $existingjob_check = $Jobs | where {$_.powershell.runspace.name -eq 'Vlc_Play_media' -or $_.Name -eq 'Vlc_Play_media'}
  if($existingjob_check){
    try{
      if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false){
        write-ezlogs "Existing Runspace 'Vlc_Play_media' found as busy, stopping before starting new" -showtime -warning -logfile:$log 
        start-sleep -Milliseconds 100
        write-ezlogs "Streams: $($existingjob_check.powershell.Streams.Information  | out-string)" -showtime -Warning
        $existingjob_check.powershell.stop()      
        $existingjob_check.powershell.Runspace.Dispose()
        $existingjob_check.powershell.dispose()        
        $jobs.remove($existingjob_check)            
        #$null = $existingjob_check.powershell.EndInvoke($existingjob_check.Runspace)
      }
    }catch{
      write-ezlogs " An exception occurred stopping existing runspace 'Vlc_Play_media'" -showtime -catcherror $_
    }
  }    
  $synchash.Start_media = $null
  $synchash.Last_Played = $Null
  $synchash.Start_media_timer.stop()      
  $synchash.Youtube_WebPlayer_URL = $null
  $synchash.Youtube_WebPlayer_title = $null   
  $synchash.Spotify_WebPlayer_URL = $null
  $synchash.Spotify_WebPlayer_title = $null
  $synchash.Spotify_WebPlayer_State = $Null
  $synchash.Spotify_WebPlayer_timer.start()
  $synchash.WebPlayer_Playing_timer.stop() 
  $synchash.Current_playing_media = $Null
  $synchash.Window.Dispatcher.invoke([action]{  
      $syncHash.MainGrid_Background_Image_Source_transition.content = ''
      $syncHash.MainGrid_Background_Image_Source.Source = $null
      #$syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')
      $synchash.MediaView_Image.Source = $Null
      $synchash.Chat_View_Button.IsEnabled = $false    
      $synchash.chat_column.Width = "*"
      $synchash.Chat_Icon.Kind="ChatRemove"
      $synchash.Chat_View_Button.Opacity=0.7
      $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
      $synchash.chat_WebView2.Visibility = 'Hidden'
      if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
        $synchash.chat_WebView2.stop()
      }     
  },'Background')  
  $synchash.Media_Current_Title = ''
  #Make Sure Spotify status is stopped
  $synchash.Spotify_Status = 'Stopped'  
  Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value '' -MemberType NoteProperty -Force
  if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Making sure Tick Timer is Stopped" -showtime -logfile:$log}
  $Synchash.Timer.stop()
  if($synchash.vlc.IsPlaying){
    $synchash.vlc.stop()
  }
  if($Media){ 
    try{
      write-ezlogs ">>>> Selected Spotify Media to play $($Media.title)" -showtime -logfile:$log
      if($thisApp.Config.Verbose_logging){write-ezlogs "Media: $($Media | out-string)" -showtime -logfile:$log}
      if(@($Media).count -gt 1){
        write-ezlogs "More than 1 media object was provided. Selecting first only to continue" -showtime -warning -logfile:$log 
        $media = $Media | Select -first 1
      }
      $mediatitle = $($Media.title)
      $encodedtitle = $media.encodedtitle
      $artist = $Media.Artist
      $url = $($Media.url) 
      $Spotify_Path = $media.Spotify_Path         
      if($thisApp.config.Use_Spicetify -and !$thisApp.Config.Spicetify.is_paused){
        try{
          write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan -logfile:$log
          Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
          $thisApp.Config.Spicetify = ''
        }catch{
          write-ezlogs "[Start-SpotifyMedia] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_ -logfile:$log
          $thisApp.Config.Spicetify = ''
          if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
            Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
          }             
        }
      }elseif($synchash.current_track_playing.is_playing){
        try{
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
          #write-ezlogs "Spotify is currently playing $($synchash.current_track_playing.item.name) - starting new track $($media.Track_Url)" -showtime -color cyan -logfile:$log
          write-ezlogs "Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id) " -showtime -color cyan -logfile:$log
          $thisApp.Config.Spicetify = ''
          $synchash.current_track_playing = $Null
          #Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
          Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
        }catch{
          write-ezlogs "An exception occurred executing Suspend-Playback for device $($devices.id)" -showtime -catcherror $_ -logfile:$log
          $thisApp.Config.Spicetify = ''
          if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
            Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
          }             
        }      
      }    
      if([System.IO.File]::Exists($thisApp.Config.Config_Path)){
        $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
        if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-SpotifyMedia] | Importing config file $($thisApp.Config.Config_Path)" -showtime -logfile:$log}
      }  
      $existingitems = $null
      [array]$existingitems = $thisApp.config.Current_Playlist.values      
      if($thisApp.config.Current_Playlist){
        if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){
          if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] Current_playlist not orderedictionary $(($thisApp.config.Current_Playlist.GetType()).name) - converting"  -showtime -warning -logfile:$log}
          $thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)
        } 
      }else{
        $thisApp.config.Current_Playlist = [System.Collections.Specialized.OrderedDictionary]::new()
      }         
      if($thisApp.config.Current_Playlist.values -notcontains $media.id){
        #$thisApp.config.Current_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
        $null = $thisApp.config.Current_Playlist.clear()
        $index = 0
        write-ezlogs "[Play-SpotifyMedia] | Adding $($media.id) to Play Queue" -showtime -logfile:$log
        $null = $thisApp.config.Current_Playlist.add($index,$media.id) 
        foreach($id in $existingitems){
          $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisApp.config.Current_Playlist.add($index,$id)
        }    
      }   
      $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "[Play-SpotifyMedia] An exception occurred updating current_playlist" -showtime -catcherror $_ -logfile:$log
    } 
    Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp   
    # Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -Refresh_Spotify_Playlists
    $spotify_scriptblock = {
      try{
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
            if($Media.Track_ID){
              $Spotify_ID= $Media.Track_ID
            }elseif($media.id){
              $Spotify_ID = $Media.id
            }           
            $playback_url = "https://open.spotify.com/track/$($Spotify_ID)"
          }else{
            $Spotify_ID = $media.Track_Url         
            $playback_url = $($media.Track_Url)
          }        
        }
        if($use_WebPlayer){
          write-ezlogs "Using Spotify Web Player with playback url $playback_url" -showtime -logfile:$log
          if($syncHash.WebView2 -eq $null -or $synchash.Webview2.CoreWebView2 -eq $null){
            $synchash.Initialize_WebPlayer_timer.start()
          }
          $Name = $media.title            
          $Artist = $media.Artist
          $title = "$($Name) - $($Artist)"      
          if($Spotify_ID -and $playback_url){
            $synchash.Spotify_WebPlayer_URL = [Uri]$playback_url          
          }else{
            write-ezlogs "Unable to get Spotify_ID and Playback_URL, cannot continue! Media $($media | out-string)" -showtime -warning -logfile:$log 
            Update-Notifications -Level 'WARNING' -Message "Unable to get Spotify_ID and Playback_URL, cannot continue! See logs" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
            $synchash.Window.Dispatcher.invoke([action]{  
                Stop-Media -synchash $synchash -thisApp $thisApp
            })            
            return
          }                                                             
          $synchash.Window.Dispatcher.invoke([action]{     
              if($media.duration_ms){
                $synchash.MediaPlayer_CurrentDuration = $media.duration_ms 
                $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($media.duration_ms)).TotalSeconds 
                [int]$hrs = $($([timespan]::FromMilliseconds($media.duration_ms)).Hours)
                [int]$mins = $($([timespan]::FromMilliseconds($media.duration_ms)).Minutes)
                [int]$secs = $($([timespan]::FromMilliseconds($media.duration_ms)).Seconds)   
              }  
              $total_time = "$mins`:$secs"                
              $synchash.Media_Length_Label.content = '0' + "/" + "$total_time"  
              if($playback_url){
                $synchash.txtUrl.text = $playback_url
              }             
              $synchash.Media_Current_Title = $title 
              $synchash.Spotify_WebPlayer_title = $title      
              $synchash.Spotify_WebPlayer_URL = [Uri]$playback_url   
              $synchash.Last_Played = ($Media.id)
              $synchash.Current_playing_media = $media
              Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($Media.id) -MemberType NoteProperty -Force
              $thisApp.Config.Last_Played_title = $Name
              $synchash.Spotify_WebPlayer_timer.start()                                  
              #$synchash.Spotify_Status = 'Playing'
              $synchash.Now_Playing_Label.content = "Now Playing - $title"    
              $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content                          
          })          
          #$synchash.Spotify_WebPlayer_timer.start()
        }else{    
          $start_Waittimer = 0   
          Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -Force
          #$current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name         
          if(![System.IO.File]::Exists($Spotify_Path)){
            try{
              if($psversiontable.PSVersion.Major -gt 5){
                write-ezlogs "[Start-SpotifyMedia] Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell to find appx packages" -showtime
                Import-module Appx -usewindowspowershell
              }              
              #$installed_apps = Get-InstalledApplications -GetAppx -Force
              $Spotify_app = (Get-appxpackage 'Spotify*')
              #$Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify' -or $_.'Display Name' -eq 'Spotify Music'} | select -Unique
              if($Spotify_app){
                $Spotify_Path = "$($Spotify_app.InstallLocation)\\Spotify.exe"
              }
            }catch{
              write-ezlogs "[Start-SpotifyMedia] An exception occurred in Get-installedApplications" -showtime -catcherror $_ -logfile:$log
            }
          }elseif([System.IO.File]::Exists($Spotify_Path)){          
            if(Get-process *Spotify* -ErrorAction SilentlyContinue){
              write-ezlogs "[Start-SpotifyMedia] >>>> Spotify is running" -showtime -color cyan -logfile:$log  
              $Spotify_Process = (Get-Process -Name 'Spotify*')                           
            }else{   
              write-ezlogs "[Start-SpotifyMedia] >>>> Spotify is installed but not running, Starting minimized" -showtime -color cyan -logfile:$log
              $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru                           
              #$Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url" -PassThru
              #$Spotify_Process = Start $media.Track_Url -WindowStyle Minimized -ArgumentList '--minimized' -PassThru
            }
            Set-WindowState -InputObject $Spotify_Process -State HIDE
            #wait for spotify to launch
            #start-sleep 1
          }else{
            write-ezlogs "Unable to find Spotify installed" -showtime -Warning -logfile:$log
            if($thisApp.Config.Install_Spotify){
              write-ezlogs ">>>> Installing Spotify via chocolatey" -showtime -logfile:$log      
              choco upgrade spotify -confirm -force --acceptlicense   
              $installed_apps = Get-InstalledApplications -verboselog
              $Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify'} | select -Unique    
              $Spotify_Install_Path = $Spotify_app.'Install Location'
              $Spotify_Path = "$($Spotify_app.'Install Location')\\Spotify.exe"       
              if([System.IO.File]::Exists($Spotify_Path)){
                write-ezlogs "Spotify is installed, Starting Spotify" -showtime -logfile:$log
                if($playback_url){
                  #$Spotify_Process = Start $media.Track_Url -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
                  $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url" -PassThru
                }else{
                  #$Spotify_Process = Start $media.Track_Url -WindowStyle Minimized -ArgumentList '--minimized' -PassThru
                  $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
                }              
                #wait for spotify to launch   
              }else{
                write-ezlogs "[Play-SpotifyMedia] Spotify did not appear to install or unable to find, cannot continue" -showtime -warning -logfile:$log
                return
              }     
            }else{
              Update-Notifications -Level 'WARNING' -Message "Spotify is not installed! You must manually install Spotify or enable the 'Install Spotify' option under Settings" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
              write-ezlogs "Auto installation of Spotify is not enabled, skipping install. Spotify must be manually installed for Spotify features to function" -showtime -warning
            }
          }          
          write-ezlogs "[Start-SpotifyMedia] Getting available spotify devices for app $($thisApp.config.App_Name)" -showtime -logfile:$log
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name           
          #$Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
          if(!$devices){
            write-ezlogs "[Start-SpotifyMedia] No spotify devices available from api, waiting for spotify to start" -showtime -logfile:$log
            if(!$Spotify_Process.MainWindowHandle){ 
              while(!$Spotify_Process.MainWindowHandle -and $start_waittimer -le 120){
                write-ezlogs "[Start-SpotifyMedia] ....Waiting for Spotify Process" -showtime -logfile:$log
                $start_waittimer++
                $Spotify_Process = (Get-Process -Name 'Spotify*')
                start-sleep -Milliseconds 100
              }
            }                    
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name 
            $device_Wait = 1
            while(!$devices -and $start_waittimer -le 120){
              $start_waittimer++
              write-ezlogs "| Waiting for available Spotify devices" -showtime -warning -logfile:$log
              $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
              if($device_Wait -and $device_Wait -eq 11){
                write-ezlogs "| Attempting to restart Spotify client as it should have started by now" -showtime -warning -logfile:$log
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru                
              }   
              Set-WindowState -InputObject (Get-process 'Spotify*') -State HIDE          
              #start-sleep -Milliseconds 500
            }          
            if($devices){
              if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime -logfile:$log}   
              if(!$thisApp.config.Use_Spicetify){
                $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id  
              }       
            }                 
          }else{
            if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime -logfile:$log}
            $Spotify_Process = (Get-Process -Name 'Spotify*')            
          }
          if($Spotify_Process.id){
            write-ezlogs "[Start-SpotifyMedia] | Found Spotify Process $($Spotify_Process.Id)" -showtime -logfile:$log
            try{
              write-ezlogs "[Start-SpotifyMedia] | Hiding Spotify Process window" -showtime -logfile:$log
              Set-WindowState -InputObject $Spotify_Process -State HIDE
            }catch{
              write-ezlogs "[Start-SpotifyMedia] An exception occurred in Set-WindowState" -showtime -catcherror $_ -logfile:$log
            }                    
          }elseif($start_waittimer -ge 120){
            write-ezlogs "[Start-SpotifyMedia] | Timed out waiting for Spotify process to start" -showtime -warning -logfile:$log
            return
          }              
          #$current_track = $Null 
          $waittimer = 0      
          if($thisApp.config.Use_Spicetify){
            try{
              write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback with command http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime -logfile:$log 
              Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing                                
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback using Invoke-RestMethod for url http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime -catcherror $_ -logfile:$log
            }                                          
            while((!$thisApp.Config.Spicetify.is_playing -or $thisApp.Config.Spicetify.title -notmatch $media.Track_Name) -and $waittimer -lt 60){
              write-ezlogs "[Play-SpotifyMedia] Waiting for Spotify Playback to begin..." -showtime -logfile:$log
              if($waittimer -eq 10){
                write-ezlogs "[Play-SpotifyMedia] Spotify should have started by now, lets restart Spotify" -showtime -warning -logfile:$log
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
              }
              Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing
              start-sleep 1
            }
          }else{
            if($Media.type -eq 'Playlist'){
              try{
                if($($Media.Playlist_URL)){
                  $url = $($Media.Playlist_URL)
                }elseif($($Media.uri)){
                  $url = $($Media.uri)
                }
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of Playlist $($url)" -showtime -logfile:$log
                Start-Playback -ContextUri $url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for url $($url)" -showtime -catcherror $_ -logfile:$log
              } 
            }elseif($Media.type -eq 'Track'){
              if($Media.Playlist_URL){
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track $($Media.Track_Name) from playlist $($Media.Playlist) -- URL $($media.Track_Url) - device $($devices.id)" -showtime -logfile:$log          
                try{
                  #Start-Playback -ContextUri $Media.Playlist_URL -OffsetUri $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                     
                  #$Spotify_Process = Start $media.Track_Url -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
                  $start_playback = Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback Playlist URL: $($Media.Playlist_URL) -- Track URL: $($media.Track_Url)" -showtime -catcherror $_ -logfile:$log
                }                        
              }else{
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track $($Media.Track_Name)" -showtime -logfile:$log
                try{
                  Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                  #$Spotify_Process = Start $media.Track_Url -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for track url $($media.Track_Url)" -showtime -catcherror $_ -logfile:$log
                }                         
              }
            }          
            <#            $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                if(!$current_track.is_playing){
 
                }elseif($current_track.is_playing -and $current_track.item.uri -ne $media.Track_Url){
                write-ezlogs "[Play-SpotifyMedia] Spotify is playing $($current_track.item.name) - URI: $($current_track.item.uri) but should be $($media.Track_name) - URI: $($media.Track_Url)" -showtime -warning -logfile:$log
                write-ezlogs "[Play-SpotifyMedia] Executing Start-Playback for trackuri $($media.Track_Url)" -showtime -warning -logfile:$log
                Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }else{
                write-ezlogs "[Play-SpotifyMedia] >>>> Spotify is currently playing track $($current_track.item.name)" -showtime -logfile:$log
            }#>
            #Set-WindowState -InputObject (Get-process 'Spotify*') -State HIDE
            #start-sleep -Seconds 1  
            #Resume-Playback -DeviceId $devices.id -ApplicationName $thisApp.config.App_Name
            $waittimer = 0
            $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id        
            while(!$current_track.is_playing -and $waittimer -lt 60 -and !$current_track.item.name){
              try{  
                write-ezlogs "[Play-SpotifyMedia] Waiting for Spotify playback to start..." -showtime -logfile:$log       
                write-ezlogs "Current Track: $($current_track | out-string)" -showtime -logfile:$log 
                $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id              
                $synchash.current_track_playing = $current_track
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
              }
              $waittimer++
              start-sleep 1
            }            
          } 
          if($thisApp.Config.Verbose_Logging){write-ezlogs "Now Spotify Track item: $($current_track.item | out-string)" -showtime -logfile:$log }  
          if($waittimer -ge 60){
            write-ezlogs "[Play-SpotifyMedia] Timed out waiting for Spotify playback to begin!" -showtime -warning -logfile:$log
            Update-Notifications -Level 'WARNING' -Message "Timed out waiting for Spotify playback to begin!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
            return        
          }
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id 
        }
        if($encodedtitle){
          Add-Member -InputObject $thisApp.config -Name 'Spotify_Last_Played' -Value $encodedtitle -MemberType NoteProperty -Force
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($Media.id) -MemberType NoteProperty -Force 
          $synchash.Last_Played = ($Media.id)         
          $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
        }
        if(-not [string]::IsNullOrEmpty($Media.Album_images)){
          $image = $($Media.Album_images | select -First 1)
        }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){
          $image = $($Media.thumbnail | select -First 1)
        }else{
          $image = $null
        } 
        $image_Cache_path = $Null
        if($image)
        {
          if($thisApp.Config.Verbose_logging){write-ezlogs "Media Image found: $($image)" -showtime -logfile:$log}       
          if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
            if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime -logfile:$log}
            $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
          }
          $encodeduri = $Null  
          $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
          $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
          $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
          if([System.IO.File]::Exists($image_Cache_path)){
            $cached_image = $image_Cache_path
            if($thisApp.Config.Verbose_logging){write-ezlogs "| Found cached image: $cached_image" -showtime -logfile:$log}
          }elseif($image){         
            if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime -logfile:$log}
            if(!([System.IO.File]::Exists($image_Cache_path))){
              try{
                if([System.IO.File]::Exists($image)){
                  if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime -logfile:$log}
                  $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
                }else{
                  $uri = new-object system.uri($image)
                  if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime -logfile:$log}
                  (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                }             
                if([System.IO.File]::Exists($image_Cache_path)){
                  $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                  $image = new-object System.Windows.Media.Imaging.BitmapImage
                  $image.BeginInit();
                  $image.CacheOption = "OnLoad"
                  #$image.CreateOptions = "DelayCreation"
                  #$image.DecodePixelHeight = 229;
                  $image.DecodePixelWidth = 500;
                  $image.StreamSource = $stream_image
                  $image.EndInit();        
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze();
                  if($thisApp.Config.Verbose_logging){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs -logfile:$log}
                  $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                  $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                  $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                  $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                  $encoder.Save($save_stream)
                  $save_stream.Dispose()       
                }  
                $cached_image = $image_Cache_path            
              }catch{
                $cached_image = $Null
                write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_ -logfile:$log
              }
            }           
          }else{
            write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning -logfile:$log
            $cached_image = $Null        
          }                                      
        }
        if([System.IO.File]::Exists($cached_image)){
          $synchash.Background_cached_image = $cached_image
          <#        Add-Type -AssemblyName System.Drawing
              write-ezlogs "Getting primary accent color for image: $image_Cache_path" -showtime
              $BitMap = [System.Drawing.Bitmap]::FromFile($image_Cache_path)

              # A hashtable to keep track of the colors we've encountered
              $table = @{}
              foreach($h in 1..$BitMap.Height){
              foreach($w in 1..$BitMap.Width) {
              # Assign a value to the current Color key
              $table[$BitMap.GetPixel($w - 1,$h - 1)] = $true
              }
              }
              $bitmap.Dispose()
              # The hashtable keys is out palette
              $palette = $table.Keys | sort-object -Property "Count" -Descending | Select -last 1
          $synchash.background_accent_color = $palette.Name#>
        }else{
          $synchash.background_accent_color = $Null
          $synchash.Background_cached_image = $null
        }                                              
        if($thisApp.config.Show_notifications)
        {
          try{
            $spotify_startapp = Get-startapps *spotify
            if($spotify_startapp){
              $spotify_appid = $spotify_startapp.AppID
            }elseif(Get-startapps "*$($thisApp.Config.App_name)*"){
              $spotify_startapp = Get-startapps "*$($thisApp.Config.App_name)*"
              $spotify_appid = $spotify_startapp
            }else{
              $spotify_appid = $Spotify_Path
            }              
            if(!$cached_image){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Spotify.png"
            }else{
              $applogo = $cached_image
            }
            [int]$hrs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Hours)
            [int]$mins = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Minutes)
            [int]$secs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Seconds)     
            $total_time = "$mins`:$secs"            
            $Message = "Song : $($Name) - $($Artist)`nPlay Duration : $total_time`nSource : Spotify"
            if($psversiontable.PSVersion.Major -gt 5){
              Import-module Burnttoast
            }              
            New-BurntToastNotification -AppID $spotify_appid -Text $Message -AppLogo $applogo

          }catch{
            write-ezlogs "An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_ -logfile:$log
          }
        }                              
        if($current_track -or $thisApp.config.Spicetify){
          if($thisApp.Config.Use_Spicetify){
            $Name = $thisApp.config.Spicetify.title
            $Artist = $thisApp.config.Spicetify.ARTIST             
          }elseif($use_WebPlayer){
            $Name = $media.title            
            $Artist = $media.Artist
          }else{
            $Name = $current_track.item.name
            $Artist = $current_track.item.artists.name         
          }                       
          $synchash.current_track_playing = $current_track
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
          if($thisApp.Config.Verbose_logging){
            if($thisApp.Config.Use_Spicetify){
              write-ezlogs "[Play-SpotifyMedia] Spicetify Current Track Playing: $($thisApp.config.Spicetify | out-string)" -showtime -logfile:$log
            }else{
              write-ezlogs "[Play-SpotifyMedia] Current Track Playing: $($current_track | out-string)" -showtime -logfile:$log
            }         
          }              
          if($thisApp.Config.Use_Spicetify){
            while(($thisApp.config.Spicetify.is_paused -eq $true -or $thisApp.config.Spicetify.is_playing -eq $false -or $thisApp.Config.Spicetify.title -notmatch $media.Track_Name)){
              try{                   
                $Name = $thisApp.config.Spicetify.title
                $Artist = $thisApp.config.Spicetify.ARTIST  
                $status = $thisApp.config.Spicetify.is_Playing
                $pause = $thisapp.config.Spicetify.is_paused 
                $thisApp.Config.Last_Played_title = $Name    
                write-ezlogs "[Play-SpotifyMedia] Waiting for Spicetify (Status: $status) - (Pause: $pause) - (Title: $($Name) - (Track Name: $($media.Track_Name)))" -showtime -warning -logfile:$log  
                #$synchash.current_track = $current_track         
                # if($thisApp.Config.Verbose_Logging){write-ezlogs "Track '$($current_track.item.name)' is still playing with progress $($current_track.progress_ms)" -showtime} 
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
              
              }
              start-sleep -Milliseconds 500
            }              
          }else{
            $current_Track_wait = 0
            while((!$Name -or !$current_track.is_playing -and ($current_Track_wait -lt 60))){
              try{    
                write-ezlogs "[Play-SpotifyMedia] Waiting for Get-CurrentTrack status to indicate Spotify is playing and responding with playing title $name..." -showtime -warning -logfile:$log
                $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                write-ezlogs "Current Track: $($Current_Track | out-string)"
                $Name = $current_track.item.name
                write-ezlogs "Name: $($Name)" -logfile:$log
                $Artist = $current_track.item.artists.name    
                write-ezlogs "Artist: $($Artist)" -logfile:$log
                $progress = $current_track.progress_ms 
                write-ezlogs "Progress: $($progress)" -logfile:$log
                $thisApp.Config.Last_Played_title = $Name      
                write-ezlogs "Is_Playing: $($current_track.is_playing)" -logfile:$log      
                Start-sleep -Milliseconds 500
                $current_Track_wait++        
                #$synchash.current_track = $current_track         
                # if($thisApp.Config.Verbose_Logging){write-ezlogs "Track '$($current_track.item.name)' is still playing with progress $($current_track.progress_ms)" -showtime} 
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
              
              }
              start-sleep -Milliseconds 500
            }
            if($current_Track_wait -ge 60){
              write-ezlogs "Timed out waiting for status of current playing Spotify media!" -showtime -warning
              Update-Notifications -Level 'WARNING' -Message "Timed out waiting to get status of current playing Spotify media!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
              return
              
            }
          }             
          $synchash.Window.Dispatcher.invoke([action]{    
              if($thisApp.Config.Use_Spicetify){
                $Name = $thisApp.config.Spicetify.title
                $Artist = $thisApp.config.Spicetify.ARTIST             
              }else{
                $Name = $current_track.item.name
                $progress = $current_track.progress_ms
                $Artist = $current_track.item.artists.name
              } 
              $title = "$($Name) - $($Artist)"  
              $synchash.Media_Current_Title = "$($Name) - $($Artist)"                 
              $thisApp.Config.Last_Played_title = $Name           
              $synchash.Current_playing_media = $media
              $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($current_track.item.duration_ms)).TotalSeconds      
              [int]$hrs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Hours)
              [int]$mins = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Minutes)
              [int]$secs = $($([timespan]::FromMilliseconds($current_track.item.duration_ms)).Seconds)     
              $total_time = "$mins`:$secs"
              $synchash.Media_Length_Label.content = '0' + "/" + "$total_time"  
              if($Current_track.item.external_urls.spotify){
                $synchash.txtUrl.text = $Current_track.item.external_urls.spotify
                #write-ezlogs "[START-SPOTIFY] Navigating with CoreWebView2.Navigate: $($initial_url)" -enablelogs -Color cyan -showtime
                #$syncHash.WebView2.CoreWebView2.Navigate($Current_track.item.external_urls.spotify)
              }                       
              $synchash.current_track_playing = $current_track
              $thisApp.Config.Last_Played_title = $Name
              $synchash.Spotify_Status = 'Playing'
              $synchash.Now_Playing_Label.content = "Now Playing - $title"
              $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
              write-ezlogs "[Start-SpotifyMedia] >>>> Saving config file to $($thisApp.Config.Config_Path)" -showtime -color cyan -logfile:$log
              $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8  
              write-ezlogs "[Start-SpotifyMedia] >>>> Refreshing play queue" -showtime -logfile:$log
              $synchash.update_status_timer.start()    
              $synchash.update_background_timer.start() 
              write-ezlogs "[Start-SpotifyMedia] >>>> Starting Tick Timer" -showtime -logfile:$log
              $Synchash.Timer.start()                               
          })
          # }   
          $Name = $media.track_name 
          $progress = 1
          start-sleep 1   
          $synchash.Spotify_Status = 'Playing'                                                   
          #while($current_track.is_playing -and $thisApp.Config.Spicetify.is_paused -eq $false -and $thisApp.Config.Spicetify.is_playing -and ($thisApp.Config.Spotify_Status -ne 'Stopped' -or $thisApp.Config.Spotify_Status -ne $null) ){
          while(($synchash.Spotify_Status -ne 'Stopped') -and ($progress -ne $null) -and $media.track_name -match $Name -and  ($progress -ne 0)){
            try{
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name  -DeviceId $devices.id            
              $synchash.current_track_playing = $current_track
              if($thisApp.Config.Use_Spicetify){
                $Name = $thisApp.config.Spicetify.title
                $status = $thisApp.config.Spicetify.is_Playing
                $pause = $thisapp.config.Spicetify.is_paused
                $Artist = $thisApp.config.Spicetify.ARTIST
                try{
                  if($thisApp.config.Spicetify.POSITION -ne $Null){
                    $progress = [timespan]::Parse($thisApp.config.Spicetify.POSITION).TotalMilliseconds
                  }else{
                    $progress = $($([timespan]::FromMilliseconds(0)).TotalMilliseconds)
                  }
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred parsing Spicetify position timespan" -showtime -catcherror $_ -logfile:$log
                }                 
              }else{
                $Name = $current_track.item.name
                $Artist = $current_track.item.artists.name
                $status = $current_track.is_Playing
                $progress = $current_track.progress_ms
              } 
              $thisApp.Config.Last_Played_title = $name                          
              #$synchash.current_track = $current_track         
              if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] Track '$($Name)' (Should be Name: $($media.track_name)) is playing (Status: $status) - (Pause: $pause) - (State: $($thisApp.config.Spicetify.state)) with progress $($progress)" -showtime -logfile:$log}
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
              
            }
            start-sleep -Milliseconds 250
          }
          if($media.track_name -notmatch [regex]::Escape($Name)){
            write-ezlogs "[Play-SpotifyMedia] A different track is now playing (og: $($media.track_name)) - (Now: $Name)" -showtime -logfile:$log
          }elseif(!$progress){
            write-ezlogs "[Play-SpotifyMedia] Progress is now null or 0: $progress" -showtime -logfile:$log
          }elseif($synchash.Spotify_Status -eq 'Stopped'){
            write-ezlogs "[Play-SpotifyMedia] Spotify_Status is now 'Stopped'" -showtime -logfile:$log
          }
          $synchash.current_track_playing = $null
          $synchash.Spotify_Status = 'Stopped'
          $synchash.current_track = $null          
          write-ezlogs "[Play-SpotifyMedia] Playback of track '$($name)' finished" -showtime -logfile:$log   
          <#          if($thisApp.config.Use_Spicetify){
              if($thisApp.config.Spicetify.is_Playing -or $thisApp.config.Spicetify.is_paused -eq $false){
              write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with command http://127.0.0.1:8974/PAUSE" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
              }        
              }else{
              write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id          
          }#>               
        }elseif($use_WebPlayer){
          $synchash.Window.Dispatcher.invoke([action]{     
              $synchash.update_background_timer.start()                                
          })          
        }else{
          write-ezlogs "[Play-SpotifyMedia] Unable to get current playing Spotify track info!" -showtime -warning -logfile:$log
          Update-Notifications -Level 'WARNING' -Message "Unable to get current playing Spotify track info!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout       
        } 
      }catch{
        write-ezlogs "An exception occurred attempting to start Spotify/Playback" -showtime -catcherror $_ -logfile:$log
        Update-Notifications -Level 'ERROR' -Message "An exception occurred attempting to start Spotify/Playback - See logs" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
      }  
      if($error){
        write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
      }       
    }    
  }else{
    write-ezlogs "[Play-SpotifyMedia] Provided media is null or invalid!" -showtime -warning -logfile:$log
  }
 
  #Get-CurrentPlaybackInfo
  #Get-CurrentUserProfile
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $spotify_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Spotify_Play_media" -thisApp $thisApp -Script_Modules $Script_Modules
  
}
#---------------------------------------------- 
#endregion Start-SpotifyMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-SpotifyMedia')

