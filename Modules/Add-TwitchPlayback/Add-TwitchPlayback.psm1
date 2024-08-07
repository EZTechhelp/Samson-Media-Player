<#
    .Name
    Add-TwitchPlayback

    .Version 
    0.1.0

    .SYNOPSIS
    Provides immediate playback of Twitch media while importing 

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
#region Add-TwitchPlayback Function
#----------------------------------------------
function Add-TwitchPlayback
{
  Param (
    $thisApp,
    $synchash,
    [switch]$PlayOnly,
    [switch]$AddtoQueue,
    [string]$Channel,
    [string]$AddtoPlaylist,
    [string]$LinkUri,
    [string]$linktext,
    [switch]$Startup,
    [switch]$Verboselog
  )
  if($Channel -and $LinkUri){
    if($LinkUri -match '\?'){
      $LinkUri = ($LinkUri -split '\?')[0]
    }
    if(!$PlayOnly){
      try{
        if($LinkUri -match '\/videos\/'){
          $VideoId = [regex]::matches($LinkUri, "\/videos\/(?<value>.*)") | & { process {$_.groups[1].value}}
          $video_info = Get-TwitchVideos -TwitchVideoId $VideoId -thisApp $thisApp
          if($video_info.user_name){
            $TwitchAPI = Get-TwitchAPI -StreamName $video_info.user_name -thisApp $thisApp
          }
        }else{
          $video_info = Get-TwitchAPI -StreamName $Channel -thisApp $thisApp
        }       
      }catch{
        write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
      } 
    }
    $url = [uri]$LinkUri
    if($VideoId){
      $id = $VideoId
    }elseif($video_info.id){
      $id = $video_info.id
    }elseif($video_info.user_id){
      $id = $video_info.user_id
    }elseif($channel.id){
      $id = $channel.id
    }elseif($Channel){
      $idbytes = [System.Text.Encoding]::UTF8.GetBytes("$($Channel)-TwitchChannel")
      $id = [System.Convert]::ToBase64String($idbytes)
    }
    if($video_info.type -eq 'archive'){
      $title = "$($video_info.title)"
      $channel = $video_info.user_name
      $Live_Status = ''
      $Status_msg = ''
      $Stream_title = ''
      [int]$viewer_count = $video_info.view_count
    }elseif(!$video_info.type){          
      $title = "Twitch: $($Channel)"
      $Live_Status = 'Offline'
      $Status_msg = ''
      $Stream_title = ''
      [int]$viewer_count = 0
    }elseif($video_info.type -match 'live'){
      $title = "Twitch: $($video_info.user_name)"
      $Live_Status = 'Live'
      $Status_msg = "$($video_info.game_name)"
      $Stream_title = $video_info.title
      [int]$viewer_count = $video_info.viewer_count
    }elseif($video_info.type){
      $title = "Twitch: $($video_info.user_name)"
      $Live_Status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($video_info.type).tolower())
      $Status_msg = "$($video_info.game_name)"
      $Stream_title = $video_info.title
      [int]$viewer_count = $video_info.viewer_count
    }else{
      $title = "Twitch: $($channel)"
      $Live_Status = 'Offline'
      $Status_msg = ''
      $Stream_title = ''
      [int]$viewer_count = 0
    }
    if($video_info.profile_image_url){
      $profile_image_url = $video_info.profile_image_url
      $offline_image_url = $video_info.offline_image_url
      $description = $video_info.description
    }elseif($TwitchAPI.profile_image_url){
      $profile_image_url = $TwitchAPI.profile_image_url
      $offline_image_url = $TwitchAPI.offline_image_url
      $description = $TwitchAPI.description
    }else{
      $profile_image_url = $Null
      $offline_image_url = $Null  
      $description = $Null   
    }
    if($video_info.duration){
      try{
        $time = $($video_info.duration -replace 'd',':' -replace 'h',':' -replace 'm',':' -replace 'm',':' -replace 's')
        $duration =[TimeSpan]::Parse($time)
        if($duration){
          $duration = "$(([string]$duration.hours).PadLeft(2,'0')):$(([string]$duration.Minutes).PadLeft(2,'0')):$(([string]$duration.Seconds).PadLeft(2,'0'))"
        }
      }catch{
        $duration = ''
      }
    }else{
      $duration = ''
    }

    #$Group = 'Youtube'
    if($PlayOnly){
      $live_status = 'Temporary'
    }
    if(-not [string]::IsNullOrEmpty($thisApp.Config.TwitchMedia_Display_Syntax)){
      $DisplayName = $thisApp.Config.TwitchMedia_Display_Syntax -replace '%channel%',$channel -replace '%title%',$title -replace '%type%','TwitchChannel' -replace '%live_status%',$Live_Status -replace '%stream_title%',$Stream_title
    }elseif($VideoId){
      $DisplayName = "Twitch VOD: $channel | $title"
    }else{
      $DisplayName = $null
    } 
    $media = [Media]@{
      'Id' = $id
      'User_id' = $video_info.user_id
      'Artist' = $channel
      'Name' = $channel
      'Title' = $title
      'Playlist' = $channel
      'Playlist_ID' = $id
      'Playlist_url' = $url
      'Channel_Name' = $channel
      'Channel_ID' = $video_info.stream_id
      'Description' =  $description
      'Live_Status' = $Live_Status
      'Stream_title' = $Stream_title
      'Status_msg' = $Status_msg
      'Viewer_Count' = $viewer_count
      'Cached_Image_Path' = $null
      'Profile_Image_Url' = $profile_image_url
      'Offline_Image_Url' = $offline_image_url
      'Chat_Url' = "https://twitch.tv/$($channel)/chat"
      'Source' = 'Twitch'
      'Followed' = $Null
      'Profile_Date_Added' = [DateTime]::Now.ToString()
      'url' = $url
      'type' = 'TwitchChannel'
      'Duration' = $duration
      'Display_Name' = $DisplayName
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
      Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification
    }               
  }else{
    write-ezlogs "Can't start Twitch media, missing Channel ($($Channel)) or LinkUri ($($LinkUri))" -warning
    Update-Notifications  -Level 'WARNING' -Message "Can't start Twitch media, missing Channel ($($Channel)) or LinkUri ($($LinkUri))" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold
  }
}
#---------------------------------------------- 
#endregion Add-TwitchPlayback Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-TwitchPlayback')