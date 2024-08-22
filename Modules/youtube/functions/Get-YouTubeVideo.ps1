<#
    .Name
    Get-YouTubeVideo

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves details about a specific YouTube video, or multiple videos. 
     
    .EXAMPLE
    Get-YouTubeVideo -Id LFWxH-bexNk
      
    .EXAMPLE
    Get-YouTubeVideo -Id LFWxH-bexNk,8dZbdl3wzW8

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
#region Get-YouTubeVideo Function
#----------------------------------------------
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
    [switch] $Disliked,
    [switch] $VerboseLog
  )
  try{
    if($PSCmdlet.ParameterSetName -eq 'VideoById'){
      $Parts = 'contentDetails,id,liveStreamingDetails,localizations,player,recordingDetails,snippet,statistics,status,topicDetails'
      $Uri = 'https://www.googleapis.com/youtube/v3/videos?part={0}&maxResults=50' -f $Parts
      $id = $ID
      $type = 'id'
      $Uri += '&{0}={1}' -f $type,($Id -join ',')
    }
    if ($PSCmdlet.ParameterSetName -eq 'LikedVideos') { $Uri += '&myRating=liked' }
    if ($PSCmdlet.ParameterSetName -eq 'DislikedVideos') { $Uri += '&myRating=disliked' } 
    $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    if(!$access_token -or !$refresh_access_token){
      write-ezlogs "[Get-YoutubeVideo] Missing access_token or refresh_access_token, trying again in case of transient issue" -showtime -warning -logtype Youtube
      start-sleep -Milliseconds 500
      $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }
    if($access_token_expires -le ([Datetime]::now) -or !$access_token){
      write-ezlogs "[Get-YoutubeVideo] Token has expired ($($access_token_expires)), attempting to refresh" -showtime -warning -logtype Youtube
      try{
        Grant-YoutubeOauth -thisApp $thisApp
        $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
      }
    } 
    if($access_Token){  
      if($VerboseLog){write-ezlogs ">>>> Peforming Youtube Video API looking for ID(s): $Id" -logtype Youtube}
      $results_output = [System.Collections.Generic.List[Object]]::new()
      $Authorization = 'Bearer {0}' -f $access_token
      if(@($Id).count -gt 1){
        $group = 50
        $i = 0 
        $ids = $null    
        $name = $null
        $Parts = 'contentDetails,id,liveStreamingDetails,localizations,player,recordingDetails,snippet,statistics,status,topicDetails'   
        $type = 'id'
        do {
          $name = $Null
          $ids = $null 
          $Uri = 'https://www.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&id=' -f $Parts  
          foreach($name in $Id[$i..(($i+= $group) - 1)] | where {$_}){
            try{
              $name = $name.replace(" ",[string]::Empty)    
              if([string]::IsNullOrEmpty($ids) -and $ids -notlike "*$name*"){   
                $ids += "$name"
              }elseif($ids -notlike "*$name*"){
                $ids += ",$name"
              }
                          
            }catch{
              write-ezlogs "An exception building url while processing entry $name" -showtime -catcherror $_
            }       
          } 
          $Uri += $ids
          try{
            $req=[System.Net.HTTPWebRequest]::Create($Uri);
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('Authorization',$Authorization)
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $result = $output | convertfrom-json
          }catch{
            write-ezlogs "An exception occurred in Get-YoutubeVideo with HTTPWebRequest to $($Uri) - access_token: $($access_Token | out-string)" -showtime -catcherror $_          
            #break
          }finally{
            if($headers){
              $null = $headers.Clear()
            }
            if($response){
              $null = $response.Dispose()
            }
            if($strm){
              $null = $strm.Dispose()
            }
            if($sr){
              $null = $sr.Dispose()
            }
          } 
          <#        $result.items | foreach {
              if($results_output -notcontains $_){           
              $null = $results_output.add($_)
              } 
          }#>
          $result.items | & { process { 
              if($_.id -notin $results_output.id){
                [void]$results_output.add($_)
              }
          }}
        }
        until ($i -ge $Id.count -1) 
      }else{
        try{
          $req=[System.Net.HTTPWebRequest]::Create($Uri);
          $req.Method='GET'
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',$Authorization)
          $req.Headers = $headers              
          $response = $req.GetResponse()
          $strm=$response.GetResponseStream()
          $sr=[System.IO.Streamreader]::new($strm)
          $output=$sr.ReadToEnd()
          $result = $output | convertfrom-json   
        }catch{
          write-ezlogs "An exception occurred in Get-YoutubeVideo with HTTPWebRequest to $($Uri) - access_token: $($access_Token | out-string)" -showtime -catcherror $_
          #break
        }finally{
          if($headers){
            $null = $headers.Clear()
          }
          if($response){
            $null = $response.Dispose()
          }
          if($strm){
            $null = $strm.Dispose()
          }
          if($sr){
            $null = $sr.Dispose()
          }
        } 
        $result.items | & { process { 
            if($_.id -notin $results_output.id){
              [void]$results_output.add($_)
            }
        }}
      }            
      return $results_output
    }else{
      write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning -logtype Youtube
    }
  }catch{
    write-ezlogs "An exception occurred in Get-YoutubeVideo" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-YouTubeVideo Function
#----------------------------------------------