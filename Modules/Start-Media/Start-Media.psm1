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
    - Module designed for Samson Media Player

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
    $synchashWeak,
    $thisApp,
    [switch]$Restart,
    [switch]$Startup,
    [switch]$CheckRunspace,
    [switch]$EnableCasting,
    [switch]$TemporaryPlayback,
    [switch]$Use_invidious,
    [switch]$No_YT_Embed,
    [switch]$start_Paused,
    [switch]$Use_Streamlink,
    [switch]$ForceUseYTDLP = $thisApp.Config.ForceUse_YTDLP,
    [switch]$use_WebPlayer = $thisapp.config.Youtube_WebPlayer,
    [switch]$Show_notifications = $thisApp.Config.Show_notifications,
    $memory_stream,
    [switch]$Verboselog = $true
  ) 
  try{  
    $Start_Media_Measure = [system.diagnostics.stopwatch]::StartNew()
    write-ezlogs "[Caller: $((Get-PSCallStack)[1].Location):$((Get-PSCallStack)[1].ScriptLineNumber)] ##### Start-Media Executed for $($Media.title)" -loglevel 2 -linesbefore 1
    $synchashWeak.Target.VLC_PlaybackCancel = $true
    $Supported_Youtube_Types = 'YoutubePlaylist','YoutubeVideo','YoutubeTV','YoutubeChannel','YoutubeSubscription','YoutubeMusic','YoutubePlaylistItem'
    if(!$start_Paused){
      write-ezlogs ">>>> Updating Now_Playing_Title_Label to loading"
      Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'Now_Playing_Title_Label' -Property 'DataContext' -value 'LOADING...'
      Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -value '' -NullValue
    }
    #Make sure last played is removed from queue
    if($synchashWeak.Target.Current_playing_media.id -ne $media.id -and $thisapp.config.Current_Playlist.values -contains $synchashWeak.Target.Current_playing_media.id){
      write-ezlogs "| Removing last played from Queue: $($synchashWeak.Target.Current_playing_media.title) - id: $($synchashWeak.Target.Current_playing_media.id)" -LogLevel 2
      Update-PlayQueue -Remove -ID $synchashWeak.Target.Current_playing_media.id -thisApp $thisApp -synchash $synchashWeak.Target -UpdateHistory
    }
    if($synchashWeak.Target.renderitems){
      write-ezlogs ">>>> Chromecast devices: $($synchashWeak.Target.renderitems | out-string)" -Dev_mode
    }   
    $synchashWeak.Target.Current_playing_media = $Null 
    $synchashWeak.Target.Youtube_webplayer_current_Media = $Null
    $synchashWeak.Target.Current_playing_Media_Chapter = $Null
    $synchashWeak.Target.Current_Video_Quality = $Null
    $synchashWeak.Target.Current_Audio_Quality = $null
    $synchashWeak.Target.streamlink = ''
    $synchashWeak.Target.VLC_IsPlaying_State = $false
    try{
      [void](Stop-Runspace -thisApp $thisApp -runspace_name 'Spotify_Play_media' -force)
    }catch{
      write-ezlogs " An exception occurred stopping existing runspace 'Spotify_Play_media'" -showtime -catcherror $_
    }   
    try{
      [void](Stop-Runspace -thisApp $thisApp -runspace_name 'Vlc_Play_media' -force)
    }catch{
      write-ezlogs " An exception occurred stopping existing runspace 'Vlc_Play_media'" -showtime -catcherror $_
    }
    $synchashWeak.Target.Youtube_WebPlayer_URL = $null
    $synchashWeak.Target.Youtube_WebPlayer_title = $null
    $synchashWeak.Target.Spotify_WebPlayer_State = $Null
    $synchashWeak.Target.MediaPlayer_TotalDuration = $Null
    $synchashWeak.Target.MediaPlayer_CurrentDuration = 0
    $synchashWeak.Target.WebPlayer_State = $null
    $synchashWeak.Target.Start_media = $null
    $synchashWeak.Target.Start_media_timer.stop()
    $IsValidYoutube_Media = (((Test-ValidPath $media -Type URL) -or (Test-ValidPath $media.url -Type URL)) -and ($media -match 'yewtu\.be|youtu\.be|youtube\.com' -or $media.url -match 'yewtu\.be|youtu\.be|youtube\.com'))
    $DisableChatView = $(!$IsValidYoutube_Media -or !$thisApp.Config.Chat_View -or ($media.url -match 'tv\.youtube\.com' -or $media -match 'tv\.youtube\.com'))
    if($thisapp.config.Youtube_WebPlayer -and $IsValidYoutube_Media){
      $CanUse_WebPlayer = $true
      if($synchashWeak.Target.YoutubeWebView2 -ne $null -and $synchashWeak.Target.YoutubeWebView2.CoreWebView2 -ne $null -and !$synchashWeak.Target.Initialize_YoutubeWebPlayer_timer.isEnabled){
        write-ezlogs ">>>> Disposing youtube webplayer Webview2 instance" -showtime -Warning
        $synchashWeak.Target.YoutubeWebView2.dispose()
        $synchashWeak.Target.YoutubeWebView2 = $Null
      }
    }else{
      $CanUse_WebPlayer = $false
      Reset-MainPlayer -thisApp $thisApp -synchash $synchashWeak.Target -SkipDiscord:$thisApp.Config.Discord_Integration
    }
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'DisplayPanel_VideoQuality_TextBlock' -Property 'text' -value $Null -NullValue
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -ClearValue -value ''
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'DisplayPanel_Sep3_Label' -Property 'text' -ClearValue -value ''   
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'DisplayPanel_Sep3_Label' -Property 'Visibility' -ClearValue -value 'Hidden'
    Set-WebPlayerTimer -synchash $synchashWeak.Target -thisApp $thisApp -stop
    Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Disable -Hide:$DisableChatView
    $synchashWeak.Target.Spotify_WebPlayer_URL = $null
    $synchashWeak.Target.Spotify_WebPlayer_title = $null  
    $synchashWeak.Target.Spotify_WebPlayer = $null
    $synchashWeak.Target.Media_Current_Title = ''
    if($thisApp.Config.Current_Playing_Media.id -eq $media.id -and -not [string]::IsNullOrEmpty($thisApp.Config.Current_Playing_Media.Current_Progress_Secs) -and !$Restart){
      $Saved_Media_Progress = $thisApp.Config.Current_Playing_Media.Current_Progress_Secs
    }
    $thisApp.Config.Current_Playing_Media = $null
    $synchashWeak.Target.ChatView_URL = $null
    if($Media.source -eq 'TOR' -and $memory_stream){
      $media_link = $memory_stream
    }elseif((Test-validpath $Media.url -Type URLorFile)){
      $media_link = $($Media.url)
      write-ezlogs ">>>> Selected Media to play: $($Media.url)" -showtime
    }elseif(!$Media.url -and (Test-validpath $Media -Type URLorFile)){
      $media_link = $Media
      write-ezlogs ">>>> Selected Media to play is a url $($media_link)" -showtime
    }else{

    }
    if($synchashWeak.Target.Timer.isEnabled){
      $synchashWeak.Target.Timer.stop()
    }
    if($synchashWeak.Target.vlc.media -is [System.IDisposable]){
      write-ezlogs "| Disposing existing libvlc_media"
      #$synchashWeak.Target.libvlc_media.dispose()
      #$synchashWeak.Target.libvlc_media = $Null
      $synchashWeak.Target.vlc.media = $Null
    }
    if($synchashWeak.Target.VLC.state -eq 'Playing' -or $synchashWeak.Target.Vlc.state -match 'Paused'){
      write-ezlogs "| Stopping Vlc"
      #$synchashWeak.Target.vlc.media = $Null
      #$synchashWeak.Target.libvlc_media = $Null
      $synchashWeak.Target.VLC.stop()
    }
    <#    if($synchashWeak.Target.libvlc){
        Add-VLCRegisteredEvents -synchash $synchashWeak.Target -thisApp $thisApp -UnregisterOnly
        write-ezlogs "[START-MEDIA] >>>> Disposing existing Libvlc instance"
        [void]$synchashWeak.Target.libvlc.dispose()
        $synchashWeak.Target.libvlc = $Null
    }#>

    <#    if($synchashWeak.Target.vlc -is [System.IDisposable]){
        write-ezlogs "| Disposing existing vlc instance"
        $synchashWeak.Target.vlc.dispose()
        $synchashWeak.Target.vlc = $Null
        if($synchashWeak.Target.VideoView.MediaPlayer -is [System.IDisposable]){
        write-ezlogs "| Disposing existing VideoView.MediaPlayer" -Warning
        $synchashWeak.Target.VideoView.MediaPlayer.Dispose()
        $synchashWeak.Target.VideoView.MediaPlayer = $Null
        }
    }#>
    if($synchashWeak.Target.libvlc -is [System.IDisposable] -and !$Startup){
      try{
        write-ezlogs "| Disposing existing Libvlc instance" -showtime -warning
        $synchashWeak.Target.libvlc.dispose()
        $synchashWeak.Target.libvlc = $Null
      }catch{
        write-ezlogs "An exception occurred An exception occurred Dispose libvlc" -showtime -catcherror $_
      }
    }
    <#    if($synchashWeak.Target.Equalizer -is [System.IDisposable]){
        write-ezlogs "| Disposing Existing Equalizer"
        $synchashWeak.Target.Equalizer.Dispose()
        $synchashWeak.Target.Equalizer = $Null
    }#>
    #Stop/reset any virtual audio
    Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchashWeak.Target -stop
  }catch{
    write-ezlogs "An exception occurred when starting Start-Media" -showtime -catcherror $_
  } 
    
  if($thisApp.config.Use_Spicetify -and ([System.Diagnostics.Process]::GetProcessesByName('Spotify')) -and $synchashWeak.Target.Spotify_Status -ne 'Stopped'){
    try{
      #start-sleep 1
      write-ezlogs "Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan -logtype Spotify
      Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing
      $synchashWeak.Target.Spicetify = ''
      $synchashWeak.Target.Spotify_Status = 'Stopped'
    }catch{
      write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
      $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
      if($Spotify_Process){
        foreach($s in $Spotify_Process){
          $s.kill()
          $s.dispose()
        }
      }
      $Spotify_Process = $Null
      $synchashWeak.Target.Spicetify = '' 
      $synchashWeak.Target.Spotify_Status = 'Stopped'
    }
  }elseif(($synchashWeak.Target.current_track_playing.is_playing -or $synchashWeak.Target.Spotify_Status -ne 'Stopped' ) -and ([System.Diagnostics.Process]::GetProcessesByName('Spotify'))){
    try{
      $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
      if($devices){
        write-ezlogs "Stopping Spotify playback with Suspend-Playback" -showtime -color cyan -logtype Spotify
        Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
      }else{
        write-ezlogs "Couldnt get Spotify Device id, using nuclear option and force stopping Spotify process" -showtime -warning -logtype Spotify
        $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
        if($Spotify_Process){
          foreach($s in $Spotify_Process){
            $s.kill()
            $s.dispose()
          }
        }
        $Spotify_Process = $Null
      }           
    }catch{
      write-ezlogs "An exception occurred executing Suspend-Playback" -showtime -catcherror $_
      $Spotify_Process = [System.Diagnostics.Process]::GetProcessesByName('Spotify')
      if($Spotify_Process){
        foreach($s in $Spotify_Process){
          $s.kill()
          $s.dispose()
        }
      }
      $Spotify_Process = $Null            
    }
    $synchashWeak.Target.Spotify_Status = 'Stopped'
    $synchashWeak.Target.current_track_playing = $Null    
  }  
  Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayButton_ToggleButton' -Property 'isChecked' -value $true

  if(!$synchashWeak.Target.vlc_scriptblock){
    $synchashWeak.Target.vlc_scriptblock = {
      param (
        $Media = $media,
        $synchashWeak = $synchashWeak,
        $thisApp = $thisApp,
        [switch]$Restart = $Restart,
        [switch]$CheckRunspace = $CheckRunspace,
        [switch]$EnableCasting = $EnableCasting,
        [switch]$TemporaryPlayback = $TemporaryPlayback,
        [switch]$Use_invidious = $Use_invidious,
        [switch]$No_YT_Embed = $No_YT_Embed,
        [switch]$start_Paused = $start_Paused,
        [switch]$Use_Streamlink = $Use_Streamlink,
        [switch]$ForceUseYTDLP = $ForceUseYTDLP,
        [switch]$use_WebPlayer = $use_WebPlayer,
        [switch]$Show_notifications = $Show_notifications,
        $memory_stream = $memory_stream,
        [switch]$Verboselog = $Verboselog
      )
      $chat_url = $chat_url
      $Supported_Youtube_Types = $Supported_Youtube_Types
      $media_link = $media_link
      $CanUse_WebPlayer = $CanUse_WebPlayer
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Start-Media\Start-Media.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\EZT-AudioManager\EZT-AudioManager.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-module Microsoft.PowerShell.Utility -NoClobber -Scope Local
      $jobs = [System.WeakReference]::new($thisApp.Jobs.clone(),$false).Target
      $index = $($jobs.Name.IndexOf("Vlc_Play_media"))
      if($index -ne -1){
        $waithandle = [System.WeakReference]::new($jobs[$index])
      }else{
        write-ezlogs "Unable to find runspace job for runspace: Vlc_Play_media - cannot continue!" -warning
        return
      }
      $jobs = $Null
      $envpaths = $env:path -split ';'
      #if($thisApp.Config.startup_perf_timer){write-ezlogs "[START-MEDIA] | Start-Media Scriptblock begin:" -logtype Perf -GetMemoryUsage}

      $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl"
      $Streamlinkpath = "$env:ProgramFiles\Streamlink\bin"
      if($envpaths -notcontains $youtubedl_path){
        $env:Path += ";$youtubedl_path"
      }
      $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl\yt-dlp.exe"
      if($envpaths -notcontains $Streamlinkpath){
        write-ezlogs ">>>> Adding streamlink path top enviroment paths: $Streamlinkpath"
        $env:Path += ";$Streamlinkpath"
      }
      if(!$media_link -and $media.source -eq 'Local' -and $synchashWeak.Target.All_local_Media.count -gt 0){
        try{
          $index = $synchashWeak.Target.All_local_Media.id.IndexOf($media.id)
          if($index -ne -1){                 
            $Track = $synchashWeak.Target.All_local_Media[$index]
          }
          if($Track.id -and $(Test-validpath $Track.url -Type URLorFile)){
            write-ezlogs ">>>> Found updated media from library profile: $($Track.url)" -warning
            $media = $track
            $media_link = $Track.url
            #TODO: Update playlist profile
          }elseif($Track.id -and $Track.url){           
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Find-FilesFast\Find-FilesFast.psm1" -NoClobber -DisableNameChecking -Scope Local
            $Filename = [System.IO.Path]::GetFileName($Track.url)
            $RootDir = [System.IO.Path]::GetPathRoot($Track.url)
            $searchpattern = [regex]::Escape($Filename)
            if([System.IO.Directory]::Exists($RootDir)){
              write-ezlogs ">>>> Unable to find local media url -- attempting to search root directory ($($RootDir)) for filename: $Filename" -Warning
              $FileSearch = Find-FilesFast -Path $RootDir -Recurse -Filter $searchpattern
              if($FileSearch.FileName -eq $Filename){
                write-ezlogs "Find media file at new location: $($FileSearch.FullName) -- updating media profile with new url" -Success
                $media_link = $FileSearch.FullName
                $Track.url = $FileSearch.FullName
                $Media.url = $FileSearch.FullName
              }else{
                write-ezlogs "Unable to find media file in root directory: $RootDir" -Warning
              }
            }else{
              write-ezlogs "Media files root directory does not exist at: $RootDir" -Warning
            }
          }else{
            write-ezlogs "Unable to find Media URL link to use for media: $($media.url)" -warning
          }
        }catch{
          write-ezlogs "An exception occurred looking up media in local library with id: $($media.id)" -catcherror $_
        }
      }
      if(-not [string]::IsNullOrEmpty($Media.title)){
        $title = $Media.title
      }
      if($Media.Artist){
        $artist = $Media.Artist
      }
      #Update Playlist/Queue  
      try{
        $synchashWeak.Target.VLC_PlaybackCancel = $false
        $ffmpeg_Path = "$($thisApp.config.Current_folder)\Resources\flac"
        if($envpaths -notcontains $ffmpeg_Path){
          $env:Path += ";$ffmpeg_Path"
        }
        $synchashWeak.Target.Current_playing_media = $media
        Update-PlayQueue -synchash $synchashWeak.Target -thisApp $thisApp -Add -Add_First $media.id -RefreshQueue
        Update-MediaTransportControls -synchash $synchashWeak.Target -thisApp $thisApp -Media $media
      }catch{
        write-ezlogs "An exception occurred updating current_playlist" -showtime -catcherror $_
      }

      #Chat URL   
      try{
        if($media.url -match 'twitch\.tv' -and $Media.chat_url){
          $chat_url = $Media.chat_url
        }elseif($media.uri -match 'twitch\.tv' -and $media.uri -notmatch '\/videos\/'){
          $chat_url = "$($media.uri)/chat"
        }elseif($media_link -match 'twitch\.tv' -and $media_link -notmatch '\/videos\/'){
          $chat_url = "$($media_link)/chat"
        }else{
          $chat_url = $null
        }
      }catch{
        write-ezlogs "An exception occurred parsing chat url" -showtime -catcherror $_
      }

      write-ezlogs ">>>> Checking media type: $($media.type)" -showtime
      if($media_link -match 'soundcloud\.com' -or $media.type -eq 'Soundcloud'){
        write-ezlogs "| Media type is soundcloud, using yt-dlp" -showtime
        $ForceUseYTDLP = $true
        $CanUse_WebPlayer = $false
      }
      #Subtitles
      if($thisApp.Config.Enable_Subtitles -and $media.source -eq 'Local'){
        try{
          $mediadirectory = [system.io.path]::GetDirectoryName($Media.url)
          if([system.io.path]::GetExtension($Media.Subtitles_Path) -eq '.srt' -and [system.io.file]::Exists($media.Subtitles_path)){
            write-ezlogs "| Found Subtitles file to use for media: $($Media.Subtitles_Path)"
            $Subtitles_Path = $Media.Subtitles_Path
          }elseif([System.IO.Directory]::Exists($mediadirectory)){
            $Subtitles_Path = ([system.io.path]::Combine($mediadirectory,"$([system.io.path]::GetFileNameWithoutExtension($Media.url)).srt"))
            if([system.io.file]::Exists($Subtitles_Path)){
              write-ezlogs  "| Found new subtitle file: $Subtitles_Path" -Success
              if($Media.Subtitles_Path -ne $Subtitles_Path){
                $Media.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('Subtitles_Path',$Subtitles_Path))
              }
            }else{
              $Subtitles_Path = $Null
              write-ezlogs "| No subtitles were found for local media"
              if($Media.Subtitles_Path -ne ''){
                $Media.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('Subtitles_Path',''))
              }
            }          
          }else{
            write-ezlogs "| No valid subtitles found for: $($Media.url)" -warning
            $Subtitles_Path = $null
          }
        }catch{
          write-ezlogs "An exception occurred getting subtitles for: $($media.url)" -catcherror $_
        }
      }
      if(!$CanUse_WebPlayer -and $media_link -match 'tv\.youtube\.com' -or $media.type -eq 'YoutubeTV'){
        write-ezlogs "| Media is Youtube TV content, forcing use of Webplayer" -showtime
        $CanUse_WebPlayer = $true
      }    
      if($TemporaryPlayback -and ($media_link -match 'youtube\.com'  -or $media_link -match 'youtu\.be') -and $media_link -notmatch 'googlevideo\.com' -and $thisapp.config.Youtube_WebPlayer){
        $CanUse_WebPlayer = $true
      }
      if($CanUse_WebPlayer){
        $mediaType = 'Youtube'
        write-ezlogs "| Using Youtube Web Player" -showtime
        if($synchashWeak.Target.YoutubeWebView2 -eq $null -or $synchashWeak.Target.YoutubeWebView2.CoreWebView2 -eq $null){
          $synchashWeak.Target.Initialize_YoutubeWebPlayer_timer.start()
        }   
        if($media.title){
          $title = $media.title
        }else{
          $title = $media
        }
        $synchashWeak.Target.Youtube_WebPlayer_title = $title
        write-ezlogs "| Youtube URL Title: $title - URL: $media_link" -LogLevel 2
        try{
          if(-not [string]::IsNullOrEmpty($media.Duration_ms)){
            $duration = $($([timespan]::FromMilliseconds(($media.Duration_ms)).TotalMilliseconds))
          }elseif(-not [string]::IsNullOrEmpty($media.duration) -and $media.duration -notmatch ':'){
            $duration = $($([timespan]::FromMilliseconds(($media.Duration)).TotalMilliseconds))
          }elseif(-not [string]::IsNullOrEmpty($media.duration)){
            $duration = $media.duration
          }else{
            $duration = 0
          } 
        }catch{
          write-ezlogs "An exception occurred parsing media duration for media $($media | out-string)" -showtime -catcherror $_
        }
        $youtube = Get-YoutubeURL -URL $media_link -APILookup -thisApp $thisApp
        $youtube_id = $youtube.id
        if($youtube.YTVUrl){
          [Uri]$vlcurl = $youtube.YTVUrl  
          write-ezlogs "| YoutubeTV URL for playback: $($vlcurl)" -loglevel 2
        }elseif($youtube.playlist_id){
          <#          if($playlist_id){
              $Playlist_items = Get-YouTubePlaylistItems -Id $playlist_id
              if($PlaylistIndex){
              $Index = $PlaylistIndex -1
              }else{
              $Index = 0
              }
              $Playlistitem = $Playlist_items[$Index]
          }#>
          if($thisApp.Config.Use_invidious -or $Use_invidious){            
            [Uri]$vlcurl = "https://yewtu.be/embed/videoseries?list=$($youtube.playlist_id)" 
          }else{
            if($No_YT_Embed -or $youtube.id){
              [Uri]$vlcurl = "https://www.youtube.com/watch?v=$($youtube.id)&list=$($youtube.playlist_id)" 
            }else{
              [Uri]$vlcurl = "https://www.youtube.com/embed/videoseries?list=$($youtube.playlist_id)"
            }     
          }
        }elseif($youtube.id){
          if($thisApp.Config.Use_invidious -or $Use_invidious){
            [Uri]$vlcurl = "https://yewtu.be/embed/$($youtube.id)"
            write-ezlogs "| Youtube invidious URL for playback: $($vlcurl)" -loglevel 2
          }else{
            if($No_YT_Embed){
              [Uri]$vlcurl = "https://www.youtube.com/watch/$($youtube.id)"
              write-ezlogs "| Youtube Non-embeded URL for playback: $($vlcurl)" -loglevel 2
            }else{            
              [Uri]$vlcurl = "https://www.youtube.com/embed/$($youtube.id)"
              write-ezlogs "| Youtube embeded URL for playback: $($vlcurl)" -loglevel 2
            }
          }
        }
        #TODO: PlayerParams: tracking video played history?
        if($media_link -match '\&pp='){
          $pp = [regex]::matches($media_link, "\&pp=(?<value>.*)") | & { process {$_.groups[1].value}}
          [Uri]$vlcurl = "$vlcurl" + "&pp=$pp"
        }
        if($youtube.TimeIndex){
          [Uri]$vlcurl = "$vlcurl" + $youtube.TimeIndex
        }
        if($vlcurl){
          $synchashWeak.Target.Youtube_WebPlayer_URL = [Uri]$vlcurl
          if($thisApp.Config.Enable_EQ){
            $media_link = "dshow://"
          }
          write-ezlogs ">>>> Starting YoutubeWebPlayerTimer - URL: $($synchashWeak.Target.Youtube_WebPlayer_URL)"
          Set-YoutubeWebPlayerTimer -synchash $synchashWeak.Target -thisApp $thisApp -No_YT_Embed:$No_YT_Embed
        }else{
          Update-Notifications -Level 'WARNING' -Message "Playback failed! Unable to parse a valid Youtube ID or URL from: $($media_link)" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold  
          $synchashWeak.Target.Stop_media_timer.start()
          return
        }
      }elseif($media.type -match 'Youtube' -or $media.Source -eq 'Youtube' -or ($media_link -match 'youtube\.com' -and (Test-ValidPath $media_link -Type URL)) -or ($media_link -match 'twitch\.tv' -and (Test-ValidPath $media_link -Type URL))){
        if($media.url -match 'twitch\.tv'){
          $mediaType = 'Twitch'
          write-ezlogs ">>>> Media is type Twitch Stream, using Streamlink" -showtime
      
          #if($thisApp.Config.startup_perf_timer){write-ezlogs "[START-MEDIA] | Start-Media Twitch Processing begin: " -logtype Perf -GetMemoryUsage}
          if($media.url -match '\/videos\/'){
            $VideoId = [regex]::matches($media.url, "\/videos\/(?<value>.*)") | & { process {$_.groups[1].value}}
            if($VideoId -match '\?'){
              $VideoId = ($VideoId -split '\?')[0]
            }
            $TwitchArchive = $true
            $synchashWeak.Target.streamlink = Get-TwitchVideos -TwitchVideoId $VideoId -thisApp $thisApp
            $twitch_channel = $synchashWeak.Target.streamlink.user_name
            write-ezlogs "| Media is Twitch VOD -- video id: $VideoId -- channel: $twitch_channel" -showtime
            if($synchashWeak.Target.streamlink.duration -match 'h'){
              $hours = [regex]::matches($synchashWeak.Target.streamlink.duration, "(?<value>.*)h") | & { process {$_.groups[1].value}}
              $minutes = [regex]::matches($synchashWeak.Target.streamlink.duration, "h(?<value>.*)m") | & { process {$_.groups[1].value}}
            }else{
              $hours = 0
            }
            if(!$minutes -and $synchashWeak.Target.streamlink.duration -match 'm'){
              $minutes = [regex]::matches($synchashWeak.Target.streamlink.duration, "(?<value>.*)m")| & { process {$_.groups[1].value}}
            }elseif(!$minutes){
              $minutes = 0
            } 
            if($synchashWeak.Target.streamlink.duration -match 's' -and $synchashWeak.Target.streamlink.duration -match 'm'){
              $seconds = [regex]::matches($synchashWeak.Target.streamlink.duration, "m(?<value>.*)s") | & { process {$_.groups[1].value}}
            }elseif($synchashWeak.Target.streamlink.duration -match 's'){
              $seconds = [regex]::matches($synchashWeak.Target.streamlink.duration, "(?<value>.*)s") | & { process {$_.groups[1].value}}
            }elseif(!$seconds){
              $seconds = 0
            }                  
            $duration = [timespan]::new($hours,$minutes,$seconds).TotalMilliseconds
            write-ezlogs "| Twitch url is a VOD - duration: $($duration)"
          }else{
            $TwitchArchive = $false
            $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(([System.IO.Path]::GetFileName($media.url)).ToLower())
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Twitch\Get-Twitch.psm1" -NoClobber
            $synchashWeak.Target.streamlink = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
            if($thisapp.config.Streamlink_Interface -eq 'Default'){
              $Streamlink_Interface = "127.0.0.1"
            }else{
              if($thisapp.config.Streamlink_Interface -eq 'Default' -or [string]::IsNullOrEmpty($thisapp.config.Streamlink_Interface)){
                $Streamlink_Interface = "127.0.0.1"
              }else{
                try{
                  $Network_Adapter = (Get-CimInstance -Class Win32_NetworkAdapterConfiguration).Where({$_.IPEnabled -and $_.IPaddress -and $_.DefaultIPGateway -notcontains '0.0.0.0' -and $_.DefaultIPGateway -ne $Null})
                  if($Network_Adapter.IPAddress -contains $thisapp.config.Streamlink_Interface){
                    $Streamlink_Interface = $thisapp.config.Streamlink_Interface
                  }elseif($thisapp.config.Streamlink_Interface -eq 'Any' -and $Network_Adapter){
                    $Streamlink_Interface = ($Network_Adapter.where({$_.DefaultIPGateway})).IPAddress | Select-Object -first 1
                  }else{
                    $Streamlink_Interface = "127.0.0.1"
                  }
                }catch{
                  write-ezlogs "An exception occured gettign network adapters" -catcherror $_
                }finally{
                  if($Network_Adapter -and $Network_Adapter[0] -is [System.IDisposable]){
                    [void]($Network_Adapter.dispose())
                    $Network_Adapter = $Null
                  }
                }
              }
            }
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Streamlink_HTTP_Port)){
              $Streamlink_Port = $thisApp.Config.Streamlink_HTTP_Port
            }else{
              $Streamlink_Port = '53888'
            }
            if($Streamlink_Interface){
              write-ezlogs "| Primary network interface to use for streamlink $($Streamlink_Interface)" -Dev_mode
              $synchashWeak.Target.streamlink_HTTP_URL = "http://$($Streamlink_Interface):$Streamlink_Port"      
              $synchashWeak.Target.Primary_Network_Interface = $($Streamlink_Interface)
            }else{
              write-ezlogs "Unable to determine primary network adapter address, using default address http://127.0.0.1:$Streamlink_Port/" -warning
              $synchashWeak.Target.streamlink_HTTP_URL = "http://127.0.0.1:$Streamlink_Port/"
            }
          }
          if($synchashWeak.Target.streamlink){
            $TwitchAPI = $synchashWeak.Target.streamlink
            $synchashWeak.Target.Current_playing_media = $media
          }                       
          try{  
            if($TwitchAPI.thumbnail_url){
              $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500' -replace '%{width}x%{height}','500x500')"
            }else{
              $thumbnail = ''
            }                
            if(!$TwitchAPI.type){
              write-ezlogs "Twitch Channel $twitch_channel`: OFFLINE" -showtime -warning -logtype Twitch -AlertUI -synchash $synchashWeak.Target
              #Update-Notifications -Level 'WARNING' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout
              $media.Live_Status = 'Offline'
              $media.Status_Msg = ''
              $media.Stream_title = ''
              $media.thumbnail = ''
              $media.Artist = "$($twitch_channel)"
              $media.viewer_count = 0
              if($synchashWeak.Target.Timer){
                $synchashWeak.Target.Timer.stop()
              }
              try{
                Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'Now_Playing_Title_Label' -Property 'DataContext' -value '' -NullValue
                Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'Now_Playing_Artist_Label' -Property 'DataContext' -value '' -NullValue
                Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'DisplayPanel_Bitrate_TextBlock' -Property 'text' -value '' -NullValue
                Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -Control 'DisplayPanel_Sep3_Label' -Property 'Visibility' -value 'Hidden'
              }catch{
                write-ezlogs "An exception occurred updating Now Playing labels" -showtime -catcherror $_
              }                          
              if($synchashWeak.Target.Stop_media_timer){
                $synchashWeak.Target.Stop_media_timer.start()
              }
              Update-TwitchStatus -thisApp $thisApp -synchash $synchashWeak.Target -media $media
              return
            }else{
              write-ezlogs ">>>> Starting streamlink for url: $($media.url)" -showtime -logtype Twitch
              if(!$TwitchArchive){
                #$twitch_status = $((Get-Culture).textinfo.totitlecase(($TwitchAPI.type).tolower()))
                $twitch_status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($TwitchAPI.type).tolower()).trim()
                $media.Live_Status = $twitch_status
                $media.Status_Msg = "$($TwitchAPI.game_name)"
                $media.viewer_count = [int]$TwitchAPI.viewer_count
              }else{
                $media.viewer_count = [int]$TwitchAPI.view_count
              }
              $media.Stream_title = "$($TwitchAPI.title)"
              $media.thumbnail = $thumbnail
              $media.Artist = "$($twitch_channel)"
              if($thisApp.Config.Skip_Twitch_Ads){
                $twitch_disable_ads = '--twitch-disable-ads'
                if(-not [string]::IsNullOrEmpty($thisApp.Config.Chat_WebView2_Cookie)){
                  try{
                    $Twitch_token = ([System.Web.HttpUtility]::UrlDecode($thisApp.Config.Chat_WebView2_Cookie) | convertfrom-json).authToken
                    write-ezlogs "| Using Chat Webview2 cookie token for Twitch stream oauth " -showtime -loglevel 2 -logtype 'Twitch'
                  }catch{
                    write-ezlogs "An exception occurred parsing Twitch oath from webview2 cookie" -showtime -catcherror $_
                  }
                }
                if(-not [string]::IsNullOrEmpty($Twitch_token)){
                  $Twitch_oauth = "--twitch-api-header=Authorization=OAuth $($Twitch_token)"
                }else{
                  $Twitch_oauth = ""
                }                
              }else{
                $twitch_disable_ads = ''
              }                          
              $streamlink_wait_timer = 1
              if(([system.io.file]::Exists("$Streamlinkpath\Streamlink.exe")) -and !$ForceUseYTDLP){
                if($TwitchArchive){
                  write-ezlogs "| Getting usable hls url from streamlink for url: $($media.url)" -showtime
                  $synchashWeak.Target.streamlink_HTTP_URL = Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -media $media -Use_Runspace -TwitchVOD -wait
                }else{                  
                  Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -twitch_disable_ads $twitch_disable_ads -Twitch_oauth $Twitch_oauth -media $media -Use_Runspace
                }
                write-ezlogs "| Streamlink http address to use: $($synchashWeak.Target.streamlink_HTTP_URL)"
              }else{
                write-ezlogs "Unable to find Streamlink installed, falling back to using YTDLP" -showtime -warning
                $synchashWeak.Target.ForceUseYTDLP = $true
                $synchashWeak.Target.Start_media = $Media
                $synchashWeak.Target.start_media_timer.start()                  
                return
              }                    
            }
            if($synchashWeak.Target.all_playlists){
              $Playlist_profile = Get-IndexesOf $synchashWeak.Target.all_playlists.Playlist_Tracks.values.id -Value $media.id | & { process {
                  $synchashWeak.Target.all_playlists.Playlist_Tracks.values[$_]
              }}
            }
            foreach($track in $Playlist_profile.Playlist_tracks.values){
              if($track.id -eq $media.id){
                $track.title = $Media.Title
                if(!$TwitchArchive){
                  $track.Status_Msg = $Media.Status_Msg
                  $track.Live_Status = $Media.Live_Status
                }
                $track.viewer_count = [int]$TwitchAPI.viewer_count
                $track.Stream_title = "$($Media.Stream_title)"
                $track.Artist = "$($twitch_channel)"          
                write-ezlogs "| Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -logtype Twitch
              }
            }                    
          }catch{
            write-ezlogs "An exception occurred starting streamlink" -showtime -catcherror $_
          }
          if(!$ForceUseYTDLP -and !$TwitchArchive){
            while($streamlink_wait_timer -lt 60 -and !$([System.Diagnostics.Process]::GetProcessesByName('streamlink')) -and !$synchashWeak.Target.ForceUseYTDLP -and !$synchashWeak.Target.VLC_PlaybackCancel){
              $streamlink_wait_timer++
              write-ezlogs "| Waiting for streamlink process...." -showtime -logtype Twitch
              if($streamlink_wait_timer -eq 30){
                write-ezlogs "Relaunching streamlink as it should have started by now" -showtime -logtype Twitch -warning
                Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -twitch_disable_ads $twitch_disable_ads -Twitch_oauth $Twitch_oauth -media $media -Use_Runspace
              }
              if($waithandle.target.runspace.AsyncWaitHandle){
                [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(200)
              }else{
                start-sleep -Milliseconds 200
              }
            }
          }
          if($synchashWeak.Target.VLC_PlaybackCancel){
            write-ezlogs "Playback has been canceled, stopping any further processing" -warning
            return
          }
          if((!$TwitchArchive -and ($streamlink_wait_timer -ge 60)) -or $ForceUseYTDLP){
            $synchashWeak.Target.ForceUseYTDLP = $false
            write-ezlogs "Timed out waiting for streamlink to start, falling back to yt-dlp" -showtime -warning -logtype Twitch   
            if($thisApp.Config.Skip_Twitch_Ads){ 
              if([string]::IsNullOrEmpty($Twitch_token) -and -not [string]::IsNullOrEmpty($thisApp.Config.Chat_WebView2_Cookie)){
                try{
                  $Twitch_token = [System.Web.HttpUtility]::UrlDecode($thisApp.Config.Chat_WebView2_Cookie) | convertfrom-json
                }catch{
                  write-ezlogs "An exception occurred parsing Twitch oath from webview2 cookie" -showtime -catcherror $_
                }
              }
            }
            try{
              $newProc = [System.Diagnostics.ProcessStartInfo]::new($youtubedl_path)
              $newProc.WindowStyle = 'Hidden'
              $newProc.Arguments = "-f b -g $($media.url) -o '*' -j --cookies-from-browser $($thisApp.config.Youtube_Browser) --add-header `"Device-Id:twitch-web-wall-mason`" --add-header `"X-Device-Id:twitch-web-wall-mason`" --add-header `"Authorization: OAuth $($Twitch_token)`" --sponsorblock-remove all"
              $newProc.UseShellExecute = $false
              $newProc.CreateNoWindow = $true
              $newProc.RedirectStandardOutput = $true
              $Process = [System.Diagnostics.Process]::Start($newProc)
              $yt_dlp = $Process.StandardOutput.ReadToEnd() | Convertfrom-Json
            }catch{
              write-ezlogs "An exception occurred executing: $youtubedl_path" -catcherror $_
            }finally{
              if($Process -is [System.IDisposable]){
                $Process.dispose()
              }
            }
            <#            if($thisApp.config.Youtube_Browser){
                $yt_dlp = yt-dlp -f b -g $media.url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-Id:twitch-web-wall-mason" --add-header "X-Device-Id:twitch-web-wall-mason" --add-header "Authorization: OAuth $($Twitch_token)" --sponsorblock-remove all 
                }else{
                $yt_dlp = yt-dlp -f b -g $media.url -o '*' -j  --add-header "Device-Id:twitch-web-wall-mason" --add-header "X-Device-Id:twitch-web-wall-mason" --add-header "Authorization: OAuth $($Twitch_token)" --sponsorblock-remove all 
            }#>
            if($yt_dlp){
              [Uri]$vlcurl = $yt_dlp[0] 
              write-ezlogs ">>>> YT-DLP returned url: $($vlcurl)" -showtime -warning
              $media_link = $vlcurl
            }else{
              write-ezlogs "Fall back to YT-DLP failed!" -showtime -warning
              if($synchashWeak.Target.streamlinkerror){
                write-ezlogs "Streamlink returned an error when trying to access stream url $($media.url) - $($synchashWeak.Target.streamlinkerror | out-string)" -showtime -warning
                Update-Notifications -Level 'ERROR' -Message "Streamlink returned an error: $($synchashWeak.Target.streamlinkerror | out-string)" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold  
              }else{
                Update-Notifications -Level 'WARNING' -Message "Failed to play stream url $($media.url) with either Streamlink or YT-DLP" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold  
              }
              $synchashWeak.Target.streamlinkerror = $Null
              $synchashWeak.Target.Stop_media_timer.start()
              return
            }               
          }elseif(!$TwitchArchive -and $media.live_status -eq 'Offline'){
            write-ezlogs "Stream offline -- cannot continue" -showtime -warning -logtype Twitch
            return               
          }else{
            [Uri]$vlcurl = $($synchashWeak.Target.streamlink_HTTP_URL)
            $media_link = $vlcurl
            $Live_stream = !$TwitchArchive
            write-ezlogs ">>>> Connecting to Streamlink URL for playback: $($media_link)" -showtime -logtype Twitch
          }            
        }elseif($media.url -match 'youtube' -or $media_link -match 'youtube' -or $media.url -match 'youtu\.be' -or $media_link -match 'youtu\.be' -or $media.type -eq 'Soundcloud'){          
          if($media.id){
            $youtube_id = $media.id
          }
          if($media.type -eq 'Soundcloud'){
            $mediaType = 'Soundcloud'
          }else{
            $mediaType = 'Youtube'
          }
          if($parse.IsCompleted){
            [Uri]$vlcurl = $libvlc_media.SubItems[0].Mrl 
            $media_link = $libvlc_media.SubItems[0].Mrl                     
          }else{
            if($Use_Streamlink -and !$ForceUseYTDLP){
              write-ezlogs ">>>> Starting Streamlink for Youtube url: $media_link" -LogLevel 2
              $streamlink = Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -media $media -Use_Runspace -Youtube -wait
              if((Test-ValidPath $streamlink -Type URL)){
                [Uri]$vlcurl = $streamlink
                $media_link = $vlcurl
                write-ezlogs ">>>> Connecting to Streamlink URL for playback: $($media_link)" -showtime
              }else{
                $synchashWeak.Target.Stop_media_timer.start()
                return
              }                   
            }else{
              write-ezlogs "| Getting best quality video and audio links from yt_dlp for Youtube url: $($media.url)" -showtime 
              try{
                if($media.url){
                  $media_link = $media.url
                }           
                #Yt-dlp arguments that allow downloading YT Premium bitrates/quality: --extractor-args "youtube:player_client=default,ios || -f 'bestvideo+bestaudio/best'"
                try{
                  $newProc = [System.Diagnostics.ProcessStartInfo]::new($youtubedl_path)
                  $newProc.WindowStyle = 'Hidden'
                  $newProc.Arguments = "$media_link --sponsorblock-remove all --sponsorblock-mark all --sponsorblock-chapter-title '`"[SponsorBlock]: %(category_names)l`"' --extractor-args `"youtube:player_client=default,ios`" --no-check-certificate --skip-download --youtube-skip-dash-manifest --cookies-from-browser $($thisApp.config.Youtube_Browser) -j"
                  $newProc.UseShellExecute = $false
                  $newProc.CreateNoWindow = $true
                  $newProc.RedirectStandardOutput = $true
                  $Process = [System.Diagnostics.Process]::Start($newProc)
                  $yt_dlp = $Process.StandardOutput.ReadToEnd() | Convertfrom-Json
                }catch{
                  write-ezlogs "An exception occurred executing: $streamlinkpath" -catcherror $_
                }finally{
                  if($Process -is [System.IDisposable]){
                    $Process.dispose()
                  }
                }
                <#                if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
                    $yt_dlp = yt-dlp $media_link --sponsorblock-remove all --sponsorblock-mark all --sponsorblock-chapter-title '"[SponsorBlock]: %(category_names)l"' --extractor-args "youtube:player_client=default,ios" --no-check-certificate --skip-download --youtube-skip-dash-manifest --cookies-from-browser $thisApp.config.Youtube_Browser -j | convertfrom-json     
                    }else{
                    $yt_dlp = yt-dlp $media_link --sponsorblock-remove all --sponsorblock-mark all --sponsorblock-chapter-title '"[SponsorBlock]: %(category_names)l"' --extractor-args "youtube:player_client=default,ios" --no-check-certificate --skip-download --youtube-skip-dash-manifest -j | convertfrom-json 
                }#>
              }catch{
                write-ezlogs "An exception occurred in yt-dlp when processing URL $($media_link)" -showtime -catcherror $_
              }
              if(!$yt_dlp -and !$Use_streamlink){
                write-ezlogs "Unable to get playable url from yt-dlp, trying streamlink..." -showtime -warning
                $streamlink_wait_timer = 1
                Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -media $media_link -Use_Runspace -Youtube
                while($streamlink_wait_timer -lt 20 -and !$([System.Diagnostics.Process]::GetProcessesByName('streamlink'))){
                  $streamlink_wait_timer++
                  write-ezlogs "| Waiting for streamlink process...." -showtime
                  if($streamlink_wait_timer -eq 15){
                    write-ezlogs "Relaunching streamlink as it should have started by now" -showtime -warning
                    Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -media $media_link -Use_Runspace -Youtube
                  }
                  if($waithandle.target.runspace.AsyncWaitHandle){
                    [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(1000)
                  }else{
                    start-sleep -Milliseconds 1000
                  }
                }
                if($streamlink_wait_timer -ge 20){
                  write-ezlogs "Timed out waiting for streamlink to start: $media_link, cannot continue!" -showtime -warning
                  Update-Notifications -Level 'WARNING' -Message "Timed out waiting for streamlink to start: $media_link, cannot continue!" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold   
                  return     
                }else{
                  [Uri]$vlcurl = $($synchashWeak.Target.streamlink_HTTP_URL)
                  $media_link = $vlcurl
                  write-ezlogs ">>>> Connecting to Streamlink URL for playback: $($media_link)" -showtime             
                }                                             
              }else{
                $best_quality = $yt_dlp.url | Select-Object -last 1
                if(!$best_quality -and $yt_dlp.format){           
                  $yt_dlp_audio = ($yt_dlp.formats.where({$_.abr -eq ($yt_dlp.formats | Measure-Object -Property abr -Maximum).Maximum}) | Select-Object -last 1)
                  $audio_url = ($yt_dlp_audio).url
                  write-ezlogs "| Getting Best Quality Audio $($yt_dlp_audio.format) -- ABR: $($yt_dlp_audio.abr)" -showtime -logtype Youtube
                  if($thisapp.config.Youtube_Quality -eq 'Best'){
                    $yt_dlp_video = ($yt_dlp.formats.where({$_.vbr -eq ($yt_dlp.formats | Measure-Object -Property vbr -Maximum).Maximum}))
                    #$yt_dlp_video = $yt_dlp_video | where {$_.vbr -eq ($yt_dlp_video | measure -Property vbr -Maximum).Maximum}
                    $video_url = ($yt_dlp_video).url
                    write-ezlogs "| Getting Best Quality Video $($yt_dlp_video.format) -- VBR: $($yt_dlp_video.vbr)" -showtime -logtype Youtube
                  }elseif($thisapp.config.Youtube_Quality -eq 'Medium' -or !$thisapp.config.Youtube_Quality -or $thisapp.config.Youtube_Quality -eq 'Auto'){
                    $yt_dlp_video = ($yt_dlp.formats.where({$_.height -le '720' -and $_.Height -gt '480'}) | Select-Object -last 1)
                    if(!$yt_dlp_video){
                      $yt_dlp_video = ($yt_dlp.formats.where({$_.vbr -gt '1000' -and $_.vbr -lt '2000'}) | Select-Object -last 1)
                    }                  
                    $video_url = ($yt_dlp_video).url
                    write-ezlogs "| Getting Medium Quality Video $($yt_dlp_video.format) -- VBR: $($yt_dlp_video.vbr)" -showtime -logtype Youtube
                  }elseif($thisapp.config.Youtube_Quality -eq 'Low'){
                    $yt_dlp_video = ($yt_dlp.formats.where({$_.vbr -lt '1000'}) | Select-Object -last 1)
                    $video_url = ($yt_dlp_video).url
                    write-ezlogs "| Getting Low Quality Video $($yt_dlp_video.format) -- VBR: $($yt_dlp_video.vbr)" -showtime -logtype Youtube
                  } 
                }                                        
                if(Test-ValidPath $best_quality){
                  [Uri]$vlcurl = $best_quality 
                  $media_link = $vlcurl
                }elseif((Test-ValidPath $video_url) -and (Test-ValidPath $audio_url)){
                  $vlcurl = $Null
                  $media_link = $Null
                  write-ezlogs "| Video URL: $video_url" -showtime -logtype Youtube
                  write-ezlogs "| Audio URL: $audio_url" -showtime -logtype Youtube
                }else{
                  write-ezlogs "Unable to find right URL to use in $($yt_dlp | out-string) -- cannot continue" -showtime -warning -logtype Youtube
                  Update-Notifications -Level 'WARNING' -Message "Unable to find right correct URLs to use from yt-dlp cannot continue!" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold
                  $synchashWeak.Target.stop_media_timer.start()
                  return
                }
                #TODO:Sponserblock?
                <#              if($yt_dlp.sponsorblock_chapters){
                    $SponserBlock_Chapters = $yt_dlp.sponsorblock_chapters
                    }else{
                    $SponserBlock_Chapters = $Null
                }#>
              }
            }            
          }         
        }else{
          $vlcurl = $media_link
          $mediaType = 'Other'
        }
        if($media.duration_ms){
          $duration = $media.duration_ms
        }     
        $title = $media.title
      }elseif((Test-ValidPath $Media_link) -and ($media_link -match 'youtube.com|yewtu.be')){
        $mediaType = 'Youtube'
        write-ezlogs "| Media is type Youtube URL" -showtime
        $delay = $null
        #$media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
        #[Uri]$vlcurl = $Media_link
        [Uri]$vlcurl = $media[0]
        #$media_metadata = $media[1] | Convertfrom-json      
        $title = $media.title
        write-ezlogs "| Youtube URL Title: $title" -showtime
      }elseif($media_link -match 'streaming.mediaservices.windows.net'){
        $mediaType = 'Other'
        $delay = -2000000
        try{
          $newProc = [System.Diagnostics.ProcessStartInfo]::new($youtubedl_path)
          $newProc.WindowStyle = 'Hidden'
          $newProc.Arguments = "-f b -g $media_link --rm-cache-dir -o '*' -j"
          $newProc.UseShellExecute = $false
          $newProc.CreateNoWindow = $true
          $newProc.RedirectStandardOutput = $true
          $Process = [System.Diagnostics.Process]::Start($newProc)
          $media = $Process.StandardOutput.ReadToEnd() | Convertfrom-Json
        }catch{
          write-ezlogs "An exception occurred executing: $youtubedl_path" -catcherror $_
        }finally{
          if($Process -is [System.IDisposable]){
            $Process.dispose()
          }
        }
        if($verboselog){write-ezlogs " | Media Metadata: $media" -showtime}     
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
        write-ezlogs "| Media is type Local path" -showtime
        $mediaType = 'LocalMedia'
        if(-not [string]::IsNullOrEmpty($media.duration)){
          $duration = $media.duration
        }elseif(-not [string]::IsNullOrEmpty($media.SongInfo.duration_ms)){
          $duration = $media.SongInfo.duration_ms
        }else{
          try{
            $taginfo = [taglib.file]::create($media.url)
            if($taginfo.properties.duration){
              $duration = [timespan]::Parse($taginfo.properties.duration).TotalMilliseconds
            }else{
              $duration = 0
            }
          }catch{
            write-ezlogs "An exception occurred getting taginfo for $($media.url)" -showtime -catcherror $_
          }finally{
            if($taginfo -is [System.IDisposable]){
              [void]($taginfo.Dispose())
              $taginfo = $null
            }
          }
        }                   
        [Uri]$vlcurl = $($media_link)      
        if($thisApp.Config.Verbose_Logging){write-ezlogs "| Local Path Title: $title" -showtime}
      }elseif($media_link -eq $memory_Stream -and $media.source -eq 'TOR'){
        $mediaType = 'TOR'
        write-ezlogs "| Media is type TOR" -showtime
        [Uri]$vlcurl = $($media_link)     
        if($media.duration -eq '00:00:00' -and [system.io.file]::Exists($media.streaming_file)){
          try{
            write-ezlogs "| Checking torrent streaming file for duration using ffprobe: $($media.streaming_file)"
            $duration = $Null
            try{
              $newProc = [System.Diagnostics.ProcessStartInfo]::new("$($thisApp.Config.Current_Folder)\Resources\flac\ffprobe.exe")
              $newProc.WindowStyle = 'Hidden'
              $newProc.Arguments = "-i `"$($media.streaming_file)`" -show_entries format=duration -v quiet -of csv=`"p=0`" -sexagesimal"
              $newProc.UseShellExecute = $false
              $newProc.CreateNoWindow = $true
              $newProc.RedirectStandardOutput = $true
              $Process = [System.Diagnostics.Process]::Start($newProc)
            }catch{
              write-ezlogs "An exception occurred executing ffprobe on: $($media.streaming_file)" -catcherror $_
            }finally{
              if($Process.StandardOutput){
                $duration = $Process.StandardOutput.ReadToEnd()
              }
              if($Process -is [System.IDisposable]){
                $Process.dispose()
              }
            }
            #$duration = ffprobe -i $media.streaming_file -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal
            if($duration){
              write-ezlogs ">>>> Updating media duration: $duration" -logtype Tor
              $duration = [timespan]::parse($duration)
              if(-not [string]::IsNullOrEmpty($media.id) -and $synchashWeak.Target.All_Tor_Results.SyncRoot){
                lock-object -InputObject $synchashWeak.Target.All_Tor_Results.SyncRoot -ScriptBlock {
                  $media.duration = $duration
                }
              }
            }
          }catch{
            write-ezlogs "An exception occurred getting duration from $($media.streaming_file)" -catcherror $_
          }      
        }else{
          $duration = $media.duration
        }
        $title = $media.title
        $artist = $media.target
        write-ezlogs "| Unknown media type Title: $title" -showtime    
      }elseif(Test-ValidPath $Media_link){
        write-ezlogs "[OTHER_MEDIA] | Media is type: Other URL" -showtime
        $mediaType = 'Other'
        $duration = $media.duration
        if(Test-ValidPath $Media_link -Type URL){
          try{
            write-ezlogs "[OTHER_MEDIA] | Parsing media url with yt_dlp" -showtime
            $newProc = [System.Diagnostics.ProcessStartInfo]::new($youtubedl_path)
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "-f bv+ba/b $media_link --sponsorblock-remove all --sponsorblock-mark all --sponsorblock-chapter-title '`"[SponsorBlock]: %(category_names)l`"' --no-check-certificate --skip-download -j"
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $newProc.RedirectStandardOutput = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
            $yt_dlp = $Process.StandardOutput.ReadToEnd() | Convertfrom-Json
          }catch{
            write-ezlogs "An exception occurred executing: $streamlinkpath" -catcherror $_
          }finally{
            if($Process -is [System.IDisposable]){
              $Process.dispose()
            }
          }
          if($yt_dlp){
            $best_quality = $yt_dlp.url | Select-Object -last 1
            if(!$best_quality -and $yt_dlp.format){           
              $yt_dlp_audio = ($yt_dlp.formats.where({$_.abr -eq ($yt_dlp.formats | Measure-Object -Property abr -Maximum).Maximum}) | Select-Object -last 1)
              $audio_url = ($yt_dlp_audio).url
              write-ezlogs "[OTHER_MEDIA] | Getting Best available Quality Audio $($yt_dlp_audio.format) -- ABR: $($yt_dlp_audio.abr)" -showtime
              $yt_dlp_video = ($yt_dlp.formats.where({$_.height -le '720' -and $_.Height -gt '480'}) | Select-Object -last 1)
              if(!$yt_dlp_video){
                $yt_dlp_video = ($yt_dlp.formats.where({$_.vbr -gt '1000' -and $_.vbr -lt '2000'}) | Select-Object -last 1)
              }                  
              $video_url = ($yt_dlp_video).url
            }
            if(Test-ValidPath $best_quality){
              [Uri]$vlcurl = $best_quality 
              $media_link = $vlcurl
            }elseif((Test-ValidPath $video_url) -and (Test-ValidPath $audio_url)){
              $vlcurl = $Null
              $media_link = $Null
              write-ezlogs "[OTHER_MEDIA] | Video URL: $video_url" -showtime
              write-ezlogs "[OTHER_MEDIA] | Audio URL: $audio_url" -showtime
            }else{
              write-ezlogs "[OTHER_MEDIA] Unable to find right URL to use in $($yt_dlp)" -showtime -warning
              [Uri]$vlcurl = $($media_link)
            }
          }
        }else{
          [Uri]$vlcurl = $($media_link)
        }
        if($yt_dlp.title){
          $title = $yt_dlp.title
          if($title -and $media.title -and $media.title -ne $title){
            $media.title = $title
          }
        }else{
          $title = $media.title
        }
        write-ezlogs "[OTHER_MEDIA] | URL Media Title: $title" -showtime
      }else{
        $mediaType = 'Other'
        [Uri]$vlcurl = $($media_link)
        $duration = $null
        $title = $media.title
        write-ezlogs "| Uknown media type -- Title: $title" -showtime
        if($synchashWeak.Target.MiniPlayer_Viewer.isLoaded){
          try{
            Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local
            $startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"
            if($startapp){
              $appid = $startapp.AppID | Select-Object -last 1
            }elseif(Get-AllStartApps VLC*){
              $startapp = Get-AllStartApps VLC*
              $appid = $startapp.AppID | Select-Object -last 1
            }else{
              $startapp = Get-AllStartApps '*Windows Media Player'
              $appid = $startapp.AppID | Select-Object -last 1
            }
            New-BurntToastNotification -AppID $appid -Text "Cannot load unknown media or path is not available!`nURL: $vlcurl`nTitle: $title" -AppLogo "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
          }catch{
            write-ezlogs "An exception occurred attempting to generate the notification balloon - appid: $($appid)" -showtime -catcherror $_
          }     
        }else{
          Update-Notifications -Level 'ERROR' -Message "Unknown media or path is not available: $vlcurl" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout
        }       
        $synchashWeak.Target.Stop_media_timer.start()
        return      
      }    
      try{     
        if(Test-ValidPath $chat_url -Type URL){
          write-ezlogs "| Chat URL: $($chat_url)" -showtime -Dev_mode
          $synchashWeak.Target.ChatView_URL = $chat_url
          Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Navigate -ChatView_URL $synchashWeak.Target.ChatView_URL -show:$thisApp.Config.Chat_View
        }elseif($youtube_id -and $media_link -notmatch 'tv\.youtube\.com' -and $media.url -notmatch 'tv\.youtube\.com' -and $media.type -ne 'YoutubeTV' -and $thisApp.Config.Enable_YoutubeComments){
          $synchashWeak.Target.ChatView_URL = $Null
          Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Navigate -Youtube_ID $youtube_id -show:$thisApp.Config.Chat_View
        }else{
          $synchashWeak.Target.ChatView_URL = $Null
          Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Disable -Hide
        }
        if(!$synchashWeak.Target.Youtube_WebPlayer_URL -or $media_link -eq "dshow://"){  
          try{
            $audio_media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)flac|(?i)wav|(?i)3gp|(?i)aac))')  
            $vlcArgs = [System.Collections.Generic.List[String]]::new()
            [void]($vlcArgs.add('--file-logging'))
            [void]($vlcArgs.add("--logfile=$($thisapp.config.Vlc_Log_file)"))
            [void]($vlcArgs.add("--mouse-events"))
            [void]($vlcArgs.add("--log-verbose=$($thisapp.config.Vlc_Verbose_logging)"))
            [void]($vlcArgs.add("--osd"))
            #TODO: Add global gain to config
            [double]$doubleref = [double]::NaN
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Libvlc_Global_Gain) -and [double]::TryParse($thisApp.Config.Libvlc_Global_Gain,[ref]$doubleref)){
              write-ezlogs "| Applying custom global gain for libvlc: $($thisApp.Config.Libvlc_Global_Gain)" -logtype Libvlc -loglevel 2
              [void]($vlcArgs.add("--gain=$($thisApp.Config.Libvlc_Global_Gain)"))
            }else{
              write-ezlogs "| Setting default global gain for libvlc: 4" -logtype Libvlc -loglevel 2
              [void]($vlcArgs.add('--gain=4.0')) #Set gain to 4 which is default that VLC uses but for some reason libvlc does not
            }
            [void]($vlcArgs.add("--logmode=text"))

            #TODO: Add Video Output Module to config
            #Use opengl for windows with tone mapping set to 2 (Reinhard) to properly play HDR video on SDR displays         
            #[void]($vlcArgs.add("--vout=glwin32"))
            #[void]($vlcArgs.add('--tone-mapping=2'))

            #[void]$vlcArgs.add("--volume-step=2.56")
            #Sadly no audio filters work with libvlc, all are overridden by the built-in EQ - hopefully libvlc 4 will fix
            if($Enable_normalizer){
              [void]($vlcArgs.add("--audio-filter=normalizer"))
            }
            if($thisapp.config.Enable_EQ2Pass){
              [void]($vlcArgs.add("--equalizer-2pass"))
            }
            if($thisApp.Config.Use_Visualizations -and ($media_link -match $audio_media_pattern -or $vlcurl -match $audio_media_pattern)){ 
              #,"--no-video"
              [void]($vlcArgs.add("--video-on-top"))
              [void]($vlcArgs.add("--spect-show-original"))
              if($thisApp.Config.Current_Visualization -eq 'Spectrum'){        
                [void]($vlcArgs.add("--audio-visual=Visual"))
                [void]($vlcArgs.add("--effect-list=spectrum"))
              }else{
                [void]($vlcArgs.add("--audio-visual=$($thisApp.Config.Current_Visualization)"))
                [void]($vlcArgs.add("--effect-list=spectrum"))
              }             
              write-ezlogs ">>>> Configuring libvlc instance, with visualization: $($thisApp.Config.Current_Visualization)" -showtime -loglevel 2 -logtype Libvlc                                                      
            }else{  
              [void]($vlcArgs.add("--file-caching=1000"))
              write-ezlogs ">>>> Configuring libvlc instance, no visualization, file-caching=1000" -showtime -loglevel 2 -logtype Libvlc -linesbefore 1
            }                 
            if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
              try{
                $thisapp.config.vlc_Arguments -split ',' | & { process {                 
                    if([regex]::Escape($_) -match '--' -and $vlcArgs -notcontains $_){
                      write-ezlogs "| Adding custom Libvlc option: $($_)" -loglevel 2 -logtype Libvlc
                      [void]($vlcArgs.add("$($_)"))
                    }else{
                      write-ezlogs "Cannot add custom libvlc option $($_) - it does not meet the required format or is already added!" -warning -loglevel 2 -logtype Libvlc
                    }
                }}
              }catch{
                write-ezlogs "An exception occurred processing custom VLC arguments" -catcherror $_
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
              $synchashWeak.Target.libvlc = [LibVLCSharp.LibVLC]::new($libvlc_arguments)
            }else{
              $synchashWeak.Target.libvlc = [LibVLCSharp.Shared.LibVLC]::new($libvlc_arguments)
            }
            if($thisApp.Config.Enable_EQ -and $media_link -eq 'dshow://'){
              $useragent = "$($thisApp.Config.App_Name) Media Player - WebPlayer EQ"
            }else{
              $useragent = "$($thisApp.Config.App_Name) Media Player"
            }
            $synchashWeak.Target.libvlc.SetUserAgent($useragent,"HTTP/User/Agent")
            if($thisApp.Config.Installed_AppID){
              $appid = $thisApp.Config.Installed_AppID
            }else{
              $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID 
              $thisApp.Config.Installed_AppID = $appid
            }
            if($appid -and $synchashWeak.Target.libvlc){
              $synchashWeak.Target.libvlc.SetAppId($appid,$thisApp.Config.App_Version,"$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
            }
            if($thisApp.Config.Enable_EQ -and $media_link -eq 'dshow://'){
              write-ezlogs "| Enabling dshow capture of virtual audio cable for Youtube webplayer" -warning
              $allDevices = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::EnumerateDevices([CSCore.CoreAudioAPI.DataFlow]::All)
              $capture_device = $allDevices.where({$_.friendlyname -match 'CABLE Input \(VB-Audio Virtual Cable\)'})
              if($capture_device){
                Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchashWeak.Target -start -wait -Startlibvlc
              }else{
                write-ezlogs "Unable to find required 'CABLE Input (VB-Audio Virtual Cable)' audio device - cannot enable EQ for Webplayer!" -AlertUI -Warning -synchash $synchashWeak.Target
              }
            }                            
          }catch{
            write-ezlogs "An exception occurred disposing and creating a new libvlc instance" -showtime -catcherror $_
          }finally{
            if($allDevices -is [System.IDisposable]){
              $allDevices.dispose()
              $allDevices = $Null
            }
            if($capture_device -is [System.IDisposable]){
              $capture_device.Dispose()
              $capture_device = $null
            }
          }
        }
        try{      
          $synchashWeak.Target.Last_Played = $media.id
          $synchashWeak.Target.Current_playing_media = $media
          if($synchashWeak.Target.update_Queue_timer -and !$synchashWeak.Target.update_Queue_timer.isEnabled -and !$synchashWeak.Target.Playlists_Update_Timer.isEnabled){
            $synchashWeak.Target.update_Queue_timer.Tag = 'UpdatePlaylists'
            [void]$synchashWeak.Target.update_Queue_timer.start() 
          }                                      
        }catch{
          write-ezlogs "An exception occurred attempting update current playing media and queue" -showtime -catcherror $_
        }
        #TODO: POTENTIAL FEATURE - SCREEN RECORDING?? - Why tho?
        if($screenrecorder){
          $media_link = "screen://"
        }
        if(!$synchashWeak.Target.Youtube_WebPlayer_URL){
          if([string]::IsNullOrEmpty($duration)){
            if($yt_dlp.duration){
              $duration = $($([timespan]::FromSeconds($yt_dlp.duration)).TotalMilliseconds)
              write-ezlogs "| YTDLP Duration: $($yt_dlp.duration) - Parsed Duration $($duration)"
            }elseif($media.duration){
              $duration = $media.duration
              write-ezlogs "| media.duration: $($duration)"
            }
          }
          if(-not [string]::IsNullOrEmpty($duration)){
            try{            
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
              $synchashWeak.Target.MediaPlayer_TotalDuration = $total_seconds
              if($hrs -lt 1){
                $hrs = '0'
              }
              $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
              write-ezlogs "| Media Total Time: $($total_time)" -showtime -loglevel 3
            }catch{
              write-ezlogs "An exception occurred parsing duration time $($duration)" -showtime -catcherror $_
            }
          }else{
            $total_time = "00`:00`:00"
          } 
          write-ezlogs "| Duration/Total Time: $($total_time)" -showtime             
          $synchashWeak.Target.MediaPlayer_CurrentDuration = $total_time
          try{
            #TODO: Do something with quality information?
            if($yt_dlp_audio -and $yt_dlp_video){
              write-ezlogs "| Current Video Quality and format selected: $($yt_dlp_video.format) - TBR: $($yt_dlp_video.tbr)" -showtime
              write-ezlogs "| Current Audio Quality and format selected: $($yt_dlp_audio.format) - TBR: $($yt_dlp_audio.tbr)" -showtime
              $synchashWeak.Target.Current_Video_Quality = $yt_dlp_video.format
              $synchashWeak.Target.Current_Audio_Quality = $yt_dlp_audio.format
            }
            if($memory_stream -and $media.source -eq 'TOR'){
              Update-MainPlayer -thisApp $thisApp -synchash $synchashWeak.Target -New_MediaPlayer -Now_Playing_Label "PLAYING" -memory_stream $memory_stream -Now_Playing_Title $title -Now_Playing_Artist "$($Artist)" -Add_VideoView
            }else{
              Update-MainPlayer -synchash $synchashWeak.Target -thisApp $thisApp -Now_Playing_Label "PLAYING" -Now_Playing_Artist "$($Artist)" -Now_Playing_Title $title -Add_VideoView -New_MediaPlayer -video_url $video_url -vlcurl $vlcurl -media_link $media_link -audio_url $audio_url -Saved_Media_Progress $Saved_Media_Progress -start_Paused:$start_Paused -Live_stream:$Live_stream -EnableCasting:$EnableCasting -Subtitles_Path $Subtitles_Path   
            }                                       
          }catch{
            write-ezlogs "An exception occurred starting vlc playback" -showtime -catcherror $_
            Update-Notifications -Level 'ERROR' -Message "An exception occurred starting vlc playback: $_" -VerboseLog -thisApp $thisApp -synchash $synchashWeak.Target -Open_Flyout
            return
          }         
          $play_timeout = 0
          $streamlink_wait_timer = 1    
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $mediaplaying_state = $synchashWeak.Target.vlc.state -ne 'Playing'
          }else{
            $mediaplaying_state = $synchashWeak.Target.vlc.media.state -ne 'Playing'
          }               
          while(!$synchashWeak.Target.VLC_IsPlaying_State -and $play_timeout -lt 60 -and !$start_Paused -and !$synchashWeak.Target.VLC_PlaybackCancel -and $mediaplaying_state){
            try{
              $play_timeout++
              $streamlink_wait_timer++
              if($thisApp.Config.Libvlc_Version -eq '4'){
                $synchashWeak.Target.VLC_IsPlaying_State = $synchashWeak.Target.vlc.state -eq 'Playing'
                $mediaplaying_state = $synchashWeak.Target.vlc.state -ne 'Playing'
                $State = $synchashWeak.Target.vlc.state
              }else{
                $State = $synchashWeak.Target.vlc.media.state
                $mediaplaying_state = $synchashWeak.Target.vlc.media.state -ne 'Playing'
                $synchashWeak.Target.VLC_IsPlaying_State = $synchashWeak.Target.vlc.media.state -eq 'Playing'
              }         
              write-ezlogs "| Waiting for VLC to begin playing...VLC_IsPlaying_State: $($synchashWeak.Target.VLC_IsPlaying_State) -- VLC_PlaybackCancel: $($synchashWeak.Target.VLC_PlaybackCancel): play_timeout: $play_timeout" -showtime
              if($media.url -match 'twitch\.tv' -and $streamlink_wait_timer -and $streamlink_wait_timer -eq 100){
                write-ezlogs "Checking streamlink as it should have started by now" -showtime -warning
                try{   
                  write-ezlogs "| Current Loaded VLC Media $($synchashWeak.Target.vlc.media.mrl)" -loglevel 2
                  if($State -eq 'ENDED' -and $synchashWeak.Target.VLC.media.mrl -eq $($synchashWeak.Target.streamlink_HTTP_URL)){
                    write-ezlogs "| Media state is ENDED, Attempting to execute Play() again on media" -LogLevel 2
                    [void]($synchashWeak.Target.VLC.Play())
                  }         
                  <#              if([system.io.file]::Exists($thisApp.Config.Streamlink_Log_File)){
                      write-ezlogs "| Reading current streamlink log $($thisApp.Config.Streamlink_Log_File)" -showtime
                      Get-Content -Path $thisApp.Config.Streamlink_Log_File -force -Tail 5 | foreach{
                      write-ezlogs "[STREAMLINK_LOG] $_" -showtime -logtype Twitch
                      if($_ -match 'Waiting for pre-roll ads to finish'){
                      write-ezlogs "Streamlink indicates it is waiting for pre-roll ads to finish, resetting streamlink timer to wait longer" -showtime -warning -loglevel 2
                      Update-MainPlayer -synchash $synchashWeak.Target -thisApp $thisApp -Now_Playing_Title "LOADING...Waiting for Pre-Roll ADs to Finish..." -Clear_DisplayPanel_Bitrate -Clear_Now_Playing_Artist
                      $streamlink_wait_timer = 1
                      continue
                      }elseif($_ -match 'Unable to open URL'){
                      write-ezlogs "Streamlink indicates an error opening the stream URL" -showtime -warning
                      $synchashWeak.Target.ForceUseYTDLP = $true
                      }
                      }
                  }#>
                  if(!([System.Diagnostics.Process]::GetProcessesByName('streamlink'))){
                    write-ezlogs "Streamlink process cannot be found or hasnt started yet" -warning
                    Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -twitch_disable_ads $twitch_disable_ads -Twitch_oauth $Twitch_oauth -media $media -Use_Runspace
                    start-sleep -Seconds 1
                    <#                    if($waithandle.target.runspace.AsyncWaitHandle){
                        [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(1000)
                        }else{
                        start-sleep -Milliseconds 1000
                    }#>
                    continue
                  }elseif($streamlink_wait_timer -gt 12){
                    write-ezlogs "| Streamlink process is running, but seems to not be responding, attempting to restart" -showtime -warning
                    Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -twitch_disable_ads $twitch_disable_ads -Twitch_oauth $Twitch_oauth -media $media -Use_Runspace
                    continue
                  }elseif($synchashWeak.Target.vlc.media.Mrl -match $($synchashWeak.Target.streamlink_HTTP_URL) -and $State -eq 'Ended'){
                    write-ezlogs "There may have been a delay between when streamlink and liblvlc were ready..executing Play on loaded meda" -warning
                    [void]($synchashWeak.Target.VLC.Play())
                  } 
                }catch{
                  write-ezlogs "An execption occurred processsing streamlink log $($thisApp.Config.Streamlink_Log_File)" -showtime -catcherror $_
                }
                try{              
                  $streamlinkjson = streamlink $media.url "best,720p,480p" --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --logfile $($thisApp.Config.Streamlink_Log_File) --retry-streams 1 --retry-max 10 --twitch-disable-ads --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data --twitch-low-latency --json
                  if($streamlinkjson){
                    $streamlinkinfo = $streamlinkjson | convertfrom-json
                    $synchashWeak.Target.streamlinkerror = $streamlinkinfo.error
                    write-ezlogs "| StreamlinkInfo: $($streamlinkinfo | out-string)" -loglevel 2
                    #Start-Streamlink -synchash $synchashWeak.Target -thisApp $thisApp -twitch_disable_ads $twitch_disable_ads -Twitch_oauth $Twitch_oauth -media $media -Use_Runspace
                    continue
                  }else{
                    write-ezlogs "No info returned when checking url $($media.url) from streamlink" -warning
                    if($synchashWeak.Target.ForceUseYTDLP_Count -lt 1){
                      $synchashWeak.Target.ForceUseYTDLP = $true
                      write-ezlogs "Will attempt to use YTDLP vs streamlink on the next retry for $($media.url)" -showtime -warning                               
                      $synchashWeak.Target.ForceUseYTDLP_Count++ 
                      $synchashWeak.Target.Start_media = $Media
                      $synchashWeak.Target.start_media_timer.start()
                    }
                  }
                }catch{
                  write-ezlogs "An exception occurred relaunching Start-Media" -showtime -catcherror $_
                }             
              }elseif(($play_timeout -eq 20 -or $play_timeout -eq 25) -and $State -ne 'Opening'){
                write-ezlogs "| Playback still hasnt starting, attempting to execute Update-MainPlayer again for vlc media: $($synchashWeak.Target.vlc.media.mrl)" -showtime -warning
                Update-MainPlayer -synchash $synchashWeak.Target -thisApp $thisApp -Now_Playing_Label "PLAYING" -Now_Playing_Artist "$($Artist)" -Add_VideoView -New_MediaPlayer -video_url $video_url -vlcurl $vlcurl -media_link $media_link -audio_url $audio_url -Saved_Media_Progress $Saved_Media_Progress -start_Paused:$start_Paused -EnableCasting:$EnableCasting -Live_stream:$Live_stream          
              }
            }catch{
              write-ezlogs "An exception occurred in playback waiting loop" -CatchError $_
            }finally{
              start-sleep -Seconds 1
              <#              if($waithandle.target.runspace.AsyncWaitHandle){
                  [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(1000)
                  }else{
                  start-sleep -Seconds 1
              }#>
            }
          }
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $playing_state = $synchashWeak.Target.vlc.state -eq 'Playing'
          }else{
            $playing_state = $synchashWeak.Target.vlc.media.state -eq 'Playing'
          }
          if($synchashWeak.Target.VLC_IsPlaying_State -or $start_Paused -or $playing_state){
            write-ezlogs ">>>> LibVLC is now playing"
            $synchashWeak.Target.VLC_IsPlaying_State = $true
            if($SponserBlock_Chapters){
              Update-MainPlayer -synchash $synchashWeak.Target -thisApp $thisApp -video_url $video_url -vlcurl $vlcurl -media_link $media_link -audio_url $audio_url -SponserBlock $SponserBlock_Chapters
            }          
            $synchashWeak.Target.Last_Played = $media.id
            try{
              if($media.source -eq 'Local' -and $media.url){
                $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile") 
                $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
                write-ezlogs ">>>> Getting local media metadata" -Dev_mode
                $songinfo = Get-SongInfo -path $media.url -use_FFPROBE_Fallback
                if($songinfo){
                  foreach($s in $media){
                    try{
                      $profile_To_Update = Get-MediaProfile -thisApp $thisApp -synchash $synchashWeak.Target -Media_ID $media.id
                    }catch{
                      $profile_To_Update = $Null
                    }    
                    if(-not [string]::IsNullOrEmpty($Songinfo.title) -and $s.title -ne $Songinfo.title){
                      $s.title = $Songinfo.title
                      if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.title -ne $Songinfo.title){
                        write-ezlogs  ">>>> Updating media profile title from '$($profile_To_Update.title)' to '$($Songinfo.title)'"
                        $profile_To_Update.title = $Songinfo.title
                        $updateProfile = $true
                      }
                    } 
                    if(-not [string]::IsNullOrEmpty($songinfo.duration)){
                      try{
                        $Timespan = [timespan]::Parse($songinfo.duration)
                        if($Timespan){
                          $updated_duration = "$(([string]$timespan.Hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
                        }                
                      }catch{
                        write-ezlogs "An exception occurred parsing timespan for duration $duration" -showtime -catcherror $_
                        $error.clear()
                      } 
                      if(-not [string]::IsNullOrEmpty($updated_duration) -and $s.duration -ne $updated_duration){                       
                        $s.duration = $updated_duration
                        $synchashWeak.Target.MediaPlayer_TotalDuration = $timespan.TotalSeconds
                        $synchashWeak.Target.MediaPlayer_CurrentDuration = $updated_duration
                        $duration = $updated_duration
                        write-ezlogs "| Found updated media duration: $($updated_duration)"
                        if(-not [string]::IsNullOrEmpty($profile_To_Update.duration) -and $profile_To_Update.duration -ne $updated_duration){
                          write-ezlogs  "| Updating media profile duration from '$($profile_To_Update.duration)' to '$($updated_duration)'"
                          $profile_To_Update.duration = $updated_duration
                          $updateProfile = $true
                        }
                      }                                             
                    }
                    if(-not [string]::IsNullOrEmpty($Songinfo.Artist) -and $s.Artist -ne $Songinfo.Artist){
                      #$s.artist = (Get-Culture).TextInfo.ToTitleCase($Songinfo.Artist).trim()      
                      $s.artist = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($Songinfo.Artist).trim()
                      if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.artist -ne $Songinfo.Artist){
                        write-ezlogs  "| Updating media profile artist from '$($profile_To_Update.artist)' to '$($s.artist)'"
                        $profile_To_Update.Artist = $s.artist
                        $updateProfile = $true
                      }     
                    } 
                    if(-not [string]::IsNullOrEmpty($Songinfo.Album) -and $s.Album -ne $Songinfo.Album){
                      #$s.Album = (Get-Culture).TextInfo.ToTitleCase($Songinfo.Album).trim()
                      $s.Album = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($Songinfo.Album).trim()
                      if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.Album -ne $Songinfo.Album){
                        write-ezlogs  "| Updating media profile Album from '$($profile_To_Update.Album)' to '$($s.Album)'"
                        $profile_To_Update.Album = $s.Album
                        $updateProfile = $true
                      }                          
                    }
                    if(-not [string]::IsNullOrEmpty($Songinfo.hasVideo) -and [string]::IsNullOrEmpty($s.hasVideo)){
                      $s.hasVideo = $Songinfo.hasVideo    
                      if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.hasVideo -ne $Songinfo.hasVideo){
                        write-ezlogs  "| Updating media profile hasVideo from '$($profile_To_Update.hasVideo)' to '$($s.hasVideo)'"
                        $profile_To_Update.hasVideo = $s.hasVideo
                        $updateProfile = $true
                      }              
                    }  
                    if(-not [string]::IsNullOrEmpty($Songinfo.PictureData) -and [string]::IsNullOrEmpty($s.PictureData)){
                      $s.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('PictureData',$Songinfo.PictureData))
                      if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.PictureData -ne $Songinfo.PictureData){
                        write-ezlogs  "| Updating media profile PictureData from '$($profile_To_Update.PictureData)' to '$($s.PictureData)'"
                        $profile_To_Update.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('PictureData',$Songinfo.PictureData))
                        $updateProfile = $true
                      }          
                    } 
                    #Bitrate
                    if([string]::IsNullOrEmpty($s.bitrate) -or $s.bitrate -eq '0'){
                      write-ezlogs ">>>> Attempting to get bitrate via ffprobe format"
                      try{
                        $newProc = [System.Diagnostics.ProcessStartInfo]::new("$($thisApp.Config.Current_Folder)\Resources\flac\ffprobe.exe")
                        $newProc.WindowStyle = 'Hidden'
                        $newProc.Arguments = "-hide_banner -loglevel error -show_optional_fields always -show_entries format -print_format json `"$($s.url)`""
                        $newProc.UseShellExecute = $false
                        $newProc.CreateNoWindow = $true
                        $newProc.RedirectStandardOutput = $true
                        $Process = [System.Diagnostics.Process]::Start($newProc) 
                      }catch{
                        write-ezlogs "An exception occurred executing ffprobe" -catcherror $_
                      }finally{
                        if($Process.StandardOutput){
                          $ffprobe = $Process.StandardOutput.ReadToEnd() | convertfrom-json
                        }
                        if($Process -is [System.IDisposable]){
                          $Process.dispose()
                        }
                      }
                      #$ffprobe = ffprobe -hide_banner -loglevel error -show_optional_fields always -show_entries format -print_format json $s.url | convertfrom-json
                      if($ffprobe.format.bit_rate){
                        $s.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('bitrate',(Convert-Size -From Bytes -To KB -Value $ffprobe.format.bit_rate -Precision 2)))
                        write-ezlogs "| Found media bitrate: $($s.bitrate) kbps"
                        if(-not [string]::IsNullOrEmpty($profile_To_Update) -and $profile_To_Update.bitrate -ne $s.bitrate){
                          write-ezlogs  "| Updating media profile bitrate from '$($profile_To_Update.bitrate)' to '$($s.bitrate)'"
                          $profile_To_Update.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('bitrate',$s.bitrate))
                          $updateProfile = $true
                        }
                      }
                    }
                    if($updateProfile -and $synchashWeak.Target.All_local_Media){
                      write-ezlogs ">>>> Saving updating media in all media profle $AllMedia_Profile_File_Path"
                      Export-SerializedXML -InputObject $synchashWeak.Target.All_local_Media -Path $AllMedia_Profile_File_Path
                      #Export-Clixml -InputObject ($synchashWeak.Target.All_local_Media) -Path $AllMedia_Profile_File_Path -Force -Encoding Default
                    }
                  }               
                }
              }            
            }catch{
              write-ezlogs "An exception occurred executing Get-SongInfo for media $($media | out-string)" -catcherror $_
            }
            $synchashWeak.Target.Current_playing_media = $media

            #TODO: Set Audio Tracks
            #$synchashWeak.Target.vlc_audiotrack_timer.start()

            if(!$start_Paused -and !$SponserBlock_Chapters){
              write-ezlogs ">>>> Starting Media Timer"
              $synchashWeak.Target.Timer.Start()
            }elseif($SponserBlock_Chapters){
              $SponserBlock_timeout = 0
              #$synchashWeak.Target.vlc.IsPlaying           
              while(!$synchashWeak.Target.VLC_IsPlaying_State -and $SponserBlock_timeout -lt 60 -and !$synchashWeak.Target.VLC_IsPlaying_State){
                $SponserBlock_timeout++
                write-ezlogs "| Waiting for playback to resume after sponserblock skip..."
                if($thisApp.Config.Libvlc_Version -eq '4'){
                  $synchashWeak.Target.VLC_IsPlaying_State = $synchashWeak.Target.vlc.state -eq 'Playing'
                }else{
                  $synchashWeak.Target.VLC_IsPlaying_State = $synchashWeak.Target.vlc.media.state -eq 'Playing'
                }
                start-sleep -Milliseconds 500
                <#                if($waithandle.target.runspace.AsyncWaitHandle){
                    [void]$waithandle.target.runspace.AsyncWaitHandle.WaitOne(500)
                    }else{
                    start-sleep -Milliseconds 500
                }#>
              }
              write-ezlogs ">>>> Starting Media Timer"
              [void]($synchashWeak.Target.Timer.Start())
            }     
          }
        }
        if(-not [string]::IsNullOrEmpty($Media.profile_image_url)){
          $image = $($Media.profile_image_url | Select-Object -First 1)
          $decode_Width = "300"
        }elseif((Test-ValidPath $Media.cached_image_path -Type URLorFile)){
          $decode_Width = "300"
          $image = $Media.cached_image_path
        }elseif((Test-ValidPath $Media.cached_image -Type URLorFile)){
          $decode_Width = "300"
          $image = $Media.cached_image
        }elseif(-not [string]::IsNullOrEmpty($synchashWeak.Target.streamlink.profile_image_url)){
          $image = $($synchashWeak.Target.streamlink.profile_image_url | Select-Object -First 1)
          $decode_Width = "300"
        }elseif(-not [string]::IsNullOrEmpty($synchashWeak.Target.streamlink.offline_image_url)){
          $image = $($synchashWeak.Target.streamlink.offline_image_url | Select-Object -First 1)
          $decode_Width = "300"
        }elseif(-not [string]::IsNullOrEmpty($Media.offline_image_url)){
          $image = $($Media.offline_image_url | Select-Object -First 1)
          $decode_Width = "300"
        }elseif(-not [string]::IsNullOrEmpty($Media.cover_art)){
          $decode_Width = "300"
          $image = $($Media.Cover_art | Select-Object -First 1)
        }elseif(-not [string]::IsNullOrEmpty((($Media.images).psobject.Properties.Value).url)){
          $decode_Width = "300"
          $image = $((($Media.images).psobject.Properties.Value).url.where({$_ -match 'maxresdefault.jpg'}) | Select-Object -First 1)
          if(!$image){
            $image = (($Media.images).psobject.Properties.Value).url.where({$_ -match 'original.jpg'}) | Select-Object -First 1
          }
          write-ezlogs "| Media Image: $($image)" -showtime
        }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){
          $decode_Width = "300"
          $image = $($Media.thumbnail | Select-Object -First 1)
        }else{
          $image = $null
        } 
        $image_Cache_path = $Null
        if(!([System.IO.Directory]::Exists("$($thisApp.config.image_Cache_path)\$mediaType"))){
          write-ezlogs "| Creating $mediaType image cache directory: $($thisApp.config.image_Cache_path)\$mediaType" -showtime -loglevel 2
          [void][System.IO.Directory]::CreateDirectory("$($thisApp.config.image_Cache_path)\$mediaType")
        }
        if([system.io.file]::Exists($media_link)){
          try{
            $taginfo = [taglib.file]::create($media_link) 
            if($thisApp.Config.Verbose_logging){write-ezlogs "| Tag Picture: $($taginfo.tag.pictures | out-string)" -showtime}
            if($taginfo.tag.pictures){
              $cached_image = ($taginfo.tag.pictures | Select-Object -first 1).data.data
              if($cached_image){
                $cached_image_isByte = $true
                $decode_Width = '300'
                write-ezlogs "Cached image from taginfo type $($cached_image.gettype())" -Dev_mode
              }
            }
          }catch{
            write-ezlogs "An exception occurred getting taginfo for $($media.URL)" -showtime -catcherror $_
          }finally{
            if($taginfo -is [System.IDisposable]){
              [void]($taginfo.Dispose())
              $taginfo = $null
            }
          }
        }elseif($image){      
          if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
            if($thisApp.Config.dev_mode){write-ezlogs "Creating image cache directory: $($thisApp.config.image_Cache_path)" -Dev_mode}
            [void][System.IO.Directory]::CreateDirectory($thisApp.config.image_Cache_path)
          }                   
          $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),$mediaType,"$($media.id).png")
          if([System.IO.File]::Exists($image_Cache_path)){
            $cached_image = $image_Cache_path
          }elseif($image){         
            if($thisApp.Config.dev_mode){write-ezlogs "| Destination path for cached image: $image_Cache_path" -Dev_mode}
            if(!([System.IO.File]::Exists($image_Cache_path))){
              try{
                if([System.IO.File]::Exists($image)){
                  if($thisApp.Config.dev_mode){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -Dev_mode}
                  [void][system.io.file]::Copy($image, $image_Cache_path,$true)
                }else{
                  try{
                    $uri = [system.uri]::new($image)
                    if($thisApp.Config.dev_mode){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -Dev_mode}
                    $webclient = [System.Net.WebClient]::new()
                    [void]($webclient.DownloadFile($uri,$image_Cache_path))
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
                  $image.DecodePixelWidth = $decode_Width
                  $image.StreamSource = $stream_image
                  $image.EndInit()
                  $stream_image.Close()
                  $stream_image.Dispose()
                  $stream_image = $null
                  $image.Freeze()
                  if($thisApp.Config.Dev_mode){write-ezlogs "Saving decoded media image to path $image_Cache_path" -Dev_mode}
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
                write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -catcherror $_
              }
            }           
          }else{
            write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -warning
            $cached_image = $Null        
          }                                    
        }
        if($media.url -match 'twitch\.tv'){          
          $source = 'Twitch Stream'
          $iconkind = 'Twitch'
          $iconcolor = '#FFA970FF'
          if($Media.profile_image_url){
            $applogo = $Media.profile_image_url
          }elseif($Media.thumbnail){
            $applogo = $($Media.thumbnail | Select-Object -First 1)
          }else{
            $applogo = "$($thisApp.Config.Current_folder)\Resources\Twitch\Material-Twitch.png"
          }
        }elseif($media.type -in $Supported_Youtube_Types -or $media.Source -eq 'Youtube' -or $media.url -match 'Youtube\.com' -or $media.url -match 'youtu\.be'){
          $source = 'Youtube Media'
          $iconkind = 'Youtube'
          $iconcolor = '#FFFF0000'
          if($Media.images.url){
            $applogo = $Media.images.url | Select-Object -first 1
          }elseif($cached_image){
            $applogo = $cached_image
          }else{              
            $applogo = "$($thisApp.Config.Current_folder)\Resources\Youtube\Material-Youtube.png"
          }
        }else{
          $source = 'Local Media'
          $iconkind = 'Harddisk'
          $iconcolor = '#FFF48100' 
          $default_Icon = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),'LocalMedia',"$($iconkind).png")
          if(!([System.IO.Directory]::Exists("$($thisApp.config.image_Cache_path)\LocalMedia"))){
            if($thisApp.Config.Dev_mode){write-ezlogs "| Creating local media image cache directory: $($thisApp.config.image_Cache_path)\LocalMedia" -Dev_mode}
            [void][System.IO.Directory]::CreateDirectory("$($thisApp.config.image_Cache_path)\LocalMedia")
          }
          if($cached_image_isByte){
            $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),'LocalMedia',"$($media.id).png")
            if(!([System.IO.File]::Exists($image_Cache_path))){
              write-ezlogs ">>>> Saving new image from taginfo to path: $image_Cache_path"
              $BinaryWriter = [System.IO.BinaryWriter]::new([System.IO.File]::create($image_Cache_path))
              $BinaryWriter.Write($cached_image)
              $BinaryWriter.Close()
              $binarywriter.Dispose() 
            }else{
              write-ezlogs ">>>> Using previously cached image from taginfo from path: $image_Cache_path" -Dev_mode
            }
            $cached_image = $image_Cache_path
            $applogo = $image_Cache_path      
          }elseif([System.IO.File]::Exists($cached_image)){
            $applogo = $cached_image 
          }elseif([system.IO.File]::Exists($default_Icon)){
            $applogo = $default_Icon
          }else{
            #VLC Icon
            write-ezlogs ">>>> Using Default Local Media icon for media image"
            $applogo = "$($thisApp.Config.Current_Folder)\Resources\Images\Harddisk.png"   
          }                      
        }       
        if($cached_image){
          if([bool]($cached_image -is [Byte[]]) -and [System.IO.File]::Exists($applogo)){
            $Background_cached_image = $applogo
          }elseif([System.IO.File]::Exists($cached_image)){
            $Background_cached_image = $cached_image
            if($media.cached_image_path -ne $cached_image){
              $media.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('cached_image_path',$cached_image))
            }
          }elseif([System.IO.File]::Exists($applogo)){
            $Background_cached_image = $applogo 
          }elseif($cached_image){
            $Background_cached_image = $cached_image
          }      
        }elseif($applogo){
          $Background_cached_image = $Null
          $Background_default_image = $applogo
        }else{
          $Background_cached_image = $null
        } 
        if([System.IO.File]::Exists($Background_cached_image)){
          $stamped_image = Merge-Images -synchash $synchashWeak.Target -thisApp $thisApp -LargeImage $Background_cached_image -StampIcon $iconkind -StampIcon_Pack "PackIconMaterial" -StampIcon_Color $iconcolor -decode_Width $decode_Width
        }else{
          $stamped_image = $null
        }
        if([System.IO.File]::Exists($stamped_image)){
          $Background_cached_image = $stamped_image
        }
        if($thisApp.Config.Enable_AudioMonitor){
          Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchashWeak.Target -Action Begin
        }
        if($synchashWeak.Target.VLC_IsPlaying_State -or ($use_WebPlayer -and $synchashWeak.Target.Youtube_WebPlayer_URL) -or $start_Paused){       
          $synchashWeak.Target.Media_Current_Title = "$title"
          $synchashWeak.Target.Last_Played = $media.id
          $synchashWeak.Target.Current_playing_media = $media
          if($synchashWeak.Target.EQ_Timer){
            $synchashWeak.Target.EQ_Timer.tag = 'StartMedia'
            $synchashWeak.Target.EQ_Timer.start()  
          }
          Update-MediaState -thisApp $thisApp -synchash $synchashWeak.Target -Background_cached_image $Background_cached_image -Background_default_image $Background_default_image
        }elseif($play_timeout -ge 60){
          write-ezlogs "Timedout waiting for VLC media to begin playing: $($Media.URL)!" -showtime -warning -AlertUI -synchash $synchashWeak.Target
          $synchashWeak.Target.Stop_media_timer.start()
          return
        }
        if($thisApp.config.Show_notifications){
          try{
            Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local
            $startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"
            if($startapp){
              $appid = $startapp.AppID | Select-Object -last 1          
            }elseif(Get-AllStartApps VLC*){
              $startapp = Get-AllStartApps VLC*
              $appid = $startapp.AppID | Select-Object -last 1
            }else{
              $startapp = Get-AllStartApps '*Windows Media Player'
              $appid = $startapp.AppID | Select-Object -last 1
            }
            if($synchashWeak.Target.MediaPlayer_CurrentDuration){
              $Message = "Media : $($title)`nPlay Duration : $($synchashWeak.Target.MediaPlayer_CurrentDuration)`nSource : $source"
            }else{
              $Message = "Media : $($title)`nSource : $source"
            }
            New-BurntToastNotification -AppID $appid -Text "$Message" -AppLogo $applogo
          }catch{
            write-ezlogs "An exception occurred attempting to generate the notification balloon - appid: $($appid) - applogo: $($applogo) - message: $($Message)" -showtime -catcherror $_
          }
        }   
      }catch{
        write-ezlogs "An exception occurred attempting to play media $($media | out-string)" -showtime -catcherror $_
      }  
    }  
  }
  $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  $Runspace_Args = @{
    'scriptblock' = $synchashWeak.Target.vlc_scriptblock
    'Variable_list' = $Variable_list
    'thisApp' = $thisApp
    'synchash' = $synchashWeak.Target
    'runspace_name' = 'Vlc_Play_media'
    'RestrictedRunspace' = $true
    'function_list' = 'write-ezlogs',
    'Import-SerializedXML',
    'Export-SerializedXML',
    'Get-AllStartApps',
    'Update-MediaState',
    'Get-SpectrumAnalyzer',
    'Update-MediaTransportControls',
    'Merge-Images',
    'Get-MediaProfile',
    'Get-SongInfo',
    'Update-PlayQueue',
    'Get-TwitchAPI',
    'Get-TwitchVideos',
    'Get-TwitchStatus',
    'Update-TwitchStatus',
    'Set-YoutubeWebPlayerTimer',
    'Get-YoutubeURL',
    'Update-Notifications',
    'Update-MainWindow',
    'Start-Streamlink',
    'Start-Runspace',
    'Update-ChatView',
    'Update-MainPlayer',
    'Test-ValidPath'
    'verboselog' = $verboselog
    'ApartmentState' = 'STA'
  }
  Start-Runspace @Runspace_Args
  #Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchashWeak.Target -logfile $thisApp.Config.Log_file -runspace_name "Vlc_Play_media" -thisApp $thisApp -ApartmentState STA
  $Variable_list = $Null
  if($Start_Media_Measure){
    $Start_Media_Measure.stop()
    write-ezlogs "Start-Media Measure" -PerfTimer $Start_Media_Measure
  }
}
#---------------------------------------------- 
#endregion Start-Media Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-Streamlink Function
#----------------------------------------------
function Start-Streamlink {
  Param (
    $synchash,
    $thisApp,
    [switch]$Youtube,
    [switch]$TwitchVOD,
    [switch]$wait,
    $twitch_disable_ads,
    $Twitch_oauth,
    [switch]$Use_Runspace,
    [switch]$AllowMultiple,
    [string]$RunspaceName,
    [string]$CallPath = $callpath,
    $media,
    [switch]$fallBack_YTDLP,
    [switch]$close,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    $streamlinkblock = {
      Param (
        $synchash,
        $thisApp,
        [switch]$Youtube,
        [switch]$TwitchVOD,
        [switch]$wait,
        $twitch_disable_ads,
        $Twitch_oauth,
        [switch]$Use_Runspace,
        [switch]$AllowMultiple,
        [string]$RunspaceName,
        [string]$CallPath,
        $media,
        [switch]$fallBack_YTDLP,
        [switch]$close,
        [switch]$verboselog,
        [switch]$Startup
      )
      $SProcess = [System.Diagnostics.Process]::GetProcessesByName('streamlink')
      if($SProcess -and !$thisApp.Config.Dev_mode -and !$AllowMultiple){
        write-ezlogs ">>>> Closing existing streamlink process before starting new" -loglevel 2 -warning -logtype Twitch
        foreach($p in $SProcess){
          $p.kill()
          $p.dispose()
        }
      }
      $paths = [Environment]::GetEnvironmentVariable('Path') -split ';'
      $paths2 = $env:path -split ';'
      if([system.io.file]::Exists("${env:ProgramFiles(x86)}\Streamlink\bin\streamlink.exe")){
        $streamlinkpath = "${env:ProgramFiles(x86)}\Streamlink\bin\streamlink.exe"
      }elseif([system.io.file]::Exists("$env:ProgramW6432\Streamlink\bin\streamlink.exe")){
        $streamlinkpath = "$env:ProgramW6432\Streamlink\bin\streamlink.exe"
      }
      <#      if($streamlinkpath -notin $paths2){
          write-ezlogs ">>>> Adding streamlink to user enviroment path: $streamlinkpath"
          $env:path += ";$streamlinkpath"
          if($streamlinkpath -notin $paths){
          [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$streamlinkpath",[EnvironmentVariableTarget]::User)
          }
      }#>
      
      #Streamlink port
      if(-not [string]::IsNullOrEmpty($thisApp.Config.Streamlink_HTTP_Port)){
        $Streamlink_Port = $thisApp.Config.Streamlink_HTTP_Port
      }else{
        $Streamlink_Port = '53888'
      }
      if([system.io.file]::Exists($streamlinkpath) -and $TwitchVOD){
        try{
          if($thisApp.Config.Twitch_Quality -eq 'Best'){
            $qualities = "best,1080p60,1080p,720p60,720p,480p"
          }elseif($thisApp.Config.Twitch_Quality -eq '1080p'){
            $qualities = "1080p,720p60,720p,480p"
          }elseif($thisApp.Config.Twitch_Quality -eq '720p'){
            $qualities = "720p60,720p,480p"
          }elseif($thisApp.Config.Twitch_Quality -eq '480p'){
            $qualities = "480p,worst"
          }elseif($thisApp.Config.Twitch_Quality -eq 'worst'){
            $qualities = "worst"
          }elseif($thisApp.Config.Twitch_Quality -eq 'audio_only'){
            $qualities = "audio_only"
          }else{
            $qualities = "best,1080p60,1080p,720p60,720p,480p"
          }
          $newProc = [System.Diagnostics.ProcessStartInfo]::new($streamlinkpath)
          $newProc.WindowStyle = 'Hidden'
          $newProc.Arguments = "$($media.url) $qualities --stream-url --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --hls-segment-queue-threshold 4 --hls-playlist-reload-attempts 4 --retry-max 10"
          $newProc.UseShellExecute = $false
          $newProc.CreateNoWindow = $true
          $newProc.RedirectStandardOutput = $true
          $Process = [System.Diagnostics.Process]::Start($newProc)
          $synchash.streamlink_HTTP_URL = $Process.StandardOutput.ReadToEnd()
          write-ezlogs "| Twitch VOD stream url: $($synchash.streamlink_HTTP_URL)"
        }catch{
          write-ezlogs "An exception occurred executing svcl" -catcherror $_
        }finally{
          if($Process -is [System.IDisposable]){
            $Process.dispose()
          }
        }
      }elseif([system.io.file]::Exists($streamlinkpath) -and !$Youtube){
        if($thisApp.Config.Twitch_Quality -eq 'Best'){
          $qualities = "best,1080p60,1080p,720p60,720p,480p"
        }elseif($thisApp.Config.Twitch_Quality -eq '1080p'){
          $qualities = "1080p,720p60,720p,480p"
        }elseif($thisApp.Config.Twitch_Quality -eq '720p'){
          $qualities = "720p60,720p,480p"
        }elseif($thisApp.Config.Twitch_Quality -eq '480p'){
          $qualities = "480p,worst"
        }elseif($thisApp.Config.Twitch_Quality -eq 'worst'){
          $qualities = "worst"
        }elseif($thisApp.Config.Twitch_Quality -eq 'audio_only'){
          $qualities = "audio_only"
        }else{
          $qualities = "best,1080p60,1080p,720p60,720p,480p"
        }
        write-ezlogs "| Streamlink Preferred Quality: $($qualities)" -loglevel 2 -logtype Twitch
        if($synchash.Primary_Network_Interface){
          $HTTP_Interface = "--player-external-http-interface=$($synchash.Primary_Network_Interface)"
        }else{
          $HTTP_Interface = ''
        }
        if($thisapp.config.Skip_Twitch_Ads){
          if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Streamlink\twitch.py")){
            $TwitchPlugin = [System.IO.FileInfo]::new("$($thisApp.Config.Current_Folder)\Resources\Streamlink\twitch.py")
            $TwitchPlugin_exist = [System.IO.FileInfo]::new("$env:APPDATA\Streamlink\Plugins\twitch.py")
            if($TwitchPlugin.Length -ne $TwitchPlugin_exist.length){
              try{
                write-ezlogs ">>>> Existing installed Twitch.py plugin does not match source plugin or is not installed, copying to: $env:APPDATA\Streamlink\Plugins\twitch.py" -warning
                if(![system.IO.Directory]::Exists("$env:APPDATA\Streamlink\Plugins\")){
                  write-ezlogs "| Creating new streamlink plugins directory: $env:APPDATA\Streamlink\Plugins\"
                  [void][system.io.directory]::CreateDirectory("$env:appdata\streamlink\plugins")
                }
                [void][system.io.file]::Copy("$($thisApp.Config.Current_Folder)\Resources\Streamlink\twitch.py","$env:APPDATA\Streamlink\Plugins\twitch.py",$true)
              }catch{
                write-ezlogs "An exception occurred updating or copying Twitch.py streamlink plugin" -catcherror $_
              }
            } 
          }
          if([system.io.file]::Exists("$env:APPDATA\Streamlink\Plugins\twitch.py")){      
            $twitch_disable_ads = '--twitch-disable-ads'
            if($thisApp.config.UseTwitchCustom -and $thisApp.Config.TwitchProxies.count -gt 0){
              [String[]]$proxies = ($thisApp.Config.TwitchProxies | & { process {
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Adding custom Twitch Playlist Proxy URL for Streamlink: $($_)" -loglevel 2 -Dev_mode} 
                    if([regex]::Escape($_) -match 'https:'){
                      $_
                    }else{
                      write-ezlogs "Cannot add playlist proxy url $($_) - it does not meet the required format!" -warning -loglevel 2
                    }
              }}) -join ','
              if($proxies){
                write-ezlogs ">>>> Using custom provided Twitch playlist proxy urls for streamlink: $proxies" -logtype Twitch
                $TwitchProxies = "--twitch-proxy-playlist=$proxies"
              }
            }elseif($thisapp.config.Use_Twitch_luminous){
              $TwitchProxies = '--twitch-proxy-playlist=https://eu.luminous.dev,https://lb-na.cdn-perfprod.com,https://eu2.luminous.dev,https://as.luminous.dev,https://lb-eu.cdn-perfprod.com,https://lb-eu2.cdn-perfprod.com,https://api.ttv.lol'
            }elseif($thisapp.config.Use_Twitch_TTVLOL){
              $TwitchProxies = '--twitch-proxy-playlist=https://api.ttv.lol,https://eu.luminous.dev,https://eu2.luminous.dev,https://as.luminous.dev'
            }else{
              $TwitchProxies = $Null
            }
          }else{
            write-ezlogs "Unable to find twitch streamlink plugin at: $env:APPDATA\Streamlink\Plugins\twitch.py" -warning -logtype Twitch
            $twitch_disable_ads = '--twitch-disable-ads'
            $TwitchProxies = $null
          }
          write-ezlogs "| Streamlink Adblocking solutions to use: $twitch_disable_ads $TwitchProxies" -loglevel 2 -logtype Twitch
        }else{
          $twitch_disable_ads = $null
          $TwitchProxies = $null
          write-ezlogs "| Streamlink will not attempt to block ADs" -loglevel 2 -logtype Twitch
        } 
        #client id for nintendo switch, used as a hack/bypass for twitch ads, not likely needed anymore: --twitch-api-header="Client-Id=ue6666qo983tsx6so1t0vnawi233wa"
        if($TwitchProxies){
          #Dont pass twitch token when using proxy playlists - ignored anyway
          $Twitch_oauth = $Null
        }
        Write-EZLogs "############## [STREAMLINK MONITOR START] ##############" -logtype Twitch -loglevel 2
        $qualitypattern = '\[cli\]\[info\] Opening stream:(?<value>.*)'
        #$Availablestreamspattern = 'Available streams: (?<value>.*)'
        #$Openingstreampattern ='Opening stream: (?<value>.*)'
        $errorurlpattern = 'error: No playable streams found on this URL: (?<value>.*)'
        $protectedvideopattern = 'This plugin does not support protected videos'
        #TODO: Make ringbuffer configurable - default 16MB - changed to 32MB then 128MB
        try{
          $newProc = [System.Diagnostics.ProcessStartInfo]::new($streamlinkpath)
          $newProc.WindowStyle = 'Hidden'
          $newProc.Arguments = "$($media.url) $qualities --player-external-http --player-external-http-port $Streamlink_Port --player-external-http-continuous 0 --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --retry-streams 1 --hls-segment-queue-threshold 4 --hls-playlist-reload-attempts 4 --retry-max 10 $twitch_disable_ads $TwitchProxies --stream-segment-threads 3 --ringbuffer-size 128M --hls-segment-stream-data  --twitch-low-latency $Twitch_oauth $HTTP_Interface"
          $newProc.UseShellExecute = $false
          $newProc.CreateNoWindow = $true
          $newProc.RedirectStandardOutput = $true
          $Process = [System.Diagnostics.Process]::Start($newProc)
        }catch{
          write-ezlogs "An exception occurred executing svcl" -catcherror $_
        }finally{
          while($Process.StandardOutput.EndOfStream -eq $false){
            $Process.StandardOutput.ReadLine() | & { process {
                write-ezlogs $_ -logfile $($thisApp.Config.Streamlink_Log_File) -callpath 'Start-Streamlink'
                if($_ -match $qualitypattern){
                  $CurrentQuality = ([regex]::matches($_, $qualitypattern) | & { process {$_.groups[1].value}}).trim()
                  if($CurrentQuality -match '\(hls\)'){
                    $CurrentQuality = ($CurrentQuality -replace '\(hls\)','').trim()
                  }
                  $synchash.Current_Video_Quality = $CurrentQuality
                }
                if($_ -match 'Encountered an ad segment, re-execing to retrieve a new playlist'){
                  write-ezlogs "Streamlink twitch plugin is attempting to restart/fetch new playlist to prevent ads...keeping streamlink log monitor active" -logtype Twitch -loglevel 2 -warning
                }
                <#                if($_ -match $Availablestreamspattern){
                    $Availablestreams = ([regex]::matches($_, $Availablestreamspattern) | & { process {$_.groups[1].value}})
                }#>
                <#                if($_ -match $Openingstreampattern){
                    $Openingstream = ([regex]::matches($_, $Openingstreampattern) | & { process {$_.groups[1].value}})
                }#>
                if($_ -match "Filtering out segments and pausing stream output" -and $synchash.Now_Playing_Title_Label.DataContext -notmatch 'LOADING...' -and $synchash.Now_Playing_Title_Label.DataContext -notin 'SKIPPING ADS...','OPENING...'){   
                  write-ezlogs  "Streamlink paused output to filter Twitch Ads, updating now playing label to 'SKIPPING ADS...'" -logtype Twitch -warning -loglevel 2
                  if(!$synchash.IsCurrentlyMuted){                                 
                    if($thisApp.Config.Skip_Twitch_Ads -and $thisApp.Config.Mute_Twitch_Ads){
                      write-ezlogs  " | Muting for Ads skip" -logtype twitch -warning -loglevel 2
                      $synchash.IsCurrentlyMuted = $true
                      $synchash.Mute_media_timer.start()
                    }                  
                  }
                  if($thisApp.Config.Skip_Twitch_Ads){
                    Write-ezlogs ">>>> Updating Now_Playing_Title_Label to SKIPPING ADS..." -warning
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Title_Label' -Property 'DataContext' -value 'SKIPPING ADS...'
                  }                                
                  #update UI/user so they know stream/playback is not broken, ads are being filtering
                }             
                if($_ -match 'Waiting for pre-roll ads to finish, be patient' -and $synchash.Now_Playing_Title_Label.DataContext -notmatch 'LOADING...' -and $synchash.Now_Playing_Title_Label.DataContext -notin 'SKIPPING ADS...','OPENING...'){
                  #stream has resume, update UI/user
                  write-ezlogs  "Updating now playing label to 'Waiting for pre-roll ads to finish, be patient'" -logtype twitch -warning -loglevel 2 
                  Update-MainPlayer -synchash $synchash -thisApp $thisApp -Now_Playing_Title "LOADING...Waiting for Pre-Roll ADs to Finish..."
                }
                if($_ -match "Resuming stream output"){
                  #stream has resume, update UI/user                 
                  if($thisApp.Config.Skip_Twitch_Ads){           
                    if($synchash.IsCurrentlyMuted -and $thisApp.Config.Mute_Twitch_Ads){
                      write-ezlogs  "| Unmuting from Ads skip" -logtype twitch -warning -loglevel 2
                      $synchash.IsCurrentlyMuted = $false
                      $synchash.Mute_media_timer.start()                 
                    }
                    write-ezlogs  "| Streamlink has resumed, Resetting now playing label to $($synchash.streamlink.title)" -logtype twitch -warning -loglevel 2 
                    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Now_Playing_Title_Label' -Property 'DataContext' -value "$($synchash.streamlink.title)"
                  }
                }
                if($_ -match 'Closing currently open stream...'-and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports it is closing the currently open stream" -logtype Twitch -warning -loglevel 2
                }elseif($_ -match "HTTP connection closed" -and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports connection to player has been closed" -logtype Twitch -warning -loglevel 2
                }elseif($_ -match 'Stream ended' -and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports stream has ended" -logtype Twitch -warning -loglevel 2
                  #continue
                }elseif($_ -match $protectedvideopattern){
                  write-ezlogs "| Streamlink reports it can't play ($($synchash.Current_playing_media.url)) because it is a protected video! Try disabling the Use Streamlink option under Youtube Settings" -logtype Twitch -warning -loglevel 2 -AlertUI -synchash $synchash
                  #continue
                }elseif($_ -match $errorurlpattern){
                  $badurl = ([regex]::matches($_, $errorurlpattern) | & { process {$_.groups[1].value}})
                  write-ezlogs "| Streamlink reports error: No playable streams found on this URL: $badurl" -logtype Twitch -warning -loglevel 2 -AlertUI -synchash $synchash
                  #continue
                }elseif([string]::IsNullOrEmpty($synchash.Current_playing_media.id)){
                  write-ezlogs "| Ending Streamlink as current playing media is empty" -loglevel 2 -logtype Twitch -warning
                  $sprocess = [System.Diagnostics.Process]::GetProcessesByName('streamlink')
                  if($sprocess){
                    foreach($p in $sprocess){
                      $p.kill()
                      $p.dispose()
                    }
                  }
                  $Canceling = $true
                }elseif(!([System.Diagnostics.Process]::GetProcessesByName('streamlink')) -and !($synchash.VLC_IsPlaying_State) -and !$Canceling){
                  write-ezlogs "| Streamlink process ended or vlc playback stopping" -loglevel 2 -logtype Twitch -warning
                  #continue
                }
            }}
          }
          if($Process -is [System.IDisposable]){
            $Process.dispose()
          }
        }
        Write-EZLogs "############## [STREAMLINK MONITOR END] ##############" -logtype Twitch -loglevel 2
        #$streamlink = streamlink $media.url $qualities --player-external-http --player-external-http-port $Streamlink_Port --player-external-http-continuous 0 --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --logfile $($thisApp.Config.Streamlink_Log_File) --retry-streams 1 --retry-max 10 $twitch_disable_ads $twitch_ttvlol --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data --twitch-api-header="Client-Id=ue6666qo983tsx6so1t0vnawi233wa" --twitch-low-latency $Twitch_oauth $HTTP_Interface
        #$streamlink = streamlink $media.url $qualities --player-external-http --player-external-http-port $Streamlink_Port --player-external-http-continuous 0 --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --logfile $($thisApp.Config.Streamlink_Log_File) --retry-streams 1 --retry-max 10 --twitch-disable-ads --stream-segment-threads 2 --ringbuffer-size 32M --hls-segment-stream-data --twitch-api-header="Client-Id=ue6666qo983tsx6so1t0vnawi233wa" --twitch-low-latency                                
      }elseif([system.io.file]::Exists($streamlinkpath) -and $Youtube){
        if($thisApp.Config.Youtube_Quality -in 'Best','Auto'){
          $qualities = "best,1080p60,1080p,720p60,720p,480p"
          $ringbuffer = '64M'
        }elseif($thisApp.Config.Youtube_Quality -eq 'Medium'){
          $qualities = "720p60,720p,480p"
          $ringbuffer = '64M'
        }elseif($thisApp.Config.Youtube_Quality -eq 'Low'){
          $qualities = "480p,worst"
          $ringbuffer = '32M'
        }else{
          $qualities = "best,1080p60,1080p,720p60,720p,480p"
          $ringbuffer = '64M'
        }
        write-ezlogs "| Streamlink Preferred Quality: $($thisApp.Config.Youtube_Quality)" -loglevel 2
        write-ezlogs "| Streamlink ringbuffer: $($ringbuffer)" -loglevel 2
        try{
          $newProc = [System.Diagnostics.ProcessStartInfo]::new($streamlinkpath)
          $newProc.WindowStyle = 'Hidden'
          $newProc.Arguments = "$($media.url) $qualities --player-external-http --player-external-http-continuous 0 --player-external-http-port $Streamlink_Port --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --logfile $($thisApp.Config.Streamlink_Log_File) --retry-streams 1 --retry-max 10 --stream-segment-threads 2 --ringbuffer-size $ringbuffer --twitch-api-header=`"Client-Id=ue6666qo983tsx6so1t0vnawi233wa`""
          $newProc.UseShellExecute = $false
          $newProc.CreateNoWindow = $true
          $newProc.RedirectStandardOutput = $true
          $Process = [System.Diagnostics.Process]::Start($newProc)
        }catch{
          write-ezlogs "An exception occurred executing: $streamlinkpath" -catcherror $_
        }finally{
          while($Process.StandardOutput.EndOfStream -eq $false){
            $Process.StandardOutput.ReadLine() | & { process {
                write-ezlogs $_ -logfile $($thisApp.Config.Streamlink_Log_File) -callpath 'Start-Streamlink:Youtube'
                if($_ -match $qualitypattern){
                  $CurrentQuality = ([regex]::matches($_, $qualitypattern) | & { process {$_.groups[1].value}}).trim()
                  if($CurrentQuality -match '\(hls\)'){
                    $CurrentQuality = ($CurrentQuality -replace '\(hls\)','').trim()
                  }
                  $synchash.Current_Video_Quality = $CurrentQuality
                }
                if($_ -match 'Encountered an ad segment, re-execing to retrieve a new playlist'){
                  write-ezlogs "Streamlink twitch plugin is attempting to restart/fetch new playlist to prevent ads...keeping streamlink log monitor active" -loglevel 2 -warning
                }            
                if($_ -match 'Closing currently open stream...'-and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports it is closing the currently open stream" -warning -loglevel 2
                }elseif($_ -match "HTTP connection closed" -and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports connection to player has been closed" -warning -loglevel 2
                }elseif($_ -match 'Stream ended' -and !($synchash.VLC_IsPlaying_State)){
                  write-ezlogs "| Streamlink reports stream has ended" -warning -loglevel 2
                  #continue
                }elseif($_ -match $protectedvideopattern){
                  write-ezlogs "| Streamlink reports it can't play ($($synchash.Current_playing_media.url)) because it is a protected video! Try disabling the Use Streamlink option under Youtube Settings" -warning -loglevel 2 -AlertUI -synchash $synchash
                  #continue
                }elseif($_ -match $errorurlpattern){
                  $badurl = ([regex]::matches($_, $errorurlpattern) | & { process {$_.groups[1].value}})
                  write-ezlogs "| Streamlink reports error: No playable streams found on this URL: $badurl" -warning -loglevel 2 -AlertUI -synchash $synchash
                  #continue
                }elseif([string]::IsNullOrEmpty($synchash.Current_playing_media.id)){
                  write-ezlogs "| Ending Streamlink as current playing media is empty" -loglevel 2 -warning
                  $SProcess = [System.Diagnostics.Process]::GetProcessesByName('streamlink')
                  if($Process){
                    foreach($s in $SProcess){
                      $s.kill()
                      $s.dispose()
                    }
                  }
                  $SProcess = $Null
                  $Canceling = $true
                }elseif(!([System.Diagnostics.Process]::GetProcessesByName('streamlink')) -and !($synchash.VLC_IsPlaying_State) -and !$Canceling){
                  write-ezlogs "| Streamlink process ended or vlc playback stopping" -loglevel 2 -warning
                  #continue
                }
            }}
          }
          if($Process -is [System.IDisposable]){
            $Process.dispose()
          }
        }
        #$streamlink = . $streamlinkpath $media.url $qualities --player-external-http --player-external-http-continuous 0 --player-external-http-port $Streamlink_Port --loglevel $($thisApp.Config.Streamlink_Verbose_logging) --logfile $($thisApp.Config.Streamlink_Log_File) --retry-streams 1 --retry-max 10 --stream-segment-threads 2 --ringbuffer-size $ringbuffer --twitch-api-header="Client-Id=ue6666qo983tsx6so1t0vnawi233wa"
      }elseif($fallBack_YTDLP){
        write-ezlogs "Unable to find Streamlink installed, falling back to using YTDLP" -showtime -warning
        $synchash.ForceUseYTDLP = $true
        $synchash.Start_media = $Media
        $synchash.start_media_timer.start()                  
        return
      }
    }
    if($Use_Runspace){
      if(!$RunspaceName){
        $RunspaceName = "Streamlink_HTTP_Runspace"
      }
      Start-Runspace $streamlinkblock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name $RunspaceName -thisApp $thisApp -RestrictedRunspace -function_list Write-EZLogs,Update-MainWindow,Update-MainPlayer -cancel_runspace
      #$Variable_list = $Null
      if($wait){
        $streamlink_wait_timer = 0
        if($TwitchVOD){
          while($streamlink_wait_timer -lt 40 -and !$synchash.streamlink_HTTP_URL){
            $streamlink_wait_timer++
            write-ezlogs "| Waiting for streamlink to get vod url...." -showtime
            start-sleep -Milliseconds 500
          }
        }else{
          while($streamlink_wait_timer -lt 40 -and !$([System.Diagnostics.Process]::GetProcessesByName('streamlink'))){
            $streamlink_wait_timer++
            write-ezlogs "| Waiting for streamlink process...." -showtime
            if($streamlink_wait_timer -eq 30){
              write-ezlogs "Relaunching streamlink as it should have started by now"  -warning
              Start-Streamlink @PSBoundParameters
            }
            start-sleep -Milliseconds 500
          }
        }
        if(($streamlink_wait_timer -ge 60)){
          write-ezlogs "Timed out waiting for streamlink to start playback for $($media.url). Try disabling the Use Streamlink option under Youtube Settings" -showtime -warning -logtype youtube -AlertUI -synchash $synchash
          return
        }else{
          return $($synchash.streamlink_HTTP_URL)
        }
      }
    }else{
      Invoke-Command -ScriptBlock $streamlinkblock #-ArgumentList $PSBoundParameters
    }
  }catch{
    write-ezlogs "An exception occurred in Start-Streamlink" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Start-Streamlink Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-NewMedia Function
#----------------------------------------------
function Start-NewMedia {
  [CmdletBinding()]
  param (
    $Media,
    $Mediaurl,
    $synchash,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    $thisApp,
    [switch]$Restart,
    [switch]$Use_invidious,
    [switch]$No_YT_Embed,
    [switch]$start_Paused,
    [switch]$Use_Streamlink,
    [switch]$Use_Runspace,
    [string]$RunspaceName,
    [switch]$ForceUseYTDLP = $thisApp.Config.ForceUse_YTDLP,
    [switch]$use_WebPlayer = $thisapp.config.Youtube_WebPlayer,
    $all_playlists,
    [switch]$Show_notifications = $thisApp.Config.Show_notifications,
    [ValidateSet('Youtube','Spotify','Local','Twitch','Other')]
    [string]$MediaType,
    [switch]$Verboselog = $true
  )
  try{
    if(!$Mediaurl -and $media.url){
      $Mediaurl = $media.url
    }
    write-ezlogs "#### Attempting to start playback of new or unknown media url: $($mediaurl)" -linesbefore 1
    if(!(Test-ValidPath -path $mediaurl -Type URLorFile)){
      write-ezlogs "Unable to find or verify a valid media URL to play using: $($mediaurl)" -warning -AlertUI -synchash $synchash
      return
    }
    $synchash.Temporary_Playback_Media = $Null
    $startmediacriptblock = {
      param (
        $Media = $Media,
        $Mediaurl = $Mediaurl,
        $synchash = $synchash,
        $Media_ContextMenu = $Media_ContextMenu,
        $thisApp = $thisApp,
        [switch]$Restart = $Restart,
        [switch]$Use_invidious = $Use_invidious,
        [switch]$No_YT_Embed = $No_YT_Embed,
        [switch]$start_Paused = $start_Paused,
        [switch]$Use_Streamlink = $Use_Streamlink,
        [switch]$Use_Runspace = $Use_Runspace,
        [string]$RunspaceName = $RunspaceName,
        [switch]$ForceUseYTDLP = $ForceUseYTDLP,
        [switch]$use_WebPlayer = $use_WebPlayer,
        [switch]$Show_notifications = $Show_notifications,
        [string]$MediaType = $MediaType,
        [switch]$Verboselog = $Verboselog
      )
      $cleanedYoutubeURL = $Null
      Update-MainPlayer -synchash $synchash -thisApp $thisApp -Now_Playing_Title "LOADING..."
      if(!$Mediaurl -and $media.url){
        $Mediaurl = $media.url
      }
      if($MediaType -eq 'Youtube'){
        try{
          if($Mediaurl -match '&t='){
            $Mediaurl = ($($Mediaurl) -split('&t='))[0].trim()
          }            
          if($Mediaurl -match "v=(?<value>.*)&(?<value>.*)"){
            $youtube_id = [regex]::matches($Mediaurl, "v=(?<value>.*)&(?<value>.*)") | & { process {$_.groups[1].captures.value[0]}}
          }elseif($Mediaurl -match "v="){
            $youtube_id = ($($Mediaurl) -split('v='))[1].trim()    
          }elseif($Mediaurl -match 'list='){
            $youtube_id = ($($Mediaurl) -split('list='))[1].trim()                  
          }
          $cleanedYoutubeURL = "https://www.youtube.com/watch?v=$youtube_id"
        }catch{
          write-ezlogs "An exception occurred parsing youtube id form link $Mediaurl" -showtime -catcherror $_
        }
      }elseif($Mediaurl -match 'Twitch\.tv'){
        $MediaType = 'Twitch'
      }
      try{
        #Lookup by url to see if there is already a profile for it
        $Media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_URL $Mediaurl
      }catch{
        write-ezlogs "An exception occurred checking for a media profile for url: $Mediaurl" -CatchError $_
      }
      if([string]::IsNullOrEmpty($Media.id)){
        if((Test-ValidPath -path $mediaurl -Type URL)){
          write-ezlogs "| Mediaurl is URL link $($Mediaurl)" -showtime       
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseNetwork
            $from_path = [LibVLCSharp.FromType]::FromLocation
          }else{
            $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseNetwork
            $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
          } 
        }else{
          write-ezlogs "| Mediaurl is local path link $($Mediaurl)" -showtime      
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $ParseOption = [LibVLCSharp.MediaParseOptions]::ParseLocal
            $from_path = [LibVLCSharp.FromType]::FromPath
          }else{
            $ParseOption = [LibVLCSharp.Shared.MediaParseOptions]::ParseLocal
            $from_path = [LibVLCSharp.Shared.FromType]::FromPath
          }
        } 
        #TODO: Refactor/consolidate into Initialize-VLC 
        if(!$synchash.libvlc){
          try{
            $audio_media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)flac|(?i)wav|(?i)3gp|(?i)aac))')  
            $vlcArgs = [System.Collections.Generic.List[String]]::new()
            [void]($vlcArgs.add('--file-logging'))
            [void]($vlcArgs.add("--logfile=$($thisapp.config.Vlc_Log_file)"))
            [void]($vlcArgs.add("--mouse-events"))
            [void]($vlcArgs.add("--log-verbose=$($thisapp.config.Vlc_Verbose_logging)"))
            [void]($vlcArgs.add("--osd"))
            if($thisApp.Config.Libvlc_Global_Gain -is [int]){
              [void]($vlcArgs.add("--gain=$($thisApp.Config.Libvlc_Global_Gain)"))
            }else{
              [void]($vlcArgs.add('--gain=4.0')) #Set gain to 4 which is default that VLC uses but for some reason libvlc does not
            }
            [void]($vlcArgs.add("--logmode=text"))
            if($thisapp.config.Enable_EQ2Pass){
              [void]($vlcArgs.add("--equalizer-2pass"))
            }else{
              $vlc_eq2pass = $null
            }
            if($thisApp.Config.Use_Visualizations -and ($Mediaurl -match $audio_media_pattern)){ 
              [void]($vlcArgs.add("--video-on-top"))
              [void]($vlcArgs.add("--spect-show-original"))
              if($thisApp.Config.Current_Visualization -eq 'Spectrum'){         
                [void]($vlcArgs.add("--audio-visual=Visual"))
                [void]($vlcArgs.add("--effect-list=spectrum"))
              }else{
                [void]($vlcArgs.add("--audio-visual=$($thisApp.Config.Current_Visualization)"))
                [void]($vlcArgs.add("--effect-list=spectrum"))
              }                                                        
            }else{  
              [void]($vlcArgs.add("--file-caching=1000"))
              write-ezlogs "| New libvlc instance, no visualization, (file-caching: 1000)" -showtime -loglevel 2 -logtype Libvlc      
            }
            if(-not [string]::IsNullOrEmpty($thisapp.config.vlc_Arguments)){
              try{
                $thisapp.config.vlc_Arguments -split ',' | & { process {               
                    if([regex]::Escape($_) -match '--' -and $vlcArgs -notcontains $_){
                      write-ezlogs "| Adding custom Libvlc option: $($_)" -loglevel 2 
                      [void]($vlcArgs.add("$($_)"))
                    }else{
                      write-ezlogs "Cannot add custom libvlc option $($_) - it does not meet the required format or is already added!" -warning -loglevel 2 -logtype Libvlc
                    }
                }}
              }catch{
                write-ezlogs "An exception occurred processing custom VLC arguments" -catcherror $_
              }          
            }
            [String[]]$libvlc_arguments = $vlcArgs | & { process {
                if($thisApp.Config.Dev_mode){write-ezlogs "[Start-NewMedia] | Applying Libvlc option: $($_)" -loglevel 2 -logtype Libvlc -Dev_mode} 
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
            $synchash.libvlc.SetUserAgent("$($thisApp.Config.App_Name) Media Player","HTTP/User/Agent")
            $startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"
            if($startapp.AppID -and $synchash.libvlc){
              $synchash.libvlc.SetAppId($startapp.AppID,$thisApp.Config.App_Version,"$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
            }                     
          }catch{
            write-ezlogs "An exception occurred disposing and creating a new videoview control" -showtime -catcherror $_
          }  
        }  
        $mediaproperties = @{}
        if($MediaType -ne 'Twitch'){
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $libvlc_media = [LibVLCSharp.Media]::new([Uri]($Mediaurl),$from_path,$null)
          }else{
            $libvlc_media = [LibVLCSharp.Shared.Media]::new($synchash.libvlc,[Uri]($Mediaurl),$from_path,$null)
          }

          #Parsemedia by loading it into vlc
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $Parse_Status = $libvlc_media.ParsedStatus -eq 'Done'  
          }else{
            $Parse_Status = $libvlc_media.IsParsed   
          }           
          if(!$Parse_Status){
            try{
              write-ezlogs ">>>> Parsing media with option $($ParseOption)" -showtime         
              if($thisApp.Config.Libvlc_Version -eq '4'){
                $parseresult = $libvlc_media.parseasync($synchash.libvlc,$ParseOption)
              }else{
                $parseresult = $libvlc_media.Parse($ParseOption) 
              }
              while(!$parseresult.IsCompleted){
                start-sleep -Milliseconds 500
              }
              write-ezlogs "| Parse result: $($parseresult | out-string)" -showtime
            }catch{
              write-ezlogs "An exception occurred parsing libvlc_media" -showtime -catcherror $_
            } 
          }
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $Parse_Status = $libvlc_media.ParsedStatus -eq 'Done'  
          }else{
            $Parse_Status = $libvlc_media.IsParsed   
          }        
          if($Parse_Status){
            if($thisApp.Config.Libvlc_Version -eq '4'){
              $Metatypes = [LibVLCSharp.MetadataType]::GetNames([LibVLCSharp.Shared.MetadataType]) 
            }else{
              $Metatypes = [LibVLCSharp.Shared.MetadataType]::GetNames([LibVLCSharp.Shared.MetadataType])
            }
            write-ezlogs "| Getting metadata properties: $($Metatypes)" -showtime -Dev_mode
            if($libvlc_media.SubItems[0]){
              if($thisApp.Config.Libvlc_Version -eq '4'){
                $Parse_Status = $libvlc_media.SubItems[0].ParsedStatus -eq 'Done'  
              }else{
                $Parse_Status = $libvlc_media.SubItems[0].IsParsed   
              }  
              if(!$Parse_Status){
                try{
                  write-ezlogs ">>>> Parsing subitem from media with option $($ParseOption)" -showtime         
                  if($thisApp.Config.Libvlc_Version -eq '4'){
                    $parseresult = $libvlc_media.SubItems[0].parseasync($synchash.libvlc,$ParseOption)
                  }else{
                    $parseresult = $libvlc_media.SubItems[0].Parse($ParseOption)
                  }
                  while(!$parseresult.IsCompleted){
                    start-sleep -Milliseconds 500
                  }
                  write-ezlogs "| Parse subitem result: $($parseresult | out-string)" -showtime
                }catch{
                  write-ezlogs "An exception occurred parsing subitem libvlc_media" -showtime -catcherror $_
                } 
              }
              foreach($type in $Metatypes){
                $mediaproperties."$type" = $libvlc_media.SubItems[0].Meta($type)
              }
              $mediaproperties.duration = $libvlc_media.SubItems[0].Duration
              $mediaproperties.Type = $libvlc_media.SubItems[0].Type
              $hasVideo = $libvlc_media.SubItems.tracks.TrackType -in 'Video'          
              $url = $libvlc_media.SubItems[0].Mrl
            }else{
              foreach($type in $Metatypes){
                $mediaproperties."$type" = $libvlc_media.Meta($type)
              }
              $mediaproperties.duration = $libvlc_media.Duration
              $mediaproperties.Type = $libvlc_media.Type
              $hasVideo = $libvlc_media.tracks.TrackType -in 'Video'
              $url = $libvlc_media.Mrl
            }
            write-ezlogs "| Parsed Media Properties: $($mediaproperties | out-string)" -Dev_mode
          }        
        }else{
          $twitch_channel = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(([System.IO.Path]::GetFileName($Mediaurl)).tolower()).trim()
          #$twitch_channel = $((Get-Culture).textinfo.totitlecase(([System.IO.Path]::GetFileName($Mediaurl)).tolower())) 
          $mediaproperties.title = $twitch_channel
          $url = $Mediaurl
          $hasVideo = $true
          $mediaproperties.type = 'Twitch'      
        }          
        if(!$mediaproperties.TrackID){
          $track_encodedBytes = $Null
          $track_encodedid = $Null
          if($mediaproperties.title -and $mediaproperties.Artist){
            $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($mediaproperties.title)-$($mediaproperties.Artist)-TemporaryMedia")
            $track_encodedid = [System.Convert]::ToBase64String($track_encodedBytes)
            $mediaproperties.TrackID = $track_encodedid
          }elseif($libvlc_media.NativeReference){
            $mediaproperties.TrackID = "$($libvlc_media.NativeReference)"
          }else{
            $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Mediaurl)-TemporaryMedia")
            $track_encodedid = [System.Convert]::ToBase64String($track_encodedBytes)
            $mediaproperties.TrackID = $track_encodedid
          }
          write-ezlogs "| Generating new TrackID: $($mediaproperties.TrackID)" -Dev_mode
        }
        if($cleanedYoutubeURL){
          $url = $cleanedYoutubeURL
        }
        $media = [PSCustomObject]@{
          'title' =  $mediaproperties.title
          'Artist' = $mediaproperties.Artist
          'Album' = $mediaproperties.Album
          'Track' = $mediaproperties.TrackNumber
          'Episode' = $mediaproperties.Episode
          'Season' = $mediaproperties.Season
          'ShowName' = $mediaproperties.ShowName
          'Language' = $mediaproperties.Language
          'Date' = $mediaproperties.Date
          'hasVideo' = $hasVideo
          'Genre' = $mediaproperties.Genre
          'Web_URL' = $mediaproperties.URL
          'description' = $mediaproperties.Description
          'id' = $mediaproperties.TrackID
          'duration' = $mediaproperties.duration
          'url' = $url              
          'cached_image' = $mediaproperties.ArtworkURL
          'type' = $mediaproperties.type
          'Playlist_url' = ''
          'playlist_id' = ''
          'Profile_Path' =''
          'Profile_Date_Added' = [DateTime]::Now.ToString()
          'Source' = 'Custom'
        }
      }
      $synchash.Temporary_Playback_Media = $media
      Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification -use_WebPlayer:$false -TemporaryPlayback
      if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Temporary_Playback_Media ||  $($media | out-string)" -Dev_mode}
    }
    if($Use_Runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      if(!$RunspaceName){
        $RunspaceName = "NewMedia_Runspace"
      }
      Start-Runspace $startmediacriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name $RunspaceName -thisApp $thisApp
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $startmediacriptblock
    }
  }catch{
    write-ezlogs "An exception occurred in Start-NewMedia" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Start-NewMedia Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-MediaRenderers Function
#----------------------------------------------
function Update-MediaRenderers {
  Param (
    $synchash,
    $thisApp,
    [switch]$Show,
    [switch]$Hide,
    [switch]$close,
    [switch]$clear,
    [switch]$screenshot,
    [string]$Visibility,
    [switch]$UpdateMediaRenderers,
    [switch]$Startup
  )
  try{
    if($Startup -or $clear){
      if($clear){
        [void]($synchash.VideoView_Cast_Button.items.clear())
      }
      if($synchash.VideoView_Cast_Button -and $synchash.VideoView_Cast_Button.items.header -notcontains 'Media Renderers'){
        $Menuitem = [System.Windows.Controls.MenuItem]::new()
        $Menuitem.IsCheckable = $false
        $Menuitem.Header = 'Media Renderers'
        $Menuitem.FontWeight = "Bold"
        $Menuitem.IsEnabled = $false
        $Menuitem.Margin = '0,5,0,0'
        $Menuitem.HorizontalAlignment = 'Center'
        $Menuitem.Background = "Transparent"
        $Menuitem.VerticalAlignment="Center"
        $Menuitem.Style = $synchash.Window.TryFindResource("TrayDropDownMenuitemStyle")
        [void]($synchash.VideoView_Cast_Button.items.add($Menuitem))
        $menu_separator = [System.Windows.Controls.Separator]::new()
        $menu_separator.OpacityMask = $synchash.Window.TryFindResource('SeparatorGradient')
        $menu_separator.HorizontalAlignment = "Stretch"
        $menu_separator.Margin = "0,5,23,5"
        $menu_separator.Height = '1'
        $menu_separator.MinWidth = '100'
        $menu_separator.VerticalAlignment="Center"
        [void]($synchash.VideoView_Cast_Button.items.add($menu_separator))
        if($synchash.MediaRenderers.count -lt 1){
          $menu_textblock = [System.Windows.Controls.MenuItem]::new()
          $menu_textblock.HorizontalAlignment = "Center"
          $menu_textblock.Header = "No Renderers Found"
          $menu_textblock.Name = 'MediaRenderStatus_TextBox'
          $menu_textblock.FontSize = '11'
          $menu_textblock.FontStyle = 'Italic'
          $menu_textblock.Opacity = "0.8"
          $menu_textblock.IsEnabled = $false
          $menu_textblock.Style = $synchash.Window.TryFindResource("TrayDropDownMenuitemStyle")
          $menu_textblock.VerticalAlignment="Center"
          $synchash.MediaRenderStatus_TextBox = $menu_textblock
          if($synchash.VideoView_Cast_Button.items -notcontains $synchash.MediaRenderStatus_TextBox){
            [void]($synchash.VideoView_Cast_Button.items.add($synchash.MediaRenderStatus_TextBox))
          } 
        } 
        $synchash.VideoView_Cast_rescan = [System.Windows.Controls.MenuItem]::new()
        $synchash.VideoView_Cast_rescan.HorizontalAlignment = "Center"
        $synchash.VideoView_Cast_rescan.IsCheckable = $false
        if(!$synchash.PackIconFontAwesome_Spinner){
          $synchash.PackIconFontAwesome_Spinner = [MahApps.Metro.IconPacks.PackIconFontAwesome]::new()
          $synchash.PackIconFontAwesome_Spinner.Kind = 'SyncAltSolid'
          $synchash.PackIconFontAwesome_Spinner.Foreground = 'White'
          $synchash.PackIconFontAwesome_Spinner.Tag = $false
          $synchash.PackIconFontAwesome_Spinner.SpinDuration = [double]1
          $synchash.PackIconFontAwesome_Spinner.Spin = $false
        }
        $synchash.VideoView_Cast_rescan.icon = $synchash.PackIconFontAwesome_Spinner
        $synchash.VideoView_Cast_rescan.Header = "Rescan Now"
        $synchash.VideoView_Cast_rescan.StaysOpenOnClick = $true
        $synchash.VideoView_Cast_rescan.FontSize = '11'
        $synchash.VideoView_Cast_rescan.VerticalAlignment="Center"
        [void]($synchash.VideoView_Cast_rescan.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.ScanMediaRenderers_Command))
        [void]($synchash.VideoView_Cast_rescan.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.ScanMediaRenderers_Command))
        if($synchash.VideoView_Cast_Button.items -notcontains $synchash.VideoView_Cast_rescan){
          [void]($synchash.VideoView_Cast_Button.items.add($synchash.VideoView_Cast_rescan))
        }   
      }
      if($Startup){
        $synchash.MediaRenderers_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new()
        $synchash.MediaRenderers_Update_Timer.add_tick({
            try{  
              $synchash = $synchash
              $thisApp = $thisApp                       
              if(-not [string]::IsNullOrEmpty($this.tag.Visibility)){
                $synchash.Window.Visibility = $this.tag.Visibility 
              }   
              if($this.tag.Show){
                $synchash.window.ShowActivated = $true
                $synchash.window.ShowInTaskbar = $true
                $synchash.window.Opacity = 1
                $synchash.Window.show()
                $synchash.Window.Activate()
              }
              if($this.tag.Hide){
                $synchash.Window.Hide() 
              }  
              if($this.tag.Close){
                $synchash.Window.Close() 
              }
              if($this.tag.UpdateMediaRenderers){
                if($synchash.MediaRenderers.count -gt 0){
                  if($synchash.VideoView_Cast_Button.items -contains $synchash.MediaRenderStatus_TextBox){
                    write-ezlogs ">>>> Removing no renderers found item" -Dev_mode
                    [void]($synchash.VideoView_Cast_Button.items.remove($synchash.MediaRenderStatus_TextBox))
                  }
                  if($synchash.VideoView_Cast_Button.items -contains $synchash.VideoView_Cast_rescan){
                    [void]($synchash.VideoView_Cast_Button.items.Remove($synchash.VideoView_Cast_rescan))
                  }
                  $synchash.MediaRenderers | foreach {
                    try{
                      if($synchash.VideoView_Cast_Button.items.header -notcontains $_.Model){
                        write-ezlogs ">>>> Adding media renderer to list: $($_.Model)" -loglevel 2
                        $Menuitem = [System.Windows.Controls.MenuItem]::new()
                        $Menuitem.IsCheckable = $true
                        $Menuitem.Header = $_.Model
                        $Menuitem.Tag = $_.url
                        $Menuitem.HorizontalAlignment = 'Left'
                        $Menuitem.VerticalAlignment="Center"
                        $Menuitem.Style = $synchash.Window.TryFindResource("TrayDropDownMenuitemStyle")
                        [void]($Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.CastMedia_Command))
                        [void]($Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.CastMedia_Command))
                        [void]($synchash.VideoView_Cast_Button.items.add($Menuitem))    
                      }
                    }catch{
                      write-ezlogs "An exception occurred adding Media Renderer $($_ | out-string)" -catcherror $_
                    }             
                  }
                  if($synchash.VideoView_Cast_rescan -and $synchash.VideoView_Cast_Button.items -notcontains $synchash.VideoView_Cast_rescan){
                    write-ezlogs ">>>> Moving rescan item to bottom" -Dev_mode
                    [void]($synchash.VideoView_Cast_Button.items.Add($synchash.VideoView_Cast_rescan))
                  }
                }else{
                  try{
                    Update-MediaRenderers -synchash $synchash -thisApp $thisApp -clear
                  }catch{
                    write-ezlogs "An exception occurred in Update-MediaRenderers -clear" -catcherror $_
                  }          
                }
                if($synchash.PackIconFontAwesome_Spinner){
                  $synchash.PackIconFontAwesome_Spinner.Spin = $false 
                }
                if($synchash.VideoView_Cast_rescan){
                  $synchash.VideoView_Cast_rescan.isEnabled = $true
                }
              }                             
              $this.Stop()
            }catch{
              write-ezlogs "An exception occurred in MediaRenderers_Update_Timer.add_tick" -showtime -catcherror $_
            }finally{
              $this.Stop()
            }
        }) 
      }
    }elseif(!$synchash.MediaRenderers_Update_Timer.isEnabled){
      $synchash.MediaRenderers_Update_Timer.tag = [PSCustomObject]::new(@{
          'UpdateMediaRenderers' = $UpdateMediaRenderers
          'Visibility' = $Visibility
          'Show' = $Show
          'Hide' = $hide
          'Close' = $close
      })
      $synchash.MediaRenderers_Update_Timer.start()
    }
  }catch{
    write-ezlogs "An exception occurred in Update-MediaRenderers" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-MediaRenderers Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-MediaCast Function
#----------------------------------------------
function Start-MediaCast {
  Param (
    $synchash,
    $thisApp,
    [switch]$Youtube,
    [switch]$wait,
    [switch]$Scan,
    [switch]$Use_Runspace,
    [switch]$Launch,
    [switch]$Close,   
    [string]$RunspaceName,
    [string]$DeviceName,
    [string]$DeviceURL,
    [string]$LocalMediaURL,
    $media,
    [switch]$verboselog,
    [switch]$Startup
  )
  try{
    $castscriptblock = {
      $Launch = $Launch
      $Close = $Close
      $Scan = $Scan
      $DeviceName = $DeviceName
      $DeviceURL = $DeviceURL
      $LocalMediaURL = $LocalMediaURL
      $thisApp = $thisApp
      $synchash = $synchash
      $paths = [Environment]::GetEnvironmentVariable('Path') -split ';'
      $paths2 = $env:path -split ';'
      $ffmpeg_path = "$($thisApp.Config.Current_Folder)\Resources\flac"
      $go2tv_path = "$($thisApp.Config.Current_Folder)\Resources\streaming"
      if($ffmpeg_path -notin $paths2){
        write-ezlogs ">>>> Adding FFMPEG to user enviroment path $ffmpeg_path"
        $env:path += ";$ffmpeg_path"
        <#        if($ffmpeg_path -notin $paths){
            [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$ffmpeg_path",[EnvironmentVariableTarget]::User)
        }#>
      }
      if($go2tv_path -notin $paths2){
        write-ezlogs ">>>> Adding go2tv to user enviroment path $go2tv_path"
        $env:path += ";$go2tv_path"
        <#        if($go2tv_path -notin $paths){
            [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$go2tv_path",[EnvironmentVariableTarget]::User)
        }#>
      }
      if($Scan){
        write-ezlogs ">>>> Scanning for available DLNA Media Renderers"
        $synchash.MediaRenderers = [System.Collections.Generic.List[object]]::new()
        $devices = go2tv-lite -l
        $devices | & { process {
            if($_ -match 'Model\:'){
              $model = ($($_ -split ':')[1] | out-string).trim()
            }
            if($_ -match 'URL\:'){
              $url = ($($_ -split 'URL\:')[1] | out-string).trim()
              $device = [PSCustomObject]@{
                'Model' =  $model
                'url' = $url
              }
              if($model -and $url -and $synchash.MediaRenderers -notcontains $device){
                write-ezlogs "| Found available media renderer $($model) - $($url)"
                [void]($synchash.MediaRenderers.add($device))
              }
              $url = $Null
              $model = $Null  
            }
        }}
        if($synchash.MediaRenderers.count -gt 0){
          write-ezlogs "| Total Media Renderers found $($synchash.MediaRenderers.count)"
        }else{
          write-ezlogs "Unable to find any available or supported Media Renderers to cast to" -warning
        }
        Update-MediaRenderers -synchash $synchash -thisApp $thisApp -UpdateMediaRenderers
      }
      if($launch -and $DeviceName -and $(Test-ValidPath $DeviceURL)){
        $gprocess = [System.Diagnostics.Process]::GetProcessesByName('go2tv')
        if($gprocess){
          write-ezlogs ">>>> Closing running Go2tv casting utility"
          foreach($p in $gprocess){
            $p.kill()
            $p.dispose()
          }
        }
        $glprocess = [System.Diagnostics.Process]::GetProcessesByName('go2tv-lite')
        if($glprocess){
          write-ezlogs ">>>> Closing running go2tv-lite casting utility"
          foreach($p in $glprocess){
            $p.kill()
            $p.dispose()
          }
        }
        if([system.io.file]::Exists($LocalMediaURL)){
          try{
            write-ezlogs ">>>> Starting cast of $LocalMediaURL to device $DeviceName with URL $DeviceURL" -linesbefore 1
            $go2tv_output = go2tv-lite -v $LocalMediaURL -t $DeviceURL                  
          }catch{
            write-ezlogs "An exception occurred executing go2tv-lite -v $LocalMediaURL -t $DeviceURL" -catcherror $_
          }finally{
            if($go2tv_output){
              write-ezlogs "GO2TV FINISHED -- OUTPUT: $($go2tv_output | out-string)" 
            }
          }
        }else{
          try{
            if(-not [string]::IsNullOrEmpty($thisapp.config.Cast_HTTPPort)){
              $CastPort = $thisapp.config.Cast_HTTPPort
            }else{
              $CastPort = '8080'
            }
            write-ezlogs ">>>> Starting cast of 127.0.0.1:$CastPort to device $DeviceName with URL $DeviceURL" -linesbefore 1
            if(!(NETSTAT.EXE -an | where-Object {($_ -match "127.0.0.1:$CastPort" -or $_ -match "0.0.0.0:$CastPort") -and $_ -match 'LISTENING'} | Select-Object -first 1)){
              write-ezlogs "Vlc is not yet streaming on 127.0.0.1:$CastPort - waiting" -warning
              $streamwaittimer = 0
              while(!(NETSTAT.EXE -an | where-Object {($_ -match "127.0.0.1:$CastPort" -or $_ -match "0.0.0.0:$CastPort") -and $_ -match 'LISTENING'} | Select-Object -first 1) -and $streamwaittimer -lt 15){
                $streamwaittimer++
                write-ezlogs "| Waiting for vlc to stream on 127.0.0.1:$CastPort...."
                start-sleep -Seconds 1
              }
              if($streamwaittimer -ge 15){
                write-ezlogs "Timed-out waiting for vlc to stream on 127.0.0.1:$CastPort - canceling device casting" -warning -AlertUI -synchash $synchash
                return
              }         
            }
            if((NETSTAT.EXE -an | where-Object {($_ -match "127.0.0.1:$CastPort" -or $_ -match "0.0.0.0:$CastPort") -and $_ -match 'LISTENING'} | Select-Object -first 1)){
              write-ezlogs ">>>> Found active streaming port - Executing go2tv-lite -u http://127.0.0.1:$CastPort -t $DeviceURL" 
              $go2tv_output = go2tv-lite -u "http://127.0.0.1:$CastPort" -t $DeviceURL         
            }else{
              write-ezlogs "Timed-out waiting for vlc to stream on 127.0.0.1:$CastPort - aborting!" -Warning -AlertUI -synchash $synchash
              return
            }                  
          }catch{
            write-ezlogs "An exception occurred executing go2tv-lite -u http://127.0.0.1:$CastPort -t $DeviceURL" -catcherror $_
          }finally{
            if($go2tv_output){
              write-ezlogs "GO2TV FINISHED -- OUTPUT: $($go2tv_output)" 
              if(($go2tv_output | Select-Object -last 1) -match 'giving up after 4 attempts'){
                write-ezlogs "got2tv received a POST error, retrying to connect one more time" -warning
                try{
                  $go2tv_output = go2tv-lite -u "http://127.0.0.1:$CastPort" -t $DeviceURL
                }catch{
                  write-ezlogs "An exception occurred executing go2tv" -catcherror $_
                }finally{
                  write-ezlogs "FINAL GO2TV OUTPUT: $($go2tv_output)" 
                }
              }
            }
          }
        }
      }elseif($launch){
        write-ezlogs "An invalid devicename ($DeviceName) or DeviceURL ($DeviceURL) was provided, cannot continue" -warning
      }
      if($close){
        try{
          $gprocess = [System.Diagnostics.Process]::GetProcessesByName('go2tv')
          if($gprocess){
            write-ezlogs ">>>> Closing go2tv casting for $DeviceName with URL $DeviceURL"
            foreach($p in $gprocess){
              $p.kill()
              $p.dispose()
            }
          }
          $glprocess = [System.Diagnostics.Process]::GetProcessesByName('go2tv-lite')
          if($glprocess){
            write-ezlogs ">>>> Closing go2tv-lite casting for $DeviceName with URL $DeviceURL"
            foreach($p in $glprocess){
              $p.kill()
              $p.dispose()
            }
          }
        }catch{
          write-ezlogs "An exception occurred closing go2tv" -catcherror $_
        }  
      }elseif($close){
        write-ezlogs "Could not find go2tv process to close, skipping futher actions" -warning -dev_mode
      }
      <#
          if($LaunchUtility){
          if(!$(Get-Process go2tv*) -and [system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Streaming\go2tv-lite.exe")){
          write-ezlogs "[Start-MediaCast] >>>> Launching Go2tv for casting"
          start-process "$($thisApp.Config.Current_Folder)\Resources\Streaming\go2tv-lite.exe" -Wait:$false
          }elseif($(Get-Process go2tv*)){
          write-ezlogs "[Start-MediaCast] >>>> Go2tv is already running"
          }else{
          write-ezlogs "[Start-MediaCast] Could not find go2tv utility to start for casting" -warning
          }
          }elseif($CloseUtility){
          if($(Get-Process go2tv*)){
          write-ezlogs "[Start-MediaCast] >>>> Closing Go2tv casting utility"
          (Get-Process go2tv*) | Stop-Process -Force
          }else{
          write-ezlogs "[Start-MediaCast] Go2tv casting utility process not found, cannot close" -warning
          }
      }#>
      <#      if($error){
          write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
          $error.clear()
      }#>
    }
    if($Use_Runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}} 
      if(!$RunspaceName){
        $RunspaceName = "MediaCast_Runspace"
      }
      if($close){
        $RunspaceName = "Close_MediaCast_Runspace"
      }
      Start-Runspace $castscriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name $RunspaceName -thisApp $thisApp
      Remove-Variable Variable_list
      if($wait){
        $cast_wait_timer = 0
        while($cast_wait_timer -lt 20){
          $cast_wait_timer++
          write-ezlogs "Waiting for media casting...." -showtime -logtype Youtube
          if($cast_wait_timer -eq 15){
            write-ezlogs ">>>> Relaunching streamlink as it should have started by now" -logtype Youtube
          }
          start-sleep 1
        }
        if(($cast_wait_timer -ge 60)){
          write-ezlogs "Timed out waiting for media casting for $($media.url)" -showtime -warning -AlertUI -synchash $synchash
          return
        }else{
          return
        }
      }
    }else{
      Invoke-Command -ScriptBlock $castscriptblock
    }
  }catch{
    write-ezlogs "An exception occurred in Start-MediaCast" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Start-MediaCast Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-Subtitles Function
#----------------------------------------------
function Update-Subtitles {
  Param (
    $synchash,
    $thisApp,
    [switch]$Show,
    [switch]$Hide,
    [switch]$close,
    [switch]$clear,
    [switch]$screenshot,
    [switch]$Add_Subtitles,
    [string]$Subtitles_Path,
    [string]$Visibility,
    [switch]$UpdateSubtitles,
    [switch]$Startup
  )
  try{
    if($Startup -or $clear -or !$synchash.MediaSubtitles_Update_Timer){
      if($clear){
        [void]($synchash.VideoView_Subtitles_Button.items.clear())
      }
      if($Startup -or !$synchash.MediaSubtitles_Update_Timer){
        $synchash.MediaSubtitles_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new()
        $synchash.MediaSubtitles_Update_Timer.add_tick({
            try{  
              $synchash = $synchash
              $thisApp = $thisApp
              if(-not [string]::IsNullOrEmpty($this.tag.Visibility)){
                $synchash.Window.Visibility = $this.tag.Visibility 
              }   
              if($this.tag.Show){
                $synchash.window.ShowActivated = $true
                $synchash.window.ShowInTaskbar = $true
                $synchash.window.Opacity = 1
                $synchash.Window.show() 
                $synchash.Window.Activate() 
              }
              if($this.tag.Hide){
                $synchash.Window.Hide() 
              }  
              if($this.tag.Close){
                $synchash.Window.Close() 
              }
              if($this.tag.Add_Subtitles){
                try{
                  if([system.io.file]::Exists($this.tag.Subtitles_Path)){
                    if($synchash.Current_playing_media.source -eq 'Local' -and $synchash.Current_playing_media.Subtitles_Path -ne $this.tag.Subtitles_Path){
                      $synchash.Current_playing_media.Subtitles_Path = $this.tag.Subtitles_Path
                    }          
                    write-ezlogs ">>>> Refreshing vlc media to load subtitle file: $($this.tag.Subtitles_Path)" -logtype Libvlc    
                    Update-LibVLC -thisApp $thisApp -synchash $synchash -force
                  }else{
                    if($synchash.MediaSubtitles_TextBox){
                      $synchash.MediaSubtitles_TextBox.Header = 'No Subtitles Found'
                    }
                  }
                }catch{
                  write-ezlogs "An exception occurred adding subtitles - $($this.tag.Subtitles_Path)" -catcherror $_
                }finally{
                  if($synchash.VideoView_Subtitles_Fetch){
                    $synchash.VideoView_Subtitles_Fetch.isEnabled = $true
                  }  
                  if($synchash.PackIconFontAwesome_Subtitle_Spinner){
                    $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false 
                  }
                }
              }
              if($this.tag.UpdateSubtitles){
                write-ezlogs ">>>> Looking for subtitles: $($synchash.vlc.media.tracks)" -logtype Libvlc
                $Current_Subtitles = $synchash.vlc.media.tracks | where-Object {$_.TrackType -eq 'Text'}
                if($Current_Subtitles.count -gt 0){
                  if($synchash.VideoView_Subtitles_Button.items -contains $synchash.MediaSubtitles_TextBox){
                    write-ezlogs "| Removing no Subtitles found item" -logtype Libvlc
                    [void]($synchash.VideoView_Subtitles_Button.items.remove($synchash.MediaSubtitles_TextBox))
                  }
                  $Current_Subtitles | & { Process {
                      try{
                        $SubtitleName = "$($_.Language)"
                        if(-not [string]::IsNullOrEmpty($_.Description)){
                          $SubtitleName += " _ $($_.Description)"
                        }
                        if([string]::IsNullOrEmpty($SubtitleName)){
                          $SubtitleName = "Subtitle - $($_.ID)"
                        }
                        if($synchash.VideoView_Subtitles_Button.items.header -notcontains $SubtitleName){
                          write-ezlogs "| Adding Subtitle to list: $($SubtitleName)" -logtype Libvlc
                          $Menuitem = [System.Windows.Controls.MenuItem]::new()
                          $Menuitem.IsCheckable = $true
                          $Menuitem.IsChecked = $synchash.vlc.Spu -eq $_.ID
                          $Menuitem.Header = $SubtitleName
                          $Menuitem.Tag = $_.ID
                          $Menuitem.HorizontalAlignment = 'Left'
                          $Menuitem.VerticalAlignment="Center"
                          $Menuitem.Style = $synchash.Window.TryFindResource("TrayDropDownMenuitemStyle")
                          #[void]$Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EnableSubtitles_Command)
                          [void]($Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EnableSubtitles_Command))
                          [void]($synchash.VideoView_Subtitles_Button.items.add($Menuitem))     
                        }
                      }catch{
                        write-ezlogs "An exception occurred adding Subtitle $($_ | out-string)" -catcherror $_
                      }             
                  }}
                }else{
                  try{
                    write-ezlogs ">>>> Clearing Subtitles from UI/Menus" -logtype Libvlc
                    Update-Subtitles -synchash $synchash -thisApp $thisApp -clear
                  }catch{
                    write-ezlogs "An exception occurred in Update-Subtitles -clear" -catcherror $_
                  }          
                }
                if($synchash.PackIconFontAwesome_Subtitle_Spinner){
                  $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false
                }
              }                             
              $this.Stop()
            }catch{
              write-ezlogs "An exception occurred in MediaSubtitles_Update_Timer.add_tick" -showtime -catcherror $_
            }finally{
              $this.Stop()
            }
        }) 
      }
      if($synchash.VideoView_Subtitles_Button.items.header -notcontains 'Auto-Fetch'){
        $synchash.VideoView_Subtitles_Fetch = [System.Windows.Controls.MenuItem]::new()
        $synchash.VideoView_Subtitles_Fetch.HorizontalAlignment = "Center"
        $synchash.VideoView_Subtitles_Fetch.IsCheckable = $false
        if(!$synchash.PackIconFontAwesome_Subtitle_Spinner){
          $synchash.PackIconFontAwesome_Subtitle_Spinner = [MahApps.Metro.IconPacks.PackIconFontAwesome]::new()
          $synchash.PackIconFontAwesome_Subtitle_Spinner.Kind = 'SyncAltSolid'
          $synchash.PackIconFontAwesome_Subtitle_Spinner.Foreground = 'White'
          $synchash.PackIconFontAwesome_Subtitle_Spinner.Tag = $false
          $synchash.PackIconFontAwesome_Subtitle_Spinner.SpinDuration = [double]1
          $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false
        }
        $synchash.VideoView_Subtitles_Fetch.icon = $synchash.PackIconFontAwesome_Subtitle_Spinner
        $synchash.VideoView_Subtitles_Fetch.Header = "Auto-Fetch"
        $synchash.VideoView_Subtitles_Fetch.StaysOpenOnClick = $true
        $synchash.VideoView_Subtitles_Fetch.FontSize = '11'
        $synchash.VideoView_Subtitles_Fetch.VerticalAlignment="Center"
        [void]($synchash.VideoView_Subtitles_Fetch.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.FetchSubtitles_Command))
        [void]($synchash.VideoView_Subtitles_Fetch.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.FetchSubtitles_Command))
        if($synchash.VideoView_Subtitles_Button.items -notcontains $synchash.VideoView_Subtitles_Fetch){
          [void]($synchash.VideoView_Subtitles_Button.items.add($synchash.VideoView_Subtitles_Fetch))
        }  
      }
      $Current_Subtitles = $synchash.vlc.media.tracks | where-Object {$_.TrackType -eq 'Text'}
      if($Current_Subtitles.count -lt 1 -and $synchash.VideoView_Subtitles_Button.items -notcontains $synchash.MediaSubtitles_TextBox){
        $menu_textblock = [System.Windows.Controls.MenuItem]::new()
        $menu_textblock.HorizontalAlignment = "Center"
        $menu_textblock.Header = "No Subtitles Found"
        $menu_textblock.Name = 'MediaSubtitles_TextBox'
        $menu_textblock.FontSize = '11'
        $menu_textblock.FontStyle = 'Italic'
        $menu_textblock.Opacity = "0.8"
        $menu_textblock.IsEnabled = $false
        $menu_textblock.Style = $synchash.Window.TryFindResource("TrayDropDownMenuitemStyle")
        $menu_textblock.VerticalAlignment="Center"
        $synchash.MediaSubtitles_TextBox = $menu_textblock
        #$synchash.vlc.media.tracks
        [void]($synchash.VideoView_Subtitles_Button.items.add($synchash.MediaSubtitles_TextBox))
      }else{
        if($synchash.VideoView_Subtitles_Button.items.header -notcontains 'Increase Delay'){
          $synchash.VideoView_Subtitles_addDelay = [System.Windows.Controls.MenuItem]::new()
          $synchash.VideoView_Subtitles_addDelay.HorizontalAlignment = "Center"
          $synchash.VideoView_Subtitles_addDelay.IsCheckable = $false
          if(!$synchash.PackIconForkAwesome_Subtitle_PlusSolid){
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid = [MahApps.Metro.IconPacks.PackIconFontAwesome]::new()
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid.Height = '10'
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid.Width = '10'
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid.Kind = 'PlusSolid'
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid.Foreground = 'White'
            $synchash.PackIconForkAwesome_Subtitle_PlusSolid.Tag = $false
            #$synchash.PackIconForkAwesome_Subtitle_PlusSolid.SpinDuration = [double]1
            #$synchash.PackIconForkAwesome_Subtitle_PlusSolid.Spin = $false
          }
          $synchash.VideoView_Subtitles_addDelay.icon = $synchash.PackIconForkAwesome_Subtitle_PlusSolid
          $synchash.VideoView_Subtitles_addDelay.Header = "Increase Delay"
          $synchash.VideoView_Subtitles_addDelay.StaysOpenOnClick = $true
          $synchash.VideoView_Subtitles_addDelay.FontSize = '11'
          $synchash.VideoView_Subtitles_addDelay.VerticalAlignment="Top"
          [void]($synchash.VideoView_Subtitles_addDelay.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.DelaySubtitles_Command))
          [void]($synchash.VideoView_Subtitles_addDelay.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.DelaySubtitles_Command))
          if($synchash.VideoView_Subtitles_Button.items -notcontains $synchash.VideoView_Subtitles_addDelay){
            [void]($synchash.VideoView_Subtitles_Button.items.add($synchash.VideoView_Subtitles_addDelay))
          }  
        }
        if($synchash.VideoView_Subtitles_Button.items.header -notcontains 'Decrease Delay'){
          $synchash.VideoView_Subtitles_removeDelay = [System.Windows.Controls.MenuItem]::new()
          $synchash.VideoView_Subtitles_removeDelay.HorizontalAlignment = "Left"
          $synchash.VideoView_Subtitles_removeDelay.IsCheckable = $false
          if(!$synchash.PackIconForkAwesome_Subtitle_MinusSolid){
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid = [MahApps.Metro.IconPacks.PackIconFontAwesome]::new()
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid.Height = '10'
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid.Width = '10'
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid.Kind = 'MinusSolid'
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid.Foreground = 'White'
            $synchash.PackIconForkAwesome_Subtitle_MinusSolid.Tag = $false
            #$synchash.PackIconForkAwesome_Subtitle_PlusSolid.SpinDuration = [double]1
            #$synchash.PackIconForkAwesome_Subtitle_PlusSolid.Spin = $false
          }
          $synchash.VideoView_Subtitles_removeDelay.icon = $synchash.PackIconForkAwesome_Subtitle_MinusSolid
          $synchash.VideoView_Subtitles_removeDelay.Header = "Decrease Delay"
          $synchash.VideoView_Subtitles_removeDelay.StaysOpenOnClick = $true
          $synchash.VideoView_Subtitles_removeDelay.FontSize = '11'
          $synchash.VideoView_Subtitles_removeDelay.VerticalAlignment="Center"
          [void]($synchash.VideoView_Subtitles_removeDelay.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.DelaySubtitles_Command))
          [void]($synchash.VideoView_Subtitles_removeDelay.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.DelaySubtitles_Command))
          if($synchash.VideoView_Subtitles_Button.items -notcontains $synchash.VideoView_Subtitles_removeDelay){
            [void]($synchash.VideoView_Subtitles_Button.items.add($synchash.VideoView_Subtitles_removeDelay))
          }  
        }
      }
      $menu_separator = [System.Windows.Controls.Separator]::new()
      $menu_separator.OpacityMask = $synchash.Window.TryFindResource('SeparatorGradient')
      $menu_separator.HorizontalAlignment = "Stretch"
      $menu_separator.Margin = "0,5,23,5"
      $menu_separator.Height = '1'
      $menu_separator.MinWidth = '100'
      $menu_separator.VerticalAlignment="Center"
      if($synchash.VideoView_Subtitles_Button.items -notcontains $menu_separator){
        [void]($synchash.VideoView_Subtitles_Button.items.add($menu_separator))
      } 
    }else{ 
      if(!$synchash.MediaSubtitles_Update_Timer){
        if($synchash.VideoView_Subtitles_Button){
          $synchash.VideoView_Subtitles_Button.ArrowVisibility = 'Visible'
        } 
        Update-Subtitles -synchash $synchash -thisApp $thisApp -Startup
      } 
      $synchash.MediaSubtitles_Update_Timer.tag = [PSCustomObject]@{
        'UpdateSubtitles' = $UpdateSubtitles
        'Add_Subtitles' = $Add_Subtitles
        'Subtitles_Path' = $Subtitles_Path
        'Visibility' = $Visibility
        'Show' = $Show
        'Hide' = $hide
        'Close' = $close
      }
      $synchash.MediaSubtitles_Update_Timer.start()
    }
  }catch{
    write-ezlogs "An exception occurred in Update-Subtitles" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-Subtitles Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Media','Start-Streamlink','Start-MediaCast','Start-NewMedia','Update-MediaRenderers','Update-Subtitles')