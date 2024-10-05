<#
    .Name
    Invoke-DownloadMedia

    .Version 
    0.1.0

    .SYNOPSIS
    Downloads media files from URL or youtube via yt-dlp  

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
#region Invoke-DownloadMedia Function
#----------------------------------------------
function Invoke-DownloadMedia{

  param (
    $Media,
    [string]$Download_URL,
    [string]$Title_name,
    $synchash,
    $thisScript,
    $Download_Path,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    $thisApp,
    [switch]$Show_notification,
    [switch]$Verboselog
  )

  if($Media.title){
    $title = $Media.title
  }elseif($Media.name){
    $title = $Media.name
  }elseif($Title_name){
    $title = $Title_name
  }

  #$mediatitle = $($Media.title)
  #$encodedtitle = $media.id
  #$artist = $Media.Artist
  if($Download_URL){
    $media_link = $($Download_URL).trim()
  }else{
    if(-not [string]::IsNullOrEmpty($Media.url)){
      $media_link = "$($Media.url)".trim()
    }elseif(-not [string]::IsNullOrEmpty($Media.uri)){
      $media_link = "$($Media.uri)".trim()
    }
  }
  write-ezlogs ">>>> Selected Media to download $($title) -- $media_link" -showtime
  #$length = $($Media.songinfo.length  | out-string)
  $synchash.Download_message = ''
  $vlc_scriptblock = {
    param (
      $Media = $media,
      [string]$Download_URL = $Download_URL,
      [string]$Title_name = $Title_name,
      $synchash = $synchash,
      $Download_Path = $Download_Path,
      $thisApp = $thisApp,
      $media_link = $media_link,
      $title = $title,
      [switch]$Show_notification = $Show_notification,
      [switch]$Verboselog = $Verboselog
    )
    $media_formats = @(
      '*.Mp3'
      '*.mp4'
      '*.wav'
      '*.flac'
      '*.h264'
      '*.avi'
      '*.mkv'
      '*.webm'
      '*.h265'
      '*.mov'
      '*.wmv'
      '*.h264'
      '*.mpeg'
      '*.mpg4'
      '*.movie'
      '*.mpgx'
      '*.vob'
      '*.3gp'
      '*.m2ts'
      '*.aac'
    )  
    $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl"
    $ffmpeg_Path = "$($thisApp.config.Current_folder)\Resources\flac"
    $envpaths = [Environment]::GetEnvironmentVariable('Path') -split ';'
    $envpaths2 = $env:path -split ';'
    $synchash.Download_Cancel = $false
    if($ffmpeg_Path -notin $envpaths2){
      write-ezlogs ">>>> Adding ffmpeg to user enviroment path $ffmpeg_Path"
      $env:path += ";$ffmpeg_Path"
<#      if($ffmpeg_Path -notin $envpaths){
        [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$ffmpeg_Path",[EnvironmentVariableTarget]::User)
      }#>
    }
    if($youtubedl_path -notin $envpaths2){
      write-ezlogs ">>>> Adding ytdlp to user enviroment path $youtubedl_path"
      $env:path += ";$youtubedl_path"
<#      if($youtubedl_path -notin $envpaths){
        [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$youtubedl_path",[EnvironmentVariableTarget]::User)
      }#>
    }
    $yt_dlp_tempfile = "$($thisApp.config.Temp_folder)\yt_dlp.log"     
    $thisApp.config.Download_logfile = $yt_dlp_tempfile  
    if(($media_link -match 'youtube\.com' -or $media_link -match 'youtu\.be' -or $media_link -match 'yewtu.be|invidious' -or $media_link -match 'soundcloud\.com') -and $media_link -notmatch 'tv\.youtube\.com'){
      if($media_link -match '&t='){
        $media_link = ($($media_link) -split('&t='))[0].trim()
      }
      if($media_link -match "v="){
        $youtube_id = ($($media_link) -split('v='))[1].trim()
      }elseif($media_link -match 'list='){
        if($media_link -match "\&index="){
          $PlaylistIndex = [regex]::matches($media_link, "\&index=(?<value>.*)")| %{$_.groups[1].value}
          $media_link = ($($media_link) -split('\&index='))[0].trim()
        }
        $playlist_id = ($($media_link) -split('list='))[1].trim()
        $isYoutubePlaylist = $true  
        write-ezlogs "Youtube link is playlist, will attempt to download all videos" -showtime -warning
        $youtube_playlistid = $youtube_id
      }else{
        $youtube_id = $Null
      } 
      if($playlist_id){
        $Playlist_items = Get-YouTubePlaylistItems -Id $playlist_id
        if($PlaylistIndex){
          $Index = $PlaylistIndex -1
        }else{
          $Index = 0
        }
        $Playlistitem = $Playlist_items[$Index]
        $youtube_id = $Playlistitem.contentDetails.videoId
      }
      if($youtube_id -match '\&pp='){
        $youtube_id = ($youtube_id -split '\&pp=')[0]
      }           
      write-ezlogs " | Getting best quality video and audio links from yt_dlp" -showtime 
      if($youtube_id){
        $sponserblock = "--sponsorblock-remove all"
        $format = "bestvideo+bestaudio"
        $media_Link = "https://www.youtube.com/watch/$youtube_id"
      }else{
        $sponserblock = $Null
        $format = "bestaudio"
      }
      if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
        $command = "& `"$($thisApp.config.Current_folder)\Resources\youtube-dl\yt-dlp.exe`" -f bestvideo+bestaudio $($media_link) -P `"$Download_Path`" -o `"%(title)s.%(ext)s`" --cookies-from-browser $($thisApp.config.Youtube_Browser) --audio-quality 0 --ffmpeg-location `"$ffmpeg_Path`" --extractor-args `"youtube:player_client=default,ios`" --embed-thumbnail --add-metadata --compat-options embed-metadata $sponserblock *>'$yt_dlp_tempfile'"
      }else{
        $command = "& `"$($thisApp.config.Current_folder)\Resources\youtube-dl\yt-dlp.exe`" -f $format $($media_link) -P `"$Download_Path`" -o `"%(title)s.%(ext)s`" --audio-quality 0 --embed-thumbnail --ffmpeg-location `"$ffmpeg_Path`" --add-metadata --extractor-args `"youtube:player_client=default,ios`" --compat-options embed-metadata $sponserblock *>'$yt_dlp_tempfile'"
      }  
    }else{
      write-ezlogs "No valid youtube URL was provided!" -showtime -warning
      Update-Notifications  -Level 'WARNING' -Message "No valid youtube URL was provided or found ($media_link)" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
      return
    }     
    try{
      $UID = (Get-Random)
      $synchash.Download_UID = $UID
      $synchash.Download_message = "Downloading: $($title)"
      Update-Notifications -id $UID -Level 'INFO' -Message $synchash.Download_message -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
    }catch{
      write-ezlogs "An exception occurred adding items to notifications grid" -showtime -catcherror $_
    }
    $downloaded_Files = [System.Collections.Generic.List[String]]::new()
    $Files_to_Import = [System.Collections.Generic.List[String]]::new()
    write-ezlogs "[yt_dlp Download] >>>> Executing yt_dlp with command '$command'" -showtime -enablelogs -color Cyan
    if([System.IO.File]::Exists($yt_dlp_tempfile)){
      $null = remove-item $yt_dlp_tempfile -Force
    }
    $block = 
    {
      Param
      (
        $command
      
      )
      $console_output_array = invoke-expression $command -ErrorAction Ignore -Verbose    
    }   
    #Remove all jobs and set max threads
    Get-Job | Remove-Job -Force
    $MaxThreads = 3
  
    #Start the jobs. Max 4 jobs running simultaneously.
    While ($(Get-Job -state running).count -ge $MaxThreads)
    {Start-Sleep -Milliseconds 3}
    Write-EZLogs -text ">>>> Executing yt_dlp`n" -showtime -color cyan
    $Null = Start-Job -Scriptblock $Block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
    Write-EZLogs '-----------yt_dlp Log Entries-----------'            
    #Wait for all jobs to finish.
    $yt_dlp_start_timer = 0
    While(!(get-process yt-dlp -ErrorAction SilentlyContinue) -and $yt_dlp_start_timer -lt 120){
      $yt_dlp_start_timer++
      start-sleep -Milliseconds 500
    }  
    $count = 0 
    $synchash.Download_status = $true
    $Synchash.downloadTimer.start()
    if($yt_dlp_start_timer -ge 120){
      write-ezlogs "Timed out waiting for Download to begin!" -showtime -warning
      Update-Notifications -id $UID -Level 'WARNING' -Message "Timed out waiting for Download to begin!" -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -clear -Open_Flyout
    }else{
      While ($(Get-Job -State Running).count -gt 0 -or (get-process 'yt-dlp' -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if(!([System.IO.File]::Exists($yt_dlp_tempfile)))
        {Start-Sleep -Milliseconds 500}
        else
        {        
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait         
          Get-Content -Path $yt_dlp_tempfile -force -Tail 1 | ForEach {
            $count++
            Write-EZLogs "$($_)" -showtime -Dev_mode
            $speedpattern = 'at (?<value>.*) ETA'
            $sizepattern ='of (?<value>.*) at'
            $progresspattern ='\[download\]  (?<value>.*)% of'
            $etapattern ='ETA (?<value>.*)'
            $embedthumbpattern = "\[EmbedThumbnail\] (?<value>.*): Adding thumbnail to `"(?<value>.*)`""
            $addmetadatapattern = "\[Metadata\](?<value>.*)Adding metadata to `"(?<value>.*)`""
            $downloaddestpattern = "\[download\] Destination: (?<value>.*)"
            $multiDownloadpattern = 'Downloading video (?<value>.*) of (?<value>.*)'
            if($synchash.Download_Cancel){
              $synchash.Download_status = $false
              write-ezlogs "Breaking out of yt-dlp log monitoring due to cancel status" -warning
              break
            }
            if($_ -match $multiDownloadpattern){
              $totalDownloads = ([regex]::matches($_, $multiDownloadpattern)| %{$_.groups[1].value} )
              write-ezlogs ">>>> Number of videos to download: $totalDownloads" -showtime
              $currentdownload = ([regex]::matches($_, 'Downloading video (?<value>.*) of ')| %{$_.groups[1].value} )
              write-ezlogs ">>>> Currently downloading video: $currentdownload" -showtime 
            }
            if($_ -match $speedpattern){
              $speed = ([regex]::matches($_, $speedpattern)| %{$_.groups[1].value} )
            }
            if($_ -match $sizepattern){
              $download_size = ([regex]::matches($_, $sizepattern)| %{$_.groups[1].value} )
            }
            if($_ -match $progresspattern){
              [int]$progress = ([regex]::matches($_, $progresspattern)| %{$_.groups[1].value} )
            } 
            if($_ -match $etapattern){
              $eta = ([regex]::matches($_, $etapattern)| %{$_.groups[1].value} )
            }                                         
            if($progress){
              try{
                if($totalDownloads -and $currentdownload){
                  $download_message = "($progress%) Downloading ($currentdownload of $totalDownloads) $($title) at $speed - Download Size: $download_size - ETA $eta"
                }else{
                  $download_message = "($progress%) Downloading $($title) at $speed - Download Size: $download_size - ETA $eta"
                }
                $synchash.Download_status = $true
                $synchash.Download_message = $download_message
                $synchash.Download_UID = $UID
              }catch{
                write-ezlogs "An exception occurred updating the notification and message with ID $UID" -showtime -catcherror
              }
            }
            if($_ -match "\[download\] (?<value>.*) has already been downloaded"){           
              $downloaded_File = $([regex]::matches($_, "\[download\] (?<value>.*) has already been downloaded") | %{$_.groups[1].value}) 
              $downloaded_File = ($downloaded_File).trim()
              if([System.IO.File]::Exists($downloaded_File)){              
                write-ezlogs "Media file $downloaded_File already exists in the specified directory!" -showtime -warning
                $message = "Media file $downloaded_File already exists in the specified directory!"
                $level = 'WARNING'
                $synchash.Download_message = "Media file $downloaded_File already exists in the specified directory!"
              }            
              #if(!$(get-process yt_dlp -ErrorAction SilentlyContinue)){write-ezlogs "Ended due to yt_dlp process ending ending" -showtime;break }
            }
            if($_ -match "ERROR\:"){                      
              write-ezlogs "Media file $downloaded_File already exists in the specified directory!" -showtime -warning
              $message = "$_"
              $level = 'ERROR'
              $synchash.Download_message = $message           
            }
            if($_ -match $embedthumbpattern -or $_ -match $downloaddestpattern -or $_ -match $addmetadatapattern){
              if($_ -match $addmetadatapattern){
                $downloaded_File = $([regex]::matches($_, $addmetadatapattern) | %{$_.groups[1].value})  
              }elseif($_ -match $downloaddestpattern){
                $downloaded_File = $([regex]::matches($_, $downloaddestpattern) | %{$_.groups[1].value})  
              }else{
                $downloaded_File = $([regex]::matches($_, $embedthumbpattern) | %{$_.groups[1].value})  
              }             
              $downloaded_File = ($downloaded_File).trim()   
              if([System.IO.File]::Exists($downloaded_File)){
                if($totalDownloads -and $currentdownload){
                  if($downloaded_Files -notcontains $downloaded_File){
                    $null = $downloaded_Files.add($downloaded_File)
                    write-ezlogs "Media ($currentdownload of $totalDownloads) downloaded to $downloaded_File" -showtime -Success
                    $message = "[SUCCESS] Media ($currentdownload of $totalDownloads) downloaded to $downloaded_File"
                    $level = 'SUCCESS'
                  }
                }else{
                  if($downloaded_Files -notcontains $downloaded_File){
                    $null = $downloaded_Files.add($downloaded_File)
                    write-ezlogs "Media downloaded to $downloaded_File" -showtime -Success
                    $message = "[SUCCESS] Media downloaded to $downloaded_File"
                    $level = 'SUCCESS'
                  }
                }
                $synchash.Download_message = $message                           
              }
              <#              if(!$(get-process yt_dlp -ErrorAction SilentlyContinue) -and (!($totalDownloads -and $currentdownload) -or ($totalDownloads -eq $currentdownload))){
                  write-ezlogs "Ended due to job or process ending totalDownloads: $totalDownloads - currentdownload: $currentdownload";             
                  $Synchash.downloadTimer.stop()           
                  break
              }#>
              if(!(Get-Process 'yt-dlp' -ErrorAction SilentlyContinue) -and !(Get-Process 'ffmpeg' -ErrorAction SilentlyContinue)){
                write-ezlogs "Ended due to job or process ending totalDownloads: $totalDownloads - currentdownload: $currentdownload";             
                $Synchash.downloadTimer.stop()           
                break
              }               
            }  
            <#            if($(Get-Job -State Running).count -eq 0 -or !(Get-Process 'yt-dlp*' -ErrorAction SilentlyContinue) -and (!($totalDownloads -and $currentdownload) -or ($totalDownloads -eq $currentdownload))){
                write-ezlogs "Ended due to job or process ending";
                $Synchash.downloadTimer.stop()            
                break
            }#>
            if($(Get-Job -State Running).count -eq 0 -or !(Get-Process 'yt-dlp*' -ErrorAction SilentlyContinue)){
              write-ezlogs "Ended due to job or process ending";
              $Synchash.downloadTimer.stop()            
              break
            }
          }
          if($progress){
            start-sleep -Seconds 2
          }
        }      
      }
    }
    #Get information from each job.
    foreach($job in Get-Job)
    {$info=Receive-Job -Id ($job.Id)}
  
    #Remove all jobs created.
    Get-Job | Remove-Job -Force 
    $synchash.Download_status = $false
    $notification_id = $synchash.Download_UID
    $synchash.Download_UID = ''
    $Synchash.downloadTimer.stop()
     
    Write-EZLogs '---------------END Log Entries---------------' -enablelogs
    Write-EZLogs -text ">>>> yt_dlp finished. Final loop count: $count -- Downloaded_Files: $($downloaded_Files)" -showtime    
    if($synchash.Download_Cancel){
      write-ezlogs "Downloading was canceled by user action" -warning
      if(Get-Process 'yt-dlp*'){
        write-ezlogs "| Closing yt-dlp process" -warning
        Get-Process 'yt-dlp*' | Stop-Process -Force
      }
      Update-Notifications -Level 'WARNING' -Message 'Youtube video downloading was canceled' -VerboseLog -thisApp $thisapp -synchash $synchash -open_flyout
      return
    }
    if($youtube_playlistid){
      try{
        write-ezlogs ">>>> Getting playlist info and items for youtube playlist id: $youtube_playlistid" -showtime
        $playlist_info = Get-YouTubePlaylistItems -ID $youtube_playlistid
      }catch{
        write-ezlogs "An exception occurred executing Get-YoutubePlaylistItems" -showtime -catcherror $_
      }           
    }  
    if([System.IO.File]::Exists("$($thisapp.config.Media_Profile_Directory)\All-MediaProfile\All-Media-Profile.xml")){
      write-ezlogs ">>>> Importing all local media profile cache: $($thisapp.config.Media_Profile_Directory)\All-MediaProfile\All-Media-Profile.xml" -showtime
      $allLocal_media_profile = Import-SerializedXML -Path "$($thisapp.config.Media_Profile_Directory)\All-MediaProfile\All-Media-Profile.xml"
      #$allLocal_media_profile = Import-Clixml "$($thisapp.config.Media_Profile_Directory)\All-MediaProfile\All-Media-Profile.xml"
    } 
    if($downloaded_Files){
      foreach($downloaded_File in $downloaded_Files){   
        $Download_FileName = ([System.IO.Path]::GetFileNameWithoutExtension($downloaded_File))
        if(![System.IO.File]::Exists($downloaded_File)){
          $downloaded_File = [System.IO.Path]::Combine($Download_Path,"$($Download_FileName).mkv").replace('/','_').replace('.f251','')
        }
        if(![System.IO.File]::Exists($downloaded_File)){
          write-ezlogs "Unable to verify successful download of media file $downloaded_File" -showtime -warning
          $message = "[WARNING] Unable to verify successful download of media file $downloaded_File"
          $level = 'WARNING'
          Update-Notifications -id $UID -Level 'WARNING' -Message $message -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -clear -Open_Flyout
        }elseif([System.IO.File]::Exists($downloaded_File)){        
          $message = "[SUCCESS] Media downloaded to $downloaded_File"
          write-ezlogs "Media downloaded to: $downloaded_File" -showtime -success
          if($youtube_id)
          { 
            if($youtube_playlistid -and $playlist_info -and $playlist_info -ne 'Not Found'){            
              $video_info = $playlist_info | where {$_.snippet.title -eq $Download_FileName -or $_.snippet.title -match [regex]::Escape($Download_FileName)} | select -first 1  
              if($thisApp.Config.Verbose_logging){write-ezlogs "Found video info from playlist information from Youtube API $($video_info | out-string)" -showtime}        
            }else{
              try{
                write-ezlogs ">>>> Getting video info for youtube video id: $youtube_id" -showtime
                $video_info = Get-YouTubeVideo -Id $youtube_id
              }catch{
                write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
              }         
            }          
            if($video_info){
              write-ezlogs "Found Video information from Youtube API" -showtime -Success
              if($video_info.snippet.thumbnails){
                $image = $video_info.snippet.thumbnails.maxres.url | select -last 1
              }else{
                $image = "https://i.ytimg.com/vi/$youtube_id/maxresdefault.jpg"
              }
            }
            if($image){write-ezlogs "Caching thumbnail images: $($image)" -showtime}      
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime -Dev_mode
              $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
            }
            $Download_Directory = ([System.IO.Directory]::GetParent($downloaded_File)).fullname  
            $Download_FileName = ([System.IO.Path]::GetFileNameWithoutExtension($downloaded_File))                         
            $image_Cache_path = [System.IO.Path]::Combine(($Download_Directory),"$($Download_FileName).png")
            if([System.IO.File]::Exists($image_Cache_path)){
              if($thisApp.Config.Verbose_logging){write-ezlogs "Cached Image already exists at $image_Cache_path, skipping download" -showtime}
              $cached_image = $image_Cache_path
            }elseif($image){         
              if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
              if(!([System.IO.File]::Exists($image_Cache_path))){
                try{
                  if([System.IO.File]::Exists($image)){
                    if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime}
                    $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
                  }elseif((Test-URL $image)){
                    try{
                      $uri = new-object system.uri($image)
                      if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime}
                      (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                    }catch{
                      write-ezlogs "An exception occurred downloading image $uri to path $image_Cache_path" -showtime -catcherror $_
                    }
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
                  $cached_image = $image_Cache_path            
                }catch{
                  $cached_image = $Null
                  write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
                }
              }           
            }else{
              write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
              $cached_image = $Null        
            }                                    
          }
          try{
            $spotifyartist_pattern = 'https://open.spotify.com/artist/(?<value>.*)'
            $spotifyalbum_pattern = 'https://open.spotify.com/album/(?<value>.*)'
            $bandcamp_pattern = "https://(?<value>.*).bandcamp.com/"
            $bandcampAlbum_pattern = "https://(?<value>.*).bandcamp.com/album/(?<value>.*)"
            $pagenamepattern = "\<meta property=`"og\:site_name`" content=`"(?<value>.*)`"\>"
            if(!$cached_image){
              $directory = [System.io.directory]::GetParent($downloaded_File).fullname
              $filename = [System.io.path]::GetFileNameWithoutExtension($downloaded_File)
              $image_pattern = [regex]::new('$(?<=\.((?i)jpg|(?i)png|(?i)jpeg|(?i)bmp|(?i)webp|(?i)gif))')
              $images = [System.IO.Directory]::EnumerateFiles($directory,'*.*','TopDirectoryOnly') | where {$_ -match $image_pattern}
              if($images){
                $cached_image = $images | where {$_ -match $filename}                  
                if(!$cached_image){
                  $cached_image = $images | where {$_ -match 'cover'}
                }                  
                if(!$cached_image){
                  $cached_image = $images | where {$_ -match 'album'}
                }                  
              }
            }
            $taginfo = [taglib.file]::create($downloaded_File)
            if($taginfo.Tag){
              if([System.IO.File]::Exists($cached_image)){
                write-ezlogs " | Adding image to tag pictures: $cached_image" -enablelogs -showtime
                try{
                  $picture = [TagLib.Picture]::CreateFromPath($cached_image)
                  $taginfo.Tag.Pictures = $picture
                }catch{
                  write-ezlogs "An exception occurred setting taglib image from image path $cached_image" -showtime -catcherror $_
                }
              }
              if([string]::IsNullOrEmpty($taginfo.tag.Description) -and $taginfo.tag.SimpleTags.DESCRIPTION){
                $taginfo.tag.Description = $taginfo.tag.SimpleTags["DESCRIPTION"][0].ToString()
                if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting description from SimpleTags: $($taginfo.tag.Description)" -enablelogs -showtime}
              }elseif($video_info.snippet.description){
                $taginfo.tag.Description = $video_info.snippet.description
                if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting description from Youtube API: $($taginfo.tag.Description)" -enablelogs -showtime}
              }
              #Spotify Arist lookup
              if($taginfo.tag.Description -match $spotifyartist_pattern){
                $spotifyURL = ([regex]::matches($($taginfo.tag.Description), $spotifyartist_pattern)| %{$_.groups[0].value} )
                if(Test-URL $spotifyURL){
                  try{
                    write-ezlogs "[Spotify_Lookup] | Found Spotify URL $spotifyURL" -showtime
                    $spotifyArtistID = ([regex]::matches($($taginfo.tag.Description), $spotifyartist_pattern)| %{$_.groups[1].value} )
                    if($spotifyArtistID){
                      $spotify_artist = Get-Artist -Id $spotifyArtistID -ApplicationName $thisApp.Config.App_Name
                    }
                    if($spotify_artist){
                      $artist = $spotify_artist.name
                      write-ezlogs "[Spotify_Lookup] | Found Spotify Artist $artist" -showtime
                      $taginfo.tag.Artists = $artist
                      if($spotify_artist.genres){
                        write-ezlogs "[Spotify_Lookup] | Adding artist genres: $($spotify_artist.genres)" -enablelogs -showtime
                        $taginfo.tag.Genres = $spotify_artist.genres
                      }
                    }
                  }catch{
                    write-ezlogs "An exception occurred in Get-Artist for Artist ID: $spotifyArtistID" -showtime -catcherror $_
                  }
                }
                #bandcamp Arist lookup
              }elseif($taginfo.tag.Description -match $bandcamp_pattern){
                $bandcampURL = ([regex]::matches($($taginfo.tag.Description), $bandcamp_pattern)| %{$_.groups[0].value} )
                if(Test-URL $bandcampURL){
                  try{
                    write-ezlogs " | Found Bandcamp URL $bandcampURL" -showtime
                    $req=[System.Net.HTTPWebRequest]::Create($bandcampURL)
                    $req.Method='GET'         
                    $req.Timeout = 5000    
                    $response = $req.GetResponse()
                    $strm=$response.GetResponseStream();
                    $sr=New-Object System.IO.Streamreader($strm);
                    $output=$sr.ReadToEnd()
                    $bandcampPage = $output   
                    $response.Dispose()
                    $strm.Dispose()
                    $sr.Dispose()
                  }catch{
                    write-ezlogs "An exception occurred in invoke-restmethod for url $bandcampURL" -showtime -catcherror $_
                  }
                  if($bandcampPage -match $pagenamepattern){
                    $artist = ([regex]::matches($bandcampPage, "\<meta property=`"og\:site_name`" content=`"(?<value>.*)`"\>")| %{$_.groups[1].value} )
                    write-ezlogs " | Found Page name for Artist: $artist" -showtime
                    $taginfo.tag.Artists = $artist
                  }
                  if($taginfo.tag.Description -match $bandcampAlbum_pattern){
                    $album = ([regex]::matches($($taginfo.tag.Description), $bandcampAlbum_pattern)| %{$_.groups[1].value} )
                    if($album){
                      $album = $((Get-Culture).textinfo.totitlecase(($album).tolower())) 
                      write-ezlogs " | Found Bandcamp Album name $album" -showtime
                      $taginfo.tag.Album = $album
                    }
                  }
                }
              }
              #Spotify Album lookup
              if($taginfo.tag.Description -match $spotifyalbum_pattern){
                $spotifyAlbumURL = ([regex]::matches($($taginfo.tag.Description), $spotifyalbum_pattern)| %{$_.groups[0].value} )
                if(Test-URL $spotifyAlbumURL){
                  try{
                    write-ezlogs "[Spotify_Lookup] | Found Spotify Album URL $spotifyAlbumURL" -showtime
                    $spotifyAlbumID = ([regex]::matches($($taginfo.tag.Description), $spotifyalbum_pattern)| %{$_.groups[1].value} )
                    if($spotifyAlbumID){
                      $spotify_Album = Get-Album -Id $spotifyAlbumID -ApplicationName $thisApp.Config.App_Name
                    }
                    if($spotify_Album){
                      $album = $spotify_Album.name
                      write-ezlogs "[Spotify_Lookup] | Settng Album name from Spotify: $album" -showtime
                      $taginfo.tag.Album = $album
                      if($spotify_Album.total_tracks){
                        write-ezlogs "[Spotify_Lookup] | Adding total tracks: $($spotify_Album.total_tracks)" -enablelogs -showtime
                        $taginfo.tag.TrackCount = $spotify_Album.total_tracks             
                      }
                      if($spotify_Album.release_date){
                        try{
                          write-ezlogs "[Spotify_Lookup] | Adding album release date: $($spotify_Album.release_date)" -enablelogs -showtime
                          $taginfo.tag.Year = [datetime]::Parse($spotify_Album.release_date).year
                        }catch{
                          write-ezlogs "An exception occured parsing year from album release date: $($spotify_Album.release_date)" -showtime -catcherror $_
                        }
                      }
                    }
                  }catch{
                    write-ezlogs "An exception occurred in Get-Artist for Artist ID: $spotifyArtistID" -showtime -catcherror $_
                  }
                }
              }
              if(!$taginfo.tag.Artists -and $taginfo.tag.SimpleTags.ARTIST){
                $taginfo.tag.Artists = $taginfo.tag.SimpleTags["ARTIST"][0].ToString()
                write-ezlogs " | Setting artist from SimpleTags: $($taginfo.tag.Artists)" -enablelogs -showtime
              }
              if($taginfo.tag.SimpleTags.PURL){
                $url = " - $($taginfo.tag.SimpleTags["PURL"][0].ToString())"
              }
              if($video_info.snippet.title){
                write-ezlogs " | Setting title from Youtube API: $($video_info.snippet.title)" -enablelogs -showtime
                $taginfo.tag.Title = $video_info.snippet.title
              }elseif($media.title){
                write-ezlogs " | Setting title from original provided media $($media.title)" -enablelogs -showtime
                $taginfo.tag.Title = $media.title
              }elseif($Download_FileName){
                write-ezlogs " | Setting title from downloaded file name title: $($Download_FileName)" -enablelogs -showtime
                $taginfo.tag.Title = $Download_FileName
              }
              if($taginfo.tag.Artists -and $taginfo.tag.Title -match "$($taginfo.tag.Artists) - (?<value>.*)"){
                $cleaned_Title = ([regex]::matches($($taginfo.tag.Title), "$($taginfo.tag.Artists) - (?<value>.*)")| %{$_.groups[1].value})
                if($cleaned_Title){
                  write-ezlogs " | Removing Artist name from title: $($cleaned_Title)" -enablelogs -showtime
                  $taginfo.tag.Title = $("$cleaned_Title").trim()
                }
              }elseif(!$taginfo.tag.Artists -and $media.artist){
                write-ezlogs " | Setting artist from original provided media $($media.artist)" -enablelogs -showtime
                $taginfo.tag.Artists = $media.artist
              }
              $taginfo.tag.Comment = "Created/Downloaded with YT-DLP via $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)$url"
              try{
                if($verboselog){write-ezlogs ">>>> Saving new tag info: $($taginfo.tag | out-string)" -showtime}
                $taginfo.Save()
                $taginfo.dispose()
              }catch{
                write-ezlogs "An exception occurred saving tag info to $downloaded_File" -showtime -catcherror $_
              }
            }else{
              write-ezlogs "Unable to get tag information with taglib for $downloaded_File" -showtime -warning
            } 
          }catch{
            write-ezlogs "An exception occurred creating file ID tags for $downloaded_file" -showtime -catcherror $_
          }
          $temp_downloaded_File = [System.IO.path]::ChangeExtension($downloaded_File,".temp.mkv")
          if([System.IO.File]::Exists($temp_downloaded_File)){
            write-ezlogs ">>>> Removing temporary file created by yt-dlp: $temp_downloaded_File" -showtime -color cyan
            $null = Remove-item $temp_downloaded_File -Force
          }
          $temp_image_File = [System.IO.path]::ChangeExtension($downloaded_File,".webp")
          if([System.IO.File]::Exists($temp_image_File)){
            write-ezlogs ">>>> Removing temporary image file created by yt-dlp: $temp_image_File" -showtime -color cyan
            $null = Remove-item $temp_image_File -Force
          }
          $download_file_dir = [system.io.path]::GetDirectoryName($downloaded_File)
          $download_file_rootdir = [system.io.path]::GetPathRoot($downloaded_File)
          if(!$thisApp.Config.Enable_LocalMedia_Monitor){
            write-ezlogs ">>>> Checking if file $downloaded_File was downloaded to existing local media directory $download_file_dir" -showtime
            if(($allLocal_media_profile.directory.fullname -contains $download_file_dir -or $thisApp.Config.Media_Directories -contains $download_file_rootdir) -and $Files_to_Import -notcontains $download_file_dir){
              write-ezlogs " | File exists in existing local media library directory $($download_file_dir), adding to local media tables" -showtime     
              $null = $Files_to_Import.add($download_file_dir)        
            }
          }
        }           
      }  
    }else{
      write-ezlogs "Unable to verify successful download of media files $downloaded_Files" -showtime -warning
      $message = "[WARNING] Unable to verify successful download of media files $downloaded_Files"
      $level = 'WARNING'
    }     
    if($Show_notification){
      try{
        if(($totalDownloads -and $currentdownload) -and $youtube_playlistid){
          $message = "$currentdownload of $totalDownloads downloaded from playlist id $youtube_playlistid"
          if($playlist_info.playlist_info.snippet.thumbnails.default.url){
            $cached_image = $playlist_info.playlist_info.snippet.thumbnails.default.url | select -last 1
          }
        }
        Update-Notifications -id $notification_id -Level $level -Message $message -VerboseLog -thisApp $thisapp -synchash $synchash -Open_Flyout
        $startapp = Get-AllStartApps "*$($thisApp.Config.App_name)*"
        if($startapp){
          $appid = $startapp.AppID | select -last 1
        }elseif(Get-AllStartApps VLC*){
          $startapp = Get-AllStartApps VLC*
          $appid = $startapp.AppID | select -last 1
        }else{
          $startapp = Get-AllStartApps '*Windows Media Player'
          $appid = $startapp.AppID | select -last 1
        } 
        if($cached_image){
          $applogo = $image_Cache_path 
        }else{
          $applogo = "$($thisApp.Config.Current_folder)\Resources\Samson_icon1.png"
        }
        if($media_link -match 'Youtube'){
          $source = 'Youtube Media'
          if(!$cached_image){
            $applogo = "$($thisApp.Config.Current_folder)\Resources\Youtube\Material-Youtube.png"
          }
        }else{
          $source = 'Local Media'
        } 
        $Message = "$message`nSource : $source"
        New-BurntToastNotification -AppID $appid -Text $Message -AppLogo $applogo
      }catch{
        write-ezlogs "An exception occurred attempting to generate the notification balloon - image: $uri" -showtime -catcherror $_
      }     
    }
    if(@($Files_to_Import) -ge 1){
      Import-Media -Media_path $Files_to_Import -verboselog:$verboselog -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace -AddNewOnly -ImportMode 'Normal'
    }
  }
  $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}} 
  Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Download Media" -thisApp $thisApp
  Remove-Variable Variable_list
}
#---------------------------------------------- 
#endregion Invoke-DownloadMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Invoke-DownloadMedia')

