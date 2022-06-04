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
    - Module designed for EZT-MediaPlayer

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
    $synchash,
    $thisScript,
    $Download_Path,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    $thisApp,
    [switch]$Show_notification,
    $Script_Modules,
    [switch]$Verboselog
  )
  write-ezlogs ">>>> Selected Media to download $($media | out-string)" -showtime
  $mediatitle = $($Media.title)
  #$encodedtitle = $media.id
  $artist = $Media.Artist
  $url = $($Media.url)
  #$length = $($Media.songinfo.length  | out-string)

  if(!$Media -and $synchash.Media_URL.text){
    $media_link = $($synchash.Media_URL.text).trim()
  }elseif(-not [string]::IsNullOrEmpty($url)){
    $media_link = $($url).trim()
  }
  $thisApp.config.Download_message = ''
  $vlc_scriptblock = {
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
    $env:Path += ";$youtubedl_path"   
    
    $yt_dlp_tempfile = "$($thisScript.tempfolder)\\yt_dlp.log"     
    $thisApp.config.Download_logfile = $yt_dlp_tempfile 
    if($media.type -eq 'YoutubePlaylist_item' -or $media_link -match 'youtube' -or $media_link -match 'yewtu.be'){   
      if($media.webpage_url){
        if($media.webpage_url -match "youtube.com"){
          if($media.webpage_url -match "v="){
            $youtube_id = ($($media.webpage_url) -split('v='))[1].trim()
          }elseif($media.webpage_url -match 'list='){
            $youtube_id = ($($media.webpage_url) -split('list='))[1].trim()
          }else{
            $youtube_id = $Null
          } 
        }       
        write-ezlogs " | Getting best quality video and audio links from yt_dlp" -showtime 
        if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
          #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url --rm-cache-dir -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser
          #$yt_dlp = yt-dlp -f b -g $media.webpage_url -P "C:/Audio" -o "%(title)s.%(ext)s"  -j --cookies-from-browser $thisApp.config.Youtube_Browser --audio-quality 0 --embed-thumbnail --add-metadata
          #$yt_dlp = yt-dlp -f bestvideo+bestaudio $media.webpage_url -P $Download_Path -o "%(title)s.%(ext)s" --cookies-from-browser $thisApp.config.Youtube_Browser --audio-quality 0 --embed-thumbnail --add-metadata
          $command = "& `"$($thisApp.config.Current_folder)\Resources\youtube-dl\\yt-dlp.exe`" -f bestvideo+bestaudio $($media.webpage_url) -P `"$Download_Path`" -o `"%(title)s.%(ext)s`" --cookies-from-browser $($thisApp.config.Youtube_Browser) --audio-quality 0 --embed-thumbnail --add-metadata --sponsorblock-remove all *>'$yt_dlp_tempfile'"
        }else{
          #$yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url --rm-cache-dir -o '*' -j
          #$yt_dlp = yt-dlp -f b -g $media.webpage_url -P "C:/Audio" -o "%(title)s.%(ext)s"  -j --audio-quality 0 --embed-thumbnail --add-metadata
          #$yt_dlp = yt-dlp -f bestvideo+bestaudio $media.webpage_url -P $Download_Path -o "%(title)s.%(ext)s" --audio-quality 0 --embed-thumbnail --add-metadata
          $command = "& `"$($thisApp.config.Current_folder)\Resources\youtube-dl\\yt-dlp.exe`" -f bestvideo+bestaudio $($media.webpage_url) -P `"$Download_Path`" -o `"%(title)s.%(ext)s`" --audio-quality 0 --embed-thumbnail --add-metadata --sponsorblock-remove all *>'$yt_dlp_tempfile'"
        }  
      }     
    }
    try{
      $UID = (Get-Random)
      Update-Notifications -id $UID -Level 'INFO' -Message "Downloading $($Media.Title)" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
    }catch{
      write-ezlogs "An exception occurred adding items to notifications grid" -showtime -catcherror $_
    }
    write-ezlogs "[yt_dlp Download] >>>> Executing yt_dlp with command '$command'" -showtime -enablelogs -color Cyan
    $thisApp.config.Download_UID = $UID
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
    $synchash.window.Dispatcher.invoke([action]{
        $Synchash.downloadTimer.start()
    }) 
    $yt_dlp_start_timer = 0
    While(!(get-process yt-dlp -ErrorAction SilentlyContinue) -and $yt_dlp_start_timer -lt 120){
      $yt_dlp_start_timer++
      start-sleep -Milliseconds 500
    }   
    if($yt_dlp_start_timer -ge 120){
      write-ezlogs "Timed out waiting for Download to begin!" -showtime -warning
      Update-Notifications -id $UID -Level 'WARNING' -Message "Timed out waiting for Download to begin!" -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -clear -Open_Flyout
    }else{
      While ($(Get-Job -State Running).count -gt 0 -or (get-process yt-dlp -ErrorAction SilentlyContinue))
      {
        #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
        if(!([System.IO.File]::Exists($yt_dlp_tempfile)))
        {Start-Sleep -Milliseconds 500}
        else
        {        
          #$last_line = Get-Content -Path $yt_dlp_tempfile -force -Tail 1 2> $Null
          #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
          $count = 0
          Get-Content -Path $yt_dlp_tempfile -force -Tail 1 -wait | ForEach {
            $count++
            Write-EZLogs "$($_)" -showtime
            $speedpattern = 'at (?<value>.*) ETA'
            $sizepattern ='of (?<value>.*) at'
            $progresspattern =' (?<value>.*)% of'
            $etapattern ='ETA (?<value>.*)'
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
                $thisApp.config.Download_status = $true
                $thisApp.config.Download_message = "($progress%) Downloading $($Media.Title) at $speed - Download Size: $download_size - ETA $eta"
                $thisApp.config.Download_UID = $UID
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
                $thisApp.config.Download_message = "Media file $downloaded_File already exists in the specified directory!"
              }            
              #if(!$(get-process yt_dlp -ErrorAction SilentlyContinue)){write-ezlogs "Ended due to yt_dlp process ending ending" -showtime;break }
            }
            if($_ -match "\[Metadata\] Adding metadata to `"(?<value>.*)`""){
              $downloaded_File = $([regex]::matches($_, "\[Metadata\] Adding metadata to `"(?<value>.*)`"") | %{$_.groups[1].value})  
              $downloaded_File = ($downloaded_File).trim()   
              if([System.IO.File]::Exists($downloaded_File)){
                write-ezlogs "[SUCCESS] Media downloaded to $downloaded_File" -showtime -color green
                $message = "[SUCCESS] Media downloaded to $downloaded_File"
                $thisApp.config.Download_message = $message             
              }
              #if(!$(get-process yt_dlp -ErrorAction SilentlyContinue)){write-ezlogs "Ended due to yt_dlp process ending ending" -showtime;break } 
            }  
            #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
            if($(Get-Job -State Running).count -eq 0){
              write-ezlogs "Ended due to job ending";
              $synchash.window.Dispatcher.invoke([action]{
                  $Synchash.downloadTimer.stop()
              })             
              break 
            }
            #if(!$(get-process yt_dlp -ErrorAction SilentlyContinue)){write-ezlogs "Ended due to yt_dlp process ending ending" -showtime;break }
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
    $thisApp.config.Download_status = $false
    $thisApp.config.Download_UID = ''
    $synchash.window.Dispatcher.invoke([action]{
        $Synchash.downloadTimer.stop()
    })     
    Write-EZLogs '---------------END Log Entries---------------' -enablelogs
    Write-EZLogs -text ">>>> yt_dlp. Final loop count: $count" -showtime            
    if(![System.IO.File]::Exists($downloaded_File)){
      $downloaded_File = [System.IO.Path]::Combine($Download_Path,"$($media.Title).mkv")
    }
    if(![System.IO.File]::Exists($downloaded_File)){
      write-ezlogs "Unable to verify successful download of media file $downloaded_File" -showtime -warning
      $message = "[WARNING] Unable to verify successful download of media file $downloaded_File"
      Update-Notifications -id $UID -Level 'WARNING' -Message $message -VerboseLog -Message_color "Orange" -thisApp $thisApp -synchash $synchash -clear -Open_Flyout
    }elseif([System.IO.File]::Exists($downloaded_File)){
     
      if($youtube_id)
      { 
        $image = "https://i.ytimg.com/vi/$youtube_id/maxresdefault.jpg"
        if($thisApp.Config.Verbose_logging){write-ezlogs "Caching thumbnail images: $($image)" -showtime}       
        if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
          if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
          $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
        }
        #$encodeduri = $Null  
        #$encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
        #$encodeduri = [System.Convert]::ToBase64String($encodedBytes) 
        $Download_Directory = ([System.IO.Directory]::GetParent($downloaded_File)).fullname  
        $Download_FileName = ([System.IO.Path]::GetFileNameWithoutExtension($downloaded_File))                         
        $image_Cache_path = [System.IO.Path]::Combine(($Download_Directory),"$($Download_FileName).png")
        if([System.IO.File]::Exists($image_Cache_path)){
          write-ezlogs "Cached Image already exists at $image_Cache_path, skipping download" -showtime
          $cached_image = $image_Cache_path
        }elseif($image){         
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
          if(!([System.IO.File]::Exists($image_Cache_path))){
            try{
              if([System.IO.File]::Exists($image)){
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime}
                $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
              }else{
                $uri = new-object system.uri($image)
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime}
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
      if($cached_image -and $thisApp.Config.Verbose_logging){
        write-ezlogs "Media image: $cached_image" -showtime
      }     
      write-ezlogs ">>>> Checking if file was downloaded to existing local media directory" -showtime -color cyan
      foreach($directory in $thisApp.config.Media_Directories){
        $confirm_downloaded_file = (robocopy $directory 'Doesntexist' $($downloaded_File | split-path -leaf) /L /E /FP /NS /NC /NjH /NJS /NDL /NP /MT:20).trim()
        if($confirm_downloaded_file){   
          write-ezlogs " | File exists in existing local directory $($confirm_downloaded_file), adding to local media tables" -showtime     
          Import-Media -Media_Path $confirm_downloaded_file -verboselog -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisApp -use_runspace
        }
      }
    }           
    if($Show_notification){
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
        if($cached_image){
          $applogo = $image_Cache_path 
        }else{
          $applogo = "$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.png"
        }
        if($media.type -eq 'YoutubePlaylist_item'){
          $source = 'Youtube Media'
          if(!$cached_image){
            $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Youtube.png"
          }
        }else{
          $source = 'Local Media'
        } 
        $Message = "$message`nSource : $source"
        if($psversiontable.PSVersion.Major -gt 5){
          Import-module Burnttoast -Force
        }
        New-BurntToastNotification -AppID $appid -Text $Message -AppLogo $applogo
        #Show-NotifyBalloon -Message $Message -TipIcon Info -thisapp $thisapp
      }catch{
        write-ezlogs "An exception occurred attempting to generate the notification balloon - image: $uri" -showtime -catcherror $_
        #Import-module Burnttoast -Force
        #New-BurntToastNotification -AppID $appid -Text $Message -AppLogo $applogo
      }     
    }
  }  
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Download Media" -thisApp $thisApp -Script_Modules $Script_Modules
}
#---------------------------------------------- 
#endregion Invoke-DownloadMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Invoke-DownloadMedia')

