<#
    .Name
    Get-YouTubePlaylistInfo

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves details about a specific or multiple YouTube playlists. 
     
    .EXAMPLE
    Get-YouTubePlaylistInfo -Id LFWxH-bexNk
      
    .EXAMPLE
    Get-YouTubePlaylistInfo -Id LFWxH-bexNk,8dZbdl3wzW8

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
#region Get-YouTubePlaylistInfo Function
#----------------------------------------------
function Get-YouTubePlaylistInfo {
  <#
      .SYNOPSIS
      Retrieves details about a specific or multiple YouTube playlists.

      .EXAMPLE
      Get-YouTubePlaylistInfo -Id LFWxH-bexNk

      .EXAMPLE
      Get-YouTubePlaylistInfo -Id LFWxH-bexNk,8dZbdl3wzW8
  #>
  [CmdletBinding()]
  param (
    [string[]] $Id,
    [switch] $VerboseLog
  )
  try{
    $Playlistparts = 'contentDetails,id,localizations,player,snippet,status'   
    $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    if(!$access_token -or !$refresh_access_token){
      write-ezlogs "[Get-YouTubePlaylistInfo] Missing access_token or refresh_access_token, trying again in case of transient issue" -showtime -warning -logtype Youtube
      start-sleep -Milliseconds 500
      $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }
    if($access_token_expires -le ([Datetime]::now) -or !$access_token){
      write-ezlogs "[Get-YouTubePlaylistInfo] Token has expired ($($access_token_expires)), attempting to refresh" -showtime -warning -logtype Youtube
      try{
        Grant-YoutubeOauth -thisApp $thisApp
        $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
      }catch{
        write-ezlogs "An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
      }
    } 
    if($access_Token){  
      if($VerboseLog){write-ezlogs ">>>> Peforming Youtube Playlist API looking for ID(s): $Id" -logtype Youtube}
      $results_output = [System.Collections.Generic.List[Object]]::new()
      $Authorization = 'Bearer {0}' -f $access_token
      if(@($Id).count -gt 1){
        $group = 50
        $i = 0 
        $ids = $null    
        $name = $null  
        $Parts = 'contentDetails,id,localizations,player,snippet,status'
        do {
          $name = $Null
          $ids = $null 
          $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id=' -f $Parts
          #$Uri = 'https://www.googleapis.com/youtube/v3/videos?part={0}&maxResults=50&id=' -f $Parts  
          foreach($name in $Id[$i..(($i+= $group) - 1)] | Where-Object {$_}){
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
            $req=[System.Net.HTTPWebRequest]::Create($Uri)
            $req.Method='GET'
            $headers = [System.Net.WebHeaderCollection]::new()
            $headers.add('Authorization',$Authorization)
            $req.Headers = $headers              
            $response = $req.GetResponse()
            $strm=$response.GetResponseStream()
            $sr=[System.IO.Streamreader]::new($strm)
            $output=$sr.ReadToEnd()
            $result = $output | convertfrom-json
            write-ezlogs "Result: $($result | out-string)"
          }catch{
            write-ezlogs "An exception occurred in Get-YouTubePlaylistInfo with HTTPWebRequest to $($Uri)" -showtime -catcherror $_          
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
        until ($i -ge $Id.count -1)
      }else{
        try{
          $playlistURL = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&id={1}' -f $Playlistparts,(("$ID").trim())
          $req=[System.Net.HTTPWebRequest]::Create($playlistURL)
          $req.Method='GET'
          $headers = [System.Net.WebHeaderCollection]::new()
          $headers.add('Authorization',$Authorization)
          $req.Headers = $headers              
          $response = $req.GetResponse()
          $strm=$response.GetResponseStream()
          $sr=[System.IO.Streamreader]::new($strm)
          $output=$sr.ReadToEnd()
          $playlistlookup = $output | convertfrom-json -ErrorAction SilentlyContinue
          $headers.Clear()
          $result = $playlistlookup.items
        }catch{
          write-ezlogs "An exception occurred getting playlist info with url $playlistURL" -showtime -catcherror $_
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
        $result | & { process { 
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
    write-ezlogs "An exception occurred in Get-YouTubePlaylistInfo" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-YouTubePlaylistInfo Function
#----------------------------------------------