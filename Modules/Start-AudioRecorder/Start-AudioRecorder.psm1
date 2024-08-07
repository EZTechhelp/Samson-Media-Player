<#
    .Name
    Start-AudioRecorder

    .Version 
    0.1.0

    .SYNOPSIS
    Records audio output from the primary/default audio device

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
#region Start-AudioRecorder Function
#----------------------------------------------
function Start-AudioRecorder
{
  Param (
    $thisApp,
    $synchash,
    $write_tags,
    $media,
    [parameter(Mandatory=$true)]
    [string]$Savepath,
    [parameter(Mandatory=$true)]
    [validateset("wav","mp3","wma","aac","flac")]
    [string]$Output_Type,
    [string]$bitrate = 320000,
    [string]$filename,
    [timespan]$duration,
    [switch]$Overwrite,
    [switch]$Startup,
    [switch]$Verboselog
  )
  try{  
    write-ezlogs ">>>> Starting new loopback recording" -showtime 
    $ffmpeg_Path = "$($thisApp.config.Current_folder)\Resources\flac"
    $envpaths = [Environment]::GetEnvironmentVariable('Path') -split ';'
    $envpaths2 = $env:path -split ';'
    if($ffmpeg_Path -notin $envpaths2){
      write-ezlogs ">>>> Adding ffmpeg to user enviroment path $ffmpeg_Path"
      $env:path += ";$ffmpeg_Path"
<#      if($ffmpeg_Path -notin $envpaths){
        [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$ffmpeg_Path",[EnvironmentVariableTarget]::User)
      }#>
    }
    if(![System.IO.Directory]::Exists($Savepath)){
      write-ezlogs " | Creating new output directory $Savepath" -showtime -warning
      $null = New-item -Path $Savepath -ItemType Directory -Force
    }
    if($output_type -eq 'flac'){
      $file_ext = 'wav'
    }else{
      $file_ext = $output_type
    }
    if($Media.source -eq 'Spotify' -or $Media.url -match 'spotify\:'){
      $type = 'Spotify'
    }
    if(-not [string]::IsNullOrEmpty($filename)){
      #cleaning illegal path chars
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
      $pattern = "[™`?�:$illegal]"
      $filename = ([Regex]::Replace($filename, $pattern, '')).trim() 
      $file_output = [system.io.path]::Combine($Savepath,"$filename.$file_ext")
      $temp_file_output = [system.io.path]::Combine($thisApp.Config.Temp_Folder,"$filename.$file_ext")
      write-ezlogs " | Audio file output name: $file_output" -showtime
    }else{
      $file_output = [system.io.path]::Combine($Savepath,"$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt').$file_ext")
      $temp_file_output = [system.io.path]::Combine($thisApp.Config.Temp_Folder,"$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt').$file_ext")
      write-ezlogs "No file name specified, using default output format: $file_output" -showtime -warning
    }

    if([system.io.file]::Exists($file_output)){
      if($Overwrite){
        write-ezlogs "Existing file found at $file_output, Overwriting" -showtime -warning
      }else{
        write-ezlogs "Existing file found at $file_output, ovewrite not specified, haulting further actions" -showtime -warning
        return
      }
    }
    if($Output_Type -ne "wav" -and $Output_Type -ne "flac"){
      write-ezlogs " | Output bitrate for $Output_Type`: $bitrate" -showtime
    }else{
      $bitrate = $null
    }
    $start_playback_timeout = 0
    if($type -eq 'Spotify'){
      if($thisApp.Config.Spotify_WebPlayer){
        write-ezlogs "Waiting for Spotify Web Player audio playback to begin...." -showtime
        while((!$synchash.Spotify_WebPlayer.is_started) -and $start_playback_timeout -lt 600){
          start-sleep -Milliseconds 100
          $start_playback_timeout++
        }
      }else{
        write-ezlogs "Waiting for Spotify audio playback to begin...." -showtime
        while(!$synchash.current_track_playing.is_playing -and $start_playback_timeout -lt 6000){
          start-sleep -Milliseconds 100
          $start_playback_timeout++
        }
      }
    }elseif($type -eq 'Youtube'){
      write-ezlogs "To record Youtube videos, simply select 'Download' from the Right-Click menu on any Youtube video " -showtime -Warning -AlertUI
      return
    }else{
      write-ezlogs "The Recorder only supports recording Spotify Media for now. Support for other types may be added in later versions." -showtime -Warning -AlertUI
      return
    }
    if($start_playback_timeout -ge 600){
      write-ezlogs "Timed out waiting for media playback to begin, canceling recording" -showtime -Warning -AlertUI
      #Update-Notifications -Level 'WARNING' -Message "Timed out waiting for media playback to begin, canceling recording" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold
      return
    }
    write-ezlogs "Starting new recording stopwatch timer for $($duration)...." -showtime    
    $synchash.AudioRecorder = @{}
    $recording_stopwatch = [system.diagnostics.stopwatch]::StartNew()
    $Recording = [PSCore.LoopbackRecorder]
    $Recording::StartRecording($temp_file_output,$bitrate)
    $synchash.AudioRecorder.isRecording = $true
    $synchash.AudioRecorder.RecordingMedia = $write_tags
    if($synchash.RecordButton_ToggleButton){
      $synchash.Window.Dispatcher.invoke([action]{
          $synchash.RecordButton_ToggleButton.isChecked = $true
      },'Normal')
    }
    Update-Notifications -Level 'INFO' -Message "Recording output started for $temp_file_output" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -LevelFontWeight Bold -EnableAudio:$false
    while(($recording_stopwatch.Elapsed -le $duration -or $synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio) -and $synchash.AudioRecorder.isRecording){
      start-sleep 1
    }
    if($synchash.RecordButton_ToggleButton){
      $synchash.Window.Dispatcher.invoke([action]{
          $synchash.RecordButton_ToggleButton.isChecked = $false
      },'Normal')
    }
    $Recording::StopRecording()
    $recording_stopwatch.stop()
    if($synchash.AudioRecorder.Dispose){
      write-ezlogs "Disposing of recorded audio $temp_file_output" -showtime -warning
      if([System.IO.file]::Exists($temp_file_output)){
        $null = Remove-item $temp_file_output -Force
      }
      $synchash.AudioRecorder = $null
      return
    }
    $synchash.AudioRecorder = $null
    write-ezlogs ">>>> Stopped recording at $($recording_stopwatch.Elapsed)" -showtime
    if([System.IO.file]::Exists($temp_file_output)){
      write-ezlogs "[SUCCESS] Audio recording file saved to $temp_file_output" -showtime
      start-sleep -Milliseconds 500
      if($output_type -eq 'flac'){   
        try{
          $flac_output = [System.IO.path]::ChangeExtension($temp_file_output,'flac')
          write-ezlogs ">>>> Converting wav to raw wv with wavpack" -showtime
          try{
            wavpack $temp_file_output -y
          }catch{
            write-ezlogs "An exception occurred converting $temp_file_output to raw wv with wavpack" -showtime -catcherror $_
          }
          $raw_wv = [System.IO.path]::ChangeExtension($temp_file_output,'wv')
          if([System.IO.file]::Exists($raw_wv)){
            write-ezlogs " | Found raw converted wv $raw_wv" -showtime
            write-ezlogs " | Converting wv to flac with ffmpeg: $flac_output" -showtime
            try{
              ffmpeg -i $raw_wv -acodec flac $flac_output -y
            }catch{
              write-ezlogs "An exception occurred converting $raw_wv to flac with ffmpeg" -showtime -catcherror $_
            }         
          }else{
            write-ezlogs "Something went wrong, cannot find converted raw wv file $raw_wv" -showtime -warning
          }                   
          if([System.IO.file]::Exists($flac_output)){
            write-ezlogs "[SUCCESS] Successfully converted $temp_file_output to $flac_output" -showtime
            $file_output = [System.IO.path]::ChangeExtension($file_output,'flac')
            write-ezlogs " | Moving converted file $temp_file_output to target destination $file_output"           
            $null = Move-item $flac_output -Destination $file_output -Force
            write-ezlogs "[Cleanup] | Removing original wav file $temp_file_output" -showtime
            $null = Remove-item $temp_file_output -Force
            if([System.IO.file]::Exists($raw_wv)){
              write-ezlogs "[Cleanup] | Removing converted wv file $raw_wv" -showtime
              $null = Remove-item $raw_wv -Force
            }
          }else{
            write-ezlogs "Something went wrong, cannot find converted flac from $temp_file_output to $flac_output" -showtime -warning
            if([System.IO.file]::Exists($raw_wv)){
              write-ezlogs "[Cleanup] | Removing converted wv file $raw_wv" -showtime
              $null = Remove-item $raw_wv -Force
            }
            if([System.IO.file]::Exists($temp_file_output)){
              write-ezlogs "[Cleanup] | Removing original output file $temp_file_output" -showtime
              $null = Remove-item $temp_file_output -Force
            }
            Update-Notifications -Level 'WARNING' -Message "Something went wrong, unable to convert recording output to flac!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -LevelFontWeight Bold -Message_color 'Orange'
            return
          }
        }catch{
          write-ezlogs "An exception occurred converting $file_output to flac" -showtime -catcherror $_
        }
      }else{
        write-ezlogs " | Moving converted file $temp_file_output to target destination $file_output"           
        $null = Move-item $temp_file_output -Destination $file_output -Force
      }
      if($write_tags){     
        try{ 
          if($write_tags.Id){
            $track_info = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $write_tags.Id
            if($track_info){
              $write_tags = $track_info
            }
          }
          write-ezlogs ">>>> Writing media tags info to file for media $($write_tags | out-string)" -showtime
          $taginfo = [taglib.file]::create($file_output) 
          if($taginfo.Tag){           
            if($write_tags.title){
              $taginfo.tag.title = $write_tags.title
            }elseif($write_tags.name){
              $taginfo.tag.name = $write_tags.name
            }
            if($write_tags.Artist){
              $taginfo.tag.Artists = $write_tags.Artist
            }
            if($write_tags.Album){
              $taginfo.tag.Album = $write_tags.Album
            }
            if($write_tags.track){
              $taginfo.tag.Track = $write_tags.track
            }
            if($write_tags.disc_number){
              $taginfo.tag.disc = $write_tags.disc_number
            }
            if(-not [string]::IsNullOrEmpty($write_tags.cached_image_path)){
              $image = $($write_tags.cached_image_path | select -First 1)
            }elseif(-not [string]::IsNullOrEmpty($write_tags.thumbnail)){
              $image = $($write_tags.thumbnail | select -First 1)
            }else{
              $image = $null
            } 
            $image_Cache_path = $Null
            if($image)
            {
              write-ezlogs "Media Image found: $($image)" -showtime      
              if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
                write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime
                $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
              }
              if($write_tags.Album_ID){
                $imageid = $write_tags.Album_ID
              }else{ 
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Image | split-path -Leaf)-Local")
                $imageid = [System.Convert]::ToBase64String($encodedBytes)         
              }                    
              $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($imageid).png")
              if([System.IO.File]::Exists($image_Cache_path)){
                $cached_image = $image_Cache_path
                write-ezlogs "| Found cached image: $cached_image" -showtime
              }elseif($image){         
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
                if(!([System.IO.File]::Exists($image_Cache_path))){
                  try{
                    if([System.IO.File]::Exists($image)){
                      if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $image to cache path $image_Cache_path" -enablelogs -showtime}
                      $null = Copy-item -LiteralPath $image -Destination $image_Cache_path -Force
                    }else{
                      $uri = new-object system.uri($image)
                      write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime
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
            if([System.IO.File]::Exists($cached_image)){
              write-ezlogs " | Adding image to tag pictures: $cached_image" -enablelogs -showtime
              $picture = [TagLib.Picture]::CreateFromPath($cached_image)
              $taginfo.Tag.Pictures = $picture
            }
            <#            if($write_tags.External_url){
                $taginfo.tag.Description = "$($write_tags.External_url)"              
            }#>
            <#            if($write_tags.album_info.total_tracks){
                $taginfo.tag.TrackCount = $write_tags.album_info.total_tracks             
            }#>
            if($write_tags.release_date){
              try{
                $taginfo.tag.Year = [datetime]::Parse($write_tags.release_date).year
              }catch{
                write-ezlogs "An exception occured parsing year from album release date: $($write_tags.release_date)" -showtime -catcherror $_
              }
            }          
            if($write_tags.Artist_ID){
              try{
                $artist_info = Get-Artist -id $write_tags.Artist_ID -ApplicationName $($thisApp.Config.App_Name)
                if($artist_info.genres){
                  $taginfo.tag.Genres = $artist_info.genres
                }
              }catch{
                write-ezlogs "An exception occurred getting artist info artist id: $($write_tags.artists.id)" -showtime -catcherror $_
              }
            }
            $taginfo.tag.Comment = "Created with $($thisApp.Config.App_Name) - $($thisApp.Config.App_Version)"
            try{
              write-ezlogs ">>>> Saving new tag info: $($taginfo.tag | out-string)" -showtime
              $taginfo.Save()
              $taginfo.dispose()
            }catch{
              write-ezlogs "An exception occurred saving tag info to $file_output" -showtime -catcherror $_
            }
          }
        }catch{
          write-ezlogs "An exception occurred getting taginfo for $file_output" -showtime -catcherror $_
        } 
      }
      Update-Notifications -Level 'INFO' -Message "New Audio recording saved to $file_output" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -Message_color 'LightGreen' -LevelFontWeight Bold 
    }else{
      write-ezlogs "Unable to find audio recording file at $file_output" -showtime -warning
      Update-Notifications -Level 'WARNING' -Message "Unable to find audio recording file at $file_output" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout -Message_color 'Orange' -MessageFontWeight bold -LevelFontWeight Bold  
    }
  }catch{
    write-ezlogs 'An exception occurred in Start-AudioRecorder' -showtime -catcherror $_
    if($recording_stopwatch){
      $recording_stopwatch.stop()
    }
    if($Recording){
      $Recording::StopRecording()
    }
  }
}
#---------------------------------------------- 
#endregion Start-AudioRecorder Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-AudioRecorder')