<#
    .Name
    Get-YouTubePlaylistItems

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves list of Youtube videos parsed from Youtube playlists. Adapted from Module Youtube  

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
#region Get-YouTubePlaylistItems Function
#----------------------------------------------
function Get-YouTubePlaylistItems {
  <#
      .SYNOPSIS
      Retrieves details about a specific YouTube video, or multiple videos.

      .EXAMPLE
      Get-YouTubePlaylistItems -Id LFWxH-bexNk

      .EXAMPLE
      Get-YouTubePlaylistItems -Id LFWxH-bexNk,8dZbdl3wzW8
  #>
  [CmdletBinding()]
  param (
    [string[]] $Id,
    [switch] $Liked,   
    [switch] $Disliked,
    [switch] $Verboselog,
    $PlaylistInfo
  )
  $results_output = [System.Collections.Generic.List[Object]]::new()
  if($Id){
    $Parts = 'contentDetails,id,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlistItems?part={0}&maxResults=50' -f $Parts
    $type = 'playlistId'
    $Uri += '&{0}={1}' -f $type,($ID -join ',')
  }elseif($Liked){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&myRating=like' -f $Parts
  }else{
    $Parts = 'contentDetails,id,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50' -f $Parts
  }
  try{
    $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name) 
  }catch{
    write-ezlogs "[Get-YouTubePlaylistItems]  An exception occurred executing Get-AccessToken" -showtime -catcherror $_
  }
  if(!$access_Token.Authorization){
    write-ezlogs "[Get-YouTubePlaylistItems] No token expiration found (Secret Vault $($thisApp.Config.App_name)) - try again in case of transient issue" -showtime -warning
    $accesstoken = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    if($access_token_expires -le (Get-date) -or !$accesstoken){
      write-ezlogs "[Get-YouTubePlaylistItems] Token has expired ($access_token_expires), attempting to refresh (Secret Vault $($thisApp.Config.App_name))" -showtime -warning
      try{
        Grant-YoutubeOauth -thisApp $thisApp 
        $accesstoken = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "[Get-YouTubePlaylistItems]  An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
      }
    }
    $access_Token =  @{
      Authorization = 'Bearer {0}' -f $accesstoken
    }
  }
  if($access_Token.Authorization){  
    if($Id -and !$PlaylistInfo){
      try{
        $Playlistparts = 'contentDetails,id,localizations,player,snippet,status'
        $playlistURL = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id={1}' -f $Playlistparts,(("$ID").trim())
        write-ezlogs ">>>> Calling Youtube API for Playist id $Id -- URI: $playlistURL" -LogLevel 0 -Verboselog:$VerboseLog
        $req=[System.Net.HTTPWebRequest]::Create($playlistURL)
        $req.Method='GET'
        $headers = [System.Net.WebHeaderCollection]::new()
        $headers.add('Authorization',$access_Token.Authorization)
        $req.Headers = $headers              
        $response = $req.GetResponse()
        $strm=$response.GetResponseStream()
        $sr=[System.IO.Streamreader]::new($strm)
        $output=$sr.ReadToEnd()
        $playlistlookup = $output | convertfrom-json -ErrorAction SilentlyContinue
        $headers.Clear()
        $PlaylistInfo = $playlistlookup.items
      }catch{
        write-ezlogs "An exception occurred getting playlist info with url: $playlistURL" -showtime -catcherror $_
      }finally{
        if($response){
          $response.Dispose()
        }
        if($strm){
          $strm.Dispose()
        }
        if($sr){
          $sr.Dispose()
        } 
        if($headers){
          $headers.Clear()
        }  
        $req = $Null          
      }
    }  
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){ 
        try{
          write-ezlogs ">>>> Calling Youtube API: $Uri" -LogLevel 0 -Verboselog:$VerboseLog
          $req=[System.Net.HTTPWebRequest]::Create($Uri)
          $req.Method='GET'
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',$access_Token.Authorization)
          $req.Headers = $headers              
          $response = $req.GetResponse()
          $strm=$response.GetResponseStream()
          $sr=[System.IO.Streamreader]::new($strm)
          $output=$sr.ReadToEnd()
          $result = $output | convertfrom-json   
        }catch{
          if($response){
            $response.Dispose()
          }
          if($strm){
            $strm.Dispose()
          }
          if($sr){
            $sr.Dispose()
          }   
          $req = $Null  
          $error.clear()
          if($_.Exception -match 'The remote server returned an error: \(404\) Not Found'){
            write-ezlogs "Youtube API server returned '(404) Not Found' - for playlist id: $ID" -warning -logtype Youtube
            return 'Not Found'
          }else{
            write-ezlogs "An exception occurred in Get-YoutubePlaylistitems with HTTPWebRequest to: $($Uri)" -showtime -catcherror $_
          }         
          break
        }             
        if($result.nextPageToken){
          if($ID){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlistItems?part={0}&maxResults=50&{1}={2}&pageToken={3}' -f $Parts,$type,(($ID | out-string).trim()),$result.nextPageToken
          }elseif($Liked){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&myRating=like&pageToken={1}' -f $Parts,$result.nextPageToken
          }
        }else{
          if($ID){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/playlistItems?part={0}&maxResults=50&{1}={2}' -f $Parts,$type,(($ID | out-string).trim())
          }elseif($Liked){
            $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&myRating=like' -f $Parts
          }
        }
        if($result.items){
          foreach($item in $result.items){
            if($results_output -notcontains $item){
              if($PlaylistInfo -and (!$item.Playlist_info)){
                Add-Member -InputObject $item -Name 'Playlist_info' -Value $playlistlookup.items -MemberType NoteProperty -Force
              }           
              $null = $results_output.add($item)
            }
          } 
          #$result # this return items that will be aggregated with items of other loops
        }
      }
      $headers.Clear()
      $response.Dispose()
      $strm.Dispose()
      $sr.Dispose()
    }catch{
      write-ezlogs "An exception occurred invoking url $Uri" -showtime -catcherror $_
    }
    if(!$Result){
      write-ezlogs "Unable to results, starting Youtube authorization capture process" -showtime -warning
      try{
        Grant-YoutubeOauth -thisApp $thisApp   
        try{
          $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
        }catch{
          write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
        } 
        if($access_token){
          try{
            $result = @{nextPageToken = 1 }   
            While ($result.nextPageToken){  
              $req=[System.Net.HTTPWebRequest]::Create($Uri);
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('Authorization','Bearer {0}' -f $access_token)
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream();
              $sr=New-Object System.IO.Streamreader($strm);
              $output=$sr.ReadToEnd()
              $result = $output | convertfrom-json
              if($result.nextPageToken){
                if($ID){
                  $Uri = 'https://youtube.googleapis.com/youtube/v3/playlistItems?part={0}&maxResults=50&{1}={2}&pageToken={3}' -f $Parts,$type,(($ID | out-string).trim()),$result.nextPageToken
                }elseif($Liked){
                  $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&myRating=like&pageToken={1}' -f $Parts,$result.nextPageToken
                }
              }else{
                if($ID){
                  $Uri = 'https://youtube.googleapis.com/youtube/v3/playlistItems?part={0}&maxResults=50&{1}={2}' -f $Parts,$type,(($ID | out-string).trim())
                }elseif($Liked){
                  $Uri = 'https://youtube.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&myRating=like' -f $Parts
                }
              }
              if($result.items){
                foreach($item in $result.items){
                  if($results_output -notcontains $item){
                    if($PlaylistInfo -and !$item.Playlist_info){
                      Add-Member -InputObject $item -Name 'Playlist_info' -Value $playlistlookup.items -MemberType NoteProperty -Force
                    }           
                    $null = $results_output.add($item)
                  }
                } 
                #$result # this return items that will be aggregated with items of other loops
              }
            }
            $headers.Clear()
            $response.Dispose()
            $strm.Dispose()
            $sr.Dispose()                                
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
    return $results_output 
  }else{
    write-ezlogs "Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}
#---------------------------------------------- 
#region Get-YouTubePlaylistItems Function
#----------------------------------------------