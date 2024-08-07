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
    - Module designed for Samson Media Player

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
    $synchash,
    [switch]$PlayOnly,
    [switch]$AddtoQueue,
    [string]$youtube_id,
    [string]$AddtoPlaylist,
    [string]$LinkUri,
    [string]$linktext,
    [switch]$Startup,
    [switch]$Verboselog
  )
  if(!$youtube_id -and $LinkUri){
    try{
      $youtube = Get-YoutubeURL -thisApp $thisApp -URL $LinkUri -APILookup
      if($youtube.id){
        $youtube_id = $youtube.id
      }
      if($youtube.url){
        $LinkUri = $youtube.url
      }
      if($youtube.playlist_id){
        $playlist_id = $youtube.playlist_id
      }
    }catch{
      write-ezlogs "An exception occurred parsing youtube id form link $linkuri" -showtime -catcherror $_
    }
  }
  if($youtube_id -and $LinkUri){
    if(!$PlayOnly){
      try{
        $video_info = Get-YouTubeVideo -Id $youtube_id
      }catch{
        write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
      } 
    }
    $url = [uri]$LinkUri
    if($video_info){
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
          if($TimeValues){
            try{      
              $TimeSpan =[TimeSpan]::FromHours((Convert-TimespanToInt -Timespan $TimeValues))
              if($TimeSpan){
                $duration = "$(([string]$TimeSpan.hours).PadLeft(2,'0')):$(([string]$TimeSpan.Minutes).PadLeft(2,'0')):$(([string]$TimeSpan.Seconds).PadLeft(2,'0'))"  
              }                               
            }catch{
              write-ezlogs "An exception occurred parsing duration for $($title)" -showtime -catcherror $_
            }
          }
        }catch{
          write-ezlogs "An exception occurred parsing duration $($video_info.contentDetails.duration)" -showtime -catcherror $_
        }
      }           
    }elseif(!$title -and $linktext){
      $title = $linktext
    }else{
      $title = "Youtube Video - $youtube_id"
    }
    if($url -match '\/tv\.youtube\.com\/'){
      $type = 'YoutubeTV'
    }elseif($playlist_id){
      $type = 'YoutubePlaylistItem'
    }else{
      $type = 'YoutubeVideo'
    }
    #$Group = 'Youtube'
    if($PlayOnly){
      $live_status = 'Temporary'
    }else{
      $live_status = $null
    }
    if(-not [string]::IsNullOrEmpty($thisApp.Config.YoutubeMedia_Display_Syntax)){
      $DisplayName = $thisApp.Config.YoutubeMedia_Display_Syntax -replace '%artist%',$channel_title -replace '%title%',$title -replace '%track%','' -replace '%playlist%',''
    }else{
      $DisplayName = $Null
    }
    $media = [PSCustomObject]@{
      'title' =  $title
      'Artist' = $channel_title
      'Channel_Name' = $channel_title
      'Display_Name' = $DisplayName
      'description' = $description
      'channel_id' = $channel_id
      'id' = $youtube_id
      'duration' = $duration
      'url' = $url
      'thumbnail' = $thumbnail
      'type' = $type
      'image' = $images
      #'live_status' = $live_status
      'Playlist_url' = ''
      'playlist_id' = $youtube_id
      'Profile_Date_Added' = [DateTime]::Now.ToString()
      'Source' = 'Youtube'
      #'Group' = 'WebBrowser'
    }
    if($AddtoQueue){
      if(!$synchash.Temporary_Media){
        $synchash.Temporary_Media = [System.Collections.Generic.List[Object]]::new()
      }
      if($synchash.Temporary_Media.id -notcontains $media.id){
        write-ezlogs "| Adding track '$title' to temporary media queue"
        $Null = $synchash.Temporary_Media.add($media)
      }
      Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media @($media) -Use_RunSpace -RefreshQueue
    }elseif($AddtoPlaylist -and $media){
      Add-Playlist -Media $media -Playlist $AddtoPlaylist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI
    }elseif($media){
      $synchash.Temporary_Playback_Media = $media
      Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification -use_WebPlayer:$thisapp.config.Youtube_WebPlayer  
    }               
  }else{
    write-ezlogs "Can't start youtube media, missing youtube_id $($youtube_id) or LinkUri $($LinkUri)" -warning
    Update-Notifications  -Level 'WARNING' -Message "Can't start youtube media, missing youtube_id $($youtube_id) or LinkUri $($LinkUri)" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold
  }
}
#---------------------------------------------- 
#endregion Add-YoutubePlayback Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-YoutubePlayback')