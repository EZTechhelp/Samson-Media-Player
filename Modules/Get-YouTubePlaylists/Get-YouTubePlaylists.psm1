<#
    .Name
    Get-YouTubePlaylists

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves list of Youtube playlists. Adapted from Module Youtube  

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
#region Get-YouTubePlaylists Function
#----------------------------------------------
function Get-YouTubePlaylists {
  <#
      .SYNOPSIS
      Retrieves list of Youtube playlists.

      .EXAMPLE
      Get-YouTubePlaylists

      .EXAMPLE
      Get-YouTubePlaylists
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'Mine')]
    [switch] $mine,
    [Parameter(ParameterSetName = 'Id')]
    [string] $id
  )
  $results_output = [System.Collections.Generic.List[Object]]::new()
  if($PSCmdlet.ParameterSetName -eq 'Mine'){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
  }elseif($PSCmdlet.ParameterSetName -eq 'id'){
    $Parts = 'contentDetails,id,localizations,player,snippet,status'
    $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&channelId={1}' -f $Parts,$id
  }
  $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  $refresh_access_token = Get-secret -name Youtuberefresh_token  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  if($refresh_access_token){
    $access_token_expires = Get-secret -name Youtubeexpires_in  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
  }
  if($access_token_expires -le (Get-date) -or !$access_token){
    write-ezlogs "[Get-YouTubePlaylists] Token has expired, attempting to refresh - access_token_expires: $($access_token_expires)" -showtime -warning -logtype Youtube
    try{
      Grant-YoutubeOauth -thisApp $thisApp
      $access_token = Get-secret -name YoutubeAccessToken  -Vault $($thisApp.Config.App_name) -ErrorAction SilentlyContinue
    }catch{
      write-ezlogs "[Get-YouTubePlaylists] An exception occurred getting Secret YoutubeAccessToken" -showtime -catcherror $_
    }
  }
<#  $Header =  @{
    Authorization = 'Bearer {0}' -f $access_token
  }#>
  if($access_Token){    
    try{   
      $result = @{nextPageToken = 1 }   
      While ($result.nextPageToken){       
        $req=[System.Net.HTTPWebRequest]::Create($uri)
        $req.Method='GET'
        $headers = [System.Net.WebHeaderCollection]::new()
        $headers.add('Authorization',"Bearer $access_token")
        $req.Headers = $headers              
        $response = $req.GetResponse()
        $strm=$response.GetResponseStream();
        $sr=New-Object System.IO.Streamreader($strm);
        $output=$sr.ReadToEnd()
        $result = $output | convertfrom-json  
        $headers.Clear()
        $response.Dispose()
        $strm.Dispose()
        $sr.Dispose()
        if($result.nextPageToken){
          $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true&pageToken={1}' -f $Parts,$result.nextPageToken
        }else{
          $Uri = 'https://youtube.googleapis.com/youtube/v3/playlists?part={0}&maxResults=50&mine=true' -f $Parts
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
    }catch{
      write-ezlogs "[Get-YouTubePlaylists] An exception occurred invoking url $Uri" -showtime -catcherror $_
    }
    if(!$Result){
      write-ezlogs "[Get-YouTubePlaylists] No Youtube playlists were found!" -showtime -warning -logtype Youtube
    }             
    return $results_output 
  }else{
    write-ezlogs "[Get-YouTubePlaylists] Unable to retrieve proper youtube authentication!" -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Get-YouTubePlaylists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-YouTubePlaylists')