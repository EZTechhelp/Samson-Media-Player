<#
    .Name
    Add-YoutubePlayback

    .Version 
    0.1.0

    .SYNOPSIS
    Provides immediate playback of youtube media while importing 

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
#region Add-YoutubePlayback Function
#----------------------------------------------
function Add-YoutubePlayback
{
  Param (
    $thisApp,
    $thisScript,
    $synchash,
    [switch]$PlayOnly,
    [string]$youtube_id,
    [string]$LinkUri,
    [string]$linktext,
    [switch]$Startup,
    [switch]$Verboselog
  )
  if(!$youtube_id -and $LinkUri){
    try{
      if($LinkUri -match '&t='){
        $LinkUri = ($($LinkUri) -split('&t='))[0].trim()
      }          
      write-ezlogs ">>>> Adding Youtube link $LinkUri" -showtime -color cyan
      if($LinkUri -match "v="){
        $youtube_id = ($($LinkUri) -split('v='))[1].trim()    
      }elseif($LinkUri -match 'list='){
        $youtube_id = ($($LinkUri) -split('list='))[1].trim()                  
      }
    }catch{
      write-ezlogs "An exception occurred parsing youtube id form link $linkuri" -showtime -catcherror $_
    }
  }
  if($youtube_id -and $LinkUri){
    try{
      $video_info = Get-YouTubeVideo -Id $youtube_id
    }catch{
      write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
    }               
    if($video_info){
      $url = [uri]$LinkUri
      if($video_info.snippet.title){
        $title = $video_info.snippet.title
      }elseif($video_info.localizations.en.title){
        $title = $video_info.localizations.en.title
      }                                
      $description = $video_info.snippet.description
      $channel_id = $video_info.snippet.channelId
      $channel_title = $video_info.snippet.channelTitle                 
      $images = $video_info.snippet.thumbnails
      $thumbnail = $video_info.snippet.thumbnails.medium.url
      if($video_info.contentDetails.duration){
        try{
          $TimeValues = $video_info.contentDetails.duration
          if($TimeValues -match 'H'){
            $hr = [regex]::matches($TimeValues, "PT(?<value>.*)H")| %{$_.groups[1].value}
            $mins = [regex]::matches($TimeValues, "PT(?<value>.*)H(?<value>.*)M")| %{$_.groups[1].value}
            $Secs = [regex]::matches($TimeValues, "M(?<value>.*)S")| %{$_.groups[1].value}
          }elseif($TimeValues -match 'M'){
            $hr = 0
            $mins = [regex]::matches($TimeValues, "PT(?<value>.*)M")| %{$_.groups[1].value}
            $Secs = [regex]::matches($TimeValues, "M(?<value>.*)S")| %{$_.groups[1].value}
          }elseif($TimeValues -match 'S'){
            $hr = 0
            $mins = 0
            $Secs = [regex]::matches($TimeValues, "PT(?<value>.*)S")| %{$_.groups[1].value}
          }else{
            $hr = 0
            $mins = 0
            $secs = 0
          }
          if($secs -eq $null){$secs = 0}
          if($mins -eq $null){$mins = 0}
          if($hr -eq $null){$hr = 0}
          $duration = [TimeSpan]::Parse("$hr`:$mins`:$secs").TotalMilliseconds
        }catch{
          write-ezlogs "An exception occurred parsing duration $($video_info.contentDetails.duration)" -showtime -catcherror $_
        }
      }
      $viewcount = $video_info.statistics.viewCount              
    }elseif(!$title -and $linktext){
      $title = $linktext
    }else{
      $title = "Youtube Video - $youtube_id"
    }  
    $Group = 'Youtube'
    if($PlayOnly){
      $live_status = 'Temporary'
    }else{
      $live_status = $null
    }
    $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($LinkUri)-YoutubeWebLink")
    $track_encodedTitle = [System.Convert]::ToBase64String($track_encodedBytes)
    $media = New-Object PsObject -Property @{
      'title' =  $title
      'description' = $description
      'playlist_index' = ''
      'channel_id' = $channel_id
      'id' = $youtube_id
      'duration' = $duration
      'encodedTitle' = $track_encodedTitle
      'url' = $url
      'urls' = $LinkUri                
      'webpage_url' = $LinkUri
      'thumbnail' = $thumbnail
      'view_count' = $viewcount
      'manifest_url' = ''
      'uploader' = $channel_title
      'webpage_url_domain' = $url.Host
      'type' = ''
      'availability' = ''
      'Tracks_Total' = ''
      'images' = $images
      'live_status' = $live_status
      'Playlist_url' = ''
      'playlist_id' = $youtube_id
      'Profile_Path' =''
      'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
      'Source' = 'YoutubePlaylist_item'
      'Group' = $Group
    }
    $synchash.Temporary_Playback_Media = $media            
    Start-Media -Media $media -thisApp $thisApp -synchash $synchash -Show_notification -use_WebPlayer:$thisapp.config.Youtube_WebPlayer                  
  }else{
    write-ezlogs "Can't start youtube media, missing youtube_id $($youtube_id) or LinkUri $($LinkUri)" -warning
    Update-Notifications  -Level 'WARNING' -Message "Can't start youtube media, missing youtube_id $($youtube_id) or LinkUri $($LinkUri)" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
  }
}
#---------------------------------------------- 
#endregion Add-YoutubePlayback Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-YoutubePlayback')

