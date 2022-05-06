<#
    .Name
    Start-Media

    .Version 
    0.1.1

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
#region Start-Media Function
#----------------------------------------------
function Start-Media{
  [CmdletBinding()]
  param (
    $Media,
    $synchash,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    $thisApp,
    $all_playlists,
    [switch]$Show_notifications = $thisApp.Config.Show_notifications,
    $Script_Modules,
    [switch]$Verboselog
  )
  
  $synchash.Window.Dispatcher.invoke([action]{  
      $syncHash.MainGrid_Background_Image_Source_transition.content = ''
      $syncHash.MainGrid_Background_Image_Source.Source = $null
      $syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')
      $synchash.MediaView_Image.Source = $Null
  },'Background')
  $synchash.Media_Current_Title = '' 
  if($Media.SongInfo.title){
    $mediatitle = $($Media.SongInfo.title)
    $artist = $Media.SongInfo.Artist
  }else{
    $mediatitle = $($Media.title)
    $artist = $Media.Artist
  } 
  #$encodedtitle = $media.id 
  $url = $($Media.url)
  write-ezlogs ">>>> Selected Media to play $($mediatitle)" -showtime
  if($thisApp.Config.Verbose_logging){
    write-ezlogs " | Media to play: $($media | out-string)" -showtime
  }
  $thisapp.Config.streamlink = ''
  Add-Member -InputObject $thisApp.config -Name 'streamlink' -Value '' -MemberType NoteProperty -Force  
  if($synchash.VLC.state -eq 'Playing'){
    $synchash.VLC.stop()
  }
  $Synchash.Timer.stop()
  if($thisApp.config.Use_Spicetify -and (Get-Process -Name 'Spotify*') -and $synchash.Spotify_Status -ne 'Stopped'){
    try{
      #start-sleep 1
      write-ezlogs "[START-MEDIA] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan -logfile:$thisApp.Config.SpotifyMedia_logfile
      Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
      $thisApp.Config.Spicetify = ''
    }catch{
      write-ezlogs "[START-MEDIA] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile
      if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
        Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
      }  
      $thisApp.Config.Spicetify = ''   
      $synchash.Spotify_Status = 'Stopped'        
    }
  }elseif(($synchash.current_track_playing.is_playing -or $synchash.Spotify_Status -ne 'Stopped' ) -and (Get-Process -Name 'Spotify*')){
    try{
      $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
      if($devices){
        write-ezlogs "[START-MEDIA] Stopping Spotify playback with Suspend-Playback" -showtime -color cyan -logfile:$thisApp.Config.SpotifyMedia_logfile
        Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
      }else{
        write-ezlogs "[START-MEDIA] Couldnt get Spotify Device id, using nuclear option and force stopping Spotify process" -showtime -warning -logfile:$thisApp.Config.SpotifyMedia_logfile
        if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
          Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
        }            
      }           
    }catch{
      write-ezlogs "[START-MEDIA] An exception occurred executing Suspend-Playback" -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile
      if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
        Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
      }             
    }
    $synchash.Spotify_Status = 'Stopped'  
    $synchash.current_track_playing = $Null       
  }  
    
  if(!$Media -and $synchash.Media_URL.text){
    $media_link = $($synchash.Media_URL.text).trim()
  }elseif(-not [string]::IsNullOrEmpty($url)){
    $media_link = $($url).trim()
  }
  try{
    $existingitems = $null
    [array]$existingitems = $thisApp.config.Current_Playlist.values
    if($thisApp.config.Current_Playlist){
      if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){
        if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-Media] Current_playlist not orderedictionary $(($thisApp.config.Current_Playlist.GetType()).name) - converting"  -showtime -warning}
        $thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)
      } 
    }else{
      $thisApp.config.Current_Playlist = [System.Collections.Specialized.OrderedDictionary]::new()
    }           
    if($thisApp.config.Current_Playlist.values -notcontains $media.id){
      $null = $thisApp.config.Current_Playlist.clear()
      $index = 0
      write-ezlogs "[Start-Media] | Adding $($media.id) to Play Queue" -showtime
      $null = $thisApp.config.Current_Playlist.add($index,$media.id)  
      foreach($id in $existingitems){
        $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
        $index++
        $null = $thisApp.config.Current_Playlist.add($index,$id)
      }            
    }
    $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    #$synchash.update_status_timer.start()
    #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists       
    <#    if($media.type -eq 'YoutubePlaylist_item' -and @($synchash.YoutubeTable.SelectedItems).count -gt 1){
        foreach($item in $synchash.YoutubeTable.SelectedItems | where {$_.id -ne $media.id}){
        if($thisApp.config.Current_Playlist.values -notcontains $item.id){
        write-ezlogs "[Start-Media] | Adding Youtube selected item $($item.id) to Play Queue" -showtime
        $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
        $index++
        $null = $thisApp.config.Current_Playlist.add($index,$item.id) 
        }
        }   
        }elseif($media.id -and @($synchash.MediaTable.SelectedItems).count -gt 1){
        foreach($item in $synchash.MediaTable.SelectedItems | where {$_.id -ne $media.id}){
        if($thisApp.config.Current_Playlist.values -notcontains $item.id){
        write-ezlogs "[Start-Media] | Adding MediaTable selected item $($item.id) to Play Queue" -showtime
        $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
        $index++
        $null = $thisApp.config.Current_Playlist.add($index,$item.id)        
        }
        }                   
    }#>  
  }catch{
    write-ezlogs "[START-MEDIA] An exception occurred updating current_playlist" -showtime -catcherror $_
  }
  $vlc_scriptblock = {  
    $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl"
    $env:Path += ";$youtubedl_path"  
 
    if($media.webpage_url -match 'twitch' -and $Media.chat_url){
      $chat_url = $Media.chat_url
    }elseif($media.webpage_url -match 'twitch'){      
      $chat_url = "$($media.webpage_url)/chat"
    }else{
      $chat_url = $null
    }                     
    if($media.type -eq 'YoutubePlaylist_item'){
      $delay = $null
      if($media.webpage_url -match 'twitch.tv'){
        $twitch_channel = $((Get-Culture).textinfo.totitlecase(($media.webpage_url | split-path -leaf).tolower()))
        #$streamlink_fetchjson = streamlink $media.webpage_url --loglevel info --logfile $streamlink_log --json
        $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
        if($TwitchAPI){
          $thisApp.Config.streamlink = $TwitchAPI #$streamlink_fetchjson | convertfrom-json
        }                
        $streamlink_log = "$env:temp\EZT-MediaPlayer\streamlink.log"
        try{       
          if(!$TwitchAPI.type){
            write-ezlogs "[START_MEDIA] Twitch Channel $twitch_channel`: OFFLINE" -showtime -warning -logfile:$thisApp.Config.TwitchMedia_logfile
            Update-Notifications -Level 'WARNING' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
            Add-Member -InputObject $media -Name 'Live_Status' -Value 'Offline' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value '' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Stream_title' -Value "" -MemberType NoteProperty -Force          
            $synchash.Window.Dispatcher.invoke([action]{ 
                $Synchash.Timer.stop() 
                $synchash.Now_Playing_Label.content = ""                     
            }.GetNewClosure())     
            return
          }else{
            write-ezlogs "[START_MEDIA] Starting streamlink $($media.webpage_url)" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
            Add-Member -InputObject $Media -Name 'Live_Status' -Value $TwitchAPI.type -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value "- $($TwitchAPI.game_name)" -MemberType NoteProperty -Force  
            Add-Member -InputObject $media -Name 'Stream_title' -Value "$($TwitchAPI.title)" -MemberType NoteProperty -Force       
            $streamlink_wait_timer = 1
            $streamlinkblock = {
              if((Get-Process Streamlink*)){
                Get-Process Streamlink* | Stop-Process -Force
              }
              $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53828 --loglevel debug --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
              if($error){
                write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
              }
            }
            $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules            
            
          }
          $Playlist_profile = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $media.id}         
          foreach($track in $Playlist_profile.Playlist_tracks){
            if($track.id -eq $media.id){
              $track.title = $Media.Title
              $track.Status_msg = $Media.Status_msg
              $track.Live_Status = $Media.Live_Status
              Add-Member -InputObject $track -Name 'Stream_title' -Value "$($Media.Stream_title)" -MemberType NoteProperty -Force 
              if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] >>>> Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile}
              if([System.IO.FIle]::Exists($track.Playlist_File_Path)){
                if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] >>>> Saving updated playlist profile from track profile: $($track.Playlist_File_Path)" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile}
                $Playlist_profile | Export-Clixml $track.Playlist_File_Path -Force
              }elseif([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
                if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile}
                $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
              }         
            }
          }
          $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8                      
        }catch{
          write-ezlogs "[START_MEDIA] An exception occurred starting streamlink" -showtime -catcherror $_ -logfile:$thisApp.Config.TwitchMedia_logfile
        }        
        if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] Twitch API: $($thisApp.Config.streamlink | out-string)" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile}        
        #start-sleep 1
        while($streamlink_wait_timer -lt 60 -and !$thisApp.Config.streamlink -and !$(Get-Process *streamlink*)){
          $streamlink_wait_timer++
          write-ezlogs "[START_MEDIA] Waiting for streamlink process...." -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
          if($streamlink_wait_timer -eq 10){
            write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile
            $streamlinkblock = {
              if((Get-Process Streamlink*)){
                Get-Process Streamlink* | Stop-Process -Force
              }
              $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53828 --loglevel debug --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
              if($error){
                write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
              }
            }
            $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules 
          }
          start-sleep 1
        }
        if($streamlink_wait_timer -ge 60){
          write-ezlogs "[START_MEDIA] Timed out waiting for streamlink to start, falling back to yt-dlp" -showtime -warning -logfile:$thisApp.Config.TwitchMedia_logfile
          $yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all 
          [Uri]$vlcurl = $yt_dlp[0]  
          $media_link = $vlcurl
        }elseif($media.live_status -eq 'Offline'){
          write-ezlogs "[START_MEDIA] Stream offline -- cannot continue" -showtime -warning -logfile:$thisApp.Config.TwitchMedia_logfile
          return               
        }else{
          write-ezlogs "[START_MEDIA] >>>> Connecting to streamlink http://127.0.0.1:53828/" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
          [Uri]$vlcurl = 'http://127.0.0.1:53828/'
          $media_link = $vlcurl                  
        }              
      }elseif($media.webpage_url){ 
        <#        $libvlc_media = [LibVLCSharp.Shared.Media]::new([LibVLCSharp.Shared.LibVLC]::new(),[Uri]($media.webpage_url),[LibVLCSharp.Shared.FromType]::FromLocation,$null)
            $parse = $libvlc_media.Parse([LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork)
            while(!$parse.IsCompleted){
            start-sleep -Milliseconds 50
            }
            write-ezlogs "Parse results: $($parse | out-string)" -showtime        
        write-ezlogs "Libvlc Parsed Youtube URL: $($libvlc_media.SubItems[0].Mrl)" -showtime#>
        if($parse.IsCompleted){
          [Uri]$vlcurl = $libvlc_media.SubItems[0].Mrl 
          $media_link = $libvlc_media.SubItems[0].Mrl                     
        }else{
          write-ezlogs "[START_MEDIA] | Getting best quality video and audio links from yt_dlp for $($media.webpage_url)" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile 
          if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
            #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --sponsorblock-remove all            
            #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --sponsorblock-remove all
            $yt_dlp = yt-dlp -f b $media.webpage_url --no-check-certificate --skip-download --youtube-skip-dash-manifest --cookies-from-browser $thisApp.config.Youtube_Browser -j --dump-single-json | convertfrom-json  | select -Unique
            #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all        
          }else{
            #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --sponsorblock-remove all 
            #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --sponsorblock-remove all 
            $yt_dlp = yt-dlp -f b $media.webpage_url --no-check-certificate --skip-download --youtube-skip-dash-manifest -j --dump-single-json | convertfrom-json  | select -Unique
            #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all
          } 
          $best_quality = $yt_dlp.url | select -last 1
          if(Test-URL $best_quality){
            [Uri]$vlcurl = $best_quality 
            $media_link = $vlcurl
          }else{
            write-ezlogs "Unable to find right URL to use in $($yt_dlp | out-string) -- cannot continue" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
            return
            $media_link = $Null
            $vlcurl = $Null
          }            
        }         
        #[Uri]$video_url = $yt_dlp[0]
        
        # [Uri]$audio_url = $yt_dlp[1] 
      }else{
        $vlcurl = $media_link
      }   
      $duration = $media.duration_ms
      $title = $media.title  
      #write-ezlogs "[START_MEDIA] | YoutubePlaylist_item Title: $title" -showtime    
    }elseif(Test-URL $Media_link -and ($media_link -match 'youtube' -or $media_link -match 'yewtu.be')){
      $delay = $null
      $media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
      [Uri]$vlcurl = $media[0]
      $media_metadata = $media[1] | Convertfrom-json    
      $duration = $($([timespan]::Fromseconds($media_metadata.duration)).TotalMilliseconds)
      $title = $media_metadata.title
      write-ezlogs "[START_MEDIA] | Youtube URL Title: $title" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
    }elseif($media_link -match 'streaming.mediaservices.windows.net'){
      $delay = -2000000
      $media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
      if($verboselog){write-ezlogs "[START_MEDIA] | Media Metadata: $media" -showtime}     
      if(-not [string]::IsNullOrEmpty($media)){
        [Uri]$vlcurl = $media[0]
        $media_metadata = $media[1] | Convertfrom-json
        $duration = $media_metadata.duration
        $title = $media_metadata.title               
      }else{
        [Uri]$vlcurl = $($media_link)
        $title = $video.caption
        $duration = $media_metadata.duration
      }
    }elseif([System.IO.File]::Exists($Media_link)){
      $title = "$mediatitle - $Artist"
      if($media.duration){
        $media_Duration = $media.duration
      }elseif($media.SongInfo.duration){
        $media_Duration = $media.SongInfo.duration
      }
      if($media_Duration){
        try{
          [int]$length = $([System.TimeSpan]::Parse($media_Duration).TotalSeconds)
          $timespan = $([timespan]::FromSeconds($length))
          $duration = $timespan.TotalMilliseconds
        }catch{
          write-ezlogs "An execption occurred parsing duration of ($($media_Duration)) for $($title)" -showtime -catcherror $_
        }            
      }              
      [Uri]$vlcurl = $($media_link)      
      if($thisApp.Config.Verbose_Logging){write-ezlogs "[START_MEDIA] | Local Path Title: $title" -showtime}
      $delay = $null
    }elseif(Test-URL $Media_link){
      $delay = $null
      [Uri]$vlcurl = $($media_link)
      $duration = $null
      $title = $media.title
      write-ezlogs "[START_MEDIA] | URL Media Title: $title" -showtime
    }else{
      $delay = $null
      [Uri]$vlcurl = $($media_link)
      $duration = $null
      $title = $media.title
      write-ezlogs "[START_MEDIA] | Uknown media type Title: $title" -showtime
      Update-Notifications -Level 'ERROR' -Message "[START_MEDIA] Unknown media or path is not available: $vlcurl" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
      return      
    }    
    try{     
      Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"           
   
      $synchash.Window.Dispatcher.invoke([action]{   
          $a = 0
          $c = 0
          #Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"
          #write-ezlogs " | Media link $($media_link | out-string)" -showtime             
          $synchash.Media_URL.text = $media_link                           
          if($delay){
            $synchash.vlc.SetAudioDelay(-2000000)
          }              
          $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($duration)).TotalSeconds 
          [int]$a = $($duration / 1000);
          $synchash.Now_Playing_Label.content = "Now Playing - $title"          
          [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
          [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
          [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
          [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
          [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
          $total_time = "$hrs`:$mins`:$secs"      
          $synchash.Media_Length_Label.content = '0' + "/" + "$total_time"  
          $synchash.MediaPlayer_CurrentDuration = $total_time          
          if($video_url -and $audio_url){
            $libvlc_media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($video_url),[LibVLCSharp.Shared.FromType]::FromLocation,":input-slave=$($audio_url)")
          }elseif($vlcurl -or $media_link){
            if($media_link){
              if($media_link){
                write-ezlogs "[START_MEDIA] | Medialink is URL link $media_link" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
              }else{
                write-ezlogs "[START_MEDIA] | Medialink is local path link $media_link" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromPath
              }
              $libvlc_media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($media_link),$from_path,$null)             
            }else{
              if($vlcurl){
                write-ezlogs "[START_MEDIA] | vlcurl is URL link $vlcurl" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
              }else{
                write-ezlogs "[START_MEDIA] | vlcurl is local path link $vlcurl" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromPath
              }            
              $libvlc_media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($vlcurl),$from_path,$null)
            }
          } 
          if(!$thisApp.Config.Use_HardwareAcceleration){
            write-ezlogs "[START_MEDIA] | Disabling Hardware Acceleration" -showtime
            $libvlc_media.AddOption(":avcodec-hw=none")
          }  
          if($thisApp.Config.Verbose_Logging){write-ezlogs "[START_MEDIA] | VLC Media URL to play: $($libvlc_media.Mrl)" -showtime}                         
          $synchash.vlc.media = $libvlc_media                              
          $null = $synchash.VLC.Play()  

          Add-Member -InputObject $thisApp.config -Name 'Last_Played_title' -Value $title -MemberType NoteProperty -Force
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value $media.id -MemberType NoteProperty -Force              
          try{          
            if(Test-URL $chat_url){
              if($thisApp.config.Chat_View){
                $synchash.chat_WebView2.Visibility = 'Visible'
                #$synchash.Chat_View.Visibility = 'Visible'   
                $synchash.Chat_Icon.Kind="Chat"
                $synchash.Chat_View_Button.Opacity=1
                $synchash.Chat_View_Button.ToolTip="Chat View"   
                $synchash.chat_column.Width = "400"        
              } 
              $synchash.Chat_View_Button.IsEnabled = $true   
              if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
                write-ezlogs "[START_MEDIA] Navigating with CoreWebView2.Navigate: $($chat_url)" -enablelogs -Color cyan -showtime
                $syncHash.chat_WebView2.CoreWebView2.Navigate($chat_url)
              }
              else{
                write-ezlogs "[START_MEDIA] Navigating with Source: $($chat_url)" -enablelogs -Color cyan -showtime
                $syncHash.chat_WebView2.source="https://twitch.tv/$($chat_url)/chat"
              }         
            }else{
              $synchash.Chat_View_Button.IsEnabled = $false    
              $synchash.chat_column.Width = "*"
              $synchash.Chat_Icon.Kind="ChatRemove"
              $synchash.Chat_View_Button.Opacity=0.7
              $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
              $synchash.chat_WebView2.Visibility = 'Hidden'
              $synchash.chat_WebView2.stop()
            }                   
            [array]$media_queue = $syncHash.PlayQueue_TreeView.Items.Items.tag.Media
            foreach($id in $media_queue.id){
              if($thisApp.config.Current_Playlist.values -notcontains $id){
                $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
                $index++
                $null = $thisApp.config.Current_Playlist.add($index,$id)               
              }
            }           
            write-ezlogs "[START_MEDIA] >>>> Saving config file to $($thisApp.Config.Config_Path)" -showtime -color cyan
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8  
            $synchash.update_status_timer.start()    
            $synchash.VideoView.add_MouseEnter({

                $synchash.VideoView_Flyout.IsOpen = $true
                write-ezlogs "Video Mouse Enter: $($this | out-string)"

            })                                     
          }catch{
            write-ezlogs "[START_MEDIA] An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_
          }                                                            
      },"Normal")
     
      $play_timeout = 0
      $streamlink_wait_timer = 1
      while(!$synchash.vlc.IsPlaying -and $play_timeout -lt 60){
        $play_timeout++
        $streamlink_wait_timer++
        write-ezlogs "[START_MEDIA] | Waiting for VLC to begin playing..." -showtime
        if($media.webpage_url -match 'twitch.tv' -and $streamlink_wait_timer -and $streamlink_wait_timer -eq 11){
          write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile
          $streamlinkblock = {              
            if((Get-Process Streamlink*)){
              Get-Process Streamlink* | Stop-Process -Force
            }        
            $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53828 --loglevel debug --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
            if($error){
              write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
            }
          }
          $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
          Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules 
        }
        start-sleep 1
      }

      if(-not [string]::IsNullOrEmpty($Media.cover_art)){
        $image = $($Media.Cover_art | select -First 1)
      }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){
        $image = $($Media.thumbnail | select -First 1)
      }else{
        $image = $null
      } 
      $image_Cache_path = $Null
      if($image)
      {
        if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] Media Image found: $($image)" -showtime}
       
        if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
          if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
          $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
        }
        $encodeduri = $Null  
        $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
        $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
        $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
        if([System.IO.File]::Exists($image_Cache_path)){
          $image_Cache_path = $image
        }elseif($image){         
          if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] | Destination path for cached image: $image_Cache_path" -showtime}
          if(!([System.IO.File]::Exists($image_Cache_path))){
            try{
              if([System.IO.File]::Exists($image)){
                if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] | Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime}
                $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
              }else{
                $uri = new-object system.uri($image)
                if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime}
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
                if($thisApp.Config.Verbose_logging){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs}
                $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                $encoder.Save($save_stream)
                $save_stream.Dispose()       
              }              
            }catch{
              $image_Cache_path = $Null
              write-ezlogs "[START_MEDIA] An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
            }
          }           
        }else{
          write-ezlogs "[START_MEDIA] Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
          $image_Cache_path = $Null        
        }                                    
      } 
      if([System.IO.File]::Exists($image_Cache_path)){
        if($thisApp.Config.Verbose_logging){write-ezlogs "Setting background image to $image_Cache_path" -enablelogs -showtime}
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
      if($synchash.vlc.IsPlaying){       
        $synchash.Media_Current_Title = "$title"
        $synchash.Window.Dispatcher.invoke([action]{  
            $synchash.update_background_timer.start()      
            #$Synchash.Timer.start() 
            <#            if($thisApp.Config.streamlink.title){
                $synchash.Now_Playing_Label.content = "Now Playing - $($thisApp.Config.streamlink.User_Name): $($thisApp.Config.streamlink.title)"
            }#>            
        },'Normal')             
      }elseif($play_timeout -ge 60){
        write-ezlogs "[START_MEDIA] Timedout waiting for VLC media to begin playing!" -showtime -warning
        Update-Notifications -Level 'WARNING' -Message "[START_MEDIA] Timedout waiting for VLC media to begin playing!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
        return
      } 
      if($thisApp.config.Show_notifications)
      {
        try{
          $startapp = Get-startapps "*$($thisApp.Config.App_name)*"
          if($startapp){
            $appid = $startapp.AppID | select -last 1
          }elseif(Get-startapps VLC*){
            $startapp = Get-startapps VLC*
            $appid = $startapp.AppID | select -last 1
          }else{
            $startapp = Get-startapps '*Windows Media Player'
            $appid = $startapp.AppID | select -last 1
          } 
          if($image_Cache_path){
            $applogo = $image_Cache_path 
          }else{
            $applogo = "$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.png"
          }
          if($media.webpage_url -match 'twitch.tv'){
            $source = 'Twitch Stream'
            if(!$image_Cache_path){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Twitch48.png"
            }
          }elseif($media.type -eq 'YoutubePlaylist_item'){
            $source = 'Youtube Media'
            if(!$image_Cache_path){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Youtube.png"
            }
          }else{
            $source = 'Local Media'
          } 
          $Message = "Media : $($thisApp.config.Last_Played_title)`nPlay Duration : $($synchash.MediaPlayer_CurrentDuration)`nSource : $source"
          if($psversiontable.PSVersion.Major -gt 5){
            Import-module Burnttoast -Force
          }
          New-BurntToastNotification -AppID $appid -Text $Message -AppLogo $applogo         
        }catch{
          write-ezlogs "[START_MEDIA] An exception occurred attempting to generate the notification balloon - image: $uri" -showtime -catcherror $_
        }
      } 
      if($error){
        Write-ezlogs "[-----ALL ERRORS------]" -linesbefore 1
        $e_index = 0
        foreach ($e in $Error)
        {
          $e_index++
          write-ezlogs "[ERROR $e_index Message] =========================================================================`n$($e.exception.message)`n$($e.InvocationInfo.positionmessage)`n$($e.ScriptStackTrace)`n`n" -showtime
        }
      }   
    }catch{
      write-ezlogs "[START_MEDIA] An exception occurred attempting to play media $($libvlc_media | out-string)" -showtime -catcherror $_
    } 
    if($error){
      write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
    }   
  }.GetNewClosure()  
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Vlc Play media" -thisApp $thisApp -Script_Modules $Script_Modules
}
#---------------------------------------------- 
#endregion Start-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Media')
