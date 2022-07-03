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
    update yt-dlp: yt-dlp -U
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
    [switch]$use_WebPlayer = $thisapp.config.Youtube_WebPlayer,
    $all_playlists,
    [switch]$Show_notifications = $thisApp.Config.Show_notifications,
    $Script_Modules,
    [switch]$Verboselog = $true
  ) 
  try{  
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
    $synchash.Youtube_WebPlayer_URL = $null
    $synchash.Youtube_WebPlayer_title = $null
    $synchash.Spotify_WebPlayer_State = $Null
    $synchash.Start_media = $null
    $synchash.Start_media_timer.stop()  
    $synchash.Youtube_WebPlayer_timer.start()
    $synchash.WebPlayer_Playing_timer.stop()       
    $synchash.Spotify_WebPlayer_URL = $null
    $synchash.Spotify_WebPlayer_title = $null  
    $synchash.Media_Current_Title = '' 
    $synchash.Current_playing_media = $Null
    if($Media.SongInfo.title){
      $mediatitle = $($Media.SongInfo.title)
      $artist = $Media.SongInfo.Artist
    }else{
      $mediatitle = $($Media.title)
      $artist = $Media.Artist
    } 
    $streamlink_log = "$env:temp\EZT-MediaPlayer\streamlink.log"
    #$encodedtitle = $media.id 
    $url = $($Media.url)
    if(!$url -and (Test-URL $Media)){
      $url = $Media
      write-ezlogs ">>>> Selected Media to play is a url $($url)" -showtime
    }else{
      write-ezlogs ">>>> Selected Media to play $($mediatitle)" -showtime
    }
    #write-ezlogs " | Media to play: $($media.songinfo | out-string)" -showtime
    if($thisApp.Config.Verbose_logging){
      write-ezlogs " | Media to play: $($media | out-string)" -showtime
    }
    $thisapp.Config.streamlink = ''
    $synchash.streamlink = ''
    #Add-Member -InputObject $thisApp.config -Name 'streamlink' -Value '' -MemberType NoteProperty -Force   
    if((Get-Process Streamlink*)){
      Get-Process Streamlink* | Stop-Process -Force
    } 
    if($synchash.VLC.state -eq 'Playing'){
      $synchash.VLC.stop()
    }
    $Synchash.Timer.stop()
  }catch{
    write-ezlogs "An exception occurred when starting Start-Media" -showtime -catcherror $_
  }  
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
    $media_link = $($url)
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
    Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
    # $synchash.update_status_timer.start()
    # Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists       
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

    if($media.webpage_url -match 'twitch' -and $Media.chat_url){
      $chat_url = $Media.chat_url
    }elseif($media.webpage_url -match 'twitch'){      
      $chat_url = "$($media.webpage_url)/chat"
    }else{
      $chat_url = $null
    }
  }catch{
    write-ezlogs "[START-MEDIA] An exception occurred updating current_playlist" -showtime -catcherror $_
  }
  $vlc_scriptblock = {  
    $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl"
    $env:Path += ";$youtubedl_path"   
    write-ezlogs ">>>> Checking media type $($media.type)" -showtime
    if($thisapp.config.Youtube_WebPlayer -and ($media.type -eq 'YoutubePlaylist_item' -or $media.Group -eq 'Youtube' -or $media.Source -eq 'YoutubePlaylist_item') -and ($media.webpage_url -match 'youtube.com' -or $media.webpage_url -match 'yewtu.be' -or $media.url -match 'youtube.com' -or $media -match 'yewtu.be' -or $media -match 'youtube.com')){
      write-ezlogs " | Using Youtube Web Player" -showtime
      if($syncHash.WebView2 -eq $null -or $synchash.Webview2.CoreWebView2 -eq $null){
        $synchash.Initialize_WebPlayer_timer.start()
        while(!$syncHash.WebView2){
          start-sleep -Milliseconds 100
        }
      }
      $delay = $null     
      if($media.title){
        $title = $media.title
      }else{
        $title = $media
      }
      if($media.webpage_url){
        $media_url = $media.webpage_url
      }elseif($media.url){
        $media_url = $media.url
      }
      write-ezlogs "[Youtube_WebPlayer] | Youtube URL Title: $title - URL: $media_url" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
      if(-not [string]::IsNullOrEmpty($media.Duration_ms)){
        $duration = $($([timespan]::FromMilliseconds(($media.Duration_ms)).TotalMilliseconds))
      }elseif( -not [string]::IsNullOrEmpty($media.duration)){
        $duration = $($([timespan]::FromMilliseconds(($media.Duration)).TotalMilliseconds))
      } 
      if($duration){
        $a = $duration
        #[int]$c = $($([timespan]::FromMilliseconds($a)).TotalMinutes)     
        [int]$hrs = $($([timespan]::FromMilliseconds($a)).Hours)
        #write-ezlogs "hrs..$($hrs)"
        [int]$mins = $($([timespan]::FromMilliseconds($a)).Minutes)
        #write-ezlogs "mins..$($mins)"
        [int]$secs = $($([timespan]::FromMilliseconds($a)).Seconds)
        #write-ezlogs "secs..$($secs)"
        #[int]$milsecs = $($([timespan]::FromMilliseconds($a)).Milliseconds)
        $total_time = "$hrs`:$mins`:$secs"      
        $synchash.MediaPlayer_TotalDuration = $total_time
      }  
      #write-ezlogs "totaldur..$($synchash.MediaPlayer_TotalDuration)"     
      $synchash.Youtube_WebPlayer_title = $title
      #$synchash.MediaPlayer_CurrentDuration = $duration
     
      if($media_url -match "v="){
        if($media_url -match '&t='){
          $media_url = ($($media_url) -split('&t='))[0].trim()
        }      
        $youtube_id = ($($media_url) -split('v='))[1].trim()
        if($thisApp.Config.Use_invidious){
          [Uri]$vlcurl = "https://yewtu.be/embed/$youtube_id`?&autoplay=1"
        }else{
          [Uri]$vlcurl = "https://www.youtube.com/embed/$youtube_id`?&autoplay=1"
        }
        if($timeindex){
          [Uri]$vlcurl = "$vlcurl" + $timeindex
        }
      }elseif($media_url -match 'list='){
        $youtube_id = ($($media_url) -split('list='))[1].trim()
        if($thisApp.Config.Use_invidious){            
          [Uri]$vlcurl = "https://yewtu.be/embed/videoseries?list=$youtube_id`&autoplay=1"            
        }else{
          [Uri]$vlcurl = "https://www.youtube.com/embed/videoseries?list=$youtube_id`&autoplay=1"
        }                   
      }      
      $synchash.Youtube_WebPlayer_URL = [Uri]$vlcurl
      $synchash.Youtube_WebPlayer_timer.start()
    }elseif($media.type -eq 'YoutubePlaylist_item' -or $media.Source -eq 'YoutubePlaylist_item' -or ($media_link -match 'youtube.com' -and (Test-URL $media_link)) -or ($media_link -match 'twitch.tv' -and (Test-URL $media_link))){
      $delay = $null
      if($media.webpage_url -match 'twitch.tv'){
        write-ezlogs " | Media is type Twitch Stream" -showtime
        $twitch_channel = $((Get-Culture).textinfo.totitlecase(($media.webpage_url | split-path -leaf).tolower()))
        #$streamlink_fetchjson = streamlink $media.webpage_url --loglevel info --logfile $streamlink_log --json
        $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
        if($TwitchAPI){
          $synchash.streamlink = $TwitchAPI #$streamlink_fetchjson | convertfrom-json
        }                       
        try{       
          if(!$TwitchAPI.type){
            write-ezlogs "[START_MEDIA] Twitch Channel $twitch_channel`: OFFLINE" -showtime -warning -logfile:$thisApp.Config.TwitchMedia_logfile
            Update-Notifications -Level 'WARNING' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
            Add-Member -InputObject $media -Name 'Live_Status' -Value 'Offline' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value '' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Stream_title' -Value "" -MemberType NoteProperty -Force 
            Add-Member -InputObject $media -Name 'thumbnail' -Value "" -MemberType NoteProperty -Force         
            $synchash.Window.Dispatcher.invoke([action]{ 
                $Synchash.Timer.stop() 
                $synchash.Now_Playing_Label.content = "" 
                $Synchash.Main_Tool_Icon.Text = $synchash.Window.Title                    
            }.GetNewClosure())     
            return
          }else{
            write-ezlogs "[START_MEDIA] Starting streamlink $($media.webpage_url)" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
            if($TwitchAPI.thumbnail_url){
              $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
            }else{
              $thumbnail = ''
            }            
            Add-Member -InputObject $Media -Name 'Live_Status' -Value $TwitchAPI.type -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value "- $($TwitchAPI.game_name)" -MemberType NoteProperty -Force  
            Add-Member -InputObject $media -Name 'Stream_title' -Value "$($TwitchAPI.title)" -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'thumbnail' -Value $thumbnail -MemberType NoteProperty -Force       
            $streamlink_wait_timer = 1
            $streamlinkblock = {
              try{
                if((Get-Process Streamlink*)){
                  Get-Process Streamlink* | Stop-Process -Force
                  start-sleep -Milliseconds 500
                }              
                $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53888 --loglevel debug --logfile $streamlink_log --retry-streams 1 --retry-max 10 --twitch-disable-ads --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data --twitch-low-latency
              }catch{
                write-ezlogs "An exception occurred executing streamlink for Media url $($media.webpage_url)" -showtime -catcherror $_
              }            
              if($error){
                write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
              }
            }
            $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules            
            
          }
          $Playlist_profile = $synchash.all_playlists | where {$_.Playlist_tracks.id -eq $media.id}         
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
        if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] Twitch API: $($synchash.streamlink | out-string)" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile}        
        #start-sleep 1
        while($streamlink_wait_timer -lt 60 -and !$synchash.streamlink -and !$(Get-Process *streamlink*)){
          $streamlink_wait_timer++
          write-ezlogs "[START_MEDIA] Waiting for streamlink process...." -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
          if($streamlink_wait_timer -eq 10){
            write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile
            $streamlinkblock = {
              if((Get-Process Streamlink*)){
                Get-Process Streamlink* | Stop-Process -Force
              }
              $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53888 --loglevel debug --logfile $streamlink_log --retry-streams 1 --retry-max 10 --twitch-disable-ads --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data --twitch-low-latency
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
          write-ezlogs "[START_MEDIA] >>>> Connecting to streamlink http://127.0.0.1:53888/" -showtime -logfile:$thisApp.Config.TwitchMedia_logfile
          [Uri]$vlcurl = 'http://127.0.0.1:53888/'
          $media_link = $vlcurl                  
        }              
      }elseif($media.webpage_url -match 'youtube' -or $media_link -match 'youtube' -or $media.url -match 'youtube'){ 
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
          try{
            if($media.webpage_url){
              $media_link = $media.webpage_url
            }           
            if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
              #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --sponsorblock-remove all            
              #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --sponsorblock-remove all
              $yt_dlp = yt-dlp -f b $media_link --no-check-certificate --skip-download --youtube-skip-dash-manifest --cookies-from-browser $thisApp.config.Youtube_Browser -j --dump-single-json | convertfrom-json  | select -Unique
              #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all        
            }else{
              #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --sponsorblock-remove all 
              #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --sponsorblock-remove all 
              $yt_dlp = yt-dlp -f b $media_link --no-check-certificate --skip-download --youtube-skip-dash-manifest -j --dump-single-json | convertfrom-json  | select -Unique
              #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all
            }
          }catch{
            write-ezlogs "An exception occurred in yt-dlp when processing URL $($media_link)" -showtime -catcherror $_
          }
          if(!$yt_dlp){
            write-ezlogs "Unable to get playable url from yt-dlp, trying streamlink..." -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
            $streamlink_wait_timer = 1
            $streamlinkblock = {
              try{
                if((Get-Process Streamlink*)){
                  Get-Process Streamlink* | Stop-Process -Force
                  start-sleep -Milliseconds 500
                }              
                $streamlink = streamlink $media_link "best,720p,480p" --player-external-http --player-external-http-port 53888 --loglevel debug --logfile $streamlink_log --retry-streams 1 --retry-max 10 --twitch-disable-ads --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data 
                write-ezlogs "Streamlink: $($streamlink | out-string)" -showtime
              }catch{
                write-ezlogs "An exception occurred executing streamlink for Media url $($media_link)" -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
              }            
              if($error){
                write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
              }
            }.GetNewClosure()
            $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules   
            while($streamlink_wait_timer -lt 20 -and !$(Get-Process *streamlink*)){
              $streamlink_wait_timer++
              write-ezlogs "[START_MEDIA] Waiting for streamlink process...." -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
              if($streamlink_wait_timer -eq 10){
                write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now" -showtime -color cyan -logfile:$thisApp.Config.YoutubeMedia_logfile
                $streamlinkblock = {
                  if((Get-Process Streamlink*)){
                    Get-Process Streamlink* | Stop-Process -Force
                  }
                  $streamlink = streamlink $media_link "best,720p,480p" --player-external-http --player-external-http-port 53888 --loglevel debug --logfile $streamlink_log --retry-streams 2
                  if($error){
                    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
                  }
                }
                $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
                Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules 
              }
              start-sleep 1
            }
            if($streamlink_wait_timer -ge 20){
              write-ezlogs "[START_MEDIA] Timed out waiting for streamlink to start: $media_link, cannot continue!" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile 
              Update-Notifications -Level 'WARNING' -Message "Timed out waiting for streamlink to start: $media_link, cannot continue!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold   
              return     
            }else{
              write-ezlogs "[START_MEDIA] >>>> Connecting to streamlink http://127.0.0.1:53888/" -showtime -logfile:$thisApp.Config.YoutubeMedia_logfile
              [Uri]$vlcurl = 'http://127.0.0.1:53888/'
              $media_link = $vlcurl                  
            }                                             
          }else{
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
      write-ezlogs " | Media is type Youtube URL" -showtime
      $delay = $null
      $media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
      [Uri]$vlcurl = $media[0]
      $media_metadata = $media[1] | Convertfrom-json 
      if($media_metadata.duration){
        $duration = $($([timespan]::Fromseconds($media_metadata.duration)).TotalMilliseconds)     
      }     
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
      write-ezlogs " | Media is type Local path" -showtime
      $title = "$mediatitle - $Artist"
      if($media.duration_ms){
        $duration = $media.duration_ms
      }elseif($media.SongInfo.duration_ms){
        $duration = $media.SongInfo.duration_ms
      }else{
        try{
          $taginfo = [taglib.file]::create($media.url) 
        }catch{
          write-ezlogs "An exception occurred getting taginfo for $($media.url)" -showtime -catcherror $_
        }
        if($taginfo.properties.duration){
          $duration = [timespan]::Parse($taginfo.properties.duration).TotalMilliseconds
        }else{
          $duration = 0
        }
      }              
      [Uri]$vlcurl = $($media_link)      
      if($thisApp.Config.Verbose_Logging){write-ezlogs "[START_MEDIA] | Local Path Title: $title" -showtime}
      $delay = $null
    }elseif(Test-URL $Media_link){
      write-ezlogs " | Media is type URL" -showtime
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
      write-ezlogs "[START_MEDIA] | Importing Module Get-HelperFunctions" -showtime
      Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"          
      $synchash.Window.Dispatcher.invoke([action]{   
      
          if(!$synchash.Youtube_WebPlayer_URL){
            $a = 0
            $c = 0
            #Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"
            write-ezlogs " | Media link $($media_link | out-string)" -showtime             
            $synchash.Media_URL.text = $media_link                           
            if($delay){
              $synchash.vlc.SetAudioDelay(-2000000)
            }              
            if(-not [string]::IsNullOrEmpty($duration)){
              try{
                write-ezlogs " | Duration: $($duration)" -showtime
                if($duration -match '\:'){
                  $total_Seconds = [timespan]::Parse($duration).TotalSeconds
                  [int]$hrs = $($([timespan]::Parse($duration)).Hours)
                  [int]$mins = $($([timespan]::Parse($duration)).Minutes)
                  [int]$secs = $($([timespan]::Parse($duration)).Seconds)
                }else{
                  $total_Seconds = $([timespan]::FromMilliseconds($duration)).TotalSeconds
                  [int]$a = $($duration / 1000);
                  [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
                  [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
                  [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
                  [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
                  [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
                }
                $synchash.MediaPlayer_TotalDuration = $total_seconds 
                #$synchash.Now_Playing_Label.content = "Now Playing - $title"  
                #$Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content       
                $total_time = "$hrs`:$mins`:$secs"
                write-ezlogs " | Total Time: $($total_time)" -showtime
              }catch{
                write-ezlogs "An exception occurred parsing duration time $($duration)" -showtime -catcherror $_
              }
            }else{
              $total_time = "0`:0`:0"
            }                  
            $synchash.Media_Length_Label.content = '0' + "/" + "$total_time"  
            $synchash.MediaPlayer_CurrentDuration = $total_time   
            $audio_media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)flac|(?i)wav|(?i)3gp|(?i)aac))')        
            write-ezlogs " | Disposing existing libvlc instance" -showtime
            try{
              $synchash.libvlc.dispose()   
              #$video_View_grid = $synchash.VideoView_Grid          
              if($synchash.VLC_Grid.children -contains $synchash.VideoView){
                $synchash.VLC_Grid.children.Remove($synchash.VideoView)
              }
              $synchash.VideoView.MediaPlayer.Dispose()
              if($synchash.VLC_Grid.children -notcontains $synchash.VideoView){
                $synchash.VLC_Grid.children.add($synchash.VideoView)                
              } 
              $synchash.VLC_Grid.UpdateLayout()                 
            }catch{
              write-ezlogs "An exception occurred disposing and creating a new Webvifew control" -showtime -catcherror $_
            }
            if($thisApp.Config.Use_Visualizations -and ($media_link -match $audio_media_pattern -or $vlcurl -match $audio_media_pattern)){ 
              #,"--no-video"
              $synchash.FullScreen_Player_Button.isEnabled = $true
              if($thisApp.Config.Current_Visualization -eq 'Spectrum'){
                $Visualization = "Visual"
                $effect = "--effect-list=spectrum"
              }else{
                $Visualization = $thisApp.Config.Current_Visualization
                $effect = "--effect-list=spectrum"
              }     
              write-ezlogs "Enabling Visualization plugin '$Visualization'" -showtime        
              $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($thisApp.Config.logfile_directory)\$($thisapp.config.App_Name)-$($thisapp.config.App_Version)-VLC.log",'--log-verbose=3',"--audio-visual=$($Visualization)",$effect,"--video-on-top","--spect-show-original")                                                   
            }else{       
              write-ezlogs " | New libvlc instance, no visualization" -showtime   
              $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($thisApp.Config.logfile_directory)\$($thisapp.config.App_Name)-$($thisapp.config.App_Version)-VLC.log",'--log-verbose=3',"--file-caching=2000")         
            }            
            $synchash.VideoView.MediaPlayer = [LibVLCSharp.Shared.MediaPlayer]::new($synchash.libvlc)     
            $synchash.VLC = $synchash.VideoView.MediaPlayer   
            if($thisapp.config.Enable_EQ){
              write-ezlogs " | Set EQ for new vlc instance" -showtime 
              $null = $synchash.vlc.SetEqualizer($synchash.Equalizer)
            } 
            $synchash.libvlc_No_vis_timer.start()
                                                     
            if($video_url -and $audio_url){
              write-ezlogs " | Set video url $video_url - with input-slave: $audio_url" -showtime
              $libvlc_media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($video_url),[LibVLCSharp.Shared.FromType]::FromLocation,":input-slave=$($audio_url)")
            }elseif($vlcurl -or $media_link){
              if($media_link){
                if([System.IO.File]::Exists($media_link)){
                  write-ezlogs "[START_MEDIA] | Medialink is local path link $media_link" -showtime
                  $from_path = [LibVLCSharp.Shared.FromType]::FromPath                
                }else{
                  write-ezlogs "[START_MEDIA] | Medialink is URL link $media_link" -showtime
                  $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
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
              $synchash.vlc.EnableHardwareDecoding = $false
            }else{
              $synchash.vlc.EnableHardwareDecoding = $true
            } 
            if($vlcurl -eq 'http://127.0.0.1:53888/'){
              $libvlc_media.AddOption(":network-caching=150")
              $libvlc_media.AddOption(":clock-jitter=0")
              $libvlc_media.AddOption(":clock-synchro=0")
            }
            write-ezlogs "[START_MEDIA] | VLC Media URL to play: $($libvlc_media.Mrl)" -showtime                         
            $synchash.vlc.media = $libvlc_media                                   
            #$null = $synchash.VLC.Play()  
          }else{
            $synchash.MediaPlayer_CurrentDuration = 0
          }
          Add-Member -InputObject $thisApp.config -Name 'Last_Played_title' -Value $title -MemberType NoteProperty -Force
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value $media.id -MemberType NoteProperty -Force    
          $synchash.Last_Played = $media.id
          $synchash.Current_playing_media = $media
                    
          try{          
            if(Test-URL $chat_url){
              write-ezlogs "[START_MEDIA] | Chat URL available: $($chat_url)" -showtime
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
                $synchash.ChatView_URL = $chat_url
                $synchash.Initialize_ChatView_timer.start()
                #Initialize-ChatView -synchash $synchash -thisApp $thisApp -chat_url $chat_url
                #$synchash.Initialize_ChatView_timer.start()
              

                #write-ezlogs "[START_MEDIA] Navigating with Source: $($chat_url)" -enablelogs -Color cyan -showtime
                #$syncHash.chat_WebView2.source="https://twitch.tv/$($chat_url)/chat"
              }         
            }else{
              try{
                $synchash.Chat_View_Button.IsEnabled = $false    
                $synchash.chat_column.Width = '*'
                $synchash.chat_column.MinWidth = ''
                $synchash.Chat_Icon.Kind="ChatRemove"
                $synchash.Chat_View_Button.Opacity=0.7
                $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
                $synchash.chat_WebView2.Visibility = 'Hidden'
                if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
                  $synchash.chat_WebView2.stop()
                }
              }catch{
                write-ezlogs "An exception occurred disabling chat view" -showtime -catcherror $_
              }
            }
            if($thisapp.config.VideoView_LargePlayer){
              #$synchash.MainGrid_Row3.Height="22*"
              #$synchash.playlist_column.Width="*"
              #$synchash.Expand_Player_Icon.Kind = 'ScreenNormal'
              #$synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenNormal'
            }else{
              #$synchash.MainGrid_Row3.Height="400*"
             # $synchash.playlist_column.Width="200*"
              #$synchash.Expand_Player_Icon.Kind = 'ScreenFull'
              #$synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenFull'
            }                               
            [array]$media_queue = $syncHash.PlayQueue_TreeView.Items.tag.Media
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
          }catch{
            write-ezlogs "[START_MEDIA] An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_
          }                                                            
      },"Normal")
      
      if(!$synchash.Youtube_WebPlayer_URL){
        $null = $synchash.VLC.Play()     
        #$synchash.EQ_Timer.start()    
        $play_timeout = 0
        $streamlink_wait_timer = 1        
        while(!$synchash.vlc.IsPlaying -and $play_timeout -lt 60){
          $play_timeout++
          $streamlink_wait_timer++
          write-ezlogs "[START_MEDIA] | Waiting for VLC to begin playing..." -showtime
          if($media.webpage_url -match 'twitch.tv' -and $streamlink_wait_timer -and $streamlink_wait_timer -eq 11){
            write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now, relaunching Start-Media" -showtime -color cyan -logfile:$thisApp.Config.TwitchMedia_logfile
            try{
              $synchash.Start_media = $Media
              $synchash.start_media_timer.start()
              return
              #Start-Media -Media $Media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -media_contextMenu $synchash.Media_ContextMenu -PlayMedia_Command $synchash.PlayMedia_Command -all_playlists $all_playlists
            }catch{
              write-ezlogs "An exception occurred relaunching Start-Media" -showtime -catcherror $_
            }            
            <#            $streamlinkblock = {              
                if((Get-Process Streamlink*)){
                Get-Process Streamlink* | Stop-Process -Force
                }        
                $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53888 --loglevel debug --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
                start-sleep 1 
                $null = $synchash.VLC.Play()
                if($error){
                write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
                }
                }
                $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules #> 
          }elseif($play_timeout -eq 15){
            write-ezlogs "| Playback still hasnt starting, Attempting to execute Play() again" -showtime -warning
            $null = $synchash.VLC.Play()           
          }
          start-sleep 1         
        }
        if($synchash.vlc.IsPlaying){
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value $media.id -MemberType NoteProperty -Force
          $synchash.Current_playing_media = $media
          $synchash.Timer.Start()  
        }
      }   
      if(-not [string]::IsNullOrEmpty($Media.offline_image_url)){
        $image = $($Media.offline_image_url | select -First 1)
        $decode_Width = "1280"
      }elseif(-not [string]::IsNullOrEmpty($Media.profile_image_url)){
        $image = $($Media.profile_image_url | select -First 1)
        $decode_Width = "500"
      }elseif(-not [string]::IsNullOrEmpty($Media.cover_art)){
        $decode_Width = "500"
        $image = $($Media.Cover_art | select -First 1)
      }elseif(-not [string]::IsNullOrEmpty($Media.images.url)){
        $decode_Width = "500"
        $image = $($Media.images.url | where {$_ -match 'maxresdefault.jpg'} | select -First 1)
        write-ezlogs "#### Media : $($image)" -showtime
      }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){
        $decode_Width = "500"
        $image = $($Media.thumbnail | select -First 1)
      }else{
        $image = $null
      } 
      $image_Cache_path = $Null
      write-ezlogs " | SongInfo: $($media.songinfo)" -showtime
      if($media.songinfo){
        try{
          $taginfo = [taglib.file]::create($media_link) 
          write-ezlogs " | Tag Picture: $($taginfo.tag.pictures | out-string)" -showtime
        }catch{
          write-ezlogs "An exception occurred getting taginfo for $($media.URL)" -showtime -catcherror $_
        }
        if($taginfo.tag.pictures.IsLoaded){
          $cached_image = ($taginfo.tag.pictures | select -first 1).data.data
        }      
      }elseif($image){
        if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] Media Image found: $($image)" -showtime}      
        if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
          if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
          $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
        }
        #$encodeduri = $Null  
        #$encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($media.title)-$($media.type)")
        #$encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
        $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($media.id).png")
        if([System.IO.File]::Exists($image_Cache_path)){
          $cached_image = $image_Cache_path
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
                $image.DecodePixelWidth = $decode_Width
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
              $cached_image = $image_Cache_path            
            }catch{
              $cached_image = $Null
              write-ezlogs "[START_MEDIA] An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
            }
          }           
        }else{
          write-ezlogs "[START_MEDIA] Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
          $cached_image = $Null        
        }                                    
      } 
      if($cached_image){
        #if($thisApp.Config.Verbose_logging){write-ezlogs "Setting background image to $cached_image" -enablelogs -showtime}
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
      if($synchash.vlc.IsPlaying -or ($use_WebPlayer -and $synchash.Youtube_WebPlayer_URL)){       
        $synchash.Media_Current_Title = "$title"
        Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value $media.id -MemberType NoteProperty -Force
        $synchash.Current_playing_media = $media
        $synchash.Window.Dispatcher.invoke([action]{  
            $synchash.update_background_timer.start()                       
            $synchash.EQ_Timer.start()               
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
          if($media.webpage_url -match 'twitch.tv'){          
            $source = 'Twitch Stream'
            if(!$Media.profile_image_url){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Twitch48.png"
            }else{
              $applogo = $($Media.profile_image_url | select -First 1)
            }
          }elseif($media.type -eq 'YoutubePlaylist_item' -or $media.Group -eq 'Youtube'){
            $source = 'Youtube Media'
            if($Media.images.url){
              $applogo = $Media.images.url | select -first 1
            }elseif($cached_image){
              $applogo = $cached_image
            }else{              
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Youtube.png"
            }
          }else{
            $source = 'Local Media'
            if($cached_image){
              $applogo = $cached_image 
            }else{
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.png"
            }            
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
  Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Vlc_Play_media" -thisApp $thisApp -Script_Modules $Script_Modules
}
#---------------------------------------------- 
#endregion Start-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Media')
