
#---------------------------------------------- 
#region Get-YouTubeActivity Function
#----------------------------------------------
function Get-YouTubeActivity {
  <#
      .SYNOPSIS
      Obtain activities performed by yourself or a specific channel ID.
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'ChannelId')]
    [string] $ChannelId,
    [Parameter(ParameterSetName = 'Mine')]
    [switch] $Mine,
    [Parameter(ParameterSetName = 'ChannelId')]
    [Parameter(ParameterSetName = 'Mine')]
    [switch] $Raw
  )
  $Uri = 'https://www.googleapis.com/youtube/v3/activities?part=id,snippet,contentDetails&maxResults=50'
  $Parts = 'contentDetails,id,snippet'
  $type = 'channelId'
  $results_output = [System.Collections.Generic.List[Object]]::new()
  switch ($PSCmdlet.ParameterSetName) {
    'Mine' {
      $Uri += '&mine=true'
      break
    }
    'ChannelId' {
      $Uri += '&channelId={0}' -f $ChannelId
    }
  }
  try{
    $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name) 
  }catch{
    write-ezlogs "[Get-YouTubeActivity]  An exception occurred executing Get-AccessToken" -showtime -catcherror $_
  }
  if(!$access_Token.Authorization){
    write-ezlogs "[Get-YouTubeActivity] No token expiration found (Secret Vault $($thisApp.Config.App_name)) - try again in case of transient issue" -showtime -warning
    $accesstoken = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    #$refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    if($access_token_expires -le (Get-date) -or !$accesstoken){
      write-ezlogs "[Get-YouTubeActivity] Token has expired ($access_token_expires), attempting to refresh (Secret Vault $($thisApp.Config.App_name))" -showtime -warning
      try{
        Grant-YoutubeOauth -thisApp $thisApp 
        $accesstoken = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "[Get-YouTubeActivity]  An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
      }
    }
    $access_Token =  @{
      Authorization = 'Bearer {0}' -f $accesstoken
    }
  }
  if($access_Token.Authorization){
    try{   
      $result = @{nextPageToken = 1 }
      While ($result.nextPageToken){ 
        try{
          $req=[System.Net.HTTPWebRequest]::Create($Uri)
          $req.Method='GET'
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',$access_Token.Authorization)
          $req.Headers = $headers              
          $response = $req.GetResponse()
          $strm=$response.GetResponseStream()
          $sr=[System.IO.Streamreader]::New($strm)
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
            write-ezlogs "Youtube API server returned '(404) Not Found' - for channel id: $ChannelID" -warning -logtype Youtube
            return 'Not Found'
          }else{
            write-ezlogs "An exception occurred in Get-YouTubeActivity with HTTPWebRequest to: $($Uri)" -showtime -catcherror $_
          }         
          break
        }             
        if($result.nextPageToken){
          $Uri = 'https://youtube.googleapis.com/youtube/v3/activities?part={0}&maxResults=50&{1}={2}&pageToken={3}' -f $Parts,$type,(($ChannelID | out-string).trim()),$result.nextPageToken
        }else{
          $Uri = 'https://youtube.googleapis.com/youtube/v3/activities?part={0}&maxResults=50&{1}={2}' -f $Parts,$type,(($ChannelID | out-string).trim())
        }
        if($result.items){
          foreach($item in $result.items){
            if($results_output -notcontains $item){         
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
              $req=[System.Net.HTTPWebRequest]::Create($Uri)
              $req.Method='GET'
              $headers = [System.Net.WebHeaderCollection]::new()
              $headers.add('Authorization','Bearer {0}' -f $access_token)
              $req.Headers = $headers              
              $response = $req.GetResponse()
              $strm=$response.GetResponseStream()
              $sr=[System.IO.Streamreader]::new($strm)
              $output=$sr.ReadToEnd()
              $result = $output | convertfrom-json
              if($result.nextPageToken){
                $Uri = 'https://youtube.googleapis.com/youtube/v3/activities?part={0}&maxResults=50&{1}={2}&pageToken={3}' -f $Parts,$type,(($channelID | out-string).trim()),$result.nextPageToken
              }else{
                $Uri = 'https://youtube.googleapis.com/youtube/v3/activities?part={0}&maxResults=50&{1}={2}' -f $Parts,$type,(($channelID | out-string).trim())
              }
              if($result.items){
                foreach($item in $result.items){
                  if($results_output -notcontains $item){          
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
#endregion Get-YouTubeActivity Function
#----------------------------------------------