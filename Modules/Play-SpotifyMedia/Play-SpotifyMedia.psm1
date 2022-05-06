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
    $log = $thisApp.Config.SpotifyMedia_logfile,
    $Script_Modules,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    [switch]$Show_notifications = $thisApp.config.Show_notifications
  )
  
  #Reset UI
  $synchash.Window.Dispatcher.invoke([action]{  
      $syncHash.MainGrid_Background_Image_Source_transition.content = ''
      $syncHash.MainGrid_Background_Image_Source.Source = $null
      $syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')
      $synchash.MediaView_Image.Source = $Null
      $synchash.Chat_View_Button.IsEnabled = $false    
      $synchash.chat_column.Width = "*"
      $synchash.Chat_Icon.Kind="ChatRemove"
      $synchash.Chat_View_Button.Opacity=0.7
      $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
      $synchash.chat_WebView2.Visibility = 'Hidden'
      $synchash.chat_WebView2.stop()      
  },'Background')  
  $synchash.Media_Current_Title = ''
  #Make Sure Spotify status is stopped
  $synchash.Spotify_Status = 'Stopped'  
  if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Making sure Tick Timer is Stopped" -showtime -logfile:$log}
  $Synchash.Timer.stop()
  if($synchash.vlc.IsPlaying){
    $synchash.vlc.stop()
  }
  if($Media){ 
    try{
      write-ezlogs ">>>> Selected Spotify Media to play $($Media.title)" -showtime -logfile:$log
      $synchash.MediaView_Image.Source = $Null
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
          write-ezlogs "Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id) " -showtime -color cyan -logfile:$log
          $thisApp.Config.Spicetify = ''
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
      <#      if(@($synchash.SpotifyTable.SelectedItems).count -gt 1){
          foreach($item in $synchash.SpotifyTable.SelectedItems | where {$_.encodedtitle -ne $encodedtitle}){
          if($item.id -and $thisApp.config.Current_Playlist.values -notcontains $item.id){ 
          write-ezlogs "[Play-SpotifyMedia] | Adding $($item.id) to Play Queue" -showtime
          $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisApp.config.Current_Playlist.add($index,$item.id)                 
          }
          }    
      }#> 
      $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "[Play-SpotifyMedia] An exception occurred updating current_playlist" -showtime -catcherror $_ -logfile:$log
    }
    
    Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command 
    $spotify_scriptblock = {
      try{
        Import-module "$($thisApp.Config.Current_Folder)\Modules\Spotishell\Spotishell.psm1" -Force
        $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name
        write-ezlogs "[Play-SpotifyMedia] Getting available spotify devices for app $($thisApp.config.App_Name)" -showtime -logfile:$log
        $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name    
        if($Media.type -eq 'Playlist'){
          $playback_url = $($Media.Playlist_URL)
        }else{
          $playback_url = $($media.Track_Url)
        }        
        #$Spotify_Auth_app = Get-SpotifyApplication -Name $thisApp.config.App_Name
        if(!$devices){
          write-ezlogs "[Play-SpotifyMedia] No spotify devices available, finding spotify to launch" -showtime -logfile:$log
          if(![System.IO.File]::Exists($Spotify_Path)){
            try{
              $installed_apps = Get-InstalledApplications
              $Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify'} | select -Unique
              $Spotify_Path = "$($Spotify_app.'Install Location')\\Spotify.exe"
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred in Get-installedApplications" -showtime -catcherror $_ -logfile:$log
            }
          }
          if([System.IO.File]::Exists($Spotify_Path)){          
            if(Get-process *Spotify* -ErrorAction SilentlyContinue){
              write-ezlogs "[Play-SpotifyMedia] >>>> Spotify is running" -showtime -color cyan -logfile:$log             
            }else{
              write-ezlogs "[Play-SpotifyMedia] >>>> Spotify is installed, Starting minimized..." -showtime -color cyan -logfile:$log
              #$Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized --uri=$playback_url" -PassThru
              $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList '--minimized' -PassThru

            }
            #Set-WindowState -InputObject $Spotify_Process -State HIDE
            #wait for spotify to launch
            #start-sleep 1
          }else{
            write-ezlogs "[Play-SpotifyMedia] Unable to find Spotify installed, installing via chocolatey" -showtime -Warning -logfile:$log
            choco upgrade spotify -confirm
            $installed_apps = Get-InstalledApplications
            $Spotify_app = $installed_apps | where {$_.'Display Name' -eq 'Spotify'} | select -Unique    
            $Spotify_Install_Path = $Spotify_app.'Install Location'
            $Spotify_Path = "$($Spotify_app.'Install Location')\\Spotify.exe"       
            if([System.IO.File]::Exists($Spotify_Path)){
              write-ezlogs "Spotify is installed, Starting Spotify" -showtime -logfile:$log
              if($playback_url){
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList "--minimized" -PassThru
              }else{
                $Spotify_Process = Start $Spotify_Path -WindowStyle Minimized -ArgumentList '--minimized' -PassThru
              }              
              #wait for spotify to launch   
            }else{
              write-ezlogs "[Play-SpotifyMedia] Spotify did not appear to install or unable to find, cannot continue" -showtime -warning -logfile:$log
              return
            }
          }
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name  
          if($devices){
            write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime -logfile:$log
          }
        }else{
          write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime -logfile:$log
        }
        $start_Waittimer = 0
        if(!$Spotify_Process.MainWindowHandle){ 
          while(!$Spotify_Process.MainWindowHandle -and $start_waittimer -le 120){
            write-ezlogs "[Play-SpotifyMedia] ....Waiting for Spotify Process" -showtime -logfile:$log
            $start_waittimer++
            $Spotify_Process = (Get-Process -Name 'Spotify*')
            start-sleep -Milliseconds 500
          }
        }
        if($Spotify_Process){
          write-ezlogs "[Play-SpotifyMedia] | Found Spotify Process $($Spotify_Process.Id)" -showtime -logfile:$log
          try{
            Set-WindowState -InputObject $Spotify_Process -State HIDE
          }catch{
            write-ezlogs "[Play-SpotifyMedia] An exception occurred in Set-WindowState" -showtime -catcherror $_ -logfile:$log
          }                    
        }elseif($start_waittimer -ge 120){
          write-ezlogs "[Play-SpotifyMedia] | Timed out waiting for Spotify process to start" -showtime -warning -logfile:$log
          return
        }        
        if(!$devices){       
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name 
          while(!$devices -and $start_waittimer -le 120){
            $start_waittimer++
            write-ezlogs "[Play-SpotifyMedia] | Waiting for available Spotify devices" -showtime -warning -logfile:$log
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
            start-sleep 1
          }          
          if($devices){
            if($thisApp.Config.Verbose_logging){write-ezlogs "[Play-SpotifyMedia] | Found Spotify device $($devices | out-string)" -showtime -logfile:$log}
          }        
        }
        $current_track = $Null
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
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
          if(!$current_track.is_playing){
            if($Media.type -eq 'Playlist'){
              try{
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of Playlist $($Media.Playlist_URL)" -showtime -logfile:$log
                Start-Playback -ContextUri $Media.Playlist_URL -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for url $($Media.Playlist_URL)" -showtime -catcherror $_ -logfile:$log
              } 
            }elseif($Media.type -eq 'Track'){
              if($Media.Playlist_URL){
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track from playlist $($Media.Playlist)" -showtime -logfile:$log          
                try{
                  Start-Playback -ContextUri $Media.Playlist_URL -OffsetUri $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback Playlist URL: $($Media.Playlist_URL) -- Track URL: $($media.Track_Url)" -showtime -catcherror $_ -logfile:$log
                }                        
              }else{
                write-ezlogs "[Play-SpotifyMedia] >>>> Starting playback of track $($Media.Track_Name)" -showtime -logfile:$log
                try{
                  Start-Playback -TrackUris $media.Track_Url -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                }catch{
                  write-ezlogs "[Play-SpotifyMedia] An exception occurred in Start-Playback for track url $($media.Track_Url)" -showtime -catcherror $_ -logfile:$log
                }             
            
              }
            } 
          }
          #start-sleep -Seconds 1  
          #Resume-Playback -DeviceId $devices.id -ApplicationName $thisApp.config.App_Name
          $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id        
          while(!$current_track.is_playing -and $waittimer -lt 60 -and !$current_track.item.name){
            try{         
              $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id -logfile:$log 
              write-ezlogs "[Play-SpotifyMedia] Waiting for Spotify playback to start..." -showtime -logfile:$log
              $synchash.current_track_playing = $current_track
            }catch{
              write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
            }
            $waittimer++
            start-sleep 1
          }            
        } 
        if($waittimer -ge 60){
          write-ezlogs "[Play-SpotifyMedia] Timed out waiting for Spotify playback to begin!" -showtime -warning -logfile:$log
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
              $image_Cache_path = $image
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
                }catch{
                  $image_Cache_path = $Null
                  write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_ -logfile:$log
                }
              }           
            }else{
              write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning -logfile:$log
              $image_Cache_path = $Null        
            }                                      
          }
          if([System.IO.File]::Exists($image_Cache_path)){
            $synchash.Background_cached_image = $image_Cache_path
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
              write-ezlogs "An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_ -logfile:$log
            }
          }
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
            while((!$Name -or !$current_track.is_playing)){
              try{    
                write-ezlogs "[Play-SpotifyMedia] Waiting for Get-CurrentTrack status to indicate Spotify is playing and responding with playing title $name..." -showtime -warning -logfile:$log
                $current_track = Get-CurrentTrack -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
                $Name = $current_track.item.name
                $Artist = $current_track.item.artists.name    
                $progress = $current_track.progress_ms 
                $thisApp.Config.Last_Played_title = $Name                    
                #$synchash.current_track = $current_track         
                # if($thisApp.Config.Verbose_Logging){write-ezlogs "Track '$($current_track.item.name)' is still playing with progress $($current_track.progress_ms)" -showtime} 
              }catch{
                write-ezlogs "[Play-SpotifyMedia] An exception occurred getting the current track" -showtime -catcherror $_ -logfile:$log
              
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
          $synch
          $title = "$($Name) - $($Artist)"  
          $synchash.Media_Current_Title = "$($Name) - $($Artist)"                 
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
              $synchash.update_background_timer.start() 
              write-ezlogs "[Play-SpotifyMedia] >>>> Starting Tick Timer" -showtime -logfile:$log
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
          if($media.track_name -notmatch $Name){
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
  Start-Runspace $spotify_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Spotify Play media" -thisApp $thisApp -Script_Modules $Script_Modules
  
}
#---------------------------------------------- 
#endregion Play-SpotifyMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Play-SpotifyMedia')

