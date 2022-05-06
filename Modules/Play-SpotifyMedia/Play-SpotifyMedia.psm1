<#
    .Name
    Play-SpotifyMedia

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
#region Play-SpotifyMedia Function
#----------------------------------------------
function Play-SpotifyMedia{

  param (
    $Media,
    $synchash,
    $thisApp,
    $Script_Modules,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    [switch]$Show_notifications = $thisApp.config.Show_notifications
  )
  write-ezlogs ">>>> Selected Spotify Media to play $($media | out-string)" -showtime
  $mediatitle = $($Media.title)
  $encodedtitle = $media.encodedtitle
  $artist = $Media.Artist
  $url = $($Media.url)
  if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Making sure Tick Timer is Stopped" -showtime}
  $Synchash.Timer.stop()
  $Spotify_Path = $media.Spotify_Path
  if($synchash.vlc.IsPlaying){
    $synchash.vlc.stop()
  }
  if($Media){ 
    try{
      if($thisApp.config.Use_Spicetify -and !$thisApp.Config.Spicetify.is_paused){
        try{
          write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
          Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
          $thisApp.Config.Spicetify = ''
        }catch{
          write-ezlogs "[Start-SpotifyMedia] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
          $thisApp.Config.Spicetify = ''
          if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
            Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
          }             
        }
      }    
      if([System.IO.File]::Exists($thisApp.Config.Config_Path)){
        $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
        if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-SpotifyMedia] | Importing config file $($thisApp.Config.Config_Path)" -showtime}
      }  
      $existingitems = $null
      [array]$existingitems = $thisApp.config.Current_Playlist.values      
      if($thisApp.config.Current_Playlist){
        if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){
          if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] Current_playlist not orderedictionary $(($thisApp.config.Current_Playlist.GetType()).name) - converting"  -showtime -warning}
          $thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)
        } 
      }else{
        $thisApp.config.Current_Playlist = [System.Collections.Specialized.OrderedDictionary]::new()
      }         
      if($thisApp.config.Current_Playlist.values -notcontains $media.id){
        #$thisApp.config.Current_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
        $null = $thisApp.config.Current_Playlist.clear()
        $index = 0
        write-ezlogs "[Play-SpotifyMedia] | Adding $($media.id) to Play Queue" -showtime
        $null = $thisApp.config.Current_Playlist.add($index,$media.id) 
        foreach($id in $existingitems){
          $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisApp.config.Current_Playlist.add($index,$id)
        }    
      }   
      if(@($synchash.SpotifyTable.SelectedItems).count -gt 1){
        foreach($item in $synchash.SpotifyTable.SelectedItems | where {$_.encodedtitle -ne $encodedtitle}){
          if($item.id -and $thisApp.config.Current_Playlist.values -notcontains $item.id){ 
            write-ezlogs "[Play-SpotifyMedia] | Adding $($item.id) to Play Queue" -showtime
            $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisApp.config.Current_Playlist.add($index,$item.id)                 
          }
        }    
      } 
      $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "[Play-SpotifyMedia] An exception occurred updating current_playlist" -showtime -catcherror $_
    }
    
    Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command 
    $spotify_scriptblock = {
      try{
        Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -Force
        $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name
        write-ezlogs "[Play-SpotifyMedia] Getting available spotify devices for app $($thisApp.config.App_Name)" -showtime
        $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name    
        if($Media.type -eq 'Playlist'){
          $playback_url = $($Media.Playlist_URL)
        }else{
          $playback_url = $($media.Track_Url)
        }        
        #$Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
        if(!$devices){
          write-ezlogs "[Play-SpotifyMedia] No spotify devices available, finding spotify to launch" -showtime
          if(![System.IO.File]::Exists($Spotify_Path)){
            try{
              $installed_apps = Get-InstalledApplications
              $Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify'} | select -Unique
              $Spotify_Path = "$($Spotify_app.'Install Location')\\Spotify.exe"
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred in Get-installedApplications" -showtime -catcherror $_
            }
          }
          if([System.IO.File]::Exists($Spotify_Path)){          
            if(Get-process *Spotify* -ErrorAction SilentlyContinue){
              write-ezlogs "[Play-SpotifyMedia] >>>> Spotify is running" -showtime -color cyan             
            }else{
              write-ezlogs "[Play-SpotifyMedia] >>>> Spotify is installed, Starting minimized..." -showtime -color cyan
              #$Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url" -PassThru
              $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList '--minimized' -PassThru

            }
            #Set-WindowState -InputObject $Spotify_Process -State HIDE
            #wait for spotify to launch
            #start-sleep 1
          }else{
            write-ezlogs "[Play-SpotifyMedia] Unable to find Spotify installed, installing via chocolatey" -showtime -Warning
            choco upgrade spotify -confirm
            $installed_apps = Get-InstalledApplications
            $Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify'} | select -Unique    
            $Spotify_Install_Path = $Spotify_app.'Install Location'
            $Spotify_Path = "$($Spotify_app.'Install Location')\\Spotify.exe"       
            if([System.IO.File]::Exists($Spotify_Path)){
              write-ezlogs "Spotify is installed, Starting Spotify" -showtime
              if($playback_url){
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
              }else{
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList '--minimized' -PassThru
              }              
              #wait for spotify to launch   
            }else{
              write-ezlogs "[Play-SpotifyMedia] Spotify did not appear to install or unable to find, cannot continue" -showtime -warning
              return
            }
          }
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name  
          if($devices){
            write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime
          }
        }else{
          write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime
        }
        $start_Waittimer = 0
        if(!$Spotify_Process.MainWindowHandle){ 
          while(!$Spotify_Process.MainWindowHandle -and $start_waittimer -le 120){
            write-ezlogs "[Play-SpotifyMedia] ....Waiting for Spotify Process" -showtime
            $start_waittimer++
            $Spotify_Process = (Get-Process -Name 'Spotify')
            start-sleep -Milliseconds 500
          }
        }
        if($Spotify_Process){
          write-ezlogs "[Play-SpotifyMedia] | Found Spotify Process $($Spotify_Process.Id)" -showtime
          try{
            Set-WindowState -InputObject $Spotify_Process -State HIDE
          }catch{
            write-ezlogs "[Play-SpotifyMedia] An exception occurred in Set-WindowState" -showtime -catcherror $_
          }                    
        }elseif($start_waittimer -ge 120){
          write-ezlogs "[Play-SpotifyMedia] | Timed out waiting for Spotify process to start" -showtime -warning
          return
        }        
        if(!$devices){       
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name 
          while(!$devices -and $start_waittimer -le 120){
            $start_waittimer++
            write-ezlogs "[Play-SpotifyMedia] | Waiting for available Spotify devices" -showtime -warning
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
            start-sleep 1
          }          
          if($devices){
            if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime}
          }        
        }
        $current_track = $Null
        $waittimer = 0
        if($thisApp.config.Use_Spicetify){
          try{
            write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback with command http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime 
            Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing                                
          }catch{
            write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback using Invoke-RestMethod for url http://127.0.0.1:8974/PLAYURI?$($playback_url)" -showtime -catcherror $_
          }                                          
          while((!$thisApp.Config.Spicetify.is_playing -or $thisApp.Config.Spicetify.title -notmatch $media.Track_Name) -and $waittimer -lt 60){
            write-ezlogs "[Play-SpotifyMedia] Waiting for Spotify Playback to begin..." -showtime
            if($waittimer -eq 10){
              write-ezlogs "[Play-SpotifyMedia] Spotify should have started by now, lets restart Spotify" -showtime -warning
              $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
            }
            Invoke-RestMethod -Uri "http://127.0.0.1:8974/PLAYURI?$($playback_url)" -UseBasicParsing
            start-sleep 1
          }
        }else{
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
          if(!$current_track.is_playing){
            if($Media.type -eq 'Playlist'){
              try{
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of Playlist $($Media.Playlist_URL)" -showtime
                Start-Playback -ContextUri $Media.Playlist_URL -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for url $($Media.Playlist_URL)" -showtime -catcherror $_
              } 
            }elseif($Media.type -eq 'Track'){
              if($Media.Playlist_URL){
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track from playlist $($Media.Playlist)" -showtime          
                try{
                  Start-Playback -ContextUri $Media.Playlist_URL -OffsetUri $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback Playlist URL: $($Media.Playlist_URL) -- Track URL: $($media.Track_Url)" -showtime -catcherror $_
                }                        
              }else{
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track $($Media.Track_Name)" -showtime
                try{
                  Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for track url $($media.Track_Url)" -showtime -catcherror $_
                }             
            
              }
            } 
          }
          #start-sleep -Seconds 1  
          #Resume-Playback -DeviceId $devices.id -ApplicationName $thisApp.config.App_Name
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id        
          while(!$current_track.is_playing -and $waittimer -lt 60 -and !$current_track.item.name){
            try{         
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id 
              write-ezlogs "[Play-SpotifyMedia] Waiting for Spotify playback to start: $($current_track | out-string)" -showtime
              $synchash.current_track_playing = $current_track
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_
            }
            $waittimer++
            start-sleep 1
          }            
        } 
        if($waittimer -ge 60){
          write-ezlogs "[Play-SpotifyMedia] Timed out waiting for Spotify playback to begin!" -showtime -warning
          Update-Notifications -Level 'WARNING' -Message "Timed out waiting for Spotify playback to begin!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
          return        
        }        
        $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id        
        if($current_track -or $thisApp.config.Spicetify){
          if($thisApp.Config.Use_Spicetify){
            $Name = $thisApp.config.Spicetify.title
            $Artist = $thisApp.config.Spicetify.ARTIST             
          }else{
            $Name = $current_track.item.name
            $Artist = $current_track.item.artists.name
          }                
          <#          if(!$current_track.item.name){
              $Name = $thisApp.config.Spicetify.title
              }else{
              $Name = $current_track.item.name
              }
              if(!$current_track.item.artists.name){
              $Artist = $thisApp.config.Spicetify.ARTIST
              }else{
              $Artist = $current_track.item.artists.name
          }#>        
          $synchash.current_track_playing = $current_track
          if($encodedtitle){
            Add-Member -InputObject $thisApp.config -Name 'Spotify_Last_Played' -Value $encodedtitle -MemberType NoteProperty -Force
            Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($Media.id) -MemberType NoteProperty -Force            
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
            #$image = $($Media.thumbnail | select -First 1)
            if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Media Image found: $($image)" -showtime}
            $uri = new-object system.uri($image)
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
            }
            if([System.IO.File]::Exists($uri)){
              $image_Cache_path = $uri
            }elseif($uri){
              $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($Image | split-path -Leaf)-$($Media.id).png")
              if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Destination path for cached image: $image_Cache_path" -enablelogs -showtime}
              if(!([System.IO.File]::Exists($image_Cache_path))){
                write-ezlogs "[Play-SpotifyMedia] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime
                try{
                  (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                }catch{
                  $image_Cache_path = $Null
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred attempting to download $uri to path $image_Cache_path" -showtime -catcherror $_
                }
              }
            }else{
              write-ezlogs "[Play-SpotifyMedia] Cannot Download image $uri to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
              $image_Cache_path = $Null        
            }                                      
          }                                    
          if($thisApp.config.Show_notifications)
          {
            try{
              $spotify_startapp = Get-startapps *spotify
              if($spotify_startapp){
                $spotify_appid = $spotify_startapp.AppID
              }else{
                $spotify_appid = $Spotify_Path
              }
              if(!$image_Cache_path){
                $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Spotify.png"
              }else{
                $applogo = $image_Cache_path
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
              write-ezlogs "An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_
            }
          }
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
          if($thisApp.Config.Verbose_logging){
            if($thisApp.Config.Use_Spicetify){
              write-ezlogs "[Play-SpotifyMedia] Spicetify Current Track Playing: $($thisApp.config.Spicetify | out-string)" -showtime 
            }else{
              write-ezlogs "[Play-SpotifyMedia] Current Track Playing: $($current_track | out-string)" -showtime 
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
                write-ezlogs "[Play-SpotifyMedia] Waiting for Spicetify (Status: $status) - (Pause: $pause) - (Title: $($Name) - (Track Name: $($media.Track_Name)))" -showtime -warning  
                #$synchash.current_track = $current_track         
                # if($thisApp.Config.Verbose_Logging){write-ezlogs "Track '$($current_track.item.name)' is still playing with progress $($current_track.progress_ms)" -showtime} 
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_
              
              }
              start-sleep -Milliseconds 500
            }              
          }else{
            while((!$Name -or !$current_track.is_playing)){
              try{    
                write-ezlogs "[Play-SpotifyMedia] Waiting for Get-CurrentTrack status to indicate Spotify is playing and responding with playing title $name..." -showtime -warning
                $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                $Name = $current_track.item.name
                $Artist = $current_track.item.artists.name    
                $progress = $current_track.progress_ms 
                $thisApp.Config.Last_Played_title = $Name                    
                #$synchash.current_track = $current_track         
                # if($thisApp.Config.Verbose_Logging){write-ezlogs "Track '$($current_track.item.name)' is still playing with progress $($current_track.progress_ms)" -showtime} 
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_
              
              }
              start-sleep -Milliseconds 500
            }
          }             
          if($thisApp.Config.Use_Spicetify){
            $Name = $thisApp.config.Spicetify.title
            $Artist = $thisApp.config.Spicetify.ARTIST             
          }else{
            $Name = $current_track.item.name
            $progress = $current_track.progress_ms
            $Artist = $current_track.item.artists.name
          } 
          $title = "$($Name) - $($Artist)"        
          $thisApp.Config.Last_Played_title = $Name
          $synchash.Window.Dispatcher.invoke([action]{     
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
              if($image_Cache_path){
                $synchash.VLC_Grid_Row1.Height="200*"
                $synchash.MediaView_Image.Source = $image_Cache_path
              }else{
                $synchash.VLC_Grid_Row1.Height="*"
                $synchash.MediaView_Image.Source = $null
              }            
              $synchash.VideoView.Visibility="Hidden"
              $synchash.VLC_Grid_Row2.Height="15*"
              $synchash.VLC_Grid_Row0.Height="*"
              $synchash.MediaView_TextBlock.text = "$($Name) - $($Artist)"  
              #$synchash.update_status_timer.start()
              write-ezlogs "[Play-SpotifyMedia] >>>> Starting Tick Timer" -showtime
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
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred parsing Spicetify position timespan" -showtime -catcherror $_
                }                 
              }else{
                $Name = $current_track.item.name
                $Artist = $current_track.item.artists.name
                $status = $current_track.is_Playing
                $progress = $current_track.progress_ms
              } 
              $thisApp.Config.Last_Played_title = $name                          
              #$synchash.current_track = $current_track         
              if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] Track '$($Name)' (Should be Name: $($media.track_name)) is playing (Status: $status) - (Pause: $pause) - (State: $($thisApp.config.Spicetify.state)) with progress $($progress)" -showtime}
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_
              
            }
            start-sleep -Milliseconds 500
          }
          if($media.track_name -notmatch $Name){
            write-ezlogs "[Play-SpotifyMedia] A different track is now playing (og: $($media.track_name)) - (Now: $Name)" -showtime 
          }elseif(!$progress){
            write-ezlogs "[Play-SpotifyMedia] Progress is now null or 0: $progress" -showtime 
          }elseif($synchash.Spotify_Status -eq 'Stopped'){
            write-ezlogs "[Play-SpotifyMedia] Spotify_Status is now 'Stopped'" -showtime
          }
          $synchash.current_track_playing = $null
          $synchash.Spotify_Status = 'Stopped'
          $synchash.current_track = $null          
          write-ezlogs "[Play-SpotifyMedia] Playback of track '$($name)' finished" -showtime   
          <#          if($thisApp.config.Use_Spicetify){
              if($thisApp.config.Spicetify.is_Playing -or $thisApp.config.Spicetify.is_paused -eq $false){
              write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with command http://127.0.0.1:8974/PAUSE" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
              }        
              }else{
              write-ezlogs "[Start-SpotifyMedia] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id          
          }#>               
        }else{
          write-ezlogs "[Play-SpotifyMedia] Unable to get current playing Spotify track info!" -showtime -warning
          Update-Notifications -Level 'WARNING' -Message "Unable to get current playing Spotify track info!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
        } 
      }catch{
        write-ezlogs "An exception occurred attempting to start Spotify/Playback" -showtime -catcherror $_
        Update-Notifications -Level 'ERROR' -Message "An exception occurred attempting to start Spotify/Playback - See logs" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
      }   
    }    
  }else{
    write-ezlogs "[Play-SpotifyMedia] Provided media is null or invalid!" -showtime -warning
  }
 
  #Get-CurrentPlaybackInfo
  #Get-CurrentUserProfile
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $spotify_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Spotify Play media" -thisApp $thisApp -Script_Modules $Script_Modules
  
}
#---------------------------------------------- 
#endregion Play-SpotifyMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Play-SpotifyMedia')

