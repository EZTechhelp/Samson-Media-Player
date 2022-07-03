function Get-YouTubeVideo {
  <#
      .SYNOPSIS
      Retrieves details about a specific YouTube video, or multiple videos.

      .EXAMPLE
      Get-YouTubeVideo -Id LFWxH-bexNk

      .EXAMPLE
      Get-YouTubeVideo -Id LFWxH-bexNk,8dZbdl3wzW8
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'VideoById')]
    [string[]] $Id,
    [Parameter(ParameterSetName = 'LikedVideos')]
    [switch] $Liked,  
    [Parameter(ParameterSetName = 'DislikedVideos')]
    [switch] $Disliked
  )
  if($PSCmdlet.ParameterSetName -eq 'VideoById'){
    $Parts = 'contentDetails,id,liveStreamingDetails,localizations,player,recordingDetails,snippet,statistics,status,topicDetails'
    $Uri = 'https://www.googleapis.com/youtube/v3/videos?part={0}&maxResults=50' -f $Parts
    $id = $ID
    $type = 'id'
    $Uri += '&{0}={1}' -f $type,($Id -join ',')
  }

  if ($PSCmdlet.ParameterSetName -eq 'LikedVideos') { $Uri += '&myRating=liked' }
  if ($PSCmdlet.ParameterSetName -eq 'DislikedVideos') { $Uri += '&myRating=disliked' }
  #$access_Token = (Get-AccessToken) 
  $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  $refresh_access_token = Get-secret -name Youtuberefresh_token -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  if($refresh_access_token){
    $access_token_expires = Get-secret -name Youtubeexpires_in -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  }
  if($access_token_expires -le (Get-date) -or !$access_token){
    write-ezlogs "Token has expired, attempting to refresh" -showtime -warning
    try{
      Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript 
      $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
    }
  } 
  $Header =  @{
    Authorization = 'Bearer {0}' -f $access_token
  }
  if($access_Token){  
    try{ 
      $Result = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Header
    }catch{
      write-ezlogs "An exception occurred invoking url $Uri" -showtime -catcherror $_
    }
    if(!$Result){
      write-ezlogs "Unable to get results for youtube id $($id) - $($Result | out-string), starting Youtube authorization capture process" -showtime -warning
      try{
        Grant-YoutubeOauth -thisApp $thisApp -thisScript $thisScript    
        try{
          $access_token = Get-secret -name YoutubeAccessToken -AsPlainText -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
        } 
        if($access_token){
          try{
            $Header =  @{
              Authorization = 'Bearer {0}' -f $access_token
            } 
            $Result = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Header                  
          }catch{
            write-ezlogs "An exception occurred invoking url $Uri" -showtime -catcherror $_
          }        
        }else{
          write-ezlogs "Unable to get Youtube access token!" -showtime -warning
          return $false
        }                          
      }catch{
        write-ezlogs "An exception occurred executing Grant-YoutubeOauth from Get-Youtubevideo" -showtime -catcherror $_
      }
    }             
    return $result.items
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}